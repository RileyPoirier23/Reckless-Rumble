## Story screenshots: godot --path game -s tests/story_demo.gd -- <out_dir>
## Walks the cutscene sets, the avatar screen, a title card, the drunk prologue drive and the
## counter tutorial, saving a picture of each.
extends SceneTree

var out := "user://story_shots"

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

func _step_of(pred: Callable) -> int:
	for k in StoryScript.STEPS.size():
		if pred.call(StoryScript.STEPS[k]): return k
	return -1

func _run() -> void:
	await _wait(0.3)
	StoryState.new_game()
	StoryState.avatar = { "name": "RAY MELANSON", "seed": 777, "female": 0, "age": 58 }
	# the title card
	StoryState.step = 0
	change_scene_to_file("res://story/story.tscn")
	await _wait(1.4)
	await _shot("00_card")
	# every scene: a shot a few lines in, so the set and a portrait show
	for id in StoryScript.SCENES:
		StoryState.step = _step_of(func(s): return s.type == "scene" and s.id == id)
		change_scene_to_file("res://story/story.tscn")
		await _wait(0.3)
		var sc: Node = current_scene
		for n in 3: sc.press(); sc.press()
		await _wait(0.6)
		await _shot("10_scene_" + id)
	StoryState.step = _step_of(func(s): return s.type == "avatar")
	change_scene_to_file("res://story/avatar.tscn")
	await _wait(0.6)
	await _shot("20_avatar")
	StoryState.step = _step_of(func(s): return s.type == "drive" and s.mission == "last_call")
	change_scene_to_file("res://drive.tscn")
	await _wait(5.0)
	await _shot("30_last_call")
	StoryState.step = _step_of(func(s): return s.type == "drive" and s.mission == "detailing")
	change_scene_to_file("res://drive.tscn")
	await _wait(5.0)
	await _shot("31_detailing")
	StoryState.step = _step_of(func(s): return s.type == "counter")
	change_scene_to_file("res://counter.tscn")
	await _wait(2.0)
	await _shot("40_counter_tutorial")
	StoryState.active = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(StoryState.PATH))
	quit()
