## A drive-by of the town's buildings, day and night: godot --path game -- --tour-demo <out_dir>
extends Node

var main: Node
var out := "user://tour_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--tour-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.traffic.enabled = false
	if OS.get_environment("TOUR_ZOOM") != "": main.zoom_mult = float(OS.get_environment("TOUR_ZOOM"))
	# a spread of places: houses in town, downtown, the country
	var picks := []
	var seen := {}
	for b in main.world.map.buildings:
		var kinds: Array = OS.get_environment("TOUR_KINDS").split(",") if OS.get_environment("TOUR_KINDS") != "" else ["house", "shop", "farmhouse", "warehouse", "bigbox"]
		var key := "%s/%s" % [b.kind, b.zone] if OS.get_environment("TOUR_KINDS") == "" else "%s/%d" % [b.kind, int((b.r as Rect2).position.x / 400.0)]
		if seen.has(key) or picks.size() >= 6: continue
		if not b.kind in kinds: continue
		seen[key] = true
		picks.append(b)
	# TOUR_MAP=1: the big map at every zoom, from downtown, instead of the building tour
	# (TOUR_MAP_PICK=n: with the n-th place on its list picked, the way there shown)
	if OS.get_environment("TOUR_MAP") != "":
		main._teleport(Vector2(5900, 1480), -PI / 2.0)
		main.hold_car = true
		await _wait(1.0)
		main.map_screen.open()
		main.map_screen.visible = true
		if OS.get_environment("TOUR_MAP_PICK") != "": main.map_screen._pick(int(OS.get_environment("TOUR_MAP_PICK")))
		for z in 3:
			main.map_screen.zoom = z
			main.map_screen.queue_redraw()
			await _wait(0.3)
			await _shot("map_zoom%d" % z)
		get_tree().quit()
		return
	# TOUR_AT=x,y,heading_deg: one spot, day and night, instead of the building tour
	if OS.get_environment("TOUR_AT") != "":
		var sp := OS.get_environment("TOUR_AT").split(",")
		var at := Vector2(float(sp[0]), float(sp[1]))
		var hd := deg_to_rad(float(sp[2])) if sp.size() > 2 else 0.0
		for night in [false, true]:
			main.sky.time_h = 22.0 if night else 13.0
			main._teleport(at, hd)
			main.hold_car = true
			await _wait(6.0)
			print("at ", at, " zone ", main.world.map.zone_at(at).get("label", "?"), " buildings near: ", main.world.map.buildings.filter(func(b): return (b.r as Rect2).get_center().distance_to(at) < 80.0).map(func(b): return "%s %s" % [b.name, str(b.r)]))
			main.hud.msgs.clear()
			await _shot("at_%s" % ("night" if night else "day"))
		get_tree().quit()
		return
	# TOUR_WEATHER=summer:clear,fall:rain,winter:snow,...: every season and weather named, day and
	# night, at the first couple of places, instead of the building tour
	if OS.get_environment("TOUR_WEATHER") != "":
		for i in mini(2, picks.size()):
			var b0: Dictionary = picks[i]
			var rd0: Dictionary = main.world.map.nearest_road((b0.r as Rect2).get_center(), 80.0)
			if rd0.is_empty(): continue
			for w in OS.get_environment("TOUR_WEATHER").split(","):
				var parts := w.split(":")
				main.sky.set_season(parts[0])
				main.sky.pick_weather(parts[1])
				main.sky.forced = true
				main.sky.snap()
				for night in [false, true]:
					main.sky.time_h = 22.0 if night else 13.0
					main._teleport(rd0.point, (rd0.dir as Vector2).angle())
					await _wait(2.5)
					main.hud.msgs.clear()
					await _shot("w%d_%s_%s_%s" % [i, parts[0], parts[1], "night" if night else "day"])
		get_tree().quit()
		return
	for i in picks.size():
		var b: Dictionary = picks[i]
		var c: Vector2 = (b.r as Rect2).get_center()
		var rd: Dictionary = main.world.map.nearest_road(c, 80.0)
		if rd.is_empty(): continue
		for night in [false, true]:
			main.sky.time_h = 22.0 if night else 13.0
			main._teleport(rd.point, (rd.dir as Vector2).angle())
			await _wait(2.0)
			main.hud.msgs.clear()
			await _shot("%d_%s_%s_%s" % [i, b.kind, b.zone, "night" if night else "day"])
	get_tree().quit()
