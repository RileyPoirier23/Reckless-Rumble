## Day 1 of a new game, played start to finish by an autopilot and filmed: the title, the
## prologue and the drunk drive, the next morning, making the old manager, the first shift at
## the counter, the evening's two drives and the night at home. Captions point out what came
## from Papers, Please and what came from CAGE BOSS. Everything on screen is the real game
## taking real inputs (keys, the stick's worth of steering, the desk cursor); nothing is staged.
##   XDG_DATA_HOME=<empty dir> xvfb-run -a -s "-screen 0 1280x720x24" godot --path game \
##     --write-movie day1.avi --fixed-fps 30 -s tests/day_one_video.gd -- --dayone-video
## (an empty user:// so it really is a new game: no save, no awards, default settings)
extends SceneTree

var cap: Captions
var said := {}                     # captions already shown (each one once)
var picks := { "party": 2, "the_kid": 0, "frankie": 0 }   # which option Leo takes in each scene's choice
var _last_scene: Node

func _initialize() -> void:
	cap = Captions.new()
	root.add_child.call_deferred(cap)
	# --from <step>: start part way through day one (for working on the autopilot)
	var a := OS.get_cmdline_user_args()
	var k := a.find("--from")
	if k >= 0 and k + 1 < a.size():
		StoryState.new_game()
		StoryState.avatar = { "name": "RAY MELANSON", "seed": 777, "female": 0, "age": 58 }
		StoryState.step = int(a[k + 1])
		StoryState.go(self)
	else:
		change_scene_to_file("res://title.tscn")
	_run()

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _frames(n: int) -> void:
	for k in n: await process_frame

## A key press: down for a couple of frames, then up (what a person's tap looks like to the game).
## It goes down at the top of a frame, before the scene reads its input (a timer wakes us after).
func _tap(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await _frames(3)
	Input.action_release(action)
	await _frames(2)

func _say(key: String, tag: String, text: String, secs := 6.0, where := "top", point := Rect2()) -> void:
	if said.has(key): return
	said[key] = true
	cap.show_caption(tag, text, secs, where, point)

func _script_of(n: Node) -> String:
	var s: Script = n.get_script() if n != null else null
	return s.resource_path if s != null else ""

func _run() -> void:
	await _wait(0.5)
	while true:
		var s := current_scene
		var path := _script_of(s)
		if s == null or path == "":
			await process_frame
			continue
		if s != _last_scene: print("day one: %s, step %d" % [path.get_file(), StoryState.step])
		_last_scene = s
		if path.ends_with("title.gd"): await _title(s)
		elif path.ends_with("story_scene.gd"):
			if await _story(s): break
		elif path.ends_with("avatar_scene.gd"): await _avatar(s)
		elif path.ends_with("counter_scene.gd"): await _counter(s)
		elif path.ends_with("drive.gd"): await _drive(s)
		else: await process_frame
	# the end of day one
	await _wait(1.0)
	_say("end", "THAT'S DAY ONE", "A SHIFT AT THE COUNTER, A CAR THAT LEAKS, A DEBT TO THE FAMILIA. DRIVEBOSS: FROM THE MAKER OF CAGE BOSS.", 7.0, "middle")
	await _wait(7.5)
	quit()

# ------------------------------------------------------------------ the title

func _title(s: Node) -> void:
	_say("title", "CAGE BOSS", "FROM THE MAKER OF CAGE BOSS: THE SAME PIXEL HAND, THE SAME FONT, THE SAME FACE GENERATOR. THIS TIME THE DESK IS A GARAGE COUNTER AND THE NIGHTS ARE FOR DRIVING.", 7.0, "bottom")
	await _wait(5.5)
	_say("new", "DAY 1", "A BRAND NEW GAME. NO SAVE, DEFAULT SETTINGS. EVERY INPUT FROM HERE ON IS AN AUTOPILOT PRESSING THE SAME KEYS YOU WOULD.", 6.0, "bottom")
	await _wait(1.5)
	# down to NEW STORY and in
	var items: Array = s.ITEMS
	var want := -1
	for k in items.size():
		if String(items[k][2]) == "story:new": want = k
	while int(s.sel) != want:
		await _tap("ui_down")
		await _wait(0.45)
	await _wait(1.2)
	await _tap("ui_accept")
	while current_scene == s: await process_frame

# ------------------------------------------------------------------ the story

## Plays a card or a cutscene through, reading at a person's pace. True when day one is over
## (the CHAPTER 1 card that ends the day).
func _story(sc: Node) -> bool:
	await _wait(0.4)
	var st: Dictionary = sc.step
	if String(st.type) == "card":
		if bool(st.get("day_ends", false)):
			_say("ch1", "DAY 1", "THE DAY ENDS ON A TITLE CARD. TOMORROW: THE COUNTER AGAIN, AND WHATEVER THE FAMILIA WANTS IN BAY 3.", 6.0, "bottom")
			await _wait(6.0)
			return true
		if String(st.title) == "PROLOGUE": _say("prologue", "DRIVEBOSS", "THE STORY: PORT RUMBLE, NEW BRUNSWICK (A PARODY OF MONCTON), OCTOBER 2019. LEO COVINGTON'S DAD DIED ON THE COAST ROAD. LEO IS NOT HANDLING IT.", 7.0, "bottom")
		await _wait(4.5)
		await _tap("ui_accept")
		while current_scene == sc: await process_frame
		return false
	var id := String(st.get("id", ""))
	match id:
		"party": _say("sets", "CAGE BOSS", "CUTSCENES THE CAGE BOSS WAY: EVERY SET IS PAINTED BY CODE, PIXEL BY PIXEL, AND EVERY FACE COMES OUT OF CAGE BOSS'S PORTRAIT GENERATOR.", 7.0, "top")
		"the_meet": _say("meet", "DRIVEBOSS", "HE CRASHED INTO THE FAMILIA'S MEET. NOW HE OWES DOM TORTELLINI A CAR. (THE FAST AND FURIOUS PARODIES START HERE.)", 6.0, "top")
		"gus_morning": _say("gus", "PAPERS, PLEASE", "THE DAY JOB: THE INSPECTION COUNTER AT HIS DAD'S GARAGE. THE GAME'S OTHER HALF IS A PAPERS, PLEASE DESK.", 6.0, "top")
		"clock_out_1": _say("clockout", "DRIVEBOSS", "CLOCK OUT, AND THE EVENING IS FOR DRIVING. THE COUNTER AND THE ROAD ARE ONE DAY.", 6.0, "top")
		"runs_great": _say("darrell", "DRIVEBOSS", "DARRELL SELLS LEO A '91 NISSUN SILVIO FOR $840. DARRELL LIES. THE MARKETTHING APP IS FULL OF DARRELLS.", 6.0, "top")
		"home_night": _say("home", "DRIVEBOSS", "ARIES, LEO'S LITTLE SISTER. THE STORY RUNS SIX YEARS AND KEEPS SCORE OF WHO LEO BECOMES.", 6.0, "top")
	while current_scene == sc:
		var i := int(sc.i)
		var lines: Array = sc.lines
		if i >= lines.size():
			await _tap("ui_accept")
			await _wait(0.3)
			continue
		var ln: Array = lines[i]
		var who := String(ln[0])
		if who == "choice":
			await _wait(1.6)
			var want: int = int(picks.get(id, 0))
			_say("choice_" + id, "DRIVEBOSS", "CHOICES ARE REMEMBERED: THEY CHANGE WHAT PEOPLE SAY TO LEO LATER, AND WHICH WAY THE STORY ENDS.", 5.0, "top")
			while int(sc.choice_sel) != want:
				await _tap("ui_down")
				await _wait(0.5)
			await _wait(0.8)
			await _tap("ui_accept")
			await _wait(0.5)
			continue
		if who in ["set", "cash", "flag", "pose"]:
			await process_frame
			continue
		var text := String(ln[1]) if ln.size() > 1 else ""
		# let it type out, then read it
		await _wait(text.length() / 55.0 + 0.9 + text.length() / 45.0)
		if current_scene != sc: break
		if int(sc.i) == i: await _tap("ui_accept")
	return false

# ------------------------------------------------------------------ the old manager

func _avatar(s: Node) -> void:
	await _wait(1.0)
	_say("avatar", "CAGE BOSS", "MAKE THE OLD MANAGER: CAGE BOSS'S FIGHTER-PORTRAIT GENERATOR, NOW MAKING THE MECHANIC WHO RAN THIS COUNTER BEFORE LEO.", 8.0, "bottom")
	var name := "RAY MELANSON"
	for k in name.length():
		s.edit.text = name.substr(0, k + 1)
		s.edit.text_changed.emit(s.edit.text)
		await _wait(0.12)
	await _wait(0.6)
	await _tap("ui_accept")                  # done typing: down to FACE
	await _wait(0.6)
	for k in 4:                              # a few faces
		await _tap("ui_accept")
		await _wait(0.9)
	await _tap("ui_down")                    # LOOK, AGE
	await _wait(0.5)
	await _tap("ui_down")
	await _wait(0.5)
	for k in 2:
		await _tap("ui_right")
		await _wait(0.5)
	await _tap("ui_down")                    # DONE
	await _wait(0.8)
	await _tap("ui_accept")
	while current_scene == s: await process_frame

# ------------------------------------------------------------------ the counter

func _counter(s: CounterScene) -> void:
	await _wait(1.0)
	cap.narrow = true
	_say("brief", "PAPERS, PLEASE", "EVERY MORNING OPENS ON THE DAY'S RULES, THE WAY PAPERS, PLEASE OPENS ON THE MINISTRY'S BULLETIN. THE RULES PILE UP AS THE WEEKS GO BY.", 7.0, "bottom")
	await _wait(6.0)
	s.pad_cursor = true
	s.press()                                # into the shift
	var served := -1
	while current_scene == s:
		match String(s.phase):
			"counter":
				if int(s.served) != served:
					served = int(s.served)
					await _serve(s, served)
				else: await process_frame
			"result":
				await _wait(2.6)
				await _cursor_to(s, Vector2(320, 300))
				s.press()
				await _wait(0.4)
			"day_end":
				_say("dayend", "PAPERS, PLEASE", "THE END OF THE DAY: WHAT YOU EARNED, THE FINES, THE BILLS. PAPERS, PLEASE'S EVENING LEDGER, WITH A GARAGE'S RENT INSTEAD OF A FAMILY'S HEAT.", 7.0, "top")
				await _wait(7.0)
				s.press()
				await _wait(1.0)
			"week_end", "month_end":
				await _wait(3.0)
				s.press()
				await _wait(1.0)
			_: await process_frame
	while current_scene == s: await process_frame
	cap.narrow = false

## One customer at the window: look at the papers, check two things that should agree, then the
## stamp the rules call for.
func _serve(s: CounterScene, n: int) -> void:
	await _wait(1.6)
	if n == 0:
		_say("window", "PAPERS, PLEASE", "ONE PERSON AT THE WINDOW. THEIR PAPERS LAND ON THE DESK: WORK ORDER, REGISTRATION, LICENCE, INSURANCE. THE CAR WAITS IN THE BAY.", 7.0, "top")
		await _wait(3.0)
		_say("cageboss_desk", "CAGE BOSS", "CAGE BOSS PUT A FIGHT PROMOTER BEHIND A DESK OF CONTRACTS AND STAMPS. DRIVEBOSS PUTS LEO BEHIND A GARAGE COUNTER.", 6.0, "top")
	if String(s.c.get("napkin", "")) != "":
		_say("napkin", "PAPERS, PLEASE", "A NAPKIN TUCKED IN THE PAPERS: THE FAMILIA WANTS THIS CAR IN BAY 3. THE BRIBES AND THE QUIET FAVOURS ARE PAPERS, PLEASE'S EZIC, WITH CAR PARTS.", 7.0, "top")
	# move over the papers a little, the way you'd read them
	for d in s.docs:
		await _cursor_to(s, Vector2(d.pos) + Vector2(30, 14), 0.35)
		await _wait(0.35)
	# INSPECT, then two things side by side
	var pair := _pair(s)
	if not pair.is_empty():
		await _button(s, "INSPECT")
		if n == 0: _say("inspect", "PAPERS, PLEASE", "INSPECT: CLICK TWO THINGS THAT SHOULD AGREE. A MISMATCH LIGHTS UP RED, JUST LIKE A DISCREPANCY IN PAPERS, PLEASE.", 7.0, "top")
		for f in pair:
			await _cursor_to(s, (f.r as Rect2).get_center(), 0.6)
			await _wait(0.4)
			s.press()
			await _wait(0.5)
		await _wait(2.4)
		if s.inspecting: await _button(s, "INSPECT")
	# the stamp the rules call for
	var stamp := _right_stamp(s)
	if n == 0: _say("stamp", "PAPERS, PLEASE", "APPROVE, DENY, REPORT IT, OR WAVE IT INTO BAY 3. GET ONE WRONG AND IT'S A WARNING, TWICE A SHIFT, THEN A CITATION.", 7.0, "top")
	await _button(s, stamp)
	await _wait(1.2)

## Moves the desk cursor to `p` over `secs`, the way a stick or a mouse would.
func _cursor_to(s: CounterScene, p: Vector2, secs := 0.5) -> void:
	s.pad_cursor = true
	var from: Vector2 = s.cur
	var steps := maxi(1, int(secs * 30.0))
	for k in steps:
		var u := float(k + 1) / float(steps)
		s.cur = from.lerp(p, u * u * (3.0 - 2.0 * u))
		await process_frame

func _button(s: CounterScene, id: String) -> void:
	for i in CounterScene.BUTTONS.size():
		if String(CounterScene.BUTTONS[i].id) == id:
			await _cursor_to(s, s._button_rect(i).get_center(), 0.5)
			await _wait(0.3)
			s.press()
			await _wait(0.4)
			return

## Two things on the desk to hold side by side: a pair that disagrees if there is one (that's
## the catch), otherwise a pair that agrees (that's the check). Both must be on top, clickable.
func _pair(s: CounterScene) -> Array:
	s.inspecting = true
	var fs: Array = []
	for f in s.fields():
		if String(f.key) in ["notebook", "rule", "bolo"]: continue
		var hit: Dictionary = s.field_at((f.r as Rect2).get_center())
		if not hit.is_empty() and hit.r == f.r: fs.append(f)
	var good: Array = []
	var bad: Array = []
	for a in fs.size():
		for b in range(a + 1, fs.size()):
			if fs[a].get("doc", "") == fs[b].get("doc", ""): continue
			var v: Array = s.compare(fs[a], fs[b])
			if v[1] == false and bad.is_empty(): bad = [fs[a], fs[b]]
			elif v[1] == true and good.is_empty(): good = [fs[a], fs[b]]
	s.inspecting = false
	return bad if not bad.is_empty() else good

## What a careful inspector stamps: the call the rules judge right.
func _right_stamp(s: CounterScene) -> String:
	for id in ["APPROVED", "DENIED", "WRENCH", "REPORT"]:
		var r := CounterRules.judge(s.c, id, s.jday(), s.bolo_now())
		if bool(r.get("correct", false)): return id
	return "APPROVED"

# ------------------------------------------------------------------ the drives

func _drive(d: Node) -> void:
	while d.car == null or d.mission == null:
		if current_scene != d: return
		await process_frame
	var title := String(d.mission.m.get("title", ""))
	match title:
		"LAST CALL":
			_say("drunk", "DRIVEBOSS", "THE PROLOGUE: DAD'S SUPREEM, 1:36 A.M., DRIZZLE, DRUNK. THE STEERING ANSWERS LATE AND DRIFTS ON PURPOSE. IT DOES NOT END WELL.", 7.0, "top")
		"RUNS GREAT":
			_say("tow", "DRIVEBOSS", "TOBY'S TOW TRUCK, ACROSS TOWN TO THE TIM BURTONS ON MOUNTAIN RD. THE GPS PLOTS THE ROUTE; THE SIGNALS AND STOP SIGNS ARE REAL, AND SO ARE THE POLICE.", 7.0, "top")
		"IT RUNS. GREAT.":
			_say("silvio", "DRIVEBOSS", "LEO'S FIRST CAR. EVERY CAR IN THE GAME (THREE HUNDRED AND SOME PARODIES) DRIVES ON THE SAME TIRE-AND-ENGINE PHYSICS.", 7.0, "top")
	var pilot := Autopilot.new()
	pilot.drive = d
	d.add_child(pilot)
	while current_scene == d:
		# Employee of the Month cards come up when you stop: read it, carry on
		if d.award_card.visible:
			_say("award", "CAGE BOSS", "EMPLOYEE OF THE MONTH: THE ACHIEVEMENTS ARE FRAMED PHOTOS ON THE BREAK ROOM WALL, LIKE CAGE BOSS'S TROPHY CASE.", 6.0, "top")
			await _wait(3.5)
			await _tap("ui_accept")
		await process_frame


## Drives the player's car along the GPS route with the same inputs a player has: gas, brake and
## a steering axis. Keeps a gap to the car ahead, stops for red lights and stop signs, slows for
## corners and stops on the objective.
class Autopilot extends Node:
	var drive: Node
	var held := {}
	var _stop_at := -1                # the junction being stopped at
	var _stopped_t := 0.0
	var _cleared := {}                 # junctions already stopped at and gone through
	var _log_t := 0.0
	var _stuck_t := 0.0                # pushing on the gas and going nowhere
	var _back_t := 0.0                 # backing out of it
	var _rg := 0.0                     # time spent getting out of reverse

	func _physics_process(dt: float) -> void:
		var car: PlayerCar = drive.car
		if car == null or drive.modal_open() or drive.mission == null or drive.mission.done:
			_controls(0.0, 0.25, 0.0, 1.0)
			return
		var route: PackedVector2Array = drive.gps.route
		var o: Dictionary = drive.mission.objective()
		var p: Vector2 = car.sim.pos
		var v: float = car.sim.speed()
		var fwd := Vector2.from_angle(car.sim.heading)
		if route.size() < 2 or o.is_empty():
			_controls(0.0, 0.25, 0.0, 1.0)
			return
		# where along the route we are (the nearest point on it, not just the nearest corner: a
		# corner still ahead of us mustn't be skipped), and a point to aim at further on
		var best := 0
		var bd := INF
		var on := p
		for k in route.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, route[k], route[k + 1])
			var dd := q.distance_squared_to(p)
			if dd < bd:
				bd = dd
				best = k
				on = q
		var look := clampf(5.0 + v * 0.9, 6.0, 18.0)
		var aim := _along(route, best, on, look)
		var err := wrapf(fwd.angle_to(aim - p), -PI, PI)
		var steer := clampf(err * 2.2, -1.0, 1.0)
		# how fast: the corner ahead, the car ahead, the junction ahead, the end
		var want := 13.0
		var bend := absf(wrapf(fwd.angle_to(_along(route, best, on, 22.0) - p), -PI, PI))
		want = lerpf(want, 5.0, clampf(bend / 1.2, 0.0, 1.0))
		var gap := _gap_ahead(p, fwd)
		if gap < 30.0: want = minf(want, maxf(0.0, (gap - 7.0) * 0.7))
		var to_end := p.distance_to(o.to)
		if to_end < 45.0: want = minf(want, maxf(0.0, sqrt(2.0 * 2.5 * maxf(0.0, to_end - float(o.radius) * 0.4))))
		var stop := _junction_stop(on, fwd, route, best, dt, v)
		if stop >= 0.0: want = minf(want, sqrt(2.0 * 3.0 * maxf(0.0, stop - 1.0)))
		_log_t += dt
		if _log_t > 5.0:
			_log_t = 0.0
			print("pilot: at %s  %.1f m/s  want %.1f  gap %.0f  stop %.1f  to go %.0f m  gear %d  rpm %.0f  blown %s  surface %s  hit %s  dmg %s" % [str(p.round()), v, want, gap, stop, to_end, car.sim.gear, car.sim.rpm, car.sim.engine_blown, car.sim.surface, (car.last_hit.get_class() + ":" + str(car.last_hit.name)) if is_instance_valid(car.last_hit) else "-", str(car.damage)])
		var th := 0.0
		var br := 0.0
		var hb := 0.0
		if v < want - 0.5: th = clampf((want - v) * 0.25, 0.15, 0.75)
		elif v > want + 0.6: br = clampf((v - want) * 0.3, 0.1, 1.0)
		# held at a stop: a light foot and the handbrake (a firm one would find reverse)
		if want < 0.3 and v < 1.0:
			th = 0.0
			br = 0.25
			hb = 1.0
		# backing up by mistake: the gas finds drive again, but only a fresh press from a standstill
		# does (in reverse the gas is the brake): feather it under a "press" to stop, then let go
		# and press again
		if car.sim.gear < 0 and want > 0.5 and _back_t <= 0.0:
			br = 0.0
			_rg += dt
			if v > 0.15:
				th = 0.25
				_rg = 0.0
			else: th = 0.0 if fmod(_rg, 1.2) < 0.5 else 0.6     # (the keyboard gas eases off, so a long let-go)
		# nosed into something: back off it (the brake reverses once stopped), wheel the other way
		_stuck_t = _stuck_t + dt if th > 0.3 and v < 0.4 and want > 3.0 else 0.0
		if _stuck_t > 2.5:
			_stuck_t = 0.0
			_back_t = 1.8
		if _back_t > 0.0:
			_back_t -= dt
			_controls(0.0, 0.7, -steer, 0.0)
			return
		_controls(th, br, steer, hb)

	## The point `ahead` metres on along the route from where we are.
	func _along(route: PackedVector2Array, k: int, p: Vector2, ahead: float) -> Vector2:
		var left := ahead
		var at := p
		for j in range(k + 1, route.size()):
			var seg := route[j] - at
			if seg.length() >= left: return at + seg.normalized() * left
			left -= seg.length()
			at = route[j]
		return route[route.size() - 1]

	## Metres to the nearest car in our lane ahead (traffic, police, racers), or INF.
	func _gap_ahead(p: Vector2, fwd: Vector2) -> float:
		var out := INF
		var others: Array = []
		for c in drive.traffic.cars: others.append(c.pos)
		for a in drive.traffic.extra:
			if is_instance_valid(a) and a.get("sim") != null: others.append(a.sim.pos)
		for q in others:
			var rel: Vector2 = q - p
			var ahead := rel.dot(fwd)
			if ahead < 0.0 or ahead > 40.0: continue
			if absf(rel.dot(fwd.orthogonal())) > 2.4: continue
			out = minf(out, ahead)
		return out

	## Metres to where we have to stop for a junction ahead (red light, stop sign), or -1.
	func _junction_stop(p: Vector2, fwd: Vector2, route: PackedVector2Array, k: int, dt: float, v: float) -> float:
		var furn: RoadFurniture = drive.furniture
		var tr: Traffic = drive.traffic
		for step_m in range(4, 36, 3):
			var q := _along(route, k, p, float(step_m))
			var n := furn._junction_at(q)
			if n < 0 or _cleared.has(n): continue
			var j: Dictionary = tr.junctions[n]
			# the arm we're coming in on
			var from := -1
			var bestd := -2.0
			var road := {}
			for e in tr.map.g_adj[n]:
				var arm: Vector2 = (tr.map.g_pos[e[0]] - tr.map.g_pos[n]).normalized()
				var dd := arm.dot(-fwd)
				if dd > bestd:
					bestd = dd
					from = int(e[0])
					road = e[2]
			var major: bool = (j.majors as Array).has(int(road.get("idx", -1)))
			var dist: float = p.distance_to(tr.map.g_pos[n]) - tr.stop_line(n, from)
			var must := false
			var wait_s := 0.0
			match String(j.control):
				"signal":
					var g := 0 if major else 1
					var light := Traffic.signal_state(int(j.offset), g)
					must = light == "red" or (light == "amber" and dist > 6.0)
				"allway":
					must = true
					wait_s = 1.4
				"priority":
					must = not major and String(road.get("cls", "")) != "ramp"
					wait_s = 1.4
			if not must:
				return -1.0
			if dist < -1.0:
				_cleared[n] = true             # already in it
				return -1.0
			if wait_s > 0.0 and v < 0.4 and dist < 3.0:
				_stopped_t += dt
				if _stopped_t >= wait_s:
					_cleared[n] = true
					_stopped_t = 0.0
					return -1.0
			return dist
		return -1.0

	func _controls(th: float, br: float, steer: float, hb := 0.0) -> void:
		_press("throttle", th)
		_press("brake", br)
		_press("handbrake", hb)
		_press("steer_right", maxf(steer, 0.0))
		_press("steer_left", maxf(-steer, 0.0))

	func _press(action: String, amount: float) -> void:
		if amount > 0.02:
			Input.action_press(action, amount)
			held[action] = true
		elif held.get(action, false):
			Input.action_release(action)
			held[action] = false

	## Hands off when the drive scene goes (and the autopilot with it).
	func _exit_tree() -> void:
		for a in held: Input.action_release(a)
		held.clear()


## The captions: a strip with a coloured tag (PAPERS, PLEASE in stamp red, CAGE BOSS in gold),
## the text, and sometimes a box blinking round the thing it's talking about. On top of
## everything and through every scene change.
class Captions extends CanvasLayer:
	var box: Control
	var tag := ""
	var text := ""
	var where := "top"
	var point := Rect2()
	var t := 0.0
	var life := 0.0
	var queue: Array = []              # captions waiting their turn (each one gets its full time)
	var narrow := false                # at the counter: over the lot window, clear of the clock and the cash

	func _init() -> void:
		layer = 120
		box = Control.new()
		box.size = Vector2(640, 360)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.draw.connect(_draw_box)
		add_child(box)

	func show_caption(the_tag: String, the_text: String, secs: float, the_where: String, the_point: Rect2) -> void:
		var c := [the_tag, the_text, secs, the_where, the_point]
		if text != "" and t < life: queue.append(c)
		else: _start(c)

	func _start(c: Array) -> void:
		tag = String(c[0])
		text = String(c[1])
		life = float(c[2])
		where = String(c[3])
		point = c[4]
		t = 0.0

	func _process(dt: float) -> void:
		t += dt
		if t > life and not queue.is_empty(): _start(queue.pop_front())
		box.queue_redraw()

	func _draw_box() -> void:
		if text == "" or t > life: return
		var a := clampf(minf(t / 0.3, (life - t) / 0.4), 0.0, 1.0)
		var tag_col := Color("c8342c") if tag == "PAPERS, PLEASE" else (Color("d9a441") if tag == "CAGE BOSS" else Color("5a8ac8"))
		var x0 := 152.0 if narrow else 70.0
		var w := 314.0 if narrow else 500.0
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
		if point.size != Vector2.ZERO and int(t * 3.0) % 2 == 0:
			box.draw_rect(point.grow(3), Color(tag_col, a), false, 2.0)
