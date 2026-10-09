## A MarketThing meetup in the drive scene: the GPS to the seller, the parking-lot inspection
## (touch the hood, pull the dipstick, the creeper light...), the test drive in their car with
## its faults in it, and buying it into the garage.
class_name MarketRunner
extends Node2D

var drive: Node
var l := {}                      # the listing you're meeting about ({} when none)
var stage := ""                  # drive, meet, test
var place := {}
var t := 0.0
var panel: MeetPanel
var _test_t := 0.0
var _test_dmg := 0.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	z_index = 3050
	z_as_relative = false
	panel = MeetPanel.new()
	panel.runner = self
	panel.size = Vector2(640, 360)
	panel.visible = false
	drive.get_node("HudLayer").add_child(panel)

func active() -> bool:
	return not l.is_empty()

func panel_open() -> bool:
	return panel.visible

func start(listing: Dictionary) -> void:
	if bool(listing.get("ghosted", false)):
		drive.hud.post("THEY LEFT YOU ON SEEN. NOBODY'S MEETING YOU.", 4.0)
		return
	l = listing
	var places: Array = Market.places(drive.world.map)
	place = places[int(l.place) % places.size()]
	stage = "drive"
	drive._on_dest(String(place.name), place.p)
	var e := CarCatalog.entry(String(l.car))
	drive.hud.objective = "MARKETTHING: MEET THE SELLER AT %s ABOUT THE %s %s. STOP IN THE LOT." % [place.name, String(e.make).to_upper(), String(e.model).to_upper()]

func cancel() -> void:
	if stage == "test": _end_test(false)
	l = {}
	stage = ""
	panel.visible = false
	drive.hud.objective = ""
	drive.clear_route()

func _process(dt: float) -> void:
	queue_redraw()
	if not active() or drive.car == null: return
	t += dt
	var c: PlayerCar = drive.car
	match stage:
		"drive":
			if c.sim.pos.distance_to(place.p) < 20.0 and c.sim.speed() < 2.0 and not panel.visible:
				drive.hud.post(Hints.fmt("{use}: MEET THE SELLER"), 0.2)
				if Input.is_action_just_pressed("use"): open_meet()
		"test":
			_test_t -= dt
			var dmg := _damage_sum()
			var left := maxi(0, int(_test_t))
			drive.hud.objective = "TEST DRIVE: BRING IT BACK TO THE SELLER.  %d:%02d" % [left / 60, left % 60]
			if (c.sim.pos.distance_to(place.p) < 18.0 and c.sim.speed() < 2.0 and _test_t < 140.0) or _test_t <= 0.0:
				if _test_t <= 0.0: drive.hud.post("THE SELLER'S ON THE PHONE WITH THE POLICE. YOU BRING IT BACK.", 5.0)
				_test_dmg = dmg
				_end_test(true)

func open_meet() -> void:
	stage = "meet"
	drive.hud.objective = ""
	if Market.SELLERS[String(l.seller)].has("scam"):
		drive.hud.post("NOBODY. THE PROFILE IS GONE. IT WAS ALWAYS GOING TO BE GONE.", 6.0)
		l.sold = true
		cancel()
		return
	panel.open(l)

# ------------------------------------------------------------------ the meetup's actions

func do_check(check: String) -> String:
	drive.sky.time_h = fmod(drive.sky.time_h + 1.0 / 6.0, 24.0)       # ten minutes with your head under the hood
	return String(Market.inspect(l, check).text)

func start_test() -> void:
	panel.visible = false
	stage = "test"
	_test_t = 150.0
	drive.job_swap_car(String(l.car))
	drive.car.sim.set_wear(Market.wear_for(l))
	drive.car.sim.coolant_c = 80.0
	drive.hud.post("THE SELLER HANDS YOU THE KEYS. \"DON'T GO FAR.\"", 4.0)

func _end_test(back: bool) -> void:
	var res := Market.inspect(l, "test_drive")
	drive.job_restore_car("THE SELLER TAKES THE KEYS BACK. YOU'RE IN YOUR OWN CAR AGAIN.")
	drive._teleport(place.p, drive.car.sim.heading)
	stage = "meet"
	if _test_dmg > 0.05:
		var bill := int(_test_dmg * 2000.0)
		drive.save.cash = int(drive.save.cash) - bill
		panel.log_line("YOU BENT THEIR CAR. THEY WANT $%d. YOU PAY." % bill)
	panel.log_line("TEST DRIVE: " + String(res.text))
	if back: panel.open(l, false)

func buy() -> String:
	var price := int(l.deal) if int(l.deal) > 0 else int(l.ask)
	if int(drive.save.cash) < price:
		return "YOU'RE $%d SHORT. THE SELLER LOOKS AT YOUR SHOES." % (price - int(drive.save.cash))
	drive.save.cash = int(drive.save.cash) - price
	l.deal = price
	l.sold = true
	(drive.save.garage as Array).append(Market.to_garage(l))
	drive.save.market.listings.erase(l)
	SaveGame.write(drive.save)
	var e := CarCatalog.entry(String(l.car))
	var msg := "SOLD. THE %d %s %s IS YOURS FOR $%d. IT'S IN THE GARAGE. GUS: \"WHAT IS THAT.\"" % [int(l.year), String(e.make).to_upper(), String(e.model).to_upper(), price]
	drive.hud.post(msg, 7.0)
	cancel()
	return msg

func _damage_sum() -> float:
	var d: Dictionary = drive.car.damage
	return float(d.front) + float(d.rear) + float(d.left) + float(d.right)

func _draw() -> void:
	if stage != "drive" or place.is_empty(): return
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	draw_arc(place.p * CarArt.PX, 18.0 * CarArt.PX, 0.0, TAU, 48, Color(0.4, 0.6, 1.0, 0.35 + 0.3 * pulse), 4.0)


## The meetup in the parking lot: the seller, the car, and a list of things to check before
## you hand over cash. Every check takes ten minutes and tells you what it finds.
class MeetPanel extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const GREEN := Color("6fbf5a")
	const RED := Color("e0402e")
	var runner: MarketRunner
	var l := {}
	var sel := 0
	var notes: Array = []
	var _photo: ImageTexture

	func open(listing: Dictionary, fresh := true) -> void:
		l = listing
		visible = true
		if fresh:
			notes = []
			sel = 0
			var s: Dictionary = Market.SELLERS[String(l.seller)]
			log_line("%s: \"%s\"" % [String(s.name), String(s.hi)])
		var spec := CarCatalog.spec(String(l.car))
		var img := PixCars.showroom(spec, 170, Color(String(l.paint)), { "year": int(l.year) })
		_photo = ImageTexture.create_from_image(img.get_region(img.get_used_rect().grow(2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))))

	func log_line(s: String) -> void:
		notes.append(s)

	func items() -> Array:
		var out: Array = []
		for c in Market.CHECK_ORDER:
			out.append(["check", c])
		out.append(["buy", ""])
		out.append(["leave", ""])
		return out

	func _process(_dt: float) -> void:
		if not visible: return
		queue_redraw()
		var its := items()
		if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % its.size()
		if Input.is_action_just_pressed("ui_up"): sel = (sel + its.size() - 1) % its.size()
		if Input.is_action_just_pressed("ui_cancel"):
			visible = false
			runner.cancel()
			return
		if not Input.is_action_just_pressed("ui_accept"): return
		var it: Array = its[sel]
		match String(it[0]):
			"check":
				var c := String(it[1])
				if c == "test_drive": runner.start_test()
				else: log_line("%s: %s" % [String(Market.CHECKS[c].label), runner.do_check(c)])
			"buy":
				var msg := runner.buy()
				if runner.active(): log_line(msg)
			"leave":
				visible = false
				runner.cancel()

	func _draw() -> void:
		if l.is_empty(): return
		var r := Rect2(70, 24, 500, 312)
		draw_rect(r, Color(0.04, 0.04, 0.06, 0.985))
		draw_rect(r, GOLD, false, 1.0)
		var e := CarCatalog.entry(String(l.car))
		PixelFont.draw(self, r.position + Vector2(10, 8), "MEETUP: %d %s %s" % [int(l.year), String(e.make).to_upper(), String(e.model).to_upper()], GOLD, 2)
		var price := int(l.deal) if int(l.deal) > 0 else int(l.ask)
		PixelFont.draw(self, r.position + Vector2(10, 26), "%s  -  %s  -  DASH SAYS %s KM" % [String(Market.SELLERS[String(l.seller)].name), "DEAL $%d" % price if int(l.deal) > 0 else "ASKING $%d" % price, Market._km(int(l.km_claimed))], ASH)
		if _photo: draw_texture(_photo, r.position + Vector2(r.size.x - _photo.get_width() - 6, 30))
		var its := items()
		var y := r.position.y + 44
		for i in its.size():
			var it: Array = its[i]
			var label := ""
			match String(it[0]):
				"check": label = String(Market.CHECKS[String(it[1])].label) + ("  (DONE)" if (l.checked as Array).has(String(it[1])) else "")
				"buy": label = "BUY IT: $%d CASH (YOU HAVE $%d)" % [price, int(runner.drive.save.get("cash", 0))]
				"leave": label = "WALK AWAY"
			var on := i == sel
			if on: draw_rect(Rect2(r.position.x + 6, y - 2, 250, 11), Color(1, 1, 1, 0.1))
			PixelFont.draw(self, Vector2(r.position.x + 10, y), label, GOLD if on else (GREEN if String(it[0]) == "buy" else BONE))
			y += 12
		# what you've found
		var ly := r.position.y + 170
		draw_rect(Rect2(r.position.x + 6, ly - 4, r.size.x - 12, r.end.y - ly - 14), Color(1, 1, 1, 0.04))
		var lines: Array = []
		for s in notes: lines.append_array(Hud.wrap_lines(String(s), 80))
		for ln in lines.slice(maxi(0, lines.size() - 12)):
			PixelFont.draw(self, Vector2(r.position.x + 10, ly), ln, BONE)
			ly += 9
		PixelFont.draw_centered(self, r.get_center().x, r.end.y - 10, Hints.fmt("{updown}: PICK  {ui_accept}: DO IT  {ui_cancel}: LEAVE"), ASH)
