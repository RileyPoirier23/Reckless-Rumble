## Garage screenshots: godot --path game -s tests/garage_demo.gd -- <out_dir>
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://garage_shots"
	DirAccess.make_dir_recursive_absolute(out)
	_run(out)

func _run(out: String) -> void:
	Controls.setup()
	await create_timer(0.2).timeout
	var save := SaveGame.default_data()
	save.shelf = ["ind_greddy", "tire_sport", "susp_coilover", "aero_gt"]
	save.garage[0].parts = { "exhaust": "exh_borlah", "brakes": "brk_brenbo", "susp": "" }
	save.garage[0].parts.erase("susp")
	save.garage[0].parts.induction = "ind_garrette"
	save.garage[0].parts.fuel = "fuel_e85"
	save.garage[0].tune = { "boost": 0.15, "timing": 2 }
	save.garage[0].installing = [{ "slot": "internals", "part": "int_built", "done_h": float(save.get("clock_h", 0.0)) + 11.5 }]
	save.orders = [{ "part": "lsd_osgiggle", "arrives_h": 30.0 }]
	var g := GarageScreen.new()
	g.size = Vector2(640, 360)
	root.add_child(g)
	g.open(save)
	for k in GarageScreen.TABS.size():
		g.tab = k
		g.row = 5 if k == 1 else (2 if k == 2 else 0)
		if k == 1: g.opt["induction"] = 1
		if k == 2:
			g.trial.rim = "turbofan"
			g.trial.rim_color = "#1a1a1e"
			g.trial.stripes = "racing"
			g.trial_paint = "#e8a020"
		if k == 4: g.dyno_t = 5.0
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/garage_%d.png" % [out, k])
		print("shot ", k)
	quit()
