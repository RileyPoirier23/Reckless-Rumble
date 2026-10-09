## Street races and the police, run inside the drive scene:
##   godot --headless --path game -- --race-test
## The AI racers have to get round a real route through traffic without getting lost or stuck;
## a race pays out (or doesn't) the way Marco says; a patrol car spots a speeder, pulls them
## over and writes the ticket; a chase can be lost; high heat gets the car impounded.
extends Node

var main: Node
var fails := 0
var _t0 := 0.0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _ready() -> void:
	Engine.time_scale = 4.0
	main.sky.time_h = 23.0
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.save.cash = 2000
	main.save.heat = 0.0
	if not OS.get_cmdline_user_args().has("--police-only"):
		await _race_ai()
	if OS.get_cmdline_user_args().has("--race-only"):
		print("%d failed" % fails)
		get_tree().quit()
		return
	if not OS.get_cmdline_user_args().has("--police-only"): await _race_win()
	await _police_ticket()
	await _police_lose()
	await _police_impound()
	print("%d failed" % fails)
	Engine.time_scale = 1.0
	get_tree().quit()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, true, false).timeout

func _start(route_i: int) -> StreetRace:
	var j: JobRunner = main.jobs
	j.start("street")
	j.race_route = StreetRace.ROUTES[route_i]
	j.race_start = StreetRace.build_path(main.world.map, j.race_route)[0]
	main._teleport(j.race_start, 0.0)
	j.sign_in()
	return j.race

## Three AI racers round the Downtown Box, twice, with traffic; you sit it out.
func _race_ai() -> void:
	var cash0 := int(main.save.cash)
	var race := _start(1)
	check("street race: signing in takes the buy-in", int(main.save.cash) == cash0 - 300, "$%d -> $%d" % [cash0, int(main.save.cash)])
	check("street race: three racers on the grid", race.racers.size() == 3)
	await _wait(0.2)
	check("street race: nobody moves before the lights", race.holding() and main.car.locked)
	var grid0: Array = []
	for a in race.racers: grid0.append(a.sim.pos)
	await _wait(2.8)
	var crept := 0.0
	for i in race.racers.size(): crept = maxf(crept, race.racers[i].sim.pos.distance_to(grid0[i]))
	check("street race: the grid holds still", crept < 1.0, "%.1f m" % crept)
	await _wait(1.5)
	check("street race: lights out", race.racing())
	# park yourself off the road so the field has the track
	main._teleport(Vector2(5570, 1566), -PI / 2.0)
	var off_max := 0.0
	var stuck := [0.0, 0.0, 0.0]
	var stuck_max := 0.0
	var t := 0.0
	var first := -1.0
	while t < 420.0 and race.state == "race":
		await _wait(0.5)
		t += 0.5
		for i in race.racers.size():
			var a: AiCar = race.racers[i]
			if race.finish_t.has(i): continue
			var off := a.track.off_line(a.sim.pos)
			if off > 20.0 and off_max <= 20.0:
				var best := INF
				for q in a.track.pts.size() - 1: best = minf(best, MapData.seg_dist(a.sim.pos, a.track.pts[q], a.track.pts[q + 1]))
				print("   off the line: %s (%s) at %s seg %d/%d, %.1f m from its segment, %.1f from the nearest, %.1f m/s, damage %s" % [race.info[i].name, race.info[i].car, str(a.sim.pos.round()), a.track.seg, a.track.pts.size(), off, best, a.sim.speed(), str(a.damage)])
				for ln in a.trace: print("      ", ln)
			off_max = maxf(off_max, off)
			stuck[i] = stuck[i] + 0.5 if a.sim.speed() < 1.0 else 0.0
			stuck_max = maxf(stuck_max, stuck[i])
			if stuck[i] == 6.0:
				print("   stuck: %s at %s gear %d seg %d/%d off %.1f target %.1f m/s back %.1f in %s slip %.1f pass %.1f hit %s surface %s" % [race.info[i].name, str(a.sim.pos.round()), a.sim.gear, a.track.seg, a.track.pts.size(), a.track.off_line(a.sim.pos), a.target_v, a._back_t, str(a.last_in), a.sim.drive_slip(), a._pass, (a.last_hit.get_class() + ":" + str(a.last_hit.get_script().get_global_name() if a.last_hit.get_script() else "")) if is_instance_valid(a.last_hit) else "-", a.sim.surface])
				if stuck_max <= 6.0:
					for ln in a.trace.slice(-25): print("      ", ln)
				for tc in main.traffic.cars:
					if tc.pos.distance_to(a.sim.pos) < 12.0: print("      traffic %s %s v%.1f rule %s lead %s" % [tc.state, str(tc.pos.round()), tc.v, tc.last_rule, str(tc.lead_obj)])
				for o in race.racers:
					if o != a and o.sim.pos.distance_to(a.sim.pos) < 12.0: print("      racer at %s" % str(o.sim.pos.round()))
		if first < 0.0 and not race.finish_t.is_empty(): first = race.clock
	var lap_len := race.total / 2.0
	print("   downtown box: lap %.0f m, winner %.1f s, finished %d/3, off-line max %.1f m, stuck max %.1f s" % [lap_len, first, race.finish_t.size(), off_max, stuck_max])
	check("street race: somebody wins the Downtown Box", first > 0.0, "%.1f s" % first)
	check("street race: the winner averages a racer's pace", first > 0.0 and race.total / first > 11.0, "%.1f m/s" % (race.total / maxf(first, 1.0)))
	var least := 1.0
	for a in race.racers: least = minf(least, a.track.dist / race.total)
	check("street race: the whole field gets most of the way round", least >= 0.75, "%d finished, the last %.0f%% of the way" % [race.finish_t.size(), least * 100.0])
	check("street race: racers stay on the route", off_max < 16.0, "%.1f m" % off_max)
	check("street race: nobody's stuck for long", stuck_max < 12.0, "%.1f s" % stuck_max)
	check("street race: sitting it out is a DNF", race.state == "done" and race._winnings() == 0)
	await _wait(8.0)
	check("street race: the night ends and the field goes home", not main.jobs.active() and main.jobs.race == null)
	check("street race: it goes in the save", int(main.save.get("street", {}).get("races", 0)) >= 1)

## The Main Street Mile, where you hit every checkpoint first.
func _race_win() -> void:
	var race := _start(0)
	var cash0 := int(main.save.cash)
	await _wait(4.3)
	var skipped_ok := true
	# try the last checkpoint first: it shouldn't count
	main._teleport(race.track.point_at(race.total), 0.0)
	await _wait(0.3)
	skipped_ok = race.check_i == 0
	for i in race.checks.size():
		var s: float = race.checks[i]
		var p := race.track.point_at(s)
		var d := race.track.dir_at(s)
		main._teleport(p - d * 3.0, d.angle())
		await _wait(0.25)
		main._teleport(p + d * 1.0, d.angle())
		await _wait(0.25)
	check("street race: checkpoints only count in order", skipped_ok)
	check("street race: you finish when you've been through them all", race.finish_t.has(-1), "%d/%d" % [race.check_i, race.checks.size()])
	check("street race: first is first", race.place() == 1, "P%d" % race.place())
	await _wait(9.0)
	var purse := StreetRace.purse(150, 4)
	check("street race: the winner gets the pot less Marco's tenth", int(main.save.cash) == cash0 + purse, "$%d -> $%d (+%d)" % [cash0, int(main.save.cash), purse])
	main.police.clear()

func _cruiser_behind(dist: float) -> AiCar:
	var map: MapData = main.world.map
	# St George Blvd, heading east
	var at := Vector2(5800, 1390) + Vector2(5.5, 2.5)
	main._teleport(at + Vector2(dist, 0), 0.0)
	var k: AiCar = main.police.spawn_at(at, 0.0)
	k.set_path(PackedVector2Array([at, at + Vector2(400, 0)]))
	return k

## Doing 100 in a 50 past a patrol car, then pulling over.
func _police_ticket() -> void:
	var p: Police = main.police
	p.enabled = true
	main.save.heat = 0.0
	var cash0 := int(main.save.cash)
	var k := _cruiser_behind(30.0)
	main.car.sim.vx = 28.0
	await _wait(1.0)
	check("police: a patrol car lights up a speeder", p.state == "stop" and k.siren, "%s, %s" % [p.state, str(p.offences)])
	# you pull over
	main.hold_car = true
	var t := 0.0
	var tickets0 := int(main.save.get("tickets", 0))
	while t < 30.0 and int(main.save.get("tickets", 0)) == tickets0:
		await _wait(0.25)
		t += 0.25
	if int(main.save.get("tickets", 0)) == tickets0:
		print("   no ticket: state %s, you at %s doing %.1f, cop at %s doing %.1f, want %.1f, bust_t %.1f, siren %s, path %d pts done %s" % [p.state, str(main.car.sim.pos.round()), main.car.sim.speed(), str(k.sim.pos.round()), k.sim.speed(), k.target_v, p.bust_t, str(k.siren), k.track.pts.size(), str(k.track.done)])
		for ln in k.trace.slice(-12): print("      ", ln)
	var paid := cash0 - int(main.save.cash)
	check("police: pull over and it's a ticket", int(main.save.get("tickets", 0)) == tickets0 + 1, "%.1f s" % t)
	check("police: the ticket is for the speeding", paid >= 100 and paid < 1000, "$%d" % paid)
	check("police: a ticket isn't the impound", main.car.sim.pos.distance_to(Jobs.IMPOUND) > 100.0)
	check("police: they stand down after", p.state == "calm" and not k.siren)
	await _wait(3.5)
	main.hold_car = false
	p.clear()

## A chase you get out of: far enough away, long enough, they lose you.
func _police_lose() -> void:
	var p: Police = main.police
	main.save.heat = 30.0
	var k := _cruiser_behind(40.0)
	p._light_up(k, "speeding", 40.0)
	p.state = "chase"
	p.offences.append("fleeing")
	await _wait(1.0)
	main._teleport(Vector2(6500, 1300), 0.0)        # out in Dieppe
	var t := 0.0
	while t < 40.0 and p.chasing():
		await _wait(0.5)
		t += 0.5
	check("police: get far enough away and they lose you", not p.chasing(), "%.1f s" % t)
	check("police: losing them keeps the heat", p.heat() > 20.0, "%.0f" % p.heat())
	p.clear()

## When the heat's up, the car goes to the impound lot.
func _police_impound() -> void:
	var p: Police = main.police
	main.save.heat = 80.0
	var cash0 := int(main.save.cash)
	var k := _cruiser_behind(25.0)
	p._light_up(k, "speeding", 30.0)
	main.car.sim.vx = 0.0
	main.hold_car = true
	var t := 0.0
	while t < 30.0 and p.chasing():
		await _wait(0.25)
		t += 0.25
	check("police: high heat, stopped, it's the impound", main.car.sim.pos.distance_to(Jobs.IMPOUND) < 5.0, "%.0f m away" % main.car.sim.pos.distance_to(Jobs.IMPOUND))
	check("police: the impound fee is on the bill", cash0 - int(main.save.cash) >= Police.IMPOUND_FEE)
	check("police: the heat drops after", p.heat() <= 10.0, "%.0f" % p.heat())
	main.hold_car = false
	p.clear()
