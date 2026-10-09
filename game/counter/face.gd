## Faces drawn pixel by pixel from a seed: a straight port of CAGE BOSS's procedural portrait
## (src/art/portrait.ts, drawPortrait). 64x64, flat 3-tone skin lit from the upper left, dark
## outlines, cel ramps with a thin checker seam between bands, head shapes with per-face jitter,
## ten hair styles that recede and grey with age, brows, eyes with whites/irises/glints, nose,
## lips, beards, scars, glasses, hats, neck, shoulders and clothes, on a muted radial background.
## Same seed, same face, every time. The seed picks a civilian Look (no fight damage, no wounds).
class_name Face
extends RefCounted

const W := 64
const H := 64
const P := 64
const CX := 32

# CAGE BOSS palette (src/art/palette.ts)
const SKIN_TONES: Array[int] = [0xf0cfae, 0xdcae88, 0xc08e64, 0x9a6844, 0x75492f, 0x52321f]
const HAIR_COLORS: Array[int] = [0x1c1714, 0x3b2a1e, 0x6b4527, 0xa8763d, 0xd2b071, 0x8c3a22, 0x8d8a86, 0xd8d4cc]
const PAL_BLOOD := 0x8e2f2f
## Head shapes: half-widths at crown / temple / cheek / jaw / chin.
const HEAD_SHAPES := [[10, 13, 13, 11, 5], [11, 13, 14, 13, 7], [10, 12, 12, 9, 4], [11, 14, 15, 13, 6]]
const IRIS: Array[int] = [0x3a2a1c, 0x4a3420, 0x2c4a6a, 0x3a5a3a, 0x5a4428, 0x6a8698]

## Civilian wardrobe: clothing accents (hoodie, jersey, tie) and muted backdrops.
const CLOTH_ACCENTS: Array[int] = [0x4f6582, 0x8e2f2f, 0x4e6a43, 0x4c7470, 0x6a4c72, 0x9c4a35, 0x6f7a46, 0xb8733a, 0x2c3a5a, 0x5a5a62, 0x7a2a34, 0x3a5a7a]
const BG_ACCENTS: Array[int] = [0x3a3441, 0x343c46, 0x3a3a32, 0x40353b, 0x2f3a3a, 0x383444, 0x3c3832, 0x33363e]
const ATTIRES: Array[String] = ["shirt", "shirt", "shirt", "hoodie", "hoodie", "hoodie", "jersey", "jersey", "suit", "tracksuit"]

static var _cache := {}
static var _small_cache := {}

## 64x64 portrait texture (cached). `female` (-1 seed decides, 0 man, 1 woman) and `age`
## (-1 seed decides) let a caller match the face to a name and a date of birth.
static func texture(seed: int, female := -1, age := -1) -> ImageTexture:
	var key := "%d:%d:%d" % [seed, female, age]
	if _cache.has(key): return _cache[key]
	var t := ImageTexture.create_from_image(image(seed, female, age))
	_cache[key] = t
	return t

## 32x32 box-filtered portrait for small slots (CAGE BOSS halfSize), cached.
static func small_texture(seed: int, female := -1, age := -1) -> ImageTexture:
	var key := "%d:%d:%d" % [seed, female, age]
	if _small_cache.has(key): return _small_cache[key]
	var t := ImageTexture.create_from_image(small_image(seed, female, age))
	_small_cache[key] = t
	return t

static func image(seed: int, female := -1, age := -1) -> Image:
	return _to_image(paint(civilian(seed, female, age)), P, P)

static func small_image(seed: int, female := -1, age := -1) -> Image:
	return _to_image(_half_size(paint(civilian(seed, female, age)), P, P), P >> 1, P >> 1)

# ------------------------------------------------------------------ the person behind the seed

## A random civilian: look, gender, age, clothes. Deterministic in the seed.
static func civilian(seed: int, female_hint := -1, age_hint := -1) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = (seed * 2654435761 + 0x9e3779b9) & 0x7fffffffffffffff
	var female := r.randf() < 0.45
	var age := r.randi_range(19, 75)
	if female_hint >= 0: female = female_hint == 1
	if age_hint >= 0: age = clampi(age_hint, 16, 90)
	var skin := _pick(r, [0, 0, 1, 1, 2, 2, 3, 4, 5])
	var hair_color := _pick(r, [0, 0, 1]) if skin >= 2 else _pick(r, [0, 1, 1, 2, 2, 3, 4, 5])
	var hair: int
	if female: hair = _pick(r, [2, 3, 5, 5, 6, 7, 7, 8, 9, 9])
	else:
		hair = _pick(r, [0, 1, 1, 2, 2, 2, 3, 3, 5, 6, 7, 8, 4])
		if (hair == 4 and age > 40) or (hair == 6 and age > 50): hair = _pick(r, [0, 1, 2, 3])
		if age > 55 and r.randf() < 0.35: hair = 0
	var beard := 0
	if not female:
		beard = _pick(r, [0, 0, 0, 1, 1, 2, 3, 3, 4])
		if age < 25 and r.randf() < 0.4: beard = 5
		elif r.randf() < 0.025: beard = 6
	var look := {
		"head": r.randi_range(0, 3), "skin": skin, "hair": hair, "hairColor": hair_color, "beard": beard,
		"brows": r.randi_range(0, 2), "eyes": r.randi_range(0, 2), "nose": _pick(r, [0, 0, 0, 1, 1, 2]),
		"ears": _pick(r, [0, 0, 0, 0, 0, 1]), "scar": 0 if r.randf() < 0.88 else _pick(r, [1, 1, 2]),
		"tattoo": 0 if r.randf() < 0.92 else _pick(r, [1, 1, 3]), "build": _pick(r, [0, 1, 1, 2]),
		"glasses": 0, "widow": 0, "stoned": 0, "beanie": 0, "hat": 0, "iris": -1, "freckles": 0, "chain": 0,
	}
	var g := r.randf()
	if g < 0.05: look.glasses = 1
	elif g < 0.2 + (0.2 if age > 45 else 0.0): look.glasses = 2
	if not female and r.randf() < 0.06: look.widow = 1
	if r.randf() < 0.03: look.stoned = 1
	var hat := r.randf()
	if hat < 0.08: look.beanie = 1
	elif hat < 0.11: look.hat = 1
	if skin <= 1 and r.randf() < 0.25: look.iris = 5
	if skin <= 1 and r.randf() < 0.1: look.freckles = 1
	if not female and r.randf() < 0.06: look.chain = 1
	var ex := r.randf()
	return {
		"id": "civ:%d" % seed, "look": look, "female": female, "age": age,
		"attire": ATTIRES[r.randi() % ATTIRES.size()],
		"accent": CLOTH_ACCENTS[r.randi() % CLOTH_ACCENTS.size()],
		"bg": BG_ACCENTS[r.randi() % BG_ACCENTS.size()],
		"expr": "flat" if ex < 0.7 else ("smirk" if ex < 0.9 else "frown"),
	}

static func _pick(r: RandomNumberGenerator, a: Array) -> int:
	return int(a[r.randi() % a.size()])

## Draw the portrait for a civilian() dictionary into a 64x64 buffer of 0xRRGGBB ints (-1 = empty).
static func paint(inp: Dictionary) -> PackedInt32Array:
	var p := _Painter.new(inp)
	p.paint()
	return p.px

# ------------------------------------------------------------------ colour helpers (palette.ts)

## JS Math.round: half up towards +infinity.
static func jround(v: float) -> int:
	return int(floor(v + 0.5))

static func lerp_color(a: int, b: int, t: float) -> int:
	var ar := (a >> 16) & 255
	var ag := (a >> 8) & 255
	var ab := a & 255
	var br := (b >> 16) & 255
	var bg := (b >> 8) & 255
	var bb := b & 255
	return (jround(ar + (br - ar) * t) << 16) | (jround(ag + (bg - ag) * t) << 8) | jround(ab + (bb - ab) * t)

static func shade(c: int, f: float) -> int:
	return lerp_color(c, 0x000000, -f) if f < 0.0 else lerp_color(c, 0xffffff, f)

## Pick from a ramp (dark..light): flat cel bands, a thin checker seam where two bands meet.
static func ramp(cols: PackedInt32Array, v: float, x: int, y: int) -> int:
	var n := cols.size()
	var t := maxf(0.0, minf(0.999, v)) * (n - 1)
	var i := int(floor(t))
	var f := t - i
	if f > 0.42 and f < 0.58: return cols[mini(n - 1, i + 1)] if (x + y) % 2 != 0 else cols[i]
	return cols[mini(n - 1, i + 1)] if f >= 0.5 else cols[i]

## FNV-1a, as CAGE BOSS's hashString (ASCII ids).
static func hash_string(s: String) -> int:
	var h := 0x811c9dc5
	for ch in s.to_utf8_buffer():
		h ^= ch
		h = (h * 0x01000193) & 0xffffffff
	return h

## Math.imul(a, b) >>> 0 for 32-bit unsigned a, b.
static func _mul32(a: int, b: int) -> int:
	var lo := (a * (b & 0xffff)) & 0xffffffff
	var hi := ((a * ((b >> 16) & 0xffff)) & 0xffff) << 16
	return (lo + hi) & 0xffffffff

static func _to_image(px: PackedInt32Array, w: int, h: int) -> Image:
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for i in w * h:
		var c := px[i]
		if c < 0: continue
		bytes[i * 4] = (c >> 16) & 255
		bytes[i * 4 + 1] = (c >> 8) & 255
		bytes[i * 4 + 2] = c & 255
		bytes[i * 4 + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)

## Box-filter a portrait down by 2x (portrait.ts halfSize).
static func _half_size(src: PackedInt32Array, w: int, h: int) -> PackedInt32Array:
	var ow := w >> 1
	var oh := h >> 1
	var out := PackedInt32Array()
	out.resize(ow * oh)
	out.fill(-1)
	for y in oh:
		for x in ow:
			var r := 0
			var g := 0
			var bl := 0
			var n := 0
			for dy in 2:
				for dx in 2:
					var c := src[(y * 2 + dy) * w + x * 2 + dx]
					if c < 0: continue
					r += (c >> 16) & 255
					g += (c >> 8) & 255
					bl += c & 255
					n += 1
			if n > 0: out[y * ow + x] = (jround(float(r) / n) << 16) | (jround(float(g) / n) << 8) | jround(float(bl) / n)
	return out

# ------------------------------------------------------------------ the painter (drawPortrait)

class _Painter:
	var px := PackedInt32Array()
	var seed := 0
	var look: Dictionary
	var female := false
	var age := 30
	var build := 0
	var grey := 0.0
	var skin := 0
	var SK := PackedInt32Array()
	var SKL := PackedInt32Array()
	var OUT := 0
	var hair_base := 0
	var HR := PackedInt32Array()
	var attire := "shirt"
	var accent := 0x3a3441
	var bg := 0x3a3441
	var expr := "flat"
	var hw_tab := PackedInt32Array()
	var crown := 0
	var temple := 0
	var cheek := 0
	var jaw := 0
	var chin := 0
	var fat := 0
	var top := 9
	var chin_y := 45
	var face_h := 36
	var eye_y := 0
	var brow_y := 0
	var nose_y := 0
	var mouth_y := 0
	var eye_l := 0
	var eye_r := 0
	var neck_w := 0
	var shoulder_y := 52
	var hs := 0
	var recede := 0
	var hair_out := 0

	func _init(inp: Dictionary) -> void:
		px.resize(P * P)
		px.fill(-1)
		look = inp.look
		seed = Face.hash_string(str(inp.id))
		female = bool(inp.female)
		age = int(inp.age)
		attire = str(inp.attire)
		accent = int(inp.accent)
		bg = int(inp.bg)
		expr = str(inp.get("expr", "flat"))

	func rnd(n: int) -> int:
		var k := n * 2654435761 + 7
		return ((seed >> (n % 24)) ^ (((seed & 0xffff) * (k & 0xffff)) & 0xffff)) & 0xffff

	func lk(key: String) -> int:
		return int(look.get(key, 0))

	func put(x: int, y: int, c: int) -> void:
		if x < 0 or y < 0 or x >= P or y >= P: return
		px[y * P + x] = c

	func at(x: int, y: int) -> int:
		if x < 0 or y < 0 or x >= P or y >= P: return -1
		return px[y * P + x]

	func rect(x: int, y: int, w: int, h: int, c: int) -> void:
		for j in h:
			for i in w: put(x + i, y + j, c)

	func hline(x0: int, x1: int, y: int, c: int) -> void:
		for x in range(x0, x1 + 1): put(x, y, c)

	func ramp(cols: PackedInt32Array, v: float, x: int, y: int) -> int:
		return Face.ramp(cols, v, x, y)

	func shade(c: int, f: float) -> int:
		return Face.shade(c, f)

	func lerpc(a: int, b: int, t: float) -> int:
		return Face.lerp_color(a, b, t)

	func pal(a: Array) -> PackedInt32Array:
		return PackedInt32Array(a)

	## Half-width of the head at row y (0 outside).
	func hw_at(y: int) -> int:
		if y < 0 or y >= P: return 0
		return hw_tab[y]

	func _hw_calc(y: int) -> int:
		var t := float(y - top) / face_h
		if t < 0.0 or t > 1.0: return 0
		var hw: float
		if t < 0.12: hw = crown * sqrt(t / 0.12) * 0.9 + 2
		elif t < 0.32: hw = crown + (temple - crown) * ((t - 0.12) / 0.2)
		elif t < 0.6: hw = temple + (cheek - temple) * ((t - 0.32) / 0.28)
		elif t < 0.86: hw = cheek + (jaw - cheek) * ((t - 0.6) / 0.26)
		else: hw = jaw + (chin - jaw) * ((t - 0.86) / 0.14)
		if t > 0.55: hw += fat
		return maxi(1, Face.jround(hw))

	func paint() -> void:
		build = mini(3, lk("build") + (1 if age > 38 else 0))
		grey = clampf((age - 36) / 14.0, 0.0, 1.0)
		skin = Face.SKIN_TONES[lk("skin") % Face.SKIN_TONES.size()]
		SK = pal([shade(skin, -0.42), shade(skin, -0.26), shade(skin, -0.12), skin, shade(skin, 0.1), shade(skin, 0.2)])
		SKL = pal([shade(skin, -0.24), skin, shade(skin, 0.12)])
		OUT = shade(skin, -0.62)
		hair_base = lerpc(Face.HAIR_COLORS[lk("hairColor") % Face.HAIR_COLORS.size()], 0xa8a59e, grey)
		HR = pal([shade(hair_base, -0.35), shade(hair_base, -0.18), hair_base, shade(hair_base, 0.15)])
		hair_out = shade(HR[0], -0.4)

		# ------------------------------------------------ background ('plain')
		var bgr := pal([shade(bg, -0.35), shade(bg, -0.18), bg])
		for y in P:
			for x in P:
				var d := sqrt(float((x - 32) * (x - 32) + (y - 26) * (y - 26))) / 46.0
				put(x, y, ramp(bgr, 1.0 - d, x, y))

		# ------------------------------------------------ geometry
		var base: Array = Face.HEAD_SHAPES[lk("head") % Face.HEAD_SHAPES.size()]
		var jw := (rnd(31) % 3) - 1
		crown = int(base[0]) + (rnd(33) % 2)
		temple = int(base[1]) + jw
		cheek = int(base[2]) + jw
		jaw = int(base[3]) + ((rnd(35) % 3) - 1)
		chin = int(base[4]) + ((rnd(37) % 3) - 1)
		fat = 1 if build >= 2 else 0
		top = 9
		chin_y = 45 + (1 if lk("head") == 2 else 0)
		face_h = chin_y - top
		hw_tab.resize(P)
		for y in P: hw_tab[y] = _hw_calc(y)
		eye_y = top + Face.jround(face_h * 0.46) + ((rnd(41) % 3) - 1)
		brow_y = eye_y - 4 - (rnd(43) % 2)
		nose_y = eye_y + 6 + (rnd(45) % 3)
		mouth_y = mini(chin_y - 5, nose_y + 5 + (rnd(47) % 2))
		var spread := 6 + (1 if rnd(49) % 3 == 0 else 0) - (1 if rnd(51) % 4 == 0 else 0)
		eye_l = CX - spread - 1
		eye_r = CX + spread

		# ------------------------------------------------ long hair behind the head
		hs = lk("hair")
		recede = mini(4, int(floor((age - 31) / 3.0))) if age >= 33 and not female else 0
		if hs == 9:
			for y in range(top + 3, P):
				var wave := Face.jround(sin(y / 3.2) * 1.5)
				var grow := minf(5.0, (y - top - 3) * 0.8)
				var hw := Face.jround(maxi(hw_at(mini(y, chin_y)), temple) + grow + (minf(6.0, (y - chin_y) / 2.0) if y > chin_y else 0.0) + wave)
				for x in range(CX - hw, CX + hw):
					var curl := 0.22 if (x * 5 + y * 3 + rnd(x & 31)) % 7 == 0 else (-0.15 if (x + y * 2) % 9 == 0 else 0.0)
					put(x, y, ramp(HR, 0.3 + 0.45 * (1.0 - float(x - (CX - hw)) / (2 * hw)) + curl - (y - top) / 200.0, x, y))
				put(CX - hw - 1, y, hair_out)
				put(CX + hw, y, hair_out)
		if hs == 5 or (female and (hs == 6 or hs == 7)):
			var hlen := 58 if female else 50
			for y in range(top + 4, hlen):
				var hw := maxi(hw_at(mini(y, chin_y)), temple) + 3
				for x in range(CX - hw, CX + hw):
					var v := 0.35 + 0.4 * (1.0 - float(x - (CX - hw)) / (2 * hw)) + (0.2 if (x * 7 + rnd(x)) % 5 == 0 else 0.0)
					put(x, y, ramp(HR, v - (y - top) / 160.0, x, y))

		_attire()
		_neck_and_ears()
		_head()
		_hair()
		_hats()
		_face()
		_beard()
		_marks()
		_accessories()

	# ------------------------------------------------ shoulders, chest, attire
	func _attire() -> void:
		neck_w = 6 + build * 2 + (-1 if female else 0)
		shoulder_y = 52
		var cols: PackedInt32Array
		match attire:
			"suit": cols = pal([0x16161c, 0x20202a, 0x2c2c38])
			"shirt": cols = pal([0xa8a296, 0xc8c2b4, 0xe2ddd0])
			"hoodie": cols = pal([shade(accent, -0.45), shade(accent, -0.25), accent])
			"tracksuit": cols = pal([0x101014, 0x1a1a22, 0x262632])
			_: cols = pal([shade(accent, -0.4), shade(accent, -0.2), accent, shade(accent, 0.15)])
		for y in range(shoulder_y - 4, P):
			var t := minf(1.0, (y - (shoulder_y - 4)) / 8.0)
			var half := Face.jround(neck_w + (22 + build * 3 - neck_w) * sqrt(t))
			for x in range(CX - half, CX + half):
				var nx := float(x - CX) / half
				var v := 0.62 - nx * 0.28 - (y - shoulder_y) / 50.0
				put(x, y, ramp(cols, v, x, y))
			put(CX - half - 1, y, 0x0c0a0c)
			put(CX + half, y, 0x0c0a0c)
		match attire:
			"suit":
				for y in range(shoulder_y - 3, P):
					var v := maxi(1, 6 - int(floor((y - shoulder_y + 3) / 2.0)))
					hline(CX - v, CX + v - 1, y, 0xe8e3d6)
					put(CX - v - 1, y, 0x0e0e12)
					put(CX + v, y, 0x0e0e12)
				for y in range(shoulder_y - 1, P):
					var tw := 1 if y < shoulder_y + 1 else 2
					hline(CX - tw, CX + tw - 1, y, accent)
				hline(CX - 1, CX, shoulder_y - 2, shade(accent, -0.3))
			"shirt":
				for y in range(shoulder_y - 3, shoulder_y + 3):
					put(CX - 5 + (y - shoulder_y + 3), y, 0x8a8478)
					put(CX + 4 - (y - shoulder_y + 3), y, 0x8a8478)
				for y in range(shoulder_y + 3, P, 3): put(CX, y, 0x6a655a)
			"hoodie":
				for y in range(shoulder_y - 4, shoulder_y + 1): hline(CX - neck_w - 3, CX + neck_w + 2, y, shade(accent, -0.35))
				rect(CX - 4, shoulder_y + 2, 1, 7, 0xe0dccf)
				rect(CX + 3, shoulder_y + 2, 1, 7, 0xe0dccf)
			"tracksuit":
				for k in 3:
					for y in range(shoulder_y - 1, P):
						var off := Face.jround((y - shoulder_y) * 0.35)
						put(CX - 17 - k * 2 - off, y, 0xe8e8ee)
						put(CX + 16 + k * 2 + off, y, 0xe8e8ee)
				hline(CX - neck_w - 1, CX + neck_w, shoulder_y - 4, 0x26262e)
				hline(CX - neck_w - 1, CX + neck_w, shoulder_y - 3, 0x26262e)
				for y in range(shoulder_y - 4, P): put(CX, y, 0x8a8a94)
				rect(CX - 10, shoulder_y + 4, 4, 2, 0xe8e8ee)
			_:
				rect(CX - 3, shoulder_y + 3, 6, 6, shade(accent, 0.35))
				hline(CX - neck_w, CX + neck_w - 1, shoulder_y - 3, shade(accent, 0.3))

	# ------------------------------------------------ neck, ears
	func _neck_and_ears() -> void:
		for y in range(chin_y - 6, shoulder_y - 1):
			for x in range(CX - neck_w, CX + neck_w):
				var nx := float(x - CX) / neck_w
				var v := 0.5 - nx * 0.3 - (0.25 if y < chin_y + 2 else 0.0)
				put(x, y, ramp(SKL, v, x, y))
			put(CX - neck_w - 1, y, OUT)
			put(CX + neck_w, y, OUT)
		if not female and build >= 1:
			for y in range(chin_y + 2, chin_y + 5): put(CX, y + 1, SK[2])
		if lk("tattoo") == 1 or lk("tattoo") == 3:
			for i in 7: put(CX - neck_w + 1 + (i % 3), chin_y + 1 + i, shade(skin, -0.58))
		var cauli := mini(3, lk("ears"))
		var ear_top := eye_y - 3
		for side in [-1, 1]:
			var s: int = side
			var hw := hw_at(ear_top + 3)
			var ex := CX - hw - 1 if s < 0 else CX + hw
			var eh := 9 + (1 if cauli >= 2 else 0)
			for j in eh:
				var wdt := 2 if (j == 0 or j == eh - 1) else 3 + (1 if cauli >= 1 else 0) + (1 if cauli >= 3 and j > 2 and j < eh - 2 else 0)
				for k in wdt:
					var x := ex + s * k
					var lumpy := cauli >= 2 and (j + k) % 3 == 0
					var c: int
					if k == wdt - 1: c = OUT
					elif lumpy: c = SK[1]
					elif k == 1 and j > 2 and j < eh - 2: c = SK[1]
					else: c = SK[3] if s < 0 else SK[2]
					put(x, ear_top + j, c)

	# ------------------------------------------------ head (lit from upper left)
	func _head() -> void:
		for y in range(top, chin_y + 1):
			var hw := hw_at(y)
			for x in range(CX - hw, CX + hw):
				var nx := (x - CX + 0.5) / hw
				var ny := float(y - top) / face_h
				var v := 0.66 - nx * 0.3 - maxf(0.0, ny - 0.75) * 0.9 - pow(absf(nx), 3) * 0.35
				if ny > 0.5 and ny < 0.58 and absf(nx) > 0.45 and absf(nx) < 0.8: v += 0.12
				if ny > 0.64 and ny < 0.74 and absf(nx) > 0.5: v -= 0.12
				put(x, y, ramp(SKL, v, x, y))
			put(CX - hw - 1, y, OUT)
			put(CX + hw, y, OUT)
		hline(CX - hw_at(chin_y) - 1, CX + hw_at(chin_y), chin_y + 1, OUT)
		for x in range(CX - hw_at(top), CX + hw_at(top)): put(x, top - 1, OUT)
		for x in range(CX - neck_w, CX + neck_w): put(x, chin_y + 1, SK[0])

	## Hair cap: the head silhouette pushed up by `vol` px, down to a hairline `rows` below the crown.
	func cap_rows(rows: int, rec: int, vol := 3, sideburns := true, pattern := 0, side := 1) -> void:
		var widow := lk("widow") != 0
		for y in range(top - vol, brow_y + 1):
			var outer := hw_at(mini(chin_y, maxi(top, y + vol))) + 1 + (side if y > top and y < eye_y - 3 else 0)
			var inner := hw_at(maxi(top, y))
			for x in range(CX - outer, CX + outer):
				var dx := absf(x - CX + 0.5)
				var r := y - top
				var hairline := rows - (rec * 2 if dx < 3 + rec * 2 else 0) - (-2 if dx > inner - 4 else 0)
				if widow: hairline += 4 if dx < 1.5 else (2 if dx < 3 else (-2 if dx < 7 else 0))
				if sideburns and dx > inner - 3 and y < eye_y - 2: hairline = 99
				if r >= hairline: continue
				if y >= top and r >= rows and not (sideburns and dx > inner - 3): continue
				if pattern == 1 and y > top and Face._mul32((((x * 73856093) & 0xffffffff) ^ ((y * 19349663) & 0xffffffff)), 2654435761) % 5 == 0: continue
				if pattern == 1 and dx > inner and y > top: continue
				var nx := float(x - CX) / outer
				var strand := 0.0
				if (x * 7 + int(floor(y / 2.0)) * 3 + (rnd(x & 15) & 3)) % 6 == 0: strand = 0.12
				elif (x * 5 + y * 3 + (rnd(y & 15) & 3)) % 9 == 0: strand = -0.14
				var shine := 0.14 if y < top + 2 and nx < -0.1 and nx > -0.7 else 0.0
				var hcol := ramp(HR, 0.5 - nx * 0.3 + strand + shine - (y - (top - vol)) / 120.0, x, y)
				put(x, y, lerpc(hcol, SKL[0], 0.3) if pattern == 1 else hcol)
			if y < top:
				put(CX - outer - 1, y, hair_out)
				put(CX + outer, y, hair_out)
		for x in range(CX - hw_at(top) - 1, CX + hw_at(top) + 1): put(x, top - vol - 1, hair_out)

	# ------------------------------------------------ hair (front)
	func _hair() -> void:
		match hs:
			0: # bald: shine
				put(CX - 6, top + 2, SK[5])
				put(CX - 5, top + 2, SK[5])
				put(CX - 7, top + 3, SK[5])
				put(CX - 6, top + 3, SK[4])
			1: # buzz cut: dithered fuzz
				cap_rows(6, int(floor(recede / 2.0)), 1, true, 1, 0)
			2: # short
				cap_rows(7, recede)
			3: # swept / quiff
				cap_rows(7, recede, 4, true, 0, 2)
				for x in range(CX - 9, CX + 8):
					for y in range(top - 4, top - 1):
						if y > top - 4 or x > CX - 5: put(x, y, ramp(HR, 0.6 - (x - CX) / 20.0, x, y))
				for y in range(top, top + 5): put(CX + 7 + int(floor((y - top) / 2.0)), y, HR[1])
			4: # mohawk
				for y in range(top - 9, top + 8):
					for x in range(CX - 3, CX + 3):
						put(x, y, ramp(HR, 0.7 - (x - CX + 3) / 8.0 + (0.2 if (x + y) % 4 == 0 else 0.0), x, y))
				for y in range(top - 9, top + 8):
					put(CX - 4, y, hair_out)
					put(CX + 3, y, hair_out)
				for y in range(top, top + 6):
					for x in range(CX - hw_at(y), CX + hw_at(y)):
						if absi(x - CX) > 3 and (x + y) % 3 == 0: put(x, y, HR[0])
			5: # long
				cap_rows(8, 0 if female else recede, 3, true, 0, 2)
				for y in range(top + 6, top + 26):
					var hw := hw_at(mini(chin_y, y))
					put(CX - hw, y, HR[1])
					put(CX - hw + 1, y, HR[2])
					put(CX + hw - 1, y, HR[1])
					if female:
						put(CX - hw + 2, y, HR[2])
						put(CX + hw - 2, y, HR[1])
			6: # braids / cornrows
				for y in range(top - 2, top + 8):
					var hw := hw_at(mini(chin_y, maxi(top, y + 2))) + 1
					for x in range(CX - hw, CX + hw):
						var lane := (x - CX + 32) % 4
						if lane == 0: continue
						put(x, y, HR[2] if (y + (1 if lane == 2 else 0)) % 2 != 0 else HR[1])
				if female:
					for y in range(top + 6, 60): put(CX + hw_at(mini(y, chin_y)) + 1, y, HR[2] if y % 2 != 0 else HR[0])
			8: # curly mess: a big uneven cloud of ringlets
				var R := 15
				var cy := top + 2
				for y in range(cy - R - 2, eye_y - 1):
					for x in range(CX - R - 4, CX + R + 4):
						var nx := (x - CX + 0.5) / (R + 3)
						var ny := float(y - cy) / (R - 1)
						var wob := float((rnd((x * 7 + y * 13) & 63) % 5) - 2) / 18.0
						if nx * nx + ny * ny > 1.0 + wob: continue
						if y >= top + 5 and absf(x - CX + 0.5) < hw_at(mini(chin_y, y)) - 1 and y > top + 4: continue
						var curl := 0.25 if ((x + y * 2) % 4 == 0 or (x * 3 + y) % 5 == 0) else 0.0
						put(x, y, ramp(HR, 0.55 - nx * 0.3 - ny * 0.15 + curl - ((x ^ y) & 1) * 0.08, x, y))
				for i in 40:
					var x := CX - R + (rnd(i + 200) % (R * 2))
					var y := cy - R + (rnd(i + 260) % (R + 4))
					if at(x, y) != -1 and y < top + 5: put(x, y, HR[2] if i % 3 != 0 else shade(HR[0], -0.3))
				for x in range(CX - 6, CX + 6, 2): put(x, top + 5 + ((x + rnd(x & 15)) % 2), HR[1])
			9: # long waves, middle part
				cap_rows(7, 0, 4, false)
				for y in range(top - 3, top + 6): put(CX - 1, y, shade(HR[0], -0.25))
				for k in range(1, 7):
					put(CX - 1 - k, top - 3 + int(floor(k / 2.0)), HR[3])
					put(CX + k, top - 3 + int(floor(k / 2.0)), HR[2])
				for side in [-1, 1]:
					var s: int = side
					for y in range(top + 4, P):
						var face := hw_at(y) if y <= chin_y else neck_w + 2
						var wave := Face.jround(sin(y / 2.6 + (1.4 if s > 0 else 0.0)) * 1.2)
						var w0 := 4 if y < eye_y else (3 if y < chin_y else 5 + mini(3, int(floor((y - chin_y) / 4.0))))
						for k in w0:
							var x := (CX - face - 1 - k + wave) if s < 0 else (CX + face + k + wave)
							var strand := 0.2 if (x * 3 + y) % 5 == 0 else (-0.18 if (x + y) % 7 == 0 else 0.0)
							put(x, y, ramp(HR, (0.62 if s < 0 else 0.4) - k * 0.05 + strand - (y - top) / 180.0, x, y))
						if y < eye_y - 1:
							for k in 2: put(CX - face + k if s < 0 else CX + face - 1 - k, y, HR[2] if s < 0 else HR[1])
			7: # man bun / ponytail
				cap_rows(6, 0, 2)
				for y in range(top - 7, top - 1):
					for x in range(CX - 3, CX + 4):
						if sqrt(float((x - CX) * (x - CX) + (y - (top - 4)) * (y - (top - 4)))) < 3.6: put(x, y, ramp(HR, 0.6 - (x - CX) / 8.0, x, y))
		# grey temples
		if grey > 0.3 and hs != 0:
			for y in range(eye_y - 6, eye_y):
				put(CX - hw_at(y), y, 0xb8b5ae)
				put(CX + hw_at(y) - 1, y, 0xb8b5ae)

	func _hats() -> void:
		if lk("hat") == 1:
			# cowboy hat: felt crown with a pinch, a band, and a wide curled brim
			var felt := pal([0x3a2616, 0x5a3c22, 0x7a5432, 0x96703e])
			var brim_y := top + 4
			for y in range(top - 9, brim_y):
				var hw := 10 - (1 if y < top - 6 else 0)
				for x in range(CX - hw, CX + hw):
					if y == top - 9 and absf(x - CX + 0.5) < 3: continue
					put(x, y, ramp(felt, 0.7 - (x - CX) / 26.0 - (y - top) / 40.0, x, y))
				put(CX - hw - 1, y, 0x1a1008)
				put(CX + hw, y, 0x1a1008)
			hline(CX - 10, CX + 9, brim_y - 3, 0x2a1a0e)
			hline(CX - 10, CX + 9, brim_y - 2, 0x4a3018)
			for x in range(CX - 22, CX + 22):
				var curl := -1 if absf(x - CX + 0.5) > 17 else 0
				put(x, brim_y + curl, ramp(felt, 0.75 - (x - CX) / 50.0, x, brim_y))
				put(x, brim_y + 1 + curl, felt[0])
		elif lk("hat") == 2:
			# green top hat with a black band and gold buckle, cocked to one side
			var G := pal([0x14401e, 0x1e5a2a, 0x2a7a38, 0x3a9a48])
			var brim_y := top + 2
			for y in range(top - 9, brim_y):
				var tilt := Face.jround((brim_y - y) / 6.0)
				for x in range(CX - 8 + tilt, CX + 8 + tilt): put(x, y, ramp(G, 0.7 - (x - CX - tilt) / 20.0, x, y))
				put(CX - 9 + tilt, y, 0x08200c)
				put(CX + 8 + tilt, y, 0x08200c)
				if y >= brim_y - 5 and y < brim_y - 1:
					for x in range(CX - 8 + tilt, CX + 8 + tilt): put(x, y, 0x101010)
			rect(CX - 2, brim_y - 5, 4, 4, 0xd8b040)
			rect(CX - 1, brim_y - 4, 2, 2, 0x101010)
			for x in range(CX - 14, CX + 14):
				put(x, brim_y, G[2])
				put(x, brim_y + 1, G[0])
		if lk("beanie") != 0:
			# knit beanie pulled down to just above the brows, folded cuff, a bit of slouch
			var knit := pal([0x1c1c22, 0x2a2a32, 0x3a3a44])
			var cuff := top + 11
			for y in range(top - 4, cuff + 3):
				var hw := maxi(hw_at(maxi(top, y)) + 2, (9 + (y - top + 4) * 2) if y < top else 0)
				for x in range(CX - hw, CX + hw):
					var v := 0.7 - float(x - CX) / (hw * 3) - (y - top) / 60.0 + (0.12 if (x + y) % 3 == 0 else 0.0)
					put(x, y, ramp(knit, v + 0.15 if y >= cuff else v, x, y))
				put(CX - hw - 1, y, 0x08080a)
				put(CX + hw, y, 0x08080a)
			hline(CX - hw_at(cuff) - 2, CX + hw_at(cuff) + 1, cuff - 1, 0x101014)
			rect(CX + 5, cuff, 4, 2, 0xd8d8de)

	# ------------------------------------------------ brows, eyes, nose, mouth
	func _face() -> void:
		var brow_c := 0x9a978f if grey > 0.5 else shade(hair_base, -0.15)
		var thick := 2 if lk("brows") == 2 else 1
		var angry := lk("brows") == 2 or expr == "frown"
		for pair in [[eye_l, -1], [eye_r, 1]]:
			var cx: int = pair[0]
			var dir: int = pair[1]
			for i in range(-3, 4):
				var tilt := Face.jround(float(i * dir) / 3.0) if angry else (1 if i * dir > 2 else 0)
				for t in thick: put(cx + i, brow_y + tilt + t, brow_c)
			if female: put(cx + 4 * dir, brow_y + 1, brow_c)
		for i in range(-3, 4):
			put(eye_l + i, brow_y + thick + 1, SK[2])
			put(eye_r + i, brow_y + thick + 1, SK[2])

		var iris_i := lk("iris")
		var iris: int = Face.IRIS[iris_i if iris_i >= 0 else rnd(3) % 5]
		var squint := lk("eyes") == 1 or lk("stoned") != 0
		for cx in [eye_l, eye_r]: _eye(cx, squint, iris)
		if lk("stoned") != 0:
			for cx in [eye_l, eye_r]:
				put(cx - 2, eye_y, 0xd88a84)
				put(cx + 2, eye_y, 0xd88a84)
				for i in range(-3, 4): put(cx + i, eye_y - 1, SK[2])
				for i in range(-2, 3): put(cx + i, eye_y + 1, lerpc(SK[1], 0x8a5a6a, 0.35))
		if lk("eyes") == 2:
			for i in range(-2, 3):
				put(eye_l + i, eye_y - 1, SK[2])
				put(eye_r + i, eye_y - 1, SK[2])
		if age > 34:
			for i in range(-2, 3):
				put(eye_l + i, eye_y + 2, SK[2])
				put(eye_r + i, eye_y + 2, SK[2])
		if age > 38:
			put(eye_l - 5, eye_y - 1, SK[1])
			put(eye_l - 5, eye_y + 1, SK[1])
			put(eye_r + 5, eye_y - 1, SK[1])
			put(eye_r + 5, eye_y + 1, SK[1])
		if age > 42 and hs != 4:
			for i in range(-6, 7):
				if i % 4 != 0: put(CX + i, brow_y - 4 - (1 if absi(i) > 3 else 0), SK[2])

		# nose
		var broken := lk("nose") == 2
		var nx0 := CX - 1 + (1 if broken else 0)
		for y in range(brow_y + 3, nose_y):
			var kink := 1 if broken and y > brow_y + 5 else 0
			put(nx0 + kink - 1, y, SK[2])
			put(nx0 + kink, y, SK[4])
		var wide := 1 if lk("nose") == 1 else 0
		for i in range(-2 - wide, 3 + wide): put(nx0 + i, nose_y, SK[2] if i < 0 else SK[3])
		put(nx0 - 2 - wide, nose_y + 1, SK[1])
		put(nx0 + 2 + wide, nose_y + 1, SK[1])
		put(nx0 - 1, nose_y + 1, OUT)
		put(nx0 + 1, nose_y + 1, OUT)
		put(nx0 + 1, nose_y - 1, SK[5])
		for i in range(-2 - wide, 3 + wide): put(nx0 + i, nose_y + 2, SK[2])
		var fold := 2 if age > 30 else 1
		var fold_c: int = SK[2 - (1 if age > 40 else 0)]
		for i in 3 + fold:
			put(nx0 - 4 - wide - int(floor(i / 2.0)), nose_y + 1 + i, fold_c)
			put(nx0 + 4 + wide + int(floor(i / 2.0)), nose_y + 1 + i, fold_c)

		# mouth & expression
		var lip_d := lerpc(shade(skin, -0.35), 0x8a3a3a, 0.45 if female else 0.18)
		var lip_l := lerpc(shade(skin, -0.05), 0xb05a5a, 0.35 if female else 0.1)
		var mw := (4 if female else 4 + (1 if build >= 2 else 0)) + (1 if rnd(53) % 3 == 0 else 0) - (1 if rnd(55) % 4 == 0 else 0)
		for i in range(-mw, mw + 1):
			var dy := 0
			if expr == "frown" and absi(i) >= mw - 1: dy = 1
			if (expr == "grin" or expr == "smirk") and ((absi(i) >= mw - 1) if expr == "grin" else (i >= mw - 1)): dy = -1
			put(CX + i, mouth_y + dy, OUT)
			if absi(i) < mw: put(CX + i, mouth_y - 1 + dy, lip_d)
			if absi(i) < mw - 1: put(CX + i, mouth_y + 1, lip_l)
		if expr == "grin":
			for i in range(-mw + 2, mw - 1): put(CX + i, mouth_y + 1, 0xeee8dc)
		hline(CX - 2, CX + 1, mouth_y + 3, SK[2])
		if lk("head") == 1: put(CX, chin_y - 2, SK[1])
		_mw = mw

	var _mw := 4

	func _eye(cx: int, squint: bool, iris: int) -> void:
		for i in range(-3, 4): put(cx + i, eye_y - 2, SK[1])
		for i in range(-2, 3): put(cx + i, eye_y, 0xe8e2d6)
		if not squint:
			for i in range(-1, 2): put(cx + i, eye_y - 1, 0xe8e2d6)
		put(cx, eye_y, iris)
		put(cx + 1, eye_y, iris)
		if not squint: put(cx, eye_y - 1, iris)
		put(cx, eye_y, 0x0e0a08)
		if not squint: put(cx + 1, eye_y - 1, 0xffffff)
		for i in range(-3, 4): put(cx + i, eye_y - (1 if squint else 2), OUT)
		put(cx - 3, eye_y, OUT)
		put(cx + 3, eye_y, SK[1])
		for i in range(-2, 3): put(cx + i, eye_y + 1, SK[1])
		if female:
			put(cx - 4, eye_y - 2, OUT)
			put(cx + 4, eye_y - 2, OUT)

	# ------------------------------------------------ beard & stubble
	func _beard() -> void:
		if female: return
		var mw := _mw
		var beard_c := lerpc(hair_base, 0xa8a59e, grey * 0.8)
		var BR := pal([shade(beard_c, -0.35), shade(beard_c, -0.12), beard_c])
		match lk("beard"):
			1:
				for y in range(nose_y + 2, chin_y + 1):
					var hw := hw_at(y)
					for x in range(CX - hw, CX + hw):
						if absi(x - CX) < mw + 1 and absi(y - mouth_y) <= 1: continue
						if (x * 3 + y * 7) % 4 == 0:
							var cur := at(x, y)
							put(x, y, shade(skin if cur < 0 else cur, -0.3))
			2: # goatee + moustache
				for i in range(-mw, mw + 1): put(CX + i, mouth_y - 2, BR[1])
				for y in range(mouth_y + 2, chin_y + 1):
					var hw := hw_at(y)
					var half := maxi(1, 4 - int(floor((y - mouth_y - 2) / 2.0)))
					for x in range(CX - hw, CX + hw):
						if absf(x - CX + 0.5) <= half: put(x, y, ramp(BR, 0.55 - (x - CX) / 10.0 + (0.2 if (x + y) % 3 == 0 else 0.0), x, y))
				for y in range(mouth_y, mouth_y + 2):
					put(CX - mw - 1, y, BR[1])
					put(CX + mw, y, BR[1])
			3: # full beard
				for y in range(eye_y + 4, chin_y + 1):
					var hw := hw_at(y)
					for x in range(CX - hw, CX + hw):
						var rel := float(x - CX) / hw
						if not (absf(rel) > 0.62 or y > mouth_y - 3): continue
						if absi(x - CX) <= mw and absi(y - mouth_y) <= 1: continue
						put(x, y, ramp(BR, 0.55 - rel * 0.25 + (0.25 if (x * 5 + y * 3) % 4 == 0 else 0.0), x, y))
				for i in range(-mw - 1, mw + 2): put(CX + i, mouth_y - 2, BR[1])
				for y in range(chin_y + 1, chin_y + 4):
					for x in range(CX - 6 + (y - chin_y), CX + 6 - (y - chin_y)): put(x, y, BR[(x + y) % 2])
			6: # a beard to the belt
				for y in range(eye_y + 3, chin_y + 1):
					var hw := hw_at(y)
					for x in range(CX - hw, CX + hw):
						var rel := float(x - CX) / hw
						if not (absf(rel) > 0.55 or y > mouth_y - 3): continue
						if absi(x - CX) <= mw and absi(y - mouth_y) <= 1: continue
						put(x, y, ramp(BR, 0.6 - rel * 0.25 + (0.25 if (x * 5 + y * 3) % 4 == 0 else 0.0), x, y))
				for i in range(-mw - 1, mw + 2): put(CX + i, mouth_y - 2, BR[2])
				for y in range(chin_y + 1, P):
					var hw := maxi(2, Face.jround(hw_at(chin_y) - (y - chin_y) * 0.35))
					for x in range(CX - hw, CX + hw):
						put(x, y, ramp(BR, 0.55 - (x - CX) / 14.0 + (0.22 if (x * 3 + y) % 4 == 0 else 0.0) + (-0.1 if y % 5 == 0 else 0.0), x, y))
					put(CX - hw - 1, y, shade(BR[0], -0.3))
					put(CX + hw, y, shade(BR[0], -0.3))
			5: # young guy's fuzz
				for i in range(-mw, mw + 1):
					if (i + 32) % 3 != 0: put(CX + i, mouth_y - 2, BR[1])
				for y in range(mouth_y + 2, mouth_y + 5):
					for x in range(CX - 1, CX + 1): put(x, y, BR[1] if (x + y) % 2 != 0 else BR[0])
			4: # moustache (handlebar if the seed says so)
				for i in range(-mw - 1, mw + 2):
					put(CX + i, mouth_y - 2, BR[2])
					put(CX + i, mouth_y - 1, BR[1])
				if rnd(4) % 2 != 0:
					put(CX - mw - 2, mouth_y, BR[1])
					put(CX + mw + 2, mouth_y, BR[1])
					put(CX - mw - 2, mouth_y + 1, BR[0])
					put(CX + mw + 2, mouth_y + 1, BR[0])

	# ------------------------------------------------ scars, face ink, freckles
	func _marks() -> void:
		var scar := lk("scar")
		if scar >= 1:
			for i in 3: put(eye_r + 2 + i, brow_y - 1 + i, SK[5])
		if scar >= 2:
			for i in 4: put(eye_l - 1, brow_y - 2 + i, lerpc(SK[4], 0xc98a7a, 0.5))
		if scar >= 3:
			for i in 7: put(eye_l - 4 + i, eye_y + 4 + int(floor(i / 2.0)), lerpc(SK[3], 0xb07a6c, 0.6))
		if lk("tattoo") == 3:
			put(eye_r + 3, eye_y + 3, shade(skin, -0.65))
			put(eye_r + 3, eye_y + 4, shade(skin, -0.65))
			put(eye_r + 2, eye_y + 4, shade(skin, -0.5))
		if lk("freckles") != 0:
			for i in 10: put(CX - 9 + (rnd(i + 90) % 18), nose_y - 3 + (rnd(i + 110) % 3), shade(skin, -0.1))
		elif lk("skin") <= 1 and rnd(12) % 3 == 0:
			for i in 8: put(CX - 8 + (rnd(i + 70) % 16), nose_y - 2 + (rnd(i + 80) % 3), shade(skin, -0.2))

	# ------------------------------------------------ accessories
	func _accessories() -> void:
		if lk("glasses") == 1:
			for cx in [eye_l, eye_r]:
				var c0: int = cx
				for y in range(eye_y - 2, eye_y + 3):
					for x in range(c0 - 4, c0 + 4):
						put(x, y, 0x050505 if y == eye_y - 2 else (0x3a3a4a if (x + y) % 5 == 0 else 0x101014))
			hline(eye_l + 4, eye_r - 5, eye_y - 1, 0x050505)
			put(eye_l - 2, eye_y - 1, 0x5a5a6a)
			put(eye_r - 2, eye_y - 1, 0x5a5a6a)
		elif lk("glasses") == 2:
			for cx in [eye_l, eye_r]:
				var c0: int = cx
				hline(c0 - 4, c0 + 3, eye_y - 3, 0x1a1a1a)
				hline(c0 - 4, c0 + 3, eye_y + 2, 0x1a1a1a)
				for y in range(eye_y - 3, eye_y + 3):
					put(c0 - 4, y, 0x1a1a1a)
					put(c0 + 3, y, 0x1a1a1a)
			hline(eye_l + 4, eye_r - 5, eye_y - 2, 0x1a1a1a)
		if lk("chain") != 0:
			for i in range(-10, 11): put(CX + i, shoulder_y + 2 + Face.jround(i * i / 16.0), 0xe8c868 if i % 2 != 0 else 0xa8862a)
		if female and rnd(23) % 3 == 0:
			var ear_top := eye_y - 3
			put(CX - hw_at(ear_top + 6) - 2, ear_top + 8, 0xe8e0c0)
			put(CX + hw_at(ear_top + 6) + 1, ear_top + 8, 0xe8e0c0)
