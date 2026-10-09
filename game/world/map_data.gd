## The map: Port Rumble (our Moncton) out to Salisbury and Havelock, along the Petitcodiac.
##
## Laid out from the real geography at about 1:8 (towns and roads where they really are,
## relative to each other), with the city streets at full size. Everything is data here:
## roads as polylines, the river, the rail line, zones, lots, buildings, landmarks and lights.
## No drawing. The world streams it in chunks; the GPS and the tests read it too.
##
## Units are metres. x = east, y = south (screen-down).
class_name MapData
extends RefCounted

const BOUNDS := Rect2(0, 0, 7000, 3300)
const CELL := 32.0                       # spatial index cell (metres)

# road classes: width (m), shoulder, lane markings, plowed first in winter
const CLS := {
	"highway":  { "w": 26.0, "shoulder": 3.0, "rank": 5 },
	"arterial": { "w": 16.0, "shoulder": 0.0, "rank": 4 },
	"street":   { "w": 11.0, "shoulder": 0.0, "rank": 2 },
	"rural":    { "w": 9.0,  "shoulder": 2.5, "rank": 3 },
	"gravel":   { "w": 7.0,  "shoulder": 0.0, "rank": 1 },
	"ramp":     { "w": 8.0,  "shoulder": 1.5, "rank": 3 },
}

# what each zone looks like, and what lights its streets
const ZONES := [
	{ "id": "downtown", "r": Rect2(5750, 1380, 560, 200), "light": "led", "style": "downtown", "label": "DOWNTOWN" },
	{ "id": "covington", "r": Rect2(5440, 1440, 280, 200), "light": "sodium", "style": "oldtown", "label": "COVINGTON CORNER" },
	{ "id": "northend", "r": Rect2(5690, 1090, 620, 290), "light": "sodium", "style": "residential", "label": "NORTH END" },
	{ "id": "riverside", "r": Rect2(5540, 1775, 600, 220), "light": "led", "style": "residential", "label": "RIVERSIDE" },
	{ "id": "dieppe", "r": Rect2(6340, 1180, 460, 280), "light": "led", "style": "commercial", "label": "DIEPPE" },
	{ "id": "industrial", "r": Rect2(6140, 880, 420, 200), "light": "sodium", "style": "industrial", "label": "NORTHSIDE INDUSTRIAL" },
	{ "id": "magnet", "r": Rect2(4960, 680, 420, 230), "light": "led", "style": "rural", "label": "MAGNET HILL" },
	{ "id": "salisbury", "r": Rect2(3280, 2060, 320, 200), "light": "sodium", "style": "village", "label": "SALISBURY" },
	{ "id": "havelock", "r": Rect2(640, 2640, 320, 230), "light": "mercury", "style": "village", "label": "HAVELOCK" },
]

var roads: Array = []           # { name, cls, pts: PackedVector2Array, w, zone, limited }
var lots: Array = []            # { r: Rect2, kind: "asphalt"|"gravel"|"runway"|"park", name, lines }
var buildings: Array = []       # { r: Rect2, h, kind, name, neon, zone }
var lights: Array = []          # { p, type, seed }
var landmarks: Array = []       # { name, p, dest }
var river_pts: PackedVector2Array
var river_hw: PackedFloat32Array
var rail_pts: PackedVector2Array
var crossings: Array = []       # rail level crossings: { p, road }
var bridges: Array = []         # { a, b, w } road decks over the river
var interchanges: Array[Vector2] = []
var grid_cells: Array = []      # { r: Rect2, style, zone, reserved }

var _road_index := {}           # Vector2i -> Array of [road, seg]
var _river_index := {}
var noise := FastNoiseLite.new()
var field_noise := FastNoiseLite.new()

# graph for the GPS: nodes and edges
var g_pos: Array[Vector2] = []
var g_adj: Array = []           # node -> Array of [node, length, road]
var _g_key := {}

static var _inst: MapData

static func get_map() -> MapData:
	if _inst == null:
		_inst = MapData.new()
		_inst.build()
	return _inst

func build() -> void:
	noise.seed = 506
	noise.frequency = 0.004
	field_noise.seed = 1867
	field_noise.frequency = 0.0035
	_river()
	_rail()
	_highways()
	_city_grids()
	_villages()
	_landmarks()
	_index_roads()
	_find_bridges_and_crossings()
	_buildings()
	_street_lights()
	_graph()

# ------------------------------------------------------------------ geography

func _river() -> void:
	# the Petitcodiac: a creek at Havelock's edge, wide and brown by the time it bends at Port Rumble
	var p := [Vector2(2700, 2330), Vector2(3050, 2265), Vector2(3420, 2225), Vector2(3800, 2120), Vector2(4300, 2010),
		Vector2(4800, 1890), Vector2(5300, 1765), Vector2(5650, 1690), Vector2(5950, 1650), Vector2(6250, 1625),
		Vector2(6550, 1680), Vector2(6800, 1850), Vector2(7050, 2080)]
	var w := [10.0, 14.0, 18.0, 26.0, 34.0, 42.0, 55.0, 70.0, 75.0, 80.0, 95.0, 120.0, 150.0]
	river_pts = PackedVector2Array(p)
	river_hw = PackedFloat32Array(w)

func _rail() -> void:
	rail_pts = PackedVector2Array([Vector2(7000, 1240), Vector2(6600, 1235), Vector2(6300, 1275), Vector2(5900, 1340),
		Vector2(5500, 1440), Vector2(5000, 1600), Vector2(4600, 1715), Vector2(4100, 1850), Vector2(3700, 1985),
		Vector2(3420, 2075), Vector2(3050, 2150), Vector2(2650, 2240), Vector2(2000, 2420), Vector2(1400, 2600), Vector2(900, 2690), Vector2(0, 2820)])

func add_road(name: String, cls: String, pts: Array, zone := "", limited := false, wiggle := 0.0) -> Dictionary:
	var pv := PackedVector2Array(pts)
	if wiggle > 0.0: pv = _wiggle(pv, wiggle)
	var r := { "name": name, "cls": cls, "pts": pv, "w": float(CLS[cls].w), "zone": zone, "limited": limited }
	roads.append(r)
	return r

## Country roads aren't ruler-straight: bend them between their control points.
func _wiggle(pts: PackedVector2Array, amp: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var n := maxi(2, int(a.distance_to(b) / 30.0))
		var nrm := (b - a).normalized().orthogonal()
		for k in n:
			var t := float(k) / n
			var q := a.lerp(b, t)
			var off := noise.get_noise_2d(q.x * 0.6, q.y * 0.6) * amp * sin(PI * t)
			out.append(q + nrm * off)
	out.append(pts[pts.size() - 1])
	return out

func _highways() -> void:
	# Route 2, the Trans-Canada: north of the city, then down to Salisbury and on to Petitcodiac
	add_road("TRANS-CANADA HWY", "highway", [Vector2(7000, 1000), Vector2(6600, 900), Vector2(6100, 830), Vector2(5900, 820),
		Vector2(5500, 820), Vector2(5180, 860), Vector2(4700, 1000), Vector2(4300, 1150), Vector2(3950, 1450),
		Vector2(3650, 1800), Vector2(3480, 2050), Vector2(3250, 2350), Vector2(2950, 2750), Vector2(2780, 3300)], "", true)
	interchanges = [Vector2(5900, 820), Vector2(5180, 860), Vector2(4300, 1150), Vector2(3480, 2050), Vector2(6600, 900)]
	# Route 15, Wheeler Blvd: the ring road down to Dieppe
	add_road("WHEELER BLVD", "arterial", [Vector2(5900, 820), Vector2(6150, 1000), Vector2(6350, 1150), Vector2(6500, 1300), Vector2(6600, 1440)])
	# Mountain Road: downtown up to Magnet Hill
	add_road("MOUNTAIN RD", "arterial", [Vector2(5950, 1545), Vector2(5800, 1360), Vector2(5600, 1180), Vector2(5400, 1020), Vector2(5180, 860)])
	# Route 106: Main St through downtown, then Salisbury Rd out along the river
	add_road("MAIN ST", "arterial", [Vector2(7000, 1395), Vector2(6800, 1420), Vector2(6500, 1462), Vector2(6250, 1505), Vector2(6000, 1548),
		Vector2(5700, 1592)], "")
	add_road("SALISBURY RD", "rural", [Vector2(5700, 1592), Vector2(5420, 1640), Vector2(5000, 1730), Vector2(4650, 1790),
		Vector2(4300, 1880), Vector2(4075, 1935), Vector2(3750, 2050), Vector2(3560, 2112)], "", false, 22.0)
	add_road("MAIN ST", "street", [Vector2(3560, 2112), Vector2(3420, 2160), Vector2(3300, 2185)], "salisbury")
	add_road("ROUTE 106", "rural", [Vector2(3440, 2290), Vector2(3250, 2420), Vector2(3000, 2650), Vector2(2880, 3300)], "", false, 25.0)
	# Route 112: Coverdale Rd along the south bank, over the river at Salisbury
	add_road("COVERDALE RD", "rural", [Vector2(6110, 1780), Vector2(5700, 1786), Vector2(5500, 1812), Vector2(5100, 1905),
		Vector2(4600, 2040), Vector2(4100, 2150), Vector2(3700, 2265), Vector2(3440, 2290)], "", false, 20.0)
	add_road("ROUTE 112", "rural", [Vector2(3440, 2290), Vector2(3440, 2160)], "salisbury")
	add_road("ROUTE 112", "rural", [Vector2(3440, 2160), Vector2(3300, 1950), Vector2(3150, 1600), Vector2(3100, 1000), Vector2(3150, 0)], "", false, 30.0)
	# the bridges into Riverside
	add_road("THE CAUSEWAY", "arterial", [Vector2(5700, 1592), Vector2(5700, 1786)])
	add_road("GUNNINGSVILLE BRIDGE", "arterial", [Vector2(6110, 1515), Vector2(6110, 1780)])
	# Route 880 to Havelock, and Route 885 through it
	add_road("ROUTE 880", "rural", [Vector2(3300, 2185), Vector2(2900, 2240), Vector2(2400, 2390), Vector2(1900, 2470),
		Vector2(1500, 2610), Vector2(1100, 2705), Vector2(800, 2750), Vector2(400, 2790), Vector2(0, 2800)], "", false, 35.0)
	add_road("ROUTE 885 - CANAAN RD", "rural", [Vector2(800, 2400), Vector2(803, 2640), Vector2(805, 2750), Vector2(815, 2985), Vector2(820, 3050), Vector2(860, 3300)], "", false, 18.0)
	add_road("ROUTE 885 - CANAAN RD", "rural", [Vector2(800, 2400), Vector2(760, 1800), Vector2(700, 0)], "", false, 30.0)
	# back roads: Lutes Mountain, Irishtown, Boundary Creek
	add_road("LUTES MOUNTAIN RD", "rural", [Vector2(4650, 1790), Vector2(4550, 1450), Vector2(4300, 1150), Vector2(4250, 700), Vector2(4300, 0)], "", false, 26.0)
	add_road("IRISHTOWN RD", "rural", [Vector2(5600, 1180), Vector2(5650, 700), Vector2(5700, 300), Vector2(5750, 0)], "", false, 22.0)
	add_road("BOUNDARY CREEK RD", "gravel", [Vector2(4075, 1935), Vector2(4000, 1600), Vector2(3800, 1350), Vector2(3950, 1450)], "", false, 18.0)
	add_road("BERRY MILLS RD", "gravel", [Vector2(5000, 1730), Vector2(4900, 1350), Vector2(4700, 1000)], "", false, 25.0)
	add_road("SCOTCH SETTLEMENT RD", "gravel", [Vector2(2400, 2390), Vector2(2300, 2000), Vector2(2100, 1500)], "", false, 30.0)
	add_road("PARKINDALE RD", "gravel", [Vector2(1900, 2470), Vector2(2000, 2900), Vector2(2100, 3300)], "", false, 28.0)

func _main_y(x: float) -> float:
	# where Main St / Salisbury Rd is at this x (city part)
	var pts := PackedVector2Array([Vector2(7000, 1395), Vector2(6800, 1420), Vector2(6500, 1462), Vector2(6250, 1505),
		Vector2(6000, 1548), Vector2(5700, 1592), Vector2(5420, 1640)])
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if x <= a.x and x >= b.x:
			return lerpf(a.y, b.y, (a.x - x) / (a.x - b.x))
	return 1600.0

func _south_y(south, x: float) -> float:
	if south is String:
		if south == "salisbury": return lerpf(2185.0, 2112.0, (x - 3300.0) / 260.0)
		return _main_y(x)
	return float(south)

## A street grid: north-south streets from y0 down to `south` (a number or "main"), east-west across.
func _grid(zone: String, xs: Array, ys: Array, south, ns_names: Array, ew_names: Array, style: String, arterial_ns := []) -> void:
	for i in xs.size():
		var x: float = xs[i]
		var y1: float = _south_y(south, x)
		var cls := "arterial" if arterial_ns.has(i) else "street"
		add_road(ns_names[i % ns_names.size()], cls, [Vector2(x, ys[0]), Vector2(x, y1)], zone)
	for j in ys.size():
		add_road(ew_names[j % ew_names.size()], "street", [Vector2(xs[0], ys[j]), Vector2(xs[xs.size() - 1], ys[j])], zone)
	for i in xs.size() - 1:
		for j in ys.size():
			var y0: float = ys[j]
			var yb: float
			if j + 1 < ys.size(): yb = ys[j + 1]
			else: yb = minf(_south_y(south, xs[i]), _south_y(south, xs[i + 1]))
			if yb - y0 < 20.0: continue
			grid_cells.append({ "r": Rect2(xs[i], y0, xs[i + 1] - xs[i], yb - y0), "style": style, "zone": zone, "reserved": false })

func _city_grids() -> void:
	_grid("downtown", [5760, 5830, 5900, 5970, 6040, 6110, 6180, 6250, 6310], [1390, 1445, 1500], "main",
		["LUTZ ST", "ARCHIBALD ST", "VAUGHAN HARVEY BLVD", "BOTSFORD ST", "WELDON ST", "HIGHFIELD ST", "ROBINSON ST", "KING ST", "CHURCH ST"],
		["ST GEORGE BLVD", "QUEEN ST", "JOHN ST"], "downtown", [2])
	_grid("northend", [5700, 5780, 5860, 5940, 6020, 6100, 6180, 6260], [1110, 1180, 1250, 1320], 1390,
		["CAMERON ST", "GORDON ST", "PARK ST", "STEADMAN ST", "MCBEATH AVE", "PRINCE ST", "DOMINION ST", "CHESTER ST"],
		["MORTON AVE", "ELMWOOD DR", "CLOVERDALE ST", "MCSWEENEY AVE"], "residential")
	_grid("covington", [5460, 5540, 5620, 5700], [1460, 1520], "main",
		["MILL RD", "COVINGTON AVE", "HARBOUR RD", "WEST ST"], ["NORTH ST", "CORNER ST"], "oldtown")
	_grid("riverside", [5560, 5640, 5720, 5800, 5880, 5960, 6040, 6120], [1850, 1910, 1970], 1990,
		["PINE GLEN RD", "FINDLAY BLVD", "WHITEPINE RD", "BRIDGEDALE BLVD", "MANNING ST", "RUSSELL ST", "GILES ST", "CORONATION ST"],
		["CLEVELAND AVE", "HILLCREST DR", "TRITES RD"], "residential")
	# Riverside streets run up to Coverdale Rd
	for x in [5560, 5640, 5720, 5800, 5880, 5960, 6040, 6120]:
		add_road("", "street", [Vector2(x, 1850), Vector2(x, 1786 + (5700 - x) * 0.0 if x <= 5700 else 1784.0)], "riverside")
	_grid("dieppe", [6360, 6440, 6520, 6600, 6770], [1200, 1270, 1340], "main",
		["CHAMPLAIN ST", "PAUL ST", "AMIRAULT ST", "ACADIE AVE", "GAUVIN RD"],
		["DIEPPE BLVD", "GAETAN ST", "MELANSON RD"], "commercial")
	_grid("industrial", [6160, 6280, 6400, 6520], [900, 980, 1060], 1100,
		["URQUHART AVE", "MAPLETON RD", "TRADE ST", "FOUNDRY ST"], ["INDUSTRIAL DR", "SNOW AVE", "WORKS RD"], "industrial")

func _villages() -> void:
	_grid("salisbury", [3320, 3380, 3440, 3500, 3560], [2060, 2105], "salisbury",
		["FREDERICTON RD", "LEWIS ST", "MAPLE ST", "CHURCH ST", "STATION ST"], ["PARK ST", "SCHOOL ST"], "village")
	add_road("ROUTE 106 CONNECTOR", "ramp", [Vector2(3480, 2050), Vector2(3500, 2080)], "salisbury")
	# Havelock: a crossroads, a church, a store, the airfield and the lime quarry
	add_road("CHURCH ST", "street", [Vector2(700, 2700), Vector2(910, 2700)], "havelock")
	add_road("SCHOOL ST", "street", [Vector2(700, 2810), Vector2(910, 2810)], "havelock")
	add_road("FAIRWAY LN", "street", [Vector2(700, 2700), Vector2(700, 2810)], "havelock")
	add_road("AIRFIELD RD", "gravel", [Vector2(803, 2640), Vector2(700, 2610), Vector2(620, 2610)], "havelock")
	add_road("QUARRY RD", "gravel", [Vector2(815, 2985), Vector2(950, 2975), Vector2(1020, 2960)], "", false, 10.0)
	grid_cells.append({ "r": Rect2(700, 2700, 210, 110), "style": "village", "zone": "havelock", "reserved": false })

func _landmarks() -> void:
	# Covington Auto: the garage, the lot, the sign
	_reserve(Rect2(5540, 1520, 80, 84))
	lots.append({ "r": Rect2(5546, 1560, 70, 34), "kind": "asphalt", "name": "COVINGTON AUTO - CUSTOMERS ONLY", "lines": true })
	buildings.append({ "r": Rect2(5548, 1526, 44, 30), "h": 9.0, "kind": "garage", "name": "COVINGTON AUTO", "zone": "covington" })
	buildings.append({ "r": Rect2(5596, 1528, 20, 26), "h": 7.0, "kind": "shop", "name": "PARTS", "zone": "covington" })
	lights.append({ "p": Vector2(5560, 1596), "type": "sodium", "seed": 1 })
	lights.append({ "p": Vector2(5600, 1560), "type": "sodium_flicker", "seed": 2 })
	landmarks.append({ "name": "COVINGTON AUTO", "p": Vector2(5580, 1577), "dest": true })
	# downtown: the arena, Tidal Bore Park, a Tim Burtons on every corner
	_reserve(Rect2(5970, 1445, 70, 55))
	buildings.append({ "r": Rect2(5976, 1452, 58, 42), "h": 22.0, "kind": "arena", "name": "RUMBLE CENTRE", "zone": "downtown" })
	lights.append({ "p": Vector2(5976, 1497), "type": "led_flood", "seed": 3 })
	lights.append({ "p": Vector2(6034, 1497), "type": "led_flood", "seed": 4 })
	landmarks.append({ "name": "RUMBLE CENTRE", "p": Vector2(6005, 1505), "dest": true })
	lots.append({ "r": Rect2(5850, 1560, 70, 26), "kind": "park", "name": "TIDAL BORE PARK", "lines": false })
	landmarks.append({ "name": "TIDAL BORE PARK", "p": Vector2(5885, 1568), "dest": true })
	for x in [5856, 5884, 5912]: lights.append({ "p": Vector2(x, 1584), "type": "lamp", "seed": x })
	_tims(Vector2(6145, 1472), "downtown")
	_tims(Vector2(5470, 1120), "")
	_tims(Vector2(3350, 2125), "salisbury")
	# Magnet Hill: the hill where cars roll uphill, the casino, the zoo
	add_road("MAGNET HILL RD", "street", [Vector2(5180, 860), Vector2(5100, 820), Vector2(5040, 770), Vector2(5000, 720)], "magnet")
	add_road("CASINO DR", "street", [Vector2(5180, 860), Vector2(5260, 800), Vector2(5300, 770)], "magnet")
	lots.append({ "r": Rect2(5270, 700, 110, 64), "kind": "asphalt", "name": "", "lines": true })
	buildings.append({ "r": Rect2(5290, 660, 80, 38), "h": 16.0, "kind": "casino", "name": "CASINO RUMBLE", "zone": "magnet" })
	for i in 5: lights.append({ "p": Vector2(5280 + i * 22, 700), "type": "casino", "seed": i })
	for i in 3: lights.append({ "p": Vector2(5285 + i * 40, 735), "type": "led", "seed": 30 + i })
	lots.append({ "r": Rect2(4960, 690, 60, 40), "kind": "gravel", "name": "ZOO PARKING", "lines": false })
	buildings.append({ "r": Rect2(4970, 660, 40, 24), "h": 6.0, "kind": "shop", "name": "ZOO", "zone": "magnet" })
	landmarks.append({ "name": "MAGNET HILL", "p": Vector2(5060, 790), "dest": true })
	landmarks.append({ "name": "CASINO RUMBLE", "p": Vector2(5320, 730), "dest": true })
	# Champagne Place: the mall in Dieppe, and the biggest empty parking lot in the province after 10 p.m.
	_reserve(Rect2(6600, 1200, 160, 140))
	lots.append({ "r": Rect2(6606, 1250, 148, 86), "kind": "asphalt", "name": "", "lines": true })
	buildings.append({ "r": Rect2(6610, 1206, 140, 40), "h": 12.0, "kind": "mall", "name": "CHAMPAGNE PLACE", "zone": "dieppe" })
	for i in 4:
		for j in 2: lights.append({ "p": Vector2(6630 + i * 34, 1272 + j * 40), "type": "led", "seed": 40 + i * 2 + j })
	landmarks.append({ "name": "CHAMPAGNE PLACE", "p": Vector2(6680, 1300), "dest": true })
	# Northside Industrial and the old airport: Airstrip 7
	lots.append({ "r": Rect2(6600, 1010, 340, 24), "kind": "runway", "name": "7", "lines": true })
	add_road("AIRSTRIP RD", "street", [Vector2(6520, 1060), Vector2(6600, 1040), Vector2(6620, 1034)], "industrial")
	for x in range(6610, 6940, 40):
		lights.append({ "p": Vector2(x, 1008), "type": "runway", "seed": x })
		lights.append({ "p": Vector2(x, 1036), "type": "runway", "seed": x + 1 })
	landmarks.append({ "name": "AIRSTRIP 7", "p": Vector2(6640, 1022), "dest": true })
	# the Big Stop at the Salisbury exit: diesel, fries, truckers
	lots.append({ "r": Rect2(3510, 1960, 100, 70), "kind": "asphalt", "name": "", "lines": false })
	buildings.append({ "r": Rect2(3560, 1966, 44, 22), "h": 7.0, "kind": "shop", "name": "THE BIG STOP", "zone": "" })
	add_road("BIG STOP RD", "ramp", [Vector2(3480, 2050), Vector2(3530, 2000)], "")
	for i in 3: lights.append({ "p": Vector2(3522 + i * 14, 2004), "type": "canopy", "seed": i })
	landmarks.append({ "name": "THE BIG STOP", "p": Vector2(3540, 2010), "dest": true })
	landmarks.append({ "name": "SALISBURY", "p": Vector2(3440, 2120), "dest": true })
	# gas bars
	_gas(Rect2(5640, 1210, 44, 34), "GAS BAR", "")
	_gas(Rect2(6420, 1420, 44, 30), "ULTRAMARGE", "dieppe")
	_gas(Rect2(3580, 2060, 40, 28), "GAS BAR", "salisbury")
	# the Lutes Mountain towers: red lights you can see from everywhere
	for i in 3:
		var tp := Vector2(4360 + i * 40, 1040 + i * 18)
		lights.append({ "p": tp, "type": "aviation", "seed": i })
		buildings.append({ "r": Rect2(tp - Vector2(2, 2), Vector2(4, 4)), "h": 40.0, "kind": "tower", "name": "", "zone": "" })
	# Havelock
	lots.append({ "r": Rect2(520, 2590, 280, 22), "kind": "runway", "name": "HAVELOCK", "lines": false })
	landmarks.append({ "name": "HAVELOCK AIRFIELD", "p": Vector2(640, 2600), "dest": true })
	lots.append({ "r": Rect2(1000, 2900, 200, 130), "kind": "gravel", "name": "", "lines": false })
	buildings.append({ "r": Rect2(1150, 2910, 40, 26), "h": 14.0, "kind": "plant", "name": "LIME", "zone": "" })
	lights.append({ "p": Vector2(1140, 2940), "type": "sodium", "seed": 9 })
	lights.append({ "p": Vector2(1060, 2960), "type": "sodium", "seed": 10 })
	landmarks.append({ "name": "LIME QUARRY", "p": Vector2(1060, 2960), "dest": true })
	landmarks.append({ "name": "HAVELOCK", "p": Vector2(805, 2755), "dest": true })
	buildings.append({ "r": Rect2(720, 2716, 30, 20), "h": 12.0, "kind": "church", "name": "", "zone": "havelock" })
	buildings.append({ "r": Rect2(820, 2716, 28, 18), "h": 6.0, "kind": "shop", "name": "GENERAL STORE", "zone": "havelock" })
	lights.append({ "p": Vector2(834, 2738), "type": "neon", "seed": 77 })
	landmarks.append({ "name": "RIVERSIDE", "p": Vector2(5840, 1880), "dest": true })
	landmarks.append({ "name": "DIEPPE", "p": Vector2(6500, 1300), "dest": false })

func _tims(p: Vector2, zone: String) -> void:
	var r := Rect2(p - Vector2(14, 14), Vector2(28, 28))
	_reserve(r)
	buildings.append({ "r": Rect2(p - Vector2(10, 10), Vector2(18, 14)), "h": 6.0, "kind": "coffee", "name": "TIM BURTONS", "zone": zone })
	lots.append({ "r": Rect2(p + Vector2(-14, 5), Vector2(28, 9)), "kind": "asphalt", "name": "", "lines": false })
	lights.append({ "p": p + Vector2(0, 5), "type": "neon_red", "seed": int(p.x) })
	landmarks.append({ "name": "TIM BURTONS", "p": p, "dest": false })

func _gas(r: Rect2, name: String, zone: String) -> void:
	_reserve(r)
	lots.append({ "r": r, "kind": "asphalt", "name": "", "lines": false })
	buildings.append({ "r": Rect2(r.position + Vector2(r.size.x - 14, 2), Vector2(12, 10)), "h": 5.0, "kind": "shop", "name": name, "zone": zone })
	buildings.append({ "r": Rect2(r.position + Vector2(4, r.size.y * 0.45), Vector2(r.size.x * 0.55, 3)), "h": 1.0, "kind": "pumps", "name": "", "zone": zone })
	for i in 2: lights.append({ "p": r.position + Vector2(8 + i * 14, r.size.y * 0.5), "type": "canopy", "seed": int(r.position.x) + i })

func _reserve(r: Rect2) -> void:
	for c in grid_cells:
		if c.r.intersects(r): c.reserved = true

# ------------------------------------------------------------------ queries

func zone_at(m: Vector2) -> Dictionary:
	for z in ZONES:
		if z.r.has_point(m): return z
	return { "id": "", "light": "", "style": "rural", "label": "" }

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001: return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func seg_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Variant:
	var r := b - a
	var s := d - c
	var den := r.cross(s)
	if absf(den) < 0.0001: return null
	var t := (c - a).cross(s) / den
	var u := (c - a).cross(r) / den
	if t < -0.001 or t > 1.001 or u < -0.001 or u > 1.001: return null
	return a + r * t

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))

func _index_roads() -> void:
	_road_index = {}
	for ri in roads.size():
		var r: Dictionary = roads[ri]
		var pts: PackedVector2Array = r.pts
		var pad: float = r.w / 2.0 + float(CLS[r.cls].shoulder) + 2.0
		for si in pts.size() - 1:
			var a := pts[si]
			var b := pts[si + 1]
			var c0 := _cell(Vector2(minf(a.x, b.x) - pad, minf(a.y, b.y) - pad))
			var c1 := _cell(Vector2(maxf(a.x, b.x) + pad, maxf(a.y, b.y) + pad))
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var k := Vector2i(cx, cy)
					if not _road_index.has(k): _road_index[k] = []
					_road_index[k].append([ri, si])
	_river_index = {}
	for si in river_pts.size() - 1:
		var a := river_pts[si]
		var b := river_pts[si + 1]
		var pad := maxf(river_hw[si], river_hw[si + 1]) + 14.0
		var c0 := _cell(Vector2(minf(a.x, b.x) - pad, minf(a.y, b.y) - pad))
		var c1 := _cell(Vector2(maxf(a.x, b.x) + pad, maxf(a.y, b.y) + pad))
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var k := Vector2i(cx, cy)
				if not _river_index.has(k): _river_index[k] = []
				_river_index[k].append(si)

## The road at this point, if any: { road, dist, seg, edge (0 = centre, 1 = edge of asphalt) }
func road_at(m: Vector2, extra := 0.0) -> Dictionary:
	var best := {}
	var best_d := INF
	for e in _road_index.get(_cell(m), []):
		var r: Dictionary = roads[e[0]]
		var pts: PackedVector2Array = r.pts
		var d := seg_dist(m, pts[e[1]], pts[e[1] + 1])
		var lim: float = r.w / 2.0 + extra
		if d <= lim and d / (r.w / 2.0) < best_d:
			best_d = d / (r.w / 2.0)
			best = { "road": r, "dist": d, "seg": e[1], "edge": d / (r.w / 2.0) }
	return best

## Nearest road within `radius` (for the GPS street name and respawning).
func nearest_road(m: Vector2, radius := 60.0) -> Dictionary:
	var best := {}
	var best_d := radius
	var c0 := _cell(m - Vector2(radius, radius))
	var c1 := _cell(m + Vector2(radius, radius))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for e in _road_index.get(Vector2i(cx, cy), []):
				var r: Dictionary = roads[e[0]]
				var pts: PackedVector2Array = r.pts
				var a := pts[e[1]]
				var b := pts[e[1] + 1]
				var d := seg_dist(m, a, b)
				if d < best_d:
					best_d = d
					var ab := b - a
					var t := clampf((m - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
					best = { "road": r, "dist": d, "point": a + ab * t, "dir": ab.normalized() }
	return best

func shoulder_at(m: Vector2) -> bool:
	for e in _road_index.get(_cell(m), []):
		var r: Dictionary = roads[e[0]]
		var sh: float = CLS[r.cls].shoulder
		if sh <= 0.0: continue
		var pts: PackedVector2Array = r.pts
		if seg_dist(m, pts[e[1]], pts[e[1] + 1]) <= r.w / 2.0 + sh: return true
	return false

## 0 = dry land, 1 = river (open water), 2 = the mud banks
func river_at(m: Vector2) -> int:
	var best := 0
	for si in _river_index.get(_cell(m), []):
		var a := river_pts[si]
		var b := river_pts[si + 1]
		var ab := b - a
		var t := clampf((m - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var hw := lerpf(river_hw[si], river_hw[si + 1], t) + noise.get_noise_2d(m.x * 3.0, m.y * 3.0) * 4.0
		var d := m.distance_to(a + ab * t)
		if d < hw: return 1
		if d < hw + 10.0: best = 2
	return best

func lot_at(m: Vector2) -> Dictionary:
	for l in lots:
		if l.r.has_point(m): return l
	return {}

func rail_near(m: Vector2, d := 3.0) -> bool:
	if absf(m.y - 1900) > 1000 and m.x > 1000: pass
	for i in rail_pts.size() - 1:
		if seg_dist(m, rail_pts[i], rail_pts[i + 1]) < d: return true
	return false

## What kind of ground this is, before weather: asphalt, gravel, grass, water, mud, ballast
func ground_at(m: Vector2) -> String:
	var rd := road_at(m)
	if not rd.is_empty():
		return "gravel" if rd.road.cls == "gravel" else "asphalt"
	var l := lot_at(m)
	if not l.is_empty():
		return "gravel" if l.kind == "gravel" else ("grass" if l.kind == "park" else "asphalt")
	if shoulder_at(m): return "gravel"
	var rv := river_at(m)
	if rv == 1: return "water"
	if rv == 2: return "mud"
	return "grass"

func road_rank_at(m: Vector2) -> int:
	var rd := road_at(m)
	return 0 if rd.is_empty() else int(CLS[rd.road.cls].rank)

# ------------------------------------------------------------------ bridges, crossings, buildings

func _find_bridges_and_crossings() -> void:
	for r in roads:
		var pts: PackedVector2Array = r.pts
		for si in pts.size() - 1:
			var a := pts[si]
			var b := pts[si + 1]
			# sample along the segment: where it's over water, it's a bridge
			var n := maxi(1, int(a.distance_to(b) / 4.0))
			var start := Vector2.INF
			for k in n + 1:
				var q := a.lerp(b, float(k) / n)
				var wet := river_at(q) > 0
				if wet and start == Vector2.INF: start = q
				if (not wet or k == n) and start != Vector2.INF:
					if start.distance_to(q) > 6.0:
						var dir := (q - start).normalized()
						bridges.append({ "a": start - dir * 6.0, "b": q + dir * 6.0, "w": r.w, "name": r.name })
					start = Vector2.INF
			for ri in rail_pts.size() - 1:
				var x = seg_intersect(a, b, rail_pts[ri], rail_pts[ri + 1])
				if x != null and not r.limited:
					crossings.append({ "p": x, "dir": (b - a).normalized(), "w": r.w, "road": r.name })

func _clear_of_roads(r: Rect2, margin: float) -> bool:
	var pts := [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), r.get_center(),
		(r.position + r.get_center()) / 2.0, (r.end + r.get_center()) / 2.0]
	for p in pts:
		if not road_at(p, margin).is_empty(): return false
		if river_at(p) > 0: return false
		if rail_near(p, 6.0): return false
	for l in lots:
		if l.r.grow(2.0).intersects(r): return false
	return true

const SHOP_NAMES := ["PAWN", "DEP 24H", "PIZZA", "BAR", "TATTOO", "VAPE", "SUBS", "THRIFT", "NAILS", "PHO", "PUB", "BOOKS",
	"DONAIR", "GYM", "BANK", "CELL", "LIQUOR", "SHAWARMA", "BARBER", "ARCADE", "POUTINE", "MOTEL"]
const NEON := [Color("ff3a8a"), Color("3ad8ff"), Color("8aff4a"), Color("ff6a2a"), Color("c84aff"), Color("ffe04a")]

func _buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1990
	for c in grid_cells:
		if c.reserved: continue
		# step in from the street centrelines: half a street, a sidewalk, a little gap
		var r: Rect2 = c.r.grow(-10.0)
		match c.style:
			"downtown": _fill_downtown(r, c.zone, rng)
			"residential", "village": _fill_houses(r, c.zone, rng, c.style == "village")
			"oldtown": _fill_oldtown(r, c.zone, rng)
			"commercial": _fill_commercial(r, c.zone, rng)
			"industrial": _fill_industrial(r, c.zone, rng)
	# farms along the country roads
	for rd in roads:
		if rd.cls != "rural" and rd.cls != "gravel": continue
		var pts: PackedVector2Array = rd.pts
		var acc := 0.0
		var next := 60.0 + rng.randf() * 200.0
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			acc += a.distance_to(b)
			if acc < next: continue
			acc = 0.0
			next = 120.0 + rng.randf() * 320.0
			if zone_at(a).id != "": continue
			var dir := (b - a).normalized()
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var base: Vector2 = a + dir.orthogonal() * side * (rd.w / 2.0 + 16.0 + rng.randf() * 10.0)
			var house := Rect2(base - Vector2(6, 5), Vector2(12, 10))
			if _clear_of_roads(house, 4.0):
				buildings.append({ "r": house, "h": 7.0, "kind": "farmhouse", "name": "", "zone": "" })
				lights.append({ "p": base + Vector2(0, 7), "type": "porch", "seed": rng.randi() })
				var barn := Rect2(base + dir * (18.0 + rng.randf() * 8.0) + dir.orthogonal() * side * 10.0 - Vector2(9, 7), Vector2(18, 14))
				if _clear_of_roads(barn, 4.0):
					buildings.append({ "r": barn, "h": 9.0, "kind": "barn", "name": "", "zone": "" })
					lights.append({ "p": barn.get_center() + Vector2(0, 9), "type": "mercury", "seed": rng.randi() })

func _fill_downtown(r: Rect2, zone: String, rng: RandomNumberGenerator) -> void:
	var x := r.position.x
	while x < r.end.x - 12.0:
		var w := minf(14.0 + rng.randf() * 22.0, r.end.x - x)
		var b := Rect2(x, r.position.y, w, r.size.y)
		if _clear_of_roads(b, 1.0):
			var shop: bool = rng.randf() < 0.6
			var nm: String = SHOP_NAMES[rng.randi() % SHOP_NAMES.size()] if shop else ""
			buildings.append({ "r": b, "h": 12.0 + rng.randf() * 22.0, "kind": "apts" if not shop else "shop", "name": nm, "zone": zone,
				"neon": NEON[rng.randi() % NEON.size()] if shop and rng.randf() < 0.7 else null })
			if shop: lights.append({ "p": Vector2(b.get_center().x, b.end.y + 2.0), "type": "neon", "seed": rng.randi(), "color": buildings[-1].get("neon") })
		x += w + 1.5

func _fill_oldtown(r: Rect2, zone: String, rng: RandomNumberGenerator) -> void:
	var x := r.position.x
	while x < r.end.x - 10.0:
		var w := minf(12.0 + rng.randf() * 12.0, r.end.x - x)
		var hgt := minf(r.size.y, 18.0 + rng.randf() * 12.0)
		var b := Rect2(x, r.end.y - hgt, w, hgt)
		if _clear_of_roads(b, 1.0):
			var shop: bool = rng.randf() < 0.45
			buildings.append({ "r": b, "h": 7.0 + rng.randf() * 8.0, "kind": "shop" if shop else "houses",
				"name": SHOP_NAMES[rng.randi() % SHOP_NAMES.size()] if shop else "", "zone": zone })
			if shop and rng.randf() < 0.5: lights.append({ "p": Vector2(b.get_center().x, b.end.y + 2.0), "type": "neon", "seed": rng.randi() })
		x += w + 3.0

func _fill_houses(r: Rect2, zone: String, rng: RandomNumberGenerator, village: bool) -> void:
	# two rows of houses, front doors on the street, backyards meeting in the middle
	for row in 2:
		var x := r.position.x + rng.randf() * 4.0
		while x < r.end.x - 9.0:
			var w := 9.0 + rng.randf() * 4.0
			var d := 8.0 + rng.randf() * 3.0
			var y := r.position.y + 3.0 if row == 0 else r.end.y - d - 3.0
			var b := Rect2(x, y, w, d)
			if r.size.y < 2.0 * d + 6.0 and row == 1: break
			if _clear_of_roads(b, 1.5):
				buildings.append({ "r": b, "h": 6.0 + rng.randf() * 3.0, "kind": "house", "name": "", "zone": zone, "color": rng.randi() % 6 })
				if rng.randf() < 0.6: lights.append({ "p": Vector2(b.get_center().x, (b.position.y - 1.0) if row == 0 else (b.end.y + 1.0)), "type": "porch", "seed": rng.randi() })
			x += w + (5.0 if not village else 12.0) + rng.randf() * 6.0

func _fill_commercial(r: Rect2, zone: String, rng: RandomNumberGenerator) -> void:
	var b := Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.5))
	if _clear_of_roads(b, 1.0):
		buildings.append({ "r": b, "h": 8.0 + rng.randf() * 4.0, "kind": "bigbox", "name": ["SUPERSTORE", "HARDWARE", "CINEMA", "BINGO", "FURNITURE", "AUTO PARTS"][rng.randi() % 6], "zone": zone })
		var lot := Rect2(r.position.x + 2, b.end.y + 2, r.size.x - 4, r.end.y - b.end.y - 4)
		if lot.size.y > 8.0 and _clear_of_roads(lot, 1.0):
			lots.append({ "r": lot, "kind": "asphalt", "name": "", "lines": true })
			lights.append({ "p": lot.get_center(), "type": "led", "seed": rng.randi() })

func _fill_industrial(r: Rect2, zone: String, rng: RandomNumberGenerator) -> void:
	var b := Rect2(r.position + Vector2(2, 2), Vector2(r.size.x * (0.5 + rng.randf() * 0.3), r.size.y - 4))
	if _clear_of_roads(b, 1.0):
		buildings.append({ "r": b, "h": 9.0 + rng.randf() * 5.0, "kind": "warehouse", "name": ["FREIGHT", "STEEL", "LUMBER", "SALVAGE", "TIRES", "COLD STORAGE"][rng.randi() % 6], "zone": zone })
		var lot := Rect2(b.end.x + 2, r.position.y + 2, r.end.x - b.end.x - 4, r.size.y - 4)
		if lot.size.x > 8.0 and _clear_of_roads(lot, 1.0):
			lots.append({ "r": lot, "kind": "gravel" if rng.randf() < 0.5 else "asphalt", "name": "", "lines": false })
		lights.append({ "p": Vector2(b.end.x + 1, b.get_center().y), "type": "sodium", "seed": rng.randi() })

## Streetlights: every road in a lit zone gets poles on alternating sides; highways get
## high-mast lights at the interchanges; the country stays dark.
func _street_lights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for rd in roads:
		if rd.limited: continue
		var pts: PackedVector2Array = rd.pts
		var acc := 0.0
		var side := 1.0
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var L := a.distance_to(b)
			var dir := (b - a) / maxf(L, 0.001)
			var s := 18.0 - acc
			while s < L:
				var p := a + dir * s
				var z := zone_at(p)
				if z.light != "":
					var lp: Vector2 = p + dir.orthogonal() * side * (rd.w / 2.0 + 1.5)
					var typ: String = z.light
					if typ == "sodium" and rng.randf() < 0.08: typ = "sodium_flicker"
					if typ == "sodium" and rng.randf() < 0.04: typ = "dead"
					lights.append({ "p": lp, "type": typ, "seed": rng.randi() })
				side = -side
				s += 34.0
			acc = fmod(acc + L, 34.0)
	for p in interchanges:
		for k in 4:
			lights.append({ "p": p + Vector2(cos(k * PI / 2.0 + 0.6), sin(k * PI / 2.0 + 0.6)) * 30.0, "type": "highmast", "seed": k })
	for b in bridges:
		var dir: Vector2 = (b.b - b.a).normalized()
		var L: float = b.a.distance_to(b.b)
		var s := 6.0
		while s < L:
			for side in [-1.0, 1.0]:
				lights.append({ "p": b.a + dir * s + dir.orthogonal() * side * (b.w / 2.0 + 1.0), "type": "bridge", "seed": int(s) })
			s += 24.0
	for c in crossings:
		lights.append({ "p": c.p + c.dir.orthogonal() * (c.w / 2.0 + 2.0) - c.dir * 6.0, "type": "rail", "seed": 0 })
		lights.append({ "p": c.p - c.dir.orthogonal() * (c.w / 2.0 + 2.0) + c.dir * 6.0, "type": "rail", "seed": 1 })
	# traffic signals where two big roads meet in town
	for i in roads.size():
		for j in range(i + 1, roads.size()):
			var r1: Dictionary = roads[i]
			var r2: Dictionary = roads[j]
			if r1.limited or r2.limited: continue
			if CLS[r1.cls].rank < 4 and CLS[r2.cls].rank < 4: continue
			if r1.cls in ["rural", "gravel"] or r2.cls in ["rural", "gravel"]: continue
			for si in r1.pts.size() - 1:
				for sj in r2.pts.size() - 1:
					var x = seg_intersect(r1.pts[si], r1.pts[si + 1], r2.pts[sj], r2.pts[sj + 1])
					if x != null and zone_at(x).id != "":
						lights.append({ "p": x + Vector2(r1.w / 2.0 + 1.0, r2.w / 2.0 + 1.0), "type": "signal", "seed": i * 31 + j, "j": x,
							"dir": (r1.pts[si + 1] - r1.pts[si]).normalized() })

# ------------------------------------------------------------------ the GPS graph

func _node(p: Vector2) -> int:
	var k := Vector2i(roundi(p.x), roundi(p.y))
	if _g_key.has(k): return _g_key[k]
	g_pos.append(p)
	g_adj.append([])
	_g_key[k] = g_pos.size() - 1
	return g_pos.size() - 1

func _link(a: int, b: int, road: Dictionary) -> void:
	if a == b: return
	var L := g_pos[a].distance_to(g_pos[b])
	g_adj[a].append([b, L, road])
	g_adj[b].append([a, L, road])

## Roads become a graph: every vertex is a node, and where two roads cross (and can actually
## turn onto each other: not under a highway overpass), the crossing is a node of both.
func _graph() -> void:
	var cuts := {}    # road index -> Array of [seg, t, point]
	for k in _road_index:
		var es: Array = _road_index[k]
		for x in es.size():
			for y in range(x + 1, es.size()):
				var e1: Array = es[x]
				var e2: Array = es[y]
				if e1[0] == e2[0]: continue
				var r1: Dictionary = roads[e1[0]]
				var r2: Dictionary = roads[e2[0]]
				var a: Vector2 = r1.pts[e1[1]]
				var b: Vector2 = r1.pts[e1[1] + 1]
				var c: Vector2 = r2.pts[e2[1]]
				var d: Vector2 = r2.pts[e2[1] + 1]
				var p = seg_intersect(a, b, c, d)
				if p == null: continue
				if _cell(p) != k: continue
				if r1.limited != r2.limited:
					var near := false
					for ip in interchanges:
						if ip.distance_to(p) < 60.0: near = true
					if not near: continue
				for pair in [[e1[0], e1[1], a, b], [e2[0], e2[1], c, d]]:
					if not cuts.has(pair[0]): cuts[pair[0]] = []
					var t: float = (p - pair[2]).length() / maxf((pair[3] - pair[2]).length(), 0.001)
					cuts[pair[0]].append([pair[1], t, p])
	for ri in roads.size():
		var r: Dictionary = roads[ri]
		var pts: PackedVector2Array = r.pts
		var seq: Array = []
		var cs: Array = cuts.get(ri, [])
		cs.sort_custom(func(u, v): return u[0] < v[0] or (u[0] == v[0] and u[1] < v[1]))
		var ci := 0
		for si in pts.size():
			seq.append(pts[si])
			while ci < cs.size() and cs[ci][0] == si:
				seq.append(cs[ci][2])
				ci += 1
		var prev := -1
		for p in seq:
			var n := _node(p)
			if prev >= 0: _link(prev, n, r)
			prev = n

func nearest_node(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in g_pos.size():
		var d := g_pos[i].distance_squared_to(p)
		if d < bd and not g_adj[i].is_empty():
			bd = d
			best = i
	return best

## A* from one point to another along the roads. Returns the points to drive through.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var s := nearest_node(from)
	var t := nearest_node(to)
	var out := PackedVector2Array()
	if s < 0 or t < 0: return out
	var open := { s: true }
	var came := {}
	var g := { s: 0.0 }
	var f := { s: g_pos[s].distance_to(g_pos[t]) }
	var guard := 0
	while not open.is_empty() and guard < 200000:
		guard += 1
		var cur := -1
		var cf := INF
		for n in open:
			if f[n] < cf:
				cf = f[n]
				cur = n
		if cur == t: break
		open.erase(cur)
		for e in g_adj[cur]:
			var nb: int = e[0]
			# highways are faster, so the GPS likes them (like real ones do)
			var cost: float = e[1] / (1.6 if e[2].cls == "highway" else (1.25 if e[2].cls == "arterial" else 1.0))
			var ng: float = g[cur] + cost
			if ng < g.get(nb, INF):
				g[nb] = ng
				came[nb] = cur
				f[nb] = ng + g_pos[nb].distance_to(g_pos[t]) / 1.6
				open[nb] = true
	if not came.has(t) and s != t: return out
	var n := t
	out.append(g_pos[n])
	while n != s:
		n = came[n]
		out.append(g_pos[n])
	out.reverse()
	return out
