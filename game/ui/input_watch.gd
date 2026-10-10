## Autoload: loads the settings and the bindings before any scene, notices whether you last
## touched the keyboard, a controller or the wheel (so prompts follow, and steering reads the pad
## you're using), finds the wheel again when it's plugged in, and tells scenes when a setting
## changes (`settings_changed`).
extends Node

signal settings_changed(section: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.load_file()
	Controls.setup()
	Wheel.resolve()
	GameSettings.apply_audio()
	GameSettings.apply_display(get_tree())
	_prompts()
	Input.joy_connection_changed.connect(_on_joy)

func _on_joy(_device: int, _connected: bool) -> void:
	Wheel.resolve()

func _input(e: InputEvent) -> void:
	# the wheel's pedals rest at an end of their travel: they shouldn't flip the prompts to "pad"
	if (e is InputEventJoypadMotion or e is InputEventJoypadButton) and e.device != Wheel.device:
		if e is InputEventJoypadButton or absf((e as InputEventJoypadMotion).axis_value) > 0.4: Controls.last_pad = e.device
	if String(GameSettings.get_v("controls", "prompts")) == "auto" and not (e.device == Wheel.device and e is InputEventJoypadMotion):
		Hints.saw(e)

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
		"wheel": Wheel.resolve()
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
		_: Hints.pad = not Input.get_connected_joypads().is_empty()
