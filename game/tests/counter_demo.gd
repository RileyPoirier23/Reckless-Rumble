## Scripted counter screenshots: godot --path game -- --counter-demo <out_dir>
## The line in the lot, ASK and a proof, the binder, Hatch and the notebook, the sticker log's
## gap, a Halloween mask, a warning, and the end of the day. Then Desk 2.1: a regular coming
## back, tint and a medical exemption, the courier's box, Hachey's audit, a busy day's tally,
## and the end of the run.
extends Node

var scene: CounterScene
var out := "user://counter_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--counter-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	if a.has("--pad"): Hints.pad = true      # the controller's prompts
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
	await _desk21()
	print("COUNTER DEMO DONE")
	get_tree().quit()

## Regular `id` out of today's line (still on the way, or already in the lot).
func _booked(id: String) -> Dictionary:
	for i in scene.arrivals.size():
		if String(scene.arrivals[i].c.get("regular", "")) == id: return scene.arrivals.pop_at(i).c
	for i in scene.waiting.size():
		if String(scene.waiting[i].get("regular", "")) == id: return scene.waiting.pop_at(i)
	return {}

func _desk21() -> void:
	# Jayden, turned away bald on Tuesday, back on the Friday of week two
	DeskBook.reset()
	scene.start_day(1)
	scene.press()
	_serve(_booked("jayden"))
	scene.stamp("DENIED")
	await get_tree().create_timer(0.1).timeout
	scene.press()
	scene.start_day(11)
	scene.press()
	scene.clock = 75.0
	scene.tick(0.01)
	_serve(_booked("jayden"))
	scene.cur = Vector2(60, 200)
	await _shot("12_regular_back")
	# Mrs. Doiron's tint, and her doctor's form out of the visor
	scene.start_day(29)
	scene.press()
	scene.clock = 120.0
	scene.tick(0.01)
	_serve(_booked("doiron"))
	scene.inspecting = true
	scene.tab = scene._tabs_today().find("INSPECTION")
	var tint := {}
	for f in scene.fields():
		if f.key == "measure" and String(f.val.kind) == "tint": tint = f
	scene.pick(tint)
	for f in scene.fields():
		if f.key == "rule" and f.val == "tint": scene.pick(f)
	scene.ask("tint")
	await _shot("13_tint_exemption")
	scene.verdict = {}
	scene.inspecting = false
	# the courier: the wrong part number on the slip
	scene.start_day(31)
	scene.press()
	scene.clock = 150.0
	scene.tick(0.01)
	var box := scene.rules.courier(31, "wrong_part")
	while not box.has("customs"): box = scene.rules.courier(31, "customs_value")
	_serve(box)
	scene.tab = scene._tabs_today().find("PARTS")
	scene.inspecting = true
	scene.pick(_field("order", "paid"))
	scene.pick(_field("customs", "paid"))
	await _shot("14_courier")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("DENIED")
	await get_tree().create_timer(0.1).timeout
	await _shot("15_courier_refused")
	scene.press()
	# Hachey's audit: a file from last week, the stamp under his thumb
	scene.start_day(39)
	scene.press()
	for want in ["expired_reg", "clean", "noise"]:
		_serve(scene.rules.walk_in(39, want))
		scene.stamp("DENIED" if want != "clean" else "APPROVED")
		await get_tree().create_timer(0.05).timeout
		scene.press()
	scene.start_day(42)
	scene.press()
	while scene.clock < 91.0:
		scene.tick(0.5)
		if scene.phase == "counter" and scene.c.kind != "audit":
			scene.stamp("DENIED")
			scene._resolve()
		if scene.phase == "result": scene.press()
	while scene.phase != "counter" or scene.c.kind != "audit":
		if scene.phase == "counter":
			scene.stamp("DENIED")
			scene._resolve()
		if scene.phase == "result": scene.press()
		scene.tick(0.1)
	scene.tab = scene._tabs_today().find("MINISTRY")
	scene.cur = Vector2(330, 250)
	await _shot("16_audit")
	scene.stamp("APPROVED" if String(scene.c.audit.stamp) == "DENIED" else "DENIED")
	await get_tree().create_timer(0.1).timeout
	await _shot("17_audit_disagree")
	scene.press()
	# a busy day's tally, and the end of the run
	scene.day_log.merge({ "fees": 75, "audits": 2, "audits_same": 1 }, true)
	scene.clock = CounterRules.SHIFT_LEN - 1.0
	scene.arrivals = []
	scene.tick(0.1)
	scene.close_up()
	await _shot("18_day_end_busy")
	scene.day = CounterRules.LAST_DAY
	scene.phase = "month_end"
	await _shot("19_audit_over")
	# the new mornings: the courier, Remembrance Day and the noise rule, and Hachey at the door
	for d in [30, 36, 42]:
		scene.start_day(d)
		await _shot("20_brief_%d" % d)
