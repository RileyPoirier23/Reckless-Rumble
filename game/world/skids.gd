## Tire marks: every sliding tire leaves a mark that stays (until there are too many), and on soft
## ground (mud, snow, grass, gravel) every tire leaves its track, sliding or not: ruts.
class_name Skids
extends Node2D

const MAX := 9000
var segs := PackedVector2Array()      # pairs: from, to
var alphas := PackedFloat32Array()
var colors := PackedColorArray()
var widths := PackedFloat32Array()
var last := {}                        # wheel id -> last point

func mark(id: int, p: Vector2, strength: float, col: Color, width := 3.0, spacing := 0.0) -> void:
	if strength <= 0.0:
		last.erase(id)
		return
	if last.has(id) and spacing > 0.0 and last[id].distance_to(p) < spacing: return     # (a rut's laid in longer pieces)
	if last.has(id) and last[id].distance_to(p) < 60.0:
		segs.append(last[id])
		segs.append(p)
		alphas.append(clampf(strength, 0.15, 0.7))
		colors.append(col)
		widths.append(width)
		if alphas.size() > MAX:
			segs = segs.slice(2)
			alphas = alphas.slice(1)
			colors = colors.slice(1)
			widths = widths.slice(1)
	last[id] = p
	queue_redraw()

func clear() -> void:
	segs.clear()
	alphas.clear()
	colors.clear()
	widths.clear()
	last.clear()
	queue_redraw()

## One draw command a width, not one a mark: thousands of marks (a long burnout, then a drive)
## used to be thousands of commands, and past the renderer's budget for a frame it crashed.
func _draw() -> void:
	# (packed arrays copy on assignment: each group's arrays are built in locals and put back)
	var pts_by_w := {}                # width -> points (pairs)
	var cols_by_w := {}               # width -> a colour a segment
	for i in alphas.size():
		var c := colors[i]
		c.a = alphas[i]
		var w: float = widths[i] if i < widths.size() else 3.0
		var pts: PackedVector2Array = pts_by_w.get(w, PackedVector2Array())
		var cs: PackedColorArray = cols_by_w.get(w, PackedColorArray())
		pts.append(segs[i * 2])
		pts.append(segs[i * 2 + 1])
		cs.append(c)
		pts_by_w[w] = pts
		cols_by_w[w] = cs
	for w in pts_by_w:
		draw_multiline_colors(pts_by_w[w], cols_by_w[w], float(w))

## What a tire leaves rolling over soft ground: [colour, strength, width px], or [] on the hard stuff.
static func rut(surface: String, snow_cover: float) -> Array:
	match surface:
		"mud": return [Color("2e2218"), 0.6, 4.0]
		"snow": return [Color("8a96a8"), 0.5, 4.5]
		"grass":
			if snow_cover > 0.3: return [Color("8a96a8"), 0.45, 4.5]
			return [Color("24381c"), 0.28, 3.5]
		"gravel", "dirt": return [Color("5a5244"), 0.3, 3.5]
	return []
