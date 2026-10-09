## The car catalogue: three hundred and some parody cars, 1955 to 2019, from kei trucks to
## hypercars, plus the four hand-made cars in data/cars.
##
## Every catalogue car is one line of TABLE (at the bottom of this file): make, model, year,
## class, body, size, mass, drivetrain, engine, gearbox, price, rarity, art cues and a blurb.
## spec(id) turns those numbers into a full driving-sim spec, in exactly the shape of the
## hand-made JSON specs: a torque curve from the power, torque and redline, gear ratios from
## the top speed the car can push through the air, tires from its weight and era, a centre of
## gravity from where the engine sits, and so on. The hand-made cars stay as JSON; spec() hands
## those straight to SaveGame.load_spec.
##
## random_traffic() picks a car for the traffic in a zone: weighted by rarity, with more
## pickups and rust out in the country and more compacts and luxury downtown.
class_name CarCatalog
extends RefCounted

const GAME_YEAR := 2022           # the Silvio (1991) is "31 years old"
const G := 9.81

const CLASSES := ["economy", "compact", "sedan", "wagon", "coupe", "sports", "muscle", "pony", "luxury",
	"exotic", "hatch", "hot_hatch", "kei", "minivan", "van", "suv", "crossover", "pickup", "hd_pickup",
	"work_truck", "offroad", "classic", "rally", "jdm", "euro", "oddball"]

## The body styles CarArt draws (top-down), and the nearest PixCars side-view body for each.
const SIDE_BODY := {
	"coupe": "coupe", "hatch": "hatch", "sedan": "sedan", "tow": "tow", "wagon": "suv", "pickup": "pickup",
	"suv": "suv", "van": "van", "minivan": "van", "muscle": "coupe", "sports": "coupe", "wedge": "coupe",
	"roadster": "coupe", "kei": "hatch", "offroad": "suv", "boxtruck": "van", "trike": "hatch", "bubble": "hatch",
}

## Art cues a table line can switch on (CarArt draws them); everything else in the flags column
## is a sim hint (mid, rear, digidash) or a palette (p=#hex/#hex).
const ART_CUES := ["chrome", "nochrome", "round", "quad", "popups", "fins", "twotone", "vinyl", "wood", "rack", "norack",
	"stripes", "scoop", "wing", "spoiler", "spare", "nospare", "bullbar", "beacon", "snorkel", "sunroof", "ttops", "topper",
	"ladder", "toolbox", "cargo", "open", "crew", "ext", "cabover", "ute", "dually", "hardtop", "spotlight", "plow",
	"portholes", "strakes", "split"]

## A line about the car you get for free with some of the cues.
const QUIRK_TEXT := {
	"popups": "Pop-up headlights. One of them always winks.",
	"ttops": "T-tops: two glass panels, four drips on your left knee.",
	"wood": "Wood-grain sides. The wood is vinyl. The rot is real.",
	"vinyl": "Vinyl roof, peeling at the corners like an old sticker.",
	"fins": "Tail fins, in case it needs to take off.",
	"digidash": "Digital dash: green numbers, orange bar graphs, no idea what any of it means.",
	"open": "No roof. Bring a towel.",
	"hardtop": "Removable hardtop. Removing it takes two people and a chiropractor.",
	"wing": "A rear wing. It holds the car down at speeds you will never see.",
	"stripes": "Racing stripes: plus ten horsepower, by eye.",
	"scoop": "Hood scoop. Feeds the engine air and the driver confidence.",
	"rack": "Roof rack, for the canoe you keep saying you'll buy.",
	"spare": "Spare tire on the back door.",
	"snorkel": "A snorkel, for rivers you will never ford.",
	"beacon": "Amber beacons on the roof, for looking official.",
	"plow": "A plow blade, for pushing snow into somebody else's driveway.",
	"dually": "Dual rear wheels, for wide loads and wide turns.",
	"chrome": "Chrome bumpers you could shave in.",
	"split": "Split rear window: a beautiful blind spot.",
	"sunroof": "Glass roof panels, so the kids in the back can count the clouds.",
	"topper": "A sign on the roof.",
	"spotlight": "A pillar-mounted spotlight from its old job.",
	"portholes": "Portholes in the fenders. Purely decorative. Mostly rust holes now.",
}

const HANDMADE := {
	"silvio": { "class": "jdm", "price": 9500.0, "rarity": 5.0 },
	"supreem": { "class": "jdm", "price": 7800.0, "rarity": 3.0 },
	"charjer": { "class": "muscle", "price": 21000.0, "rarity": 8.0 },
	"tow": { "class": "work_truck", "price": 18000.0, "rarity": 1.5 },
}

## Paint by era (year it starts), and by class where the class has its own taste.
const ERA_PAINTS := [
	[1955, ["#7fb8b0", "#e89aa8", "#f0e6c8", "#5a8ac8", "#c83c3c", "#2a2a2e", "#e8d07a", "#9ab87a", "#e8e4dc", "#3a5a8a"]],
	[1963, ["#1a3a6a", "#c8342c", "#e8e4dc", "#d8a03a", "#3a6a3a", "#2a8a9a", "#f0d040", "#4a4a50", "#8a1a1a", "#7a9ab8"]],
	[1973, ["#8a5a2a", "#c8a060", "#5a6a2a", "#a8442a", "#d8ccb0", "#4a2a1a", "#6a7a8a", "#e8e4dc", "#7a1a1a", "#2a4a3a"]],
	[1980, ["#8a1a2a", "#2c4a8a", "#b8b0a0", "#c8c8c8", "#1e1e24", "#e8e8e8", "#7a2a2a", "#3a4a5a", "#d8c8a0", "#c8342c"]],
	[1990, ["#2a6a5a", "#1a4a3a", "#6a1a3a", "#2a3a6a", "#e8e8e8", "#c8342c", "#8a8e94", "#4a8a8a", "#2a2a2e", "#a89a7a"]],
	[2000, ["#a8acb0", "#8a8e94", "#2a2a2e", "#e8e8e8", "#1a3a6a", "#7a1a1a", "#c8342c", "#4a4a50", "#c8b890", "#3a5a3a"]],
	[2010, ["#e8e8ec", "#1e1e24", "#5a5e64", "#a8acb0", "#2a4a8a", "#b8202a", "#d8d8d0", "#3a3e44", "#e86a1a", "#6a7a5a"]],
]
const CLASS_PAINTS := {
	"exotic": ["#d81e1e", "#f0c800", "#ff7a1a", "#1e1e24", "#e8e8e8", "#2a6a3a", "#2a4a8a"],
	"work_truck": ["#e8e8e8", "#f0f0ec", "#e8e8e8", "#d8a03a", "#c8342c", "#2c4a8a"],
	"muscle": ["#ff7a1a", "#f0d040", "#6a2a6a", "#3a8a3a", "#c8342c", "#1e1e24", "#e8e4dc", "#2c4a8a"],
	"pony": ["#c8342c", "#f0d040", "#2c4a8a", "#1e1e24", "#e8e4dc", "#3a8a3a", "#ff7a1a"],
	"luxury": ["#1e1e24", "#e8e8ec", "#5a5e64", "#6a1a2a", "#a8acb0", "#2a3a5a", "#d8ccb0"],
	"sports": ["#c8342c", "#f0d040", "#e8e8e8", "#1e1e24", "#2c4a8a", "#a8acb0"],
	"rally": ["#2a4a8a", "#e8e8e8", "#c8342c", "#1e1e24"],
}

## Zone styles (MapData zones) and how much more or less of each class they get.
const ZONE_MULT := {
	"rural": { "pickup": 3.0, "hd_pickup": 2.5, "work_truck": 1.2, "offroad": 2.0, "suv": 1.4, "luxury": 0.4, "exotic": 0.15, "sports": 0.6, "hot_hatch": 0.6, "kei": 0.6, "classic": 1.2 },
	"village": { "pickup": 2.0, "hd_pickup": 1.6, "offroad": 1.5, "luxury": 0.6, "exotic": 0.3, "classic": 1.4, "wagon": 1.3 },
	"downtown": { "compact": 1.6, "economy": 1.4, "hatch": 1.5, "hot_hatch": 1.3, "luxury": 2.0, "exotic": 2.5, "sports": 1.4, "kei": 1.5, "van": 1.3, "work_truck": 1.2, "pickup": 0.5, "hd_pickup": 0.3, "offroad": 0.6 },
	"commercial": { "van": 1.6, "work_truck": 1.6, "crossover": 1.5, "suv": 1.3, "minivan": 1.4 },
	"industrial": { "work_truck": 3.0, "van": 2.2, "pickup": 1.8, "hd_pickup": 2.2, "luxury": 0.3, "exotic": 0.1, "sports": 0.5, "kei": 1.5 },
	"residential": { "minivan": 1.8, "crossover": 1.6, "sedan": 1.3, "wagon": 1.4, "suv": 1.2, "compact": 1.2, "work_truck": 0.5 },
	"oldtown": { "classic": 2.0, "sedan": 1.2, "wagon": 1.4, "euro": 1.4, "coupe": 1.2 },
}

static var _entries := {}          # id -> entry
static var _order: Array = []      # ids in table order (hand-made cars first)
static var _specs := {}            # id -> built spec (cached)
static var _zone_pick := {}        # zone style -> [ids, cumulative weights]

# ------------------------------------------------------------------ the public face

## Every car id: the hand-made ones first, then the table in order.
static func ids() -> Array:
	_load()
	return _order.duplicate()

static func has(id: String) -> bool:
	_load()
	return _entries.has(id)

## The catalogue line for a car, as a Dictionary (see _parse for the keys). {} if unknown.
static func entry(id: String) -> Dictionary:
	_load()
	return (_entries.get(id, {}) as Dictionary).duplicate(true)

## The ids of every car in a class ("pickup", "kei", ...).
static func by_class(cls: String) -> Array:
	_load()
	var out: Array = []
	for id in _order:
		if String(_entries[id]["class"]) == cls: out.append(id)
	return out

## The full driving-sim spec, in the same shape as data/cars/*.json. The hand-made cars come
## from their JSON. {} if the id is unknown.
static func spec(id: String) -> Dictionary:
	if FileAccess.file_exists(_json_path(id)): return SaveGame.load_spec(id)
	_load()
	if not _entries.has(id): return {}
	if not _specs.has(id): _specs[id] = _build_spec(_entries[id])
	return (_specs[id] as Dictionary).duplicate(true)

## A car for the traffic: weighted by rarity and by what's normal in this kind of zone
## (MapData zone styles: downtown, oldtown, residential, commercial, industrial, rural, village).
## Returns what TrafficCar and CarArt need: id, name, make, model, year, class, body, side_body,
## length, width, wheelbase, track, mass, paint (hex) and art cues (with rust on old cars out
## in the country).
static func random_traffic(rng: RandomNumberGenerator, zone_style: String) -> Dictionary:
	_load()
	if not _zone_pick.has(zone_style): _zone_pick[zone_style] = _zone_table(zone_style)
	var pick: Array = _zone_pick[zone_style]
	var ids_z: Array = pick[0]
	var cum: Array = pick[1]
	var total: float = cum[cum.size() - 1]
	var i: int = clampi(cum.bsearch(rng.randf() * total, false), 0, ids_z.size() - 1)
	var e: Dictionary = _entries[ids_z[i]]
	var paints: Array = e.paints
	var art: Dictionary = (e.art as Dictionary).duplicate()
	var age := GAME_YEAR - int(e.year)
	if zone_style in ["rural", "village", "industrial"] and age >= 18 and rng.randf() < 0.65:
		art["rust"] = rng.randf_range(0.15, clampf(float(age - 12) / 30.0, 0.2, 0.9))
	elif age >= 25 and rng.randf() < 0.3:
		art["rust"] = rng.randf_range(0.05, 0.3)
	return {
		"id": e.id, "name": e.name, "make": e.make, "model": e.model, "year": e.year, "class": e["class"],
		"body": e.body, "side_body": e.side_body, "length": e.length, "width": e.width,
		"wheelbase": e.wheelbase, "track": e.track, "mass": e.mass,
		"paint": paints[rng.randi() % paints.size()], "art": art,
	}

# ------------------------------------------------------------------ loading the table

static func _json_path(id: String) -> String:
	return "res://data/cars/%s.json" % id

static func _load() -> void:
	if not _order.is_empty(): return
	for id in HANDMADE:
		var e := _handmade_entry(id)
		if e.is_empty(): continue
		_entries[id] = e
		_order.append(id)
	for line in TABLE.split("\n"):
		var l := line.strip_edges()
		if l.is_empty() or l.begins_with("#"): continue
		var e := _parse(l)
		if e.is_empty(): continue
		if _entries.has(e.id):
			push_error("CarCatalog: duplicate id %s" % e.id)
			continue
		_entries[e.id] = e
		_order.append(e.id)

static func slug(s: String) -> String:
	var out := ""
	for ch in s.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"): out += ch
		elif not out.ends_with("_") and not out.is_empty(): out += "_"
	return out.trim_suffix("_")

## make|model|year|class|body|length|width|wheelbase|kg|drive|cc|layout|aspiration|hp|Nm|redline|gearbox|price|rarity|flags|blurb
static func _parse(line: String) -> Dictionary:
	var f := line.split("|")
	if f.size() != 21:
		push_error("CarCatalog: %d fields in: %s" % [f.size(), line])
		return {}
	for i in f.size(): f[i] = f[i].strip_edges()
	var make := f[0]
	var model := f[1]
	var year := int(f[2])
	var cls := f[3]
	var body := f[4]
	var width := float(f[6])
	var drive := f[9]
	var cc := int(f[10])
	var layout := f[11]
	var asp := f[12]
	var trans := f[16]
	var tokens: Array = []
	var palette: Array = []
	for t in f[19].split(",", false):
		var tok := t.strip_edges()
		if tok.begins_with("p="):
			for hx in tok.substr(2).split("/", false): palette.append("#" + hx.trim_prefix("#"))
		elif not tok.is_empty():
			tokens.append(tok)
	var id := "%s_%s_%d" % [slug(make), slug(model), year]
	var pos := "front"
	if tokens.has("mid"): pos = "mid"
	elif tokens.has("rear"): pos = "rear"
	var truckish := body in ["pickup", "boxtruck", "tow"] or cls in ["hd_pickup", "work_truck"]
	var e := {
		"id": id, "make": make, "model": model, "year": year, "class": cls, "body": body,
		"side_body": SIDE_BODY.get(body, "sedan"), "name": ("%s %s" % [make, model]).to_upper(),
		"length": float(f[5]), "width": width, "wheelbase": float(f[7]),
		"track": snappedf(width * (0.78 if tokens.has("dually") else (0.84 if truckish else 0.855)), 0.01),
		"mass": float(f[8]), "drivetrain": drive,
		"engine": {
			"name": _engine_name(cc, layout, asp), "cc": cc, "displacement": snappedf(cc / 1000.0, 0.1),
			"layout": layout, "aspiration": asp, "hp": float(f[13]), "torque": float(f[14]),
			"redline": float(f[15]), "position": pos,
		},
		"gearbox": _gearbox_info(trans),
		"price": float(f[17]), "rarity": float(f[18]),
		"tokens": tokens, "blurb": f[20],
	}
	e["paints"] = palette if not palette.is_empty() else _palette(id, year, cls)
	e["art"] = _art(e, tokens)
	e["quirks"] = _quirks(e, tokens)
	return e

static func _handmade_entry(id: String) -> Dictionary:
	var s := SaveGame.load_spec(id)
	if s.is_empty(): return {}
	var extra: Dictionary = HANDMADE[id]
	var eng: Dictionary = s.engine
	var peak_w := 0.0
	var peak_t := 0.0
	for p in eng.torque_curve:
		if float(p[0]) > float(eng.limiter_rpm): continue
		peak_w = maxf(peak_w, float(p[0]) * float(p[1]) * TAU / 60.0)
		peak_t = maxf(peak_t, float(p[1]))
	var nm := String(eng.name)
	var disp := float(nm.get_slice(" ", 0))
	return {
		"id": id, "make": s.make, "model": s.model, "year": int(s.year), "class": extra["class"],
		"body": s.body, "side_body": SIDE_BODY.get(String(s.body), "sedan"),
		"name": ("%s %s" % [s.make, s.model]).to_upper(),
		"length": float(s.length), "width": float(s.width), "wheelbase": float(s.wheelbase), "track": float(s.track),
		"mass": float(s.mass), "drivetrain": s.get("drivetrain", "RWD"),
		"engine": {
			"name": nm, "cc": int(disp * 1000.0), "displacement": disp, "layout": "", "aspiration": "T" if eng.has("turbo") else "NA",
			"hp": roundf(peak_w / 745.7), "torque": peak_t, "redline": float(eng.redline_rpm), "position": "front",
		},
		"gearbox": { "count": (s.gearbox.gears as Array).size(), "type": "manual", "code": "M%d" % (s.gearbox.gears as Array).size(),
			"label": "%d-speed manual" % (s.gearbox.gears as Array).size() },
		"price": extra.price, "rarity": extra.rarity, "tokens": [], "blurb": s.get("blurb", ""),
		"paints": [s.get("paint", "#c8342c")], "art": {}, "quirks": [], "handmade": true,
	}

static func _engine_name(cc: int, layout: String, asp: String) -> String:
	if asp == "E": return "Dual electric motors" if layout == "E2" else "Electric motor"
	var size := ("%d cc" % cc) if cc < 1000 else ("%.1f L" % (cc / 1000.0))
	var kind: String = {
		"S1": "single", "I2": "twin", "F2": "flat-twin", "I3": "inline-3", "I4": "inline-4", "I5": "inline-5",
		"I6": "inline-6", "V6": "V6", "V8": "V8", "V10": "V10", "V12": "V12", "W12": "W12", "W16": "W16",
		"F4": "flat-4", "F6": "flat-6", "F12": "flat-12", "R2": "twin-rotor", "R3": "three-rotor",
	}.get(layout, layout)
	var pre: String = { "T": "turbo ", "TT": "twin-turbo ", "S": "supercharged ", "TD": "turbo-diesel ",
		"D": "diesel ", "2S": "two-stroke " }.get(asp, "")
	return "%s %s%s" % [size, pre, kind]

static func _gearbox_info(code: String) -> Dictionary:
	if code == "CVT": return { "count": 6, "type": "cvt", "code": code, "label": "CVT" }
	if code == "E1": return { "count": 1, "type": "direct", "code": code, "label": "single-speed" }
	if code.begins_with("DCT"):
		var n := int(code.substr(3))
		return { "count": n, "type": "dual-clutch", "code": code, "label": "%d-speed dual-clutch" % n }
	var n := int(code.substr(1))
	var manual := code.begins_with("M")
	return { "count": n, "type": "manual" if manual else "automatic", "code": code,
		"label": "%d-speed %s" % [n, "manual" if manual else "automatic"] }

static func _palette(id: String, year: int, cls: String) -> Array:
	var era: Array = ERA_PAINTS[0][1]
	for row in ERA_PAINTS:
		if year >= int(row[0]): era = row[1]
	var pool: Array = []
	if CLASS_PAINTS.has(cls): pool.append_array(CLASS_PAINTS[cls])
	pool.append_array(era)
	var out: Array = []
	var start := absi(hash(id)) % pool.size()
	for k in pool.size():
		var c: String = pool[(start + k * 3) % pool.size()]
		if not out.has(c): out.append(c)
		if out.size() >= 6: break
	return out

## The art cues CarArt draws, from the table flags plus a few the era and body imply.
static func _art(e: Dictionary, tokens: Array) -> Dictionary:
	var art := {}
	var year: int = e.year
	var body: String = e.body
	for t in tokens:
		if ART_CUES.has(t): art[t] = true
	if year < 1980 and not art.has("nochrome") and not body in ["boxtruck"]: art["chrome"] = true
	if art.has("popups"): art["lamps"] = "popups"
	elif art.has("quad"): art["lamps"] = "quad"
	elif art.has("round") or (year < 1975 and not body in ["wedge"]): art["lamps"] = "round"
	if body == "wagon" and not art.has("norack"): art["rack"] = true
	if body == "suv" and year >= 1995 and not art.has("norack") and not e["class"] in ["crossover", "luxury"]: art["rack"] = true
	if body == "offroad" and not art.has("nospare"): art["spare"] = true
	for k in ["nochrome", "norack", "nospare", "round", "quad"]: art.erase(k)
	if body == "pickup":
		art["cab"] = "crew" if art.has("crew") else ("ext" if art.has("ext") else ("cabover" if art.has("cabover") else ("ute" if art.has("ute") else "reg")))
		for k in ["crew", "ext", "cabover", "ute"]: art.erase(k)
	return art

static func _quirks(e: Dictionary, tokens: Array) -> Array:
	var q: Array = []
	var eng: Dictionary = e.engine
	match String(eng.layout):
		"R2", "R3": q.append("Rotary: check the oil every time you get gas. Bring two quarts.")
		"S1": q.append("One cylinder. You can count the explosions.")
	match String(eng.aspiration):
		"2S": q.append("Two-stroke: mix the oil in with the gas and wave at the blue cloud behind you.")
		"D", "TD": q.append("Diesel: count to ten on the glow plugs in January.")
		"E": q.append("Plug it in. No, not there.")
		"T", "TT":
			if int(e.year) < 1992: q.append("Turbo lag you can measure with a calendar.")
	if String(eng.position) == "rear": q.append("Engine in the back, trunk in the front, physics everywhere.")
	if String(eng.position) == "mid": q.append("Engine behind your head. Luggage space: a glovebox.")
	if String(e.gearbox.type) == "automatic" and int(e.gearbox.count) <= 2: q.append("Two-speed automatic: Drive, and Also Drive.")
	if String(e.gearbox.type) == "manual" and int(e.gearbox.count) == 3 and int(e.year) < 1980: q.append("Three on the tree: the shifter is on the steering column.")
	for t in tokens:
		if QUIRK_TEXT.has(t): q.append(QUIRK_TEXT[t])
	return q

# ------------------------------------------------------------------ the sim spec

const HEIGHT := { "coupe": 1.32, "hatch": 1.42, "sedan": 1.42, "tow": 1.95, "wagon": 1.45, "pickup": 1.85,
	"suv": 1.78, "van": 2.05, "minivan": 1.72, "muscle": 1.32, "sports": 1.24, "wedge": 1.12, "roadster": 1.25,
	"kei": 1.62, "offroad": 1.82, "boxtruck": 3.0, "trike": 1.4, "bubble": 1.38 }
const FIRST_GEAR := { "kei": 11.5, "economy": 13.5, "compact": 14.0, "hatch": 14.0, "sedan": 14.5, "wagon": 14.0,
	"coupe": 15.0, "sports": 16.5, "muscle": 17.5, "pony": 16.5, "luxury": 15.5, "exotic": 19.0, "hot_hatch": 14.5,
	"minivan": 13.5, "van": 12.5, "suv": 12.5, "crossover": 13.5, "pickup": 12.5, "hd_pickup": 11.0,
	"work_truck": 10.0, "offroad": 11.0, "classic": 15.0, "rally": 14.5, "jdm": 15.0, "euro": 14.5, "oddball": 12.0 }

static func _build_spec(e: Dictionary) -> Dictionary:
	var eng: Dictionary = e.engine
	var art: Dictionary = e.art
	var body: String = e.body
	var cls: String = e["class"]
	var year: int = e.year
	var mass: float = e.mass
	var wb: float = e.wheelbase
	var width: float = e.width
	var drive: String = e.drivetrain
	var pos: String = eng.position
	var asp: String = eng.aspiration
	var electric := asp == "E"
	var truck := cls in ["pickup", "hd_pickup", "work_truck"] or body in ["pickup", "boxtruck"]
	var sporty := cls in ["sports", "exotic", "rally", "hot_hatch"]
	# --- where the weight sits
	var front: float = { "FWD": 0.61, "AWD": 0.57, "4WD": 0.56 }.get(drive, 0.53)
	if truck: front = maxf(front, 0.57)
	if pos == "rear": front = 0.40
	elif pos == "mid": front = 0.43
	var height: float = HEIGHT.get(body, 1.42)
	var cg_k := 0.36
	if body in ["pickup", "suv", "offroad", "van", "minivan", "kei"]: cg_k = 0.40
	elif body == "boxtruck": cg_k = 0.32
	elif body in ["wedge", "sports"]: cg_k = 0.38
	# --- air
	var cd := 0.30
	for row in [[1960, 0.50], [1970, 0.48], [1980, 0.46], [1990, 0.39], [2000, 0.34], [2010, 0.32]]:
		if year < int(row[0]):
			cd = float(row[1])
			break
	cd += { "boxtruck": 0.25, "van": 0.05, "pickup": 0.08, "offroad": 0.10, "suv": 0.04, "kei": 0.02,
		"wedge": -0.04, "sports": -0.03, "roadster": 0.02 }.get(body, 0.0)
	var cda := cd * width * height * (0.9 if body == "boxtruck" else 0.84)
	# --- tires
	var tire := _tires(e, truck)
	var r: float = tire.radius
	# --- engine
	var red: float = eng.redline
	var idle := 800.0
	var disp: float = float(eng.cc) / 1000.0
	if electric: idle = 400.0
	elif asp in ["D", "TD"]: idle = 700.0
	elif asp == "2S" or eng.layout == "S1": idle = 1000.0
	elif eng.layout in ["R2", "R3"]: idle = 900.0
	elif disp >= 4.5: idle = 650.0
	elif disp < 1.0: idle = 950.0
	elif eng.layout in ["I6", "V6"]: idle = 750.0
	var curve := _torque_curve(float(eng.hp), float(eng.torque), red, idle, asp, disp, int(year))
	var peak_t := 0.0
	for p in curve: peak_t = maxf(peak_t, float(p[1]))
	var engine := {
		"name": eng.name,
		"idle_rpm": idle,
		"redline_rpm": red,
		"limiter_rpm": red + (200.0 if asp in ["D", "TD"] or electric else 300.0),
		"inertia": snappedf(clampf((0.08 if electric else 0.12) + 0.04 * disp * (1.25 if asp in ["D", "TD"] else 1.0), 0.06, 0.5), 0.01),
		"clutch_torque": snappedf(maxf(peak_t * 1.55, 60.0), 1.0),
		"torque_curve": curve,
	}
	if asp in ["T", "TT", "TD"]:
		var spool := red * (0.38 if asp == "TT" else 0.42)
		var lag := 0.7 if year < 1990 else (0.55 if year < 2005 else 0.38)
		var no_boost := 0.6 if year < 1990 else (0.66 if year < 2005 else 0.72)
		if asp == "TD":
			spool = 1700.0
			lag = 0.5
			no_boost = 0.55
		if asp == "TT": lag *= 0.8
		engine["turbo"] = { "spool_rpm": snappedf(spool, 10.0), "lag": snappedf(lag, 0.01), "no_boost": no_boost }
	var s := {
		"id": e.id, "make": e.make, "model": e.model, "year": year, "blurb": e.blurb,
		"class": cls, "body": body, "side_body": e.side_body, "art": art.duplicate(), "quirks": (e.quirks as Array).duplicate(),
		"price": e.price, "drivetrain": drive, "mass": mass, "wheelbase": wb,
		"cg_front": snappedf(wb * (1.0 - front), 0.01), "cg_height": snappedf(height * cg_k, 0.01),
		"track": e.track, "length": e.length, "width": width,
		"cda": snappedf(cda, 0.01),
		"steer_lock": 0.62 if body in ["kei", "bubble", "trike"] else (0.55 if sporty or body in ["wedge", "sports"] else 0.58),
		# CarSim drives the rear axle only: all-wheel drive shows up as a rear that hooks up and stays put
		"rear_grip": { "FWD": 1.12, "AWD": 1.22, "4WD": 1.12 }.get(drive, 1.0 if truck else (1.12 if float(eng.hp) / mass * 1000.0 > 200.0 else 1.05)),
		"engine": engine,
		"tires": tire,
		"paint": (e.paints as Array)[0],
		"dash": _dash(e, truck),
		"gps": _gps(e, truck),
	}
	if pos == "rear": s.rear_grip = 1.14
	elif pos == "mid": s.rear_grip = 1.10
	s["gearbox"] = _gears(e, s)
	var mu_b := 1.22
	for row in [[1965, 0.95], [1975, 1.0], [1990, 1.08], [2005, 1.15]]:
		if year < int(row[0]):
			mu_b = float(row[1])
			break
	if sporty: mu_b += 0.1
	if truck: mu_b -= 0.1
	s["brakes"] = {
		"max_torque": snappedf(mass * G * mu_b * r, 50.0),
		"bias": { "FWD": 0.68, "AWD": 0.64 }.get(drive, 0.62) if pos == "front" else (0.56 if pos == "rear" else 0.58),
	}
	return s

## Full-throttle torque (N·m) against rpm, shaped by how the engine breathes, through the
## quoted peak torque and peak power.
static func _torque_curve(hp: float, nm: float, red: float, idle: float, asp: String, disp: float, year: int) -> Array:
	var kw := hp * 0.7457
	var w := TAU / 60.0
	if asp == "E":
		# full torque from standstill to the base speed, then constant power
		var base := minf(kw * 1000.0 / (nm * w), red * 0.8)
		var pts: Array = [[idle, nm], [base, nm]]
		for k in [1.4, 1.9, 2.6, 3.4]:
			var rr: float = base * k
			if rr < red - 100.0: pts.append([snappedf(rr, 10.0), snappedf(kw * 1000.0 / (rr * w), 0.1)])
		var t_red := kw * 1000.0 / (red * w)
		pts.append([red, snappedf(t_red, 0.1)])
		pts.append([red + 200.0, snappedf(t_red * 0.8, 0.1)])
		pts.append([red + 900.0, snappedf(t_red * 0.4, 0.1)])
		return _clean(pts)
	var rp := red * 0.92            # peak power
	var rt := red * 0.60            # peak torque starts
	var rt2 := -1.0                 # ...and ends (turbos and diesels have a plateau)
	var low := 0.62                 # fraction of peak torque just off idle
	match asp:
		"T", "TT":
			rp = red * 0.88; rt = red * (0.45 if year < 1990 else 0.36); rt2 = red * 0.68; low = 0.42
		"TD":
			rp = red * 0.85; rt = red * 0.38; rt2 = red * 0.62; low = 0.45
		"D":
			rp = red * 0.9; rt = red * 0.5; rt2 = red * 0.56; low = 0.6
		"S":
			rp = red * 0.9; rt = red * 0.45; rt2 = red * 0.66; low = 0.62
		"2S":
			rp = red * 0.92; rt = red * 0.7; low = 0.42
		_:
			if disp >= 4.0:
				rt = red * 0.5; low = 0.7
			elif red >= 7500.0:
				rt = red * 0.72; low = 0.5
	if rt2 < rt: rt2 = rt
	var tp := kw * 1000.0 / (rp * w)
	if tp > nm * 0.98:
		# the quoted power needs more torque at the power peak than the quoted torque: move
		# the peak down if there's room, otherwise trust the power figure
		var rp2 := kw * 1000.0 / (nm * 0.97 * w)
		if rp2 >= rt2 + 200.0:
			rp = rp2
			tp = nm * 0.97
		else:
			nm = tp / 0.97
	var t_red := tp * rp / red * 0.96
	var pts: Array = [
		[idle, nm * low],
		[lerpf(idle, rt, 0.5), nm * (low + (1.0 - low) * 0.72)],
		[rt, nm],
	]
	if rt2 > rt + 100.0: pts.append([rt2, nm])
	pts.append([lerpf(rt2, rp, 0.5), lerpf(nm, tp, 0.45)])
	pts.append([rp, tp])
	if red > rp + 60.0: pts.append([red, t_red])
	pts.append([red + 300.0, t_red * 0.9])
	pts.append([red + 1000.0, t_red * 0.7])
	return _clean(pts)

## Rounded, strictly rising rpm, as floats (the shape JSON gives the hand-made cars). The
## quoted figures are at the crank; CarSim takes its own internal friction (12 + 0.0045·rpm N·m)
## off the curve, so the curve carries it on top, or a 600 cc kei engine would never get going.
static func _clean(pts: Array) -> Array:
	var out: Array = []
	var last := -1.0
	for p in pts:
		var rr := snappedf(float(p[0]), 10.0)
		if rr <= last: continue
		out.append([rr, snappedf(maxf(float(p[1]), 1.0) + 12.0 + 0.0045 * rr, 0.1)])
		last = rr
	return out

static func _tires(e: Dictionary, truck: bool) -> Dictionary:
	var cls: String = e["class"]
	var year: int = e.year
	var mass: float = e.mass
	var w := 120.0 + mass * 0.055
	w += { "sports": 15.0, "exotic": 40.0, "muscle": 20.0, "pony": 10.0, "hot_hatch": 10.0, "rally": 5.0,
		"kei": -15.0, "luxury": 5.0 }.get(cls, 0.0)
	if year < 1975: w -= 10.0
	elif year >= 2010: w += 10.0
	if truck: w = clampf(w, 215.0, 285.0)
	w = clampf(w, 125.0, 335.0)
	var wmm := int(floor(w / 10.0)) * 10 + 5
	var econ := cls in ["economy", "kei"]
	var fancy := cls in ["sports", "exotic", "luxury", "muscle", "pony", "hot_hatch", "rally"]
	var rim := 14
	if year < 1965: rim = 15 if mass > 1800.0 else 14
	elif year < 1980: rim = 13 if econ else (15 if truck or cls == "luxury" else 14)
	elif year < 1990: rim = 13 if econ else (15 if fancy or truck else 14)
	elif year < 2000: rim = 14 if econ else (16 if fancy or truck else 15)
	elif year < 2010: rim = 15 if econ else (18 if cls == "exotic" else (17 if fancy or truck else 16))
	else: rim = 15 if econ else (20 if cls == "exotic" else (18 if fancy or truck else 17))
	if cls == "kei" or mass < 700.0: rim = mini(rim, 12 if year < 1990 else 13)
	if mass < 450.0: rim = 10
	var aspect := 55
	if year < 1975: aspect = 80
	elif year < 1985: aspect = 75 if not fancy else 60
	elif year < 1995: aspect = 65 if not fancy else 55
	elif year < 2005: aspect = 60 if not fancy else 45
	else: aspect = 55 if not fancy else (30 if cls == "exotic" else 35)
	if truck or e.body in ["offroad"]: aspect = maxi(aspect, 70)
	var radius := (rim * 25.4 / 2.0 + wmm * aspect / 100.0) / 1000.0
	var size := ""
	if year < 1975 and not truck:
		var steps := [4.80, 5.20, 5.60, 6.00, 6.45, 6.95, 7.35, 7.75, 8.25, 8.55, 8.85, 9.15]
		var inch := wmm / 25.4 * 1.03
		var best: float = steps[0]
		for s in steps:
			if absf(float(s) - inch) < absf(best - inch): best = s
		size = "%.2f-%d" % [best, rim]
	elif truck:
		size = "LT%d/%dR%d" % [wmm, aspect, rim]
	else:
		size = "%d/%dR%d" % [wmm, aspect, rim]
	var drv: String = e.drivetrain
	return {
		"radius": snappedf(radius, 0.005),
		"tread_mm": 12.0 if truck else (7.0 if cls in ["sports", "exotic"] else (9.0 if year < 1975 else 8.0)),
		"driven_inertia": snappedf(1.2 + mass / 1000.0 + (1.2 if truck or drv == "4WD" else 0.0), 0.1),
		"size": size,
	}

## Gear ratios: top gear runs out of revs a little past the top speed the car can push through
## the air (overdrives a lot past it), first gear runs out at a speed that suits the class.
static func _gears(e: Dictionary, sp: Dictionary) -> Dictionary:
	var info: Dictionary = e.gearbox
	var kind: String = info.type
	var n: int = info.count
	var year: int = e.year
	var cls: String = e["class"]
	var drv: String = e.drivetrain
	var red: float = sp.engine.redline_rpm
	var r: float = sp.tires.radius
	var mass: float = sp.mass
	var cda: float = sp.cda
	var w_red := red * TAU / 60.0
	var eff := 0.87
	match kind:
		"automatic": eff = 0.80 if year < 1990 else 0.85
		"cvt": eff = 0.83
		"dual-clutch": eff = 0.88
		"direct": eff = 0.94
	if drv in ["AWD", "4WD"]: eff -= 0.02
	# top speed through the air: power at the wheels = drag + rolling
	var kw: float = float(e.engine.hp) * 0.7457
	var p := kw * 1000.0 * eff * 0.95
	var lo := 5.0
	var hi := 160.0
	for i in 40:
		var v := (lo + hi) / 2.0
		if 0.6 * cda * v * v * v + 0.013 * mass * G * v > p: hi = v
		else: lo = v
	var v_air := lo
	var shift_time := 0.28
	match kind:
		"manual": shift_time = 0.2 if cls in ["sports", "exotic", "rally", "hot_hatch"] else (0.32 if year < 1975 else 0.28)
		"automatic": shift_time = 0.5 if n <= 3 else (0.38 if n == 4 else (0.28 if n <= 6 else 0.18))
		"cvt": shift_time = 0.12
		"dual-clutch": shift_time = 0.08
		"direct": shift_time = 0.1
	if n <= 1:
		var vt1 := clampf(v_air * 1.04, 25.0, 90.0)
		return { "gears": [1.0], "reverse": 1.0, "final": snappedf(w_red * r / vt1, 0.01), "efficiency": snappedf(eff, 0.01), "shift_time": shift_time }
	var over := 1.02
	if n == 4: over = 1.08
	elif n >= 5: over = 1.2
	var vt := clampf(v_air * over, 22.0, 105.0)
	var v1: float = FIRST_GEAR.get(cls, 14.0)
	if n == 2: v1 *= 1.9
	elif n == 3: v1 *= 1.45
	elif n == 4: v1 *= 1.12
	elif n >= 8: v1 *= 0.9
	v1 = minf(v1, vt * 0.6)
	var gt := 1.0
	if n == 4 and (kind != "manual" and year >= 1980): gt = 0.7
	elif n == 5: gt = 0.8 if kind == "manual" else 0.75
	elif n == 6: gt = 0.68
	elif n == 7: gt = 0.64
	elif n >= 8: gt = 0.67 if n == 8 else 0.6
	var spread := vt / v1
	var g1 := clampf(gt * spread, 2.2, 6.0)
	var fin := w_red * r / (gt * vt)
	if fin > 6.2 or fin < 2.0:
		fin = clampf(fin, 2.0, 6.2)
		gt = w_red * r / (fin * vt)
		g1 = gt * spread
	var gears: Array = []
	for i in n:
		var k := pow(float(i) / float(n - 1), 0.85)
		gears.append(snappedf(g1 * pow(gt / g1, k), 0.01))
	return {
		"gears": gears,
		"reverse": snappedf(g1 * 1.05, 0.01),
		"final": snappedf(fin, 0.01),
		"efficiency": snappedf(eff, 0.01),
		"shift_time": shift_time,
	}

static func _dash(e: Dictionary, truck: bool) -> String:
	if truck or e.body in ["van", "boxtruck"]: return "truck"
	if (e.tokens as Array).has("digidash"): return "digital80"
	if int(e.year) >= 2012: return "tft"
	return "analog90"

static func _gps(e: Dictionary, truck: bool) -> String:
	var year: int = e.year
	if truck: return "trucker"
	if e["class"] in ["luxury", "exotic"] and year >= 2003: return "builtin"
	if year >= 2009: return "phone"
	if year >= 1998: return "tomtum"
	return "phone" if absi(hash(e.id)) % 2 == 0 else "tomtum"

static func _zone_table(zone_style: String) -> Array:
	var mult: Dictionary = ZONE_MULT.get(zone_style, {})
	var ids_z: Array = []
	var cum: Array = []
	var total := 0.0
	for id in _order:
		var e: Dictionary = _entries[id]
		var wgt: float = float(e.rarity) * float(mult.get(e["class"], 1.0))
		var age := GAME_YEAR - int(e.year)
		if zone_style in ["rural", "village"] and age >= 20: wgt *= 1.4
		if zone_style == "downtown" and age >= 25 and e["class"] != "classic": wgt *= 0.7
		if wgt <= 0.0: continue
		total += wgt
		ids_z.append(id)
		cum.append(total)
	return [ids_z, cum]

# ------------------------------------------------------------------ the table
# make|model|year|class|body|length m|width m|wheelbase m|kg|drive|cc|layout|aspiration|hp|Nm|redline|gearbox|price CAD|rarity|flags|blurb
# layout: S1 I2 F2 I3 I4 I5 I6 V6 V8 V10 V12 W12 W16 F4 F6 F12 R2 R3 E1 E2
# aspiration: NA T TT S TD D 2S E     gearbox: M3..M7 A2..A10 CVT DCT6 DCT7 E1
# flags: art cues (see ART_CUES), mid / rear (engine position), digidash, p=#hex/#hex (palette)

const TABLE := """
# ---- Fjord
Fjord|Fairlame|1957|classic|sedan|5.08|1.96|2.95|1560|RWD|4785|V8|NA|190|366|4600|A3|32000|1.5|fins,twotone|Two-tone paint, a three-speed automatic, four drum brakes and a prayer for the fifth.
Fjord|Thunderburd|1957|classic|roadster|4.65|1.83|2.59|1590|RWD|5112|V8|NA|245|450|4800|A3|68000|0.6|hardtop,fins|The porthole hardtop comes off with two people and one hernia.
Fjord|Galaxee 500|1964|classic|sedan|5.33|2.02|3.05|1700|RWD|4736|V8|NA|195|390|4800|A3|24000|1.5||Five hundred of nothing in particular. Corners like a sofa going down a staircase.
Fjord|Falconn|1963|compact|sedan|4.6|1.78|2.78|1200|RWD|2781|I6|NA|101|210|4400|M3|14000|1.2||The sensible one. Three on the tree, and the tree has rust.
Fjord|Mustank|1966|pony|coupe|4.61|1.73|2.74|1300|RWD|4736|V8|NA|225|414|5000|M4|45000|1.5||The original pony. Every seller swears it's the one from the movie.
Fjord|Mustank Fastback|1969|muscle|muscle|4.8|1.82|2.74|1560|RWD|7014|V8|NA|335|597|5400|M4|95000|0.6|scoop,stripes|The scoop is real. So is the fuel bill. So is the guy who wants to race you at every light.
Fjord|Mustank|1988|pony|coupe|4.56|1.73|2.55|1430|RWD|4942|V8|NA|225|407|4800|M5|16000|3||Five-point-oh. Every gas station in Port Rumble has seen one do a burnout. Most of them have seen this one.
Fjord|Mustank|2005|pony|coupe|4.77|1.88|2.72|1590|RWD|4606|V8|NA|300|434|6000|M5|15000|5||Retro sheet metal, a live rear axle, and a strong belief that every on-ramp is a drag strip.
Fjord|Mustank|2018|pony|coupe|4.78|1.92|2.72|1700|RWD|5038|V8|NA|460|569|7400|M6|38000|4||Line-lock mode from the factory. It finds the crowd leaving every car show, and then it finds the curb.
Fjord|Pintoh|1974|economy|hatch|4.23|1.75|2.39|1100|RWD|2295|I4|NA|88|165|5000|M4|4500|1.2||Rear-ending one is not recommended. Neither is being one.
Fjord|Mavericky|1972|compact|coupe|4.55|1.79|2.62|1270|RWD|3277|I6|NA|98|220|4400|A3|11000|1.2||Cheap, simple and unkillable. In fairness, nobody has tried very hard.
Fjord|Torinno|1972|muscle|muscle|5.3|2.0|3.0|1720|RWD|5752|V8|NA|163|400|4400|A3|26000|1.2|stripes|Comes with a lawn. You will be told to get off it.
Fjord|Ell-Tee-Dud|1975|sedan|sedan|5.6|2.0|3.08|2100|RWD|6555|V8|NA|158|393|4000|A3|7000|0.8|vinyl|Limited, it says on the badge. Unlimited, the trunk. Bring friends, and a shovel for winter.
Fjord|Country Square|1978|wagon|wagon|5.79|2.0|3.1|2150|RWD|6555|V8|NA|160|400|4000|A3|9500|1.5|wood|Seats nine, eight if one of them is Uncle Gord. Fake wood, real rust.
Fjord|Fairmonte|1981|sedan|sedan|4.9|1.8|2.7|1300|RWD|3277|I6|NA|88|220|4400|A3|3800|1.5|vinyl|The vinyl roof is peeling like a sunburnt tourist at Parlee Beach.
Fjord|Escorted|1987|economy|hatch|4.1|1.67|2.4|950|FWD|1897|I4|NA|90|145|5800|M5|1800|5||Your first car, your sister's first car, and somehow still somebody's first car.
Fjord|Tempoh|1990|compact|sedan|4.5|1.73|2.54|1200|FWD|2295|I4|NA|98|170|5000|A3|1500|5||Italian for time. This one is out of it.
Fjord|Torus|1989|sedan|sedan|4.79|1.8|2.69|1400|FWD|2986|V6|NA|140|217|5000|A4|2200|7||The jellybean that saved a company. Now it saves a parking spot at the curling club.
Fjord|Torus Ess-Aitch-Oh|1991|sedan|sedan|4.79|1.8|2.69|1450|FWD|2986|V6|NA|220|271|7300|M5|6500|1.2||A V6 with a motorcycle maker's soul in a body your accountant would pick.
Fjord|Probed|1993|sports|sports|4.5|1.77|2.61|1270|FWD|2497|V6|NA|164|217|6500|M5|3500|2|popups|Pop-up headlights and front-wheel drive. Half of a sports car, all of the payments.
Fjord|Aerostare|1992|minivan|minivan|4.5|1.83|3.02|1700|RWD|3983|V6|NA|155|312|5000|A4|2500|3||A rear-wheel-drive minivan: every hockey dad's secret drift car.
Fjord|Econolean|1995|van|van|5.4|2.0|3.5|2300|RWD|4942|V8|NA|205|373|4500|A4|4500|5|cargo,ladder|No windows in the back. Strictly for plumbing. Mostly.
Fjord|Crown Victorious|2005|sedan|sedan|5.39|1.98|2.91|1800|RWD|4606|V8|NA|224|373|5000|A4|5500|6|spotlight|Ex-cop. Drivers on the highway still drop to 99 when they see it in the mirror.
Fjord|F-One-Fiddy|1979|pickup|pickup|5.3|2.0|3.33|1900|RWD|5752|V8|NA|156|373|4000|M4|9000|2||Rust holes big enough to check the tire pressure from the cab.
Fjord|F-One-Fiddy|1996|pickup|pickup|5.7|2.0|3.53|2000|4WD|4942|V8|NA|205|373|4500|A4|5000|9|ext|Four-by-four, five-point-oh, and a toolbox full of empty coffee cups.
Fjord|F-One-Fiddy|2015|pickup|pickup|5.9|2.03|3.68|2250|4WD|3497|V6|TT|365|569|6000|A6|27000|12|crew|Aluminum body: the rust has to find a new hobby.
Fjord|F-Two-Fiddy Super Duty-Free|2006|hd_pickup|pickup|6.2|2.03|4.0|3100|4WD|5998|V8|TD|325|760|3500|A5|17000|5|crew|The six-litre diesel: famous for torque, infamous for head gaskets, never boring.
Fjord|F-Three-Fiddy Dually|2017|hd_pickup|pickup|6.7|2.4|4.2|3600|4WD|6700|V8|TD|440|1166|3500|A6|52000|2|crew,dually|Six wheels, a thousand newton-metres and a wide-load swagger in the grocery store parking lot.
Fjord|F-Four-Fiddy Service|2010|work_truck|pickup|6.6|2.4|4.2|3800|4WD|6800|V10|NA|362|624|4750|A5|24000|2|crew,dually,ladder,toolbox,beacon|Ladder rack, amber beacon, a toolbox with the good wrenches and a driver who knows where every hydro line is.
Fjord|Rangor|1998|pickup|pickup|4.8|1.75|2.85|1400|RWD|2499|I4|NA|117|203|5000|M5|3500|6|ext|Compact truck, compact engine, compact expectations. Exceeds all of them, by a little.
Fjord|Rangor|2010|pickup|pickup|5.15|1.76|3.2|1600|4WD|4016|V6|NA|207|322|5000|A5|9000|6|ext|The mechanics call it the hammer: simple, heavy, and mostly used for hitting things.
Fjord|Exploder|1995|suv|suv|4.79|1.79|2.84|1900|4WD|4015|V6|NA|160|305|5000|A4|2500|6||Check the tire pressure. Then check it again. Then maybe a third time.
Fjord|Expeditious|2003|suv|suv|5.2|2.0|3.02|2600|4WD|5408|V8|NA|260|474|5000|A4|7000|5||Three rows, eight seats, and the turning circle of a cruise ship.
Fjord|Siesta|2014|economy|hatch|4.07|1.72|2.49|1170|FWD|1596|I4|NA|120|152|6500|DCT6|7500|8||Nap-sized. The dual-clutch gearbox likes a little lie-down at every stop sign too.
Fjord|Fokus|2008|compact|sedan|4.5|1.7|2.62|1250|FWD|1999|I4|NA|140|184|6500|A4|4000|10||Perfectly adequate. It says so on the window sticker, in very small letters.
Fjord|Fokus Arr-Ess|2017|hot_hatch|hatch|4.39|1.82|2.65|1530|AWD|2261|I4|T|350|475|6800|M6|38000|1.5|spoiler|Has a drift mode button. Nobody knows what it does to the diff. Everybody knows what it does to the tires.
Fjord|Escorted Arr-Ess Cossie|1994|rally|hatch|4.2|1.74|2.55|1275|AWD|1993|I4|T|224|304|6500|M5|85000|0.03|wing|A whale-tail wing the size of a picnic table and a turbo that sounds like an angry kettle.
Fjord|Fussion|2013|sedan|sedan|4.87|1.85|2.85|1550|FWD|2488|I4|NA|175|237|6500|A6|11000|12||The grille looks borrowed from something Italian. The rest of it clearly was not.
Fjord|Escaped|2012|crossover|suv|4.44|1.81|2.62|1600|AWD|2488|I4|NA|171|231|6500|A6|10000|12||Every third driveway in Riverside has one. Every second one has two.
Fjord|Edgy|2016|crossover|suv|4.81|1.93|2.85|1850|AWD|3496|V6|NA|280|340|6500|A6|22000|8||It isn't, really. That's the joke.
Fjord|Fleks|2011|crossover|suv|5.13|1.93|2.99|2100|AWD|3496|V6|NA|262|336|6500|A6|9000|2||A shoebox for seven, with a refrigerator in the console. The shoebox is very nice.
Fjord|Transitory|2016|van|van|5.98|2.47|3.3|2300|RWD|3496|V6|NA|275|353|6000|A6|32000|5|cargo|High roof: you can stand up in the back, and you will, because the seat is broken.
Fjord|E-Three-Fiddy Cube|2008|work_truck|boxtruck|6.9|2.4|4.0|3800|RWD|5408|V8|NA|255|474|4500|A5|22000|4||Sixteen feet of box. The ramp is out back, and so is your weekend.
Fjord|GT-Fourty-ish|2005|exotic|wedge|4.64|1.95|2.71|1520|RWD|5409|V8|S|550|678|6500|M6|480000|0.15|mid|Forty-four inches tall. You don't get in, you get installed.
Fjord|Broncho|1970|offroad|offroad|3.9|1.75|2.33|1500|4WD|4942|V8|NA|205|400|4400|M3|55000|0.8|open|Early, uncut, no rust: pick any two.
Fjord|Broncho|1990|suv|suv|4.6|2.0|2.66|2100|4WD|5751|V8|NA|210|427|4200|A4|14000|1.5||Removable roof, irremovable smell of wet dog.
Fjord|Rancherro|1972|pickup|pickup|5.2|2.0|3.0|1600|RWD|5752|V8|NA|163|400|4400|A3|16000|0.8|ute|Car in the front, truck in the back, mullet in the driver's seat.
Fjord|Windstair|1999|minivan|minivan|5.1|1.95|3.07|1900|FWD|3797|V6|NA|200|325|5000|A4|1800|6||Front-wheel drive, rear-wheel rust, and a sliding door that slides when it feels like it.
Fjord|Five Hunnert|2006|sedan|sedan|5.07|1.89|2.87|1700|AWD|2967|V6|NA|203|280|6500|CVT|3500|4||A big sedan with a small engine and a gearbox that drones like a bagpipe at a funeral.
Fjord|Contort|1997|sedan|sedan|4.67|1.75|2.7|1300|FWD|1999|I4|NA|125|177|6500|M5|1200|3||A world car, they said. The world took one look and passed.
# ---- Chevrolay
Chevrolay|Bel Err|1957|classic|sedan|5.0|1.88|2.92|1550|RWD|4637|V8|NA|220|366|5000|A2|58000|1|fins,twotone|The fins are pure jet age. The two-speed automatic is pure stone age.
Chevrolay|Biscaynne|1962|classic|sedan|5.3|1.97|3.02|1600|RWD|3851|I6|NA|135|295|4200|M3|15000|0.4||The stripper model: rubber floor mats, a six and no radio. The farmer's choice and the hot-rodder's secret.
Chevrolay|Impaler|1964|classic|sedan|5.4|2.02|3.0|1650|RWD|5359|V8|NA|250|475|4800|A2|36000|1.2||Long, low and wide, and happiest hopping three feet in the air on somebody else's suspension.
Chevrolay|Impaler|1977|sedan|sedan|5.4|1.95|2.95|1700|RWD|5733|V8|NA|170|366|4200|A3|8000|1.2||The first downsized one. Still bigger than your apartment.
Chevrolay|Impaler|2008|sedan|sedan|5.09|1.85|2.81|1600|FWD|3510|V6|NA|211|290|6000|A4|3500|10||Rental-counter royalty. Every trunk smells faintly of airport.
Chevrolay|Shovelle Ess-Ess|1970|muscle|muscle|5.06|1.92|2.84|1650|RWD|7440|V8|NA|450|678|5600|M4|85000|0.6|scoop,stripes|Four hundred fifty horsepower in 1970 money. Bias-ply tires in 1970 grip.
Chevrolay|Novah|1972|compact|coupe|4.8|1.84|2.81|1400|RWD|4097|I6|NA|110|251|4200|A3|12000|1.5||Legend says the name means 'doesn't go' in Spanish. It goes. Slowly.
Chevrolay|Camareo|1969|muscle|muscle|4.72|1.88|2.74|1500|RWD|5733|V8|NA|300|515|5400|M4|78000|0.8|scoop,stripes|First-generation, big-block dreams, small-block reality, rally stripes regardless.
Chevrolay|Camareo|1985|pony|coupe|4.87|1.85|2.56|1450|RWD|5001|V8|NA|190|366|4600|A4|9000|2|ttops|T-tops, a mullet's natural habitat, and a dashboard that rattles in G.
Chevrolay|Camareo|1998|pony|coupe|4.92|1.88|2.57|1550|RWD|5665|V8|NA|305|454|6000|M6|11000|2.5|ttops|A pointy nose, a long dash, a short temper.
Chevrolay|Camareo Ess-Ess|2016|pony|coupe|4.78|1.9|2.81|1700|RWD|6162|V8|NA|455|617|6500|M6|42000|2.5||You can't see out of it. That's fine. The point is that everyone sees you.
Chevrolay|Corvet|1963|sports|sports|4.45|1.77|2.49|1400|RWD|5359|V8|NA|300|488|5500|M4|120000|0.4|split|Split rear window: the most beautiful blind spot ever made.
Chevrolay|Corvet|1979|sports|sports|4.7|1.75|2.49|1550|RWD|5733|V8|NA|195|380|5000|A3|19000|1|ttops|Soda-bottle hips, a hood longer than a hockey stick, and T-tops that drip on your left knee.
Chevrolay|Corvet|1997|sports|sports|4.57|1.87|2.65|1470|RWD|5665|V8|NA|345|475|6000|M6|28000|1|popups|Pop-up headlights, a pushrod V8 and a seat built for a man who owns a boat.
Chevrolay|Corvet Zee-Oh-Sicks|2015|exotic|sports|4.5|1.97|2.71|1600|RWD|6162|V8|S|650|881|6600|M7|85000|0.5|wing|Six hundred fifty horsepower and a cupholder. A whole continent, condensed.
Chevrolay|Vegan|1973|economy|hatch|4.4|1.65|2.47|1050|RWD|2287|I4|NA|90|176|4800|M4|3500|0.8||Aluminum block, plenty of opinions, no meat on its bones. Rusts before you finish reading this.
Chevrolay|Shovette|1984|economy|hatch|4.1|1.57|2.4|900|RWD|1598|I4|NA|65|108|5200|M4|1800|1.5||Rear-wheel drive, sixty-five horsepower and the gravitational pull of every snowbank in Havelock.
Chevrolay|Citashun|1981|compact|hatch|4.5|1.73|2.66|1150|FWD|2474|I4|NA|90|180|4400|A3|1500|1||Recalled more often than your ex.
Chevrolay|Caprees|1986|sedan|sedan|5.4|1.92|2.94|1700|RWD|5001|V8|NA|165|339|4400|A4|5500|2.5|vinyl|The box. Cab companies loved it, cops loved it, and no uncle has ever sold one.
Chevrolay|Caprees Wagon|1994|wagon|wagon|5.6|2.0|2.94|2100|RWD|5733|V8|NA|260|447|5000|A4|9000|1.2|wood|A whale with a small-block. The rear-facing third row is basically a drive-in theatre.
Chevrolay|Cava-Lame|1987|compact|coupe|4.6|1.7|2.64|1150|FWD|1990|I4|NA|90|150|5200|A3|1500|4||Your cousin's. It's always been your cousin's.
Chevrolay|Cava-Lame|2002|compact|sedan|4.6|1.74|2.64|1200|FWD|2190|I4|NA|115|183|6000|A4|1200|8||Rust, a cassette adapter and four tires from three different decades.
Chevrolay|Cobbolt|2008|compact|coupe|4.58|1.73|2.62|1250|FWD|2189|I4|NA|155|203|6500|M5|2500|9||Don't hang anything heavy off the ignition key. Trust us. Just don't.
Chevrolay|Maliboo|1980|sedan|sedan|4.98|1.83|2.75|1400|RWD|3785|V6|NA|115|258|4400|A3|4500|1.5||The lowrider kids want the frame, the drift kids want the diff, and you just want it to start.
Chevrolay|Maliboo|2016|sedan|sedan|4.92|1.85|2.83|1500|FWD|1490|I4|T|160|250|6000|A6|14000|12||Tiny turbo, quiet cabin, the dashboard of a hotel lobby.
Chevrolay|Lumenah|1995|sedan|sedan|5.08|1.84|2.73|1500|FWD|3135|V6|NA|160|251|5200|A4|1500|4||Every one ever built was a taxi or wanted to be.
Chevrolay|Astronot|1999|minivan|minivan|4.82|1.97|2.82|1950|RWD|4300|V6|NA|190|339|4800|A4|3500|3|ladder|Rear-wheel drive, truck frame and a ladder rack: the contractor's minivan.
Chevrolay|Upslander|2007|minivan|minivan|5.2|1.83|3.08|1950|FWD|3880|V6|NA|240|325|6000|A4|2000|5||A minivan with a sport-ute nose glued on. Fooled nobody, including the minivan.
Chevrolay|Expresso|2010|van|van|5.69|2.01|3.43|2600|RWD|4800|V8|NA|280|400|5200|A4|14000|5|cargo,ladder|Strong coffee, stronger van. Three ladders and a smell of solvent included.
Chevrolay|Suburbian|1987|suv|suv|5.6|2.0|3.3|2400|4WD|5733|V8|NA|210|407|4400|A4|9000|2|twotone|Two-tone paint, barn doors at the back and room for a whole minor hockey line.
Chevrolay|Suburbian|2015|suv|suv|5.7|2.04|3.3|2600|4WD|5328|V8|NA|355|519|6000|A6|42000|4||Picks up the whole team, drops the whole fuel budget.
Chevrolay|Blazzer|1977|offroad|offroad|4.7|2.0|2.7|2100|4WD|5733|V8|NA|165|346|4200|A3|28000|0.8|open|A convertible, a truck and a bathtub when it rains.
Chevrolay|Ess-Ten|1994|pickup|pickup|4.9|1.73|2.75|1450|RWD|4300|V6|NA|165|339|4800|M5|3500|5|ext|The small truck with the big V6. Every rural driveway has one up on blocks.
Chevrolay|Silver-Addo|2004|pickup|pickup|5.8|2.0|3.65|2200|4WD|5328|V8|NA|295|454|5600|A4|7500|12|ext|Rocker panels made of a substance science calls 'mostly hope.'
Chevrolay|Silver-Addo|2018|pickup|pickup|5.84|2.03|3.65|2300|4WD|5328|V8|NA|355|519|5800|A6|35000|10|crew|A chrome grille the size of a garage door. You will see it in your mirror on the highway. Very close.
Chevrolay|Silver-Addo Thirty-Five Hunnert|2012|hd_pickup|pickup|6.6|2.03|4.3|3400|4WD|6599|V8|TD|397|1037|3600|A6|38000|3|crew|The diesel that pulls a house. Pulled one, in fact, out of Salisbury, in 2016.
Chevrolay|El Caminno|1979|pickup|pickup|5.3|1.85|2.9|1500|RWD|5001|V8|NA|160|353|4400|A3|14000|0.8|ute|Business in the front, party in the back, and both of them a bit rusty.
Chevrolay|Avalaunch|2005|pickup|pickup|5.62|2.0|3.3|2600|4WD|5328|V8|NA|295|454|5600|A4|7000|2|crew|Half pickup, half sport ute, all plastic cladding.
Chevrolay|Step Vann|1985|work_truck|boxtruck|6.6|2.3|3.8|2900|RWD|5733|V8|NA|165|380|4000|A3|8000|1.5||Bread truck. The bread is long gone. The smell is not.
Chevrolay|Sparkk|2016|economy|hatch|3.64|1.6|2.38|1030|FWD|1399|I4|NA|98|128|6300|CVT|7500|5||Small enough to park sideways, slow enough to get passed by tractors on the 106.
Chevrolay|Crews|2014|compact|sedan|4.6|1.8|2.69|1400|FWD|1362|I4|T|138|200|6000|A6|8000|10||A small turbo with big feelings about coolant.
Chevrolay|Equinocks|2017|crossover|suv|4.65|1.84|2.72|1650|AWD|1490|I4|T|170|275|6000|A6|19000|10||Equal day, equal night, equal parts beige.
Chevrolay|Voltt|2013|compact|hatch|4.5|1.79|2.68|1720|FWD|0|E1|E|149|370|9000|E1|11000|2||Electric until it isn't. Then a little gas engine wakes up and apologizes.
# ---- GMZ
GMZ|Sierruh|1988|pickup|pickup|5.4|2.0|3.33|1950|4WD|5733|V8|NA|210|407|4400|A4|7000|5|ext|Built like a filing cabinet. Rusts like one, too.
GMZ|Sierruh Plow Rig|2002|work_truck|pickup|6.2|2.0|3.6|2600|4WD|5967|V8|NA|300|488|5200|A4|14000|2|ext,plow,beacon|Hired by the hour to push snow onto your freshly shovelled driveway. The amber light means sorry.
GMZ|Sierruh Denial|2016|pickup|pickup|5.84|2.03|3.65|2400|4WD|6162|V8|NA|420|624|6000|A8|38000|6|crew|Like the half-ton, but with a grille you can see from orbit and seats that cool your back.
GMZ|Jimmeh|1995|suv|suv|4.6|1.72|2.72|1800|4WD|4300|V6|NA|195|353|4800|A4|2500|3||Two doors, four-wheel drive and a radio that only gets the country station.
GMZ|Vandurruh|1989|van|van|5.0|2.0|3.1|2100|RWD|5733|V8|NA|210|407|4400|A3|12000|1.5|stripes,p=1e1e24|Red stripe, black paint, and a team of soldiers of fortune in the back. Allegedly.
GMZ|Sy-Clone|1991|oddball|pickup|4.6|1.73|2.75|1600|AWD|4300|V6|T|280|475|4800|A4|35000|0.3|p=1e1e24|A turbo mini-truck that embarrassed an Italian supercar in a magazine test. Still won't shut up about it.
GMZ|You-Kon Denial|2010|suv|suv|5.13|2.01|2.95|2600|4WD|6162|V8|NA|403|565|5800|A6|17000|4||Leather, chrome and a strong belief that this is a luxury car.
GMZ|Top Kickk|2005|work_truck|boxtruck|8.0|2.4|4.6|4500|RWD|8100|V8|NA|325|610|4200|A6|28000|1.5|beacon|Medium duty, maximum attitude. Delivers furniture, mostly into the furniture.
# ---- Pontiak
Pontiak|Strato Chieftain|1958|classic|sedan|5.3|2.0|3.0|1650|RWD|4638|V8|NA|200|383|4600|A2|28000|0.8|fins,twotone|Canadian-built from one brand's bones with another brand's face. A dual citizen with chrome.
Pontiak|Parisienna|1966|classic|sedan|5.4|2.03|3.0|1700|RWD|5359|V8|NA|275|481|4800|A3|26000|0.8||Built in Oshawa for Canadians who wanted a bit of Paris and a lot of V8.
Pontiak|G.T.Whoa|1967|muscle|muscle|5.1|1.9|2.92|1600|RWD|6555|V8|NA|360|597|5100|M4|88000|0.6|scoop|The goat. It started all of this, and it's still not sorry.
Pontiak|Fireburd Trans-Ammo|1979|muscle|muscle|5.0|1.86|2.74|1650|RWD|6555|V8|NA|220|434|4400|A3|38000|1|ttops,scoop|A screaming chicken on the hood and a sheriff in the mirror. East bound and down.
Pontiak|Fireburd|1987|pony|coupe|4.85|1.84|2.56|1500|RWD|5001|V8|NA|170|346|4500|A4|7500|1.5|popups,ttops|Pop-up lights, T-tops, and a talking dashboard that only ever says 'door ajar.'
Pontiak|Fieryo|1985|sports|wedge|4.07|1.75|2.37|1200|RWD|2471|I4|NA|92|182|5000|M4|5500|0.8|mid,popups|Mid-engine, plastic panels and a reputation for spontaneous warmth. Keep a fire extinguisher. Keep two.
Pontiak|Sunburd|1988|compact|coupe|4.5|1.68|2.57|1150|FWD|1998|I4|T|165|237|6000|M5|1800|1||A turbo badge on a compact coupe. Mostly a sticker. A little bit not.
Pontiak|Grand Ham|1999|compact|sedan|4.73|1.79|2.68|1350|FWD|3350|V6|NA|175|278|6000|A4|1500|8|spoiler|More plastic cladding than a dollar store. The intake gaskets are a subscription.
Pontiak|Grand Prize|2004|sedan|sedan|5.04|1.83|2.81|1600|FWD|3791|V6|S|260|380|5600|A4|3500|5|spoiler|Supercharged and front-wheel drive, with a head-up speedometer for reading off to the photo radar.
Pontiak|Awkteck|2003|crossover|suv|4.62|1.87|2.81|1800|AWD|3350|V6|NA|185|285|6000|A4|3500|1.5||Comes with a tent that clips onto the back. You'll need it, because nobody will give you a ride home.
Pontiak|Bonnevillain|1972|sedan|sedan|5.67|2.03|3.2|2000|RWD|7457|V8|NA|250|508|4400|A3|11000|0.8|vinyl|Seven and a half litres of land yacht, captained by a man in a short-sleeved dress shirt.
Pontiak|Acadianne|1985|economy|hatch|4.05|1.57|2.4|900|RWD|1598|I4|NA|65|108|5200|M4|1500|1||Sold only in Canada, and proud of it. Slow, honest, and parked in half the driveways in Dieppe.
Pontiak|Vybe|2005|hatch|hatch|4.37|1.78|2.6|1300|FWD|1794|I4|NA|130|170|6400|M5|3500|4||A Toyoda under a Pontiak badge. Dependable. Don't tell anyone.
Pontiak|Montannuh|2001|minivan|minivan|5.1|1.83|3.0|1800|FWD|3350|V6|NA|185|285|5600|A4|1500|4||Called itself a sport van. The sport was intake-gasket replacement.
Pontiak|Solstiss|2008|sports|roadster|4.0|1.81|2.42|1300|RWD|1998|I4|T|260|353|6300|M5|19000|0.6||Pretty roadster. Folding the top takes a degree in origami, and the trunk holds one sandwich.
# ---- Oldsmobeel
Oldsmobeel|Ninety-Ate|1959|classic|sedan|5.6|2.03|3.2|1900|RWD|6080|V8|NA|315|624|4600|A4|30000|0.5|fins|Chrome by the pound, fins by the foot, and a four-speed automatic named after a sea monster.
Oldsmobeel|Tornadoh|1967|luxury|coupe|5.36|2.03|3.02|2050|FWD|7000|V8|NA|385|644|4800|A3|26000|0.4|popups|Front-wheel drive with a seven-litre V8, in 1966. Hidden headlights, hidden genius.
Oldsmobeel|Cutless Supremo|1985|sedan|coupe|5.1|1.82|2.74|1500|RWD|5001|V8|NA|150|325|4200|A4|8000|2.5|vinyl|The most popular car in the country at one point. Specifically, in your grandparents' garage.
Oldsmobeel|Vista Crusher|1972|wagon|wagon|5.6|2.0|3.07|2000|RWD|5735|V8|NA|160|373|4200|A3|18000|0.6|wood,sunroof|Glass in the roof so the kids in the way-back can count the clouds, or the potholes, reflected.
Oldsmobeel|Seara|1993|sedan|sedan|4.83|1.76|2.62|1300|FWD|3135|V6|NA|160|251|5000|A4|1200|4||Seat cushions sculpted for a quiet life. An engine tuned for one, too.
Oldsmobeel|Alergo|2003|compact|sedan|4.75|1.78|2.72|1350|FWD|3350|V6|NA|170|271|6000|A4|1500|3||The last new model of a brand that ran out of new. It sneezes on cold mornings.
Oldsmobeel|Sillywet|1998|minivan|minivan|5.1|1.84|3.07|1800|FWD|3350|V6|NA|180|278|5600|A4|1200|2||Shaped like a cordless vacuum. Sounds like one too, at full throttle.
# ---- Buickk
Buickk|Roadmassive|1956|classic|sedan|5.4|2.0|3.1|1900|RWD|5276|V8|NA|255|475|4400|A2|35000|0.5|portholes,twotone|Portholes in the fenders and a grille that looks like it swallowed a harmonica.
Buickk|Rivieruh|1971|luxury|coupe|5.6|2.03|3.07|2050|RWD|7458|V8|NA|315|610|4400|A3|24000|0.5||The boat-tail. Drawn by someone who loved yachts and hated parallel parking.
Buickk|Grand Nashunal|1987|muscle|coupe|5.1|1.82|2.74|1600|RWD|3791|V6|T|245|481|5000|A4|48000|0.4|p=1e1e24|All black, a turbo V6, and every V8 at the drag strip handing over its lunch money.
Buickk|Le Sabot|1999|sedan|sedan|5.08|1.88|2.84|1600|FWD|3791|V6|NA|205|312|5200|A4|1500|5||The car of every retired optometrist. The V6 under the hood will outlive them all.
Buickk|Century-ish|1996|sedan|sedan|4.88|1.76|2.62|1350|FWD|3135|V6|NA|160|251|5000|A3|900|3||Beige paint, beige cloth, beige soul, and it will still be running after the heat death of the universe.
Buickk|Roadmassive Wagon|1995|wagon|wagon|5.7|2.03|2.94|2100|RWD|5733|V8|NA|260|447|5000|A4|12000|0.6|wood|A sports-car V8 in a wood-panelled whale. Dad's secret weapon at the drag strip.
Buickk|Rondayvoo|2004|crossover|suv|4.78|1.88|2.86|1850|AWD|3350|V6|NA|185|285|5200|A4|2000|2||A date with destiny. Destiny showed up in plastic cladding.
Buickk|Enclaive|2014|crossover|suv|5.1|2.0|3.02|2200|AWD|3564|V6|NA|288|366|6500|A6|17000|5||Three rows of quiet. The quietest place in the arena parking lot.
# ---- Cadillak
Cadillak|Coupe de Villain|1959|luxury|coupe|5.7|2.03|3.3|2200|RWD|6384|V8|NA|325|583|4800|A4|75000|0.4|fins,twotone|The tallest fins ever bolted to a car, with bullet tail lights. Pointy enough to count as a weapon.
Cadillak|El Dorkado|1976|luxury|coupe|5.83|2.03|3.3|2300|FWD|8194|V8|NA|190|488|4000|A3|22000|0.6|vinyl|Eight point two litres, one hundred ninety horsepower. The other horses went into the cupholders.
Cadillak|Simmeron|1983|luxury|sedan|4.5|1.68|2.57|1200|FWD|1999|I4|NA|88|150|5000|A3|1500|0.5||A compact with a luxury badge and a four-cylinder ego. Executives wept.
Cadillak|Broughamm|1990|luxury|sedan|5.6|1.93|3.07|1950|RWD|5733|V8|NA|175|407|4200|A4|6500|1.5|vinyl|The last of the long ones: landau roof, wire wheels and a trunk that fits three bodies. Of luggage.
Cadillak|Escalator|2008|luxury|suv|5.14|2.0|2.95|2600|4WD|6162|V8|NA|403|565|5800|A6|17000|4||Moves you up in the world. Takes two parking spots while it does.
Cadillak|Fleetwould Hearse|1985|oddball|wagon|6.4|2.0|3.6|2600|RWD|5735|V8|NA|155|373|4000|A4|9000|0.2|norack,p=1e1e24|Rides in the back are free. One way only.
Cadillak|CTZ-Vee|2012|luxury|sedan|4.86|1.85|2.88|1900|RWD|6162|V8|S|556|747|6200|A6|38000|0.5||The executive sedan that ate a sports car and kept its manners. Mostly.
# ---- Linkoln
Linkoln|Incontinental|1962|luxury|sedan|5.4|1.98|3.1|2300|RWD|7046|V8|NA|300|630|4600|A3|42000|0.4||Rear doors hinged at the back, so you can step out with dignity, or fall out without it.
Linkoln|Marked Five|1978|luxury|coupe|5.9|2.03|3.08|2200|RWD|6588|V8|NA|166|434|4000|A3|19000|0.6|vinyl|Opera windows, a vinyl roof and a hood longer than some people's driveways.
Linkoln|Town Carr|1995|luxury|sedan|5.56|1.98|2.98|1850|RWD|4601|V8|NA|210|373|5000|A4|3500|5||Grandpa's chariot, airport limo, funeral escort. It's seen everything, at forty-five kilometres an hour.
Linkoln|Town Carr Stretch|1998|oddball|sedan|8.3|1.98|5.0|2900|RWD|4601|V8|NA|200|373|5000|A4|9000|0.2|p=f0f0ec/1e1e24|Ten seats, a mirrored ceiling, and a prom-night smell no detailer can get out.
Linkoln|Navigatrix|2005|luxury|suv|5.23|2.0|3.02|2700|4WD|5408|V8|NA|300|495|5000|A6|8000|2||Power running boards that fold down to greet you, and fold up stuck in January.
# ---- Merkury
Merkury|Couger|1969|pony|coupe|4.9|1.82|2.82|1500|RWD|5752|V8|NA|290|522|5000|A3|30000|0.6|popups|Hidden headlights and sequential tail lamps: the pony car that wore a suit.
Merkury|Meteorite|1965|classic|sedan|5.4|2.0|3.0|1700|RWD|5000|V8|NA|200|383|4600|A3|20000|0.6||A Canada-only special, for people who wanted something nobody on the street had.
Merkury|Grand Marquee|2003|sedan|sedan|5.38|1.98|2.91|1800|RWD|4601|V8|NA|224|373|5000|A4|3000|6||A floaty V8 sedan with two speeds: fifty, and parked outside the legion hall.
Merkury|Sabel|1992|wagon|wagon|5.0|1.82|2.69|1500|FWD|3802|V6|NA|140|292|4800|A4|1200|2||A light bar across the grille. Not a police car. Please stop pulling over.
Merkury|Linx|1984|economy|hatch|4.05|1.67|2.39|950|FWD|1597|I4|NA|70|119|5500|M4|1200|0.6||A rebadged hatch with a cat's name and a dog's performance.
# ---- Dodgy
Dodgy|Coronnette|1958|classic|sedan|5.3|1.98|3.0|1650|RWD|5326|V8|NA|252|461|4600|A3|26000|0.6|fins,twotone|Push-button automatic on the dashboard. Push it, and wait.
Dodgy|Dartt|1968|compact|sedan|4.98|1.77|2.79|1300|RWD|3687|I6|NA|145|291|4400|A3|11000|1.2||The slanted six: leans over, never falls down. The body is another story.
Dodgy|Charjer|1969|muscle|muscle|5.3|1.95|2.97|1700|RWD|7206|V8|NA|375|651|5000|M4|110000|0.4|popups,stripes|Hidden headlights, a bumblebee stripe, and an urge to jump creek beds out in the county.
Dodgy|Challenjer|1970|muscle|muscle|4.86|1.95|2.79|1600|RWD|6974|V8|NA|425|664|5200|M4|130000|0.3|scoop,stripes|Shaker hood, pistol-grip shifter and a fuel gauge you can actually watch move.
Dodgy|Challenjer Hellcatt|2017|muscle|muscle|5.03|1.92|2.95|2000|RWD|6166|V8|S|707|881|6200|A8|65000|0.6|scoop|Seven hundred horsepower. The supercharger whine is how the dogs know a storm is coming.
Dodgy|Monacko|1974|sedan|sedan|5.6|2.0|3.1|2000|RWD|7212|V8|NA|230|461|4400|A3|12000|0.6|spotlight|An ex-cruiser that once jumped a drawbridge in a movie. On a mission from somebody.
Dodgy|Ommni|1985|economy|hatch|4.15|1.68|2.47|1000|FWD|2213|I4|NA|96|160|5200|M5|1500|1||Basic transportation. Some madman turbocharged a few. This is not one of those.
Dodgy|Arees|1984|compact|sedan|4.5|1.73|2.55|1100|FWD|2213|I4|NA|96|160|5200|A3|1200|1||The K-car: built a whole corporation back up, one beige sedan at a time.
Dodgy|Daytoner|1987|sports|coupe|4.62|1.75|2.47|1300|FWD|2213|I4|T|146|228|6000|M5|3000|0.8|popups|Turbo badge on the hood, pop-ups up front, louvres on the back glass. The eighties, in one shape.
Dodgy|Shaddow|1992|economy|coupe|4.37|1.71|2.46|1150|FWD|2501|V6|NA|141|231|5500|A3|900|2||A ghost of a car. It haunts the back row of every auction lot in the province.
Dodgy|Spirritt|1993|compact|sedan|4.6|1.73|2.62|1250|FWD|2501|V6|NA|141|231|5500|A4|900|2||Your teacher's car. It was boring then, too.
Dodgy|Neeon|1998|economy|sedan|4.36|1.71|2.64|1100|FWD|1996|I4|NA|132|175|6800|M5|900|6||It said 'Hi' in the ads. It says it on the driveway too, in oil, every week.
Dodgy|Wiper|1996|exotic|roadster|4.45|1.92|2.44|1550|RWD|7990|V10|NA|415|664|6000|M6|72000|0.3|stripes|Eight litres, ten cylinders, zero electronic help and side pipes that cook your calves.
Dodgy|Stealthy|1993|sports|sports|4.55|1.84|2.47|1700|AWD|2972|V6|TT|300|415|7000|M5|9000|0.5|spoiler|A rebadged twin-turbo. Every bolt-on aero bit is load-bearing, emotionally.
Dodgy|Caravann|1996|minivan|minivan|4.73|1.95|2.88|1650|FWD|3301|V6|NA|158|275|5200|A4|900|6||The automatic came with a prepaid subscription to the transmission shop.
Dodgy|Grand Caravann|2004|minivan|minivan|5.1|2.0|3.03|1950|FWD|3301|V6|NA|180|285|5600|A4|2500|12||The official car of Canadian minor hockey. The sliding door has given up three times this winter.
Dodgy|Grand Caravann|2016|minivan|minivan|5.15|2.0|3.08|2050|FWD|3604|V6|NA|283|353|6400|A6|11000|12||Stow-and-go seats, stow-and-go pride, stow-and-go hockey bags.
Dodgy|Dakotuh|2000|pickup|pickup|5.2|1.82|3.33|1900|4WD|4701|V8|NA|235|400|5200|A4|3500|4|ext|A mid-size truck with a full-size V8 and a quarter-size gas tank.
Dodgy|Durangoh|2001|suv|suv|4.9|1.82|2.95|2100|4WD|4701|V8|NA|235|400|5200|A4|2500|3||Three rows, a V8, and a front end that looks like a truck because it is one.
Dodgy|Rammcharjer|1979|offroad|offroad|4.8|2.0|2.7|2200|4WD|5900|V8|NA|180|400|4200|A3|22000|0.6|open|A full-size pickup with the bed stolen and a roof made of maybe.
Dodgy|A-Hunnert|1965|oddball|van|4.3|1.8|2.29|1450|RWD|3687|I6|NA|145|291|4400|M3|26000|0.3|twotone|Engine between the front seats, the wheelbase of a shopping cart, and the steering of a ship.
Dodgy|Sprintur|2008|work_truck|van|5.9|2.0|3.66|2400|RWD|2987|V6|TD|154|330|4200|A5|15000|3|cargo|A German diesel delivery van wearing a local badge. The courier's coffee cup holder.
Dodgy|Calibrr|2008|compact|hatch|4.42|1.75|2.64|1350|FWD|1998|I4|NA|158|190|6500|CVT|3500|4||A wagon-hatch-thing with a cooler in the glovebox, for keeping your disappointment chilled.
Dodgy|Journeyman|2012|crossover|suv|4.9|1.83|2.89|1850|FWD|2360|I4|NA|173|225|6500|A4|7000|7||Seven seats, four cylinders, and a long, long trip to a hundred.
# ---- Plymooth
Plymooth|Furry|1958|classic|sedan|5.3|1.98|3.0|1650|RWD|5211|V8|NA|290|473|4800|A3|60000|0.3|fins,p=c83c3c/e8d07a/f0e6c8|It has a mind of its own. Don't leave it in the garage overnight. Don't let it near your girlfriend.
Plymooth|Valliant|1966|compact|sedan|4.7|1.79|2.69|1250|RWD|2786|I6|NA|145|291|4400|A3|9500|0.8||Built in Windsor for Canadians who wanted an honest car with a slanted engine and a straight answer.
Plymooth|Road Rooner|1969|muscle|muscle|5.1|1.95|2.95|1650|RWD|6276|V8|NA|335|576|5200|M4|72000|0.4|scoop|The horn goes meep meep. The coyote never stood a chance.
Plymooth|Cudda|1970|muscle|muscle|4.74|1.89|2.74|1600|RWD|7210|V8|NA|425|664|5000|M4|180000|0.2|scoop,stripes|The fish with a monster heart. Insurance companies still flinch at the name.
Plymooth|Superburd|1970|muscle|muscle|5.6|1.95|2.95|1750|RWD|7210|V8|NA|375|651|5000|M4|220000|0.1|wing,popups|A wing two feet tall and a nose cone like a beak. Built for the oval, legal for groceries.
Plymooth|Horizonn|1983|economy|hatch|4.15|1.68|2.47|1000|FWD|1714|I4|NA|63|113|5200|M4|1200|0.8||Imported engine, local everything else. Nothing on the horizon but the next repair.
Plymooth|Voyajer|1987|minivan|minivan|4.5|1.75|2.84|1450|FWD|2555|I4|NA|104|190|5000|A3|2200|1.2|wood|The original magic wagon. Wood-grain sides and dog-hair upholstery as standard.
Plymooth|Prowlur|2001|oddball|roadster|4.2|1.94|2.9|1300|RWD|3518|V6|NA|253|346|6400|A4|38000|0.2|p=6a2a6a|A hot rod from the factory, with a V6 and an automatic. The flames are all on the inside.
Plymooth|Caravella|1985|sedan|sedan|4.6|1.73|2.62|1150|FWD|2213|I4|NA|96|160|5200|A3|1100|0.6||A Canada-only name on a K-car. Basically a souvenir with a carburetor.
# ---- Chryslur
Chryslur|New Yorkie|1960|luxury|sedan|5.6|2.03|3.2|2000|RWD|6768|V8|NA|350|637|4600|A3|30000|0.4|fins|A small dog's name on a very large car.
Chryslur|Cordobuh|1976|luxury|coupe|5.47|1.97|2.93|1850|RWD|5899|V8|NA|175|380|4000|A3|9000|0.6|vinyl|Seats in fine Corinthian vinyl. The salesman insisted it was leather.
Chryslur|Le Barren|1990|sedan|roadster|4.68|1.74|2.54|1350|FWD|2972|V6|NA|141|233|5500|A4|2000|2||For people who want to be seen at the yacht club, and leave before the boat goes out.
Chryslur|PT Crusher|2005|compact|hatch|4.29|1.7|2.62|1400|FWD|2429|I4|NA|150|224|6000|A4|2500|5|wood|A thirties hot rod shape with a minivan's insides. Some have wood. All have regret.
Chryslur|Three Hunnert See|2009|sedan|sedan|5.0|1.88|3.05|1900|RWD|5654|V8|NA|360|529|5800|A5|8000|6||A gangster-grille sedan with a bass line that rattles every piece of plastic in it.
Chryslur|Pacifickuh|2018|minivan|minivan|5.17|2.02|3.09|2000|FWD|3604|V6|NA|287|355|6400|A9|28000|5||The minivan, made almost cool. Almost.
# ---- Jepp
Jepp|See-Jay Five|1972|offroad|offroad|3.6|1.72|2.08|1250|4WD|4228|I6|NA|100|285|4000|M3|25000|0.6|open|Doors are optional, the roof is optional, getting wet is not.
Jepp|Wagonear|1987|suv|suv|4.7|1.9|2.76|2100|4WD|5899|V8|NA|144|380|4000|A3|42000|0.6|wood,rack|The original luxury four-by-four: wood on the sides, a V8 up front and rust in the middle.
Jepp|Cherokay|1999|suv|suv|4.24|1.76|2.58|1550|4WD|3964|I6|NA|190|305|4800|A4|5000|6||The straight-six will run forever. The rear leaf springs already saw forever.
Jepp|Wranglur|1995|offroad|offroad|3.9|1.69|2.37|1550|4WD|3964|I6|NA|181|301|5000|M5|9000|3|open|The wave. Drive one and you will be waved at. You must wave back. These are the rules.
Jepp|Wranglur Unlimitless|2014|offroad|offroad|4.7|1.87|2.95|2050|4WD|3604|V6|NA|285|353|6400|A5|28000|5||Four doors, removable top, removable doors, removable resale anxiety.
Jepp|Grand Cherokay|2006|suv|suv|4.74|1.87|2.78|2100|4WD|5654|V8|NA|326|500|5800|A5|7500|7||A mall crawler that could actually climb a mountain. Nobody has ever asked it to.
Jepp|Commanch|1988|pickup|pickup|4.9|1.76|3.0|1500|4WD|3964|I6|NA|177|305|4800|M5|9000|0.4||A pickup made from the front half of a sport ute. The back half is a bed. Good plan.
Jepp|Compost|2011|crossover|suv|4.45|1.81|2.63|1500|FWD|2360|I4|NA|172|224|6400|CVT|5000|4||It points north, technically. It also points at the dealership a lot.
# ---- Ramm
Ramm|Fifteen Hunnert|2014|pickup|pickup|5.82|2.02|3.57|2400|4WD|5654|V8|NA|395|556|5800|A8|26000|10|crew|Coil springs out back, a dial for a shifter and a V8 that wakes the whole street at five in the morning.
Ramm|Thirty-Five Hunnert|2016|hd_pickup|pickup|6.4|2.03|4.1|3500|4WD|6690|I6|TD|385|1180|3200|A6|46000|3|crew,dually|An inline-six diesel with an industrial cough. Tows the trailer, the boat, and the truck that couldn't.
Ramm|Promastur|2017|van|van|6.0|2.1|3.45|2300|FWD|3604|V6|NA|280|353|6400|A6|25000|4|cargo|A front-wheel-drive delivery van with a floor so low you can roll the parcels in.
# ---- Rambla
Rambla|Americano|1963|compact|sedan|4.5|1.78|2.67|1150|RWD|3200|I6|NA|125|244|4400|M3|9000|0.6||Thrift on four wheels. The seats fold flat into a bed, which was a selling point and a scandal.
Rambla|Gremlyn|1974|economy|hatch|4.1|1.8|2.44|1250|RWD|3802|I6|NA|100|251|4200|M3|9000|0.6|stripes|Chopped off at the back like it ran out of car. It did. Fun, though.
Rambla|Pacemaker|1977|oddball|hatch|4.4|1.96|2.55|1450|RWD|4228|I6|NA|110|278|4200|A3|9000|0.3|wood|A fishbowl on wheels with a passenger door longer than the driver's. The future, briefly.
Rambla|Javelinn|1971|pony|coupe|4.9|1.88|2.79|1500|RWD|6573|V8|NA|330|583|5000|M4|38000|0.3|stripes|The forgotten pony car. It remembers you, though.
Rambla|Eagel|1983|wagon|wagon|4.6|1.83|2.78|1500|4WD|4228|I6|NA|110|285|4200|A3|9000|0.6|wood|A four-wheel-drive station wagon with wood sides, a decade before crossovers had a name. Prophets are never thanked.
# ---- the odd domestic ones
Studebakker|Hawkk|1957|classic|coupe|5.1|1.8|3.06|1550|RWD|4736|V8|NA|275|451|4600|M3|38000|0.3|fins|A European-looking coupe from the middle of America. Pretty didn't pay the bills.
Studebakker|Larkk|1964|compact|sedan|4.6|1.82|2.76|1350|RWD|2779|I6|NA|112|209|4400|M3|10000|0.4||Built in Hamilton, Ontario, until the money ran out. The last one is in a museum. This one is in a field.
Studebakker|Avantee|1963|sports|coupe|4.9|1.78|2.75|1500|RWD|4736|V8|S|290|441|5200|M4|45000|0.2||Fibreglass, a supercharger and no grille. Still looks like the future, just a different one.
Internashnal|Scowt|1975|offroad|offroad|4.2|1.78|2.54|1700|4WD|5047|V8|NA|155|380|4000|M4|30000|0.4||A tractor company made a sport ute before anyone knew what that was. The rust knew.
Internashnal|Travelalot|1969|suv|suv|5.2|2.0|3.0|2100|4WD|5277|V8|NA|196|420|4200|A3|28000|0.3||A wagon made by a combine-harvester company. Nine seats, three gears, and every one of them is low.
Hummor|Aitch-Won|1996|offroad|offroad|4.7|2.2|3.3|3400|4WD|6500|V8|TD|190|583|3400|A4|110000|0.15||Military grade. Fits in a parking spot the way an elephant fits in a phone booth.
Hummor|Aitch-Too|2005|suv|offroad|4.82|2.06|3.12|2900|4WD|5967|V8|NA|325|495|5200|A4|17000|1.5|rack|A hockey-dad tank. Twenty litres per hundred kilometres, downhill.
Saturne|Ess-Ell Won|1995|economy|sedan|4.5|1.69|2.6|1050|FWD|1901|I4|NA|100|155|6000|M5|900|3||Dent-proof plastic doors on a car that will never be worth fixing the dents on anyway.
Saturne|Eye-On|2005|compact|sedan|4.69|1.71|2.62|1250|FWD|2189|I4|NA|140|197|6500|A4|1000|3||A speedometer in the middle of the dash and plastic panels that never dent. Never been worth denting.
Saturne|Vuew|2004|crossover|suv|4.6|1.82|2.7|1600|FWD|2189|I4|NA|143|205|6000|CVT|1500|3||When the CVT dies, the plastic panels will live on without it, forever.
Geoh|Metroh|1994|economy|hatch|3.8|1.59|2.36|720|FWD|993|I3|NA|55|79|6000|M5|900|2||Three cylinders, a lunchbox for a crumple zone and the aerodynamics of a sneeze.
Geoh|Trakker|1993|offroad|offroad|3.6|1.63|2.2|1100|4WD|1590|I4|NA|80|128|6000|M5|3500|1.5|open|A tiny four-by-four with a soft top that whistles on the highway and the heart of a house cat.
Geoh|Prysm|1997|compact|sedan|4.36|1.69|2.47|1100|FWD|1587|I4|NA|105|145|6400|A3|900|1.5||A Corolly in disguise. It will outlive the disguise.
Tesler|Model Ess|2015|luxury|sedan|4.97|1.96|2.96|2100|RWD|0|E1|E|380|440|14000|E1|45000|2||No engine noise, no gearbox, and an over-the-air update that added a whoopee-cushion mode.
Tesler|Roadstur|2010|exotic|roadster|3.95|1.85|2.35|1235|RWD|0|E1|E|288|370|14000|E1|90000|0.2|mid|A tiny British-bodied roadster full of laptop batteries. Quietly very fast. Loudly very expensive.
Deloreon|DMZ-Twelve|1981|oddball|sports|4.27|1.99|2.41|1230|RWD|2849|V6|NA|130|208|5500|M5|65000|0.2|rear,p=b8bcc0|Stainless steel, gull-wing doors and a flux something. It doesn't hit eighty-eight miles an hour very often.
Bricklynn|Ess-Vee Won|1975|oddball|wedge|4.5|1.8|2.44|1600|RWD|5899|V8|NA|175|386|4400|A3|38000|0.2|popups,p=ff7a1a/3a8a3a/c83c3c/f0d040|Built in Saint John. Gull-wing doors that need a pump, acrylic panels in safety colours, and a government cheque.
Chequer|Marathone|1978|oddball|sedan|5.2|2.0|3.07|1800|RWD|4999|V8|NA|155|339|4200|A3|18000|0.3|topper,p=f0d040|A taxi built like a bank vault. The back seat is the size of a bachelor apartment.
Grumpman|Ell-Ell-Vee|1995|oddball|van|4.4|1.98|2.67|1350|RWD|2471|I4|NA|90|180|4800|A3|9000|0.3|p=e8e8e8|Right-hand drive, a sliding door, no air conditioning. Delivers bills and catches fire with equal enthusiasm.
Asunna|Sunrunnur|1994|offroad|offroad|4.15|1.7|2.48|1200|4WD|1590|I4|NA|95|133|6000|M5|2500|0.4||A brand that existed for three years, only in Canada. Name it at trivia night and win.
Shelbee|Kobrah|1965|exotic|roadster|3.96|1.73|2.29|1070|RWD|6997|V8|NA|425|651|6000|M4|1500000|0.05|stripes,p=2c4a8a/c83c3c/e8e4dc|A British roadster with an American heart transplant. The patient survived. The passengers, sometimes not.
De Tomato|Panterruh|1972|exotic|wedge|4.27|1.83|2.51|1420|RWD|5763|V8|NA|330|441|6000|M5|180000|0.1|mid,popups|Italian body, American V8, and a cooling system designed by optimists.
# ---- Toyoda
Toyoda|Corolly|1975|economy|sedan|4.0|1.57|2.37|850|RWD|1166|I4|NA|55|86|6000|M4|5000|0.8||A Japanese economy car in a land of V8s. Everybody laughed. It outlived everybody.
Toyoda|Corolly|1988|economy|sedan|4.2|1.66|2.43|950|FWD|1587|I4|NA|90|135|6200|A3|1500|3||Will not die. Has been tried.
Toyoda|Corolly|2003|compact|sedan|4.53|1.7|2.6|1150|FWD|1794|I4|NA|130|170|6400|A4|3500|14||The most rational car ever made. Your mother approves. That's the problem.
Toyoda|Corolly|2017|compact|sedan|4.65|1.78|2.7|1290|FWD|1798|I4|NA|132|173|6400|CVT|14000|14||Every second car in the hospital parking lot. Will still be there after they rebuild the hospital.
Toyoda|Corolly Drifto|1986|jdm|coupe|4.2|1.63|2.4|950|RWD|1587|I4|NA|112|131|7600|M5|18000|0.6|popups|Pop-up lamps, a twin-cam four that sings, and a faint smell of tofu from the mountain deliveries.
Toyoda|Starlette|1983|economy|hatch|3.7|1.6|2.3|780|RWD|1290|I4|NA|58|94|6000|M4|3500|0.4||Rear-wheel drive and tiny. Rallied in sand, rusted in salt.
Toyoda|Celliko|1978|coupe|coupe|4.4|1.64|2.5|1100|RWD|2189|I4|NA|95|165|5400|M5|9000|0.4||Liftback styling borrowed from a pony car, reliability borrowed from a refrigerator.
Toyoda|Celliko Rally-Four|1990|rally|hatch|4.4|1.71|2.53|1450|AWD|1998|I4|T|200|275|6800|M5|14000|0.4|popups,scoop|Rally-bred all-wheel drive and a turbo that whistles through the hood scoop.
Toyoda|Supreem Twin-Turbo|1995|jdm|coupe|4.52|1.81|2.55|1570|RWD|2997|I6|TT|320|427|6800|M6|95000|0.3|wing|The straight-six tuners take to a thousand horsepower in somebody's garage with a borrowed welder.
Toyoda|Cressiduh|1990|sedan|sedan|4.8|1.72|2.78|1450|RWD|2954|I6|NA|190|251|6000|A4|3500|0.6||A luxury sedan before the luxury badge. Rear-wheel drive, straight-six. The drift kids know.
Toyoda|Chasser|1998|jdm|sedan|4.72|1.75|2.73|1500|RWD|2491|I6|T|276|378|7000|M5|28000|0.15||Right-hand drive, imported last year, already sideways in every video on the internet.
Toyoda|Turtle|1984|wagon|wagon|4.2|1.61|2.43|1000|4WD|1452|I4|NA|62|102|5600|M6|4000|0.4||A tall wagon with on-demand four-wheel drive and a gear called extra low. It gets there. Eventually.
Toyoda|Land Crusher|1978|offroad|offroad|4.0|1.67|2.29|1600|4WD|4230|I6|NA|125|285|3600|M4|38000|0.3||Driven across every desert on Earth. Driven across the curling club parking lot, today.
Toyoda|Land Crusher|2010|suv|suv|4.95|1.97|2.85|2700|4WD|5663|V8|NA|381|544|5600|A6|45000|1.5||Will survive the apocalypse. Will also be stolen during it.
Toyoda|Hi-Lucks|1985|pickup|pickup|4.69|1.69|2.62|1300|4WD|2366|I4|NA|103|185|4800|M5|9000|1||Indestructible. A TV show tried. They put it on a roof and it drove off.
Toyoda|Tacomah|2005|pickup|pickup|5.29|1.9|3.24|1850|4WD|3956|V6|NA|245|383|5200|A5|13000|8|ext|The frame was recalled for rust. The rest of it will outlive us all.
Toyoda|Tundruh|2016|pickup|pickup|5.81|2.03|3.7|2500|4WD|5663|V8|NA|381|544|5600|A6|31000|6|crew|A full-size truck that sounds like farm machinery and lasts like it, too.
Toyoda|Previous|1993|minivan|minivan|4.75|1.8|2.86|1700|RWD|2438|I4|S|158|278|5600|A4|4500|1|mid,sunroof|An egg on wheels with the engine under the floor. Mid-engined: technically, a supercar.
Toyoda|Siennuh|2012|minivan|minivan|5.09|1.99|3.03|2000|FWD|3456|V6|NA|266|333|6200|A6|17000|9||Swagger wagon. Somebody said that in an ad once, and now every dad believes it.
Toyoda|Rave-Four|2001|crossover|suv|4.2|1.74|2.49|1350|AWD|1998|I4|NA|148|192|6000|A4|3500|6|spare|The cute-ute that invented the whole category. Spare on the back door, cupholders in the dash.
Toyoda|Rave-Four|2017|crossover|suv|4.6|1.85|2.66|1600|AWD|2494|I4|NA|176|233|6000|A6|23000|12||The default answer. To every question. Ever.
Toyoda|Pious|2010|compact|hatch|4.46|1.75|2.7|1380|FWD|1798|I4|NA|134|142|5200|CVT|9000|8||Hybrid halo, smug aura included. Sneaks up silently on pedestrians in parking lots.
Toyoda|Camree|1997|sedan|sedan|4.81|1.79|2.67|1400|FWD|2164|I4|NA|133|199|5500|A4|2000|12||Beige. Not the colour: the personality. Runs forever anyway.
Toyoda|Camree|2015|sedan|sedan|4.85|1.82|2.78|1500|FWD|2494|I4|NA|178|231|6000|A6|15000|14||Air conditioning that could freeze a lake and a radio that only knows easy listening.
Toyoda|Mister Two|1991|sports|wedge|4.17|1.7|2.4|1250|RWD|1998|I4|T|200|271|7000|M5|14000|0.6|mid|Mid-engine, a turbo, and lift-off oversteer. Snap goes the tail, snap goes the wallet.
Toyoda|Echoh|2002|economy|sedan|4.15|1.66|2.37|920|FWD|1497|I4|NA|108|142|6000|M5|1500|4||Tall and narrow, with the gauges in the middle of the dash so the passenger can nag.
Toyoda|Matrixx|2005|hatch|hatch|4.35|1.76|2.6|1250|FWD|1794|I4|NA|130|170|6400|A4|3500|6||A Corolly wagon in a leather jacket. Nobody took the red pill.
Toyoda|Eff-Jay Crusher|2008|offroad|offroad|4.67|1.9|2.69|2000|4WD|3956|V6|NA|239|377|5600|A5|20000|1.5||A retro box with a white roof, rear-hinged back doors and a blind spot the size of the Maritimes.
# ---- Datsum / Nissun
Datsum|Five-Ten|1970|compact|sedan|4.12|1.56|2.42|930|RWD|1595|I4|NA|96|135|6500|M4|16000|0.4||The poor man's German sports sedan: independent rear end, and a cult that won't let it die.
Datsum|Two-Forty Zed|1972|sports|sports|4.14|1.63|2.3|1050|RWD|2393|I6|NA|150|198|6500|M4|42000|0.4||Long hood, short tail, straight six. It's pronounced zed around here, and don't argue.
Datsum|Bee-Two-Ten|1978|economy|hatch|4.0|1.56|2.34|850|RWD|1397|I4|NA|70|105|6000|M5|5000|0.4||Ran on fumes and promises through the gas crisis. Still does. Mostly fumes.
Datsum|Two-Eighty Zed-X|1982|sports|sports|4.42|1.69|2.32|1300|RWD|2753|I6|T|180|275|5600|M5|14000|0.4|ttops|Turbo, T-tops, and a talking dashboard that sounds like a disappointed robot.
Nissun|Three Hundred Zed-X|1990|sports|sports|4.53|1.8|2.45|1580|RWD|2960|V6|TT|300|383|7000|M5|22000|0.4|ttops|A supercar in a cardigan. The engine bay is so full you change the spark plugs by prayer.
Nissun|Two-Forty Ess-X|1993|jdm|coupe|4.52|1.69|2.47|1250|RWD|2389|I4|NA|155|217|6400|M5|9000|1.2|popups|The fastback with pop-ups. The third owner will swap in an engine from overseas.
Nissun|Skylion Gee-Tee-Arr|1991|jdm|coupe|4.55|1.76|2.62|1430|AWD|2568|I6|TT|276|353|8000|M5|72000|0.3|wing|The monster. Imported right-hand drive the day it turned twenty-five, as a birthday present to itself.
Nissun|Stagehand|1998|jdm|wagon|4.8|1.76|2.72|1550|AWD|2498|I6|T|276|363|7000|A4|22000|0.08||A turbo straight-six under a family wagon roof rack. The ultimate sleeper, imported.
Nissun|Sentruh|1995|economy|sedan|4.32|1.69|2.54|1050|FWD|1597|I4|NA|115|146|6500|M5|1200|8||Point A to point B with zero drama. Point C is the scrapyard, twenty years later.
Nissun|Sentruh|2016|compact|sedan|4.63|1.76|2.7|1300|FWD|1798|I4|NA|130|174|6400|CVT|11000|10||A rental car's rental car. The CVT sounds like a hair dryer climbing a hill.
Nissun|Alteema|2007|sedan|sedan|4.82|1.8|2.78|1450|FWD|2488|I4|NA|175|244|6000|CVT|4000|12||Driven like it's stolen by every owner. Turn signals optional, per the unofficial owner's manual.
Nissun|Maximuh|1994|sedan|sedan|4.77|1.77|2.7|1450|FWD|2960|V6|NA|190|258|6500|M5|2000|3||The four-door sports car, said the ads. Four doors: accurate.
Nissun|Pathfindurr|1996|suv|suv|4.53|1.84|2.7|1850|4WD|3275|V6|NA|168|265|4800|A4|3000|3||A real body-on-frame trucklet with carpet. The rear wiper sings.
Nissun|Hardbod|1993|pickup|pickup|4.82|1.69|2.95|1400|RWD|2389|I4|NA|134|210|5600|M5|3500|3||The compact truck that holds up the whole lobster industry on the Northumberland Strait.
Nissun|Titann|2006|pickup|pickup|5.7|2.02|3.55|2400|4WD|5552|V8|NA|305|522|5600|A5|9000|3|crew|A full-size truck from an unlikely country. Never quite invited to the party.
Nissun|Rouge|2015|crossover|suv|4.69|1.84|2.71|1600|AWD|2488|I4|NA|170|237|6000|CVT|17000|12||Named like the lipstick. Behaves like a sensible shoe.
Nissun|Mikra|2015|economy|hatch|3.83|1.67|2.45|1050|FWD|1598|I4|NA|109|146|6000|M5|7000|6||The cheapest new car in the country. It has its own racing series. Somehow.
Nissun|Leef|2013|compact|hatch|4.45|1.77|2.7|1500|FWD|0|E1|E|107|254|10000|E1|9000|3||Silent, slow and never far from a plug. The battery's memory is worse than Grandpa's.
Nissun|Kyoob|2010|compact|kei|3.98|1.69|2.53|1250|FWD|1798|I4|NA|122|172|6400|CVT|6000|1.5||A lopsided back window and a shag dash mat: a toaster that got serious about life.
Nissun|Figarro|1991|oddball|roadster|3.74|1.63|2.3|810|FWD|987|I4|T|76|106|6000|A3|18000|0.2|chrome,round,p=7fb8b0/e8d07a/a89a7a|A brand-new retro car in 1991, sold by lottery. Now driven by your hippest aunt.
# ---- Hondo / Acurra
Hondo|En-Six-Hunnert|1971|kei|kei|3.0|1.3|2.0|500|FWD|598|I2|NA|36|45|9000|M4|11000|0.3||A motorcycle engine in a shoebox. Revs to nine grand. You will need all of them.
Hondo|Civil|1977|economy|hatch|3.68|1.5|2.2|720|FWD|1488|I4|NA|60|105|5500|M4|5000|0.6||Rust-friendly sheet metal and fuel economy that made the big three very nervous.
Hondo|Civil|1992|economy|hatch|4.07|1.69|2.57|980|FWD|1493|I4|NA|102|133|6800|M5|2500|4||Every tuner's first. The exhaust is louder than the engine. The wing is taller than the driver.
Hondo|Civil Ess-Eye|1999|hot_hatch|coupe|4.45|1.7|2.62|1150|FWD|1595|I4|NA|160|151|8200|M5|7500|1.5|spoiler|Revs to eight thousand. Somewhere around six, the cams switch over, yo.
Hondo|Civil|2008|compact|sedan|4.5|1.75|2.7|1250|FWD|1799|I4|NA|140|174|6800|A5|6000|14||A two-tier dash puts the speed right in your eyeline, for all the good it does.
Hondo|Civil Type-Arr|2017|hot_hatch|hatch|4.56|1.88|2.7|1380|FWD|1996|I4|T|306|400|7000|M6|42000|0.8|wing|A wing, three tailpipes, and the shape of a toy robot that gave up halfway through transforming.
Hondo|C-Arr-Exx|1988|hatch|hatch|3.75|1.68|2.3|860|FWD|1590|I4|NA|105|135|6800|M5|8000|0.6||A two-seat lunchbox that zips. Miles per gallon or smiles per gallon: pick one.
Hondo|Accordion|1985|sedan|sedan|4.5|1.69|2.45|1050|FWD|1829|I4|NA|86|136|5600|M5|1500|1.5|popups|Pop-up headlights on a family sedan. The eighties were a different time.
Hondo|Accordion|2004|sedan|sedan|4.81|1.82|2.74|1450|FWD|2354|I4|NA|160|218|6800|A5|4000|12||The automatic goes bad the year the warranty runs out. Everything else is forever.
Hondo|Prelewd|1990|coupe|coupe|4.46|1.71|2.57|1150|FWD|2056|I4|NA|135|176|6800|M5|3500|0.8|popups|Four-wheel steering: the back wheels turn too. Nobody you tell will believe you.
Hondo|Oddyssey|2008|minivan|minivan|5.1|1.96|3.0|2000|FWD|3471|V6|NA|244|326|6500|A5|7000|10||A minivan that actually handles. The kids won't notice. You will.
Hondo|See-Arr-Vee|2003|crossover|suv|4.54|1.78|2.62|1500|AWD|2354|I4|NA|160|219|6500|A4|4500|10|spare|A picnic table in the trunk floor, a spare on the tailgate and a fully adult blandness.
Hondo|Fitt|2009|economy|hatch|4.1|1.7|2.5|1100|FWD|1497|I4|NA|117|144|6600|M5|5500|8||It fits a couch. A bicycle. Your whole band. Nobody knows how.
Hondo|Elemental|2005|crossover|kei|4.3|1.82|2.57|1600|AWD|2354|I4|NA|160|218|6500|A4|6500|1.5|rack|A toaster built for surfers, with rubber floors you can hose out. Inland surfers.
Hondo|Ridgelyne|2017|pickup|pickup|5.33|2.0|3.18|2000|AWD|3471|V6|NA|280|355|6500|A6|30000|3|crew|A truck with a trunk in the bed. Real truck guys hate it. Real truck guys also borrow it to move.
Hondo|Ess-Two-Grand|2002|sports|roadster|4.13|1.75|2.4|1250|RWD|1997|I4|NA|240|208|9000|M6|24000|0.6||A nine-thousand-rpm redline. Torque is something that happens to other people.
Hondo|Beet|1992|kei|roadster|3.3|1.4|2.28|760|RWD|656|I3|NA|63|60|8500|M5|11000|0.15|mid|A mid-engine kei roadster: a Ferraree for people who live in a shoebox.
Hondo|Actee|1995|kei|pickup|3.3|1.4|1.9|700|RWD|656|I3|NA|45|58|7000|M5|7500|0.5|cabover|A kei truck: tiny, mid-engined, and better at farm work than most farmhands.
Acurra|In-Tegruh|1994|jdm|coupe|4.38|1.71|2.57|1170|FWD|1797|I4|NA|170|174|8000|M5|9000|0.8|wing|The one everybody tries to steal. The one with the wing is already gone.
Acurra|Legendary|1991|luxury|sedan|4.94|1.81|2.83|1500|FWD|3206|V6|NA|200|284|6500|A4|2500|0.6||Convinced everyone a Japanese brand could do luxury. Now it does doorstop.
Acurra|En-Ess-Eks|1991|exotic|wedge|4.4|1.81|2.53|1370|RWD|2977|V6|NA|270|285|8000|M5|95000|0.1|mid,popups|Developed with a world champion: an aluminum body, pop-up lamps and a cabin made for normal humans.
Acurra|Ee-Ell|2003|compact|sedan|4.45|1.72|2.62|1200|FWD|1668|I4|NA|127|154|6500|A4|2000|4||Made in Ontario, sold only in Canada: basically a Civil with leather and a smug badge.
Acurra|Tee-Ell-Ish|2004|sedan|sedan|4.73|1.83|2.74|1550|FWD|3210|V6|NA|270|322|6600|A5|5000|5||A dentist's daily. Clean, quick, and stuck on the same jazz station forever.
Acurra|Em-Dee-Eks|2007|crossover|suv|4.85|2.0|2.75|2050|AWD|3664|V6|NA|300|373|6300|A6|11000|5||Three rows and a buttoned-up face, parked outside a private school.
# ---- Mazduh
Mazduh|Roto-Three|1973|jdm|coupe|4.15|1.6|2.31|950|RWD|1146|R2|NA|110|135|7000|M4|25000|0.2||A rotary in a little coupe. Hums like a hive of angry bees. Drinks like a sailor.
Mazduh|Roto-Seven|1985|sports|sports|4.32|1.67|2.42|1100|RWD|1146|R2|NA|135|180|7000|M5|12000|0.6|popups|A rotary engine and pop-ups: the Japanese sports car in its purest, thirstiest form.
Mazduh|Roto-Seven|1993|jdm|sports|4.29|1.76|2.42|1300|RWD|1308|R2|TT|255|294|8000|M5|38000|0.3|popups,wing|Sequential twin turbos, perfect balance, and apex seals held together by hope and premium fuel.
Mazduh|Roto-Ate|2005|sports|coupe|4.43|1.77|2.7|1380|RWD|1308|R2|NA|238|211|9000|M6|8000|1|spoiler|Little back doors that open backwards and an engine that eats oil for breakfast.
Mazduh|Cosmoh|1991|jdm|coupe|4.82|1.8|2.75|1500|RWD|1962|R3|TT|280|402|7000|A4|35000|0.03|digidash|A three-rotor grand tourer with a touchscreen in 1990. The screen died first. Then the rotors.
Mazduh|Myata|1990|sports|roadster|3.95|1.68|2.27|980|RWD|1597|I4|NA|116|136|7000|M5|8000|2|popups|Pop-up headlights. Always the answer. To any question.
Mazduh|Myata|2016|sports|roadster|3.92|1.73|2.31|1060|RWD|1998|I4|NA|155|200|6800|M6|25000|1.5||Still the answer. The question has gotten more expensive.
Mazduh|Protejay|2001|compact|sedan|4.43|1.7|2.61|1150|FWD|1991|I4|NA|130|183|6500|M5|1500|5||Fun to drive, said the ads. Mostly true. The rear quarter panels are mostly rust holes by now.
Mazduh|Six-Two-Sicks|1988|sedan|sedan|4.52|1.69|2.58|1200|FWD|1998|I4|NA|110|160|6000|M5|1200|2||The family car that was quietly fun. Quietly rusting, too.
Mazduh|Emm-Pee-Vee|1992|minivan|minivan|4.66|1.82|2.8|1700|RWD|2954|V6|NA|155|228|5500|A4|2000|1||Rear-wheel drive, a swing-out back door, and a V6 that groans like a dad standing up.
Mazduh|Bee-Two-Grand|1986|pickup|pickup|4.6|1.66|2.79|1200|RWD|1998|I4|NA|85|150|5000|M5|3500|1.5||A rust-coloured compact truck. Originally another colour. Nobody living remembers which.
Mazduh|Tree|2014|compact|hatch|4.46|1.8|2.7|1300|FWD|1998|I4|NA|155|200|6500|M6|12000|10||A sensible hatch with a grin. Say the model name in a Maritime accent and it's the number three.
Mazduh|Az-Won|1993|kei|wedge|3.3|1.4|2.24|720|RWD|657|I3|T|64|85|7500|M5|28000|0.1|mid|Gull-wing doors on a car the size of a shopping cart, with a turbo three. Glorious nonsense.
Mazduh|See-Ex-Five|2017|crossover|suv|4.55|1.84|2.7|1600|AWD|2488|I4|NA|187|252|6200|A6|25000|10||The crossover car people buy when they're secretly still car people.
# ---- Subaroo
Subaroo|Three-Sixty|1968|kei|bubble|3.0|1.3|1.8|410|RWD|356|I2|2S|25|35|5500|M3|18000|0.1|rear|Ladybug-shaped, rear-engined, two-stroke. Crash rating: please don't.
Subaroo|Bratt|1980|oddball|pickup|4.6|1.6|2.46|1050|4WD|1595|F4|NA|67|111|5200|M4|12000|0.2|ute|Two seats bolted in the bed, facing backward, to dodge a tariff. Genius or crime? Both.
Subaroo|Gee-Ell Waggin|1987|wagon|wagon|4.45|1.66|2.47|1100|4WD|1781|F4|NA|90|138|5600|M5|2500|0.8||The original rural Maritime wagon. Starts at forty below. Never stops rusting.
Subaroo|Ex-Tee|1986|oddball|wedge|4.5|1.69|2.47|1200|4WD|1781|F4|T|112|182|6000|M5|5500|0.15|digidash,popups|A wedge with a steering wheel shaped like a jet yoke and a digital dash that cost more than the engine.
Subaroo|Justee|1989|economy|hatch|3.6|1.54|2.29|780|4WD|1189|I3|NA|66|95|5600|M5|1500|0.3||A three-cylinder four-wheel-drive hatch. Will climb a snowbank. Will not climb a hill.
Subaroo|Legacee|2000|sedan|wagon|4.68|1.7|2.65|1450|AWD|2457|F4|NA|165|224|6000|A4|2500|5||Head gaskets that come pre-weeping, and all-wheel drive to get it to the shop through the snow.
Subaroo|Imprezza Wrecks|2004|rally|sedan|4.42|1.74|2.53|1450|AWD|2457|F4|T|300|407|7000|M6|18000|0.8|scoop,wing,p=2a4a8a|Gold wheels, a hood scoop, and a wing older than the tree it's parked under.
Subaroo|Bahaha|2004|oddball|pickup|4.9|1.78|2.65|1550|AWD|2457|F4|T|210|319|6000|A4|9000|0.2|ute,rack|Half wagon, half truck, entirely confusing. The bed reaches into the cabin through a hole in the back seat.
Subaroo|Outbak|2012|wagon|wagon|4.78|1.82|2.75|1600|AWD|2498|F4|NA|170|235|6000|CVT|11000|12||A kayak on the roof, a dog in the back, a national park sticker on the tailgate. Every single one.
Subaroo|Forestur|2015|crossover|suv|4.6|1.8|2.64|1550|AWD|2498|F4|NA|170|235|6000|CVT|17000|11|rack|A box with a windshield the size of a picture window. The dog's favourite car.
# ---- Mitsubishy
Mitsubishy|Starrion|1986|sports|coupe|4.4|1.74|2.44|1300|RWD|2555|I4|T|170|298|5500|M5|9000|0.3|popups,scoop|Named for a stallion, mispronounced into legend. The turbo lag came from 1986.
Mitsubishy|Eclipsed|1995|jdm|coupe|4.37|1.74|2.51|1400|AWD|1997|I4|T|210|290|7000|M5|6500|1|wing|Turbo, all-wheel drive and a wing: the first car in half of every street racing movie.
Mitsubishy|Three-Grand Gee-Tee|1994|sports|sports|4.58|1.84|2.47|1700|AWD|2972|V6|TT|320|427|7000|M6|15000|0.3|wing,popups|All-wheel steer, active aero, an adjustable exhaust, and nine pages of things that are broken.
Mitsubishy|Lanser Evolushun|2008|rally|sedan|4.5|1.81|2.65|1600|AWD|1998|I4|T|291|407|7000|M5|28000|0.6|wing|Born on a gravel stage, raised in a parking garage. The wing is bigger than your balcony.
Mitsubishy|Monteareo|1997|suv|suv|4.7|1.78|2.73|2000|4WD|3497|V6|NA|200|300|5500|A4|4000|1|spare|Tough, round and a bit dumpy, like a hockey dad at the beer league.
Mitsubishy|Mirrage|2017|economy|hatch|3.71|1.67|2.45|900|FWD|1193|I3|NA|78|100|6000|CVT|6500|4||The cheapest new car you can buy, and it feels it. Also the thriftiest. Pick your battle.
Mitsubishy|Dellica|1992|oddball|van|4.6|1.69|2.45|1900|4WD|2477|I4|TD|85|196|4200|M5|14000|0.3|bullbar,rack|An imported off-road van with a bull bar and the nerve of a mountain goat on a diet.
Mitsubishy|Minicabbie|1994|kei|pickup|3.3|1.4|1.88|720|RWD|657|I3|NA|42|55|7000|M5|7000|0.3|cabover|A cabover kei truck with a bed that holds a whole pallet of nothing.
Mitsubishy|Pajama Minnie|1997|kei|offroad|3.3|1.4|2.28|850|4WD|659|I4|T|64|98|7000|M5|9000|0.15||A sport ute in pyjamas, shrunk to kei size. A turbo four and the stance of a toy.
Mitsubishy|Outlandish|2016|crossover|suv|4.7|1.8|2.67|1500|AWD|2360|I4|NA|166|221|6000|CVT|14000|6||A crossover. Outlandish in name only. The warranty is the most outlandish thing about it.
# ---- Suzooki / Isuzoo / Daihatsoo
Suzooki|Samurrai|1987|offroad|offroad|3.43|1.53|2.03|950|4WD|1324|I4|NA|63|101|5500|M5|6500|0.8|open|Leaps tall rocks in a single bound. Also tips over in the right magazine test.
Suzooki|Sidekik|1995|offroad|offroad|3.6|1.63|2.2|1100|4WD|1590|I4|NA|95|132|6000|M5|2500|1.5||The cute little ute: your aunt's, your sister's, and the ski-hill liftie's.
Suzooki|Swifft|1989|hot_hatch|hatch|3.67|1.59|2.25|800|FWD|1298|I4|NA|100|113|7000|M5|3500|0.6||A featherweight hatch with a twin-cam that laughs at pricey sports cars on the roundabout.
Suzooki|Alt-Oh|1995|kei|hatch|3.3|1.4|2.34|650|FWD|658|I3|NA|52|58|7000|M5|4500|0.2||A kei hatch that weighs less than a hockey team. Top speed: ninety, with a tailwind.
Suzooki|Cappuchino|1992|kei|roadster|3.3|1.4|2.06|700|RWD|657|I3|T|63|85|8500|M5|12000|0.15||A kei roadster with a roof that packs into the trunk. The trunk then holds nothing.
Suzooki|Carrie|1998|kei|pickup|3.3|1.4|1.9|700|4WD|658|I3|NA|46|58|7500|M5|7500|0.4|cabover|A kei truck that has delivered more cabbages than any vehicle in history. Probably.
Suzooki|Jimnee|2002|kei|offroad|3.4|1.48|2.25|980|4WD|658|I3|T|63|103|7000|M5|9000|0.2||A Land Crusher shrunk in the wash. Climbs like a goat, cruises like a nervous one.
Suzooki|Esteam|1998|economy|wagon|4.35|1.69|2.48|1050|FWD|1590|I4|NA|95|134|6000|M5|900|1||A small wagon with a big roof rack and modest self-esteem.
Suzooki|Aerioh|2004|compact|hatch|4.25|1.72|2.48|1250|FWD|2290|I4|NA|155|210|6500|M5|1500|1.5|digidash|A digital dash that looks like a video game from 1995. Because it basically is one.
Isuzoo|Troopur|1994|suv|suv|4.62|1.76|2.76|2000|4WD|3165|V6|NA|175|255|5600|M5|3500|1|spare|A box. A good box. A box that gets you to the cottage and back on a tank of patience.
Isuzoo|Impulsive|1990|sports|coupe|4.2|1.69|2.45|1200|AWD|1588|I4|T|160|202|6800|M5|5000|0.2|spoiler|Handling by a British sports car company, the ads said. The ads did not lie, for once.
Isuzoo|Pupp|1985|pickup|pickup|4.45|1.65|2.65|1150|RWD|2238|I4|D|58|130|4400|M5|4500|0.4||A diesel pup truck: slow as ketchup, frugal as Grandpa, louder than both.
Isuzoo|En-Pee-Arr|2007|work_truck|boxtruck|6.3|2.0|3.4|3300|RWD|5193|I4|TD|190|510|3000|A6|17000|3|cabover|The cabover box truck every landscaper and caterer in the city bought on the same day.
Isuzoo|Vehicrossed|1999|oddball|offroad|4.13|1.79|2.33|1700|4WD|3494|V6|NA|215|312|5600|A4|14000|0.1||Looks like a concept car that escaped from the auto show. It did. Nobody chased it.
Daihatsoo|Charaded|1990|economy|hatch|3.62|1.6|2.34|770|FWD|993|I3|NA|53|76|6000|M5|1500|0.3||A three-cylinder hatch, sold here briefly. Everyone pretended to like it. That's the joke in the name.
Daihatsoo|Hijinx|1999|kei|kei|3.4|1.48|2.0|850|RWD|659|I3|NA|46|60|7000|M5|8000|0.4||A kei van with sliding doors on both sides and the top speed of a strong opinion.
Daihatsoo|Kopen|2003|kei|roadster|3.4|1.48|2.23|830|FWD|659|I4|T|63|110|7500|M5|11000|0.1|hardtop|A folding hardtop the size of a pizza box, on a car the size of a pizza box.
Daihatsoo|Rockee|1990|offroad|offroad|3.85|1.58|2.2|1400|4WD|1589|I4|NA|94|129|5800|M5|4500|0.2||A hardy little four-by-four, sold here for about five minutes. Spare parts: also five minutes.
# ---- Lexis / Infinitee / Scionn
Lexis|Ell-Ess Four-Hunnert|1990|luxury|sedan|5.0|1.82|2.81|1700|RWD|3969|V8|NA|250|353|6000|A4|7500|1.5||Balanced a pyramid of champagne glasses on the engine at redline in the ads. Has never spilled a coffee since.
Lexis|Ee-Ess Three-Hunnert|1999|luxury|sedan|4.83|1.79|2.67|1550|FWD|2995|V6|NA|200|290|6000|A4|3000|5||A Camree in a suit. A very nice suit.
Lexis|Eye-Ess Three-Hunnert|2001|sports|sedan|4.48|1.72|2.67|1500|RWD|2997|I6|NA|215|294|6400|M5|7000|1||Chronograph gauges, a straight-six and a rear end the drift kids already have their eye on.
Lexis|Arr-Ex Three-Hunnert|2001|crossover|suv|4.58|1.82|2.62|1750|AWD|2995|V6|NA|220|302|6000|A4|5000|5||The luxury crossover before everybody made one. The golf club parking lot is entirely these.
Lexis|Ell-Eff-Ayy|2012|exotic|sports|4.5|1.9|2.6|1480|RWD|4805|V10|NA|553|480|9000|M6|650000|0.05|wing|A V10 that screams like a formula car, tuned by a musical instrument company. That is not a joke.
Infinitee|Queue-Forty-Five|1990|luxury|sedan|5.07|1.83|2.88|1750|RWD|4494|V8|NA|278|393|6500|A4|3500|0.4||Launched with ads full of rocks and trees and no car. Buyers didn't see the car either.
Infinitee|Gee-Thirty-Five|2005|sports|coupe|4.63|1.82|2.85|1600|RWD|3498|V6|NA|298|353|7000|M6|9000|2||The upscale twin of a Zed. Drift kids buy it for the diff. Dentists buy it for the leather.
Infinitee|Queue-Ex-Fifty-Six|2008|luxury|suv|5.26|2.0|3.13|2700|4WD|5552|V8|NA|320|529|5600|A5|11000|1||A full-size truck in a tuxedo with a big chrome bow tie.
Scionn|Toaster|2005|compact|kei|3.95|1.69|2.46|1100|FWD|1497|I4|NA|103|136|6000|M5|5000|3||A box. Literally. Sold to young people, bought by retirees.
Scionn|Eff-Arr-Ess|2014|sports|coupe|4.24|1.78|2.57|1250|RWD|1998|F4|NA|200|205|7400|M6|17000|1.5|spoiler|Skinny tires, a boxer engine, and a torque dip you could lose a dog in.
# ---- Hyundie / Kiah / Daywoo
Hyundie|Ponee|1985|economy|hatch|4.0|1.56|2.38|920|RWD|1439|I4|NA|70|113|5600|M4|3000|0.6||The best-selling car in Canada in 1985. The best-selling rust in Canada by 1989.
Hyundie|Stellarr|1987|sedan|sedan|4.42|1.72|2.58|1050|RWD|1597|I4|NA|74|121|5500|A3|2500|0.2||Designed in Italy, built in Korea, and mostly forgotten in New Brunswick.
Hyundie|Excellent|1993|economy|hatch|4.1|1.6|2.38|930|FWD|1468|I4|NA|81|120|5600|M5|900|1||The name is aspirational. So are the tires. So, mostly, are the brakes.
Hyundie|Aksent|2005|economy|hatch|4.04|1.69|2.44|1050|FWD|1599|I4|NA|105|141|6000|M5|1800|6||Built to a price. The price was correct.
Hyundie|Tiburron|2003|coupe|coupe|4.39|1.76|2.53|1300|FWD|2656|V6|NA|172|245|6500|M6|2500|1.5|spoiler|The poor man's Italian exotic, if the poor man squints in the dark from far away.
Hyundie|Elantruh|2013|compact|sedan|4.53|1.78|2.7|1250|FWD|1797|I4|NA|145|175|6500|A6|10000|14||Sculpted sheet metal and a ten-year warranty, as advertised every five minutes.
Hyundie|Velloster|2013|hatch|hatch|4.22|1.79|2.65|1250|FWD|1591|I4|T|201|265|6500|M6|10000|2||One door on the left, two on the right. The engineers had an argument and both won.
Hyundie|Santa Fay|2008|crossover|suv|4.68|1.89|2.7|1850|AWD|3342|V6|NA|242|307|6000|A5|5500|9||Not a Christmas present. A crossover. December gets confusing.
Hyundie|Too-Sawn|2017|crossover|suv|4.48|1.85|2.67|1550|AWD|1999|I4|NA|164|205|6200|A6|19000|11||Named after a city in the desert, sold in a province full of snow.
Kiah|Riyoh|2006|economy|sedan|4.24|1.69|2.5|1100|FWD|1599|I4|NA|110|145|6000|A4|1500|4||A bargain-bin sedan that is somehow still running, against every prediction.
Kiah|Sole|2012|compact|kei|4.11|1.8|2.55|1300|FWD|1999|I4|NA|164|190|6500|A6|9000|10||The box from the hamster commercials. The hamsters drive it. So do you.
Kiah|Fortay|2015|compact|sedan|4.56|1.78|2.7|1300|FWD|1999|I4|NA|173|209|6500|A6|11000|9||Plain, plush, and it puts its warranty on a billboard every chance it gets.
Kiah|Sedonuh|2008|minivan|minivan|5.13|1.99|3.02|2100|FWD|3778|V6|NA|250|343|6000|A5|3500|4||Three years newer than the van it replaces, at a third the price. That's the whole pitch.
Kiah|Sorrentoh|2016|crossover|suv|4.78|1.89|2.78|1850|AWD|3342|V6|NA|290|336|6400|A6|20000|8||Seven seats and a warranty so long the car might outlive its own powertrain coverage. Might.
Kiah|Stingur|2018|sports|sedan|4.83|1.87|2.9|1850|AWD|3342|V6|TT|365|510|6200|A8|42000|1|spoiler|Twin-turbo, fastback hatch: a family sedan that would rather be a grand tourer.
Daywoo|Lanose|2001|economy|hatch|4.07|1.68|2.52|1100|FWD|1598|I4|NA|105|145|6000|M5|600|2||Bought new for nine grand, sold used for the price of a tank of gas.
Daywoo|Nubiruh|1999|compact|wagon|4.5|1.7|2.57|1250|FWD|1998|I4|NA|129|184|6000|A4|500|0.4||A Korean wagon designed in Britain. Forgotten by everyone, Korea and Britain included.
# ---- Volkswagon
Volkswagon|Beetel|1967|economy|bubble|4.07|1.54|2.4|780|RWD|1493|F4|NA|53|106|4000|M4|15000|1|rear|Air-cooled, rear-engined, unkillable. The heater works in July.
Volkswagon|Karma Ghiaa|1969|coupe|bubble|4.14|1.63|2.4|830|RWD|1493|F4|NA|53|106|4000|M4|28000|0.3|rear|An Italian-designed suit on a Beetel's bones. Looks like it's going fast. It isn't.
Volkswagon|Hippie Buss|1972|oddball|van|4.5|1.72|2.4|1300|RWD|1679|F4|NA|63|110|4000|M4|38000|0.6|rear,twotone|Peace, love, and a top speed set by the wind direction. Patience mandatory.
Volkswagon|Thingy|1973|oddball|offroad|3.78|1.64|2.4|900|RWD|1584|F4|NA|46|98|4000|M4|22000|0.15|rear,open|A doorless, roofless, flat-sided box. Every drive is a sunburn.
Volkswagon|Jackrabbit|1980|hatch|hatch|3.82|1.61|2.4|840|FWD|1588|I4|NA|76|113|6000|M4|3500|0.6||Boxy, light and eager. The diesel version gets to a hundred eventually.
Volkswagon|Golph Gee-Tee-Eye|1985|hot_hatch|hatch|3.99|1.68|2.47|930|FWD|1781|I4|NA|102|149|6300|M5|8500|0.6||The hot hatch that started the whole thing: a red stripe on the grille and a dimpled-ball shift knob.
Volkswagon|Sirocko|1985|coupe|hatch|4.05|1.65|2.4|920|FWD|1781|I4|NA|90|140|6000|M5|5000|0.3||A wedge with a hot wind's name and a warm breeze's power.
Volkswagon|Vanagone Westfailure|1987|oddball|van|4.57|1.84|2.46|1650|RWD|2109|F4|NA|95|160|5000|M4|30000|0.3|rear,rack,twotone|A camper with a pop-top, a fridge, a sink and a breakdown schedule printed in the owner's manual.
Volkswagon|Jettuh|1996|compact|sedan|4.38|1.7|2.47|1200|FWD|1984|I4|NA|115|166|6000|M5|1500|6||A Golph with a trunk. Every dorm parking lot's centrepiece, every check-engine light's favourite.
Volkswagon|Passatt Wagon|2002|wagon|wagon|4.68|1.74|2.7|1500|FWD|1781|I4|T|170|225|6200|A5|2500|4||A German family wagon that knows exactly what your ignition coils are going to do next, and when.
Volkswagon|Twoareg|2008|suv|suv|4.75|1.93|2.86|2300|AWD|3597|V6|NA|280|360|6300|A6|9000|2||An air suspension that sighs every morning, like it's not a morning person either.
Volkswagon|Jettuh Tee-Dee-Eye|2010|compact|sedan|4.55|1.78|2.65|1450|FWD|1968|I4|TD|140|320|4800|M6|6500|5||Clean diesel, they said. Very clean. Suspiciously clean. Ask the lawyers.
Volkswagon|Golph|2015|compact|hatch|4.26|1.8|2.64|1300|FWD|1798|I4|T|170|250|6200|M5|13000|8||The sensible quality hatch, with a warranty that ends exactly one week before the water pump.
# ---- Beemer-Werke
Beemer-Werke|Isette|1958|oddball|bubble|2.29|1.38|1.5|360|RWD|298|S1|NA|13|19|5200|M4|38000|0.1||The whole front of the car is the door, and the steering wheel swings out with it. Park nose-first at the curb.
Beemer-Werke|Two-Oh-Two|1972|euro|sedan|4.23|1.59|2.5|1000|RWD|1990|I4|NA|100|157|6000|M4|28000|0.3||The compact sports sedan that invented the idea. Every owner will tell you so.
Beemer-Werke|Dreier|1988|euro|sedan|4.32|1.65|2.57|1200|RWD|2494|I6|NA|168|222|6500|M5|9000|1.2||A straight-six that purrs like a sewing machine. The rest of it purrs like one that needs oil.
Beemer-Werke|Emm-Dreier|1990|sports|coupe|4.35|1.68|2.56|1200|RWD|2302|I4|NA|195|240|7200|M5|85000|0.15|wing|A homologation special with box flares. Every one left is worth more than your house.
Beemer-Werke|Achter|1992|exotic|sports|4.78|1.86|2.68|1800|RWD|4988|V12|NA|300|450|6000|M6|35000|0.1|popups|A grand tourer with pop-up lamps and a V12 that runs on twelve cylinders and dread.
Beemer-Werke|Zee-Dreier|1998|sports|roadster|4.03|1.69|2.45|1250|RWD|2793|I6|NA|190|280|6500|M5|11000|0.6||A retro roadster driven by a secret agent once, and by a dentist every other time.
Beemer-Werke|Funfer|1999|euro|sedan|4.78|1.8|2.83|1600|RWD|2793|I6|NA|190|280|6500|A5|4500|3||Drives beautifully until the cooling system fails. It's failing right now. Can you hear it?
Beemer-Werke|Emm-Funf|2006|luxury|sedan|4.86|1.85|2.89|1830|RWD|4999|V10|NA|500|520|8250|A7|25000|0.3||A V10 in a business sedan. The rod bearings are a recurring expense, like a mortgage.
Beemer-Werke|Ex-Funf|2007|suv|suv|4.85|1.93|2.93|2300|AWD|4799|V8|NA|350|475|6500|A6|11000|3||The lawyer's ski chalet runabout. Self-levelling suspension, self-righteous parking.
# ---- Mercedez / Smartt
Mercedez|Gullwinger|1955|exotic|coupe|4.52|1.79|2.4|1300|RWD|2996|I6|NA|215|275|6000|M4|1900000|0.02|chrome|Doors that open upward like an angel taking off, and a price that rose even faster.
Mercedez|Three-Hunnert Diesel|1982|euro|sedan|4.73|1.79|2.8|1500|RWD|3005|I5|D|80|169|4600|A4|6000|0.6||A million kilometres, give or take. Zero to a hundred: give or take a calendar.
Mercedez|Superleicht|1985|luxury|roadster|4.39|1.79|2.46|1600|RWD|5547|V8|NA|227|380|5200|A4|22000|0.3|hardtop|The rich divorcee's roadster, with a hardtop that two people can lift and one dog can sit on.
Mercedez|One-Ninety Eee|1989|euro|sedan|4.42|1.68|2.67|1200|RWD|2299|I4|NA|130|186|6000|M5|5000|1||The baby of the family. Over-engineered, underpowered, impossible to kill.
Mercedez|Ess-Klassy|2005|luxury|sedan|5.04|1.87|2.97|1900|RWD|4966|V8|NA|302|460|6000|A7|9000|1.5||A fridge in the back seat and an air suspension that leaks in front.
Mercedez|Gee-Waggen|2012|offroad|offroad|4.66|1.86|2.85|2500|4WD|5461|V8|NA|382|530|6000|A7|60000|0.6||A military box turned status symbol. The doors close like a bank vault. The fuel bill opens like one.
Mercedez|Sprintur Cube|2015|work_truck|boxtruck|7.0|2.2|4.3|3200|RWD|2987|V6|TD|188|440|4000|A5|28000|2||The delivery cube. The parcel guy calls it home from eight to six.
Smartt|Fourtoo|2008|oddball|kei|2.7|1.56|1.87|820|RWD|999|I3|NA|70|92|5800|A5|3500|1.5|rear|Parks sideways, gets passed by bicycles, and shifts gears like it has the hiccups.
# ---- Awdi / Porch
Awdi|Kwattro|1983|rally|coupe|4.4|1.72|2.52|1300|AWD|2144|I5|T|200|285|6500|M5|90000|0.2|spoiler|All-wheel drive changed rallying forever. The five-cylinder warble changes your neighbour's mood forever.
Awdi|Five-Grand|1986|euro|sedan|4.79|1.81|2.69|1300|FWD|2226|I5|NA|130|187|5800|A3|2500|0.2||Accused of accelerating all by itself. If only.
Awdi|Tee-Tee|2001|sports|coupe|4.04|1.76|2.42|1400|AWD|1781|I4|T|225|280|6500|M6|6500|1||A design-school bathtub with a turbo. The architect's first car, and last.
Awdi|Ayy-Four|2004|euro|sedan|4.55|1.77|2.65|1500|AWD|1781|I4|T|170|225|6200|M5|3500|5||Owners love it. Mechanics love it more. It's paying for their boats.
Awdi|Queue-Seven|2010|luxury|suv|5.09|1.98|3.0|2400|AWD|3597|V6|NA|280|360|6300|A6|14000|2||Three rows of German leather. The repair bills also seat seven.
Awdi|Arr-Ate|2011|exotic|wedge|4.44|1.9|2.65|1560|AWD|5204|V10|NA|525|530|8700|M6|130000|0.15|mid|A gated manual on a V10. The sweetest clack in the history of shifting.
Porch|Speedstur|1957|sports|roadster|3.95|1.67|2.1|770|RWD|1582|F4|NA|70|110|5500|M4|380000|0.05|rear|A bathtub with a racing pedigree. Weighs nothing, steers by thought, costs a cottage.
Porch|Neuner|1973|sports|sports|4.15|1.61|2.27|1080|RWD|2341|F6|NA|190|216|7200|M5|140000|0.15|rear|Rear engine, steering from the gods, and lift-off oversteer from the other place.
Porch|Nine-Two-Ate|1985|exotic|sports|4.45|1.84|2.5|1500|RWD|4664|V8|NA|288|400|5750|A4|35000|0.15|popups|The front-engine V8 one that the purists hated. The purists were wrong.
Porch|Neuner Turbo|1986|exotic|sports|4.29|1.78|2.27|1340|RWD|3299|F6|T|282|430|6800|M4|180000|0.1|rear,wing|The widow-maker: a whale-tail wing, four gears and a turbo that arrives all at once, mid-corner.
Porch|Nine-Forty-For|1987|sports|sports|4.2|1.74|2.4|1290|RWD|2479|I4|NA|158|210|6000|M5|9000|0.6|popups|Front engine, rear gearbox, perfect balance, pop-up lights. The timing belt is a ticking bomb.
Porch|Boxter|2001|sports|roadster|4.32|1.78|2.42|1300|RWD|2687|F6|NA|228|260|6700|M5|11000|1|mid|The poor man's Porch. Not poor enough to fix the intermediate shaft bearing, though.
Porch|Kayenne|2008|luxury|suv|4.8|1.93|2.86|2300|AWD|4806|V8|NA|385|500|6700|A6|14000|1.5||A sports car company built a sport ute. The sports car company now exists because of it.
# ---- Volvoh / Saabb
Volvoh|Amasson|1965|euro|sedan|4.45|1.62|2.6|1100|RWD|1778|I4|NA|90|143|5800|M4|14000|0.3||Hump-backed, indestructible, and a Swedish farmer's idea of a sports sedan.
Volvoh|Pee-Eighteen|1967|coupe|coupe|4.35|1.7|2.45|1100|RWD|1778|I4|NA|115|152|6000|M4|35000|0.15|fins|One of these holds the record for the most kilometres ever driven. This one hasn't helped.
Volvoh|Brick|1989|wagon|wagon|4.79|1.71|2.64|1400|RWD|2316|I4|NA|114|185|5500|A4|4500|2.5||Boxy, rear-drive, safe as a bank. Driven by every literature professor in the province.
Volvoh|Seven-Forty Turbrick|1990|wagon|wagon|4.79|1.75|2.77|1450|RWD|2316|I4|T|162|264|5500|A4|5000|0.8||A turbocharged brick. A flying brick is still a brick. A fast one, though.
Volvoh|Eight-Fiftee Tee-Fivr|1995|euro|wagon|4.71|1.76|2.66|1500|FWD|2319|I5|T|240|330|6000|M5|9000|0.4||A family wagon that went touring-car racing. The groceries get home first.
Volvoh|Vee-Seventy|2004|wagon|wagon|4.71|1.8|2.76|1600|FWD|2435|I5|T|197|285|6000|A5|3000|3||The boring wagon that will take the whole family to Cape Breton and back in comfort. Twice.
Volvoh|Ex-See-Ninety|2016|crossover|suv|4.95|2.01|2.98|2100|AWD|1969|I4|TT|316|400|6000|A8|38000|3||A Scandinavian living room on wheels: driftwood trim, a wool blanket, and a crash score to brag about.
Saabb|Ninety-Sicks|1967|oddball|bubble|4.2|1.58|2.5|900|FWD|841|I3|2S|40|78|4600|M4|14000|0.15||A two-stroke three that sounds like a chainsaw and wants oil in the gas tank. Freewheel for fun.
Saabb|Nine-Hunnert Turbo|1987|euro|hatch|4.69|1.69|2.52|1300|FWD|1985|I4|T|160|255|6000|M5|7000|0.6||The ignition key is between the seats. Aircraft engineers did that, and you will never find out why.
Saabb|Nine-Five Airhead|2002|euro|wagon|4.83|1.79|2.7|1600|FWD|2290|I4|T|250|350|6200|M5|3500|0.3||A turbo family wagon built by an aircraft company. Fast, weird, comfortable and orphaned.
# ---- Minni / Fiatt / Alfa Romio / Lanchia
Minni|Cupper|1965|hot_hatch|hatch|3.05|1.41|2.04|650|FWD|1071|I4|NA|70|84|6500|M4|38000|0.3|twotone|Won rallies against cars five times its size. Fits in a closet. You'll need a small driver.
Minni|Moak|1966|oddball|offroad|3.05|1.3|2.03|600|FWD|848|I4|NA|34|60|5500|M4|35000|0.08|open,nospare|A beach buggy that's basically a tray with an engine. Sunburn is a feature.
Minni|Cupper Ess|2005|hot_hatch|hatch|3.66|1.69|2.47|1215|FWD|1598|I4|S|168|220|6750|M6|5000|2|twotone,scoop|The supercharger whines like a happy dog. The clutch dies like a sad one.
Fiatt|Cinquesomething|1968|kei|bubble|2.97|1.32|1.84|500|RWD|499|I2|NA|18|30|4600|M4|19000|0.2|rear|Two cylinders out back and a canvas roof that folds open, so you can stand up in traffic.
Fiatt|Spydurr|1979|sports|roadster|3.97|1.61|2.28|1000|RWD|1756|I4|NA|86|136|6000|M5|11000|0.3||A pretty Italian roadster. Every piece of it rusts at its own speed, like an orchestra tuning up.
Fiatt|Ex-Won-Nine|1980|sports|wedge|3.83|1.57|2.2|900|RWD|1498|I4|NA|75|108|6000|M5|8000|0.2|mid,popups|A tiny mid-engine wedge with pop-ups. The poor man's exotic. Accurate, both halves.
Fiatt|Strada-ish|1981|economy|hatch|3.88|1.65|2.45|900|FWD|1498|I4|NA|69|108|5800|M5|2500|0.1||Its nickname is a four-word acronym about fixing it again. You can work it out.
Fiatt|Cinquesomething|2012|economy|bubble|3.55|1.63|2.3|1100|FWD|1368|I4|NA|101|133|6500|M5|6500|3|round|The same idea as the old one, upsized for people who now need cupholders.
Alfa Romio|Duettoh|1967|sports|roadster|4.25|1.63|2.25|990|RWD|1570|I4|NA|109|142|6000|M5|38000|0.15||The boat-tail roadster from a famous film with a famous ending. Rusts at the speed of a Sicilian sunset.
Alfa Romio|Milanese|1987|euro|sedan|4.33|1.63|2.51|1200|RWD|2492|V6|NA|154|206|6200|M5|12000|0.1||The V6 sings opera. The electrics sing tragic opera.
Alfa Romio|Giuliana Kloverleaf|2017|sports|sedan|4.64|1.86|2.82|1600|RWD|2891|V6|TT|505|600|6500|A8|65000|0.3||A family sedan that laps a famous German racetrack faster than supercars. It also has more warning lights than some.
Lanchia|Deltuh Integrally|1992|rally|hatch|3.9|1.77|2.48|1300|AWD|1995|I4|T|210|300|6500|M5|75000|0.03|scoop|Six world titles in a row in a car shaped like a cardboard box with flared arches.
# ---- Brits
Landrova|Series Too-Ay|1968|offroad|offroad|3.62|1.68|2.24|1400|4WD|2286|I4|NA|70|160|4500|M4|28000|0.2||Galvanized chassis, aluminium body, and oil leaks that mark the territory like a dog.
Landrova|Range Rova|1990|suv|suv|4.45|1.82|2.54|2000|4WD|3947|V8|NA|185|319|4750|A4|12000|0.3||Upstairs, downstairs, and every stair in between. The air suspension became coil springs and regret.
Landrova|Defendur|1997|offroad|offroad|4.0|1.79|2.79|1900|4WD|2495|I5|TD|122|265|4200|M5|65000|0.2|rack,snorkel|A snorkel for crossing rivers, in a city with one muddy river and a perfectly good bridge.
Landrova|Freeloader|2005|crossover|suv|4.4|1.8|2.56|1650|AWD|2497|V6|NA|174|240|6250|A5|3500|0.6||Small, cheap and adorable, and therefore almost entirely unreliable.
Landrova|Discovered|2005|suv|suv|4.85|1.92|2.88|2600|4WD|4394|V8|NA|300|425|5500|A6|9000|0.6||A seven-seat house with a stepped roof. The electrics discover new faults every morning.
Jagwire|Ee-Typo|1965|exotic|sports|4.45|1.66|2.44|1250|RWD|4235|I6|NA|265|384|5500|M4|190000|0.05||Called the most beautiful car ever made by a man who made rival cars. He was being humble.
Jagwire|Ex-Jay-Sicks|1987|luxury|sedan|4.99|1.8|2.87|1800|RWD|4235|I6|NA|165|318|5000|A3|5500|0.4||Wood, leather, and wiring from a supplier the owners call the Prince of Darkness.
Jagwire|Ex-Jay-Ess|1990|luxury|coupe|4.76|1.79|2.59|1750|RWD|5343|V12|NA|262|393|6000|A3|9000|0.2||A V12 grand tourer. The dealer handed you two keys and the mechanic's phone number.
Jagwire|Ess-Typo|2001|luxury|sedan|4.88|1.82|2.91|1700|RWD|3996|V8|NA|281|392|6400|A5|3000|0.6||A retro face built to look old. It succeeded beyond its wildest dreams. It now feels very old.
Triumf|Spitflame|1972|sports|roadster|3.73|1.49|2.11|780|RWD|1296|I4|NA|61|91|6000|M4|9000|0.3||A tiny British roadster. The whole front tilts forward like a clam. The bits fall off like a clam's too.
Triumf|Wedgie|1977|sports|wedge|4.06|1.68|2.16|1050|RWD|1998|I4|NA|92|162|5500|M4|5000|0.15|popups|Shaped like a doorstop. The shape of things to come, said the ads. Half right.
Emmgee|Bee|1974|sports|roadster|3.89|1.52|2.31|950|RWD|1798|I4|NA|95|149|5500|M4|12000|0.6||The British roadster everybody's dad owned once. The oil stains mark where he parked it.
Austen-Healthy|Frog-Eyed Spryte|1959|sports|roadster|3.49|1.35|2.03|600|RWD|948|I4|NA|43|71|5800|M4|22000|0.1||Headlights on top of the hood like a frog's eyes. The trunk doesn't open. The doors barely matter.
Austen-Healthy|Big Healthy|1965|sports|roadster|4.0|1.54|2.34|1150|RWD|2912|I6|NA|148|224|5250|M4|95000|0.06||A rumbling six, an exhaust that scrapes everything, and a cockpit that warms you like whisky.
Lotis|Ellann|1966|sports|roadster|3.68|1.42|2.13|700|RWD|1558|I4|NA|105|146|6500|M4|60000|0.05||A feather with an engine. More power makes you faster on the straights. Less weight makes you faster everywhere.
Lotis|Espree|1979|exotic|wedge|4.19|1.86|2.44|1100|RWD|2174|I4|T|210|271|6500|M5|30000|0.08|mid,popups|Once turned into a submarine in a spy movie. It leaks like one now.
Lotis|Eleese|2005|sports|roadster|3.79|1.72|2.3|860|RWD|1796|I4|NA|190|181|8000|M6|38000|0.1|mid|No power steering, no carpet, no mercy. Getting in requires yoga.
Reliable|Robbin|1975|oddball|trike|3.33|1.42|2.13|440|RWD|850|I4|NA|40|61|5500|M4|7000|0.15||One wheel at the front. Corners like a shopping cart full of cats. Tips over if you look at it wrong.
# ---- the Continent's odd ones
Renoh|Le Carr|1979|economy|hatch|3.5|1.53|2.4|780|FWD|1289|I4|NA|55|90|5500|M4|5000|0.15||The badge on the door says it's French for the car, in case there was any doubt.
Renoh|Ally-Ants|1985|economy|sedan|4.1|1.65|2.48|870|FWD|1397|I4|NA|64|102|5500|M4|1200|0.15||A French car built in Wisconsin and sold in Canada. It was never sure which one it was.
Peugoh|Five-Oh-For|1976|euro|sedan|4.49|1.69|2.74|1200|RWD|1971|I4|NA|97|160|5500|M4|8000|0.1||Bush taxi, Paris cab, a professor's commuter in Quebec City. All of it, slowly.
Peugoh|Two-Oh-Five Tee-Sixteen|1985|rally|hatch|3.82|1.67|2.54|1150|AWD|1775|I4|T|200|255|7000|M5|400000|0.005|mid|A rally monster in a shopping hatch's clothes. Banned before it could finish its homework.
Citrowen|Goddess|1970|oddball|sedan|4.87|1.79|3.12|1300|FWD|2175|I4|NA|106|172|5500|M4|45000|0.1||Hydraulic suspension: it rises when you start it, kneels when you park it, and floats over every pothole on Main.
Citrowen|Deux Chevals|1975|oddball|bubble|3.83|1.48|2.4|560|FWD|602|F2|NA|29|39|5750|M4|17000|0.15||An umbrella on four wheels, built to cross a ploughed field with a basket of eggs on the seat.
Ladda|Signett|1985|economy|sedan|4.13|1.62|2.42|1030|RWD|1452|I4|NA|71|106|5600|M4|3000|0.2||A Soviet sedan from a sixties Italian design. The toolkit was standard, and you needed it.
Ladda|Nivva|1988|offroad|offroad|3.74|1.68|2.2|1150|4WD|1569|I4|NA|73|116|5400|M4|8000|0.3||A Soviet four-by-four. Climbs anything, rusts everything, sold in Canada for one glorious decade.
Yugoh|Jee-Vee|1988|economy|hatch|3.49|1.54|2.15|830|FWD|1116|I4|NA|54|73|5600|M4|2500|0.2||The cheapest new car on the continent in 1988. Still is, technically.
Trabbie|Six-Oh-Won|1975|oddball|bubble|3.56|1.5|2.02|615|FWD|594|I2|2S|26|54|4200|M4|9000|0.1||A body of cotton-reinforced plastic and a two-stroke smoke trail. Ten-year waiting list not included.
Peeled|Pee-Fifty|1963|oddball|bubble|1.37|0.99|1.27|59|RWD|49|S1|2S|4.2|5|6000|M3|120000|0.02||The smallest car ever sold. No reverse: there's a handle on the back. Pick it up and turn it around.
Messershmidt|Kabine|1956|oddball|bubble|2.82|1.22|2.03|230|RWD|191|S1|2S|10|13|5000|M4|60000|0.03||A fighter-plane canopy on a scooter. Your passenger sits right behind you, commenting.
Amphicarr|Floaty|1963|oddball|coupe|4.33|1.57|2.1|1050|RWD|1147|I4|NA|43|75|4750|M4|80000|0.05|rear|Drives on the road, swims in the river. Seven knots on water, seventy on land, terrible at both.
# ---- exotics
Ferraree|Two-Fifty Gee-Tee-Oh-No|1962|exotic|sports|4.33|1.6|2.4|1000|RWD|2953|V12|NA|300|294|7500|M5|60000000|0.005||Thirty-six were built. If you see one in traffic, you're dreaming, or very rich, or both.
Ferraree|Deeno|1972|exotic|sports|4.23|1.7|2.34|1080|RWD|2419|V6|NA|195|226|7600|M5|450000|0.02|mid|Not allowed to wear the big badge at first: too few cylinders. It wore the shame beautifully.
Ferraree|Three-Oh-Ate|1984|exotic|wedge|4.23|1.72|2.34|1300|RWD|2927|V8|NA|240|260|7700|M5|95000|0.06|mid,popups|A loud shirt, a moustache and a mid-engine V8. Private investigator not included.
Ferraree|Mondiale|1985|exotic|coupe|4.58|1.79|2.65|1450|RWD|2926|V8|NA|240|260|7000|M5|45000|0.05|mid,popups|The four-seat mid-engine one nobody wanted. Which makes it the cheapest way into the club.
Ferraree|Testosterona|1987|exotic|wedge|4.49|1.98|2.55|1500|RWD|4942|F12|NA|390|490|6800|M5|180000|0.05|mid,popups,strakes|Side strakes like cheese graters, and wide enough to be a problem in every parking garage in the Maritimes.
Ferraree|Eff-Forty|1990|exotic|wedge|4.36|1.97|2.45|1100|RWD|2936|V8|TT|471|577|7750|M5|3200000|0.01|mid,wing|No carpets, no door handles, no radio, no mercy. The boost hits like a door slammed in your face.
Ferraree|Three-Sixty Modennuh|2002|exotic|wedge|4.48|1.92|2.6|1400|RWD|3586|V8|NA|395|373|8500|M6|95000|0.1|mid|A glass engine cover shows off the V8 the way a peacock shows off its tail.
Ferraree|Four-Five-Ate|2012|exotic|wedge|4.53|1.94|2.65|1500|RWD|4497|V8|NA|562|540|9000|DCT7|260000|0.1|mid|Nine thousand rpm and a steering wheel with more buttons than a TV remote.
Lamberghini|Meeura|1968|exotic|sports|4.36|1.76|2.5|1100|RWD|3929|V12|NA|350|370|7000|M5|2500000|0.01|mid|The first supercar: a V12 sideways behind your head and eyelashes around the headlights.
Lamberghini|Coontash|1985|exotic|wedge|4.14|2.0|2.45|1490|RWD|5167|V12|NA|455|500|7000|M5|650000|0.02|mid,wing,popups|On every bedroom wall in 1987. Reversing it means sitting on the door sill and praying.
Lamberghini|Ell-Emm Oh-Oh-Too|1988|oddball|suv|4.79|2.0|2.95|2700|4WD|5167|V12|NA|444|500|6800|M5|450000|0.02|spare,norack|A military-ish truck with a supercar's V12. A 290-litre fuel tank, good for the next town over.
Lamberghini|Diabloh|1995|exotic|wedge|4.46|2.04|2.65|1580|AWD|5707|V12|NA|492|580|7000|M5|380000|0.03|mid,popups,wing|The devil's own doorstop, with pop-up lamps from a humble sports car's parts bin.
Lamberghini|Huracane|2015|exotic|wedge|4.46|1.92|2.62|1550|AWD|5204|V10|NA|602|560|8500|DCT7|260000|0.08|mid|Named after a fighting bull, sounds like a hurricane, parks like a crab.
Mazeratty|Biturboh|1985|euro|sedan|4.15|1.71|2.51|1200|RWD|1996|V6|TT|180|255|7000|M5|9000|0.06||Twin turbos and Italian electrics: a tragic opera in the shape of a sedan.
Mazeratty|Ghibbly|2015|luxury|sedan|4.97|1.95|3.0|1900|RWD|2979|V6|TT|345|500|6500|A8|30000|0.5||A trident on the grille and a cabin assembled in a hurry, but beautifully.
Aston Martian|Double-Bee Five|1964|exotic|coupe|4.57|1.68|2.49|1500|RWD|3995|I6|NA|282|390|5500|M5|1100000|0.01||Secret agents prefer theirs with ejector seats. This one has a regular seat and a regular bill.
Aston Martian|Lagonduh|1980|oddball|sedan|5.28|1.82|2.92|2000|RWD|5340|V8|NA|280|434|6000|A3|65000|0.05|digidash,popups|A wedge-shaped limousine with a digital dash so advanced it was usually broken.
Aston Martian|Vantidge|2008|exotic|sports|4.38|1.87|2.6|1600|RWD|4735|V8|NA|420|470|7300|M6|60000|0.08||The handsome one. Every line drawn by somebody who hated straight lines.
Bentlee|Continentally Gee-Tee|2006|luxury|coupe|4.8|1.92|2.75|2400|AWD|5998|W12|TT|552|650|6100|A6|45000|0.2||Hand-stitched leather at three hundred kilometres an hour. The resale value goes even faster.
Rolls-Rois|Silver Shaddow|1975|luxury|sedan|5.17|1.8|3.04|2100|RWD|6750|V8|NA|200|441|4500|A3|25000|0.05||Power output, per the factory: adequate. Fuel economy, per the factory: none of your business.
Rolls-Rois|Phantomm|2005|luxury|sedan|5.83|1.99|3.57|2560|RWD|6749|V12|NA|453|720|5350|A6|120000|0.03||Umbrellas in the doors, stars in the headliner, and a turning circle measured in hectares.
Bugattee|Veyrun|2008|exotic|wedge|4.46|2.0|2.71|1890|AWD|7993|W16|TT|1001|1250|6600|DCT7|1900000|0.005|mid,wing|Sixteen cylinders, four turbos, ten radiators, and tires that cost as much as a used Corolly.
Maclarence|Eff-Won|1994|exotic|wedge|4.29|1.82|2.72|1140|RWD|6064|V12|NA|618|650|7500|M6|25000000|0.002|mid|The driver sits in the middle. The passengers sit behind on either side, and had better be good friends.
"""
