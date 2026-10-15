## The in-development trailer, filmed off the real game: the drive-in opening, where the story's
## at (four cutscenes), a day at the counter, then the road: the garage and the map, a burnout in
## the lot, a drift across the mall lot at Champagne Place, drag night, 1ton's hydraulics, a
## winter night on Coverdale Rd, getting pulled over, and the chase after. A different car for
## every clip, a fade between them with the place's name, and cards and captions over it all.
##   XDG_DATA_HOME=<dir with the dev save> xvfb-run -a -s "-screen 0 1280x720x24" godot --path game \
##     --write-movie trailer.avi --fixed-fps 30 -s tests/trailer_video.gd -- --trailer
## Then ffmpeg turns the AVI into an MP4 (see the README). TRAILER_ONLY=<scene> films one scene.
extends SceneTree

const SCENES := ["garage", "burnout", "drift", "drag", "oneton", "winter", "pulled_over", "chase"]

var cap: Captions
var card: Card
var fader: Fader
var drive_in: DriveIn

func _initialize() -> void:
	cap = Captions.new()
	root.add_child.call_deferred(cap)
	card = Card.new()
	root.add_child.call_deferred(card)
	fader = Fader.new()
	root.add_child.call_deferred(fader)
	drive_in = DriveIn.new()
	root.add_child.call_deferred(drive_in)
	_run()

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _frames(n: int) -> void:
	for k in n: await process_frame

func _tap(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await _frames(3)
	Input.action_release(action)
	await _frames(2)

func _say(tag: String, text: String, secs := 6.0, where := "top") -> void:
	cap.show_caption(tag, text, secs, where)

func _script_of(n: Node) -> String:
	var s: Script = n.get_script() if n != null else null
	return s.resource_path if s != null else ""

func _run() -> void:
	await _wait(0.3)
	var only := OS.get_environment("TRAILER_ONLY")      # one scene, for working on it
	if only == "":
		# --- the drive-in: Leo in the Silvio, the leader counts down, the feature flashes up the
		# title, and the camera goes into the screen
		await drive_in.ready_to_roll()
		await _wait(1.6)
		drive_in.countdown()
		await _wait(DriveIn.COUNT_S)
		drive_in.flash()
		await _wait(0.9)
		drive_in.push_in(DriveIn.PUSH_S)
		await _wait(DriveIn.PUSH_S)
		# the screen fills the frame: the card takes over, same layout, pixel for pixel
		card.show_card("DRIVEBOSS", "IN DEVELOPMENT", "FROM THE MAKER OF CAGE BOSS", 4.0)
		await process_frame
		drive_in.queue_free()
		await _wait(3.6)
		# --- the story so far
		await _story("party", 9.0, "THE STORY", "PORT RUMBLE, NEW BRUNSWICK, OCTOBER 2019. LEO COVINGTON IS 19, HIS DAD IS DEAD, AND HE'S DRUNK AT A PARTY WITH HIS DAD'S CAR KEYS.")
		await _story("the_meet", 9.0, "THE STORY", "HE DRIVES IT THROUGH THE FAMILIA'S MEET. NOW HE OWES DOM TORTELLINI A CAR, AND HIS DAYS AT THE INSPECTION COUNTER PAY FOR IT.")
		await _story("johnny", 8.0, "THE STORY", "THE NIGHTS ARE FOR THE ROAD: TOW CALLS, PIZZA, DRAG NIGHT, STREET RACES FOR PINK SLIPS AGAINST PEOPLE LIKE JOHNNY TRAM.")
		await _story("frankie", 8.0, "THE STORY", "SIX YEARS, THREE ENDINGS, AND A KID NAMED FRANKIE WHO'S WATCHING WHAT KIND OF MAN LEO TURNS INTO.")
	else:
		drive_in.queue_free()
	StoryState.active = false
	# every photo's already on the break room wall: no Employee of the Month cards in the way
	Awards.ensure()
	for a in Awards.LIST: Awards.won[String(a.id)] = { "at": 0, "n": Awards.won.size() }
	# --- the days
	if only == "" or only == "counter": await _counter()
	if only == "counter": quit()
	# --- the road
	await fader.out(0.5)
	print("trailer: to the lot")
	LoadingScreen.go(self, "res://drive.tscn", "THE LOT")
	_watch_cards()
	var d: Node = await _drive_ready()
	print("trailer: the lot's ready, car ", d.car.spec.get("id", "?"))
	d.traffic.enabled = true
	d.wildlife.enabled = false
	d.police.enabled = false
	for sc in SCENES:
		if only != "" and only != sc: continue
		await call("_" + sc, d)
	await fader.out(0.6)
	await _revive(d)
	if only != "": quit()
	# --- where it's at
	card.show_card("WHERE IT'S AT", "499 CARS. A COUNTER, A GARAGE, A CITY.\nTOW, PIZZA, RIDES, DRAG NIGHT, STREET RACES, THE MEET, THE AUCTION.\nPOLICE, WEATHER, SEASONS, MOOSE. 1TON'S HYDRAULICS.\nTHE STORY: FIVE CHAPTERS, THREE ENDINGS.\nFULL LOGITECH WHEEL SUPPORT. CONTROLLER SUPPORT.", "STILL BUILDING: MORE MISSIONS, MORE TOWN, POLISH.", 10.0)
	fader.in_(0.3)
	await _wait(9.4)
	await fader.out(0.5)
	card.show_card("DRIVEBOSS", "IN DEVELOPMENT", "FOLLOW ALONG: @506CLICKS", 6.0)
	fader.in_(0.3)
	await _wait(6.0)
	await fader.out(0.5)
	quit()

# ------------------------------------------------------------------ the story

## Plays the opening of a cutscene for `secs`, pressing through its lines at a reading pace.
func _story(id: String, secs: float, tag: String, text: String) -> void:
	await fader.out(0.4)
	StoryState.new_game()
	StoryState.active = true
	for k in StoryScript.STEPS.size():
		var st: Dictionary = StoryScript.STEPS[k]
		if st.type == "scene" and String(st.get("id", "")) == id: StoryState.step = k
	change_scene_to_file("res://story/story.tscn")
	await _wait(0.8)
	var sc = current_scene
	fader.in_(0.5)
	_say(tag, text, secs - 1.0, "top")
	var t := 0.0
	var line_t := 0.0
	while t < secs and is_instance_valid(sc) and current_scene == sc:
		await process_frame
		var dt := 1.0 / 30.0
		t += dt
		line_t += dt
		if sc._tr >= 0.0 or sc._leaving: continue
		var i := int(sc.i)
		var lines: Array = sc.lines
		if i >= lines.size() - 1: continue
		var ln: Array = lines[i]
		var who := String(ln[0])
		if who == "choice": continue
		var txt := String(ln[1]) if ln.size() > 1 else ""
		if line_t > txt.length() / 40.0 + 1.4:
			sc.shown = 9999.0
			sc.press()
			line_t = 0.0

# ------------------------------------------------------------------ the days

## A customer at the inspection counter: the papers, two things that get compared, the stamp.
func _counter() -> void:
	print("trailer: counter")
	await fader.out(0.4)
	change_scene_to_file("res://counter.tscn")
	await _wait(0.7)
	var sc = current_scene
	if sc == null or not _script_of(sc).ends_with("counter_scene.gd"):
		print("trailer: no counter scene")
		return
	sc.start_day(9)
	sc.press()                                  # past the morning brief
	sc.clock = 170.0
	sc.tick(0.01)
	sc.since = 40.0
	sc.next_honk = 0.0
	sc.tick(0.01)
	var cb: Dictionary = sc.rules.customer(10, "clean", { "plain": true })
	sc.waiting.push_front(cb)
	sc.next_customer()
	sc.pad_cursor = true
	sc.cur = Vector2(330, 190)
	await _wait(0.3)
	await _reveal("COVINGTON AUTO", "THE INSPECTION COUNTER")
	_say("THE DAYS", "THE DAYS ARE THE COUNTER. REGISTRATION, LICENCE, THE BILL OF SALE, THE STICKER LOG. FIND WHAT DOESN'T MATCH, STAMP IT, AND THE LINE OUTSIDE KEEPS HONKING.", 8.0, "top")
	await _wait(1.6)
	sc.inspecting = true
	var a: Dictionary = _field(sc, "reg", "owner")
	var b: Dictionary = _field(sc, "licence", "name")
	await _cursor_to(sc, a)
	if not a.is_empty(): sc.pick(a)
	await _wait(0.6)
	await _cursor_to(sc, b)
	if not b.is_empty(): sc.pick(b)
	await _wait(2.0)
	sc.inspecting = false
	sc.verdict = {}
	await _wait(0.6)
	sc.stamp("APPROVED")
	await _wait(2.2)

func _field(sc: Node, doc: String, key: String) -> Dictionary:
	for f in sc.fields():
		if f.key == key and (doc == "" or f.get("doc", "") == doc): return f
	return {}

## The cursor glides over to a field (a hand, not a teleport).
func _cursor_to(sc: Node, f: Dictionary) -> void:
	if f.is_empty(): return
	var to: Vector2 = (f.r as Rect2).get_center()
	var from: Vector2 = sc.cur
	var t := 0.0
	while t < 0.7:
		await process_frame
		t += 1.0 / 30.0
		sc.cur = from.lerp(to, smoothstep(0.0, 1.0, t / 0.7))

# ------------------------------------------------------------------ the road

## Employee of the Month cards come up when you stop: put them on the wall and carry on.
func _watch_cards() -> void:
	while true:
		var s := current_scene
		if s != null and _script_of(s).ends_with("drive.gd") and s.award_card != null and s.award_card.visible:
			await _wait(0.6)
			await _tap("ui_accept")
		await process_frame

func _drive_ready() -> Node:
	var t := 0.0
	while true:
		var s := current_scene
		if s != null and _script_of(s).ends_with("drive.gd") and s.car != null:
			t += 1.0 / 30.0
			# (the loading card holds the car; past a point we go anyway)
			if not s.hold_car or t > 12.0: return s
		await process_frame
	return null

## Fade to black and, behind it, put Leo in another car out of the lot, fresh.
func _cut(d: Node, car_id := "") -> void:
	await fader.out(0.45)
	_release_all()
	d.hold_car = false
	await _revive(d)
	if car_id != "" and String(d.car.spec.get("id", "")) != car_id:
		for i in (d.save.garage as Array).size():
			if String((d.save.garage[i] as Dictionary).id) == car_id:
				d._on_garage_pick(i)
				break
		await _drive_ready()
		d.hud.msgs.clear()                        # ("keys are in it": not for the camera)
	# a fresh car (every run of this writes the save: a hurt engine from the last take would stay)
	d.car.sim.reset_parts()
	d.car.sim.set_wear({})
	d.car.sim.engine_health = 1.0
	d.car.sim.fuel_l = d.car.sim.tank_l
	d.car.sim.coolant_c = 90.0
	d.car.sim.oil_c = 95.0
	d.car.sim.auto_gearbox = true
	print("trailer: in the ", d.car.spec.get("id", "?"))

## A wreck in the last take: back on its wheels behind the black.
func _revive(d: Node) -> void:
	if d.death.visible or d.car.dead:
		d.death.showing = false
		d.death.visible = false
		d._after_death()
		await _wait(0.5)

## The lights up on a set scene, its name in the corner.
func _reveal(title: String, sub := "") -> void:
	fader.set_title(title, sub)
	await fader.in_(0.5)

func _sky(d: Node, hour: float, weather := "clear") -> void:
	d.sky.time_h = hour
	d.sky.pick_weather(weather)
	d.sky.forced = true
	d.sky.snap()

## Steer toward a heading with the keys (digital, so it's a nudge when it's off).
func _hold_heading(d: Node, want: float) -> void:
	var err := wrapf(want - d.car.sim.heading, -PI, PI)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if err > 0.04: Input.action_press("steer_right")
	elif err < -0.04: Input.action_press("steer_left")

func _release_all() -> void:
	for a in ["throttle", "brake", "handbrake", "steer_left", "steer_right", "use", "ui_accept", "hydraulics"]: Input.action_release(a)

## The garage: the lot sorted by make, the looks tab with an underglow kit on the turntable, the
## parts site and the dyno; then the map of the whole province.
func _garage(d: Node) -> void:
	print("trailer: garage")
	await _cut(d, "silvio")
	_sky(d, 17.5)
	d._teleport(d.GARAGE_DOOR.get_center(), -PI / 2.0)
	d._store_car()
	d.garage.open(d.save)
	await _wait(0.4)
	await _reveal("COVINGTON AUTO", "THE GARAGE")
	_say("THE ROAD", "THE GARAGE: 499 CARS SORTED BY MAKE, EVERY ONE DRAWN AHEAD OF TIME. LEFT AND RIGHT PICK A CAR, UP AND DOWN JUMP A MAKE.", 7.0, "top")
	await _wait(1.4)
	for k in 3:
		await _tap("ui_right")
		await _wait(0.8)
	for k in 3:
		await _tap("ui_down")
		await _wait(0.9)
	await _tap("shift_up")
	await _wait(2.2)
	_say("THE ROAD", "UPGRADES BY THE STAGE. LOOKS: PAINT, RIMS, TINT, UNDERGLOW, STRIPES, KITS. ROCKAUTTO.CA SHIPS THE PARTS, AND THE DYNO PROVES THEM.", 8.0, "top")
	await _tap("shift_up")                      # LOOKS
	await _wait(0.6)
	for k in 12:                                # down to UNDERGLOW
		await _tap("ui_down")
		await _wait(0.1)
	await _wait(0.4)
	await _tap("ui_right")
	await _wait(0.8)
	await _tap("ui_right")
	await _wait(1.0)
	await _tap("horn")                          # the turntable from above
	await _wait(3.0)
	await _tap("shift_up")                      # ROCKAUTTO.CA
	await _wait(2.2)
	await _tap("shift_up")                      # DYNO
	await _wait(2.6)
	await _tap("ui_cancel")
	await _wait(0.6)
	d.hud.msgs.clear()
	_say("THE ROAD", "ONE MAP: PORT RUMBLE OUT ROUTE 106 TO SALISBURY AND HAVELOCK. EVERY JOB, SHOP AND STRIP ON IT, AND THE GPS ROUTES YOU THERE.", 6.0, "top")
	d.map_screen.current_name = ""
	d.map_screen.current_p = Vector2.INF
	d.map_screen.open()
	await _wait(1.6)
	await _tap("ui_tab_next")
	await _wait(1.6)
	await _tap("ui_tab_next")
	await _wait(2.0)
	d.map_screen.visible = false
	await _wait(0.4)

## In the lot at dusk: foot on the brake and the gas, and the rears go up in smoke.
func _burnout(d: Node) -> void:
	print("trailer: burnout")
	await _cut(d, "fjord_mustank_fastback_1969")
	_sky(d, 20.3)
	d._teleport(d.START + Vector2(0, 6), -PI / 2.0)
	await _wait(0.4)
	await _reveal("COVINGTON AUTO", "THE LOT, AFTER CLOSE")
	await _wait(0.8)
	_say("THE ROAD", "EVERY CAR DRIVES ON THE SAME TIRE, CLUTCH AND ENGINE PHYSICS. A REAR-DRIVER ON THE BRAKE AND THE GAS DOES THIS.", 6.0, "bottom")
	# (the line lock wants the gas and the brake both hard down; the street aids would cut the
	# gas as the rears spun up, so they're off for the show)
	var was: int = d.car.sim.assist
	d.car.sim.assist = CarSim.Assist.SIM
	# (the gas first: a brake pressed from a standstill is reverse on an automatic)
	d.car.sim.gear = 1
	Input.action_press("throttle")
	await _frames(3)
	Input.action_press("brake")
	for k in 11:
		await _wait(0.5)
		var c: PlayerCar = d.car
		print("trailer: burnout %.1fs th %.2f gear %d rpm %.0f vx %.2f w %.1f slip %.1f" % [k * 0.5, c.throttle_in, c.sim.gear, c.sim.rpm, c.sim.vx, c.sim.w_wheel, float(c.sim.wheel_slip[2])])
	Input.action_release("brake")
	await _wait(1.2)
	_release_all()
	d.car.sim.assist = was
	await _wait(0.8)

## The mall lot at Champagne Place after it shuts: the biggest empty slab of asphalt in the
## province. A flick into a right-hander and the gas holds it, most of the way round the lot.
func _drift(d: Node) -> void:
	print("trailer: drift")
	await _cut(d, "nissun_two_forty_ess_x_1993")
	_sky(d, 20.7)                               # (the last of the light: the slide has to read)
	d.parked.enabled = false                    # the lot's empty at this hour
	d.parked.clear()
	var lot: Rect2 = CarMeet.LOT
	var at := Vector2(lot.position.x + 30.0, lot.get_center().y - 22.0)
	d._teleport(at, 0.0)
	var v0 := 13.0                              # (any quicker and the flick spins it)
	d.car.sim.vx = v0
	d.car.sim.w_wheel = v0 / float(d.car.spec.tires.radius)
	d.car.sim.gear = 2
	d.car.sim.clutch_locked = true
	d.car.sim.assist = CarSim.Assist.STREET
	await _wait(0.3)
	await _reveal("CHAMPAGNE PLACE", "THE MALL LOT, AFTER TEN")
	_say("THE ROAD", "DRIFTS YOU CAN HOLD: A FLICK OF THE HANDBRAKE, THEN THE GAS. THE STICK SETS THE ANGLE, INTO THE CORNER FOR MORE, AWAY TO STRAIGHTEN.", 5.5, "bottom")
	_say("THE ROAD", "ON A CONTROLLER, THE KEYBOARD, OR A LOGITECH WHEEL (G29, G920, G923 AND THE REST): THE RIM TURNS THE ROAD WHEELS ONE FOR ONE, 900 DEGREES LOCK TO LOCK.", 5.5, "bottom")
	Input.action_press("throttle")
	await _wait(0.5)
	# the flick: full lock and the handbrake, then the stick holds the angle and the gas the speed,
	# the long way round the lot
	await _flick(d, "steer_right", 0.3)
	await _hold_drift(d, -0.35, 8.0, lot)
	_release_all()
	await _wait(0.8)
	d.parked.enabled = true

func _flick(d: Node, side: String, hb_s: float) -> void:
	Input.action_press(side)
	await _wait(0.15)
	Input.action_press("handbrake")
	await _wait(hb_s)
	Input.action_release("handbrake")

## Holds a slip angle (`want`, in radians, minus for a right-hander) the way a driver does: the
## stick into the corner for more angle, counter-steer for less, and the gas keeps the speed up.
func _hold_drift(d: Node, want: float, secs: float, lot: Rect2) -> void:
	var t := 0.0
	var k := 0
	var last := atan2(d.car.sim.vy, maxf(d.car.sim.vx, 0.1))
	var h0: float = d.car.sim.heading
	while t < secs:
		await process_frame
		t += 1.0 / 30.0
		k += 1
		var c: PlayerCar = d.car
		var beta := atan2(c.sim.vy, maxf(c.sim.vx, 0.1))
		var dbeta := (beta - last) * 30.0
		last = beta
		# the stick: toward the angle wanted (into the corner for more, counter-steer for less),
		# early when it's swinging fast
		var st := clampf((beta - want) * 2.5 + dbeta * 0.4, -1.0, 1.0)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if st > 0.0: Input.action_press("steer_right", st)
		else: Input.action_press("steer_left", -st)
		# the gas is the angle too: too sideways (or getting there fast), ease off and let the rears
		# bite; not enough, more
		var e := absf(beta) - absf(want)
		var de := dbeta * signf(beta)
		var v := c.sim.speed()
		Input.action_press("throttle", clampf(0.85 - e * 3.0 - maxf(de, 0.0) * 0.35, 0.15, 1.0) if v > 6.0 else 1.0)
		if k % 15 == 0: print("trailer: drift %.1fs pos %.0f,%.0f in %s v %.1f beta %.2f st %.2f drifting %s turned %.2f rpm %.0f dead %s" % [t, c.sim.pos.x, c.sim.pos.y, lot.has_point(c.sim.pos), v, beta, st, c.sim.drifting, wrapf(c.sim.heading - h0, -PI, PI), c.sim.rpm, c.dead])

## Drag night on runway 7: sign in, stage, the tree, and go on the green.
func _drag(d: Node) -> void:
	print("trailer: drag")
	await _cut(d, "dodgy_challenjer_hellcatt_2017")
	_sky(d, 22.3)
	d.save.cash = maxi(int(d.save.cash), 5000)
	d.jobs.start("drag")
	d._teleport(DragStrip.START + Vector2(-20, 0), 0.0)
	await _wait(0.4)
	await _reveal("AIRSTRIP 7", "DRAG NIGHT")
	await _wait(0.6)
	d.jobs.open_strip()
	await _wait(0.4)
	var strip = d.jobs.strip
	if strip == null: return
	_say("THE ROAD", "DRAG NIGHT AT AIRSTRIP 7: DIAL IN, STAGE, AND LEAVE ON THE GREEN. A RED LIGHT OR A SLOW TREE AND THE PURSE GOES NEXT DOOR.", 7.0, "top")
	await _wait(2.5)
	await _tap("ui_accept")
	# the tree: eyes on your lane's green
	var t := 0.0
	while t < 8.0 and is_instance_valid(strip) and strip.state == "tree":
		await process_frame
		t += 1.0 / 30.0
		if strip.t >= float(strip.green[1]) - 0.05: break
	Input.action_press("throttle")
	t = 0.0
	while t < 14.0 and is_instance_valid(strip) and strip.state != "slip":
		await process_frame
		t += 1.0 / 30.0
	Input.action_release("throttle")
	await _wait(3.5)
	if is_instance_valid(strip): await _tap("ui_cancel")
	await _wait(0.8)
	d.jobs.finish(false)
	_release_all()

## The Luchadooros' lot: a word with 1ton, then three pumps and an Impaler on its back wheels.
func _oneton(d: Node) -> void:
	print("trailer: oneton")
	await _cut(d, "chevrolay_impaler_1964")
	_sky(d, 22.6)
	var lot = d.luchadooros
	var crew: Dictionary = d.save.get("crew", {})
	crew.met_oneton = true
	d.save.crew = crew
	d._teleport(Luchadooros.SPOT + Vector2(0, 7), -PI / 2.0)
	d.car.sim.set_world_velocity(Vector2.ZERO)
	await _wait(0.4)
	await _reveal("THE LUCHADOOROS", "1TON'S BAYS")
	await _wait(0.8)
	_say("THE ROAD", "1TON AND THE LUCHADOOROS. HE RUNS THE BAYS. LA CALAVERA RUNS THE STREETS. EL PULPO RUNS HIS MOUTH. GET IN WITH THEM AND 1TON TAKES BAY THREE.", 7.0, "top")
	await _tap("use")
	await _wait(3.6)
	if lot.open(): await _tap("ui_accept")
	await _wait(2.2)
	if lot.open(): await _tap("ui_cancel")
	await _wait(0.6)
	_say("THE ROAD", "HYDRAULICS AND DONKS, HIS LABOUR FREE (HIS MOTHER WOULD HEAR ABOUT IT). THREE PUMPS, AND THE BUTTON DUMPS THEM.", 7.0, "bottom")
	d.car.hyd = 3
	for k in 7:
		Input.action_press("hydraulics")
		await _wait(0.25)
		Input.action_release("hydraulics")
		await _wait(0.85)
	await _wait(1.0)
	_release_all()

## Coverdale Rd in a January snow, in a Wranglur: the seasons and the weather are the game too.
func _winter(d: Node) -> void:
	print("trailer: winter")
	await _cut(d, "jepp_wranglur_1995")
	d._apply_season("winter")
	_sky(d, 21.0, "snow")
	d.hud.msgs.clear()
	d.traffic.enabled = false                   # (nobody else out in it tonight)
	var x := 5900.0
	var at := Vector2(x, d.world.map._coverdale_y(x) - 2.0)
	d._teleport(at, PI)
	d.car.sim.vx = 12.0
	d.car.sim.w_wheel = 12.0 / float(d.car.spec.tires.radius)
	d.car.sim.gear = 2
	d.car.sim.clutch_locked = true
	await _wait(0.3)
	await _reveal("COVERDALE RD", "JANUARY")
	_say("THE ROAD", "FOUR SEASONS AND THE WEATHER THAT COMES WITH THEM: WET LEAVES, FOG ON THE RIVER, SNOW, BLIZZARDS, FREEZING RAIN. SUMMER TIRES ARE HOCKEY PUCKS. GUS SELLS WINTERS.", 7.5, "top")
	var t := 0.0
	while t < 9.0:
		# easy on the snow: a third throttle, and the wheel eased toward the lane, not banged
		var c: PlayerCar = d.car
		var lane_y: float = d.world.map._coverdale_y(c.sim.pos.x) - 2.0
		var want := PI - clampf((lane_y - c.sim.pos.y) * 0.08, -0.25, 0.25)
		var err := wrapf(want - c.sim.heading, -PI, PI)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if err > 0.0: Input.action_press("steer_right", clampf(err * 3.0, 0.0, 0.6))
		else: Input.action_press("steer_left", clampf(-err * 3.0, 0.0, 0.6))
		Input.action_press("throttle", 0.35 if c.sim.speed() < 14.0 else 0.15)
		await process_frame
		t += 1.0 / 30.0
	_release_all()
	await _wait(0.6)
	# (summer again behind the black: the season turning is a flash)
	await fader.out(0.45)
	d._apply_season("summer")
	d.hud.msgs.clear()
	d.traffic.enabled = true

## Doing 100 in a 50 past a patrol car on St George Blvd, and pulling over for it.
func _pulled_over(d: Node) -> void:
	print("trailer: pulled_over")
	await _cut(d, "fjord_mustank_2018")
	_sky(d, 14.5)
	var p = d.police
	p.enabled = true
	d.save.heat = 0.0
	var at := Vector2(5800, 1390) + Vector2(5.5, 2.5)
	d._teleport(at + Vector2(30, 0), 0.0)
	var k = p.spawn_at(at, 0.0)
	k.set_path(PackedVector2Array([at, at + Vector2(400, 0)]))
	d.car.sim.vx = 27.0
	d.car.sim.w_wheel = 27.0 / float(d.car.spec.tires.radius)
	d.car.sim.gear = 3
	d.car.sim.clutch_locked = true
	await _wait(0.2)
	_reveal("ST GEORGE BLVD", "A 50 ZONE")
	Input.action_press("throttle")
	var t := 0.0
	while t < 4.0 and p.state != "stop":
		_hold_heading(d, 0.0)
		await process_frame
		t += 1.0 / 30.0
	_say("THE ROAD", "PORT RUMBLE POLICE. SPEED PAST A CRUISER AND IT LIGHTS UP. PULL OVER AND THE OFFICER WALKS UP TO YOUR WINDOW.", 7.0, "top")
	await _wait(1.0)
	_release_all()
	d.hold_car = true
	t = 0.0
	while t < 25.0 and not p.stop_panel.visible:
		await process_frame
		t += 1.0 / 30.0
	await _wait(2.5)
	_say("THE ROAD", "WHAT YOU SAY AT THE WINDOW MATTERS: SORRY, A STORY, OR NOTHING. A TICKET, A WARNING, OR THE IMPOUND LOT.", 6.0, "top")
	await _wait(1.5)
	if p.stop_panel.visible: p.stop_panel.choose("sorry")
	t = 0.0
	while t < 12.0 and p.walk != "":
		await process_frame
		t += 1.0 / 30.0
	await _wait(1.5)
	d.hold_car = false
	p.clear()
	await _wait(0.5)

## Floor it instead: a chase through town, in something with four driven wheels.
func _chase(d: Node) -> void:
	print("trailer: chase")
	await _cut(d, "subaroo_imprezza_wrecks_2004")
	_sky(d, 15.0)
	var p = d.police
	p.enabled = true
	d.save.heat = 30.0
	var at := Vector2(5800, 1390) + Vector2(5.5, 2.5)
	d._teleport(at + Vector2(45, 0), 0.0)
	var k = p.spawn_at(at, 0.0)
	k.set_path(PackedVector2Array([at, at + Vector2(400, 0)]))
	d.car.sim.vx = 20.0
	d.car.sim.w_wheel = 20.0 / float(d.car.spec.tires.radius)
	d.car.sim.gear = 3
	d.car.sim.clutch_locked = true
	p._light_up(k, "speeding", 40.0)
	p.state = "chase"
	p.offences.append("fleeing")
	await _wait(0.2)
	_reveal("ST GEORGE BLVD", "THE SAME CRUISER")
	_say("THE ROAD", "OR DON'T PULL OVER. THE HEAT CLIMBS, MORE CRUISERS COME, AND IT ENDS WITH YOU LOSING THEM OR THE CAR GOING TO THE IMPOUND.", 7.0, "top")
	Input.action_press("throttle")
	var t := 0.0
	while t < 9.0:
		_hold_heading(d, 0.0)
		await process_frame
		t += 1.0 / 30.0
	_release_all()
	await _wait(1.0)
	p.clear()

# ------------------------------------------------------------------ overlays

class Captions extends CanvasLayer:
	var box: Control
	var tag := ""
	var text := ""
	var where := "top"
	var t := 0.0
	var life := 0.0
	var queue: Array = []

	func _init() -> void:
		layer = 120
		box = Control.new()
		box.size = Vector2(640, 360)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.draw.connect(_draw_box)
		add_child(box)

	func show_caption(the_tag: String, the_text: String, secs: float, the_where: String) -> void:
		var c := [the_tag, the_text, secs, the_where]
		if text != "" and t < life: queue.append(c)
		else: _start(c)

	func _start(c: Array) -> void:
		tag = String(c[0])
		text = String(c[1])
		life = float(c[2])
		where = String(c[3])
		t = 0.0

	func _process(dt: float) -> void:
		t += dt
		if t > life and not queue.is_empty(): _start(queue.pop_front())
		box.queue_redraw()

	func _draw_box() -> void:
		if text == "" or t > life: return
		var a := clampf(minf(t / 0.3, (life - t) / 0.4), 0.0, 1.0)
		var tag_col := Color("d9a441") if tag == "THE STORY" else Color("5a8ac8")
		var x0 := 70.0
		var w := 500.0
		var ls := Hud.wrap_lines(text, int((w - 16.0) / 4.0))
		var h := 22.0 + ls.size() * 10.0
		var y := 6.0 if where == "top" else (360.0 - h - 6.0 if where == "bottom" else 180.0 - h / 2.0)
		var r := Rect2(x0, y, w, h)
		box.draw_rect(r, Color(0.04, 0.035, 0.05, 0.9 * a))
		box.draw_rect(r, Color(tag_col, a), false, 1.0)
		var tw := PixelFont.width(tag) + 10.0
		box.draw_rect(Rect2(r.position + Vector2(6, 5), Vector2(tw, 11)), Color(tag_col, a))
		PixelFont.draw(box, r.position + Vector2(11, 7), tag, Color(0.05, 0.04, 0.06, a))
		for k in ls.size():
			PixelFont.draw(box, r.position + Vector2(8, 20 + k * 10), ls[k], Color(0.95, 0.92, 0.82, a))

## A full-screen card: a big title, lines under it, a small line at the bottom, over black.
class Card extends CanvasLayer:
	var box: Control
	var title := ""
	var body := ""
	var foot := ""
	var t := 0.0
	var life := 0.0

	func _init() -> void:
		layer = 121
		box = Control.new()
		box.size = Vector2(640, 360)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.draw.connect(_draw_box)
		add_child(box)

	var fade_in := true
	func show_card(the_title: String, the_body: String, the_foot: String, secs: float) -> void:
		fade_in = title != ""           # (the first card comes off the drive-in's screen: no fade)
		title = the_title
		body = the_body
		foot = the_foot
		life = secs
		t = 0.0

	func _process(dt: float) -> void:
		t += dt
		box.queue_redraw()

	func _draw_box() -> void:
		if title == "" or t > life: return
		var a := clampf(minf(t / 0.5 if fade_in else 1.0, (life - t) / 0.6), 0.0, 1.0)
		box.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.025, 0.04, 0.96 * a))
		var gold := Color(0.85, 0.64, 0.25, a)
		var bone := Color(0.95, 0.92, 0.82, a)
		var ink := Color(0.05, 0.04, 0.06, a)
		var big := 6 if title.length() <= 10 else 4
		var lines := body.split("\n")
		var block := 30.0 * big / 6.0 + 14.0 + lines.size() * 14.0
		var y := 180.0 - block / 2.0 - 10.0
		PixelFont.draw_centered(box, 320, y, title, gold, big, ink)
		y += 10.0 * big + 10.0
		for ln in lines:
			var sc := 2 if ln.length() <= 36 else 1
			PixelFont.draw_centered(box, 320, y, ln, bone, sc, ink)
			y += 7.0 * sc + 6.0
		if foot != "": PixelFont.draw_centered(box, 320, 330, foot, Color(0.6, 0.58, 0.52, a * clampf((t - 0.8) / 0.5, 0.0, 1.0)), 1, ink)


## The drive-in on the old Shediac Rd: a lot of cars nosed up to the screen under the stars, Leo's
## Silvio in the middle of the front row. The leader counts down on the screen, the feature
## flashes up the title, and the camera pushes in until the screen is the whole frame. The title
## on the screen is the Card's layout at half size, so the push-in ends pixel for pixel where the
## Card starts.
class DriveIn extends Node2D:
	const COUNT_S := 4.0
	const PUSH_S := 3.0
	const SCREEN := Rect2(160, 22, 320, 180)       # half the view, so the push-in is a 2x zoom
	var cam: Camera2D
	var t := 0.0
	var phase := "dark"                 # dark, count, flash, title
	var phase_t := 0.0
	var push_t := -1.0
	var views: Array = []
	var _built := false

	func _ready() -> void:
		CarView.screen_up = Vector2(0, -1)
		CarView.night = 1.0
		cam = Camera2D.new()
		# a wide shot: the whole field, the screen small at the top of it
		cam.position = Vector2(320, 250)
		cam.zoom = Vector2(0.7, 0.7)
		add_child(cam)
		cam.make_current()
		# the field: four rows of cars on the grass, well back from the screen, every one from the
		# catalogue in dark paints, nosed at it
		var rng := RandomNumberGenerator.new()
		rng.seed = 506
		var ids: Array = CarCatalog.ids()
		var paints := [Color("3a3c44"), Color("4a3b36"), Color("2d3b55"), Color("5a5a58"), Color("4b2f2f"), Color("36483a"), Color("6a6258"), Color("2a2a30")]
		# three rows, a car length and a half apart so nobody's on anybody's bumper; the back row
		# (up by the screen) drawn smaller and dimmer, the front row full size: depth. Leo's
		# Silvio is front and centre.
		const ROWS := [[296.0, 0.78, 9, 84.0], [372.0, 0.9, 8, 100.0], [448.0, 1.0, 7, 116.0]]
		for row in ROWS.size():
			var y: float = ROWS[row][0]
			var k_scale: float = ROWS[row][1]
			var n: int = ROWS[row][2]
			var gap: float = ROWS[row][3]
			for k in n:
				var x := 320.0 + (float(k) - float(n - 1) / 2.0) * gap + rng.randf_range(-4.0, 4.0)
				var leo := row == ROWS.size() - 1 and k == n / 2
				var id: String = "silvio" if leo else String(ids[rng.randi() % ids.size()])
				var spec := CarCatalog.spec(id)
				if spec.is_empty(): continue
				var v := CarView.new()
				v.art = CarArt.build(spec, Color("c0392b") if leo else paints[rng.randi() % paints.size()], {}, rng.randi() % 9 + 1, CarArt.CAR_SCALE, {}).take()
				v.heading = -PI / 2.0 + rng.randf_range(-0.04, 0.04)
				v.position = Vector2(x, y)
				v.scale = Vector2(k_scale, k_scale)
				v.modulate = Color(1, 1, 1).darkened((1.0 - k_scale) * 1.2)
				v.headlights = false
				v.z_index = row
				add_child(v)
				views.append(v)
		_built = true

	func ready_to_roll() -> void:
		while not _built: await get_tree().process_frame
		await get_tree().process_frame

	func countdown() -> void:
		phase = "count"
		phase_t = 0.0

	func flash() -> void:
		phase = "flash"
		phase_t = 0.0

	func push_in(secs: float) -> void:
		push_t = 0.0

	func _process(dt: float) -> void:
		t += dt
		phase_t += dt
		if phase == "flash" and phase_t > 0.18:
			phase = "title"
			phase_t = 0.0
		if push_t >= 0.0:
			push_t += dt
			var u := clampf(push_t / PUSH_S, 0.0, 1.0)
			u = u * u * (3.0 - 2.0 * u)
			var z := lerpf(0.7, 2.0, u)
			cam.zoom = Vector2(z, z)
			cam.position = Vector2(320, 250).lerp(SCREEN.get_center(), u)
		queue_redraw()

	func _draw() -> void:
		# the night: sky, a few stars, the tree line, the lot
		draw_rect(Rect2(-400, -400, 1440, 620), Color("07070c"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 90:
			var p := Vector2(rng.randf_range(-400, 1040), rng.randf_range(-400, 200))
			draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, rng.randf_range(0.2, 0.7) * (0.6 + 0.4 * sin(t * 2.0 + i))))
		draw_rect(Rect2(-400, 205, 1440, 20), Color("0d1410"))
		for i in 60:
			var x := -400.0 + i * 24.0
			draw_rect(Rect2(x, 190 + (i * 7) % 12, 14, 30), Color("0b100d"))
		# the field: mown grass, the stripes of the mower still in it, a gravel lane along the
		# front, and the low humps the rows park on
		draw_rect(Rect2(-400, 220, 1440, 600), Color("162a19"))
		for i in 48:
			if i % 2 == 0: draw_rect(Rect2(-400, 220 + i * 12, 1440, 12), Color(1, 1, 1, 0.025))
		for i in 400:
			var gx := -400.0 + fmod(i * 37.0 + (i * i) % 23, 1440.0)
			var gy := 222.0 + fmod(i * 53.0 + (i * 7) % 31, 380.0)
			draw_rect(Rect2(gx, gy, 1, 2), Color("1d3a22"))
		draw_rect(Rect2(-400, 262, 1440, 8), Color("2a2822"))
		for row in 3:
			draw_rect(Rect2(-400, 290 + row * 76, 1440, 12), Color("1b3320"))
		# the speaker posts
		for row in 3:
			for k in 24:
				var p := Vector2(-380 + k * 60 + row * 13, 300 + row * 76)
				draw_rect(Rect2(p, Vector2(2, 10)), Color("2a2a30"))
				draw_rect(Rect2(p + Vector2(-2, -3), Vector2(6, 4)), Color("3a3a42"))
		# the screen's tower and the screen, and its light on the lot
		var s := SCREEN
		draw_rect(Rect2(s.position.x - 6, s.position.y - 6, s.size.x + 12, s.size.y + 50), Color("26242c"))
		draw_rect(Rect2(s.position.x + 30, s.end.y, 20, 60), Color("1c1b22"))
		draw_rect(Rect2(s.end.x - 50, s.end.y, 20, 60), Color("1c1b22"))
		var glow := Color(0.9, 0.9, 1.0, 0.0)
		match phase:
			"dark":
				draw_rect(s, Color("15151a"))
				PixelFont.draw_centered(self, s.get_center().x, s.get_center().y - 4, "FEATURE PRESENTATION", Color("3a3a44"), 1)
			"count":
				draw_rect(s, Color("c9c4b6"))
				glow.a = 0.06
				# the leader: a sweep round the circle, a number a second
				var c := s.get_center()
				var n := maxi(1, int(ceil(COUNT_S - phase_t)))
				var sweep := fmod(phase_t, 1.0)
				draw_circle(c, 60.0, Color("9a958a"))
				draw_arc(c, 60.0, -PI / 2.0, -PI / 2.0 + TAU * sweep, 48, Color("3a3630"), 4.0)
				draw_line(Vector2(s.position.x, c.y), Vector2(s.end.x, c.y), Color("8a857a"), 1.0)
				draw_line(Vector2(c.x, s.position.y), Vector2(c.x, s.end.y), Color("8a857a"), 1.0)
				PixelFont.draw_centered(self, c.x, c.y - 14, str(n), Color("2a2622"), 4)
				# the scratches and the flicker
				for i in 3:
					var x := s.position.x + fmod(phase_t * 173.0 + i * 97.0, s.size.x)
					draw_rect(Rect2(x, s.position.y, 1, s.size.y), Color(0, 0, 0, 0.25))
				draw_rect(s, Color(0, 0, 0, 0.08 * absf(sin(phase_t * 37.0))))
			"flash":
				draw_rect(s, Color("fdfbf2"))
				glow.a = 0.35
			"title":
				# the Card's layout at half size (the push-in doubles it)
				draw_rect(s, Color(0.03, 0.025, 0.04))
				var c := s.get_center()
				var gold := Color(0.85, 0.64, 0.25)
				var bone := Color(0.95, 0.92, 0.82)
				var ink := Color(0.05, 0.04, 0.06)
				PixelFont.draw_centered(self, c.x, c.y + (141.0 - 180.0) / 2.0, "DRIVEBOSS", gold, 3, ink)
				PixelFont.draw_centered(self, c.x, c.y + (211.0 - 180.0) / 2.0, "IN DEVELOPMENT", bone, 1, ink)
				glow.a = 0.05
		if glow.a > 0.0:
			# the screen lights the lot, fading down the rows
			for row in 8:
				var a := glow.a * (1.0 - float(row) / 8.0)
				draw_rect(Rect2(s.position.x - 40 - row * 30, s.end.y + row * 30, s.size.x + 80 + row * 60, 30), Color(glow, a))
		# the frame's edges
		draw_rect(s, Color("0a0a0e"), false, 2.0)

## Black over everything between scenes, and the name of the place in the corner as it lifts.
class Fader extends CanvasLayer:
	const TITLE_S := 3.0
	var box: Control
	var a := 0.0
	var target := 0.0
	var speed := 2.0
	var title := ""
	var sub := ""
	var title_t := -1.0

	func _init() -> void:
		layer = 125
		box = Control.new()
		box.size = Vector2(640, 360)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.draw.connect(_draw_box)
		add_child(box)

	func out(secs: float) -> void:
		target = 1.0
		speed = 1.0 / maxf(secs, 0.05)
		await get_tree().create_timer(secs + 0.05, true, false, true).timeout

	func in_(secs: float) -> void:
		target = 0.0
		speed = 1.0 / maxf(secs, 0.05)
		await get_tree().create_timer(secs, true, false, true).timeout

	func set_title(the_title: String, the_sub: String) -> void:
		title = the_title
		sub = the_sub
		title_t = 0.0

	func _process(dt: float) -> void:
		a = move_toward(a, target, speed * dt)
		if title_t >= 0.0: title_t += dt
		box.queue_redraw()

	func _draw_box() -> void:
		if a > 0.0: box.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, a))
		if title == "" or title_t < 0.0 or title_t > TITLE_S: return
		var k := clampf(minf(title_t / 0.35, (TITLE_S - title_t) / 0.4), 0.0, 1.0)
		var slide := (1.0 - smoothstep(0.0, 1.0, minf(title_t / 0.35, 1.0))) * 24.0
		var x := 22.0 - slide
		var y := 304.0 if sub != "" else 314.0
		var h := 32.0 if sub != "" else 22.0
		var w := maxf(PixelFont.width(title, 2) as float, PixelFont.width(sub) as float) + 24.0
		box.draw_rect(Rect2(x - 8.0, y - 6.0, w, h), Color(0.04, 0.035, 0.05, 0.78 * k))
		box.draw_rect(Rect2(x - 8.0, y - 6.0, 4.0, h), Color(0.85, 0.64, 0.25, k))
		PixelFont.draw(box, Vector2(x + 4.0, y), title, Color(0.95, 0.92, 0.82, k), 2, Color(0.05, 0.04, 0.06, k))
		if sub != "": PixelFont.draw(box, Vector2(x + 4.0, y + 17.0), sub, Color(0.6, 0.58, 0.52, k), 1, Color(0.05, 0.04, 0.06, k))
