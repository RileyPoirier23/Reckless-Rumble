## The authored top-down stacks: tools/export_runtime.gd writes a car's slices, masks, lamps,
## bumpers and wheel; CarArt reads them back for a stock car and draws exactly what the painter
## draws; anything modded or damaged still goes to the painter.
## godot --headless --path game -s tests/runtime_art_tests.gd
extends SceneTree

var fails := 0
const DIR := "user://runtime_art_test"
## The factory grey the files are in, two paints in its band, and three well out of it.
const PAINTS := ["8a8e94", "c8a060", "7fb8b0", "c8342c", "2c5a8a", "e8e8e8", "1e1e24"]

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var tool: GDScript = load("res://tools/export_runtime.gd")
	_wipe(DIR)
	var ids: Array = ["silvio", "charjer", _first("pickup"), _first("van"), _first("kei")]
	var specs := {}
	for id: String in ids:
		var spec := CarCatalog.spec(id)
		specs[id] = spec
		var r: Dictionary = tool.export_car(spec, DIR.path_join(PixCars.art_id(spec)))
		check("%s exports with every paint pixel accounted for" % id, int(r.unmatched) == 0 and int(r.files) > int(r.n), "%d files, %d unmatched" % [r.files, r.unmatched])
	CarArt.runtime_dir = DIR
	CarArt.clear_stacks()
	for id: String in ids:
		_files(id, specs[id])
		_same(id, specs[id])
	_lightness(tool)
	_painter_still(specs.silvio)
	_hand_painted(specs.silvio)
	CarArt.runtime_dir = "res://art/vehicles/runtime/"
	CarArt.clear_stacks()
	_wipe(DIR)
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

func _first(cls: String) -> String:
	return String(CarCatalog.by_class(cls)[0])

## The folder holds what RUNTIME.md promises: one canvas for every slice, strips as long as the
## atlas, the five lamp masks, the bumpers on the slices they're on, the wheel's slices.
func _files(id: String, spec: Dictionary) -> void:
	var dir := DIR.path_join(PixCars.art_id(spec))
	CarArt.runtime_on = false
	var ref := CarArt.new(spec, Color("8a8e94"), 0.0, 1, CarArt.CAR_SCALE)
	CarArt.runtime_on = true
	var sizes := {}
	var z := 0
	while FileAccess.file_exists(dir.path_join("body_%02d.png" % z)):
		var img := Image.load_from_file(dir.path_join("body_%02d.png" % z))
		sizes[img.get_size()] = true
		if img.get_format() != Image.FORMAT_RGBA8: sizes["not rgba8"] = true
		z += 1
	check("%s: one body slice per stack slice, all the plan's canvas" % id, z == ref.n and sizes.size() == 1 and sizes.has(ref.size), "%d slices, %s" % [z, str(sizes.keys())])
	var strip := Vector2i(ref.size.x * ref.n, ref.size.y)
	var bad: Array = []
	for f: String in ["mask_paint", "mask_head", "mask_brake", "mask_reverse", "mask_signal_left", "mask_signal_right"]:
		var p := dir.path_join("masks/%s.png" % f)
		if not FileAccess.file_exists(p) or Image.load_from_file(p).get_size() != strip: bad.append(f)
	check("%s: the paint and lamp masks are strips the atlas' size" % id, bad.is_empty(), str(bad))
	var det: Array = []
	var front := 0
	var rear := 0
	for f2 in DirAccess.get_files_at(dir.path_join("detachable")):
		if Image.load_from_file(dir.path_join("detachable").path_join(f2)).get_size() != ref.size: det.append(f2)
		if f2.begins_with("front_bumper_"): front += 1
		if f2.begins_with("rear_bumper_"): rear += 1
	check("%s: both bumpers come off, on the body's canvas" % id, front > 0 and rear > 0 and det.is_empty(), "%d front, %d rear %s" % [front, rear, str(det)])
	var wz := 0
	var wsz := {}
	while FileAccess.file_exists(dir.path_join("wheel_%02d.png" % wz)):
		wsz[Image.load_from_file(dir.path_join("wheel_%02d.png" % wz)).get_size()] = true
		wz += 1
	check("%s: the wheel's slices share one canvas, as many as the painter's" % id, wz == ref.wheel_n and wsz.size() == 1 and wsz.has(ref.wheel_size), "%d, %s" % [wz, str(wsz.keys())])
	# (the empty pixels are transparent black: no halo at the edges)
	var halo := 0
	var b0 := Image.load_from_file(dir.path_join("body_00.png")).get_data()
	for i in range(0, b0.size(), 4):
		if b0[i + 3] == 0 and (b0[i] != 0 or b0[i + 1] != 0 or b0[i + 2] != 0): halo += 1
	check("%s: transparent pixels are transparent black" % id, halo == 0, "%d" % halo)

## Loaded from its files, the stock car is the painter's car, pixel for pixel, lamp for lamp.
func _same(id: String, spec: Dictionary) -> void:
	var off: Array = []
	var lamps_off: Array = []
	var meta_off: Array = []
	for hex: String in PAINTS:
		var paint := Color(hex)
		CarArt.runtime_on = false
		var ref := CarArt.new(spec, paint, 0.0, 7, CarArt.CAR_SCALE)
		CarArt.runtime_on = true
		var art := CarArt.new(spec, paint, 0.0, 7, CarArt.CAR_SCALE)
		if not art.authored:
			off.append(hex + " not authored")
			continue
		if art.atlas.get_image().get_data() != ref.atlas.get_image().get_data() or art.n != ref.n or art.size != ref.size:
			off.append("%s (%d px)" % [hex, _diff(art.atlas.get_image(), ref.atlas.get_image())])
		for kk: String in CarArt.LAMP_KINDS:
			if _lit(art, kk) != _lit(ref, kk): lamps_off.append("%s %s" % [hex, kk])
		if art.wheel_tex.get_image().get_data() != ref.wheel_tex.get_image().get_data() or art.wheel_n != ref.wheel_n or art.wheel_size != ref.wheel_size:
			meta_off.append(hex + " wheel")
		if art.has_beacons != ref.has_beacons or not _spots_match(art.lamp_spots, ref.lamp_spots): meta_off.append(hex + " lamp spots")
	check("%s: loaded from its files it is the painter's stock car in every paint" % id, off.is_empty(), str(off))
	check("%s: the lamp masks light the same pixels on the same slices" % id, lamps_off.is_empty(), str(lamps_off))
	check("%s: the same wheel stack and lamp glows" % id, meta_off.is_empty(), str(meta_off))
	# drawn on a worker thread, the same
	var j := CarArt.build(spec, Color("c8342c"), 0.0, 3, CarArt.CAR_SCALE)
	var a2 := j.take()
	CarArt.runtime_on = false
	var r2 := CarArt.new(spec, Color("c8342c"), 0.0, 3, CarArt.CAR_SCALE)
	CarArt.runtime_on = true
	check("%s: built on a worker, the same" % id, a2.authored and a2.atlas.get_image().get_data() == r2.atlas.get_image().get_data())

func _diff(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size(): return -1
	var da := a.get_data().to_int32_array()
	var db := b.get_data().to_int32_array()
	var cnt := 0
	for i in da.size():
		if da[i] != db[i]: cnt += 1
	return cnt

## Every lit pixel of one lamp kind: "x,y,slice" -> colour.
func _lit(art: CarArt, kind: String) -> Dictionary:
	var out := {}
	var img: Image = art.lamp_tex[kind].get_image()
	var sx := art.size.x
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0: continue
			out["%d,%d,%d" % [x % sx, y, art.lamp_z0 + x / sx]] = c.to_html()
	return out

## The glows: the same lamps in the same places (their colours to within 8-bit rounding).
func _spots_match(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	var left := b.duplicate()
	for s: Array in a:
		var hit := -1
		for k in left.size():
			var t: Array = left[k]
			if int(s[0]) == int(t[0]) and int(s[3]) == int(t[3]) and (s[1] as Vector3).is_equal_approx(t[1]) \
					and absf((s[2] as Color).r - (t[2] as Color).r) < 0.01 and absf((s[2] as Color).g - (t[2] as Color).g) < 0.01:
				hit = k
				break
		if hit < 0: return false
		left.remove_at(hit)
	return true

## A car whose stripes the painter colours by how light the paint is: its stack is used in paints
## as light as the factory grey, the painter draws it in the others, and either way it's the
## painter's car.
func _lightness(tool: GDScript) -> void:
	var spec := CarCatalog.spec("fjord_mustank_fastback_1969")
	var r: Dictionary = tool.export_car(spec, DIR.path_join(PixCars.art_id(spec)))
	check("a striped car's export marks its stripes as picked by the paint's lightness", int(r.lightness) > 0 \
		and FileAccess.file_exists(DIR.path_join(PixCars.art_id(spec)).path_join("masks/mask_lightness.png")), "%d px" % r.lightness)
	var used: Array = []
	var off: Array = []
	for hex: String in PAINTS:
		CarArt.runtime_on = false
		var ref := CarArt.new(spec, Color(hex), 0.0, 1, CarArt.CAR_SCALE)
		CarArt.runtime_on = true
		var art := CarArt.new(spec, Color(hex), 0.0, 1, CarArt.CAR_SCALE)
		if art.authored: used.append(hex)
		if art.atlas.get_image().get_data() != ref.atlas.get_image().get_data(): off.append(hex)
	check("its stack is used only in paints in the factory grey's band", used == ["8a8e94", "c8a060", "7fb8b0"], str(used))
	check("and in every paint it's the painter's car", off.is_empty(), str(off))

## Mods, damage, wear, another scale, no folder: the painter, every time.
func _painter_still(spec: Dictionary) -> void:
	var paint := Color("c8342c")
	check("the stock Silvio is drawn from its files", CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE).authored)
	check("its own year is still stock", CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, { "year": int(spec.year), "shadow": false }).authored)
	var cases := {
		"a dented one": CarArt.new(spec, paint, 0.4, 1, CarArt.CAR_SCALE),
		"a front end hit": CarArt.new(spec, paint, { "front": 0.8 }, 1, CarArt.CAR_SCALE),
		"a winged one": CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, { "spoiler": "wing" }),
		"a tinted one": CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, { "tint": 0.5 }),
		"a dirty one": CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, { "wear": { "dirt": 0.5 } }),
		"another year": CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, { "year": 2005 }),
		"the garage's scale": CarArt.new(spec, paint, 0.0, 1, 1.0),
		"a trailer": CarArt.new({ "body": "trailer", "length": 13.6, "width": 2.55, "track": 2.1 }, paint, 0.0, 1, CarArt.CAR_SCALE),
	}
	var wrong: Array = []
	for k: String in cases:
		if (cases[k] as CarArt).authored: wrong.append(k)
	# (a catalogue car's design is its catalogue entry's, so rust only reaches the painter on a
	# car that isn't in the catalogue)
	var rusty := spec.duplicate(true)
	rusty.erase("id")
	rusty.art = { "rust": 0.5 }
	if CarArt.new(rusty, paint, 0.0, 1, CarArt.CAR_SCALE).authored: wrong.append("a rusty one")
	check("modded, damaged, worn, rescaled cars and trailers go to the painter", wrong.is_empty(), str(wrong))
	# a damaged car still looks like the painter's damaged car (the loader didn't touch it)
	var dented: CarArt = cases["a dented one"]
	CarArt.runtime_on = false
	var ref := CarArt.new(spec, paint, 0.4, 1, CarArt.CAR_SCALE)
	CarArt.runtime_on = true
	check("a damaged car is the painter's damaged car", dented.atlas.get_image().get_data() == ref.atlas.get_image().get_data())
	var other := CarCatalog.spec("silvio")
	other.width = float(other.width) + 0.3
	check("a car by the same name but another shape goes to the painter", not CarArt.new(other, paint, 0.0, 1, CarArt.CAR_SCALE).authored)
	var nobody := spec.duplicate(true)
	nobody.make = "Nobody"
	check("a car with no folder goes to the painter", not CarArt.new(nobody, paint, 0.0, 1, CarArt.CAR_SCALE).authored)

## The point of it all: a slice painted by hand shows up in the game with no code change, and a
## paint mask decides what takes the paint.
func _hand_painted(spec: Dictionary) -> void:
	var dir := DIR.path_join(PixCars.art_id(spec))
	var path := dir.path_join("body_08.png")
	var img := Image.load_from_file(path)
	var mask := Image.load_from_file(dir.path_join("masks/mask_paint.png"))
	var sx := img.get_width()
	# a pixel that isn't paint gets a hand-painted colour; a paint pixel is taken off the mask
	var spot := Vector2i(-1, -1)
	var paint_px := Vector2i(-1, -1)
	for y in img.get_height():
		for x in sx:
			if img.get_pixel(x, y).a8 == 0: continue
			var painted := mask.get_pixel(8 * sx + x, y).a8 > 0
			if not painted and spot.x < 0: spot = Vector2i(x, y)
			if painted and paint_px.x < 0: paint_px = Vector2i(x, y)
	img.set_pixelv(spot, Color("00ff00"))
	img.save_png(path)
	mask.set_pixel(8 * sx + paint_px.x, paint_px.y, Color(0, 0, 0, 0))
	img.set_pixelv(paint_px, Color("ff00ff"))
	img.save_png(path)
	mask.save_png(dir.path_join("masks/mask_paint.png"))
	CarArt.clear_stacks()
	var art := CarArt.new(spec, Color("2c5a8a"), 0.0, 1, CarArt.CAR_SCALE)
	var atl := art.atlas.get_image()
	check("a hand-painted pixel shows up in the game", art.authored and atl.get_pixel(8 * sx + spot.x, spot.y).to_html(false) == "00ff00")
	check("a pixel taken off the paint mask keeps its own colour", atl.get_pixel(8 * sx + paint_px.x, paint_px.y).to_html(false) == "ff00ff")
	# a slice on the wrong canvas: the painter draws the car (and says so)
	Image.create(sx + 3, img.get_height(), false, Image.FORMAT_RGBA8).save_png(dir.path_join("body_09.png"))
	CarArt.clear_stacks()
	check("slices on different canvases fall back to the painter", not CarArt.new(spec, Color("2c5a8a"), 0.0, 1, CarArt.CAR_SCALE).authored)
	CarArt.clear_stacks()

func _wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir): return
	for sub in DirAccess.get_directories_at(dir): _wipe(dir.path_join(sub))
	for f in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
