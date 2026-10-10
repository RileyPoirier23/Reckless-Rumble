## What stands at the side of the road and over it, and what it means:
##   - traffic signals: a head over every lane coming into a signal junction, showing what that
##     approach's traffic obeys (the same cycle the traffic runs on), on a pole at the corner, with
##     the stop line painted across the approach
##   - stop signs: the side road at a priority junction, every way at an all-way stop (4-WAY)
##   - streetlights: the poles, their arms out over the street and the lamps on them lit at night
##     (each on its own photocell; the odd one flickers, the odd one's dead)
##   - speed limits: after a junction where the limit changes, out of every interchange, and every
##     kilometre and a half on the long roads
##   - warnings: curves and sharp turns (with the speed to take them at, and chevrons round the
##     sharp ones), merges, lanes ending, SIGNAL AHEAD and STOP AHEAD on the fast roads, railway
##     crossings; and EXIT signs on the highway
## The poles near you are solid. And it watches you at junctions: through a red light, or past a
## stop sign without stopping, and if a patrol car sees it, they light you up.
class_name RoadFurniture
extends Node2D

const PX := CarArt.PX
const CELL := 64.0
const STREET_LIGHTS := ["sodium", "sodium_flicker", "dead", "led", "lamp"]
const POLES := 20                  # solid poles kept around you
## How far up things stand, in pixels (the world is drawn top-down, tipped a little toward you).
const H_SIGN := 22.0
const H_SIGNAL := 34.0
const H_LIGHT := 40.0

const YELLOW := Color("f2c21a")
const SIGN_WHITE := Color("eeeeea")
const STOP_RED := Color("c8201c")
const EXIT_GREEN := Color("1e6e3a")
const POST := Color("6a6e74")
const INK := Color("141414")

var drive: Node
var map: MapData
var traffic: Traffic
var cells := {}                    # Vector2i -> Array of items
var counts := {}                   # kind -> how many (for the tests)
var vis: Array = []                # this frame's items in view
var lamps: Array = []              # this frame's lit lamps: [pos px, angle, local offset, colour, radius, glow]
var glow: Node2D
var paint: Node2D
var body: StaticBody2D
var _shapes: Array[CollisionShape2D] = []
var _pole_t := 0.0
var _t := 0.0
var _cum := {}                     # road idx -> PackedFloat32Array of arc length at each point
var _js := {}                      # road idx -> Array of [s, node] junctions along it
var _bld := {}                     # Vector2i (32 m) -> Array of building rects, for keeping signs out of them
# watching you
var watch_on := true               # tests and demos drive their own way through junctions: off there
var _in_j := -1
var _slow_t := 99.0
var _slow_p := Vector2.ZERO

# ------------------------------------------------------------------ building it

func setup(the_drive: Node) -> void:
	drive = the_drive
	z_index = 3000                 # with the treetops: over the cars
	glow = Glow.new()
	glow.fx = self
	glow.z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED          # lamps glow: the night doesn't darken them
	glow.material = mat
	add_child(glow)
	paint = Paint.new()
	paint.fx = self
	paint.z_as_relative = false
	paint.z_index = -3995          # on the road, under the cars
	add_child(paint)
	body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for i in POLES:
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 0.18 * PX
		cs.shape = c
		cs.disabled = true
		body.add_child(cs)
		_shapes.append(cs)
	build(drive.world.map, drive.traffic)

## Work out where everything goes (also used by the tests, with no scene around it).
func build(the_map: MapData, the_traffic: Traffic) -> void:
	map = the_map
	traffic = the_traffic
	cells = {}
	counts = {}
	_cum = {}
	_js = {}
	_bld = {}
	for b in map.buildings:
		var br: Rect2 = (b.r as Rect2).grow(0.4)
		for ky in range(floori(br.position.y / 32.0), floori(br.end.y / 32.0) + 1):
			for kx in range(floori(br.position.x / 32.0), floori(br.end.x / 32.0) + 1):
				var bk := Vector2i(kx, ky)
				if not _bld.has(bk): _bld[bk] = []
				_bld[bk].append(br)
	for r in map.roads: _cum[int(r.idx)] = _arc(r.pts)
	for n in traffic.junctions:
		for e in map.g_adj[n]:
			var i := int(e[2].idx)
			if not _js.has(i): _js[i] = []
			var s := _proj(e[2], map.g_pos[n])
			var dup := false
			for x in _js[i]:
				if absf(float(x[0]) - s) < 1.0: dup = true
			if not dup: _js[i].append([s, n])
	for i in _js: (_js[i] as Array).sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	_junction_signs()
	_limits()
	for r in map.roads: _curves(r)
	_merges()
	_lanes_end()
	_rail()
	_exits()
	_lights()
	for sg in map.wild_signs: _add({ "kind": "wild", "p": sg.p, "dir": sg.get("dir", Vector2.RIGHT), "animal": String(sg.kind) })

func _add(it: Dictionary) -> void:
	var kind := String(it.kind)
	if kind != "light" and kind != "signal":          # (a signal's found its own corner)
		# off the road and out of the buildings: step it further off the road, or back, or leave it out
		var spot: Variant = _clear_spot(it.p, _right(it.dir), it.dir)
		if spot == null:
			counts["dropped"] = int(counts.get("dropped", 0)) + 1
			return
		it.p = spot
		if kind != "chevron":
			for o in items_near(it.p, 3.0):
				if not String(o.kind) in ["light", "chevron"]:
					counts["dropped"] = int(counts.get("dropped", 0)) + 1
					return
	var k := Vector2i(floori(it.p.x / CELL), floori(it.p.y / CELL))
	if not cells.has(k): cells[k] = []
	cells[k].append(it)
	counts[it.kind] = int(counts.get(it.kind, 0)) + 1

## A spot near `p` that's off every road and out of every building: `p` itself, or a step further
## out to the side, or back the way traffic comes. Null if there's none.
func _clear_spot(p: Vector2, side: Vector2, along: Vector2, wide := false) -> Variant:
	var backs: Array = [0.0, 3.0, 6.0, 10.0] + ([-3.0, 14.0, 18.0] if wide else [])
	var outs: Array = [0.0, 1.2, 2.4, 3.6] + ([5.0, 6.5, -1.2] if wide else [])
	for back in backs:
		for out in outs:
			var q: Vector2 = p + side * out - along * back
			if not map.road_at(q, 0.5).is_empty(): continue
			if _in_building(q): continue
			return q
	return null

func _in_building(q: Vector2) -> bool:
	for r in _bld.get(Vector2i(floori(q.x / 32.0), floori(q.y / 32.0)), []):
		if (r as Rect2).has_point(q): return true
	return false

static func _right(d: Vector2) -> Vector2:
	return Vector2(-d.y, d.x)

## Where a sign stands beside road `r`: off the edge (and the shoulder), on the sidewalk in town.
static func _off(r: Dictionary) -> float:
	return float(r.w) / 2.0 + float(MapData.CLS[r.cls].shoulder) + 1.6

func _limit(r: Dictionary) -> int:
	return int(Police.limit_kmh(String(r.cls)))

# ---- a road as one long line: arc length along it, a point and its direction at any length

static func _arc(pts: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var acc := 0.0
	out.append(0.0)
	for i in range(1, pts.size()):
		acc += pts[i - 1].distance_to(pts[i])
		out.append(acc)
	return out

func _len(r: Dictionary) -> float:
	var c: PackedFloat32Array = _cum[int(r.idx)]
	return c[c.size() - 1]

## [point, direction of increasing length] at length `s` along road `r`.
func _at(r: Dictionary, s: float) -> Array:
	var pts: PackedVector2Array = r.pts
	var c: PackedFloat32Array = _cum[int(r.idx)]
	s = clampf(s, 0.0, c[c.size() - 1])
	var i := 0
	while i < pts.size() - 2 and c[i + 1] < s: i += 1
	var seg := c[i + 1] - c[i]
	var d := (pts[i + 1] - pts[i]) / maxf(seg, 0.001)
	return [pts[i] + d * (s - c[i]), d]

## How far along road `r` the point nearest `p` is.
func _proj(r: Dictionary, p: Vector2) -> float:
	var pts: PackedVector2Array = r.pts
	var c: PackedFloat32Array = _cum[int(r.idx)]
	var best := 0.0
	var bd := INF
	for i in pts.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d
			best = c[i] + pts[i].distance_to(q)
	return best

## The junctions on road `r` strictly between lengths `a` and `b`.
func _junctions_between(r: Dictionary, a: float, b: float) -> int:
	var n := 0
	for x in _js.get(int(r.idx), []):
		if float(x[0]) > minf(a, b) + 0.5 and float(x[0]) < maxf(a, b) - 0.5: n += 1
	return n

## A sign facing traffic that drives along road `r` the way `dirn` (+1 with the points, -1
## against), standing `s` along it on that traffic's right.
func _sign_at(r: Dictionary, s: float, dirn: int, it: Dictionary) -> void:
	if s < 2.0 or s > _len(r) - 2.0: return
	var pd: Array = _at(r, s)
	var d: Vector2 = pd[1] * float(dirn)
	it.p = (pd[0] as Vector2) + _right(d) * _off(r)
	it.dir = d
	it.road = int(r.idx)
	_add(it)

# ---- junctions: signals, stop signs, and the warnings before them on the fast roads

func _junction_signs() -> void:
	for n in traffic.junctions:
		var j: Dictionary = traffic.junctions[n]
		var hwy := false
		for e in map.g_adj[n]:
			if String(e[2].cls) == "highway": hwy = true
		for e in map.g_adj[n]:
			var m: int = e[0]
			var r: Dictionary = e[2]
			if String(r.cls) == "highway": continue
			var din := (map.g_pos[n] - map.g_pos[m]).normalized()
			var rt := _right(din)
			var sd: float = traffic.stop_line(n, m) if traffic.has_method("stop_line") else float(j.radius) + 1.2
			var c := map.g_pos[n] - din * sd
			var hw := float(r.w) / 2.0
			var major: bool = (j.majors as Array).has(int(r.idx))
			var line := [c + rt * 0.3, c + rt * (hw - 0.2)]
			var kind := ""
			match String(j.control):
				"signal":
					var heads := PackedVector2Array()
					for lane in Traffic.LANE[r.cls]: heads.append(c + rt * float(lane))
					# the pole on the near right corner; on the left if there's no room on the right
					var pole: Variant = _clear_spot(c + rt * (hw + 1.6), rt, din, true)
					if pole == null: pole = _clear_spot(c - rt * (hw + 1.6), -rt, din, true)
					if pole == null: pole = c + rt * (hw + 1.6)
					_add({ "kind": "signal", "p": pole, "dir": din, "n": n, "group": 0 if major else 1, "heads": heads, "line": line })
					kind = "signal_ahead"
				"allway":
					_add({ "kind": "stop", "p": c + rt * (hw + 1.6), "dir": din, "allway": true, "line": line })
					kind = "stop_ahead"
				"priority":
					if major: continue
					if hwy and String(r.cls) == "ramp": continue          # the ramp merges (see _merges)
					_add({ "kind": "stop", "p": c + rt * (hw + 1.6), "dir": din, "allway": false, "line": line })
					kind = "stop_ahead"
			# on the fast roads, a warning well back from it (if the last junction is far enough back)
			if kind != "" and _limit(r) >= 60:
				var sn := _proj(r, map.g_pos[n])
				var toward := 1 if _proj(r, map.g_pos[m]) < sn else -1
				var back := 150.0 if _limit(r) >= 80 else 110.0
				var s0 := sn - toward * back
				if s0 > 0.0 and s0 < _len(r) and _junctions_between(r, s0, sn) == 0 and _prev_junction_gap(r, sn, toward) > back + 60.0:
					_sign_at(r, s0, toward, { "kind": "warn", "icon": kind, "tab": "" })

## How far back along road `r` (driving `toward`) the junction before the one at `sn` is.
func _prev_junction_gap(r: Dictionary, sn: float, toward: int) -> float:
	var best := INF
	for x in _js.get(int(r.idx), []):
		var d := (sn - float(x[0])) * toward
		if d > 1.0: best = minf(best, d)
	return best if best < INF else (sn if toward > 0 else _len(r) - sn)

# ---- speed limits

func _limits() -> void:
	for r in map.roads:
		var L := _limit(r)
		var js: Array = _js.get(int(r.idx), [])
		var stops: Array = [[0.0, -1]] + js + [[_len(r), -1]]
		for k in stops.size() - 1:
			var a := float(stops[k][0])
			var b := float(stops[k + 1][0])
			var gap := b - a
			if gap < 70.0: continue
			var d := 25.0 if L <= 60 else 70.0
			# out of each end of this stretch: where the limit changes at the junction, or a long road
			for dirn: int in [1, -1]:
				var from_n: int = int(stops[k][1]) if dirn == 1 else int(stops[k + 1][1])
				if not (gap > 400.0 or from_n < 0 or _limit_changes(from_n, L)): continue
				var s := a + d if dirn == 1 else b - d
				_sign_at(r, s, dirn, { "kind": "limit", "kmh": L })
				# and again every kilometre and a half down a long one
				var rep := 1500.0
				while rep < gap - 300.0:
					_sign_at(r, (a + d + rep) if dirn == 1 else (b - d - rep), dirn, { "kind": "limit", "kmh": L })
					rep += 1500.0

func _limit_changes(n: int, L: int) -> bool:
	for e in map.g_adj[n]:
		if _limit(e[2]) != L: return true
	return false

# ---- curves

## The bends on road `r`, both ways: a warning sign with the speed to take it at, before it, and
## chevrons round the outside of the sharp ones. Not in town (the corners there are junctions).
func _curves(r: Dictionary) -> void:
	var town := String(r.cls) == "street" or (String(r.cls) == "arterial" and String(r.get("zone", "")) != "")
	var L := _limit(r)
	var total := _len(r)
	var step := 4.0
	var n := int(total / step)
	if n < 12: return
	var hd := PackedFloat32Array()
	for k in n + 1: hd.append((_at(r, k * step)[1] as Vector2).angle())
	var k := 0
	while k < n - 15:
		var dth := wrapf(hd[k + 15] - hd[k], -PI, PI)
		if absf(dth) < deg_to_rad(22.0):
			k += 1
			continue
		# the bend: from where the heading starts going round to where it stops
		var sgn := signf(dth)
		var k0 := k
		while k0 > 0 and wrapf(hd[k0] - hd[k0 - 1], -PI, PI) * sgn > deg_to_rad(0.8): k0 -= 1
		var k1 := k + 1
		while k1 < n and wrapf(hd[k1] - hd[k1 - 1], -PI, PI) * sgn > deg_to_rad(0.8): k1 += 1
		var turn := absf(wrapf(hd[k1] - hd[k0], -PI, PI))
		var blen := maxf((k1 - k0) * step, step)
		k = k1 + 1
		if turn < deg_to_rad(22.0): continue
		if town and turn < deg_to_rad(60.0): continue            # in town, only the real corners
		var s0 := k0 * step
		var s1 := k1 * step
		# a bend at a junction is the junction's business
		var near_j := false
		for x in _js.get(int(r.idx), []):
			if float(x[0]) > s0 - 30.0 and float(x[0]) < s1 + 30.0: near_j = true
		if near_j: continue
		var radius := blen / turn
		var adv := int(floorf(sqrt(3.2 * radius) * 3.6 / 10.0)) * 10
		adv = maxi(adv, 20)
		if adv >= L - 5: continue
		var sharp := turn > 1.2 and blen < 70.0
		var lead := 100.0 if L >= 80 else (70.0 if L >= 60 else 45.0)
		for dirn: int in [1, -1]:
			var right := (sgn > 0.0) == (dirn == 1)
			var icon := ("turn_" if sharp else "curve_") + ("r" if right else "l")
			var at := (s0 - lead) if dirn == 1 else (s1 + lead)
			if _junctions_between(r, at, s0 if dirn == 1 else s1) == 0:
				_sign_at(r, at, dirn, { "kind": "warn", "icon": icon, "tab": str(adv) })
			# chevrons on the outside, where you'd go off
			if sharp or adv <= 50:
				var nch := clampi(int(blen / 12.0) + 2, 3, 6)
				for c in nch:
					var s := lerpf(s0, s1, (float(c) + 0.5) / float(nch))
					var pd: Array = _at(r, s)
					var d: Vector2 = pd[1] * float(dirn)
					var outside := -_right(d) if right else _right(d)
					_add({ "kind": "chevron", "p": (pd[0] as Vector2) + outside * (_off(r) + 0.6), "dir": d, "right": right })

# ---- merges, exits, lanes ending

func _merges() -> void:
	for n in traffic.junctions:
		var hw_roads: Array = []
		var ramps: Array = []
		for e in map.g_adj[n]:
			if String(e[2].cls) == "highway": hw_roads.append(e)
			elif String(e[2].cls) == "ramp": ramps.append(e)
		if hw_roads.is_empty() or ramps.is_empty(): continue
		# on the ramp coming down to the highway: MERGE
		for e in ramps:
			var r: Dictionary = e[2]
			var sn := _proj(r, map.g_pos[n])
			var toward := 1 if _proj(r, map.g_pos[e[0]]) < sn else -1
			_sign_at(r, sn - toward * 70.0, toward, { "kind": "warn", "icon": "merge_l", "tab": "" })
		# on the highway: EXIT before a ramp that leaves on the right, MERGE before one that joins
		var done := {}
		for e in hw_roads:
			var h: Dictionary = e[2]
			if done.has(int(h.idx)): continue
			done[int(h.idx)] = true
			var sn := _proj(h, map.g_pos[n])
			for dirn: int in [1, -1]:
				var t: Vector2 = (_at(h, sn)[1] as Vector2) * float(dirn)
				for re in ramps:
					var arm := (map.g_pos[re[0]] - map.g_pos[n]).normalized()
					if t.x * arm.y - t.y * arm.x <= 0.2: continue       # not on this side
					if arm.dot(t) > 0.2:
						_sign_at(h, sn - dirn * 300.0, dirn, { "kind": "exit" })
					elif arm.dot(t) < -0.2:
						_sign_at(h, sn - dirn * 150.0, dirn, { "kind": "warn", "icon": "merge_r", "tab": "" })

## Where a two-lane road carries straight on as a one-lane one: RIGHT LANE ENDS, before it.
func _lanes_end() -> void:
	for n in map.g_pos.size():
		var es: Array = map.g_adj[n]
		for x in es.size():
			for y in es.size():
				if x == y: continue
				var r1: Dictionary = es[x][2]
				var r2: Dictionary = es[y][2]
				if r1 == r2 or String(r1.cls) == "highway": continue
				if (Traffic.LANE[r1.cls] as Array).size() < 2 or (Traffic.LANE[r2.cls] as Array).size() != 1: continue
				var a1 := (map.g_pos[es[x][0]] - map.g_pos[n]).normalized()
				var a2 := (map.g_pos[es[y][0]] - map.g_pos[n]).normalized()
				if a1.dot(a2) > -0.9: continue
				var sn := _proj(r1, map.g_pos[n])
				var toward := 1 if _proj(r1, map.g_pos[es[x][0]]) < sn else -1
				_sign_at(r1, sn - toward * 80.0, toward, { "kind": "warn", "icon": "lane_ends", "tab": "" })

## EXIT, on the highway before every interchange, both ways.
func _exits() -> void:
	for ip in map.interchanges:
		var best := {}
		var bd := 80.0
		for r in map.roads:
			if String(r.cls) != "highway": continue
			var d := (_at(r, _proj(r, ip))[0] as Vector2).distance_to(ip)
			if d < bd:
				bd = d
				best = r
		if best.is_empty(): continue
		var s := _proj(best, ip)
		for dirn: int in [1, -1]: _sign_at(best, s - dirn * 320.0, dirn, { "kind": "exit" })

func _rail() -> void:
	for c in map.crossings:
		var hit: Dictionary = map.road_at(c.p, 2.0)
		if hit.is_empty(): continue
		var r: Dictionary = hit.road
		var sc := _proj(r, c.p)
		var back := 110.0 if _limit(r) >= 70 else 60.0
		for dirn: int in [1, -1]: _sign_at(r, sc - dirn * back, dirn, { "kind": "warn", "icon": "rail", "tab": "" })

## The streetlights the map put up: their poles and arms (the light itself is the light pool's).
func _lights() -> void:
	for l in map.lights:
		if not STREET_LIGHTS.has(String(l.type)): continue
		var arm: Vector2 = l.get("arm", Vector2.ZERO)
		_add({ "kind": "light", "p": l.p, "dir": arm, "arm": arm, "type": String(l.type), "seed": int(l.seed), "src": l })

# ------------------------------------------------------------------ the frame

func items_near(c: Vector2, radius: float) -> Array:
	var out: Array = []
	var k0 := Vector2i(floori((c.x - radius) / CELL), floori((c.y - radius) / CELL))
	var k1 := Vector2i(floori((c.x + radius) / CELL), floori((c.y + radius) / CELL))
	for ky in range(k0.y, k1.y + 1):
		for kx in range(k0.x, k1.x + 1):
			for it in cells.get(Vector2i(kx, ky), []):
				if (it.p as Vector2).distance_to(c) < radius: out.append(it)
	return out

func _process(dt: float) -> void:
	if drive == null or drive.car == null: return
	_t += dt
	var cm: Vector2 = drive.cam.global_position / PX
	var zoom: float = maxf(0.3, drive.cam.zoom.x)
	vis = items_near(cm, 40.0 / zoom + 25.0)
	_lamps()
	queue_redraw()
	glow.queue_redraw()
	paint.queue_redraw()
	_pole_t -= dt
	if _pole_t <= 0.0:
		_pole_t = 0.25
		_poles()
	_watch(dt)

## The camera's "up", and the angle that turns a sign's face so it reads upright on the screen.
static func _up() -> Vector2:
	return CarView.screen_up

static func _face_angle() -> float:
	return CarView.screen_up.angle() + PI / 2.0

## Whether a sign for traffic going `dir` shows you its face: the camera looks the way you're
## driving, so you read the ones meant for you and see the backs of the ones for the other way.
static func faces_you(dir: Vector2) -> bool:
	return dir.dot(CarView.screen_up) > 0.25

## Which lamps are lit this frame, and where.
func _lamps() -> void:
	lamps = []
	var up := _up()
	var ang := _face_angle()
	var night: bool = drive.sky.daylight() < 0.6
	for it in vis:
		match String(it.kind):
			"signal":
				var j: Dictionary = traffic.junctions.get(int(it.n), {})
				if j.is_empty(): continue
				var st := Traffic.signal_state(int(j.offset), int(it.group))
				var slot := 0 if st == "red" else (1 if st == "amber" else 2)
				var col: Color = [Color(1.0, 0.16, 0.1), Color(1.0, 0.72, 0.1), Color(0.2, 1.0, 0.45)][slot]
				if not faces_you(it.dir): continue          # another road's lights: you see the backs
				for hp in (it.heads as PackedVector2Array):
					lamps.append([hp * PX + up * (H_SIGNAL - 4.0), ang, Vector2(0, 2.5 + slot * 4.0), col, 1.6, night])
			"light":
				if String(it.type) == "dead" or not drive.sky.lights_on(int(it.seed) & 0xffff): continue
				if String(it.type) == "sodium_flicker":
					var ph := fmod(_t * 1.3 + (int(it.seed) & 0xffff) * 0.37, 7.0)
					if ph > 6.2 and int(_t * 18.0) % 2 == 0: continue
				var col := Color(1.0, 0.7, 0.35) if String(it.type).begins_with("sodium") else (Color(1.0, 0.88, 0.65) if String(it.type) == "lamp" else Color(0.9, 0.95, 1.0))
				var head: Vector2 = (it.p as Vector2) * PX + up * H_LIGHT + (it.arm as Vector2) * 2.2 * PX
				lamps.append([head, ang, Vector2(0, 1), col, 1.4, night])

func _draw() -> void:
	var up := _up()
	var ang := _face_angle()
	# the backs of signs first, so a face on the same post (chevrons both ways) shows over them
	var order: Array = []
	for it in vis:
		if String(it.kind) in ["light", "signal"] or not faces_you(it.dir): order.append(it)
	for it in vis:
		if not (String(it.kind) in ["light", "signal"]) and faces_you(it.dir): order.append(it)
	for it in order:
		var base: Vector2 = (it.p as Vector2) * PX
		match String(it.kind):
			"light":
				var top := base + up * H_LIGHT
				draw_line(base, top, Color("55585e"), 2.0)
				var arm: Vector2 = it.arm
				var head := top + arm * 2.2 * PX
				if arm != Vector2.ZERO: draw_line(top, head, Color("55585e"), 1.5)
				draw_set_transform(head, ang, Vector2.ONE)
				draw_rect(Rect2(-3, -1, 6, 3), Color("3a3c42"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"signal":
				var top := base + up * H_SIGNAL
				draw_line(base, top, Color("3a3c40"), 2.5)
				var far := top
				for hp in (it.heads as PackedVector2Array):
					var h: Vector2 = hp * PX + up * H_SIGNAL
					if h.distance_to(top) > far.distance_to(top): far = h
				draw_line(top, far, Color("3a3c40"), 2.0)
				var front := faces_you(it.dir)
				for hp in (it.heads as PackedVector2Array):
					draw_set_transform(hp * PX + up * (H_SIGNAL - 4.0), ang, Vector2.ONE)
					if front:
						draw_rect(Rect2(-3, -1, 6, 13), Color("e8c020"))
						draw_rect(Rect2(-2, 0, 4, 11), INK)
						for i in 3: draw_circle(Vector2(0, 2.5 + i * 4.0), 1.5, [Color("4a1210"), Color("4a3a10"), Color("10401c")][i])
					else:
						draw_rect(Rect2(-2.5, 0, 5, 12), Color("2a2a2e"))         # the back of the head
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:
				var top := base + up * H_SIGN
				draw_line(base, top, POST, 1.5)
				draw_set_transform(top, ang, Vector2.ONE)
				if faces_you(it.dir): _face(it)
				else: _back(it)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## A sign's face, drawn upright with its bottom middle at (0, 0).
func _face(it: Dictionary) -> void:
	match String(it.kind):
		"limit":
			var r := Rect2(-9, -21, 18, 21)
			draw_rect(r, SIGN_WHITE)
			draw_rect(r, INK, false, 1.0)
			PixelFont.draw_centered(self, 0, -19, "MAX", INK)
			var num := str(int(it.kmh))
			PixelFont.draw_centered(self, 0, -12, num, INK, 2 if num.length() <= 2 else 1)
		"stop":
			var pts := PackedVector2Array()
			for i in 8: pts.append(Vector2(0, -10) + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * 9.0)
			draw_colored_polygon(pts, STOP_RED)
			draw_polyline(pts + PackedVector2Array([pts[0]]), SIGN_WHITE, 1.0)
			PixelFont.draw_centered(self, 0, -12, "STOP", SIGN_WHITE)
			if bool(it.allway):
				draw_rect(Rect2(-11, 0, 22, 8), SIGN_WHITE)
				draw_rect(Rect2(-11, 0, 22, 8), INK, false, 1.0)
				PixelFont.draw_centered(self, 0, 2, "4-WAY", INK)
		"exit":
			var r := Rect2(-12, -12, 24, 12)
			draw_rect(r, EXIT_GREEN)
			draw_rect(r.grow(-1), SIGN_WHITE, false, 1.0)
			PixelFont.draw_centered(self, 0, -9, "EXIT", SIGN_WHITE)
		"wild":
			# MOOSE / DEER CROSSING: the animal in black on the yellow diamond
			var c := Vector2(0, -10)
			var dia := PackedVector2Array([c + Vector2(0, -9), c + Vector2(9, 0), c + Vector2(0, 9), c + Vector2(-9, 0)])
			draw_colored_polygon(dia, YELLOW)
			draw_polyline(dia + PackedVector2Array([dia[0]]), INK, 1.0)
			var moose: bool = String(it.animal) == "moose"
			var bw := 7.0 if moose else 6.0
			draw_line(c + Vector2(bw * 0.5, -1), c + Vector2(-bw * 0.5, -1), INK, 3.0)
			for lx in [-0.35, 0.35]: draw_line(c + Vector2(-bw * lx, 0), c + Vector2(-bw * lx, 3.5), INK, 1.0)
			draw_line(c + Vector2(-bw * 0.5, -1), c + Vector2(-(bw * 0.5 + 1.5), -(4.0 if moose else 3.5)), INK, 2.0)
			if moose: draw_line(c + Vector2(-(bw * 0.5 - 0.5), -5), c + Vector2(-(bw * 0.5 + 3.0), -5.5), INK, 1.0)
		"chevron":
			draw_rect(Rect2(-5, -12, 10, 12), YELLOW)
			var s := 1.0 if bool(it.right) else -1.0
			draw_polyline(PackedVector2Array([Vector2(-2 * s, -10), Vector2(2 * s, -6), Vector2(-2 * s, -2)]), INK, 2.0)
		"warn":
			_diamond(String(it.icon))
			var tab := String(it.get("tab", ""))
			if tab != "":
				draw_rect(Rect2(-8, -4, 16, 8), YELLOW)
				draw_rect(Rect2(-8, -4, 16, 8), INK, false, 1.0)
				PixelFont.draw_centered(self, 0, -2, tab, INK)

## The back of a sign: the same shape, in galvanized grey.
func _back(it: Dictionary) -> void:
	var grey := Color("8e9298")
	match String(it.kind):
		"limit": draw_rect(Rect2(-9, -21, 18, 21), grey)
		"stop":
			var pts := PackedVector2Array()
			for i in 8: pts.append(Vector2(0, -10) + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * 9.0)
			draw_colored_polygon(pts, grey)
		"exit": draw_rect(Rect2(-12, -12, 24, 12), grey)
		"chevron": draw_rect(Rect2(-5, -12, 10, 12), grey)
		"warn", "wild":
			var c := Vector2(0, -14) if String(it.kind) == "warn" else Vector2(0, -10)
			var r := 10.0 if String(it.kind) == "warn" else 9.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), grey)
			if String(it.get("tab", "")) != "": draw_rect(Rect2(-8, -4, 16, 8), grey)
	draw_rect(Rect2(-1, -6, 2, 6), Color("6a6e74"))            # the bracket on the post

## A yellow warning diamond, and what it's warning about.
func _diamond(icon: String) -> void:
	var c := Vector2(0, -14)
	var dia := PackedVector2Array([c + Vector2(0, -10), c + Vector2(10, 0), c + Vector2(0, 10), c + Vector2(-10, 0)])
	draw_colored_polygon(dia, YELLOW)
	draw_polyline(dia + PackedVector2Array([dia[0]]), INK, 1.0)
	var s := -1.0 if icon.ends_with("_l") else 1.0
	match icon:
		"curve_l", "curve_r":
			draw_polyline(PackedVector2Array([c + Vector2(-2 * s, 5), c + Vector2(-2 * s, 1), c + Vector2(0, -2), c + Vector2(2 * s, -3)]), INK, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(2 * s, -6), c + Vector2(5 * s, -3), c + Vector2(2 * s, 0)]), INK)
		"turn_l", "turn_r":
			draw_polyline(PackedVector2Array([c + Vector2(-2 * s, 5), c + Vector2(-2 * s, -2), c + Vector2(2 * s, -2)]), INK, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(2 * s, -5), c + Vector2(5 * s, -2), c + Vector2(2 * s, 1)]), INK)
		"merge_l", "merge_r":
			draw_line(c + Vector2(s, 6), c + Vector2(s, -4), INK, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(s - 3, -3), c + Vector2(s, -7), c + Vector2(s + 3, -3)]), INK)
			draw_line(c + Vector2(-4 * s, 6), c + Vector2(s, 0), INK, 1.5)
		"lane_ends":
			draw_line(c + Vector2(-3, 6), c + Vector2(-3, -6), INK, 1.5)
			draw_line(c + Vector2(3, 6), c + Vector2(3, 0), INK, 1.5)
			draw_line(c + Vector2(3, 0), c + Vector2(-1, -5), INK, 1.5)
		"signal_ahead":
			draw_rect(Rect2(c + Vector2(-2.5, -6), Vector2(5, 12)), INK)
			for i in 3: draw_circle(c + Vector2(0, -3.5 + i * 3.5), 1.3, [STOP_RED, Color("e8a010"), Color("2aa84a")][i])
		"stop_ahead":
			var pts := PackedVector2Array()
			for i in 8: pts.append(c + Vector2(0, -2.5) + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * 3.8)
			draw_colored_polygon(pts, STOP_RED)
			draw_line(c + Vector2(0, 7), c + Vector2(0, 2), INK, 1.5)
		"rail":
			draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), INK, 2.0)
			draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), INK, 2.0)

## The lit lamps, unshaded, with a halo at night.
class Glow extends Node2D:
	var fx: RoadFurniture
	func _draw() -> void:
		for l in fx.lamps:
			draw_set_transform(l[0], l[1], Vector2.ONE)
			var col: Color = l[3]
			if bool(l[5]): draw_circle(l[2], float(l[4]) * 3.2, Color(col, 0.22))
			draw_circle(l[2], float(l[4]), col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The stop lines, painted across each approach that has to stop.
class Paint extends Node2D:
	var fx: RoadFurniture
	func _draw() -> void:
		var snow := clampf(fx.drive.sky.snow_cover * 1.3, 0.0, 0.9) if fx.drive else 0.0
		var col := Color(0.92, 0.92, 0.9, 0.9 * (1.0 - snow))
		for it in fx.vis:
			if not it.has("line"): continue
			draw_line((it.line[0] as Vector2) * PX, (it.line[1] as Vector2) * PX, col, 0.45 * PX)

# ------------------------------------------------------------------ the poles you can hit

func _poles() -> void:
	var c: PlayerCar = drive.car
	var near: Array = []
	for it in items_near(c.sim.pos, 40.0):
		if String(it.kind) in ["light", "signal"]: near.append([c.sim.pos.distance_squared_to(it.p), it.p])
	near.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	for i in POLES:
		if i < near.size():
			_shapes[i].position = (near[i][1] as Vector2) * PX
			_shapes[i].disabled = false
		else:
			_shapes[i].disabled = true

# ------------------------------------------------------------------ watching you

## Through a red (that had been red a second) or past a stop sign, without having stopped: if a
## patrol car sees it, that's them lighting you up. Stopping first and then going (a right on
## red, or your turn at the stop) is fine.
func _watch(dt: float) -> void:
	var c: PlayerCar = drive.car
	var p := c.sim.pos
	if c.sim.speed() < 1.5:
		_slow_t = 0.0
		_slow_p = p
	else:
		_slow_t += dt
	var n := _junction_at(p)
	if n == _in_j or not watch_on:
		_in_j = n
		return
	_in_j = n
	if n < 0: return
	var why := violation(n, p, c.sim.world_velocity(), _slow_t < 6.0 and _slow_p.distance_to(map.g_pos[n]) < float(traffic.junctions[n].radius) + 22.0)
	if why == "": return
	if StoryState.active or not drive.police.enabled: return
	# (mid-chase it just goes on the ticket: no note on the screen)
	if not drive.police.chasing(): drive.hud.notify("THAT LIGHT WAS RED." if why == "red_light" else "YOU ROLLED THE STOP SIGN.", "warn", 1, 2.5)
	drive.police.report(why)

## The junction whose box `p` is in, or -1.
func _junction_at(p: Vector2) -> int:
	var k := Vector2i(floori(p.x / 64.0), floori(p.y / 64.0))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for n in traffic._node_cells.get(k + Vector2i(dx, dy), []):
				if not traffic.junctions.has(n): continue
				if map.g_pos[n].distance_to(p) < float(traffic.junctions[n].radius) - 0.5: return n
	return -1

## What driving into junction `n` at `p` with velocity `v` breaks: "red_light", "stop_sign" or "".
func violation(n: int, p: Vector2, v: Vector2, stopped_first: bool) -> String:
	if v.length() < 1.5 or stopped_first: return ""
	var j: Dictionary = traffic.junctions.get(n, {})
	if j.is_empty(): return ""
	# which way you came in: the arm behind you
	var best := -1.0
	var road := {}
	for e in map.g_adj[n]:
		var arm := (map.g_pos[e[0]] - map.g_pos[n]).normalized()
		var d := arm.dot(-v.normalized())
		if d > best:
			best = d
			road = e[2]
	if best < 0.6 or road.is_empty(): return ""
	var major: bool = (j.majors as Array).has(int(road.idx))
	match String(j.control):
		"signal":
			var g := 0 if major else 1
			if Traffic.signal_state(int(j.offset), g) == "red" and Traffic.signal_since(int(j.offset), g) > 1.0: return "red_light"
		"allway": return "stop_sign"
		"priority":
			if not major and String(road.cls) != "ramp": return "stop_sign"
	return ""
