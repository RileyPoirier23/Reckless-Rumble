## The card that comes up when you win Employee of the Month: never mid-drive. It waits until
## you've stopped with nothing else going on, and the game holds still while it's up.
class_name AwardCard
extends Control

signal done

const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const PANEL := Rect2(160, 52, 320, 236)

var id := ""
var t := 0.0
var _opened := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(640, 360)
	visible = false

func open(award_id: String) -> void:
	id = award_id
	t = 0.0
	visible = true
	_opened = Engine.get_process_frames()
	get_parent().move_child(self, -1)
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false
	done.emit()

func _process(dt: float) -> void:
	if not visible: return
	t += dt
	queue_redraw()
	if Engine.get_process_frames() == _opened or t < 0.4: return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		close()

func _input(e: InputEvent) -> void:
	if visible and t >= 0.4 and e is InputEventMouseButton and e.pressed: close()

func _draw() -> void:
	if not visible: return
	var a := Awards.by_id(id)
	if a.is_empty(): return
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.82))
	# the rays turning behind it
	var c := PANEL.get_center()
	for i in 12:
		var ang := t * 0.4 + i * TAU / 12.0
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(ang - 0.12) * 260.0, c + Vector2.from_angle(ang + 0.12) * 260.0]), Color(GOLD, 0.06))
	draw_rect(PANEL, Color(0.06, 0.05, 0.07, 0.96))
	draw_rect(PANEL, GOLD, false, 1.0)
	var n := int(Awards.won.get(id, {}).get("n", 0))
	PixelFont.draw_centered(self, c.x, PANEL.position.y + 10, "EMPLOYEE OF THE MONTH", GOLD, 2)
	PixelFont.draw_centered(self, c.x, PANEL.position.y + 26, Awards.month_of(n), ASH)
	# the photo, framed, big
	var ph := Rect2(c.x - EmployeeWall.PHOTO.x, PANEL.position.y + 40, EmployeeWall.PHOTO.x * 2.0, EmployeeWall.PHOTO.y * 2.0)
	draw_rect(ph.grow(5), Color("1e1a16"))
	draw_rect(ph.grow(3), Color("efeae0"))
	EmployeeWall.draw_photo(self, ph, a, n)
	PixelFont.draw_centered(self, c.x, ph.end.y + 12, String(a.name), BONE, 2)
	var ls := Hud.wrap_lines(String(a.desc), 72)
	for k in mini(ls.size(), 2): PixelFont.draw_centered(self, c.x, ph.end.y + 28 + k * 9, ls[k], ASH)
	PixelFont.draw_centered(self, c.x, PANEL.end.y - 34, "%d OF %d ON THE WALL" % [Awards.count(), Awards.LIST.size()], ASH)
	PixelFont.draw_centered(self, c.x, PANEL.end.y - 16, Hints.fmt("{ui_accept}: PUT IT ON THE WALL"), GOLD)
