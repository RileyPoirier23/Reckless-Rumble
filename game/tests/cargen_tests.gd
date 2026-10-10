## The side-view car generator: godot --headless --path game -s tests/cargen_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var ids := CarCatalog.ids()
	# --- the same car is the same picture, every time
	var silvio := CarCatalog.spec("silvio")
	var d1 := CarGen.design(silvio)
	CarGen._designs.clear()
	var d2 := CarGen.design(silvio)
	check("a design is the same after the cache is gone", JSON.stringify(d1) == JSON.stringify(d2))
	var a := CarGen.render(160, d2, Color("c8342c"), { "year": 1991 })
	var b := CarGen.render(160, CarGen.design({ "id": "silvio" }), Color("c8342c"), { "year": 1991 })
	check("a spec and a bare id draw the same car", a.get_data() == b.get_data())
	check("paint changes the picture", a.get_data() != CarGen.render(160, d2, Color("2c5a8a"), { "year": 1991 }).get_data())
	# --- every catalogue car designs and paints, inside its image, wheels on the ground
	var broken: Array = []
	var outside: Array = []
	var floating: Array = []
	var sigs := {}
	var len := 120
	for id in ids:
		var e := CarCatalog.entry(String(id))
		var d := CarGen.design(CarCatalog.spec(String(id)))
		var img := CarGen.render(len, d, Color(String((e.paints as Array)[0])), { "year": int(e.year), "shadow": false })
		if img.get_width() != len + 44 or img.get_height() < int(len * 0.75) + 30:
			broken.append(id)
			continue
		var used := img.get_used_rect()
		if used.size.x < len * 0.9 or used.size.y < 20: broken.append(id)
		if used.position.x <= 0 or used.position.y <= 0 or used.end.x >= img.get_width() or used.end.y > img.get_height() - 6: outside.append("%s %s" % [id, str(used)])
		var gy := img.get_height() - 8
		for spot: Array in CarGen.wheel_spots(len, d, {}):
			var xx := int(spot[0])
			var low := -1
			for yy in range(img.get_height() - 1, -1, -1):
				if img.get_pixel(xx, yy).a > 0.9:
					low = yy
					break
			if absi(low - gy) > 1: floating.append("%s x%d low %d gy %d" % [id, xx, low, gy])
		var sig := _signature(img)
		var key := "%s %s" % [e.make, e.model]
		if sigs.has(sig): sigs[sig].append(key)
		else: sigs[sig] = [key]
	check("every catalogue car paints", broken.is_empty(), str(broken.slice(0, 6)))
	check("every car stays inside its picture", outside.is_empty(), str(outside.slice(0, 4)))
	check("wheels sit on the ground line", floating.is_empty(), str(floating.slice(0, 4)))
	# --- no two cars share a silhouette
	var shared: Array = []
	var same_model := 0
	for sg in sigs:
		var who: Array = sigs[sg]
		if who.size() < 2: continue
		var models := {}
		for m in who: models[m] = true
		if models.size() > 1: shared.append(str(who))
		else: same_model += who.size() - 1
	check("no two different models share a silhouette", shared.is_empty(), str(shared.slice(0, 4)))
	check("nearly every car has a silhouette of its own", float(sigs.size()) >= float(ids.size()) * 0.98, "%d shapes for %d cars" % [sigs.size(), ids.size()])
	# --- the families look like what they are
	var pickup := CarGen.design({ "id": "fjord_f_one_fiddy_2015" })
	check("a pickup has a cab and a bed", String(pickup.rear) == "pickup" and float(pickup.cab_x) > 0.2 and float(pickup.cab_x) < float(pickup.roof_f))
	check("a wagon's roof runs to the back", String(CarGen.design({ "id": "volvoh_brick_1989" }).rear) == "box")
	check("a mid-engine wedge sits low with its cabin forward", float(CarGen.design({ "id": "lamberghini_coontash_1985" }).h) < float(CarGen.design({ "id": "toyoda_camree_2015" }).h) and float(CarGen.design({ "id": "lamberghini_coontash_1985" }).cowl_x) > 0.65)
	check("fifties cars get fins, chrome and whitewalls", float(CarGen.design({ "id": "cadillak_coupe_de_villain_1959" }).fin) > 0.0 and String(CarGen.design({ "id": "chevrolay_bel_err_1957" }).bumper) == "chrome" and String(CarGen.design({ "id": "chevrolay_bel_err_1957" }).wall) == "white")
	check("pop-ups come up with the lights", _differs("mazduh_myata_1990", {}, { "lights_on": true }, {}, {}))
	var missing: Array = []
	for id in CarGen.ICONS:
		if not CarCatalog.has(String(id)): missing.append(id)
	check("every icon is a catalogue car", missing.is_empty() and CarGen.ICONS.size() >= 40, "%d icons, missing %s" % [CarGen.ICONS.size(), str(missing)])
	# --- every mod shows
	var mods := [
		["silvio", { "rim": "deepdish" }], ["silvio", { "rim_color": Color("1a1a1e"), "rim": "fivespoke" }], ["silvio", { "rim_size": 0.8 }],
		["silvio", { "caliper": Color("e0402e") }], ["silvio", { "drop": 1.0 }], ["silvio", { "drop": -1.0 }], ["silvio", { "tire": "mud" }],
		["silvio", { "tire": "lowpro" }], ["silvio", { "spoiler": "ducktail" }], ["silvio", { "spoiler": "wing" }], ["silvio", { "spoiler": "gt" }],
		["silvio", { "kit": { "lip": true } }], ["silvio", { "kit": { "skirts": true } }], ["silvio", { "kit": { "diffuser": true } }],
		["silvio", { "fenders": "flared" }], ["silvio", { "livery": "slash" }], ["silvio", { "stripes": "racing" }], ["silvio", { "stripes": "side" }],
		["silvio", { "stripes": "rally" }], ["silvio", { "tint": 1.0 }], ["silvio", { "finish": "matte" }], ["silvio", { "finish": "metallic" }],
		["silvio", { "finish": "pearl" }], ["silvio", { "finish": "chrome" }], ["silvio", { "exhaust": "dual" }], ["silvio", { "exhaust": "quad" }],
		["silvio", { "exhaust": "side" }], ["silvio", { "hood": "vented" }], ["silvio", { "lights_on": true }], ["silvio", { "shadow": false }],
		["silvio", { "bash": true }], ["silvio", { "rust": 0.6 }], ["silvio", { "rim": "wire" }],
		["gmz_sierruh_1988", { "rollbar": true }], ["gmz_sierruh_1988", { "spare": true }], ["gmz_sierruh_1988", { "bed": "tonneau" }],
		["gmz_sierruh_1988", { "smooth": true }], ["chevrolay_caprees_1986", OneTon.looks({ "custom": { "donk": 2 } }, {})],
		["chevrolay_caprees_1986", OneTon.looks({ "custom": { "hyd": 3 } }, {})],
	]
	var still: Array = []
	for m: Array in mods:
		if not _differs(String(m[0]), {}, m[1], {}, {}): still.append(str(m[1]))
	check("every mod changes the picture", still.is_empty(), str(still))
	check("a stripe colour shows", _differs("silvio", { "stripes": "side" }, { "stripes": "side", "stripe_color": Color("e8a020") }, {}, {}))
	check("a light bar needs the roll bar and shows on it", _differs("gmz_sierruh_1988", { "rollbar": true }, { "rollbar": true, "lightbar": true }, {}, {}))
	# --- every crash shows
	var hits := [{ "front": 0.8 }, { "rear": 0.8 }, { "roof": 0.8 }, { "glass": true }, { "wheel_off": "front" }, { "flat": "rear" },
		{ "smoke": 0.8 }, { "bumper": "hang" }, { "bumper": "gone" }, { "lights": true },
		{ "driver": { "skin": Color("dcae88"), "hair": Color("3b2a1e"), "long_hair": true, "sleeve": Color("2a4a6a") } }]
	var unhurt: Array = []
	for h: Dictionary in hits:
		if not _differs("toyoda_camree_2015", {}, {}, {}, h): unhurt.append(str(h))
	check("every kind of crash changes the picture", unhurt.is_empty(), str(unhurt))
	# --- the old door still opens: body-only calls, wheels, the showroom fallback
	var old_ok := true
	for body in PixCars.BODIES:
		var im := PixCars.image(110, String(body), Color("8a8e94"), { "year": int(PixCars.BODIES[body].year) })
		if im.get_used_rect().size.x < 100: old_ok = false
		var p := Pix.new(200, 120, 1)
		PixCars.draw(p, 30, 100, 110, String(body), Color("c8342c"), { "front": 0.5 }, true, 0.1, {})
		if p.img.get_used_rect().size.x < 60: old_ok = false
	check("body-only calls still draw every body", old_ok)
	check("the showroom paints modded cars at len + 44", PixCars.showroom(silvio, 200, Color.RED, { "spoiler": "gt" }).get_width() == 244)
	var spots := PixCars.wheel_spots(silvio, 200)
	check("wheel spots: rear then front, inside the car", spots.size() == 2 and float(spots[0][0]) < float(spots[1][0]) and float(spots[0][0]) > 22.0 and float(spots[1][0]) < 222.0)
	var wp := Pix.new(40, 40, 1)
	for rim in PixCars.RIMS: PixCars.wheel(wp, 20, 20, 16.0, String(rim), false, { "wall": "white", "caliper": Color("e0402e") })
	PixCars.loose_wheel(wp, 20, 20, 12.0, "steel")
	check("every rim paints", wp.img.get_used_rect().size.x >= 30)
	# --- detail follows size: tiny counter cars and cutscene cars stay clean
	var tiny := PixCars.image_of({ "id": "toyoda_camree_2015" }, 36, Color("4a6a8a"))
	var small := PixCars.image_of({ "id": "toyoda_camree_2015" }, 90, Color("4a6a8a"))
	check("a counter-sized car still reads", tiny.get_used_rect().size.x >= 34 and small.get_used_rect().size.x >= 88)
	# --- the art director's round: shapes by era, trucks on frames, hand-drawn icons
	var camry := CarGen.design({ "id": "toyoda_camree_2015" })
	var camry97 := CarGen.design({ "id": "toyoda_camree_1997" })
	check("a 2015 sedan has a higher belt and a bowed roof, a '97 one doesn't",
		float(camry.belt_f) > float(camry97.belt_f) and bool(camry.arc) and not bool(camry97.arc))
	var f150 := CarGen.design({ "id": "fjord_f_one_fiddy_2015" })
	var hd := CarGen.design({ "id": "ramm_thirty_five_hunnert_2016" })
	var comanch := CarGen.design({ "id": "fjord_rangor_1998" })
	check("a full-size pickup stands tall on a frame: a high flat hood, daylight under the sills",
		float(f150.hood_h) * float(f150.L) > 1.15 and float(f150.clear) * float(f150.L) > 0.4 and float(f150.under) > 0.0 and bool(f150.boxy))
	check("a heavy-duty truck's hood is taller still and a compact truck's lower",
		float(hd.hood_h) * float(hd.L) > float(f150.hood_h) * float(f150.L) and float(comanch.hood_h) * float(comanch.L) < float(f150.hood_h) * float(f150.L))
	var van := CarGen.design({ "id": "fjord_transitory_2016" })
	var vtop := CarGen.top_line(CarGen.smooth(CarGen.profile(van), 200.0))
	check("a high-roof van's windshield runs up near the roof, and the roof is flat behind it",
		float(van.cab_top) > float(van.h) - 0.04 and absf(CarGen.top_at(vtop, float(van.roof_f) - 0.12) - float(van.h)) < 0.006 and absf(CarGen.top_at(vtop, 0.3) - float(van.h)) < 0.004)
	var jeep := CarGen.design({ "id": "jepp_wranglur_1995" })
	check("a Jepp is a tub with trapezoid flares", bool(jeep.tub) and String(jeep.flare) == "trap" and String(jeep.arch) == "trap")
	var drawn := 0
	var bad_tops: Array = []
	for id in CarGen.ICONS:
		var icon: Dictionary = CarGen.ICONS[id]
		if not icon.has("top"): continue
		drawn += 1
		var d := CarGen.design({ "id": id })
		var top := CarGen.top_line(CarGen.smooth(CarGen.profile(d), 200.0))
		var L: float = d.L
		var last := -1.0
		for q: Array in icon.top:
			if float(q[0]) < last - 0.05 or float(q[0]) > L + 0.01: bad_tops.append("%s runs backwards at %.2f" % [id, float(q[0])])
			last = float(q[0])
		# the body covers the tops of the wheels (bar a hot rod's open front wheels)
		for wx: float in ([float(d.wr)] if icon.get("cycle", false) else [float(d.wr), float(d.wf)]):
			if CarGen.top_at(top, wx) < float(d.tire_r) * 2.0: bad_tops.append("%s low over a wheel" % id)
	check("forty-odd icons are drawn by hand, front to back, over their wheels", drawn >= 35 and bad_tops.is_empty(), "%d drawn; %s" % [drawn, str(bad_tops.slice(0, 4))])
	var shape_icon := _signature(CarGen.render(120, CarGen.design({ "id": "porch_neuner_1973" }), Color("c8342c"), { "shadow": false }))
	CarGen._designs.erase("porch_neuner_1973")
	var no_icon := CarGen._dna(CarGen.facts({ "body": "sports", "year": 1973, "len": 4.15 }))
	check("a hand-drawn icon isn't the generic car of its kind", shape_icon != _signature(CarGen.render(120, no_icon, Color("c8342c"), { "shadow": false })))
	# racing stripes are one band along the top; flares stop at the sill
	var sd := CarGen.design({ "id": "silvio" })
	var plain := CarGen.render(200, sd, Color("2c5a8a"), {})
	var striped := CarGen.render(200, sd, Color("2c5a8a"), { "stripes": "racing" })
	var flared := CarGen.render(200, sd, Color("2c5a8a"), { "fenders": "flared" })
	var deep := 0
	var hood_band := 0
	var hood_x := 22 + int(lerpf(float(sd.cowl_x), float(sd.wf), 0.4) * 200.0)
	var under_sill := 0
	var sill_y := plain.get_height() - 8 - int(float(sd.clear) * 200.0)
	for xx in plain.get_width():
		var t0p := -1
		for yy in plain.get_height():
			if plain.get_pixel(xx, yy).a > 0.9:
				t0p = yy
				break
		for yy in plain.get_height():
			if striped.get_pixel(xx, yy) != plain.get_pixel(xx, yy) and t0p >= 0 and yy > t0p + 9: deep += 1
			if xx == hood_x and striped.get_pixel(xx, yy) != plain.get_pixel(xx, yy): hood_band += 1
			if flared.get_pixel(xx, yy) != plain.get_pixel(xx, yy) and yy > sill_y + 2 and flared.get_pixel(xx, yy).a > 0.9 and plain.get_pixel(xx, yy).a < 0.5: under_sill += 1
	check("racing stripes are a solid band along the tops, no streaks down the side", deep == 0 and hood_band >= 5, "%d pixels below the band, %d in it over the hood" % [deep, hood_band])
	check("flares stop at the sill", under_sill == 0, "%d pixels under it" % under_sill)
	# a car that loses a wheel sits down on that corner
	var whole := CarGen.render(170, camry, Color("c8342c"), {}, {})
	var three := CarGen.render(170, camry, Color("c8342c"), {}, { "wheel_off": "front" })
	var nose_x := 22 + int(0.93 * 170.0)
	check("a car that lost a wheel sits down on that corner", _lowest_body(three, nose_x) > _lowest_body(whole, nose_x) + 2)
	# the driver's arm is only out over the door when the glass is gone
	var drv := { "skin": Color("dcae88"), "hair": Color("3b2a1e"), "sleeve": Color("2a4a6a") }
	var belt_y := whole.get_height() - 8 - int(float(camry.belt_f) * 170.0)
	var shut := CarGen.render(170, camry, Color("c8342c"), {}, { "glass": true })
	var shut_drv := CarGen.render(170, camry, Color("c8342c"), {}, { "glass": true, "driver": drv })
	var whole_drv := CarGen.render(170, camry, Color("c8342c"), {}, { "driver": drv })
	check("the driver's arm hangs out over the door only through broken glass",
		_rows_differ(whole, whole_drv, belt_y + 3, whole.get_height()) == 0 and _rows_differ(shut, shut_drv, belt_y + 3, whole.get_height()) > 0)
	# no wing over a roof rack
	var wagon := CarGen.design({ "id": "volkswagon_passatt_wagon_2002" })
	check("a wagon with a roof rack gets no wing", CarGen.render(170, wagon, Color("c8342c"), {}).get_data() == CarGen.render(170, wagon, Color("c8342c"), { "spoiler": "gt" }).get_data())
	# lit lamps: a bright lens and a warm falloff in the lamp's own colour, kept on the car in
	# daylight and spilling past the outline only at night
	var lit := CarGen.render(170, camry, Color("2a2a2e"), { "lights_on": true, "shadow": false })
	var dark := CarGen.render(170, camry, Color("2a2a2e"), { "shadow": false })
	var night := CarGen.render(170, camry, Color("2a2a2e"), { "lights_on": true, "glow": true, "shadow": false })
	var cold := 0
	var bright := 0
	var spilled := 0
	var night_spill := 0
	for yy in lit.get_height():
		for xx in range(lit.get_width() - 30, lit.get_width()):
			var c := lit.get_pixel(xx, yy)
			var c0 := dark.get_pixel(xx, yy)
			if night.get_pixel(xx, yy) != c0 and c0.a < 0.5: night_spill += 1
			if c == c0: continue
			if c0.a < 0.5:
				spilled += 1
				continue
			if c.get_luminance() > 0.8: bright += 1
			if c.b - c0.b > c.r - c0.r + 0.02: cold += 1
	check("headlights light up warm: a bright lens, a warm falloff, on the car by day and past it at night",
		bright > 3 and cold == 0 and spilled == 0 and night_spill > 3, "%d bright, %d cold, %d spilled by day, %d at night" % [bright, cold, spilled, night_spill])
	# nothing solid under the road, at any size
	var below: Array = []
	for k in range(0, ids.size(), 9):
		for ln: int in [36, 90]:
			var im := CarGen.render(ln, CarGen.design({ "id": ids[k] }), Color("c8342c"), {})
			var g2 := im.get_height() - 8
			for yy in range(g2 + 2, im.get_height()):
				for xx in im.get_width():
					if im.get_pixel(xx, yy).a > 0.6:
						below.append("%s len%d" % [ids[k], ln])
						break
	check("nothing solid below the road", below.is_empty(), str(below.slice(0, 4)))
	# --- quick enough for a garage preview
	for w in 3: CarGen.render(200, d1, Color("c8342c"), { "year": 1991 })
	var t0 := Time.get_ticks_usec()
	var some := ["silvio", "fjord_f_one_fiddy_2015", "lamberghini_coontash_1985", "volvoh_brick_1989", "chevrolay_bel_err_1957", "jepp_wranglur_1995"]
	for id in some: CarGen.render(200, CarGen.design({ "id": id }), Color("c8342c"), { "rim": "fivespoke", "spoiler": "wing", "kit": { "lip": true } })
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / float(some.size())
	check("one car at len 200 paints in well under a frame budget", ms < 60.0, "%.1f ms" % ms)
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

## The lowest solid body pixel in a column (the shadow doesn't count).
func _lowest_body(img: Image, xx: int) -> int:
	for yy in range(img.get_height() - 1, -1, -1):
		if img.get_pixel(xx, yy).a > 0.9: return yy
	return -1

## How many pixels differ between two pictures in rows y0..y1.
func _rows_differ(a: Image, b: Image, y0: int, y1: int) -> int:
	var n := 0
	for yy in range(y0, mini(y1, a.get_height())):
		for xx in a.get_width():
			if a.get_pixel(xx, yy) != b.get_pixel(xx, yy): n += 1
	return n

## Did changing the mods or the damage change the picture?
func _differs(id: String, m0: Dictionary, m1: Dictionary, d0: Dictionary, d1: Dictionary) -> bool:
	var d := CarGen.design({ "id": id })
	var a := CarGen.render(170, d, Color("c8342c"), m0, d0)
	var b := CarGen.render(170, d, Color("c8342c"), m1, d1)
	return a.get_data() != b.get_data()

## The silhouette as numbers: the top of the car in 48 columns across it, and where the glass is.
func _signature(img: Image) -> String:
	var used := img.get_used_rect()
	var gy := img.get_height() - 8
	var out := PackedStringArray()
	for k in 48:
		var xx := used.position.x + int(float(used.size.x - 1) * float(k) / 47.0)
		var top := -1
		for yy in range(used.position.y, gy):
			if img.get_pixel(xx, yy).a > 0.9:
				top = yy
				break
		out.append(str(gy - top))
	return ",".join(out)
