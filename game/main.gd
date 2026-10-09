## DriveBoss driving prototype: one car, two blocks of Port Rumble, four seasons, day and night.
extends Node2D

const PX := CarArt.PX

var city: City
var skids: Skids
var ysort: Node2D
var car: PlayerCar
var cam: Camera2D
var dark: CanvasModulate
var hud: Hud
var audio: EngineAudio
var snow_fx: CPUParticles2D
var rain_fx: CPUParticles2D
var night := false

func _ready() -> void:
	_input_map()
	city = City.new()
	add_child(city)
	skids = Skids.new()
	add_child(skids)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	city.build(ysort)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.size = Vector2(640, 360)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	car = PlayerCar.new()
	ysort.add_child(car)
	car.setup(spec, city, skids, hud, Vector2(240, 150), -PI / 2.0)    # in the Covington Auto lot, nose north
	hud.sim = car.sim
	hud.city = city
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.make_current()
	cam.global_position = car.global_position
	dark = CanvasModulate.new()
	add_child(dark)
	snow_fx = _weather(Color(1, 1, 1, 0.9), Vector2(-8, 28), 220, 1.0)
	rain_fx = _weather(Color(0.7, 0.78, 0.9, 0.55), Vector2(-30, 260), 260, 0.0)
	audio = EngineAudio.new()
	audio.sim = car.sim
	add_child(audio)
	_apply_season("summer")
	_set_night(false)
	hud.post("COLD START. LET IT WARM UP BEFORE YOU WRING IT OUT.", 6.0)
	if OS.get_cmdline_user_args().has("--demo"):
		var d: Node = load("res://tests/demo.gd").new()
		d.main = self
		add_child(d)

func _weather(col: Color, vel: Vector2, amount: int, size: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 2.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(560, 320)
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
		# rain is streaks
		var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		p.texture = ImageTexture.create_from_image(img)
	cam.add_child(p) if cam else add_child(p)
	return p

func _input_map() -> void:
	var map := {
		"throttle": [KEY_W, KEY_UP, [JOY_AXIS_TRIGGER_RIGHT, 1.0]],
		"brake": [KEY_S, KEY_DOWN, [JOY_AXIS_TRIGGER_LEFT, 1.0]],
		"steer_left": [KEY_A, KEY_LEFT, [JOY_AXIS_LEFT_X, -1.0]],
		"steer_right": [KEY_D, KEY_RIGHT, [JOY_AXIS_LEFT_X, 1.0]],
		"handbrake": [KEY_SPACE, JOY_BUTTON_B],
		"shift_up": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_A],
		"shift_down": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_X],
		"gearbox": [KEY_G, JOY_BUTTON_Y],
		"reset": [KEY_R, JOY_BUTTON_BACK],
		"night": [KEY_N, JOY_BUTTON_DPAD_UP],
		"season": [KEY_M, JOY_BUTTON_DPAD_RIGHT],
		"tires": [KEY_T, JOY_BUTTON_DPAD_DOWN],
		"assist": [KEY_P, JOY_BUTTON_DPAD_LEFT],
		"help": [KEY_F1, JOY_BUTTON_START],
	}
	for action in map:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.12)
		for b in map[action]:
			var ev: InputEvent
			if b is Array:
				var j := InputEventJoypadMotion.new()
				j.axis = b[0]
				j.axis_value = b[1]
				ev = j
			elif action in ["handbrake", "shift_up", "shift_down", "gearbox", "reset", "night", "season", "tires", "assist", "help"] and b < 100:
				var jb := InputEventJoypadButton.new()
				jb.button_index = b
				ev = jb
			else:
				var k := InputEventKey.new()
				k.physical_keycode = b
				ev = k
			InputMap.action_add_event(action, ev)

func _apply_season(s: String) -> void:
	city.set_season(s)
	car.sim.set_ambient(city.ambient())
	snow_fx.emitting = s == "winter"
	rain_fx.emitting = s == "fall" or s == "spring"
	skids.clear()
	# winter means winter tires (if you're smart)
	var tips := {
		"summer": "SUMMER. GRIP EVERYWHERE. THE ENGINE RUNS HOT IN TRAFFIC.",
		"fall": "FALL. WET LEAVES ARE ICE WITH A NICER COLOUR.",
		"winter": "WINTER. -12°C. SUMMER TIRES ARE HOCKEY PUCKS. T FOR WINTER TIRES.",
		"spring": "SPRING. RAIN AND POTHOLES. MUD SEASON.",
	}
	hud.post(tips[s], 5.0)

func _set_night(on: bool) -> void:
	night = on
	hud.night = on
	dark.color = Color(0.2, 0.22, 0.36) if on else Color(1, 1, 1)
	city.set_night(on)
	car.head_light.visible = on
	car.tail_light.visible = on
	car.view.headlights = on

func _process(dt: float) -> void:
	# camera: look ahead of the car, pull back with speed
	var v := car.sim.world_velocity() * PX
	var ahead := v * 0.32
	if ahead.length() > 190.0: ahead = ahead.normalized() * 190.0
	cam.global_position = car.global_position + ahead
	var z := lerpf(1.0, 0.55, clampf(car.sim.speed() / 55.0, 0.0, 1.0))
	cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.5 * dt)
	hud.surface = car.sim.surface
	audio.throttle = car.throttle_in
	# toggles
	if Input.is_action_just_pressed("night"): _set_night(not night)
	if Input.is_action_just_pressed("season"):
		var i := City.ORDER.find(city.season)
		_apply_season(City.ORDER[(i + 1) % City.ORDER.size()])
	if Input.is_action_just_pressed("tires"):
		car.sim.compound = "winter" if car.sim.compound == "summer" else "summer"
		hud.post("%s TIRES ON" % car.sim.compound.to_upper())
	if Input.is_action_just_pressed("assist"):
		car.sim.assist = (car.sim.assist + 1) % 3
		hud.post(["SIM: NOTHING SAVES YOU", "STREET: ABS, NO MONEY SHIFTS", "ARCADE: NOTHING BREAKS"][car.sim.assist])
	if Input.is_action_just_pressed("gearbox"):
		car.sim.auto_gearbox = not car.sim.auto_gearbox
		hud.post("AUTOMATIC" if car.sim.auto_gearbox else "MANUAL: E/Q OR RB/LB TO SHIFT")
	if Input.is_action_just_pressed("help"): hud.show_help = not hud.show_help
	if Input.is_action_just_pressed("reset"): car.respawn()
	if not car.sim.auto_gearbox:
		if Input.is_action_just_pressed("shift_up"): car.sim.shift(car.sim.gear + 1)
		if Input.is_action_just_pressed("shift_down"): car.sim.shift(car.sim.gear - 1)
		for m in car.sim.messages: hud.post(m)
