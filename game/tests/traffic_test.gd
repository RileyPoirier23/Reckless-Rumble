## Traffic soak test, run inside the drive scene: godot --headless --path game -- --traffic-test
## Parks you downtown (then on the highway), lets traffic run, and checks it flows: no pile-ups
## between AI cars, nobody stuck for a minute, cars actually getting somewhere.
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
var _why := ""
var _stuck_car = null

const SPOTS := [[Vector2(5860, 1250), "north end"], [Vector2(6005, 1470), "downtown"], [Vector2(4300, 1400), "trans-canada"], [Vector2(3440, 2120), "salisbury"]]
const SECONDS := 150.0
var only_first := OS.get_cmdline_user_args().has("--quick")

func _ready() -> void:
	Engine.time_scale = 4.0
	main.traffic.ignore_player = true
	var a := OS.get_cmdline_user_args()
	var k := a.find("--spot")
	_go(int(a[k + 1]) if k >= 0 else 0)

func _go(i: int) -> void:
	phase = i
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
		out += "[%s v%.1f rule:%s %s d%.0f ent%d stp%d wait%.0f acc%.1f a%d b%d c%d] -> " % [x.state, x.v, x.last_rule, cnt, main.traffic.map.g_pos[x.b].distance_to(x.pos), x.entered, x.stopped_at, x.wait_t, x.acc, x.a, x.b, x.c_next]
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
	return "%s v%.1f rule %s turn %.1f j%s %s %s d%.0f | lat %.1f want %.1f road %s/%s s%.0f L%.0f" % [x.state, x.v, x.last_rule, x.turn_ahead, jn, ctl, "MAJOR" if major else "minor", jd, lat, x._lane(r2), r2.get("name", "?"), r2.get("cls", "?"), x.s, A.distance_to(tr.map.g_pos[x.b])]

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
			print("     car d%.1f %s v%.1f a%d b%d c%d stopped_at%d t%.1f rule %s wait %.0f" % [d, o.state, o.v, o.a, o.b, o.c_next, o.stopped_at, o.stop_time, o.last_rule, o.wait_t])

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
	for c in cars:
		if c.state == "drive":
			speed_sum += c.v
			samples += 1
			if c.wait_t > stuck_max:
				stuck_max = c.wait_t
				_why = _chain(c)
				_stuck_car = c
	# AI cars overlapping each other = a crash the rules should have prevented
	for i in cars.size():
		for j in range(i + 1, cars.size()):
			var a: TrafficCar = cars[i]
			var b: TrafficCar = cars[j]
			if a.pos.distance_to(b.pos) < (a.length + b.length) * 0.32:
				var key := "%d-%d" % [a.get_instance_id(), b.get_instance_id()]
				if not _hit_pairs.has(key):
					_hit_pairs[key] = true
					crashes += 1
					if crashes <= 6: print("   crash: ", _desc(a), " | ", _desc(b), " angle %.0f" % rad_to_deg(absf(wrapf(a.heading - b.heading, -PI, PI))))
	if t >= SECONDS:
		var name: String = SPOTS[phase][1]
		var avg := speed_sum / maxf(samples, 1) * 3.6
		print("%s: up to %d cars, %d AI crashes, longest wait %.0f s, average %.0f km/h" % [name, max_cars, crashes, stuck_max, avg])
		check("%s: traffic spawns" % name, max_cars >= 5, "%d" % max_cars)
		check("%s: hardly any AI fender-benders" % name, crashes <= 2, "%d in %.0f s" % [crashes, SECONDS])
		check("%s: nobody stuck for a minute and a half" % name, stuck_max < 90.0, "%.0f s: %s" % [stuck_max, _why])
		if stuck_max >= 90.0 and is_instance_valid(_stuck_car): _dump(_stuck_car)
		check("%s: traffic moves" % name, avg > 12.0, "%.0f km/h" % avg)
		if phase + 1 < SPOTS.size() and not only_first:
			_go(phase + 1)
		else:
			print("\n%d failed" % fails)
			get_tree().quit(1 if fails > 0 else 0)
