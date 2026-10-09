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
var traffic: Traffic
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
var zoom_mult := 1.0
var cam_rot := 0.0
var _season_seen := ""
var _blink_was := false
var dest := { "name": "", "p": Vector2.ZERO }
var save: Dictionary
var garage: GarageScreen
var _save_t := 30.0
const GARAGE_DOOR := Rect2(5546, 1556, 48, 12)     # in front of Covington Auto's bay doors

func _ready() -> void:
	Controls.setup()
	save = SaveGame.read()
	sky = WorldSky.new()
	sky.time_h = 17.5
	sky.set_season("fall")
	world = World.new()
	add_child(world)
	skids = Skids.new()
	skids.z_index = -3993
	add_child(skids)
	ysort = Node2D.new()          # cars and buildings: sorted by depth toward the camera each frame
	add_child(ysort)
	world.setup(sky, ysort)
	lights = LightPool.new()
	add_child(lights)
	lights.setup(world, sky)
	clouds = Clouds.new()
	clouds.sky = sky
	clouds.z_index = 3100
	add_child(clouds)
	# the HUD layer
	var layer := CanvasLayer.new()
	layer.name = "HudLayer"
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
	cam.ignore_rotation = false
	add_child(cam)
	cam.make_current()
	dark = CanvasModulate.new()
	add_child(dark)
	snow_fx = _weather(Color(1, 1, 1, 0.9), Vector2(-8, 28), 260, 1.0)
	rain_fx = _weather(Color(0.7, 0.78, 0.9, 0.55), Vector2(-30, 260), 300, 0.0)
	audio = EngineAudio.new()
	add_child(audio)
	garage = GarageScreen.new()
	garage.size = Vector2(640, 360)
	garage.visible = false
	garage.picked.connect(_on_garage_pick)
	garage.repaired.connect(_on_garage_repair)
	get_node("HudLayer").add_child(garage)
	_spawn_car(int(save.get("current", 0)), START, -PI / 2.0)
	traffic = Traffic.new()
	add_child(traffic)
	traffic.setup(world, sky, ysort, car)
	world.warm(START, Vector2(40, 25))
	hud.post("COLD START. LET IT WARM UP BEFORE YOU WRING IT OUT.", 6.0)
	hud.post("TAB OR D-UP: THE MAP. PICK A PLACE AND THE GPS TAKES YOU THERE.", 8.0)
	if OS.get_cmdline_user_args().has("--traffic-demo"):
		var td: Node = load("res://tests/traffic_demo.gd").new()
		td.main = self
		add_child(td)
	elif OS.get_cmdline_user_args().has("--traffic-test"):
		var tt: Node = load("res://tests/traffic_test.gd").new()
		tt.main = self
		add_child(tt)
	elif OS.get_cmdline_user_args().has("--world-demo"):
		var wd: Node = load("res://tests/world_demo.gd").new()
		wd.main = self
		add_child(wd)
	elif OS.get_cmdline_user_args().has("--demo"):
		var d: Node = load("res://tests/demo.gd").new()
		d.main = self
		add_child(d)

func _spawn_car(i: int, at: Vector2, heading: float) -> void:
	if car: _store_car()
	car_i = i
	var entry: Dictionary = save.garage[i] if i < (save.garage as Array).size() else { "id": CARS[i % CARS.size()], "paint": "", "damage": {} }
	var spec: Dictionary = SaveGame.load_spec(entry.id)
	if String(entry.get("paint", "")) != "": spec.paint = entry.paint
	var old_v := Vector2.ZERO
	if car:
		old_v = car.sim.world_velocity()
		car.queue_free()
	car = PlayerCar.new()
	ysort.add_child(car)
	car.setup(spec, world, skids, hud, at, heading)
	car.sim.set_world_velocity(old_v)
	hud.sim = car.sim
	hud.player = car
	if traffic: traffic.player = car
	dash.sim = car.sim
	dash.style = String(spec.get("dash", "analog90"))
	gps.sim = car.sim
	gps.style = String(spec.get("gps", "tomtum"))
	map_screen.sim = car.sim
	audio.sim = car.sim
	car.sim.assist = CarSim.Assist.STREET
	for k in car.damage: car.damage[k] = float(entry.get("damage", {}).get(k, 0.0))
	car.damage_bucket = -2
	save.current = i
	cam_rot = heading + PI / 2.0
	cam.global_position = car.global_position
	if dest.name != "": gps.set_route(world.map.route(at, dest.p), dest.name)

## Write the car you're driving back into the save (its paint and its dents).
func _store_car() -> void:
	if car == null or car_i >= (save.garage as Array).size(): return
	save.garage[car_i].damage = car.damage.duplicate()
	save.garage[car_i].paint = "#" + car.paint.to_html(false)
	save.garage[car_i].odo_km = float(save.garage[car_i].get("odo_km", 0.0)) + car.sim.odometer_m / 1000.0
	car.sim.odometer_m = 0.0

func _on_garage_pick(i: int) -> void:
	_store_car()
	_spawn_car(i, START, -PI / 2.0)
	_teleport(START, -PI / 2.0)
	SaveGame.write(save)
	var spec: Dictionary = car.spec
	hud.post("%s %s. GUS: \"KEYS ARE IN IT.\"" % [String(spec.make).to_upper(), String(spec.model).to_upper()], 3.0)

func _on_garage_repair(i: int) -> void:
	for k in save.garage[i].damage: save.garage[i].damage[k] = 0.0
	if i == car_i:
		for k in car.damage: car.damage[k] = 0.0
		car.damage_bucket = -2
		car.sim.reset_parts()
	SaveGame.write(save)

func _exit_tree() -> void:
	_store_car()
	SaveGame.write(save)

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
	p.z_index = 3200
	p.emitting = false
	if size == 0.0:
		var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		p.texture = ImageTexture.create_from_image(img)
	cam.add_child(p)
	return p

func _apply_season(s: String, reset := true) -> void:
	if reset: sky.set_season(s)
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
	if garage and garage.visible:
		CarView.screen_up = Vector2(0, -1)      # the garage is drawn straight on
		return
	sky.step(dt)
	if sky.season != _season_seen:
		if _season_seen != "": _apply_season(sky.season, false)
		_season_seen = sky.season
	# the chase cam: behind the car and turning with it, so up on the screen is always ahead.
	# It swings round a little slower than the car, so you can see a slide happen.
	var target := car.sim.heading + PI / 2.0
	if car.sim.vx < -2.0: target = cam_rot      # reversing: don't spin the world around
	cam_rot = lerp_angle(cam_rot, target, 1.0 - exp(-3.2 * dt))
	cam.rotation = cam_rot
	var up := Vector2(0, -1).rotated(cam_rot)
	CarView.screen_up = up
	var spd := car.sim.speed()
	var ahead := up * (70.0 + minf(spd * PX * 0.35, 150.0))
	cam.global_position = car.global_position + ahead
	var z := lerpf(1.0, 0.6, clampf(spd / 55.0, 0.0, 1.0)) * zoom_mult
	cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.5 * dt)
	var r := Vector2(320, 180).length() / cam.zoom.x
	var half_px := Vector2(r, r)
	traffic.step(dt, cam.global_position / PX)
	_save_t -= dt
	if _save_t <= 0.0:
		_save_t = 30.0
		_store_car()
		SaveGame.write(save)
	_depth_sort(up)
	# the blinker relay clicks
	var b_on := CarView.blink_on() and (car.view.blink_left or car.view.blink_right)
	if b_on != _blink_was:
		_blink_was = b_on
		audio.tick = 1.0
	world.update_view(cam.global_position / PX, half_px / PX)
	# light: the sky colour, the lights, headlights, windows
	dark.color = sky.ambient_color()
	var lamps := sky.lights_on(30)
	if lamps != night:
		night = lamps
		world.set_night(night)
	car.lights_on = night or sky.fog > 0.4 or sky.rain > 0.5 or sky.snow > 0.5
	car.tail_light.visible = car.lights_on
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

## Cars and buildings drawn back to front along the camera's view (y-sort, but for a camera
## that turns).
func _depth_sort(up: Vector2) -> void:
	var c := cam.global_position
	for n in ysort.get_children():
		if not (n is Node2D): continue
		var p: Vector2 = n.sort_point() if n.has_method("sort_point") else n.global_position
		n.z_index = 1000 + clampi(int((p - c).dot(-up) / 2.0), -950, 950)

func _teleport(at: Vector2, heading: float) -> void:
	car.sim.vx = 0.0
	car.sim.vy = 0.0
	car.sim.yaw_rate = 0.0
	car.sim.pos = at
	car.sim.heading = heading
	cam_rot = heading + PI / 2.0
	car.position = at * PX
	cam.global_position = car.global_position
	world.warm(at, Vector2(40, 25))

func _inputs() -> void:
	if garage.visible: return
	# the garage: pull up to the bay doors and stop
	if GARAGE_DOOR.has_point(car.sim.pos) and car.sim.speed() < 2.0:
		hud.post("F / Y: THE GARAGE", 0.15)
		if Input.is_action_just_pressed("use"):
			_store_car()
			garage.open(save)
			return
	if Input.is_action_just_pressed("map"):
		if map_screen.visible: map_screen.visible = false
		else: map_screen.open()
	if map_screen.visible: return
	if Input.is_action_just_pressed("gearbox"):
		car.sim.auto_gearbox = not car.sim.auto_gearbox
		hud.post("AUTOMATIC" if car.sim.auto_gearbox else "MANUAL: E/Q OR RB/LB TO SHIFT")
	if Input.is_action_just_pressed("help"): hud.show_help = not hud.show_help
	if Input.is_action_just_pressed("reset"):
		car.respawn()
		world.warm(car.sim.pos, Vector2(40, 25))
	if Input.is_action_just_pressed("menu_back"): get_tree().change_scene_to_file("res://title.tscn")
	audio.horn = Input.is_action_pressed("horn")
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
