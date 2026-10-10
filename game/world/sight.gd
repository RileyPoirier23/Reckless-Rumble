## What Leo can see from the driver's seat, Project Zomboid style. Every building near the car
## throws a shadow away from it: the ground in a building's shadow is darker, and anybody driving
## in there (traffic, the police, a racer) fades out until they come round the corner. A building
## standing between the camera and the car goes see-through, so the car's never lost behind one.
## Settings > Graphics > LINE OF SIGHT turns it off.
class_name Sight
extends CanvasGroup

const SHADE := 0.5                 # how dark a shadow is
const REACH := 2400.0              # how far a shadow runs out past its building (px)
const CUT_ALPHA := 0.28            # a building in the way, see-through
const FADE_S := 0.18               # how quickly things fade in and out (s)

var drive: Node
var on := true
var shadows: Array[PackedVector2Array] = []    # this frame's shadow polygons, world px
var _draw_node: Node2D

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
	var movers: Array[Node2D] = []
	for n in drive.ysort.get_children():
		if n is BuildingNode:
			var b := n as BuildingNode
			if b.global_position.distance_to(eye) > view_r + 600.0:
				b.modulate.a = 1.0
				continue
			# in the way of the car: see-through
			var want := CUT_ALPHA if on and b.covers(eye) else 1.0
			b.modulate.a = lerpf(b.modulate.a, want, k)
			if not on or not b.blocks_sight(): continue
			var world_cs := PackedVector2Array()
			for c in b.corners(): world_cs.append(b.global_position + c)
			var s := shadow_of(world_cs, eye, REACH)
			if s.size() >= 3: shadows.append(s)
		elif n == drive.car:
			continue
		elif n is TrafficCar or n is PlayerCar or n is Wildlife.Animal:
			movers.append(n)
	visible = on and not shadows.is_empty()
	_draw_node.queue_redraw()
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
