## What the cars run into that isn't a car: godot --headless --path game -- --collide-audit
## Six AI drivers go round the street race routes with the traffic for a couple of minutes
## (CA_SECS), and every solid thing one of them hits is listed by what it was and where.
extends Node

var main: Node
var cars: Array = []
var t := 0.0
var secs := 150.0
var done := false
var spin := SpinWatch.new()
var _spin_t := 0.0
var circles: Array = []

func _ready() -> void:
	if OS.get_environment("CA_SECS") != "": secs = float(OS.get_environment("CA_SECS"))
	Engine.time_scale = 3.0
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 14.0
	main.hold_car = true
	main.car.collision_layer = 0
	PlayerCar.hit_log = []
	PlayerCar.log_hits = true
	var ids := ["fjord_crown_victorious_2005", "chevrolay_expresso_2010", "fjord_transitory_2016", "hunda_civil_2004", "toyoda_corolla_2009", "dodgy_caravan_2008"]
	for i in mini(6, StreetRace.ROUTES.size()):
		var r: Dictionary = StreetRace.ROUTES[i]
		var path := StreetRace.build_path(main.world.map, r)
		if path.size() < 2: continue
		var k := AiCar.new()
		main.ysort.add_child(k)
		var id: String = ids[i % ids.size()]
		var spec := SaveGame.load_spec(id)
		if spec.is_empty(): spec = SaveGame.load_spec("fjord_crown_victorious_2005")
		spec.name = "AUDIT %d" % i
		k.name = "audit_%d_%s" % [i, String(r.get("name", ""))]
		k.setup_ai(spec, main.world, main.skids, main.hud, path[0], (path[1] - path[0]).angle(), 60 + i)
		k.set_path(path, bool(r.loop))
		k.traffic = main.traffic
		k.limits = true
		k.skill = 0.75
		main.traffic.extra.append(k)
		cars.append(k)
	main._teleport(cars[0].sim.pos + Vector2(0, 8), 0.0)
	# the lead car stands in for you: traffic gets out of its way, turns round at dead ends near it
	main.traffic.player = cars[0]
	main.traffic.ignore_player = false
	print("audit: %d cars on %d routes" % [cars.size(), StreetRace.ROUTES.size()])

func _process(dt: float) -> void:
	if done: return
	t += dt
	# the world follows the first car (chunks, traffic, parked cars), the rest drive what's loaded
	main.cam.global_position = cars[0].global_position
	main.world.update_view(cars[0].sim.pos, Vector2(60, 40))
	_spin_t += dt
	if _spin_t >= 0.25:
		_spin_t = 0.0
		for c in main.traffic.cars:
			var r := spin.note(c.get_instance_id(), c.pos, c.heading, t, "traffic (%s, a%d b%d next%d rule %s turn %.2f v%.1f)" % [c.state, c.a, c.b, c.c_next, c.last_rule, c.turn_ahead, c.v])
			if r != "":
				var map: MapData = main.world.map
				r += "\n      a%d %s b%d %s next%d %s | s %.1f lane_i %d pull %.2f evade %.2f boxes %s junction %s\n      path %s\n      ahead %s" % [c.a, map.g_pos[c.a], c.b, map.g_pos[c.b], c.c_next, map.g_pos[c.c_next] if c.c_next >= 0 else Vector2.ZERO, c.s, c.lane_i, c.pull, c.evade, str(c.boxes), str(main.traffic.junctions.get(c.b, {}).get("control", "-")), str(c._path), "-"]
				circles.append(r)
		for k in cars:
			var r2 := spin.note(k.get_instance_id(), k.sim.pos, k.sim.heading, t, k.name)
			if r2 != "": circles.append(r2)
		for k in main.police.cruisers:
			var r3 := spin.note(k.get_instance_id(), k.sim.pos, k.sim.heading, t, "cruiser")
			if r3 != "": circles.append(r3)
	if t < secs: return
	done = true
	var by := {}
	for h in PlayerCar.hit_log:
		var key: String = h[1]
		if not by.has(key): by[key] = []
		by[key].append(h)
	print("audit: %d hits of things that aren't cars in %.0f s" % [PlayerCar.hit_log.size(), secs])
	for key in by:
		var hs: Array = by[key]
		print("  %s: %d" % [key, hs.size()])
		for h in hs.slice(0, 6): print("     at (%.0f,%.0f) touching (%.0f,%.0f) at %.0f km/h, %s" % [h[0].x, h[0].y, h[2].x, h[2].y, h[3] * 3.6, h[4]])
	for k in cars: print("  %s drove %.0f m, now at (%.0f,%.0f) %.0f km/h" % [k.name, k.track.dist, k.sim.pos.x, k.sim.pos.y, k.sim.speed() * 3.6])
	for r in circles: print("  CIRCLES: ", r)
	var fails := circles.size()
	for key in by:
		if not String(key).begins_with("TrafficCar"): fails += 1
	print("%d failed" % fails)
	get_tree().quit()
