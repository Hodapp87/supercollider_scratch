s.boot;

(
SynthDef.new(\trainThing, {
	// Arguments:
	// out_bus -- output bus
	// gate -- gate of envelope
	// amp -- amplitude
	// freq -- base frequency of filter
	// qf -- bandwidth of filter
	// lr_delay -- relative left/right delay; keep in about [-0.2, 0.2]
	// env_delay -- delay of envelope's start (mostly applicable when
	//     using this in a larger setup)
	|out_bus, freq = 1200, gate = 1, amp = 1.0, qf = 0.0005, lr_delay = 0.0, env_delay = 0.0|
	// Envelope parameters are randomized:
	var attack = Rand.new(1.0, 2.5);
	var sustain = Rand.new(1.0, 4.0);
	var level = Rand.new(0.1, 1.0);
	var env = Env.linen(attack, sustain, attack, level, -3.0);
	// Base signal is white noise, but run through a resonant
	// filter whose frequency is varies +- 5%:
	var sig = WhiteNoise.ar();
	var f2 = freq * LFNoise2.kr(5.0).range(0.95, 1.05);
	sig = Resonz.ar(sig, f2, qf) * 10;
	// TODO: Is there a better way to get that 'ringing' sort of sound?
	// Resonz with a very tiny bandwidth gets the right sound, but
	// I then have to amplify it considerably.  Perhaps this is an
	// artifact of starting from white noise.
	//
	// Delay left or right channel to add a little directionality:
	sig = DelayN.ar(sig, delaytime: [0.max(lr_delay), 0.max(lr_delay.neg)]);
	// TODO: Letting this delay change through the course of the
	// envelope might add some motion to the directionality.  Could
	// be interesting.
	//
	// And finally, apply reverb and envelope. Reverb is purposely
	// pretty heavy/distant.
	sig = FreeVerb.ar(sig, 0.95, 1.0, 0.25) * env.kr(doneAction: 2, gate: 1);
	// TODO: Why must I use the envelope on FreeVerb (rather than
	// on any other prior UGen) to avoid the clicks at the end?
	Out.ar(out_bus, sig * amp);
}).add;
)

// Run a continuous stream of them, but with random frequencies
// and timing.
(
Pdef(\trainsAmbient, Pbind(
	\instrument, \trainThing,
	\out_bus, 0,
	\dur, Pfunc({rrand(0.25, 4.0)}),
	\freq, Pfunc({exprand(1000, 8000)}),
	\amp, Pfunc({rrand(0.0, 0.5)}),
	\env_delay, Pfunc({rrand(0.0, 5.0)}),
	\lr_delay, rand(-0.1, 0.1),
));
Pdef(\trainsAmbient).play;
)
// TODO: Why does this fail to work right if I re-enable
// the gate in the args?  I'm missing something.

//thisProcess.platform.recordingsDir
//s.record(duration: 60);

Pdef(\trainsAmbient).stop;
