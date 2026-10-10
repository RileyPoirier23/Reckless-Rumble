## Button prompts that follow whatever you're holding. Touch a key and every prompt in the game
## says ENTER / ESC / SPACE; touch the controller and they say A / B / RT (or CROSS / CIRCLE / R2
## on a PlayStation pad). `Hints.fmt("{ui_accept} NEXT  {menu_back} MENU")` fills in the names.
class_name Hints
extends RefCounted

static var pad := false
static var playstation := false

const XBOX := { JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_BACK: "VIEW", JOY_BUTTON_START: "MENU",
	JOY_BUTTON_DPAD_UP: "D-PAD UP", JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN", JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT", JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3" }
const PS := { JOY_BUTTON_A: "CROSS", JOY_BUTTON_B: "CIRCLE", JOY_BUTTON_X: "SQUARE", JOY_BUTTON_Y: "TRIANGLE",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_BACK: "SHARE", JOY_BUTTON_START: "OPTIONS",
	JOY_BUTTON_DPAD_UP: "D-PAD UP", JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN", JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT", JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3" }
## Pad-only stand-ins for actions that are keyboard-only (or the other way round).
const PAD_ALIAS := { "menu_back": "ui_back_pad", "reset": "" }
const KEY_NAMES := { "ESCAPE": "ESC", "BACKSPACE": "BKSP", "UP": "UP", "DOWN": "DOWN", "LEFT": "LEFT", "RIGHT": "RIGHT",
	"KP ENTER": "ENTER", "SPACE": "SPACE" }
## Labels for pairs that read better as one word.
const PAIRS := {
	"steer": ["A/D", "L-STICK"], "drive": ["W/S", "RT/LT"], "updown": ["UP/DOWN", "D-PAD"], "leftright": ["LEFT/RIGHT", "D-PAD"],
	"shift": ["E/Q", "RB/LB"], "blinkers": ["Z/C", "D-PAD L/R"],
}
## The two actions behind each pair: once either is rebound in Settings, the label is built from them.
const PAIR_ACTIONS := { "steer": ["steer_left", "steer_right"], "drive": ["throttle", "brake"],
	"shift": ["shift_up", "shift_down"], "blinkers": ["blink_left", "blink_right"] }

## Called by the InputWatch autoload on every input event.
static func saw(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.4):
		if not pad:
			pad = true
			var nm := Input.get_joy_name(e.device).to_lower()
			playstation = nm.contains("ps") or nm.contains("dualsense") or nm.contains("dualshock") or nm.contains("sony") or nm.contains("playstation")
	elif e is InputEventKey or e is InputEventMouseButton:
		pad = false

## The name of the button for an action, for whatever's in your hands right now.
static func key(action: String) -> String:
	if PAIR_ACTIONS.has(action) and _rebound(PAIR_ACTIONS[action]):
		var a := key(String(PAIR_ACTIONS[action][0]))
		var b := key(String(PAIR_ACTIONS[action][1]))
		if a == "" and b == "": return ""
		return a + "/" + b
	if PAIRS.has(action):
		var pr: Array = PAIRS[action]
		var s: String = pr[1] if pad else pr[0]
		if pad and playstation: s = s.replace("RT/LT", "R2/L2").replace("RB/LB", "R1/L1")
		return s
	var act := action
	if pad and PAD_ALIAS.has(action):
		act = String(PAD_ALIAS[action])
		if act == "": return ""
	if not InputMap.has_action(act): return act.to_upper()
	for e in InputMap.action_get_events(act):
		if pad:
			if e is InputEventJoypadButton:
				var names: Dictionary = PS if playstation else XBOX
				return String(names.get((e as InputEventJoypadButton).button_index, "?"))
			if e is InputEventJoypadMotion:
				var m := e as InputEventJoypadMotion
				match m.axis:
					JOY_AXIS_TRIGGER_RIGHT: return "R2" if playstation else "RT"
					JOY_AXIS_TRIGGER_LEFT: return "L2" if playstation else "LT"
					JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return "L-STICK"
					_: return "R-STICK"
		else:
			if e is InputEventKey:
				var k := e as InputEventKey
				var code := k.physical_keycode if k.physical_keycode != 0 else k.keycode
				var nm := OS.get_keycode_string(code).to_upper()
				return String(KEY_NAMES.get(nm, nm))
			if e is InputEventMouseButton: return "CLICK"
	if action == "click" and not pad: return "CLICK"
	return ""

static func _rebound(acts: Array) -> bool:
	var b: Dictionary = GameSettings.data.get("bindings", {})
	for a in acts:
		if b.has(String(a)): return true
	return false

## Fill {action} placeholders. Bits whose action has no button on this device drop out,
## along with the words up to the next double space.
static func fmt(template: String) -> String:
	var parts := template.split("  ", false)
	var out: Array[String] = []
	for part in parts:
		var s: String = part.strip_edges()
		var ok := true
		var guard := 0
		while s.find("{") >= 0 and guard < 8:
			guard += 1
			var a := s.find("{")
			var b := s.find("}", a)
			if b < 0: break
			var k := key(s.substr(a + 1, b - a - 1))
			if k == "": ok = false
			s = s.substr(0, a) + k + s.substr(b + 1)
		if ok: out.append(s)
	return "   ".join(out)
