## Side-view cars, generated the CAGE BOSS way (src/art/portrait.ts there, counter/face.gd here):
## a car's catalogue facts (year, class, body, length, height, wheelbase, tyres, where the engine
## sits, its art cues) plus a seed from its id become a design, the car's DNA: dozens of
## independent proportions and details. render() draws a design layer by layer into a pixel
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
## What a maker's cars from 2000 on wear so you know them at a glance, the way a CAGE BOSS face
## keeps its family's nose: the headlamp's shape and how far back it sweeps (a fraction of the
## length), the grille on the nose, the tail lamp, a six-light greenhouse (a little window behind
## the back door), chrome or black round the glass, how high the character line runs down the
## side (0 shoulder .. 1 sill), the mirror on the door or on the sail, the stock rim, and on a
## crossover how far the roof drops (m) and how hard the D-pillar leans (degrees).
const MAKERS := {
	"Toyoda": { "head": "hook", "head_len": 0.11, "grille": "slim", "tail": "lid", "tail_len": 0.1, "sixlight": true, "frame": "black",
		"crease": 0.14, "mirror_at": "door", "rim": "tenspoke", "xo_drop": 0.06, "xo_rake": 44.0 },
	"Lexis": { "head": "hook", "head_len": 0.12, "grille": "big", "tail": "ell", "tail_len": 0.09, "sixlight": true, "frame": "chrome",
		"crease": 0.16, "mirror_at": "door", "rim": "multispoke", "xo_drop": 0.08, "xo_rake": 50.0 },
	"Scionn": { "head": "blade", "head_len": 0.1, "grille": "big", "tail": "slim", "tail_len": 0.08, "frame": "black", "crease": 0.3, "mirror_at": "door", "rim": "tenspoke" },
	"Hondo": { "head": "blade", "head_len": 0.13, "grille": "bar", "tail": "ell", "tail_len": 0.08, "sixlight": false, "frame": "black",
		"crease": 0.24, "mirror_at": "sail", "rim": "multispoke", "xo_drop": 0.08, "xo_rake": 40.0 },
	"Acurra": { "head": "led", "head_len": 0.12, "grille": "beak", "tail": "ell", "tail_len": 0.09, "frame": "chrome", "crease": 0.2,
		"mirror_at": "sail", "rim": "fivespoke", "xo_drop": 0.07, "xo_rake": 46.0 },
	"Chevrolay": { "head": "split", "head_len": 0.1, "grille": "split", "tail": "dual", "tail_len": 0.07, "sixlight": false, "frame": "chrome",
		"crease": 0.36, "mirror_at": "door", "rim": "fivespoke", "xo_drop": 0.04, "xo_rake": 34.0 },
	"Pontiak": { "head": "split", "head_len": 0.11, "grille": "split", "tail": "slim", "tail_len": 0.12, "frame": "black", "crease": 0.42,
		"mirror_at": "sail", "rim": "fivespoke", "xo_drop": 0.05, "xo_rake": 38.0 },
	"Buickk": { "head": "teardrop", "head_len": 0.12, "grille": "waterfall", "tail": "wrap", "tail_len": 0.09, "frame": "chrome", "crease": 0.18,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.07, "xo_rake": 44.0 },
	"Cadillak": { "head": "tower", "head_len": 0.06, "grille": "big", "tail": "tower", "tail_len": 0.04, "frame": "chrome", "crease": 0.1,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.04, "xo_rake": 36.0 },
	"Oldsmobeel": { "head": "long", "head_len": 0.11, "grille": "split", "tail": "slim", "tail_len": 0.11, "frame": "chrome", "crease": 0.3, "mirror_at": "door", "rim": "multispoke" },
	"Saturne": { "head": "teardrop", "head_len": 0.11, "grille": "slim", "tail": "wrap", "tail_len": 0.08, "frame": "black", "crease": 0.4, "mirror_at": "sail", "rim": "tenspoke" },
	"Fjord": { "head": "long", "head_len": 0.16, "grille": "big", "tail": "slim", "tail_len": 0.11, "sixlight": false, "frame": "chrome",
		"crease": 0.18, "mirror_at": "sail", "rim": "multispoke", "xo_drop": 0.07, "xo_rake": 48.0 },
	"Merkury": { "head": "long", "head_len": 0.12, "grille": "waterfall", "tail": "slim", "tail_len": 0.14, "frame": "chrome", "crease": 0.3, "mirror_at": "door", "rim": "tenspoke" },
	"Linkoln": { "head": "led", "head_len": 0.1, "grille": "waterfall", "tail": "slim", "tail_len": 0.16, "frame": "chrome", "crease": 0.12,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.05, "xo_rake": 38.0 },
	"Chryslur": { "head": "hook", "head_len": 0.1, "grille": "big", "tail": "dual", "tail_len": 0.08, "frame": "chrome", "crease": 0.32, "mirror_at": "door", "rim": "fivespoke" },
	"Dodgy": { "head": "tower", "head_len": 0.08, "grille": "big", "tail": "slim", "tail_len": 0.12, "frame": "black", "crease": 0.3,
		"mirror_at": "door", "rim": "fivespoke", "xo_drop": 0.03, "xo_rake": 32.0 },
	"Nissun": { "head": "boomerang", "head_len": 0.14, "grille": "vee", "tail": "boomerang", "tail_len": 0.1, "sixlight": true, "frame": "chrome",
		"crease": 0.1, "mirror_at": "door", "rim": "multispoke", "xo_drop": 0.09, "xo_rake": 52.0 },
	"Infinitee": { "head": "boomerang", "head_len": 0.12, "grille": "big", "tail": "slim", "tail_len": 0.1, "frame": "chrome", "crease": 0.12,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.09, "xo_rake": 50.0 },
	"Hyundie": { "head": "teardrop", "head_len": 0.17, "grille": "hex", "tail": "teardrop", "tail_len": 0.12, "sixlight": false, "frame": "chrome",
		"crease": 0.2, "mirror_at": "door", "rim": "tenspoke", "xo_drop": 0.08, "xo_rake": 48.0 },
	"Kiah": { "head": "teardrop", "head_len": 0.13, "grille": "tiger", "tail": "slim", "tail_len": 0.1, "frame": "black", "crease": 0.3,
		"mirror_at": "sail", "rim": "fivespoke", "xo_drop": 0.06, "xo_rake": 42.0 },
	"Mazduh": { "head": "teardrop", "head_len": 0.14, "grille": "big", "tail": "round", "tail_len": 0.08, "frame": "chrome", "crease": 0.16,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.08, "xo_rake": 50.0 },
	"Subaroo": { "head": "hook", "head_len": 0.1, "grille": "hex", "tail": "ell", "tail_len": 0.08, "frame": "black", "crease": 0.34,
		"mirror_at": "door", "rim": "fivespoke", "xo_drop": 0.03, "xo_rake": 30.0 },
	"Mitsubishy": { "head": "blade", "head_len": 0.11, "grille": "big", "tail": "slim", "tail_len": 0.09, "frame": "chrome", "crease": 0.22,
		"mirror_at": "door", "rim": "fivespoke", "xo_drop": 0.06, "xo_rake": 40.0 },
	"Volkswagon": { "head": "led", "head_len": 0.09, "grille": "bar", "tail": "slim", "tail_len": 0.08, "frame": "chrome", "crease": 0.08,
		"mirror_at": "door", "rim": "fivespoke", "xo_drop": 0.04, "xo_rake": 36.0 },
	"Awdi": { "head": "led", "head_len": 0.1, "grille": "big", "tail": "slim", "tail_len": 0.09, "frame": "chrome", "crease": 0.05,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.07, "xo_rake": 46.0 },
	"Mercedez": { "head": "jewel", "head_len": 0.1, "grille": "big", "tail": "wrap", "tail_len": 0.1, "frame": "chrome", "crease": 0.1,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.05, "xo_rake": 40.0 },
	"Beemer-Werke": { "head": "angel", "head_len": 0.09, "grille": "kidney", "tail": "ell", "tail_len": 0.09, "frame": "chrome", "crease": 0.12,
		"mirror_at": "door", "rim": "multispoke", "xo_drop": 0.06, "xo_rake": 44.0 },
	"Volvoh": { "head": "hook", "head_len": 0.09, "grille": "bar", "tail": "tower", "tail_len": 0.04, "frame": "chrome", "crease": 0.08,
		"mirror_at": "door", "rim": "tenspoke", "xo_drop": 0.04, "xo_rake": 34.0 },
	"Tesler": { "head": "teardrop", "head_len": 0.12, "grille": "none", "tail": "wrap", "tail_len": 0.1, "frame": "chrome", "crease": 0.12, "mirror_at": "door", "rim": "multispoke" },
}

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
		"suv": h = 1.68 if cls == "crossover" else (1.9 if cls == "luxury" and year >= 1995 else (1.84 if L > 5.3 else 1.78))
		"offroad": h = 1.8
		"pickup":
			if f.art.get("cab", "") == "ute": h = 1.38
			elif f.art.get("cab", "") == "cabover": h = 1.76
			elif L < 5.05: h = 1.62
			else: h = [1.8, 1.82, 1.83, 1.84, 1.85, 1.9, 1.95][era] + (0.08 if cls in ["hd_pickup", "work_truck"] else 0.0)
		"van": h = 2.05
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
		"brow_d": 0.0, "brow_h": 0.0, "arc": false, "peak": 0.55, "boxy": false, "kink": 0.0, "c_w": 0.0, "under": 0.03,
		"tub": false, "xo": false, "lux": false, "sail": 0.0, "formal": false, "jelly": 0.0, "centre": false,
	}
	var us: bool = String(f.make) in US_MAKES
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
			# a Jepp and its kind: a short flat-topped tub on a frame, up off the ground, with the
			# doors cut out of its sides, an upright windshield and a flat hood to a square grille
			if String(f.make) == "Jepp" or (art.has("open") and L < 4.3):
				g.tub = true
				g.clear = 0.42
				g.under = 0.13
				g.hood_h = 1.0
				g.cowl_rise = 0.05
				g.cowl_d = minf(L * 0.36, 1.45)
				g.rake = 10.0 if year < 1987 else (20.0 if year < 2007 else 28.0)
				g.nose_drop = 0.14
				g.nose_round = 0.02
				g.nose_bot = 0.44
				g.tail_bot = 0.46
				g.belt_up = 0.02
				g.kick = 0.0
				g.soft = 0.12 if year < 2007 else 0.3
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
			if rear_eng or year < 1975:
				g.cowl_d = L * 0.05
				g.rake = 18.0
				g.hood_h = 0.92
				g.cowl_rise = 0.06
			g.rear = "box"
			g.rear_d = 0.02
			g.d_w = 0.14
			g.rt = 0.12 if modern else 0.15
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
			g.nose_drop = 0.16
			g.nose_round = 0.2
			g.nose_lean = 0.04
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
	_era(g, f, fam, L, us, r)
	_modern(g, f, fam, L, r)
	if art.has("fins") and fam in ["sedan", "coupe", "wagon", "roadster"]:
		# every maker cut its fins its own way: tall or low, peaked at the tail or swept forward
		g.fin = { 1956: 0.08, 1957: 0.12, 1958: 0.15, 1959: 0.24, 1960: 0.14 }.get(year, 0.07) * r.randf_range(0.6, 1.35)
	# a little of the car's own in every number, so no two cars share a silhouette
	for k in ["hood_h", "cowl_rise", "cowl_d", "tail_h", "deck", "crown", "c_top", "rt", "nose_drop", "nose_round"]:
		g[k] = _j(r, float(g[k]), 0.04)
	for k in ["rake", "bl_rake"]:
		g[k] = float(g[k]) + r.randf_range(-2.0, 2.0)
	g.kick = float(g.kick) + r.randf_range(-0.012, 0.012)
	g.belt_up = float(g.belt_up) + r.randf_range(-0.012, 0.012)
	return g

## Before 2000 each decade had its own sedan: the sixties compacts sit their cabin square over
## the wheelbase, the seventies full-size cars run a long flat hood to an upright chrome grille
## and stand their back glass up behind a wide formal C-pillar, and from the mid-eighties the
## jellybeans round off the roof and the nose (Fjord first, everybody else a few years later).
static func _era(g: Dictionary, f: Dictionary, fam: String, L: float, us: bool, r: RandomNumberGenerator) -> void:
	var year: int = f.year
	var cls: String = f.cls
	if year >= 2000 or not fam in ["sedan", "coupe", "wagon"] or cls in ["sports", "exotic"]: return
	if year >= 1959 and year < 1976 and L < 4.95 and fam != "wagon" and us: g.centre = true
	if year >= 1970 and year < 1980 and fam == "sedan" and us and (L > 5.0 or cls == "luxury"):
		g.formal = true
		g.cowl_d = L * 0.43
		g.cowl_rise = 0.05
		g.hood_h = float(g.hood_h) + 0.02
		g.bl_rake = r.randf_range(14.0, 24.0)
		g.c_w = r.randf_range(0.3, 0.4)
		g.c_top = 0.1
		g.deck = L * 0.2
		g.crown = 0.004
		g.soft = 0.15
		g.nose_round = 0.02
		g.nose_drop = 0.24
	if year >= 1986:
		var start := 1985 if String(f.make) == "Fjord" else 1988
		var jb := clampf(float(year - start) / 6.0, 0.0, 1.0)
		if jb <= 0.0: return
		g.jelly = jb
		g.soft = lerpf(float(g.soft), 1.15, jb)
		g.crown = lerpf(float(g.crown), 0.045, jb)
		g.nose_round = lerpf(float(g.nose_round), 0.15, jb)
		g.nose_drop = float(g.nose_drop) + 0.04 * jb
		g.rake = lerpf(float(g.rake), 62.0, jb)
		g.tail_h = float(g.tail_h) + 0.03 * jb
		if fam == "sedan":
			g.bl_rake = lerpf(float(g.bl_rake), 62.0, jb)
			g.c_w = 0.16 * jb

## Cars from 2000 on don't share the nineties' three-box: a high beltline with the glass a third
## of the side, one bow from the A-pillar over the roof to a short high deck, a tall blunt nose.
## SUVs and pickups from the mid-nineties on stand tall: a flat hood, a square upright face, a
## high belt, square arches and daylight under the sills. `m` runs 0..1 from 2000 to 2012, when
## the coupe roofs and the big rims arrive.
static func _modern(g: Dictionary, f: Dictionary, fam: String, L: float, r: RandomNumberGenerator) -> void:
	var year: int = f.year
	var cls: String = f.cls
	var fwd: bool = f.drive == "FWD"
	var m := clampf(float(year - 1999) / 13.0, 0.0, 1.0)
	var lux := cls == "luxury"
	if year >= 2000 and fam in ["sedan", "coupe", "hatch", "muscle"] and not cls in ["classic"]:
		g.arc = true
		g.peak = r.randf_range(0.42, 0.62)
		g.clear = 0.14
		g.soft = 1.0
		g.hood_h = lerpf(0.78, 0.86, m) + (0.03 if lux else 0.0)
		g.cowl_rise = lerpf(0.21, 0.16, m)
		g.rake = lerpf(60.0, 63.0, m)
		g.belt_up = lerpf(0.01, 0.04, m)
		g.kick = lerpf(0.05, 0.09, m)
		g.crown = lerpf(0.035, 0.05, m)
		# a tall blunt face: the bumper stands nearly upright under the hood's front edge
		g.nose_round = 0.06
		g.nose_drop = lerpf(0.13, 0.1, m)
		g.nose_bot = 0.22
		g.tail_bot = 0.26
		g.rt = 0.065
		match fam:
			"sedan", "muscle":
				g.cowl_d = L * lerpf(0.31, 0.29, m) + (0.0 if fwd else 0.2)
				g.hood_h = lerpf(0.8, 0.84, m) + (0.03 if lux else 0.0)
				g.cowl_rise = lerpf(0.16, 0.14, m)
				g.belt_up = 0.0
				g.rake = lerpf(55.0, 58.0, m)
				g.tail_h = lerpf(1.05, 1.1, m)
				g.tail_mid = g.tail_h * 0.62
				g.deck = L * lerpf(0.17, 0.19, m) + (0.08 if lux else 0.0)
				g.deck_rise = 0.0
				g.bl_rake = lerpf(58.0, 64.0, m)
				g.c_top = 0.08
				g.c_w = lerpf(0.18, 0.14, m)
				if fam == "muscle": g.doors = 2
			"coupe":
				g.cowl_d = L * lerpf(0.33, 0.31, m) + (0.0 if fwd else 0.15)
				g.hood_h = lerpf(0.76, 0.8, m)
				g.cowl_rise = 0.15
				g.belt_up = 0.0
				g.rake = lerpf(58.0, 61.0, m)
				g.tail_h = lerpf(1.0, 1.04, m)
				g.tail_mid = g.tail_h * 0.62
				g.deck = L * lerpf(0.15, 0.14, m)
				g.deck_rise = 0.0
				g.bl_rake = lerpf(64.0, 70.0, m)
				g.c_top = 0.06
				g.c_w = 0.2
			"hatch":
				g.cowl_d = L * lerpf(0.29, 0.27, m)
				g.cowl_rise = lerpf(0.17, 0.15, m)
				g.belt_up = 0.0
				g.tail_h = lerpf(0.98, 1.05, m)
				if g.rear == "hatch" and float(g.bl_rake) < 60.0:
					g.bl_rake = lerpf(40.0, 52.0, m)
					g.c_top = 0.12
					g.c_bot = lerpf(0.0, -0.06, m)
				else:
					g.c_w = 0.18
				g.tail_x = 0.0
				g.tail_mid = 0.62
	elif fam in ["suv", "offroad", "pickup"] and year >= 1995 and String(g.cab) != "ute" and String(g.cab) != "cabover" and not g.tub:
		var cross := cls == "crossover"
		var big := L > 5.05
		var hd: bool = cls in ["hd_pickup", "work_truck"] or f.body == "tow"
		g.boxy = true
		g.soft = lerpf(0.35, 0.6, m) if not cross else 0.8
		g.nose = "blunt"
		g.nose_round = 0.04 if not cross else 0.07
		g.belt_up = 0.05 if not cross else 0.03
		g.kick = 0.02 if not cross else lerpf(0.03, 0.07, m)
		g.rake = lerpf(56.0, 60.0, m) if not cross else lerpf(60.0, 64.0, m)
		# a body on a frame stands up off the ground, with the frame and the tank in the gap
		if fam == "pickup":
			g.hood_h = lerpf(1.1, 1.26, m) + (0.1 if hd else 0.0) - (0.14 if not big else 0.0)
			g.cowl_rise = 0.07
			g.clear = (lerpf(0.4, 0.47, m) + (0.04 if hd else 0.0)) if big else lerpf(0.32, 0.36, m)
			g.under = 0.17 if big else 0.13
			g.nose_drop = 0.22
			g.bed_h = float(g.hood_h) - 0.03
			if big and year >= 2004:
				# the modern full-size: the front clip stands well over the bed rail, a tall flat
				# grille face, more air under it
				var mm := clampf(float(year - 2004) / 10.0, 0.0, 1.0)
				g.hood_h = float(g.hood_h) + lerpf(0.04, 0.1, mm)
				g.bed_h = float(g.hood_h) - lerpf(0.08, 0.14, mm)
				g.clear = float(g.clear) + 0.04
				g.cowl_rise = 0.05
				g.nose_round = 0.03
				g.nose_drop = float(g.hood_h) - float(g.clear) - 0.12
		elif cross:
			g.hood_h = lerpf(0.92, 1.0, m)
			g.cowl_rise = 0.11
			g.clear = 0.24
			g.under = 0.05
			g.nose_drop = 0.24
			g.rear_d = lerpf(0.22, 0.34, m)
			g.d_w = 0.2
			g.crown = 0.03
			if year >= 2005: _crossover(g, f, L, r)
		else:
			g.hood_h = lerpf(1.02, 1.16, m) + (0.06 if big else 0.0)
			g.cowl_rise = 0.08
			g.clear = (0.4 if big else 0.33) if fam == "suv" else 0.36
			g.under = 0.14 if fam == "suv" else 0.16
			g.nose_drop = 0.2
			g.rear_d = 0.06
			if lux and fam == "suv":
				# a full-size truck in a tuxedo: a tall flat hood to a big chrome grille, the
				# windshield stood up, a square greenhouse to a square back
				g.lux = true
				g.hood_h = float(g.hood_h) + 0.08
				g.cowl_rise = 0.04
				g.rake = 54.0
				g.rear_d = 0.03
				g.d_w = 0.12
				g.soft = 0.3
				g.nose_round = 0.03
				g.nose_drop = 0.36
				g.kick = 0.0
		if not g.xo:
			g.nose_bot = float(g.clear) - 0.03
			g.tail_bot = float(g.clear) - 0.01
	elif fam == "van" and year >= 2005:
		# the Euro-style vans: a short sloping hood, a tall face, the windshield nearly to the roof
		g.cowl_d = 0.95
		g.hood_h = 1.08
		g.cowl_rise = 0.16
		g.rake = 30.0
		g.nose = "blunt"
		g.nose_round = 0.1
		g.nose_drop = 0.16
		g.nose_bot = 0.34
		g.soft = 0.7

## A crossover from the mid-2000s on is no upright two-box: the beltline climbs toward the back,
## the roof drops to a raked tailgate over a short tail, the pillars are black so the roof
## floats, the cladding stays on the arches and big wheels fill them. How far the roof drops and
## how hard the D-pillar leans are the maker's (MAKERS).
static func _crossover(g: Dictionary, f: Dictionary, L: float, r: RandomNumberGenerator) -> void:
	var m := clampf(float(int(f.year) - 2005) / 10.0, 0.0, 1.0)
	var dna: Dictionary = MAKERS.get(String(f.make), {})
	g.xo = true
	g.boxy = false
	g.rear = "hatch"
	g.arc = true
	g.peak = r.randf_range(0.56, 0.7)
	g.soft = 0.95
	g.hood_h = lerpf(0.96, 1.02, m)
	g.cowl_rise = 0.13
	g.cowl_d = L * 0.3
	g.rake = lerpf(60.0, 64.0, m)
	g.belt_up = 0.03
	g.kick = lerpf(0.08, 0.13, m)
	g.crown = float(dna.get("xo_drop", r.randf_range(0.04, 0.09))) * r.randf_range(0.85, 1.15)
	g.tail_x = 0.0
	g.tail_h = lerpf(1.02, 1.08, m)
	g.tail_mid = 0.64
	g.bl_rake = float(dna.get("xo_rake", r.randf_range(34.0, 50.0))) + r.randf_range(-3.0, 3.0)
	g.c_top = 0.1
	g.c_w = 0.3
	g.ff = 0.6
	g.nose = "round"
	g.nose_round = 0.09
	g.nose_drop = 0.2
	g.clear = 0.23
	g.under = 0.04
	g.nose_bot = 0.26
	g.tail_bot = 0.29

static func _dna(f: Dictionary) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(f.key))
	var L: float = f.L
	var year: int = f.year
	var era := clampi((year - 1950) / 10, 0, 6)
	var icon: Dictionary = ICONS.get(String(f.id), {})
	# an icon can move a car to the family and class it really belongs to (a Q7 is a crossover)
	if icon.has("cls"): f.cls = String(icon.cls)
	var fam := String(icon.get("family", _family(f)))
	if icon.has("art"): (f.art as Dictionary).merge(icon.art, true)
	var H := float(icon.get("H", _height(f, fam, era) * (1.0 + r.randf_range(-0.015, 0.015))))
	var g := _skeleton(f, fam, era, L, H, r)
	for k in icon:
		if g.has(k): g[k] = icon[k]
	if icon.has("deck") and not icon.has("rear"): g.rear = "notch"
	var d := { "id": f.id, "year": year, "cls": f.cls, "body": f.body, "family": fam, "make": f.make,
		"model": f.model, "rear": g.rear, "nose": g.nose, "L": L, "h": H / L, "cab": g.cab, "doors": g.doors,
		"soft": float(g.soft), "art": f.art, "pos": f.pos, "xo": g.xo, "lux": g.lux, "formal": g.formal, "jelly": float(g.jelly) }
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
	# the rims read bigger than the tape measure says from the nineties on, the way Pixel Car Racer
	# draws them: thin sidewalls filling the arches
	var rim_frac := clampf(rim_in * 0.0254 * 0.5 / tire_m * lerpf(1.0, 1.14, clampf(float(year - 1988) / 24.0, 0.0, 1.0)), 0.42, 0.82)
	if fam == "boxtruck": rim_frac = 0.55
	var oh: float = maxf(0.25, L - float(f.WB))
	var ff: float = g.ff
	d.wf = 1.0 - oh * ff / L
	d.wr = oh * (1.0 - ff) / L
	d.tire_r = tire_m / L * float(icon.get("tire", 1.0)) * (1.1 if fam in ["pickup", "suv", "offroad"] else 1.06)
	d.rim = float(icon.get("rim_frac", rim_frac))
	# big wheels fill the arches of a modern crossover, a luxury truck and a full-size pickup
	var min_tire := 0.0
	if g.xo: min_tire = 0.084
	elif g.lux: min_tire = 0.08
	elif fam == "pickup" and L > 5.05 and year >= 2004 and String(g.cab) != "ute": min_tire = lerpf(0.07, 0.078, clampf(float(year - 2004) / 10.0, 0.0, 1.0))
	if min_tire > 0.0 and not icon.has("tire"):
		d.tire_r = maxf(float(d.tire_r), min_tire)
		rim_frac = maxf(rim_frac, 0.68 if g.lux else 0.64)
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
	# a sixties compact sits its cabin square over the wheelbase, not pushed back like a coupe's
	if g.centre:
		var cab_mid := (1.0 - float(g.cowl_d) / L + (float(g.tail_x) + float(g.deck)) / L) * 0.5
		var shift := (float(d.wr) + float(d.wf)) * 0.5 + 0.01 - cab_mid
		if shift > 0.0:
			g.cowl_d = float(g.cowl_d) - shift * L
			g.deck = float(g.deck) + shift * L
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
	if fam == "van" and H > 2.15:
		# a high roof: the windshield runs up nearly to it, the side glass stops at van height
		top_h = H - 0.16
		d.glass_cap = (2.0 - float(g.rt)) / L
	d.cab_top = top_h / L
	d.arc = g.arc
	d.tub = g.tub
	d.peak = g.peak
	d.boxy = g.boxy
	d.kink = float(g.kink) / L
	d.under = float(g.under) / L
	d.roof_f = float(d.cowl_x) - (top_h - cowl_h) * tan(rake) / L
	d.belt_f = (cowl_h + float(g.belt_up)) / L
	d.belt_r = float(d.belt_f) + float(g.kick) / L
	d.nose_x = 1.0 - float(g.nose_round) / L
	# a front fender that crests above the hood line (a lamp on top of it), as [x, y]
	d.brow_x = 1.0 - float(g.brow_d) / L if float(g.brow_d) > 0.0 else 0.0
	d.brow_h = float(g.brow_h) / L
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
			d.sail = float(g.sail) / L
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
	var min_roof := 0.1 if fam in ["sedan", "coupe", "muscle", "wagon"] else (0.14 if fam == "bubble" else 0.05)
	if g.rear in ["notch", "fast", "hatch"] and float(d.roof_f) - float(d.roof_r) < min_roof:
		var mid := (float(d.roof_f) + float(d.roof_r)) * 0.5
		d.roof_f = mid + min_roof * 0.5
		d.roof_r = mid - min_roof * 0.5
	if icon.has("top"): _hand_drawn(d, icon.top, g, L)
	d.dna = _maker(f, fam, g)
	if d.dna.has("sixlight"): d.sixlight = d.dna.sixlight
	if icon.has("sixlight"): d.sixlight = icon.sixlight
	d.wrap = year >= 1954 and year <= 1960 and String(f.make) in US_MAKES and fam in ["sedan", "coupe", "wagon"] and not icon.has("top")
	_glass_and_doors(d, g, L, r)
	_details(d, f, fam, era, r)
	for k in icon:
		if not g.has(k) and not k in ["H", "art", "top"]: d[k] = icon[k]
	return d

## The maker's signature parts (MAKERS) for a car that wears them: a car from 2000 on, or a
## modern crossover. Empty for everybody else.
static func _maker(f: Dictionary, fam: String, g: Dictionary) -> Dictionary:
	if int(f.year) < 2000 or String(f.cls) in ["classic", "exotic"]: return {}
	if not (fam in ["sedan", "coupe", "hatch", "wagon", "muscle"] or g.xo): return {}
	return MAKERS.get(String(f.make), {})

## A top line drawn by hand for a car everybody knows: [x, y, corner radius, anchor] in metres,
## x from the rear bumper, round from the tail over the roof to the front of the nose. The
## named points move the anchors the glass, the pillars, the doors and the lamps hang on: tail,
## deck (where the backlight meets the trunk), roof_r and roof_f (the top of the backlight and of
## the windshield), cowl (the bottom of the windshield), hood (its front edge) and nose.
static func _hand_drawn(d: Dictionary, top: Array, g: Dictionary, L: float) -> void:
	var pts: Array = []
	for q: Array in top:
		var x := float(q[0]) / L
		var y := float(q[1]) / L
		pts.append([x, y, float(q[2]) / L])
		if q.size() < 4: continue
		match String(q[3]):
			"tail":
				d.tail_x = x
				d.tail_h = y
			"deck":
				d.deck_x = x
				d.deck_h = y
			"roof_r": d.roof_r = x
			"roof_f":
				d.roof_f = x
				d.cab_top = y
			"cowl":
				d.cowl_x = x
				d.cowl_h = y
			"hood":
				d.nose_x = x
				d.hood_h = y
			"nose": d.nose_mid = y
	d.top_pts = pts
	d.belt_f = float(d.cowl_h) + float(g.belt_up) / L
	d.belt_r = float(d.belt_f) + float(g.kick) / L

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
	# a high roof's side glass stops at van height, so its front edge follows the windshield there
	var a_top: float = float(ws_x.call(minf(glass_top, float(d.get("glass_cap", 9.0))))) - a_w * 0.7
	var dogleg := -1.0
	if d.get("wrap", false):
		# a fifties wraparound windshield: the glass runs round the corner to a dogleg A-pillar
		# that leans the wrong way, its foot further back than its top
		dogleg = a_top
		a_bot = float(ws_x.call(belt_f)) - a_w * 0.2
		a_top = float(ws_x.call(glass_top)) - a_w * 0.25
	var dlo_rt := 0.0
	var dlo_r := 0.0
	match String(d.rear):
		"notch", "fast", "hatch":
			dlo_rt = float(d.roof_r) + float(g.c_top) / L
			dlo_r = float(d.roof_r) + float(g.c_bot) / L
			if float(g.c_w) > 0.0:
				# the glass's back edge runs parallel to the backlight, a C-pillar's width ahead of it
				var b0 := Vector2(float(d.deck_x), float(d.deck_h)) if d.rear == "notch" else Vector2(float(d.tail_x), float(d.tail_h))
				var b1 := Vector2(float(d.roof_r), float(d.h))
				var t := clampf((float(d.belt_r) - b0.y) / maxf(0.001, b1.y - b0.y), 0.0, 1.0)
				dlo_r = lerpf(b0.x, b1.x, t) + float(g.c_w) / L
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
		if d.rear == "box" or d.xo:
			var cx := dlo_r + span * (0.2 if not d.xo else 0.24)
			pillars.append([cx, cx + lean * 0.5, b_w * 0.8])
			rear_door_end = cx
		elif bool(d.get("sixlight", r.randf() < 0.45)):
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
	if dogleg > 0.0: pillars.append([dogleg - 0.02, dogleg, b_w * 0.8])
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
	if d.boxy and fam in ["pickup", "suv"] and cls != "crossover" and not art.has("round"): head = "truck"
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
	# the four-door hardtops of the fifties and sixties: no B-pillar, just a chrome line
	if not d.hardtop and int(d.doors) == 4 and us and year >= 1955 and year < 1972 and fam == "sedan": d.hardtop = r.randf() < 0.45
	# where the chrome spear runs down the side, and how it bends
	d.spear_y = r.randf_range(0.16, 0.52)
	d.spear_kind = _pick(r, ["straight", "dip", "sweep", "split"]) if year < 1962 else "straight"
	d.vent = year < 1969 and not fam in ["sports", "mid", "roadster", "bubble"] and r.randf() < 0.8
	# --- trim down the side
	var trim: Array = []
	if year < 1966 and not fam in ["pickup", "offroad", "bubble", "van", "boxtruck"]: trim.append("spear")
	if (cls in ["luxury", "classic"] and year < 1990) or (us and year < 1970 and r.randf() < 0.4): trim.append("rocker_chrome")
	if year >= 1975 and year < 2002 and not fam in ["sports", "mid", "wedge", "offroad", "boxtruck", "rear"] and r.randf() < 0.6: trim.append("moulding")
	if fam == "suv" and year >= 1990 and year < 2012: trim.append("cladding")
	if (cls == "crossover" and year >= 2000) or (fam == "suv" and year >= 2005 and r.randf() < 0.5): trim.append("arch_cladding")
	if cls == "crossover" and year >= 2000 and not trim.has("cladding") and r.randf() < 0.7: trim.append("cladding")
	if us and year < 1972 and cls in ["luxury", "classic"]: trim.append("arch_chrome")
	if art.has("chrome") and year < 1980 and not trim.has("rocker_chrome"): trim.append("rocker_chrome")
	d.trim = trim
	d.crease = -1.0 if year < 1985 and r.randf() < 0.5 else r.randf_range(0.1, 0.28)
	# a mast on the front fender or the corner of the deck, on the cars that had one
	var mast_ok := fam in ["sedan", "coupe", "wagon", "hatch", "pickup", "minivan"] and not cls in ["sports", "exotic", "muscle", "pony"]
	d.antenna = "mast" if year >= 1965 and year < 2004 and mast_ok and r.randf() < 0.5 else ("fin" if year >= 2010 and r.randf() < 0.4 else "none")
	d.antenna_at = "front" if fam == "pickup" or r.randf() < 0.6 else "rear"
	d.fuel = r.randf() < 0.75 and not fam in ["boxtruck"]
	d.badge = r.randi_range(0, 3)
	d.side_vent = "intake" if fam in ["mid", "wedge"] and f.pos != "front" else ("vent" if (cls in ["sports", "exotic", "luxury"] and year >= 2004 and not fam in ["suv", "pickup", "offroad", "van"] and r.randf() < 0.5) else "none")
	if art.has("portholes"): d.side_vent = "portholes"
	if art.has("strakes"): d.side_vent = "strakes"
	d.skirt = (us and cls in ["luxury", "classic"] and year >= 1955 and year < 1977 and fam in ["sedan", "coupe"] and r.randf() < 0.6)
	d.mudflaps = cls in ["rally", "work_truck"] or (fam == "pickup" and year < 1995 and r.randf() < 0.3)
	d.step = (fam == "pickup" and year >= 1999 and r.randf() < 0.5) or (fam == "suv" and year >= 2002 and cls != "crossover" and r.randf() < 0.6) or (cls == "hd_pickup" and year >= 1995)
	# --- arches
	var arch := "round"
	if (fam == "pickup" or fam == "suv") and year >= 1970 and year < 1995: arch = _pick(r, ["flat", "square"])
	if offroad: arch = "square" if year < 2005 else "flat"
	if d.boxy and not offroad: arch = "square"
	if fam == "kei" or fam == "boxtruck": arch = "flat"
	if year >= 1975 and year < 1990 and fam in ["sedan", "coupe", "hatch", "wagon"] and r.randf() < 0.3: arch = "flat"
	if cls == "rally" or art.has("dually") or (fam == "offroad" and year < 2000 and r.randf() < 0.3): d.flare = "box" if cls == "rally" else "bulge"
	else: d.flare = "none"
	if d.tub:
		# flat-topped trapezoid flares, black plastic from the late eighties on
		d.flare = "trap"
		arch = "trap"
	d.arch = arch
	d.arch_gap = (0.045 if fam in ["pickup", "suv", "offroad", "boxtruck"] else (0.006 if fam in ["sports", "mid", "wedge"] or cls == "exotic" else 0.012)) / float(d.L)
	if d.boxy: d.arch_gap = 0.03 / float(d.L)
	elif year >= 2000: d.arch_gap = minf(float(d.arch_gap), 0.008 / float(d.L))
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
	# the maker's signature parts on a modern car
	var dna: Dictionary = d.dna
	d.grille = "none"
	d.head_len = 0.0
	d.tail_len = 0.0
	d.mirror_at = "sail"
	if not dna.is_empty():
		if not d.head in ["popup", "hidden", "round", "quad"]: d.head = String(dna.head)
		d.head_len = float(dna.head_len) * r.randf_range(0.92, 1.08)
		d.grille = String(dna.get("grille", "none"))
		d.tail_lamp = String(dna.tail)
		d.tail_len = float(dna.tail_len) * r.randf_range(0.9, 1.1)
		d.frame = String(dna.frame)
		d.crease = float(dna.crease) + r.randf_range(-0.02, 0.02)
		d.mirror_at = String(dna.mirror_at)
		if not (cls == "economy" and year < 2012) and not cls in ["work_truck"]: d.rim_style = String(dna.rim)
	if d.xo:
		# a modern crossover: black plastic round the arches only, the roof floating on black pillars
		trim.erase("cladding")
		if not trim.has("arch_cladding"): trim.append("arch_cladding")
		trim.erase("moulding")
		if dna.is_empty(): d.tail_lamp = "wrap"
		d.step = false
	if d.lux:
		d.grille = "big"
		d.step = true
		if not trim.has("rocker_chrome"): trim.append("rocker_chrome")
	if d.formal:
		# the seventies' full-size sedan: a chrome waterfall grille, an opera window, often vinyl
		d.grille = "waterfall"
		d.opera = true
		d.vinyl = r.randf() < 0.6
		d.crease = -1.0
	elif float(d.jelly) > 0.5 and dna.is_empty():
		d.head = "flush"
		if year >= 1990: d.bumper = "body"
	# the stripes cue, the way that kind of car wore them
	d.stripe_kind = "racing"
	if cls in ["muscle", "pony"] and year < 1976: d.stripe_kind = _pick(r, ["hockey", "side", "tail"])
	elif fam in ["van"]: d.stripe_kind = "rainbow"
	elif cls in ["economy", "compact", "hatch", "oddball"]: d.stripe_kind = "side"

# ================================================================== the outline

## The body's outline as fractions: [x, y, corner radius], round from the rear bumper's
## bottom, up the tail and over the roof, down the nose and back along the sills. A car in
## ICONS can draw the whole top by hand instead (top_pts, see _hand_drawn), the way a CAGE BOSS
## signature face overrides the generator.
static func profile(d: Dictionary) -> Array:
	var pts: Array = []
	var tail_bot: float = d.tail_bot
	pts.append([0.012, tail_bot, 0.003])
	if d.has("top_pts"):
		pts.append_array(d.top_pts)
	else:
		pts.append_array(_rear_line(d))
		pts.append_array(_roof_line(d))
		pts.append_array(_nose_line(d))
	var nose_lean: float = d.nose_lean
	pts.append([1.0 - 0.012 - nose_lean, float(d.nose_bot), 0.003])
	pts.append([float(d.wf), float(d.nose_bot), 0.0])
	pts.append([float(d.wf), float(d.clear), 0.0])
	pts.append([float(d.wr), float(d.clear), 0.0])
	pts.append([float(d.wr), tail_bot, 0.0])
	return pts

## The tail and the deck (or a pickup's bed, or a box truck's box), up to where the roof starts.
static func _rear_line(d: Dictionary) -> Array:
	var s := float(d.soft)
	var h: float = d.h
	var pts: Array = []
	var rear: String = d.rear
	var tail_bot: float = d.tail_bot
	var crown: float = d.crown
	var arc: bool = d.get("arc", false)
	if rear == "pickup":
		var bed_h: float = d.bed_h
		pts.append([0.0, tail_bot + 0.02, 0.003])
		pts.append([0.0, bed_h, 0.004])
		var cab_x: float = d.cab_x
		if d.cab == "ute":
			pts.append([cab_x - 0.02, bed_h, 0.004 * s])
			pts.append([float(d.roof_r), h - crown * 0.4, 0.02 * s + 0.004])
		else:
			var sail := float(d.get("sail", 0.0))
			if sail > 0.0:
				# a sail panel: the cab's back runs down at a slant onto the bed rail, a flying buttress
				pts.append([cab_x - sail, bed_h, 0.004])
				pts.append([cab_x - 0.01, h - 0.03, 0.01])
				pts.append([cab_x, h - 0.01, 0.012 * s + 0.002])
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
		if not d.get("tub", false): pts.append([0.0, d.tail_mid, 0.012 * s + 0.004])
		match rear:
			"notch":
				if float(d.fin) > 0.0:
					pts.append([float(d.tail_x), float(d.tail_h) + float(d.fin), 0.002])
					pts.append([float(d.deck_x) * 0.5 + 0.08, float(d.tail_h) + float(d.fin) * 0.3, 0.06])
				else:
					pts.append([float(d.tail_x), float(d.tail_h), 0.01 * s + 0.003])
				pts.append([float(d.deck_x), float(d.deck_h), 0.02 * s + 0.004])
				if not arc: pts.append([float(d.roof_r), h - crown * 0.5, 0.03 * s + 0.006])
			"fast":
				pts.append([float(d.tail_x), float(d.tail_h), 0.012 * s + 0.003])
				if not arc: pts.append([float(d.roof_r), h - crown * 0.5, 0.06 * s + 0.01])
			"hatch":
				pts.append([float(d.tail_x), float(d.tail_h), 0.008 * s + 0.003])
				if not arc: pts.append([float(d.roof_r), h - crown * 0.5, 0.03 * s + 0.006])
			"open":
				if d.get("tub", false):
					# a flat-topped tub with the door openings cut deep into its sides
					var cut := tub_cut(d)
					var tub_h: float = d.belt_r
					pts.append([0.0, tub_h, 0.004])
					pts.append([cut[0], tub_h, 0.004])
					pts.append([cut[0] + 0.012, cut[2], 0.03])
					pts.append([cut[1] - 0.012, cut[2], 0.03])
					pts.append([cut[1], float(d.belt_f), 0.004])
				else:
					pts.append([float(d.tail_x), float(d.tail_h), 0.015 * s + 0.003])
					pts.append([float(d.dlo_r) - 0.03, float(d.belt_r) + 0.006, 0.02])
					pts.append([float(d.dlo_r), float(d.belt_r), 0.006])
					pts.append([float(d.a_bot), float(d.belt_f), 0.006])
			_:
				# a wagon's roof drops a touch to the tailgate; a high-roof van's stays flat
				var drop := 0.012 if h <= float(d.cab_top) + 0.01 else 0.0
				pts.append([float(d.roof_r) * 0.6, h - drop, 0.012 * s + 0.004])
	return pts

## Where a Jepp's door opening is cut into the tub: [rear edge, front edge, bottom], fractions.
static func tub_cut(d: Dictionary) -> Array:
	var cut1: float = float(d.cowl_x) - 0.04 / float(d.L)
	var cut0 := maxf(cut1 - 0.85 / float(d.L), float(d.wr) + float(d.tire_r) * 1.3)
	return [cut0, cut1, lerpf(float(d.clear), float(d.belt_r), 0.4)]

## The greenhouse: over the roof from the deck (or the back of the cab) to the cowl. Modern
## cars carry one long bow from the windshield to the deck; older ones a flat roof with corners.
static func _roof_line(d: Dictionary) -> Array:
	var s := float(d.soft)
	var h: float = d.h
	var pts: Array = []
	var rear: String = d.rear
	var crown: float = d.crown
	var arc: bool = d.get("arc", false)
	var high := rear == "box" and h > float(d.cab_top) + 0.01
	if rear != "open":
		var rf: float = d.roof_f
		var rr: float = d.roof_r
		if rear == "boxtruck": rr = maxf(rr, float(d.box_x) + 0.01)
		var top: float = d.cab_top
		if high:
			# a high-roof van: the windshield runs nearly all the way up and the roof is flat from
			# just behind it to the back doors
			pts.append([rf - 0.03, h, 0.02])
			pts.append([rf - 0.004, top + (h - top) * 0.45, 0.02])
			pts.append([rf, top, 0.008])
		elif arc and rear in ["notch", "fast", "hatch"]:
			# one long bow from the A-pillar to the deck: the backlight bulges a little, the roof
			# crowns ahead of the middle and the windshield rolls into it
			var bl := Vector2(rr, top - crown * 0.6)
			var dk := Vector2(float(d.deck_x), float(d.deck_h)) if rear == "notch" else Vector2(float(d.tail_x), float(d.tail_h))
			var bulge := (bl - dk).orthogonal().normalized() * 0.006
			if bulge.y < 0.0: bulge = -bulge
			pts.append([lerpf(dk.x, bl.x, 0.5) + bulge.x, lerpf(dk.y, bl.y, 0.5) + bulge.y, 0.5])
			pts.append([bl.x, bl.y, 0.5])
			pts.append([rr + (rf - rr) * float(d.get("peak", 0.55)), top, 0.5])
			pts.append([rf, top - crown * 0.7, 0.5])
		else:
			pts.append([rr + (rf - rr) * 0.55, top, (rf - rr) * 0.45 if crown > 0.004 else 0.0])
			pts.append([rf, top - crown, 0.02 * s + 0.004])
	pts.append([float(d.cowl_x), float(d.cowl_h), 0.03 if arc else 0.012 * s + 0.002])
	return pts

## The hood and the face, from just ahead of the cowl down to the bottom of the nose.
static func _nose_line(d: Dictionary) -> Array:
	var s := float(d.soft)
	var pts: Array = []
	if float(d.brow_x) > 0.0: pts.append([float(d.brow_x), float(d.brow_h), 0.03 * s + 0.01])
	var nose_lean: float = d.nose_lean
	# blunt noses (trucks, boxes) keep tight corners; a wedge comes to a point
	var nr := (0.014 * s + 0.002) * (0.35 if d.nose == "blunt" else 1.0)
	pts.append([float(d.nose_x) - nose_lean * 0.5, float(d.hood_h), nr])
	pts.append([1.0, float(d.nose_mid), nr if d.nose != "wedge" else 0.003])
	return pts

## Control points [x, y, corner radius] -> a closed outline with every corner rounded, still in
## fractions. `lf` is the length in pixels it will be painted at, which decides how finely.
static func smooth(pts: Array, lf: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var q: Array = pts[i]
		var pt := Vector2(float(q[0]), float(q[1]))
		var qa: Array = pts[(i - 1 + n) % n]
		var qb: Array = pts[(i + 1) % n]
		var a := Vector2(float(qa[0]), float(qa[1]))
		var b := Vector2(float(qb[0]), float(qb[1]))
		var la := pt.distance_to(a)
		var lb := pt.distance_to(b)
		if la < 0.000001 or lb < 0.000001:
			out.append(pt)
			continue
		var rr := minf(float(q[2]), minf(la, lb) * 0.5)
		if rr * lf < 0.75:
			out.append(pt)
			continue
		var p1 := pt + (a - pt) / la * rr
		var p2 := pt + (b - pt) / lb * rr
		var steps := clampi(int(rr * lf / 1.5), 2, 14)
		for k in steps + 1:
			var t := float(k) / float(steps)
			out.append(p1.lerp(pt, t).lerp(pt.lerp(p2, t), t))
	return out

## How high the body's top edge is all the way along: TOP_N + 1 samples from the rear bumper (0)
## to the nose (1), -1 where there's no body.
const TOP_N := 240

static func top_line(outline: PackedVector2Array) -> PackedFloat32Array:
	var top := PackedFloat32Array()
	top.resize(TOP_N + 1)
	top.fill(-1.0)
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var k0 := clampi(int(ceil(minf(a.x, b.x) * TOP_N)), 0, TOP_N)
		var k1 := clampi(int(floor(maxf(a.x, b.x) * TOP_N)), 0, TOP_N)
		var flat := absf(b.x - a.x) < 0.000001
		for k in range(k0, k1 + 1):
			var y := maxf(a.y, b.y) if flat else lerpf(a.y, b.y, (float(k) / TOP_N - a.x) / (b.x - a.x))
			if y > top[k]: top[k] = y
	return top

static func top_at(top: PackedFloat32Array, x: float) -> float:
	var f := clampf(x, 0.0, 1.0) * TOP_N
	var k := mini(int(f), TOP_N - 1)
	return lerpf(top[k], top[k + 1], f - float(k))

## The side glass as fractions, same shape as profile(). Its top edge follows the roof a roof's
## thickness in, so an arched roof gets an arched window; a kink tucks the back of it forward.
static func glass_shape(d: Dictionary, top: PackedFloat32Array) -> Array:
	var r := 0.01 * float(d.soft) + 0.002
	var rt: float = d.rt
	var belt_r: float = d.belt_r
	var cap := float(d.get("glass_cap", 9.0))
	var x0: float = d.dlo_rt
	var x1: float = d.a_top
	var pts: Array = []
	pts.append([float(d.dlo_r), belt_r, 0.002])
	var kink := float(d.get("kink", 0.0))
	if kink > 0.0:
		# a kink: the back edge of the glass runs up the C-pillar, then turns forward
		var ky := belt_r + (top_at(top, x0) - rt - belt_r) * 0.4
		pts.append([float(d.dlo_r) + kink * 0.3, ky, 0.003])
		pts.append([float(d.dlo_r) + kink, ky + (top_at(top, x0) - rt - ky) * 0.25, 0.006])
	var n := 10
	for k in n + 1:
		var x := lerpf(x0, x1, float(k) / float(n))
		var y := maxf(minf(top_at(top, x) - rt, cap), belt_r + 0.012)
		pts.append([x, y, r if k == 0 or k == n else 0.0])
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
	# dark paint shows the sky in its highlights; pale paint goes blue-grey in its shadows
	var lum := paint.get_luminance()
	var dark := clampf((0.32 - lum) / 0.32, 0.0, 1.0)
	var pale := clampf((lum - 0.6) / 0.4, 0.0, 1.0)
	var sky := Color(0.74, 0.81, 0.92)
	var shade := cool.lerp(Color(0.3, 0.34, 0.46), pale)
	var out := {
		"deep": paint.lerp(shade, k[0]), "sh": paint.lerp(shade, k[1]), "mid": paint.lerp(shade, k[2]), "base": paint,
		"lt": paint.lerp(warm, k[4]).lerp(sky.darkened(0.5), dark * 0.32),
		"hi": paint.lerp(warm, k[5]).lerp(sky.darkened(0.3), dark * 0.48),
		"spec": paint.lerp(warm, k[6]).lerp(sky, dark * 0.6),
	}
	if finish == "pearl":
		var shift := Color.from_hsv(fposmod(paint.h + 0.14, 1.0), 0.35, 1.0)
		out.lt = (out.lt as Color).lerp(shift, 0.25)
		out.hi = (out.hi as Color).lerp(shift, 0.45)
		out.spec = (out.spec as Color).lerp(Color.WHITE, 0.4)
		out.sh = (out.sh as Color).lerp(Color.from_hsv(fposmod(paint.h - 0.08, 1.0), 0.6, 0.3), 0.25)
	if finish == "chrome":
		var tint := paint.lerp(Color(0.75, 0.78, 0.82), 0.7)
		out = { "deep": Color("1e2024").lerp(tint, 0.1), "sh": Color("3c4046").lerp(tint, 0.15), "mid": Color("8a8e94").lerp(tint, 0.3),
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
	var top_f := PackedFloat32Array()      # the body's top edge, undamaged, in fractions
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
		if front > 0.0 and fx > 0.62:
			var k := (fx - 0.62) / 0.38
			# the crushed end comes back in jagged folds, worst at the very front
			var j := sin(fy * 520.0) * 0.6 + sin(fy * 1310.0 + 1.7) * 0.4
			fx -= front * (0.2 * k + 0.016 * j * k * k)
			# the hood buckles up into a peak a little behind the crush
			if fy > float(d.hood_h) - 0.03: fy += front * 0.03 * maxf(0.0, 1.0 - absf(k - 0.55) / 0.22)
			if fy > float(d.clear) and fy < belt + 0.03: fy += front * 0.04 * k * (0.6 + 0.4 * sin(fx * 90.0))
		if rear > 0.0 and fx < 0.34:
			var k2 := (0.34 - fx) / 0.34
			var j2 := sin(fy * 470.0 + 0.6) * 0.6 + sin(fy * 1190.0) * 0.4
			fx += rear * (0.16 * k2 + 0.014 * j2 * k2 * k2)
			# the trunk lid kinks up
			if fy > float(d.tail_h) - 0.03: fy += rear * 0.025 * maxf(0.0, 1.0 - absf(k2 - 0.5) / 0.25)
			if fy > float(d.clear) and fy < belt + 0.03: fy += rear * 0.035 * k2 * (0.6 + 0.4 * sin(fx * 80.0))
		if roof > 0.0 and fy > belt + 0.01:
			fy -= roof * 0.08 * clampf((fy - belt) / maxf(0.01, float(d.h) - belt), 0.0, 1.0)
		return Vector2(X(fx), Y(fy))

	## Fractions with corner radii -> a pixel polygon, each corner rounded with a curve. Where a
	## crash bent the car, long straight runs are cut short first so the crumple can bite.
	func poly(pts: Array) -> PackedVector2Array:
		return warped(CarGen.smooth(pts, lf))

	func warped(outline: PackedVector2Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		var n := outline.size()
		var bent := front > 0.0 or rear > 0.0
		var step := 2.0 / lf
		for i in n:
			var a := outline[i]
			out.append(warp(a.x, a.y))
			if not bent: continue
			var b := outline[(i + 1) % n]
			var in_zone := (a.x > 0.6 or b.x > 0.6) and front > 0.0 or (a.x < 0.34 or b.x < 0.34) and rear > 0.0
			if not in_zone: continue
			var cuts := int(a.distance_to(b) / step)
			for k in range(1, cuts):
				var q := a.lerp(b, float(k) / float(cuts))
				out.append(warp(q.x, q.y))
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
		var outline := CarGen.smooth(CarGen.profile(d), lf)
		top_f = CarGen.top_line(outline)
		shape = warped(outline)
		fill(bm, shape, 1)
		if d.rear != "open":
			glass = poly(CarGen.glass_shape(d, top_f))
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
		if String(mods.get("stripes", d.stripe_kind if d.art.has("stripes") else "none")) == "rally": _rally_plate()
		_lamps()
		_windshield()
		_glass_frame()
		_cabin_open()
		_outline()
		_float_roof()
		_sail()
		_fenders()
		_bumpers()
		_mirror()
		_roof_things()
		_aero()
		_truck_things()
		_lightbar()
		_kit()
		_wells()
		_underbody()
		_flares()
		_wheels()
		_cycle_fender()
		_damage_fx()
		if art.has("beacon") or art.has("topper") or art.has("spotlight"): _roof_lights()
		if dmg.has("wheel_off"): _tilt()
		_clip_ground()

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
			"trap":
				var tt := ra * 0.88
				if -dy >= tt: return false
				return absf(dx) < lerpf(ra * 1.02, ra * 0.7, -dy / tt)
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
			if cycled(wv): continue
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

	## A front wheel out in the open, ahead of the body, under a cycle fender.
	func cycled(wv: Array) -> bool:
		return d.get("cycle", false) and wv[0] == "front"

	func skirted(wv: Array) -> bool:
		return d.skirt and d.flare == "none" and String(mods.get("fenders", "stock")) != "flared" and wv[0] == "rear" and not mods.has("rim") and String(dmg.get("flat", "")) != "rear" and String(dmg.get("wheel_off", "")) != "rear"

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

	## Paint every body pixel by where it sits, as a light level (0 deep shadow .. 8 specular).
	## Tops catch the sky. Down the side: a bright shoulder with specular streaks along the curved
	## panels, the sky, the reflected horizon (it bends round the wheels and lifts at the ends), the
	## darker ground, the rocker turning under. Each fender gets a lit crescent over its wheel and
	## a lip on the arch; the tail catches a rim of light; a slanted reflection crosses the doors.
	func _shade_body() -> void:
		var lv: Array[int] = []
		for c: Color in [pal.deep, pal.sh, (pal.mid as Color).lerp(pal.sh, 0.15), pal.mid, pal.base, (pal.base as Color).lerp(pal.lt, 0.6), pal.lt, pal.hi, pal.spec]:
			lv.append(c.to_abgr32())
		var matte := finish == "matte"
		var chrome := finish == "chrome"
		if chrome:
			lv.clear()
			for hx in ["1d1f23", "141518", "2a2d32", "4a4e54", "8a9098", "b9cde0", "dbe8f4", "f3f8fd", "ffffff"]:
				lv.append(Color(hx).to_abgr32())
		var c_gnd_lt: int = Color("8f8270").to_abgr32()
		# chrome reflects the world: a white shoulder, a thin bright sky, a hard horizon just under
		# the shoulder, dark asphalt most of the way down, a little ground low and dark at the sill
		var mirror: Array[int] = []
		for hx in ["ffffff", "dcecf8", "a9c8e6", "7ba3cf", "f2f8ff", "0b0b0d", "24272c", "343840", "474c54", "5c6067", "6a665f", "1a1b1e"]:
			mirror.append(Color(hx).to_abgr32())
		# the panel breaks (door cuts) the reflections break at
		var breaks: Array[float] = []
		for dc: Array in d.door_cuts:
			breaks.append(X(float(dc[0])))
			breaks.append(X(float(dc[1])))
		var hq := len >= 150 and lod >= 2
		var flake := finish in ["metallic", "pearl"]
		var c_flk: int = (pal.lt as Color).to_abgr32()
		var c_flk2: int = (pal.mid as Color).to_abgr32()
		var end_k := maxf(2.0, lf * 0.016)
		var ct := maxf(2.0, lf * 0.03)
		var streak_x := X(lerpf(float(d.dlo_r), float(d.a_bot), 0.55))
		var streak_w := maxf(2.0, lf * 0.022)
		var a_bot_x := X(float(d.a_bot))
		var dlo_x := X(float(d.dlo_r))
		for xx in range(maxi(0, x_lo), mini(w, x_hi + 1)):
			var t0 := top_y[xx]
			if t0 < 0: continue
			var fx := (float(xx) - float(ox)) / lf
			var sh_y := Y(shoulder(fx))
			var span := maxf(3.0, sill - sh_y)
			var dl := float(xx - x_lo)
			var dr := float(x_hi - xx)
			# the horizon lifts where the body turns away at either end
			var h_t := 0.42 - 0.1 * clampf(1.0 - minf(dl, dr) / (end_k * 4.0), 0.0, 1.0)
			var hl := maxf(1.0, float(u)) / span
			# specular runs along the shoulder over the front fender and the rear quarter
			var spec_side := (float(xx) > a_bot_x + lf * 0.02 and float(xx) < X(float(d.nose_x)) - lf * 0.06) or (float(xx) < dlo_x - lf * 0.01 and float(xx) > float(x_lo) + lf * 0.05)
			for yy in range(t0, bot_y[xx] + 1):
				var i := yy * w + xx
				if bm[i] == 0 or gm[i] != 0: continue
				var from_top := yy - t0
				var bay := float(BAYER_K[(yy & 3) * 4 + (xx & 3)])
				var l := 4
				var t := (float(yy) - sh_y) / span
				if float(yy) < sh_y - 0.5:
					# hood, roof, deck and pillars: lit from above, a streak of sky along the crest
					l = 7 if from_top == 0 else (6 if from_top <= u else 5)
					if from_top == u and not matte and int(float(xx) * 0.09 + float(t0) * 0.02) % 3 != 0: l = 8 if chrome else 7
				else:
					var td := t + (bay - 0.5) * 0.05
					if matte:
						l = 6 if td < 0.05 else (4 if td < 0.5 else (3 if td < 0.85 else 1))
					elif chrome:
						# a mirror: the sky deepening down to a hard black horizon, then the road
						# coming back up out of the dark, lightest just before the rocker turns under
						# a mirror: deep sky at the shoulder paling down to a white horizon, a hard black
						# horizon line, then the road coming back up out of the dark, lightest just
						# before the rocker turns under; hard white glints across it
						var hz := 0.22 + sin(fx * 31.0) * 0.012
						var c_m := 0
						if td < 0.03: c_m = 0
						elif td < 0.09: c_m = 1
						elif td < hz - 0.05: c_m = 2
						elif td < hz - hl * 1.5: c_m = 3
						elif td < hz: c_m = 4
						elif td < hz + hl * 2.0: c_m = 5
						elif td < hz + 0.16: c_m = 6
						elif td < 0.5: c_m = 7
						elif td < 0.75: c_m = 8
						elif td < 0.82: c_m = 9
						elif td < 0.9: c_m = 10
						else: c_m = 11
						# polished metal: bright vertical streaks where the panels break
						for bx: float in breaks:
							var dbx := absf(float(xx) - bx)
							if td > hz + hl * 2.0 and td < 0.82 and dbx >= 1.0 and dbx < 2.0 + float(u): c_m = 4 if dbx < 2.0 else 2
						var sx2 := streak_x - (float(yy) - sh_y) * 0.45
						if td > hz + 0.06 and td < 0.75 and absf(float(xx) - sx2) < streak_w * 0.5: c_m = 3
						if from_top == 0: c_m = 0
						buf[i] = mirror[c_m]
						continue
					elif hq:
						# garage size: a bright shoulder that follows the body line, a darker recess under it,
						# the doors curving from sky to belly in steps, the reflection band broken at every door
						# cut, a lit rocker edge
						var near_break := false
						for bx: float in breaks:
							if absf(float(xx) - bx) < 1.5: near_break = true
						var band := 0.27 + 0.03 * sin(floor((float(xx) - float(x_lo)) / maxf(8.0, lf * 0.2)) * 2.1)
						if td < 0.025: l = 8 if spec_side else 7
						elif td < 0.075: l = 6
						elif td < 0.13: l = 3 if bay > (td - 0.075) / 0.055 else 4
						elif td < band - 0.04: l = 5 if bay > (td - 0.13) / maxf(0.02, band - 0.17) * 0.6 else 4
						elif td < band + 0.03: l = 6 if not near_break else 4
						elif td < h_t: l = 4
						elif td < h_t + hl: l = 1
						elif td < 0.62: l = 3 if bay > (td - h_t) / maxf(0.05, 0.62 - h_t) else 2
						elif td < 0.8: l = 2 if bay > (td - 0.62) / 0.18 else 1
						elif td < 0.86: l = 1
						elif td < 0.86 + hl * 1.5: l = 4
						else: l = 0
						var sx3 := streak_x - (float(yy) - sh_y) * 0.45
						if td > 0.13 and td < h_t and absf(float(xx) - sx3) < streak_w and not near_break: l = mini(l + 1, 7)
					else:
						if td < 0.03: l = 8 if spec_side else 7
						elif td < 0.1: l = 6
						elif td < h_t - 0.07: l = 5
						elif td < h_t: l = 5 if bay > (td - (h_t - 0.07)) / 0.07 else 4
						elif td < h_t + hl: l = 1
						elif td < 0.7: l = 2
						elif td < 0.84: l = 2 if bay > (td - 0.7) / 0.14 else 1
						elif td < 0.94: l = 1
						else: l = 0
						# a slanted reflection across the doors
						var sx := streak_x - (float(yy) - sh_y) * 0.45
						if td > 0.06 and td < h_t and absf(float(xx) - sx) < streak_w: l = mini(l + 1, 7)
					if from_top == 0: l = 7
					# the ends of the car turn away from us
					if (dl < end_k or dr < end_k) and t > 0.08 and l >= 0: l = maxi(0, l - 1)
				# the fenders: a lit crescent over each wheel and a lip on the arch
				if hq and t > 0.0 and l >= 3:
					# a soft hotspot on the fender crown over each wheel
					for wv2: Array in wheels:
						var ac2: Vector2 = wv2[3]
						var ex := (float(xx) - ac2.x) / (arch_r * 0.75)
						var ey := (float(yy) - (ac2.y - arch_r * 1.35)) / maxf(2.0, arch_r * 0.32)
						var e2 := ex * ex + ey * ey
						if e2 < 1.0 and bay > e2 * 0.9: l = mini(l + 1, 7)
				if t > -0.05 and not matte and l >= 0:
					for wv: Array in wheels:
						var ac: Vector2 = wv[3]
						var dx := float(xx) + 0.5 - ac.x
						var dy := float(yy) + 0.5 - ac.y
						if absf(dx) > arch_r + ct or dy > arch_r * 0.2 or dy < -(arch_r + ct): continue
						if skirted(wv): continue
						var k := 0
						while k <= int(ct) and not in_arch(dx, dy, arch_r + float(k)): k += 1
						if k > int(ct): continue
						if k <= 1: l = 6 if dy < -arch_r * 0.35 else 3
						elif dy < -arch_r * 0.15 and bay > float(k) / ct * 0.8: l = mini(l + 1, 7)
				if flake and t > 0.1 and ((xx * 73 + yy * 151) % 23 == 0) and l > 0:
					buf[i] = c_flk if t < 0.45 else c_flk2
					continue
				buf[i] = c_gnd_lt if l < 0 else lv[l]
		# a rim of light down the tail, where it faces the light
		if not matte:
			for yy in range(maxi(0, y_lo), mini(hgt, y_hi + 1)):
				for xx in range(maxi(1, x_lo), mini(w, x_lo + int(lf * 0.12))):
					var i := yy * w + xx
					if bm[i] == 0 or gm[i] != 0 or bm[i - 1] != 0: continue
					if float(yy) < sill - 1.0 and float(yy) > float(top_y[xx]) + 1.0: buf[i] = lv[6] if float(yy) < Y(float(d.belt_r)) + lf * 0.06 else lv[3]
					break

	const BAYER_K: Array[float] = [0.0, 0.53, 0.13, 0.67, 0.8, 0.27, 0.93, 0.4, 0.2, 0.73, 0.07, 0.6, 1.0, 0.47, 0.87, 0.33]

	## Blue glass: pale at the top, deep at the bottom, the seats and headrests dark behind it, two
	## streaks of reflection across it. Tint darkens it and hides the cabin.
	func _shade_glass() -> void:
		if glass.is_empty(): return
		var tint := clampf(float(mods.get("tint", 0.0)), 0.0, 1.0)
		var gx0 := int(X(float(d.dlo_r)))
		var gx1 := int(X(float(d.a_bot)))
		var cols := [CarGen.GLASS_TOP.darkened(tint * 0.55), CarGen.GLASS.darkened(tint * 0.55), CarGen.GLASS_LO.darkened(tint * 0.6)]
		var cab := CarGen.GLASS.darkened(0.42 + tint * 0.3).lerp(CarGen.CABIN, 0.25)
		var streak := CarGen.GLASS_TOP.lightened(0.12).darkened(tint * 0.4)
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
				if len >= 150:
					# the sky lies across the top of the glass in two tones, cut on a slant; under it
					# you see in: the dark cabin, the seat backs and the headrests
					var sxf := float(xx - gx0) / maxf(1.0, float(gx1 - gx0))
					var cut := 0.34 + 0.16 * sxf
					if f < 0.1: c = cols[0].lightened(0.12)
					elif f < cut: c = cols[0]
					elif f < cut + 0.08: c = cols[1]
					else: c = cols[1].lerp(cab, 0.45) if f < 0.8 else cols[2]
				if tint < 0.9 and _in_seat(seats, xx, yy): c = cab
				var s := (float(xx - gx0) / maxf(1.0, float(gx1 - gx0))) + f * 0.14
				if tint < 0.95 and ((s > 0.3 and s < 0.33) or (s > 0.37 and s < 0.45)) and f < 0.92: c = streak
				buf[i] = c.to_abgr32()


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

	## Stripes and liveries. Racing stripes run over the top of the car, so from the side they're
	## a solid band down the crest of the hood and the deck (never across the glass), the whole
	## roof skin above the side glass, a pinstripe under the band and a shut line where the hood
	## and the trunk lid end. Side stripes are one band down the flank; a rally car carries a
	## number plate on the front door. Liveries: a slash, a two-tone split, a sponsor's block on
	## the doors, flames off the front wheel. With no colour picked, the stripe stands out from
	## the paint: dark on pale paint, light on dark.
	func _livery() -> void:
		var stripes := String(mods.get("stripes", "none"))
		if stripes == "none" and d.art.has("stripes") and not mods.has("stripes"): stripes = String(d.stripe_kind)
		var livery := String(mods.get("livery", "none"))
		var sc: Color = CarGen._col(mods.get("stripe_color", null), Color("1e1e24") if paint_c.get_luminance() > 0.55 else Color("f0ece4"))
		if stripes == "none" and livery == "none": return
		var scd := sc.darkened(0.25)
		var band := clampi(int(round(lf * 0.032)), 3, 10)
		var glass_spans: Array = []
		if d.rear != "open":
			glass_spans.append([float(d.roof_f) - 0.01, float(d.cowl_x) + 0.01])
			match String(d.rear):
				"notch": glass_spans.append([float(d.deck_x) - 0.01, float(d.roof_r) + 0.01])
				"fast": glass_spans.append([lerpf(float(d.roof_r), float(d.tail_x), 0.7), float(d.roof_r) + 0.01])
				"hatch": glass_spans.append([float(d.tail_x) + 0.03, float(d.roof_r) + 0.01])
		# where the hood and the trunk lid end: the stripe breaks there
		var shut_f := int(X(float(d.nose_x) - 0.012))
		var shut_r := int(X(float(d.tail_x) + 0.012))
		var gt := Y(float(d.glass_top))
		var roof0 := X(float(d.dlo_rt))
		var roof1 := X(float(d.a_top))
		for xx in range(x_lo, x_hi + 1):
			var fx := (float(xx) - float(ox)) / lf
			var sh_y := Y(shoulder(fx))
			var span := maxf(3.0, sill - sh_y)
			var over_glass := false
			for gs: Array in glass_spans:
				if fx > float(gs[0]) and fx < float(gs[1]): over_glass = true
			var t0 := top_y[xx]
			var on_roof: bool = d.rear != "open" and float(xx) >= roof0 and float(xx) <= roof1
			for yy in range(maxi(0, t0), bot_y[xx] + 1):
				var mi := yy * w + xx
				if bm[mi] == 0 or gm[mi] != 0: continue
				var s2 := (float(yy) - sh_y) / span
				var on := false
				var c := sc
				match stripes:
					"racing":
						if not over_glass:
							var depth := yy - t0
							if on_roof:
								# the whole roof skin over the side glass
								on = float(yy) < gt - 0.5
							elif depth < band:
								on = true
								if depth == band - 1 and band > 3: c = scd
							elif depth == band + 1 and lod >= 1 and band >= 4 and float(yy) < sh_y:
								on = true          # a pinstripe under the band, one row of paint between
							if on and (xx == shut_f or xx == shut_r) and depth <= band: c = CarGen.INK.lerp(scd, 0.4)
					"side": on = s2 > 0.56 and s2 < 0.56 + maxf(0.07, float(band) / span)
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
				var liv := _livery_px(livery, fx, s2, xx, yy, sc)
				if liv.a > 0.5:
					p.img.set_pixel(xx, yy, liv)
					continue
				if on:
					if stripes == "racing": p.img.set_pixel(xx, yy, c.lightened(0.12) if yy == t0 else c)
					else: p.img.set_pixel(xx, yy, (c.lightened(0.15) if s2 < 0.12 else (scd if s2 > 0.74 else c)))
		if livery == "sponsor" and lod >= 2: _sponsor_text()

	## One pixel of a livery, or a clear colour where it doesn't paint. s2 runs 0 at the shoulder
	## to 1 at the sill.
	func _livery_px(livery: String, fx: float, s2: float, xx: int, yy: int, sc: Color) -> Color:
		var none := Color(0, 0, 0, 0)
		if s2 < 0.0: return none
		match livery:
			"slash":
				var dd := fx + s2 * 0.18
				if dd > 0.18 and dd < 0.26: return sc
				if dd > 0.28 and dd < 0.31: return Color("8a8e96")
				if dd > 0.4 and dd < 0.5 and s2 > 0.3: return Color("b8bcc4") if s2 < 0.6 else sc
			"split":
				# two-tone: the lower body in the second colour under a crisp line, a pinstripe on it
				var line := 0.5 + (0.5 - fx) * 0.08
				if absf(s2 - line) < 0.5 / maxf(4.0, sill - Y(shoulder(fx))): return CarGen.INK.lerp(sc, 0.3)
				if s2 > line: return sc.darkened(0.12) if s2 > 0.86 else sc
			"sponsor":
				# a big panel down the doors, the sponsor's name on it
				var cuts: Array = d.door_cuts
				if cuts.is_empty(): return none
				var x0 := float(cuts[cuts.size() - 1][1]) + 0.01
				var x1 := float(cuts[0][0]) - 0.01
				if fx > x0 and fx < x1 and s2 > 0.22 and s2 < 0.7:
					if s2 < 0.25 or s2 > 0.67: return sc.darkened(0.3)
					return sc
			"flames":
				# five tongues of fire licking back from the front wheel, each one pointed: a yellow
				# heart, orange, red at the tips, a dark edge round the lot
				var fa: Vector2 = wheels[1][3]
				var fx0 := (fa.x - float(ox)) / lf + 0.05
				var reach := fx0 - fx
				if reach < 0.0 or s2 < 0.04 or s2 > 0.7: return none
				var lane := (s2 - 0.04) / 0.132
				var idx := int(lane)
				var v := absf(fposmod(lane, 1.0) - 0.5) * 2.0
				var len_k := (0.2 + 0.26 * float((idx * 7 + 3) % 5) / 4.0) * pow(maxf(0.0, 1.0 - v), 0.6)
				var edge := 1.5 / lf
				if reach > len_k + edge: return none
				if reach > len_k - edge * 0.5: return Color("6a1408")
				var k := reach / maxf(0.001, len_k)
				return Color("f8d850") if k < 0.4 else (Color("f08a24") if k < 0.75 else Color("c8321e"))
		return none

	## The sponsor's name on the door panel: the coffee chain, the parts site, the pizza place.
	func _sponsor_text() -> void:
		var cuts: Array = d.door_cuts
		if cuts.is_empty(): return
		var names := ["TIM BURTONS", "ROCKAUTTO", "PIZZA DELIRIUM", "MARKETTHING"]
		var brand: String = names[absi(hash(String(d.id) + String(d.model))) % names.size()]
		var x0 := X(float(cuts[cuts.size() - 1][1]) + 0.01)
		var x1 := X(float(cuts[0][0]) - 0.01)
		var fx := (x0 + x1) * 0.5
		var sh_y := Y(shoulder((fx - float(ox)) / lf))
		var cy := int(sh_y + (sill - sh_y) * 0.46) - 2
		var c := Color("1e1e24") if CarGen._col(mods.get("stripe_color", null), Color("f0ece4")).get_luminance() > 0.5 else Color("f4f2ea")
		var tw := Pix.text_w(brand)
		if float(tw) > x1 - x0 - 4.0:
			brand = brand.split(" ")[0]
			tw = Pix.text_w(brand)
		if float(tw) <= x1 - x0 - 2.0: p.text(int(fx) - tw / 2, cy, brand, c)

	## A rally plate on the front door: a white roundel with the car's number on it.
	func _rally_plate() -> void:
		var cuts: Array = d.door_cuts
		var dx0: float = float(cuts[0][1]) if cuts.size() > 0 else float(d.dlo_r)
		var dx1: float = float(cuts[0][0]) if cuts.size() > 0 else float(d.a_bot)
		var cx := int(X(lerpf(dx0, dx1, 0.5)))
		var sh_y := Y(shoulder(lerpf(dx0, dx1, 0.5)))
		var cy := int(sh_y + (sill - sh_y) * 0.42)
		var rr := maxf(3.0, (sill - sh_y) * 0.21)
		p.disc(cx, cy, rr + 1.0, CarGen.INK)
		p.disc(cx, cy, rr, Color("f4f2ea"))
		p.disc(cx - 1, cy - 1, rr * 0.4, Color("ffffff"))
		var num := str(1 + absi(hash(String(d.id) + String(d.model))) % 99)
		if rr >= 5.0:
			p.text(cx - Pix.text_w(num) / 2, cy - 2, num, Color("1a1a1e"))
		else:
			p.rect(cx - 1, cy - 1, 2, 3, Color("1a1a1e"))

	## Rust where cars really rust: the arch lips, the rockers, the bottoms of the doors and round
	## the bottom of the windshield. Bubbled blotches, chunky so they read as rot and not dirt,
	## each with a rim of lifted paint round it; more and bigger the further gone it is.
	func _rust() -> void:
		var amt := clampf(float(mods.get("rust", d.art.get("rust", 0.0))), 0.0, 1.0)
		if amt <= 0.0 or lod == 0: return
		var brown := Color("8a4e26")
		var dark := Color("4a2a18")
		var rim := (pal.lt as Color).lerp(Color("d8c8a8"), 0.3)
		var rock := Y(float(d.rocker))
		var belt := Y(float(d.belt_f))
		var ws := Vector2(X(float(d.a_bot)), belt)
		var cell := maxi(2, int(lf / 70.0))
		var cuts: Array = d.door_cuts
		var lip := lf * 0.03
		for xx in range(x_lo, x_hi + 1):
			for yy in range(maxi(0, top_y[xx]), bot_y[xx] + 1):
				if not on_paint(xx, yy): continue
				# how likely this spot is to rot, 0..1
				var pot := 0.0
				for wv: Array in wheels:
					var dd := Vector2(xx, yy).distance_to(wv[3]) - arch_r
					if dd >= 0.0 and dd < lip and float(yy) < sill: pot = maxf(pot, 1.0 - dd / lip)
				if float(yy) > rock - lf * 0.03: pot = maxf(pot, 0.9)
				for dc: Array in cuts:
					if float(xx) > X(float(dc[1])) and float(xx) < X(float(dc[0])) and float(yy) > rock - lf * 0.07: pot = maxf(pot, 0.7)
				var dw := Vector2(xx, yy).distance_to(ws)
				if dw < lf * 0.05: pot = maxf(pot, 0.75 * (1.0 - dw / (lf * 0.05)))
				if pot <= 0.0: continue
				# chunky noise, so the rot comes in blotches
				var n := float(((xx / cell) * 92821 ^ (yy / cell) * 68917 ^ 7919) % 1000) / 1000.0
				var n2 := float(((xx * 31 + yy * 57) ^ 3571) % 100) / 100.0
				var v := pot * (0.55 + 0.45 * n) + n2 * 0.08
				var cut_v := 1.02 - amt * 0.62
				if v > cut_v: p.img.set_pixel(xx, yy, dark if n2 < 0.3 or v > cut_v + 0.25 else brown)
				elif v > cut_v - 0.07: p.img.set_pixel(xx, yy, rim)

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
		# the character line stays out of a racing stripe's band over the hood and the deck
		var striped := String(mods.get("stripes", d.stripe_kind if d.art.has("stripes") else "none")) == "racing"
		var keep := clampi(int(round(lf * 0.032)), 3, 10) + 3 if striped else 0
		if crease > 0.0 and lod >= 1:
			for xx in range(x_lo + 2, x_hi - 1):
				var fx := (float(xx) - float(ox)) / lf
				var sy := Y(shoulder(fx))
				var yy := int(sy + (sill - sy) * crease)
				if yy < top_y[xx] + keep: continue
				if on_paint(xx, yy) and on_paint(xx, yy + 1) and not _near_arch(xx, yy, 2.0):
					p.img.set_pixel(xx, yy, (pal.hi as Color))
					p.img.set_pixel(xx, yy + 1, (pal.sh as Color))
		for t: String in trim:
			match t:
				"spear":
					# a chrome spear down the side, set high or low, straight, dipping over the back door,
					# sweeping up into the fin, or split into a wedge with the second colour inside it
					var sy0 := int(belt + (rock - belt) * float(d.get("spear_y", 0.32)))
					var kind := String(d.get("spear_kind", "straight"))
					var x0 := int(X(0.06))
					var x1 := int(X(0.88))
					var fill := Color("ece6d6") if paint_c.get_luminance() < 0.6 else Color("7a1a1a")
					for xx in range(x0, x1):
						var st := float(xx - x0) / float(maxi(1, x1 - x0))
						var dy := 0
						match kind:
							"dip": dy = int(lf * 0.03) if st < 0.42 else (int(lf * 0.03 * (0.5 - st) / 0.08) if st < 0.5 else 0)
							"sweep": dy = -int(lf * 0.04 * clampf((0.45 - st) / 0.45, 0.0, 1.0))
							"split": dy = 0
						if on_paint(xx, sy0 + dy):
							p.img.set_pixel(xx, sy0 + dy, CarGen.CHROME[3])
							if on_paint(xx, sy0 + dy + 1): p.img.set_pixel(xx, sy0 + dy + 1, CarGen.CHROME[1])
						if kind == "split":
							var low := sy0 + int(lf * 0.035 * (1.0 - st))
							for yy in range(sy0 + 2, low):
								if on_paint(xx, yy): p.img.set_pixel(xx, yy, fill)
							if on_paint(xx, low): p.img.set_pixel(xx, low, CarGen.CHROME[2])
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
						if t == "arch_cladding" and d.get("xo", false): thick = maxf(2.0, lf * 0.02)
						for yy in range(int(ac.y - arch_r - thick) - 1, int(rock) + 2):
							for xx in range(int(ac.x - arch_r - thick) - 1, int(ac.x + arch_r + thick) + 2):
								if not on_paint(xx, yy): continue
								if not _near_arch(xx, yy, thick): continue
								var c4: Color = CarGen.RUBBER if t == "arch_cladding" else CarGen.CHROME[2]
								# the plastic's top edge catches a little light
								if t == "arch_cladding" and not _near_arch(xx, yy - 1, thick): c4 = Color("4a4e56")
								p.img.set_pixel(xx, yy, c4)

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
				# a fender vent behind the front wheel: a dark slot in a chrome frame, slats across it
				var vw := maxi(4, int(lf * 0.045))
				var vh := maxi(3, int(lf * 0.02))
				var vx := int(fa.x + arch_r * 0.6) - vw - int(arch_r * 1.2)
				var vy := int(belt + (rock - belt) * 0.22)
				p.rect(vx, vy, vw, vh, CarGen.WELL)
				for k in range(1, vh, maxi(2, u + 1)): p.hline(vx + 1, vy + k, vw - 2, CarGen.TRIM.lightened(0.15))
				p.frame(vx - 1, vy - 1, vw + 2, vh + 2, CarGen.CHROME[2])
				p.hline(vx - 1, vy - 1, vw + 2, CarGen.CHROME[3])
			"scoop_side":
				# a scoop on the quarter panel ahead of the rear wheel: a raised body-coloured
				# blade, tapering back, with its dark mouth facing forward
				var sx2 := int(ra.x + arch_r * 1.05)
				var sy2 := int(Y(float(d.belt_r)) + (rock - Y(float(d.belt_r))) * 0.22)
				var sw2 := maxi(4, int(lf * 0.055))
				var sh2 := maxi(3, int((rock - Y(float(d.belt_r))) * 0.3))
				var mw := maxi(1, sw2 / 4)
				for k in sw2:
					var t := float(k) / float(sw2 - 1)
					var hh := maxi(1, int(lerpf(float(sh2) * 0.3, float(sh2), t)))
					var y0 := sy2 + (sh2 - hh) / 2
					p.px(sx2 + k, y0 - 1, CarGen.INK)
					p.px(sx2 + k, y0 + hh, CarGen.INK)
					for yy in range(y0, y0 + hh):
						var c: Color = (pal.hi as Color) if yy == y0 else ((pal.base as Color) if yy < y0 + hh - 1 else (pal.sh as Color))
						if k >= sw2 - mw and yy > y0: c = CarGen.WELL
						p.px(sx2 + k, yy, c)
				p.vline(sx2 + sw2, sy2, sh2, CarGen.INK)
			"portholes_roof":
				var phx := int(X(float(d.dlo_r))) - int(lf * 0.035)
				var phy := int(Y(float(d.glass_top))) + int(lf * 0.025)
				p.disc(phx, phy, maxf(1.5, lf * 0.012), CarGen.GLASS)
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
				p.rect(mx, my, 2 * u + 1, u + 1, CarGen.AMBER)
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


	# ------------------------------------------------------------ lamps

	func _lamps() -> void:
		var lights_on: bool = dmg.get("lights", mods.get("lights_on", false))
		var nose := int(X(1.0 - front * 0.2)) - 1
		var tail := int(X(rear * 0.16))
		var lens := Color("fffbe8") if lights_on else Color("d8e2ea")
		var reflector := Color("fff4cc") if lights_on else Color("8c9aaa")
		var head_at := Vector2(-1, -1)
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
				var fr := maxf(1.5, lf * 0.022)
				var fy := _first_body(fx) - int(fr * 0.4)
				p.disc(fx, fy, fr, (pal.base as Color))
				p.disc(fx + int(fr * 0.5), fy, fr * 0.6, lens)
				p.ring(fx, fy, fr + 0.6, CarGen.INK)
				head_at = Vector2(fx + fr, fy)
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
						head_at = Vector2(px0 + pw, py - ph / 2)
					else:
						for xx in range(px0, px0 + pw): gap_px(xx, _first_body(xx) + u + 1)
						gap_px(px0, _first_body(px0) + u)
					# the turn signal and parking lamp low in the bumper
					var sy := int(Y(float(d.nose_mid))) + u
					_lens(nose - 3 * u, sy, 3 * u, 2 * u, CarGen.AMBER)
				"round", "quad":
					var ry := col_top + maxi(2, int(lf * 0.026))
					var rr := maxf(1.5, lf * 0.021)
					var rx := nose - int(rr)
					p.disc(rx, ry, rr + 0.7, CarGen.CHROME[2] if year < 1990 else CarGen.INK)
					p.disc(rx, ry, rr, reflector)
					p.disc(rx + int(rr * 0.25), ry - int(rr * 0.2), rr * 0.7, lens)
					p.px(rx - int(rr * 0.4), ry - int(rr * 0.45), Color.WHITE)
					if d.head == "quad" and lod >= 1:
						var qx := nose - int(rr * 2.7)
						p.disc(qx, ry, rr * 0.82 + 0.7, CarGen.CHROME[2] if year < 1990 else CarGen.INK)
						p.disc(qx, ry, rr * 0.82, reflector.darkened(0.06))
						p.disc(qx + 1, ry - 1, rr * 0.55, lens.darkened(0.06))
					head_at = Vector2(nose, ry)
				"rect":
					var lw := maxi(3, int(lf * 0.045))
					var lh := maxi(3, int(lf * 0.03))
					var ly := col_top + maxi(2, int(lf * 0.012))
					_lamp_block(nose - lw, ly, lw, lh, lens, reflector)
					p.frame(nose - lw - 1, ly - 1, lw + 2, lh + 2, CarGen.CHROME[2] if year < 1985 else CarGen.INK)
					_lens(nose - lw - 2 * u - 1, ly + lh - 2 * u, 2 * u, 2 * u, CarGen.AMBER)
					head_at = Vector2(nose, ly + lh / 2)
				"truck", "tower":
					# an upright lamp stack on the corner of a square face, tucked inside the outline,
					# the indicator under it; a luxury truck's runs nearly to the bumper
					var tw := maxi(3, int(lf * (0.03 if head == "truck" else 0.024)))
					var th := maxi(4, int(lf * (0.046 if head == "truck" else 0.07)))
					var tx := nose - tw - maxi(1, u)
					var tly := _first_body(tx + tw / 2) + maxi(1, u) + 1
					_clipped_lamp(tx, tly, tw, th, lens, reflector)
					_clipped_lamp(tx, tly + th + 1, tw, maxi(2, 2 * u), CarGen.AMBER.lightened(0.2), CarGen.AMBER)
					head_at = Vector2(tx + tw / 2, tly + th / 2)
				_:
					head_at = _sweep_lamp(head, nose, lens, reflector, lights_on)
			if lod >= 1: _grille(nose, head_at)
			if front > 0.12 and head_at.x >= 0.0 and lod >= 1: _crack(int(head_at.x) - int(lf * 0.03), int(head_at.y))
			if lights_on and head_at.x >= 0.0: _bloom(int(head_at.x), int(head_at.y), maxf(4.0, lf * 0.045), Color("fff8de"))
		else:
			p.rect(nose - 2 * u, int(Y(float(d.hood_h))) + u, 3 * u, 3 * u, CarGen.WELL)
		if rear < 0.4:
			var red := CarGen.LAMP_RED if not lights_on else Color("ff3a2e")
			var red_hi := Color("ff7a7a") if not lights_on else Color("ffc4b0")
			var tw := maxi(3, int(lf * 0.034))
			var ty2 := _first_body(tail + tw / 2) + maxi(1, u)
			var tail_at := Vector2(tail, ty2 + int(lf * 0.012))
			match String(d.tail_lamp):
				"fin":
					var fy := _first_body(tail + u) + u
					_lens(tail, fy, maxi(3, int(lf * 0.028)), maxi(3, int(lf * 0.034)), red)
					tail_at = Vector2(tail, fy + int(lf * 0.015))
				"bar":
					var by := int(Y(float(d.tail_h))) + 2 * u
					_lens(tail, by, maxi(4, int(lf * 0.06)), maxi(2, int(lf * 0.018)), red)
					tail_at = Vector2(tail, by + 1)
				"round":
					var rr2 := maxf(1.5, lf * 0.016)
					p.disc(tail + int(rr2), ty2 + int(rr2), rr2 + 0.6, CarGen.INK)
					p.disc(tail + int(rr2), ty2 + int(rr2), rr2, red)
					p.disc(tail + int(rr2) - 1, ty2 + int(rr2) - 1, rr2 * 0.5, red_hi)
					tail_at = Vector2(tail, ty2 + int(rr2))
				"tall":
					var th := maxi(4, int(lf * 0.08))
					_lens(tail, ty2 + u, tw, th, red)
					p.rect(tail, ty2 + u + th - 2 * u, tw, 2 * u, CarGen.AMBER)
					p.hline(tail, ty2 + u + th / 2, tw, Color("f4f0ec") if not lights_on else red_hi)
					tail_at = Vector2(tail, ty2 + th / 2)
				"block":
					_lens(tail, ty2, maxi(4, int(lf * 0.05)), maxi(3, int(lf * 0.036)), red)
				"racetrack":
					# one long thin bar wrapped round the tail
					var rw := int(lf * 0.1)
					for xx in range(tail, tail + rw):
						var top := _first_body(xx) + u
						if not on_paint(xx, top + 1): continue
						p.img.set_pixel(xx, top, red_hi)
						p.img.set_pixel(xx, top + 1, red)
						p.px(xx, top + 2, CarGen.INK)
				"tower":
					# a tall lamp standing up the corner of the tail, from the roof nearly to the bumper
					var tw3 := maxi(2, int(lf * 0.022))
					var t_top := _first_body(tail + tw3) + maxi(2, int(lf * 0.016))
					var t_bot := int(Y(float(d.tail_bot))) - maxi(2, int(lf * 0.04))
					for yy in range(t_top, t_bot):
						var ex := _tail_edge(yy)
						if ex < 0: continue
						for k in tw3:
							var c3 := red_hi if k == 0 else (red if (yy - t_top) % maxi(3, 3 * u) != 0 else red.darkened(0.25))
							if on_paint(ex + k, yy): p.img.set_pixel(ex + k, yy, c3)
						p.px(ex + tw3, yy, CarGen.INK)
					tail_at = Vector2(tail, (t_top + t_bot) / 2)
				_:
					tail_at = _shaped_tail(tail, red, red_hi)
			if rear > 0.12 and lod >= 1: _crack(int(tail_at.x) + int(lf * 0.02), int(tail_at.y))
			if lights_on: _bloom(int(tail_at.x), int(tail_at.y), maxf(3.0, lf * 0.03), Color("ff4a3a"))

	## A lamp lens in a box: bright along the top, the reflector showing through at the bottom.
	func _lamp_block(x0: int, y0: int, lw: int, lh: int, lens: Color, reflector: Color) -> void:
		for k in lh:
			var f := float(k) / float(maxi(1, lh - 1))
			p.hline(x0, y0 + k, lw, lens.lightened(0.5) if k == 0 else (lens if f < 0.5 else (lens.lerp(reflector, 0.5) if f < 0.8 else reflector)))
		if lw > 4 and lh > 3: p.px(x0 + 1, y0 + 1, Color.WHITE)

	## Light coming off a lamp: the lens burns bright and the light falls off round it in the
	## lamp's own colour, in solid steps (half, then a fifth) across a small ellipse. In daylight
	## it stays on the car; at night (a crash with the lights on, or the glow mod) it spills past
	## the outline.
	func _bloom(cx: int, cy: int, r: float, c: Color) -> void:
		var spill: bool = dmg.get("lights", false) or mods.get("glow", false)
		var rx := r
		var ry := maxf(2.0, r * 0.6)
		for dy in range(-int(ceil(ry)), int(ceil(ry)) + 1):
			for dx in range(-int(ceil(rx)), int(ceil(rx)) + 1):
				var e := sqrt(pow(float(dx) / rx, 2.0) + pow(float(dy) / ry, 2.0))
				if e >= 1.0: continue
				var xx := cx + dx
				var yy := cy + dy
				if xx < 0 or yy < 0 or xx >= w or yy >= hgt: continue
				var under := p.img.get_pixel(xx, yy)
				var a := 0.5 if e < 0.5 else 0.2
				if under.a > 0.6: p.img.set_pixel(xx, yy, under.lerp(c, a))
				elif spill: p.img.set_pixel(xx, yy, Color(c, maxf(under.a, a)) if under.a < 0.01 else Color(under.lerp(c, a), maxf(under.a, a)))

	## A lamp box painted only where there's body under it, ink round what shows.
	func _clipped_lamp(x0: int, y0: int, lw: int, lh: int, lens: Color, reflector: Color) -> void:
		for k in lh:
			var f := float(k) / float(maxi(1, lh - 1))
			var c := lens.lightened(0.5) if k == 0 else (lens if f < 0.5 else (lens.lerp(reflector, 0.5) if f < 0.8 else reflector))
			for xx in range(x0, x0 + lw):
				if on_paint(xx, y0 + k): p.img.set_pixel(xx, y0 + k, c)
		for xx in range(x0 - 1, x0 + lw + 1):
			if on_paint(xx, y0 - 1): p.img.set_pixel(xx, y0 - 1, CarGen.INK)
			if on_paint(xx, y0 + lh): p.img.set_pixel(xx, y0 + lh, CarGen.INK)
		for yy in range(y0, y0 + lh):
			if on_paint(x0 - 1, yy): p.img.set_pixel(x0 - 1, yy, CarGen.INK)
			if on_paint(x0 + lw, yy): p.img.set_pixel(x0 + lw, yy, CarGen.INK)

	## The first paint pixel at the tail on row yy, or -1.
	func _tail_edge(yy: int) -> int:
		for xx in range(maxi(0, x_lo), mini(w, x_lo + int(lf * 0.25))):
			if on_paint(xx, yy): return xx
		return -1

	## A headlamp that follows the hood's line back from the nose, shaped the maker's way
	## (MAKERS): a clear lens over a chrome reflector, the indicator at its back end and a
	## projector up front. long sweeps far back, hook drops down at its back end, boomerang
	## kicks down and back, teardrop narrows to a point, blade and split are thin slits (split
	## with a second lamp low in the bumper), led runs a white strip along its bottom, angel
	## rings its projector. Returns where the light comes from.
	func _sweep_lamp(head: String, nose: int, lens: Color, reflector: Color, lights_on: bool) -> Vector2:
		var hl := float(d.get("head_len", 0.0))
		if hl <= 0.0: hl = 0.075 if head == "flush" else (0.095 if head in ["jewel", "angel"] else 0.125)
		var lw := maxi(4, int(lf * hl))
		var lh := maxi(2, int(lf * (0.026 if head != "swept" else 0.024)))
		var amber_t := 0.0 if head in ["flush", "split", "led"] else 0.16
		var first := -1
		var first_ty := 0
		var first_hh := 0
		var last := nose
		var at := Vector2(-1, -1)
		for xx in range(nose - lw, nose + 1):
			if top_y[clampi(xx, 0, w - 1)] < 0: continue
			var t := float(xx - (nose - lw)) / float(maxi(1, lw))
			var off := u + (1 if head == "flush" else 0)
			var hh := lh + int(t * lf * 0.008)
			match head:
				"swept": hh = maxi(2, int(float(lh) * (0.5 + t * 0.9)))
				"long": hh = maxi(2, int(float(lh) * (0.35 + t * 0.95)))
				"hook": hh = lh if t > 0.2 else maxi(3, int(float(lh) * 2.0))
				"boomerang":
					hh = maxi(2, int(float(lh) * 0.8))
					if t < 0.32: off += int((0.32 - t) / 0.32 * float(lh) * 1.4)
				"teardrop": hh = maxi(1, int(float(lh) * (0.25 + 1.25 * t * t)))
				"blade", "split": hh = maxi(2, int(float(lh) * 0.62))
				"led", "angel": hh = lh
			var ty := _first_body(xx) + off
			if not on_paint(xx, ty + hh): continue
			if first < 0:
				first = xx
				first_ty = ty
				first_hh = hh
			for k in hh:
				var f := float(k) / float(maxi(1, hh - 1))
				var c := lens.lightened(0.5) if k == 0 else (lens if f < 0.45 else (lens.lerp(reflector, 0.5) if f < 0.75 else reflector))
				if head == "led" and k == hh - 1 and hh > 2: c = Color("eaf4ff") if not lights_on else Color.WHITE
				if t < amber_t: c = CarGen.AMBER.lightened(0.3) if k == 0 else CarGen.AMBER
				p.img.set_pixel(xx, ty + k, c)
			p.px(xx, ty - 1, CarGen.INK)
			p.px(xx, ty + hh, CarGen.INK)
			last = xx
			at = Vector2(xx, ty + hh / 2)
		if first < 0: return at
		p.vline(first - 1, first_ty - 1, first_hh + 2, CarGen.INK)
		if amber_t > 0.0 and lod >= 1:
			var ax := first + int(float(lw) * amber_t)
			var aty := _first_body(ax) + u
			if head == "boomerang": aty += int(float(lh) * 0.6)
			p.vline(ax, aty, maxi(1, lh - 1), CarGen.INK.lerp(lens, 0.5))
		if not head in ["flush", "split", "blade"] and lod >= 2:
			# the projector: a dark bowl with a bright bulb, ringed on an angel-eye
			var bx := last - int(lf * 0.025)
			var by := _first_body(bx) + u + lh / 2 + 1
			var br := maxf(1.2, lf * 0.009)
			p.disc(bx, by, br + 0.6, CarGen.INK)
			p.disc(bx, by, br, Color("3a4250") if not lights_on else Color("fff8e0"))
			if head == "angel": p.ring(bx, by, br + 0.8, Color("eaf4ff"))
			p.px(bx - 1, by - 1, Color.WHITE)
		if head in ["swept", "long", "teardrop", "hook"] and year >= 2012 and lod >= 1:
			# an LED running light under the lens
			var ly := _first_body(first + lw / 2) + u + lh + 1
			for xx in range(first + 2, last - 1):
				if on_paint(xx, ly): p.img.set_pixel(xx, ly, Color("eaf4ff"))
		if head == "split" and lod >= 1:
			# the main lamp sits low in the bumper, under the thin running light
			var sw := maxi(3, int(float(lw) * 0.32))
			var sy := int(Y(float(d.nose_mid))) - maxi(2, int(lf * 0.022))
			_clipped_lamp(nose - sw - 2 * u, sy, sw, maxi(2, lh - 1), lens, reflector)
		return Vector2(last, at.y)

	## The grille on the nose, side-on, between the headlamp and the bumper's intake: a big dark
	## mouth with a chrome surround, a honeycomb, a chrome waterfall, a chrome bar or a vee, the
	## way the maker draws its face (MAKERS).
	func _grille(nose: int, head_at: Vector2) -> void:
		var kind := String(d.get("grille", "none"))
		if kind == "none" or front >= 0.4: return
		var top := (int(head_at.y) + maxi(2, int(lf * 0.016))) if head_at.x >= 0.0 else _first_body(nose - 2) + 2 * u
		if kind == "waterfall": top = _first_body(nose - 2) + u + 1
		var bot := int(Y(float(d.nose_bot))) - maxi(2, int(lf * 0.034))
		if bot - top < 2: return
		var gw := maxi(2, int(lf * (0.02 if kind in ["big", "hex", "tiger"] else (0.014 if kind == "waterfall" else 0.01))))
		var mid := (top + bot) / 2
		for yy in range(top, bot):
			var fx := nose
			while fx > nose - int(lf * 0.08) and not on_paint(fx, yy): fx -= 1
			if not on_paint(fx, yy): continue
			var t := float(yy - top) / float(maxi(1, bot - top))
			for k in gw:
				var xx := fx - k
				if not on_paint(xx, yy): continue
				var c := Color(0, 0, 0, 0)
				match kind:
					"waterfall": c = CarGen.CHROME[3] if (yy - top) % 2 == 0 else CarGen.CHROME[1]
					"big", "tiger": c = CarGen.CHROME[3] if k == 0 or yy == top or yy == bot - 1 else (CarGen.WELL if (xx + yy) % 2 == 0 else CarGen.TRIM)
					"hex": c = CarGen.CHROME[2] if k == 0 or yy == top else (CarGen.TRIM if (xx * 2 + yy) % 3 == 0 else CarGen.WELL)
					"bar", "split", "kidney": if absi(yy - mid) <= u: c = CarGen.CHROME[3] if yy <= mid else CarGen.CHROME[1]
					"slim": if yy - top <= u: c = CarGen.WELL
					"vee", "beak": if absi(k - int(t * float(gw))) <= 0: c = CarGen.CHROME[3]
				if kind == "split" and absi(yy - mid) > u and t > 0.15 and t < 0.85: c = CarGen.WELL
				if kind == "kidney" and absi(yy - mid) > u and t > 0.1 and t < 0.9: c = CarGen.WELL if k > 0 else CarGen.CHROME[2]
				if c.a > 0.5: p.img.set_pixel(xx, yy, c)
			if kind in ["big", "tiger", "hex", "kidney"] and on_paint(fx - gw, yy): p.img.set_pixel(fx - gw, yy, CarGen.INK)

	## A tail lamp wrapped round the rear corner onto the quarter panel, shaped the maker's way:
	## wrap and swept taper forward, lid carries on across the trunk's shut line, slim is one thin
	## bar, teardrop narrows to a point, dual splits in two, ell drops a leg down the tail, and a
	## boomerang hooks down at its front end.
	func _shaped_tail(tail: int, red: Color, red_hi: Color) -> Vector2:
		var kind := String(d.tail_lamp)
		var tl := float(d.get("tail_len", 0.0))
		if tl <= 0.0: tl = 0.06 if kind == "wrap" else 0.08
		var ww := maxi(4, int(lf * tl))
		var hh2 := maxi(3, int(lf * 0.034))
		var thin := maxi(2, int(lf * 0.017))
		var ty0 := int(Y(float(d.tail_h))) + maxi(1, u)
		for xx in range(tail, tail + ww):
			var t2 := float(xx - tail) / float(maxi(1, ww))
			var hh3 := maxi(2, int(float(hh2) * (1.0 - t2 * (0.5 if kind in ["wrap", "lid", "dual"] else 0.7))))
			match kind:
				"slim": hh3 = thin
				"teardrop": hh3 = maxi(1, int(float(hh2) * (1.15 - t2)))
				"ell": hh3 = thin if t2 > 0.2 else int(float(hh2) * 1.9)
				"boomerang": hh3 = thin if t2 < 0.8 else int(float(hh2) * 1.6)
			var top := maxi(ty0, _first_body(xx) + u)
			if not on_paint(xx, top + hh3): continue
			var gap := (kind == "lid" and absf(t2 - 0.45) < 0.5 / float(ww)) or (kind == "dual" and absf(t2 - 0.5) < 0.5 / float(ww))
			for k in hh3:
				var c := red
				if k == 0: c = red_hi
				elif k == hh3 - 1 and hh3 > 3: c = red.darkened(0.3)
				elif k == hh3 / 2 and hh3 > 4 and lod >= 2: c = red.lightened(0.12)
				if gap: c = gap_c() if kind == "lid" else (pal.base as Color)
				p.img.set_pixel(xx, top + k, c)
			p.px(xx, top - 1, CarGen.INK)
			p.px(xx, top + hh3, CarGen.INK)
		p.vline(tail + ww, maxi(ty0, _first_body(tail + ww) + u), maxi(2, (thin if kind in ["slim", "ell"] else hh2 / 2)), CarGen.INK)
		return Vector2(tail, ty0 + hh2 / 2)

	## A cracked lens: a star of dark lines and a missing chip.
	func _crack(cx: int, cy: int) -> void:
		var r := maxf(2.0, lf * 0.018)
		for k in 4:
			var a := 0.7 + float(k) * 1.6
			p.line(cx, cy, cx + int(cos(a) * r), cy + int(sin(a) * r * 0.7), Color("2a2e36"))
		p.px(cx, cy, CarGen.WELL)

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

	## A van's windshield is long and leans well back, so it shows from the side: a band of glass
	## just inside the outline from the cowl up to the roof, paler at the top.
	func _windshield() -> void:
		if not d.family in ["van", "minivan"] or lod == 0 or front > 0.4: return
		var p0 := Vector2(X(float(d.cowl_x)), Y(float(d.cowl_h)))
		var p1 := Vector2(X(float(d.roof_f)), Y(float(d.cab_top)))
		var along := p1 - p0
		var ln := along.length()
		if ln < 4.0: return
		var dir := along / ln
		var nrm := Vector2(-dir.y, dir.x)
		if nrm.x > 0.0: nrm = -nrm
		var bw := maxf(2.0, lf * 0.018)
		for yy in range(int(p1.y) - 2, int(p0.y) + 2):
			for xx in range(int(minf(p0.x, p1.x)) - int(bw) - 2, int(maxf(p0.x, p1.x)) + 2):
				if not on_paint(xx, yy) or glass_at(xx, yy): continue
				var q := Vector2(float(xx) + 0.5, float(yy) + 0.5) - p0
				var t := q.dot(dir) / ln
				var n := q.dot(nrm)
				if t < 0.05 or t > 0.96 or n < 1.2 or n > bw + 1.2: continue
				var c := CarGen.GLASS_TOP if t > 0.7 else (CarGen.GLASS if t > 0.2 else CarGen.GLASS_LO)
				if absf(t - 0.55) < 0.06: c = CarGen.GLASS_TOP.lightened(0.15)
				if n > bw: c = CarGen.TRIM
				p.img.set_pixel(xx, yy, c)

	## The frame round the side glass, the pillars on it, a vent window, a sunroof or T-tops.
	func _glass_frame() -> void:
		if glass.is_empty(): return
		var trim := CarGen.CHROME[2] if d.frame == "chrome" else CarGen.INK
		var gt := int(Y(float(d.glass_top)))
		var belt := int(Y(float(d.belt_f)))
		var pil_c := (pal.base as Color) if d.pillar == "body" else CarGen.TRIM
		for q: Array in d.pillars:
			if d.hardtop and d.family in ["coupe", "muscle", "sedan"]:
				pil_c = CarGen.CHROME[2]
			var xb := X(float(q[0]))
			var xt := X(float(q[1]))
			var pw := maxf(1.0, float(q[2]) * lf)
			if d.hardtop and d.family in ["coupe", "muscle", "sedan"]: pw = 1.0
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
				p.img.set_pixel(xx, ty, CarGen.GLASS_TOP)
				if xx % 3 == 0: p.img.set_pixel(xx, ty + 1, CarGen.GLASS)
		if d.art.has("sunroof") and lod >= 1:
			var sx0 := int(X(float(d.a_top))) - int(lf * 0.05)
			for xx in range(sx0 - int(lf * 0.1), sx0):
				p.px(xx, _first_body(xx) - 1, CarGen.GLASS)
			p.px(sx0, _first_body(sx0) - 1, CarGen.INK)

	# ------------------------------------------------------------ open cars

	## Roadsters and open 4x4s: a framed windshield, seats and headrests, a folded top or a roll bar.
	func _cabin_open() -> void:
		if d.rear != "open": return
		if d.get("tub", false):
			_tub_cabin()
			return
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
		p.poly(gpts, Color(CarGen.GLASS_TOP, 0.55))
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

	## A Jepp with its doors off: through the opening, the far side of the tub and the seats; an
	## upright windshield frame on the cowl and a roll bar over the back seat.
	func _tub_cabin() -> void:
		var cut := CarGen.tub_cut(d)
		var tub := Y(float(d.belt_r))
		var x0 := int(X(float(cut[0])))
		var x1 := int(X(float(cut[1])))
		var by := int(Y(float(cut[2])))
		var wall := (pal.sh as Color)
		for xx in range(x0, x1 + 1):
			for yy in range(int(tub), by + 1):
				if body_at(xx, yy) or p.get_px(xx, yy).a > 0.6: continue
				p.img.set_pixel(xx, yy, (pal.mid as Color) if yy <= int(tub) + u else wall)
		var seat := Color("2a2622")
		var seat_hi := Color("4a423a")
		# the driver's seat: a back leaning a little, its headrest above the tub
		var sx := int(lerpf(float(x0), float(x1), 0.28))
		var sw := maxi(2, int(lf * 0.03))
		var top := int(tub - lf * 0.06)
		for yy in range(top, by):
			var lean := int(float(yy - top) * 0.2)
			p.hline(sx - lean, yy, sw, seat if yy > top + 1 else seat_hi)
		p.rect(sx - int(float(by - top) * 0.2), by - maxi(2, int(lf * 0.02)), int(lf * 0.07), maxi(2, int(lf * 0.02)), seat)
		p.frame(sx - 1, top - 1, sw + 2, int(lf * 0.03), CarGen.INK)
		# the back seat's headrest over the rear tub
		var rx := int(X(float(cut[0]) - 0.07))
		p.rect(rx, int(tub - lf * 0.045), sw, int(lf * 0.045), seat)
		p.hline(rx, int(tub - lf * 0.045), sw, seat_hi)
		# the steering wheel in front of the seat
		p.line(int(X(float(cut[1]) - 0.02)), int(tub - lf * 0.035), int(X(float(cut[1]) - 0.045)), int(tub + lf * 0.01), Color("1a1a1e"))
		# the windshield: an upright frame standing on the cowl, glass edge-on behind the post
		var cx := X(float(d.cowl_x))
		var cy := Y(float(d.cowl_h))
		var ws_h := lf * 0.5 / float(d.L) / 4.0 * 4.0
		var rake := tan(deg_to_rad(float(d.get("ws_rake", 0.0))))
		var lean2 := (float(d.cowl_x) - float(d.roof_f)) / maxf(0.01, float(d.h) - float(d.cowl_h))
		if rake <= 0.0: rake = lean2
		var post := maxf(2.0, lf * 0.012)
		var frame_c := (pal.base as Color) if year < 1987 else CarGen.TRIM
		var tx := cx - ws_h * rake
		var ty := cy - ws_h
		for k in int(post) + 1:
			p.line(int(cx) - k, int(cy), int(tx) - k, int(ty), frame_c if k > 0 else (pal.hi as Color))
		p.line(int(cx) - int(post) - 1, int(cy), int(tx) - int(post) - 1, int(ty), CarGen.GLASS_TOP)
		p.line(int(cx) + 1, int(cy), int(tx) + 1, int(ty), CarGen.INK)
		p.line(int(cx) - int(post) - 2, int(cy), int(tx) - int(post) - 2, int(ty), CarGen.INK)
		p.rect(int(tx) - int(post) - 2, int(ty) - u, int(post) + 4, 2 * u, frame_c)
		p.frame(int(tx) - int(post) - 3, int(ty) - u - 1, int(post) + 6, 2 * u + 2, CarGen.INK)
		# the roll bar over the back seat, padded black
		var rb := Color("26292f")
		var rb_hi := Color("4a4f58")
		var bf := x0 - maxi(1, int(lf * 0.012))
		var bb := bf - int(lf * 0.13)
		var bt := int(tub - lf * 0.13)
		var bw := maxi(2, int(lf * 0.012))
		for k in bw:
			p.line(bf + k, int(tub), bf + k - int(lf * 0.012), bt, rb)
			p.line(bb + k, int(tub), bb + k + int(lf * 0.01), bt, rb)
			p.line(bb + k + int(lf * 0.01), bt + k, bf + k - int(lf * 0.012), bt + k, rb if k > 0 else rb_hi)
		p.line(bb + int(lf * 0.01), bt, bf, int(tub), rb)

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

	## A modern crossover's floating roof: everything between the roof skin and the shoulder
	## behind the side glass is gloss black, so the roof seems to hover over the car.
	func _float_roof() -> void:
		if not d.get("xo", false) or lod == 0: return
		var rt_px := maxi(1, int(float(d.rt) * lf * 0.8))
		var x1 := int(X(float(d.dlo_r)))
		for xx in range(x_lo, x1 + 2):
			var fx := (float(xx) - float(ox)) / lf
			var sh_y := int(Y(shoulder(fx)))
			for yy in range(top_y[xx] + rt_px, sh_y):
				if not on_paint(xx, yy): continue
				p.img.set_pixel(xx, yy, Color("3a3f48") if yy == top_y[xx] + rt_px else CarGen.TRIM)

	## A sail panel behind a pickup's cab: black plastic on a truck with cladding, body colour
	## with a shut line where it meets the bed otherwise.
	func _sail() -> void:
		var sail := float(d.get("sail", 0.0))
		if sail <= 0.0 or d.rear != "pickup" or lod == 0: return
		var clad: bool = (d.trim as Array).has("cladding")
		var x0 := int(X(float(d.cab_x) - sail))
		var x1 := int(X(float(d.cab_x)))
		var rail := int(Y(float(d.bed_h)))
		for xx in range(x0, x1 + 1):
			for yy in range(top_y[xx], rail + 1):
				if not on_paint(xx, yy): continue
				if clad: p.img.set_pixel(xx, yy, Color("4a4e56") if yy == top_y[xx] else Color("2e3238"))
				elif yy == rail: p.img.set_pixel(xx, yy, gap_c())

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
			if end == 1 and bumper in ["gone", "hang"]: _bare_nose(nose, by)
			if end == 1 and (bumper == "gone" or bash): continue
			if end == 1 and bumper == "hang":
				_hanging_bumper(nose, by, style)
				continue
			var bw := int(lf * (0.07 if style != "steel" else 0.05))
			var bh := maxi(3, int(lf * (0.03 if style == "chrome" else 0.04)))
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

	## With the bumper cover off, the nose shows what's behind it: the dark crash structure and
	## the steel reinforcement bar across it.
	func _bare_nose(nose: int, by: int) -> void:
		if lod == 0: return
		var top := by - int(lf * 0.05)
		for yy in range(top, by + 1):
			for xx in range(nose - int(lf * 0.07), nose + 1):
				if on_paint(xx, yy): p.img.set_pixel(xx, yy, CarGen.WELL if (xx + yy) % 5 != 0 else CarGen.TRIM)
		var bar_y := top + int(lf * 0.018)
		p.rect(nose - int(lf * 0.05), bar_y, int(lf * 0.05) + 2, maxi(2, int(lf * 0.012)), CarGen.STEEL)
		p.hline(nose - int(lf * 0.05), bar_y, int(lf * 0.05) + 2, CarGen.STEEL.lightened(0.3))
		p.frame(nose - int(lf * 0.05) - 1, bar_y - 1, int(lf * 0.05) + 4, maxi(2, int(lf * 0.012)) + 2, CarGen.INK)

	## A bumper hanging off: still clipped on by the front wheel, its nose end down on the road.
	func _hanging_bumper(nose: int, by: int, style: String) -> void:
		var bh := maxf(3.0, lf * 0.034)
		var a := Vector2(float(wheels[1][1]) + arch_r * 0.9, float(by) - bh * 0.6)
		var b := Vector2(float(nose) + lf * 0.05, float(gy) - bh * 0.5)
		var dir := (b - a).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		if nrm.y > 0.0: nrm = -nrm
		var c_mid: Color = pal.base
		var c_top: Color = pal.lt
		var c_low: Color = pal.sh
		match style:
			"chrome", "chrome5":
				c_mid = CarGen.CHROME[2]
				c_top = CarGen.CHROME[4]
				c_low = CarGen.CHROME[0]
			"rubber", "steel":
				c_mid = CarGen.RUBBER if style == "rubber" else CarGen.STEEL
				c_top = c_mid.lightened(0.25)
				c_low = c_mid.darkened(0.35)
		var corners := PackedVector2Array([a + nrm * bh * 0.5, b + nrm * bh * 0.5, b - nrm * bh * 0.5, a - nrm * bh * 0.5])
		p.poly(corners, c_mid)
		p.line(int(a.x + nrm.x * bh * 0.5), int(a.y + nrm.y * bh * 0.5), int(b.x + nrm.x * bh * 0.5), int(b.y + nrm.y * bh * 0.5), c_top)
		p.line(int(a.x - nrm.x * bh * 0.4), int(a.y - nrm.y * bh * 0.4), int(b.x - nrm.x * bh * 0.4), int(b.y - nrm.y * bh * 0.4), c_low)
		# the torn end and the dark inside of the cover where it turned the corner
		p.line(int(b.x), int(b.y - bh * 0.5), int(b.x), int(b.y + bh * 0.5), CarGen.TRIM)
		p.poly_outline(corners, CarGen.INK)
		# a clip strap still holding it up at the wheel
		p.line(int(a.x), int(a.y), int(a.x) - 2, int(a.y) - int(bh), CarGen.TRIM)

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
		if String(d.get("mirror_at", "sail")) == "door":
			# out on the door skin, back from the glass corner
			mx -= int(lf * 0.03)
			my += maxi(1, int(lf * 0.012))
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
		if d.antenna == "mast" and lf >= 120.0:
			# a mast standing up off the front fender by the windshield, or the corner of the deck
			var ax := int(X(float(d.a_bot) + 0.035)) if String(d.get("antenna_at", "front")) == "front" or d.rear != "notch" else int(X(float(d.tail_x) + 0.04))
			var ay := _first_body(ax)
			var ah := int(lf * 0.1)
			p.line(ax, ay, ax - int(lf * 0.012), ay - ah, CarGen.CHROME[1])
			p.px(ax - int(lf * 0.012), ay - ah, CarGen.CHROME[3])
			p.px(ax, ay, CarGen.INK)
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
		if d.get("opera", false) and not (art.has("vinyl") or d.get("vinyl", false)) and lod >= 1:
			# a formal roof's opera window, set in the wide C-pillar
			var ow2 := X(float(d.dlo_r)) - lf * 0.055
			var oy2 := int(Y(float(d.glass_top))) + 2 * u
			p.rect(int(ow2), oy2, maxi(2, int(lf * 0.022)), maxi(2, int(lf * 0.026)), CarGen.GLASS)
			p.frame(int(ow2) - 1, oy2 - 1, maxi(2, int(lf * 0.022)) + 2, maxi(2, int(lf * 0.026)) + 2, CarGen.CHROME[2])
		if art.has("blackroof"):
			for xx in range(int(X(float(d.dlo_rt))) - int(lf * 0.02), int(X(float(d.a_top))) + u):
				var t0 := _first_body(xx)
				for yy in range(t0, int(Y(float(d.glass_top)))):
					if on_paint(xx, yy): p.img.set_pixel(xx, yy, CarGen.TRIM if yy > t0 else Color("3a3e46"))
		if art.has("vinyl") or d.get("vinyl", false):
			var vc := Color("1e1c1e") if paint_c.get_luminance() > 0.3 else Color("e8e2d0")
			for xx in range(int(X(float(d.dlo_rt))) - int(lf * 0.03), int(X(float(d.a_top))) - u):
				var t0 := _first_body(xx)
				var gt := int(Y(float(d.glass_top)))
				for yy in range(t0, gt):
					if on_paint(xx, yy): p.img.set_pixel(xx, yy, vc.lightened(0.12) if (xx + yy * 3) % 7 == 0 else vc)
			# the opera window in the C-pillar
			if (d.doors == 2 or d.get("opera", false)) and lod >= 1:
				var ow := X(float(d.dlo_r)) - lf * 0.05
				p.rect(int(ow), int(Y(float(d.glass_top))) + 2 * u, int(lf * 0.025), int(lf * 0.03), CarGen.GLASS)
				p.frame(int(ow) - 1, int(Y(float(d.glass_top))) + 2 * u - 1, int(lf * 0.025) + 2, int(lf * 0.03) + 2, CarGen.CHROME[2])

	## A light bar on the roof over the windshield: a black housing on two feet, its pods lit.
	func _lightbar() -> void:
		if not mods.get("lightbar", false) or lod == 0: return
		var x1 := int(X(float(d.roof_f))) - int(lf * 0.01)
		var x0 := x1 - maxi(8, int(lf * 0.15))
		var top := 0
		if d.get("tub", false):
			# on a Jepp it rides the roll bar
			var cut := CarGen.tub_cut(d)
			var bf := int(X(float(cut[0]))) - maxi(1, int(lf * 0.012))
			x1 = bf
			x0 = bf - maxi(8, int(lf * 0.13))
			top = int(Y(float(d.belt_r)) - lf * 0.13)
		elif d.rear == "open": return
		else:
			top = gy
			for xx in range(x0, x1): top = mini(top, _first_body(xx))
		var bh := maxi(3, 2 * u + 1)
		var by := top - bh - maxi(1, u)
		for fx2: int in [x0 + 2 * u, x1 - 2 * u]: p.vline(fx2, by + bh, top - by - bh + 1, CarGen.TRIM)
		p.rect(x0, by, x1 - x0, bh, CarGen.TRIM)
		var pods := maxi(3, (x1 - x0) / maxi(3, 3 * u + 1))
		for k in pods:
			var px0 := x0 + 1 + k * (x1 - x0 - 2) / pods
			var pw := maxi(1, (x1 - x0 - 2) / pods - 1)
			p.rect(px0, by + 1, pw, bh - 2, Color("f4f4ec"))
			p.px(px0, by + 1, Color.WHITE)
		p.frame(x0 - 1, by - 1, x1 - x0 + 2, bh + 2, CarGen.INK)

	func _roof_lights() -> void:
		var art: Dictionary = d.art
		var mid := int((X(float(d.roof_f)) + X(float(d.roof_r))) * 0.5)
		var top := _first_body(mid)
		if art.has("beacon"):
			p.rect(mid - 2 * u, top - 3 * u, 4 * u, 3 * u, CarGen.AMBER)
			p.hline(mid - 2 * u, top - 3 * u, 4 * u, CarGen.AMBER.lightened(0.4))
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
		if rear > 0.5 and not mods.has("spoiler"): spoiler = "none"
		# a wing wants a deck under it: a wagon or an SUV gets a spoiler off the roof's back edge
		# instead, and nothing at all where a roof rack is in the way
		if spoiler != "none" and d.rear == "box":
			spoiler = "none" if art.has("rack") else "roof"
		if spoiler in ["wing", "gt", "factory_wing", "tall", "deck"] and d.rear == "hatch" and (float(d.roof_r) - float(d.tail_x)) * float(d.L) < 0.4: spoiler = "roof"
		if spoiler == "roof" and not d.family in ["van", "boxtruck"]:
			var rx := X(float(d.roof_r)) + lf * 0.004
			var rt := float(_first_body(int(rx + lf * 0.03)))
			var pts6 := PackedVector2Array([Vector2(rx - lf * 0.035, rt + 2 * u), Vector2(rx - lf * 0.03, rt - u), Vector2(rx + lf * 0.06, rt - u), Vector2(rx + lf * 0.06, rt + u)])
			p.poly(pts6, (pal.base as Color))
			p.hline(int(rx - lf * 0.03), int(rt - u), int(lf * 0.09), (pal.hi as Color))
			p.poly_outline(pts6, CarGen.INK)
			spoiler = "none"
		if spoiler != "none" and not d.family in ["pickup", "van", "boxtruck"]:
			var dx0 := X(float(d.tail_x) + rear * 0.16) + lf * 0.01
			var dtop := float(_first_body(int(dx0 + lf * 0.05)))
			match spoiler:
				"lip":
					var lx := int(X(float(d.tail_x) + rear * 0.16)) + u
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
			# a raised louvre panel standing up off the hood, its slots facing back
			var hx0 := int(X(float(d.cowl_x) + (float(d.nose_x) - float(d.cowl_x)) * 0.18))
			var hw := maxi(6, int(lf * 0.11))
			var hh := maxi(2, int(lf * 0.012))
			var slot := maxi(2, 2 * u + 1)
			for k in hw:
				var xx := hx0 + k
				var top := _first_body(xx)
				var rise := hh if k > hh and k < hw - 1 else maxi(1, mini(k, hw - 1 - k))
				for yy in range(top - rise, top):
					var c: Color = (pal.hi as Color) if yy == top - rise else (pal.base as Color)
					if k > hh and k < hw - 2 and (k % slot) == 0 and yy > top - rise: c = CarGen.WELL
					p.px(xx, yy, c)
				p.px(xx, top - rise - 1, CarGen.INK)
			p.vline(hx0 - 1, _first_body(hx0) - 1, 2, CarGen.INK)
			p.vline(hx0 + hw, _first_body(hx0 + hw - 1) - 1, 2, CarGen.INK)

	# ------------------------------------------------------------ trucks and 4x4s

	func _truck_things() -> void:
		var art: Dictionary = d.art
		var r := r_tire
		if d.rear == "pickup":
			var bx0 := int(X(0.004 + rear * 0.16))
			var bx1 := int(X(float(d.cab_x) - float(d.get("sail", 0.0)))) - 2
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
					if on_paint(bx1 + 1, yy): p.img.set_pixel(bx1 + 1, yy, gap_c() if d.get("unibody", false) else CarGen.WELL)
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
				pass
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
			# a flap behind each wheel, hung from the body and stopping short of the road
			for wv: Array in wheels:
				var mx := int(float(wv[1]) - arch_r * 0.95) - u
				var my := int(sill)
				var mh := int(float(gy - my) * 0.7)
				var mw := maxi(2, u + 1)
				p.rect(mx, my, mw, mh, CarGen.RUBBER)
				p.vline(mx, my, mh, Color("3e434b"))
				p.frame(mx - 1, my, mw + 2, mh + 1, CarGen.INK)
		# a truck's grille seen from the side: a chrome edge down the face, big on the heavy-duty ones
		if d.boxy and d.family in ["pickup", "suv"] and front < 0.3 and lod >= 1 and d.cls != "crossover":
			var hd: bool = d.cls in ["hd_pickup", "work_truck"]
			var gx := int(X(1.0)) - 1
			var gt := int(Y(float(d.hood_h))) + u
			var gb := int(Y(float(d.nose_bot))) - int(lf * 0.03)
			var gw := maxi(2, int(lf * (0.016 if hd else 0.009)))
			for yy in range(gt, gb):
				for k in gw:
					var xx := gx - k
					if not on_paint(xx, yy): continue
					var t := float(yy - gt) / float(maxi(1, gb - gt))
					var c: Color = CarGen.CHROME[3] if k == gw - 1 else (CarGen.CHROME[2] if t < 0.5 else CarGen.CHROME[1])
					if hd and (yy - gt) % (3 * u + 1) == 0: c = CarGen.CHROME[0]
					p.img.set_pixel(xx, yy, c)
			p.vline(gx - gw, gt, gb - gt, CarGen.INK)

	## A spare on the back door, seen edge-on: the tread face of a tyre, rounded top and bottom,
	## with its blocks, the sidewall's lit edge and the carrier bracket to the body.
	func _spare(sx: int, sy: int, sr: float) -> void:
		var hw := maxf(2.0, sr * 0.3)
		var x0 := float(sx) - hw
		var x1 := float(sx) + hw
		var bx := int(x1) + 1
		p.rect(bx, sy - int(sr * 0.18), maxi(2, int(sr * 0.3)), maxi(2, int(sr * 0.36)), CarGen.TRIM)
		for yy in range(sy - int(sr) - 1, sy + int(sr) + 2):
			var fy := (float(yy) + 0.5 - float(sy)) / sr
			if absf(fy) > 1.0: continue
			# the tyre's round seen from the end: narrower toward the top and the bottom
			var pinch := hw * (1.0 - sqrt(maxf(0.0, 1.0 - fy * fy)) * 0.0) * sqrt(maxf(0.0, 1.0 - pow(absf(fy), 6.0)))
			var a0 := int(round(float(sx) - pinch))
			var a1 := int(round(float(sx) + pinch))
			for xx in range(a0, a1 + 1):
				var c := CarGen.TIRE
				var fx := (float(xx) - x0) / maxf(1.0, x1 - x0)
				if fx < 0.18: c = Color("3a3f48")
				elif fx > 0.85: c = Color("101216")
				# tread blocks: grooves across, staggered left and right of the centre rib
				var rows := maxf(3.0, sr * 0.45)
				var ph := fposmod((fy + 1.0) * rows, 1.0)
				if fx >= 0.18 and fx <= 0.85 and ph < 0.3 and (fx < 0.5) == (int((fy + 1.0) * rows) % 2 == 0): c = Color("0c0d10")
				if absf(fy) > 0.93: c = Color("101216")
				p.px(xx, yy, c)
			p.px(a0 - 1, yy, CarGen.INK)
			p.px(a1 + 1, yy, CarGen.INK)
		p.hline(int(round(float(sx) - hw * 0.4)), sy - int(sr) - 1, int(hw * 0.8) + 1, CarGen.INK)
		p.hline(int(round(float(sx) - hw * 0.4)), sy + int(sr) + 1, int(hw * 0.8) + 1, CarGen.INK)

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
		if ex == "side":
			# side pipes along the rocker, heat shields and all, out just ahead of the rear wheel
			var sx0 := int(ra.x + arch_r) + 2 * u
			var sx1 := int(fa.x - arch_r) - 2 * u
			var sy := int(sill) + 1
			var th := maxi(2, 2 * u)
			p.rect(sx0, sy, sx1 - sx0, th, CarGen.CHROME[2])
			p.hline(sx0, sy, sx1 - sx0, CarGen.CHROME[4])
			if th > 2: p.hline(sx0, sy + th - 1, sx1 - sx0, CarGen.CHROME[1])
			if lod >= 2:
				for k in range(sx0 + 3 * u, sx1 - 2 * u, 3 * u): p.px(k, sy + th / 2, CarGen.CHROME[0])
			p.rect(sx0 - 1, sy, 2, th, CarGen.WELL)
			p.frame(sx0 - 2, sy - 1, sx1 - sx0 + 3, th + 2, CarGen.INK)
		else:
			# round tips poking out from under the rear bumper
			var tips := { "single": 1, "dual": 1, "quad": 2 }.get(ex, 1) as int
			var tr := maxi(2, u + 1)
			var ty := int(Y(float(d.tail_bot))) - tr + u
			for k in tips:
				var tx := tail - 2 * u + k * (tr + 2 * u + 1)
				if ex == "single":
					p.rect(tx + 2 * u, ty + 1, 3 * u, tr - 1, CarGen.TRIM)
					continue
				p.rect(tx, ty, 3 * u + 1, tr, CarGen.CHROME[2])
				p.hline(tx, ty, 3 * u + 1, CarGen.CHROME[4])
				p.vline(tx, ty, tr, CarGen.WELL)
				p.frame(tx - 1, ty - 1, 3 * u + 3, tr + 2, CarGen.INK)

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

	## Under the sills: a car's dark floor pan; a truck's frame rails, its tank, the exhaust and the
	## leaf springs, so a body on a frame stands up off the ground with daylight under it.
	func _underbody() -> void:
		var fd := float(d.get("under", 0.0)) * lf
		if lod == 0 or fd < 0.8: return
		var top := int(sill) + 1
		var rail := maxi(1, int(fd * (0.55 if fd > 4.0 else 1.0)))
		var ra: Vector2 = wheels[0][3]
		var fa: Vector2 = wheels[1][3]
		var x0 := int(X(0.03 + rear * 0.16))
		var x1 := int(X(0.97 - front * 0.2))
		var dark := Color("191c21")
		var mid := Color("2b2f36")
		var lit := Color("474d57")
		for xx in range(x0, x1):
			var over_wheel := absf(float(xx) - ra.x) < arch_r * 0.92 or absf(float(xx) - fa.x) < arch_r * 0.92
			for k in rail:
				var yy := top + k
				if over_wheel or p.get_px(xx, yy).a > 0.6: continue
				# the frame rail: lit along its bottom flange where the road light catches it
				p.px(xx, yy, lit if k == rail - 1 and rail > 1 else (mid if k == 0 else dark))
		# crossmember stubs under the cab and the bed
		if fd > 4.0:
			for f2: float in [0.3, 0.55]:
				var cxm := int(lerpf(ra.x + arch_r, fa.x - arch_r, f2))
				for yy in range(top, top + rail + int(fd * 0.2)):
					if p.get_px(cxm, yy).a < 0.6: p.px(cxm, yy, mid)
		if fd <= 4.0: return
		# the tank and the exhaust between the wheels
		var gap0 := ra.x + arch_r
		var gap1 := fa.x - arch_r
		var tx0 := int(lerpf(gap0, gap1, 0.12))
		var tx1 := int(lerpf(gap0, gap1, 0.5))
		var ty0 := top + rail
		var ty1 := top + int(fd)
		for yy in range(ty0, ty1):
			for xx in range(tx0, tx1):
				if p.get_px(xx, yy).a > 0.6: continue
				var c := mid if yy == ty0 or xx == tx0 else (dark if yy == ty1 - 1 else Color("23272d"))
				if (xx == tx0 or xx == tx1 - 1) and (yy == ty1 - 1): continue
				p.px(xx, yy, c)
		var ey := top + rail + maxi(1, int(fd * 0.25))
		for xx in range(int(ra.x - arch_r * 1.2), tx0):
			if p.get_px(xx, ey).a < 0.6 and absf(float(xx) - ra.x) > arch_r * 0.92: p.px(xx, ey, Color("4a4e56"))
		for xx in range(tx1, int(gap1)):
			if p.get_px(xx, ey).a < 0.6: p.px(xx, ey, Color("3a3e46"))
		# leaf springs ahead of and behind the rear wheel, on a truck
		if d.family == "pickup" or (d.family in ["suv", "offroad"] and year < 2000):
			for side: float in [-1.0, 1.0]:
				var sx := ra.x + side * arch_r * 1.0
				var ex := ra.x + side * arch_r * 1.45
				for k in 6:
					var t := float(k) / 5.0
					var qx := int(lerpf(sx, ex, t))
					var qy := top + rail + int(fd * 0.3 * (1.0 - t))
					if p.get_px(qx, qy).a < 0.6: p.px(qx, qy, Color("3a3e46"))
					if p.get_px(qx, qy + 1).a < 0.6: p.px(qx, qy + 1, dark)

	## The dark inside of each wheel arch, behind the tyre.
	func _wells() -> void:
		for wv: Array in wheels:
			if skirted(wv): continue
			if cycled(wv):
				# the nose sits back between the wheels: shade the body behind the open wheel
				var cc: Vector2 = wv[3]
				for yy in range(int(cc.y - arch_r * 1.3), int(sill) + 2):
					for xx in range(int(cc.x - arch_r * 1.4), int(cc.x + arch_r * 1.4)):
						if on_paint(xx, yy) and Vector2(xx, yy).distance_to(cc) < arch_r * 1.35:
							p.img.set_pixel(xx, yy, (pal.deep as Color) if Vector2(xx, yy).distance_to(cc) < arch_r * 1.1 else (pal.sh as Color))
				continue
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

	## Fender flares: the drift kit's bolt-ons, a rally car's box arches, a muscle car's bulge, a
	## dually's hips. A flare is an arch over the top of the wheel that comes straight down to the
	## sill and stops there: a lit lip along its top, its face shaded round the curve, a dark
	## underside where it turns in toward the tyre, and its shadow on the panel behind it.
	func _flares() -> void:
		var style := "none"
		if String(mods.get("fenders", "stock")) == "flared": style = "bolt"
		elif d.flare != "none": style = String(d.flare)
		if d.art.has("dually"): _dually_hips()
		if style == "trap":
			_trap_flares()
			return
		if style == "none": return
		var box := style == "box"
		var c_hi := (pal.hi as Color)
		var c_lt := (pal.lt as Color)
		var c_base := (pal.base as Color)
		var c_mid := (pal.mid as Color)
		var c_sh := (pal.sh as Color)
		var bottom := int(minf(sill, Y(float(d.rocker)) + float(u)))
		for wv: Array in wheels:
			if style == "bulge" and d.art.has("dually"): continue
			var ac: Vector2 = wv[3]
			var th0 := (2.5 if style == "bulge" else 3.5) * float(u) + lf * (0.006 if style == "bulge" else 0.01)
			var fr0 := arch_r + th0
			for yy in range(int(ac.y - fr0) - 2, bottom + 1):
				# thickest over the top, thinning down the sides to the rocker
				var drop := clampf((float(yy) - ac.y) / maxf(1.0, float(bottom) - ac.y), 0.0, 1.0)
				var th := th0 * (1.0 - 0.5 * drop)
				var fr := arch_r + th
				for xx in range(int(ac.x - fr0 * 1.15) - 2, int(ac.x + fr0 * 1.15) + 3):
					if xx < 0 or yy < 0 or xx >= w or yy >= hgt: continue
					var dx := float(xx) + 0.5 - ac.x
					var dy := float(yy) + 0.5 - ac.y
					# above the hub the flare is a ring; below it, it drops straight to the rocker
					var dd := sqrt(dx * dx + dy * dy) if dy < 0.0 else absf(dx)
					if box: dd = maxf(absf(dx), -dy) * 0.6 + dd * 0.4 if dy < 0.0 else absf(dx)
					if in_arch(dx, dy, arch_r - 0.2) or dd > fr + 1.2: continue
					if dd < arch_r - 0.2: continue
					if dd > fr + 0.2:
						# standing proud: its shadow on the panel, ink where it sticks out past the body
						if on_paint(xx, yy): p.img.set_pixel(xx, yy, c_sh)
						elif p.img.get_pixel(xx, yy).a < 0.5: p.img.set_pixel(xx, yy, CarGen.INK)
						continue
					var up := -dy / maxf(0.5, sqrt(dx * dx + dy * dy))
					var c := c_lt if up > 0.75 else (c_base if up > 0.3 else c_mid)
					if dd > fr - 1.0: c = c_hi if up > 0.5 else (c_lt if up > 0.0 else c_base)
					elif dd < arch_r + 1.2: c = c_sh if up > 0.2 else c_mid
					if yy >= bottom - u: c = c_sh
					p.img.set_pixel(xx, yy, c)
			# the ends stop square at the rocker
			for xx in range(int(ac.x - fr0) - 1, int(ac.x + fr0) + 2):
				if absf(float(xx) + 0.5 - ac.x) >= arch_r - 0.2 and absf(float(xx) + 0.5 - ac.x) <= arch_r + th0 * 0.5 + 1.0: p.px(xx, bottom + 1, CarGen.INK)
			if style == "bolt" and lod >= 1:
				for k in 5:
					var a3 := PI + PI * (0.1 + 0.8 * float(k) / 4.0)
					p.px(int(ac.x + cos(a3) * (fr0 - 1.5 * u)), int(ac.y + sin(a3) * (fr0 - 1.5 * u)), CarGen.CHROME[2])

	## A Jepp's flares: flat-topped trapezoids standing proud of the tub, black plastic from the
	## late eighties on and body colour before, each with a lit top and a dark underside.
	func _trap_flares() -> void:
		var plastic: bool = year >= 1987 and d.make != "Hummor"
		var c_top := Color("5a606a") if plastic else (pal.hi as Color)
		var c_face := Color("30353d") if plastic else (pal.lt as Color)
		var c_low := Color("1c2026") if plastic else (pal.mid as Color)
		var bottom := sill
		var th := maxf(2.0, lf * 0.018)
		for wv: Array in wheels:
			var ac: Vector2 = wv[3]
			var ra := arch_r
			var top := ra * 0.88 + th
			for yy in range(int(ac.y - top) - 2, int(bottom) + 1):
				for xx in range(int(ac.x - ra * 1.1 - th) - 3, int(ac.x + ra * 1.1 + th) + 4):
					var dx := float(xx) + 0.5 - ac.x
					var dy := float(yy) + 0.5 - ac.y
					if in_arch(dx, dy, ra): continue
					var half := ra * 1.02 + th if dy >= 0.0 else lerpf(ra * 1.02 + th, ra * 0.7 + th * 0.9, -dy / top)
					var inside := -dy <= top and absf(dx) <= half
					if not inside:
						if -dy <= top + 1.0 and absf(dx) <= half + 1.0: p.px(xx, yy, CarGen.INK)
						continue
					var c := c_face
					if -dy > top - maxf(1.0, th * 0.4): c = c_top
					elif in_arch(dx, dy, ra + 1.6): c = c_low
					elif dx > half - 1.2: c = c_low
					p.px(xx, yy, c)
			# the flare stops square at the sill
			for xx in range(int(ac.x - ra * 1.02 - th) - 1, int(ac.x + ra * 1.02 + th) + 2):
				if absf(float(xx) + 0.5 - ac.x) >= ra: p.px(xx, int(bottom) + 1, CarGen.INK)

	## A dually's rear hips: one wide fender over both rear tyres, flat across the top with round
	## shoulders, standing out from the bed side down to the rocker.
	func _dually_hips() -> void:
		var ac: Vector2 = wheels[0][3]
		var ra := arch_r * 1.06
		var top := ac.y - ra - maxf(3.0, lf * 0.028)
		var bottom := Y(float(d.rocker))
		var rc := minf(ra * 0.55, (bottom - top) * 0.5)
		var x0 := maxf(ac.x - ra * 1.55, X(0.012))
		var x1 := minf(ac.x + ra * 1.55, X(float(d.get("cab_x", 0.4))) - 3.0)
		var c_hi := (pal.hi as Color)
		var c_lt := (pal.lt as Color)
		var c_base := (pal.base as Color)
		var c_sh := (pal.sh as Color)
		for yy in range(int(top) - 1, int(bottom) + 2):
			for xx in range(int(x0) - 1, int(x1) + 2):
				var fx := float(xx) + 0.5
				var fy := float(yy) + 0.5
				# a rounded box: is this pixel inside, on its edge, or out?
				var qx := maxf(0.0, maxf(x0 + rc - fx, fx - (x1 - rc)))
				var qy := maxf(0.0, top + rc - fy)
				var dist := sqrt(qx * qx + qy * qy) - rc
				if fx < x0 or fx > x1 or fy < top or fy > bottom: dist = maxf(dist, 1.0)
				var dx := fx - ac.x
				var dy := fy - ac.y
				if in_arch(dx, dy, ra): continue
				if dist > 1.0: continue
				if dist > 0.0:
					p.px(xx, yy, CarGen.INK)
					continue
				var f := (fy - top) / maxf(1.0, bottom - top)
				var c := c_hi if fy < top + 1.0 else (c_lt if f < 0.18 else (c_base if f < 0.5 else ((pal.mid as Color) if f < 0.75 else c_sh)))
				if fx > x1 - 1.5 or fx < x0 + 1.5: c = (pal.deep as Color)
				if in_arch(dx, dy, ra + 1.5): c = c_sh
				p.img.set_pixel(xx, yy, c)
		# the hips throw a shadow on the bed side ahead of them
		for yy in range(int(top) + 2, int(bottom)):
			for k in maxi(1, u):
				if on_paint(int(x1) + 2 + k, yy): p.img.set_pixel(int(x1) + 2 + k, yy, (pal.deep as Color))

	func _wheels() -> void:
		var look := CarGen.wheel_look(d, mods, len)
		var rim: String = look[0]
		var wm: Dictionary = look[1]
		for wv: Array in wheels:
			var cx := int(round(float(wv[1])))
			var cy := int(round(float(wv[2])))
			if String(dmg.get("wheel_off", "")) == String(wv[0]):
				# nothing here: _tilt() sits the car down on the bare hub
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

	## A cycle fender: a thin painted arc hugging the top of an open front wheel, on a stay to
	## the hub, the way a hot rod wears them.
	func _cycle_fender() -> void:
		for wv: Array in wheels:
			if not cycled(wv): continue
			var cx := float(wv[1])
			var cy := float(wv[2])
			var r0 := r_tire + maxf(1.5, lf * 0.008)
			var r1 := r0 + maxf(2.0, lf * 0.016)
			for yy in range(int(cy - r1) - 1, int(cy) + 1):
				for xx in range(int(cx - r1) - 1, int(cx + r1) + 2):
					var dd := Vector2(float(xx) + 0.5 - cx, float(yy) + 0.5 - cy)
					var ang := atan2(dd.y, dd.x)
					if ang > -0.35 or ang < -PI + 0.5: continue
					var rr := dd.length()
					if rr < r0 - 0.8 or rr > r1 + 0.8:
						continue
					var c: Color = (pal.hi as Color) if rr > r1 - 1.0 else ((pal.base as Color) if rr > r0 + 0.8 else (pal.sh as Color))
					if rr < r0 or rr > r1: c = CarGen.INK
					p.img.set_pixel(xx, yy, c)
			# the stay from the fender down to the hub
			p.line(int(cx + r0 * 0.5), int(cy - r0 * 0.85), int(cx), int(cy), CarGen.TRIM)

	## A fender skirt over the rear wheel: the body carries on over the top half of it.
	func _skirt(ac: Vector2) -> void:
		var ra := arch_r
		var bottom := int(sill)
		p.hline(int(ac.x - ra) - 1, bottom + 1, int(ra * 2.0) + 3, CarGen.INK)
		# the skirt's edge: a shut line round the arch, and a chrome lip along the bottom
		for k in 40:
			var a := PI * 1.12 + PI * 0.76 * float(k) / 39.0
			var qx := int(ac.x + cos(a) * ra)
			var qy := int(ac.y + sin(a) * ra)
			if qy < bottom and on_paint(qx, qy): p.img.set_pixel(qx, qy, (pal.sh as Color))
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
		_scrapes()
		var smoke := float(dmg.get("smoke", 0.0))
		if smoke > 0.0:
			var sx2 := int(X(0.85 - front * 0.18))
			var by := Y(float(d.belt_f))
			for k in int(6 + smoke * 10.0):
				p.glow(sx2 - k * 2 + int(sin(float(k)) * 3.0), int(by) - 3 - k * 3, (2.0 + float(k) * 0.6) * u, Color(0.82, 0.82, 0.84), 1.0 - float(k) * 0.04)
		var drv: Dictionary = dmg.get("driver", {})
		if not drv.is_empty(): _driver(drv)

	## A crash leaves its marks near the hit: the panels creased in folds, a dent shaded into the
	## door, bare metal scraped through the paint and a patch of grey primer.
	func _scrapes() -> void:
		if lod == 0: return
		var bare := Color("c9cdd2")
		var bare_lo := Color("7e838a")
		var primer := Color("8f8c84")
		var primer_lo := Color("74716b")
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(String(d.get("id", "")) + String(d.get("model", "")))
		var belt := Y(float(d.belt_f))
		for end: int in [1, 0]:
			var amt := front if end == 1 else rear
			if amt < 0.15: continue
			var x_end := X(1.0 - amt * 0.2) if end == 1 else X(amt * 0.16)
			var dir := -1.0 if end == 1 else 1.0
			# creases in the crushed panels, each a dark fold with a lit edge behind it
			var small := lf < 140.0
			for k in 2 + int(amt * 2.0):
				var cx := int(x_end + dir * lf * (0.03 + 0.045 * float(k)))
				var lean := rng.randf_range(-0.35, 0.35)
				for yy in range(_first_body(cx) + u, int(sill) - u):
					var xx := cx + int(float(yy) * lean) - int(belt * lean)
					if (yy + k) % 4 == 0 and not small: continue
					# a dark fold with its lit edge; two pixels of each when the car is small
					if on_paint(xx, yy): p.img.set_pixel(xx, yy, (pal.deep as Color))
					if small and on_paint(xx + int(dir), yy): p.img.set_pixel(xx + int(dir), yy, (pal.deep as Color))
					if on_paint(xx - int(dir), yy): p.img.set_pixel(xx - int(dir), yy, (pal.lt as Color))
					if small and on_paint(xx - 2 * int(dir), yy): p.img.set_pixel(xx - 2 * int(dir), yy, (pal.hi as Color))
			# a dent in the door behind the crumple: dark where it dips away from the light
			var dcx := x_end + dir * lf * rng.randf_range(0.17, 0.22)
			var dcy := lerpf(belt, sill, 0.45)
			var drx := lf * 0.04 * (0.6 + amt * 0.6) * (1.3 if lf < 140.0 else 1.0)
			var dry := drx * 0.55
			for yy in range(int(dcy - dry), int(dcy + dry) + 1):
				for xx in range(int(dcx - drx), int(dcx + drx) + 1):
					var ex := (float(xx) - dcx) / drx
					var ey := (float(yy) - dcy) / dry
					var e := ex * ex + ey * ey
					if e > 1.0 or not on_paint(xx, yy): continue
					# the whole dent sits in shadow, darker toward the light, lit on its far rim
					if ex + ey > 0.5 and e > 0.3: p.img.set_pixel(xx, yy, (pal.lt as Color))
					elif ex + ey < -0.3 and e > 0.2: p.img.set_pixel(xx, yy, (pal.deep as Color))
					else: p.img.set_pixel(xx, yy, (pal.sh as Color))
			# a primer patch on the fender
			var pcx := x_end + dir * lf * rng.randf_range(0.08, 0.12)
			var pcy := lerpf(belt, sill, rng.randf_range(0.2, 0.45))
			var prx := lf * rng.randf_range(0.025, 0.04) * (0.7 + amt * 0.5)
			var pry := prx * 0.65
			for yy in range(int(pcy - pry) - 1, int(pcy + pry) + 2):
				for xx in range(int(pcx - prx) - 1, int(pcx + prx) + 2):
					var e2 := pow((float(xx) - pcx) / prx, 2.0) + pow((float(yy) - pcy) / pry, 2.0) + sin(float(xx) * 1.3 + float(yy) * 0.7) * 0.18
					if e2 > 1.0 or not on_paint(xx, yy): continue
					p.img.set_pixel(xx, yy, primer if e2 < 0.7 else primer_lo)
			# scrapes: bare metal streaks running back from the hit, a dark lower edge under each
			for k in 2 + int(amt * 3.0):
				var sy := lerpf(belt + lf * 0.015, sill - lf * 0.015, rng.randf())
				var sx0 := x_end + dir * lf * rng.randf_range(0.02, 0.05)
				var sl := int(lf * rng.randf_range(0.07, 0.17) * (0.5 + amt * 0.5))
				var slope := rng.randf_range(-0.06, 0.06)
				for t in sl:
					if t % 7 == 5: continue
					var xx2 := int(sx0 + dir * float(t))
					var yy2 := int(sy + float(t) * slope)
					if on_paint(xx2, yy2): p.img.set_pixel(xx2, yy2, bare)
					if t % 3 != 0 and on_paint(xx2, yy2 + 1): p.img.set_pixel(xx2, yy2 + 1, bare_lo)

	## The driver after the crash, slumped against the front window: a head with its hair and a
	## sleeved shoulder behind the glass. With the glass gone, the arm hangs out over the door.
	func _driver(drv: Dictionary) -> void:
		if glass.is_empty() or lod == 0: return
		var sk: Color = drv.get("skin", Color("dcae88"))
		var hc: Color = drv.get("hair", Color("3b2a1e"))
		var sl: Color = drv.get("sleeve", Color("3a4a5a"))
		var broken: bool = dmg.get("glass", false)
		var belt := Y(float(d.belt_f))
		var gt := Y(float(d.glass_top))
		var seats := _seats()
		var fx := X(lerpf(float(d.dlo_r), float(d.a_bot), 0.62))
		if seats.size() > 0: fx = float(seats[0][1]) + lf * 0.03
		var hr := maxf(2.0, lf * 0.024)
		# slumped forward and down against the door: the head low in the window
		var hx := fx + hr * 0.6
		var hy := belt - hr * 1.1
		var lay := Image.create(w, hgt, false, Image.FORMAT_RGBA8)
		var q := Pix.new(1, 1)
		q.img = lay
		q.w = w
		q.h = hgt
		# the shoulder and the upper arm in the sleeve, then the head and its hair
		q.rect(int(hx - hr * 2.2), int(hy + hr * 0.4), int(hr * 2.4), int(belt - hy), sl)
		q.hline(int(hx - hr * 2.2), int(hy + hr * 0.4), int(hr * 2.4), sl.lightened(0.15))
		q.disc(int(hx), int(hy), hr + 1.0, CarGen.INK)
		q.disc(int(hx), int(hy), hr, sk)
		q.disc(int(hx - hr * 0.35), int(hy - hr * 0.35), hr * 0.85, hc)
		q.px(int(hx + hr * 0.5), int(hy + hr * 0.1), sk.darkened(0.25))
		if drv.get("long_hair", false):
			q.rect(int(hx - hr * 1.2), int(hy), int(hr * 1.2), int(hr * 1.8), hc)
			q.vline(int(hx - hr * 1.2) + 1, int(hy + 1), int(hr * 1.4), hc.lightened(0.15))
		# only what shows in the window opening, seen through the glass unless it broke
		var gc := Color(CarGen.GLASS, 0.35)
		for yy in range(maxi(0, int(gt) - 2), mini(hgt, int(belt) + 1)):
			for xx in range(maxi(0, int(hx - hr * 3.0)), mini(w, int(hx + hr * 2.0))):
				var c := lay.get_pixel(xx, yy)
				if c.a < 0.5 or not glass_at(xx, yy): continue
				p.img.set_pixel(xx, yy, c if broken else c.blend(gc))
		if not broken or lf < 120.0: return
		# the arm hangs limp out of the window and down the door: the sleeve over the sill to a
		# bent elbow, the forearm angled down and back, the hand at the end of it
		var aw := maxf(1.5, lf * 0.009)
		var sh := Vector2(hx - hr * 0.3, belt - aw * 0.5)
		var el := sh + Vector2(-lf * 0.008, lf * 0.045)
		var wr := el + Vector2(-lf * 0.026, lf * 0.032)
		var hand := wr + Vector2(-lf * 0.008, lf * 0.012)
		# ink round the whole limb first, then the sleeve, the forearm and the hand
		_limb(sh, el, aw + 1.0, CarGen.INK)
		_limb(el, wr, aw * 0.85 + 1.0, CarGen.INK)
		p.disc(int(hand.x), int(hand.y), aw * 1.1 + 1.0, CarGen.INK)
		_limb(sh, el, aw, sl)
		_limb(sh + Vector2(aw * 0.4, 0.0), el + Vector2(aw * 0.4, 0.0), maxf(0.6, aw * 0.35), sl.lightened(0.18))
		_limb(el, wr, aw * 0.85, sk)
		_limb(el + Vector2(aw * 0.3, aw * 0.2), wr + Vector2(aw * 0.3, aw * 0.2), maxf(0.6, aw * 0.3), sk.darkened(0.18))
		p.disc(int(hand.x), int(hand.y), aw * 1.1, sk)
		p.px(int(hand.x) + 1, int(hand.y) + 1, sk.darkened(0.25))
		# the cuff where the sleeve meets the wrist
		p.disc(int(el.x), int(el.y), aw * 0.95, sl.darkened(0.15))

	## A thick line with round ends, for an arm.
	func _limb(a: Vector2, b: Vector2, r: float, c: Color) -> void:
		var n := maxi(2, int(a.distance_to(b)))
		for k in n + 1:
			var q := a.lerp(b, float(k) / float(n))
			p.disc(int(round(q.x)), int(round(q.y)), r, c)

	## Nothing solid below the road: anything that strayed under the ground line goes, the
	## shadow stays.
	func _clip_ground() -> void:
		var under := Color(0.0, 0.0, 0.02, 0.25) if mods.get("shadow", true) else Color(0, 0, 0, 0)
		for yy in range(gy + 2, hgt):
			for xx in w:
				if p.img.get_pixel(xx, yy).a >= 0.6: p.img.set_pixel(xx, yy, under)

	## A car that lost a wheel sits down on that corner: the whole picture turns about the other
	## wheel's contact patch until the bare brake disc is on the road.
	func _tilt() -> void:
		var side := String(dmg.get("wheel_off", ""))
		var lost: Array = wheels[1] if side == "front" else wheels[0]
		var kept: Array = wheels[0] if side == "front" else wheels[1]
		var hub_r := r_tire * 0.55
		var pivot := Vector2(float(kept[1]), float(gy))
		var span := float(lost[1]) - float(kept[1])
		var ang := atan2(r_tire - hub_r, absf(span)) * signf(span)
		var src: Image = p.img.duplicate()
		var ca := cos(ang)
		var sa := sin(ang)
		p.img.fill(Color(0, 0, 0, 0))
		for yy in hgt:
			for xx in w:
				var c := src.get_pixel(xx, yy)
				# the ground shadow stays where it is
				if c.a > 0.0 and c.a < 0.6: p.img.set_pixel(xx, yy, c)
		for yy in hgt:
			for xx in w:
				var dx := float(xx) + 0.5 - pivot.x
				var dy := float(yy) + 0.5 - pivot.y
				var ix := int(floor(pivot.x + dx * ca + dy * sa))
				var iy := int(floor(pivot.y - dx * sa + dy * ca))
				if ix < 0 or iy < 0 or ix >= w or iy >= hgt: continue
				var c2 := src.get_pixel(ix, iy)
				if c2.a >= 0.6: p.img.set_pixel(xx, yy, c2)
		# the bare hub where the wheel was: the brake disc on the road, the caliper on it
		var hx := int(pivot.x + span * ca)
		var hy := gy - int(hub_r)
		p.disc(hx, hy, hub_r + 0.6, CarGen.INK)
		p.disc(hx, hy, hub_r, Color("6a625c"))
		p.ring(hx, hy, hub_r * 0.8, Color("8a817a"))
		p.disc(hx, hy, hub_r * 0.42, Color("9a9ea4"))
		for k in 5:
			var la := TAU * float(k) / 5.0
			p.px(hx + int(cos(la) * hub_r * 0.3), hy + int(sin(la) * hub_r * 0.3), Color("dadee4"))
		p.rect(hx - int(hub_r * 0.95), hy - int(hub_r * 0.5), maxi(2, int(hub_r * 0.35)), int(hub_r), Color("b8603a"))
		# sparks and a gouge in the road where it dragged
		p.hline(hx - int(lf * 0.08), gy, int(lf * 0.08), Color("3a3632"))
		for k in 4: p.px(hx - int(lf * 0.03) - k * 3 * u, gy - 1 - (k % 2) * u, Color("ffd070"))

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
	if r < 4.5:
		# counter size: a dark tyre and a grey hub, no spokes to turn into a white square
		var q0 := 1.0 - 0.5 / r
		for yy in range(int(floor(ccy - ry - 1.0)), int(ceil(ccy + ry + 1.0))):
			for xx in range(cx - int(r) - 1, cx + int(r) + 2):
				var ddx := float(xx) - float(cx)
				var ddy := float(yy) - ccy
				if (ddx * ddx) / (r * r) + (ddy * ddy) / (ry * ry) <= q0: p.px(xx, yy, tire_c[1])
		var hub := Color("7d838c") if rim != "beadlock" else Color("4a4e56")
		p.px(cx, int(ccy), hub)
		if r >= 3.4:
			p.px(cx - 1, int(ccy), hub.darkened(0.2))
			p.px(cx, int(ccy) - 1, hub.lightened(0.15))
		return
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
			# a round tyre, no single pixels poking out at twelve, three, six and nine o'clock
			if q > 1.0 - 0.55 / r:
				# mud tyres: knobs standing proud of the round
				if kind == "mud" and q < 1.14:
					var a0 := atan2(dy, dx) + spin * 0.5
					if fposmod(a0 * 16.0 / TAU, 1.0) < 0.5: p.px(xx, yy, tire_c[0])
				continue
			var a := atan2(dy, dx)
			var nd := Vector2(dx, dy) / maxf(0.01, dist)
			var lit := nd.dot(light)          # -1 facing away .. 1 facing the light
			if dist > rr:
				# the tyre: a crisp black tread edge, the sidewall lit from the upper left with a
				# bright bead ring just outside the rim
				var t := (dist - rr) / maxf(0.5, r - rr)
				var c: Color
				if sqrt(q) * r > r - 1.45: c = tire_c[0]
				else:
					var k := 1 + int(clampf((lit + 1.0) * 0.5 * 3.0 + (0.4 if t < 0.35 else 0.0), 0.0, 2.99))
					c = tire_c[k]
					if not simple and dist - rr < 1.0 and lit > -0.35: c = tire_c[4]
					elif not simple and absf(t - 0.62) < 0.5 / maxf(1.0, r - rr) and lit > 0.25: c = tire_c[3]
					if kind == "mud" and t > 0.7 and fposmod((a + spin * 0.5) * 16.0 / TAU, 1.0) < 0.3: c = tire_c[0]
					if wall == "white" and not simple and t > 0.25 and t < 0.6: c = Color("e8e6dc") if lit > -0.3 else Color("b8b6ac")
					if wall == "letters" and not simple and t > 0.38 and t < 0.6 and a < -0.6 and a > -2.5:
						var sa := fposmod((a - spin) * 30.0 / TAU, 1.0)
						if sa < 0.55 and int((a - spin) * 30.0 / TAU) % 4 != 3: c = Color("e8e4d8")
				p.px(xx, yy, c)
				continue
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
	if simple:
		p.px(cx, int(ccy), rc.darkened(0.2))
	else:
		p.disc(cx, int(ccy), cap, rc.lerp(Color.WHITE, 0.2) if rim != "beadlock" else Color("3a3e46"))
		p.px(cx - 1, int(ccy) - 1, Color.WHITE)
	if not simple and cap > 1.5: p.ring(cx, int(ccy), cap + 0.5, lo)
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
			# a cross-spoke lattice: eight spokes, an X between each pair, dark behind it
			if rt < 0.24: return shade
			if rt > 0.88: return rc if lit > -0.3 else lo
			var nm := 6 if simple else 8
			var seg_m := TAU / float(nm)
			var um := fposmod(ang + PI / 2.0, seg_m) / seg_m
			var vm := (rt - 0.24) / 0.64
			var wm := 0.15 if not simple else 0.22
			if um < 0.08 or um > 0.92 or absf(um - vm) < wm or absf(um - (1.0 - vm)) < wm:
				return hi if lit > 0.2 else (rc if lit > -0.45 else rc.darkened(0.2))
			return gap
		"wire":
			if rt < 0.24: return shade
			var k3 := fposmod(ang * 24.0 / TAU + rt * 3.0, 1.0)
			var k4 := fposmod(ang * 24.0 / TAU - rt * 3.0, 1.0)
			if k3 < 0.16 or k4 < 0.16: return Color("eef2f6") if lit > -0.2 else Color("a8b0b8")
			return Color("4c5159")
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
			# a shallow bowl: its rim catches the light on the upper left, the inside of the bowl
			# the other way round, darkest where it dips toward the hub
			if rt > 0.82: return hi if lit > 0.2 else (rc if lit > -0.3 else lo)
			if rt < 0.2: return hi if lit > 0.0 else rc
			var bowl := -lit * 0.55 + (rt - 0.5) * 0.9
			if bowl > 0.3: return hi
			if bowl > -0.05: return rc
			if bowl > -0.35: return rc.darkened(0.18)
			return lo
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
	"fjord_mustank_1966": { "top": [[0.0, 0.5, 0.04], [0.02, 0.86, 0.04, "tail"], [0.62, 0.92, 0.06, "deck"], [1.2, 1.26, 0.08, "roof_r"], [1.75, 1.3, 0.3], [2.18, 1.27, 0.08, "roof_f"], [2.65, 0.94, 0.05, "cowl"], [4.45, 0.86, 0.06, "hood"], [4.61, 0.66, 0.04, "nose"]], "H": 1.3, "hood_h": 0.75, "cowl_rise": 0.10, "cowl_d": 2.0, "rake": 50.0, "deck": 0.58, "tail_h": 0.88, "bl_rake": 54.0,
		"kick": 0.03, "soft": 0.45, "side_vent": "scoop_side", "head": "round", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "none" },
	"fjord_mustank_fastback_1969": { "top": [[0.0, 0.52, 0.04], [0.02, 0.9, 0.04], [0.3, 0.95, 0.08, "tail"], [1.55, 1.25, 0.15, "roof_r"], [2.0, 1.29, 0.3], [2.25, 1.26, 0.08, "roof_f"], [2.72, 0.97, 0.05, "cowl"], [4.6, 0.88, 0.06, "hood"], [4.8, 0.68, 0.04, "nose"]], "rear": "fast", "H": 1.29, "hood_h": 0.75, "cowl_rise": 0.09, "cowl_d": 2.1, "rake": 54.0, "tail_h": 0.9,
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
	"chevrolay_camareo_ess_ess_2016": { "top": [[0.0, 0.62, 0.06], [0.04, 1.06, 0.06, "tail"], [0.75, 1.1, 0.12, "deck"], [1.45, 1.32, 0.2, "roof_r"], [1.95, 1.35, 0.3], [2.25, 1.32, 0.12, "roof_f"], [2.9, 1.07, 0.1, "cowl"], [4.55, 0.92, 0.12, "hood"], [4.78, 0.78, 0.06, "nose"]], "H": 1.35, "hood_h": 0.86, "cowl_rise": 0.2, "cowl_d": 2.0, "rake": 64.0, "belt_up": 0.04,
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
	"dodgy_charjer_1969": { "top": [[0.0, 0.52, 0.04], [0.02, 0.92, 0.04, "tail"], [0.7, 0.97, 0.08, "deck"], [1.35, 1.3, 0.15, "roof_r"], [2.0, 1.34, 0.4], [2.52, 1.31, 0.08, "roof_f"], [3.05, 0.98, 0.05, "cowl"], [5.15, 0.9, 0.06, "hood"], [5.3, 0.7, 0.04, "nose"]], "rear": "notch", "H": 1.34, "hood_h": 0.75, "cowl_rise": 0.10, "cowl_d": 2.25, "rake": 55.0, "tail_h": 0.92, "bl_rake": 70.0,
		"c_top": 0.08, "c_bot": -0.38, "kick": 0.07, "soft": 0.45, "head": "hidden", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel",
		"wall": "letters", "stripe_kind": "tail" },
	"dodgy_challenjer_1970": { "H": 1.29, "hood_h": 0.75, "cowl_rise": 0.09, "cowl_d": 2.1, "rake": 54.0, "deck": 0.6, "tail_h": 0.92, "bl_rake": 64.0,
		"c_bot": -0.18, "kick": 0.03, "soft": 0.4, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "steel", "wall": "letters", "stripe_kind": "side" },
	"plymooth_cudda_1970": { "H": 1.29, "hood_h": 0.73, "cowl_rise": 0.10, "cowl_d": 2.05, "rake": 54.0, "deck": 0.58, "tail_h": 0.9, "bl_rake": 64.0,
		"c_bot": -0.18, "kick": 0.03, "soft": 0.45, "head": "quad", "tail_lamp": "bar", "hardtop": true, "rim_style": "fivespoke", "wall": "letters",
		"stripe_kind": "hockey" },
	"dodgy_challenjer_hellcatt_2017": { "H": 1.45, "hood_h": 0.9, "cowl_rise": 0.16, "cowl_d": 2.15, "rake": 62.0, "belt_up": 0.06, "deck": 0.56,
		"tail_h": 1.06, "bl_rake": 66.0, "c_bot": -0.16, "kick": 0.03, "soft": 0.75, "head": "round", "tail_lamp": "racetrack", "rim_style": "fivespoke", "rim_frac": 0.74 },
	"plymooth_superburd_1970": { "top": [[0.0, 0.52, 0.04], [0.02, 0.9, 0.04, "tail"], [0.95, 0.95, 0.08, "deck"], [1.6, 1.3, 0.12, "roof_r"], [2.2, 1.34, 0.35], [2.65, 1.31, 0.08, "roof_f"], [3.2, 0.98, 0.05, "cowl"], [4.6, 0.88, 0.12], [5.25, 0.72, 0.3, "hood"], [5.6, 0.5, 0.06, "nose"]],
		"H": 1.34, "hood_h": 0.88, "cowl_rise": 0.1, "cowl_d": 2.4, "rake": 55.0, "deck": 0.95, "tail_h": 0.9, "bl_rake": 64.0, "c_bot": -0.3, "nose": "wedge",
		"nose_lean": 0.3, "nose_bot": 0.3, "head": "popup", "tail_lamp": "bar", "wing_kind": "tall", "rim_style": "steel", "wall": "letters", "antenna": "none" },
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
	"fjord_thunderburd_1957": { "top": [[0.0, 0.5, 0.03], [0.04, 0.94, 0.03, "tail"], [0.6, 0.9, 0.2], [1.25, 0.88, 0.04, "deck"], [1.42, 1.26, 0.06, "roof_r"], [2.1, 1.3, 0.1], [2.32, 1.27, 0.04, "roof_f"], [2.6, 0.95, 0.04, "cowl"], [4.45, 0.88, 0.08, "hood"], [4.65, 0.64, 0.05, "nose"]],
		"H": 1.3, "doors": 2, "quarter": false, "soft": 0.9, "head": "round", "tail_lamp": "fin", "wall": "white", "rim_style": "hubcap", "side_vent": "portholes_roof" },
	"chequer_marathone_1978": { "H": 1.6, "hood_h": 0.92, "cowl_rise": 0.1, "cowl_d": 1.95, "rake": 32.0, "deck": 0.8, "tail_h": 0.98, "bl_rake": 30.0,
		"soft": 0.45, "crown": 0.03, "head": "quad", "bumper": "chrome5", "rim_style": "hubcap" },
	# --- sports cars, then and now
	"chevrolay_corvet_1963": { "top": [[0.0, 0.48, 0.06], [0.05, 0.78, 0.1], [0.5, 0.86, 0.2, "tail"], [1.5, 1.2, 0.25, "roof_r"], [1.85, 1.26, 0.25], [2.05, 1.24, 0.1, "roof_f"], [2.45, 0.98, 0.06, "cowl"], [3.6, 0.85, 0.35], [4.3, 0.7, 0.15, "hood"], [4.45, 0.52, 0.06, "nose"]], "rear": "fast", "H": 1.26, "hood_h": 0.66, "cowl_rise": 0.2, "cowl_d": 2.15, "rake": 58.0, "tail_h": 0.8, "bl_rake": 76.0,
		"c_bot": -0.35, "kick": 0.05, "soft": 0.7, "nose": "wedge", "head": "hidden", "tail_lamp": "round", "side_vent": "vent", "rim_style": "dish", "wall": "white" },
	"chevrolay_corvet_1979": { "top": [[0.0, 0.5, 0.06], [0.03, 0.88, 0.06, "tail"], [0.7, 0.93, 0.25], [1.25, 1.0, 0.2], [1.6, 1.18, 0.15, "roof_r"], [1.95, 1.21, 0.2], [2.15, 1.18, 0.08, "roof_f"], [2.55, 0.92, 0.06, "cowl"], [3.6, 0.88, 0.35], [4.4, 0.7, 0.2, "hood"], [4.7, 0.5, 0.06, "nose"]], "rear": "fast", "H": 1.21, "hood_h": 0.6, "cowl_rise": 0.3, "cowl_d": 2.4, "rake": 64.0, "tail_h": 0.92, "bl_rake": 70.0,
		"c_bot": -0.22, "kick": 0.08, "soft": 0.8, "nose": "wedge", "nose_drop": 0.1, "head": "popup", "tail_lamp": "round", "side_vent": "vent",
		"rim_style": "fivespoke", "wall": "letters", "bumper": "body" },
	"chevrolay_corvet_1997": { "head": "popup", "tail_lamp": "round" },
	"deloreon_dmz_twelve_1981": { "top": [[0.0, 0.5, 0.02], [0.02, 0.92, 0.02, "tail"], [0.42, 0.95, 0.02, "deck"], [1.45, 1.13, 0.03, "roof_r"], [2.25, 1.14, 0.03, "roof_f"], [2.72, 0.93, 0.02, "cowl"], [4.15, 0.7, 0.02, "hood"], [4.27, 0.55, 0.02, "nose"]], "rear": "notch", "H": 1.14, "hood_h": 0.6, "cowl_rise": 0.26, "cowl_d": 1.55, "rake": 64.0, "deck": 0.45, "tail_h": 0.92,
		"bl_rake": 78.0, "c_top": 0.06, "c_bot": -0.08, "soft": 0.06, "nose": "wedge", "nose_drop": 0.14, "head": "rect", "tail_lamp": "block",
		"bumper": "rubber", "rim_style": "turbofan", "trim": ["moulding"], "art": { "louvers": true } },
	"fjord_gt_fourty_ish_2005": { "top": [[0.0, 0.55, 0.06], [0.03, 0.97, 0.05, "tail"], [0.6, 1.0, 0.3], [1.1, 1.03, 0.2, "deck"], [1.55, 1.1, 0.3, "roof_r"], [2.25, 1.12, 0.4], [2.62, 1.09, 0.2, "roof_f"], [3.15, 0.84, 0.12, "cowl"], [3.75, 0.76, 0.3], [4.45, 0.62, 0.12, "hood"], [4.64, 0.45, 0.06, "nose"]],
		"H": 1.12, "hood_h": 0.64, "cowl_rise": 0.2, "cowl_d": 1.5, "rake": 66.0, "deck": 0.95, "tail_h": 0.98, "bl_rake": 80.0, "ff": 0.6,
		"soft": 1.0, "nose": "round", "head": "jewel", "tail_lamp": "round", "rim_style": "tenspoke", "art": { "louvers": true, "stripes": true } },
	"porch_neuner_1973": { "top": [[0.0, 0.5, 0.12], [0.05, 0.7, 0.12, "tail"], [0.45, 0.86, 0.3], [1.15, 1.18, 0.3, "roof_r"], [1.75, 1.29, 0.45], [2.05, 1.26, 0.2, "roof_f"], [2.6, 0.95, 0.1, "cowl"], [3.3, 0.82, 0.4], [3.85, 0.79, 0.15], [4.08, 0.62, 0.1, "hood"], [4.15, 0.48, 0.06, "nose"]], "brow_d": 0.34, "brow_h": 0.76, "hood_h": 0.6, "nose_drop": 0.14, "head": "round", "tail_lamp": "bar", "bumper": "chrome", "rim_style": "fivespoke" },
	"porch_neuner_turbo_1986": { "top": [[0.0, 0.5, 0.12], [0.05, 0.72, 0.12, "tail"], [0.5, 0.88, 0.3], [1.22, 1.18, 0.3, "roof_r"], [1.85, 1.28, 0.45], [2.15, 1.25, 0.2, "roof_f"], [2.72, 0.95, 0.1, "cowl"], [3.4, 0.83, 0.4], [3.98, 0.8, 0.15], [4.22, 0.62, 0.1, "hood"], [4.29, 0.48, 0.06, "nose"]], "brow_d": 0.34, "brow_h": 0.76, "hood_h": 0.6, "nose_drop": 0.14, "kick": 0.06, "head": "round", "tail_lamp": "bar", "bumper": "body", "rim_style": "fivespoke", "flare": "bulge",
		"wing_kind": "whale", "tire": 1.04 },
	"ferraree_testosterona_1987": { "top": [[0.0, 0.5, 0.02], [0.02, 0.98, 0.03, "tail"], [1.05, 1.0, 0.04, "deck"], [1.8, 1.11, 0.06, "roof_r"], [2.3, 1.13, 0.1], [2.5, 1.11, 0.04, "roof_f"], [3.0, 0.9, 0.03, "cowl"], [4.3, 0.68, 0.05, "hood"], [4.49, 0.52, 0.03, "nose"]], "H": 1.13, "hood_h": 0.6, "cowl_rise": 0.2, "cowl_d": 1.5, "rake": 66.0, "deck": 1.0, "tail_h": 0.98, "bl_rake": 82.0,
		"c_bot": -0.05, "soft": 0.15, "head": "popup", "tail_lamp": "block", "rim_style": "fivespoke" },
	"ferraree_eff_forty_1990": { "top": [[0.0, 0.5, 0.02], [0.02, 1.0, 0.02, "tail"], [0.9, 1.02, 0.08, "deck"], [1.55, 1.1, 0.1, "roof_r"], [2.1, 1.12, 0.2], [2.4, 1.09, 0.06, "roof_f"], [2.85, 0.88, 0.04, "cowl"], [4.15, 0.66, 0.08, "hood"], [4.36, 0.5, 0.04, "nose"]], "H": 1.12, "hood_h": 0.58, "cowl_rise": 0.22, "cowl_d": 1.5, "rake": 66.0, "deck": 0.9, "tail_h": 1.0, "bl_rake": 80.0,
		"soft": 0.4, "head": "popup", "tail_lamp": "round", "wing_kind": "deck", "rim_style": "fivespoke", "art": { "louvers": true } },
	"ferraree_three_oh_ate_1984": { "soft": 0.5, "head": "popup", "tail_lamp": "round", "rim_style": "fivespoke" },
	"ferraree_two_fifty_gee_tee_oh_no_1962": { "H": 1.2, "hood_h": 0.62, "cowl_rise": 0.2, "cowl_d": 2.0, "rake": 56.0, "tail_h": 0.88, "bl_rake": 70.0,
		"soft": 1.2, "side_vent": "vent", "head": "round", "tail_lamp": "round", "rim_style": "wire", "art": { "spoiler": true } },
	"lamberghini_coontash_1985": { "top": [[0.0, 0.5, 0.02], [0.02, 0.98, 0.02, "tail"], [0.95, 1.0, 0.02, "deck"], [1.6, 1.06, 0.04, "roof_r"], [2.25, 1.07, 0.04, "roof_f"], [2.85, 0.88, 0.02, "cowl"], [3.95, 0.66, 0.02, "hood"], [4.14, 0.5, 0.02, "nose"]], "H": 1.07, "hood_h": 0.6, "cowl_rise": 0.18, "cowl_d": 1.3, "rake": 72.0, "deck": 0.95, "tail_h": 0.98, "bl_rake": 84.0,
		"c_top": 0.04, "c_bot": -0.04, "soft": 0.04, "nose_drop": 0.2, "nose_round": 0.32, "nose_lean": 0.05, "arch": "square", "head": "popup", "tail_lamp": "block",
		"rim_style": "steel", "rim_color": "c8ccd4" },
	"lamberghini_diabloh_1995": { "soft": 0.7, "rake": 70.0 },
	"lamberghini_meeura_1968": { "top": [[0.0, 0.5, 0.06], [0.03, 0.88, 0.06, "tail"], [0.6, 0.92, 0.3], [1.3, 0.97, 0.3, "deck"], [1.85, 1.03, 0.3, "roof_r"], [2.25, 1.06, 0.3], [2.55, 1.03, 0.15, "roof_f"], [3.0, 0.8, 0.12, "cowl"], [3.45, 0.76, 0.3], [4.15, 0.62, 0.2, "hood"], [4.36, 0.42, 0.08, "nose"]], "H": 1.06, "hood_h": 0.6, "cowl_rise": 0.18, "cowl_d": 1.55, "rake": 64.0, "deck": 0.95, "tail_h": 0.92, "bl_rake": 82.0,
		"soft": 1.4, "head": "round", "tail_lamp": "block", "rim_style": "steel", "art": { "louvers": true } },
	"jagwire_ee_typo_1965": { "top": [[0.0, 0.48, 0.08], [0.05, 0.76, 0.12], [0.4, 0.86, 0.2, "tail"], [1.2, 1.17, 0.3, "roof_r"], [1.6, 1.22, 0.3], [1.85, 1.19, 0.12, "roof_f"], [2.2, 0.98, 0.06, "cowl"], [3.3, 0.9, 0.4], [4.2, 0.72, 0.3, "hood"], [4.45, 0.5, 0.1, "nose"]], "H": 1.22, "hood_h": 0.64, "cowl_rise": 0.2, "cowl_d": 2.3, "rake": 58.0, "tail_h": 0.8, "bl_rake": 72.0, "soft": 1.6,
		"nose_round": 0.25, "nose_drop": 0.2, "head": "round", "tail_lamp": "round", "bumper": "chrome", "rim_style": "wire" },
	"aston_martian_double_bee_five_1964": { "top": [[0.0, 0.5, 0.06], [0.04, 0.86, 0.08], [0.45, 0.94, 0.2, "tail"], [1.2, 1.26, 0.25, "roof_r"], [1.8, 1.34, 0.35], [2.1, 1.31, 0.1, "roof_f"], [2.55, 1.02, 0.06, "cowl"], [3.7, 0.92, 0.35], [4.4, 0.78, 0.2, "hood"], [4.57, 0.58, 0.08, "nose"]], "rear": "fast", "H": 1.34, "hood_h": 0.74, "cowl_rise": 0.14, "cowl_d": 2.05, "rake": 52.0, "tail_h": 0.88,
		"bl_rake": 64.0, "soft": 1.0, "side_vent": "vent", "head": "round", "tail_lamp": "bar", "rim_style": "wire" },
	"mercedez_gullwinger_1955": { "top": [[0.0, 0.5, 0.12], [0.06, 0.78, 0.2], [0.7, 0.98, 0.4, "tail"], [1.3, 1.22, 0.3, "roof_r"], [1.85, 1.3, 0.45], [2.2, 1.26, 0.2, "roof_f"], [2.62, 0.98, 0.12, "cowl"], [3.6, 0.89, 0.5], [4.3, 0.72, 0.25, "hood"], [4.52, 0.48, 0.1, "nose"]], "rear": "fast", "H": 1.3, "hood_h": 0.76, "cowl_rise": 0.14, "cowl_d": 2.0, "rake": 46.0, "tail_h": 0.82, "bl_rake": 64.0,
		"soft": 1.5, "side_vent": "vent", "head": "round", "rim_style": "hubcap", "trim": ["arch_chrome"] },
	"austen_healthy_frog_eyed_spryte_1959": { "head": "frog", "rim_style": "steel" },
	"bugattee_veyrun_2008": { "top": [[0.0, 0.5, 0.1], [0.05, 0.92, 0.12, "tail"], [0.55, 0.98, 0.3], [1.0, 1.03, 0.2, "deck"], [1.55, 1.18, 0.25, "roof_r"], [2.1, 1.21, 0.4], [2.45, 1.17, 0.2, "roof_f"], [3.05, 0.86, 0.15, "cowl"], [3.7, 0.74, 0.35], [4.3, 0.6, 0.15, "hood"], [4.46, 0.45, 0.08, "nose"]], "soft": 1.0, "art": { "twotone": true } },
	"maclarence_eff_won_1994": { "soft": 0.9, "art": { "roofscoop": true } },
	"acurra_en_ess_eks_1991": { "H": 1.17, "hood_h": 0.62, "cowl_rise": 0.2, "cowl_d": 1.6, "rake": 66.0, "deck": 0.9, "tail_h": 1.0, "bl_rake": 78.0,
		"soft": 0.7, "head": "popup", "tail_lamp": "wrap", "rim_style": "multispoke", "art": { "blackroof": true } },
	# --- the JDM heroes
	"toyoda_supreem_twin_turbo_1995": { "top": [[0.0, 0.55, 0.1], [0.05, 0.98, 0.1, "tail"], [0.5, 1.04, 0.25], [1.25, 1.24, 0.25, "roof_r"], [1.85, 1.27, 0.5], [2.22, 1.22, 0.2, "roof_f"], [2.7, 0.94, 0.12, "cowl"], [3.9, 0.8, 0.4], [4.42, 0.66, 0.12, "hood"], [4.52, 0.5, 0.08, "nose"]], "rear": "fast", "H": 1.27, "hood_h": 0.64, "cowl_rise": 0.22, "cowl_d": 1.95, "rake": 64.0, "tail_h": 1.0,
		"bl_rake": 70.0, "c_bot": -0.25, "soft": 1.2, "head": "jewel", "tail_lamp": "round", "rim_style": "fivespoke", "trim": [] },
	"nissun_skylion_gee_tee_arr_1991": { "top": [[0.0, 0.52, 0.03], [0.02, 1.0, 0.03, "tail"], [0.6, 1.03, 0.04, "deck"], [1.2, 1.31, 0.06, "roof_r"], [1.9, 1.34, 0.1], [2.05, 1.32, 0.05, "roof_f"], [2.75, 0.93, 0.04, "cowl"], [4.4, 0.77, 0.06, "hood"], [4.55, 0.57, 0.03, "nose"]], "H": 1.34, "hood_h": 0.74, "cowl_rise": 0.17, "cowl_d": 1.82, "rake": 60.0, "deck": 0.55, "tail_h": 1.0,
		"bl_rake": 60.0, "soft": 0.45, "flare": "bulge", "head": "flush", "tail_lamp": "round", "rim_style": "tenspoke", "trim": [] },
	"nissun_two_forty_ess_x_1993": { "H": 1.29, "hood_h": 0.64, "cowl_rise": 0.21, "cowl_d": 1.74, "rake": 60.0, "tail_h": 0.93, "deck": 0.62,
		"bl_rake": 60.0, "soft": 0.9, "head": "popup", "tail_lamp": "wrap" },
	"mazduh_roto_seven_1993": { "top": [[0.0, 0.58, 0.1], [0.04, 0.93, 0.08, "tail"], [0.3, 0.98, 0.2], [1.2, 1.2, 0.3, "roof_r"], [1.75, 1.23, 0.4], [2.05, 1.18, 0.2, "roof_f"], [2.55, 0.9, 0.1, "cowl"], [3.1, 0.83, 0.3], [3.75, 0.78, 0.3], [4.2, 0.6, 0.12, "hood"], [4.29, 0.48, 0.06, "nose"]], "rear": "fast", "H": 1.23, "hood_h": 0.58, "cowl_rise": 0.22, "cowl_d": 1.7, "rake": 64.0, "tail_h": 0.95, "bl_rake": 72.0,
		"kick": 0.06, "soft": 1.5, "head": "popup", "tail_lamp": "round", "rim_style": "fivespoke" },
	"mazduh_roto_seven_1985": { "rear": "fast", "H": 1.26, "hood_h": 0.6, "cowl_rise": 0.22, "cowl_d": 1.65, "rake": 62.0, "tail_h": 0.88, "bl_rake": 72.0,
		"soft": 0.4, "tail_lamp": "wrap", "rim_style": "turbofan" },
	"mazduh_myata_1990": { "H": 1.22, "soft": 1.3, "head": "popup", "tail_lamp": "wrap", "rim_style": "multispoke" },
	"hondo_civil_type_arr_2017": { "rim_style": "multispoke", "rim_color": "2a2a2e", "side_vent": "vent", "flare": "box" },
	"acurra_in_tegruh_1994": { "rear": "fast", "head": "quad", "tail_lamp": "wrap", "rim_style": "fivespoke" },
	"mitsubishy_lanser_evolushun_2008": { "nose_lean": -0.06, "flare": "box", "rim_style": "tenspoke", "side_vent": "vent" },
	"subaroo_imprezza_wrecks_2004": { "rim_style": "fivespoke", "rim_color": "c8a040" },
	"datsum_two_forty_zed_1972": { "top": [[0.0, 0.5, 0.05], [0.03, 0.86, 0.05], [0.35, 0.9, 0.1, "tail"], [1.3, 1.22, 0.2, "roof_r"], [1.7, 1.29, 0.25], [1.92, 1.26, 0.08, "roof_f"], [2.3, 0.96, 0.05, "cowl"], [3.4, 0.86, 0.3], [4.0, 0.74, 0.15, "hood"], [4.14, 0.56, 0.05, "nose"]], "rear": "fast", "H": 1.29, "hood_h": 0.66, "cowl_rise": 0.18, "cowl_d": 1.95, "rake": 56.0, "tail_h": 0.86,
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
	"volkswagon_golph_gee_tee_eye_1985": { "top": [[0.0, 0.5, 0.04], [0.03, 0.9, 0.04, "tail"], [0.25, 1.36, 0.08, "roof_r"], [2.0, 1.4, 0.15], [2.15, 1.37, 0.06, "roof_f"], [2.8, 0.92, 0.05, "cowl"], [3.85, 0.74, 0.08, "hood"], [3.99, 0.56, 0.04, "nose"]], "H": 1.4, "hood_h": 0.72, "cowl_rise": 0.18, "cowl_d": 1.2, "rake": 54.0, "tail_h": 0.9, "bl_rake": 28.0,
		"soft": 0.2, "c_top": 0.24, "c_bot": 0.12, "doors": 2, "head": "round", "tail_lamp": "block", "bumper": "rubber", "rim_style": "tenspoke" },
	"volvoh_brick_1989": { "top": [[0.0, 0.5, 0.03], [0.02, 1.38, 0.04], [0.15, 1.42, 0.03, "roof_r"], [2.2, 1.42, 0.04], [2.32, 1.4, 0.03, "roof_f"], [2.95, 0.92, 0.03, "cowl"], [4.68, 0.76, 0.03, "hood"], [4.79, 0.58, 0.02, "nose"]], "soft": 0.06, "rake": 52.0 },
	"minni_cupper_1965": { "top": [[0.0, 0.42, 0.06], [0.03, 0.8, 0.08, "tail"], [0.22, 0.84, 0.04, "deck"], [0.36, 1.27, 0.08, "roof_r"], [1.85, 1.33, 0.12], [2.0, 1.3, 0.06, "roof_f"], [2.25, 0.9, 0.06, "cowl"], [2.85, 0.8, 0.12, "hood"], [3.05, 0.56, 0.06, "nose"]],
		"H": 1.33, "rear": "notch", "hood_h": 0.8, "cowl_rise": 0.1, "cowl_d": 0.8, "rake": 32.0, "deck": 0.22, "tail_h": 0.82, "clear": 0.17,
		"bl_rake": 18.0, "c_top": 0.08, "c_bot": 0.02, "soft": 0.6, "head": "round", "tail_lamp": "block", "bumper": "chrome", "rim_style": "steel",
		"wr": 0.08, "wf": 0.92, "tire_r": 0.066, "rim": 0.56 },
	"volkswagon_beetel_1967": { "top": [[0.0, 0.42, 0.1], [0.06, 0.6, 0.12, "tail"], [0.45, 0.85, 0.3], [1.15, 1.3, 0.4, "roof_r"], [1.85, 1.5, 0.6], [2.3, 1.42, 0.25, "roof_f"], [2.62, 1.0, 0.1, "cowl"], [3.35, 0.88, 0.3], [3.72, 0.85, 0.1], [3.95, 0.66, 0.15, "hood"], [4.07, 0.5, 0.08, "nose"]], "H": 1.5, "rear": "fast", "hood_h": 0.74, "cowl_rise": 0.26, "cowl_d": 1.45, "rake": 32.0, "tail_h": 0.62, "bl_rake": 52.0,
		"clear": 0.3, "crown": 0.12, "soft": 3.0, "c_top": 0.08, "c_bot": -0.04, "head": "round", "tail_lamp": "round", "bumper": "chrome",
		"brow_d": 0.36, "brow_h": 0.82, "fenders": "separate", "rim_style": "dish", "wall": "none" },
	"citrowen_deux_chevals_1975": { "top": [[0.0, 0.5, 0.06], [0.08, 0.7, 0.15, "tail"], [0.7, 1.35, 0.4, "roof_r"], [1.6, 1.6, 0.6], [2.25, 1.55, 0.25, "roof_f"], [2.6, 1.02, 0.1, "cowl"], [3.4, 0.86, 0.3], [3.7, 0.72, 0.12, "hood"], [3.83, 0.55, 0.05, "nose"]], "H": 1.6, "rear": "fast", "hood_h": 0.78, "cowl_rise": 0.2, "cowl_d": 1.2, "rake": 28.0, "tail_h": 0.66,
		"bl_rake": 40.0, "clear": 0.32, "crown": 0.1, "soft": 2.0, "doors": 4, "head": "round", "fenders": "separate", "rim_style": "steel" },
	"citrowen_goddess_1970": { "top": [[0.0, 0.48, 0.08], [0.1, 0.78, 0.2, "tail"], [0.95, 1.05, 0.3, "deck"], [1.35, 1.38, 0.2, "roof_r"], [2.3, 1.47, 0.4], [2.5, 1.44, 0.15, "roof_f"], [3.15, 0.98, 0.15, "cowl"], [4.2, 0.8, 0.4], [4.72, 0.62, 0.2, "hood"], [4.87, 0.45, 0.06, "nose"]], "rear": "notch", "H": 1.47, "hood_h": 0.66, "cowl_rise": 0.26, "cowl_d": 1.72, "rake": 56.0, "tail_h": 0.86, "bl_rake": 62.0,
		"soft": 1.5, "nose_round": 0.2, "skirt": true, "head": "round", "tail_lamp": "round", "rim_style": "hubcap" },
	# --- trucks, 4x4s and vans everybody knows
	"fjord_broncho_1970": { "H": 1.77, "hood_h": 1.02, "cowl_rise": 0.04, "cowl_d": 1.35, "rake": 16.0, "soft": 0.1, "ff": 0.5,
		"nose_drop": 0.4, "head": "round", "bumper": "chrome", "rim_style": "steel", "wall": "letters" },
	"jepp_see_jay_five_1972": { "H": 1.72, "hood_h": 0.98, "cowl_rise": 0.04, "cowl_d": 1.3, "rake": 8.0, "soft": 0.05, "ff": 0.5,
		"nose_drop": 0.42, "head": "round", "rim_style": "steel", "wall": "letters" },
	"jepp_wranglur_1995": { "H": 1.75, "hood_h": 1.0, "cowl_rise": 0.05, "cowl_d": 1.35, "rake": 22.0, "soft": 0.08, "head": "rect",
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
	"hummor_aitch_won_1996": { "top": [[0.0, 0.55, 0.04], [0.0, 1.42, 0.04, "tail"], [0.5, 1.86, 0.05, "roof_r"], [2.55, 1.9, 0.05], [2.8, 1.86, 0.04, "roof_f"], [3.05, 1.56, 0.04, "cowl"], [4.55, 1.38, 0.05, "hood"], [4.7, 1.12, 0.04, "nose"]],
		"H": 1.9, "clear": 0.46, "hood_h": 1.38, "cowl_rise": 0.18, "cowl_d": 1.65, "rake": 30.0, "rear_d": 0.5, "d_w": 0.1, "belt_up": 0.04, "kick": 0.0, "soft": 0.04,
		"arch": "trap", "flare": "trap", "head": "round", "rim_style": "beadlock", "tire": 1.18, "rim_frac": 0.5 },
	"volkswagon_hippie_buss_1972": { "top": [[0.0, 0.5, 0.15], [0.0, 1.6, 0.25], [0.2, 1.95, 0.25, "roof_r"], [4.05, 1.95, 0.3], [4.35, 1.8, 0.2, "roof_f"], [4.45, 1.05, 0.15, "cowl"], [4.47, 0.95, 0.1, "hood"], [4.5, 0.6, 0.15, "nose"]], "H": 1.95, "hood_h": 0.95, "cowl_rise": 0.06, "cowl_d": 0.12, "rake": 16.0, "rear_d": 0.12, "soft": 1.6, "crown": 0.06,
		"nose_drop": 0.55, "nose_round": 0.25, "head": "round", "bumper": "chrome", "rim_style": "hubcap" },
	"dodgy_sprintur_2008": { "H": 2.6 },
	"fjord_transitory_2016": { "H": 2.5 },
	"ramm_promastur_2017": { "H": 2.5 },
	"toyoda_previous_1993": { "hood_h": 0.86, "cowl_rise": 0.22, "cowl_d": 0.75, "rake": 64.0, "rear_d": 0.06, "soft": 1.6 },
	"gmz_sy_clone_1991": { "H": 1.52, "clear": 0.14, "hood_h": 0.86, "rim_style": "multispoke" },
	"fjord_crown_victorious_2005": { "arc": false, "bl_rake": 30.0, "deck": 1.12, "tail_h": 1.02, "c_top": 0.16, "kick": 0.0, "crown": 0.012, "soft": 0.35,
		"nose_round": 0.04, "nose_drop": 0.18, "cowl_d": 2.05, "rim_style": "steel", "rim_color": "2a2e36", "head": "flush", "tail_lamp": "block", "grille": "waterfall" },
	# --- the odd ones
	"peeled_pee_fifty_1963": { "H": 1.2, "rear": "fast", "hood_h": 0.55, "cowl_rise": 0.2, "cowl_d": 0.3, "rake": 30.0, "tail_h": 0.55,
		"bl_rake": 40.0, "crown": 0.05, "soft": 1.6, "c_top": 0.05, "c_bot": 0.0, "doors": 2, "tire": 0.7, "head": "round" },
	"beemer_werke_isette_1958": { "H": 1.34, "rear": "fast", "hood_h": 0.6, "cowl_rise": 0.3, "cowl_d": 0.35, "rake": 38.0, "tail_h": 0.62,
		"bl_rake": 52.0, "crown": 0.1, "soft": 2.5, "c_top": 0.06, "c_bot": -0.02, "head": "round", "bumper": "chrome" },
	"cadillak_fleetwould_hearse_1985": { "H": 1.64, "rear_d": 0.08, "art": { "hearse": true, "vinyl": true } },
	# --- the sedans on the road all day, each with its maker's cue: where the roof peaks, how
	# fast the C-pillar falls, how high and short the deck sits, a kink in the glass
	"toyoda_corolly_2017": { "deck": 0.78, "deck_rise": 0.03, "tail_h": 1.1, "bl_rake": 62.0, "peak": 0.62, "crown": 0.04, "nose_drop": 0.15, "kick": 0.08 },
	"toyoda_corolly_2003": { "H": 1.49, "deck": 0.85, "tail_h": 1.06, "bl_rake": 52.0, "rake": 56.0, "peak": 0.5, "crown": 0.025, "kick": 0.03, "c_w": 0.12 },
	"hondo_civil_2008": { "cowl_d": 1.25, "rake": 66.0, "peak": 0.42, "crown": 0.06, "deck": 0.62, "deck_rise": 0.03, "bl_rake": 64.0, "kick": 0.06 },
	"hyundie_elantruh_2013": { "peak": 0.55, "crown": 0.06, "kick": 0.11, "c_w": 0.24, "bl_rake": 70.0, "deck": 0.55, "deck_rise": 0.04 },
	"toyoda_camree_2015": { "deck": 0.95, "bl_rake": 58.0, "peak": 0.5, "crown": 0.04, "kick": 0.05, "c_w": 0.16 },
	"toyoda_camree_1997": { "deck": 0.98, "bl_rake": 50.0, "crown": 0.02, "kick": 0.02, "c_top": 0.14 },
	"chevrolay_maliboo_2016": { "H": 1.46, "deck": 0.58, "bl_rake": 71.0, "c_w": 0.26, "peak": 0.45, "crown": 0.05, "kick": 0.07 },
	"chevrolay_crews_2014": { "peak": 0.66, "crown": 0.05, "deck": 0.6, "deck_rise": 0.04, "tail_h": 1.1, "kick": 0.08 },
	"fjord_fussion_2013": { "cowl_d": 1.6, "bl_rake": 72.0, "c_w": 0.24, "deck": 0.55, "peak": 0.48, "nose_drop": 0.08, "nose_round": 0.04, "hood_h": 0.88 },
	"nissun_sentruh_2016": { "deck": 0.7, "peak": 0.56, "crown": 0.05, "bl_rake": 64.0 },
	"nissun_alteema_2007": { "deck": 0.75, "peak": 0.5, "crown": 0.065, "kick": 0.06, "bl_rake": 63.0 },
	"fjord_fokus_2008": { "H": 1.5, "rake": 57.0, "deck": 0.78, "bl_rake": 55.0, "crown": 0.03, "peak": 0.55 },
	"hondo_accordion_2004": { "kick": 0.1, "deck": 0.82, "deck_rise": 0.02, "peak": 0.5, "crown": 0.04, "sixlight": true },
	"kiah_fortay_2015": { "bl_rake": 68.0, "c_w": 0.22, "peak": 0.5, "deck": 0.6 },
	"chevrolay_impaler_2008": { "arc": false, "bl_rake": 44.0, "deck": 1.02, "c_top": 0.15, "tail_h": 1.08, "kick": 0.03 },
	"chevrolay_cava_lame_2002": { "deck": 0.85, "crown": 0.03, "peak": 0.52, "bl_rake": 56.0 },
	"merkury_grand_marquee_2003": { "arc": false, "bl_rake": 32.0, "deck": 1.12, "c_top": 0.16, "cowl_d": 1.95, "kick": 0.0, "crown": 0.012, "soft": 0.4,
		"nose_round": 0.05, "head": "flush", "tail_lamp": "slim", "tail_len": 0.16, "grille": "waterfall" },
	"mercedez_ess_klassy_2005": { "peak": 0.48, "crown": 0.075, "deck": 0.98, "deck_rise": 0.03, "cowl_d": 1.85, "kick": 0.04, "c_w": 0.2 },
	"awdi_ayy_four_2004": { "crown": 0.03, "peak": 0.56, "deck": 0.86, "bl_rake": 58.0, "nose_drop": 0.09, "c_w": 0.14 },
	"beemer_werke_emm_funf_2006": { "cowl_d": 1.85, "kink": 0.13, "deck": 0.95, "deck_rise": 0.05, "peak": 0.5, "crown": 0.04 },
	"mercedez_one_ninety_eee_1989": { "deck": 0.86, "tail_h": 1.0, "bl_rake": 48.0, "c_top": 0.12, "crown": 0.012, "soft": 0.25 },
	"kiah_stingur_2018": { "rear": "fast", "tail_h": 1.05, "bl_rake": 74.0, "cowl_d": 1.75, "peak": 0.5, "crown": 0.05, "c_bot": -0.3 },
	"hyundie_tiburron_2003": { "rear": "fast", "bl_rake": 72.0, "peak": 0.45, "crown": 0.05, "c_bot": -0.28 },
	# --- drawn by hand from the top line down, like a signature face
	"daihatsoo_kopen_2003": { "top": [[0.0, 0.48, 0.08], [0.04, 0.82, 0.12, "tail"], [0.45, 0.9, 0.25], [0.95, 0.92, 0.1, "deck"], [1.1, 0.85, 0.03], [1.72, 0.85, 0.03], [1.88, 0.88, 0.04, "cowl"], [2.75, 0.76, 0.3], [3.25, 0.64, 0.12, "hood"], [3.4, 0.46, 0.08, "nose"]],
		"family": "roadster", "rear": "open", "H": 1.18, "rake": 62.0, "soft": 1.4, "doors": 2, "head": "round", "tail_lamp": "round", "rim_style": "fivespoke", "antenna": "none" },
	"subaroo_three_sixty_1968": { "H": 1.34, "rear": "fast", "soft": 2.5, "head": "round", "tail_lamp": "round", "rim_style": "hubcap", "doors": 2, "top": [[0.0, 0.45, 0.15], [0.08, 0.72, 0.2, "tail"], [0.45, 1.05, 0.3, "roof_r"], [1.1, 1.34, 0.5], [1.55, 1.3, 0.3, "roof_f"], [2.15, 0.88, 0.25, "cowl"], [2.7, 0.7, 0.3], [2.95, 0.55, 0.12, "hood"], [3.0, 0.4, 0.08, "nose"]] },
	"volkswagon_karma_ghiaa_1969": { "H": 1.33, "rear": "notch", "soft": 1.8, "head": "round", "tail_lamp": "round", "bumper": "chrome", "rim_style": "dish", "doors": 2, "top": [[0.0, 0.5, 0.12], [0.06, 0.74, 0.15, "tail"], [0.65, 0.93, 0.3, "deck"], [1.2, 1.25, 0.3, "roof_r"], [1.85, 1.33, 0.5], [2.25, 1.28, 0.2, "roof_f"], [2.8, 0.9, 0.12, "cowl"], [3.45, 0.8, 0.35], [3.95, 0.66, 0.2, "hood"], [4.14, 0.45, 0.1, "nose"]] },
	"porch_speedstur_1957": { "H": 1.22, "soft": 2.0, "head": "round", "tail_lamp": "round", "bumper": "chrome", "rim_style": "steel", "rim_color": "c8ccd4", "top": [[0.0, 0.48, 0.12], [0.07, 0.68, 0.2, "tail"], [0.7, 0.9, 0.4], [1.25, 0.94, 0.2], [1.4, 0.9, 0.05], [2.15, 0.88, 0.05, "cowl"], [3.2, 0.8, 0.4], [3.75, 0.68, 0.25, "hood"], [3.95, 0.45, 0.1, "nose"]] },
	"tesler_model_ess_2015": { "H": 1.45, "rear": "fast", "soft": 1.0, "head": "swept", "tail_lamp": "wrap", "rim_style": "multispoke", "rim_frac": 0.74, "handle": "flush", "trim": [], "top": [[0.0, 0.62, 0.08], [0.06, 1.03, 0.08], [0.4, 1.06, 0.15, "tail"], [1.7, 1.38, 0.5, "roof_r"], [2.4, 1.45, 0.6], [2.75, 1.41, 0.3, "roof_f"], [3.4, 1.0, 0.15, "cowl"], [4.35, 0.86, 0.4], [4.85, 0.74, 0.15, "hood"], [4.97, 0.56, 0.08, "nose"]] },
	"jagwire_ess_typo_2001": { "H": 1.44, "rear": "notch", "soft": 1.3, "head": "round", "tail_lamp": "wrap", "rim_style": "multispoke", "trim": ["rocker_chrome"], "top": [[0.0, 0.55, 0.12], [0.07, 0.98, 0.15, "tail"], [0.85, 1.03, 0.3, "deck"], [1.55, 1.36, 0.4, "roof_r"], [2.3, 1.44, 0.7], [2.8, 1.38, 0.3, "roof_f"], [3.35, 0.99, 0.15, "cowl"], [4.3, 0.86, 0.45], [4.75, 0.74, 0.2, "hood"], [4.88, 0.55, 0.1, "nose"]] },
	"toyoda_eff_jay_crusher_2008": { "H": 1.83, "rear": "box", "soft": 0.3, "head": "round", "tail_lamp": "tall", "rim_style": "fivespoke", "art": { "twotone": true, "spare": true }, "top": [[0.0, 0.45, 0.05], [0.02, 1.8, 0.08], [0.25, 1.83, 0.1, "roof_r"], [1.95, 1.82, 0.1], [2.35, 1.8, 0.06, "roof_f"], [2.55, 1.24, 0.06, "cowl"], [4.55, 1.16, 0.1, "hood"], [4.67, 0.95, 0.04, "nose"]] },
	"jepp_wranglur_unlimitless_2014": { "H": 1.8, "soft": 0.3, "head": "round", "tail_lamp": "tall", "rim_style": "fivespoke", "top": [[0.0, 0.55, 0.03], [0.0, 1.76, 0.04], [0.1, 1.8, 0.03, "roof_r"], [2.25, 1.8, 0.04], [2.4, 1.78, 0.03, "roof_f"], [2.95, 1.22, 0.03, "cowl"], [4.55, 1.12, 0.04, "hood"], [4.7, 0.92, 0.03, "nose"]] },
	"chevrolay_corvet_zee_oh_sicks_2015": { "H": 1.23, "rear": "fast", "soft": 0.5, "head": "swept", "tail_lamp": "block", "rim_style": "multispoke", "rim_frac": 0.76, "side_vent": "vent", "art": { "spoiler": true }, "top": [[0.0, 0.55, 0.04], [0.02, 1.0, 0.04], [0.35, 1.02, 0.08, "tail"], [1.35, 1.2, 0.15, "roof_r"], [1.75, 1.23, 0.3], [2.05, 1.2, 0.1, "roof_f"], [2.6, 0.92, 0.06, "cowl"], [3.6, 0.81, 0.3], [4.4, 0.62, 0.1, "hood"], [4.5, 0.48, 0.04, "nose"]] },
	"aston_martian_lagonduh_1980": { "top": [[0.0, 0.5, 0.02], [0.02, 0.93, 0.02, "tail"], [1.05, 0.96, 0.02, "deck"], [1.6, 1.26, 0.03, "roof_r"], [2.75, 1.29, 0.03, "roof_f"], [3.3, 0.97, 0.02, "cowl"], [5.12, 0.66, 0.02, "hood"], [5.28, 0.5, 0.02, "nose"]],
		"H": 1.29, "belt_up": 0.07, "kick": 0.0, "soft": 0.04, "nose": "wedge", "head": "popup", "tail_lamp": "block", "bumper": "rubber", "trim": ["moulding"], "antenna": "none" },
	# --- the round-two fixes: each car's one defining part
	"plymooth_prowlur_2001": { "top": [[0.0, 0.45, 0.1], [0.08, 0.8, 0.15, "tail"], [0.6, 0.92, 0.3], [1.1, 0.9, 0.1, "deck"], [1.28, 0.84, 0.03], [1.95, 0.84, 0.03], [2.1, 0.86, 0.04, "cowl"], [2.7, 0.78, 0.25], [3.1, 0.56, 0.2], [3.9, 0.48, 0.15, "hood"], [4.2, 0.36, 0.06, "nose"]],
		"family": "roadster", "rear": "open", "H": 1.29, "rake": 60.0, "soft": 1.2, "clear": 0.14, "nose_bot": 0.24, "head": "round", "tail_lamp": "round",
		"rim_style": "multispoke", "rim_frac": 0.66, "cycle": true, "antenna": "none" },
	"chryslur_pt_crusher_2005": { "top": [[0.0, 0.48, 0.05], [0.03, 0.95, 0.1, "tail"], [0.14, 1.42, 0.12, "roof_r"], [0.6, 1.57, 0.25], [1.9, 1.6, 0.35], [2.32, 1.55, 0.15, "roof_f"], [2.85, 1.04, 0.08, "cowl"], [3.55, 0.9, 0.25], [4.1, 0.74, 0.15, "hood"], [4.29, 0.55, 0.08, "nose"]],
		"H": 1.6, "rear": "hatch", "belt_up": 0.02, "kick": 0.02, "soft": 1.0, "head": "round", "tail_lamp": "tall", "fenders": "separate", "rim_style": "fivespoke", "trim": [] },
	"fiatt_cinquesomething_1968": { "top": [[0.0, 0.42, 0.12], [0.05, 0.68, 0.15, "tail"], [0.3, 0.9, 0.25], [0.7, 1.22, 0.25, "roof_r"], [1.25, 1.32, 0.4], [1.75, 1.27, 0.2, "roof_f"], [2.15, 0.9, 0.15, "cowl"], [2.6, 0.76, 0.3], [2.86, 0.6, 0.15, "hood"], [2.97, 0.42, 0.1, "nose"]],
		"H": 1.32, "rear": "fast", "soft": 1.6, "doors": 2, "head": "round", "tail_lamp": "round", "bumper": "chrome", "rim_style": "hubcap", "art": { "sunroof": true } },
	"hummor_aitch_too_2005": { "top": [[0.0, 0.6, 0.04], [0.0, 1.3, 0.05, "tail"], [0.15, 1.4, 0.05], [0.78, 1.92, 0.08, "roof_r"], [2.75, 1.95, 0.08], [2.95, 1.92, 0.05, "roof_f"], [3.3, 1.34, 0.05, "cowl"], [4.6, 1.26, 0.06, "hood"], [4.82, 1.0, 0.04, "nose"]],
		"H": 1.95, "clear": 0.36, "rear_d": 0.78, "d_w": 0.08, "belt_up": 0.02, "kick": 0.0, "soft": 0.2, "arch": "square", "flare": "box", "head": "truck",
		"tail_lamp": "tall", "rim_style": "fivespoke", "tire": 1.1, "trim": [] },
	"cadillak_escalator_2008": { "head": "truck", "tail_lamp": "tower", "rim_style": "multispoke", "rim_frac": 0.72 },
	"linkoln_navigatrix_2005": { "head": "truck", "tail_lamp": "tall", "rim_style": "multispoke" },
	"infinitee_queue_ex_fifty_six_2008": { "head": "truck", "tail_lamp": "tall", "rim_style": "multispoke" },
	"awdi_queue_seven_2010": { "cls": "crossover", "rim_style": "multispoke" },
	"chevrolay_avalaunch_2005": { "sail": 0.8, "trim": ["cladding", "arch_cladding"] },
	"hondo_ridgelyne_2017": { "sail": 0.62, "unibody": true },
	"fjord_torus_1989": { "rear": "notch", "soft": 1.3, "crown": 0.05, "nose_round": 0.18, "head": "flush", "tail_lamp": "wrap", "bumper": "body" },
}
