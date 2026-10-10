## Traffic: the other drivers of Port Rumble.
##
## Every car follows the lanes of the road graph (right-hand traffic), steering at a point a
## little way ahead on its path (pure pursuit). Speed comes from the Intelligent Driver Model:
## it holds a safe gap to whatever is ahead (another car, you, or a stop line it has to obey)
## and brakes harder the faster that gap closes. Intersections have rules:
## - signals: green go, amber stop if you can, red stop;
## - stop signs on the smaller road: stop, then go when the main road is clear;
## - all-way stops: stop, then first come, first served;
## - nobody enters an intersection unless there's room on the other side (don't block the box).
## Cars spawn out of sight around you and disappear far behind, so the city always feels busy.
class_name Traffic
extends Node2D

const PX := CarArt.PX
const CYCLE := 50.0                # signal cycle (s): main road 22 green, 3 amber, 2 all red; side road 18, 3, 2
const SPAWN_MIN := 110.0           # metres from the camera: never pop in where you can see
const SPAWN_MAX := 240.0
const DESPAWN := 320.0

const SPEED := { "highway": 27.8, "arterial": 16.7, "street": 13.9, "rural": 22.2, "gravel": 13.0, "ramp": 15.0 }
const LANE := { "highway": [4.0, 7.6], "arterial": [2.0, 5.6], "street": [2.25], "rural": [2.0], "gravel": [1.75], "ramp": [2.0] }

const BODIES := [
	{ "name": "HONDO CIVIL", "body": "sedan", "length": 4.4, "width": 1.72, "wheelbase": 2.62 },
	{ "name": "TOYODA COROLLY", "body": "sedan", "length": 4.5, "width": 1.74, "wheelbase": 2.6 },
	{ "name": "FJORD ESCAPED", "body": "hatch", "length": 4.4, "width": 1.82, "wheelbase": 2.62 },
	{ "name": "DODGY CHARJER", "body": "sedan", "length": 5.04, "width": 1.9, "wheelbase": 3.05 },
	{ "name": "CHEVROLAY CAVA-LAME", "body": "coupe", "length": 4.6, "width": 1.7, "wheelbase": 2.64 },
	{ "name": "FJORD F-ONE-FIDDY", "body": "tow", "length": 5.6, "width": 2.0, "wheelbase": 3.6 },
	{ "name": "SUBAROO IMPREZZA", "body": "hatch", "length": 4.4, "width": 1.74, "wheelbase": 2.6 },
	{ "name": "VOLKSWAGON GULF", "body": "hatch", "length": 4.2, "width": 1.78, "wheelbase": 2.58 },
	{ "name": "DODGY GRAND CRAVIN'", "body": "hatch", "length": 5.1, "width": 1.95, "wheelbase": 3.08 },
	{ "name": "KIAH SOLE", "body": "hatch", "length": 4.1, "width": 1.8, "wheelbase": 2.57 },
	{ "name": "FJORD CROWN VICTORIOUS", "body": "sedan", "length": 5.4, "width": 1.98, "wheelbase": 2.9 },
	{ "name": "NISSUN SILVIO", "body": "coupe", "length": 4.52, "width": 1.69, "wheelbase": 2.47 },
]
const PAINTS := ["#c8342c", "#2c5a8a", "#e8e4dc", "#2a2a2e", "#8a8e94", "#3a6a3a", "#d8a03a", "#6a2a4a", "#4a6a8a", "#b8b0a0", "#e8e8e8", "#1e1e24", "#7a1a1a", "#c8c0a0"]

var map: MapData
var world: World
var sky: WorldSky
var ysort: Node2D
var player: PlayerCar
var cars: Array[TrafficCar] = []
var extra: Array = []          # cars with other drivers (racers, the police): traffic gives them room too
var parked: Array = []         # the parked cars near you (ParkedCars): the racers and the police go round them
var hush := Rect2()            # a street race is on in here: Marco's crew has the side streets blocked
var junctions := {}                 # node -> { control, major_roads, radius, queue, offset }
var _node_cells := {}               # Vector2i -> Array of node ids (64 m cells)
var shadowed := {}                  # Vector2i(a, b) -> true: a stretch of road laid over another one
var _grid := {}                     # per frame: Vector2i (20 m) -> Array of cars
var rng := RandomNumberGenerator.new()
var _spawn_t := 0.0
var night := false
var enabled := true
var ignore_player := false
static var clock := 0.0        # game seconds: what the signals cycle on (they stop when the game does)

func setup(the_world: World, the_sky: WorldSky, the_ysort: Node2D, the_player: PlayerCar) -> void:
	world = the_world
	map = world.map
	sky = the_sky
	ysort = the_ysort
	player = the_player
	rng.seed = 2019
	classify(map)

## Which junction is controlled how (signals, all-way stops, priority): from the map alone, so the
## road furniture and the tests can have it without a scene.
func classify(the_map: MapData) -> void:
	map = the_map
	junctions = {}
	_node_cells = {}
	for i in map.roads.size(): map.roads[i]["idx"] = i
	for n in map.g_pos.size():
		var k := Vector2i(floori(map.g_pos[n].x / 64.0), floori(map.g_pos[n].y / 64.0))
		if not _node_cells.has(k): _node_cells[k] = []
		_node_cells[k].append(n)
	for n in map.g_pos.size():
		if map.g_adj[n].size() >= 3: junctions[n] = _junction(n)
	_coordinate_signals()
	_shadows()

## Lights a few metres apart (one crossing, really, where the map's roads meet in a knot) run in
## step: the road that runs on through both gets its green at both at once, so nobody's caught
## at a red between them with their tail across the last one. Where a knot of three can't all
## line up, the bigger roads win, and nobody's routed the way that's left out of step.
func _coordinate_signals() -> void:
	var links: Array = []
	for n: int in junctions:
		if String(junctions[n].control) != "signal": continue
		for e in map.g_adj[n]:
			var m: int = e[0]
			if m <= n or not junctions.has(m) or String(junctions[m].control) != "signal" or float(e[1]) > 25.0: continue
			var gn := 0 if junctions[n].majors.has(int(e[2].idx)) else 1
			var gm := 0 if junctions[m].majors.has(int(e[2].idx)) else 1
			links.append([n, m, gn, gm, 0 if gn + gm == 0 else (1 if gn == gm else 2), float(e[1]), int(MapData.CLS[e[2].cls].rank)])
	# (the bigger road first: through traffic on an arterial outweighs a side street's turn)
	links.sort_custom(func(x: Array, y: Array) -> bool:
		if x[6] != y[6]: return x[6] > y[6]
		return x[4] < y[4] if x[4] != y[4] else x[5] < y[5])
	var placed := {}
	for l: Array in links:
		var a: int = l[0]
		var b: int = l[1]
		if placed.has(a) and placed.has(b): continue
		# the green for the linking road starts at the same moment at both ends
		var start := [0, 27]
		if placed.has(b):
			junctions[a].offset = posmod(int(junctions[b].offset) + start[l[2]] - start[l[3]], int(CYCLE))
		else:
			junctions[b].offset = posmod(int(junctions[a].offset) + start[l[3]] - start[l[2]], int(CYCLE))
		placed[a] = true
		placed[b] = true

## Stretches of road the map lays right on top of another road (a street that runs on a few
## metres alongside the main road into the same junction): two lanes of traffic can't share
## that, so nobody's routed down the lesser one unless it's the only way on.
func _shadows() -> void:
	shadowed = {}
	for a in map.g_pos.size():
		for e in map.g_adj[a]:
			var b: int = e[0]
			if b < a: continue
			var A := map.g_pos[a]
			var B := map.g_pos[b]
			var d := (B - A).normalized()
			var rank := int(MapData.CLS[e[2].cls].rank)
			var under := 0
			for f: float in [0.25, 0.5, 0.75]:
				var q := A.lerp(B, f)
				for m: int in _near_nodes(q, 0.0, 70.0):
					var hit := false
					for g in map.g_adj[m]:
						var k: int = g[0]
						if int(g[2].idx) == int(e[2].idx) or int(MapData.CLS[g[2].cls].rank) < rank: continue
						var M := map.g_pos[m]
						var Kp := map.g_pos[k]
						if absf((Kp - M).normalized().dot(d)) > 0.95 and MapData.seg_dist(q, M, Kp) < float(e[2].w) * 0.5:
							hit = true
							break
					if hit:
						under += 1
						break
			if under == 3:
				shadowed[Vector2i(a, b)] = true
				shadowed[Vector2i(b, a)] = true

# ------------------------------------------------------------------ the rules of the road

func _junction(n: int) -> Dictionary:
	var roads := {}
	var top := 0
	var radius := 4.0
	for e in map.g_adj[n]:
		var r: Dictionary = e[2]
		roads[int(r.idx)] = r
		top = maxi(top, int(MapData.CLS[r.cls].rank))
		radius = maxf(radius, r.w / 2.0 + 2.0)
	var majors: Array[int] = []
	var big := 0
	for i in roads:
		if int(MapData.CLS[roads[i].cls].rank) == top: majors.append(i)
		if int(MapData.CLS[roads[i].cls].rank) >= 4: big += 1
	var control := "priority"
	var z := map.zone_at(map.g_pos[n])
	var town: bool = z.id != ""
	if big >= 2 and town and top < 5: control = "signal"
	elif town and top == 4 and map.g_adj[n].size() >= 4: control = "signal"     # a full crossing on an arterial in town
	elif majors.size() == roads.size():
		# downtown and the village centres have four-way stops; elsewhere the street that runs
		# east-west (or the longer one) is the through road and the other one stops
		if z.style in ["downtown", "village"] and roads.size() >= 2: control = "allway"
		else:
			var best := -1
			var best_score := -INF
			for i in roads:
				var r: Dictionary = roads[i]
				var d: Vector2 = (r.pts[r.pts.size() - 1] - r.pts[0])
				var score := absf(d.normalized().x) * 100.0 + d.length() * 0.01
				if score > best_score:
					best_score = score
					best = i
			majors = [best]
	if control == "signal" and majors.size() > 1:
		majors.sort()
		majors = [majors[0]]            # the main road gets the long green
	if control == "signal":
		# a road that carries straight on from the main road's arm under another name (Main St
		# into Salisbury Rd) gets the main road's green, never the cross street's
		var main_dirs: Array[Vector2] = []
		for e in map.g_adj[n]:
			if majors.has(int(e[2].idx)): main_dirs.append((map.g_pos[e[0]] - map.g_pos[n]).normalized())
		for e in map.g_adj[n]:
			var i := int(e[2].idx)
			if majors.has(i): continue
			var arm := (map.g_pos[e[0]] - map.g_pos[n]).normalized()
			for md in main_dirs:
				if arm.dot(md) < -0.85:
					majors.append(i)
					break
	# where each road's traffic waits: at the edge of the box, or further back where it comes in at
	# a sharp angle to another road (waiting at the box there, its nose is in the other road's lanes)
	var stops := {}
	for e in map.g_adj[n]:
		var ui := (map.g_pos[e[0]] - map.g_pos[n]).normalized()
		var need := radius + 1.2
		var cap := 0.6
		for f in map.g_adj[n]:
			if f[0] == e[0]: continue
			var th := absf(ui.angle_to((map.g_pos[f[0]] - map.g_pos[n]).normalized()))
			# (a ramp laid in alongside the highway it joins waits back where it's off the
			# highway's lanes, however far back up the ramp that is)
			var merge := String(e[2].cls) == "ramp" and String(f[2].cls) == "highway" and th >= deg_to_rad(5.0)
			if (th < deg_to_rad(15.0) and not merge) or th > deg_to_rad(75.0): continue
			if merge and th < deg_to_rad(15.0): cap = 0.85
			need = maxf(need, (float(f[2].w) / 2.0 + 0.3 + float(e[2].w) / 2.0 * cos(th)) / sin(th))
		stops[e[0]] = minf(need, maxf(radius + 1.2, float(e[1]) * cap))
		# and back out of the way of another junction a few metres off to the side (two streets
		# that meet a main road a car's length apart): the nose waits clear of its box too
		for m: int in _near_nodes(map.g_pos[n], 1.0, 20.0):
			if m == e[0] or map.g_adj[m].size() < 3: continue
			var to_m := map.g_pos[m] - map.g_pos[n]
			if absf(ui.angle_to(to_m)) < 0.5: continue
			var rm := 4.0
			for f in map.g_adj[m]: rm = maxf(rm, float(f[2].w) / 2.0 + 2.0)
			var along := to_m.dot(ui)
			var off := absf(to_m.cross(ui))
			if off < rm + 1.0:
				var back := along + sqrt((rm + 1.0) * (rm + 1.0) - off * off) + 1.0
				if back < float(e[1]) * 0.8: stops[e[0]] = maxf(float(stops[e[0]]), back)
	# how far out a car leaving is still in the way: where two roads meet at a sharp angle their
	# lanes lie over each other well past the box
	var clear := radius
	for e in map.g_adj[n]:
		var ue := (map.g_pos[e[0]] - map.g_pos[n]).normalized()
		for f in map.g_adj[n]:
			if f[0] == e[0]: continue
			var th := absf(ue.angle_to((map.g_pos[f[0]] - map.g_pos[n]).normalized()))
			if th < deg_to_rad(70.0): clear = maxf(clear, minf(18.0, (float(e[2].w) + float(f[2].w)) / 2.0 / sin(maxf(th, 0.3))))
	return { "control": control, "majors": majors, "radius": radius, "queue": [], "inside": [],
		"offset": signal_offset(map.g_pos[n]), "stops": stops, "clear": clear }

## How far back from junction `n`'s middle the traffic coming in from node `from` waits.
func stop_line(n: int, from: int) -> float:
	var j: Dictionary = junctions.get(n, {})
	return float(j.get("stops", {}).get(from, float(j.get("radius", 0.0)) + 1.2))

static func signal_offset(p: Vector2) -> int:
	return absi(int(roundf(p.x)) * 7 + int(roundf(p.y)) * 13) % int(CYCLE)

## "green", "amber" or "red" for the main road (group 0) or the side roads (group 1). The lights
## run on the game clock (`clock`), the same one the drivers live by, and both ways are red for
## two seconds between greens so whoever went through on the amber is out of the box.
static func signal_state(offset: int, group: int) -> String:
	var t := fmod(clock + offset, CYCLE)
	if group == 0:
		return "green" if t < 22.0 else ("amber" if t < 25.0 else "red")
	return "green" if t >= 27.0 and t < 45.0 else ("amber" if t >= 45.0 and t < 48.0 else "red")

## How long the light stays green from now (0 if it isn't green).
static func signal_left(offset: int, group: int) -> float:
	var t := fmod(clock + offset, CYCLE)
	if group == 0: return 22.0 - t if t < 22.0 else 0.0
	return 45.0 - t if t >= 27.0 and t < 45.0 else 0.0

## How long the light's been what it is now (so a red you went through a moment after it changed
## isn't the same as one that had been red a while).
static func signal_since(offset: int, group: int) -> float:
	var t := fmod(clock + offset, CYCLE)
	if group == 0:
		if t < 22.0: return t
		if t < 25.0: return t - 22.0
		return t - 25.0
	if t < 27.0: return t + (CYCLE - 48.0)          # red since 48 the cycle before
	if t < 45.0: return t - 27.0
	if t < 48.0: return t - 45.0
	return t - 48.0

# ------------------------------------------------------------------ paths

func edge_road(a: int, b: int) -> Dictionary:
	for e in map.g_adj[a]:
		if e[0] == b: return e[2]
	return {}

## A point on the lane from node a to node b, s metres along, `lane` metres right of centre.
func lane_point(a: int, b: int, s: float, lane: float) -> Vector2:
	var A := map.g_pos[a]
	var B := map.g_pos[b]
	var d := (B - A).normalized()
	return A + d * s + Vector2(-d.y, d.x) * lane

## Choose where to go after arriving at `b` from `a`: anywhere but back, unless it's a dead end.
func next_node(a: int, b: int, car: TrafficCar) -> int:
	var opts: Array = []
	var din := (map.g_pos[b] - map.g_pos[a]).normalized()
	var lanes_in: Array = LANE[edge_road(a, b).cls]
	# where two roads fork at a shallow angle, the one bearing right is the outer lane's and the
	# one bearing left the inner lane's (or the two lanes swap across each other in the fork)
	var straightest := INF
	for e in map.g_adj[b]:
		if e[0] != a: straightest = minf(straightest, absf(din.angle_to((map.g_pos[e[0]] - map.g_pos[b]).normalized())))
	for e in map.g_adj[b]:
		if e[0] == a: continue
		var r: Dictionary = e[2]
		var dout := (map.g_pos[e[0]] - map.g_pos[b]).normalized()
		# prefer staying on bigger roads and going roughly straight; nobody wants the gravel
		var w := 1.0 + maxf(0.0, din.dot(dout)) * 2.0 + float(MapData.CLS[r.cls].rank) * 0.3
		var turn := din.angle_to(dout)
		if lanes_in.size() > 1:
			if car.lane_i == 0 and turn > 0.5: continue          # inner lane: no right turns
			if car.lane_i == 1 and turn < -0.5: continue         # outer lane: no left turns
			if absf(turn) > straightest + 0.05 and absf(turn) < 0.6 and (turn > 0.0) == (car.lane_i == 0): continue
		if r.cls == "gravel": w *= 0.3
		if car.highway_only and r.cls != "highway": continue
		# a bus or a truck turning swings its tail across the corner: it goes straight when it can
		if car.big and absf(turn) > 0.6: w *= 0.25
		# a stub that ends a few metres on is no place to go (you'd only turn round in the road),
		# nor a street laid over the main road beside it, nor a hairpin back into a junction a
		# couple of metres off (the knots where the map's roads meet in a bunch)
		if map.g_adj[e[0]].size() == 1 and float(e[1]) < 60.0: w *= 0.02
		if shadowed.has(Vector2i(b, int(e[0]))): w *= 0.01
		if absf(turn) > 2.0 or (absf(turn) > 0.6 and float(e[1]) < 9.0 and map.g_adj[e[0]].size() >= 3): w *= 0.1
		if not _in_step(a, b, int(e[0])): w *= 0.05
		opts.append([e[0], w, int(MapData.CLS[r.cls].rank)])
	if opts.is_empty(): return a
	# where three junctions sit a few metres apart (a diagonal road across the grid), don't go
	# round the little triangle and back the way you came
	var onward := opts.filter(func(o: Array) -> bool: return map.g_pos[int(o[0])].distance_to(map.g_pos[a]) > 12.0)
	if not onward.is_empty(): opts = onward
	# buses and trucks keep to the big roads when there's one to keep to
	if car.big:
		var wide := opts.filter(func(o: Array) -> bool: return int(o[2]) >= 3)
		if not wide.is_empty(): opts = wide
	var total := 0.0
	for o in opts: total += o[1]
	var roll := car.rng.randf() * total
	for o in opts:
		roll -= o[1]
		if roll <= 0.0: return o[0]
	return opts[0][0]

# ------------------------------------------------------------------ spawning

func _near_nodes(c: Vector2, rmin: float, rmax: float) -> Array:
	var out: Array = []
	var k0 := Vector2i(floori((c.x - rmax) / 64.0), floori((c.y - rmax) / 64.0))
	var k1 := Vector2i(floori((c.x + rmax) / 64.0), floori((c.y + rmax) / 64.0))
	for y in range(k0.y, k1.y + 1):
		for x in range(k0.x, k1.x + 1):
			for n in _node_cells.get(Vector2i(x, y), []):
				var d := map.g_pos[n].distance_to(c)
				if d >= rmin and d <= rmax: out.append(n)
	return out

func _target_count(c: Vector2) -> int:
	var z := map.zone_at(c)
	var mult := 1.0
	var h := sky.time_h
	if h < 6.0 or h > 23.0: mult = 0.35          # the middle of the night
	elif (h > 7.5 and h < 9.0) or (h > 16.0 and h < 18.0): mult = 1.35   # rush hour (such as it is)
	match z.style:
		"downtown", "commercial": return int(34 * mult)
		"residential", "oldtown", "industrial": return int(24 * mult)
		"village": return int(10 * mult)
	var rd := map.nearest_road(c, 80.0)
	if not rd.is_empty() and rd.road.cls == "highway": return int(26 * mult)
	return int(14 * mult)

func _spawn(cam_m: Vector2) -> void:
	var fwd := _heading_of_player()
	# out on the open road, moving: half of them come out just past the edge of the screen up the
	# road you're on, so there's somebody to pass and somebody coming the other way
	if fwd != Vector2.ZERO and rng.randf() < 0.5:
		for k in 3:
			if _spawn_ahead(cam_m, fwd): return
	# (on the move, from just off the screen; sat still, further out, where they've had time to
	# sort themselves out by the time they get to you)
	var near := _spawn_min() if fwd != Vector2.ZERO else SPAWN_MIN
	var nodes := _near_nodes(cam_m, near, SPAWN_MAX)
	if nodes.is_empty(): return
	# when you're on the move, most of them come out up ahead, where you'll meet them
	if fwd != Vector2.ZERO:
		var ahead := nodes.filter(func(n: int) -> bool: return (map.g_pos[n] - cam_m).normalized().dot(fwd) > 0.45)
		if ahead.size() >= 2 and rng.randf() < 0.75: nodes = ahead
	for attempt in 10:
		var a: int = nodes[rng.randi() % nodes.size()]
		var adj: Array = map.g_adj[a]
		if adj.is_empty(): continue
		var e: Array = adj[rng.randi() % adj.size()]
		var b: int = e[0]
		var road: Dictionary = e[2]
		var L := map.g_pos[a].distance_to(map.g_pos[b])
		if L < 6.0 or shadowed.has(Vector2i(a, b)): continue
		var lanes: Array = LANE[road.cls]
		var lane: float = lanes[rng.randi() % lanes.size()]
		# not in a junction or its queue, and well clear of every other car
		var ja: float = junctions.get(a, {}).get("radius", 0.0) + 6.0
		var jb: float = junctions.get(b, {}).get("radius", 0.0) + 22.0
		if L < ja + jb + 2.0: continue
		var s := ja + rng.randf() * (L - ja - jb)
		var p := lane_point(a, b, s, lane)
		if p.distance_to(cam_m) < near * 0.9 or hush.has_point(p): continue
		if _place_car(a, b, s, lane, road, p): return

## How near the camera a car can turn up: just past the corners of the screen (in close in town,
## further out at speed or with the camera pulled back), never nearer than 60 m nor further than
## SPAWN_MIN.
func _spawn_min() -> float:
	if CarView.view_radius <= 0.0: return SPAWN_MIN
	return clampf(CarView.view_radius / PX + 30.0, 60.0, SPAWN_MIN)

## A car on the road you're on (or the one coming at you down it), 70 to 160 m up ahead (on a
## town street, from just off the screen): out of sight, close enough to meet. False if there's
## no stretch of open road there.
func _spawn_ahead(cam_m: Vector2, fwd: Vector2) -> bool:
	var rd := map.nearest_road(cam_m, 14.0)
	if rd.is_empty() or not String(rd.road.cls) in ["highway", "rural", "arterial", "street"]: return false
	var near := _spawn_min() if String(rd.road.cls) == "street" else 70.0
	# the graph edge you're driving along
	var best := []
	var best_d := 14.0
	for n in _near_nodes(cam_m, 0.0, 600.0):
		for e in map.g_adj[n]:
			var A := map.g_pos[n]
			var B := map.g_pos[e[0]]
			if (B - A).normalized().dot(fwd) < 0.7: continue
			var dd := MapData.seg_dist(cam_m, A, B)
			if dd < best_d:
				best_d = dd
				best = [n, e[0], e[2]]
	if best.is_empty(): return false
	var road: Dictionary = best[2]
	var a: int = best[0]
	var b: int = best[1]
	var against := rng.randf() < 0.45
	var A2 := map.g_pos[a]
	var L := A2.distance_to(map.g_pos[b])
	var s := (cam_m - A2).dot((map.g_pos[b] - A2).normalized()) + rng.randf_range(near, 160.0)
	if against:
		# coming the other way down the same road
		var t := a
		a = b
		b = t
		s = L - s
	var ja: float = junctions.get(a, {}).get("radius", 0.0) + 6.0
	var jb: float = junctions.get(b, {}).get("radius", 0.0) + 22.0
	if s < ja or s > L - jb: return false
	var lanes: Array = LANE[road.cls]
	var lane: float = lanes[rng.randi() % lanes.size()]
	var p := lane_point(a, b, s, lane)
	if hush.has_point(p): return false
	return _place_car(a, b, s, lane, road, p)

## Puts a car off the catalogue at s metres along a -> b, if it's well clear of everyone. True
## if it did.
func _place_car(a: int, b: int, s: float, lane: float, road: Dictionary, p: Vector2) -> bool:
	var z := map.zone_at(p)
	var car := TrafficCar.new()
	car.traffic = self
	car.rng.seed = rng.randi()
	var fleet := _fleet_pick(String(road.cls), String(z.get("style", "")) if String(z.get("id", "")) != "" else "rural", car.rng)
	# a semi needs the length of its trailer clear behind it too; a car in the next lane over or
	# coming the other way only needs to be clear of it
	var room := 30.0 + (24.0 if _fleet_has(fleet, "tractor") else 0.0)
	var along := (map.g_pos[b] - map.g_pos[a]).normalized()
	var clear := true
	for c in cars:
		var rel := c.pos - p
		var r2 := room if absf(rel.cross(along)) < 2.0 and Vector2.from_angle(c.heading).dot(along) > 0.0 else 14.0
		if rel.length() < r2 or (c.trailer != null and c.trailer_centre.distance_to(p) < room): clear = false
	if player and player.sim.pos.distance_to(p) < room: clear = false
	if not clear:
		car.free()
		return false
	# a car off the catalogue, picked for the part of town: rust and pickups out in the
	# country, compacts and luxury downtown
	var style := String(z.get("style", ""))
	if String(z.get("id", "")) == "" or style == "": style = "rural"
	var body: Dictionary = CarCatalog.traffic_car(fleet, car.rng, style) if fleet != "" else CarCatalog.random_traffic(car.rng, style)
	if body.is_empty():
		body = BODIES[car.rng.randi() % BODIES.size()]
		body.paint = PAINTS[car.rng.randi() % PAINTS.size()]
	body.looks = dress(body, car.rng, style, sky.season == "winter", sky.time_h)
	car.setup(body, Color(String(body.paint)), a, b, s, lane)
	car.v = minf(car.desired_speed(road) * 0.8, 12.0)
	ysort.add_child(car)
	cars.append(car)
	return true

static var _by_cue := {}            # cue -> the fleet ids that carry it

## Now and then the next car out is one of the fleet, by where and when: semis on the highway,
## school buses on weekday mornings and afternoons, city buses downtown, the garbage truck through
## the neighbourhoods in the morning, delivery trucks where the shops are, the odd ambulance.
func _fleet_pick(road_cls: String, style: String, r: RandomNumberGenerator) -> String:
	var h := sky.time_h
	var weekday := sky.day % 7 < 5
	var roll := r.randf()
	if road_cls == "highway": return _fleet_id("tractor", r) if roll < 0.2 else ""
	if road_cls in ["ramp", "gravel"]: return ""
	var town := style in ["downtown", "commercial", "residential", "oldtown", "village", "industrial"]
	var odds: Array = []
	if weekday and ((h > 7.0 and h < 9.0) or (h > 14.5 and h < 16.5)) and style in ["residential", "village", "downtown", "oldtown"]: odds.append(["schoolbus", 0.12])
	if h > 6.0 and road_cls == "arterial" and style in ["downtown", "commercial", "oldtown"]: odds.append(["bus", 0.12])
	if weekday and h > 6.0 and h < 12.0 and style in ["residential", "oldtown", "village"]: odds.append(["packer", 0.05])
	if h > 7.0 and h < 19.0 and style in ["commercial", "industrial", "downtown"]: odds.append(["delivery", 0.08])
	if town: odds.append(["ambulance", 0.012])
	for o: Array in odds:
		roll -= float(o[1])
		if roll < 0.0: return _fleet_id(String(o[0]), r)
	return ""

static func _fleet_id(cue: String, r: RandomNumberGenerator) -> String:
	if _by_cue.is_empty():
		for id in CarCatalog.fleet_ids():
			var art: Dictionary = CarCatalog.entry(id).get("art", {})
			var tagged := false
			for k: String in ["tractor", "schoolbus", "bus", "packer", "ambulance"]:
				if art.has(k):
					if not _by_cue.has(k): _by_cue[k] = []
					_by_cue[k].append(id)
					tagged = true
			if not tagged:
				if not _by_cue.has("delivery"): _by_cue["delivery"] = []
				_by_cue["delivery"].append(id)
	var pool: Array = _by_cue.get(cue, [])
	return String(pool[r.randi() % pool.size()]) if not pool.is_empty() else ""

static func _fleet_has(id: String, cue: String) -> bool:
	return id != "" and (CarCatalog.entry(id).get("art", {}) as Dictionary).has(cue)

## Somebody else's car: lived in. Clean or dirty (and salty all winter), the old ones rusting,
## sun-faded, a primer panel, a door off a car of another colour, dents; a taxi, a pizza car or a
## driving school with its sign on the roof, a work van with the business on its doors and a
## ladder up top, a pickup with something in the bed; and now and then one somebody's modded.
## Returns the mods CarArt draws (see CarArt and PixCars for the keys).
static func dress(body: Dictionary, rng: RandomNumberGenerator, style: String, winter: bool, hour: float) -> Dictionary:
	var m := {}
	var wear := {}
	var cls := String(body.get("class", ""))
	var age := CarCatalog.GAME_YEAR - int(body.get("year", 2010))
	var fam := String(body.get("body", "sedan"))
	if fam in ["bus", "semi", "boxtruck"] or cls == "fleet": return _fleet(body, rng, winter)
	var dirty := rng.randf() * (0.5 if style in ["rural", "village", "industrial"] else 0.25)
	if winter:
		wear.salt = rng.randf_range(0.35, 0.9)
		dirty += 0.15
	if dirty > 0.12: wear.dirt = dirty
	if age >= 15 and rng.randf() < 0.35: wear.faded = rng.randf_range(0.25, 0.8)
	if age >= 8 and rng.randf() < 0.3: wear.dents = rng.randf_range(0.2, 0.7)
	if age >= 14 and rng.randf() < 0.08: wear.primer = ["hood", "fender", "door", "trunk"][rng.randi() % 4]
	elif age >= 12 and rng.randf() < 0.05: wear.door = PAINTS[rng.randi() % PAINTS.size()]
	var art: Dictionary = body.get("art", {})
	if art.has("rust"): wear.rust = float(art.rust)
	if not wear.is_empty(): m.wear = wear
	# a job on the roof or on the doors
	var town := style in ["downtown", "commercial", "oldtown", "residential"]
	if cls in ["sedan", "compact", "economy"] and age < 20:
		var roll := rng.randf()
		if town and style != "residential" and roll < 0.06: m.sign = "taxi"
		elif town and (hour > 16.0 or hour < 1.0) and roll < 0.09:
			m.sign = "pizza"
			m.decal = 3
		elif town and hour > 8.0 and hour < 18.0 and roll < 0.11: m.sign = "school"
	if cls in ["van", "work_truck"] or (fam in ["pickup", "van"] and rng.randf() < 0.3):
		if rng.randf() < 0.55: m.decal = rng.randi() % CarArt.DECALS.size()
		if rng.randf() < 0.4 and not art.has("ladder"): m.ladder = true
	if fam == "pickup" and not art.has("toolbox") and rng.randf() < 0.4:
		m.load = ["lumber", "firewood", "boxes", "mulch"][rng.randi() % 4]
	# somebody's project
	if cls in ["jdm", "sports", "hot_hatch", "muscle", "pony", "coupe", "compact"] and age < 35 and rng.randf() < 0.18:
		var p := rng.randf()
		m.rim = PixCars.RIMS[rng.randi() % 7]
		if p < 0.6: m.drop = rng.randf_range(0.3, 0.9)
		if p < 0.4: m.spoiler = ["ducktail", "wing", "gt"][rng.randi() % 3]
		if p < 0.3: m.stripes = ["racing", "side", "rally"][rng.randi() % 3]
		if p < 0.5: m.tint = 0.75
		m.exhaust = ["dual", "quad", "single"][rng.randi() % 3]
	return m

## A fleet vehicle (a bus, a truck): cleaner, the outfit's colours and its name on the side.
static func _fleet(body: Dictionary, rng: RandomNumberGenerator, winter: bool) -> Dictionary:
	var m := {}
	var wear := {}
	if winter: wear.salt = rng.randf_range(0.3, 0.7)
	if rng.randf() < 0.4: wear.dirt = rng.randf_range(0.15, 0.4)
	if not wear.is_empty(): m.wear = wear
	var art: Dictionary = body.get("art", {})
	if art.has("decal"): m.decal = int(art.decal)
	elif String(body.get("body", "")) == "boxtruck" and rng.randf() < 0.6: m.decal = rng.randi() % CarArt.DECALS.size()
	return m

# ------------------------------------------------------------------ the frame

func step(dt: float, cam_m: Vector2) -> void:
	clock += dt
	if not enabled: return
	night = sky.lights_on(30)
	# who's where (a 20 m grid), for finding the car ahead
	_grid = {}
	for c in cars:
		_put(c.pos, c)
		if c.trailer != null and absf(c.trailer_centre.x - c.pos.x) + absf(c.trailer_centre.y - c.pos.y) > 4.0: _put(c.trailer_centre, c)
	# despawn the far ones (sooner the ones you've left behind), spawn new ones out of sight
	var fwd := _heading_of_player()
	for i in range(cars.size() - 1, -1, -1):
		var c := cars[i]
		# wrecks get towed once you've moved on
		if c.state == "parked" and ((c.wreck_t > 20.0 and c.pos.distance_to(cam_m) > 60.0) or c.wreck_t > 40.0): c.gone = true
		var behind := fwd != Vector2.ZERO and c.pos.distance_to(cam_m) > SPAWN_MAX and (c.pos - cam_m).normalized().dot(fwd) < -0.3
		if c.pos.distance_to(cam_m) > DESPAWN or behind or c.gone or (hush.has_point(c.pos) and c.pos.distance_to(cam_m) > 90.0):
			_leave_junctions(c)
			c.queue_free()
			cars.remove_at(i)
	_spawn_t -= dt
	var want := _target_count(cam_m)
	if _spawn_t <= 0.0 and cars.size() < want:
		_spawn_t = 0.25
		# well short (you've just come into town, or off the highway onto it): a few at a time
		for k in (3 if cars.size() < want * 0.6 else 1): _spawn(cam_m)
	for c in cars: c.drive(dt)

## Which way you're going, if you're going anywhere much (zero when you're stopped or crawling).
func _heading_of_player() -> Vector2:
	if player == null: return Vector2.ZERO
	var vel := player.sim.world_velocity()
	return vel.normalized() if vel.length() > 5.0 else Vector2.ZERO

func _put(p: Vector2, c) -> void:
	var k := Vector2i(floori(p.x / 20.0), floori(p.y / 20.0))
	if not _grid.has(k): _grid[k] = []
	_grid[k].append(c)

## The nearest thing on `car`'s own path within `reach` metres: [gap (m), its speed along
## the path, what it is]. The path is the lane it will actually drive (round the corner if
## it's turning), so cars waiting on the cross street or coming the other way don't count.
func leader(car: TrafficCar, reach: float) -> Array:
	var best: Array = [INF, 0.0, null]
	var path := car._path if car._path.size() > 1 else car.path_ahead(reach)
	if path.size() < 2: return best
	var k0 := Vector2i(floori((car.pos.x - reach) / 20.0), floori((car.pos.y - reach) / 20.0))
	var k1 := Vector2i(floori((car.pos.x + reach) / 20.0), floori((car.pos.y + reach) / 20.0))
	for y in range(k0.y, k1.y + 1):
		for x in range(k0.x, k1.x + 1):
			for o in _grid.get(Vector2i(x, y), []):
				if o == car: continue
				# two cars each waiting on the other: the older one goes (but nobody drives on into
				# a car that's still moving, whoever it thinks is in its way)
				if o.lead_obj == car and car.get_instance_id() < o.get_instance_id() and o.state == "drive" and car.v < 1.0 and o.v < 1.0: continue
				_consider(car, path, o.pos, o.velocity_vec(), o.length, o.width, best, o)
				if o.trailer != null: _consider(car, path, o.trailer_centre, o.velocity_vec(), o.trailer_len, o.width, best, o)
	if player and not ignore_player:
		_consider(car, path, player.sim.pos, player.sim.world_velocity(), float(player.spec.length) * CarArt.CAR_SCALE, float(player.spec.width) * CarArt.CAR_SCALE, best, player)
	for o in extra:
		if is_instance_valid(o):
			var oc: PlayerCar = o
			_consider(car, path, oc.sim.pos, oc.sim.world_velocity(), float(oc.spec.length) * CarArt.CAR_SCALE, float(oc.spec.width) * CarArt.CAR_SCALE, best, oc)
	return best

func _consider(car: TrafficCar, path: PackedVector2Array, p: Vector2, vel: Vector2, olen: float, owid: float, best: Array, who) -> void:
	if p.distance_squared_to(car.pos) > 70.0 * 70.0: return
	var along := 0.0
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var seg := b - a
		var L := seg.length()
		if L < 0.01: continue
		var t := clampf((p - a).dot(seg) / (L * L), 0.0, 1.0)
		var q := a + seg * t
		var off := p.distance_to(q)
		if off < (owid + car.width) * 0.5 + 0.4:
			var dir := seg / L
			# oncoming traffic passing in its own lane brushes our corner-cut path; ignore it
			# unless it's really in the way (square in our lane, coming at us)
			if vel.dot(dir) < -1.0 and along + L * t > 8.0 and off > (owid + car.width) * 0.5 - 0.8: return
			# coming straight at us in our lane counts; crossing or going away counts too
			var gap := along + L * t - (car.length + olen) * 0.5
			if gap < best[0]:
				best[0] = gap
				best[1] = vel.dot(dir)
				best[2] = who
			return
		along += L

# ------------------------------------------------------------------ intersections

## Can this car enter junction `n`, coming from node `from` and heading for `to`?
## Returns "go", "stop" (at the line) or "yield" (slow, then go when clear).
func may_enter(car: TrafficCar, n: int, from: int, to: int, dist: float) -> String:
	var j: Dictionary = junctions.get(n, {})
	if j.is_empty(): return "go"
	var road: Dictionary = edge_road(from, n)
	var major: bool = j.majors.has(int(road.get("idx", -1)))
	# at a stop sign, once you've pulled out you keep going (stopping halfway is how you get hit)
	if String(j.control) != "signal" and j.inside.has(car): return "go"
	# a red light is a red light, however long you've sat at it: it'll go green
	if String(j.control) == "signal":
		var st := signal_state(int(j.offset), 0 if major else 1)
		if st == "red" or (st == "amber" and dist >= car.v * car.v / (2.0 * 3.5)):   # amber: stop if you can
			# ("amber": it's only just changed, and a car that can't stop for it now goes on through)
			return _stop(car, "amber" if st == "amber" or signal_since(int(j.offset), 0 if major else 1) < 1.5 else "light")
		# green, but somebody who came in the other way is still getting across: let them clear it
		if _crossing(car, n, j, major): return _stop(car, "crossing")
	# whoever is already crossing (or too close to stop) where we'd cross goes first, whatever
	# the sign or the light says: a left turner still finishing, the last one through on the amber
	var other: TrafficCar = _conflict(car, n, from, dist)
	if other != null: return _stop(car, "wide" if other.big else "conflict")
	# don't block the box: is there room on the far side?
	if not _room_after(car, n, to): return _stop(car, "room")
	# a block too short to wait in: go only when the next junction will take you straight through
	if not _through_next(car, n, to): return _stop(car, "block")
	# a bus or a truck turning swings across the road it's turning into: not while somebody's
	# waiting at the line there (at a light they'd never move; there it waits its turn)
	if car.big and absf(car.turn_ahead) > 0.5 and String(j.control) != "signal" and car.wait_t < 30.0 and _waiting_on(car, n, to): return _stop(car, "swing")
	# turning left: oncoming traffic goes first (unless it's sitting there waving you through)
	if car.turn_ahead < -0.5 and not _oncoming_clear(car, n, from, dist): return _stop(car, "oncoming")
	# a driver who has sat there for 45 s with an empty box in front of them goes anyway (but
	# doesn't pull out under a car on the main road)
	if car.wait_t > 45.0 and _box_empty(car, n, float(j.radius)) and (String(j.control) != "priority" or major or _main_clear(car, n, j, 2.5)):
		enter(car, n)
		return "go"
	# gridlock (two junctions a car's length apart, each with somebody waiting in it for the
	# other): after a minute, ease through past whoever's sat in the box waiting on the next one
	if car.wait_t > 60.0 and String(j.control) != "signal" and _only_waiting_in(car, n, float(j.radius)):
		enter(car, n)
		return "go"
	match String(j.control):
		"signal":
			return "go"
		"priority":
			if major: return "go"
			if car.stopped_at != n: return _stop(car, "full stop")         # a full stop first
			# after a long wait a smaller gap will do (but never one the main road can't brake for)
			if _main_clear(car, n, j, 6.0 if car.wait_t < 15.0 else 2.5):
				enter(car, n)         # claim it now, before anyone else decides the same thing
				return "go"
			return _stop(car, "main road")
		"allway":
			if car.stopped_at != n: return _stop(car, "full stop")
			if car.wait_t > 6.0 and _box_empty(car, n, j.radius):   # everybody waved
				enter(car, n)
				return "go"
			# first to stop goes first, once the box is empty
			if not _box_empty(car, n, j.radius): return _stop(car, "box")
			for c in cars:
				if c != car and c.stopped_at == n and c.b == n and c.stop_time < car.stop_time: return _stop(car, "turn")
			enter(car, n)
			return "go"
	return "go"

## "stop", noting why on the car (the soak test prints it when somebody's stuck).
static func _stop(car: TrafficCar, why: String) -> String:
	car.why = why
	return "stop"

func _room_after(car: TrafficCar, n: int, to: int) -> bool:
	var r2 := edge_road(n, to)
	if r2.is_empty(): return true
	var lanes: Array = LANE[r2.cls]
	# a long one needs its whole length clear past the box
	var room := 12.0 + maxf(0.0, car.length - 6.0)
	var exit := lane_point(n, to, room, lanes[mini(car.lane_i, lanes.size() - 1)])
	for c in cars:
		if c == car: continue
		if c.a == n and c.b == to and c.s < room and c.v < 2.0: return false
		if c.a == n and c.b == to and c.s < 9.0 + maxf(0.0, c.length - 6.0): return false     # someone just went through: let them get clear
		if c.pos.distance_to(exit) < 2.5 and c.v < 1.0: return false
	return true

## Somebody still in signal junction `n` who came in from the other light's roads (a slow left
## turner, the last one through on the amber), close enough to be in the way.
func _crossing(car: TrafficCar, n: int, j: Dictionary, major: bool) -> bool:
	var jp := map.g_pos[n]
	for c in j.inside:
		if c == car or not is_instance_valid(c) or not c.boxes.has(n): continue
		var their: bool = j.majors.has(int(edge_road(int(c.boxes[n]), n).get("idx", -1)))
		if their != major and c.pos.distance_to(jp) < float(j.get("clear", j.radius)) + 3.0: return true
	# and the last one through on the amber, not in the box yet but not stopping either
	for c in cars:
		if c == car or c.b != n or c.boxes.has(n) or c.last_rule != "go" or c.v < 2.0: continue
		var theirs: bool = j.majors.has(int(edge_road(c.a, n).get("idx", -1)))
		if theirs != major and c.pos.distance_to(jp) < stop_line(n, c.a) + c.v * 1.5: return true
	return false

## The block from `n` to `to` is long enough to wait in past n's box, or the junction at its end
## won't make you wait (a green with time left on it), and nobody's sat in the block already.
## Otherwise a car would wait for the next light with its tail across this junction.
func _through_next(car: TrafficCar, n: int, to: int) -> bool:
	var jt: Dictionary = junctions.get(to, {})
	if jt.is_empty() or to == n: return true
	var L := map.g_pos[n].distance_to(map.g_pos[to])
	if L - stop_line(to, n) - float(junctions[n].radius) >= car.length + 1.0: return true
	for c in cars:
		if c != car and c.a == n and c.b == to: return false
	# (two lights whose greens hardly overlap, a stop sign that never clears: after a while you
	# go and wait in the block anyway, if there's a block to wait in and not just the middle of
	# this junction or the next one)
	if car.wait_t > 25.0 and L - stop_line(to, n) - float(junctions[n].radius) > -2.0 or car.wait_t > 50.0: return true
	var major: bool = jt.majors.has(int(edge_road(n, to).get("idx", -1)))
	if String(jt.control) == "signal":
		# (from a standstill it's slower across than the speed limit says)
		var d := L + float(jt.radius) + car.length
		return signal_left(int(jt.offset), 0 if major else 1) > 2.0 + (sqrt(car.v * car.v + 2.0 * car.a_max * d) - car.v) / car.a_max
	# a stop sign at the end of the block: only once it looks like you'll be straight through it
	# (from a standstill here, across this junction and that one, before the main road gets there)
	var across := L + float(junctions[n].radius) + float(jt.radius) * 2.0 + car.length
	var t_clear := (sqrt(car.v * car.v + 2.0 * car.a_max * across) - car.v) / car.a_max
	return _box_empty(car, to, float(jt.radius)) and (major and String(jt.control) == "priority" or _main_clear(car, to, jt, maxf(6.0, t_clear + 1.0)))

## Going from `a` through signal `b` to signal `c` a few metres on is fine if c's green for that
## road comes on with b's (a knot of lights that can't all line up leaves some ways out of step:
## you'd sit at the second red with your tail across the first junction).
func _in_step(a: int, b: int, c: int) -> bool:
	var jb: Dictionary = junctions.get(b, {})
	var jc: Dictionary = junctions.get(c, {})
	if String(jb.get("control", "")) != "signal" or String(jc.get("control", "")) != "signal": return true
	var L := map.g_pos[b].distance_to(map.g_pos[c])
	if L - stop_line(c, b) - float(jb.radius) > 6.0: return true
	var start := [0.0, 27.0]
	var gb := 0 if jb.majors.has(int(edge_road(a, b).get("idx", -1))) else 1
	var gc := 0 if jc.majors.has(int(edge_road(b, c).get("idx", -1))) else 1
	var lag := fposmod((start[gc] - float(jc.offset)) - (start[gb] - float(jb.offset)), CYCLE)
	return lag < 6.0 or lag > CYCLE - 6.0

## Nobody coming the other way toward junction `n` soon (for a left turn across their lane),
## and nobody from the other side still crossing it: a left turner coming the other way cuts
## through the same middle. The longer you've waited, the smaller the gap you'll take, but
## never one they'd have to stand on the brakes for.
func _oncoming_clear(car: TrafficCar, n: int, from: int, dist := 0.0) -> bool:
	var jp := map.g_pos[n]
	var din := (jp - map.g_pos[from]).normalized()
	var keen := clampf((car.wait_t - 10.0) / 20.0, 0.0, 1.0)
	# from a standstill it takes a while to get across a wide junction: long enough that they
	# can't get there first
	var across := float(junctions[n].radius) * 2.0 + car.length + maxf(dist, 0.0)
	var t_clear := (sqrt(car.v * car.v + 2.0 * car.a_max * across) - car.v) / car.a_max
	var window := maxf(lerpf(3.5, 2.0, keen), t_clear * lerpf(1.0, 0.8, keen))
	for c in cars:
		if c == car or c.state != "drive": continue
		if c.boxes.has(n) and (jp - map.g_pos[int(c.boxes[n])]).normalized().dot(din) < -0.7: return false
		var d := _dist_to(c, n)
		if d == INF: continue
		var near_n: bool = c.b == n or c.c_next == n
		var cd := (jp - map.g_pos[c.a if c.b == n else c.b]).normalized() if near_n else Vector2.from_angle(c.heading)
		if cd.dot(din) < -0.7:
			if d < 6.0 + c.v * window and not (c.v < 0.5 and c.last_rule == "stop"): return false
	return true

## Somebody whose line through junction `n` crosses (or merges into) the one `car` would take,
## who is in the box already or too close and too quick to stop before it (null if nobody).
## Somebody from the same road and lane is just ahead (the leader minds them), and somebody sat
## in the box waiting on `car` itself doesn't count (one of the two has to go).
func _conflict(car: TrafficCar, n: int, from: int, dist: float) -> TrafficCar:
	var j: Dictionary = junctions[n]
	var jp := map.g_pos[n]
	var r := float(j.get("clear", j.radius)) + 2.0
	var who: Array = []
	for c in cars:
		if c == car or c.state != "drive" or c.pos.distance_squared_to(jp) > 70.0 * 70.0: continue
		if c.boxes.has(n):
			# (in from the same road in the same lane: just ahead of us, the leader minds them; in
			# the lane beside us, a bus swinging out of it still counts)
			if int(c.boxes[n]) == from and c.lane_i == car.lane_i or c.pos.distance_to(jp) > r + c.length * 0.5: continue
			if c.v < 0.3 and c.lead_obj == car: continue
			# (both sat there waiting on the other: whoever's waited longest goes; the car in front
			# still stops it if they're really in its way)
			if c.v < 0.3 and c.last_rule == "stop" and car.v < 0.3 and car.wait_t > 10.0 \
				and (car.wait_t > c.wait_t + 5.0 or car.wait_t > c.wait_t - 5.0 and car.get_instance_id() < c.get_instance_id()): continue
			who.append(c)
		elif c.b == n and c.a != from:
			var to_line := c.pos.distance_to(jp) - stop_line(n, c.a)
			# over its line already (off a link shorter than the line's set back), or coming too
			# quick to stop short of it
			# (two of those both sat waiting on each other: the older one goes)
			if to_line < -0.5 and not (c.v < 0.3 and c.last_rule == "stop" and c.get_instance_id() > car.get_instance_id()) \
				or c.last_rule == "go" and c.v > 2.0 and to_line < c.v * c.v / (2.0 * 3.5) + c.v * 0.3 + 1.0: who.append(c)
	if who.is_empty(): return null
	var mine := _in_box(car.path_ahead(car.pos.distance_to(jp) + r + 6.0), jp, r)
	if mine.size() < 2: return null
	for c: TrafficCar in who:
		var theirs := _in_box(c.path_ahead(c.pos.distance_to(jp) + r + 6.0), jp, r)
		# (a bus's ends swing well wide of the line its middle drives)
		var swing := maxf(0.0, maxf(car.length, c.length) * 0.5 - 3.0) * 0.5
		if theirs.size() >= 2 and _paths_meet(mine, theirs, (car.width + c.width) * 0.5 + 0.3 + swing): return c
	return null

## The part of a path inside the circle `r` round `jp` (and a point either side).
static func _in_box(path: PackedVector2Array, jp: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in path.size():
		if path[i].distance_to(jp) < r:
			if out.is_empty() and i > 0: out.append(path[i - 1])
			out.append(path[i])
		elif not out.is_empty():
			out.append(path[i])
			break
	return out

## Two polylines cross, or come within `tol` metres of each other somewhere (but two lanes
## running past each other the opposite way only count where they actually cross).
static func _paths_meet(p: PackedVector2Array, q: PackedVector2Array, tol: float) -> bool:
	for i in p.size() - 1:
		for k in q.size() - 1:
			if Geometry2D.segment_intersects_segment(p[i], p[i + 1], q[k], q[k + 1]) != null: return true
			if (p[i + 1] - p[i]).normalized().dot((q[k + 1] - q[k]).normalized()) < -0.85: continue
			var d := minf(minf(p[i].distance_to(Geometry2D.get_closest_point_to_segment(p[i], q[k], q[k + 1])), p[i + 1].distance_to(Geometry2D.get_closest_point_to_segment(p[i + 1], q[k], q[k + 1]))),
				minf(q[k].distance_to(Geometry2D.get_closest_point_to_segment(q[k], p[i], p[i + 1])), q[k + 1].distance_to(Geometry2D.get_closest_point_to_segment(q[k + 1], p[i], p[i + 1]))))
			if d < tol: return true
	return false

## How far `c` has to drive to junction `n`: on the road into it, or on the one before that (the
## block between two junctions can be shorter than a few seconds of driving), or further out on a
## road that runs on into it (a winding highway is many short edges), as the crow flies, if it's
## headed this way. INF if none of those.
func _dist_to(c: TrafficCar, n: int) -> float:
	if c.b == n: return c.pos.distance_to(map.g_pos[n])
	if c.c_next == n: return c.pos.distance_to(map.g_pos[c.b]) + map.g_pos[c.b].distance_to(map.g_pos[n])
	var to_j := map.g_pos[n] - c.pos
	var d := to_j.length()
	if d <= 1.0 or d >= 140.0 or Vector2.from_angle(c.heading).dot(to_j / d) < 0.85: return INF
	# (on one of the junction's own roads, not a road that only passes near it)
	var ri := int(edge_road(c.a, c.b).get("idx", -1))
	for e in map.g_adj[n]:
		if int(e[2].idx) == ri: return d * 1.08
	return INF

## Somebody coming into junction `n` down the road `car` is turning onto, near the line.
func _waiting_on(car: TrafficCar, n: int, to: int) -> bool:
	var reach := stop_line(n, to) + 8.0
	for c in cars:
		if c != car and c.a == to and c.b == n and c.pos.distance_to(map.g_pos[n]) < reach: return true
	return false

## Nobody (but `car`) in the middle of junction `n`.
func _box_empty(car: TrafficCar, n: int, radius: float) -> bool:
	var jp := map.g_pos[n]
	for c in junctions.get(n, {}).get("inside", []):
		# (somebody on the list but long gone down the road isn't in anybody's way)
		if c != car and is_instance_valid(c) and c.pos.distance_to(jp) < radius + 15.0: return false
	for c in cars:
		if c != car and c.pos.distance_to(jp) < radius + 0.5: return false
		if c != car and c.trailer != null and c.trailer_centre.distance_to(jp) < radius + c.trailer_len * 0.5: return false
	if player and not ignore_player and player.sim.pos.distance_to(jp) < radius + 1.0: return false
	return true

## Everybody in junction `n`'s box (but `car`) is stopped there waiting on the junction after it.
func _only_waiting_in(car: TrafficCar, n: int, radius: float) -> bool:
	var jp := map.g_pos[n]
	for c in cars:
		if c == car or c.pos.distance_to(jp) >= radius + 0.5: continue
		if c.b == n or c.v > 0.5: return false
	return true

## Nothing on the main road due at junction `n` within `window` seconds (and the box empty).
func _main_clear(car: TrafficCar, n: int, j: Dictionary, window := 6.0) -> bool:
	var jp := map.g_pos[n]
	if not _box_empty(car, n, j.radius): return false
	for c in cars:
		if c == car: continue
		var d := _dist_to(c, n)
		if d == INF: continue
		var r: Dictionary = edge_road(c.a if c.b == n else c.b, n)
		if r.is_empty(): r = edge_road(c.a, c.b)
		if not j.majors.has(int(r.get("idx", -1))): continue
		if d < 8.0 + c.v * window: return false
	if player and not ignore_player:
		var d := player.sim.pos.distance_to(jp)
		var closing := -player.sim.world_velocity().dot((player.sim.pos - jp).normalized())
		# parked at the corner, you're not coming (_box_empty minds you if you're in the box)
		if (d < 10.0 and closing > 0.3) or (closing > 1.0 and d < closing * window * 0.67): return false
	return true

func enter(car: TrafficCar, n: int) -> void:
	var j: Dictionary = junctions.get(n, {})
	if j.is_empty(): return
	if not j.inside.has(car): j.inside.append(car)
	j.queue.erase(car)

func leave(car: TrafficCar, n: int) -> void:
	var j: Dictionary = junctions.get(n, {})
	if j.is_empty(): return
	j.inside.erase(car)
	j.queue.erase(car)

func _leave_junctions(car: TrafficCar) -> void:
	for n in junctions:
		junctions[n].inside.erase(car)
		junctions[n].queue.erase(car)
