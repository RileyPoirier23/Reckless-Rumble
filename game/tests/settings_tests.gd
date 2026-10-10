## Settings, rebinding, the wheel and the menus that show them:
##   godot --headless --path game -s tests/settings_tests.gd
## Works on a scratch settings file; never touches the player's.
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	_file()
	_difficulty()
	_bindings()
	_wheel()
	_wheel_only_drives()
	_keyboard()
	_steering()
	_police()
	_layout()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

# ------------------------------------------------------------------ the file

func _file() -> void:
	GameSettings.path = "user://settings_test.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.path))
	GameSettings.load_file()
	check("no file: the defaults", String(GameSettings.get_v("difficulty", "preset")) == "normal" and bool(GameSettings.get_v("ui", "scan_tool")))
	GameSettings.set_v("audio", "master", 0.4)
	GameSettings.set_v("ui", "messages", "important")
	GameSettings.set_v("wheel", "rotation", 540.0)
	GameSettings.set_v("graphics", "lights", 16)
	GameSettings.save_file()
	GameSettings.data = {}
	GameSettings.load_file()
	check("settings come back the way they were saved", is_equal_approx(float(GameSettings.get_v("audio", "master")), 0.4) and String(GameSettings.get_v("ui", "messages")) == "important"
		and is_equal_approx(float(GameSettings.get_v("wheel", "rotation")), 540.0) and int(GameSettings.get_v("graphics", "lights")) == 16)
	# a hand-edited file with a wrong type in it, and one that's garbage
	var cf := ConfigFile.new()
	cf.load(GameSettings.path)
	cf.set_value("ui", "scan_tool", "maybe")
	cf.set_value("audio", "master", 1)
	cf.save(GameSettings.path)
	GameSettings.load_file()
	check("a wrong type falls back to the default", bool(GameSettings.get_v("ui", "scan_tool")) == true and GameSettings.get_v("ui", "scan_tool") is bool)
	check("a whole number where a fraction goes is fine", is_equal_approx(float(GameSettings.get_v("audio", "master")), 1.0))
	var f := FileAccess.open(GameSettings.path, FileAccess.WRITE)
	f.store_string("[[[ this isn't a settings file }}}")
	f.close()
	GameSettings.load_file()
	check("a broken file loads the defaults", String(GameSettings.get_v("ui", "messages")) == "all" and int(GameSettings.get_v("graphics", "lights")) == 56)
	GameSettings.reset("audio")
	check("reset puts a tab back", is_equal_approx(float(GameSettings.get_v("audio", "master")), 1.0))
	check("an unknown key reads as nothing", GameSettings.get_v("ui", "nope") == null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.path))

# ------------------------------------------------------------------ difficulty

func _difficulty() -> void:
	GameSettings.set_v("difficulty", "preset", "hard")
	check("hard sets every knob", GameSettings.assist() == CarSim.Assist.SIM and GameSettings.police_strictness() > 1.0 and GameSettings.wildlife_rate() > 1.0)
	GameSettings.set_v("difficulty", "wildlife", "off")
	check("changing one knob makes it custom", String(GameSettings.get_v("difficulty", "preset")) == "custom" and GameSettings.wildlife_rate() == 0.0)
	GameSettings.set_v("difficulty", "assist", "arcade")
	GameSettings.set_v("difficulty", "police", "relaxed")
	GameSettings.set_v("difficulty", "wildlife", "rare")
	check("knobs that match a preset are that preset", String(GameSettings.get_v("difficulty", "preset")) == "easy", String(GameSettings.get_v("difficulty", "preset")))
	GameSettings.set_v("difficulty", "preset", "normal")
	check("normal is the street aids", GameSettings.assist() == CarSim.Assist.STREET and GameSettings.police_strictness() == 1.0)

# ------------------------------------------------------------------ rebinding

func _has_key(action: String, code: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and int((e as InputEventKey).physical_keycode) == code: return true
	return false

func _has_axis(action: String, axis: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion and int((e as InputEventJoypadMotion).axis) == axis: return true
	return false

func _bindings() -> void:
	GameSettings.data.bindings = {}
	Controls.setup()
	check("the defaults are bound", _has_key("throttle", KEY_W) and _has_axis("throttle", JOY_AXIS_TRIGGER_RIGHT) and _has_key("pause", KEY_ESCAPE))
	Controls.bind("throttle", "key", ["key", KEY_T, 0.0, -1])
	check("rebinding the keyboard swaps the keys", _has_key("throttle", KEY_T) and not _has_key("throttle", KEY_W) and not _has_key("throttle", KEY_UP))
	check("...and leaves the controller alone", _has_axis("throttle", JOY_AXIS_TRIGGER_RIGHT))
	Controls.bind("throttle", "pad", ["joyaxis", JOY_AXIS_RIGHT_Y, -1.0, -1])
	check("rebinding the controller leaves the keys alone", _has_key("throttle", KEY_T) and _has_axis("throttle", JOY_AXIS_RIGHT_Y) and not _has_axis("throttle", JOY_AXIS_TRIGGER_RIGHT))
	Controls.bind("horn", "key", [])
	check("a cleared column has nothing in it", not _has_key("horn", KEY_H))
	# what the settings screen shows for a binding
	check("binding names read right", Controls.label(["key", KEY_SPACE, 0.0, -1]) == "SPACE" and Controls.label(["joyaxis", JOY_AXIS_TRIGGER_LEFT, 1.0, -1]) == "LT"
		and Controls.label(["joybtn", JOY_BUTTON_A, 0.0, -1]) == "A" and Controls.label(["joybtn", 14, 0.0, 3]) == "WHEEL BTN 14", Controls.label(["joybtn", 14, 0.0, 3]))
	# pressing something to bind it
	var k := InputEventKey.new()
	k.physical_keycode = KEY_K
	k.pressed = true
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_X
	jb.pressed = true
	jb.device = 2
	var wiggle := InputEventJoypadMotion.new()
	wiggle.axis = JOY_AXIS_LEFT_X
	wiggle.axis_value = 0.3
	check("a key press binds", Controls.entry_of(k) == ["key", KEY_K, 0.0, -1])
	check("a pad button binds to any pad, a wheel's to the wheel", Controls.entry_of(jb) == ["joybtn", JOY_BUTTON_X, 0.0, -1] and Controls.entry_of(jb, 2) == ["joybtn", JOY_BUTTON_X, 0.0, 2])
	check("a stick barely moved doesn't bind", Controls.entry_of(wiggle).is_empty())
	# prompts follow a rebind
	Controls.bind("steer_left", "key", ["key", KEY_J, 0.0, -1])
	Hints.pad = false
	check("the prompts follow a rebind", Hints.key("steer") == "J/D" and Hints.key("throttle") == "T", Hints.key("steer"))
	# into the file and back
	GameSettings.path = "user://settings_test.cfg"
	GameSettings.save_file()
	GameSettings.load_file()
	Controls.apply_bindings()
	check("rebinds survive a restart", _has_key("throttle", KEY_T) and _has_key("steer_left", KEY_J) and not _has_key("horn", KEY_H))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.path))
	Controls.reset_bindings()
	check("put every button back", _has_key("throttle", KEY_W) and _has_key("horn", KEY_H) and Hints.key("steer") == "A/D")
	var every := true
	for r in Controls.REBIND:
		if not Controls.DEFAULTS.has(r[0]): every = false
	for g in Controls.GEARS:
		if not InputMap.has_action(g[0]): every = false
	check("everything on the rebind list is a real action", every)

# ------------------------------------------------------------------ the wheel

func _wheel() -> void:
	check("pedal at rest is 0", Wheel.pedal(-1.0, -1.0, 1.0) == 0.0)
	check("pedal floored is 1", Wheel.pedal(1.0, -1.0, 1.0) == 1.0)
	check("pedal halfway is about half", absf(Wheel.pedal(0.0, -1.0, 1.0) - 0.5) < 0.05, str(Wheel.pedal(0.0, -1.0, 1.0)))
	check("a pedal that runs backwards", Wheel.pedal(1.0, 1.0, -1.0) == 0.0 and Wheel.pedal(-1.0, 1.0, -1.0) == 1.0)
	check("a foot resting on the pedal does nothing", Wheel.pedal(-0.96, -1.0, 1.0, 0.03) == 0.0)
	check("a pedal that never moved reads 0", Wheel.pedal(0.4, 0.0, 0.0) == 0.0)
	check("centred is straight", Wheel.steer(0.0, 0.0, -1.0, 1.0, 1.0, 900.0, 0.0) == 0.0)
	# AUTO range: 32 degrees of lock at 14 to 1 is 882 degrees of rim, about the whole 900
	var auto_full := Wheel.steer(1.0, 0.0, -1.0, 1.0, 1.0, 900.0, 0.0, 1.0, 0.0, 0.55, 14.0)
	check("auto range: full rim is full lock", auto_full == 1.0, str(auto_full))
	var auto_half := Wheel.steer(0.5, 0.0, -1.0, 1.0, 1.0, 900.0, 0.0, 1.0, 0.0, 0.55, 14.0)
	check("auto range: half the rim is about half lock", absf(auto_half - 0.51) < 0.02, str(auto_half))
	var r450 := Wheel.steer(0.25, 0.0, -1.0, 1.0, 1.0, 900.0, 450.0)
	check("a 450-degree range: a quarter turn of a 900 wheel is half lock", absf(r450 - 0.5) < 0.01, str(r450))
	check("a 270-degree wheel never asks for more than it can turn", Wheel.steer(1.0, 0.0, -1.0, 1.0, 1.0, 270.0, 900.0) < 0.31)
	check("a reversed axis steers the right way", Wheel.steer(-1.0, 0.0, -1.0, 1.0, -1.0, 900.0, 0.0) > 0.99)
	check("an off-centre wheel centres where it rests", Wheel.steer(0.1, 0.1, -1.0, 1.0, 1.0, 900.0, 0.0) == 0.0)
	check("steering dead zone", Wheel.steer(0.03, 0.0, -1.0, 1.0, 1.0, 900.0, 900.0, 1.0, 0.05) == 0.0)
	# the calibration wizard: steering on axis 0, gas on 1 (resting at +1), brake on 2
	var rest := [0.02, 1.0, -1.0, 0.0]
	var left := [-0.98, 1.0, -1.0, 0.0]
	var right := [0.97, 1.0, -1.0, 0.0]
	var gas := [0.0, -1.0, -1.0, 0.0]
	var brk := [0.0, 1.0, 1.0, 0.0]
	var res: Dictionary = SettingsScreen.Wizard.solve(rest, left, right, gas, brk)
	check("the wizard finds the steering", int(res.steer_axis) == 0 and float(res.steer_sign) == 1.0 and absf(float(res.steer_center) - 0.02) < 0.001)
	check("the wizard finds the pedals", int(res.gas_axis) == 1 and float(res.gas_rest) == 1.0 and float(res.gas_full) == -1.0 and int(res.brake_axis) == 2 and not bool(res.combined))
	# both pedals on one axis (older wheels): gas one way, brake the other
	var one: Dictionary = SettingsScreen.Wizard.solve([0.0, 0.0], [-1.0, 0.0], [1.0, 0.0], [0.0, -1.0], [0.0, 1.0])
	check("pedals on one axis", bool(one.combined) and int(one.gas_axis) == 1)
	check("one axis: the gas reads", Wheel.pedal(-1.0, float(one.gas_rest), float(one.gas_full)) == 1.0 and Wheel.pedal(-1.0, float(one.brake_rest), float(one.brake_full)) == 0.0)
	check("nothing's plugged in: no wheel", not Wheel.active())

# ------------------------------------------------------------------ a wheel only drives

## Does any of this action's controller events listen to this device?
func _listens(action: String, dev: int) -> bool:
	for e in InputMap.action_get_events(action):
		if (e is InputEventJoypadButton or e is InputEventJoypadMotion) and (e.device == dev or e.device == -1): return true
	return false

func _wheel_only_drives() -> void:
	GameSettings.reset("wheel")
	Controls.reset_bindings()
	# a G29, an Xbox pad, and a pedal set on its own plug, never set up
	Wheel.test_pads = { 0: "Logitech G29 Driving Force Racing Wheel", 1: "Xbox Wireless Controller", 2: "Fanatec ClubSport Pedals V3" }
	Wheel.resolve()
	check("a wheel plugged in is found without setting it up", Wheel.device == 0 and Wheel.needs_setup() and not Wheel.active())
	check("the pad isn't taken for a wheel; the pedal set is part of the rig", Wheel.pads() == [1] and Wheel.devices() == [0, 2], "%s %s" % [Wheel.pads(), Wheel.devices()])
	check("a wheel known by its maker and model, a pedal set isn't a wheel", Wheel.wheel_name("USB Device", 0x046d, 0xc24f) and not Wheel.wheel_name("Fanatec ClubSport Pedals V3") and Wheel.wheel_name("Thrustmaster T300RS Racing wheel"))
	check("a pedal that hasn't said anything yet reads as resting, not halfway", Wheel.axis(-1, 2, -1.0) == -1.0)
	Controls.setup()
	var bad := ""
	for a in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "pause", "throttle", "brake", "steer_left", "horn", "ui_tab_next"]:
		if _listens(a, 0): bad += "%s hears the wheel; " % a
		if _listens(a, 2): bad += "%s hears the pedals; " % a
		if not _listens(a, 1): bad += "%s doesn't hear the pad; " % a
	check("the menus and the buttons listen to the pad, never the wheel", bad == "", bad)
	# the wheel's pedal resting at the end of its travel on the stick's axis doesn't scroll a menu
	var pedal := InputEventJoypadMotion.new()
	pedal.device = 0
	pedal.axis = JOY_AXIS_LEFT_Y
	pedal.axis_value = 1.0
	var stick := pedal.duplicate() as InputEventJoypadMotion
	stick.device = 1
	check("a pedal on the wheel never moves a menu; the pad's stick does", not InputMap.event_is_action(pedal, "ui_down") and InputMap.event_is_action(stick, "ui_down"))
	check("the stick and the rumble use the pad", Controls.active_pad() == 1)
	CounterScene.setup_actions()
	check("the counter's desk buttons hear the pad, not the wheel", _listens("desk_click", 1) and not _listens("desk_click", 0))
	# a button on the wheel binds to the wheel, and keeps the pad's button beside it
	var paddle := InputEventJoypadButton.new()
	paddle.device = 0
	paddle.button_index = 4 as JoyButton
	paddle.pressed = true
	var en := Controls.entry_of(paddle)
	check("a wheel button binds to the wheel", int(en[3]) >= 0 and Controls.label(en) == "WHEEL BTN 4", str(en))
	Controls.bind("shift_up", "pad", en)
	var paddle_on := false
	for e in InputMap.action_get_events("shift_up"):
		if e is InputEventJoypadButton and e.device == 0 and (e as InputEventJoypadButton).button_index == 4: paddle_on = true
	check("the paddle shifts up and RB still does", paddle_on and _listens("shift_up", 1))
	# calibrated: it drives
	GameSettings.set_v("wheel", "name", "Logitech G29 Driving Force Racing Wheel")
	GameSettings.set_v("wheel", "enabled", true)
	Wheel.resolve()
	check("set up, it drives (and stops asking)", Wheel.active() and not Wheel.needs_setup())
	# no wheel: a controller binding listens to any controller again
	Wheel.test_pads = { 1: "Xbox Wireless Controller" }
	Wheel.resolve()
	Controls.apply_bindings()
	check("unplugged: no wheel, any pad works", Wheel.device == -1 and not Wheel.active() and _listens("ui_down", 5))
	Wheel.test_pads = {}
	Wheel.resolve()
	GameSettings.reset("wheel")
	Controls.reset_bindings()
	Controls.apply_bindings()
	# the mouse pointer
	var img := Cursor.image(Cursor.ARROW, 2)
	check("the pointer is drawn at the window's scale", img.get_width() == 24 and img.get_height() == 36 and img.get_pixel(0, 0).is_equal_approx(Cursor.INK) and img.get_pixel(23, 35).a == 0.0)
	check("pointer scale follows the window", Cursor.scale_for(Vector2i(1280, 720)) == 2 and Cursor.scale_for(Vector2i(1920, 1080)) == 3 and Cursor.scale_for(Vector2i(800, 600)) == 1)
	var ok := true
	for sh in [Cursor.ARROW, Cursor.POINT, Cursor.GRAB]:
		for r in sh:
			for ch in String(r):
				if not ch in ["X", "O", "G", "S", "."]: ok = false
	check("the pointers are only made of the palette", ok)
	# the wizard's words fit
	var wbad := ""
	for st in SettingsScreen.WIZ_STEPS:
		if Hud.wrap_lines(SettingsScreen.wiz_text(String(st)), 70).size() > 4: wbad += "%s runs long; " % st
	check("the wheel set-up's words fit", wbad == "", wbad)

# ------------------------------------------------------------------ the keyboard

func _keyboard() -> void:
	GameSettings.reset("controls")
	Hints.pad = false
	Controls._kb = [0.0, 0.0, 0.0]
	Input.action_press("throttle")
	var a: Array = Controls.drive_inputs(0.1)
	var b: Array = []
	for i in 3: b = Controls.drive_inputs(0.1)
	check("the gas key eases in", float(a[0]) > 0.3 and float(a[0]) < 0.5 and float(b[0]) == 1.0, "%.2f then %.2f" % [float(a[0]), float(b[0])])
	Input.action_release("throttle")
	var c: Array = Controls.drive_inputs(0.05)
	check("...and lets off quicker", float(c[0]) < 0.65 and float(c[0]) > 0.5, "%.2f" % float(c[0]))
	Input.action_press("steer_right")
	var s1: Array = Controls.drive_inputs(0.1)
	check("steering keys ease in", float(s1[2]) > 0.3 and float(s1[2]) < 0.4, "%.2f" % float(s1[2]))
	Input.action_release("steer_right")
	Input.action_press("steer_left")
	var s2: Array = Controls.drive_inputs(0.1)
	check("the other way comes back through the middle quickly", float(s2[2]) < -0.3, "%.2f" % float(s2[2]))
	Input.action_release("steer_left")
	GameSettings.set_v("controls", "kb_ramp", false)
	Input.action_press("brake")
	var d: Array = Controls.drive_inputs(0.016)
	check("with easing off, a key is all or nothing", float(d[1]) == 1.0)
	Input.action_release("brake")
	GameSettings.reset("controls")
	check("no controller: the triggers read 0", Controls.trigger("throttle") == 0.0)

# ------------------------------------------------------------------ the car on a wheel

func _steering() -> void:
	var spec: Dictionary = SaveGame.load_spec("silvio")
	var c := CarSim.new(spec)
	c.set_ambient(20.0)
	c.direct_steer = true
	for i in 10: c.step(1.0 / 60.0, 0.0, 0.0, 0.5, 0.0)
	check("on a wheel the road wheels follow the rim", absf(c.steer - 0.5 * float(spec.steer_lock)) < 0.01, "%.3f vs %.3f" % [c.steer, 0.5 * float(spec.steer_lock)])
	var p := CarSim.new(spec)
	p.set_ambient(20.0)
	for i in 10: p.step(1.0 / 60.0, 0.0, 0.0, 0.5, 0.0)
	check("on a pad the steering takes its time", absf(p.steer) < absf(c.steer))

# ------------------------------------------------------------------ difficulty in the world

func _police() -> void:
	var pol := Police.new()
	pol.strictness = 1.5
	var strict := [pol.over_kmh(), pol.stop_s(), pol.lose_s()]
	pol.strictness = 0.6
	check("strict police let less slide and wait less", float(strict[0]) < pol.over_kmh() and float(strict[1]) < pol.stop_s() and float(strict[2]) > pol.lose_s())
	pol.free()
	var w := Wildlife.new()
	check("wildlife starts at the normal rate", w.rate == 1.0)
	w.free()

# ------------------------------------------------------------------ nothing overlaps

func _layout() -> void:
	var sc := SettingsScreen.new()
	var bad := ""
	var tabs_end := 120.0
	for t in SettingsScreen.TABS: tabs_end += PixelFont.width(t) + 14
	check("the tabs fit across the top", tabs_end <= 624.0 - PixelFont.width("LB/RB: TABS") - 8, "%d" % int(tabs_end))
	check("the rows stop above the description", SettingsScreen.row_rect(SettingsScreen.ROWS_VIS - 1).end.y <= SettingsScreen.DESC.position.y)
	check("the column headings sit under the tabs", SettingsScreen.ROW_Y - 10 >= SettingsScreen.TAB_Y + 9 and SettingsScreen.row_rect(0).position.y >= SettingsScreen.ROW_Y - 10 + 6)
	check("the description's four lines fit its box", 5 + 3 * 9 + 5 <= SettingsScreen.DESC.size.y and SettingsScreen.DESC.end.y < SettingsScreen.HINT_Y)
	for ti in SettingsScreen.TABS.size():
		sc.tab = ti
		var rs := sc.rows()
		for r in rs:
			var lw := SettingsScreen.LABEL_X + PixelFont.width(String(r.label))
			var desc := Hud.wrap_lines(String(r.get("desc", "")), 148)
			if desc.size() > 4: bad += "%s: description runs over; " % r.label
			match String(r.kind):
				"bind":
					var x := SettingsScreen.PAD_COL if r.get("pad_only", false) else SettingsScreen.KEY_COL
					if lw + 6 > x: bad += "%s: label hits the buttons; " % r.label
				"choice":
					for o in r.opts:
						GameSettings.set_v(String(r.sec), String(r.key), o)
						var v := "< " + sc.value_text(r) + " >"
						if lw + 8 > SettingsScreen.VALUE_R - PixelFont.width(v): bad += "%s=%s collides; " % [r.label, v]
					GameSettings.reset(String(r.sec))
					GameSettings.set_v("difficulty", "preset", "normal")
				"live":
					if lw + 6 > SettingsScreen.KEY_COL: bad += "%s: label hits the readout; " % r.label
				_:
					var v := "< " + sc.value_text(r) + " >"
					if lw + 8 > SettingsScreen.VALUE_R - PixelFont.width(v): bad += "%s collides; " % r.label
	# a long wheel name
	GameSettings.set_v("wheel", "name", "Logitech G923 Racing Wheel for PlayStation and PC (USB)")
	sc.tab = 1
	var dv := "< " + sc.value_text(sc.rows()[0]) + " >"
	if SettingsScreen.LABEL_X + PixelFont.width("WHEEL") + 8 > SettingsScreen.VALUE_R - PixelFont.width(dv): bad += "a long wheel name collides; "
	GameSettings.reset("wheel")
	# the longest binding text in each column, cut where the screen cuts it
	if PixelFont.width("X".repeat(36)) > SettingsScreen.PAD_COL - SettingsScreen.KEY_COL - 4: bad += "the keyboard column runs into the controller one; "
	if SettingsScreen.PAD_COL + PixelFont.width("X".repeat(34)) > 636: bad += "the controller column runs off the screen; "
	check("no setting's text runs into another", bad == "", bad)
	sc.free()
	var hint := Hints.fmt("{updown}: PICK  {leftright}: CHANGE  {ui_accept}: SELECT  {ui_cancel}: DONE")
	check("the key hints fit", PixelFont.width(hint) < 600, "%d" % PixelFont.width(hint))
	# the pause menu and its controls card
	var pm_bad := ""
	for it in PauseMenu.ITEMS:
		if PixelFont.width(String(it)) > PauseMenu.PANEL.size.x - 24: pm_bad += "%s too wide; " % it
		if Hud.wrap_lines(String(PauseMenu.DESCS[it]), 56).size() > 2: pm_bad += "%s description runs over; " % it
	if Hud.wrap_lines(String(PauseMenu.DESCS["SET UP THE WHEEL"]), 56).size() > 2: pm_bad += "the wheel's set-up description runs over; "
	var last_item_y := PauseMenu.PANEL.position.y + 34 + PauseMenu.ITEMS.size() * 16 + 8      # one more with a wheel to set up
	if last_item_y > PauseMenu.PANEL.end.y - 24: pm_bad += "the items run into the description; "
	var ls := PauseMenu.card_lines()
	if PauseMenu.CARD.position.y + 28 + ls.size() * 12 > PauseMenu.CARD.end.y: pm_bad += "the card runs off its panel; "
	for l in ls:
		if PixelFont.width(String(l[0])) > 156: pm_bad += "%s hits the keys; " % l[0]
		if PixelFont.width(String(l[1]).substr(0, 21)) > 86: pm_bad += "%s keys hit the pad column; " % l[0]
		if PauseMenu.CARD.position.x + 260 + PixelFont.width(String(l[2]).substr(0, 19)) > PauseMenu.CARD.end.x - 2: pm_bad += "%s pad runs off; " % l[0]
	check("the pause menu and controls card fit", pm_bad == "", pm_bad)
