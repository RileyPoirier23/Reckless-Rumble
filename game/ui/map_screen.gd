## The big map: Port Rumble to Salisbury to Havelock. Pick a place (the list, the keys, or click
## it on the map) and it shows the way there and what the place is for; accept and the GPS takes
## you. Click anywhere else on the map to drop a pin and drive to that. Zoom in round you with the
## tab buttons or the mouse wheel. Whatever you're meant to be doing right now is on it too.
class_name MapScreen
extends Control

signal chosen(name: String, at: Vector2)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const BLUE := Color("3aa0ff")

## What kind of place each one is (the colour of its marker), and what it's for.
const KINDS := {
	"objective": Color("f0c040"), "shop": Color("e07a3a"), "fuel": Color("6fbf5a"),
	"night": Color("b070e0"), "parts": Color("4aa0c8"), "place": Color("c84a3a"), "pin": Color("3aa0ff"),
}
const ABOUT := {
	"COVINGTON AUTO": ["shop", "THE SHOP. THE GARAGE IS HERE: SWITCH CARS, PARTS, PAINT AND REPAIRS. THE COUNTER OPENS IN THE MORNING."],
	"RUMBLE CENTRE": ["place", "DOWNTOWN: THE ARENA, THE BARS, THE TRAFFIC."],
	"TIDAL BORE PARK": ["place", "WHERE THE RIVER RUNS BACKWARDS TWICE A DAY."],
	"MAGNET HILL": ["place", "LET OFF THE GAS ON THE HILL ROAD AND THE CAR ROLLS UPHILL. IT DOESN'T. IT DOES."],
	"CASINO RUMBLE": ["place", "LIGHTS, A BIG LOT, NOBODY WINNING."],
	"CHAMPAGNE PLACE": ["night", "THE MEET: FRIDAY AND SATURDAY NIGHTS FROM 10 IN THE BACK ROW. $20 TO GET IN."],
	"AIRSTRIP 7": ["night", "DRAG NIGHT ON THE OLD RUNWAY (IT'S ON THE GIGS APP)."],
	"THE LARGE STOP": ["fuel", "THE TRUCK STOP ON THE HIGHWAY: FUEL AND BAD COFFEE."],
	"SALISBURY": ["place", "THE NEXT TOWN WEST, DOWN THE HIGHWAY."],
	"HAVELOCK AIRFIELD": ["place", "A GRASS STRIP AND A WINDSOCK."],
	"LIME QUARRY": ["place", "GRAVEL ROADS AND A BIG HOLE."],
	"HAVELOCK": ["place", "THE END OF THE ROAD. THE MOOSE LIVE OUT HERE."],
	"RIVERSIDE": ["place", "ACROSS THE RIVER: QUIET STREETS."],
	"NORTHSIDE SALVAGE": ["parts", "USED PARTS, CHEAP. SOME OF THEM WORK."],
	"NORTHSIDE IMPOUND": ["parts", "WHERE TOWED CARS GO. THE AUCTION IS ON SATURDAYS."],
	"THE LUCHADOOROS": ["shop", "1TON'S CLUB: HYDRAULICS AND DONKS."],
}
const ZOOMS := [1.0, 2.5, 6.0]
const ROW_H := 13
const ROWS_VIS := 19

var map: MapData
var world: World
var sim: CarSim
var dests: Array = []
var sel := 0
var area := Rect2(178, 40, 452, 252)
var current_name := ""                 # what you're meant to be doing right now, and where
var current_p := Vector2.INF
var zoom := 0
var scroll := 0
var _route := PackedVector2Array()     # the way to the picked place, for the preview
var _route_for := -1
var _pin := Vector2.INF
var _opened := -1
var _labels: Array[Rect2] = []         # where this frame's names went, so none lands on another

func open() -> void:
	dests = []
	if current_p != Vector2.INF:
		dests.append({ "name": "GPS: " + (current_name if current_name != "" else "WHERE YOU'RE HEADED"), "p": current_p, "kind": "objective" })
	for l in map.landmarks:
		if not l.dest: continue
		dests.append({ "name": l.name, "p": l.p, "kind": kind_of(String(l.name)) })
	if _pin != Vector2.INF: dests.append({ "name": "YOUR PIN", "p": _pin, "kind": "pin" })
	sel = 0
	scroll = 0
	_route_for = -1
	_opened = Engine.get_process_frames()
	visible = true

## What kind of place this is (for its colour), by name.
static func kind_of(nm: String) -> String:
	if ABOUT.has(nm): return String(ABOUT[nm][0])
	if nm.contains("GAS") or nm.contains("ULTRAMARGE"): return "fuel"
	return "place"

## A line on what's there.
static func about(nm: String, kind: String) -> String:
	if ABOUT.has(nm): return String(ABOUT[nm][1])
	match kind:
		"objective": return "WHERE YOU'RE MEANT TO BE GOING RIGHT NOW."
		"fuel": return "A GAS STATION. PULL UP TO THE PUMPS AND STOP TO FILL UP."
		"pin": return "WHERE YOU CLICKED. THE GPS GETS YOU AS CLOSE AS THE ROADS GO."
	return ""

## Metres, as the GPS counts them.
static func dist_text(m: float) -> String:
	return "%d M" % int(roundf(m / 10.0) * 10.0) if m < 1000.0 else "%.1f KM" % (m / 1000.0)

func _pick(i: int) -> void:
	sel = clampi(i, 0, dests.size() - 1)
	if sel < scroll: scroll = sel
	if sel >= scroll + ROWS_VIS: scroll = sel - ROWS_VIS + 1

func _go() -> void:
	if dests.is_empty(): return
	chosen.emit(String(dests[sel].name), dests[sel].p)
	visible = false

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	if dests.is_empty() or Engine.get_process_frames() == _opened: return
	if Input.is_action_just_pressed("ui_down"): _pick((sel + 1) % dests.size())
	if Input.is_action_just_pressed("ui_up"): _pick((sel + dests.size() - 1) % dests.size())
	if Input.is_action_just_pressed("ui_tab_next"): zoom = mini(zoom + 1, ZOOMS.size() - 1)
	if Input.is_action_just_pressed("ui_tab_prev"): zoom = maxi(zoom - 1, 0)
	if Input.is_action_just_pressed("ui_accept"): _go()

func _gui_input(e: InputEvent) -> void:
	if not visible or dests.is_empty(): return
	if e is InputEventMouseButton and e.pressed:
		var mb := e as InputEventMouseButton
		var at := get_local_mouse_position()
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and area.has_point(at): zoom = mini(zoom + 1, ZOOMS.size() - 1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and area.has_point(at): zoom = maxi(zoom - 1, 0)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			# the list: click to pick, click the picked one again to go
			if Rect2(10, 40, 160, ROWS_VIS * ROW_H).has_point(at):
				var i := scroll + int((at.y - 43) / ROW_H)
				if i >= 0 and i < dests.size():
					if i == sel or mb.double_click: _go()
					else: _pick(i)
			elif area.has_point(at):
				# the map: a place near the click, or a pin where it landed
				var best := -1
				var bd := 7.0
				for i in dests.size():
					var d := _to(dests[i].p).distance_to(at)
					if d < bd:
						bd = d
						best = i
				if best >= 0:
					if best == sel or mb.double_click: _go()
					else: _pick(best)
				else:
					_pin = _from(at)
					dests = dests.filter(func(x): return String(x.kind) != "pin")
					dests.append({ "name": "YOUR PIN", "p": _pin, "kind": "pin" })
					_pick(dests.size() - 1)
					_route_for = -1
		accept_event()
	elif e is InputEventMouseMotion:
		var at2 := get_local_mouse_position()
		var over := Rect2(10, 40, 160, ROWS_VIS * ROW_H).has_point(at2) and scroll + int((at2.y - 43) / ROW_H) < dests.size()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if over or area.has_point(at2) else Control.CURSOR_ARROW

## The map's view: the whole region, or zoomed in round you.
func _view() -> Rect2:
	var B := MapData.BOUNDS
	var z: float = ZOOMS[zoom]
	if z <= 1.0: return B
	var w := B.size.x / z
	var h := B.size.y / z
	var c := sim.pos
	c.x = clampf(c.x, B.position.x + w / 2.0, B.end.x - w / 2.0)
	c.y = clampf(c.y, B.position.y + h / 2.0, B.end.y - h / 2.0)
	return Rect2(c - Vector2(w, h) / 2.0, Vector2(w, h))

func _scale() -> float:
	var v := _view()
	return minf(area.size.x / v.size.x, area.size.y / v.size.y)

func _to(m: Vector2) -> Vector2:
	var v := _view()
	return area.position + (m - v.position) * _scale()

func _from(s: Vector2) -> Vector2:
	return _view().position + (s - area.position) / _scale()

func _seen(p: Vector2) -> bool:
	return area.grow(-2).has_point(p)

func _line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	# only what's inside the map's frame (a cheap clip: both ends in, or skip it)
	var pa := _to(a)
	var pb := _to(b)
	if not (area.has_point(pa) or area.has_point(pb)): return
	pa = pa.clamp(area.position, area.end)
	pb = pb.clamp(area.position, area.end)
	draw_line(pa, pb, col, w)

## A name on the map, unless it would land on one already there (the first one in wins). Backed
## so it reads over the roads.
func _label(at: Vector2, text: String, col: Color, centred := false) -> void:
	var w := float(PixelFont.width(text))
	var x := at.x - w / 2.0 if centred else at.x
	x = clampf(x, area.position.x + 2, area.end.x - w - 2)
	var r := Rect2(x - 1, at.y - 1, w + 2, 7)
	if not area.encloses(r): return
	for o in _labels:
		if o.intersects(r): return
	_labels.append(r)
	draw_rect(r, Color(0, 0, 0, 0.55))
	PixelFont.draw(self, Vector2(x, at.y), text, col)

func _draw() -> void:
	_labels.clear()
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 0.94))
	PixelFont.draw(self, Vector2(12, 12), "MAP", GOLD, 3, INK)
	PixelFont.draw(self, Vector2(178, 16), "PORT RUMBLE - SALISBURY - HAVELOCK", ASH, 2)
	var zl := "ZOOM %s" % ["WHOLE MAP", "TOWN", "STREETS"][zoom]
	PixelFont.draw(self, Vector2(630 - PixelFont.width(zl), 30), zl, ASH)
	draw_rect(area, Color("2a3424"))
	# the river
	for i in range(0, world.river_l.size() - 1, 2):
		var j := mini(i + 2, world.river_l.size() - 1)
		var q := PackedVector2Array([_to(world.river_l[i]), _to(world.river_l[j]), _to(world.river_r[j]), _to(world.river_r[i])])
		var inside := false
		for p in q: inside = inside or area.has_point(p)
		if not inside: continue
		for k in q.size(): q[k] = q[k].clamp(area.position, area.end)
		var rc := Color("6a4a32")
		draw_primitive(q, PackedColorArray([rc, rc, rc, rc]), PackedVector2Array())
	# the towns
	for z in MapData.ZONES:
		var r := Rect2(_to(z.r.position), _to(z.r.end) - _to(z.r.position)).intersection(area)
		if r.has_area(): draw_rect(r, Color(0.5, 0.48, 0.42, 0.35))
	# rail, roads
	for i in map.rail_pts.size() - 1: _line(map.rail_pts[i], map.rail_pts[i + 1], Color("6a5a4a"), 1.0)
	for rd in map.roads:
		var col := Color("f0b040") if rd.cls == "highway" else (Color("e8e4dc") if rd.cls in ["arterial", "rural"] else Color("8a8478"))
		var w := 2.0 if rd.cls in ["highway", "arterial"] else 1.0
		if zoom >= 2: w += 1.0
		var pts: PackedVector2Array = rd.pts
		for i in pts.size() - 1: _line(pts[i], pts[i + 1], col, w)
	# the way to the picked place
	if not dests.is_empty():
		if _route_for != sel:
			_route = map.route(sim.pos, dests[sel].p)
			_route_for = sel
		for i in _route.size() - 1: _line(_route[i], _route[i + 1], Color(BLUE, 0.95), 3.0 if zoom > 0 else 2.0)
	# the places: a marker each, coloured by what's there; the picked one's named on the map
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	for i in dests.size():
		var p := _to(dests[i].p)
		if not _seen(p): continue
		var col: Color = KINDS.get(String(dests[i].kind), KINDS.place)
		var s := 3.0 if i == sel else 2.0
		if String(dests[i].kind) == "objective":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0)]), Color(col, 0.6 + 0.4 * pulse))
		else:
			draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), INK)
			draw_rect(Rect2(p - Vector2(s - 1, s - 1), Vector2(s - 1, s - 1) * 2.0), col)
		if i == sel: draw_arc(p, 6.0 + 2.0 * pulse, 0.0, TAU, 16, GOLD, 1.0)
	# you
	var me := _to(sim.pos)
	if _seen(me):
		var ang := sim.heading
		draw_circle(me, 9, Color(0.23, 0.63, 1.0, 0.25 + 0.15 * pulse))
		draw_colored_polygon(PackedVector2Array([me + Vector2(7, 0).rotated(ang), me + Vector2(-4, 4).rotated(ang), me + Vector2(-4, -4).rotated(ang)]), BLUE)
	# the names, most important first: where you're going, you, the places, the towns
	if not dests.is_empty() and _seen(_to(dests[sel].p)):
		_label(_to(dests[sel].p) + Vector2(8, -3), String(dests[sel].name), GOLD)
	if _seen(me): _label(me + Vector2(9, 4), "YOU", BLUE)
	if zoom >= 1:
		for i in dests.size():
			if i != sel and _seen(_to(dests[i].p)): _label(_to(dests[i].p) + Vector2(6, -3), String(dests[i].name), Color(BONE, 0.85))
	if zoom < 2:
		for z in MapData.ZONES:
			var c := _to(z.r.get_center())
			if _seen(c): _label(c + Vector2(0, -10), String(z.label), BONE, true)
	draw_rect(area, Color(ASH, 0.6), false, 1.0)
	# the list
	draw_rect(Rect2(10, 40, 160, ROWS_VIS * ROW_H + 6), Color(0, 0, 0, 0.4))
	for i in range(scroll, mini(dests.size(), scroll + ROWS_VIS)):
		var y := 46 + (i - scroll) * ROW_H
		if i == sel: draw_rect(Rect2(12, y - 3, 156, ROW_H - 1), Color(0.85, 0.64, 0.25, 0.25))
		var col2: Color = KINDS.get(String(dests[i].kind), KINDS.place)
		draw_rect(Rect2(15, y, 4, 5), col2)
		PixelFont.draw(self, Vector2(22, y), String(dests[i].name).substr(0, 21), GOLD if i == sel else BONE)
	if dests.size() > ROWS_VIS:
		PixelFont.draw(self, Vector2(10, 32), "%d/%d" % [sel + 1, dests.size()], ASH)
	# what the picked place is, how far, and roughly how long
	if not dests.is_empty():
		var d: Dictionary = dests[sel]
		var road_m := 0.0
		for i in _route.size() - 1: road_m += _route[i].distance_to(_route[i + 1])
		if road_m <= 0.0: road_m = sim.pos.distance_to(d.p)
		var mins := maxi(1, int(ceilf(road_m / (45.0 / 3.6) / 60.0)))
		var box := Rect2(178, 296, 452, 30)
		draw_rect(box, Color(0, 0, 0, 0.4))
		PixelFont.draw(self, box.position + Vector2(6, 5), "%s   %s BY ROAD, ABOUT %d MIN" % [String(d.name), dist_text(road_m), mins], GOLD)
		var ab := about(String(d.name), String(d.kind))
		if ab != "": PixelFont.draw(self, box.position + Vector2(6, 17), ab.substr(0, 110), ASH)
	PixelFont.draw(self, Vector2(10, 334), Hints.fmt("{updown}: PICK  {ui_accept}: SET THE GPS  {ui_tab_prev}/{ui_tab_next}: ZOOM  {map}: CLOSE"), ASH)
	PixelFont.draw(self, Vector2(10, 346), "MOUSE: CLICK A PLACE, CLICK IT AGAIN TO GO. CLICK ANYWHERE ELSE TO DROP A PIN. THE WHEEL ZOOMS.", Color(ASH, 0.75))
