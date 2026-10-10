## Crashes that aren't yours, and the ones that are: what happens after. Every so often two cars
## tangle somewhere out of sight; a few seconds later the radio has it, and the police, an
## ambulance and a fire truck come down the lane with the lights on and park in a line behind the
## wrecks, with cones out behind the fire truck; the lane's shut, so traffic goes round. They work
## it for a minute or so, the wrecks get towed and everybody leaves.
##
## A crash you cause (a hard hit on a car in traffic) gets the same response. Stay until the
## police get there and it's an insurance claim; drive off before they do and it's a hit and run:
## somebody got your plate.
class_name Incidents
extends Node

const EVERY_S := Vector2(160.0, 360.0)   # between crashes somewhere near you (s, free driving)
const STAGE_M := Vector2(140.0, 260.0)   # how far from you they happen (m): close enough to see the lights
const CALL_S := Vector2(6.0, 12.0)       # from the crash to the first unit rolling
const UNIT_GAP_S := 9.0                  # then the next unit, and the next
const WORK_S := Vector2(55.0, 85.0)      # on scene, working it, once everybody's there
const FAR_M := 600.0                     # you're long gone: it packs up without you
const LEFT_M := 150.0                    # drove this far off from your own crash: a hit and run
const HARD_HIT := 8.0                    # how hard (m/s change) a hit on traffic has to be to call it in
const FIRST_DELAY := 120.0               # nothing in the first two minutes

## Who comes, in what order, and where they park, as metres along the lane from the wreck
## (minus is back toward the traffic coming up on it).
const UNITS := [
	{ "kind": "police", "spec": "charjer", "paint": "#e9e9ec", "name": "PORT RUMBLE POLICE", "at": -11.0, "bar": ["e0402e", "3060ff"] },
	{ "kind": "ambulance", "spec": "ambulance", "paint": "#f2f2ee", "name": "PORT RUMBLE EMS", "at": -23.0, "bar": ["e0402e", "f4f4f4"] },
	{ "kind": "fire", "spec": "fire", "paint": "#b81e1e", "name": "PORT RUMBLE FIRE", "at": -38.0, "bar": ["e0402e", "e0402e"] },
]

## What the radio says when it happens (CHUM-style traffic on the nines).
const RADIO := [
	"TRAFFIC ON THE NINES: A TWO-CAR CRASH ON %s. POLICE AND EMS ARE ON THE WAY. GIVE THEM ROOM.",
	"103.9 TRAFFIC: FENDER-BENDER ON %s. ONE LANE'S CLOSED. YOU KNOW THE DRILL.",
	"WE'RE HEARING ABOUT A COLLISION ON %s. FIRE AND AMBULANCE RESPONDING. SLOW DOWN OUT THERE.",
	"HEADS UP: %s IS DOWN TO ONE LANE. SOMEBODY DIDN'T SEE SOMEBODY.",
]

var drive: Node
var enabled := true
var rng := RandomNumberGenerator.new()
var scenes: Array = []            # each a Scene
var _next_t := FIRST_DELAY

class Scene:
	var a := 0                     # the wreck's lane runs from node a to node b
	var b := 0
	var s := 0.0                   # how far along it (m)
	var lane := 0.0
	var at := Vector2.ZERO         # where (m)
	var road := ""
	var wrecks: Array = []         # TrafficCars
	var units: Array = []          # AiCars, in the order they were called
	var parked: Array = []         # [AiCar, where it parks (m)]
	var cones: Array = []          # Cone nodes
	var phase := "crash"           # crash, rolling, working, leaving
	var t := 0.0
	var work_s := 70.0
	var yours := false             # you caused it
	var stayed := false            # ...and you were still there when the police got there
	var left := false              # ...or you weren't
	var called := 0                # units called so far

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.randomize()

## Is now a time for it? Not in the middle of a job, a chase, a scripted mission or a race.
func quiet() -> bool:
	if not enabled or drive.car == null or not drive.free_roam: return false
	if drive.police.chasing(): return false
	if drive.jobs.active(): return false
	if drive.mission != null: return false
	return true

func step(dt: float) -> void:
	if drive.car == null: return
	var me: Vector2 = drive.car.sim.pos
	_next_t -= dt
	if _next_t <= 0.0:
		_next_t = rng.randf_range(EVERY_S.x, EVERY_S.y)
		if scenes.is_empty() and quiet(): stage(me)
	for sc: Scene in scenes.duplicate(): _work(sc, dt, me)

# ------------------------------------------------------------------ starting one

## Two cars tangled somewhere near `me`, out of sight. Returns the scene, or null if there was
## nowhere good.
func stage(me: Vector2) -> Scene:
	var traffic: Traffic = drive.traffic
	var map: MapData = drive.world.map
	for attempt in 12:
		var p := me + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(STAGE_M.x, STAGE_M.y)
		var n := map.nearest_node(p)
		if n < 0 or map.g_adj[n].is_empty(): continue
		var e: Array = map.g_adj[n][rng.randi() % map.g_adj[n].size()]
		var a := n
		var b: int = e[0]
		var road: Dictionary = e[2]
		if not String(road.cls) in ["street", "arterial", "rural", "highway"]: continue
		var L := map.g_pos[a].distance_to(map.g_pos[b])
		if L < 110.0: continue
		var s := rng.randf_range(70.0, L - 30.0)
		var lanes: Array = Traffic.LANE[road.cls]
		var lane: float = lanes[lanes.size() - 1]
		var at := traffic.lane_point(a, b, s, lane)
		if at.distance_to(me) < STAGE_M.x * 0.8 or traffic.hush.has_point(at): continue
		var sc := Scene.new()
		sc.a = a
		sc.b = b
		sc.s = s
		sc.lane = lane
		sc.at = at
		sc.road = String(road.get("name", "THE ROAD"))
		# the one that stopped, and the one that didn't
		var front := traffic.place_car(a, b, s, lane)
		var back := traffic.place_car(a, b, s - 5.2, lane)
		if front == null or back == null:
			for c in [front, back]:
				if c != null: c.gone = true
			continue
		var fwd := (map.g_pos[b] - map.g_pos[a]).normalized()
		back.heading += rng.randf_range(-0.5, 0.5)
		back.hit(fwd * -rng.randf_range(6.0, 10.0), back.pos + fwd * back.length * 0.5)
		front.hit(fwd * rng.randf_range(6.0, 10.0), front.pos - fwd * front.length * 0.5)
		for c: TrafficCar in [front, back]:
			c.wreck_v = Vector2.ZERO
			c.spin = 0.0
			c.held = true
			sc.wrecks.append(c)
		sc.t = 0.0
		_open(sc)
		drive.hud.post(String(RADIO[rng.randi() % RADIO.size()]) % sc.road, 6.0)
		return sc
	return null

## A hard hit on a car in traffic: did you just cause a crash? The car's held where it stopped and
## the response comes to it.
func reported(car: TrafficCar, dv: float, yours: bool) -> Scene:
	if dv < HARD_HIT or not quiet(): return null
	for sc: Scene in scenes:
		if sc.wrecks.has(car) or sc.at.distance_to(car.pos) < 40.0: return null
	var sc := Scene.new()
	sc.a = car.a
	sc.b = car.b
	sc.lane = car._lane(drive.traffic.edge_road(car.a, car.b))
	var map: MapData = drive.world.map
	var dir := (map.g_pos[sc.b] - map.g_pos[sc.a]).normalized()
	sc.s = clampf((car.pos - map.g_pos[sc.a]).dot(dir), 0.0, map.g_pos[sc.a].distance_to(map.g_pos[sc.b]))
	sc.at = car.pos
	sc.road = String(drive.traffic.edge_road(sc.a, sc.b).get("name", "THE ROAD"))
	sc.yours = yours
	car.held = true
	sc.wrecks.append(car)
	_open(sc)
	if yours: drive.hud.post("SOMEBODY'S ON THE PHONE WITH 911. STICK AROUND.", 4.0)
	return sc

func _open(sc: Scene) -> void:
	drive.traffic.blocked[Vector2i(sc.a, sc.b)] = true
	sc.phase = "crash"
	sc.work_s = rng.randf_range(WORK_S.x, WORK_S.y)
	sc.t = -rng.randf_range(CALL_S.x, CALL_S.y)
	scenes.append(sc)

# ------------------------------------------------------------------ working it

func _work(sc: Scene, dt: float, me: Vector2) -> void:
	sc.t += dt
	var d := me.distance_to(sc.at)
	# you caused it and you're leaving
	if sc.yours and not sc.stayed and not sc.left and d > LEFT_M:
		sc.left = true
		_hit_and_run()
	if d > FAR_M:
		close(sc)
		return
	match sc.phase:
		"crash", "rolling":
			# units called one after another
			while sc.called < UNITS.size() and sc.t >= sc.called * UNIT_GAP_S:
				_dispatch(sc, UNITS[sc.called], sc.called)
				sc.called += 1
				sc.phase = "rolling"
			var here := 0
			for pk: Array in sc.parked:
				var k: AiCar = pk[0]
				if not is_instance_valid(k): here += 1; continue
				if k.hold: here += 1; continue
				var stop: Vector2 = pk[1]
				if k.sim.pos.distance_to(stop) < 4.0 or (k.track.valid() and k.track.done):
					k.hold = true
					k.speed_cap = 0.0
					here += 1
					if UNITS[sc.units.find(k)].kind == "police":
						if sc.yours and not sc.left:
							sc.stayed = true
							drive.hud.post("CONSTABLE TREMBLAY: \"YOU STAYED. GOOD. INSURANCE IS GOING TO HATE YOU, BUT YOU STAYED.\"", 6.0)
							Karma.deed("stayed")
			if sc.called == UNITS.size() and here == sc.parked.size():
				sc.phase = "working"
				sc.t = 0.0
				_cones(sc)
			elif sc.t > 150.0:
				close(sc)            # somebody never made it: call it
		"working":
			if sc.t >= sc.work_s:
				# the wrecks go on the hook, the cones come up, everybody heads home
				sc.phase = "leaving"
				sc.t = 0.0
				for c in sc.wrecks:
					if is_instance_valid(c): c.gone = true
				sc.wrecks.clear()
				_clear_cones(sc)
				_unblock(sc)
				for k: AiCar in sc.units:
					if not is_instance_valid(k): continue
					k.hold = false
					k.siren = false
					k.speed_cap = 20.0
					k.set_path(_route_away(k.sim.pos, k.sim.forward()))
		"leaving":
			if sc.t > 40.0 or d > 350.0:
				close(sc)
				return
			for k: AiCar in sc.units.duplicate():
				if is_instance_valid(k) and k.track.valid() and k.track.done and k.sim.pos.distance_to(me) > 120.0:
					_remove_unit(sc, k)

## A unit rolls in, lights and siren on, down the wreck's own lane from a junction back up the road.
func _dispatch(sc: Scene, u: Dictionary, i: int) -> void:
	var map: MapData = drive.world.map
	var L := map.g_pos[sc.a].distance_to(map.g_pos[sc.b])
	var stop: Vector2 = drive.traffic.lane_point(sc.a, sc.b, clampf(sc.s + float(u.at), 2.0, L - 2.0), sc.lane)
	var path := approach(sc.a, sc.b, drive.car.sim.pos)
	path.append(stop)
	var k := AiCar.new()
	drive.ysort.add_child(k)
	var spec := SaveGame.load_spec(String(u.spec))
	spec.paint = String(u.paint)
	spec.name = String(u.name)
	var h := (path[1] - path[0]).angle()
	k.setup_ai(spec, drive.world, drive.skids, drive.hud, path[0], h, 60 + i)
	k.traffic = drive.traffic
	k.lights = Color(String(u.bar[0]))
	k.bar_cols = [Color(String(u.bar[0])), Color(String(u.bar[1]))]
	k.siren = true
	k.limits = false
	k.skill = 0.78
	k.speed_cap = 24.0 if u.kind == "fire" else 30.0
	k.set_path(path)
	drive.traffic.extra.append(k)
	sc.units.append(k)
	sc.parked.append([k, stop])

## The way in to the lane from node a to node b: back up the road from a, junction by junction
## (as straight as the roads go), until it's a few hundred metres back and out of sight of `me`.
## Returns the junctions in driving order, ending at a.
func approach(a: int, b: int, me: Vector2) -> PackedVector2Array:
	var map: MapData = drive.world.map
	var nodes: Array = [a]
	var prev := b
	var cur := a
	var back := 0.0
	while nodes.size() < 40:
		if back >= 260.0 and map.g_pos[cur].distance_to(me) >= 140.0: break
		if back >= 520.0: break
		var heading := (map.g_pos[cur] - map.g_pos[prev]).normalized()
		var best := -1
		var best_d := -INF
		for e in map.g_adj[cur]:
			var q: int = e[0]
			if q == prev or nodes.has(q): continue
			if String((e[2] as Dictionary).get("cls", "")) == "gravel": continue
			var d := heading.dot((map.g_pos[q] - map.g_pos[cur]).normalized())
			if d > best_d:
				best_d = d
				best = q
		if best < 0: break
		back += map.g_pos[cur].distance_to(map.g_pos[best])
		prev = cur
		cur = best
		nodes.append(cur)
	var out := PackedVector2Array()
	for j in range(nodes.size() - 1, -1, -1): out.append(map.g_pos[nodes[j]])
	if out.size() < 2: out.insert(0, map.g_pos[a] + (map.g_pos[a] - map.g_pos[b]).normalized() * 60.0)
	return out

## Everybody's parked: cones out behind the fire truck in a taper, from the curb side of the lane
## back up the road across to the centre line.
func _cones(sc: Scene) -> void:
	if not sc.cones.is_empty(): return
	var map: MapData = drive.world.map
	var L := map.g_pos[sc.a].distance_to(map.g_pos[sc.b])
	var last := 0.0
	for u in UNITS: last = minf(last, float(u.at))
	for i in 6:
		var s := sc.s + last - 8.0 - (5 - i) * 4.0
		if s < 2.0 or s > L - 2.0: continue
		var off := sc.lane + 1.5 - float(i) / 5.0 * 3.0
		var c := Cone.new()
		c.position = drive.traffic.lane_point(sc.a, sc.b, s, off) * CarArt.PX
		c.drive = drive
		drive.ysort.add_child(c)
		sc.cones.append(c)

func _clear_cones(sc: Scene) -> void:
	for c in sc.cones:
		if is_instance_valid(c): c.queue_free()
	sc.cones.clear()

func _unblock(sc: Scene) -> void:
	drive.traffic.blocked.erase(Vector2i(sc.a, sc.b))

func _route_away(from: Vector2, fwd: Vector2) -> PackedVector2Array:
	var map: MapData = drive.world.map
	var to := from + fwd * 400.0 + fwd.orthogonal() * rng.randf_range(-200.0, 200.0)
	var p: Vector2 = map.nearest_road(to, 300.0).get("point", to)
	var r: PackedVector2Array = map.route(from, p)
	var out := PackedVector2Array([from])
	for q in r: out.append(q)
	out.append(p)
	return out

func _remove_unit(sc: Scene, k: AiCar) -> void:
	sc.units.erase(k)
	drive.traffic.extra.erase(k)
	k.queue_free()

## The whole scene, gone (you left, or it's done, or the story needs the road).
func close(sc: Scene) -> void:
	for c in sc.wrecks:
		if is_instance_valid(c):
			c.held = false
			c.gone = true
	_clear_cones(sc)
	_unblock(sc)
	for k in sc.units.duplicate():
		if is_instance_valid(k): _remove_unit(sc, k)
	scenes.erase(sc)

func clear() -> void:
	for sc in scenes.duplicate(): close(sc)

## You drove away from a crash you caused.
func _hit_and_run() -> void:
	drive.police.add_heat(30.0)
	Karma.deed("hit_run")
	drive.hud.post("HIT AND RUN. SOMEBODY GOT YOUR PLATE. THE POLICE WILL BE LOOKING.", 6.0)

## Nearest flashing light bar to you (for the siren): [distance m, AiCar] or [INF, null].
func nearest_siren(me: Vector2) -> Array:
	var best := [INF, null]
	for sc: Scene in scenes:
		for k in sc.units:
			if is_instance_valid(k) and k.siren and not k.hold:
				var d: float = k.sim.pos.distance_to(me)
				if d < best[0]: best = [d, k]
	return best

## Where the scenes are, for the GPS.
func blips() -> Array:
	var out: Array = []
	for sc: Scene in scenes:
		out.append([sc.at, Color("ff9a1a")])
		for k in sc.units:
			if is_instance_valid(k): out.append([k.sim.pos, Color(1, 0.2, 0.15) if k.siren else Color(0.6, 0.6, 0.6)])
	return out

## A traffic cone: orange, white band, and it goes flying if you hit it.
class Cone extends Node2D:
	var drive: Node
	var vel := Vector2.ZERO       # px/s
	var spin := 0.0
	var down := false             # knocked over

	func sort_point() -> Vector2:
		return global_position

	func _process(dt: float) -> void:
		if drive == null or drive.car == null: return
		var car: PlayerCar = drive.car
		if not down and car.global_position.distance_to(global_position) < float(car.spec.get("length", 4.5)) * 0.5 * CarArt.PX and car.sim.speed() > 1.0:
			down = true
			vel = car.sim.world_velocity() * CarArt.PX * 0.9 + Vector2.from_angle(randf() * TAU) * 40.0
			spin = randf_range(-9.0, 9.0)
		if vel.length() > 1.0:
			position += vel * dt
			rotation += spin * dt
			vel *= exp(-2.5 * dt)
			spin *= exp(-2.5 * dt)
			queue_redraw()

	func _draw() -> void:
		var px := CarArt.PX
		var up := CarView.screen_up * CarView.lift_k
		if down:
			# on its side: a short orange wedge
			var f := Vector2.from_angle(rotation)
			draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
			var tip := f * 0.6 * px
			var r := f.orthogonal() * 0.18 * px
			draw_colored_polygon(PackedVector2Array([tip, -f * 0.1 * px + r * 1.6, -f * 0.1 * px - r * 1.6]), Color("f07a1a"))
			draw_line(-f * 0.1 * px + r * 1.6, -f * 0.1 * px - r * 1.6, Color("2a2a2a"), 2.0)
			return
		draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
		var base := 0.22 * px
		draw_rect(Rect2(-base, -base, base * 2.0, base * 2.0), Color("2a2a2a"))       # the square foot
		var tip := up * 0.7 * px
		var left := up.orthogonal() * 0.16 * px
		draw_colored_polygon(PackedVector2Array([left, -left, tip]), Color("f07a1a"))
		var b0 := up * 0.3 * px
		var b1 := up * 0.42 * px
		var w0 := left * (1.0 - 0.3 / 0.7)
		var w1 := left * (1.0 - 0.42 / 0.7)
		draw_colored_polygon(PackedVector2Array([b0 + w0, b0 - w0, b1 - w1, b1 + w1]), Color("f4f4f4"))
