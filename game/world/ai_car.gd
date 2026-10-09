## A car with somebody else driving: the same CarSim as yours, the same bumps and dents, steered
## down a line of points (pure pursuit) at whatever speed the bends ahead allow. Street racers
## and the police both drive these. It goes round slower traffic when the road is wide enough,
## sits behind it when it isn't, and backs out when it gets stuck against something.
class_name AiCar
extends PlayerCar

var track := PathTrack.new()       # the line it drives
var skill := 0.85                  # how much of the grip it dares use (0.6 timid .. 0.98 pro)
var speed_cap := 99.0              # m/s
var limits := false                # keep to each road's speed limit (a patrol car)
var hold := false                  # sit still with the brake on (the grid, a stop)
var traffic: Traffic               # the cars in the way
var others: Array = []             # more cars to go round: racers, the player
var target_v := 0.0                # the speed it wants right now
var last_in: Array = [0.0, 0.0, 0.0, 0.0]
var trace: Array = []              # the last few seconds of driving, for working out what went wrong
var _trace_n := 0
var lights := Color.TRANSPARENT    # a light bar: TRANSPARENT for none
var siren := false
var night := false

var _pass := 0.0                   # sideways offset to get round something (m, + right)
var _stuck_t := 0.0
var _back_t := 0.0
var _lost_t := 0.0                 # how long since it last got anywhere along its line
var _best_dist := -INF
var _brake_seen := 0.0             # how hard this car really stops, per unit of grip (m/s²)
var _v_last := 0.0
var _br_last := 0.0
var _tc := 1.0                     # traction control's throttle ceiling: down while the tires spin
var _flash_t2 := 0.0
var _bar: Node2D
var _bar_light: PointLight2D

## A car on the road with a driver: `id` keeps its skid marks apart from everyone else's.
func setup_ai(car_spec: Dictionary, the_city: World, the_skids: Skids, the_hud: Hud, at_m: Vector2, h: float, id: int) -> void:
	quiet = true
	setup(car_spec, the_city, the_skids, the_hud, at_m, h)
	can_die = false
	skid_base = 100 + id * 20
	# layer 2: you hit them and they hit you, but two of them never tangle up with each other
	collision_layer = 2
	collision_mask = 1
	sim.assist = CarSim.Assist.STREET
	sim.coolant_c = 88.0
	sim.oil_c = 95.0
	for i in 4: sim.tires[i].temp = float(CarSim.COMPOUND[sim.compound].opt)
	_brake_seen = brake_probe(car_spec)

## How hard this car stops from 90 km/h on dry road with the pedal down (m/s²): a second of
## the real sim, so a heavy truck on drums doesn't plan its corners like a sports car.
static func brake_probe(car_spec: Dictionary) -> float:
	var p := CarSim.new(car_spec)
	p.assist = CarSim.Assist.STREET
	p.cold_start()
	p.coolant_c = 88.0
	p.oil_c = 95.0
	for i in 4: p.tires[i].temp = float(CarSim.COMPOUND[p.compound].opt)
	p.vx = 25.0
	p.w_wheel = 25.0 / float(car_spec.tires.radius)
	for i in 60: p.step(1.0 / 60.0, 0.0, 1.0, 0.0, 0.0)
	return clampf(25.0 - p.speed(), 3.0, 12.0)

## The line to drive, picked up from wherever the car is now. Corners get rounded into a line
## it can drive (pass 0 for a line that's already been rounded).
func set_path(pts: PackedVector2Array, is_loop := false, corner_r := 10.0) -> void:
	track.set_path(PathTrack.rounded(pts, corner_r, is_loop), is_loop, sim.pos)
	_best_dist = track.dist
	_lost_t = 0.0

func point_at(s: float) -> Vector2:
	return track.point_at(s)

func dir_at(s: float) -> Vector2:
	return track.dir_at(s) if track.valid() else sim.forward()

## How hard it can corner and brake on this road in these tires.
func grip() -> float:
	var mu := 0.0
	for i in 4: mu += sim.tire_mu(i)
	return clampf(mu / 4.0, 0.1, 1.3)

## The fastest it should be going now: the corners ahead, each one it has to be able to brake for.
func plan_speed() -> float:
	var v := sim.speed()
	var mu := grip()
	var a_lat := mu * 9.81 * skill
	var a_brk := mu * 9.81 * (0.5 + 0.35 * skill)
	# what this car has really managed under hard braking (old drums, heavy trucks, wet roads)
	if _brake_seen > 0.0: a_brk = minf(a_brk, _brake_seen * mu * 0.92)
	var vt := speed_cap
	if limits:
		var road: Dictionary = city.map.road_at(sim.pos).get("road", {})
		if not road.is_empty(): vt = minf(vt, float(Traffic.SPEED.get(road.cls, 14.0)) * 1.04)
	var s0 := track.proj(sim.pos)
	var reach := v * v / (2.0 * a_brk) + 30.0
	var d := 0.0
	while d < reach:
		var s := s0 + d
		if not track.loop and s >= track.length() - 2.0:
			vt = minf(vt, sqrt(2.0 * a_brk * maxf(0.0, d - 2.0)))
			break
		var turn := absf(dir_at(s).angle_to(dir_at(s + 12.0)))
		if turn > 0.05:
			var v_c := sqrt(a_lat / maxf(turn / 12.0, 0.0001))
			# be down to it a beat early: brakes take a moment to bite
			vt = minf(vt, sqrt(v_c * v_c + 2.0 * a_brk * maxf(0.0, d - 3.0 - v * 0.35)))
		d += 4.0
	return vt

## What's in the way: [gap ahead (m), its speed along our way, the offset that gets round it].
func _blocker(fwd: Vector2, v: float) -> Array:
	var look := 8.0 + v * 1.8
	var right := Vector2(-fwd.y, fwd.x)
	var best: Array = [INF, 0.0, 0.0]
	var cands: Array = []
	if traffic:
		for c in traffic.cars:
			if c.pos.distance_squared_to(sim.pos) < (look + 10.0) * (look + 10.0):
				cands.append([c.pos, c.velocity_vec(), c.width])
	for o in others:
		if o == self or not is_instance_valid(o): continue
		var oc: PlayerCar = o
		if oc.sim.pos.distance_squared_to(sim.pos) < (look + 10.0) * (look + 10.0):
			cands.append([oc.sim.pos, oc.sim.world_velocity(), float(oc.spec.width)])
	var half := float(spec.width) * 0.5
	for c in cands:
		var rel: Vector2 = c[0] - sim.pos
		var ahead := rel.dot(fwd)
		if ahead < 1.0 or ahead > look: continue
		var lat := rel.dot(right)
		var clear := half + float(c[2]) * 0.5 + 0.7
		if absf(lat - _pass) > clear: continue
		var gap := ahead - float(spec.length)
		if gap < float(best[0]):
			best[0] = gap
			best[1] = (c[1] as Vector2).dot(fwd)
			# go round on the side it isn't on (the left, if it's dead ahead)
			best[2] = lat - clear - 0.4 if lat >= -0.3 else lat + clear + 0.4
	return best

func _inputs(dt: float) -> Array:
	var v := sim.speed()
	# learn the brakes: hard braking, still rolling fast, nothing in the way
	if _br_last > 0.85 and v > 6.0 and _v_last > v and hit_frame < Engine.get_physics_frames() - 2:
		_brake_seen = lerpf(_brake_seen, (_v_last - v) / maxf(dt, 0.001) / grip(), 0.08)
	_v_last = v
	# these drivers keep their cars running: dents yes, a dead engine in the middle of King St no
	sim.engine_blown = false
	sim.engine_health = maxf(sim.engine_health, 0.7)
	sim.radiator = maxf(sim.radiator, 0.9)
	sim.coolant_c = minf(sim.coolant_c, 104.0)
	sim.clutch_cond = maxf(sim.clutch_cond, 0.6)
	for t in sim.tires: t.flat = false
	if hold or not track.valid() or track.done:
		_pass = 0.0
		# stopped: the handbrake and a little brake (over 0.3 at a stop would find reverse)
		return [0.0, 1.0, 0.0, 0.0] if v > 0.8 else [0.0, 0.25, 0.0, 1.0]
	track.advance(sim.pos)
	var here := track.proj(sim.pos)
	if _rescue(dt, here): return [0.0, 0.25, 0.0, 1.0]
	# stuck against something: back out, wheel the other way, then try again
	if _back_t > 0.0:
		_back_t -= dt
		var aim := angle_difference(sim.heading, (point_at(here + 10.0) - sim.pos).angle())
		return [0.0, 0.5 if sim.gear < 0 else 0.8, clampf(-aim * 2.0, -1.0, 1.0), 0.0]
	var fwd := dir_at(here + 4.0)
	# something in the way: go round it if the road's wide enough, follow it if it isn't
	var blk := _blocker(fwd, v)
	var road: Dictionary = city.map.road_at(sim.pos).get("road", {})
	var room := float(road.get("w", 9.0)) * 0.5 - float(spec.width) * 0.5 - 0.6 if not road.is_empty() else 2.0
	var want := 0.0
	var follow := INF
	# no passing into a corner: an offset taken on the way in points it at the far kerb on the way out
	var bend := absf(dir_at(here).angle_to(dir_at(here + 12.0 + v * 1.5)))
	if bend > 0.35: room = 0.0
	if float(blk[0]) < INF:
		want = clampf(float(blk[2]), -room, room)
		if absf(want - float(blk[2])) > 0.3:
			follow = maxf(0.0, float(blk[1])) + maxf(0.0, float(blk[0]) - 3.0) * 0.5
	_pass = move_toward(_pass, want, dt * (2.5 if want != 0.0 else 1.2))
	# steer: pure pursuit on a point down the line, shifted sideways when passing
	var look := clampf(5.0 + v * 0.42, 6.0, 32.0)
	var s_t := here + look
	var d_t := dir_at(s_t)
	var tgt := point_at(s_t) + Vector2(-d_t.y, d_t.x) * _pass
	var to_t := tgt - sim.pos
	var alpha := angle_difference(sim.heading, to_t.angle())
	var delta := atan(2.0 * float(spec.wheelbase) * sin(alpha) / maxf(to_t.length(), 1.0))
	var max_steer := lerpf(float(spec.steer_lock), 0.11, clampf(v / 42.0, 0.0, 1.0))
	var st := clampf(delta / max_steer, -1.0, 1.0)
	if absf(alpha) > PI / 2.0: st = signf(alpha)         # the target's behind: full lock round to it
	var beta := atan2(sim.vy, maxf(absf(sim.vx), 1.0))
	if v > 4.0 and absf(beta) > 0.08: st = clampf(st + beta * 1.3, -1.0, 1.0)
	# speed: the bends ahead, the car ahead, and never into a wall pointing the wrong way
	target_v = minf(plan_speed(), follow)
	if absf(alpha) > 1.2: target_v = minf(target_v, 6.0)
	var err := target_v - v
	var th := 0.0
	var br := 0.0
	if err > -0.6: th = clampf(0.35 + err * 0.4, 0.0, 1.0)
	elif err < -1.2: br = clampf((-err - 0.6) * 0.45, 0.0, 1.0)
	if v < 1.0: br = minf(br, 0.25)
	# traction control, launches included: ease off while the tires spin, feed it back in as they
	# bite (wheelspin off the line on a wet street goes nowhere, and sideways)
	var spin := sim.drive_slip()
	_tc = maxf(0.06, _tc - 3.0 * dt) if spin > 2.5 else minf(1.0, _tc + (1.2 if spin < 1.5 else 0.3) * dt)
	th = minf(th, _tc)
	if sim.gear < 0 and th > 0.0: th = maxf(th, 0.4)    # out of reverse
	# stuck: wants to go, isn't, and it isn't just wheelspin it's working through
	_stuck_t = _stuck_t + dt if target_v > 2.0 and br == 0.0 and v < 0.7 and spin < 4.0 else maxf(0.0, _stuck_t - dt * 0.5)
	if _stuck_t > 2.0:
		_stuck_t = 0.0
		_back_t = 1.6
	_br_last = br
	last_in = [th, br, st, 0.0]
	_trace_n += 1
	if _trace_n % 6 == 0:
		trace.append("%s v%.1f vx%.1f want%.1f th%.2f br%.2f st%.2f a%.2f seg%d g%d slip%.1f w%.1f stuck%.1f" % [str(sim.pos.round()), v, sim.vx, target_v, th, br, st, alpha, track.seg, sim.gear, sim.drive_slip(), sim.w_wheel, _stuck_t])
		if trace.size() > 40: trace.pop_front()
	return last_in

## No real progress along its line for a while (stuck, spun, shoved onto the grass): once you're
## not around to see it, it's back on the road (somebody's cousin with a truck). Returns true on
## the frame it happens.
func _rescue(dt: float, here: float) -> bool:
	if track.dist > _best_dist + 3.0 or target_v < 2.0:
		_best_dist = maxf(_best_dist, track.dist)
		_lost_t = 0.0
		return false
	_lost_t += dt
	if _lost_t < 7.0: return false
	var you: PlayerCar = traffic.player if traffic else null
	if you and you.sim.pos.distance_to(sim.pos) < 70.0: return false
	_lost_t = 0.0
	var s := here + 4.0
	sim.pos = point_at(s)
	sim.heading = dir_at(s).angle()
	sim.vx = 0.0
	sim.vy = 0.0
	sim.yaw_rate = 0.0
	sim.w_wheel = 0.0
	sim.w_eng = float(spec.engine.idle_rpm) / CarSim.RPM
	sim.gear = 1
	_tc = 0.3
	position = sim.pos * PX
	_pass = 0.0
	_back_t = 0.0
	return true

func _lights(dt: float, _st: float) -> void:
	lights_on = night
	view.headlights = lights_on
	head_light.visible = lights_on
	head_light.rotation = sim.heading
	if lights.a <= 0.0: return
	_flash_t2 += dt
	if _bar == null:
		_bar = LightBar.new()
		_bar.z_index = 1
		add_child(_bar)
		_bar_light = PointLight2D.new()
		_bar_light.texture = city._light_tex(Color(1, 1, 1))
		_bar_light.texture_scale = 1.4
		add_child(_bar_light)
	var bar := _bar as LightBar
	bar.heading = sim.heading
	bar.width = float(spec.width)
	bar.on = siren
	bar.t = _flash_t2
	_bar_light.visible = siren
	if siren:
		var red := fmod(_flash_t2 * 3.0, 1.0) < 0.5
		_bar_light.color = Color(1.0, 0.15, 0.1) if red else Color(0.15, 0.3, 1.0)
		_bar_light.energy = 2.4

## The bar on the roof: off, it's a dark strip; on, it flashes red and blue, side to side.
class LightBar extends Node2D:
	var heading := 0.0
	var width := 1.8
	var on := false
	var t := 0.0

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var px := CarArt.PX
		var f := Vector2(cos(heading), sin(heading))
		var r := Vector2(-f.y, f.x)
		var half := width * 0.42 * px
		var c := CarView.screen_up * 17.0        # up on the roof, over the top slice
		var phase := fmod(t * 3.0, 1.0) < 0.5
		for side: float in [-1.0, 1.0]:
			var a: Vector2 = c + r * side * half
			var b: Vector2 = c + r * side * 0.12 * px
			var col := Color("1a1a22")
			if on:
				var lit: bool = (side < 0.0) == phase
				col = (Color(1.0, 0.18, 0.12) if side < 0.0 else Color(0.2, 0.4, 1.0)) if lit else col.lightened(0.2)
			draw_line(a + f * 0.1 * px, b + f * 0.1 * px, col, 0.45 * px)
			if on and col.r + col.b > 1.0: draw_line(a + f * 0.1 * px, b + f * 0.1 * px, Color(1, 1, 1, 0.55), 0.15 * px)
		draw_line(c - r * 0.12 * px, c + r * 0.12 * px, Color("dcdcdc"), 0.45 * px)
