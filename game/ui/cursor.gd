## The game's own mouse pointers, drawn in pixels like everything else: an arrow, a pointing
## finger for things you can press, and a closed hand for paper you're dragging across the counter.
## Scaled up with the window, so a pixel of the pointer is a pixel of the game.
class_name Cursor
extends RefCounted

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const SHADE := Color("b8ab8c")

## X ink, O bone, G gold, S shade, . clear. The first row is the top.
const ARROW := [
	"X...........",
	"XX..........",
	"XOX.........",
	"XOOX........",
	"XOOOX.......",
	"XOOOOX......",
	"XOOOOOX.....",
	"XOOOOOOX....",
	"XOOOOOOOX...",
	"XOOOOOOOSX..",
	"XOOOOOOSSSX.",
	"XOOOGXXXXXXX",
	"XOOXGGX.....",
	"XOX.XGGX....",
	"XX..XGGX....",
	"X....XGGX...",
	".....XGGX...",
	"......XX....",
]
const POINT := [
	"....XX.......",
	"...XOOX......",
	"...XOOX......",
	"...XOOX......",
	"...XOOXXX....",
	"...XOOXOOXX..",
	"XX.XOOXOOXOXX",
	"XOXXOOOOOOOOX",
	"XOOXOOOOOOOOX",
	".XOOOOOOOOOSX",
	"..XOOOOOOOOSX",
	"..XOOOOOOOSX.",
	"...XOOOOOOSX.",
	"...XGGGGGGX..",
	"...XXXXXXXX..",
]
const GRAB := [
	".............",
	".............",
	".............",
	"....XXXXXX...",
	"...XOOXOOXXX.",
	"..XXOOXOOXOOX",
	".XOXOOOOOOOOX",
	".XOOOOOOOOOOX",
	"..XOOOOOOOOSX",
	"..XOOOOOOOOSX",
	"..XOOOOOOOSX.",
	"...XOOOOOOSX.",
	"...XGGGGGGX..",
	"...XXXXXXXX..",
]

## The pixel scale for this window: as many whole times the game's 640x360 as fit.
static func scale_for(win: Vector2i) -> int:
	return maxi(1, mini(int(win.x / 640.0), int(win.y / 360.0)))

## One pointer as an image, each pixel `s` screen pixels across.
static func image(rows: Array, s: int) -> Image:
	var w := 0
	for r in rows: w = maxi(w, String(r).length())
	var img := Image.create(w * s, rows.size() * s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var r := String(rows[y])
		for x in r.length():
			var c := Color(0, 0, 0, 0)
			match r[x]:
				"X": c = INK
				"O": c = BONE
				"G": c = GOLD
				"S": c = SHADE
				_: continue
			img.fill_rect(Rect2i(x * s, y * s, s, s), c)
	return img

## Put the pointers up for this window's size (again when it changes).
static func apply(win: Window) -> void:
	if DisplayServer.get_name() == "headless": return
	var s := scale_for(win.size if win else Vector2i(1280, 720))
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(image(ARROW, s)), Input.CURSOR_ARROW, Vector2.ZERO)
	var hand := ImageTexture.create_from_image(image(POINT, s))
	Input.set_custom_mouse_cursor(hand, Input.CURSOR_POINTING_HAND, Vector2(4.5 * s, 0))
	var grab := ImageTexture.create_from_image(image(GRAB, s))
	for shape in [Input.CURSOR_DRAG, Input.CURSOR_MOVE, Input.CURSOR_CAN_DROP]:
		Input.set_custom_mouse_cursor(grab, shape, Vector2(6.5 * s, 7.0 * s))
