## Moose and deer screenshots: godot --path game -- --wild-demo <out_dir>
extends Node

var main: Node
var out := "user://wild_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--wild-demo")
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
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 18.6
	var w: Wildlife = main.wildlife
	w.enabled = true
	var rd: Dictionary = main.world.map.nearest_road(Vector2(3763, 1668), 30.0)       # the Trans-Canada
	var dir: Vector2 = rd.dir
	var right := Vector2(-dir.y, dir.x)
	main.hold_car = true
	main.car.sim.set_wear({})
	main._teleport(rd.point + right * 4.0, dir.angle())
	await _wait(1.2)
	main.hud.msgs.clear()
	var ahead: Vector2 = rd.point + dir * 11.0
	var moose := w.spawn_at("moose", ahead + right * 2.0, dir.angle() + PI / 2.0)
	moose.antlers = true
	moose.state = "stand"
	await _wait(0.8)
	await _shot("1_moose_dusk")
	w.clear()
	# night: a deer at the roadside, eyes in the high beams
	main.sky.time_h = 23.0
	main.car.high_beams = true
	await _wait(0.6)
	main.hud.msgs.clear()
	var cp: Vector2 = main.car.sim.pos
	var cf: Vector2 = main.car.sim.forward()
	var cr: Vector2 = main.car.sim.right()
	w.spawn_at("deer", cp + cf * 8.0 + cr * 1.5, (-cf).angle() + 0.3)
	var d2 := w.spawn_at("deer", cp + cf * 10.5 - cr * 2.5, (-cf).angle() - 0.5)
	d2.antlers = true
	await _wait(1.0)
	for a in w.animals:
		var rel: Vector2 = (a.pos - main.car.sim.pos).rotated(-main.car.sim.heading)
		print("   %s %s ahead %.1f right %.1f state %s lights %s beam %.2f" % [a.kind, str(a.pos.round()), rel.x, rel.y, a.state, str(main.car.lights_on), main.car.beam])
	await _shot("2_deer_eyes")
	print("WILD DEMO DONE")
	get_tree().quit()
