## A heavier 5x7 pixel font for captions and title cards: the death-screen meme captions, mostly.
## `bold` doubles each column for that thick old-school caption look.
class_name BigFont
extends RefCounted

# each glyph: 7 rows of 5 bits (MSB = left)
const G := {
	"A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30], "C": [14, 17, 16, 16, 16, 17, 14],
	"D": [30, 17, 17, 17, 17, 17, 30], "E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17], "I": [14, 4, 4, 4, 4, 4, 14],
	"J": [7, 2, 2, 2, 2, 18, 12], "K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31],
	"M": [17, 27, 21, 21, 17, 17, 17], "N": [17, 17, 25, 21, 19, 17, 17], "O": [14, 17, 17, 17, 17, 17, 14],
	"P": [30, 17, 17, 30, 16, 16, 16], "Q": [14, 17, 17, 17, 21, 18, 13], "R": [30, 17, 17, 30, 20, 18, 17],
	"S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4], "U": [17, 17, 17, 17, 17, 17, 14],
	"V": [17, 17, 17, 17, 17, 10, 4], "W": [17, 17, 17, 21, 21, 21, 10], "X": [17, 17, 10, 4, 10, 17, 17],
	"Y": [17, 17, 10, 4, 4, 4, 4], "Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14], "2": [14, 17, 1, 2, 4, 8, 31],
	"3": [31, 2, 4, 2, 1, 17, 14], "4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14],
	"6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8], "8": [14, 17, 17, 14, 17, 17, 14],
	"9": [14, 17, 17, 15, 1, 2, 12],
	" ": [0, 0, 0, 0, 0, 0, 0], ".": [0, 0, 0, 0, 0, 12, 12], ",": [0, 0, 0, 0, 12, 4, 8],
	"'": [4, 4, 8, 0, 0, 0, 0], "\"": [10, 10, 0, 0, 0, 0, 0], "!": [4, 4, 4, 4, 4, 0, 4],
	"?": [14, 17, 1, 2, 4, 0, 4], "-": [0, 0, 0, 31, 0, 0, 0], ":": [0, 12, 12, 0, 12, 12, 0],
	"/": [1, 1, 2, 4, 8, 16, 16], "(": [2, 4, 8, 8, 8, 4, 2], ")": [8, 4, 2, 2, 2, 4, 8],
	"$": [4, 15, 20, 14, 5, 30, 4], "%": [24, 25, 2, 4, 8, 19, 3], "&": [12, 18, 20, 8, 21, 18, 13],
	"#": [10, 10, 31, 10, 31, 10, 10], "+": [0, 4, 4, 31, 4, 4, 0], ";": [0, 12, 12, 0, 12, 4, 8],
}

static func advance(bold: bool) -> int:
	return 7 if bold else 6

static func width(text: String, scale := 1, bold := false) -> int:
	return (text.length() * advance(bold) - 1) * scale

static func draw(ci: CanvasItem, pos: Vector2, text: String, color: Color, scale := 1, bold := false, shadow := Color(0, 0, 0, 0)) -> void:
	if shadow.a > 0.0:
		draw(ci, pos + Vector2(scale, scale), text, shadow, scale, bold)
	var x := pos.x
	var bw := 2 if bold else 1
	for ch in text.to_upper():
		var rows: Array = G.get(ch, G["?"])
		for ry in 7:
			var bits: int = rows[ry]
			for rx in 5:
				if bits & (16 >> rx):
					ci.draw_rect(Rect2(x + rx * scale, pos.y + ry * scale, scale * bw, scale), color)
		x += advance(bold) * scale

static func draw_centered(ci: CanvasItem, cx: float, y: float, text: String, color: Color, scale := 1, bold := false, shadow := Color(0, 0, 0, 0)) -> void:
	draw(ci, Vector2(roundf(cx - width(text, scale, bold) / 2.0), y), text, color, scale, bold, shadow)

## Word-wrap to at most `max_w` pixels wide.
static func wrap(text: String, max_w: int, scale := 1, bold := false) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" "):
		var trial := word if cur == "" else cur + " " + word
		if width(trial, scale, bold) <= max_w or cur == "": cur = trial
		else:
			out.append(cur)
			cur = word
	if cur != "": out.append(cur)
	return out
