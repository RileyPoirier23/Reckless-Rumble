## The counter at Covington Auto: one week of shifts, Papers, Please style.
##
## Everything is drawn by code in _draw(). Documents lie on the desk and can be dragged.
## INSPECT mode: click one thing, then another, and Leo compares them (a VIN against a VIN,
## an expiry date against the calendar, a licence photo against the face at the counter,
## a plate against the stolen list). Then stamp the work order.
## Mouse, or a controller (left stick moves a cursor, A clicks and drags, Y inspects, B cancels).
class_name CounterScene
extends Node2D

const BOOTH := Rect2(0, 0, 150, 360)
const WINDOW := Rect2(150, 0, 320, 112)
const DESK := Rect2(150, 112, 320, 196)
const TRAY := Rect2(150, 308, 320, 52)
const WALL := Rect2(470, 0, 170, 360)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const RED := Color("e0402e")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const BLUE := Color("4a7ab8")
const PAPER_INK := Color("2a2420")
const PAPER_DIM := Color("7a7064")

const BUTTONS := [
	{ "id": "INSPECT", "label": "INSPECT", "sub": "I / Y", "col": Color("c8b070") },
	{ "id": "APPROVED", "label": "APPROVE", "sub": "1", "col": Color("4a8a3a") },
	{ "id": "DENIED", "label": "DENY", "sub": "2", "col": Color("a8342a") },
	{ "id": "REPORT", "label": "REPORT", "sub": "3", "col": Color("3a5a8a") },
	{ "id": "WRENCH", "label": "BAY 3", "sub": "4 OFF BOOKS", "col": Color("3a3438") },
]

const BRIEFS := [
	["GUS LEANS ON THE DOORFRAME.", "\"FRONT COUNTER'S YOURS, KID. YOUR DAD RAN IT TWENTY YEARS. READ EVERY PAPER. EVERY ONE.\"", "\"IF THE PAPERS DON'T MATCH THE CAR, IT DOESN'T GET A STICKER. I READ THE VIN OFF THE DASH MYSELF.\""],
	["A FAX FROM THE MINISTRY CURLS OUT OF THE MACHINE.", "\"EXPIRED REGISTRATIONS ARE NOW YOUR PROBLEM.\"", "GUS: \"CHECK THE DATE AGAINST THE CALENDAR. THE CALENDAR DOESN'T LIE.\""],
	["ANOTHER FAX. GUS DOESN'T EVEN LOOK UP.", "\"NO INSURANCE, NO SERVICE. AND THE LICENCE HAS TO BE THE OWNER'S.\"", "GUS: \"YOUR DAD USED TO SAY THE PAPERWORK IS THE JOB. THE WRENCHING IS THE FUN PART.\""],
	["CONSTABLE TREMBLAY DROPS OFF A STOLEN LIST AND A DOUBLE-DOUBLE.", "\"PIN THAT UP. ONE OF THOSE ROLLS IN, YOU CALL ME. YOU DON'T TOUCH IT.\"", "THEN MIA TORTELLINI CALLS. \"THE FAMILY'S SENDING CARS. YOU STILL OWE US A CAR, LEO. BAY 3. NO PAPERS.\""],
	["LAST FAX OF THE WEEK.", "\"PEOPLE ARE LENDING EACH OTHER LICENCES. CHECK THE PHOTO.\"", "GUS: \"RENT'S DUE TONIGHT. AND I HEARD THERE'S A NEW GUY ASKING AROUND ABOUT 'NEW NUMBERS'. BE SMART.\""],
]

var rules: CounterRules
var day := 0
var line: Array = []
var idx := 0
var c: Dictionary = {}               # the customer at the counter
var phase := "brief"                  # brief, counter, stamping, result, day_end, week_end
var docs: Array = []                  # [{id, pos}] back to front
var drag := -1
var drag_off := Vector2.ZERO
var inspecting := false
var pick_a: Dictionary = {}
var verdict: Dictionary = {}          # {a, b, text, good, t}
var stamped := ""
var stamp_t := 0.0
var result: Dictionary = {}
var cur := Vector2(320, 200)
var pad_cursor := false
var car_view: CarView
var demo := false
var story: Dictionary = {}          # the story step, when this shift is part of the story
var tutorial := false

## Gus, standing behind you on your first day, one tip per customer.
const TIPS := [
	"GUS: DRAG THE PAPERS AROUND. THEN INSPECT (I OR Y) AND CLICK THE VIN ON THE OWNERSHIP, THEN THE VIN ON MY SHEET.",
	"GUS: ...THAT'S A NAPKIN. I DIDN'T SEE A NAPKIN. WHAT HAPPENS IN BAY 3 IS YOUR BUSINESS NOW. (BAY 3 PAYS DOWN WHAT YOU OWE.)",
	"GUS: PLATE ON THE CAR AGAINST THE PLATE ON THE OWNERSHIP. PEOPLE SWAP 'EM. PEOPLE ARE LIKE THAT.",
	"GUS: SAFETY INSPECTIONS: TREAD, PADS, LIGHTS, RUST. INSPECT A READING AGAINST THE BULLETIN ON THE WALL.",
	"GUS: STAMP THE WORK ORDER WHEN YOU'RE SURE. WHEN YOU'RE NOT SURE, LOOK AGAIN.",
	"GUS: LAST ONE. THEN WE LOCK UP AND YOU GO DEAL WITH WHATEVER YOU'RE DEALING WITH.",
]

# the week's books
var cash := CounterRules.START_CASH
var day_log := {}
var week := { "earned": 0, "dirty": 0, "fines": 0, "citations": 0, "heat": 0, "trust": 0, "reviews": 0, "correct": 0, "seen": 0 }

func _ready() -> void:
	Controls.setup()
	rules = CounterRules.new(506 + int(Time.get_unix_time_from_system()) % 100000)
	rules.make_bolo()
	car_view = CarView.new()
	car_view.position = Vector2(WINDOW.position.x + 160, 60)
	car_view.scale = Vector2(1.5, 1.5)
	add_child(car_view)
	if StoryState.active and String(StoryState.current().get("type", "")) == "counter":
		story = StoryState.current()
		tutorial = bool(story.get("tutorial", false))
	start_day(int(story.get("day", 0)))
	if OS.get_cmdline_user_args().has("--counter-demo"):
		demo = true
		var d: Node = load("res://tests/counter_demo.gd").new()
		d.scene = self
		add_child(d)

# ------------------------------------------------------------------ the day

func start_day(d: int) -> void:
	day = d
	line = rules.day_line(day)
	if tutorial:
		# the first day: a short line, and the Familia's first napkin second in it
		line = line.slice(0, 4)
		var fam := rules.familia(day)
		fam.napkin = "BAY 3. NEW NUMBERS. DOM SAYS WELCOME TO THE FAMILY. -V"
		line.insert(1, fam)
	idx = 0
	day_log = { "earned": 0, "dirty": 0, "fines": 0, "citations": [], "heat": 0, "trust": 0, "reviews": 0, "correct": 0, "seen": 0 }
	phase = "brief"
	car_view.visible = false

func next_customer() -> void:
	if idx >= line.size():
		phase = "day_end"
		car_view.visible = false
		return
	c = line[idx]
	idx += 1
	phase = "counter"
	stamped = ""
	inspecting = false
	pick_a = {}
	verdict = {}
	var spec := { "length": c.car.len, "width": c.car.wid, "wheelbase": float(c.car.len) * 0.6 }
	car_view.art = CarArt.new(spec, Color(c.car.paint), 0.15 if c.sheet.rust else 0.0, c.person.face)
	car_view.heading = 0.0
	car_view.visible = true
	docs = [{ "id": "work", "pos": Vector2(156, 118) }, { "id": "reg", "pos": Vector2(304, 122) }, { "id": "licence", "pos": Vector2(160, 186) }]
	if not c.insurance.is_empty(): docs.append({ "id": "insurance", "pos": Vector2(306, 196) })
	docs.append({ "id": "sheet", "pos": Vector2(226, 232) })
	if c.napkin != "": docs.append({ "id": "napkin", "pos": Vector2(374, 232) })

func stamp(s: String) -> void:
	if phase != "counter": return
	stamped = s
	stamp_t = 0.0 if demo else 0.8
	phase = "stamping"
	inspecting = false
	_raise(_doc_index("work"))

func _resolve() -> void:
	result = CounterRules.judge(c, stamped, day, rules.bolo if day >= 3 else [])
	result.fine = 0
	if result.citation != "":
		result.fine = 2000 if c.kind == "sting" else CounterRules.FINE
		day_log.citations.append(result.citation)
	result.cut = result.money
	for k in ["heat", "trust", "dirty"]: day_log[k] += result[k]
	day_log.earned += result.money
	day_log.fines += result.fine
	day_log.reviews += result.review
	day_log.seen += 1
	if result.correct: day_log.correct += 1
	cash += result.money + result.dirty - result.fine
	phase = "result"

func end_day() -> void:
	if not story.is_empty():
		_clock_out()
		return
	for k in ["earned", "dirty", "fines", "heat", "trust", "reviews", "correct", "seen"]: week[k] += day_log[k]
	week.citations += day_log.citations.size()
	if day >= 4:
		_pay_bills()
		phase = "week_end"
	else:
		start_day(day + 1)

## CLOCK OUT: Leo's pay for the day (a cut of the shop's take), Bay 3 cash goes straight to
## the Familia, and the story carries on into the evening.
func _clock_out() -> void:
	var wage := 60 + int(day_log.earned * 0.15)
	StoryState.cash += wage
	StoryState.debt = maxi(0, StoryState.debt - int(day_log.dirty))
	StoryState.last_result = { "earned": day_log.earned, "dirty": day_log.dirty, "fines": day_log.fines, "correct": day_log.correct, "seen": day_log.seen, "wage": wage }
	StoryState.advance(get_tree())

var bills_paid: Array = []
func _pay_bills() -> void:
	bills_paid = []
	for b in CounterRules.BILLS:
		var paid: bool = cash >= int(b[1])
		if paid: cash -= int(b[1])
		bills_paid.append([b[0], b[1], paid])

# ------------------------------------------------------------------ input

## The little label under each stamp: the hotkey on a keyboard, the button on a pad.
func _sub(b: Dictionary) -> String:
	if not Hints.pad: return String(b.sub)
	if b.id == "INSPECT": return Hints.key("inspect")
	return ("OFF BOOKS  " if b.id == "WRENCH" else "") + "POINT + " + Hints.key("click")

func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		cur = get_global_mouse_position()
		pad_cursor = false
		if drag >= 0: _drag_to(cur)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		cur = get_global_mouse_position()
		if e.pressed: press()
		else: drag = -1
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		_toggle_inspect()
	elif e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B and e.pressed:
		_cancel()
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_1: stamp("APPROVED")
			KEY_2: stamp("DENIED")
			KEY_3: stamp("REPORT")
			KEY_4: stamp("WRENCH")
			KEY_SPACE, KEY_ENTER: if phase != "counter": press()

func _process(dt: float) -> void:
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if stick.length() > 0.2:
		pad_cursor = true
		cur = (cur + stick * stick.length() * 260.0 * dt).clamp(Vector2.ZERO, Vector2(639, 359))
		if drag >= 0: _drag_to(cur)
	if Input.is_action_just_pressed("click"): press()
	if Input.is_action_just_released("click"): drag = -1
	if Input.is_action_just_pressed("inspect"): _toggle_inspect()
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("ui_back_pad"):
		if inspecting: _cancel()
		else: get_tree().change_scene_to_file("res://title.tscn")
	if phase == "stamping":
		stamp_t -= dt
		if stamp_t <= 0.0: _resolve()
	if not verdict.is_empty():
		verdict.t -= dt
		if verdict.t <= 0.0: verdict = {}
	queue_redraw()

func press() -> void:
	match phase:
		"brief": next_customer()
		"result": next_customer()
		"day_end": end_day()
		"week_end": get_tree().change_scene_to_file("res://title.tscn")
		"counter":
			for i in BUTTONS.size():
				if _button_rect(i).has_point(cur):
					if BUTTONS[i].id == "INSPECT": _toggle_inspect()
					else: stamp(BUTTONS[i].id)
					return
			if inspecting:
				var f := field_at(cur)
				if not f.is_empty(): pick(f)
				return
			var d := _doc_at(cur)
			if d >= 0:
				d = _raise(d)
				drag = d
				drag_off = cur - docs[d].pos

func _toggle_inspect() -> void:
	if phase != "counter": return
	inspecting = not inspecting
	pick_a = {}

func _cancel() -> void:
	if inspecting and not pick_a.is_empty(): pick_a = {}
	else: inspecting = false

func _drag_to(p: Vector2) -> void:
	var size := _doc_size(docs[drag].id)
	var np: Vector2 = p - drag_off
	np.x = clampf(np.x, DESK.position.x - size.x * 0.4, DESK.end.x - size.x * 0.6)
	np.y = clampf(np.y, DESK.position.y, DESK.end.y - 16)
	docs[drag].pos = np.round()

func _raise(i: int) -> int:
	var d: Dictionary = docs[i]
	docs.remove_at(i)
	docs.append(d)
	return docs.size() - 1

func _doc_index(id: String) -> int:
	for i in docs.size():
		if docs[i].id == id: return i
	return -1

func _doc_at(p: Vector2) -> int:
	for i in range(docs.size() - 1, -1, -1):
		if Rect2(docs[i].pos, _doc_size(docs[i].id)).has_point(p): return i
	return -1

func _button_rect(i: int) -> Rect2:
	return Rect2(TRAY.position.x + 4 + i * 63, TRAY.position.y + 6, 59, 40)

# ------------------------------------------------------------------ fields and comparing

## Every clickable fact on screen: {r, key, val, label}. Documents in front win.
func fields() -> Array:
	var out: Array = []
	if phase != "counter": return out
	for i in range(docs.size() - 1, -1, -1):
		out.append_array(_doc_fields(docs[i]))
	out.append({ "r": _face_rect(), "key": "person", "val": c.face_shown, "label": "THE PERSON AT THE COUNTER" })
	out.append({ "r": _plate_rect(), "key": "plate", "val": c.car.plate, "label": "THE PLATE ON THE CAR" })
	out.append({ "r": Rect2(476, 6, 72, 40), "key": "today", "val": CounterRules.today(day), "label": "TODAY" })
	var by := 52.0
	for r in CounterRules.rules_for(day):
		var lines := wrap_text(r.text, 38)
		if r.id == "inspect":
			out.append({ "r": Rect2(476, by + 10, 158, lines.size() * 7), "key": "rule_inspect", "val": 0, "label": "THE INSPECTION RULE" })
		by += lines.size() * 7 + 3
	if day >= 3:
		out.append({ "r": _bolo_rect(), "key": "bolo", "val": rules.bolo, "label": "THE STOLEN LIST" })
	return out

func field_at(p: Vector2) -> Dictionary:
	# the top document under the cursor hides the ones under it
	var top := _doc_at(p)
	for f in fields():
		if f.r.has_point(p):
			if f.has("doc") and top >= 0 and f.doc != docs[top].id: continue
			return f
	return {}

func pick(f: Dictionary) -> void:
	if pick_a.is_empty():
		pick_a = f
		return
	if pick_a.r == f.r:
		pick_a = {}
		return
	var v := compare(pick_a, f)
	verdict = { "a": pick_a, "b": f, "text": v[0], "good": v[1], "t": 4.0 }
	pick_a = {}

## Leo reads two things side by side. Returns [what he concludes, good? (true/false/null)]
func compare(a: Dictionary, b: Dictionary) -> Array:
	var ka: String = a.key
	var kb: String = b.key
	var pair := [ka, kb]
	if ka == kb and ka in ["name", "plate", "vin", "car"]:
		return ["MATCH", true] if a.val == b.val else ["MISMATCH", false]
	if ka == kb: return ["NOTHING TO COMPARE", null]
	if pair.has("today") and (pair.has("expiry") or pair.has("start")):
		var d: Array = a.val if ka != "today" else b.val
		var k: String = ka if ka != "today" else kb
		var t := CounterRules.today(day)
		if k == "expiry":
			return ["EXPIRED " + CounterRules.date_str(d), false] if CounterRules.date_cmp(d, t) < 0 else ["STILL VALID", true]
		return ["NOT IN EFFECT YET", false] if CounterRules.date_cmp(d, t) > 0 else ["IN EFFECT", true]
	if pair.has("photo") and pair.has("person"):
		return ["SAME PERSON", true] if a.val == b.val else ["THAT'S NOT THEM", false]
	if pair.has("bolo") and (pair.has("plate") or pair.has("vin")):
		var x: Dictionary = a if ka != "bolo" else b
		for e in rules.bolo:
			if e[x.key] == x.val: return ["ON THE STOLEN LIST", false]
		return ["NOT ON THE LIST", true]
	if pair.has("rule_inspect") and pair.has("measure"):
		var m: Dictionary = a.val if ka == "measure" else b.val
		match m.kind:
			"tread":
				for t in m.v: if t < 1.6: return ["%.1f MM TREAD: FAILS" % t, false]
				return ["TREAD PASSES", true]
			"pads":
				for t in m.v: if t < 3.0: return ["%.1f MM PADS: FAILS" % t, false]
				return ["PADS PASS", true]
			"lights": return ["LIGHTS WORK", true] if m.v else ["A LIGHT IS OUT: FAILS", false]
			"rust": return ["RUSTED THROUGH: FAILS", false] if m.v else ["NO RUST-THROUGH", true]
	return ["NOTHING TO COMPARE", null]

# ------------------------------------------------------------------ documents

const DOC_W := 160.0

func _doc_rows(id: String) -> Array:
	match id:
		"work": return [["NAME", c.work.name, "name", c.work.name], ["PLATE", c.work.plate, "plate", c.work.plate],
			["CAR", c.work.car, "car", c.work.car], ["WORK", c.request, "", null]]
		"reg": return [["OWNER", c.reg.owner, "name", c.reg.owner], ["ADDRESS", c.reg.address, "", null],
			["CAR", c.reg.car, "car", c.reg.car], ["PLATE", c.reg.plate, "plate", c.reg.plate],
			["VIN", c.reg.vin, "vin", c.reg.vin], ["EXPIRES", CounterRules.date_str(c.reg.expires), "expiry", c.reg.expires]]
		"licence": return [["NAME", c.licence.name, "name", c.licence.name], ["BORN", CounterRules.date_str(c.licence.dob), "", null],
			["ADDR", c.licence.address, "", null], ["NO.", c.licence.number, "", null],
			["EXPIRES", CounterRules.date_str(c.licence.expires), "expiry", c.licence.expires]]
		"insurance": return [["INSURED", c.insurance.holder, "name", c.insurance.holder], ["COMPANY", c.insurance.insurer, "", null],
			["POLICY", c.insurance.policy, "", null], ["VIN", c.insurance.vin, "vin", c.insurance.vin],
			["FROM", CounterRules.date_str(c.insurance.from), "start", c.insurance.from], ["TO", CounterRules.date_str(c.insurance.to), "expiry", c.insurance.to]]
		"sheet":
			var s: Dictionary = c.sheet
			var tr: Array = s.tread
			var pd: Array = s.pads
			return [["VIN", s.vin, "vin", s.vin], ["ODO", "%d KM" % s.odo, "", null],
				["TREAD", "FL %.1f FR %.1f RL %.1f RR %.1f" % [tr[0], tr[1], tr[2], tr[3]], "measure", { "kind": "tread", "v": tr }],
				["PADS", "FRONT %.1f  REAR %.1f" % [pd[0], pd[1]], "measure", { "kind": "pads", "v": pd }],
				["LIGHTS", "ALL WORKING" if s.lights else "LEFT TAIL OUT", "measure", { "kind": "lights", "v": s.lights }],
				["RUST", "SURFACE ONLY" if not s.rust else "THROUGH THE ROCKER", "measure", { "kind": "rust", "v": s.rust }]]
	return []

const TITLES := { "work": "WORK ORDER - COVINGTON AUTO", "reg": "VEHICLE REGISTRATION", "licence": "DRIVER'S LICENCE",
	"insurance": "PROOF OF INSURANCE", "sheet": "GUS'S SHEET (READ OFF THE CAR)", "napkin": "" }
const PAPER := { "work": Color("efe2b0"), "reg": Color("cfe0c4"), "licence": Color("c6d6e8"), "insurance": Color("ecd2cc"),
	"sheet": Color("e8e6de"), "napkin": Color("f4f2ec") }

func _doc_size(id: String) -> Vector2:
	match id:
		"licence": return Vector2(DOC_W, 58)
		"napkin": return Vector2(92, 18 + wrap_text(c.napkin, 20).size() * 8)
		"work": return Vector2(DOC_W, 14 + 4 * 9 + 18)
	return Vector2(DOC_W, 14 + _doc_rows(id).size() * 9 + 4)

func _row_x(id: String) -> float:
	return 40.0 if id == "licence" else 4.0

func _doc_fields(d: Dictionary) -> Array:
	var out: Array = []
	var rows := _doc_rows(d.id)
	var x0 := _row_x(d.id)
	for i in rows.size():
		if rows[i][2] == "": continue
		out.append({ "r": Rect2(d.pos + Vector2(x0, 12 + i * 9), Vector2(DOC_W - x0 - 4, 8)), "key": rows[i][2], "val": rows[i][3],
			"label": "%s ON THE %s" % [rows[i][0], TITLES[d.id].split(" - ")[0]], "doc": d.id })
	if d.id == "licence":
		out.append({ "r": Rect2(d.pos + Vector2(4, 13), Vector2(32, 32)), "key": "photo", "val": c.licence.face, "label": "THE LICENCE PHOTO", "doc": d.id })
	return out

func _draw_doc(d: Dictionary) -> void:
	var size := _doc_size(d.id)
	var r := Rect2(d.pos, size)
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	var paper: Color = PAPER[d.id]
	draw_rect(r, paper)
	draw_rect(r, paper.darkened(0.35), false, 1.0)
	if d.id == "napkin":
		for i in 6: draw_rect(Rect2(r.position + Vector2(4 + i * 15, 3), Vector2(8, 1)), paper.darkened(0.08))
		var ls := wrap_text(c.napkin, 20)
		for i in ls.size(): PixelFont.draw(self, r.position + Vector2(6, 9 + i * 8), ls[i], Color("2a3a7a"))
		return
	draw_rect(Rect2(r.position, Vector2(size.x, 10)), paper.darkened(0.18))
	PixelFont.draw(self, r.position + Vector2(4, 3), TITLES[d.id], PAPER_INK)
	var rows := _doc_rows(d.id)
	var x0 := _row_x(d.id)
	for i in rows.size():
		var p: Vector2 = r.position + Vector2(x0, 14 + i * 9)
		PixelFont.draw(self, p, rows[i][0], PAPER_DIM)
		PixelFont.draw(self, p + Vector2(32, 0), str(rows[i][1]), PAPER_INK)
	if d.id == "licence":
		draw_rect(Rect2(r.position + Vector2(3, 12), Vector2(34, 34)), paper.darkened(0.3))
		draw_texture(_face_tex(c.licence.face, true), r.position + Vector2(4, 13))
	if d.id == "work":
		var box := Rect2(r.position + Vector2(size.x - 70, size.y - 17), Vector2(66, 14))
		draw_rect(box, paper.darkened(0.12))
		if stamped == "": PixelFont.draw_centered(self, box.get_center().x, box.position.y + 5, "STAMP HERE", PAPER_DIM)
		else:
			var col: Color = Color("2f7a2a") if stamped == "APPROVED" else (Color("a8282a") if stamped == "DENIED" else (Color("2a4a8a") if stamped == "REPORT" else Color("3a3438")))
			draw_rect(box.grow(1), col, false, 2.0)
			PixelFont.draw_centered(self, box.get_center().x, box.position.y + 3, {"APPROVED": "APPROVED", "DENIED": "DENIED", "REPORT": "REPORTED", "WRENCH": "BAY 3"}[stamped], col, 2)

# ------------------------------------------------------------------ drawing

const _WOMEN := ["DANIELLE", "KAYLA", "NATALIE", "CHANTAL", "MELANIE", "AMBER", "KRISTA", "SYLVIE", "JESSICA", "MONIQUE", "ASHLEY", "BRITTANY", "NICOLE", "TAMMY"]

## The customer's face (or the licence photo): a CAGE BOSS-style portrait that matches the
## name's gender and the age on the date of birth.
func _face_tex(seed: int, small := false) -> ImageTexture:
	var fem := 1 if str(c.person.first) in _WOMEN else 0
	var age := CounterRules.YEAR - int(c.person.dob[0])
	return Face.small_texture(seed, fem, age) if small else Face.texture(seed, fem, age)

func _face_rect() -> Rect2:
	return Rect2(11, 10, 128, 128)   # the 64px portrait at 2x, above the counter top (y 142)

func _plate_rect() -> Rect2:
	return Rect2(WINDOW.position.x + 18, 84, 56, 20)

func _bolo_rect() -> Rect2:
	return Rect2(476, 236, 158, 76)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("1c1a1e"))
	_draw_booth()
	_draw_window()
	_draw_wall()
	# desk
	draw_rect(DESK, Color("5a4232"))
	for i in 12: draw_line(Vector2(DESK.position.x, DESK.position.y + 8 + i * 16), Vector2(DESK.end.x, DESK.position.y + 10 + i * 16), Color("4e382a"), 1.0)
	if phase in ["counter", "stamping", "result"]:
		for d in docs: _draw_doc(d)
	_draw_tray()
	if phase in ["counter", "stamping"]: _draw_inspect()
	match phase:
		"brief": _draw_brief()
		"result": _draw_result()
		"day_end": _draw_day_end()
		"week_end": _draw_week_end()
	if tutorial and phase in ["counter", "stamping"] and idx - 1 < TIPS.size():
		var ls := wrap_text(TIPS[idx - 1], 74)
		_panel(Rect2(150, 0, 320, 6 + ls.size() * 8), 0.92)
		for k in ls.size(): PixelFont.draw(self, Vector2(156, 3 + k * 8), ls[k], Color("c8c0a8"))
	if pad_cursor or demo: _draw_cursor()

func _panel(r: Rect2, a := 0.9) -> void:
	draw_rect(r, Color(0.04, 0.035, 0.05, a))
	draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)

func _draw_booth() -> void:
	draw_rect(BOOTH, Color("2a2a32"))
	draw_rect(Rect2(0, 0, 150, 150), Color("3a3a44"))
	for i in 7: draw_rect(Rect2(0, i * 22, 150, 1), Color("34343c"))
	if phase in ["counter", "stamping", "result"]:
		draw_texture_rect(_face_tex(c.face_shown), _face_rect(), false)
		# the counter top and the glass
		draw_rect(Rect2(0, 142, 150, 8), Color("6a5a48"))
		draw_rect(Rect2(8, 8, 134, 134), Color(0.7, 0.85, 1.0, 0.06))
		draw_line(Vector2(20, 14), Vector2(48, 42), Color(1, 1, 1, 0.12), 2.0)
		var said := _speech()
		var ls := wrap_text(said, 33)
		var bh: int = 10 + ls.size() * 8
		draw_rect(Rect2(6, 158, 138, bh), BONE)
		draw_colored_polygon(PackedVector2Array([Vector2(60, 158), Vector2(76, 158), Vector2(70, 150)]), BONE)
		for i in ls.size(): PixelFont.draw(self, Vector2(11, 163 + i * 8), ls[i], INK)
		PixelFont.draw(self, Vector2(8, 340), "CUSTOMER %d OF %d" % [idx, line.size()], ASH)
	else:
		draw_rect(Rect2(0, 142, 150, 8), Color("6a5a48"))
		PixelFont.draw_centered(self, 75, 70, "CLOSED", ASH, 2)
	PixelFont.draw(self, Vector2(8, 350), Hints.fmt("{menu_back}: MENU"), Color(ASH, 0.6))

func _speech() -> String:
	match c.kind:
		"familia": return "DOM SENT ME. HE SAYS YOU'D UNDERSTAND THE NAPKIN."
		"sting": return "HEY MAN. A BUDDY SAID YOU CAN HELP ME OUT. I GOT CASH."
	var asks := { "SAFETY INSPECTION": "HI. I NEED A SAFETY INSPECTION.", "OIL CHANGE": "JUST AN OIL CHANGE, PLEASE.",
		"BRAKE JOB": "MY BRAKES ARE GRINDING. CAN YOU DO A BRAKE JOB?", "WINTER TIRES ON": "HI. I NEED MY WINTER TIRES PUT ON.",
		"CHECK ENGINE LIGHT": "MY CHECK ENGINE LIGHT IS ON. AGAIN." }
	var s: String = asks.get(c.request, "HI.")
	if c.insurance.is_empty() and day >= 2: s += " INSURANCE? UH, IT'S IN MY OTHER CAR."
	return s

func _draw_window() -> void:
	draw_rect(WINDOW, Color("6a6c70"))
	# the bay: concrete, a drain, the lift posts, the window frame
	draw_rect(Rect2(WINDOW.position + Vector2(0, 20), Vector2(WINDOW.size.x, 92)), Color("8a8a86"))
	for i in 8: draw_rect(Rect2(WINDOW.position.x + i * 40 + 6, 22, 1, 88), Color("7e7e7a"))
	draw_rect(Rect2(WINDOW.position.x + 60, 26, 6, 66), Color("c8a030"))
	draw_rect(Rect2(WINDOW.position.x + 236, 26, 6, 66), Color("c8a030"))
	draw_rect(Rect2(WINDOW.position, Vector2(WINDOW.size.x, 18)), Color("3a3a40"))
	PixelFont.draw(self, WINDOW.position + Vector2(6, 6), "BAY 1", ASH)
	PixelFont.draw(self, WINDOW.position + Vector2(250, 6), "COVINGTON AUTO", GOLD)
	if phase in ["counter", "stamping", "result"]:
		var pr := _plate_rect()
		draw_rect(pr, Color("e8e4d4"))
		draw_rect(pr, Color("2a4a8a"), false, 1.0)
		PixelFont.draw_centered(self, pr.get_center().x, pr.position.y + 2, "PORT RUMBLE", Color("2a4a8a"))
		PixelFont.draw_centered(self, pr.get_center().x, pr.position.y + 9, c.car.plate, INK, 1)
		draw_rect(Rect2(pr.position + Vector2(3, 16), Vector2(pr.size.x - 6, 1)), Color("2a4a8a"))
		draw_line(pr.position + Vector2(56, 10), Vector2(car_view.position.x - float(c.car.len) * 9.0, car_view.position.y), Color(1, 1, 1, 0.25), 1.0)
		PixelFont.draw(self, WINDOW.position + Vector2(96, 98), "%s %s" % [c.car.make, c.car.model], BONE)
	draw_rect(WINDOW, Color("2a2a30"), false, 3.0)

func _draw_wall() -> void:
	draw_rect(WALL, Color("4a4038"))
	# calendar
	draw_rect(Rect2(476, 6, 72, 40), Color("f0ece0"))
	draw_rect(Rect2(476, 6, 72, 10), RED)
	var t := CounterRules.today(day)
	PixelFont.draw_centered(self, 512, 9, CounterRules.DAYS[day], BONE)
	PixelFont.draw_centered(self, 512, 20, "%s %d" % [CounterRules.MONTHS[t[1] - 1], t[0]], INK)
	PixelFont.draw_centered(self, 512, 29, str(t[2]), INK, 2)
	# cash and how people feel about you
	_panel(Rect2(554, 6, 80, 40), 0.6)
	PixelFont.draw(self, Vector2(558, 10), "CASH", ASH)
	PixelFont.draw(self, Vector2(580, 10), "$%d" % cash, GREEN if cash >= 0 else RED)
	PixelFont.draw(self, Vector2(558, 20), "HEAT", ASH)
	PixelFont.draw(self, Vector2(580, 20), str(week.heat + day_log.heat), RED if week.heat + day_log.heat > 30 else BONE)
	PixelFont.draw(self, Vector2(558, 30), "FAMILIA", ASH)
	PixelFont.draw(self, Vector2(590, 30), "%+d" % (week.trust + day_log.trust), BONE)
	# the Ministry bulletin
	draw_rect(Rect2(474, 50, 162, 182), Color("e8e4d8"))
	PixelFont.draw(self, Vector2(478, 53), "MINISTRY BULLETIN - INSPECTION STATIONS", PAPER_INK)
	var by := 62.0
	for r in CounterRules.rules_for(day):
		var ls := wrap_text(r.text, 38)
		var col := RED.darkened(0.2) if r.day == day else PAPER_INK
		for i in ls.size(): PixelFont.draw(self, Vector2(478, by + i * 7), ls[i], col)
		by += ls.size() * 7 + 3
	# the stolen list
	if day >= 3:
		var br := _bolo_rect()
		draw_rect(br, Color("f2f0e8"))
		draw_rect(Rect2(br.position, Vector2(br.size.x, 9)), BLUE)
		PixelFont.draw(self, br.position + Vector2(3, 2), "PORT RUMBLE POLICE - STOLEN", BONE)
		for i in rules.bolo.size():
			var b: Dictionary = rules.bolo[i]
			PixelFont.draw(self, br.position + Vector2(4, 12 + i * 10), b.plate, INK)
			PixelFont.draw(self, br.position + Vector2(36, 12 + i * 10), b.car, PAPER_DIM)
		draw_circle(br.position + Vector2(br.size.x / 2, 1), 2, RED)
	else:
		PixelFont.draw(self, Vector2(478, 250), "(A CORKBOARD. EMPTY FOR NOW.)", ASH)
	# help
	var help := ["DRAG PAPERS AROUND THE DESK.", "INSPECT: CLICK TWO THINGS", "TO COMPARE THEM.", "THEN STAMP THE WORK ORDER."]
	for i in help.size(): PixelFont.draw(self, Vector2(478, 320 + i * 8), help[i], Color(BONE, 0.55))

func _draw_tray() -> void:
	draw_rect(TRAY, Color("2a2420"))
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var r := _button_rect(i)
		var on: bool = phase == "counter" and r.has_point(cur)
		var col: Color = b.col
		if b.id == "INSPECT" and inspecting: col = GOLD
		draw_rect(r, col.lightened(0.15) if on else col)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), col.darkened(0.4))
		PixelFont.draw_centered(self, r.get_center().x, r.position.y + 10, b.label, BONE, 2, INK)
		PixelFont.draw_centered(self, r.get_center().x, r.position.y + 26, _sub(b), Color(BONE, 0.7))

func _draw_inspect() -> void:
	if inspecting:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.85, 0.7, 0.2, 0.06))
		var h := field_at(cur)
		if not h.is_empty(): draw_rect(h.r.grow(1), Color(GOLD, 0.8), false, 1.0)
		if not pick_a.is_empty():
			draw_rect(pick_a.r.grow(2), GOLD, false, 2.0)
			draw_line(pick_a.r.get_center(), cur, Color(GOLD, 0.6), 1.0)
		var tip := "INSPECT: PICK SOMETHING" if pick_a.is_empty() else "COMPARE %s WITH...?" % pick_a.label
		var w := PixelFont.width(tip) + 10
		_panel(Rect2(310 - w / 2.0, 114, w, 11))
		PixelFont.draw_centered(self, 310, 117, tip, GOLD)
	if not verdict.is_empty():
		var col: Color = GREEN if verdict.good == true else (RED if verdict.good == false else ASH)
		var a: Dictionary = verdict.a
		var b: Dictionary = verdict.b
		draw_rect(a.r.grow(2), col, false, 2.0)
		draw_rect(b.r.grow(2), col, false, 2.0)
		draw_line(a.r.get_center(), b.r.get_center(), col, 1.0)
		var mid: Vector2 = (a.r.get_center() + b.r.get_center()) / 2.0
		var w := PixelFont.width(verdict.text, 2) + 12
		mid.x = clampf(mid.x, w / 2.0 + 2, 638 - w / 2.0)
		draw_rect(Rect2(mid.x - w / 2.0, mid.y - 8, w, 16), Color(col.darkened(0.55), 0.95))
		draw_rect(Rect2(mid.x - w / 2.0, mid.y - 8, w, 16), col, false, 1.0)
		PixelFont.draw_centered(self, mid.x, mid.y - 4, verdict.text, BONE, 2)

func _draw_brief() -> void:
	var r := Rect2(60, 40, 520, 280)
	_panel(r, 0.95)
	var t := CounterRules.today(day)
	PixelFont.draw_centered(self, 320, 54, "%s, %s" % [CounterRules.DAYS[day], CounterRules.date_str(t)], GOLD, 3, INK)
	PixelFont.draw_centered(self, 320, 76, "WEEK ONE AT COVINGTON AUTO" if day == 0 else "DAY %d OF 5" % (day + 1), ASH)
	var y := 96.0
	var paras: Array = BRIEFS[day]
	if tutorial:
		paras = ["CLOCK IN: 8:00 A.M. GUS IS LEANING ON THE DOORFRAME WITH A COFFEE THAT SAYS WORLD'S OKAYEST BOSS.",
			StoryState.fill("\"THAT'S {MANAGER}'S MUG. I SAID DON'T TOUCH THE MUG. FINE. KEEP IT. READ EVERY PAPER.\""),
			"\"I'LL BE RIGHT BEHIND YOU. NOT HELPING. JUST BEHIND YOU.\""]
	for para in paras:
		for l in wrap_text(para, 62):
			PixelFont.draw(self, Vector2(80, y), l, BONE, 2)
			y += 13
		y += 6
	var news := CounterRules.RULES.filter(func(x): return x.day == day)
	if not news.is_empty():
		PixelFont.draw(self, Vector2(80, y + 4), "NEW ON THE BULLETIN:", RED)
		y += 14
		for n in news:
			for l in wrap_text(n.text, 100):
				PixelFont.draw(self, Vector2(80, y), l, BONE)
				y += 8
	PixelFont.draw_centered(self, 320, 304, Hints.fmt("{ui_accept}: OPEN THE COUNTER") if Hints.pad else "CLICK, SPACE OR ENTER TO OPEN THE COUNTER", Color(BONE, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)))

func _draw_result() -> void:
	var r := Rect2(164, 128, 292, 168)
	_panel(r, 0.94)
	var good: bool = result.correct
	PixelFont.draw_centered(self, 310, 138, {"APPROVED": "APPROVED", "DENIED": "DENIED", "REPORT": "REPORTED TO POLICE", "WRENCH": "BAY 3, NO PAPERS"}[stamped], GOLD, 2)
	var y := 158.0
	for l in wrap_text(result.line, 66):
		PixelFont.draw(self, Vector2(174, y), l, BONE)
		y += 8
	y += 6
	if result.money > 0: PixelFont.draw(self, Vector2(174, y), "+$%d FOR THE SHOP" % result.money, GREEN, 2); y += 14
	if result.dirty > 0: PixelFont.draw(self, Vector2(174, y), "+$%d CASH. NO RECEIPT." % result.dirty, GOLD, 2); y += 14
	if result.citation != "":
		PixelFont.draw(self, Vector2(174, y), "MINISTRY CITATION  -$%d" % result.fine, RED, 2); y += 14
		for l in wrap_text(result.citation, 66):
			PixelFont.draw(self, Vector2(174, y), l, RED.lightened(0.3))
			y += 8
	if result.heat > 0: PixelFont.draw(self, Vector2(174, y + 2), "HEAT +%d" % result.heat, RED); y += 10
	if result.trust != 0: PixelFont.draw(self, Vector2(174, y + 2), "FAMILIA %+d" % result.trust, ASH); y += 10
	if c.kind == "regular" and not good and result.citation == "":
		PixelFont.draw(self, Vector2(174, y + 2), "THERE WAS NOTHING WRONG WITH THAT ONE.", ASH)
	PixelFont.draw_centered(self, 310, 284, "NEXT" if idx < line.size() else "CLOSE UP FOR THE DAY", Color(BONE, 0.7))

func _draw_day_end() -> void:
	var r := Rect2(120, 40, 400, 280)
	_panel(r, 0.96)
	PixelFont.draw_centered(self, 320, 54, "%s IS DONE" % CounterRules.DAYS[day], GOLD, 3, INK)
	var y := 84.0
	var rows := [["CUSTOMERS", "%d (%d RIGHT CALLS)" % [day_log.seen, day_log.correct], BONE],
		["SHOP MONEY", "+$%d" % day_log.earned, GREEN], ["CASH, NO RECEIPTS", "+$%d" % day_log.dirty, GOLD],
		["CITATIONS", "%d  (-$%d)" % [day_log.citations.size(), day_log.fines], RED if day_log.fines > 0 else BONE],
		["REVIEWS", "%+d STARS" % day_log.reviews, BONE], ["HEAT", "%+d" % day_log.heat, BONE], ["FAMILIA", "%+d" % day_log.trust, BONE],
		["CASH ON HAND", "$%d" % cash, GREEN if cash >= 0 else RED]]
	for row in rows:
		PixelFont.draw(self, Vector2(150, y), row[0], ASH, 2)
		PixelFont.draw(self, Vector2(330, y), row[1], row[2], 2)
		y += 16
	for cit in day_log.citations.slice(0, 3):
		PixelFont.draw(self, Vector2(150, y), "- " + cit, RED.lightened(0.3))
		y += 8
	if day == 3: PixelFont.draw_centered(self, 320, y + 6, "TOMORROW IS FRIDAY. BILLS ARE DUE.", GOLD)
	if not story.is_empty():
		PixelFont.draw_centered(self, 320, 286, "LEO'S PAY: $%d.  BAY 3 CASH GOES TO THE FAMILIA: OWED $%d." % [60 + int(day_log.earned * 0.15), maxi(0, StoryState.debt - int(day_log.dirty))], GOLD)
		PixelFont.draw_centered(self, 320, 304, "CLOCK OUT", Color(BONE, 0.7 + 0.3 * sin(Time.get_ticks_msec() / 250.0)), 2)
	else:
		PixelFont.draw_centered(self, 320, 304, "GO HOME" if day < 4 else "PAY THE BILLS", Color(BONE, 0.7))

func _draw_week_end() -> void:
	var r := Rect2(80, 20, 480, 320)
	_panel(r, 0.97)
	PixelFont.draw_centered(self, 320, 32, "FRIDAY NIGHT. THE BILLS.", GOLD, 3, INK)
	var y := 60.0
	var short := 0
	for b in bills_paid:
		PixelFont.draw(self, Vector2(110, y), b[0], BONE, 2)
		PixelFont.draw(self, Vector2(400, y), ("$%d" % b[1]) if b[2] else "CAN'T PAY", GREEN if b[2] else RED, 2)
		if not b[2]: short += int(b[1])
		y += 15
	PixelFont.draw(self, Vector2(110, y + 2), "LEFT IN THE TILL", ASH, 2)
	PixelFont.draw(self, Vector2(400, y + 2), "$%d" % cash, BONE, 2)
	y += 26
	var lines: Array = []
	if short == 0: lines.append("EVERYTHING'S PAID. GUS COUNTS THE TILL TWICE AND NODS ONCE. FROM GUS, THAT'S A PARADE.")
	for b in bills_paid:
		if b[2]: continue
		match b[0]:
			"RENT ON THE GARAGE": lines.append("THE LANDLORD TAPES A NOTICE TO THE BAY DOOR. YOU HAVE UNTIL THE END OF THE MONTH.")
			"THE FAMILIA (FOR MIA'S CAR)": lines.append("SATURDAY MORNING YOUR CAR HAS NO WINDSHIELD. THERE'S A NAPKIN ON THE SEAT: \"FRIDAY. -M\"")
			"ARIES'S HOCKEY": lines.append("ARIES SAYS IT'S FINE, SHE DIDN'T WANT TO PLAY THIS SEASON ANYWAY. SHE'S LYING.")
			"GUS'S PAY": lines.append("GUS DOESN'T SAY A WORD ABOUT HIS PAY. HE SHOWS UP SATURDAY ANYWAY.")
	if week.heat >= 50: lines.append("A CAR PARKS ACROSS THE STREET ALL WEEKEND. NOBODY GETS OUT.")
	if week.trust >= 15: lines.append("DOM SENDS A TRAY OF LASAGNA. NOBODY KNOWS HOW HE GOT INTO THE GARAGE.")
	elif week.trust <= -30: lines.append("SOMEBODY LETS THE AIR OUT OF ALL FOUR OF YOUR TIRES. NEATLY.")
	if week.citations >= 4: lines.append("THE MINISTRY WANTS A MEETING ABOUT YOUR INSPECTION LICENCE.")
	if week.reviews >= 8: lines.append("COVINGTON AUTO HITS 4.6 STARS. SOMEONE WRITES \"JUST LIKE WHEN FRANK RAN IT.\"")
	for para in lines:
		for l in wrap_text(para, 76):
			PixelFont.draw(self, Vector2(100, y), l, BONE)
			y += 8
		y += 5
	PixelFont.draw_centered(self, 320, 300, "%d CUSTOMERS. %d RIGHT CALLS. %d CITATIONS." % [week.seen, week.correct, week.citations], ASH)
	PixelFont.draw_centered(self, 320, 312, "END OF WEEK ONE. THE FULL GAME HAS EIGHT YEARS OF THESE.", ASH)
	PixelFont.draw_centered(self, 320, 326, "BACK TO THE MENU", Color(BONE, 0.7))

func _draw_cursor() -> void:
	var p := cur.round()
	var col := GOLD if inspecting else BONE
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(0, 10), p + Vector2(3, 7), p + Vector2(7, 7)]), INK)
	draw_colored_polygon(PackedVector2Array([p + Vector2(1, 2), p + Vector2(1, 8), p + Vector2(3, 6), p + Vector2(5, 6)]), col)

## Word-wraps to `n` characters a line.
static func wrap_text(text: String, n: int) -> Array[String]:
	var out: Array[String] = []
	var cur_line := ""
	for word in text.split(" "):
		if cur_line == "": cur_line = word
		elif cur_line.length() + 1 + word.length() <= n: cur_line += " " + word
		else:
			out.append(cur_line)
			cur_line = word
	if cur_line != "": out.append(cur_line)
	return out
