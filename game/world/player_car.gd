## The car you drive: input -> CarSim -> collisions with the city -> what you see and hear.
class_name PlayerCar
extends CharacterBody2D

const PX := CarArt.PX

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
var head_light: PointLight2D
var tail_light: PointLight2D
var damage_bucket := 0
var throttle_in := 0.0
var start_pos := Vector2.ZERO
var start_heading := 0.0

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
	safe_margin = 0.5
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(spec.length), float(spec.width)) * PX * Vector2(0.96, 0.9)
	shape_node.shape = shape
	add_child(shape_node)
	view = CarView.new()
	view.art = CarArt.new(spec, paint, 0.0)
	add_child(view)
	for i in 2:
		var p := _particles(Color(0.85, 0.85, 0.88, 0.55), 1.2, 60)
		smoke.append(p)
	steam = _particles(Color(0.95, 0.97, 1.0, 0.5), 1.6, 30)
	engine_smoke = _particles(Color(0.12, 0.12, 0.14, 0.7), 2.0, 40)
	head_light = PointLight2D.new()
	head_light.texture = _cone_tex()
	head_light.energy = 1.3
	head_light.color = Color(1.0, 0.96, 0.85)
	head_light.offset = Vector2(64, 0)
	add_child(head_light)
	tail_light = PointLight2D.new()
	tail_light.texture = city._light_tex(Color(1, 0.2, 0.15))
	tail_light.texture_scale = 0.35
	tail_light.energy = 0.8
	tail_light.color = Color(1, 0.25, 0.2)
	add_child(tail_light)

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
	p.z_index = 2
	get_parent().add_child.call_deferred(p)
	return p

func _cone_tex() -> ImageTexture:
	var img := Image.create(160, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		for x in 160:
			var dx := float(x) / 160.0
			var dy := absf(float(y) - 48.0) / 48.0
			var spread := 0.18 + dx * 0.82
			var a := clampf(1.0 - dy / spread, 0.0, 1.0) * clampf(1.0 - dx, 0.0, 1.0) * clampf(dx * 6.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

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
	hud.post("TOWED HOME AND FIXED UP. DON'T TELL GUS.")

func _physics_process(dt: float) -> void:
	var th := Input.get_action_strength("throttle")
	var br := Input.get_action_strength("brake")
	var st := Input.get_axis("steer_left", "steer_right")
	if absf(st) < 0.08: st = 0.0
	var hb := Input.get_action_strength("handbrake")
	throttle_in = th
	sim.surface = city.surface_at(sim.pos)
	var before := sim.pos
	sim.step(dt, th, br, st, hb)
	var motion := (sim.pos - before) * PX
	position = before * PX
	shape_node.rotation = sim.heading
	var col := move_and_collide(motion)
	if col:
		var n := col.get_normal()
		var vw := sim.world_velocity()
		var vn := -vw.dot(n)
		if vn > 0.0:
			var hit_dir := -n
			var d := hit_dir.dot(sim.forward())
			var where := "front" if d > 0.6 else ("rear" if d < -0.6 else "side")
			sim.impact(vn, where)
			vw += n * vn * 1.25
			var tang := vw - n * vw.dot(n)
			vw -= tang * 0.18
			sim.set_world_velocity(vw)
			sim.yaw_rate *= 0.55
			sim.w_wheel = sim.vx / float(spec.tires.radius) if absf(sim.vx) > 0.5 else sim.w_wheel
			if vn > 6.0: hud.post("CRUNCH (%d KM/H)" % int(vn * 3.6), 2.0)
		move_and_collide(col.get_remainder().slide(n))
	sim.pos = position / PX
	for m in sim.messages: hud.post(m)
	_update_look(dt, br)

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
	var bucket := int((1.0 - sim.body) * 10.0)
	if bucket != damage_bucket:
		damage_bucket = bucket
		view.art = CarArt.new(spec, paint, (1.0 - sim.body) * 0.9, 3)
	# tire marks and smoke
	var half_wb := float(spec.wheelbase) / 2.0
	var half_tr := float(spec.track) / 2.0
	var snow := sim.surface in ["snow", "ice"]
	var mark_col := Color(0.05, 0.05, 0.06) if not snow else Color(0.45, 0.48, 0.55)
	for side in 2:
		var v := -half_tr if side == 0 else half_tr
		var rear := _wheel_world(-half_wb, v)
		var slip: float = sim.wheel_slip[2 + side]
		var s := clampf((slip - 2.0) / 6.0, 0.0, 1.0)
		skids.mark(10 + side, rear, s, mark_col)
		smoke[side].global_position = rear
		smoke[side].emitting = slip > 4.5 and sim.surface != "ice"
		smoke[side].color_ramp.colors[0] = Color(0.88, 0.9, 0.95, 0.6) if snow else Color(0.85, 0.85, 0.88, 0.55)
		var front := _wheel_world(half_wb, v)
		var fs := 0.8 if sim.front_locked else clampf((float(sim.wheel_slip[side]) - 2.5) / 6.0, 0.0, 1.0)
		skids.mark(20 + side, front, fs, mark_col)
	var nose := _wheel_world(float(spec.length) * 0.45, 0.0)
	steam.global_position = nose
	steam.emitting = sim.coolant_c > 112.0 or sim.head_gasket
	engine_smoke.global_position = nose
	engine_smoke.emitting = sim.engine_health < 0.45
	head_light.rotation = sim.heading
	head_light.position = sim.forward() * float(spec.length) * PX * 0.4
	tail_light.position = -sim.forward() * float(spec.length) * PX * 0.5
	tail_light.energy = 1.4 if view.braking else 0.5
