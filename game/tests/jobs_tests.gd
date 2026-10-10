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
	# the meet
	var mfri := 4
	check("the meet: Friday and Saturday nights, and after midnight it's still the night before",
		Jobs.weekday(mfri) == "FRIDAY" and Jobs.meet_night(mfri, 23.0) and Jobs.meet_night(mfri + 1, 1.0) and Jobs.meet_night(mfri + 1, 23.0)
		and Jobs.meet_night(mfri + 2, 1.0) and not Jobs.meet_night(mfri + 2, 23.0) and not Jobs.meet_night(mfri - 1, 23.0))
	check("the board only opens it on those nights", Jobs.open_now("meet", 23.0, mfri) and not Jobs.open_now("meet", 23.0, mfri - 1) and not Jobs.open_now("meet", 15.0, mfri))
	var themes := {}
	for d in 7: themes[CarMeet.theme_for(d).id] = true
	check("a different theme every night of the week", themes.size() == CarMeet.THEMES.size(), str(themes.keys()))
	var tricked := { "finish": "chrome", "rim": "deepdish", "rim_size": 0.78, "drop": 0.8, "caliper": Color("#c8242c"), "tint": 0.5, "stripes": "racing",
		"spoiler": "gt", "kit": { "lip": true, "skirts": true, "diffuser": true }, "exhaust": "quad" }
	check("stock looks score nothing; a full kit and wheels score plenty", CarMeet.looks_pts({}) == 0.0 and CarMeet.looks_pts(tricked) > 12.0, "%.1f" % CarMeet.looks_pts(tricked))
	check("stance night counts the drop and the wheels double", CarMeet.looks_pts({ "drop": 1.0 }, true) == 2.0 * CarMeet.looks_pts({ "drop": 1.0 }))
	var built := { "intake": "intake_kandm", "exhaust": "exh_magnaflown", "tires": "tire_semi", "induction": "ind_upgrade" }
	check("the build counts the stages, up to a point", CarMeet.build_pts({}) == 0.0 and CarMeet.build_pts(built) > 2.0 and CarMeet.build_pts(built) <= 12.0, "%.1f" % CarMeet.build_pts(built))
	check("dents cost you", CarMeet.clean_pts({ "front": 0.5 }) < 0.0 and CarMeet.clean_pts({ "front": 1.0, "rear": 1.0, "left": 1.0 }) == -8.0)
	var anything: Dictionary = CarMeet.THEMES[0]
	var sleeper: Dictionary = CarMeet.THEMES.filter(func(x): return x.id == "sleeper")[0]
	var sv := SaveGame.load_spec("silvio")
	var shut := CarMeet.card(sv, {}, 8.0, {}, anything, 0.0, false)
	var open_c := CarMeet.card(sv, {}, 8.0, {}, anything, 0.0, true)
	check("keep the hood down and they only half-believe you", float(open_c.total) - float(shut.total) > 5.0, "%.1f vs %.1f" % [float(open_c.total), float(shut.total)])
	check("sleeper night: the shiny one loses to the plain fast one", float(CarMeet.card(sv, {}, 10.0, {}, sleeper, 0.0, true).total) > float(CarMeet.card(sv, tricked, 10.0, {}, sleeper, 0.0, true).total))
	var mr := RandomNumberGenerator.new()
	var wins_built := 0
	var wins_stock := 0
	var jdm_night: Dictionary = CarMeet.THEMES.filter(func(x): return x.id == "jdm")[0]
	var jdm_n := 0
	var names_ok := true
	for seed_i in 30:
		mr.seed = 900 + seed_i
		var ents := CarMeet.make_entrants(mr, anything if seed_i % 2 == 0 else jdm_night, 6, "silvio")
		var seen_n := {}
		for e in ents:
			if seen_n.has(e.name) or String(e.id) == "silvio" or CarCatalog.spec(String(e.id)).is_empty(): names_ok = false
			seen_n[e.name] = true
			if seed_i % 2 == 1 and String(CarCatalog.entry(String(e.id)).get("class", "")) == "jdm": jdm_n += 1
		var best := 0.0
		for e in ents: best = maxf(best, float(CarMeet.card(CarCatalog.spec(String(e.id)), e.looks, float(e.build), e.damage, anything, float(e.hype), true).total))
		if float(CarMeet.card(sv, tricked, 10.0, {}, anything, 2.5, true).total) > best: wins_built += 1
		if float(CarMeet.card(SaveGame.load_spec("silvio"), {}, 0.0, { "front": 0.4 }, anything, 0.0, false).total) > best: wins_stock += 1
	check("six locals, different people, real cars, never your own", names_ok)
	check("on JDM night the locals mostly bring JDM", jdm_n >= 40, "%d of 90" % jdm_n)
	check("a built, kitted car usually takes it; a dented stocker never does", wins_built >= 22 and wins_stock == 0, "%d / %d of 30" % [wins_built, wins_stock])
	# Northside Salvage
	var pile := SalvageYard.stock(12)
	var again := SalvageYard.stock(12)
	var n_part := pile.filter(func(it): return it.kind == "part").size()
	var n_wear := pile.filter(func(it): return it.kind == "wear").size()
	check("the yard's pile: six used parts and three worn bits, the same all day", n_part == 6 and n_wear == 3 and str(pile) == str(again), "%d + %d" % [n_part, n_wear])
	var cheap := true
	var a_dud := false
	var grades := {}
	for d in 40:
		for it in SalvageYard.stock(d):
			grades[int(it.grade)] = true
			if it.kind == "part":
				if int(it.price) >= Parts.price(String(it.id))  * 0.6: cheap = false
				if int(it.grade) == 0 and bool(it.dud): a_dud = true
			elif int(it.price) >= int(SalvageYard.WEAR[String(it.id)].gus): cheap = false
	check("used is cheaper than new, and cheaper than Gus fixing it", cheap)
	check("an A-grade part is never junk; every grade turns up", not a_dud and grades.size() == 4, str(grades.keys()))
	var duds := 0
	var d_parts := 0
	for d in 200:
		for it in SalvageYard.stock(d):
			if it.kind == "part" and int(it.grade) == 3:
				d_parts += 1
				if bool(it.dud): duds += 1
	check("a D-grade part is a lottery ticket", d_parts > 30 and duds > d_parts * 0.25 and duds < d_parts * 0.55, "%d of %d" % [duds, d_parts])
	check("Lloyd pays a fifth for what's on the bench", SalvageYard.offer("exh_magnaflown") == 140, "$%d" % SalvageYard.offer("exh_magnaflown"))
	var yard_lm := map.landmarks.filter(func(l): return l.name == "NORTHSIDE SALVAGE")
	var in_yard := map.buildings.filter(func(b): return (b.r as Rect2).intersects(MapData.SALVAGE))
	var only_ours := in_yard.all(func(b): return b.kind in ["shop", "junk"])
	check("the yard's on the GPS, a gravel lot of junk", yard_lm.size() == 1 and map.ground_at(SalvageYard.OFFICE) == "gravel" and only_ours and in_yard.size() >= 5,
		"%s, %d buildings" % [map.ground_at(SalvageYard.OFFICE), in_yard.size()])
	check("you can drive up to the trailer", map.route(Jobs.COVINGTON, SalvageYard.OFFICE).size() >= 2 and map.buildings.all(func(b): return not (b.r as Rect2).grow(2.0).has_point(SalvageYard.OFFICE)))
	# HOPP-IN
	var rr2 := RandomNumberGenerator.new()
	rr2.seed = 2
	var late_ok := true
	var day_ok := true
	for i in 200:
		var k1 := Rides.pick_type(1.0, rr2)
		if not k1 in ["party", "quiet"]: late_ok = false
		var k2 := Rides.pick_type(10.0, rr2)
		if k2 == "party": day_ok = false
	check("rides: bar crowd at 1 a.m., never at 10", late_ok and day_ok)
	check("rides: the fare goes by distance", Rides.fare(2000.0) > Rides.fare(500.0) + 10 and Rides.fare(0.0) >= 3, "%d vs %d" % [Rides.fare(2000.0), Rides.fare(500.0)])
	check("rides: smooth and on time is five stars", Rides.stars("nervous", 0.0, 0.0, 0, 0.0, false) == 5 and Rides.stars("hurry", 0.0, 0.0, 0, -30.0, false) == 5)
	check("rides: memere doesn't like being thrown about", Rides.stars("nervous", 2.5, 0.0, 0, 0.0, false) <= 2)
	check("rides: hit something and it shows", Rides.stars("quiet", 0.0, 0.0, 2, 0.0, false) <= 2)
	check("rides: late for the shift costs stars, speeding doesn't", Rides.stars("hurry", 0.0, 2000.0, 0, 60.0, false) <= 3 and Rides.stars("hurry", 0.0, 2000.0, 0, -30.0, false) == 5)
	check("rides: sick in the back is one star", Rides.stars("party", 0.0, 0.0, 0, 0.0, true) == 1)
	check("rides: five stars tips a fifth", Rides.tip(20, 5) == 4 and Rides.tip(20, 3) == 0)
	var rs := {}
	var gone := false
	for star_n in [5, 2, 1, 2]:
		gone = Rides.record(rs, star_n, 3) or gone
	check("rides: a run of bad ones and you're off for the day", gone and Rides.deactivated(rs, 3) and not Rides.deactivated(rs, 4), str(rs))
	# street rep and pink slips
	var gated := true
	for d in 8:
		if Jobs.street_route(d, 0).id != "main_mile": gated = false
	check("with no rep it's the Main Street Mile every night", gated)
	var ne_day := 3
	check("the North End needs rep 5; with 4 you get the Downtown Box", Jobs.street_route(ne_day).id == "northend" and Jobs.street_route(ne_day, 4).id == "downtown" and Jobs.street_route(ne_day, 5).id == "northend",
		"%s / %s / %s" % [Jobs.street_route(ne_day).id, Jobs.street_route(ne_day, 4).id, Jobs.street_route(ne_day, 5).id])
	var fri := 4
	check("pink slips: Friday and Saturday, with the rep", Jobs.weekday(fri) == "FRIDAY" and Jobs.pinks_tonight(fri, 6) and Jobs.pinks_tonight(fri + 1, 9) and not Jobs.pinks_tonight(fri, 5) and not Jobs.pinks_tonight(fri + 2, 9))
	check("rep: a win's one, pinks two, a loss nothing, a no-show costs one", StreetRace.rep_after(3, true, 1, false) == 4 and StreetRace.rep_after(3, true, 1, true) == 5 and StreetRace.rep_after(3, true, 3, false) == 3 and StreetRace.rep_after(3, false, 4, false) == 2 and StreetRace.rep_after(0, false, 4, false) == 0)
	var rv_ok := true
	var hpt: Array = []
	for i in StreetRace.RIVALS.size():
		var rid := StreetRace.rival_car(i)
		if not CarCatalog.has(rid): rv_ok = false
		else: hpt.append(StreetRace.hp_per_t(CarCatalog.spec(rid)))
	var climbing := true
	for i in range(1, hpt.size()): climbing = climbing and float(hpt[i]) >= float(hpt[i - 1])
	check("every pink-slip rival brings a real car, each quicker than the last", rv_ok and climbing, str(hpt))
	var line := Jobs.street_line({ "street": { "rep": 7, "pinks": 0 } }, fri)
	check("the phone says pink slips on the night", line.begins_with("PINK SLIPS") and Jobs.street_line({}, 0).ends_with("REP 0"), line)
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
