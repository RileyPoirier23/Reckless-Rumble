## Every input action in the game, for keyboard, controller and wheel. Safe to call more than once:
## setup() rebuilds every action from the defaults below plus whatever you've rebound in Settings.
##
## Driving (controller): RT gas, LT brake, left stick steer, B handbrake, RB/LB shift (manual), L3
## auto/manual, Y use (garage, doors), X horn, D-pad left/right blinkers, D-pad down hazards, D-pad
## up high beams (tap to switch, hold to flash). View: map. Menu: pause.
## A steering wheel is set up and calibrated in Settings > Wheel (see Wheel).
class_name Controls
extends RefCounted

## The defaults: key codes, pad buttons (under 32), and pad axes as [axis, direction].
const DEFAULTS := {
	"throttle": [KEY_W, KEY_UP, [JOY_AXIS_TRIGGER_RIGHT, 1.0]],
	"brake": [KEY_S, KEY_DOWN, [JOY_AXIS_TRIGGER_LEFT, 1.0]],
	"steer_left": [KEY_A, KEY_LEFT, [JOY_AXIS_LEFT_X, -1.0]],
	"steer_right": [KEY_D, KEY_RIGHT, [JOY_AXIS_LEFT_X, 1.0]],
	"handbrake": [KEY_SPACE, JOY_BUTTON_B],
	"shift_up": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
	"shift_down": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
	"gearbox": [KEY_G, JOY_BUTTON_LEFT_STICK],
	"use": [KEY_F, KEY_ENTER, JOY_BUTTON_Y],
	"horn": [KEY_H, JOY_BUTTON_X],
	"blink_left": [KEY_Z, JOY_BUTTON_DPAD_LEFT],
	"blink_right": [KEY_C, JOY_BUTTON_DPAD_RIGHT],
	"hazards": [KEY_V, JOY_BUTTON_DPAD_DOWN],
	"high_beams": [KEY_B, JOY_BUTTON_DPAD_UP],
	"reset": [KEY_R],
	"hydraulics": [KEY_X, JOY_BUTTON_A],
	"map": [KEY_TAB, KEY_M, JOY_BUTTON_BACK],
	"jobs": [KEY_J, JOY_BUTTON_RIGHT_STICK],
	"help": [KEY_F1],
	"pause": [KEY_ESCAPE, JOY_BUTTON_START],
	"inspect": [KEY_I, JOY_BUTTON_Y],
	"click": [JOY_BUTTON_A],
	"menu_back": [KEY_ESCAPE],
	"ui_back_pad": [JOY_BUTTON_BACK],
	"ui_tab_prev": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
	"ui_tab_next": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
	# an H-shifter: bound to the wheel's buttons in Settings, nothing by default
	"gear_1": [], "gear_2": [], "gear_3": [], "gear_4": [], "gear_5": [], "gear_6": [], "gear_r": [],
}

## What the settings screen lets you rebind, in order, and what it calls them.
const REBIND := [
	["throttle", "GAS"], ["brake", "BRAKE / REVERSE"], ["steer_left", "STEER LEFT"], ["steer_right", "STEER RIGHT"],
	["handbrake", "HANDBRAKE"], ["shift_up", "SHIFT UP"], ["shift_down", "SHIFT DOWN"], ["gearbox", "AUTO / MANUAL"],
	["use", "USE"], ["horn", "HORN"], ["blink_left", "LEFT BLINKER"], ["blink_right", "RIGHT BLINKER"], ["hazards", "HAZARDS"],
	["high_beams", "HIGH BEAMS"], ["map", "MAP"], ["jobs", "GIGS"], ["reset", "TOW HOME"], ["hydraulics", "HYDRAULICS"], ["help", "CONTROLS CARD"], ["pause", "PAUSE"],
]
const GEARS := [["gear_1", "1ST"], ["gear_2", "2ND"], ["gear_3", "3RD"], ["gear_4", "4TH"], ["gear_5", "5TH"], ["gear_6", "6TH"], ["gear_r", "REVERSE"]]

## The pad that was touched last (steering reads that one, so a second pad or a wheel works).
static var last_pad := 0
static var _kb := [0.0, 0.0, 0.0]          # the eased keyboard gas, brake and steer

static func setup() -> void:
	GameSettings.ensure()
	# Godot's built-in menu actions don't listen to a controller: A confirms, B backs out
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var has := false
		for e in InputMap.action_get_events(pair[0]):
			if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == pair[1]: has = true
		if not has:
			var jb := InputEventJoypadButton.new()
			jb.button_index = pair[1]
			jb.device = -1
			InputMap.action_add_event(pair[0], jb)
	apply_bindings()

## Build every action from its saved binding (or the default).
static func apply_bindings() -> void:
	var over: Dictionary = GameSettings.data.get("bindings", {})
	for action in DEFAULTS:
		# triggers get their dead zone in trigger(); the stick's steering actions keep a small one
		var dz := 0.0 if action in ["throttle", "brake"] else (0.2 if action.begins_with("steer") else 0.5)
		if not InputMap.has_action(action): InputMap.add_action(action, dz)
		else: InputMap.action_set_deadzone(action, dz)
		InputMap.action_erase_events(action)
		for en in entries(action, over):
			var ev := event_from(en)
			if ev: InputMap.action_add_event(action, ev)

## An action's bindings: [[kind, code, value, device], ...].
static func entries(action: String, over := {}) -> Array:
	if over.has(action): return over[action]
	var out: Array = []
	for b in DEFAULTS.get(action, []):
		if b is Array: out.append(["joyaxis", int(b[0]), float(b[1]), -1])
		elif int(b) < 32: out.append(["joybtn", int(b), 0.0, -1])     # pad buttons are 0..20; key codes are 32 and up
		else: out.append(["key", int(b), 0.0, -1])
	return out

static func event_from(en: Array) -> InputEvent:
	var dev := int(en[3]) if en.size() > 3 else -1
	match String(en[0]):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(en[1]) as Key
			return k
		"joybtn":
			var jb := InputEventJoypadButton.new()
			jb.button_index = int(en[1]) as JoyButton
			jb.device = dev
			return jb
		"joyaxis":
			var j := InputEventJoypadMotion.new()
			j.axis = int(en[1]) as JoyAxis
			j.axis_value = float(en[2])
			j.device = dev
			return j
	return null

## The binding entry for an event someone just pressed (for rebinding), or [] if it can't bind.
static func entry_of(e: InputEvent, wheel_device := -1) -> Array:
	if e is InputEventKey and e.pressed and not e.echo:
		var k := e as InputEventKey
		return ["key", int(k.physical_keycode if k.physical_keycode != 0 else k.keycode), 0.0, -1]
	if e is InputEventJoypadButton and e.pressed:
		var jb := e as InputEventJoypadButton
		return ["joybtn", int(jb.button_index), 0.0, jb.device if jb.device == wheel_device and wheel_device >= 0 else -1]
	if e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.6:
		var j := e as InputEventJoypadMotion
		return ["joyaxis", int(j.axis), signf(j.axis_value), j.device if j.device == wheel_device and wheel_device >= 0 else -1]
	return []

## Rebind one column of an action: the keyboard ("key") or the controller/wheel ("pad").
static func bind(action: String, column: String, en: Array) -> void:
	var cur := entries(action, GameSettings.data.bindings)
	var keep: Array = cur.filter(func(x): return (String(x[0]) == "key") != (column == "key"))
	if not en.is_empty(): keep.append(en)
	GameSettings.data.bindings[action] = keep
	apply_bindings()

static func reset_bindings() -> void:
	GameSettings.data.bindings = {}
	apply_bindings()

## What a binding is called on the settings screen.
static func label(en: Array) -> String:
	if en.is_empty(): return "-"
	match String(en[0]):
		"key":
			var nm := OS.get_keycode_string(int(en[1]) as Key).to_upper()
			return String(Hints.KEY_NAMES.get(nm, nm))
		"joybtn":
			var b := int(en[1])
			if int(en[3]) >= 0 or b > JOY_BUTTON_DPAD_RIGHT: return "BTN %d" % b
			return String(Hints.XBOX.get(b, "BTN %d" % b))
		"joyaxis":
			var a := int(en[1])
			var dir := "+" if float(en[2]) > 0.0 else "-"
			match a:
				JOY_AXIS_TRIGGER_RIGHT: return "RT"
				JOY_AXIS_TRIGGER_LEFT: return "LT"
				JOY_AXIS_LEFT_X: return "L-STICK " + ("RIGHT" if dir == "+" else "LEFT")
				JOY_AXIS_LEFT_Y: return "L-STICK " + ("DOWN" if dir == "+" else "UP")
			return "AXIS %d%s" % [a, dir]
	return "?"

## Gas, brake, steering and handbrake for the car this frame: from the wheel if one's set up,
## otherwise from the pad or the keyboard. On the keyboard the pedals and the steering ease in
## (keys are all or nothing), and back out quicker.
static func drive_inputs(dt: float, steer_lock := 0.55) -> Array:
	if Wheel.active(): return Wheel.inputs(steer_lock)
	var th := trigger("throttle")
	var br := trigger("brake")
	var st := steer_axis()
	var hb := Input.get_action_strength("handbrake")
	if not Hints.pad and bool(GameSettings.get_v("controls", "kb_ramp")):
		_kb[0] = move_toward(float(_kb[0]), th, dt * (4.0 if th > float(_kb[0]) else 8.0))
		_kb[1] = move_toward(float(_kb[1]), br, dt * (6.0 if br > float(_kb[1]) else 12.0))
		var s0 := float(_kb[2])
		var turning_in := absf(st) > absf(s0) and (signf(st) == signf(s0) or is_zero_approx(s0))
		_kb[2] = move_toward(s0, st, dt * (3.5 if turning_in else 7.0))
		return [_kb[0], _kb[1], _kb[2], hb]
	_kb = [th, br, st]
	return [th, br, st, hb]

## The stick, read raw with a proper round dead zone and a response curve (both in Settings):
## small movements make small corrections, full lock is still at the end of the travel.
static func steer_axis() -> float:
	var kb := Input.get_axis("steer_left", "steer_right")
	var pads := Input.get_connected_joypads()
	if pads.is_empty(): return kb
	var dev: int = last_pad if pads.has(last_pad) else pads[0]
	if Wheel.device == dev and Wheel.device >= 0: dev = pads[0] if pads[0] != Wheel.device or pads.size() == 1 else pads[1]
	var x := Input.get_joy_axis(dev, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y)
	var dz := float(GameSettings.get_v("controls", "pad_deadzone"))
	var curve := float(GameSettings.get_v("controls", "pad_curve"))
	var stick := 0.0
	if Vector2(x, y).length() > dz and absf(x) > 0.06:
		var t := clampf((absf(x) - 0.06) / 0.9, 0.0, 1.0)
		stick = signf(x) * pow(t, curve)
	# keyboard keys are digital; the stick wins if it's being used
	return stick if absf(stick) > 0.0 else kb

## Triggers with a small dead zone at the bottom (worn triggers rest above zero).
static func trigger(action: String) -> float:
	var v := Input.get_action_strength(action)
	var dz := float(GameSettings.get_v("controls", "trigger_deadzone"))
	return clampf((v - dz) / maxf(1.0 - dz, 0.01), 0.0, 1.0)

## Rumble on the controller you're using, scaled by the setting.
static func rumble(weak: float, strong: float, secs: float) -> void:
	var k := float(GameSettings.get_v("controls", "vibration"))
	if k <= 0.0: return
	var pads := Input.get_connected_joypads()
	if pads.is_empty(): return
	var dev: int = last_pad if pads.has(last_pad) else pads[0]
	Input.start_joy_vibration(dev, clampf(weak * k, 0.0, 1.0), clampf(strong * k, 0.0, 1.0), secs)
