## Scripted counter screenshots: godot --path game -- --counter-demo <out_dir>
## The line in the lot, ASK and a proof, the binder, Hatch and the notebook, the sticker log's
## gap, a Halloween mask, a warning, and the end of the day.
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

func _field(doc: String, key: String, row := "") -> Dictionary:
	for f in scene.fields():
		if f.key == key and (doc == "" or f.get("doc", "") == doc) and (row == "" or f.get("row", "") == row): return f
	return {}

## Put somebody at the window, ahead of the line.
func _serve(c: Dictionary) -> void:
	scene.waiting.push_front(c)
	scene.next_customer()

func _run() -> void:
	# Wednesday of week two: the binder, and a line building in the lot
	scene.start_day(9)
	await _shot("01_brief")
	scene.press()
	scene.clock = 170.0
	scene.tick(0.01)
	scene.since = 40.0
	scene.next_honk = 0.0
	scene.tick(0.01)
	scene.pad_cursor = true
	scene.cur = Vector2(330, 190)
	await _shot("02_queue")
	# a name that doesn't match, a question, and the bill of sale out of a pocket
	var r := scene.rules
	var cb := r.customer(10, "clean", { "plain": true })
	r.excuse(cb, 10, "name_mismatch")
	scene.day = 10
	_serve(cb)
	scene.inspecting = true
	scene.pick(_field("reg", "owner"))
	scene.pick(_field("licence", "name"))
	scene.cur = Vector2(60, 250)
	await _shot("03_red_then_ask")
	scene.ask("name_mismatch")
	scene.verdict = {}
	scene.pick(_field("bos", "sold"))
	scene.pick(_field("", "today"))
	await _shot("04_bill_of_sale")
	# Dale Hatch, small talk, and the notebook
	scene.day = 9
	scene.inspecting = false
	for x in r.shift(9):
		if String(x.c.get("script", {}).get("id", "")) == "dale_hatch": _serve(x.c)
	scene.ask("local")
	scene.inspecting = true
	scene.pick(_field("", "says"))
	scene.pick(_field("", "notebook"))
	await _shot("05_hatch_noted")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.1).timeout
	scene.press()
	scene.open_book("notebook")
	await _shot("06_notebook")
	# last fall's sticker log, and the page that isn't there
	DeskBook.old_log = true
	scene.open_book("log")
	scene.log_old = true
	scene.inspecting = true
	var s47: Dictionary = {}
	var s49: Dictionary = {}
	for f in scene.fields():
		if f.key == "sticker" and int(f.val) == 447: s47 = f
		if f.key == "sticker" and int(f.val) == 449: s49 = f
	scene.pick(s47)
	scene.pick(s49)
	await _shot("07_sticker_gap")
	scene.book = ""
	scene.inspecting = false
	scene.verdict = {}
	# Halloween: a mask at the counter, the MINISTRY tab
	scene.start_day(24)
	scene.press()
	var cm := r.customer(24, "photo_mismatch", { "plain": true })
	cm.mask = "GOALIE"
	_serve(cm)
	scene.tab = scene._tabs_today().find("SEASONAL")
	scene.inspecting = true
	scene.pick(_field("licence", "photo"))
	scene.pick(_field("", "person"))
	await _shot("08_mask")
	scene.inspecting = false
	scene.ask("mask")
	scene.verdict = {}
	scene.inspecting = true
	scene.pick(_field("licence", "photo"))
	scene.pick(_field("", "person"))
	await _shot("09_photo")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.1).timeout
	scene.tab = scene._tabs_today().find("MINISTRY")
	await _shot("10_warning")
	scene.press()
	scene.clock = CounterRules.SHIFT_LEN - 1.0
	scene.arrivals = []
	scene.tick(0.1)
	scene.close_up()
	await _shot("11_day_end")
	print("COUNTER DEMO DONE")
	get_tree().quit()
