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
var burn_cloud: CPUParticles2D    # a burnout's (or a donut's) cloud: big, slow, it hangs about
var burn_t := 0.0                 # seconds into the burnout going on now
var burn_last := 0.0              # how long the last one went, once it's over (the HUD reads it, then clears it)
var smoke_on := true           # Settings > Graphics: tire smoke
var smoke_build := 0.0         # 0..1: how long the tires have been going up in smoke (a wisp at first, a fog bank after a few seconds)
var hyd := 0                    # 1ton's hydraulics kit (0 none .. 3 four pumps)
var looks := {}                 # what the body shop, the parts and 1ton did to it (SaveGame.car_looks): the art wears them
var hop := 0.0                  # metres off the ground mid-hop
var _hop_v := 0.0
var head_light: PointLight2D       # the left beam (and the right): a smashed assembly's goes dark
var head_light_r: PointLight2D
var tail_light: PointLight2D       # the red wash behind each tail lamp (white backing up)
var tail_light_r: PointLight2D
var blink_lights: Array[PointLight2D] = []   # amber at the corners: front left, front right, rear left, rear right
var glow_light: PointLight2D       # the underglow kit's light on the road
var _lamps_on := false             # the headlights are lit this frame (the beams follow in _set_lamps)
static var _tail_cone: ImageTexture
static var _spot: GradientTexture2D
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
	view.art = CarArt.new(spec, paint, 0.0, 1, CarArt.CAR_SCALE, looks)
	view.light_bar = has_light_bar()
	add_child(view)
	for i in 4:                    # rear left, rear right, front left, front right
		var p := _particles(Color(0.85, 0.85, 0.88, 0.55), 1.2, 60)
		smoke.append(p)
	var puff := _puff_tex()
	for p in smoke:
		# a jet off the tire that thickens and billows as it slows
		p.texture = puff
		p.direction = Vector2(1, 0)
		p.spread = 28.0
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 1.5
		p.amount = 90
		p.lifetime = 1.8
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.2
		p.initial_velocity_min = 14.0
		p.initial_velocity_max = 34.0
		p.damping_min = 10.0
		p.damping_max = 18.0
		p.scale_amount_curve = _grow_curve()
	burn_cloud = _particles(Color(0.84, 0.84, 0.87, 0.32), 4.0, 80)
	burn_cloud.spread = 180.0
	burn_cloud.initial_velocity_min = 12.0
	burn_cloud.initial_velocity_max = 34.0
	burn_cloud.gravity = Vector2(0, -2)
	burn_cloud.texture = puff
	burn_cloud.scale_amount_min = 1.6
	burn_cloud.scale_amount_max = 3.6
	burn_cloud.damping_min = 5.0
	burn_cloud.damping_max = 9.0
	burn_cloud.scale_amount_curve = _grow_curve()
	steam = _particles(Color(0.95, 0.97, 1.0, 0.5), 1.6, 30)
	engine_smoke = _particles(Color(0.12, 0.12, 0.14, 0.7), 2.0, 40)
	if _cone == null: _cone = _cone_tex()
	if _tail_cone == null: _tail_cone = CarArt.beam_tex(72, 56, 0.8)
	if _spot == null: _spot = World.light_tex(Color.WHITE)
	head_light = _lamp(_cone, Color(1.0, 0.98, 0.92), 1.3)
	head_light_r = _lamp(_cone, Color(1.0, 0.98, 0.92), 1.3)
	tail_light = _lamp(_tail_cone, Color(1, 0.12, 0.08), 0.6)
	tail_light_r = _lamp(_tail_cone, Color(1, 0.12, 0.08), 0.6)
	for i in 4: blink_lights.append(_lamp(_spot, Color(1.0, 0.62, 0.1), 0.5, 0.12))
	glow_light = _lamp(_spot, Color.WHITE, 0.0, 0.5)

## Every tire spinning hard adds to the smoke hanging round the car (SmokeField): the harder and
## longer it spins, the thicker the cloud gets. A burnout's tires are going nowhere, so their smoke
## all lands in one place and piles up; a drift's is spread down the road behind it.
func _feed_smoke(dt: float, half_wb: float, half_tr: float, thrown: float, snow: bool) -> void:
	var field := SmokeField.current
	if field == null or not smoke_on or sim.surface == "ice" or dead: return
	var col := Color(0.9, 0.92, 0.96) if snow else Color(0.86, 0.86, 0.89)
	if sim.surface in ["grass", "mud", "gravel", "dirt"]: col = Color(0.7, 0.62, 0.5)   # dust, not smoke
	var out := Vector2.from_angle(thrown) * 30.0
	for i in 4:
		if i < 2 and sim.front_locked: continue
		var slip: float = sim.wheel_slip[i]
		if slip < 4.5: continue
		var at := _wheel_world(half_wb if i < 2 else -half_wb, (-half_tr if i % 2 == 0 else half_tr))
		field.add(at, clampf((slip - 4.5) / 6.0, 0.2, 1.0) * dt * 3.0 * lerpf(0.15, 1.0, smoke_build), out + sim.world_velocity() * PX * 0.3, col)

## The smoke lives on the parent (so it stays where it was puffed out). Freeing a CPUParticles2D
## that's been emitting crashes the engine (4.5 updates them off the main thread), so the car's
## particle nodes are never freed: they're stopped and kept for the next car on the same parent.
static var _spare: Array[CPUParticles2D] = []

func _exit_tree() -> void:
	for p in smoke + [steam, engine_smoke, burn_cloud]:
		if is_instance_valid(p):
			p.emitting = false
			_spare.append(p)
	smoke.clear()
	steam = null
	engine_smoke = null
	burn_cloud = null

func _particles(col: Color, life: float, amount: int) -> CPUParticles2D:
	var parent := get_parent()
	for i in range(_spare.size() - 1, -1, -1):
		var q: CPUParticles2D = _spare[i]
		if not is_instance_valid(q) or not q.is_inside_tree():
			_spare.remove_at(i)
			continue
		if q.get_parent() == parent:
			_spare.remove_at(i)
			_set_up_particles(q, col, life, amount)
			return q
	var p := CPUParticles2D.new()
	_set_up_particles(p, col, life, amount)
	parent.add_child.call_deferred(p)
	return p

func _set_up_particles(p: CPUParticles2D, col: Color, life: float, amount: int) -> void:
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
	# a reused node: back to a plain puff before the caller dresses it
	p.texture = null
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	p.damping_min = 0.0
	p.damping_max = 0.0
	p.scale_amount_curve = null
	p.restart()

## How many seconds of wheelspin it takes for the smoke to build all the way up.
const SMOKE_BUILD_S := 5.0

static var _puff: ImageTexture

## One puff of smoke: a 6-pixel round blob, solid in the middle and thin at the edge.
static func _puff_tex() -> ImageTexture:
	if _puff: return _puff
	var rows := [".oOOo.", "oOOOOo", "OOOOOO", "OOOOOO", "oOOOOo", ".oOOo."]
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in 6:
			var ch := String(rows[y])[x]
			img.set_pixel(x, y, Color(1, 1, 1, 1.0 if ch == "O" else (0.45 if ch == "o" else 0.0)))
	_puff = ImageTexture.create_from_image(img)
	return _puff

## Smoke that swells as it goes: half size as it leaves the tire, full size as it fades.
static func _grow_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.45))
	c.add_point(Vector2(0.5, 0.85))
	c.add_point(Vector2(1.0, 1.0))
	return c

## The headlight beam: 160 px long from the bumper, out ahead of the car.
static func _cone_tex() -> ImageTexture:
	return CarArt.beam_tex(160, 96)

## A lamp on the car. It lights the road (cull mask 1) and never the car's own body (mask 2).
func _lamp(tex: Texture2D, col: Color, energy: float, scale := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex
	l.color = col
	l.energy = energy
	l.texture_scale = scale
	l.shadow_enabled = false
	l.visible = false
	CarArt.reach_road(l)
	add_child(l)
	return l

## Every lamp where its assembly is, pointed the way it points: a beam out of each headlight, a red
## wash behind each tail (white when backing up, bright on the brakes), the blinkers' amber at the
## corners, the underglow kit's pool under the middle. A smashed assembly gives nothing, and the
## one left carries a little more. `beam` 0..1 is the high beams.
func _set_lamps(on: bool, beam: float, tails_on: bool, braking: bool) -> void:
	var fwd := sim.forward()
	var rt := sim.right()
	var hl := float(spec.length) * CarArt.CAR_SCALE * PX * 0.5
	var hw := float(spec.width) * CarArt.CAR_SCALE * PX * 0.3
	var ok_h: Array = view.art.head_ok if view.art != null else [true, true]
	var ok_t: Array = view.art.tail_ok if view.art != null else [true, true]
	var scale := lerpf(1.4, 2.4, beam)
	var e := lerpf(1.25, 1.75, beam)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var l := head_light if i == 0 else head_light_r
		var alone: bool = not ok_h[1 - i]
		l.visible = on and ok_h[i]
		l.rotation = sim.heading
		l.position = fwd * hl + rt * side * hw
		l.texture_scale = scale * (0.86 if alone else 0.78)
		l.energy = e * (0.95 if alone else 0.72)
		l.offset = Vector2(80.0 * l.texture_scale, 0)
		var t := tail_light if i == 0 else tail_light_r
		var alone_t: bool = not ok_t[1 - i]
		t.visible = (tails_on or braking or view.reversing) and ok_t[i]
		t.rotation = sim.heading + PI
		t.position = -fwd * hl + rt * side * hw
		t.texture_scale = 0.9 if braking else 0.6
		t.offset = Vector2(36.0 * t.texture_scale, 0)
		t.color = Color(0.95, 0.95, 0.9) if view.reversing else Color(1, 0.12, 0.08)
		t.energy = (0.9 if view.reversing else (1.3 if braking else 0.55)) * (1.15 if alone_t else 1.0)
	var bl := view.blink_left and CarView.blink_on()
	var br := view.blink_right and CarView.blink_on()
	for i in 4:
		var l := blink_lights[i]
		var side := -1.0 if i % 2 == 0 else 1.0
		l.visible = bl if side < 0.0 else br
		l.position = fwd * (hl if i < 2 else -hl) + rt * side * hw * 1.3
		l.energy = 0.2 + 0.5 * CarView.night
	var ug: Color = view.art.underglow if view.art != null else Color(0, 0, 0, 0)
	glow_light.visible = ug.a > 0.0 and CarView.night > 0.05
	if glow_light.visible:
		glow_light.color = Color(ug.r, ug.g, ug.b)
		glow_light.texture_scale = float(spec.length) * CarArt.CAR_SCALE * PX / 128.0 * 1.35
		# it breathes
		glow_light.energy = (0.2 + 0.55 * CarView.night) * (0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004))

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
var beacons := false              # the wrecker's light bar (the hydraulics button, on a car with no hydraulics)
var _blink_steer := 0.0
var locked := false               # a menu is up: hands off, ease to a stop
var show_mode := false            # parked at the meet: out of gear, handbrake on, the gas just revs it
var _in_show := false
var _karma_hit: Object = null    # the last car Leo put his into (one bump, one count)
var on_traffic_hit: Callable           # the driver's car: a hard hit on traffic gets called in (Incidents)
var show_off := false             # doing a donut or a handbrake slide on purpose: the aids step back

## The driver's inputs, plus the help a modern car gives you on STREET (traction control and
## a little stability control). SIM gives you none; ARCADE gives you more.
func _inputs(dt: float) -> Array:
	var ins := Controls.drive_inputs(dt, float(spec.get("steer_lock", 0.55)))
	var th: float = ins[0]
	var br: float = ins[1]
	var st: float = ins[2]
	var hb: float = ins[3]
	# the clutch is yours in pedal mode with a manual gearbox (a wheel's third pedal, or the key)
	sim.manual_clutch = String(GameSettings.get_v("controls", "clutch")) == "pedal" and not sim.auto_gearbox
	sim.clutch_in = clampf(float(ins[4]), 0.0, 1.0) if ins.size() > 4 and sim.manual_clutch else 0.0
	# a wheel turns the road wheels one for one: no help that would move them without the rim
	var wheel := Wheel.active()
	sim.direct_steer = wheel
	if impaired > 0.0:
		# drunk: the wheel answers late, the car drifts, and you overcorrect
		_drunk_t += dt
		_st_lag += (st - _st_lag) * (1.0 - exp(-dt / (0.06 + 0.45 * impaired)))
		st = _st_lag * (1.0 + 0.35 * impaired) + sin(_drunk_t * 0.9) * 0.16 * impaired + sin(_drunk_t * 2.3 + 1.0) * 0.06 * impaired
		th = clampf(th * (1.0 + 0.4 * impaired * sin(_drunk_t * 1.7)), 0.0, 1.0)
	var aided := PlayerCar.aids(sim, th, st, hb, _hb_t, wheel, float(GameSettings.get_v("controls", "speed_steer")))
	th = aided[0]
	st = aided[1]
	show_off = aided[2]
	sim.esc_off = show_off
	return [th, br, st, hb]

## The driving aids (STREET and ARCADE): traction control, steering into a slide for you, and
## less lock at speed. Takes the gas, the steering and the handbrake as the player gave them, and
## gives back [gas, steering, showing off]. Showing off is a donut at a crawl or a slide off the
## handbrake: the aids step back for that, the way you'd switch traction control off.
## `speed_steer` is Settings > Controls > SPEED STEERING (how much less lock at speed).
static func aids(sim: CarSim, th: float, st: float, hb: float, hb_t: float, wheel: bool, speed_steer: float) -> Array:
	if sim.assist == CarSim.Assist.SIM: return [th, st, false]
	var v := sim.speed()
	var street := sim.assist == CarSim.Assist.STREET
	# (showing off: hard lock and gas at a crawl, or the handbrake pulled this last moment; the aids
	# used to stay off for two seconds after any pull, and that read as the truck stuck sliding)
	var show_off := street and ((absf(st) > 0.85 and th > 0.6 and v < 9.0) or hb > 0.5 or hb_t < 0.6)
	# traction control: back off the gas while the driven tires spin up
	var spin := sim.drive_slip()
	var tc_limit := 2.0 if street else 1.5
	if spin > tc_limit and v > 1.5 and hb < 0.1 and not show_off:
		th *= clampf(1.0 - (spin - tc_limit) * 0.35, 0.1 if street else 0.0, 1.0)
	# and off the gas while the back's stepping out (stability control cuts the power too)
	var slide := absf(atan2(sim.vy, maxf(absf(sim.vx), 1.0)))
	if slide > 0.15 and v > 4.0 and hb < 0.1 and not show_off:
		th *= clampf(1.0 - (slide - 0.15) * (2.5 if street else 4.0), 0.1, 1.0)
	if not wheel:
		# a wheel turns the road wheels one for one: no help that would move them without the rim.
		# Stability: steer into a slide for you, and don't let the stick over-rotate at speed
		var beta := atan2(sim.vy, maxf(absf(sim.vx), 1.0))
		var help := 0.75 if street else 0.9
		if v > 4.0 and absf(beta) > 0.08 and hb < 0.1 and not show_off:
			st = clampf(st + beta * help * 1.6, -1.0, 1.0)
		var at_speed := lerpf(1.0, 0.5 if street else 0.45, clampf(speed_steer, 0.0, 1.5))
		st *= lerpf(1.0, at_speed, clampf(v / 35.0, 0.0, 1.0))
	return [th, st, show_off]

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
	_lamps_on = on
	view.headlights = on
	# an LED roof bar comes on with the brights (flashing them too)
	view.high_beams = on and beam > 0.5
	# blinkers: they cancel themselves when you straighten out after a turn
	if hands and Input.is_action_just_pressed("blink_left"): blink = 0 if blink == -1 else -1
	if hands and Input.is_action_just_pressed("blink_right"): blink = 0 if blink == 1 else 1
	if hands and Input.is_action_just_pressed("hazards"): hazards = not hazards
	if hands and view.light_bar and hyd == 0 and Input.is_action_just_pressed("hydraulics"): set_beacons(not beacons)
	view.beacons = beacons
	if blink != 0:
		if signf(st) == float(blink) and absf(st) > 0.5: _blink_steer = 1.0
		elif _blink_steer > 0.0 and absf(st) < 0.15:
			blink = 0
			_blink_steer = 0.0
	view.blink_left = hazards or blink == -1
	view.blink_right = hazards or blink == 1

## A wrecker has an amber light bar on the cab.
func has_light_bar() -> bool:
	return String(spec.get("body", "")) == "tow" or String(spec.get("id", "")) == "tow"

## The light bar on or off (says so, unless it's somebody else's car).
func set_beacons(on: bool) -> void:
	if beacons == on or not has_light_bar(): return
	beacons = on
	if not quiet and hud: hud.notify("LIGHT BAR ON." if on else "LIGHT BAR OFF. JUST A TRUCK NOW.", "status", 1, 2.0)

## Tests: every solid thing (not a car) the car ran into, as [pos, what, where, speed, who].
static var log_hits := false
static var hit_log: Array = []

## What a collider is, by its scripts up the tree: "StaticBody2D<Chunk<World" is a tree trunk
## or a bridge rail, "StaticBody2D<RoadFurniture" a pole, "BuildingNode<Chunk" a building.
static func hit_name(o) -> String:
	if o == null: return "nothing"
	var chain := ""
	var n = o
	while n is Node and chain.length() < 90:
		var sc = n.get_script()
		var nm: String = sc.get_global_name() if sc != null and sc.get_global_name() != "" else n.get_class()
		chain += ("<" if chain != "" else "") + nm
		if nm in ["World", "Drive", "RoadFurniture", "BuildingNode", "ParkedCar", "Yards"]: break
		n = n.get_parent()
	return chain

func _physics_process(dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_physics_process_timed(dt)
	Prof.lap('player_phys', _t0)

func _physics_process_timed(dt: float) -> void:
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
		if log_hits:
			var what := hit_name(other)
			if other is TrafficCar: what = "TrafficCar %s v%.1f" % [(other as TrafficCar).state, (other as TrafficCar).v]
			hit_log.append([sim.pos, what, col.get_position() / PX, vw.length(), name])
		if is_car: vn = -(vw - other.velocity_vec()).dot(n)
		if vn > 0.0:
			var hit_dir := -n
			var d := hit_dir.dot(sim.forward())
			var where := "front" if d > 0.6 else ("rear" if d < -0.6 else "side")
			_check_fatal(col, other, vn, d, vw.length())
			if other is AiCar and (other as AiCar).lights.a > 0.0 and vn > 3.0: hit_police += 1
			elif other is TrafficCar and vn > 4.0 and not quiet and other != _karma_hit:
				_karma_hit = other
				Karma.deed("crash_traffic")
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
				if other is TrafficCar and on_traffic_hit.is_valid(): on_traffic_hit.call(other, vn * (m1 / (m1 + m2)) * 1.6)
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
	_unwedge(dt, th, br, col != null)
	for m in sim.messages: _diag(m)
	_update_look(dt, br)

var damage := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
var _scrape_t := 0.0
var _free_pos := Vector2.INF      # the last place it was moving freely (m)
var _free_heading := 0.0
var _wedged_t := 0.0

## Jammed against something (a tree and a kerb, the corner of a building) with the gas or the
## brake down and going nowhere for a few seconds: it comes loose, back where it last moved freely.
## (The player's car; the AI has its own way out.)
func _unwedge(dt: float, th: float, br: float, touching: bool) -> void:
	if quiet: return
	var v := sim.speed()
	if not touching and v > 0.8:
		_free_pos = sim.pos
		_free_heading = sim.heading
	var pushing := th > 0.3 or br > 0.3
	var recent := Engine.get_physics_frames() - hit_frame < 20
	_wedged_t = _wedged_t + dt if pushing and v < 0.3 and recent else 0.0
	if _wedged_t > 3.0 and _free_pos != Vector2.INF and _free_pos.distance_to(sim.pos) < 20.0:
		_wedged_t = 0.0
		sim.vx = 0.0
		sim.vy = 0.0
		sim.yaw_rate = 0.0
		sim.w_wheel = 0.0
		sim.pos = _free_pos
		sim.heading = _free_heading
		position = _free_pos * PX
		shape_node.rotation = sim.heading
		_diag("YOU WIGGLE IT LOOSE.")

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
		info.other_id = String(os.get("id", ""))
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
	# hydraulics: the button dumps the pumps and up it goes (slow, or stopped: it's a show, not a jump)
	if hyd > 0:
		var r := OneTon.hop_step(hop, _hop_v, dt, Input.is_action_pressed("hydraulics") and not locked and not quiet and sim.speed() < 6.0, hyd)
		hop = float(r[0])
		_hop_v = float(r[1])
	view.lift = hop * PX              # (a donk stands up on its own big wheels: the art draws that)
	view.braking = (br > 0.05 and sim.gear >= 0) or (sim.gear < 0 and throttle_in > 0.05)
	view.reversing = sim.gear < 0
	view.wheel_turn += sim.vx * dt * 3.0
	# dents show up as the body takes damage
	var bucket := int((damage.front + damage.rear + damage.left + damage.right) * 12.0)
	if bucket != damage_bucket:
		damage_bucket = bucket
		view.build(spec, paint, damage, 3, CarArt.CAR_SCALE, looks)
	# tire marks and smoke
	var half_wb := float(spec.wheelbase) * CarArt.CAR_SCALE / 2.0
	var half_tr := float(spec.track) * CarArt.CAR_SCALE / 2.0
	var snow := sim.surface in ["snow", "ice"]
	var mark_col := Color(0.05, 0.05, 0.06) if not snow else Color(0.45, 0.48, 0.55)
	# the smoke comes off the spinning tire itself, in its wheel well: it's thrown out the back of
	# the tire (out the front, spinning backwards) and a little to the outside, and it's drawn under
	# the body, so the car hides what's still under it and it billows out from the fenders
	var tire_w := 0.12 * CarArt.CAR_SCALE
	var smoke_z := z_index - 1
	var thrown := sim.heading + (0.0 if sim.gear < 0 else PI)
	# the smoke builds: the first second of wheelspin is a wisp off the tires, and it takes a good
	# few seconds of it before the jets are billowing; it dies back quicker than it builds
	var spinning := sim.surface != "ice" and (float(sim.wheel_slip[2]) > 4.5 or float(sim.wheel_slip[3]) > 4.5 \
		or not sim.front_locked and (float(sim.wheel_slip[0]) > 4.5 or float(sim.wheel_slip[1]) > 4.5))
	smoke_build = clampf(smoke_build + (dt / SMOKE_BUILD_S if spinning else -dt / 1.5), 0.0, 1.0)
	var thick := lerpf(0.1, 1.0, smoke_build * smoke_build)
	for side in 2:
		var v := -half_tr if side == 0 else half_tr
		var out_v := v + (-tire_w if side == 0 else tire_w)
		var outward := (0.4 if side == 0 else -0.4) * (-1.0 if sim.gear < 0 else 1.0)
		var back := -0.3 if sim.gear >= 0 else 0.3
		var rear := _wheel_world(-half_wb, v)
		var slip: float = sim.wheel_slip[2 + side]
		var s := clampf((slip - 2.0) / 6.0, 0.0, 1.0)
		skids.mark(skid_base + side, rear, s, mark_col)
		smoke[side].global_position = _wheel_world(-half_wb + back, out_v)
		smoke[side].global_rotation = thrown + outward
		smoke[side].emitting = smoke_on and slip > 4.5 and sim.surface != "ice"
		smoke[side].color_ramp.colors[0] = Color(0.88, 0.9, 0.95, 0.6 * thick) if snow else Color(0.85, 0.85, 0.88, 0.55 * thick)
		smoke[side].initial_velocity_max = lerpf(18.0, 34.0, smoke_build)
		var front := _wheel_world(half_wb, v)
		var fs := 0.8 if sim.front_locked else clampf((float(sim.wheel_slip[side]) - 2.5) / 6.0, 0.0, 1.0)
		skids.mark(skid_base + 10 + side, front, fs, mark_col)
		# rolling over soft ground: every tire leaves its track (deeper when it's spinning)
		var rt: Array = Skids.rut(sim.surface, city.sky.snow_cover if city and city.sky else 0.0)
		var rolling := sim.speed() > 0.6
		for fr in 2:
			var wp := front if fr == 0 else rear
			var rs := 0.0 if rt.is_empty() or not rolling else float(rt[1]) * (1.0 + 0.4 * clampf(float(sim.wheel_slip[2 * (1 - fr) + side]) / 8.0, 0.0, 1.0))
			skids.mark(skid_base + 20 + fr * 2 + side, wp, rs, rt[0] if not rt.is_empty() else mark_col, float(rt[2]) * CarArt.CAR_SCALE if not rt.is_empty() else 3.0, 6.0)
		# a front-driver's burnout (the reverse-to-drive slam) smokes the fronts
		smoke[2 + side].global_position = _wheel_world(half_wb + back, out_v)
		smoke[2 + side].global_rotation = thrown + outward
		smoke[2 + side].emitting = smoke_on and float(sim.wheel_slip[side]) > 4.5 and not sim.front_locked and sim.surface != "ice"
		smoke[2 + side].color_ramp.colors[0] = smoke[side].color_ramp.colors[0]
		smoke[2 + side].initial_velocity_max = smoke[side].initial_velocity_max
	for p in smoke + [burn_cloud]:
		p.set_meta("no_sort", true)
		p.z_index = smoke_z
		p.gravity = CarView.screen_up * 7.0           # it rises: up the screen, whichever way the camera's turned
	# a burnout or a donut: the driven tires spinning hard and the car going nowhere fast. The
	# smoke piles up round the car and the HUD counts it
	var rear_slip := maxf(float(sim.wheel_slip[2]), float(sim.wheel_slip[3]))
	var front_slip := 0.0 if sim.front_locked else maxf(float(sim.wheel_slip[0]), float(sim.wheel_slip[1]))
	var burning := maxf(rear_slip, front_slip) > 7.0 and sim.speed() < 10.0 and sim.surface != "ice" and not dead
	if burning: burn_t += dt
	elif burn_t > 0.0:
		burn_last = burn_t
		burn_t = 0.0
	burn_cloud.global_position = _wheel_world(-half_wb if rear_slip >= front_slip else half_wb, 0.0)
	burn_cloud.emitting = smoke_on and burning and burn_t > 1.5
	burn_cloud.color_ramp.colors[0] = Color(0.84, 0.84, 0.87, 0.32 * clampf((burn_t - 1.5) / 4.0, 0.15, 1.0))
	_feed_smoke(dt, half_wb, half_tr, thrown, snow)
	var nose := _wheel_world(float(spec.length) * CarArt.CAR_SCALE * 0.45, 0.0)
	steam.global_position = nose
	steam.emitting = sim.coolant_c > 112.0 or sim.head_gasket
	engine_smoke.global_position = nose
	engine_smoke.emitting = sim.engine_health < 0.45
	_set_lamps(_lamps_on, beam, lights_on, view.braking)
