## Tire smoke that piles up. Every puff a spinning tire throws joins the cloud already hanging
## there if there is one (it gets thicker and bigger) instead of starting a new one, so a long
## burnout builds a fog bank you can lose the car in, and a drift leaves a trail down the road.
## The cloud hangs about, rises, drifts with the wind and thins out over the best part of half a
## minute. Settings > Graphics > TIRE SMOKE turns it off along with the jets off the tires.
class_name SmokeField
extends Node2D

const MAX_PUFFS := 220
const MERGE := 0.7                 # a new puff this close (in radii) to an old one feeds it instead
const R0 := 14.0                   # a fresh puff's radius (px)
const R_MAX := 90.0                # how big one puff of a cloud can get (px)
const THICK_MAX := 0.9             # how solid the middle of a cloud can get
const HALF_LIFE := 7.0             # a puff nobody's feeding loses half its thickness this often (s)
const LINGER := 2.5                # ...after it's been left alone this long (s)
const SPREAD := 1.5                # how much more smoke a full puff takes before the cloud grows past it

static var current: SmokeField     # the scene's cloud, for whoever's spinning tires in it

var wind := Vector2.ZERO           # px/s the air is moving
var on := true
var puffs: Array[Puff] = []

class Puff:
	var pos: Vector2
	var vel: Vector2
	var r := R0
	var thick := 0.0               # 0..THICK_MAX
	var idle := 0.0                # seconds since it was last fed
	var over := 0.0                # smoke it couldn't hold, toward spreading out a new puff
	var col := Color(0.86, 0.86, 0.89)

static var _tex: ImageTexture

func _ready() -> void:
	current = self
	z_index = 2600                 # over the cars: a thick cloud swallows them
	z_as_relative = false
	if _tex == null: _tex = _soft_tex()

func _exit_tree() -> void:
	if current == self: current = null

## Smoke off a tire at `at` (world px): `amount` is how much this frame (about 1 a second for a
## tire spinning flat out), thrown out at `vel` px/s.
func add(at: Vector2, amount: float, vel := Vector2.ZERO, col := Color(0.86, 0.86, 0.89)) -> void:
	if not on or amount <= 0.0: return
	var best: Puff = null
	var best_d := INF
	for p in puffs:
		var d := p.pos.distance_to(at)
		if d < p.r * MERGE and d < best_d:
			best = p
			best_d = d
	if best != null and not (best.r >= R_MAX and best.thick >= THICK_MAX - 0.01):
		# feeding a cloud: thicker first, then bigger once it's as thick as smoke gets
		var room := THICK_MAX - best.thick
		best.thick = minf(THICK_MAX, best.thick + amount * 0.3)
		var spill := maxf(0.0, amount * 0.3 - room)
		best.r = minf(R_MAX, best.r + amount * 7.0 + spill * 18.0)
		best.idle = 0.0
		best.vel = best.vel.lerp(vel, 0.05)
		best.col = best.col.lerp(col, 0.1)
		return
	if best != null:
		# that one's as big and thick as a puff gets: what it can't hold builds up, and every so
		# often the cloud spreads out a puff's width round it
		best.idle = 0.0
		best.over += amount
		if best.over < SPREAD: return
		best.over = 0.0
		at = best.pos + Vector2.from_angle(randf() * TAU) * best.r * 0.8
		amount = 1.2
	if puffs.size() >= MAX_PUFFS:
		# the thinnest puff makes way
		var thin := 0
		for i in puffs.size():
			if puffs[i].thick < puffs[thin].thick: thin = i
		puffs.remove_at(thin)
	var np := Puff.new()
	np.pos = at
	np.vel = vel
	np.thick = minf(THICK_MAX, 0.04 + amount * 0.3)      # a new puff starts as a wisp
	np.col = col
	puffs.append(np)

## How thick the smoke is at a point (0..1): for the death screen's "you couldn't see" and tests.
func thickness_at(at: Vector2) -> float:
	var t := 0.0
	for p in puffs:
		var d := p.pos.distance_to(at)
		if d < p.r: t = maxf(t, p.thick * (1.0 - d / p.r))
	return t

func step(dt: float, rise: Vector2) -> void:
	if not on:
		if not puffs.is_empty():
			puffs.clear()
			queue_redraw()
		return
	var fade := pow(0.5, dt / HALF_LIFE)
	for i in range(puffs.size() - 1, -1, -1):
		var p := puffs[i]
		p.idle += dt
		p.vel = p.vel * pow(0.25, dt) + (wind + rise) * (1.0 - pow(0.25, dt))
		p.pos += p.vel * dt
		if p.idle > LINGER:
			p.thick *= fade
			p.r = minf(R_MAX * 1.3, p.r + dt * 3.0)      # it spreads out as it thins
		if p.thick < 0.02: puffs.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if _tex == null: return
	for p in puffs:
		var c := p.col
		c.a = p.thick
		# two layers: the body of the cloud and a softer, wider skirt round it
		draw_texture_rect(_tex, Rect2(p.pos - Vector2(p.r, p.r) * 1.35, Vector2(p.r, p.r) * 2.7), false, Color(c, c.a * 0.35))
		draw_texture_rect(_tex, Rect2(p.pos - Vector2(p.r, p.r), Vector2(p.r, p.r) * 2.0), false, c)

## A round puff, solid in the middle and feathering out, with a few lumps in its edge so a cloud
## of them isn't a pile of perfect circles. Pixel-sized steps (it's drawn big, nearest-filtered).
static func _soft_tex() -> ImageTexture:
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bumps := []
	for k in 7: bumps.append(rng.randf_range(0.85, 1.0))
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0)
			var ang := fposmod(d.angle(), TAU) / TAU * 7.0
			var edge := lerpf(bumps[int(ang) % 7], bumps[(int(ang) + 1) % 7], ang - floorf(ang)) * n / 2.0
			var t := d.length() / edge
			if t >= 1.0: continue
			var a := 1.0 - t * t
			a = snappedf(a, 0.2)                        # in steps, like the rest of the art
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
