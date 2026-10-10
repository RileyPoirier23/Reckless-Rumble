## The meet: Friday and Saturday nights in the back of the Champagne Place lot. Six locals and you
## in a row facing the mall. Park in your spot, rev it, pop the hood, and the crowd votes: how it
## looks, what's under the hood (if you show them), how clean it is, whether it fits the night's
## theme, and how loud you got. Then everybody leaves, some of them sideways.
class_name CarMeet
extends Node2D

const ROW_Y := 1318.0                       # the back row, noses to the mall
const SPOTS := [6650.0, 6655.0, 6660.0, 6665.0, 6670.0, 6675.0]
const YOUR_SPOT := Vector2(6681.5, 1318.0)
const LOT := Rect2(6606, 1250, 148, 86)
const SPOT_M := 2.0
const SHOW_S := 40.0
const LEAVE_S := 25.0
const ENTRY := 20
const PRIZES := [250, 100, 40]
const PEOPLES := 50

## The night's theme: which cars the crowd came for, and how it weighs looks against the build.
const THEMES := [
	{ "id": "anything", "name": "ANYTHING GOES", "lw": 1.0, "bw": 1.0, "say": "\"BRING WHATEVER. WE'VE SEEN A MINIVAN WIN.\"" },
	{ "id": "jdm", "name": "JDM NIGHT", "lw": 1.0, "bw": 1.0, "cls": ["jdm"], "say": "\"IMPORTS ONLY. IF IT'S NOT RIGHT-HAND DRIVE IT BETTER BE CLOSE.\"" },
	{ "id": "muscle", "name": "MUSCLE NIGHT", "lw": 1.0, "bw": 1.0, "cls": ["muscle", "pony"], "say": "\"V8S. BURNOUTS AFTER. NOT DURING. AFTER.\"" },
	{ "id": "stance", "name": "STANCE NIGHT", "lw": 1.5, "bw": 0.5, "stance": true, "say": "\"LOW AND WIDE. IF YOU CAN FIT A FIST UNDER IT, GO HOME.\"" },
	{ "id": "sleeper", "name": "SLEEPER NIGHT", "lw": -0.4, "bw": 1.8, "say": "\"THE SLOWER IT LOOKS, THE BETTER. POP THE HOOD AND SURPRISE US.\"" },
	{ "id": "euro", "name": "EURO NIGHT", "lw": 1.0, "bw": 1.0, "cls": ["euro", "luxury"], "say": "\"GERMAN, ITALIAN, SWEDISH. FRENCH, IF YOU'RE BRAVE.\"" },
	{ "id": "classic", "name": "CRUISE-IN: CLASSICS", "lw": 1.0, "bw": 0.8, "before": 1990, "say": "\"OLDER THAN THE MALL. THE MALL IS FROM 1986.\"" },
]

const NAMES := ["BRAYDEN", "TANNER", "MEGAN F.", "JULIEN", "DESTINY", "CODY (THE OTHER CODY)", "RAYMOND, 61", "THE TWINS",
	"STEPH", "KAYDEN WITH THE WING", "MARC-ANTOINE", "JESS AND HER DAD", "DYLAN FROM THE PARTS COUNTER", "OLD GERALD"]
## Cars the locals bring, when it isn't a themed night.
const LOCAL_CLASSES := ["jdm", "sports", "muscle", "pony", "euro", "hot_hatch", "classic", "rally", "coupe", "offroad", "oddball", "luxury"]

var drive: Node
var theme: Dictionary = {}
var entrants: Array = []         # the locals: { name, id, spec, paint, looks, build, clean, hype }
var cars: Array = []             # their AiCars, parked
var state := "arrive"            # arrive, show, results, leave, done (or turned_away, then done)
var t := 0.0
var hood := false
var rev_t := 0.0
var hype := 0.0
var backed_in := false
var you := {}                    # your score card once the votes are in
var results: Array = []          # everyone, best first
var place := 0
var paid := 0
var burnout := false
var hud: MeetHud
var _say_t := 0.0
var _said: Array = []

## The theme on a given night.
static func theme_for(day: int) -> Dictionary:
	return THEMES[posmod(day * 3 + 1, THEMES.size())]

# ------------------------------------------------------------------ the votes

## How a car looks, from its looks (as SaveGame.car_looks gives them, parts included). Stance
## night counts the drop and the wheels double.
static func looks_pts(l: Dictionary, stance := false) -> float:
	var p := 0.0
	p += float({ "gloss": 0.0, "metallic": 0.8, "pearl": 1.5, "matte": 1.5, "chrome": 2.5 }.get(String(l.get("finish", "gloss")), 0.0))
	var wheels := 0.0
	if String(l.get("rim", "")) != "": wheels += 2.0
	wheels += clampf((float(l.get("rim_size", 0.66)) - 0.66) * 15.0, 0.0, 2.0)
	var drop := float(l.get("drop", 0.0)) * 2.5
	p += (wheels + drop) * (2.0 if stance else 1.0)
	var cal: Variant = l.get("caliper", null)
	if cal != null and Color(cal) != Color("#5a5a60"): p += 0.5
	p += float(l.get("tint", 0.0)) * 0.8
	if String(l.get("stripes", "none")) != "none": p += 1.0
	if String(l.get("livery", "none")) != "none": p += 1.2
	var sp := String(l.get("spoiler", "none"))
	if sp != "none": p += float({ "ducktail": 0.8, "wing": 1.2, "gt": 1.8 }.get(sp, 1.0))
	var kit: Dictionary = l.get("kit", {})
	if kit.get("lip", false): p += 0.6
	if kit.get("skirts", false): p += 0.8
	if kit.get("diffuser", false): p += 0.8
	p += float({ "dual": 0.4, "quad": 0.8 }.get(String(l.get("exhaust", "single")), 0.0))
	return p

## What's under the hood: the stages of everything bolted on.
static func build_pts(parts: Dictionary) -> float:
	var p := 0.0
	for sl in parts: p += Parts.stage(String(parts[sl])) * 0.55
	return minf(p, 12.0)

## Dents cost you.
static func clean_pts(damage: Dictionary) -> float:
	var d := 0.0
	for k in damage: d += clampf(float(damage[k]), 0.0, 1.0)
	return -minf(d * 4.0, 8.0)

## What the car's worth (people like expensive things) and whether it's the night's kind of car.
static func value_pts(id: String) -> float:
	var price := float(CarCatalog.entry(id).get("price", 8000.0))
	return clampf(log(maxf(price, 1.0) / 5000.0) / log(2.0), 0.0, 4.0)

static func theme_pts(spec: Dictionary, th: Dictionary) -> float:
	var cls := String(CarCatalog.entry(String(spec.get("id", ""))).get("class", ""))
	if th.has("cls") and cls in (th.cls as Array): return 4.0
	if th.has("before") and int(spec.get("year", 2000)) < int(th.before): return 4.0
	return 0.0

## The whole card: { looks, build, clean, value, theme, hype, total }. `shown` is whether the
## hood went up (the crowd only half-believes what it can hear).
static func card(spec: Dictionary, looks: Dictionary, parts_b: float, damage: Dictionary, th: Dictionary, hype_pts: float, shown: bool) -> Dictionary:
	var l := looks_pts(looks, th.has("stance"))
	var b := parts_b * (1.0 if shown else 0.25)
	var c := clean_pts(damage)
	var v := value_pts(String(spec.get("id", "")))
	var m := theme_pts(spec, th)
	var total := l * float(th.lw) + b * float(th.bw) + c + v + m + hype_pts
	return { "looks": l * float(th.lw), "build": b * float(th.bw), "clean": c, "value": v, "theme": m, "hype": hype_pts, "total": total }

## Six locals: a car each (half of them the night's kind, on a themed night), some effort on the
## looks, some on the engine, and a bit of noise.
static func make_entrants(rng: RandomNumberGenerator, th: Dictionary, n: int, not_id := "") -> Array:
	var out: Array = []
	var names := NAMES.duplicate()
	for i in n:
		var pool: Array = []
		if th.has("cls") and rng.randf() < 0.6:
			for cls in th.cls: pool += CarCatalog.by_class(String(cls))
		elif th.has("before") and rng.randf() < 0.6:
			pool = CarCatalog.by_class("classic")
		else:
			pool = CarCatalog.by_class(String(LOCAL_CLASSES[rng.randi() % LOCAL_CLASSES.size()]))
		pool = pool.filter(func(x): return String(x) != not_id)
		if pool.is_empty(): pool = CarCatalog.by_class("sports")
		var id := String(pool[rng.randi() % pool.size()])
		var effort := 0.2 + rng.randf() * 0.8
		var l := {}
		if rng.randf() < effort: l.finish = ["metallic", "pearl", "matte", "chrome"][rng.randi() % 4]
		if rng.randf() < effort:
			l.rim = PixCars.RIMS[rng.randi() % PixCars.RIMS.size()]
			l.rim_size = 0.66 + rng.randf() * 0.12
		if rng.randf() < effort * 0.8: l.drop = snappedf(rng.randf() * effort, 0.2)
		if rng.randf() < effort * 0.5: l.tint = 0.5
		if rng.randf() < effort * 0.4: l.stripes = ["racing", "side", "rally"][rng.randi() % 3]
		if rng.randf() < effort * 0.5: l.spoiler = ["ducktail", "wing", "gt"][rng.randi() % 3]
		if rng.randf() < effort * 0.5:
			var kn: String = ["lip", "lip + skirts", "full"][rng.randi() % 3]
			l.kit_name = kn
			l.kit = { "lip": true, "skirts": kn != "lip", "diffuser": kn == "full" }
		if rng.randf() < effort * 0.6: l.exhaust = ["dual", "quad"][rng.randi() % 2]
		var name := String(names.pop_at(rng.randi() % names.size()))
		out.append({ "name": name, "id": id, "looks": l,
			"paint": "#%02x%02x%02x" % [rng.randi_range(25, 235), rng.randi_range(25, 235), rng.randi_range(25, 235)],
			"build": snappedf((0.3 + rng.randf()) * effort * 9.0, 0.1), "damage": { "front": 0.25 } if rng.randf() < 0.15 else {},
			"hype": snappedf(rng.randf() * 2.2 * effort, 0.1) })
	return out

# ------------------------------------------------------------------ the night

func setup(the_drive: Node, rng: RandomNumberGenerator, day: int) -> void:
	drive = the_drive
	z_index = 3050
	z_as_relative = false
	theme = theme_for(day)
	var mine := String(drive.car.spec.get("id", ""))
	entrants = make_entrants(rng, theme, SPOTS.size(), mine)
	for i in entrants.size():
		var e: Dictionary = entrants[i]
		var spec := CarCatalog.spec(String(e.id))
		spec.paint = String(e.paint)
		e.spec = spec
		var a := AiCar.new()
		drive.ysort.add_child(a)
		var at := Vector2(float(SPOTS[i]), ROW_Y)
		a.setup_ai(spec, drive.world, drive.skids, drive.hud, at, -PI / 2.0, 80 + i)
		a.set_path(PackedVector2Array([at, at + Vector2(0, -3)]), false)
		a.traffic = drive.traffic
		a.hold = true
		drive.traffic.extra.append(a)
		cars.append(a)
	hud = MeetHud.new()
	hud.meet = self
	hud.size = Vector2(640, 360)
	drive.get_node("HudLayer").add_child(hud)

## In your spot: stopped, close enough, straight in or backed in.
func parked() -> bool:
	var c: PlayerCar = drive.car
	if c == null or c.sim.speed() > 0.5 or c.sim.pos.distance_to(YOUR_SPOT) > SPOT_M: return false
	var d := absf(wrapf(c.sim.heading + PI / 2.0, -PI, PI))
	return d < 0.6 or d > PI - 0.6

func _process(dt: float) -> void:
	queue_redraw()
	var c: PlayerCar = drive.car
	if c == null: return
	match state:
		"arrive":
			if parked() and int(drive.save.get("cash", 0)) < ENTRY:
				# no money, no spot
				state = "turned_away"
				drive.hud.post("THE ORGANIZER HOLDS OUT A HAND. YOU'VE GOT $%d. \"IT'S $%d TO GET IN, KID. NO MONEY, NO SPOT.\"" % [maxi(0, int(drive.save.get("cash", 0))), ENTRY], 6.0)
			elif parked():
				state = "show"
				t = 0.0
				backed_in = absf(wrapf(c.sim.heading + PI / 2.0, -PI, PI)) > PI / 2.0
				c.show_mode = true
				drive.save.cash = int(drive.save.get("cash", 0)) - ENTRY
				drive.hud.post("THE ORGANIZER TAKES YOUR $%d. \"FOR THE TIRE FUND.\" %s" % [ENTRY, String(theme.say)], 6.0)
				if backed_in: drive.hud.post("BACKED IN. A GUY IN A HOODIE NODS. RESPECT.", 4.0)
		"show": _show(dt, c)
		"turned_away":
			if not LOT.grow(30.0).has_point(c.sim.pos): state = "done"
		"leave":
			t += dt
			var spin := absf(c.sim.w_wheel * float(c.sim.spec.tires.radius)) - c.sim.speed()
			if not burnout and spin > 8.0 and LOT.grow(10.0).has_point(c.sim.pos):
				burnout = true
				drive.hud.post("SMOKE EVERYWHERE. THE CROWD LOSES ITS MIND. MALL SECURITY PUTS DOWN HIS DONUT.", 5.0)
				var p: Police = drive.police
				if p.enabled and p.state == "calm" and randf() < 0.6:
					var at := Vector2(6600, 1345)
					p.pull_over(p.spawn_at(at, 0.0), "stunting")
			if t > LEAVE_S or not LOT.grow(30.0).has_point(c.sim.pos): state = "done"

func _show(dt: float, c: PlayerCar) -> void:
	t += dt
	var red := float(c.sim.spec.engine.redline_rpm)
	if c.sim.rpm > red * 0.8:
		rev_t += dt
		var loud := 1.0 + 0.25 * Parts.stage(String(_entry().get("parts", {}).get("exhaust", "")))
		if rev_t < 12.0: hype = minf(3.0, hype + dt * 0.35 * loud)
		else:
			hype = maxf(0.0, hype - dt * 0.3)
			if not _said.has("enough"):
				_said.append("enough")
				drive.hud.post("\"OKAY, WE GET IT. IT'S LOUD.\" A MOM COVERS HER KID'S EARS.", 4.0)
	if Input.is_action_just_pressed("use") and not hood:
		hood = true
		var b := build_pts(_entry().get("parts", {}))
		drive.hud.post("YOU POP THE HOOD. " + ("PHONES COME OUT. SOMEBODY ASKS WHAT IT MAKES." if b > 4.0 else ("A COUPLE OF NODS." if b > 1.0 else "\"IS THAT... STOCK?\" THEY SAY IT LIKE A DIAGNOSIS.")), 5.0)
	_say_t -= dt
	if _say_t <= 0.0 and drive.hud.chatter_ready():
		_say_t = 7.0
		var line := _comment()
		if line != "": drive.hud.chatter("", line)
	if t >= SHOW_S: _vote()

## Your garage entry ({} if you came in somebody else's car).
func _entry() -> Dictionary:
	var i: int = drive.car_i
	return drive.save.garage[i] if i >= 0 and i < (drive.save.garage as Array).size() else {}

## Somebody in the crowd says something about your car.
func _comment() -> String:
	var e := _entry()
	var l := SaveGame.car_looks(e) if not e.is_empty() else {}
	var dmg: Dictionary = e.get("damage", {})
	var opts: Array = []
	if float(dmg.get("front", 0.0)) > 0.3: opts.append(["dent", "\"WHAT HAPPENED TO THE FRONT?\" \"A MOOSE.\" \"FAIR.\""])
	if (l.get("kit", {}) as Dictionary).get("diffuser", false): opts.append(["kit", "\"FULL KIT. WHO'S YOUR BODY GUY?\" YOU SAY GUS. THEY SAY, \"GUS DOES BODY?\""])
	if String(l.get("finish", "")) == "chrome": opts.append(["chrome", "\"CHROME. YOU CAN SEE YOUR FACE IN IT. YOU CAN SEE YOUR REGRETS IN IT.\""])
	if float(l.get("drop", 0.0)) >= 0.6: opts.append(["drop", "\"HOW DO YOU GET OVER SPEED BUMPS?\" \"I DON'T.\""])
	if String(l.get("spoiler", "none")) in ["wing", "gt"]: opts.append(["wing", "\"DOES THE WING DO ANYTHING?\" \"IT DOES NOW.\""])
	if theme_pts(drive.car.spec, theme) > 0.0: opts.append(["theme", "\"FINALLY. SOMEBODY READ THE FLYER.\""])
	if rev_t > 3.0: opts.append(["revs", "A GUY FILMS YOUR REVS VERTICALLY. HE'LL POST IT WITH THE WRONG SONG."])
	opts.append(["gen1", "SOMEBODY PARKS A SCOOTER IN THE ROW. NOBODY SAYS ANYTHING. IT'S HIS ROW NOW."])
	opts.append(["gen2", "A KID ASKS IF HE CAN SIT IN IT. HIS DAD ASKS IF HE CAN SIT IN IT."])
	opts.append(["gen3", "SOMEONE'S PLAYING THE SAME SONG FROM FOUR DIFFERENT CARS. NONE OF THEM IN SYNC."])
	for o in opts:
		if not _said.has(o[0]):
			_said.append(o[0])
			return String(o[1])
	return ""

## The votes are in.
func _vote() -> void:
	var c: PlayerCar = drive.car
	var e := _entry()
	var looks := SaveGame.car_looks(e) if not e.is_empty() else {}
	var h := hype + (0.5 if backed_in else 0.0)
	you = card(c.spec, looks, build_pts(e.get("parts", {})), c.damage, theme, h, hood)
	you.name = "YOU"
	you.you = true
	you.car = _car_name(String(c.spec.get("id", "")))
	results = [you]
	for x in entrants:
		var k := card(x.spec, x.looks, float(x.build), x.damage, theme, float(x.hype), true)
		k.name = x.name
		k.car = _car_name(String(x.id))
		k.entrant = x
		results.append(k)
	results.sort_custom(func(a, b): return float(a.total) > float(b.total))
	place = 1
	var loudest: Dictionary = results[0]
	for i in results.size():
		var r: Dictionary = results[i]
		if r.has("you"): place = i + 1
		if float(r.hype) > float(loudest.hype): loudest = r
	paid = (int(PRIZES[place - 1]) if place <= PRIZES.size() else 0) + (PEOPLES if loudest.has("you") else 0)
	if paid > 0: drive.jobs.pay(paid)
	var m: Dictionary = drive.save.get("meets", {})
	m.count = int(m.get("count", 0)) + 1
	if place == 1: m.wins = int(m.get("wins", 0)) + 1
	m.best = mini(int(m.get("best", 99)), place)
	drive.save.meets = m
	if place == 1:
		var st: Dictionary = drive.save.get("street", {})
		st.rep = int(st.get("rep", 0)) + 1
		drive.save.street = st
	SaveGame.write(drive.save)
	c.show_mode = false
	state = "results"
	hud.show_results()

## Done looking at the results: everybody heads out.
func leave() -> void:
	if state != "results": return
	state = "leave"
	t = 0.0
	hud.panel_on = false
	for a in cars: a.hold = true
	drive.hud.post("SOMEBODY YELLS \"COPS!\" IT'S NOT COPS. IT'S NEVER COPS. EVERYBODY LEAVES ANYWAY.", 5.0)

static func _car_name(id: String) -> String:
	var e := CarCatalog.entry(id)
	return ("%s %s" % [String(e.get("make", "")), String(e.get("model", ""))]).to_upper().strip_edges()

func close() -> void:
	if drive.car: drive.car.show_mode = false
	for a in cars:
		drive.traffic.extra.erase(a)
		a.queue_free()
	cars.clear()
	if hud: hud.queue_free()

## Your spot, painted on the lot.
func _draw() -> void:
	if state != "arrive": return
	var px := CarArt.PX
	var r := Rect2((YOUR_SPOT - Vector2(1.4, 2.6)) * px, Vector2(2.8, 5.2) * px)
	var a := 0.5 + 0.3 * sin(Time.get_ticks_msec() / 250.0)
	draw_rect(r, Color(0.85, 0.64, 0.25, a), false, 3.0)
	# a painted arrow into the spot (no lettering over the lot)
	var c := r.get_center()
	draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -10), c + Vector2(8, -10), c + Vector2(0, 6)]), Color(0.95, 0.85, 0.5, a * 0.8))


## The meet's corner of the screen: the theme, the clock, the hype; then the results card.
class MeetHud extends Control:
	const BONE := Color("f3ead2")
	const GOLD := Color("d9a441")
	const ASH := Color("8a8478")
	const GREEN := Color("6fbf5a")
	const RED := Color("e0402e")
	var meet: CarMeet
	var panel_on := false
	var pics: Array = []         # side views of the podium

	func show_results() -> void:
		panel_on = true
		pics.clear()
		for i in mini(3, meet.results.size()):
			var r: Dictionary = meet.results[i]
			var spec: Dictionary
			var paint: Color
			var looks: Dictionary
			if r.has("you"):
				spec = meet.drive.car.spec
				paint = meet.drive.car.paint
				looks = SaveGame.car_looks(meet._entry()) if not meet._entry().is_empty() else {}
			else:
				spec = r.entrant.spec
				paint = Color(String(r.entrant.paint))
				looks = (r.entrant.looks as Dictionary).duplicate(true)
			looks.year = int(spec.get("year", 2000))
			pics.append(ImageTexture.create_from_image(PixCars.showroom(spec, 120, paint, looks)))

	func _process(_dt: float) -> void:
		queue_redraw()
		if panel_on and Input.is_action_just_pressed("ui_accept"): meet.leave()

	func _draw() -> void:
		if meet == null: return
		if meet.state == "turned_away":
			var r := Rect2(4, 38, 168, 30)
			draw_rect(r, Color(0, 0, 0, 0.6))
			PixelFont.draw(self, r.position + Vector2(6, 5), "THE MEET: TURNED AWAY", RED)
			PixelFont.draw(self, r.position + Vector2(6, 17), "$%d TO GET IN. YOU'VE GOT $%d." % [CarMeet.ENTRY, maxi(0, int(meet.drive.save.get("cash", 0)))], BONE)
			return
		if meet.state in ["arrive", "show"]:
			var r := Rect2(4, 38, 168, 52)
			draw_rect(r, Color(0, 0, 0, 0.6))
			PixelFont.draw(self, r.position + Vector2(6, 5), "THE MEET: " + String(meet.theme.name), GOLD)
			if meet.state == "arrive":
				PixelFont.draw(self, r.position + Vector2(6, 17), "PARK IN YOUR SPOT. $%d TO GET IN." % CarMeet.ENTRY, BONE)
				PixelFont.draw(self, r.position + Vector2(6, 27), "NOSE IN OR BACK IN.", ASH)
				return
			PixelFont.draw(self, r.position + Vector2(6, 17), "VOTES IN %d" % int(ceilf(CarMeet.SHOW_S - meet.t)), BONE)
			PixelFont.draw(self, r.position + Vector2(84, 17), "HOOD: %s" % ("UP" if meet.hood else "DOWN"), GREEN if meet.hood else ASH)
			PixelFont.draw(self, r.position + Vector2(6, 28), "HYPE", ASH)
			draw_rect(Rect2(r.position.x + 30, r.position.y + 28, 130, 5), Color(1, 1, 1, 0.1))
			draw_rect(Rect2(r.position.x + 30, r.position.y + 28, 130 * meet.hype / 3.0, 5), RED if meet.rev_t >= 12.0 else GOLD)
			PixelFont.draw(self, r.position + Vector2(6, 40), Hints.fmt("{throttle}: REV IT   {use}: POP THE HOOD"), ASH)
			return
		if not panel_on: return
		var p := Rect2(110, 24, 420, 312)
		draw_rect(p, Color(0.05, 0.05, 0.07, 1.0))
		draw_rect(p, GOLD, false, 1.0)
		PixelFont.draw_centered(self, p.get_center().x, p.position.y + 8, "THE VOTES: " + String(meet.theme.name), GOLD, 2)
		# the podium
		for i in pics.size():
			var x := p.position.x + 14 + i * 136
			var tex: Texture2D = pics[i]
			draw_texture(tex, Vector2(x, p.position.y + 70 - tex.get_height()))
			var r: Dictionary = meet.results[i]
			PixelFont.draw(self, Vector2(x, p.position.y + 74), "%d. %s" % [i + 1, String(r.name).substr(0, 22)], GOLD if r.has("you") else BONE)
		var y := p.position.y + 92
		for i in meet.results.size():
			var r: Dictionary = meet.results[i]
			var col := GOLD if r.has("you") else BONE
			PixelFont.draw(self, Vector2(p.position.x + 14, y), "%d" % (i + 1), col)
			PixelFont.draw(self, Vector2(p.position.x + 28, y), "%s - %s" % [String(r.name).substr(0, 26), String(r.car).substr(0, 34)], col)
			var s := "%.1f" % float(r.total)
			PixelFont.draw(self, Vector2(p.end.x - 14 - PixelFont.width(s), y), s, col)
			y += 11
		y += 6
		var u: Dictionary = meet.you
		PixelFont.draw(self, Vector2(p.position.x + 14, y), "YOURS:  LOOKS %.1f  BUILD %.1f%s  CLEAN %.1f" % [float(u.looks), float(u.build), "" if meet.hood else " (HOOD DOWN)", float(u.clean)], ASH)
		PixelFont.draw(self, Vector2(p.position.x + 14, y + 10), "        VALUE %.1f  THEME %.1f  HYPE %.1f" % [float(u.value), float(u.theme), float(u.hype)], ASH)
		var verdict := "BEST IN SHOW. $%d. MARCO HEARS ABOUT IT." % meet.paid if meet.place == 1 else ("%s. $%d." % [["", "", "SECOND", "THIRD"][meet.place], meet.paid] if meet.place <= 3 else ("%dTH. %s" % [meet.place, "PEOPLE'S CHOICE, THOUGH: $%d." % meet.paid if meet.paid > 0 else "THERE'S ALWAYS NEXT WEEK."]))
		PixelFont.draw_centered(self, p.get_center().x, p.end.y - 34, verdict, GREEN if meet.paid > 0 else BONE)
		PixelFont.draw_centered(self, p.get_center().x, p.end.y - 14, Hints.fmt("{ui_accept}: HEAD OUT"), ASH)
