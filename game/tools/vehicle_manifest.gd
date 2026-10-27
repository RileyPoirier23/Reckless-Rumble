## The vehicle art manifest (DEV ADDITIONS.md, "Vehicle Art Manifest"): one JSON file per car in
## data/vehicle_art/<vehicle_id>.json saying what an artist has to draw for it and where it goes.
## Shared by the tool that writes them (tools/build_vehicle_manifests.gd), the validator
## (tools/validate_vehicle_art.gd) and the tests (tests/vehicle_art_tests.gd), so all three agree.
##
## Nothing in a manifest is typed in by hand. The names, sizes and classes come off the car's
## spec (CarCatalog.spec), the archetype from VehicleArchetypes, and the anchors are measured off
## the car as the game draws it from above (CarArt at 12 px/m: where its wheels, bumpers, roof,
## exhaust tips and lamps actually are). The slots list what the body shop sells for that car
## and only what CarArt or CarGen actually draws on it: every option (the rims aside) is tried
## on the car and kept only if the picture changes. So a manifest can be rebuilt at any time and
## comes out the same, byte for byte.
class_name VehicleManifest
extends RefCounted

const SCHEMA_VERSION := 1
const DIR := "res://data/vehicle_art/"
const SHOWROOM_DIR := "res://art/vehicles/showroom/"
const RUNTIME_DIR := "res://art/vehicles/runtime/"
const SLICES := 16
const PPM := 12                     # CarArt.PX
const SHOWROOM_SIZE := Vector2i(256, 96)
const SHOWROOM_BASELINE := 78       # PixCars.SHOWROOM_BASELINE
const SHOWROOM_FOOTPRINT := Vector2i(224, 76)
const MAX_YEAR := 2019
const FACTORY := Color("8a8e94")    # the neutral factory paint the art is drawn in

## The paint masks every runtime car exports (masks/mask_<name>.png, the spec's naming), and the
## lamp masks (masks/light_<name>.png) that light up on their own.
const MASKS := ["paint", "accent", "trim", "glass", "decal"]
const LIGHT_MASKS := ["head", "brake", "reverse", "signal_left", "signal_right"]
## CarArt.lamp_spots' kinds, by number.
const LAMP_KINDS := ["brake", "reverse", "head", "signal_left", "signal_right", "beacon", "roof_bar"]

## The spec's slot names, mapped onto what the garage's LOOKS tab sells (ui/garage_screen.gd)
## and the looks each choice sets. The first value of each is the car as it comes. The body kit
## is one row in the garage (lip, lip + skirts, full) but three slots here: the lip is the front
## bumper's, the skirts the sills', the diffuser the rear bumper's. The wheels and the paint come
## last: the garage sells them on every car, but even they don't always show (whitewalls on a car
## that has them from the factory, racing stripes on one that came striped).
static func options() -> Array:
	var rims: Array = [["stock", {}]]
	for r: String in PixCars.RIMS: rims.append([r, { "rim": r }])
	var tires: Array = []
	for t: String in CarGen.TIRES: tires.append([t, {} if t == "stock" else { "tire": t }])
	var fits_: Array = []
	for f: String in CarGen.FITMENTS: fits_.append([f, {} if f == "stock" else { "offset": f }])
	return [
		["front_bumper", [["stock", {}], ["lip", { "kit": { "lip": true } }], ["bash_bar", { "bash": true }]]],
		["rear_bumper", [["stock", {}], ["diffuser", { "kit": { "diffuser": true } }], ["spare", { "spare": true }]]],
		["side_skirt", [["stock", {}], ["skirts", { "kit": { "skirts": true } }]]],
		["spoiler", _row("spoiler", GarageScreen.SPOILERS)],
		["hood", _row("hood", GarageScreen.HOODS)],
		["fenders", _row("fenders", GarageScreen.FENDERS)],
		["lights", [["stock", {}], ["halo", { "halo": true }], ["smoked", { "smoked": true }]]],
		["exhaust", _row("exhaust", GarageScreen.EXHAUSTS)],
		["roof", _row("roof", GarageScreen.ROOFS)],
		["bed", _row("bed", GarageScreen.BEDS)],
		["wheel_family", rims],
		["tire", tires],
		["fitment", fits_],
		["stagger", _row("stagger", GarageScreen.STAGGERS)],
		["finish", _row("finish", GarageScreen.FINISHES)],
		["livery", _row("livery", GarageScreen.LIVERIES)],
		["stripes", _row("stripes", GarageScreen.STRIPES)],
	]

static func _row(key: String, values: Array) -> Array:
	var out: Array = []
	for i in values.size():
		out.append([String(values[i]), {} if i == 0 else { key: values[i] }])
	return out

## Every value a slot can ever hold, for the validator.
static func vocabulary() -> Dictionary:
	var out := {}
	for pair: Array in options():
		var vals: Array = []
		for o: Array in pair[1]: vals.append(o[0])
		out[pair[0]] = vals
	return out

## The looks a slot's value puts on the car, or null if the slot has no such value.
static func looks_of(slot: String, value: String) -> Variant:
	for pair: Array in options():
		if pair[0] != slot: continue
		for o: Array in pair[1]:
			if o[0] == value: return o[1]
	return null

## The garage's own rules for what fits a car at all (GarageScreen._look_fits): a bed on a
## pickup (not the wrecker), a spare on a truck or a 4x4, no bull bar on a sports car.
static func fits(spec: Dictionary, slot: String, value: String) -> bool:
	var fam := String(CarGen.design(spec).family)
	if slot == "bed" and value != "stock": return fam == "pickup" and String(spec.get("body", "")) != "tow"
	if value == "spare": return fam in ["pickup", "suv", "offroad"]
	if value == "bash_bar": return not fam in ["sports", "mid", "wedge", "roadster", "bubble"]
	return true

# ------------------------------------------------------------------ which cars

## Every car that gets a manifest: the catalogue (hand-made cars first), the fleet, then any
## other hand-made car in data/cars (the ambulance and the fire engine the incidents send).
static func car_ids() -> Array:
	var out: Array = CarCatalog.ids() + CarCatalog.fleet_ids()
	var files := Array(DirAccess.get_files_at("res://data/cars"))
	files.sort()
	for f: String in files:
		if not f.ends_with(".json"): continue
		var id := f.get_basename()
		if not out.has(id): out.append(id)
	return out

static func spec_of(car_id: String) -> Dictionary:
	return CarCatalog.spec(car_id)

static func path_of(vehicle_id: String) -> String:
	return DIR + vehicle_id + ".json"

static func to_text(m: Dictionary) -> String:
	return JSON.stringify(m, "\t", false) + "\n"

# ------------------------------------------------------------------ one car

## What people write into a manifest by hand: who drew it, who reviewed it, whether it's
## approved, which files may keep soft edges. A rebuild keeps them.
const HAND_KEYS := [["review", "artist"], ["review", "reviewer"], ["review", "approved"], ["art", "alpha_whitelist"]]

## The manifest for a car as the tool writes it: measured off the car, with the hand-written
## fields carried over from the one on disk.
static func rebuild(car_id: String) -> Dictionary:
	var m := build(car_id)
	if m.is_empty(): return m
	var path := path_of(String(m.vehicle_id))
	if not FileAccess.file_exists(path): return m
	var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not old is Dictionary: return m
	for k: Array in HAND_KEYS:
		var sec: Variant = (old as Dictionary).get(k[0])
		if sec is Dictionary and (sec as Dictionary).has(k[1]): m[k[0]][k[1]] = sec[k[1]]
	return m

## The manifest for a car, measured off it.
static func build(car_id: String) -> Dictionary:
	var spec := spec_of(car_id)
	if spec.is_empty(): return {}
	var vid := PixCars.art_id(spec)
	var e := CarCatalog.entry(car_id)
	var year := int(spec.get("year", 0))
	var arch := VehicleArchetypes.of(spec)
	var cls := String(VehicleArchetypes.facts(spec)["class"])
	var art := CarArt.new(spec, FACTORY, 0.0, 1, 1.0, {})
	return {
		"schema_version": SCHEMA_VERSION,
		"vehicle_id": vid,
		"car_id": car_id,
		"display": {
			"make": String(spec.get("make", "")),
			"model": String(spec.get("model", "")),
			"trim": String(spec.get("trim", "")),
			"year": year,
		},
		"classification": {
			"class": cls,
			"body": String(spec.get("body", "")),
			"era": VehicleArchetypes.era(year),
			"era_band": VehicleArchetypes.era_band(year),
			"archetype": arch,
			"archetype_exceptions": VehicleArchetypes.exceptions(spec),
			"quota_class": VehicleArchetypes.quota_class(spec),
		},
		"dimensions_m": {
			"length": _m(float(spec.get("length", 0.0))),
			"width": _m(float(spec.get("width", 0.0))),
			"wheelbase": _m(float(spec.get("wheelbase", 0.0))),
			"track": _m(float(spec.get("track", 0.0))),
		},
		"art": {
			"showroom": SHOWROOM_DIR + vid + ".png",
			"runtime_dir": RUNTIME_DIR + vid,
			"slice_count": art.n,                # (the painter stands a car as many slices as its height wants: 14 to 46)
			"front_axis": "+x",
			"pixels_per_metre": PPM,
			"showroom_size": [SHOWROOM_SIZE.x, SHOWROOM_SIZE.y],
			"showroom_baseline_y": SHOWROOM_BASELINE,
			"alpha_whitelist": [],
		},
		"anchors": anchors(spec, art),
		"slots": slots(spec, art),
		"masks": MASKS.duplicate(),
		"light_masks": LIGHT_MASKS.duplicate(),
		"review": {
			"reference_notes": notes(spec, e, arch),
			"artist": "",
			"reviewer": "",
			"approved": false,
		},
	}

static func _m(v: float) -> float:
	return snappedf(v, 0.001)

## Where things are on the car, in metres from its centre (+x the nose, +y its right side), off
## the top-down art at 12 px/m: the axles where CarArt put the wheels (a semi tractor's tandem
## is one rear axle at its middle, rear_axles_m lists both), the bumpers at the ends of the art's
## length, the roof's slice, the side the exhaust tips come out, every lamp.
static func anchors(spec: Dictionary, art: CarArt = null) -> Dictionary:
	if art == null: art = CarArt.new(spec, FACTORY, 0.0, 1, 1.0, {})
	var ppm := art.px
	var front := 0.0
	for v: Vector2 in art.wheel_spots: front += v.x
	front /= maxf(1.0, float(art.wheel_spots.size()))
	# the back axle: a tractor's tandem counts as one, at its middle
	var xs: Array = []
	for w: Array in art.wheel_rears:
		var x := snappedf((w[0] as Vector2).x, 0.01)
		if not xs.has(x): xs.append(x)
	xs.sort()
	var rear := 0.0
	var rears: Array = []
	for x: float in xs:
		rear += x
		rears.append(_m(x / ppm))
	rear /= maxf(1.0, float(xs.size()))
	var track := 0.0
	if art.wheel_spots.size() >= 2: track = absf(art.wheel_spots[1].y - art.wheel_spots[0].y)
	var radius := 0.0
	if not art.wheel_rears.is_empty(): radius = (art.wheel_rears[0][1] as Vector2).x / 2.0
	var lamps: Array = []
	for l: Array in art.lamp_spots:
		var at: Vector3 = l[1]
		lamps.append({ "kind": LAMP_KINDS[clampi(int(l[0]), 0, LAMP_KINDS.size() - 1)],
			"x_m": _m(at.x / ppm), "y_m": _m(at.y / ppm), "slice": snappedf(at.z, 0.01) })
	return {
		"front_axle_m": _m(front / ppm),
		"rear_axle_m": _m(rear / ppm),
		"rear_axles_m": rears,
		"front_bumper_m": _m(art.length_px / 2.0 / ppm),
		"rear_bumper_m": _m(-art.length_px / 2.0 / ppm),
		"track_m": _m(track / ppm),
		"wheel_radius_m": _m(radius / ppm),
		"roof_z_slice": int(round(art.roof_z)),
		"procedural_slices": art.n,
		"exhaust_side": exhaust_side(spec),
		"lamps": lamps,
	}

## Which way the exhaust comes out, found by drawing the car with and without its tips and
## seeing where the pixels went: rear_right, rear_left, rear_both, side_both or hidden.
static func exhaust_side(spec: Dictionary) -> String:
	var with_tips := _plan(spec, {})
	var without := _plan(spec, { "exhaust": "none" })
	var left := false
	var right := false
	var side := false
	for y in with_tips.sy:
		for x in with_tips.sx:
			var i := with_tips.idx(x, y)
			if with_tips.h0[i] == without.h0[i] and with_tips.m0[i] == without.m0[i]: continue
			if float(x) > float(CarArt.MX) + with_tips.lpx * 0.15: side = true
			elif float(y) + 0.5 < with_tips.cy: left = true
			else: right = true
	if side: return "side_both"
	if left and right: return "rear_both"
	if right: return "rear_right"
	if left: return "rear_left"
	return "hidden"

static func _plan(spec: Dictionary, mods: Dictionary) -> CarArt.Plan:
	var m := CarGen.looks(mods)
	var z := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
	return CarArt.plan_of(spec, m, z, 1.0, CarGen.design(spec), CarArt._plan_key(spec, m, z, 1.0))

## The looks a slot's value really puts on a car: the save's own translation (a bed's roll bar
## is the side view's rollbar, a roof light bar its lightbar).
static func applied(looks: Dictionary) -> Dictionary:
	return SaveGame.car_looks({ "looks": looks.duplicate(true), "parts": {} })

## The slots for a car: for each, the stock value and every other value the garage would fit
## and that changes how the car looks. Each option is tried on the car, cheapest look first:
## does its shape from above change (CarArt's plan), do its slices, wheels or lamps from above
## change (CarArt, painted), does its side view change at the showroom's scale (CarGen: raised
## white letters only show that big). Left out if none does.
## The rims are the one shortcut: every car shows its wheels, so every rim but the factory one
## (that's "stock") shows; the tests try them all on one car of every archetype.
static func slots(spec: Dictionary, art: CarArt = null) -> Dictionary:
	if art == null: art = CarArt.new(spec, FACTORY, 0.0, 1, 1.0, {})
	var z := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
	var d := CarGen.design(spec)
	var base_key := CarArt._plan_key(spec, {}, z, 1.0)
	var base_sig := _sig(_plan(spec, {}))
	var side_len := mini(224, int(float(spec.get("length", 4.6)) * 38.0))     # tools/export_showroom.gd's scale
	var side0 := PackedByteArray()
	var base_pics: Array = []
	var stock_rim := String(d.get("rim_style", ""))
	var out := {}
	for pair: Array in options():
		var slot: String = pair[0]
		var vals: Array = []
		for o: Array in pair[1]:
			var value: String = o[0]
			if vals.is_empty():
				vals.append(value)
				continue
			if not fits(spec, slot, value): continue
			if slot == "wheel_family":
				if value != stock_rim: vals.append(value)
				continue
			var m := applied(o[1])
			var shows := false
			if CarArt._plan_key(spec, CarGen.looks(m), z, 1.0) != base_key: shows = _sig(_plan(spec, m)) != base_sig
			if not shows:
				if base_pics.is_empty(): base_pics = _pictures(art)
				shows = _pictures(CarArt.new(spec, FACTORY, 0.0, 1, 1.0, m)) != base_pics
			if not shows:
				if side0.is_empty(): side0 = CarGen.render(side_len, d, FACTORY, { "shadow": false }).get_data()
				var sm := m.duplicate()
				sm.shadow = false
				shows = CarGen.render(side_len, d, FACTORY, sm).get_data() != side0
			if shows: vals.append(value)
		out[slot] = vals
	return out

static func _sig(p: CarArt.Plan) -> int:
	return hash([p.sx, p.sy, p.n, p.h0, p.b0, p.m0, p.h1, p.b1, p.m1, p.h2, p.b2, p.m2])

## Everything a car's top-down art is: the slices, the front wheel's stack, the lamps.
static func _pictures(a: CarArt) -> Array:
	var out: Array = [a.size, a.n, a.atlas.get_image().get_data(), a.wheel_tex.get_image().get_data()]
	for lk: String in ["head", "brake", "rev", "bl", "br", "bar"]: out.append(a.lamp_tex[lk].get_image().get_data())
	return out

## One line for the artist: what the car is, the parody rule, and the catalogue's own blurb.
static func notes(spec: Dictionary, e: Dictionary, arch: String) -> String:
	var year := int(spec.get("year", 0))
	var cls := String(VehicleArchetypes.facts(spec)["class"]).replace("_", " ")
	var body := String(spec.get("body", "")).replace("_", " ")
	var blurb := String(e.get("blurb", spec.get("blurb", ""))).replace("\n", " ").strip_edges()
	return "Fictional parody: a %s %s %s on the %s archetype; original badges, grille and lamp graphics, no real logos or liveries. %s" % [
		VehicleArchetypes.era(year), cls, body, arch, blurb]
