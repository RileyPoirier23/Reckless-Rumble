## Every cutscene, screenshots of the opening line (or of a line further in):
##   godot --path game -s tests/cutscene_demo.gd -- <out_dir> [scene_id[@line] ...]
## "clean_end@18" presses through the first 18 lines (choices take their first option, a change
## of place fades through) and shoots what's on screen then, as clean_end_18.png.
extends SceneTree

var out := "user://cutscene_shots"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var ids: Array = []
	for k in a.size():
		if k == 0: out = a[k]
		else: ids.append(a[k])
	if ids.is_empty(): ids = StoryScript.SCENES.keys()
	DirAccess.make_dir_recursive_absolute(out)
	_run(ids)

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _run(ids: Array) -> void:
	await _wait(0.3)
	StoryState.new_game()
	for want in ids:
		var id := String(want).get_slice("@", 0)
		var n := int(String(want).get_slice("@", 1)) if String(want).contains("@") else 0
		for k in StoryScript.STEPS.size():
			var st: Dictionary = StoryScript.STEPS[k]
			if st.type == "scene" and st.id == id: StoryState.step = k
		change_scene_to_file("res://story/story.tscn")
		await _wait(0.9)
		var sc = current_scene
		for k in n:
			# never press through a fade: the change of place runs its own "cast" line when it's black
			while is_instance_valid(sc) and sc._tr >= 0.0 and not sc._leaving: await _wait(0.1)
			# ...and never past the end of the scene: the next step would take the scene away
			if not is_instance_valid(sc) or sc._leaving or sc.i >= sc.lines.size() - 1:
				print("  (", want, ": the scene ends after line ", k, ")")
				break
			sc.shown = 9999.0
			sc.press()
			await _wait(0.08)
		await _wait(1.6)
		root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, String(want).replace("@", "_")])
		print("shot ", want)
	quit()
