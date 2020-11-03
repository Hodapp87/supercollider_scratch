(
var number;
number = 3.cubed
)

3.cubed
(
"Hello World!".postln;
)

// Variable 's' is automatically set to Server.local.
s.boot;
// s.quit;

x = {SinOsc.ar}.play;
x.free

(
f = { [SinOsc.ar(440, 0, 0.2), SinOsc.ar(442, 0, 0.2)] };
f.play;
)

cubed

{ SinOsc.ar(440.0, SinOsc.ar(31.0)) }.play

// Some dabbling with phase modulation synthesis (?):
(
z = {
	arg freq1 = 440, freq2 = 20;
	var sig;
	sig = SinOsc.ar(freq1, SinOsc.ar(freq2));
}.play;
)
z.set(\freq2, 30)

(
z = {
	arg freq1 = 440;
	var sig, freq2;
	freq2 = LFNoise0.kr(8).exprange(1, 1000);
	sig = SinOsc.ar(freq1, SinOsc.ar(freq2));
}.play;
)

// From tutorial 3
(
SynthDef.new(\pulseTest, {
	arg ampHz=4, fund=40, maxPartial=4, width=0.5;
	var amp1, amp2, freq1, freq2, sig1, sig2;
	// Amplitude: a pulse-wave, right-channel out of phase with
	// left, ~12% duty-cycle.
	amp1 = LFPulse.kr(ampHz, 0, 0.12) * 0.75;
	amp2 = LFPulse.kr(ampHz, 0.5, 0.12) * 0.75;
	// freq1 & freq2: generate random values, non-interpolated,
	// 4 times per second. They're uncorrelated with each other.
	// Those values are exponential from fund to fund*maxPartial,
	// rounded to the nearest multiple of 'fund'.
	freq1 = LFNoise0.kr(4).exprange(fund, fund*maxPartial).round(fund);
	freq2 = LFNoise0.kr(4).exprange(fund, fund*maxPartial).round(fund);
	// Add a random octave jump to each (8 and 6 times/second).
	// LFPulse.kr has add:1, so it equals either 1 or 2 - thus
	// either we keep this frequency, or double it (+1 octave).
	freq1 = freq1 * LFPulse.kr(8, add:1);
	freq2 = freq2 * LFPulse.kr(6, add:1);
	sig1 = Pulse.ar(freq1, width, amp1);
	sig2 = Pulse.ar(freq2, width, amp2);
	sig1 = FreeVerb.ar(sig1, 0.7, 0.8, 0.25);
	sig2 = FreeVerb.ar(sig2, 0.7, 0.8, 0.25);
	Out.ar(0, sig1);
	Out.ar(1, sig2);
}).add;
)

x = Synth.new(\pulseTest);
x.set(\ampHz, 4);
x.set(\width, 0.1);
x.set(\maxPartial, 10);
x.free

(
SynthDef.new(\phaseThing, {
	arg base_f = 300, side = 2, phase_f = 5;
	var sig, amp;
	amp = SinOsc.kr([phase_f, phase_f], [0.0, pi/2]);
	sig = SinOsc.ar([base_f - side, base_f + side]) * amp;
	Out.ar(0, sig);
}).add;
)
x = Synth.new(\phaseThing);
x.set(\side, 1, \phase_f, 2.0);
x.free;

s.meter

Env.new.plot

SystemClock.sched(5, { "hello".postln });

x = [6, 5, 4, 0.5, 10, 7].collect(_.squared)
x = [6, 5, 4, 0.5, 10, 7].collect({|s| s.squared})

f = {|x| x.squared};
f.value(5)
5.do(_.postln)

(
SynthDef.new(\windThing, {
	arg out_bus, amp=0.20, delay_base=0.02, lfreq=0.1;
	var sig, delays, amp2, lpf, qf;
	amp2 = LFNoise2.kr(lfreq).range(0.2, 0.8);
	lpf = LFNoise2.kr(lfreq).exprange(50, 1000);
	qf = LFNoise2.kr(lfreq).range(0.0, 3.0);
	sig = PinkNoise.ar(amp * amp2) ! 2;
	//sig = LPF.ar(sig, lpf);
	sig = BPF.ar(sig, lpf, qf);
	// Scale to (approx) +- 0.01, then bias to always positive
	delays = {LFNoise2.kr(lfreq, delay_base, 2*delay_base)} ! 2;
	//sig = FreeVerb.ar(sig, 0.7, 0.8, 0.25);
	sig = DelayN.ar(sig, delaytime: delays);
	Out.ar(out_bus, sig);
}).add;
)
x = Synth.new(\windThing, [\out_bus, 0, \amp, 0.1, \lfreq: 0.2]);
y = Synth.new(\windThing, [\out_bus, 0, \amp, 0.1, \lfreq: 0.1]);
z = Synth.new(\windThing, [\out_bus, 0, \amp, 0.1, \lfreq: 0.25]);
x.free; y.free; z.free;

s.scope;
s.meter;

(
SynthDef.new(\trainThing, {
	arg out_bus, freq = 1200, qf = 0.0005, gate = 0, delay = 0.0, env_delay = 0.0, amp = 1.0;
	var attack = Rand.new(1.0, 2.5);
	var sustain = Rand.new(1.0, 4.0);
	var level = Rand.new(0.1, 1.0);
	var env = Env.linen(attack, sustain, attack, level, -3.0);
	var sig = WhiteNoise.ar();
	var f2 = freq * LFNoise2.kr(5.0).range(0.95, 1.05);
	sig = Resonz.ar(sig, f2, qf) * 10;
	// TODO: Is there a better way to get that 'ringing' sort of sound?
	sig = DelayN.ar(sig, delaytime: [0.max(delay), 0.max(delay.neg)]);
	sig = FreeVerb.ar(sig, 0.95, 1.0, 0.25) * env.delay(env_delay).kr(doneAction: 2, gate: 1);
	// TODO: Why must I use the envelope on FreeVerb to avoid
	// the clicks at the end?
	Out.ar(out_bus, sig * amp);
}).add;
)
x = Synth.new(\trainThing, [\out_bus, 0, \freq, exprand(1000, 8000), \delay, rand(-0.1, 0.1), \gate, 1]);
x.set(\gate, 0);
x.free;

// Some dabbling with a Routine, but it forces sequential (ish):
(
x = Routine({
	loop({
		Synth.new(\trainThing, [\out_bus, 0, \freq, exprand(1000, 8000), \delay, rand(-0.1, 0.1), \gate, 1]);
		5.wait;
	})
}).play
)
// how do I stop this?

(
var pb = Pbind(
	\instrument, \trainThing,
	\out_bus, 0,
	\dur, Pfunc({rrand(0.25, 4.0)}),
	\env_delay, Pfunc({rrand(0.0, 5.0)}),
	\delay, rand(-0.1, 0.1),
	\freq, Pfunc({exprand(1000, 8000)}),
	\amp, Pfunc({rrand(0.0, 0.5)}),
);
var player = pb.play;
//s.record(duration: 60);
)
// TODO: Why does this fail to work right if I re-enable
// the gate in the args?
// TODO: How do I stop this?

//thisProcess.platform.recordingsDir
