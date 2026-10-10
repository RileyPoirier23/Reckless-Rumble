## Runs the evening job you took off the board, inside the drive scene: Pizza Delirium runs,
## tow calls in Toby's wrecker, the drive out to Drag Night (DragStrip takes over at the line),
## and the Night Drive. Draws the markers on the ground and keeps the objective line up to date.
class_name JobRunner
extends Node2D

signal ended(kind: String)

var drive: Node
var kind := ""                 # "" when idle
var stage := ""
var rng := RandomNumberGenerator.new()
var t := 0.0
var earned := 0
var _prompt_t := 0.0

# pizza
var shop := {}
var stops: Array = []          # { p, house, label }
var stop_i := 0
var limit := 0.0
var clock := 0.0
var condition := 1.0
var _dmg_seen := 0.0
var runs := 0

# tow
var target: TowTarget
var tow_dest := {}
var _boom := 0.0
var _odo0 := 0.0
var _mass_add := 0.0

# night drive
var _cruise_m := 0.0

# drag
var strip: DragStrip
# street race
var race: StreetRace
var race_route := {}
var race_start := Vector2.ZERO
var race_rival := {}
# the meet
var meet: CarMeet
# rides
var rider := {}
var _ride_wait := 0.0
var _talk_t := 0.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	z_index = 3050
	z_as_relative = false
	rng.seed = int(Time.get_ticks_usec())

func active() -> bool:
	return kind != ""

func map() -> MapData:
	return drive.world.map

func car() -> PlayerCar:
	return drive.car

# ------------------------------------------------------------------ starting and stopping

func start(k: String) -> void:
	if active(): finish(false)
	kind = k
	t = 0.0
	earned = 0
	match k:
		"pizza":
			shop = Jobs.pizza_shop(map())
			stage = "pickup"
			runs = 0
			drive._on_dest("PIZZA DELIRIUM", shop.p)
			drive.hud.post("PIZZA DELIRIUM: \"YOU'RE LATE. YOU'RE NOT EVEN HERE YET AND YOU'RE LATE.\"", 5.0)
		"tow":
			if String(car().spec.get("id", "")) != "tow":
				drive.job_swap_car("tow")
				drive.hud.post("TOBY SWAPS YOU INTO THE WRECKER. \"DON'T TOUCH THE RADIO PRESETS.\"", 5.0)
			_new_tow()
		"drag":
			stage = "drive"
			drive._on_dest("AIRSTRIP 7", DragStrip.START + Vector2(-20, 0))
			drive.hud.post("DRAG NIGHT. PULL ONTO RUNWAY 7 AND STOP AT THE LINE.", 5.0)
		"street":
			stage = "drive"
			var st: Dictionary = drive.save.get("street", {})
			var rep := int(st.get("rep", 0))
			var rung := int(st.get("pinks", 0))
			race_rival = {}
			if Jobs.pinks_tonight(drive.sky.day, rep) and rung < StreetRace.RIVALS.size():
				race_rival = StreetRace.make_rival(rung)
				race_route = StreetRace.ROUTES[0]
				var e := CarCatalog.entry(String(race_rival.car))
				drive.hud.post("PINK SLIPS TONIGHT: %s IN THE %s %s. WIN AND IT'S YOURS. LOSE AND YOURS IS THEIRS." % [String(race_rival.name), String(e.get("make", "")).to_upper(), String(e.get("model", "")).to_upper()], 7.0)
			else:
				race_route = Jobs.street_route(drive.sky.day, rep)
				var tonight := Jobs.street_route(drive.sky.day)
				if tonight.id != race_route.id:
					drive.hud.post("MARCO: \"%s IS FOR PEOPLE WITH A NAME. YOU GET %s.\"" % [String(tonight.name), String(race_route.name)], 6.0)
				drive.hud.post("STREET RACE: %s. MEET MARCO AT THE START. $%d BUY-IN." % [race_route.name, int(race_route.buy_in)], 5.0)
			race_start = StreetRace.build_path(map(), race_route)[0]
			drive._on_dest("MARCO", race_start)
		"ride":
			if Rides.deactivated(drive.save, drive.sky.day):
				drive.hud.post("HOPP-IN: YOUR ACCOUNT IS ON A COOLING-OFF PERIOD. TRY AGAIN TOMORROW.", 5.0)
				kind = ""
				return
			stage = "wait"
			runs = 0
			_ride_wait = 3.0
			drive.clear_route()
			drive.hud.post("HOPP-IN: YOU'RE ONLINE. RATING %.1f. WAITING FOR A REQUEST." % Rides.average(drive.save), 4.0)
		"meet":
			stage = "drive"
			drive._on_dest("THE MEET", CarMeet.YOUR_SPOT)
			drive.hud.post("THE MEET: %s. BACK ROW OF THE CHAMPAGNE PLACE LOT." % String(CarMeet.theme_for(_meet_day()).name), 5.0)
		"cruise":
			stage = "cruise"
			_cruise_m = 0.0
			drive.clear_route()
			drive.hud.post("NIGHT DRIVE. NO JOBS. NO NOISE. JUST THE ROAD.", 5.0)
	_objective()

## End the job: paid out (done) or walked away from. Puts back whatever the job borrowed.
func finish(done := true) -> void:
	if kind == "": return
	var k := kind
	if target:
		target.queue_free()
		target = null
	if _mass_add > 0.0:
		car().sim.spec.mass = float(car().sim.spec.mass) - _mass_add
		_mass_add = 0.0
	if meet:
		meet.close()
		meet.queue_free()
		meet = null
	if strip:
		strip.close()
		strip.queue_free()
		strip = null
	if race:
		race.close()
		race.queue_free()
		race = null
		if not done: drive.hud.post("YOU PULL OUT OF THE RACE. MARCO KEEPS YOUR BUY-IN. OF COURSE HE DOES.", 4.0)
	match k:
		"pizza": drive.hud.post("SHIFT OVER. %d RUNS, $%d IN YOUR POCKET. YOU SMELL LIKE OREGANO." % [runs, earned], 6.0)
		"tow": if not done: drive.hud.post("YOU LEAVE IT IN THE DITCH. SOMEBODY ELSE'S PROBLEM NOW.", 4.0)
		"ride": drive.hud.post("HOPP-IN: OFFLINE. %d RIDE%s, $%d. RATING %.1f." % [runs, "" if runs == 1 else "S", earned, Rides.average(drive.save)], 6.0)
		"street": if done: drive.hud.post("RACE NIGHT: %s." % ("$%d UP" % earned if earned > 0 else "$%d DOWN" % -earned), 5.0)
		"meet": if not done: drive.hud.post("YOU SKIP THE MEET. SOMEBODY ELSE GETS YOUR SPOT. IT'S A MINIVAN.", 4.0)
		"cruise": drive.hud.post("NIGHT DRIVE: %.1f KM. THE KNOT IN YOUR SHOULDERS IS GONE." % (_cruise_m / 1000.0), 6.0)
	if k == "tow" and String(car().spec.get("id", "")) == "tow": drive.job_restore_car()
	kind = ""
	stage = ""
	drive.hud.objective = ""
	drive.clear_route()
	SaveGame.write(drive.save)
	ended.emit(k)

func pay(n: int) -> void:
	earned += n
	drive.save.cash = int(drive.save.get("cash", 0)) + n
	SaveGame.write(drive.save)

# ------------------------------------------------------------------ the frame

func _process(dt: float) -> void:
	queue_redraw()
	if not active() or car() == null or car().dead: return
	t += dt
	match kind:
		"pizza": _pizza(dt)
		"tow": _tow(dt)
		"drag": _drag(dt)
		"street": _street(dt)
		"ride": _ride(dt)
		"meet": _meet(dt)
		"cruise":
			_cruise_m += car().sim.speed() * dt
	_objective()

func _objective() -> void:
	var o := ""
	match kind:
		"pizza":
			if stage == "pickup": o = "PIZZA DELIRIUM: PICK UP THE ORDER. STOP OUT FRONT."
			elif stage == "deliver":
				var left := limit - clock
				o = "DELIVER TO %s (%d OF %d)   %s   PIZZA %d%%" % [stops[stop_i].label, stop_i + 1, stops.size(),
					("%d:%02d" % [int(maxf(left, 0.0)) / 60, int(maxf(left, 0.0)) % 60]) if left >= 0.0 else "LATE %ds" % int(-left), int(condition * 100.0)]
		"tow":
			if stage == "find": o = "TOW CALL: A %s ON THE SHOULDER OF %s. HAZARDS ON." % [target.label, tow_dest.get("road", "THE ROAD")]
			elif stage == "hook": o = "BACK UP TO IT. STOP. HOLD %s TO WORK THE BOOM." % Hints.key("use")
			elif stage == "deliver": o = "TOW IT TO %s. EASY ON THE BRAKES: IT WEIGHS %d KG." % [tow_dest.name, int(target.mass)]
		"drag":
			if stage == "drive": o = "DRAG NIGHT: AIRSTRIP 7. STOP AT THE START LINE ON RUNWAY 7."
		"street":
			if race == null: o = "STREET RACE: %s. %s STOP AT THE START AND SIGN IN WITH MARCO." % [race_route.name, race_route.blurb]
		"ride":
			if stage == "pickup": o = "HOPP-IN: PICK UP %s AT %s. STOP OUT FRONT." % [rider.name, rider.from_label]
			elif stage == "ride":
				o = "HOPP-IN: TAKE %s TO %s. $%d." % [rider.name, rider.to_label, int(rider.fare)]
				if Rides.TYPES[rider.kind].has("wants_speed"):
					var left := Rides.expected_s(float(rider.route_m)) - float(rider.t)
					o += "  %s" % ("%d:%02d" % [int(left) / 60, int(left) % 60] if left >= 0.0 else "LATE %ds" % int(-left))
		"meet":
			if meet == null or meet.state == "arrive": o = "THE MEET: PARK IN YOUR SPOT AT THE BACK OF THE CHAMPAGNE PLACE LOT."
			elif meet.state == "show": o = "THE MEET: REV IT, POP THE HOOD. THE VOTES ARE IN SOON."
		"cruise": o = ""
	drive.hud.objective = o

# ------------------------------------------------------------------ the meet

## The meet's night (after midnight it's still the night before).
func _meet_day() -> int:
	return int(drive.sky.day) - (1 if float(drive.sky.time_h) < 6.0 else 0)

func _meet(_dt: float) -> void:
	if meet == null:
		# the locals are parked by the time you get there
		if car().sim.pos.distance_to(CarMeet.YOUR_SPOT) < 220.0:
			meet = CarMeet.new()
			add_child(meet)
			meet.setup(drive, rng, _meet_day())
			stage = "meet"
		return
	if meet.state == "show" and stage != "show":
		stage = "show"
		drive.clear_route()
	if meet.state == "done": finish(true)

# ------------------------------------------------------------------ pizza

func _pizza(dt: float) -> void:
	var c := car()
	if stage == "pickup":
		if c.sim.pos.distance_to(shop.p) < 16.0 and c.sim.speed() < 2.0:
			var n := 1 + rng.randi() % 3
			stops = Jobs.addresses(map(), rng, shop.p, n)
			if stops.is_empty():
				drive.hud.post("NO ORDERS. THE OVEN'S BROKEN AGAIN. COME BACK LATER.", 4.0)
				finish(false)
				return
			stop_i = 0
			condition = 1.0
			_dmg_seen = _damage_sum()
			stage = "deliver"
			drive.hud.post("%d PIZZA%s IN THE BAG. HOT. GO." % [stops.size(), "" if stops.size() == 1 else "S"], 4.0)
			_next_stop()
		return
	if stage != "deliver": return
	clock += dt
	# hard cornering slides the toppings off; a hit squashes the box
	var g := absf(c.sim.ay) / 9.81
	if g > 0.7: condition = maxf(0.0, condition - (g - 0.7) * 0.7 * dt)
	var dmg := _damage_sum()
	if dmg > _dmg_seen + 0.01:
		condition = maxf(0.0, condition - (dmg - _dmg_seen) * 2.0)
		drive.hud.post("SOMETHING IN THE BACK WENT SPLAT.", 2.5)
	_dmg_seen = dmg
	var s: Dictionary = stops[stop_i]
	if c.sim.pos.distance_to(s.p) < 14.0 and c.sim.speed() < 2.0:
		var payd := Jobs.pizza_pay(clock - limit, limit * 0.33, condition)
		pay(int(payd.total))
		runs += 1
		drive.hud.post("%s  +$%d (TIP $%d)" % [_customer(int(payd.tip)), int(payd.total), int(payd.tip)], 5.0)
		stop_i += 1
		if stop_i >= stops.size():
			if Jobs.open_now("pizza", drive.sky.time_h):
				stage = "pickup"
				drive._on_dest("PIZZA DELIRIUM", shop.p)
				drive.hud.post("BACK TO THE SHOP. MORE ORDERS ARE UP.", 3.0)
			else:
				finish(true)
		else:
			_next_stop()

func _next_stop() -> void:
	var s: Dictionary = stops[stop_i]
	limit = Jobs.pizza_limit(_route_len(car().sim.pos, s.p))
	clock = 0.0
	drive._on_dest(String(s.label), s.p)

func _customer(tip: int) -> String:
	if tip >= 9: return ["\"THAT WAS FAST. ARE YOU OKAY?\"", "\"KEEP THE CHANGE. AND THE OTHER CHANGE.\"", "\"STILL BUBBLING. YOU'RE A HERO.\""][rng.randi() % 3]
	if tip >= 5: return ["\"YEAH, THAT'S PIZZA.\"", "\"LITTLE COLD. IT'S FINE.\"", "\"YOU'RE THE GUY FROM THE GARAGE, EH?\""][rng.randi() % 3]
	return ["\"THE CHEESE IS ON THE LID.\"", "\"THIRTY MINUTES. IT SAYS THIRTY MINUTES.\"", "\"DID YOU DRIVE THIS THROUGH A CAR WASH?\""][rng.randi() % 3]

func _damage_sum() -> float:
	var d: Dictionary = car().damage
	return float(d.front) + float(d.rear) + float(d.left) + float(d.right)

func _route_len(a: Vector2, b: Vector2) -> float:
	var r: PackedVector2Array = map().route(a, b)
	var n := 0.0
	for i in range(1, r.size()): n += r[i - 1].distance_to(r[i])
	return maxf(n, a.distance_to(b))

# ------------------------------------------------------------------ tow calls

func _new_tow() -> void:
	var spot := Jobs.tow_spot(map(), rng, car().sim.pos)
	if spot.is_empty():
		drive.hud.post("NO CALLS. EVERYBODY'S DRIVING CAREFULLY FOR ONCE.", 4.0)
		finish(false)
		return
	var style := String(map().zone_at(spot.p).get("style", "rural"))
	var spec := CarCatalog.random_traffic(rng, style)
	target = TowTarget.new()
	drive.ysort.add_child(target)
	target.setup(spec, spot.p, float(spot.heading) + (PI if rng.randf() < 0.5 else 0.0), rng)
	if rng.randf() < 0.6:
		tow_dest = { "name": "COVINGTON AUTO", "p": Jobs.road_point(map(), Jobs.COVINGTON), "road": String(spot.road) }
	else:
		tow_dest = { "name": "THE NORTHSIDE IMPOUND", "p": Jobs.road_point(map(), Jobs.IMPOUND), "road": String(spot.road) }
	drive.world.warm(spot.p, Vector2(20, 12))
	stage = "find"
	drive._on_dest("TOW CALL", spot.road_p)
	drive.hud.post("DISPATCH: \"%s, %s. OWNER SAYS IT 'JUST STOPPED'.\"" % [target.label, String(spot.road)], 5.0)

func _tow(dt: float) -> void:
	var c := car()
	if target == null: return
	if stage == "find":
		if c.sim.pos.distance_to(target.pos) < 25.0: stage = "hook"
		return
	if stage == "hook":
		# the boom is at the back of the wrecker: line it up with either end of the car
		var hitch := c.sim.pos - c.sim.forward() * (float(c.spec.length) * 0.5 + 0.6)
		var near := minf(hitch.distance_to(target.end(1.0)), hitch.distance_to(target.end(-1.0)))
		if near < 4.0 and c.sim.speed() < 1.0:
			if Input.is_action_pressed("use"):
				_boom += dt
				drive.hud.post("WORKING THE BOOM... %d%%" % int(minf(_boom / 1.5, 1.0) * 100.0), 0.2)
				if _boom >= 1.5:
					target.hook(near == hitch.distance_to(target.end(1.0)))
					_mass_add = target.mass * 0.6
					c.sim.spec.mass = float(c.sim.spec.mass) + _mass_add
					_odo0 = c.sim.odometer_m
					stage = "deliver"
					drive._on_dest(String(tow_dest.name), tow_dest.p)
					drive.hud.post("HOOKED. CHAINS ON. IT'S RIDING ON YOUR BACK NOW.", 4.0)
			else:
				_boom = 0.0
				drive.hud.post(Hints.fmt("HOLD {use}: WORK THE BOOM"), 0.2)
		elif c.sim.pos.distance_to(target.pos) > 60.0:
			stage = "find"
		return
	if stage == "deliver":
		var hitch2 := c.sim.pos - c.sim.forward() * (float(c.spec.length) * 0.5 + 0.6)
		target.follow(hitch2)
		if c.sim.pos.distance_to(tow_dest.p) < 18.0 and c.sim.speed() < 1.5:
			var km := (c.sim.odometer_m - _odo0) / 1000.0
			var n := Jobs.tow_pay(km, Jobs.is_night(drive.sky.time_h), Jobs.bad_weather(drive.sky.weather))
			pay(n)
			drive.hud.post("DROPPED AT %s. %.1f KM TOWED. +$%d" % [tow_dest.name, km, n], 6.0)
			finish(true)

# ------------------------------------------------------------------ drag night

func _drag(_dt: float) -> void:
	if strip: return
	var c := car()
	if DragStrip.RUNWAY.has_point(c.sim.pos) and c.sim.speed() < 2.0:
		drive.hud.post(Hints.fmt("{use}: PULL UP TO THE LINE"), 0.2)
		if Input.is_action_just_pressed("use"): open_strip()

func open_strip() -> void:
	strip = DragStrip.new()
	drive.get_node("HudLayer").add_child(strip)
	strip.setup(drive)
	strip.closed.connect(_on_strip_closed)
	drive.hud.objective = ""

func _on_strip_closed(won: int) -> void:
	earned += won
	if strip:
		strip.queue_free()
		strip = null
	finish(true)

# ------------------------------------------------------------------ rides

func _new_rider() -> void:
	var c := car()
	var from_list := Jobs.addresses(map(), rng, c.sim.pos, 1, 150.0, 900.0)
	if from_list.is_empty():
		_ride_wait = 8.0
		return
	var from: Dictionary = from_list[0]
	var to := {}
	if rng.randf() < 0.5:
		var picks: Array = []
		for l in map().landmarks:
			if bool(l.dest) and (l.p as Vector2).distance_to(from.p) > 400.0 and (l.p as Vector2).distance_to(from.p) < 2600.0: picks.append(l)
		if not picks.is_empty():
			var l: Dictionary = picks[rng.randi() % picks.size()]
			to = { "p": Jobs.road_point(map(), l.p), "label": String(l.name) }
	if to.is_empty():
		var tl := Jobs.addresses(map(), rng, from.p, 1, 400.0, 1800.0)
		if tl.is_empty():
			_ride_wait = 8.0
			return
		to = { "p": tl[0].p, "label": String(tl[0].label) }
	var k := Rides.pick_type(drive.sky.time_h, rng)
	var t: Dictionary = Rides.TYPES[k]
	var route_m := _route_len(from.p, to.p)
	rider = { "kind": k, "name": String((t.names as Array)[rng.randi() % (t.names as Array).size()]), "from": from.p, "from_label": String(from.label),
		"to": to.p, "to_label": String(to.label), "route_m": route_m, "fare": Rides.fare(route_m),
		"t": 0.0, "rough": 0.0, "over": 0.0, "hits": 0, "sick": false }
	stage = "pickup"
	drive._on_dest(String(from.label), from.p)
	drive.hud.post("HOPP-IN: %s AT %s. $%d TO %s." % [rider.name, rider.from_label, int(rider.fare), rider.to_label], 5.0)

func _ride(dt: float) -> void:
	var c := car()
	match stage:
		"wait":
			_ride_wait -= dt
			if _ride_wait <= 0.0: _new_rider()
		"pickup":
			if c.sim.pos.distance_to(rider.from) < 14.0 and c.sim.speed() < 2.0:
				stage = "ride"
				_dmg_seen = _damage_sum()
				_talk_t = rng.randf_range(15.0, 25.0)
				var t: Dictionary = Rides.TYPES[rider.kind]
				drive.hud.post("%s GETS IN. %s" % [rider.name, String((t.hi as Array)[rng.randi() % (t.hi as Array).size()])], 6.0)
				drive._on_dest(String(rider.to_label), rider.to)
		"ride":
			var t: Dictionary = Rides.TYPES[rider.kind]
			rider.t = float(rider.t) + dt
			# how hard you're throwing them about, past what they'll put up with
			var g := Vector2(c.sim.ax, c.sim.ay).length() / 9.81
			rider.rough = float(rider.rough) + maxf(0.0, g - float(t.tol)) * dt
			var road: Dictionary = map().road_at(c.sim.pos).get("road", {})
			if not road.is_empty():
				rider.over = float(rider.over) + maxf(0.0, c.sim.speed() * 3.6 - Police.limit_kmh(String(road.cls)) - 10.0) * dt
			var dmg := _damage_sum()
			if dmg > _dmg_seen + 0.02:
				rider.hits = int(rider.hits) + 1
				drive.hud.post("\"HEY!\"", 2.0)
			_dmg_seen = dmg
			if t.has("sick") and not bool(rider.sick) and float(rider.rough) > 1.2:
				rider.sick = true
				drive.hud.post("OH NO. OH NO NO NO. (THE BACK SEAT.)", 4.0)
			_talk_t -= dt
			if _talk_t <= 0.0:
				_talk_t = rng.randf_range(18.0, 30.0)
				drive.hud.post(String((t.talk as Array)[rng.randi() % (t.talk as Array).size()]), 5.0)
			if c.sim.pos.distance_to(rider.to) < 14.0 and c.sim.speed() < 2.0: _drop_off()

func _drop_off() -> void:
	var late := float(rider.t) - Rides.expected_s(float(rider.route_m))
	var star := Rides.stars(String(rider.kind), float(rider.rough), float(rider.over), int(rider.hits), late, bool(rider.sick))
	var fare_d := int(rider.fare)
	var tip_d := Rides.tip(fare_d, star)
	pay(fare_d + tip_d)
	if bool(rider.sick):
		pay(-Rides.CLEANING)
	runs += 1
	var off := Rides.record(drive.save, star, drive.sky.day)
	var stars_txt := ""
	for i in 5: stars_txt += "*" if i < star else "-"
	drive.hud.post("%s: %s  $%d%s%s" % [rider.name, stars_txt, fare_d, " + $%d TIP" % tip_d if tip_d > 0 else "", "  - $%d CLEANING" % Rides.CLEANING if bool(rider.sick) else ""], 6.0)
	SaveGame.write(drive.save)
	if off:
		drive.hud.post("HOPP-IN: \"WE'VE NOTICED SOME CONCERNING FEEDBACK.\" YOU'RE OFF FOR THE DAY.", 6.0)
		finish(false)
		return
	stage = "wait"
	_ride_wait = rng.randf_range(6.0, 14.0)
	drive.clear_route()

# ------------------------------------------------------------------ street race

func _street(_dt: float) -> void:
	if race: return
	var c := car()
	if c.sim.pos.distance_to(race_start) < 22.0 and c.sim.speed() < 2.0:
		drive.hud.post(Hints.fmt("{use}: SIGN IN WITH MARCO ($%d)" % int(race_route.buy_in)), 0.2)
		if Input.is_action_just_pressed("use"): sign_in()

## Pay Marco and line up.
func sign_in() -> bool:
	if not race_rival.is_empty():
		var why := pinks_block()
		if why != "":
			drive.hud.post(why, 4.0)
			return false
	var fee := int(race_route.buy_in) if race_rival.is_empty() else 0
	if int(drive.save.get("cash", 0)) < fee:
		drive.hud.post("MARCO: \"$%d. I DON'T DO IOUS. I'VE MET YOU.\"" % fee, 4.0)
		return false
	drive.save.cash = int(drive.save.cash) - fee
	earned -= fee
	race = StreetRace.new()
	add_child(race)
	race.setup(drive, race_route, rng, race_rival)
	race.closed.connect(_on_race_closed)
	stage = "race"
	return true

## Why you can't put this car's pink slip on the line ("" when you can).
func pinks_block() -> String:
	if drive.car_i < 0: return "MARCO: \"THAT'S NOT YOUR CAR TO BET.\""
	if String(car().spec.get("id", "")) == "tow": return "MARCO: \"TOBY'S WRECKER? NO.\""
	if (drive.save.garage as Array).size() < 2: return "MARCO: \"IT'S YOUR ONLY CAR. HOW WOULD YOU GET HOME?\""
	return ""

func _on_race_closed(won: int) -> void:
	if won > 0: pay(won)
	if race and not race.rival.is_empty():
		var st: Dictionary = drive.save.get("street", {})
		if race.won_pinks():
			var e := CarCatalog.entry(String(race.rival.car))
			(drive.save.garage as Array).append({ "id": String(race.rival.car), "paint": String(race.rival.get("paint", "#8a8e94")), "damage": {},
				"parts": {}, "looks": {}, "tune": {}, "wear": { "fuel": 0.3 }, "installing": [], "odo_km": float(int(e.get("year", 2000)) % 17) * 9000.0 + 40000.0, "pinks": true })
			st.pinks = int(st.get("pinks", 0)) + 1
		else:
			drive.lose_current_car()
		drive.save.street = st
		SaveGame.write(drive.save)
	finish(true)

# ------------------------------------------------------------------ markers

func _draw() -> void:
	if not active(): return
	var p := Vector2.INF
	var r := 14.0
	match kind:
		"pizza": p = shop.p if stage == "pickup" else (stops[stop_i].p if stage == "deliver" and stop_i < stops.size() else Vector2.INF)
		"tow":
			if stage == "deliver": p = tow_dest.p
			r = 18.0
		"drag":
			if stage == "drive" and strip == null: p = DragStrip.START
		"street":
			if race == null: p = race_start
			r = 20.0
		"ride":
			if stage == "pickup": p = rider.from
			elif stage == "ride": p = rider.to
	if p == Vector2.INF: return
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	draw_arc(p * CarArt.PX, r * CarArt.PX, 0.0, TAU, 48, Color(1.0, 0.75, 0.2, 0.35 + 0.3 * pulse), 4.0)
	draw_arc(p * CarArt.PX, r * 0.6 * CarArt.PX, 0.0, TAU, 32, Color(1.0, 0.75, 0.2, 0.2), 2.0)


## A broken-down car waiting on the shoulder with its hazards on; once hooked it rides behind
## the wrecker on its back wheels, trailing like a trailer.
class TowTarget extends Node2D:
	var spec: Dictionary
	var view: CarView
	var pos := Vector2.ZERO
	var heading := 0.0
	var mass := 1300.0
	var label := "CAR"
	var hooked := false
	var _rear := Vector2.ZERO
	var _flip := 1.0              # hooked by the back end: it rides facing backwards

	func setup(car_spec: Dictionary, at: Vector2, h: float, rng: RandomNumberGenerator) -> void:
		spec = car_spec
		pos = at
		heading = h
		mass = float(spec.get("mass", 1300.0))
		label = "%s %s" % [String(spec.get("make", "")).to_upper(), String(spec.get("model", "")).to_upper()]
		view = CarView.new()
		var hit := { "front": rng.randf() * 0.7, "rear": rng.randf() * 0.3, "left": rng.randf() * 0.4, "right": rng.randf() * 0.4 }
		view.art = CarArt.new(spec, Color(String(spec.get("paint", "#8a8e94"))), hit, rng.randi())
		view.blink_left = true
		view.blink_right = true
		add_child(view)
		_place()

	## One end of the car: +1 the nose, -1 the tail.
	func end(side: float) -> Vector2:
		return pos + Vector2(cos(heading), sin(heading)) * float(spec.get("length", 4.5)) * 0.5 * side

	func hook(by_nose: bool) -> void:
		hooked = true
		view.blink_left = false
		view.blink_right = false
		_flip = 1.0 if by_nose else -1.0
		var dir := Vector2(cos(heading), sin(heading)) * _flip
		_rear = pos - dir * float(spec.get("wheelbase", 2.6)) * 0.5

	## Trailer kinematics: the lifted end sits on the hitch, the wheels on the ground follow it.
	func follow(hitch: Vector2) -> void:
		var l := float(spec.get("length", 4.5))
		var reach := l * 0.5 + float(spec.get("wheelbase", 2.6)) * 0.5
		var dir := (hitch - _rear)
		if dir.length() < 0.01: return
		dir = dir.normalized()
		_rear = hitch - dir * reach
		pos = hitch - dir * l * 0.5
		heading = dir.angle() if _flip > 0.0 else dir.angle() + PI
		_place()

	func _place() -> void:
		position = pos * CarArt.PX
		view.heading = heading

	func sort_point() -> Vector2:
		return global_position
