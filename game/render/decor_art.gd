## Everything low that isn't a tree, from above: shrubs and alder, granite boulders with lichen,
## stumps, fallen logs, roadside lupines, wildflowers and goldenrod, ferns, tall grass, cattails
## in the wet spots, round hay bales, and blueberry barrens that go crimson in the fall.
## Every kind changes with the season. Lit from the upper left, cached per look.
class_name DecorArt
extends RefCounted

const KINDS := ["shrub", "alder", "boulder", "stump", "log", "lupine", "flowers", "fern", "grass", "cattail", "bale", "blueberry", "rocks"]

static var _cache := {}

## r: rough radius in screen px. variant: any int.
static func texture(kind: String, season: String, snow: bool, variant: int, r: int) -> ImageTexture:
	r = clampi((r / 3) * 3, 6, 48)
	var v := variant % 5
	var key := "%s|%s|%d|%d|%d" % [kind, season, int(snow), v, r]
	if _cache.has(key): return _cache[key]
	var size := r * 2 + r / 2 + 6
	var p := Pix.new(size, size, v * 389 + r)
	var c := Vector2i(r + 3, r + 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 7919 + r * 31 + kind.hash() % 1000
	match kind:
		"shrub": _shrub(p, c, r, season, snow, rng, false)
		"alder": _shrub(p, c, r, season, snow, rng, true)
		"boulder": _boulder(p, c, r, snow, rng)
		"rocks":
			for k in 4:
				var o := Vector2i(rng.randi_range(-r / 2, r / 2), rng.randi_range(-r / 2, r / 2))
				_boulder(p, c + o, maxi(3, r / 3 + rng.randi_range(-1, 2)), snow, rng)
		"stump": _stump(p, c, r, snow)
		"log": _log(p, c, r, snow, rng)
		"lupine": _spikes(p, c, r, season, snow, rng)
		"flowers": _flowers(p, c, r, season, snow, rng)
		"fern": _fern(p, c, r, season, snow, rng)
		"grass": _grass(p, c, r, season, snow, rng)
		"cattail": _cattail(p, c, r, season, snow, rng)
		"bale": _bale(p, c, r, snow, v)
		"blueberry": _blueberry(p, c, r, season, snow, rng)
	var t := ImageTexture.create_from_image(p.img)
	_cache[key] = t
	return t

static func origin(r: int) -> Vector2:
	r = clampi((r / 3) * 3, 6, 48)
	return Vector2(r + 3, r + 3)

static func _shade(p: Pix, cc: Vector2, cr: float, off: float, alpha: float) -> void:
	var sc := cc + Vector2(off, off * 0.75)
	for y in range(int(sc.y - cr) - 1, int(sc.y + cr) + 2):
		for x in range(int(sc.x - cr) - 1, int(sc.x + cr) + 2):
			var d := Vector2(x, y) - sc
			if d.length() < cr and p.get_px(x, y).a < alpha:
				var soft := clampf((cr - d.length()) / 2.0, 0.0, 1.0)
				p.px(x, y, Color(0.02, 0.03, 0.02, alpha * soft))

## A lumpy dome of leaves (or bare twigs in winter).
static func _shrub(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator, alder: bool) -> void:
	var ramp: Array
	match season:
		"fall":
			# sumac and wild rose go red; alder just goes brown
			ramp = [Color("4a2a12"), Color("6a3c18"), Color("8a5420"), Color("a8702a"), Color("c08a3a")] if alder else ([Color("5a1010"), Color("8a1a14"), Color("b82a1e"), Color("d8462a"), Color("ec6a3a")] if rng.randf() < 0.6 else [Color("5a3a10"), Color("8a5a14"), Color("b8801e"), Color("d8a02a"), Color("ecc04a")])
		"spring": ramp = [Color("2a4418"), Color("3c5e22"), Color("54802e"), Color("72a03c"), Color("98c050")]
		"winter": ramp = []
		_: ramp = [Color("16280e"), Color("203a16"), Color("2e501e"), Color("406a28"), Color("588434")] if not alder else [Color("1a2e14"), Color("26421c"), Color("365a26"), Color("4a7432"), Color("62903e")]
	var n := 3 if not alder else 5
	var blobs: Array = []
	for k in n:
		var a := rng.randf() * TAU
		blobs.append([Vector2(c) + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.0, 0.45), r * rng.randf_range(0.45, 0.65)])
	for b in blobs: _shade(p, b[0], b[1], r * 0.3, 0.22)
	if ramp.is_empty():
		var tw := Color("5a4636")
		for b in blobs:
			for k in 7:
				var a := rng.randf() * TAU
				var cc: Vector2 = b[0]
				p.line(int(cc.x), int(cc.y), int(cc.x + cos(a) * b[1]), int(cc.y + sin(a) * b[1]), tw)
		if snow:
			for b in blobs: p.disc(int(b[0].x) - 1, int(b[0].y) - 1, b[1] * 0.4, Color("e8eef4"))
		return
	for b in blobs:
		var cc: Vector2 = b[0]
		var cr: float = b[1]
		for y in range(int(cc.y - cr) - 1, int(cc.y + cr) + 2):
			for x in range(int(cc.x - cr) - 1, int(cc.x + cr) + 2):
				var d := Vector2(x, y) - cc
				if d.length() > cr * (0.82 + 0.18 * TreeArt._n(int(d.angle() * 20.0), int(cr), 3)): continue
				var tone := TreeArt._light(d, cr + 1.0) + (TreeArt._n(x, y, 17) - 0.5) * 0.5
				var col: Color = ramp[clampi(int(tone * 4.0 + 0.4), 0, 4)]
				if snow and tone > 0.6: col = Color("e8eef4")
				p.img.set_pixel(x, y, col)
	if season == "summer" and not alder and rng.randf() < 0.4:
		for k in 6: p.px(c.x + rng.randi_range(-r / 2, r / 2), c.y + rng.randi_range(-r / 2, r / 2), Color("f0a0b8"))   # wild roses

## Granite: grey, a lit top-left face, a dark underside, orange-and-green lichen.
static func _boulder(p: Pix, c: Vector2i, r: int, snow: bool, rng: RandomNumberGenerator) -> void:
	var rr := float(r) * 0.8
	_shade(p, Vector2(c), rr, rr * 0.35, 0.3)
	var base := [Color("4a4a4e"), Color("62626a"), Color("7a7a80"), Color("929298"), Color("aaaab0")]
	var facets := rng.randi_range(5, 7)
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			var d := Vector2(x - c.x, y - c.y)
			var a := d.angle()
			# a rough polygon outline
			var f := fposmod(a * float(facets) / TAU, 1.0)
			var edge := rr * (0.82 + 0.12 * absf(f - 0.5) * 2.0)
			if d.length() > edge: continue
			var lit := TreeArt._light(d, edge + 1.0)
			# flat faces: quantise the light so it reads as chipped stone
			var tone: float = floor(lit * 3.0) / 3.0 + (TreeArt._n(x, y, 29) - 0.5) * 0.2
			var col: Color = base[clampi(int(tone * 4.0 + 0.5), 0, 4)]
			var ln := TreeArt._n(x, y, 31)
			if ln < 0.06: col = Color("c8a040")
			elif ln < 0.1: col = Color("7a8a5a")
			if snow and lit > 0.55: col = Color("e8eef4")
			p.img.set_pixel(x, y, col)

static func _stump(p: Pix, c: Vector2i, r: int, snow: bool) -> void:
	var rr := float(r) * 0.55
	_shade(p, Vector2(c), rr, rr * 0.4, 0.3)
	p.disc(c.x, c.y, rr, Color("3a2c20"))
	p.disc(c.x, c.y, rr - 1.5, Color("b89a6a") if not snow else Color("e8eef4"))
	if not snow:
		for k in range(2, int(rr), 2): p.ring(c.x, c.y, float(k), Color("9a7a4a"))
		p.line(c.x, c.y, c.x + int(rr * 0.7), c.y + int(rr * 0.4), Color("6a4a2a"))      # a crack

static func _log(p: Pix, c: Vector2i, r: int, snow: bool, rng: RandomNumberGenerator) -> void:
	var a := rng.randf() * PI
	var dir := Vector2(cos(a), sin(a))
	var half := float(r) * 0.95
	var th := maxf(2.5, float(r) * 0.22)
	for k in range(-int(half), int(half) + 1):
		var q := Vector2(c) + dir * float(k)
		for s in range(-int(th), int(th) + 1):
			var pt := q + dir.orthogonal() * float(s)
			var f := float(s) / th
			var col := Color("4a3626").lerp(Color("2a1e14"), clampf((f + 1.0) / 2.0, 0.0, 1.0))
			if f < -0.4: col = Color("6a5038")
			if TreeArt._n(int(pt.x), int(pt.y), 41) < 0.12: col = Color("4a6a2a")      # moss
			if snow and f < -0.2: col = Color("e8eef4")
			p.px(int(pt.x), int(pt.y), col)
	var end := Vector2(c) + dir * half
	p.disc(int(end.x), int(end.y), th, Color("a88a5a"))
	p.ring(int(end.x), int(end.y), th * 0.5, Color("8a6a40"))

## Lupines: the purple, pink and white spikes along every back road in June.
static func _spikes(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	if season == "winter":
		if not snow:
			for k in 6: p.px(c.x + rng.randi_range(-r, r), c.y + rng.randi_range(-r, r), Color("6a5a40"))
		return
	var cols := [Color("7a4ac8"), Color("9a5ad8"), Color("d870b0"), Color("f0e8f0"), Color("5a3aa8")]
	for k in int(r * 1.4):
		var q := Vector2i(c.x + rng.randi_range(-r, r), c.y + rng.randi_range(-r, r))
		if Vector2(q - c).length() > r: continue
		p.disc(q.x, q.y, 1.5, Color("2e5a22"))                                # palmate leaves
		if season == "fall":
			p.vline(q.x, q.y - 3, 3, Color("7a6a3a"))                        # seed pods
			continue
		var col: Color = cols[rng.randi() % cols.size()]
		for j in 4:
			p.px(q.x, q.y - 1 - j, col.lightened(0.15 * float(j % 2)))
		p.px(q.x + 1, q.y - 2, col.darkened(0.2))

static func _flowers(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	if season == "winter": return
	for k in int(r * 2):
		var q := Vector2i(c.x + rng.randi_range(-r, r), c.y + rng.randi_range(-r, r))
		if Vector2(q - c).length() > r: continue
		p.px(q.x, q.y + 1, Color("3a6a28"))
		match season:
			"fall": p.px(q.x, q.y, Color("e8c030") if rng.randf() < 0.7 else Color("a88ac8"))     # goldenrod and asters
			"spring": p.px(q.x, q.y, Color("f0e040") if rng.randf() < 0.6 else Color("f0f0e8"))   # dandelions
			_:
				var col: Color = [Color("f4f0e4"), Color("f0d030"), Color("e8a0c0"), Color("f08030")][rng.randi() % 4]
				p.px(q.x, q.y, col)
				if col == Color("f4f0e4"):                                              # daisies have eyes
					p.px(q.x + 1, q.y, col)
					p.px(q.x, q.y - 1, Color("f0c020"))

static func _fern(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	if season == "winter":
		if not snow: _grass(p, c, r / 2, "fall", false, rng)
		return
	var col := Color("3a7a2e") if season != "fall" else Color("b8702a")
	if season == "spring": col = Color("6aa83e")
	var fronds := rng.randi_range(5, 8)
	for k in fronds:
		var a := TAU * float(k) / float(fronds) + rng.randf() * 0.4
		var len := float(r) * rng.randf_range(0.7, 1.0)
		for j in int(len):
			var q := Vector2(c) + Vector2(cos(a), sin(a)) * float(j)
			var tone := col.lightened(0.15) if j % 2 == 0 else col
			p.px(int(q.x), int(q.y), tone.darkened(0.2))
			var side := Vector2(cos(a), sin(a)).orthogonal() * maxf(1.0, (len - float(j)) * 0.25)
			p.px(int(q.x + side.x), int(q.y + side.y), tone)
			p.px(int(q.x - side.x), int(q.y - side.y), tone.darkened(0.1))

static func _grass(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	var col: Color = { "summer": Color("6a8a3a"), "spring": Color("7aa84a"), "fall": Color("a89a5a"), "winter": Color("8a7a5a") }.get(season, Color("6a8a3a"))
	for k in int(r * 2.5):
		var a := rng.randf() * TAU
		var d := rng.randf() * float(r)
		var q := Vector2(c) + Vector2(cos(a), sin(a)) * d
		var tip := q + Vector2(cos(a), sin(a)) * rng.randf_range(2.0, 4.0) + Vector2(-1, -1)
		var cc: Color = col.lightened(rng.randf() * 0.2) if rng.randf() < 0.5 else col.darkened(rng.randf() * 0.25)
		p.line(int(q.x), int(q.y), int(tip.x), int(tip.y), cc)
	if snow: p.disc(c.x, c.y, r * 0.4, Color("e8eef4"))

static func _cattail(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	var leaf := Color("5a7a3a") if season in ["summer", "spring"] else Color("a8945a")
	for k in int(r * 1.6):
		var q := Vector2i(c.x + rng.randi_range(-r, r), c.y + rng.randi_range(-r / 2, r / 2))
		p.line(q.x, q.y, q.x + rng.randi_range(-2, 2), q.y - rng.randi_range(4, 7), leaf.darkened(rng.randf() * 0.3))
		if rng.randf() < 0.3:
			p.rect(q.x, q.y - 9, 2, 4, Color("5a3a1e") if season != "winter" else Color("8a7a6a"))   # the brown heads
			if snow: p.px(q.x, q.y - 10, Color("e8eef4"))

## Round bales, wrapped in white plastic or left as straw.
static func _bale(p: Pix, c: Vector2i, r: int, snow: bool, v: int) -> void:
	var rr := float(r) * 0.6
	_shade(p, Vector2(c), rr, rr * 0.5, 0.32)
	var wrapped := v % 2 == 0
	var base := Color("e8e8e4") if wrapped else Color("c8a85a")
	# lying on its side: a cylinder seen from above
	for y in range(int(c.y - rr), int(c.y + rr) + 1):
		for x in range(int(c.x - rr * 1.3), int(c.x + rr * 1.3) + 1):
			var dx := float(x - c.x) / (rr * 1.3)
			var dy := float(y - c.y) / rr
			if dx * dx * dx * dx + dy * dy > 1.0: continue
			var col := base.lightened(0.15) if dy < -0.3 else (base.darkened(0.2) if dy > 0.4 else base)
			if not wrapped and TreeArt._n(x, y, 51) < 0.25: col = col.darkened(0.12)
			if wrapped and absi(x - c.x) % 7 == 0: col = col.darkened(0.08)
			if snow and dy < 0.1: col = Color("f0f4f8")
			p.img.set_pixel(x, y, col)
	if not wrapped and not snow:
		p.ring(c.x + int(rr * 1.2), c.y, rr * 0.6, base.darkened(0.25))

## Lowbush blueberries: a low carpet, green in summer with blue berries, crimson in the fall.
static func _blueberry(p: Pix, c: Vector2i, r: int, season: String, snow: bool, rng: RandomNumberGenerator) -> void:
	if snow: return
	var ramp := [Color("2a4a24"), Color("3a5e2c"), Color("4e7436")]
	match season:
		"fall": ramp = [Color("6a1418"), Color("9a1e22"), Color("c03a2a")]
		"winter": ramp = [Color("4a2a24"), Color("5a3a2c"), Color("6a4a34")]
		"spring": ramp = [Color("3a5a2a"), Color("5a7a34"), Color("c8a8a8")]
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			var d := Vector2(x - c.x, y - c.y).length() / float(r)
			var n := TreeArt._n(x, y, 61)
			if d > 1.0 or n > 1.15 - d * 0.6: continue
			p.img.set_pixel(x, y, ramp[int(n * 2.99)])
	if season == "summer":
		for k in int(r): p.px(c.x + rng.randi_range(-r, r) / 2, c.y + rng.randi_range(-r, r) / 2, Color("3a4a9a"))
