## The cars nobody's driving: parked along the town streets, in the driveways beside the houses,
## in the stalls of the lots, semis resting at the truck stop. So the town looks lived in.
##
## The spots come from the map once (a parking bay along both curbs of every town street, cut
## into the wide sidewalk so a parked car sits clear of the lane, away from the junctions, the
## driveways and whatever stands on the sidewalk; a driveway beside each house with room for one;
## every stall of the striped lots) and are kept by 64 m cell. A spot takes a car that fits it,
## and never one that would touch a car already parked nearby. Cells near the camera get their cars
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
const BAY := 7.6                  # a curb bay's length, m
const BAY_DEEP := 2.3             # and how far it's cut into the sidewalk
## The longest car (catalogue metres, before CAR_SCALE) each kind of spot takes.
const FITS := { "curb": 5.6, "stall": 5.6, "driveway": 5.4, "semi": 99.0 }

var drive: Node
var map: MapData
var traffic: Traffic
var enabled := true
var spots := {}                   # Vector2i -> Array of spots: { p, h, kind, style, seed, lot }
var live := {}                    # Vector2i -> Array of ParkedCar
var pads := {}                    # Vector2i -> Array of [centre, heading] driveway pads to draw
var bays := {}                    # Vector2i -> Array of [centre, heading, depth] curb bays to draw
var boxes := {}                   # Vector2i -> Array of [centre, heading, half size] of the cars parked there
var _blds := {}                   # Vector2i -> Array of building Rect2s (for laying out the spots)
var _t := 0.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	map = drive.world.map
	traffic = drive.traffic
	z_index = -3994                # on the ground, under the skid marks and the cars
	z_as_relative = false
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for bd in map.buildings:
		var r: Rect2 = bd.r
		var k := Vector2i(floori(r.get_center().x / CELL), floori(r.get_center().y / CELL))
		if not _blds.has(k): _blds[k] = []
		_blds[k].append(r)
	_curbs()
	_driveways()
	_lots()
	_clear_driveways()

# ------------------------------------------------------------------ where they go

func _add(p: Vector2, h: float, kind: String, style: String, lot := "") -> void:
	var k := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	if not spots.has(k): spots[k] = []
	spots[k].append({ "p": p, "h": h, "kind": kind, "style": style, "seed": absi(int(p.x * 131.0) * 7919 + int(p.y * 71.0)), "lot": lot })

## Both curbs of every street in town, a bay's length apart, clear of the junctions, the
## crossings, the bridges and the poles and signs on the sidewalk. The bay is cut into the
## sidewalk (the town's sidewalks are wide: their outer edge is where an 11 m street's was), so a
## parked car's inside wheels sit on the road's edge and the lane beside it stays clear.
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
			var band := 2.5 + maxf(0.0, 11.0 - float(r.w)) / 2.0
			var deep := clampf(band - 1.0, 1.4, BAY_DEEP)
			var s := 7.0
			while s < L - 7.0:
				var c := a + d * s
				s += BAY
				var z := map.zone_at(c)
				var style := String(z.get("style", ""))
				if not style in ["downtown", "residential", "oldtown", "village"]: continue
				if not _clear_curb(c): continue
				for side: float in [-1.0, 1.0]:
					var p := c + right * side * (float(r.w) / 2.0 + deep / 2.0)
					if _near_furniture(p) or not map.lot_at(p).is_empty(): continue
					if not _bay_clear(r, p, d): continue
					# parked facing the way that side of the street drives
					_add(p, (d * side).angle(), "curb", style)
					var k := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
					if not bays.has(k): bays[k] = []
					bays[k].append([p, d.angle(), deep])

func _clear_curb(c: Vector2) -> bool:
	for n in traffic._near_nodes(c, 0.0, 20.0):
		if map.g_adj[n].size() != 2: return false
	if map.rail_near(c, 12.0) or map.river_at(c) > 0: return false
	for br in map.bridges:
		if MapData.seg_dist(c, br.a, br.b) < 14.0: return false
	return true

## A bay whose car, and half a car past either end, stays off every other road (the mouth of a
## side street, the main street's curb at a T) and out of the buildings (the arena comes right
## out to the sidewalk).
func _bay_clear(r: Dictionary, p: Vector2, d: Vector2) -> bool:
	var reach := BAY / 2.0 + 2.6
	for t: float in [-reach, -BAY / 2.0, 0.0, BAY / 2.0, reach]:
		var rd := map.road_at(p + d * t, 1.0)
		if not rd.is_empty() and not is_same(rd.road, r): return false
	var n := d.orthogonal() * (BAY_DEEP / 2.0 + 0.3)
	var a := d * (BAY / 2.0)
	var bay := PackedVector2Array([p + a + n, p + a - n, p - a - n, p - a + n])
	var k := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for b: Rect2 in _blds.get(k + Vector2i(dx, dy), []):
				var poly := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y)])
				if not Geometry2D.intersect_polygons(bay, poly).is_empty(): return false
	return true

## No curb bay across the mouth of a driveway.
func _clear_driveways() -> void:
	for k in spots:
		var keep: Array = []
		for sp: Dictionary in spots[k]:
			if String(sp.kind) != "curb" or not _blocks_driveway(sp.p, k): keep.append(sp)
		spots[k] = keep
	for k2 in bays:
		var keep2: Array = []
		for b: Array in bays[k2]:
			if not _blocks_driveway(b[0], k2): keep2.append(b)
		bays[k2] = keep2

func _blocks_driveway(p: Vector2, k: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for sp: Dictionary in spots.get(k + Vector2i(dx, dy), []):
				if String(sp.kind) != "driveway": continue
				var out := Vector2.from_angle(float(sp.h))
				if MapData.seg_dist(p, sp.p, (sp.p as Vector2) + out * 14.0) < BAY / 2.0 + 1.5: return true
	return false

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
			boxes.erase(k)
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
	var winter: bool = drive.sky.season == "winter"
	for pk: Array in pick(k, drive.sky.time_h, int(drive.sky.day)):
		var sp: Dictionary = pk[0]
		var body: Dictionary = pk[1]
		var r: RandomNumberGenerator = pk[3]
		body.looks = Traffic.dress(body, r, String(sp.style), winter, 12.0)
		var c := ParkedCar.new()
		c.rng.seed = r.randi()
		c.park(traffic, body, sp.p, float(pk[2]))
		drive.ysort.add_child(c)
		traffic.parked.append(c)
		out.append(c)
		if String(sp.kind) == "driveway": pd.append([sp.p, float(sp.h)])
	live[k] = out
	if not pd.is_empty(): pads[k] = pd
	queue_redraw()
	return maxi(1, out.size())

## Who's parked in a cell at this hour of this day: [spot, body, heading, its dice] for each car,
## each one a car that fits its spot and clear of every car already parked around it (`every`
## fills every spot whatever the hour: the tests).
func pick(k: Vector2i, hour: float, day: int, every := false) -> Array:
	var out: Array = []
	for sp: Dictionary in spots.get(k, []):
		# the same car in the same spot all day; a different one tomorrow
		var r := RandomNumberGenerator.new()
		r.seed = int(sp.seed) + day * 104729
		if r.randf() > odds(sp, hour) and not every: continue
		if traffic.hush.has_point(sp.p): continue
		var body: Dictionary
		if String(sp.kind) == "semi":
			body = CarCatalog.traffic_car(Traffic._fleet_id("tractor", r), r, "rural")
		else:
			# nothing longer than the bay or the stall, no box trucks
			for _try in 4:
				body = CarCatalog.random_traffic(r, String(sp.style))
				if fits(body, String(sp.kind)): break
				body = {}
		if body.is_empty(): continue
		var h := float(sp.h) + (PI if String(sp.kind) == "curb" and r.randf() < 0.08 else 0.0)
		var box := [sp.p, h, Vector2(float(body.length), float(body.width)) * CarArt.CAR_SCALE / 2.0]
		if _touches(box, k): continue
		if not boxes.has(k): boxes[k] = []
		boxes[k].append(box)
		out.append([sp, body, h, r])
	return out

## Whether a body fits a kind of spot: short enough for it, and not a box truck or a bus.
static func fits(body: Dictionary, kind: String) -> bool:
	if body.is_empty(): return false
	if kind != "semi" and String(body.get("body", "")) in ["boxtruck", "bus", "semi"]: return false
	return float(body.get("length", 4.5)) <= float(FITS.get(kind, 5.6))

## True when a car's rectangle ([centre, heading, half size], m) would touch one already parked
## in its cell or the cells around it.
func _touches(box: Array, k: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for o: Array in boxes.get(k + Vector2i(dx, dy), []):
				if boxes_touch(box, o): return true
	return false

## Two rotated rectangles [centre, heading, half size] overlap (separating axes).
static func boxes_touch(a: Array, b: Array) -> bool:
	var ca: Vector2 = a[0]
	var cb: Vector2 = b[0]
	var ha: Vector2 = a[2]
	var hb: Vector2 = b[2]
	if ca.distance_to(cb) > ha.length() + hb.length(): return false
	var fa := Vector2.from_angle(float(a[1]))
	var fb := Vector2.from_angle(float(b[1]))
	for ax: Vector2 in [fa, fa.orthogonal(), fb, fb.orthogonal()]:
		var ra := absf(fa.dot(ax)) * ha.x + absf(fa.orthogonal().dot(ax)) * ha.y
		var rb := absf(fb.dot(ax)) * hb.x + absf(fb.orthogonal().dot(ax)) * hb.y
		if absf((cb - ca).dot(ax)) > ra + rb: return false
	return true

## Every parked car gone (a story scene, a test that wants the streets bare).
func clear() -> void:
	for k in live:
		for c: ParkedCar in live[k]:
			traffic.parked.erase(c)
			c.queue_free()
	live.clear()
	pads.clear()
	boxes.clear()
	queue_redraw()

## The concrete under the driveway cars, out to the sidewalk; the curb bays near the camera,
## asphalt cut into the sidewalk with a painted tick at each end.
func _draw() -> void:
	var snow: float = drive.sky.snow_cover
	var col := Color("8e8a82").lerp(Color("dfe3e8"), clampf(snow * 1.2, 0.0, 1.0))
	var tex: Texture2D = drive.world.asphalt
	var tint: Color = drive.world.asphalt_tint()
	var tick := Color(0.92, 0.92, 0.88, 0.8 * (1.0 - clampf(snow * 1.5, 0.0, 1.0)))
	for k in live:
		for b: Array in bays.get(k, []):
			draw_set_transform((b[0] as Vector2) * PX, float(b[1]), Vector2.ONE)
			var half := Vector2(BAY, float(b[2])) * PX / 2.0
			draw_texture_rect(tex, Rect2(-half, half * 2.0), true, tint)
			for e: float in [-1.0, 1.0]:
				draw_rect(Rect2(Vector2(e * half.x - 1.0, -half.y), Vector2(2.0, half.y * 2.0)), tick)
	for k in pads:
		for pd: Array in pads[k]:
			var c: Vector2 = pd[0]
			var h: float = pd[1]
			draw_set_transform(c * PX, h, Vector2.ONE)
			draw_rect(Rect2(Vector2(-4.2, -1.6) * PX, Vector2(9.4, 3.2) * PX), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
