## MarketThing: listings, sellers, haggling, and the promise the desk makes too: every hidden
## fault can be caught at the meetup.  godot --headless --path game -s tests/market_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var map := MapData.get_map()
	var places := Market.places(map)
	check("meetup places exist", places.size() >= 6, "%d" % places.size())
	var bad_p: Array = []
	for p in places:
		if map.ground_at(p.p) != "asphalt" or map.route(Jobs.COVINGTON, p.p).size() < 2: bad_p.append(p.name)
	check("every meetup place is on a road you can route to", bad_p.is_empty(), str(bad_p))
	# listings
	var a := Market.listings_for_day(3, places.size())
	var b := Market.listings_for_day(3, places.size())
	check("6 to 10 listings a day, the same each time you look", a.size() >= 6 and a.size() <= 10 and JSON.stringify(a) == JSON.stringify(b), "%d" % a.size())
	var bad_ask: Array = []
	var all: Array = []
	for d in 40: all.append_array(Market.listings_for_day(d, places.size()))
	for l in all:
		var cents := int(l.ask) % 100
		if not cents in [0, 99, 69]: bad_ask.append(l.ask)
	check("asking prices end in 00, 99 or 69", bad_ask.is_empty(), str(bad_ask.slice(0, 5)))
	# every fault is provable at the meetup
	var unprovable: Array = []
	for f in Market.FAULTS:
		var checks: Array = Market.FAULTS[f].checks
		if checks.is_empty(): unprovable.append(f)
		for c in checks:
			var l := { "faults": [f], "km": 241000, "km_claimed": 140000, "checked": [] }
			if not (Market.inspect(l, String(c)).found as Array).has(f): unprovable.append("%s via %s" % [f, c])
	check("every hidden fault shows up on at least one check", unprovable.is_empty(), str(unprovable))
	var clean := Market.inspect({ "faults": [], "km": 1, "km_claimed": 1, "checked": [] }, "dipstick")
	check("a clean car checks out clean", (clean.found as Array).is_empty())
	# honesty
	var lied := 0
	var told := 0
	for l in all:
		var s: Dictionary = Market.SELLERS[String(l.seller)]
		if (l.faults as Array).is_empty(): continue
		if bool(s.honest) and not s.has("scam"): told += 1 if not (l.known as Array).is_empty() or (l.faults as Array) == ["rolled_odo"] else 0
		elif not (l.known as Array).is_empty(): lied += 1
	check("honest sellers say what's wrong; the rest never do", told > 0 and lied == 0, "told %d, dishonest disclosures %d" % [told, lied])
	# haggling
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var l1 := Market.listing("silvio", rng, 1, places.size())
	l1.seller = "flipper"
	l1.patience = 40
	check("full asking price is a yes", Market.offer(l1.duplicate(true), int(l1.ask), rng).kind == "yes")
	var lowl: Dictionary = l1.duplicate(true)
	var r1 := Market.offer(lowl, int(int(l1.ask) * 0.5), rng)
	check("a lowball gets a lowball reply and costs patience", r1.kind == "lowball" and int(lowl.patience) == 15)
	Market.offer(lowl, int(int(l1.ask) * 0.5), rng)
	check("enough lowballs and they ghost you", bool(lowl.ghosted))
	var sc: Dictionary = l1.duplicate(true)
	sc.seller = "scammer"
	check("the scammer wants a deposit", Market.offer(sc, 100, rng).kind == "scam")
	var yes_r := 0
	for i in 200:
		var lt: Dictionary = l1.duplicate(true)
		lt.seller = "grandma"
		lt.patience = 90
		if Market.offer(lt, int(int(l1.ask) * 0.96), rng).kind == "yes": yes_r += 1
	check("a fair offer to a fair seller often works", yes_r > 60, "%d of 200" % yes_r)
	# value
	check("more kilometres, less value", Market.value(10000.0, 300000, []) < Market.value(10000.0, 50000, []))
	check("faults cost value", Market.value(10000.0, 100000, ["head_gasket"]) < Market.value(10000.0, 100000, []) * 0.6)
	# buying: the car comes home with its faults
	var bought := { "car": "nissun_skylion_gee_tee_arr_1991", "paint": "#2a2a2e", "km": 210000, "faults": ["worn_clutch", "head_gasket"], "deal": 9000, "ask": 9500 }
	var entry := Market.to_garage(bought)
	var spec := SaveGame.car_spec(entry)
	var sim := CarSim.new(spec)
	sim.set_wear(entry.wear)
	check("bought cars bring their faults home", sim.clutch_cond < 0.3 and sim.head_gasket and not spec.is_empty(), "clutch %.2f" % sim.clutch_cond)
	check("selling gets a fair-ish offer", Market.sell_offer(entry, rng) > 0)
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
