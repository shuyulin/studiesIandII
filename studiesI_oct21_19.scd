
/* Studies I - for soprano, piano and electronics */
/* Oct 21, 2019 */

/* This script contains instructions to generate electronics part of the piece. Pianist will trigger using Akai MPK mini midi controller. Electronics performer will trigger using push button midi controllers, Akai APC mini. This piece will involve 9 speakers in which 2 will be placed beside the performers at the right and left of the stage. One speaker will be placed under the grand piano (piano needs to be opened to the largest without taking it apart). A dynamic microphone, Shure SM57, will be placed in front of the soprano in order to pick up vocal sound. A condenser microphoneo, Rode NT 5 (or Sontronics STC-10), will be placed beside the piano and aim into it. This microphone will be used to pick up piano resonances. */


//////////////////////////////////////// PREP ////////////////////////////////////////
/********* change input and ouput bus numbers/ channels *********/
/********* specify audio interface *********/

(
{
	/* start up file */
	Server.local.options.numOutputBusChannels = 9; // change number of input and output channels; 9 speakers for Studies I and II, the 9th will be placed aiming into piano
	Server.local.options.numInputBusChannels = 2;
	Server.internal.options.numOutputBusChannels = 9;
	Server.internal.options.numInputBusChannels = 2;
	Server.local.options.device = "MOTU 896mk3 Hybrid";

	{s.meter;}.defer; // make sure it has 0-9 channels
	MIDIClient.init;
	MIDIIn.connectAll;

	s.waitForBoot {

		"buffers".postln;

		/* allocate buffers */
		~bufLength = 20;
		~buf = Buffer.alloc(s, 44100 * ~bufLength, 1); // allocate buffer to record for 13 seconds for rec 1
		s.sync;
		"buffers done".postln;

		/* pick up mic 1 signal, modify amplitude etc for output */
		~inNdef1= {
			Ndef.ar(\micIn1, 1); // 1 input from 1 mic
			//Ndef(\micIn, { Compander.ar(SoundIn.ar(2), 0, 0.7, 0.5, 0.9, 0.01, 0.1, 0.5) });
			Ndef(\micIn1, { SoundIn.ar(0)}); // pick up from channel 0; change this based on tech setup
		};
		~inNdef1.(); // run SounIn ~inNdef globally

		/* pick up mic 2 signal, modify amplitude etc for output */
		~inNdef2 = {
			Ndef.ar(\micIn2, 1); // 2nd input from 2nd mic
			//Ndef(\micIn2, { Compander.ar(SoundIn.ar(3), 0, 0.5, 1, 1, 0.01, 0.1, 1) });
			Ndef(\micIn2, { SoundIn.ar(1)}); // pick up from channel 1; change this based on tech setup
		};
		~inNdef2.(); // run globally

		/* record soprano through Shure SM57 */
		SynthDef(\SoundIn, {
			var input, rec, bufnum = 0, recLevel = 1, preLevel = 0;
			input = SoundIn.ar(0); // to make sure it is recording use .poll
			rec = RecordBuf.ar(input, bufnum, 0, recLevel, preLevel, loop: 0, doneAction: 0);
		}).add;

		/* condenser mic aiming into piano */
		SynthDef(\SoundInAtPiano, {
			var input, rec, bufnum = 0, recLevel = 1, preLevel = 0;
			input = SoundIn.ar(1);
			rec = RecordBuf.ar(input, bufnum, 0, recLevel, preLevel, loop: 0, doneAction: 0);
		}).add;

		~grainSopLiveRec = {
			arg sndbuf, out, gate = 1, vol = 1, amp = 0.9, numChannels, trigger, dur, rate, pos, interp, pan, envbufnum, maxGrains;
			var env, signal;
			numChannels = 8;
			trigger = Impulse.ar(XLine.kr(800)); // this gives a swarm at the beginning
			dur = 1;
			rate = LFNoise1.kr.range(0.5, 2); // * -1 to playbackwards
			pos = SinOsc.ar(LFNoise1.kr(500));
			interp = 1;
			pan = SinOsc.kr(400);
			envbufnum = -1;
			maxGrains = 512;
			env = EnvGen.kr(Env.adsr, gate, levelScale: amp, doneAction: 2);
			signal = GrainBuf.ar(numChannels, trigger, dur, sndbuf, rate, pos, interp, pan, envbufnum, maxGrains) * env;
			Out.ar(0, signal * vol); // amplify (eg. *10 ) if signal is too soft from the dynamic mic
		};

		/* function to be used in bar 1 when pianist trigger pad 5 */
		~bar1IntoPiano = {
			arg out, gate = 1, vol = 1;
			var in, amp, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			amp = 0.7;
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(in, 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * amp * env);
			Out.ar(0, signal * vol); // change this to the 9th speaker (output channel 8)
		};

		/* function for bar 13; output soprano voice through speakers 7 8 */
		~bar13Sop = {
			arg out, gate = 1, vol = 1;
			var in, amp, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			amp = 0.8;
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(in, 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * amp * env);
			Out.ar([4, 5], signal * vol); // change this to 7 and 8 speaker (output channel [6, 7])
		};

		~bar14LeftToFront = {
			arg out, gate = 1, vol = 0.8;
			var in, amp, pan, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			in = Ndef.ar(\micIn1, 1); // pick up from mic 1 (for testing: in = ClipNoise.ar;)
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(CombN.ar(in, 0.8, 0.5, 6), 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * env);
			// use PanAz in the last bit of signal chain
			pan = (PanAz.ar(4, signal, LFSaw.kr(1), 0.3, 3)) * vol;
			Out.ar(4, pan[0]); // change the channel sequence if necessary, ch sequence depend on the speaker setup
			Out.ar(3, pan[1]);
			Out.ar(2, pan[2]);
			Out.ar(1, pan[3]);
		};

		~bar14RightToFront = {
			arg out, gate = 1, vol = 0.8;
			var in, amp, pan, signal, env;
			env = EnvGen.kr(Env.cutoff(0.5), gate, doneAction: 2);
			in = Ndef.ar(\micIn1, 1);
			signal = (FreeVerb.ar(FreeVerb.ar(Resonz.ar(CombN.ar(in, 0.8, 0.5, 6), 440, 1, 0.8), 0.3, 0.5, 1, 1), 0.3, 0.5, 1, 1) * env);
			// use PanAz in the last bit of signal chain
			pan = (PanAz.ar(4, signal, LFSaw.kr(1), 0.3, 3)) * vol;
			Out.ar(5, pan[0]); // change the channel sequence if necessary, ch sequence depend on the speaker setup
			Out.ar(6, pan[1]);
			Out.ar(7, pan[2]);
			Out.ar(8, pan[3]);
		};

		"func and def done".postln;

		/* get midi controller IDs */
		MIDIClient.sources.do{|item|
			if(item.name == "APC MINI", {~apcID = item.uid}); }; // pad controller
		MIDIClient.destinations.do{|item|
			if(item.name == "APC MINI", {~apcOutID = item.uid}); };
		MIDIClient.sources.do{|item|
			if(item.name == "MPKmini2", {~mpkID = item.uid}); }; // keyboard controller
		MIDIClient.destinations.do{|item|
			if(item.name == "MPKmini2", {~mpkOutID = item.uid}); };

		/* set midi outputs */
		a = MIDIOut(0, ~apcOutID);
		m = MIDIOut(0, ~mpkOutID);
		"MIDIOut done".postln;

		/* APC slider controls */
		/* slider 2 */
		MIDIdef.cc(\slider2_button2, {
			arg num, id, chan, src;
			Ndef(\bar13Sop).set(\vol, num.linlin(0,127, 0, 1));
		}, 49, srcID: ~apcID);

		/* slider 3 */
		MIDIdef.cc(\slider3_button3, {
			arg num, id, chan, src;
			Ndef(\bar14LeftToFront).set(\vol, num.linlin(0,127, 0, 1));
			Ndef(\bar14RightToFront).set(\vol, num.linlin(0,127, 0, 1));
		}, 50, srcID: ~apcID);

		/* slider 4 */
		MIDIdef.cc(\slider4_button4, {
			arg num, id, chan, src;
			Ndef(\grainSopLiveRec).set(\vol, num.linlin(0,127, 0, 1));
		}, 51, srcID: ~apcID);

		/* MPK knob 1 */
		MIDIdef.cc(\mpkKnob1, {
			arg num, nn, chan, src;
			Ndef(\bar1IntoPiano).set(\vol, num.linlin(0,127, 0, 1));
		}, 1, srcID: ~mpkIDsource);

		//////////////////////////////////////// BEGIN /////////////////////////////////////////

		/* Akai MPK mini 2 control mapping; trigger by pianist */
		~midiMapMpk = {
			//arg button, onFunc, offFunc;
			~countMpk1 = 0;
			~countMpk2 = 0;

			//////////////////// bar 1 //////////////////// MPK button 1
			MIDIdef.cc(\mpkButton24, {
				arg vel, nn, chan, src;

				/* button press for pad 5 on MPK */
				/* project soprano voice (pick up by Shure SM 57) into piano through speaker 9 (channel 8) */
				if (~countMpk1 == 0, {
					~bar1 = Ndef(\bar1IntoPiano, ~bar1IntoPiano);
					"on MPK cc 24, pad 5".postln;
					~countMpk1= 1;
				}, {
					~bar1.release(2);
					"off MPK cc 24, pad 5".postln;
					~countMpk1 = 0;
				});
			}, 24, srcID: ~mpkID); // MPK pad 5 midi number 24

		};

		/* trigger sound; APC */
		~midiMapApc = {
			~countApc1 = 0;
			~countApc2 = 0;
			~countApc3 = 0;
			~countApc4 = 0;

			//////////////////// bar 1 //////////////////// button 1
			MIDIdef.noteOn(\apcButton56, {
				arg vel, nn, chan, src;
				/* start recording into buffer */
				~recStart = {
					a.noteOn(0, 56, 03); // button color red
					/* record 1 */
					~bar1Rec = Synth(\SoundIn, [\buffer, ~buf]); //start recording (no playback)
					"recording".postln;
					~countApc1 = 1;
					~recording = true;
				};
				/* stop recording and free buffer */
				~recStop = {
					~bar1Rec.free; // stop synth for recording
					~buf.free; // free buffer
					~recording = false;
					// realocate buffer to be recorded into again
					~waitForBufferReallocation = Routine {
						~buf = Buffer.alloc(s, 44100 * ~bufLength, 1); // allocate buffer to record for 20 seconds for rec 1
						s.sync;
					}.value;
					"recording stopped, buffer reallocated".postln;
					~countApc1 = 0;
				};
				/* function to turn light off after recording */
				~recCompleteLightOff = {
					a.noteOn(0, 56, 0); // light off
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
						~bufLength.yield; // time when recording into buffer
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
						a.noteOn(0, 56, 0); // light off
					});
				});
			}, 56, srcID: ~apcID); // APC midi number 56

			//////////////////// bar 13 //////////////////// button 2
			MIDIdef.noteOn(\apcButton57, {
				arg vel, nn, chan, src;
				/* output soprano voice through speakers 7 8 */
				if (~countApc2 == 0, {
					~bar13 = Ndef (\bar13Sop, ~bar13Sop);
					a.noteOn(0, 57, 01); //light on
					"on 57 button 2".postln;
					~countApc2 = 1;
				}, {
					~bar13.release(2);
					a.noteOn(0, 57, 0); //light off
					"off 57 button 2".postln;
					~countApc2 = 0;
				});
			}, 57, srcID: ~apcID);

			//////////////////// bar 14 //////////////////// button 3
			MIDIdef.noteOn(\apcButton58, {
				arg vel, nn, chan, src;
				/* pan soprano voice from back speakers to front speakers */
				if (~countApc3 == 0, {
					~bar14Left = Ndef(\bar14LeftToFront, ~bar14LeftToFront);
					~bar14Right = Ndef(\bar14RightToFront, ~bar14RightToFront);
					a.noteOn(0, 58, 01); // light on
					~countApc3 = 1;
					"on 58 button 3".postln;
				}, {
					~bar14Left.release(3);
					~bar14Right.release(3);
					a.noteOn(0, 58, 0); // light off
					~countApc3 = 0;
					"off 58 button 3".postln;
				});
			}, 58, srcID: ~apcID);

			//////////////////// bar 15 //////////////////// button 4
			MIDIdef.noteOn(\apcButton59, {
				arg vel, nn, chan, src;
				/* granularize rec 1 (recorded in ~buf) */
				if (~countApc4 == 0, {
					~bar15GrainRec1 = Ndef(\grainSopLiveRec, ~grainSopLiveRec);
					Ndef(\grainSopLiveRec).set(\sndbuf, ~buf);
					a.noteOn(0, 59, 01); // light on
					"on 59, button 4".postln;
					~countApc4 = 1;
				}, {
					~bar15GrainRec1.release(2);
					a.noteOn(0, 59, 0); // light off
					"off 59 button 4".postln;
					~countApc4 = 0;
				});
			}, 59, srcID: ~apcID);

		};

		/* run mappings for controllers, and send on and off messages */
		// go APC mapping
		~midiMapApc.();
		// go MPK mapping
		~midiMapMpk.(); // run mapping function for MPK mini
		"midiMap done".postln;
		"done!".postln;
	};
}.fork

)

//////////////////////////////////////// END ////////////////////////////////////////
