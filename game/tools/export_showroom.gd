## Paints the 256x96 showroom sprite and paint mask for every car: the whole catalogue
## (CarCatalog.ids() and fleet_ids()) and the hand-made cars in data/cars, into
## art/vehicles/showroom/<art_id>.png and showroom/masks/<art_id>_paint.png. Faces right, the
## lowest tyre row on y=78, everything inside the 224x76 footprint, transparent padding.
## PixCars.showroom() prefers these files over the painter, so an artist's file dropped over
## one wins; re-running this overwrites them all, so pass ids to redo just a few.
##   godot --headless --path game -s tools/export_showroom.gd -- [out_dir] [id ...]
## out_dir (anything with a / or a :) defaults to res://art/vehicles/showroom; ids are
## catalogue ids (silvio, fjord_f_one_fiddy_2015) or art ids (nissun_silvio_1991).
## See art/vehicles/SHOWROOM.md for the contract.
extends SceneTree

const W := 256
const H := 96
const BASELINE := 78              # the lowest opaque tyre row
const FOOT := Vector2i(224, 76)   # the most a car may cover, centred on the canvas
const FACTORY := Color("8a8e94")
## One scale for every car, so a kei car is small next to a dually: 8.3 m (the stretch limo)
## fills the 224 px footprint and a 2.5 m tall van fits under the 76.
const PX_PER_M := 26.0
## Buses, box trucks and semis can't share that scale and stay inside the footprint (a city bus
## is 12 m, a sleeper cab 4 m tall), so the big rigs share a second, smaller one of their own.
const BIG_PX_PER_M := 18.0
const BIG_BODIES := ["bus", "semi", "boxtruck"]
const MASK_LEVELS := [0.125, 0.375, 0.625, 0.875]   # deep, shadow, base, highlight

func _init() -> void:
	var out := "res://art/vehicles/showroom"
	var only := {}
	for arg in OS.get_cmdline_user_args():
		if arg.contains("/") or arg.contains(":"): out = arg
		else: only[arg] = true
	if out.begins_with("res://") or out.begins_with("user://"): out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out.path_join("masks"))
	var n := 0
	var big := 0
	var bad: Array = []
	var t0 := Time.get_ticks_msec()
	for pair: Array in cars():
		var id: String = pair[0]
		var spec: Dictionary = pair[1]
		if not only.is_empty() and not only.has(id) and not only.has(String(pair[2])): continue
		var r := render(spec)
		save_png(r[0] as Image, out.path_join(id + ".png"))
		save_png(r[1] as Image, out.path_join("masks").path_join(id + "_paint.png"))
		n += 1
		if is_big(spec): big += 1
		var why := check(r[0] as Image)
		if why != "": bad.append("%s: %s" % [id, why])
	print("%d cars (%d big rigs at %.0f px/m, the rest at %.0f px/m) -> %s in %.1f s" % [n, big, BIG_PX_PER_M, PX_PER_M, out, (Time.get_ticks_msec() - t0) / 1000.0])
	for b in bad: print("OFF CONTRACT  " + b)
	quit(1 if not bad.is_empty() else 0)

## Every car once, as [art_id, spec, catalogue id]: the catalogue (hand-made cars first, then
## the table, then the fleet), then any data/cars JSON the catalogue doesn't list.
static func cars() -> Array:
	var out: Array = []
	var seen := {}
	for id in CarCatalog.ids() + CarCatalog.fleet_ids():
		var s := CarCatalog.spec(String(id))
		var aid := PixCars.art_id(s)
		if seen.has(aid): continue
		seen[aid] = true
		out.append([aid, s, String(id)])
	for f in DirAccess.get_files_at("res://data/cars"):
		if not f.ends_with(".json"): continue
		var s: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/" + f))
		var aid := PixCars.art_id(s)
		if seen.has(aid): continue
		seen[aid] = true
		out.append([aid, s, f.get_basename()])
	return out

static func is_big(spec: Dictionary) -> bool:
	return String(spec.get("body", "")) in BIG_BODIES

## Pixels along the car at the shared scale.
static func length_px(spec: Dictionary) -> int:
	return int(round(float(spec.get("length", 4.6)) * (BIG_PX_PER_M if is_big(spec) else PX_PER_M)))

## [sprite, mask]: the car in factory grey with its paint brought down to the four values the
## mask names, and the mask: grey levels marking which paint value each paintable pixel takes
## (found by painting the car twice in different colours), transparent everywhere else.
static func render(spec: Dictionary) -> Array:
	var len := length_px(spec)
	var mods := { "year": int(spec.get("year", 2000)), "shadow": false }
	var a := PixCars.image_of(spec, len, FACTORY, mods)
	var b := PixCars.image_of(spec, len, Color("ff00ff"), mods)
	# the tyres' lowest opaque row goes on the baseline (the painter puts it on or a row above
	# its ground line, depending on the tyre)
	var low := -1
	for spot: Array in PixCars.wheel_spots(spec, len, mods):
		var xx := int(spot[0])
		for yy in range(a.get_height() - 1, -1, -1):
			if a.get_pixel(xx, yy).a >= 0.5:
				low = maxi(low, yy)
				break
	if low < 0: low = a.get_height() - 9
	var ox := (W - len) / 2 - 22
	var oy := BASELINE - low
	var sprite := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var mask := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var pal := PixCars._palette(FACTORY, "gloss")
	var tones := [pal.deep, pal.sh, pal.base, pal.hi]
	for yy in a.get_height():
		var ty := yy + oy
		# nothing under the road: a mud flap or a step that hangs a row past the tyres is cut
		if ty < 0 or ty > BASELINE: continue
		for xx in a.get_width():
			var tx := xx + ox
			if tx < 0 or tx >= W: continue
			var ca := a.get_pixel(xx, yy)
			# hard edges only: no half-transparent pixels, and clear means clear black
			if ca.a < 0.5: continue
			ca.a = 1.0
			if not ca.is_equal_approx(b.get_pixel(xx, yy)):
				var best := 0
				var bd := 9.0
				for i in tones.size():
					var d := absf((tones[i] as Color).get_luminance() - ca.get_luminance())
					if d < bd:
						bd = d
						best = i
				ca = tones[best]
				var g: float = MASK_LEVELS[best]
				mask.set_pixel(tx, ty, Color(g, g, g, 1.0))
			sprite.set_pixel(tx, ty, ca)
	return [sprite, mask]

## An 8-bit RGBA PNG with nothing in it but the picture: Godot's encoder adds an sRGB chunk,
## which goes, so every file is IHDR, IDAT and IEND only.
static func save_png(img: Image, path: String) -> void:
	var src := img.save_png_to_buffer()
	var out := src.slice(0, 8)
	var i := 8
	while i + 8 <= src.size():
		var n := (src[i] << 24) | (src[i + 1] << 16) | (src[i + 2] << 8) | src[i + 3]
		var kind := src.slice(i + 4, i + 8).get_string_from_ascii()
		if kind in ["IHDR", "IDAT", "IEND"]: out.append_array(src.slice(i, i + 12 + n))
		i += 12 + n
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(out)
	f.close()

## Why a sprite breaks the contract, or "" when it doesn't: the size, the baseline, the footprint.
static func check(img: Image) -> String:
	if img.get_size() != Vector2i(W, H): return "canvas %s" % str(img.get_size())
	var u := img.get_used_rect()
	if u.end.y - 1 != BASELINE: return "lowest row %d, not %d" % [u.end.y - 1, BASELINE]
	if u.size.x > FOOT.x or u.position.x < (W - FOOT.x) / 2 or u.end.x > (W + FOOT.x) / 2: return "%d px wide at x %d..%d" % [u.size.x, u.position.x, u.end.x - 1]
	if BASELINE + 1 - u.position.y > FOOT.y: return "%d px tall" % (BASELINE + 1 - u.position.y)
	return ""
