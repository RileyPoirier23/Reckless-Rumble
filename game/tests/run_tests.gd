## Headless tests for the driving sim:  godot --headless --path game -s tests/run_tests.gd
extends SceneTree

var fails := 0

func car(season_surface := "dry", ambient := 20.0) -> CarSim:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	var c := CarSim.new(spec)
	c.set_ambient(ambient)
	c.cold_start()
	c.surface = season_surface
	# warm it up so tests that aren't about the cold don't trip the cold-engine wear
	c.coolant_c = 90.0
	c.oil_c = 95.0
	return c

func check(name: String, ok: bool, detail: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + name + "  (" + detail + ")")
	if not ok: fails += 1

func run(c: CarSim, secs: float, th: float, br := 0.0, st := 0.0, hb := 0.0) -> void:
	var n := int(secs * 120.0)
	for i in n: c.step(1.0 / 120.0, th, br, st, hb)

## brake to a stop and measure (not the reverse that follows holding the brake)
func stop_distance(c: CarSim) -> float:
	var start := c.pos
	var n := 0
	while c.vx > 0.3 and n < 120 * 40:
		c.step(1.0 / 120.0, 0.0, 1.0, 0.0, 0.0)
		n += 1
	return c.pos.distance_to(start)

func _init() -> void:
	# 1. 0-100 km/h, automatic, dry
	var c := car()
	var t := 0.0
	while c.vx < 100.0 / 3.6 and t < 30.0:
		c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
		t += 1.0 / 120.0
	check("0-100 km/h is believable", t > 5.0 and t < 9.5, "%.2f s" % t)
	# 2. top speed
	run(c, 60.0, 1.0)
	check("top speed is believable", c.vx * 3.6 > 190.0 and c.vx * 3.6 < 260.0, "%d km/h, gear %d, %d rpm" % [int(c.vx * 3.6), c.gear, int(c.rpm)])
	check("full-throttle run didn't hurt a healthy engine", c.engine_health > 0.97, "health %.3f" % c.engine_health)
	# 3. money shift: 130 km/h, manual, into 1st
	c = car()
	c.auto_gearbox = false
	c.gear = 1
	var guard := 0
	for g in range(1, 5):
		guard = 0
		while c.rpm < 6600.0 and guard < 3600:
			c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
			guard += 1
		c.shift(g + 1)
	guard = 0
	while c.vx < 130.0 / 3.6 and guard < 6000:
		c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
		guard += 1
	print("  (money shift from %d km/h in gear %d)" % [int(c.vx * 3.6), c.gear])
	c.shift(1)
	run(c, 1.5, 0.0)
	check("money shift bends valves", c.valves_bent and c.engine_health < 0.6, "health %.2f, bent %s" % [c.engine_health, c.valves_bent])
	# 4. burnout eats the rear tread (line lock: front brake, rear free)
	c = car()
	run(c, 10.0, 1.0, 1.0)
	var rear: float = c.tires[2].tread
	var front: float = c.tires[0].tread
	check("10 s burnout eats rear tread", rear < 6.5 and front > 7.9, "rear %.2f mm, front %.2f mm, rear temp %d°C" % [rear, front, int(c.tires[2].temp)])
	check("the car stays put during the burnout", c.pos.length() < 1.5, "moved %.2f m" % c.pos.length())
	# 5. holed radiator: sit at high rpm, it cooks the head gasket
	c = car("dry", 30.0)
	c.radiator = 0.25
	c.coolant_level = 0.5
	c.gear = 0
	c.auto_gearbox = false
	run(c, 240.0, 0.55)
	check("holed radiator + high revs blows the head gasket", c.head_gasket, "coolant %d°C, health %.2f" % [int(c.coolant_c), c.engine_health])
	# 6. healthy car idling in summer doesn't overheat
	c = car("dry", 30.0)
	run(c, 300.0, 0.0)
	check("healthy car idles cool", c.coolant_c < 105.0 and not c.head_gasket, "coolant %d°C" % int(c.coolant_c))
	# 7. revving a cold engine wears it
	c = car("dry", -15.0)
	c.cold_start()
	c.gear = 0
	c.auto_gearbox = false
	run(c, 20.0, 0.8)
	check("revving a cold engine wears it", c.engine_health < 0.995, "health %.4f, oil %d°C" % [c.engine_health, int(c.oil_c)])
	# 8. stopping distance: dry vs snow vs ice (summer tires), from 80 km/h
	var dist := {}
	for s in ["dry", "snow", "ice"]:
		c = car(s, 0.0 if s != "dry" else 20.0)
		c.vx = 80.0 / 3.6
		c.w_wheel = c.vx / 0.31
		c.gear = 3
		dist[s] = stop_distance(c)
	check("snow and ice stop far longer than dry", dist.dry < 40.0 and dist.snow > dist.dry * 1.8 and dist.ice > dist.snow * 1.8, "dry %.1f m, snow %.1f m, ice %.1f m" % [dist.dry, dist.snow, dist.ice])
	# 9. winter tires stop shorter on snow than summer tires
	c = car("snow", -5.0)
	c.compound = "winter"
	c.vx = 80.0 / 3.6
	c.w_wheel = c.vx / 0.31
	c.gear = 3
	var winter_d := stop_distance(c)
	check("winter tires stop shorter on snow", winter_d < dist.snow * 0.8, "winter %.1f m vs summer %.1f m" % [winter_d, dist.snow])
	# 10. steady cornering: turn the wheel at 50 km/h and the car turns right, without spinning
	c = car()
	c.vx = 50.0 / 3.6
	c.w_wheel = c.vx / 0.31
	c.gear = 3
	run(c, 3.0, 0.3, 0.0, 0.3)
	check("steering right turns right without spinning", c.heading > 0.5 and absf(c.vy) < 2.0, "heading %.2f rad, slide %.2f m/s" % [c.heading, c.vy])
	# 10b. lifting mid-corner at the limit: it may slide, but it shouldn't swap ends
	c = car()
	c.vx = 60.0 / 3.6
	c.w_wheel = c.vx / 0.31
	c.gear = 3
	run(c, 2.0, 0.0, 0.0, 0.6)
	check("lift-off at the limit doesn't spin it around", absf(atan2(c.vy, c.vx)) < 1.0, "slip angle %.2f rad" % atan2(c.vy, c.vx))
	# 11. handbrake at speed with steering kicks the rear out (drift)
	c = car()
	c.vx = 60.0 / 3.6
	c.w_wheel = c.vx / 0.31
	c.gear = 3
	run(c, 0.6, 0.6, 0.0, 0.7, 1.0)
	var slide := atan2(c.vy, c.vx)
	check("handbrake turn slides the rear out", absf(slide) > 0.2, "slip angle %.2f rad" % slide)
	# 12. stop at a light, then go again (the clutch must not stall the engine)
	c = car()
	run(c, 3.0, 1.0)
	stop_distance(c)
	run(c, 0.5, 0.0)
	var idle_rpm := c.rpm
	run(c, 4.0, 1.0)
	check("stop, idle, and pull away again", idle_rpm > 600.0 and c.vx * 3.6 > 40.0, "idle %d rpm, then %d km/h" % [int(idle_rpm), int(c.vx * 3.6)])
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
