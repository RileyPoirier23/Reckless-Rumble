## 1ton and the Luchadooros, screenshots: godot --path game -- --crew-demo <out_dir>
## Puts the save back the way it found it.
extends Node

var main: Node
var out := "user://crew_shots"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	var k := a.find("--crew-demo")
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
	var crew0: Variant = main.save.get("crew", null)
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 19.0
	main.save.erase("crew")
	# pull up at the lot
	main._teleport(Luchadooros.SPOT + Vector2(0, -1), PI / 2.0)
	main.car.sim.vx = 0.0
	main.hold_car = true
	await _wait(2.0)
	await _shot("1_the_lot")
	var lot: Luchadooros = main.luchadooros
	lot.panel.open()
	await _wait(0.3)
	await _shot("2_oneton_intro")
	lot.panel.line_i = 3
	await _wait(0.2)
	await _shot("3_the_list")
	lot.panel.lines = OneTon.JOINS.duplicate()
	main.save.crew = { "oneton": true, "met_oneton": true }
	lot.panel.line_i = 1
	await _wait(0.2)
	await _shot("4_joins")
	lot.panel.visible = false
	# his bay
	# a car on the list, for the demo (taken back out at the end)
	var cap := Luchadooros.find_car("CAPREES", 1986)
	(main.save.garage as Array).append({ "id": cap, "paint": "#5a1e7a", "damage": { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 },
		"odo_km": 0.0, "parts": {}, "looks": {}, "tune": {}, "wear": {}, "installing": [] })
	var ci: int = (main.save.garage as Array).size() - 1
	main.garage.open(main.save)
	main.garage.sel = ci
	main.garage.tab = main.garage.tabs().find(GarageScreen.BAY)
	main.garage.bay = { "hyd": 3, "donk": 3 }
	main.garage.row = 1
	await _wait(0.6)
	await _shot("5_bay")
	main.garage.visible = false
	# on the road with it: lifted on 28s, and a hop
	var car0: int = main.car_i
	main.save.garage[ci].custom = { "hyd": 3, "donk": 3 }
	main.car_i = -1               # (don't park the demo's car into the slot it just borrowed)
	main._spawn_car(ci, Luchadooros.SPOT + Vector2(-8, -1), PI / 2.0)
	main._teleport(Luchadooros.SPOT + Vector2(-8, -1), PI / 2.0)
	main.hold_car = false
	main.sky.time_h = 13.0
	await _wait(1.0)
	await _shot("6_donk")
	Input.action_press("hydraulics")
	await _wait(0.1)
	Input.action_release("hydraulics")
	await _wait(0.33)
	print("hop: ", main.car.hop)
	await _shot("7_hop")
	# put it all back
	(main.save.garage as Array).remove_at(ci)
	main.car_i = car0
	if crew0 == null: main.save.erase("crew")
	else: main.save.crew = crew0
	get_tree().quit()
