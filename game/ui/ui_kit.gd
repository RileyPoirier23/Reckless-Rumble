## The look every menu shares, so the title, the settings, the pause menu and the HUD read as one
## game: the palette, a panel (dark fill, a 1 px line round it, its name on a tab sitting on the
## top line, the way the loading and death screens already did it), the gold bar under whatever's
## picked, meters, and the key hints along the bottom.
##
## Text sizes, at 640x360: scale 1 is the 3x5 face (fine print only), scale 2 the 5x7 face (what
## you read: rows, descriptions, hints), and `title` the 5x7 face doubled (headings, the one thing
## to do now).
class_name UiKit
extends RefCounted

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")
const GREEN := Color("6fbf5a")

const BG := Color("0d0c10")                       # a full-screen menu's backdrop
const FILL := Color(0.04, 0.035, 0.05, 0.94)      # a panel's inside
const LINE := Color(1, 1, 1, 0.14)                # a panel's edge
const RULE := Color(1, 1, 1, 0.08)                # a divider inside a panel
const SEL := Color(0.85, 0.64, 0.25, 0.16)        # the picked row
const TRACK := Color(1, 1, 1, 0.1)                # an empty meter

const PAD := 10.0                                 # a panel's inner margin
const TAB_H := 14.0                               # a panel's name tab
const LINE_H := 10.0                              # a line of scale-2 text

## A panel: the fill, the line round it and, given a name, the tab with the name on it, sitting
## across the top line (so the name never eats into the panel's own room).
static func panel(ci: CanvasItem, r: Rect2, title := "", accent := GOLD, a := 1.0, fill := FILL) -> void:
	ci.draw_rect(r, Color(fill, fill.a * a))
	ci.draw_rect(r, Color(LINE, LINE.a * a), false, 1.0)
	if title != "": tab(ci, Vector2(r.position.x + 8, r.position.y - 6), title, accent, a)

## The name tab on its own: a dark chip in the accent with the name lit up on it.
static func tab(ci: CanvasItem, at: Vector2, title: String, accent := GOLD, a := 1.0) -> void:
	ci.draw_rect(Rect2(at, Vector2(PixelFont.width(title, 2) + 12, TAB_H)), Color(accent.darkened(0.55), 0.95 * a))
	PixelFont.draw(ci, at + Vector2(6, 3), title, Color(accent.lightened(0.2), a), 2)

## The picked row: a gold wash with a solid bar down its left edge, so it reads at a glance.
static func select(ci: CanvasItem, r: Rect2, a := 1.0) -> void:
	ci.draw_rect(r, Color(SEL, SEL.a * a))
	ci.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(GOLD, a))

## A meter: the track, the fill from the left, a hairline round it.
static func meter(ci: CanvasItem, r: Rect2, frac: float, col := GOLD, edge := Color(1, 1, 1, 0.18)) -> void:
	ci.draw_rect(r, TRACK)
	ci.draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * clampf(frac, 0.0, 1.0)), r.size.y)), col)
	ci.draw_rect(r, edge, false, 1.0)

## A meter that fills out from its middle (steering, an axis): -1 is full left, 1 full right.
static func meter_mid(ci: CanvasItem, r: Rect2, v: float, col := GOLD) -> void:
	ci.draw_rect(r, TRACK)
	var half := r.size.x / 2.0
	var w := roundf(absf(clampf(v, -1.0, 1.0)) * half)
	ci.draw_rect(Rect2(r.position.x + half - (w if v < 0.0 else 0.0), r.position.y, w, r.size.y), col)
	ci.draw_rect(Rect2(r.position.x + half, r.position.y - 1, 1, r.size.y + 2), Color(BONE, 0.5))
	ci.draw_rect(r, Color(1, 1, 1, 0.18), false, 1.0)

## A heading: the 5x7 face at two pixels a dot, 14 px tall, on a shadow.
static func title(ci: CanvasItem, at: Vector2, text: String, col := GOLD) -> void:
	PixelFont.draw_main(ci, at, text, col, 2, INK)

## Word-wraps `text` to lines no wider than `max_w` pixels in the heading size.
static func wrap_title(text: String, max_w: float) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" ", false):
		if cur == "": cur = word
		elif PixelFont.main_width(cur + " " + word) <= max_w: cur += " " + word
		else:
			out.append(cur)
			cur = word
	if cur != "": out.append(cur)
	return out

## The key hints along the bottom, "UP/DOWN: PICK  ENTER: GO": each key on a little cap in bone,
## what it does after it in ash. Centred on `cx`.
static func hints(ci: CanvasItem, cx: float, y: float, text: String, a := 1.0) -> void:
	var x := roundf(cx - hints_width(text) / 2.0)
	for part in _hint_parts(text):
		var k: String = part[0]
		var v: String = part[1]
		if k != "":
			var kw := PixelFont.width(k, 2)
			ci.draw_rect(Rect2(x, y - 1, kw + 6, 11), Color(1, 1, 1, 0.07 * a))
			ci.draw_rect(Rect2(x, y - 1, kw + 6, 11), Color(1, 1, 1, 0.16 * a), false, 1.0)
			PixelFont.draw(ci, Vector2(x + 3, y), k, Color(BONE, a), 2)
			x += kw + 10
		if v != "":
			PixelFont.draw(ci, Vector2(x, y), v, Color(ASH, a), 2)
			x += PixelFont.width(v, 2)
		x += 14

## How wide `hints` draws a line.
static func hints_width(text: String) -> float:
	var w := 0.0
	for part in _hint_parts(text):
		if String(part[0]) != "": w += PixelFont.width(String(part[0]), 2) + 10
		w += PixelFont.width(String(part[1]), 2) + 14
	return maxf(0.0, w - 14)

## "UP/DOWN: PICK  ENTER: GO" as [["UP/DOWN", "PICK"], ["ENTER", "GO"]]. A part with no colon is
## all words.
static func _hint_parts(text: String) -> Array:
	var out: Array = []
	for seg in text.split("  ", false):
		var s := seg.strip_edges()
		var k := s.rfind(": ")
		if k > 0: out.append([s.substr(0, k), s.substr(k + 2)])
		else: out.append(["", s])
	return out

## `text` cut short with "..." to fit `max_w` pixels at `scale` (untouched if it already fits).
static func fit(text: String, max_w: float, scale := 2) -> String:
	if PixelFont.width(text, scale) <= max_w: return text
	var t := text
	while t.length() > 0 and PixelFont.width(t + "...", scale) > max_w: t = t.substr(0, t.length() - 1)
	return t.strip_edges() + "..."

## Word-wraps `text` to lines no wider than `max_w` pixels at `scale`.
static func wrap(text: String, max_w: float, scale := 2) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" ", false):
		if cur == "": cur = word
		elif PixelFont.width(cur + " " + word, scale) <= max_w: cur += " " + word
		else:
			out.append(cur)
			cur = word
	if cur != "": out.append(cur)
	return out
