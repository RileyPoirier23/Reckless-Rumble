## Scripted counter screenshots: godot --path game -- --counter-demo <out_dir>
## The line in the lot, ASK and a proof, the binder, Hatch and the notebook, the sticker log's
## gap, a Halloween mask, a warning, and the end of the day. Then Desk 2.1: a regular coming
## back, tint and a medical exemption, the courier's box, Hachey's audit, a busy day's tally,
## and the end of the run. Then Desk 2.2: a stolen part on a car and in a box, winter week's
## taxi and studs, Hachey pulling a box, and the new end of the run. Then Desk 2.3: Hachey
## reading a stolen car's file against its own week's list, and overtime (the picker, a cab in
## January, the streak, Mrs. Doiron's studs in May, the day-end record, Friday's bills). Then
## Desk 2.4: Gus's tool drawer under the day-end sheet, buying a tool, the date wheel and the UV
## lamp at the desk, and the relaxed clock on the week picker. `--only 24` takes just those.
extends Node

var scene: CounterScene
var out := "user://counter_shots"
var only := ""

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--counter-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	if a.has("--pad"): Hints.pad = true      # the controller's prompts
	var o := a.find("--only")
	if o >= 0 and o + 1 < a.size(): only = a[o + 1]
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
	if only == "24":
		await _desk24()
		await _done()
		return
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
	await _desk22()
	await _desk23()
	await _desk24()
	await _done()

func _done() -> void:
	# the room goes quiet before the lights go off (a sound still playing at exit leaks)
	for p in scene.audio.get_children(): if p is AudioStreamPlayer: (p as AudioStreamPlayer).stop()
	await get_tree().create_timer(0.5).timeout
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

## A fact on the desk by its kind of measure (tires, tint...).
func _measure(kind: String) -> Dictionary:
	for f in scene.fields():
		if f.key == "measure" and String(f.val.kind) == kind: return f
	return {}

func _rule(id: String) -> Dictionary:
	for f in scene.fields():
		if f.key == "rule" and f.val == id: return f
	return {}

func _desk22() -> void:
	DeskBook.reset()
	# Thursday of week 6: the parts list goes up, and a car with a stolen cat (and an invoice that says otherwise)
	scene.start_day(38)
	await _shot("21_brief_38")
	scene.press()
	scene.clock = 140.0
	scene.tick(0.01)
	var c := scene.rules.customer(38, "hot_part")
	while String(c.invoice.serial) == String(c.sheet.serial): c = scene.rules.customer(38, "hot_part")
	_serve(c)
	scene.tab = scene._tabs_today().find("POLICE")
	scene.inspecting = true
	scene.pick(_field("sheet", "serial"))
	scene.pick(_field("", "bolo"))
	scene.cur = Vector2(60, 250)
	await _shot("22_hot_part")
	scene.verdict = {}
	scene.pick(_field("invoice", "serial"))
	scene.pick(_field("sheet", "serial"))
	await _shot("23_invoice_vs_part")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("REPORT")
	await get_tree().create_timer(0.1).timeout
	await _shot("24_reported")
	scene.press()
	# a stolen part in Fundy's box
	_serve(scene.rules.courier(38, "hot_part"))
	scene.inspecting = true
	scene.pick(_field("slip", "serial"))
	scene.pick(_field("", "bolo"))
	await _shot("25_hot_box")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.1).timeout
	await _shot("26_hot_box_signed")
	scene.press()
	# week 8: winter tires on working cars
	scene.start_day(49)
	await _shot("27_brief_49")
	scene.press()
	scene.clock = 110.0
	scene.tick(0.01)
	var taxi := scene.rules.customer(49, "no_winter_tires")
	_serve(taxi)
	scene.tab = scene._tabs_today().find("SEASONAL")
	scene.inspecting = true
	scene.pick(_measure("tires"))
	scene.pick(_rule("winter"))
	await _shot("28_taxi_tires")
	scene.inspecting = false
	scene.verdict = {}
	# Wednesday: studs, and the calendar
	scene.start_day(51)
	await _shot("29_brief_51")
	scene.press()
	scene.clock = 165.0
	scene.tick(0.01)
	_serve(_booked("doiron"))
	scene.tab = scene._tabs_today().find("SEASONAL")
	scene.inspecting = true
	scene.pick(_measure("tires"))
	scene.pick(_rule("studs"))
	await _shot("30_studs_in_season")
	scene.inspecting = false
	scene.verdict = {}
	# Hachey pulls a box from week 5, signed for; Leo refuses it this time
	DeskBook.reset()
	scene.start_day(31)
	scene.press()
	_serve(scene.rules.box(31, "wrong_part"))
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.05).timeout
	scene.press()
	scene.start_day(42)
	scene.press()
	while scene.phase != "counter" or scene.c.kind != "audit":
		if scene.phase == "counter":
			scene.stamp("DENIED")
			scene._resolve()
		if scene.phase == "result": scene.press()
		scene.tick(0.1)
	scene.inspecting = true
	scene.pick(_field("order", "part"))
	scene.pick(_field("slip", "part"))
	await _shot("31_audit_box")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.1).timeout
	await _shot("32_audit_box_same")
	scene.press()
	scene.clock = CounterRules.SHIFT_LEN - 1.0
	scene.arrivals = []
	scene.tick(0.1)
	scene.close_up()
	await _shot("33_day_end_prompt")
	scene.day = CounterRules.LAST_DAY
	scene.phase = "month_end"
	await _shot("34_run_over")

## Tick the shift on until Hachey's at the window (anybody else gets DENIED).
func _until_hachey() -> void:
	for i in 6000:
		if scene.phase == "counter" and scene.c.kind == "audit": return
		if scene.phase == "counter":
			scene.stamp("DENIED")
			scene._resolve()
		if scene.phase == "result": scene.press()
		scene.tick(0.1)

func _desk23() -> void:
	# (the demo's overtime keeps out of the player's)
	DeskBook.overtime_path = "user://counter_demo_overtime.json"
	if FileAccess.file_exists(DeskBook.overtime_path): DirAccess.remove_absolute(DeskBook.overtime_path)
	DeskBook.reset()
	# a stolen car in week 5, approved; in week 7 Hachey pulls it, with week 5's list
	scene.start_day(31)
	scene.press()
	_serve(scene.rules.walk_in(31, "stolen"))
	scene.stamp("APPROVED")
	await get_tree().create_timer(0.05).timeout
	scene.press()
	scene.start_day(42)
	scene.press()
	_until_hachey()
	scene.tab = scene._tabs_today().find("POLICE")
	scene.inspecting = true
	scene.pick(_field("reg", "plate"))
	scene.pick(_field("", "bolo"))
	scene.cur = Vector2(560, 280)
	await _shot("35_audit_old_list")
	scene.inspecting = false
	scene.verdict = {}
	# OVERTIME on the week picker, after week 8
	DeskBook.reset()
	scene.fresh = true
	scene.start_day(49)
	await _shot("36_week8_brief_picker")
	scene._tab_step(1)
	await _shot("37_overtime_brief")
	scene.fresh = false
	# January: a cab up for its sticker on all-seasons, a month into overtime
	var jan := CounterRules.days_between(CounterRules.WEEK_START, [2020, 1, 14])
	DeskBook.overtime.merge({ "days": 29, "streak": 12, "best": 27 }, true)
	scene.start_day(jan)
	scene.press()
	scene.clock = 130.0
	scene.tick(0.01)
	var cab := scene.rules.customer(jan, "no_winter_tires")
	while String(cab.reg.use) == "COMMERCIAL": cab = scene.rules.customer(jan, "no_winter_tires")
	_serve(cab)
	scene.tab = scene._tabs_today().find("SEASONAL")
	scene.inspecting = true
	scene.pick(_measure("tires"))
	scene.pick(_rule("winter"))
	scene.cur = Vector2(60, 250)
	await _shot("38_overtime_january_cab")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("DENIED")
	await get_tree().create_timer(0.1).timeout
	await _shot("39_overtime_streak")
	scene.press()
	# May 1: the stud notice; then Mrs. Doiron, still on her studs
	DeskBook.overtime.merge({ "days": 98, "streak": 31, "best": 31 }, true)
	var may := CounterRules.days_between(CounterRules.WEEK_START, [2020, 5, 1])
	scene.start_day(may)
	await _shot("40_overtime_may_brief")
	scene.press()
	scene.clock = 150.0
	scene.tick(0.01)
	var studs := -1
	var ot: Array = DeskRegulars.regulars().doiron.overtime
	for k in ot.size(): if String(ot[k].problem) == "studs_out_of_season": studs = k
	_serve(scene.rules.scripted(DeskRegulars.spec("doiron", DeskRegulars.OT + studs, "?", may), may))
	scene.tab = scene._tabs_today().find("SEASONAL")
	scene.inspecting = true
	scene.pick(_measure("tires"))
	scene.pick(_rule("studs"))
	scene.cur = Vector2(60, 250)
	await _shot("41_overtime_may_studs")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("DENIED")
	await get_tree().create_timer(0.1).timeout
	scene.press()
	scene.clock = CounterRules.SHIFT_LEN - 1.0
	scene.arrivals = []
	scene.tick(0.1)
	scene.close_up()
	await _shot("42_overtime_day_end")
	scene.press()
	await _shot("43_overtime_friday")
	scene.overtime = false
	if FileAccess.file_exists(DeskBook.overtime_path): DirAccess.remove_absolute(DeskBook.overtime_path)

func _desk24() -> void:
	DeskBook.reset()
	scene.overtime = false
	scene.fresh = false
	# the end of a good Thursday in week 2: Gus's drawer under the day-end sheet
	scene.start_day(10)
	scene.press()
	scene.cash = 2140
	scene.clock = CounterRules.SHIFT_LEN - 1.0
	scene.arrivals = []
	scene.tick(0.1)
	scene.close_up()
	scene.day_log.merge({ "seen": 11, "correct": 10, "earned": 1065, "dirty": 600 }, true)
	scene.cur = CounterScene.DRAWER_HANDLE.get_center()
	await _shot("44_day_end_drawer")
	# pull it open, and buy the date wheel
	scene._tab_step(1)
	scene.cur = scene._drawer_rect(1).get_center()
	scene._drawer_hover()
	await _shot("45_drawer")
	scene.press()
	await _shot("46_drawer_bought")
	scene._cancel()
	# the next week (the lamp's in the drawer too by now): an expired registration, and a
	# temporary permit somebody made up
	DeskBook.tools = ["wheel", "lamp"]
	scene.start_day(15)
	scene.press()
	scene.clock = 140.0
	scene.tick(0.01)
	var c: Dictionary = {}
	for i in 60:
		c = scene.rules.customer(15, "clean", { "plain": true })
		scene.rules.excuse(c, 15, "expired_reg")
		scene.rules._proof(c, "expired_reg", 15, "bad")
		if DeskTools.forged(c, "permit"): break
	_serve(c)
	scene.tab = scene._tabs_today().find("DOCUMENTS")
	scene.inspecting = true
	var lapse := _field("reg", "expiry")
	scene.pick(lapse)
	scene.cur = (lapse.r as Rect2).get_center()
	await _shot("47_wheel_again")
	scene.pick(lapse)
	scene.cur = Vector2(60, 250)
	await _shot("48_wheel_expired")
	scene.ask("expired_reg")
	scene.verdict = {}
	var seal := _field("permit", "seal")
	scene.pick(seal)
	scene.pick(seal)
	scene.cur = (seal.r as Rect2).get_center() + Vector2(14, 10)
	await _shot("49_lamp_fake")
	scene.inspecting = false
	scene.verdict = {}
	scene.stamp("DENIED")
	await get_tree().create_timer(0.1).timeout
	scene.press()
	# ...and a bill of sale that's real: it glows
	var b := scene.rules.customer(15, "clean", { "plain": true })
	scene.rules.excuse(b, 15, "name_mismatch")
	_serve(b)
	scene.ask("name_mismatch")
	scene.inspecting = true
	var bs := _field("bos", "seal")
	scene.pick(bs)
	scene.pick(bs)
	scene.cur = Vector2(60, 250)
	await _shot("50_lamp_real")
	scene.inspecting = false
	scene.verdict = {}
	# the relaxed clock, next to the week picker
	DeskBook.reset()
	scene.fresh = true
	scene.start_day(14)
	scene.toggle_relaxed()
	await _shot("51_brief_relaxed")
	scene.fresh = false
	DeskBook.reset()
