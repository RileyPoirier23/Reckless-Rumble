## Headless tests for the desk itself (the scene, not just the rules): the shift clock and the
## line, warnings, ASK, the notebook and the sticker log, the binder, the controls, Desk 2.2's
## stolen parts, winter week and wider audit, Desk 2.3's weekly stolen lists and overtime, and
## Desk 2.4's tool drawer, the tools at the desk, the relaxed clock, and faces that age.
## godot --headless --path game -s tests/desk_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

## A counter with no window around it: the same scene the game runs, minus the tree.
func desk(seed := 11) -> CounterScene:
	var sc := CounterScene.new()
	sc.rules = CounterRules.new(seed)
	sc.rules.make_bolo()
	sc.car_view = CarView.new()
	sc._new_week()
	return sc

func done(sc: CounterScene) -> void:
	sc.car_view.free()
	sc.free()

## Stamp whoever's at the window, as if the stamp had landed.
func stamp_now(sc: CounterScene, s: String) -> void:
	sc.stamp(s)
	sc._resolve()

func field(sc: CounterScene, doc: String, key: String) -> Dictionary:
	for f in sc.fields():
		if f.key == key and (doc == "" or f.get("doc", "") == doc): return f
	return {}

## Overtime keeps its book in a file: the tests keep theirs out of the player's way.
const TEST_OVERTIME := "user://desk_tests_overtime.json"

func _wipe_overtime() -> void:
	if FileAccess.file_exists(TEST_OVERTIME): DirAccess.remove_absolute(TEST_OVERTIME)

func _init() -> void:
	CounterScene.setup_actions()
	DeskBook.reset()
	DeskBook.overtime_path = TEST_OVERTIME
	_wipe_overtime()
	_controls()
	_shift()
	_warnings()
	_ask()
	_books()
	_days()
	_fixes()
	_regulars()
	_memory()
	_courier()
	_audit()
	_sounds()
	_layout()
	_hot_desk()
	_winter_desk()
	_audit_more()
	_list_desk()
	_overtime_desk()
	_drawer_desk()
	_tools_desk()
	_relaxed_desk()
	_saved_desk()
	_ages_desk()
	_wipe_overtime()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

# ------------------------------------------------------------------ controls

func _controls() -> void:
	# every desk action has a key, and everything but the number-key stamps has a pad button
	var keys_ok := true
	var pad_ok := true
	for action in CounterScene.ACTIONS:
		var has_key := false
		var has_pad := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey: has_key = true
			if e is InputEventJoypadButton: has_pad = true
		if not has_key: keys_ok = false
		if not has_pad and not action in ["desk_approve", "desk_deny", "desk_report", "desk_wrench"]: pad_ok = false
	check("every desk action has a key", keys_ok)
	check("every desk action has a controller button", pad_ok)
	for a in ["inspect", "desk_click", "desk_cancel", "menu_back"]:
		var sc := desk()
		sc.start_day(1)
		Hints.pad = false
		var kb := Hints.key(a)
		Hints.pad = true
		var pd := Hints.key("ui_back_pad" if a == "menu_back" else a)
		Hints.pad = false
		check("%s reads right on both: %s / %s" % [a, kb, pd], kb != "" and pd != "" and kb != pd)
		done(sc)
	# the stamps, the questions and the books are all reachable with the pad's cursor
	var sc := desk()
	sc.start_day(9)
	sc.press()
	sc.clock = 200.0
	sc.tick(0.01)
	var ts := sc.targets()
	var all_there := true
	for i in CounterScene.BUTTONS.size(): if not ts.has(sc._button_rect(i).get_center()): all_there = false
	for row in sc._ask_rows(): if not ts.has((row.r as Rect2).get_center()): all_there = false
	if not ts.has(CounterScene.NOTEBOOK_ICON.get_center()) or not ts.has(CounterScene.LOG_ICON.get_center()): all_there = false
	check("stamps, questions, tabs and books are all snap targets", all_there and ts.size() > 10, "%d targets" % ts.size())
	sc.cur = Vector2(0, 0)
	sc.snap(1)
	check("the D-pad jumps the cursor to the next thing", ts.has(sc.cur) and sc.pad_cursor)
	sc.cur = sc._button_rect(2).get_center()
	sc.press()
	check("pointing at DENY and pressing A stamps it", sc.stamped == "DENIED" and sc.phase == "stamping")
	done(sc)
	# no prompt on the desk spells out a key: they all come from Hints
	var src := FileAccess.get_file_as_string("res://counter/counter_scene.gd")
	var raw := 0
	for w in ["\"SPACE", "\"ENTER", "\"ESC", "CLICK OR", "PRESS SPACE", "(I OR Y)"]: if src.contains(w): raw += 1
	check("every on-screen prompt goes through Hints", raw == 0, "%d raw" % raw)

# ------------------------------------------------------------------ the shift

func _shift() -> void:
	var sc := desk(21)
	sc.start_day(10)
	var total := sc.arrivals.size()
	check("the day opens on the brief, clock at 8:00", sc.phase == "brief" and sc.clock == 0.0)
	sc.press()
	check("opening the window starts the shift", sc.phase == "idle")
	var honked := false
	var max_line := 0
	var hold := 0.0
	for i in 2000:
		sc.tick(1.0)
		max_line = maxi(max_line, sc.waiting.size())
		if sc.honk_t > 0.0: honked = true
		if sc.phase == "counter":
			hold += 1.0
			# a slow, careful clerk: an hour and three quarters with the first, an hour with the rest
			if hold >= (105.0 if sc.served == 0 else 60.0):
				stamp_now(sc, "DENIED")
				hold = 0.0
		if sc.phase == "result":
			sc.press()
		if sc.phase == "day_end": break
	check("the shift clock ends the day at 6:00", sc.phase == "day_end" and sc.clock == CounterRules.SHIFT_LEN, "%s at %.0f" % [sc.phase, sc.clock])
	check("a line builds in the lot", max_line >= 2, "%d at most" % max_line)
	check("the next one honks when you take too long", honked)
	check("whoever's left at six drives off, and the money with them", sc.day_log.walked > 0 and sc.day_log.walked_money > 0, "%d walked" % sc.day_log.walked)
	check("everybody who came was served or walked", sc.served + sc.walked.size() == total, "%d + %d vs %d" % [sc.served, sc.walked.size(), total])
	check("a careful clerk serves 6 to 10 a day", sc.served >= 6 and sc.served <= 10, "%d" % sc.served)
	done(sc)
	# a quick clerk: the day still ends at clock-out, not when the line's empty
	sc = desk(22)
	sc.start_day(3)
	sc.press()
	for i in 4000:
		sc.tick(1.0)
		if sc.phase == "counter": stamp_now(sc, "APPROVED")
		if sc.phase == "result": sc.press()
		if sc.phase == "day_end": break
	check("a quick clerk still clocks out at six, with nobody left behind", sc.phase == "day_end" and sc.clock == CounterRules.SHIFT_LEN and sc.day_log.walked == 0)
	done(sc)
	# the first morning: a short line, all there by nine, with the Familia's napkin second
	sc = desk(23)
	sc.tutorial = true
	sc.start_day(0)
	check("the tutorial line is five, the napkin second", sc.arrivals.size() == 5 and sc.arrivals[1].c.kind == "familia" and String(sc.arrivals[1].c.napkin).ends_with("-S"))
	done(sc)

# ------------------------------------------------------------------ warnings

func _warnings() -> void:
	var sc := desk(31)
	sc.start_day(9)
	sc.press()
	var fines: Array = []
	for i in 3:
		sc.waiting.push_front(sc.rules.customer(9, "vin_mismatch"))
		sc.next_customer()
		stamp_now(sc, "APPROVED")
		fines.append(sc.result.fine)
		sc.press()
	check("two Ministry warnings a shift, then $100 citations", fines == [0, 0, CounterRules.FINE] and sc.warnings_used == 2, str(fines))
	check("the warnings are logged, the fine is on the licence", sc.day_log.warnings.size() == 2 and sc.day_log.citations.size() == 1)
	sc.start_day(10)
	check("a new shift, two fresh warnings", sc.warnings_used == 0)
	done(sc)

# ------------------------------------------------------------------ ASK

func _ask() -> void:
	var sc := desk(41)
	sc.start_day(10)
	sc.press()
	var c := sc.rules.customer(10, "clean", { "plain": true })
	sc.rules.excuse(c, 10, "name_mismatch")
	sc.waiting.push_front(c)
	sc.next_customer()
	check("the bill of sale starts in their pocket", not sc.docs.any(func(d): return d.id == "bos"))
	check("nothing proven yet: only the questions you can always ask", not sc.ask_list().has("name_mismatch"))
	sc.inspecting = true
	sc.pick(field(sc, "reg", "owner"))
	sc.pick(field(sc, "licence", "name"))
	check("a red verdict puts the question at the top of the list", sc.verdict.good == false and sc.ask_list()[0] == "name_mismatch")
	sc.ask_next()
	check("ASK: out comes the bill of sale, onto the desk", sc.docs.any(func(d): return d.id == "bos") and not c.hidden.has("bos") and sc.asked.has("name_mismatch"))
	check("Leo's question and their answer are in the bubble", String(sc._bubble().text) == String(CounterRules.answer(c, "name_mismatch").line))
	sc.pick(field(sc, "bos", "sold"))
	sc.pick(field(sc, "", "today"))
	check("the bill of sale checks out against the calendar", sc.verdict.good == true)
	stamp_now(sc, "APPROVED")
	check("approving a covered car is the right call", sc.result.correct and sc.result.citation == "")
	sc.press()
	# a mask at the counter
	var m := sc.rules.customer(24, "clean", { "plain": true })
	m.mask = "PUMPKIN"
	sc.day = 24
	sc.waiting.push_front(m)
	sc.next_customer()
	check("a mask is on the ASK list", sc.ask_list().has("mask"))
	sc.ask("mask")
	check("ASK about the mask: it comes off", m.mask == "")
	done(sc)

# ------------------------------------------------------------------ the notebook and the sticker log

func _books() -> void:
	DeskBook.reset()
	var sc := desk(51)
	sc.start_day(9)
	sc.press()
	var hatch: Dictionary = {}
	for x in sc.arrivals: if String(x.c.get("script", {}).get("id", "")) == "dale_hatch": hatch = x.c
	check("Dale Hatch is in Wednesday's line", not hatch.is_empty())
	sc.waiting.push_front(hatch)
	sc.next_customer()
	check("Hatch leaves a letter on the desk", sc.docs.any(func(d): return d.id == "letter"))
	sc.ask("local")
	sc.inspecting = true
	sc.pick(field(sc, "", "says"))
	sc.pick(field(sc, "", "notebook"))
	check("what Hatch says goes in the notebook", DeskBook.has_note("hatch_sundays") and sc.verdict.good == true)
	check("...and the story hears about it", DeskBook.flags.has("desk_note_hatch_sundays"))
	sc.pick(field(sc, "", "says"))
	sc.pick(field(sc, "", "notebook"))
	check("writing it twice doesn't", DeskBook.notes.size() == 1)
	sc.inspecting = false
	stamp_now(sc, "APPROVED")
	check("an approved inspection puts sticker %04d in the log" % DeskBook.FIRST_STICKER, int(sc.result.sticker) == DeskBook.FIRST_STICKER and DeskBook.stickers.size() == 1)
	check("Hatch's stamp raises his flags", DeskBook.flags.has("desk_dale_hatch_approved") and DeskBook.flags.has("hatch_offer_seen"))
	sc.press()
	sc.open_book("notebook")
	check("the notebook opens on the desk, its entries pickable", sc.book == "notebook" and sc.fields().any(func(f): return f.key == "note"))
	sc.open_book("log")
	check("the sticker log opens", sc.book == "log" and sc.fields().any(func(f): return f.key == "sticker"))
	DeskBook.old_log = true
	sc.log_old = true
	var v := sc.compare({ "key": "sticker", "val": 447 }, { "key": "sticker", "val": 449 })
	check("last fall's log: 0447 against 0449 shows the gap", v[1] == false and String(v[0]).contains("0448"))
	check("the gap goes in the notebook, and to the story", DeskBook.has_note("sticker_gap") and DeskBook.flags.has("desk_sticker_gap"))
	check("0440 against 0441 is in order", sc.compare({ "key": "sticker", "val": 440 }, { "key": "sticker", "val": 441 })[1] == true)
	done(sc)
	# the book rides along in the story's save
	var was := StoryState.active
	StoryState.active = true
	StoryState.flags = {}
	DeskBook.close_book()
	check("clock-out hands the desk's flags to the story", StoryState.flag("desk_note_hatch_sundays") and StoryState.flags.get("desk_book", null) is Dictionary)
	DeskBook.reset()
	DeskBook.open_book()
	check("and the next shift opens the same book", DeskBook.has_note("hatch_sundays") and DeskBook.stickers.size() == 1 and DeskBook.old_log)
	StoryState.active = was
	StoryState.flags = {}
	DeskBook.reset()

# ------------------------------------------------------------------ days, weeks, the binder

func _days() -> void:
	var sc := desk(61)
	sc.fresh = true
	sc.start_day(0)
	sc._tab_step(1)
	check("free play: pick the week on the first brief", sc.day == 8 and sc.phase == "brief")
	sc._tab_step(-1)
	check("...and back", sc.day == 0)
	sc.start_day(8)
	var tabs := sc._tabs_today()
	check("week two: the binder has tabs", CounterRules.binder(8) and tabs.size() >= 3, str(tabs))
	sc.fresh = false
	var t0 := sc.tab
	sc._tab_step(1)
	check("LB/RB turn the binder's tabs", sc.tab == posmod(t0 + 1, tabs.size()))
	var shown := sc._rule_blocks().filter(func(b): return b.has("rule")).map(func(b): return b.rule.tab)
	check("a tab shows only its own rules", shown.all(func(x): return x == tabs[sc.tab]))
	sc.tab = tabs.find("DOCUMENTS")
	check("week two opens at the newest rule's tab", sc._newest_tab() == tabs.find("DOCUMENTS"))
	# Wednesday ends into Thursday; Friday into the bills; the last Friday into the month
	sc.start_day(9)
	sc.close_up()
	sc.end_day()
	check("Wednesday's clock-out opens Thursday", sc.day == 10 and sc.phase == "brief")
	sc.start_day(11)
	sc.close_up()
	sc.end_day()
	check("Friday's clock-out is the bills", sc.phase == "week_end" and sc.bills_paid.size() == CounterRules.BILLS.size())
	sc._after_week()
	check("the weekend, then Monday of week three", sc.day == 14 and sc.phase == "brief")
	sc.start_day(CounterRules.LAST_DAY)
	sc.close_up()
	sc.end_day()
	sc._after_week()
	check("the last Friday ends the month", sc.phase == "month_end")
	DeskBook.citations = CounterRules.REVOKE_AT
	sc.phase = "week_end"
	sc._after_week()
	check("twelve citations and the licence is gone", sc.phase == "revoked")
	DeskBook.reset()
	done(sc)

# ------------------------------------------------------------------ the fix list

func _fixes() -> void:
	var sc := desk(71)
	var keep: Dictionary = StoryState.avatar.duplicate()
	StoryState.avatar.name = "RAY MELANSON"
	sc.tutorial = true
	sc.start_day(0)
	var brief := " ".join(sc._brief_paras())
	check("fix 2: the tutorial says THE OLD MANAGER'S MUG, never the name", brief.contains("THE OLD MANAGER'S MUG") and not brief.contains("RAY MELANSON"))
	StoryState.avatar = keep
	check("fix 3: Frank ran the shop; the counter was somebody else's", " ".join(CounterScene.BRIEFS[0]).contains("THE COUNTER WAS SOMEBODY ELSE'S"))
	check("there's no Vinny on the napkins", not FileAccess.get_file_as_string("res://counter/counter_scene.gd").contains("-V\""))
	done(sc)

# ------------------------------------------------------------------ Desk 2.1: the regulars

## Whoever's booked into the day's line with this id ({} if nobody).
func booked(sc: CounterScene, id: String) -> Dictionary:
	for x in sc.arrivals:
		if String(x.c.get("regular", "")) == id: return x.c
	return {}

## Put somebody at the window and stamp them.
func serve(sc: CounterScene, c: Dictionary, s: String) -> void:
	sc.waiting.push_front(c)
	sc.next_customer()
	stamp_now(sc, s)
	sc.press()

func _regulars() -> void:
	# Jayden's bald tire: what you stamp on Tuesday decides who comes back on Friday of week two
	for way in ["DENIED", "APPROVED", "WALKED"]:
		DeskBook.reset()
		var sc := desk(81)
		sc.start_day(1)
		sc.press()
		var j := booked(sc, "jayden")
		check("Jayden's in Tuesday's line (%s)" % way, not j.is_empty() and j.flags == ["fails_inspection"])
		if way == "WALKED":
			sc.walked.append(j)
			sc.close_up()
		else: serve(sc, j, way)
		sc.start_day(11)
		var back := booked(sc, "jayden")
		var says := String(back.get("says", ""))
		match way:
			"DENIED": check("turned away, Jayden comes back with four used tires and a box for Gus", back.flags.is_empty() and says.begins_with("FOUR TIRES"))
			"APPROVED": check("passed bald, Jayden comes back off the causeway for a brake job", back.flags.is_empty() and back.request == "BRAKE JOB" and says.contains("CAUSEWAY"))
			"WALKED": check("left in the lot, Jayden comes back still bald, and says so", back.flags == ["fails_inspection"] and says.begins_with("I WAITED TILL SIX"))
		check("...the same kid in the same Civil (%s)" % way, int(back.person.face) == int(j.person.face) and back.car.plate == j.car.plate)
		done(sc)
	# Mrs. Doiron's light: pass it and she knows Frank never did
	DeskBook.reset()
	var sc := desk(82)
	sc.start_day(2)
	sc.press()
	var d := booked(sc, "doiron")
	sc.waiting.push_front(d)
	sc.next_customer()
	stamp_now(sc, "APPROVED")
	check("pass Mrs. Doiron's dead light and she asks if you're feeling all right", String(sc.result.line).contains("FEELING ALL RIGHT") or String(sc.result.line).contains("feeling all right"))
	check("...and it's a citation", sc.result.citation != "")
	sc.press()
	sc.start_day(10)
	check("a week later the light's still out, and a policeman's asked about her sticker", String(booked(sc, "doiron").says).contains("POLICEMAN"))
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ the filing cabinet and the save

func _memory() -> void:
	DeskBook.reset()
	var sc := desk(91)
	sc.start_day(12)
	sc.press()
	# somebody turned away for no insurance comes back; find one who will
	var c: Dictionary = {}
	for i in 200:
		var w := sc.rules.walk_in(12, "insurance_expired")
		if posmod(int(w.seed) >> 4, 10) < 6:
			c = w
			break
	serve(sc, c, "DENIED")
	var rec: Dictionary = DeskBook.files[DeskBook.files.size() - 1]
	check("every stamp goes in the filing cabinet", rec.stamp == "DENIED" and rec.correct and rec.probs == ["insurance_expired"] and int(rec.seed) == int(c.seed))
	# the cabinet rides along in the story's save, through JSON and back
	var was := StoryState.active
	StoryState.active = true
	StoryState.flags = {}
	DeskBook.close_book()
	var saved = JSON.parse_string(JSON.stringify(StoryState.flags))
	DeskBook.reset()
	StoryState.flags = saved
	DeskBook.open_book()
	check("the filing cabinet survives the save", DeskBook.files.size() == 1 and int(DeskBook.files[0].seed) == int(c.seed) and DeskBook.files[0].seed is int)
	StoryState.active = was
	StoryState.flags = {}
	var due := DeskRegulars.due(DeskBook.files[0])
	sc.start_day(due)
	var backs := sc.arrivals.filter(func(x): return int(x.c.get("script", {}).get("of", 0)) == int(rec.no))
	check("they come back, the same person in the same car", backs.size() == 1 and int(backs[0].c.person.face) == int(c.person.face) and backs[0].c.car.vin == c.car.vin)
	if backs.size() == 1:
		serve(sc, backs[0].c, "APPROVED")
		check("...and once they're served, that file's closed", DeskBook.file_no(int(rec.no)).get("back", false) and DeskRegulars.returns(due).is_empty())
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ the courier at the window

func _courier() -> void:
	DeskBook.reset()
	var sc := desk(101)
	sc.start_day(31)
	sc.press()
	var box := sc.rules.courier(31, "wrong_part")
	while box.courier != "fundy": box = sc.rules.courier(31, "wrong_part")
	sc.waiting.push_front(box)
	sc.next_customer()
	check("the courier's papers: our order and their slip on the desk", sc.docs.any(func(x): return x.id == "order") and sc.docs.any(func(x): return x.id == "slip"))
	sc.inspecting = true
	sc.pick(field(sc, "order", "part"))
	sc.pick(field(sc, "slip", "part"))
	check("the part numbers don't match, and that's a question", sc.verdict.good == false and sc.ask_list()[0] == "wrong_part")
	sc.inspecting = false
	sc.stamp("DENIED")
	check("the stamp goes on the packing slip", sc.docs[sc.docs.size() - 1].id == "slip")
	sc._resolve()
	check("refusing the wrong part is the right call", sc.result.correct)
	sc.press()
	var again := sc.rules.courier(32, "clean")
	while again.courier != "fundy": again = sc.rules.courier(32, "clean")
	check("Fundy's driver remembers the box you sent back", String(again.says).contains("RODNEY TRIPLE-CHECKED"))
	sc.waiting.push_front(sc.rules.courier(31, "wrong_part"))
	sc.next_customer()
	var cash0 := sc.cash
	stamp_now(sc, "APPROVED")
	check("signing for the wrong part costs a fee off the till, not a citation", sc.cash < cash0 and sc.day_log.fees > 0 and sc.result.citation == "" and sc.warnings_used == 0)
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ the Ministry's audit

func _audit() -> void:
	DeskBook.reset()
	var sc := desk(111)
	# a few work orders from the week before
	sc.start_day(39)
	sc.press()
	var stamps: Array = []
	for i in 4:
		var w := sc.rules.walk_in(39, ["expired_reg", "clean", "tint", "clean"][i])
		var s: String = ["DENIED", "APPROVED", "APPROVED", "DENIED"][i]
		serve(sc, w, s)
		stamps.append(s)
	sc.close_up()
	sc.start_day(42)
	check("Monday of week 7: Hachey's booked for 9:30 and 2:00", sc.arrivals.filter(func(x): return x.c.kind == "audit").size() == 2)
	sc.press()
	var busy := sc.rules.walk_in(42)
	sc.waiting.push_front(busy)
	sc.next_customer()
	while sc.clock < 91.0: sc.tick(0.5)
	check("the Ministry doesn't wait in line", sc.waiting.size() > 0 and sc.waiting[0].kind == "audit" and sc.waiting[0].has("audit"))
	stamp_now(sc, "DENIED")
	sc.press()
	check("Hachey at the window, with one of your files", sc.c.kind == "audit" and DeskBook.file_no(int(sc.c.audit.no)).get("pulled", false))
	check("the car's long gone: no plate on a car, no calendar, the bay's empty", not sc.car_view.visible and not sc.fields().any(func(f): return String(f.get("doc", "")) == "car" or String(f.get("label", "")) == "TODAY"))
	check("the work order carries the file's date", sc._rows("work").any(func(x): return x[2] == "today" and x[3] == CounterRules.today(39)))
	var was := String(sc.c.audit.stamp)
	stamp_now(sc, was)
	check("stamp it the same way: no citation, consistent", sc.result.correct and sc.result.citation == "" and sc.day_log.audits_same == 1)
	sc.press()
	while sc.clock < 361.0:
		sc.tick(0.5)
		if sc.phase == "counter" and sc.c.kind != "audit": stamp_now(sc, "DENIED")
		if sc.phase == "result": sc.press()
	var a: Dictionary = sc.c if sc.phase == "counter" and sc.c.kind == "audit" else {}
	if a.is_empty():
		for i in 60:
			sc.tick(0.5)
			if sc.phase == "counter" and sc.c.kind == "audit":
				a = sc.c
				break
			if sc.phase == "counter": stamp_now(sc, "DENIED")
			if sc.phase == "result": sc.press()
	check("the second file comes at two", not a.is_empty())
	if not a.is_empty():
		var other := "APPROVED" if String(a.audit.stamp) == "DENIED" else "DENIED"
		var w0 := sc.warnings_used
		stamp_now(sc, other)
		check("stamp it differently: the Ministry writes it up", not sc.result.correct and String(sc.result.citation).begins_with("AUDIT") and (sc.warnings_used == w0 + 1 or sc.result.fine > 0))
		sc.press()
	check("Hachey keeps the tally for his report", DeskBook.audits.size() == 2 and sc.audit_verdict().contains("2 FILES PULLED"))
	done(sc)
	# a fresh week 7 with nothing in the cabinet: he waits, and comes back
	DeskBook.reset()
	sc = desk(112)
	sc.start_day(42)
	sc.press()
	while sc.clock < 100.0: sc.tick(0.5)
	check("nothing to pull: Hachey comes back in an hour", not sc.waiting.any(func(x): return x.kind == "audit") and sc.arrivals.any(func(x): return x.c.kind == "audit" and x.c.get("retry", false)))
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ the room's sounds

func _sounds() -> void:
	# every sound is made in code, short, and kept quiet
	var ok := true
	var note := ""
	for s in DeskAudio.LEVEL:
		var smp := DeskAudio.samples(s)
		var peak := 0.0
		for x in smp: peak = maxf(peak, absf(x))
		var secs := float(smp.size()) / DeskAudio.RATE
		if smp.is_empty() or peak > 0.95 or peak < 0.1 or secs > 1.0 or float(DeskAudio.LEVEL[s]) > -8.0:
			ok = false
			if note == "": note = "%s: peak %.2f, %.2f s, %.0f dB" % [s, peak, secs, DeskAudio.LEVEL[s]]
		if DeskAudio.sound(s).data.size() != smp.size() * 2: ok = false
	check("every desk sound is made in code, short and quiet", ok, note)
	# and the desk asks for them at the right moments
	DeskBook.reset()
	var sc := desk(121)
	sc.start_day(9)
	sc.press()
	sc.waiting.push_front(sc.rules.customer(9, "vin_mismatch"))
	sc.next_customer()
	check("the papers land on the desk with a shuffle", sc.heard.has("paper"))
	sc.waiting.append(sc.rules.customer(9, "clean"))
	sc.since = sc.clock - 200.0
	sc.next_honk = 0.0
	sc.tick(1.1)
	check("the horn from the lot when you take too long", sc.heard.has("honk"))
	check("the wall clock ticks", sc.heard.has("tick") or sc.heard.has("tock"))
	sc.heard = []
	sc.stamp("APPROVED")
	check("the stamp comes down with a thunk", sc.heard.has("stamp"))
	sc._resolve()
	sc.press()
	sc.heard = []
	for i in 2:
		sc.waiting.push_front(sc.rules.customer(9, "vin_mismatch"))
		sc.next_customer()
		stamp_now(sc, "APPROVED")
		sc.press()
	check("the till rings when the Ministry takes its hundred", sc.heard.has("till") and sc.day_log.fines > 0)
	sc.open_book("notebook")
	check("the notebook opens with a page", sc.heard.has("page"))
	check("the warnings don't ring the till", sc.heard.count("till") == 1)
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ the day-end sheet and the binder

func _layout() -> void:
	# a busy day in audit week: everything on the sheet at once, every row at the same size,
	# values lined up on the right, nothing running into anything
	var sc := desk(131)
	sc.start_day(42)
	sc.day_log.merge({ "seen": 14, "correct": 9, "walked": 6, "walked_money": 1265, "earned": 1840, "dirty": 600, "fees": 75,
		"citations": ["A", "B", "C"], "warnings": ["D", "E"], "fines": 300, "reviews": -3, "heat": 25, "trust": -15, "audits": 2, "audits_same": 1 }, true)
	sc.cash = -12345
	var rows := sc._day_end_rows()
	var fits := true
	var note := ""
	for row in rows:
		var lw := PixelFont.width(String(row[0]), 2)
		var vw := PixelFont.width(String(row[1]), 2)
		if CounterScene.LEDGER_L + lw + 12.0 > CounterScene.LEDGER_R - vw:
			fits = false
			if note == "": note = "%s / %s" % [row[0], row[1]]
	check("the day-end rows all fit at the labels' size, values lined up on the right", fits, note)
	check("every row of a busy day is on the sheet", rows.size() >= 11)
	sc.day_log.citations = ["AUDIT: YOUR OWN WORK ORDER SAYS APPROVED. TODAY YOU SAY DENIED. THE MINISTRY WOULD LIKE YOU TO PICK ONE", "B", "C"]
	var small := sc._small_print()
	check("the small print wraps instead of running off the sheet, four lines at most", small.size() <= 4 and small.all(func(l): return PixelFont.width(String(l)) <= CounterScene.LEDGER_R - CounterScene.LEDGER_L))
	check("the sheet and its small print stay above the prompts", 66 + rows.size() * CounterScene.LEDGER_PITCH + 6 + small.size() * 8 + 10 < 296)
	done(sc)
	# every tab of the binder fits on its page, every day of the run
	sc = desk(132)
	var over := ""
	for day in CounterRules.LAST_DAY + 1:
		if not CounterRules.is_open(day): continue
		sc.day = day
		for t in sc._tabs_today().size():
			sc.tab = t
			var blocks := sc._rule_blocks()
			if blocks.is_empty(): continue
			var last: Rect2 = blocks[blocks.size() - 1].r
			if last.end.y > CounterScene.BOARD.end.y - 10 and over == "": over = "day %d %s" % [day, sc._tabs_today()[t]]
	check("every tab of the binder fits on its page", over == "", over)
	sc.day = CounterRules.LAST_DAY
	var tabs := sc._tabs_today()
	var n := tabs.size()
	var labels_fit := true
	for t in n: if PixelFont.width(String(CounterScene.TAB_SHORT[tabs[t]])) > sc._tab_rect(t, n).size.x: labels_fit = false
	check("the binder's tabs (PARTS too) fit across the top", n == CounterRules.TABS.size() and sc._tab_rect(n - 1, n).end.x <= CounterScene.BOARD.end.x and labels_fit)
	done(sc)

# ------------------------------------------------------------------ Desk 2.2: stolen parts at the desk

func _hot_desk() -> void:
	DeskBook.reset()
	var sc := desk(141)
	sc.start_day(38)
	sc.press()
	var c := sc.rules.customer(38, "hot_part")
	while String(c.invoice.serial) == String(c.sheet.serial): c = sc.rules.customer(38, "hot_part")
	sc.waiting.push_front(c)
	sc.next_customer()
	check("a new part comes with its invoice on the desk", sc.docs.any(func(d): return d.id == "invoice"))
	sc.inspecting = true
	sc.pick(field(sc, "invoice", "serial"))
	sc.pick(field(sc, "", "bolo"))
	check("the invoice's serial against the stolen list: not on it", sc.verdict.good == true)
	sc.pick(field(sc, "sheet", "serial"))
	sc.pick(field(sc, "", "bolo"))
	check("the serial Gus read off the part: on the list, and that's a question", sc.verdict.good == false and sc.ask_list()[0] == "hot_part")
	sc.ask_next()
	check("ASK about the serial: a story", CounterRules.EXCUSES["hot_part"].has(String(sc._bubble().text)))
	sc.inspecting = false
	var w0 := sc.warnings_used
	stamp_now(sc, "REPORT")
	check("REPORT a stolen part: the right call", sc.result.correct and sc.result.citation == "" and sc.warnings_used == w0)
	sc.press()
	sc.waiting.push_front(sc.rules.courier(38, "hot_part"))
	sc.next_customer()
	stamp_now(sc, "APPROVED")
	check("sign for a stolen part: the police fine, never a free warning", not sc.result.correct and sc.result.fine == CounterRules.FINE * 2 and sc.warnings_used == w0)
	sc.press()
	# the wall: six cars and four serials still fit on the sheet
	var lines := 12.0 + CounterRules.bolo_cars(sc.rules.bolo).size() * 7.0 + 9.0 + ceilf(CounterRules.bolo_parts(sc.rules.bolo).size() / 2.0) * 7.0 - 2.0
	check("the stolen list fits its cars and its part serials", lines <= sc._bolo_rect().size.y, "%.0f of %.0f" % [lines, sc._bolo_rect().size.y])
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.2: winter week at the desk

func _winter_desk() -> void:
	# the week picker reaches week 8 (and OVERTIME after it)
	var sc := desk(151)
	sc.fresh = true
	sc.start_day(0)
	sc._tab_step(-1)
	check("free play: the week picker wraps round to OVERTIME, after week 8", sc.overtime and sc.day == CounterRules.OVERTIME_START)
	sc._tab_step(-1)
	check("...and back to week 8", not sc.overtime and sc.day == 49 and CounterRules.week_of(sc.day) == 8)
	done(sc)
	_wipe_overtime()
	# Rob's team van: put its winters on Tuesday and it's fine on Friday; send him away and it isn't
	for way in ["APPROVED", "DENIED"]:
		DeskBook.reset()
		sc = desk(152)
		sc.start_day(50)
		sc.press()
		var rob := booked(sc, "rob")
		check("Rob's team van is in Tuesday's line for its winters, on all-seasons (%s)" % way, rob.request == "WINTER TIRES ON" and rob.sheet.tires == "ALL-SEASON" and rob.reg.use == "COMMERCIAL" and rob.flags.is_empty())
		serve(sc, rob, way)
		sc.start_day(53)
		var fri := booked(sc, "rob")
		if way == "APPROVED": check("winters on Tuesday: Friday's sticker is clean", fri.flags.is_empty() and fri.sheet.tires == "WINTER")
		else: check("sent away Tuesday: Friday he's back on all-seasons for a sticker", fri.flags == ["no_winter_tires"] and String(fri.says).begins_with("YOU WOULDN'T PUT MY WINTERS ON"))
		done(sc)
	# Mrs. Doiron's studs in November: the calendar says they're fine
	DeskBook.reset()
	sc = desk(153)
	sc.start_day(51)
	sc.press()
	var d := booked(sc, "doiron")
	sc.waiting.push_front(d)
	sc.next_customer()
	sc.inspecting = true
	sc.tab = sc._tabs_today().find("SEASONAL")
	var tires: Dictionary = {}
	for f in sc.fields(): if f.key == "measure" and String(f.val.kind) == "tires": tires = f
	sc.pick(tires)
	for f in sc.fields(): if f.key == "rule" and f.val == "studs": sc.pick(f)
	check("studs against the stud rule on Nov 27: in season", sc.verdict.good == true and String(sc.verdict.text).contains("IN SEASON"))
	sc.inspecting = false
	stamp_now(sc, "DENIED")
	check("failing Mrs. Doiron for her studs in November is the wrong call", not sc.result.correct and String(sc.result.line).contains("November"))
	sc.press()
	# Gus's sheet grows to eleven lines, and still sits above the tray
	var full := sc.rules.customer(53, "hot_part")
	full.request = "SAFETY INSPECTION"
	sc.day = 53
	sc.waiting.push_front(full)
	sc.next_customer()
	var sheet: Dictionary = sc.docs[sc._doc_index("sheet")]
	check("Gus's sheet, every line on it, sits on the desk above the tray", sc._rows("sheet").size() >= 11 and float(sheet.pos.y) + sc._doc_size("sheet").y <= CounterScene.DESK.end.y)
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.2: Hachey pulls a box and a regular

func _audit_more() -> void:
	DeskBook.reset()
	var sc := desk(161)
	# last week: a box Leo signed for, and Jayden's tint passed (wrongly)
	sc.start_day(31)
	sc.press()
	var bx := sc.rules.box(31, "clean")
	serve(sc, bx, "APPROVED")
	sc.start_day(30)
	sc.press()
	var j := booked(sc, "jayden")
	serve(sc, j, "APPROVED")
	check("both went in the cabinet, rebuildable", DeskBook.files.size() == 2 and DeskBook.files.all(func(f): return CounterRules.auditable(f, 42)))
	sc.start_day(42)
	sc.press()
	var pulled: Array = []
	for i in 2000:
		sc.tick(0.5)
		if sc.phase == "counter":
			if sc.c.kind == "audit":
				pulled.append(sc.c)
				# stamp it the same way it was stamped
				stamp_now(sc, String(sc.c.audit.stamp))
			else: stamp_now(sc, "DENIED")
		if sc.phase == "result": sc.press()
		if pulled.size() == 2 or sc.phase == "day_end": break
	check("Hachey pulls both: a packing slip and a regular's work order", pulled.size() == 2 and pulled.any(func(x): return x.has("slip")) and pulled.any(func(x): return x.has("licence")))
	var box: Dictionary = {}
	for x in pulled: if x.has("slip"): box = x
	check("the box's file opens at the slip, his thumb on the signature", not box.is_empty() and String(box.says).begins_with("PACKING SLIP"))
	check("the same wrong stamp twice: no citation, and it's on the day-end sheet", sc.day_log.audits_wrong == 1 and sc.day_log.citations.is_empty()
		and sc._day_end_rows().any(func(r): return String(r[0]) == "FILES PULLED" and String(r[1]).contains("1 WRONG TWICE")))
	check("Hachey's report says so", sc.audit_verdict().contains("WRONG BOTH TIMES") and DeskBook.flags.has("desk_audit_wrong_twice"))
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.3: a new list every week, and Hachey reads a file against its own

## Tick the shift on until Inspector Hachey's at the window with a file (stamping anybody else
## DENIED). {} if he never comes.
func until_hachey(sc: CounterScene) -> Dictionary:
	for i in 4000:
		sc.tick(0.5)
		if sc.phase == "counter":
			if sc.c.kind == "audit": return sc.c
			stamp_now(sc, "DENIED")
		if sc.phase == "result": sc.press()
		if sc.phase == "day_end": break
	return {}

func _list_desk() -> void:
	DeskBook.reset()
	var sc := desk(181)
	sc.start_day(31)
	var wk5 := sc.rules.bolo
	sc.start_day(33)
	check("the stolen list is the same all week", sc.rules.bolo == wk5 and sc._list_title().begins_with("POLICE - STOLEN - WEEK OF NOV 4"))
	sc.start_day(36)
	check("...and a new one comes the next week", sc.rules.bolo != wk5 and sc.rules.list_seed == DeskBook.week_list(6))
	# a stolen car in week 5, approved: the file keeps week 5's list
	sc.start_day(31)
	sc.press()
	var w := sc.rules.walk_in(31, "stolen")
	serve(sc, w, "APPROVED")
	var rec: Dictionary = DeskBook.files[DeskBook.files.size() - 1]
	check("a stolen car's file keeps the list it was read against", int(rec.get("list", -1)) == DeskBook.week_list(5) and rec.probs == ["stolen"] and CounterRules.auditable(rec, 42))
	sc.close_up()
	# week 7: a new list on the wall, and Hachey pulls the file
	sc.start_day(42)
	sc.press()
	var a := until_hachey(sc)
	check("Hachey pulls the stolen car's file", not a.is_empty() and int(a.get("audit", {}).get("no", 0)) == int(rec.no))
	if not a.is_empty():
		check("...and reads it against week 5's list, pinned over this week's", sc.bolo_now() == wk5 and sc.rules.bolo != wk5 and sc._list_title() == "STOLEN AS OF NOV 7 - FILE COPY")
		sc.inspecting = true
		sc.pick(field(sc, "reg", "plate"))
		sc.pick(field(sc, "", "bolo"))
		check("the plate on the file against that week's list: stolen", sc.verdict.good == false and String(sc.verdict.text) == "ON THE STOLEN LIST")
		sc.inspecting = false
		stamp_now(sc, "APPROVED")
		check("stamp it the way it was stamped: consistent, and wrong twice", sc.result.correct and sc.result.citation == "" and sc.result.get("wrong_twice", false))
		sc.press()
		check("once he's gone, this week's list is back on the wall", sc.bolo_now() == sc.rules.bolo or sc.c.is_empty() or sc.c.kind != "audit")
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.3: overtime

## A walk-in with nothing wrong, for a right call (and a file Hachey can pull later).
func clean_one(sc: CounterScene) -> Dictionary:
	return sc.rules.walk_in(sc.day, "clean")

func _overtime_desk() -> void:
	# OVERTIME, after week 8 on the picker: Monday, December 2, a fresh book, the till at the start
	_wipe_overtime()
	DeskBook.reset()
	var sc := desk(171)
	sc.fresh = true
	sc.start_day(49)
	sc._tab_step(1)
	check("OVERTIME is after week 8 on the picker: Monday, December 2, a fresh book", sc.overtime and sc.day == CounterRules.OVERTIME_START and sc.phase == "brief"
		and DeskBook.files.is_empty() and sc.cash == CounterRules.START_CASH and int(DeskBook.overtime.get("days", -1)) == 0)
	var brief := " ".join(sc._brief_paras())
	check("the first overtime morning says so, and the December 1 fax is on it", brief.contains("OVERTIME") and brief.contains("FROM DECEMBER 1"), brief.substr(0, 80))
	check("every rule from the eight weeks is in the binder", sc._tabs_today().size() == CounterRules.TABS.size())
	# the streak: right calls build it, a wrong one ends it; the best stays
	sc.press()
	for i in 3: serve(sc, clean_one(sc), "APPROVED")
	check("three right calls: a streak of three, and a new best each time", int(DeskBook.overtime.streak) == 3 and int(DeskBook.overtime.best) == 3 and int(sc.result.best_was) == 2)
	sc.waiting.push_front(sc.rules.customer(sc.day, "vin_mismatch"))
	sc.next_customer()
	stamp_now(sc, "APPROVED")
	check("a wrong call ends it, and says so", int(DeskBook.overtime.streak) == 0 and int(DeskBook.overtime.best) == 3 and int(sc.result.streak_was) == 3)
	sc.press()
	serve(sc, clean_one(sc), "APPROVED")
	check("...and it starts again; the best streak stays", int(DeskBook.overtime.streak) == 1 and int(DeskBook.overtime.best) == 3)
	check("the day-end sheet keeps the record", sc._day_end_rows().any(func(r): return String(r[0]) == "OVERTIME" and String(r[1]).contains("STREAK 1 (BEST 3)")))
	# clock out: the day's kept, and the book saved with tomorrow in it
	sc.close_up()
	sc.end_day()
	check("clock-out: one day kept, Tuesday next, and it's saved", int(DeskBook.overtime.days) == 1 and sc.day == 57 and sc.phase == "brief" and FileAccess.file_exists(TEST_OVERTIME))
	var till := sc.cash
	var filed := DeskBook.files.size()
	done(sc)
	# a new session: OVERTIME picks up where it left off
	DeskBook.reset()
	sc = desk(172)
	sc.fresh = true
	sc.start_day(0)
	sc._tab_step(-1)
	check("pick OVERTIME again: the same day, the same till, the same book and record", sc.overtime and sc.day == 57 and sc.cash == till and DeskBook.files.size() == filed
		and int(DeskBook.overtime.streak) == 1 and int(DeskBook.overtime.best) == 3 and int(DeskBook.overtime.days) == 1 and DeskBook.files[0].seed is int and DeskBook.overtime.days is int)
	check("the brief keeps the record too", " ".join(sc._brief_paras()) != "" and sc._record_line() == "DAYS KEPT 1.  STREAK 1.  BEST STREAK 3.")
	# Friday's bills, then Monday: in overtime the month doesn't end
	sc.start_day(60)
	sc.press()
	sc.close_up()
	sc.end_day()
	check("Friday in overtime: the bills", sc.phase == "week_end" and sc.bills_paid.size() == CounterRules.BILLS.size())
	sc._after_week()
	check("...then Monday, December 9: no end of the month in overtime", sc.phase == "brief" and sc.day == 63 and " ".join(sc._brief_paras()).contains("NEW STOLEN LIST"))
	# Christmas week: shut Wednesday and Thursday, the bills Friday
	sc.start_day(78)
	sc.close_up()
	sc.end_day()
	check("Christmas Eve's clock-out opens Friday the 27th", sc.day == 81 and sc.phase == "brief" and " ".join(sc._brief_paras()).contains("SHUT FOR CHRISTMAS AND BOXING DAY"))
	# spring: studs out of season at the desk
	var may := CounterRules.days_between(CounterRules.WEEK_START, [2020, 5, 5])
	sc.start_day(may)
	sc.press()
	var st := sc.rules.customer(may, "studs_out_of_season")
	sc.waiting.push_front(st)
	sc.next_customer()
	sc.inspecting = true
	sc.tab = sc._tabs_today().find("SEASONAL")
	var tires: Dictionary = {}
	for f in sc.fields(): if f.key == "measure" and String(f.val.kind) == "tires": tires = f
	sc.pick(tires)
	for f in sc.fields(): if f.key == "rule" and f.val == "studs": sc.pick(f)
	check("May 5: studs against the stud rule, out of season", sc.verdict.good == false and String(sc.verdict.text).contains("OUT OF SEASON") and sc.ask_list()[0] == "studs_out_of_season")
	sc.inspecting = false
	stamp_now(sc, "DENIED")
	check("failing studs in May is the right call", sc.result.correct)
	sc.press()
	# Hachey still drops in now and then, and pulls one of the overtime files
	var hd := may
	while CounterRules.audit_times(hd).is_empty(): hd = CounterRules.next_open(hd)
	sc.start_day(hd)
	check("Hachey's sedan is in the lot on the morning he's coming", " ".join(sc._brief_paras()).contains("HACHEY") and sc.arrivals.filter(func(x): return x.c.kind == "audit").size() == 1)
	sc.press()
	var a := until_hachey(sc)
	check("...and pulls an older file", not a.is_empty() and int(a.audit.day) < hd)
	done(sc)
	# the end of the run: KEEP WORKING carries this run's book into overtime
	_wipe_overtime()
	DeskBook.reset()
	sc = desk(173)
	sc.start_day(CounterRules.LAST_DAY)
	sc.press()
	serve(sc, sc.rules.walk_in(CounterRules.LAST_DAY, "tint"), "DENIED")
	sc.close_up()
	sc.end_day()
	sc._after_week()
	check("the run still ends on November 29", sc.phase == "month_end")
	var left := sc.cash
	sc._tab_step(1)
	check("KEEP WORKING: overtime on Monday, December 2, with the run's files and till", sc.overtime and sc.day == CounterRules.OVERTIME_START and sc.phase == "brief" and DeskBook.files.size() == 1 and sc.cash == left)
	# losing the licence ends an overtime: the next one starts over, and the best streak stays
	DeskBook.overtime.best = 9
	DeskBook.citations = CounterRules.REVOKE_AT
	sc.start_day(60)
	sc.close_up()
	sc.end_day()
	sc._after_week()
	check("twelve citations and overtime's over too", sc.phase == "revoked" and bool(DeskBook.overtime_on_file().get("ended", false)))
	done(sc)
	DeskBook.reset()
	sc = desk(174)
	sc.fresh = true
	sc.start_day(49)
	sc._tab_step(1)
	check("the next OVERTIME starts over from December 2, the best streak still on the books", sc.day == CounterRules.OVERTIME_START and DeskBook.files.is_empty()
		and DeskBook.citations == 0 and int(DeskBook.overtime.days) == 0 and int(DeskBook.overtime.best) == 9)
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.4: Gus's tool drawer

func _drawer_desk() -> void:
	DeskBook.reset()
	var sc := desk(191)
	sc.start_day(0)
	sc.press()
	sc.close_up()
	check("Gus's drawer is under the first day-end sheet: the tread gauge and the date wheel tonight",
		sc.phase == "day_end" and sc.drawer_tools().map(func(t): return String(t.id)) == ["gauge", "wheel"])
	sc._tab_step(1)
	check("LB/RB pull it open, at the first tool", sc.phase == "drawer" and sc.drawer_sel == 0)
	sc.cash = 300
	sc.cur = sc._drawer_rect(0).get_center()
	sc.press()
	check("short of the price: nothing bought, and Gus says by how much", DeskBook.tools.is_empty() and sc.cash == 300 and sc.drawer_line.contains("$450 SHORT"), sc.drawer_line)
	sc.cash = 2000
	sc.heard = []
	sc.press()
	check("buy the tread gauge: off the till, into the drawer, the till rings and Gus has a word",
		DeskBook.tools == ["gauge"] and sc.cash == 1250 and sc.drawer_line == String(DeskTools.tool("gauge").gus) and sc.heard.has("till"))
	sc.press()
	check("...and only the once", DeskBook.tools == ["gauge"] and sc.cash == 1250 and sc.drawer_line.contains("YOU'VE GOT ONE"))
	sc._tab_step(1)
	check("LB/RB move along the drawer, the cursor with them", sc.drawer_sel == 1 and sc._drawer_row_at(sc.cur) == 1)
	sc.press()
	check("buy the date wheel too", DeskBook.tools == ["gauge", "wheel"] and sc.cash == 350)
	check("the loupe isn't in the drawer before there's a stolen list", not sc.buy_tool("loupe") and DeskBook.tools.size() == 2)
	sc._cancel()
	check("B shuts the drawer: back to the sheet", sc.phase == "day_end")
	sc.cur = CounterScene.DRAWER_HANDLE.get_center()
	sc.press()
	check("...and a click on its handle opens it again", sc.phase == "drawer")
	sc.cur = sc._drawer_shut_rect().get_center()
	sc.press()
	sc.cur = Vector2(320, 200)
	sc.press()
	check("shut it and go home: Tuesday morning, the tools still in the drawer", sc.phase == "brief" and sc.day == 1 and DeskBook.tools == ["gauge", "wheel"])
	# the drawer's front is where the stamps sit by day: a click straight through from the last
	# stamp goes home; move off it and back, and a click opens it
	sc.press()
	sc.cur = sc._button_rect(2).get_center()
	sc.close_up()
	sc.press()
	check("a click straight through from the stamps goes home, not into the drawer", sc.phase == "brief" and sc.day == 2)
	sc.press()
	sc.cur = sc._button_rect(2).get_center()
	sc.close_up()
	sc.cur = Vector2(320, 200)
	sc._drawer_hover()
	sc.cur = sc._button_rect(2).get_center()
	sc.press()
	check("...but off it and back on, a click on its front opens it", sc.phase == "drawer")
	done(sc)
	# in the story a tool comes out of Leo's own money (the shop's till there is only the day's)
	DeskBook.reset()
	var keep_cash := StoryState.cash
	sc = desk(192)
	sc.story = { "type": "counter", "day": 10 }
	sc.start_day(10)
	sc.press()
	sc.close_up()
	StoryState.cash = 1000
	var till := sc.cash
	sc._tab_step(1)
	var ok := sc.buy_tool("lamp") == false and sc.buy_tool("wheel")
	check("in the story a tool's paid out of Leo's own money, not the day's till", ok and StoryState.cash == 100 and sc.cash == till and sc.purse_label() == "YOUR OWN MONEY")
	StoryState.cash = keep_cash
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.4: the tools at the desk

func _tools_desk() -> void:
	DeskBook.reset()
	var sc := desk(201)
	sc.start_day(15)
	sc.press()
	# an expired registration, and a temporary permit in the pocket that somebody made up
	var c: Dictionary = {}
	for i in 60:
		c = sc.rules.customer(15, "clean", { "plain": true })
		sc.rules.excuse(c, 15, "expired_reg")
		sc.rules._proof(c, "expired_reg", 15, "bad")
		if DeskTools.forged(c, "permit"): break
	sc.waiting.push_front(c)
	sc.next_customer()
	sc.inspecting = true
	var lapse := field(sc, "reg", "expiry")
	sc.pick(lapse)
	sc.pick(lapse)
	check("no tools: the same thing twice just puts it back down", sc.pick_a.is_empty() and sc.verdict.is_empty())
	check("...and a seal's nothing to pick", not sc.fields().any(func(f): return f.key == "seal"))
	DeskBook.tools = ["gauge", "wheel", "loupe", "lamp"]
	sc.pick(lapse)
	check("with a tool that reads it, the inspect hint offers it", DeskTools.tool_for(sc.pick_a, DeskBook.tools) == "wheel")
	sc.pick(lapse)
	check("the date wheel: the registration twice, it's expired, and that's the question", sc.verdict.good == false and String(sc.verdict.text).begins_with("EXPIRED")
		and sc.verdict.get("tool", "") == "DATE WHEEL" and sc.ask_list()[0] == "expired_reg")
	sc.ask("expired_reg")
	var seal := field(sc, "permit", "seal")
	check("out comes the permit; with the UV lamp its seal is a thing to pick", not seal.is_empty())
	sc.pick(seal)
	sc.pick(seal)
	check("the UV lamp on a made-up permit: no glow", sc.verdict.good == false and String(sc.verdict.text).contains("FAKE") and sc.lit.get("permit", true) == false)
	sc.inspecting = false
	stamp_now(sc, "DENIED")
	check("...and turning it away is still Leo's call to make (the right one)", sc.result.correct)
	sc.press()
	# the gauge on the tread, the loupe on the plate
	var bald := sc.rules.customer(15, "fails_inspection")
	while int(Array(bald.sheet.tread).filter(func(x): return x < 1.6).size()) == 0: bald = sc.rules.customer(15, "fails_inspection")
	sc.waiting.push_front(bald)
	sc.next_customer()
	check("a new customer: nothing lit", sc.lit.is_empty())
	sc.inspecting = true
	var tread: Dictionary = {}
	for f in sc.fields(): if f.key == "measure" and String(f.val.kind) == "tread": tread = f
	sc.pick(tread)
	sc.pick(tread)
	check("the tread gauge: the tread twice, it fails, no binder", sc.verdict.good == false and sc.verdict.get("tool", "") == "TREAD GAUGE" and sc.ask_list()[0] == "fails_inspection")
	var plate := field(sc, "car", "plate")
	sc.pick(plate)
	sc.pick(plate)
	check("the loupe: the plate on the car twice, read against the stolen list", sc.verdict.get("tool", "") == "LOUPE" and sc.verdict.good == true)
	sc.pick(plate)
	sc.pick(field(sc, "reg", "plate"))
	check("...and a tool doesn't get in the way of putting two things side by side", sc.verdict.text == "MATCH" and not sc.verdict.has("tool"))
	sc.inspecting = false
	stamp_now(sc, "APPROVED")
	check("the tools never stamp: a bald tire approved is still a citation", not sc.result.correct and sc.result.citation != "")
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.4: the relaxed clock

func _relaxed_desk() -> void:
	DeskBook.reset()
	var sc := desk(211)
	sc.fresh = true
	sc.start_day(0)
	check("the wall clock starts at its usual pace: ten minutes a day", not DeskBook.relaxed and sc.relax_line().contains("OFF (10 MIN A DAY)"))
	sc.toggle_relaxed()
	check("{R} on the brief puts it on the relaxed clock: fifteen minutes a day", DeskBook.relaxed and sc.relax_line().contains("ON (15 MIN A DAY)"))
	sc._tab_step(1)
	check("...and it stays that way along the week picker", DeskBook.relaxed and sc.day == 8)
	sc.press()
	sc.toggle_relaxed()
	check("...and only flips on the brief", DeskBook.relaxed)
	done(sc)
	# the same day both ways: the same line and the same calls; only the real time is longer
	var runs: Array = []
	for relaxed in [false, true]:
		DeskBook.reset()
		DeskBook.book_seed = 5
		DeskBook.relaxed = relaxed
		var s2 := desk(212)
		s2.start_day(10)
		var line: Array = s2.arrivals.map(func(x): return "%s %s %.1f" % [x.c.kind, str(x.c.get("seed", "")), x.t])
		var calls: Array = []
		var secs := 0.0
		var hold := 0.0
		s2.press()
		for i in 6000:
			var was := s2.clock
			s2.tick(0.5)
			secs += 0.5
			if s2.phase == "counter":
				hold += s2.clock - was
				# (a slow clerk: seventy minutes on the clock with each one, and whoever's at the window at six)
				if hold >= 70.0 or s2.clock >= CounterRules.SHIFT_LEN:
					stamp_now(s2, "APPROVED" if CounterRules.find_problems(s2.c, 10, s2.bolo_now()).is_empty() else "DENIED")
					calls.append("%s %s %s %d" % [s2.c.kind, s2.stamped, s2.result.correct, int(s2.result.money)])
					hold = 0.0
			if s2.phase == "result": s2.press()
			if s2.phase == "day_end": break
		runs.append({ "line": line, "calls": calls, "secs": secs, "walked": int(s2.day_log.walked), "end": s2.phase })
		done(s2)
	check("relaxed or not: the same line, the same calls, the same people left at six", runs[0].end == "day_end" and runs[1].end == "day_end" and runs[0].line == runs[1].line
		and runs[0].calls == runs[1].calls and runs[0].walked == runs[1].walked and runs[0].walked > 0, "%d / %d calls, %d / %d walked, %s" % [runs[0].calls.size(), runs[1].calls.size(), runs[0].walked, runs[1].walked,
		"same line" if runs[0].line == runs[1].line else "%s vs %s" % [runs[0].line.slice(0, 3), runs[1].line.slice(0, 3)]])
	check("...and the day takes half as long again in real time", absf(runs[1].secs / runs[0].secs - CounterScene.RELAXED_STRETCH) < 0.1, "%.0f s / %.0f s" % [runs[0].secs, runs[1].secs])
	# somebody at the window: the horn still waits ninety minutes on the clock, which is longer in real time
	DeskBook.reset()
	DeskBook.relaxed = true
	sc = desk(213)
	sc.start_day(10)
	sc.press()
	sc.waiting.push_front(sc.rules.customer(10, "clean"))
	sc.next_customer()
	sc.waiting.append(sc.rules.customer(10, "clean"))
	var real := 0.0
	while sc.honk_t <= 0.0 and real < 400.0:
		sc.tick(0.25)
		real += 0.25
	check("relaxed: the next one honks after ninety minutes on the clock, two and a quarter real minutes", absf(sc.clock - CounterRules.HONK_AFTER) < 1.0 and absf(real - 135.0) < 1.0, "%.1f s, %.1f min" % [real, sc.clock])
	done(sc)
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.4: the drawer and the clock are kept

func _saved_desk() -> void:
	# through JSON, in the story's save, in overtime's file
	DeskBook.reset()
	DeskBook.tools = ["gauge", "lamp"]
	DeskBook.relaxed = true
	var d: Variant = JSON.parse_string(JSON.stringify(DeskBook.to_dict()))
	DeskBook.reset()
	DeskBook.from_dict(d as Dictionary)
	check("the tools and the relaxed clock survive the save, through JSON", DeskBook.tools == ["gauge", "lamp"] and DeskBook.relaxed)
	var was := StoryState.active
	StoryState.active = true
	StoryState.flags = {}
	DeskBook.close_book()
	DeskBook.reset()
	DeskBook.open_book()
	check("...and ride along in the story's save", DeskBook.tools == ["gauge", "lamp"] and DeskBook.relaxed)
	StoryState.active = was
	StoryState.flags = {}
	# overtime: a tool bought at the day's end and the clock are in the file at clock-out
	_wipe_overtime()
	DeskBook.reset()
	var sc := desk(221)
	sc.fresh = true
	sc.start_day(49)
	sc.toggle_relaxed()
	sc._tab_step(1)
	check("a new overtime keeps the clock picked on the brief", sc.overtime and DeskBook.relaxed and DeskBook.tools.is_empty())
	sc.press()
	sc.close_up()
	sc.cash = 5000
	sc._tab_step(1)
	var bought := sc.buy_tool("loupe")
	sc._cancel()
	sc.end_day()
	check("buy the loupe in overtime and clock out: saved", bought and FileAccess.file_exists(TEST_OVERTIME))
	done(sc)
	DeskBook.reset()
	sc = desk(222)
	sc.fresh = true
	sc.start_day(0)
	check("a new session: the normal clock and an empty drawer", not DeskBook.relaxed and DeskBook.tools.is_empty())
	sc._tab_step(-1)
	check("pick OVERTIME: the loupe and the relaxed clock are back with its book", sc.overtime and DeskBook.tools == ["loupe"] and DeskBook.relaxed and sc.cash == 5000 - 1150)
	sc._tab_step(1)
	check("back to week 1: a fresh book with nothing in the drawer, on the clock the picker shows", not sc.overtime and DeskBook.tools.is_empty() and DeskBook.relaxed)
	done(sc)
	_wipe_overtime()
	DeskBook.reset()

# ------------------------------------------------------------------ Desk 2.4: faces that age

func _ages_desk() -> void:
	DeskBook.reset()
	var sc := desk(231)
	sc.start_day(1)
	sc.press()
	sc.waiting.push_front(booked(sc, "jayden"))
	sc.next_customer()
	var then := sc.face_age()
	var later := CounterRules.days_between(CounterRules.WEEK_START, [2021, 5, 4])
	sc.start_day(later)
	sc.press()
	sc.waiting.push_front(sc.rules.scripted(DeskRegulars.spec("jayden", DeskRegulars.OT + 1, "?", later), later))
	sc.next_customer()
	check("faces age with the calendar: Jayden's 19 in the run, 21 at the window in May 2021", then == 19 and sc.face_age() == 21, "%d / %d" % [then, sc.face_age()])
	sc.waiting.push_front(CounterRules.audit_customer({ "no": 9, "day": later - 1, "stamp": "APPROVED", "correct": true, "kind": "regular", "seed": 77, "id": "" }))
	sc.next_customer()
	check("...and Hachey, at the window with a file, is as old as he is that day", sc.c.kind == "audit" and sc.window_age() == CounterRules.age_on(CounterRules.HACHEY.dob, later) and sc.window_age() == 64)
	done(sc)
	DeskBook.reset()
