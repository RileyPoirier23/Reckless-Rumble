## Engine sound, made live from the sim, on its own thread (a sample loop in script is a few
## milliseconds a frame: off the main thread it costs the game nothing).
##
## The engine is its firings: every power stroke is a pulse of exhaust (a thump of pipe
## resonance with a burst of noise) that rings down before the next, so at idle a four-cylinder
## chugs and a V8 lopes, and as the revs climb the pulses run together into a note. The
## throttle sharpens and loudens the pulses (and opens the intake roar), a lift off the gas at
## revs pops and crackles, the limiter cuts the fuel in a stutter, a hurt engine misfires, a
## turbo whistles with boost and sighs when the throttle shuts. Plus the horn, other people's
## horns, a siren, the blinker relay and tire squeal, as before.
class_name EngineAudio
extends AudioStreamPlayer

const RATE := 22050.0
var sim: CarSim:
	set(v):
		sim = v
		if v != null:
			var lay := String((v.spec.engine as Dictionary).get("layout", ""))
			var digits := lay.lstrip("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
			cylinders = clampi(int(digits), 1, 16) if digits.is_valid_int() else 4
			electric = bool((v.spec.engine as Dictionary).get("electric", false)) or lay.begins_with("E")
			var cc := int((v.spec.engine as Dictionary).get("cc", 2000))
			# the pipe's note: big engines boom low, little ones bark
			_pipe_hz = clampf(170.0 - cc / 1000.0 * 18.0, 70.0, 160.0)
			_limiter = float((v.spec.engine as Dictionary).get("limiter_rpm", 6500.0))
			_idle = float((v.spec.engine as Dictionary).get("idle_rpm", 800.0))
var cylinders := 4
var electric := false
var throttle := 0.0
var horn := false
var tick := 0.0               # blinker relay clicks (set to 1.0 for one click)
var siren := 0.0              # how loud the nearest siren is (0 none .. 1 right on you)

# --- what the thread reads (copied under the lock once a frame)
var _lock := Mutex.new()
var _p := { "rpm": 0.0, "throttle": 0.0, "boost": 0.0, "slip": 0.0, "rough": 0.0, "running": false,
	"shifting": false, "horn": false, "siren": 0.0, "tick": 0.0, "honks": [] }
var _pipe_hz := 120.0
var _limiter := 6500.0
var _idle := 800.0

# --- the synth's own state (thread only)
var _rng := RandomNumberGenerator.new()
var _phase := 0.0             # firing phase 0..1
var _env := 0.0               # the current pulse's loudness, ringing down
var _env_noise := 0.0
var _pipe_p := 0.0
var _cut_n := 0               # limiter stutter counter
var _pop_t := 0.0             # seconds of lift-off crackle left
var _bov_t := 0.0             # blow-off sigh left
var _last_th := 0.0
var _last_boost := 0.0
var _roar := 0.0              # intake noise filter state
var _roar2 := 0.0
var _whistle := 0.0
var _whine := 0.0
var _squeal := 0.0
var _lp := 0.0
var _lp2 := 0.0
var _horn_a := 0.0
var _horn_b := 0.0
var _horn_env := 0.0
var _tick := 0.0
var _honks: Array = []        # other people's horns: [samples left, pitch, gain, phase a, phase b]
var _siren_p := 0.0
var _siren_t := 0.0
var _pb: AudioStreamGeneratorPlayback
var _thread: Thread
var _quit := false
var _buf := PackedVector2Array()

## Somebody else leans on their horn `dist` metres away: a short blast, quieter with distance, at
## their car's pitch (every make a little different).
func honk(dist: float, pitch := 1.0, secs := 0.45) -> void:
	var gain := clampf(1.0 - dist / 90.0, 0.0, 1.0)
	if gain <= 0.02: return
	_lock.lock()
	if (_p.honks as Array).size() < 4: (_p.honks as Array).append([int(secs * RATE), pitch, gain * gain, 0.0, 0.0])
	_lock.unlock()

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.12
	stream = gen
	volume_db = -8.0
	play()
	_pb = get_stream_playback()
	if _pb != null and not Engine.is_editor_hint():
		_thread = Thread.new()
		_thread.start(_run)

func _exit_tree() -> void:
	_stop_thread()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE: _stop_thread()

func _stop_thread() -> void:
	if _thread == null: return
	_lock.lock()
	_quit = true
	_lock.unlock()
	if _thread.is_started(): _thread.wait_to_finish()
	_thread = null

## Once a frame: hand the thread what the engine's doing.
func _process(_dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_lock.lock()
	if sim != null:
		_p.rpm = sim.rpm
		_p.throttle = throttle
		_p.boost = sim.boost
		var slip := 0.0
		for s in sim.wheel_slip: slip = maxf(slip, s)
		_p.slip = slip
		_p.rough = 1.0 - sim.engine_health
		_p.running = not sim.engine_blown and not sim.stalled
		_p.shifting = sim.shift_timer > 0.0
	else:
		_p.running = false
		_p.slip = 0.0
	_p.horn = horn
	_p.siren = siren
	if tick > 0.0:
		_p.tick = tick
		tick = 0.0
	_lock.unlock()
	Prof.lap('render_engine_audio_process', _t0)

func _run() -> void:
	while true:
		_lock.lock()
		var quit := _quit
		var p := _p.duplicate()
		_p.tick = 0.0
		_p.honks = []
		_lock.unlock()
		if quit: return
		for hk in p.honks: _honks.append(hk)
		var n := _pb.get_frames_available()
		if n > 0: _fill(mini(n, 2048), p)
		OS.delay_msec(4)

## `n` samples of everything, into the player.
func _fill(n: int, p: Dictionary) -> void:
	synth(n, p)
	_pb.push_buffer(_buf)

## `n` samples into `_buf` (what the thread runs; a test can run it without a player).
func synth(n: int, p: Dictionary) -> void:
	if _buf.size() != n: _buf.resize(n)
	var rpm: float = p.rpm
	var th: float = p.throttle
	var boost: float = p.boost
	var running: bool = p.running
	var rough: float = p.rough
	var f := rpm / 60.0 * cylinders / 2.0          # firings a second
	var load := 0.3 + 0.7 * th
	# a pulse rings down before the next one: distinct chugs at idle, a note at revs
	var tau := clampf(0.38 / maxf(f, 1.0), 0.004, 0.035)
	var decay := exp(-1.0 / (tau * RATE))
	var pipe_step := _pipe_hz / RATE
	var pipe2_step := (_pipe_hz * 1.5 + f * 0.5) / RATE
	# idle lumps: at idle every firing's a little different; wound up they're all alike
	var jitter := lerpf(0.5, 0.08, clampf((rpm - _idle) / 2200.0, 0.0, 1.0))
	# off the gas at revs: pops and crackles out the pipe for a moment
	if _last_th > 0.5 and th < 0.15 and rpm > 3200.0: _pop_t = 0.7
	_last_th = th
	# the turbo's blow-off: the throttle shuts on boost and the pressure sighs out
	if _last_boost > 0.45 and th < 0.2 and boost < _last_boost: _bov_t = 0.3
	_last_boost = boost
	var at_limiter := rpm >= _limiter - 30.0
	var squeal_amp := clampf((float(p.slip) - 2.0) / 8.0, 0.0, 0.6)
	var whistle_f := 1800.0 + boost * 4200.0
	var lp_k := lerpf(0.22, 0.55, th)              # the throttle opens the sound up
	var roar_amp := th * clampf(rpm / 6000.0, 0.15, 1.0) * 0.22
	var siren_v: float = p.siren
	var horn_on: bool = p.horn
	if float(p.tick) > 0.0: _tick = float(p.tick)
	var whine_f := 240.0 + rpm * 0.32
	for i in n:
		var s := 0.0
		if running and not electric:
			_phase += f / RATE
			if _phase >= 1.0:
				_phase -= 1.0
				# a firing
				var amp := (0.5 + 0.5 * load) * (1.0 + jitter * (_rng.randf() - 0.5))
				if bool(p.shifting): amp *= 0.2
				if at_limiter:
					_cut_n += 1
					if _cut_n % 3 != 0: amp *= 0.08       # the fuel cut: bap-bap-bap
				if rough > 0.2 and _rng.randf() < rough * 0.08: amp *= 0.05   # a misfire
				var noise_k := 0.45 + 0.4 * th
				if _pop_t > 0.0 and _rng.randf() < 0.12:
					amp = 1.1
					noise_k = 1.4
				_env = amp
				_env_noise = amp * noise_k
			_env *= decay
			_env_noise *= decay
			_pipe_p = fmod(_pipe_p + pipe_step, 1.0)
			var pipe := sin(_pipe_p * TAU) * 0.7 + sin(fmod(_pipe_p * 2.0 + 0.3, 1.0) * TAU) * 0.22 + sin(_pipe_p * TAU * 3.0) * 0.1
			s = _env * pipe * 0.9 + (_rng.randf() - 0.5) * _env_noise * 0.8
			# the note itself, under the pulses (keeps the pitch readable when they blur together)
			var pp := _phase * TAU
			s += (sin(pp) * 0.3 + sin(pp * 2.0) * 0.14 * load + (fmod(_phase, 1.0) - 0.5) * 0.2 * load) * 0.5
			# intake roar: noise through a soft filter, wide open on the throttle
			_roar += ((_rng.randf() - 0.5) - _roar) * 0.35
			_roar2 += (_roar - _roar2) * 0.5
			s += _roar2 * roar_amp * 2.2
		elif running and electric:
			# the motor's whine and the inverter's buzz, climbing with the speed, quiet
			_whine = fmod(_whine + whine_f / RATE, 1.0)
			s = sin(_whine * TAU) * 0.08 * (0.3 + th) + sin(_whine * TAU * 3.0) * 0.025 * th + (_rng.randf() - 0.5) * 0.02 * th
		_whistle = fmod(_whistle + whistle_f / RATE, 1.0)
		s += sin(_whistle * TAU) * 0.05 * boost
		if _bov_t > 0.0:
			s += (_rng.randf() - 0.5) * 0.35 * minf(1.0, _bov_t / 0.3)
			_bov_t -= 1.0 / RATE
		if _pop_t > 0.0: _pop_t -= 1.0 / RATE
		# tire squeal
		_squeal = fmod(_squeal + (680.0 + _rng.randf() * 60.0) / RATE, 1.0)
		s += sin(_squeal * TAU) * squeal_amp * 0.35 + (_rng.randf() - 0.5) * squeal_amp * 0.25
		# the horn: two flat notes a third apart, like every old car's
		_horn_env = move_toward(_horn_env, 1.0 if horn_on else 0.0, 1.0 / (RATE * 0.02))
		if _horn_env > 0.0:
			_horn_a = fmod(_horn_a + 415.0 / RATE, 1.0)
			_horn_b = fmod(_horn_b + 520.0 / RATE, 1.0)
			s += (signf(sin(_horn_a * TAU)) * 0.5 + signf(sin(_horn_b * TAU)) * 0.5) * 0.22 * _horn_env
		# other people's horns, out there somewhere
		for k in range(_honks.size() - 1, -1, -1):
			var hk: Array = _honks[k]
			hk[3] = fmod(float(hk[3]) + 440.0 * float(hk[1]) / RATE, 1.0)
			hk[4] = fmod(float(hk[4]) + 554.0 * float(hk[1]) / RATE, 1.0)
			var env := minf(1.0, float(hk[0]) / (RATE * 0.03))
			s += (signf(sin(float(hk[3]) * TAU)) * 0.5 + signf(sin(float(hk[4]) * TAU)) * 0.5) * 0.14 * float(hk[2]) * env
			hk[0] = int(hk[0]) - 1
			if int(hk[0]) <= 0: _honks.remove_at(k)
		# a siren somewhere: the wail, rising and falling every four seconds, square-ish like a horn speaker
		if siren_v > 0.01:
			_siren_t = fmod(_siren_t + 1.0 / RATE, 4.0)
			var sweep := 0.5 - 0.5 * cos(_siren_t / 4.0 * TAU)
			_siren_p = fmod(_siren_p + (620.0 + sweep * 780.0) / RATE, 1.0)
			s += clampf(sin(_siren_p * TAU) * 1.8, -1.0, 1.0) * 0.16 * siren_v * siren_v
		if _tick > 0.0:
			s += (_rng.randf() - 0.5) * _tick * 0.8
			_tick = maxf(0.0, _tick - 1.0 / (RATE * 0.006))
		# the body of the car and the air between: two soft poles
		_lp += (s - _lp) * lp_k
		_lp2 += (_lp - _lp2) * 0.7
		var o := clampf(_lp2 * 0.42, -0.95, 0.95)
		_buf[i] = Vector2(o, o)
