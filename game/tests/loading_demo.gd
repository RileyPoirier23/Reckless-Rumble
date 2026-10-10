## Loading screen screenshots: godot --path game -s tests/loading_demo.gd -- <out_dir>
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://loading_shots"
	DirAccess.make_dir_recursive_absolute(out)
	_run(out)

func _run(out: String) -> void:
	await create_timer(0.2).timeout
	for k in 4:
		LoadingScreen.next_path = "res://counter.tscn"
		LoadingScreen.label = "COVINGTON AUTO: CLOCKING IN"
		var ls: Node = load("res://ui/loading_screen.gd").new()
		root.add_child(ls)
		await create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/loading_%d.png" % [out, k])
		print("shot ", k)
		ls.done = true
		ls.queue_free()
		await process_frame
	quit()
