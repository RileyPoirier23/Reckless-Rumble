## Draws a CarArt stack: every slice rotated to the car's heading and lifted 1 px per slice.
## The body leans with the car's accelerations (roll in corners, squat and dive), the front
## wheels (their own little stacks) turn with the steering, and the lights come on.
class_name CarView
extends Node2D

const STEP := 1.0                  # screen pixels between slices

var art: CarArt
var heading := 0.0
var steer := 0.0
var lean := Vector2.ZERO           # in the car's frame: x = pitch (+ = nose dips), y = roll (+ = leans right)
var braking := false
var reversing := false
var headlights := false
var wheel_turn := 0.0              # for the tread flicker
var blink_left := false            # the turn signal switch (the lamp pulses on its own)
var blink_right := false
var lift := 0.0                    # pixels the whole car sits up off its shadow (a hop)
var wheel_k := 1.0                 # how big the front wheels draw (old donk scaling; the art sizes its own wheels now)
var still := false                 # a parked car: only redrawn when the camera turns or it's on screen again

## Which way is "up" on the screen, in world space. The chase camera turns, so the stack
## has to rise toward the top of the screen, not toward north. Set once a frame by the scene.
static var screen_up := Vector2(0, -1)
## What the camera can see, in world px (centre, radius); set by the scene. Cars well off it
## don't redraw.
static var view_centre := Vector2.ZERO
static var view_radius := 0.0

## The flasher relay: about 85 flashes a minute, a little longer on than off.
static func blink_on() -> bool:
	return fmod(Time.get_ticks_msec() / 1000.0, 0.7) < 0.38

var _lamps: LampLayer
var _drawn_up := Vector2.ZERO
var _job: CarArt.Job              # a new look being drawn on a worker thread

## Draws the car's art on a worker thread; until it's done the old art (or nothing) shows.
func build(spec: Dictionary, paint: Color, damage = 0.0, seed := 1, scale := CarArt.CAR_SCALE, mods := {}) -> void:
	if _job != null: _job.take()
	_job = CarArt.build(spec, paint, damage, seed, scale, mods)

## True while the art is still being drawn.
func building() -> bool:
	return _job != null

func _exit_tree() -> void:
	if _job != null:
		_job.take()
		_job = null

func _notification(what: int) -> void:
	# freed without ever being in the tree: still wait for the worker
	if what == NOTIFICATION_PREDELETE and _job != null:
		_job.take()
		_job = null

func _ready() -> void:
	# the lamps glow: they're drawn unshaded, so the night doesn't darken them
	_lamps = LampLayer.new()
	_lamps.view = self
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_lamps.material = mat
	add_child(_lamps)

func _process(_dt: float) -> void:
	if _job != null and _job.done():
		art = _job.take()
		_job = null
		_drawn_up = Vector2.ZERO
	if view_radius > 0.0 and global_position.distance_to(view_centre) > view_radius + 120.0: return
	if still and _drawn_up == screen_up: return
	_drawn_up = screen_up
	queue_redraw()
	if _lamps: _lamps.queue_redraw()

## A stack drawn straight onto another canvas (the garage's preview): no lean, no lamps, the
## front wheels straight, the stack rising toward the top of the screen.
static func paint_stack(ci: CanvasItem, the_art: CarArt, at: Vector2, h: float) -> void:
	if the_art == null or the_art.atlas == null: return
	var sz := Vector2(the_art.size)
	var ws := Vector2(the_art.wheel_size)
	ci.draw_set_transform(at + Vector2(2, 2), h, Vector2.ONE)
	ci.draw_rect(Rect2(-Vector2(the_art.length_px, the_art.width_px) / 2.0, Vector2(the_art.length_px, the_art.width_px)), Color(0, 0, 0, 0.35))
	for z in the_art.n:
		var off := at + Vector2(0, -z * STEP)
		ci.draw_set_transform(off, h, Vector2.ONE)
		ci.draw_texture_rect_region(the_art.atlas, Rect2(-sz / 2.0, sz), Rect2(float(z) * sz.x, 0.0, sz.x, sz.y))
		if z < the_art.wheel_n:
			for spot: Vector2 in the_art.wheel_spots:
				ci.draw_set_transform(off + spot.rotated(h), h, Vector2(1.0, -1.0 if spot.y < 0.0 else 1.0))
				ci.draw_texture_rect_region(the_art.wheel_tex, Rect2(-ws / 2.0, ws), Rect2(float(z) * ws.x, 0.0, ws.x, ws.y))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## How high the roof stands, in screen pixels (for light bars and signs that sit on it).
func roof_px() -> float:
	return (art.roof_z if art else 12.0) * STEP + lift

func _draw() -> void:
	if art == null or art.atlas == null: return
	var sz := Vector2(art.size)
	var half := sz / 2.0
	var fwd := Vector2(cos(heading), sin(heading))
	var rt := Vector2(-sin(heading), cos(heading))
	var bl := blink_left and blink_on()
	var br := blink_right and blink_on()
	var n := art.n
	# ground shadow
	draw_set_transform(-screen_up * 2.0 + screen_up.orthogonal() * 2.0, heading, Vector2.ONE)
	draw_rect(Rect2(-Vector2(art.length_px, art.width_px) / 2.0 + Vector2(1, 1), Vector2(art.length_px, art.width_px) - Vector2(2, 2)), Color(0, 0, 0, 0.35))
	for z in n:
		# only the body leans; the tires stay planted
		var body_k := maxf(0.0, (float(z) - 1.5) / float(maxi(1, n - 1)))
		var off := screen_up * (z * STEP + lift) + (fwd * lean.x + rt * lean.y) * body_k
		draw_set_transform(off, heading, Vector2.ONE)
		draw_texture_rect_region(art.atlas, Rect2(-half, sz), Rect2(float(z) * sz.x, 0.0, sz.x, sz.y))
		if _lamps == null: _lamp_slice(self, z, off, half, bl, br)
		# the front wheels: drawn on their own so they can steer
		if z < art.wheel_n:
			_front_wheels(screen_up * (z * STEP + lift), z)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The lit lamps on one slice: the tails glow with the headlights on and brighten when braking.
func _lamp_slice(ci: CanvasItem, z: int, off: Vector2, half: Vector2, bl: bool, br: bool) -> void:
	var lz := z - art.lamp_z0
	if lz < 0 or lz >= art.lamp_n or art.lamp_tex.is_empty(): return
	ci.draw_set_transform(off, heading, Vector2.ONE)
	var sz := Vector2(art.size)
	var dst := Rect2(-half, sz)
	var src := Rect2(float(lz) * sz.x, 0.0, sz.x, sz.y)
	if braking: ci.draw_texture_rect_region(art.lamp_tex.brake, dst, src)
	elif headlights: ci.draw_texture_rect_region(art.lamp_tex.brake, dst, src, Color(0.6, 0.6, 0.6))
	if reversing: ci.draw_texture_rect_region(art.lamp_tex.rev, dst, src)
	if headlights: ci.draw_texture_rect_region(art.lamp_tex.head, dst, src)
	if bl: ci.draw_texture_rect_region(art.lamp_tex.bl, dst, src)
	if br: ci.draw_texture_rect_region(art.lamp_tex.br, dst, src)

## The lamps, on their own unshaded layer over the body.
class LampLayer extends Node2D:
	var view: CarView
	func _draw() -> void:
		if view == null or view.art == null or view.art.lamp_tex.is_empty(): return
		if not (view.braking or view.reversing or view.headlights or view.blink_left or view.blink_right): return
		var half := Vector2(view.art.size) / 2.0
		var fwd := Vector2(cos(view.heading), sin(view.heading))
		var rt := Vector2(-sin(view.heading), cos(view.heading))
		var bl := view.blink_left and CarView.blink_on()
		var br := view.blink_right and CarView.blink_on()
		var n := view.art.n
		for z in range(view.art.lamp_z0, view.art.lamp_z0 + view.art.lamp_n):
			var body_k := maxf(0.0, (float(z) - 1.5) / float(maxi(1, n - 1)))
			var off := CarView.screen_up * (z * CarView.STEP + view.lift) + (fwd * view.lean.x + rt * view.lean.y) * body_k
			view._lamp_slice(self, z, off, half, bl, br)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _front_wheels(off: Vector2, z: int) -> void:
	var ws := Vector2(art.wheel_size)
	var src := Rect2(float(z) * ws.x, 0.0, ws.x, ws.y)
	for i in art.wheel_spots.size():
		var spot: Vector2 = art.wheel_spots[i]
		var centre := spot.rotated(heading) + off
		# the rim's face is on the wheel's +y side: the left wheel is drawn mirrored
		var flip := -1.0 if spot.y < 0.0 else 1.0
		draw_set_transform(centre, heading + steer, Vector2(wheel_k, flip))
		draw_texture_rect_region(art.wheel_tex, Rect2(-ws / 2.0, ws), src)
		# tread flicker so you can see the wheel turn
		if z == art.wheel_n - 1:
			var f := int(absf(wheel_turn) * 3.0) % 3
			draw_rect(Rect2(-ws.x / 2.0 + float(f) * ws.x / 3.0, -ws.y / 2.0, 1.0, ws.y), Color(1, 1, 1, 0.12))
