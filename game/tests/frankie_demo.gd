## Frankie, screenshots: godot --path game -s tests/frankie_demo.gd -- <out_dir>
## The news, the June card, the naming, and Employee of the Month with him in the photos.
extends SceneTree

var out := "user://frankie_shots"

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

## Into a scene, and on until line `upto` is showing.
func _scene_at(id: String, upto: int) -> void:
	StoryState.step = _step_of(func(s): return s.type == "scene" and s.id == id)
	change_scene_to_file("res://story/story.tscn")
	await _wait(0.4)
	var sc: Node = current_scene
	while int(sc.i) < upto:
		sc.press()
		sc.press()
		await process_frame
	await _wait(0.9)

func _run() -> void:
	await _wait(0.3)
	StoryState.new_game()
	await _scene_at("the_news", 4)
	await _shot("1_the_news")
	await _scene_at("the_news", 7)
	await _shot("2_the_news_choice")
	StoryState.step = _step_of(func(s): return s.type == "card" and String(s.title) == "JUNE 2020")
	change_scene_to_file("res://story/story.tscn")
	await _wait(1.4)
	await _shot("3_june_card")
	await _scene_at("frankie", 3)
	await _shot("4_frankie_fridge")
	await _scene_at("frankie", 7)
	await _shot("5_frankie_name")
	await _scene_at("frankie", 11)
	await _shot("6_gus")
	# the wall, a year and a half in: the later photos have him in them
	change_scene_to_file("res://title.tscn")
	await _wait(0.6)
	Awards.ensure()
	for i in Awards.LIST.size(): Awards.won[String(Awards.LIST[i].id)] = { "at": 0, "n": i }
	var w := EmployeeWall.new()
	w.size = Vector2(640, 360)
	current_scene.add_child(w)
	w.open()
	w.sel = 9
	await _wait(0.5)
	await _shot("7_wall_with_frankie")
	w.sel = 30
	w.scroll = 1
	await _wait(0.3)
	await _shot("8_wall_later")
	quit()
