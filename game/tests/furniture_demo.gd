## Road furniture screenshots: godot --path game -- --furniture-demo <out_dir>
extends Node

var main: Node
var out := "user://furniture_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--furniture-demo")
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

func _first(kind: String, icon := "") -> Dictionary:
	var best := {}
	for c in main.furniture.cells:
		for it in main.furniture.cells[c]:
			if String(it.kind) != kind or (icon != "" and String(it.get("icon", "")) != icon): continue
			if best.is_empty() or (it.p as Vector2).x > (best.p as Vector2).x: best = it
	return best

func _go(it: Dictionary, back: float) -> void:
	var d: Vector2 = it.dir
	var p: Vector2 = it.p - d * back - Vector2(-d.y, d.x) * 6.0
	var road: Dictionary = main.world.map.road_at(p, 6.0)
	main._teleport(p, d.angle())
	main.car.sim.vx = 0.0
	main.hold_car = true

func _run() -> void:
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 12.0
	await _wait(1.0)
	var sig := _first("signal")
	_go(sig, 9.0)
	await _wait(1.5)
	await _shot("1_signal_day")
	Traffic.clock += 26.0
	await _wait(0.5)
	await _shot("2_signal_day_later")
	main.sky.time_h = 22.0
	await _wait(1.5)
	await _shot("3_signal_night")
	main.sky.time_h = 12.0
	var stop := _first("stop")
	_go(stop, 8.0)
	await _wait(1.5)
	await _shot("4_stop")
	var lim := _first("limit")
	_go(lim, 8.0)
	await _wait(1.5)
	await _shot("5_limit")
	for ic in ["curve_r", "curve_l", "turn_r", "turn_l"]:
		var w := _first("warn", ic)
		if w.is_empty(): continue
		_go(w, 8.0)
		await _wait(1.5)
		await _shot("6_" + ic)
		break
	var ch := _first("chevron")
	_go(ch, 12.0)
	await _wait(1.5)
	await _shot("7_chevrons")
	var ex := _first("exit")
	if not ex.is_empty():
		_go(ex, 8.0)
		await _wait(1.5)
		await _shot("8_exit")
	var le := _first("warn", "lane_ends")
	if not le.is_empty():
		_go(le, 8.0)
		await _wait(1.5)
		await _shot("9_lane_ends")
	# streetlights at night, downtown: beside one, on the street it lights
	main.sky.time_h = 22.5
	var lamp := {}
	for c in main.furniture.cells:
		for it in main.furniture.cells[c]:
			if String(it.kind) == "light" and (it.arm as Vector2) != Vector2.ZERO and main.world.map.zone_at(it.p).id == "downtown":
				lamp = it
				break
		if not lamp.is_empty(): break
	var arm: Vector2 = lamp.arm
	var along := Vector2(-arm.y, arm.x)
	main._teleport((lamp.p as Vector2) + arm * 3.5 - along * 6.0, along.angle())
	main.car.sim.vx = 0.0
	await _wait(2.0)
	await _shot("10_streetlights_night")
	_go(ch, 4.0)
	main.sky.time_h = 12.0
	await _wait(1.5)
	await _shot("11_chevrons_close")
	get_tree().quit()
