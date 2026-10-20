## Frame-time probe, in the drive scene: xvfb-run godot --path game -- --perf-probe
## Drives through downtown (day, then night) and prints frame, process, physics and draw-call
## numbers. PERF_OFF=traffic,lights,parked,furniture,wild,incidents,veg turns systems off;
## PERF_AT=x,y,heading_deg picks the spot; PERF_SECS the run length.
extends Node

var main: Node

func _ready() -> void:
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	var off: Array = OS.get_environment("PERF_OFF").split(",") if OS.get_environment("PERF_OFF") != "" else []
	if "traffic" in off: main.traffic.enabled = false
	if "parked" in off: main.parked.visible = false
	if "lights" in off: main.lights.visible = false
	if "furniture" in off and main.get("furniture"): main.furniture.visible = false
	if "wild" in off and main.get("wildlife"): main.wildlife.visible = false
	var secs := float(OS.get_environment("PERF_SECS")) if OS.get_environment("PERF_SECS") != "" else 12.0
	var at := Vector2(6310, 1495)
	var hd := PI
	if OS.get_environment("PERF_AT") != "":
		var sp := OS.get_environment("PERF_AT").split(",")
		at = Vector2(float(sp[0]), float(sp[1]))
		hd = deg_to_rad(float(sp[2])) if sp.size() > 2 else 0.0
	var hide: Array = OS.get_environment("PERF_HIDE").split(",") if OS.get_environment("PERF_HIDE") != "" else []
	var nights: Array = [false, true] if OS.get_environment("PERF_NIGHT") != "0" else [false]
	# PERF_GARAGE=1: open the garage on the save as it is, time it, screenshot it, quit
	if OS.get_environment("PERF_GARAGE") != "":
		var t0 := Time.get_ticks_usec()
		main.garage.open(main.save)
		print("GARAGE open() %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		t0 = Time.get_ticks_usec()
		Prof.reset()
		Prof.on = true
		main.garage._preview_box()
		print("GARAGE _preview_box() %.0f ms: %s" % [(Time.get_ticks_usec() - t0) / 1000.0, Prof.report(1)])
		Prof.reset()
		t0 = Time.get_ticks_usec()
		main.garage._draw_cars()
		print("GARAGE _draw_cars() %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		t0 = Time.get_ticks_usec()
		Prof.reset()
		Prof.on = true
		await get_tree().process_frame
		print("GARAGE first frame %.0f ms: %s" % [(Time.get_ticks_usec() - t0) / 1000.0, Prof.report(12)])
		Prof.reset()
		t0 = Time.get_ticks_usec()
		await get_tree().process_frame
		print("GARAGE opened with %d cars in %.0f ms: %s" % [(main.save.garage as Array).size(), (Time.get_ticks_usec() - t0) / 1000.0, Prof.report(12)])
		for i in 3:
			var t1 := Time.get_ticks_usec()
			await get_tree().process_frame
			print("GARAGE frame %.0f ms" % ((Time.get_ticks_usec() - t1) / 1000.0))
		if OS.get_environment("PERF_SHOT") != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("PERF_SHOT"))
		get_tree().quit()
		return
	for night in nights:
		main.sky.time_h = 22.0 if night else 13.0
		main._teleport(at, hd)
		await _wait(1.5)
		Input.action_press("throttle")
		Prof.reset()
		Prof.on = true
		var frames := 0
		var t0 := Time.get_ticks_usec()
		var worst := 0.0
		var proc := 0.0
		var phys := 0.0
		var draws := 0.0
		var prims := 0.0
		var objs := 0.0
		var last := Time.get_ticks_usec()
		var prev := {}
		var slow := 0
		var hist := {}
		var samples := []
		var psamples := []
		var phsamples := []
		while (Time.get_ticks_usec() - t0) / 1e6 < secs:
			await get_tree().process_frame
			_hide(hide)
			var now := Time.get_ticks_usec()
			var ms := (now - last) / 1000.0
			last = now
			frames += 1
			worst = maxf(worst, ms)
			hist[int(ms / 5.0)] = int(hist.get(int(ms / 5.0), 0)) + 1
			samples.append(ms)
			if ms > 50.0 and slow < 12:
				slow += 1
				var top: Array = []
				for k in Prof.acc:
					var d: int = int(Prof.acc[k]) - int(prev.get(k, 0))
					if d > 2000: top.append([d, k])
				top.sort_custom(func(x, y): return x[0] > y[0])
				var names: Array = []
				for t in top.slice(0, 5): names.append("%s %.1f" % [t[1], t[0] / 1000.0])
				print("SLOW %.0f ms at %.1fs, %.0f km/h: %s | nodes %d" % [ms, (now - t0) / 1e6, main.car.sim.speed() * 3.6, ", ".join(names), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
			prev = Prof.acc.duplicate()
			psamples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			phsamples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
			proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			objs += Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		Input.action_release("throttle")
		Prof.on = false
		# PERF_SHOT on a drive: the HUD with every lane in use (objective, a line, a prompt), daytime
		if OS.get_environment("PERF_SHOT") != "" and not night:
			main.hud.objective = "DELIVER THE PIZZA TO 14 HARBOUR ROAD BEFORE IT GETS COLD. TIP RIDES ON IT."
			main.hud.say("GUS", "TAKE THE BRIDGE, KID. THE LIGHTS ON MAIN ARE OUT AGAIN.", 3, 6.0)
			main.hud.prompt(Hints.fmt("{use}: THE GARAGE"))
			main.hud._prompt_t = 5.0          # (a slow frame under xvfb would outlast the usual 0.12 s)
			for i in 20: await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("PERF_SHOT"))
		print("PROF ", Prof.report(frames))
		var n := maxf(1.0, float(frames))
		samples.sort()
		psamples.sort()
		phsamples.sort()
		var med := int(samples.size() / 2)
		var p90 := int(samples.size() * 0.9)
		print("PERF %s: %d frames in %.1fs = %.1f fps | frame med %.1f p90 %.1f worst %.1f ms | process med %.1f p90 %.1f | physics med %.1f p90 %.1f | draw calls %d, prims %dk, nodes %d | speed %.0f km/h" % [
			"night" if night else "day", frames, secs, frames / secs, samples[med], samples[p90], worst, psamples[med], psamples[p90], phsamples[med], phsamples[p90], int(draws / n), int(prims / n / 1000.0), int(objs / n), main.car.sim.speed() * 3.6])
	get_tree().quit()

## PERF_HIDE: world layer kinds (ground, water, base, decor, road, marks, rail, weather, canopy),
## buildings, windows, furniture, parked, cars, lights, hud, yards: hidden, to see what they cost.
func _hide(kinds: Array) -> void:
	if kinds.is_empty(): return
	for k in main.world.chunks:
		var ch = main.world.chunks[k]
		for kind in ch.layers:
			if kind in kinds: ch.layers[kind].visible = false
		for n in ch.get_children():
			if n is BuildingNode:
				if "buildings" in kinds: n.visible = false
				if "windows" in kinds: n.windows.visible = false
			elif n is Yards and "yards" in kinds: n.visible = false
	if "furniture" in kinds: main.furniture.visible = false
	if "lights" in kinds: main.lights.visible = false
	if "hud" in kinds:
		main.hud.visible = false
		main.dash.visible = false
		main.gps.visible = false
	for n in main.ysort.get_children():
		if n is ParkedCar and "parked" in kinds: n.visible = false
		elif n is TrafficCar and "cars" in kinds: n.visible = false
