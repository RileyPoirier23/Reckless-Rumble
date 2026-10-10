## Line of sight screenshots downtown, on and off: godot --path game -- --sight-demo <out_dir>
extends Node

var main: Node
var out := "user://sight_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--sight-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name, "  shadows ", main.sight.shadows.size())

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 13.0
	main.hold_car = true
	var spots := [["main_st", Vector2(6000, 1548), 0.0], ["queen_st", Vector2(5935, 1445), 0.0], ["behind", Vector2(5935, 1412), PI]]
	for s in spots:
		var rd: Dictionary = main.world.map.nearest_road(s[1], 40.0)
		var dir: Vector2 = rd.dir if not rd.is_empty() else Vector2.RIGHT
		main._teleport(rd.point if not rd.is_empty() else s[1], dir.angle() + float(s[2]))
		main.sight.on = true
		await _wait(2.5)
		main.hud.msgs.clear()
		await _shot(String(s[0]) + "_on")
		main.sight.on = false
		await _wait(0.6)
		await _shot(String(s[0]) + "_off")
	# what it costs a frame
	var t0 := Time.get_ticks_usec()
	for i in 100: main.sight.update_sight(1.0 / 60.0, main.car.global_position, 400.0)
	var nb := 0
	for n in main.ysort.get_children(): if n is BuildingNode: nb += 1
	print("sight: %.2f ms a frame, %d buildings in the scene, %d nodes" % [(Time.get_ticks_usec() - t0) / 100000.0, nb, main.ysort.get_child_count()])
	var t1 := Time.get_ticks_msec()
	var f0 := Engine.get_frames_drawn()
	await _wait(3.0)
	print("fps: %.1f" % ((Engine.get_frames_drawn() - f0) / ((Time.get_ticks_msec() - t1) / 1000.0)))
	main.sight.on = false
	t1 = Time.get_ticks_msec()
	f0 = Engine.get_frames_drawn()
	await _wait(3.0)
	print("fps without sight: %.1f" % ((Engine.get_frames_drawn() - f0) / ((Time.get_ticks_msec() - t1) / 1000.0)))
	main.sight.on = true
	# the three camera angles, same spot
	for ang in ["overhead", "angled", "low"]:
		GameSettings.set_v("ui", "camera_angle", ang)
		await _wait(1.0)
		await _shot("angle_" + ang)
	GameSettings.set_v("ui", "camera_angle", "angled")
	# wide, to see the shadows run out
	main.zoom_mult = 0.45
	main.sight.on = true
	await _wait(2.0)
	await _shot("wide_on")
	# tucked in behind a building: it goes see-through
	main.zoom_mult = 1.0
	var best: BuildingNode = null
	for n in main.ysort.get_children():
		if n is BuildingNode and n.blocks_sight() and (best == null or n.sort_point().distance_to(Vector2(6000, 1500) * main.PX) < best.sort_point().distance_to(Vector2(6000, 1500) * main.PX)): best = n
	var top: Vector2 = (best.global_position + Vector2(best.fp.get_center().x, best.fp.position.y)) / main.PX
	main._teleport(top + Vector2(0, -1.4), -PI / 2.0)
	await _wait(1.5)
	await _shot("tucked_on")
	main.sight.on = false
	await _wait(0.8)
	await _shot("tucked_off")
	get_tree().quit()
