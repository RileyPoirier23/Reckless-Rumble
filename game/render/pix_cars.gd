## Side-view pixel cars: the cutscenes, the death screens and the garage all use these.
## Painted like a brochure shot: smooth silhouettes, paint that reflects sky above the shoulder
## line and ground below the horizon line, real glass with trim, bumpers by era (chrome, black
## rubber, body colour), proper lamps, wheels with spokes, brake discs and calipers, an ink outline.
##
## Scale: people in the cutscenes are 64 px for 1.75 m, so a car is about 36 px a metre
## (a 4.5 m car is ~165 px long). Use PixCars.length_px(metres) for anything near the people.
##
## draw(p, x, y, len, body, paint, dmg, flip, tilt, mods): x = rear bumper, y = where the tyres
## touch the ground, facing right (flip for left).
## mods (customisation): rim (fivespoke, tenspoke, multispoke, mesh, turbofan, dish, steel, hubcap),
##   rim_color, rim_size (0.45..0.8), caliper (Color), drop (0..1 ride height lowered), spoiler
##   (none, ducktail, wing, gt), kit ({lip, skirts, diffuser}), tint (0..1), stripes
##   (none, racing, side, rally), stripe_color, finish (gloss, matte, metallic, pearl, chrome),
##   year (era cues), exhaust (single, dual, quad), lights_on.
## dmg: front, rear (0..1 crush), roof, glass, wheel_off ("front"/"rear"), flat, smoke, bumper
##   ("hang"/"gone"), lights, driver ({skin, hair, long_hair, sleeve}).
class_name PixCars
extends RefCounted

const PX_PER_M := 36.6

## Silhouettes, rear (x=0) to nose (x=1), heights in car lengths. A third value of 1 keeps a
## corner sharp (truck beds, hatch edges); everything else is smoothed.
const BODIES := {
	"coupe": {
		"shape": [[0.0, 0.07], [0.0, 0.15], [0.012, 0.185], [0.06, 0.2], [0.2, 0.205], [0.27, 0.212], [0.36, 0.262], [0.43, 0.286], [0.5, 0.291], [0.56, 0.287], [0.6, 0.274], [0.7, 0.212], [0.85, 0.196], [0.95, 0.18], [0.99, 0.163], [1.0, 0.13], [1.0, 0.075], [0.985, 0.052]],
		"glass": [[0.292, 0.214], [0.37, 0.258], [0.43, 0.279], [0.5, 0.284], [0.555, 0.28], [0.594, 0.27], [0.684, 0.216]],
		"pillar": [0.47], "doors": [0.405, 0.665], "belt": 0.205, "wr": 0.19, "wf": 0.8, "wheel": 0.068, "lamp": "slim", "year": 1991,
	},
	"hatch": {
		"shape": [[0.0, 0.08], [0.0, 0.2, 1], [0.012, 0.232], [0.06, 0.262], [0.14, 0.304], [0.25, 0.314], [0.55, 0.318], [0.6, 0.31], [0.7, 0.226], [0.88, 0.206], [0.98, 0.19], [1.0, 0.17], [1.0, 0.08], [0.985, 0.056]],
		"glass": [[0.062, 0.238], [0.142, 0.297], [0.25, 0.307], [0.55, 0.31], [0.592, 0.302], [0.684, 0.229]],
		"pillar": [0.2, 0.45], "doors": [0.24, 0.452, 0.665], "belt": 0.215, "wr": 0.19, "wf": 0.81, "wheel": 0.066, "lamp": "square", "year": 1986,
	},
	"sedan": {
		"shape": [[0.0, 0.09], [0.0, 0.2], [0.018, 0.226], [0.16, 0.236], [0.25, 0.243], [0.34, 0.3], [0.42, 0.321], [0.55, 0.322], [0.6, 0.31], [0.71, 0.244], [0.88, 0.229], [0.97, 0.212], [1.0, 0.186], [1.0, 0.085], [0.985, 0.058]],
		"glass": [[0.272, 0.246], [0.35, 0.298], [0.42, 0.313], [0.55, 0.314], [0.594, 0.303], [0.694, 0.247]],
		"pillar": [0.36, 0.47], "doors": [0.36, 0.47, 0.675], "belt": 0.232, "wr": 0.19, "wf": 0.81, "wheel": 0.074, "lamp": "angry", "year": 2015,
	},
	"wagon": {
		"shape": [[0.0, 0.09], [0.0, 0.22, 1], [0.01, 0.29], [0.04, 0.316], [0.55, 0.319], [0.6, 0.308], [0.7, 0.237], [0.88, 0.222], [0.97, 0.206], [1.0, 0.18], [1.0, 0.085], [0.985, 0.058]],
		"glass": [[0.03, 0.242], [0.042, 0.305], [0.55, 0.311], [0.59, 0.3], [0.685, 0.241]],
		"pillar": [0.2, 0.36, 0.47], "doors": [0.24, 0.47, 0.675], "belt": 0.228, "wr": 0.19, "wf": 0.81, "wheel": 0.068, "lamp": "square", "year": 1995,
	},
	"muscle": {
		"shape": [[0.0, 0.08], [0.0, 0.17], [0.02, 0.19], [0.2, 0.2], [0.3, 0.248], [0.42, 0.284], [0.53, 0.285], [0.58, 0.27], [0.66, 0.206], [0.9, 0.195], [0.98, 0.182], [1.0, 0.162], [1.0, 0.08], [0.985, 0.058]],
		"glass": [[0.322, 0.248], [0.42, 0.277], [0.53, 0.278], [0.574, 0.265], [0.645, 0.209]],
		"pillar": [], "doors": [0.36, 0.64], "belt": 0.197, "wr": 0.18, "wf": 0.79, "wheel": 0.07, "lamp": "round", "year": 1969,
	},
	"pickup": {
		"shape": [[0.0, 0.1], [0.0, 0.27, 1], [0.012, 0.276], [0.42, 0.276, 1], [0.424, 0.39, 1], [0.44, 0.405], [0.6, 0.405], [0.62, 0.39], [0.69, 0.296], [0.95, 0.281], [1.0, 0.256], [1.0, 0.1], [0.985, 0.08]],
		"glass": [[0.446, 0.301], [0.449, 0.389], [0.6, 0.392], [0.675, 0.301]],
		"pillar": [0.53], "doors": [0.44, 0.535, 0.665], "belt": 0.28, "wr": 0.17, "wf": 0.8, "wheel": 0.076, "lamp": "square", "year": 2008, "bed": [0.0, 0.42],
	},
	"tow": {
		"shape": [[0.0, 0.1], [0.0, 0.25, 1], [0.012, 0.256], [0.42, 0.256, 1], [0.424, 0.38, 1], [0.44, 0.393], [0.6, 0.393], [0.62, 0.38], [0.69, 0.286], [0.95, 0.27], [1.0, 0.246], [1.0, 0.1], [0.985, 0.08]],
		"glass": [[0.446, 0.29], [0.449, 0.377], [0.6, 0.38], [0.674, 0.29]],
		"pillar": [0.53], "doors": [0.44, 0.535, 0.665], "belt": 0.27, "wr": 0.19, "wf": 0.8, "wheel": 0.07, "lamp": "square", "year": 2008, "boom": true,
	},
	"suv": {
		"shape": [[0.0, 0.1], [0.0, 0.32, 1], [0.018, 0.358], [0.08, 0.375], [0.6, 0.376], [0.64, 0.362], [0.74, 0.272], [0.95, 0.252], [1.0, 0.226], [1.0, 0.1], [0.985, 0.075]],
		"glass": [[0.04, 0.272], [0.05, 0.356], [0.6, 0.363], [0.728, 0.274]],
		"pillar": [0.2, 0.44], "doors": [0.21, 0.44, 0.69], "belt": 0.262, "wr": 0.18, "wf": 0.8, "wheel": 0.077, "lamp": "slim", "year": 2012,
	},
	"van": {
		"shape": [[0.0, 0.1], [0.0, 0.35, 1], [0.03, 0.386], [0.6, 0.391], [0.66, 0.372], [0.82, 0.262], [0.96, 0.222], [1.0, 0.196], [1.0, 0.09], [0.985, 0.066]],
		"glass": [[0.04, 0.258], [0.05, 0.37], [0.6, 0.376], [0.8, 0.26]],
		"pillar": [0.25, 0.5], "doors": [0.26, 0.52, 0.76], "belt": 0.25, "wr": 0.17, "wf": 0.81, "wheel": 0.066, "lamp": "slim", "year": 2010,
	},
}

const RIMS := ["fivespoke", "tenspoke", "multispoke", "mesh", "turbofan", "dish", "steel", "hubcap"]
const INK := Color("120e14")

static func body_of(spec: Dictionary) -> String:
	var b := String(spec.get("body", "sedan"))
	return b if BODIES.has(b) else "sedan"

## A car's length in cutscene pixels, at the same scale as the people.
static func length_px(metres: float, depth := 1.0) -> int:
	return int(metres * PX_PER_M * depth)

static func draw(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg := {}, flip := false, tilt := 0.0, mods := {}) -> void:
	var below := int(len * 0.45)
	var src := Pix.new(len + 40, int(len * 0.62) + 30 + below, 7)
	var gy := src.h - 8 - below
	_paint(src, 20, gy, len, body, paint, dmg, mods)
	if absf(tilt) > 0.001:
		var wf: float = BODIES[body].wr if tilt > 0.0 else BODIES[body].wf
		src.img = _rotate(src.img, tilt, Vector2(20 + len * wf, gy))
	p.stamp(src.img, x - 20, y - gy, flip)

## A car on its own transparent image (the garage, the parts site, anything else).
static func image(len: int, body: String, paint: Color, mods := {}, dmg := {}) -> Image:
	var src := Pix.new(len + 40, int(len * 0.62) + 30, 7)
	_paint(src, 20, src.h - 8, len, body, paint, dmg, mods)
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
## crumple, a crushed roof and lowered suspension applied.
static func _outline(b: Dictionary, key: String, x: int, y: int, len: int, dmg: Dictionary, drop: float) -> PackedVector2Array:
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
		raw.append([Vector2(x + fx * len, y - fy * len + drop), sharp])
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
		# open outlines don't wrap around: the ends use themselves as neighbours (no overshoot)
		var p0: Vector2 = raw[(k - 1 + n) % n][0] if (closed or k > 0) else p1
		var p3: Vector2 = raw[(k + 2) % n][0] if (closed or k + 2 < n) else p2
		for s in range(1, 5):
			var t := float(s) / 5.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	if not closed:
		out.append(Vector2(x + 0.015 * len, y - 0.05 * len + drop))     # close along the sills
	return out

static func _same(a: Color, b: Color) -> bool:
	return a.to_rgba32() == b.to_rgba32()

static func _paint(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg: Dictionary, mods: Dictionary) -> void:
	var b: Dictionary = BODIES[body]
	var year := int(mods.get("year", b.get("year", 2000)))
	var finish := String(mods.get("finish", "gloss"))
	var drop := float(mods.get("drop", 0.0)) * len * 0.025
	var front := float(dmg.get("front", 0.0))
	var rear := float(dmg.get("rear", 0.0))
	var r := float(b.wheel) * len
	var ink_w := 1 if len < 140 else 2
	# a soft shadow on the ground first
	p.shadow(x + len / 2, y, len * 0.52, maxf(2.0, len * 0.03), 0.6)
	for xx in range(x - 2, x + len + 2):
		for yy in range(y - 1, y + 2):
			p.px(xx, yy, Color(0, 0, 0, 0.18))
	# --- the body: fill, then shade every pixel from where it sits on the side of the car
	var shape := _outline(b, "shape", x, y, len, dmg, drop)
	var glass := _outline(b, "glass", x, y, len, dmg, drop)
	var body_img := Pix.new(p.w, p.h, 3)
	body_img.poly(shape, paint)
	var belt_y := float(y) - float(b.belt) * len + drop
	var sill_y := float(y) - 0.05 * len + drop
	var hl := paint.lightened(0.42 if finish != "matte" else 0.16)
	for xx in range(maxi(0, x - 2), mini(p.w, x + len + 3)):
		var top := -1
		for yy in p.h:
			if body_img.get_px(xx, yy).a > 0.0:
				top = yy
				break
		if top < 0: continue
		for yy in range(top, p.h):
			if body_img.get_px(xx, yy).a <= 0.0: continue
			var c := paint
			if float(yy) < belt_y - 1.0:
				c = paint.lightened(0.1 if finish != "matte" else 0.04)          # pillars, roof: sky
				if yy - top < ink_w: c = hl
			else:
				var s := (float(yy) - belt_y) / maxf(1.0, sill_y - belt_y)
				if yy - top < ink_w: c = hl                                      # hood / deck edge
				elif s < 0.09: c = paint.lightened(0.3 if finish != "matte" else 0.1)  # the shoulder line
				elif s < 0.4: c = paint.lightened(0.07)
				elif s < 0.47: c = paint.darkened(0.3 if finish != "matte" else 0.12)  # horizon reflection
				elif s < 0.53 and Pix.dith(xx, yy, 0.5): c = paint.darkened(0.2)
				elif s < 0.82: c = paint.darkened(0.06)
				else: c = paint.darkened(0.26) if not Pix.dith(xx, yy, (s - 0.82) * 2.0) else paint.darkened(0.36)
			match finish:
				"metallic":
					if TreeArt._n(xx, yy, 71) < 0.06: c = c.lightened(0.25)
				"pearl":
					c = c.lerp(Color(0.85, 0.8, 1.0), 0.08 * sin(float(xx) * 0.08))
				"chrome":
					var cs := (float(yy) - float(top)) / maxf(1.0, float(y) - float(top))
					c = Color(0.95, 0.96, 1.0) if cs < 0.3 else (Color(0.25, 0.27, 0.3) if cs < 0.45 else Color(0.7, 0.72, 0.76))
			p.px(xx, yy, c)
	# --- stripes and liveries, before the glass
	var stripes := String(mods.get("stripes", "none"))
	if stripes != "none":
		var sc: Color = mods.get("stripe_color", Color("f0ece4"))
		for xx in range(x, x + len):
			for yy in range(int(belt_y), int(sill_y)):
				if body_img.get_px(xx, yy).a <= 0.0: continue
				var s2 := (float(yy) - belt_y) / maxf(1.0, sill_y - belt_y)
				var on := false
				match stripes:
					"racing": on = (s2 > 0.16 and s2 < 0.28) or (s2 > 0.32 and s2 < 0.38)
					"side": on = s2 > 0.6 and s2 < 0.7
					"rally": on = s2 > 0.22 and s2 < 0.55 and xx > x + len * 0.42 and xx < x + len * 0.6
				if on: p.px(xx, yy, sc.darkened(0.15 * s2))
		if stripes == "rally":
			var nx := x + int(len * 0.51)
			var ny := int(belt_y + (sill_y - belt_y) * 0.3)
			if len >= 120: p.text(nx - 3, ny, "07", Color("1a1614"))
	# --- glass, window trim, the B-pillar
	var tint := clampf(float(mods.get("tint", 0.0)), 0.0, 1.0)
	var gbase := Color("26303c").darkened(tint * 0.6)
	var gtop := Color("5a6a7e").darkened(tint * 0.55)
	var gl := Pix.new(p.w, p.h, 4)
	gl.poly(glass, Color(1, 1, 1))
	var gy0 := int(glass[0].y)
	var gy1 := gy0
	for q in glass:
		gy0 = mini(gy0, int(q.y))
		gy1 = maxi(gy1, int(q.y))
	for yy in range(gy0, gy1 + 1):
		for xx in range(x, x + len):
			if gl.get_px(xx, yy).a <= 0.0: continue
			var f := float(yy - gy0) / maxf(1.0, float(gy1 - gy0))
			var c := gtop.lerp(gbase, f)
			var streak := posmod(xx - yy * 2, maxi(17, len / 6))
			if streak < maxi(1, len / 60): c = c.lightened(0.35)
			elif streak < maxi(2, len / 40) + 2 and streak >= maxi(1, len / 60) + 2: c = c.lightened(0.15)
			p.px(xx, yy, c)
	# interior: headrests and a steering wheel behind the glass
	var seat_x := int(x + (float(b.doors[b.doors.size() - 1]) - 0.17) * len)
	if len >= 100:
		p.rect(seat_x, gy1 - int(len * 0.04), maxi(3, int(len * 0.025)), int(len * 0.03), Color(0.06, 0.06, 0.07, 0.7))
		p.ring(seat_x + int(len * 0.12), gy1 - int(len * 0.02), len * 0.018, Color(0.06, 0.06, 0.07, 0.7))
	var trim := Color("c8ccd4") if year < 1996 else Color("16161a")
	p.poly_outline(glass, trim)
	for pf in b.pillar:
		var px0 := int(x + float(pf) * len)
		for yy in range(gy0, gy1 + 1):
			if gl.get_px(px0, yy).a > 0.0:
				for w2 in maxi(2, int(len * 0.015)):
					p.px(px0 + w2, yy, Color("16161a") if year >= 1990 else paint.darkened(0.1))
	if dmg.get("glass", false):
		var cx := int(x + (float(b.glass[1][0]) + 0.05) * len)
		var cy := int(belt_y - 0.05 * len)
		for k in 7:
			var a := TAU * float(k) / 7.0 + 0.3
			p.line(cx, cy, cx + int(cos(a) * len * 0.08), cy + int(sin(a) * len * 0.05), Color("c8d4e0"))
		p.ring(cx, cy, len * 0.03, Color("a8b4c0"))
	# --- doors, handles, mirror, fuel door, side marker
	var doors: Array = b.doors
	for k in doors.size():
		var dx := int(x + float(doors[k]) * len)
		if dx < x + int(rear * 0.16 * len) + 2 or dx > x + int((1.0 - front * 0.2) * len) - 2: continue
		for yy in range(int(belt_y) + 1, int(sill_y) - 1):
			if body_img.get_px(dx, yy).a > 0.0:
				p.px(dx, yy, paint.darkened(0.42))
				p.px(dx + 1, yy, paint.lightened(0.1))
		if k > 0:
			var hw := maxi(2, int(len * 0.03))
			var hx := dx - maxi(4, int(len * 0.05)) - hw
			var hy := int(belt_y + (sill_y - belt_y) * 0.18)
			p.hline(hx, hy, hw, paint.darkened(0.45))
			p.hline(hx, hy + 1, hw, paint.lightened(0.25))
	var mx := int(glass[glass.size() - 1].x) - 1
	var mw := maxi(3, int(len * 0.035))
	var mh := maxi(3, int(len * 0.022))
	p.rect(mx - mw + 2, int(belt_y) - mh, mw, mh, paint.darkened(0.08))
	p.hline(mx - mw + 2, int(belt_y) - mh, mw, paint.lightened(0.3))
	p.px(mx + 2, int(belt_y) - 1, Color("16161a"))
	if body != "tow" and body != "pickup":
		var fx := int(x + 0.14 * len)
		p.frame(fx, int(belt_y) + 3, maxi(3, int(len * 0.035)), maxi(3, int(len * 0.03)), paint.darkened(0.35))
	# --- bumpers by era, grille, lamps
	var nose := x + int((1.0 - front * 0.2) * len) - 1
	var tail := x + int(rear * 0.16 * len)
	var bump_y := int(y - 0.085 * len + drop)
	var bh := maxi(2, int(len * 0.028))
	var bumper := String(dmg.get("bumper", ""))
	var chrome := year < 1976
	var rubber := year >= 1976 and year < 1992
	for end in [0, 1]:
		var bw := int(len * 0.07)
		var bx0: int = tail - 1 if end == 0 else nose - bw
		if end == 1 and bumper == "gone": continue
		if end == 1 and bumper == "hang":
			p.line(nose - 6, bump_y, nose + 4, y + int(drop) - 1, Color("1e1e22") if rubber else paint.darkened(0.15))
			continue
		if chrome:
			p.rect(bx0, bump_y, bw + 1, bh, Color("d8dce4"))
			p.hline(bx0, bump_y, bw + 1, Color("ffffff"))
			p.hline(bx0, bump_y + bh - 1, bw + 1, Color("6a6e78"))
		elif rubber:
			p.rect(bx0, bump_y, bw + 1, bh, Color("1e1e22"))
			p.hline(bx0, bump_y, bw + 1, Color("3a3a40"))
		else:
			p.hline(bx0, bump_y - 1, bw, paint.darkened(0.4))         # the bumper seam
	if front < 0.5:
		var gh := maxi(2, int(len * 0.03))
		p.rect(nose - 1, bump_y - gh - 1, 2, gh, Color("16161a"))
	var kit: Dictionary = mods.get("kit", {})
	if kit.get("lip", false) and front < 0.5:
		p.rect(nose - int(len * 0.12), int(y - 0.045 * len + drop), int(len * 0.12) + 2, maxi(1, int(len * 0.012)), Color("1a1a1e"))
	var lamp_y := int(belt_y + (sill_y - belt_y) * 0.12)
	var lights_on: bool = dmg.get("lights", mods.get("lights_on", false))
	var ls := maxi(1, int(len / 90))                   # lamp scale
	if front < 0.4:
		var lc := Color("fff4c8") if lights_on else Color("e8ecf0")
		match String(b.lamp):
			"slim":
				p.rect(nose - 3 * ls, lamp_y, 4 * ls, 2 * ls, lc)
				p.px(nose - 3 * ls, lamp_y + ls, Color("8a8e96"))
			"square":
				p.rect(nose - 2 * ls, lamp_y - ls, 3 * ls, 4 * ls, lc)
				p.vline(nose - 2 * ls, lamp_y - ls, 4 * ls, Color("8a8e96"))
			"angry":
				p.rect(nose - 5 * ls, lamp_y - ls, 6 * ls, ls, lc)
				p.rect(nose - 2 * ls, lamp_y, 3 * ls, 2 * ls, lc)
			"round":
				p.disc(nose - ls, lamp_y + ls, 1.6 * ls, lc)
				p.ring(nose - ls, lamp_y + ls, 2.2 * ls, Color("d8dce4"))
		p.rect(nose - int(len * 0.05), lamp_y + 4 * ls, 2 * ls, ls, Color("f0a020"))  # side marker
		if lights_on: p.glow(nose + 3, lamp_y + 1, 9.0 * ls, Color("fff4c8"), 0.8)
	else:
		p.rect(nose - 2, lamp_y, 3, 3, Color("2a2a2e"))
	if rear < 0.4:
		p.rect(tail, lamp_y - ls, 3 * ls, 4 * ls, Color("c8242c"))
		p.px(tail + ls, lamp_y, Color("ff6a6a"))
		p.rect(tail, lamp_y + 3 * ls, ls, ls, Color("f0a020"))
	# exhaust tips
	var ex := String(mods.get("exhaust", "single"))
	var ey := int(y - 0.055 * len + drop)
	var tips := 2 if ex == "dual" else (4 if ex == "quad" else 1)
	for k in mini(tips, 2):
		p.rect(tail - 2 + k * 4 * ls, ey, 3 * ls, 2 * ls, Color("8a8a90"))
		p.px(tail - 2 + k * 4 * ls, ey, Color("2a2a2e"))
	if kit.get("skirts", false):
		p.rect(x + int(len * 0.27), int(sill_y) - 1, int(len * 0.44), maxi(2, int(len * 0.014)), Color("1a1a1e"))
	if kit.get("diffuser", false):
		for k in 3: p.vline(x + 2 + k * 3 * ls, int(y - 0.06 * len + drop), 3 * ls, Color("1a1a1e"))
	var spoiler := String(mods.get("spoiler", "none"))
	if spoiler != "none" and not body in ["pickup", "tow", "van"]:
		var dx0 := x + int(len * 0.04)
		var dtop := p.h
		for yy in p.h:
			if body_img.get_px(dx0 + int(len * 0.05), yy).a > 0.0:
				dtop = yy
				break
		var u := maxi(1, int(len / 80))
		match spoiler:
			"ducktail":
				p.poly(PackedVector2Array([Vector2(dx0, dtop), Vector2(dx0 + len * 0.1, dtop), Vector2(dx0, dtop - 3 * u)]), paint.lightened(0.1))
			"wing":
				p.rect(dx0 + 3 * u, dtop - 4 * u, 2 * u, 4 * u, Color("1a1a1e"))
				p.rect(dx0 - u, dtop - 6 * u, int(len * 0.14), 2 * u, paint)
				p.hline(dx0 - u, dtop - 6 * u, int(len * 0.14), paint.lightened(0.3))
			"gt":
				p.rect(dx0 + 2 * u, dtop - 7 * u, 2 * u, 7 * u, Color("1a1a1e"))
				p.rect(dx0 + int(len * 0.1), dtop - 7 * u, 2 * u, 7 * u, Color("1a1a1e"))
				p.rect(dx0 - 3 * u, dtop - 10 * u, int(len * 0.18), 3 * u, Color("1a1a1e"))
				p.hline(dx0 - 3 * u, dtop - 10 * u, int(len * 0.18), Color("4a4a50"))
				p.rect(dx0 - 4 * u, dtop - 12 * u, 2 * u, 6 * u, Color("1a1a1e"))
	if b.get("boom", false):
		var bx := int(x + 0.38 * len)
		var by := int(y - 0.25 * len)
		var u2 := maxi(1, int(len / 90))
		for w2 in u2 + 1:
			p.line(bx, by + w2, int(x + 0.05 * len), int(y - 0.42 * len) + w2, Color("e8b020") if w2 == 0 else Color("2a2a2e"))
		p.line(int(x + 0.05 * len), int(y - 0.42 * len), int(x + 0.04 * len), int(y - 0.2 * len), Color("6a6a6e"))
		p.rect(int(x + 0.03 * len), int(y - 0.2 * len), 3 * u2, 3 * u2, Color("3a3a3e"))
		p.rect(int(x + 0.47 * len), int(y - 0.41 * len), int(len * 0.11), 2 * u2, Color("e8a020"))
		p.rect(int(x + 0.47 * len), int(y - 0.41 * len), 3 * u2, 2 * u2, Color("e03020"))
		p.text(int(x + 0.12 * len), int(y - 0.18 * len), "TOW", Color("e8b020"))
	if b.has("bed"):
		p.hline(x + 1, int(y - 0.276 * len + drop) + 1, int(len * 0.41), paint.darkened(0.4))
	var smoke := float(dmg.get("smoke", 0.0))
	if smoke > 0.0:
		var sx := int(x + (0.85 - front * 0.18) * len)
		for k in int(6 + smoke * 10.0):
			var rr := (2.0 + float(k) * 0.6) * maxf(1.0, len / 90.0)
			p.glow(sx - k * 2 + int(sin(float(k)) * 3.0), int(belt_y) - 3 - k * 3, rr, Color(0.82, 0.82, 0.84), 1.0 - float(k) * 0.04)
	var drv: Dictionary = dmg.get("driver", {})
	if not drv.is_empty():
		var u3 := maxi(1, int(len / 90))
		var wx := int(x + (float(doors[doors.size() - 1]) - 0.06) * len)
		var wy := int(belt_y)
		var sk: Color = drv.get("skin", Color("dcae88"))
		var hc: Color = drv.get("hair", Color("3b2a1e"))
		p.rect(wx - 5 * u3, wy - 6 * u3, 6 * u3, 6 * u3, hc)
		p.rect(wx - 5 * u3, wy - 6 * u3, 6 * u3, u3, hc.lightened(0.2))
		if drv.get("long_hair", false): p.rect(wx - 3 * u3, wy, 3 * u3, int(len * 0.1), hc)
		if drv.get("sleeve", null) != null: p.rect(wx - u3, wy - u3, 3 * u3, 3 * u3, drv.sleeve)
		p.rect(wx - u3, wy + 2 * u3, 3 * u3, int(len * 0.1), sk)
		p.rect(wx - u3, wy + 2 * u3 + int(len * 0.1), 3 * u3, 3 * u3, sk.darkened(0.08))
	# --- wheels: well, tyre, rim, brake
	for side in ["rear", "front"]:
		var wf: float = b.wr if side == "rear" else b.wf
		if side == "front": wf -= front * 0.12
		else: wf += rear * 0.08
		var wcx := int(x + wf * len)
		var wcy := y - int(round(r))
		for yy in range(int(wcy - r * 1.35), wcy + 1):
			for xx in range(int(wcx - r * 1.35), int(wcx + r * 1.35) + 1):
				var d := Vector2(xx - wcx, yy - wcy + drop * 0.6).length()
				if d < r * 1.16 and body_img.get_px(xx, yy).a > 0.0:
					p.px(xx, yy, Color("0c0a0e"))
				elif d < r * 1.16 + ink_w + 1 and body_img.get_px(xx, yy).a > 0.0:
					p.px(xx, yy, paint.darkened(0.3))                      # the arch lip
		if String(dmg.get("wheel_off", "")) == side:
			p.disc(wcx, wcy + 2, r * 0.6, Color("6a5a50"))
			p.ring(wcx, wcy + 2, r * 0.6, Color("4a3a30"))
			p.disc(wcx, wcy + 2, r * 0.25, Color("8a8a8e"))
			for k in 5:
				var a := TAU * float(k) / 5.0
				p.px(wcx + int(cos(a) * r * 0.42), wcy + 2 + int(sin(a) * r * 0.42), Color("c8c8cc"))
			p.rect(wcx - int(r * 0.7), wcy - int(r * 0.2), 2, int(r), Color("b8603a"))
			continue
		wheel(p, wcx, wcy, r, String(mods.get("rim", _default_rim(body, year))), dmg.get("flat", "") == side, mods)
	_ink(p, body_img, ink_w)

static func _default_rim(body: String, year: int) -> String:
	match body:
		"pickup", "tow": return "steel"
		"van": return "hubcap"
		"muscle": return "dish"
		"hatch": return "mesh" if year < 1995 else "multispoke"
		"sedan": return "tenspoke"
	return "fivespoke"

## An outline just outside the body, so the car reads against any background.
static func _ink(p: Pix, body_img: Pix, w := 1) -> void:
	for yy in range(1, p.h - 1):
		for xx in range(1, p.w - 1):
			if body_img.get_px(xx, yy).a > 0.0: continue
			var near := false
			for d in range(1, w + 1):
				if body_img.get_px(xx + d, yy).a > 0.0 or body_img.get_px(xx - d, yy).a > 0.0 or body_img.get_px(xx, yy - d).a > 0.0:
					near = true
			if near:
				var c := p.get_px(xx, yy)
				if c.a < 0.5 or c.v > 0.12: p.px(xx, yy, Color(INK, 0.85))

## One wheel: tyre with a sidewall and tread highlight, a brake disc and caliper behind the
## rim, then the rim itself, lit from the upper left.
static func wheel(p: Pix, cx: int, cy: int, r: float, rim: String, flat := false, mods := {}) -> void:
	var ry := r * (0.82 if flat else 1.0)
	var oy := int(r - ry)
	p.ellipse(cx, cy + oy, r, ry, Color("141216"))
	p.ellipse(cx, cy + oy, r * 0.9, ry * 0.9, Color("232127"))
	p.ellipse(cx, cy + oy, r * 0.8, ry * 0.8, Color("1a181c"))
	for k in 10:
		var a := PI + 0.3 + float(k) * 0.09
		p.px(cx + int(cos(a) * r * 0.95), cy + oy + int(sin(a) * ry * 0.95), Color("3a383e"))
	var rr := r * clampf(float(mods.get("rim_size", 0.66)), 0.45, 0.8)
	var rc: Color = mods.get("rim_color", Color("c8ccd4"))
	var hi := rc.lightened(0.3)
	var lo := rc.darkened(0.35)
	p.disc(cx, cy, rr * 0.95, Color("4a4a50"))                              # brake disc
	p.ring(cx, cy, rr * 0.72, Color("3a3a40"))
	var cal: Color = mods.get("caliper", Color("5a5a60"))
	p.rect(cx - int(rr * 0.25), cy - int(rr * 0.98), maxi(2, int(rr * 0.5)), maxi(2, int(rr * 0.42)), cal)
	match rim:
		"fivespoke", "tenspoke", "multispoke", "turbofan":
			var n: int = { "fivespoke": 5, "tenspoke": 10, "multispoke": 14, "turbofan": 12 }[rim]
			var wdt := maxi(1, int(rr / 4.0)) if rim == "fivespoke" else maxi(1, int(rr / 8.0))
			for k in n:
				var a := TAU * float(k) / float(n) - PI / 2.0
				var c := hi if cos(a + 0.8) > 0.3 else (lo if cos(a + 0.8) < -0.3 else rc)
				for t in range(int(rr * 0.25), int(rr) + 1):
					for w2 in range(-wdt / 2, wdt - wdt / 2):
						p.px(cx + int(round(cos(a) * t - sin(a) * w2)), cy + int(round(sin(a) * t + cos(a) * w2)), c)
				if rim == "turbofan":
					p.px(cx + int(cos(a + 0.2) * rr * 0.8), cy + int(sin(a + 0.2) * rr * 0.8), lo)
			p.ring(cx, cy, rr, rc)
			p.ring(cx, cy, rr + 0.6, lo)
		"mesh":
			p.disc(cx, cy, rr, rc.darkened(0.15))
			for yy in range(-int(rr), int(rr) + 1):
				for xx in range(-int(rr), int(rr) + 1):
					if xx * xx + yy * yy >= rr * rr: continue
					if posmod(xx + yy, 3) == 0: p.px(cx + xx, cy + yy, hi if xx + yy < 0 else rc)
					elif posmod(xx - yy, 3) == 0: p.px(cx + xx, cy + yy, lo)
			p.ring(cx, cy, rr, hi)
		"dish":
			p.disc(cx, cy, rr, rc)
			p.disc(cx - 1, cy - 1, rr * 0.75, hi)
			p.disc(cx, cy, rr * 0.6, rc.darkened(0.1))
			for k in 5:
				var a := TAU * float(k) / 5.0
				p.disc(cx + int(cos(a) * rr * 0.4), cy + int(sin(a) * rr * 0.4), maxf(1.0, rr * 0.08), Color("2a2a30"))
		"steel":
			p.disc(cx, cy, rr, Color("d8d8dc"))
			p.disc(cx + 1, cy + 1, rr * 0.7, Color("b8b8bc"))
			p.ring(cx, cy, rr * 0.6, Color("8a8a90"))
			for k in 8:
				var a := TAU * float(k) / 8.0
				p.disc(cx + int(cos(a) * rr * 0.42), cy + int(sin(a) * rr * 0.42), maxf(0.6, rr * 0.06), Color("5a5a60"))
		_:
			p.disc(cx, cy, rr, Color("c8ccd4"))
			p.disc(cx - 1, cy - 1, rr * 0.7, Color("e8ecf0"))
			p.ring(cx, cy, rr * 0.75, Color("8a8e96"))
	p.disc(cx, cy, maxf(1.0, rr * 0.22), lo)
	p.px(cx - 1, cy - 1, hi)

static func loose_wheel(p: Pix, cx: int, cy: int, r: float, rim: String) -> void:
	wheel(p, cx, cy, r, rim)
