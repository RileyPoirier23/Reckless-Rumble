## The Luchadooros' lot, in the industrial park off the road from Northside Salvage: three cars
## out front (1ton's Caprees on 28s, La Calavera's '64 Impaler laid out on the pavement, El
## Pulpo's gold Town Carr), and 1ton in a folding chair with a laminated list. Pull up and he'll
## talk; pull up in a car that's on the list and he joins your crew.
class_name Luchadooros
extends Node

const LOT := Rect2(6490, 992, 18, 56)
const SPOT := Vector2(6499, 1001)          # where you pull up, by the gate
const USE_M := 9.0
const NEAR_M := 160.0                      # their cars are out when you're this close
## Their cars: [model, year, paint, where (m), the custom work on it]
const CARS := [
	["CAPREES", 1986, "#5a1e7a", Vector2(6494.0, 1011.0), { "donk": 3 }],
	["IMPALER", 1964, "#a81e2a", Vector2(6499.5, 1011.0), { "hyd": 3 }],
	["TOWN CARR", 1995, "#c8a040", Vector2(6505.0, 1011.0), { "hyd": 2, "donk": 1 }],
]

var drive: Node
var panel: LotPanel
var cars: Array = []

func setup(the_drive: Node) -> void:
	drive = the_drive
	panel = LotPanel.new()
	panel.lot = self
	panel.size = Vector2(640, 360)
	panel.visible = false
	drive.get_node("HudLayer").add_child(panel)
	# on the map, to drive to
	var known := false
	for lm in drive.world.map.landmarks:
		if String(lm.name) == OneTon.CLUB: known = true
	if not known: drive.world.map.landmarks.append({ "name": OneTon.CLUB, "p": SPOT, "dest": true })

func open() -> bool:
	return panel.visible

func at_lot() -> bool:
	var c: PlayerCar = drive.car
	return c != null and c.sim.speed() < 1.5 and c.sim.pos.distance_to(SPOT) < USE_M

## A catalogue car by model and year.
static func find_car(model: String, year: int) -> String:
	for id in CarCatalog.ids():
		var e := CarCatalog.entry(String(id))
		if String(e.get("model", "")).to_upper() == model and int(e.get("year", 0)) == year: return String(id)
	return ""

func _process(_dt: float) -> void:
	if drive.car == null: return
	_park(drive.car.sim.pos.distance_to(SPOT) < NEAR_M and not StoryState.active)
	if panel.visible or StoryState.active or drive.garage.visible or drive.modal_open(): return
	if not at_lot(): return
	drive.hud.prompt(Hints.fmt("{use}: THE LUCHADOOROS"))
	if Input.is_action_just_pressed("use"): panel.open()

## Their cars, parked out front while you're around.
func _park(want: bool) -> void:
	if want == not cars.is_empty(): return
	if not want:
		for a in cars:
			drive.traffic.extra.erase(a)
			a.queue_free()
		cars.clear()
		return
	for i in CARS.size():
		var c: Array = CARS[i]
		var id := find_car(String(c[0]), int(c[1]))
		if id == "": continue
		var spec := OneTon.apply(CarCatalog.spec(id), { "custom": c[4] })
		spec.paint = String(c[2])
		var a := AiCar.new()
		drive.ysort.add_child(a)
		var at: Vector2 = c[3]
		a.setup_ai(spec, drive.world, drive.skids, drive.hud, at, -PI / 2.0, 120 + i)
		a.set_path(PackedVector2Array([at, at + Vector2(0, -3)]), false)
		a.traffic = drive.traffic
		a.hold = true
		a.view.lift = OneTon.stance({ "custom": c[4] }).x
		drive.traffic.extra.append(a)
		cars.append(a)

## What happens when you show him the car you're in.
func show_car() -> Array:
	var was := OneTon.in_crew(drive.save)
	var lines := OneTon.show_car(drive.save, drive.car.spec, int(drive.sky.day))
	if not was and OneTon.in_crew(drive.save):
		SaveGame.write(drive.save)
		drive.hud.notify("1TON JOINS YOUR CREW: HYDRAULICS AND DONKS, BAY THREE AT COVINGTON AUTO.", "award", 2, 6.0)
	return lines

## 1ton, at the lot: his face, what he's saying, and what you can do.
class LotPanel extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const PURPLE := Color("8a4ab0")
	const R := Rect2(90, 40, 460, 260)
	var lot: Luchadooros
	var lines: Array = []
	var line_i := 0
	var sel := 0
	var _opened := -1

	func items() -> Array:
		var out: Array = ["TALK"]
		if not OneTon.in_crew(lot.drive.save): out.append("SHOW HIM YOUR CAR")
		out.append("LEAVE")
		return out

	func open() -> void:
		visible = true
		sel = 0
		_opened = Engine.get_process_frames()
		var met: bool = bool((lot.drive.save.get("crew", {}) as Dictionary).get("met_oneton", false))
		if not met:
			lines = OneTon.INTRO.duplicate()
			var crew: Dictionary = lot.drive.save.get("crew", {})
			crew.met_oneton = true
			lot.drive.save.crew = crew
		elif OneTon.in_crew(lot.drive.save):
			lines = ["BAY THREE. COVINGTON AUTO. I AM THERE WHEN YOU NEED ME. ALSO WHEN YOU DON'T."]
		else:
			lines = ["YOU CAME BACK. GOOD. HAVE YOU BROUGHT ME A PROPER CAR?"]
		line_i = 0

	func _process(_dt: float) -> void:
		if not visible: return
		queue_redraw()
		if Engine.get_process_frames() == _opened: return
		if Input.is_action_just_pressed("ui_cancel"):
			visible = false
			return
		var it := items()
		if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % it.size()
		if Input.is_action_just_pressed("ui_up"): sel = (sel + it.size() - 1) % it.size()
		if not (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("use")): return
		# still talking: the next line first
		if line_i < lines.size() - 1:
			line_i += 1
			return
		match String(it[sel]):
			"TALK":
				lines = [OneTon.TALK[(int(lot.drive.sky.day) * 3 + int(Time.get_ticks_msec() / 997)) % OneTon.TALK.size()]]
				line_i = 0
			"SHOW HIM YOUR CAR":
				lines = lot.show_car()
				line_i = 0
				sel = 0
			"LEAVE":
				visible = false

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
		draw_rect(R, Color(0.07, 0.05, 0.09, 0.97))
		draw_rect(R, PURPLE, false, 1.0)
		PixelFont.draw(self, R.position + Vector2(12, 10), OneTon.CLUB, GOLD, 2)
		var sub := "1TON RUNS THE BAYS.  LA CALAVERA RUNS THE STREETS.  EL PULPO RUNS HIS MOUTH."
		PixelFont.draw(self, R.position + Vector2(12, 28), sub, ASH)
		# his face, framed
		var fr := Rect2(R.position + Vector2(12, 44), Vector2(72, 72))
		draw_rect(fr, PURPLE)
		draw_texture_rect(OneTon.face(), fr.grow(-4), false)
		PixelFont.draw_centered(self, fr.get_center().x, fr.end.y + 5, "1TON", GOLD)
		# what he's saying
		var tx := fr.end.x + 12
		var w := int((R.end.x - 12 - tx) / 4)
		var ls := Hud.wrap_lines(String(lines[line_i]) if line_i < lines.size() else "", w)
		for k in mini(ls.size(), 6): PixelFont.draw(self, Vector2(tx, fr.position.y + 4 + k * 10), ls[k], BONE)
		if line_i < lines.size() - 1: PixelFont.draw(self, Vector2(R.end.x - 30, fr.end.y - 6), "...", GOLD)
		# the choices
		var it := items()
		for i in it.size():
			var y := R.position.y + 150 + i * 18
			var on := i == sel and line_i >= lines.size() - 1
			if on: draw_rect(Rect2(R.position.x + 12, y - 4, R.size.x - 24, 15), Color(0.55, 0.3, 0.7, 0.25))
			PixelFont.draw(self, Vector2(R.position.x + 20, y), String(it[i]), GOLD if on else BONE)
		var crew := "IN YOUR CREW" if OneTon.in_crew(lot.drive.save) else "NOT IN YOUR CREW YET"
		PixelFont.draw(self, Vector2(R.end.x - 12 - PixelFont.width(crew), R.position.y + 14), crew, PURPLE if OneTon.in_crew(lot.drive.save) else ASH)
		var hint := Hints.fmt("{updown}: PICK  {ui_accept}: GO ON  {ui_cancel}: LEAVE")
		PixelFont.draw_centered(self, R.get_center().x, R.end.y - 14, hint, ASH)
