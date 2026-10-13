## Car meet screenshots: godot --path game -- --meet-demo <out_dir>
extends Node

var main: Node
var out := "user://meet_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--meet-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 900
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
	main.sky.time_h = 22.6
	await _wait(1.0)
	main.job_board.open(main.sky, main.save, "", Market.places(main.world.map))
	main.job_board.sel = Jobs.ORDER.find("meet")
	await _wait(0.4)
	await _shot("1_board")
	main.job_board.visible = false
	var j: JobRunner = main.jobs
	main._teleport(CarMeet.YOUR_SPOT + Vector2(0, 14), -PI / 2.0)
	j.start("meet")
	await _wait(1.5)
	await _shot("2_arrive")
	main._teleport(CarMeet.YOUR_SPOT, -PI / 2.0)
	main.car.sim.set_world_velocity(Vector2.ZERO)
	await _wait(0.8)
	var m: CarMeet = j.meet
	Input.action_press("throttle")
	await _wait(4.0)
	await _shot("3_revving")
	Input.action_release("throttle")
	m.hood = true
	m.t = CarMeet.SHOW_S - 0.05
	await _wait(0.6)
	await _shot("4_votes")
	print("MEET DEMO DONE")
	get_tree().quit()
