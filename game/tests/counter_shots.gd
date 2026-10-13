## Screenshots of the counter, one customer after another: godot --path game -s tests/counter_shots.gd <out_dir>
extends SceneTree

func _init() -> void:
	var out := "user://counter_shots"
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	change_scene_to_file("res://counter.tscn")
	_run(out)

func _run(out: String) -> void:
	await create_timer(2.0).timeout
	var sc = current_scene
	for i in 8:
		if sc.has_method("next_customer"):
			sc.next_customer()
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/customer_%d.png" % [out, i])
		print("shot ", i, " phase ", sc.get("phase"), " car ", str(sc.get("c").get("car", {}).get("cat", "?")) if sc.get("c") is Dictionary and not (sc.get("c") as Dictionary).is_empty() else "-")
	quit()
