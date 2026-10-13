## Triangles piled up to reach the GPU as one command (one draw call), in the order they were
## added: quads, lines as thin quads, fans, circles. flush(ci) hands them to that canvas item.
## A building or a chunk layer drawn this way is a few commands, not a few hundred.
class_name TriBatch

var pts := PackedVector2Array()
var cols := PackedColorArray()
var idx := PackedInt32Array()

func clear() -> void:
	pts.clear()
	cols.clear()
	idx.clear()

func size() -> int:
	return idx.size() / 3

func tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var n := pts.size()
	pts.append(a)
	pts.append(b)
	pts.append(c)
	cols.append(col)
	cols.append(col)
	cols.append(col)
	idx.append(n)
	idx.append(n + 1)
	idx.append(n + 2)

func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	quad_cols(a, b, c, d, col, col, col, col)

func quad_cols(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var n := pts.size()
	pts.append(a)
	pts.append(b)
	pts.append(c)
	pts.append(d)
	cols.append(ca)
	cols.append(cb)
	cols.append(cc)
	cols.append(cd)
	idx.append(n)
	idx.append(n + 1)
	idx.append(n + 2)
	idx.append(n)
	idx.append(n + 2)
	idx.append(n + 3)

## A line as draw_line draws it: a quad `w` wide centred on the segment (1 px when w < 0).
func line(a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.0001: return
	var o := Vector2(-d.y, d.x) / L * (maxf(w, 1.0) * 0.5)
	quad(a + o, b + o, b - o, a - o, col)

func polyline(p: PackedVector2Array, col: Color, w := 1.0) -> void:
	for i in p.size() - 1: line(p[i], p[i + 1], col, w)

func rect(r: Rect2, col: Color) -> void:
	quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col)

func rect_outline(r: Rect2, col: Color, w := 1.0) -> void:
	polyline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]), col, w)

## A convex polygon (or any fan from its first point).
func fan(p: PackedVector2Array, col: Color) -> void:
	for i in range(1, p.size() - 1): tri(p[0], p[i], p[i + 1], col)

## A thin ring (draw_arc round the whole circle).
func ring(c: Vector2, r: float, col: Color, w := 1.0, segs := 12) -> void:
	var p := PackedVector2Array()
	for i in segs + 1: p.append(c + Vector2.from_angle(TAU * i / segs) * r)
	polyline(p, col, w)

func circle(c: Vector2, r: float, col: Color, segs := 12) -> void:
	var n := pts.size()
	pts.append(c)
	cols.append(col)
	for i in segs:
		pts.append(c + Vector2.from_angle(TAU * i / segs) * r)
		cols.append(col)
	for i in segs:
		idx.append(n)
		idx.append(n + 1 + i)
		idx.append(n + 1 + (i + 1) % segs)

## Everything so far onto `ci`, in one command; then empty, ready for more.
func flush(ci: CanvasItem) -> void:
	if idx.is_empty(): return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)
	clear()
