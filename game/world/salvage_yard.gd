## Northside Salvage: a fenced lot of crushed cars in the industrial park, a trailer for an
## office, and a guy named Lloyd. Used parts, graded A to D by Lloyd, at a fraction of new (the
## worse the grade, the better the odds it's junk, and you find out when the yard truck drops it
## at Covington's and Gus opens the box). Worn-out bits (a clutch, a turbo, a motor, tires, pads)
## his nephew puts in right there in the yard. And he'll buy what's sitting on Gus's bench.
class_name SalvageYard
extends Node

const OFFICE := Vector2(6426, 932)        # in front of the trailer
const USE_M := 9.0
const OPEN_H := [8.0, 18.0]
const GRADES := ["A", "B", "C", "D"]
const PART_CUT := [0.55, 0.4, 0.28, 0.16]  # of new
const DUD := [0.0, 0.08, 0.2, 0.4]         # odds Gus opens the box and it's junk
const COND := [0.9, 0.75, 0.6, 0.45]       # how much life is left in a worn bit
const WEAR_CUT := [0.5, 0.38, 0.27, 0.18]  # of what Gus charges to fix it
const NEPHEW := 40                         # labour, cash
const TRUCK_H := 1.0                       # the yard truck to Covington's
const BUYS_AT := 0.2                       # what Lloyd pays for a part off the bench
const PARTS_A_DAY := 6

## The bits his nephew swaps in the yard: what Gus would charge to fix it, and how long it takes.
const WEAR := {
	"clutch": { "name": "A CLUTCH OFF A WRECK", "gus": 520, "h": 2.0 },
	"turbo": { "name": "A TURBO, PULLED", "gus": 780, "h": 1.5, "turbo": true },
	"motor": { "name": "A MOTOR. IT FITS. DON'T ASK", "gus": 1500, "h": 4.0 },
	"tires": { "name": "FOUR TIRES, MATCHING-ISH", "gus": 480, "h": 0.5 },
	"pads": { "name": "BRAKE PADS IN A BAG", "gus": 140, "h": 0.5 },
}
const WEAR_ORDER := ["clutch", "turbo", "motor", "tires", "pads"]

const LINES := [
	"LLOYD: \"NO REFUNDS. NO RETURNS. NO WARRANTY. THE DOG IS FRIENDLY. MOSTLY.\"",
	"LLOYD: \"EVERYTHING HERE RAN WHEN IT CAME IN. MOST OF IT CAME IN ON A FLATBED.\"",
	"LLOYD: \"A-GRADE IS A-GRADE. D-GRADE IS A LOTTERY TICKET.\"",
	"LLOYD: \"YOU'RE GUS'S KID? HE STILL OWES ME FOR A TRANSMISSION. 1998.\"",
]
const DUD_WHY := ["CRACKED", "SEIZED", "IT'S HELD TOGETHER WITH HOCKEY TAPE", "THERE'S A MOUSE NEST IN IT. THE MOUSE IS HOME",
	"IT'S FOR A DIFFERENT CAR. A BOAT, MAYBE", "SOMEBODY ALREADY SOLD THE GOOD HALF"]

var drive: Node
var panel: YardPanel

func setup(the_drive: Node) -> void:
	drive = the_drive
	panel = YardPanel.new()
	panel.yard = self
	panel.size = Vector2(640, 360)
	panel.visible = false
	drive.get_node("HudLayer").add_child(panel)

## The day's pile: used parts (with the grade Lloyd gives them, and whether they're junk, which
## nobody knows yet) and the worn bits his nephew can swap. The same day always has the same pile.
static func stock(day: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 13
	var ids: Array = Parts.CATALOG.keys()
	ids.sort()
	var out: Array = []
	var seen := {}
	while out.size() < PARTS_A_DAY:
		var id: String = ids[rng.randi() % ids.size()]
		if seen.has(id) or Parts.price(id) < 80: continue
		seen[id] = true
		var g := _grade(rng)
		out.append({ "kind": "part", "id": id, "grade": g, "price": _snap(Parts.price(id) * PART_CUT[g]),
			"dud": rng.randf() < DUD[g], "why": rng.randi() % DUD_WHY.size() })
	var keys := WEAR_ORDER.duplicate()
	for i in 3:
		var k: String = keys.pop_at(rng.randi() % keys.size())
		var g := _grade(rng)
		out.append({ "kind": "wear", "id": k, "grade": g, "price": _snap(float(WEAR[k].gus) * WEAR_CUT[g]) })
	return out

static func _grade(rng: RandomNumberGenerator) -> int:
	var x := rng.randf()
	return 0 if x < 0.15 else (1 if x < 0.45 else (2 if x < 0.78 else 3))

static func _snap(x: float) -> int:
	return maxi(5, int(round(x / 5.0)) * 5)

static func name_of(it: Dictionary) -> String:
	return Parts.name_of(String(it.id)) if String(it.kind) == "part" else String(WEAR[String(it.id)].name)

## What a part off the bench fetches.
static func offer(id: String) -> int:
	return _snap(Parts.price(id) * BUYS_AT)

## How much life a worn bit has left, as it'd go in (clutch/turbo/motor 0-1, pads mm, tread mm).
static func life(key: String, grade: int, spec: Dictionary) -> float:
	match key:
		"pads": return 10.0 * COND[grade]
		"tires": return float(spec.tires.tread_mm) * COND[grade]
	return COND[grade]

## The same, for what's on the car now.
static func life_now(key: String, sim: CarSim) -> float:
	match key:
		"clutch": return sim.clutch_cond
		"turbo": return sim.turbo_cond
		"motor": return 0.0 if sim.engine_blown else sim.engine_health
		"pads": return sim.pads_mm
		"tires":
			var t := 0.0
			for w in sim.tires: t += float(w.tread) / 4.0
			return t
	return 1.0

## Life as a percent of new, for the panel.
static func pct(key: String, x: float, spec: Dictionary) -> int:
	match key:
		"pads": return int(round(x * 10.0))
		"tires": return int(round(100.0 * x / maxf(float(spec.tires.tread_mm), 0.1)))
	return int(round(x * 100.0))

## Today's pile with what's been bought crossed off.
func today() -> Array:
	var day: int = drive.sky.day
	var s: Dictionary = drive.save.get("salvage", {})
	if int(s.get("day", -1)) != day:
		s = { "day": day, "bought": [] }
		drive.save.salvage = s
	return stock(day)

func bought(i: int) -> bool:
	return (drive.save.get("salvage", {}).get("bought", []) as Array).has(i)

func is_open() -> bool:
	var h: float = drive.sky.time_h
	return h >= OPEN_H[0] and h < OPEN_H[1]

func at_yard() -> bool:
	var c: PlayerCar = drive.car
	return c != null and c.sim.speed() < 1.5 and c.sim.pos.distance_to(OFFICE) < USE_M

func open() -> bool:
	return panel.visible

func _process(_dt: float) -> void:
	if panel.visible or drive.car == null or StoryState.active or drive.garage.visible: return
	if not at_yard(): return
	if not is_open():
		drive.hud.post("NORTHSIDE SALVAGE: CLOSED. OPEN 8 TO 6. THE DOG IS NOT CLOSED.", 0.2)
		return
	drive.hud.post(Hints.fmt("{use}: NORTHSIDE SALVAGE"), 0.2)
	if Input.is_action_just_pressed("use"): panel.open()

## Buy item i off today's pile. Returns what Lloyd says (or why not).
func buy(i: int) -> String:
	var pile := today()
	if i < 0 or i >= pile.size(): return ""
	if bought(i): return "LLOYD: \"SOLD. SOMEBODY BEAT YOU TO IT. IT WAS YOU.\""
	var it: Dictionary = pile[i]
	var cost := int(it.price) + (NEPHEW if String(it.kind) == "wear" else 0)
	if int(drive.save.get("cash", 0)) < cost:
		return "LLOYD: \"THAT'S $%d. CASH. I DON'T TAKE CARDS, I DON'T TAKE IOUS, I DON'T TAKE E-TRANSFERS.\"" % cost
	if String(it.kind) == "wear":
		var why := cant_swap(String(it.id))
		if why != "": return why
		swap(String(it.id), int(it.grade))
	else:
		# the yard truck takes it to Covington's; Gus opens the box
		var orders: Array = drive.save.get("orders", [])
		orders.append({ "part": String(it.id), "arrives_h": float(drive.save.get("clock_h", 0.0)) + TRUCK_H, "yard": true,
			"dud": bool(it.dud), "why": DUD_WHY[int(it.why)] })
		drive.save.orders = orders
	drive.save.cash = int(drive.save.get("cash", 0)) - cost
	(drive.save.salvage.bought as Array).append(i)
	Awards.bump("salvage_buys")
	SaveGame.write(drive.save)
	if String(it.kind) == "wear":
		return "THE NEPHEW PUTS IT IN. %s. $%d, AND $%d FOR THE NEPHEW." % [_took(float(WEAR[String(it.id)].h)), int(it.price), NEPHEW]
	return "$%d. THE YARD TRUCK DROPS IT AT COVINGTON'S IN AN HOUR. GUS OPENS THE BOX." % int(it.price)

static func _took(h: float) -> String:
	return "TAKES HALF AN HOUR" if h < 1.0 else ("TAKES AN HOUR AND A HALF" if h < 2.0 else "TAKES %d HOURS" % int(h))

## Why the nephew won't put this in the car you're in ("" when he will).
func cant_swap(key: String) -> String:
	var c: PlayerCar = drive.car
	if c == null or drive.car_i < 0: return "LLOYD: \"THAT'S NOT YOUR CAR. BRING YOUR OWN CAR.\""
	if WEAR[key].has("turbo") and (c.sim.spec.engine.get("turbo", {}) as Dictionary).is_empty():
		return "LLOYD: \"YOUR CAR DOESN'T HAVE A TURBO. IT CAN HAVE THIS ONE FOR $780 MORE.\""
	return ""

## The nephew swaps a worn bit on the car you're in, and the clock runs while he does.
func swap(key: String, grade: int) -> void:
	var sim: CarSim = drive.car.sim
	var x := life(key, grade, sim.spec)
	match key:
		"clutch": sim.clutch_cond = x
		"turbo": sim.turbo_cond = x
		"pads": sim.pads_mm = x
		"motor":
			sim.engine_health = x
			sim.engine_blown = false
			sim.valves_bent = false
			sim.head_gasket = false
		"tires":
			for t in sim.tires:
				t.tread = x
				t.flat = false
	var h: float = WEAR[key].h
	SaveGame.pass_hours(drive.sky, drive.save, h)          # (past midnight, the date turns over)
	drive._store_car()

## Sell a part off Gus's bench.
func sell(id: String) -> String:
	var shelf: Array = drive.save.get("shelf", [])
	if not shelf.has(id): return ""
	shelf.erase(id)
	var p := offer(id)
	drive.save.cash = int(drive.save.get("cash", 0)) + p
	SaveGame.write(drive.save)
	return "LLOYD: \"$%d. TOBY CAN BRING IT OVER. TELL HIM NOT TO TOUCH THE DOG.\"" % p


## The trailer's window: today's pile (BUY), and what's on Gus's bench (SELL).
class YardPanel extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const GREEN := Color("6fbf5a")
	const RED := Color("e0402e")
	const RUST := Color("b0603a")
	const GRADE_COL := [Color("6fbf5a"), Color("c8d06a"), Color("d9a441"), Color("e0402e")]
	var yard: SalvageYard
	var tab := 0                 # 0 buy, 1 sell
	var sel := 0
	var note := ""

	func open() -> void:
		tab = 0
		sel = 0
		note = SalvageYard.LINES[int(yard.drive.sky.day) % SalvageYard.LINES.size()]
		visible = true

	func shelf() -> Array:
		var out: Array = []
		for id in yard.drive.save.get("shelf", []):
			if not out.has(String(id)): out.append(String(id))
		return out

	func rows() -> int:
		return yard.today().size() if tab == 0 else shelf().size()

	func _process(_dt: float) -> void:
		if not visible: return
		queue_redraw()
		var n := rows()
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("use"):
			visible = false
			return
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			tab = 1 - tab
			sel = 0
			return
		if n > 0:
			if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % n
			if Input.is_action_just_pressed("ui_up"): sel = (sel + n - 1) % n
		if not Input.is_action_just_pressed("ui_accept") or n == 0: return
		if tab == 0: note = yard.buy(sel)
		else:
			note = yard.sell(String(shelf()[sel]))
			sel = mini(sel, maxi(0, rows() - 1))

	func _draw() -> void:
		if yard == null or yard.drive.car == null: return
		var r := Rect2(80, 16, 480, 328)
		draw_rect(r, Color(0.06, 0.05, 0.04, 0.97))
		draw_rect(r, RUST, false, 1.0)
		PixelFont.draw(self, r.position + Vector2(12, 8), "NORTHSIDE SALVAGE", GOLD, 2)
		PixelFont.draw(self, r.position + Vector2(r.size.x - 120, 12), "CASH $%d" % int(yard.drive.save.get("cash", 0)), BONE)
		for i in 2:
			var tx := r.position.x + 12 + i * 70
			var on := i == tab
			draw_rect(Rect2(tx, r.position.y + 30, 64, 13), Color(1, 1, 1, 0.12 if on else 0.04))
			PixelFont.draw_centered(self, tx + 32, r.position.y + 33, ["BUY", "SELL"][i], GOLD if on else ASH)
		var y := r.position.y + 52
		var sim: CarSim = yard.drive.car.sim
		if tab == 0:
			var pile := yard.today()
			for i in pile.size():
				var it: Dictionary = pile[i]
				var gone := yard.bought(i)
				var on := i == sel
				if on: draw_rect(Rect2(r.position.x + 8, y - 3, r.size.x - 16, 20), Color(1, 1, 1, 0.1))
				var g := int(it.grade)
				draw_rect(Rect2(r.position.x + 12, y - 1, 13, 13), GRADE_COL[g] if not gone else ASH)
				PixelFont.draw_centered(self, r.position.x + 18.5, y + 2, SalvageYard.GRADES[g], Color("1a1410"))
				var col := ASH if gone else (GOLD if on else BONE)
				PixelFont.draw(self, Vector2(r.position.x + 32, y), _clip(SalvageYard.name_of(it), 60), col)
				var price := "SOLD" if gone else "$%d" % int(it.price)
				PixelFont.draw(self, Vector2(r.end.x - 12 - PixelFont.width(price), y), price, col)
				PixelFont.draw(self, Vector2(r.position.x + 32, y + 9), _sub(it, sim), ASH if gone else _sub_col(it, sim))
				y += 22
		else:
			var sh := shelf()
			if sh.is_empty():
				PixelFont.draw(self, Vector2(r.position.x + 14, y), "GUS'S BENCH IS EMPTY. HE SAYS THAT'S A FIRST.", ASH)
			for i in sh.size():
				var id: String = sh[i]
				var on := i == sel
				if on: draw_rect(Rect2(r.position.x + 8, y - 3, r.size.x - 16, 13), Color(1, 1, 1, 0.1))
				var n := (yard.drive.save.shelf as Array).count(id)
				PixelFont.draw(self, Vector2(r.position.x + 14, y), _clip(Parts.name_of(id) + ("  X%d" % n if n > 1 else ""), 46), GOLD if on else BONE)
				var p := "$%d" % SalvageYard.offer(id)
				PixelFont.draw(self, Vector2(r.end.x - 12 - PixelFont.width(p), y), p, GOLD if on else BONE)
				y += 14
				if y > r.end.y - 50: break
		var ny := r.end.y - 38
		for ln in Hud.wrap_lines(note, 110):
			PixelFont.draw(self, Vector2(r.position.x + 12, ny), ln, BONE)
			ny += 9
		var hint := "{updown}: PICK  {ui_accept}: %s  {leftright}: BUY / SELL  {ui_cancel}: LEAVE" % ("BUY" if tab == 0 else "SELL")
		PixelFont.draw_centered(self, r.get_center().x, r.end.y - 11, Hints.fmt(hint), ASH)

	static func _clip(s: String, n: int) -> String:
		return s if s.length() <= n else s.substr(0, n - 2) + ".."

	## The line under a row: for a part, whether it fits the car you came in; for a worn bit,
	## how much life it has against what's on your car now.
	func _sub(it: Dictionary, sim: CarSim) -> String:
		if String(it.kind) == "part":
			var sl := Parts.slot(String(it.id))
			var fits := Parts.fits(String(it.id), sim.spec)
			return "%s.  %s" % [String(Parts.SLOT_NAMES.get(sl, sl.to_upper())), "FITS THIS CAR" if fits else "NOT FOR THIS CAR"]
		var k := String(it.id)
		if yard.cant_swap(k) != "" and SalvageYard.WEAR[k].has("turbo"): return "YOUR CAR HAS NO TURBO"
		var mine := SalvageYard.pct(k, SalvageYard.life_now(k, sim), sim.spec)
		var theirs := SalvageYard.pct(k, SalvageYard.life(k, int(it.grade), sim.spec), sim.spec)
		return "%d%% LEFT. YOURS: %d%%. +$%d FOR THE NEPHEW, IN THE YARD" % [theirs, mine, SalvageYard.NEPHEW]

	func _sub_col(it: Dictionary, sim: CarSim) -> Color:
		if String(it.kind) == "part": return GREEN if Parts.fits(String(it.id), sim.spec) else RED
		var k := String(it.id)
		if yard.cant_swap(k) != "": return RED
		return GREEN if SalvageYard.life(k, int(it.grade), sim.spec) > SalvageYard.life_now(k, sim) else ASH
