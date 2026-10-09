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
	if StoryState.has_save():
		ITEMS.append(["CONTINUE THE STORY", "PICK UP WHERE LEO LEFT OFF.", "story:continue"])
	ITEMS.append(["NEW STORY", "OCTOBER 2019. LEO IS 19, DRUNK, AND ABOUT TO DRIVE THROUGH A FENCE.", "story:new"])
	ITEMS.append(["THE COUNTER", "EIGHT WEEKS OF SHIFTS AT COVINGTON AUTO. READ THE PAPERS. STAMP THEM.", "res://counter.tscn"])
	ITEMS.append(["THE LOT", "FREE DRIVE: PORT RUMBLE TO SALISBURY AND HAVELOCK, WITH TRAFFIC.", "res://drive.tscn"])
	ITEMS.append(["QUIT", "", ""])

var sel := 0
var car: CarView
var t := 0.0

func _ready() -> void:
	Controls.setup()
	_items()
	var args := OS.get_cmdline_user_args()
	if args.has("--demo") or args.has("--world-demo") or args.has("--traffic-test") or args.has("--traffic-demo") or args.has("--crash-demo") or args.has("--veg-demo") or args.has("--jobs-demo") or args.has("--market-demo") or args.has("--race-test") or args.has("--race-demo") or args.has("--fuel-demo") or args.has("--wild-demo"):
		get_tree().change_scene_to_file.call_deferred("res://drive.tscn")
		return
	if args.has("--counter-demo"):
		get_tree().change_scene_to_file.call_deferred("res://counter.tscn")
		return
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	car = CarView.new()
	car.art = CarArt.new(spec, Color(spec.paint))
	car.position = Vector2(320, 150)
	car.headlights = true
	car.scale = Vector2(2, 2)
	add_child(car)
	if args.has("--title-shot"):
		await get_tree().create_timer(0.6).timeout
		var a := args.find("--title-shot")
		get_viewport().get_texture().get_image().save_png(args[a + 1] if a + 1 < args.size() else "user://title.png")
		get_tree().quit()

func _item_rect(i: int) -> Rect2:
	return Rect2(150, 186 + i * 30, 340, 28)

func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		for i in ITEMS.size():
			if _item_rect(i).has_point(get_global_mouse_position()): sel = i
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in ITEMS.size():
			if _item_rect(i).has_point(get_global_mouse_position()):
				sel = i
				_go()

func _process(dt: float) -> void:
	t += dt
	if car: car.heading = t * 0.5
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % ITEMS.size()
	if Input.is_action_just_pressed("ui_up"): sel = (sel + ITEMS.size() - 1) % ITEMS.size()
	if Input.is_action_just_pressed("ui_accept"): _go()
	queue_redraw()

func _go() -> void:
	var target: String = ITEMS[sel][2]
	match target:
		"": get_tree().quit()
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
	draw_rect(Rect2(0, 0, 640, 360), Color("15131a"))
	# the harbour at night: water, cranes, the lighthouse sweeping
	draw_rect(Rect2(0, 110, 640, 90), Color("1a2230"))
	for i in 40:
		var x := fmod(i * 53.0 + t * 6.0, 660.0) - 10.0
		draw_rect(Rect2(x, 120 + (i * 7) % 70, 8 + i % 5 * 3, 1), Color(0.5, 0.6, 0.8, 0.18))
	for cx in [70, 150, 520]:
		draw_rect(Rect2(cx, 40, 4, 70), Color("2a2a34"))
		draw_rect(Rect2(cx - 30, 40, 70, 4), Color("2a2a34"))
		draw_rect(Rect2(cx + 34, 44, 1, 30), Color("2a2a34"))
		draw_rect(Rect2(cx - 1, 36, 2, 2), RED if int(t * 2) % 2 == 0 else Color("401010"))
	draw_rect(Rect2(600, 60, 10, 50), Color("d8d0c0"))
	draw_rect(Rect2(598, 54, 14, 8), Color("2a2a34"))
	var beam := t * 0.9
	draw_colored_polygon(PackedVector2Array([Vector2(605, 58), Vector2(605 + cos(beam) * 400, 58 + sin(beam) * 30 - 20), Vector2(605 + cos(beam) * 400, 58 + sin(beam) * 30 + 20)]), Color(1, 0.95, 0.7, 0.07))
	draw_rect(Rect2(0, 200, 640, 160), Color("1e1c22"))
	# the logo
	PixelFont.draw_centered(self, 320, 16, "DRIVEBOSS", GOLD, 8, INK)
	PixelFont.draw_centered(self, 320, 62, "PORT RUMBLE. EIGHT WINTERS. ONE GARAGE.", BONE, 2, INK)
	for i in ITEMS.size():
		var r := _item_rect(i)
		var on := i == sel
		draw_rect(r, Color(0.85, 0.64, 0.25, 0.18) if on else Color(1, 1, 1, 0.04))
		if on: draw_rect(r, GOLD, false, 1.0)
		PixelFont.draw(self, r.position + Vector2(10, 5), ("> " if on else "  ") + ITEMS[i][0], GOLD if on else BONE, 2)
		PixelFont.draw(self, r.position + Vector2(26, 20), ITEMS[i][1], ASH)
	PixelFont.draw(self, Vector2(8, 350), "PROTOTYPE 0.2", ASH)
	var hint := Hints.fmt("{updown}: PICK  {ui_accept}: GO")
	PixelFont.draw(self, Vector2(632 - PixelFont.width(hint), 350), hint, ASH)
