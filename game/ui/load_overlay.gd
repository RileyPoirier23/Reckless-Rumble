## A card over the road while the next stretch of it is built and painted (a mission start, the
## handover, a respawn): the same ink and pixel text as the loading screen, with a bar that fills
## as the chunks come in. Nothing moves under it until it's gone.
class_name LoadOverlay
extends Control

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")

var title := "THE ROAD"
var line := ""
var progress := 0.0
var _t := 0.0

func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func open(what: String, tip := "") -> void:
	title = what
	line = tip
	progress = 0.0
	_t = 0.0
	visible = true
	queue_redraw()

func _process(dt: float) -> void:
	if not visible: return
	_t += dt
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), INK)
	# a strip of road, the dashes rolling by
	draw_rect(Rect2(0, 236, 640, 24), Color("2e2e34"))
	for k in 9:
		var dx := fmod(k * 80.0 - _t * 120.0, 720.0) - 40.0
		draw_rect(Rect2(dx, 247, 40, 2), Color("e8c040"))
	PixelFont.draw(self, Vector2(320 - PixelFont.width(title, 2) / 2.0, 150), title, BONE, 2)
	var dots := ".".repeat(1 + int(_t * 2.0) % 3)
	PixelFont.draw(self, Vector2(320 - PixelFont.width("LOADING" + dots) / 2.0, 172), "LOADING" + dots, ASH)
	draw_rect(Rect2(220, 190, 200, 6), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(220, 190, 200 * clampf(progress, 0.0, 1.0), 6), GOLD)
	if line != "": PixelFont.draw(self, Vector2(320 - PixelFont.width(line) / 2.0, 300), line, Color(BONE, 0.8))
