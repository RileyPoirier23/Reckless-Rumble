## Headless tests for the desk itself (the scene, not just the rules): the shift clock and the
## line, warnings, ASK, the notebook and the sticker log, the binder, the controls.
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

func _init() -> void:
	CounterScene.setup_actions()
	DeskBook.reset()
	_controls()
	_shift()
	_warnings()
	_ask()
	_books()
	_days()
	_fixes()
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
	# a mask, and a sting who doesn't know which Tim's
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
