## Bits that come off in a crash: a bumper skidding down the road, glass, a hubcap.
## They slide, spin, scrape to a stop and stay there until you're long gone.
class_name Debris
extends Node2D

const PX := CarArt.PX

var vel := Vector2.ZERO        # m/s
var spin := 0.0
var kind := "bumper"           # bumper, glass, hubcap
var size_m := Vector2(1.7, 0.35)
var col := Color.WHITE
var life := 90.0

static func spawn(parent: Node, at_m: Vector2, heading: float, v: Vector2, what: String, paint: Color, width_m := 1.7) -> void:
	var d := Debris.new()
	d.kind = what
	d.col = paint
	d.position = at_m * PX
	d.rotation = heading + PI / 2.0
	d.vel = v
	d.spin = randf_range(-6.0, 6.0)
	d.size_m = Vector2(width_m * 0.95, 0.35) if what == "bumper" else Vector2(0.45, 0.45)
	d.z_index = 1
	parent.add_child(d)
	if what != "glass":
		# and a shower of glass with it
		var g := CPUParticles2D.new()
		g.position = d.position
		g.one_shot = true
		g.amount = 24
		g.lifetime = 0.6
		g.explosiveness = 1.0
		g.spread = 180.0
		g.initial_velocity_min = 30.0
		g.initial_velocity_max = 110.0
		g.damping_min = 120.0
		g.damping_max = 200.0
		g.gravity = Vector2.ZERO
		g.scale_amount_min = 1.0
		g.scale_amount_max = 2.0
		g.color = Color(0.8, 0.88, 0.95, 0.9)
		g.z_index = 2600
		g.z_as_relative = false
		g.emitting = true
		parent.add_child(g)
		g.finished.connect(g.queue_free)

func _process(dt: float) -> void:
	position += vel * dt * PX
	rotation += spin * dt
	vel = vel.move_toward(Vector2.ZERO, 7.0 * dt)     # scraping along the asphalt
	spin = move_toward(spin, 0.0, 9.0 * dt)
	life -= dt
	if life <= 0.0: queue_free()
	queue_redraw()

func _draw() -> void:
	var sz := size_m * PX
	match kind:
		"bumper":
			draw_rect(Rect2(-sz / 2.0 + Vector2(1, 1), sz), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(-sz / 2.0, sz), Color("1d1b20").lerp(col, 0.5))
			draw_rect(Rect2(-sz / 2.0, Vector2(sz.x, 1)), col.lightened(0.2))
			draw_rect(Rect2(Vector2(-sz.x * 0.15, -sz.y / 2.0), Vector2(sz.x * 0.3, sz.y)), Color("d8d4c0") * 0.8)   # the plate's still on it
		"hubcap":
			draw_circle(Vector2.ZERO, sz.x * 0.5, Color("a8acb0"))
			draw_circle(Vector2.ZERO, sz.x * 0.2, Color("6a6e72"))
		_:
			draw_rect(Rect2(-sz / 4.0, sz / 2.0), Color(0.8, 0.88, 0.95, 0.8))
