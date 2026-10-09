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
	for day in 5:
		for prob in CounterRules.PROBLEM_RULE.keys() + [""]:
			if prob != "" and not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			if prob == "no_insurance": continue
			for seed in 12:
				var rr := CounterRules.new(seed * 7 + day * 101)
				rr.make_bolo()
				var cust := rr.customer(day, prob) if prob != "" else rr.customer(day, "")
				if prob == "" and not CounterRules.find_problems(cust, day, rr.bolo).is_empty(): continue
				var sc := CounterScene.new()
				sc.rules = rr
				sc.car_view = CarView.new()
				sc.day = day
				sc.line = [cust]
				sc.idx = 0
				sc.next_customer()
				var fs := sc.fields()
				var red := false
				for a in fs.size():
					for b in range(a + 1, fs.size()):
						if sc.compare(fs[a], fs[b])[1] == false: red = true
				tried += 1
				if prob != "" and not red:
					unprovable += 1
					if note == "": note = "day %d %s" % [day, prob]
				if prob == "" and red: false_red += 1
				sc.car_view.free()
				sc.free()
	check("inspect proves every problem", unprovable == 0, "%d/%d unprovable %s" % [unprovable, tried, note])
	check("inspect shows no red on clean customers", false_red == 0, "%d" % false_red)
	_desk()
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
			for seed in 5:
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
