## Autoload: loads the settings and the bindings before any scene, notices whether you last
## touched the keyboard or a controller (so prompts follow, and steering reads the pad you're
## using), finds a wheel when it's plugged in (and keeps it out of the menus: a wheel only
## drives), puts up the game's own mouse pointer, and tells scenes when a setting changes
## (`settings_changed`).
extends Node

signal settings_changed(section: String)
signal wheel_found(name: String)       # a wheel was plugged in that's never been set up

var _mouse_t := 0.0                    # seconds since the mouse last moved

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.load_file()
	Wheel.resolve()
	Controls.setup()
	GameSettings.apply_audio()
	GameSettings.apply_display(get_tree())
	_prompts()
	Input.joy_connection_changed.connect(_on_joy)
	Cursor.apply(get_window())
	get_tree().root.size_changed.connect(func(): Cursor.apply(get_window()))

func _on_joy(_device: int, _connected: bool) -> void:
	var had := Wheel.device
	Wheel.resolve()
	Controls.apply_bindings()
	_prompts()
	if Wheel.needs_setup() and Wheel.device != had: wheel_found.emit(Input.get_joy_name(Wheel.device))

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadMotion or e is InputEventJoypadButton:
		# the wheel only drives: its rim, pedals and buttons never move the prompts or pick "the pad"
		if Wheel.is_wheel(e.device): return
		if e is InputEventJoypadButton or absf((e as InputEventJoypadMotion).axis_value) > 0.4: Controls.last_pad = e.device
	if e is InputEventMouseMotion:
		_mouse_t = 0.0
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if String(GameSettings.get_v("controls", "prompts")) == "auto":
		Hints.saw(e)

## On the road the pointer gets out of the way when the mouse sits still; it's back the moment
## the mouse moves (and always in a menu).
func _process(dt: float) -> void:
	_mouse_t += dt
	var scene := get_tree().current_scene
	var driving := scene != null and scene.scene_file_path == "res://drive.tscn" and not get_tree().paused
	if driving and _mouse_t > 2.5:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif not driving and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _notification(what: int) -> void:
	if not bool(GameSettings.get_v("audio", "mute_unfocused")): return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: AudioServer.set_bus_mute(0, false)

## A setting changed: apply what applies everywhere, then tell the scenes.
func changed(section: String) -> void:
	match section:
		"display": GameSettings.apply_display(get_tree())
		"audio": GameSettings.apply_audio()
		"bindings": Controls.apply_bindings()
		"wheel":
			Wheel.resolve()
			Controls.apply_bindings()
			_prompts()
		"controls": _prompts()
	GameSettings.save_file()
	settings_changed.emit(section)

## Prompts can be pinned to the keyboard or a controller in Settings > UI.
func _prompts() -> void:
	match String(GameSettings.get_v("controls", "prompts")):
		"keyboard": Hints.pad = false
		"xbox":
			Hints.pad = true
			Hints.playstation = false
		"playstation":
			Hints.pad = true
			Hints.playstation = true
		_: Hints.pad = not Wheel.pads().is_empty()
