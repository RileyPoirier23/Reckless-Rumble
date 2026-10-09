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

## Which way is "up" on the screen, in world space. The chase camera turns, so the stack
## has to rise toward the top of the screen, not toward north. Set once a frame by the scene.
static var screen_up := Vector2(0, -1)

## The flasher relay: about 85 flashes a minute, a little longer on than off.
static func blink_on() -> bool:
	return fmod(Time.get_ticks_msec() / 1000.0, 0.7) < 0.38

func _process(_dt: float) -> void:
	queue_redraw()

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
		var off := screen_up * (z * STEP) + (fwd * lean.x + rt * lean.y) * body_k
		draw_set_transform(off, heading, Vector2.ONE)
		draw_texture(art.slices[z], -half)
		if braking and art.brake_lights[z] != null: draw_texture(art.brake_lights[z], -half)
		if reversing: draw_texture(art.reverse_lights[z], -half)
		if headlights: draw_texture(art.head_lights[z], -half)
		if bl: draw_texture(art.blink_left[z], -half)
		if br: draw_texture(art.blink_right[z], -half)
		# the front wheels: drawn on their own so they can steer
		if z <= 2:
			_front_wheels(off, z)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _front_wheels(off: Vector2, z: int) -> void:
	var wf := art.wheelbase_px / 2.0
	var hw := art.width_px / 2.0
	for side in [-1.0, 1.0]:
		var centre := Vector2(wf, side * (hw - 1.0 * CarArt.K)).rotated(heading) + off
		draw_set_transform(centre, heading + steer, Vector2.ONE)
		var k := CarArt.K
		draw_rect(Rect2(-3 * k, -1.5 * k, 6 * k, 3 * k), CarArt.TIRE)
		if z >= 1:
			draw_rect(Rect2(-1 * k, -1.5 * k, 2 * k, 3 * k), CarArt.RIM * 0.75)
			# tread flicker so you can see the wheel turn
			var f := int(absf(wheel_turn) * 3.0) % 3
			draw_rect(Rect2((-3 + f * 2) * k, -1.5 * k, k, 3 * k), CarArt.TIRE * 1.6)
