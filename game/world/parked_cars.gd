## The cars nobody's driving: parked along the town streets, in the driveways beside the houses,
## in the stalls of the lots, semis resting at the truck stop. So the town looks lived in.
##
## The spots come from the map once (both curbs of every town street, clear of the junctions and
## of whatever stands on the sidewalk; a driveway beside each house with room for one; every
## stall of the striped lots) and are kept by 64 m cell. Cells near the camera get their cars
## (who's parked where depends on the time of day: downtown fills up by day, the driveways by
## night, the mall's lot empties after closing); cells left far behind let them go. A parked car
## is a ParkedCar: no sim, built from the same art as traffic, solid to drive into.
class_name ParkedCars
extends Node2D

const PX := CarArt.PX
const CELL := 64.0
const NEAR := 150.0               # cells this close to the camera have their cars
const FAR := 230.0                # and let them go past this
const PER_STEP := 10              # cars parked per step at most (the art's drawn on a worker anyway)

var drive: Node
var map: MapData
var traffic: Traffic
var enabled := true
var spots := {}                   # Vector2i -> Array of spots: { p, h, kind, style, seed, lot }
var live := {}                    # Vector2i -> Array of ParkedCar
var pads := {}                    # Vector2i -> Array of [centre, heading] driveway pads to draw
var _t := 0.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	map = drive.world.map
	traffic = drive.traffic
	z_index = -3994                # on the ground, under the skid marks and the cars
	z_as_relative = false
	_curbs()
	_driveways()
	_lots()

# ------------------------------------------------------------------ where they go

func _add(p: Vector2, h: float, kind: String, style: String, lot := "") -> void:
	var k := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	if not spots.has(k): spots[k] = []
	spots[k].append({ "p": p, "h": h, "kind": kind, "style": style, "seed": absi(int(p.x * 131.0) * 7919 + int(p.y * 71.0)), "lot": lot })

## Both curbs of every street in town, a car's length apart, clear of the junctions, the
## crossings, the bridges and the poles and signs on the sidewalk.
func _curbs() -> void:
	for r in map.roads:
		if String(r.cls) != "street" or String(r.zone) == "": continue
		var pts: PackedVector2Array = r.pts
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var L := a.distance_to(b)
			var d := (b - a) / maxf(L, 0.01)
			var right := Vector2(-d.y, d.x)
			var s := 7.0
			while s < L - 7.0:
				var c := a + d * s
				s += 7.6
				var z := map.zone_at(c)
				var style := String(z.get("style", ""))
				if not style in ["downtown", "residential", "oldtown", "village"]: continue
				if not _clear_curb(c): continue
				for side: float in [-1.0, 1.0]:
					# along the curb, the outside wheels up over it, clear of the lane
					var p := c + right * side * (float(r.w) / 2.0 - 0.1)
					if _near_furniture(p) or not map.lot_at(p).is_empty(): continue
					# parked facing the way that side of the street drives
					_add(p, (d * side).angle(), "curb", style)

func _clear_curb(c: Vector2) -> bool:
	for n in traffic._near_nodes(c, 0.0, 20.0):
		if map.g_adj[n].size() != 2: return false
	if map.rail_near(c, 12.0) or map.river_at(c) > 0: return false
	for br in map.bridges:
		if MapData.seg_dist(c, br.a, br.b) < 14.0: return false
	return true

func _near_furniture(p: Vector2) -> bool:
	var f: RoadFurniture = drive.furniture
	if f == null: return false
	var k := Vector2i(floori(p.x / RoadFurniture.CELL), floori(p.y / RoadFurniture.CELL))
	for it in f.cells.get(k, []):
		if (it.p as Vector2).distance_to(p) < 4.5: return true
	return false

## A driveway beside each house that has room for one, the car nose out toward the street.
func _driveways() -> void:
	var near := {}
	for bd in map.buildings:
		var k := Vector2i(floori((bd.r as Rect2).get_center().x / CELL), floori((bd.r as Rect2).get_center().y / CELL))
		if not near.has(k): near[k] = []
		near[k].append(bd.r)
	var car := Vector2(2.4, 5.8)           # drawn size, a little room each side
	for bd in map.buildings:
		if String(bd.kind) != "house": continue
		var r: Rect2 = bd.r
		# which side the street's on
		var up := not map.road_at(Vector2(r.get_center().x, r.position.y - 9.0), 2.0).is_empty()
		var down := not map.road_at(Vector2(r.get_center().x, r.end.y + 9.0), 2.0).is_empty()
		if up == down: continue
		var x := r.end.x + 0.4 + car.x / 2.0
		var y := r.position.y + car.y / 2.0 - 2.4 if up else r.end.y - car.y / 2.0 + 2.4
		var spot := Rect2(Vector2(x, y) - car / 2.0, car)
		var ok := true
		var k2 := Vector2i(floori(x / CELL), floori(y / CELL))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for o: Rect2 in near.get(k2 + Vector2i(dx, dy), []):
					if o.intersects(spot): ok = false
		if not ok or not map.road_at(spot.get_center(), 0.5).is_empty(): continue
		var z := map.zone_at(spot.get_center())
		_add(spot.get_center(), -PI / 2.0 if up else PI / 2.0, "driveway", String(z.get("style", "residential")))

## Every stall of the striped lots (not Covington's customer spots, not the impound lot), and
## the truck stop's apron for the semis.
func _lots() -> void:
	for l in map.lots:
		var r: Rect2 = l.r
		if String(l.kind) != "asphalt": continue
		if String(l.name).contains("COVINGTON") or r.intersects(MapData.IMPOUND_LOT): continue
		var lot := "mall" if r.intersects(Rect2(6600, 1200, 160, 140)) else ("casino" if r.intersects(Rect2(5270, 700, 110, 64)) else "lot")
		if r.intersects(Rect2(3510, 1960, 100, 70)):
			for i in 4: _add(Vector2(r.position.x + 18.0 + i * 9.0, r.position.y + 14.0), PI / 2.0, "semi", "rural", "truckstop")
			continue
		if not l.lines: continue
		var z := map.zone_at(r.get_center())
		var style := String(z.get("style", "commercial"))
		for x in range(int(r.position.x) + 3, int(r.end.x) - 4, 3):
			_add(Vector2(float(x) + 1.5, r.position.y + 3.6), -PI / 2.0, "stall", style, lot)
			if r.size.y > 16: _add(Vector2(float(x) + 1.5, r.end.y - 3.6), PI / 2.0, "stall", style, lot)

# ------------------------------------------------------------------ who's parked, when

## How likely a spot is to have a car in it right now.
func odds(sp: Dictionary, hour: float) -> float:
	var night := hour < 6.5 or hour > 21.0
	var day := hour > 8.0 and hour < 18.5
	match String(sp.kind):
		"curb":
			match String(sp.style):
				"downtown": return 0.75 if day else (0.4 if not night else 0.25)
				"oldtown": return 0.55
				"village": return 0.25
			return 0.3 if day else 0.5
		"driveway": return 0.45 if day else 0.85
		"semi": return 0.6 if night else 0.35
		"stall":
			match String(sp.lot):
				"mall": return 0.55 if day else (0.25 if not night else 0.03)
				"casino": return 0.4 if day else 0.75
			return 0.5 if day else 0.12
	return 0.3

# ------------------------------------------------------------------ the frame

func step(dt: float, cam_m: Vector2) -> void:
	for k in live:
		for c: ParkedCar in live[k]:
			if c.state != "parked" or not c.view.still: c.drive(dt)
	_t -= dt
	if _t > 0.0: return
	_t = 0.3
	if not enabled:
		if not live.is_empty(): clear()
		return
	# let the far cells go
	for k in live.keys():
		var centre := (Vector2(k) + Vector2(0.5, 0.5)) * CELL
		if centre.distance_to(cam_m) > FAR:
			for c: ParkedCar in live[k]:
				traffic.parked.erase(c)
				c.queue_free()
			live.erase(k)
			pads.erase(k)
			queue_redraw()
	# park the near ones
	var budget := PER_STEP
	var k0 := Vector2i(floori((cam_m.x - NEAR) / CELL), floori((cam_m.y - NEAR) / CELL))
	var k1 := Vector2i(floori((cam_m.x + NEAR) / CELL), floori((cam_m.y + NEAR) / CELL))
	for y in range(k0.y, k1.y + 1):
		for x in range(k0.x, k1.x + 1):
			var k := Vector2i(x, y)
			if live.has(k) or not spots.has(k): continue
			if budget <= 0: return
			budget -= _fill(k)

## Parks a cell's cars; returns how many.
func _fill(k: Vector2i) -> int:
	var out: Array = []
	var pd: Array = []
	var hour: float = drive.sky.time_h
	var winter: bool = drive.sky.season == "winter"
	var r := RandomNumberGenerator.new()
	for sp: Dictionary in spots[k]:
		# the same car in the same spot all day; a different one tomorrow
		r.seed = int(sp.seed) + int(drive.sky.day) * 104729
		if r.randf() > odds(sp, hour): continue
		if traffic.hush.has_point(sp.p): continue
		var body: Dictionary
		if String(sp.kind) == "semi":
			body = CarCatalog.traffic_car(Traffic._fleet_id("tractor", r), r, "rural")
		else:
			body = CarCatalog.random_traffic(r, String(sp.style))
		if body.is_empty(): continue
		body.looks = Traffic.dress(body, r, String(sp.style), winter, 12.0)
		var c := ParkedCar.new()
		c.rng.seed = r.randi()
		c.park(traffic, body, sp.p, float(sp.h) + (PI if String(sp.kind) == "curb" and r.randf() < 0.08 else 0.0))
		drive.ysort.add_child(c)
		traffic.parked.append(c)
		out.append(c)
		if String(sp.kind) == "driveway": pd.append([sp.p, float(sp.h)])
	live[k] = out
	if not pd.is_empty():
		pads[k] = pd
		queue_redraw()
	return maxi(1, out.size())

## Every parked car gone (a story scene, a test that wants the streets bare).
func clear() -> void:
	for k in live:
		for c: ParkedCar in live[k]:
			traffic.parked.erase(c)
			c.queue_free()
	live.clear()
	pads.clear()
	queue_redraw()

## The concrete under the driveway cars, out to the sidewalk.
func _draw() -> void:
	var snow: float = drive.sky.snow_cover
	var col := Color("8e8a82").lerp(Color("dfe3e8"), clampf(snow * 1.2, 0.0, 1.0))
	for k in pads:
		for pd: Array in pads[k]:
			var c: Vector2 = pd[0]
			var h: float = pd[1]
			draw_set_transform(c * PX, h, Vector2.ONE)
			draw_rect(Rect2(Vector2(-4.2, -1.6) * PX, Vector2(9.4, 3.2) * PX), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
