## Street races and the police, run inside the drive scene:
##   godot --headless --path game -- --race-test
## The AI racers have to get round a real route through traffic without getting lost or stuck;
## a race pays out (or doesn't) the way Marco says; a patrol car spots a speeder, pulls them
## over and writes the ticket; a chase can be lost; high heat gets the car impounded.
extends Node

var main: Node
var fails := 0
var done := 0                  # sections that ran to the end (a script error mid-way stops one short)
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
	await _wildlife()
	if not OS.get_cmdline_user_args().has("--police-only"): await _pinks()
	await _ride()
	var want := 8 if not OS.get_cmdline_user_args().has("--police-only") else 5
	check("every part of the test ran to the end", done == want, "%d of %d" % [done, want])
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
	check("street race: nobody's stuck for long", stuck_max < 15.0, "%.1f s" % stuck_max)
	check("street race: sitting it out is a DNF", race.state == "done" and race._winnings() == 0)
	await _wait(8.0)
	check("street race: the night ends and the field goes home", not main.jobs.active() and main.jobs.race == null)
	check("street race: it goes in the save", int(main.save.get("street", {}).get("races", 0)) >= 1)
	done += 1

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
	done += 1

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
	done += 1

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
	done += 1

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
	done += 1

## A moose in the road at highway speed is the end of you; a deer at town speed is a bent bumper;
## the horn moves a deer along.
func _wildlife() -> void:
	var w: Wildlife = main.wildlife
	w.enabled = true
	main.sky.time_h = 19.0
	var map: MapData = main.world.map
	var rd: Dictionary = map.nearest_road(Vector2(4490, 1369), 30.0)       # Lutes Mountain Rd, out in the country
	check("the wildlife test has a country road", not rd.is_empty())
	if rd.is_empty(): return
	var dir: Vector2 = rd.dir
	var died: Array = []
	var catch_it := func(info: Dictionary): died.append(info)
	var c: PlayerCar = main.car
	c.fatal.disconnect(main._on_fatal)
	c.fatal.connect(catch_it)
	c.can_die = true
	# the moose
	main._teleport(rd.point - dir * 70.0, dir.angle())
	await _wait(0.3)
	var moose := w.spawn_at("moose", rd.point, dir.angle() + PI / 2.0)
	moose.state = "stand"
	c.sim.vx = 22.5
	var t := 0.0
	while t < 6.0 and died.is_empty():
		c.sim.vx = maxf(c.sim.vx, 22.0)
		await get_tree().physics_frame
		t += 1.0 / 60.0
	check("a moose in the road at 80 is the end of you", not died.is_empty() and String(died[0].cause) == "moose", str(died[0].cause) if not died.is_empty() else "drove on")
	c.dead = false
	for k in c.damage: c.damage[k] = 0.0
	w.clear()
	# the deer
	died.clear()
	main._teleport(rd.point - dir * 40.0, dir.angle())
	await _wait(0.3)
	var deer := w.spawn_at("deer", rd.point, dir.angle() + PI / 2.0)
	deer.state = "stand"
	t = 0.0
	while t < 5.0 and deer.state == "stand":
		c.sim.vx = maxf(c.sim.vx, 14.0)
		await get_tree().physics_frame
		t += 1.0 / 60.0
	await _wait(0.3)
	check("a deer at 50 bends the car, not you", died.is_empty() and float(c.damage.front) > 0.0 and deer.state == "hurt", "damage %.2f, deer %s" % [float(c.damage.front), deer.state])
	w.clear()
	# the horn
	main._teleport(rd.point - dir * 60.0, dir.angle())
	main.hold_car = true
	await _wait(0.3)
	var shy := w.spawn_at("deer", rd.point + Vector2(-dir.y, dir.x) * 9.0, dir.angle() - PI / 2.0)
	Input.action_press("horn")
	await _wait(0.6)
	Input.action_release("horn")
	check("the horn sends a deer back into the trees", shy.state in ["flee", "gone"], shy.state)
	main.hold_car = false
	w.clear()
	c.fatal.disconnect(catch_it)
	c.fatal.connect(main._on_fatal)
	w.enabled = false
	done += 1

## Pink slips: win and the rival's car is in your garage; lose and yours is in theirs.
func _pinks() -> void:
	var j: JobRunner = main.jobs
	main.save.street = { "races": 5, "wins": 5, "rep": 6, "pinks": 0 }
	main.sky.day = 4                    # a Friday
	main.sky.time_h = 23.0
	var cars0 := (main.save.garage as Array).size()
	j.start("street")
	check("pinks: Friday night with the rep, it's pink slips", not j.race_rival.is_empty(), str(j.race_rival.get("name", "")))
	main._teleport(j.race_start, 0.0)
	await _wait(0.2)
	check("pinks: you're racing for your own car", j.sign_in() and j.race != null and j.race.racers.size() == 1)
	var race: StreetRace = j.race
	await _wait(4.3)
	for i in race.checks.size():
		var s: float = race.checks[i]
		var p := race.track.point_at(s)
		var d := race.track.dir_at(s)
		main._teleport(p - d * 3.0, d.angle())
		await _wait(0.25)
		main._teleport(p + d * 1.0, d.angle())
		await _wait(0.25)
	await _wait(9.0)
	var g: Array = main.save.garage
	check("pinks: win and their car is in your garage", g.size() == cars0 + 1 and bool((g[g.size() - 1] as Dictionary).get("pinks", false)), "%d -> %d cars" % [cars0, g.size()])
	check("pinks: two rep for it, and the next rival's up", int(main.save.street.rep) == 8 and int(main.save.street.pinks) == 1, str(main.save.street))
	# now lose one
	var lose_id := String(main.car.spec.get("id", ""))
	var n0 := g.size()
	j.start("street")
	main._teleport(j.race_start, 0.0)
	await _wait(0.2)
	j.sign_in()
	race = j.race
	await _wait(4.3)
	main._teleport(Vector2(5570, 1566), -PI / 2.0)          # you sit it out; they don't
	var t := 0.0
	while t < 260.0 and j.race != null:
		await _wait(1.0)
		t += 1.0
	check("pinks: lose and your car's gone, and you're home in another", (main.save.garage as Array).size() == n0 - 1 and main.car != null and main.car_i >= 0 and main.car.sim.pos.distance_to(main.START) < 5.0, "%d -> %d cars, lost the %s" % [n0, (main.save.garage as Array).size(), lose_id])
	main.save.street = { "races": 0, "wins": 0, "rep": 0 }
	main.police.clear()
	done += 1

## A HOPP-IN ride, start to finish: a request comes in, you pick them up, you drop them off.
func _ride() -> void:
	var j: JobRunner = main.jobs
	main.save.erase("rides")
	main.sky.time_h = 14.0
	main._teleport(Vector2(5570, 1566), -PI / 2.0)
	j.start("ride")
	var t := 0.0
	while t < 12.0 and j.stage != "pickup":
		await _wait(0.5)
		t += 0.5
	check("rides: a request comes in", j.stage == "pickup" and not j.rider.is_empty(), j.stage)
	if j.stage != "pickup":
		j.finish(false)
		return
	main._teleport(j.rider.from, 0.0)
	await _wait(0.6)
	check("rides: they get in", j.stage == "ride", j.stage)
	var cash0 := int(main.save.cash)
	var fare := int(j.rider.fare)
	main._teleport(j.rider.to, 0.0)
	await _wait(0.6)
	check("rides: dropped off, paid the fare and a tip", j.runs == 1 and int(main.save.cash) >= cash0 + fare, "$%d -> $%d (fare $%d)" % [cash0, int(main.save.cash), fare])
	check("rides: it goes on your rating", int(main.save.get("rides", {}).get("count", 0)) == 1)
	j.finish(true)
	done += 1
