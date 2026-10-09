## Drivetrain, ABS and handling tests for the sim:  godot --headless --path game -s tests/physics_tests.gd
extends SceneTree

var fails := 0

func car(drivetrain := "RWD", surface := "dry", id := "silvio") -> CarSim:
	var spec: Dictionary = SaveGame.load_spec(id)
	spec.drivetrain = drivetrain
	var c := CarSim.new(spec)
	c.set_ambient(20.0)
	c.cold_start()
	c.coolant_c = 90.0
	c.oil_c = 95.0
	c.surface = surface
	for i in 4: c.tires[i].temp = float(CarSim.COMPOUND[c.compound].opt)
	return c

func check(name: String, ok: bool, detail: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + name + "  (" + detail + ")")
	if not ok: fails += 1

func run(c: CarSim, secs: float, th: float, br := 0.0, st := 0.0, hb := 0.0) -> void:
	for i in int(secs * 120.0): c.step(1.0 / 120.0, th, br, st, hb)

## Time to 100 km/h (or 30 s), feeding the gas like a good launch.
func zero100(c: CarSim) -> float:
	var t := 0.0
	var th := 0.6
	while c.vx < 100.0 / 3.6 and t < 30.0:
		th = clampf(th + (3.0 / 120.0 if c.drive_slip() < 1.2 else -8.0 / 120.0), 0.25, 1.0)
		c.step(1.0 / 120.0, th, 0.0, 0.0, 0.0)
		t += 1.0 / 120.0
	return t

## Get up to speed in a straight line, then hand back the car.
func rolling(c: CarSim, kmh: float) -> CarSim:
	c.vx = kmh / 3.6
	c.w_wheel = c.vx / float(c.spec.tires.radius)
	c.gear = 3
	c.w_eng = c.w_wheel * c.ratio(3)
	c.clutch_locked = true
	return c

func ok_num(c: CarSim) -> bool:
	for v in [c.vx, c.vy, c.yaw_rate, c.heading, c.pos.x, c.pos.y, c.w_wheel, c.w_eng]:
		if is_nan(float(v)) or is_inf(float(v)): return false
	return true

func _init() -> void:
	# every drivetrain gets off the line and up to speed
	var times := {}
	for d in ["RWD", "FWD", "AWD"]:
		var c := car(d)
		times[d] = zero100(c)
		check("%s reaches 100 km/h" % d, float(times[d]) > 4.0 and float(times[d]) < 12.0 and ok_num(c), "%.2f s" % float(times[d]))
	# on snow, four driven wheels pull away far better than two
	var snow := {}
	for d in ["RWD", "FWD", "AWD"]:
		var c := car(d, "snow")
		run(c, 6.0, 1.0)
		snow[d] = c.vx * 3.6
	check("AWD pulls away best on snow", float(snow.AWD) > float(snow.RWD) * 1.15 and float(snow.AWD) > float(snow.FWD) * 1.1, "AWD %d, FWD %d, RWD %d km/h after 6 s" % [int(snow.AWD), int(snow.FWD), int(snow.RWD)])
	# a front-driver's handbrake turn: the rear locks and comes round
	var fh := rolling(car("FWD"), 50.0)
	run(fh, 0.3, 0.0, 0.0, 0.6, 0.0)
	var slide := 0.0
	for i in 72:
		fh.step(1.0 / 120.0, 0.0, 0.0, 0.6, 1.0)
		slide = maxf(slide, absf(atan2(fh.vy, maxf(fh.vx, 0.1))))
	check("FWD handbrake turn swings the rear out", slide > 0.25, "peak slip angle %.2f rad" % slide)
	# power-on at the limit: the front-driver pushes wide, the rear-driver rotates
	var yaw := {}
	for d in ["RWD", "FWD"]:
		var c := rolling(car(d), 60.0)
		run(c, 2.0, 1.0, 0.0, 0.8)
		yaw[d] = absf(c.heading)
	check("FWD understeers more than RWD under power", float(yaw.FWD) < float(yaw.RWD) * 0.92, "heading change FWD %.2f vs RWD %.2f rad" % [float(yaw.FWD), float(yaw.RWD)])
	# ABS: braking hard while steering on snow still turns the car
	var turned := {}
	for assist in [CarSim.Assist.SIM, CarSim.Assist.STREET]:
		var c := rolling(car("RWD", "snow"), 60.0)
		c.assist = assist
		run(c, 1.5, 0.0, 1.0, 0.7)
		turned[assist] = absf(c.heading)
	check("ABS keeps the steering alive under full brakes", float(turned[CarSim.Assist.STREET]) > float(turned[CarSim.Assist.SIM]) * 1.3, "turned %.2f rad with ABS, %.2f without" % [float(turned[CarSim.Assist.STREET]), float(turned[CarSim.Assist.SIM])])
	# catching a slide: steering into it brings the car back straight
	var caught := {}
	for cs in [false, true]:
		var c := rolling(car("RWD"), 60.0)
		run(c, 0.25, 0.0, 0.0, 0.6, 1.0)
		var h0 := c.heading
		var worst := 0.0
		for i in 180:
			var beta := atan2(c.vy, maxf(c.vx, 0.1))
			c.step(1.0 / 120.0, 0.3, 0.0, clampf(beta / 0.35, -1.0, 1.0) if cs else 0.8, 0.0)
			worst = maxf(worst, absf(atan2(c.vy, maxf(c.vx, 0.1))))
		caught[cs] = [absf(c.heading - h0), worst]
	var with_cs: Array = caught[true]
	var without: Array = caught[false]
	check("counter-steer catches a slide", float(with_cs[0]) < float(without[0]) * 0.7 and float(with_cs[1]) < 1.2, "turned %.2f rad (peak slip %.2f) with counter-steer, %.2f (%.2f) holding the turn" % [float(with_cs[0]), float(with_cs[1]), float(without[0]), float(without[1])])
	# engine braking: lifting off at speed slows the car noticeably
	var eb := rolling(car(), 100.0)
	run(eb, 3.0, 0.0)
	check("lifting off slows the car", eb.vx * 3.6 < 91.0 and eb.vx * 3.6 > 60.0, "%d km/h after 3 s off the gas" % int(eb.vx * 3.6))
	# traction control reads the driven wheels
	var fw := car("FWD")
	run(fw, 0.6, 1.0)
	check("drive slip follows the driven axle", fw.drive_slip() >= float(fw.wheel_slip[2]), "front %.2f, rear %.2f m/s" % [fw.drive_slip(), float(fw.wheel_slip[2])])
	# no NaNs flat out or backing up
	var fast := rolling(car("AWD"), 300.0)
	fast.gear = 5
	fast.w_eng = fast.w_wheel * fast.ratio(5)
	run(fast, 3.0, 1.0, 0.0, 0.3)
	var back := car("FWD")
	run(back, 1.0, 0.0, 1.0)
	run(back, 3.0, 0.0, 1.0, -0.6)
	check("no NaNs at 300 km/h or in reverse", ok_num(fast) and ok_num(back) and back.vx < -0.5, "reverse %.1f m/s" % back.vx)
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
