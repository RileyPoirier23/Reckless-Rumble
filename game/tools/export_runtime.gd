## Writes every car's top-down stack as files an artist can paint over, in the folder layout
## CarArt reads back (see art/vehicles/RUNTIME.md):
##   godot --headless --path game -s tools/export_runtime.gd -- [out_dir] [id ...]
## out_dir defaults to res://art/vehicles/runtime (the game's own folder); the ids (catalogue ids
## or art ids) default to every catalogue car, the fleet and the hand-made cars in data/cars.
## The first argument is the folder when it has a "/" or a ":" in it (an id never does).
## Each car is the painter's stock car, undamaged, in factory grey; the paint mask says which
## pixels take the paint. Writing over a folder replaces what's there.
extends SceneTree

const FACTORY := Color("8a8e94")
## Two more paints the stack is painted in to find which pixels take the paint and how. Both are
## as light as the factory grey's band (over 0.55, under 0.7): the painter picks a stripe's, a
## vinyl roof's and a two-tone's colours by how light the paint is, and those stay as painted.
const PROBES := [Color("c8a060"), Color("7fb8b0")]
## And the game's own paints, light and dark, to tell apart the ops that come out the same in
## those three (they don't decide which pixels are paint: a stripe isn't, whatever its colour).
const TIEBREAK := [Color("c8342c"), Color("2c5a8a"), Color("e8e8e8"), Color("1e1e24"), Color("f0d040"), Color("3a6a3a"),
	Color("e86a1a"), Color("6a1a3a")]
const DEFAULT_OUT := "res://art/vehicles/runtime"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := DEFAULT_OUT
	if not args.is_empty() and (String(args[0]).contains("/") or String(args[0]).contains(":")):
		out = String(args[0])
		args = args.slice(1)
	var ids: Array = args if not args.is_empty() else every_id()
	CarArt.runtime_on = false
	var t0 := Time.get_ticks_msec()
	var files := 0
	var bytes := 0
	var cars := 0
	var odd := 0
	var seen := {}
	for want: String in ids:
		var spec := spec_of(want)
		if spec.is_empty():
			push_error("no car called %s" % want)
			continue
		var aid := PixCars.art_id(spec)
		if seen.has(aid):
			print("%-40s  skipped: same art id as %s" % [want, seen[aid]])
			continue
		seen[aid] = want
		var r := export_car(spec, out.path_join(aid))
		files += int(r.files)
		bytes += int(r.bytes)
		odd += int(r.unmatched)
		cars += 1
		print("%-40s n=%d %dx%d  body %d  bumpers %d+%d  wheel %d  masks %d  = %d files %d KB%s" % [aid, r.n, r.size.x, r.size.y,
			r.n, r.front, r.rear, r.wheel, r.masks, r.files, int(r.bytes) / 1024, ("  (%d paint px kept as painted)" % r.unmatched) if int(r.unmatched) > 0 else ""]
			+ ("  (%d px by the paint's lightness)" % r.lightness if int(r.lightness) > 0 else ""))
	print("%d cars, %d files, %d KB -> %s (%d paint px kept as painted, %.1f s)" % [cars, files, bytes / 1024, out, odd, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()

## Every car the game draws from the top: the catalogue, the fleet, and the hand-made specs.
static func every_id() -> Array:
	var out: Array = CarCatalog.ids() + CarCatalog.fleet_ids()
	for f in DirAccess.get_files_at("res://data/cars"):
		if f.ends_with(".json") and not f.get_basename() in out: out.append(f.get_basename())
	return out

## A catalogue id, a hand-made car or an art id -> its spec ({} when there's no such car).
static func spec_of(id: String) -> Dictionary:
	var spec := CarCatalog.spec(id)
	if not spec.is_empty(): return spec
	for cid: String in every_id():
		var s := CarCatalog.spec(cid)
		if PixCars.art_id(s) == id: return s
	return {}

## The painter's stock car: its images straight off the worker side (no textures needed).
static func painted(spec: Dictionary, paint: Color, bumpers := true) -> CarArt:
	var a := CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, {}, true)
	a.bumper_front = bumpers
	a.bumper_rear = bumpers
	a.compute()
	return a

## Writes one car's folder. Returns what went in it: n, size, front, rear (bumper slices), wheel,
## masks, files, bytes, unmatched (pixels that change with the paint in a way no paint op makes),
## lightness (pixels whose colour the painter picks by how light the paint is).
static func export_car(spec: Dictionary, dir: String) -> Dictionary:
	var was: bool = CarArt.runtime_on
	CarArt.runtime_on = false
	var g := painted(spec, FACTORY)
	var off := painted(spec, FACTORY, false)
	var paints: Array = PROBES + TIEBREAK
	var pa: Array[PackedInt32Array] = []
	for c: Color in paints: pa.append((painted(spec, c)._imgs.atlas as Image).get_data().to_int32_array())
	CarArt.runtime_on = was
	var sx := g.size.x
	var sy := g.size.y
	var n := g.n
	var aw := sx * n
	var body: PackedInt32Array = (g._imgs.atlas as Image).get_data().to_int32_array()
	# --- the paint: every ramp value through every op, in every paint. A pixel takes the (value,
	# op) that makes it in the grey and both probes; when several do (dark pixels near the road
	# round alike), the one that also makes it in the most tie-break paints
	var ops := CarArt.paint_ops()
	var by_grey := {}
	var tabs: Array[Dictionary] = []
	var rp: Array = []
	for c2: Color in paints:
		tabs.append({})
		rp.append(CarArt.paint_ramp(c2))
	var rg := CarArt.paint_ramp(FACTORY)
	for v in 7:
		for o in ops.size():
			var code := v * 256 + o
			var gv := CarArt.abgr(CarArt.paint_op(rg[v], ops[o]))
			if not by_grey.has(gv): by_grey[gv] = []
			(by_grey[gv] as Array).append(code)
			for pi2 in paints.size(): tabs[pi2][code] = CarArt.abgr(CarArt.paint_op((rp[pi2] as Array)[v], ops[o]))
	var mask := PackedByteArray()
	mask.resize(aw * sy * 4)
	var unmatched := 0
	var need := PROBES.size()
	# pixels the painter colours by how light the paint is (a stripe, a vinyl roof, a two-tone, a
	# black floating roof): neither the grey nor the mask says what they'd be in another paint
	var shifty := PackedByteArray()
	shifty.resize(aw * sy * 4)
	var shifts := 0
	for i in body.size():
		var gc := body[i]
		if gc == 0: continue
		var same := true
		for pi3 in need:
			if pa[pi3][i] != gc: same = false
		if same:
			for pi6 in range(need, paints.size()):
				if pa[pi6][i] != gc: same = false
			if not same:
				shifty[i * 4] = 255
				shifty[i * 4 + 1] = 255
				shifty[i * 4 + 2] = 255
				shifty[i * 4 + 3] = 255
				shifts += 1
			continue
		var hit := -1
		var best := -1
		for code: int in by_grey.get(gc, []):
			var ok := true
			for pi4 in need:
				if int(tabs[pi4][code]) != pa[pi4][i]:
					ok = false
					break
			if not ok: continue
			var score := 0
			for pi5 in range(need, paints.size()):
				if int(tabs[pi5][code]) == pa[pi5][i]: score += 1
			if score > best:
				best = score
				hit = code
		if hit < 0:
			unmatched += 1
			continue
		if best < paints.size() - need:
			shifty[i * 4] = 255
			shifty[i * 4 + 1] = 255
			shifty[i * 4 + 2] = 255
			shifty[i * 4 + 3] = 255
			shifts += 1
		mask[i * 4] = roundi(float(hit >> 8) * 255.0 / 6.0)
		mask[i * 4 + 1] = hit & 255
		mask[i * 4 + 3] = 255
	# --- the bumpers: what goes when they're knocked off (the bumper that juts past the body, and
	# the face under the bumper line that turns to a dark hole)
	var sh := CarArt._Shaper.new(spec, {}, { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, CarArt.CAR_SCALE, g.design)
	sh.run()
	var offb: PackedInt32Array = (off._imgs.atlas as Image).get_data().to_int32_array()
	var front := PackedInt32Array()
	var rear := PackedInt32Array()
	front.resize(body.size())
	rear.resize(body.size())
	for i2 in body.size():
		var c := body[i2]
		if c == 0: continue
		var xa := i2 % aw
		var x := xa % sx
		var y := i2 / aw
		var jut := not sh.bumper.is_empty() and sh.bumper[y * sx + x] == 1
		if not jut and offb[i2] == c: continue
		if x >= sx / 2: front[i2] = c
		else: rear[i2] = c
	# --- write it
	DirAccess.make_dir_recursive_absolute(dir.path_join("masks"))
	DirAccess.make_dir_recursive_absolute(dir.path_join("detachable"))
	_clear(dir, ["body_", "wheel_"])
	_clear(dir.path_join("detachable"), ["front_bumper_", "rear_bumper_"])
	_clear(dir.path_join("masks"), ["mask_"])
	var r := { "n": n, "size": Vector2i(sx, sy), "front": 0, "rear": 0, "wheel": 0, "masks": 0, "files": 0, "bytes": 0, "unmatched": unmatched,
		"lightness": shifts }
	# the plan the slices were drawn for: a spec by the same name but another shape isn't this car
	var pf := FileAccess.open(dir.path_join("plan.txt"), FileAccess.WRITE)
	pf.store_string(g._key + "\n")
	pf.close()
	r.files = int(r.files) + 1
	r.bytes = int(r.bytes) + FileAccess.get_file_as_bytes(dir.path_join("plan.txt")).size()
	var atlas := Image.create_from_data(aw, sy, false, Image.FORMAT_RGBA8, body.to_byte_array())
	for z in n: _save(atlas.get_region(Rect2i(z * sx, 0, sx, sy)), dir.path_join("body_%02d.png" % z), r)
	_save(Image.create_from_data(aw, sy, false, Image.FORMAT_RGBA8, mask), dir.path_join("masks/mask_paint.png"), r)
	r.masks = 1
	if shifts > 0:
		_save(Image.create_from_data(aw, sy, false, Image.FORMAT_RGBA8, shifty), dir.path_join("masks/mask_lightness.png"), r)
		r.masks = 2
	# the lit lamps, on strips as long as the atlas (slice z at x = z * width); the five the
	# spec names always, a beacon or a light bar only when the car has one
	for kk: String in CarArt.LAMP_KINDS:
		var lit: Image = g._imgs[kk]
		var strip := Image.create(aw, sy, false, Image.FORMAT_RGBA8)
		strip.blit_rect(lit, Rect2i(Vector2i.ZERO, lit.get_size()), Vector2i(g.lamp_z0 * sx, 0))
		if kk in ["beacon", "bar"] and strip.get_used_rect().size.x <= 0: continue
		_save(strip, dir.path_join("masks/mask_%s.png" % CarArt.LAMP_FILES[kk]), r)
		r.masks = int(r.masks) + 1
	# the bumpers, a file for each slice they're on
	var fi := Image.create_from_data(aw, sy, false, Image.FORMAT_RGBA8, front.to_byte_array())
	var ri := Image.create_from_data(aw, sy, false, Image.FORMAT_RGBA8, rear.to_byte_array())
	for z2 in n:
		var fs := fi.get_region(Rect2i(z2 * sx, 0, sx, sy))
		if fs.get_used_rect().size.x > 0:
			_save(fs, dir.path_join("detachable/front_bumper_%02d.png" % z2), r)
			r.front = int(r.front) + 1
		var rs := ri.get_region(Rect2i(z2 * sx, 0, sx, sy))
		if rs.get_used_rect().size.x > 0:
			_save(rs, dir.path_join("detachable/rear_bumper_%02d.png" % z2), r)
			r.rear = int(r.rear) + 1
	# the steerable front wheel's own stack
	var wimg: Image = g._imgs.wheel
	for z3 in g.wheel_n:
		_save(wimg.get_region(Rect2i(z3 * g.wheel_size.x, 0, g.wheel_size.x, g.wheel_size.y)), dir.path_join("wheel_%02d.png" % z3), r)
	r.wheel = g.wheel_n
	return r

## Removes the numbered files a re-export would leave behind (a car one slice shorter).
static func _clear(dir: String, prefixes: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".png"): continue
		for pre: String in prefixes:
			if f.begins_with(pre): DirAccess.remove_absolute(dir.path_join(f))

static func _save(img: Image, path: String, r: Dictionary) -> void:
	img.save_png(path)
	r.files = int(r.files) + 1
	r.bytes = int(r.bytes) + FileAccess.get_file_as_bytes(path).size()
