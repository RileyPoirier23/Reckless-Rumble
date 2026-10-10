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
var hush := Rect2()            # a street race is on in here: Marco's crew has the side streets blocked
var junctions := {}                 # node -> { control, major_roads, radius, queue, offset }
var _node_cells := {}               # Vector2i -> Array of node ids (64 m cells)
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
		if map.g_adj[n].size() >= 3: junctions[n] = _junction(n)

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
		for f in map.g_adj[n]:
			if f[0] == e[0]: continue
			var th := absf(ui.angle_to((map.g_pos[f[0]] - map.g_pos[n]).normalized()))
			if th < deg_to_rad(15.0) or th > deg_to_rad(75.0): continue
			need = maxf(need, (float(f[2].w) / 2.0 + 0.3 + float(e[2].w) / 2.0 * cos(th)) / sin(th))
		stops[e[0]] = minf(need, maxf(radius + 1.2, float(e[1]) * 0.6))
	return { "control": control, "majors": majors, "radius": radius, "queue": [], "inside": [],
		"offset": signal_offset(map.g_pos[n]), "stops": stops }

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
	for e in map.g_adj[b]:
		if e[0] == a: continue
		var r: Dictionary = e[2]
		var dout := (map.g_pos[e[0]] - map.g_pos[b]).normalized()
		# prefer staying on bigger roads and going roughly straight; nobody wants the gravel
		var w := 1.0 + maxf(0.0, din.dot(dout)) * 2.0 + float(MapData.CLS[r.cls].rank) * 0.3
		var turn := din.angle_to(dout)
		var lanes_in: Array = LANE[edge_road(a, b).cls]
		if lanes_in.size() > 1:
			if car.lane_i == 0 and turn > 0.5: continue          # inner lane: no right turns
			if car.lane_i == 1 and turn < -0.5: continue         # outer lane: no left turns
		if r.cls == "gravel": w *= 0.3
		opts.append([e[0], w])
	if opts.is_empty(): return a
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
		"downtown", "commercial": return int(30 * mult)
		"residential", "oldtown", "industrial": return int(20 * mult)
		"village": return int(10 * mult)
	var rd := map.nearest_road(c, 80.0)
	if not rd.is_empty() and rd.road.cls == "highway": return int(16 * mult)
	return int(8 * mult)

func _spawn(cam_m: Vector2) -> void:
	var nodes := _near_nodes(cam_m, SPAWN_MIN, SPAWN_MAX)
	if nodes.is_empty(): return
	for attempt in 6:
		var a: int = nodes[rng.randi() % nodes.size()]
		var adj: Array = map.g_adj[a]
		if adj.is_empty(): continue
		var e: Array = adj[rng.randi() % adj.size()]
		var b: int = e[0]
		var road: Dictionary = e[2]
		var L := map.g_pos[a].distance_to(map.g_pos[b])
		if L < 6.0: continue
		var lanes: Array = LANE[road.cls]
		var lane: float = lanes[rng.randi() % lanes.size()]
		# not in a junction or its queue, and well clear of every other car
		var ja: float = junctions.get(a, {}).get("radius", 0.0) + 6.0
		var jb: float = junctions.get(b, {}).get("radius", 0.0) + 22.0
		if L < ja + jb + 2.0: continue
		var s := ja + rng.randf() * (L - ja - jb)
		var p := lane_point(a, b, s, lane)
		if p.distance_to(cam_m) < SPAWN_MIN * 0.9 or hush.has_point(p): continue
		var clear := true
		for c in cars:
			if c.pos.distance_to(p) < 30.0: clear = false
		if player and player.sim.pos.distance_to(p) < 30.0: clear = false
		if not clear: continue
		var car := TrafficCar.new()
		car.traffic = self
		car.rng.seed = rng.randi()
		# a car off the catalogue, picked for the part of town: rust and pickups out in the
		# country, compacts and luxury downtown
		var z := map.zone_at(p)
		var style := String(z.get("style", ""))
		if String(z.get("id", "")) == "" or style == "": style = "rural"
		var body: Dictionary = CarCatalog.random_traffic(car.rng, style)
		if body.is_empty():
			body = BODIES[car.rng.randi() % BODIES.size()]
			body.paint = PAINTS[car.rng.randi() % PAINTS.size()]
		car.setup(body, Color(String(body.paint)), a, b, s, lane)
		car.v = minf(car.desired_speed(road) * 0.8, 12.0)
		ysort.add_child(car)
		cars.append(car)
		return

# ------------------------------------------------------------------ the frame

func step(dt: float, cam_m: Vector2) -> void:
	clock += dt
	if not enabled: return
	night = sky.lights_on(30)
	# who's where (a 20 m grid), for finding the car ahead
	_grid = {}
	for c in cars: _put(c.pos, c)
	# despawn the far ones, spawn new ones out of sight
	for i in range(cars.size() - 1, -1, -1):
		var c := cars[i]
		# wrecks get towed once you've moved on
		if c.state == "parked" and ((c.wreck_t > 20.0 and c.pos.distance_to(cam_m) > 60.0) or c.wreck_t > 40.0): c.gone = true
		if c.pos.distance_to(cam_m) > DESPAWN or c.gone or (hush.has_point(c.pos) and c.pos.distance_to(cam_m) > 90.0):
			_leave_junctions(c)
			c.queue_free()
			cars.remove_at(i)
	_spawn_t -= dt
	if _spawn_t <= 0.0 and cars.size() < _target_count(cam_m):
		_spawn_t = 0.25
		_spawn(cam_m)
	for c in cars: c.drive(dt)

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
				# two cars each waiting on the other: the older one goes
				if o.lead_obj == car and car.get_instance_id() < o.get_instance_id() and o.state == "drive": continue
				_consider(car, path, o.pos, o.velocity_vec(), o.length, o.width, best, o)
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
		if p.distance_to(q) < (owid + car.width) * 0.5 + 0.4:
			var dir := seg / L
			# oncoming traffic passing in its own lane brushes our corner-cut path; ignore it
			# unless it's really in the way
			if vel.dot(dir) < -1.0 and along + L * t > 8.0: return
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
	# a red light is a red light, however long you've sat at it: it'll go green
	if String(j.control) == "signal":
		var st := signal_state(int(j.offset), 0 if major else 1)
		if st == "red" or (st == "amber" and dist >= car.v * car.v / (2.0 * 3.5)): return "stop"   # amber: stop if you can
	# don't block the box: is there room on the far side?
	if not _room_after(car, n, to): return "stop"
	# turning left: oncoming traffic goes first (unless it's sitting there waving you through)
	if car.turn_ahead < -0.5 and not _oncoming_clear(car, n, from): return "stop"
	# a driver who has sat there for 45 s with an empty box in front of them goes anyway (but
	# doesn't pull out under a car on the main road)
	if car.wait_t > 45.0 and _box_empty(car, n, float(j.radius)) and (String(j.control) != "priority" or major or _main_clear(car, n, j, 2.5)):
		enter(car, n)
		return "go"
	match String(j.control):
		"signal":
			return "go"
		"priority":
			if major: return "go"
			if car.stopped_at != n: return "stop"         # a full stop first
			# after a long wait a smaller gap will do (but never one the main road can't brake for)
			if _main_clear(car, n, j, 6.0 if car.wait_t < 15.0 else 2.5):
				enter(car, n)         # claim it now, before anyone else decides the same thing
				return "go"
			return "stop"
		"allway":
			if car.stopped_at != n: return "stop"
			if car.wait_t > 6.0 and _box_empty(car, n, j.radius):   # everybody waved
				enter(car, n)
				return "go"
			# first to stop goes first, once the box is empty
			if not _box_empty(car, n, j.radius): return "stop"
			for c in cars:
				if c != car and c.stopped_at == n and c.b == n and c.stop_time < car.stop_time: return "stop"
			enter(car, n)
			return "go"
	return "go"

func _room_after(car: TrafficCar, n: int, to: int) -> bool:
	var r2 := edge_road(n, to)
	if r2.is_empty(): return true
	var lanes: Array = LANE[r2.cls]
	var exit := lane_point(n, to, 12.0, lanes[mini(car.lane_i, lanes.size() - 1)])
	for c in cars:
		if c == car: continue
		if c.a == n and c.b == to and c.s < 12.0 and c.v < 2.0: return false
		if c.a == n and c.b == to and c.s < 9.0: return false     # someone just went through: let them get clear
		if c.pos.distance_to(exit) < 2.5 and c.v < 1.0: return false
	return true

## Nobody coming the other way toward junction `n` soon (for a left turn across their lane),
## and nobody from the other side still crossing it: a left turner coming the other way cuts
## through the same middle. The longer you've waited, the smaller the gap you'll take, but
## never one they'd have to stand on the brakes for.
func _oncoming_clear(car: TrafficCar, n: int, from: int) -> bool:
	var jp := map.g_pos[n]
	var din := (jp - map.g_pos[from]).normalized()
	var window := lerpf(3.5, 2.0, clampf((car.wait_t - 10.0) / 20.0, 0.0, 1.0))
	for c in cars:
		if c == car or c.state != "drive": continue
		if c.entered == n and c.entered_from >= 0 and (jp - map.g_pos[c.entered_from]).normalized().dot(din) < -0.7: return false
		var d := _dist_to(c, n)
		if d == INF: continue
		var cd := (jp - map.g_pos[c.a if c.b == n else c.b]).normalized()
		if cd.dot(din) < -0.7:
			if d < 6.0 + c.v * window and not (c.v < 0.5 and c.last_rule == "stop"): return false
	return true

## How far `c` has to drive to junction `n`: on the road into it, or on the one before that (the
## block between two junctions can be shorter than a few seconds of driving). INF if neither.
func _dist_to(c: TrafficCar, n: int) -> float:
	if c.b == n: return c.pos.distance_to(map.g_pos[n])
	if c.c_next == n: return c.pos.distance_to(map.g_pos[c.b]) + map.g_pos[c.b].distance_to(map.g_pos[n])
	return INF

## Nobody (but `car`) in the middle of junction `n`.
func _box_empty(car: TrafficCar, n: int, radius: float) -> bool:
	var jp := map.g_pos[n]
	for c in junctions.get(n, {}).get("inside", []):
		# (somebody on the list but long gone down the road isn't in anybody's way)
		if c != car and is_instance_valid(c) and c.pos.distance_to(jp) < radius + 15.0: return false
	for c in cars:
		if c != car and c.pos.distance_to(jp) < radius + 0.5: return false
	if player and not ignore_player and player.sim.pos.distance_to(jp) < radius + 1.0: return false
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
