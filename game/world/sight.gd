## What Leo can see from the driver's seat, Project Zomboid style. Every building near the car
## throws a shadow away from it: the ground in a building's shadow is darker, and anybody driving
## in there (traffic, the police, a racer) fades out until they come round the corner. Buildings
## stay solid: when one stands between the camera and your car, the car's outline shows over it
## (Ghost), so it's never lost and the house never turns to glass.
## Settings > Graphics > LINE OF SIGHT turns it off.
class_name Sight
extends CanvasGroup

const SHADE := 0.5                 # how dark a shadow is
const REACH := 2400.0              # how far a shadow runs out past its building (px)
const FADE_S := 0.18               # how quickly things fade in and out (s)

var drive: Node
var on := true
var shadows: Array[PackedVector2Array] = []    # this frame's shadow polygons, world px
var _draw_node: Node2D
var ghost: Ghost

func _ready() -> void:
	z_index = -3990                 # over the ground, the roads and the skid marks, under everything that stands up
	z_as_relative = false
	self_modulate = Color(1, 1, 1, SHADE)
	_draw_node = Polys.new()
	_draw_node.sight = self
	add_child(_draw_node)

## A building's shadow from an eye: the footprint and everything behind it, out to `reach` past
## each corner. A rectangle's shadow is convex, so it's the hull of the corners and the corners run
## out away from the eye. [] if the eye's inside it.
static func shadow_of(corners: PackedVector2Array, eye: Vector2, reach: float) -> PackedVector2Array:
	if Geometry2D.is_point_in_polygon(eye, corners): return PackedVector2Array()
	var pts := corners.duplicate()
	for c in corners: pts.append(c + (c - eye).normalized() * reach)
	return Geometry2D.convex_hull(pts)

## Is this point (world px) in any of this frame's shadows?
func hidden(p: Vector2) -> bool:
	for s in shadows:
		if Geometry2D.is_point_in_polygon(p, s): return true
	return false

func update_sight(dt: float, eye: Vector2, view_r: float) -> void:
	shadows.clear()
	var k := minf(1.0, dt / FADE_S)
	var hidden_car := false
	var movers: Array[Node2D] = []
	for n in drive.ysort.get_children():
		if n is BuildingNode:
			var b := n as BuildingNode
			# a building off the screen can't cover the car, and its shadow falls away off the screen too
			if b.global_position.distance_to(eye) > view_r + b.reach(): continue
			if b.modulate.a != 1.0: b.modulate.a = 1.0
			if b.covers(eye): hidden_car = true
			if not on or not b.blocks_sight(): continue
			var s := shadow_of(b.world_corners(), eye, REACH)
			if s.size() >= 3: shadows.append(s)
		elif n == drive.car:
			continue
		elif n is TrafficCar or n is PlayerCar or n is Wildlife.Animal:
			movers.append(n)
	visible = on and not shadows.is_empty()
	_draw_node.queue_redraw()
	# the car behind a building: its outline over the roof
	if ghost == null:
		ghost = Ghost.new()
		drive.add_child(ghost)
	ghost.car = drive.car
	ghost.strength = lerpf(ghost.strength, 1.0 if hidden_car else 0.0, k)
	ghost.visible = ghost.strength > 0.02
	if ghost.visible: ghost.queue_redraw()
	# whoever's in a shadow fades out until they're in sight
	for o in movers:
		var target := 0.0 if on and hidden(o.global_position) else 1.0
		o.modulate.a = lerpf(o.modulate.a, target, k)

## Draws the shadows, solid; the group puts them on the ground at one strength, so two
## buildings' shadows that overlap aren't twice as dark.
class Polys extends Node2D:
	var sight: Sight
	func _draw() -> void:
		for s in sight.shadows: draw_colored_polygon(s, Color.BLACK)

## Your car seen through whatever's in the way: its outline and a faint fill, over the buildings.
class Ghost extends Node2D:
	var car: PlayerCar
	var strength := 0.0

	func _ready() -> void:
		z_index = 3200
		z_as_relative = false

	func _draw() -> void:
		if car == null or not is_instance_valid(car) or car.view == null or car.view.art == null: return
		var art: CarArt = car.view.art
		if art.atlas == null: return
		var sz := Vector2(art.size)
		var half := sz / 2.0
		var h := car.view.heading
		var top := car.global_position + CarView.screen_up * art.roof_z * CarView.STEP * CarView.lift_k
		# the roof's shape, faint, and a bright edge round the whole car's footprint
		draw_set_transform(top, h, Vector2.ONE)
		var z := clampi(int(art.roof_z) - 1, 0, art.n - 1)
		draw_texture_rect_region(art.atlas, Rect2(-half, sz), Rect2(float(z) * sz.x, 0.0, sz.x, sz.y), Color(1, 1, 1, 0.35 * strength))
		var r := Rect2(-Vector2(art.length_px, art.width_px) / 2.0, Vector2(art.length_px, art.width_px))
		draw_rect(r, Color(1.0, 0.95, 0.75, 0.85 * strength), false, 1.5)
		# the nose, so you can tell which way it's pointing
		draw_line(Vector2(r.end.x, -r.size.y * 0.3), Vector2(r.end.x + 4.0, 0.0), Color(1.0, 0.95, 0.75, 0.85 * strength), 1.5)
		draw_line(Vector2(r.end.x, r.size.y * 0.3), Vector2(r.end.x + 4.0, 0.0), Color(1.0, 0.95, 0.75, 0.85 * strength), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
