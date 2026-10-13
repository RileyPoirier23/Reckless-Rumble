## Gas station screenshots: godot --path game -- --fuel-demo <out_dir>
extends Node

var main: Node
var out := "user://fuel_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--fuel-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 400
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 19.5
	await _wait(1.0)
	# low on the highway: the light's on
	var c: PlayerCar = main.car
	c.sim.fuel_l = c.sim.tank_l * 0.08
	await _wait(0.6)
	await _shot("1_fuel_light")
	# at the pumps
	var s: Dictionary = main.fuel.stations[0]
	var r: Rect2 = s.r
	main._teleport(r.get_center() + Vector2(0, 5.0), 0.0)
	await _wait(1.0)
	await _shot("2_at_pumps")
	main.fuel.panel.open(s)
	main.fuel.panel.sel = 1
	await _wait(0.4)
	await _shot("3_pump_menu")
	main.fuel.panel.premium = true
	main.fuel.panel.going = 20.0
	await _wait(1.2)
	await _shot("4_pumping")
	await _wait(3.0)
	await _shot("5_paid")
	main.fuel.panel.visible = false
	# dry on the side of the road
	main._teleport(Vector2(4300, 1400), 0.0)
	c.sim.fuel_l = 0.0
	await _wait(1.5)
	await _shot("6_out_of_gas")
	main.fuel.jerry_can()
	await _wait(0.6)
	await _shot("7_toby")
	print("FUEL DEMO DONE")
	get_tree().quit()
