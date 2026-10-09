## A building in 3/4 view: the roof lifted by the wall height, the south wall showing.
## Its origin is the south edge of the footprint, so y-sorting puts cars in front or behind.
class_name BuildingNode
extends StaticBody2D

const HOUSE_COLS := [Color("6a7a8a"), Color("8a6a5a"), Color("c8c0a8"), Color("5a7a5a"), Color("8a8a6a"), Color("a85a4a")]

var data: Dictionary
var fp: Rect2           # footprint in px, relative to the origin
var hpx: float
var windows: Node2D

func setup(b: Dictionary) -> void:
	data = b
	var r: Rect2 = b.r
	position = Vector2(r.position.x, r.end.y) * CarArt.PX
	fp = Rect2(Vector2(0, -r.size.y * CarArt.PX), r.size * CarArt.PX)
	hpx = float(b.h) * CarArt.PX * 0.5
	if b.kind != "pumps":
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = fp.size
		cs.shape = shape
		cs.position = fp.position + fp.size / 2.0
		add_child(cs)
	windows = Windows.new()
	windows.building = self
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	windows.material = mat
	windows.visible = false
	add_child(windows)

func colors() -> Array:
	match data.kind:
		"garage": return [Color("6a5a48"), Color("4e4234"), Color("3a3640")]
		"coffee": return [Color("8a2a22"), Color("6a201a"), Color("4a4448")]
		"shop": return [Color("5a5470"), Color("443e58"), Color("3c3a40")]
		"house":
			var c: Color = HOUSE_COLS[int(data.get("color", 0)) % HOUSE_COLS.size()]
			return [c, c.darkened(0.25), Color("4a3a34")]
		"farmhouse": return [Color("e8e4dc"), Color("b8b4ac"), Color("3a3a44")]
		"barn": return [Color("8a2a22"), Color("6a201a"), Color("5a5a5e")]
		"church": return [Color("ece8e0"), Color("c8c4bc"), Color("4a4a54")]
		"warehouse": return [Color("6a6e74"), Color("54585e"), Color("5e6268")]
		"bigbox", "mall": return [Color("b8b0a0"), Color("8a8478"), Color("6a6a6e")]
		"arena": return [Color("4a5a6a"), Color("3a4654"), Color("8a9098")]
		"casino": return [Color("2a1a3a"), Color("1e1228"), Color("3a2a4a")]
		"plant": return [Color("9a948a"), Color("7a746a"), Color("6a665e")]
		"tower": return [Color("b8b8bc"), Color("8a8a90"), Color("c8c8cc")]
		"pumps": return [Color("d8d8d0"), Color("a8a8a0"), Color("e8e8e0")]
	return [Color("7a6a5a"), Color("5a4e42"), Color("3a383e")]

func _draw() -> void:
	var c := colors()
	if data.kind == "tower":
		# a lattice radio tower, seen from above: a tall thin shadow and a red tip
		draw_line(Vector2(fp.get_center().x, fp.end.y), Vector2(fp.get_center().x + 40, fp.end.y + 30), Color(0, 0, 0, 0.3), 3.0)
		for i in 8: draw_rect(Rect2(fp.get_center().x - 2, fp.end.y - i * 30 - 30, 4, 28), c[0] if i % 2 == 0 else Color("c83a2a"))
		return
	var wall := Rect2(fp.position.x, fp.end.y - hpx, fp.size.x, hpx)
	var roof := Rect2(fp.position.x, fp.position.y - hpx, fp.size.x, fp.size.y)
	draw_rect(Rect2(fp.position + Vector2(hpx * 0.5, 4), fp.size), Color(0, 0, 0, 0.22))
	draw_rect(wall, c[0])
	var rows := maxi(1, int(hpx / 14.0))
	for row in rows:
		for x in range(int(fp.position.x) + 6, int(fp.end.x) - 8, 14):
			var y := wall.position.y + 4 + row * 14
			if y + 8 < wall.end.y - 2:
				draw_rect(Rect2(x, y, 7, 8), Color("1e2430"))
				draw_rect(Rect2(x, y, 7, 2), Color("3a4658"))
	if data.kind == "garage":
		for i in 3:
			var bx := fp.position.x + 20 + i * 150
			if bx + 110 > fp.end.x: break
			draw_rect(Rect2(bx, wall.end.y - 30, 110, 30), Color("8a8a84"))
			for k in 6: draw_rect(Rect2(bx, wall.end.y - 30 + k * 5, 110, 1), Color("6a6a66"))
	if data.kind in ["house", "farmhouse"]:
		# a pitched roof: two slopes and a ridge
		draw_rect(roof, c[2])
		draw_rect(Rect2(roof.position, Vector2(roof.size.x, roof.size.y / 2.0)), c[2].lightened(0.12))
		draw_line(Vector2(roof.position.x, roof.get_center().y), Vector2(roof.end.x, roof.get_center().y), c[2].darkened(0.3), 2.0)
		draw_rect(Rect2(wall.get_center().x - 5, wall.end.y - 16, 10, 16), Color("3a2a22"))
		return
	if data.kind == "barn":
		draw_rect(roof, c[2])
		draw_line(Vector2(roof.position.x, roof.get_center().y), Vector2(roof.end.x, roof.get_center().y), c[2].lightened(0.2), 3.0)
		draw_rect(Rect2(wall.get_center().x - 18, wall.end.y - 36, 36, 36), c[1])
		draw_line(Vector2(wall.get_center().x - 18, wall.end.y - 36), Vector2(wall.get_center().x + 18, wall.end.y), Color("e8e4dc"), 2.0)
		draw_line(Vector2(wall.get_center().x + 18, wall.end.y - 36), Vector2(wall.get_center().x - 18, wall.end.y), Color("e8e4dc"), 2.0)
		return
	if data.kind == "church":
		draw_rect(roof, c[2])
		var sx := roof.get_center().x
		draw_rect(Rect2(sx - 10, roof.end.y - 30, 20, 30), c[0])
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 12, roof.end.y - 30), Vector2(sx + 12, roof.end.y - 30), Vector2(sx, roof.end.y - 90)]), c[2].lightened(0.1))
		draw_rect(Rect2(sx - 1, roof.end.y - 110, 2, 20), Color("d8c870"))
		draw_rect(Rect2(sx - 6, roof.end.y - 104, 12, 2), Color("d8c870"))
		return
	draw_rect(roof, c[2])
	draw_rect(roof, c[1], false, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(fp.size.x * 7 + fp.size.y + position.x)
	for i in mini(14, int(fp.size.x * fp.size.y / 9000.0) + 2):
		var p := roof.position + Vector2(rng.randf() * maxf(roof.size.x - 30, 1) + 10, rng.randf() * maxf(roof.size.y - 30, 1) + 10)
		draw_rect(Rect2(p, Vector2(12 + rng.randi() % 10, 8 + rng.randi() % 6)), c[2].lightened(0.15))
		draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 3)), c[2].darkened(0.3))
	if data.kind in ["arena", "mall", "bigbox"]:
		for x in range(int(roof.position.x) + 20, int(roof.end.x) - 20, 60):
			draw_rect(Rect2(x, roof.position.y + 10, 30, roof.size.y - 20), c[2].lightened(0.08))
	if data.name != "" and data.kind != "pumps":
		var sign_w := PixelFont.width(data.name, 2) + 10
		var sp := Vector2(fp.position.x + (fp.size.x - sign_w) / 2.0, wall.position.y - 6)
		draw_rect(Rect2(sp, Vector2(sign_w, 16)), Color("1a1418"))
		var nc: Color = Color("f2d36a")
		if data.kind == "coffee": nc = Color("f4ece0")
		if data.get("neon") != null: nc = (data.neon as Color).darkened(0.2)
		PixelFont.draw(self, sp + Vector2(5, 3), data.name, nc, 2)

class Windows extends Node2D:
	var building: BuildingNode
	func _draw() -> void:
		var fp := building.fp
		var hpx := building.hpx
		var kind: String = building.data.kind
		if kind in ["tower", "pumps", "barn"]: return
		var wall_y := fp.end.y - hpx
		var rows := maxi(1, int(hpx / 14.0))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(fp.size.x + building.position.x)
		var lit := 0.55 if kind in ["apts", "house", "farmhouse", "shop"] else 0.3
		for row in rows:
			for x in range(int(fp.position.x) + 6, int(fp.end.x) - 8, 14):
				var y := wall_y + 4 + row * 14
				if y + 8 < fp.end.y - 2 and rng.randf() < lit:
					draw_rect(Rect2(x, y, 7, 8), Color("f2c86a") if rng.randf() < 0.75 else Color("9ad0f0"))
		var name: String = building.data.name
		if name != "":
			var sign_w := PixelFont.width(name, 2) + 10
			var sp := Vector2(fp.position.x + (fp.size.x - sign_w) / 2.0, wall_y - 6)
			var nc := Color("ffe68a")
			if building.data.get("neon") != null: nc = building.data.neon
			if kind == "casino": nc = Color.from_hsv(fmod(Time.get_ticks_msec() / 3000.0, 1.0), 0.7, 1.0)
			PixelFont.draw(self, sp + Vector2(5, 3), name, nc, 2)
