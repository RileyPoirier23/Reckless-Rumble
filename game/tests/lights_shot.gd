## Screenshots of the player's lamps at night, for looking over: tails, brakes, a blinker, backing
## up, a smashed headlight, and the tread rolling. godot --path game -- --lights-shot <out_dir>
extends Node

var main: Node
var out := "user://lights_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--lights-shot")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.traffic.enabled = false
	main.police.enabled = false
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
	main.sky.time_h = 22.5
	main.sky.snap()
	var c: PlayerCar = main.car
	# on the road out front, pointing down the screen so both ends show
	var rd: Dictionary = main.world.map.nearest_road(Vector2(5560, 1560), 80.0)
	main._teleport(rd.point, (rd.dir as Vector2).angle())
	main.hold_car = true
	await _wait(2.0)
	main.hud.msgs.clear()
	await _shot("1_lights_on")
	c.view.braking = true
	await _wait(0.3)
	await _shot("2_braking")
	c.view.braking = false
	c.view.blink_left = true
	await _wait(0.45)
	await _shot("3_blinker")
	c.view.blink_left = false
	c.view.reversing = true
	await _wait(0.3)
	await _shot("4_reversing")
	c.view.reversing = false
	# the left headlight smashed: its beam's gone, the right one carries on
	c.damage.front = 0.6
	c.damage.left = 0.5
	c.damage_bucket = -2
	await _wait(1.5)
	await _shot("5_one_headlight")
	# rolling: the tread moves
	main.hold_car = false
	c.damage.front = 0.0
	c.damage.left = 0.0
	c.damage_bucket = -2
	c.sim.vx = 12.0
	await _wait(0.6)
	await _shot("6_rolling")
	get_tree().quit()
