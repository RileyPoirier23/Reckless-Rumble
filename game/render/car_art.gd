## Draws a car, pixel by pixel, as a stack of horizontal slices (sprite stacking).
##
## Like CAGE BOSS's portrait generator: no image files, just a recipe. Slice 0 is the
## undercarriage, the last slice is the roof. The game stacks them 1 px apart and rotates
## each one, so the car turns smoothly through 360° and still looks hand-pixelled.
## Front of the car = +x in every slice.
class_name CarArt
extends RefCounted

const PX := 12.0         # pixels per metre (the whole game uses this)
const CAR_SCALE := 1.25  # cars in the world are drawn (and bump into things) this much bigger than life,
                         # so they hold their own next to the roads; the driving physics don't change
const SLICES := 16
const K := PX / 8.0      # the recipe is written in 8 px/m units and drawn finer

## A light that reaches the road. The ground, the road and the skid marks are drawn far below
## the cars (z about -4000), past a Light2D's default z range, and the tree tops and clouds above
## them shouldn't light up.
static func reach_road(l: Light2D) -> void:
	l.range_z_min = RenderingServer.CANVAS_ITEM_Z_MIN
	l.range_z_max = 2999

## A headlight beam, pointing along +x from the left edge of the texture: nothing at the lamp
## itself (so the car's own hood stays dark), brightest a few metres out, fading with distance
## and spreading wider as it goes.
static func beam_tex(w: int, h: int, strength := 1.0) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var dx := float(x) / float(w)
			var dy := absf(float(y) - h / 2.0) / (h / 2.0)
			var spread := 0.25 + 0.75 * dx
			var a := smoothstep(0.0, 0.12, dx) * pow(1.0 - dx, 1.4) * clampf(1.0 - dy / spread, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * strength))
	return ImageTexture.create_from_image(img)

var length_px: int
var width_px: int
var wheelbase_px: float
var slices: Array[ImageTexture] = []
var brake_lights: Array[ImageTexture] = []     # same size as slices; only the lit pixels
var reverse_lights: Array[ImageTexture] = []
var head_lights: Array[ImageTexture] = []
var blink_left: Array[ImageTexture] = []      # turn signals, lit pixels only
var blink_right: Array[ImageTexture] = []
const AMBER_OFF := Color("a8661a")
const AMBER_LIT := Color("ffb02a")
var size: Vector2i

const TIRE := Color("141414")
const RIM := Color("8a8e94")
const GLASS := Color("1c2633")
const GLASS_HI := Color("3b5068")
const TRIM := Color("1d1b20")
const UNDER := Color("100e12")
const HEAD := Color("f4ecc2")
const TAIL := Color("9a1c1c")
const TAIL_LIT := Color("ff3b2e")
const REV_LIT := Color("f4f4f0")

var body := "coupe"      # coupe, hatch, sedan, tow
const AMBER := Color("ffa020")
const STEEL := Color("6a6e74")

## Damage by side: 0..1 each. A plain number still works (spread around the car).
var dmg := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
var px := PX              # this art's pixels per metre (PX x the scale it was drawn at)
var k := K
var bumper_front := true
var bumper_rear := true
var head_ok := [true, true]     # left, right
var tail_ok := [true, true]
const PRIMER := Color("8a8a84")

func _init(spec: Dictionary, paint: Color, damage = 0.0, seed := 1, scale := 1.0) -> void:
	px = PX * scale
	k = px / 8.0
	body = String(spec.get("body", "coupe"))
	if damage is Dictionary:
		for zk in dmg: dmg[zk] = clampf(float(damage.get(zk, 0.0)), 0.0, 1.0)
	else:
		for zk in dmg: dmg[zk] = clampf(float(damage), 0.0, 1.0) * 0.6
	bumper_front = dmg.front < 0.65
	bumper_rear = dmg.rear < 0.65
	# a hard hit on one corner takes that side's lamps out
	head_ok = [not (dmg.front > 0.45 and dmg.left >= dmg.right * 0.8), not (dmg.front > 0.45 and dmg.right > dmg.left * 0.8)]
	tail_ok = [not (dmg.rear > 0.45 and dmg.left >= dmg.right * 0.8), not (dmg.rear > 0.45 and dmg.right > dmg.left * 0.8)]
	length_px = int(round(float(spec.length) * px))
	width_px = int(round(float(spec.width) * px))
	if width_px % 2 == 1: width_px += 1
	wheelbase_px = float(spec.wheelbase) * px
	size = Vector2i(length_px + 4, width_px + 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for z in SLICES:
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		var brake := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		var rev := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		var head := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		_bl = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		_br = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		_slice(img, brake, rev, head, z, paint, 0.0, rng)
		_outline(img)
		slices.append(ImageTexture.create_from_image(img))
		brake_lights.append(ImageTexture.create_from_image(brake))
		reverse_lights.append(ImageTexture.create_from_image(rev))
		head_lights.append(ImageTexture.create_from_image(head))
		blink_left.append(ImageTexture.create_from_image(_bl))
		blink_right.append(ImageTexture.create_from_image(_br))

var _bl: Image
var _br: Image

## centre-relative coordinates: u along the car (+ = front), v across (+ = right side)
func _uv(x: int, y: int) -> Vector2:
	return Vector2(x + 0.5 - size.x / 2.0, y + 0.5 - size.y / 2.0)

static func _rounded(u: float, v: float, hl: float, hw: float, cr: float) -> bool:
	var au := absf(u)
	var av := absf(v)
	if au > hl or av > hw: return false
	if au > hl - cr and av > hw - cr:
		return Vector2(au - (hl - cr), av - (hw - cr)).length() <= cr
	return true

func _slice(img: Image, brake: Image, rev: Image, head: Image, z: int, paint: Color, _unused: float, rng: RandomNumberGenerator) -> void:
	var hl := length_px / 2.0 / k
	var hw := width_px / 2.0 / k
	var wf := wheelbase_px / 2.0 / k       # front axle at +wf, rear at -wf
	var shade := 0.58 + 0.42 * float(z) / float(SLICES - 1)
	var zz := int(float(z) * 12.0 / float(SLICES))   # which layer of the 12-layer recipe
	var bodyc := paint * shade
	bodyc.a = 1.0
	# where the cabin sits along the car, by body style
	var cab_f := 0.30
	var cab_b := -0.50
	match body:
		"hatch": cab_f = 0.24; cab_b = -0.84
		"sedan": cab_f = 0.32; cab_b = -0.52
		"tow": cab_f = 0.42; cab_b = 0.04
	var truck := body == "tow"
	var boxy := body in ["ambulance", "fire"]
	for y in size.y:
		for x in size.x:
			var p := _uv(x, y) / k
			var u := p.x
			var v := p.y
			var c := Color(0, 0, 0, 0)
			var rear_wheel := absf(u + wf) <= 3.0 and absf(v) >= hw - 2.5 and absf(v) <= hw + 0.4
			if boxy and zz >= 7:
				c = _box_layer(u, v, hl, hw, zz, bodyc)
			elif truck and zz >= 7:
				c = _tow_layer(u, v, hl, hw, zz, bodyc)
			else:
				match zz:
					0, 1:
						if _rounded(u, v, hl - 2.0, hw - 1.5, 2.0): c = UNDER
						if rear_wheel: c = TIRE if zz == 0 or absf(u + wf) > 1.0 else RIM * 0.7
					2, 3:
						if _rounded(u, v, hl, hw, 3.0):
							c = bodyc
							var arch := (absf(u - wf) <= 3.4 or absf(u + wf) <= 3.4) and absf(v) >= hw - 1.6
							if arch: c = TIRE if absf(absf(u) - wf) > 1.2 else RIM * (0.6 + 0.15 * zz)
							if u > hl - 1.4 or u < -hl + 1.4: c = TRIM.lerp(bodyc, 0.25)        # bumpers
						if truck and u < -hl + 1.4:
							c = Color("1a1a1e")                                              # the wheel-lift crossbar
							if absf(v) > hw - 1.8: c = Color("e0b020")                       # ...and its yellow hooks
							if absf(v) > hw - 0.8 and absf(absf(u) - wf) > 3.4 and zz == 2: c = TRIM.lerp(bodyc, 0.5)   # skirt line
					4, 5:
						if _rounded(u, v, hl, hw, 3.0):
							c = bodyc
							if u > hl - 1.6 and absf(v) < 2.2: c = TRIM                       # grille
							if u > hl - 1.8 and absf(v) >= 2.6 and absf(v) <= hw - 0.6:     # headlights
								c = HEAD * 0.85
								if head_ok[0 if v < 0.0 else 1]: head.set_pixel(x, y, HEAD)
								else: c = Color("2a2a2e")                                     # smashed
							if u < -hl + 1.6 and absf(v) >= 2.4 and absf(v) <= hw - 0.4:    # taillights
								c = TAIL
								if tail_ok[0 if v < 0.0 else 1]: brake.set_pixel(x, y, TAIL_LIT)
								else: c = Color("3a1a1a")
								if absf(v) < 3.6: rev.set_pixel(x, y, REV_LIT)
							if u < -hl + 1.2 and absf(v) < 1.6: c = Color("d8d4c0") * 0.8   # plate
							# turn signals: amber at the front corners; at the back the corners are part of the
							# red tail lamp and flash red (the North American way)
							if u > hl - 2.2 and absf(v) > hw - 1.5:
								c = AMBER_OFF
								(_bl if v < 0.0 else _br).set_pixel(x, y, AMBER_LIT)
							elif u < -hl + 1.8 and absf(v) > hw - 1.1:
								c = TAIL
								(_bl if v < 0.0 else _br).set_pixel(x, y, TAIL_LIT)
								if tail_ok[0 if v < 0.0 else 1]: brake.set_pixel(x, y, TAIL_LIT)
							if absf(absf(u) - wf) <= 3.4 and absf(v) >= hw - 0.6 and zz == 4: c = bodyc * 0.82   # arch lip
					6:
						if _rounded(u, v, hl - 0.6, hw - 0.6, 3.0):
							c = bodyc
							if u > 6.0 and absf(v) < 0.6: c = bodyc * 1.12           # hood crease
							if truck and u < hl * 0.02:
								c = STEEL * 0.75 if (int(absf(u) * 2.0) % 3 != 0) else STEEL * 0.55   # the wrecker deck
								c.a = 1.0
								if absf(v) > hw - 1.2: c = bodyc * 0.8
					7, 8, 9:
						var gk := float(zz - 7)
						var front := hl * 0.30 - gk * 1.3
						var back := -hl * 0.50 + gk * 1.0
						if u <= front and u >= back and absf(v) <= hw - 0.8 - gk * 0.7:
							c = GLASS
							if zz == 9 and u > front - 1.5: c = GLASS_HI                       # windshield glint
							if absf(u - (back + front) * 0.42) < 0.6: c = bodyc * 0.95        # B-pillar
							if u > front - 0.8 or u < back + 0.8: c = bodyc * 0.9             # A and C pillars
						elif _rounded(u, v, hl - 1.0 - k * 2.0, hw - 1.0, 3.0) and zz == 7 and (u > front or u < back):
							c = bodyc                                                          # hood and trunk top
					10, 11:
						var front2 := hl * cab_f - 4.2
						var back2 := hl * cab_b + 3.4
						if u <= front2 and u >= back2 and absf(v) <= hw - 3.0 + (1 if zz == 10 else 0):
							c = bodyc * (1.08 if zz == 11 else 1.0)
							if zz == 11 and v < -hw + 4.5: c = bodyc * 1.25                     # roof highlight
			if c.a > 0.0 and c != TIRE:
				c = _damaged(c, u, v, hl, hw, zz, rng)
			if c.a > 0.0: img.set_pixel(x, y, c)

## The upper half of a box-bodied truck (an ambulance, a fire engine): a cab up front with its
## windshield, and the box behind. The ambulance has a red band round the box and a cross on the
## roof; the fire engine's cab is as tall as its body, with the ladder racked on top.
func _box_layer(u: float, v: float, hl: float, hw: float, zz: int, bodyc: Color) -> Color:
	var fire := body == "fire"
	var cab_back := hl * (0.36 if not fire else 0.48)
	var gk := float(clampi(zz - 7, 0, 2))
	var front := hl * (0.72 if not fire else 0.86) - gk * 1.2
	var red := Color("c8281e") * (0.58 + 0.42 * float(zz) / 11.0)
	red.a = 1.0
	if u < cab_back and u > -hl + 0.6 and _rounded(u, v, hl - 0.6, hw - 0.4, 1.5):
		# the box
		var c := bodyc * (1.06 if zz >= 10 else 1.0)
		c.a = 1.0
		if not fire:
			if zz == 8 and (absf(v) > hw - 1.4 or u < -hl + 1.6): c = red              # the band
			if zz == 11 and ((absf(u + hl * 0.3) < 1.0 and absf(v) < 3.2) or (absf(v) < 1.0 and absf(u + hl * 0.3) < 3.2)): c = red
		else:
			if zz == 11:
				var rail := absf(v) > 1.5 and absf(v) < 2.1
				var rung := absf(v) <= 1.5 and int(floorf(u + 100.0)) % 3 == 0
				if rail or rung: c = STEEL * 0.9
				elif absf(v) <= 1.5: c = bodyc * 0.8
				c.a = 1.0
			if zz == 9 and absf(v) > hw - 1.0 and int(floorf(u + 100.0)) % 6 < 3: c = STEEL * 0.7     # compartment doors
			c.a = 1.0
		return c
	if u >= cab_back and u <= front and absf(v) <= hw - 0.8 - gk * 0.6:
		if fire or zz <= 9:
			if zz >= 10:
				return bodyc * 1.05 if not (zz == 11 and absf(v) < hw - 2.0 and absf(u - (cab_back + 1.5)) < 0.8) else Color("e0402e")
			var c2 := GLASS
			if zz == 9 and u > front - 1.5: c2 = GLASS_HI
			if u < cab_back + 1.2: c2 = bodyc * 0.9                                       # the back of the cab
			return c2
	if zz == 7 and u > front and _rounded(u, v, hl - 1.0, hw - 1.0, 3.0):
		return bodyc                                                                       # the hood
	return Color(0, 0, 0, 0)

## The top of a wrecker: a short cab with its glass, the headache rack behind it, the yellow boom
## down the middle of the deck with its ram beside it, and toolboxes along both sides.
func _tow_layer(u: float, v: float, hl: float, hw: float, zz: int, bodyc: Color) -> Color:
	var gk := float(clampi(zz - 7, 0, 2))
	var cab_back := hl * 0.06
	var front := hl * 0.46 - gk * 1.2
	var yellow := Color("e0b020") * (0.75 + 0.25 * float(zz) / 11.0)
	yellow.a = 1.0
	var dark := STEEL * 0.55
	dark.a = 1.0
	# the cab
	if u >= cab_back and absf(v) <= hw - 0.8 - gk * 0.6:
		if zz <= 9 and u <= front:
			if u < cab_back + 1.0 or u > front - 0.8: return bodyc * 0.9                   # B and A pillars
			return GLASS_HI if zz == 9 and u > front - 2.0 else GLASS
		if zz >= 10 and u <= hl * 0.40 and u >= cab_back + 0.6 and absf(v) <= hw - 1.6:
			return bodyc * 1.08                                                             # the roof
		if zz == 7 and u > front and _rounded(u, v, hl - 1.0, hw - 1.0, 3.0): return bodyc   # the hood
		return Color(0, 0, 0, 0)
	# the headache rack, right behind the cab
	if u < cab_back and u >= cab_back - 1.2 and absf(v) <= hw - 1.0 and zz <= 10:
		return dark if int(floorf(v + 100.0)) % 2 == 0 else STEEL * 0.8
	if u < cab_back - 1.2 and u > -hl + 1.4:
		# the boom down the middle, and the ram beside it
		if zz <= 9 and absf(v) <= 1.1:
			return yellow if absf(v) < 0.8 else yellow * 0.7
		if zz == 7 and absf(v) > 1.1 and absf(v) <= 1.8 and u < -hl * 0.1 and u > -hl * 0.55: return dark
		# toolboxes along the sides
		if zz == 7 and absf(v) > hw - 2.2 and absf(v) <= hw - 0.3 and u > -hl * 0.75:
			var lid := STEEL * (0.85 if int(floorf(u + 100.0)) % 4 != 0 else 0.6)
			lid.a = 1.0
			return lid
	return Color(0, 0, 0, 0)

## What the crash did to this pixel: dents (darker, crumpled) toward the side that got hit,
## paint scraped to primer along the sides, a missing bumper, cracked glass.
func _damaged(c: Color, u: float, v: float, hl: float, hw: float, zz: int, rng: RandomNumberGenerator) -> Color:
	var f: float = clampf((u - hl * 0.35) / (hl * 0.65), 0.0, 1.0) * dmg.front
	var r: float = clampf((-u - hl * 0.35) / (hl * 0.65), 0.0, 1.0) * dmg.rear
	var l: float = clampf((-v - hw * 0.35) / (hw * 0.65), 0.0, 1.0) * dmg.left
	var rt: float = clampf((v - hw * 0.35) / (hw * 0.65), 0.0, 1.0) * dmg.right
	var hit := f + r + l + rt
	if hit <= 0.0: return c
	# no bumper: the crash bar shows (thin and dark), the rest is gone
	if (not bumper_front and u > hl - 1.4 and zz <= 3) or (not bumper_rear and u < -hl + 1.4 and zz <= 3):
		return Color(0, 0, 0, 0) if absf(v) > hw * 0.75 or zz == 3 else Color("1a1a1e")
	if c == GLASS or c == GLASS_HI:
		# cracks spider out from the impact
		if rng.randf() < hit * 0.5: return Color("c8d0d8")
		return c
	# side swipes: long streaks of scraped paint, down to primer
	if (l > 0.05 or rt > 0.05) and absf(v) > hw - 1.6 and int(u * 3.0 + v) % 3 == 0 and rng.randf() < (l + rt) * 1.6:
		return c.lerp(PRIMER, 0.7)
	if rng.randf() < hit * 0.8:
		var dk := 0.5 + rng.randf() * 0.3
		return Color(c.r * dk, c.g * dk, c.b * dk, 1.0)
	return c

## A 1-px darker rim on every slice so the stack reads as a solid, outlined shape.
func _outline(img: Image) -> void:
	var src: Image = img.duplicate()
	for y in size.y:
		for x in size.x:
			var c := src.get_pixel(x, y)
			if c.a == 0.0: continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= size.x or q.y >= size.y or src.get_pixel(q.x, q.y).a == 0.0:
					edge = true
			if edge:
				img.set_pixel(x, y, Color(c.r * 0.55, c.g * 0.55, c.b * 0.6, 1.0))
