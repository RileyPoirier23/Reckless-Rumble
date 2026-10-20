## Title screen: pick the counter or the lot.
extends Node2D

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")

var ITEMS: Array = []

func _items() -> void:
	ITEMS = []
	if DemoBuild.on():
		if DemoBuild.saved_step() > 0 and DemoBuild.saved_step() < DemoBuild.end_step():
			ITEMS.append(["CONTINUE THE PROLOGUE", "PICK UP WHERE LEO LEFT OFF.", "story:continue"])
		if Wheel.needs_setup():
			ITEMS.append(["SET UP YOUR WHEEL", "FOUND: %s. TWENTY SECONDS: TURN IT, PRESS THE PEDALS, AND IT DRIVES." % Input.get_joy_name(Wheel.device).to_upper().substr(0, 32), "wheel_setup"])
		ITEMS.append(["PLAY THE PROLOGUE", "OCTOBER 2019. LEO IS 19, DRUNK, AND ABOUT TO DRIVE THROUGH A FENCE. THEN HIS FIRST DAY AT THE COUNTER.", "story:new"])
		ITEMS.append(["SETTINGS", "CONTROLS AND REBINDING, A STEERING WHEEL, THE SCREEN, DIFFICULTY, GRAPHICS AND SOUND.", "settings"])
		ITEMS.append(["CREDITS", "WHO MADE IT, WHO'S IN IT, AND WHO IT'S FOR.", "credits"])
		ITEMS.append(["QUIT", "SEE YOU TOMORROW.", ""])
		return
	if Wheel.needs_setup():
		ITEMS.append(["SET UP YOUR WHEEL", "FOUND: %s. TWENTY SECONDS: TURN IT, PRESS THE PEDALS, AND IT DRIVES. IT ONLY DRIVES: THE MENUS STAY ON THE KEYBOARD, MOUSE AND CONTROLLER." % Input.get_joy_name(Wheel.device).to_upper().substr(0, 32), "wheel_setup"])
	if StoryState.has_save():
		ITEMS.append(["CONTINUE THE STORY", "PICK UP WHERE LEO LEFT OFF.", "story:continue"])
	ITEMS.append(["NEW STORY", "OCTOBER 2019. LEO IS 19, DRUNK, AND ABOUT TO DRIVE THROUGH A FENCE.", "story:new"])
	ITEMS.append(["THE COUNTER", "EIGHT WEEKS AT COVINGTON AUTO, THEN OVERTIME. READ THE PAPERS. STAMP THEM.", "res://counter.tscn"])
	ITEMS.append(["THE LOT", "FREE DRIVE: PORT RUMBLE TO SALISBURY AND HAVELOCK, WITH TRAFFIC.", "res://drive.tscn"])
	ITEMS.append(["EMPLOYEE OF THE MONTH", "THE WALL IN THE BREAK ROOM AT COVINGTON AUTO: A PHOTO FOR EVERYTHING YOU'VE DONE ON THE ROAD.", "wall"])
	ITEMS.append(["SETTINGS", "CONTROLS AND REBINDING, A STEERING WHEEL, THE SCREEN, DIFFICULTY, GRAPHICS AND SOUND.", "settings"])
	ITEMS.append(["CREDITS", "WHO MADE IT, WHO'S IN IT, AND WHO IT'S FOR.", "credits"])
	ITEMS.append(["QUIT", "SEE YOU TOMORROW.", ""])

var sel := 0
var car: CarView
var t := 0.0
var settings: SettingsScreen
var wall: EmployeeWall

func _ready() -> void:
	Controls.setup()
	_items()
	var args := OS.get_cmdline_user_args()
	if args.has("--demo") or args.has("--world-demo") or args.has("--traffic-test") or args.has("--traffic-demo") or args.has("--crash-demo") or args.has("--veg-demo") or args.has("--jobs-demo") or args.has("--market-demo") or args.has("--race-test") or args.has("--mission-test") or args.has("--lights-shot") or args.has("--perf-probe") or args.has("--collide-audit") or args.has("--preview-frames") or args.has("--tour-demo") or args.has("--race-demo") or args.has("--fuel-demo") or args.has("--wild-demo") or args.has("--sight-demo") or args.has("--incident-demo") or args.has("--salvage-demo") or args.has("--meet-demo") or args.has("--auction-demo") or args.has("--pause-demo") or args.has("--furniture-demo") or args.has("--crew-demo"):
		get_tree().change_scene_to_file.call_deferred("res://drive.tscn")
		return
	if args.has("--counter-demo"):
		get_tree().change_scene_to_file.call_deferred("res://counter.tscn")
		return
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	car = CarView.new()
	car.art = CarArt.new(spec, Color(spec.paint))
	car.position = TURNTABLE
	car.headlights = true
	car.scale = Vector2(2, 2)
	add_child(car)
	settings = SettingsScreen.new()
	settings.size = Vector2(640, 360)
	settings.visible = false
	add_child(settings)
	wall = EmployeeWall.new()
	wall.size = Vector2(640, 360)
	wall.visible = false
	add_child(wall)
	if args.has("--settings-shot"):
		# every tab of the settings screen, one picture each, into the folder given
		var dir: String = args[args.find("--settings-shot") + 1] if args.find("--settings-shot") + 1 < args.size() else "user://"
		settings.open()
		for ti in SettingsScreen.TABS.size():
			settings.tab = ti
			settings.row = 2 if ti == 0 else 0
			await get_tree().create_timer(0.25).timeout
			get_viewport().get_texture().get_image().save_png("%s/settings_%d.png" % [dir, ti])
		settings.tab = 0
		settings.row = 24
		settings.scroll = 24 - SettingsScreen.ROWS_VIS + 1
		await get_tree().create_timer(0.25).timeout
		get_viewport().get_texture().get_image().save_png("%s/settings_scroll.png" % dir)
		# the wheel's calibration, as it looks part way through (no wheel needed: nothing reads)
		settings.tab = 1
		settings.wiz = { "dev": -1, "devs": [-1], "step": 3, "t": 0.0, "sum": [], "n": 0, "rest": [], "left": [], "right": [], "gas": [], "brake": [], "clutch": [],
			"held": [], "up": -1, "down": -1, "rig_held": {}, "gears": {} }
		await get_tree().create_timer(0.25).timeout
		get_viewport().get_texture().get_image().save_png("%s/settings_wizard.png" % dir)
		get_tree().quit()
		return
	if args.has("--title-shot"):
		await get_tree().create_timer(0.6).timeout
		var a := args.find("--title-shot")
		get_viewport().get_texture().get_image().save_png(args[a + 1] if a + 1 < args.size() else "user://title.png")
		get_tree().quit()

## The menu down the left in its panel, the car turning on the quay on the right, what the picked
## item does underneath, the version and the keys along the very bottom.
const ITEM_Y := 100.0
const ITEM_PITCH := 18.0
const MENU_W := 232.0
const DESC := Rect2(24, 298, 592, 34)
const TURNTABLE := Vector2(470, 236)

## Item i's box. The items close up when there are more of them, so the last never reaches the
## description box.
func _item_rect(i: int) -> Rect2:
	var pitch := minf(ITEM_PITCH, floorf((DESC.position.y - 14.0 - ITEM_Y) / maxf(ITEMS.size(), 1)))
	return Rect2(32, ITEM_Y + i * pitch, MENU_W - 16, minf(15.0, pitch - 2.0))

func _input(e: InputEvent) -> void:
	if (settings and settings.visible) or (wall and wall.visible): return
	if e is InputEventMouseMotion:
		for i in ITEMS.size():
			if _item_rect(i).has_point(get_global_mouse_position()): sel = i
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in ITEMS.size():
			if _item_rect(i).has_point(get_global_mouse_position()):
				sel = i
				_go()

var _wheel_offer := false

func _process(dt: float) -> void:
	t += dt
	if Wheel.needs_setup() != _wheel_offer:
		_wheel_offer = Wheel.needs_setup()
		var was: String = ITEMS[sel][2] if sel < ITEMS.size() else ""
		_items()
		sel = 0
		for i in ITEMS.size():
			if ITEMS[i][2] == was: sel = i
	if car: car.heading = t * 0.5
	if (settings and settings.visible) or (wall and wall.visible):
		queue_redraw()
		return
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % ITEMS.size()
	if Input.is_action_just_pressed("ui_up"): sel = (sel + ITEMS.size() - 1) % ITEMS.size()
	if Input.is_action_just_pressed("ui_accept"): _go()
	queue_redraw()

func _go() -> void:
	var target: String = ITEMS[sel][2]
	match target:
		"": get_tree().quit()
		"settings": settings.open()
		"wheel_setup": settings.open_wheel()
		"wall": wall.open()
		"credits":
			EndCredits.from_menu = true
			get_tree().change_scene_to_file("res://ui/credits.tscn")
		"story:continue":
			StoryState.load_game()
			StoryState.go(get_tree())
		"story:new":
			StoryState.new_game()
			StoryState.go(get_tree())
		_:
			StoryState.active = false
			LoadingScreen.go(get_tree(), target, "THE LOT" if target.contains("drive") else ("THE COUNTER" if target.contains("counter") else ""))


func _draw() -> void:
	_draw_harbour()
	# the logo: the name on a hard shadow, the line under it between two rules
	PixelFont.draw_centered(self, 320, 19, "DRIVEBOSS", Color("3a2610"), 8)
	PixelFont.draw_centered(self, 320, 16, "DRIVEBOSS", GOLD, 8)
	var tag: String = "THE PROLOGUE: A DEMO" if DemoBuild.on() else "PORT RUMBLE. EIGHT WINTERS. ONE GARAGE."
	var tw := PixelFont.width(tag, 2)
	PixelFont.draw_centered(self, 320, 66, tag, BONE, 2, INK)
	draw_rect(Rect2(320 - tw / 2.0 - 46, 70, 36, 1), Color(GOLD, 0.7))
	draw_rect(Rect2(320 + tw / 2.0 + 10, 70, 36, 1), Color(GOLD, 0.7))
	if (settings and settings.visible) or (wall and wall.visible): return
	# the menu, in its panel
	var first := _item_rect(0)
	var last := _item_rect(ITEMS.size() - 1)
	UiKit.panel(self, Rect2(24, first.position.y - 8, MENU_W, last.end.y - first.position.y + 16), "", GOLD, 1.0, Color(UiKit.FILL, 0.88))
	for i in ITEMS.size():
		var r := _item_rect(i)
		var on := i == sel
		if on: UiKit.select(self, r)
		var ty := r.position.y + floorf((r.size.y - 9.0) / 2.0)
		if on: PixelFont.draw(self, Vector2(r.position.x + 7, ty), "▶", GOLD, 2)
		var col := GOLD if on else (BONE if String(ITEMS[i][2]) != "" else Color(BONE, 0.7))
		PixelFont.draw(self, Vector2(r.position.x + 18, ty), String(ITEMS[i][0]), col, 2)
	# what the picked one does
	UiKit.panel(self, DESC, "", GOLD, 1.0, Color(UiKit.FILL, 0.88))
	var ls := UiKit.wrap(String(ITEMS[sel][1]), DESC.size.x - 2 * UiKit.PAD)
	for k in mini(ls.size(), 2):
		PixelFont.draw(self, DESC.position + Vector2(UiKit.PAD, 7 + k * UiKit.LINE_H), ls[k], Color(BONE, 0.85), 2)
	PixelFont.draw(self, Vector2(8, 350), "IN DEVELOPMENT 0.3  506 CLICKS", ASH)
	var hint := Hints.fmt("{updown}: PICK  {ui_accept}: GO")
	UiKit.hints(self, 632 - UiKit.hints_width(hint) / 2.0, 347, hint)

## The harbour at night behind it all: the sky, the far shore's lights, the water with the cranes'
## lamps in it, the lighthouse sweeping, and the quay in front with the car turning on its plate.
func _draw_harbour() -> void:
	# the sky, darkest at the top
	for k in 12:
		draw_rect(Rect2(0, k * 10, 640, 10), Color("0c0b12").lerp(Color("1d1c2c"), k / 11.0))
	for k in 28:
		var sx := float((k * 211) % 640)
		var sy := float((k * 97) % 84) + 4.0
		draw_rect(Rect2(sx, sy, 1, 1), Color(BONE, 0.25 + 0.2 * sin(t * 1.3 + k)))
	# the far shore: low hills and a few lit windows
	var hill := PackedVector2Array([Vector2(0, 120)])
	for k in 17: hill.append(Vector2(k * 40.0, 108.0 + 6.0 * sin(k * 1.7) + 3.0 * sin(k * 0.6)))
	hill.append(Vector2(640, 120))
	draw_colored_polygon(hill, Color("15141c"))
	for k in 22:
		draw_rect(Rect2((k * 137) % 620 + 10, 112 + (k * 5) % 6, 2, 1), Color(GOLD, 0.35 + 0.15 * float(k % 3)))
	# the water, with streaks drifting
	draw_rect(Rect2(0, 120, 640, 56), Color("161d2a"))
	for i in 36:
		var x := fmod(i * 53.0 + t * 6.0, 660.0) - 10.0
		draw_rect(Rect2(x, 124 + (i * 7) % 50, 8 + i % 5 * 3, 1), Color(0.5, 0.6, 0.8, 0.14))
	# the cranes on the far quay, their lamps blinking and shaking in the water
	for cx in [40, 112, 520]:
		var crane := Color("26252f")
		draw_rect(Rect2(cx, 44, 4, 76), crane)
		draw_rect(Rect2(cx - 30, 44, 72, 4), crane)
		draw_rect(Rect2(cx + 34, 48, 1, 30), crane)
		draw_rect(Rect2(cx + 31, 78, 7, 4), crane)
		var lamp := RED if int(t * 2) % 2 == 0 else Color("401010")
		draw_rect(Rect2(cx + 1, 40, 2, 2), lamp)
		for k in 3: draw_rect(Rect2(cx - 1 + sin(t * 3.0 + k) * 1.5, 132 + k * 9, 4, 1), Color(lamp, 0.35 - k * 0.1))
	# the lighthouse on the point and its beam
	draw_rect(Rect2(604, 64, 10, 56), Color("d8d0c0"))
	draw_rect(Rect2(604, 80, 10, 4), RED.darkened(0.3))
	draw_rect(Rect2(602, 58, 14, 8), Color("26252f"))
	draw_rect(Rect2(606, 60, 6, 4), Color(1, 0.95, 0.7, 0.9))
	var beam := t * 0.9
	draw_colored_polygon(PackedVector2Array([Vector2(609, 62), Vector2(609 + cos(beam) * 400, 62 + sin(beam) * 30 - 20), Vector2(609 + cos(beam) * 400, 62 + sin(beam) * 30 + 20)]), Color(1, 0.95, 0.7, 0.07))
	# the quay: its edge, the bollards, the asphalt and its painted bays
	draw_rect(Rect2(0, 176, 640, 184), Color("1c1a21"))
	draw_rect(Rect2(0, 176, 640, 3), Color("34313b"))
	for bx in range(20, 640, 72): draw_rect(Rect2(bx, 172, 5, 5), Color("2c2a33"))
	for k in 9: draw_rect(Rect2(300 + k * 40, 188, 1, 30), Color(BONE, 0.06))
	# the turntable: a plate with a ring, a pool of light on it
	var c := TURNTABLE
	for k in 5:
		_ellipse(c, 92.0 - k * 10.0, Color(GOLD, 0.025 + k * 0.012))
	_ellipse(c, 62.0, Color("26232c"))
	_ellipse_line(c, 62.0, Color(BONE, 0.18))
	_ellipse_line(c, 50.0, Color(BONE, 0.07))

const _SQUASH := 0.55             # the turntable seen at the same tilt as the car

func _ellipse(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 40: pts.append(c + Vector2(cos(k * TAU / 40.0) * r, sin(k * TAU / 40.0) * r * _SQUASH))
	draw_colored_polygon(pts, col)

func _ellipse_line(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 41: pts.append(c + Vector2(cos(k * TAU / 40.0) * r, sin(k * TAU / 40.0) * r * _SQUASH))
	draw_polyline(pts, col, 1.0)
