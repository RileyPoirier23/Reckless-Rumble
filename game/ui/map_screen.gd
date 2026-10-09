## The big map: Port Rumble to Salisbury to Havelock. Pick a place and the GPS routes you there.
class_name MapScreen
extends Control

signal chosen(name: String, at: Vector2)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")

var map: MapData
var world: World
var sim: CarSim
var dests: Array = []
var sel := 0
var area := Rect2(178, 40, 452, 270)

func open() -> void:
	dests = map.landmarks.filter(func(l): return l.dest)
	visible = true

func _process(_dt: float) -> void:
	if not visible: return
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % dests.size()
	if Input.is_action_just_pressed("ui_up"): sel = (sel + dests.size() - 1) % dests.size()
	if Input.is_action_just_pressed("ui_accept"):
		chosen.emit(dests[sel].name, dests[sel].p)
		visible = false
	queue_redraw()

func _to(m: Vector2) -> Vector2:
	var B := MapData.BOUNDS
	var s := minf(area.size.x / B.size.x, area.size.y / B.size.y)
	return area.position + (m - B.position) * s

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 0.94))
	PixelFont.draw(self, Vector2(12, 12), "MAP", GOLD, 3, INK)
	PixelFont.draw(self, Vector2(178, 16), "PORT RUMBLE - SALISBURY - HAVELOCK", ASH, 2)
	draw_rect(area, Color("2a3424"))
	# the river
	for i in range(0, world.river_l.size() - 1, 2):
		var j := mini(i + 2, world.river_l.size() - 1)
		var rc := Color("6a4a32")
		draw_primitive(PackedVector2Array([_to(world.river_l[i]), _to(world.river_l[j]), _to(world.river_r[j]), _to(world.river_r[i])]), PackedColorArray([rc, rc, rc, rc]), PackedVector2Array())
	# the towns
	for z in MapData.ZONES:
		var r := Rect2(_to(z.r.position), _to(z.r.end) - _to(z.r.position))
		draw_rect(r, Color(0.5, 0.48, 0.42, 0.35))
	# rail, roads
	for i in map.rail_pts.size() - 1: draw_line(_to(map.rail_pts[i]), _to(map.rail_pts[i + 1]), Color("6a5a4a"), 1.0)
	for rd in map.roads:
		var col := Color("f0b040") if rd.cls == "highway" else (Color("e8e4dc") if rd.cls in ["arterial", "rural"] else Color("8a8478"))
		var w := 2.0 if rd.cls in ["highway", "arterial"] else 1.0
		var pts: PackedVector2Array = rd.pts
		for i in pts.size() - 1: draw_line(_to(pts[i]), _to(pts[i + 1]), col, w)
	# labels
	for z in MapData.ZONES:
		var c := _to(z.r.get_center())
		PixelFont.draw_centered(self, c.x, c.y - 10, z.label, BONE, 1, INK)
	# places you can go
	for i in dests.size():
		var p := _to(dests[i].p)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), GOLD if i == sel else Color("c84a3a"))
	# you
	var me := _to(sim.pos)
	var ang := sim.heading
	draw_colored_polygon(PackedVector2Array([me + Vector2(7, 0).rotated(ang), me + Vector2(-4, 4).rotated(ang), me + Vector2(-4, -4).rotated(ang)]), Color("3aa0ff"))
	draw_circle(me, 9, Color(0.23, 0.63, 1.0, 0.25 + 0.15 * sin(Time.get_ticks_msec() / 200.0)))
	# the list
	draw_rect(Rect2(10, 40, 160, 270), Color(0, 0, 0, 0.4))
	for i in dests.size():
		var y := 46 + i * 15
		if i == sel: draw_rect(Rect2(12, y - 3, 156, 13), Color(0.85, 0.64, 0.25, 0.25))
		PixelFont.draw(self, Vector2(18, y), dests[i].name, GOLD if i == sel else BONE)
		PixelFont.draw(self, Vector2(132, y), "%.1fK" % (dests[i].p.distance_to(sim.pos) / 1000.0 * 8.0), ASH)
	PixelFont.draw(self, Vector2(10, 318), Hints.fmt("{updown}: PICK  {ui_accept}: SET THE GPS  {map}: CLOSE"), ASH)
	PixelFont.draw(self, Vector2(10, 330), "DISTANCES ARE REAL-WORLD KM. THE MAP IS ABOUT 1:8.", Color(ASH, 0.7))
