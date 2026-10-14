## A building in 3/4 view: the roof lifted by the wall height, the south wall showing.
## Its origin is the south edge of the footprint, so y-sorting puts cars in front or behind.
class_name BuildingNode
extends StaticBody2D

## Vinyl and clapboard: the colours houses round here come in.
const HOUSE_COLS := [Color("8a9aaa"), Color("b89a7a"), Color("d8d0b8"), Color("7a9a7a"), Color("b0aa88"), Color("b86a5a"), Color("e8e4dc"), Color("6a7a9a"), Color("c8b070"), Color("9a8a9a")]

var data: Dictionary
var fp: Rect2           # footprint in px, relative to the origin
var hpx_base: float      # wall height (px) seen from straight overhead
var hpx: float:          # ...and from where the camera is
	get: return hpx_base * CarView.lift_k
var windows: Node2D
var _tb := TriBatch.new()       # the building's triangles, one command per redraw
var _drawn_up := Vector2.ZERO
var _drawn_k := 0.0
var _drawn_night := false

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
		"garage": return [Color("6a5a48"), Color("4e4234"), Color("5e5c62")]
		"coffee": return [Color("8a2a22"), Color("6a201a"), Color("4a4448")]
		"shop", "apts":
			var bc: Color = BRICK[int(absf(position.x * 0.37 + position.y)) % BRICK.size()]
			return [bc, bc.darkened(0.25), Color("6a6a6c")]
		"houses":
			var hc: Color = HOUSE_COLS[int(absf(position.x)) / 5 % HOUSE_COLS.size()]
			return [hc, hc.darkened(0.25), Color("4a3a34")]
		"house":
			var c: Color = HOUSE_COLS[(int(data.get("color", 0)) * 3 + int(absf(position.x)) / 7) % HOUSE_COLS.size()]
			return [c, c.darkened(0.25), Color("4a3a34")]
		"farmhouse": return [Color("e8e4dc"), Color("b8b4ac"), Color("3a3a44")]
		"barn": return [Color("8a2a22"), Color("6a201a"), Color("5a5a5e")]
		"church": return [Color("ece8e0"), Color("c8c4bc"), Color("4a4a54")]
		"warehouse": return [Color("6a6e74"), Color("54585e"), Color("7a7e84")]
		"bigbox", "mall": return [Color("b8b0a0"), Color("8a8478"), Color("8a8a8e")]
		"arena": return [Color("4a5a6a"), Color("3a4654"), Color("8a9098")]
		"casino": return [Color("2a1a3a"), Color("1e1228"), Color("3a2a4a")]
		"plant": return [Color("9a948a"), Color("7a746a"), Color("6a665e")]
		"tower": return [Color("b8b8bc"), Color("8a8a90"), Color("c8c8cc")]
		"pumps": return [Color("b8b8b2"), Color("8a8a84"), Color("a4a6a8")]
		"junk": return [Color("6a5040"), Color("3a2c24"), Color("5a4a40")]
	return [Color("7a6a5a"), Color("5a4e42"), Color("5e5e62")]

## Downtown brick and block: red, brown, buff, painted.
const BRICK := [Color("8a4434"), Color("7a5442"), Color("b89a76"), Color("6a6e78"), Color("9a5a3e"), Color("5a6a5a"), Color("a88a6a")]

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
	var _t0 := Time.get_ticks_usec()
	_process_timed(_dt)
	Prof.lap('proc_building', _t0)

## Redrawn when the camera turns or tilts (the walls lean with it), or when the lights come on;
## a casino's neon cycles its colour. Otherwise the same commands stand from frame to frame.
func _process_timed(_dt: float) -> void:
	var neon: bool = String(data.kind) == "casino" and windows.visible
	var up := lean_up()
	if up == _drawn_up and CarView.lift_k == _drawn_k and windows.visible == _drawn_night and not neon: return
	_drawn_up = up
	_drawn_k = CarView.lift_k
	_drawn_night = windows.visible
	queue_redraw()
	windows.queue_redraw()

## The camera's up, in steps of a degree and a half: the walls lean with it, and redrawing every
## building for every fraction of a degree while the chase camera swings is most of a frame.
static func lean_up() -> Vector2:
	return Vector2.from_angle(snappedf(CarView.screen_up.angle(), deg_to_rad(1.5)))

## The walls that face the camera: [a, b, outward normal] (a toward b along the footprint).
func visible_walls() -> Array:
	var c := corners()
	var out: Array = []
	var down := -CarView.screen_up
	for i in 4:
		var a := c[i]
		var b := c[(i + 1) % 4]
		var n := (b - a).normalized().orthogonal()      # (corners run clockwise, so this points out)
		if n.dot(down) > 0.05: out.append([a, b, n])
	return out

func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	_tb.quad(a, b, c, d, col)

func _draw() -> void:
	var _t0 := Time.get_ticks_usec()
	_draw_timed()
	Prof.lap('draw_building', _t0)

func _draw_timed() -> void:
	var c := colors()
	var up := CarView.screen_up
	var hv := up * hpx
	var cs := corners()
	if data.kind == "tower":
		# a lattice radio tower: a tall thin mast with red and white bands
		var base := fp.get_center()
		for i in 8:
			var a := base + up * (i * 30.0)
			_tb.line(a, a + up * 28.0, c[0] if i % 2 == 0 else Color("c83a2a"), 4.0)
		_tb.flush(self)
		return
	var st := style()
	# shadow on the ground, cast away from the sun (low in the south-west sky)
	var sh := Vector2(1, 0.6).normalized() * hpx_base * (0.6 if st.roof == "flat" else 0.85)
	_tb.fan(PackedVector2Array([cs[0] + sh, cs[1] + sh, cs[2] + sh, cs[3] + sh]), Color(0, 0, 0, 0.22))
	# walls, shaded by which way they face, with what's on them
	for w in visible_walls():
		_wall(w[0], w[1], w[2], hv, c, st)
	# the roof
	match String(st.roof):
		"gable": _gable_roof(st)
		_: _flat_roof(c, st)
	if data.kind == "church":
		var top := fp.get_center() + hv + up * float(st.ridge) * CarView.lift_k
		_tb.fan(PackedVector2Array([top + up.orthogonal() * 10.0, top - up.orthogonal() * 10.0, top + up * 70.0]), c[2].lightened(0.1))
		_tb.line(top + up * 70.0, top + up * 92.0, Color("d8c870"), 2.0)
		_tb.line(top + up * 84.0 + up.orthogonal() * 6.0, top + up * 84.0 - up.orthogonal() * 6.0, Color("d8c870"), 2.0)
	_tb.flush(self)
	_sign(false)

const LIGHT := Vector2(-0.6, -0.8)      # where the daylight comes from (the north-west), for shading
const SHINGLES := [Color("3c3c42"), Color("4e3e34"), Color("33402f"), Color("5e5e64"), Color("6e3a30")]
const STEEL_ROOFS := [Color("8a2e26"), Color("2e4a6e"), Color("2e5a3a"), Color("8a8a8e")]
const TRIM := Color("e8e4da")
const SHUTTERS := [Color("2a3a4a"), Color("3a2a22"), Color("2a3a2a"), Color("1e1e22"), Color("6a2a24")]
const AWNINGS := [Color("8a2a24"), Color("2a5a3a"), Color("2a3a6a"), Color("c88a2a"), Color("3a3a3e")]

var _style := {}
## How this building is dressed, worked out once from where it stands (so it's the same every
## time): the roof (pitched or flat), its colours, the trim, the shutters, a chimney.
func style() -> Dictionary:
	if not _style.is_empty(): return _style
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 13.0 + position.y * 7.0) + 1
	var k := String(data.kind)
	var pitched := k in ["house", "farmhouse", "barn", "church", "houses"]
	var steel := k == "barn" or (pitched and rng.randf() < (0.35 if k == "farmhouse" else 0.12))
	var short := minf(fp.size.x, fp.size.y)
	_style = {
		"roof": "gable" if pitched else "flat",
		"roof_col": (STEEL_ROOFS[rng.randi() % STEEL_ROOFS.size()] if steel else SHINGLES[rng.randi() % SHINGLES.size()]) if k != "barn" else Color("8a8a8e"),
		"steel": steel,
		"ridge": short * (0.16 if k in ["barn", "church"] else 0.12),    # px from straight overhead (lifted with the camera)
		"eave": 4.0,
		"shutters": SHUTTERS[rng.randi() % SHUTTERS.size()] if k in ["house", "farmhouse"] and rng.randf() < 0.65 else null,
		"chimney": pitched and k != "barn" and rng.randf() < 0.6,
		"chimney_at": rng.randf_range(0.2, 0.8),
		"awning": AWNINGS[rng.randi() % AWNINGS.size()] if k == "shop" else null,
		"units": rng.randi_range(1, 5),
		"seed": rng.randi(),
	}
	return _style

## A point on the building: (x, y) on the footprint (local px), z up off the ground (px, already
## scaled for the camera).
func _at(p: Vector2, z: float) -> Vector2:
	return p + CarView.screen_up * z

func _shade(n: Vector2) -> float:
	return 0.74 + 0.26 * clampf(n.dot(LIGHT.normalized()), -1.0, 1.0)

## One wall facing the camera: siding or brick, the windows and doors, the trim.
func _wall(a: Vector2, b: Vector2, n: Vector2, hv: Vector2, c: Array, st: Dictionary) -> void:
	var wc: Color = c[0] * _shade(n)
	wc.a = 1.0
	_quad(a, b, b + hv, a + hv, wc)
	var k := String(data.kind)
	var L := a.distance_to(b)
	var H := hv.length()
	if L < 2.0 or H < 2.0: return
	var dir := (b - a) / L
	var upn := hv / H
	match k:
		"junk":
			_crushed(a, b, hv)
			return
		"barn":
			_quad(a.lerp(b, 0.35), a.lerp(b, 0.65), a.lerp(b, 0.65) + hv * 0.6, a.lerp(b, 0.35) + hv * 0.6, c[1])
			for t: float in [0.35, 0.65]: _tb.line(a.lerp(b, t), a.lerp(b, 0.5) + hv * 0.6 * (1.0 if t < 0.5 else 1.0), Color(1, 1, 1, 0.5), 1.0)
			return
		"pumps":
			return
	if k in ["house", "farmhouse", "houses"]:
		# lap siding: a line every few pixels, a shadow under each board
		var y := 3.0
		while y < H - 1.0:
			_tb.line(a + upn * y, b + upn * y, Color(0, 0, 0, 0.13), 1.0)
			y += 3.0
		# the foundation, and the corner boards
		_quad(a, b, b + upn * 2.5, a + upn * 2.5, Color("5a5852") * _shade(n))
		_tb.line(a, a + hv, TRIM * 0.92, 1.5)
		_tb.line(b, b + hv, TRIM * 0.92, 1.5)
	elif k in ["shop", "apts", "coffee", "garage"]:
		# brick: courses and a lighter band at the top
		var y2 := 4.0
		while y2 < H - 3.0:
			_tb.line(a + upn * y2, b + upn * y2, Color(0, 0, 0, 0.08), 1.0)
			y2 += 4.0
		_quad(a + hv - upn * 3.0, b + hv - upn * 3.0, b + hv, a + hv, (c[0] as Color).lightened(0.18))
	# the windows (the same places the night lights them, see window_slots)
	for sl in window_slots(L, H):
		var p: Vector2 = a + dir * float(sl.x) + upn * float(sl.z)
		var ww: float = sl.w
		var wh: float = sl.h
		if String(sl.kind) == "store":
			_quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, Color("26323e"))
			_quad(p + upn * wh * 0.55, p + dir * ww * 0.5 + upn * wh * 0.55, p + dir * ww * 0.35 + upn * wh, p + upn * wh, Color(1, 1, 1, 0.08))
			var m := 0.0
			while m < ww:
				_tb.line(p + dir * m, p + dir * m + upn * wh, Color("8a8e92"), 1.0)
				m += 12.0
			if st.awning != null:
				# a striped awning over the window, leaning out from the wall
				var top := p + upn * (wh + 3.0)
				var out := n * 6.0
				var aw: Color = st.awning
				_quad(top, top + dir * ww, top + dir * ww + out - upn * 4.0, top + out - upn * 4.0, aw)
				var sx := 0.0
				while sx < ww:
					_quad(top + dir * sx, top + dir * minf(ww, sx + 3.0), top + dir * minf(ww, sx + 3.0) + out - upn * 4.0, top + dir * sx + out - upn * 4.0, Color(1, 1, 1, 0.35))
					sx += 6.0
			continue
		if String(sl.kind) == "bay":
			# a roll-up door: steel panels, a row of little windows up top, the track either side
			var dc := Color("9a9ca0") if k == "garage" else Color("7a7c80")
			_quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, dc)
			var py := 0.0
			while py < wh - 1.0:
				_tb.line(p + upn * py, p + dir * ww + upn * py, Color(0, 0, 0, 0.22), 1.0)
				py += 4.0
			var wy := wh * 0.72
			var wx := 3.0
			while wx + 7.0 < ww - 2.0:
				_quad(p + dir * wx + upn * wy, p + dir * (wx + 7.0) + upn * wy, p + dir * (wx + 7.0) + upn * (wy + 6.0), p + dir * wx + upn * (wy + 6.0), Color("26323e"))
				wx += 10.0
			_tb.line(p, p + upn * wh, TRIM, 1.5)
			_tb.line(p + dir * ww, p + dir * ww + upn * wh, TRIM, 1.5)
			# the apron out front: a dark strip of oil-stained concrete
			_quad(p - dir * 1.0, p + dir * (ww + 1.0), p + dir * (ww + 1.0) + n * 4.0, p - dir * 1.0 + n * 4.0, Color("4e4c4a"))
			continue
		if String(sl.kind) == "drivethru":
			# the drive-thru: a sliding window, a ledge under it, the menu board and its little roof
			_quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, Color("26323e"))
			_tb.line(p + dir * ww * 0.5, p + dir * ww * 0.5 + upn * wh, Color("8a8e92"), 1.0)
			_tb.polyline(PackedVector2Array([p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, p]), Color("d8d4cc"), 1.0)
			_quad(p - dir * 1.0, p + dir * (ww + 1.0), p + dir * (ww + 1.0) + n * 2.5, p - dir * 1.0 + n * 2.5, Color("8a8884"))
			var mb := p - dir * 40.0 + n * 14.0
			_quad(mb, mb + dir * 22.0, mb + dir * 22.0 + upn * 28.0, mb + upn * 28.0, Color("2a1e1c"))
			_quad(mb + dir * 2.0 + upn * 2.0, mb + dir * 20.0 + upn * 2.0, mb + dir * 20.0 + upn * 26.0, mb + dir * 2.0 + upn * 26.0, Color("f4ece0"))
			_tb.line(mb + dir * 4.0 + upn * 21.0, mb + dir * 18.0 + upn * 21.0, Color("8a2a22"), 2.0)
			for row in 4: _tb.line(mb + dir * 4.0 + upn * (16.0 - row * 3.5), mb + dir * (12.0 + float(row % 2) * 5.0) + upn * (16.0 - row * 3.5), Color("6a6058"), 1.0)
			continue
		if String(sl.kind) == "door":
			_quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, Color("4a2e22") if k != "shop" else Color("26323e"))
			_tb.line(p + upn * wh, p + dir * ww + upn * wh, TRIM, 1.0)
			_tb.rect(Rect2(p + dir * ww * 0.75 + upn * wh * 0.45, Vector2(1, 1)), Color("d8c870"))
			# the step
			_quad(p - dir * 1.0, p + dir * (ww + 1.0), p + dir * (ww + 1.0) + n * 3.0, p - dir * 1.0 + n * 3.0, Color("8a8884"))
			continue
		# a window: glass, a glint, a white frame, shutters either side
		_quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, Color("1e2a38"))
		_quad(p + upn * wh * 0.6, p + dir * ww * 0.4 + upn * wh, p + dir * ww * 0.6 + upn * wh, p + upn * wh * 0.8, Color(0.75, 0.85, 1.0, 0.18))
		_tb.polyline(PackedVector2Array([p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, p]), TRIM if k in ["house", "farmhouse", "houses"] else Color("4a4e54"), 1.0)
		_tb.line(p + dir * ww * 0.5, p + dir * ww * 0.5 + upn * wh, TRIM * 0.85 if k in ["house", "farmhouse"] else Color("4a4e54"), 1.0)
		if st.shutters != null:
			var sc: Color = st.shutters
			_quad(p - dir * 3.0, p - dir * 0.5, p - dir * 0.5 + upn * wh, p - dir * 3.0 + upn * wh, sc)
			_quad(p + dir * (ww + 0.5), p + dir * (ww + 3.0), p + dir * (ww + 3.0) + upn * wh, p + dir * (ww + 0.5) + upn * wh, sc)

## At night the roofs go as dark as the ground round them: a faint moonlit line along the ridge
## and the eaves (or round a flat roof's parapet) keeps the shape of the place. Drawn on the
## unshaded night layer.
func _moon_edges(ci: CanvasItem) -> void:
	var st := style()
	var moon := Color(0.6, 0.68, 0.85, 0.22)
	var hp := hpx
	if String(st.roof) == "gable":
		var rh := float(st.ridge) * CarView.lift_k
		var R := fp.grow(float(st.eave))
		var cy := fp.get_center()
		var long_x := fp.size.x >= fp.size.y
		var r0 := Vector2(R.position.x, cy.y) if long_x else Vector2(cy.x, R.position.y)
		var r1 := Vector2(R.end.x, cy.y) if long_x else Vector2(cy.x, R.end.y)
		_tb.line(_at(r0, hp + rh), _at(r1, hp + rh), Color(moon, 0.35), 1.0)
		var rc := [R.position, Vector2(R.end.x, R.position.y), R.end, Vector2(R.position.x, R.end.y), R.position]
		for i in 4: _tb.line(_at(rc[i], hp), _at(rc[i + 1], hp), moon, 1.0)
	else:
		var cs := corners()
		for i in 4: _tb.line(_at(cs[i], hp), _at(cs[(i + 1) % 4], hp), moon, 1.0)

## Where the windows and doors go on a wall L px long and H px tall (all in px along the wall and up
## it): [{ x, z, w, h, kind: window / door / store }]. The day art and the night lights both use it,
## so a lit window is always where the window is.
func window_slots(L: float, H: float) -> Array:
	var out: Array = []
	var k := String(data.kind)
	if k in ["tower", "pumps", "barn", "junk", "church"] or L < 16.0 or H < 10.0: return out
	if k in ["house", "farmhouse", "houses"]:
		# a front door on the long wall, windows either side, at sill height
		var n := maxi(1, int(L / 26.0))
		var wh := clampf(H * 0.38, 6.0, 12.0)
		var z0 := clampf(H * 0.32, 4.0, 14.0)
		var door := L >= 40.0
		var door_i := n / 2 if door else -1
		var step := L / float(n + (1 if door else 0))
		var i := 0
		for j in n + (1 if door else 0):
			var cx := step * (float(j) + 0.5)
			if j == door_i:
				out.append({ "x": cx - 4.0, "z": 2.5, "w": 8.0, "h": minf(H * 0.62, 18.0), "kind": "door" })
				continue
			out.append({ "x": cx - 5.0, "z": z0, "w": 10.0, "h": wh, "kind": "window" })
			i += 1
		# a second storey
		if H > 38.0:
			for j in n:
				out.append({ "x": L / float(n) * (float(j) + 0.5) - 5.0, "z": H * 0.66, "w": 10.0, "h": wh * 0.9, "kind": "window" })
		return out
	# shops: a storefront at street level; everything else floors of windows
	var row0 := 6.0
	if k == "garage" and L > 120.0:
		# a service garage (12 px to the metre): roll-up bay doors three and a half metres wide
		# spread along the front, the office with its window and door at the end
		var office := 70.0
		var usable := L - office - 12.0
		var bays := clampi(int(usable / 56.0), 1, 4)
		var bw := 42.0
		var gap := (usable - float(bays) * bw) / float(bays + 1)
		var bh := minf(H * 0.8, 40.0)
		for j in bays:
			out.append({ "x": 12.0 + gap + float(j) * (bw + gap), "z": 0.0, "w": bw, "h": bh, "kind": "bay" })
		out.append({ "x": L - office + 8.0, "z": 12.0, "w": 26.0, "h": minf(H * 0.4, 22.0), "kind": "window" })
		out.append({ "x": L - 26.0, "z": 0.0, "w": 14.0, "h": minf(H * 0.6, 30.0), "kind": "door" })
		return out
	if k == "coffee" and L < maxf(fp.size.x, fp.size.y) - 1.0 and L >= 80.0:
		# the short wall of a coffee shop: the drive-thru window, with its menu board and a ledge
		out.append({ "x": L * 0.5 - 2.0, "z": 12.0, "w": 28.0, "h": minf(H * 0.4, 22.0), "kind": "drivethru" })
		return out
	if k in ["shop", "coffee"] and L > 30.0:
		out.append({ "x": 6.0, "z": 3.0, "w": L * 0.55, "h": minf(H * 0.4, 16.0), "kind": "store" })
		out.append({ "x": L * 0.55 + 12.0, "z": 2.5, "w": 8.0, "h": minf(H * 0.45, 17.0), "kind": "door" })
		row0 = minf(H * 0.4, 16.0) + 9.0
	var row := 0
	while row0 + row * 14.0 + 8.0 < H - 4.0:
		var x := 6.0
		while x + 7.0 < L - 6.0:
			out.append({ "x": x, "z": row0 + row * 14.0, "w": 7.0, "h": 8.0, "kind": "window" })
			x += 14.0
		row += 1
	return out

## A pitched roof over the walls: two slopes of shingles (or ribbed steel) meeting at a raised
## ridge along the long side, gable ends showing the wall colour, the eaves sticking out past the
## walls, and maybe a chimney. Drawn far slope first, so the near one covers it.
func _gable_roof(st: Dictionary) -> void:
	var up := CarView.screen_up
	var down := -up
	var hp := hpx
	var rh := float(st.ridge) * CarView.lift_k
	var o := float(st.eave)
	var R := fp.grow(o)
	var long_x := fp.size.x >= fp.size.y
	var cy := fp.get_center()
	# the ridge's two ends, and each slope's eave edge, as [a, b] on the ground plan
	var ridge := [Vector2(R.position.x, cy.y), Vector2(R.end.x, cy.y)] if long_x else [Vector2(cy.x, R.position.y), Vector2(cy.x, R.end.y)]
	var slopes: Array = []
	if long_x:
		slopes.append({ "eave": [R.position, Vector2(R.end.x, R.position.y)], "n": Vector2(0, -1) })
		slopes.append({ "eave": [Vector2(R.position.x, R.end.y), R.end], "n": Vector2(0, 1) })
	else:
		slopes.append({ "eave": [R.position, Vector2(R.position.x, R.end.y)], "n": Vector2(-1, 0) })
		slopes.append({ "eave": [Vector2(R.end.x, R.position.y), R.end], "n": Vector2(1, 0) })
	slopes.sort_custom(func(s1, s2): return (s1.n as Vector2).dot(down) < (s2.n as Vector2).dot(down))
	var base: Color = st.roof_col
	# the far slope, then the gable ends, then the near slope
	_slope(slopes[0], ridge, hp, rh, base, st)
	var wall: Color = colors()[0]
	var ends := [[Vector2(fp.position.x, fp.position.y), Vector2(fp.position.x, fp.end.y), Vector2(-1, 0)], [Vector2(fp.end.x, fp.position.y), Vector2(fp.end.x, fp.end.y), Vector2(1, 0)]] if long_x \
		else [[Vector2(fp.position.x, fp.position.y), Vector2(fp.end.x, fp.position.y), Vector2(0, -1)], [Vector2(fp.position.x, fp.end.y), Vector2(fp.end.x, fp.end.y), Vector2(0, 1)]]
	for e in ends:
		var en: Vector2 = e[2]
		if en.dot(down) <= 0.05: continue
		var ea: Vector2 = e[0]
		var eb: Vector2 = e[1]
		var mid := (ea + eb) / 2.0
		var gc := wall * _shade(en)
		gc.a = 1.0
		_tb.fan(PackedVector2Array([_at(ea, hp), _at(eb, hp), _at(mid, hp + rh)]), gc)
		# a little vent up in the gable
		_tb.rect(Rect2(_at(mid, hp + rh * 0.45) - Vector2(2, 2), Vector2(4, 3)), Color(0, 0, 0, 0.35))
	_slope(slopes[1], ridge, hp, rh, base, st)
	# the ridge cap
	_tb.line(_at(ridge[0], hp + rh), _at(ridge[1], hp + rh), base.lightened(0.25), 2.0)
	if st.chimney:
		var t: float = st.chimney_at
		var cp: Vector2 = (ridge[0] as Vector2).lerp(ridge[1], t) + (slopes[0].n as Vector2) * 3.0
		_box(cp, 6.0, 5.0, hp + rh * 0.6, hp + rh + 7.0, Color("7a3a2e"))

## One slope: shingles in courses from the eave up to the ridge.
func _slope(sl: Dictionary, ridge: Array, hp: float, rh: float, base: Color, st: Dictionary) -> void:
	var e: Array = sl.eave
	var n: Vector2 = sl.n
	var col := base * _shade(n)
	col.a = 1.0
	var ea := _at(e[0], hp)
	var eb := _at(e[1], hp)
	var ra := _at(ridge[0], hp + rh)
	var rb := _at(ridge[1], hp + rh)
	_tb.fan(PackedVector2Array([ea, eb, rb, ra]), col)
	var rows := 7
	for i in range(1, rows):
		var t := float(i) / float(rows)
		var la := ea.lerp(ra, t)
		var lb := eb.lerp(rb, t)
		_tb.line(la, lb, col.darkened(0.22), 1.0)
		if not st.steel:
			# the tabs: little gaps along each course, staggered row to row
			var L := la.distance_to(lb)
			var d := (lb - la) / maxf(L, 0.01)
			var x := 3.0 if i % 2 == 0 else 6.0
			while x < L:
				var q := la + d * x
				_tb.line(q, q + (ea.lerp(ra, float(i - 1) / float(rows)) - la) * 0.5, col.darkened(0.15), 1.0)
				x += 6.0
	if st.steel:
		# ribs down the slope
		var L2 := ea.distance_to(eb)
		var k := 4.0
		while k < L2:
			var f := k / L2
			_tb.line(ea.lerp(eb, f), ra.lerp(rb, f), col.lightened(0.12), 1.0)
			k += 4.0
	# the eave's edge: a gutter
	_tb.line(ea, eb, col.darkened(0.45), 1.5)

## A box standing on the building (a chimney, a rooftop unit): its top and the sides that face the
## camera. `p` is its middle on the plan, w x d px, from z0 up to z1.
func _box(p: Vector2, w: float, d: float, z0: float, z1: float, col: Color) -> void:
	var down := -CarView.screen_up
	var c4 := [p + Vector2(-w, -d) / 2.0, p + Vector2(w, -d) / 2.0, p + Vector2(w, d) / 2.0, p + Vector2(-w, d) / 2.0]
	for i in 4:
		var a: Vector2 = c4[i]
		var b: Vector2 = c4[(i + 1) % 4]
		var n := (b - a).normalized().orthogonal()      # (corners run clockwise, so this points out)
		if n.dot(down) <= 0.05: continue
		var fc := col * _shade(n) * 0.9
		fc.a = 1.0
		_quad(_at(a, z0), _at(b, z0), _at(b, z1), _at(a, z1), fc)
	var tc := col.lightened(0.12)
	_tb.fan(PackedVector2Array([_at(c4[0], z1), _at(c4[1], z1), _at(c4[2], z1), _at(c4[3], z1)]), tc)

## A flat roof: the parapet round the edge with its shadow inside, the membrane's seams, and what
## stands on it (air handlers, vents, a hatch, skylights on the big stores).
func _flat_roof(c: Array, st: Dictionary) -> void:
	var hp := hpx
	var cs := corners()
	var roof := PackedVector2Array([_at(cs[0], hp), _at(cs[1], hp), _at(cs[2], hp), _at(cs[3], hp)])
	var base: Color = c[2]
	_tb.fan(roof, base)
	var k := String(data.kind)
	if k == "pumps":
		# the canopy: a pale underside lit from below at night, and a fascia band round it in the
		# station's colours
		var band := Color("c8322a") if hash(position) % 2 == 0 else Color("2a5ab0")
		_tb.polyline(roof + PackedVector2Array([roof[0]]), band, 4.0)
		_tb.polyline(roof + PackedVector2Array([roof[0]]), band.lightened(0.35), 1.0)
		return
	# the membrane's seams
	var inner := fp.grow(-3.0)
	if inner.size.x > 4.0 and inner.size.y > 4.0:
		var x := inner.position.x + 14.0
		while x < inner.end.x:
			_tb.line(_at(Vector2(x, inner.position.y), hp), _at(Vector2(x, inner.end.y), hp), base.lightened(0.06), 1.0)
			x += 14.0
		# the parapet: a lip round the edge, lit on the sunny side, shadow on the inside
		var ic := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
		_tb.polyline(PackedVector2Array([_at(ic[0], hp), _at(ic[1], hp), _at(ic[2], hp), _at(ic[3], hp), _at(ic[0], hp)]), base.darkened(0.3), 2.0)
	_tb.polyline(roof + PackedVector2Array([roof[0]]), base.lightened(0.25), 2.0)
	if k == "junk":
		_junk_top(c)
		return
	# on the roof: air handlers, vents and a hatch (or skylights on a big store)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(st.seed)
	if k in ["bigbox", "mall", "warehouse"]:
		var gx := fp.position.x + 20.0
		while gx < fp.end.x - 20.0:
			var gy := fp.position.y + 16.0
			while gy < fp.end.y - 16.0:
				var r := Rect2(_at(Vector2(gx, gy), hp), Vector2(10, 6))
				_tb.rect(r, Color("8aa0b4"))
				_tb.rect(Rect2(r.position, Vector2(10, 2)), Color("c8d8e8"))
				gy += 30.0
			gx += 34.0
	var units := mini(int(st.units) + int(fp.size.x * fp.size.y / 20000.0), 10)
	for i in units:
		var p := fp.position + Vector2(rng.randf_range(10.0, maxf(11.0, fp.size.x - 10.0)), rng.randf_range(10.0, maxf(11.0, fp.size.y - 10.0)))
		var w := rng.randf_range(8.0, 14.0)
		var d := rng.randf_range(6.0, 10.0)
		_box(p, w, d, hp, hp + 5.0 * CarView.lift_k, Color("8a8c90"))
		# the fan on top
		_tb.circle(_at(p, hp + 5.0 * CarView.lift_k), minf(w, d) * 0.28, Color("4a4c50"))
	for i in 2 + units / 2:
		var vp := fp.position + Vector2(rng.randf_range(6.0, maxf(7.0, fp.size.x - 6.0)), rng.randf_range(6.0, maxf(7.0, fp.size.y - 6.0)))
		_tb.circle(_at(vp, hp + 1.0), 1.5, Color("2a2a2e"))

func _junk_top(c: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x + position.y)
	var hv := CarView.screen_up * hpx
	var along := fp.size.x >= fp.size.y
	var k := 4.0
	var L := fp.size.x if along else fp.size.y
	while k + 30.0 < L:
		var w := 26.0 + rng.randf() * 10.0
		var cr := Rect2(fp.position + (Vector2(k, 4) if along else Vector2(4, k)) + hv, Vector2(w, fp.size.y - 8) if along else Vector2(fp.size.x - 8, w))
		_tb.rect(cr, CRUSHED[rng.randi() % CRUSHED.size()])
		_tb.rect_outline(cr, Color("4a2c1a"), 2.0)
		k += w + 6.0

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
			if rng.randf() < 0.4: _tb.line(p + upn * (h * 0.5), p + dir * minf(6.0, w) + upn * (h * 0.5), Color("d8d0c0", 0.5), 1.0)
			x += w + 2.0
		y += h

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
		var _t0 := Time.get_ticks_usec()
		_draw_timed()
		Prof.lap('draw_windows', _t0)

	func _draw_timed() -> void:
		var kind: String = building.data.kind
		if kind in ["tower", "pumps", "barn", "junk"]: return
		var hv := CarView.screen_up * building.hpx
		var lit := 0.55 if kind in ["apts", "house", "farmhouse", "shop", "houses"] else 0.3
		for w in building.visible_walls():
			_lit_windows(w[0], w[1], hv, lit)
		building._moon_edges(self)
		building._tb.flush(self)
		building._sign(true, self)

	func _lit_windows(a: Vector2, b: Vector2, hv: Vector2, chance: float) -> void:
		var L := a.distance_to(b)
		var H := hv.length()
		if L < 2.0 or H < 2.0: return
		var dir := (b - a) / L
		var upn := hv / H
		var rng := RandomNumberGenerator.new()
		rng.seed = int(building.position.x * 3.0 + a.x + a.y)
		for sl in building.window_slots(L, H):
			var kind := String(sl.kind)
			var on := kind == "store" or rng.randf() < chance
			if not on: continue
			var p: Vector2 = a + dir * float(sl.x) + upn * float(sl.z)
			var ww: float = sl.w
			var wh: float = sl.h
			var col := Color("f2c86a") if rng.randf() < 0.75 else Color("9ad0f0")
			if kind == "door":
				# the porch light over the door, not the door itself
				building._tb.circle(p + dir * ww * 0.5 + upn * (wh + 3.0), 1.5, Color("ffe0a0"))
				continue
			if kind == "store": col = Color("f4e0b0")
			building._tb.quad(p, p + dir * ww, p + dir * ww + upn * wh, p + upn * wh, col)
			# the light it throws on the ground out front, fading away from the wall
			var out := dir.orthogonal() * (26.0 if kind == "store" else 16.0)
			var g0 := a + dir * float(sl.x)
			var g1 := g0 + dir * ww
			var spread := dir * ww * 0.35
			var lit := Color(col, 0.2 if kind == "store" else 0.13)
			var none := Color(col, 0.0)
			building._tb.quad_cols(g0, g1, g1 + out + spread, g0 + out - spread, lit, lit, none, none)
