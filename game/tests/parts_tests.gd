## Parts tests: godot --headless --path game -s tests/parts_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var bad := []
	for id in Parts.CATALOG:
		var p: Array = Parts.CATALOG[id]
		if not Parts.SLOTS.has(String(p[0])): bad.append(id)
		var fx: Dictionary = p[4]
		if fx.has("compound") and not CarSim.COMPOUND.has(String(fx.compound)): bad.append(id + " compound")
	check("every part has a real slot and tyre compound", bad.is_empty(), str(bad))
	check("there's plenty to buy", Parts.CATALOG.size() >= 50, "%d parts" % Parts.CATALOG.size())
	var base := SaveGame.load_spec("silvio")
	var nan := []
	for id in Parts.CATALOG:
		var s := Parts.apply(base, { Parts.slot(id): id })
		var c := CarSim.new(s)
		c.set_ambient(20.0)
		c.cold_start()
		for i in 120: c.step(1.0 / 60.0, 1.0, 0.0, 0.1, 0.0)
		if is_nan(c.speed()) or c.speed() <= 0.0: nan.append(id)
	check("every part drives (no NaNs, still moves)", nan.is_empty(), str(nan))
	check("apply never changes the stock spec", Parts.peaks(SaveGame.load_spec("silvio")).x == Parts.peaks(base).x)
	var stock := Perf.estimate(base)
	var built := Parts.apply(base, { "induction": "ind_greddy", "intercooler": "ic_mishimotoh", "ecu": "ecu_apexii", "exhaust": "exh_borlah", "clutch": "clutch_s3", "tires": "tire_sport" })
	var fast := Perf.estimate(built)
	check("a bigger turbo makes more power", Parts.peaks(built).x > Parts.peaks(base).x * 1.4, "%d -> %d hp" % [int(Parts.peaks(base).x), int(Parts.peaks(built).x)])
	check("and the car is quicker to 100", fast.zero100 > 0.0 and fast.zero100 < stock.zero100, "%.1f -> %.1f s" % [stock.zero100, fast.zero100])
	check("stock numbers are believable", stock.zero100 > 4.0 and stock.zero100 < 14.0 and stock.top_kmh > 150.0, "0-100 %.1f, top %d" % [stock.zero100, int(stock.top_kmh)])
	var light := Parts.apply(base, { "weight": "wt_full" })
	check("stripping it makes it lighter", float(light.mass) < float(base.mass) - 100.0)
	var na := SaveGame.load_spec("supreem")
	check("a turbo kit bolts onto a car without one", not (Parts.apply(na, { "induction": "ind_garrette" }).engine.get("turbo", {}) as Dictionary).is_empty())
	check("the stock-frame upgrade only fits turbo cars", Parts.fits("ind_upgrade", base) and not Parts.fits("ind_upgrade", na))
	var save := SaveGame.default_data()
	check("new saves have money and a parts shelf", int(save.cash) > 0 and save.shelf is Array and save.garage[0].parts is Dictionary)
	save.garage[0].parts = { "aero": "aero_gt", "brakes": "brk_brenbo", "suspension": "susp_coilover" }
	var lk := SaveGame.car_looks(save.garage[0])
	check("parts show on the car (wing, calipers, drop)", lk.get("spoiler", "") == "gt" and lk.has("caliper") and float(lk.get("drop", 0.0)) > 0.5, str(lk))
	# stages and install time
	var unstaged: Array = []
	for id in Parts.CATALOG:
		if Parts.stage(id) < 1 or Parts.stage(id) > 4 or not Parts.STAGE.has(id) or Parts.install_h(id) <= 0.0: unstaged.append(id)
	check("every part has a stage and an install time", unstaged.is_empty(), str(unstaged))
	# the dyno tune: boost and timing make power, and push toward knock; fuel and forged parts hold it off
	var turbo_parts := { "induction": "ind_garrette" }
	var t0 := Parts.apply(base, turbo_parts, {})
	var t1 := Parts.apply(base, turbo_parts, { "boost": 0.15 })
	var t2 := Parts.apply(base, turbo_parts, { "timing": 3 })
	check("more boost on the dyno, more power", Parts.peaks(t1).x > Parts.peaks(t0).x * 1.1, "%d -> %d hp" % [int(Parts.peaks(t0).x), int(Parts.peaks(t1).x)])
	check("more timing, a little more torque", Parts.peaks(t2).y > Parts.peaks(t0).y * 1.02)
	var risky := Parts.knock_risk(turbo_parts, { "boost": 0.15, "timing": 3 })
	var e85 := turbo_parts.duplicate()
	e85.fuel = "fuel_e85"
	check("an aggressive tune risks knock, E85 holds it off", risky > 0.2 and Parts.knock_risk(e85, { "boost": 0.15, "timing": 3 }) < risky * 0.5, "%.2f vs %.2f" % [risky, Parts.knock_risk(e85, { "boost": 0.15, "timing": 3 })])
	var forged := turbo_parts.duplicate()
	forged.internals = "int_built"
	check("a built bottom end opens up the boost range", float(Parts.tune_range(forged, t0).boost) > float(Parts.tune_range(turbo_parts, t0).boost) + 0.3)
	check("a stock tune is safe", Parts.knock_risk(turbo_parts, {}) <= 0.0)
	check("tuning never touches the base spec", Parts.peaks(SaveGame.load_spec("silvio")).x == Parts.peaks(base).x)
	# knock eats the engine at full load; a safe tune doesn't
	var hurt := []
	for spec in [t0, Parts.apply(base, turbo_parts, { "boost": 0.15, "timing": 3 })]:
		var c := CarSim.new(spec)
		c.coolant_c = 88.0
		c.oil_c = 95.0
		for i in 60 * 20: c.step(1.0 / 60.0, 1.0, 0.0, 0.0, 0.0)
		hurt.append(1.0 - c.engine_health)
	check("knock hurts the engine at full load", float(hurt[1]) > float(hurt[0]) + 0.02, "safe %.3f, risky %.3f" % [float(hurt[0]), float(hurt[1])])
	# wear: launches eat the clutch, stops eat the pads, and worn parts show it
	var cw := CarSim.new(base)
	cw.coolant_c = 88.0
	cw.oil_c = 95.0
	for k2 in 8:
		for i in 60 * 2: cw.step(1.0 / 60.0, 1.0, 0.0, 0.0, 0.0)
		for i in 60 * 4: cw.step(1.0 / 60.0, 0.0, 1.0, 0.0, 0.0)
	check("hard launches and stops wear the clutch and pads", cw.clutch_cond < 1.0 and cw.pads_mm < 10.0, "clutch %.3f, pads %.3f mm" % [cw.clutch_cond, cw.pads_mm])
	var stops := []
	for mm in [10.0, 0.0]:
		var c2 := CarSim.new(base)
		c2.pads_mm = mm
		c2.vx = 27.0
		c2.w_wheel = 27.0 / float(base.tires.radius)
		var p0 := c2.pos
		var n2 := 0
		while c2.vx > 0.5 and n2 < 60 * 20:
			c2.step(1.0 / 60.0, 0.0, 1.0, 0.0, 0.0)
			n2 += 1
		stops.append(c2.pos.distance_to(p0))
	check("worn-out pads stop much longer", float(stops[1]) > float(stops[0]) * 1.3, "%.1f m vs %.1f m" % [float(stops[0]), float(stops[1])])
	var slip := []
	for cond in [1.0, 0.3]:
		var c3 := CarSim.new(base)
		c3.clutch_cond = cond
		c3.coolant_c = 88.0
		c3.oil_c = 95.0
		for i in 60 * 6: c3.step(1.0 / 60.0, 1.0, 0.0, 0.0, 0.0)
		slip.append(c3.vx)
	check("a worn clutch is slower", float(slip[1]) < float(slip[0]) * 0.97, "%.1f vs %.1f m/s after 6 s" % [float(slip[0]), float(slip[1])])
	# Gus's installs land when the clock gets there
	var sv := SaveGame.ensure({ "garage": [{ "id": "silvio", "paint": "", "damage": {} }], "current": 0, "clock_h": 10.0 })
	sv.garage[0].installing = [{ "slot": "intake", "part": "intake_kandm", "done_h": 10.5 }]
	var none := SaveGame.finish_installs(sv)
	sv.clock_h = 10.6
	var landed := SaveGame.finish_installs(sv)
	check("installs land on the clock", none.is_empty() and landed.size() == 1 and String(sv.garage[0].parts.get("intake", "")) == "intake_kandm" and (sv.garage[0].installing as Array).is_empty())
	# side-view art: authored showroom sprites take over from the painter for stock cars
	var silvio := SaveGame.load_spec("silvio")
	check("art ids follow the sprite naming", PixCars.art_id(silvio) == "nissun_silvio_1991", PixCars.art_id(silvio))
	var dir := OS.get_user_data_dir().path_join("showroom_test")
	DirAccess.make_dir_recursive_absolute(dir.path_join("masks"))
	var pair: Array = load("res://tools/export_showroom.gd").render(silvio)
	var spr: Image = pair[0]
	var msk: Image = pair[1]
	check("exported showroom is 256x96 with the car on y=78", spr.get_size() == Vector2i(256, 96) and spr.get_used_rect().end.y >= 76 and spr.get_used_rect().end.y <= 82, str(spr.get_used_rect()))
	spr.save_png(dir.path_join("nissun_silvio_1991.png"))
	msk.save_png(dir.path_join("masks/nissun_silvio_1991_paint.png"))
	PixCars.showroom_dir = dir + "/"
	var red := PixCars.showroom(silvio, 200, Color("a8232d"), { "year": 1991 })
	var blue := PixCars.showroom(silvio, 200, Color("1e4a8a"), { "year": 1991 })
	check("stock cars use the authored sprite, repainted by its mask", red.get_width() == 256 and red.get_data() != blue.get_data())
	check("modded cars go back to the painter", PixCars.showroom(silvio, 200, Color.RED, { "spoiler": "gt" }).get_width() == 244)
	PixCars.showroom_dir = "res://art/vehicles/showroom/"
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
