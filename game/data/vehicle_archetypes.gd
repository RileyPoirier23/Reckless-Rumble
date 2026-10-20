## The geometry archetypes of the vehicle art expansion (DEV ADDITIONS.md, "Vehicle Archetypes"):
## every car is drawn on one of 25 shared shapes, so a bumper, a hood or a wing is authored once
## per archetype and fits every car on it instead of being hand-fitted to five hundred.
##
## of(spec) picks a car's archetype from what the catalogue already knows: its body, its class,
## its length and where its engine sits. The body decides first (a pickup is a pickup whatever
## its class), then the class and the size split it. The rules read the same numbers CarGen
## builds the side view from, so a car never lands on a shape it isn't drawn as.
##
## quota_class() and era_band() sort a car into the spec's class and era quotas (Catalog
## Allocation), so the manifest tool can print the spread against them.
class_name VehicleArchetypes
extends RefCounted

## The 25, in the spec's order, each with the lengths (m) its parts are authored for. A car
## outside its archetype's range still goes on it, but its manifest says so ("length_outside_range")
## so the part author knows to check the fit.
const TABLE := [
	["micro_fwd", 1.2, 3.7, "city cars, kei cars, bubble cars and three-wheelers"],
	["compact_fwd", 3.7, 4.55, "subcompacts and economy notchbacks, boxy kei-shaped compacts"],
	["hatch_fwd", 3.0, 4.7, "three- and five-door hatchbacks, hot hatches, rally hatches"],
	["sedan_compact", 4.0, 4.65, "compact sedans"],
	["sedan_midsize", 4.6, 5.1, "family and sport sedans, fleet cars"],
	["sedan_fullsize", 5.0, 6.0, "full-size, formal and executive sedans"],
	["coupe_compact", 3.9, 4.8, "small coupes and liftbacks, wedge-shaped economy coupes"],
	["coupe_gt", 4.3, 6.0, "personal luxury coupes, front-engined GTs and grand tourers"],
	["muscle_longhood", 4.4, 5.6, "pony cars and muscle cars: long hood, short deck"],
	["sports_frontengine", 3.3, 4.9, "front-engined sports cars and roadsters, tuner coupes"],
	["sports_midengine", 3.3, 4.8, "mid- and rear-engined sports cars: no long hood, the deck carries the vents"],
	["exotic_wedge", 3.9, 4.8, "wedge exotics and halo cars"],
	["wagon_compact", 4.0, 4.65, "compact estates"],
	["wagon_fullsize", 4.6, 6.5, "long-roofs and full-size estates"],
	["crossover_compact", 3.9, 4.75, "compact crossovers and soft-roaders"],
	["suv_midsize", 4.3, 5.05, "mid-size SUVs and long-wheelbase 4x4s"],
	["suv_fullsize", 5.0, 5.9, "full-size and luxury SUVs"],
	["offroad_short", 2.9, 4.4, "short-wheelbase trail 4x4s"],
	["pickup_compact", 3.2, 5.0, "kei and compact pickups, car-based utes"],
	["pickup_half_ton", 4.95, 6.0, "half-ton pickups"],
	["pickup_heavy", 5.6, 7.0, "heavy-duty pickups and duallies, semi tractors"],
	["van_cargo", 4.3, 6.2, "panel and cargo vans"],
	["van_passenger", 4.2, 6.2, "passenger and conversion vans, buses"],
	["minivan", 4.4, 5.3, "minivans"],
	["utility_tow", 5.5, 10.0, "wreckers, box trucks, ambulances, fire engines, packers"],
]

## The spec's class quotas (out of 300) and its era quotas.
const QUOTA_CLASSES := {
	"compact_economy": 28, "sedan": 32, "hatchback": 24, "wagon": 20, "coupe": 26, "muscle": 18, "sports": 28,
	"super_exotic": 14, "pickup": 26, "van_minivan": 16, "suv_crossover": 28, "utility_service": 12, "offroad": 14,
	"luxury": 14,
}
const ERA_BANDS := { "1950-1969": 24, "1970-1979": 30, "1980-1989": 50, "1990-1999": 66, "2000-2009": 70, "2010-2019": 60 }

static func names() -> Array:
	var out: Array = []
	for row: Array in TABLE: out.append(row[0])
	return out

static func is_valid(arch: String) -> bool:
	return names().has(arch)

## [min, max] length (m) an archetype's parts are authored for.
static func length_range(arch: String) -> Vector2:
	for row: Array in TABLE:
		if row[0] == arch: return Vector2(float(row[1]), float(row[2]))
	return Vector2.ZERO

## What the rules read: the spec's own numbers, with the catalogue line filling in what a
## spec leaves out (a hand-made car's class, a catalogue car's engine position and cues).
static func facts(spec: Dictionary) -> Dictionary:
	var id := String(spec.get("id", ""))
	var e := CarCatalog.entry(id) if id != "" else {}
	var eng: Dictionary = e.get("engine", {})
	var art: Dictionary = spec.get("art", e.get("art", {}))
	var tokens: Array = e.get("tokens", [])
	var cls := String(spec.get("class", e.get("class", "")))
	var body := String(spec.get("body", e.get("body", "sedan")))
	if cls == "": cls = "fleet" if spec.has("owner") and body in ["boxtruck", "bus", "semi"] else String(CarGen.DEFAULT_CLASS.get(body, "sedan"))
	return {
		"class": cls, "body": body, "L": float(spec.get("length", e.get("length", 4.5))),
		"pos": String(eng.get("position", "front")), "art": art, "tokens": tokens,
	}

## The archetype a car is drawn on. Every car gets exactly one.
static func of(spec: Dictionary) -> String:
	var f := facts(spec)
	var cls: String = f["class"]
	var body: String = f.body
	var L: float = f.L
	var behind: bool = f.pos in ["mid", "rear"]        # the engine sits behind the seats
	var art: Dictionary = f.art
	match body:
		"tow", "boxtruck":
			return "utility_tow"
		"bus":
			return "van_passenger"        # CarGen draws a bus on the van skeleton
		"semi":
			return "pickup_heavy"         # and a tractor on the pickup's, a frame where the bed goes
		"pickup":
			if cls in ["hd_pickup", "work_truck"] or art.has("dually"): return "pickup_heavy"
			return "pickup_compact" if L < 5.0 else "pickup_half_ton"
		"van":
			return "van_cargo" if art.has("cargo") or (f.tokens as Array).has("cargo") or cls == "work_truck" else "van_passenger"
		"minivan":
			return "minivan"
		"muscle":
			return "muscle_longhood"
		"wedge":
			if cls == "exotic": return "exotic_wedge"
			if behind: return "sports_midengine"
			return "sports_frontengine" if cls in ["sports", "jdm", "rally"] else "coupe_compact"
		"sports":
			if behind: return "sports_midengine"
			return "coupe_gt" if cls in ["exotic", "luxury"] else "sports_frontengine"
		"roadster":
			if behind: return "sports_midengine"
			return "coupe_gt" if cls in ["luxury", "classic", "sedan"] else "sports_frontengine"
		"coupe":
			if cls in ["muscle", "pony"]: return "muscle_longhood"
			if cls == "exotic": return "sports_midengine" if behind else "coupe_gt"
			if cls == "luxury": return "coupe_gt"
			if cls in ["sports", "jdm", "rally"]: return "sports_midengine" if behind else "sports_frontengine"
			return "coupe_gt" if L >= 4.8 else "coupe_compact"
		"hatch":
			if cls == "kei" or L < 3.65: return "micro_fwd"
			if cls in ["jdm", "sports", "coupe"] or (cls == "oddball" and L >= 4.3): return "coupe_compact"
			return "compact_fwd" if cls == "economy" and L < 4.3 else "hatch_fwd"
		"sedan":
			if cls == "economy" or L < 4.25: return "compact_fwd"
			if cls == "compact" or L < 4.6: return "sedan_compact"
			return "sedan_midsize" if L < 5.0 else "sedan_fullsize"
		"wagon":
			return "wagon_compact" if L < 4.65 else "wagon_fullsize"
		"suv":
			if cls == "crossover": return "crossover_compact" if L < 4.75 else "suv_midsize"
			if L < 4.4: return "offroad_short"
			return "suv_midsize" if L < 5.05 else "suv_fullsize"
		"offroad":
			if L < 4.4: return "offroad_short"
			return "suv_midsize" if L < 5.05 else "suv_fullsize"
		"kei", "bubble", "trike":
			if L < 3.7: return "micro_fwd"
			if cls == "crossover": return "crossover_compact"
			return "coupe_compact" if cls == "coupe" else "compact_fwd"
	# a body the art doesn't know yet: by size, as a sedan
	if L < 4.25: return "compact_fwd"
	return "sedan_compact" if L < 4.6 else ("sedan_midsize" if L < 5.0 else "sedan_fullsize")

## Why a car sits a little off its archetype: shapes drawn on another skeleton, and lengths
## past what the archetype's parts are authored for. Empty for most cars.
static func exceptions(spec: Dictionary) -> Array:
	var f := facts(spec)
	var arch := of(spec)
	var out: Array = []
	match String(f.body):
		"bus": out.append("bus_on_van_skeleton")
		"semi": out.append("tractor_on_pickup_skeleton")
		"boxtruck": out.append("box_body")
	var r := length_range(arch)
	if float(f.L) < r.x or float(f.L) > r.y: out.append("length_outside_range")
	return out

## Which of the spec's fourteen class quotas a car counts toward.
static func quota_class(spec: Dictionary) -> String:
	var f := facts(spec)
	var cls: String = f["class"]
	var arch := of(spec)
	if cls in ["fleet", "work_truck"]: return "utility_service"
	if cls == "exotic": return "super_exotic"
	if cls == "luxury" and not arch in ["crossover_compact", "suv_midsize", "suv_fullsize"]: return "luxury"
	if cls == "offroad": return "offroad"
	match arch:
		"micro_fwd", "compact_fwd": return "compact_economy"
		"hatch_fwd": return "hatchback"
		"sedan_compact", "sedan_midsize", "sedan_fullsize": return "sedan"
		"coupe_compact", "coupe_gt": return "coupe"
		"muscle_longhood": return "muscle"
		"sports_frontengine", "sports_midengine": return "sports"
		"exotic_wedge": return "super_exotic"
		"wagon_compact", "wagon_fullsize": return "wagon"
		"crossover_compact", "suv_midsize", "suv_fullsize": return "suv_crossover"
		"offroad_short": return "offroad"
		"pickup_compact", "pickup_half_ton", "pickup_heavy": return "pickup"
		"van_cargo", "van_passenger", "minivan": return "van_minivan"
		"utility_tow": return "utility_service"
	return "sedan"

## "1990s" for a 1991 car.
static func era(year: int) -> String:
	return "%ds" % (year / 10 * 10)

## The spec's era quota a year counts toward ("1950-1969" ... "2010-2019"); "" past 2019.
static func era_band(year: int) -> String:
	if year < 1970: return "1950-1969"
	if year >= 2020: return ""
	var d := year / 10 * 10
	return "%d-%d" % [d, d + 9]
