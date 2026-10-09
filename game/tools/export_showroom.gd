## Paints a 256x96 showroom preview and paint mask for every car in data/cars, in the layout the
## authored sprites use (faces right, ground at y=78, footprint inside 224x76, one shared scale).
## Artists can trace proportions from these; drop finished art over them and the game picks it up.
##   godot --headless --path game -s tools/export_showroom.gd -- <out_dir>
extends SceneTree

const W := 256
const H := 96
const PX_PER_M := 38.0          # 5.9 m fills the 224 px footprint
const FACTORY := Color("8a8e94")

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://showroom"
	DirAccess.make_dir_recursive_absolute(out.path_join("masks"))
	var n := 0
	for f in DirAccess.get_files_at("res://data/cars"):
		if not f.ends_with(".json"): continue
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/" + f))
		var id := PixCars.art_id(spec)
		var pair := render(spec)
		(pair[0] as Image).save_png(out.path_join(id + ".png"))
		(pair[1] as Image).save_png(out.path_join("masks").path_join(id + "_paint.png"))
		print("%s  %s" % [id, f])
		n += 1
	print("%d cars -> %s" % [n, out])
	quit()

## [sprite, mask]: the car in factory grey, and grey levels marking which paint value each
## paintable pixel takes (found by painting it twice in different colours).
static func render(spec: Dictionary) -> Array:
	var len := mini(224, int(float(spec.get("length", 4.6)) * PX_PER_M))
	var body := PixCars.body_of(spec)
	var mods := { "year": int(spec.get("year", 2000)) }
	var a := PixCars.image(len, body, FACTORY, mods)
	# tall things (a wrecker's boom) shrink until they fit the 224x76 footprint
	var used := a.get_used_rect()
	var tall := (a.get_height() - 8) - used.position.y
	if tall > 76 or used.size.x > 224:
		len = int(float(len) * minf(76.0 / float(tall), 224.0 / float(used.size.x)))
		a = PixCars.image(len, body, FACTORY, mods)
	var b := PixCars.image(len, body, Color("ff00ff"), mods)
	var sprite := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var mask := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var ox := (W - len) / 2 - 22
	var oy := 78 - (a.get_height() - 8)
	sprite.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i(ox, oy))
	var pal := PixCars._palette(FACTORY, "gloss")
	var tones := [[pal.deep, 0.125], [pal.sh, 0.375], [pal.base, 0.625], [pal.hi, 0.875]]
	for yy in a.get_height():
		for xx in a.get_width():
			var ca := a.get_pixel(xx, yy)
			if ca.a < 0.5 or ca.is_equal_approx(b.get_pixel(xx, yy)): continue
			var best := 0.0
			var bd := 9.0
			for t in tones:
				var d := absf((t[0] as Color).get_luminance() - ca.get_luminance())
				if d < bd:
					bd = d
					best = float(t[1])
			var tx := xx + ox
			var ty := yy + oy
			if tx >= 0 and ty >= 0 and tx < W and ty < H: mask.set_pixel(tx, ty, Color(best, best, best, 1.0))
	return [sprite, mask]
