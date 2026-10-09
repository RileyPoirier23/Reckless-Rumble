## Headless tests for the counter: godot --headless --path game -s tests/counter_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

## Every day the shop is open in the first four weeks.
func open_days() -> Array:
	var out: Array = []
	for d in CounterRules.LAST_DAY + 1:
		if CounterRules.is_open(d): out.append(d)
	return out

func _init() -> void:
	# 1. every injected problem can be found again from the papers alone, and nothing else is wrong
	var bad := 0
	var total := 0
	var example := ""
	for day in open_days():
		for prob in CounterRules.PROBLEM_RULE:
			if not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			for seed in (40 if day < 5 else 16):
				var r := CounterRules.new(seed * 31 + day)
				r.make_bolo()
				var c := r.customer(day, prob)
				var found := CounterRules.find_problems(c, day, r.bolo)
				total += 1
				if found != [prob]:
					bad += 1
					if example == "": example = "day %d %s -> %s" % [day, prob, found]
	check("every injected problem is findable, and alone", bad == 0, "%d/%d wrong %s" % [bad, total, example])
	# 2. random line-ups: what's injected is exactly what's findable
	bad = 0
	total = 0
	for day in open_days():
		for seed in (30 if day < 5 else 8):
			var r := CounterRules.new(seed + 1000 * day)
			r.make_bolo()
			for c in r.day_line(day):
				total += 1
				if CounterRules.find_problems(c, day, r.bolo) != c.flags:
					bad += 1
					if example == "": example = "%s vs %s" % [CounterRules.find_problems(c, day, r.bolo), c.flags]
	check("line-ups: flags == what the papers show", bad == 0, "%d/%d wrong %s" % [bad, total, example])
	# 3. problems only appear once their rule is on the bulletin
	var r0 := CounterRules.new(7)
	r0.make_bolo()
	var early := 0
	for i in 300:
		var c := r0.customer(0)
		for f in c.flags:
			if not CounterRules.rule_active(CounterRules.PROBLEM_RULE[f], 0): early += 1
	check("Monday only has Monday's problems", early == 0, "%d early" % early)
	# 4. judging: clean + APPROVED pays; problem + APPROVED is a citation; stolen wants REPORT
	var r := CounterRules.new(3)
	r.make_bolo()
	var clean := r.customer(4, "")
	while not clean.flags.is_empty(): clean = r.customer(4, "")
	var j := CounterRules.judge(clean, "APPROVED", 4, r.bolo)
	check("clean car, approved: paid, no citation", j.money > 0 and j.citation == "" and j.correct)
	j = CounterRules.judge(clean, "DENIED", 4, r.bolo)
	check("clean car, denied: wrong call, bad review", not j.correct and j.review < 0)
	var bent := r.customer(4, "vin_mismatch")
	j = CounterRules.judge(bent, "APPROVED", 4, r.bolo)
	check("VIN mismatch, approved: citation", not j.correct and j.citation.contains("VIN"))
	j = CounterRules.judge(bent, "DENIED", 4, r.bolo)
	check("VIN mismatch, denied: right call", j.correct and j.citation == "")
	var hot := r.customer(4, "stolen")
	check("stolen car, reported: right call", CounterRules.judge(hot, "REPORT", 4, r.bolo).correct)
	check("stolen car, approved: citation and heat", CounterRules.judge(hot, "APPROVED", 4, r.bolo).heat > 0)
	# 5. the Familia and the sting
	var fam := r.familia(3)
	check("Familia car has a real problem on it", not CounterRules.find_problems(fam, 3, r.bolo).is_empty())
	check("Familia: the wrench pays dirty cash and trust", CounterRules.judge(fam, "WRENCH", 3, r.bolo).dirty > 0)
	check("Familia: reporting them costs a lot of trust", CounterRules.judge(fam, "REPORT", 3, r.bolo).trust <= -50)
	var st := r.sting(4)
	check("sting: the wrench gets you busted", CounterRules.judge(st, "WRENCH", 4, r.bolo).heat >= 50)
	check("sting: denying it is safe", CounterRules.judge(st, "DENIED", 4, r.bolo).heat == 0)
	# 6. line-up shape
	var r2 := CounterRules.new(9)
	r2.make_bolo()
	var thu := r2.day_line(3)
	var fri := r2.day_line(4)
	check("Thursday has a Familia car", thu.any(func(c): return c.kind == "familia"))
	check("Friday has the sting", fri.any(func(c): return c.kind == "sting"))
	# 7. the INSPECT tool can prove every problem (no insurance is proven by the missing card),
	#    and never shows red on a clean customer
	var unprovable := 0
	var false_red := 0
	var tried := 0
	var note := ""
	#    (all of it as the desk draws it: every paper, every tab of the binder, after asking
	#    every question there is, so the pockets and the masks are empty)
	for day in open_days():
		for prob in CounterRules.PROBLEM_RULE.keys() + [""]:
			if prob != "" and not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			for seed in (8 if day < 5 else (2 if day < 26 else 1)):
				var rr := CounterRules.new(seed * 7 + day * 101)
				rr.make_bolo()
				var cust := rr.customer(day, prob) if prob != "" else rr.customer(day, "")
				if prob == "" and not CounterRules.find_problems(cust, day, rr.bolo).is_empty(): continue
				var sc := CounterScene.new()
				sc.rules = rr
				sc.car_view = CarView.new()
				sc.day = day
				sc.waiting = [cust]
				sc.next_customer()
				for t in CounterRules.TOPIC_LABEL: sc.ask(t)
				var fs: Array = []
				for ti in sc._tabs_today().size():
					sc.tab = ti
					for f in sc.fields(): if ti == 0 or f.key == "rule": fs.append(f)
				var reds: Array = []
				for a in fs.size():
					for b in range(a + 1, fs.size()):
						var v := sc.compare(fs[a], fs[b])
						if v[1] == false: reds.append(v[2])
				tried += 1
				if prob != "" and not reds.has(prob) and not (prob == "no_insurance" and CounterRules.standing_topics(cust, day).has(prob)):
					unprovable += 1
					if note == "": note = "day %d %s -> %s" % [day, prob, reds]
				if prob == "":
					var base := String(cust.exception.get("problem", "-"))
					for x in reds:
						if x != base:
							false_red += 1
							if note == "": note = "day %d clean -> %s" % [day, reds]
				sc.car_view.free()
				sc.free()
	check("inspect proves every problem, from the desk as drawn", unprovable == 0, "%d/%d unprovable %s" % [unprovable, tried, note])
	check("inspect shows no red on clean customers (but the discrepancy a proof covers)", false_red == 0, "%d %s" % [false_red, note])
	_desk()
	_late_weeks()
	_courier()
	_audit()
	_regulars()
	_returns()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

# ------------------------------------------------------------------ Desk 2.0

## A clean customer with nothing random about them.
func _plain(r: CounterRules, day: int) -> Dictionary:
	return r.customer(day, "clean", { "plain": true })

## Every red verdict Leo can reach from the desk: [{text, topic}] over every pair of facts.
func _reds(c: Dictionary, day: int, bolo: Array, pockets := true) -> Array:
	var fs := CounterRules.desk_facts(c, day, pockets)
	var out: Array = []
	for a in fs.size():
		for b in range(a + 1, fs.size()):
			var v := CounterRules.compare(c, day, bolo, fs[a], fs[b])
			if v[1] == false: out.append({ "text": v[0], "topic": v[2] })
	return out

func _desk() -> void:
	# 8. an exception is valid only when its proof passes, and spoiling the proof spoils it
	var wrong := 0
	var tried := 0
	var note := ""
	for day in open_days():
		for base in CounterRules.PROOFS:
			for seed in 6:
				var r := CounterRules.new(seed * 13 + day * 7 + String(base).length())
				r.make_bolo()
				var c := _plain(r, day)
				if not r.excuse(c, day, base): continue
				tried += 1
				var ok: bool = c.exception.valid and CounterRules.proof_ok(c, base, day) and CounterRules.find_problems(c, day, r.bolo).is_empty()
				# now spoil the proof: a VIN off by one, or (a bill of sale) the wrong seller
				var doc: String = c.exception.doc
				if doc == "bos": c.bos.seller = r.other_name(String(c.bos.seller))
				else: c[doc].vin = r.vin_tweak(String(c[doc].vin))
				ok = ok and not CounterRules.proof_ok(c, base, day) and not CounterRules.find_problems(c, day, r.bolo).is_empty()
				if not ok:
					wrong += 1
					if note == "": note = "day %d %s" % [day, base]
	check("an exception holds only while its proof checks out", wrong == 0 and tried > 100, "%d/%d wrong %s" % [wrong, tried, note])
	# ...and every exception the generator rolls says honestly whether its proof passes
	wrong = 0
	tried = 0
	for day in open_days():
		var r := CounterRules.new(day * 31 + 5)
		r.make_bolo()
		for i in 120:
			var c := r.customer(day)
			if c.exception.is_empty(): continue
			tried += 1
			if bool(c.exception.valid) != CounterRules.proof_ok(c, String(c.exception.problem), day): wrong += 1
	check("rolled exceptions: valid == the proof passes", wrong == 0 and tried > 50, "%d/%d" % [wrong, tried])
	# 9. every problem is findable from the desk: a red comparison under its own ASK topic
	#    (no insurance is a question you can always ask), once the pockets are emptied
	var missing := 0
	tried = 0
	note = ""
	for day in open_days():
		for prob in CounterRules.PROBLEM_RULE:
			if not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			for seed in (5 if day < 26 else 3):
				var r := CounterRules.new(seed * 101 + day)
				r.make_bolo()
				var c := r.customer(day, prob)
				c.mask = ""
				tried += 1
				var topics := _reds(c, day, r.bolo).map(func(x): return x.topic)
				var ok: bool = topics.has(prob) or (prob == "no_insurance" and CounterRules.standing_topics(c, day).has(prob))
				if not ok:
					missing += 1
					if note == "": note = "day %d %s -> %s" % [day, prob, topics]
	check("every problem type is findable from the desk, under its own name", missing == 0, "%d/%d %s" % [missing, tried, note])
	# 10. clean customers show no red; covered ones only show the red their proof explains,
	#     and that red is there before you ASK (so there's a reason to)
	var false_red := 0
	var stray := 0
	var no_reason := 0
	note = ""
	for day in open_days():
		var r := CounterRules.new(day * 17 + 3)
		r.make_bolo()
		for i in 40:
			var c := r.customer(day)
			if not CounterRules.find_problems(c, day, r.bolo).is_empty(): continue
			c.mask = ""
			var reds := _reds(c, day, r.bolo)
			if c.exception.is_empty():
				if not reds.is_empty():
					false_red += 1
					if note == "": note = "day %d %s" % [day, reds[0]]
				continue
			var base: String = c.exception.problem
			for x in reds:
				if x.topic != base:
					stray += 1
					if note == "": note = "day %d %s: %s" % [day, base, x]
			var before := _reds(c, day, r.bolo, false).map(func(x): return x.topic)
			if not before.has(base) and not CounterRules.standing_topics(c, day).has(base): no_reason += 1
	check("clean customers never show red", false_red == 0, "%d %s" % [false_red, note])
	check("a covered discrepancy is the only red, and it shows before you ASK", stray == 0 and no_reason == 0, "%d stray, %d hidden %s" % [stray, no_reason, note])
	# 11. ASK: the proof comes out of the pocket; the mask comes off; stings stumble on small talk
	var r := CounterRules.new(77)
	r.make_bolo()
	var cb := _plain(r, 12)
	r.excuse(cb, 12, "name_mismatch")
	var ans := CounterRules.answer(cb, "name_mismatch")
	check("ASK about the name: out comes the bill of sale", String(ans.get("doc", "")) == "bos" and cb.hidden.has("bos"))
	var cm := _plain(r, 24)
	cm.mask = "GOALIE"
	check("ASK about the mask: it comes off", CounterRules.answer(cm, "mask").get("unmask", false))
	check("small talk is always on the list", CounterRules.standing_topics(_plain(r, 3), 3).has("local"))
	check("the sting doesn't know which Tim's", CounterRules.STING_ASK.has(String(CounterRules.answer(r.sting(4), "local").line)))
	# 12. two free warnings a shift, then fines; police matters are never free
	var bent := r.customer(9, "vin_mismatch")
	var j := CounterRules.judge(bent, "APPROVED", 9, r.bolo)
	var p0 := CounterRules.penalty(bent, j, 0)
	var p1 := CounterRules.penalty(bent, j, 1)
	var p2 := CounterRules.penalty(bent, j, 2)
	check("the first two citations are warnings", p0.warning and p1.warning and p0.fine == 0 and p1.fine == 0)
	check("the third one costs $%d" % CounterRules.FINE, not p2.warning and p2.fine == CounterRules.FINE)
	var hot := r.customer(9, "stolen")
	check("a stolen car is never a free warning", not CounterRules.penalty(hot, CounterRules.judge(hot, "APPROVED", 9, r.bolo), 0).warning)
	var st := r.sting(4)
	check("the sting costs $2,000", CounterRules.penalty(st, CounterRules.judge(st, "WRENCH", 4, r.bolo), 0).fine == 2000)
	# 13. the calendar, the binder and the rules by week
	check("Thanksgiving and weekends are closed", not CounterRules.is_open(7) and not CounterRules.is_open(5) and CounterRules.is_open(8))
	check("the bulletin becomes a binder in week two", not CounterRules.binder(4) and CounterRules.binder(8))
	var tabs_ok := true
	for rule in CounterRules.RULES: if not CounterRules.TABS.has(rule.tab): tabs_ok = false
	check("every rule has a binder tab", tabs_ok)
	for id in ["odo", "bos", "door", "oop", "salvage"]:
		check("rule %s arrives in weeks 2 to 4" % id, CounterRules.rule_active(id, CounterRules.LAST_DAY) and not CounterRules.rule_active(id, 4))
	# 14. the shift: arrivals in order, inside opening hours, a full day's worth
	var sh := r.shift(10)
	var in_order := true
	for i in range(1, sh.size()): if sh[i].t < sh[i - 1].t: in_order = false
	check("the shift's arrivals come in order, before closing", in_order and sh[sh.size() - 1].t < CounterRules.SHIFT_LEN)
	check("a shift brings more customers than a careful player can serve", sh.size() >= 8, "%d" % sh.size())
	check("the shift clock reads like a wall clock", CounterRules.clock_str(0) == "8:00 A.M." and CounterRules.clock_str(600) == "6:00 P.M.")
	# 15. scripted customers from data/story_customers.json
	var sd := CounterRules.story_data()
	check("story_customers.json loads", not sd.is_empty())
	for id in ["dale_hatch", "darrell_trade"]:
		check("%s is in the file" % id, not CounterRules.story_spec(id).is_empty())
	var ids_ok := true
	var cat := CounterRules.catalogue()
	for id in (sd.get("customers", {}) as Dictionary):
		var spec := CounterRules.story_spec(id)
		var cid := String((spec.get("car", {}) as Dictionary).get("catalogue", ""))
		if cat != null and cid != "" and (cat.call("entry", cid) as Dictionary).is_empty(): ids_ok = false
	for ch in (sd.get("schedule", {}) as Dictionary):
		for d in (sd.schedule[ch] as Dictionary):
			for id in sd.schedule[ch][d]: if CounterRules.story_spec(id).is_empty(): ids_ok = false
	check("every scheduled customer and catalogue car exists", ids_ok)
	var dar := r.shift(16).filter(func(x): return String(x.c.get("script", {}).get("id", "")) == "darrell_trade")
	check("Darrell comes in on the Wednesday of week three", dar.size() == 1)
	if dar.size() == 1:
		var dc: Dictionary = dar[0].c
		check("Darrell's odometer is rolled back, and you can prove it", CounterRules.find_problems(dc, 16, r.bolo).has("odo_rollback") and _reds(dc, 16, r.bolo).any(func(x): return x.topic == "odo_rollback"))
		check("his papers are the same every time", CounterRules.new(1).scripted(CounterRules.story_spec("darrell_trade"), 16).car.vin == dc.car.vin)
		var jd := CounterRules.judge(dc, "DENIED", 16, r.bolo)
		check("a scripted stamp sets the story's flags", jd.flags.has("desk_darrell_trade_denied"))
	var hat := r.shift(9).filter(func(x): return String(x.c.get("script", {}).get("id", "")) == "dale_hatch")
	check("Dale Hatch comes in the Wednesday after Thanksgiving, papers perfect", hat.size() == 1 and CounterRules.find_problems(hat[0].c, 9, r.bolo).is_empty())
	var thu := r.shift(10)
	check("a scripted Familia car takes Thursday's napkin", thu.filter(func(x): return x.c.kind == "familia").size() == 1)
	# 16. fix 16: no real names in the short list
	var real := false
	for cm2 in CounterRules.CARS:
		var words := ("%s %s" % [cm2.make, cm2.model]).split(" ")
		for w in ["KIA", "GOLF", "CARAVAN"]: if words.has(w): real = true
	check("the short list uses parody names only", not real)

# ------------------------------------------------------------------ Desk 2.1: weeks 5 to 7

## Every red Leo can reach from a pulled file: its own day, its own papers, no face, no car.
func _file_reds(a: Dictionary) -> Array:
	return _reds(a, int(a.audit.day), []).map(func(x): return x.topic)

func _late_weeks() -> void:
	# 17. the calendar: seven weeks, Remembrance Day shut, the audit week at the end
	check("Remembrance Day is closed", not CounterRules.is_open(35) and String(CounterRules.CLOSED.get(35, "")) == "REMEMBRANCE DAY")
	check("the run ends on Friday, November 22", CounterRules.date_str(CounterRules.today(CounterRules.LAST_DAY)) == "NOV 22 2019" and CounterRules.day_name(CounterRules.LAST_DAY) == "FRIDAY")
	for id in ["tint", "courier", "noise", "audit"]:
		check("rule %s arrives in weeks 5 to 7" % id, CounterRules.rule_active(id, CounterRules.LAST_DAY) and not CounterRules.rule_active(id, 25))
	var tabs_ok := true
	for rule in CounterRules.RULES: if not CounterRules.TABS.has(rule.tab): tabs_ok = false
	for p in CounterRules.PROBLEM_RULE: if not CounterRules.RULES.any(func(x): return x.id == CounterRules.PROBLEM_RULE[p]): tabs_ok = false
	check("every new problem has a rule, and every rule a tab", tabs_ok)
	# 18. tint: 70% of the light passes, 65% doesn't; inspections only; the exemption is one driver's, one car's
	var r := CounterRules.new(5)
	r.make_bolo()
	var c := _plain(r, 30)
	c.request = "SAFETY INSPECTION"
	c.sheet.tint = 70
	check("tint: 70% of the light passes", CounterRules.find_problems(c, 30, r.bolo).is_empty())
	c.sheet.tint = 65
	check("tint: 65% fails", CounterRules.find_problems(c, 30, r.bolo) == ["tint"])
	check("tint: nobody minded before the rule", CounterRules.find_problems(c, 27, r.bolo).is_empty())
	c.request = "OIL CHANGE"
	check("tint: an oil change doesn't care", CounterRules.find_problems(c, 30, r.bolo).is_empty())
	var e := _plain(r, 30)
	r.excuse(e, 30, "tint")
	check("a good exemption covers dark windows", int(e.sheet.tint) < CounterRules.TINT_MIN and CounterRules.find_problems(e, 30, r.bolo).is_empty())
	e.exempt.name = r.other_name(String(e.exempt.name))
	check("...but only for the driver it names", CounterRules.find_problems(e, 30, r.bolo) == ["tint"])
	# 19. noise: 95 dB passes, 96 doesn't, and a hole fails however quiet it is
	var n := _plain(r, 37)
	n.request = "SAFETY INSPECTION"
	n.sheet.db = 95
	check("exhaust: 95 dB passes", CounterRules.find_problems(n, 37, r.bolo).is_empty())
	n.sheet.db = 96
	check("exhaust: 96 dB fails", CounterRules.find_problems(n, 37, r.bolo) == ["noise"])
	n.sheet.db = 80
	n.sheet.hole = true
	check("exhaust: a hole fails, quiet or not", CounterRules.find_problems(n, 37, r.bolo) == ["noise"])
	var rows_at := func(d: int) -> Array: return CounterRules.doc_rows(n, "sheet", d).map(func(x): return x[0])
	check("Gus's sheet grows its light meter and sound meter with their rules",
		not rows_at.call(27).has("TINT") and rows_at.call(30).has("TINT") and not rows_at.call(30).has("EXHAUST") and rows_at.call(36).has("EXHAUST"))

func _courier() -> void:
	# 20. the courier: a right box pays for the job it was for; a wrong one costs the shop, never the licence
	var r := CounterRules.new(31)
	r.make_bolo()
	var box := r.courier(31, "clean")
	var j := CounterRules.judge(box, "APPROVED", 31, r.bolo)
	check("a right box, signed for: the job it's for goes ahead", j.correct and j.money == int(CounterRules.PAY[String(box.order.job)]) and j.citation == "")
	check("a right box, refused: the wrong call", not CounterRules.judge(box, "DENIED", 31, r.bolo).correct)
	var wp := r.courier(31, "wrong_part")
	j = CounterRules.judge(wp, "APPROVED", 31, r.bolo)
	check("the wrong part, signed for: a restocking fee, no citation", not j.correct and int(j.fee) > 0 and j.citation == "")
	check("the wrong part, refused: the right call", CounterRules.judge(wp, "DENIED", 31, r.bolo).correct)
	var cv := r.courier(31, "customs_value")
	check("customs only comes on a box from the States", cv.has("customs") and not r.courier(31, "ship_to").has("customs"))
	check("a false declaration, signed for: the broker's penalty", int(CounterRules.judge(cv, "APPROVED", 31, r.bolo).fee) == CounterRules.CUSTOMS_PENALTY)
	var sp := r.courier(31, "clean")
	r.excuse(sp, 31, "wrong_part")
	check("a supplier's notice covers a new part number", String(sp.slip.no) != String(sp.order.no) and CounterRules.find_problems(sp, 31, r.bolo).is_empty())
	sp.notice.was = r.part_tweak(String(sp.notice.was))
	check("...but not a notice about some other number", CounterRules.find_problems(sp, 31, r.bolo) == ["wrong_part"])
	var car := _plain(r, 31)
	check("a car's papers never explain a box (and a box's never a car)", not r.excuse(car, 31, "wrong_part") and not r.excuse(r.courier(31, "clean"), 31, "tint"))
	var fam := r.courier(38, "", true)
	check("the Familia's box is addressed to Bay 3", fam.kind == "familia" and CounterRules.find_problems(fam, 38, r.bolo) == ["ship_to"] and int(CounterRules.judge(fam, "WRENCH", 38, r.bolo).dirty) > 0)
	# no courier before Gus opens the account; most days after
	var early := 0
	var days := 0
	var with_box := 0
	for day in open_days():
		var rr := CounterRules.new(day * 3 + 1)
		rr.make_bolo()
		var any: bool = rr.shift(day).any(func(x): return x.c.has("slip"))
		if day < 30 and any: early += 1
		if day >= 30:
			days += 1
			if any: with_box += 1
	check("no courier before the account's opened", early == 0)
	check("the courier comes most days from week 5", with_box * 2 >= days, "%d of %d" % [with_box, days])

func _audit() -> void:
	# 21. the audit: two files a day in week 7, rebuilt exactly, re-stamped against your own stamp
	check("Hachey pulls two files a day, in week 7 only", CounterRules.audit_times(42).size() == 2 and CounterRules.audit_times(39).is_empty())
	var bad := 0
	var tried := 0
	for day in [3, 12, 24, 31, 40]:
		var rr := CounterRules.new(day * 7)
		rr.make_bolo()
		for i in 25:
			var w := rr.walk_in(day)
			var probs := CounterRules.find_problems(w, day, rr.bolo)
			if probs.has("stolen"): continue
			tried += 1
			var back := CounterRules.rebuild({ "seed": w.seed, "day": day })
			if back.reg != w.reg or back.sheet != w.sheet or back.licence != w.licence or back.request != w.request or CounterRules.find_problems(back, day, []) != probs: bad += 1
	check("a walk-in's papers rebuild exactly from the file", bad == 0 and tried > 80, "%d/%d" % [bad, tried])
	var rng := RandomNumberGenerator.new()
	var files := [{ "no": 1, "day": 3, "stamp": "APPROVED", "correct": true, "probs": [], "kind": "regular", "seed": 5, "id": "" },
		{ "no": 2, "day": 4, "stamp": "REPORT", "correct": true, "probs": ["stolen"], "kind": "regular", "seed": 6, "id": "" },
		{ "no": 3, "day": 4, "stamp": "DENIED", "correct": true, "probs": ["photo_mismatch"], "kind": "regular", "seed": 7, "id": "" },
		{ "no": 4, "day": 31, "stamp": "APPROVED", "correct": true, "probs": [], "kind": "courier", "seed": -1, "id": "courier_fundy" },
		{ "no": 5, "day": 11, "stamp": "DENIED", "correct": true, "probs": [], "kind": "regular", "seed": -1, "id": "jayden" },
		{ "no": 6, "day": 43, "stamp": "APPROVED", "correct": true, "probs": [], "kind": "regular", "seed": 8, "id": "" }]
	var only := true
	for i in 20: if int(CounterRules.pull(files, 42, rng).get("no", 0)) != 1: only = false
	check("Hachey only pulls walk-ins you approved or denied, judged from papers alone, from before today", only)
	# every problem type a file can hold is findable from the file, on the file's own day
	var missing := 0
	tried = 0
	var note := ""
	for day in open_days():
		if day % 3 != 0 and day > 4: continue
		for prob in CounterRules.PROBLEM_RULE:
			if CounterRules.UNAUDITABLE.has(prob) or CounterRules.COURIER_PROBLEMS.has(prob): continue
			if not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			var rr := CounterRules.new(day * 11 + String(prob).length())
			rr.make_bolo()
			var w := rr.walk_in(day, prob)
			var a := CounterRules.audit_customer({ "no": 7, "day": day, "stamp": "DENIED", "correct": true, "seed": w.seed, "want": prob })
			tried += 1
			var ts := _file_reds(a)
			if not (ts.has(prob) or (prob == "no_insurance" and CounterRules.standing_topics(a, day).has(prob))):
				missing += 1
				if note == "": note = "day %d %s -> %s" % [day, prob, ts]
	check("every problem type is findable from a pulled file, under its own name", missing == 0 and tried > 60, "%d/%d %s" % [missing, tried, note])
	var rr := CounterRules.new(77)
	rr.make_bolo()
	var w := rr.walk_in(20, "expired_reg")
	var a := CounterRules.audit_customer({ "no": 12, "day": 20, "stamp": "DENIED", "correct": true, "seed": w.seed, "want": "expired_reg" })
	check("a pulled file: every paper out, no mask, Hachey at the window", a.kind == "audit" and a.hidden.is_empty() and a.mask == "" and int(a.window.face) == int(CounterRules.HACHEY.face))
	check("...dated the day it was stamped", CounterRules.doc_rows(a, "work", 42).any(func(x): return x[2] == "today" and x[3] == CounterRules.today(20)))
	var same := CounterRules.judge(a, "DENIED", 42, [])
	var diff := CounterRules.judge(a, "APPROVED", 42, [])
	check("stamping a file the same way twice: no citation", same.correct and same.citation == "")
	check("disagreeing with your own stamp: a citation", not diff.correct and String(diff.citation).begins_with("AUDIT"))
	check("Hachey isn't the customer: no red for his face against the photo", not _reds(a, 20, []).any(func(x): return String(x.text).contains("NOT THEM")))

func _regulars() -> void:
	# 22. the regulars: every visit, and every branch of it, is on an open day, under that day's rules,
	#     and its papers show exactly the problem it says it has
	var regs := DeskRegulars.regulars()
	check("the regulars are in story_customers.json", regs.has("jayden") and regs.has("rob") and regs.has("doiron") and regs.has("darrell"))
	var wrong := 0
	var tried := 0
	var note := ""
	var stamps_ok := true
	for id in regs:
		var vs: Array = regs[id].visits
		for k in vs.size():
			var v: Dictionary = vs[k]
			var day := int(v.day)
			if not CounterRules.is_open(day): wrong += 1
			var keys: Array = [""] + (v.get("after", {}) as Dictionary).keys()
			for key in keys:
				var stamp := String(key).trim_suffix("_WRONG")
				if key != "" and not stamp in ["APPROVED", "DENIED", "REPORT", "WRENCH", "WALKED"]: stamps_ok = false
				DeskBook.reset()
				if key != "": DeskBook.files = [{ "no": 1, "day": day - 1, "id": String(v.get("after_id", id)), "stamp": stamp, "correct": not String(key).ends_with("_WRONG"), "kind": "regular", "seed": -1 }]
				var s := DeskRegulars.spec(String(id), k)
				var r := CounterRules.new(day)
				r.make_bolo()
				var c := r.scripted(s, day)
				tried += 1
				var p := String(s.get("problem", "clean"))
				var found := CounterRules.find_problems(c, day, r.bolo)
				if found != c.flags or (p != "clean" and not CounterRules.rule_active(CounterRules.PROBLEM_RULE[p], day)) or c.kind != "regular" or String(s.last) != key:
					wrong += 1
					if note == "": note = "%s %d %s: %s vs %s" % [id, k, key, found, c.flags]
	DeskBook.reset()
	check("every regular's visit and branch is honest about its papers", wrong == 0 and tried > 40, "%d/%d %s" % [wrong, tried, note])
	check("branches are keyed by stamps", stamps_ok)
	var r := CounterRules.new(1)
	var j1 := r.scripted(DeskRegulars.spec("jayden", 0), 1)
	var j2 := r.scripted(DeskRegulars.spec("jayden", 3), 30)
	check("Jayden's the same kid in the same car every time", j1.person.face == j2.person.face and j1.car.plate == j2.car.plate and j1.car.vin == j2.car.vin)
	var d1 := r.scripted(DeskRegulars.spec("darrell", 0), 32)
	var d2 := r.scripted(DeskRegulars.spec("darrell", 1), 39)
	check("Darrell's trade-ins are different cars, same Darrell", d1.car.vin != d2.car.vin and d1.person.face == d2.person.face)
	var visits := 0
	for id in regs: visits += (regs[id].visits as Array).size()
	check("the regulars come in often enough to know", visits >= 15, "%d visits" % visits)
	# 23. no real car names in the regulars either (nor anybody named Vinny)
	var src := FileAccess.get_file_as_string(CounterRules.STORY_PATH).to_upper()
	var real := false
	for w in ["KIA ", "GOLF\"", "CARAVAN ", "CIVIC", "COROLLA", "ZAMBONI", "VINNY"]: if src.contains(w): real = true
	check("the regulars drive parody cars only", not real)

func _returns() -> void:
	# 24. the people you turn away come back: on the day their file says, the same person in the same car,
	#     with papers that tell the truth about what they brought
	DeskBook.reset()
	var came := 0
	var denied := 0
	var honest := true
	var same := true
	var twice := false
	var note := ""
	var wants := ["fails_inspection", "expired_reg", "insurance_expired", "name_mismatch", "tint", "noise", "clean"]
	for seed in 140:
		var r := CounterRules.new(seed * 13 + 1)
		r.make_bolo()
		var day: int = [3, 9, 15, 22, 29, 36][seed % 6]
		var want: String = wants[seed % wants.size()]
		if not CounterRules.rule_active(CounterRules.PROBLEM_RULE.get(want, "match"), day): continue
		var w := r.walk_in(day, want)
		var probs := CounterRules.find_problems(w, day, r.bolo)
		DeskBook.reset()
		var rec := DeskBook.file(day, w, "DENIED", not probs.is_empty(), probs)
		denied += 1
		var due := DeskRegulars.due(rec)
		if due < 0: continue
		var back := DeskRegulars.returns(due)
		if back.is_empty(): continue
		came += 1
		var bc := r.scripted(back[0], due)
		if CounterRules.find_problems(bc, due, r.bolo) != bc.flags:
			honest = false
			if note == "": note = "%s: %s vs %s" % [probs, CounterRules.find_problems(bc, due, r.bolo), bc.flags]
		if bc.person.face != w.person.face or bc.car.plate != w.car.plate or bc.car.vin != w.car.vin or bc.licence.number != w.licence.number: same = false
		var gap := 0
		var d := day
		while d < due:
			d = CounterRules.next_open(d)
			gap += 1
		if gap < 1 or gap > 4: same = false
		DeskBook.file(due, bc, "APPROVED", true, [])
		if not DeskRegulars.returns(due).is_empty() or not DeskBook.file_no(int(rec.no)).get("back", false): twice = true
	DeskBook.reset()
	check("about half the people you turn away come back", came * 4 >= denied and came * 4 <= denied * 3, "%d of %d" % [came, denied])
	check("the same person, the same car, one to four open days later", same)
	check("what they bring back is on the papers, honestly", honest, note)
	check("nobody comes back twice about the same file", not twice)
