## Scripted counter screenshots: godot --path game -- --counter-demo <out_dir>
extends Node

var scene: CounterScene
var out := "user://counter_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--counter-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()

func _shot(name: String) -> void:
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _field(doc: String, key: String) -> Dictionary:
	for f in scene.fields():
		if f.key == key and (doc == "" or f.get("doc", "") == doc): return f
	return {}

func _run() -> void:
	await _shot("1_brief")
	scene.press()
	await _shot("2_monday")
	scene.inspecting = true
	scene.pick(_field("reg", "vin"))
	scene.pick(_field("sheet", "vin"))
	scene.cur = Vector2(300, 250)
	await _shot("3_inspect_vin")
	scene.pick(_field("licence", "photo"))
	scene.pick(_field("", "person"))
	await _shot("4_inspect_photo")
	scene.stamp("APPROVED")
	await _shot("5_result")
	# Friday: the stolen list, the Familia, the sting
	scene.start_day(4)
	await _shot("6_friday_brief")
	for i in scene.line.size():
		if scene.line[i].kind == "familia":
			scene.idx = i
			break
	scene.next_customer()
	scene.inspecting = true
	scene.pick(_field("", "plate"))
	scene.pick(_field("", "bolo"))
	await _shot("7_friday_familia")
	scene.stamp("WRENCH")
	await _shot("8_familia_result")
	scene.idx = scene.line.size()
	scene.next_customer()
	await _shot("9_day_end")
	scene.end_day()
	await _shot("10_week_end")
	print("COUNTER DEMO DONE")
	get_tree().quit()
