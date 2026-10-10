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

## Layout, at 640x360: the tabs, the rows (scrolling), what the selected row does, the keys.
const TAB_Y := 22.0
const ROW_Y := 48.0
const ROW_H := 13.0
const ROWS_VIS := 18
const LABEL_X := 20.0
const VALUE_R := 620.0
const KEY_COL := 330.0
const PAD_COL := 480.0
const DESC := Rect2(16, 284, 608, 42)
const HINT_Y := 340.0

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
			out.append({ "kind": "choice", "sec": "controls", "key": "transmission", "label": "GEARBOX", "opts": ["auto", "manual"], "desc": "AUTOMATIC, OR SHIFT IT YOURSELF. THE AUTO/MANUAL BUTTON SWITCHES IT ON THE ROAD TOO." })
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
			out.append({ "kind": "toggle", "sec": "ui", "key": "scan_tool", "label": "SCAN TOOL", "desc": "THE DIAGNOSTIC COMPUTER UNDER THE DASH: FAULT CODES, THE TIRES, THE WARNING LIGHTS." })
			out.append({ "kind": "choice", "sec": "ui", "key": "camera_zoom", "label": "CAMERA DISTANCE", "opts": [0.8, 0.9, 1.0, 1.1, 1.2], "desc": "FURTHER OUT SEES MORE ROAD; CLOSER IN SEES MORE CAR." })
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

const WIZ_STEPS := ["rest", "left", "right", "gas", "brake", "done"]
const WIZ_TEXT := {
	"rest": "HANDS OFF THE WHEEL, FEET OFF THE PEDALS. HOLD STILL...",
	"left": "TURN THE WHEEL ALL THE WAY LEFT AND HOLD IT. THEN ACCEPT.",
	"right": "NOW ALL THE WAY RIGHT AND HOLD IT. THEN ACCEPT.",
	"gas": "LET GO. PRESS THE GAS ALL THE WAY DOWN AND HOLD IT. THEN ACCEPT.",
	"brake": "LET GO OF THE GAS. PRESS THE BRAKE ALL THE WAY DOWN. THEN ACCEPT.",
	"done": "DONE. ACCEPT TO SAVE, AND DRIVE.",
}

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
	GameSettings.set_v("wheel", "name", Input.get_joy_name(d))
	GameSettings.set_v("wheel", "guid", Input.get_joy_guid(d))
	wiz = { "dev": d, "step": 0, "t": 0.0, "sum": [], "n": 0, "rest": [], "left": [], "right": [], "gas": [], "brake": [] }

static func _axes(d: int) -> Array:
	var out: Array = []
	for i in JOY_AXIS_MAX: out.append(Input.get_joy_axis(d, i as JoyAxis))
	return out

func _wizard(dt: float) -> void:
	var step: String = WIZ_STEPS[int(wiz.step)]
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		wiz = {}
		note = "CALIBRATION CANCELLED. NOTHING CHANGED."
		return
	var now := _axes(int(wiz.dev))
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
			wiz.step = 1
		return
	if not Input.is_action_just_pressed("ui_accept"): return
	if step == "done":
		var res := Wizard.solve(wiz.rest, wiz.left, wiz.right, wiz.gas, wiz.brake)
		for k in res: GameSettings.set_v("wheel", k, res[k])
		GameSettings.set_v("wheel", "enabled", true)
		_changed("wheel")
		wiz = {}
		note = "THE WHEEL'S SET UP. STEERING ON AXIS %d, GAS ON %d, BRAKE ON %d%s." % [int(res.steer_axis), int(res.gas_axis), int(res.brake_axis), " (ONE AXIS)" if res.combined else ""]
		return
	wiz[step] = now
	wiz.step = int(wiz.step) + 1

## Working the calibration out from what the axes read at each step (pure: the tests use it).
class Wizard:
	static func solve(rest: Array, left: Array, right: Array, gas: Array, brake: Array) -> Dictionary:
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
		return { "steer_axis": sa, "steer_center": float(rest[sa]), "steer_min": lo, "steer_max": hi,
			"steer_sign": 1.0 if float(right[sa]) > float(left[sa]) else -1.0,
			"gas_axis": ga, "gas_rest": float(rest[ga]), "gas_full": float(gas[ga]),
			"brake_axis": ba, "brake_rest": float(rest[ba]), "brake_full": float(brake[ba]),
			"combined": ga == ba }

# ------------------------------------------------------------------ drawing

## Where row i (counting from the top of the list) sits.
static func row_rect(i: int) -> Rect2:
	return Rect2(14, ROW_Y + i * ROW_H - 2, 612, ROW_H - 1)

func _draw() -> void:
	if not visible: return
	draw_rect(Rect2(0, 0, 640, 360), Color("0d0c10"))
	PixelFont.draw(self, Vector2(16, 6), "SETTINGS", GOLD, 2)
	var tx := 120.0
	for i in TABS.size():
		var w := PixelFont.width(TABS[i]) + 10
		var r := Rect2(tx, TAB_Y - 4, w, 12)
		draw_rect(r, Color(0.85, 0.64, 0.25, 0.22) if i == tab else Color(1, 1, 1, 0.05))
		PixelFont.draw(self, r.position + Vector2(5, 3), TABS[i], GOLD if i == tab else ASH)
		tx += w + 4
	var hint_tabs := Hints.fmt("{ui_tab_prev}/{ui_tab_next}: TABS")
	PixelFont.draw(self, Vector2(624 - PixelFont.width(hint_tabs), 6), hint_tabs, ASH)
	if not wiz.is_empty():
		_draw_wizard()
		return
	var rs := rows()
	if TABS[tab] == "CONTROLS" or TABS[tab] == "WHEEL":
		PixelFont.draw(self, Vector2(KEY_COL, ROW_Y - 10), "KEYBOARD" if TABS[tab] == "CONTROLS" else "", ASH)
		PixelFont.draw(self, Vector2(PAD_COL, ROW_Y - 10), "CONTROLLER / WHEEL" if TABS[tab] == "CONTROLS" else "", ASH)
	for i in range(scroll, mini(rs.size(), scroll + ROWS_VIS)):
		var r: Dictionary = rs[i]
		var rr := row_rect(i - scroll)
		var on := i == row
		if on: draw_rect(rr, Color(0.85, 0.64, 0.25, 0.16))
		var y := rr.position.y + 4
		PixelFont.draw(self, Vector2(LABEL_X, y), String(r.label), GOLD if on else BONE)
		if String(r.kind) == "bind":
			var bt := bind_texts(r)
			var cap := capturing == String(r.action)
			if not r.get("pad_only", false):
				var kc := BONE if not (on and col == 0) else GOLD
				PixelFont.draw(self, Vector2(KEY_COL, y), ("..." if cap and col == 0 else String(bt[0])).substr(0, 36), kc)
			var pc := BONE if not (on and (col == 1 or r.get("pad_only", false))) else GOLD
			PixelFont.draw(self, Vector2(PAD_COL, y), ("..." if cap and (col == 1 or r.get("pad_only", false)) else String(bt[1])).substr(0, 34), pc)
		elif String(r.kind) == "live":
			_draw_live(Vector2(KEY_COL, y))
		else:
			var v := value_text(r)
			if String(r.kind) in ["choice", "slider", "device"] and on: v = "< " + v + " >"
			PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(v), y), v, GOLD if on else BONE)
	if rs.size() > ROWS_VIS:
		var cnt := "%d/%d" % [row + 1, rs.size()]
		PixelFont.draw(self, Vector2(VALUE_R - PixelFont.width(cnt), ROW_Y - 10), cnt, ASH)
	# what the selected row does
	draw_rect(DESC, Color(1, 1, 1, 0.04))
	var desc := note if note != "" else String((rs[row] as Dictionary).get("desc", ""))
	var ls := Hud.wrap_lines(desc, 148)
	for k in mini(ls.size(), 4): PixelFont.draw(self, DESC.position + Vector2(6, 5 + k * 9), ls[k], ASH if note == "" else GOLD)
	var hint := Hints.fmt("{updown}: PICK  {leftright}: CHANGE  {ui_accept}: SELECT  {ui_cancel}: DONE")
	PixelFont.draw_centered(self, 320, HINT_Y, hint, ASH)

## The wheel as it reads right now: steering, gas, brake.
func _draw_live(p: Vector2) -> void:
	if not Wheel.active() and Wheel.device < 0:
		PixelFont.draw(self, p, "NO WHEEL", ASH)
		return
	var ins := Wheel.inputs(0.55) if Wheel.device >= 0 else [0.0, 0.0, 0.0, 0.0]
	var st: float = ins[2]
	draw_rect(Rect2(p.x, p.y, 80, 5), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(p.x + 40 + minf(st, 0.0) * 40, p.y, absf(st) * 40, 5), GOLD)
	draw_rect(Rect2(p.x + 100, p.y, 50, 5), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(p.x + 100, p.y, 50 * float(ins[0]), 5), GREEN)
	draw_rect(Rect2(p.x + 160, p.y, 50, 5), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(p.x + 160, p.y, 50 * float(ins[1]), 5), RED)

func _draw_wizard() -> void:
	var step: String = WIZ_STEPS[int(wiz.step)]
	PixelFont.draw(self, Vector2(20, 50), "CALIBRATING: " + Input.get_joy_name(int(wiz.dev)).to_upper().substr(0, 50), GOLD)
	for ln_i in Hud.wrap_lines(String(WIZ_TEXT[step]), 70).size():
		PixelFont.draw(self, Vector2(20, 70 + ln_i * 14), Hud.wrap_lines(String(WIZ_TEXT[step]), 70)[ln_i], BONE, 2)
	# every axis, live, so you can see which one is moving
	var now := _axes(int(wiz.dev))
	for i in now.size():
		var y := 130.0 + i * 13.0
		PixelFont.draw(self, Vector2(20, y), "AXIS %d" % i, ASH)
		draw_rect(Rect2(80, y, 200, 6), Color(1, 1, 1, 0.08))
		var v := float(now[i])
		draw_rect(Rect2(180 + minf(v, 0.0) * 100, y, absf(v) * 100, 6), GOLD)
		PixelFont.draw(self, Vector2(290, y), "%.2f" % v, BONE)
	PixelFont.draw_centered(self, 320, HINT_Y, Hints.fmt("{ui_accept}: NEXT  {ui_cancel}: CANCEL"), ASH)
