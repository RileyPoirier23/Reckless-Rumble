## The counter's sounds, made in code like the engine's (render/engine_audio.gd): a horn out in
## the lot, the stamp coming down, paper on the desk, the wall clock, and the till when the
## Ministry or a supplier takes its cut. Each one is built once as a short 16-bit WAV and played
## through a handful of players. Quiet on purpose: it's a front counter, not an arcade.
class_name DeskAudio
extends Node

const RATE := 22050
## How loud each one plays (dB): the clock is the quietest thing in the room, the stamp the loudest.
const LEVEL := { "honk": -17.0, "stamp": -9.0, "paper": -17.0, "page": -15.0, "tick": -28.0, "tock": -29.0, "till": -13.0 }
const VOICES := 6

static var _bank := {}                 # name -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

## Play one of the sounds in LEVEL, a little louder or softer than usual if asked.
func play(sound_name: String, pitch := 1.0, gain_db := 0.0) -> void:
	if not LEVEL.has(sound_name) or _players.is_empty(): return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = sound(sound_name)
	p.volume_db = float(LEVEL[sound_name]) + gain_db
	p.pitch_scale = pitch
	p.play()

## The sound as a WAV, built the first time it's asked for.
static func sound(sound_name: String) -> AudioStreamWAV:
	if not _bank.has(sound_name):
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = RATE
		w.stereo = false
		w.data = _pcm(samples(sound_name))
		_bank[sound_name] = w
	return _bank[sound_name]

static func _pcm(s: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(s.size() * 2)
	for i in s.size(): b.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	return b

## The raw sound, -1 to 1 (the tests listen to these).
static func samples(sound_name: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound_name)
	match sound_name:
		"honk": return _honk()
		"stamp": return _stamp(rng)
		"paper": return _paper(rng, [[0.0, 0.11], [0.09, 0.27]], 0.0)
		"page": return _paper(rng, [[0.0, 0.18]], 0.2)
		"tick": return _tick(rng, 2400.0)
		"tock": return _tick(rng, 1750.0)
		"till": return _till(rng)
	return PackedFloat32Array()

static func _buf(seconds: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(seconds * RATE))
	return s

## Scale so the loudest sample sits at `peak`.
static func _level(s: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var top := 0.0
	for x in s: top = maxf(top, absf(x))
	if top > 0.0:
		for i in s.size(): s[i] = s[i] / top * peak
	return s

## Whoever's next in line, leaning on it: two blasts through the bay door's glass. Two flat
## notes a third apart, like every old car's (the engine's horn), with the top end gone.
static func _honk() -> PackedFloat32Array:
	var s := _buf(0.86)
	var blasts := [[0.0, 0.2], [0.31, 0.82]]
	var lp := 0.0
	var lp2 := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var env := 0.0
		for b in blasts:
			var on: float = clampf((t - float(b[0])) / 0.015, 0.0, 1.0) * clampf((float(b[1]) - t) / 0.04, 0.0, 1.0)
			env = maxf(env, on)
		var x := (signf(sin(TAU * 415.0 * t)) + signf(sin(TAU * 520.0 * t))) * 0.5 * env
		lp += (x - lp) * 0.16
		lp2 += (lp - lp2) * 0.3
		s[i] = lp2
	return _level(s, 0.7)

## The stamp coming down on the work order: a wooden knock and a low thud through the desk.
static func _stamp(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := _buf(0.26)
	var ph := 0.0
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var f := 55.0 + 95.0 * exp(-t / 0.025)
		ph += TAU * f / RATE
		var body := sin(ph) * exp(-t / 0.055)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.35
		var knock := lp * exp(-t / 0.016)
		var click := rng.randf_range(-1.0, 1.0) * exp(-t / 0.0015)
		s[i] = body * 0.9 + knock * 0.5 + click * 0.35
	return _level(s, 0.9)

## Paper sliding on paper: soft bumps of hiss with the bottom taken out. `thump` adds a book
## landing on the desk at the end.
static func _paper(rng: RandomNumberGenerator, bumps: Array, thump: float) -> PackedFloat32Array:
	var end := 0.0
	for b in bumps: end = maxf(end, float(b[1]))
	var s := _buf(end + (0.08 if thump > 0.0 else 0.02))
	var lp := 0.0
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var env := 0.0
		for b in bumps:
			var u: float = (t - float(b[0])) / (float(b[1]) - float(b[0]))
			if u > 0.0 and u < 1.0: env = maxf(env, sin(PI * u) * (0.6 + 0.4 * sin(PI * u * 3.0)))
		var n := rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * 0.08
		var x := (n - lp) * env * 0.6
		if thump > 0.0 and t > end - 0.02:
			var u2 := t - (end - 0.02)
			ph += TAU * 90.0 / RATE
			x += sin(ph) * exp(-u2 / 0.03) * thump * 2.0
		s[i] = x
	return _level(s, 0.6)

## The wall clock: a click and a little ping off the case.
static func _tick(rng: RandomNumberGenerator, ping: float) -> PackedFloat32Array:
	var s := _buf(0.04)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = rng.randf_range(-1.0, 1.0) * exp(-t / 0.0018) * 0.6 + sin(TAU * ping * t) * exp(-t / 0.007) * 0.5
	return _level(s, 0.5)

## The till: the drawer clunks out, the bell rings twice. Somebody just paid the Ministry.
static func _till(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := _buf(0.7)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.2
		var x := sin(TAU * 82.0 * t) * exp(-t / 0.045) * 0.6 + lp * exp(-t / 0.03) * 0.5
		for strike in [[0.06, 2093.0], [0.11, 2637.0]]:
			var u: float = t - float(strike[0])
			if u < 0.0: continue
			var f: float = strike[1]
			# a bell's partials aren't whole multiples: that's what makes it a bell
			x += (sin(TAU * f * u) * exp(-u / 0.3) + sin(TAU * f * 2.76 * u) * exp(-u / 0.12) * 0.4 + sin(TAU * f * 5.4 * u) * exp(-u / 0.06) * 0.2) * 0.35
		s[i] = x
	return _level(s, 0.8)
