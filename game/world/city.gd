## Two blocks of Port Rumble, drawn by code: roads, sidewalks, the Covington Auto lot,
## buildings, streetlights, and what each season does to all of it (and to the grip).
class_name City
extends Node2D

const PX := CarArt.PX
const SIZE := Vector2(380, 240)          # metres
const ROAD := 16.0

# seasons: what the air is like and what's on the road
const SEASONS := {
	"summer": { "ambient": 26.0, "label": "SUMMER" },
	"fall":   { "ambient": 9.0,  "label": "FALL" },
	"winter": { "ambient": -12.0, "label": "WINTER" },
	"spring": { "ambient": 6.0,  "label": "SPRING" },
}
const ORDER := ["summer", "fall", "winter", "spring"]

var season := "summer"
var roads: Array[Rect2] = []             # metres
var lots: Array[Rect2] = []
var sidewalks: Array[Rect2] = []
var buildings: Array[Dictionary] = []
var lights: Array[Vector2] = []          # streetlight positions (metres)
var noise := FastNoiseLite.new()
var asphalt: ImageTexture
var ysort: Node2D                        # buildings, poles and cars live here (sorted by y)
var light_nodes: Array[PointLight2D] = []
var window_nodes: Array[Node2D] = []

func _init() -> void:
	noise.seed = 506
	noise.frequency = 0.05
	_layout()
	asphalt = _asphalt_tile()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _layout() -> void:
	# the street grid: North St, Main St, West Rd, Covington Ave, Harbour Rd
	roads = [
		Rect2(0, 0, SIZE.x, ROAD), Rect2(0, SIZE.y - ROAD, SIZE.x, ROAD),
		Rect2(0, 0, ROAD, SIZE.y), Rect2(182, 0, ROAD, SIZE.y), Rect2(SIZE.x - ROAD, 0, ROAD, SIZE.y),
		Rect2(ROAD, 112, 166, 8),        # the alley through block A
	]
	lots = [Rect2(204, 92, 154, 126)]     # Covington Auto's lot (burnouts welcome after hours)
	sidewalks = [Rect2(ROAD, ROAD, 166, 208), Rect2(198, ROAD, 166, 208)]
	# buildings: footprint (metres), wall height (metres), look
	buildings = [
		{ "r": Rect2(212, 26, 64, 52), "h": 9.0, "kind": "garage", "name": "COVINGTON AUTO" },
		{ "r": Rect2(296, 28, 58, 44), "h": 7.0, "kind": "coffee", "name": "TIM BURTONS" },
		{ "r": Rect2(24, 24, 44, 82), "h": 14.0, "kind": "apts", "name": "" },
		{ "r": Rect2(74, 24, 46, 82), "h": 11.0, "kind": "houses", "name": "" },
		{ "r": Rect2(126, 24, 50, 82), "h": 16.0, "kind": "apts", "name": "" },
		{ "r": Rect2(24, 126, 70, 90), "h": 18.0, "kind": "apts", "name": "" },
		{ "r": Rect2(100, 126, 34, 40), "h": 7.0, "kind": "dep", "name": "DEP 24H" },
		{ "r": Rect2(100, 172, 76, 44), "h": 10.0, "kind": "houses", "name": "" },
		{ "r": Rect2(140, 126, 36, 40), "h": 8.0, "kind": "shop", "name": "PAWN" },
	]
	for x in range(30, int(SIZE.x), 44):
		lights.append(Vector2(x, ROAD + 1.0))
		lights.append(Vector2(x + 22, SIZE.y - ROAD - 1.0))
	for y in range(40, int(SIZE.y) - 20, 50):
		lights.append(Vector2(198 + 1.0, y))

## Builds the nodes that need to be real (collision, y-sorting, lights). Call once.
func build(parent_ysort: Node2D) -> void:
	ysort = parent_ysort
	for b in buildings:
		var n := Building.new()
		n.setup(b)
		ysort.add_child(n)
		window_nodes.append(n.windows)
	# the edge of the world
	var walls := StaticBody2D.new()
	add_child(walls)
	for r in [Rect2(-10, -10, SIZE.x + 20, 10), Rect2(-10, SIZE.y, SIZE.x + 20, 10), Rect2(-10, 0, 10, SIZE.y), Rect2(SIZE.x, 0, 10, SIZE.y)]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size * PX
		cs.shape = shape
		cs.position = (r.position + r.size / 2.0) * PX
		walls.add_child(cs)
	var tex := _light_tex(Color(1.0, 0.72, 0.38))
	for p in lights:
		var pole := Pole.new()
		pole.position = p * PX
		ysort.add_child(pole)
		var l := PointLight2D.new()
		l.texture = tex
		l.texture_scale = 2.4
		l.energy = 1.1
		l.position = p * PX + Vector2(0, -14)
		l.color = Color(1.0, 0.75, 0.45)
		add_child(l)
		light_nodes.append(l)

func set_season(s: String) -> void:
	season = s
	queue_redraw()

func ambient() -> float:
	return SEASONS[season].ambient

func is_wet() -> bool:
	return season == "fall" or season == "spring"

func set_night(night: bool) -> void:
	for l in light_nodes: l.visible = night
	for w in window_nodes: w.visible = night

## What's under the tires at this point (metres).
func surface_at(m: Vector2) -> String:
	var on_road := false
	for r in roads + lots:
		if r.has_point(m): on_road = true
	var n := noise.get_noise_2d(m.x, m.y)
	match season:
		"summer":
			return "dry" if on_road else "gravel"
		"fall":
			if n > 0.35: return "leaves"
			return "wet" if on_road else "gravel"
		"winter":
			if not on_road: return "snow"
			# packed snow everywhere; black ice in the shade and at the corners
			if n > 0.42 or _at_intersection(m): return "ice"
			return "snow"
		"spring":
			return "wet" if on_road else "gravel"
	return "dry"

func _at_intersection(m: Vector2) -> bool:
	var xs := [8.0, 190.0, SIZE.x - 8.0]
	var ys := [8.0, SIZE.y - 8.0]
	for x in xs:
		for y in ys:
			if absf(m.x - x) < 9.0 and absf(m.y - y) < 9.0: return true
	return false

# ------------------------------------------------------------------ drawing

func _asphalt_tile() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 64:
		for x in 64:
			var v := 0.2 + rng.randf() * 0.035
			if rng.randf() < 0.03: v += 0.05
			if rng.randf() < 0.015: v -= 0.05
			img.set_pixel(x, y, Color(v, v, v * 1.05))
	return ImageTexture.create_from_image(img)

func _light_tex(c: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(c.r, c.g, c.b, 1.0), Color(c.r, c.g, c.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

func _px(r: Rect2) -> Rect2:
	return Rect2(r.position * PX, r.size * PX)

func _draw() -> void:
	var winter := season == "winter"
	var wet := is_wet()
	var fall := season == "fall"
	# the ground beyond: grass, dirt or snow
	var ground := Color("3d4a2c") if not winter else Color("d8dde4")
	if fall: ground = Color("5a4a2a")
	if season == "spring": ground = Color("4a4630")
	draw_rect(Rect2(Vector2(-400, -400), SIZE * PX + Vector2(800, 800)), ground)
	# sidewalks / block interiors
	for s in sidewalks:
		draw_rect(_px(s), Color("8f8c86") if not winter else Color("e4e8ee"))
	# asphalt
	var tint := Color(1, 1, 1)
	if wet: tint = Color(0.72, 0.74, 0.8)
	if winter: tint = Color(2.3, 2.35, 2.5)
	for r in roads + lots:
		draw_texture_rect(asphalt, _px(r), true, tint)
	# curbs
	for s in sidewalks:
		draw_rect(_px(s), Color("b0aca2") if not winter else Color("f2f4f8"), false, 2.0)
	_markings(winter)
	_lot_lines(winter)
	if winter: _winter()
	if wet: _puddles()
	if fall: _leaves()
	if season == "spring": _potholes()

func _markings(winter: bool) -> void:
	var yellow := Color("d8b23a") if not winter else Color(0.85, 0.75, 0.45, 0.35)
	var white := Color("d8d8d0") if not winter else Color(1, 1, 1, 0.25)
	# double yellow down the middle of the big roads, dashed white elsewhere
	for r in [roads[0], roads[1]]:
		var y: float = (r.position.y + r.size.y / 2.0) * PX
		for x in range(int(r.position.x * PX), int(r.end.x * PX), 1):
			if not _in_intersection_px(Vector2(x, y)):
				draw_rect(Rect2(x, y - 2, 1, 1), yellow)
				draw_rect(Rect2(x, y + 1, 1, 1), yellow)
	for r in [roads[2], roads[3], roads[4]]:
		var x: float = (r.position.x + r.size.x / 2.0) * PX
		for y in range(int(r.position.y * PX), int(r.end.y * PX), 24):
			if not _in_intersection_px(Vector2(x, y)):
				draw_rect(Rect2(x - 1, y, 2, 12), white)
	# crosswalks at Covington Ave and Main
	for i in range(0, 14):
		draw_rect(Rect2((182 + 1.0 + i) * PX, (SIZE.y - ROAD - 4) * PX, PX * 0.5, 3 * PX), white)

func _in_intersection_px(p: Vector2) -> bool:
	return _at_intersection(p / PX) or (absf(p.x / PX - 190.0) < 9.0)

func _lot_lines(winter: bool) -> void:
	var c := Color("d8d8d0") if not winter else Color(1, 1, 1, 0.2)
	var lot: Rect2 = lots[0]
	for i in range(0, 14):
		var x := (lot.position.x + 6 + i * 3.2) * PX
		draw_rect(Rect2(x, lot.position.y * PX + 4, 1, 5.5 * PX), c)
		draw_rect(Rect2(x, (lot.end.y - 5.5) * PX - 4, 1, 5.5 * PX), c)
	PixelFont.draw(self, (lot.position + Vector2(60, 58)) * PX, "COVINGTON AUTO - CUSTOMERS ONLY", Color(c.r, c.g, c.b, 0.6), 2)

func _winter() -> void:
	# plow banks along every curb, tire ruts down the lanes
	for s in sidewalks:
		draw_rect(_px(Rect2(s.position - Vector2(1.2, 1.2), s.size + Vector2(2.4, 2.4))), Color(0.95, 0.97, 1.0), false, 1.2 * PX)
	for r in [roads[0], roads[1]]:
		for lane in [0.3, 0.7]:
			var y: float = (r.position.y + r.size.y * lane) * PX
			draw_rect(Rect2(r.position.x * PX, y - 6, r.size.x * PX, 3), Color(0.62, 0.64, 0.7, 0.55))
			draw_rect(Rect2(r.position.x * PX, y + 4, r.size.x * PX, 3), Color(0.62, 0.64, 0.7, 0.55))
	# black ice: glossy patches
	for r in roads + lots:
		for y in range(int(r.position.y), int(r.end.y), 2):
			for x in range(int(r.position.x), int(r.end.x), 2):
				var m := Vector2(x, y)
				if noise.get_noise_2d(m.x, m.y) > 0.42 or _at_intersection(m):
					draw_rect(Rect2(m * PX, Vector2(2, 2) * PX), Color(0.55, 0.65, 0.8, 0.45))

func _puddles() -> void:
	for r in roads + lots:
		for y in range(int(r.position.y), int(r.end.y), 3):
			for x in range(int(r.position.x), int(r.end.x), 3):
				if noise.get_noise_2d(x * 1.7, y * 1.7) > 0.5:
					draw_rect(Rect2(Vector2(x, y) * PX, Vector2(3, 2) * PX), Color(0.35, 0.42, 0.55, 0.5))

func _leaves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var cols := [Color("c8642a"), Color("d8a03a"), Color("8a3a22"), Color("b8502a")]
	for i in 2600:
		var m := Vector2(rng.randf() * SIZE.x, rng.randf() * SIZE.y)
		if noise.get_noise_2d(m.x, m.y) > 0.2 or rng.randf() < 0.25:
			draw_rect(Rect2(m * PX, Vector2(2, 1 + rng.randi() % 2)), cols[rng.randi() % cols.size()])

func _potholes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 70:
		var r: Rect2 = roads[rng.randi() % roads.size()]
		var m := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		draw_circle(m * PX, 4 + rng.randf() * 4, Color(0.1, 0.1, 0.11))
		draw_circle(m * PX + Vector2(-1, -1), 3, Color(0.25, 0.3, 0.38, 0.6))


## A building in 3/4 view: roof lifted by its wall height, the south wall showing.
## Its origin is the south edge of the footprint so y-sorting puts cars in front or behind.
class Building extends StaticBody2D:
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
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = fp.size
		cs.shape = shape
		cs.position = fp.position + fp.size / 2.0
		add_child(cs)
		# lit windows at night: unshaded so the darkness doesn't touch them
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
			"dep": return [Color("4a6a5a"), Color("36504a"), Color("3c3a40")]
			"shop": return [Color("5a5470"), Color("443e58"), Color("3c3a40")]
			"houses": return [Color("6a7a8a"), Color("4e5a68"), Color("5a3a34")]
		return [Color("7a6a5a"), Color("5a4e42"), Color("3a383e")]

	func _draw() -> void:
		var c := colors()
		var wall := Rect2(fp.position.x, fp.end.y - hpx, fp.size.x, hpx)
		var roof := Rect2(fp.position.x, fp.position.y - hpx, fp.size.x, fp.size.y)
		# shadow on the ground to the south-east
		draw_rect(Rect2(fp.position + Vector2(6, 4), fp.size), Color(0, 0, 0, 0.25))
		draw_rect(wall, c[0])
		# windows / doors on the south wall
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
				draw_rect(Rect2(bx, wall.end.y - 30, 110, 30), Color("8a8a84"))
				for k in 6: draw_rect(Rect2(bx, wall.end.y - 30 + k * 5, 110, 1), Color("6a6a66"))
		draw_rect(roof, c[2])
		draw_rect(roof, c[1], false, 3.0)
		# roof clutter: vents, an AC unit, tar seams
		var rng := RandomNumberGenerator.new()
		rng.seed = int(fp.size.x * 7 + fp.size.y)
		for i in int(fp.size.x * fp.size.y / 9000.0) + 2:
			var p := roof.position + Vector2(rng.randf() * (roof.size.x - 30) + 10, rng.randf() * (roof.size.y - 30) + 10)
			draw_rect(Rect2(p, Vector2(12 + rng.randi() % 10, 8 + rng.randi() % 6)), c[2].lightened(0.15))
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 3)), c[2].darkened(0.3))
		if data.name != "":
			var sign_w := PixelFont.width(data.name, 2) + 10
			var sp := Vector2(fp.position.x + (fp.size.x - sign_w) / 2.0, wall.position.y - 6)
			draw_rect(Rect2(sp, Vector2(sign_w, 16)), Color("1a1418"))
			PixelFont.draw(self, sp + Vector2(5, 3), data.name, Color("f2d36a") if data.kind != "coffee" else Color("f4ece0"), 2)

class Windows extends Node2D:
	var building: Building
	func _draw() -> void:
		var fp := building.fp
		var hpx := building.hpx
		var wall_y := fp.end.y - hpx
		var rows := maxi(1, int(hpx / 14.0))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(fp.size.x)
		for row in rows:
			for x in range(int(fp.position.x) + 6, int(fp.end.x) - 8, 14):
				var y := wall_y + 4 + row * 14
				if y + 8 < fp.end.y - 2 and rng.randf() < 0.55:
					draw_rect(Rect2(x, y, 7, 8), Color("f2c86a") if rng.randf() < 0.8 else Color("9ad0f0"))
		if building.data.name != "":
			var sign_w := PixelFont.width(building.data.name, 2) + 10
			var sp := Vector2(fp.position.x + (fp.size.x - sign_w) / 2.0, wall_y - 6)
			PixelFont.draw(self, sp + Vector2(5, 3), building.data.name, Color("ffe68a"), 2)

class Pole extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-1, -16, 2, 16), Color("2a2a2e"))
		draw_rect(Rect2(-1, -17, 6, 2), Color("2a2a2e"))
		draw_rect(Rect2(3, -16, 3, 1), Color("f4e0a0"))
