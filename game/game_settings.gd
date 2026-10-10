## Everything the settings screen changes, kept in user://settings.cfg (apart from the game save,
## so starting a new game doesn't lose your wheel calibration). Read once at startup by the
## InputWatch autoload; scenes listen for InputWatch.settings_changed to pick up a change live.
## Tests and demos never read the player's file: they run on the defaults.
class_name GameSettings
extends RefCounted

static var path := "user://settings.cfg"
static var data := {}
static var _loaded := false

const DEFAULTS := {
	"controls": { "transmission": "auto", "pad_deadzone": 0.14, "pad_curve": 1.7, "speed_steer": 1.0,
		"trigger_deadzone": 0.06, "kb_ramp": true, "vibration": 1.0, "prompts": "auto" },
	# action -> [[kind, code, value, device], ...] where kind is key, joybtn or joyaxis; absent = defaults
	"bindings": {},
	"wheel": { "enabled": false, "guid": "", "name": "", "ids": "", "pedals_guid": "", "pedals_name": "", "pedals_ids": "",
		"steer_axis": 0, "steer_center": 0.0, "steer_min": -1.0, "steer_max": 1.0, "steer_sign": 1.0,
		"gas_axis": 2, "gas_rest": -1.0, "gas_full": 1.0,
		"brake_axis": 3, "brake_rest": -1.0, "brake_full": 1.0,
		"combined": false, "rotation": 900.0, "range": 0.0, "ratio": 14.0,
		"steer_dz": 0.0, "steer_gamma": 1.0, "pedal_dz": 0.03, "pedal_sat": 0.97 },
	"display": { "mode": "windowed", "size": "1280x720", "vsync": true, "max_fps": 0, "stretch": "integer" },
	"ui": { "messages": "all", "tips": true, "scan_tool": true, "camera_zoom": 1.0, "controls_card": false },
	"difficulty": { "preset": "normal", "assist": "street", "police": "normal", "wildlife": "normal" },
	"graphics": { "lights": 56, "weather": "full", "clouds": true, "smoke": true, "skids": true, "flashes": true, "blur": true, "sight": true },
	"audio": { "master": 1.0, "engine": 1.0, "effects": 1.0, "mute_unfocused": false },
}

## The difficulty presets: what each sets.
const PRESETS := {
	"easy": { "assist": "arcade", "police": "relaxed", "wildlife": "rare" },
	"normal": { "assist": "street", "police": "normal", "wildlife": "normal" },
	"hard": { "assist": "sim", "police": "strict", "wildlife": "many" },
}

## Tests, demos and headless runs use the defaults and never write the player's file.
static func testing() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.ends_with("-test") or a.ends_with("-demo") or a.ends_with("-shot"): return true
	var args := OS.get_cmdline_args()
	return args.has("-s") or args.has("--script")

static func ensure() -> void:
	if not _loaded: load_file()

static func load_file() -> void:
	_loaded = true
	data = DEFAULTS.duplicate(true)
	if testing() and path == "user://settings.cfg": return
	var cf := ConfigFile.new()
	if cf.load(path) != OK: return
	for sec in DEFAULTS:
		if not cf.has_section(sec): continue
		if sec == "bindings":
			for act in cf.get_section_keys(sec):
				var v: Variant = cf.get_value(sec, act, [])
				if v is Array: data.bindings[act] = v
			continue
		for k in DEFAULTS[sec]:
			var def: Variant = DEFAULTS[sec][k]
			var v: Variant = cf.get_value(sec, k, def)
			# a value of the wrong type (an old or hand-edited file) falls back to the default
			if typeof(v) == typeof(def) or (def is float and v is int) or (def is int and v is float): data[sec][k] = v
			else: data[sec][k] = def

static func save_file() -> void:
	if testing() and path == "user://settings.cfg": return
	var cf := ConfigFile.new()
	cf.set_value("meta", "version", 1)
	for sec in data:
		for k in data[sec]: cf.set_value(sec, k, data[sec][k])
	cf.save(path)

static func get_v(sec: String, key: String) -> Variant:
	ensure()
	return (data.get(sec, {}) as Dictionary).get(key, (DEFAULTS.get(sec, {}) as Dictionary).get(key))

static func set_v(sec: String, key: String, value: Variant) -> void:
	ensure()
	if not data.has(sec): data[sec] = {}
	data[sec][key] = value
	# changing one difficulty knob by hand makes it a custom setup
	if sec == "difficulty" and key != "preset": data.difficulty.preset = _match_preset()
	if sec == "difficulty" and key == "preset" and PRESETS.has(String(value)):
		for k in PRESETS[String(value)]: data.difficulty[k] = PRESETS[String(value)][k]

static func _match_preset() -> String:
	for p in PRESETS:
		var same := true
		for k in PRESETS[p]:
			if String(data.difficulty.get(k, "")) != String(PRESETS[p][k]): same = false
		if same: return p
	return "custom"

static func reset(sec: String) -> void:
	ensure()
	data[sec] = (DEFAULTS[sec] as Dictionary).duplicate(true)

# ------------------------------------------------------------------ what the game reads

static func assist() -> int:
	match String(get_v("difficulty", "assist")):
		"arcade": return CarSim.Assist.ARCADE
		"sim": return CarSim.Assist.SIM
	return CarSim.Assist.STREET

## How hard the police come down: scales the speed they let slide and how long they wait.
static func police_strictness() -> float:
	return { "relaxed": 0.6, "normal": 1.0, "strict": 1.5 }.get(String(get_v("difficulty", "police")), 1.0)

static func wildlife_rate() -> float:
	return { "off": 0.0, "rare": 0.4, "normal": 1.0, "many": 2.0 }.get(String(get_v("difficulty", "wildlife")), 1.0)

static func chatter_level() -> int:
	return { "off": 0, "important": 1, "all": 2 }.get(String(get_v("ui", "messages")), 2)

static func weather_amount() -> float:
	return { "off": 0.0, "half": 0.5, "full": 1.0 }.get(String(get_v("graphics", "weather")), 1.0)

static func manual() -> bool:
	return String(get_v("controls", "transmission")) == "manual"

# ------------------------------------------------------------------ applying it

## The window: windowed or full screen, its size, vsync, a frame cap and the pixel scaling.
static func apply_display(tree: SceneTree) -> void:
	if testing() or DisplayServer.get_name() == "headless" or OS.has_feature("mobile"): return
	match String(get_v("display", "mode")):
		"fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"exclusive": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var wh := String(get_v("display", "size")).split("x")
			if wh.size() == 2:
				var size := Vector2i(int(wh[0]), int(wh[1]))
				DisplayServer.window_set_size(size)
				var screen := DisplayServer.screen_get_usable_rect()
				DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_v("display", "vsync")) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(get_v("display", "max_fps"))
	if tree and tree.root:
		tree.root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if String(get_v("display", "stretch")) == "integer" else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

## The sound: Master, plus an Engine bus for the car and an Effects bus for the rest.
static func apply_audio() -> void:
	for nm in ["Engine", "Effects"]:
		if AudioServer.get_bus_index(nm) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nm)
			AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(get_v("audio", "master")), 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Engine"), linear_to_db(maxf(float(get_v("audio", "engine")), 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(maxf(float(get_v("audio", "effects")), 0.0001)))
