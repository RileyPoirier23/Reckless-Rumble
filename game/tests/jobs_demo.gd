## Evening jobs screenshots: godot --path game -- --jobs-demo <out_dir>
extends Node

var main: Node
var out := "user://jobs_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--jobs-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 600
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
	main.sky.time_h = 18.0
	await _wait(1.0)
	main.job_board.open(main.sky, main.save, "")
	await _wait(0.5)
	await _shot("1_board")
	main.job_board.visible = false
	# pizza: pull up at the shop, take the order
	main.jobs.start("pizza")
	main._teleport(main.jobs.shop.p, 0.0)
	await _wait(1.5)
	main.car.sim.vx = 9.0
	await _wait(0.8)
	await _shot("2_pizza")
	main.jobs.finish(false)
	# tow: back up to the car on the shoulder and work the boom
	main.jobs.start("tow")
	await _wait(0.5)
	var tg = main.jobs.target
	var tail: Vector2 = tg.end(1.0) + Vector2(cos(tg.heading), sin(tg.heading)) * (float(main.car.spec.length) * 0.5 + 1.0)
	main._teleport(tail, tg.heading)
	await _wait(0.6)
	Input.action_press("use")
	await _wait(1.8)
	Input.action_release("use")
	await _wait(0.3)
	await _shot("3_tow_hooked")
	main.car.sim.vx = 7.0
	main.car.sim.w_wheel = 7.0 / float(main.car.spec.tires.radius)
	await _wait(2.5)
	await _shot("4_towing")
	main.jobs.finish(false)
	await _wait(0.5)
	# drag night
	main.sky.time_h = 21.5
	main.jobs.start("drag")
	main._teleport(DragStrip.START + Vector2(-4, 0), 0.0)
	await _wait(1.0)
	main.jobs.open_strip()
	await _wait(0.6)
	await _shot("5_signin")
	var strip: DragStrip = main.jobs.strip
	strip._race()
	while strip and strip.t < float(strip.green[1]) - 0.6:
		await _wait(0.05)
	await _shot("6_tree")
	while strip and strip.t < float(strip.green[1]) + 0.18:
		await _wait(0.02)
	Input.action_press("throttle")
	await _wait(2.0)
	await _shot("7_race")
	while strip and strip.state != "slip":
		await _wait(0.2)
	Input.action_release("throttle")
	await _wait(1.0)
	await _shot("8_slip")
	get_tree().quit()
