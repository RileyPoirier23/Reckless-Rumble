## The lot, and everything past it: free drive from Port Rumble out to Salisbury and Havelock.
## The clock runs, the weather turns, the lights come on, and the GPS knows the way.
extends Node2D

const PX := CarArt.PX
const CARS := ["silvio", "supreem", "charjer", "tow"]
const START := Vector2(5570, 1566)          # Covington Auto's lot, nose at the bay doors

var world: World
var sky: WorldSky
var skids: Skids
var ysort: Node2D
var car: PlayerCar
var cam: Camera2D
var dark: CanvasModulate
var lights: LightPool
var hud: Hud
var dash: DashView
var gps: GpsView
var map_screen: MapScreen
var audio: EngineAudio
var snow_fx: CPUParticles2D
var rain_fx: CPUParticles2D
var fog_rect: ColorRect
var flash_rect: ColorRect
var clouds: Node2D
var car_i := 0
var _light_t := 0.0
var _water_t := 0.0
var night := false
var dest := { "name": "", "p": Vector2.ZERO }

func _ready() -> void:
	Controls.setup()
	sky = WorldSky.new()
	sky.time_h = 17.5
	sky.set_season("fall")
	world = World.new()
	add_child(world)
	skids = Skids.new()
	skids.z_index = -23
	add_child(skids)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	world.setup(sky, ysort)
	lights = LightPool.new()
	add_child(lights)
	lights.setup(world, sky)
	clouds = Clouds.new()
	clouds.sky = sky
	clouds.z_index = 6
	add_child(clouds)
	# the HUD layer
	var layer := CanvasLayer.new()
	add_child(layer)
	fog_rect = ColorRect.new()
	fog_rect.size = Vector2(640, 360)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.color = Color(1, 1, 1, 0)
	layer.add_child(fog_rect)
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(640, 360)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	layer.add_child(flash_rect)
	hud = Hud.new()
	hud.size = Vector2(640, 360)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.sky = sky
	layer.add_child(hud)
	dash = DashView.new()
	dash.size = Vector2(640, 360)
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dash)
	gps = GpsView.new()
	gps.size = Vector2(640, 360)
	gps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gps.world = world
	gps.map = world.map
	gps.sky = sky
	layer.add_child(gps)
	map_screen = MapScreen.new()
	map_screen.size = Vector2(640, 360)
	map_screen.map = world.map
	map_screen.world = world
	map_screen.visible = false
	map_screen.chosen.connect(_on_dest)
	layer.add_child(map_screen)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.make_current()
	dark = CanvasModulate.new()
	add_child(dark)
	snow_fx = _weather(Color(1, 1, 1, 0.9), Vector2(-8, 28), 260, 1.0)
	rain_fx = _weather(Color(0.7, 0.78, 0.9, 0.55), Vector2(-30, 260), 300, 0.0)
	audio = EngineAudio.new()
	add_child(audio)
	_spawn_car(0, START, -PI / 2.0)
	world.warm(START, Vector2(40, 25))
	hud.post("COLD START. LET IT WARM UP BEFORE YOU WRING IT OUT.", 6.0)
	hud.post("TAB OR D-UP: THE MAP. PICK A PLACE AND THE GPS TAKES YOU THERE.", 8.0)
	if OS.get_cmdline_user_args().has("--world-demo"):
		var wd: Node = load("res://tests/world_demo.gd").new()
		wd.main = self
		add_child(wd)
	elif OS.get_cmdline_user_args().has("--demo"):
		var d: Node = load("res://tests/demo.gd").new()
		d.main = self
		add_child(d)

func _spawn_car(i: int, at: Vector2, heading: float) -> void:
	car_i = i
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/%s.json" % CARS[i]))
	var old_v := Vector2.ZERO
	if car:
		old_v = car.sim.world_velocity()
		car.queue_free()
	car = PlayerCar.new()
	ysort.add_child(car)
	car.setup(spec, world, skids, hud, at, heading)
	car.sim.set_world_velocity(old_v)
	hud.sim = car.sim
	dash.sim = car.sim
	dash.style = String(spec.get("dash", "analog90"))
	gps.sim = car.sim
	gps.style = String(spec.get("gps", "tomtum"))
	map_screen.sim = car.sim
	audio.sim = car.sim
	cam.global_position = car.global_position
	if dest.name != "": gps.set_route(world.map.route(at, dest.p), dest.name)

func _on_dest(name: String, at: Vector2) -> void:
	dest = { "name": name, "p": at }
	gps.set_route(world.map.route(car.sim.pos, at), name)
	hud.post("GPS: %s" % name, 3.0)

func _weather(col: Color, vel: Vector2, amount: int, size: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 2.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(620, 360)
	p.direction = vel.normalized()
	p.spread = 6.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel.length() * 0.8
	p.initial_velocity_max = vel.length() * 1.2
	p.color = col
	p.scale_amount_min = 1.0 + size
	p.scale_amount_max = 1.5 + size
	p.z_index = 10
	p.emitting = false
	if size == 0.0:
		var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		p.texture = ImageTexture.create_from_image(img)
	cam.add_child(p)
	return p

func _apply_season(s: String) -> void:
	sky.set_season(s)
	car.sim.set_ambient(sky.temperature())
	skids.clear()
	var tips := {
		"summer": "SUMMER. GRIP EVERYWHERE. THUNDERSTORMS ROLL IN AFTER HOT DAYS.",
		"fall": "FALL. WET LEAVES ARE ICE WITH A NICER COLOUR. FOG ON THE RIVER.",
		"winter": "WINTER. SNOW, BLIZZARDS, FREEZING RAIN. SUMMER TIRES ARE HOCKEY PUCKS: T.",
		"spring": "SPRING. RAIN, MUD AND POTHOLES. FREEZING RAIN ON COLD NIGHTS.",
	}
	hud.post(tips[s], 5.0)

func _process(dt: float) -> void:
	sky.step(dt)
	# the camera: look ahead of the car, pull back with speed
	var v := car.sim.world_velocity() * PX
	var ahead := v * 0.32
	if ahead.length() > 190.0: ahead = ahead.normalized() * 190.0
	cam.global_position = car.global_position + ahead
	var z := lerpf(1.0, 0.55, clampf(car.sim.speed() / 55.0, 0.0, 1.0))
	cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.5 * dt)
	var half_px := Vector2(320, 180) / cam.zoom
	world.update_view(cam.global_position / PX, half_px / PX)
	# light: the sky colour, the lights, headlights, windows
	dark.color = sky.ambient_color()
	var lamps := sky.lights_on(30)
	if lamps != night:
		night = lamps
		world.set_night(night)
		car.head_light.visible = night
		car.tail_light.visible = night
		car.view.headlights = night
	_light_t -= dt
	if _light_t <= 0.0:
		_light_t = 0.12
		lights.refresh(cam.global_position, half_px)
	lights.animate(dt)
	dash.lit = night
	# the weather you can see
	var wind := sky.wind_dir * sky.wind
	rain_fx.emitting = sky.rain > 0.08
	snow_fx.emitting = sky.snow > 0.08
	rain_fx.modulate.a = clampf(sky.rain * 1.3, 0.2, 1.0)
	snow_fx.modulate.a = clampf(sky.snow * 1.3, 0.25, 1.0)
	rain_fx.direction = (Vector2(wind.x * 6.0, 260)).normalized()
	snow_fx.direction = (Vector2(wind.x * 3.0, 28 + absf(wind.y))).normalized()
	snow_fx.initial_velocity_min = 24.0 + sky.wind * 4.0
	snow_fx.initial_velocity_max = 34.0 + sky.wind * 6.0
	var fogc := Color(0.75, 0.77, 0.8) if sky.daylight() > 0.4 else Color(0.18, 0.2, 0.26)
	if sky.snow > 0.5: fogc = Color(0.9, 0.92, 0.96) if sky.daylight() > 0.4 else Color(0.3, 0.32, 0.4)
	fog_rect.color = Color(fogc.r, fogc.g, fogc.b, sky.fog * 0.55)
	flash_rect.color = Color(1, 1, 1, sky.flash * 0.55)
	if sky.thunder_in >= 0.0 and sky.thunder_in < dt:
		hud.post("*THUNDER*", 1.5)
		Input.start_joy_vibration(0, 0.4, 0.8, 0.6)
	# the car's world
	car.sim.set_ambient(sky.temperature())
	hud.surface = car.sim.surface
	hud.place = world.map.zone_at(car.sim.pos).label if world.map.zone_at(car.sim.pos).label != "" else "COUNTRY"
	audio.throttle = car.throttle_in
	# into the river
	if car.sim.surface == "water":
		_water_t += dt
		if _water_t > 1.2:
			_water_t = 0.0
			hud.post("YOU DROVE INTO THE CHOCOLATE RIVER. TOBY TOWS YOU OUT. AGAIN.", 5.0)
			var rd := world.map.nearest_road(car.sim.pos, 400.0)
			if not rd.is_empty(): _teleport(rd.point, rd.dir.angle())
	else:
		_water_t = 0.0
	# Magnet Hill: on the hill road, the car rolls "uphill" (it's an optical illusion; so is this)
	if car.sim.pos.distance_to(Vector2(5080, 800)) < 60.0 and car.throttle_in < 0.05 and car.sim.speed() < 6.0:
		car.sim.set_world_velocity(car.sim.world_velocity() + Vector2(-0.6, -0.5).normalized() * 0.9 * dt)
	_inputs()

func _teleport(at: Vector2, heading: float) -> void:
	car.sim.vx = 0.0
	car.sim.vy = 0.0
	car.sim.yaw_rate = 0.0
	car.sim.pos = at
	car.sim.heading = heading
	car.position = at * PX
	cam.global_position = car.global_position
	world.warm(at, Vector2(40, 25))

func _inputs() -> void:
	if Input.is_action_just_pressed("map"):
		if map_screen.visible: map_screen.visible = false
		else: map_screen.open()
	if map_screen.visible: return
	if Input.is_action_just_pressed("night"):
		sky.time_h = fmod(sky.time_h + 3.0, 24.0)
		hud.post("THREE HOURS LATER. %s" % sky.clock_str(), 2.5)
	if Input.is_action_just_pressed("season"):
		var i := ["summer", "fall", "winter", "spring"].find(sky.season)
		_apply_season(["summer", "fall", "winter", "spring"][(i + 1) % 4])
	if Input.is_action_just_pressed("weather"):
		sky.next_weather()
		hud.post("WEATHER: %s" % sky.label(), 2.5)
	if Input.is_action_just_pressed("tires"):
		car.sim.compound = "winter" if car.sim.compound == "summer" else "summer"
		hud.post("%s TIRES ON" % car.sim.compound.to_upper())
	if Input.is_action_just_pressed("assist"):
		car.sim.assist = (car.sim.assist + 1) % 3
		hud.post(["SIM: NOTHING SAVES YOU", "STREET: ABS, NO MONEY SHIFTS", "ARCADE: NOTHING BREAKS"][car.sim.assist])
	if Input.is_action_just_pressed("gearbox"):
		car.sim.auto_gearbox = not car.sim.auto_gearbox
		hud.post("AUTOMATIC" if car.sim.auto_gearbox else "MANUAL: E/Q OR RB/LB TO SHIFT")
	if Input.is_action_just_pressed("next_car"):
		_spawn_car((car_i + 1) % CARS.size(), car.sim.pos, car.sim.heading)
		hud.post("%s %s" % [car.spec.make, car.spec.model], 3.0)
	if Input.is_action_just_pressed("help"): hud.show_help = not hud.show_help
	if Input.is_action_just_pressed("reset"):
		car.respawn()
		world.warm(car.sim.pos, Vector2(40, 25))
	if Input.is_action_just_pressed("menu_back"): get_tree().change_scene_to_file("res://title.tscn")
	if not car.sim.auto_gearbox:
		if Input.is_action_just_pressed("shift_up"): car.sim.shift(car.sim.gear + 1)
		if Input.is_action_just_pressed("shift_down"): car.sim.shift(car.sim.gear - 1)
		for m in car.sim.messages: hud.post(m)


## Cloud shadows drifting over everything on a cloudy day.
class Clouds extends Node2D:
	var sky: WorldSky
	var tex: GradientTexture2D
	var off := Vector2.ZERO
	func _ready() -> void:
		tex = World.light_tex(Color(0, 0, 0))
	func _process(dt: float) -> void:
		off += sky.wind_dir * (2.0 + sky.wind) * dt * CarArt.PX
		queue_redraw()
	func _draw() -> void:
		var a := sky.cloud * 0.22 * sky.daylight() * (1.0 - sky.rain * 0.6)
		if a < 0.01: return
		var cam := get_viewport().get_camera_2d()
		if cam == null: return
		var c := cam.global_position
		var cell := 900.0
		var base := ((c - off) / cell).floor()
		for y in range(-2, 3):
			for x in range(-2, 3):
				var k := base + Vector2(x, y)
				var h := int(absf(k.x * 7919.0 + k.y * 104729.0)) % 1000
				var p := k * cell + off + Vector2(h % 300, (h * 7) % 300)
				var s := 500.0 + float(h % 400)
				draw_texture_rect(tex, Rect2(p - Vector2(s, s * 0.6), Vector2(s * 2.0, s * 1.2)), false, Color(1, 1, 1, a))
