## Draws a CarArt stack: every slice rotated to the car's heading and lifted 1 px per slice.
## The body leans with the car's accelerations (roll in corners, squat and dive), the front
## wheels (their own little stacks) turn with the steering, and the lights come on.
class_name CarView
extends Node2D

const STEP := 1.0                  # screen pixels between slices

var art: CarArt
var heading := 0.0
var steer := 0.0
var _steer_vis := 0.0              # the wheels' drawn angle: follows steer, but can't snap
const STEER_RATE := 5.0            # rad/s the drawn wheels can turn
var lean := Vector2.ZERO           # in the car's frame: x = pitch (+ = nose dips), y = roll (+ = leans right)
var braking := false
var reversing := false
var headlights := false
var high_beams := false            # brights on: an off-road LED roof bar lights with them
var wheel_turn := 0.0              # for the tread flicker
var blink_left := false            # the turn signal switch (the lamp pulses on its own)
var blink_right := false
var beacons := false               # an emergency rig running code (or the wrecker's bar switched on): its roof lights flash
var lift := 0.0                    # pixels the whole car sits up off its shadow (a hop)
var wheel_k := 1.0                 # how big the front wheels draw (old donk scaling; the art sizes its own wheels now)
var still := false                 # a parked car: only redrawn when the camera turns or it's on screen again
var light_bar := false             # an amber light bar across the cab roof (the wrecker)

## Which way is "up" on the screen, in world space. The chase camera turns, so the stack
## has to rise toward the top of the screen, not toward north. Set once a frame by the scene.
static var screen_up := Vector2(0, -1)
## How far the camera's tipped down from straight overhead: everything that stands up (car
## slices, walls, poles) is drawn this much taller, while the camera squashes the ground (SQUASH).
static var lift_k := 1.0
## Settings > UI > CAMERA ANGLE: [ground squash, height lift] for each.
const ANGLES := { "overhead": [1.0, 1.0], "angled": [0.82, 1.45], "low": [0.68, 1.9] }
static var squash := 1.0

static func set_angle(name: String) -> void:
	var a: Array = ANGLES.get(name, ANGLES.angled)
	squash = float(a[0])
	lift_k = float(a[1])
## What the camera can see, in world px (centre, radius); set by the scene. Cars well off it
## don't redraw.
static var view_centre := Vector2.ZERO
static var view_radius := 0.0

## How dark it is out, 0 broad day .. 1 the dead of night: the scene sets it from the sky. Lit
## lamps glow with it (and an underglow lights the road under the car).
static var night := 0.0

## A lamp's glow: a few hard-edged rings, brightest in the middle, so it stays pixel art.
static var _glow_tex: ImageTexture
static func glow_tex() -> ImageTexture:
	if _glow_tex == null:
		var n := 17
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x - n / 2, y - n / 2).length()
				# bright at the lamp and falling away fast, in fine steps (so it reads as light, not a disc)
				var a := snappedf(0.62 * pow(clampf(1.0 - d / 8.2, 0.0, 1.0), 2.2), 0.04)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex

## The beacons' flash: on a little under half the time, three times a second.
static func beacon_on() -> bool:
	return fmod(Time.get_ticks_msec() / 1000.0, 0.34) < 0.17

## The flasher relay: about 85 flashes a minute, a little longer on than off.
static func blink_on() -> bool:
	return fmod(Time.get_ticks_msec() / 1000.0, 0.7) < 0.38

var _lamps: LampLayer
var _glows: GlowLayer
var _under: GlowLayer
var _drawn_up := Vector2.ZERO
var _drawn_k := 1.0
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
	# lit by the streetlights (mask 2) but never by a car's own lamps (those light the road, mask 1):
	# a tail lamp's red pool used to wash over the car's own roof
	light_mask = 2
	# the lamps glow: they're drawn unshaded, so the night doesn't darken them
	_lamps = LampLayer.new()
	_lamps.view = self
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_lamps.material = mat
	add_child(_lamps)
	# the glows add light: round the lit lamps over the car, and the underglow on the road under it
	var add := CanvasItemMaterial.new()
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glows = GlowLayer.new()
	_glows.view = self
	_glows.material = add
	add_child(_glows)
	_under = GlowLayer.new()
	_under.view = self
	_under.under = true
	_under.material = add
	_under.show_behind_parent = true
	add_child(_under)

func _process(dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_process_timed(dt)
	Prof.lap('car_view_proc', _t0)

func _process_timed(dt: float) -> void:
	_steer_vis = move_toward(_steer_vis, clampf(steer, -0.7, 0.7), STEER_RATE * dt)
	if _job != null and _job.done():
		art = _job.take()
		_job = null
		_drawn_up = Vector2.ZERO
	if view_radius > 0.0 and global_position.distance_to(view_centre) > view_radius + 120.0: return
	if still and _drawn_up == screen_up and _drawn_k == lift_k: return
	_drawn_up = screen_up
	_drawn_k = lift_k
	queue_redraw()
	if _lamps: _lamps.queue_redraw()
	if _glows: _glows.queue_redraw()
	if _under: _under.queue_redraw()

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
	return (art.roof_z if art else 12.0) * STEP * lift_k + lift

## Where slice z of the car stands on the screen, up from its shadow (px).
func slice_px(z: float) -> float:
	return z * STEP * lift_k + lift

func _draw() -> void:
	var _t0 := Time.get_ticks_usec()
	_draw_timed()
	Prof.lap('draw_car', _t0)

func _draw_timed() -> void:
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
		var off := screen_up * (z * STEP * lift_k + lift) + (fwd * lean.x + rt * lean.y) * body_k
		draw_set_transform(off, heading, Vector2.ONE)
		draw_texture_rect_region(art.atlas, Rect2(-half, sz), Rect2(float(z) * sz.x, 0.0, sz.x, sz.y))
		# tipped down, the slices spread apart: a second copy halfway up fills the gap
		if lift_k > 1.05 and z < n - 1:
			draw_set_transform(off + screen_up * STEP * lift_k * 0.5, heading, Vector2.ONE)
			draw_texture_rect_region(art.atlas, Rect2(-half, sz), Rect2(float(z) * sz.x, 0.0, sz.x, sz.y))
		if _lamps == null: _lamp_slice(self, z, off, half, bl, br)
		# the back wheels are in the stack: their tread rolls over the top slice
		if z == art.wheel_n - 1:
			for rw: Array in art.wheel_rears:
				draw_set_transform((rw[0] as Vector2).rotated(heading) + screen_up * (z * STEP * lift_k + lift), heading, Vector2.ONE)
				_tread(rw[1])
		# the front wheels: drawn on their own so they can steer
		if z < art.wheel_n:
			_front_wheels(screen_up * (z * STEP * lift_k + lift), z)
			if lift_k > 1.05 and z < art.wheel_n - 1: _front_wheels(screen_up * ((z + 0.5) * STEP * lift_k + lift), z)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Which ends of the car face the camera: [the back, the front]. The lit lamps are drawn over
## the whole stack (unshaded, so the night doesn't dim them), so the lamps on an end turned away
## from the camera are left out, or a car driving down the screen would show its tail lamps
## through its own trunk lid.
func ends_seen() -> Array:
	var away := Vector2(cos(heading), sin(heading)).dot(screen_up)    # + the nose points up the screen
	return [away > -0.3, away < 0.3]

## The lit lamps on one slice: the tails glow with the headlights on and brighten when braking.
## Only the halves of the car whose end faces the camera (see ends_seen); the roof's lamps always.
func _lamp_slice(ci: CanvasItem, z: int, off: Vector2, half: Vector2, bl: bool, br: bool, ends := [true, true]) -> void:
	var lz := z - art.lamp_z0
	if lz < 0 or lz >= art.lamp_n or art.lamp_tex.is_empty(): return
	ci.draw_set_transform(off, heading, Vector2.ONE)
	var sz := Vector2(art.size)
	var dst := Rect2(-half, sz)
	var src := Rect2(float(lz) * sz.x, 0.0, sz.x, sz.y)
	if beacons and art.has_beacons and beacon_on():
		ci.draw_texture_rect_region(art.lamp_tex.beacon, dst, src)
	if high_beams and art.lamp_tex.has("bar"): ci.draw_texture_rect_region(art.lamp_tex.bar, dst, src)
	for e in 2:
		if not ends[e]: continue
		# the back half (e 0) or the front half (e 1) of the slice
		var d2 := Rect2(dst.position + Vector2(sz.x * 0.5 * e, 0.0), Vector2(sz.x * 0.5, sz.y))
		var s2 := Rect2(src.position + Vector2(sz.x * 0.5 * e, 0.0), Vector2(sz.x * 0.5, sz.y))
		if braking: ci.draw_texture_rect_region(art.lamp_tex.brake, d2, s2)
		elif headlights: ci.draw_texture_rect_region(art.lamp_tex.brake, d2, s2, Color(0.6, 0.6, 0.6))
		if reversing: ci.draw_texture_rect_region(art.lamp_tex.rev, d2, s2)
		if headlights: ci.draw_texture_rect_region(art.lamp_tex.head, d2, s2)
		if bl: ci.draw_texture_rect_region(art.lamp_tex.bl, d2, s2)
		if br: ci.draw_texture_rect_region(art.lamp_tex.br, d2, s2)

## The lamps, on their own unshaded layer over the body.
class LampLayer extends Node2D:
	var view: CarView
	func _draw() -> void:
		var _t0 := Time.get_ticks_usec()
		_draw_timed()
		Prof.lap('draw_car_lamps', _t0)

	func _draw_timed() -> void:
		if view == null or view.art == null or view.art.lamp_tex.is_empty(): return
		if not (view.braking or view.reversing or view.headlights or view.blink_left or view.blink_right or view.beacons or view.high_beams or view.light_bar): return
		var half := Vector2(view.art.size) / 2.0
		var fwd := Vector2(cos(view.heading), sin(view.heading))
		var rt := Vector2(-sin(view.heading), cos(view.heading))
		var bl := view.blink_left and CarView.blink_on()
		var br := view.blink_right and CarView.blink_on()
		var n := view.art.n
		var ends := view.ends_seen()
		for z in range(view.art.lamp_z0, view.art.lamp_z0 + view.art.lamp_n):
			var body_k := maxf(0.0, (float(z) - 1.5) / float(maxi(1, n - 1)))
			var off := CarView.screen_up * (z * CarView.STEP * CarView.lift_k + view.lift) + (fwd * view.lean.x + rt * view.lean.y) * body_k
			view._lamp_slice(self, z, off, half, bl, br, ends)
		if view.light_bar: _light_bar(half, fwd, rt)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## The wrecker's roof bar: two amber lamps on the cab, flashing turn about when it's on. It
	## stands on the cab's roof just behind the windshield, as wide as the roof is there.
	func _light_bar(half: Vector2, fwd: Vector2, rt: Vector2) -> void:
		var spot: Vector3 = view.art.roof_front
		var off := CarView.screen_up * (view.slice_px(spot.z) + 1.0) + (fwd * view.lean.x + rt * view.lean.y)
		draw_set_transform(off, view.heading, Vector2.ONE)
		var k: float = view.art.k
		var x := spot.x - 1.5 * k
		var w := minf(view.art.roof_w, view.art.width_px * 0.86)
		draw_rect(Rect2(x - 1.5 * k, -w / 2.0, 3.0 * k, w), Color("2a2a2e"))
		var phase := int(Time.get_ticks_msec() / 160) % 4
		for side: float in [-1.0, 1.0]:
			var lit: bool = view.beacons and (phase < 2) == (side < 0.0)
			var r := Rect2(x - 1.0 * k, (-w / 2.0 + 0.5 * k) if side < 0.0 else (w / 2.0 - w * 0.42), 2.0 * k, w * 0.42 - 0.5 * k)
			draw_rect(r, Color("ffb020") if lit else Color("6a4a14"))
			if lit: draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1.0), Color("ffe6a0"))
		# the bar's lens, white in the middle
		draw_rect(Rect2(x - 0.5 * k, -1.0 * k, k, 2.0 * k), Color("e8e4dc"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The glows: round every lit lamp at night (a pixel-stepped halo in the lamp's colour, at the
## lamp's own height on the stack, so it never floats off the body), the wrecker's amber bar's,
## and under the car its underglow, washing the road in its colour.
class GlowLayer extends Node2D:
	var view: CarView
	var under := false

	func _draw() -> void:
		var _t0 := Time.get_ticks_usec()
		_draw_timed()
		Prof.lap('draw_car_glows', _t0)

	func _draw_timed() -> void:
		if view == null or view.art == null: return
		var art: CarArt = view.art
		var fwd := Vector2(cos(view.heading), sin(view.heading))
		var rt := Vector2(-fwd.y, fwd.x)
		var dark := CarView.night
		if under:
			if art.underglow.a <= 0.0: return
			# a pool of light just past the car's outline, in steps, brighter at night
			var a := 0.14 + 0.55 * dark
			draw_set_transform(CarView.screen_up * view.lift, view.heading, Vector2.ONE)
			var hl := Vector2(art.length_px * 0.43, art.width_px * 0.5)
			for k in 3:
				var g := float(k + 1) * 2.0 * art.k
				draw_rect(Rect2(-hl - Vector2(g * 0.6, g), hl * 2.0 + Vector2(g * 1.2, g * 2.0)), Color(art.underglow, a * [0.5, 0.3, 0.16][k]))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		var bl := view.blink_left and CarView.blink_on()
		var br := view.blink_right and CarView.blink_on()
		var tex := CarView.glow_tex()
		var n := art.n
		var ends := view.ends_seen()
		for sp: Array in art.lamp_spots:
			var kind: int = sp[0]
			# (a lamp on an end turned away from the camera is behind the car: no glow over it)
			if kind <= 4 and not ends[1 if (sp[1] as Vector3).x > 0.0 else 0]: continue
			var strength := 0.0
			var c: Color = sp[2]
			match kind:
				0:
					if view.braking: strength = 0.55 + 0.45 * dark
					elif view.headlights: strength = 0.45 * dark
					c = Color(1.0, 0.16, 0.1)
				1: if view.reversing: strength = 0.25 + 0.6 * dark
				2:
					if view.headlights: strength = 0.9 * dark
					c = c.lerp(Color(1.0, 0.95, 0.82), 0.6)
				3: if bl: strength = 0.35 + 0.5 * dark
				4: if br: strength = 0.35 + 0.5 * dark
				5: if view.beacons and CarView.beacon_on(): strength = 0.5 + 0.5 * dark
				6: if view.high_beams: strength = 0.95 * dark + 0.1
			if strength <= 0.02: continue
			var at: Vector3 = sp[1]
			var body_k := maxf(0.0, (at.z - 1.5) / float(maxi(1, n - 1)))
			var pos := fwd * at.x + rt * at.y + CarView.screen_up * view.slice_px(at.z) + (fwd * view.lean.x + rt * view.lean.y) * body_k
			var r := art.k * (2.6 + minf(3.0, sqrt(float(sp[3])) * 0.45))
			if kind == 2 or kind == 6: r *= 1.3
			draw_texture_rect(tex, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(c, strength))
		if view.light_bar and view.beacons:
			# the wrecker's amber bar, flashing side to side
			var spot: Vector3 = art.roof_front
			var w := minf(art.roof_w, art.width_px * 0.86)
			var phase := int(Time.get_ticks_msec() / 160) % 4
			var side := -1.0 if phase < 2 else 1.0
			var pos2 := fwd * (spot.x - 1.5 * art.k) + rt * side * w * 0.28 + CarView.screen_up * (view.slice_px(spot.z) + 1.0)
			var r2 := art.k * 6.0
			draw_texture_rect(tex, Rect2(pos2 - Vector2(r2, r2), Vector2(r2, r2) * 2.0), false, Color(1.0, 0.62, 0.12, 0.45 + 0.45 * dark))

func _front_wheels(off: Vector2, z: int) -> void:
	var ws := Vector2(art.wheel_size)
	var src := Rect2(float(z) * ws.x, 0.0, ws.x, ws.y)
	for i in art.wheel_spots.size():
		var spot: Vector2 = art.wheel_spots[i]
		var centre := spot.rotated(heading) + off
		# the rim's face is on the wheel's +y side: the left wheel is drawn mirrored
		var flip := -1.0 if spot.y < 0.0 else 1.0
		# a turned wheel seen from above: its face narrows (cos) and swings out a little (sin), but
		# never turns in the screen's plane, or the spokes would wheel round like it was spinning
		var fwd := Vector2.from_angle(heading)
		var rt := Vector2(-fwd.y, fwd.x)
		# (pointing up or down the screen the face is edge-on, so there it can turn all the way)
		var swing := absf(fwd.dot(screen_up))
		var xa := (fwd * cos(_steer_vis) + rt * sin(_steer_vis) * swing) * wheel_k
		var ya := (rt * lerpf(1.0, cos(_steer_vis), swing) - fwd * sin(_steer_vis) * swing) * flip
		draw_set_transform_matrix(Transform2D(xa, ya, centre))
		draw_texture_rect_region(art.wheel_tex, Rect2(-ws / 2.0, ws), src)
		if z == art.wheel_n - 1: _tread(ws)

## The tread rolling with the wheel: dark blocks spaced round the tyre, drawn where they'd show
## from above (quick over the top, bunched at the front and back edges), so a moving wheel turns.
func _tread(size: Vector2) -> void:
	var r := size.x * 0.5
	for i in 4:
		var ph := wheel_turn + float(i) * TAU / 4.0
		var c := cos(ph)
		if c < 0.12: continue
		var x := sin(ph) * (r - 0.6)
		draw_rect(Rect2(x - 0.5, -size.y / 2.0 + 0.5, 1.0, size.y - 1.0), Color(0.04, 0.04, 0.06, 0.42 * c))
