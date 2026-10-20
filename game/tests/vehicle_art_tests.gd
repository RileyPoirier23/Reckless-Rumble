## The vehicle art pipeline: godot --headless --path game -s tests/vehicle_art_tests.gd
## Every car has a manifest, the manifests are what the tool builds today (byte for byte), every
## car is on exactly one of the spec's 25 archetypes, the anchors sit on the wheels the car is
## drawn with, the slots only offer what the code draws, and the validator's art gates catch
## broken sprites and slices.
extends SceneTree

var fails := 0

## The spec's archetypes (DEV ADDITIONS.md, "Vehicle Archetypes"), in its order.
const SPEC_ARCHETYPES := ["micro_fwd", "compact_fwd", "hatch_fwd", "sedan_compact", "sedan_midsize", "sedan_fullsize",
	"coupe_compact", "coupe_gt", "muscle_longhood", "sports_frontengine", "sports_midengine", "exotic_wedge",
	"wagon_compact", "wagon_fullsize", "crossover_compact", "suv_midsize", "suv_fullsize", "offroad_short",
	"pickup_compact", "pickup_half_ton", "pickup_heavy", "van_cargo", "van_passenger", "minivan", "utility_tow"]

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var cars := _coverage()
	_archetypes(cars)
	_determinism(cars)
	_gates(cars)
	_anchors(cars)
	_slots(cars)
	_showroom_gate()
	_runtime_gate()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

## vehicle id -> car id for every car that should have a manifest.
func _coverage() -> Dictionary:
	var cars := {}
	var dup: Array = []
	for id: String in VehicleManifest.car_ids():
		var vid := PixCars.art_id(VehicleManifest.spec_of(id))
		if cars.has(vid): dup.append(vid)
		cars[vid] = id
	var want := CarCatalog.ids().size() + CarCatalog.fleet_ids().size()
	for f: String in DirAccess.get_files_at("res://data/cars"):
		if f.ends_with(".json") and not CarCatalog.has(f.get_basename()): want += 1
	check("every catalogue car, fleet vehicle and hand-made car is in the list", cars.size() == want and dup.is_empty(), "%d of %d, shared ids %s" % [cars.size(), want, str(dup)])
	var missing: Array = []
	for vid: String in cars:
		if not FileAccess.file_exists(VehicleManifest.path_of(vid)): missing.append(vid)
	check("every one of them has a manifest", missing.is_empty(), "%d missing: %s" % [missing.size(), str(missing.slice(0, 5))])
	var orphans: Array = []
	for f2: String in DirAccess.get_files_at(VehicleManifest.DIR):
		if f2.ends_with(".json") and not cars.has(f2.get_basename()): orphans.append(f2)
	check("and no manifest is for a car that isn't there", orphans.is_empty(), str(orphans.slice(0, 5)))
	# ids never change once merged: saves and art folders hang off them
	var pins := { "silvio": "nissun_silvio_1991", "supreem": "toyoda_supreem_1986", "charjer": "dodgy_charjer_r_t_2015",
		"tow": "fjord_f_one_fiddy_wrecker_2008", "fjord_mustank_1966": "fjord_mustank_1966" }
	var moved: Array = []
	for id2: String in pins:
		if PixCars.art_id(CarCatalog.spec(id2)) != pins[id2] or not FileAccess.file_exists(VehicleManifest.path_of(pins[id2])): moved.append(id2)
	check("the hand-made cars keep their vehicle ids", moved.is_empty(), str(moved))
	return cars

func _manifest(vid: String) -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(VehicleManifest.path_of(vid)))
	return v if v is Dictionary else {}

func _archetypes(cars: Dictionary) -> void:
	check("the archetype table is the spec's 25", VehicleArchetypes.names() == SPEC_ARCHETYPES, str(VehicleArchetypes.names()))
	var used := {}
	var bad: Array = []
	var by_era := {}
	for vid: String in cars:
		var spec := VehicleManifest.spec_of(cars[vid])
		var a := VehicleArchetypes.of(spec)
		var m := _manifest(vid)
		var ma := String((m.get("classification", {}) as Dictionary).get("archetype", ""))
		if not SPEC_ARCHETYPES.has(a) or ma != a: bad.append("%s: %s / %s" % [vid, a, ma])
		used[a] = int(used.get(a, 0)) + 1
		var band := VehicleArchetypes.era_band(int(spec.get("year", 0)))
		by_era[band] = int(by_era.get(band, 0)) + 1
	check("every car is on exactly one of the 25, and its manifest says which", bad.is_empty(), str(bad.slice(0, 5)))
	var empty: Array = SPEC_ARCHETYPES.filter(func(a2: String) -> bool: return not used.has(a2))
	check("every archetype has cars on it (Phase B needs one of each)", empty.is_empty(), str(empty))
	check("every car falls in one of the spec's eras (none past 2019)", not by_era.has("") and by_era.size() == VehicleArchetypes.ERA_BANDS.size(), str(by_era))
	var quotas := 0
	for q: String in VehicleArchetypes.QUOTA_CLASSES: quotas += int(VehicleArchetypes.QUOTA_CLASSES[q])
	var eras := 0
	for b: String in VehicleArchetypes.ERA_BANDS: eras += int(VehicleArchetypes.ERA_BANDS[b])
	check("the quota tables add up to the spec's 300", quotas == 300 and eras == 300, "%d classes, %d eras" % [quotas, eras])
	# the rules read the body first: a few cars whose archetype is plain
	var spot := { "silvio": "sports_frontengine", "charjer": "sedan_fullsize", "tow": "utility_tow",
		"fjord_f_one_fiddy_2015": "pickup_half_ton", "lamberghini_coontash_1985": "exotic_wedge", "hondo_beet_1992": "sports_midengine" }
	var wrong: Array = []
	for id: String in spot:
		if VehicleArchetypes.of(CarCatalog.spec(id)) != spot[id]: wrong.append("%s: %s" % [id, VehicleArchetypes.of(CarCatalog.spec(id))])
	check("cars land where you'd expect", wrong.is_empty(), str(wrong))

## The manifests on disk are what the tool builds now. All the hand-made cars and a spread of
## the rest (the whole lot takes minutes: tools/build_vehicle_manifests.gd -- --check).
func _determinism(cars: Dictionary) -> void:
	var stale: Array = []
	var k := 0
	var n := 0
	for vid: String in cars:
		var id: String = cars[vid]
		k += 1
		if k % 12 != 0 and CarCatalog.has(id) and not CarCatalog.HANDMADE.has(id): continue
		n += 1
		var text := VehicleManifest.to_text(VehicleManifest.rebuild(id))
		if text != FileAccess.get_file_as_string(VehicleManifest.path_of(vid)): stale.append(vid)
	check("manifests rebuild byte for byte from the tool", stale.is_empty(), "%d of %d stale: %s" % [stale.size(), n, str(stale.slice(0, 5))])
	var a := VehicleManifest.to_text(VehicleManifest.build("fjord_mustank_1966"))
	var b := VehicleManifest.to_text(VehicleManifest.build("fjord_mustank_1966"))
	check("building a manifest twice gives the same text", a == b)

## The manifest gates over every car.
func _gates(cars: Dictionary) -> void:
	var bad: Array = []
	for vid: String in cars:
		var spec := VehicleManifest.spec_of(cars[vid])
		var art := CarArt.new(spec, VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
		var ps := VehicleArtChecks.manifest(_manifest(vid), vid + ".json", spec, art)
		if not ps.is_empty(): bad.append("%s: %s" % [vid, str(ps.slice(0, 2))])
	check("every manifest passes the validator's gates", bad.is_empty(), "%d: %s" % [bad.size(), str(bad.slice(0, 4))])
	# and the gates bite
	var m := _manifest("nissun_silvio_1991")
	var spec2 := CarCatalog.spec("silvio")
	var broken: Array = []
	for edit: Array in [["dimensions_m", "length", 4.9], ["classification", "archetype", "minivan"], ["display", "year", 2021],
			["art", "slice_count", 13], ["review", "reference_notes", "two\nlines"]]:
		var m2 := m.duplicate(true)
		m2[edit[0]][edit[1]] = edit[2]
		if VehicleArtChecks.manifest(m2, "nissun_silvio_1991.json", spec2).is_empty(): broken.append(edit)
	var m3 := m.duplicate(true)
	(m3.slots.spoiler as Array).append("rocket")
	if VehicleArtChecks.manifest(m3, "nissun_silvio_1991.json", spec2).is_empty(): broken.append("a slot the code can't draw")
	var m4 := m.duplicate(true)
	m4.slots["bed"] = ["stock", "tonneau"]
	if VehicleArtChecks.manifest(m4, "nissun_silvio_1991.json", spec2).is_empty(): broken.append("a bed on a coupe")
	if VehicleArtChecks.manifest(m, "silvio.json", spec2).is_empty(): broken.append("file name")
	check("a wrong size, archetype, year, slice count, note, slot or file name fails", broken.is_empty(), str(broken))

## The axle anchors are where the wheels are drawn, from above and side on.
func _anchors(cars: Dictionary) -> void:
	var off: Array = []
	var per_arch := {}
	for vid: String in cars:
		var spec := VehicleManifest.spec_of(cars[vid])
		var a := VehicleArchetypes.of(spec)
		if per_arch.has(a) and not CarCatalog.HANDMADE.has(String(cars[vid])): continue
		per_arch[a] = vid
		var art := CarArt.new(spec, VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
		var an: Dictionary = _manifest(vid).anchors
		var ps := VehicleArtChecks.wheels_under_anchors(spec, art, an)
		# side on, at the showroom's scale, the tyres touch the ground under the anchors
		var len := int(float(spec.length) * 38.0)
		var d := CarGen.design(spec)
		var img := CarGen.render(len, d, VehicleManifest.FACTORY, { "shadow": false })
		var ground := img.get_height() - 8
		var L := float(spec.length)
		for ax: float in [float(an.front_axle_m)] + Array(an.rear_axles_m):
			var x := int(round(22.0 + (ax / L + 0.5) * len))
			var hit := false
			for dx in range(-2, 3):
				for y in range(ground - 2, ground + 1):
					if img.get_pixel(clampi(x + dx, 0, img.get_width() - 1), y).a > 0.5: hit = true
			if not hit: ps.append("no tyre on the ground side on at %.2f m" % ax)
		if not ps.is_empty(): off.append("%s: %s" % [vid, str(ps.slice(0, 2))])
	check("anchors sit on the visible wheels (one car of every archetype, and the hand-made ones)", off.is_empty(), str(off.slice(0, 4)))
	var spec2 := CarCatalog.spec("silvio")
	var art2 := CarArt.new(spec2, VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
	var an2: Dictionary = _manifest("nissun_silvio_1991").anchors.duplicate(true)
	an2.rear_axle_m = float(an2.rear_axle_m) + 0.6
	an2.front_axle_m = float(an2.front_axle_m) - 0.6
	check("...and an anchor off the wheels is caught", not VehicleArtChecks.wheels_under_anchors(spec2, art2, an2).is_empty())

func _differs(spec: Dictionary, base: CarArt, side0: PackedByteArray, side_len: int, mods: Dictionary) -> bool:
	var m := VehicleManifest.applied(mods)
	var a := CarArt.new(spec, VehicleManifest.FACTORY, 0.0, 1, 1.0, m)
	if VehicleManifest._pictures(a) != VehicleManifest._pictures(base): return true
	var sm := m.duplicate()
	sm.shadow = false
	return CarGen.render(side_len, CarGen.design(spec), VehicleManifest.FACTORY, sm).get_data() != side0

## The slots: the garage's own fitting rules, and on one car of every archetype every option
## listed really changes the picture.
func _slots(cars: Dictionary) -> void:
	var g := GarageScreen.new()
	var disagree: Array = []
	var undrawn: Array = []
	var per_arch := {}
	for vid: String in cars:
		var id: String = cars[vid]
		var spec := VehicleManifest.spec_of(id)
		var arch := VehicleArchetypes.of(spec)
		if per_arch.has(arch): continue
		per_arch[arch] = true
		g.data = { "garage": [{ "id": id, "paint": "#8a8e94", "looks": {}, "parts": {} }] }
		g.sel = 0
		for pair: Array in [["BED", "bed", "tonneau"], ["SPARE", "rear_bumper", "spare"], ["BULL BAR", "front_bumper", "bash_bar"]]:
			if g._look_fits(pair[0]) != VehicleManifest.fits(spec, pair[1], pair[2]): disagree.append("%s %s" % [vid, pair[0]])
		var slots: Dictionary = _manifest(vid).slots
		var base := CarArt.new(spec, VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
		var side_len := mini(224, int(float(spec.length) * 38.0))      # the showroom's scale, as the build tries them
		var side0 := CarGen.render(side_len, CarGen.design(spec), VehicleManifest.FACTORY, { "shadow": false }).get_data()
		var stock_rim := PixCars.stock_rim(spec)
		for slot: String in slots:
			var vals: Array = slots[slot]
			for i in range(1, vals.size()):
				var v: String = vals[i]
				if slot == "wheel_family" and v == stock_rim: continue      # the factory rim is the stock look
				var looks: Variant = VehicleManifest.looks_of(slot, v)
				if looks == null or not _differs(spec, base, side0, side_len, looks): undrawn.append("%s %s=%s" % [vid, slot, v])
	g.free()
	check("the manifests' fitting rules are the garage's", disagree.is_empty(), str(disagree))
	check("every option a manifest lists shows on the car (one car of every archetype)", undrawn.is_empty(), "%d: %s" % [undrawn.size(), str(undrawn.slice(0, 8))])
	var beet: Dictionary = _manifest("hondo_beet_1992").slots
	check("a roadster's slots leave out roofs it hasn't got", not (beet.roof as Array).has("sunroof"), str(beet.roof))
	check("a pickup's bed options are there, a coupe has none", (_manifest("fjord_f_one_fiddy_2015").slots.bed as Array).size() > 1
		and (_manifest("nissun_silvio_1991").slots.bed as Array) == ["stock"])

func _showroom_manifest() -> Dictionary:
	return _manifest("nissun_silvio_1991")

## The showroom gate on pictures made up for it: the painter's own export passes, and each kind
## of broken sprite is caught.
func _showroom_gate() -> void:
	var ex: Variant = load("res://tools/export_showroom.gd")
	var m := _showroom_manifest()
	var good: Image = ex.render(CarCatalog.spec("silvio"))[0]
	var ps := VehicleArtChecks.showroom(good, m)
	check("the showroom exporter's Silvio passes the showroom gate", ps.is_empty(), str(ps))
	var low := Image.create(256, 96, false, Image.FORMAT_RGBA8)
	low.blit_rect(good, Rect2i(0, 0, 256, 93), Vector2i(0, 3))
	var wide := Image.create(255, 96, false, Image.FORMAT_RGBA8)
	var rgb := good.duplicate()
	rgb.convert(Image.FORMAT_RGB8)
	var soft := good.duplicate()
	var u := good.get_used_rect()
	soft.set_pixel(u.position.x + u.size.x / 2, u.position.y + 1, Color(1, 1, 1, 0.5))
	var one := Image.create(256, 96, false, Image.FORMAT_RGBA8)
	one.fill_rect(Rect2i(100, 60, 30, 19), Color.BLACK)
	var missed: Array = []
	for pair: Array in [["off the ground line", low], ["wrong size", wide], ["no alpha", rgb], ["blurred edge", soft], ["one wheel", one]]:
		if VehicleArtChecks.showroom(pair[1], m).is_empty(): missed.append(pair[0])
	check("a sprite off the ground line, the wrong size, with no alpha, blurred or one-wheeled fails", missed.is_empty(), str(missed))

## The runtime gate on a stack written out from CarArt's own slices.
func _runtime_gate() -> void:
	var m := _showroom_manifest()
	var dir := "user://vehicle_art_test/nissun_silvio_1991"
	_clear(dir)
	DirAccess.make_dir_recursive_absolute(dir.path_join("masks"))
	DirAccess.make_dir_recursive_absolute(dir.path_join("detachable"))
	var art := CarArt.new(CarCatalog.spec("silvio"), VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
	var atlas := art.atlas.get_image()
	for z in VehicleManifest.SLICES:
		var s := Image.create(art.size.x, art.size.y, false, Image.FORMAT_RGBA8)
		if z < art.n: s.blit_rect(atlas, Rect2i(z * art.size.x, 0, art.size.x, art.size.y), Vector2i.ZERO)
		_harden(s)
		s.save_png(dir.path_join("body_%02d.png" % z))
	var blank := Image.create(art.size.x, art.size.y, false, Image.FORMAT_RGBA8)
	for mk: String in VehicleManifest.MASKS: blank.save_png(dir.path_join("masks/mask_%s.png" % mk))
	for lk: String in VehicleManifest.LIGHT_MASKS: blank.save_png(dir.path_join("masks/light_%s.png" % lk))
	blank.save_png(dir.path_join("detachable/bumper_front.png"))
	blank.save_png(dir.path_join("detachable/bumper_rear.png"))
	var ps := VehicleArtChecks.runtime(dir, m)
	check("sixteen of CarArt's own slices, masks and bumpers pass the runtime gate", ps.is_empty(), str(ps.slice(0, 4)))
	var missed: Array = []
	# a slice short
	DirAccess.remove_absolute(dir.path_join("body_07.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a missing slice")
	blank.save_png(dir.path_join("body_07.png"))
	# a seventeenth
	blank.save_png(dir.path_join("body_16.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a seventeenth slice")
	DirAccess.remove_absolute(dir.path_join("body_16.png"))
	# a slice on another canvas
	Image.create(art.size.x + 2, art.size.y, false, Image.FORMAT_RGBA8).save_png(dir.path_join("body_03.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a different canvas")
	blank.save_png(dir.path_join("body_03.png"))
	# a soft edge, and a clear pixel that isn't black
	var soft := blank.duplicate()
	soft.set_pixel(3, 3, Color(1, 1, 1, 0.5))
	soft.save_png(dir.path_join("body_04.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a partly transparent pixel")
	var dirty := blank.duplicate()
	dirty.set_pixel(3, 3, Color(1, 0, 1, 0))
	dirty.save_png(dir.path_join("body_04.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a clear pixel that isn't black")
	blank.save_png(dir.path_join("body_04.png"))
	# no glass mask, no rear bumper
	DirAccess.remove_absolute(dir.path_join("masks/mask_glass.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("a missing mask")
	blank.save_png(dir.path_join("masks/mask_glass.png"))
	DirAccess.remove_absolute(dir.path_join("detachable/bumper_rear.png"))
	if VehicleArtChecks.runtime(dir, m).is_empty(): missed.append("no rear bumper")
	check("a missing or extra slice, another canvas, a soft or dirty pixel, a missing mask or bumper fails", missed.is_empty(), str(missed))
	_clear(dir)

## Solid or clear, and clear is clear black: what the slices must be.
func _harden(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5: img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif c.a < 1.0: img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

func _clear(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir): return
	for sub: String in DirAccess.get_directories_at(dir): _clear(dir.path_join(sub))
	for f: String in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
