## The credits, screenshots: the roll, the thank-you and the memorial.
##   godot --path game -s tests/credits_demo.gd -- <out_dir>
extends SceneTree

var out := "user://credits_shots"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[a.size() - 1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	EndCredits.from_menu = true
	change_scene_to_file("res://ui/credits.tscn")
	await _wait(3.0)
	await _shot("1_roll")
	var c: EndCredits = current_scene
	c.roll_y = -300.0
	await _wait(0.3)
	await _shot("2_roll_end")
	c.stage = "thanks"
	c.t = 3.0
	await _wait(0.2)
	await _shot("3_thanks")
	c.to_memorial()
	await _wait(5.0)
	await _shot("4_memorial")
	quit()
