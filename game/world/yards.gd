## The yards round the houses in one chunk of the map: a mowed lawn out front with a walk down to
## the street, flower beds along the front of the house, a mailbox at the end of the walk, and out
## back a fence round the yard with whatever's in it (an above-ground pool, a trampoline, a shed,
## a woodpile, a boat on its trailer under a tarp, a clothesline, a fire pit). The flat things lie
## on the ground; the fences, the posts and the shed stand up toward the top of the screen the way
## the buildings do, so it redraws when the camera turns or tips. Worked out from where each house
## stands, so a yard is the same every time you drive past.
class_name Yards
extends Node2D

const PX := CarArt.PX

var world: World
var yards: Array = []              # one Dictionary per house (see _yard)
var _near: Array = []              # the buildings round about (a yard doesn't run into the neighbour's house)
var _up := Vector2.ZERO
var _k := 0.0
var _season := ""

func _ready() -> void:
	z_index = -3997                # on the ground, over the soil and the decor, under the roads' marks and everything that stands up
	z_as_relative = false

## Lays out the yards for these houses (the map's building dicts); `near` is every building
## round about.
func setup(the_world: World, houses: Array, near: Array) -> void:
	world = the_world
	_near = near
	for b in houses:
		var y := _yard(b)
		if not y.is_empty(): yards.append(y)

func _process(_dt: float) -> void:
	var s := world.sky.season if world and world.sky else ""
	if CarView.screen_up != _up or CarView.lift_k != _k or s != _season:
		_up = CarView.screen_up
		_k = CarView.lift_k
		_season = s
		queue_redraw()

## Which way the house faces (toward the nearest road, snapped to the house's sides), and what's
## in its yard.
func _yard(b: Dictionary) -> Dictionary:
	var r: Rect2 = b.r
	var c := r.get_center()
	var rd: Dictionary = world.map.nearest_road(c, 40.0)
	if rd.is_empty(): return {}
	var to: Vector2 = rd.point - c
	var f := Vector2(signf(to.x), 0.0) if absf(to.x) > absf(to.y) else Vector2(0.0, signf(to.y))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.x * 31.0 + c.y * 17.0)
	# how far the front yard runs: to the sidewalk's back edge
	var front_d := clampf(absf(to.dot(f)) - float(rd.road.w) / 2.0 - 3.0 - (r.size.x if f.x != 0.0 else r.size.y) / 2.0, 0.0, 12.0)
	var y := { "r": r, "f": f, "front": front_d, "rng_seed": rng.randi() }
	# the back yard: as wide as the house and a bit, as deep as there's room for
	var side := Vector2(absf(f.y), absf(f.x))
	var half_w := (r.size.x if f.y != 0.0 else r.size.y) / 2.0 + 2.5
	var back_face := c - f * ((r.size.x if f.x != 0.0 else r.size.y) / 2.0)
	var depth := 0.0
	for d in [9.0, 7.0, 5.0]:
		var far: Vector2 = back_face - f * d
		if _clear(far + side * half_w) and _clear(far - side * half_w) and _clear(far) and _clear(back_face - f * d * 0.5 + side * half_w) and _clear(back_face - f * d * 0.5 - side * half_w):
			depth = d
			break
	y.back = depth
	y.half_w = half_w
	y.back_face = back_face
	y.side = side
	y.fence = ["wood", "chain", "picket", "wood", "none"][rng.randi() % 5] if depth > 0.0 else "none"
	var extras := ["pool", "trampoline", "shed", "woodpile", "boat", "clothesline", "firepit", "", ""]
	y.extra = extras[rng.randi() % extras.size()] if depth >= 7.0 else ""
	y.beds = rng.randf() < 0.75
	y.hedge = front_d > 3.0 and rng.randf() < 0.4
	y.shrubs = rng.randi_range(0, 3)
	y.mailbox = front_d > 2.0 and rng.randf() < 0.8
	y.flower = [Color("e04a6a"), Color("f0d040"), Color("9a5ad0"), Color("f08a30"), Color("f4f0e8")][rng.randi() % 5]
	return y

func _clear(p: Vector2) -> bool:
	if not world.map.road_at(p, 2.0).is_empty(): return false
	if world.map.ground_at(p) != "grass": return false
	for b in _near:
		if (b.r as Rect2).grow(1.0).has_point(p): return false
	return true

## A point on the ground (metres) lifted `z` px toward the top of the screen.
func _at(p: Vector2, z := 0.0) -> Vector2:
	return p * PX + CarView.screen_up * z * CarView.lift_k

func _draw() -> void:
	var s := _season
	var winter := s == "winter" or (world and world.sky.snow_cover > 0.3)
	for y in yards:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(y.rng_seed)
		var r: Rect2 = y.r
		var f: Vector2 = y.f
		var side: Vector2 = y.side
		var c := r.get_center()
		var front_face := c + f * ((r.size.x if f.x != 0.0 else r.size.y) / 2.0)
		var half_house := (r.size.x if f.y != 0.0 else r.size.y) / 2.0
		# the lawn, mowed in stripes (not under snow)
		var fd: float = y.front
		if fd > 1.0 and not winter:
			var n := int(half_house * 2.0 / 1.2)
			for i in n:
				if i % 2 == 1: continue
				var a := front_face + side * (-half_house + float(i) * 1.2)
				_ground_quad(a, a + side * 1.2, a + side * 1.2 + f * fd, a + f * fd, Color(1, 1, 0.8, 0.05))
		# the walk from the door to the street, and the step's landing
		if fd > 0.5:
			_ground_quad(front_face - side * 0.6, front_face + side * 0.6, front_face + side * 0.6 + f * fd, front_face - side * 0.6 + f * fd, Color("b8b4aa") if not winter else Color("d8dce2"))
		# flower beds along the front, either side of the walk
		if y.beds and not winter:
			for sgn: float in [-1.0, 1.0]:
				var a2 := front_face + side * sgn * 1.0
				var b2 := front_face + side * sgn * (half_house - 0.3)
				_ground_quad(a2, b2, b2 + f * 0.9, a2 + f * 0.9, Color("5a3e2a"))
				if s in ["spring", "summer", "fall"]:
					var L := a2.distance_to(b2)
					var d := (b2 - a2) / maxf(L, 0.01)
					var x := 0.3
					while x < L - 0.2:
						var q := a2 + d * x + f * rng.randf_range(0.2, 0.7)
						draw_rect(Rect2(_at(q) - Vector2(1, 1), Vector2(2, 2)), y.flower if s != "fall" else Color("d07a2a"))
						if rng.randf() < 0.5: draw_rect(Rect2(_at(q + d * 0.2 + f * 0.1) - Vector2(1, 1), Vector2(2, 2)), Color("3a7a2a"))
						x += 0.45
		# shrubs at the front corners of the house, and a cedar hedge down the lot line
		for i in int(y.shrubs):
			var sp := front_face + side * (half_house - 0.6) * (1.0 if i % 2 == 0 else -1.0) + f * (0.6 + float(i / 2) * 1.2)
			_bush(sp, rng.randf_range(0.6, 0.9), winter, Color("3a6a2e") if i % 3 != 2 else Color("4a7a3a"))
		if y.hedge:
			for sgn2: float in [-1.0, 1.0]:
				var h0 := front_face + side * sgn2 * (half_house + 2.0)
				var x2 := 0.4
				while x2 < fd - 0.4:
					_bush(h0 + f * x2, 0.55, winter, Color("2e5a2a"))
					x2 += 0.7
		# the mailbox at the end of the walk
		if y.mailbox:
			var mp := front_face + f * fd + side * 1.2
			_post(mp, 9.0, Color("4a3a2a"))
			var top := _at(mp, 9.0)
			draw_rect(Rect2(top - Vector2(3, 2), Vector2(6, 4)), Color("2a2a2e"))
			draw_rect(Rect2(top + Vector2(2, -4), Vector2(1, 3)), Color("c83a2a"))
		# out back
		var depth: float = y.back
		if depth <= 0.0: continue
		var bf: Vector2 = y.back_face
		var hw: float = y.half_w
		var far: Vector2 = bf - f * depth
		var corners := [bf + side * hw, far + side * hw, far - side * hw, bf - side * hw]
		_extra(String(y.extra), bf - f * depth * 0.55 + side * hw * 0.3, f, side, rng, winter)
		_fence(String(y.fence), corners, rng)

func _ground_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([_at(a), _at(b), _at(c), _at(d)]), PackedColorArray([col, col, col, col]), PackedVector2Array())

## A post standing up off the ground: z px tall (from straight overhead).
func _post(p: Vector2, z: float, col: Color, w := 1.5) -> void:
	draw_line(_at(p), _at(p, z), col, w)

## A fence along the back yard's three open sides (the house closes the fourth).
func _fence(style: String, c: Array, rng: RandomNumberGenerator) -> void:
	if style == "none": return
	var h := 7.0 if style == "wood" else (5.0 if style == "chain" else 4.0)
	var col: Color = { "wood": Color("8a6a48"), "chain": Color("9aa0a6"), "picket": Color("ece8e0") }[style]
	for i in 3:
		var a: Vector2 = c[i]
		var b: Vector2 = c[i + 1]
		var L := a.distance_to(b)
		if L < 0.5: continue
		var d := (b - a) / L
		if style == "wood":
			# a privacy fence: boards side by side, a shaded face, a top rail
			var face := Color(col, 1.0) * (0.85 + 0.15 * clampf(d.orthogonal().dot(-CarView.screen_up), -1.0, 1.0))
			face.a = 1.0
			draw_primitive(PackedVector2Array([_at(a), _at(b), _at(b, h), _at(a, h)]), PackedColorArray([face, face, face, face]), PackedVector2Array())
			var x := 0.0
			while x < L:
				draw_line(_at(a + d * x), _at(a + d * x, h), face.darkened(0.2), 1.0)
				x += 0.3
			draw_line(_at(a, h), _at(b, h), face.lightened(0.15), 1.0)
		elif style == "chain":
			draw_line(_at(a, h), _at(b, h), col, 1.0)
			draw_line(_at(a, 1.0), _at(b, 1.0), Color(col, 0.6), 1.0)
			var x2 := 0.0
			while x2 <= L:
				_post(a + d * x2, h, col.darkened(0.2), 1.0)
				x2 += 2.5
		else:
			var x3 := 0.0
			while x3 <= L:
				_post(a + d * x3, h if int(x3 / 0.25) % 2 == 0 else h - 1.0, col, 1.0)
				x3 += 0.25
			draw_line(_at(a, h * 0.6), _at(b, h * 0.6), col.darkened(0.1), 1.0)

## What's in the back yard.
func _extra(kind: String, p: Vector2, f: Vector2, side: Vector2, rng: RandomNumberGenerator, winter: bool) -> void:
	match kind:
		"pool":
			if winter:
				draw_circle(_at(p, 4.0), 1.8 * PX, Color("2a3a5a"))         # the winter cover
			else:
				draw_circle(_at(p), 1.9 * PX, Color(0, 0, 0, 0.25))
				draw_circle(_at(p, 4.0), 1.8 * PX, Color("c8ccd0"))
				draw_circle(_at(p, 4.0), 1.6 * PX, Color("3a9ad8"))
				draw_arc(_at(p, 4.0), 1.2 * PX, 3.6, 4.4, 8, Color(1, 1, 1, 0.5), 1.0)
		"trampoline":
			draw_circle(_at(p), 1.6 * PX, Color(0, 0, 0, 0.2))
			draw_circle(_at(p, 5.0), 1.5 * PX, Color("2a5ab8"))
			draw_circle(_at(p, 5.0), 1.2 * PX, Color("1a1a1e"))
		"shed":
			var w := 2.4
			var d := 2.0
			var col := Color("8a6a48") if rng.randf() < 0.5 else Color("6a7a6a")
			var c4 := [p - side * w / 2.0 - f * d / 2.0, p + side * w / 2.0 - f * d / 2.0, p + side * w / 2.0 + f * d / 2.0, p - side * w / 2.0 + f * d / 2.0]
			for i in 4:
				var a: Vector2 = c4[i]
				var b: Vector2 = c4[(i + 1) % 4]
				var nrm := (b - a).normalized().orthogonal()
				if nrm.dot(-CarView.screen_up) <= 0.05: continue
				var fc := col * (0.8 + 0.2 * clampf(nrm.dot(Vector2(-0.6, -0.8)), -1.0, 1.0))
				fc.a = 1.0
				draw_primitive(PackedVector2Array([_at(a), _at(b), _at(b, 14.0), _at(a, 14.0)]), PackedColorArray([fc, fc, fc, fc]), PackedVector2Array())
			draw_primitive(PackedVector2Array([_at(c4[0], 14.0), _at(c4[1], 14.0), _at(c4[2], 14.0), _at(c4[3], 14.0)]), PackedColorArray([Color("4a4a50"), Color("4a4a50"), Color("4a4a50"), Color("4a4a50")]), PackedVector2Array())
		"woodpile":
			for i in 3:
				var a := p + side * (float(i) * 0.4 - 0.6)
				draw_line(_at(a - f * 0.8, float(i) * 2.0), _at(a + f * 0.8, float(i) * 2.0 + 2.0), Color("7a5a3a"), 4.0)
			draw_line(_at(p - f * 0.8 - side * 0.8, 6.0), _at(p + f * 0.8 + side * 0.4, 6.0), Color("5a6a7a"), 3.0)   # a tarp
		"boat":
			# a fishing boat on its trailer under a blue tarp
			var bow := p + side * 2.2
			var stern := p - side * 2.2
			draw_line(_at(stern), _at(bow + side * 0.8), Color("3a3a3e"), 2.0)                    # the trailer tongue
			draw_colored_polygon(PackedVector2Array([_at(stern + f * 0.9, 5.0), _at(bow + f * 0.3, 6.0), _at(bow + side * 0.6, 6.0), _at(bow - f * 0.3, 6.0), _at(stern - f * 0.9, 5.0)]), Color("2a5aa8"))
			draw_line(_at(stern, 6.0), _at(bow, 7.0), Color("4a7ac8"), 1.0)
		"clothesline":
			var a2 := p - side * 2.5
			var b2 := p + side * 2.5
			_post(a2, 16.0, Color("6a6a6e"))
			_post(b2, 16.0, Color("6a6a6e"))
			draw_line(_at(a2, 16.0), _at(b2, 16.0), Color(0.9, 0.9, 0.9, 0.6), 1.0)
			if not winter:
				for i in 4:
					var q := a2.lerp(b2, 0.2 + float(i) * 0.18)
					var cc: Color = [Color("e8e4dc"), Color("3a6aa8"), Color("c83a3a"), Color("e8c84a")][i]
					draw_rect(Rect2(_at(q, 15.0), Vector2(5, 5)), cc)
		"firepit":
			draw_circle(_at(p), 0.8 * PX, Color("6a6a6e"))
			draw_circle(_at(p), 0.55 * PX, Color("2a2420"))
			for i in 3:
				var cp := p + Vector2.from_angle(float(i) * TAU / 3.0 + 0.5) * 1.8
				draw_rect(Rect2(_at(cp, 3.0) - Vector2(3, 2), Vector2(6, 3)), Color("2a5a3a"))    # the chairs

## A round bush: a dark shadow, a body standing a little off the ground, a lit side and a few
## leaf flecks (snow on top in winter).
func _bush(p: Vector2, r: float, winter: bool, col: Color) -> void:
	var rp := r * PX
	draw_circle(_at(p) + Vector2(rp * 0.3, rp * 0.2), rp, Color(0, 0, 0, 0.22))
	var c := _at(p, rp * 0.4)
	draw_circle(c, rp, col)
	draw_circle(c + Vector2(-rp * 0.25, -rp * 0.25), rp * 0.6, col.lightened(0.15))
	draw_circle(c + Vector2(-rp * 0.4, -rp * 0.4), rp * 0.25, col.lightened(0.3))
	if winter: draw_circle(c + Vector2(0, -rp * 0.3), rp * 0.7, Color(0.93, 0.95, 0.98, 0.9))
