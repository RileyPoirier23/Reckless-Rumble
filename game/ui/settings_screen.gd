## Settings: controls (and rebinding them), the steering wheel (and calibrating it), the display,
## the UI, difficulty, graphics and sound. Opened from the title and from the pause menu. Every
## change is saved to user://settings.cfg and applied right away.
class_name SettingsScreen
extends Control

signal closed

const TABS := ["CONTROLS", "WHEEL", "DISPLAY", "UI", "DIFFICULTY", "GRAPHICS", "AUDIO"]
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")
const GREEN := Color("6fbf5a")
const INK := Color("0b090d")

## Layout, at 640x360: the tabs, the rows (scrolling) in their panel, what the selected row does,
## the keys. Every row reads in three columns: the name, then either the keyboard and controller
## buttons, or the value, which always sits in the controller column so values line up tab to tab.
const TAB_Y := 32.0
const LIST := Rect2(16, 50, 608, 230)
const ROW_Y := 70.0
const ROW_H := 13.0
const ROWS_VIS := 16
const LABEL_X := 26.0
const KEY_COL := 290.0
const PAD_COL := 452.0
const COL_W := 158.0               # a button column's cell
const VAL_X := PAD_COL             # the value column: VAL_X to VALUE_R
const VALUE_R := 610.0
const SLIDER_W := 122.0
const DESC := Rect2(16, 290, 608, 44)
const HINT_Y := 344.0

var tab := 0
var row := 0
var scroll := 0
var col := 0                   # on a button row: 0 the keyboard column, 1 the controller one
var capturing := ""            # the action being rebound
var _cap_t := 0.0
var note := ""
var wiz := {}                  # the wheel wizard, while it runs
var _dev_i := 0
var _quiet := -1               # a frame to ignore: the press that opened it, or a key just bound

func open() -> void:
	visible = true
	tab = 0
	row = 0
	scroll = 0
	capturing = ""
	wiz = {}
	note = ""
	process_mode = Node.PROCESS_MODE_ALWAYS
	_quiet = Engine.get_process_frames()

## Straight to the wheel: its tab, with the calibration already going (the "wheel found" offer).
func open_wheel() -> void:
	open()
	tab = TABS.find("WHEEL")
	_start_wizard()

func close() -> void:
	GameSettings.save_file()
	visible = false
	closed.emit()

func _changed(sec: String) -> void:
	var iw := get_node_or_null("/root/InputWatch")
	if iw: iw.changed(sec)
	else: GameSettings.save_file()

# ------------------------------------------------------------------ the rows

static func _t(v: bool) -> String:
	return "ON" if v else "OFF"

## One tab's rows. kind: bind (an action's buttons), choice (left/right through `opts`), slider,
## toggle, action (accept runs it), device (pick the wheel), live (the wheel's readout).
func rows() -> Array:
	var out: Array = []
	match TABS[tab]:
		"CONTROLS":
			for r in Controls.REBIND: out.append({ "kind": "bind", "action": r[0], "label": r[1], "desc": "ACCEPT TO PRESS A NEW KEY OR BUTTON. LEFT/RIGHT PICKS THE KEYBOARD OR CONTROLLER COLUMN. DELETE CLEARS IT." })
			out.append({ "kind": "choice", "sec": "controls", "key": "transmission", "label": "GEARBOX", "opts": ["auto", "manual"], "desc": "AUTOMATIC, OR SHIFT IT YOURSELF ON THE SHOULDER BUTTONS (Q AND E ON A KEYBOARD, WHERE G SWITCHES IT TOO)." })
			out.append({ "kind": "choice", "sec": "controls", "key": "clutch", "label": "CLUTCH", "opts": ["auto", "pedal"], "desc": "PEDAL: THE CLUTCH IS YOURS (A WHEEL'S THIRD PEDAL, OR THE CLUTCH KEY). LET IT OUT WITH NO REVS AND IT STALLS. MANUAL GEARBOX ONLY." })
			out.append({ "kind": "slider", "sec": "controls", "key": "pad_deadzone", "label": "STICK DEAD ZONE", "min": 0.04, "max": 0.3, "step": 0.02, "desc": "HOW FAR THE STICK MOVES BEFORE THE CAR STEERS. RAISE IT IF THE CAR WANDERS ON ITS OWN." })
			out.append({ "kind": "slider", "sec": "controls", "key": "pad_curve", "label": "STICK CURVE", "min": 1.0, "max": 2.6, "step": 0.1, "desc": "1.0 IS STRAIGHT. HIGHER MEANS GENTLER NEAR THE MIDDLE, FULL LOCK STILL AT THE END." })
			out.append({ "kind": "slider", "sec": "controls", "key": "speed_steer", "label": "LESS LOCK AT SPEED", "min": 0.0, "max": 1.5, "step": 0.1, "desc": "HOW MUCH THE STICK AND KEYS STEER LESS AT SPEED, SO YOU DON'T SPIN IT ON THE HIGHWAY. 0 IS NONE." })
			out.append({ "kind": "slider", "sec": "controls", "key": "trigger_deadzone", "label": "TRIGGER DEAD ZONE", "min": 0.0, "max": 0.2, "step": 0.02, "desc": "FOR WORN TRIGGERS THAT DON'T SIT AT ZERO." })
			out.append({ "kind": "toggle", "sec": "controls", "key": "kb_ramp", "label": "EASE IN THE KEYBOARD", "desc": "KEYS ARE ON OR OFF: THIS EASES THE GAS, BRAKE AND STEERING IN, AND QUICKER BACK OUT." })
			out.append({ "kind": "slider", "sec": "controls", "key": "vibration", "label": "VIBRATION", "min": 0.0, "max": 1.0, "step": 0.1, "desc": "CONTROLLER RUMBLE: CRASHES, THUNDER." })
			out.append({ "kind": "action", "do": "reset_bindings", "label": "PUT EVERY BUTTON BACK", "desc": "EVERY KEY AND BUTTON GOES BACK TO HOW IT CAME." })
		"WHEEL":
			out.append({ "kind": "device", "label": "WHEEL", "desc": "WHICH CONTROLLER IS THE WHEEL. LEFT/RIGHT GOES THROUGH WHAT'S PLUGGED IN." })
			out.append({ "kind": "toggle", "sec": "wheel", "key": "enabled", "label": "DRIVE WITH THE WHEEL", "desc": "THE RIM TURNS THE ROAD WHEELS ONE FOR ONE, AND THE STEERING HELP IS OFF. CALIBRATE IT FIRST." })
			out.append({ "kind": "action", "do": "calibrate", "label": "CALIBRATE", "desc": "FINDS YOUR STEERING AND PEDALS: HANDS OFF, FULL LEFT, FULL RIGHT, THE GAS, THE BRAKE." })
			out.append({ "kind": "choice", "sec": "wheel", "key": "rotation", "label": "WHEEL ROTATION", "opts": [270.0, 540.0, 900.0, 1080.0], "unit": " DEG", "desc": "LOCK TO LOCK, AS SET IN YOUR WHEEL'S OWN SOFTWARE. MATCH IT HERE." })
			out.append({ "kind": "choice", "sec": "wheel", "key": "range", "label": "STEERING RANGE", "opts": [0.0, 180.0, 270.0, 360.0, 450.0, 540.0, 720.0, 900.0], "unit": " DEG", "zero": "AUTO", "desc": "HOW MUCH OF THE RIM GIVES FULL LOCK. AUTO GEARS IT LIKE THE REAL CAR (ABOUT 14 TO 1)." })
			out.append({ "kind": "slider", "sec": "wheel", "key": "ratio", "label": "AUTO RATIO", "min": 10.0, "max": 20.0, "step": 1.0, "desc": "FOR AUTO RANGE: HOW MANY DEGREES OF RIM FOR ONE DEGREE AT THE ROAD WHEELS." })
			out.append({ "kind": "slider", "sec": "wheel", "key": "steer_dz", "label": "STEERING DEAD ZONE", "min": 0.0, "max": 0.1, "step": 0.01, "desc": "A LITTLE PLAY IN THE MIDDLE. MOST WHEELS WANT NONE." })
			out.append({ "kind": "slider", "sec": "wheel", "key": "steer_gamma", "label": "STEERING CURVE", "min": 0.6, "max": 2.0, "step": 0.1, "desc": "1.0 IS STRAIGHT THROUGH. HIGHER IS GENTLER AROUND THE MIDDLE." })
			out.append({ "kind": "slider", "sec": "wheel", "key": "pedal_dz", "label": "PEDAL DEAD ZONE", "min": 0.0, "max": 0.15, "step": 0.01, "desc": "HOW FAR A PEDAL GOES DOWN BEFORE IT DOES ANYTHING." })
			out.append({ "kind": "bind", "action": "shift_up", "label": "RIGHT PADDLE", "pad_only": true, "desc": "ACCEPT, THEN PULL THE PADDLE." })
			out.append({ "kind": "bind", "action": "shift_down", "label": "LEFT PADDLE", "pad_only": true, "desc": "ACCEPT, THEN PULL THE PADDLE." })
			for g in Controls.GEARS: out.append({ "kind": "bind", "action": g[0], "label": "H-SHIFTER " + String(g[1]), "pad_only": true, "desc": "ACCEPT, THEN PUT THE SHIFTER IN THAT GEAR. LET GO AND IT'S IN NEUTRAL." })
			out.append({ "kind": "live", "label": "WHAT THE WHEEL SAYS", "desc": "TURN IT AND PRESS THE PEDALS. NO PUSH-BACK IN THE GAME: TURN ON YOUR WHEEL'S CENTRING SPRING IN ITS OWN SOFTWARE." })
		"DISPLAY":
			out.append({ "kind": "choice", "sec": "display", "key": "mode", "label": "WINDOW", "opts": ["windowed", "fullscreen", "exclusive"], "desc": "A WINDOW, FULL SCREEN, OR EXCLUSIVE FULL SCREEN (LOWEST LAG)." })
			out.append({ "kind": "choice", "sec": "display", "key": "size", "label": "WINDOW SIZE", "opts": ["1280x720", "1920x1080", "2560x1440"], "desc": "THE WINDOW'S SIZE WHEN IT'S A WINDOW." })
			out.append({ "kind": "toggle", "sec": "display", "key": "vsync", "label": "VSYNC", "desc": "NO TEARING. OFF FOR THE LEAST INPUT LAG." })
			out.append({ "kind": "choice", "sec": "display", "key": "max_fps", "label": "FRAME CAP", "opts": [0, 30, 60, 120, 144, 240], "zero": "NONE", "desc": "AN UPPER LIMIT ON FRAMES A SECOND." })
			out.append({ "kind": "choice", "sec": "display", "key": "stretch", "label": "PIXEL SCALING", "opts": ["integer", "fractional"], "desc": "WHOLE-NUMBER SCALING KEEPS EVERY PIXEL SQUARE; FRACTIONAL FILLS THE SCREEN." })
		"UI":
			out.append({ "kind": "choice", "sec": "ui", "key": "messages", "label": "CHATTER", "opts": ["all", "important", "off"], "desc": "PASSENGERS, THE CROWD AT THE MEET: ALL OF IT, LESS OF IT, OR NONE. WHAT MATTERS ALWAYS SHOWS." })
			out.append({ "kind": "toggle", "sec": "ui", "key": "tips", "label": "FIRST-TIME TIPS", "desc": "THE ONE-TIME HINTS ABOUT THE MAP, GIGS AND THE CONTROLS." })
			out.append({ "kind": "toggle", "sec": "ui", "key": "radio", "label": "THE RADIO", "desc": "THREE STATIONS OUT OF PORT RUMBLE WHILE YOU DRIVE: THE DJ, THE NEWS, THE WEATHER, THE ADS, AND THE ODD WORD ABOUT YOU. N SWITCHES THEM." })
			out.append({ "kind": "toggle", "sec": "ui", "key": "scan_tool", "label": "SCAN TOOL", "desc": "THE DIAGNOSTIC COMPUTER UNDER THE DASH: FAULT CODES, THE TIRES, THE WARNING LIGHTS." })
			out.append({ "kind": "choice", "sec": "ui", "key": "camera_mode", "label": "CAMERA", "opts": ["chase", "follow", "top_down"], "desc": "CHASE TURNS WITH THE CAR. FREE ROAM SWINGS ROUND BEHIND WHERE YOU'RE GOING (RIGHT STICK LOOKS ROUND). TOP DOWN KEEPS NORTH UP. Y (TRIANGLE) OR T FLIPS THROUGH THEM WHILE YOU DRIVE." })
			out.append({ "kind": "choice", "sec": "ui", "key": "camera_angle", "label": "CAMERA ANGLE", "opts": ["overhead", "angled", "low"], "desc": "STRAIGHT DOWN, TIPPED, OR DOWN LOW TO SEE THE SIDES OF THINGS. (THE Y KEY FLIPS THROUGH THEM TOO.)" })
			out.append({ "kind": "choice", "sec": "ui", "key": "camera_zoom", "label": "CAMERA DISTANCE", "opts": [0.7, 0.8, 0.9, 1.0, 1.1, 1.2], "desc": "FURTHER OUT SEES MORE ROAD; CLOSER IN SEES MORE CAR." })
			out.append({ "kind": "choice", "sec": "ui", "key": "clock", "label": "CLOCK", "opts": ["normal", "slow", "fast"], "desc": "HOW FAST A DAY GOES BY ON THE ROAD: AN HOUR, TWO HOURS, OR 24 MINUTES." })
			out.append({ "kind": "toggle", "sec": "ui", "key": "controls_card", "label": "CONTROLS CARD AT START", "desc": "SHOW THE CONTROLS EVERY TIME YOU START DRIVING (F1 ANY TIME)." })
			out.append({ "kind": "choice", "sec": "controls", "key": "prompts", "label": "BUTTON PROMPTS", "opts": ["auto", "keyboard", "xbox", "playstation"], "desc": "AUTO FOLLOWS WHATEVER YOU TOUCHED LAST." })
		"DIFFICULTY":
			out.append({ "kind": "choice", "sec": "difficulty", "key": "preset", "label": "DIFFICULTY", "opts": ["easy", "normal", "hard"], "desc": "EASY: ARCADE HANDLING, EASYGOING COPS, FEW ANIMALS. HARD: NO HELP, STRICT COPS, MOOSE." })
			out.append({ "kind": "choice", "sec": "difficulty", "key": "assist", "label": "DRIVING AIDS", "opts": ["arcade", "street", "sim"], "desc": "ARCADE: GRIP, NO DAMAGE TO THE ENGINE. STREET: TRACTION AND STABILITY CONTROL, ABS. SIM: NONE OF IT." })
			out.append({ "kind": "choice", "sec": "difficulty", "key": "police", "label": "POLICE", "opts": ["relaxed", "normal", "strict"], "desc": "HOW FAR OVER THE LIMIT THEY LET SLIDE, AND HOW LONG THEY WAIT FOR YOU TO PULL OVER." })
			out.append({ "kind": "choice", "sec": "difficulty", "key": "wildlife", "label": "MOOSE AND DEER", "opts": ["off", "rare", "normal", "many"], "desc": "HOW OFTEN THEY COME OUT ON THE WILDLIFE STRETCHES." })
		"GRAPHICS":
			out.append({ "kind": "choice", "sec": "graphics", "key": "lights", "label": "STREETLIGHTS", "opts": [16, 32, 56], "desc": "HOW MANY STREETLIGHTS CAST LIGHT AT ONCE. FEWER IS FASTER." })
			out.append({ "kind": "choice", "sec": "graphics", "key": "weather", "label": "RAIN AND SNOW", "opts": ["off", "half", "full"], "desc": "THE FALLING RAIN AND SNOW (THE ROAD STILL GETS WET)." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "sight", "label": "LINE OF SIGHT", "desc": "BUILDINGS BLOCK WHAT LEO CAN SEE: TRAFFIC BEHIND THEM FADES OUT, AND A BUILDING IN FRONT OF THE CAR GOES SEE-THROUGH." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "clouds", "label": "CLOUD SHADOWS", "desc": "SHADOWS OF THE CLOUDS DRIFTING OVER." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "smoke", "label": "TIRE SMOKE", "desc": "SMOKE OFF SPINNING TIRES." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "skids", "label": "SKID MARKS", "desc": "RUBBER LEFT ON THE ROAD." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "flashes", "label": "LIGHTNING FLASHES", "desc": "THE SCREEN FLASHES WITH LIGHTNING. OFF IF FLASHES BOTHER YOU." })
			out.append({ "kind": "toggle", "sec": "graphics", "key": "blur", "label": "DRUNK BLUR", "desc": "THE STORY'S BLURRY DRIVING." })
		"AUDIO":
			out.append({ "kind": "slider", "sec": "audio", "key": "master", "label": "VOLUME", "min": 0.0, "max": 1.0, "step": 0.1, "desc": "EVERYTHING." })
			out.append({ "kind": "slider", "sec": "audio", "key": "engine", "label": "ENGINE", "min": 0.0, "max": 1.0, "step": 0.1, "desc": "THE ENGINE, THE HORN, THE BLINKERS." })
			out.append({ "kind": "slider", "sec": "audio", "key": "effects", "label": "EFFECTS", "min": 0.0, "max": 1.0, "step": 0.1, "desc": "EVERYTHING ELSE." })
			out.append({ "kind": "toggle", "sec": "audio", "key": "mute_unfocused", "label": "MUTE IN THE BACKGROUND", "desc": "QUIET WHEN THE GAME ISN'T THE WINDOW YOU'RE USING." })
	if TABS[tab] != "CONTROLS": out.append({ "kind": "action", "do": "reset_tab", "label": "RESET THIS TAB", "desc": "EVERYTHING ON THIS TAB GOES BACK TO HOW IT CAME." })
	return out

## What a row shows on the right.
func value_text(r: Dictionary) -> String:
	match String(r.kind):
		"choice":
			var v: Variant = GameSettings.get_v(String(r.sec), String(r.key))
			if r.has("zero") and float(v) == 0.0: return String(r.zero)
			if v is float and r.has("unit"): return "%d%s" % [int(v), String(r.unit)]
			if v is float: return "%.1f" % float(v)
			return str(v).to_upper()
		"slider":
			var v := float(GameSettings.get_v(String(r.sec), String(r.key)))
			return "%.2f" % v if float(r.step) < 0.1 else ("%.1f" % v if float(r.step) < 1.0 else "%d" % int(v))
		"toggle": return _t(bool(GameSettings.get_v(String(r.sec), String(r.key))))
		"device":
			var nm := String(GameSettings.get_v("wheel", "name"))
			if Wheel.needs_setup(): return (Input.get_joy_name(Wheel.device) + " (FOUND)").to_upper().substr(0, 40)
			return nm.to_upper().substr(0, 40) if nm != "" else "NONE PICKED"
		"action": return ">"
		"live": return ""
	return ""

## A button row's two columns.
func bind_texts(r: Dictionary) -> Array:
	var es := Controls.entries(String(r.action), GameSettings.data.get("bindings", {}))
	var k: Array = []
	var p: Array = []
	for e in es:
		if String(e[0]) == "key": k.append(Controls.label(e))
		else: p.append(Controls.label(e))
	return [", ".join(k) if not k.is_empty() else "-", ", ".join(p) if not p.is_empty() else "-"]

# ------------------------------------------------------------------ input

func _process(dt: float) -> void:
	if not visible: return
	queue_redraw()
	_cap_t -= dt
	if not wiz.is_empty():
		_wizard(dt)
		return
	if capturing != "" or Engine.get_process_frames() == _quiet: return
	var rs := rows()
	if Input.is_action_just_pressed("ui_tab_next") or Input.is_action_just_pressed("ui_tab_prev"):
		tab = (tab + (1 if Input.is_action_just_pressed("ui_tab_next") else TABS.size() - 1)) % TABS.size()
		row = 0
		scroll = 0
		note = ""
		return
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("menu_back"):
		close()
		return
	if Input.is_action_just_pressed("ui_down"): row = (row + 1) % rs.size()
	if Input.is_action_just_pressed("ui_up"): row = (row + rs.size() - 1) % rs.size()
	if row < scroll: scroll = row
	if row >= scroll + ROWS_VIS: scroll = row - ROWS_VIS + 1
	var r: Dictionary = rs[row]
	var dx := 0
	if Input.is_action_just_pressed("ui_right"): dx = 1
	if Input.is_action_just_pressed("ui_left"): dx = -1
	if dx != 0: _step(r, dx)
	if Input.is_action_just_pressed("ui_accept"): _accept(r)

func _step(r: Dictionary, dx: int) -> void:
	match String(r.kind):
		"bind":
			if not r.get("pad_only", false): col = clampi(col + dx, 0, 1)
		"choice":
			var opts: Array = r.opts
			var cur: Variant = GameSettings.get_v(String(r.sec), String(r.key))
			var i := 0
			for k in opts.size():
				if str(opts[k]) == str(cur) or (opts[k] is float and absf(float(opts[k]) - float(cur)) < 0.001): i = k
			GameSettings.set_v(String(r.sec), String(r.key), opts[(i + dx + opts.size()) % opts.size()])
			_changed(String(r.sec))
		"slider":
			var v := snappedf(clampf(float(GameSettings.get_v(String(r.sec), String(r.key))) + dx * float(r.step), float(r.min), float(r.max)), float(r.step))
			GameSettings.set_v(String(r.sec), String(r.key), v)
			_changed(String(r.sec))
		"toggle":
			GameSettings.set_v(String(r.sec), String(r.key), not bool(GameSettings.get_v(String(r.sec), String(r.key))))
			_changed(String(r.sec))
		"device":
			var pads := Input.get_connected_joypads()
			if pads.is_empty():
				note = "NOTHING'S PLUGGED IN."
				return
			_dev_i = (_dev_i + dx + pads.size()) % pads.size()
			var d: int = pads[_dev_i]
			GameSettings.set_v("wheel", "name", Input.get_joy_name(d))
			GameSettings.set_v("wheel", "guid", Input.get_joy_guid(d))
			_changed("wheel")

func _accept(r: Dictionary) -> void:
	match String(r.kind):
		"bind":
			capturing = String(r.action)
			_cap_t = 0.2
			note = "PRESS A %s FOR %s. ESC TO CANCEL, DELETE TO CLEAR." % ["KEY" if col == 0 and not r.get("pad_only", false) else "BUTTON", String(r.label)]
		"toggle": _step(r, 1)
		"action":
			match String(r.do):
				"reset_bindings":
					Controls.reset_bindings()
					_changed("bindings")
					note = "EVERY BUTTON'S BACK HOW IT CAME."
				"reset_tab":
					var sec := { "WHEEL": "wheel", "DISPLAY": "display", "UI": "ui", "DIFFICULTY": "difficulty", "GRAPHICS": "graphics", "AUDIO": "audio" }.get(TABS[tab], "") as String
					if sec != "":
						GameSettings.reset(sec)
						_changed(sec)
						note = "THIS TAB'S BACK HOW IT CAME."
				"calibrate": _start_wizard()

func _input(e: InputEvent) -> void:
	if not visible or capturing == "" or _cap_t > 0.0: return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).physical_keycode
		if k == KEY_ESCAPE:
			capturing = ""
			note = "LEFT AS IT WAS."
			get_viewport().set_input_as_handled()
			return
		if k == KEY_DELETE or k == KEY_BACKSPACE:
			_finish_bind([])
			get_viewport().set_input_as_handled()
			return
	var pad_col := col == 1 or _pad_only_row()
	var en := Controls.entry_of(e, Wheel.device)
	if en.is_empty(): return
	if pad_col == (String(en[0]) == "key"): return       # a key in the controller column, or the other way round
	_finish_bind(en)
	get_viewport().set_input_as_handled()

func _pad_only_row() -> bool:
	var rs := rows()
	return row < rs.size() and bool(rs[row].get("pad_only", false))

func _finish_bind(en: Array) -> void:
	var column := "pad" if col == 1 or _pad_only_row() else "key"
	Controls.bind(capturing, column, en)
	note = "%s: %s." % [capturing.to_upper().replace("_", " "), Controls.label(en) if not en.is_empty() else "CLEARED"]
	capturing = ""
	_quiet = Engine.get_process_frames()
	_changed("bindings")

# ------------------------------------------------------------------ the wheel wizard

const WIZ_STEPS := ["wake", "rest", "left", "right", "gas", "brake", "clutch", "up", "down", "g1", "g2", "g3", "g4", "g5", "g6", "gr", "done"]
const WIZ_GEARS := { "g1": "gear_1", "g2": "gear_2", "g3": "gear_3", "g4": "gear_4", "g5": "gear_5", "g6": "gear_6", "gr": "gear_r" }
const WIZ_TEXT := {
	"wake": "PRESS THE GAS AND THE BRAKE ONCE EACH AND TURN THE WHEEL A LITTLE (SO THEY WAKE UP). LET GO, THEN PRESS A BUTTON ON THE WHEEL.",
	"rest": "HANDS OFF THE WHEEL, FEET OFF THE PEDALS. HOLD STILL...",
	"left": "TURN THE WHEEL ALL THE WAY LEFT, HOLD IT, AND PRESS ANY BUTTON ON THE WHEEL.",
	"right": "NOW ALL THE WAY RIGHT, HOLD IT, AND PRESS A BUTTON.",
	"gas": "LET GO. PUSH THE GAS ALL THE WAY DOWN, HOLD IT, AND PRESS A BUTTON.",
	"brake": "LET GO OF THE GAS. PUSH THE BRAKE ALL THE WAY DOWN, HOLD IT, AND PRESS A BUTTON.",
	"clutch": "LET GO. GOT A CLUTCH? PUSH IT ALL THE WAY DOWN, HOLD IT, AND PRESS A BUTTON. NO CLUTCH? PRESS %s.",
	"up": "PULL THE RIGHT PADDLE: THAT SHIFTS UP. NO PADDLES? PRESS %s.",
	"down": "NOW THE LEFT PADDLE: THAT SHIFTS DOWN. NO PADDLES? PRESS %s.",
	"g1": "GOT AN H-SHIFTER? PUT IT IN 1ST. NO SHIFTER? PRESS %s.",
	"g2": "2ND.", "g3": "3RD.", "g4": "4TH.", "g5": "5TH.",
	"g6": "6TH. (A FIVE-SPEED? PRESS %s.)",
	"gr": "REVERSE.",
	"done": "DONE. PRESS A BUTTON TO SAVE IT, AND DRIVE.",
}

## The wizard's words for a step, with the keyboard/controller button filled in.
static func wiz_text(step: String) -> String:
	var t := String(WIZ_TEXT[step])
	return t % Hints.fmt("{ui_accept}") if t.contains("%s") else t

## A button on the wheel pressed since last frame (-1 if none). `held` is last frame's buttons.
static func wheel_press(dev: int, held: Array) -> int:
	var hit := -1
	if held.size() != JOY_BUTTON_MAX: held.resize(JOY_BUTTON_MAX)
	for b in JOY_BUTTON_MAX:
		var down := Input.is_joy_button_pressed(dev, b as JoyButton)
		if down and not bool(held[b]) and hit < 0: hit = b
		held[b] = down
	return hit

## A button pressed since last frame on any of the watched rig parts: [device, button], or [].
static func rig_press(devs: Array, held: Dictionary) -> Array:
	var hit: Array = []
	for d in devs:
		var h: Array = held.get(d, [])
		var b := wheel_press(int(d), h)
		held[d] = h
		if b >= 0 and hit.is_empty(): hit = [int(d), b]
	return hit

func _wiz_device() -> int:
	Wheel.resolve()
	if Wheel.device >= 0: return Wheel.device
	var pads := Input.get_connected_joypads()
	for d in pads:
		if Wheel.looks_like_wheel(d): return d
	return pads[0] if not pads.is_empty() else -1

func _start_wizard() -> void:
	var d := _wiz_device()
	if d < 0:
		note = "PLUG THE WHEEL IN FIRST."
		return
	# watch the wheel and anything else that could be its pedals (a pedal set on its own plug),
	# but not a regular controller
	var devs: Array[int] = [d]
	for o in Wheel.connected():
		if o != d and (Wheel.looks_like_rig(o) or not Input.is_joy_known(o)): devs.append(o)
	wiz = { "dev": d, "devs": devs, "step": 0, "t": 0.0, "sum": [], "n": 0, "rest": [], "left": [], "right": [], "gas": [], "brake": [], "clutch": [], "held": [], "up": -1, "down": -1,
		"rig_held": {}, "gears": {} }
	wheel_press(d, wiz.held)        # whatever's held as it starts doesn't count
	rig_press(devs, wiz.rig_held)

## Every watched device's axes, one after another (device k's axis i is at k * JOY_AXIS_MAX + i).
static func _axes(devs: Array) -> Array:
	var out: Array = []
	for d in devs:
		for i in JOY_AXIS_MAX: out.append(Input.get_joy_axis(int(d), i as JoyAxis))
	return out

func _wizard(dt: float) -> void:
	var step: String = WIZ_STEPS[int(wiz.step)]
	var wb := wheel_press(int(wiz.dev), wiz.held)
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		wiz = {}
		note = "CALIBRATION CANCELLED. NOTHING CHANGED."
		return
	var now := _axes(wiz.devs)
	if step == "wake":
		if wb >= 0 or Input.is_action_just_pressed("ui_accept"): wiz.step = 1
		return
	if step == "rest":
		wiz.t = float(wiz.t) + dt
		if (wiz.sum as Array).is_empty(): wiz.sum = now.duplicate()
		else:
			for i in now.size(): wiz.sum[i] = float(wiz.sum[i]) + float(now[i])
		wiz.n = int(wiz.n) + 1
		if float(wiz.t) >= 1.5:
			var rest: Array = []
			for v in wiz.sum: rest.append(float(v) / float(wiz.n))
			wiz.rest = rest
			wiz.step = WIZ_STEPS.find("left")
		return
	if WIZ_GEARS.has(step):
		var rp := rig_press(wiz.devs, wiz.rig_held)
		if wb >= 0 and rp.is_empty(): rp = [int(wiz.dev), wb]
		if not rp.is_empty():
			wiz.gears[WIZ_GEARS[step]] = rp
			wiz.step = int(wiz.step) + 1
		elif Input.is_action_just_pressed("ui_accept"):
			wiz.step = WIZ_STEPS.find("done")       # no shifter, or no more gears
		return
	rig_press(wiz.devs, wiz.rig_held)               # keep the other parts' buttons in step
	# a button on the wheel goes on to the next step (so you never have to let go), as does accept
	if wb < 0 and not Input.is_action_just_pressed("ui_accept"): return
	if step == "up" or step == "down":
		wiz[step] = wb
		wiz.step = int(wiz.step) + 1
		return
	if step == "clutch" and wb < 0:
		wiz.clutch = []                               # no third pedal
		wiz.step = int(wiz.step) + 1
		return
	if step == "done":
		var res := Wizard.solve(wiz.rest, wiz.left, wiz.right, wiz.gas, wiz.brake, wiz.clutch)
		# which device each axis was on: the wheel is whatever turned, the pedals whatever was pressed
		var devs: Array = wiz.devs
		var d := int(devs[int(res.steer_axis) / JOY_AXIS_MAX])
		var pd := int(devs[int(res.gas_axis) / JOY_AXIS_MAX])
		for k in ["steer_axis", "gas_axis", "brake_axis"]: res[k] = int(res[k]) % JOY_AXIS_MAX
		if int(res.clutch_axis) >= 0: res.clutch_axis = int(res.clutch_axis) % JOY_AXIS_MAX
		GameSettings.set_v("wheel", "name", Input.get_joy_name(d))
		GameSettings.set_v("wheel", "guid", Input.get_joy_guid(d))
		GameSettings.set_v("wheel", "ids", Wheel.ids_of(d))
		GameSettings.set_v("wheel", "pedals_name", Input.get_joy_name(pd) if pd != d else "")
		GameSettings.set_v("wheel", "pedals_guid", Input.get_joy_guid(pd) if pd != d else "")
		GameSettings.set_v("wheel", "pedals_ids", Wheel.ids_of(pd) if pd != d else "")
		for k in res: GameSettings.set_v("wheel", k, res[k])
		GameSettings.set_v("wheel", "enabled", true)
		_changed("wheel")
		for pair in [["shift_up", int(wiz.up)], ["shift_down", int(wiz.down)]]:
			if int(pair[1]) >= 0: Controls.bind(String(pair[0]), "pad", ["joybtn", int(pair[1]), 0.0, d])
		var gears: Dictionary = wiz.gears
		for g in gears:
			var rp: Array = gears[g]
			var en: Array = ["joybtn", int(rp[1]), 0.0, int(rp[0])]
			if int(rp[0]) != d: en.append(Input.get_joy_name(int(rp[0])))     # a shifter on its own plug
			Controls.bind(String(g), "pad", en)
		_changed("bindings")
		var paddles := "" if int(wiz.up) < 0 else ", PADDLES ON BUTTONS %d AND %d" % [int(wiz.up), int(wiz.down)]
		if not gears.is_empty(): paddles += ", A %d-POSITION SHIFTER" % gears.size()
		if int(res.clutch_axis) >= 0: paddles += ", A CLUTCH ON AXIS %d (TURN IT ON UNDER CONTROLS > CLUTCH)" % int(res.clutch_axis)
		wiz = {}
		note = "THE WHEEL'S SET UP. STEERING ON AXIS %d, GAS ON %d, BRAKE ON %d%s%s%s." % [int(res.steer_axis), int(res.gas_axis), int(res.brake_axis), " (ONE AXIS)" if res.combined else "", " (THE PEDAL SET'S OWN PLUG)" if pd != d else "", paddles]
		return
	wiz[step] = now
	wiz.step = int(wiz.step) + 1

## Working the calibration out from what the axes read at each step (pure: the tests use it).
class Wizard:
	static func solve(rest: Array, left: Array, right: Array, gas: Array, brake: Array, clutch := []) -> Dictionary:
		var n := rest.size()
		# steering: the axis that moved most between full left and full right
		var sa := 0
		for i in n:
			if absf(float(right[i]) - float(left[i])) > absf(float(right[sa]) - float(left[sa])): sa = i
		var lo := minf(float(left[sa]), float(right[sa]))
		var hi := maxf(float(left[sa]), float(right[sa]))
		# the gas: what moved most from rest, other than the steering
		var ga := -1
		for i in n:
			if i == sa: continue
			if ga < 0 or absf(float(gas[i]) - float(rest[i])) > absf(float(gas[ga]) - float(rest[ga])): ga = i
		var ba := -1
		for i in n:
			if i == sa: continue
			if ba < 0 or absf(float(brake[i]) - float(rest[i])) > absf(float(brake[ba]) - float(rest[ba])): ba = i
		# the clutch, if a third pedal moved: whatever moved most that isn't the others, and moved enough
		var ca := -1
		if clutch.size() == n:
			for i in n:
				if i == sa or i == ga or i == ba: continue
				if ca < 0 or absf(float(clutch[i]) - float(rest[i])) > absf(float(clutch[ca]) - float(rest[ca])): ca = i
			if ca >= 0 and absf(float(clutch[ca]) - float(rest[ca])) < 0.25: ca = -1
		return { "clutch_axis": ca, "clutch_rest": float(rest[ca]) if ca >= 0 else -1.0, "clutch_full": float(clutch[ca]) if ca >= 0 else 1.0,
			"steer_axis": sa, "steer_center": float(rest[sa]), "steer_min": lo, "steer_max": hi,
			"steer_sign": 1.0 if float(right[sa]) > float(left[sa]) else -1.0,
			"gas_axis": ga, "gas_rest": float(rest[ga]), "gas_full": float(gas[ga]),
			"brake_axis": ba, "brake_rest": float(rest[ba]), "brake_full": float(brake[ba]),
			"combined": ga == ba }

# ------------------------------------------------------------------ drawing

## Where row i (counting from the top of the list) sits.
static func row_rect(i: int) -> Rect2:
	return Rect2(18, ROW_Y + i * ROW_H - 2, 598, ROW_H - 1)

## The tabs along the top, left to right.
static func tab_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var x := 16.0
	for t: String in TABS:
		var w := PixelFont.width(t, 2) + 12
		out.append(Rect2(x, TAB_Y, w, 14))
		x += w + 2
	return out

func _draw() -> void:
	if not visible: return
	draw_rect(Rect2(0, 0, 640, 360), UiKit.BG)
	UiKit.title(self, Vector2(16, 10), "SETTINGS")
	var hint_tabs := Hints.fmt("{ui_tab_prev}/{ui_tab_next}: TABS")
	UiKit.hints(self, 624 - UiKit.hints_width(hint_tabs) / 2.0, 14, hint_tabs)
	# the tabs: the open one a solid gold chip standing on a gold rule, the rest quiet
	var trs := tab_rects()
	draw_rect(Rect2(16, TAB_Y + 14, 608, 1), Color(GOLD, 0.6))
	for i in TABS.size():
		var r: Rect2 = trs[i]
		if i == tab:
			draw_rect(r, GOLD)
			PixelFont.draw(self, r.position + Vector2(6, 3), TABS[i], INK, 2)
		else:
			draw_rect(Rect2(r.position, r.size - Vector2(0, 1)), Color(1, 1, 1, 0.05))
			PixelFont.draw(self, r.position + Vector2(6, 3), TABS[i], ASH, 2)
	if not wiz.is_empty():
		_draw_wizard()
		return
	var rs := rows()
	UiKit.panel(self, LIST)
	if TABS[tab] == "CONTROLS":
		PixelFont.draw(self, Vector2(KEY_COL, ROW_Y - 12), "KEYBOARD", ASH, 2)
		PixelFont.draw(self, Vector2(PAD_COL, ROW_Y - 12), "CONTROLLER / WHEEL", ASH, 2)
	if rs.size() > ROWS_VIS:
		var cnt := "%d/%d" % [row + 1, rs.size()]
		PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(cnt), ROW_Y - 11), cnt, ASH)
		# the scrollbar down the right edge
		var track := Rect2(619, ROW_Y - 2, 2, ROWS_VIS * ROW_H - 1)
		draw_rect(track, UiKit.TRACK)
		var th := maxf(8.0, track.size.y * ROWS_VIS / rs.size())
		var ty := track.position.y + (track.size.y - th) * scroll / maxf(1.0, rs.size() - ROWS_VIS)
		draw_rect(Rect2(track.position.x, ty, 2, th), Color(GOLD, 0.8))
	for i in range(scroll, mini(rs.size(), scroll + ROWS_VIS)):
		var r: Dictionary = rs[i]
		var rr := row_rect(i - scroll)
		var on := i == row
		if on: UiKit.select(self, rr)
		elif (i - scroll) % 2 == 1: draw_rect(rr, Color(1, 1, 1, 0.02))
		var y := rr.position.y + 2
		var kind := String(r.kind)
		PixelFont.draw(self, Vector2(LABEL_X, y), String(r.label), GOLD if on else (BONE if kind != "action" else Color(BONE, 0.85)), 2)
		match kind:
			"bind": _draw_bind(r, rr, on)
			"live": _draw_live(Vector2(KEY_COL, y))
			"choice", "device": _draw_choice(value_text(r), rr, on)
			"slider": _draw_slider(r, rr, on)
			"toggle": _draw_toggle(bool(GameSettings.get_v(String(r.sec), String(r.key))), rr, on)
			"action": _draw_action(rr, on)
	# what the selected row does, in a panel named after it
	var cur: Dictionary = rs[row] if row < rs.size() else {}
	var title := "NOTE" if note != "" else String(cur.get("label", ""))
	UiKit.panel(self, DESC, UiKit.fit(title, DESC.size.x - 40), GOLD if note == "" else GREEN)
	var desc := note if note != "" else String(cur.get("desc", ""))
	var ls := UiKit.wrap(desc, DESC.size.x - 2 * UiKit.PAD)
	for k in mini(ls.size(), 3): PixelFont.draw(self, DESC.position + Vector2(UiKit.PAD, 12 + k * UiKit.LINE_H), ls[k], BONE if note != "" else Color(BONE, 0.8), 2)
	UiKit.hints(self, 320, HINT_Y, Hints.fmt("{updown}: PICK  {leftright}: CHANGE  {ui_accept}: SELECT  {ui_cancel}: DONE"))

## A button row: the keyboard column and the controller one, the one you're on boxed in gold.
func _draw_bind(r: Dictionary, rr: Rect2, on: bool) -> void:
	var bt := bind_texts(r)
	var cap := capturing == String(r.action)
	var pad_only := bool(r.get("pad_only", false))
	var blink := int(Time.get_ticks_msec() / 300) % 2 == 0
	for c in 2:
		if c == 0 and pad_only: continue
		var x := KEY_COL if c == 0 else PAD_COL
		var here := on and (c == col or pad_only)
		var cell := Rect2(x - 4, rr.position.y, COL_W, rr.size.y)
		var txt := String(bt[c])
		if cap and here: txt = "PRESS ONE..." if blink else ""
		if here:
			draw_rect(cell, Color(GOLD, 0.12))
			draw_rect(cell, Color(GOLD, 0.8), false, 1.0)
		PixelFont.draw(self, Vector2(x, rr.position.y + 2), UiKit.fit(txt, COL_W - 8), GOLD if here else (ASH if txt == "-" else BONE), 2)

## A choice: the value centred in the value column, arrows either side (lit when it's yours to change).
func _draw_choice(v: String, rr: Rect2, on: bool) -> void:
	var y := rr.position.y + 2
	var ac := GOLD if on else Color(ASH, 0.45)
	PixelFont.draw(self, Vector2(VAL_X, y), "<", ac, 2)
	PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(">", 2), y), ">", ac, 2)
	PixelFont.draw_centered(self, (VAL_X + VALUE_R) / 2.0, y, UiKit.fit(v, VALUE_R - VAL_X - 20), GOLD if on else BONE, 2)

## A slider: a bar with a knob where it's set, the number at the end.
func _draw_slider(r: Dictionary, rr: Rect2, on: bool) -> void:
	var v := float(GameSettings.get_v(String(r.sec), String(r.key)))
	var frac := clampf((v - float(r.min)) / maxf(0.0001, float(r.max) - float(r.min)), 0.0, 1.0)
	var bar := Rect2(VAL_X, rr.position.y + 4, SLIDER_W, 5)
	UiKit.meter(self, bar, frac, GOLD if on else Color(BONE, 0.55))
	var kx := bar.position.x + roundf((bar.size.x - 3) * frac)
	draw_rect(Rect2(kx, bar.position.y - 2, 3, 9), GOLD if on else BONE)
	var t := value_text(r)
	PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(t, 2), rr.position.y + 2), t, GOLD if on else BONE, 2)

## A toggle: a little switch, green when it's on, and the word.
func _draw_toggle(v: bool, rr: Rect2, on: bool) -> void:
	var sw := Rect2(VAL_X, rr.position.y + 2, 20, 8)
	draw_rect(sw, Color(GREEN, 0.85) if v else UiKit.TRACK)
	draw_rect(sw, Color(GOLD, 0.8) if on else Color(1, 1, 1, 0.18), false, 1.0)
	draw_rect(Rect2(sw.position.x + (11 if v else 1), sw.position.y + 1, 8, 6), BONE if v else ASH)
	PixelFont.draw(self, Vector2(VAL_X + 28, rr.position.y + 2), _t(v), GOLD if on else (BONE if v else ASH), 2)

## A row that does something: a chevron, or the key that does it once you're on it.
func _draw_action(rr: Rect2, on: bool) -> void:
	if on:
		var k := Hints.fmt("{ui_accept}")
		var w := PixelFont.width(k, 2) + 6
		var cap := Rect2(VALUE_R - w, rr.position.y + 1, w, 11)
		draw_rect(cap, Color(GOLD, 0.2))
		draw_rect(cap, Color(GOLD, 0.8), false, 1.0)
		PixelFont.draw(self, cap.position + Vector2(3, 1), k, GOLD, 2)
	else:
		PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(">", 2), rr.position.y + 2), ">", ASH, 2)

## The wheel as it reads right now: steering from the middle, the gas, the brake.
func _draw_live(p: Vector2) -> void:
	if not Wheel.active() and Wheel.device < 0:
		PixelFont.draw(self, p, "NO WHEEL PLUGGED IN", ASH, 2)
		return
	var ins := Wheel.inputs(0.55) if Wheel.device >= 0 else [0.0, 0.0, 0.0, 0.0]
	var x := p.x
	for m in [["STEER", 92.0], ["GAS", 56.0], ["BRAKE", 56.0]]:
		var lab: String = m[0]
		PixelFont.draw(self, Vector2(x, p.y), lab, ASH, 2)
		x += PixelFont.width(lab, 2) + 4
		var bar := Rect2(x, p.y + 2, float(m[1]), 5)
		match lab:
			"STEER": UiKit.meter_mid(self, bar, float(ins[2]))
			"GAS": UiKit.meter(self, bar, float(ins[0]), GREEN)
			"BRAKE": UiKit.meter(self, bar, float(ins[1]), RED)
		x += float(m[1]) + 10

func _draw_wizard() -> void:
	var step: String = WIZ_STEPS[int(wiz.step)]
	UiKit.panel(self, LIST.merge(DESC))
	var x0 := LIST.position.x + UiKit.PAD
	var y0 := LIST.position.y + 8
	PixelFont.draw(self, Vector2(x0, y0), "CALIBRATING", GOLD, 2)
	PixelFont.draw(self, Vector2(x0 + PixelFont.width("CALIBRATING", 2) + 8, y0), UiKit.fit(Input.get_joy_name(int(wiz.dev)).to_upper(), 300), BONE, 2)
	# how far through it is: a pip a step, gold behind you, bone where you are
	var n := WIZ_STEPS.size()
	for k in n:
		var pr := Rect2(LIST.end.x - UiKit.PAD - (n - k) * 8 + 2, y0 + 1, 6, 6)
		if k < int(wiz.step): draw_rect(pr, GOLD)
		elif k == int(wiz.step): draw_rect(pr, BONE)
		else: draw_rect(pr, Color(1, 1, 1, 0.18), false, 1.0)
	draw_rect(Rect2(x0, y0 + 14, LIST.size.x - 2 * UiKit.PAD, 1), UiKit.RULE)
	# what to do now, big
	var wl := UiKit.wrap_title(wiz_text(step), LIST.size.x - 2 * UiKit.PAD)
	for ln_i in mini(wl.size(), 4):
		UiKit.title(self, Vector2(x0, y0 + 24 + ln_i * 18), wl[ln_i], BONE)
	# the axes, live, so you can see which one is moving (the ones that have said anything), in
	# two columns of six
	var devs: Array = wiz.devs
	var now := _axes(devs)
	var ay := y0 + 24 + 4 * 18 + 8
	PixelFont.draw(self, Vector2(x0, ay), "WHAT IT READS", ASH, 2)
	var row_i := 0
	for k in now.size():
		var v := float(now[k])
		if v == 0.0 or row_i >= 12: continue
		var cx := x0 + (row_i / 6) * 300.0
		var y := ay + 14 + (row_i % 6) * 13.0
		row_i += 1
		var lab := ("AXIS %d" % (k % JOY_AXIS_MAX)) if devs.size() == 1 else ("%d: AXIS %d" % [k / JOY_AXIS_MAX + 1, k % JOY_AXIS_MAX])
		PixelFont.draw(self, Vector2(cx, y), lab, ASH, 2)
		UiKit.meter_mid(self, Rect2(cx + 70, y + 2, 170, 5), v)
		PixelFont.draw(self, Vector2(cx + 248, y), "%.2f" % v, BONE, 2)
	if row_i == 0: PixelFont.draw(self, Vector2(x0, ay + 14), "NOTHING YET: MOVE SOMETHING.", Color(ASH, 0.7), 2)
	if devs.size() > 1:
		var names: Array = []
		for k in devs.size(): names.append("%d: %s" % [k + 1, Input.get_joy_name(int(devs[k])).to_upper()])
		PixelFont.draw(self, Vector2(x0, DESC.end.y - 14), UiKit.fit("   ".join(names), LIST.size.x - 2 * UiKit.PAD), ASH, 2)
	UiKit.hints(self, 320, HINT_Y, Hints.fmt("{ui_accept}: NEXT (OR ANY BUTTON ON THE WHEEL)  {ui_cancel}: CANCEL"))
