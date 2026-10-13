## The car catalogue: godot --headless --path game -s tests/catalog_tests.gd
extends SceneTree

var fails := 0

## Real makes and well-known real models that must never appear as-is (whole words).
const REAL := ["FORD", "TOYOTA", "HONDA", "NISSAN", "CHEVROLET", "CHEVY", "DODGE", "BMW", "MERCEDES", "BENZ",
	"VOLKSWAGEN", "VW", "AUDI", "PORSCHE", "FERRARI", "LAMBORGHINI", "SUBARU", "MAZDA", "MITSUBISHI", "HYUNDAI",
	"KIA", "VOLVO", "SAAB", "JEEP", "GMC", "CADILLAC", "BUICK", "PONTIAC", "CHRYSLER", "PLYMOUTH", "LINCOLN",
	"MERCURY", "TESLA", "JAGUAR", "FIAT", "PEUGEOT", "RENAULT", "CITROEN", "LADA", "SKODA", "SUZUKI", "ISUZU",
	"LEXUS", "ACURA", "INFINITI", "BUGATTI", "MCLAREN", "BENTLEY", "MASERATI", "DELOREAN", "HUMMER",
	"OLDSMOBILE", "DATSUN", "TRABANT", "YUGO", "OPEL", "DAEWOO", "STUDEBAKER", "KOENIGSEGG", "PAGANI", "DAIHATSU",
	"COROLLA", "CAMRY", "CIVIC", "ACCORD", "MUSTANG", "CAMARO", "CORVETTE", "SILVIA", "SKYLINE", "SUPRA",
	"CHARGER", "CHALLENGER", "SILVERADO", "TACOMA", "HILUX", "WRANGLER", "BRONCO", "BEETLE", "GOLF", "JETTA",
	"MIATA", "COUNTACH", "TESTAROSSA", "VEYRON", "IMPALA", "CAPRICE", "EXPLORER", "FOCUS", "FIESTA", "TAURUS",
	"PRIUS", "OUTBACK", "FORESTER", "IMPREZA", "LANCER", "ECLIPSE", "INTEGRA", "VIPER", "PINTO", "GREMLIN",
	"CARAVAN", "ODYSSEY", "SIENNA", "ELANTRA", "SENTRA", "ALTIMA", "MAXIMA", "CHEROKEE", "DURANGO", "TUNDRA",
	"ESCALADE", "SUBURBAN", "TAHOE", "YUKON"]

## Real names that are also ordinary words: only checked in makes and models, not in blurbs.
const COMMON := ["DODGE", "GOLF", "FOCUS", "ECLIPSE", "ODYSSEY", "CHALLENGER", "CHARGER", "EXPLORER", "MERCURY",
	"BEETLE", "VIPER", "ACCORD", "OUTBACK", "FORESTER", "MUSTANG", "PINTO", "GREMLIN", "CARAVAN", "SUBURBAN", "FIESTA"]
## What the sim reads from a spec.
const SIM_KEYS := ["mass", "wheelbase", "cg_front", "cg_height", "track", "length", "width", "cda", "steer_lock",
	"engine", "gearbox", "tires", "brakes", "drivetrain"]

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var ids := CarCatalog.ids()
	check("hundreds of cars", ids.size() >= 300, "%d" % ids.size())
	var bad_id: Array = []
	var seen := {}
	var real: Array = []
	for id in ids:
		if seen.has(id) or CarCatalog.slug(String(id)) != String(id): bad_id.append(id)
		seen[id] = true
		var e := CarCatalog.entry(id)
		for part in ["name", "blurb"]:
			var words := ("%s %s" % [e.get("make", ""), e.get("model", "")]).to_upper() if part == "name" else String(e.get("blurb", "")).to_upper()
			for ch in ".,;:!?()'\"/-":
				words = words.replace(ch, " ")
			var split := words.split(" ", false)
			for w in REAL:
				if w in split and (part == "name" or not w in COMMON): real.append("%s: %s" % [id, w])
	check("ids are unique snake_case", bad_id.is_empty(), str(bad_id.slice(0, 5)))
	check("no real makes or models", real.is_empty(), str(real.slice(0, 8)))
	# every spec builds and drives; a sample gets a proper run
	var keys: Array = SIM_KEYS
	var missing: Array = []
	var broken: Array = []
	var k := 0
	for id in ids:
		var s := CarCatalog.spec(id)
		for key in keys:
			if not s.has(key): missing.append("%s.%s" % [id, key])
		if k % 6 == 0:
			var c := CarSim.new(s)
			c.set_ambient(20.0)
			c.coolant_c = 88.0
			c.oil_c = 95.0
			for i in 360: c.step(1.0 / 60.0, 1.0, 0.0, 0.0, 0.0)
			if is_nan(c.vx) or c.vx * 3.6 < 15.0: broken.append("%s %.0f km/h" % [id, c.vx * 3.6])
		k += 1
	check("every spec has the hand-made cars' keys", missing.is_empty(), str(missing.slice(0, 6)))
	check("cars drive (a sixth of them, 6 s flat out, 15 km/h even for a bubble car)", broken.is_empty(), str(broken.slice(0, 6)))
	# saves can hold catalogue cars
	var other: String = ids[ids.size() - 1]
	check("load_spec falls back to the catalogue", SaveGame.load_spec(other).get("id", "") == other, other)
	# traffic by zone: valid cars, and more pickups out in the country than downtown
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trucks := { "rural": 0, "downtown": 0 }
	var bad_t: Array = []
	for zone in ["rural", "downtown"]:
		for i in 400:
			var t := CarCatalog.random_traffic(rng, zone)
			if float(t.get("length", 0.0)) < 2.4 or not t.has("body") or not t.has("paint"): bad_t.append(t.get("id", "?"))
			if String(t.get("body", "")) == "pickup": trucks[zone] = int(trucks[zone]) + 1
	check("traffic picks are valid cars", bad_t.is_empty(), str(bad_t.slice(0, 5)))
	check("more pickups in the country than downtown", int(trucks.rural) > int(trucks.downtown), "rural %d, downtown %d of 400" % [int(trucks.rural), int(trucks.downtown)])
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
