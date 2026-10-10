## The impound auction: Saturdays, 10 to 2, at the Northside impound lot. Cars nobody came back
## for, sold as is, where is: no test drives, no looking under them, and some have no keys. Lyle
## calls it fast; Darrell's there, a dealer from Shediac, and a guy in a trucker hat who just nods.
class_name Auction
extends Node

const GATE := Vector2(6182, 934)          # the booth at the gate
const USE_M := 9.0
const OPEN_H := [10.0, 14.0]
const LOTS := 4
const CALL_S := 1.6                       # going once... going twice... sold: one call this often
const LOCKSMITH := 250
const BIDDERS := [
	{ "name": "DARRELL", "in": "\"I KNOW A GUY WHO'LL TAKE IT.\"", "out": "DARRELL SHAKES HIS HEAD. \"NOT AT THAT.\"", "eager": 1.0, "top": [0.5, 0.9] },
	{ "name": "THE DEALER FROM SHEDIAC", "in": "\"FOR PARTS. ALWAYS FOR PARTS.\"", "out": "THE DEALER FROM SHEDIAC LOOKS AT HIS PHONE.", "eager": 0.75, "top": [0.45, 0.8] },
	{ "name": "TRUCKER HAT", "in": "(HE NODS.)", "out": "TRUCKER HAT FOLDS HIS ARMS.", "eager": 0.55, "top": [0.3, 1.05] },
]
const WHY := ["SEIZED FROM A STREET RACER. HIS PARTS ARE STILL ON IT.", "NINETY DAYS IN THE IMPOUND. NOBODY CAME FOR IT.",
	"LEFT AT THE BIG STOP WITH THE KEYS IN IT. THE OWNER WASN'T.", "REPO. THE BANK WANTS IT GONE. THE BANK DOESN'T CARE FOR HOW MUCH.",
	"ESTATE. THE FAMILY JUST WANTS IT OUT OF THE DRIVEWAY.", "FOUND IN A FIELD IN HAVELOCK. RUNS. PROBABLY."]
const CLASSES := ["jdm", "sports", "muscle", "pony", "hot_hatch", "euro", "coupe", "sedan", "pickup", "rally", "classic", "luxury"]

var drive: Node
var panel: AuctionPanel
var lots: Array = []
var lot_i := 0
var bid := 0                     # the bid on the floor
var high := ""                   # who has it: "" (nobody yet), "YOU" or a bidder's name
var calls := 0                   # 0, then going once (1), twice (2), sold (3)
var call_t := 0.0
var tops: Array = []             # each bidder's limit on this lot
var wait_t: Array = []           # how long each bidder takes to put a hand up
var out_said: Array = []
var pause_t := 0.0               # between lots
var rng := RandomNumberGenerator.new()

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.seed = int(Time.get_ticks_usec())
	panel = AuctionPanel.new()
	panel.auction = self
	panel.size = Vector2(640, 360)
	panel.visible = false
	drive.get_node("HudLayer").add_child(panel)

static func is_day(day: int) -> bool:
	return Jobs.weekday(day) == "SATURDAY"

## This Saturday's lots: the car (as a MarketThing listing, faults and all, none of them known),
## why it's here, whether it has keys, what a street racer left bolted on, and the opening bid.
static func lots_for(day: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = day * 4241 + 7
	var out: Array = []
	for i in LOTS:
		var pool := CarCatalog.by_class(String(CLASSES[r.randi() % CLASSES.size()]))
		if pool.is_empty(): pool = CarCatalog.by_class("sedan")
		var id := String(pool[r.randi() % pool.size()])
		var l := Market.listing(id, r, 90000 + day * 10 + i, 1)
		l.why = r.randi() % WHY.size()
		l.keys = r.randf() > 0.25
		var parts := {}
		if int(l.why) == 0:
			var spec := CarCatalog.spec(id)
			var ids: Array = Parts.CATALOG.keys()
			ids.sort()
			for k in 12:
				var pid := String(ids[r.randi() % ids.size()])
				var sl := Parts.slot(pid)
				if parts.size() < 4 and not parts.has(sl) and Parts.fits(pid, spec) and Parts.stage(pid) >= 1: parts[sl] = pid
		l.parts = parts
		var extra := 0.0
		for sl in parts: extra += Parts.price(String(parts[sl])) * 0.5
		l.worth = int(float(l.value) + extra)
		l.open = maxi(100, int(round(float(l.worth) * 0.22 / 50.0)) * 50)
		out.append(l)
	return out

## The next bid up from this one.
static func step(b: int) -> int:
	if b < 1000: return 50
	if b < 5000: return 100
	return 250

## How high each bidder will go on a lot.
static func limits(l: Dictionary, r: RandomNumberGenerator) -> Array:
	var out: Array = []
	for b in BIDDERS:
		out.append(int(float(l.worth) * r.randf_range(float(b.top[0]), float(b.top[1]))))
	return out

## What the floor bid would be if you put your hand up now.
func your_price() -> int:
	return bid if high == "" else bid + step(bid)

func is_open() -> bool:
	var h: float = drive.sky.time_h
	return is_day(drive.sky.day) and h >= OPEN_H[0] and h < OPEN_H[1]

func at_gate() -> bool:
	var c: PlayerCar = drive.car
	return c != null and c.sim.speed() < 1.5 and c.sim.pos.distance_to(GATE) < USE_M

func open() -> bool:
	return panel.visible

## Lots already sold today (index -> who got it).
func done() -> Dictionary:
	var a: Dictionary = drive.save.get("auction", {})
	if int(a.get("day", -1)) != int(drive.sky.day):
		a = { "day": int(drive.sky.day), "done": {} }
		drive.save.auction = a
	return a.done

func _process(dt: float) -> void:
	if not panel.visible:
		if drive.car == null or StoryState.active or drive.garage.visible or not at_gate(): return
		if not is_open():
			drive.hud.post("NORTHSIDE IMPOUND. AUCTION SATURDAYS, 10 TO 2. AS IS, WHERE IS.", 0.2)
			return
		drive.hud.post(Hints.fmt("{use}: THE AUCTION"), 0.2)
		if Input.is_action_just_pressed("use"): start()
		return
	tick(dt)

## Walk up to the rail: the next lot that hasn't sold yet.
func start() -> void:
	lots = lots_for(int(drive.sky.day))
	lot_i = -1
	_next_lot()
	panel.open()

func _next_lot() -> void:
	var d := done()
	lot_i += 1
	while lot_i < lots.size() and d.has(str(lot_i)): lot_i += 1
	if lot_i >= lots.size():
		high = ""
		panel.say("LYLE: \"THAT'S THE LOT, FOLKS. SAME TIME NEXT SATURDAY.\"")
		return
	var l: Dictionary = lots[lot_i]
	bid = int(l.open)
	high = ""
	calls = 0
	call_t = CALL_S * 2.0
	tops = limits(l, rng)
	wait_t = []
	out_said = []
	for b in BIDDERS: wait_t.append(rng.randf_range(0.5, 1.6) / float(b.eager))
	panel.pic = null
	panel.say("LYLE: \"LOT %d. WHO'LL START ME AT $%d? $%d, ANYBODY?\"" % [lot_i + 1, bid, bid])

func live() -> bool:
	return lot_i >= 0 and lot_i < lots.size() and pause_t <= 0.0

## One frame of Lyle: the bidders put their hands up, the calls run down, and it sells.
func tick(dt: float) -> void:
	if pause_t > 0.0:
		pause_t -= dt
		if pause_t <= 0.0: _next_lot()
		return
	if not live(): return
	# the floor
	for i in BIDDERS.size():
		var b: Dictionary = BIDDERS[i]
		if high == String(b.name): continue
		var price := your_price()
		if int(tops[i]) >= price:
			wait_t[i] = float(wait_t[i]) - dt
			if float(wait_t[i]) <= 0.0:
				_bid(String(b.name), price)
				panel.say("%s: %s  $%d." % [String(b.name), String(b.in), price])
				break
		elif not out_said.has(i) and high != "":
			out_said.append(i)
			panel.say(String(b.out))
	call_t -= dt
	if call_t <= 0.0:
		calls += 1
		call_t = CALL_S
		if calls == 1: panel.say("LYLE: \"$%d. GOING ONCE...\"" % bid)
		elif calls == 2: panel.say("LYLE: \"GOING TWICE...\"")
		else: _sold()

func _bid(who: String, price: int) -> void:
	bid = price
	high = who
	calls = 0
	call_t = CALL_S * 1.5
	for i in BIDDERS.size(): wait_t[i] = rng.randf_range(0.6, 2.0) / float(BIDDERS[i].eager)

## Your hand goes up.
func you_bid() -> String:
	if not live() or high == "YOU": return ""
	var price := your_price()
	if int(drive.save.get("cash", 0)) < price: return "LYLE: \"YOU GOT $%d ON YOU, KID? NO? THEN PUT THE HAND DOWN.\"" % price
	_bid("YOU", price)
	return "YOU: $%d." % price

func _sold() -> void:
	var l: Dictionary = lots[lot_i]
	var d := done()
	if high == "":
		d[str(lot_i)] = "NO SALE"
		panel.say("LYLE: \"NO SALE. IT GOES TO LLOYD'S FOR SCRAP.\"")
	elif high == "YOU":
		d[str(lot_i)] = "YOU"
		panel.say(_win(l))
	else:
		d[str(lot_i)] = high
		panel.say("LYLE: \"SOLD, $%d, TO %s.\"" % [bid, high])
	pause_t = 3.0
	SaveGame.write(drive.save)

## You won it: pay, and Toby tows it to Covington's.
func _win(l: Dictionary) -> String:
	var cost := bid + (0 if bool(l.keys) else LOCKSMITH)
	drive.save.cash = int(drive.save.get("cash", 0)) - cost
	l.deal = bid
	var entry := Market.to_garage(l)
	entry.parts = (l.parts as Dictionary).duplicate()
	(drive.save.garage as Array).append(entry)
	var e := CarCatalog.entry(String(l.car))
	var name := "%d %s %s" % [int(l.year), String(e.get("make", "")).to_upper(), String(e.get("model", "")).to_upper()]
	var msg := "LYLE: \"SOLD, $%d, TO THE KID.\" THE %s IS YOURS. TOBY TOWS IT TO COVINGTON'S." % [bid, name]
	if not bool(l.keys): msg += " NO KEYS: THE LOCKSMITH IS $%d." % LOCKSMITH
	drive.hud.post(msg, 7.0)
	return msg

## Walk away. A lot that's live goes to whoever wanted it most.
func leave() -> void:
	if live():
		var best := -1
		for i in BIDDERS.size():
			if int(tops[i]) >= your_price() and (best < 0 or int(tops[i]) > int(tops[best])): best = i
		if high == "YOU": high = ""
		if best >= 0:
			high = String(BIDDERS[best].name)
			bid = maxi(your_price(), bid)
		_sold()
	pause_t = 0.0
	panel.visible = false


## The rail at the auction: the car on the block, the bid, and Lyle.
class AuctionPanel extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const GREEN := Color("6fbf5a")
	const RED := Color("e0402e")
	var auction: Auction
	var lines: Array = []
	var pic: Texture2D

	func open() -> void:
		visible = true

	func say(s: String) -> void:
		lines.append(s)
		if lines.size() > 4: lines = lines.slice(lines.size() - 4)

	func _process(_dt: float) -> void:
		if not visible: return
		queue_redraw()
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("use"):
			auction.leave()
			return
		if Input.is_action_just_pressed("ui_accept"):
			var s := auction.you_bid()
			if s != "": say(s)

	func _draw() -> void:
		if auction == null: return
		var r := Rect2(70, 16, 500, 328)
		draw_rect(r, Color(0.05, 0.05, 0.06, 1.0))
		draw_rect(r, GOLD, false, 1.0)
		PixelFont.draw(self, r.position + Vector2(12, 8), "IMPOUND AUCTION", GOLD, 2)
		PixelFont.draw(self, Vector2(r.end.x - 12 - PixelFont.width("CASH $%d" % int(auction.drive.save.get("cash", 0))), r.position.y + 12), "CASH $%d" % int(auction.drive.save.get("cash", 0)), BONE)
		if auction.lot_i >= 0 and auction.lot_i < auction.lots.size():
			var l: Dictionary = auction.lots[auction.lot_i]
			var e := CarCatalog.entry(String(l.car))
			var spec := CarCatalog.spec(String(l.car))
			if pic == null:
				pic = ImageTexture.create_from_image(PixCars.showroom(spec, 150, Color(String(l.paint)), { "year": int(l.year) }))
			draw_texture(pic, Vector2(r.position.x + 12, r.position.y + 102 - pic.get_height()))
			var x := r.position.x + 200
			PixelFont.draw(self, Vector2(x, r.position.y + 34), "LOT %d OF %d" % [auction.lot_i + 1, auction.lots.size()], ASH)
			PixelFont.draw(self, Vector2(x, r.position.y + 46), "%d %s %s" % [int(l.year), String(e.get("make", "")).to_upper(), String(e.get("model", "")).to_upper()], BONE)
			PixelFont.draw(self, Vector2(x, r.position.y + 56), "%s KM ON THE CLOCK" % Market._km(int(l.km_claimed)), ASH)
			PixelFont.draw(self, Vector2(x, r.position.y + 66), "KEYS: YES" if bool(l.keys) else "KEYS: NO (LOCKSMITH $%d)" % Auction.LOCKSMITH, GREEN if bool(l.keys) else RED)
			var y := r.position.y + 78
			for ln in Hud.wrap_lines(String(Auction.WHY[int(l.why)]), 64):
				PixelFont.draw(self, Vector2(x, y), ln, ASH)
				y += 9
			var parts: Dictionary = l.parts
			if not parts.is_empty():
				var names: Array = []
				for sl in parts: names.append(Parts.name_of(String(parts[sl])))
				for ln in Hud.wrap_lines("BOLTED ON: " + ", ".join(names), 64):
					PixelFont.draw(self, Vector2(x, y), ln, GOLD)
					y += 9
			PixelFont.draw(self, Vector2(r.position.x + 12, r.position.y + 108), "AS IS. WHERE IS. NO TEST DRIVES. NO LOOKING UNDER IT.", ASH)
			# the floor
			var by := r.position.y + 132
			PixelFont.draw(self, Vector2(r.position.x + 12, by), "$%d" % auction.bid, GOLD if auction.high == "YOU" else BONE, 3)
			var who := "NO BIDS YET" if auction.high == "" else ("YOUR BID" if auction.high == "YOU" else auction.high)
			PixelFont.draw(self, Vector2(r.position.x + 12, by + 22), who, GREEN if auction.high == "YOU" else ASH)
			var call: String = ["", "GOING ONCE", "GOING TWICE", "SOLD"][mini(auction.calls, 3)]
			PixelFont.draw(self, Vector2(r.end.x - 12 - PixelFont.width(call, 2), by + 4), call, RED, 2)
		var ly := r.position.y + 178
		for ln0 in auction.panel.lines:
			for ln in Hud.wrap_lines(String(ln0), 110):
				PixelFont.draw(self, Vector2(r.position.x + 12, ly), ln, BONE)
				ly += 10
		var hint := ("{ui_accept}: BID $%d  " % auction.your_price() if auction.live() and auction.high != "YOU" else "") + "{ui_cancel}: WALK AWAY"
		PixelFont.draw_centered(self, r.get_center().x, r.end.y - 12, Hints.fmt(hint), ASH)
