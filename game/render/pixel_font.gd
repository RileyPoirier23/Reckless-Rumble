## A tiny 3×5 pixel font, drawn rect by rect, so the HUD stays crisp at any scale.
class_name PixelFont
extends RefCounted

# each glyph: 5 rows of 3 bits (MSB = left)
const G := {
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7], "3": [7, 1, 7, 1, 7], "4": [5, 5, 7, 1, 1],
	"5": [7, 4, 7, 1, 7], "6": [7, 4, 7, 5, 7], "7": [7, 1, 1, 2, 2], "8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 7],
	"A": [2, 5, 7, 5, 5], "B": [6, 5, 6, 5, 6], "C": [7, 4, 4, 4, 7], "D": [6, 5, 5, 5, 6], "E": [7, 4, 6, 4, 7],
	"F": [7, 4, 6, 4, 4], "G": [7, 4, 5, 5, 7], "H": [5, 5, 7, 5, 5], "I": [7, 2, 2, 2, 7], "J": [1, 1, 1, 5, 7],
	"K": [5, 5, 6, 5, 5], "L": [4, 4, 4, 4, 7], "M": [5, 7, 7, 5, 5], "N": [6, 5, 5, 5, 5], "O": [7, 5, 5, 5, 7],
	"P": [7, 5, 7, 4, 4], "Q": [7, 5, 5, 7, 1], "R": [6, 5, 6, 5, 5], "S": [7, 4, 7, 1, 7], "T": [7, 2, 2, 2, 2],
	"U": [5, 5, 5, 5, 7], "V": [5, 5, 5, 5, 2], "W": [5, 5, 7, 7, 5], "X": [5, 5, 2, 5, 5], "Y": [5, 5, 2, 2, 2],
	"Z": [7, 1, 2, 4, 7], " ": [0, 0, 0, 0, 0], ".": [0, 0, 0, 0, 2], ",": [0, 0, 0, 2, 4], ":": [0, 2, 0, 2, 0],
	"-": [0, 0, 7, 0, 0], "+": [0, 2, 7, 2, 0], "/": [1, 1, 2, 4, 4], "%": [5, 1, 2, 4, 5], "°": [2, 5, 2, 0, 0],
	"!": [2, 2, 2, 0, 2], ";": [0, 2, 0, 2, 4], "?": [7, 1, 2, 0, 2], "(": [1, 2, 2, 2, 1], ")": [4, 2, 2, 2, 4], "'": [2, 2, 0, 0, 0],
	"\"": [5, 5, 0, 0, 0], "=": [0, 7, 0, 7, 0], "<": [1, 2, 4, 2, 1], ">": [4, 2, 1, 2, 4], "#": [5, 7, 5, 7, 5],
	"[": [3, 2, 2, 2, 3], "]": [6, 2, 2, 2, 6], "_": [0, 0, 0, 0, 7], "*": [5, 2, 7, 2, 5], "&": [2, 5, 2, 5, 3], "$": [7, 6, 7, 3, 7],
}

static func width(text: String, scale := 1) -> int:
	return text.length() * 4 * scale - scale

## Draws `text` on `ci` (a CanvasItem inside its _draw) with its top-left at `pos`.
static func draw(ci: CanvasItem, pos: Vector2, text: String, color: Color, scale := 1, shadow := Color(0, 0, 0, 0)) -> void:
	if shadow.a > 0.0:
		draw(ci, pos + Vector2(scale, scale), text, shadow, scale)
	var x := pos.x
	for ch in text.to_upper():
		var rows: Array = G.get(ch, G["?"])
		for ry in 5:
			var bits: int = rows[ry]
			for rx in 3:
				if bits & (4 >> rx):
					ci.draw_rect(Rect2(x + rx * scale, pos.y + ry * scale, scale, scale), color)
		x += 4 * scale

static func draw_centered(ci: CanvasItem, center_x: float, y: float, text: String, color: Color, scale := 1, shadow := Color(0, 0, 0, 0)) -> void:
	draw(ci, Vector2(roundf(center_x - width(text, scale) / 2.0), y), text, color, scale, shadow)
