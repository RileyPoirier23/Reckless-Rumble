## The in-development trailer, filmed off the real game: the title, where the story's at (four
## cutscenes), then the road: a burnout in the lot, a drift on the runway, a run at drag night,
## getting pulled over, and the chase after. Cards and captions over it all.
##   XDG_DATA_HOME=<dir with the dev save> xvfb-run -a -s "-screen 0 1280x720x24" godot --path game \
##     --write-movie trailer.avi --fixed-fps 30 -s tests/trailer_video.gd -- --trailer
## Then ffmpeg turns the AVI into an MP4 (see the README).
extends SceneTree

var cap: Captions
var card: Card

func _initialize() -> void:
	cap = Captions.new()
	root.add_child.call_deferred(cap)
	card = Card.new()
	root.add_child.call_deferred(card)
	change_scene_to_file("res://title.tscn")
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
	await _wait(0.6)
	# --- the title
	await _wait(2.5)
	card.show_card("DRIVEBOSS", "IN DEVELOPMENT", "FROM THE MAKER OF CAGE BOSS", 4.5)
	await _wait(5.0)
	# --- the story so far
	await _story("party", 9.0, "THE STORY", "PORT RUMBLE, NEW BRUNSWICK, OCTOBER 2019. LEO COVINGTON IS 19, HIS DAD IS DEAD, AND HE'S DRUNK AT A PARTY WITH HIS DAD'S CAR KEYS.")
	await _story("the_meet", 9.0, "THE STORY", "HE DRIVES IT THROUGH THE FAMILIA'S MEET. NOW HE OWES DOM TORTELLINI A CAR, AND HIS DAYS AT THE INSPECTION COUNTER PAY FOR IT.")
	await _story("johnny", 8.0, "THE STORY", "THE NIGHTS ARE FOR THE ROAD: TOW CALLS, PIZZA, DRAG NIGHT, STREET RACES FOR PINK SLIPS AGAINST PEOPLE LIKE JOHNNY TRAM.")
	await _story("frankie", 8.0, "THE STORY", "SIX YEARS, THREE ENDINGS, AND A KID NAMED FRANKIE WHO'S WATCHING WHAT KIND OF MAN LEO TURNS INTO.")
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
	# Leo's Silvio, out of whatever lot the save has
	for i in (d.save.garage as Array).size():
		if String((d.save.garage[i] as Dictionary).id) == "silvio" and i != d.car_i:
			d._on_garage_pick(i)
			d = await _drive_ready()
			break
	d.traffic.enabled = true
	d.wildlife.enabled = false
	d.police.enabled = false
	await _burnout(d)
	await _drift(d)
	await _drag(d)
	await _oneton(d)
	await _pulled_over(d)
	await _chase(d)
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
	Input.action_press("brake")
	await _frames(4)
	Input.action_press("throttle")
	await _wait(5.5)
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

	func show_card(the_title: String, the_body: String, the_foot: String, secs: float) -> void:
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
		var a := clampf(minf(t / 0.5, (life - t) / 0.6), 0.0, 1.0)
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
		if foot != "": PixelFont.draw_centered(box, 320, 330, foot, Color(0.6, 0.58, 0.52, a), 1, ink)
