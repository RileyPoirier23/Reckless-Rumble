## The GPS, in the style of whatever's stuck to the car's dash, with day and night maps:
## - tomtum:   a cheap suction-cup unit from 2009, heading-up, chirpy colours (Silvio)
## - phone:    Leo's cracked phone in a vent clip; loses signal out in the country (Supreem)
## - builtin:  the Charjer's dash screen: dark, red, tilted 2.5D
## - trucker:  a big rugged unit, north-up, orange on black (the wrecker)
class_name GpsView
extends Control

const PX := CarArt.PX
const INK := Color("0b090d")
const BONE := Color("f3ead2")

const PAL := {
	"tomtum": {
		"day": { "bg": Color("e8e2c8"), "road": Color("ffffff"), "edge": Color("a8a290"), "hwy": Color("f0b040"), "water": Color("8ac0e8"), "route": Color("2a7ad8"), "text": Color("1a1a1a"), "bar": Color("2a3a5a") },
		"night": { "bg": Color("1a2236"), "road": Color("6a7488"), "edge": Color("2a3248"), "hwy": Color("c08a30"), "water": Color("0e1a30"), "route": Color("3aa0ff"), "text": Color("e8e8f0"), "bar": Color("0e1424") } },
	"phone": {
		"day": { "bg": Color("ecebe6"), "road": Color("ffffff"), "edge": Color("d0cec6"), "hwy": Color("f8d070"), "water": Color("a8d0f0"), "route": Color("3a7af0"), "text": Color("202124"), "bar": Color("ffffff") },
		"night": { "bg": Color("202428"), "road": Color("4a5058"), "edge": Color("2a2e34"), "hwy": Color("8a7a50"), "water": Color("101820"), "route": Color("6aa0ff"), "text": Color("e8eaed"), "bar": Color("2a2e34") } },
	"builtin": {
		"day": { "bg": Color("1a1a1e"), "road": Color("5a5a62"), "edge": Color("2a2a30"), "hwy": Color("8a8a96"), "water": Color("1a2a3a"), "route": Color("e0202a"), "text": Color("f0f0f0"), "bar": Color("0e0e10") },
		"night": { "bg": Color("0a0a0c"), "road": Color("3a3a42"), "edge": Color("18181c"), "hwy": Color("5a5a66"), "water": Color("0a1420"), "route": Color("e0202a"), "text": Color("d8d8d8"), "bar": Color("050506") } },
	"trucker": {
		"day": { "bg": Color("d8ccb0"), "road": Color("8a6a40"), "edge": Color("b8a88a"), "hwy": Color("c8501a"), "water": Color("6a9ab8"), "route": Color("e0207a"), "text": Color("1a1408"), "bar": Color("2a2418") },
		"night": { "bg": Color("0a0806"), "road": Color("8a5a1a"), "edge": Color("1a140c"), "hwy": Color("ff8a1a"), "water": Color("0a1418"), "route": Color("ff3aa0"), "text": Color("ffb040"), "bar": Color("1a140c") } },
}

var style := "tomtum"
var world: World
var map: MapData
var sim: CarSim
var sky: WorldSky
var route := PackedVector2Array()
var dest_name := ""
var screen: Rect2            # where the map goes, inside the bezel
var _route_i := 0
var _clip: Control
var _top: Control
var _args := []

func _ready() -> void:
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.draw.connect(func(): if not _args.is_empty(): _map(_clip, Rect2(Vector2.ZERO, _clip.size), _args[0], _args[1], _args[2]))
	add_child(_clip)
	_top = Control.new()
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.size = Vector2(640, 360)
	_top.draw.connect(func(): _frame(_top, true))
	add_child(_top)

## The map is drawn into a clipped child so roads stop at the edge of the screen.
func _show_map(r: Rect2, heading_up: bool, tilt: float, scale_px_per_m: float) -> void:
	_clip.position = r.position
	_clip.size = r.size
	_args = [heading_up, tilt, scale_px_per_m]
	_clip.queue_redraw()

func _process(_dt: float) -> void:
	queue_redraw()

func set_route(p: PackedVector2Array, name: String) -> void:
	route = p
	dest_name = name
	_route_i = 0

func night() -> bool:
	return sky != null and sky.daylight() < 0.45

func pal() -> Dictionary:
	return PAL[style]["night" if night() else "day"]

func _signal() -> bool:
	# the phone loses its signal out past the towns (except along the highway)
	if style != "phone": return true
	if map.zone_at(sim.pos).id != "": return true
	var rd := map.nearest_road(sim.pos, 40.0)
	if not rd.is_empty() and rd.road.cls == "highway": return true
	return fmod(sim.pos.x * 0.01 + sim.pos.y * 0.013, 3.0) < 1.2

func _draw() -> void:
	if sim == null: return
	_frame(self, false)
	_top.queue_redraw()

func _frame(ci: CanvasItem, top: bool) -> void:
	if sim == null: return
	match style:
		"phone": _frame_phone(ci, top)
		"builtin": _frame_builtin(ci, top)
		"trucker": _frame_trucker(ci, top)
		_: _frame_tomtum(ci, top)

# ------------------------------------------------------------------ the map itself

func _map(ci: CanvasItem, r: Rect2, heading_up: bool, tilt: float, scale_px_per_m: float) -> void:
	var P: Dictionary = pal()
	ci.draw_rect(r, P.bg)
	if not _signal():
		for y in range(int(r.position.y), int(r.end.y), 10):
			for x in range(int(r.position.x), int(r.end.x), 10):
				ci.draw_rect(Rect2(x, y, 9, 9), P.edge)
		PixelFont.draw_centered(ci, r.get_center().x, r.get_center().y + 14, "NO SIGNAL", P.text)
		_arrow(ci, r.get_center() + Vector2(0, r.size.y * 0.15), 0.0 if heading_up else sim.heading + PI / 2.0, P.route)
		return
	var centre := r.get_center() + Vector2(0, r.size.y * 0.18 if heading_up else 0.0)
	var rot := -sim.heading - PI / 2.0 if heading_up else 0.0
	var radius := maxf(r.size.x, r.size.y) / scale_px_per_m * 0.9
	var toscreen := func(m: Vector2) -> Vector2:
		var q: Vector2 = (m - sim.pos).rotated(rot) * scale_px_per_m
		q.y *= tilt
		return centre + q
	# river
	if world:
		var c0 := World.ck(sim.pos - Vector2(radius, radius))
		var c1 := World.ck(sim.pos + Vector2(radius, radius))
		var done := {}
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				for i in world._b_river.get(Vector2i(cx, cy), []):
					if done.has(i): continue
					done[i] = true
					var poly := PackedVector2Array([toscreen.call(world.river_l[i]), toscreen.call(world.river_l[i + 1]), toscreen.call(world.river_r[i + 1]), toscreen.call(world.river_r[i])])
					ci.draw_primitive(poly, PackedColorArray([P.water, P.water, P.water, P.water]), PackedVector2Array())
	# roads: casings first, then fills, highways on top
	var segs := {}
	var k0 := map._cell(sim.pos - Vector2(radius, radius))
	var k1 := map._cell(sim.pos + Vector2(radius, radius))
	for cy in range(k0.y, k1.y + 1):
		for cx in range(k0.x, k1.x + 1):
			for e in map._road_index.get(Vector2i(cx, cy), []):
				segs[Vector2i(e[0], e[1])] = true
	var widths := { "highway": 6.0, "arterial": 4.5, "street": 2.5, "rural": 3.5, "gravel": 2.0, "ramp": 2.5 }
	for pass_i in 3:
		for s in segs:
			var rd: Dictionary = map.roads[s.x]
			var a: Vector2 = toscreen.call(rd.pts[s.y])
			var b: Vector2 = toscreen.call(rd.pts[s.y + 1])
			var w: float = widths[rd.cls]
			var hwy: bool = rd.cls == "highway"
			if pass_i == 0: ci.draw_line(a, b, P.edge, w + 2.0)
			elif pass_i == 1 and not hwy: ci.draw_line(a, b, P.road, w)
			elif pass_i == 2 and hwy: ci.draw_line(a, b, P.hwy, w)
	# the route
	if route.size() > 1:
		_advance_route()
		var pts := PackedVector2Array()
		pts.append(toscreen.call(sim.pos))
		for i in range(_route_i, route.size()):
			pts.append(toscreen.call(route[i]))
		ci.draw_polyline(pts, P.route, 3.0)
		var end: Vector2 = toscreen.call(route[route.size() - 1])
		if r.has_point(end):
			ci.draw_rect(Rect2(end + Vector2(0, -10), Vector2(2, 10)), P.text)
			ci.draw_rect(Rect2(end + Vector2(2, -10), Vector2(7, 5)), P.route)
	_arrow(ci, centre, 0.0 if heading_up else sim.heading + PI / 2.0, P.route if style != "tomtum" else Color("e04020"))

func _arrow(ci: CanvasItem, c: Vector2, ang: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, -7), Vector2(5, 5), Vector2(0, 2), Vector2(-5, 5)])
	var out := PackedVector2Array()
	for p in pts: out.append(c + p.rotated(ang))
	ci.draw_colored_polygon(out, col)
	ci.draw_polyline(out + PackedVector2Array([out[0]]), Color(1, 1, 1, 0.8), 1.0)

func _advance_route() -> void:
	while _route_i < route.size() - 1 and route[_route_i].distance_to(sim.pos) < 25.0:
		_route_i += 1
	# skip ahead if the car is closer to a later point
	var best := _route_i
	var bd := route[_route_i].distance_to(sim.pos)
	for i in range(_route_i, mini(route.size(), _route_i + 12)):
		var d := route[i].distance_to(sim.pos)
		if d < bd:
			bd = d
			best = i
	_route_i = best

func route_left() -> float:
	if route.size() < 2: return 0.0
	var d := sim.pos.distance_to(route[_route_i])
	for i in range(_route_i, route.size() - 1): d += route[i].distance_to(route[i + 1])
	return d

## The next turn: [-1 left / 1 right / 0 straight, metres to it]
func next_turn() -> Array:
	if route.size() < 3: return [0, 0.0]
	var acc := sim.pos.distance_to(route[_route_i])
	for i in range(maxi(1, _route_i), route.size() - 1):
		var d1 := (route[i] - route[i - 1]).normalized()
		var d2 := (route[i + 1] - route[i]).normalized()
		var turn := d1.angle_to(d2)
		if absf(turn) > deg_to_rad(35.0):
			return [1 if turn > 0.0 else -1, acc]
		acc += route[i].distance_to(route[i + 1])
	return [0, acc]

func _street() -> String:
	var rd := map.nearest_road(sim.pos, 25.0)
	if rd.is_empty(): return "OFF ROAD"
	var n: String = rd.road.name
	return n if n != "" else map.zone_at(sim.pos).label

func _dist_str(m: float) -> String:
	return "%d M" % int(snappedf(m, 10.0)) if m < 1000.0 else "%.1f KM" % (m / 1000.0)

func _turn_icon(ci: CanvasItem, p: Vector2, dir: int, col: Color) -> void:
	ci.draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 10)), col)
	if dir == 0:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(5, 0), p + Vector2(0.5, -5)]), col)
	else:
		var s := float(dir)
		ci.draw_rect(Rect2(p + Vector2(0 if s > 0 else -7, -1), Vector2(8, 3)), col)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(s * 8, -4), p + Vector2(s * 8, 5), p + Vector2(s * 13, 0.5)]), col)

# ------------------------------------------------------------------ the units
# Each unit is drawn in two passes: "bezel" (the case, under the map) and "top" (the
# turn banner, street name and status bits, over the map).

func _frame_tomtum(ci: CanvasItem, top: bool) -> void:
	var r := Rect2(470, 254, 166, 102)
	screen = Rect2(r.position + Vector2(6, 6), r.size - Vector2(12, 12))
	var P: Dictionary = pal()
	if not top:
		ci.draw_rect(Rect2(r.get_center().x - 6, r.position.y - 6, 12, 8), Color("2a2a2e"))   # the suction-cup arm
		ci.draw_rect(r, Color("16161a"))
		ci.draw_rect(r.grow(-1), Color("26262c"), false, 2.0)
		PixelFont.draw(ci, Vector2(r.position.x + 4, r.end.y - 5), "TOMTUM", Color("5a5a62"))
		_show_map(screen, true, 1.0, 0.45 + 0.35 * (1.0 - clampf(sim.speed() / 30.0, 0, 1)))
		return
	ci.draw_rect(Rect2(screen.position.x, screen.end.y - 14, screen.size.x, 14), P.bar)
	PixelFont.draw(ci, Vector2(screen.position.x + 3, screen.end.y - 10), _street(), Color.WHITE)
	PixelFont.draw(ci, Vector2(screen.end.x - 18, screen.end.y - 10), "%d" % int(sim.speed() * 3.6), Color("8aff6a"))
	if route.size() > 1:
		var nt := next_turn()
		ci.draw_rect(Rect2(screen.position, Vector2(58, 22)), Color(P.bar, 0.92))
		_turn_icon(ci, screen.position + Vector2(10, 9), nt[0], Color("8aff6a"))
		PixelFont.draw(ci, screen.position + Vector2(22, 4), _dist_str(nt[1]), Color.WHITE)
		PixelFont.draw(ci, screen.position + Vector2(22, 13), _dist_str(route_left()), Color(1, 1, 1, 0.6))

func _frame_phone(ci: CanvasItem, top: bool) -> void:
	var r := Rect2(530, 210, 102, 146)
	screen = Rect2(r.position + Vector2(4, 9), r.size - Vector2(8, 18))
	var P: Dictionary = pal()
	if not top:
		ci.draw_rect(r, Color("0e0e10"))
		ci.draw_rect(r, Color("3a3a40"), false, 2.0)
		ci.draw_rect(Rect2(r.get_center().x - 10, r.position.y + 3, 20, 3), Color("2a2a2e"))   # the speaker
		_show_map(screen, true, 1.0, 0.6)
		return
	# status bar: the time, the signal, a battery that's always low
	ci.draw_rect(Rect2(screen.position, Vector2(screen.size.x, 8)), Color(0, 0, 0, 0.55))
	PixelFont.draw(ci, screen.position + Vector2(2, 1), sky.clock_str().split(" ")[0], Color.WHITE)
	var bars := 4 if _signal() else 0
	for i in 4: ci.draw_rect(Rect2(screen.position + Vector2(screen.size.x - 32 + i * 3, 6 - i * 1.5), Vector2(2, 1.5 + i * 1.5)), Color.WHITE if i < bars else Color(1, 1, 1, 0.25))
	ci.draw_rect(Rect2(screen.end.x - 16, screen.position.y + 1, 12, 5), Color.WHITE, false, 1.0)
	ci.draw_rect(Rect2(screen.end.x - 15, screen.position.y + 2, 3, 3), Color("e0402e"))
	if route.size() > 1:
		var nt := next_turn()
		ci.draw_rect(Rect2(screen.position + Vector2(0, 8), Vector2(screen.size.x, 20)), Color("0a6a3a"))
		_turn_icon(ci, screen.position + Vector2(9, 16), nt[0], Color.WHITE)
		PixelFont.draw(ci, screen.position + Vector2(20, 11), _dist_str(nt[1]), Color.WHITE)
		PixelFont.draw(ci, screen.position + Vector2(20, 19), dest_name.substr(0, 18), Color(1, 1, 1, 0.75))
	ci.draw_rect(Rect2(screen.position.x, screen.end.y - 10, screen.size.x, 10), P.bar)
	PixelFont.draw(ci, Vector2(screen.position.x + 2, screen.end.y - 8), _street().substr(0, 23), P.text)
	# the crack (it was like this when Leo got it)
	var c := Color(1, 1, 1, 0.45)
	var o := screen.position
	ci.draw_line(o + Vector2(60, 30), o + Vector2(78, 56), c, 1.0)
	ci.draw_line(o + Vector2(78, 56), o + Vector2(70, 80), c, 1.0)
	ci.draw_line(o + Vector2(78, 56), o + Vector2(93, 64), c, 1.0)
	ci.draw_line(o + Vector2(60, 30), o + Vector2(52, 20), c, 1.0)

func _frame_builtin(ci: CanvasItem, top: bool) -> void:
	var r := Rect2(430, 262, 206, 94)
	screen = Rect2(r.position + Vector2(4, 12), r.size - Vector2(8, 26))
	var P: Dictionary = pal()
	if not top:
		ci.draw_rect(r, Color("050506"))
		ci.draw_rect(r, Color("2a2a30"), false, 2.0)
		_show_map(screen, true, 0.62, 0.5)
		return
	# top bar: the time, the outside temperature
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 10)), Color("0e0e10"))
	PixelFont.draw(ci, r.position + Vector2(5, 4), sky.clock_str(), P.text)
	PixelFont.draw(ci, r.position + Vector2(r.size.x - 30, 4), "%d°C" % int(sky.temperature()), P.text)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2.0 - 14, 3), Vector2(28, 8)), Color("e0202a"))
	PixelFont.draw_centered(ci, r.get_center().x, r.position.y + 5, "NAV", Color.WHITE)
	# bottom bar
	ci.draw_rect(Rect2(r.position.x + 2, r.end.y - 14, r.size.x - 4, 12), Color("0e0e10"))
	PixelFont.draw(ci, Vector2(r.position.x + 5, r.end.y - 11), _street(), P.text)
	if route.size() > 1:
		var nt := next_turn()
		_turn_icon(ci, Vector2(r.end.x - 86, r.end.y - 9), nt[0], Color("e0202a"))
		PixelFont.draw(ci, Vector2(r.end.x - 74, r.end.y - 11), _dist_str(nt[1]), P.text)
		var eta_min := route_left() / maxf(sim.speed(), 12.0) * sky.rate * 60.0
		PixelFont.draw(ci, Vector2(r.end.x - 34, r.end.y - 11), "%d MIN" % int(maxf(1.0, eta_min)), Color("e0202a"))

func _frame_trucker(ci: CanvasItem, top: bool) -> void:
	var r := Rect2(460, 250, 176, 106)
	screen = Rect2(r.position + Vector2(7, 7), r.size - Vector2(14, 30))
	var P: Dictionary = pal()
	if not top:
		ci.draw_rect(r, Color("e07a1a"))
		ci.draw_rect(r.grow(-3), Color("1a1814"))
		_show_map(screen, false, 1.0, 0.35)
		return
	PixelFont.draw(ci, screen.position + Vector2(3, 3), "N", P.text, 2)
	ci.draw_rect(Rect2(r.position.x + 5, r.end.y - 22, r.size.x - 10, 18), P.bar)
	PixelFont.draw(ci, Vector2(r.position.x + 9, r.end.y - 19), _street(), Color("ffb040"))
	PixelFont.draw(ci, Vector2(r.position.x + 9, r.end.y - 11), "%d KM/H  %d°C" % [int(sim.speed() * 3.6), int(sky.temperature())], Color("ffb040"))
	if route.size() > 1:
		var nt := next_turn()
		_turn_icon(ci, Vector2(r.end.x - 52, r.end.y - 14), nt[0], Color("ffb040"))
		PixelFont.draw(ci, Vector2(r.end.x - 40, r.end.y - 19), _dist_str(nt[1]), Color("ffb040"))
		PixelFont.draw(ci, Vector2(r.end.x - 40, r.end.y - 11), _dist_str(route_left()), Color(1, 0.7, 0.25, 0.7))
