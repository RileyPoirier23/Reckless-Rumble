## The pause menu (ESC / START while driving): the game stops under it. Resume, the settings, the
## controls card, Employee of the Month, or back to the title (the game's saved first).
class_name PauseMenu
extends Control

signal quit_to_title

const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const INK := Color("0b090d")

const ITEMS := ["RESUME", "SETTINGS", "CONTROLS", "EMPLOYEE OF THE MONTH", "QUIT TO TITLE"]
const DESCS := {
	"RESUME": "BACK ON THE ROAD.",
	"SETTINGS": "CONTROLS, THE WHEEL, THE SCREEN, DIFFICULTY, GRAPHICS AND SOUND.",
	"CONTROLS": "WHAT EVERY BUTTON DOES. CHANGE THEM IN SETTINGS.",
	"EMPLOYEE OF THE MONTH": "THE WALL IN THE BREAK ROOM AT COVINGTON AUTO.",
	"QUIT TO TITLE": "THE GAME'S SAVED FIRST.",
}
const PANEL := Rect2(200, 70, 240, 150)
const CARD := Rect2(150, 40, 340, 270)

var sel := 0
var card := false              # the controls card is up
var settings: SettingsScreen
var wall: EmployeeWall
var _opened := -1               # the frame it opened on: the same press doesn't close it again
var _back := -1                 # the frame the settings closed on

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(640, 360)
	visible = false
	settings = SettingsScreen.new()
	settings.size = Vector2(640, 360)
	settings.visible = false
	settings.closed.connect(func(): _back = Engine.get_process_frames())
	add_child(settings)
	wall = EmployeeWall.new()
	wall.size = Vector2(640, 360)
	wall.visible = false
	wall.closed.connect(func(): _back = Engine.get_process_frames())
	add_child(wall)

func open() -> void:
	visible = true
	sel = 0
	card = false
	_opened = Engine.get_process_frames()
	get_parent().move_child(self, -1)          # over every panel the HUD layer has
	get_tree().paused = true

func close() -> void:
	visible = false
	settings.visible = false
	wall.visible = false
	get_tree().paused = false

func items() -> Array:
	return ITEMS.duplicate()

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	if settings.visible or wall.visible: return
	var f := Engine.get_process_frames()
	if f == _opened or f == _back: return
	if card:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pause"):
			card = false
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		close()
		return
	var n := ITEMS.size()
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % n
	if Input.is_action_just_pressed("ui_up"): sel = (sel + n - 1) % n
	if Input.is_action_just_pressed("ui_accept"): _pick(String(ITEMS[sel]))

func _pick(item: String) -> void:
	match item:
		"RESUME": close()
		"SETTINGS": settings.open()
		"CONTROLS": card = true
		"EMPLOYEE OF THE MONTH": wall.open()
		"QUIT TO TITLE":
			get_tree().paused = false
			visible = false
			quit_to_title.emit()

## The controls card: every driving action and what it's on, keyboard and controller.
static func card_lines() -> Array:
	var out: Array = []
	var was := Hints.pad
	for r in Controls.REBIND:
		Hints.pad = false
		var k := Hints.key(String(r[0]))
		Hints.pad = true
		var p := Hints.key(String(r[0]))
		out.append([String(r[1]), k if k != "" else "-", p if p != "" else "-"])
	Hints.pad = was
	return out

func _draw() -> void:
	if not visible or settings.visible or wall.visible: return
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.6))
	if card:
		_draw_card()
		return
	draw_rect(PANEL, Color(0.05, 0.05, 0.07, 0.95))
	draw_rect(PANEL, Color(GOLD, 0.7), false, 1.0)
	PixelFont.draw_centered(self, PANEL.get_center().x, PANEL.position.y + 8, "PAUSED", GOLD, 2)
	for i in ITEMS.size():
		var y := PANEL.position.y + 34 + i * 16
		var on := i == sel
		if on: draw_rect(Rect2(PANEL.position.x + 10, y - 3, PANEL.size.x - 20, 13), Color(0.85, 0.64, 0.25, 0.18))
		PixelFont.draw_centered(self, PANEL.get_center().x, y, String(ITEMS[i]), GOLD if on else BONE)
	var ls := Hud.wrap_lines(String(DESCS[ITEMS[sel]]), 56)
	for k in mini(ls.size(), 2):
		PixelFont.draw_centered(self, PANEL.get_center().x, PANEL.end.y - 24 + k * 9, ls[k], ASH)
	PixelFont.draw_centered(self, 320, 340, Hints.fmt("{updown}: PICK  {ui_accept}: SELECT  {pause}: RESUME"), ASH)

func _draw_card() -> void:
	draw_rect(CARD, Color(0.05, 0.05, 0.07, 0.96))
	draw_rect(CARD, Color(GOLD, 0.7), false, 1.0)
	PixelFont.draw(self, CARD.position + Vector2(10, 8), "CONTROLS", GOLD, 2)
	PixelFont.draw(self, CARD.position + Vector2(170, 12), "KEYBOARD", ASH)
	PixelFont.draw(self, CARD.position + Vector2(260, 12), "CONTROLLER", ASH)
	var ls := card_lines()
	for i in ls.size():
		var y := CARD.position.y + 28 + i * 12
		PixelFont.draw(self, Vector2(CARD.position.x + 10, y), String(ls[i][0]), BONE)
		PixelFont.draw(self, Vector2(CARD.position.x + 170, y), String(ls[i][1]).substr(0, 21), BONE)
		PixelFont.draw(self, Vector2(CARD.position.x + 260, y), String(ls[i][2]).substr(0, 19), BONE)
	PixelFont.draw_centered(self, 320, 340, Hints.fmt("{ui_cancel}: BACK"), ASH)
