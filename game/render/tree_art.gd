## Trees from above, painted pixel by pixel: spruce as stacked whorls of needled branches,
## maples as lumpy clumps of leaves, birches airy enough to see the white trunk through.
## Lit from the upper left like everything else, shadows to the lower right, seasons
## (fall reds and golds, bare winter branches, snow on the boughs). Cached per look and size.
class_name TreeArt
extends RefCounted

static var _cache := {}

## kind: spruce, maple, birch. r: canopy radius in screen px. variant: any int (seed).
static func texture(kind: String, season: String, snow: bool, variant: int, r: int) -> ImageTexture:
	r = clampi((r / 4) * 4, 12, 64)
	var v := variant % 6
	var key := "%s|%s|%d|%d|%d" % [kind, season, int(snow), v, r]
	if _cache.has(key): return _cache[key]
	var size := r * 2 + int(r * 0.7) + 4
	var p := Pix.new(size, size, v * 977 + r)
	var c := Vector2i(r + 2, r + 2)            # the trunk; the shadow falls to the lower right
	match kind:
		"spruce": _spruce(p, c, r, snow, v, SPRUCE, 9, 4, 1.6)
		"fir": _spruce(p, c, r, snow, v, FIR, 13, 5, 0.9)
		"tamarack":
			if season == "winter": _bare(p, c, r, Color("6a6058"), snow, v, false)
			else: _spruce(p, c, r, snow, v, TAMARACK_FALL if season == "fall" else TAMARACK, 11, 3, 1.2)
		"pine": _tufts(p, c, r, snow, v, PINE, 6, 0.42)
		"cedar": _tufts(p, c, r, snow, v, CEDAR, 5, 0.5)
		"snag": _bare(p, c, r, Color("8a8478"), snow, v, true)
		"birch": _deciduous(p, c, r, season, snow, v, "birch")
		"aspen": _deciduous(p, c, r, season, snow, v, "aspen")
		"oak": _deciduous(p, c, r, season, snow, v, "oak")
		_: _deciduous(p, c, r, season, snow, v, "maple")
	var t := ImageTexture.create_from_image(p.img)
	_cache[key] = t
	return t

## Where the trunk sits inside the texture (to place it).
static func origin(r: int) -> Vector2:
	r = clampi((r / 4) * 4, 12, 64)
	return Vector2(r + 2, r + 2)

static func _shadow(p: Pix, c: Vector2i, r: int, jag: float, v: int) -> void:
	var off := Vector2(r * 0.42, r * 0.32)
	for y in p.h:
		for x in p.w:
			var d := Vector2(x, y) - (Vector2(c) + off)
			var ang := d.angle()
			var rr := r * (0.92 + jag * sin(ang * 7.0 + v))
			if d.length() < rr:
				var soft := clampf((rr - d.length()) / 3.0, 0.0, 1.0)
				p.img.set_pixel(x, y, Color(0.02, 0.03, 0.02, 0.26 * soft))

## Cheap per-pixel noise (0..1) without visible patterns.
static func _n(x: int, y: int, salt := 0) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 2147483) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float((h ^ (h >> 16)) & 1023) / 1023.0

## Light from the upper left: how lit a point on a dome of radius r is.
static func _light(d: Vector2, r: float) -> float:
	var nz := sqrt(maxf(0.0, 1.0 - d.length_squared() / (r * r)))
	var n := Vector3(d.x / r, d.y / r, nz)
	return clampf(n.dot(Vector3(-0.55, -0.55, 0.63).normalized()), 0.0, 1.0)

# ------------------------------------------------------------------ conifers

const SPRUCE := [Color("0e2216"), Color("163020"), Color("1e3e28"), Color("2a5034"), Color("3a6844")]
const FIR := [Color("08180e"), Color("0e2416"), Color("16321e"), Color("204428"), Color("2e5a36")]
const TAMARACK := [Color("2a4a1e"), Color("3a6228"), Color("4e7a32"), Color("68943e"), Color("88b050")]
const TAMARACK_FALL := [Color("6a4a10"), Color("9a7018"), Color("c8961e"), Color("e0b830"), Color("f0d860")]
const PINE := [Color("142a24"), Color("1e3c32"), Color("2a5040"), Color("3a6a52"), Color("5a8a6a")]
const CEDAR := [Color("1e3214"), Color("2c461c"), Color("3e5e24"), Color("56782e"), Color("7a9a3e")]

static func _spruce(p: Pix, c: Vector2i, r: int, snow: bool, v: int, ramp: Array, base_spokes: int, whorls: int, sharp: float) -> void:
	_shadow(p, c, r, 0.12, v)
	for w in whorls:
		var wr := float(r) * (1.0 - float(w) * (0.88 / float(whorls)))
		var spokes := base_spokes + w
		var rot := float(v) * 0.7 + float(w) * 0.9
		for y in range(c.y - int(wr) - 1, c.y + int(wr) + 2):
			for x in range(c.x - int(wr) - 1, c.x + int(wr) + 2):
				var d := Vector2(x - c.x, y - c.y)
				var ang := d.angle() + rot
				# branch tips: a star with soft points, needles fringing the edge
				var f := fposmod(ang * float(spokes) / TAU, 1.0)
				var tip := 1.0 - absf(f * 2.0 - 1.0)                  # 0 between branches, 1 at a tip
				var edge := wr * (0.5 + 0.5 * pow(tip, sharp)) * (0.92 + 0.16 * _n(int(ang * 40.0), w, v))
				var dl := d.length()
				if dl > edge: continue
				var lit := _light(d, wr + 1.0)
				# the branch's own ridge catches light, the gaps between branches are dark
				var ridge := pow(tip, 2.0) * 0.25
				var tone := lit * 0.85 + ridge + 0.08 * float(w)
				if dl > edge - 1.5 and _n(x, y, w) < 0.5: tone -= 0.3        # needle fringe
				if tip < 0.25: tone -= 0.25                                # dark gaps between branches
				tone += (_n(x, y, 7 + w) - 0.5) * 0.35                    # needle texture
				var k := clampi(int(tone * 4.0 + 0.5), 0, 4)
				var col: Color = ramp[k]
				if snow and lit > 0.5 and tip > 0.35 and _n(x, y, 3) < 0.75:
					col = Color("e8eef4") if lit > 0.75 else Color("b8c6d4")
				p.img.set_pixel(x, y, col)
	# the leader at the top
	p.px(c.x, c.y, ramp[4].lightened(0.15) if not snow else Color("f4f8fc"))
	p.px(c.x - 1, c.y - 1, ramp[4])

## White pine and cedar: soft tufts of needles rather than a star.
static func _tufts(p: Pix, c: Vector2i, r: int, snow: bool, v: int, ramp: Array, n: int, spread: float) -> void:
	_shadow(p, c, r, 0.2, v)
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 131 + r
	var tufts: Array = []
	for k in n:
		var a := TAU * float(k) / float(n) + rng.randf() * 0.6
		tufts.append([Vector2(c) + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.3, spread + 0.15), r * rng.randf_range(0.34, 0.48)])
	tufts.append([Vector2(c), r * 0.42])
	tufts.sort_custom(func(a, b): return (a[0].x + a[0].y) > (b[0].x + b[0].y))
	for tf in tufts:
		var cc: Vector2 = tf[0]
		var cr: float = tf[1]
		for y in range(int(cc.y - cr) - 1, int(cc.y + cr) + 2):
			for x in range(int(cc.x - cr) - 1, int(cc.x + cr) + 2):
				var d := Vector2(x, y) - cc
				# needle bundles: a spiky edge
				var edge := cr * (0.78 + 0.22 * _n(int(d.angle() * 30.0), int(cr), v))
				if d.length() > edge: continue
				var tone := _light(d, cr + 1.0) * 0.6 + _light(Vector2(x, y) - Vector2(c), float(r) + 2.0) * 0.4
				tone += (_n(x, y, 13) - 0.5) * 0.45
				var k := clampi(int(tone * 4.0 + 0.4), 0, 4)
				var col: Color = ramp[k]
				if snow and k >= 3 and _n(x, y, 4) < 0.7: col = Color("e8eef4")
				p.img.set_pixel(x, y, col)

## A dead tree, or a tamarack in winter: grey limbs, nothing else.
static func _bare(p: Pix, c: Vector2i, r: int, bark: Color, snow: bool, v: int, dead: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 71 + r
	var limbs := 5 if dead else 9
	for k in limbs:
		var a := TAU * float(k) / float(limbs) + rng.randf() * 0.5
		_limb(p, Vector2(c), a, r * rng.randf_range(0.4, 0.8) * (0.7 if dead else 1.0), 2 if dead else 3, bark, snow, rng)
	p.disc(c.x, c.y, 2.0, bark.darkened(0.25))

# ------------------------------------------------------------------ maple / birch / aspen / oak

static func _leaf_ramp(season: String, birch: bool, v: int, kind := "") -> Array:
	if kind == "oak":
		match season:
			"fall": return [Color("3a2010"), Color("5a3216"), Color("7a4a20"), Color("9a6a2e"), Color("b8884a")]
			"spring": return [Color("2a3e18"), Color("3e5a22"), Color("587a2e"), Color("74963c"), Color("94b452")]
		return [Color("142410"), Color("1e3616"), Color("2a4a1e"), Color("3a6028"), Color("4e7834")]
	if kind == "aspen":
		match season:
			"fall": return [Color("7a6418"), Color("a8881e"), Color("d8b428"), Color("f0d040"), Color("fff080")]
			"spring": return [Color("3a5a24"), Color("527a30"), Color("6e9a3c"), Color("8eb84c"), Color("b0d468")]
		return [Color("2e4a22"), Color("44682c"), Color("5e8838"), Color("7ca448"), Color("a0c060")]
	match season:
		"fall":
			if birch: return [Color("6a5418"), Color("9a7a1e"), Color("c8a02a"), Color("e0c040"), Color("f0dc70")]
			match v % 3:
				0: return [Color("5a1a10"), Color("8a2a16"), Color("b83a1e"), Color("d8562a"), Color("ec8a40")]
				1: return [Color("6a3410"), Color("9a5214"), Color("c8781e"), Color("e09a2a"), Color("f0c050")]
				_: return [Color("5a2a10"), Color("8a4012"), Color("c8501e"), Color("e0a028"), Color("e8c84a")]
		"spring":
			return [Color("2a4a1e"), Color("3e6a28"), Color("5a8a36"), Color("7aaa48"), Color("a0c860")]
	if birch: return [Color("2a4a1e"), Color("3e6428"), Color("5a8638"), Color("7aa64a"), Color("9ac060")]
	return [Color("162e14"), Color("22421c"), Color("2e5a26"), Color("427434"), Color("5a8c44")]

static func _deciduous(p: Pix, c: Vector2i, r: int, season: String, snow: bool, v: int, kind: String) -> void:
	var birch := kind == "birch"
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 31 + r * 7 + kind.hash() % 97
	var bark := Color("e8e4dc") if birch else (Color("b8b4a0") if kind == "aspen" else Color("4a3a2c"))
	var bare := season == "winter"
	if bare:
		# the shadow of bare branches is just more branches, faint, off to the lower right
		var seed0 := rng.seed
		_branches(p, c + Vector2i(int(r * 0.35), int(r * 0.26)), r, Color(0.02, 0.03, 0.02, 0.22), false, rng, birch)
		rng.seed = seed0
		_branches(p, c, r, bark, snow, rng, birch)
		return
	_shadow(p, c, r, 0.18, v)
	var ramp := _leaf_ramp(season, birch, v, kind)
	# clumps of leaves around the crown: oaks broad and lumpy, aspens small and many
	var clumps: Array = []
	var n: int = { "birch": 9, "aspen": 11, "oak": 6 }.get(kind, 7)
	var csz: float = { "birch": 0.85, "aspen": 0.7, "oak": 1.12 }.get(kind, 1.0)
	for k in n:
		var a := TAU * float(k) / float(n) + rng.randf() * 0.5
		var dist := r * rng.randf_range(0.28, 0.55)
		var cr := r * rng.randf_range(0.36, 0.5) * csz
		clumps.append([Vector2(c) + Vector2(cos(a), sin(a)) * dist, cr])
	clumps.append([Vector2(c) + Vector2(-r * 0.08, -r * 0.08), r * 0.5])
	# paint back to front: lower-right clumps first so the lit ones overlap them
	clumps.sort_custom(func(a, b): return (a[0].x + a[0].y) > (b[0].x + b[0].y))
	for cl in clumps:
		var cc: Vector2 = cl[0]
		var cr: float = cl[1]
		for y in range(int(cc.y - cr) - 1, int(cc.y + cr) + 2):
			for x in range(int(cc.x - cr) - 1, int(cc.x + cr) + 2):
				var d := Vector2(x, y) - cc
				var ang := d.angle()
				var edge := cr * (0.86 + 0.14 * sin(ang * 5.0 + cr) + 0.06 * sin(ang * 13.0))
				if d.length() > edge: continue
				if (birch or kind == "aspen") and _n(x, y, 11) < 0.1: continue                  # airy: gaps you see through
				var lit := _light(d, cr + 1.0)
				# the whole crown is lit from the upper left too
				var crown := _light(Vector2(x, y) - Vector2(c), float(r) + 2.0)
				var tone := lit * 0.55 + crown * 0.45
				var k := clampi(int(tone * 4.0 + 0.4), 0, 4)
				if d.length() > edge - 1.2: k = maxi(0, k - 1)             # each clump's rim sits in its own shade
				var nn := _n(x, y, 5)
				if nn > 0.86: k = clampi(k + 1, 0, 4)                         # leaves catching light
				elif nn < 0.14: k = clampi(k - 1, 0, 4)
				var col: Color = ramp[k]
				if season == "fall" and kind == "maple" and _n(x, y, 9) < 0.07:
					col = _leaf_ramp("fall", false, v + 1)[k]                # a few leaves turning a different colour
				if snow and k >= 3 and _n(x, y, 4) < 0.6: col = Color("e8eef4")
				p.img.set_pixel(x, y, col)
	if birch:
		# the white trunk and a couple of limbs show through the gaps
		p.rect(c.x - 1, c.y - 1, 3, 3, bark)
		p.px(c.x + 1, c.y + 1, Color("2a2420"))

## Winter: the crown is just branches, forking out from the trunk.
static func _branches(p: Pix, c: Vector2i, r: int, bark: Color, snow: bool, rng: RandomNumberGenerator, birch: bool) -> void:
	# the fine twigs at the ends read as a haze from above
	for y in range(c.y - r, c.y + r):
		for x in range(c.x - r, c.x + r):
			var d := Vector2(x - c.x, y - c.y).length() / float(r)
			if d < 0.95 and d > 0.25 and _n(x, y, 21) < 0.16 * (1.0 - d * 0.6):
				p.px(x, y, Color(bark.darkened(0.25), 0.7))
	var limbs := 6 if not birch else 8
	for k in limbs:
		var a := TAU * float(k) / float(limbs) + rng.randf() * 0.4
		_limb(p, Vector2(c), a, r * rng.randf_range(0.55, 0.95), 3, bark, snow, rng)
	p.disc(c.x, c.y, 2.0, bark.darkened(0.2))
	p.px(c.x - 1, c.y - 1, bark.lightened(0.2))

static func _limb(p: Pix, from: Vector2, a: float, len: float, depth: int, bark: Color, snow: bool, rng: RandomNumberGenerator) -> void:
	var to := from + Vector2(cos(a), sin(a)) * len
	var col := bark.darkened(0.15 * float(3 - depth))
	p.line(int(from.x), int(from.y), int(to.x), int(to.y), col)
	if depth == 3: p.line(int(from.x) + 1, int(from.y), int(to.x) + 1, int(to.y), col.darkened(0.2))
	if snow and depth < 3:
		var mid := (from + to) * 0.5
		p.px(int(mid.x), int(mid.y) - 1, Color("e8eef4"))
	if depth <= 0 or len < 4.0: return
	for s in [-1.0, 1.0]:
		_limb(p, to, a + s * rng.randf_range(0.35, 0.7), len * rng.randf_range(0.45, 0.6), depth - 1, bark, snow, rng)
