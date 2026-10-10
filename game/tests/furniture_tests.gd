## The road furniture: signals, stop signs, streetlights, limits, warnings, and the junction rules
## you can break:  godot --headless --path game -s tests/furniture_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var map := MapData.get_map()
	var tr := Traffic.new()
	tr.classify(map)
	var fx := RoadFurniture.new()
	var t0 := Time.get_ticks_msec()
	fx.build(map, tr)
	var ms := Time.get_ticks_msec() - t0
	print("built in %d ms: %s" % [ms, str(fx.counts)])
	check("it builds quickly", ms < 2500, "%d ms" % ms)
	for k in ["signal", "stop", "limit", "warn", "chevron", "light", "wild", "exit"]:
		check("there are %s items" % k, int(fx.counts.get(k, 0)) > 0, str(fx.counts.get(k, 0)))
	var all: Array = []
	for k in fx.cells: all.append_array(fx.cells[k])
	var icons := {}
	for it in all:
		if String(it.kind) == "warn": icons[String(it.icon)] = int(icons.get(String(it.icon), 0)) + 1
	print("warnings: ", icons)
	check("there are merge warnings", int(icons.get("merge_l", 0)) + int(icons.get("merge_r", 0)) > 0)
	for ic in ["curve_l", "curve_r", "turn_l", "turn_r", "lane_ends", "signal_ahead", "stop_ahead", "rail"]:
		check("there are %s warnings" % ic, int(icons.get(ic, 0)) > 0, str(icons.get(ic, 0)))
	# every approach to every signal junction has its own signal, facing it, in its group
	var missing := 0
	var sig_j := 0
	for n in tr.junctions:
		var j: Dictionary = tr.junctions[n]
		if String(j.control) != "signal": continue
		sig_j += 1
		var want := 0
		for e in map.g_adj[n]:
			if String(e[2].cls) != "highway": want += 1
		var got := 0
		for it in fx.items_near(map.g_pos[n], 40.0):
			if String(it.kind) == "signal" and int(it.n) == n: got += 1
		if got != want: missing += 1
	check("every way into a signal junction has its signal", missing == 0 and sig_j > 0, "%d of %d junctions short" % [missing, sig_j])
	# both groups exist: the main road's and the side roads'
	var groups := {}
	for it in all:
		if String(it.kind) == "signal": groups[int(it.group)] = true
	check("main-road and side-road signals", groups.has(0) and groups.has(1))
	# signs stand off the road (not in a lane) and not inside a building
	var on_road := 0
	var in_bldg := 0
	var signs := 0
	for it in all:
		if String(it.kind) in ["light", "chevron", "wild"]: continue
		signs += 1
		var hit: Dictionary = map.road_at(it.p)
		if not hit.is_empty() and float(hit.dist) < float(hit.road.w) / 2.0 - 0.3: on_road += 1
		for b in map.buildings:
			if (b.r as Rect2).grow(0.3).has_point(it.p):
				in_bldg += 1
				print("   in a building: %s %s at %s (%s)" % [it.kind, it.get("icon", ""), str(it.p), b.kind])
				break
	print("signs %d: %d in a lane, %d in a building" % [signs, on_road, in_bldg])
	check("no sign stands in a lane", on_road == 0, "%d" % on_road)
	check("no sign stands in a building", in_bldg == 0, "%d" % in_bldg)
	# no two signs on top of each other
	var close := 0
	for it in all:
		if String(it.kind) in ["light", "chevron", "signal"]: continue
		for o in fx.items_near(it.p, 3.0):
			if o != it and not String(o.kind) in ["light", "chevron"]: close += 1
	check("no two signs on one spot", close == 0, "%d" % (close / 2))
	# a speed limit says what the police go by
	var wrong := 0
	for it in all:
		if String(it.kind) != "limit": continue
		if int(it.kmh) != int(Police.limit_kmh(String(map.roads[int(it.road)].cls))): wrong += 1
	check("every limit sign says the road's limit", wrong == 0, "%d" % wrong)
	# the cycle
	Traffic.clock = 0.0
	check("main road green at the start of the cycle", Traffic.signal_state(0, 0) == "green" and Traffic.signal_state(0, 1) == "red")
	Traffic.clock = 30.0
	check("side road green later", Traffic.signal_state(0, 1) == "green" and Traffic.signal_state(0, 0) == "red")
	check("red for 5 s", absf(Traffic.signal_since(0, 0) - 5.0) < 0.01, str(Traffic.signal_since(0, 0)))
	Traffic.clock = 1.0
	check("the side road's red counts from the cycle before", absf(Traffic.signal_since(0, 1) - 3.0) < 0.01, str(Traffic.signal_since(0, 1)))
	# the rules: find a signal junction and a stop sign, and drive into them
	var sn := -1
	for n in tr.junctions:
		if String(tr.junctions[n].control) == "signal":
			sn = n
			break
	var j: Dictionary = tr.junctions[sn]
	var maj_from := -1
	var min_from := -1
	for e in map.g_adj[sn]:
		if (j.majors as Array).has(int(e[2].idx)): maj_from = e[0]
		elif String(e[2].cls) != "highway": min_from = e[0]
	var vin := (map.g_pos[sn] - map.g_pos[maj_from]).normalized() * 12.0
	# main road red for 5 s
	Traffic.clock = 30.0 - float(j.offset)
	check("through a red on the main road", fx.violation(sn, map.g_pos[sn], vin, false) == "red_light", fx.violation(sn, map.g_pos[sn], vin, false))
	check("stopped first, then went (a right on red): fine", fx.violation(sn, map.g_pos[sn], vin, true) == "")
	check("creeping in: fine", fx.violation(sn, map.g_pos[sn], vin.normalized() * 1.0, false) == "")
	Traffic.clock = 10.0 - float(j.offset)
	check("through the main road's green: fine", fx.violation(sn, map.g_pos[sn], vin, false) == "")
	Traffic.clock = 25.5 - float(j.offset)
	check("just after it went red: let off", fx.violation(sn, map.g_pos[sn], vin, false) == "")
	if min_from >= 0:
		var vside := (map.g_pos[sn] - map.g_pos[min_from]).normalized() * 12.0
		Traffic.clock = 10.0 - float(j.offset)
		check("the side road's red while the main road's green", fx.violation(sn, map.g_pos[sn], vside, false) == "red_light")
	var pn := -1
	var p_minor := -1
	var p_major := -1
	for n in tr.junctions:
		var pj: Dictionary = tr.junctions[n]
		if String(pj.control) != "priority": continue
		var hwy := false
		for e in map.g_adj[n]:
			if String(e[2].cls) in ["highway", "ramp"]: hwy = true
		if hwy: continue
		for e in map.g_adj[n]:
			if (pj.majors as Array).has(int(e[2].idx)): p_major = e[0]
			else: p_minor = e[0]
		if p_minor >= 0 and p_major >= 0:
			pn = n
			break
	check("there's a stop-sign junction to try", pn >= 0)
	if pn >= 0:
		var vmin := (map.g_pos[pn] - map.g_pos[p_minor]).normalized() * 8.0
		var vmaj := (map.g_pos[pn] - map.g_pos[p_major]).normalized() * 8.0
		check("rolling the stop sign", fx.violation(pn, map.g_pos[pn], vmin, false) == "stop_sign")
		check("stopping at it: fine", fx.violation(pn, map.g_pos[pn], vmin, true) == "")
		check("the through road doesn't stop", fx.violation(pn, map.g_pos[pn], vmaj, false) == "")
		var has_stop := false
		for it in fx.items_near(map.g_pos[pn], 30.0):
			if String(it.kind) == "stop": has_stop = true
		check("and there's a stop sign there to see", has_stop)
	# the streetlights reach out over their street
	var armless := 0
	var lights := 0
	for it in all:
		if String(it.kind) != "light" or not it.src.has("arm"): continue
		lights += 1
		var tip: Vector2 = (it.p as Vector2) + (it.arm as Vector2) * 2.2
		if map.road_at(tip, 1.0).is_empty(): armless += 1
	check("streetlight arms reach over the road", lights > 0 and armless * 20 < lights, "%d of %d don't" % [armless, lights])
	fx.free()
	tr.free()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
