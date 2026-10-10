## The meme death screen. A fatal crash fades to black, then a pixel-art picture of the wreck
## (the car you were driving, folded around the thing you hit, in the right season, weather and
## time of day), a caption in a box ("YOU DIED BECAUSE...") and PRESS A TO CONTINUE.
class_name DeathScreen
extends Node2D

signal continued

const SW := 300               # the painted fallback picture, in art pixels (drawn 2x)
const SH := 112
const PIC := Rect2(20, 14, 600, 216)     # where the picture sits on screen

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")

const WHAT := { "tree": "A TREE", "building": "A BUILDING", "rail": "THE GUARDRAIL", "water": "THE PETITCODIAC",
	"edge": "THE EDGE OF THE MAP", "traffic": "ANOTHER CAR", "moose": "A MOOSE", "deer": "A DEER" }

var info: Dictionary
var caption := ""
var lines: Array[String] = []
var tex: Texture2D
var t := 0.0
var showing := false
var car_name := ""

func _ready() -> void:
	visible = false
	z_index = 200

## `shot` is a frame grabbed from the game at the moment of the crash (HUD hidden, camera in close).
## Without one (tests), a picture of the wreck is painted instead.
func open(the_info: Dictionary, shot: Image = null) -> void:
	info = the_info
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var speed := float(info.get("speed_kmh", 0.0))
	if not info.has("wheeloff"):
		info.wheeloff = shot == null and info.get("cause", "") in ["tree", "rail", "building", "traffic"] and speed > 95.0 and rng.randf() < 0.45
	caption = DeathMemes.pick(info, rng)
	lines = BigFont.wrap(caption, 588, 2, true)
	car_name = String(info.get("car_name", "")).to_upper()
	if shot != null: tex = ImageTexture.create_from_image(frame_from(shot))
	else: tex = ImageTexture.create_from_image(paint_scene(info, rng.randi()))
	t = 0.0
	showing = true
	visible = true

## Bring a full-window grab back onto the game's 640x360 pixel grid and crop the picture out of it.
static func frame_from(shot: Image) -> Image:
	var img := shot.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	img.resize(640, 360, Image.INTERPOLATE_NEAREST)
	var out := img.get_region(Rect2i(PIC.position.x, 72, PIC.size.x, PIC.size.y))
	# a freeze-frame: a little colour drained out, the edges pulled down
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var g := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			c = c.lerp(Color(g, g, g), 0.28)
			var d := Vector2((x - 300.0) / 300.0, (y - 108.0) / 108.0).length()
			if d > 0.75: c = c.darkened(clampf((d - 0.75) * 1.4, 0.0, 0.6))
			out.set_pixel(x, y, c)
	return out

func _process(dt: float) -> void:
	if not showing: return
	t += dt
	queue_redraw()
	if t > 1.4 and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("use")
			or Input.is_action_just_pressed("click") or Input.is_action_just_pressed("handbrake")):
		showing = false
		visible = false
		continued.emit()

func _draw() -> void:
	if not showing: return
	draw_rect(Rect2(0, 0, 640, 360), Color(INK, clampf(t * 2.5, 0.0, 1.0)))
	var a := clampf((t - 0.35) * 2.2, 0.0, 1.0)
	if a <= 0.0: return
	# the picture, framed like everything else in the game, with a camera-flash pop as it lands
	draw_rect(PIC.grow(2), Color(1, 1, 1, 0.14 * a), false, 1.0)
	draw_texture_rect(tex, PIC, false, Color(1, 1, 1, a))
	var flash := clampf(1.0 - (t - 0.35) * 4.0, 0.0, 1.0)
	if flash > 0.0: draw_rect(PIC, Color(1, 1, 1, flash * 0.8))
	# tags on the picture: TOTALED, the car
	var tag := "TOTALED"
	draw_rect(Rect2(PIC.position.x + 8, PIC.position.y + 8, PixelFont.width(tag, 2) + 12, 16), Color(RED.darkened(0.55), 0.95 * a))
	PixelFont.draw(self, PIC.position + Vector2(14, 12), tag, Color(RED.lightened(0.3), a), 2)
	if car_name != "":
		var cw := PixelFont.width(car_name, 1) + 10
		draw_rect(Rect2(PIC.end.x - cw - 8, PIC.position.y + 8, cw, 11), Color(0, 0, 0, 0.75 * a))
		PixelFont.draw(self, Vector2(PIC.end.x - cw - 3, PIC.position.y + 11), car_name, Color(BONE, a))
	# the caption, in the same box the cutscenes use
	var by := 238.0
	var bh := 24.0 + lines.size() * 18.0 + 14.0
	draw_rect(Rect2(8, by, 624, bh), Color(0.04, 0.035, 0.05, 0.94 * a))
	draw_rect(Rect2(8, by, 624, bh), Color(1, 1, 1, 0.14 * a), false, 1.0)
	draw_rect(Rect2(16, by - 6, PixelFont.width("CAUSE OF DEATH", 2) + 12, 14), Color(GOLD.darkened(0.55), 0.95 * a))
	PixelFont.draw(self, Vector2(22, by - 3), "CAUSE OF DEATH", Color(GOLD.lightened(0.2), a), 2)
	var shown := mini(caption.length(), int(maxf(0.0, t - 0.6) * 70.0))
	var left := shown
	for k in lines.size():
		var ln: String = lines[k]
		var part := ln.substr(0, clampi(left, 0, ln.length()))
		left -= ln.length() + 1
		BigFont.draw_centered(self, 320, by + 16 + k * 18, part if part.length() == ln.length() else part + " ".repeat(ln.length() - part.length()), Color(BONE, a), 2, true, INK)
	# the numbers, like the HUD would show them
	var stats := "IMPACT %d KM/H   HIT %s" % [int(info.get("speed_kmh", 0.0)), WHAT.get(String(info.get("cause", "")), "SOMETHING")]
	if String(info.get("place", "")) != "": stats += "   " + String(info.place)
	PixelFont.draw(self, Vector2(18, by + bh - 12), stats, Color(ASH, a))
	if t > 1.4:
		var pa := 0.5 + 0.5 * sin(t * 4.0)
		var prompt := Hints.fmt("{ui_accept} CONTINUE >")
		PixelFont.draw(self, Vector2(624 - PixelFont.width(prompt), by + bh - 12), prompt, Color(GOLD, pa * a))

# ====================================================================== the picture

## Paint the wreck. Static so the tests and the screenshot pass can call it.
static func paint_scene(info: Dictionary, seed := 1) -> Image:
	var p := Pix.new(SW, SH, seed)
	var hour := float(info.get("time_h", 13.0))
	var night := hour < 6.0 or hour > 20.5
	var dusk := not night and (hour > 17.5 or hour < 7.5)
	var season := String(info.get("season", "summer"))
	var weather := String(info.get("weather", "clear"))
	var cause := String(info.get("cause", "tree"))
	var town := String(info.get("style", "rural")) in ["downtown", "oldtown", "commercial", "residential", "industrial"] or cause == "building"
	_sky(p, night, dusk, weather)
	if cause == "edge":
		_far(p, night, dusk, season, false)
		_ground(p, night, season, 0, 190)
		_void(p, 190)
	elif cause == "water" or cause == "rail":
		_far(p, night, dusk, season, false)
		_river(p, night, cause == "rail")
	else:
		_far(p, night, dusk, season, town)
		_ground(p, night, season, 0, SW)
		if town: _sidewalk(p, night)
		else: _fence(p, night, season)
		_road(p, night, season)
	_wreck(p, info, night, season, seed)
	_weather(p, weather, season, night)
	if night: _night_tint(p)
	return p.img

static func _sky(p: Pix, night: bool, dusk: bool, weather: String) -> void:
	var overcast := weather in ["cloudy", "rain", "drizzle", "storm", "fog", "snow"]
	if night:
		p.grad_v(0, 0, SW, 70, Color("05070f"), Color("141a30"), 6)
		if not overcast:
			p.speckle(0, 0, SW, 50, Color("c8d0e8"), 0.012)
			p.speckle(0, 0, SW, 40, Color("ffffff"), 0.004)
			p.disc(240, 14, 5.5, Color("e8e4d0"))
			p.disc(242, 13, 4.5, Color("05070f").lerp(Color("141a30"), 0.1))
	elif dusk:
		p.grad_v(0, 0, SW, 70, Color("2a2448"), Color("f0884a"), 7)
		p.disc(230, 60, 9.0, Color("ffd890"))
	else:
		p.grad_v(0, 0, SW, 70, Color("4a7ab8") if not overcast else Color("6a7480"), Color("b8d0e0") if not overcast else Color("a8b0b8"), 6)
	if overcast:
		for k in 9:
			var cx := (k * 41 + 13) % SW
			var cy := 6 + (k * 17) % 26
			var cc := Color("1a1e2a") if night else Color("8a929c")
			p.ellipse(cx, cy, 26.0, 6.0, cc)
			p.ellipse(cx + 8, cy - 3, 16.0, 5.0, cc.lightened(0.06))
	elif not night:
		for k in 4:
			var cx := (k * 83 + 30) % SW
			var cy := 10 + (k * 13) % 20
			p.ellipse(cx, cy, 18.0, 4.0, Color(1, 1, 1, 0.75))
			p.ellipse(cx + 6, cy - 2, 10.0, 3.0, Color(1, 1, 1, 0.9))

## Far hills (the Caledonia Highlands, blue in the distance), spruce lines, or a town skyline.
static func _far(p: Pix, night: bool, dusk: bool, season: String, town: bool) -> void:
	var hill := Color("4a5a78") if not night else Color("0e1220")
	if dusk: hill = Color("5a4a6a")
	for x in SW:
		var hy := 44 + int(sin(float(x) * 0.021) * 6.0 + sin(float(x) * 0.057 + 1.3) * 3.0)
		p.vline(x, hy, 70 - hy, hill)
		if season == "winter" and not night and (x % 3 != 0): p.px(x, hy, Color("e8eef4"))
	if town:
		var bx := 0
		var k := 0
		while bx < SW:
			var bw := 18 + (k * 7) % 22
			var bh := 16 + (k * 13) % 26
			var bc := Color("3a3e4a") if not night else Color("12141c")
			p.rect(bx, 66 - bh, bw, bh, bc)
			p.hline(bx, 66 - bh, bw, bc.lightened(0.15))
			for wy in range(66 - bh + 3, 62, 5):
				for wx in range(bx + 2, bx + bw - 2, 4):
					var lit := night and ((wx * 7 + wy * 3 + k) % 5 < 2)
					p.rect(wx, wy, 2, 2, Color("f0c870") if lit else bc.lightened(0.1))
			bx += bw + 2
			k += 1
		return
	# spruce and fir, two rows, the near one darker
	for row in 2:
		var base_y := 62 + row * 4
		var x := -4 + row * 5
		var k := 0
		while x < SW:
			var th := 10 + ((x * 13 + k * 7 + row * 5) % 9) + row * 3
			var tc := Color("1e3a2a") if row == 0 else Color("16301f")
			if night: tc = Color("070c0a") if row == 0 else Color("040806")
			if season == "fall" and k % 4 == 1 and row == 1 and not night: tc = Color("8a4a1a")
			for yy in th:
				var hw := int(float(yy) * 0.36) + 1
				p.hline(x - hw, base_y - th + yy, hw * 2 + 1, tc)
				if yy % 3 == 2: p.px(x + hw, base_y - th + yy, tc.lightened(0.12))
			if season == "winter" and not night:
				for yy in range(2, th, 3): p.px(x - int(float(yy) * 0.36), base_y - th + yy, Color("e8eef4"))
			p.vline(x, base_y, 2, Color("2a1e14"))
			x += 5 + (x * 3 + k) % 5
			k += 1

static func _ground_col(season: String, night: bool) -> Color:
	var g: Color = { "summer": Color("4e7a3a"), "spring": Color("5a8a40"), "fall": Color("7a7038"), "winter": Color("dfe6ee") }.get(season, Color("4e7a3a"))
	return g.darkened(0.7) if night else g

static func _ground(p: Pix, night: bool, season: String, x0: int, x1: int) -> void:
	var g := _ground_col(season, night)
	p.rect(x0, 66, x1 - x0, SH - 66, g)
	p.grad_v(x0, 66, x1 - x0, 10, g.darkened(0.15), g, 3)
	p.rng.seed = 99
	for i in int(float((x1 - x0) * (SH - 66)) * 0.09):
		var x := x0 + p.rng.randi() % maxi(1, x1 - x0)
		var y := 68 + p.rng.randi() % (SH - 68)
		var c := g.darkened(0.2) if p.rng.randf() < 0.5 else g.lightened(0.12)
		if season == "winter": c = Color("b8c8d8") if not night else g.lightened(0.1)
		p.px(x, y, c)
		if season != "winter" and p.rng.randf() < 0.4: p.px(x, y - 1, c)       # tufts
	if season == "fall" and not night:
		for i in 140:
			p.px(x0 + p.rng.randi() % maxi(1, x1 - x0), 70 + p.rng.randi() % (SH - 70), [Color("c8501e"), Color("e0a028"), Color("a83a1a")][i % 3])

static func _fence(p: Pix, night: bool, season: String) -> void:
	var wood := Color("6a4a2c") if not night else Color("1a120c")
	for x in range(2, 200, 14):
		p.rect(x, 58, 2, 13, wood)
		p.px(x, 58, wood.lightened(0.2))
	p.rect(0, 61, 200, 1, wood.lightened(0.1))
	p.rect(0, 65, 200, 1, wood)
	if season == "winter" and not night: p.rect(0, 60, 200, 1, Color("e8eef4"))

static func _sidewalk(p: Pix, night: bool) -> void:
	var c := Color("8a8a86") if not night else Color("2a2a2c")
	p.rect(0, 70, SW, 6, c)
	for x in range(0, SW, 12): p.vline(x, 70, 6, c.darkened(0.2))
	p.hline(0, 76, SW, c.darkened(0.35))                        # the curb

## The road coming at you on the right: asphalt, white edge line, yellow centre dashes, a gravel shoulder.
static func _road(p: Pix, night: bool, season: String) -> void:
	var asphalt := Color("3e3e44") if not night else Color("141418")
	var edge_a := Vector2(150, SH)
	var edge_b := Vector2(268, 66)
	var road := PackedVector2Array([edge_a, Vector2(SW + 40, SH), Vector2(SW, 66), edge_b])
	var shoulder := PackedVector2Array([edge_a - Vector2(14, 0), edge_a, edge_b, edge_b - Vector2(4, 0)])
	p.poly(shoulder, Color("7a746a") if not night else Color("242220"))
	p.poly(road, asphalt)
	p.rng.seed = 5
	for i in 900:
		var y := 66 + p.rng.randi() % (SH - 66)
		var f := float(y - 66) / float(SH - 66)
		var xl := lerpf(edge_b.x, edge_a.x, f)
		var x := int(xl) + p.rng.randi() % maxi(1, SW - int(xl))
		p.px(x, y, asphalt.lightened(0.08) if i % 2 == 0 else asphalt.darkened(0.1))
	p.line(int(edge_a.x) + 3, SH - 1, int(edge_b.x) + 1, 66, Color("e8e8e0") if not night else Color("6a6a66"))
	# yellow centre dashes, getting shorter into the distance
	for k in 7:
		var f0 := float(k) / 7.0
		var f1 := f0 + 0.07
		var xa := lerpf(250.0, 292.0, f0)
		var ya := lerpf(float(SH), 66.0, f0)
		var xb := lerpf(250.0, 292.0, f1)
		var yb := lerpf(float(SH), 66.0, f1)
		p.line(int(xa), int(ya), int(xb), int(yb), Color("e8c040") if not night else Color("6a5a20"))
	if season == "winter":
		# a plow bank along the shoulder
		for y in range(66, SH):
			var f := float(y - 66) / float(SH - 66)
			var xl := int(lerpf(edge_b.x, edge_a.x, f)) - 6 - int(f * 12.0)
			p.hline(xl, y, 4 + int(f * 8.0), Color("e8eef4") if not night else Color("4a525e"))

static func _river(p: Pix, night: bool, bridge: bool) -> void:
	# the Petitcodiac: brown (the "Chocolate River"), mud banks
	var mud := Color("6a5038") if not night else Color("1e160e")
	var water := Color("7a5a3a") if not night else Color("1a140e")
	p.rect(0, 64, SW, SH - 64, water)
	p.grad_v(0, 64, SW, 8, mud, water, 3)
	for y in range(70, SH, 3):
		for x in range((y * 7) % 9, SW, 9):
			p.hline(x, y, 3 + (x + y) % 3, water.lightened(0.1) if (x + y) % 2 == 0 else water.darkened(0.1))
	if bridge:
		var deck := Color("8a8680") if not night else Color("2a2826")
		p.rect(0, 64, 205, 8, deck)
		p.hline(0, 64, 205, deck.lightened(0.15))
		p.rect(0, 72, 205, 3, deck.darkened(0.35))
		for x in [40, 140]: p.rect(x, 75, 10, SH - 75, deck.darkened(0.15))         # piers
		# the rail: posts and a beam, torn open at the end
		var rail := Color("b8bcc0") if not night else Color("3a3c40")
		for x in range(4, 186, 10): p.rect(x, 56, 2, 8, rail.darkened(0.3))
		p.rect(0, 57, 182, 2, rail)
		p.line(182, 57, 196, 50, rail)
		p.line(183, 59, 194, 66, rail)

## The edge of the map: ground stops, and past it the missing-texture checkerboard.
static func _void(p: Pix, x0: int) -> void:
	for y in SH:
		for x in range(x0, SW):
			var k := ((x - x0) / 6 + y / 6) % 2
			p.px(x, y, Color("ff00dc") if k == 0 else Color("000000"))
	for y in range(66, SH): p.px(x0, y, Color("2a2018"))
	p.rect(x0 - 26, 50, 2, 18, Color("6a6a6e"))
	p.rect(x0 - 34, 44, 18, 8, Color("e8c040"))
	p.text(x0 - 33, 46, "END", Color("1a1614"))

# ---------------------------------------------------------------- the wreck itself

static func _driver(info: Dictionary) -> Dictionary:
	var seed := int(StoryScript.CAST.LEO.seed)
	var fem := 0
	var age := 19
	var who := String(info.get("driver", "LEO"))
	if who == "AVATAR" and not StoryState.avatar.is_empty():
		seed = int(StoryState.avatar.seed)
		fem = int(StoryState.avatar.female)
		age = int(StoryState.avatar.age)
	elif StoryScript.CAST.has(who):
		seed = int(StoryScript.CAST[who].seed)
		fem = int(StoryScript.CAST[who].female)
		age = int(StoryScript.CAST[who].age)
	var civ := Face.civilian(seed, fem, age)
	var look: Dictionary = civ.look
	return {
		"skin": Pix.hex(Face.SKIN_TONES[int(look.skin)]),
		"hair": Pix.hex(Face.HAIR_COLORS[int(look.hairColor)]),
		"long_hair": int(look.hair) in [5, 7, 9],
		"sleeve": Pix.hex(int(PixPeople.OUTFITS.get(who, {}).get("top", civ.accent))),
	}

static func _wreck(p: Pix, info: Dictionary, night: bool, season: String, seed: int) -> void:
	var cause := String(info.get("cause", "tree"))
	# the car you were in, drawn as itself when we know which it was
	var car: Dictionary = { "id": String(info.get("car", "")), "body": String(info.get("body", "sedan")), "length": float(info.get("length", 4.6)) }
	var paint: Color = info.get("paint", Color("c8342c"))
	var looks: Dictionary = info.get("looks", {})
	var len := clampi(int(float(info.get("length", 4.6)) * 19.0), 78, 118)
	var speed := float(info.get("speed_kmh", 100.0))
	var crush := clampf((speed - 60.0) / 90.0, 0.45, 1.0)
	var wheel_off: bool = info.get("wheeloff", false)
	var dmg := {
		"front": crush, "glass": true, "smoke": 0.8, "bumper": "gone" if crush > 0.7 else "hang",
		"lights": night and info.get("lights", true), "driver": _driver(info),
	}
	if wheel_off: dmg.wheel_off = "front"
	if info.get("flat", false): dmg.flat = "rear"
	var gy := 98                                   # where the tires touch
	var x := 48
	var tilt := 0.0                                # a car on three wheels sits itself down
	match cause:
		"tree":
			x = 40
			var nose := x + int(len * (1.0 - crush * 0.2))
			_skids(p, x, gy, night)
			PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
			_tree(p, nose + 1, gy + 2, night, season)
			_glass(p, nose, gy, seed)
		"building":
			x = 60
			var nose := x + int(len * (1.0 - crush * 0.2))
			_wall(p, nose - 6, night)
			PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
			_rubble(p, nose - 8, gy, night)
		"traffic":
			var sub := String(info.get("sub", "tbone"))
			var other: Dictionary = { "id": String(info.get("other_id", "")), "body": String(info.get("other_body", "van")) }
			var other_paint: Color = info.get("other_paint", Color("d8d4c8"))
			var olen := 76 if String(CarGen.design(other).family) in ["van", "suv", "pickup", "boxtruck", "offroad"] else 68
			x = 30
			var nose := x + int(len * (1.0 - crush * 0.2))
			match sub:
				"headon":
					var od := { "front": crush * 0.9, "glass": true, "smoke": 0.5, "bumper": "gone" }
					PixCars.draw_car(p, nose + 2 - int(olen * crush * 0.9 * 0.2), gy, olen, other, other_paint, od, true)
					PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
				"rear":
					var od := { "rear": crush, "glass": true, "smoke": 0.0 }
					PixCars.draw_car(p, nose - int(olen * crush * 0.16) - 2, gy, olen, other, other_paint, od, false)
					PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
				_:
					var od := { "roof": 0.6, "glass": true, "smoke": 0.0 }
					PixCars.draw_car(p, nose - olen / 2 - 6, gy - 8, olen, other, other_paint.darkened(0.08), od, true)
					PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
			_glass(p, nose, gy, seed)
		"rail":
			x = 190 - int(len * 0.19)
			PixCars.draw_car(p, x, 64, len, car, paint, dmg, false, 0.5, looks)
			_splash(p, x + int(len * 0.95), 96, night)
		"water":
			x = 100
			dmg.erase("driver")
			dmg.smoke = 0.0
			dmg.front = 0.1
			dmg.lights = night
			_bank(p, night, x)
			PixCars.draw_car(p, x, 100, len, car, paint, dmg, false, 0.16, looks)
			_waterline(p, x - 8, x + len + 14, 90, night)
		"edge":
			x = 186 - int(len * 0.19)
			PixCars.draw_car(p, x, 92, len, car, paint, dmg, false, 0.38, looks)
		_:
			PixCars.draw_car(p, x, gy, len, car, paint, dmg, false, tilt, looks)
	if wheel_off and cause != "water":
		# the one that got away, rolling off down the road
		var r := float(PixCars.wheel_spots(car, len)[1][1])
		PixCars.wheel(p, 262, gy - 4 - int(r), r, PixCars.stock_rim(car))
		p.hline(254, gy - 3, 18, Color(0, 0, 0, 0.35))

static func _tree(p: Pix, x: int, gy: int, night: bool, season: String) -> void:
	var bark := Color("4a3a2c") if not night else Color("161210")
	# canopy first (behind the trunk's top)
	var leaf: Color = { "summer": Color("3a6a2a"), "spring": Color("4a8a34"), "fall": Color("c8501e"), "winter": Color("00000000") }.get(season, Color("3a6a2a"))
	if night and season != "winter": leaf = leaf.darkened(0.75)
	if season != "winter":
		for k in 9:
			var cx := x + 5 + int(sin(float(k) * 2.1) * 26.0)
			var cy := 10 + int(cos(float(k) * 1.7) * 9.0) + k % 3 * 6
			p.disc(cx, cy, 13.0 - float(k % 3), leaf)
			p.disc(cx - 3, cy - 3, 7.0, leaf.lightened(0.12))
			p.speckle(cx - 12, cy - 12, 24, 24, leaf.darkened(0.25), 0.08)
		if season == "fall" and not night:
			p.speckle(x - 30, 0, 70, 30, Color("e0a028"), 0.06)
	else:
		for k in 6:
			var a := -PI / 2.0 + (float(k) - 2.5) * 0.35
			p.line(x + 5, 30, x + 5 + int(cos(a) * 30.0), 30 + int(sin(a) * 30.0), bark)
			if not night: p.px(x + 5 + int(cos(a) * 28.0), 30 + int(sin(a) * 28.0) - 1, Color("e8eef4"))
	p.rect(x, 18, 11, gy - 18, bark)
	p.vline(x, 18, gy - 18, bark.lightened(0.15))
	p.vline(x + 10, 18, gy - 18, bark.darkened(0.3))
	for y in range(20, gy, 5):
		p.hline(x + 2 + (y % 3), y, 3, bark.darkened(0.25))
	p.rect(x - 2, gy - 3, 15, 3, bark.darkened(0.1))          # roots
	# a scar where the bark came off
	p.rect(x, gy - 22, 4, 9, Color("c8a878") if not night else Color("3a3020"))

static func _wall(p: Pix, x: int, night: bool) -> void:
	p.bricks(x, 8, SW - x, 92, Color("8a3a2a") if not night else Color("2a1410"), Color("b8aa98") if not night else Color("2a2622"))
	# a shop window with a sign over it
	var glass := Color("1c2430") if not night else Color("c8a060")
	p.rect(x + 40, 40, 60, 34, glass)
	p.frame(x + 40, 40, 60, 34, Color("1a1614"))
	p.hline(x + 41, 60, 58, Color("6a4a2a"))                       # the display shelf
	for k in 6: p.ellipse(x + 47 + k * 9, 57, 3.5, 2.0, Color("c8883a"))      # loaves
	for k in 3: p.line(x + 44 + k * 18, 42, x + 52 + k * 18, 52, Color(1, 1, 1, 0.35))
	p.rect(x + 82, 63, 14, 6, Color("1a1614"))
	p.text(x + 83, 64, "OPEN", Color("e0402e"))
	p.rect(x + 36, 28, 68, 9, Color("1a3a6a"))
	p.text(x + 40, 30, "BAKERY", Color("f0e8d0"))
	# the hole the car made
	for y in range(46, 100):
		var jag := (y * 7) % 5
		p.rect(x - 1, y, 10 + jag, 1, Color("1a1410"))

static func _rubble(p: Pix, x: int, gy: int, night: bool) -> void:
	p.rng.seed = 3
	for i in 40:
		var bx := x - 4 + p.rng.randi() % 34
		var by := gy - 6 + p.rng.randi() % 10
		p.box(bx, by, 4, 2, Color("8a3a2a") if not night else Color("2a1410"), false)
	p.glow(x + 6, gy - 20, 18.0, Color(0.75, 0.7, 0.62), 0.6)       # brick dust

static func _skids(p: Pix, x: int, gy: int, night: bool) -> void:
	var c := Color(0.05, 0.05, 0.06, 0.6)
	for k in 2:
		for xx in range(x + 40, 240):
			var yy := gy + 1 + k * 3 + int(sin(float(xx) * 0.06) * 2.0)
			p.px(xx, yy, c)

static func _glass(p: Pix, x: int, gy: int, seed: int) -> void:
	p.rng.seed = seed
	for i in 26:
		p.px(x - 6 + p.rng.randi() % 30, gy - 2 + p.rng.randi() % 6, Color("d8e8f0") if i % 2 == 0 else Color("8aa8c0"))

static func _splash(p: Pix, x: int, y: int, night: bool) -> void:
	var c := Color("e8e0d0") if not night else Color("5a5450")
	for k in 12:
		var a := PI + float(k) / 11.0 * PI
		p.line(x, y, x + int(cos(a) * (8.0 + k % 3 * 4)), y + int(sin(a) * (10.0 + k % 4 * 3)), c)

## The near bank: mud and grass, with tire tracks running into the water.
static func _bank(p: Pix, night: bool, x: int) -> void:
	var mud := Color("5a4430") if not night else Color("1a120c")
	var pts := PackedVector2Array([Vector2(0, 80), Vector2(x + 10, 84), Vector2(x + 30, SH), Vector2(0, SH)])
	p.poly(pts, mud)
	p.speckle(0, 82, x + 20, SH - 82, mud.lightened(0.12), 0.08)
	p.poly(PackedVector2Array([Vector2(0, 74), Vector2(x - 20, 78), Vector2(x - 6, 84), Vector2(0, 86)]), Color("4e7a3a") if not night else Color("101a0c"))
	for k in 2:
		p.line(10, 96 + k * 6, x + 12, 88 + k * 4, mud.darkened(0.35))

static func _waterline(p: Pix, x0: int, x1: int, y: int, night: bool) -> void:
	var water := Color("7a5a3a") if not night else Color("1a140e")
	for yy in range(y, SH):
		for xx in range(x0, x1):
			var c := water if (xx + yy) % 7 != 0 else water.lightened(0.1)
			p.px(xx, yy, c)
	for xx in range(x0, x1, 2): p.px(xx, y, water.lightened(0.25))
	for k in 6: p.ring(x0 + 20 + k * 11, y - 4 - (k * 5) % 9, 1.5, Color(0.9, 0.85, 0.75, 0.8))   # bubbles

static func _weather(p: Pix, weather: String, season: String, night: bool) -> void:
	p.rng.seed = 21
	match weather:
		"rain", "drizzle", "storm":
			var n := 260 if weather != "drizzle" else 110
			for i in n:
				var x := p.rng.randi() % SW
				var y := p.rng.randi() % SH
				p.line(x, y, x - 1, y + 3, Color(0.75, 0.8, 0.9, 0.55 if not night else 0.3))
		"snow":
			for i in 220: p.px(p.rng.randi() % SW, p.rng.randi() % SH, Color(1, 1, 1, 0.9))
		"fog":
			for y in range(10, 96):
				var f := 1.0 - absf(float(y) - 55.0) / 45.0
				for x in SW:
					if Pix.dith(x, y, f * 0.42): p.px(x, y, Color(0.86, 0.87, 0.89, 0.55))

static func _night_tint(p: Pix) -> void:
	# a vignette so the wreck sits in a pool of its own lights
	for y in SH:
		for x in SW:
			var d := Vector2((x - 110) / 150.0, (y - 85) / 70.0).length()
			if d > 0.9 and Pix.dith(x, y, clampf((d - 0.9) * 1.5, 0.0, 1.0)):
				p.img.set_pixel(x, y, p.img.get_pixel(x, y).darkened(0.5))
