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
		_lp += (s - _lp) * 0.45
		_pb.push_frame(Vector2(_lp, _lp) * 0.35)
