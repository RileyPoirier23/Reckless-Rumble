## The people who come back to the window.
##
## The regulars (Jayden from the Mountain Tim's drive-thru, hockey dad Rob, Mrs. Doiron and her
## cursed Cava-lame, Darrell and his trade-ins) come in on their own days, and what Leo stamped
## on them last time changes what they say and what they bring this time. Who they are and
## their visits live in data/story_customers.json ("regulars"). A visit's "after" picks what
## changes, keyed by the last stamp: APPROVED, DENIED, REPORT or WRENCH, with _WRONG on the end
## when that stamp was the wrong call (the plain key covers both), or WALKED if they drove off
## at six. A branch that sets "problem" brings its own papers, proof and lines; "hello" goes in
## front of what they say.
##
## And anybody Leo turned away comes back one to four open days later (six in ten of them):
## with it fixed, with a paper from a pocket (good or not), or with the same problem and hopes
## for a different clerk. Somebody turned away for nothing is back for an oil change, and not
## happy about it.
##
## Both read DeskBook.files, which rides along in the story's save.
class_name DeskRegulars
extends RefCounted

## What somebody says when they come back with it fixed, by what was wrong last time.
const FIXED := {
	"fails_inspection": ["ME AGAIN. NEW TIRES, NEW PADS, NEW ATTITUDE. WELL. TWO OUT OF THREE.", "FIXED IT. GUS CAN LOOK. GUS CAN LOOK ALL HE WANTS."],
	"expired_reg": ["RENEWED IT. THE REGISTRY LADY SAID 'AGAIN?' I DON'T KNOW WHAT SHE MEANT.",
		"BACK. REGISTRATION'S GOOD TILL NEXT YEAR. I PUT A REMINDER IN MY PHONE. I'LL IGNORE IT."],
	"no_insurance": ["GOT INSURANCE. IT COSTS MORE THAN THE CAR. HAPPY?"],
	"insurance_expired": ["PAID THE INSURANCE. THE NEW CARD'S RIGHT THERE. STILL WARM FROM THE PRINTER."],
	"insurance_vin": ["THEY FIXED THE CARD. THE GIRL ON THE PHONE SAID IT WAS MY FAULT. IT WAS A LITTLE MY FAULT."],
	"name_mismatch": ["PUT IT IN MY NAME. MY BUDDY CRIED A LITTLE. IT WAS A GOOD CAR, HE SAID. IT STILL IS."],
	"bos_expired": ["REGISTERED IT. IN MY NAME. LIKE YOU SAID. LIKE THE LAW SAID. MOSTLY LIKE YOU SAID."],
	"vin_door_mismatch": ["FOUND THE BODY SHOP BILL. IT WAS IN THE DOOR. THE OTHER DOOR."],
	"out_of_province": ["BOOKED THE FULL ONE THIS TIME. A HUNDRED AND FORTY BUCKS. IN TORONTO THAT'S A SANDWICH."],
	"salvage_no_cert": ["GOT THE STRUCTURAL. THE GUY IN SALISBURY SIGNED IT. AT A DESK, THIS TIME."],
	"tint": ["PEELED THE TINT. TOOK ALL NIGHT. YOU CAN SEE MY FACE NOW. YOU'RE WELCOME."],
	"noise": ["NEW MUFFLER. THE NEIGHBOURS BROUGHT ME A PIE. I DIDN'T KNOW THEY KNEW MY NAME."],
	"no_winter_tires": ["WINTERS ARE ON. GOT 'EM OUT OF MY BROTHER-IN-LAW'S SHED WITH A CROWBAR. HE'S STILL IN FLORIDA. HE'LL FIND OUT."],
	"studs_out_of_season": ["STUDS ARE OFF. THE DRIVEWAY'S NEVER BEEN SO QUIET."],
}
## Back with the same problem, hoping for a different clerk.
const AGAIN := ["ME AGAIN. IS THE OTHER GUY HERE? THE NICE ONE?", "BACK AGAIN. I FIGURED YOU'D BE IN A BETTER MOOD TODAY.",
	"HI. WE'VE NEVER MET. I'VE NEVER BEEN HERE. NEW DAY, NEW ME."]
## Back with a paper (it might even be a good one).
const FOUND := ["ME AGAIN. I FOUND THE PAPER. IT WAS IN THE GLOVEBOX THE WHOLE TIME. EVERYTHING IS.",
	"BACK. I'VE GOT A PAPER NOW. ASK ME ABOUT IT. GO ON. ASK."]
## Turned away for nothing.
const WRONGED := ["LINDSAY PASSED IT IN TEN MINUTES. SHE GAVE ME A SUCKER. I'M ONLY HERE BECAUSE SHE DOESN'T DO OIL.",
	"YOU SENT ME AWAY FOR NOTHING LAST TIME. I'M GIVING YOU ONE MORE CHANCE. OIL CHANGE. DON'T FIND ANYTHING."]
## When a branch changes the problem, the visit's own papers, proof and lines go with it.
const RESETS := ["papers", "excuse", "forged", "ask", "outcomes", "from_away"]

static func regulars() -> Dictionary:
	return CounterRules.story_data().get("regulars", {})

# ------------------------------------------------------------------ the regulars

## Everybody whose visit is today, as specs for CounterRules.scripted.
static func visits(day: int) -> Array:
	var out: Array = []
	var regs := regulars()
	for id in regs:
		var vs: Array = (regs[id] as Dictionary).get("visits", [])
		for k in vs.size():
			if int((vs[k] as Dictionary).get("day", -1)) == day: out.append(spec(String(id), k))
	return out

## What Leo did with somebody last time, before `day`: "" if he's never seen them, WALKED, or
## the stamp, with _WRONG on the end when it was the wrong call.
static func outcome(id: String, day: int) -> String:
	var f := DeskBook.last_file(id, day)
	if f.is_empty(): return ""
	var s := String(f.stamp)
	return s if s == "WALKED" or bool(f.correct) else s + "_WRONG"

## Regular `id`'s visit `k`: who they are, the visit, and the branch for what happened last time.
## `known` is that last time, if it's known already (a file being rebuilt): "?" looks it up.
static func spec(id: String, k: int, known := "?") -> Dictionary:
	var reg: Dictionary = regulars().get(id, {})
	var v: Dictionary = (reg.get("visits", []) as Array)[k]
	var out := { "id": id, "regular": id, "seed": id, "kind": "regular", "visit": k }
	for key in ["cast", "person", "car"]:
		if reg.has(key): out[key] = _dup(reg[key])
	for key in v:
		if not key in ["after", "after_id", "day"]: out[key] = _dup(v[key])
	# a trade-in is a different car every time, with its own plate and VIN
	if v.has("car"): out.seed = "%s_%d" % [id, k]
	var last := outcome(String(v.get("after_id", id)), int(v.day)) if known == "?" else known
	out.last = last
	var after: Dictionary = v.get("after", {})
	for key in [last, last.trim_suffix("_WRONG")]:
		if key == "" or not after.has(key): continue
		var branch: Dictionary = after[key]
		if branch.has("problem"):
			for r in RESETS: out.erase(r)
		for b in branch: out[b] = _dup(branch[b])
		break
	if out.has("hello"): out.says = "%s %s" % [out.hello, out.get("says", "")]
	# small talk is the regular's own, whatever the visit
	var ask: Dictionary = _dup(reg.get("ask", {}))
	ask.merge(out.get("ask", {}), true)
	out.ask = ask
	return out

static func _dup(v: Variant) -> Variant:
	return (v as Dictionary).duplicate(true) if v is Dictionary else ((v as Array).duplicate(true) if v is Array else v)

# ------------------------------------------------------------------ the people you turned away

## Everybody coming back today about a work order Leo turned them away on.
static func returns(day: int) -> Array:
	var out: Array = []
	for rec in DeskBook.files:
		if due(rec) != day: continue
		var s := back_spec(rec)
		if not s.is_empty(): out.append(s)
	return out

## The day somebody comes back about a file (-1 if they don't): a walk-in Leo DENIED, one to
## four open days later, six in ten of them.
static func due(rec: Dictionary) -> int:
	if String(rec.stamp) != "DENIED" or String(rec.kind) != "regular" or String(rec.id) != "" or rec.get("back", false): return -1
	var s := int(rec.seed)
	if s < 0 or posmod(s >> 4, 10) >= 6: return -1
	var d := int(rec.day)
	for i in 1 + posmod(s, 4): d = CounterRules.next_open(d)
	return d

## The spec for somebody coming back: the same person in the same car (a few kilometres on),
## and what they did about it. {} if they don't come back after all.
static func back_spec(rec: Dictionary) -> Dictionary:
	var orig := CounterRules.rebuild(rec)
	if orig.is_empty(): return {}
	var h := absi(int(rec.seed) >> 7)
	var probs: Array = rec.get("probs", [])
	var p := String(probs[0]) if not probs.is_empty() else ""
	var car: Dictionary = (orig.car as Dictionary).duplicate(true)
	car.odo = int(car.odo) + 60 + h % 900
	var day := due(rec)
	var spec := { "id": "back_%d" % int(rec.no), "of": int(rec.no), "kind": "regular", "quiet": true,
		"person": (orig.person as Dictionary).duplicate(true), "car": car, "request": String(orig.request),
		"arrive": 30.0 + float(h % 420), "papers": { "licence": { "number": String(orig.licence.number) } } }
	# a cab's still a cab
	if (orig.reg as Dictionary).has("use"): spec.papers.reg = { "use": String(orig.reg.use) }
	if p == "":
		# turned away for nothing: back for something else, and not happy about it
		if h % 10 >= 5: return {}
		spec.request = "OIL CHANGE"
		spec.problem = "clean"
		spec.says = WRONGED[h % WRONGED.size()]
		return spec
	if not FIXED.has(p): return {}
	var mode := h % 20
	var has_proof: bool = CounterRules.PROOFS.has(p) and CounterRules.rule_active(CounterRules.PROOFS[p][1], day)
	if mode < 3:
		spec.problem = p
		spec.says = AGAIN[h % AGAIN.size()]
	elif mode < 7 and has_proof:
		# a paper from a pocket: good, or not
		spec.says = FOUND[h % FOUND.size()]
		if mode < 5 or p == "no_insurance":
			spec.problem = "clean"
			spec.excuse = p
		elif p == "name_mismatch":
			# a bill of sale that doesn't add up is its own problem
			spec.problem = "bos_forged"
		else:
			spec.problem = p
			spec.forged = true
	else:
		var lines: Array = FIXED[p]
		spec.problem = "clean"
		spec.says = lines[h % lines.size()]
		match p:
			"vin_door_mismatch", "salvage_no_cert": spec.excuse = p
			"out_of_province": spec.from_away = true
	return spec
