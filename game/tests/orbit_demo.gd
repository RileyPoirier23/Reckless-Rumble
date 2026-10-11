## The camera swung round your car in the game itself, every camera mode and tilt, parked and
## driving, traffic and parked cars about: godot --path game -- --orbit-demo <out_dir>
## Each sheet: 16 camera headings (two rows of eight) per tilt, overhead, angled and low.
extends Node

var main: Node
var out := "user://orbit_shots"
const CELL := Vector2i(520, 360)

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--orbit-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 13.0
	GameSettings.set_v("ui", "camera_mode", "follow")
	# downtown, on a street with cars parked along it
	var rd: Dictionary = main.world.map.nearest_road(Vector2(6000, 1548), 40.0)
	for run: String in ["parked", "driving"]:
		var sheet := Image.create(CELL.x * 8, CELL.y * 6, false, Image.FORMAT_RGBA8)
		for t in 3:
			var tilt: String = ["overhead", "angled", "low"][t]
			GameSettings.set_v("ui", "camera_angle", tilt)
			main._teleport(rd.point, (rd.dir as Vector2).angle())
			await _wait(0.6)
			main.hud.msgs.clear()
			if run == "driving":
				Input.action_press("throttle")
				await _wait(1.5)
				Input.action_press("steer_right")
				await _wait(0.4)
			for k in 16:
				# swing the camera round by hand, the way the right stick does
				main._orbit = 0.0
				main._orbit_was = 0.0
				main.cam_rot = main.car.sim.heading + PI / 2.0 + TAU * float(k) / 16.0
				await get_tree().process_frame
				main.cam_rot = main.car.sim.heading + PI / 2.0 + TAU * float(k) / 16.0
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				# the car on the screen: the camera's ahead of it by the look-ahead
				var at: Vector2 = (main.cam as Camera2D).get_canvas_transform() * (main.car as Node2D).global_position
				var sc := Vector2(img.get_size()) / get_viewport().get_visible_rect().size
				var c := Vector2i(at * sc)
				var r := Rect2i(c - CELL / 2, CELL).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
				sheet.blit_rect(img, r, Vector2i((k % 8) * CELL.x, (t * 2 + k / 8) * CELL.y) + (r.position - (c - CELL / 2)))
			Input.action_release("steer_right")
			Input.action_release("throttle")
			Input.action_press("brake")
			await _wait(1.0)
			Input.action_release("brake")
		sheet.save_png("%s/orbit_game_%s.png" % [out, run])
		print("saved ", run)
	GameSettings.set_v("ui", "camera_mode", "chase")
	GameSettings.set_v("ui", "camera_angle", "angled")
	get_tree().quit()
