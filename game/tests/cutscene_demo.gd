## Every cutscene, screenshots of the opening line (and the line given):
##   godot --path game -s tests/cutscene_demo.gd -- <out_dir> [scene_id ...]
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
	for id in ids:
		for k in StoryScript.STEPS.size():
			var st: Dictionary = StoryScript.STEPS[k]
			if st.type == "scene" and st.id == id: StoryState.step = k
		change_scene_to_file("res://story/story.tscn")
		await _wait(1.6)
		root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, id])
		print("shot ", id)
	quit()
