## Each camera, driving into a turn: godot --path game -- --cam-demo <out_dir>
extends Node

var main: Node
var out := "user://cam_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--cam-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name, "  cam_rot %.2f  heading %.2f" % [main.cam_rot, main.car.sim.heading])

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 13.0
	main.traffic.enabled = false
	for mode in ["chase", "follow", "top_down"]:
		GameSettings.set_v("ui", "camera_mode", mode)
		var rd: Dictionary = main.world.map.nearest_road(Vector2(6000, 1548), 40.0)
		main._teleport(rd.point, (rd.dir as Vector2).angle())
		await _wait(1.0)
		main.hud.msgs.clear()
		Input.action_press("throttle")
		await _wait(2.5)
		Input.action_press("steer_right")
		await _wait(1.2)
		await _shot(mode + "_turning")
		Input.action_release("steer_right")
		Input.action_release("throttle")
		Input.action_press("brake")
		await _wait(2.0)
		Input.action_release("brake")
	GameSettings.set_v("ui", "camera_mode", "chase")
	get_tree().quit()
