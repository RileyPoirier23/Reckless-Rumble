## The long-play variety: the radio, the roadside breakdowns, the race routes and the text pools.
## godot --headless --path game -s tests/variety_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	# ---- the radio
	var lines := Radio.all_lines()
	check("the radio has plenty to say", lines.size() >= 100, "%d lines" % lines.size())
	var bad: Array[String] = []
	for l in lines:
		var lo := l.to_lower()
		for w in ["fag", "retard", " ford", "chevy", "toyota", "honda", "dodge", "walmart", "tim horton", "canadian tire "]:
			if lo.contains(w): bad.append(l)
	check("nothing on the radio is a slur or a real brand", bad.is_empty(), str(bad))
	var r := Radio.new()
	var sky := WorldSky.new(7)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var empty := 0
	var seen := {}
	for st in Radio.STATIONS:
		for wk in WorldSky.WEATHER.keys():
			for h in [6.0, 12.0, 17.0, 20.0, 23.5]:
				sky.weather = wk
				sky.time_h = h
				var l := r.pick(String(st.id), sky, { "heat": 60.0, "street": { "rep": 4 } }, rng)
				if l == "": empty += 1
				seen[l] = true
	check("every station has a line for every weather and hour", empty == 0, "%d empty" % empty)
	check("and they vary", seen.size() >= 60, "%d different lines" % seen.size())
	var about := 0
	for i in 60:
		var l := r.pick("bore", sky, { "heat": 80.0, "street": { "rep": 6 } }, rng)
		if Radio.ABOUT_YOU.heat.has(l) or Radio.ABOUT_YOU.rep.has(l): about += 1
	check("with the heat up and a name on the street, the Bore talks about you", about >= 6, "%d of 60" % about)
	r.free()
	# ---- the roadside
	var ids := {}
	for i in 200: ids[String(Roadside.pick_outcome(rng).id)] = true
	check("every roadside trouble comes up", ids.size() == Roadside.OUTCOMES.size(), str(ids.keys()))
	var gas := 0
	for i in 100: if String(Roadside.pick_outcome(rng, 5.0).id) == "gas": gas += 1
	check("no jerry can when you're nearly dry yourself", gas == 0, "%d" % gas)
	check("helping is a karma deed", Karma.DEEDS.has("helped") and float(Karma.DEEDS.helped[0]) > 0.0)
	for o in Roadside.OUTCOMES:
		for w in ["son", "sir", "boy"]:
			check("roadside: '%s' never calls Leo %s" % [String(o.id), w], not (" %s" % w.to_upper()) in String(o.text).replace("BOY", "BOY") or not String(o.text).contains(", %s" % w.to_upper()))
	# ---- the races
	check("six street race routes", StreetRace.ROUTES.size() >= 6, "%d" % StreetRace.ROUTES.size())
	var map := MapData.get_map()
	var off := 0
	for rt in StreetRace.ROUTES:
		check("route '%s' needs a rep" % String(rt.id), StreetRace.REP_NEED.has(String(rt.id)))
		for p in rt.pts:
			if map.nearest_road(p, 12.0).is_empty(): off += 1
	check("every route point is on a road", off == 0, "%d off" % off)
	var nights := {}
	for d in 14: nights[String(Jobs.street_route(d, 99).id)] = true
	check("Marco runs every route over a fortnight", nights.size() == StreetRace.ROUTES.size(), str(nights.keys()))
	# ---- the text pools
	check("twenty mornings at the counter", CounterScene.MORNINGS.size() >= 20, "%d" % CounterScene.MORNINGS.size())
	for k in Rides.TYPES:
		check("%s riders have a few things to say" % k, (Rides.TYPES[k].talk as Array).size() >= 3)
	check("the radio has a key", Controls.DEFAULTS.has("radio") and Controls.REBIND.any(func(r2): return r2[0] == "radio"))
	print("%d failed" % fails)
	quit(1 if fails > 0 else 0)
