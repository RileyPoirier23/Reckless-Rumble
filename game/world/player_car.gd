## The car you drive: input -> CarSim -> collisions with the city -> what you see and hear.
class_name PlayerCar
extends CharacterBody2D

const PX := CarArt.PX

signal fatal(info: Dictionary)

var sim: CarSim
var view: CarView
var city: World
var skids: Skids
var hud: Hud
var spec: Dictionary
var paint: Color
var shape_node: CollisionShape2D
var smoke: Array[CPUParticles2D] = []
var steam: CPUParticles2D
var engine_smoke: CPUParticles2D
var smoke_on := true           # Settings > Graphics: tire smoke
var head_light: PointLight2D
var tail_light: PointLight2D
var damage_bucket := 0
var throttle_in := 0.0
var start_pos := Vector2.ZERO
var start_heading := 0.0
var quiet := false                # somebody else's car: it doesn't talk to the HUD
var hit_police := 0               # times this car drove into a police car (not the other way round)
var last_hit: Object = null       # the last thing it ran into
var hit_frame := -1               # the physics frame it last hit something
var skid_base := 10               # its own strips of rubber on the road

static var _cone: ImageTexture

func setup(car_spec: Dictionary, the_city: World, the_skids: Skids, the_hud: Hud, at_m: Vector2, heading: float) -> void:
	spec = car_spec
	city = the_city
	skids = the_skids
	hud = the_hud
	paint = Color(spec.paint)
	start_pos = at_m
	start_heading = heading
	sim = CarSim.new(spec)
	sim.set_ambient(city.ambient())
	sim.cold_start()
	sim.pos = at_m
	sim.heading = heading
	position = at_m * PX
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 1 | 2            # the city and traffic (1), and the other drivers' cars (2)
	safe_margin = 0.5
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(spec.length), float(spec.width)) * PX * CarArt.CAR_SCALE * Vector2(0.96, 0.9)
	shape_node.shape = shape
	add_child(shape_node)
	view = CarView.new()
	view.art = CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE)
	add_child(view)
	for i in 2:
		var p := _particles(Color(0.85, 0.85, 0.88, 0.55), 1.2, 60)
		smoke.append(p)
	steam = _particles(Color(0.95, 0.97, 1.0, 0.5), 1.6, 30)
	engine_smoke = _particles(Color(0.12, 0.12, 0.14, 0.7), 2.0, 40)
	head_light = PointLight2D.new()
	if _cone == null: _cone = _cone_tex()
	head_light.texture = _cone
	head_light.energy = 1.3
	head_light.color = Color(1.0, 0.98, 0.92)
	CarArt.reach_road(head_light)
	add_child(head_light)
	tail_light = PointLight2D.new()
	tail_light.texture = city._light_tex(Color(1, 0.2, 0.15))
	tail_light.texture_scale = 0.25
	tail_light.energy = 0.6
	tail_light.color = Color(1, 0.12, 0.08)
	CarArt.reach_road(tail_light)
	add_child(tail_light)

## The smoke lives on the parent (so it stays where it was puffed out): it goes with the car.
func _exit_tree() -> void:
	for p in smoke + [steam, engine_smoke]:
		if is_instance_valid(p): p.queue_free()

func _particles(col: Color, life: float, amount: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emitting = false
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, -6)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.0)])
	p.color_ramp = ramp
	p.z_index = 2500
	p.z_as_relative = false
	get_parent().add_child.call_deferred(p)
	return p

## The headlight beam: 160 px long from the bumper, out ahead of the car.
static func _cone_tex() -> ImageTexture:
	return CarArt.beam_tex(160, 96)

func respawn() -> void:
	sim.reset_parts()
	sim.set_ambient(city.ambient())
	sim.cold_start()
	sim.pos = start_pos
	sim.heading = start_heading
	sim.vx = 0.0
	sim.vy = 0.0
	sim.yaw_rate = 0.0
	sim.w_wheel = 0.0
	sim.gear = 1
	position = start_pos * PX
	damage_bucket = -1
	for k in damage: damage[k] = 0.0
	if not quiet: hud.notify("TOWED HOME AND FIXED UP. DON'T TELL GUS.")

var can_die := true               # the story turns this off when a crash is the plot
var dead := false
var _hb_t := 99.0                 # seconds since the handbrake was pulled
var _water_t := 0.0
var impaired := 0.0               # 0 sober .. 1 hammered: lag, sway, overcorrection
var _st_lag := 0.0
var _drunk_t := 0.0
var high_beams := false
var beam := 0.0                   # 0 = low, 1 = high (fades between)
var lights_on := false
var _flash_t := 0.0
var _hb_down := 0.0
var blink := 0                    # -1 left, 1 right, 0 off
var hazards := false
var _blink_steer := 0.0
var locked := false               # a menu is up: hands off, ease to a stop
var show_mode := false            # parked at the meet: out of gear, handbrake on, the gas just revs it
var _in_show := false

## The driver's inputs, plus the help a modern car gives you on STREET (traction control and
## a little stability control). SIM gives you none; ARCADE gives you more.
func _inputs(dt: float) -> Array:
	var ins := Controls.drive_inputs(dt, float(spec.get("steer_lock", 0.55)))
	var th: float = ins[0]
	var br: float = ins[1]
	var st: float = ins[2]
	var hb: float = ins[3]
	# a wheel turns the road wheels one for one: no help that would move them without the rim
	var wheel := Wheel.active()
	sim.direct_steer = wheel
	if impaired > 0.0:
		# drunk: the wheel answers late, the car drifts, and you overcorrect
		_drunk_t += dt
		_st_lag += (st - _st_lag) * (1.0 - exp(-dt / (0.06 + 0.45 * impaired)))
		st = _st_lag * (1.0 + 0.35 * impaired) + sin(_drunk_t * 0.9) * 0.16 * impaired + sin(_drunk_t * 2.3 + 1.0) * 0.06 * impaired
		th = clampf(th * (1.0 + 0.4 * impaired * sin(_drunk_t * 1.7)), 0.0, 1.0)
	if sim.assist != CarSim.Assist.SIM:
		var v := sim.speed()
		# traction control: back off the gas while the rears spin up
		var spin := sim.drive_slip()
		var tc_limit := 2.5 if sim.assist == CarSim.Assist.STREET else 1.5
		if spin > tc_limit and v > 1.5 and hb < 0.1:
			th *= clampf(1.0 - (spin - tc_limit) * 0.35, 0.15, 1.0)
		if not wheel:
			# stability: steer into a slide for you, and don't let the stick over-rotate at speed
			# (how much less lock at speed is a setting: Settings > Controls > SPEED STEERING)
			var beta := atan2(sim.vy, maxf(absf(sim.vx), 1.0))
			var help := 0.55 if sim.assist == CarSim.Assist.STREET else 0.9
			if v > 4.0 and absf(beta) > 0.08 and hb < 0.1:
				st = clampf(st + beta * help * 1.6, -1.0, 1.0)
			var at_speed := lerpf(1.0, 0.55 if sim.assist == CarSim.Assist.STREET else 0.45, clampf(float(GameSettings.get_v("controls", "speed_steer")), 0.0, 1.5))
			st *= lerpf(1.0, at_speed, clampf(v / 35.0, 0.0, 1.0))
	return [th, br, st, hb]

func _lights(dt: float, st: float) -> void:
	# high beams: tap to switch, hold to flash (hands off while a menu's up; the lamps still work)
	var hands := not locked
	if hands and Input.is_action_just_pressed("high_beams"): _hb_down = 0.0
	if hands and Input.is_action_pressed("high_beams"): _hb_down += dt
	if hands and Input.is_action_just_released("high_beams"):
		if _hb_down < 0.35: high_beams = not high_beams
	var flashing := hands and Input.is_action_pressed("high_beams") and _hb_down >= 0.35
	var want := 1.0 if (high_beams or flashing) else 0.0
	beam = move_toward(beam, want, dt * 5.0)
	var on := lights_on or flashing
	head_light.visible = on
	head_light.texture_scale = lerpf(1.4, 2.4, beam)
	head_light.energy = lerpf(1.25, 1.75, beam) * (0.0 if not on else 1.0)
	# the texture's left edge (the lamp end of the beam) sits on the front bumper
	head_light.offset = Vector2(80.0 * head_light.texture_scale, 0)
	view.headlights = on
	# blinkers: they cancel themselves when you straighten out after a turn
	if hands and Input.is_action_just_pressed("blink_left"): blink = 0 if blink == -1 else -1
	if hands and Input.is_action_just_pressed("blink_right"): blink = 0 if blink == 1 else 1
	if hands and Input.is_action_just_pressed("hazards"): hazards = not hazards
	if blink != 0:
		if signf(st) == float(blink) and absf(st) > 0.5: _blink_steer = 1.0
		elif _blink_steer > 0.0 and absf(st) < 0.15:
			blink = 0
			_blink_steer = 0.0
	view.blink_left = hazards or blink == -1
	view.blink_right = hazards or blink == 1

func _physics_process(dt: float) -> void:
	if dead: return
	# locked: ease to a stop and hold it there on the handbrake (the brake pedal past 0.3 at a
	# standstill would find reverse)
	var ins := _inputs(dt) if not locked else ([0.0, 0.3, 0.0, 0.0] if sim.speed() > 0.5 else [0.0, 0.25, 0.0, 1.0])
	if show_mode and not locked:
		sim.gear = 0
		ins = [Controls.trigger("throttle"), 0.0, 0.0, 1.0]
		_in_show = true
	elif _in_show:
		_in_show = false
		if sim.auto_gearbox: sim.gear = 1
	var th: float = ins[0]
	var br: float = ins[1]
	var st: float = ins[2]
	var hb: float = ins[3]
	_lights(dt, Controls.steer_axis() if not locked else 0.0)
	throttle_in = th
	_hb_t = 0.0 if hb > 0.5 else _hb_t + dt
	sim.surface = city.surface_at(sim.pos)
	# into the river: a couple of seconds and that's it
	_water_t = _water_t + dt if sim.surface == "water" else 0.0
	if _water_t > 2.2: _die("water", "", sim.speed() * 3.6 + 40.0, null)
	var before := sim.pos
	sim.step(dt, th, br, st, hb)
	var motion := (sim.pos - before) * PX
	position = before * PX
	shape_node.rotation = sim.heading
	var col := move_and_collide(motion)
	if col:
		var n := col.get_normal()
		var vw := sim.world_velocity()
		var other = col.get_collider()
		last_hit = other
		hit_frame = Engine.get_physics_frames()
		var vn := -vw.dot(n)
		var is_car := other is TrafficCar or other is PlayerCar or other is Wildlife.Animal
		if is_car: vn = -(vw - other.velocity_vec()).dot(n)
		if vn > 0.0:
			var hit_dir := -n
			var d := hit_dir.dot(sim.forward())
			var where := "front" if d > 0.6 else ("rear" if d < -0.6 else "side")
			_check_fatal(col, other, vn, d, vw.length())
			if other is AiCar and (other as AiCar).lights.a > 0.0 and vn > 3.0: hit_police += 1
			sim.impact(vn, where)
			_take_damage(-n, vn, col.get_position() / PX)
			if is_car:
				# two cars: share the hit by mass (traffic's is a guess: about 1,500 kg)
				var m1 := float(spec.mass)
				var m2 := 1500.0
				if other is PlayerCar: m2 = float(other.spec.mass)
				elif other is Wildlife.Animal:
					m2 = (other as Wildlife.Animal).mass
					if (other as Wildlife.Animal).state != "hurt": Awards.bump("hit_" + (other as Wildlife.Animal).kind)
				other.hit(-n * vn * (m1 / (m1 + m2)) * 1.6, col.get_position() / PX)
				vw += n * vn * (m2 / (m1 + m2)) * 1.3
			else:
				vw += n * vn * 1.25
			var tang := vw - n * vw.dot(n)
			vw -= tang * (0.18 if not is_car else 0.08)
			sim.set_world_velocity(vw)
			sim.yaw_rate *= 0.55
			sim.w_wheel = sim.vx / float(spec.tires.radius) if absf(sim.vx) > 0.5 else sim.w_wheel
			if vn > 6.0: _diag("CRUNCH: HIT AT %d KM/H" % int(vn * 3.6))
		move_and_collide(col.get_remainder().slide(n))
	sim.pos = position / PX
	for m in sim.messages: _diag(m)
	_update_look(dt, br)

var damage := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
var _scrape_t := 0.0

## Some hits you don't walk away from. What it was decides the death screen.
const FATAL_KMH := { "tree": 70.0, "building": 76.0, "rail": 88.0, "traffic": 84.0, "edge": 76.0, "moose": 55.0, "deer": 150.0 }

func _check_fatal(col: KinematicCollision2D, other: Object, vn: float, d: float, speed: float) -> void:
	if not can_die or dead or sim.assist == CarSim.Assist.ARCADE: return
	var cause := "edge"
	var sub := ""
	if other is TrafficCar or other is PlayerCar:
		cause = "traffic"
		var oh: float = (other as TrafficCar).heading if other is TrafficCar else (other as PlayerCar).sim.heading
		var rel := cos(angle_difference(sim.heading, oh))
		if d > 0.6: sub = "headon" if rel < -0.5 else ("rear" if rel > 0.5 else "tbone")
		else: sub = "tbone"
	elif other is Wildlife.Animal:
		cause = (other as Wildlife.Animal).kind
		vn = maxf(vn, speed * 0.9)          # it doesn't bounce off a moose; it comes through the glass
	elif other is BuildingNode: cause = "building"
	else:
		var owner_node = col.get_collider_shape()
		if owner_node is CollisionShape2D:
			if owner_node.shape is CircleShape2D: cause = "tree"
			elif owner_node.shape is SegmentShape2D: cause = "rail"
	if vn * 3.6 < float(FATAL_KMH[cause]): return
	_die(cause, sub, maxf(vn, speed) * 3.6, other)

func _die(cause: String, sub: String, kmh: float, other: Object) -> void:
	if dead or not can_die or sim.assist == CarSim.Assist.ARCADE: return
	dead = true
	var flat := false
	for tr in sim.tires: flat = flat or tr.flat
	var info := {
		"cause": cause, "sub": sub, "speed_kmh": kmh,
		"car": String(spec.get("id", "")), "body": String(spec.get("body", "sedan")), "paint": paint,
		"length": float(spec.get("length", 4.6)), "impaired": impaired > 0.3, "handbrake": _hb_t < 1.5,
		"reverse": sim.gear < 0, "blink": blink != 0 and not hazards, "flat": flat,
		"hot": sim.coolant_c > 118.0 or sim.head_gasket, "lights": lights_on, "surface": sim.surface,
	}
	if other is TrafficCar or other is PlayerCar:
		var os: Dictionary = other.spec
		var ob := String(os.get("side_body", os.get("body", "sedan")))
		info.other_body = "pickup" if ob == "tow" else ob
		info.other_name = String(os.get("name", ""))
		info.other_paint = other.paint
		info.other_police = other is AiCar and (other as AiCar).lights.a > 0.0
	Controls.rumble(1.0, 1.0, 1.0)
	fatal.emit(info)

## Where the hit landed decides what gets bent. Glancing hits along a wall scrape the paint;
## a hard hit on a bumper can take it right off.
func _take_damage(dir_world: Vector2, vn: float, at: Vector2) -> void:
	if sim.assist == CarSim.Assist.ARCADE: return
	var local := Vector2(dir_world.dot(sim.forward()), dir_world.dot(sim.right()))
	var amt := clampf((vn - 1.5) / 14.0, 0.0, 1.0)
	if vn < 1.5:
		amt = 0.004                          # a scrape: paint, not metal
	var zone := ""
	if absf(local.x) > absf(local.y) * 1.3: zone = "front" if local.x > 0.0 else "rear"
	else: zone = "right" if local.y > 0.0 else "left"
	var before: float = damage[zone]
	damage[zone] = minf(1.0, damage[zone] + amt)
	# the bumper lets go
	if (zone == "front" or zone == "rear") and before < 0.65 and damage[zone] >= 0.65:
		var sgn := 1.0 if zone == "front" else -1.0
		var p := sim.pos + sim.forward() * sgn * float(spec.length) * CarArt.CAR_SCALE * 0.5
		Debris.spawn(get_parent(), p, sim.heading, sim.world_velocity() * 0.6 + sim.forward() * sgn * 2.0, "bumper", paint, float(spec.width) * CarArt.CAR_SCALE)
		_diag("THERE GOES THE %s BUMPER" % ("FRONT" if zone == "front" else "REAR"))
	elif amt > 0.25 and randf() < 0.4:
		Debris.spawn(get_parent(), at, sim.heading, sim.world_velocity() * 0.5, "hubcap" if randf() < 0.3 else "glass", paint)
	if amt >= 0.02: damage_bucket = -2         # redraw the art now

func _say(msg: String, secs := 4.0) -> void:
	if not quiet: hud.post(msg, secs)

## What the car reports goes on the scan tool, not across the windshield.
func _diag(msg: String) -> void:
	if not quiet and hud: hud.diag_event(msg)

func velocity_vec() -> Vector2:
	return sim.world_velocity()

## Another car hit this one: `dv` is the shove it got (m/s, world), `at` where (metres).
func hit(dv: Vector2, at: Vector2) -> void:
	if dead: return
	sim.set_world_velocity(sim.world_velocity() + dv)
	sim.yaw_rate += (at - sim.pos).cross(dv) * 0.35 / maxf(float(spec.length), 1.0)
	var vn := dv.length()
	if vn > 0.5:
		sim.impact(vn, "side")
		_take_damage(-dv / vn, vn * 1.2, at)
	if vn > 6.0: _diag("CRUNCH: HIT AT %d KM/H" % int(vn * 3.6))

func _wheel_world(u: float, v: float) -> Vector2:
	return position + (sim.forward() * u + sim.right() * v) * PX

func _update_look(dt: float, br: float) -> void:
	view.heading = sim.heading
	view.steer = sim.steer
	view.lean = view.lean.lerp(Vector2(clampf(-sim.ax * 0.22, -2.0, 2.0), clampf(-sim.ay * 0.18, -2.0, 2.0)), 0.2)
	view.braking = (br > 0.05 and sim.gear >= 0) or (sim.gear < 0 and throttle_in > 0.05)
	view.reversing = sim.gear < 0
	view.wheel_turn += sim.vx * dt * 3.0
	# dents show up as the body takes damage
	var bucket := int((damage.front + damage.rear + damage.left + damage.right) * 12.0)
	if bucket != damage_bucket:
		damage_bucket = bucket
		view.art = CarArt.new(spec, paint, damage, 3, CarArt.CAR_SCALE)
	# tire marks and smoke
	var half_wb := float(spec.wheelbase) * CarArt.CAR_SCALE / 2.0
	var half_tr := float(spec.track) * CarArt.CAR_SCALE / 2.0
	var snow := sim.surface in ["snow", "ice"]
	var mark_col := Color(0.05, 0.05, 0.06) if not snow else Color(0.45, 0.48, 0.55)
	for side in 2:
		var v := -half_tr if side == 0 else half_tr
		var rear := _wheel_world(-half_wb, v)
		var slip: float = sim.wheel_slip[2 + side]
		var s := clampf((slip - 2.0) / 6.0, 0.0, 1.0)
		skids.mark(skid_base + side, rear, s, mark_col)
		smoke[side].global_position = rear
		smoke[side].emitting = smoke_on and slip > 4.5 and sim.surface != "ice"
		smoke[side].color_ramp.colors[0] = Color(0.88, 0.9, 0.95, 0.6) if snow else Color(0.85, 0.85, 0.88, 0.55)
		var front := _wheel_world(half_wb, v)
		var fs := 0.8 if sim.front_locked else clampf((float(sim.wheel_slip[side]) - 2.5) / 6.0, 0.0, 1.0)
		skids.mark(skid_base + 10 + side, front, fs, mark_col)
	var nose := _wheel_world(float(spec.length) * CarArt.CAR_SCALE * 0.45, 0.0)
	steam.global_position = nose
	steam.emitting = sim.coolant_c > 112.0 or sim.head_gasket
	engine_smoke.global_position = nose
	engine_smoke.emitting = sim.engine_health < 0.45
	# the beam starts at the front bumper and points out ahead; the red glow sits behind the back one
	head_light.rotation = sim.heading
	head_light.position = sim.forward() * float(spec.length) * CarArt.CAR_SCALE * PX * 0.5
	tail_light.position = -sim.forward() * (float(spec.length) * CarArt.CAR_SCALE * PX * 0.5 + 8.0)
	tail_light.visible = lights_on or view.braking
	tail_light.energy = 1.4 if view.braking else 0.6
