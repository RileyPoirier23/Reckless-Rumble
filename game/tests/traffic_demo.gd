## Traffic screenshots: godot --path game -- --traffic-demo <out_dir>
extends Node

var main: Node
var out := "user://traffic_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--traffic-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.get_node("HudLayer").visible = true
	main.hud.show_help = false
	main.traffic.ignore_player = true
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 12.5
	main._teleport(Vector2(6082, 1530), PI)          # Main St downtown, facing west
	main.zoom_mult = 0.75
	Engine.time_scale = 3.0
	await _wait(25.0)
	Engine.time_scale = 1.0
	await _wait(0.5)
	await _shot("1_traffic_day")
	main.sky.time_h = 22.0
	await _wait(1.0)
	await _shot("2_traffic_night")
	main.car.high_beams = true
	await _wait(0.6)
	await _shot("3_high_beams")
	main.car.high_beams = false
	main.car.blink = -1
	await _wait(0.2)
	await _shot("4_blinker")
	main.car.blink = 0
	# a crash: put the car behind a traffic car and drive into it
	main.sky.time_h = 13.0
	var target: TrafficCar = null
	var best := INF
	for c in main.traffic.cars:
		var d: float = c.pos.distance_to(main.car.sim.pos)
		if d < best and c.state == "drive":
			best = d
			target = c
	if target:
		var fwd := Vector2(cos(target.heading), sin(target.heading))
		main._teleport(target.pos - fwd * 14.0, target.heading)
		main.car.sim.vx = 17.0
		main.car.sim.w_wheel = 17.0 / 0.31
		await _wait(0.9)
		await _shot("5_crash")
		await _wait(0.8)
		await _shot("6_after")
	# a beaten-up car, for the record
	main.car.damage = { "front": 0.8, "rear": 0.3, "left": 0.5, "right": 0.15 }
	main.car.damage_bucket = -2
	await _wait(0.3)
	main.zoom_mult = 2.0
	await _wait(1.5)
	await _shot("7_damage_closeup")
	main.zoom_mult = 1.0
	main._store_car()
	main.garage.open(main.save)
	await _wait(0.4)
	await _shot("8_garage")
	print("TRAFFIC DEMO DONE")
	get_tree().quit()
