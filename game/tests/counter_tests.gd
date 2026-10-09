## Headless tests for the counter: godot --headless --path game -s tests/counter_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	# 1. every injected problem can be found again from the papers alone, and nothing else is wrong
	var bad := 0
	var total := 0
	var example := ""
	for day in 5:
		for prob in CounterRules.PROBLEM_RULE:
			if not CounterRules.rule_active(CounterRules.PROBLEM_RULE[prob], day): continue
			for seed in 40:
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
	for day in 5:
		for seed in 30:
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
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
