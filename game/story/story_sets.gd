## The cutscene sets, drawn by code in side view (640×360), with a little life in each:
## party lights, headlights through smoke, a lamp that buzzes, a TV that flickers.
class_name StorySets
extends RefCounted

static func draw(ci: CanvasItem, name: String, t: float) -> void:
	match name:
		"party": _party(ci, t)
		"airstrip": _airstrip(ci, t)
		"office": _office(ci, t)
		"lot_dusk": _lot_dusk(ci, t)
		"tims": _tims(ci, t)
		"apartment": _apartment(ci, t)
		"bay": _bay(ci, t)
		_: ci.draw_rect(Rect2(0, 0, 640, 360), Color("0b090d"))

## A car from the side: body, cabin, windows, wheels. `len` in px, facing right.
static func car_side(ci: CanvasItem, p: Vector2, len: float, col: Color, style := "coupe", lights := false, wrecked := 0.0) -> void:
	var h := len * 0.16
	var body := Rect2(p.x, p.y - h, len, h)
	ci.draw_rect(Rect2(p.x + 4, p.y - 2, len - 8, 4), Color(0, 0, 0, 0.35))
	ci.draw_rect(body, col)
	ci.draw_rect(Rect2(body.position, Vector2(len, 2)), col.lightened(0.2))
	var cab_f := 0.62 if style == "coupe" else 0.68
	var cab_b := 0.28 if style == "coupe" else 0.2
	var top := p.y - h - len * (0.11 if style != "truck" else 0.16)
	var cab := PackedVector2Array([Vector2(p.x + len * cab_b, p.y - h), Vector2(p.x + len * (cab_b + 0.06), top), Vector2(p.x + len * (cab_f - 0.08), top), Vector2(p.x + len * cab_f, p.y - h)])
	if wrecked > 0.0:
		for k in cab.size(): cab[k] += Vector2(0, wrecked * 6.0 * float(k % 2))
	ci.draw_colored_polygon(cab, col.darkened(0.1))
	var win := PackedVector2Array([cab[0] + Vector2(4, -1), cab[1] + Vector2(3, 3), cab[2] + Vector2(-3, 3), cab[3] + Vector2(-4, -1)])
	ci.draw_colored_polygon(win, Color("1c2633") if wrecked < 0.5 else Color("a8b4c0"))
	for wx in [0.18, 0.8]:
		ci.draw_circle(Vector2(p.x + len * wx, p.y), len * 0.07, Color("141414"))
		ci.draw_circle(Vector2(p.x + len * wx, p.y), len * 0.035, Color("8a8e94"))
	if lights:
		ci.draw_rect(Rect2(p.x + len - 4, p.y - h + 3, 4, 4), Color("f4ecc2"))
		ci.draw_rect(Rect2(p.x, p.y - h + 3, 3, 4), Color("ff3b2e"))

static func _sky(ci: CanvasItem, top: Color, bottom: Color, h := 360.0) -> void:
	for y in range(0, int(h), 6):
		ci.draw_rect(Rect2(0, y, 640, 6), top.lerp(bottom, float(y) / h))

static func _stars(ci: CanvasItem, t: float, n := 60, max_y := 160.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in n:
		var p := Vector2(rng.randf() * 640.0, rng.randf() * max_y)
		var a := 0.4 + 0.4 * sin(t * (1.0 + rng.randf() * 2.0) + k)
		ci.draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, a))

# ------------------------------------------------------------------ the sets

static func _party(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color("140e18"))
	# corrugated warehouse wall
	for x in range(0, 640, 12): ci.draw_rect(Rect2(x, 0, 6, 220), Color("1c1622"))
	ci.draw_rect(Rect2(0, 220, 640, 140), Color("221c26"))
	# light beams sweeping from the ceiling
	var cols := [Color(1, 0.2, 0.6, 0.18), Color(0.2, 0.8, 1, 0.18), Color(0.6, 1, 0.2, 0.15)]
	for k in 3:
		var src := Vector2(160 + k * 160, 0)
		var ang := sin(t * (0.8 + k * 0.3) + k) * 0.7
		var d := Vector2(sin(ang), cos(ang))
		ci.draw_colored_polygon(PackedVector2Array([src, src + d.rotated(0.12) * 300.0, src + d.rotated(-0.12) * 300.0]), cols[k])
	# the speaker stack that's breathing
	var pulse := 1.0 + 0.06 * absf(sin(t * 8.0))
	ci.draw_rect(Rect2(500, 120, 70, 120), Color("0e0c10"))
	for k in 2:
		ci.draw_circle(Vector2(535, 150 + k * 55), 20.0 * pulse, Color("2a2630"))
		ci.draw_circle(Vector2(535, 150 + k * 55), 8.0, Color("0e0c10"))
	# the crowd, bobbing
	for k in 14:
		var x := 20.0 + k * 34.0
		var bob := sin(t * 8.0 + k * 1.7) * 3.0
		var col := Color("0a080c")
		ci.draw_circle(Vector2(x, 196 + bob), 9, col)
		ci.draw_rect(Rect2(x - 12, 204 + bob, 24, 60), col)
	# a string of party lights
	for k in 22:
		var x := 10.0 + k * 29.0
		var y := 40.0 + sin(k * 0.5) * 6.0
		ci.draw_circle(Vector2(x, y), 3, [Color("ff4a8a"), Color("4ad8ff"), Color("ffe04a")][k % 3] * (0.7 + 0.3 * sin(t * 3.0 + k)))
	ci.draw_rect(Rect2(0, 260, 640, 100), Color(0, 0, 0, 0.4))

static func _airstrip(ci: CanvasItem, t: float) -> void:
	_sky(ci, Color("06070e"), Color("1a1830"), 200)
	_stars(ci, t)
	ci.draw_rect(Rect2(0, 200, 640, 160), Color("1e1e22"))
	# runway edge lights and the centre line
	for x in range(0, 640, 40):
		ci.draw_rect(Rect2(x + 10, 216, 18, 2), Color("d8d8d0"))
		ci.draw_circle(Vector2(x, 206), 2, Color(0.35, 0.55, 1.0, 0.8))
	# the circle of cars with their lights on
	for k in 6:
		var x := 30.0 + k * 100.0
		var col: Color = [Color("2a2a2e"), Color("c8342c"), Color("e8e4dc"), Color("2c5a8a"), Color("1e1e24"), Color("d8a03a")][k]
		if k == 2 or k == 3: continue
		car_side(ci, Vector2(x, 252 + (k % 2) * 6), 90, col, "coupe", true)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 90, 240), Vector2(x + 200, 220), Vector2(x + 200, 262)]), Color(1, 0.95, 0.75, 0.08))
	# the wreck: the Supreem inside Mia's car
	car_side(ci, Vector2(250, 262), 100, Color("e8e4dc"), "coupe", false, 1.0)
	car_side(ci, Vector2(310, 268), 96, Color("d86a1a"), "coupe", false, 1.0)
	# steam off the wreck
	for k in 6:
		var p := Vector2(330 + sin(t + k) * 10.0, 220 - fmod(t * 20.0 + k * 12.0, 70.0))
		ci.draw_circle(p, 8 + k, Color(0.8, 0.8, 0.85, 0.12))
	# the fence Leo came through
	for x in range(560, 640, 8): ci.draw_line(Vector2(x, 170), Vector2(x + 6, 205), Color("5a5a5e"), 1.0)
	ci.draw_line(Vector2(560, 175), Vector2(640, 175), Color("5a5a5e"), 1.0)
	ci.draw_line(Vector2(590, 190), Vector2(612, 214), Color("8a8a8e"), 2.0)

static func _office(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color("4a4038"))
	for x in range(0, 640, 32): ci.draw_rect(Rect2(x, 0, 2, 230), Color("40362e"))
	# the window into the bays
	ci.draw_rect(Rect2(380, 40, 220, 120), Color("2a2a30"))
	ci.draw_rect(Rect2(386, 46, 208, 108), Color("6a6c70"))
	car_side(ci, Vector2(410, 140), 120, Color("e8e4dc").darkened(0.3), "coupe", false, 1.0)
	ci.draw_line(Vector2(490, 46), Vector2(490, 154), Color("2a2a30"), 3.0)
	# Frank's photo
	ci.draw_rect(Rect2(90, 50, 60, 72), Color("8a6a3a"))
	ci.draw_texture_rect(Face.texture(196501, 0, 51), Rect2(94, 54, 52, 52), false)
	ci.draw_rect(Rect2(94, 108, 52, 10), Color("e8e4dc"))
	PixelFont.draw_centered(ci, 120, 110, "FRANK", Color("2a2420"))
	# the calendar
	ci.draw_rect(Rect2(200, 60, 60, 60), Color("f0ece0"))
	ci.draw_rect(Rect2(200, 60, 60, 12), Color("e0402e"))
	PixelFont.draw_centered(ci, 230, 63, "OCT 2019", Color("f3ead2"))
	PixelFont.draw_centered(ci, 230, 84, "7", Color("2a2420"), 3)
	# the desk, the computer, the mug
	ci.draw_rect(Rect2(40, 230, 560, 40), Color("6a4e36"))
	ci.draw_rect(Rect2(40, 270, 560, 90), Color("5a4232"))
	ci.draw_rect(Rect2(120, 170, 90, 60), Color("c8c0a8"))
	ci.draw_rect(Rect2(126, 176, 78, 46), Color("1a3a2a") if int(t * 2.0) % 6 != 0 else Color("2a4a3a"))
	PixelFont.draw(ci, Vector2(130, 182), "MINISTRY", Color("6aff8a"))
	PixelFont.draw(ci, Vector2(130, 190), "INSPECTION", Color("6aff8a"))
	PixelFont.draw(ci, Vector2(130, 198), "SYSTEM 98", Color("6aff8a"))
	ci.draw_rect(Rect2(150, 230, 30, 4), Color("8a8478"))
	ci.draw_rect(Rect2(300, 206, 22, 24), Color("e8e4dc"))
	ci.draw_rect(Rect2(322, 212, 6, 10), Color("e8e4dc"), false, 2.0)
	PixelFont.draw(ci, Vector2(244, 196), "WORLD'S OKAYEST BOSS", Color("2a2420").lightened(0.5))
	# morning light through the blinds
	for k in 6:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(380 + k * 36, 40), Vector2(398 + k * 36, 40), Vector2(260 + k * 40, 360), Vector2(230 + k * 40, 360)]), Color(1, 0.9, 0.6, 0.05))

static func _lot_dusk(ci: CanvasItem, t: float) -> void:
	_sky(ci, Color("2a1a3a"), Color("e07a4a"), 220)
	ci.draw_circle(Vector2(520, 200), 30, Color(1, 0.75, 0.4, 0.8))
	ci.draw_rect(Rect2(0, 220, 640, 140), Color("3a3a3e"))
	# Covington Auto: the building, the sign, the bay doors
	ci.draw_rect(Rect2(60, 110, 360, 120), Color("6a5a48"))
	ci.draw_rect(Rect2(60, 104, 360, 10), Color("3a3640"))
	ci.draw_rect(Rect2(140, 84, 200, 22), Color("1a1418"))
	PixelFont.draw_centered(ci, 240, 90, "COVINGTON AUTO", Color("f2d36a"), 2)
	for k in 3:
		ci.draw_rect(Rect2(80 + k * 110, 150, 90, 80), Color("8a8a84"))
		for r in 8: ci.draw_rect(Rect2(80 + k * 110, 150 + r * 10, 90, 1), Color("6a6a66"))
	ci.draw_rect(Rect2(400, 170, 14, 60), Color("2a2a30"))
	ci.draw_rect(Rect2(396, 164, 22, 8), Color("f4e0a0") if fmod(t, 4.0) < 3.7 else Color("6a5a3a"))
	# across the street: the black Charjer, idling
	car_side(ci, Vector2(470, 300), 130, Color("1e1e24"), "sedan", true)
	for k in 4:
		ci.draw_circle(Vector2(466 - fmod(t * 15.0 + k * 9.0, 40.0), 290), 3 + k, Color(0.6, 0.6, 0.65, 0.12))

static func _tims(ci: CanvasItem, t: float) -> void:
	_sky(ci, Color("06070e"), Color("14182a"), 180)
	_stars(ci, t, 40, 120)
	ci.draw_rect(Rect2(0, 180, 640, 180), Color("26262a"))
	# the Tim Burtons
	ci.draw_rect(Rect2(40, 100, 220, 110), Color("8a2a22"))
	ci.draw_rect(Rect2(40, 92, 220, 12), Color("4a4448"))
	ci.draw_rect(Rect2(70, 110, 160, 22), Color("1a1418"))
	PixelFont.draw_centered(ci, 150, 116, "TIM BURTONS", Color("f4ece0") if fmod(t, 7.0) < 6.6 else Color("6a5a5a"), 2)
	ci.draw_rect(Rect2(60, 146, 180, 40), Color("f2c86a"))
	# the one lamp that works
	ci.draw_rect(Rect2(420, 60, 6, 170), Color("2a2a2e"))
	ci.draw_rect(Rect2(404, 56, 30, 6), Color("2a2a2e"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(410, 62), Vector2(432, 62), Vector2(520, 300), Vector2(320, 300)]), Color(1, 0.75, 0.45, 0.12))
	# the Silvio, and its very old rain puddle
	ci.draw_circle(Vector2(430, 292), 26, Color(0.3, 0.32, 0.4, 0.5))
	car_side(ci, Vector2(360, 290), 130, Color("c8342c"), "coupe")
	# Darrell's truck
	car_side(ci, Vector2(520, 300), 120, Color("4a5a3a"), "truck")

static func _apartment(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color("16141c"))
	# the window, the streetlight outside it
	ci.draw_rect(Rect2(400, 50, 140, 110), Color("0a0a12"))
	ci.draw_circle(Vector2(470, 90), 18, Color(1, 0.6, 0.25, 0.35))
	ci.draw_line(Vector2(470, 50), Vector2(470, 160), Color("2a2830"), 3.0)
	ci.draw_line(Vector2(400, 105), Vector2(540, 105), Color("2a2830"), 3.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(400, 160), Vector2(540, 160), Vector2(600, 360), Vector2(320, 360)]), Color(1, 0.6, 0.3, 0.06))
	# the TV, flickering
	var f := 0.5 + 0.5 * absf(sin(t * 7.0) * sin(t * 2.3))
	ci.draw_rect(Rect2(80, 150, 120, 80), Color("1a1a1e"))
	ci.draw_rect(Rect2(86, 156, 108, 64), Color(0.3 * f, 0.4 * f, 0.6 * f))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(86, 220), Vector2(194, 220), Vector2(260, 360), Vector2(20, 360)]), Color(0.4, 0.5, 0.8, 0.05 * f))
	# the couch
	ci.draw_rect(Rect2(220, 240, 200, 60), Color("3a2e2a"))
	ci.draw_rect(Rect2(220, 220, 200, 24), Color("44362e"))
	# Aries's door, and the light under it
	ci.draw_rect(Rect2(560, 120, 60, 180), Color("2a2420"))
	ci.draw_rect(Rect2(560, 296, 60, 3), Color(1, 0.85, 0.5, 0.6 if fmod(t, 9.0) < 8.0 else 0.0))

static func _bay(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color("2a2a2e"))
	ci.draw_rect(Rect2(0, 250, 640, 110), Color("5a5a58"))
	# the tool wall
	ci.draw_rect(Rect2(40, 60, 220, 120), Color("3a3a40"))
	for k in 14:
		var x := 50.0 + (k % 7) * 30.0
		var y := 70.0 + int(k / 7) * 50.0
		ci.draw_rect(Rect2(x, y, 4, 30 + (k % 3) * 6), Color("8a8e94"))
	# the lift posts and the tarped car
	ci.draw_rect(Rect2(300, 100, 12, 160), Color("c8a030"))
	ci.draw_rect(Rect2(580, 100, 12, 160), Color("c8a030"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(330, 262), Vector2(340, 214), Vector2(400, 196), Vector2(500, 196), Vector2(560, 216), Vector2(568, 262)]), Color("3a4a3a"))
	for k in 5: ci.draw_line(Vector2(360 + k * 40, 200 + (k % 2) * 4), Vector2(350 + k * 42, 262), Color("2e3a2e"), 1.0)
	# the hanging light, swinging a little
	var sw := sin(t * 0.8) * 6.0
	ci.draw_line(Vector2(450, 0), Vector2(450 + sw, 70), Color("1a1a1e"), 2.0)
	ci.draw_rect(Rect2(436 + sw, 70, 28, 10), Color("1a1a1e"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(440 + sw, 80), Vector2(460 + sw, 80), Vector2(560 + sw * 2.0, 262), Vector2(340 + sw * 2.0, 262)]), Color(1, 0.9, 0.6, 0.1))
