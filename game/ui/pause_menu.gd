## The pause menu (ESC / START while driving): the game stops under it. Resume, the settings, the
## controls card, Employee of the Month, or back to the title (the game's saved first).
class_name PauseMenu
extends Control

signal quit_to_title

const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const INK := Color("0b090d")

const ITEMS := ["RESUME", "HOW IT WORKS", "SETTINGS", "CONTROLS", "EMPLOYEE OF THE MONTH", "QUIT TO TITLE"]
const DESCS := {
	"RESUME": "BACK ON THE ROAD.",
	"HOW IT WORKS": "WHAT A DAY IS, GETTING ABOUT, MONEY, THE POLICE, AND WHO LEO'S TURNING INTO.",
	"SETTINGS": "CONTROLS, THE WHEEL, THE SCREEN, DIFFICULTY, GRAPHICS AND SOUND.",
	"CONTROLS": "WHAT EVERY BUTTON DOES. CHANGE THEM IN SETTINGS.",
	"EMPLOYEE OF THE MONTH": "THE WALL IN THE BREAK ROOM AT COVINGTON AUTO.",
	"QUIT TO TITLE": "THE GAME'S SAVED FIRST.",
	"SET UP THE WHEEL": "A WHEEL'S PLUGGED IN. TWENTY SECONDS: TURN IT, PRESS THE PEDALS, AND IT DRIVES.",
}
const PANEL := Rect2(170, 88, 300, 172)
const CARD := Rect2(40, 30, 560, 294)
const ITEM_H := 16.0
const CARD_KEY_X := 250.0          # the controls card's keyboard column, from the card's left
const CARD_PAD_X := 410.0          # and its controller column
const CARD_TOP := 34.0             # where its rows start
const CARD_PITCH := 12.0

var sel := 0
var card := false              # the controls card is up
var guide := -1                # the HOW IT WORKS page that's up (-1: none)
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
	guide = -1
	_opened = Engine.get_process_frames()
	get_parent().move_child(self, -1)          # over every panel the HUD layer has
	get_tree().paused = true

func close() -> void:
	visible = false
	settings.visible = false
	wall.visible = false
	get_tree().paused = false

## What's on the menu: the usual, and the wheel's setup while a wheel's plugged in that isn't.
func items() -> Array:
	var out := ITEMS.duplicate()
	if Wheel.needs_setup(): out.insert(1, "SET UP THE WHEEL")
	return out

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	if settings.visible or wall.visible: return
	var f := Engine.get_process_frames()
	if f == _opened or f == _back: return
	if guide >= 0:
		var pages := HowItWorks.PAGES.size()
		if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_accept"):
			guide += 1
			if guide >= pages: guide = -1
		elif Input.is_action_just_pressed("ui_left"): guide = maxi(0, guide - 1)
		elif Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"): guide = -1
		return
	if card:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pause"):
			card = false
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		close()
		return
	var its := items()
	var n := its.size()
	sel = mini(sel, n - 1)
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % n
	if Input.is_action_just_pressed("ui_up"): sel = (sel + n - 1) % n
	if Input.is_action_just_pressed("ui_accept"): _pick(String(its[sel]))

func _pick(item: String) -> void:
	match item:
		"RESUME": close()
		"HOW IT WORKS": guide = 0
		"SETTINGS": settings.open()
		"SET UP THE WHEEL": settings.open_wheel()
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
		# the clutch only matters in pedal mode: keep the card to what you're using
		if String(r[0]) == "clutch" and String(GameSettings.get_v("controls", "clutch")) != "pedal": continue
		if String(r[0]) == "help": continue                 # (you're looking at it)
		Hints.pad = false
		var k := Hints.key(String(r[0]))
		Hints.pad = true
		var p := Hints.key(String(r[0]))
		out.append([String(r[1]), k if k != "" else "-", p if p != "" else "-"])
	Hints.pad = was
	return out

## Item i's box on the panel.
static func item_rect(i: int) -> Rect2:
	return Rect2(PANEL.position.x + 8, PANEL.position.y + 16 + i * ITEM_H, PANEL.size.x - 16, ITEM_H - 2)

## Where the line under the items (and the description under it) starts.
static func desc_y() -> float:
	return PANEL.end.y - 30

func _draw() -> void:
	if not visible or settings.visible or wall.visible: return
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.6))
	if guide >= 0:
		_draw_guide()
		return
	if card:
		_draw_card()
		return
	UiKit.panel(self, PANEL, "PAUSED")
	var its := items()
	var pick := mini(sel, its.size() - 1)
	for i in its.size():
		var r := item_rect(i)
		var on := i == pick
		if on: UiKit.select(self, r)
		if on: PixelFont.draw(self, r.position + Vector2(7, 3), "▶", GOLD, 2)
		PixelFont.draw(self, r.position + Vector2(18, 3), String(its[i]), GOLD if on else BONE, 2)
	draw_rect(Rect2(PANEL.position.x + UiKit.PAD, desc_y() - 6, PANEL.size.x - 2 * UiKit.PAD, 1), UiKit.RULE)
	var ls := UiKit.wrap(String(DESCS[its[pick]]), PANEL.size.x - 2 * UiKit.PAD)
	for k in mini(ls.size(), 2):
		PixelFont.draw(self, Vector2(PANEL.position.x + UiKit.PAD, desc_y() + k * UiKit.LINE_H), ls[k], Color(BONE, 0.75), 2)
	UiKit.hints(self, 320, 344, Hints.fmt("{updown}: PICK  {ui_accept}: SELECT  {pause}: RESUME"))

## A HOW IT WORKS page's lines, wrapped to the card.
static func guide_lines(page: int) -> Array[String]:
	return HowItWorks.lines(page, CARD.size.x - 2 * UiKit.PAD - 4)

func _draw_guide() -> void:
	UiKit.panel(self, CARD, "HOW IT WORKS")
	var n := HowItWorks.PAGES.size()
	# the pages as pips at the top right, this one lit
	for k in n:
		var pr := Rect2(CARD.end.x - UiKit.PAD - (n - k) * 10 + 4, CARD.position.y + 21, 6, 6)
		if k == guide: draw_rect(pr, GOLD)
		else: draw_rect(pr, Color(1, 1, 1, 0.25), false, 1.0)
	var pg := "%d / %d" % [guide + 1, n]
	PixelFont.draw(self, Vector2(CARD.end.x - UiKit.PAD - n * 10 - 6 - PixelFont.width(pg, 2), CARD.position.y + 19), pg, ASH, 2)
	UiKit.title(self, CARD.position + Vector2(UiKit.PAD, 16), String(HowItWorks.PAGES[guide][0]))
	draw_rect(Rect2(CARD.position.x + UiKit.PAD, CARD.position.y + 38, CARD.size.x - 2 * UiKit.PAD, 1), UiKit.RULE)
	var y := CARD.position.y + 46
	for ln in guide_lines(guide):
		if y > CARD.end.y - 12: break
		PixelFont.draw(self, Vector2(CARD.position.x + UiKit.PAD + 2, y), ln, BONE, 2)
		y += UiKit.LINE_H if ln != "" else 6
	UiKit.hints(self, 320, 336, Hints.fmt("{leftright}: TURN THE PAGE  {ui_cancel}: BACK"))

func _draw_card() -> void:
	UiKit.panel(self, CARD, "CONTROLS")
	PixelFont.draw(self, CARD.position + Vector2(CARD_KEY_X, 14), "KEYBOARD", ASH, 2)
	PixelFont.draw(self, CARD.position + Vector2(CARD_PAD_X, 14), "CONTROLLER", ASH, 2)
	draw_rect(Rect2(CARD.position.x + UiKit.PAD, CARD.position.y + 26, CARD.size.x - 2 * UiKit.PAD, 1), UiKit.RULE)
	var ls := card_lines()
	for i in ls.size():
		var y := CARD.position.y + CARD_TOP + i * CARD_PITCH
		if i % 2 == 1: draw_rect(Rect2(CARD.position.x + 4, y - 2, CARD.size.x - 8, CARD_PITCH), Color(1, 1, 1, 0.025))
		PixelFont.draw(self, Vector2(CARD.position.x + UiKit.PAD + 2, y), String(ls[i][0]), BONE, 2)
		for c in 2:
			var txt := String(ls[i][1 + c])
			var x := CARD.position.x + (CARD_KEY_X if c == 0 else CARD_PAD_X)
			var w := (CARD_PAD_X - CARD_KEY_X - 10) if c == 0 else (CARD.size.x - CARD_PAD_X - UiKit.PAD)
			PixelFont.draw(self, Vector2(x, y), UiKit.fit(txt, w), ASH if txt == "-" else GOLD.lightened(0.25), 2)
	UiKit.hints(self, 320, 336, Hints.fmt("{ui_cancel}: BACK  CHANGE THEM IN SETTINGS"))
