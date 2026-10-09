## Tire marks: every sliding tire leaves a mark that stays (until there are too many).
class_name Skids
extends Node2D

const MAX := 9000
var segs := PackedVector2Array()      # pairs: from, to
var alphas := PackedFloat32Array()
var colors := PackedColorArray()
var last := {}                        # wheel id -> last point

func mark(id: int, p: Vector2, strength: float, col: Color) -> void:
	if strength <= 0.0:
		last.erase(id)
		return
	if last.has(id) and last[id].distance_to(p) < 60.0:
		segs.append(last[id])
		segs.append(p)
		alphas.append(clampf(strength, 0.15, 0.7))
		colors.append(col)
		if alphas.size() > MAX:
			segs = segs.slice(2)
			alphas = alphas.slice(1)
			colors = colors.slice(1)
	last[id] = p
	queue_redraw()

func clear() -> void:
	segs.clear()
	alphas.clear()
	colors.clear()
	last.clear()
	queue_redraw()

func _draw() -> void:
	for i in alphas.size():
		var c := colors[i]
		c.a = alphas[i]
		draw_line(segs[i * 2], segs[i * 2 + 1], c, 3.0)
