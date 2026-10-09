## The counter at Covington Auto: who walks in, what papers they carry, what's wrong with
## them, and what each stamp costs you. Pure logic (no drawing), so it can be tested headless.
##
## The generator injects problems; `find_problems` finds them again by reading only the
## documents, the car and the wall. The tests check that the two always agree, so every
## problem in the game can actually be caught by a player who looks.
class_name CounterRules
extends RefCounted

const YEAR := 2019                      # Year 1 of the story
const WEEK_START := [YEAR, 10, 7]       # Monday, October 7
const DAYS := ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"]
const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const VIN_CHARS := "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"

# the Ministry bulletin: what's checked from which day (day index 0 = Monday)
const RULES := [
	{ "day": 0, "id": "match", "text": "THE CAR MUST MATCH ITS REGISTRATION: PLATE AND VIN." },
	{ "day": 0, "id": "inspect", "text": "SAFETY INSPECTIONS: TREAD 1.6 MM+, PADS 3 MM+, ALL LIGHTS, NO RUST-THROUGH." },
	{ "day": 1, "id": "reg_valid", "text": "NO SERVICE ON AN EXPIRED REGISTRATION." },
	{ "day": 2, "id": "insured", "text": "NO INSURANCE, NO SERVICE. THE CARD MUST COVER THIS VIN, TODAY." },
	{ "day": 2, "id": "owner", "text": "THE LICENCE NAME MUST MATCH THE REGISTERED OWNER." },
	{ "day": 3, "id": "bolo", "text": "POLICE: REPORT ANY CAR ON THE STOLEN LIST. DO NOT TOUCH IT." },
	{ "day": 4, "id": "photo", "text": "THE LICENCE PHOTO MUST BE THE PERSON AT THE COUNTER." },
]

# problem -> the rule that catches it
const PROBLEM_RULE := {
	"vin_mismatch": "match", "plate_mismatch": "match", "fails_inspection": "inspect",
	"expired_reg": "reg_valid", "no_insurance": "insured", "insurance_expired": "insured",
	"insurance_vin": "insured", "name_mismatch": "owner", "stolen": "bolo", "photo_mismatch": "photo",
}

const FIRST := ["MARC", "JOEL", "DANIELLE", "KAYLA", "BRANDON", "NATALIE", "LUC", "SHAWN", "CHANTAL", "TYLER", "MELANIE", "JASON", "AMBER", "RENE", "KRISTA", "DEREK", "SYLVIE", "COREY", "JESSICA", "PAUL", "MONIQUE", "TRAVIS", "ASHLEY", "GILLES", "BRITTANY", "DYLAN", "NICOLE", "ROGER", "TAMMY", "KEVIN"]
const LAST := ["LEBLANC", "CORMIER", "GALLANT", "ARSENAULT", "DOUCETTE", "RICHARD", "MELANSON", "LANDRY", "THIBODEAU", "MACDONALD", "MACLEOD", "GAUDET", "BOURQUE", "SAVOIE", "ROBICHAUD", "BABINEAU", "LEGER", "COMEAU", "GOGUEN", "BELLIVEAU", "DUPUIS", "HACHE", "MAILLET", "STEEVES", "WILSON", "OUELLETTE", "BOUDREAU", "MALLET", "VAUTOUR", "DOIRON"]
const STREETS := ["MAIN ST", "ST GEORGE BLVD", "MOUNTAIN RD", "ELMWOOD DR", "HIGHFIELD ST", "CLOVERDALE RD", "BOTSFORD ST", "KING ST", "CHURCH ST", "SHEDIAC RD"]
const CARS := [
	{ "make": "HONDO", "model": "CIVIL", "len": 4.4, "wid": 1.7 },
	{ "make": "TOYODA", "model": "COROLLY", "len": 4.5, "wid": 1.72 },
	{ "make": "FJORD", "model": "ESCAPED", "len": 4.4, "wid": 1.8 },
	{ "make": "DODGY", "model": "CHARJER", "len": 5.0, "wid": 1.9 },
	{ "make": "CHEVROLAY", "model": "CAVA-LAME", "len": 4.6, "wid": 1.7 },
	{ "make": "FJORD", "model": "F-ONE-FIDDY", "len": 5.4, "wid": 2.0 },
	{ "make": "SUBAROO", "model": "IMPREZZA", "len": 4.4, "wid": 1.74 },
	{ "make": "VOLKSWAGON", "model": "GOLF", "len": 4.2, "wid": 1.78 },
	{ "make": "DODGY", "model": "GRAND CARAVAN", "len": 5.1, "wid": 1.95 },
	{ "make": "KIA", "model": "SOLE", "len": 4.1, "wid": 1.8 },
]
const PAINTS := ["#c8342c", "#2c5a8a", "#e8e4dc", "#2a2a2e", "#8a8e94", "#3a6a3a", "#d8a03a", "#6a2a4a", "#4a6a8a", "#b8b0a0"]
const REQUESTS := ["SAFETY INSPECTION", "SAFETY INSPECTION", "OIL CHANGE", "BRAKE JOB", "WINTER TIRES ON", "CHECK ENGINE LIGHT"]
const INSURERS := ["MARITIME MUTUAL", "TIDEWATER INSURANCE", "FUNDY GENERAL"]
# what each job brings into the shop
const PAY := { "SAFETY INSPECTION": 75, "OIL CHANGE": 70, "BRAKE JOB": 320, "WINTER TIRES ON": 110, "CHECK ENGINE LIGHT": 140 }
# what Friday night takes back out
const BILLS := [["RENT ON THE GARAGE", 1100], ["THE FAMILIA (FOR MIA'S CAR)", 400], ["ARIES'S HOCKEY", 120], ["GUS'S PAY", 800]]
const FINE := 100
const START_CASH := 300

var rng := RandomNumberGenerator.new()
var bolo: Array = []                    # [{plate, vin, car}] on the police list this week

func _init(seed := 506) -> void:
	rng.seed = seed

# ------------------------------------------------------------------ dates

## day offset from the start of the week -> [y, m, d]
static func date_add(base: Array, days: int) -> Array:
	var t := Time.get_unix_time_from_datetime_dict({ "year": base[0], "month": base[1], "day": base[2], "hour": 12 })
	var d := Time.get_datetime_dict_from_unix_time(t + days * 86400)
	return [d.year, d.month, d.day]

static func date_str(d: Array) -> String:
	return "%s %02d %d" % [MONTHS[d[1] - 1], d[2], d[0]]

static func date_cmp(a: Array, b: Array) -> int:
	for i in 3:
		if a[i] != b[i]: return -1 if a[i] < b[i] else 1
	return 0

static func today(day: int) -> Array:
	return date_add(WEEK_START, day)

static func rules_for(day: int) -> Array:
	return RULES.filter(func(r): return r.day <= day)

static func rule_active(id: String, day: int) -> bool:
	for r in RULES:
		if r.id == id: return r.day <= day
	return false

# ------------------------------------------------------------------ generators

func vin() -> String:
	var s := ""
	for i in 17: s += VIN_CHARS[rng.randi() % VIN_CHARS.length()]
	return s

## a VIN that's one or two characters off: the kind you only catch if you read it
func vin_tweak(v: String) -> String:
	var out := v
	var n := 1 + rng.randi() % 2
	var used: Array[int] = []
	while used.size() < n:
		var i := 9 + rng.randi() % 8
		if used.has(i): continue
		used.append(i)
		var c := out[i]
		var r := c
		while r == c: r = VIN_CHARS[rng.randi() % VIN_CHARS.length()]
		out = out.substr(0, i) + r + out.substr(i + 1)
	return out

func plate() -> String:
	var L := "ABCDEFGHJKLMNPRSTUVWXYZ"
	return "%s%s%s %03d" % [L[rng.randi() % L.length()], L[rng.randi() % L.length()], L[rng.randi() % L.length()], rng.randi() % 1000]

func plate_tweak(p: String) -> String:
	var digits := int(p.substr(4))
	var nd := digits
	while nd == digits: nd = (digits + 1 + rng.randi() % 9) % 1000
	return p.substr(0, 4) + "%03d" % nd

func person() -> Dictionary:
	return {
		"first": FIRST[rng.randi() % FIRST.size()], "last": LAST[rng.randi() % LAST.size()],
		"dob": [1950 + rng.randi() % 50, 1 + rng.randi() % 12, 1 + rng.randi() % 28],
		"address": "%d %s" % [10 + rng.randi() % 990, STREETS[rng.randi() % STREETS.size()]],
		"face": rng.randi(),
	}

## The stolen list for the week (seeded so the wall and the cars agree).
func make_bolo(n := 6) -> void:
	bolo = []
	for i in n:
		var c: Dictionary = CARS[rng.randi() % CARS.size()]
		bolo.append({ "plate": plate(), "vin": vin(), "car": "%s %s" % [c.make, c.model] })

## A customer for `day`. `want` forces a problem (for tests); otherwise it's rolled.
func customer(day: int, want := "") -> Dictionary:
	var p := person()
	var cm: Dictionary = CARS[rng.randi() % CARS.size()]
	var t := today(day)
	var car := {
		"make": cm.make, "model": cm.model, "year": 1998 + rng.randi() % 21, "paint": PAINTS[rng.randi() % PAINTS.size()],
		"len": cm.len, "wid": cm.wid, "plate": plate(), "vin": vin(), "odo": 40000 + rng.randi() % 260000,
	}
	var c := {
		"person": p, "car": car, "request": REQUESTS[rng.randi() % REQUESTS.size()], "kind": "regular",
		"face_shown": p.face,
		"reg": { "owner": "%s %s" % [p.first, p.last], "address": p.address, "plate": car.plate, "vin": car.vin,
			"car": "%d %s %s" % [car.year, car.make, car.model], "expires": date_add(t, 30 + rng.randi() % 330) },
		"licence": { "name": "%s %s" % [p.first, p.last], "dob": p.dob, "address": p.address, "face": p.face,
			"number": "%s%07d" % [p.last.substr(0, 1), rng.randi() % 10000000], "expires": date_add(t, 60 + rng.randi() % 1400) },
		"insurance": { "holder": "%s %s" % [p.first, p.last], "insurer": INSURERS[rng.randi() % INSURERS.size()], "vin": car.vin,
			"from": date_add(t, -(10 + rng.randi() % 300)), "to": date_add(t, 20 + rng.randi() % 300),
			"policy": "P-%06d" % (rng.randi() % 1000000) },
		"sheet": { "vin": car.vin, "odo": car.odo, "tread": [], "pads": [], "lights": true, "rust": false },
		"work": { "name": "%s %s" % [p.first, p.last], "plate": car.plate, "car": "%d %s %s" % [car.year, car.make, car.model] },
		"flags": [],
		"napkin": "",
	}
	for i in 4: c.sheet.tread.append(snappedf(2.4 + rng.randf() * 6.0, 0.1))
	for i in 2: c.sheet.pads.append(snappedf(3.5 + rng.randf() * 7.0, 0.1))
	# what's wrong with it (only problems the rules check today, so nothing is unfair)
	var options: Array = []
	for prob in PROBLEM_RULE:
		if rule_active(PROBLEM_RULE[prob], day): options.append(prob)
	var prob := want
	if prob == "" and rng.randf() < 0.45 and not options.is_empty():
		prob = options[rng.randi() % options.size()]
	if prob != "": _inject(c, prob, day)
	return c

func _inject(c: Dictionary, prob: String, day: int) -> void:
	var t := today(day)
	match prob:
		"vin_mismatch": c.reg.vin = vin_tweak(c.car.vin)
		"plate_mismatch": c.reg.plate = plate_tweak(c.car.plate)
		"fails_inspection":
			c.request = "SAFETY INSPECTION"
			match rng.randi() % 4:
				0: c.sheet.tread[rng.randi() % 4] = snappedf(0.4 + rng.randf() * 1.1, 0.1)
				1: c.sheet.pads[rng.randi() % 2] = snappedf(0.8 + rng.randf() * 2.0, 0.1)
				2: c.sheet.lights = false
				3: c.sheet.rust = true
		"expired_reg": c.reg.expires = date_add(t, -(1 + rng.randi() % 200))
		"no_insurance": c.insurance = {}
		"insurance_expired": c.insurance.to = date_add(t, -(1 + rng.randi() % 90))
		"insurance_vin": c.insurance.vin = vin_tweak(c.car.vin)
		"name_mismatch":
			var other := person()
			while other.last == c.person.last: other = person()
			c.reg.owner = "%s %s" % [other.first, other.last]
		"stolen":
			# the plate on the car is on the stolen list (and the papers were made to match)
			var b: Dictionary = bolo[rng.randi() % bolo.size()]
			c.car.plate = b.plate
			c.reg.plate = b.plate
			c.work.plate = b.plate
		"photo_mismatch":
			c.face_shown = c.person.face ^ (1 + rng.randi() % 0xffff)
	c.flags.append(prob)

## Thursday on: one of the Familia's cars. Something's wrong with it, and there's a napkin.
func familia(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch" if rng.randf() < 0.5 else "plate_mismatch")
	c.kind = "familia"
	c.napkin = ["DOM SAYS MAKE IT CLEAN. FAMILY PRICE. -V", "NEW NUMBERS ON THIS ONE. NO PAPERWORK. -V", "YOU KNOW WHAT TO DO. DOM SAYS HI. -V"][rng.randi() % 3]
	c.request = "\"DETAILING\""
	return c

## Friday: someone who isn't who he says he is asks for the thing you shouldn't do.
func sting(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch")
	c.kind = "sting"
	c.napkin = "HEARD YOU DO NEW NUMBERS. $800 CASH. NO QUESTIONS. -A FRIEND OF A FRIEND"
	c.request = "\"DETAILING\""
	return c

## A day's line-up.
func day_line(day: int) -> Array:
	var n := 5 + (1 if day >= 2 else 0)
	var out: Array = []
	for i in n: out.append(customer(day))
	if day >= 3: out.insert(2 + rng.randi() % 3, familia(day))
	if day == 4: out.insert(3 + rng.randi() % 2, sting(day))
	return out

# ------------------------------------------------------------------ reading the papers

## Every problem a careful player could prove today, read only from what's on the desk:
## the documents, the car in the window, the stolen list on the wall, the person's face.
static func find_problems(c: Dictionary, day: int, bolo_list: Array) -> Array:
	var out: Array = []
	var t := today(day)
	var reg: Dictionary = c.reg
	if rule_active("match", day):
		if reg.vin != c.sheet.vin: out.append("vin_mismatch")
		if reg.plate != c.car.plate: out.append("plate_mismatch")
	if rule_active("inspect", day) and c.request == "SAFETY INSPECTION":
		var fail := false
		for x in c.sheet.tread: if x < 1.6: fail = true
		for x in c.sheet.pads: if x < 3.0: fail = true
		if not c.sheet.lights or c.sheet.rust: fail = true
		if fail: out.append("fails_inspection")
	if rule_active("reg_valid", day) and date_cmp(reg.expires, t) < 0: out.append("expired_reg")
	if rule_active("insured", day):
		var ins: Dictionary = c.insurance
		if ins.is_empty(): out.append("no_insurance")
		else:
			if date_cmp(ins.to, t) < 0: out.append("insurance_expired")
			if ins.vin != c.sheet.vin: out.append("insurance_vin")
	if rule_active("owner", day) and c.licence.name != reg.owner: out.append("name_mismatch")
	if rule_active("bolo", day):
		for b in bolo_list:
			if b.plate == c.car.plate or b.vin == c.sheet.vin: out.append("stolen")
	if rule_active("photo", day) and c.face_shown != c.licence.face: out.append("photo_mismatch")
	return out

## What the stamp did. Returns { money, dirty, citation, heat, trust, review, line, correct }
static func judge(c: Dictionary, stamp: String, day: int, bolo_list: Array) -> Dictionary:
	var probs := find_problems(c, day, bolo_list)
	var r := { "money": 0, "dirty": 0, "citation": "", "heat": 0, "trust": 0, "review": 0, "line": "", "correct": true }
	var pay := PAY
	match c.kind:
		"familia":
			match stamp:
				"WRENCH": r.dirty = 600; r.trust = 10; r.heat = 4; r.line = "\"Dom says thanks. Family looks after family.\""
				"DENIED": r.trust = -15; r.line = "\"...I'll tell Dom you were busy.\" He doesn't look at you."
				"REPORT": r.trust = -60; r.heat = -5; r.line = "Twenty minutes later a black Charjer idles across the street. For an hour."
				_: r.trust = -5; r.line = "\"Wrong stamp, kid.\""
			r.correct = stamp == "WRENCH"
			return r
		"sting":
			match stamp:
				"WRENCH": r.heat = 60; r.citation = "UNDERCOVER STING: VIN TAMPERING. $2,000 FINE AND A FILE WITH YOUR NAME ON IT"; r.correct = false; r.line = "He badges you. \"Thought so.\""
				"DENIED": r.line = "\"No worries, man. Wrong garage.\" He writes something in his phone."
				"REPORT": r.heat = -15; r.line = "The cops come and go. One of them shakes your hand. The Familia hears about it."; r.trust = -10
				_: r.line = "He leaves."
			return r
	var bad := not probs.is_empty()
	if probs.has("stolen"):
		match stamp:
			"REPORT": r.line = "The police tow it. A cop says thanks without looking up."; r.heat = -5
			"APPROVED": r.correct = false; r.heat = 25; r.citation = "YOU WORKED ON A STOLEN CAR. IT WAS ON THE LIST ON YOUR WALL"
			"DENIED": r.correct = false; r.citation = "STOLEN CAR SENT BACK ON THE ROAD. IT WAS ON THE LIST: REPORT IT"
			"WRENCH": r.correct = false; r.heat = 40; r.citation = "OFF-BOOKS WORK ON A STOLEN CAR"
		return r
	match stamp:
		"APPROVED":
			if bad:
				r.correct = false
				r.citation = _citation_for(probs[0])
			else:
				r.money = pay.get(c.request, 80)
				r.review = 1
				r.line = ["\"Thanks, bud.\"", "\"Same time next year.\"", "\"Your dad would be proud.\"", "\"Cash okay?\""][c.person.face % 4]
		"DENIED":
			if bad:
				r.line = _denied_line(probs[0])
			else:
				r.correct = false
				r.review = -1
				r.line = "\"There's nothing wrong with my papers!\" A one-star review appears an hour later."
		"REPORT":
			r.correct = false
			r.review = -1
			r.heat = 3
			r.line = "The police show up for nothing. They are not amused, and neither is your customer."
		"WRENCH":
			r.correct = false
			r.heat = 8
			r.citation = "OFF-BOOKS WORK ON A CUSTOMER CAR (NO WORK ORDER, NO RECEIPT)"
	return r

static func _citation_for(p: String) -> String:
	match p:
		"vin_mismatch": return "VIN ON THE REGISTRATION DOESN'T MATCH THE CAR"
		"plate_mismatch": return "PLATE ON THE REGISTRATION DOESN'T MATCH THE CAR"
		"fails_inspection": return "PASSED A CAR THAT FAILS INSPECTION"
		"expired_reg": return "SERVICED A CAR WITH AN EXPIRED REGISTRATION"
		"no_insurance": return "SERVICED AN UNINSURED CAR"
		"insurance_expired": return "INSURANCE WAS EXPIRED"
		"insurance_vin": return "INSURANCE CARD COVERS A DIFFERENT VIN"
		"name_mismatch": return "LICENCE NAME DOESN'T MATCH THE REGISTERED OWNER"
		"photo_mismatch": return "THE LICENCE BELONGS TO SOMEBODY ELSE"
	return "PAPERWORK PROBLEM"

static func _denied_line(p: String) -> String:
	match p:
		"vin_mismatch": return "\"Must be a typo at the registry.\" Sure it is."
		"plate_mismatch": return "\"I swapped plates with my cousin, it's fine.\" It is not fine."
		"fails_inspection": return "\"How much to just... pass it?\" Gus coughs very loudly."
		"expired_reg": return "\"I've been MEANING to renew it.\""
		"no_insurance", "insurance_expired", "insurance_vin": return "\"Insurance is a scam anyway.\""
		"name_mismatch": return "\"It's my buddy's car. He said it's cool.\""
		"photo_mismatch": return "\"I got a haircut.\" And a new face, apparently."
	return "They leave, muttering."
