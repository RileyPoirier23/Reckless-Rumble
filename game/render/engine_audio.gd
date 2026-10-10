## Engine sound, made live from the sim: firing pulses at the engine's rpm, intake roar with
## throttle, a turbo whistle with boost, and tire squeal when the tires slide.
class_name EngineAudio
extends AudioStreamPlayer

const RATE := 22050.0
var sim: CarSim
var cylinders := 4
var _phase := 0.0
var _whistle := 0.0
var _squeal := 0.0
var _lp := 0.0
var _rng := RandomNumberGenerator.new()
var _pb: AudioStreamGeneratorPlayback
var throttle := 0.0
var horn := false
var _horn_a := 0.0
var _horn_b := 0.0
var _horn_env := 0.0
var tick := 0.0               # blinker relay clicks (set to 1.0 for one click)
var siren := 0.0              # how loud the nearest siren is (0 none .. 1 right on you)
var _siren_p := 0.0
var _siren_t := 0.0

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.12
	stream = gen
	volume_db = -8.0
	play()
	_pb = get_stream_playback()

func _process(_dt: float) -> void:
	if sim == null or _pb == null: return
	var n := _pb.get_frames_available()
	if n <= 0: return
	var running := not sim.engine_blown
	var f := sim.rpm / 60.0 * cylinders / 2.0          # firing frequency
	var load := 0.35 + 0.65 * throttle
	var slip := 0.0
	for s in sim.wheel_slip: slip = maxf(slip, s)
	var squeal_amp := clampf((slip - 2.0) / 8.0, 0.0, 0.6)
	var whistle_f := 1800.0 + sim.boost * 4200.0
	var rough := 1.0 - sim.engine_health                # a hurt engine misfires
	for i in n:
		var s := 0.0
		if running:
			_phase = fmod(_phase + f / RATE, 1.0)
			var p := _phase * TAU
			s = sin(p) * 0.55 + sin(p * 2.0) * 0.3 * load + sin(p * 3.0 + 0.4) * 0.18 + (fmod(_phase, 1.0) - 0.5) * 0.35 * load
			s += (_rng.randf() - 0.5) * 0.25 * throttle
			if rough > 0.2 and _rng.randf() < rough * 0.02: s *= 0.1   # misfire
		_whistle = fmod(_whistle + whistle_f / RATE, 1.0)
		s += sin(_whistle * TAU) * 0.05 * sim.boost
		_squeal = fmod(_squeal + (680.0 + _rng.randf() * 60.0) / RATE, 1.0)
		s += sin(_squeal * TAU) * squeal_amp * 0.35 + (_rng.randf() - 0.5) * squeal_amp * 0.25
		# the horn: two flat notes a third apart, like every old car's
		_horn_env = move_toward(_horn_env, 1.0 if horn else 0.0, 1.0 / (RATE * 0.02))
		if _horn_env > 0.0:
			_horn_a = fmod(_horn_a + 415.0 / RATE, 1.0)
			_horn_b = fmod(_horn_b + 520.0 / RATE, 1.0)
			s += (signf(sin(_horn_a * TAU)) * 0.5 + signf(sin(_horn_b * TAU)) * 0.5) * 0.22 * _horn_env
		# a siren somewhere: the wail, rising and falling every four seconds, square-ish like a horn speaker
		if siren > 0.01:
			_siren_t = fmod(_siren_t + 1.0 / RATE, 4.0)
			var sweep := 0.5 - 0.5 * cos(_siren_t / 4.0 * TAU)
			_siren_p = fmod(_siren_p + (620.0 + sweep * 780.0) / RATE, 1.0)
			s += clampf(sin(_siren_p * TAU) * 1.8, -1.0, 1.0) * 0.16 * siren * siren
		if tick > 0.0:
			s += (_rng.randf() - 0.5) * tick * 0.8
			tick = maxf(0.0, tick - 1.0 / (RATE * 0.006))
		_lp += (s - _lp) * 0.45
		_pb.push_frame(Vector2(_lp, _lp) * 0.35)
