## Traffic soak test, run inside the drive scene: godot --headless --fixed-fps 60 --path game -- --traffic-test
## Parks you downtown (then on the highway), lets traffic run, and checks it flows: no pile-ups
## between AI cars, nobody stuck for a minute, cars actually getting somewhere. The traffic's dice
## are seeded; --fixed-fps makes every frame the same length too, so a run is the same every time
## (without it the frame times wobble and so does the traffic). --seeds 1,2,3 runs every spot once
## per seed (different cars, different turns, the lights at a different point in their cycle), so
## a fixed-frame run still tries more than one way things can go.
extends Node

var main: Node
var t := 0.0
var phase := 0
var crashes := 0
var stuck_max := 0.0
var dist := 0.0
var samples := 0
var speed_sum := 0.0
var max_cars := 0
var fails := 0
var _hit_pairs := {}
var _near := {}
var _trace := {}
var _tr_t := 0.0
var _why := ""
var _stuck_car = null

const SPOTS := [[Vector2(5860, 1250), "north end"], [Vector2(6005, 1470), "downtown"], [Vector2(4300, 1400), "trans-canada"], [Vector2(3440, 2120), "salisbury"]]
const SECONDS := 150.0
var only_first := OS.get_cmdline_user_args().has("--quick")
var seeds: Array[int] = [2019]
var seed_i := 0
var first_spot := 0
var why_often := OS.get_cmdline_user_args().has("--why")

func _ready() -> void:
	Engine.time_scale = 4.0
	# traffic doesn't see your car here, so it mustn't be able to hit it either (the north end
	# spot is the middle of a junction)
	main.traffic.ignore_player = true
	main.car.collision_layer = 0
	main.car.collision_mask = 0
	var a := OS.get_cmdline_user_args()
	var k := a.find("--spot")
	var ks := a.find("--seeds")
	if ks >= 0 and ks + 1 < a.size():
		seeds = []
		for w in a[ks + 1].split(","): seeds.append(int(w))
	first_spot = int(a[k + 1]) if k >= 0 else 0
	_go(first_spot)

func _go(i: int) -> void:
	phase = i
	# the same seed gives the same run (with --fixed-fps); the clock starts where the seed says
	var sd: int = seeds[seed_i]
	main.traffic.rng.seed = sd * 7919 + i
	Traffic.clock = float(sd * 13 % int(Traffic.CYCLE))
	t = 0.0
	crashes = 0
	stuck_max = 0.0
	speed_sum = 0.0
	samples = 0
	max_cars = 0
	_hit_pairs = {}
	for c in main.traffic.cars: c.queue_free()
	main.traffic.cars.clear()
	main.sky.time_h = 12.0
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main._teleport(SPOTS[i][0], 0.0)
	main.car.sim.vx = 0.0

func _chain(c) -> String:
	var out := ""
	var seen := {}
	var x = c
	for k in 6:
		if x == null or not (x is TrafficCar) or seen.has(x): break
		seen[x] = true
		var cnt: String = main.traffic.junctions.get(x.b, {}).get("control", "-")
		out += "[%d %s v%.1f rule:%s%s %s d%.0f ent%d stp%d wait%.0f acc%.1f a%d b%d c%d] -> " % [x.get_instance_id() % 10000, x.state, x.v, x.last_rule, ("(" + x.why + ")") if x.last_rule == "stop" else "", cnt, main.traffic.map.g_pos[x.b].distance_to(x.pos), x.entered, x.stopped_at, x.wait_t, x.acc, x.a, x.b, x.c_next]
		x = x.lead_obj
	return out + ("player" if x is PlayerCar else str(x))

func _desc(x) -> String:
	var tr: Traffic = main.traffic
	var jn := -1
	var jd := INF
	for n in [x.a, x.b]:
		if tr.junctions.has(n) and tr.map.g_pos[n].distance_to(x.pos) < jd:
			jd = tr.map.g_pos[n].distance_to(x.pos)
			jn = n
	var ctl: String = tr.junctions.get(jn, {}).get("control", "-") if jn >= 0 else "-"
	var major := false
	if jn >= 0:
		var r: Dictionary = tr.edge_road(x.a, x.b)
		major = tr.junctions[jn].majors.has(int(r.get("idx", -1)))
	var A: Vector2 = tr.map.g_pos[x.a]
	var d: Vector2 = (tr.map.g_pos[x.b] - A).normalized()
	var lat: float = (x.pos - A).dot(Vector2(-d.y, d.x))
	var r2: Dictionary = tr.edge_road(x.a, x.b)
	var light := ""
	if ctl == "signal": light = " " + Traffic.signal_state(int(tr.junctions[jn].offset), 0 if major else 1)
	var from := ""
	if x.entered_from >= 0: from = " in from %.0f deg" % rad_to_deg((tr.map.g_pos[x.entered] - tr.map.g_pos[x.entered_from]).angle())
	return "%s v%.1f rule %s(for j%d) turn %.1f j%s %s%s %s d%.0f | lat %.1f want %.1f road %s/%s s%.0f L%.0f | heading %.0f wait %.0f ent%d%s len %.1f" % [x.state, x.v, x.last_rule, x.b, x.turn_ahead, jn, ctl, light, "MAJOR" if major else "minor", jd, lat, x._lane(r2), r2.get("name", "?"), r2.get("cls", "?"), x.s, A.distance_to(tr.map.g_pos[x.b]), rad_to_deg(x.heading), x.wait_t, x.entered, from, x.length]

func _dump(c) -> void:
	var tr: Traffic = main.traffic
	var x = c
	while x.lead_obj is TrafficCar and x.lead_obj.b == x.b: x = x.lead_obj
	var n: int = x.b
	var j: Dictionary = tr.junctions.get(n, {})
	print("   head car at node %d: control %s, radius %.1f, room_after %s, oncoming_clear %s, box_empty %s, turn %.2f" % [n, j.get("control"), j.get("radius", 0.0), tr._room_after(x, n, x.c_next), tr._oncoming_clear(x, n, x.a), tr._box_empty(x, n, j.get("radius", 5.0)), x.turn_ahead])
	for o in tr.cars:
		var d: float = o.pos.distance_to(tr.map.g_pos[n])
		if d < 30.0:
			print("     car %d d%.1f %s v%.1f a%d b%d c%d stopped_at%d t%.1f rule %s%s wait %.0f boxes %s lead %s" % [o.get_instance_id() % 10000, d, o.state, o.v, o.a, o.b, o.c_next, o.stopped_at, o.stop_time, o.last_rule, ("(" + o.why + ")") if o.last_rule == "stop" else "", o.wait_t, o.boxes, str(o.lead_obj.get_instance_id() % 10000) if o.lead_obj is Object else "-"])

## One car on a limited-access highway and the other on a road that crosses it with no junction
## there: the overpass. They pass over and under each other, not into each other.
func _levels_differ(a: TrafficCar, b: TrafficCar) -> bool:
	var tr: Traffic = main.traffic
	var ra: Dictionary = tr.edge_road(a.a, a.b)
	var rb: Dictionary = tr.edge_road(b.a, b.b)
	if bool(ra.get("limited", false)) == bool(rb.get("limited", false)): return false
	# (unless they're at a junction of the two roads: a ramp's end, not an overpass)
	for n in [a.a, a.b, b.a, b.b]:
		if not tr.junctions.has(n) or tr.map.g_pos[n].distance_to(a.pos) > 30.0: continue
		var idx: Array = tr.map.g_adj[n].map(func(e: Array) -> int: return int(e[2].idx))
		if idx.has(int(ra.get("idx", -1))) and idx.has(int(rb.get("idx", -1))): return false
	return true

## Two cars touching: their collision boxes (the size they're drawn at, the way they point)
## overlap. Two long trucks passing in their own lanes on a narrow street don't.
static func overlap(a: TrafficCar, b: TrafficCar) -> bool:
	var ha := Vector2(a.length * 0.95, a.width * 0.9) * 0.5
	var hb := Vector2(b.length * 0.95, b.width * 0.9) * 0.5
	var ua := Vector2.from_angle(a.heading)
	var ub := Vector2.from_angle(b.heading)
	var va := Vector2(-ua.y, ua.x)
	var vb := Vector2(-ub.y, ub.x)
	var d := b.pos - a.pos
	for ax: Vector2 in [ua, va, ub, vb]:
		var ra := ha.x * absf(ua.dot(ax)) + ha.y * absf(va.dot(ax))
		var rb := hb.x * absf(ub.dot(ax)) + hb.y * absf(vb.dot(ax))
		if absf(d.dot(ax)) > ra + rb: return false
	return true

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _process(dt: float) -> void:
	t += dt
	# keep the player parked where it is (out of the way, on the curb side is fine)
	main.car.sim.vx = 0.0
	main.car.sim.vy = 0.0
	var cars: Array = main.traffic.cars
	max_cars = maxi(max_cars, cars.size())
	_tr_t += dt
	if _tr_t > 0.25:
		_tr_t = 0.0
		for c in cars:
			var k: int = c.get_instance_id()
			if not _trace.has(k): _trace[k] = []
			_trace[k].append("t%.1f p(%.1f,%.1f) h%.0f v%.1f a%d b%d c%d li%d s%.1f rule %s ent%d wait%.1f turn%.2f lead %s" % [t, c.pos.x, c.pos.y, rad_to_deg(c.heading), c.v, c.a, c.b, c.c_next, c.lane_i, c.s, c.last_rule, c.entered, c.wait_t, c.turn_ahead, str(c.lead_obj.get_instance_id() % 10000) if c.lead_obj is Object else "-"])
			if _trace[k].size() > 30: _trace[k].pop_front()
	for c in cars:
		if c.state == "drive":
			speed_sum += c.v
			samples += 1
			if c.wait_t > stuck_max:
				stuck_max = c.wait_t
				_why = _chain(c)
				_stuck_car = c
	# somebody stuck a long while: what they're waiting on, now and then (--why: sooner and every second)
	var every := 1.0 if why_often else 5.0
	if is_instance_valid(_stuck_car) and _stuck_car.wait_t > (30.0 if why_often else 60.0) and fmod(t, every) < dt:
		var sc: TrafficCar = _stuck_car
		var jn: Dictionary = main.traffic.junctions.get(sc.b, {})
		var lt := ""
		if String(jn.get("control", "")) == "signal": lt = Traffic.signal_state(int(jn.offset), 0 if jn.majors.has(int(main.traffic.edge_road(sc.a, sc.b).get("idx", -1))) else 1)
		print("   t%.0f stuck at j%d (light %s): %s" % [t, sc.b, lt, _chain(sc)])
	# AI cars overlapping each other = a crash the rules should have prevented
	for i in cars.size():
		for j in range(i + 1, cars.size()):
			var a: TrafficCar = cars[i]
			var b: TrafficCar = cars[j]
			if a.pos.distance_to(b.pos) < (a.length + b.length) * 0.32: _near["%d-%d" % [a.get_instance_id(), b.get_instance_id()]] = true
			if a.pos.distance_to(b.pos) < (a.length + b.length) * 0.5 and overlap(a, b) and not _levels_differ(a, b):
				var key := "%d-%d" % [a.get_instance_id(), b.get_instance_id()]
				if not _hit_pairs.has(key):
					_hit_pairs[key] = true
					crashes += 1
					if crashes <= 6: print("   crash: ", _desc(a), " | ", _desc(b), " angle %.0f" % rad_to_deg(absf(wrapf(a.heading - b.heading, -PI, PI))))
					if crashes <= 2:
						for x in [a, b]:
							print("   TRACE of ", x.get_instance_id() % 10000)
							for ln in _trace.get(x.get_instance_id(), []): print("      ", ln)
	if t >= SECONDS:
		var name: String = SPOTS[phase][1] + ("" if seeds.size() == 1 and seeds[0] == 2019 else " (seed %d)" % seeds[seed_i])
		var avg := speed_sum / maxf(samples, 1) * 3.6
		print("%s: up to %d cars, %d AI crashes (%d by the old measure), longest wait %.0f s, average %.0f km/h" % [name, max_cars, crashes, _near.size(), stuck_max, avg])
		check("%s: traffic spawns" % name, max_cars >= 5, "%d" % max_cars)
		check("%s: hardly any AI fender-benders" % name, crashes <= 2, "%d in %.0f s" % [crashes, SECONDS])
		check("%s: nobody stuck for a minute and a half" % name, stuck_max < 90.0, "%.0f s: %s" % [stuck_max, _why])
		if stuck_max >= 90.0 and is_instance_valid(_stuck_car): _dump(_stuck_car)
		check("%s: traffic moves" % name, avg > 12.0, "%.0f km/h" % avg)
		if phase + 1 < SPOTS.size() and not only_first:
			_go(phase + 1)
		elif seed_i + 1 < seeds.size():
			seed_i += 1
			_go(first_spot)
		else:
			print("\n%d failed" % fails)
			get_tree().quit(1 if fails > 0 else 0)
