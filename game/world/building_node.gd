## A building in 3/4 view: the roof lifted by the wall height, the south wall showing.
## Its origin is the south edge of the footprint, so y-sorting puts cars in front or behind.
class_name BuildingNode
extends StaticBody2D

const HOUSE_COLS := [Color("6a7a8a"), Color("8a6a5a"), Color("c8c0a8"), Color("5a7a5a"), Color("8a8a6a"), Color("a85a4a")]

var data: Dictionary
var fp: Rect2           # footprint in px, relative to the origin
var hpx_base: float      # wall height (px) seen from straight overhead
var hpx: float:          # ...and from where the camera is
	get: return hpx_base * CarView.lift_k
var windows: Node2D

func setup(b: Dictionary) -> void:
	data = b
	var r: Rect2 = b.r
	position = Vector2(r.position.x, r.end.y) * CarArt.PX
	fp = Rect2(Vector2(0, -r.size.y * CarArt.PX), r.size * CarArt.PX)
	hpx_base = minf(float(b.h) * CarArt.PX * 0.32, 84.0)
	if b.kind != "pumps":
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = fp.size
		cs.shape = shape
		cs.position = fp.position + fp.size / 2.0
		add_child(cs)
	windows = Windows.new()
	windows.building = self
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	windows.material = mat
	windows.visible = false
	add_child(windows)

func colors() -> Array:
	match data.kind:
		"garage": return [Color("6a5a48"), Color("4e4234"), Color("3a3640")]
		"coffee": return [Color("8a2a22"), Color("6a201a"), Color("4a4448")]
		"shop": return [Color("5a5470"), Color("443e58"), Color("3c3a40")]
		"house":
			var c: Color = HOUSE_COLS[int(data.get("color", 0)) % HOUSE_COLS.size()]
			return [c, c.darkened(0.25), Color("4a3a34")]
		"farmhouse": return [Color("e8e4dc"), Color("b8b4ac"), Color("3a3a44")]
		"barn": return [Color("8a2a22"), Color("6a201a"), Color("5a5a5e")]
		"church": return [Color("ece8e0"), Color("c8c4bc"), Color("4a4a54")]
		"warehouse": return [Color("6a6e74"), Color("54585e"), Color("5e6268")]
		"bigbox", "mall": return [Color("b8b0a0"), Color("8a8478"), Color("6a6a6e")]
		"arena": return [Color("4a5a6a"), Color("3a4654"), Color("8a9098")]
		"casino": return [Color("2a1a3a"), Color("1e1228"), Color("3a2a4a")]
		"plant": return [Color("9a948a"), Color("7a746a"), Color("6a665e")]
		"tower": return [Color("b8b8bc"), Color("8a8a90"), Color("c8c8cc")]
		"pumps": return [Color("d8d8d0"), Color("a8a8a0"), Color("e8e8e0")]
		"junk": return [Color("6a5040"), Color("3a2c24"), Color("5a4a40")]
	return [Color("7a6a5a"), Color("5a4e42"), Color("3a383e")]

## The four footprint corners (px, local), clockwise from the north-west.
func corners() -> PackedVector2Array:
	return PackedVector2Array([fp.position, Vector2(fp.end.x, fp.position.y), fp.end, Vector2(fp.position.x, fp.end.y)])

## Where to sort this building against cars (the middle of its footprint, in world px).
func sort_point() -> Vector2:
	return global_position + fp.get_center()

## The footprint corners in world px (buildings don't move, so worked out once).
var _wc := PackedVector2Array()
func world_corners() -> PackedVector2Array:
	if _wc.is_empty():
		for c in corners(): _wc.append(global_position + c)
	return _wc

## How far from its origin any of it reaches (px): the footprint's far corner, plus the walls.
func reach() -> float:
	return fp.size.length() + hpx

## Does this building stand between the camera and a point (world px)? Its walls and roof are
## drawn lifted toward the top of the screen, so a car just behind it (further up the screen)
## disappears under it.
func covers(p: Vector2) -> bool:
	var up := CarView.screen_up
	if (p - sort_point()).dot(-up) >= 0.0: return false       # in front of it: drawn over it
	if p.distance_to(sort_point()) > fp.size.length() * 0.5 + hpx + 20.0: return false
	var pts := PackedVector2Array()
	for c in corners():
		pts.append(global_position + c)
		pts.append(global_position + c + up * hpx)
	var hull := Geometry2D.convex_hull(pts)
	# the car stands up off the road a little: any of it under the roof counts
	return Geometry2D.is_point_in_polygon(p, hull) or Geometry2D.is_point_in_polygon(p + up * 10.0, hull)

## Can you see past it? Gas pumps under a canopy and a radio mast don't block anything.
func blocks_sight() -> bool:
	return not String(data.get("kind", "")) in ["pumps", "tower"]

func _process(_dt: float) -> void:
	queue_redraw()
	windows.queue_redraw()

## The walls that face the camera: [a, b, outward normal] (a toward b along the footprint).
func visible_walls() -> Array:
	var c := corners()
	var out: Array = []
	var down := -CarView.screen_up
	for i in 4:
		var a := c[i]
		var b := c[(i + 1) % 4]
		var n := (b - a).normalized().orthogonal() * -1.0
		if n.dot(down) > 0.05: out.append([a, b, n])
	return out

func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([col, col, col, col]), PackedVector2Array())

func _draw() -> void:
	var c := colors()
	var up := CarView.screen_up
	var hv := up * hpx
	var cs := corners()
	if data.kind == "tower":
		# a lattice radio tower: a tall thin mast with red and white bands
		var base := fp.get_center()
		for i in 8:
			var a := base + up * (i * 30.0)
			draw_line(a, a + up * 28.0, c[0] if i % 2 == 0 else Color("c83a2a"), 4.0)
		return
	# shadow on the ground, cast away from the sun (low in the south-west sky)
	var sh := Vector2(1, 0.6).normalized() * hpx_base * 0.6
	draw_colored_polygon(PackedVector2Array([cs[0] + sh, cs[1] + sh, cs[2] + sh, cs[3] + sh]), Color(0, 0, 0, 0.22))
	# walls, shaded by which way they face
	var light := Vector2(-0.6, -0.8)
	for w in visible_walls():
		var a: Vector2 = w[0]
		var b: Vector2 = w[1]
		var n: Vector2 = w[2]
		var shade := 0.72 + 0.28 * clampf(n.dot(light), -1.0, 1.0)
		var wc: Color = c[0] * shade
		wc.a = 1.0
		_quad(a, b, b + hv, a + hv, wc)
		if data.kind in ["barn"]:
			_quad(a.lerp(b, 0.35), a.lerp(b, 0.65), a.lerp(b, 0.65) + hv * 0.6, a.lerp(b, 0.35) + hv * 0.6, c[1])
		elif data.kind == "junk":
			_crushed(a, b, hv)
		elif data.kind not in ["pumps", "church"]:
			_windows_on(a, b, hv, Color("1e2430"), Color("3a4658"), 1.0)
		if data.kind == "garage":
			var L := a.distance_to(b)
			var k := 20.0
			while k + 110.0 < L:
				var p0 := a.lerp(b, k / L)
				var p1 := a.lerp(b, (k + 110.0) / L)
				_quad(p0, p1, p1 + up * 30.0, p0 + up * 30.0, Color("8a8a84"))
				for r in 6: draw_line(p0 + up * (r * 5.0), p1 + up * (r * 5.0), Color("6a6a66"), 1.0)
				k += 150.0
	# the roof
	var roof := PackedVector2Array([cs[0] + hv, cs[1] + hv, cs[2] + hv, cs[3] + hv])
	draw_colored_polygon(roof, c[2])
	draw_polyline(roof + PackedVector2Array([roof[0]]), c[1], 2.0)
	match data.kind:
		"house", "farmhouse", "barn":
			# a pitched roof: the ridge along the long side
			var long_x := fp.size.x >= fp.size.y
			var m0 := (cs[0] + cs[3]) / 2.0 + hv if long_x else (cs[0] + cs[1]) / 2.0 + hv
			var m1 := (cs[1] + cs[2]) / 2.0 + hv if long_x else (cs[3] + cs[2]) / 2.0 + hv
			var half := PackedVector2Array([cs[0] + hv, cs[1] + hv, m1, m0]) if long_x else PackedVector2Array([cs[0] + hv, m0, m1, cs[3] + hv])
			draw_colored_polygon(half, c[2].lightened(0.12))
			draw_line(m0 + up * 6.0, m1 + up * 6.0, c[2].darkened(0.3), 2.0)
			if data.kind == "barn": draw_line(m0 + up * 6.0, m1 + up * 6.0, c[2].lightened(0.25), 3.0)
		"junk":
			# the top of the stack: a couple of flattened roofs, rust round the edges
			var rng := RandomNumberGenerator.new()
			rng.seed = int(position.x + position.y)
			var along := fp.size.x >= fp.size.y
			var k := 4.0
			var L := fp.size.x if along else fp.size.y
			while k + 30.0 < L:
				var w := 26.0 + rng.randf() * 10.0
				var cr := Rect2(fp.position + (Vector2(k, 4) if along else Vector2(4, k)) + hv, Vector2(w, fp.size.y - 8) if along else Vector2(fp.size.x - 8, w))
				draw_rect(cr, CRUSHED[rng.randi() % CRUSHED.size()])
				draw_rect(cr, Color("4a2c1a"), false, 2.0)
				k += w + 6.0
		"church":
			var top := fp.get_center() + hv
			draw_colored_polygon(PackedVector2Array([top + Vector2(-12, 0), top + Vector2(12, 0), top + up * 70.0]), c[2].lightened(0.1))
			draw_line(top + up * 70.0, top + up * 92.0, Color("d8c870"), 2.0)
			draw_line(top + up * 84.0 + up.orthogonal() * 6.0, top + up * 84.0 - up.orthogonal() * 6.0, Color("d8c870"), 2.0)
		_:
			var rng := RandomNumberGenerator.new()
			rng.seed = int(fp.size.x * 7 + fp.size.y + position.x)
			for i in mini(14, int(fp.size.x * fp.size.y / 9000.0) + 2):
				var p := fp.position + Vector2(rng.randf() * maxf(fp.size.x - 30, 1) + 10, rng.randf() * maxf(fp.size.y - 30, 1) + 10) + hv
				draw_rect(Rect2(p, Vector2(12 + rng.randi() % 10, 8 + rng.randi() % 6)), c[2].lightened(0.15))
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 3)), c[2].darkened(0.3))
	_sign(false)

const CRUSHED := [Color("7a2a24"), Color("2a4a6a"), Color("8a8a84"), Color("c8c0a8"), Color("3a5a3a"), Color("a86a2a"), Color("2a2a30")]

## A wall of crushed cars: flat slabs of old paint, stacked, with rust between.
func _crushed(a: Vector2, b: Vector2, hv: Vector2) -> void:
	var L := a.distance_to(b)
	var H := hv.length()
	if L < 8.0 or H < 4.0: return
	var dir := (b - a) / L
	var upn := hv / H
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 5.0 + a.x + a.y)
	var y := 1.0
	while y + 5.0 < H:
		var h := 5.0 + rng.randf() * 3.0
		var x := rng.randf() * 6.0
		while x + 8.0 < L:
			var w := minf(18.0 + rng.randf() * 16.0, L - x)
			var p := a + dir * x + upn * y
			_quad(p, p + dir * w, p + dir * w + upn * (h - 1.0), p + upn * (h - 1.0), CRUSHED[rng.randi() % CRUSHED.size()].darkened(0.15))
			if rng.randf() < 0.4: draw_line(p + upn * (h * 0.5), p + dir * minf(6.0, w) + upn * (h * 0.5), Color("d8d0c0", 0.5), 1.0)
			x += w + 2.0
		y += h

## Window grid on one wall, a..b along the ground, hv up the wall.
func _windows_on(a: Vector2, b: Vector2, hv: Vector2, glass: Color, frame: Color, lit_chance: float) -> void:
	var L := a.distance_to(b)
	var H := hv.length()
	if L < 16.0 or H < 14.0: return
	var dir := (b - a) / L
	var upn := hv / H
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 3.0 + a.x + a.y)
	var row := 0
	while 6.0 + row * 14.0 + 8.0 < H - 2.0:
		var x := 6.0
		while x + 7.0 < L - 6.0:
			var p := a + dir * x + upn * (H - 6.0 - row * 14.0 - 8.0)
			if rng.randf() < lit_chance:
				_quad(p, p + dir * 7.0, p + dir * 7.0 + upn * 8.0, p + upn * 8.0, glass)
				if lit_chance >= 1.0: draw_line(p + upn * 7.0, p + dir * 7.0 + upn * 7.0, frame, 1.0)
			x += 14.0
		row += 1

## The name over the door on the wall that faces the camera most, always upright on screen.
func _sign(lit: bool, ci: CanvasItem = null) -> void:
	if data.name == "" or data.kind == "pumps": return
	var target: CanvasItem = ci if ci else self
	var walls := visible_walls()
	if walls.is_empty(): return
	var best: Array = walls[0]
	for w in walls:
		if (w[2] as Vector2).dot(-CarView.screen_up) > (best[2] as Vector2).dot(-CarView.screen_up): best = w
	var mid: Vector2 = ((best[0] as Vector2) + (best[1] as Vector2)) / 2.0 + CarView.screen_up * hpx
	var ang := CarView.screen_up.angle() + PI / 2.0
	var sign_w := PixelFont.width(data.name, 2) + 10
	target.draw_set_transform(mid, ang, Vector2.ONE)
	var nc: Color = Color("f2d36a")
	if data.kind == "coffee": nc = Color("f4ece0")
	if data.get("neon") != null: nc = (data.neon as Color)
	if lit:
		if data.kind == "casino": nc = Color.from_hsv(fmod(Time.get_ticks_msec() / 3000.0, 1.0), 0.7, 1.0)
		PixelFont.draw(target, Vector2(-sign_w / 2.0 + 5, -13), data.name, nc.lightened(0.2), 2)
	else:
		target.draw_rect(Rect2(-sign_w / 2.0, -16, sign_w, 16), Color("1a1418"))
		PixelFont.draw(target, Vector2(-sign_w / 2.0 + 5, -13), data.name, nc.darkened(0.25), 2)
	target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

class Windows extends Node2D:
	var building: BuildingNode
	func _draw() -> void:
		var kind: String = building.data.kind
		if kind in ["tower", "pumps", "barn", "junk"]: return
		var hv := CarView.screen_up * building.hpx
		var lit := 0.55 if kind in ["apts", "house", "farmhouse", "shop"] else 0.3
		for w in building.visible_walls():
			_lit_windows(w[0], w[1], hv, lit)
		building._sign(true, self)

	func _lit_windows(a: Vector2, b: Vector2, hv: Vector2, chance: float) -> void:
		var L := a.distance_to(b)
		var H := hv.length()
		if L < 16.0 or H < 14.0: return
		var dir := (b - a) / L
		var upn := hv / H
		var rng := RandomNumberGenerator.new()
		rng.seed = int(building.position.x * 3.0 + a.x + a.y)
		var row := 0
		while 6.0 + row * 14.0 + 8.0 < H - 2.0:
			var x := 6.0
			while x + 7.0 < L - 6.0:
				var p := a + dir * x + upn * (H - 6.0 - row * 14.0 - 8.0)
				if rng.randf() < chance:
					var col := Color("f2c86a") if rng.randf() < 0.75 else Color("9ad0f0")
					draw_primitive(PackedVector2Array([p, p + dir * 7.0, p + dir * 7.0 + upn * 8.0, p + upn * 8.0]), PackedColorArray([col, col, col, col]), PackedVector2Array())
				x += 14.0
			row += 1
