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
	arg out_bus, amp=0.20, delay_base=0.02, lfreq=0.1, qf=2.0;
	var sig, delays, amp2, lpf, qf;
	amp2 = LFNoise2.kr(lfreq).range(0.2, 0.8);
	lpf = LFNoise2.kr(lfreq).exprange(50, 1000);
	//qf = LFNoise2.kr(lfreq).range(0.0, 3.0);
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
Window.closeAll;
w = Window.new("Foo", Rect(200,200,255,100)).front;
w.view.decorator = FlowLayout(w.view.bounds);
s = Slider(w, 150@20);
s.action = { x.set(\amp, s.value) };
f = Slider(w, 150@20);
f.action = { x.set(\lfreq, f.value * 10) };
d = Slider(w, 150@20);
d.action = { x.set(\delay_base, (f.value - 0.5) / 2.5) };
q = Slider(w, 150@20);
q.action = { x.set(\qf, q.value) };
w.front;
)

(
SynthDef.new(\sine, {
	arg freq=440, atk=0.005, rel=0.3, amp=1, pan=0;
	var sig, env;
	sig = LFTri.ar(freq);
	env = EnvGen.kr(Env.new([0,1,0], [atk,rel], [1,-1]), doneAction: 2);
	sig = Pan2.ar(sig, pan, amp);
	sig = sig*env;
	Out.ar(0, sig);
}).add;
)

(
//s.record(duration: 60);
Pdef(
	\sinepat,
	Pbind(
		\instrument, \sine,
		\dur, Pwhite(0.1, 0.2, inf).round(0.05),
		// \state is used by nothing directly, but I guess I
		// can still refer to it via Pkey
		\state, Pseq([0, 12], inf).trace(prefix: "s "),
		\midinote,
		Pxrand(
		    [Pseq([44, 45, 47, 48, 50, 51, 53, 54]),
			 //Pseq([45, 50]),
			 //Pseq([44, 49]),
			],
			inf,
		) + Pkey(\state),
		//\harmonic, Pexprand(1, 20, inf).round.trace,
		//\harmonic, Pxrand([1,2,4,8,16,32], inf).trace(prefix: "harmonic "),
		\harmonic, Pxrand([1, 2, 3, 4], inf).trace(prefix: "h "),
		\atk, Pwhite(0.01, 0.10, inf),
		\rel, Pwhite(0.5, 1.0, inf),
		\amp, Pkey(\harmonic).reciprocal * 0.3,
		\pan, Pwhite(-0.8, 0.8, inf),
	);
).play;
)

Pdef(\sinepat).stop