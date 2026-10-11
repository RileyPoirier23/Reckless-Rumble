## The story missions' objective kinds, run inside the drive scene: a stop, a drag run with the
## tree (a red light, a medal), a race (win it, lose it and go back), a gentle leg (a hit starts
## it over), a chase. godot --path game -- --mission-test
extends Node

var main: Node
var fails := 0
var done := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _ready() -> void:
	Engine.time_scale = 3.0
	main.traffic.enabled = false
	main.police.enabled = false
	main.wildlife.enabled = false
	_run()

## Start a mission the way the story does, with the step set so the runner's flags land.
func _start(id: String) -> void:
	StoryState.new_game()
	StoryState.active = true
	for k in StoryScript.STEPS.size():
		var st: Dictionary = StoryScript.STEPS[k]
		if st.type == "drive" and String(st.mission) == id: StoryState.step = k
	if main.mission != null:
		main.mission.queue_free()
		main.mission = null
	main._start_mission(StoryMissions.MISSIONS[id])
	main.hold_car = false

## Hold the mission open once it's done (so the runner doesn't change the scene on us).
func _finished() -> bool:
	if main.mission != null and main.mission.done:
		main.mission._end_t = 1.0e9
		return true
	return false

## Wait for the mission to finish (holding it open the moment it does), up to `secs`.
func _until_done(secs: float) -> void:
	var t := 0.0
	while t < secs and not _finished():
		await _wait(0.05)
		t += 0.05

func _park_at(p: Vector2) -> void:
	main._teleport(p, 0.0)
	main.car.sim.vx = 0.0

func _run() -> void:
	await _wait(1.0)
	await _stop_leg()
	await _drag()
	await _race()
	await _gentle()
	await _chase()
	await _handover()
	check("every part of the test ran to the end", done == 6, "%d of 6" % done)
	print("%d failed" % fails)
	Engine.time_scale = 1.0
	StoryState.active = false
	get_tree().quit(1 if fails > 0 else 0)

# ------------------------------------------------------------------ a stop

func _stop_leg() -> void:
	_start("gus_heart")
	await _wait(0.5)
	check("a mission starts in its car, at its start, with its objective up", String(main.car.spec.id) == "silvio" and main.hud.objective != "", String(main.car.spec.id))
	_park_at(StoryMissions.GENERAL)
	await _until_done(3.0)
	check("stop at the place and the objective's done", _finished())
	done += 1

# ------------------------------------------------------------------ Dom's eighth-mile

func _drag() -> void:
	_start("launch_control")
	await _wait(0.5)
	_park_at(StoryMissions.AIRSTRIP)
	var r: StoryMissions.MissionRunner = main.mission
	var t1 := 0.0
	while r.k < 1 and t1 < 3.0:
		await _wait(0.05)
		t1 += 0.05
	await _wait(0.1)
	check("drag: the first leg done, the car's on the line", r.k == 1 and main.car.sim.pos.distance_to(StoryMissions.RUNWAY_LINE) < 4.0, "leg %d, %.0f m off the line, tree %.1f s, %.1f m/s" % [r.k, main.car.sim.pos.distance_to(StoryMissions.RUNWAY_LINE), r._go_t, main.car.sim.speed()])
	# jump the tree: rolling before green is a red light, and it's back to the line
	await _wait(0.3)
	main.car.sim.vx = 5.0
	await _wait(0.5)
	check("drag: go before green and it's a red light (back on the line, the tree again)", r._go_t < 2.0 and main.car.sim.pos.distance_to(StoryMissions.RUNWAY_LINE) < 4.0, "tree %.1f s" % r._go_t)
	# then sit still through the tree and run it flat out
	main.car.sim.vx = 0.0
	# the tree again: the red light's reset is a frame behind the check, so wait for green itself
	var tw := 0.0
	while r._go_t < 2.4 and tw < 10.0:
		main.car.sim.vx = 0.0                     # foot on the brake: an automatic creeps, and creeping is a red light
		await _wait(0.05)
		tw += 0.05
	var t0 := 0.0
	while not _finished() and t0 < 20.0:
		main.car.sim.vx = 30.0
		main.car.sim.heading = (StoryMissions.RUNWAY_END - StoryMissions.RUNWAY_LINE).angle()
		await _wait(0.05)
		t0 += 0.05 * Engine.time_scale
	var medal := ""
	for m in ["gold", "silver", "bronze"]:
		if StoryState.flag("launch_" + m): medal = m
	var along: float = (main.car.sim.pos - StoryMissions.RUNWAY_LINE).dot((StoryMissions.RUNWAY_END - StoryMissions.RUNWAY_LINE).normalized())
	check("drag: past the cones and it's timed: a medal flag for Dom's scene", _finished() and medal != "", "medal %s, %.2f s, %.0f m along, go_t %.1f run_t %.1f, k %d, done %s, %.1f m/s, scale %.2f" % [medal, float(StoryState.last_result.get("eighth", 0.0)), along, r._go_t, r._run_t, r.k, str(r.done), main.car.sim.speed(), Engine.time_scale])
	done += 1

# ------------------------------------------------------------------ Johnny Tram

func _race() -> void:
	_start("johnny_tram")
	await _wait(0.4)
	var r: StoryMissions.MissionRunner = main.mission
	check("race: Johnny's on the line, held for the count", r.target != null and r.target.hold, str(r.target))
	# the count is three seconds of game time (the white-out at the start runs slow)
	var tc := 0.0
	while r._go_t >= 0.0 and tc < 10.0:
		await _wait(0.1)
		tc += 0.1
	check("race: after the count he's off", r.target != null and not r.target.hold, "%.1f s, go_t %.1f" % [tc, r._go_t])
	# he gets there first: it's back to the start, both of you, and the count starts over
	var start: Vector2 = StoryMissions.MISSIONS.johnny_tram.start
	r.target.sim.pos = StoryMissions.BRIDGE
	await _wait(0.3)
	check("race: he gets to the bridge first and it's back to the start, a new count", main.car.sim.pos.distance_to(start) < 6.0 and r.target != null and r.target.hold, "%.0f m from the start, %s" % [main.car.sim.pos.distance_to(start), str(r.target)])
	# you get there first
	await _wait(4.5)
	_park_at(StoryMissions.BRIDGE)
	await _until_done(3.0)
	check("race: get to the bridge first and it's won", _finished())
	done += 1

# ------------------------------------------------------------------ Aries in the car

func _gentle() -> void:
	_start("principals_office")
	await _wait(0.5)
	_park_at(StoryMissions.SCHOOL)
	await _wait(1.0)
	var r: StoryMissions.MissionRunner = main.mission
	check("gentle: picked her up, on to the second leg", r.k == 1, "leg %d" % r.k)
	# drive off a bit, then hit something: back to the school
	main._teleport(StoryMissions.SCHOOL + Vector2(40, 0), 0.0)
	await _wait(0.4)
	main.car.damage.front += 0.3
	await _wait(0.6)
	check("gentle: a hit with her in the car and it's back to where the leg started", main.car.sim.pos.distance_to(StoryMissions.SCHOOL) < 6.0, "%.0f m from the school" % main.car.sim.pos.distance_to(StoryMissions.SCHOOL))
	_park_at(StoryMissions.COVINGTON)
	await _until_done(3.0)
	check("gentle: home without another scratch and it's done", _finished())
	done += 1

# ------------------------------------------------------------------ Hatch up the Mountain

func _chase() -> void:
	StoryState.flags = { "frankie_dead": true }
	_start("the_mountain")
	await _wait(1.5)
	var r: StoryMissions.MissionRunner = main.mission
	check("chase: Hatch's Charjer is on the road ahead", r.target != null and String(r.target.spec.id) == "charjer", str(r.target))
	# sit on his bumper and he's caught
	var t := 0.0
	while not _finished() and t < 12.0:
		if r.target != null:
			main.car.sim.pos = r.target.sim.pos - r.target.sim.forward() * 5.0
			main.car.sim.heading = r.target.sim.heading
			main.car.sim.vx = r.target.sim.speed()
		await _wait(0.05)
		t += 0.05 * Engine.time_scale
	check("chase: stay on his bumper and he's caught", _finished(), "%.1f s" % t)
	done += 1

# ------------------------------------------------------------------ picking up the Charjer

func _handover() -> void:
	_start("detailing")
	await _wait(0.5)
	var r: StoryMissions.MissionRunner = main.mission
	_park_at(StoryMissions.AIRSTRIP)
	var t := 0.0
	while t < 3.0 and r._hand == "":
		await _wait(0.05)
		t += 0.05
	check("handover: stopped at the airstrip, Dom gets out and walks over (no teleporting)", r._hand == "walk" and r._hand_who != null and String(main.car.spec.id) == "silvio" and main.hold_car, r._hand)
	t = 0.0
	while t < 40.0 and r._hand != "":
		await _wait(0.1)
		t += 0.1
	check("handover: the keys change hands and you're in the Charjer, on to the next leg", String(main.car.spec.id) == "charjer" and r.k == 1 and not main.hold_car, "%s leg %d after %.1f s" % [String(main.car.spec.id), r.k, t])
	var left := is_instance_valid(r._hand_car) and String(r._hand_car.spec.get("id", "")) == "silvio" and r._hand_car.sim.pos.distance_to(main.car.sim.pos) < 14.0
	check("handover: your car's left where you got out of it", left)
	done += 1
