## Side-view pixel cars: the cutscenes, the death screens, the garage, the loading screens, and
## the showroom sprites (art/vehicles/showroom) all come from here.
##
## The house style (see DEV ADDITIONS.md on ai/car-sprite-expansion): a near-black contour round
## every part, three paint values (highlight band under the shoulder, base, shadow low down)
## plus a dark crease, blue glass with black trim, chunky wheels with real tyres, hard edges.
##
## draw(p, x, y, len, body, paint, dmg, flip, tilt, mods): x = rear bumper, y = where the tyres
## touch the ground, facing right (flip for left).
## mods: rim (mesh, fivespoke, tenspoke, multispoke, turbofan, deepdish, dish, steel, hubcap,
##   beadlock), rim_color, rim_size, caliper, drop (-1 lifted .. 1 slammed), tire (stock, mud,
##   lowpro), spoiler (none, ducktail, wing, gt), kit ({lip, skirts, diffuser}), fenders (stock,
##   flared), livery (none, slash), stripes (none, racing, side, rally), stripe_color, tint,
##   finish (gloss, matte, metallic, pearl, chrome), year, exhaust (single, dual, quad, side),
##   rollbar, lightbar, bash, spare, bed (stock, tonneau), hood (stock, vented), smooth,
##   lights_on, shadow.
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

## Silhouettes, rear (x=0) to nose (x=1), heights in car lengths. A third value of 1 keeps a
## corner sharp; everything else is smoothed.
const BODIES := {
	"coupe": {
		"shape": [[0.0, 0.075], [0.0, 0.15], [0.012, 0.184], [0.06, 0.2], [0.2, 0.206], [0.275, 0.214], [0.37, 0.27], [0.44, 0.296], [0.5, 0.3], [0.565, 0.295], [0.61, 0.279], [0.705, 0.212], [0.85, 0.196], [0.955, 0.18], [0.993, 0.162], [1.0, 0.13], [1.0, 0.08], [0.985, 0.055]],
		"glass": [[0.296, 0.216], [0.375, 0.264], [0.44, 0.287], [0.5, 0.292], [0.56, 0.287], [0.6, 0.275], [0.688, 0.217]],
		"pillar": [0.468], "doors": [0.405, 0.668], "belt": 0.206, "crease": 0.42, "wr": 0.19, "wf": 0.8, "wheel": 0.068, "lamp": "slim", "year": 1991,
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
		"shape": [[0.0, 0.1], [0.0, 0.27, 1], [0.012, 0.276], [0.43, 0.276, 1], [0.432, 0.392, 1], [0.448, 0.405], [0.6, 0.405], [0.62, 0.392], [0.69, 0.298], [0.94, 0.284], [0.99, 0.262], [1.0, 0.24], [1.0, 0.1], [0.985, 0.08]],
		"glass": [[0.455, 0.302], [0.458, 0.39], [0.6, 0.393], [0.677, 0.302]],
		"pillar": [0.535], "doors": [0.44, 0.67], "belt": 0.284, "crease": 0.36, "wr": 0.18, "wf": 0.8, "wheel": 0.078, "lamp": "square", "year": 1988, "bed": [0.012, 0.43],
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

const RIMS := ["mesh", "fivespoke", "tenspoke", "multispoke", "turbofan", "deepdish", "dish", "steel", "hubcap", "beadlock"]

static func body_of(spec: Dictionary) -> String:
	var b := String(spec.get("body", "sedan"))
	return b if BODIES.has(b) else "sedan"

static func length_px(metres: float, depth := 1.0) -> int:
	return int(metres * PX_PER_M * depth)

static func draw(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg := {}, flip := false, tilt := 0.0, mods := {}) -> void:
	var below := int(len * 0.45)
	var src := Pix.new(len + 44, int(len * 0.75) + 30 + below, 7)
	var gy := src.h - 8 - below
	_paint(src, 22, gy, len, body, paint, dmg, mods)
	if absf(tilt) > 0.001:
		var wf: float = BODIES[body].wr if tilt > 0.0 else BODIES[body].wf
		src.img = _rotate(src.img, tilt, Vector2(22 + len * wf, gy))
	p.stamp(src.img, x - 22, y - gy, flip)

## Authored showroom art wins over the painter when the car is stock and undamaged:
## art/vehicles/showroom/<art_id>.png (256x96, faces right, ground at y=78) with an optional
## paint mask at showroom/masks/<art_id>_paint.png whose grey picks the paint value
## (<25% deep, <50% shadow, <75% base, else highlight). Same framing as image(): ground 8px up.
static var showroom_dir := "res://art/vehicles/showroom/"
const SHOWROOM_BASELINE := 78
const COSMETIC_KEYS := ["year", "shadow", "lights_on"]
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
	return image(len, body_of(spec), paint, mods, dmg)

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

## A car on its own transparent image.
static func image(len: int, body: String, paint: Color, mods := {}, dmg := {}) -> Image:
	var src := Pix.new(len + 44, int(len * 0.75) + 30, 7)
	_paint(src, 22, src.h - 8, len, body, paint, dmg, mods)
	return src.img

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

## Profile points → pixel polygon, smoothed (Catmull-Rom) except at sharp corners, with crash
## crumple, a crushed roof and the ride height applied.
static func _outline(b: Dictionary, key: String, x: int, y: int, len: int, dmg: Dictionary, lift: float) -> PackedVector2Array:
	var front := float(dmg.get("front", 0.0))
	var rear := float(dmg.get("rear", 0.0))
	var roof := float(dmg.get("roof", 0.0))
	var raw: Array = []
	var i := 0
	for q in b[key]:
		var fx: float = q[0]
		var fy: float = q[1]
		if front > 0.0 and fx > 0.7:
			var k := (fx - 0.7) / 0.3
			fx -= front * 0.2 * k
			if fy > 0.1 and fy < float(b.belt) + 0.02: fy += front * 0.05 * k * (1.0 if i % 2 == 0 else 0.4)
		if rear > 0.0 and fx < 0.3:
			var k2 := (0.3 - fx) / 0.3
			fx += rear * 0.16 * k2
			if fy > 0.1 and fy < float(b.belt) + 0.02: fy += rear * 0.04 * k2 * (1.0 if i % 2 == 0 else 0.5)
		if roof > 0.0 and fy > float(b.belt) + 0.02: fy -= roof * 0.08
		var sharp: bool = (q as Array).size() > 2 and int(q[2]) == 1
		raw.append([Vector2(x + fx * len, y - fy * len - lift), sharp])
		i += 1
	var out := PackedVector2Array()
	var n := raw.size()
	var closed := key == "glass"
	for k in n:
		var p1: Vector2 = raw[k][0]
		out.append(p1)
		if k == n - 1 and not closed: continue
		var p2: Vector2 = raw[(k + 1) % n][0]
		if raw[k][1] or raw[(k + 1) % n][1]: continue
		var p0: Vector2 = raw[(k - 1 + n) % n][0] if (closed or k > 0) else p1
		var p3: Vector2 = raw[(k + 2) % n][0] if (closed or k + 2 < n) else p2
		for s in range(1, 5):
			var t := float(s) / 5.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	if not closed:
		out.append(Vector2(x + 0.015 * len, y - 0.05 * len - lift))
	return out

## Three paint values plus a crease tone, adjusted for the finish.
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

static func _paint(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg: Dictionary, mods: Dictionary) -> void:
	var b: Dictionary = BODIES[body]
	var year := int(mods.get("year", b.get("year", 2000)))
	var finish := String(mods.get("finish", "gloss"))
	var pal := _palette(paint, finish)
	var front := float(dmg.get("front", 0.0))
	var rear := float(dmg.get("rear", 0.0))
	var u := maxi(1, int(round(len / 110.0)))            # detail unit: 1px small, 2px big
	# ride height: + lowers, - lifts; tyres get bigger on lifted trucks
	var drop := float(mods.get("drop", 0.0))
	var tire_kind := String(mods.get("tire", "mud" if drop < -0.3 else ("lowpro" if drop > 0.7 else "stock")))
	var r_stock := float(b.wheel) * len
	var r := r_stock * (1.22 if tire_kind == "mud" else 1.0)
	var lift := -drop * len * 0.036 + (r - r_stock) * 0.9      # how far the body sits above stock
	if mods.get("shadow", true):
		for k in 3:
			p.shadow(x + len / 2, y + 1, len * (0.56 - k * 0.05), maxf(2.0, len * (0.035 - k * 0.008)), 0.55)
	# --- the body mask
	var shape := _outline(b, "shape", x, y, len, dmg, lift)
	var glass := _outline(b, "glass", x, y, len, dmg, lift)
	var bm := Pix.new(p.w, p.h, 3)
	bm.poly(shape, Color(1, 1, 1))
	var gm := Pix.new(p.w, p.h, 4)
	gm.poly(glass, Color(1, 1, 1))
	var belt_y := float(y) - float(b.belt) * len - lift
	var sill_y := float(y) - 0.05 * len - lift
	var crease_y := int(belt_y + (sill_y - belt_y) * float(b.crease))
	# wheel centres (on the ground) and arches (where the body expects them)
	var wheels: Array = []
	for side in ["rear", "front"]:
		var wf: float = b.wr if side == "rear" else b.wf
		if side == "front": wf -= front * 0.12
		else: wf += rear * 0.08
		var wcx := int(x + wf * len)
		var arch_c := Vector2(wcx, float(y) - r_stock - lift)
		wheels.append([side, wcx, y - int(round(r)), arch_c])
	var flared := String(mods.get("fenders", "stock")) == "flared"
	var arch_r := maxf(r, r_stock) * 1.07 + 0.5 * float(u)
	# carve the wells out of the mask so the contour follows the arch
	for w in wheels:
		var ac: Vector2 = w[3]
		for yy in range(int(ac.y - arch_r) - 1, p.h):
			for xx in range(int(ac.x - arch_r) - 1, int(ac.x + arch_r) + 2):
				var d := Vector2(xx, yy) - ac
				if d.length() < arch_r or (absf(d.x) < arch_r and yy > ac.y):
					if bm.get_px(xx, yy).a > 0.0: bm.img.set_pixel(xx, yy, Color(0, 0, 0, 0))
	# --- paint every body pixel by where it sits
	for yy in p.h:
		for xx in range(maxi(0, x - 4), mini(p.w, x + len + 5)):
			if bm.get_px(xx, yy).a <= 0.0: continue
			if gm.get_px(xx, yy).a > 0.0: continue                 # glass is painted later
			var top_edge := bm.get_px(xx, yy - 1).a <= 0.0
			var c: Color = pal.base
			if float(yy) < belt_y - 0.5:
				c = pal.hi if top_edge else pal.base                # roof and pillars
			else:
				var t := (float(yy) - belt_y) / maxf(1.0, sill_y - belt_y)
				if top_edge or t < 0.07: c = pal.hi.lightened(0.12)  # the shoulder line, brightest
				elif t < 0.3: c = pal.hi                             # the upper side catching the sky
				elif yy == crease_y: c = pal.deep                   # the body crease
				elif yy == crease_y + 1: c = pal.hi
				elif t > 0.74: c = pal.sh
				if t > 0.93: c = pal.deep
			p.px(xx, yy, c)
	# --- liveries and stripes
	_livery(p, bm, x, len, belt_y, sill_y, mods)
	# --- glass: blue, lighter up top, a streak, black trim and pillars
	var gy0 := 9999
	var gy1 := -1
	for q in glass:
		gy0 = mini(gy0, int(q.y))
		gy1 = maxi(gy1, int(q.y))
	var tint := clampf(float(mods.get("tint", 0.0)), 0.0, 1.0)
	for yy in range(gy0, gy1 + 1):
		for xx in range(x, x + len):
			if gm.get_px(xx, yy).a <= 0.0: continue
			var f := float(yy - gy0) / maxf(1.0, float(gy1 - gy0))
			var c2 := GLASS_HI if f < 0.3 else (GLASS if f < 0.78 else GLASS_LO)
			var streak := posmod(xx - (yy - gy0) * 2 - x, maxi(20, len / 5))
			if streak < 2 * u and f < 0.85: c2 = GLASS_HI.lightened(0.18)
			p.px(xx, yy, c2.darkened(tint * 0.5))
	var trim := CHROME if year < 1980 else INK
	p.poly_outline(glass, trim)
	for pf in b.pillar:
		var px0 := int(x + float(pf) * len)
		for yy in range(gy0, gy1 + 1):
			if gm.get_px(px0, yy).a > 0.0:
				for w2 in 2 * u: p.px(px0 + w2, yy, INK)
	if len >= 120:
		var hx := int(x + (float(b.doors[b.doors.size() - 1]) - 0.2) * len)
		p.rect(hx, gy1 - int(len * 0.035), 3 * u, int(len * 0.03), Color(INK, 0.55))     # a headrest
	if dmg.get("glass", false):
		var cx := int(x + (float(b.glass[1][0]) + 0.05) * len)
		var cy := int(belt_y - 0.05 * len)
		for k in 7:
			var a := TAU * float(k) / 7.0 + 0.3
			p.line(cx, cy, cx + int(cos(a) * len * 0.08), cy + int(sin(a) * len * 0.05), Color("c8d4e0"))
	# --- doors and the rear quarter: crisp shut lines, a handle on each
	var doors: Array = b.doors
	for k in doors.size():
		var dx := int(x + float(doors[k]) * len)
		if dx < x + int(rear * 0.16 * len) + 2 or dx > x + int((1.0 - front * 0.2) * len) - 2: continue
		for yy in range(int(belt_y) + 1, int(sill_y) - u):
			if bm.get_px(dx, yy).a > 0.0 and gm.get_px(dx, yy).a <= 0.0: p.px(dx, yy, INK)
		if k > 0:
			var hw := maxi(3, int(len * 0.035))
			var hx2 := dx - maxi(4, int(len * 0.06)) - hw
			var hy := int(belt_y + (sill_y - belt_y) * 0.2)
			p.rect(hx2, hy, hw, u + 1, INK)
			p.hline(hx2, hy + u + 1, hw, pal.hi)
	if not body in ["pickup", "tow"]:
		var fx0 := int(x + 0.12 * len)
		p.frame(fx0, int(belt_y) + 2 * u + 1, maxi(4, int(len * 0.035)), maxi(4, int(len * 0.03)), pal.deep)
	# --- the mirror at the base of the A-pillar
	var mx := int(glass[glass.size() - 1].x) - 2 * u
	var mw := maxi(4, int(len * 0.04))
	var mh := maxi(3, int(len * 0.025))
	p.rect(mx - mw + 2, int(belt_y) - mh, mw, mh, pal.base)
	p.hline(mx - mw + 2, int(belt_y) - mh, mw, pal.hi)
	p.frame(mx - mw + 1, int(belt_y) - mh - 1, mw + 2, mh + 2, INK)
	p.rect(mx - 1, int(belt_y) - 1, u + 1, u + 1, INK)
	# --- bumpers, lamps, grille
	var nose := x + int((1.0 - front * 0.2) * len) - 1
	var tail := x + int(rear * 0.16 * len)
	var bump_y := int(y - 0.09 * len - lift)
	var bh := maxi(3, int(len * 0.04))
	var bumper := String(dmg.get("bumper", ""))
	var chrome: bool = year < 1976 or (body in ["pickup", "tow"] and year < 2000 and not mods.get("smooth", false))
	var rubber: bool = not chrome and year >= 1976 and year < 1992 and not body in ["coupe"]
	var bash: bool = mods.get("bash", false)
	for end in [0, 1]:
		var bw := int(len * 0.075)
		var bx0: int = tail - u if end == 0 else nose - bw - u
		if end == 1 and (bumper == "gone" or bash): continue
		if end == 1 and bumper == "hang":
			p.line(nose - 6, bump_y, nose + 4, y - int(lift) - 1, BLACK_TRIM)
			continue
		if chrome or rubber:
			var bc := CHROME if chrome else BLACK_TRIM
			p.rect(bx0, bump_y, bw + 2, bh, bc)
			p.hline(bx0, bump_y, bw + 2, bc.lightened(0.3))
			p.hline(bx0, bump_y + bh - 1, bw + 2, bc.darkened(0.35))
			p.frame(bx0 - 1, bump_y - 1, bw + 4, bh + 2, INK)
		else:
			p.hline(bx0 + (2 * u if end == 0 else -u), bump_y - u, bw, INK)        # the bumper seam
	if front < 0.5 and not bash:
		var gh := maxi(3, int(len * 0.03))
		var iy := int(y - 0.105 * len - lift)
		for xx in range(nose - int(len * 0.07), nose - int(len * 0.01)):    # the lower intake, on bodywork only
			if bm.get_px(xx, iy - 1).a > 0.0: p.px(xx, iy - 1, pal.sh)
			for yy in range(iy, iy + maxi(2, gh - u)):
				if bm.get_px(xx, yy + u).a > 0.0: p.px(xx, yy, INK)
	var lamp_y := int(belt_y + (sill_y - belt_y) * 0.1)
	var lights_on: bool = dmg.get("lights", mods.get("lights_on", false))
	if front < 0.4:
		var lc := Color("fff6d2") if lights_on else Color("e6ebee")
		var lw := maxi(4, int(len * 0.06))
		match String(b.lamp):
			"slim":
				p.rect(nose - lw - u, lamp_y, lw, 2 * u + 1, lc)
				p.hline(nose - lw - u, lamp_y + 2 * u, lw, Color("f0a020"))
				p.frame(nose - lw - u - 1, lamp_y - 1, lw + 2, 3 * u + 2, INK)
			"square":
				p.rect(nose - 4 * u, lamp_y - u, 3 * u, 5 * u, lc)
				p.frame(nose - 4 * u - 1, lamp_y - u - 1, 3 * u + 2, 5 * u + 2, INK)
			"angry":
				p.rect(nose - lw - u, lamp_y - u, lw, u + 1, lc)
				p.rect(nose - 4 * u, lamp_y, 3 * u, 2 * u, lc)
				p.frame(nose - lw - u - 1, lamp_y - u - 1, lw + 2, 3 * u + 2, INK)
			"round":
				p.disc(nose - 2 * u, lamp_y + u, 2.0 * u, lc)
				p.ring(nose - 2 * u, lamp_y + u, 2.5 * u, CHROME)
		p.rect(nose - int(len * 0.09), lamp_y + 2 * u, 3 * u, 2 * u, Color("f0a020"))    # corner marker
		p.frame(nose - int(len * 0.09) - 1, lamp_y + 2 * u - 1, 3 * u + 2, 2 * u + 2, INK)
		if lights_on: p.glow(nose + 4, lamp_y + u, 10.0 * u, Color("fff4c8"), 0.8)
	else:
		p.rect(nose - 2 * u, lamp_y, 3 * u, 3 * u, WELL)
	if rear < 0.4:
		var tw := maxi(4, int(len * 0.035))
		var th := maxi(5, int(len * 0.05))
		p.rect(tail + u, lamp_y - u, tw, th, Color("c42630"))
		p.rect(tail + u, lamp_y - u + th - 2 * u, tw, 2 * u, Color("e88a22"))
		p.px(tail + u + 1, lamp_y, Color("ff7a7a"))
		p.frame(tail + u - 1, lamp_y - u - 1, tw + 2, th + 2, INK)
	# --- exhaust
	var ex := String(mods.get("exhaust", "single"))
	var ey := int(y - 0.085 * len - lift)
	if ex == "side":
		var sx := int(wheels[1][1] - arch_r - 4 * u)
		p.rect(sx, ey - u, 4 * u, 2 * u, CHROME)
		p.frame(sx - 1, ey - u - 1, 4 * u + 2, 2 * u + 2, INK)
	else:
		var tips := 2 if ex == "dual" else (3 if ex == "quad" else 1)
		for k in tips:
			var tx := tail + 2 * u + k * 4 * u
			p.rect(tx, ey, 3 * u, 2 * u, CHROME)
			p.frame(tx - 1, ey - 1, 3 * u + 2, 2 * u + 2, INK)
	# --- spoilers and wings
	var spoiler := String(mods.get("spoiler", "none"))
	if spoiler != "none" and not body in ["pickup", "tow", "van"]:
		var dx0 := x + int(len * 0.03)
		var dtop := p.h
		for yy in p.h:
			if bm.get_px(dx0 + int(len * 0.06), yy).a > 0.0:
				dtop = yy
				break
		match spoiler:
			"ducktail":
				var pts := PackedVector2Array([Vector2(dx0, dtop + u), Vector2(dx0 + len * 0.12, dtop), Vector2(dx0 - u, dtop - 3 * u)])
				p.poly(pts, pal.base)
				p.poly_outline(pts, INK)
			"wing", "gt":
				var big := spoiler == "gt"
				var ph := (5 if big else 3) * u
				var bw2 := int(len * (0.16 if big else 0.13))
				var bc2: Color = BLACK_TRIM if big else pal.base
				for px1 in [dx0 + 3 * u, dx0 + int(len * 0.09)]:
					p.rect(px1, dtop - ph, u + 1, ph, bc2)
					p.frame(px1 - 1, dtop - ph - 1, u + 3, ph + 1, INK)
				var bt := 2 * u
				var blade := Rect2i(dx0 - 3 * u, dtop - ph - bt, bw2, bt)
				# the blade, a touch of angle: the trailing edge kicks up
				var pts2 := PackedVector2Array([Vector2(blade.position.x, blade.position.y - u), Vector2(blade.end.x, blade.position.y + u), Vector2(blade.end.x, blade.end.y), Vector2(blade.position.x, blade.end.y)])
				p.poly(pts2, bc2)
				p.line(blade.position.x, blade.position.y - u, blade.end.x, blade.position.y + u, Color("4a4e56") if big else pal.hi)
				p.poly_outline(pts2, INK)
				if big:
					p.rect(blade.position.x - u, blade.position.y - 2 * u, u + 1, bt + 3 * u, BLACK_TRIM)
					p.frame(blade.position.x - u - 1, blade.position.y - 2 * u - 1, u + 3, bt + 3 * u + 2, INK)
	if String(mods.get("hood", "stock")) == "vented":
		var hx0 := int(x + 0.78 * len)
		for k in 3:
			p.hline(hx0 + k * 4 * u, int(belt_y) + 2 * u, 2 * u, INK)
	# --- trucks: bed rail, tonneau, roll bar and lights, the spare, a bash bar
	if b.has("bed"):
		var bed: Array = b.bed
		var bx0 := int(x + float(bed[0]) * len)
		var bx1 := int(x + float(bed[1]) * len)
		var rail := int(y - 0.276 * len - lift)
		if String(mods.get("bed", "stock")) == "tonneau":
			p.rect(bx0, rail - 2 * u, bx1 - bx0, 2 * u, BLACK_TRIM)
			p.frame(bx0 - 1, rail - 2 * u - 1, bx1 - bx0 + 2, 2 * u + 2, INK)
		else:
			p.hline(bx0, rail + 2 * u, bx1 - bx0, INK)
		if mods.get("spare", false):
			var sr := r * 0.75
			wheel(p, bx0 + int(len * 0.22), rail - int(sr * 0.55), sr, "beadlock", false, { "tire_kind": "mud" })
		if mods.get("rollbar", false):
			var rb := Color("2a2e36")
			var rx0 := bx1 - int(len * 0.12)
			var top := rail - int(len * 0.12)
			for w3 in 2 * u: p.line(rx0 + w3, rail, rx0 + int(len * 0.07) + w3, top, rb)
			p.rect(rx0 + int(len * 0.07), top, int(len * 0.06), 2 * u, rb)
			p.vline(bx1 - 2 * u, top, rail - top, rb)
			p.vline(bx1 - u, top, rail - top, rb)
			if mods.get("lightbar", false):
				for k in 4:
					var lx2 := rx0 + int(len * 0.06) + k * 5 * u
					p.disc(lx2, top - 3 * u, 2.2 * u, Color("f4f4ec"))
					p.ring(lx2, top - 3 * u, 2.4 * u, INK)
	if bash:
		var bx := nose - 2 * u
		var by := bump_y - u
		var tube := Color("2a2e36")
		p.rect(bx - int(len * 0.04), by, int(len * 0.06), 2 * u, tube)
		p.rect(bx + int(len * 0.02), by - 3 * u, 2 * u, 9 * u, tube)
		p.line(bx - int(len * 0.04), by + 2 * u, bx - int(len * 0.06), int(sill_y) + 3 * u, tube)
		p.frame(bx - int(len * 0.04) - 1, by - 1, int(len * 0.06) + 2, 2 * u + 2, INK)
	# --- the wrecker
	if b.get("boom", false):
		var bxx := int(x + 0.38 * len)
		var byy := int(y - 0.25 * len)
		for w4 in u + 1:
			p.line(bxx, byy + w4, int(x + 0.05 * len), int(y - 0.42 * len) + w4, Color("e8b020") if w4 == 0 else INK)
		p.line(int(x + 0.05 * len), int(y - 0.42 * len), int(x + 0.04 * len), int(y - 0.2 * len), Color("6a6a6e"))
		p.rect(int(x + 0.03 * len), int(y - 0.2 * len), 3 * u, 3 * u, Color("3a3a3e"))
		p.rect(int(x + 0.47 * len), int(y - 0.41 * len), int(len * 0.11), 2 * u, Color("e8a020"))
		p.rect(int(x + 0.47 * len), int(y - 0.41 * len), 3 * u, 2 * u, Color("e03020"))
		p.text(int(x + 0.12 * len), int(y - 0.18 * len), "TOW", Color("e8b020"))
	# --- smoke and the driver (death screens)
	var smoke := float(dmg.get("smoke", 0.0))
	if smoke > 0.0:
		var sx2 := int(x + (0.85 - front * 0.18) * len)
		for k in int(6 + smoke * 10.0):
			p.glow(sx2 - k * 2 + int(sin(float(k)) * 3.0), int(belt_y) - 3 - k * 3, (2.0 + float(k) * 0.6) * u, Color(0.82, 0.82, 0.84), 1.0 - float(k) * 0.04)
	var drv: Dictionary = dmg.get("driver", {})
	if not drv.is_empty():
		var wx := int(x + (float(doors[doors.size() - 1]) - 0.06) * len)
		var wy := int(belt_y)
		var sk: Color = drv.get("skin", Color("dcae88"))
		var hc: Color = drv.get("hair", Color("3b2a1e"))
		p.rect(wx - 5 * u, wy - 6 * u, 6 * u, 6 * u, hc)
		if drv.get("long_hair", false): p.rect(wx - 3 * u, wy, 3 * u, int(len * 0.1), hc)
		if drv.get("sleeve", null) != null: p.rect(wx - u, wy - u, 3 * u, 3 * u, drv.sleeve)
		p.rect(wx - u, wy + 2 * u, 3 * u, int(len * 0.1), sk)
		p.rect(wx - u, wy + 2 * u + int(len * 0.1), 3 * u, 3 * u, sk.darkened(0.08))
	# --- the contour round the whole body
	_ink(p, bm, u)
	# --- kits hang under the contour: lip, skirts, diffuser
	var kit: Dictionary = mods.get("kit", {})
	var ra: Vector2 = wheels[0][3]
	var fa: Vector2 = wheels[1][3]
	if kit.get("lip", false) and front < 0.5:
		_under(p, bm, int(fa.x + arch_r) + u, nose - 2 * u, 2 * u, BLACK_TRIM, Color("3a3e46"))
	if kit.get("skirts", false):
		_under(p, bm, int(ra.x + arch_r) + u, int(fa.x - arch_r) - u, 2 * u, pal.sh, pal.base)
	if kit.get("diffuser", false):
		var d0 := tail + 3 * u
		var d1 := int(ra.x - arch_r) - u
		_under(p, bm, d0, d1, u + 1, BLACK_TRIM, BLACK_TRIM)
		for k in 4:
			var fx2 := d0 + int(float(d1 - d0) * (0.15 + 0.23 * float(k)))
			var fy2 := _bottom(bm, fx2) + 2
			p.vline(fx2, fy2, 3 * u, INK)
	# --- the wheel wells: dark inside the arch, behind the tyre
	for w in wheels:
		var ac2: Vector2 = w[3]
		for yy in range(int(ac2.y - arch_r), int(sill_y) + 2):
			for xx in range(int(ac2.x - arch_r) + 1, int(ac2.x + arch_r)):
				if Vector2(xx, yy).distance_to(ac2) < arch_r - 0.5 and p.get_px(xx, yy).a < 0.5:
					p.px(xx, yy, WELL)
	# --- fender flares, after the contour so they sit proud of it
	if flared:
		for w in wheels:
			var ac3: Vector2 = w[3]
			var fr := arch_r + 3.0 * u
			for k in 60:
				var a := PI + PI * float(k) / 59.0
				for t2 in 3 * u + 1:
					var rr := fr - float(t2)
					var qx := int(ac3.x + cos(a) * rr)
					var qy := int(ac3.y + sin(a) * rr)
					if qy <= int(sill_y) + u: p.px(qx, qy, INK if t2 == 0 or t2 == 3 * u else pal.base)
			for k in 5:
				var a2 := PI + PI * (0.15 + 0.7 * float(k) / 4.0)
				p.px(int(ac3.x + cos(a2) * (fr - 1.5 * u)), int(ac3.y + sin(a2) * (fr - 1.5 * u)), CHROME)
	# --- wheels last
	for w in wheels:
		if String(dmg.get("wheel_off", "")) == String(w[0]):
			var wcx: int = w[1]
			var wcy: int = w[2]
			p.disc(wcx, wcy + 2, r * 0.6, Color("6a5a50"))
			p.ring(wcx, wcy + 2, r * 0.6, INK)
			p.disc(wcx, wcy + 2, r * 0.25, Color("8a8a8e"))
			p.rect(wcx - int(r * 0.7), wcy - int(r * 0.2), 2 * u, int(r), Color("b8603a"))
			continue
		var m2 := mods.duplicate()
		m2.tire_kind = tire_kind
		wheel(p, int(w[1]), int(w[2]), r, String(mods.get("rim", _default_rim(body, year))), dmg.get("flat", "") == String(w[0]), m2)

static func _livery(p: Pix, bm: Pix, x: int, len: int, belt_y: float, sill_y: float, mods: Dictionary) -> void:
	var stripes := String(mods.get("stripes", "none"))
	var livery := String(mods.get("livery", "none"))
	var sc: Color = mods.get("stripe_color", Color("f0f0ec"))
	if stripes == "none" and livery == "none": return
	for yy in range(int(belt_y) + 1, int(sill_y)):
		var s2 := (float(yy) - belt_y) / maxf(1.0, sill_y - belt_y)
		for xx in range(x, x + len):
			if bm.get_px(xx, yy).a <= 0.0: continue
			var on := false
			var c := sc
			match stripes:
				"racing": on = (s2 > 0.18 and s2 < 0.3) or (s2 > 0.34 and s2 < 0.4)
				"side": on = s2 > 0.6 and s2 < 0.7
				"rally": on = s2 > 0.22 and s2 < 0.55 and xx > x + len * 0.42 and xx < x + len * 0.6
			if livery == "slash":
				# diagonal slashes from the rear wheel to the door, white and grey
				var d := float(xx - x) / len + s2 * 0.18
				if d > 0.18 and d < 0.26: on = true
				elif d > 0.28 and d < 0.31:
					on = true
					c = Color("8a8e96")
				elif d > 0.4 and d < 0.5 and s2 > 0.3:
					on = true
					c = Color("b8bcc4") if s2 < 0.6 else sc
			if on: p.px(xx, yy, c)

static func _default_rim(body: String, year: int) -> String:
	match body:
		"pickup", "tow": return "steel"
		"van": return "hubcap"
		"muscle": return "dish"
		"hatch": return "mesh" if year < 1995 else "multispoke"
		"sedan": return "tenspoke"
		"coupe": return "mesh" if year < 1996 else "fivespoke"
	return "fivespoke"

## The lowest body pixel in a column (or -1).
static func _bottom(bm: Pix, xx: int) -> int:
	for yy in range(bm.h - 1, -1, -1):
		if bm.get_px(xx, yy).a > 0.0: return yy
	return -1

## A strip hung under the body's bottom edge between x0 and x1, ink round it.
static func _under(p: Pix, bm: Pix, x0: int, x1: int, depth: int, c: Color, top: Color) -> void:
	if x1 <= x0: return
	for xx in range(x0, x1):
		var by := _bottom(bm, xx)
		if by < 0: continue
		p.px(xx, by + 1, INK)
		for k in depth:
			p.px(xx, by + 2 + k, top if k == 0 else c)
		p.px(xx, by + 2 + depth, INK)
	for e in [x0 - 1, x1]:
		var by2 := _bottom(bm, e if e >= x0 else x0)
		if by2 >= 0: p.vline(e, by2 + 1, depth + 2, INK)

## A solid contour just outside the body.
static func _ink(p: Pix, bm: Pix, u := 1) -> void:
	for yy in range(1, p.h - 1):
		for xx in range(1, p.w - 1):
			if bm.get_px(xx, yy).a > 0.0: continue
			if bm.get_px(xx + 1, yy).a > 0.0 or bm.get_px(xx - 1, yy).a > 0.0 or bm.get_px(xx, yy - 1).a > 0.0 or bm.get_px(xx, yy + 1).a > 0.0:
				p.px(xx, yy, INK)
				if u > 1 and bm.get_px(xx, yy + 1).a > 0.0: p.px(xx, yy - 1, INK)

## One wheel, in the house style: an ink ring, rubber, a sidewall, the rim with its own ring.
## mods.tire_kind: stock, mud (knobs round the edge), lowpro (thin sidewall).
static func wheel(p: Pix, cx: int, cy: int, r: float, rim: String, flat := false, mods := {}, spin := 0.0) -> void:
	var ry := r * (0.82 if flat else 1.0)
	var oy := int(r - ry)
	var kind := String(mods.get("tire_kind", "stock"))
	p.ellipse(cx, cy + oy, r + 1.0, ry + 1.0, INK)
	p.ellipse(cx, cy + oy, r, ry, TIRE)
	if kind == "mud":
		for k in 18:
			var a := TAU * float(k) / 18.0 + spin * 0.5
			var kx := cx + int(round(cos(a) * (r - 0.5)))
			var ky := cy + oy + int(round(sin(a) * (ry - 0.5)))
			p.rect(kx - 1, ky - 1, 2, 2, INK)
		p.ring(cx, cy + oy, r * 0.86, SIDEWALL)
	else:
		p.ring(cx, cy + oy, r * 0.88, SIDEWALL)
	for k in 6:
		var a2 := PI + 0.5 + float(k) * 0.1
		p.px(cx + int(cos(a2) * r * 0.94), cy + oy + int(sin(a2) * ry * 0.94), Color("3c414b"))
	var size := clampf(float(mods.get("rim_size", 0.7 if kind != "lowpro" else 0.8)), 0.45, 0.84)
	if kind == "mud": size = minf(size, 0.56)
	var rr := r * size
	var rc: Color = mods.get("rim_color", Color("c9ced6") if rim != "beadlock" else Color("2a2e36"))
	if rim == "deepdish" and not mods.has("rim_color"): rc = Color("eceef2")
	var hi := rc.lightened(0.3)
	var lo := rc.darkened(0.38)
	p.disc(cx, cy, rr, Color("3a3e46"))                                  # brake disc
	var cal: Color = mods.get("caliper", Color("5a5e66"))
	p.rect(cx - int(rr * 0.25), cy - int(rr * 0.95), maxi(2, int(rr * 0.5)), maxi(2, int(rr * 0.4)), cal)
	match rim:
		"mesh":
			p.disc(cx, cy, rr, rc.darkened(0.12))
			for yy in range(-int(rr), int(rr) + 1):
				for xx in range(-int(rr), int(rr) + 1):
					if xx * xx + yy * yy >= (rr - 1.0) * (rr - 1.0): continue
					var ux := xx + int(spin * 3.0)
					if posmod(ux + yy, 4) == 0 or posmod(ux - yy, 4) == 0: p.px(cx + xx, cy + yy, hi if xx + yy < 0 else rc)
					elif posmod(ux + yy, 4) == 2 and posmod(ux - yy, 4) == 2: p.px(cx + xx, cy + yy, lo)
			p.ring(cx, cy, rr - 0.5, hi)
		"fivespoke", "tenspoke", "multispoke", "turbofan", "beadlock":
			var n: int = { "fivespoke": 5, "tenspoke": 10, "multispoke": 14, "turbofan": 12, "beadlock": 6 }[rim]
			if rim == "beadlock": p.disc(cx, cy, rr, rc.darkened(0.2))
			var wdt := maxi(2, int(rr / 3.2)) if rim in ["fivespoke", "beadlock"] else maxi(1, int(rr / 7.0))
			for k in n:
				var a := TAU * float(k) / float(n) - PI / 2.0 + spin
				var lit := cos(a + 0.8)
				var c := hi if lit > 0.3 else (lo if lit < -0.3 else rc)
				for t in range(int(rr * 0.28), int(rr) + 1):
					for w2 in range(-wdt / 2, wdt - wdt / 2):
						p.px(cx + int(round(cos(a) * t - sin(a) * w2)), cy + int(round(sin(a) * t + cos(a) * w2)), c)
			p.ring(cx, cy, rr, rc)
			p.ring(cx, cy, rr - 1.0, lo)
			if rim == "beadlock":
				for k in 16:
					var a3 := TAU * float(k) / 16.0
					p.px(cx + int(cos(a3) * (rr - 0.5)), cy + int(sin(a3) * (rr - 0.5)), CHROME)
		"deepdish":
			p.disc(cx, cy, rr, Color("aeb4bc"))
			p.ring(cx, cy, rr - 0.5, Color("f6f8fa"))
			p.disc(cx, cy, rr * 0.62, rc)
			for k in 8:
				var a4 := TAU * float(k) / 8.0 + spin
				p.line(cx, cy, cx + int(cos(a4) * rr * 0.6), cy + int(sin(a4) * rr * 0.6), rc.darkened(0.25))
			p.ring(cx, cy, rr * 0.62, rc.darkened(0.3))
		"dish":
			p.disc(cx, cy, rr, rc)
			p.disc(cx - 1, cy - 1, rr * 0.75, hi)
			p.disc(cx, cy, rr * 0.6, rc.darkened(0.1))
			for k in 5:
				var a5 := TAU * float(k) / 5.0 + spin
				p.disc(cx + int(cos(a5) * rr * 0.4), cy + int(sin(a5) * rr * 0.4), maxf(1.0, rr * 0.08), INK)
		"steel":
			p.disc(cx, cy, rr, Color("d4d6da"))
			p.disc(cx + 1, cy + 1, rr * 0.72, Color("b4b8bc"))
			p.ring(cx, cy, rr * 0.6, Color("868a90"))
			for k in 6:
				var a6 := TAU * float(k) / 6.0 + spin
				p.disc(cx + int(cos(a6) * rr * 0.78), cy + int(sin(a6) * rr * 0.78), maxf(0.8, rr * 0.08), Color("6a6e74"))
		_:
			p.disc(cx, cy, rr, Color("c8ccd4"))
			p.disc(cx - 1, cy - 1, rr * 0.7, Color("e8ecf0"))
			p.ring(cx, cy, rr * 0.75, Color("8a8e96"))
	p.ring(cx, cy, rr + 0.5, INK)
	p.disc(cx, cy, maxf(1.2, rr * 0.2), lo)
	p.px(cx - 1, cy - 1, hi)

static func loose_wheel(p: Pix, cx: int, cy: int, r: float, rim: String) -> void:
	wheel(p, cx, cy, r, rim)
