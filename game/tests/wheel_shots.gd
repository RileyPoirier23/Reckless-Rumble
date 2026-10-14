## Cars on a plain lot from above, at a few headings and steering angles, zoomed in: to look at
## the wheels.  godot --path game -s tests/wheel_shots.gd -- <out.png>
extends SceneTree

func _init() -> void:
	var out := "/tmp/wheels.png"
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	_run(out)

func _run(out: String) -> void:
	await process_frame
	var root_n := Node2D.new()
	root.add_child(root_n)
	var bg := ColorRect.new()
	bg.color = Color("3a3a3c")
	bg.size = Vector2(2000, 2000)
	bg.position = Vector2(-500, -500)
	root_n.add_child(bg)
	var cam := Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	cam.position = Vector2(300, 150)
	root_n.add_child(cam)
	cam.make_current()
	var ids: Array = Array(OS.get_environment("WS_CARS").split(",", false)) if OS.get_environment("WS_CARS") != "" else ["silvio", "f150", "camaro_69"]
	var mods := {}
	if OS.get_environment("WS_MODS") != "": mods = JSON.parse_string(OS.get_environment("WS_MODS"))
	var views: Array = []
	var y := 40.0
	for id in ids:
		var spec := CarCatalog.spec(id)
		if spec.is_empty():
			print("no car ", id)
			continue
		var x := 40.0
		for h in [0.0, PI / 4.0, PI / 2.0, 3.0 * PI / 4.0, PI]:
			for st in [0.0, 0.6]:
				var v := CarView.new()
				v.art = CarArt.build(spec, Color("c0392b"), {}, 3, CarArt.CAR_SCALE, mods).take()
				v.heading = h
				v.steer = st
				v._steer_vis = st
				v.wheel_turn = 0.7
				v.position = Vector2(x, y)
				root_n.add_child(v)
				views.append(v)
				x += 62.0
		y += 90.0
	CarView.screen_up = Vector2(0, -1)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
