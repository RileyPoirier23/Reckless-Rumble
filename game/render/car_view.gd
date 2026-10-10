## Draws a CarArt stack: every slice rotated to the car's heading and lifted 1 px per slice.
## The body leans with the car's accelerations (roll in corners, squat and dive), the front
## wheels turn with the steering, and the lights come on.
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
var lift := 0.0                    # pixels the whole car sits up off its shadow (a donk; a hop)
var wheel_k := 1.0                 # how big the front wheels draw (big rims)
var light_bar := false             # an amber light bar across the cab roof (the wrecker)
var beacons := false               # ...and it's switched on

## Which way is "up" on the screen, in world space. The chase camera turns, so the stack
## has to rise toward the top of the screen, not toward north. Set once a frame by the scene.
static var screen_up := Vector2(0, -1)

## The flasher relay: about 85 flashes a minute, a little longer on than off.
static func blink_on() -> bool:
	return fmod(Time.get_ticks_msec() / 1000.0, 0.7) < 0.38

var _lamps: LampLayer

func _ready() -> void:
	# the lamps glow: they're drawn unshaded, so the night doesn't darken them
	_lamps = LampLayer.new()
	_lamps.view = self
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_lamps.material = mat
	add_child(_lamps)

func _process(_dt: float) -> void:
	queue_redraw()
	if _lamps: _lamps.queue_redraw()

func _draw() -> void:
	if art == null: return
	var half := Vector2(art.size) / 2.0
	var fwd := Vector2(cos(heading), sin(heading))
	var rt := Vector2(-sin(heading), cos(heading))
	var bl := blink_left and blink_on()
	var br := blink_right and blink_on()
	# ground shadow
	draw_set_transform(-screen_up * 2.0 + screen_up.orthogonal() * 2.0, heading, Vector2.ONE)
	draw_rect(Rect2(-half + Vector2(2, 2), Vector2(art.size) - Vector2(4, 4)), Color(0, 0, 0, 0.35))
	for z in CarArt.SLICES:
		# only the body leans; the tires stay planted
		var body_k := maxf(0.0, (float(z) - 1.5) / float(CarArt.SLICES - 1))
		var off := screen_up * (z * STEP + lift) + (fwd * lean.x + rt * lean.y) * body_k
		draw_set_transform(off, heading, Vector2.ONE)
		draw_texture(art.slices[z], -half)
		if _lamps == null: _lamp_slice(self, z, off, half, bl, br)
		# the front wheels: drawn on their own so they can steer
		if z <= 2:
			_front_wheels(off, z)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The lit lamps on one slice: the tails glow with the headlights on and brighten when braking.
func _lamp_slice(ci: CanvasItem, z: int, off: Vector2, half: Vector2, bl: bool, br: bool) -> void:
	ci.draw_set_transform(off, heading, Vector2.ONE)
	if art.brake_lights[z] != null:
		if braking: ci.draw_texture(art.brake_lights[z], -half)
		elif headlights: ci.draw_texture(art.brake_lights[z], -half, Color(0.6, 0.6, 0.6))
	if reversing: ci.draw_texture(art.reverse_lights[z], -half)
	if headlights: ci.draw_texture(art.head_lights[z], -half)
	if bl: ci.draw_texture(art.blink_left[z], -half)
	if br: ci.draw_texture(art.blink_right[z], -half)

## The lamps, on their own unshaded layer over the body.
class LampLayer extends Node2D:
	var view: CarView
	func _draw() -> void:
		if view == null or view.art == null: return
		var half := Vector2(view.art.size) / 2.0
		var fwd := Vector2(cos(view.heading), sin(view.heading))
		var rt := Vector2(-sin(view.heading), cos(view.heading))
		var bl := view.blink_left and CarView.blink_on()
		var br := view.blink_right and CarView.blink_on()
		# the lamps sit on slices 6 and 7 (the 4th and 5th layers of the recipe)
		for z in range(5, 9):
			var body_k := maxf(0.0, (float(z) - 1.5) / float(CarArt.SLICES - 1))
			var off := CarView.screen_up * (z * CarView.STEP + view.lift) + (fwd * view.lean.x + rt * view.lean.y) * body_k
			view._lamp_slice(self, z, off, half, bl, br)
		if view.light_bar: _light_bar(half, fwd, rt)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## The wrecker's roof bar: two amber lamps on the cab, flashing turn about when it's on.
	func _light_bar(half: Vector2, fwd: Vector2, rt: Vector2) -> void:
		var z := CarArt.SLICES - 1
		var off := CarView.screen_up * (z * CarView.STEP + view.lift + 1.0) + (fwd * view.lean.x + rt * view.lean.y)
		draw_set_transform(off, view.heading, Vector2.ONE)
		var k: float = view.art.k
		var x := half.x * 0.22                     # over the cab, a little ahead of the middle
		var w := view.art.width_px * 0.78
		draw_rect(Rect2(x - 1.5 * k, -w / 2.0, 3.0 * k, w), Color("2a2a2e"))
		var phase := int(Time.get_ticks_msec() / 160) % 4
		for side: float in [-1.0, 1.0]:
			var lit: bool = view.beacons and (phase < 2) == (side < 0.0)
			var r := Rect2(x - 1.0 * k, (-w / 2.0 + 0.5 * k) if side < 0.0 else (w / 2.0 - w * 0.42), 2.0 * k, w * 0.42 - 0.5 * k)
			draw_rect(r, Color("ffb020") if lit else Color("6a4a14"))
			if lit:
				draw_circle(r.get_center(), 9.0 * k, Color(1.0, 0.65, 0.1, 0.16))
				draw_circle(r.get_center(), 4.0 * k, Color(1.0, 0.75, 0.2, 0.22))
		# the bar's lens, white in the middle
		draw_rect(Rect2(x - 0.5 * k, -1.0 * k, k, 2.0 * k), Color("e8e4dc"))

func _front_wheels(off: Vector2, z: int) -> void:
	var wf := art.wheelbase_px / 2.0
	var hw := art.width_px / 2.0
	for side in [-1.0, 1.0]:
		var centre := Vector2(wf, side * (hw - 1.0 * art.k)).rotated(heading) + off
		draw_set_transform(centre, heading + steer, Vector2(wheel_k, 1.0))
		var k := art.k
		draw_rect(Rect2(-3 * k, -1.5 * k, 6 * k, 3 * k), CarArt.TIRE)
		if z >= 1:
			draw_rect(Rect2(-1 * k, -1.5 * k, 2 * k, 3 * k), CarArt.RIM * 0.75)
			# tread flicker so you can see the wheel turn
			var f := int(absf(wheel_turn) * 3.0) % 3
			draw_rect(Rect2((-3 + f * 2) * k, -1.5 * k, k, 3 * k), CarArt.TIRE * 1.6)
