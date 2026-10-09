## Drag Night at Airstrip 7: eighth-mile bracket racing on runway 7, top-down. Sign in against
## the next racer on the ladder, set a dial-in, stage, beat the tree, and get an ET slip.
## Lives on the HUD layer; the opponent is a real CarSim racing down the other lane.
class_name DragStrip
extends Control

signal closed(won: int)

const RUNWAY := Rect2(6600, 1010, 340, 24)
const LINE_X := 6612.0
const LANE_Y := [1016.0, 1028.0]          # 0: the other racer, 1: you
const START := Vector2(LINE_X, 1028.0)
const EIGHTH := 201.17
const SIXTY := 18.29
const THREE_THIRTY := 100.58
const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")
const GREEN := Color("6fbf5a")
const PAPER := Color("efe6cc")
const LAUNCH_RPM := 3800.0
const DIAL_MARGIN := 0.15        # how slow to dial in over a clean run, so a good run doesn't break out

static var _et_cache := {}

## The eighth-mile ET a car runs off the two-step with a clean launch, timed the way the strip
## times it (from leaving the beam). Dial-ins are set from this.
static func sim_et(spec: Dictionary) -> float:
	var key := JSON.stringify(spec).hash()
	if _et_cache.has(key): return _et_cache[key]
	var r := DragRacer.new()
	r.setup(spec, Vector2.ZERO, 1.0, 0.0, false)
	r.go_at = 0.0
	var t := 0.0
	var leave := -1.0
	var et := 99.0
	while t < 40.0:
		r.tick(1.0 / 60.0, t)
		t += 1.0 / 60.0
		if leave < 0.0 and r.sim.pos.x > 0.3: leave = t
		if r.sim.pos.x >= EIGHTH:
			et = t - leave
			break
	r.free()
	_et_cache[key] = et
	return et

var drive: Node
var state := "signin"          # signin, tree, race, slip
var rung := 0
var dial := 10.0               # yours
var won := 0
var t := 0.0
var t0 := 0.0                  # the tree starts
var green := [0.0, 0.0]
var lanes: Array = []          # per lane: { name, dial, staged, leave, rt, sixty, three30, et, kmh, red, done }
var result := {}
var opp: DragRacer
var opp_info := {}
var _suggest := 10.0

func setup(the_drive: Node) -> void:
	drive = the_drive
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rung = clampi(int(drive.save.get("drag_rung", 0)), 0, Jobs.LADDER.size() - 1)
	_signin()

func close() -> void:
	if opp:
		opp.queue_free()
		opp = null
	if drive and drive.car: drive.car.locked = false

func _signin() -> void:
	state = "signin"
	opp_info = Jobs.LADDER[rung]
	_suggest = snappedf(sim_et(drive.car.sim.spec) + DIAL_MARGIN, 0.05)
	dial = _suggest
	drive.car.locked = true

# ------------------------------------------------------------------ input

func _process(dt: float) -> void:
	t += dt
	queue_redraw()
	match state:
		"signin":
			if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_down"): dial = maxf(4.0, dial - 0.05)
			if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_up"): dial = minf(30.0, dial + 0.05)
			if Input.is_action_just_pressed("ui_accept"): _race()
			elif Input.is_action_just_pressed("ui_cancel"): closed.emit(won)
		"tree", "race":
			_run(dt)
		"slip":
			if Input.is_action_just_pressed("ui_accept"):
				if opp:
					opp.queue_free()
					opp = null
				_signin()
			elif Input.is_action_just_pressed("ui_cancel"):
				closed.emit(won)

# ------------------------------------------------------------------ the race

func _race() -> void:
	var purse := Jobs.drag_purse(rung)
	if int(drive.save.get("cash", 0)) < int(purse.fee):
		drive.hud.post("ENTRY IS $%d. YOU HAVE $%d. THE GUY AT THE TABLE LAUGHS." % [int(purse.fee), int(drive.save.cash)], 4.0)
		return
	drive.save.cash = int(drive.save.cash) - int(purse.fee)
	won -= int(purse.fee)
	var c: PlayerCar = drive.car
	drive._teleport(Vector2(LINE_X - float(c.spec.length) * 0.5, LANE_Y[1]), 0.0)
	c.sim.w_wheel = 0.0
	c.sim.gear = 1
	c.locked = false
	# the other lane: a real car on its own sim, dialled in a little slow
	opp = DragRacer.new()
	drive.ysort.add_child(opp)
	var spec := SaveGame.load_spec(String(opp_info.car))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_usec())
	var spread := float(opp_info.spread)
	var rts: Array = opp_info.rt
	opp.setup(spec, Vector2(LINE_X - float(spec.length) * 0.5, LANE_Y[0]), clampf(1.0 - spread * rng.randf() * 0.5, 0.75, 1.0),
		rng.randf_range(float(rts[0]), float(rts[1])))
	var opp_dial := snappedf(sim_et(spec) + spread * 0.4 + 0.03, 0.01)
	lanes = [_lane(String(opp_info.name), opp_dial, opp.sim.pos.x), _lane("YOU", dial, c.sim.pos.x)]
	var dmax := maxf(opp_dial, dial)
	t0 = t + 1.6
	green = [t0 + 1.5 + (dmax - opp_dial), t0 + 1.5 + (dmax - dial)]
	opp.go_at = green[0] + opp.rt
	state = "tree"
	drive.hud.post("STAGED. EYES ON THE TREE.", 2.0)

func _lane(name: String, d: float, x: float) -> Dictionary:
	return { "name": name, "dial": d, "staged": x, "press": -1.0, "leave": -1.0, "rt": 0.0, "sixty": -1.0, "three30": -1.0,
		"et": -1.0, "kmh": 0.0, "red": false, "done": false }

func _run(dt: float) -> void:
	if opp: opp.tick(dt, t)
	# staged: the car sits on the line (no idle creep, no backing up on the brake) until you
	# put your foot in it; go early and the beam sees you
	var me: PlayerCar = drive.car
	# reaction time is the driver's: green to the throttle going down (early is a red light)
	if float(lanes[1].press) < 0.0 and me.throttle_in > 0.5:
		lanes[1].press = t
		lanes[1].rt = t - float(green[1])
		if float(lanes[1].rt) < 0.0: lanes[1].red = true
		me.sim.w_eng = maxf(me.sim.w_eng, LAUNCH_RPM / CarSim.RPM)    # off the two-step
	if opp and float(lanes[0].press) < 0.0 and t >= opp.go_at:
		lanes[0].press = t
		lanes[0].rt = t - float(green[0])
	if float(lanes[1].leave) < 0.0 and me.throttle_in < 0.2:
		me.sim.pos.x = float(lanes[1].staged)
		me.sim.vx = 0.0
		me.sim.w_wheel = 0.0
		if me.sim.gear < 1: me.sim.gear = 1
	var xs := [opp.sim.pos.x if opp else 0.0, drive.car.sim.pos.x]
	var vs := [opp.sim.speed() if opp else 0.0, drive.car.sim.speed()]
	for i in 2:
		var l: Dictionary = lanes[i]
		if l.done: continue
		var d: float = xs[i] - float(l.staged)
		if float(l.leave) < 0.0 and d > 0.3:
			l.leave = t
			if float(l.press) < 0.0:                     # rolled through without the gas: still counts
				l.press = t
				l.rt = t - float(green[i])
			if t < float(green[i]): l.red = true
			if i == 1: state = "race"
		if float(l.leave) < 0.0: continue
		var e := t - float(l.leave)
		if float(l.sixty) < 0.0 and d >= SIXTY: l.sixty = e
		if float(l.three30) < 0.0 and d >= THREE_THIRTY: l.three30 = e
		if d >= EIGHTH:
			l.et = e
			l.kmh = float(vs[i]) * 3.6
			l.done = true
	if opp and opp.sim.pos.x > LINE_X + EIGHTH + 15.0: opp.braking = true
	var both: bool = lanes[0].done and lanes[1].done
	var timeout := t > t0 + 35.0
	if both or timeout or (bool(lanes[1].red) and float(lanes[1].leave) > 0.0 and lanes[0].done):
		_finish()

func _finish() -> void:
	for l in lanes:
		if float(l.et) < 0.0:
			l.et = 99.99
	result = Jobs.drag_winner(lanes[0], lanes[1])
	if not lanes[1].done and not bool(lanes[1].red): result = { "lane": 0, "why": "DID NOT FINISH" }
	var purse := Jobs.drag_purse(rung)
	if int(result.lane) == 1:
		drive.save.cash = int(drive.save.cash) + int(purse.win)
		won += int(purse.win)
		if rung < Jobs.LADDER.size() - 1:
			rung += 1
			drive.save.drag_rung = maxi(int(drive.save.get("drag_rung", 0)), rung)
		else:
			drive.save.airstrip_king = true
		drive.hud.post("WIN. +$%d. %s" % [int(purse.win), _taunt(true)], 5.0)
	else:
		drive.hud.post("LOSS (%s). %s" % [String(result.why), _taunt(false)], 5.0)
	SaveGame.write(drive.save)
	state = "slip"
	drive.car.locked = true

func _taunt(win: bool) -> String:
	if win: return ["THE CROWD MAKES A NOISE. MOSTLY GOOD.", "SOMEBODY BANGS ON YOUR ROOF. AFFECTIONATELY.", "GUS WOULD PRETEND HE WASN'T IMPRESSED."][randi() % 3]
	return ["THE TIMING TOWER DOESN'T CARE ABOUT YOUR EXCUSES.", "SOMEBODY IN THE BLEACHERS SAYS \"OOF.\"", "RUN IT BACK."][randi() % 3]

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	match state:
		"signin": _draw_signin()
		"tree", "race": _draw_tree()
		"slip":
			_draw_tree()
			_draw_slip()

func _panel(r: Rect2, col := Color(0.04, 0.035, 0.05, 0.92)) -> void:
	draw_rect(r, col)
	draw_rect(r, GOLD, false, 1.0)

func _draw_signin() -> void:
	var r := Rect2(150, 70, 340, 210)
	_panel(r)
	PixelFont.draw_centered(self, 320, 80, "DRAG NIGHT - AIRSTRIP 7", GOLD, 2)
	PixelFont.draw_centered(self, 320, 98, "RACER %d OF %d ON THE LADDER" % [rung + 1, Jobs.LADDER.size()], ASH)
	var spec := SaveGame.load_spec(String(opp_info.car))
	PixelFont.draw(self, Vector2(166, 116), String(opp_info.name), BONE, 2)
	PixelFont.draw(self, Vector2(166, 134), "%s %s '%s" % [String(spec.get("make", "")).to_upper(), String(spec.get("model", "")).to_upper(), str(int(spec.get("year", 0))).substr(2)], ASH)
	var lines := Hud.wrap_lines(String(opp_info.line), 52)
	for i in lines.size(): PixelFont.draw(self, Vector2(166, 148 + i * 9), String(lines[i]), BONE)
	var purse := Jobs.drag_purse(rung)
	PixelFont.draw(self, Vector2(166, 182), "ENTRY $%d     WIN PAYS $%d     YOU HAVE $%d" % [int(purse.fee), int(purse.win), int(drive.save.get("cash", 0))], GOLD)
	PixelFont.draw(self, Vector2(166, 202), "YOUR DIAL-IN", ASH)
	PixelFont.draw(self, Vector2(166, 212), "%.2f S" % dial, BONE, 3)
	PixelFont.draw(self, Vector2(290, 206), "THE SHEET SAYS ABOUT %.2f." % (_suggest - DIAL_MARGIN), ASH)
	PixelFont.draw(self, Vector2(290, 216), "RUN QUICKER THAN YOUR DIAL AND YOU LOSE.", ASH)
	PixelFont.draw_centered(self, 320, 262, Hints.fmt("{leftright}: DIAL-IN  {ui_accept}: RACE  {ui_cancel}: LEAVE"), BONE)

## The Christmas tree: two columns (the other lane on the left), stage bulbs, three ambers,
## green and red, lit by each lane's own clock.
func _draw_tree() -> void:
	var x0 := 586.0
	_panel(Rect2(x0 - 4, 60, 52, 150))
	for i in 2:
		var cx := x0 + 10 + i * 24
		var l: Dictionary = lanes[i] if lanes.size() > i else {}
		var g: float = green[i]
		var bulbs := [
			[GOLD.lightened(0.4), t > t0 - 1.0], [GOLD.lightened(0.4), t > t0 - 0.4],
			[Color("ffb020"), t >= g - 1.5], [Color("ffb020"), t >= g - 1.0], [Color("ffb020"), t >= g - 0.5],
			[GREEN.lightened(0.2), t >= g and not bool(l.get("red", false))], [RED, bool(l.get("red", false))],
		]
		for k in bulbs.size():
			var on: bool = bulbs[k][1]
			var col: Color = bulbs[k][0]
			var y := 72.0 + k * 19.0 if k >= 2 else 70.0 + k * 8.0
			var rad := 3.0 if k < 2 else 7.0
			if k >= 2: y = 92.0 + (k - 2) * 20.0
			draw_circle(Vector2(cx, y), rad + 1.0, INK)
			draw_circle(Vector2(cx, y), rad, col if on else col.darkened(0.78))
		PixelFont.draw_centered(self, cx, 200, "THEM" if i == 0 else "YOU", ASH)
	# the board up top: names and dial-ins
	if lanes.size() == 2:
		_panel(Rect2(180, 40, 280, 18))
		PixelFont.draw(self, Vector2(186, 45), "%s  %.2f" % [String(lanes[0].name), float(lanes[0].dial)], BONE)
		PixelFont.draw(self, Vector2(400, 45), "YOU  %.2f" % float(lanes[1].dial), GOLD)

func _draw_slip() -> void:
	var r := Rect2(190, 80, 260, 200)
	draw_rect(r, PAPER)
	draw_rect(r, INK, false, 1.0)
	var y := 88.0
	PixelFont.draw_centered(self, 320, y, "AIRSTRIP 7 - TIME SLIP", INK, 1)
	y += 12
	var cols := [282.0, 372.0]
	PixelFont.draw(self, Vector2(cols[0], y), "LEFT", INK)
	PixelFont.draw(self, Vector2(cols[1], y), "RIGHT", INK)
	y += 10
	var rows := [["DIAL", "dial"], ["R/T", "rt"], ["60'", "sixty"], ["330'", "three30"], ["1/8 ET", "et"], ["KM/H", "kmh"]]
	for row in rows:
		PixelFont.draw(self, Vector2(200, y), String(row[0]), INK)
		for i in 2:
			var v: float = lanes[i][row[1]]
			var s := "%.3f" % v if row[1] in ["rt"] else ("%.2f" % v if row[1] != "kmh" else "%d" % int(v))
			if row[1] == "rt" and bool(lanes[i].red): s = "RED"
			if v < 0.0 and row[1] != "rt": s = "--"
			PixelFont.draw(self, Vector2(cols[i], y), s, INK if not (row[1] == "rt" and bool(lanes[i].red)) else RED)
		y += 11
	y += 4
	PixelFont.draw(self, Vector2(200, y), String(lanes[0].name), INK)
	y += 10
	var win := int(result.get("lane", 0)) == 1
	PixelFont.draw_centered(self, 320, y + 6, "YOU WIN" if win else "YOU LOSE", GREEN.darkened(0.3) if win else RED, 2)
	PixelFont.draw_centered(self, 320, y + 26, String(result.get("why", "")), INK)
	var next := "RUN IT BACK" if not win else ("NEXT RACER" if rung < Jobs.LADDER.size() - 1 or not drive.save.get("airstrip_king", false) else "RUN IT BACK")
	PixelFont.draw_centered(self, 320, 268, Hints.fmt("{ui_accept}: %s  {ui_cancel}: LEAVE" % next), INK)


## The car in the other lane: its own CarSim, held on the line until its green plus its
## reaction time, then a clean launch, kept straight in its lane.
class DragRacer extends Node2D:
	var sim: CarSim
	var view: CarView
	var go_at := 999.0
	var rt := 0.2
	var cap := 1.0
	var braking := false
	var _th := 0.6
	var lane_y := 0.0

	var _acc := 0.0
	var _launched := false

	func setup(spec: Dictionary, at: Vector2, throttle_cap: float, reaction: float, visible_car := true) -> void:
		sim = CarSim.new(spec)
		sim.set_ambient(18.0)
		sim.cold_start()
		sim.coolant_c = 88.0
		sim.oil_c = 95.0
		sim.assist = CarSim.Assist.STREET
		for i in 4: sim.tires[i].temp = float(CarSim.COMPOUND[sim.compound].opt)
		sim.pos = at
		sim.heading = 0.0
		lane_y = at.y
		cap = throttle_cap
		rt = reaction
		if visible_car:
			view = CarView.new()
			view.art = CarArt.new(spec, Color(String(spec.get("paint", "#c8342c"))), 0.0, 9)
			add_child(view)
		position = at * CarArt.PX

	func tick(dt: float, now: float) -> void:
		if now < go_at:
			return                                   # sitting on the line, revving
		if not _launched:
			_launched = true
			sim.w_eng = maxf(sim.w_eng, DragStrip.LAUNCH_RPM / CarSim.RPM)
		# fixed 60 Hz steps so a race runs the same as the ET the dial-in came from
		_acc += dt
		while _acc >= 1.0 / 60.0:
			_acc -= 1.0 / 60.0
			var h := 1.0 / 60.0
			var th := 0.0
			var br := 0.0
			if not braking:
				_th = clampf(_th + (3.0 * h if sim.drive_slip() < 1.2 else -8.0 * h), 0.25, 1.0)
				th = minf(_th, cap)
			else:
				br = 0.8
			sim.step(h, th, br, 0.0, 0.0)
			sim.vy = 0.0
			sim.yaw_rate = 0.0
			sim.heading = 0.0
			sim.pos.y = lane_y
		position = sim.pos * CarArt.PX
		if view:
			view.heading = 0.0
			view.braking = braking

	func sort_point() -> Vector2:
		return global_position
