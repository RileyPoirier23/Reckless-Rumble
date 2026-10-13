## The top-down cars, the traffic they make up and the cars parked along the streets:
## godot --headless --path game -s tests/top_down_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _art(id: String, mods := {}, damage = 0.0, paint := Color("2c5a8a")) -> CarArt:
	var spec := CarCatalog.spec(id)
	return CarArt.new(spec, paint, damage, 5, CarArt.CAR_SCALE, mods)

func _plan(id: String, mods := {}) -> CarArt.Plan:
	var spec := CarCatalog.spec(id)
	return CarArt.plan_of(spec, mods, { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, CarArt.CAR_SCALE, CarGen.design(spec), CarArt._plan_key(spec, mods, {}, CarArt.CAR_SCALE))

## How tall each column of a plan stands down the middle of the car, nose to tail.
func _spine(p: CarArt.Plan) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var y := int(p.cy)
	for x in p.sx: out.append(float(maxi(p.h0[p.idx(x, y)], -1)))
	return out

func _differs(a: CarArt, b: CarArt) -> bool:
	return a.atlas.get_image().get_data() != b.atlas.get_image().get_data()

func _init() -> void:
	_every_car()
	_shapes()
	_mods()
	_wear_and_traffic()
	_fleet()
	_parked()
	_knots()
	_supercars_and_lamps()
	_fenders_and_mirrors()
	_no_clipping()
	_ambulance_and_trucks()
	_async()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

## The wedges from above: drawn in from the doors to the nose, hips over a wider back track, the
## Countach's wing a blade over its tail, the F40's slatted engine cover, the Testosterona's
## strakes. And a headlamp is a lens one or two slices deep, a sunroof sits in a dark seal.
func _supercars_and_lamps() -> void:
	var narrow: Array = []
	for id: String in ["lamberghini_coontash_1985", "ferraree_testosterona_1987", "ferraree_eff_forty_1990", "lotis_espree_1979", "pontiak_fieryo_1985"]:
		var p := _plan(id)
		var x_mid := 0
		var x_front := 0
		for x in p.sx:
			if p.ux[x] <= 0.5: x_mid = x
			if p.ux[x] <= 0.88: x_front = x
		if p.hw[x_front] > p.hw[x_mid] * 0.9: narrow.append(id)
	check("a wedge is drawn in toward its nose from the doors", narrow.is_empty(), str(narrow))
	var c := _plan("lamberghini_coontash_1985")
	var rear_y := 0.0
	var front_y := 0.0
	for w: Array in c.wheels:
		if w[4]: front_y = maxf(front_y, absf(float(w[1]) - c.cy))
		else: rear_y = maxf(rear_y, absf(float(w[1]) - c.cy))
	check("a mid-engined car's back wheels sit wider than its front ones", rear_y > front_y, "%.1f / %.1f" % [rear_y, front_y])
	var blade := 0
	for i in c.m2.size(): if c.h2[i] >= 0 and (c.m2[i] & 255) == CarArt.M_TRIM: blade += 1
	check("the Countach's wing has a dark trailing edge over its tail", blade > 4, "%d px" % blade)
	var slats := 0
	var f40 := _plan("ferraree_eff_forty_1990")
	for i in f40.m0.size(): if f40.h0[i] >= 0 and (f40.m0[i] & 255) == CarArt.M_TRIM: slats += 1
	var plain := 0
	var nsx := _plan("acurra_en_ess_eks_1991")
	for i in nsx.m0.size(): if nsx.h0[i] >= 0 and (nsx.m0[i] & 255) == CarArt.M_TRIM: plain += 1
	check("an F40's engine cover is slatted, more than a plain one's pair of vents", slats > plain + 20, "%d / %d" % [slats, plain])
	var ribs := {}
	for id3: String in ["ferraree_testosterona_1987", "lamberghini_diabloh_1995"]:
		var p3 := _plan(id3)
		var n := 0
		for i in p3.m0.size():
			var m := p3.m0[i]
			if p3.h0[i] >= 0 and (m & 255) == CarArt.M_PAINT and ((m >> 8) & 15) == 0 and ((m >> 12) & 15) == CarArt.R_BODY: n += 1
		ribs[id3] = n
	check("strakes down a Testosterona's flanks show from above", int(ribs.ferraree_testosterona_1987) > int(ribs.lamberghini_diabloh_1995) + 6, str(ribs))
	var tall: Array = []
	for id2: String in ["toyoda_camree_2015", "hondo_accordion_2004", "nissun_alteema_2007", "chryslur_three_hunnert_see_2009", "silvio"]:
		var p2 := _plan(id2)
		var lo := 999
		var hi := -1
		for i in p2.m0.size():
			if p2.h0[i] >= 0 and (p2.m0[i] & 255) == CarArt.M_HEAD:
				lo = mini(lo, p2.h0[i])
				hi = maxi(hi, p2.h0[i])
		if hi < 0 or hi - lo > 1: tall.append("%s %d..%d" % [id2, lo, hi])
	check("a headlamp's lens is one or two slices deep, not a stack up the corner", tall.is_empty(), str(tall))
	var seal := []
	for mods: Dictionary in [{ "roof": "sunroof" }, {}]:
		var sr := _plan("hondo_civil_ess_eye_1999", mods)
		var n2 := 0
		for i in sr.m0.size(): if sr.h0[i] >= 0 and (sr.m0[i] & 255) == CarArt.M_TRIM and ((sr.m0[i] >> 8) & 15) == 0: n2 += 1
		seal.append(n2)
	check("a sunroof sits in a dark seal", int(seal[0]) > int(seal[1]) + 8, str(seal))

## The knots where the map's roads bunch up: lights a few metres apart run in step, a street laid
## over the main road isn't driven down, a car waiting at a stop sign keeps its nose out of the
## junction next door, nobody's sent up a dead-end stub to turn round in the road.
func _knots() -> void:
	var map := MapData.get_map()
	var tr := Traffic.new()
	tr.classify(map)
	var out_of_step: Array = []
	for n: int in tr.junctions:
		if String(tr.junctions[n].control) != "signal": continue
		for e in map.g_adj[n]:
			var m: int = e[0]
			if not tr.junctions.has(m) or String(tr.junctions[m].control) != "signal" or float(e[1]) > 25.0: continue
			if tr.junctions[n].majors.has(int(e[2].idx)) and tr.junctions[m].majors.has(int(e[2].idx)) and int(tr.junctions[n].offset) != int(tr.junctions[m].offset): out_of_step.append([n, m])
	check("lights a few metres apart on the same main road run in step", out_of_step.is_empty(), str(out_of_step))
	# (found by where they are: the map's node numbers move when roads are added)
	var john_king := map.nearest_node(Vector2(6250, 1500))
	var john_main := map.nearest_node(Vector2(6279, 1500))
	var john_robinson := map.nearest_node(Vector2(6180, 1500))
	check("John St where it runs on top of Main St is nobody's route", tr.shadowed.has(Vector2i(john_king, john_main)) and tr.shadowed.size() < 10, str(tr.shadowed.keys()))
	check("waiting on John St at King St, the nose is out of Main St's junction", tr.stop_line(john_king, john_robinson) > 10.0, "%.1f" % tr.stop_line(john_king, john_robinson))
	var car := TrafficCar.new()
	car.rng.seed = 5
	var picks := {}
	for i in 400:
		var c := tr.next_node(792, 795, car)
		picks[c] = int(picks.get(c, 0)) + 1
	check("from John St at King St, hardly anybody goes down the John St stretch on top of Main St", int(picks.get(48, 0)) < 12, str(picks))
	var stub := 0
	for i in 400: if tr.next_node(52, 51, car) == 342: stub += 1
	check("hardly anybody turns up the bridge's dead-end stub", stub < 12, "%d of 400" % stub)
	car.free()

var lamp_bad: Array = []

## A car's lamps where its lamps are: two headlamps in the front half no higher than the roof,
## two stop lamps in the back half, every glow's spot inside the car's outline and its stack.
func _lamps_on_the_body(id: String, a: CarArt) -> void:
	var heads := 0
	var tails := 0
	for sp: Array in a.lamp_spots:
		var at: Vector3 = sp[1]
		if absf(at.x) > a.size.x / 2.0 or absf(at.y) > a.size.y / 2.0 or at.z < 0.0 or at.z > float(a.n):
			lamp_bad.append("%s: kind %d off the car at %s" % [id, int(sp[0]), str(at)])
		match int(sp[0]):
			2:
				heads += 1
				if at.x < 0.0 or at.z > a.roof_z + 1.0: lamp_bad.append("%s: a headlamp at %s" % [id, str(at)])
			0:
				if at.x < 0.0: tails += 1
	if heads < 2 or tails < 2: lamp_bad.append("%s: %d headlamps, %d stop lamps" % [id, heads, tails])

## Every catalogue car, the fleet and a trailer draw: an atlas of slices, lamps, a wheel stack.
func _every_car() -> void:
	var bad: Array = []
	var ids := CarCatalog.ids() + CarCatalog.fleet_ids()
	for id: String in ids:
		var a := _art(id)
		var spec := CarCatalog.spec(id)
		var ok := a.atlas != null and a.n >= 8 and a.atlas.get_width() == a.size.x * a.n and a.wheel_tex != null and a.lamp_tex.has("brake")
		ok = ok and absi(a.length_px - int(round(float(spec.length) * CarArt.PX * CarArt.CAR_SCALE))) <= 1
		ok = ok and a.atlas.get_image().get_used_rect().size.x > a.length_px * 0.8
		if not ok: bad.append(id)
		_lamps_on_the_body(id, a)
	check("every car and every fleet vehicle draws from above", bad.is_empty(), str(bad.slice(0, 6)))
	check("every car's lamps sit on its body: headlamps up front, tail lamps at the back, none floating", lamp_bad.is_empty(),
		"%d bad: %s" % [lamp_bad.size(), str(lamp_bad.slice(0, 6))])
	var tr := CarArt.new({ "body": "trailer", "length": 13.6, "width": 2.55, "track": 2.1 }, Color.WHITE, 0.0, 1, CarArt.CAR_SCALE, { "decal": 2 })
	check("a semi's trailer draws, with no front wheels of its own", tr.atlas != null and tr.wheel_spots.is_empty() and tr.n > 30, "%d slices" % tr.n)

## The plan from above follows the side profile: same length, the roof where the side view puts
## it, the hood lower than the roof, a pickup's bed low behind the cab, a bus taller than a car.
func _shapes() -> void:
	var sig := {}
	for id: String in ["charjer", "silvio", "supreem"]:
		var p := _plan(id)
		var d: Dictionary = p.d
		var sp := _spine(p)
		var top := -1.0
		var top_x := 0
		for x in sp.size():
			if sp[x] > top:
				top = sp[x]
				top_x = x
		var u: float = p.ux[top_x]
		check("%s: the roof's highest point is between the windshield and the backlight" % id, u >= float(d.roof_r) - 0.05 and u <= float(d.roof_f) + 0.05, "u %.2f, roof %.2f..%.2f" % [u, float(d.roof_r), float(d.roof_f)])
		var hood_x := int(round(float(CarArt.MX) + (float(d.cowl_x) + 1.0) * 0.5 * float(p.lpx)))
		check("%s: the hood sits well under the roof" % id, sp[hood_x] < top - 3.0, "hood %.0f roof %.0f" % [sp[hood_x], top])
		sig[id] = sp
	var diff := func(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
		var n := mini(a.size(), b.size())
		var s := 0.0
		for i in n: s += absf(a[i] - b[i])
		return s / float(n) + absf(float(a.size() - b.size()))
	check("a Charjer, a Silvio and a Supreem are different shapes from above",
		diff.call(sig.charjer, sig.silvio) > 1.0 and diff.call(sig.silvio, sig.supreem) > 1.0 and diff.call(sig.charjer, sig.supreem) > 1.0)
	var widths := {}
	for id: String in ["charjer", "silvio"]:
		var p2 := _plan(id)
		widths[id] = p2.wpx
	check("each car is its own width from above", int(widths.charjer) > int(widths.silvio))
	var truck := _plan("fjord_f_one_fiddy_2015")
	var sp2 := _spine(truck)
	var bed_x := int(round(float(CarArt.MX) + 0.15 * float(truck.lpx)))
	var cab_x := int(round(float(CarArt.MX) + (float(truck.d.cab_x) + 0.05) * float(truck.lpx)))
	check("a pickup's bed floor is down under its cab roof", sp2[bed_x] < sp2[cab_x] - 6.0, "bed %.0f cab %.0f" % [sp2[bed_x], sp2[cab_x]])
	var bus := _art(CarCatalog.fleet_ids()[0])
	var sedan := _art("fjord_crown_victorious_2005")
	var exotic := _art("lamberghini_coontash_1985")
	check("a bus stands taller than a sedan, a sedan taller than an exotic", bus.n > sedan.n + 10 and sedan.n > exotic.n, "%d / %d / %d" % [bus.n, sedan.n, exotic.n])
	var bent := _art("charjer", {}, { "front": 0.9, "rear": 0.0, "left": 0.0, "right": 0.0 })
	var whole := _art("charjer")
	check("a crushed nose is shorter and has lost a headlamp", bent.atlas.get_image().get_used_rect().size.x < whole.atlas.get_image().get_used_rect().size.x + 1 and not (bent.head_ok[0] and bent.head_ok[1]))
	check("a car drawn twice is the same picture", not _differs(_art("silvio"), _art("silvio")))
	# an open car has its cockpit: the windshield's glass, the seats sunk in behind it
	var no_cockpit: Array = []
	var open_n := 0
	for id2: String in CarCatalog.ids():
		var d2 := CarGen.design(CarCatalog.spec(id2))
		if String(d2.rear) != "open": continue
		open_n += 1
		var p3 := _plan(id2)
		var glass := false
		var seat := false
		for x in p3.sx:
			var u: float = p3.ux[x]
			if u < float(d2.dlo_r) - 0.03 and String(d2.family) != "offroad" or u > float(d2.cowl_x) + 0.01: continue
			for y in p3.sy:
				var m: int = p3.m0[p3.idx(x, y)] & 255
				if m == CarArt.M_GLASS: glass = true
				if m == CarArt.M_SEAT: seat = true
		if not (glass and seat): no_cockpit.append(id2)
	check("every open car shows its windshield and its seats from above", open_n > 25 and no_cockpit.is_empty(), "%d open, %s" % [open_n, str(no_cockpit.slice(0, 5))])
	var jepp := _plan("jepp_wranglur_1995")
	var bar := false
	for i in jepp.h2.size():
		if jepp.h2[i] >= 0 and (jepp.m2[i] & 255) == CarArt.M_TRIM: bar = true
	check("a Jepp has its roll bar", bar)
	# a crowned roof steps down a slice at a time without drawing contour lines (the smile)
	var civic := _art("hondo_civil_ess_eye_1999", {}, 0.0, Color("e8e4dc"))
	var cp := _plan("hondo_civil_ess_eye_1999")
	var dark_steps := 0
	var img := civic.atlas.get_image()
	for x in cp.sx:
		var u2: float = cp.ux[x]
		if u2 < float(cp.d.roof_r) + 0.02 or u2 > float(cp.d.roof_f) - 0.02: continue
		for y in cp.sy:
			var i2 := cp.idx(x, y)
			if absf(float(y) + 0.5 - cp.cy) > cp.gr * 0.7 or cp.nmin[i2] < 0: continue
			for z in range(maxi(cp.nmin[i2], 0), cp.h0[i2]):
				if img.get_pixel(z * cp.sx + x, y).get_luminance() < 0.35: dark_steps += 1
	check("a light car's roof has no dark contour lines across it", dark_steps == 0, "%d dark step pixels" % dark_steps)

## Everything the body shop sells shows on the car out on the road.
func _mods() -> void:
	var stock := _art("silvio")
	var looks := [
		{ "finish": "metallic" }, { "finish": "pearl" }, { "finish": "matte" }, { "finish": "chrome" },
		{ "stripes": "racing" }, { "stripes": "side" }, { "stripes": "rally" }, { "stripe_color": Color("f0d040"), "stripes": "racing" },
		{ "livery": "slash" }, { "livery": "split" }, { "livery": "sponsor" }, { "livery": "flames" },
		{ "hood": "vented" }, { "hood": "scoop" }, { "hood": "carbon" },
		{ "spoiler": "ducktail" }, { "spoiler": "wing" }, { "spoiler": "gt" },
		{ "kit": { "lip": true } }, { "kit": { "skirts": true } }, { "kit": { "diffuser": true } }, { "fenders": "flared" },
		{ "rim": "deepdish" }, { "rim": "beadlock" }, { "rim_color": Color("e8c040") }, { "rim_size": 0.8 }, { "offset": "poke" },
		{ "tint": 1.0 }, { "roof": "sunroof" }, { "roof": "ttops" }, { "roof": "vinyl" }, { "roof": "rack" }, { "roof": "lightbar" },
		{ "exhaust": "quad" }, { "exhaust": "side" }, { "bash": true }, { "drop": 1.0 }, { "drop": -1.0 },
	]
	var same: Array = []
	for m: Dictionary in looks:
		if not _differs(stock, _art("silvio", m)): same.append(m)
	check("every body-shop option changes the car from above", same.is_empty(), str(same))
	# every rim, lip depth and tyre shows from above on the back wheels (the atlas) and the front
	# ones (their own stacks, so they can steer)
	var wheel_same: Array = []
	var opts: Array = []
	for rim: String in PixCars.RIMS: opts.append({ "rim": rim })
	for t: String in CarGen.TIRES: opts.append({ "tire": t })
	for dp: float in [0.0, 0.5, 1.0]: opts.append({ "lip_depth": dp })
	var base := _art("silvio", { "rim": "fivespoke", "tire": "stock", "lip_depth": 0.25 })
	for o: Dictionary in opts:
		var m2 := { "rim": "fivespoke", "tire": "stock", "lip_depth": 0.25 }
		m2.merge(o, true)
		if m2 == { "rim": "fivespoke", "tire": "stock", "lip_depth": 0.25 }: continue
		var a2 := _art("silvio", m2)
		if not _differs(base, a2) or a2.wheel_tex.get_image().get_data() == base.wheel_tex.get_image().get_data(): wheel_same.append(o)
	check("every rim, lip depth and tyre shows from above, back wheels and front", wheel_same.is_empty(), str(wheel_same))
	# fitment, staggered rears and spacers, slammed: all of it shows from above
	var low := _art("silvio", { "drop": 1.0 })
	var fit_same: Array = []
	var fit_opts: Array = [{ "stagger": "staggered" }, { "spacers": 1 }, { "spacers": 3 }]
	for f: String in CarGen.FITMENTS:
		if f != "stock": fit_opts.append({ "offset": f })
	for o2: Dictionary in fit_opts:
		var m3 := { "drop": 1.0 }
		m3.merge(o2)
		var a3 := _art("silvio", m3)
		if not _differs(low, a3) and a3.wheel_tex.get_image().get_data() == low.wheel_tex.get_image().get_data(): fit_same.append(o2)
	check("every fitment, staggered rears and spacers show from above", fit_same.is_empty(), str(fit_same))
	var poke := _plan("silvio", { "offset": "poke", "spacers": 3 })
	var tuck := _plan("silvio", { "offset": "tucked" })
	var stock_p := _plan("silvio", {})
	check("poke and spacers push the wheels out, tucked pulls them in", absf(float(poke.wheels[0][1]) - poke.cy) > absf(float(stock_p.wheels[0][1]) - stock_p.cy)
		and absf(float(tuck.wheels[0][1]) - tuck.cy) < absf(float(stock_p.wheels[0][1]) - stock_p.cy))
	var stance := _art("silvio", { "offset": "stance" })
	check("a stanced wheel leans its top in (its stack is wider than the tyre)", stance.wheel_size.y > _art("silvio").wheel_size.y)
	check("staggered rears are wider than the fronts", int(_plan("silvio", { "stagger": "staggered" }).wheels[0][3]) > int(_plan("silvio", { "stagger": "staggered" }).wheels[2][3]))
	# the lights the body shop sells: angel eyes, smoked tails, underglow, an LED bar on the roof
	var halo := _art("silvio", { "halo": true })
	var plain := _art("silvio")
	check("halo headlights ring the lamps, lit with them", _differs(plain, halo) and halo.lamp_tex.head.get_image().get_data() != plain.lamp_tex.head.get_image().get_data())
	check("smoked tails darken the lenses", _differs(plain, _art("silvio", { "smoked": true })))
	check("underglow goes under the car in its colour", _art("silvio", { "underglow": "#3a8ad8" }).underglow == Color("#3a8ad8") and plain.underglow.a == 0.0)
	var led := _art("fjord_f_one_fiddy_1996", { "roof": "lightbar" })
	check("an LED roof bar lights on its own (with the high beams), not with the headlamps", led.lamp_tex.bar.get_image().get_used_rect().size.x > 0
		and _art("fjord_f_one_fiddy_1996").lamp_tex.bar.get_image().get_used_rect().size.x == 0)
	# light bars sit on the roofs: a cruiser's over the middle of its roof, the wrecker's just behind its windshield
	var cruiser := _art("charjer")
	var wrecker := _art("tow")
	check("a light bar's spot is on the roof", absf(cruiser.roof_mid.x) < cruiser.length_px * 0.3 and absf(cruiser.roof_mid.z - cruiser.roof_z) <= 2.0
		and wrecker.roof_front.x > wrecker.roof_mid.x and wrecker.roof_front.z >= wrecker.roof_z - 3.0, "%s %s / %s" % [str(cruiser.roof_mid), str(wrecker.roof_front), str(wrecker.roof_mid)])
	for r4: String in ["FITMENT", "STAGGER", "SPACERS", "LIP DEPTH", "TIRES", "HEADLIGHTS", "TAIL LIGHTS", "UNDERGLOW"]:
		if not GarageScreen.LOOK_ROWS.has(r4): check("the garage sells %s" % r4, false)
	var slick := _plan("silvio", { "tire": "slicks" })
	check("drag slicks are wider at the back than the front", int(slick.wheels[0][3]) > int(slick.wheels[2][3]), "%d / %d" % [int(slick.wheels[0][3]), int(slick.wheels[2][3])])
	var saved_w := SaveGame.car_looks(JSON.parse_string(JSON.stringify({ "id": "silvio", "looks": { "rim": "threepiece", "lip_depth": 0.75, "tire": "whitewall" }, "parts": {} })))
	check("rims, lip depth and tyres come back from the save", saved_w.rim == "threepiece" and float(saved_w.lip_depth) == 0.75 and saved_w.tire == "whitewall")
	var truck := _art("fjord_f_one_fiddy_2015")
	var truck_same: Array = []
	for m2: Dictionary in [{ "bed": "tonneau" }, { "bed": "rollbar" }, { "bed": "rollbar_lights" }, { "spare": true }, { "load": "lumber" }, { "ladder": true }]:
		if not _differs(truck, _art("fjord_f_one_fiddy_2015", m2)): truck_same.append(m2)
	check("a pickup's bed options show", truck_same.is_empty(), str(truck_same))
	check("a spare on the back door of a 4x4", _differs(_art("fjord_broncho_1990"), _art("fjord_broncho_1990", { "spare": true })))
	var donk := _art("charjer", OneTon.looks({ "custom": { "donk": 3 } }, {}))
	check("a donk stands up on bigger wheels", donk.n > _art("charjer").n and donk.wheel_n > _art("charjer").wheel_n)
	# the garage sells them and saves them
	for r: String in GarageScreen.LOOK_ROWS:
		if r == "PAINT": continue
		if not (GarageScreen.LOOK_KEYS.has(r) and GarageScreen.LOOK_COST.has(r)):
			check("garage row %s has a key and a price" % r, false)
	var saved := SaveGame.car_looks({ "id": "fjord_f_one_fiddy_2015", "looks": { "bed": "rollbar_lights", "roof": "rack", "hood": "carbon" }, "parts": {} })
	check("the bed's roll bar and lights reach the side view too", saved.get("rollbar", false) and saved.get("lightbar", false) and saved.hood == "carbon")
	check("the side view shows a carbon hood and a roof rack", CarGen.render(200, CarGen.design({ "id": "silvio" }), Color.RED, { "hood": "carbon" }).get_data() != CarGen.render(200, CarGen.design({ "id": "silvio" }), Color.RED, {}).get_data()
		and CarGen.render(200, CarGen.design({ "id": "silvio" }), Color.RED, { "roof": "rack" }).get_data() != CarGen.render(200, CarGen.design({ "id": "silvio" }), Color.RED, {}).get_data())

## Traffic is lived in: winter salt, old cars rusting and faded, signs on the roofs, work vans
## with their names on the doors, pickups with loads.
func _wear_and_traffic() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 99
	var counts := { "salt": 0, "rust": 0, "faded": 0, "sign": 0, "decal": 0, "ladder": 0, "load": 0, "dents": 0, "primer": 0, "door": 0, "mods": 0 }
	for i in 3000:
		var style: String = ["downtown", "residential", "rural", "industrial", "commercial"][i % 5]
		var body := CarCatalog.random_traffic(r, style)
		var m := Traffic.dress(body, r, style, i % 2 == 0, 17.0)
		var w: Dictionary = m.get("wear", {})
		for k: String in ["salt", "rust", "faded", "dents", "primer", "door"]:
			if w.has(k): counts[k] += 1
		for k2: String in ["sign", "decal", "ladder", "load"]:
			if m.has(k2): counts[k2] += 1
		if m.has("rim"): counts.mods += 1
	var missing: Array = []
	for k3 in counts:
		if int(counts[k3]) == 0: missing.append(k3)
	check("traffic comes salty, rusty, faded, dented, primered, odd-doored, signed, lettered, laddered, loaded and modded", missing.is_empty(), str(counts))
	var one := Traffic.dress(CarCatalog.random_traffic(r, "rural"), r, "rural", false, 12.0)
	check("no salt on the roads outside winter", not (one.get("wear", {}) as Dictionary).has("salt"))
	var a := _art("fjord_fairmonte_1981")
	check("the wear shows from above", _differs(a, _art("fjord_fairmonte_1981", { "wear": { "rust": 0.8, "dirt": 0.5 } }))
		and _differs(a, _art("fjord_fairmonte_1981", { "sign": "taxi" })) and _differs(a, _art("fjord_fairmonte_1981", { "wear": { "primer": "hood" } })))

## The fleet: traffic only, never for sale, out where and when it should be.
func _fleet() -> void:
	var fleet := CarCatalog.fleet_ids()
	check("the fleet has buses, semis, a garbage truck, an ambulance and delivery trucks", fleet.size() >= 8)
	var leak := false
	for id: String in fleet:
		if CarCatalog.ids().has(id): leak = true
	check("nobody sells you a school bus", not leak)
	for id2: String in fleet:
		var e := CarCatalog.entry(id2)
		var spec := CarCatalog.spec(id2)
		var d := CarGen.design(spec)
		var img := CarGen.render(160, d, Color(String((e.paints as Array)[0])), {})
		if img.get_used_rect().size.x < 140: check("%s draws side on" % id2, false)
		for w: String in ["FREIGHTLINER", "KENWORTH", "MACK", "PETERBILT", "INTERNATIONAL", "GRUMMAN"]:
			if ("%s %s" % [e.make, e.model]).to_upper().contains(w): check("%s is a parody" % id2, false)
	var tr := Traffic.new()
	tr.sky = WorldSky.new()
	var r := RandomNumberGenerator.new()
	r.seed = 4
	var on_highway := {}
	var school_noon := 0
	var school_morning := 0
	for i in 600:
		var id3 := tr._fleet_pick("highway", "rural", r)
		if id3 != "": on_highway[(CarCatalog.entry(id3).art as Dictionary).has("tractor")] = true
		tr.sky.day = 1
		tr.sky.time_h = 12.0
		if Traffic._fleet_has(tr._fleet_pick("street", "residential", r), "schoolbus"): school_noon += 1
		tr.sky.time_h = 8.0
		if Traffic._fleet_has(tr._fleet_pick("street", "residential", r), "schoolbus"): school_morning += 1
	check("semis, and only semis, out on the highway", on_highway.has(true) and not on_highway.has(false))
	check("school buses on weekday mornings, not at noon", school_morning > 20 and school_noon == 0, "%d / %d" % [school_morning, school_noon])
	tr.sky.day = 5
	var weekend := 0
	for i in 300:
		if Traffic._fleet_has(tr._fleet_pick("street", "residential", r), "schoolbus"): weekend += 1
	check("no school buses on the weekend", weekend == 0)
	tr.free()
	# a semi's trailer follows it round a bend
	var semi := TrafficCar.new()
	semi.rng.seed = 3
	semi.v = 15.0
	semi.length = 6.8 * CarArt.CAR_SCALE
	semi._hook_trailer(CarCatalog.traffic_car(Traffic._fleet_id("tractor", r), r))
	semi.heading = 0.6
	for i in 200: semi._tow(1.0 / 30.0)
	var amb := _art("fjord_e_fiddy_ambulanz_2014")
	check("the ambulance has its roof lights, ready to flash", amb.has_beacons and amb.lamp_tex.has("beacon"))
	# the fire engine: a light bar and beacons that flash, its ladders, hose bed and deck gun on top
	var fire_spec := SaveGame.load_spec("fire")
	var fire := CarArt.new(fire_spec, Color(String(fire_spec.paint)), 0.0, 5, CarArt.CAR_SCALE)
	var fp := CarArt.plan_of(fire_spec, {}, { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, CarArt.CAR_SCALE, CarGen.design(fire_spec),
		CarArt._plan_key(fire_spec, {}, {}, CarArt.CAR_SCALE))
	var on_top := {}
	for i4 in fp.m2.size():
		if fp.h2[i4] >= 0: on_top[fp.m2[i4] & 255] = true
	var hose := false
	for i5 in fp.m0.size():
		if fp.h0[i5] >= 0 and (fp.m0[i5] & 255) == CarArt.M_CARGO: hose = true
	check("the fire engine has its light bar and beacons, ready to flash", fire.has_beacons and fire.lamp_tex.has("beacon")
		and fire.lamp_tex.beacon.get_image().get_used_rect().size.x > 0)
	check("the fire engine carries ladders, a deck gun and a hose bed", on_top.has(CarArt.M_LADDER) and on_top.has(CarArt.M_CHROME) and hose)
	var box_spec := fire_spec.duplicate(true)
	box_spec.art = {}
	check("the fire engine isn't a plain box truck any more, from above or side on", _differs(fire, CarArt.new(box_spec, Color(String(fire_spec.paint)), 0.0, 5, CarArt.CAR_SCALE))
		and PixCars.image_of(fire_spec, 200, Color.RED).get_data() != PixCars.image_of(box_spec, 200, Color.RED).get_data())
	check("fire is an art cue the catalogue knows", CarCatalog.ART_CUES.has("fire"))
	var van := _plan("grumpman_step_up_van_2004")
	var sky := false
	var vent := false
	for i3 in van.m0.size():
		if (van.m0[i3] & 255) == CarArt.M_PLATE and van.h0[i3] > 20: sky = true
		if van.h2[i3] >= 0 and (van.m2[i3] & 255) == CarArt.M_STEEL: vent = true
	check("a step van's roof has its skylight and vents", sky and vent)
	check("a trailer swings round behind its tractor", absf(angle_difference(semi.trailer_heading, semi.heading)) < 0.05 and semi.trailer_centre.distance_to(semi.pos) > 8.0, "%.2f" % semi.trailer_heading)
	semi.free()

## Parked cars: spots along the town's curbs, beside the houses and in the lots; never in a
## junction or out in a lane; busy where and when they should be.
func _parked() -> void:
	var map := MapData.get_map()
	var tr := Traffic.new()
	tr.classify(map)
	var fake := FakeDrive.new()
	fake.world = { "map": map }
	fake.traffic = tr
	fake.sky = WorldSky.new()
	var pc := ParkedCars.new()
	pc.setup(fake)
	var kinds := {}
	var in_lane: Array = []
	var in_house: Array = []
	var near_junction: Array = []
	for k in pc.spots:
		for sp: Dictionary in pc.spots[k]:
			kinds[sp.kind] = int(kinds.get(sp.kind, 0)) + 1
			var p: Vector2 = sp.p
			if String(sp.kind) == "curb":
				var rd := map.nearest_road(p, 12.0)
				if not rd.is_empty() and float(rd.dist) < float(rd.road.w) / 2.0 - 0.6: in_lane.append(p)
				for n in tr._near_nodes(p, 0.0, 12.0):
					if map.g_adj[n].size() >= 3: near_junction.append(p)
			if String(sp.kind) == "driveway":
				for b in map.buildings:
					if (b.r as Rect2).has_point(p): in_house.append(p)
	check("spots along the curbs, in the driveways, in the lots and at the truck stop", int(kinds.get("curb", 0)) > 200 and int(kinds.get("driveway", 0)) > 40 and int(kinds.get("stall", 0)) > 60 and int(kinds.get("semi", 0)) >= 2, str(kinds))
	check("no parked car out in a lane", in_lane.is_empty(), str(in_lane.slice(0, 3)))
	check("none in a junction", near_junction.is_empty(), str(near_junction.slice(0, 3)))
	check("no driveway car inside a house", in_house.is_empty(), str(in_house.slice(0, 3)))
	# nor under a house's roof: the roof's drawn lifted up the screen off its footprint
	var under_roof: Array = []
	for k2 in pc.spots:
		for sp2: Dictionary in pc.spots[k2]:
			if String(sp2.kind) != "driveway": continue
			var car := Rect2((sp2.p as Vector2) - Vector2(1.2, 2.9), Vector2(2.4, 5.8))
			for b2 in map.buildings:
				var r2: Rect2 = b2.r
				if r2.grow_individual(0.0, ParkedCars.ROOF_LIFT, 0.0, 0.0).intersects(car) and r2.get_center().distance_to(car.get_center()) < 40.0: under_roof.append(sp2.p)
	check("no driveway car under the roof of a house beside it", under_roof.is_empty(), str(under_roof.slice(0, 3)))
	var mall := { "kind": "stall", "lot": "mall", "style": "commercial" }
	var drive_way := { "kind": "driveway", "style": "residential" }
	check("the mall's lot empties at night, the driveways fill up", pc.odds(mall, 13.0) > pc.odds(mall, 2.0) * 5.0 and pc.odds(drive_way, 23.0) > pc.odds(drive_way, 13.0))
	# every spot in town taken at once: no two cars touch, every car fits its spot, a curb car
	# stays clear of the lane beside it and off every other street
	var all: Array = []
	var too_long: Array = []
	var off_bay: Array = []
	var near_lane: Array = []
	for k in pc.spots:
		for pk: Array in pc.pick(k, 12.0, 1, true):
			var sp: Dictionary = pk[0]
			var body: Dictionary = pk[1]
			var half := Vector2(float(body.length), float(body.width)) * CarArt.CAR_SCALE / 2.0
			all.append([sp.p, float(pk[2]), half, sp.kind])
			var f0 := Vector2.from_angle(float(pk[2]))
			var shape := PackedVector2Array([(sp.p as Vector2) + f0 * half.x + f0.orthogonal() * half.y, (sp.p as Vector2) + f0 * half.x - f0.orthogonal() * half.y,
				(sp.p as Vector2) - f0 * half.x - f0.orthogonal() * half.y, (sp.p as Vector2) - f0 * half.x + f0.orthogonal() * half.y])
			if String(sp.kind) == "curb":
				for bd in map.buildings:
					var br: Rect2 = bd.r
					if br.get_center().distance_to(sp.p) > 80.0: continue
					if not Geometry2D.intersect_polygons(shape, PackedVector2Array([br.position, Vector2(br.end.x, br.position.y), br.end, Vector2(br.position.x, br.end.y)])).is_empty(): in_house.append(sp.p)
				if half.x * 2.0 > ParkedCars.BAY: too_long.append(body.id)
				var f := Vector2.from_angle(float(pk[2]))
				var rd := map.nearest_road(sp.p, 12.0)
				for c: Vector2 in [f * half.x + f.orthogonal() * half.y, f * half.x - f.orthogonal() * half.y, -f * half.x + f.orthogonal() * half.y, -f * half.x - f.orthogonal() * half.y]:
					var at := (sp.p as Vector2) + c
					var on := map.road_at(at, 0.0)
					if not on.is_empty() and not is_same(on.road, rd.road): off_bay.append(sp.p)
					var dc := map.nearest_road(at, 12.0)
					if not dc.is_empty() and is_same(dc.road, rd.road) and float(dc.dist) < float(rd.road.w) / 2.0 - 0.3: near_lane.append(sp.p)
	var touching: Array = []
	for i in all.size():
		for j in range(i + 1, all.size()):
			if (all[i][0] as Vector2).distance_to(all[j][0]) > 16.0: continue
			if ParkedCars.boxes_touch(all[i], all[j]): touching.append([all[i][0], all[j][0]])
	check("with every spot taken, no two parked cars touch", all.size() > 300 and touching.is_empty(), "%d cars, %s" % [all.size(), str(touching.slice(0, 3))])
	check("no car longer than its curb bay", too_long.is_empty(), str(too_long.slice(0, 4)))
	check("no curb car pokes into another street", off_bay.is_empty(), str(off_bay.slice(0, 3)))
	check("no curb car parked into a building", in_house.is_empty(), str(in_house.slice(0, 3)))
	check("a curb car's inside wheels stop at the road's edge, the lane stays clear", near_lane.is_empty(), str(near_lane.slice(0, 3)))
	check("no box truck or limo squeezed into a curb bay", not ParkedCars.fits({ "body": "boxtruck", "length": 6.9 }, "curb") and not ParkedCars.fits({ "body": "sedan", "length": 8.3 }, "curb") and ParkedCars.fits({ "body": "sedan", "length": 4.6 }, "curb"))
	pc.free()
	tr.free()
	fake.free()

## Drawn on a worker thread, it's the same car.
func _async() -> void:
	var spec := CarCatalog.spec("supreem")
	var j := CarArt.build(spec, Color("e8e4dc"), 0.0, 5, CarArt.CAR_SCALE, { "stripes": "racing" })
	var a := j.take()
	var b := CarArt.new(spec, Color("e8e4dc"), 0.0, 5, CarArt.CAR_SCALE, { "stripes": "racing" })
	check("a car drawn on a worker thread is the same as one drawn now", a.atlas != null and not _differs(a, b))

## What ParkedCars reads off the drive scene.
class FakeDrive extends Node:
	var world: Dictionary
	var traffic: Traffic
	var furniture: RoadFurniture
	var sky: WorldSky
	var ysort := Node2D.new()

## Every wheel sits under its fender: no tyre's top shows through the body over it, slammed or
## not, whatever the fitment (a poked tyre stands outside the body, so its outside rows don't
## count), and nothing hangs in the air off the side (a mirror's arm reaches down to the door).
func _fenders_and_mirrors() -> void:
	var through: Array = []
	var hanging: Array = []
	var ids: Array = ["silvio", "charjer", "supreem", "fjord_crown_victorious_2005", "fjord_f_one_fiddy_2015", "mazduh_myata_1990",
		"daihatsoo_hijinx_1999", "acurra_en_ess_eks_1991", "chevrolay_suburbian_2015", "fjord_econolean_1995"]
	for id: String in ids:
		for m: Dictionary in [{}, { "drop": 1.0 }, { "drop": 1.0, "offset": "stance" }, { "drop": 1.0, "offset": "tucked" }, { "drop": -1.0 }]:
			var p := _plan(id, m)
			for w: Array in p.wheels:
				var xc: float = w[0]
				var yc: float = w[1]
				var r: float = w[2]
				var ww: int = w[3]
				for x in range(int(xc - r * 0.7), int(xc + r * 0.7) + 1):
					# (the tyre's top slice, as the plan stacks it)
					var top := float(maxi(0, int(round(r * CarArt.RISE + CarArt.RISE * sqrt(maxf(0.0, r * r - pow(float(x) + 0.5 - xc, 2.0))))) - 1))
					for y in range(int(round(yc - ww / 2.0)), int(round(yc + ww / 2.0))):
						if y < 0 or y >= p.sy or x < 0 or x >= p.sx: continue
						var i := p.idx(x, y)
						if p.h0[i] < 0 or absf(float(y) + 0.5 - p.cy) > p.hw[x] - 0.5: continue
						if float(p.h0[i]) < top and through.size() < 12: through.append("%s %s (%d,%d) body %d tyre %.1f" % [id, str(m), x, y, p.h0[i], top])
			for i2 in p.h0.size():
				if p.h0[i2] < 0 or p.belt[i2] < 999 or (p.m0[i2] & 255) == CarArt.M_GRILLE: continue
				var x2 := i2 % p.sx
				var y2 := i2 / p.sx
				var av := absf(float(y2) + 0.5 - p.cy)
				if p.hw[x2] <= 0.0 or av <= p.hw[x2] + 0.01: continue
				# out past the side: something must hold it up, the body beside it reaching its foot
				var yin := y2 - 1 if float(y2) > p.cy else y2 + 1
				var ok := p.b0[i2] <= 0
				for yy: int in [yin, yin - 1 if float(y2) > p.cy else yin + 1]:
					if yy >= 0 and yy < p.sy and p.h0[p.idx(x2, yy)] >= p.b0[i2]: ok = true
				if not ok and hanging.size() < 12: hanging.append("%s %s (%d,%d) %d..%d" % [id, str(m), x2, y2, p.b0[i2], p.h0[i2]])
	check("every tyre sits under its fender: none shows through the body over it, slammed or not", through.is_empty(), str(through.slice(0, 4)))
	check("nothing hangs in the air off the side: mirrors reach down to the doors", hanging.is_empty(), str(hanging.slice(0, 4)))

## The ambulance from above: AMBULANCE across its hood (mirrored, for the mirror of the car
## ahead), the star of life on its roof, its stripes down the sides; a step van's windshield is
## glass; a semi's tandem stays under its frame.
func _ambulance_and_trucks() -> void:
	for id: String in ["fjord_e_fiddy_ambulanz_2014", "ambulance"]:
		var spec := CarCatalog.spec(id)
		var a := CarArt.new(spec, Color("f2f2ee"), 0.0, 5, CarArt.CAR_SCALE)
		var img := a.atlas.get_image()
		var red := 0
		var blue := 0
		var orange := 0
		for yy in img.get_height():
			for xx in img.get_width():
				var c := img.get_pixel(xx, yy)
				if c == Color("c8201c"): red += 1
				elif c == Color("1f4fb0"): blue += 1
				elif c == Color("f07818"): orange += 1
		var p := CarArt.plan_of(spec, {}, { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, CarArt.CAR_SCALE, CarGen.design(spec), CarArt._plan_key(spec, {}, {}, CarArt.CAR_SCALE))
		# the word on the hood: red marks on the hood's top, ahead of the windshield
		var hood_red := 0
		var d := CarGen.design(spec)
		var top_z := p.n - 1
		for i in p.h0.size():
			var x := i % p.sx
			if p.h0[i] < 0 or p.ux[x] < float(d.cowl_x): continue
			var z: int = p.h0[i]
			if img.get_pixel(z * p.sx + x, i / p.sx) == Color("c8201c"): hood_red += 1
		check("%s: AMBULANCE across the hood, the star of life on the roof, red and orange stripes down the sides" % id,
			hood_red > 30 and blue > 40 and red > 200 and orange > 100, "hood %d, blue %d, red %d, orange %d" % [hood_red, blue, red, orange])
	var plain := _art("fjord_e_fiddy_ambulanz_2014", {}, 0.0, Color("f2f2ee"))
	var signed := _art("fjord_e_fiddy_ambulanz_2014", { "decal": 3 }, 0.0, Color("f2f2ee"))
	check("traffic never hangs a plumber's sign on the ambulance's doors", not _differs(plain, signed))
	var step := _plan("grumpman_step_up_van_2004")
	var glass := 0
	for i3 in step.m0.size():
		if step.h0[i3] >= 0 and (step.m0[i3] & 255) == CarArt.M_GLASS: glass += 1
	check("a step van has its windshield from above", glass > 20, "%d" % glass)
	for id2: String in ["kenwerth_tee_six_eighty_ate_2016", "freightlinear_cascadeeya_2013"]:
		var tp := _plan(id2)
		var x_tail := float(CarArt.MX)
		var behind := 0.0
		for w: Array in tp.wheels: behind = maxf(behind, x_tail - (float(w[0]) - float(w[2])))
		check("%s's tandem stays under its frame" % id2, behind <= 1.0 and tp.wheels.size() >= 10, "%.1f px out, %d wheels" % [behind, tp.wheels.size()])

## The sweep from above: in every combination of rim size, tyre, fitment, spacers, stagger, drop,
## camber, lift and wide arches, no tyre (back ones in the plan, the steering front ones by their
## stack) shares a slice with the body over it: the body over a tyre always starts above it, and a
## poked tyre stands outside the body. And the new looks each change the car from above.
func _no_clipping() -> void:
	var bad: Array = []
	var n := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cars := ["silvio", "fjord_crown_victorious_2005", "fjord_f_one_fiddy_2015", "fjord_escorted_1987", "acurra_en_ess_eks_1991"]
	for k in 220:
		var m := {
			"rim_size": [0.6, 0.7, 0.78, 0.86][rng.randi() % 4], "tire": ["stock", "lowpro", "offroad", "slicks", "mud"][rng.randi() % 5],
			"offset": CarGen.FITMENTS[rng.randi() % CarGen.FITMENTS.size()], "spacers": rng.randi() % 4,
			"drop": [-1.0, -0.5, 0.0, 0.5, 1.0][rng.randi() % 5], "camber": [0, -3, -8][rng.randi() % 3],
			"lift": [0, 2, 4, 6][rng.randi() % 4], "widebody": ["", "overfenders", "widebody"][rng.randi() % 3],
		}
		if rng.randf() < 0.3: m.stagger = "staggered"
		var id: String = cars[k % cars.size()]
		var p := _plan(id, m)
		n += 1
		for w: Array in p.wheels:
			var xc: float = w[0]
			var yc: float = w[1]
			var r: float = w[2]
			var ww: int = w[3]
			var s := float(w[5])
			var zmax := 2.0 * r * CarArt.RISE
			for x in range(int(floor(xc - r)), int(ceil(xc + r)) + 1):
				var dx := float(x) + 0.5 - xc
				if absf(dx) > r or x < 0 or x >= p.sx: continue
				var dz := CarArt.RISE * sqrt(maxf(0.0, r * r - dx * dx))
				var zb := maxi(0, int(round(r * CarArt.RISE - dz)))
				var zt := maxi(zb, int(round(r * CarArt.RISE + dz)) - 1)
				var y_out := int(round(yc - ww / 2.0)) + (ww - 1 if s > 0.0 else 0)
				for ring in ww + p.camber:
					var y := y_out - int(s) * ring
					if y < 0 or y >= p.sy: continue
					# this row's slices of the tyre (a leaning one's rows move in up top)
					for z in range(zb, zt + 1):
						var sh := CarArt.wheel_lean(float(z), p.camber, zmax)
						if ring < sh or ring >= sh + ww: continue
						var i := p.idx(x, y)
						if p.h0[i] >= 0 and z >= p.b0[i] and z <= p.h0[i] and (p.m0[i] & 255) != CarArt.M_TIRE and bad.size() < 12:
							bad.append("%s %s (%d,%d,z%d) body %d..%d" % [id, str(m), x, y, z, p.b0[i], p.h0[i]])
	check("no tyre shares a slice with the body over it, from above, in %d combinations" % n, bad.is_empty(), str(bad.slice(0, 3)))
	# the front wheels steered to full lock: their ends swing in, never into the body
	var steer_bad: Array = []
	for id2: String in cars:
		for m3: Dictionary in [{}, { "drop": 1.0, "offset": "stance" }, { "drop": 1.0, "camber": -8, "widebody": "widebody" }, { "drop": -1.0, "tire": "mud", "lift": 4 }]:
			var p2 := _plan(id2, m3)
			for w2: Array in p2.wheels:
				if not w2[4]: continue
				var r2: float = w2[2]
				var ww2: int = w2[3]
				var zmax2 := 2.0 * r2 * CarArt.RISE
				for st: float in [-0.7, 0.7]:
					var rot := Vector2.from_angle(st)
					for z in range(0, int(zmax2)):
						var hz2 := absf(float(z) + 0.5 - r2 * CarArt.RISE) / CarArt.RISE
						if hz2 > r2: continue
						var half := sqrt(r2 * r2 - hz2 * hz2)
						for k2 in 9:
							var along := lerpf(-half, half, float(k2) / 8.0)
							for ring2 in ww2 + p2.camber:
								var off := Vector2(along, (float(ring2) - float(ww2 - 1) / 2.0) * -float(w2[5]))
								var at := Vector2(float(w2[0]), float(w2[1])) + Vector2(off.x * rot.x - off.y * rot.y, off.x * rot.y + off.y * rot.x)
								var xi := int(floor(at.x))
								var yi := int(floor(at.y))
								if xi < 0 or yi < 0 or xi >= p2.sx or yi >= p2.sy: continue
								var i2 := p2.idx(xi, yi)
								if p2.h0[i2] >= 0 and z >= p2.b0[i2] + 1 and z < p2.h0[i2] and steer_bad.size() < 8:
									steer_bad.append("%s %s steer %.1f (%d,%d,z%d) body %d..%d" % [id2, str(m3), st, xi, yi, z, p2.b0[i2], p2.h0[i2]])
	check("a front wheel at full lock swings its ends in under the arch, never into the body", steer_bad.is_empty(), str(steer_bad.slice(0, 3)))
	var same: Array = []
	var base := _art("silvio")
	for m2: Dictionary in [{ "lift": 4 }, { "camber": -8 }, { "widebody": "overfenders" }, { "widebody": "widebody" },
			{ "special": "rally" }, { "special": "drift" }, { "special": "overland" }, { "special": "drag" }, { "special": "time_attack" }]:
		if not _differs(base, _art("silvio", m2)): same.append(m2)
	check("lift, camber, wide arches and the special kits all show from above", same.is_empty(), str(same))
	var wide := _plan("silvio", { "widebody": "widebody" })
	var narrow := _plan("silvio", {})
	check("wide arches take a wider fitment", absf(float(wide.wheels[0][1]) - wide.cy) > absf(float(narrow.wheels[0][1]) - narrow.cy))
	# lit lamps on the end turned away from the camera stay hidden behind the car
	var cv := CarView.new()
	CarView.screen_up = Vector2(0, -1)
	cv.heading = PI / 2.0                 # nose down the screen, toward the camera
	var e1 := cv.ends_seen()
	cv.heading = -PI / 2.0                # nose up the screen, away
	var e2 := cv.ends_seen()
	cv.heading = 0.0                      # side on: both ends show
	var e3 := cv.ends_seen()
	cv.free()
	check("lamps on the end turned away from the camera don't glow through the car", e1 == [false, true] and e2 == [true, false] and e3 == [true, true])
	var skinny := _plan("silvio", { "special": "drag" })
	check("a drag car's front tyres are skinny", skinny.tire_wf < skinny.tire_w)
