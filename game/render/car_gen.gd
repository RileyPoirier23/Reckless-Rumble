## Side-view cars, generated the CAGE BOSS way (src/art/portrait.ts there, counter/face.gd here):
## a car's catalogue facts (year, class, body, length, height, wheelbase, tyres, where the engine
## sits, its art cues) plus a seed from its id become a design, the car's DNA: dozens of
## independent proportions and details. paint() draws a design layer by layer into a pixel
## canvas: the silhouette, paint with a shoulder highlight, a sky band, the horizon and the ground
## reflected in it, glass with the seats behind it, trim, lamps and bumpers by era, and the wheels
## with their brakes behind the spokes. Same car, same picture, every time. No image files.
##
## The cars everybody knows get a line in ICONS on top of the rules, so the Charjer reads as a
## Charjer and the Coontash as a Coontash.
##
## Geometry is worked out in metres first (the skeleton), then every number in a design becomes a
## fraction of the car's length: x from the rear bumper (0) to the nose (1), y up from the ground.
class_name CarGen
extends RefCounted

const INK := Color("15181f")
const GLASS_TOP := Color("7b9cc0")
const GLASS := Color("33547a")
const GLASS_LO := Color("1f3550")
const CABIN := Color("121821")
const TIRE := Color("1c1f25")
const WELL := Color("0c0e12")
const TRIM := Color("23272e")
const RUBBER := Color("2c3036")
const AMBER := Color("f0a020")
const LAMP_RED := Color("c42630")
const STEEL := Color("5a5f67")
## Chrome, dark to bright: the ground reflected low, the sky high.
const CHROME: Array[Color] = [Color("3c434c"), Color("7a848f"), Color("b9c3cd"), Color("e6edf4"), Color("ffffff")]
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
## Windshield rake (degrees back from upright) by decade, 1950s to 2010s.
const RAKE: Array[float] = [33.0, 40.0, 50.0, 56.0, 60.0, 62.0, 63.0]

const DEFAULT_LEN := { "coupe": 4.5, "hatch": 4.1, "sedan": 4.8, "wagon": 4.8, "muscle": 4.9, "pickup": 5.4, "tow": 6.6,
	"suv": 4.8, "van": 5.1, "minivan": 4.9, "kei": 3.6, "bubble": 3.9, "roadster": 4.0, "sports": 4.4, "wedge": 4.3,
	"offroad": 4.2, "boxtruck": 6.8, "trike": 3.3 }
const DEFAULT_CLASS := { "coupe": "coupe", "hatch": "hatch", "sedan": "sedan", "wagon": "wagon", "muscle": "muscle",
	"pickup": "pickup", "tow": "work_truck", "suv": "suv", "van": "van", "minivan": "minivan", "kei": "kei",
	"bubble": "economy", "roadster": "sports", "sports": "sports", "wedge": "exotic", "offroad": "offroad",
	"boxtruck": "work_truck", "trike": "oddball" }
## Makes that build to Japanese taste (fender mirrors before '83, hardtop sedans, kei rules).
const JDM_MAKES := ["Toyoda", "Datsum", "Nissun", "Hondo", "Acurra", "Mazduh", "Subaroo", "Mitsubishy", "Suzooki",
	"Isuzoo", "Daihatsoo", "Lexis", "Infinitee", "Scionn"]
const US_MAKES := ["Fjord", "Chevrolay", "GMZ", "Pontiak", "Oldsmobeel", "Buickk", "Cadillak", "Linkoln", "Merkury",
	"Dodgy", "Plymooth", "Chryslur", "Jepp", "Ramm", "Rambla", "Studebakker", "Internashnal", "Hummor", "Saturne", "Geoh",
	"Chequer", "Grumpman", "Shelbee"]

static var _designs := {}

# ================================================================== the design

## The DNA for a car: a spec, a catalogue entry, a traffic car, a counter car ({cat}) or just
## { "body": "pickup", "year": 1988 }. Cached; treat it as read-only.
static func design(car: Dictionary) -> Dictionary:
	var f := facts(car)
	var key := String(f.key)
	if not _designs.has(key): _designs[key] = _dna(f)
	return _designs[key]

## What the catalogue knows about a car, in one flat shape, with sensible guesses for the rest.
static func facts(car: Dictionary) -> Dictionary:
	var id := String(car.get("id", car.get("cat", "")))
	var e := {}
	var tires: Dictionary = car.get("tires", {})
	if id != "" and CarCatalog.has(id):
		e = CarCatalog.entry(id)
		if tires.is_empty(): tires = CarCatalog.spec(id).get("tires", {})
	else:
		id = ""
	var src: Dictionary = e if not e.is_empty() else car
	var body := String(src.get("body", "sedan"))
	if not DEFAULT_LEN.has(body): body = "sedan"
	var year := int(src.get("year", 0))
	if year <= 0: year = int(car.get("year", 1995))
	var length := float(src.get("length", car.get("len", DEFAULT_LEN[body])))
	var eng: Dictionary = src.get("engine", {})
	var art: Dictionary = (src.get("art", {}) as Dictionary).duplicate()
	var f := {
		"id": id, "make": String(src.get("make", "")), "model": String(src.get("model", "")), "year": year,
		"cls": String(src.get("class", DEFAULT_CLASS[body])), "body": body, "L": maxf(1.2, length),
		"W": float(src.get("width", car.get("wid", 1.8))), "WB": float(src.get("wheelbase", length * 0.6)),
		"pos": String(eng.get("position", "front")), "drive": String(src.get("drivetrain", "RWD")),
		"art": art, "tokens": src.get("tokens", []),
		"tire_m": float(tires.get("radius", 0.0)), "tire_size": String(tires.get("size", "")),
	}
	f.key = id if id != "" else "%s|%d|%.2f|%s|%s" % [body, year, length, f.cls, str(art.keys())]
	return f

## Which skeleton a car is built on.
static func _family(f: Dictionary) -> String:
	var body: String = f.body
	var art: Dictionary = f.art
	match body:
		"sports":
			return "mid" if f.pos == "mid" else ("rear" if f.pos == "rear" else "sports")
		"wedge":
			return "wedge"
		"roadster":
			return "coupe" if art.has("hardtop") else "roadster"
		"offroad":
			return "offroad"
		"tow":
			return "pickup"
		"trike":
			return "hatch"
	return body

static func _height(f: Dictionary, fam: String, era: int) -> float:
	var cls: String = f.cls
	var L: float = f.L
	var year: int = f.year
	var h := 1.42
	match fam:
		"sedan": h = [1.5, 1.4, 1.37, 1.38, 1.41, 1.46, 1.47][era]
		"wagon": h = [1.52, 1.44, 1.42, 1.42, 1.45, 1.5, 1.52][era]
		"coupe": h = [1.42, 1.35, 1.33, 1.31, 1.3, 1.37, 1.38][era]
		"muscle": h = 1.31 if year < 2000 else 1.45
		"hatch": h = [1.38, 1.36, 1.35, 1.36, 1.38, 1.45, 1.47][era]
		"sports": h = 1.27
		"rear": h = 1.3
		"mid": h = 1.12
		"wedge": h = 1.16
		"roadster": h = 1.26
		"suv": h = 1.68 if cls == "crossover" else (1.84 if L > 5.3 else 1.78)
		"offroad": h = 1.8
		"pickup":
			if f.art.get("cab", "") == "ute": h = 1.38
			elif f.art.get("cab", "") == "cabover": h = 1.76
			elif L < 5.05: h = 1.62
			else: h = [1.8, 1.82, 1.83, 1.84, 1.85, 1.9, 1.95][era] + (0.08 if cls in ["hd_pickup", "work_truck"] else 0.0)
		"van": h = 2.05 if year < 2005 else 2.5
		"minivan": h = 1.72
		"kei": h = 1.64
		"bubble": h = 1.42
		"boxtruck": h = 3.1
	if cls == "luxury" and not fam in ["suv", "offroad", "pickup"]: h += 0.03
	if cls == "exotic" and fam in ["sports", "coupe", "mid", "wedge"]: h -= 0.04
	if f.body == "trike": h = 1.4
	return h

static func _j(r: RandomNumberGenerator, v: float, pct: float) -> float:
	return v * (1.0 + r.randf_range(-pct, pct))

static func _pick(r: RandomNumberGenerator, a: Array) -> Variant:
	return a[r.randi() % a.size()]

## The skeleton, in metres: where the windshield sits and how far it leans, the hood, the roof,
## the deck, the glass. Every family starts from the same list and changes what it needs.
static func _skeleton(f: Dictionary, fam: String, era: int, L: float, H: float, r: RandomNumberGenerator) -> Dictionary:
	var year: int = f.year
	var cls: String = f.cls
	var art: Dictionary = f.art
	var fwd: bool = f.drive == "FWD"
	var g := {
		"rear": "notch", "nose": "round", "clear": 0.15, "rocker": 0.07, "hood_h": 0.76, "cowl_rise": 0.17,
		"cowl_d": 0.36 * L, "rake": RAKE[era], "belt_up": 0.03, "kick": 0.0, "tail_x": 0.02, "tail_h": 0.98,
		"deck": 0.13 * L, "deck_rise": 0.02, "bl_rake": 55.0, "crown": 0.02, "rt": 0.07, "a_w": 0.09,
		"c_top": 0.12, "c_bot": -0.06, "soft": 0.8, "nose_drop": 0.2, "nose_round": 0.06, "nose_lean": 0.0,
		"nose_bot": 0.2, "tail_bot": 0.24, "tail_mid": 0.55, "ff": 0.44, "rear_d": 0.06, "d_w": 0.16,
		"cab_d": 0.0, "bed_h": 0.0, "box_d": 0.0, "cab": "", "fin": 0.0, "doors": 4, "quarter": true,
	}
	match fam:
		"sedan", "wagon":
			g.clear = 0.17 if era <= 1 else 0.15
			g.hood_h = [0.8, 0.76, 0.76, 0.74, 0.72, 0.76, 0.8][era]
			g.cowl_rise = [0.06, 0.08, 0.12, 0.17, 0.18, 0.18, 0.18][era]
			g.cowl_d = L * [0.4, 0.39, 0.39, 0.37, 0.36, 0.35, 0.35][era]
			g.kick = [-0.02, 0.0, 0.0, 0.0, 0.03, 0.05, 0.07][era]
			g.tail_h = [0.95, 0.9, 0.93, 0.96, 0.98, 1.03, 1.06][era]
			g.deck = L * [0.21, 0.2, 0.19, 0.16, 0.14, 0.12, 0.11][era]
			g.bl_rake = [45.0, 52.0, 50.0, 38.0, 55.0, 60.0, 63.0][era]
			g.crown = [0.035, 0.015, 0.01, 0.006, 0.02, 0.03, 0.035][era]
			g.soft = [0.9, 0.5, 0.35, 0.2, 0.75, 0.9, 0.95][era]
			g.c_top = [0.16, 0.14, 0.2, 0.16, 0.12, 0.1, 0.1][era]
			g.c_bot = [-0.06, -0.04, 0.04, 0.0, -0.06, -0.1, -0.12][era]
			g.ff = 0.52 if fwd else 0.44
			g.tail_mid = g.tail_h * 0.6
			if fam == "wagon":
				g.rear = "box"
				g.rear_d = 0.1
				g.d_w = 0.2
				g.tail_h = g.hood_h + g.cowl_rise + g.belt_up + g.kick
				g.ff = 0.44 if fwd else 0.4
		"coupe":
			g.clear = 0.15
			g.hood_h = [0.78, 0.74, 0.74, 0.72, 0.7, 0.72, 0.76][era]
			g.cowl_rise = [0.06, 0.08, 0.11, 0.15, 0.16, 0.17, 0.17][era]
			g.cowl_d = L * [0.42, 0.42, 0.42, 0.38, 0.38, 0.38, 0.38][era]
			g.kick = [0.0, 0.02, 0.02, 0.0, 0.03, 0.04, 0.06][era]
			g.tail_h = [0.93, 0.9, 0.92, 0.94, 0.95, 1.0, 1.02][era]
			g.deck = L * [0.2, 0.18, 0.18, 0.15, 0.13, 0.12, 0.1][era]
			g.bl_rake = [50.0, 58.0, 60.0, 48.0, 58.0, 64.0, 66.0][era]
			g.crown = [0.03, 0.015, 0.01, 0.008, 0.02, 0.03, 0.035][era]
			g.soft = [0.9, 0.5, 0.35, 0.2, 0.8, 0.9, 0.95][era]
			g.c_top = 0.1
			g.c_bot = -0.16
			g.doors = 2
			g.ff = 0.5 if fwd else 0.44
			var fast_odds: float = [0.0, 0.35, 0.25, 0.3, 0.35, 0.4, 0.45][era]
			if cls == "pony" and year >= 1980: fast_odds = 1.0
			if r.randf() < fast_odds:
				g.rear = "fast"
				g.bl_rake = 70.0
				g.c_bot = -0.3
		"muscle":
			g.clear = 0.15
			g.hood_h = 0.76 if year < 2000 else 0.86
			g.cowl_rise = 0.1 if year < 2000 else 0.14
			g.cowl_d = L * 0.44
			g.kick = 0.06
			g.tail_h = 0.9 if year < 2000 else 1.02
			g.deck = L * 0.17
			g.bl_rake = 60.0 if year < 2000 else 66.0
			g.crown = 0.012
			g.soft = 0.5 if year < 2000 else 0.85
			g.doors = 2
			g.c_top = 0.1
			g.c_bot = -0.14
			if year < 1970 and r.randf() < 0.5:
				g.rear = "fast"
				g.bl_rake = 72.0
				g.c_bot = -0.32
		"hatch":
			g.clear = 0.14
			g.hood_h = [0.7, 0.7, 0.7, 0.68, 0.66, 0.72, 0.78][era]
			g.cowl_rise = 0.2
			g.cowl_d = L * [0.3, 0.3, 0.32, 0.32, 0.31, 0.3, 0.3][era]
			g.kick = [0.0, 0.0, 0.0, 0.0, 0.02, 0.04, 0.06][era]
			g.soft = [0.8, 0.5, 0.35, 0.25, 0.8, 0.9, 0.95][era]
			g.rear = "hatch"
			g.ff = 0.56 if fwd else 0.48
			g.doors = 2 if cls in ["hot_hatch", "sports", "coupe", "rally"] or L < 3.9 or r.randf() < 0.4 else 4
			var lift_odds := 0.9 if cls in ["sports", "coupe", "jdm", "pony"] else (0.3 if cls in ["compact", "hatch"] else 0.1)
			if r.randf() < lift_odds:
				g.tail_h = 0.86
				g.bl_rake = 68.0
				g.c_top = 0.12
				g.c_bot = -0.2
			else:
				g.tail_h = 0.9 if era <= 4 else 0.98
				g.bl_rake = [24.0, 24.0, 28.0, 30.0, 38.0, 45.0, 50.0][era]
				g.c_top = 0.14
				g.c_bot = 0.04
			g.tail_x = 0.0
			g.tail_mid = 0.55
		"suv":
			var cross := cls == "crossover"
			g.clear = 0.2 if cross else 0.25
			g.hood_h = [1.0, 1.0, 1.0, 0.98, 0.98, 1.02, 1.04][era] - (0.08 if cross else 0.0)
			g.cowl_rise = 0.12
			g.cowl_d = L * 0.33
			g.rake = RAKE[era] - 4.0
			g.kick = 0.04 if era >= 5 else 0.0
			g.rear = "box"
			g.rear_d = 0.06 if not cross else 0.22
			g.d_w = 0.16
			g.soft = [0.5, 0.4, 0.3, 0.2, 0.5, 0.7, 0.85][era]
			g.ff = 0.5 if cross and fwd else 0.45
			g.nose_drop = 0.3
			g.nose_bot = 0.3
			g.tail_bot = 0.32
		"offroad":
			g.clear = 0.3
			g.hood_h = 1.0
			g.cowl_rise = 0.06
			g.cowl_d = L * 0.4
			g.rake = 24.0 if year < 2005 else 32.0
			g.rear = "open" if art.has("open") else "box"
			g.rear_d = 0.02
			g.d_w = 0.14
			g.soft = 0.15 if year < 2005 else 0.35
			g.ff = 0.47
			g.doors = 2 if L < 4.3 else 4
			g.nose = "blunt"
			g.nose_drop = 0.36
			g.nose_round = 0.02
			g.nose_bot = 0.36
			g.tail_bot = 0.38
		"pickup":
			var cab := String(art.get("cab", "reg"))
			if f.body == "tow": cab = "reg"
			var small := L < 5.05
			g.cab = cab
			g.clear = 0.22 if small else 0.27
			g.hood_h = [0.95, 0.98, 1.0, 1.02, 1.05, 1.15, 1.25][era] - (0.12 if small else 0.0)
			g.cowl_rise = 0.1
			g.cowl_d = L * (0.34 if small else 0.33)
			g.rake = [35.0, 38.0, 42.0, 45.0, 52.0, 55.0, 56.0][era]
			g.rear = "pickup"
			g.soft = [0.6, 0.4, 0.25, 0.2, 0.5, 0.6, 0.6][era]
			g.ff = 0.43
			g.nose = "blunt"
			g.nose_round = 0.03
			g.nose_drop = 0.36
			g.nose_bot = 0.34
			g.tail_bot = 0.36
			# the bed decides where the cab ends: an 8-foot box on a regular cab, shorter as the cab grows
			var bed_len: float = { "reg": 2.45, "ext": 1.98, "crew": 1.68 }.get(cab, 2.45) if not small else { "reg": 1.85, "ext": 1.83, "crew": 1.55 }.get(cab, 1.85)
			if L < 4.7: bed_len = minf(bed_len, L * 0.36)
			g.cab_d = L - bed_len - 0.08
			g.bed_h = g.hood_h - 0.02
			g.doors = 4 if cab == "crew" else 2
			g.quarter = cab == "ext"
			if cab == "ute":
				g.hood_h = 0.78
				g.cowl_rise = 0.14
				g.cowl_d = L * 0.4
				g.rake = RAKE[era]
				g.clear = 0.17
				g.cab_d = L - 1.85
				g.bed_h = 0.98
				g.nose = "round"
				g.nose_drop = 0.22
				g.nose_bot = 0.22
				g.tail_bot = 0.26
				g.soft = 0.5
			elif cab == "cabover":
				g.hood_h = 0.95
				g.cowl_rise = 0.04
				g.cowl_d = 0.12
				g.rake = 14.0
				g.cab_d = 1.4
				g.bed_h = 0.9
				g.clear = 0.2
				g.ff = 0.28
				g.nose_drop = 0.55
				g.nose_round = 0.02
				g.nose_bot = 0.28
		"van":
			var modern := year >= 2005
			var rear_eng: bool = f.pos == "rear"
			g.clear = 0.2
			g.hood_h = 1.0 if not modern else 0.98
			g.cowl_rise = 0.12
			g.cowl_d = L * (0.22 if not rear_eng else 0.05)
			g.rake = 48.0 if not modern else 58.0
			if rear_eng:
				g.rake = 18.0
				g.hood_h = 0.92
				g.cowl_rise = 0.06
			g.rear = "box"
			g.rear_d = 0.02
			g.d_w = 0.14
			g.rt = 0.22 if modern else 0.15
			g.soft = 0.4 if not modern else 0.7
			g.ff = 0.38
			g.nose = "blunt" if not modern else "round"
			g.nose_drop = 0.4
			g.nose_bot = 0.3
			g.tail_bot = 0.32
		"minivan":
			g.clear = 0.17
			g.hood_h = 0.86
			g.cowl_rise = 0.18
			g.cowl_d = L * 0.26
			g.rake = 64.0
			g.rear = "box"
			g.rear_d = 0.1
			g.d_w = 0.18
			g.soft = 0.85
			g.kick = 0.02
			g.ff = 0.5
			g.nose_drop = 0.28
		"kei":
			g.clear = 0.15
			g.hood_h = 0.78
			g.cowl_rise = 0.15
			g.cowl_d = L * 0.22
			g.rake = 52.0
			g.rear = "box"
			g.rear_d = 0.02
			g.d_w = 0.14
			g.soft = 0.45
			g.ff = 0.5
			g.nose = "blunt"
			g.nose_drop = 0.26
		"bubble":
			g.clear = 0.17
			g.hood_h = 0.66
			g.cowl_rise = 0.2
			g.cowl_d = L * 0.32
			g.rake = 45.0
			g.rear = "fast"
			g.bl_rake = 55.0
			g.tail_h = 0.72
			g.crown = 0.09
			g.soft = 2.2
			g.ff = 0.42 if f.pos == "rear" else 0.5
			g.doors = 2
			g.c_bot = -0.06
			g.nose_drop = 0.24
			g.nose_round = 0.14
		"roadster":
			g.clear = 0.13
			g.hood_h = 0.66
			g.cowl_rise = 0.12
			g.cowl_d = L * 0.44
			g.rake = 50.0 if year < 1980 else 62.0
			g.rear = "open"
			g.tail_h = 0.8
			g.soft = 1.0 if year < 1975 else 0.8
			g.doors = 2
			g.kick = 0.02
			g.ff = 0.45 if f.pos == "front" else 0.52
			g.nose_drop = 0.2
			g.nose_round = 0.1
		"sports":
			g.clear = 0.12
			g.hood_h = 0.64
			g.cowl_rise = 0.14
			g.cowl_d = L * 0.46
			g.rake = RAKE[era] + 6.0
			g.rear = "fast"
			g.tail_h = 0.9
			g.bl_rake = 72.0
			g.kick = 0.04
			g.doors = 2
			g.c_top = 0.1
			g.c_bot = -0.3
			g.soft = [0.9, 0.8, 0.6, 0.35, 0.85, 0.9, 0.95][era]
			g.ff = 0.45
			g.nose_drop = 0.18
			g.nose_round = 0.1
		"mid":
			g.clear = 0.11
			g.hood_h = 0.6
			g.cowl_rise = 0.18
			g.cowl_d = L * 0.33
			g.rake = 62.0
			g.deck = L * 0.2
			g.bl_rake = 75.0
			g.tail_h = 0.9
			g.doors = 2
			g.soft = 1.0
			g.ff = 0.52
			g.c_top = 0.08
			g.c_bot = -0.12
			g.nose_drop = 0.18
			g.nose_round = 0.1
		"rear":
			g.clear = 0.13
			g.hood_h = 0.58
			g.cowl_rise = 0.24
			g.cowl_d = L * 0.36
			g.rake = 58.0
			g.rear = "fast"
			g.tail_h = 0.76
			g.bl_rake = 66.0
			g.doors = 2
			g.soft = 1.3
			g.ff = 0.47
			g.c_top = 0.1
			g.c_bot = -0.24
			g.nose_drop = 0.16
			g.nose_round = 0.12
		"wedge":
			var front_eng: bool = f.pos == "front"
			g.clear = 0.11
			g.hood_h = 0.56
			g.cowl_rise = 0.22
			g.cowl_d = L * (0.4 if front_eng else 0.31)
			g.rake = 68.0 if year >= 1970 else 60.0
			g.deck = L * (0.12 if front_eng else 0.21)
			g.bl_rake = 76.0 if not front_eng else 62.0
			g.tail_h = 0.95
			g.doors = 2
			g.soft = 0.12 if year < 1990 else 0.85
			g.ff = 0.46 if front_eng else 0.52
			g.c_top = 0.08
			g.c_bot = -0.1
			g.nose = "wedge"
			g.nose_drop = 0.12
			g.nose_round = 0.08
			g.nose_lean = 0.03
			g.nose_bot = 0.17
		"boxtruck":
			var model := String(f.model).to_lower()
			g.cab = "cabover" if art.has("cabover") else ("step" if model.contains("step") else ("van" if model.contains("cube") else "conv"))
			g.rear = "boxtruck"
			g.clear = 0.32
			g.soft = 0.25
			g.nose = "blunt"
			g.nose_bot = 0.36
			g.tail_bot = 0.5
			match String(g.cab):
				"cabover":
					g.hood_h = 1.25
					g.cowl_rise = 0.05
					g.cowl_d = 0.12
					g.rake = 10.0
					g.box_d = 2.0
					g.ff = 0.2
					g.nose_drop = 0.7
				"step":
					g.hood_h = 1.2
					g.cowl_rise = 0.08
					g.cowl_d = 0.35
					g.rake = 22.0
					g.box_d = 0.0
					g.ff = 0.3
					g.nose_drop = 0.6
				"van":
					g.hood_h = 1.05
					g.cowl_rise = 0.12
					g.cowl_d = 1.25
					g.rake = 52.0
					g.box_d = 2.45
					g.ff = 0.3
					g.nose_drop = 0.45
				_:
					g.hood_h = 1.3
					g.cowl_rise = 0.1
					g.cowl_d = 2.0
					g.rake = 25.0
					g.box_d = 3.0
					g.ff = 0.3
					g.nose_drop = 0.5
			g.cab_h = 2.3 if g.cab != "step" else H
			g.doors = 2
	if art.has("fins") and fam in ["sedan", "coupe", "wagon", "roadster"]:
		g.fin = { 1956: 0.08, 1957: 0.12, 1958: 0.15, 1959: 0.24, 1960: 0.14 }.get(year, 0.07)
	# a little of the car's own in every number, so no two cars share a silhouette
	for k in ["hood_h", "cowl_rise", "cowl_d", "tail_h", "deck", "crown", "c_top", "rt", "nose_drop", "nose_round"]:
		g[k] = _j(r, float(g[k]), 0.04)
	for k in ["rake", "bl_rake"]:
		g[k] = float(g[k]) + r.randf_range(-2.0, 2.0)
	g.kick = float(g.kick) + r.randf_range(-0.012, 0.012)
	g.belt_up = float(g.belt_up) + r.randf_range(-0.012, 0.012)
	return g

static func _dna(f: Dictionary) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(f.key))
	var L: float = f.L
	var year: int = f.year
	var era := clampi((year - 1950) / 10, 0, 6)
	var fam := _family(f)
	var icon: Dictionary = ICONS.get(String(f.id), {})
	var H := float(icon.get("H", _height(f, fam, era) * (1.0 + r.randf_range(-0.015, 0.015))))
	var g := _skeleton(f, fam, era, L, H, r)
	for k in icon:
		if g.has(k): g[k] = icon[k]
	if icon.has("deck") and not icon.has("rear"): g.rear = "notch"
	var d := { "id": f.id, "year": year, "cls": f.cls, "body": f.body, "family": fam, "make": f.make,
		"model": f.model, "rear": g.rear, "nose": g.nose, "L": L, "h": H / L, "cab": g.cab, "doors": g.doors,
		"soft": float(g.soft), "art": f.art, "pos": f.pos }
	# --- wheels
	var tire_m: float = f.tire_m
	var rim_in := 0.0
	var ts: String = f.tire_size
	if ts.contains("R"): rim_in = float(ts.get_slice("R", 1))
	if tire_m <= 0.0:
		tire_m = 0.3
		if fam in ["pickup", "suv", "offroad", "van"]: tire_m = 0.37
		elif fam in ["kei", "bubble"] or L < 3.6: tire_m = 0.27
		elif fam == "boxtruck": tire_m = 0.45
	if rim_in <= 0.0: rim_in = clampf(13.0 + float(year - 1950) * 0.08, 13.0, 18.0)
	var rim_frac := clampf(rim_in * 0.0254 * 0.5 / tire_m, 0.42, 0.82)
	if fam == "boxtruck": rim_frac = 0.55
	var oh: float = maxf(0.25, L - float(f.WB))
	var ff: float = g.ff
	d.wf = 1.0 - oh * ff / L
	d.wr = oh * (1.0 - ff) / L
	d.tire_r = tire_m / L * float(icon.get("tire", 1.0)) * (1.1 if fam in ["pickup", "suv", "offroad"] else 1.06)
	d.rim = float(icon.get("rim_frac", rim_frac))
	# the wheels stay inside the bumpers, even on a car that's nearly all wheel
	d.wr = maxf(float(d.wr), float(d.tire_r) * 1.08)
	d.wf = minf(float(d.wf), 1.0 - float(d.tire_r) * 1.08)
	# and the hood clears the front arch
	var arch_top := float(d.tire_r) * L * 2.2 + 0.05
	var cowl_m := float(g.hood_h) + float(g.cowl_rise)
	var cowl_f := 1.0 - float(g.cowl_d) / L
	var at_wheel := clampf((1.0 - float(d.wf)) / maxf(0.05, 1.0 - cowl_f), 0.0, 1.0)
	var hood_at_wheel := lerpf(float(g.hood_h), cowl_m, at_wheel)
	if hood_at_wheel < arch_top + 0.04: g.hood_h = float(g.hood_h) + arch_top + 0.04 - hood_at_wheel
	# --- the body, in fractions
	var hood_h: float = g.hood_h
	var cowl_h: float = hood_h + float(g.cowl_rise)
	d.clear = float(g.clear) / L
	d.rocker = (float(g.clear) + float(g.rocker)) / L
	d.hood_h = hood_h / L
	d.cowl_h = cowl_h / L
	d.cowl_x = 1.0 - float(g.cowl_d) / L
	var rake := deg_to_rad(float(g.rake))
	var top_h := H
	if fam == "boxtruck" and g.cab != "step": top_h = float(g.cab_h)
	if fam == "van" and H > 2.15: top_h = 2.0
	d.cab_top = top_h / L
	d.roof_f = float(d.cowl_x) - (top_h - cowl_h) * tan(rake) / L
	d.belt_f = (cowl_h + float(g.belt_up)) / L
	d.belt_r = float(d.belt_f) + float(g.kick) / L
	d.nose_x = 1.0 - float(g.nose_round) / L
	d.nose_mid = maxf(float(g.nose_bot) + 0.06, hood_h - float(g.nose_drop)) / L
	d.nose_bot = float(g.nose_bot) / L
	d.nose_lean = float(g.nose_lean) / L
	d.tail_bot = float(g.tail_bot) / L
	d.crown = float(g.crown) / L
	d.rt = float(g.rt) / L
	d.a_w = float(g.a_w) / L
	d.fin = float(g.fin) / L
	d.tail_x = float(g.tail_x) / L
	d.tail_h = float(g.tail_h) / L
	d.tail_mid = minf(float(g.tail_mid), float(g.tail_h) - 0.12) / L
	d.deck_x = 0.0
	d.deck_h = 0.0
	match String(g.rear):
		"notch":
			d.deck_x = (float(g.tail_x) + float(g.deck)) / L
			d.deck_h = (float(g.tail_h) + float(g.deck_rise)) / L
			d.roof_r = float(d.deck_x) + (H - float(g.tail_h) - float(g.deck_rise)) * tan(deg_to_rad(float(g.bl_rake))) / L
		"fast", "hatch":
			d.roof_r = float(d.tail_x) + (H - float(g.tail_h)) * tan(deg_to_rad(float(g.bl_rake))) / L
		"pickup":
			d.cab_x = 1.0 - float(g.cab_d) / L
			d.bed_h = float(g.bed_h) / L
			d.roof_r = float(d.cab_x) + 0.03 / L
			d.tail_h = d.bed_h
			if g.cab == "ute":
				d.roof_r = float(d.cab_x) + 0.35 / L
		"boxtruck":
			d.box_x = 1.0 - float(g.box_d) / L if float(g.box_d) > 0.0 else 1.0
			d.roof_r = float(d.box_x) + 0.02 / L
			d.tail_h = d.h
		"open":
			d.roof_r = float(d.roof_f) - 0.2
			d.deck_x = (float(g.tail_x) + float(g.deck)) / L
		_:
			d.roof_r = float(g.rear_d) / L
	if g.rear == "pickup" and float(d.roof_f) - float(d.cab_x) < 0.6 / L:
		d.cab_x = float(d.roof_f) - 0.6 / L
		d.roof_r = float(d.cab_x) + 0.03 / L
	# keep some roof between the glass at either end
	var min_roof := 0.1 if fam in ["sedan", "coupe", "muscle", "wagon"] else 0.05
	if g.rear in ["notch", "fast", "hatch"] and float(d.roof_f) - float(d.roof_r) < min_roof:
		var mid := (float(d.roof_f) + float(d.roof_r)) * 0.5
		d.roof_f = mid + min_roof * 0.5
		d.roof_r = mid - min_roof * 0.5
	_glass_and_doors(d, g, L, r)
	_details(d, f, fam, era, r)
	for k in icon:
		if k == "art": (d.art as Dictionary).merge(icon.art, true)
		elif not g.has(k) and k != "H": d[k] = icon[k]
	return d

## The side glass (the daylight opening), the pillars on it and the door shut lines.
static func _glass_and_doors(d: Dictionary, g: Dictionary, L: float, r: RandomNumberGenerator) -> void:
	var h: float = d.cab_top
	var cowl_x: float = d.cowl_x
	var cowl_h: float = d.cowl_h
	var roof_f: float = d.roof_f
	var a_w: float = d.a_w
	var rt: float = d.rt
	var belt_f: float = d.belt_f
	var glass_top := h - rt - float(d.crown) * 0.3
	# the windshield's line, and the A-pillar just behind it
	var ws_x := func(y: float) -> float:
		return cowl_x + (y - cowl_h) / maxf(0.001, h - cowl_h) * (roof_f - cowl_x)
	var a_bot: float = float(ws_x.call(belt_f)) - a_w
	var a_top: float = float(ws_x.call(glass_top)) - a_w * 0.7
	var dlo_rt := 0.0
	var dlo_r := 0.0
	match String(d.rear):
		"notch", "fast", "hatch":
			dlo_rt = float(d.roof_r) + float(g.c_top) / L
			dlo_r = float(d.roof_r) + float(g.c_bot) / L
		"pickup":
			dlo_rt = float(d.cab_x) + 0.1 / L
			dlo_r = dlo_rt
			if d.cab == "ute":
				dlo_rt = float(d.cab_x) + 0.42 / L
				dlo_r = float(d.cab_x) + 0.3 / L
		"boxtruck":
			dlo_rt = maxf(float(d.box_x), roof_f - 0.9 / L) + 0.08 / L
			dlo_r = dlo_rt
		"open":
			dlo_rt = roof_f - 0.12
			dlo_r = dlo_rt
		_:
			dlo_rt = float(d.roof_r) + float(g.d_w) / L
			dlo_r = dlo_rt + 0.04 / L
	dlo_r = clampf(dlo_r, 0.03, a_bot - 0.08)
	dlo_rt = clampf(dlo_rt, dlo_r - 0.08, a_top - 0.04)
	d.glass_top = glass_top
	d.a_bot = a_bot
	d.a_top = a_top
	d.dlo_r = dlo_r
	d.dlo_rt = dlo_rt
	# pillars standing on the glass: [x at the belt, x at the top, width]
	var pillars: Array = []
	var doors: Array = []                 # [front edge, rear edge] of each door
	var span := a_bot - dlo_r
	var lean := 0.012
	var door_f := cowl_x - 0.004
	var b_w := 0.075 / L
	var fam: String = d.family
	if d.rear == "pickup":
		var cab_x: float = d.cab_x
		if d.cab == "crew":
			var bx := cab_x + (a_bot - cab_x) * 0.47
			pillars.append([bx, bx + lean, b_w])
			doors.append([door_f, bx])
			doors.append([bx, cab_x + 0.04 / L])
		elif d.cab == "ext":
			var bx2 := cab_x + 0.55 / L
			pillars.append([bx2, bx2 + lean * 0.5, b_w * 1.4])
			doors.append([door_f, bx2])
		elif d.cab != "cabover":
			doors.append([door_f, cab_x + 0.06 / L])
		else:
			doors.append([door_f - 0.01, cab_x + 0.08 / L])
	elif d.rear == "boxtruck":
		doors.append([door_f, dlo_r])
	elif fam in ["van"]:
		var bx3 := a_bot - 0.95 / L
		doors.append([door_f, bx3])
		if d.art.has("cargo"):
			d.dlo_r = bx3 - 0.02 / L
			d.dlo_rt = bx3 + lean - 0.02 / L
		else:
			pillars.append([bx3, bx3 + lean, b_w])
			var n := maxi(1, int((bx3 - dlo_r) * L / 1.1))
			for k in range(1, n):
				var px := bx3 - (bx3 - dlo_r) * float(k) / float(n)
				pillars.append([px, px, b_w * 0.8])
		doors.append([bx3 - 0.02, bx3 - 1.0 / L])
	elif int(d.doors) == 4 or fam in ["minivan", "suv", "kei"] and int(d.doors) != 2:
		var bx4 := dlo_r + span * 0.52
		if L > 7.0:
			# a stretch: the front doors, a long middle with its own windows, the back doors
			bx4 = a_bot - 1.05 / L
			var n2 := int((bx4 - dlo_r) * L / 1.15)
			for k in range(1, n2):
				var px2 := bx4 - (bx4 - dlo_r) * float(k) / float(n2)
				pillars.append([px2, px2 + lean * 0.5, b_w])
		pillars.append([bx4, bx4 + lean, b_w])
		doors.append([door_f, bx4])
		var rear_door_end := dlo_r + 0.02
		if d.rear in ["box"]:
			var cx := dlo_r + span * 0.2
			pillars.append([cx, cx + lean * 0.5, b_w * 0.8])
			rear_door_end = cx
		elif r.randf() < 0.45:
			var cx2 := dlo_r + span * 0.12
			pillars.append([cx2, cx2 + lean * 0.3, b_w * 0.5])
			rear_door_end = cx2 + 0.01
		doors.append([bx4, rear_door_end])
		if d.art.has("hearse"):
			d.dlo_r = bx4 - 0.02 / L
			d.dlo_rt = bx4 + lean - 0.02 / L
			pillars.clear()
			doors.pop_back()
	else:
		# two doors: a long door, and a small fixed quarter window behind it on most
		var quarter: bool = g.quarter and d.rear != "open" and span * L > 1.3
		var bx5 := dlo_r + span * (0.26 if quarter else 0.0)
		if quarter: pillars.append([bx5, bx5 + lean * 1.4, b_w * 0.8])
		doors.append([door_f, maxf(bx5, dlo_r + 0.02) - (0.0 if quarter else -0.02)])
	d.pillars = pillars
	d.door_cuts = doors

## Lamps, bumpers, mirrors, handles, trim, wheels: the era, the class and the seed decide.
static func _details(d: Dictionary, f: Dictionary, fam: String, era: int, r: RandomNumberGenerator) -> void:
	var year: int = f.year
	var cls: String = f.cls
	var art: Dictionary = f.art
	var make: String = f.make
	var jdm := make in JDM_MAKES
	var us := make in US_MAKES
	var truck := fam in ["pickup", "boxtruck", "van"] or cls in ["work_truck", "hd_pickup"]
	var offroad := fam == "offroad"
	# --- headlamps as seen from the side
	var head := "swept"
	if year < 1958: head = "round"
	elif year < 1975: head = "quad" if (us and fam in ["sedan", "coupe", "wagon", "muscle"] and r.randf() < 0.6) else "round"
	elif year < 1986: head = "rect"
	elif year < 1996: head = "flush"
	elif year < 2006: head = "jewel"
	if String(art.get("lamps", "")) == "round": head = "round"
	if String(art.get("lamps", "")) == "quad": head = "quad"
	if offroad and year < 2010: head = "round"
	if art.has("popups"): head = "popup"
	d.head = head
	var tail := "swept"
	if art.has("fins"): tail = "fin"
	elif year < 1966: tail = "bar"
	elif year < 1982: tail = "block"
	elif year < 1996: tail = "wrap"
	if fam in ["sports", "mid", "wedge", "rear"] and r.randf() < 0.35: tail = "round"
	if truck or fam in ["suv", "offroad", "kei", "minivan"] or d.rear == "box": tail = "tall"
	d.tail_lamp = tail
	# --- bumpers
	var bumper := "body"
	if year < 1974 or (art.has("chrome") and year < 1980): bumper = "chrome"
	elif year < 1985: bumper = "chrome5" if us and cls in ["luxury", "sedan", "wagon", "classic"] else "rubber"
	elif year < 1994: bumper = "strip"
	if fam in ["pickup", "boxtruck"] and year < 2004: bumper = "chrome"
	if fam == "pickup" and d.cab == "ute": bumper = "chrome" if year < 1985 else bumper
	if cls == "work_truck" or offroad: bumper = "steel" if not (offroad and year >= 2005) else bumper
	if art.has("nochrome") and bumper == "chrome": bumper = "rubber"
	d.bumper = bumper
	# --- mirrors and handles
	var mirror := "body"
	if year < 1962: mirror = "chrome_small"
	elif year < 1980: mirror = "chrome"
	elif year < 1996: mirror = "black"
	if jdm and year < 1983: mirror = "fender"
	if truck or fam == "pickup" or (fam == "suv" and year < 1995): mirror = "truck" if year >= 1985 else "truck_chrome"
	d.mirror = mirror
	d.handle = "push" if year < 1966 else ("flap" if year < 1985 else ("flush" if year < 2000 else "pull"))
	d.frame = "chrome" if year < 1980 or (cls == "luxury" and year < 2005) else "black"
	d.pillar = "body" if year < 1984 else "black"
	d.hardtop = d.doors == 2 and year >= 1955 and year < 1979 and fam in ["coupe", "muscle"] and r.randf() < 0.55
	d.vent = year < 1969 and not fam in ["sports", "mid", "roadster", "bubble"] and r.randf() < 0.8
	# --- trim down the side
	var trim: Array = []
	if year < 1966 and not fam in ["pickup", "offroad", "bubble", "van", "boxtruck"]: trim.append("spear")
	if (cls in ["luxury", "classic"] and year < 1990) or (us and year < 1970 and r.randf() < 0.4): trim.append("rocker_chrome")
	if year >= 1975 and year < 2002 and not fam in ["sports", "mid", "wedge", "offroad", "boxtruck", "rear"] and r.randf() < 0.6: trim.append("moulding")
	if fam == "suv" and year >= 1990 and year < 2012: trim.append("cladding")
	if (cls == "crossover" and year >= 2008) or (fam == "suv" and year >= 2012 and r.randf() < 0.5): trim.append("arch_cladding")
	if us and year < 1972 and cls in ["luxury", "classic"]: trim.append("arch_chrome")
	if art.has("chrome") and year < 1980 and not trim.has("rocker_chrome"): trim.append("rocker_chrome")
	d.trim = trim
	d.crease = -1.0 if year < 1985 and r.randf() < 0.5 else r.randf_range(0.1, 0.28)
	d.antenna = "mast" if year >= 1965 and year < 2004 and r.randf() < 0.5 else ("fin" if year >= 2010 and r.randf() < 0.4 else "none")
	d.fuel = r.randf() < 0.75 and not fam in ["boxtruck"]
	d.badge = r.randi_range(0, 3)
	d.side_vent = "intake" if fam in ["mid", "wedge"] and f.pos != "front" else ("vent" if (cls in ["sports", "exotic", "luxury"] and year >= 2004 and r.randf() < 0.5) else "none")
	if art.has("portholes"): d.side_vent = "portholes"
	if art.has("strakes"): d.side_vent = "strakes"
	d.skirt = (us and cls in ["luxury", "classic"] and year >= 1955 and year < 1977 and fam in ["sedan", "coupe"] and r.randf() < 0.6)
	d.mudflaps = cls in ["rally", "work_truck"] or (fam == "pickup" and r.randf() < 0.3)
	d.step = (fam == "pickup" and year >= 1999 and r.randf() < 0.5) or (fam == "suv" and year >= 2002 and cls != "crossover" and r.randf() < 0.6)
	# --- arches
	var arch := "round"
	if (fam == "pickup" or fam == "suv") and year >= 1970 and year < 1995: arch = _pick(r, ["flat", "square"])
	if offroad: arch = "square" if year < 2005 else "flat"
	if fam == "kei" or fam == "boxtruck": arch = "flat"
	if year >= 1975 and year < 1990 and fam in ["sedan", "coupe", "hatch", "wagon"] and r.randf() < 0.3: arch = "flat"
	if cls == "rally" or art.has("dually") or (fam == "offroad" and year < 2000 and r.randf() < 0.3): d.flare = "box" if cls == "rally" else "bulge"
	else: d.flare = "none"
	d.arch = arch
	d.arch_gap = (0.045 if fam in ["pickup", "suv", "offroad", "boxtruck"] else (0.008 if fam in ["sports", "mid", "wedge"] or cls == "exotic" else 0.018)) / float(d.L)
	# --- wheels
	var rim := "fivespoke"
	var wall := "none"
	if year < 1960:
		rim = "hubcap"
		wall = "white"
	elif year < 1968:
		rim = _pick(r, ["hubcap", "dish"]) if not truck and not offroad else "steel"
		if cls in ["luxury", "classic", "sedan", "wagon", "coupe"] and r.randf() < 0.7: wall = "white"
		if cls in ["sports", "exotic"]: rim = "wire"
	elif year < 1980:
		if cls in ["muscle", "pony"]:
			rim = _pick(r, ["fivespoke", "dish", "steel"])
			wall = "letters"
		elif cls == "luxury" and us: rim = "wire"
		elif truck or offroad:
			rim = "steel"
			if offroad or r.randf() < 0.4: wall = "letters"
		elif cls in ["sports", "exotic"]: rim = _pick(r, ["wire", "fivespoke", "dish"]) if year < 1974 else "fivespoke"
		else: rim = _pick(r, ["hubcap", "steel", "dish"])
		if cls == "luxury" and us: wall = "white"
	elif year < 1990:
		if cls in ["jdm", "sports", "coupe", "hot_hatch", "rally", "exotic", "euro"]: rim = _pick(r, ["mesh", "tenspoke", "turbofan", "fivespoke"])
		elif cls == "luxury": rim = "wire" if us else "mesh"
		elif cls in ["muscle", "pony"]:
			rim = _pick(r, ["tenspoke", "turbofan", "fivespoke"])
			if r.randf() < 0.5: wall = "letters"
		elif truck or offroad:
			rim = _pick(r, ["steel", "tenspoke"])
			if r.randf() < 0.4: wall = "letters"
		else: rim = _pick(r, ["hubcap", "hubcap", "steel", "tenspoke"])
	elif year < 2000:
		rim = _pick(r, ["fivespoke", "multispoke", "tenspoke"])
		if cls in ["economy", "minivan", "van"]: rim = "hubcap"
		if truck or offroad: rim = _pick(r, ["steel", "tenspoke"])
	else:
		rim = _pick(r, ["fivespoke", "multispoke", "tenspoke"])
		if cls in ["economy"] and year < 2012: rim = "hubcap"
		if cls == "work_truck" or fam == "boxtruck": rim = "steel"
	d.rim_style = rim
	d.wall = wall
	# the stripes cue, the way that kind of car wore them
	d.stripe_kind = "racing"
	if cls in ["muscle", "pony"] and year < 1976: d.stripe_kind = _pick(r, ["hockey", "side", "tail"])
	elif fam in ["van"]: d.stripe_kind = "rainbow"
	elif cls in ["economy", "compact", "hatch", "oddball"]: d.stripe_kind = "side"

# ================================================================== the outline

## The body's outline as fractions: [x, y, corner radius], round from the rear bumper's
## bottom, up over the roof and down the nose.
static func profile(d: Dictionary) -> Array:
	var s := float(d.soft)
	var h: float = d.h
	var pts: Array = []
	var rear: String = d.rear
	var tail_bot: float = d.tail_bot
	var crown: float = d.crown
	pts.append([0.012, tail_bot, 0.003])
	if rear == "pickup":
		var bed_h: float = d.bed_h
		pts.append([0.0, tail_bot + 0.02, 0.003])
		pts.append([0.0, bed_h, 0.004])
		var cab_x: float = d.cab_x
		if d.cab == "ute":
			pts.append([cab_x - 0.02, bed_h, 0.004 * s])
			pts.append([float(d.roof_r), h - crown * 0.4, 0.02 * s + 0.004])
		else:
			pts.append([cab_x - 0.006, bed_h, 0.0])
			pts.append([cab_x - 0.006, bed_h + 0.008, 0.0])
			pts.append([cab_x, bed_h + 0.008, 0.0])
			pts.append([cab_x, h - 0.01, 0.012 * s + 0.002])
	elif rear == "boxtruck":
		pts.append([0.0, tail_bot + 0.02, 0.0])
		pts.append([0.0, h, 0.004])
		var bx: float = d.box_x
		if bx < 0.99:
			pts.append([bx - 0.006, h, 0.004])
			pts.append([bx - 0.006, float(d.cab_top) - 0.02, 0.0])
			pts.append([bx, float(d.cab_top) - 0.02, 0.0])
			pts.append([bx + 0.01, float(d.cab_top), 0.01 * s])
	else:
		pts.append([0.0, d.tail_mid, 0.012 * s + 0.004])
		match rear:
			"notch":
				if float(d.fin) > 0.0:
					pts.append([float(d.tail_x), float(d.tail_h) + float(d.fin), 0.002])
					pts.append([float(d.deck_x) * 0.5 + 0.08, float(d.tail_h) + float(d.fin) * 0.3, 0.06])
				else:
					pts.append([float(d.tail_x), float(d.tail_h), 0.01 * s + 0.003])
				pts.append([float(d.deck_x), float(d.deck_h), 0.02 * s + 0.004])
				pts.append([float(d.roof_r), h - crown * 0.5, 0.03 * s + 0.006])
			"fast":
				pts.append([float(d.tail_x), float(d.tail_h), 0.012 * s + 0.003])
				pts.append([float(d.roof_r), h - crown * 0.5, 0.06 * s + 0.01])
			"hatch":
				pts.append([float(d.tail_x), float(d.tail_h), 0.008 * s + 0.003])
				pts.append([float(d.roof_r), h - crown * 0.5, 0.03 * s + 0.006])
			"open":
				pts.append([float(d.tail_x), float(d.tail_h), 0.015 * s + 0.003])
				pts.append([float(d.dlo_r) - 0.03, float(d.belt_r) + 0.006, 0.02])
				pts.append([float(d.dlo_r), float(d.belt_r), 0.006])
				pts.append([float(d.a_bot), float(d.belt_f), 0.006])
			_:
				pts.append([float(d.roof_r) * 0.6, h - 0.012, 0.012 * s + 0.004])
	if rear != "open":
		# the roof: a gentle crown, highest a little ahead of the middle
		var rf: float = d.roof_f
		var rr: float = d.roof_r
		if rear in ["box", "pickup", "boxtruck"] and rear != "fast":
			rr = maxf(rr, float(pts[pts.size() - 1][0]))
		var top: float = d.cab_top
		if rear == "box" and h > top + 0.01:
			# a high-roof van: the roof steps up behind the windshield
			pts.append([rf - 0.06, h, 0.03])
			pts.append([rf - 0.01, top + 0.004, 0.02])
		else:
			pts.append([rr + (rf - rr) * 0.55, top, (rf - rr) * 0.45 if crown > 0.004 else 0.0])
		pts.append([rf, top - crown, 0.02 * s + 0.004])
	pts.append([float(d.cowl_x), float(d.cowl_h), 0.012 * s + 0.002])
	var nose_lean: float = d.nose_lean
	pts.append([float(d.nose_x) - nose_lean * 0.5, float(d.hood_h), 0.014 * s + 0.002])
	pts.append([1.0, float(d.nose_mid), 0.014 * s + 0.002])
	pts.append([1.0 - 0.012 - nose_lean, float(d.nose_bot), 0.003])
	pts.append([float(d.wf), float(d.nose_bot), 0.0])
	pts.append([float(d.wf), float(d.clear), 0.0])
	pts.append([float(d.wr), float(d.clear), 0.0])
	pts.append([float(d.wr), tail_bot, 0.0])
	return pts

## The side glass as fractions, same shape as profile().
static func glass_shape(d: Dictionary) -> Array:
	var top: float = d.glass_top
	var r := 0.01 * float(d.soft) + 0.002
	var pts: Array = []
	pts.append([float(d.dlo_r), float(d.belt_r), 0.002])
	pts.append([float(d.dlo_rt), top, r])
	if d.rear != "open":
		var rf: float = d.a_top
		var rr: float = d.dlo_rt
		pts.append([rr + (rf - rr) * 0.55, top + float(d.crown) * 0.5, (rf - rr) * 0.4])
	pts.append([float(d.a_top), top - (0.0 if d.rear != "open" else 0.0), r * 0.6])
	pts.append([float(d.a_bot), float(d.belt_f), 0.002])
	return pts

# ================================================================== painting

## A car as its own image: rear bumper at x=22, tyres on the ground 8px above the bottom (and
## `below` px more under that for callers that tilt it). Width len + 44.
static func render(len: int, d: Dictionary, paint: Color, mods := {}, dmg := {}, below := 0) -> Image:
	var c := _Car.new(len, d, paint, mods, dmg, below)
	c.run()
	return c.p.img

## Where a design's wheels sit on an image from render(): [[x, r], ...] rear then front, x from
## the image's left edge, r the tyre radius (the wheel's centre is r above the ground).
static func wheel_spots(len: int, d: Dictionary, mods := {}) -> Array:
	var r := _tire_px(len, d, mods)
	return [[22.0 + float(d.wr) * len, r], [22.0 + float(d.wf) * len, r]]

static func _tire_px(len: int, d: Dictionary, mods: Dictionary) -> float:
	var r := float(d.tire_r) * len
	var drop := float(mods.get("drop", 0.0))
	var kind := _tire_kind(mods)
	if kind == "mud": r *= 1.18
	if _donk(mods): r *= 1.3 + clampf(-drop - 0.45, 0.0, 0.5) * 0.6
	return r

## The rim and the wheel() mods a design's wheels are painted with, so a caller can paint the
## same wheel again (the loading screen spins them).
static func wheel_look(d: Dictionary, mods: Dictionary, len: int) -> Array:
	var rim := String(mods.get("rim", ""))
	if rim == "": rim = String(d.rim_style)
	var kind := _tire_kind(mods)
	var wm := mods.duplicate()
	wm.tire_kind = kind
	if not mods.has("rim_size"): wm.rim_size = float(d.rim) if kind != "lowpro" else maxf(float(d.rim), 0.74)
	if not mods.has("rim_color") and d.has("rim_color") and String(mods.get("rim", "")) == "": wm.rim_color = Color(String(d.rim_color))
	if not wm.has("wall"): wm.wall = d.wall if String(mods.get("rim", "")) == "" or kind == "stock" else "none"
	if kind == "mud" and d.wall == "letters": wm.wall = "letters"
	var year := int(mods.get("year", d.year))
	wm.lugs = 6 if d.family in ["pickup", "suv", "offroad", "van"] else (4 if year < 1985 and d.cls in ["economy", "kei"] else 5)
	if d.family == "boxtruck": wm.lugs = 8
	if len < 60: wm.simple = true
	return [rim, wm]

static func _donk(mods: Dictionary) -> bool:
	return float(mods.get("drop", 0.0)) < -0.3 and float(mods.get("rim_size", 0.0)) >= 0.8

static func _tire_kind(mods: Dictionary) -> String:
	var drop := float(mods.get("drop", 0.0))
	if mods.has("tire"): return String(mods.tire)
	if _donk(mods): return "lowpro"
	return "mud" if drop < -0.3 else ("lowpro" if drop > 0.7 else "stock")

static func _col(v: Variant, fallback: Color) -> Color:
	if v is Color: return v
	if v is String and String(v) != "": return Color(String(v))
	return fallback

## Seven paint values, deep shadow to specular, for a finish. Shadows go cooler and richer,
## highlights warmer and paler: a pixel-art ramp, not a plain darken/lighten.
static func ramp(paint: Color, finish: String) -> Dictionary:
	var cool := Color(0.05, 0.06, 0.13)
	var warm := Color(1.0, 0.98, 0.9)
	var k: Array = [0.62, 0.4, 0.2, 0.0, 0.16, 0.36, 0.72]
	match finish:
		"matte": k = [0.45, 0.26, 0.11, 0.0, 0.05, 0.11, 0.16]
		"metallic": k = [0.6, 0.38, 0.18, 0.0, 0.2, 0.42, 0.8]
	var out := {
		"deep": paint.lerp(cool, k[0]), "sh": paint.lerp(cool, k[1]), "mid": paint.lerp(cool, k[2]), "base": paint,
		"lt": paint.lerp(warm, k[4]), "hi": paint.lerp(warm, k[5]), "spec": paint.lerp(warm, k[6]),
	}
	if finish == "pearl":
		var shift := Color.from_hsv(fposmod(paint.h + 0.14, 1.0), 0.35, 1.0)
		out.lt = (out.lt as Color).lerp(shift, 0.25)
		out.hi = (out.hi as Color).lerp(shift, 0.45)
		out.spec = (out.spec as Color).lerp(Color.WHITE, 0.4)
		out.sh = (out.sh as Color).lerp(Color.from_hsv(fposmod(paint.h - 0.08, 1.0), 0.6, 0.3), 0.25)
	if finish == "chrome":
		var tint := paint.lerp(Color(0.75, 0.78, 0.82), 0.7)
		out = { "deep": Color("2a2622").lerp(tint, 0.1), "sh": Color("5a524a").lerp(tint, 0.15), "mid": Color("8a8a8c").lerp(tint, 0.3),
			"base": Color("c4ccd6").lerp(tint, 0.3), "lt": Color("dfe8f2").lerp(tint, 0.2), "hi": Color("f4f8fc"), "spec": Color.WHITE }
	return out

## One car being painted. Holds the canvas, the masks and where everything landed.
class _Car:
	var p: Pix
	var w: int
	var hgt: int
	var ox := 22
	var gy: int
	var len: int
	var lf: float
	var d: Dictionary
	var mods: Dictionary
	var dmg: Dictionary
	var buf := PackedInt32Array()
	var bm := PackedByteArray()          # 1 = body
	var gm := PackedByteArray()          # 1 = side glass
	var lift := 0.0
	var u := 1
	var lod := 2
	var pal := {}
	var finish := "gloss"
	var front := 0.0
	var rear := 0.0
	var roof := 0.0
	var r_stock := 0.0
	var r_tire := 0.0
	var arch_r := 0.0
	var wheels: Array = []               # [side, centre x, centre y, arch centre]
	var shape := PackedVector2Array()
	var glass := PackedVector2Array()
	var top_y := PackedInt32Array()      # first body row in each column (-1 none)
	var bot_y := PackedInt32Array()
	var x_lo := 0
	var x_hi := 0
	var y_lo := 0
	var y_hi := 0
	var sill := 0.0
	var paint_c: Color
	var year := 2000

	func _init(length: int, design: Dictionary, paint: Color, the_mods: Dictionary, the_dmg: Dictionary, below: int) -> void:
		len = maxi(16, length)
		lf = float(len)
		d = design
		mods = the_mods
		dmg = the_dmg
		w = len + 44
		hgt = maxi(int(lf * 0.75), int(lf * (float(d.h) * 1.3 + 0.08))) + 30 + below
		gy = hgt - 8 - below
		paint_c = paint
		finish = String(mods.get("finish", "gloss"))
		pal = CarGen.ramp(paint, finish)
		front = clampf(float(dmg.get("front", 0.0)), 0.0, 1.0)
		rear = clampf(float(dmg.get("rear", 0.0)), 0.0, 1.0)
		roof = clampf(float(dmg.get("roof", 0.0)), 0.0, 1.0)
		u = maxi(1, int(round(lf / 120.0)))
		lod = 0 if len < 60 else (1 if len < 130 else 2)
		year = int(mods.get("year", d.year))
		buf.resize(w * hgt)
		bm.resize(w * hgt)
		gm.resize(w * hgt)
		top_y.resize(w)
		bot_y.resize(w)

	func X(fx: float) -> float:
		return float(ox) + fx * lf

	func Y(fy: float) -> float:
		return float(gy) - fy * lf - lift

	func body_at(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < hgt and bm[y * w + x] != 0

	func glass_at(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < hgt and gm[y * w + x] != 0

	## Crash damage moves the outline: the crushed end comes back and buckles, a rolled roof sits low.
	func warp(fx: float, fy: float) -> Vector2:
		var belt: float = d.belt_f
		if front > 0.0 and fx > 0.68:
			var k := (fx - 0.68) / 0.32
			fx -= front * 0.2 * k
			if fy > float(d.clear) and fy < belt + 0.03: fy += front * 0.04 * k * (0.6 + 0.4 * sin(fx * 90.0))
		if rear > 0.0 and fx < 0.3:
			var k2 := (0.3 - fx) / 0.3
			fx += rear * 0.16 * k2
			if fy > float(d.clear) and fy < belt + 0.03: fy += rear * 0.035 * k2 * (0.6 + 0.4 * sin(fx * 80.0))
		if roof > 0.0 and fy > belt + 0.01:
			fy -= roof * 0.08 * clampf((fy - belt) / maxf(0.01, float(d.h) - belt), 0.0, 1.0)
		return Vector2(X(fx), Y(fy))

	## Fractions with corner radii -> a pixel polygon, each corner rounded with a curve.
	func poly(pts: Array) -> PackedVector2Array:
		var raw: Array = []
		for q: Array in pts:
			raw.append([warp(float(q[0]), float(q[1])), float(q[2]) * lf])
		var out := PackedVector2Array()
		var n := raw.size()
		for i in n:
			var pt: Vector2 = raw[i][0]
			var rad: float = raw[i][1]
			var a: Vector2 = raw[(i - 1 + n) % n][0]
			var b: Vector2 = raw[(i + 1) % n][0]
			var la := pt.distance_to(a)
			var lb := pt.distance_to(b)
			var rr := minf(rad, minf(la, lb) * 0.5)
			if rr < 0.75:
				out.append(pt)
				continue
			var p1 := pt + (a - pt) / la * rr
			var p2 := pt + (b - pt) / lb * rr
			var steps := clampi(int(rr / 1.5), 2, 14)
			for s in steps + 1:
				var t := float(s) / float(steps)
				out.append(p1.lerp(pt, t).lerp(pt.lerp(p2, t), t))
		return out

	## Even-odd scanline fill of a pixel polygon into a mask.
	func fill(mask: PackedByteArray, pts: PackedVector2Array, v: int) -> void:
		if pts.size() < 3: return
		var y0 := hgt
		var y1 := 0
		for q in pts:
			y0 = mini(y0, int(floor(q.y)))
			y1 = maxi(y1, int(ceil(q.y)))
		y0 = maxi(0, y0)
		y1 = mini(hgt - 1, y1)
		var n := pts.size()
		for yy in range(y0, y1 + 1):
			var fy := float(yy) + 0.5
			var xs: Array[float] = []
			for i in n:
				var a := pts[i]
				var b := pts[(i + 1) % n]
				if (a.y <= fy and b.y > fy) or (b.y <= fy and a.y > fy):
					xs.append(a.x + (fy - a.y) / (b.y - a.y) * (b.x - a.x))
			xs.sort()
			var k := 0
			var row := yy * w
			while k + 1 < xs.size():
				var xa := maxi(0, int(round(xs[k])))
				var xb := mini(w, int(round(xs[k + 1])))
				for xx in range(xa, xb): mask[row + xx] = v
				k += 2

	func run() -> void:
		_stance()
		var art: Dictionary = d.art
		if mods.get("shadow", true): _shadow()
		shape = poly(CarGen.profile(d))
		fill(bm, shape, 1)
		if d.rear != "open":
			glass = poly(CarGen.glass_shape(d))
			fill(gm, glass, 1)
			for i in gm.size():
				if gm[i] != 0 and bm[i] == 0: gm[i] = 0
		_carve()
		_columns()
		_shade_body()
		_shade_glass()
		# from here on, plain pixel drawing on the image
		var img := Image.create_from_data(w, hgt, false, Image.FORMAT_RGBA8, buf.to_byte_array())
		p = Pix.new(1, 1)
		p.img = img
		p.w = w
		p.h = hgt
		_two_tone()
		_wood()
		_livery()
		_glints()
		_rust()
		_panels()
		_trim()
		_side_bits()
		_lamps()
		_glass_frame()
		_cabin_open()
		_outline()
		_fenders()
		_bumpers()
		_mirror()
		_roof_things()
		_aero()
		_truck_things()
		_kit()
		_wells()
		_flares()
		_wheels()
		_damage_fx()
		if art.has("beacon") or art.has("topper") or art.has("spotlight"): _roof_lights()

	# ------------------------------------------------------------ stance and wheels

	func _stance() -> void:
		var drop := float(mods.get("drop", 0.0))
		r_stock = float(d.tire_r) * lf
		r_tire = CarGen._tire_px(len, d, mods)
		lift = -drop * lf * 0.036 + (r_tire - r_stock) * 0.9
		arch_r = r_stock * 1.1 + float(d.arch_gap) * lf + 0.5
		wheels.clear()
		for side in ["rear", "front"]:
			var wf: float = d.wr if side == "rear" else d.wf
			if side == "front": wf -= front * 0.12
			else: wf += rear * 0.08
			var wx := X(wf)
			wheels.append([side, wx, float(gy) - r_tire, Vector2(wx, float(gy) - r_stock - lift)])
		sill = Y(float(d.clear))

	## A soft dithered shadow on the ground, see-through so it darkens whatever is under the car.
	func _shadow() -> void:
		var cx := X(0.5)
		var rx := lf * 0.54
		var ry := maxf(2.0, lf * 0.03)
		var inner := Color(0.0, 0.0, 0.02, 0.45).to_abgr32()
		var outer := Color(0.0, 0.0, 0.02, 0.25).to_abgr32()
		for yy in range(maxi(0, int(gy - ry)), mini(hgt, int(gy + ry) + 1)):
			var fy := (float(yy) - float(gy) - 0.5) / ry
			var qy := fy * fy
			if qy > 1.0: continue
			var half := rx * sqrt(1.0 - qy)
			var half_in := rx * sqrt(maxf(0.0, 0.55 - qy))
			for xx in range(maxi(0, int(cx - half)), mini(w, int(cx + half) + 1)):
				buf[yy * w + xx] = inner if absf(float(xx) - cx) < half_in else outer

	func in_arch(dx: float, dy: float, ra: float) -> bool:
		if dy >= 0.0: return absf(dx) < ra
		match String(d.arch):
			"flat":
				return dx * dx + dy * dy < ra * ra * 1.02 and -dy < ra * 0.8
			"square":
				var rx := ra * 1.02
				var top := ra * 0.9
				if absf(dx) >= rx or -dy >= top: return false
				var rc := ra * 0.42
				var cx := rx - rc
				var cy := top - rc
				if absf(dx) > cx and -dy > cy: return pow(absf(dx) - cx, 2.0) + pow(-dy - cy, 2.0) < rc * rc
				return true
		return dx * dx + dy * dy < ra * ra

	## Cut the wheel openings out of the body so the outline follows the arch.
	func _carve() -> void:
		for wv: Array in wheels:
			var ac: Vector2 = wv[3]
			var ra := arch_r * (1.06 if wv[0] == "rear" and d.art.has("dually") else 1.0)
			var from := int(ac.y - ra) - 2
			if skirted(wv): from = int(sill) + 1
			for yy in range(maxi(0, from), hgt):
				var row := yy * w
				for xx in range(maxi(0, int(ac.x - ra * 1.1) - 2), mini(w, int(ac.x + ra * 1.1) + 3)):
					if bm[row + xx] != 0 and in_arch(float(xx) + 0.5 - ac.x, float(yy) + 0.5 - ac.y, ra):
						bm[row + xx] = 0
						gm[row + xx] = 0

	func skirted(wv: Array) -> bool:
		return d.skirt and wv[0] == "rear" and not mods.has("rim") and String(dmg.get("flat", "")) != "rear" and String(dmg.get("wheel_off", "")) != "rear"

	func _columns() -> void:
		x_lo = w
		x_hi = 0
		var y0 := hgt
		var y1 := 0
		for q in shape:
			y0 = mini(y0, int(q.y) - 1)
			y1 = maxi(y1, int(q.y) + 1)
		y0 = clampi(y0, 0, hgt - 1)
		y1 = clampi(y1, 0, hgt - 1)
		y_lo = hgt
		y_hi = 0
		for xx in w:
			top_y[xx] = -1
			bot_y[xx] = -1
			var i := y0 * w + xx
			for yy in range(y0, y1 + 1):
				if bm[i] != 0:
					if top_y[xx] < 0: top_y[xx] = yy
					bot_y[xx] = yy
				i += w
			if top_y[xx] >= 0:
				x_lo = mini(x_lo, xx)
				x_hi = maxi(x_hi, xx)
				y_lo = mini(y_lo, top_y[xx])
				y_hi = maxi(y_hi, bot_y[xx])

	## Where the side of the car turns into the tops: the beltline, carried forward along the
	## fender to the lamps and back along the quarter to the tail.
	func shoulder(fx: float) -> float:
		var dlo_r: float = d.dlo_r
		var a_bot: float = d.a_bot
		var belt_r: float = d.belt_r
		var belt_f: float = d.belt_f
		var y := belt_f
		if d.rear == "pickup" and fx < float(d.cab_x): y = float(d.bed_h) - 0.004
		elif fx < dlo_r: y = lerpf(float(d.tail_h) - 0.006, belt_r, clampf(fx / maxf(0.01, dlo_r), 0.0, 1.0))
		elif fx < a_bot: y = lerpf(belt_r, belt_f, (fx - dlo_r) / maxf(0.01, a_bot - dlo_r))
		else: y = lerpf(belt_f, float(d.hood_h) - 0.01, clampf((fx - a_bot) / maxf(0.01, float(d.nose_x) - a_bot), 0.0, 1.0))
		if d.rear == "boxtruck" and fx < float(d.box_x): y = float(d.h) - 0.03
		return y

	## Paint every body pixel by where it sits. Tops catch the sky; down the side: a bright
	## shoulder, the sky, the horizon line, the darker ground, and the rocker turning under.
	func _shade_body() -> void:
		var c_deep: int = (pal.deep as Color).to_abgr32()
		var c_sh: int = (pal.sh as Color).to_abgr32()
		var c_mid: int = (pal.mid as Color).to_abgr32()
		var c_base: int = (pal.base as Color).to_abgr32()
		var c_sky: int = (pal.base as Color).lerp(pal.lt, 0.6).to_abgr32()
		var c_lt: int = (pal.lt as Color).to_abgr32()
		var c_hi: int = (pal.hi as Color).to_abgr32()
		var c_gnd: int = (pal.mid as Color).lerp(pal.sh, 0.15).to_abgr32()
		var c_bounce: int = (pal.mid as Color).to_abgr32()
		var matte := finish == "matte"
		var chrome := finish == "chrome"
		var flake := finish in ["metallic", "pearl"]
		var c_flk: int = (pal.lt as Color).to_abgr32()
		var c_flk2: int = (pal.mid as Color).to_abgr32()
		if chrome:
			c_sky = Color("dce6f0").to_abgr32()
			c_base = Color("aab6c4").to_abgr32()
			c_gnd = Color("5e5248").to_abgr32()
			c_bounce = Color("8c8072").to_abgr32()
		var end_k := maxf(2.0, lf * 0.016)
		for xx in range(maxi(0, x_lo), mini(w, x_hi + 1)):
			var t0 := top_y[xx]
			if t0 < 0: continue
			var fx := (float(xx) - float(ox)) / lf
			var sh_y := Y(shoulder(fx))
			var span := maxf(3.0, sill - sh_y)
			for yy in range(t0, bot_y[xx] + 1):
				var i := yy * w + xx
				if bm[i] == 0 or gm[i] != 0: continue
				var c := c_base
				var from_top := yy - t0
				var bay := float(BAYER_K[(yy & 3) * 4 + (xx & 3)])
				if float(yy) < sh_y - 0.5:
					# hood, roof, deck and pillars: lit from above
					c = c_hi if from_top == 0 else (c_lt if from_top <= u else c_sky)
				else:
					var t := (float(yy) - sh_y) / span
					var td := t + (bay - 0.5) * 0.04
					if chrome:
						if td < 0.06: c = c_hi
						elif td < 0.4: c = c_sky
						elif td < 0.46: c = c_base
						elif td < 0.5: c = c_deep
						elif td < 0.8: c = c_gnd
						elif td < 0.9: c = c_bounce
						else: c = c_sh
					elif matte:
						if td < 0.05: c = c_lt
						elif td < 0.5: c = c_base
						elif td < 0.85: c = c_mid
						else: c = c_sh
					else:
						if td < 0.045: c = c_hi
						elif td < 0.12: c = c_lt
						elif td < 0.4: c = c_sky
						elif td < 0.44: c = c_base
						elif td < 0.46 + 0.02 / span * float(u): c = c_sh
						elif td < 0.74: c = c_gnd
						elif td < 0.88: c = c_sh
						else: c = c_deep
					if from_top == 0: c = c_hi
					# the ends of the car turn away from us
					var dl := float(xx - x_lo)
					var dr := float(x_hi - xx)
					if (dl < end_k or dr < end_k) and t > 0.08:
						c = c_mid if c == c_sky or c == c_base else (c_sh if c == c_gnd or c == c_mid else c)
					if flake and t > 0.1 and ((xx * 73 + yy * 151) % 23 == 0):
						c = c_flk if t < 0.45 else c_flk2
				buf[i] = c

	const BAYER_K: Array[float] = [0.0, 0.53, 0.13, 0.67, 0.8, 0.27, 0.93, 0.4, 0.2, 0.73, 0.07, 0.6, 1.0, 0.47, 0.87, 0.33]

	## Blue glass: pale at the top, deep at the bottom, the seats and headrests dark behind it, two
	## streaks of reflection across it. Tint darkens it and hides the cabin.
	func _shade_glass() -> void:
		if glass.is_empty(): return
		var tint := clampf(float(mods.get("tint", 0.0)), 0.0, 1.0)
		var gx0 := int(X(float(d.dlo_r)))
		var gx1 := int(X(float(d.a_bot)))
		var cols := [GLASS_TOP_C.darkened(tint * 0.55), GLASS_C.darkened(tint * 0.55), GLASS_LO_C.darkened(tint * 0.6)]
		var cab := GLASS_C.darkened(0.42 + tint * 0.3).lerp(CarGen.CABIN, 0.25)
		var streak := GLASS_TOP_C.lightened(0.12).darkened(tint * 0.4)
		var belt := Y(float(d.belt_f))
		var gt := Y(float(d.glass_top))
		var seats := _seats()
		for xx in range(maxi(0, int(X(float(d.dlo_r))) - 2), mini(w, int(X(float(d.a_bot))) + 4)):
			var top := -1
			var bot := -1
			for yy in range(maxi(0, int(gt) - 4), mini(hgt, int(belt) + 6)):
				if gm[yy * w + xx] != 0:
					if top < 0: top = yy
					bot = yy
			if top < 0: continue
			for yy in range(top, bot + 1):
				var i := yy * w + xx
				if gm[i] == 0: continue
				var f := float(yy - top) / maxf(1.0, float(bot - top))
				var c: Color = cols[0] if f < 0.16 else (cols[1] if f < 0.72 else cols[2])
				if tint < 0.9 and _in_seat(seats, xx, yy): c = cab
				var s := (float(xx - gx0) / maxf(1.0, float(gx1 - gx0))) + f * 0.14
				if tint < 0.95 and ((s > 0.3 and s < 0.33) or (s > 0.37 and s < 0.45)) and f < 0.92: c = streak
				buf[i] = c.to_abgr32()

	const GLASS_TOP_C := Color("7b9cc0")
	const GLASS_C := Color("33547a")
	const GLASS_LO_C := Color("1f3550")

	## Seat backs and headrests behind the glass, and the wheel up front: [x0, x1, top, kind].
	func _seats() -> Array:
		var out: Array = []
		if lod == 0: return out
		var belt := Y(float(d.belt_f))
		var ab := X(float(d.a_bot))
		var seat_w := lf * 0.07
		var head_h := lf * 0.055
		var back_h := lf * 0.035
		var pil: Array = d.pillars
		var front_seat := X(float(d.dlo_r)) + seat_w * 0.6
		if pil.size() > 0: front_seat = X(float(pil[0][0])) + lf * 0.015
		else: front_seat = lerpf(X(float(d.dlo_r)), ab, 0.25)
		out.append([front_seat, front_seat + seat_w * 0.45, belt - back_h - head_h, belt - back_h])
		if int(d.doors) == 4 or d.family in ["suv", "wagon", "minivan", "van"]:
			var rs := X(float(d.dlo_r)) + lf * 0.03
			out.append([rs, rs + seat_w * 0.45, belt - back_h - head_h * 0.8, belt - back_h])
		# the steering wheel's rim
		out.append([ab - lf * 0.075, ab - lf * 0.06, belt - lf * 0.05, belt - lf * 0.005])
		return out

	func _in_seat(seats: Array, xx: int, yy: int) -> bool:
		for s: Array in seats:
			var x0: float = s[0]
			var x1: float = s[1]
			var top: float = s[2]
			var back: float = s[3]
			var fx := float(xx)
			var fy := float(yy)
			if fx >= x0 and fx <= x1 and fy >= top and fy <= back:
				# rounded headrest top
				if fy < top + 2.0 and (fx < x0 + 1.0 or fx > x1 - 1.0): continue
				return true
			# the seat back below the headrest, wider
			if fx >= x0 - lf * 0.012 and fx <= x1 + lf * 0.004 and fy > back and fy < back + lf * 0.06: return true
		return false

	# ------------------------------------------------------------ paint jobs

	## Two-tone: the roof and pillars in the second colour (white, unless the car says otherwise).
	func _two_tone() -> void:
		if not d.art.has("twotone"): return
		var second := Color("ece6d6") if paint_c.get_luminance() < 0.7 else Color("7a1a1a")
		var pr := CarGen.ramp(second, "gloss")
		var gt := Y(float(d.glass_top)) - 1.0
		var belt := Y(float(d.belt_r))
		for xx in range(x_lo, x_hi + 1):
			for yy in range(maxi(0, top_y[xx]), int(belt)):
				if not body_at(xx, yy) or glass_at(xx, yy): continue
				var fx := (float(xx) - float(ox)) / lf
				if fx < float(d.dlo_r) - 0.04 or fx > float(d.a_bot) + 0.02: continue
				var c: Color = pr.base
				if yy == top_y[xx]: c = pr.hi
				elif float(yy) < gt: c = pr.lt
				p.img.set_pixel(xx, yy, c)

	## Wood-grain sides: vinyl planks framed in pale trim, from the tail to the front fender.
	func _wood() -> void:
		if not d.art.has("wood") or lod == 0: return
		var belt := Y(float(d.belt_r))
		var rock := Y(float(d.rocker))
		var top := int(belt + (rock - belt) * 0.12)
		var bot := int(rock - (rock - belt) * 0.1)
		var x0 := int(X(0.02 + rear * 0.16))
		var x1 := int(float(wheels[1][1]) + arch_r * 0.2)
		var wood := Color("8a5630")
		var frame := Color("dccca4")
		for xx in range(x0, x1):
			for yy in range(top, bot):
				if not on_paint(xx, yy): continue
				var c := wood
				var g := int(float(yy) * 1.7 + sin(float(xx) * 0.13 + float(yy) * 0.5) * 2.2) % 4
				if g == 0: c = wood.darkened(0.22)
				elif g == 2: c = wood.lightened(0.08)
				if yy <= top + u - 1 or yy >= bot - u or xx < x0 + u or xx >= x1 - u: c = frame
				elif _near_arch(xx, yy, float(u) + 1.0): c = frame
				p.img.set_pixel(xx, yy, c)

	## Specular glints where the tops curve over: the roof's corners, the hood's leading edge, the deck.
	func _glints() -> void:
		if finish == "matte" or lod == 0: return
		var spec := (pal.spec as Color)
		var anchors: Array = [float(d.nose_x) - 0.05, float(d.wf) - 0.02]
		if d.rear != "open": anchors.append_array([float(d.roof_f) - 0.03, float(d.roof_r) + 0.04])
		if d.rear in ["notch", "fast", "hatch"]: anchors.append(float(d.tail_x) + 0.035)
		for fx: float in anchors:
			var xx := int(X(fx))
			for k in range(-2 * u, 2 * u + 1):
				var t := _first_body(xx + k)
				if on_paint(xx + k, t): p.img.set_pixel(xx + k, t, spec if absi(k) <= u else (pal.hi as Color))
			var t2 := _first_body(xx)
			if on_paint(xx, t2 + 1): p.img.set_pixel(xx, t2 + 1, (pal.hi as Color))

	func _livery() -> void:
		var stripes := String(mods.get("stripes", "none"))
		if stripes == "none" and d.art.has("stripes") and not mods.has("stripes"): stripes = String(d.stripe_kind)
		var livery := String(mods.get("livery", "none"))
		var sc: Color = CarGen._col(mods.get("stripe_color", null), Color("f0f0ec") if paint_c.get_luminance() < 0.6 else Color("1e1e24"))
		if stripes == "none" and livery == "none": return
		var scd := sc.darkened(0.25)
		for xx in range(x_lo, x_hi + 1):
			var fx := (float(xx) - float(ox)) / lf
			var sh_y := Y(shoulder(fx))
			var span := maxf(3.0, sill - sh_y)
			for yy in range(maxi(0, top_y[xx]), bot_y[xx] + 1):
				var mi := yy * w + xx
				if bm[mi] == 0 or gm[mi] != 0: continue
				var s2 := (float(yy) - sh_y) / span
				var on := false
				var c := sc
				match stripes:
					"racing":
						# down the middle of the tops, and a pair along the side
						on = (yy - top_y[xx] <= u and float(yy) < sh_y) or (s2 > 0.16 and s2 < 0.26) or (s2 > 0.3 and s2 < 0.35)
					"side": on = s2 > 0.58 and s2 < 0.68
					"rally": on = s2 > 0.2 and s2 < 0.55 and fx > 0.42 and fx < 0.6
					"hockey": on = (s2 > 0.1 and s2 < 0.2 and fx > 0.24 and fx < 0.9) or (s2 > 0.1 and s2 < 0.5 and fx > 0.24 and fx < 0.27)
					"tail": on = (fx > 0.045 and fx < 0.06 or fx > 0.07 and fx < 0.085) and s2 < 0.62
					"rainbow":
						var kick := clampf((0.35 - fx) * 1.5, 0.0, 0.35)
						var b := s2 + kick
						if b > 0.3 and b < 0.36:
							on = true
							c = Color("e8a020")
						elif b > 0.36 and b < 0.42:
							on = true
							c = Color("c8501e")
						elif b > 0.42 and b < 0.48:
							on = true
							c = Color("7a3a1a")
				if livery == "slash" and s2 > 0.0:
					var dd := fx + s2 * 0.18
					if dd > 0.18 and dd < 0.26: on = true
					elif dd > 0.28 and dd < 0.31:
						on = true
						c = Color("8a8e96")
					elif dd > 0.4 and dd < 0.5 and s2 > 0.3:
						on = true
						c = Color("b8bcc4") if s2 < 0.6 else sc
				if on:
					var lit := s2 < 0.12 or float(yy) < sh_y
					p.img.set_pixel(xx, yy, (c.lightened(0.15) if lit else (scd if s2 > 0.74 else c)))

	## Rust: brown bubbles low on the doors and round the arches, more of it the older it gets.
	func _rust() -> void:
		var amt := float(mods.get("rust", d.art.get("rust", 0.0)))
		if amt <= 0.0 or lod == 0: return
		var brown := Color("7a4a2a")
		var dark := Color("4a2a18")
		for xx in range(x_lo, x_hi + 1):
			for yy in range(maxi(0, top_y[xx]), bot_y[xx] + 1):
				if not body_at(xx, yy) or glass_at(xx, yy): continue
				var low := (float(yy) - (sill - lf * 0.06)) / (lf * 0.06)
				var near_arch := false
				for wv: Array in wheels:
					var dd := Vector2(xx, yy).distance_to(wv[3])
					if dd < arch_r + lf * 0.03: near_arch = true
				if low < 0.0 and not near_arch: continue
				var n := ((xx * 92821) ^ (yy * 68917) ^ int(amt * 977.0)) % 100
				if float(n) < amt * 55.0 * (1.0 if near_arch else maxf(0.0, low)):
					p.img.set_pixel(xx, yy, dark if n % 3 == 0 else brown)

	# ------------------------------------------------------------ panels and trim

	func gap_c() -> Color:
		return (pal.deep as Color).darkened(0.35)

	func on_paint(xx: int, yy: int) -> bool:
		return body_at(xx, yy) and not glass_at(xx, yy)

	func gap_px(xx: int, yy: int) -> void:
		if on_paint(xx, yy) and (not _near_arch(xx, yy, 1.5) or skirted(wheels[0])): p.img.set_pixel(xx, yy, gap_c())

	func _near_arch(xx: int, yy: int, pad: float) -> bool:
		for wv: Array in wheels:
			var ac: Vector2 = wv[3]
			if skirted(wv): continue
			if in_arch(float(xx) + 0.5 - ac.x, float(yy) + 0.5 - ac.y, arch_r + pad): return true
		return false

	## Door shut lines, the rocker panel, bumper seams, the fuel door and the handles.
	func _panels() -> void:
		if lod == 0: return
		var belt_f := Y(float(d.belt_f))
		var rock := Y(float(d.rocker))
		var cr := maxi(2, int(lf * 0.012))
		var cuts: Array = d.door_cuts
		for dc: Array in cuts:
			var x0 := int(X(float(dc[1])))
			var x1 := int(X(float(dc[0])))
			if x1 - x0 < 6: continue
			if front > 0.3 and x1 > int(X(0.75)): continue
			var top0 := int(Y(lerpf(float(d.belt_r), float(d.belt_f), float(dc[1] - float(d.dlo_r)) / maxf(0.01, float(d.a_bot) - float(d.dlo_r))))) + 1
			var top1 := int(belt_f) + 1
			var bot := int(rock) - 1
			# the rear edge leans back a touch, the front edge runs down from the A-pillar
			for yy in range(top0, bot - cr):
				gap_px(x0 - int(float(yy - top0) * 0.05), yy)
			for yy in range(top1 - int(lf * 0.01), bot - cr):
				gap_px(x1 + int(float(yy - top1) * 0.06), yy)
			var xl := x0 - int(float(bot - top0) * 0.05)
			var xr := x1 + int(float(bot - top1) * 0.06)
			for xx in range(xl + cr, xr - cr + 1): gap_px(xx, bot)
			for a in 6:
				var an := PI * 0.5 * float(a) / 5.0
				gap_px(xl + cr - int(round(cos(an) * cr)), bot - cr + int(round(sin(an) * cr)))
				gap_px(xr - cr + int(round(cos(an) * cr)), bot - cr + int(round(sin(an) * cr)))
			_handle(x0, top0)
		# the rocker panel: a crisp top edge under the doors
		var rx0 := int(wheels[0][1] + arch_r) + 1
		var rx1 := int(wheels[1][1] - arch_r) - 1
		for xx in range(rx0, rx1):
			if on_paint(xx, int(rock)): p.img.set_pixel(xx, int(rock), gap_c())
			if on_paint(xx, int(rock) + 1): p.img.set_pixel(xx, int(rock) + 1, (pal.mid as Color))
		# bumper seams: from the arch up to the lamp at each end, on cars with painted bumpers
		if d.bumper in ["body", "strip"] and lod >= 1:
			var fa: Vector2 = wheels[1][3]
			var ra: Vector2 = wheels[0][3]
			var fxs := int(fa.x + arch_r * 0.85)
			var rxs := int(ra.x - arch_r * 0.85)
			for k in int(lf * 0.045):
				gap_px(fxs + k / 3, int(fa.y - arch_r * 0.5) - k)
				gap_px(rxs - k / 3, int(ra.y - arch_r * 0.5) - k)
		# the fuel door over the rear wheel
		if d.fuel and lod >= 1 and not front > 0.0:
			var fdx := int(wheels[0][1]) - int(lf * 0.02)
			if d.rear == "pickup": fdx = int(X(float(d.cab_x))) - int(lf * 0.06)
			var fdy := int(Y(float(d.belt_r)) + (rock - Y(float(d.belt_r))) * 0.22)
			var fw := maxi(3, int(lf * 0.03))
			var fh := maxi(3, int(lf * 0.026))
			for xx in range(fdx, fdx + fw):
				gap_px(xx, fdy)
				gap_px(xx, fdy + fh)
			for yy in range(fdy, fdy + fh + 1):
				gap_px(fdx, yy)
				gap_px(fdx + fw, yy)

	## A door handle at the back of the door, the way the era made them.
	func _handle(door_rear: int, belt_y: int) -> void:
		if lod < 1: return
		var hw := maxi(3, int(lf * 0.032))
		var hx := door_rear + maxi(2, int(lf * 0.018))
		var hy := belt_y + maxi(2, int((Y(float(d.rocker)) - float(belt_y)) * 0.16))
		match String(d.handle):
			"push":
				p.hline(hx, hy, hw, CarGen.CHROME[3])
				p.hline(hx, hy + 1, hw, CarGen.CHROME[1])
				p.px(hx + hw - 1, hy, Color.WHITE)
			"flap":
				p.rect(hx, hy, hw, maxi(2, u + 1), CarGen.TRIM)
				p.hline(hx, hy, hw, CarGen.CHROME[2] if year < 1980 else Color("3a3e46"))
			"flush":
				p.hline(hx, hy, hw, CarGen.TRIM)
				p.hline(hx, hy + 1, hw, (pal.hi as Color))
			_:
				p.rect(hx, hy, hw, maxi(2, u + 1), (pal.lt as Color))
				p.hline(hx, hy + maxi(2, u + 1), hw, (pal.deep as Color))
				p.hline(hx + 1, hy - 1, hw - 2, gap_c())

	## Chrome spears, rocker mouldings, rubbing strips, cladding, a body crease.
	func _trim() -> void:
		var trim: Array = d.trim
		var belt := Y(float(d.belt_r))
		var rock := Y(float(d.rocker))
		var fa: Vector2 = wheels[1][3]
		var ra: Vector2 = wheels[0][3]
		var crease := float(d.crease)
		if crease > 0.0 and lod >= 1:
			for xx in range(x_lo + 2, x_hi - 1):
				var fx := (float(xx) - float(ox)) / lf
				var sy := Y(shoulder(fx))
				var yy := int(sy + (sill - sy) * crease)
				if on_paint(xx, yy) and on_paint(xx, yy + 1) and not _near_arch(xx, yy, 2.0):
					p.img.set_pixel(xx, yy, (pal.hi as Color))
					p.img.set_pixel(xx, yy + 1, (pal.sh as Color))
		for t: String in trim:
			match t:
				"spear":
					var sy0 := int(belt + (rock - belt) * 0.32)
					var x0 := int(X(0.06))
					var x1 := int(X(0.88))
					for xx in range(x0, x1):
						var dip := int(float(xx - x0) / float(maxi(1, x1 - x0)) * lf * 0.02) if d.year < 1960 else 0
						if on_paint(xx, sy0 + dip):
							p.img.set_pixel(xx, sy0 + dip, CarGen.CHROME[3])
							if on_paint(xx, sy0 + dip + 1): p.img.set_pixel(xx, sy0 + dip + 1, CarGen.CHROME[1])
				"rocker_chrome":
					for xx in range(int(ra.x + arch_r) + 1, int(fa.x - arch_r)):
						var yy := bot_y[xx] - 1
						if on_paint(xx, yy):
							p.img.set_pixel(xx, yy - 1, CarGen.CHROME[3])
							p.img.set_pixel(xx, yy, CarGen.CHROME[1])
				"moulding":
					var my := int(belt + (rock - belt) * 0.5)
					for xx in range(x_lo + int(lf * 0.03), x_hi - int(lf * 0.03)):
						if on_paint(xx, my) and on_paint(xx, my + u) and not _near_arch(xx, my, 1.0):
							for k in u + 1: p.img.set_pixel(xx, my + k, CarGen.RUBBER if k > 0 else Color("4a4e56"))
				"cladding":
					var cy := int(rock - lf * 0.03)
					var cg := Color("6a6e74") if int(d.badge) % 2 == 0 else CarGen.RUBBER
					for xx in range(x_lo, x_hi + 1):
						for yy in range(cy, bot_y[xx] + 1):
							if on_paint(xx, yy): p.img.set_pixel(xx, yy, cg if yy > cy else cg.lightened(0.2))
				"arch_cladding", "arch_chrome":
					for wv: Array in wheels:
						var ac: Vector2 = wv[3]
						var thick := maxf(1.5, lf * (0.012 if t == "arch_cladding" else 0.006))
						for yy in range(int(ac.y - arch_r - thick) - 1, int(rock) + 2):
							for xx in range(int(ac.x - arch_r - thick) - 1, int(ac.x + arch_r + thick) + 2):
								if not on_paint(xx, yy): continue
								if not _near_arch(xx, yy, thick): continue
								p.img.set_pixel(xx, yy, CarGen.RUBBER if t == "arch_cladding" else CarGen.CHROME[2])

	## Vents, intakes, portholes, strakes, side markers and the little badges.
	func _side_bits() -> void:
		if lod == 0: return
		var belt := Y(float(d.belt_f))
		var rock := Y(float(d.rocker))
		var fa: Vector2 = wheels[1][3]
		var ra: Vector2 = wheels[0][3]
		match String(d.side_vent):
			"intake":
				# a scoop ahead of the rear wheel, feeding the engine
				var ix := int(ra.x + arch_r * 1.1)
				var iy := int(belt + (rock - belt) * 0.18)
				var iw := int(lf * 0.1)
				var ih := int((rock - belt) * 0.42)
				var pts := PackedVector2Array([Vector2(ix, iy + ih * 0.2), Vector2(ix + iw, iy), Vector2(ix + iw * 0.8, iy + ih), Vector2(ix, iy + ih)])
				p.poly(pts, CarGen.WELL)
				p.line(ix, int(iy + ih * 0.2), ix + iw, iy, (pal.hi as Color))
				for k in 3: p.hline(ix + 1, iy + int(ih * (0.35 + 0.2 * k)), int(iw * 0.7), Color("2a2e36"))
			"strakes":
				var sx := int(ra.x + arch_r * 1.05)
				var sw := int(lf * 0.24)
				var sy := int(belt + (rock - belt) * 0.15)
				var sh := int((rock - belt) * 0.55)
				p.rect(sx, sy, sw, sh, CarGen.WELL)
				for k in maxi(3, int(sh / maxf(2.0, float(u) * 2.5))):
					var yy := sy + 1 + k * maxi(2, int(float(u) * 2.5))
					if yy >= sy + sh: break
					p.hline(sx, yy, sw, (pal.base as Color))
					p.hline(sx, yy + 1, sw, (pal.sh as Color))
			"vent":
				var vx := int(fa.x - arch_r * 1.25)
				var vy := int(belt + (rock - belt) * 0.2)
				for k in 3:
					p.line(vx - k * 3 * u, vy, vx - k * 3 * u - 2 * u, vy + int(lf * 0.03), CarGen.WELL)
			"scoop_side":
				# a C-shaped scoop on the quarter panel, ahead of the rear wheel
				var sx2 := int(ra.x + arch_r * 1.1)
				var sy2 := int(Y(float(d.belt_r)) + (rock - Y(float(d.belt_r))) * 0.22)
				var sw2 := maxi(3, int(lf * 0.045))
				var sh2 := maxi(3, int((rock - Y(float(d.belt_r))) * 0.38))
				p.rect(sx2, sy2, sw2, sh2, CarGen.WELL)
				p.hline(sx2, sy2 - 1, sw2 + u, (pal.hi as Color))
				p.vline(sx2 + sw2, sy2, sh2, (pal.lt as Color))
				p.frame(sx2 - 1, sy2 - 1, sw2 + 1, sh2 + 2, CarGen.INK)
			"portholes_roof":
				var phx := int(X(float(d.dlo_r))) - int(lf * 0.035)
				var phy := int(Y(float(d.glass_top))) + int(lf * 0.025)
				p.disc(phx, phy, maxf(1.5, lf * 0.012), GLASS_C)
				p.ring(phx, phy, maxf(1.5, lf * 0.012) + 0.6, CarGen.CHROME[2])
			"portholes":
				var px0 := int(fa.x - arch_r * 0.2)
				var py := int(belt + (rock - belt) * 0.18)
				for k in 3:
					p.disc(px0 - k * int(lf * 0.025), py, maxf(1.0, lf * 0.007), CarGen.CHROME[1])
					p.px(px0 - k * int(lf * 0.025), py, CarGen.WELL)
		# the amber marker low on the front corner, a red one at the back (after 1968)
		if year >= 1968 and front < 0.4:
			var mx := int(fa.x + arch_r * 1.15)
			var my := int(belt + (rock - belt) * 0.3)
			if on_paint(mx, my) and on_paint(mx + 2 * u, my):
				p.rect(mx, my, 2 * u + 1, u + 1, AMBER_C)
		if year >= 1968 and rear < 0.4:
			var mx2 := int(ra.x - arch_r * 1.15) - 2 * u
			var my2 := int(Y(float(d.belt_r)) + (rock - Y(float(d.belt_r))) * 0.3)
			if on_paint(mx2, my2) and on_paint(mx2 + 2 * u, my2): p.rect(mx2, my2, 2 * u + 1, u + 1, CarGen.LAMP_RED)
		# badges: a little chrome mark on the front fender and the rear quarter, never a real one
		if lod >= 2:
			var bx := int(fa.x - arch_r * 1.05) - 4 * u
			var by := int(belt + (rock - belt) * 0.28)
			match int(d.badge):
				0:
					p.hline(bx, by, 4 * u, CarGen.CHROME[3])
				1:
					p.rect(bx, by, 2 * u, 2 * u, CarGen.CHROME[2])
					p.px(bx, by, Color.WHITE)
				2:
					for k in 3: p.px(bx + k * 2, by - (k % 2), CarGen.CHROME[3])
				_:
					p.hline(bx, by, 2 * u, Color("c83c3c"))
					p.hline(bx + 2 * u, by, 2 * u, CarGen.CHROME[3])
			var qx := int(ra.x - arch_r * 0.6)
			var qy := int(Y(float(d.belt_r)) + (rock - Y(float(d.belt_r))) * 0.2)
			if on_paint(qx, qy) and on_paint(qx + 4 * u, qy):
				p.hline(qx, qy, 3 * u, CarGen.CHROME[3])
				p.px(qx + 3 * u + 1, qy, CarGen.CHROME[2])

	const AMBER_C := Color("f0a020")

	# ------------------------------------------------------------ lamps

	func _lamps() -> void:
		var lights_on: bool = dmg.get("lights", mods.get("lights_on", false))
		var nose := int(X(1.0 - front * 0.2)) - 1
		var tail := int(X(rear * 0.16))
		var lens := Color("fff6d8") if lights_on else Color("d8e2ea")
		if front < 0.4:
			var hx := nose
			var col_top := _first_body(hx - int(lf * 0.02))
			var head := String(d.head)
			if head == "hidden":
				if lights_on: head = "round"
				else:
					# the grille runs across where the lamps hide
					var gy0 := col_top + maxi(1, u)
					var gy1 := int(Y(float(d.nose_mid))) + u
					for yy in range(gy0, gy1):
						if on_paint(nose - u, yy): p.img.set_pixel(nose - u, yy, CarGen.WELL if yy % 2 == 0 else CarGen.TRIM)
			if head == "frog":
				# bug-eyes standing up out of the hood
				var fx := nose - int(lf * 0.08)
				var fr := maxf(1.5, lf * 0.02)
				var fy := _first_body(fx) - int(fr * 0.4)
				p.disc(fx, fy, fr, (pal.base as Color))
				p.disc(fx + int(fr * 0.5), fy, fr * 0.6, lens)
				p.ring(fx, fy, fr + 0.6, CarGen.INK)
			match head:
				"popup":
					# folded flush into the hood, or standing up when they're on
					var px0 := nose - int(lf * 0.1)
					var pw := int(lf * 0.07)
					var py := _first_body(px0 + pw / 2)
					if lights_on:
						var ph := maxi(3, int(lf * 0.03))
						p.rect(px0, py - ph, pw, ph + 1, (pal.base as Color))
						p.hline(px0, py - ph, pw, (pal.hi as Color))
						p.vline(px0 + pw - 1, py - ph + 1, ph - 1, lens)
						p.frame(px0 - 1, py - ph - 1, pw + 2, ph + 2, CarGen.INK)
					else:
						for xx in range(px0, px0 + pw): gap_px(xx, _first_body(xx) + u + 1)
						gap_px(px0, _first_body(px0) + u)
					# the turn signal and parking lamp low in the bumper
					var sy := int(Y(float(d.nose_mid))) + u
					_lens(nose - 3 * u, sy, 3 * u, 2 * u, AMBER_C)
				"round", "quad":
					var ry := col_top + maxi(2, int(lf * 0.022))
					var rr := maxf(1.5, lf * 0.016)
					p.disc(nose - int(rr), ry, rr, lens)
					p.ring(nose - int(rr), ry, rr + 0.6, CarGen.CHROME[2])
					p.px(nose - int(rr) - 1, ry - 1, Color.WHITE)
					if d.head == "quad" and lod >= 1:
						p.disc(nose - int(rr * 2.6), ry, rr * 0.8, lens.darkened(0.08))
						p.ring(nose - int(rr * 2.6), ry, rr * 0.8 + 0.6, CarGen.CHROME[2])
				"rect":
					var lw := maxi(3, int(lf * 0.035))
					var lh := maxi(3, int(lf * 0.022))
					var ly := col_top + maxi(2, int(lf * 0.01))
					_lens(nose - lw, ly, lw, lh, lens)
					p.frame(nose - lw - 1, ly - 1, lw + 2, lh + 2, CarGen.CHROME[2] if year < 1985 else CarGen.INK)
					_lens(nose - lw - 2 * u - 1, ly + lh - 2 * u, 2 * u, 2 * u, AMBER_C)
				"flush", "jewel", "swept":
					# a lamp wrapped round the corner, following the hood's line back
					var lw2 := int(lf * (0.06 if d.head == "flush" else (0.075 if d.head == "jewel" else 0.1)))
					var lh2 := maxi(2, int(lf * (0.02 if d.head != "swept" else 0.016)))
					var last := nose
					for xx in range(nose - lw2, nose + 1):
						var ty := _first_body(xx) + u + (1 if d.head == "flush" else 0)
						var t := float(xx - (nose - lw2)) / float(maxi(1, lw2))
						var hh := lh2 + int(t * lf * 0.008)
						if d.head == "swept": hh = maxi(2, int(float(lh2) * (0.5 + t)))
						if not on_paint(xx, ty + hh): continue
						for k in hh:
							var c := lens if k > 0 else lens.lightened(0.5)
							if d.head != "flush" and t < 0.22: c = AMBER_C if k > 0 else AMBER_C.lightened(0.3)
							p.img.set_pixel(xx, ty + k, c)
						p.px(xx, ty - 1, CarGen.INK)
						p.px(xx, ty + hh, CarGen.INK)
						last = xx
					if top_y[clampi(nose - lw2, 0, w - 1)] >= 0: p.vline(nose - lw2 - 1, _first_body(nose - lw2) + u - 1, lh2 + 2, CarGen.INK)
					if d.head == "jewel" and lod >= 2:
						p.disc(last - int(lf * 0.015), _first_body(last - int(lf * 0.015)) + u + lh2 / 2 + 1, maxf(1.0, lf * 0.006), Color.WHITE)
					if d.head == "swept" and year >= 2012 and lod >= 1:
						p.hline(nose - lw2 + 2, _first_body(nose - lw2 / 2) + u + lh2 + 1, lw2 - 4, Color("eaf4ff"))
			if lights_on: p.glow(nose + 3, col_top + int(lf * 0.03), maxf(6.0, lf * 0.05), Color("fff4c8"), 0.8)
		else:
			p.rect(nose - 2 * u, int(Y(float(d.hood_h))) + u, 3 * u, 3 * u, CarGen.WELL)
		if rear < 0.4:
			var tw := maxi(3, int(lf * 0.03))
			var ty2 := _first_body(tail + tw / 2) + maxi(1, u)
			match String(d.tail_lamp):
				"fin":
					var fy := _first_body(tail + u) + u
					_lens(tail, fy, maxi(3, int(lf * 0.025)), maxi(3, int(lf * 0.03)), CarGen.LAMP_RED)
				"bar":
					var by := int(Y(float(d.tail_h))) + 2 * u
					_lens(tail, by, maxi(4, int(lf * 0.05)), maxi(2, int(lf * 0.014)), CarGen.LAMP_RED)
				"round":
					p.disc(tail + int(lf * 0.012), ty2 + int(lf * 0.012), maxf(1.5, lf * 0.012), CarGen.LAMP_RED)
					p.ring(tail + int(lf * 0.012), ty2 + int(lf * 0.012), maxf(1.5, lf * 0.012) + 0.6, CarGen.INK)
				"tall":
					var th := maxi(4, int(lf * 0.065))
					_lens(tail, ty2 + u, tw, th, CarGen.LAMP_RED)
					p.rect(tail, ty2 + u + th - 2 * u, tw, 2 * u, AMBER_C)
				"block":
					_lens(tail, ty2, maxi(4, int(lf * 0.04)), maxi(3, int(lf * 0.03)), CarGen.LAMP_RED)
				"racetrack":
					# one long thin bar wrapped round the tail
					var rw := int(lf * 0.1)
					for xx in range(tail, tail + rw):
						var top := _first_body(xx) + u
						if not on_paint(xx, top + 1): continue
						p.img.set_pixel(xx, top, Color("ff5a4a"))
						p.img.set_pixel(xx, top + 1, CarGen.LAMP_RED)
						p.px(xx, top + 2, CarGen.INK)
				_:
					# wraps round onto the quarter panel
					var ww := int(lf * (0.05 if d.tail_lamp == "wrap" else 0.075))
					var hh2 := maxi(3, int(lf * 0.026))
					for xx in range(tail, tail + ww):
						var top := _first_body(xx) + u
						var t2 := float(xx - tail) / float(maxi(1, ww))
						var hh3 := maxi(2, int(float(hh2) * (1.0 - t2 * 0.6)))
						if not on_paint(xx, top + hh3): continue
						for k in hh3: p.img.set_pixel(xx, top + k, CarGen.LAMP_RED if k > 0 else Color("ff7a7a"))
						p.px(xx, top + hh3, CarGen.INK)
					p.vline(tail + ww, _first_body(tail + ww) + u, maxi(2, hh2 / 2), CarGen.INK)

	func _first_body(xx: int) -> int:
		if xx < 0 or xx >= w: return gy
		var t := top_y[xx]
		return t if t >= 0 else gy

	func _lens(x0: int, y0: int, lw: int, lh: int, c: Color) -> void:
		p.rect(x0, y0, lw, lh, c)
		p.hline(x0, y0, lw, c.lightened(0.45))
		if lh > 2: p.hline(x0, y0 + lh - 1, lw, c.darkened(0.25))
		p.frame(x0 - 1, y0 - 1, lw + 2, lh + 2, CarGen.INK)

	# ------------------------------------------------------------ glass trim

	## The frame round the side glass, the pillars on it, a vent window, a sunroof or T-tops.
	func _glass_frame() -> void:
		if glass.is_empty(): return
		var trim := CarGen.CHROME[2] if d.frame == "chrome" else CarGen.INK
		var gt := int(Y(float(d.glass_top)))
		var belt := int(Y(float(d.belt_f)))
		var pil_c := (pal.base as Color) if d.pillar == "body" else CarGen.TRIM
		for q: Array in d.pillars:
			if d.hardtop and d.family in ["coupe", "muscle"]:
				pil_c = CarGen.CHROME[2]
			var xb := X(float(q[0]))
			var xt := X(float(q[1]))
			var pw := maxf(1.0, float(q[2]) * lf)
			if d.hardtop and d.family in ["coupe", "muscle"]: pw = 1.0
			for yy in range(gt - 2, belt + 3):
				var t := float(yy - gt) / maxf(1.0, float(belt - gt))
				var xc := lerpf(xt, xb, t)
				for k in int(ceil(pw)):
					var xx := int(xc - pw * 0.5) + k
					if glass_at(xx, yy): p.img.set_pixel(xx, yy, pil_c if k > 0 or pil_c == CarGen.CHROME[2] else pil_c.lightened(0.2))
		# a vent window at the front of the door
		if d.vent and lod >= 1:
			var vx := int(X(float(d.a_bot))) - int(lf * 0.07)
			for yy in range(gt, belt + 1):
				if glass_at(vx, yy): p.img.set_pixel(vx, yy, CarGen.CHROME[2])
		p.poly_outline(glass, trim)
		if d.frame == "chrome" and lod >= 2:
			# the chrome catches the light along the bottom edge
			var x0 := int(X(float(d.dlo_r)))
			var x1 := int(X(float(d.a_bot)))
			for xx in range(x0, x1):
				var t2 := float(xx - x0) / float(maxi(1, x1 - x0))
				var yy2 := int(lerpf(Y(float(d.belt_r)), Y(float(d.belt_f)), t2)) + 1
				if on_paint(xx, yy2): p.img.set_pixel(xx, yy2, CarGen.CHROME[3])
		if d.art.has("ttops") and lod >= 1:
			var tx0 := int(X(float(d.a_top))) - int(lf * 0.02)
			var tx1 := int(X(float(d.a_top))) - int(lf * 0.14)
			for xx in range(tx1, tx0):
				var ty := _first_body(xx)
				p.img.set_pixel(xx, ty, GLASS_TOP_C)
				if xx % 3 == 0: p.img.set_pixel(xx, ty + 1, GLASS_C)
		if d.art.has("sunroof") and lod >= 1:
			var sx0 := int(X(float(d.a_top))) - int(lf * 0.05)
			for xx in range(sx0 - int(lf * 0.1), sx0):
				p.px(xx, _first_body(xx) - 1, GLASS_C)
			p.px(sx0, _first_body(sx0) - 1, CarGen.INK)

	# ------------------------------------------------------------ open cars

	## Roadsters and open 4x4s: a framed windshield, seats and headrests, a folded top or a roll bar.
	func _cabin_open() -> void:
		if d.rear != "open": return
		var cx := X(float(d.cowl_x))
		var cy := Y(float(d.cowl_h))
		var rake := (float(d.cowl_x) - float(d.roof_f)) / maxf(0.01, float(d.h) - float(d.cowl_h))
		var ws_h := lf * (0.075 if d.family == "roadster" else 0.12)
		var tx := cx - ws_h * rake * 0.9
		var ty := cy - ws_h
		var frame := CarGen.CHROME[2] if year < 1985 else CarGen.TRIM
		# seats and heads of the headrests
		var belt := Y(float(d.belt_f))
		var sx := X(float(d.dlo_r)) + (cx - X(float(d.dlo_r))) * 0.3
		var hr := maxf(2.0, lf * 0.018)
		for k in (2 if d.family == "offroad" else 1):
			var hx := sx - float(k) * lf * 0.16
			p.rect(int(hx - hr), int(belt - lf * 0.045), int(hr * 2.0), int(lf * 0.045), Color("2a2622"))
			p.disc(int(hx), int(belt - lf * 0.05), hr, Color("3a3430"))
			p.frame(int(hx - hr) - 1, int(belt - lf * 0.045), int(hr * 2.0) + 2, int(lf * 0.045), CarGen.INK)
		# steering wheel
		p.line(int(cx - lf * 0.06), int(belt - lf * 0.03), int(cx - lf * 0.045), int(belt - lf * 0.005), Color("1a1a1e"))
		# the windshield: glass in a frame
		var gpts := PackedVector2Array([Vector2(cx, cy), Vector2(tx, ty), Vector2(tx - u * 2.0, ty), Vector2(cx - lf * 0.03, cy)])
		p.poly(gpts, Color(GLASS_TOP_C, 0.55))
		p.line(int(cx), int(cy), int(tx), int(ty), frame)
		p.line(int(cx) - 1, int(cy), int(tx) - 1, int(ty), CarGen.INK)
		p.hline(int(tx) - 2 * u, int(ty), 3 * u, frame)
		if d.family == "offroad":
			# a roll bar over the seats
			var rbx := X(float(d.dlo_r)) + lf * 0.04
			var rbt := belt - lf * 0.11
			for k in u + 1:
				p.line(int(rbx) + k, int(belt), int(rbx) + k, int(rbt), CarGen.TRIM)
			p.hline(int(rbx), int(rbt), int(lf * 0.08), CarGen.TRIM)
			p.line(int(rbx + lf * 0.08), int(rbt), int(rbx + lf * 0.1), int(belt), CarGen.TRIM)
		elif year < 1990:
			# the folded top behind the seats
			var fx0 := sx - lf * 0.1
			p.rect(int(fx0), int(belt - lf * 0.02), int(lf * 0.08), int(lf * 0.02) + 1, Color("2a2a2e"))
			p.hline(int(fx0), int(belt - lf * 0.02), int(lf * 0.08), Color("4a4a50"))

	# ------------------------------------------------------------ the contour

	## A crisp dark line just outside the body all the way round.
	func _outline() -> void:
		var ink := CarGen.INK
		var img := p.img
		for yy in range(maxi(1, y_lo - 1), mini(hgt - 1, y_hi + 2)):
			var row := yy * w
			for xx in range(maxi(1, x_lo - 1), mini(w - 1, x_hi + 2)):
				var i := row + xx
				if bm[i] != 0: continue
				if bm[i + 1] != 0 or bm[i - 1] != 0 or bm[i - w] != 0 or bm[i + w] != 0:
					img.set_pixel(xx, yy, ink)

	## Separate fenders (a bug, a 2CV): a curved fender over each wheel, a running board between.
	func _fenders() -> void:
		if String(d.get("fenders", "")) != "separate": return
		var thick := maxf(2.0, lf * 0.04)
		for wv: Array in wheels:
			var ac: Vector2 = wv[3]
			var r0 := arch_r
			var r1 := arch_r + thick
			var bottom := sill + float(u)
			for yy in range(int(ac.y - r1) - 1, int(bottom) + 1):
				for xx in range(int(ac.x - r1 * 1.25) - 1, int(ac.x + r1 * 1.25) + 2):
					var dx := (float(xx) + 0.5 - ac.x) / 1.2
					var dy := float(yy) + 0.5 - ac.y
					var dd := sqrt(dx * dx + dy * dy)
					if dd > r1 or (dd < r0 and dy < 0.0) or float(yy) > bottom: continue
					if dy >= 0.0 and absf(dx) < r0: continue
					var t := (r1 - dd) / thick
					var c: Color = (pal.hi as Color) if t < 0.15 else ((pal.lt as Color) if t < 0.35 else (pal.base as Color))
					if dy > -r0 * 0.3: c = (pal.mid as Color)
					p.img.set_pixel(xx, yy, c)
			for k in 72:
				var a := PI + PI * float(k) / 71.0
				for rr: float in [r1 + 0.6, r0 - 0.6]:
					var qx := int(ac.x + cos(a) * rr * 1.2)
					var qy := int(ac.y + sin(a) * rr)
					if float(qy) <= bottom: p.px(qx, qy, CarGen.INK)
		# the running board
		var x0 := int(float(wheels[0][1]) + arch_r * 1.2)
		var x1 := int(float(wheels[1][1]) - arch_r * 1.2)
		p.rect(x0, int(sill), x1 - x0, 2 * u + 1, CarGen.RUBBER)
		p.hline(x0, int(sill), x1 - x0, Color("4a4e56"))
		p.frame(x0 - 1, int(sill) - 1, x1 - x0 + 2, 2 * u + 3, CarGen.INK)

	# ------------------------------------------------------------ bumpers

	func _bumpers() -> void:
		var nose := int(X(1.0 - front * 0.2)) - 1
		var tail := int(X(rear * 0.16))
		var bumper := String(dmg.get("bumper", ""))
		var bash: bool = mods.get("bash", false)
		var style := String(d.bumper)
		if mods.get("smooth", false) and style in ["chrome", "chrome5"]: style = "body"
		for end in [0, 1]:
			var at := tail if end == 0 else nose
			var by := int(Y(float(d.tail_bot if end == 0 else d.nose_bot)))
			if end == 1 and (bumper == "gone" or bash): continue
			if end == 1 and bumper == "hang":
				p.line(nose - 6, by - int(lf * 0.03), nose + 4, gy - 1, CarGen.TRIM)
				p.line(nose - 6, by - int(lf * 0.03) - 1, nose + 4, gy - 2, CarGen.INK)
				continue
			var bw := int(lf * (0.07 if style != "steel" else 0.05))
			var bh := maxi(3, int(lf * (0.03 if style == "chrome" else 0.04)))
			var x0 := at - 1 if end == 1 else at - 2 * u
			var stick := maxi(1, int(lf * (0.008 if style == "chrome" else 0.014)))
			var bx := (at - bw + stick) if end == 1 else (at - stick)
			var top := by - bh
			match style:
				"chrome", "chrome5":
					if style == "chrome5": bh += u
					for k in bh:
						var t := float(k) / float(maxi(1, bh - 1))
						var c: Color = CarGen.CHROME[3] if t < 0.2 else (CarGen.CHROME[4] if t < 0.32 else (CarGen.CHROME[2] if t < 0.6 else (CarGen.CHROME[1] if t < 0.85 else CarGen.CHROME[0])))
						p.hline(bx, top + k, bw, c)
					if style == "chrome5":
						p.hline(bx, top + bh / 2, bw, CarGen.RUBBER)
					p.frame(bx - 1, top - 1, bw + 2, bh + 2, CarGen.INK)
				"rubber":
					p.rect(bx, top, bw, bh + u, CarGen.RUBBER)
					p.hline(bx, top, bw, Color("4a4e56"))
					p.hline(bx, top + bh + u - 1, bw, CarGen.TRIM.darkened(0.3))
					p.frame(bx - 1, top - 1, bw + 2, bh + u + 2, CarGen.INK)
				"steel":
					p.rect(bx, top - u, bw, bh + 2 * u, CarGen.STEEL)
					p.hline(bx, top - u, bw, CarGen.STEEL.lightened(0.3))
					p.hline(bx, top + bh + u - 1, bw, CarGen.STEEL.darkened(0.4))
					p.frame(bx - 1, top - u - 1, bw + 2, bh + 2 * u + 2, CarGen.INK)
				"strip":
					var sy := top + bh / 2
					for xx in range(at - bw if end == 1 else at, at if end == 1 else at + bw):
						if on_paint(xx, sy): p.img.set_pixel(xx, sy, CarGen.RUBBER)
					_valance(end, at, by)
				_:
					_valance(end, at, by)
			x0 = x0

	## A painted bumper: its seam, and the black intake or diffuser in its bottom edge.
	func _valance(end: int, at: int, by: int) -> void:
		if lod == 0: return
		var bw := int(lf * 0.06)
		if end == 1:
			if front < 0.5:
				var iy := by - maxi(2, int(lf * 0.016))
				for xx in range(at - bw, at - int(lf * 0.008)):
					if on_paint(xx, iy) and on_paint(xx, iy + 2):
						p.img.set_pixel(xx, iy, CarGen.WELL)
						p.img.set_pixel(xx, iy + 1, CarGen.TRIM)
		else:
			var dy := by - maxi(2, int(lf * 0.01))
			for xx in range(at + u, at + bw):
				if on_paint(xx, dy) and on_paint(xx, dy + 1): p.img.set_pixel(xx, dy + 1, CarGen.TRIM)

	# ------------------------------------------------------------ mirrors

	func _mirror() -> void:
		if lod == 0 or front > 0.6: return
		var mx := int(X(float(d.a_bot))) - u
		var my := int(Y(float(d.belt_f)))
		var mw := maxi(3, int(lf * 0.032))
		var mh := maxi(2, int(lf * 0.02))
		match String(d.mirror):
			"chrome_small", "chrome":
				var r2 := maxf(1.0, lf * (0.008 if d.mirror == "chrome_small" else 0.011))
				p.vline(mx - int(r2), my - int(r2 * 1.5), int(r2 * 1.5), CarGen.CHROME[1])
				p.disc(mx - int(r2), my - int(r2 * 2.2), r2, CarGen.CHROME[2])
				p.px(mx - int(r2) - 1, my - int(r2 * 2.2) - 1, Color.WHITE)
				p.ring(mx - int(r2), my - int(r2 * 2.2), r2 + 0.7, CarGen.INK)
			"fender":
				var fx := int(X(float(d.wf))) - int(lf * 0.02)
				var fy := _first_body(fx)
				p.vline(fx, fy - int(lf * 0.02), int(lf * 0.02), CarGen.TRIM)
				p.rect(fx - 1, fy - int(lf * 0.03), 3 * u, 2 * u + 1, CarGen.CHROME[2] if year < 1978 else CarGen.TRIM)
				p.frame(fx - 2, fy - int(lf * 0.03) - 1, 3 * u + 2, 2 * u + 3, CarGen.INK)
			"truck", "truck_chrome":
				var tc := CarGen.CHROME[2] if d.mirror == "truck_chrome" else CarGen.TRIM
				var th := maxi(4, int(lf * 0.032))
				var tw := maxi(3, int(lf * 0.022))
				var ty := my - th + int(lf * 0.012)
				p.rect(mx - tw - u, ty, tw, th, tc)
				p.vline(mx - tw - u, ty, th, tc.lightened(0.3))
				p.frame(mx - tw - u - 1, ty - 1, tw + 2, th + 2, CarGen.INK)
				p.hline(mx - u, ty + th / 2, 2 * u, CarGen.INK)
			_:
				var mc := (pal.base as Color) if d.mirror == "body" else CarGen.TRIM
				var pts := PackedVector2Array([Vector2(mx - mw, my - mh), Vector2(mx, my - mh - u), Vector2(mx + u, my), Vector2(mx - mw, my)])
				p.poly(pts, mc)
				p.hline(mx - mw + 1, my - mh, mw - 1, mc.lightened(0.3))
				p.poly_outline(pts, CarGen.INK)

	# ------------------------------------------------------------ on the roof

	func _roof_things() -> void:
		var art: Dictionary = d.art
		if lod == 0: return
		var x_rf := X(float(d.roof_f))
		var x_rr := X(float(d.roof_r))
		if d.antenna == "mast" and lod >= 1:
			var ax := int(X(float(d.wf))) - int(lf * 0.06)
			var ay := _first_body(ax)
			p.line(ax, ay, ax - int(lf * 0.03), ay - int(lf * 0.12), CarGen.CHROME[1])
		elif d.antenna == "fin":
			var fx := int(x_rr) + int(lf * 0.03)
			var fy := _first_body(fx)
			p.poly(PackedVector2Array([Vector2(fx - 3 * u, fy), Vector2(fx + 2 * u, fy - 2 * u), Vector2(fx + 3 * u, fy)]), CarGen.TRIM)
		if art.has("rack"):
			var y0 := _first_body(int((x_rf + x_rr) * 0.5))
			var rx0 := int(x_rr) + int(lf * 0.02)
			var rx1 := int(x_rf) - int(lf * 0.02)
			if d.rear in ["box"]: rx0 = int(X(0.06))
			p.rect(rx0, y0 - 2 * u, rx1 - rx0, u + 1, CarGen.TRIM)
			p.hline(rx0, y0 - 2 * u, rx1 - rx0, Color("4a4e56"))
			for k in 3:
				var lx := rx0 + (rx1 - rx0) * k / 2
				p.vline(lx, y0 - 2 * u, 2 * u + 1, CarGen.TRIM)
			p.frame(rx0 - 1, y0 - 2 * u - 1, rx1 - rx0 + 2, u + 3, CarGen.INK)
		if art.has("hearse") and lod >= 1:
			var lbx := int(X(float(d.dlo_r) - 0.12))
			var lby := int(Y(float(d.glass_top))) + int(lf * 0.03)
			var lw := int(lf * 0.06)
			for k in lw:
				var t := float(k) / float(maxi(1, lw))
				p.px(lbx + k, lby + int(sin(t * PI * 1.6) * lf * 0.012), CarGen.CHROME[3])
		if art.has("blackroof"):
			for xx in range(int(X(float(d.dlo_rt))) - int(lf * 0.02), int(X(float(d.a_top))) + u):
				var t0 := _first_body(xx)
				for yy in range(t0, int(Y(float(d.glass_top)))):
					if on_paint(xx, yy): p.img.set_pixel(xx, yy, CarGen.TRIM if yy > t0 else Color("3a3e46"))
		if art.has("vinyl"):
			var vc := Color("1e1c1e") if paint_c.get_luminance() > 0.3 else Color("e8e2d0")
			for xx in range(int(X(float(d.dlo_rt))) - int(lf * 0.03), int(X(float(d.a_top))) - u):
				var t0 := _first_body(xx)
				var gt := int(Y(float(d.glass_top)))
				for yy in range(t0, gt):
					if on_paint(xx, yy): p.img.set_pixel(xx, yy, vc.lightened(0.12) if (xx + yy * 3) % 7 == 0 else vc)
			# the opera window in the C-pillar
			if d.doors == 2 and lod >= 1:
				var ow := X(float(d.dlo_r)) - lf * 0.05
				p.rect(int(ow), int(Y(float(d.glass_top))) + 2 * u, int(lf * 0.025), int(lf * 0.03), GLASS_C)
				p.frame(int(ow) - 1, int(Y(float(d.glass_top))) + 2 * u - 1, int(lf * 0.025) + 2, int(lf * 0.03) + 2, CarGen.CHROME[2])

	func _roof_lights() -> void:
		var art: Dictionary = d.art
		var mid := int((X(float(d.roof_f)) + X(float(d.roof_r))) * 0.5)
		var top := _first_body(mid)
		if art.has("beacon"):
			p.rect(mid - 2 * u, top - 3 * u, 4 * u, 3 * u, AMBER_C)
			p.hline(mid - 2 * u, top - 3 * u, 4 * u, AMBER_C.lightened(0.4))
			p.frame(mid - 2 * u - 1, top - 3 * u - 1, 4 * u + 2, 3 * u + 1, CarGen.INK)
		if art.has("topper"):
			var tw := int(lf * 0.12)
			p.rect(mid - tw / 2, top - int(lf * 0.035), tw, int(lf * 0.03), Color("f0e8c8"))
			p.frame(mid - tw / 2 - 1, top - int(lf * 0.035) - 1, tw + 2, int(lf * 0.03) + 1, CarGen.INK)
			if lod >= 2: p.text(mid - Pix.text_w("TAXI") / 2, top - int(lf * 0.03), "TAXI", Color("2a2a2e"))
		if art.has("spotlight"):
			var sx := int(X(float(d.a_bot))) - u
			var sy := int(Y(float(d.belt_f))) - int(lf * 0.02)
			p.disc(sx, sy, maxf(1.5, lf * 0.01), CarGen.CHROME[2])
			p.ring(sx, sy, maxf(1.5, lf * 0.01) + 0.7, CarGen.INK)

	# ------------------------------------------------------------ wings and scoops

	func _aero() -> void:
		var art: Dictionary = d.art
		var spoiler := String(mods.get("spoiler", "none"))
		if spoiler == "none":
			if art.has("wing"): spoiler = String(d.get("wing_kind", "factory_wing"))
			elif art.has("spoiler"): spoiler = "lip"
			if d.has("wing_kind") and not art.has("wing"): spoiler = String(d.wing_kind)
		if art.has("louvers") and lod >= 1:
			# slats over the rear glass or the engine cover
			var lx0 := int(X(float(d.tail_x) + 0.06))
			var lx1 := int(X(float(d.roof_r)))
			var step := maxi(2, 2 * u + 1)
			for xx in range(lx0, lx1, step):
				var t := _first_body(xx)
				p.px(xx, t - 1, CarGen.INK)
				p.px(xx, t, CarGen.TRIM)
				if u > 1: p.px(xx + 1, t - 1, CarGen.INK)
		if art.has("roofscoop"):
			var rx := int(X(float(d.roof_r) + 0.03))
			var rt := _first_body(rx)
			var rh := maxi(3, int(lf * 0.03))
			p.rect(rx, rt - rh, int(lf * 0.06), rh + 1, (pal.base as Color))
			p.rect(rx + int(lf * 0.06) - 2 * u, rt - rh + u, 2 * u, rh - u, CarGen.WELL)
			p.hline(rx, rt - rh, int(lf * 0.06), (pal.hi as Color))
			p.frame(rx - 1, rt - rh - 1, int(lf * 0.06) + 2, rh + 2, CarGen.INK)
		if spoiler != "none" and not d.family in ["pickup", "van", "boxtruck"]:
			var dx0 := X(float(d.tail_x)) + lf * 0.01
			var dtop := float(_first_body(int(dx0 + lf * 0.05)))
			match spoiler:
				"lip":
					var lx := int(X(float(d.tail_x))) + u
					var ly := _first_body(lx + int(lf * 0.02))
					var pts0 := PackedVector2Array([Vector2(lx - u, ly - 2 * u), Vector2(lx + lf * 0.05, ly), Vector2(lx, ly + u)])
					p.poly(pts0, (pal.base as Color))
					p.poly_outline(pts0, CarGen.INK)
				"whale":
					# a whale tail: a broad flat wing on the engine lid with a black rubber lip
					var wx0 := X(float(d.tail_x)) + lf * 0.02
					var wt := float(_first_body(int(wx0 + lf * 0.08)))
					var pts4 := PackedVector2Array([Vector2(wx0, wt + u), Vector2(wx0 - u, wt - 4 * u), Vector2(wx0 + lf * 0.09, wt - 3 * u), Vector2(wx0 + lf * 0.13, wt + u)])
					p.poly(pts4, (pal.base as Color))
					p.line(int(wx0 - u), int(wt - 4 * u), int(wx0 + lf * 0.09), int(wt - 3 * u), (pal.hi as Color))
					p.line(int(wx0 - u), int(wt - 4 * u) - 1, int(wx0 + lf * 0.09), int(wt - 3 * u) - 1, CarGen.RUBBER)
					p.poly_outline(pts4, CarGen.INK)
				"tall":
					# a wing on stilts, well above the roof
					var tx0 := X(float(d.tail_x)) + lf * 0.01
					var top2 := Y(float(d.h)) - lf * 0.02
					for st: float in [tx0 + lf * 0.015, tx0 + lf * 0.075]:
						var sb := _first_body(int(st))
						p.rect(int(st), int(top2), 2 * u, sb - int(top2), (pal.base as Color))
						p.frame(int(st) - 1, int(top2), 2 * u + 2, sb - int(top2), CarGen.INK)
					var blade := PackedVector2Array([Vector2(tx0 - 2 * u, top2 - 2 * u), Vector2(tx0 + lf * 0.11, top2 - u), Vector2(tx0 + lf * 0.11, top2 + u), Vector2(tx0 - 2 * u, top2 + u)])
					p.poly(blade, (pal.base as Color))
					p.poly_outline(blade, CarGen.INK)
				"deck":
					# the wing grows straight out of the rear deck
					var dx1 := X(float(d.tail_x))
					var dt := float(_first_body(int(dx1 + lf * 0.03)))
					var pts5 := PackedVector2Array([Vector2(dx1, dt + u), Vector2(dx1 - u, dt - lf * 0.04), Vector2(dx1 + lf * 0.04, dt - lf * 0.04), Vector2(dx1 + lf * 0.1, dt + u)])
					p.poly(pts5, (pal.base as Color))
					p.hline(int(dx1), int(dt - lf * 0.04), int(lf * 0.04), (pal.hi as Color))
					p.poly_outline(pts5, CarGen.INK)
				"ducktail":
					var pts := PackedVector2Array([Vector2(dx0, dtop + u), Vector2(dx0 + lf * 0.12, dtop), Vector2(dx0 - u, dtop - 3 * u)])
					p.poly(pts, (pal.base as Color))
					p.line(int(dx0 - u), int(dtop - 3 * u), int(dx0 + lf * 0.12), int(dtop), (pal.hi as Color))
					p.poly_outline(pts, CarGen.INK)
				"wing", "gt", "factory_wing":
					var big := spoiler == "gt"
					var ph := (5 if big else 3) * u + int(lf * 0.01)
					var bw2 := int(lf * (0.16 if big else 0.13))
					var bc2: Color = CarGen.TRIM if big else (pal.base as Color)
					for px1 in [dx0 + 3.0 * u, dx0 + lf * 0.09]:
						var st := int(px1)
						var sy := _first_body(st)
						p.rect(st, sy - ph, u + 1, ph, bc2)
						p.frame(st - 1, sy - ph - 1, u + 3, ph + 1, CarGen.INK)
					var sy0 := _first_body(int(dx0 + lf * 0.05))
					var bt := 2 * u
					var bx := int(dx0) - 3 * u
					var by := sy0 - ph - bt
					var pts2 := PackedVector2Array([Vector2(bx, by - u), Vector2(bx + bw2, by + u), Vector2(bx + bw2, by + bt), Vector2(bx, by + bt)])
					p.poly(pts2, bc2)
					p.line(bx, by - u, bx + bw2, by + u, Color("4a4e56") if big else (pal.hi as Color))
					p.poly_outline(pts2, CarGen.INK)
					if big:
						p.rect(bx - u, by - 2 * u, u + 1, bt + 3 * u, CarGen.TRIM)
						p.frame(bx - u - 1, by - 2 * u - 1, u + 3, bt + 3 * u + 2, CarGen.INK)
		# a hood scoop, or louvres on a vented hood
		if art.has("scoop") and not String(mods.get("hood", "")) == "vented":
			var sx := int(X(float(d.cowl_x) + (float(d.nose_x) - float(d.cowl_x)) * 0.35))
			var sw := int(lf * 0.08)
			var top := _first_body(sx + sw / 2)
			var sh := maxi(2, int(lf * 0.016))
			var pts3 := PackedVector2Array([Vector2(sx, top + 1), Vector2(sx + sw * 0.25, top - sh), Vector2(sx + sw, top - sh), Vector2(sx + sw, top + 1)])
			p.poly(pts3, (pal.base as Color))
			p.hline(int(sx + sw * 0.25), top - sh, int(sw * 0.75), (pal.hi as Color))
			p.vline(sx + sw - u, top - sh + 1, sh, CarGen.WELL)
			p.poly_outline(pts3, CarGen.INK)
		if String(mods.get("hood", "stock")) == "vented":
			var hx0 := int(X(float(d.cowl_x))) + int(lf * 0.03)
			for k in 3:
				var vx := hx0 + k * 4 * u
				var vy := _first_body(vx) + u
				p.hline(vx, vy, 2 * u, CarGen.INK)

	# ------------------------------------------------------------ trucks and 4x4s

	func _truck_things() -> void:
		var art: Dictionary = d.art
		var r := r_tire
		if d.rear == "pickup":
			var bx0 := int(X(0.004 + rear * 0.16))
			var bx1 := int(X(float(d.cab_x))) - 2
			var rail := int(Y(float(d.bed_h)))
			if d.body == "tow":
				_wrecker(bx0, bx1, rail)
			elif String(mods.get("bed", "stock")) == "tonneau":
				p.rect(bx0, rail - 2 * u, bx1 - bx0, 2 * u, CarGen.TRIM)
				p.hline(bx0, rail - 2 * u, bx1 - bx0, Color("3a3e46"))
				p.frame(bx0 - 1, rail - 2 * u - 1, bx1 - bx0 + 2, 2 * u + 2, CarGen.INK)
			else:
				# the bed's top rail and the gap to the cab
				for xx in range(bx0 + u, bx1):
					if on_paint(xx, rail + u + 1): p.img.set_pixel(xx, rail + u + 1, gap_c())
				for yy in range(rail, int(Y(float(d.rocker))) - u):
					if on_paint(bx1 + 1, yy): p.img.set_pixel(bx1 + 1, yy, CarGen.WELL)
				# the tailgate
				var tgx := bx0 + int(lf * 0.012)
				for yy in range(rail + 2 * u, int(Y(float(d.tail_bot))) - 2 * u):
					gap_px(tgx, yy)
			if art.has("toolbox"):
				p.rect(bx0 + u, rail - int(lf * 0.03), bx1 - bx0 - 2 * u, int(lf * 0.03), CarGen.CHROME[1])
				for k in 4: p.vline(bx0 + (bx1 - bx0) * k / 4 + u, rail - int(lf * 0.03), int(lf * 0.03), CarGen.CHROME[0])
				p.frame(bx0, rail - int(lf * 0.03) - 1, bx1 - bx0 - u, int(lf * 0.03) + 1, CarGen.INK)
			if art.has("ladder"):
				var ly := _first_body(int(X(float(d.roof_f))) - 2) - 3 * u
				p.hline(bx0, ly, int(X(float(d.roof_f))) - bx0, CarGen.TRIM)
				p.vline(bx0 + u, ly, rail - ly, CarGen.TRIM)
				p.vline(bx1 - u, ly, rail - ly, CarGen.TRIM)
				p.hline(bx0, ly - 2 * u, int(lf * 0.45), Color("c8a030"))
				for k in 8: p.vline(bx0 + k * int(lf * 0.055), ly - 2 * u, 2 * u, Color("8a7020"))
			if mods.get("spare", false) or (art.has("spare") and d.family == "pickup"):
				var sr := r * 0.75
				CarGen.wheel(p, bx0 + int(lf * 0.22), rail - int(sr * 0.55), sr, "beadlock", false, { "tire_kind": "mud" })
			if mods.get("rollbar", false):
				var rb := Color("2a2e36")
				var rx0 := bx1 - int(lf * 0.12)
				var top := rail - int(lf * 0.12)
				for w3 in 2 * u: p.line(rx0 + w3, rail, rx0 + int(lf * 0.07) + w3, top, rb)
				p.rect(rx0 + int(lf * 0.07), top, int(lf * 0.06), 2 * u, rb)
				p.vline(bx1 - 2 * u, top, rail - top, rb)
				p.vline(bx1 - u, top, rail - top, rb)
				if mods.get("lightbar", false):
					for k in 4:
						var lx2 := rx0 + int(lf * 0.06) + k * 5 * u
						p.disc(lx2, top - 3 * u, 2.2 * u, Color("f4f4ec"))
						p.ring(lx2, top - 3 * u, 2.4 * u, CarGen.INK)
		elif d.rear == "boxtruck":
			var bxx := int(X(float(d.box_x))) - 1
			if bxx < int(X(0.99)):
				for yy in range(_first_body(bxx - 2), int(Y(float(d.rocker)))):
					if on_paint(bxx, yy): p.img.set_pixel(bxx, yy, CarGen.WELL)
			# the box: ribbed sides and a roll-up door line at the back
			var bt := _first_body(int(X(0.1)))
			var bb := int(Y(float(d.clear))) - 1
			for k in range(1, 6):
				var xx2 := int(X(float(d.box_x) * float(k) / 6.0))
				for yy in range(bt + 2, bb):
					if on_paint(xx2, yy): p.img.set_pixel(xx2, yy, (pal.mid as Color))
			p.hline(int(X(0.0)), bb - int(lf * 0.02), int(X(float(d.box_x))) - int(X(0.0)), CarGen.TRIM)
		# a spare on the back door, a snorkel, a bull bar, a plow
		if art.has("spare") and d.family in ["offroad", "suv"] and not mods.get("spare", false) or (mods.get("spare", false) and d.family in ["offroad", "suv"]):
			var sr2 := r * 0.85
			var sx2 := int(X(rear * 0.16)) - int(sr2 * 0.3)
			var sy2 := int(Y(float(d.belt_r) - 0.02))
			_spare(sx2, sy2, sr2)
		if art.has("snorkel"):
			var snx := int(X(float(d.a_bot))) + int(lf * 0.02)
			var sny := int(Y(float(d.belt_f))) + int(lf * 0.03)
			var tpy := _first_body(int(X(float(d.roof_f)))) - u
			p.rect(snx, tpy, 2 * u + 1, sny - tpy, CarGen.TRIM)
			p.rect(snx - 2 * u, tpy - u, 4 * u, 2 * u, CarGen.TRIM)
			p.frame(snx - 2 * u - 1, tpy - u - 1, 4 * u + 2, 2 * u + 2, CarGen.INK)
		if art.has("bullbar") or mods.get("bash", false):
			var bx := int(X(1.0 - front * 0.2))
			var by := int(Y(float(d.nose_bot))) - int(lf * 0.03)
			var tube := Color("2a2e36") if not art.has("bullbar") else CarGen.CHROME[1]
			p.rect(bx - int(lf * 0.03), by, int(lf * 0.05), 2 * u, tube)
			p.rect(bx + int(lf * 0.012), by - int(lf * 0.03), 2 * u, int(lf * 0.07), tube)
			p.line(bx - int(lf * 0.03), by + 2 * u, bx - int(lf * 0.05), int(sill) + 3 * u, tube)
			p.frame(bx - int(lf * 0.03) - 1, by - 1, int(lf * 0.05) + 2, 2 * u + 2, CarGen.INK)
			p.frame(bx + int(lf * 0.012) - 1, by - int(lf * 0.03) - 1, 2 * u + 2, int(lf * 0.07) + 2, CarGen.INK)
		if art.has("plow"):
			var px0 := int(X(1.0)) + int(lf * 0.02)
			var py0 := int(Y(float(d.hood_h)))
			var pts := PackedVector2Array([Vector2(px0, py0), Vector2(px0 + lf * 0.05, py0 - lf * 0.01), Vector2(px0 + lf * 0.04, gy - 1), Vector2(px0 - lf * 0.01, gy - 2)])
			p.poly(pts, Color("e8b020"))
			p.line(px0, py0, px0 + int(lf * 0.05), py0 - int(lf * 0.01), Color("f8d860"))
			p.poly_outline(pts, CarGen.INK)
			p.line(px0 - int(lf * 0.02), int(Y(float(d.nose_bot))), px0, int(Y(float(d.nose_bot))) - u, CarGen.TRIM)
		if d.step and lod >= 1:
			var st0 := int(wheels[0][1] + arch_r) + u
			var st1 := int(wheels[1][1] - arch_r) - u
			var sty := int(sill) + u
			p.rect(st0, sty, st1 - st0, 2 * u, CarGen.TRIM)
			p.hline(st0, sty, st1 - st0, Color("5a5e66"))
			p.frame(st0 - 1, sty - 1, st1 - st0 + 2, 2 * u + 2, CarGen.INK)
		if d.mudflaps and lod >= 1:
			for wv: Array in wheels:
				var mx := int(float(wv[1]) - arch_r * 0.95) - u
				var my := int(float(wv[3].y))
				var mh := gy - my - int(lf * 0.025)
				p.rect(mx, my, maxi(2, u + 1), mh, CarGen.RUBBER)
				p.frame(mx - 1, my - 1, maxi(2, u + 1) + 2, mh + 2, CarGen.INK)

	func _spare(sx: int, sy: int, sr: float) -> void:
		p.rect(sx - int(sr * 0.25), sy - int(sr), int(sr * 0.55), int(sr * 2.0), CarGen.TIRE)
		p.vline(sx - int(sr * 0.25), sy - int(sr) + 1, int(sr * 2.0) - 2, Color("3a3e46"))
		p.frame(sx - int(sr * 0.25) - 1, sy - int(sr) - 1, int(sr * 0.55) + 2, int(sr * 2.0) + 2, CarGen.INK)

	## The wrecker's body: side boxes over the rear wheel, and the boom up the back.
	func _wrecker(bx0: int, bx1: int, rail: int) -> void:
		p.rect(bx0, rail - int(lf * 0.02), bx1 - bx0, int(lf * 0.02), CarGen.CHROME[1])
		for k in 3: p.vline(bx0 + (bx1 - bx0) * k / 3, rail - int(lf * 0.02), int(Y(float(d.rocker))) - rail, gap_c())
		var bxx := int(X(0.38))
		var byy := int(float(gy) - 0.25 * lf)
		for w4 in u + 1:
			p.line(bxx, byy + w4, int(X(0.05)), int(float(gy) - 0.42 * lf) + w4, Color("e8b020") if w4 == 0 else CarGen.INK)
		p.line(int(X(0.05)), int(float(gy) - 0.42 * lf), int(X(0.04)), int(float(gy) - 0.2 * lf), Color("6a6a6e"))
		p.rect(int(X(0.03)), int(float(gy) - 0.2 * lf), 3 * u, 3 * u, Color("3a3a3e"))
		p.rect(int(X(0.47)), int(Y(float(d.h))) - 2 * u, int(lf * 0.11), 2 * u, Color("e8a020"))
		p.rect(int(X(0.47)), int(Y(float(d.h))) - 2 * u, 3 * u, 2 * u, Color("e03020"))
		p.text(int(X(0.12)), int(float(gy) - 0.18 * lf), "TOW", Color("e8b020"))

	# ------------------------------------------------------------ kits

	func _kit() -> void:
		var kit: Dictionary = mods.get("kit", {})
		var ra: Vector2 = wheels[0][3]
		var fa: Vector2 = wheels[1][3]
		var nose := int(X(1.0 - front * 0.2)) - 1
		var tail := int(X(rear * 0.16))
		if kit.get("lip", false) and front < 0.5:
			_under(int(fa.x + arch_r) + u, nose - u, 2 * u, CarGen.TRIM, Color("3a3e46"))
		if kit.get("skirts", false):
			_under(int(ra.x + arch_r) + u, int(fa.x - arch_r) - u, 2 * u, (pal.sh as Color), (pal.base as Color))
		if kit.get("diffuser", false):
			var d0 := tail + 3 * u
			var d1 := int(ra.x - arch_r) - u
			_under(d0, d1, u + 1, CarGen.TRIM, CarGen.TRIM)
			for k in 4:
				var fx2 := d0 + int(float(d1 - d0) * (0.15 + 0.23 * float(k)))
				var fy2 := _bottom(fx2) + 2
				p.vline(fx2, fy2, 3 * u, CarGen.INK)
		var ex := String(mods.get("exhaust", d.get("exhaust", "single")))
		var tip_r := maxf(1.5, 1.6 * float(u))
		if ex == "side":
			var sx := int(wheels[0][1] + arch_r) + 3 * u
			for k in 2:
				var tx2 := sx + k * int(tip_r * 2.0 + float(u))
				var ty3 := _bottom(tx2) + int(tip_r * 0.6)
				p.disc(tx2, ty3, tip_r + 1.0, CarGen.INK)
				p.disc(tx2, ty3, tip_r, CarGen.CHROME[2])
				p.disc(tx2, ty3, tip_r * 0.5, Color("2a2e36"))
		elif ex == "single":
			var tx := tail + 3 * u
			p.rect(tx, _bottom(tx) + 1, 3 * u, u + 1, CarGen.TRIM)
		else:
			var tips := 2 if ex == "dual" else 3
			for k in tips:
				var tx := tail + 3 * u + k * int(tip_r * 2.0 + float(u))
				var ty3 := _bottom(tx) + int(tip_r * 0.6)
				p.disc(tx, ty3, tip_r + 1.0, CarGen.INK)
				p.disc(tx, ty3, tip_r, CarGen.CHROME[2])
				p.disc(tx, ty3, tip_r * 0.5, Color("2a2e36"))

	func _bottom(xx: int) -> int:
		if xx < 0 or xx >= w: return gy
		var b := bot_y[xx]
		return b if b >= 0 else int(sill)

	## A strip hung under the body between x0 and x1, ink round it.
	func _under(x0: int, x1: int, depth: int, c: Color, top: Color) -> void:
		if x1 <= x0: return
		for xx in range(x0, x1):
			var by := _bottom(xx)
			p.px(xx, by + 1, CarGen.INK)
			for k in depth: p.px(xx, by + 2 + k, top if k == 0 else c)
			p.px(xx, by + 2 + depth, CarGen.INK)
		for e: int in [x0 - 1, x1]:
			var by2 := _bottom(e if e >= x0 else x0)
			p.vline(e, by2 + 1, depth + 2, CarGen.INK)

	# ------------------------------------------------------------ wheels

	## The dark inside of each wheel arch, behind the tyre.
	func _wells() -> void:
		for wv: Array in wheels:
			if skirted(wv): continue
			var ac: Vector2 = wv[3]
			var ra := arch_r * (1.06 if wv[0] == "rear" and d.art.has("dually") else 1.0)
			for yy in range(int(ac.y - ra) - 1, mini(hgt, int(sill) + 3)):
				for xx in range(int(ac.x - ra) - 1, int(ac.x + ra) + 2):
					if xx < 0 or xx >= w or yy < 0 or float(yy) > sill + 1.0: continue
					if in_arch(float(xx) + 0.5 - ac.x, float(yy) + 0.5 - ac.y, ra - 0.6) and p.img.get_pixel(xx, yy).a < 0.6:
						p.img.set_pixel(xx, yy, CarGen.WELL)
			# the inner fender's lip just inside the arch
			if lod >= 1:
				for k in 24:
					var a := PI + PI * float(k) / 23.0
					var qx := int(ac.x + cos(a) * (ra - 1.5))
					var qy := int(ac.y + sin(a) * (ra - 1.5))
					if p.get_px(qx, qy) == CarGen.WELL: p.img.set_pixel(qx, qy, Color("1c2026"))

	## Fender flares: the drift kit's bolt-ons, a rally car's box arches, a dually's hips.
	func _flares() -> void:
		var style := "none"
		if String(mods.get("fenders", "stock")) == "flared": style = "bolt"
		elif d.flare != "none": style = String(d.flare)
		if style == "none": return
		for wv: Array in wheels:
			if style == "bulge" and wv[0] == "front" and d.art.has("dually"): continue
			var ac: Vector2 = wv[3]
			var fr := arch_r + (3.0 if style != "box" else 4.0) * float(u)
			var c: Color = (pal.base as Color) if style != "bolt" else (pal.base as Color)
			for k in 64:
				var a := PI + PI * float(k) / 63.0
				for t2 in 3 * u + 1:
					var rr := fr - float(t2)
					var qx := int(ac.x + cos(a) * rr * (1.08 if style == "box" else 1.0))
					var qy := int(ac.y + sin(a) * rr)
					if float(qy) <= sill + float(u):
						var shade := c if t2 > 0 else (pal.hi as Color)
						p.px(qx, qy, CarGen.INK if t2 == 3 * u else shade)
			# and an ink line on the outside of the flare
			for k in 64:
				var a2 := PI + PI * float(k) / 63.0
				var qx2 := int(ac.x + cos(a2) * (fr + 1.0) * (1.08 if style == "box" else 1.0))
				var qy2 := int(ac.y + sin(a2) * (fr + 1.0))
				if float(qy2) <= sill + float(u) and p.get_px(qx2, qy2).a < 0.5: p.px(qx2, qy2, CarGen.INK)
			if style == "bolt":
				for k in 5:
					var a3 := PI + PI * (0.15 + 0.7 * float(k) / 4.0)
					p.px(int(ac.x + cos(a3) * (fr - 1.5 * u)), int(ac.y + sin(a3) * (fr - 1.5 * u)), CarGen.CHROME[2])

	func _wheels() -> void:
		var look := CarGen.wheel_look(d, mods, len)
		var rim: String = look[0]
		var wm: Dictionary = look[1]
		for wv: Array in wheels:
			var cx := int(round(float(wv[1])))
			var cy := int(round(float(wv[2])))
			if String(dmg.get("wheel_off", "")) == String(wv[0]):
				# just the hub, on the ground, and the brake rotor glowing a bit
				p.disc(cx, cy + 2, r_tire * 0.6, Color("6a5a50"))
				p.ring(cx, cy + 2, r_tire * 0.6, CarGen.INK)
				p.disc(cx, cy + 2, r_tire * 0.25, Color("8a8a8e"))
				p.rect(cx - int(r_tire * 0.7), cy - int(r_tire * 0.2), 2 * u, int(r_tire), Color("b8603a"))
				continue
			var flat: bool = String(dmg.get("flat", "")) == String(wv[0])
			if skirted(wv):
				# the wheel peeks out under the skirt: paint it aside, keep only what's below the body
				var size := int(r_tire * 2.0) + 6
				var tmp := Pix.new(size, size, 1)
				CarGen.wheel(tmp, size / 2, size / 2, r_tire, rim, flat, wm)
				for yy in size:
					for xx in size:
						var c := tmp.img.get_pixel(xx, yy)
						var tx := cx - size / 2 + xx
						var ty := cy - size / 2 + yy
						if c.a > 0.0 and not body_at(tx, ty) and float(ty) > sill: p.px(tx, ty, c)
				_skirt(wv[3])
				continue
			if wv[0] == "rear" and d.art.has("dually"): wm.dually = true
			else: wm.erase("dually")
			CarGen.wheel(p, cx, cy, r_tire, rim, flat, wm)

	## A fender skirt over the rear wheel: the body carries on over the top half of it.
	func _skirt(ac: Vector2) -> void:
		var ra := arch_r
		var bottom := int(sill)
		p.hline(int(ac.x - ra) - 1, bottom + 1, int(ra * 2.0) + 3, CarGen.INK)
		# the skirt's edge: a shut line round the arch, and a chrome lip along the bottom
		for k in 40:
			var a := PI + PI * float(k) / 39.0
			var qx := int(ac.x + cos(a) * ra)
			var qy := int(ac.y + sin(a) * ra)
			if qy < bottom: gap_px(qx, qy)
		p.hline(int(ac.x - ra), bottom, int(ra * 2.0) + 1, CarGen.CHROME[2])

	# ------------------------------------------------------------ crashes

	func _damage_fx() -> void:
		if dmg.get("glass", false) and not glass.is_empty():
			var cx := int(X(lerpf(float(d.dlo_r), float(d.a_bot), 0.7)))
			var cy := int(Y(float(d.belt_f)) - lf * 0.05)
			for k in 7:
				var a := TAU * float(k) / 7.0 + 0.3
				var ex := cx + int(cos(a) * lf * 0.08)
				var ey := cy + int(sin(a) * lf * 0.05)
				var steps := maxi(2, int(lf * 0.08))
				for s in steps:
					var qx := cx + (ex - cx) * s / steps
					var qy := cy + (ey - cy) * s / steps
					if glass_at(qx, qy): p.img.set_pixel(qx, qy, Color("c8d4e0"))
		if front > 0.3 and lod >= 1:
			# the crumple: buckles in the hood and the fender
			var nx := int(X(1.0 - front * 0.2))
			for k in 3:
				var bx := nx - int(lf * (0.05 + 0.05 * k))
				for yy in range(_first_body(bx), int(Y(float(d.rocker)))):
					if on_paint(bx, yy) and (yy + k) % 3 != 0: p.img.set_pixel(bx, yy, gap_c())
		if rear > 0.3 and lod >= 1:
			var tx := int(X(rear * 0.16))
			for k in 2:
				var bx2 := tx + int(lf * (0.05 + 0.05 * k))
				for yy in range(_first_body(bx2), int(Y(float(d.rocker)))):
					if on_paint(bx2, yy) and (yy + k) % 3 != 0: p.img.set_pixel(bx2, yy, gap_c())
		var smoke := float(dmg.get("smoke", 0.0))
		if smoke > 0.0:
			var sx2 := int(X(0.85 - front * 0.18))
			var by := Y(float(d.belt_f))
			for k in int(6 + smoke * 10.0):
				p.glow(sx2 - k * 2 + int(sin(float(k)) * 3.0), int(by) - 3 - k * 3, (2.0 + float(k) * 0.6) * u, Color(0.82, 0.82, 0.84), 1.0 - float(k) * 0.04)
		var drv: Dictionary = dmg.get("driver", {})
		if not drv.is_empty():
			var cuts: Array = d.door_cuts
			var wx := int(X(float(cuts[0][1]) + 0.05)) if cuts.size() > 0 else int(X(0.5))
			var wy := int(Y(float(d.belt_f)))
			var sk: Color = drv.get("skin", Color("dcae88"))
			var hc: Color = drv.get("hair", Color("3b2a1e"))
			p.rect(wx - 5 * u, wy - 6 * u, 6 * u, 6 * u, hc)
			if drv.get("long_hair", false): p.rect(wx - 3 * u, wy, 3 * u, int(lf * 0.1), hc)
			if drv.get("sleeve", null) != null: p.rect(wx - u, wy - u, 3 * u, 3 * u, drv.sleeve)
			p.rect(wx - u, wy + 2 * u, 3 * u, int(lf * 0.1), sk)
			p.rect(wx - u, wy + 2 * u + int(lf * 0.1), 3 * u, 3 * u, sk.darkened(0.08))

# ================================================================== wheels

## One wheel, pixel by pixel: a tyre with its sidewall lit from the upper left (whitewalls or
## raised white letters by era, mud lugs, a thin low-profile), then the rim: a polished lip, the
## barrel's depth, the face (spokes, mesh, a dish, steel with holes, a hubcap, wire), and through
## the gaps the brake rotor and the caliper, lug nuts and a centre cap.
## mods: tire_kind (stock, mud, lowpro), rim_size, rim_color, caliper, wall (none, white,
## letters), lugs, dually, simple (no small parts).
static func wheel(p: Pix, cx: int, cy: int, r: float, rim: String, flat := false, mods := {}, spin := 0.0) -> void:
	var ry := r * (0.84 if flat else 1.0)
	var ccy := float(cy) + (r - ry)
	var kind := String(mods.get("tire_kind", "stock"))
	var size := clampf(float(mods.get("rim_size", 0.66 if kind != "lowpro" else 0.78)), 0.42, 0.86)
	if kind == "mud": size = minf(size, 0.6)
	var rr := r * size
	var rc := _col(mods.get("rim_color", null), Color("c9ced6") if not rim in ["beadlock", "steel"] else (Color("2a2e36") if rim == "beadlock" else Color("d8dce2")))
	if rim == "deepdish" and not mods.has("rim_color"): rc = Color("dfe3e8")
	if rim in ["wire", "hubcap", "dish"] and not mods.has("rim_color"): rc = Color("dde3ea")
	var cal := _col(mods.get("caliper", null), Color("5a5e66"))
	var wall := String(mods.get("wall", "none"))
	var simple: bool = mods.get("simple", false) or r < 5.0
	var lugs := int(mods.get("lugs", 5))
	var light := Vector2(-0.62, -0.78)
	var hi := rc.lerp(Color.WHITE, 0.55)
	var lo := rc.darkened(0.45)
	var dark := Color("14171c")
	var rotor := Color("3c4149")
	var tire_c: Array[Color] = [Color("121418"), Color("1c1f25"), Color("272b32"), Color("343942"), Color("454b55")]
	var lip_w := maxf(1.0, rr * (0.1 if rim != "deepdish" else 0.26))
	var x0 := int(floor(float(cx) - r - 2.0))
	var x1 := int(ceil(float(cx) + r + 2.0))
	var y0 := int(floor(ccy - ry - 2.0))
	var y1 := int(ceil(ccy + ry + 1.0))
	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			var dx := float(xx) - float(cx)
			var dy := float(yy) - ccy
			var q := (dx * dx) / (r * r) + (dy * dy) / (ry * ry)
			var dist := sqrt(dx * dx + dy * dy)
			if q > 1.0:
				# mud tyres: knobs standing proud of the round
				if kind == "mud" and q < 1.14:
					var a0 := atan2(dy, dx) + spin * 0.5
					if fposmod(a0 * 16.0 / TAU, 1.0) < 0.5: p.px(xx, yy, tire_c[0])
				continue
			var a := atan2(dy, dx)
			var nd := Vector2(dx, dy) / maxf(0.01, dist)
			var lit := nd.dot(light)          # -1 facing away .. 1 facing the light
			if dist > rr:
				# the tyre
				var t := (dist - rr) / maxf(0.5, r - rr)
				var c: Color
				if q > 0.86 or t > 0.9: c = tire_c[0]
				else:
					var k := 1 + int(clampf((lit + 1.0) * 0.5 * 3.0 + (0.4 if t < 0.35 else 0.0), 0.0, 2.99))
					c = tire_c[k]
					if kind == "mud" and t > 0.7 and fposmod((a + spin * 0.5) * 16.0 / TAU, 1.0) < 0.3: c = tire_c[0]
					if wall == "white" and not simple and t > 0.25 and t < 0.6: c = Color("e8e6dc") if lit > -0.3 else Color("b8b6ac")
					if wall == "letters" and not simple and t > 0.38 and t < 0.6 and a < -0.6 and a > -2.5:
						var sa := fposmod((a - spin) * 30.0 / TAU, 1.0)
						if sa < 0.55 and int((a - spin) * 30.0 / TAU) % 4 != 3: c = Color("e8e4d8")
				p.px(xx, yy, c)
				continue
			if flat: dy = float(yy) - ccy
			var rt := dist / rr
			var ang := a - spin
			var c2: Color
			if dist > rr - lip_w:
				# the polished lip
				c2 = hi if lit > 0.2 else (rc if lit > -0.4 else lo)
				if lit > 0.75: c2 = Color.WHITE
				if rim == "deepdish": c2 = Color("f4f6f8") if lit > 0.0 else Color("9aa0a8")
				p.px(xx, yy, c2)
				continue
			if dist > rr - lip_w - maxf(1.0, rr * 0.08) and not rim in ["hubcap", "dish"]:
				# the barrel: the inside of the rim, darker away from the light
				c2 = rc.darkened(0.55) if lit > 0.0 else rc.darkened(0.3)
				p.px(xx, yy, c2)
				continue
			var face := _rim_face(rim, rt, ang, lit, rc, hi, lo, simple)
			if face.a < 0.5:
				# a gap: the brakes behind, in the dark
				if rt > 0.44 and absf(ang + 0.75) < 0.4 and rt < 0.86 and not simple:
					c2 = cal if lit > -0.2 else cal.darkened(0.25)
					if rt > 0.82 or absf(ang + 0.75) > 0.33: c2 = cal.darkened(0.4)
				elif rt > 0.5 and rt < 0.88 and not simple:
					c2 = rotor if lit > 0.2 else rotor.darkened(0.25)
				else:
					c2 = dark
				p.px(xx, yy, c2)
				continue
			p.px(xx, yy, face)
	# lug nuts and the centre cap
	if not simple and not rim in ["hubcap", "wire"]:
		for k in lugs:
			var la := TAU * float(k) / float(lugs) + spin - PI / 2.0
			var lx := float(cx) + cos(la) * rr * 0.26
			var ly := ccy + sin(la) * rr * 0.26
			p.px(int(round(lx)), int(round(ly)), lo.darkened(0.2) if rim != "steel" else Color("3a3e46"))
	if rim == "wire" and not simple:
		# a knock-off spinner
		for k in 2:
			var sa2 := spin + PI * float(k) + 0.4
			p.line(cx, int(ccy), cx + int(cos(sa2) * rr * 0.32), int(ccy + sin(sa2) * rr * 0.32), Color("f4f6f8"))
	var cap := maxf(1.0, rr * 0.13)
	p.disc(cx, int(ccy), cap, rc.lerp(Color.WHITE, 0.2) if rim != "beadlock" else Color("3a3e46"))
	p.px(cx - 1, int(ccy) - 1, Color.WHITE)
	if not simple and cap > 1.5: p.ring(cx, int(ccy), cap + 0.5, lo)
	p.ellipse(cx, int(ccy), r + 1.0, ry + 1.0, Color(0, 0, 0, 0))
	if mods.get("dually", false) and not simple:
		# the dually's hub sticks out past the tyre
		p.disc(cx, int(ccy), rr * 0.42, Color("b8c0c8"))
		p.ring(cx, int(ccy), rr * 0.42, lo)
		p.disc(cx, int(ccy), rr * 0.2, Color("8a9098"))

## The colour of a rim's face at (radius fraction, angle), or a transparent colour for a gap.
static func _rim_face(rim: String, rt: float, ang: float, lit: float, rc: Color, hi: Color, lo: Color, simple: bool) -> Color:
	var gap := Color(0, 0, 0, 0)
	var shade := hi if lit > 0.35 else (rc if lit > -0.35 else lo)
	match rim:
		"fivespoke", "tenspoke", "multispoke", "beadlock":
			var n: int = { "fivespoke": 5, "tenspoke": 10, "multispoke": 15, "beadlock": 6 }[rim]
			if simple: n = mini(n, 6)
			if rt < 0.3: return rc if rt > 0.2 else shade
			if rim == "beadlock" and rt > 0.84: return Color("3a3e46") if fposmod(ang * 14.0 / TAU, 1.0) > 0.3 else Color("c9cfd6")
			var seg := TAU / float(n)
			var off := fposmod(ang + PI / 2.0, seg) - seg * 0.5
			var half := seg * lerpf(0.34 if n <= 6 else 0.26, 0.18 if n <= 6 else 0.14, rt)
			if absf(off) > half: return gap
			# each spoke catches the light along one edge
			var side_lit := (off < 0.0) == (sin(ang) < 0.0)
			if absf(off) > half * 0.6 and side_lit and n <= 6: return hi
			return rc if lit > -0.45 else rc.darkened(0.22)
		"mesh":
			if rt < 0.28: return shade
			if rt > 0.9: return rc
			var k1 := fposmod(ang * 14.0 / TAU + rt * 2.2, 1.0)
			var k2 := fposmod(ang * 14.0 / TAU - rt * 2.2, 1.0)
			if k1 < 0.22 or k2 < 0.22: return hi if lit > 0.0 else rc
			return gap
		"wire":
			if rt < 0.24: return shade
			var k3 := fposmod(ang * 24.0 / TAU + rt * 3.0, 1.0)
			var k4 := fposmod(ang * 24.0 / TAU - rt * 3.0, 1.0)
			if k3 < 0.16 or k4 < 0.16: return Color("eef2f6") if lit > -0.2 else Color("a8b0b8")
			return gap
		"turbofan":
			if rt < 0.3 or rt > 0.86: return shade
			if fposmod(ang * 12.0 / TAU + rt * 1.4, 1.0) < 0.38: return gap
			return rc.lightened(0.1) if lit > 0.0 else rc.darkened(0.15)
		"deepdish":
			if rt > 0.62: return Color("8a9098") if rt < 0.66 else (Color("e8ecf0") if lit > 0.0 else Color("a8aeb6"))
			if rt < 0.22: return shade
			var off2 := fposmod(ang, TAU / 8.0) - TAU / 16.0
			if absf(off2) < 0.16: return rc.darkened(0.3) if lit < 0.0 else rc
			return gap
		"dish":
			if rt > 0.78: return rc.darkened(0.1)
			if rt < 0.5 and lit > 0.2: return hi
			return rc if lit > -0.3 else lo
		"steel":
			if rt > 0.84: return lo
			if rt > 0.5 and rt < 0.68:
				var off3 := fposmod(ang, TAU / 6.0) - TAU / 12.0
				if absf(off3) < 0.22: return gap
			if rt < 0.36: return hi if lit > 0.0 else rc
			return rc if lit > -0.4 else lo
		"hubcap":
			if rt > 0.88: return Color("c8ccd4")
			if absf(rt - 0.62) < 0.05: return Color("8a8e96")
			if rt < 0.3: return Color("f4f6f8") if lit > 0.0 else Color("b8bcc4")
			return Color("e8ecf0") if lit > 0.2 else (Color("c8ccd4") if lit > -0.4 else Color("9a9ea6"))
	return shade

# ================================================================== the cars everybody knows

## Per-car corrections on top of the rules, keyed by catalogue id. Metres for the skeleton
## (H, hood_h, cowl_d, rake, tail_h, deck, bl_rake...), names for the details (head, tail_lamp,
## bumper, rim_style, wall, arch, flare...).
const ICONS := {
	# --- the hand-made cars: the '91 Silvio, Dad's Supreem, the Charjer, the wrecker
	"silvio": { "H": 1.29, "hood_h": 0.64, "cowl_rise": 0.21, "cowl_d": 1.74, "rake": 60.0, "belt_up": 0.0, "kick": 0.02, "tail_h": 0.93,
		"deck": 0.62, "bl_rake": 60.0, "crown": 0.03, "c_top": 0.1, "c_bot": -0.12, "soft": 0.9, "nose_drop": 0.16, "nose_round": 0.09,
		"head": "jewel", "tail_lamp": "wrap", "rim_style": "mesh", "trim": [], "crease": 0.42, "antenna": "none", "mirror": "body" },
	"supreem": { "H": 1.31, "rear": "hatch", "tail_x": 0.0, "hood_h": 0.66, "cowl_rise": 0.2, "cowl_d": 1.95, "rake": 58.0, "tail_h": 0.92,
		"bl_rake": 70.0, "c_top": 0.1, "c_bot": -0.2, "soft": 0.3, "crown": 0.012, "doors": 2, "nose_drop": 0.18, "head": "popup",
		"tail_lamp": "wrap", "bumper": "strip", "rim_style": "tenspoke", "trim": ["moulding"], "art": { "spoiler": true } },
	"charjer": { "H": 1.48, "hood_h": 0.88, "cowl_rise": 0.2, "cowl_d": 1.92, "rake": 63.0, "belt_up": 0.07, "kick": 0.06, "tail_h": 1.08,
		"deck": 0.48, "bl_rake": 68.0, "c_top": 0.08, "c_bot": -0.3, "crown": 0.03, "soft": 0.85, "head": "swept", "tail_lamp": "racetrack",
		"rim_style": "fivespoke", "rim_frac": 0.72, "crease": 0.5, "art": { "spoiler": true } },
	# --- pony cars and muscle
	"fjord_mustank_1966": { "H": 1.3, "hood_h": 0.75, "cowl_rise": 0.10, "cowl_d": 2.0, "rake": 50.0, "deck": 0.58, "tail_h": 0.88, "bl_rake": 54.0,
		"kick": 0.03, "soft": 0.45, "side_vent": "scoop_side", "head": "round", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "none" },
	"fjord_mustank_fastback_1969": { "rear": "fast", "H": 1.29, "hood_h": 0.75, "cowl_rise": 0.09, "cowl_d": 2.1, "rake": 54.0, "tail_h": 0.9,
		"bl_rake": 75.0, "c_bot": -0.5, "kick": 0.03, "soft": 0.4, "side_vent": "scoop_side", "head": "quad", "tail_lamp": "bar", "hardtop": true,
		"rim_style": "fivespoke", "wall": "letters", "stripe_kind": "side" },
	"fjord_mustank_1988": { "rear": "fast", "H": 1.32, "hood_h": 0.72, "cowl_rise": 0.18, "cowl_d": 1.85, "rake": 58.0, "tail_h": 0.95, "bl_rake": 68.0,
		"c_bot": -0.25, "soft": 0.22, "head": "flush", "tail_lamp": "block", "bumper": "body", "rim_style": "turbofan", "trim": ["moulding"] },
	"fjord_mustank_2005": { "H": 1.41, "hood_h": 0.86, "cowl_rise": 0.2, "cowl_d": 1.98, "rake": 62.0, "deck": 0.5, "tail_h": 1.02, "bl_rake": 72.0,
		"c_bot": -0.3, "kick": 0.04, "soft": 0.7, "side_vent": "scoop_side", "head": "jewel", "tail_lamp": "block", "rim_style": "fivespoke" },
	"fjord_mustank_2018": { "H": 1.38, "hood_h": 0.82, "cowl_rise": 0.22, "cowl_d": 2.0, "rake": 64.0, "deck": 0.42, "tail_h": 1.0, "bl_rake": 74.0,
		"c_bot": -0.3, "kick": 0.05, "soft": 0.85, "head": "swept", "tail_lamp": "block", "rim_style": "multispoke", "rim_frac": 0.7 },
	"chevrolay_camareo_1969": { "H": 1.3, "hood_h": 0.73, "cowl_rise": 0.10, "cowl_d": 2.05, "rake": 54.0, "deck": 0.62, "tail_h": 0.9, "bl_rake": 62.0,
		"kick": 0.05, "soft": 0.45, "head": "round", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "letters", "stripe_kind": "side" },
	"chevrolay_camareo_1985": { "rear": "fast", "H": 1.28, "hood_h": 0.6, "cowl_rise": 0.28, "cowl_d": 2.05, "rake": 62.0, "tail_h": 0.92, "bl_rake": 74.0,
		"c_bot": -0.3, "soft": 0.25, "nose": "wedge", "nose_drop": 0.12, "head": "rect", "tail_lamp": "wrap", "bumper": "body", "rim_style": "fivespoke" },
	"chevrolay_camareo_1998": { "rear": "fast", "H": 1.3, "hood_h": 0.58, "cowl_rise": 0.3, "cowl_d": 2.1, "rake": 68.0, "tail_h": 0.98, "bl_rake": 76.0,
		"c_bot": -0.3, "soft": 0.9, "nose": "wedge", "nose_drop": 0.12, "nose_round": 0.14, "head": "flush", "tail_lamp": "wrap", "rim_style": "fivespoke" },
	"chevrolay_camareo_ess_ess_2016": { "H": 1.35, "hood_h": 0.86, "cowl_rise": 0.2, "cowl_d": 2.0, "rake": 64.0, "belt_up": 0.04,
		"deck": 0.5, "tail_h": 1.05, "bl_rake": 70.0, "c_bot": -0.3, "kick": 0.05, "soft": 0.85, "head": "swept", "tail_lamp": "block",
		"rim_style": "fivespoke", "rim_frac": 0.72 },
	"chevrolay_shovelle_ess_ess_1970": { "H": 1.33, "hood_h": 0.75, "cowl_rise": 0.10, "cowl_d": 2.15, "rake": 54.0, "deck": 0.78, "tail_h": 0.92,
		"bl_rake": 64.0, "c_bot": -0.25, "kick": 0.04, "soft": 0.4, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "dish",
		"wall": "letters", "stripe_kind": "racing" },
	"pontiak_g_t_whoa_1967": { "H": 1.33, "hood_h": 0.77, "cowl_rise": 0.09, "cowl_d": 2.15, "rake": 52.0, "deck": 0.8, "tail_h": 0.92, "bl_rake": 58.0,
		"kick": 0.07, "soft": 0.45, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "letters" },
	"pontiak_fireburd_trans_ammo_1979": { "rear": "fast", "H": 1.27, "hood_h": 0.7, "cowl_rise": 0.2, "cowl_d": 2.3, "rake": 58.0, "tail_h": 0.94,
		"bl_rake": 72.0, "c_bot": -0.22, "kick": 0.04, "soft": 0.4, "nose": "wedge", "head": "rect", "tail_lamp": "wrap", "side_vent": "vent",
		"rim_style": "tenspoke", "wall": "letters" },
	"pontiak_fireburd_1987": { "rear": "fast", "H": 1.27, "hood_h": 0.6, "cowl_rise": 0.27, "cowl_d": 2.05, "rake": 62.0, "tail_h": 0.93, "bl_rake": 74.0,
		"c_bot": -0.28, "soft": 0.3, "nose": "wedge", "nose_drop": 0.12, "tail_lamp": "wrap", "rim_style": "mesh", "bumper": "body" },
	"buickk_grand_nashunal_1987": { "H": 1.38, "hood_h": 0.8, "cowl_rise": 0.16, "cowl_d": 2.15, "rake": 54.0, "deck": 0.72, "tail_h": 0.97, "bl_rake": 38.0,
		"c_top": 0.22, "soft": 0.12, "head": "rect", "tail_lamp": "block", "bumper": "rubber", "rim_style": "fivespoke", "trim": ["moulding"] },
	"dodgy_charjer_1969": { "rear": "fast", "H": 1.34, "hood_h": 0.75, "cowl_rise": 0.10, "cowl_d": 2.25, "rake": 55.0, "tail_h": 0.92, "bl_rake": 70.0,
		"c_top": 0.08, "c_bot": -0.38, "kick": 0.07, "soft": 0.45, "head": "hidden", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel",
		"wall": "letters", "stripe_kind": "tail" },
	"dodgy_challenjer_1970": { "H": 1.29, "hood_h": 0.75, "cowl_rise": 0.09, "cowl_d": 2.1, "rake": 54.0, "deck": 0.6, "tail_h": 0.92, "bl_rake": 64.0,
		"c_bot": -0.18, "kick": 0.03, "soft": 0.4, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "letters", "stripe_kind": "side" },
	"plymooth_cudda_1970": { "H": 1.29, "hood_h": 0.73, "cowl_rise": 0.10, "cowl_d": 2.05, "rake": 54.0, "deck": 0.58, "tail_h": 0.9, "bl_rake": 64.0,
		"c_bot": -0.18, "kick": 0.03, "soft": 0.45, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "fivespoke", "wall": "letters",
		"stripe_kind": "hockey" },
	"dodgy_challenjer_hellcatt_2017": { "H": 1.45, "hood_h": 0.9, "cowl_rise": 0.16, "cowl_d": 2.15, "rake": 62.0, "belt_up": 0.06, "deck": 0.56,
		"tail_h": 1.06, "bl_rake": 66.0, "c_bot": -0.16, "kick": 0.03, "soft": 0.75, "head": "round", "tail_lamp": "racetrack", "rim_style": "fivespoke", "rim_frac": 0.74 },
	"plymooth_superburd_1970": { "H": 1.34, "hood_h": 0.62, "cowl_rise": 0.3, "cowl_d": 2.65, "rake": 55.0, "deck": 0.72, "tail_h": 0.93, "bl_rake": 64.0,
		"c_bot": -0.3, "nose": "wedge", "nose_drop": 0.1, "nose_round": 0.25, "nose_lean": 0.12, "nose_bot": 0.28, "head": "popup", "tail_lamp": "bar",
		"wing_kind": "tall", "rim_style": "steel", "wall": "letters" },
	"oldsmobeel_tornadoh_1967": { "rear": "fast", "H": 1.35, "hood_h": 0.77, "cowl_rise": 0.10, "cowl_d": 2.3, "rake": 55.0, "tail_h": 0.9, "bl_rake": 74.0,
		"c_bot": -0.4, "soft": 0.6, "head": "hidden", "tail_lamp": "bar", "flare": "bulge", "hardtop": true },
	"buickk_rivieruh_1971": { "rear": "fast", "H": 1.37, "hood_h": 0.77, "cowl_rise": 0.10, "cowl_d": 2.35, "rake": 56.0, "tail_h": 0.86, "bl_rake": 76.0,
		"c_bot": -0.5, "kick": 0.07, "soft": 0.7, "tail_x": 0.0, "hardtop": true, "tail_lamp": "bar" },
	"dodgy_wiper_1996": { "H": 1.12, "hood_h": 0.7, "cowl_rise": 0.16, "cowl_d": 2.15, "rake": 58.0, "tail_h": 0.86, "kick": 0.04, "soft": 1.0,
		"side_vent": "vent", "exhaust": "side", "rim_style": "fivespoke", "rim_frac": 0.7, "flare": "bulge" },
	"shelbee_kobrah_1965": { "H": 1.17, "hood_h": 0.7, "cowl_rise": 0.1, "cowl_d": 1.85, "rake": 50.0, "tail_h": 0.8, "soft": 1.4, "flare": "bulge",
		"exhaust": "side", "head": "round", "tail_lamp": "round", "rim_style": "fivespoke", "wall": "none", "stripe_kind": "racing" },
	# --- fifties chrome
	"cadillak_coupe_de_villain_1959": { "H": 1.38, "hardtop": true, "skirt": true, "head": "quad", "tail_lamp": "fin", "wall": "white", "rim_style": "hubcap" },
	"chevrolay_bel_err_1957": { "H": 1.5, "head": "round", "tail_lamp": "fin", "wall": "white", "rim_style": "hubcap", "skirt": false },
	"fjord_thunderburd_1957": { "H": 1.32, "hood_h": 0.8, "cowl_rise": 0.1, "cowl_d": 2.0, "rake": 40.0, "deck": 1.1, "tail_h": 0.86, "bl_rake": 30.0,
		"c_top": 0.2, "c_bot": 0.1, "quarter": false, "soft": 0.9, "head": "round", "tail_lamp": "fin", "wall": "white", "rim_style": "hubcap",
		"side_vent": "portholes_roof" },
	"chequer_marathone_1978": { "H": 1.6, "hood_h": 0.92, "cowl_rise": 0.1, "cowl_d": 1.95, "rake": 32.0, "deck": 0.8, "tail_h": 0.98, "bl_rake": 30.0,
		"soft": 0.45, "crown": 0.03, "head": "quad", "bumper": "chrome5", "rim_style": "hubcap" },
	# --- sports cars, then and now
	"chevrolay_corvet_1963": { "rear": "fast", "H": 1.26, "hood_h": 0.66, "cowl_rise": 0.2, "cowl_d": 2.15, "rake": 58.0, "tail_h": 0.8, "bl_rake": 76.0,
		"c_bot": -0.35, "kick": 0.05, "soft": 0.7, "nose": "wedge", "head": "hidden", "tail_lamp": "round", "side_vent": "vent", "rim_style": "dish", "wall": "white" },
	"chevrolay_corvet_1979": { "rear": "fast", "H": 1.21, "hood_h": 0.6, "cowl_rise": 0.3, "cowl_d": 2.4, "rake": 64.0, "tail_h": 0.92, "bl_rake": 70.0,
		"c_bot": -0.22, "kick": 0.08, "soft": 0.8, "nose": "wedge", "nose_drop": 0.1, "head": "popup", "tail_lamp": "round", "side_vent": "vent",
		"rim_style": "fivespoke", "wall": "letters", "bumper": "body" },
	"chevrolay_corvet_1997": { "head": "popup", "tail_lamp": "round" },
	"deloreon_dmz_twelve_1981": { "rear": "notch", "H": 1.14, "hood_h": 0.6, "cowl_rise": 0.26, "cowl_d": 1.55, "rake": 64.0, "deck": 0.45, "tail_h": 0.92,
		"bl_rake": 78.0, "c_top": 0.06, "c_bot": -0.08, "soft": 0.06, "nose": "wedge", "nose_drop": 0.14, "head": "rect", "tail_lamp": "block",
		"bumper": "rubber", "rim_style": "turbofan", "trim": ["moulding"], "art": { "louvers": true } },
	"fjord_gt_fourty_ish_2005": { "H": 1.12, "hood_h": 0.64, "cowl_rise": 0.2, "cowl_d": 1.72, "rake": 64.0, "deck": 0.95, "tail_h": 0.98, "bl_rake": 80.0,
		"soft": 1.0, "nose": "round", "head": "jewel", "tail_lamp": "round", "rim_style": "tenspoke", "art": { "louvers": true, "stripes": true } },
	"porch_neuner_1973": { "head": "round", "tail_lamp": "bar", "bumper": "chrome", "rim_style": "fivespoke" },
	"porch_neuner_turbo_1986": { "kick": 0.06, "head": "round", "tail_lamp": "bar", "bumper": "body", "rim_style": "fivespoke", "flare": "bulge",
		"wing_kind": "whale", "tire": 1.04 },
	"ferraree_testosterona_1987": { "H": 1.13, "hood_h": 0.6, "cowl_rise": 0.2, "cowl_d": 1.5, "rake": 66.0, "deck": 1.0, "tail_h": 0.98, "bl_rake": 82.0,
		"c_bot": -0.05, "soft": 0.15, "head": "popup", "tail_lamp": "block", "rim_style": "fivespoke" },
	"ferraree_eff_forty_1990": { "H": 1.12, "hood_h": 0.58, "cowl_rise": 0.22, "cowl_d": 1.5, "rake": 66.0, "deck": 0.9, "tail_h": 1.0, "bl_rake": 80.0,
		"soft": 0.4, "head": "popup", "tail_lamp": "round", "wing_kind": "deck", "rim_style": "fivespoke", "art": { "louvers": true } },
	"ferraree_three_oh_ate_1984": { "soft": 0.5, "head": "popup", "tail_lamp": "round", "rim_style": "fivespoke" },
	"ferraree_two_fifty_gee_tee_oh_no_1962": { "H": 1.2, "hood_h": 0.62, "cowl_rise": 0.2, "cowl_d": 2.0, "rake": 56.0, "tail_h": 0.88, "bl_rake": 70.0,
		"soft": 1.2, "side_vent": "vent", "head": "round", "tail_lamp": "round", "rim_style": "wire", "art": { "spoiler": true } },
	"lamberghini_coontash_1985": { "H": 1.07, "hood_h": 0.62, "cowl_rise": 0.2, "cowl_d": 1.25, "rake": 72.0, "deck": 0.95, "tail_h": 0.98, "bl_rake": 84.0,
		"c_top": 0.04, "c_bot": -0.04, "soft": 0.04, "nose_drop": 0.1, "nose_round": 0.03, "arch": "square", "head": "popup", "tail_lamp": "block",
		"rim_style": "steel", "rim_color": "c8ccd4" },
	"lamberghini_diabloh_1995": { "soft": 0.7, "rake": 70.0 },
	"lamberghini_meeura_1968": { "H": 1.06, "hood_h": 0.6, "cowl_rise": 0.18, "cowl_d": 1.55, "rake": 64.0, "deck": 0.95, "tail_h": 0.92, "bl_rake": 82.0,
		"soft": 1.4, "head": "round", "tail_lamp": "block", "rim_style": "steel", "art": { "louvers": true } },
	"jagwire_ee_typo_1965": { "H": 1.22, "hood_h": 0.64, "cowl_rise": 0.2, "cowl_d": 2.3, "rake": 58.0, "tail_h": 0.8, "bl_rake": 72.0, "soft": 1.6,
		"nose_round": 0.25, "nose_drop": 0.2, "head": "round", "tail_lamp": "round", "bumper": "chrome", "rim_style": "wire" },
	"aston_martian_double_bee_five_1964": { "rear": "fast", "H": 1.34, "hood_h": 0.74, "cowl_rise": 0.14, "cowl_d": 2.05, "rake": 52.0, "tail_h": 0.88,
		"bl_rake": 64.0, "soft": 1.0, "side_vent": "vent", "head": "round", "tail_lamp": "bar", "rim_style": "wire" },
	"mercedez_gullwinger_1955": { "rear": "fast", "H": 1.3, "hood_h": 0.76, "cowl_rise": 0.14, "cowl_d": 2.0, "rake": 46.0, "tail_h": 0.82, "bl_rake": 64.0,
		"soft": 1.5, "side_vent": "vent", "head": "round", "rim_style": "hubcap", "trim": ["arch_chrome"] },
	"austen_healthy_frog_eyed_spryte_1959": { "head": "frog", "rim_style": "steel" },
	"bugattee_veyrun_2008": { "soft": 1.0, "art": { "twotone": true } },
	"maclarence_eff_won_1994": { "soft": 0.9, "art": { "roofscoop": true } },
	"acurra_en_ess_eks_1991": { "H": 1.17, "hood_h": 0.62, "cowl_rise": 0.2, "cowl_d": 1.6, "rake": 66.0, "deck": 0.9, "tail_h": 1.0, "bl_rake": 78.0,
		"soft": 0.7, "head": "popup", "tail_lamp": "wrap", "rim_style": "multispoke", "art": { "blackroof": true } },
	# --- the JDM heroes
	"toyoda_supreem_twin_turbo_1995": { "rear": "fast", "H": 1.27, "hood_h": 0.64, "cowl_rise": 0.22, "cowl_d": 1.95, "rake": 64.0, "tail_h": 1.0,
		"bl_rake": 70.0, "c_bot": -0.25, "soft": 1.2, "head": "jewel", "tail_lamp": "round", "rim_style": "fivespoke", "trim": [] },
	"nissun_skylion_gee_tee_arr_1991": { "H": 1.34, "hood_h": 0.74, "cowl_rise": 0.17, "cowl_d": 1.82, "rake": 60.0, "deck": 0.55, "tail_h": 1.0,
		"bl_rake": 60.0, "soft": 0.45, "flare": "bulge", "head": "flush", "tail_lamp": "round", "rim_style": "tenspoke", "trim": [] },
	"nissun_two_forty_ess_x_1993": { "H": 1.29, "hood_h": 0.64, "cowl_rise": 0.21, "cowl_d": 1.74, "rake": 60.0, "tail_h": 0.93, "deck": 0.62,
		"bl_rake": 60.0, "soft": 0.9, "head": "popup", "tail_lamp": "wrap" },
	"mazduh_roto_seven_1993": { "rear": "fast", "H": 1.23, "hood_h": 0.58, "cowl_rise": 0.22, "cowl_d": 1.7, "rake": 64.0, "tail_h": 0.95, "bl_rake": 72.0,
		"kick": 0.06, "soft": 1.5, "head": "popup", "tail_lamp": "round", "rim_style": "fivespoke" },
	"mazduh_roto_seven_1985": { "rear": "fast", "H": 1.26, "hood_h": 0.6, "cowl_rise": 0.22, "cowl_d": 1.65, "rake": 62.0, "tail_h": 0.88, "bl_rake": 72.0,
		"soft": 0.4, "tail_lamp": "wrap", "rim_style": "turbofan" },
	"mazduh_myata_1990": { "H": 1.22, "soft": 1.3, "head": "popup", "tail_lamp": "wrap", "rim_style": "multispoke" },
	"hondo_civil_type_arr_2017": { "rim_style": "multispoke", "rim_color": "2a2a2e", "side_vent": "vent", "flare": "box" },
	"acurra_in_tegruh_1994": { "rear": "fast", "head": "quad", "tail_lamp": "wrap", "rim_style": "fivespoke" },
	"mitsubishy_lanser_evolushun_2008": { "nose_lean": -0.06, "flare": "box", "rim_style": "tenspoke", "side_vent": "vent" },
	"subaroo_imprezza_wrecks_2004": { "rim_style": "fivespoke", "rim_color": "c8a040" },
	"datsum_two_forty_zed_1972": { "rear": "fast", "H": 1.29, "hood_h": 0.66, "cowl_rise": 0.18, "cowl_d": 1.95, "rake": 56.0, "tail_h": 0.86,
		"bl_rake": 72.0, "soft": 0.8, "head": "round", "tail_lamp": "bar", "bumper": "chrome", "rim_style": "dish" },
	"nissun_three_hundred_zed_x_1990": { "rear": "fast", "H": 1.25, "hood_h": 0.6, "cowl_rise": 0.22, "cowl_d": 1.72, "rake": 66.0, "tail_h": 0.98,
		"bl_rake": 72.0, "soft": 0.9, "head": "flush", "tail_lamp": "wrap" },
	"toyoda_mister_two_1991": { "head": "popup", "soft": 0.8 },
	"toyoda_corolly_drifto_1986": { "rear": "hatch", "H": 1.33, "hood_h": 0.66, "cowl_rise": 0.18, "cowl_d": 1.5, "rake": 58.0, "tail_h": 0.88,
		"bl_rake": 64.0, "c_bot": -0.18, "soft": 0.18, "head": "popup", "tail_lamp": "wrap", "bumper": "rubber", "rim_style": "tenspoke" },
	# --- euro boxes and rally cars
	"lanchia_deltuh_integrally_1992": { "head": "quad", "soft": 0.2, "flare": "box", "art": { "spoiler": true } },
	"awdi_kwattro_1983": { "soft": 0.12, "flare": "box", "head": "rect" },
	"beemer_werke_emm_dreier_1990": { "H": 1.37, "hood_h": 0.72, "cowl_rise": 0.17, "cowl_d": 1.6, "rake": 56.0, "deck": 0.55, "tail_h": 1.0,
		"bl_rake": 52.0, "soft": 0.15, "nose_lean": -0.04, "flare": "box", "head": "quad", "tail_lamp": "block", "rim_style": "mesh", "bumper": "strip" },
	"volkswagon_golph_gee_tee_eye_1985": { "H": 1.4, "hood_h": 0.72, "cowl_rise": 0.18, "cowl_d": 1.2, "rake": 54.0, "tail_h": 0.9, "bl_rake": 28.0,
		"soft": 0.2, "c_top": 0.24, "c_bot": 0.12, "doors": 2, "head": "round", "tail_lamp": "block", "bumper": "rubber", "rim_style": "tenspoke" },
	"volvoh_brick_1989": { "soft": 0.06, "rake": 52.0 },
	"minni_cupper_1965": { "H": 1.35, "rear": "notch", "hood_h": 0.8, "cowl_rise": 0.12, "cowl_d": 0.95, "rake": 32.0, "deck": 0.32, "tail_h": 0.84,
		"bl_rake": 22.0, "c_top": 0.08, "c_bot": 0.02, "soft": 0.6, "ff": 0.5, "head": "round", "tail_lamp": "block", "bumper": "chrome", "rim_style": "steel" },
	"volkswagon_beetel_1967": { "H": 1.5, "rear": "fast", "hood_h": 0.74, "cowl_rise": 0.26, "cowl_d": 1.45, "rake": 32.0, "tail_h": 0.62, "bl_rake": 52.0,
		"clear": 0.3, "crown": 0.12, "soft": 3.0, "c_top": 0.08, "c_bot": -0.04, "head": "round", "tail_lamp": "round", "bumper": "chrome",
		"fenders": "separate", "rim_style": "dish", "wall": "none" },
	"citrowen_deux_chevals_1975": { "H": 1.6, "rear": "fast", "hood_h": 0.78, "cowl_rise": 0.2, "cowl_d": 1.2, "rake": 28.0, "tail_h": 0.66,
		"bl_rake": 40.0, "clear": 0.32, "crown": 0.1, "soft": 2.0, "doors": 4, "head": "round", "fenders": "separate", "rim_style": "steel" },
	"citrowen_goddess_1970": { "rear": "fast", "H": 1.47, "hood_h": 0.66, "cowl_rise": 0.26, "cowl_d": 1.72, "rake": 56.0, "tail_h": 0.86, "bl_rake": 62.0,
		"soft": 1.5, "nose_round": 0.2, "skirt": true, "head": "round", "tail_lamp": "round", "rim_style": "hubcap" },
	# --- trucks, 4x4s and vans everybody knows
	"fjord_broncho_1970": { "H": 1.77, "hood_h": 1.02, "cowl_rise": 0.04, "cowl_d": 1.35, "rake": 16.0, "soft": 0.1, "arch": "square", "ff": 0.5,
		"nose_drop": 0.4, "head": "round", "bumper": "chrome", "rim_style": "steel", "wall": "letters" },
	"jepp_see_jay_five_1972": { "H": 1.72, "hood_h": 0.98, "cowl_rise": 0.04, "cowl_d": 1.3, "rake": 8.0, "soft": 0.05, "arch": "flat", "ff": 0.5,
		"nose_drop": 0.42, "head": "round", "rim_style": "steel", "wall": "letters" },
	"jepp_wranglur_1995": { "H": 1.75, "hood_h": 1.0, "cowl_rise": 0.05, "cowl_d": 1.35, "rake": 22.0, "soft": 0.08, "arch": "flat", "head": "rect",
		"rim_style": "fivespoke", "wall": "letters" },
	"jepp_cherokay_1999": { "H": 1.64, "hood_h": 0.95, "cowl_rise": 0.1, "cowl_d": 1.3, "rake": 52.0, "rear_d": 0.0, "d_w": 0.12, "soft": 0.06,
		"arch": "square", "head": "rect", "tail_lamp": "tall", "trim": ["cladding"], "rim_style": "tenspoke" },
	"jepp_wagonear_1987": { "H": 1.79, "hood_h": 1.0, "cowl_rise": 0.1, "cowl_d": 1.45, "rake": 42.0, "rear_d": 0.0, "soft": 0.06, "arch": "square",
		"head": "rect", "bumper": "chrome", "rim_style": "hubcap", "wall": "none" },
	"toyoda_land_crusher_1978": { "H": 1.9, "hood_h": 1.04, "cowl_rise": 0.04, "cowl_d": 1.3, "rake": 12.0, "soft": 0.1, "arch": "flat", "head": "round",
		"bumper": "steel", "rim_style": "steel", "art": { "twotone": true } },
	"mercedez_gee_waggen_2012": { "H": 1.95, "hood_h": 1.12, "cowl_rise": 0.06, "cowl_d": 1.6, "rake": 12.0, "soft": 0.05, "arch": "flat", "flare": "box",
		"head": "round", "tail_lamp": "tall", "bumper": "body", "rim_style": "fivespoke", "art": { "spare": true } },
	"landrova_defendur_1997": { "H": 1.97, "hood_h": 1.08, "cowl_rise": 0.06, "cowl_d": 1.3, "rake": 10.0, "soft": 0.05, "arch": "square", "head": "round", "bumper": "steel" },
	"hummor_aitch_won_1996": { "H": 1.9, "clear": 0.42, "hood_h": 1.05, "cowl_rise": 0.22, "cowl_d": 1.85, "rake": 18.0, "rear_d": 0.25, "soft": 0.04,
		"arch": "square", "head": "round", "rim_style": "beadlock", "tire": 1.1 },
	"volkswagon_hippie_buss_1972": { "H": 1.95, "hood_h": 0.95, "cowl_rise": 0.06, "cowl_d": 0.12, "rake": 16.0, "rear_d": 0.12, "soft": 1.6, "crown": 0.06,
		"nose_drop": 0.55, "nose_round": 0.25, "head": "round", "bumper": "chrome", "rim_style": "hubcap" },
	"toyoda_previous_1993": { "hood_h": 0.86, "cowl_rise": 0.22, "cowl_d": 0.75, "rake": 64.0, "rear_d": 0.06, "soft": 1.6 },
	"gmz_sy_clone_1991": { "H": 1.52, "clear": 0.14, "hood_h": 0.86, "rim_style": "multispoke" },
	"fjord_crown_victorious_2005": { "rim_style": "steel", "rim_color": "2a2e36" },
	# --- the odd ones
	"cadillak_fleetwould_hearse_1985": { "rear_d": 0.08, "art": { "hearse": true, "vinyl": true } },
	"aston_martian_lagonduh_1980": { "hood_h": 0.62, "cowl_rise": 0.26, "rake": 64.0, "deck": 0.95, "bl_rake": 64.0, "soft": 0.04, "nose": "wedge" },
}
