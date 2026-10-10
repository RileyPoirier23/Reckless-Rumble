## Draws a car top-down, pixel by pixel, as a stack of horizontal slices (sprite stacking).
##
## The car is the same car its side profile is painted from (CarGen.design, the CAGE BOSS way):
## the profile's top line is how high every column of the car stands, so the hood, the windshield,
## the roof, the backlight and the deck sit where they sit in the side view, and the wheels, the
## arches, the pillars, the lamps, the bumpers and the mirrors come from the same numbers. Across
## the car the body rounds over at the shoulders, the nose and the tail round off and taper by the
## car's own taste, and the greenhouse leans in (tumblehome). A Charjer, a Silvio and a Supreem
## are different shapes from above, not just different colours.
##
## The shape (the plan) is worked out once per car and kept. The paint, the mods (everything the
## garage sells), the wear traffic picks up (dirt, salt, rust, primer, a door off another car, a
## roof sign, a ladder rack, a magnetic sign on the doors) and the dents go on top of it every time
## a car is drawn. No image files: a recipe.
##
## Slices stand 1 px apart and a metre of car stands RISE metres of pixels tall, so a bus stands
## taller than a sports car. All the slices sit side by side in one texture, so a car is one
## draw batch. Front of the car = +x in every slice.
class_name CarArt
extends RefCounted

const PX := 12.0         # pixels per metre (the whole game uses this)
const CAR_SCALE := 1.25  # cars in the world are drawn (and bump into things) this much bigger than life,
                         # so they hold their own next to the roads; the driving physics don't change
const K := PX / 8.0      # (old recipe units: 8 px/m)
const RISE := 0.8        # how tall a metre of car stands, in pixels per pixel of length (the view is tipped)
const MX := 4            # room past the bumpers (bull bars, spares, wings, tips)
const MY := 3            # and past the sides (mirrors, flares, poke)

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

const TIRE := Color("16181c")
const RIM := Color("8a8e94")
const GLASS := Color("1c2633")
const GLASS_HI := Color("3b5068")
const TRIM := Color("1d1b20")
const UNDER := Color("100e12")
const HEAD := Color("f4ecc2")
const HEAD_RIM := Color("4a463e")
const TAIL := Color("9a1c1c")
const TAIL_LIT := Color("ff3b2e")
const REV_LIT := Color("f4f4f0")
const AMBER := Color("ffa020")
const AMBER_OFF := Color("a8661a")
const AMBER_LIT := Color("ffb02a")
const STEEL := Color("6a6e74")
const PRIMER := Color("8a8a84")
const INK := Color("15181f")
const CHROME: Array[Color] = [Color("3c434c"), Color("7a848f"), Color("b9c3cd"), Color("e6edf4"), Color("ffffff")]

## What a pixel is made of. A plan stores mat | shade << 8 | region << 12 | variant << 16.
enum { M_NONE, M_PAINT, M_GLASS, M_SIDEGLASS, M_TRIM, M_CHROME, M_TIRE, M_HEAD, M_TAIL, M_AMBER, M_REV,
	M_GRILLE, M_SEAT, M_BED, M_CARGO, M_SIGN, M_PLATE, M_BRAKE3, M_LIGHTBAR, M_STEEL, M_LADDER,
	M_DASH, M_BEACON, M_WOOD }
## Which panel a paint pixel is on (stripes, two-tone, a primer hood, a door off another car).
enum { R_NONE, R_HOOD, R_ROOF, R_DECK, R_BODY, R_PILLAR, R_BED, R_BOX, R_DOOR, R_SCOOP, R_FENDER }

## Mods that change the shape, not just the colours: they key the plan cache.
const SHAPE_MODS := ["spoiler", "kit", "fenders", "hood", "roof", "bash", "spare", "bed", "rollbar", "lightbar", "drop",
	"rim_size", "tire", "offset", "exhaust", "sign", "ladder", "load", "trailer"]

# ------------------------------------------------------------------ what callers read

var length_px: int
var width_px: int
var wheelbase_px: float
var size: Vector2i
var n := 16                         # slices
var atlas: ImageTexture             # every slice, side by side (slice z at x = z * size.x)
var lamp_z0 := 0                    # the lamps' slices: lamp_tex[kind] holds slices lamp_z0 .. lamp_z0 + lamp_n - 1
var lamp_n := 0
var lamp_tex := {}                  # "brake", "rev", "head", "bl", "br", "beacon" -> ImageTexture (lit pixels only)
var has_beacons := false            # an emergency rig's lights (lamp_tex.beacon) to flash when it runs code
var wheel_tex: ImageTexture         # one front wheel's stack, its slices side by side (rim face toward +y)
var wheel_n := 0
var wheel_size := Vector2i.ZERO
var wheel_spots: Array[Vector2] = [] # the front wheels' centres, px from the car's centre, left then right
var roof_z := 12.0                  # the top of the cabin, in slices (light bars, the police bar)
var px := PX * CAR_SCALE            # this art's pixels per metre (PX x the scale it was drawn at)
var k := K
var design: Dictionary

## Damage by side: 0..1 each. A plain number still works (spread around the car).
var dmg := { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }
var bumper_front := true
var bumper_rear := true
var head_ok := [true, true]     # left, right
var tail_ok := [true, true]

static var _plans := {}             # plan key -> Plan

## The shape of one car at one size: per pixel up to three runs of slices (the body, a wheel
## under it, something bolted on above it), what the top of each is, and where the lamps are.
class Plan:
	var key := ""
	var d: Dictionary
	var sx := 0
	var sy := 0
	var n := 1
	var lpx := 0
	var wpx := 0
	var zl := 1.0                   # slices per car length (design fractions -> slices)
	var h0 := PackedInt32Array()    # the body: top slice (-1 none)
	var b0 := PackedInt32Array()    # and bottom slice
	var m0 := PackedInt32Array()    # and what its top is
	var belt := PackedInt32Array()  # above this the body's sides are the greenhouse (glass)
	var gs := PackedInt32Array()    # and what the greenhouse's side is there (glass, a pillar)
	var h1 := PackedInt32Array()    # a wheel (or a spare)
	var b1 := PackedInt32Array()
	var m1 := PackedInt32Array()
	var h2 := PackedInt32Array()    # bolted on above: wings, racks, signs, bars
	var b2 := PackedInt32Array()
	var m2 := PackedInt32Array()
	var nmin := PackedInt32Array()  # the lowest top among the 8 neighbours (-2 for none): below it the side is hidden
	var nmin4 := PackedInt32Array() # among the 4: where the top's rim is
	var face := PackedByteArray()   # which way a visible side faces: 1 left/right, 2 front, 3 rear
	var ux := PackedFloat32Array()  # per column: 0 rear bumper .. 1 nose
	var hw := PackedFloat32Array()  # per column: half width (px)
	var doors := PackedByteArray()  # per column: 1 door shut line, 2 handle
	var wheels: Array = []          # [x centre, y centre, radius, width, front, outward sign]
	var front_spots: Array[Vector2] = []
	var tire_r := 3.0
	var tire_w := 3
	var zoff := 0
	var z_nose := Vector3.ZERO      # front face: bumper top, lamp band bottom, hood
	var z_tail := Vector3.ZERO      # rear face: bumper top, lamp band bottom, deck
	var lz0 := 0
	var lz1 := 0
	var roof_z := 10.0
	var gr := 1.0                   # the roof's half width (px)
	var gb := 1.0                   # the greenhouse's half width at the belt
	var cy := 0.0

	func idx(x: int, y: int) -> int:
		return y * sx + x

var _spec: Dictionary
var _paint: Color
var _seed := 1
var _scale := 1.0
var _mods: Dictionary
var _key := ""
var _imgs := {}                     # painted on the worker: the atlas, the lamps, the wheel

## A car drawn now (later = false), or set up to be drawn on a worker thread: see build().
func _init(spec: Dictionary, paint: Color, damage = 0.0, seed := 1, scale := 1.0, mods := {}, later := false) -> void:
	px = PX * scale
	k = px / 8.0
	if damage is Dictionary:
		for zk in dmg: dmg[zk] = clampf(float(damage.get(zk, 0.0)), 0.0, 1.0)
	else:
		for zk in dmg: dmg[zk] = clampf(float(damage), 0.0, 1.0) * 0.6
	bumper_front = dmg.front < 0.65
	bumper_rear = dmg.rear < 0.65
	# a hard hit on one corner takes that side's lamps out
	head_ok = [not (dmg.front > 0.45 and dmg.left >= dmg.right * 0.8), not (dmg.front > 0.45 and dmg.right > dmg.left * 0.8)]
	tail_ok = [not (dmg.rear > 0.45 and dmg.left >= dmg.right * 0.8), not (dmg.rear > 0.45 and dmg.right > dmg.left * 0.8)]
	_spec = spec
	_paint = paint
	_seed = seed
	_scale = scale
	_mods = mods
	# the design and the catalogue live on the main thread (their caches aren't thread-safe)
	if String(spec.get("body", "")) == "trailer":
		design = trailer_design(spec)
		_key = "trailer|%.2f|%.3f|%s" % [float(design.L), scale, str(dmg.values())]
	else:
		design = CarGen.design(spec)
		_key = _plan_key(spec, mods, dmg, scale)
	if not later:
		compute()
		finish()

## Draws a car on a worker thread. Poll done(), then take() the art (on the main thread).
static func build(spec: Dictionary, paint: Color, damage = 0.0, seed := 1, scale := 1.0, mods := {}) -> Job:
	var j := Job.new()
	j.art = CarArt.new(spec, paint, damage, seed, scale, mods, true)
	j.task = WorkerThreadPool.add_task(j.art.compute, false, "car art")
	return j

## A car being drawn on a worker thread.
class Job:
	var art: CarArt
	var task := -1
	func done() -> bool:
		return task < 0 or WorkerThreadPool.is_task_completed(task)
	## The finished art (waits for it if it isn't done yet). Main thread only.
	func take() -> CarArt:
		if task >= 0:
			WorkerThreadPool.wait_for_task_completion(task)
			task = -1
		if art != null and art.atlas == null: art.finish()
		return art

## The shape and the paint: safe on a worker thread.
func compute() -> void:
	var p := plan_of(_spec, _mods, dmg, _scale, design, _key)
	length_px = p.lpx
	width_px = p.wpx
	wheelbase_px = float(_spec.get("wheelbase", float(p.d.L) * 0.6)) * px
	size = Vector2i(p.sx, p.sy)
	n = p.n
	roof_z = p.roof_z
	wheel_spots = p.front_spots
	_Painter.new(self, p, _paint, _mods, _seed).run()

## The textures, from what compute() painted. Main thread.
func finish() -> void:
	atlas = ImageTexture.create_from_image(_imgs.atlas)
	for kk: String in ["brake", "rev", "head", "bl", "br", "beacon"]: lamp_tex[kk] = ImageTexture.create_from_image(_imgs[kk])
	wheel_tex = ImageTexture.create_from_image(_imgs.wheel)
	_imgs = {}

## A semi's trailer has no side profile of its own: a box on tandem axles at the back, its nose
## over the fifth wheel. Its design in the same shape CarGen's are, so the rest of the recipe
## draws it like any other.
static func trailer_design(spec: Dictionary) -> Dictionary:
	var L := float(spec.get("length", 13.6))
	var h := 4.0 / L
	return { "id": "", "year": 2015, "cls": "fleet", "body": "trailer", "family": "trailer", "make": "", "model": "",
		"rear": "trailer", "nose": "blunt", "L": L, "h": h, "cab": "", "doors": 0, "soft": 0.15, "art": {}, "pos": "front",
		"xo": false, "lux": false, "formal": false, "jelly": 0.0, "wf": 0.75, "wr": 1.6 / L, "tire_r": 0.52 / L, "rim": 0.55,
		"clear": 1.15 / L, "rocker": 1.2 / L, "hood_h": h, "cowl_x": 1.5, "cowl_h": h, "roof_f": 1.0, "roof_r": 0.0,
		"belt_f": h, "belt_r": h, "nose_x": 1.0, "nose_mid": 2.0 / L, "nose_bot": 1.3 / L, "nose_lean": 0.0, "tail_bot": 1.15 / L,
		"tail_mid": 1.6 / L, "tail_h": h, "crown": 0.0, "rt": 0.0, "a_w": 0.0, "fin": 0.0, "tail_x": 0.0, "deck_x": 0.0,
		"deck_h": h, "dlo_r": 0.0, "dlo_rt": 0.0, "a_bot": 1.0, "a_top": 1.0, "glass_top": h, "pillars": [], "door_cuts": [],
		"dna": {}, "head": "none", "tail_lamp": "bar", "tail_len": 0.01, "head_len": 0.0, "bumper": "steel", "mirror": "none",
		"frame": "black", "pillar": "body", "trim": [], "crease": -1.0, "rim_style": "steel", "wall": "none", "grille": "none",
		"flare": "none", "arch": "flat", "arch_gap": 0.2 / L, "boxy": true, "stripe_kind": "side", "bed_h": h, "cab_x": 1.0 }

static var _lock := Mutex.new()

static func _plan_key(spec: Dictionary, mods: Dictionary, damage: Dictionary, scale: float) -> String:
	var f := CarGen.facts(spec)
	var sm := {}
	for mk: String in SHAPE_MODS:
		if mods.has(mk): sm[mk] = mods[mk]
	var dq := ""
	for zk: String in ["front", "rear", "left", "right"]: dq += str(int(float(damage.get(zk, 0.0)) * 8.0))
	return "%s|%.3f|%.2f|%.2f|%.2f|%s|%s" % [f.key, scale, float(spec.get("length", f.L)), float(spec.get("width", 1.8)),
		float(spec.get("track", 0.0)), JSON.stringify(sm), dq]

## The plan for a car (cached): its shape at this size, with these mods and this much crumple.
static func plan_of(spec: Dictionary, mods: Dictionary, damage: Dictionary, scale: float, d: Dictionary, key: String) -> Plan:
	_lock.lock()
	var have: Plan = _plans.get(key)
	_lock.unlock()
	if have != null: return have
	var p := _Shaper.new(spec, mods, damage, scale, d).run()
	p.key = key
	_lock.lock()
	if _plans.size() > 160: _plans.clear()
	_plans[key] = p
	_lock.unlock()
	return p

# ================================================================== the shape

## Works out a Plan from the design: the outline from above, every column's height, the wheels,
## the greenhouse and its glass, the lamps, and whatever the mods bolt on.
class _Shaper:
	var spec: Dictionary
	var mods: Dictionary
	var dmg: Dictionary
	var d: Dictionary
	var p: Plan
	var px := 15.0
	var L := 4.5
	var rz := 12.0
	var zl := 50.0
	var art: Dictionary
	var fam := ""
	var top := PackedFloat32Array()
	var bot := PackedFloat32Array()
	var zt := PackedFloat32Array()      # per column: the top of the body (slices, -1 none)
	var zb := PackedFloat32Array()      # and its bottom
	var sh := PackedFloat32Array()      # and the shoulder (the belt, through the greenhouse)
	var gh := PackedByteArray()         # 1 where the column has a greenhouse
	var x_nose := 0
	var x_tail := 0
	var crush_f := 1.0
	var crush_r := 0.0

	func _init(the_spec: Dictionary, the_mods: Dictionary, damage: Dictionary, scale: float, design: Dictionary) -> void:
		spec = the_spec
		mods = the_mods
		dmg = damage
		d = design
		art = d.art
		fam = String(d.family)
		px = CarArt.PX * scale
		L = float(spec.get("length", d.L))
		rz = px * CarArt.RISE
		zl = L * rz

	func X(u: float) -> float:
		return float(CarArt.MX) + u * float(p.lpx)

	func Z(fy: float) -> float:
		return fy * zl

	func run() -> Plan:
		p = Plan.new()
		p.d = d
		p.lpx = int(round(L * px))
		p.wpx = int(round(float(spec.get("width", 1.8)) * px))
		if p.wpx % 2 == 1: p.wpx += 1
		p.sx = p.lpx + CarArt.MX * 2
		p.sy = p.wpx + CarArt.MY * 2
		p.zl = zl
		p.cy = p.sy / 2.0
		var cnt := p.sx * p.sy
		p.h0.resize(cnt)
		p.b0.resize(cnt)
		p.m0.resize(cnt)
		p.belt.resize(cnt)
		p.gs.resize(cnt)
		p.h1.resize(cnt)
		p.b1.resize(cnt)
		p.m1.resize(cnt)
		p.h2.resize(cnt)
		p.b2.resize(cnt)
		p.m2.resize(cnt)
		p.nmin.resize(cnt)
		p.nmin4.resize(cnt)
		p.h0.fill(-1)
		p.h1.fill(-1)
		p.h2.fill(-1)
		p.face.resize(cnt)
		p.ux.resize(p.sx)
		p.hw.resize(p.sx)
		p.doors.resize(p.sx)
		_lines()
		_stance()
		_outline_from_above()
		_wheels()
		_body()
		_greenhouse()
		_panels()
		_front_and_back()
		_lamps()
		_mirrors()
		_aero()
		_supercar()
		_roof()
		_fleet_roof()
		_bed_and_box()
		_bolt_ons()
		_finish()
		return p

	# ------------------------------------------------------------ lines along the car

	## The profile's top and bottom lines, in slices, column by column, and the shoulder line.
	func _lines() -> void:
		if fam == "trailer":
			_trailer_lines()
			return
		var outline := CarGen.smooth(CarGen.profile(d), float(p.lpx))
		top = CarGen.top_line(outline)
		bot = CarArt._bottom_line(outline)
		crush_f = 1.0 - 0.13 * float(dmg.get("front", 0.0))
		crush_r = 0.1 * float(dmg.get("rear", 0.0))
		zt.resize(p.sx)
		zb.resize(p.sx)
		sh.resize(p.sx)
		gh.resize(p.sx)
		var g0 := _glass_rear()
		var g1 := float(d.cowl_x)
		var open := String(d.rear) == "open"
		var belt_r := float(d.belt_r)
		var belt_f := float(d.belt_f)
		var dlo_r := float(d.dlo_r)
		var a_bot := float(d.a_bot)
		x_tail = p.sx
		x_nose = -1
		for x in p.sx:
			var u := (float(x) + 0.5 - float(CarArt.MX)) / float(p.lpx)
			p.ux[x] = u
			zt[x] = -1.0
			if u < crush_r or u > crush_f: continue
			var ty := CarGen.top_at(top, u)
			if ty < 0.0: continue
			zt[x] = Z(ty)
			zb[x] = Z(maxf(0.0, CarArt._line_at(bot, u)))
			x_tail = mini(x_tail, x)
			x_nose = maxi(x_nose, x)
			sh[x] = zt[x]
			if u > g0 and u < g1:
				var t := clampf((u - dlo_r) / maxf(0.01, a_bot - dlo_r), 0.0, 1.0)
				var bz := Z(lerpf(belt_r, belt_f, t))
				# an open car has no roof over its cockpit, but the cockpit's still there
				if zt[x] > bz + 0.6 or open:
					sh[x] = minf(bz, zt[x])
					gh[x] = 1
		# a crushed end buckles: the hood (or the trunk) kinks up behind the crush, in folds
		var fr := float(dmg.get("front", 0.0))
		var rr := float(dmg.get("rear", 0.0))
		for x in p.sx:
			if zt[x] < 0.0: continue
			var u: float = p.ux[x]
			if fr > 0.1 and u > crush_f - 0.16:
				var kk := (u - (crush_f - 0.16)) / 0.16
				var bump := fr * 3.0 * sin(kk * PI) * (0.7 + 0.3 * sin(float(x) * 2.3))
				zt[x] += bump
				sh[x] += bump
			if rr > 0.1 and u < crush_r + 0.14:
				var k2 := ((crush_r + 0.14) - u) / 0.14
				var bump2 := rr * 2.5 * sin(k2 * PI) * (0.7 + 0.3 * sin(float(x) * 1.9))
				zt[x] += bump2
				sh[x] += bump2

	## A trailer: a flat-topped box the whole way, up on its frame.
	func _trailer_lines() -> void:
		zt.resize(p.sx)
		zb.resize(p.sx)
		sh.resize(p.sx)
		gh.resize(p.sx)
		x_tail = CarArt.MX
		x_nose = CarArt.MX + p.lpx - 1
		for x in p.sx:
			p.ux[x] = (float(x) + 0.5 - float(CarArt.MX)) / float(p.lpx)
			zt[x] = -1.0
			if x < x_tail or x > x_nose: continue
			zt[x] = Z(float(d.h))
			zb[x] = Z(float(d.clear))
			sh[x] = zt[x]

	## Where the greenhouse ends at the back: the deck, the tail, the back of the cab or the box.
	func _glass_rear() -> float:
		match String(d.rear):
			"notch": return float(d.deck_x)
			"fast", "hatch": return float(d.tail_x) + 0.005
			"pickup": return float(d.cab_x)
			"boxtruck": return float(d.get("box_x", 1.0))
			"open":
				# a Jepp's tub is open all the way back to the tailgate
				if fam == "offroad": return 0.03 + 2.0 / maxf(1.0, float(p.lpx))
				return float(d.dlo_r) - 0.02
		return 0.0

	## Ride height: slammed sits it down on its tires, lifted (and a donk) stands it up.
	func _stance() -> void:
		var drop := float(mods.get("drop", 0.0))
		var lift := 0.0
		if drop > 0.0: lift = -drop * 0.06
		elif drop < 0.0: lift = -drop * 0.16
		if CarGen._donk(mods): lift += 0.12 + clampf(-drop - 0.45, 0.0, 0.5) * 0.3
		p.zoff = int(round(lift * rz))

	# ------------------------------------------------------------ the outline from above

	## How wide the car is down its length: square in the middle, the nose and the tail rounded
	## off and drawn in by the car's taste (a wedge comes to a point, a truck stays square), the
	## hips swelling over the wheels on the cars that have them.
	func _outline_from_above() -> void:
		var half := p.wpx / 2.0
		var soft := float(d.soft)
		var year := int(d.year)
		var cls := String(d.cls)
		var nose := String(d.nose)
		# plan-view corner radii (m) and how much the ends draw in (fraction of the half width)
		var rn := 0.12 + 0.22 * clampf(soft, 0.0, 1.4)
		var rt := 0.1 + 0.16 * clampf(soft, 0.0, 1.4)
		var tn := 0.03
		var tt := 0.02
		match nose:
			"blunt": rn *= 0.4
			"wedge":
				# a doorstop: drawn in all the way from the doors to a point (the front third about
				# three quarters of the car's width)
				tn = 0.3
				rn = 0.1
		if fam in ["sports", "mid", "rear", "roadster"]:
			tn = maxf(tn, 0.09)
			tt = 0.06
		if cls == "exotic" or fam == "mid": tn = maxf(tn, 0.18)
		if fam == "bubble":
			tn = 0.2
			tt = 0.16
			rn = 0.6
			rt = 0.6
		if fam in ["pickup", "boxtruck", "van", "offroad", "kei"] or bool(d.get("boxy", false)):
			rn = minf(rn, 0.16)
			rt = 0.06
			tn = 0.0
			tt = 0.0
		if String(d.rear) in ["box", "pickup", "boxtruck"]: rt = minf(rt, 0.08)
		if year >= 1990 and year < 2004 and fam in ["sedan", "coupe", "hatch", "wagon"]: tn = maxf(tn, 0.05)
		if year < 1980 and fam in ["sedan", "coupe", "wagon", "muscle"]:
			rn *= 0.6
			rt *= 0.7
		if d.has("plan_nose"): tn = float(d.plan_nose)
		if d.has("plan_tail"): tt = float(d.plan_tail)
		rn *= px
		rt *= px
		var wf := float(d.wf)
		var wr := float(d.wr)
		# hips over the wheels: muscle and sports cars, flares, a dually's rear fenders
		var hip := 0.0
		if cls in ["muscle", "pony", "sports", "exotic"] or fam in ["sports", "mid", "wedge", "rear"]: hip = 0.6
		if String(d.get("flare", "none")) != "none": hip = maxf(hip, 1.3)
		if String(mods.get("fenders", "stock")) == "flared": hip = maxf(hip, 2.2)
		var dually := art.has("dually")
		var ra := float(d.tire_r) * float(p.lpx) * 1.3
		# the engine behind the seats: the back track wider and the hips over it fat
		var mid := fam in ["mid", "wedge"]
		var hip_r := hip + (1.4 + clampf((float(spec.get("width", 1.8)) - 1.8) * 12.0, 0.0, 1.6) if mid else 0.0)
		var wedge_from := 0.42 if nose == "wedge" else wf - 0.08
		for x in p.sx:
			var u: float = p.ux[x]
			if zt[x] < 0.0:
				p.hw[x] = 0.0
				continue
			var w := half
			var fwd := clampf((u - wedge_from) / maxf(0.05, 1.0 - wedge_from), 0.0, 1.0)
			var back := clampf(((wr + 0.08) - u) / maxf(0.05, wr + 0.08), 0.0, 1.0)
			w *= 1.0 - tn * pow(fwd, 1.6 if nose != "wedge" else 1.1) - tt * pow(back, 1.6)
			var dn := (float(x_nose) + 1.0 - float(x))
			var dt := (float(x) - float(x_tail))
			if dn < rn: w = minf(w, w - rn + sqrt(maxf(0.0, rn * rn - (rn - dn) * (rn - dn))))
			if dt < rt: w = minf(w, w - rt + sqrt(maxf(0.0, rt * rt - (rt - dt) * (rt - dt))))
			# hips
			for wu: float in [wf, wr]:
				var dx := absf(float(x) - X(wu))
				if dx < ra:
					var bump := (hip_r if wu == wr else hip) * cos(dx / ra * PI * 0.5)
					if dually and wu == wr: bump = maxf(bump, 3.5 * clampf((ra - dx) / 2.0, 0.0, 1.0))
					w += bump
			# a side that took a hit caves in, in folds
			for side_k: String in ["left", "right"]:
				var amt := float(dmg.get(side_k, 0.0))
				if amt > 0.15 and u > 0.25 and u < 0.8:
					w -= amt * 1.6 * (0.6 + 0.4 * sin(float(x) * 1.7)) * sin((u - 0.25) / 0.55 * PI) * 0.5
			p.hw[x] = maxf(1.0, w)
		# the greenhouse: how wide it is at the belt and at the roof (tumblehome), by family and era
		var gbk := 0.9
		var grk := 0.72
		if year >= 1990: grk = 0.66
		if year < 1960: grk = 0.74
		match fam:
			"sports", "mid", "wedge", "rear", "roadster":
				gbk = 0.84
				grk = 0.58
			"bubble":
				gbk = 0.86
				grk = 0.56
			"pickup", "suv", "offroad", "van", "minivan":
				gbk = 0.92
				grk = 0.8
			"kei":
				gbk = 0.95
				grk = 0.86
			"boxtruck":
				gbk = 0.96
				grk = 0.9
		if bool(d.get("boxy", false)): grk = maxf(grk, 0.8)
		if d.has("plan_roof"): grk = float(d.plan_roof)
		p.gb = half * gbk
		p.gr = half * grk

	# ------------------------------------------------------------ wheels

	## Where the wheels are and how big: the design's axles and tyres, the spec's track, and the
	## mods (mud tires, a donk's rims, poke or tuck). The back ones are painted in; the front ones
	## get their own little stack so they can steer.
	func _wheels() -> void:
		var r := CarGen._tire_px(p.lpx, d, mods)
		p.tire_r = r
		var tw_m := 0.21
		if fam in ["pickup", "suv", "offroad", "van", "boxtruck"] or String(d.cls) in ["sports", "exotic", "muscle"]: tw_m = 0.25
		if CarGen._tire_kind(mods) == "mud" or CarGen._donk(mods): tw_m = 0.3
		if fam in ["kei", "bubble"]: tw_m = 0.17
		p.tire_w = maxi(2, int(round(tw_m * px)))
		var track := float(spec.get("track", float(spec.get("width", 1.8)) * 0.85)) * px
		var vc := track / 2.0
		match String(mods.get("offset", "stock")):
			"poke": vc += 1.6
			"tucked": vc -= 1.0
		# keep the outside of the tire near the body's side
		vc = minf(vc, p.wpx / 2.0 - p.tire_w / 2.0 + (1.6 if String(mods.get("offset", "")) == "poke" else 0.4))
		var xs := [X(float(d.wr)), X(float(d.wf))]
		if fam == "trailer":
			# tandem axles at the back, duals on each; no front wheels (the tractor carries that end)
			for ax: float in [0.0, -r * 2.2]:
				for s2: float in [-1.0, 1.0]:
					for dv: float in [0.0, -float(p.tire_w) - 1.0]:
						p.wheels.append([float(xs[0]) + ax + r * 1.1, p.cy + s2 * (vc + dv), r, p.tire_w, false, s2])
			xs = []
		# (a mid-engined car's back wheels sit out under its fat hips)
		var vc_r := vc + (1.0 if fam in ["mid", "wedge"] else 0.0)
		for i in xs.size():
			for s: float in [-1.0, 1.0]:
				p.wheels.append([float(xs[i]), p.cy + s * (vc_r if i == 0 else vc), r, p.tire_w, i == 1, s])
				if art.has("dually") and i == 0:
					p.wheels.append([float(xs[i]), p.cy + s * (vc - p.tire_w - 1.0), r, p.tire_w, false, s])
				if art.has("tractor") and i == 0:
					# tandem axles: a second pair of duals a wheel's width behind the first
					for dv: float in [0.0, -float(p.tire_w) - 1.0]:
						p.wheels.append([float(xs[i]) - r * 2.2, p.cy + s * (vc + dv), r, p.tire_w, false, s])
					p.wheels.append([float(xs[i]), p.cy + s * (vc - p.tire_w - 1.0), r, p.tire_w, false, s])
		for w: Array in p.wheels:
			if w[4]: p.front_spots.append(Vector2(float(w[0]) - p.sx / 2.0, float(w[1]) - p.cy))
		# the back wheels go into the plan's wheel runs
		var rise := CarArt.RISE
		for w: Array in p.wheels:
			if w[4]: continue
			var xc: float = w[0]
			var yc: float = w[1]
			var ww: int = w[3]
			for x in range(int(floor(xc - r)), int(ceil(xc + r)) + 1):
				var dx := float(x) + 0.5 - xc
				if absf(dx) > r or x < 0 or x >= p.sx: continue
				var dz := rise * sqrt(maxf(0.0, r * r - dx * dx))
				var zc := r * rise
				for y in range(int(round(yc - ww / 2.0)), int(round(yc - ww / 2.0)) + ww):
					if y < 0 or y >= p.sy: continue
					var i2 := p.idx(x, y)
					p.b1[i2] = maxi(0, int(round(zc - dz)))
					p.h1[i2] = maxi(p.b1[i2], int(round(zc + dz)) - 1)
					var outer := (y == int(round(yc - ww / 2.0)) + ww - 1) if float(w[5]) > 0.0 else (y == int(round(yc - ww / 2.0)))
					p.m1[i2] = CarArt.M_TIRE | ((1 if outer else 0) << 16)

	# ------------------------------------------------------------ the body

	## Every column of the body: the shoulder rounding over toward the sides, the hood crowned,
	## the arches cut out over the wheels, the whole thing sat at its ride height.
	func _body() -> void:
		var soft := clampf(float(d.soft), 0.1, 1.4)
		var drop_s := 1.2 + 1.6 * soft             # how far the shoulder rolls over at the very edge (slices)
		if fam in ["pickup", "boxtruck", "van", "offroad"] or bool(d.get("boxy", false)): drop_s = 1.0
		var crown := Z(float(d.crown)) * 0.6
		var rise := CarArt.RISE
		var arch_gap := maxf(0.8, float(d.get("arch_gap", 0.01)) * zl)
		var drop := float(mods.get("drop", 0.0))
		if drop > 0.4: arch_gap = maxf(0.0, arch_gap - drop * 1.5)
		for x in p.sx:
			if zt[x] < 0.0: continue
			var w: float = p.hw[x]
			var u: float = p.ux[x]
			# the arches over this column: how high they cut, and how far out from the middle
			var arch_z := -99.0
			var arch_v := 999.0
			for wv: Array in p.wheels:
				var dx := absf(float(x) + 0.5 - float(wv[0]))
				var ra := float(wv[2]) * 1.06
				if dx < ra:
					arch_z = maxf(arch_z, float(wv[2]) * rise + rise * sqrt(maxf(0.0, ra * ra - dx * dx)) + arch_gap - float(p.zoff))
					arch_v = minf(arch_v, absf(float(wv[1]) - p.cy) - float(wv[3]) / 2.0 - 1.0)
			for y in p.sy:
				var v := float(y) + 0.5 - p.cy
				var av := absf(v)
				if av > w: continue
				var vn := av / w
				var hz := sh[x] - drop_s * pow(vn, 5.0)
				if u > float(d.cowl_x) or gh[x] == 0: hz -= crown * vn * vn
				var bz := zb[x]
				if av > arch_v: bz = maxf(bz, arch_z)
				var i := p.idx(x, y)
				var hi := int(round(hz)) + p.zoff
				var lo := int(round(bz)) + p.zoff
				if lo > hi - 1: lo = hi - 1
				if hi < 0: continue
				p.h0[i] = hi
				p.b0[i] = maxi(0, lo)
				p.belt[i] = int(round(sh[x])) + p.zoff
				var reg := CarArt.R_BODY
				if u > float(d.cowl_x) + 0.01: reg = CarArt.R_HOOD
				elif gh[x] == 0 and u < 0.5: reg = CarArt.R_DECK
				# the hood and the trunk lid stop short of the fenders
				if reg == CarArt.R_HOOD and vn > 0.86: reg = CarArt.R_FENDER
				var edge := minf(w - av, minf(float(x_nose - x) * 1.4, float(x - x_tail) * 1.4))
				var shade := _shade(edge)
				if reg == CarArt.R_HOOD and shade == 4: shade = _hood_shade(u, vn)
				p.m0[i] = _paint(shade, reg)
		# door shut lines and handles along the sides, for the side bands
		for dc: Array in d.get("door_cuts", []):
			for e: int in [0, 1]:
				var xx := int(round(X(float(dc[e]))))
				if xx >= 0 and xx < p.sx: p.doors[xx] = 1
			var xh := int(round(X(float(dc[1])))) + 2
			if xh >= 0 and xh < p.sx and p.doors[xh] == 0: p.doors[xh] = 2

	## The hood's own lines by maker and era: a modern hood with two sharp creases running in
	## toward the grille (the light catches the inside of each), or a domed one lit down the middle.
	func _hood_shade(u: float, vn: float) -> int:
		var year := int(d.year)
		var t := clampf((u - float(d.cowl_x)) / maxf(0.05, 1.0 - float(d.cowl_x)), 0.0, 1.0)
		if t < 0.08 or t > 0.92: return 4
		var crease := float(d.get("crease", 0.0))
		if year >= 1998 and crease >= 0.28:
			var line := 0.5 - 0.16 * t
			if absf(vn - line) < 0.07: return 5 if vn < line else 3
			return 4
		if year >= 1998 and crease >= 0.0 and crease < 0.2 or fam in ["muscle"] or String(d.cls) == "muscle":
			return 5 if vn < 0.26 else 4
		return 4

	## How light the top of the paint is, by how far in from the edge it is: the flat tops catch
	## the sky and the last couple of pixels roll over into shadow (a bevel, the pixel-art way).
	func _shade(edge: float) -> int:
		if edge < 1.0: return 1
		if edge < 2.0: return 2
		if edge < 3.2: return 3
		return 4

	func _paint(shade: int, reg: int) -> int:
		return CarArt.M_PAINT | (shade << 8) | (reg << 12)

	# ------------------------------------------------------------ the greenhouse

	## The cabin from above: it leans in from the belt to the roof, the windshield and the
	## backlight slope down to the cowl and the deck, the side glass shows as a strip along each
	## side, and the pillars stand where the side view puts them.
	func _greenhouse() -> void:
		var roof_f := float(d.roof_f)
		var roof_r := float(d.roof_r)
		var g0 := _glass_rear()
		var cowl := float(d.cowl_x)
		var open := String(d.rear) == "open"
		var pillars: Array = d.get("pillars", [])
		var dlo_r := float(d.dlo_r)
		var a_top := float(d.a_top)
		var roof_top := 0.0
		var roof_crown := Z(float(d.crown)) * 0.5
		var a_w := 1.0
		var c_w := 1.0 + clampf(float(d.get("c_w", 0.0)) * 8.0, 0.0, 2.5) if not d.get("xo", false) else 1.0
		# a modern sedan's C-pillar: thin on the six-light cars, thick on the rest
		if not d.has("c_w") and int(d.year) >= 2000 and fam in ["sedan", "coupe"]:
			c_w = 1.0 if (d.get("dna", {}) as Dictionary).get("sixlight", false) else 2.4
		var black_pillars := String(d.get("pillar", "body")) == "black" or bool(d.get("xo", false))
		if open:
			_open_cockpit()
			return
		for x in p.sx:
			if zt[x] < 0.0 or gh[x] == 0: continue
			var u: float = p.ux[x]
			var s: float = sh[x]
			var t_top: float = zt[x]
			roof_top = maxf(roof_top, t_top)
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0: continue
				var v := float(y) + 0.5 - p.cy
				var av := absf(v)
				if av >= p.gb: continue
				var tt := clampf((p.gb - av) / maxf(1.0, p.gb - p.gr), 0.0, 1.0)
				var hz := s + (t_top - s) * tt
				if av < p.gr: hz -= roof_crown * (av / p.gr) * (av / p.gr)
				var h := int(round(hz)) + p.zoff
				if h <= p.h0[i]: continue
				p.h0[i] = h
				# what the top is here
				var on_roof := av < p.gr - 0.5 and u <= roof_f and u >= roof_r
				var mat := 0
				if on_roof:
					# lit along the crown, rolling off toward the edges
					var re := minf(p.gr - av, minf((u - roof_r), (roof_f - u)) * float(p.lpx))
					mat = _paint(2 if re < 1.0 else (4 if re < 2.5 or av > p.gr * 0.62 else 5), CarArt.R_ROOF)
				elif u > roof_f:
					# the windshield, its A-pillars down each side
					var edge := p.gr + (p.gb - p.gr) * clampf((u - roof_f) / maxf(0.01, cowl - roof_f), 0.0, 1.0)
					if av > edge - 1.0 - a_w * 0.5 or av >= p.gr and u < roof_f + 0.02: mat = _pillar(black_pillars)
					else: mat = CarArt.M_GLASS | (_glint(u, v, roof_f, cowl) << 8)
				elif u < roof_r:
					# the backlight, the C-pillars beside it
					var edge2 := p.gr + (p.gb - p.gr) * clampf((roof_r - u) / maxf(0.01, roof_r - g0), 0.0, 1.0)
					if av > edge2 - c_w: mat = _paint(3, CarArt.R_PILLAR) if not black_pillars or String(d.rear) == "notch" else _pillar(true)
					else: mat = CarArt.M_GLASS | (_glint(roof_r - u, v, 0.0, roof_r - g0) << 8)
				else:
					# the side glass, seen from above as a strip down each side, the pillars across it
					mat = CarArt.M_SIDEGLASS
					if u < dlo_r - 0.005 or u > a_top + 0.01: mat = _paint(3, CarArt.R_PILLAR)
					for pl: Array in pillars:
						if absf(u - float(pl[0])) * float(p.lpx) < maxf(0.6, float(pl[2]) * float(p.lpx) * 0.5): mat = _pillar(black_pillars)
				p.m0[i] = mat
		for x in p.sx:
			if gh[x] == 0: continue
			var u2: float = p.ux[x]
			for y in p.sy:
				var i2 := p.idx(x, y)
				if p.h0[i2] < 0: continue
				var mat2 := CarArt.M_SIDEGLASS
				if u2 < dlo_r - 0.005 or u2 > float(d.a_bot): mat2 = _paint(3, CarArt.R_PILLAR)
				for pl: Array in pillars:
					if absf(u2 - float(pl[0])) * float(p.lpx) < maxf(0.6, float(pl[2]) * float(p.lpx) * 0.5): mat2 = _pillar(black_pillars)
				if String(d.get("cab", "")) == "" and art.has("cargo") and u2 < float(d.dlo_r) + 0.02: mat2 = _paint(3, CarArt.R_PILLAR)
				p.gs[i2] = mat2
		p.roof_z = roof_top + float(p.zoff)

	## The shut lines you see from above: round the hood and the trunk lid, across the shoulders
	## where the doors meet, the cowl with its wipers at the foot of the windshield.
	func _panels() -> void:
		var cowl := float(d.cowl_x)
		var rear := String(d.rear)
		var lid: bool = rear == "notch" or (rear in ["fast", "hatch"] and fam != "bubble")
		var gap := 1 << 20
		for x in p.sx:
			if zt[x] < 0.0: continue
			var u: float = p.ux[x]
			var w: float = p.hw[x]
			for y in p.sy:
				var i := p.idx(x, y)
				var m: int = p.m0[i]
				if (m & 255) != CarArt.M_PAINT: continue
				var av := absf(float(y) + 0.5 - p.cy)
				var vn := av / w
				var reg := (m >> 12) & 15
				# the hood's edges, down each side and across its back at the cowl
				if reg == CarArt.R_HOOD and vn > 0.8 and vn <= 0.86: p.m0[i] = m | gap
				elif reg == CarArt.R_DECK and lid and vn > 0.8 and vn <= 0.86 and u < float(d.get("deck_x", 0.2)) - 0.01: p.m0[i] = m | gap
				# the doors' shut lines across the shoulder beside the glass
				elif p.doors[x] == 1 and av > p.gb and gh[x] == 1: p.m0[i] = m | gap
			# the cowl: a dark strip with the wipers on the glass above it
		# the third brake light along the top of the backlight, on the cars from '86 on
		if lid and int(d.year) >= 1986:
			var xb := int(round(X(float(d.roof_r)))) - 1
			for y in p.sy:
				if absf(float(y) + 0.5 - p.cy) < p.gr * 0.3 and xb >= 0 and (p.m0[p.idx(xb, y)] & 255) == CarArt.M_GLASS:
					p.m0[p.idx(xb, y)] = CarArt.M_BRAKE3
		var xc := int(round(X(cowl)))
		for y in p.sy:
			for dx2 in [0, 1]:
				var x2: int = xc + dx2
				if x2 < 0 or x2 >= p.sx: continue
				var i2 := p.idx(x2, y)
				var m2: int = p.m0[i2]
				if (m2 & 255) == CarArt.M_GLASS and dx2 == 0: p.m0[i2] = CarArt.M_TRIM
				elif (m2 & 255) == CarArt.M_PAINT and ((m2 >> 12) & 15) == CarArt.R_HOOD and dx2 == 0: p.m0[i2] = m2 | gap
			var av2 := absf(float(y) + 0.5 - p.cy)
			for k in 2:
				var xw := xc + 1 + k
				if xw >= p.sx: continue
				var i3 := p.idx(xw, y)
				var on: bool = (av2 > p.gr * 0.15 and av2 < p.gr * 0.6) and (k == 0 or float(y) + 0.5 - p.cy > p.gr * 0.4)
				if on and (p.m0[i3] & 255) == CarArt.M_GLASS: p.m0[i3] = CarArt.M_TRIM | (2 << 8)

	func _pillar(black: bool) -> int:
		return CarArt.M_TRIM if black else _paint(3, CarArt.R_PILLAR)

	## Glass catches a streak of sky: brighter toward the top, a diagonal glint across it.
	func _glint(u: float, v: float, a: float, b: float) -> int:
		var t := clampf((u - a) / maxf(0.01, b - a), 0.0, 1.0)
		# one streak of sky across it, off to one side
		var streak := v * 0.08 + t * 1.6
		if absf(streak - 0.55) < 0.09 and v < p.gr * 0.4: return 3
		if t < 0.35: return 2
		return 1 if t < 0.75 else 0

	## An open car from above: the windshield standing up off the cowl in its frame, the dash, the
	## seats sunk into the tub with the wheel in front of the driver's, the coaming round the edge,
	## the top folded down or the hoops behind the seats; a Jepp's tub runs back to the tailgate,
	## a bench and the cargo floor behind the front seats and the roll bar over it all.
	func _open_cockpit() -> void:
		var cowl := float(d.cowl_x)
		var lp := float(p.lpx)
		var offroad := fam == "offroad"
		var year := int(d.year)
		var ws_len := (0.16 if offroad else 0.32) * px / lp     # how far back the raked glass reaches
		var ws0 := cowl - ws_len
		var ws_h := (0.44 if offroad else 0.36) * rz            # how tall it stands over the belt
		var frame := CarArt.M_CHROME | (3 << 8) if art.has("chrome") else CarArt.M_TRIM
		if offroad: frame = _paint(4, CarArt.R_PILLAR)
		var lip := 1.6 if p.gb > 9.0 else 1.1                    # the coaming round the cockpit (px)
		var seat_c := p.gb * 0.48
		var seat_hw := maxf(1.5, p.gb * 0.3)
		# the cockpit's length behind the glass, and the seats in it
		var x_back := p.sx
		for x in p.sx:
			if gh[x] == 1: x_back = mini(x_back, x)
		var cock := (ws0 - p.ux[x_back]) * lp
		var seat0 := 4.5
		var seat_len := clampf((cock if not offroad else 0.62 * px + seat0) - seat0 - 0.5, 4.0, 0.62 * px)
		var seat1 := seat0 + seat_len
		var bench0 := seat1 + 0.35 * px
		var bench1 := bench0 + 0.45 * px
		var top_z := 0.0
		for x in p.sx:
			if zt[x] < 0.0 or gh[x] == 0: continue
			var u: float = p.ux[x]
			var s: float = sh[x]
			var du := (ws0 - u) * lp
			var floor_z := int(round(s - 0.36 * rz)) + p.zoff
			var belt_z := int(round(s)) + p.zoff
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0: continue
				var v := float(y) + 0.5 - p.cy
				var av := absf(v)
				if u >= ws0:
					# the windshield, leaning back from the cowl; its frame round the top and the sides
					if av >= p.gb - 0.5: continue
					var hz := s + ws_h * clampf((cowl - u) / maxf(0.001, ws_len), 0.0, 1.0)
					p.h0[i] = maxi(p.h0[i], int(round(hz)) + p.zoff)
					top_z = maxf(top_z, hz)
					var on_frame := (u - ws0) * lp < 1.0 or av > p.gb - 1.5
					# low and see-through: the sky in it, the dash showing under it
					p.m0[i] = frame if on_frame else CarArt.M_GLASS | (maxi(2, _glint(u, v, ws0, cowl)) << 8)
					p.gs[i] = (frame if (frame & 255) == CarArt.M_PAINT else CarArt.M_TRIM) if on_frame else 0
					continue
				if av > p.gb - lip or av > p.hw[x] - lip: continue
				var h := floor_z
				var m := CarArt.M_SEAT | (2 << 8)
				var dv := absf(av - seat_c)
				if du < 2.0:
					h = belt_z - 1
					m = CarArt.M_DASH
				elif du < 4.0 and v < 0.0 and dv < 2.2 and (du >= 3.0 or dv > 1.2):
					# the steering wheel, its rim across in front of the driver
					h = belt_z - 1
					m = CarArt.M_TRIM | (1 << 16)
				elif du >= seat0 and du < seat1 and dv < seat_hw:
					# a seat: the cushion low, the back standing up at its rear, the headrest
					var back := du > seat1 - 2.2
					h = floor_z + int(round(0.14 * rz))
					m = CarArt.M_SEAT | (1 << 8)
					if back:
						h = belt_z + (1 if dv < seat_hw * 0.55 else 0)
						m = CarArt.M_SEAT | ((3 if dv < seat_hw * 0.55 else 1) << 8)
					elif dv > seat_hw - 1.0: m = CarArt.M_SEAT
				elif du >= seat0 - 1.0 and du < seat1 - 2.0 and av < maxf(1.0, p.gb * 0.12):
					# the console between the seats, the shifter on it
					h = floor_z + int(round(0.18 * rz))
					m = CarArt.M_CHROME | (2 << 8) if absf(du - seat0 - seat_len * 0.3) < 0.8 else CarArt.M_TRIM | (1 << 8)
				elif offroad and du >= bench0 and du < bench1 and av < p.gb - lip - 0.5:
					# a Jepp's back bench
					var bback := du > bench1 - 1.8
					h = floor_z + int(round((0.36 if bback else 0.14) * rz))
					m = CarArt.M_SEAT | ((3 if bback else 1) << 8)
				elif offroad and du >= bench1:
					# the cargo floor, ribbed
					h = floor_z + 1
					m = CarArt.M_BED | ((x % 3) << 8)
				p.h0[i] = maxi(p.b0[i], h)
				p.m0[i] = m
				p.belt[i] = 999
		p.roof_z = top_z + float(p.zoff)
		# behind the seats: a roll bar on the Jepps, hoops on the modern roadsters, or the top folded down
		var x_seat := int(round(X(ws0 - (seat1 - 1.0) / lp)))
		var bar_z := int(round(sh[clampi(x_seat, 0, p.sx - 1)] + ws_h * 1.15)) + p.zoff
		if offroad or mods.get("rollbar", false):
			# a hoop behind the front seats, bars back to the tub's corners
			var xr0 := x_tail + 2
			for x in range(xr0, mini(p.sx, x_seat + 1)):
				for y in p.sy:
					var av2 := absf(float(y) + 0.5 - p.cy)
					if av2 > p.gb - lip + 0.2: continue
					var rail := av2 > p.gb - lip - 1.0
					if not rail and x != x_seat and x != xr0: continue
					var i2 := p.idx(x, y)
					var post := rail and (x == x_seat or x == xr0)
					p.b2[i2] = (int(round(sh[x])) + p.zoff) if post else bar_z - 1
					p.h2[i2] = bar_z
					p.m2[i2] = CarArt.M_TRIM | (1 << 8)
			p.roof_z = maxf(p.roof_z, float(bar_z))
		elif year >= 1996 and x_seat >= 0:
			# a hoop behind each headrest
			for x in range(x_seat - 1, x_seat + 1):
				for y in p.sy:
					var dv2 := absf(absf(float(y) + 0.5 - p.cy) - seat_c)
					if dv2 > seat_hw * 0.8: continue
					var i3 := p.idx(x, y)
					p.b2[i3] = int(round(sh[x])) + p.zoff
					p.h2[i3] = bar_z - 2
					p.m2[i3] = (CarArt.M_CHROME | (2 << 8)) if x == x_seat else _paint(4, CarArt.R_BODY)
		elif not art.has("hardtop") and x_back > x_tail:
			# the soft top folded down on the deck behind the cockpit
			for x in range(maxi(x_tail + 2, x_back - 3), x_back):
				for y in p.sy:
					var av3 := absf(float(y) + 0.5 - p.cy)
					var i4 := p.idx(x, y)
					if p.h0[i4] < 0 or av3 > p.gb - lip: continue
					p.h0[i4] += 2 if x > x_back - 3 else 1
					p.m0[i4] = CarArt.M_TRIM | ((2 if x == x_back - 1 else 0) << 8)
					p.belt[i4] = 999

	# ------------------------------------------------------------ the ends

	## The bumpers, the grille and the plate: the bumper juts out a pixel on the cars that wear
	## one, and the heights the faces' bands go by.
	func _front_and_back() -> void:
		var zo := float(p.zoff)
		p.z_nose = Vector3(Z(float(d.nose_bot)) + zo + 1.0, Z(float(d.nose_mid)) + zo, Z(float(d.hood_h)) + zo)
		p.z_tail = Vector3(Z(float(d.tail_bot)) + zo + 1.0, Z(float(d.get("tail_mid", d.tail_bot))) + zo, Z(float(d.tail_h)) + zo)
		var style := String(d.get("bumper", "body"))
		if mods.get("smooth", false) and style in ["chrome", "chrome5"]: style = "body"
		var jut := style in ["chrome", "chrome5", "rubber", "steel", "strip"]
		var mat := CarArt.M_CHROME | (2 << 8)
		if style in ["rubber", "strip"]: mat = CarArt.M_TRIM
		if style == "steel": mat = CarArt.M_STEEL
		if not jut: return
		var dmgf := float(dmg.get("front", 0.0))
		var dmgr := float(dmg.get("rear", 0.0))
		for end: int in [0, 1]:
			if end == 1 and dmgf >= 0.65: continue
			if end == 0 and dmgr >= 0.65: continue
			var xe := (x_nose + 1) if end == 1 else (x_tail - 1)
			var xin := x_nose if end == 1 else x_tail
			if xe < 0 or xe >= p.sx: continue
			var zz: Vector3 = p.z_nose if end == 1 else p.z_tail
			var w: float = p.hw[xin] * 0.96
			for y in p.sy:
				var av := absf(float(y) + 0.5 - p.cy)
				if av > w: continue
				var i := p.idx(xe, y)
				p.b0[i] = maxi(0, int(zz.x) - 1)
				p.h0[i] = maxi(p.b0[i], int(zz.x) + 1)
				p.belt[i] = 999
				p.m0[i] = mat
			# chrome wraps round the corners
			for y in p.sy:
				var av2 := absf(float(y) + 0.5 - p.cy)
				var i2 := p.idx(xin, y)
				if p.h0[i2] >= 0 and av2 > p.hw[xin] - 1.2: p.m0[i2] = mat

	## The lamps from above, by era and by maker: round and quad, square, flush, the swept and
	## hooked modern ones down the fenders; tail lamps in bars, blocks, wraps and tall towers.
	func _lamps() -> void:
		var head := String(d.get("head", "swept"))
		var hl := float(d.get("head_len", 0.0))
		if hl <= 0.0: hl = { "round": 0.035, "quad": 0.04, "rect": 0.035, "flush": 0.05, "jewel": 0.06, "popup": 0.0, "truck": 0.04 }.get(head, 0.07)
		var hpx := maxf(2.0, hl * float(p.lpx))
		var tail_kind := String(d.get("tail_lamp", "swept"))
		var tlpx := maxf(2.0, float(d.get("tail_len", 0.0)) * float(p.lpx) * 0.6)
		var grille := String(d.get("grille", "none"))
		var heads: Array[int] = []             # the headlamp pixels, sorted out by height below
		var was: Array[int] = []               # and what they were before
		for x in p.sx:
			var dn := float(x_nose) - float(x)
			var dt := float(x) - float(x_tail)
			if dn > hpx * 1.7 + 1.0 and dt > tlpx + 3.0: continue
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0 or (p.m0[i] & 255) != CarArt.M_PAINT: continue
				var v := float(y) + 0.5 - p.cy
				var vn := absf(v) / maxf(1.0, p.hw[x])
				var side := (0 if v < 0.0 else 1) << 16
				# the grille between the lamps, seen over the nose: the maker's face in a pixel or two
				if dn < 1.0 and grille != "none" and _grille_at(grille, vn): p.m0[i] = CarArt.M_GRILLE
				# headlamps: on the hood's front corners, in the maker's shape
				if dn <= hpx * 1.7 and head != "none":
					if _head_at(head, dn, vn, hpx):
						heads.append(i)
						was.append(p.m0[i])
						p.m0[i] = CarArt.M_HEAD | side
					elif head == "popup" and vn > 0.6 and vn < 0.9 and absf(dn - 3.0) < 0.6: p.m0[i] = _paint(2, CarArt.R_HOOD)
					# turn signals at the outer corners
					if dn < 2.0 and vn >= 0.9: p.m0[i] = CarArt.M_AMBER | side
				# tail lamps on the deck's back corners (the ones you see from above), big enough to read
				if dt <= tlpx + 3.0 and _tail_at(tail_kind, dt, vn, tlpx): p.m0[i] = CarArt.M_TAIL | side
		# a headlamp is a lens set in the top of the corner, one or two slices deep: the bits of
		# the shape that run down the rounded corner below that stay paint (stacked up the corner
		# they read as a smear sticking up past the hood when the car's side-on)
		var lamp_z := 0
		for i: int in heads: lamp_z = maxi(lamp_z, p.h0[i])
		for k in heads.size():
			if p.h0[heads[k]] < lamp_z - 1 and (p.m0[heads[k]] & 255) == CarArt.M_HEAD: p.m0[heads[k]] = was[k]

		# the lamps' slices (the faces carry them too): from the bumper's top to the hood
		p.lz0 = maxi(0, int(minf(p.z_nose.x, p.z_tail.x)) - 1)
		p.lz1 = int(maxf(p.z_nose.z, p.z_tail.z)) + 2
		if tail_kind == "tall" or fam in ["suv", "van", "minivan", "boxtruck", "offroad"]: p.lz1 = int(p.roof_z) + 1
		for i in p.m0.size():
			if (p.m0[i] & 255) == CarArt.M_BRAKE3:
				p.lz1 = maxi(p.lz1, p.h0[i] + 1)
				break

	## Is this spot (dn px back from the nose, vn out from the middle 0..1) a headlamp, by its shape?
	func _head_at(head: String, dn: float, vn: float, hpx: float) -> bool:
		match head:
			"round": return vn > 0.6 and vn < 0.9 and dn < 2.5
			"quad": return (vn > 0.48 and vn < 0.66 or vn > 0.72 and vn < 0.9) and dn < 2.0
			"popup", "hidden": return false
			"truck", "rect": return vn > 0.55 and vn < 0.92 and dn < 2.0
			"jewel", "frog": return Vector2((dn - 1.6) / 1.6, (vn - 0.74) / 0.16).length() < 1.0
			"tower": return vn > 0.8 and vn < 0.96 and dn < 2.0
			"blade":
				# a thin streak run far back along the fender
				return vn > 0.72 and vn < 0.95 and dn < hpx * 1.2 * (vn - 0.6) / 0.35
			"teardrop":
				# a fat drop, round at the front, pointed at the back
				var k := clampf(dn / maxf(1.0, hpx * 1.1), 0.0, 1.0)
				return dn < hpx * 1.1 and absf(vn - 0.76 - k * 0.06) < 0.2 * (1.0 - k * k)
			"hook":
				# swept back, then hooked in across the hood at its back end
				var reach := hpx * (0.5 + 0.5 * clampf((vn - 0.55) / 0.4, 0.0, 1.0))
				return vn > 0.56 and vn < 0.95 and dn < reach or absf(dn - hpx * 0.95) < 0.8 and vn > 0.5 and vn < 0.8
			"boomerang":
				# the long one that runs on up the fender
				var reach2 := hpx * (0.4 + 0.6 * clampf((vn - 0.55) / 0.4, 0.0, 1.0))
				return vn > 0.56 and vn < 0.95 and dn < reach2 or vn > 0.86 and dn < hpx * 1.6
			"split":
				# a slim running lamp at the top, the lamps proper in a block of their own behind
				return vn > 0.6 and vn < 0.92 and dn < 1.2 or vn > 0.66 and vn < 0.9 and dn > 2.2 and dn < 2.2 + hpx * 0.5
		# swept back along the fender, narrowing as it goes
		var reach3 := hpx * (0.4 + 0.6 * clampf((vn - 0.55) / 0.4, 0.0, 1.0))
		return vn > 0.56 and vn < 0.95 and dn < reach3

	## Is this spot (dt px in from the tail) a tail lamp?
	func _tail_at(kind: String, dt: float, vn: float, tlpx: float) -> bool:
		match kind:
			"bar", "racetrack", "slim": return dt < 2.0 and vn < 0.94
			"wrap": return vn > 0.6 and dt < 2.5 or vn > 0.85 and dt < tlpx + 2.0
			"fin": return vn > 0.75 and dt < 3.0
			"tall", "tower": return vn > 0.8 and dt < 2.2
			"round": return dt < 2.2 and (absf(vn - 0.78) < 0.13)
			"dual": return dt < 2.2 and (absf(vn - 0.82) < 0.1 or absf(vn - 0.56) < 0.1)
			"ell": return vn > 0.6 and dt < 1.8 or vn > 0.84 and dt < tlpx + 2.0
			"boomerang": return vn > 0.62 and dt < 1.8 or vn > 0.8 and dt < 1.8 + tlpx * (vn - 0.8) / 0.2
			"teardrop": return dt < 2.0 + tlpx * 0.6 * clampf((vn - 0.6) / 0.35, 0.0, 1.0) and vn > 0.58
			"lid": return dt < 2.0 and vn > 0.4
			"block": return dt < 2.2 and vn > 0.5
		return vn > 0.62 and dt < 2.0

	## The grille as it shows over the nose, by its kind.
	func _grille_at(kind: String, vn: float) -> bool:
		match kind:
			"big", "hex", "tiger", "waterfall": return vn < 0.5
			"split": return vn > 0.1 and vn < 0.45
			"beak", "vee": return vn < 0.22
			"kidney": return vn > 0.06 and vn < 0.3
			"slim", "bar": return vn < 0.36
		return false

	## Mirrors stand off the doors at the front of the side glass (on the fenders, on old JDM cars).
	func _mirrors() -> void:
		var kind := String(d.get("mirror", "body"))
		if kind == "none": return
		var u := float(d.a_bot) - 0.01
		if kind == "fender": u = float(d.wf) + 0.02
		var xm := int(round(X(u)))
		var big := kind in ["truck", "truck_chrome"]
		var out := 3 if big else 2
		var mat := _paint(4, CarArt.R_BODY)
		if kind in ["black", "truck"]: mat = CarArt.M_TRIM
		if kind in ["chrome", "chrome_small", "truck_chrome"]: mat = CarArt.M_CHROME | (3 << 8)
		if String(d.rear) == "open" and fam != "pickup": out = 1
		for x in range(xm - (1 if big else 0), xm + 1):
			if x < 0 or x >= p.sx or p.hw[x] <= 0.0: continue
			var bz := 0
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] >= 0: bz = maxi(bz, p.belt[i])
			for s: float in [-1.0, 1.0]:
				for k in out:
					var y2 := int(floor(p.cy + s * (p.hw[x] + float(k)))) if s > 0.0 else int(floor(p.cy - p.hw[x] - float(k) - 0.01))
					if y2 < 0 or y2 >= p.sy: continue
					var i2 := p.idx(x, y2)
					if p.h0[i2] >= 0 and k == 0: continue
					p.h0[i2] = bz + (1 if big else 0)
					p.b0[i2] = bz - (3 if big else 1)
					p.belt[i2] = 999
					p.m0[i2] = mat

	# ------------------------------------------------------------ bolted on

	## Spoilers and wings off the deck, scoops and louvres on the hood.
	func _aero() -> void:
		var spoiler := String(mods.get("spoiler", "none"))
		if spoiler == "none":
			if art.has("wing"): spoiler = String(d.get("wing_kind", "factory_wing"))
			elif art.has("spoiler"): spoiler = "lip"
		var rear := String(d.rear)
		if spoiler != "none" and rear in ["box"]: spoiler = "roof"
		if fam in ["pickup", "boxtruck", "van"]: spoiler = "none" if spoiler != "roof" else spoiler
		if float(dmg.get("rear", 0.0)) > 0.5 and not mods.has("spoiler"): spoiler = "none"
		var deck_z := 0
		for y in p.sy:
			var i0 := p.idx(mini(p.sx - 1, x_tail + 1), y)
			deck_z = maxi(deck_z, p.h0[i0])
		match spoiler:
			"lip", "ducktail":
				var len_px := 2 if spoiler == "lip" else 4
				var up := 1 if spoiler == "lip" else 2
				for x in range(x_tail, mini(p.sx, x_tail + len_px)):
					var k := float(len_px - (x - x_tail)) / float(len_px)
					for y in p.sy:
						var i := p.idx(x, y)
						if p.h0[i] < 0: continue
						var av := absf(float(y) + 0.5 - p.cy)
						if av > p.hw[x] - 0.8: continue
						p.h0[i] += int(round(float(up) * k + 0.4))
						p.m0[i] = _paint(5, CarArt.R_DECK)
			"wing", "gt", "factory_wing", "tall", "deck", "whale":
				var gt := spoiler in ["gt", "tall"]
				var chord := 3 if not gt else 5
				var lift := 3 if spoiler != "whale" else 1
				if gt: lift = 5
				# a supercar's own wing stands up on its posts, the whole width of the tail
				var proud := spoiler == "factory_wing" and String(d.cls) == "exotic"
				if proud:
					# (up on its posts, but no higher than the roof: it's still a low car)
					chord = 4
					lift = clampi(int(p.roof_z) - 2 - deck_z, 2, 5)
				var x0 := x_tail + (0 if gt else 1)
				var zw := deck_z + lift
				var mat := _paint(4, CarArt.R_DECK) if not gt else CarArt.M_TRIM | (2 << 8)
				for x in range(x0, mini(p.sx, x0 + chord)):
					var wx: float = p.hw[mini(p.sx - 1, maxi(x, x_tail + 2))]
					for y in p.sy:
						var av := absf(float(y) + 0.5 - p.cy)
						var i := p.idx(x, y)
						if av < wx - 0.5 or proud and av < wx + 0.5:
							p.b2[i] = zw
							p.h2[i] = zw + (1 if x == x0 + chord / 2 else 0)
							# (its trailing edge dark, so it reads as a blade over the deck, not more deck)
							p.m2[i] = mat if x != x0 or not proud else CarArt.M_TRIM | (1 << 8)
						# the uprights
						if absf(av - wx * 0.55) < 0.6 and x == x0 + chord / 2:
							p.b2[i] = maxi(0, deck_z)
							p.h2[i] = zw
							p.m2[i] = mat
						# endplates
						if gt and av >= wx - 0.5 and av < wx + 0.5:
							p.b2[i] = zw - 2
							p.h2[i] = zw + 1
							p.m2[i] = CarArt.M_TRIM
			"roof":
				var xr := int(round(X(float(d.roof_r)))) - 1
				if xr >= 0 and xr < p.sx:
					for y in p.sy:
						var av2 := absf(float(y) + 0.5 - p.cy)
						if av2 > p.gr: continue
						var i2 := p.idx(xr, y)
						p.b2[i2] = int(p.roof_z) - 1
						p.h2[i2] = int(p.roof_z)
						p.m2[i2] = _paint(4, CarArt.R_ROOF)
		# fins rise off the back corners
		if art.has("fins") and float(d.get("fin", 0.0)) > 0.0:
			var fz := Z(float(d.fin))
			for x in range(x_tail, x_nose):
				var u: float = p.ux[x]
				if u > 0.3: break
				var k2 := clampf(1.0 - u / 0.3, 0.0, 1.0)
				for y in p.sy:
					var i3 := p.idx(x, y)
					if p.h0[i3] < 0: continue
					var vn := absf(float(y) + 0.5 - p.cy) / maxf(1.0, p.hw[x])
					if vn > 0.78 and vn < 0.97: p.h0[i3] += int(round(fz * k2))
		# the hood: a scoop, louvres, carbon
		var hood := String(mods.get("hood", "stock"))
		if art.has("scoop") and hood == "stock": hood = "scoop"
		if hood == "scoop":
			var c0 := float(d.cowl_x) + 0.03
			var c1 := minf(float(d.cowl_x) + 0.14, 0.92)
			for x in range(int(X(c0)), int(X(c1)) + 1):
				if x < 0 or x >= p.sx: continue
				for y in p.sy:
					var av3 := absf(float(y) + 0.5 - p.cy)
					var i4 := p.idx(x, y)
					if av3 > p.hw[x] * 0.24 or p.h0[i4] < 0: continue
					var front := x >= int(X(c1)) - 1
					p.h0[i4] += 2 if not front else 1
					p.m0[i4] = (CarArt.M_TRIM if front else _paint(5 if av3 < p.hw[x] * 0.12 else 3, CarArt.R_SCOOP))

	## A supercar's own details from above: the engine cover behind the seats (louvred slats, or a
	## pair of vents), the strakes down the doors, NACA ducts in the hood.
	func _supercar() -> void:
		if not fam in ["mid", "wedge"] and String(d.cls) != "exotic": return
		var louvers := art.has("louvers")
		var x_r := int(round(X(float(d.roof_r)))) - 1
		var x_c := int(round(X(float(d.cowl_x))))
		for x in range(x_tail + 2, x_nose):
			var u: float = p.ux[x]
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0 or (p.m0[i] & 255) != CarArt.M_PAINT: continue
				var vn := absf(float(y) + 0.5 - p.cy) / maxf(1.0, p.hw[x])
				# the engine cover: slats across it, or two vents either side of its spine
				if fam in ["mid", "wedge"] and x < x_r - 1 and x > x_tail + 2:
					if louvers and vn < 0.62 and x % 2 == 0: p.m0[i] = CarArt.M_TRIM | (1 << 8)
					elif not louvers and vn > 0.18 and vn < 0.5 and (x - x_tail) % 3 == 0 and x < x_r - 3: p.m0[i] = CarArt.M_TRIM
				# strakes: ribs down the doors and over the hips
				if String(d.get("side_vent", "")) == "strakes" and vn > 0.84 and u > float(d.wr) + 0.04 and u < 0.6 and x % 2 == 0:
					p.m0[i] = _paint(0, CarArt.R_BODY)
				# NACA ducts: a pair of little dark scoops sunk in the hood
				if String(d.cls) == "exotic" and int(d.year) >= 1984 and absf(vn - 0.32) < 0.09 and x > x_c + 2 and x <= x_c + 4:
					p.m0[i] = CarArt.M_TRIM

	## What's on the roof: a sunroof or T-tops, vinyl, a rack, a light bar, a sign, a beacon.
	func _roof() -> void:
		if String(d.rear) in ["open", "pickup"] and fam != "pickup": return
		var roof_mod := String(mods.get("roof", "stock"))
		var rz0 := int(round(p.roof_z))
		var x_rf := int(round(X(float(d.roof_f))))
		var x_rr := int(round(X(float(d.roof_r))))
		if String(d.rear) in ["box"] or fam in ["van", "suv", "offroad", "minivan", "kei"]: x_rr = maxi(x_rr, x_tail + 2)
		if String(d.rear) == "boxtruck": x_rr = maxi(x_rr, int(round(X(float(d.get("box_x", 0.0))))) + 1)
		var glass_roof := roof_mod in ["sunroof", "ttops"] or (roof_mod == "stock" and (art.has("sunroof") or art.has("ttops")))
		var ttops := roof_mod == "ttops" or (roof_mod == "stock" and art.has("ttops"))
		var vinyl: bool = roof_mod == "vinyl" or (roof_mod == "stock" and (art.has("vinyl") or d.get("vinyl", false)))
		for x in range(maxi(0, x_rr), mini(p.sx, x_rf + 1)):
			var u: float = p.ux[x]
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0 or ((p.m0[i] >> 12) & 15) != CarArt.R_ROOF: continue
				var v := float(y) + 0.5 - p.cy
				var av := absf(v)
				var mid_u := (float(d.roof_f) + float(d.roof_r)) * 0.5
				var half_len := (float(d.roof_f) - float(d.roof_r)) * float(p.lpx) * 0.32
				var along := absf(u - mid_u) * float(p.lpx)
				if glass_roof and along < half_len:
					if ttops:
						if av > p.gr * 0.14 and av < p.gr * 0.82: p.m0[i] = CarArt.M_GLASS | (1 << 8)
					elif av < p.gr * 0.6: p.m0[i] = CarArt.M_GLASS | (2 << 8)
					# a sunroof sits in a thin black seal, not straight in the paint (on a white or a
					# pearl roof the glass's own light edge reads as a sticker)
					elif av < p.gr * 0.6 + 1.0: p.m0[i] = CarArt.M_TRIM
				elif glass_roof and not ttops and along < half_len + 1.0 and av < p.gr * 0.6 + 1.0:
					p.m0[i] = CarArt.M_TRIM
				elif vinyl:
					p.m0[i] = CarArt.M_TRIM | (3 << 8) | (1 << 16)
		var rack: bool = roof_mod == "rack" or (roof_mod == "stock" and art.has("rack")) or mods.get("ladder", false) or art.has("ladder")
		if fam in ["pickup"]: rack = rack and mods.get("ladder", false) == false and not art.has("ladder")
		var x0 := x_rr + 1
		var x1 := x_rf - 2
		if rack and x1 > x0:
			for x in range(x0, x1 + 1):
				for s: float in [-1.0, 1.0]:
					var y := int(floor(p.cy + s * (p.gr - 1.0)))
					if y < 0 or y >= p.sy: continue
					var i2 := p.idx(x, y)
					p.b2[i2] = rz0 + 1
					p.h2[i2] = rz0 + 1
					p.m2[i2] = CarArt.M_TRIM | (1 << 8)
			for k in 3:
				var xc := x0 + (x1 - x0) * (k + 1) / 4
				for y in p.sy:
					var av2 := absf(float(y) + 0.5 - p.cy)
					if av2 > p.gr - 0.5: continue
					var i3 := p.idx(xc, y)
					p.b2[i3] = rz0 + 1
					p.h2[i3] = rz0 + 2
					p.m2[i3] = CarArt.M_TRIM | (2 << 8)
			if mods.get("ladder", false) or art.has("ladder"):
				# an aluminium ladder down one side of the rack
				for x in range(x0 - 2, mini(p.sx, x1 + 3)):
					for yy in [int(floor(p.cy - p.gr * 0.15)), int(floor(p.cy - p.gr * 0.15)) + 2]:
						var i4 := p.idx(x, yy)
						p.b2[i4] = rz0 + 3
						p.h2[i4] = rz0 + 3
						p.m2[i4] = CarArt.M_LADDER
					if (x - x0) % 3 == 0:
						var i5 := p.idx(x, int(floor(p.cy - p.gr * 0.15)) + 1)
						p.b2[i5] = rz0 + 3
						p.h2[i5] = rz0 + 3
						p.m2[i5] = CarArt.M_LADDER | (1 << 8)
		var bar: bool = roof_mod == "lightbar" or (mods.get("lightbar", false) and fam != "pickup")
		if bar:
			for x in range(maxi(0, x_rf - 3), maxi(0, x_rf - 1)):
				for y in p.sy:
					var av3 := absf(float(y) + 0.5 - p.cy)
					if av3 > p.gr - 0.5: continue
					var i6 := p.idx(x, y)
					p.b2[i6] = rz0 + 1
					p.h2[i6] = rz0 + 2
					p.m2[i6] = CarArt.M_LIGHTBAR | ((int(av3) % 3) << 8)
		# a sign on the roof: a taxi, a pizza delivery, a driving school
		var sign := String(mods.get("sign", ""))
		if sign == "" and art.has("topper"): sign = "taxi"
		if sign != "" or art.has("beacon"):
			var xm := (x_rf + x_rr) / 2
			var half_len := 2 if sign in ["beacon", ""] else (3 if sign != "school" else 2)
			var half_w := p.gr * (0.55 if sign != "school" else 0.75)
			if sign in ["beacon", ""]: half_w = 1.5
			var hgt := 3 if sign in ["taxi", "pizza"] else 2
			if sign == "school": hgt = 4
			for x in range(xm - half_len, xm + half_len + 1):
				for y in p.sy:
					var av4 := absf(float(y) + 0.5 - p.cy)
					if av4 > half_w: continue
					var i7 := p.idx(x, y)
					p.b2[i7] = rz0 + 1
					p.h2[i7] = rz0 + hgt
					var kind := { "taxi": 0, "pizza": 1, "school": 2 }.get(sign, 3) as int
					p.m2[i7] = (CarArt.M_SIGN | (kind << 16)) if sign not in ["beacon", ""] else CarArt.M_BEACON
			p.lz1 = maxi(p.lz1, rz0 + hgt + 1)

	## The fleet's roofs: a city bus's air conditioner and hatches, a school bus's warning lamps at
	## the corners, an ambulance's light bars at the box's corners.
	func _fleet_roof() -> void:
		var bus := art.has("bus")
		var school := art.has("schoolbus")
		var amb := art.has("ambulance")
		if not (bus or school or amb): return
		var rz0 := int(round(p.roof_z))
		var x0 := x_tail + 2
		var x1 := x_nose - 2
		for x in range(x0, x1):
			var u: float = p.ux[x]
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < rz0 - 1: continue
				var av := absf(float(y) + 0.5 - p.cy)
				var w: float = p.hw[x]
				if bus:
					# the air conditioner, a low box toward the back; two hatches
					if u > 0.12 and u < 0.3 and av < w * 0.6:
						p.b2[i] = rz0 + 1
						p.h2[i] = rz0 + 2
						p.m2[i] = CarArt.M_STEEL | ((1 if av < w * 0.5 and (x % 3) != 0 else 0) << 8)
					elif (absf(u - 0.5) < 0.03 or absf(u - 0.75) < 0.03) and av < w * 0.3:
						p.m0[i] = CarArt.M_TRIM | (2 << 8)
				if school:
					# warning lamps on the four corners
					var front := x > x1 - 3
					var back := x < x0 + 2
					if (front or back) and av > w * 0.55 and av < w * 0.85:
						p.b2[i] = rz0 + 1
						p.h2[i] = rz0 + 1
						p.m2[i] = CarArt.M_BEACON if av < w * 0.7 else CarArt.M_TAIL
		if amb: _ambulance_roof()
		p.lz1 = maxi(p.lz1, rz0 + 2)

	## An ambulance's box from above: a red beacon on each of its top corners, a light bar across
	## its front edge over the cab (red and clear lenses), and the air conditioner on the roof.
	func _ambulance_roof() -> void:
		var bx := mini(int(round(X(float(d.get("box_x", 1.0))))), x_nose)
		var top := 0
		for x in range(x_tail, bx):
			top = maxi(top, p.h0[p.idx(x, int(p.cy))])
		for x in range(x_tail + 1, bx):
			var w: float = p.hw[x]
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < top - 1: continue
				var av := absf(float(y) + 0.5 - p.cy)
				var mat := -1
				var hgt := 1
				var front := x >= bx - 3
				if (front or x <= x_tail + 2) and av > w * 0.62 and av < w - 0.5:
					mat = CarArt.M_BEACON | (1 << 16)
				elif front and x == bx - 2 and av < w * 0.55:
					# the light bar: red and clear lenses in turn
					mat = CarArt.M_BEACON | ((1 if int(av / 2.0) % 2 == 0 else 2) << 16)
				elif p.ux[x] > 0.2 and p.ux[x] < 0.34 and av < w * 0.45:
					mat = CarArt.M_STEEL | ((1 if (x % 3) != 0 else 2) << 8)
					hgt = 2
				if mat < 0: continue
				p.b2[i] = top + 1
				p.h2[i] = top + hgt
				p.m2[i] = mat
		p.lz1 = maxi(p.lz1, top + 3)

	## A pickup's bed (and what's in it, or the cover over it); the box behind a box truck's cab.
	func _bed_and_box() -> void:
		var rear := String(d.rear)
		if rear == "pickup" and art.has("tractor"):
			_frame_deck()
		elif rear == "pickup" and d.body != "tow":
			var cab_x := float(d.cab_x)
			var xc := int(round(X(cab_x - float(d.get("sail", 0.0))))) - 1
			var rail := 0
			for y in p.sy: rail = maxi(rail, p.h0[p.idx(mini(p.sx - 1, maxi(0, xc - 2)), y)])
			var floor_z := maxi(int(round(float(rail) - 0.42 * rz)), 1)
			var bed := String(mods.get("bed", "stock"))
			var load := String(mods.get("load", ""))
			for x in range(x_tail, xc):
				for y in p.sy:
					var i := p.idx(x, y)
					if p.h0[i] < 0: continue
					var av := absf(float(y) + 0.5 - p.cy)
					var inner: bool = av < p.hw[x] - 1.6 and x > x_tail + 1 and x < xc - 1
					if not inner:
						p.m0[i] = _paint(5 if x <= x_tail + 1 or x >= xc - 1 else 4, CarArt.R_BED)
						continue
					if bed == "tonneau":
						p.h0[i] = rail
						p.m0[i] = CarArt.M_TRIM | (2 << 8) | ((1 if x == xc - 2 or x == x_tail + 2 else 0) << 16)
						continue
					p.h0[i] = floor_z
					p.m0[i] = CarArt.M_BED | (((x - x_tail) % 3) << 8)
			if bed != "tonneau": _bed_load(load if load != "" else ("spare" if mods.get("spare", false) or art.has("spare") else ""), xc, floor_z, rail)
			if art.has("toolbox"):
				for x in range(xc - 4, xc - 1):
					for y in p.sy:
						var i2 := p.idx(x, y)
						var av2 := absf(float(y) + 0.5 - p.cy)
						if p.h0[i2] < 0 or av2 > p.hw[x] - 0.5: continue
						p.h0[i2] = rail + 2
						p.m0[i2] = CarArt.M_CHROME | ((1 + (x + y) % 2) << 8)
			var rollbar: bool = mods.get("rollbar", false) or bed in ["rollbar", "rollbar_lights"]
			if rollbar:
				var xb := xc - 3
				for y in p.sy:
					var av3 := absf(float(y) + 0.5 - p.cy)
					if av3 > p.hw[xb] - 0.5: continue
					var i3 := p.idx(xb, y)
					var post := av3 > p.hw[xb] - 1.6
					p.b2[i3] = rail if post else int(p.roof_z) - 2
					p.h2[i3] = int(p.roof_z) - 1
					p.m2[i3] = CarArt.M_TRIM | (1 << 8)
					if (mods.get("lightbar", false) or bed == "rollbar_lights") and not post and av3 < p.hw[xb] - 2.5:
						var i4 := p.idx(xb + 1, y)
						p.b2[i4] = int(p.roof_z) - 1
						p.h2[i4] = int(p.roof_z)
						p.m2[i4] = CarArt.M_LIGHTBAR | ((int(av3) % 3) << 8)
			if mods.get("ladder", false) or art.has("ladder"):
				# a ladder rack over the bed: posts at the corners, a frame at roof height, a ladder on it
				var zr := int(p.roof_z) + 1
				for x in range(x_tail + 1, xc + 4):
					for y in p.sy:
						var av4 := absf(float(y) + 0.5 - p.cy)
						var i5 := p.idx(x, y)
						var rail_y := av4 > p.hw[mini(x, p.sx - 1)] - 1.5 and av4 < p.hw[mini(x, p.sx - 1)] - 0.3
						var cross := (x == x_tail + 1 or x == xc - 1) and av4 < p.hw[mini(x, p.sx - 1)] - 0.3
						if rail_y or cross:
							p.b2[i5] = zr if not (rail_y and (x == x_tail + 1 or x == xc - 1)) else rail
							p.h2[i5] = zr
							p.m2[i5] = CarArt.M_STEEL
				for x in range(x_tail - 1, xc + 6):
					for yy in [int(floor(p.cy - 1.0)), int(floor(p.cy + 1.0))]:
						var i6 := p.idx(clampi(x, 0, p.sx - 1), yy)
						p.b2[i6] = zr + 1
						p.h2[i6] = zr + 1
						p.m2[i6] = CarArt.M_LADDER
					if x % 3 == 0:
						var i7 := p.idx(clampi(x, 0, p.sx - 1), int(floor(p.cy)))
						p.b2[i7] = zr + 1
						p.h2[i7] = zr + 1
						p.m2[i7] = CarArt.M_LADDER | (1 << 8)
		elif rear == "boxtruck":
			# the box: a flat roof with its ribs, white or the fleet's colour
			var bx := int(round(X(float(d.get("box_x", 0.0)))))
			for x in range(x_tail, mini(bx, p.sx)):
				for y in p.sy:
					var i8 := p.idx(x, y)
					if p.h0[i8] < 0: continue
					var av5 := absf(float(y) + 0.5 - p.cy)
					# the roof bows between its ribs: a shade darker over each one (an ambulance's box is smooth)
					var rib := (x - x_tail) % 6 == 0 and not art.has("ambulance")
					p.m0[i8] = _paint(2 if av5 >= p.hw[x] - 1.0 else (3 if rib else 4), CarArt.R_BOX)
					# a translucent skylight strip down the middle of a parcel box
					if not art.has("ambulance") and av5 < p.hw[x] * 0.14 and x > x_tail + 2 and x < bx - 3:
						p.m0[i8] = CarArt.M_PLATE
					p.belt[i8] = 999
			# a roof vent or two near the front of the box
			if not art.has("ambulance"):
				for k: int in [5, 12]:
					var xv := bx - k
					if xv <= x_tail + 2: continue
					for y in p.sy:
						var av7 := absf(float(y) + 0.5 - p.cy)
						var i11 := p.idx(xv, y)
						if p.h0[i11] < 0 or absf(av7 - p.hw[xv] * 0.55) > 1.2: continue
						p.b2[i11] = p.h0[i11] + 1
						p.h2[i11] = p.h0[i11] + 1
						p.m2[i11] = CarArt.M_STEEL | (1 << 8)
		elif d.body == "tow":
			# the wrecker: a steel deck behind the cab, the boom down the middle
			var xc2 := int(round(X(float(d.cab_x)))) - 1
			for x in range(x_tail, xc2):
				for y in p.sy:
					var i9 := p.idx(x, y)
					if p.h0[i9] < 0: continue
					var av6 := absf(float(y) + 0.5 - p.cy)
					if av6 > p.hw[x] - 1.2:
						p.m0[i9] = _paint(4, CarArt.R_BED)
						continue
					p.m0[i9] = CarArt.M_STEEL | (((x - x_tail) % 3) << 8)
					if av6 < 1.6:
						p.h0[i9] += 3 if x > x_tail + 3 else 1
						p.m0[i9] = CarArt.M_STEEL | (3 << 8)

	## Behind a semi tractor's cab: no bed, just the frame rails, the fifth wheel on them, mud
	## flaps behind the back wheels and the stacks standing up behind the cab.
	func _frame_deck() -> void:
		var xc := int(round(X(float(d.cab_x)))) - 1
		var rail := 0
		for y in p.sy: rail = maxi(rail, p.h0[p.idx(mini(p.sx - 1, maxi(0, xc - 2)), y)])
		var deck_z := int(round(Z(float(d.clear)))) + 3 + p.zoff
		var fx := int(round(X(float(d.wr)))) + 1
		for x in range(x_tail, xc):
			for y in p.sy:
				var i := p.idx(x, y)
				if p.h0[i] < 0: continue
				var v := float(y) + 0.5 - p.cy
				var av := absf(v)
				var w: float = p.hw[x]
				var frame_rail := av > w * 0.22 and av < w * 0.42
				var fifth := Vector2(float(x) + 0.5 - float(fx), v * 1.2).length() < w * 0.42
				var flap := x <= x_tail + 1 and av > w * 0.62
				if fifth:
					p.h0[i] = deck_z + 1
					p.m0[i] = CarArt.M_STEEL | (2 << 8) if Vector2(float(x) + 0.5 - float(fx), v).length() > 1.5 else CarArt.M_TRIM
				elif frame_rail:
					p.h0[i] = deck_z
					p.m0[i] = CarArt.M_TRIM | (1 << 8)
				elif flap:
					p.h0[i] = deck_z - 1
					p.b0[i] = 1
					p.m0[i] = CarArt.M_TRIM
				else:
					p.h0[i] = -1
					continue
				p.belt[i] = 999
				p.b0[i] = mini(p.b0[i], p.h0[i] - 1)
		# the stacks: chrome pipes up the back corners of the cab, over the roof
		for s: float in [-1.0, 1.0]:
			var y2 := int(floor(p.cy + s * (p.hw[xc] - 1.5)))
			var i2 := p.idx(maxi(0, xc - 1), y2)
			p.b2[i2] = rail
			p.h2[i2] = int(p.roof_z) + 3
			p.m2[i2] = CarArt.M_CHROME | (3 << 8)
		p.lz1 = maxi(p.lz1, int(p.roof_z) + 3)

	## What's in the bed: lumber, firewood, boxes, a load of mulch, the spare.
	func _bed_load(load: String, xc: int, floor_z: int, rail: int) -> void:
		if load == "": return
		var x0 := x_tail + 2
		var x1 := xc - 2
		for x in range(x0 - (3 if load == "lumber" else 0), x1):
			for y in p.sy:
				var av := absf(float(y) + 0.5 - p.cy)
				var xi := maxi(x, 0)
				var i := p.idx(xi, y)
				var hw: float = p.hw[mini(p.sx - 1, maxi(x, x_tail + 2))] - 1.8
				var h := -1
				var m := 0
				match load:
					"lumber":
						if av < hw * 0.7:
							h = rail + 1
							m = CarArt.M_CARGO | ((y % 2) << 8) | (0 << 16)
					"firewood":
						if av < hw and x < x1 - 1:
							h = floor_z + 3 + int(av < hw * 0.5)
							m = CarArt.M_CARGO | (((x * 3 + y * 5) % 3) << 8) | (1 << 16)
					"boxes":
						var bxk := (x - x0) / 4
						var byk := int(av) / 3
						if av < hw and (bxk + byk) % 3 != 2:
							h = floor_z + 3 + (bxk + byk) % 2 * 2
							m = CarArt.M_CARGO | (int((x - x0) % 4 == 0 or int(av) % 3 == 0) << 8) | (2 << 16)
					"mulch":
						var hump := 1.0 - pow(av / maxf(1.0, hw), 2.0)
						if av < hw:
							h = floor_z + int(round(hump * 4.0))
							m = CarArt.M_CARGO | (((x + y) % 3) << 8) | (3 << 16)
					"spare":
						var cx := float(x0) + p.tire_r + 1.0
						var dd := Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - p.cy).length()
						if dd < p.tire_r:
							h = floor_z + 2
							m = CarArt.M_TIRE if dd > p.tire_r * 0.55 else CarArt.M_CHROME | (2 << 8)
				if h < 0: continue
				if p.h0[i] < 0:
					p.b0[i] = rail
					p.belt[i] = 999
				p.h0[i] = h if load == "lumber" else maxi(p.h0[i], h)
				p.m0[i] = m

	## A bull bar, a plow, a spare on the back door, a snorkel, exhaust tips, a body kit.
	func _bolt_ons() -> void:
		var hood_z := int(p.z_nose.z)
		# the bull bar (1ton's bash bar, or the factory one)
		if mods.get("bash", false) or art.has("bullbar"):
			var chrome: bool = art.has("bullbar") and not mods.get("bash", false)
			var mat := (CarArt.M_CHROME | (2 << 8)) if chrome else (CarArt.M_TRIM | (1 << 8))
			var xb := mini(p.sx - 1, x_nose + 2)
			var w: float = p.hw[x_nose] * 0.8
			for y in p.sy:
				var av := absf(float(y) + 0.5 - p.cy)
				if av > w: continue
				var i := p.idx(xb, y)
				var upright := absf(av - w * 0.45) < 0.8
				p.b0[i] = int(p.z_nose.x) if upright else hood_z - 1
				p.h0[i] = hood_z + (1 if upright else 0)
				p.belt[i] = 999
				p.m0[i] = mat
				var i2 := p.idx(xb - 1, y)
				if p.h0[i2] < 0 and upright:
					p.b0[i2] = int(p.z_nose.x)
					p.h0[i2] = int(p.z_nose.x) + 1
					p.belt[i2] = 999
					p.m0[i2] = mat
		if art.has("plow"):
			for x in range(mini(p.sx - 1, x_nose + 2), p.sx):
				for y in p.sy:
					var av2 := absf(float(y) + 0.5 - p.cy)
					if av2 > p.hw[x_nose] + 1.0: continue
					var i3 := p.idx(x, y)
					p.b0[i3] = 0
					p.h0[i3] = maxi(2, hood_z - 3 - (x - x_nose - 2))
					p.belt[i3] = 999
					p.m0[i3] = CarArt.M_STEEL | ((2 if x == x_nose + 2 else 1) << 8) | (1 << 16)
		# a spare on the back door
		var spare: bool = (mods.get("spare", false) or art.has("spare")) and fam in ["offroad", "suv"]
		if spare:
			var r: float = p.tire_r * 0.95
			var zc := float(p.z_tail.y) + r * CarArt.RISE * 0.6
			for x in range(maxi(0, x_tail - 2), x_tail):
				for y in p.sy:
					var dv := absf(float(y) + 0.5 - p.cy)
					if dv > r: continue
					var dz := CarArt.RISE * sqrt(maxf(0.0, r * r - dv * dv))
					var i4 := p.idx(x, y)
					p.b1[i4] = int(round(zc - dz))
					p.h1[i4] = int(round(zc + dz))
					p.m1[i4] = CarArt.M_TIRE | ((1 if x == x_tail - 2 else 0) << 16) | (1 << 20)
		if art.has("snorkel"):
			var xs := int(round(X(float(d.a_bot)))) + 1
			var ys := int(floor(p.cy + p.hw[mini(xs, p.sx - 1)]))
			for x in range(xs, mini(p.sx, xs + 2)):
				if ys < p.sy:
					var i5 := p.idx(x, ys)
					p.b0[i5] = int(p.z_nose.z)
					p.h0[i5] = int(p.roof_z)
					p.belt[i5] = 999
					p.m0[i5] = CarArt.M_TRIM
		# exhaust tips poking out the back
		var ex := String(mods.get("exhaust", d.get("exhaust", "single")))
		var tips: Array = []
		match ex:
			"single": tips = [0.55]
			"dual": tips = [-0.55, 0.55]
			"quad": tips = [-0.62, -0.45, 0.45, 0.62]
		if ex != "side" and float(dmg.get("rear", 0.0)) < 0.6 and not fam in ["boxtruck"]:
			for t: float in tips:
				var y2 := int(floor(p.cy + t * p.hw[x_tail]))
				if y2 < 0 or y2 >= p.sy: continue
				var i6 := p.idx(_past(-1, y2), y2)
				if p.h0[i6] >= 0: continue
				p.b0[i6] = maxi(0, int(p.z_tail.x) - 2)
				p.h0[i6] = int(p.z_tail.x) - 1
				p.belt[i6] = 999
				p.m0[i6] = CarArt.M_CHROME | ((3 if ex != "single" else 1) << 8)
		elif ex == "side":
			var x0 := int(X(float(d.wr) + float(d.tire_r) * 1.3))
			var x1 := int(X(float(d.wf) - float(d.tire_r) * 1.3))
			for x in range(x0, x1):
				for s: float in [-1.0, 1.0]:
					var y3 := int(floor(p.cy + s * (p.hw[x] + 0.5)))
					if y3 < 0 or y3 >= p.sy: continue
					var i7 := p.idx(x, y3)
					if p.h0[i7] >= 0: continue
					p.b0[i7] = 1
					p.h0[i7] = 2
					p.belt[i7] = 999
					p.m0[i7] = CarArt.M_CHROME | (3 << 8)
		# the body kit: a lip under the nose, skirts down the sills, a diffuser under the tail
		var kit: Dictionary = mods.get("kit", {})
		if kit.get("lip", false) and float(dmg.get("front", 0.0)) < 0.5:
			for y in p.sy:
				var av3 := absf(float(y) + 0.5 - p.cy)
				var i8 := p.idx(_past(1, y), y)
				if av3 > p.hw[x_nose] * 0.92 or p.h0[i8] >= 0: continue
				p.b0[i8] = 0
				p.h0[i8] = 1
				p.belt[i8] = 999
				p.m0[i8] = CarArt.M_TRIM | (1 << 8)
		if kit.get("skirts", false):
			for x in range(x_tail + 2, x_nose - 1):
				var near_wheel := false
				for wv: Array in p.wheels:
					if absf(float(x) + 0.5 - float(wv[0])) < float(wv[2]) * 1.1: near_wheel = true
				if near_wheel: continue
				for s2: float in [-1.0, 1.0]:
					var y4 := int(floor(p.cy + s2 * (p.hw[x] + 0.4)))
					if y4 < 0 or y4 >= p.sy: continue
					var i9 := p.idx(x, y4)
					if p.h0[i9] >= 0: continue
					p.b0[i9] = 0
					p.h0[i9] = 1
					p.belt[i9] = 999
					p.m0[i9] = _paint(2, CarArt.R_BODY)
		if kit.get("diffuser", false) and float(dmg.get("rear", 0.0)) < 0.5:
			for y in p.sy:
				var av4 := absf(float(y) + 0.5 - p.cy)
				var i10 := p.idx(_past(-1, y), y)
				if av4 > p.hw[x_tail] * 0.7 or p.h0[i10] >= 0: continue
				p.b0[i10] = 0
				p.h0[i10] = 1 if int(av4) % 3 != 0 else 2
				p.belt[i10] = 999
				p.m0[i10] = CarArt.M_TRIM

	## The first column past the nose (dir 1) or the tail (-1) with nothing in it on row y: a lip
	## or a tip goes on in front of a bumper that juts.
	func _past(dir: int, y: int) -> int:
		var x := x_nose + 1 if dir > 0 else x_tail - 1
		while x > 0 and x < p.sx - 1 and p.h0[p.idx(x, y)] >= 0: x += dir
		return clampi(x, 0, p.sx - 1)

	# ------------------------------------------------------------ last

	## How many slices, and which way each pixel's visible side faces (for the side bands): for
	## every pixel the lowest top among its neighbours (below that its side is hidden), and which
	## neighbour that is.
	func _finish() -> void:
		var top_z := 1
		for i in p.h0.size():
			top_z = maxi(top_z, maxi(p.h0[i], maxi(p.h1[i], p.h2[i])))
		p.n = top_z + 1
		p.lz1 = mini(p.lz1, p.n - 1)
		p.lz0 = clampi(p.lz0, 0, p.lz1)
		var sx := p.sx
		var sy := p.sy
		var h := p.h0.duplicate()
		for i in h.size():
			if h[i] < 0: h[i] = -2
		# the 3-wide minimum along each row, then down each column: the 8 neighbours (and itself)
		var row_min := PackedInt32Array()
		row_min.resize(h.size())
		for y in sy:
			var r := y * sx
			for x in sx:
				var a: int = h[r + x]
				if x > 0: a = mini(a, h[r + x - 1])
				else: a = -2
				if x < sx - 1: a = mini(a, h[r + x + 1])
				else: a = -2
				row_min[r + x] = a
		for y in sy:
			var r2 := y * sx
			for x in sx:
				var i := r2 + x
				var m8: int = row_min[i]
				m8 = mini(m8, row_min[i - sx] if y > 0 else -2)
				m8 = mini(m8, row_min[i + sx] if y < sy - 1 else -2)
				p.nmin[i] = m8
				var hl: int = h[i - 1] if x > 0 else -2
				var hr: int = h[i + 1] if x < sx - 1 else -2
				var hu: int = h[i - sx] if y > 0 else -2
				var hd: int = h[i + sx] if y < sy - 1 else -2
				var low := mini(mini(hl, hr), mini(hu, hd))
				p.nmin4[i] = low
				if hr == low: p.face[i] = 2
				elif hl == low: p.face[i] = 3
				else: p.face[i] = 1

## The bottom edge of a profile outline, sampled like CarGen.top_line (-1 where there's no body).
static func _bottom_line(outline: PackedVector2Array) -> PackedFloat32Array:
	var tn := CarGen.TOP_N
	var out := PackedFloat32Array()
	out.resize(tn + 1)
	out.fill(99.0)
	var cnt := outline.size()
	for i in cnt:
		var a := outline[i]
		var b := outline[(i + 1) % cnt]
		var k0 := clampi(int(ceil(minf(a.x, b.x) * tn)), 0, tn)
		var k1 := clampi(int(floor(maxf(a.x, b.x) * tn)), 0, tn)
		var flat := absf(b.x - a.x) < 0.000001
		for kk in range(k0, k1 + 1):
			var y := minf(a.y, b.y) if flat else lerpf(a.y, b.y, (float(kk) / tn - a.x) / (b.x - a.x))
			if y < out[kk]: out[kk] = y
	for kk in tn + 1:
		if out[kk] > 50.0: out[kk] = -1.0
	return out

static func _line_at(line: PackedFloat32Array, x: float) -> float:
	var tn := CarGen.TOP_N
	var f := clampf(x, 0.0, 1.0) * tn
	var kk := mini(int(f), tn - 1)
	return lerpf(line[kk], line[kk + 1], f - float(kk))

# ================================================================== the paint

## Paints a plan: the colour of every top and every side a camera can see, slice by slice, into
## the atlas; the lit lamps into their own slices; the front wheels into their own stack.
class _Painter:
	var art: CarArt
	var p: Plan
	var d: Dictionary
	var mods: Dictionary
	var paint: Color
	var seed := 1
	var pal: Array[Color] = []         # the paint, deep shadow to specular
	var pal2: Array[Color] = []        # a second colour: two-tone, the split livery
	var stripe := Color.BLACK
	var finish := "gloss"
	var stripes := "none"
	var livery := "none"
	var hood := "stock"
	var tint := 0.0
	var aw := 0                        # atlas width
	var buf := PackedInt32Array()
	var lamp_brake := PackedInt32Array()
	var lamp_rev := PackedInt32Array()
	var lamp_head := PackedInt32Array()
	var lamp_bl := PackedInt32Array()
	var lamp_br := PackedInt32Array()
	var lamp_beacon := PackedInt32Array()
	var dmg: Dictionary
	var rim_c := Color("c9ced6")
	var rim_style := "fivespoke"
	var rim_frac := 0.66
	var caliper := Color("5a5e66")
	var wall := "none"
	var glass: Array[Color] = []
	var decal := -1
	var decal_c := Color.WHITE
	var primer := ""
	var door_c := Color.BLACK
	var year := 2000
	# the wear, unpacked
	var dirt := 0.0
	var salt := 0.0
	var rust := 0.0
	var dents := 0.0
	var dmg_any := false
	var dmg_f := 0.0
	var dmg_r := 0.0
	var dmg_l := 0.0
	var dmg_rt := 0.0
	var plain := true                  # nothing on the paint but the paint: the fast way through
	var twotone := false
	# the design, unpacked (dictionary lookups are slow in the inner loops)
	var wf := 0.8
	var cowl := 0.6
	var crease := 0.3
	var spear_y := 0.4
	var t_moulding := false
	var t_spear := false
	var t_clad := false
	var t_rocker := false
	var wood := false
	var portholes := false
	var skirts := false
	var lip := false
	var bumper := 0                    # 0 body, 1 chrome, 2 rubber, 3 steel
	var popup := false
	var tail_kind := "swept"
	var grille_w := 0.5
	var grille_none := false
	var chrome_frame := false
	var seat_c := Color("26262a")
	var fleet := ""                    # schoolbus, bus, ambulance, packer: the outfit's bands down the side
	var black_roof: Array[Color] = []  # a floating roof: the roof and its pillars in gloss black
	# per column
	var door0 := PackedByteArray()     # the front doors' span
	var door1 := PackedByteArray()     # the back doors'
	var arch := PackedFloat32Array()   # how near an arch (rust starts there)
	var flank_c := PackedInt32Array()  # the flank's colour at (x, z, side), worked out once

	func _init(the_art: CarArt, plan: Plan, the_paint: Color, the_mods: Dictionary, the_seed: int) -> void:
		art = the_art
		art._imgs = {}
		p = plan
		d = plan.d
		mods = the_mods
		paint = the_paint
		seed = the_seed
		dmg = the_art.dmg
		year = int(mods.get("year", d.year))
		finish = String(mods.get("finish", "gloss"))
		var wear: Dictionary = mods.get("wear", {})
		var faded := float(wear.get("faded", 0.0))
		var base := paint
		if faded > 0.0: base = base.lerp(Color(base.get_luminance(), base.get_luminance(), base.get_luminance()).lightened(0.18), faded * 0.45)
		var r := CarGen.ramp(base, finish)
		for kk: String in ["deep", "sh", "mid", "base", "lt", "hi", "spec"]: pal.append(r[kk])
		var second := Color("ece6d6") if paint.get_luminance() < 0.7 else Color("7a1a1a")
		stripe = CarGen._col(mods.get("stripe_color", null), Color("1e1e24") if paint.get_luminance() > 0.55 else Color("f0ece4"))
		livery = String(mods.get("livery", "none"))
		if livery == "split": second = stripe
		var r2 := CarGen.ramp(second, "gloss" if finish == "chrome" else finish)
		for kk: String in ["deep", "sh", "mid", "base", "lt", "hi", "spec"]: pal2.append(r2[kk])
		stripes = String(mods.get("stripes", "none"))
		if stripes == "none" and d.art.has("stripes") and not mods.has("stripes"): stripes = String(d.get("stripe_kind", "racing"))
		if stripes in ["hockey", "tail", "rainbow"]: stripes = "side"
		hood = String(mods.get("hood", "stock"))
		tint = clampf(float(mods.get("tint", 0.0)), 0.0, 1.0)
		dirt = float(wear.get("dirt", 0.0))
		salt = float(wear.get("salt", 0.0))
		rust = float(wear.get("rust", d.art.get("rust", 0.0)))
		if mods.has("rust"): rust = float(mods.rust)
		dents = float(wear.get("dents", 0.0))
		primer = String(wear.get("primer", ""))
		if wear.has("door"): door_c = Color(String(wear.door))
		decal = int(mods.get("decal", -1))
		if decal >= 0: decal_c = CarArt.DECALS[decal % CarArt.DECALS.size()][1]
		dmg_f = float(dmg.front)
		dmg_r = float(dmg.rear)
		dmg_l = float(dmg.left)
		dmg_rt = float(dmg.right)
		dmg_any = dmg_f + dmg_r + dmg_l + dmg_rt > 0.0
		twotone = d.art.has("twotone")
		plain = not (twotone or livery != "none" or stripes != "none" or door_c != Color.BLACK or primer != "" or hood != "stock" \
			or finish in ["metallic", "pearl", "chrome"] or dirt > 0.0 or salt > 0.0 or rust > 0.0 or dents > 0.0 or dmg_any)
		var look := CarGen.wheel_look(d, mods, 200)
		rim_style = String(look[0])
		var wm: Dictionary = look[1]
		rim_frac = clampf(float(wm.get("rim_size", 0.66)), 0.42, 0.86)
		if String(wm.get("tire_kind", "stock")) == "mud": rim_frac = minf(rim_frac, 0.6)
		rim_c = CarGen._col(wm.get("rim_color", null), Color("c9ced6") if not rim_style in ["beadlock", "steel"] else (Color("2a2e36") if rim_style == "beadlock" else Color("d8dce2")))
		if rim_style in ["deepdish", "wire", "hubcap", "dish"] and not wm.has("rim_color"): rim_c = Color("dfe3e8")
		caliper = CarGen._col(mods.get("caliper", null), Color("5a5e66"))
		wall = String(wm.get("wall", "none"))
		var g0 := CarArt.GLASS.lerp(Color("07090c"), tint * 0.8)
		glass = [g0, g0.lerp(CarArt.GLASS_HI, 0.35 - tint * 0.2), g0.lerp(CarArt.GLASS_HI, 0.7 - tint * 0.3), Color("9ab4cc").lerp(g0, tint * 0.5)]
		# the design's numbers the inner loops want
		wf = float(d.wf)
		cowl = float(d.cowl_x)
		crease = float(d.get("crease", 0.3))
		spear_y = float(d.get("spear_y", 0.4))
		var trim: Array = d.get("trim", [])
		t_moulding = trim.has("moulding")
		t_spear = trim.has("spear")
		t_clad = trim.has("cladding") or trim.has("arch_cladding")
		t_rocker = trim.has("rocker_chrome")
		wood = d.art.has("wood")
		portholes = d.art.has("portholes")
		var kit: Dictionary = mods.get("kit", {})
		skirts = kit.get("skirts", false)
		lip = kit.get("lip", false)
		var bs := String(d.get("bumper", "body"))
		if mods.get("smooth", false) and bs in ["chrome", "chrome5"]: bs = "body"
		bumper = { "chrome": 1, "chrome5": 1, "rubber": 2, "strip": 2, "steel": 3 }.get(bs, 0)
		popup = String(d.get("head", "")) == "popup"
		tail_kind = String(d.get("tail_lamp", "swept"))
		var grille := String(d.get("grille", "none"))
		grille_w = 0.5 if grille != "big" else 0.62
		if String(d.family) in ["pickup", "suv", "boxtruck", "van"] or bool(d.get("boxy", false)): grille_w = 0.6
		var dna: Dictionary = d.get("dna", {})
		grille_none = int(d.year) >= 2012 and String(dna.get("grille", "")) == "none"
		chrome_frame = String(d.get("frame", "black")) == "chrome"
		seat_c = Color("3a2c26") if int(d.year) < 1985 else Color("26262a")
		# the late cars that float their roof on blacked-out pillars (one in three, by the car)
		var fam_r := String(d.family)
		if int(d.year) >= 2014 and fam_r in ["sedan", "hatch", "coupe", "suv"] and paint.get_luminance() > 0.2 and not twotone \
				and absi(String(d.get("id", d.model)).hash()) % 3 == 0 and not mods.has("livery"):
			var rb := CarGen.ramp(Color("1a1c20"), "gloss")
			for kk: String in ["deep", "sh", "mid", "base", "lt", "hi", "spec"]: black_roof.append(rb[kk])
		if String(d.rear) == "open":
			# an open car shows off its seats: black, tan, red or cream leather, by the car
			var hides: Array[Color] = [Color("3e3e46"), Color("9a7650"), Color("8a2a24"), Color("d0c4a4")]
			if int(d.year) >= 1995: hides = [Color("3e3e46"), Color("3e3e46"), Color("9a7650"), Color("8a2a24")]
			seat_c = hides[absi(String(d.get("id", d.model)).hash()) % hides.size()]
		for fk: String in ["schoolbus", "bus", "ambulance", "packer"]:
			if d.art.has(fk) and fleet == "": fleet = fk
		if String(d.family) == "trailer": fleet = "trailer"
		# per column
		door0.resize(p.sx)
		door1.resize(p.sx)
		arch.resize(p.sx)
		var cuts: Array = d.get("door_cuts", [])
		for x in p.sx:
			var u: float = p.ux[x]
			if not cuts.is_empty():
				var c0: Array = cuts[0]
				var c1: Array = cuts[cuts.size() - 1]
				door0[x] = 1 if u < float(c0[0]) - 0.005 and u > float(c0[1]) + 0.005 else 0
				door1[x] = 1 if u < float(c1[0]) - 0.005 and u > float(c1[1]) + 0.005 else 0
			var pot := 0.0
			for wv: Array in p.wheels:
				var dd := absf(float(x) + 0.5 - float(wv[0])) - float(wv[2]) * 1.1
				if dd > -1.0 and dd < 2.0: pot = 1.0
			arch[x] = pot
		flank_c.resize(p.sx * p.n * 2)

	func run() -> void:
		aw = p.sx * p.n
		buf.resize(aw * p.sy)
		art.lamp_z0 = p.lz0
		art.lamp_n = maxi(1, p.lz1 - p.lz0 + 1)
		var ln := p.sx * art.lamp_n * p.sy
		lamp_brake.resize(ln)
		lamp_rev.resize(ln)
		lamp_head.resize(ln)
		lamp_bl.resize(ln)
		lamp_br.resize(ln)
		lamp_beacon.resize(ln)
		for y in p.sy:
			for x in p.sx:
				var i := y * p.sx + x
				if p.h1[i] >= 0: _column_wheel(i, x, y)
				if p.h0[i] >= 0: _column_body(i, x, y)
				if p.h2[i] >= 0: _column_bolt(i, x, y)
		art._imgs.atlas = Image.create_from_data(aw, p.sy, false, Image.FORMAT_RGBA8, buf.to_byte_array())
		var lw := p.sx * art.lamp_n
		art._imgs.brake = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_brake.to_byte_array())
		art._imgs.rev = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_rev.to_byte_array())
		art._imgs.head = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_head.to_byte_array())
		art._imgs.bl = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_bl.to_byte_array())
		art._imgs.br = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_br.to_byte_array())
		art._imgs.beacon = Image.create_from_data(lw, p.sy, false, Image.FORMAT_RGBA8, lamp_beacon.to_byte_array())
		_front_wheel_stack()

	func _lamp(kind: int, x: int, y: int, z: int, c: Color) -> void:
		var zz := z - p.lz0
		if zz < 0 or zz >= art.lamp_n: return
		var at := y * p.sx * art.lamp_n + zz * p.sx + x
		var ci := c.to_abgr32()
		match kind:
			0: lamp_brake[at] = ci
			1: lamp_rev[at] = ci
			2: lamp_head[at] = ci
			3: lamp_bl[at] = ci
			4: lamp_br[at] = ci
			5:
				lamp_beacon[at] = ci
				art.has_beacons = true

	## A cheap, steady noise for (x, y): the same pixel gets the same speck every time.
	func _hn(x: int, y: int, s := 0) -> float:
		var h := (x * 374761393 + y * 668265263 + (seed + s) * 1442695041) & 0x7fffffff
		h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
		return float(h % 1000) / 1000.0

	# ------------------------------------------------------------ the columns

	func _column_body(i: int, x: int, y: int) -> void:
		var top: int = p.h0[i]
		var b: int = p.b0[i]
		var m: int = p.m0[i]
		var c := _top_colour(m, x, y)
		# the rim of every top (where the next pixel over drops away) gets an ink line
		var rim: int = p.nmin4[i]
		# (a headlamp's edge is one dark bezel all the way round, whichever way the car's turned)
		if (m & 255) == CarArt.M_HEAD and (rim < 0 or rim < top - 1): c = CarArt.HEAD_RIM
		elif rim < 0: c = c.darkened(0.42)
		elif rim < top - 3 and (m & 255) != CarArt.M_GLASS: c = c.darkened(0.2)
		var row := y * aw + x
		buf[row + top * p.sx] = c.to_abgr32()
		if (m & 255) >= CarArt.M_HEAD and (m & 255) <= CarArt.M_REV or (m & 255) == CarArt.M_LIGHTBAR or (m & 255) == CarArt.M_BRAKE3: _lamp_top(m, x, y, top)
		var vis: int = clampi(p.nmin[i], b, top)
		# hidden inside the stack: any colour will do
		if vis > b:
			var fill := c.darkened(0.3).to_abgr32()
			for z in range(b, vis): buf[row + z * p.sx] = fill
		if vis >= top: return
		var face: int = p.face[i]
		var belt: int = p.belt[i]
		var bolt := (m & 255) != CarArt.M_PAINT and belt >= 999
		var ground := p.nmin4[i] < 0
		# a step inside the body (a raked hood, a crowned roof) is the same surface as its top;
		# only the car's outside faces carry the bumpers, the lamps and the grille
		var inner := p.nmin[i] >= 0
		var riser := c.darkened(0.12)
		# a crowned roof or hood steps down a slice at a time: the same paint all the way, so the
		# steps don't draw contour lines across it
		var smooth := inner and (m & 255) == CarArt.M_PAINT and top - p.nmin[i] <= 2 and _paint_round(i)
		for z in range(vis, top):
			var sc: Color
			if bolt: sc = _top_colour(m, x, y).darkened(0.25)
			elif smooth: sc = c
			elif inner and z <= belt: sc = riser
			elif z > belt: sc = _glass_side(i, x, y, z, belt)
			else:
				var t := clampf(float(z - b) / maxf(1.0, float(mini(belt, top) - b)), 0.0, 1.0)
				match face:
					2: sc = _front_face(x, y, z)
					3: sc = _rear_face(x, y, z)
					_:
						var side := 0 if float(y) < p.cy else 1
						var fi := (x * p.n + z) * 2 + side
						var cached: int = flank_c[fi]
						if cached != 0: sc = Color.hex(cached)
						else:
							sc = _flank(x, y, z, t)
							flank_c[fi] = sc.to_rgba32()
			if z == b and ground: sc = sc.lerp(CarArt.INK, 0.65)
			buf[row + z * p.sx] = sc.to_abgr32()

	## True when every neighbour lower than this pixel is paint too (a step inside one panel).
	func _paint_round(i: int) -> bool:
		var top: int = p.h0[i]
		for j: int in [i - 1, i + 1, i - p.sx, i + p.sx]:
			if j < 0 or j >= p.h0.size() or p.h0[j] >= top: continue
			if (p.m0[j] & 255) != CarArt.M_PAINT: return false
		return true

	func _column_wheel(i: int, x: int, y: int) -> void:
		var top: int = p.h1[i]
		var b: int = p.b1[i]
		var m: int = p.m1[i]
		var outer := ((m >> 16) & 15) == 1
		var xc := 0.0
		var r := p.tire_r
		for wv: Array in p.wheels:
			if absf(float(x) + 0.5 - float(wv[0])) <= float(wv[2]) + 0.5: xc = float(wv[0])
		if (m >> 20) & 1 == 1: xc = float(x) + 0.5
		var row := y * aw + x
		buf[row + top * p.sx] = (Color("2a2d33") if x % 2 == 0 else Color("1f2226")).to_abgr32()
		var dark := Color("121418").to_abgr32()
		for z in range(b, top):
			if outer: buf[row + z * p.sx] = _rim_face(float(x) + 0.5 - xc, float(z) + 0.5 - r * CarArt.RISE, r).to_abgr32()
			else: buf[row + z * p.sx] = dark

	func _column_bolt(i: int, x: int, y: int) -> void:
		var top: int = p.h2[i]
		var b: int = p.b2[i]
		var m: int = p.m2[i]
		var c := _top_colour(m, x, y)
		var row := y * aw + x
		buf[row + top * p.sx] = (c.darkened(0.15) if p.nmin4[i] < 0 else c).to_abgr32()
		_lamp_top(m, x, y, top)
		for z in range(b, top):
			buf[row + z * p.sx] = _bolt_side(m, x, y, z, b, top).to_abgr32()
			_lamp_top(m, x, y, z)

	# ------------------------------------------------------------ colours

	## The paint at a pixel: the ramp's shade, then whatever's on it (stripes, liveries, a primer
	## panel, a door off another car, the finish), then the road's wear and the dents. `side_t` is
	## how high up the flank it is (0 sill .. 1 shoulder), or -1 for a top.
	func _paint_c(shade: int, reg: int, x: int, y: int, side_t := -1.0) -> Color:
		if plain: return pal[shade]
		var u: float = p.ux[x]
		var v := float(y) + 0.5 - p.cy
		var vn := absf(v) / maxf(1.0, p.hw[x])
		var use2 := false
		# two-tone: the roof and the band under the glass in the second colour
		if twotone and (reg == CarArt.R_ROOF or reg == CarArt.R_PILLAR or side_t > 0.62): use2 = true
		if livery == "split" and side_t >= 0.0 and side_t < 0.5: use2 = true
		var c: Color = pal2[shade] if use2 else pal[shade]
		# a door off another car, a primer hood, a primer fender
		if door_c != Color.BLACK and (side_t >= 0.0 or absf(v) > p.gb) and door0[x] == 1: c = door_c.lerp(Color.BLACK, 0.1 * float(6 - shade) / 6.0)
		elif primer != "" and _primer_at(reg, x, v, side_t): c = CarArt.PRIMER.lerp(Color("6a6a66"), 0.2 * float(6 - shade) / 6.0)
		if hood != "stock" and (reg == CarArt.R_HOOD or reg == CarArt.R_SCOOP):
			if hood == "carbon":
				c = Color("2a2c30") if (x + y) % 2 == 0 else Color("1a1b1e")
				if shade >= 5 and (x * 3 + y) % 4 == 0: c = Color("4a4e56")
			elif hood == "vented" and _louvre(x, vn): c = CarArt.TRIM
		# stripes and liveries
		if side_t < 0.0:
			if stripes == "racing" and vn > 0.1 and vn < 0.3 and reg != CarArt.R_PILLAR: c = stripe
			elif stripes == "rally" and reg != CarArt.R_PILLAR:
				var vv := v / maxf(1.0, p.hw[x])
				if vv > -0.42 and vv < -0.12: c = stripe
			match livery:
				"slash":
					if fposmod(u + v / maxf(1.0, float(p.lpx)) * 2.4, 0.5) < 0.06: c = stripe
				"flames":
					if reg == CarArt.R_HOOD or reg == CarArt.R_SCOOP or reg == CarArt.R_FENDER: c = _flame(u, v, c)
				"sponsor":
					if reg == CarArt.R_ROOF and vn < 0.5: c = stripe
		else:
			if stripes == "side" and absf(side_t - 0.62) < 0.08: c = stripe
			elif stripes == "racing" and side_t > 0.94: c = stripe
			match livery:
				"slash":
					if fposmod(u + side_t * 0.12, 0.5) < 0.05: c = stripe
				"flames":
					if u > wf - 0.25: c = _flame(u + side_t * 0.04 - 0.2, (side_t - 0.5) * 10.0, c)
				"sponsor":
					if door0[x] == 1 and side_t > 0.25 and side_t < 0.75: c = stripe if not (side_t > 0.45 and side_t < 0.55 and x % 2 == 0) else stripe.lerp(paint, 0.6)
		# finish
		match finish:
			"metallic":
				if _hn(x, y, 3) > 0.86: c = c.lightened(0.18)
			"pearl":
				if shade >= 4: c = c.lerp(Color.from_hsv(fposmod(paint.h + 0.14, 1.0), 0.3, 1.0), 0.12 * float(shade - 3))
			"chrome":
				# bright on the flats, dark where it rolls away, one streak of sky down its length
				c = CarArt.CHROME[clampi(shade - 1, 0, 4)]
				if side_t < 0.0 and shade >= 4 and absf(v + p.hw[x] * 0.3) < 1.0: c = Color.WHITE
				elif side_t >= 0.0 and absf(side_t - 0.55) < 0.1: c = CarArt.CHROME[3]
		return _weathered(c, x, y, side_t, reg)

	func _primer_at(reg: int, x: int, v: float, side_t: float) -> bool:
		var u: float = p.ux[x]
		match primer:
			"hood": return reg == CarArt.R_HOOD or reg == CarArt.R_SCOOP
			"fender": return u > wf - 0.12 and v > 0.0 and (side_t >= 0.0 or reg == CarArt.R_FENDER or absf(v) > p.hw[x] * 0.75)
			"door": return door0[x] == 1 and v < 0.0 and (side_t >= 0.0 or absf(v) > p.gb)
			"trunk": return reg == CarArt.R_DECK
		return false

	func _louvre(x: int, vn: float) -> bool:
		var t := (p.ux[x] - cowl) / maxf(0.01, 1.0 - cowl)
		return t > 0.15 and t < 0.55 and vn > 0.25 and vn < 0.62 and x % 2 == 0

	func _flame(u: float, v: float, c: Color) -> Color:
		var reach := (1.0 - u) * 9.0
		var lane := absf(v) * 0.6
		var lick := 2.0 + sin(lane * 2.1) * 1.2 + float(int(lane * 2.0) % 3)
		if reach > lick: return c
		var kk := reach / maxf(0.1, lick)
		if kk > 0.9: return Color("6a1408")
		return Color("f8d850") if kk < 0.35 else (Color("f08a24") if kk < 0.7 else Color("c8321e"))

	## What the road did to it: dirt and road salt low down, rust round the arches and the sills
	## and the edges of the hood and the trunk, dents; then the crash damage.
	func _weathered(c: Color, x: int, y: int, side_t: float, reg: int) -> Color:
		var low := 1.0 - side_t if side_t >= 0.0 else 0.0
		if dirt > 0.0:
			var dk := dirt * (0.15 + 0.85 * low * low) if side_t >= 0.0 else dirt * 0.25 * (1.0 - p.ux[x])
			if _hn(x, y, 11) < dk: c = c.lerp(Color("5a4c3c"), 0.45)
		if salt > 0.0 and side_t >= 0.0 and _hn(x, y, 13) < salt * low * low * 1.4: c = c.lerp(Color("e4e2dc"), 0.55)
		if rust > 0.0:
			var pot := 0.0
			if side_t >= 0.0: pot = maxf(maxf(low - 0.5, 0.0) * 2.0, arch[x] * 0.8)
			else:
				# from above: round the arches at the edges, the hood's front edge, the trunk lid's
				# back edge, the odd spot on the roof where the paint's gone through
				var u: float = p.ux[x]
				var vn := absf(float(y) + 0.5 - p.cy) / maxf(1.0, p.hw[x])
				pot = arch[x] * 0.6 if vn > 0.78 else 0.0
				if reg == CarArt.R_HOOD and u > 0.94 or reg == CarArt.R_DECK and u < 0.05: pot = maxf(pot, 0.6)
				if reg == CarArt.R_ROOF and _hn(x / 2, y / 2, 17) > 0.93: pot = maxf(pot, 0.5)
			if pot > 0.0 and _hn(x / 2, y / 2, 19) * pot > 1.0 - rust * 0.9: c = Color("8a4e26") if _hn(x, y, 23) > 0.35 else Color("4a2a18")
		if dents > 0.0 and _hn(x / 3, y / 3, 29) < dents * 0.35 and _hn(x, y, 31) < 0.7: c = c.darkened(0.16)
		if dmg_any: return _damaged(c, x, y, side_t)
		return c

	## What a crash did to this pixel: dents (darker, crumpled) toward the side that got hit,
	## scrapes down to primer along the sides.
	func _damaged(c: Color, x: int, y: int, side_t: float) -> Color:
		var u: float = p.ux[x]
		var v := (float(y) + 0.5 - p.cy) / maxf(1.0, p.wpx / 2.0)
		var f := clampf((u - 0.68) / 0.32, 0.0, 1.0) * dmg_f
		var r := clampf((0.32 - u) / 0.32, 0.0, 1.0) * dmg_r
		var l := clampf((-v - 0.35) / 0.65, 0.0, 1.0) * dmg_l
		var rt := clampf((v - 0.35) / 0.65, 0.0, 1.0) * dmg_rt
		var hit := f + r + l + rt
		if hit <= 0.0: return c
		if side_t >= 0.0 and (l > 0.05 or rt > 0.05) and (x + y * 2) % 3 == 0 and _hn(x, y, 41) < (l + rt) * 1.6:
			return c.lerp(CarArt.PRIMER, 0.7)
		if _hn(x, y, 43) < hit * 0.8:
			var dk := 0.5 + _hn(x, y, 47) * 0.3
			return Color(c.r * dk, c.g * dk, c.b * dk, 1.0)
		return c

	func _top_colour(m: int, x: int, y: int) -> Color:
		var mat := m & 255
		var shade := (m >> 8) & 15
		var vr := (m >> 16) & 15
		match mat:
			CarArt.M_PAINT:
				if (m >> 20) & 1 == 1: return _paint_c(shade, (m >> 12) & 15, x, y).darkened(0.38)
				if not black_roof.is_empty() and ((m >> 12) & 15) in [CarArt.R_ROOF, CarArt.R_PILLAR]: return black_roof[clampi(shade - 2, 0, 6)]
				return _paint_c(shade, (m >> 12) & 15, x, y)
			CarArt.M_GLASS:
				var g: Color = glass[clampi(shade, 0, 3)]
				if dmg_any:
					var u: float = p.ux[x]
					if _hn(x, y, 51) < dmg_f * 0.5 and u > 0.5 or _hn(x, y, 53) < dmg_r * 0.4 and u < 0.5: g = Color("c8d0d8")
				return g
			CarArt.M_SIDEGLASS: return glass[0].lerp(glass[1], 0.3)
			CarArt.M_TRIM:
				if vr == 1 and shade == 3: return _vinyl(x, y)
				return [CarArt.TRIM, Color("2a2c32"), Color("34363c"), Color("26282c")][clampi(shade, 0, 3)]
			CarArt.M_CHROME: return CarArt.CHROME[clampi(shade, 0, 4)]
			CarArt.M_TIRE: return Color("1f2226")
			CarArt.M_HEAD:
				if not art.head_ok[clampi(vr, 0, 1)]: return Color("2a2a2e")
				return CarArt.HEAD.darkened(0.12) if (x + y) % 3 else CarArt.HEAD
			CarArt.M_TAIL: return CarArt.TAIL if art.tail_ok[clampi(vr, 0, 1)] else Color("3a1a1a")
			CarArt.M_AMBER: return CarArt.AMBER_OFF
			CarArt.M_REV: return Color("d8d8d0")
			CarArt.M_GRILLE: return Color("17181c")
			CarArt.M_SEAT:
				match shade:
					0: return seat_c.darkened(0.15)
					1: return seat_c
					3: return seat_c.lightened(0.18)
				return Color("1c1c20")
			CarArt.M_DASH: return Color("18181c")
			CarArt.M_BED: return Color("2a2a2e") if shade != 0 else Color("1c1c20")
			CarArt.M_CARGO: return _cargo(vr, shade, x, y)
			CarArt.M_SIGN: return _sign_top(vr, x, y)
			CarArt.M_BEACON:
				# amber, an ambulance's red, or a clear lens
				match vr:
					1: return Color("b81c18") if (x + y) % 2 == 0 else Color("8a1410")
					2: return Color("e4e6ea")
				return CarArt.AMBER if (x + y) % 2 == 0 else CarArt.AMBER.darkened(0.2)
			CarArt.M_PLATE: return Color("d8d4c0")
			CarArt.M_BRAKE3: return Color("7a1414")
			CarArt.M_LIGHTBAR: return Color("f4f4ec") if shade != 0 else Color("2a2c32")
			CarArt.M_STEEL:
				if vr == 1: return Color("e8b020").darkened(0.1 * shade)
				return CarArt.STEEL.darkened(0.12 * float(shade))
			CarArt.M_LADDER: return Color("c8ccd2") if shade == 0 else Color("9a9ea6")
			CarArt.M_WOOD: return Color("8a5630")
		return Color("ff00ff")

	func _vinyl(x: int, y: int) -> Color:
		var vc := Color("1e1c1e") if paint.get_luminance() > 0.3 else Color("e8e2d0")
		return vc.lightened(0.1) if (x + y * 3) % 7 == 0 else vc

	func _cargo(kind: int, shade: int, x: int, y: int) -> Color:
		match kind:
			0: return Color("d8b880") if shade == 0 else Color("b89a64")          # lumber
			1: return [Color("8a5a34"), Color("6a4428"), Color("a87a4a")][shade % 3]  # firewood
			2: return Color("b88a52") if shade == 0 else Color("8a6436")           # boxes
			3: return [Color("5a3a22"), Color("4a2e1a"), Color("6a4628")][shade % 3]  # mulch
		return Color("6a6e74").lightened(_hn(x, y, 5) * 0.1)

	## A roof sign from above: its top edge in the sign's colour.
	func _sign_top(kind: int, x: int, y: int) -> Color:
		match kind:
			0: return Color("f0c020") if (x + y) % 4 != 0 else Color("e8e4d8")
			1: return Color("c8321e") if x % 2 == 0 else Color("f0e8d8")
			2: return Color("f0f0ec") if (y % 3) != 0 else Color("c8241c")
		return Color("f0f0ec")

	## The greenhouse's side at slice z: glass in its frame, or a pillar.
	func _glass_side(i: int, x: int, y: int, z: int, belt: int) -> Color:
		# the steps of a raked windshield or backlight are the same glass as its top
		if (p.m0[i] & 255) == CarArt.M_GLASS: return glass[clampi(((p.m0[i] >> 8) & 15) - 1, 0, 3)]
		var g: int = p.gs[i]
		if g == 0: g = CarArt.M_SIDEGLASS
		if (g & 255) == CarArt.M_PAINT: return _paint_c(2, CarArt.R_PILLAR, x, y, 0.95).darkened(0.08)
		if (g & 255) == CarArt.M_TRIM: return CarArt.TRIM if (p.m0[i] & 255) != CarArt.M_CHROME else CarArt.CHROME[2]
		if z == belt + 1 and chrome_frame: return CarArt.CHROME[2]
		return glass[0] if (z - belt) % 4 != 1 else glass[1]

	## The side of the body at height t (0 sill .. 1 shoulder): rocker, flank, the crease, the
	## shut lines and handles, the trim, a magnetic sign on the door, and the rest of the paint.
	func _flank(x: int, y: int, z: int, t: float) -> Color:
		if t < 0.12 and not skirts: return _paint_c(0, CarArt.R_BODY, x, y, t).lerp(CarArt.TRIM, 0.5)
		var shade := 1 if t < 0.35 else (2 if t < 0.7 else 3)
		if crease > 0.0 and absf(t - (1.0 - crease * 0.9)) < 0.07: shade = 4
		var c := _paint_c(shade, CarArt.R_BODY, x, y, t)
		var dr: int = p.doors[x]
		if dr == 1 and t > 0.14: c = c.darkened(0.45)
		elif dr == 2 and absf(t - 0.8) < 0.1: c = CarArt.CHROME[3]
		# trim down the side by era
		if t_moulding and absf(t - 0.45) < 0.06: c = CarArt.TRIM
		if t_spear and absf(t - 1.0 + spear_y) < 0.06: c = CarArt.CHROME[3]
		if t_clad and t < 0.3: c = Color("2a2c30")
		if t_rocker and t < 0.2: c = CarArt.CHROME[2]
		if wood and t > 0.25 and t < 0.85: c = Color("8a5630") if (z + x / 3) % 3 else Color("6a3e20")
		# a magnetic sign on the front doors (a plumber, a cleaner, a pizza place)
		if decal >= 0 and door0[x] == 1 and t > 0.3 and t < 0.82:
			c = Color("f0ece0") if (t > 0.38 and t < 0.74) else decal_c
			if t > 0.48 and t < 0.64 and (x * 7 + z) % 3 != 0: c = decal_c
		match fleet:
			"schoolbus":
				if absf(t - 0.3) < 0.04 or absf(t - 0.55) < 0.04 or absf(t - 0.8) < 0.04: c = CarArt.INK
			"bus":
				if absf(t - 0.85) < 0.08: c = Color("2a5a9a")
			"ambulance":
				if absf(t - 0.72) < 0.07: c = Color("c8201c")
			"packer":
				if absf(t - 0.6) < 0.12: c = Color("f0f0ec") if (x + z) % 4 != 0 else Color("2a6a3a")
			"trailer":
				# the outfit's name down the side, as big as it gets
				if decal >= 0 and t > 0.35 and t < 0.75 and p.ux[x] > 0.15 and p.ux[x] < 0.85:
					c = decal_c if (t < 0.42 or t > 0.68 or (x * 3 + z) % 4 == 0) else Color("f0f0ec")
		if portholes and absf(t - 0.72) < 0.1 and p.ux[x] > wf - 0.08 and p.ux[x] < wf + 0.02 and x % 3 == 0: c = CarArt.CHROME[2]
		return c

	## The nose at slice z: bumper, grille, headlamps, turn signals.
	func _front_face(x: int, y: int, z: int) -> Color:
		var v := float(y) + 0.5 - p.cy
		var vn := absf(v) / maxf(1.0, p.hw[x])
		var zz := float(z)
		var bump_top: float = p.z_nose.x + 1.0
		var hood_z: float = p.z_nose.z
		if zz <= bump_top:
			if not art.bumper_front: return Color("1a1a1e")
			match bumper:
				1: return CarArt.CHROME[2 if zz == bump_top else 1]
				2: return CarArt.TRIM
				3: return CarArt.STEEL
			if lip and zz < bump_top - 1.0: return CarArt.TRIM
			return _paint_c(2, CarArt.R_BODY, x, y, 0.3)
		if fleet == "trailer": return _paint_c(3, CarArt.R_BODY, x, y, 0.6)
		var lamp_lo := lerpf(bump_top, hood_z, 0.35)
		# the lamps in the nose: a band two or three slices deep under the hood's edge, in a dark
		# bezel (any deeper and, side-on, the stack of them stands up past the hood)
		var head_lo := maxf(lamp_lo, hood_z - 3.0)
		if zz >= head_lo and zz < hood_z - 0.5 and vn > 0.55 and vn < 0.93 and not popup:
			var lit: bool = art.head_ok[0 if v < 0.0 else 1]
			if lit: _lamp(2, x, y, z, CarArt.HEAD)
			if not lit: return Color("2a2a2e")
			return CarArt.HEAD_RIM if vn < 0.6 or vn > 0.89 or zz < head_lo + 0.5 else CarArt.HEAD.darkened(0.08)
		if vn >= 0.9 and zz >= lamp_lo - 1.0 and zz < hood_z:
			_lamp(3 if v < 0.0 else 4, x, y, z, CarArt.AMBER_LIT)
			return CarArt.AMBER_OFF
		if vn < grille_w and zz < hood_z - 0.5 and not grille_none:
			if year >= 1990: return Color("17181c") if z % 2 == 0 else Color("2a2c32")
			return CarArt.CHROME[1 + z % 2]
		return _paint_c(3, CarArt.R_BODY, x, y, 0.6)

	## The tail at slice z: bumper, plate, tail lamps (bar, block, wrap, tower), reverse lamps.
	func _rear_face(x: int, y: int, z: int) -> Color:
		var v := float(y) + 0.5 - p.cy
		var vn := absf(v) / maxf(1.0, p.hw[x])
		var zz := float(z)
		var bump_top: float = p.z_tail.x + 1.0
		var mid: float = p.z_tail.y
		var deck: float = p.z_tail.z
		if zz <= bump_top:
			if not art.bumper_rear: return Color("1a1a1e")
			if vn < 0.22 and zz >= bump_top - 1.0: return Color("d8d4c0")
			match bumper:
				1: return CarArt.CHROME[2 if zz == bump_top else 1]
				2: return CarArt.TRIM
				3: return CarArt.STEEL
			return _paint_c(1, CarArt.R_BODY, x, y, 0.3)
		var side := 0 if v < 0.0 else 1
		var lo := maxf(bump_top + 1.0, mid - 1.0)
		var hi := deck - 0.5
		var on := false
		match tail_kind:
			"bar", "racetrack": on = zz >= lo and zz < hi and vn < 0.94
			"tall":
				lo = maxf(bump_top + 1.0, deck - 2.0)
				on = vn > 0.74 and zz >= lo
			"round", "dual": on = zz >= lo and zz < hi and (absf(vn - 0.78) < 0.12 or tail_kind == "dual" and absf(vn - 0.55) < 0.1)
			_: on = zz >= lo and zz < hi and vn > 0.56
		if on:
			var ok: bool = art.tail_ok[side]
			if ok:
				_lamp(0, x, y, z, CarArt.TAIL_LIT)
				if vn > 0.8: _lamp(3 if v < 0.0 else 4, x, y, z, CarArt.TAIL_LIT)
			if vn > 0.56 and vn < 0.7 and zz < lo + 1.5 and year >= 1970:
				if ok: _lamp(1, x, y, z, CarArt.REV_LIT)
				return Color("d8d8d0")
			return CarArt.TAIL if ok else Color("3a1a1a")
		if vn < 0.22 and zz < mid + 2.0 and zz > bump_top: return Color("d8d4c0")      # the plate
		return _paint_c(2, CarArt.R_BODY, x, y, 0.6)

	## Lamps seen from above light up too.
	func _lamp_top(m: int, x: int, y: int, z: int) -> void:
		var mat := m & 255
		var vr := clampi((m >> 16) & 15, 0, 1)
		match mat:
			CarArt.M_HEAD:
				if art.head_ok[vr]: _lamp(2, x, y, z, CarArt.HEAD)
			CarArt.M_TAIL:
				if art.tail_ok[vr]:
					_lamp(0, x, y, z, CarArt.TAIL_LIT)
					_lamp(3 + vr, x, y, z, CarArt.TAIL_LIT)
			CarArt.M_AMBER: _lamp(3 + vr, x, y, z, CarArt.AMBER_LIT)
			CarArt.M_BRAKE3: _lamp(0, x, y, z, CarArt.TAIL_LIT)
			CarArt.M_BEACON:
				if (m >> 16) & 15 != 0: _lamp(5, x, y, z, Color("ff2a1e") if (m >> 16) & 15 == 1 else Color("f4f8ff"))
			CarArt.M_LIGHTBAR:
				if ((m >> 8) & 15) != 0: _lamp(2, x, y, z, Color("fffff0"))

	func _bolt_side(m: int, x: int, y: int, z: int, b: int, top: int) -> Color:
		var mat := m & 255
		if mat == CarArt.M_SIGN:
			var kind := (m >> 16) & 15
			var t := float(z - b) / maxf(1.0, float(top - b))
			match kind:
				0:
					# a taxi sign: TAXI in black on yellow (as much as four pixels can say it)
					if t > 0.3 and t < 0.8 and (x + z) % 2 == 0: return Color("1a1a1e")
					return Color("f0c020")
				1: return Color("c8321e") if t < 0.5 else Color("f0e8d8")
				2: return Color("c8241c") if absf(t - 0.5) < 0.2 else Color("f0f0ec")
			return Color("f0f0ec")
		return _top_colour(m, x, y).darkened(0.2)

	# ------------------------------------------------------------ wheels

	## The face of a wheel seen from the side, at (dx along, dz up) from its hub: the tire's
	## sidewall, the rim in its style and colour, the caliper behind the spokes, whitewalls.
	func _rim_face(dx: float, dz: float, r: float) -> Color:
		var dist := Vector2(dx, dz / CarArt.RISE).length()
		var rr := r * rim_frac
		if dist > r - 0.6: return Color("101114")
		if dist > rr:
			if wall == "white" and dist < rr + (r - rr) * 0.55: return Color("e8e6e0")
			if wall == "letters" and dist < rr + (r - rr) * 0.5 and int(atan2(dz, dx) * 4.0 + 20.0) % 2 == 0: return Color("d8d6d0")
			return Color("1c1e22")
		var ang := atan2(dz, dx)
		var hi := rim_c.lerp(Color.WHITE, 0.4)
		var lo := rim_c.darkened(0.45)
		if dist < rr * 0.28: return lo if rim_style != "hubcap" else hi
		match rim_style:
			"hubcap", "dish": return hi if dist > rr * 0.7 else rim_c
			"steel": return rim_c if int(ang * 1.9 + 8.0) % 2 == 0 or dist > rr * 0.75 else lo
			"deepdish": return hi if dist > rr * 0.62 else (rim_c if int(ang * 0.8 + 8.0) % 2 == 0 else lo)
			"beadlock": return CarArt.CHROME[3] if dist > rr * 0.78 and int(ang * 3.0 + 12.0) % 2 == 0 else rim_c
			"mesh", "wire": return rim_c if (int(dx * 2.0 + 9.0) + int(dz * 2.0 + 9.0)) % 2 == 0 else lo
		var spokes := 5
		match rim_style:
			"tenspoke": spokes = 10
			"multispoke": spokes = 14
			"turbofan": spokes = 8
		var twist := 0.6 if rim_style == "turbofan" else 0.0
		var s := fposmod((ang + dist * twist) * float(spokes) / TAU, 1.0)
		if s < 0.45: return rim_c if dist < rr * 0.8 else hi
		# a gap between spokes: the caliper shows through on the top-back quarter
		if ang > 0.6 and ang < 2.4 and dist > rr * 0.35: return caliper
		return Color("2a2d33")

	## The front wheel's stack: as many slices as the tire stands tall, the tread on top, the rim's
	## face on the +y side (CarView mirrors it for the left wheel).
	func _front_wheel_stack() -> void:
		var r := p.tire_r
		var wl := int(ceil(r * 2.0)) + 1
		var ww := p.tire_w
		var wn := int(ceil(r * 2.0 * CarArt.RISE)) + 1
		var w_aw := wl * wn
		var wb := PackedInt32Array()
		wb.resize(w_aw * ww)
		var zc := r * CarArt.RISE
		for z in wn:
			for x in wl:
				var dx := float(x) + 0.5 - float(wl) / 2.0
				if absf(dx) > r: continue
				var dz := CarArt.RISE * sqrt(maxf(0.0, r * r - dx * dx))
				var zb := int(round(zc - dz))
				var zt := maxi(zb, int(round(zc + dz)) - 1)
				if z < zb or z > zt: continue
				for y in ww:
					var c := Color("1f2226") if (x % 2 == 0) else Color("2a2d33")
					if z < zt:
						c = Color("121418")
						if y == ww - 1: c = _rim_face(dx, float(z) + 0.5 - zc, r)
					wb[y * w_aw + z * wl + x] = c.to_abgr32()
		art.wheel_n = wn
		art.wheel_size = Vector2i(wl, ww)
		art._imgs.wheel = Image.create_from_data(w_aw, ww, false, Image.FORMAT_RGBA8, wb.to_byte_array())

## Parody businesses for the magnetic signs on work vans' doors: [name, colour].
const DECALS := [
	["GORD'S PLUMBING", Color("1a4a8a")], ["MAPLE HVAC", Color("c8321e")], ["TIDAL BORE CLEANING", Color("2a8a6a")],
	["PIZZA DELIRIUM", Color("c8321e")], ["COVINGTON AUTO", Color("d9a441")], ["LUTES MTN LANDSCAPING", Color("3a7a2a")],
	["PETITCODIAC PEST", Color("6a2a6a")], ["FUNDY FLOORS", Color("8a5a2a")], ["RUMBLE ELECTRIC", Color("e8b020")],
	["HAVELOCK HOME CARE", Color("2a5a9a")],
]
