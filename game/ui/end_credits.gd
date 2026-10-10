## The credits: the roll, a thank-you, then the memorial for Riley's memere, the same one that closes
## CAGE BOSS. Played at the end of the story (and of the prologue demo), and from CREDITS on the
## title. From the title you can skip ahead, but only as far as the memorial: everybody sees her.
##
##   In Memoriam: Yvette Collette (August 20th 1953 - October 7th 2026).
##   Grandmother, Sister, Wife and Mother.
##
## The portrait is her real photo, in black and white and reduced to pixels to sit in the game's
## style (art/memorial/memere_portrait.png, from CAGE BOSS). It is never redrawn or generated.
class_name EndCredits
extends Control

signal done

const PHOTO := "res://art/memorial/memere_portrait.png"
const INK := Color("060508")
const BONE := Color("eee8dc")
const ASH := Color("8a8478")
const GOLD := Color("d9a441")
const RED := Color("c8342c")

## [text, kind]: h the title, g gold, b bold names, s a small grey heading, n a plain line, "" a gap.
const ROLL := [
	["DRIVEBOSS", "h"],
	["", "n"],
	["A 506CLICKS GAME", "s"],
	["", "n"],
	["GAME DESIGN, IDEA, STORY, ART AND EVERYTHING ELSE", "s"],
	["RILEY \"MONKEY MAN\" POIRIER", "b"],
	["506CLICKS", "b"],
	["", "n"],
	["STARRING", "s"],
	["LEO COVINGTON", "n"],
	["GUS, EVERY SATURDAY SINCE 1981", "n"],
	["MIKEY, AND HIS HAT", "n"],
	["ARIES COVINGTON", "n"],
	["FRANKIE, FROM DOWN THE STREET", "n"],
	["DALE HATCH, HATCH MOTORS", "n"],
	["DOM TORTELLINI, WHO SAYS GRACE", "n"],
	["MIA TORTELLINI", "n"],
	["SAL", "n"],
	["TOBY CORMIER, WHO WILL TOW YOU", "n"],
	["CONSTABLE TREMBLAY, WHO COUNTS", "n"],
	["DARRELL, WHO SOLD YOU A LIE FOR $840", "n"],
	["1TON AND THE LUCHADOOROS", "n"],
	["LA CALAVERA  -  EL PULPO", "n"],
	["MARCO, WHO RUNS THE STREET", "n"],
	["FRANK COVINGTON", "n"],
	["AND YOU, AS THE OLD MANAGER", "n"],
	["", "n"],
	["PLAYTESTING", "s"],
	["1TON", "b"],
	["", "n"],
	["FIND ME", "s"],
	["INSTAGRAM: @506CLICKS  -  @RPOIRIER07", "n"],
	["TIKTOK: IHEARTGRANNIES69  -  DISCORD: GLDMONKEY", "n"],
	["", "n"],
	["MADE IN MONCTON, NEW BRUNSWICK", "s"],
	["506CLICKS.CA", "n"],
	["", "n"],
	["CHECK YOUR BRAKES EVERY SUNDAY.", "g"],
]

const THANKS := "FROM A DRUNK DRIVE HOME TO A COUNTER FULL OF PAPERWORK. THANK YOU FOR PLAYING DRIVEBOSS: EVERY INSPECTION, EVERY BAD CAR OFF MARKETTHING, EVERY DOUBLE-DOUBLE. IT MEANS MORE THAN YOU KNOW."

const VERSE := "\"PEACE I LEAVE WITH YOU; MY PEACE I GIVE TO YOU. NOT AS THE WORLD GIVES DO I GIVE TO YOU. LET NOT YOUR HEARTS BE TROUBLED, NEITHER LET THEM BE AFRAID.\""

static var from_menu := false       # set before opening it from the title: skipping allowed (to her, never past)

@export var standalone := false     # its own scene (ui/credits.tscn): when it's done, the story goes on or it's the title
var menu := false
var stage := "roll"                  # roll, thanks, memorial
var t := 0.0
var roll_y := 360.0
var photo: Texture2D
var _opened := -1

func _ready() -> void:
	size = Vector2(640, 360)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	menu = from_menu
	from_menu = false
	_opened = Engine.get_process_frames()
	photo = load_photo()
	if standalone: done.connect(_leave)

func _leave() -> void:
	if StoryState.active and String(StoryState.current().get("type", "")) == "credits": StoryState.advance(get_tree())
	else: get_tree().change_scene_to_file("res://title.tscn")

## Her photo, from the import or straight off the disk.
static func load_photo() -> Texture2D:
	if ResourceLoader.exists(PHOTO): return load(PHOTO)
	var img := Image.load_from_file(PHOTO)
	return ImageTexture.create_from_image(img) if img != null else null

static func roll_height() -> float:
	var y := 0.0
	for r in ROLL: y += _gap(r)
	return y

static func _gap(r: Array) -> float:
	if String(r[0]) == "": return 14.0
	match String(r[1]):
		"h": return 30.0
		"s": return 11.0
	return 13.0

## Straight to the memorial (the menu's skip; never past her).
func to_memorial() -> void:
	if stage == "memorial": return
	stage = "memorial"
	t = 0.0

## How long before CONTINUE shows on the memorial.
func wait_s() -> float:
	return 4.0 if menu else 8.0

func _process(dt: float) -> void:
	t += minf(dt, 0.05)
	queue_redraw()
	if Engine.get_process_frames() == _opened: return
	var go := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause")
	match stage:
		"roll":
			roll_y -= minf(dt, 0.05) * 22.0
			if roll_y < -roll_height():
				stage = "thanks"
				t = 0.0
			elif menu and go: to_memorial()
		"thanks":
			if t > 9.0: to_memorial()
			elif menu and go: to_memorial()
		"memorial":
			if t >= wait_s() and Input.is_action_just_pressed("ui_accept"):
				done.emit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), INK)
	match stage:
		"roll": _draw_roll()
		"thanks": _draw_thanks()
		"memorial": draw_memorial(self, photo, clampf(t / 3.0, 0.0, 1.0), t >= wait_s())
	if menu and stage != "memorial":
		PixelFont.draw(self, Vector2(640 - 4 - PixelFont.width(Hints.fmt("{ui_accept}: SKIP TO THE END")), 350), Hints.fmt("{ui_accept}: SKIP TO THE END"), ASH)

## A line of the roll as this story ended: on the Mountain ending, Frankie's line is his years.
static func line_text(s: String) -> String:
	if s == "FRANKIE, FROM DOWN THE STREET" and StoryState.active and StoryState.flag("frankie_dead"):
		return "FRANKIE, FROM DOWN THE STREET (2007 - 2026)"
	return s

func _draw_roll() -> void:
	var y := roll_y
	for r in ROLL:
		var s := line_text(String(r[0]))
		if s != "" and y > -40.0 and y < 370.0:
			var k := String(r[1])
			var col := RED if k == "h" else (GOLD if k in ["g", "b"] else (ASH if k == "s" else BONE))
			PixelFont.draw_centered(self, 320, y, s, col, 5 if k == "h" else 2 if k != "s" else 1)
		y += _gap(r)

func _draw_thanks() -> void:
	var a := clampf(t / 1.5, 0.0, 1.0) if t < 7.0 else clampf(1.0 - (t - 7.0) / 1.5, 0.0, 1.0)
	PixelFont.draw_centered(self, 320, 120, "THANK YOU FOR PLAYING", Color(GOLD, a), 3)
	var ls := Hud.wrap_lines(THANKS, 100)
	for k in ls.size():
		PixelFont.draw_centered(self, 320, 156 + k * 10, ls[k], Color(BONE, a))
	PixelFont.draw_centered(self, 320, 156 + ls.size() * 10 + 14, "RILEY & 506CLICKS", Color(ASH, a))

## The memorial: her photo framed on the left, the words on the right. Static so a test or a
## screenshot can draw it anywhere.
static func draw_memorial(ci: CanvasItem, tex: Texture2D, a: float, show_continue: bool) -> void:
	var oy := 40.0                     # the whole of it, down to the middle of the screen
	var fr := Rect2(52, 64 + oy, 129, 140)
	ci.draw_rect(fr, Color(0.047, 0.043, 0.055, a))
	ci.draw_rect(fr.grow(1), Color(ASH, a), false, 1.0)
	if tex != null: ci.draw_texture_rect(tex, Rect2(fr.position + Vector2(2, 2), Vector2(125, 136)), false, Color(1, 1, 1, a))
	var tx := 214.0
	PixelFont.draw(ci, Vector2(tx, 60 + oy), "IN MEMORIAM", Color(ASH, a))
	PixelFont.draw(ci, Vector2(tx, 72 + oy), "YVETTE COLLETTE", Color(BONE, a), 3)
	PixelFont.draw(ci, Vector2(tx, 96 + oy), "AUGUST 20TH 1953  -  OCTOBER 7TH 2026", Color("b8b2a6", a))
	PixelFont.draw(ci, Vector2(tx, 112 + oy), "GRANDMOTHER, SISTER, WIFE AND MOTHER.", Color(BONE, a))
	ci.draw_rect(Rect2(tx, 128 + oy, 80, 1), Color("5a5650", a))
	PixelFont.draw(ci, Vector2(tx, 136 + oy), "JOHN 14:27", Color(ASH, a))
	var ls := Hud.wrap_lines(VERSE, 98)
	for k in ls.size():
		PixelFont.draw(ci, Vector2(tx, 148 + oy + k * 10), ls[k], Color("d8d2c6", a))
	PixelFont.draw(ci, Vector2(tx, 148 + oy + ls.size() * 10 + 18), "I LOVE YOU MEMERE, I'LL KEEP MAKING YOU PROUD", Color(GOLD, a))
	if show_continue:
		var hint := Hints.fmt("{ui_accept}: CONTINUE")
		PixelFont.draw_centered(ci, 320, 330, hint, Color(ASH, a))
