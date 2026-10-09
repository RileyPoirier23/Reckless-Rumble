## Every input action in the game, for keyboard and controller. Safe to call more than once.
class_name Controls
extends RefCounted

static func setup() -> void:
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
		"inspect": [KEY_I, JOY_BUTTON_Y],
		"click": [JOY_BUTTON_A],
		"menu_back": [KEY_ESCAPE],
		"ui_back_pad": [JOY_BUTTON_BACK],
	}
	for action in map:
		if InputMap.has_action(action): continue
		InputMap.add_action(action, 0.12)
		for b in map[action]:
			var ev: InputEvent
			if b is Array:
				var j := InputEventJoypadMotion.new()
				j.axis = b[0]
				j.axis_value = b[1]
				ev = j
			elif action in ["handbrake", "shift_up", "shift_down", "gearbox", "reset", "night", "season", "tires", "assist", "help", "inspect", "click", "ui_back_pad"] and b < 100:
				var jb := InputEventJoypadButton.new()
				jb.button_index = b
				ev = jb
			else:
				var k := InputEventKey.new()
				k.physical_keycode = b
				ev = k
			InputMap.action_add_event(action, ev)

