## The garage at Covington Auto. Five tabs:
##   CARS      the cars you own; take one out, or have Gus straighten one out
##   UPGRADES  bolt on what's on the shelf (Gus charges labour), take parts back off
##   LOOKS     the body shop: paint and finish, rims, calipers, ride height, tint, stripes, kits
##   ROCKAUTTO.CA  the shop computer: order parts, standard or express shipping
##   DYNO      power and torque curves against stock, and what the car actually does
## The car you're working on is up on the left, big, in the side view, and changes as you do.
class_name GarageScreen
extends Control

signal picked(index: int)
signal repaired(index: int)
signal closed

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")
const GREEN := Color("6fbf5a")

const TABS := ["CARS", "UPGRADES", "LOOKS", "ROCKAUTTO.CA", "DYNO"]
const BAY := "1TON'S BAY"            # once 1ton's in your crew
const PAINTS := ["#c8342c", "#e0402e", "#7a1a1a", "#e8a020", "#f0d040", "#2a6a3a", "#4e8a3a", "#2c5a8a", "#3a8ad8", "#1a2a5a",
	"#6a2a4a", "#a83a8a", "#e8e4dc", "#f4f4f4", "#b8b0a0", "#8a8e94", "#4a4e54", "#1e1e24", "#6a4a2a", "#d8a878"]
const FINISHES := ["gloss", "metallic", "pearl", "matte", "chrome"]
const RIM_COLORS := ["#c8ccd4", "#1a1a1e", "#e8c040", "#e8e8ec", "#c8342c", "#2a6aa8", "#6a6a70", "#d8a060"]
const CALIPERS := ["#5a5a60", "#c8242c", "#d8b020", "#2a6aa8", "#2a8a3a", "#e8e8ec"]
const STRIPES := ["none", "racing", "side", "rally"]
const SPOILERS := ["none", "ducktail", "wing", "gt"]
const KITS := ["none", "lip", "lip + skirts", "full"]
const EXHAUSTS := ["single", "dual", "quad"]
const LOOK_ROWS := ["PAINT", "FINISH", "RIMS", "RIM COLOUR", "RIM SIZE", "CALIPERS", "RIDE HEIGHT", "TINT", "STRIPES", "STRIPE COLOUR", "SPOILER", "BODY KIT", "EXHAUST TIPS"]
## What the body shop charges for each kind of change.
const LOOK_COST := { "PAINT": 900, "FINISH": 600, "RIMS": 1200, "RIM COLOUR": 250, "RIM SIZE": 400, "CALIPERS": 180, "RIDE HEIGHT": 150,
	"TINT": 220, "STRIPES": 350, "STRIPE COLOUR": 120, "SPOILER": 450, "BODY KIT": 900, "EXHAUST TIPS": 160 }

const GUS := [
	"\"TAKE WHAT YOU WANT. BRING IT BACK IN ONE PIECE.\"",
	"\"THAT ONE MAKES A NOISE. NOT A GOOD NOISE.\"",
	"\"YOUR FATHER WOULD'VE HAD THAT RUNNING BY LUNCH.\"",
	"\"DON'T PARK IT ON THE GRASS. THE GRASS HAS FEELINGS.\"",
	"\"EVERY HORSEPOWER COSTS YOU SOMETHING. USUALLY MONEY. SOMETIMES TEETH.\"",
	"\"I'LL BOLT IT ON. I WON'T TELL YOU IT WAS A GOOD IDEA.\"",
]

var data: Dictionary
var tab := 0
var sel := 0                       # which car
var current := 0
var row := 0
var scroll := 0
var _line := 0
var note := ""
var note_t := 0.0
# upgrades: the option picked in each slot (index into _options(slot))
var opt := {}
# looks being tried on, not paid for yet
var trial := {}
var trial_paint := ""
# the site
var site_slot := 0
var site_row := 0
var express := false
# the dyno
var dyno_t := -1.0
var tune_row := 0
var preview: ImageTexture
var preview_key := ""
var rng := RandomNumberGenerator.new()

func open(save: Dictionary) -> void:
	data = SaveGame.ensure(save)
	current = int(data.current)
	sel = current
	tab = 0
	row = 0
	_line = randi() % GUS.size()
	_reset_trial()
	visible = true

func _car() -> Dictionary:
	return data.garage[sel]

func _base_spec() -> Dictionary:
	return SaveGame.load_spec(String(_car().id))

func _spec_with(parts: Dictionary) -> Dictionary:
	return Parts.apply(_base_spec(), parts)

func _say(s: String) -> void:
	note = s
	note_t = 4.0

func _reset_trial() -> void:
	trial = (_car().get("looks", {}) as Dictionary).duplicate(true)
	trial_paint = String(_car().paint)
	opt.clear()
	bay = {}

# ------------------------------------------------------------------ input

func _process(dt: float) -> void:
	if not visible: return
	CarView.screen_up = Vector2(0, -1)
	note_t -= dt
	if dyno_t >= 0.0: dyno_t += dt
	if Input.is_action_just_pressed("shift_up"): _tab(1)
	if Input.is_action_just_pressed("shift_down"): _tab(-1)
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("map"):
		visible = false
		closed.emit()
		return
	var dy := 0
	var dx := 0
	if Input.is_action_just_pressed("ui_down"): dy = 1
	if Input.is_action_just_pressed("ui_up"): dy = -1
	if Input.is_action_just_pressed("ui_right"): dx = 1
	if Input.is_action_just_pressed("ui_left"): dx = -1
	var go := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("use")
	match tabs()[tab]:
		"CARS": _cars_input(dx, go)
		"UPGRADES": _upgrades_input(dy, dx, go)
		"LOOKS": _looks_input(dy, dx, go)
		"ROCKAUTTO.CA": _site_input(dy, dx, go)
		"DYNO": _dyno_input(dy, dx, go)
		BAY: _bay_input(dy, dx, go)
	queue_redraw()

## The tabs: 1ton's bay once he's in your crew.
func tabs() -> Array:
	return TABS + ([BAY] if OneTon.in_crew(data) else [])

func _tab(d: int) -> void:
	tab = (tab + d + tabs().size()) % tabs().size()
	row = 0
	scroll = 0
	_reset_trial()

func _cars_input(dx: int, go: bool) -> void:
	if dx != 0:
		sel = (sel + dx + (data.garage as Array).size()) % (data.garage as Array).size()
		_reset_trial()
	if go:
		picked.emit(sel)
		visible = false
	if Input.is_action_just_pressed("horn") or Input.is_action_just_pressed("reset"):
		_say("GUS: \"GOOD AS NEW. GOOD AS IT WAS, ANYWAY.\"")
		repaired.emit(sel)

# ------------------------------------------------------------------ upgrades

## What can go in a slot: stock, whatever's installed, and whatever's on the shelf that fits.
func _options(sl: String) -> Array:
	var out: Array = [""]
	var inst := String(_car().parts.get(sl, ""))
	if inst != "": out.append(inst)
	for id in data.shelf:
		if Parts.slot(String(id)) == sl and Parts.fits(String(id), _base_spec(), _car().get("parts", {})) and not out.has(id): out.append(id)
	return out

## The parts as they'd be if you installed what you're looking at (so the numbers preview it).
func _shown_parts() -> Dictionary:
	var parts: Dictionary = (_car().parts as Dictionary).duplicate()
	if tabs()[tab] != "UPGRADES": return parts
	var sl: String = Parts.SLOTS[row]
	if opt.has(sl):
		var ops := _options(sl)
		var want: String = ops[clampi(int(opt[sl]), 0, ops.size() - 1)]
		if want == "": parts.erase(sl)
		else: parts[sl] = want
	return parts

func _upgrades_input(dy: int, dx: int, go: bool) -> void:
	row = clampi(row + dy, 0, Parts.SLOTS.size() - 1)
	var sl: String = Parts.SLOTS[row]
	var ops := _options(sl)
	if not opt.has(sl): opt[sl] = ops.find(String(_car().parts.get(sl, "")))
	if dx != 0: opt[sl] = (int(opt[sl]) + dx + ops.size()) % ops.size()
	if go:
		var want: String = ops[int(opt[sl])]
		var have := String(_car().parts.get(sl, ""))
		if want == have: return
		for job in _car().get("installing", []):
			if String(job.slot) == sl:
				_say("GUS: \"I'M ALREADY IN THERE. ONE THING AT A TIME.\"")
				return
		var labour := maxi(40, int(Parts.price(want) * 0.1)) if want != "" else 40
		if int(data.cash) < labour:
			_say("GUS: \"LABOUR'S $%d. YOU'VE GOT $%d. I DON'T DO IOUS.\"" % [labour, int(data.cash)])
			return
		data.cash = int(data.cash) - labour
		if have != "": data.shelf.append(have)
		if want != "":
			# Gus takes the old one off now and the new one goes in on the clock
			data.shelf.erase(want)
			_car().parts.erase(sl)
			var hrs := Parts.install_h(want)
			_car().installing.append({ "slot": sl, "part": want, "done_h": float(data.get("clock_h", 0.0)) + hrs })
			_say("GUS STARTS ON THE %s. ABOUT %s. LABOUR: $%d." % [Parts.name_of(want), _hours(hrs), labour])
		else:
			_car().parts.erase(sl)
			_say("BACK TO STOCK. THE OLD PART GOES ON THE SHELF. LABOUR: $%d." % labour)
		opt.clear()

static func _hours(h: float) -> String:
	if h < 1.0: return "%d MINUTES" % int(h * 60.0)
	return "%.1f HOURS" % h if h < 10.0 else "%d HOURS" % int(h)

## A part Gus is still putting in, in this slot (or {}).
func _job(sl: String) -> Dictionary:
	for job in _car().get("installing", []):
		if String(job.slot) == sl: return job
	return {}

# ------------------------------------------------------------------ looks

func _look_value(r: String) -> Variant:
	match r:
		"PAINT": return trial_paint
		"FINISH": return trial.get("finish", "gloss")
		"RIMS": return trial.get("rim", "")
		"RIM COLOUR": return trial.get("rim_color", "#c8ccd4")
		"RIM SIZE": return float(trial.get("rim_size", 0.66))
		"CALIPERS": return trial.get("caliper", "#5a5a60")
		"RIDE HEIGHT": return float(trial.get("drop", 0.0))
		"TINT": return float(trial.get("tint", 0.0))
		"STRIPES": return trial.get("stripes", "none")
		"STRIPE COLOUR": return trial.get("stripe_color", "#f0ece4")
		"SPOILER": return trial.get("spoiler", "none")
		"BODY KIT": return trial.get("kit_name", "none")
		"EXHAUST TIPS": return trial.get("exhaust", "single")
	return null

static func _cycle(arr: Array, v: Variant, d: int) -> Variant:
	var i := arr.find(v)
	return arr[(maxi(i, 0) + d + arr.size()) % arr.size()]

func _looks_input(dy: int, dx: int, go: bool) -> void:
	row = clampi(row + dy, 0, LOOK_ROWS.size())          # the last row is PAY
	if dx != 0 and row < LOOK_ROWS.size():
		var r: String = LOOK_ROWS[row]
		match r:
			"PAINT": trial_paint = String(_cycle(PAINTS, trial_paint, dx))
			"FINISH": trial.finish = _cycle(FINISHES, trial.get("finish", "gloss"), dx)
			"RIMS": trial.rim = _cycle(PixCars.RIMS, trial.get("rim", PixCars.RIMS[0]), dx)
			"RIM COLOUR": trial.rim_color = _cycle(RIM_COLORS, trial.get("rim_color", RIM_COLORS[0]), dx)
			"RIM SIZE": trial.rim_size = clampf(float(trial.get("rim_size", 0.66)) + dx * 0.04, 0.5, 0.8)
			"CALIPERS": trial.caliper = _cycle(CALIPERS, trial.get("caliper", CALIPERS[0]), dx)
			"RIDE HEIGHT": trial.drop = clampf(float(trial.get("drop", 0.0)) + dx * 0.2, 0.0, 1.0)
			"TINT": trial.tint = clampf(float(trial.get("tint", 0.0)) + dx * 0.25, 0.0, 1.0)
			"STRIPES": trial.stripes = _cycle(STRIPES, trial.get("stripes", "none"), dx)
			"STRIPE COLOUR": trial.stripe_color = _cycle(PAINTS, trial.get("stripe_color", "#f4f4f4"), dx)
			"SPOILER": trial.spoiler = _cycle(SPOILERS, trial.get("spoiler", "none"), dx)
			"BODY KIT":
				trial.kit_name = _cycle(KITS, trial.get("kit_name", "none"), dx)
				trial.kit = { "lip": trial.kit_name != "none", "skirts": trial.kit_name in ["lip + skirts", "full"], "diffuser": trial.kit_name == "full" }
			"EXHAUST TIPS": trial.exhaust = _cycle(EXHAUSTS, trial.get("exhaust", "single"), dx)
	if go and row == LOOK_ROWS.size():
		var cost := _looks_cost()
		if cost == 0:
			_say("NOTHING TO PAY FOR. THE BODY SHOP IS DISAPPOINTED.")
		elif int(data.cash) < cost:
			_say("THE BODY SHOP WANTS $%d. YOU HAVE $%d." % [cost, int(data.cash)])
		else:
			data.cash = int(data.cash) - cost
			if trial_paint != String(_car().paint): Awards.bump("paint_jobs")
			_car().looks = trial.duplicate(true)
			_car().paint = trial_paint
			_say("DONE. $%d. IT LOOKS LIKE A DIFFERENT CAR. IT IS NOT A DIFFERENT CAR." % cost)

func _looks_cost() -> int:
	var old: Dictionary = _car().get("looks", {})
	var cost := 0
	if trial_paint != String(_car().paint): cost += LOOK_COST.PAINT
	var keys := { "FINISH": "finish", "RIMS": "rim", "RIM COLOUR": "rim_color", "RIM SIZE": "rim_size", "CALIPERS": "caliper", "RIDE HEIGHT": "drop",
		"TINT": "tint", "STRIPES": "stripes", "STRIPE COLOUR": "stripe_color", "SPOILER": "spoiler", "BODY KIT": "kit_name", "EXHAUST TIPS": "exhaust" }
	for r in keys:
		var k: String = keys[r]
		if str(trial.get(k, "")) != str(old.get(k, "")): cost += int(LOOK_COST[r])
	return cost

# ------------------------------------------------------------------ the parts site

func _site_parts() -> Array:
	return Parts.in_slot(Parts.SLOTS[site_slot])

func _site_input(dy: int, dx: int, go: bool) -> void:
	if dx != 0:
		site_slot = (site_slot + dx + Parts.SLOTS.size()) % Parts.SLOTS.size()
		site_row = 0
	var parts := _site_parts()
	site_row = clampi(site_row + dy, 0, parts.size())        # the last row is the shipping toggle
	if site_row == parts.size():
		if go: express = not express
		return
	if go:
		var id: String = parts[site_row]
		if not Parts.fits(id, _base_spec(), _car().get("parts", {})):
			_say("ROCKAUTTO.CA: THAT PART DOES NOT FIT A %s. WE CHECKED. WE NEVER CHECK." % String(_base_spec().model).to_upper())
			return
		var cost := Parts.price(id) + (int(Parts.price(id) * 0.25) + 40 if express else 0)
		if int(data.cash) < cost:
			_say("CARD DECLINED. THE BANK SENDS ITS REGARDS.")
			return
		data.cash = int(data.cash) - cost
		var hours := 3.0 if express else maxf(1.0, float(Parts.days(id))) * 24.0
		if Parts.days(id) == 0: hours = 1.0
		data.orders.append({ "part": id, "arrives_h": float(data.clock_h) + hours })
		_say("ORDERED: %s. $%d. ARRIVES IN %s." % [Parts.name_of(id), cost, _eta(hours)])

static func _eta(h: float) -> String:
	if h < 24.0: return "%d HOURS" % maxi(1, int(ceil(h)))
	var d := int(ceil(h / 24.0))
	return "%d DAY%s" % [d, "" if d == 1 else "S"]

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("16141a"))
	# tabs
	var x := 10.0
	var ts := tabs()
	for i in ts.size():
		var w := PixelFont.width(ts[i], 1) + 14.0
		var on := i == tab
		draw_rect(Rect2(x, 6, w, 15), Color(0.85, 0.64, 0.25, 0.35) if on else Color(1, 1, 1, 0.05))
		PixelFont.draw(self, Vector2(x + 7, 11), ts[i], GOLD if on else ASH)
		x += w + 4.0
	PixelFont.draw(self, Vector2(x + 6, 11), Hints.fmt("{shift}: TABS"), Color(ASH, 0.6))
	var cash := "$%s" % _money(int(data.cash))
	PixelFont.draw(self, Vector2(630 - PixelFont.width(cash, 2), 8), cash, GREEN, 2)
	_preview_box()
	match ts[tab]:
		"CARS": _draw_cars()
		"UPGRADES": _draw_upgrades()
		"LOOKS": _draw_looks()
		"ROCKAUTTO.CA": _draw_site()
		"DYNO": _draw_dyno()
		BAY: _draw_bay()
	if note_t > 0.0:
		draw_rect(Rect2(10, 304, 620, 14), Color(0, 0, 0, 0.7))
		PixelFont.draw(self, Vector2(16, 308), note, BONE)
	else:
		PixelFont.draw(self, Vector2(16, 308), "GUS: " + GUS[_line], Color(BONE, 0.7))
	var hint := ""
	match ts[tab]:
		BAY: hint = "{updown}: ROW  {leftright}: CHANGE  {ui_accept} ON PAY: 1TON PUTS IT IN  {ui_cancel}: CLOSE"
		"CARS": hint = "{leftright}: PICK  {use}: TAKE IT OUT  {horn}: GUS FIXES IT  {ui_cancel}: CLOSE"
		"UPGRADES": hint = "{updown}: SLOT  {leftright}: PART  {ui_accept}: INSTALL  {ui_cancel}: CLOSE"
		"LOOKS": hint = "{updown}: ROW  {leftright}: CHANGE  {ui_accept} ON PAY: PAY THE BODY SHOP  {ui_cancel}: CLOSE"
		"ROCKAUTTO.CA": hint = "{leftright}: CATEGORY  {updown}: PART  {ui_accept}: ORDER  {ui_cancel}: CLOSE"
		"DYNO": hint = "{updown}: BOOST/TIMING  {leftright}: TUNE  {ui_accept}: PULL  {ui_cancel}: CLOSE"
	PixelFont.draw(self, Vector2(16, 344), Hints.fmt(hint), ASH)

static func _money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

## The car, big, in the side view, on the shop floor, wearing whatever you're trying on.
func _preview_box() -> void:
	var r := Rect2(10, 28, 300, 160)
	draw_rect(r, Color("2a2a30"))
	draw_rect(Rect2(r.position.x, r.end.y - 40, r.size.x, 40), Color("4a4a48"))
	draw_rect(Rect2(r.position.x, r.end.y - 41, r.size.x, 1), Color("c8a030"))
	var spec := _base_spec()
	var shown := _shown_parts()
	var looks := SaveGame.car_looks({ "parts": shown, "looks": trial if tab == 2 else _car().get("looks", {}), "custom": _custom_shown() })
	var paint := trial_paint if tab == 2 else String(_car().paint)
	var key := "%s|%s|%s|%s" % [_car().id, paint, JSON.stringify(looks), JSON.stringify(_car().damage)]
	if key != preview_key:
		preview_key = key
		var len := 250 if float(spec.get("length", 4.6)) < 5.5 else 270
		looks.year = int(spec.get("year", 2000))
		var dmg := {}
		var d: Dictionary = _car().damage
		if float(d.get("front", 0.0)) > 0.3: dmg.front = float(d.front) * 0.6
		if float(d.get("rear", 0.0)) > 0.3: dmg.rear = float(d.rear) * 0.6
		preview = ImageTexture.create_from_image(PixCars.showroom(spec, len, Color(paint), looks, dmg))
	var pos := Vector2(r.get_center().x - preview.get_width() / 2.0, r.end.y - 22 - preview.get_height() + 8)
	draw_texture(preview, pos)
	var name := "%s %s '%s" % [String(spec.make).to_upper(), String(spec.model).to_upper(), str(int(spec.get("year", 0)) % 100).pad_zeros(2)]
	PixelFont.draw(self, r.position + Vector2(6, 6), name, GOLD, 2)
	# the numbers, under the car
	var cur := OneTon.apply(Parts.apply(spec, shown), { "custom": _custom_shown() })
	var pf := Perf.estimate(cur)
	var stock := Perf.estimate(spec)
	var y := r.end.y + 8.0
	_stat(y, "POWER", "%d HP" % int(pf.peaks.x), pf.peaks.x / 700.0, stock.peaks.x / 700.0)
	_stat(y + 12, "TORQUE", "%d NM" % int(pf.peaks.y), pf.peaks.y / 900.0, stock.peaks.y / 900.0)
	_stat(y + 24, "WEIGHT", "%d KG" % int(cur.mass), 1.0 - (float(cur.mass) - 700.0) / 2800.0, 1.0 - (float(spec.mass) - 700.0) / 2800.0)
	_stat(y + 36, "0-100", ("%.1f S" % pf.zero100) if pf.zero100 > 0 else "NEVER", 1.0 - clampf((float(pf.zero100) - 3.0) / 14.0, 0.0, 1.0), 1.0 - clampf((float(stock.zero100) - 3.0) / 14.0, 0.0, 1.0))
	_stat(y + 48, "TOP SPEED", "%d KM/H" % int(pf.top_kmh), pf.top_kmh / 320.0, stock.top_kmh / 320.0)
	_stat(y + 60, "GRIP", "%d%%" % int(float(cur.get("grip", 1.0)) * 100.0 * float(CarSim.COMPOUND[String(cur.tires.get("compound", "summer"))].dry) / 1.05), float(cur.get("grip", 1.0)) * 0.6 * float(CarSim.COMPOUND[String(cur.tires.get("compound", "summer"))].dry), 0.6)

func _stat(y: float, label: String, val: String, f: float, f0: float) -> void:
	PixelFont.draw(self, Vector2(14, y), label, ASH)
	draw_rect(Rect2(80, y, 150, 6), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(80, y, 150 * clampf(f0, 0.0, 1.0), 6), Color(1, 1, 1, 0.22))
	var better := f > f0 + 0.005
	draw_rect(Rect2(80, y, 150 * clampf(f, 0.0, 1.0), 6), GREEN if better else (RED if f < f0 - 0.005 else GOLD))
	PixelFont.draw(self, Vector2(236, y), val, BONE)

func _panel() -> Rect2:
	var r := Rect2(320, 28, 310, 272)
	draw_rect(r, Color(0.04, 0.035, 0.05, 0.96))
	draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
	return r

func _draw_cars() -> void:
	var r := _panel()
	var n := (data.garage as Array).size()
	for i in n:
		var car: Dictionary = data.garage[i]
		var spec := SaveGame.load_spec(String(car.id))
		var y := r.position.y + 10 + i * 30
		var on := i == sel
		draw_rect(Rect2(r.position.x + 6, y - 3, r.size.x - 12, 26), Color(0.85, 0.64, 0.25, 0.2) if on else Color(1, 1, 1, 0.03))
		draw_rect(Rect2(r.position.x + 10, y + 2, 10, 10), Color(String(car.paint)))
		PixelFont.draw(self, Vector2(r.position.x + 26, y + 1), ("%s %s" % [spec.make, spec.model]).to_upper(), GOLD if on else BONE)
		var dmg := 0.0
		for k in car.damage: dmg += float(car.damage[k])
		var cond := "MINT" if dmg < 0.05 else ("DINGED" if dmg < 0.6 else ("BEAT UP" if dmg < 1.6 else "A WRECK"))
		var info := "%s - %d PARTS%s" % [cond, (car.parts as Dictionary).size(), "  (OUT FRONT)" if i == current else ""]
		PixelFont.draw(self, Vector2(r.position.x + 26, y + 11), info, ASH)
	var s := _base_spec()
	var ls := BigFont.wrap(String(s.get("blurb", "")).to_upper(), 290, 1, false)
	for k in mini(ls.size(), 6):
		PixelFont.draw(self, Vector2(r.position.x + 10, r.position.y + 10 + n * 30 + 10 + k * 10), ls[k], Color(BONE, 0.8))
	PixelFont.draw(self, Vector2(r.position.x + 10, r.end.y - 14), "%s - %s - %s" % [String(s.engine.name).to_upper(), s.get("drivetrain", "RWD"), String(s.tires.get("size", ""))], ASH)

func _draw_upgrades() -> void:
	var r := _panel()
	var rows_vis := 13
	if row < scroll: scroll = row
	if row >= scroll + rows_vis: scroll = row - rows_vis + 1
	for k in range(scroll, mini(Parts.SLOTS.size(), scroll + rows_vis)):
		var sl: String = Parts.SLOTS[k]
		var y := r.position.y + 8 + (k - scroll) * 16
		var on := k == row
		var ops := _options(sl)
		var inst := String(_car().parts.get(sl, ""))
		var shown: String = ops[int(opt.get(sl, ops.find(inst)))] if on and opt.has(sl) else inst
		draw_rect(Rect2(r.position.x + 4, y - 3, r.size.x - 8, 14), Color(0.85, 0.64, 0.25, 0.2) if on else Color(1, 1, 1, 0.02))
		PixelFont.draw(self, Vector2(r.position.x + 8, y), Parts.SLOT_NAMES[sl], GOLD if on else ASH)
		var label := Parts.name_of(shown) if shown != "" else "STOCK"
		if on and ops.size() > 1: label = "< " + label + " >"
		var col := BONE if shown == inst else GREEN
		var job := _job(sl)
		if not job.is_empty() and not (on and opt.has(sl) and shown != inst):
			label = "GUS: %s, %s LEFT" % [Parts.name_of(String(job.part)).substr(0, 22), _hours(maxf(0.0, float(job.done_h) - float(data.get("clock_h", 0.0))))]
			col = Color("7ab8e0")
		elif shown != "":
			PixelFont.draw(self, Vector2(r.position.x + 74, y), "S%d" % Parts.stage(shown), [ASH, GREEN, GOLD, Color("e08a3a"), RED][Parts.stage(shown)])
		PixelFont.draw(self, Vector2(r.position.x + 92, y), label.substr(0, 46), col)
		var waiting := 0
		for o in data.orders:
			if Parts.slot(String(o.part)) == sl: waiting += 1
		if waiting > 0: PixelFont.draw(self, Vector2(r.end.x - 20, y), "+%d" % waiting, Color("7ab8e0"))
	var sl2: String = Parts.SLOTS[row]
	var ops2 := _options(sl2)
	var want: String = ops2[int(opt.get(sl2, 0))] if opt.has(sl2) else String(_car().parts.get(sl2, ""))
	var b := Parts.blurb(want) if want != "" else ("NOTHING ON THE SHELF FOR THIS SLOT. ORDER SOMETHING ON ROCKAUTTO.CA." if ops2.size() <= 1 else "THE PART THE CAR CAME WITH. IT WORKED FINE. MOSTLY.")
	var ls := BigFont.wrap(b, 296, 1, false)
	for k in mini(ls.size(), 3):
		PixelFont.draw(self, Vector2(r.position.x + 8, r.end.y - 34 + k * 9), ls[k], Color(BONE, 0.75))

func _draw_looks() -> void:
	var r := _panel()
	for k in LOOK_ROWS.size() + 1:
		var y := r.position.y + 8 + k * 18
		var on := k == row
		draw_rect(Rect2(r.position.x + 4, y - 4, r.size.x - 8, 16), Color(0.85, 0.64, 0.25, 0.2) if on else Color(1, 1, 1, 0.02))
		if k == LOOK_ROWS.size():
			var cost := _looks_cost()
			PixelFont.draw(self, Vector2(r.position.x + 8, y), "PAY THE BODY SHOP: $%s" % _money(cost), GREEN if cost > 0 else ASH, 1)
			continue
		var lr: String = LOOK_ROWS[k]
		PixelFont.draw(self, Vector2(r.position.x + 8, y), lr, GOLD if on else ASH)
		var v: Variant = _look_value(lr)
		var vx := r.position.x + 110
		match lr:
			"PAINT", "RIM COLOUR", "CALIPERS", "STRIPE COLOUR":
				draw_rect(Rect2(vx, y - 2, 30, 9), Color(String(v)))
				draw_rect(Rect2(vx, y - 2, 30, 9), Color(1, 1, 1, 0.3), false, 1.0)
			"RIM SIZE": PixelFont.draw(self, Vector2(vx, y), "%d IN" % int(14 + (float(v) - 0.5) * 30.0), BONE)
			"RIDE HEIGHT": PixelFont.draw(self, Vector2(vx, y), "STOCK" if float(v) < 0.05 else "-%d MM" % int(float(v) * 60.0), BONE)
			"TINT": PixelFont.draw(self, Vector2(vx, y), "%d%%" % int(float(v) * 100.0), BONE)
			_: PixelFont.draw(self, Vector2(vx, y), (String(v) if String(v) != "" else "STOCK").to_upper(), BONE)
		if on: PixelFont.draw(self, Vector2(vx - 12, y), "<", GOLD)
		if on: PixelFont.draw(self, Vector2(r.end.x - 14, y), ">", GOLD)

# ------------------------------------------------------------------ 1ton's bay

var bay := {}                      # the hydraulics and donk kit being tried on

## What the preview shows: what's being tried in 1ton's bay, or what's on the car.
func _custom_shown() -> Dictionary:
	if tabs()[tab] == BAY and not bay.is_empty(): return bay
	return _car().get("custom", {})

func _bay_cost() -> int:
	var cur: Dictionary = _car().get("custom", {})
	var cost := 0
	if int(bay.get("hyd", 0)) != int(cur.get("hyd", 0)): cost += int(OneTon.HYD[int(bay.get("hyd", 0))].price)
	if int(bay.get("donk", 0)) != int(cur.get("donk", 0)): cost += int(OneTon.DONK[int(bay.get("donk", 0))].price)
	return cost

func _bay_input(dy: int, dx: int, go: bool) -> void:
	if bay.is_empty(): bay = (_car().get("custom", {}) as Dictionary).duplicate()
	row = clampi(row + dy, 0, 2)
	if not OneTon.on_list(_base_spec()):
		if go or dx != 0: _say("1TON: \"NOT ON THE LIST. I DON'T PUT PUMPS IN THAT. MY MOTHER WOULD ASK QUESTIONS.\"")
		return
	if dx != 0:
		match row:
			0: bay.hyd = (int(bay.get("hyd", 0)) + dx + OneTon.HYD.size()) % OneTon.HYD.size()
			1: bay.donk = (int(bay.get("donk", 0)) + dx + OneTon.DONK.size()) % OneTon.DONK.size()
	if go and row == 2:
		var cost := _bay_cost()
		if cost == 0 and bay.hash() == (_car().get("custom", {}) as Dictionary).hash():
			_say("1TON: \"NOTHING TO DO. I WILL SIT HERE. I AM GOOD AT SITTING.\"")
		elif int(data.cash) < cost:
			_say("1TON: \"THE PARTS ARE $%s. YOU HAVE $%s. I CANNOT PAY FOR THEM. MY MOTHER COULD. SHE WON'T.\"" % [_money(cost), _money(int(data.cash))])
		else:
			data.cash = int(data.cash) - cost
			_car().custom = bay.duplicate()
			_say("1TON: \"%s\"" % OneTon.BAY[(int(bay.get("hyd", 0)) * 3 + int(bay.get("donk", 0))) % OneTon.BAY.size()])

func _draw_bay() -> void:
	var r := _panel()
	if bay.is_empty(): bay = (_car().get("custom", {}) as Dictionary).duplicate()
	PixelFont.draw(self, r.position + Vector2(8, 8), "1TON'S BAY: HYDRAULICS AND DONKS", GOLD)
	PixelFont.draw(self, r.position + Vector2(8, 18), "PARTS AT COST. LABOUR FREE (HIS MOTHER WOULD HEAR).", ASH)
	var listed := OneTon.on_list(_base_spec())
	var rows := [["HYDRAULICS", OneTon.HYD[int(bay.get("hyd", 0))]], ["DONK", OneTon.DONK[int(bay.get("donk", 0))]]]
	for k in 3:
		var y := r.position.y + 40 + k * 22
		var on := k == row
		draw_rect(Rect2(r.position.x + 4, y - 5, r.size.x - 8, 18), Color(0.55, 0.3, 0.7, 0.25) if on else Color(1, 1, 1, 0.02))
		if k == 2:
			var cost := _bay_cost()
			PixelFont.draw(self, Vector2(r.position.x + 8, y), "PAY FOR THE PARTS: $%s" % _money(cost), GREEN if cost > 0 else ASH)
			continue
		PixelFont.draw(self, Vector2(r.position.x + 8, y), String(rows[k][0]), GOLD if on else ASH)
		var it: Dictionary = rows[k][1]
		var v := String(it.name) + (("  " + String(it.tire)) if it.has("tire") and String(it.tire) != "" else "")
		PixelFont.draw(self, Vector2(r.position.x + 92, y), v, BONE if listed else ASH)
		if int(it.price) > 0:
			var pr := "$%s" % _money(int(it.price))
			PixelFont.draw(self, Vector2(r.end.x - 20 - PixelFont.width(pr), y), pr, ASH)
		if on:
			PixelFont.draw(self, Vector2(r.position.x + 82, y), "<", GOLD)
			PixelFont.draw(self, Vector2(r.end.x - 12, y), ">", GOLD)
	# what it does
	var h := int(bay.get("hyd", 0))
	var d := int(bay.get("donk", 0))
	var notes: Array = []
	if h > 0: notes.append("HOPS %d CM. %s TO HOP (STOPPED OR CREEPING). +%d KG." % [int(float(OneTon.HYD[h].hop) * 100.0), Hints.key("hydraulics"), int(OneTon.HYD[h].kg)])
	if d > 0: notes.append("TALLER GEARING, SLOWER OFF THE LINE, LESS GRIP, A LOT MORE ATTENTION.")
	if not listed: notes = ["THIS CAR IS NOT ON THE LIST. 1TON WON'T TOUCH IT."]
	var ny := r.position.y + 112
	for n in notes:
		for ln in Hud.wrap_lines(String(n), int((r.size.x - 16) / 4)):
			PixelFont.draw(self, Vector2(r.position.x + 8, ny), ln, ASH)
			ny += 10
	# the man himself
	var fr := Rect2(r.position.x + 8, r.end.y - 84, 56, 56)
	draw_rect(fr, Color("6a4c72"))
	draw_texture_rect(OneTon.face(), fr.grow(-3), false)
	PixelFont.draw_centered(self, fr.get_center().x, fr.end.y + 4, "1TON", GOLD)
	var said := Hud.wrap_lines(String(OneTon.BAY[_line % OneTon.BAY.size()]), int((r.end.x - fr.end.x - 16) / 4))
	for k in mini(said.size(), 6): PixelFont.draw(self, Vector2(fr.end.x + 8, fr.position.y + 2 + k * 10), said[k], BONE)

## ROCKAUTTO.CA, in a browser window on the shop's beige computer.
func _draw_site() -> void:
	var r := _panel()
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 16), Color("c8c4b8"))
	for k in 3: draw_rect(Rect2(r.position.x + 5 + k * 8, r.position.y + 5, 5, 5), [Color("e0402e"), Color("e8c040"), Color("6fbf5a")][k])
	draw_rect(Rect2(r.position.x + 32, r.position.y + 3, 200, 10), Color("f4f4f0"))
	PixelFont.draw(self, Vector2(r.position.x + 36, r.position.y + 6), "ROCKAUTTO.CA/" + String(_base_spec().model).to_upper().replace(" ", "-"), Color("3a3a40"))
	draw_rect(Rect2(r.position.x, r.position.y + 16, r.size.x, r.size.y - 16), Color("f0ece0"))
	var ink := Color("1a1614")
	var sl: String = Parts.SLOTS[site_slot]
	draw_rect(Rect2(r.position.x, r.position.y + 16, r.size.x, 14), Color("2a4a8a"))
	PixelFont.draw(self, Vector2(r.position.x + 6, r.position.y + 20), "< %s >" % Parts.SLOT_NAMES[sl], Color("f0ece0"))
	PixelFont.draw(self, Vector2(r.end.x - 100, r.position.y + 20), "%d OF %d" % [site_slot + 1, Parts.SLOTS.size()], Color("c8d4e8"))
	var parts := _site_parts()
	for k in parts.size():
		var id: String = parts[k]
		var y := r.position.y + 36 + k * 30
		var on := k == site_row
		var fits := Parts.fits(id, _base_spec(), _car().get("parts", {}))
		draw_rect(Rect2(r.position.x + 4, y - 2, r.size.x - 8, 28), Color(0.2, 0.35, 0.7, 0.18) if on else Color(0, 0, 0, 0.03))
		PixelFont.draw(self, Vector2(r.position.x + 8, y), Parts.name_of(id), ink if fits else Color(ink, 0.4))
		var price := "$%s" % _money(Parts.price(id))
		PixelFont.draw(self, Vector2(r.end.x - 8 - PixelFont.width(price), y), price, Color("c8242c"))
		var ship := "SHIPS IN %s" % (_eta(maxf(1.0, float(Parts.days(id))) * 24.0) if Parts.days(id) > 0 else "AN HOUR (HE'S IN THE LOT)")
		PixelFont.draw(self, Vector2(r.position.x + 8, y + 9), ("FITS" if fits else "DOES NOT FIT") + " - " + ship, Color("2a8a3a") if fits else Color("a83a2a"))
		if on:
			var bl := Parts.blurb(id)
			PixelFont.draw(self, Vector2(r.position.x + 8, y + 18), bl.substr(0, 74), Color(ink, 0.7))
	var ty := r.position.y + 36 + parts.size() * 30
	var on2 := site_row == parts.size()
	draw_rect(Rect2(r.position.x + 4, ty - 2, r.size.x - 8, 12), Color(0.2, 0.35, 0.7, 0.18) if on2 else Color(0, 0, 0, 0.03))
	PixelFont.draw(self, Vector2(r.position.x + 8, ty), "SHIPPING: %s" % ("EXPRESS (3 HOURS, +25% +$40)" if express else "STANDARD (FREE)"), ink)
	# what's on the way
	var oy := r.end.y - 12 - mini((data.orders as Array).size(), 4) * 9
	if not (data.orders as Array).is_empty():
		PixelFont.draw(self, Vector2(r.position.x + 8, oy - 10), "ON THE WAY:", Color(ink, 0.7))
	for k in mini((data.orders as Array).size(), 4):
		var o: Dictionary = data.orders[k]
		PixelFont.draw(self, Vector2(r.position.x + 8, oy + k * 9), "%s - %s" % [Parts.name_of(String(o.part)), _eta(maxf(0.1, float(o.arrives_h) - float(data.clock_h)))], Color("2a4a8a"))

## A dyno sheet: torque and power against rpm, this car against how it left the factory.
## The dyno tune: up/down picks boost or timing, left/right turns it, accept does a pull.
func _dyno_input(dy: int, dx: int, go: bool) -> void:
	tune_row = clampi(tune_row + dy, 0, 1)
	if dx != 0:
		var rng_t := Parts.tune_range(_car().parts, _base_spec())
		var t: Dictionary = _car().tune
		if tune_row == 0:
			if float(rng_t.boost) <= 0.0:
				_say("GUS: \"NO TURBO, NO BOOST. THAT'S HOW AIR WORKS.\"")
			else:
				t.boost = clampf(snappedf(float(t.get("boost", 0.0)) + 0.05 * dx, 0.05), 0.0, float(rng_t.boost))
		else:
			t.timing = clampi(int(t.get("timing", 0)) + dx, -2, int(rng_t.timing))
		dyno_t = -1.0
	if go: dyno_t = 0.0

func _draw_dyno() -> void:
	var r := _panel()
	var stock := _base_spec()
	var cur := SaveGame.car_spec(_car())
	var g := Rect2(r.position.x + 30, r.position.y + 14, r.size.x - 44, 140)
	draw_rect(g, Color("101012"))
	for k in 6:
		draw_line(Vector2(g.position.x, g.position.y + g.size.y * k / 5.0), Vector2(g.end.x, g.position.y + g.size.y * k / 5.0), Color(1, 1, 1, 0.06))
	var max_rpm := float(cur.engine.limiter_rpm) + 300.0
	var max_hp := maxf(Parts.peaks(cur).x, Parts.peaks(stock).x) * 1.15
	var max_tq := maxf(Parts.peaks(cur).y, Parts.peaks(stock).y) * 1.15
	var sweep := 1.0 if dyno_t < 0.0 else clampf(dyno_t / 3.0, 0.0, 1.0)
	for run in 2:
		var sp: Dictionary = stock if run == 0 else cur
		var c := CarSim.new(sp)
		var last_hp := Vector2.ZERO
		var last_tq := Vector2.ZERO
		var lim := float(sp.engine.limiter_rpm)
		var steps := 60
		for i in steps + 1:
			var rpm := 1000.0 + (lim - 1000.0) * float(i) / steps
			if run == 1 and rpm > 1000.0 + (lim - 1000.0) * sweep: break
			var boost := 1.0
			var tb: Dictionary = sp.engine.get("turbo", {})
			if not tb.is_empty():
				var spool := clampf((rpm - float(tb.spool_rpm) * 0.6) / (float(tb.spool_rpm) * 0.5), 0.0, 1.0)
				boost = float(tb.no_boost) + (1.0 - float(tb.no_boost)) * spool
			var tq := c.curve_torque(rpm) * boost
			var hp := tq * rpm / 7120.9
			var px := g.position.x + g.size.x * rpm / max_rpm
			var p_hp := Vector2(px, g.end.y - g.size.y * hp / max_hp)
			var p_tq := Vector2(px, g.end.y - g.size.y * tq / max_tq)
			if i > 0:
				draw_line(last_hp, p_hp, Color(RED, 0.35) if run == 0 else RED, 1.0 if run == 0 else 2.0)
				draw_line(last_tq, p_tq, Color(Color("7ab8e0"), 0.35) if run == 0 else Color("7ab8e0"), 1.0 if run == 0 else 2.0)
			last_hp = p_hp
			last_tq = p_tq
	PixelFont.draw(self, Vector2(g.position.x, g.end.y + 4), "1000", ASH)
	PixelFont.draw(self, Vector2(g.end.x - 30, g.end.y + 4), "%d RPM" % int(max_rpm), ASH)
	PixelFont.draw(self, Vector2(g.position.x + 4, g.position.y + 4), "POWER (HP)", RED)
	PixelFont.draw(self, Vector2(g.position.x + 4, g.position.y + 13), "TORQUE (NM)", Color("7ab8e0"))
	PixelFont.draw(self, Vector2(g.end.x - 110, g.position.y + 4), "FAINT = HOW IT CAME", ASH)
	var pk := Parts.peaks(cur)
	var pk0 := Parts.peaks(stock)
	var y := g.end.y + 16
	PixelFont.draw(self, Vector2(r.position.x + 10, y), "PEAK %d HP (%+d)   %d NM (%+d)" % [int(pk.x), int(pk.x - pk0.x), int(pk.y), int(pk.y - pk0.y)], BONE, 1)
	var pf := Perf.estimate(cur)
	PixelFont.draw(self, Vector2(r.position.x + 10, y + 12), "0-100 %.1f S   1/4 MILE %.1f S   TOP %d KM/H" % [pf.zero100, pf.quarter, int(pf.top_kmh)], BONE)
	# the tune
	var rng_t := Parts.tune_range(_car().parts, stock)
	var t: Dictionary = _car().tune
	var risk := Parts.knock_risk(_car().parts, t)
	var ty := y + 28
	draw_rect(Rect2(r.position.x + 6, ty - 4, r.size.x - 12, 36), Color(1, 1, 1, 0.04))
	PixelFont.draw(self, Vector2(r.position.x + 10, ty), "THE TUNE", GOLD)
	for k in 2:
		var on := tune_row == k
		var val := ("+%d%% BOOST" % int(float(t.get("boost", 0.0)) * 100.0)) if k == 0 else ("%+d° TIMING" % (int(t.get("timing", 0)) * 2))
		var lim := (" (MAX %d%%)" % int(float(rng_t.boost) * 100.0)) if k == 0 else (" (MAX %+d°)" % (int(rng_t.timing) * 2))
		PixelFont.draw(self, Vector2(r.position.x + 70 + k * 130, ty), ("< %s >" % val if on else val) + lim, BONE if on else ASH)
	var rl := "SAFE" if risk <= 0.0 else ("IT'LL PING ON HOT DAYS" if risk < 0.2 else ("IT WILL KNOCK. GUS LOOKS AWAY" if risk < 0.5 else "IT WILL EAT A PISTON"))
	PixelFont.draw(self, Vector2(r.position.x + 10, ty + 12), "KNOCK: " + rl, GREEN if risk <= 0.0 else (GOLD if risk < 0.2 else RED))
	var ly := ty + 40
	if dyno_t < 0.0: PixelFont.draw(self, Vector2(r.position.x + 10, ly), Hints.fmt("{ui_accept}: DO A PULL. GUS WILL STAND WELL BACK."), GOLD)
	elif dyno_t < 3.0: PixelFont.draw(self, Vector2(r.position.x + 10, ly), "BRRRRRRRRAAAAAAAAAAAAAAHHHHH", RED)
	else: PixelFont.draw(self, Vector2(r.position.x + 10, ly), "GUS: \"WELL. IT DIDN'T BLOW UP.\"", BONE)
