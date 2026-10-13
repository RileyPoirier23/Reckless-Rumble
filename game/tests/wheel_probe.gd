## One car's front wheel up close, with and without the body: godot --path game -s tests/wheel_probe.gd -- <out_dir> [car] [angle] [heading] [offset]
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://probe"
	var id: String = a[1] if a.size() > 1 else "silvio"
	CarView.set_angle(a[2] if a.size() > 2 else "angled")
	var h := deg_to_rad(float(a[3]) if a.size() > 3 else 20.0)
	var mods := { "offset": a[4] } if a.size() > 4 else {}
	DirAccess.make_dir_recursive_absolute(out)
	var root := Node2D.new()
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("5c6266")
	bg.size = Vector2(4000, 4000)
	bg.position = Vector2(-2000, -2000)
	bg.z_index = -10
	root.add_child(bg)
	var cam := Camera2D.new()
	cam.zoom = Vector2(5, 5 * CarView.squash)
	root.add_child(cam)
	var spec := CarCatalog.spec(id)
	for k in 3:
		var v := CarView.new()
		v.art = CarArt.new(spec, Color("c8342c"), 0.0, 1, CarArt.CAR_SCALE, mods)
		if k == 1: v.art.wheel_n = 0
		if k == 2: v.art.atlas = ImageTexture.create_from_image(Image.create(v.art.atlas.get_width(), v.art.atlas.get_height(), false, Image.FORMAT_RGBA8))
		v.heading = h
		v.position = Vector2((k - 1) * 22, (k - 1) * 34) - Vector2(cos(h), sin(h)) * v.art.wheel_spots[1].x
		root.add_child(v)
	for f in 8: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/probe.png")
	print("saved")
	quit()
