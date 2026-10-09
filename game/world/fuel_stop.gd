## Gas: the pumps at the gas bars and the Big Stop, what a litre costs, and Toby with a jerry
## can when you run dry. The car burns it (CarSim); this is where you buy it.
class_name FuelStop
extends Node

const REGULAR := 1.62          # $ a litre (Moncton, fall 2022, near enough)
const PREMIUM := 1.89
const JERRY_L := 6.0
const JERRY_FEE := 60
const PUMP_M := 7.0            # how close to the pumps you have to stop
const FLOW := 9.0              # litres a second (the pump's fast; nobody wants to watch it)

var drive: Node
var panel: PumpPanel
var stations: Array = []

func setup(the_drive: Node) -> void:
	drive = the_drive
	stations = find_stations(drive.world.map)
	panel = PumpPanel.new()
	panel.stop = self
	panel.size = Vector2(640, 360)
	panel.visible = false
	drive.get_node("HudLayer").add_child(panel)

## Every set of pumps on the map, with the name on the shop beside it.
static func find_stations(map: MapData) -> Array:
	var out: Array = []
	for b in map.buildings:
		if String(b.kind) != "pumps": continue
		var r: Rect2 = b.r
		var name := "GAS"
		var best := 80.0
		for s in map.buildings:
			if String(s.kind) != "shop" or String(s.name) == "": continue
			var d := (s.r as Rect2).get_center().distance_to(r.get_center())
			if d < best:
				best = d
				name = String(s.name)
		out.append({ "r": r, "p": r.get_center(), "name": name })
	return out

## A fill-up's bill in whole dollars (the till rounds up; it always does).
static func bill(litres: float, premium: bool) -> int:
	return int(ceilf(litres * (PREMIUM if premium else REGULAR) - 0.001))

## The pumps you're stopped at ({} when you aren't).
func at_pumps() -> Dictionary:
	var c: PlayerCar = drive.car
	if c == null or not c.sim.burn_fuel or c.sim.speed() > 1.0: return {}
	for s in stations:
		var r: Rect2 = s.r
		var q := Vector2(clampf(c.sim.pos.x, r.position.x, r.end.x), clampf(c.sim.pos.y, r.position.y, r.end.y))
		if q.distance_to(c.sim.pos) < PUMP_M: return s
	return {}

func open() -> bool:
	return panel.visible

func _process(_dt: float) -> void:
	if panel.visible or drive.car == null or StoryState.active: return
	var s := at_pumps()
	if not s.is_empty():
		drive.hud.post(Hints.fmt("{use}: PUMP GAS"), 0.2)
		if Input.is_action_just_pressed("use"): panel.open(s)
	elif drive.car.sim.burn_fuel and drive.car.sim.fuel_l <= 0.05 and drive.car.sim.speed() < 1.0:
		drive.hud.post(Hints.fmt("OUT OF GAS. {reset}: CALL TOBY ($%d)" % JERRY_FEE), 0.2)

## Out of gas on the side of the road: Toby comes out with a jerry can. Twenty minutes, sixty bucks.
func jerry_can() -> void:
	var sim: CarSim = drive.car.sim
	sim.add_fuel(JERRY_L, false)
	drive.save.cash = int(drive.save.get("cash", 0)) - JERRY_FEE
	drive.sky.time_h = fmod(drive.sky.time_h + 1.0 / 3.0, 24.0)
	drive.hud.post("TOBY SHOWS UP TWENTY MINUTES LATER WITH A JERRY CAN. \"SIXTY BUCKS. AND BUY GAS.\"", 6.0)

func out_of_gas() -> bool:
	var c: PlayerCar = drive.car
	return c != null and c.sim.burn_fuel and c.sim.fuel_l <= 0.05


## At the pump: regular or premium, fill it or put in twenty bucks. The numbers on the pump
## spin while it goes in.
class PumpPanel extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const GREEN := Color("6fbf5a")
	const RED := Color("e0402e")
	const LCD := Color("9cff7a")
	var stop: FuelStop
	var station := {}
	var sel := 0
	var going := 0.0           # litres still to go in (0 when not pumping)
	var put := 0.0             # litres in so far this time
	var premium := false
	var note := ""

	func open(s: Dictionary) -> void:
		station = s
		sel = 0
		going = 0.0
		put = 0.0
		note = ""
		visible = true

	func items() -> Array:
		var sim: CarSim = stop.drive.car.sim
		var room := sim.tank_l - sim.fuel_l
		return [
			["FILL IT, REGULAR", room, false],
			["FILL IT, PREMIUM", room, true],
			["$20 OF REGULAR", minf(room, 20.0 / FuelStop.REGULAR), false],
			["DONE", 0.0, false],
		]

	func _process(dt: float) -> void:
		if not visible: return
		queue_redraw()
		var sim: CarSim = stop.drive.car.sim
		if going > 0.0:
			var l := minf(going, FuelStop.FLOW * dt)
			going -= l
			put += l
			sim.add_fuel(l, premium)
			if going <= 0.0:
				var cost := FuelStop.bill(put, premium)
				stop.drive.save.cash = int(stop.drive.save.get("cash", 0)) - cost
				note = "%.1f L %s. $%d. THE GUY INSIDE DOESN'T LOOK UP." % [put, "PREMIUM" if premium else "REGULAR", cost]
				SaveGame.write(stop.drive.save)
			return
		var its := items()
		if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % its.size()
		if Input.is_action_just_pressed("ui_up"): sel = (sel + its.size() - 1) % its.size()
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("use"):
			visible = false
			return
		if not Input.is_action_just_pressed("ui_accept"): return
		var it: Array = its[sel]
		if float(it[1]) <= 0.05:
			visible = false
			return
		premium = bool(it[2])
		var cash := int(stop.drive.save.get("cash", 0))
		var afford := maxf(0.0, float(cash)) / (FuelStop.PREMIUM if premium else FuelStop.REGULAR)
		if afford < 1.0:
			note = "THE CARD'S DECLINED. EVEN FOR A LITRE."
			return
		going = minf(float(it[1]), afford)
		put = 0.0
		note = ""

	func _draw() -> void:
		if stop == null or stop.drive.car == null: return
		var sim: CarSim = stop.drive.car.sim
		var r := Rect2(200, 70, 240, 190)
		draw_rect(r, Color(0.05, 0.05, 0.07, 0.97))
		draw_rect(r, GOLD, false, 1.0)
		PixelFont.draw_centered(self, r.get_center().x, r.position.y + 8, String(station.get("name", "GAS")), GOLD, 2)
		# the pump's own display: litres and dollars
		var lcd := Rect2(r.position.x + 20, r.position.y + 28, r.size.x - 40, 34)
		draw_rect(lcd, Color("0e1a0c"))
		var price := FuelStop.PREMIUM if premium else FuelStop.REGULAR
		PixelFont.draw(self, lcd.position + Vector2(6, 5), "$%7.2f" % (put * price), LCD, 2)
		PixelFont.draw(self, lcd.position + Vector2(6, 22), "%6.1f L  AT $%.2f A LITRE" % [put, price], LCD)
		# the tank
		var tank := Rect2(r.position.x + 20, r.position.y + 68, r.size.x - 40, 6)
		draw_rect(tank, Color(1, 1, 1, 0.08))
		draw_rect(Rect2(tank.position, Vector2(tank.size.x * sim.fuel_frac(), tank.size.y)), GREEN if sim.fuel_frac() > 0.15 else RED)
		PixelFont.draw(self, Vector2(tank.position.x, tank.end.y + 3), "TANK %.0f / %.0f L" % [sim.fuel_l, sim.tank_l], ASH)
		var y := r.position.y + 94
		var its := items()
		for i in its.size():
			var it: Array = its[i]
			var on := i == sel and going <= 0.0
			if on: draw_rect(Rect2(r.position.x + 14, y - 2, r.size.x - 28, 11), Color(1, 1, 1, 0.1))
			var label := String(it[0])
			if float(it[1]) > 0.05: label += "  ABOUT $%d" % FuelStop.bill(float(it[1]), bool(it[2]))
			PixelFont.draw(self, Vector2(r.position.x + 20, y), label, GOLD if on else BONE)
			y += 12
		for ln in Hud.wrap_lines(note, 36):
			PixelFont.draw(self, Vector2(r.position.x + 20, y + 2), ln, ASH)
			y += 9
		PixelFont.draw_centered(self, r.get_center().x, r.end.y - 11, Hints.fmt("{updown}: PICK  {ui_accept}: PUMP  {ui_cancel}: DONE"), ASH)
