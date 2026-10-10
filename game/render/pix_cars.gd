## Side-view pixel cars: the cutscenes, the death screens, the garage, MarketThing, the auction,
## the meet, the loading screens, the counter's queue and the showroom sprites
## (art/vehicles/showroom) all come from here. The painting itself is CarGen's: every catalogue
## car has its own side profile, generated from its catalogue facts the way CAGE BOSS generates
## faces. This is the front door, kept the same for everybody who already calls it.
##
## draw_car(p, x, y, len, car, paint, dmg, flip, tilt, mods) and image_of(car, len, paint, mods,
## dmg) draw a car as itself (car = a spec, a catalogue entry, a traffic car, or { "cat": id }).
## draw()/image() with just a body name ("coupe", "pickup"...) still work and draw a generic car
## of that body and year. x = rear bumper, y = where the tyres touch the ground, facing right
## (flip for left).
## mods: rim (mesh, fivespoke, tenspoke, multispoke, turbofan, deepdish, dish, steel, hubcap,
##   beadlock, wire), rim_color, rim_size, caliper, drop (-1 lifted .. 1 slammed), tire (stock,
##   mud, lowpro), spoiler (none, ducktail, wing, gt), kit ({lip, skirts, diffuser}), fenders
##   (stock, flared), livery (none, slash, split, sponsor, flames), stripes (none, racing, side,
##   rally), stripe_color (left out: dark on pale paint, light on dark),
##   tint, finish (gloss, matte, metallic, pearl, chrome), year, exhaust (single, dual, quad,
##   side), rollbar, lightbar, bash, spare, bed (stock, tonneau), hood (stock, vented), smooth,
##   lights_on, glow (lit lamps spill past the outline, for night and dusk), shadow, rust.
## dmg: front, rear (0..1 crush), roof, glass, wheel_off, flat, smoke, bumper, lights, driver.
class_name PixCars
extends RefCounted

const PX_PER_M := 36.6
const INK := Color("15181f")
const GLASS := Color("2f4f74")
const GLASS_HI := Color("4f78a2")
const GLASS_LO := Color("22384f")
const TIRE := Color("1b1e24")
const SIDEWALL := Color("2c3038")
const WELL := Color("0d0f13")
const CHROME := Color("c9cfd6")
const BLACK_TRIM := Color("22262d")

## The old fixed silhouettes, rear (x=0) to nose (x=1), heights in car lengths. Kept for callers
## that still read their wheel spots or year; the drawing itself comes from CarGen.
const BODIES := {
	"coupe": {
		"shape": [[0.0, 0.065], [0.0, 0.153], [0.012, 0.18], [0.03, 0.193], [0.06, 0.209], [0.15, 0.214], [0.18, 0.222], [0.235, 0.254], [0.294, 0.281], [0.353, 0.292], [0.4, 0.294], [0.5, 0.294], [0.53, 0.29], [0.56, 0.283], [0.618, 0.254], [0.676, 0.216], [0.72, 0.205], [0.8, 0.199], [0.88, 0.186], [0.94, 0.168], [0.975, 0.15], [0.995, 0.128], [1.0, 0.1], [1.0, 0.08], [0.985, 0.058]],
		"glass": [[0.18, 0.212], [0.206, 0.23], [0.235, 0.247], [0.265, 0.261], [0.294, 0.272], [0.353, 0.282], [0.4, 0.285], [0.5, 0.285], [0.53, 0.282], [0.56, 0.275], [0.618, 0.247], [0.668, 0.21]],
		"pillar": [0.29, 0.372], "doors": [0.372, 0.66], "belt": 0.207, "crease": 0.64, "wr": 0.233, "wf": 0.797, "wheel": 0.072, "lamp": "slim", "year": 1991,
	},
	"hatch": {
		"shape": [[0.0, 0.08], [0.0, 0.2, 1], [0.012, 0.232], [0.06, 0.262], [0.14, 0.304], [0.25, 0.314], [0.55, 0.318], [0.6, 0.31], [0.7, 0.226], [0.88, 0.206], [0.98, 0.19], [1.0, 0.17], [1.0, 0.08], [0.985, 0.056]],
		"glass": [[0.062, 0.238], [0.142, 0.297], [0.25, 0.307], [0.55, 0.31], [0.592, 0.302], [0.684, 0.229]],
		"pillar": [0.2, 0.45], "doors": [0.24, 0.452, 0.665], "belt": 0.215, "crease": 0.45, "wr": 0.19, "wf": 0.81, "wheel": 0.066, "lamp": "square", "year": 1986,
	},
	"sedan": {
		"shape": [[0.0, 0.09], [0.0, 0.2], [0.018, 0.226], [0.16, 0.236], [0.25, 0.243], [0.34, 0.3], [0.42, 0.321], [0.55, 0.322], [0.6, 0.31], [0.71, 0.244], [0.88, 0.229], [0.97, 0.212], [1.0, 0.186], [1.0, 0.085], [0.985, 0.058]],
		"glass": [[0.272, 0.246], [0.35, 0.298], [0.42, 0.313], [0.55, 0.314], [0.594, 0.303], [0.694, 0.247]],
		"pillar": [0.36, 0.47], "doors": [0.36, 0.47, 0.675], "belt": 0.232, "crease": 0.4, "wr": 0.19, "wf": 0.81, "wheel": 0.074, "lamp": "angry", "year": 2015,
	},
	"wagon": {
		"shape": [[0.0, 0.09], [0.0, 0.22, 1], [0.01, 0.29], [0.04, 0.316], [0.55, 0.319], [0.6, 0.308], [0.7, 0.237], [0.88, 0.222], [0.97, 0.206], [1.0, 0.18], [1.0, 0.085], [0.985, 0.058]],
		"glass": [[0.03, 0.242], [0.042, 0.305], [0.55, 0.311], [0.59, 0.3], [0.685, 0.241]],
		"pillar": [0.2, 0.36, 0.47], "doors": [0.24, 0.47, 0.675], "belt": 0.228, "crease": 0.44, "wr": 0.19, "wf": 0.81, "wheel": 0.068, "lamp": "square", "year": 1995,
	},
	"muscle": {
		"shape": [[0.0, 0.08], [0.0, 0.17], [0.02, 0.19], [0.2, 0.2], [0.3, 0.248], [0.42, 0.284], [0.53, 0.285], [0.58, 0.27], [0.66, 0.206], [0.9, 0.195], [0.98, 0.182], [1.0, 0.162], [1.0, 0.08], [0.985, 0.058]],
		"glass": [[0.322, 0.248], [0.42, 0.277], [0.53, 0.278], [0.574, 0.265], [0.645, 0.209]],
		"pillar": [], "doors": [0.36, 0.64], "belt": 0.197, "crease": 0.38, "wr": 0.18, "wf": 0.79, "wheel": 0.07, "lamp": "round", "year": 1969,
	},
	"pickup": {
		"shape": [[0.0, 0.1], [0.0, 0.24, 1], [0.01, 0.249], [0.36, 0.249, 1], [0.362, 0.338, 1], [0.376, 0.352], [0.53, 0.352], [0.546, 0.343], [0.667, 0.25], [0.95, 0.233], [0.99, 0.222], [1.0, 0.205], [1.0, 0.1], [0.985, 0.088]],
		"glass": [[0.405, 0.25], [0.405, 0.334], [0.53, 0.337], [0.552, 0.333], [0.655, 0.252]],
		"pillar": [], "doors": [0.38, 0.655], "belt": 0.247, "crease": 0.37, "wr": 0.227, "wf": 0.796, "wheel": 0.072, "lamp": "square", "year": 1988, "bed": [0.012, 0.36],
	},
	"tow": {
		"shape": [[0.0, 0.1], [0.0, 0.25, 1], [0.012, 0.256], [0.42, 0.256, 1], [0.424, 0.38, 1], [0.44, 0.393], [0.6, 0.393], [0.62, 0.38], [0.69, 0.286], [0.95, 0.27], [1.0, 0.246], [1.0, 0.1], [0.985, 0.08]],
		"glass": [[0.446, 0.29], [0.449, 0.377], [0.6, 0.38], [0.674, 0.29]],
		"pillar": [0.53], "doors": [0.44, 0.535, 0.665], "belt": 0.27, "crease": 0.4, "wr": 0.19, "wf": 0.8, "wheel": 0.07, "lamp": "square", "year": 2008, "boom": true,
	},
	"suv": {
		"shape": [[0.0, 0.1], [0.0, 0.32, 1], [0.018, 0.358], [0.08, 0.375], [0.6, 0.376], [0.64, 0.362], [0.74, 0.272], [0.95, 0.252], [1.0, 0.226], [1.0, 0.1], [0.985, 0.075]],
		"glass": [[0.04, 0.272], [0.05, 0.356], [0.6, 0.363], [0.728, 0.274]],
		"pillar": [0.2, 0.44], "doors": [0.21, 0.44, 0.69], "belt": 0.262, "crease": 0.42, "wr": 0.18, "wf": 0.8, "wheel": 0.077, "lamp": "slim", "year": 2012,
	},
	"van": {
		"shape": [[0.0, 0.1], [0.0, 0.35, 1], [0.03, 0.386], [0.6, 0.391], [0.66, 0.372], [0.82, 0.262], [0.96, 0.222], [1.0, 0.196], [1.0, 0.09], [0.985, 0.066]],
		"glass": [[0.04, 0.258], [0.05, 0.37], [0.6, 0.376], [0.8, 0.26]],
		"pillar": [0.25, 0.5], "doors": [0.26, 0.52, 0.76], "belt": 0.25, "crease": 0.44, "wr": 0.17, "wf": 0.81, "wheel": 0.066, "lamp": "slim", "year": 2010,
	},
}

const RIMS := ["mesh", "fivespoke", "tenspoke", "multispoke", "turbofan", "deepdish", "dish", "steel", "hubcap", "beadlock", "wire"]

static func body_of(spec: Dictionary) -> String:
	var b := String(spec.get("body", "sedan"))
	return b if BODIES.has(b) else "sedan"

static func length_px(metres: float, depth := 1.0) -> int:
	return int(metres * PX_PER_M * depth)

## The design behind a body-only call: a generic car of that body and year.
static func _body_design(body: String, mods: Dictionary) -> Dictionary:
	if not BODIES.has(body): body = "sedan"
	return CarGen.design({ "body": body, "year": int(mods.get("year", BODIES[body].year)) })

static func draw(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg := {}, flip := false, tilt := 0.0, mods := {}) -> void:
	_stamp(p, x, y, len, _body_design(body, mods), paint, dmg, flip, tilt, mods)

## A car drawn as itself: its own silhouette, lamps, trim and wheels.
static func draw_car(p: Pix, x: int, y: int, len: int, car: Dictionary, paint: Color, dmg := {}, flip := false, tilt := 0.0, mods := {}) -> void:
	_stamp(p, x, y, len, CarGen.design(car), paint, dmg, flip, tilt, mods)

static func _stamp(p: Pix, x: int, y: int, len: int, d: Dictionary, paint: Color, dmg: Dictionary, flip: bool, tilt: float, mods: Dictionary) -> void:
	var below := int(len * 0.45)
	var m := mods
	if absf(tilt) > 0.05 and not mods.has("shadow"):
		m = mods.duplicate()
		m.shadow = false
	var img := CarGen.render(len, d, paint, m, dmg, below)
	var gy := img.get_height() - 8 - below
	if absf(tilt) > 0.001:
		var wf: float = d.wr if tilt > 0.0 else d.wf
		img = _rotate(img, tilt, Vector2(22 + len * wf, gy))
	p.stamp(img, x - 22, y - gy, flip)

## Authored showroom art wins over the painter when the car is stock and undamaged:
## art/vehicles/showroom/<art_id>.png (256x96, faces right, ground at y=78) with an optional
## paint mask at showroom/masks/<art_id>_paint.png whose grey picks the paint value
## (<25% deep, <50% shadow, <75% base, else highlight). Same framing as image(): ground 8px up.
static var showroom_dir := "res://art/vehicles/showroom/"
const SHOWROOM_BASELINE := 78
const COSMETIC_KEYS := ["year", "shadow", "lights_on", "glow"]
static var _authored := {}

static func art_id(spec: Dictionary) -> String:
	if spec.has("art_id"): return String(spec.art_id)
	var raw := "%s %s %d" % [String(spec.get("make", "")), String(spec.get("model", "")), int(spec.get("year", 0))]
	var out := ""
	for ch in raw.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"): out += ch
		elif not out.ends_with("_") and out != "": out += "_"
	return out.trim_suffix("_")

static func showroom(spec: Dictionary, len: int, paint: Color, mods := {}, dmg := {}) -> Image:
	var stock := dmg.is_empty()
	for k in mods:
		if not k in COSMETIC_KEYS: stock = false
	if stock:
		var img := authored(art_id(spec), paint)
		if img != null: return img
	return image_of(spec, len, paint, mods, dmg)

## The authored sprite in this paint, or null when there isn't one.
static func authored(id: String, paint: Color) -> Image:
	if not _authored.has(id):
		var path := showroom_dir + id + ".png"
		var mpath := showroom_dir + "masks/" + id + "_paint.png"
		var base: Image = null
		var mask: Image = null
		if ResourceLoader.exists(path): base = (load(path) as Texture2D).get_image()
		elif FileAccess.file_exists(path): base = Image.load_from_file(path)
		if base != null:
			if ResourceLoader.exists(mpath): mask = (load(mpath) as Texture2D).get_image()
			elif FileAccess.file_exists(mpath): mask = Image.load_from_file(mpath)
		_authored[id] = [base, mask]
	var pair: Array = _authored[id]
	if pair[0] == null: return null
	var src: Image = (pair[0] as Image).duplicate()
	src.convert(Image.FORMAT_RGBA8)
	var mask: Image = pair[1]
	if mask != null and mask.get_size() == src.get_size():
		var pal := _palette(paint, "gloss")
		for yy in src.get_height():
			for xx in src.get_width():
				var m := mask.get_pixel(xx, yy)
				if m.a < 0.5 or src.get_pixel(xx, yy).a < 0.5: continue
				var c: Color = pal.deep if m.r < 0.25 else (pal.sh if m.r < 0.5 else (pal.base if m.r < 0.75 else pal.hi))
				src.set_pixel(xx, yy, c)
	var h := mini(src.get_height(), SHOWROOM_BASELINE + 8)
	var out := Image.create(src.get_width(), h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, src.get_width(), h), Vector2i.ZERO)
	return out

## A generic car of a body on its own transparent image.
static func image(len: int, body: String, paint: Color, mods := {}, dmg := {}) -> Image:
	return CarGen.render(len, _body_design(body, mods), paint, mods, dmg)

## A car as itself on its own transparent image: rear bumper at x=22, tyres 8px above the bottom.
static func image_of(car: Dictionary, len: int, paint: Color, mods := {}, dmg := {}) -> Image:
	return CarGen.render(len, CarGen.design(car), paint, mods, dmg)

## Where the wheels sit on image_of()'s picture: [[x, radius], ...], rear then front.
static func wheel_spots(car: Dictionary, len: int, mods := {}) -> Array:
	return CarGen.wheel_spots(len, CarGen.design(car), mods)

## The rim and wheel() mods image_of() painted a car's wheels with: [rim, mods].
static func wheel_look(car: Dictionary, len: int, mods := {}) -> Array:
	return CarGen.wheel_look(CarGen.design(car), mods, len)

## The rim a car comes with from the factory.
static func stock_rim(car: Dictionary) -> String:
	return String(CarGen.design(car).rim_style)

static func _rotate(img: Image, ang: float, pivot: Vector2) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var ca := cos(-ang)
	var sa := sin(-ang)
	for yy in out.get_height():
		for xx in out.get_width():
			var d := Vector2(xx, yy) - pivot
			var s := pivot + Vector2(d.x * ca - d.y * sa, d.x * sa + d.y * ca)
			var sx := int(round(s.x))
			var sy := int(round(s.y))
			if sx >= 0 and sy >= 0 and sx < img.get_width() and sy < img.get_height():
				out.set_pixel(xx, yy, img.get_pixel(sx, sy))
	return out

## Four paint values for the authored sprites' masks, adjusted for the finish.
static func _palette(paint: Color, finish: String) -> Dictionary:
	var hi := paint.lightened(0.3)
	var sh := paint.darkened(0.3)
	var deep := paint.darkened(0.55)
	match finish:
		"matte":
			hi = paint.lightened(0.08)
			sh = paint.darkened(0.14)
		"metallic":
			hi = paint.lightened(0.32)
		"chrome":
			hi = Color("f4f6fa")
			sh = Color("4a5058")
	return { "hi": hi, "base": paint, "sh": sh, "deep": deep }

## One wheel (CarGen paints it): tyre, rim, brakes behind the spokes. See CarGen.wheel.
static func wheel(p: Pix, cx: int, cy: int, r: float, rim: String, flat := false, mods := {}, spin := 0.0) -> void:
	CarGen.wheel(p, cx, cy, r, rim, flat, mods, spin)

static func loose_wheel(p: Pix, cx: int, cy: int, r: float, rim: String) -> void:
	wheel(p, cx, cy, r, rim)
