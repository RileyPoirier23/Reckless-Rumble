## The Employee of the Month wall in the break room at Covington Auto: a framed photo for every
## award you've won, with the month on a brass plate, and an empty frame for every one you haven't.
## Opened from the title and from the pause menu. The photos are drawn here too (the card that
## comes up when you win one uses them).
class_name EmployeeWall
extends Control

signal closed

const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const INK := Color("0b090d")
const BRASS := Color("c8a24a")
const WALL := Color("cfc6a8")
const WALL_DARK := Color("b8ae90")

## The wall: 8 frames across, 4 rows, then what the picked one is for underneath.
const COLS := 8
const ROWS := 4
const FRAME := Vector2(66, 50)
const PITCH := Vector2(74, 56)
const GRID_X := 28.0
const GRID_Y := 40.0
const PHOTO := Vector2(50, 32)
const DETAIL := Rect2(28, 266, 584, 66)
const HINT_Y := 342.0

## Who's in the photos: Leo (the cast's seed), a year older every twelve photos.
const WHO := { "seed": 190019, "female": 0, "age": 19 }

var sel := 0
var scroll := 0                # rows scrolled (when there are more than fit)
var _opened := -1

func open() -> void:
	Awards.ensure()
	visible = true
	sel = 0
	scroll = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened = Engine.get_process_frames()

func close() -> void:
	visible = false
	closed.emit()

static func frame_rect(i: int, scroll_rows := 0) -> Rect2:
	var c := i % COLS
	var r := int(i / COLS) - scroll_rows
	return Rect2(GRID_X + c * PITCH.x, GRID_Y + r * PITCH.y, FRAME.x, FRAME.y)

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	if Engine.get_process_frames() == _opened: return
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("menu_back"):
		close()
		return
	var n := Awards.LIST.size()
	if Input.is_action_just_pressed("ui_right"): sel = mini(sel + 1, n - 1)
	if Input.is_action_just_pressed("ui_left"): sel = maxi(sel - 1, 0)
	if Input.is_action_just_pressed("ui_down"): sel = mini(sel + COLS, n - 1)
	if Input.is_action_just_pressed("ui_up"): sel = maxi(sel - COLS, 0)
	var row := int(sel / COLS)
	if row < scroll: scroll = row
	if row >= scroll + ROWS: scroll = row - ROWS + 1

func _input(e: InputEvent) -> void:
	if not visible: return
	if e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed):
		var p := get_global_mouse_position()
		for i in Awards.LIST.size():
			if frame_rect(i, scroll).has_point(p): sel = i

func _draw() -> void:
	if not visible: return
	# the break room: painted cinder block, a strip of wood trim
	draw_rect(Rect2(0, 0, 640, 360), WALL)
	for y in range(0, 360, 12):
		draw_rect(Rect2(0, y, 640, 1), WALL_DARK)
		var off := 0 if int(y / 12) % 2 == 0 else 20
		for x in range(off, 640, 40): draw_rect(Rect2(x, y, 1, 12), WALL_DARK)
	draw_rect(Rect2(0, 30, 640, 3), Color("6a4a2a"))
	PixelFont.draw_centered(self, 320, 6, "EMPLOYEE OF THE MONTH", Color("2a2014"), 2)
	var won := Awards.count()
	PixelFont.draw_centered(self, 320, 21, "COVINGTON AUTO.  %d OF %d ON THE WALL." % [won, Awards.LIST.size()], Color("4a3e2a"))
	for i in Awards.LIST.size():
		var r := frame_rect(i, scroll)
		if r.position.y < GRID_Y - 1 or r.end.y > DETAIL.position.y - 4: continue
		var a: Dictionary = Awards.LIST[i]
		var got := Awards.has(String(a.id))
		draw_frame(self, r, a, got, int(Awards.won.get(String(a.id), {}).get("n", 0)) if got else -1)
		if i == sel: draw_rect(r.grow(2), GOLD, false, 2.0)
	# the picked one
	var a: Dictionary = Awards.LIST[sel]
	var got := Awards.has(String(a.id))
	draw_rect(DETAIL, Color(0.08, 0.07, 0.06, 0.9))
	draw_rect(DETAIL, BRASS, false, 1.0)
	var big := Rect2(DETAIL.position + Vector2(8, 8), PHOTO * 1.5)
	if got: draw_photo(self, big, a, int(Awards.won[String(a.id)].n))
	else: _draw_empty(self, big)
	var tx := big.end.x + 10
	PixelFont.draw(self, Vector2(tx, DETAIL.position.y + 8), String(a.name) if got else String(a.name) + " (NOT YET)", GOLD if got else ASH, 2)
	var sub := Awards.month_of(int(Awards.won[String(a.id)].n)) if got else "NOT ON THE WALL YET"
	PixelFont.draw(self, Vector2(tx, DETAIL.position.y + 24), sub, BRASS if got else ASH)
	var ls := Hud.wrap_lines(String(a.desc), int((DETAIL.end.x - tx - 8) / 4))
	for k in mini(ls.size(), 3): PixelFont.draw(self, Vector2(tx, DETAIL.position.y + 36 + k * 9), ls[k], BONE)
	var hint := Hints.fmt("{updown}/{leftright}: LOOK  {ui_cancel}: BACK")
	PixelFont.draw_centered(self, 320, HINT_Y, hint, Color("2a2014"))

# ------------------------------------------------------------------ the frames and photos

## One frame on the wall: black frame, white mat, the photo (or the stock card), a brass plate.
static func draw_frame(ci: CanvasItem, r: Rect2, a: Dictionary, got: bool, n: int) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, Color("1e1a16"))
	ci.draw_rect(r.grow(-2), Color("efeae0"))
	var ph := Rect2(r.position + Vector2((r.size.x - PHOTO.x) / 2.0, 4), PHOTO)
	if got: draw_photo(ci, ph, a, n)
	else: _draw_empty(ci, ph)
	var plate := Rect2(r.position.x + 12, ph.end.y + 4, r.size.x - 24, 8)
	ci.draw_rect(plate, BRASS if got else Color("b0aa9c"))
	var txt := _short_month(n) if got else "-"
	PixelFont.draw_centered(ci, plate.get_center().x, plate.position.y + 2, txt, Color("3a2a10") if got else Color("7a7468"))

static func _short_month(n: int) -> String:
	var m := Awards.month_of(n).split(" ")
	return "%s %s" % [String(m[0]).substr(0, 3), String(m[1])]

## The frame before there's a photo in it: the stock card it came with.
static func _draw_empty(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color("d8d2c4"))
	var k := r.size.x / PHOTO.x
	var c := Color("bab3a2")
	ci.draw_circle(r.position + Vector2(r.size.x / 2.0, 12 * k), 6 * k, c)
	ci.draw_rect(Rect2(r.position.x + r.size.x / 2.0 - 11 * k, r.position.y + 20 * k, 22 * k, r.size.y - 20 * k), c)
	PixelFont.draw_centered(ci, r.get_center().x, r.end.y - 7 * k, "YOUR PHOTO", Color("8a8478"))

## A photo: where it was taken, Leo in it, and what it's for.
static func draw_photo(ci: CanvasItem, r: Rect2, a: Dictionary, n: int) -> void:
	var k := r.size.x / PHOTO.x
	_bg(ci, r, String(a.get("bg", "lot")), k)
	# Leo, a year older every twelve photos
	var age := int(WHO.age) + int((9 + n) / 12)
	var face := Face.texture(int(WHO.seed), int(WHO.female), age)
	var fs := 26.0 * k
	ci.draw_texture_rect(face, Rect2(r.position.x + 4 * k, r.end.y - fs, fs, fs), false)
	_prop(ci, Rect2(r.position.x + 28 * k, r.position.y + 4 * k, 20 * k, r.size.y - 6 * k), String(a.get("prop", "")), k)
	# the print's border and a little sheen
	ci.draw_rect(r, Color(1, 1, 1, 0.5), false, 1.0)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2 * k)), Color(1, 1, 1, 0.08))

static func _bg(ci: CanvasItem, r: Rect2, bg: String, k: float) -> void:
	var p := r.position
	var w := r.size.x
	var h := r.size.y
	match bg:
		"lot":
			ci.draw_rect(Rect2(p, Vector2(w, h * 0.55)), Color("8ab4d8"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.55, w, h * 0.45), Color("6a6a70"))
			ci.draw_rect(Rect2(p.x + w * 0.55, p.y + h * 0.2, w * 0.45, h * 0.36), Color("b8463a"))
			ci.draw_rect(Rect2(p.x + w * 0.6, p.y + h * 0.26, w * 0.32, h * 0.08), Color("f3ead2"))
		"road":
			ci.draw_rect(Rect2(p, Vector2(w, h * 0.5)), Color("a8c8e0"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.5, w, h * 0.5), Color("6a8a4a"))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.45, h * 0.5), p + Vector2(w * 0.55, h * 0.5), p + Vector2(w, h), p + Vector2(w * 0.3, h)]), Color("4a4a50"))
		"shop":
			ci.draw_rect(Rect2(p, r.size), Color("5a5e66"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.75, w, h * 0.25), Color("3a3c42"))
			for i in 4: ci.draw_rect(Rect2(p.x + w * 0.5 + i * 5 * k, p.y + 4 * k, 3 * k, 8 * k), Color("c8342c") if i % 2 == 0 else Color("8a8e94"))
			ci.draw_rect(Rect2(p.x + w * 0.45, p.y + h * 0.55, w * 0.55, 2 * k), Color("e8c040"))
		"night":
			ci.draw_rect(Rect2(p, r.size), Color("141a2c"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.65, w, h * 0.35), Color("26262e"))
			ci.draw_circle(p + Vector2(w * 0.8, h * 0.2), 6 * k, Color(1, 0.85, 0.5, 0.25))
			ci.draw_rect(Rect2(p.x + w * 0.8 - k, p.y + h * 0.2, 2 * k, h * 0.45), Color("3a3a44"))
		"strip":
			ci.draw_rect(Rect2(p, Vector2(w, h * 0.5)), Color("e08a4a"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.25, w, h * 0.25), Color("c8604a"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.5, w, h * 0.5), Color("3e3e44"))
			for i in 5: ci.draw_rect(Rect2(p.x + i * w / 5.0, p.y + h * 0.74, w / 10.0, k), Color("f3ead2"))
		"police":
			ci.draw_rect(Rect2(p, r.size), Color("10121c"))
			ci.draw_circle(p + Vector2(w * 0.3, h * 0.3), 9 * k, Color(0.9, 0.1, 0.1, 0.35))
			ci.draw_circle(p + Vector2(w * 0.75, h * 0.3), 9 * k, Color(0.15, 0.3, 1.0, 0.35))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.7, w, h * 0.3), Color("22222a"))
		"woods":
			ci.draw_rect(Rect2(p, r.size), Color("8aa0b8"))
			for i in 6:
				var x := p.x + i * w / 5.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, p.y + 4 * k), Vector2(x - 6 * k, p.y + h * 0.75), Vector2(x + 6 * k, p.y + h * 0.75)]), Color("2a4a2e"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.75, w, h * 0.25), Color("4a4a50"))
		"pumps":
			ci.draw_rect(Rect2(p, r.size), Color("a8c8e0"))
			ci.draw_rect(Rect2(p.x, p.y, w, h * 0.22), Color("c8342c"))
			ci.draw_rect(Rect2(p.x, p.y + h * 0.7, w, h * 0.3), Color("8a8a90"))
			ci.draw_rect(Rect2(p.x + w * 0.62, p.y + h * 0.3, 8 * k, h * 0.42), Color("e8e4dc"))
		_:
			ci.draw_rect(Rect2(p, r.size), Color("6a6a70"))

## What's in Leo's hands (or behind them): drawn small, in plain shapes.
static func _prop(ci: CanvasItem, r: Rect2, prop: String, k: float) -> void:
	var c := r.get_center()
	match prop:
		"keys":
			ci.draw_circle(c + Vector2(-2, -2) * k, 3 * k, Color("e8c040"))
			ci.draw_rect(Rect2(c.x, c.y - k, 7 * k, 2 * k), Color("c8ccd4"))
			ci.draw_rect(Rect2(c.x + 5 * k, c.y, k, 2 * k), Color("c8ccd4"))
		"odo":
			ci.draw_rect(Rect2(c.x - 9 * k, c.y - 3 * k, 18 * k, 7 * k), INK)
			PixelFont.draw_centered(ci, c.x, c.y - 2 * k, "000", Color("f3ead2"), maxi(1, int(k)))
		"car":
			ci.draw_rect(Rect2(c.x - 9 * k, c.y, 18 * k, 5 * k), Color("c8342c"))
			ci.draw_rect(Rect2(c.x - 5 * k, c.y - 4 * k, 10 * k, 4 * k), Color("a82a24"))
			ci.draw_circle(c + Vector2(-5, 5) * k, 2 * k, INK)
			ci.draw_circle(c + Vector2(5, 5) * k, 2 * k, INK)
		"wrench":
			ci.draw_line(c + Vector2(-7, 6) * k, c + Vector2(5, -6) * k, Color("c8ccd4"), 2 * k)
			ci.draw_circle(c + Vector2(6, -7) * k, 3 * k, Color("c8ccd4"))
		"box":
			ci.draw_rect(Rect2(c.x - 8 * k, c.y - 6 * k, 16 * k, 12 * k), Color("b08a5a"))
			ci.draw_rect(Rect2(c.x - 8 * k, c.y - 2 * k, 16 * k, 2 * k), Color("e8d8b0"))
		"gauge":
			ci.draw_circle(c, 8 * k, INK)
			ci.draw_circle(c, 7 * k, Color("f3ead2"))
			ci.draw_line(c, c + Vector2(5, -4) * k, Color("c8342c"), k)
		"spray":
			ci.draw_rect(Rect2(c.x - 3 * k, c.y - 6 * k, 6 * k, 13 * k), Color("2c5a8a"))
			ci.draw_rect(Rect2(c.x - 2 * k, c.y - 8 * k, 4 * k, 2 * k), INK)
			ci.draw_circle(c + Vector2(-7, -8) * k, 3 * k, Color(0.3, 0.6, 1.0, 0.5))
		"pizza":
			ci.draw_rect(Rect2(c.x - 9 * k, c.y - 2 * k, 18 * k, 8 * k), Color("e8e0d0"))
			ci.draw_rect(Rect2(c.x - 9 * k, c.y - 4 * k, 18 * k, 2 * k), Color("c8342c"))
		"phone":
			ci.draw_rect(Rect2(c.x - 4 * k, c.y - 7 * k, 8 * k, 14 * k), INK)
			ci.draw_rect(Rect2(c.x - 3 * k, c.y - 6 * k, 6 * k, 10 * k), Color("6fbf5a"))
			for i in 5: ci.draw_rect(Rect2(c.x - 3 * k + i * k * 1.3, c.y - 3 * k, k, k), Color("f0d040"))
		"hook":
			ci.draw_rect(Rect2(c.x - k, c.y - 9 * k, 2 * k, 10 * k), Color("8a8e94"))
			ci.draw_arc(c + Vector2(-2, 2) * k, 3 * k, 0.0, PI, 8, Color("8a8e94"), 2 * k)
		"moon":
			ci.draw_circle(c + Vector2(0, -4) * k, 5 * k, Color("f3ead2"))
			ci.draw_circle(c + Vector2(2, -5) * k, 4 * k, Color("141a2c"))
		"flag":
			ci.draw_rect(Rect2(c.x - 6 * k, c.y - 8 * k, k, 16 * k), Color("c8ccd4"))
			for i in 4:
				for j in 3:
					ci.draw_rect(Rect2(c.x - 5 * k + i * 3 * k, c.y - 8 * k + j * 3 * k, 3 * k, 3 * k), INK if (i + j) % 2 == 0 else Color("f3ead2"))
		"slip":
			ci.draw_rect(Rect2(c.x - 8 * k, c.y - 5 * k, 16 * k, 10 * k), Color("e8a0b8"))
			for i in 3: ci.draw_rect(Rect2(c.x - 6 * k, c.y - 3 * k + i * 3 * k, 12 * k, k * 0.6), Color("8a3a5a"))
		"trophy":
			ci.draw_rect(Rect2(c.x - 5 * k, c.y - 8 * k, 10 * k, 8 * k), Color("e8c040"))
			ci.draw_rect(Rect2(c.x - k, c.y, 2 * k, 4 * k), Color("c8a020"))
			ci.draw_rect(Rect2(c.x - 4 * k, c.y + 4 * k, 8 * k, 2 * k), Color("6a4a2a"))
		"ticket":
			ci.draw_rect(Rect2(c.x - 6 * k, c.y - 8 * k, 12 * k, 16 * k), Color("f3ead2"))
			for i in 4: ci.draw_rect(Rect2(c.x - 4 * k, c.y - 5 * k + i * 3 * k, 8 * k, k * 0.6), Color("8a8478"))
			ci.draw_rect(Rect2(c.x - 4 * k, c.y + 5 * k, 5 * k, k), Color("c8342c"))
		"siren":
			ci.draw_rect(Rect2(c.x - 8 * k, c.y - 2 * k, 8 * k, 4 * k), Color("e0402e"))
			ci.draw_rect(Rect2(c.x, c.y - 2 * k, 8 * k, 4 * k), Color("3a6ae0"))
		"moose":
			ci.draw_rect(Rect2(c.x - 7 * k, c.y - 2 * k, 13 * k, 6 * k), Color("3a2a1e"))
			ci.draw_rect(Rect2(c.x + 5 * k, c.y - 6 * k, 4 * k, 5 * k), Color("3a2a1e"))
			ci.draw_rect(Rect2(c.x + 3 * k, c.y - 9 * k, 8 * k, 2 * k), Color("b89a6a"))
			for x in [-6, -2, 2, 5]: ci.draw_rect(Rect2(c.x + x * k, c.y + 4 * k, k, 5 * k), Color("3a2a1e"))
		"deer":
			ci.draw_rect(Rect2(c.x - 6 * k, c.y - k, 11 * k, 5 * k), Color("8a6a46"))
			ci.draw_rect(Rect2(c.x + 4 * k, c.y - 5 * k, 3 * k, 5 * k), Color("8a6a46"))
			for x in [-5, -1, 2, 4]: ci.draw_rect(Rect2(c.x + x * k, c.y + 4 * k, k, 5 * k), Color("8a6a46"))
		"cash":
			for i in 3: ci.draw_rect(Rect2(c.x - 8 * k + i * k, c.y - 4 * k + i * 2 * k, 14 * k, 6 * k), Color("4e8a3a") if i % 2 == 0 else Color("6aa84a"))
		"gavel":
			ci.draw_line(c + Vector2(-6, 7) * k, c + Vector2(3, -2) * k, Color("8a5a2a"), 2 * k)
			ci.draw_rect(Rect2(c.x, c.y - 8 * k, 9 * k, 5 * k), Color("6a4a2a"))
		"sign":
			ci.draw_rect(Rect2(c.x - 8 * k, c.y - 6 * k, 16 * k, 9 * k), Color("f0d040"))
			PixelFont.draw_centered(ci, c.x, c.y - 4 * k, "SOLD", INK, maxi(1, int(k * 0.75)))
		"gascan":
			ci.draw_rect(Rect2(c.x - 5 * k, c.y - 5 * k, 10 * k, 12 * k), Color("c8342c"))
			ci.draw_rect(Rect2(c.x + 2 * k, c.y - 8 * k, 3 * k, 3 * k), Color("e8c040"))
		"mask":
			# the Luchadooros' mask: purple, white round the eyes, gold trim
			ci.draw_circle(c, 8 * k, Color("6a2a8a"))
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * 1.0, -2) * k, c + Vector2(sx * 6.0, -4) * k, c + Vector2(sx * 5.0, 1) * k, c + Vector2(sx * 1.5, 1) * k]), Color("f3ead2"))
				ci.draw_circle(c + Vector2(sx * 3.2, -1.2) * k, 1.1 * k, INK)
			ci.draw_rect(Rect2(c.x - 3 * k, c.y + 3.5 * k, 6 * k, 1.5 * k), Color("e8c040"))
		"pump":
			ci.draw_rect(Rect2(c.x - 3 * k, c.y - 7 * k, 6 * k, 13 * k), Color("c8ccd4"))
			ci.draw_rect(Rect2(c.x - 2 * k, c.y - 9 * k, 4 * k, 2 * k), Color("e8c040"))
			ci.draw_line(c + Vector2(3, -2) * k, c + Vector2(8, -2) * k, Color("c8342c"), k)
		"rim":
			ci.draw_circle(c, 9 * k, INK)
			ci.draw_circle(c, 7 * k, Color("e8c040"))
			for i in 6: ci.draw_line(c, c + Vector2.from_angle(i * PI / 3.0) * 6.5 * k, Color("8a6a20"), k)
			ci.draw_circle(c, 1.5 * k, INK)
		"wreck":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 4) * k, c + Vector2(-6, -3) * k, c + Vector2(2, -1) * k, c + Vector2(8, -5) * k, c + Vector2(9, 4) * k]), Color("8a8e94"))
			ci.draw_circle(c + Vector2(-5, 5) * k, 2 * k, INK)
			ci.draw_circle(c + Vector2(6, 5) * k, 2 * k, INK)
			ci.draw_circle(c + Vector2(0, -6) * k, 3 * k, Color(0.5, 0.5, 0.5, 0.5))
