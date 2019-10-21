
/* Studies II - for soprano, piano and electronics */
/* Oct 21, 2019 */

/* This script contains instructions to generate electronics part of the piece. Pianist will trigger using Akai MPK mini midi controller. Soprano will step on a ActitioN 4 button USB midi footswitch. Electronics performer will trigger using push button midi controllers, Akai APC mini and Akai LPD 8. This piece will involve 9 speakers in which 2 will be placed beside the performers at the right and left of the stage. One speaker will be placed under the grand piano (piano needs to be opened to the largest without taking it apart). A dynamic microphone, Shure SM57, will be placed in front of the soprano in order to pick up vocal sound. A condenser microphoneo, Rode NT 5 (or Sontronics STC-10), will be placed beside the piano and aim into it. This microphone will be used to pick up piano resonances. */


//////////////////////////////////////// PREP ////////////////////////////////////////
/********* change input and ouput channel *********/
/********* specify audio interface *********/

(
{
	/* start up file */
	Server.local.options.numOutputBusChannels = 9; // change number of input and output channels; 9 speakers for Studies I and II, the 9th will be placed aiming into piano
	Server.local.options.numInputBusChannels = 2;
	Server.internal.options.numOutputBusChannels = 9;
	Server.internal.options.numInputBusChannels = 2;
	//Server.local.options.device = "MOTU 896mk3 Hybrid";

	{s.meter;}.defer; // make sure it has 0-9 channels
	MIDIClient.init;
	MIDIIn.connectAll;

	s.waitForBoot {

		"buffers".postln;

		/* allocate buffers */
		~bufLength1 = 4;
		~bufLength2 = 4;
		~buf1 = Buffer.alloc(s, 44100 * ~bufLength1, 1); // allocate buffer to record for 4 seconds for rec 1
		s.sync;
		~buf2 = Buffer.alloc(s, 44100 * ~bufLength2, 1); // allocate buffer to record for 4 seconds for rec 2
		s.sync;
		"buffers done".postln;

		/* pick up mic 1 signal, modify amplitude etc for output */
		~inNdef1= {
			Ndef.ar(\micIn1, 1); // 1 input from 1 mic
			//Ndef(\micIn, { Compander.ar(SoundIn.ar(2), 0, 0.7, 0.5, 0.9, 0.01, 0.1, 0.5) });
			Ndef(\micIn1, { SoundIn.ar(0)}); // pick up from channel 0; change this based on tech setup
		};
		~inNdef1.(); // run globally

		/* pick up mic 2 signal, modify amplitude etc for output */
		~inNdef2 = {
			Ndef.ar(\micIn2, 1); // 2nd input from 2nd mic
			//Ndef(\micIn2, { Compander.ar(SoundIn.ar(3), 0, 0.5, 1, 1, 0.01, 0.1, 1) });
			Ndef(\micIn2, { SoundIn.ar(1)});
		};
		~inNdef2.();

		SynthDef(\SoundIn, {
			arg bufnum = 0, recLevel = 1, preLevel = 0;
			var input, rec;
			input = SoundIn.ar(0); // to make sure it is recording use .poll
			rec = RecordBuf.ar(input, bufnum, 0, recLevel, preLevel, loop: 0, doneAction: 2);
		}).add;

		/* function for granularize soprano live recordings */
		~grainSopLiveRec = {
			arg sndbuf, out, gate = 1, vol = 1, amp = 0.9, numChannels, trigger, dur, rate, pos, interp, pan, envbufnum, maxGrains;
			var env, signal;
			numChannels = 4; // 4 channels
			trigger = Impulse.ar(XLine.kr(200)); // this gives a swarm at the beginning
			dur = 1;
			rate = LFNoise1.kr.range(0.5, 2); // * -1 to playbackwards
			pos = SinOsc.ar(LFNoise1.kr(200));
			interp = 1;
			pan = SinOsc.kr(400);
			envbufnum = -1;
			maxGrains = 512;
			env = EnvGen.kr(Env.adsr, gate, levelScale: amp, doneAction: 2);
			signal = GrainBuf.ar(numChannels, trigger, dur, sndbuf, rate, pos, interp, pan, envbufnum, maxGrains) * env;
			Out.ar(0, signal * vol);
		};

		/* function for bar 1; output soprano voice through speakers 1 2 3 4 5 6 7 8 */
		~bar1SopRev = {
			arg out, gate = 1, vol = 1;
			var in, amp, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			amp = 0.8;
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(CombN.ar(in, 0.2, 0.3, 1), 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * amp * env);
			Out.ar([0,1,2,3,4,5,6,7], signal * vol);
		};

		/* function for bar 1; output random pan through speakers 1 2 3 4 5 6 7 8 */
		~bar1SopPan = {
			arg out, gate = 1, vol = 0.8;
			var in, amp, pan, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1; to test, use in = ClipNoise.ar;
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(CombN.ar(in, 0.8, 0.5, 6), 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * vol * env);
			// to multichannel pan, use PanAz last
			pan = PanAz.ar(8, signal, LFSaw.kr(1), 0.3, 3);
			Out.ar(6, pan[0]);
			Out.ar(5, pan[1]);
			Out.ar(4, pan[2]);
			Out.ar(3, pan[3]);
			Out.ar(2, pan[4]);
			Out.ar(1, pan[5]);
			Out.ar(0, pan[6]);
		};

		/* function for bar 4; output soprano voice through speakers 7 8 */
		~bar4Sop = {
			arg out, gate = 1, vol = 1;
			var in, amp, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			amp = 0.8;
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(in, 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * amp * env);
			Out.ar([4, 5], signal * vol); // change this to 7 and 8 speaker (output channel [6, 7])
		};

		/* function for bar 4; spectral filter to playback 'modulated' soprano result; output each result onto randomly picked speaker */
		~bar4spec = {
			arg gate = 1, vol = 1;
			var in1, in2, chain1, chain2, copychain, copychainNewChain2, signal, fftSig, env1, env2;
			env1 = Env.dadsr(0.1, sustainLevel:1).kr;
			env2 = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			in1 = Saw.ar(rrand(1, 500),0.8);
			in2 = Ndef.ar(\micIn1, 1);
			chain1 = FFT(LocalBuf(1024), in1);
			chain2 = FFT(LocalBuf(1024), in2);
			copychain= PV_Copy(chain2, LocalBuf(1024));
			chain1 = PV_MagMul(chain1, chain2);
			fftSig = [0.8 * IFFT(chain1),  0.8 * IFFT(copychain)] * env1;
			signal = FreeVerb.ar(fftSig, 0.5, 0.5, 0.9, 0.8);
			Out.ar([0], (PanAz.ar(2, signal, LFSaw.kr(exprand(1, 8)), 0.5, 3, 0.5)) * env2 * vol);
		};

		/* function for bar 8 ouput soprano siganl through speakers 1 and 2 */
		~bar8SopRev = {
			arg out, gate = 1, vol = 1;
			var in, amp, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			amp = 0.8;
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(CombN.ar(in, 0.2, 0.3, 1), 440, 1, 0.8), 0.3, 0.5, 1), 0.5, 0.8, 1, 1) * amp * env);
			Out.ar([0, 1], signal * vol);
		};

		/* function for granularize soprano live recordings at bar 9*/
		~grainSopLiveRecBar9 = {
			arg sndbuf, out, gate = 1, vol = 1, amp = 0.9, numChannels, trigger, dur, rate, pos, interp, pan, envbufnum, maxGrains, posPan;
			var env, signal;
			numChannels = 8;
			trigger = Impulse.ar(1);
			dur = 1;
			rate = LFNoise1.kr.range(0.5, 2);
			pos = SinOsc.ar(LFNoise1.kr(1000));
			interp = 1;
			pan = SinOsc.kr(SinOsc.kr(500));
			envbufnum = -1;
			maxGrains = 512;
			env = EnvGen.kr(Env.adsr, gate, levelScale: amp, doneAction: 2);
			signal = GrainBuf.ar(numChannels, trigger, dur, sndbuf, rate, pos, interp, pan, envbufnum, maxGrains) * env * amp;
			Out.ar(0, signal* (vol * 10));
		};

		/* function for bar 12 playback recording 2 through speakers 1 and 2 */
		~bar12PlaybackRec2 = {
			arg out = 0, bufnum, amp = 0.8;
			Out.ar([0, 1], (PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction: 2)) * amp);
		};

		/* function to pan piano with soprano at bat 18 */
		~panPiano = {
			arg pos = 0, level = 0.2, vol = 0.8;
			PanAz.ar(
				8, // num channel
				SoundIn.ar(3), // indicate input
				pos,
				level,
				2, // width
				0, //orientation
			) * vol;
		};

		/* function for bar 24 playback recording 2 through speakers 7 and 8 */
		~bar24PlaybackRec2 = {
			arg out = 0, bufnum, amp = 0.8;
			Out.ar([6, 7], (PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction: 2)) * amp);
		};

		/* function for bar 27 playback recording 2 through speakers 3 and 4 */
		~bar27PlaybackRec2 = {
			arg out = 0, bufnum, amp = 0.8;
			Out.ar([2, 3], (PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction: 2)) * amp);
		};

		/* function for bar 28 playback recording 2 through speakers 5 and 6 */
		~bar28PlaybackRec2 = {
			arg out = 0, bufnum, amp = 0.8;
			Out.ar([4, 5], (PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction: 2)) * amp);
		};

		"func and def done".postln;

		/* get midi controller IDs */
		MIDIClient.sources.do{|item|
			if(item.name == "ActitioN MIDI Controller", {~footID = item.uid}); }; // foot controller
		MIDIClient.destinations.do{|item|
			if(item.name == "ActitioN MIDI Controller", {~footOutID = item.uid}); };
		MIDIClient.sources.do{|item|
			if(item.name == "APC MINI", {~apcID = item.uid}); }; // pad controller
		MIDIClient.destinations.do{|item|
			if(item.name == "APC MINI", {~apcOutID = item.uid}); };
		MIDIClient.sources.do{|item|
			if(item.name == "LPD8", {~lpdID = item.uid}); }; // keyboard controller
		MIDIClient.destinations.do{|item|
			if(item.name == "LPD8", {~lpdOutID = item.uid}); };

		/* set midi outputs */
		m = MIDIOut(0, ~apcOutID);
		f = MIDIOut(0, ~footOutID);
		l = MIDIOut(0, ~lpdOutID);
		"MIDIOut done".postln;

		/* APC slider controls */
		/* slider 1 */
		MIDIdef.cc(\slider1_button2, {
			arg num, id, chan, src;
			//[num, id, chan, src].postln;
			Ndef(\bar1SopRev).set(\vol, num.linlin(0, 127, 0, 1));
			Ndef(\bar1SopPan).set(\vol, num.linlin(0, 127, 0, 1));
		}, 48, srcID: ~apcID);

		MIDIdef.cc(\slider1_button9, {
			arg num, id, chan, src;
			//[num, id, chan, src].postln;
			Ndef(\bar12Playback).set(\amp, num.linlin(0, 127, 0, 1));
		}, 48, srcID: ~apcID);

		/* slider 2 */
		MIDIdef.cc(\slider2_button2, {
			arg num, id, chan, src;
			Ndef(\bar1SopRev).set(\vol, num.linlin(0, 127, 0, 1));
			Ndef(\bar1SopPan).set(\vol, num.linlin(0, 127, 0, 1));
		}, 49, srcID: ~apcID);

		MIDIdef.cc(\slider2_button10, {
			arg num, id, chan, src;
			Ndef(\panPiano).set(\vol, num.linlin(0, 127, 0, 1));
		}, 49, srcID: ~apcID);

		/* slider 3 */
		MIDIdef.cc(\slider3_button11, {
			arg num, id, chan, src;
			Ndef(\bar24Playback).set(\amp, num.linlin(0,127, 0, 1));
		}, 50, srcID: ~apcID);

		/* slider 4 */
		MIDIdef.cc(\slider4_button4, {
			arg num, id, chan, src;
			Ndef(\bar4Sop).set(\vol, num.linlin(0, 127, 0, 1));
		}, 51, srcID: ~apcID);

		MIDIdef.cc(\slider4_button12, {
			arg num, id, chan, src;
			Ndef(\bar27Playback).set(\amp, num.linlin(0, 127, 0, 1));
		}, 51, srcID: ~apcID);

		/* slider 5 */
		MIDIdef.cc(\slider5_button5, {
			arg num, id, chan, src;
			Ndef(\bar4spec).set(\vol, num.linlin(0, 127, 0, 1));
		}, 52, srcID: ~apcID);

		MIDIdef.cc(\slider5_button13, {
			arg num, id, chan, src;
			Ndef(\bar28Playback).set(\amp, num.linlin(0, 127, 0, 1));
		}, 52, srcID: ~apcID);

		/* slider 6 */
		MIDIdef.cc(\slider6_button6, {
			arg num, id, chan, src;
			Ndef(\grainSopLiveRec).set(\vol, num.linlin(0,127, 0, 1));
		}, 53, srcID: ~apcID);

		/* slider 7 */
		MIDIdef.cc(\slider7_button7, {
			arg num, id, chan, src;
			Ndef(\bar8Sop).set(\vol, num.linlin(0,127, 0, 1));
		}, 54, srcID: ~apcID);

		/* slider 8 */
		MIDIdef.cc(\slider8_button8, {
			arg num, id, chan, src;
			Ndef(\bar9Gran).set(\vol, num.linlin(0,127, 0, 1));
		}, 55, srcID: ~apcID);

		/* LPD knob 1 control panning */
		MIDIdef.cc(\lpdKnob1, {
			arg num, nn, chan, src;
			~panPianoWithSop.set(\pos, num.linlin(0, 127, 0, 2));
		}, 1, srcID: ~lpdID);


		//////////////////////////////////////// BEGIN /////////////////////////////////////////

		/* foot pedal control mapping */
		~midiMapFoot = {
			~countFt3 = 0;

			//////////////////// foot controller //////////////////// button 3 (98)
			MIDIdef.cc(\footButton3, {
				arg vel, nn, chan, src;
				if (~countFt3 == 0, {
					~bar4forSopB3 = Ndef(\bar4spec, ~bar4spec);
					~countFt3 = 1;
					"on foot button 3, 98".postln;
				}, {
					~bar4forSopB3.release(0);
					~countFt3 = 0;
					"off foot button 3, 98".postln;
				});
			}, 98, srcID: ~footID); // pedal button 98

		};

		/* trigger sound; APC */
		~midiMapApc = {
			~countApc1 = 0;
			~countApc2 = 0;
			~countApc3 = 0;
			~countApc4 = 0;
			~countApc5 = 0;
			~countApc6 = 0;
			~countApc7 = 0;
			~countApc8 = 0;
			~countApc9 = 0;
			~countApc10 = 0;
			~countApc11 = 0;
			~countApc12 = 0;
			~countApc13 = 0;

			//////////////////// bar 1 //////////////////// button 1
			MIDIdef.noteOn(\apcButton56, {
				arg vel, nn, chan, src;
				/* start recording into buffer */
				~recStart = {
					m.noteOn(0, 56, 03); // button color red
					/* record 1 */
					~bar1Rec = Synth(\SoundIn, [\bufnum, ~buf1]); // start recording (no playback)
					"recording".postln;
					~countApc1 = 1;
					~recording = true;
				};
				/* stop recording and free buffer */
				~recStop = {
					~bar1Rec.free; // stop synth for recording
					~buf1.free; // free buffer
					~recording = false;
					// realocate buffer to be recorded into again
					~waitForBufferReallocation = Routine {
						~buf1 = Buffer.alloc(s, 44100 * ~bufLength1, 1); // allocate buffer to record for 20 seconds for rec 1
						s.sync;
					}.value;
					"recording stopped, buffer reallocated".postln;
					~countApc1 = 0;
				};
				/* function to turn light off after recording */
				~recCompleteLightOff = {
					m.noteOn(0, 56, 0); // light off
					~recording = false;
					~countApc1 = 0;
				};

				/* button press for button 1 */
				/* record 20 seconds of soprano voice into ~buf through Shure SM57 dynamic mic */
				if (~countApc1 == 0, {
					// routine to start recording and turn light off after recording is completed
					~recRout = {
						~recStart.();
						"on 56 button 1".postln;
						~bufLength1.yield; // time when recording into buffer
						if(~recording, {
							"recording complete".postln;
							~recCompleteLightOff.();
							"off 56 button 1".postln;
						});
					}.fork;
				}, {
					//////////////////// bar 1 stop in the middle of recording and reallocate buffer for recording again // button 1 press again OFF
					if (~countApc1 == 1, {
						~recRout.stop; // stop routine for sanity
						~recStop.(); // call to stop recording and free buffer
						"off 56 button 1".postln;
						m.noteOn(0, 56, 0); // light off
					});
				});
			}, 56, srcID: ~apcID); // APC midi number 56

			//////////////////// bar 1 //////////////////// button 2
			MIDIdef.noteOn(\apcButton57, {
				arg vel, nn, chan, src;
				/* output soprano voice through speakers 1,2,3,4,5,6,7,8  */
				if (~countApc2 == 0, {
					~bar1Sop = Ndef(\bar1SopRev, ~bar1SopRev);
					~bar1Sop2 = Ndef(\bar1SopPan, ~bar1SopPan);
					m.noteOn(0, 57, 01); // light on
					"on 57 button 2".postln;
					~countApc2 = 1;
				}, {
					~bar1Sop.release(3);
					~bar1Sop2.release(3);
					m.noteOn(0, 57, 0); // light off
					"off 57 button 2".postln;
					~countApc2 = 0;
				});
			}, 57, srcID: ~apcID);

			//////////////////// bar 4 //////////////////// button 3
			MIDIdef.noteOn(\apcButton58, {
				arg vel, nn, chan, src;
				/* start recording into buffer 2 */
				~recStart2 = {
					m.noteOn(0, 58, 03); // button color red
					/* record 1 */
					~bar4Rec = Synth(\SoundIn, [\bufnum, ~buf2]); // start recording (no playback)
					"recording".postln;
					~countApc3 = 1;
					~recording2 = true;
				};
				/* stop recording and free buffer */
				~recStop2 = {
					~bar4Rec.free; // stop synth for recording
					~buf2.free; // free buffer
					~recording2 = false;
					// realocate buffer to be recorded into again
					~waitForBufferReallocation2 = Routine {
						~buf2 = Buffer.alloc(s, 44100 * ~bufLength2, 1); // allocate buffer to record for 20 seconds for rec 1
						s.sync;
					}.value;
					"recording stopped, buffer reallocated".postln;
					~countApc3 = 0;
				};
				/* function to turn light off after recording */
				~recCompleteLightOff2 = {
					m.noteOn(0, 58, 0); // light off
					~recording2 = false;
					~countApc3 = 0;
				};

				/* button press for button 3 */
				/* record 4 seconds of soprano voice into ~buf2 through Shure SM57 dynamic mic */
				if (~countApc3 == 0, {
					// routine to start recording and turn light off after recording is completed
					~recRout2 = {
						~recStart2.();
						"on 58 button 1".postln;
						~bufLength2.yield; // time when recording into buffer
						if(~recording2, {
							"recording complete".postln;
							~recCompleteLightOff2.();
							"off 58 button 3".postln;
						});
					}.fork;
				}, {
					//////////////////// bar 1 stop in the middle of recording and reallocate buffer for recording again // button 1 press again OFF
					if (~countApc3 == 1, {
						~recRout2.stop; // stop routine for sanity
						~recStop2.(); // call to stop recording and free buffer
						"off 58 button 1".postln;
						m.noteOn(0, 58, 0); // light off
					});
				});
			}, 58, srcID: ~apcID); // APC midi number 58

			//////////////////// bar 4 //////////////////// button 4
			MIDIdef.noteOn(\apcButton59, {
				arg vel, nn, chan, src;
				/* granularize rec 1 (recorded in ~buf) */
				if (~countApc4 == 0, {
					~bar4SopButton4 = Ndef(\bar4Sop, ~bar4Sop);
					m.noteOn(0, 59, 01); // light on
					"on 59, button 4".postln;
					~countApc4 = 1;
				}, {
					~bar4SopButton4.release(2);
					m.noteOn(0, 59, 0); // light off
					"off 59 button 4".postln;
					~countApc4 = 0;
				});
			}, 59, srcID: ~apcID);

			//////////////////// bar 4 //////////////////// button 5
			// *Note: this is identical to soprano b3; I can also control what needs to be done on button 5
			MIDIdef.noteOn(\apcButton60, {
				arg vel, nn, chan, src;
				/* granularize rec 1 (recorded in ~buf) */
				if (~countApc5 == 0, {
					~bar4forSopB3 = Ndef(\bar4spec, ~bar4spec);

					m.noteOn(0, 60, 01); // light on
					"on 60, button 5".postln;
					~countApc5 = 1;

				}, {
					~bar4forSopB3.release(0);
					m.noteOn(0, 60, 0); // light off
					"off 60 button 5".postln;
					~countApc5 = 0;
				});
			}, 60, srcID: ~apcID);

			//////////////////// bar 5 //////////////////// button 6
			/* granularize soprano live recording 2 (~buf2) */
			MIDIdef.noteOn(\apcButton61, {
				arg vel, nn, chan, src;
				/* granularize rec 1 (recorded in ~buf) */
				if (~countApc6 == 0, {
					~bar5GrainRec2 = Ndef(\grainSopLiveRec, ~grainSopLiveRec);
					Ndef(\grainSopLiveRec).set(\sndbuf, ~buf2);
					m.noteOn(0, 61, 01); // light on
					"on 61, button 6".postln;
					~countApc6 = 1;
				}, {
					~bar5GrainRec2.release(0);
					m.noteOn(0, 61, 0); // light off
					"off 61 button 6".postln;
					~countApc6 = 0;
				});
			}, 61, srcID: ~apcID);

			//////////////////// bar 8 //////////////////// button 7
			/* output soprano reverberation through speakers 1 and 2 */
			MIDIdef.noteOn(\apcButton62, {
				arg vel, nn, chan, src;
				if (~countApc7 == 0, {
					~bar8Sop = Ndef(\bar8Sop , ~bar8SopRev);
					m.noteOn(0, 62, 01); // light on
					"on 62, button 7".postln;
					~countApc7 = 1;
				}, {
					~bar8Sop.release(2);
					m.noteOn(0, 62, 0); // light off
					"off 62 button 7".postln;
					~countApc7 = 0;
				});
			}, 62, srcID: ~apcID);

			//////////////////// bar 9 //////////////////// button 8
			/* granularize soprano live recording 1 (~buf1) */
			MIDIdef.noteOn(\apcButton63, {
				arg vel, nn, chan, src;
				if (~countApc8 == 0, {
					~bar9Gran = Ndef(\bar9Gran, ~grainSopLiveRecBar9);
					m.noteOn(0, 63, 01); // light on
					"on 63, button 8".postln;
					~countApc8 = 1;
				}, {
					~bar9Gran.release(4);
					m.noteOn(0, 63, 0); // light off
					"off 63 button 8".postln;
					~countApc8 = 0;
				});
			}, 63, srcID: ~apcID);

			//////////////////// bar 12 //////////////////// button 9
			/* output recording 2 through speakers 1 and 2 */
			MIDIdef.noteOn(\apcButton40, {
				arg vel, nn, chan, src;
				if (~countApc9 == 0, {
					~bar12Playback = Ndef(\bar12Playback, ~bar12PlaybackRec2);
					Ndef(\bar12Playback).set(\bufnum, ~buf2);
					m.noteOn(0, 40, 01); // light on
					"on 64, button 9".postln;
					~countApc9 = 1;
				}, {
					~bar12Playback.release(0.2);
					m.noteOn(0, 40, 0); // light off
					"off 64 button 8".postln;
					~countApc9 = 0;
				});
			}, 40, srcID: ~apcID);

			//////////////////// bar 18//////////////////// button 10
			MIDIdef.noteOn(\apcButton41, {
				arg vel, nn, chan, src;
				if (~countApc10 == 0, {
					~panPianoWithSop = Ndef(\panPiano, ~panPiano).play;
					m.noteOn(0, 41, 01); // light on
					"on 41, button 10".postln;
					~countApc10 = 1;
				}, {
					~panPianoWithSop.release(1);
					m.noteOn(0, 41, 0); // light off
					"off 41 button 10".postln;
					~countApc10 = 0;
				});
			}, 41, srcID: ~apcID);

			//////////////////// bar 24//////////////////// button 11
			MIDIdef.noteOn(\apcButton42, {
				arg vel, nn, chan, src;
				if (~countApc11 == 0, {
					~bar24Playback = Ndef(\bar24Playback, ~bar24PlaybackRec2);
					Ndef(\bar24Playback).set(\bufnum, ~buf2);
					m.noteOn(0, 42, 01); // light on
					"on 42, button 11".postln;
					~countApc11 = 1;
				}, {
					~bar24Playback.release(0.2);
					m.noteOn(0, 42, 0); // light off
					"off 42 button 11".postln;
					~countApc11 = 0;
				});
			}, 42, srcID: ~apcID);

			//////////////////// bar 27//////////////////// button 12
			MIDIdef.noteOn(\apcButton43, {
				arg vel, nn, chan, src;
				if (~countApc12 == 0, {
					~bar27Playback = Ndef(\bar27Playback, ~bar27PlaybackRec2);
					Ndef(\bar27Playback).set(\bufnum, ~buf2);
					m.noteOn(0, 43, 01); // light on
					"on 43, button 12".postln;
					~countApc12 = 1;
				}, {
					~bar27Playback.release(0.2);
					m.noteOn(0, 43, 0); // light off
					"off 43 button 12".postln;
					~countApc12 = 0;
				});
			}, 43, srcID: ~apcID);

			//////////////////// bar 28//////////////////// button 13
			MIDIdef.noteOn(\apcButton44, {
				arg vel, nn, chan, src;
				if (~countApc13 == 0, {
					~bar28Playback = Ndef(\bar28Playback, ~bar28PlaybackRec2);
					Ndef(\bar28Playback).set(\bufnum, ~buf2);
					m.noteOn(0, 44, 01); // light on
					"on 44, button 13".postln;
					~countApc13 = 1;
				}, {
					~bar28Playback.release(0.2);
					m.noteOn(0, 44, 0); // light off
					"off 44 button 13".postln;
					~countApc13 = 0;
				});
			}, 44, srcID: ~apcID);

		};

		/* run mappings for controllers, and send on and off messages */
		// go APC mapping
		~midiMapApc.();
		// go foot pedal mapping
		~midiMapFoot.();
		"midiMap done".postln;
		"done!".postln;
	};
}.fork

)

//////////////////////////////////////// END ////////////////////////////////////////
