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
