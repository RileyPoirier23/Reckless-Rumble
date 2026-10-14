## The in-development trailer, filmed off the real game: the title, where the story's at (four
## cutscenes), then the road: a burnout in the lot, a drift on the runway, a run at drag night,
## getting pulled over, and the chase after. Cards and captions over it all.
##   XDG_DATA_HOME=<dir with the dev save> xvfb-run -a -s "-screen 0 1280x720x24" godot --path game \
##     --write-movie trailer.avi --fixed-fps 30 -s tests/trailer_video.gd -- --trailer
## Then ffmpeg turns the AVI into an MP4 (see the README).
extends SceneTree

var cap: Captions
var card: Card

var drive_in: DriveIn

func _initialize() -> void:
	cap = Captions.new()
	root.add_child.call_deferred(cap)
	card = Card.new()
	root.add_child.call_deferred(card)
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
	await _wait(4.3)
	# --- the story so far
	var only := OS.get_environment("TRAILER_ONLY")      # one road scene, for working on it
	if only == "": await _story("party", 9.0, "THE STORY", "PORT RUMBLE, NEW BRUNSWICK, OCTOBER 2019. LEO COVINGTON IS 19, HIS DAD IS DEAD, AND HE'S DRUNK AT A PARTY WITH HIS DAD'S CAR KEYS.")
	if only == "": await _story("the_meet", 9.0, "THE STORY", "HE DRIVES IT THROUGH THE FAMILIA'S MEET. NOW HE OWES DOM TORTELLINI A CAR, AND HIS DAYS AT THE INSPECTION COUNTER PAY FOR IT.")
	if only == "": await _story("johnny", 8.0, "THE STORY", "THE NIGHTS ARE FOR THE ROAD: TOW CALLS, PIZZA, DRAG NIGHT, STREET RACES FOR PINK SLIPS AGAINST PEOPLE LIKE JOHNNY TRAM.")
	if only == "": await _story("frankie", 8.0, "THE STORY", "SIX YEARS, THREE ENDINGS, AND A KID NAMED FRANKIE WHO'S WATCHING WHAT KIND OF MAN LEO TURNS INTO.")
	# --- the road
	StoryState.active = false
	# every photo's already on the break room wall: no Employee of the Month cards in the way
	Awards.ensure()
	for a in Awards.LIST: Awards.won[String(a.id)] = { "at": 0, "n": Awards.won.size() }
	print("trailer: to the lot")
	LoadingScreen.go(self, "res://drive.tscn", "THE LOT")
	_watch_cards()
	var d: Node = await _drive_ready()
	print("trailer: the lot's ready, car ", d.car.spec.get("id", "?"))
	# a fresh car (every run of this writes the save: a hurt engine from the last take would stay)
	d.car.sim.reset_parts()
	d.car.sim.set_wear({})
	d.car.sim.engine_health = 1.0
	d.car.sim.fuel_l = d.car.sim.tank_l
	# Leo's Silvio, out of whatever lot the save has
	for i in (d.save.garage as Array).size():
		if String((d.save.garage[i] as Dictionary).id) == "silvio" and i != d.car_i:
			d._on_garage_pick(i)
			d = await _drive_ready()
			break
	d.traffic.enabled = true
	d.wildlife.enabled = false
	d.police.enabled = false
	print("trailer: hold_car %s locked %s assist %d" % [d.hold_car, d.car.locked, d.car.sim.assist])
	for sc in ["burnout", "drift", "drag", "oneton", "pulled_over", "chase"]:
		if only != "" and only != sc: continue
		await call("_" + sc, d)
	if only != "": quit()
	# --- where it's at
	card.show_card("WHERE IT'S AT", "499 CARS. A COUNTER, A GARAGE, A CITY.\nTOW, PIZZA, RIDES, DRAG NIGHT, STREET RACES, THE MEET, THE AUCTION.\nPOLICE, WEATHER, SEASONS, MOOSE. 1TON'S HYDRAULICS.\nTHE STORY: FIVE CHAPTERS, THREE ENDINGS.\nFULL LOGITECH WHEEL SUPPORT. CONTROLLER SUPPORT.", "STILL BUILDING: MORE MISSIONS, MORE TOWN, POLISH.", 10.0)
	await _wait(10.5)
	card.show_card("DRIVEBOSS", "IN DEVELOPMENT", "FOLLOW ALONG: @506CLICKS", 6.0)
	await _wait(6.5)
	quit()

# ------------------------------------------------------------------ the story

## Plays the opening of a cutscene for `secs`, pressing through its lines at a reading pace.
func _story(id: String, secs: float, tag: String, text: String) -> void:
	StoryState.new_game()
	StoryState.active = true
	for k in StoryScript.STEPS.size():
		var st: Dictionary = StoryScript.STEPS[k]
		if st.type == "scene" and String(st.get("id", "")) == id: StoryState.step = k
	change_scene_to_file("res://story/story.tscn")
	await _wait(0.8)
	var sc = current_scene
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

## Steer toward a heading with the keys (digital, so it's a nudge when it's off).
func _hold_heading(d: Node, want: float) -> void:
	var err := wrapf(want - d.car.sim.heading, -PI, PI)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if err > 0.04: Input.action_press("steer_right")
	elif err < -0.04: Input.action_press("steer_left")

func _release_all() -> void:
	for a in ["throttle", "brake", "handbrake", "steer_left", "steer_right", "use", "ui_accept"]: Input.action_release(a)

## In the lot at dusk: foot on the brake and the gas, and the rears go up in smoke.
func _burnout(d: Node) -> void:
	print("trailer: burnout")
	d.sky.time_h = 20.3
	d.sky.pick_weather("clear")
	d.sky.forced = true
	d.sky.snap()
	d._teleport(d.START + Vector2(0, 6), -PI / 2.0)
	d.car.sim.auto_gearbox = true
	await _wait(1.2)
	_say("THE ROAD", "EVERY CAR DRIVES ON THE SAME TIRE, CLUTCH AND ENGINE PHYSICS. A REAR-DRIVER ON THE BRAKE AND THE GAS DOES THIS.", 6.0, "bottom")
	# (the line lock wants the gas and the brake both hard down; the street aids would cut the
	# gas as the rears spun up, so they're off for the show)
	var was: int = d.car.sim.assist
	d.car.sim.assist = CarSim.Assist.SIM
	# (the gas first: a brake pressed from a standstill is reverse on an automatic)
	d.car.sim.gear = 1
	# (warmed up: cold, the engine won't rev past the three thousands)
	d.car.sim.coolant_c = 90.0
	d.car.sim.oil_c = 95.0
	Input.action_press("throttle")
	await _frames(3)
	Input.action_press("brake")
	for k in 11:
		await _wait(0.5)
		var c: PlayerCar = d.car
		print("trailer: burnout %.1fs th %.2f br %.2f dt %s gear %d rpm %.0f vx %.2f w %.1f slip %.1f locked %s hold %s eng %s" % [k * 0.5, c.throttle_in, Input.get_action_strength("brake"), c.sim.spec.get("drivetrain", "?"), c.sim.gear, c.sim.rpm, c.sim.vx, c.sim.w_wheel, float(c.sim.wheel_slip[2]), c.locked, d.hold_car, c.sim.clutch_locked])
		print("   fuel %.1f shift %.2f clutch %.2f health %.2f power %.0f kW ct %.0f pads %.1f slam %.2f hb %.2f stalled %s blown %s" % [c.sim.fuel_l, c.sim.shift_timer, c.sim.clutch_cond, c.sim.engine_health, c.sim._power_w / 1000.0, float(c.sim.spec.engine.clutch_torque), c.sim.pads_mm, c.sim.slam_roll if "slam_roll" in c.sim else -1.0, Input.get_action_strength("handbrake"), c.sim.stalled, c.sim.engine_blown])
	Input.action_release("brake")
	await _wait(1.2)
	_release_all()
	d.car.sim.assist = was
	await _wait(0.8)

## On the runway at night: a flick of the handbrake into a turn, then the gas holds it sideways.
func _drift(d: Node) -> void:
	print("trailer: drift")
	d.sky.time_h = 22.0
	d.sky.snap()
	var at := Vector2(DragStrip.RUNWAY.position.x + 40.0, DragStrip.RUNWAY.get_center().y)
	d._teleport(at, 0.0)
	d.car.sim.vx = 15.0
	d.car.sim.w_wheel = 15.0 / float(d.car.spec.tires.radius)
	d.car.sim.gear = 2
	d.car.sim.clutch_locked = true
	await _wait(0.8)
	_say("THE ROAD", "DRIFTS YOU CAN HOLD: A FLICK OF THE HANDBRAKE, THEN THE GAS. THE STICK SETS THE ANGLE, INTO THE CORNER FOR MORE, AWAY TO STRAIGHTEN.", 5.0, "bottom")
	_say("THE ROAD", "ON A CONTROLLER, THE KEYBOARD, OR A LOGITECH WHEEL (G29, G920, G923 AND THE REST): THE RIM TURNS THE ROAD WHEELS ONE FOR ONE, 900 DEGREES LOCK TO LOCK.", 5.0, "bottom")
	Input.action_press("throttle")
	await _wait(0.6)
	Input.action_press("steer_right")
	await _wait(0.15)
	Input.action_press("handbrake")
	await _wait(0.45)
	Input.action_release("handbrake")
	await _wait(2.6)
	Input.action_release("steer_right")
	Input.action_press("steer_left")
	await _wait(0.25)
	Input.action_press("handbrake")
	await _wait(0.4)
	Input.action_release("handbrake")
	await _wait(2.8)
	_release_all()
	await _wait(0.8)

## Drag night on runway 7: sign in, stage, the tree, and go on the green.
func _drag(d: Node) -> void:
	print("trailer: drag")
	d.sky.time_h = 22.3
	d.sky.snap()
	d.save.cash = maxi(int(d.save.cash), 5000)
	d.jobs.start("drag")
	d._teleport(DragStrip.START + Vector2(-20, 0), 0.0)
	await _wait(0.8)
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

## The Luchadooros' lot: a word with 1ton, then three pumps and the Silvio on its back wheels.
func _oneton(d: Node) -> void:
	print("trailer: oneton")
	d.sky.time_h = 22.6
	d.sky.snap()
	var lot = d.luchadooros
	var crew: Dictionary = d.save.get("crew", {})
	crew.met_oneton = true
	d.save.crew = crew
	d._teleport(Luchadooros.SPOT + Vector2(0, 7), -PI / 2.0)
	d.car.sim.set_world_velocity(Vector2.ZERO)
	await _wait(1.2)
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

## Doing 100 in a 50 past a patrol car on St George Blvd, and pulling over for it.
func _pulled_over(d: Node) -> void:
	print("trailer: pulled_over")
	d.sky.time_h = 14.5
	d.sky.snap()
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

## Floor it instead: a chase through town.
func _chase(d: Node) -> void:
	print("trailer: chase")
	var p = d.police
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
	_say("THE ROAD", "OR DON'T PULL OVER. THE HEAT CLIMBS, MORE CRUISERS COME, AND IT ENDS WITH YOU LOSING THEM OR THE CAR GOING TO THE IMPOUND.", 7.0, "top")
	Input.action_press("throttle")
	var t := 0.0
	while t < 13.0:
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
