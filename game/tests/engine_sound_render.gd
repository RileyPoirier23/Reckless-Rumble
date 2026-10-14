## Renders the engine synth offline, to look at (and listen to):
##   godot --headless --path game -s tests/engine_sound_render.gd -- <out_dir>
## A few seconds each of a four and a V8: idle, half throttle at 3000, flat out on the limiter,
## a lift off the gas. Writes <name>.wav and prints the loudness of every tenth of a second.
extends SceneTree

func _init() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	for layout in ["I4", "V8"]:
		var a := EngineAudio.new()
		a.cylinders = int(layout.substr(1))
		a._pipe_hz = 150.0 if layout == "I4" else 95.0
		a._limiter = 6800.0
		a._idle = 800.0
		var frames := PackedFloat32Array()
		var stages := [[800.0, 0.0, 1.5, "idle"], [3000.0, 0.5, 1.5, "cruise"], [6800.0, 1.0, 1.2, "limiter"], [5000.0, 0.0, 1.0, "lift"]]
		var pos := 0
		for st in stages:
			var n := int(float(st[2]) * EngineAudio.RATE)
			var p := { "rpm": st[0], "throttle": st[1], "boost": 0.0, "slip": 0.0, "rough": 0.0, "running": true,
				"shifting": false, "horn": false, "siren": 0.0, "tick": 0.0, "honks": [] }
			var done := 0
			var loud: Array = []
			while done < n:
				var k := mini(2205, n - done)
				a.synth(k, p)
				var rms := 0.0
				var peak := 0.0
				for i in k:
					var v: float = a._buf[i].x
					frames.append(v)
					rms += v * v
					peak = maxf(peak, absf(v))
				loud.append("%.2f/%.2f" % [sqrt(rms / k), peak])
				done += k
			print("%s %s: rms/peak per 0.1 s: %s" % [layout, st[3], " ".join(loud)])
			pos += n
		# chop at idle: how many quiet gaps between pulses in the first half second
		var gaps := 0
		var quiet := false
		for i in int(0.5 * EngineAudio.RATE):
			var q := absf(frames[i]) < 0.03
			if q and not quiet: gaps += 1
			quiet = q
		print("%s idle: %d quiet gaps in 0.5 s (firings expected: %.0f)" % [layout, gaps, 800.0 / 60.0 * a.cylinders / 2.0 * 0.5])
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = int(EngineAudio.RATE)
		wav.stereo = false
		var bytes := PackedByteArray()
		bytes.resize(frames.size() * 2)
		for i in frames.size(): bytes.encode_s16(i * 2, int(clampf(frames[i], -1.0, 1.0) * 32767.0))
		wav.data = bytes
		wav.save_to_wav(out.path_join("engine_%s.wav" % layout))
		a.free()
	quit()
