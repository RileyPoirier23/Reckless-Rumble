## Moose and deer on the country roads. They come out at dusk and dawn (and all night), more of
## them in the fall when the moose are in rut. A deer at the roadside bolts across when you come
## up on it; a moose walks out and stands in the road looking at you. The horn moves them along.
## Hit a deer and it's a bent bumper; hit a moose at highway speed and it comes through the
## windshield. Their eyes shine in your headlights: a deer's at bumper height, a moose's too high
## for low beams to catch.
class_name Wildlife
extends Node2D

const MOOSE := { "len": 2.9, "wid": 0.95, "mass": 450.0, "height": 1.9, "walk": 1.4, "run": 7.0 }
const DEER := { "len": 1.6, "wid": 0.5, "mass": 70.0, "height": 1.0, "walk": 1.2, "run": 10.0 }
const ROADS := ["rural", "highway", "gravel"]
const MAX_AROUND := 3

var drive: Node
var animals: Array = []
var enabled := true
var rate := 1.0                # Settings > Difficulty: off 0, rare 0.4, normal 1, many 2
var rng := RandomNumberGenerator.new()
var _roll_t := 3.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.seed = int(Time.get_ticks_usec())

## How likely an animal turns up ahead in the next few seconds (0..1): the hour, the season, the
## road, and whether you're in one of the wildlife stretches (MapData.WILD, the ones with the
## yellow signs): nowhere else, and never in town. Moose are dusk and dawn animals; the fall rut
## brings them out.
static func odds(hour: float, season: String, road_cls: String, style: String, wild := {}) -> float:
	if wild.is_empty(): return 0.0
	if not road_cls in Wildlife.ROADS: return 0.0
	if style in ["downtown", "oldtown", "commercial", "residential", "industrial", "village"]: return 0.0
	var h := fmod(hour, 24.0)
	var t := 0.04                                          # broad daylight: now and then
	if (h >= 17.5 and h < 21.5) or (h >= 5.0 and h < 8.0): t = 0.35   # dusk and dawn
	elif h >= 21.5 or h < 5.0: t = 0.2                     # the middle of the night
	if season == "fall": t *= 1.5
	elif season == "winter": t *= 0.6
	if road_cls == "gravel": t *= 1.3
	return clampf(t, 0.0, 0.6)

## Moose or deer: it's mostly the stretch's own animal (moose country, deer country), and the fall
## is moose season.
static func pick_kind(season: String, x: float, zone_kind := "moose") -> String:
	var moose := (0.45 if season == "fall" else 0.3) if zone_kind == "moose" else 0.08
	return "moose" if x < moose else "deer"

func _physics_process(dt: float) -> void:
	var c: PlayerCar = drive.car
	if c == null or StoryState.active or not enabled:
		if not animals.is_empty(): clear()
		return
	for a in animals.duplicate():
		if a.pos.distance_to(c.sim.pos) > 320.0 or a.state == "gone": _remove(a)
	_roll_t -= dt
	if _roll_t <= 0.0:
		_roll_t = 4.0
		var map: MapData = drive.world.map
		var hit: Dictionary = map.road_at(c.sim.pos)
		var road: Dictionary = hit.get("road", {})
		var style := String(map.zone_at(c.sim.pos).get("style", "rural"))
		var wild := map.wild_zone_at(c.sim.pos, String(road.get("name", "")))
		if animals.size() < MAX_AROUND and c.sim.speed() > 8.0 and rng.randf() < rate * odds(drive.sky.time_h, drive.sky.season, String(road.get("cls", "")), style, wild):
			spawn_ahead(c, pick_kind(drive.sky.season, rng.randf(), String(wild.kind)), wild)

## An animal at the roadside somewhere ahead of you, facing the road: only on the stretch's own
## road, inside the stretch.
func spawn_ahead(c: PlayerCar, kind: String, wild := {}) -> Animal:
	var map: MapData = drive.world.map
	var ahead := c.sim.pos + c.sim.forward() * rng.randf_range(110.0, 180.0)
	var rd := map.nearest_road(ahead, 40.0)
	if rd.is_empty(): return null
	if not spawn_ok(map, rd.point, rd.road, wild): return null
	var dir: Vector2 = rd.dir
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var half := float((rd.road as Dictionary).w) * 0.5
	var p: Vector2 = rd.point + Vector2(-dir.y, dir.x) * side * (half + rng.randf_range(2.5, 6.0))
	return spawn_at(kind, p, (rd.point - p).angle())

## Whether an animal can come out at this point on this road.
static func spawn_ok(map: MapData, p: Vector2, road: Dictionary, wild: Dictionary) -> bool:
	if wild.is_empty() or not (wild.r as Rect2).has_point(p): return false
	if not String(road.get("name", "")) in (wild.roads as Array): return false
	if not String(road.get("cls", "")) in Wildlife.ROADS: return false
	return map.zone_at(p).is_empty()

func spawn_at(kind: String, p: Vector2, h: float) -> Animal:
	var a := Animal.new()
	a.wild = self
	a.setup(kind, p, h, rng.randi())
	drive.ysort.add_child(a)
	animals.append(a)
	return a

func _remove(a) -> void:
	animals.erase(a)
	if is_instance_valid(a): a.queue_free()

func clear() -> void:
	for a in animals.duplicate(): _remove(a)


## One animal. Kinematic (it walks where it walks); when a car hits it, it gets shoved, and it
## gets shoved hard.
class Animal extends AnimatableBody2D:
	var wild: Wildlife
	var kind := "deer"
	var data: Dictionary = Wildlife.DEER
	var mass := 70.0
	var pos := Vector2.ZERO
	var heading := 0.0
	var state := "graze"        # graze, cross, stand, flee, hurt, gone
	var t := 0.0
	var v := 0.0
	var target := Vector2.ZERO
	var shove := Vector2.ZERO
	var spin := 0.0
	var antlers := false
	var _decided := false
	var _shape: CollisionShape2D
	var _rng := RandomNumberGenerator.new()
	var _col: Color

	func setup(k: String, p: Vector2, h: float, seed: int) -> void:
		kind = k
		data = Wildlife.MOOSE if k == "moose" else Wildlife.DEER
		mass = float(data.mass)
		pos = p
		heading = h
		_rng.seed = seed
		antlers = _rng.randf() < 0.5 and (k == "moose" or _rng.randf() < 0.6)
		_col = Color("3a2a1e") if k == "moose" else Color("8a6a46")
		_col = _col.lightened(_rng.randf_range(-0.08, 0.08))
		sync_to_physics = false
		_shape = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(float(data.len), float(data.wid)) * CarArt.PX * CarArt.CAR_SCALE
		_shape.shape = r
		add_child(_shape)
		_place()

	func sort_point() -> Vector2:
		return global_position

	func velocity_vec() -> Vector2:
		return shove if state == "hurt" else Vector2.from_angle(heading) * v

	## A car hit it: `dv` is the shove (m/s), `at` where.
	func hit(dv: Vector2, _at: Vector2) -> void:
		shove = velocity_vec() + dv
		spin = _rng.randf_range(-3.0, 3.0)
		state = "hurt"
		t = 0.0

	func _physics_process(dt: float) -> void:
		t += dt
		var c: PlayerCar = wild.drive.car
		if c == null: return
		var to_me := pos - c.sim.pos
		var d := to_me.length()
		var coming := c.sim.speed() > 3.0 and c.sim.world_velocity().dot(to_me) > 0.0
		var horn: bool = wild.drive.audio.horn and d < 80.0
		match state:
			"graze":
				heading += sin(t * 0.7 + float(_rng.seed % 7)) * 0.2 * dt
				if not _decided and coming and d < (60.0 if kind == "deer" else 75.0):
					_decided = true
					if kind == "deer" and _rng.randf() < 0.65: _cross(float(data.run))
					elif kind == "moose" and _rng.randf() < 0.55: _cross(float(data.walk))
				if horn and kind == "deer": _flee(c)
			"cross":
				v = move_toward(v, float(data.run) if kind == "deer" else (3.2 if horn else float(data.walk)), 6.0 * dt)
				var to_t := target - pos
				heading = lerp_angle(heading, to_t.angle(), minf(1.0, 4.0 * dt))
				# a moose in the road stops to look at your headlights
				if kind == "moose" and not horn and _on_road() and _rng.randf() < 0.6 * dt and t < 6.0:
					state = "stand"
					t = 0.0
				if to_t.length() < 1.0: _flee(c)
			"stand":
				v = move_toward(v, 0.0, 4.0 * dt)
				if horn or t > _rng.randf_range(4.0, 9.0):
					state = "cross"
					t = 6.0
			"flee":
				v = move_toward(v, float(data.run), 5.0 * dt)
				if t > 6.0: state = "gone"
			"hurt":
				pos += shove * dt
				shove *= exp(-2.5 * dt)
				heading += spin * dt
				spin *= exp(-3.0 * dt)
				if shove.length() < 0.5 and t > 1.5:
					# it gets up, shakes it off, and goes back into the trees
					state = "flee"
					t = 0.0
					heading = (pos - c.sim.pos).angle()
				_place()
				return
		pos += Vector2.from_angle(heading) * v * dt
		_place()

	func _on_road() -> bool:
		return not wild.drive.world.map.road_at(pos).is_empty()

	## Across the road to the far side.
	func _cross(speed: float) -> void:
		state = "cross"
		t = 0.0
		v = speed * 0.5
		var rd: Dictionary = wild.drive.world.map.nearest_road(pos, 30.0)
		if rd.is_empty():
			target = pos + Vector2.from_angle(heading) * 20.0
			return
		var half := float((rd.road as Dictionary).w) * 0.5
		target = rd.point + (rd.point - pos).normalized() * (half + 6.0)

	func _flee(c: PlayerCar) -> void:
		state = "flee"
		t = 0.0
		var rd: Dictionary = wild.drive.world.map.nearest_road(pos, 40.0)
		var away: Vector2 = (pos - rd.point).normalized() if not rd.is_empty() and pos.distance_to(rd.point) > 0.5 else (pos - c.sim.pos).normalized()
		heading = away.angle()

	func _place() -> void:
		position = pos * CarArt.PX
		_shape.rotation = heading
		queue_redraw()

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var px := CarArt.PX * CarArt.CAR_SCALE      # drawn to the same scale as the cars
		var f := Vector2.from_angle(heading)
		var r := Vector2(-f.y, f.x)
		var L := float(data.len) * px
		var W := float(data.wid) * px
		var up := CarView.screen_up * float(data.height) * px * 0.55
		var down := state == "hurt"
		var lift := up * (0.25 if down else 1.0)
		# shadow
		_quad(Vector2.ZERO, f * L * 0.5, r * W * 0.6, Color(0, 0, 0, 0.3))
		# legs: four dark sticks from the ground to the body
		if not down:
			var stride := sin(t * (10.0 if v > 3.0 else 4.0)) * (0.25 if v > 0.3 else 0.0)
			for k in 4:
				var fx := (0.32 if k < 2 else -0.32) * L + stride * px * (1.0 if k % 2 == 0 else -1.0)
				var fy := (0.3 if k % 2 == 0 else -0.3) * W
				var foot := f * fx + r * fy
				draw_line(foot, foot + lift * 0.85, _col.darkened(0.45), maxf(1.5, 0.12 * px))
		# the body, then the neck and head out front
		_quad(lift, f * L * 0.5, r * W * 0.5, _col)
		_quad(lift + up * 0.08, f * L * 0.35, r * W * 0.32, _col.lightened(0.08))
		var head := lift + f * L * (0.62 if kind == "moose" else 0.6) + up * 0.15
		_quad(head, f * L * (0.16 if kind == "moose" else 0.11), r * W * 0.24, _col.darkened(0.1))
		if kind == "moose":
			# the long nose and the dewlap
			_quad(head + f * L * 0.17, f * L * 0.07, r * W * 0.17, _col.darkened(0.25))
			if antlers:
				var ac := Color("c8b48a")
				for s: float in [-1.0, 1.0]:
					var base: Vector2 = head + r * s * W * 0.22 + up * 0.08
					_quad(base + r * s * W * 0.45, f * 0.25 * px, r * W * 0.35, ac)
		else:
			if antlers:
				for s: float in [-1.0, 1.0]:
					var base: Vector2 = head + r * s * W * 0.15 + up * 0.1
					draw_line(base, base + r * s * 0.35 * px + f * 0.2 * px + up * 0.2, Color("b8a07a"), 1.5)
			# the white tail goes up when it runs
			if state in ["flee", "cross"] and v > 3.0:
				_quad(lift - f * L * 0.52 + up * 0.12, f * 0.12 * px, r * 0.12 * px, Color("f4f0e8"))
		# eyes in the headlights: a deer's shine green at bumper height; a moose's sit above low beams
		var car: PlayerCar = wild.drive.car
		if car and car.lights_on and not down:
			var to_me := (pos - car.sim.pos)
			var dd := to_me.length()
			var in_beam := dd < (70.0 + 50.0 * car.beam) and car.sim.forward().dot(to_me / maxf(dd, 0.1)) > 0.92
			var catches := kind == "deer" or car.beam > 0.5
			var facing := Vector2.from_angle(heading).dot(-to_me / maxf(dd, 0.1)) > 0.2
			if in_beam and catches and facing:
				var glow := Color(0.7, 1.0, 0.6, 0.95) if kind == "deer" else Color(1.0, 0.85, 0.5, 0.9)
				for s: float in [-1.0, 1.0]:
					var e: Vector2 = head + f * L * 0.05 + r * s * W * 0.16 + up * 0.05
					draw_circle(e, 4.0, Color(glow, 0.18))
					draw_circle(e, 1.8, glow)

	func _quad(c: Vector2, ax: Vector2, ay: Vector2, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([c + ax + ay, c + ax - ay, c - ax - ay, c - ax + ay]), col)
