## One car in traffic. Driven by the rules in Traffic; drawn with the same stacked art as yours.
## When something hits it, it stops being a driver and becomes a sliding, spinning object for a
## while (hazards on), then gets back in its lane if it can.
class_name TrafficCar
extends AnimatableBody2D

const PX := CarArt.PX
const A_MAX := 1.8          # comfortable acceleration (m/s²)
const CLASS_ACCEL := { "exotic": 2.6, "sports": 2.3, "muscle": 2.3, "hot_hatch": 2.2, "pony": 2.1, "rally": 2.2,
	"kei": 1.3, "van": 1.4, "work_truck": 1.3, "hd_pickup": 1.4, "minivan": 1.6, "economy": 1.6, "classic": 1.5 }
var a_max := A_MAX
const B_COMF := 2.6         # comfortable braking
const T_GAP := 1.4          # time gap it keeps (s)
const S0 := 2.2             # minimum gap when stopped (m)

var traffic: Traffic
var rng := RandomNumberGenerator.new()
var spec: Dictionary
var view: CarView
var shape: CollisionShape2D
var head_light: PointLight2D
var a := 0                   # on the edge from node a to node b
var b := 0
var c_next := -1             # where it goes after b
var s := 0.0
var lane_i := 0
var pos := Vector2.ZERO      # metres
var heading := 0.0
var v := 0.0
var acc := 0.0
var length := 4.5
var width := 1.8
var temper := 1.0            # some drive faster than others
var turn_ahead := 0.0        # signed turn at the next node (rad), for the corridor and blinkers
var stopped_at := -1         # the junction it has made its full stop at
var entered := -1            # the junction it's crossing
var entered_from := -1       # and the node it came into it from
var wait_t := 0.0
var last_rule := ""
var lead_obj = null
var stop_time := 0.0
var _path := PackedVector2Array()
var state := "drive"         # drive, wrecked, parked
var wreck_v := Vector2.ZERO
var spin := 0.0
var wreck_t := 0.0
var damage := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
var gone := false
var paint := Color.WHITE
var looks := {}              # its wear, its sign, its ladder, its mods (Traffic.dress)
# a semi's trailer: drawn, solid, and swinging on the fifth wheel behind the tractor
var trailer: CarView
var trailer_shape: CollisionShape2D
var trailer_heading := 0.0
var trailer_len := 0.0       # the size it's drawn at (m)
var trailer_centre := Vector2.ZERO
var hitch_back := 0.0        # from the tractor's middle back to the fifth wheel (m)
var highway_only := false    # semis stay on the Trans-Canada
var big := false             # buses and trucks stick to the bigger roads where they can
var _art_damage := -1.0
var pull := 0.0              # moved over (m, right) for a siren coming up behind

static var _cone: ImageTexture

func setup(body: Dictionary, p: Color, na: int, nb: int, ns: float, lane: float) -> void:
	spec = body.duplicate()
	paint = p
	# the size it's drawn at (and bumps into things at): bigger than life, like every car on the road
	length = float(body.length) * CarArt.CAR_SCALE
	width = float(body.width) * CarArt.CAR_SCALE
	a = na
	b = nb
	s = ns
	var road := traffic.edge_road(a, b)
	var lanes: Array = Traffic.LANE[road.cls]
	lane_i = lanes.find(lane)
	if lane_i < 0: lane_i = 0
	pos = traffic.lane_point(a, b, s, lane)
	var d := traffic.map.g_pos[b] - traffic.map.g_pos[a]
	heading = d.angle()
	temper = 0.88 + rng.randf() * 0.25
	# what the car is changes how it's driven: a kei truck crawls off the line, a sports car doesn't
	var cls := String(body.get("class", ""))
	a_max = float(CLASS_ACCEL.get(cls, A_MAX))
	if cls in ["sports", "exotic", "muscle", "hot_hatch", "pony", "rally"]: temper += 0.06
	elif cls in ["classic", "kei", "work_truck", "hd_pickup", "van"]: temper -= 0.06
	sync_to_physics = false
	shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, width) * PX * Vector2(0.95, 0.9)
	shape.shape = rect
	add_child(shape)
	looks = body.get("looks", {})
	var art_cues: Dictionary = body.get("art", {})
	big = length > 9.5
	if art_cues.has("tractor"): _hook_trailer(body)
	view = CarView.new()
	view.build(spec, paint, 0.0, rng.randi(), CarArt.CAR_SCALE, looks)
	add_child(view)
	head_light = PointLight2D.new()
	if _cone == null: _cone = _cone_tex()
	head_light.texture = _cone
	head_light.energy = 1.0
	head_light.color = Color(1.0, 0.97, 0.9)
	head_light.texture_scale = 1.2
	head_light.offset = Vector2(64.0 * 1.2, 0)      # the lamp end of the beam on the bumper
	CarArt.reach_road(head_light)
	head_light.visible = false
	add_child(head_light)
	_place()

static func _cone_tex() -> ImageTexture:
	return CarArt.beam_tex(128, 72, 0.8)

func sort_point() -> Vector2:
	return global_position

func velocity_vec() -> Vector2:
	if state == "wrecked": return wreck_v
	return Vector2(cos(heading), sin(heading)) * v

func desired_speed(road: Dictionary) -> float:
	var v0: float = Traffic.SPEED[road.cls] * temper
	match traffic.world.surface_at(pos):
		"wet": v0 *= 0.88
		"snow", "mud": v0 *= 0.65
		"ice": v0 *= 0.45
	if traffic.sky.fog > 0.5: v0 *= 0.75
	return v0

func _lane(road: Dictionary) -> float:
	var lanes: Array = Traffic.LANE[road.cls]
	return float(lanes[mini(lane_i, lanes.size() - 1)]) + pull

## A siren coming up behind: move over and slow down (0 = carry on, 1 = pulled over).
func _siren_behind() -> float:
	var fwd := Vector2(cos(heading), sin(heading))
	for o in traffic.extra:
		if not is_instance_valid(o) or not o.siren: continue
		var rel: Vector2 = (o as AiCar).sim.pos - pos
		if rel.length_squared() < 50.0 * 50.0 and rel.dot(fwd) < 2.0: return 1.0
	return 0.0

# ------------------------------------------------------------------ driving

## A trailer behind a semi tractor: a box with the outfit's name on it, on the fifth wheel.
func _hook_trailer(body: Dictionary) -> void:
	highway_only = true
	trailer_len = 13.6 * CarArt.CAR_SCALE
	var d := CarGen.design(body)
	hitch_back = (0.5 - float(d.wr) - 0.03) * length
	trailer_heading = heading
	trailer = CarView.new()
	var colours := ["#e8e8e8", "#f0f0ec", "#d8d8d4", "#c8342c", "#2c4a8a", "#e8e8e8"]
	var t_looks := { "decal": rng.randi() % CarArt.DECALS.size() } if rng.randf() < 0.7 else {}
	trailer.build({ "body": "trailer", "length": 13.6, "width": 2.55, "track": 2.1 }, Color(String(colours[rng.randi() % colours.size()])), 0.0, rng.randi(), CarArt.CAR_SCALE, t_looks)
	add_child(trailer)
	trailer_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(trailer_len, 2.55 * CarArt.CAR_SCALE) * PX * Vector2(0.95, 0.9)
	trailer_shape.shape = rect
	add_child(trailer_shape)
	_tow(0.0)

## The trailer follows its fifth wheel: it swings toward the way the tractor's heading, the
## faster the further it's gone and the shorter the trailer.
func _tow(dt: float) -> void:
	if trailer == null: return
	var fwd := Vector2(cos(heading), sin(heading))
	var kingpin := pos - fwd * hitch_back
	var speed := velocity_vec().length()
	trailer_heading += sin(angle_difference(trailer_heading, heading)) * speed / maxf(1.0, trailer_len * 0.8) * dt
	trailer_centre = kingpin - Vector2.from_angle(trailer_heading) * (trailer_len * 0.5 - 1.2 * CarArt.CAR_SCALE)
	var local := (trailer_centre - pos) * PX
	trailer.position = local
	trailer.heading = trailer_heading
	trailer.lean = Vector2.ZERO
	trailer_shape.position = local
	trailer_shape.rotation = trailer_heading
	trailer.headlights = view.headlights if view else false
	trailer.braking = view.braking if view else false

func drive(dt: float) -> void:
	_tow(dt)
	if state == "wrecked":
		_wrecked(dt)
		_place()
		return
	if state == "parked":
		wreck_t += dt
		_place()
		return
	var map := traffic.map
	var road := traffic.edge_road(a, b)
	if road.is_empty():
		gone = true
		return
	var yielding := _siren_behind()
	# move over for the siren, as far as the road goes (not up onto the sidewalk)
	var lanes: Array = Traffic.LANE[road.cls]
	var room := clampf(float(road.get("w", 9.0)) / 2.0 - float(lanes[mini(lane_i, lanes.size() - 1)]) - width / 2.0 - 0.2, 0.0, 1.6)
	pull = move_toward(pull, room * yielding, dt * 1.2)
	var A := map.g_pos[a]
	var B := map.g_pos[b]
	var L := A.distance_to(B)
	if c_next < 0: c_next = traffic.next_node(a, b, self)
	var din := (B - A).normalized()
	var dout := (map.g_pos[c_next] - B).normalized() if c_next != b else -din
	turn_ahead = din.angle_to(dout) if c_next != a or map.g_adj[b].size() == 1 else PI
	var db := L - s
	# --- steer at a point a little way along its path (pure pursuit), and stay in lane
	var path := path_ahead(maxf(30.0, v * 3.0))
	_path = path
	var look := clampf(2.5 + v * 0.35, 3.0, 12.0)
	var target := along(path, look)
	var to_t := target - pos
	var alpha := wrapf(to_t.angle() - heading, -PI, PI)
	var curv := 2.0 * sin(alpha) / maxf(to_t.length(), 1.0)
	heading = wrapf(heading + clampf(v * curv, -1.8, 1.8) * dt, -PI, PI)
	if v < 0.5 and absf(alpha) > 0.3: heading += signf(alpha) * minf(absf(alpha), 0.6 * dt)
	# drift back onto the lane line on the straights (AI drivers don't wander)
	if absf(turn_ahead) < 0.2 or (db > 12.0 and s > 8.0):
		var nrm := Vector2(-din.y, din.x)
		var lat_err := (pos - A).dot(nrm) - _lane(road)
		pos -= nrm * clampf(lat_err, -1.5 * dt, 1.5 * dt)
	# --- how fast it wants to go: the limit, then slower for the bend ahead
	var v0 := desired_speed(road) * (1.0 - 0.55 * yielding)
	var jr: float = traffic.junctions.get(b, {}).get("radius", 0.0)
	var bend := absf(turn_ahead)
	if bend > 0.25:
		var v_turn := lerpf(v0, 5.0, clampf(bend / 1.5, 0.0, 1.0))
		v0 = minf(v0, sqrt(v_turn * v_turn + 2.0 * B_COMF * maxf(0.0, db - jr)))
	# --- what's ahead: the car in front, or a stop line it has to obey
	var lead := traffic.leader(self, 60.0)
	lead_obj = lead[2]
	var gap: float = lead[0]
	var v_lead: float = lead[1]
	if traffic.junctions.has(b) and entered != b and db < 50.0:
		var stop_d := db - traffic.stop_line(b, a)
		var rule := traffic.may_enter(self, b, a, c_next, stop_d)
		last_rule = rule
		if rule == "go" and traffic.junctions[b].inside.has(self): _enter_box(b)
		if rule == "stop":
			if stop_d < gap:
				gap = maxf(stop_d, 0.01)
				v_lead = 0.0
			if v < 0.4 and stop_d < 4.5 and stopped_at != b:
				stopped_at = b
				stop_time = Traffic.clock
		elif db < jr + 2.0:
			_enter_box(b)
	# --- the Intelligent Driver Model
	var dv := v - v_lead
	var s_star := S0 + maxf(0.0, v * T_GAP + v * dv / (2.0 * sqrt(a_max * B_COMF)))
	var free := 1.0 - pow(v / maxf(v0, 0.5), 4.0)
	var inter := (s_star / maxf(gap, 0.1)) ** 2 if gap < 200.0 else 0.0
	acc = clampf(a_max * (free - inter), -9.0, a_max)
	v = maxf(0.0, v + acc * dt)
	wait_t = wait_t + dt if v < 1.5 else 0.0
	pos += Vector2(cos(heading), sin(heading)) * v * dt
	# --- progress along the edge, and on to the next one
	s = (pos - A).dot(din)
	# on to the next road: at the end of this one, or once it's round the corner onto the next
	var past_corner := c_next >= 0 and c_next != a and absf(turn_ahead) > 0.2 and s > L - 14.0 and pos.distance_to(B) < 14.0 and (pos - B).dot(dout) > 0.5
	if s >= L - 0.2 or past_corner:
		a = b
		b = c_next
		c_next = -1
		s = (pos - map.g_pos[a]).dot((map.g_pos[b] - map.g_pos[a]).normalized())
		stopped_at = -1
		# turned round at a dead end and heading back into the junction it just crossed: that's a
		# new crossing, with the rules and all
		if entered == b: _leave_box()
	if entered >= 0 and entered != b and pos.distance_to(map.g_pos[entered]) > float(traffic.junctions.get(entered, {}).get("radius", 6.0)) + 3.0:
		_leave_box()
	# --- lights
	var turning := db < 40.0 and absf(turn_ahead) > 0.5 and absf(turn_ahead) < 2.8
	view.blink_left = turning and turn_ahead < 0.0
	view.blink_right = turning and turn_ahead > 0.0
	view.braking = acc < -0.8 or v < 0.2
	_place()

## Into junction `n`'s box (and out of the last one, however close the two junctions are: a
## car still on a junction's list keeps everybody else at its stop signs waiting).
func _enter_box(n: int) -> void:
	if entered >= 0 and entered != n: traffic.leave(self, entered)
	traffic.enter(self, n)
	entered = n
	entered_from = a

func _leave_box() -> void:
	if entered >= 0: traffic.leave(self, entered)
	entered = -1
	entered_from = -1

## The line it's about to drive, as points from where it is now: down its lane, round a
## smooth curve through the junction (from its lane in to the right lane out), and on.
func path_ahead(reach: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(pos)
	var map := traffic.map
	var road := traffic.edge_road(a, b)
	if road.is_empty(): return out
	var A := map.g_pos[a]
	var B := map.g_pos[b]
	var L := A.distance_to(B)
	var din := (B - A) / maxf(L, 0.01)
	var turning := c_next >= 0 and c_next != a and absf(turn_ahead) > 0.2
	var r_in := 0.0
	if turning:
		r_in = minf(maxf(float(traffic.junctions.get(b, {}).get("radius", 0.0)), 5.0), L * 0.45)
	var d := s + 3.0
	var end_s := L - r_in
	while d < end_s and d - s < reach:
		out.append(traffic.lane_point(a, b, d, _lane(road)))
		d += 3.0
	if d - s >= reach or c_next < 0: return out
	var r2 := traffic.edge_road(b, c_next)
	if r2.is_empty(): return out
	var C := map.g_pos[c_next]
	var L2 := B.distance_to(C)
	var dout := (C - B) / maxf(L2, 0.01)
	if turning:
		var r_out := minf(r_in, L2 * 0.45)
		var p0 := traffic.lane_point(a, b, end_s, _lane(road))
		var p2 := traffic.lane_point(b, c_next, r_out, _lane(r2))
		# the corner of the two lane lines is the curve's control point
		var den := din.cross(dout)
		var p1 := (p0 + p2) / 2.0
		if absf(den) > 0.05:
			var t := (p2 - p0).cross(dout) / den
			p1 = p0 + din * t
		var ahead := false
		for k in range(1, 7):
			var u := float(k) / 6.0
			var q := p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
			# partway round already: the bits of the curve behind it aren't ahead of it (aiming
			# back at them sends it round in circles in the middle of the junction)
			var tangent := (p1 - p0) * (1.0 - u) + (p2 - p1) * u
			if not ahead and k < 6 and (q - pos).dot(tangent) <= 0.0: continue
			ahead = true
			out.append(q)
		d = r_out + 3.0
	else:
		d = 1.5
	var left := reach - (out[out.size() - 1].distance_to(pos))
	while d < L2 and left > 0.0:
		out.append(traffic.lane_point(b, c_next, d, _lane(r2)))
		d += 3.0
		left -= 3.0
	return out

## The point `dist` metres along a polyline.
static func along(pts: PackedVector2Array, dist: float) -> Vector2:
	var acc := 0.0
	for i in pts.size() - 1:
		var L := pts[i].distance_to(pts[i + 1])
		if acc + L >= dist and L > 0.0: return pts[i].lerp(pts[i + 1], (dist - acc) / L)
		acc += L
	return pts[pts.size() - 1]

func _place() -> void:
	position = pos * PX
	shape.rotation = heading
	view.heading = heading
	view.lean = view.lean.lerp(Vector2(clampf(-acc * 0.25, -2.0, 2.0), 0.0), 0.2)
	view.wheel_turn += v * 0.05
	view.steer = clampf(turn_ahead * 0.3, -0.5, 0.5) if state == "drive" and absf(turn_ahead) > 0.3 else 0.0
	var dark: bool = traffic.night
	view.headlights = dark
	head_light.visible = dark and pos.distance_to(traffic.player.sim.pos) < 80.0 if traffic.player else false
	head_light.rotation = heading
	head_light.position = Vector2(cos(heading), sin(heading)) * length * PX * 0.5

# ------------------------------------------------------------------ crashes

## Something hit it. `dv` is the change in velocity (m/s, world), `at` where (metres, world).
func hit(dv: Vector2, at: Vector2) -> void:
	if state != "wrecked":
		wreck_v = velocity_vec()
	wreck_v += dv
	var r := at - pos
	spin += r.cross(dv) * 0.25 / maxf(length, 1.0)
	state = "wrecked"
	wreck_t = 0.0
	_leave_box()
	# where it got hit, in the car's own frame
	var fwd := Vector2(cos(heading), sin(heading))
	var local := Vector2(r.dot(fwd), r.dot(Vector2(-fwd.y, fwd.x)))
	var hard := clampf(dv.length() / 12.0, 0.05, 1.0)
	if absf(local.x) / length > absf(local.y) / width:
		damage["front" if local.x > 0.0 else "rear"] = minf(1.0, damage["front" if local.x > 0.0 else "rear"] + hard)
	else:
		damage["right" if local.y > 0.0 else "left"] = minf(1.0, damage["right" if local.y > 0.0 else "left"] + hard)
	_refresh_art()

func _refresh_art() -> void:
	var total := 0.0
	for k in damage: total += damage[k]
	if absf(total - _art_damage) < 0.1: return
	_art_damage = total
	view.build(spec, paint, damage, rng.randi(), CarArt.CAR_SCALE, looks)

func _wrecked(dt: float) -> void:
	wreck_t += dt
	var motion := wreck_v * dt * PX
	position = pos * PX
	var col := move_and_collide(motion)
	if col:
		var n := col.get_normal()
		wreck_v -= n * wreck_v.dot(n) * 1.4
		wreck_v *= 0.7
		spin *= 0.6
		if col.get_collider() is TrafficCar:
			var other: TrafficCar = col.get_collider()
			other.hit(-n * maxf(0.0, -wreck_v.dot(n)) * 0.5 + wreck_v * 0.3, pos)
	pos = position / PX
	heading += spin * dt
	var k := exp(-1.8 * dt)                 # tires scrubbing sideways stop it fast
	wreck_v *= k
	spin *= exp(-2.5 * dt)
	v = 0.0
	acc = 0.0
	view.blink_left = wreck_t > 1.0
	view.blink_right = wreck_t > 1.0
	view.braking = true
	if wreck_v.length() < 0.3 and absf(spin) < 0.1 and wreck_t > 6.0:
		# back to the lane if it's still close to it and pointing the right way, otherwise it
		# stays where it is with the hazards on until it's out of sight
		var lane_p := traffic.lane_point(a, b, clampf((pos - traffic.map.g_pos[a]).dot((traffic.map.g_pos[b] - traffic.map.g_pos[a]).normalized()), 0.0, 9999.0), _lane(traffic.edge_road(a, b)))
		var d := (traffic.map.g_pos[b] - traffic.map.g_pos[a]).angle()
		if lane_p.distance_to(pos) < 3.5 and absf(wrapf(d - heading, -PI, PI)) < 0.6 and damage.front < 0.8:
			state = "drive"
			view.blink_left = false
			view.blink_right = false
		else:
			state = "parked"
