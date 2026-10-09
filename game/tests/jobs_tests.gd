## Evening jobs: pay, hours, the bracket rules, and that every place a job sends you is a real
## stretch of road you can route to.  godot --headless --path game -s tests/jobs_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func lane(dial: float, rt: float, et: float, red := false) -> Dictionary:
	return { "dial": dial, "rt": rt, "et": et, "red": red }

func _init() -> void:
	# pay
	var hot := Jobs.pizza_pay(-5.0, 30.0, 1.0)
	var late := Jobs.pizza_pay(30.0, 30.0, 1.0)
	var mush := Jobs.pizza_pay(0.0, 30.0, 0.0)
	check("pizza: on time and perfect pays $16", int(hot.total) == 16, str(hot))
	check("pizza: a full grace late is just the $2 tip", int(late.tip) == 2, str(late))
	check("pizza: a wrecked pizza gets the minimum tip", int(mush.tip) == 2, str(mush))
	check("pizza: longer routes get more time", Jobs.pizza_limit(2000.0) > Jobs.pizza_limit(500.0) + 100.0)
	check("tow: $90 + $2.50/km + night + weather", Jobs.tow_pay(10.0, true, true) == 215, "%d" % Jobs.tow_pay(10.0, true, true))
	# hours
	check("pizza opens at five and shuts at eleven", Jobs.open_now("pizza", 17.5) and not Jobs.open_now("pizza", 23.5) and not Jobs.open_now("pizza", 12.0))
	check("drag night runs past midnight", Jobs.open_now("drag", 1.0) and Jobs.open_now("drag", 22.0) and not Jobs.open_now("drag", 12.0))
	check("tow calls never close", Jobs.open_now("tow", 3.0) and Jobs.open_now("tow", 15.0))
	# bracket rules
	var a := lane(9.50, 0.20, 9.55)
	var b := lane(11.00, 0.30, 11.05)
	check("handicap start: the closer run to the dial wins", int(Jobs.drag_winner(a, b).lane) == 0, str(Jobs.drag_winner(a, b)))
	check("breaking out loses", int(Jobs.drag_winner(lane(9.5, 0.1, 9.40), lane(11.0, 0.5, 11.3)).lane) == 1)
	check("a red light loses", int(Jobs.drag_winner(lane(9.5, -0.01, 9.5, true), lane(11.0, 0.9, 12.0)).lane) == 1)
	check("both break out: the smaller breakout wins", int(Jobs.drag_winner(lane(9.5, 0.1, 9.40), lane(11.0, 0.1, 10.95)).lane) == 1)
	var purse := Jobs.drag_purse(Jobs.LADDER.size() - 1)
	check("the top of the ladder pays the most", int(purse.win) > int(Jobs.drag_purse(0).win) * 5, str(purse))
	# the ladder's cars are real catalogue cars, getting quicker as you climb
	var last := 99.0
	var order_ok := true
	for r in Jobs.LADDER:
		if not CarCatalog.has(String(r.car)):
			order_ok = false
			continue
		var e := float(Perf.estimate(CarCatalog.spec(String(r.car))).eighth)
		if e > last + 0.3: order_ok = false
		last = e
	check("ladder cars exist and get quicker", order_ok)
	var p := Perf.estimate(SaveGame.load_spec("silvio"))
	check("perf has the eighth mile and the 60-foot", float(p.eighth) > 5.0 and float(p.sixty) > 1.0 and float(p.eighth) < float(p.quarter))
	# places
	var map := MapData.get_map()
	var shop := Jobs.pizza_shop(map)
	check("Pizza Delirium is on a road", not (shop.building as Dictionary).is_empty() and map.ground_at(shop.p) == "asphalt", str(shop.p))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bad: Array = []
	var n := 0
	for i in 6:
		for s in Jobs.addresses(map, rng, shop.p, 3):
			n += 1
			if map.ground_at(s.p) != "asphalt" or map.route(shop.p, s.p).size() < 2: bad.append(s.label)
	check("pizza addresses are on roads and routable", n >= 12 and bad.is_empty(), "%d addresses, bad %s" % [n, str(bad)])
	var bad_tow: Array = []
	for i in 12:
		var spot := Jobs.tow_spot(map, rng, Jobs.COVINGTON)
		if spot.is_empty() or map.route(Jobs.COVINGTON, spot.road_p).size() < 2 or not map.ground_at(spot.road_p) in ["asphalt", "gravel"]:
			bad_tow.append(spot.get("road", "none"))
	check("tow calls are beside routable roads", bad_tow.is_empty(), str(bad_tow))
	check("the tow drop-offs are on roads", map.ground_at(Jobs.road_point(map, Jobs.COVINGTON)) == "asphalt" and map.ground_at(Jobs.road_point(map, Jobs.IMPOUND)) == "asphalt")
	check("runway 7 holds an eighth mile plus room to stop", DragStrip.RUNWAY.has_point(DragStrip.START) and DragStrip.RUNWAY.has_point(Vector2(DragStrip.LINE_X + DragStrip.EIGHTH + 100.0, 1016.0)))
	check("the strip is paved", map.ground_at(DragStrip.START) == "asphalt" and map.ground_at(Vector2(DragStrip.LINE_X + DragStrip.EIGHTH, 1016.0)) == "asphalt")
	var long_blurbs: Array = []
	for k in Jobs.ORDER:
		if Hud.wrap_lines(String(Jobs.KINDS[k].blurb).to_upper(), 38).size() > 2: long_blurbs.append(k)
	check("every gig's blurb fits its two lines on the phone", long_blurbs.is_empty(), str(long_blurbs))
	# street races
	check("street racing opens late", Jobs.open_now("street", 23.0) and Jobs.open_now("street", 2.0) and not Jobs.open_now("street", 20.0))
	check("Marco runs a different route every night", Jobs.street_route(0).id != Jobs.street_route(1).id and Jobs.street_route(4).id == Jobs.street_route(0).id)
	check("the winner takes the pot less Marco's tenth", StreetRace.purse(300, 4) == 1080, "%d" % StreetRace.purse(300, 4))
	for r in StreetRace.ROUTES:
		var pth := StreetRace.build_path(map, r)
		var L := 0.0
		var jumps := 0
		for i in pth.size() - 1:
			L += pth[i].distance_to(pth[i + 1])
			if map.road_at(pth[i].lerp(pth[i + 1], 0.5)).is_empty(): jumps += 1
		var direct := 0.0
		var wp: Array = r.pts
		for i in wp.size() - 1: direct += (wp[i] as Vector2).distance_to(wp[i + 1])
		if r.loop: direct += (wp[wp.size() - 1] as Vector2).distance_to(wp[0])
		var near := true
		for w in wp:
			var bd := INF
			for q in pth: bd = minf(bd, q.distance_to(w))
			if bd > 30.0: near = false
		check("route %s follows the roads through every waypoint" % r.id, pth.size() > 3 and jumps == 0 and near and L < direct * 1.35, "%.0f m (straight %.0f), %d off-road legs" % [L, direct, jumps])
		if r.loop: check("route %s comes back to the start" % r.id, pth[0].distance_to(pth[pth.size() - 1]) < 1.0)
	var rr := RandomNumberGenerator.new()
	rr.seed = 5
	var mine := SaveGame.load_spec("silvio")
	var field := StreetRace.pick_cars(rr, mine, 3)
	var close_ok := field.size() == 3
	for id in field:
		var ratio := StreetRace.hp_per_t(CarCatalog.spec(String(id))) / StreetRace.hp_per_t(mine)
		if ratio < 0.6 or ratio > 1.6: close_ok = false
	check("the field brings cars about as quick as yours", close_ok, str(field))
	# gas
	var st := FuelStop.find_stations(map)
	var st_bad: Array = []
	for s in st:
		var sp: Vector2 = s.p
		var lot := false
		for dy in [-6.0, 6.0]:
			if map.ground_at(sp + Vector2(0, dy)) == "asphalt": lot = true
		if not lot or map.route(Jobs.COVINGTON, sp).size() < 2: st_bad.append(s.name)
	check("four places to buy gas, paved and routable", st.size() >= 4 and st_bad.is_empty(), "%d, bad %s" % [st.size(), str(st_bad)])
	var named := 0
	for l in map.landmarks:
		if String(l.name).begins_with("GAS BAR") or String(l.name).begins_with("ULTRAMARGE") or String(l.name) == "THE BIG STOP": named += 1
	check("the gas stations are on the GPS", named >= 4, "%d" % named)
	check("the till rounds up to the dollar", FuelStop.bill(10.0, false) == 17 and FuelStop.bill(10.0, true) == 19, "%d, %d" % [FuelStop.bill(10.0, false), FuelStop.bill(10.0, true)])
	# moose and deer
	check("no moose downtown", Wildlife.odds(19.0, "fall", "street", "downtown") == 0.0 and Wildlife.odds(19.0, "fall", "arterial", "") == 0.0)
	check("dusk on a country road is when they're out", Wildlife.odds(19.0, "summer", "rural", "rural") > Wildlife.odds(13.0, "summer", "rural", "rural") * 5.0)
	check("the fall rut brings more out", Wildlife.odds(19.0, "fall", "highway", "") > Wildlife.odds(19.0, "summer", "highway", ""))
	var moose_n := 0
	for i in 1000:
		if Wildlife.pick_kind("fall", float(i) / 1000.0) == "moose": moose_n += 1
	check("deer are commoner than moose, even in the fall", moose_n > 200 and moose_n < 500, "%d in 1000" % moose_n)
	# police
	check("speed limits round like the signs", Police.limit_kmh("street") == 50.0 and Police.limit_kmh("arterial") == 60.0 and Police.limit_kmh("highway") == 100.0 and Police.limit_kmh("rural") == 80.0)
	check("a little over is a small ticket", Police.fine(25.0, ["speeding"]) == 180, "%d" % Police.fine(25.0, ["speeding"]))
	check("50 over is stunt driving: double", Police.fine(55.0, ["speeding"]) == 840, "%d" % Police.fine(55.0, ["speeding"]))
	check("racing and running cost more than speeding", Police.fine(0.0, ["racing", "fleeing"]) == 2500)
	check("racing gets the car impounded", Police.impounds(0.0, ["racing"], 0.0) and not Police.impounds(20.0, ["speeding"], 0.0))
	check("a long chase gets the car impounded", Police.impounds(10.0, ["speeding", "fleeing"], 60.0) and not Police.impounds(10.0, ["speeding", "fleeing"], 10.0))
	check("more heat, more patrol cars", Police.want_cruisers(90.0, "downtown", false) > Police.want_cruisers(0.0, "downtown", false) and Police.want_cruisers(0.0, "rural", false) == 0)
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
