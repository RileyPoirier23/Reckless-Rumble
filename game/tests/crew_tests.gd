## 1ton and the Luchadooros: the list, joining the crew, what his work does to a car, the hop,
## his bay in the garage, and that everything he says fits where it's shown:
##   godot --headless --path game -s tests/crew_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _spec(model: String, year: int) -> Dictionary:
	var id := Luchadooros.find_car(model, year)
	return CarCatalog.spec(id) if id != "" else {}

func _init() -> void:
	# the list
	for m in [["CAPREES", 1986], ["IMPALER", 1964], ["TOWN CARR", 1995]]:
		check("the Luchadooros' %s %d is in the catalogue" % [m[0], m[1]], Luchadooros.find_car(String(m[0]), int(m[1])) != "")
	check("a '64 Impaler is on the list", OneTon.on_list(_spec("IMPALER", 1964)))
	check("a Caprees is on the list", OneTon.on_list(_spec("CAPREES", 1986)))
	check("the Charjer is on the list", OneTon.on_list(SaveGame.load_spec("charjer")))
	check("a front-drive Impaler isn't", not OneTon.on_list(_spec("IMPALER", 2008)))
	check("a wagon isn't", not OneTon.on_list(_spec("CAPREES WAGON", 1994)))
	check("a stretch limo isn't", not OneTon.on_list(_spec("TOWN CARR STRETCH", 1998)))
	check("the Silvio isn't", not OneTon.on_list(SaveGame.load_spec("silvio")))
	# joining
	var save := SaveGame.default_data()
	check("not in your crew to start", not OneTon.in_crew(save))
	var said := OneTon.show_car(save, SaveGame.load_spec("silvio"), 3)
	check("show him the wrong car: he says no", not OneTon.in_crew(save) and OneTon.NOT_ON_LIST.has(said[0]))
	said = OneTon.show_car(save, SaveGame.load_spec("charjer"), 3)
	check("show him one on the list: he joins", OneTon.in_crew(save) and said == OneTon.JOINS)
	said = OneTon.show_car(save, SaveGame.load_spec("silvio"), 3)
	check("after that he just talks", OneTon.in_crew(save) and OneTon.TALK.has(said[0]))
	# what the work does
	check("a 28-inch tire's radius", absf(OneTon.tire_radius("265/25R28") - 0.42185) < 0.001, "%.4f" % OneTon.tire_radius("265/25R28"))
	var base := _spec("CAPREES", 1986)
	check("no work, no change", OneTon.apply(base, {}).hash() == base.hash())
	var donk := OneTon.apply(base, { "custom": { "donk": 3 } })
	check("a donk: bigger wheels", float(donk.tires.radius) > float(base.tires.radius) * 1.15, "%.3f -> %.3f" % [float(base.tires.radius), float(donk.tires.radius)])
	check("a donk: heavier, higher, less grip", float(donk.mass) > float(base.mass) and float(donk.cg_height) > float(base.cg_height) and float(donk.get("grip", 1.0)) < float(base.get("grip", 1.0)))
	var pumps := OneTon.apply(base, { "custom": { "hyd": 2 } })
	check("pumps and batteries weigh what they weigh", absf(float(pumps.mass) - float(base.mass) - float(OneTon.HYD[2].kg)) < 0.01)
	check("and it doesn't touch the car it came from", not base.has("grip") or float(base.grip) == float(_spec("CAPREES", 1986).get("grip", 1.0)))
	var sim_stock := CarSim.new(base)
	var sim_donk := CarSim.new(donk)
	check("the donk still drives", sim_donk != null and sim_stock != null)
	var lk := OneTon.looks({ "custom": { "donk": 2 } }, {})
	check("a donk sits up in the side view", float(lk.drop) < -0.5 and float(lk.rim_size) > 0.8)
	check("pumps alone sit it low", float(OneTon.looks({ "custom": { "hyd": 3 } }, {}).drop) > 0.5)
	var tall := CarArt.new(CarCatalog.spec("charjer"), Color.RED, 0.0, 1, CarArt.CAR_SCALE, OneTon.looks({ "custom": { "donk": 4 } }, {}))
	var low := CarArt.new(CarCatalog.spec("charjer"), Color.RED, 0.0, 1, CarArt.CAR_SCALE, OneTon.looks({ "custom": { "donk": 1 } }, {}))
	var stock := CarArt.new(CarCatalog.spec("charjer"), Color.RED, 0.0, 1, CarArt.CAR_SCALE)
	check("from above, a donk stands up on big wheels", tall.n > low.n and low.n > stock.n and tall.wheel_n > stock.wheel_n, "%d / %d / %d slices" % [tall.n, low.n, stock.n])
	check("save_game applies his work", float(SaveGame.car_spec({ "id": "charjer", "parts": {}, "custom": { "donk": 3 } }).tires.radius) > 0.4)
	# the hop
	for kit in [1, 2, 3]:
		var h := 0.0
		var v := 0.0
		var top := 0.0
		for i in 120:
			var r := OneTon.hop_step(h, v, 1.0 / 60.0, i < 3, kit)
			h = float(r[0])
			v = float(r[1])
			top = maxf(top, h)
		var want := float(OneTon.HYD[kit].hop)
		check("%s hop %.2f m" % [OneTon.HYD[kit].name, want], absf(top - want) < want * 0.08, "%.2f" % top)
		for i in 240:
			var r2 := OneTon.hop_step(h, v, 1.0 / 60.0, false, kit)
			h = float(r2[0])
			v = float(r2[1])
		check("%s: back on the ground" % OneTon.HYD[kit].name, h == 0.0 and v == 0.0)
	var none := OneTon.hop_step(0.0, 0.0, 0.1, true, 0)
	check("no pumps, no hop", float(none[0]) == 0.0)
	# held down, it keeps hopping
	var hh := 0.0
	var hv := 0.0
	var hops := 0
	var was_up := false
	for i in 600:
		var r3 := OneTon.hop_step(hh, hv, 1.0 / 60.0, true, 3)
		hh = float(r3[0])
		hv = float(r3[1])
		if hh > 0.3 and not was_up: hops += 1
		was_up = hh > 0.3
	check("hold it and it keeps going", hops >= 4, "%d hops in 10 s" % hops)
	# his bay in the garage
	var g := GarageScreen.new()
	g.data = save
	check("his bay is a tab once he's in the crew", g.tabs().has(GarageScreen.BAY))
	var fresh := SaveGame.default_data()
	g.data = fresh
	check("...and not before", not g.tabs().has(GarageScreen.BAY))
	g.data = save
	g.sel = 2                       # the Charjer
	g.tab = g.tabs().find(GarageScreen.BAY)
	g.bay = { "hyd": 3, "donk": 2 }
	check("the parts cost what they cost", g._bay_cost() == int(OneTon.HYD[3].price) + int(OneTon.DONK[2].price))
	save.garage[2].custom = { "hyd": 3, "donk": 0 }
	check("what's already in it is free", g._bay_cost() == int(OneTon.DONK[2].price))
	# the tabs fit across the top
	var x := 10.0
	for t in g.tabs(): x += PixelFont.width(String(t)) + 14.0 + 4.0
	x += 6.0 + PixelFont.width("RB/LB: TABS")
	check("the garage tabs fit with his", x < 630.0 - PixelFont.width("$999,999", 2) - 6.0, "%d px" % int(x))
	g.free()
	# everything he says fits the lot's panel and the bay
	var bad := ""
	var lot_w := int((Luchadooros.LotPanel.R.end.x - 12 - (Luchadooros.LotPanel.R.position.x + 12 + 72 + 12)) / 4)
	for ln in OneTon.INTRO + OneTon.TALK + OneTon.NOT_ON_LIST + OneTon.JOINS:
		if Hud.wrap_lines(String(ln), lot_w).size() > 6: bad += "'%s...' runs over; " % String(ln).substr(0, 20)
	var bay_w := int((630 - (320 + 8 + 56) - 16) / 4)
	for ln in OneTon.BAY:
		if Hud.wrap_lines(String(ln), bay_w).size() > 6: bad += "'%s...' runs over the bay; " % String(ln).substr(0, 20)
	if PixelFont.width("1TON RUNS THE BAYS.  LA CALAVERA RUNS THE STREETS.  EL PULPO RUNS HIS MOUTH.") > Luchadooros.LotPanel.R.size.x - 24: bad += "the club line runs off; "
	for d in OneTon.DONK:
		if PixelFont.width(String(d.name) + "  " + String(d.tire)) > 310 - 92 - 70: bad += "%s runs into its price; " % d.name
	check("nothing he says runs off his panels", bad == "", bad)
	check("his face paints", OneTon.face().get_width() == Face.P)
	# his photos on the wall
	var s2 := SaveGame.default_data()
	check("no Luchadooros photos on a new save", not Awards.met("luchadooro", s2) and not Awards.met("hydraulics", s2) and not Awards.met("donk", s2))
	s2.crew = { "oneton": true }
	s2.garage[0].custom = { "hyd": 1 }
	s2.garage[1].custom = { "donk": 2 }
	check("1ton in the crew, pumps in one, 26s on another", Awards.met("luchadooro", s2) and Awards.met("hydraulics", s2) and Awards.met("donk", s2))
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
