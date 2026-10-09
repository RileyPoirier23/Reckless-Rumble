## Every input action in the game, for keyboard and controller. Safe to call more than once.
##
## Driving (controller): RT gas, LT brake, left stick steer, B handbrake, RB/LB shift (manual),
## Y use (garage, doors), X horn, D-pad left/right blinkers, D-pad down hazards, D-pad up high
## beams (tap to switch, hold to flash). Back: map. Start: help.
## Time, weather, season and car are not controls: the world runs on its own, and you change
## cars in the garage.
class_name Controls
extends RefCounted

static func setup() -> void:
	var map := {
		"throttle": [KEY_W, KEY_UP, [JOY_AXIS_TRIGGER_RIGHT, 1.0]],
		"brake": [KEY_S, KEY_DOWN, [JOY_AXIS_TRIGGER_LEFT, 1.0]],
		"steer_left": [KEY_A, KEY_LEFT, [JOY_AXIS_LEFT_X, -1.0]],
		"steer_right": [KEY_D, KEY_RIGHT, [JOY_AXIS_LEFT_X, 1.0]],
		"handbrake": [KEY_SPACE, JOY_BUTTON_B],
		"shift_up": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
		"shift_down": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
		"gearbox": [KEY_G],
		"use": [KEY_F, KEY_ENTER, JOY_BUTTON_Y],
		"horn": [KEY_H, JOY_BUTTON_X],
		"blink_left": [KEY_Z, JOY_BUTTON_DPAD_LEFT],
		"blink_right": [KEY_C, JOY_BUTTON_DPAD_RIGHT],
		"hazards": [KEY_V, JOY_BUTTON_DPAD_DOWN],
		"high_beams": [KEY_B, JOY_BUTTON_DPAD_UP],
		"reset": [KEY_R],
		"map": [KEY_TAB, KEY_M, JOY_BUTTON_BACK],
		"jobs": [KEY_J, JOY_BUTTON_RIGHT_STICK],
		"help": [KEY_F1, JOY_BUTTON_START],
		"inspect": [KEY_I, JOY_BUTTON_Y],
		"click": [JOY_BUTTON_A],
		"menu_back": [KEY_ESCAPE],
		"ui_back_pad": [JOY_BUTTON_BACK],
	}
	# Godot's built-in menu actions don't listen to a controller: A confirms, B backs out
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var has := false
		for e in InputMap.action_get_events(pair[0]):
			if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == pair[1]: has = true
		if not has:
			var jb := InputEventJoypadButton.new()
			jb.button_index = pair[1]
			InputMap.action_add_event(pair[0], jb)
	for action in map:
		if InputMap.has_action(action): continue
		InputMap.add_action(action, 0.1)
		for b in map[action]:
			var ev: InputEvent
			if b is Array:
				var j := InputEventJoypadMotion.new()
				j.axis = b[0]
				j.axis_value = b[1]
				ev = j
			elif b < 32:     # joypad buttons are 0..20; every key code is 32 or more
				var jb := InputEventJoypadButton.new()
				jb.button_index = b
				ev = jb
			else:
				var k := InputEventKey.new()
				k.physical_keycode = b
				ev = k
			InputMap.action_add_event(action, ev)

## The left stick, read raw with a proper round dead zone and a response curve: small
## movements make small corrections, full lock is still at the end of the travel.
static func steer_axis() -> float:
	var kb := Input.get_axis("steer_left", "steer_right")
	var pads := Input.get_connected_joypads()
	if pads.is_empty(): return kb
	var x := Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_Y)
	var mag := Vector2(x, y).length()
	var stick := 0.0
	if mag > 0.14 and absf(x) > 0.06:
		var t := clampf((absf(x) - 0.06) / 0.9, 0.0, 1.0)
		stick = signf(x) * pow(t, 1.7)
	# keyboard keys are digital; the stick wins if it's being used
	return stick if absf(stick) > 0.0 else kb

## Triggers with a small dead zone at the bottom (worn triggers rest above zero).
static func trigger(action: String) -> float:
	var v := Input.get_action_strength(action)
	return clampf((v - 0.06) / 0.94, 0.0, 1.0)
