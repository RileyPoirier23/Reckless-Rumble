## The cutscene sets, painted pixel by pixel at 320x180 and shown at 2x, in the same hand as the
## CAGE BOSS portraits: dithered light, cel-shaded props, ink outlines, real clutter.
## Each set is painted once (cached); the things that move (party lights, a buzzing sign,
## a TV, steam off a coffee) are drawn on top every frame by animate().
class_name StorySets
extends RefCounted

const AW := 320
const AH := 180
const INK := Color("120e14")
const FEET_Y := 128                 # the cast stand with their feet on this line (set px)

static var _cache := {}
## Where the vehicles stand in each set: { rect (set px), wreck } each, so nobody in a cutscene
## stands in one and no two cars sit in each other (unless they're one wreck, on purpose).
static var vehicles := {}
static var _painting := ""

static func texture(name: String) -> ImageTexture:
	if _cache.has(name): return _cache[name]
	var p := Pix.new(AW, AH, name.hash())
	_painting = name
	vehicles[name] = []
	match name:
		"party": _party(p)
		"airstrip": _airstrip(p)
		"office": _office(p)
		"lot_dusk": _lot(p, false)
		"lot_dusk_charjer": _lot(p, true)
		"tims": _tims(p)
		"apartment": _apartment(p)
		"bay": _bay(p)
		_: p.rect(0, 0, AW, AH, Color("0b090d"))
	var t := p.texture()
	_cache[name] = t
	return t

## The vehicles in a set: { rect, wreck } for each.
static func vehicles_in(name: String) -> Array:
	texture(name)
	return vehicles.get(name, [])

## A car in the set: painted, and where it stands remembered. Cars with the same `wreck` name
## are one crash and are allowed to be in each other.
static func _car(p: Pix, x: int, y: int, len: int, body: String, paint: Color, dmg := {}, flip := false, tilt := 0.0, mods := {}, wreck := "") -> void:
	# where it stands: the car itself, not its smoke or the glow off its lamps
	var bare := dmg.duplicate()
	bare.erase("smoke")
	bare.erase("lights")
	var probe := Pix.new(AW, AH, 1)
	PixCars.draw(probe, x, y, len, body, paint, bare, flip, tilt, mods)
	var r := probe.img.get_used_rect()
	if r.size != Vector2i.ZERO: _vehicle(Rect2(r), wreck)
	PixCars.draw(p, x, y, len, body, paint, dmg, flip, tilt, mods)

static func _vehicle(r: Rect2, wreck := "") -> void:
	(vehicles[_painting] as Array).append({ "rect": r, "wreck": wreck })

## Draw the set (2x) and its moving parts. Kept for callers that just want a backdrop.
static func draw(ci: CanvasItem, name: String, t: float) -> void:
	ci.draw_texture_rect(texture(name), Rect2(0, 0, AW * 2, AH * 2), false)
	animate(ci, name, t)

# ====================================================================== moving parts (screen px)

static func animate(ci: CanvasItem, name: String, t: float) -> void:
	match name:
		"party":
			# coloured beams sweeping through the haze
			var cols := [Color(1.0, 0.2, 0.6, 0.16), Color(0.2, 0.6, 1.0, 0.15), Color(0.4, 1.0, 0.3, 0.12)]
			for k in 3:
				var ang := sin(t * (0.7 + k * 0.23) + k * 2.0) * 0.6
				var src := Vector2(180 + k * 120, 40)
				var d := Vector2(sin(ang), cos(ang))
				var side := Vector2(d.y, -d.x) * 70.0
				ci.draw_colored_polygon(PackedVector2Array([src, src + d * 320.0 + side, src + d * 320.0 - side]), cols[k])
			# the bulbs on the string twinkle
			for k in 26:
				if int(t * 3.0 + k * 1.7) % 5 == 0:
					var x := 14.0 + k * 24.0
					var y := 58.0 + sin(k * 0.52) * 10.0 + (k % 2) * 2.0
					ci.draw_rect(Rect2(x, y, 4, 4), Color(1, 1, 0.9, 0.85))
			# the speaker cones thump
			var thump := 1.0 if fmod(t, 0.48) < 0.07 else 0.0
			ci.draw_arc(Vector2(570, 196), 26 + thump * 3.0, 0, TAU, 28, Color(1, 1, 1, 0.08 + thump * 0.15), 2.0)
			ci.draw_arc(Vector2(570, 260), 26 + thump * 3.0, 0, TAU, 28, Color(1, 1, 1, 0.08 + thump * 0.15), 2.0)
		"airstrip":
			if fmod(t, 1.6) < 0.8: ci.draw_rect(Rect2(546, 72, 6, 6), Color(1, 0.15, 0.1))
			for k in 4:
				var y := 150.0 + sin(t * 0.8 + k) * 6.0
				ci.draw_rect(Rect2(fmod(t * 9.0 + k * 170.0, 700.0) - 60.0, y + k * 14.0, 120, 6), Color(1, 1, 0.9, 0.04))
		"office":
			if fmod(t, 1.0) < 0.5: ci.draw_rect(Rect2(298, 170, 8, 4), Color("6aff8a"))
			for k in 3:
				var s := fmod(t * 0.7 + k * 0.33, 1.0)
				ci.draw_rect(Rect2(474 + sin(t * 2.0 + k) * 3.0, 186 - s * 26.0, 2, 2), Color(1, 1, 1, 0.35 * (1.0 - s)))
			if fmod(t, 9.0) < 0.12: ci.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.25))
		"lot_dusk", "lot_dusk_charjer":
			var on := fmod(t, 5.3) > 0.15
			ci.draw_rect(Rect2(150, 74, 170, 22), Color(1.0, 0.82, 0.35, 0.10 if on else 0.0))
			if name == "lot_dusk_charjer":
				ci.draw_rect(Rect2(574, 214, 6, 4), Color(1, 0.95, 0.8, 0.6 + 0.2 * sin(t * 30.0)))
		"tims":
			var flick := fmod(t, 6.0) > 5.6 and int(t * 20.0) % 2 == 0
			if flick: ci.draw_rect(Rect2(150, 96, 180, 22), Color(0, 0, 0, 0.55))
			ci.draw_rect(Rect2(476, 70, 200, 200), Color(1, 0.85, 0.5, 0.03 + 0.02 * sin(t * 50.0)))
		"apartment":
			var tv := Color(0.55 + 0.25 * sin(t * 7.0), 0.65 + 0.2 * sin(t * 5.3), 1.0, 0.16 + 0.08 * sin(t * 11.0))
			ci.draw_rect(Rect2(60, 140, 150, 120), tv)
		"bay":
			if fmod(t, 4.0) < 0.3 and int(t * 25.0) % 2 == 0:
				ci.draw_rect(Rect2(380, 0, 260, 200), Color(0, 0, 0, 0.3))
			for k in 8:
				var x := fmod(k * 83.0 + t * (4.0 + k), 640.0)
				var y := 60.0 + fmod(k * 47.0 + t * 3.0, 160.0)
				ci.draw_rect(Rect2(x, y, 2, 2), Color(1, 0.95, 0.8, 0.25))

# ====================================================================== shared bits

static func _floor_concrete(p: Pix, y0: int, c: Color) -> void:
	p.grad_v(0, y0, AW, AH - y0, c.darkened(0.15), c, 4)
	p.speckle(0, y0, AW, AH - y0, c.lightened(0.08), 0.05)
	p.speckle(0, y0, AW, AH - y0, c.darkened(0.12), 0.05)
	for k in 5:     # expansion joints, going back in perspective
		var x := 20 + k * 70
		p.line(x, AH - 1, x + (x - 160) / 6, y0, c.darkened(0.2))
	for k in 6:     # oil stains
		var sx := (k * 61 + 23) % AW
		var sy := y0 + 8 + (k * 17) % maxi(1, AH - y0 - 12)
		p.ellipse(sx, sy, 7.0 + k % 3 * 3, 2.0 + k % 2, c.darkened(0.3))
		p.ellipse(sx + 1, sy, 3.0, 1.0, c.darkened(0.45))

static func _window_night(p: Pix, x: int, y: int, w: int, h: int, panes := 2) -> void:
	p.grad_v(x, y, w, h, Color("0a1024"), Color("1e2a4a"), 4)
	p.speckle(x, y, w, h / 2, Color("c8d0e8"), 0.02)
	p.frame(x - 1, y - 1, w + 2, h + 2, Color("3a3430"))
	for k in range(1, panes): p.vline(x + w * k / panes, y, h, Color("3a3430"))
	p.hline(x, y + h / 2, w, Color("3a3430"))

static func _crate(p: Pix, x: int, y: int, w: int, h: int, c: Color) -> void:
	p.box(x, y, w, h, c)
	p.line(x + 1, y + 1, x + w - 2, y + h - 2, c.darkened(0.25))

static func _tire_stack(p: Pix, x: int, y: int, n: int) -> void:
	for k in n:
		var ty := y - k * 6
		p.ellipse(x, ty, 11.0, 4.0, Color("17151a"))
		p.ellipse(x, ty - 1, 11.0, 3.0, Color("26242a"))
		p.ellipse(x, ty - 1, 5.0, 1.5, Color("0b0a0c"))
		p.hline(x - 9, ty + 2, 4, Color("3a383e"))

static func _drum(p: Pix, x: int, y: int, c: Color) -> void:
	p.box(x, y - 22, 14, 22, c)
	for yy in [y - 18, y - 11, y - 4]: p.hline(x, yy, 14, c.darkened(0.3))
	p.ellipse(x + 7, y - 22, 7.0, 1.5, c.lightened(0.15))
	p.vline(x + 3, y - 20, 18, c.lightened(0.12))

static func _poster(p: Pix, x: int, y: int, w: int, h: int, bg: Color, title: String, ink: Color) -> void:
	p.box(x, y, w, h, bg)
	p.text(x + 2, y + 2, title, ink)
	p.rect(x + 2, y + 9, w - 4, h - 12, bg.darkened(0.2))
	p.px(x + w / 2, y, Color("c8c8cc"))                    # the pin

# ====================================================================== the party

static func _party(p: Pix) -> void:
	# corrugated warehouse wall, steel columns, high windows
	p.siding(0, 0, AW, 112, Color("2a2e3a"))
	p.grad_v(0, 0, AW, 112, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0), 4)
	for k in 6:
		var rx := 12 + k * 54
		p.rect_dither(rx, 20, 3, 60, Color("6a3a24"), 0.35)                    # rust streaks
	for x in [0, 104, 214, 312]:
		p.box(x, 0, 8, 112, Color("3a3a44"))
		for ry in range(6, 110, 10): p.px(x + 2, ry, Color("6a6a74"))
	for x in [22, 132, 240]: _window_night(p, x, 8, 60, 18, 4)
	# the banner nobody can explain
	p.box(110, 32, 104, 12, Color("e8e4dc"))
	p.text(113, 34, "HAPPY BDAY ???", Color("c8342c"))
	p.text(113, 40, "", Color("c8342c"))
	# string lights (lit bulbs painted, the twinkle is animated)
	for k in 26:
		var x := 7 + k * 12
		var y := 29 + int(sin(k * 0.52) * 5.0) + (k % 2)
		p.px(x, y - 1, Color("1a1614"))
		p.rect(x, y, 2, 2, [Color("e04060"), Color("40c0e0"), Color("e0c040"), Color("60e060")][k % 4])
		p.glow(x, y, 4.0, [Color("e04060"), Color("40c0e0"), Color("e0c040"), Color("60e060")][k % 4], 0.35)
	# the crowd: silhouettes, arms up, phone screens
	for k in 22:
		var x := 6 + k * 15 + (k * 7) % 5
		var hgt := 36 + (k * 13) % 9
		var y := 112 - hgt
		var c := Color("0e0c14")
		p.rect(x, y + 8, 10, hgt, c)
		p.disc(x + 5, y + 4, 4.0, c)
		if k % 3 == 0:
			p.rect(x + 9, y - 6, 2, 14, c)
			p.rect(x + 8, y - 8, 3, 3, Color("cfe8ff"))             # phone up, filming
		elif k % 4 == 1:
			p.rect(x - 2, y - 4, 2, 12, c)
			p.rect(x + 10, y - 4, 2, 12, c)
	# the DJ table and the stack
	p.box(232, 82, 40, 20, Color("1e1c22"))
	p.rect(240, 78, 14, 5, Color("2a2a30"))
	p.rect(241, 79, 12, 3, Color("8ab8ff"))
	p.glow(247, 80, 10.0, Color("8ab8ff"), 0.35)
	for sy in [70, 102]:
		p.box(270, sy, 34, 30, Color("16141a"))
		p.disc(286, sy + 15, 11.0, Color("0a090c"))
		p.ring(286, sy + 15, 11.0, Color("3a3a40"))
		p.disc(286, sy + 15, 4.0, Color("2a2a30"))
	# floor: concrete, cups, pizza boxes, a cooler
	_floor_concrete(p, 112, Color("3a3840"))
	p.grad_v(0, 112, AW, 14, Color(1.0, 0.3, 0.6, 0.14), Color(1.0, 0.3, 0.6, 0.0), 3)   # light pooling on the floor
	p.box(16, 120, 46, 12, Color("5a2a3a"))                                 # the couch (floral, brown, cursed)
	p.box(14, 108, 50, 13, Color("6a3444"))
	p.speckle(14, 108, 50, 24, Color("c8a040"), 0.06)
	p.box(70, 124, 22, 12, Color("e8e8e4"))                                 # the cooler
	p.rect(70, 124, 22, 4, Color("2a5aa8"))
	p.box(200, 128, 26, 3, Color("c8a878"))                                 # pizza boxes
	p.box(202, 125, 24, 3, Color("d8b888"))
	for k in 7:
		var cx := 100 + k * 23 + (k * 11) % 9
		p.rect(cx, 140 + (k * 7) % 20, 3, 4, Color("c8242c"))                 # dead red cups
		p.hline(cx, 140 + (k * 7) % 20, 3, Color("f0ece4"))
	p.rect(0, 40, AW, 72, Color(0.6, 0.5, 0.8, 0.06))                           # haze

# ====================================================================== Airstrip 7

static func _airstrip(p: Pix) -> void:
	p.grad_v(0, 0, AW, 90, Color("04050c"), Color("1a1e34"), 6)
	p.speckle(0, 0, AW, 60, Color("c8d0e8"), 0.015)
	p.speckle(0, 0, AW, 50, Color("ffffff"), 0.004)
	# the treeline and the old control tower
	for x in AW:
		var th := 6 + int(absf(sin(x * 0.37)) * 6.0 + absf(sin(x * 0.11)) * 5.0)
		p.vline(x, 82 - th, th, Color("06080a"))
	p.rect(268, 40, 10, 44, Color("0e1018"))
	p.rect(262, 30, 22, 12, Color("12141e"))
	p.rect(264, 32, 18, 5, Color("2a3040"))
	p.vline(273, 22, 8, Color("12141e"))
	# runway: cracked concrete, faded numbers, weeds in the joints
	p.grad_v(0, 82, AW, AH - 82, Color("23232a"), Color("3a3a42"), 5)
	p.speckle(0, 82, AW, AH - 82, Color("4a4a52"), 0.06)
	for k in 9:
		var x := k * 40 + 6
		p.line(x, 82, x - 30 + (k % 3) * 8, AH, Color("1a1a20"))
		p.px(x - 10, 120 + k * 5, Color("2a4a24"))
	p.text(140, 160, "07", Color("6a6a70"))
	for k in 6: p.rect(10 + k * 56, 150, 24, 2, Color("5a5a60"))
	# the fence with a car-shaped hole in it
	for x in range(0, AW, 2):
		for y in range(64, 84):
			if (x + y) % 4 == 0 and not (x > 40 and x < 76 and y > 66): p.px(x, y, Color("4a4e58"))
	for x in range(0, AW, 24): p.vline(x, 60, 24, Color("5a5e68"))
	p.line(40, 66, 30, 84, Color("6a6e78"))
	p.line(76, 66, 88, 82, Color("6a6e78"))
	# the ring of cars, headlights on (beams in the haze), behind the wreck and clear of everybody
	var ring := [[30, 95, "sedan", Color("2a2a2e"), 4.9, false], [116, 94, "muscle", Color("d8a03a"), 4.8, true]]
	for c in ring:
		_car(p, int(c[0]), int(c[1]), PixCars.length_px(float(c[4]), 0.45), String(c[2]), c[3], { "lights": true }, bool(c[5]))
	p.beam(110, 86, 210, 80, 130, Color("fff4c8"), 0.25)
	p.beam(116, 86, 20, 82, 130, Color("fff4c8"), 0.25)
	# the wreck: Dad's Supreem, parked inside Mia's car
	_car(p, 108, 126, PixCars.length_px(4.5, 0.56), "coupe", Color("3a6aa8"), { "rear": 0.9, "glass": true, "bumper": "gone" }, true, 0.0, { "rim": "fivespoke", "drop": 1.0, "spoiler": "wing" }, "the wreck")
	_car(p, 30, 128, PixCars.length_px(4.6, 0.56), "hatch", Color("d8d4c8"), { "front": 0.9, "glass": true, "smoke": 0.6, "bumper": "hang" }, false, 0.0, {}, "the wreck")
	# Mia's turbo, on the ground, where turbos don't go
	p.disc(204, 140, 5.0, Color("8a8a90"))
	p.ring(204, 140, 5.0, Color("4a4a50"))
	p.disc(204, 140, 2.0, Color("2a2a2e"))
	p.rect(209, 138, 7, 3, Color("6a6a70"))
	p.rect(0, 60, AW, 70, Color(0.7, 0.7, 0.8, 0.05))

# ====================================================================== the office

static func _office(p: Pix) -> void:
	p.planks(0, 0, AW, 116, Color("6a4a30"), 10)
	p.grad_v(0, 0, AW, 30, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0), 3)
	p.box(0, 0, AW, 4, Color("d8d4c8"))                                      # drop ceiling edge
	# Frank's photo: his real portrait, in a frame, with a black ribbon on the corner
	p.box(30, 16, 40, 46, Color("8a6a3a"))
	p.rect(33, 19, 34, 34, Color("c6d6e8"))
	var frank := Face.image(int(StoryScript.CAST.FRANK.seed), 0, int(StoryScript.CAST.FRANK.age))
	frank.resize(32, 32, Image.INTERPOLATE_NEAREST)
	p.stamp(frank, 34, 20)
	p.rect(34, 55, 32, 5, Color("e8e4dc"))
	p.text(39, 55, "FRANK", Color("2a2420"))
	p.line(62, 16, 70, 24, Color("0a0a0a"))
	p.line(63, 16, 70, 23, Color("0a0a0a"))
	# the Ministry licence and the calendar
	p.box(82, 20, 30, 22, Color("f0ece0"))
	p.rect(84, 22, 26, 3, Color("2a4a8a"))
	for k in 4: p.hline(85, 28 + k * 3, 22 - k * 3, Color("8a8a8a"))
	p.disc(104, 37, 3.0, Color("c8a030"))
	p.box(120, 16, 28, 30, Color("f0ece0"))
	p.rect(120, 16, 28, 8, Color("c8342c"))
	p.text(122, 18, "OCT19", Color("f0ece0"))
	p.text(131, 30, "7", Color("2a2420"))
	for k in 3: p.px(124 + k * 9, 40, Color("c8342c"))
	# a tire shop calendar girl? no. a tire. on a calendar. it's that kind of shop.
	_poster(p, 156, 18, 26, 30, Color("e8c040"), "TIRED", Color("1a1614"))
	p.disc(169, 35, 7.0, Color("17151a"))
	p.disc(169, 35, 3.0, Color("8a8a90"))
	# the window into the shop: a car up on the lift
	p.rect(196, 14, 110, 58, Color("3a4048"))
	p.frame(195, 13, 112, 60, Color("2a2420"))
	p.vline(251, 14, 58, Color("2a2420"))
	p.rect(210, 56, 4, 16, Color("c8342c"))
	p.rect(288, 56, 4, 16, Color("c8342c"))
	_car(p, 216, 54, 74, "sedan", Color("4a6a8a"), {})
	p.rect(196, 14, 110, 58, Color(0.8, 0.9, 1.0, 0.12))
	for k in 3: p.line(200 + k * 36, 16, 214 + k * 36, 30, Color(1, 1, 1, 0.3))
	# filing cabinet with a drawer full of the old manager's pens
	p.box(4, 70, 24, 46, Color("7a7a70"))
	for k in 3:
		p.hline(5, 84 + k * 14, 22, Color("4a4a44"))
		p.rect(13, 77 + k * 14, 6, 2, Color("c8c8c0"))
	p.box(2, 94, 28, 6, Color("8a8a80"))
	for k in 6: p.vline(5 + k * 4, 91, 4, [Color("2a4aa8"), Color("c8342c"), Color("1a1a1a")][k % 3])
	# the desk: CRT, stamp, papers, phone, coffee maker, THE MUG
	p.rect(0, 116, AW, AH - 116, Color("3a2e26"))
	p.speckle(0, 116, AW, AH - 116, Color("4a3a30"), 0.05)
	p.box(40, 108, 240, 10, Color("7a5a3a"))
	p.rect(40, 118, 240, 30, Color("5a4028"))
	p.vline(160, 118, 30, Color("3a2a1a"))
	p.box(128, 76, 40, 32, Color("d8d0b8"))                                   # the CRT
	p.rect(132, 80, 32, 22, Color("0a1a10"))
	p.text(134, 82, "MINISTRY", Color("6aff8a"))
	p.text(134, 88, "INSPECT", Color("6aff8a"))
	p.text(134, 94, "SYS 98", Color("6aff8a"))
	p.glow(148, 91, 18.0, Color("6aff8a"), 0.15)
	p.box(138, 104, 20, 4, Color("c8c0a8"))
	p.box(60, 102, 30, 6, Color("f0ece4"))                                    # papers
	p.box(64, 100, 30, 6, Color("e8e4dc"))
	p.box(100, 99, 8, 9, Color("2a2a30"))                                      # the APPROVED stamp
	p.rect(102, 96, 4, 4, Color("6a3a20"))
	p.box(180, 100, 18, 8, Color("d8d0b8"))                                    # beige phone
	p.rect(181, 98, 16, 3, Color("c8c0a8"))
	p.box(226, 88, 16, 20, Color("1a1a1e"))                                    # coffee maker
	p.rect(229, 98, 10, 9, Color("3a2416"))
	p.rect(229, 98, 10, 2, Color("8a8a90"))
	p.box(246, 98, 10, 10, Color("f0ece4"))                                    # WORLD'S OKAYEST BOSS
	p.ring(258, 102, 2.0, Color("f0ece4"))
	p.text(247, 101, "OK", Color("c8342c"))
	p.rect(42, 116, 236, 1, Color("2a1a10"))
	# light: a fluorescent fixture and the morning through the shop window
	p.rect(110, 4, 90, 3, Color("f0f4f0"))
	p.cone_down(155, 7, 110, 80.0, Color(1, 1, 0.92), 0.12)

# ====================================================================== outside Covington Auto at dusk

static func _lot(p: Pix, charjer: bool) -> void:
	p.grad_v(0, 0, AW, 96, Color("2a2448"), Color("f08a4a"), 8)
	p.disc(270, 86, 12.0, Color("ffd890"))
	p.glow(270, 86, 30.0, Color("ffd890"), 0.4)
	for k in 5:
		p.ellipse((k * 71 + 40) % AW, 20 + k * 9, 30.0, 3.0, Color("d8708a").darkened(0.1 * k))
	# a power pole and wires running across
	p.rect(300, 10, 4, 90, Color("3a2a1e"))
	p.rect(292, 16, 20, 2, Color("3a2a1e"))
	for k in 3: p.line(0, 22 + k * 4, 300, 18 + k * 2, Color("1a1416"))
	# the shop: cinder block, three bay doors, the sign
	var wall := Color("8a8070")
	p.rect(10, 38, 250, 70, wall)
	for y in range(38, 108, 5):
		p.hline(10, y, 250, wall.darkened(0.12))
		for x in range(10 + (y / 5 % 2) * 6, 260, 12): p.vline(x, y, 5, wall.darkened(0.12))
	p.rect(6, 34, 258, 5, Color("3a3430"))
	p.box(70, 22, 120, 14, Color("1a1614"))
	p.text(80, 26, "COVINGTON AUTO", Color("f2d36a"))
	p.glow(130, 29, 50.0, Color("f2d36a"), 0.12)
	p.box(196, 24, 54, 10, Color("2a4a8a"))
	p.text(198, 27, "INSPECTION", Color("f0ece0"))
	for k in 3:
		var bx := 20 + k * 58
		p.rect(bx, 54, 48, 54, Color("a8aaa8"))
		for y in range(56, 108, 4): p.hline(bx, y, 48, Color("8a8c8a"))
		p.rect(bx, 54, 48, 2, Color("6a6c6a"))
		p.rect(bx + 2, 60, 44, 3, Color("4a5a6a"))                         # the little windows
		p.text(bx + 18, 66, str(k + 1), Color("4a4c4a"))
	p.box(200, 60, 18, 48, Color("6a2a24"))                                    # office door
	p.rect(203, 64, 12, 16, Color("2a3440"))
	p.px(214, 86, Color("c8c8c0"))
	p.box(224, 70, 14, 38, Color("c8342c"))                                     # pop machine
	p.rect(226, 74, 10, 14, Color("f0ece4"))
	p.rect(226, 92, 10, 3, Color("1a1614"))
	_tire_stack(p, 248, 106, 4)
	_drum(p, 262, 108, Color("2a5a8a"))
	# the lot
	p.grad_v(0, 108, AW, AH - 108, Color("3a3638"), Color("4a4648"), 4)
	p.speckle(0, 108, AW, AH - 108, Color("56525a"), 0.05)
	for k in 5: p.line(30 + k * 64, 112, 18 + k * 64, AH, Color("d8d4c0"))
	for k in 4: p.ellipse(60 + k * 70, 130 + (k * 11) % 30, 9.0, 2.0, Color("2a2628"))
	_car(p, -40, 128, PixCars.length_px(5.6, 0.72), "pickup", Color("2a5a3a"), {})
	if charjer:
		# across the street, idling, for an hour
		p.rect(268, 108, 52, 10, Color("2a2628"))
		_car(p, 250, 114, PixCars.length_px(5.0, 0.5), "sedan", Color("16161a"), { "lights": true }, true, 0.0, { "rim": "tenspoke", "tint": 1.0 })
	# the streetlight is just coming on
	p.rect(150, 40, 2, 70, Color("2a2a2e"))

# ====================================================================== Tim Burtons, Mountain Road

static func _tims(p: Pix) -> void:
	p.grad_v(0, 0, AW, 80, Color("05070f"), Color("161c30"), 5)
	p.speckle(0, 0, AW, 50, Color("c8d0e8"), 0.01)
	# the building: brick base, big warm windows, the sign
	p.bricks(40, 40, 200, 62, Color("6a3424"), Color("3a2a22"), 8, 4)
	p.rect(36, 34, 208, 8, Color("e8e4dc"))
	p.box(70, 44, 150, 14, Color("7a1a1a"))
	p.text(105, 48, "TIM BURTONS", Color("f4ece0"))
	p.text(85, 52, "", Color("f4ece0"))
	for k in 3:
		var wx := 50 + k * 62
		p.rect(wx, 62, 54, 30, Color("f0c870"))
		p.frame(wx - 1, 61, 56, 32, Color("2a1e18"))
		p.vline(wx + 27, 62, 30, Color("2a1e18"))
		# people inside: a guy, a coffee, a guy staring at his coffee
		p.rect(wx + 8 + k * 4, 76, 8, 16, Color("3a2a22"))
		p.disc(wx + 12 + k * 4, 73, 3.0, Color("3a2a22"))
		p.rect(wx + 36, 82, 10, 3, Color("8a6a4a"))
		p.rect(wx + 38, 79, 3, 3, Color("f0ece4"))
	p.glow(140, 80, 90.0, Color("f0c870"), 0.18)
	# the drive-thru board and a poster
	p.box(250, 58, 30, 36, Color("1a1a1e"))
	for k in 6: p.hline(253, 62 + k * 5, 24, Color("e8c870").darkened(0.1 * (k % 2)))
	p.rect(262, 94, 4, 14, Color("2a2a2e"))
	p.box(14, 70, 20, 26, Color("c8342c"))
	p.text(16, 72, "ROLL", Color("f0ece0"))
	p.text(16, 78, "UP", Color("f0ece0"))
	p.text(16, 84, "RIM", Color("f0ece0"))
	p.text(16, 90, "SHOT", Color("e8c040"))
	# the lot and the only lamp that works
	p.grad_v(0, 102, AW, AH - 102, Color("1e1c22"), Color("2e2c32"), 4)
	p.speckle(0, 102, AW, AH - 102, Color("3a3840"), 0.05)
	for k in 6: p.line(14 + k * 56, 104, 2 + k * 56, AH, Color("8a8478"))
	p.rect(282, 30, 3, 100, Color("2a2a2e"))
	p.rect(270, 28, 18, 3, Color("2a2a2e"))
	p.rect(268, 30, 8, 2, Color("fff0c0"))
	p.cone_down(272, 32, 140, 46.0, Color(1.0, 0.92, 0.7), 0.3)
	p.box(10, 112, 10, 14, Color("3a5a3a"))                                    # bin
	# Darrell's truck, and the '91 Silvio with its puddle
	_car(p, -30, 126, PixCars.length_px(5.4, 0.72), "pickup", Color("6a5a48"), { "glass": true }, false, 0.0, { "year": 1988 })
	p.speckle(0, 104, 90, 16, Color("8a6a44"), 0.18)                           # rust patches
	p.ellipse(262, 132, 30.0, 3.0, Color("2a3a4a"))
	p.ellipse(262, 132, 18.0, 1.5, Color("4a6a8a"))
	_car(p, 196, 130, PixCars.length_px(4.52, 0.86), "coupe", Color("c8342c"), {}, true, 0.0, { "year": 1991, "rim": "fivespoke" })

# ====================================================================== the apartment over the garage

static func _apartment(p: Pix) -> void:
	p.rect(0, 0, AW, 120, Color("4a4038"))
	for y in range(4, 120, 8):
		for x in range((y / 8 % 2) * 8, AW, 16): p.px(x, y, Color("5a4e44"))     # old wallpaper, a little flower every so often
	for x in range(0, AW, 16): p.vline(x, 0, 120, Color("443a32"))
	p.hline(0, 84, AW, Color("6a5a4a"))                                        # chair rail
	# the window: the streetlight outside, blinds half up
	_window_night(p, 210, 18, 60, 50, 2)
	p.glow(250, 40, 22.0, Color("ff9a3a"), 0.5)
	p.disc(250, 40, 2.0, Color("ffd890"))
	for y in range(18, 40, 3): p.hline(210, y, 60, Color("c8bca8"))
	p.rect(208, 68, 64, 3, Color("6a5a4a"))
	# kitchen: counter, sink, microwave clock, fridge with magnets and Dad's photo
	p.box(276, 46, 40, 74, Color("e8e4dc"))
	p.hline(276, 72, 40, Color("b8b4ac"))
	p.rect(310, 50, 2, 14, Color("8a8a8a"))
	p.rect(310, 76, 2, 14, Color("8a8a8a"))
	var frank := Face.image(int(StoryScript.CAST.FRANK.seed), 0, int(StoryScript.CAST.FRANK.age))
	frank.resize(16, 16, Image.INTERPOLATE_NEAREST)
	p.box(282, 50, 18, 18, Color("f0ece4"))
	p.stamp(frank, 283, 51)
	p.box(300, 76, 10, 12, Color("f0ece4"))                                    # hockey schedule
	for k in 3: p.hline(301, 78 + k * 3, 8, Color("2a4a8a"))
	for k in 4: p.rect(284 + k * 6, 92, 3, 3, [Color("c8342c"), Color("e8c040"), Color("2a8a4a"), Color("2a4aa8")][k])
	# the TV (glow animated), a couch with a blanket, a lamp
	p.box(30, 70, 70, 50, Color("2a2622"))
	p.box(36, 74, 46, 34, Color("1a1a1e"))
	p.rect(40, 78, 38, 26, Color("3a5a8a"))
	p.grad_v(40, 78, 38, 26, Color("8ab0e0"), Color("3a5a8a"), 3)
	p.text(42, 80, "FAMILY", Color("f0e8c0"))
	p.text(42, 86, "FEUDING", Color("f0e8c0"))
	p.glow(59, 91, 40.0, Color(0.6, 0.75, 1.0), 0.2)
	p.box(120, 92, 70, 14, Color("4a5a3a"))
	p.box(116, 104, 78, 16, Color("3e4e30"))
	p.box(150, 92, 30, 24, Color("a83a2a"), false)                              # the blanket
	for k in range(152, 180, 4): p.vline(k, 93, 22, Color("8a2a1e"))
	p.rect(196, 60, 2, 50, Color("2a2622"))
	p.box(190, 52, 14, 10, Color("e8d8a8"))
	p.glow(197, 58, 16.0, Color("ffd890"), 0.3)
	# floor: worn boards, Aries's hockey bag and stick by the door
	p.planks(0, 120, AW, AH - 120, Color("5a4030"), 7, false)
	p.box(8, 112, 40, 16, Color("2a2a3a"))
	p.text(14, 117, "RUMBLE", Color("e8c040"))
	p.line(52, 128, 66, 72, Color("c8a878"))
	p.line(53, 128, 67, 72, Color("a88858"))
	p.rect(50, 126, 8, 3, Color("1a1a1a"))
	p.darken_rect(0, 0, AW, AH, 0.25)                                          # it's late

# ====================================================================== Bay 3

static func _bay(p: Pix) -> void:
	# two-tone block wall, pegboard with tool outlines, the old sign
	p.rect(0, 0, AW, 50, Color("8a8a84"))
	p.rect(0, 50, AW, 70, Color("6a7a6a"))
	for y in range(0, 120, 6):
		p.hline(0, y, AW, Color(0, 0, 0, 0.12))
		for x in range(((y / 6) % 2) * 8, AW, 16): p.vline(x, y, 6, Color(0, 0, 0, 0.12))
	p.hline(0, 50, AW, Color("4a5a4a"))
	p.box(20, 56, 90, 40, Color("c8a878"))
	for y in range(58, 94, 3):
		for x in range(22, 108, 3): p.px(x, y, Color("8a6a48"))
	for k in 6:
		var tx := 26 + k * 14
		p.rect(tx, 62, 3, 18, Color("3a3a40"))                               # wrenches, on their outlines
		p.rect(tx - 1, 61, 5, 3, Color("6a6a70"))
	p.box(124, 14, 92, 12, Color("2a2a2e"))
	p.text(128, 17, "COVINGTON AUTO  1987", Color("e8c040"))
	# the lift, the tool chest, tires, a drain pan, the radio on a shelf
	p.rect(240, 30, 6, 100, Color("c8342c"))
	p.rect(306, 30, 6, 100, Color("c8342c"))
	p.rect(240, 30, 72, 4, Color("8a1a1a"))
	p.box(122, 76, 38, 44, Color("b82a24"))
	for k in 5:
		p.hline(123, 80 + k * 8, 36, Color("7a1a14"))
		p.rect(136, 83 + k * 8, 10, 1, Color("d8d8dc"))
	p.text(126, 70, "SNAP-OFF", Color("f0ece0"))
	_tire_stack(p, 186, 126, 5)
	p.box(260, 8, 24, 10, Color("3a3a3e"))
	p.rect(262, 10, 8, 6, Color("1a1a1e"))
	# the floor: epoxy, drain, stains
	_floor_concrete(p, 120, Color("5a5a56"))
	p.ellipse(160, 160, 10.0, 3.0, Color("2a2a2a"))
	for x in range(152, 170, 3): p.vline(x, 158, 4, Color("1a1a1a"))
	# the Charjer under a tarp: a car-shaped hill of blue with folds
	var tarp := Color("2a4a7a")
	var pts := PackedVector2Array([Vector2(196, 150), Vector2(198, 128), Vector2(214, 124), Vector2(240, 106), Vector2(272, 104), Vector2(292, 118), Vector2(318, 124), Vector2(320, 150)])
	p.poly(pts, tarp)
	for k in 6:
		var fx := 206 + k * 19
		p.line(fx, 150, fx + 6, 112 + (k * 7) % 16, tarp.darkened(0.25))
		p.line(fx + 1, 150, fx + 7, 113 + (k * 7) % 16, tarp.lightened(0.15))
	p.poly_outline(pts, INK)
	p.disc(216, 146, 8.0, Color("17151a"))                                    # the wheels peek out
	p.disc(300, 146, 8.0, Color("17151a"))
	p.rect(196, 150, 124, 2, Color(0, 0, 0, 0.4))
	_vehicle(Rect2(196, 104, 124, 48))                                        # (the Charjer)
	# fluorescent tubes, one of them on its way out
	for x in [40, 180]:
		p.rect(x, 2, 70, 3, Color("f0f4f0"))
		p.cone_down(x + 35, 5, 120, 70.0, Color(1, 1, 0.95), 0.1)
