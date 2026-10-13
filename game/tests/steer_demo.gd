## The front wheels at every steering angle and heading, big: godot --path game -s tests/steer_demo.gd -- <out_dir>
extends SceneTree

func _init() -> void:
	var out := "user://steer_shots"
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	var root := Node2D.new()
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("5a6a5a")
	bg.size = Vector2(4000, 4000)
	bg.position = Vector2(-2000, -2000)
	bg.z_index = -10
	root.add_child(bg)
	var cam := Camera2D.new()
	cam.zoom = Vector2(4, 4)
	root.add_child(cam)
	var views := []
	var steers := [-0.5, 0.0, 0.5]
	var heads := [PI, -PI / 2.0 + 0.3]
	for i in heads.size():
		for j in steers.size():
			var v := CarView.new()
			v.art = CarArt.new(spec, Color(spec.paint), 0.0, 1, CarArt.CAR_SCALE)
			v.heading = heads[i]
			v.steer = steers[j]
			v.position = Vector2((j - 1) * 66, (i - 0.5) * 60)
			root.add_child(v)
			views.append(v)
	for f in 40: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/steer.png")
	print("saved")
	quit()
