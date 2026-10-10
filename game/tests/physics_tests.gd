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
	# braking is braking: hold it from 50 km/h and the car stops and stays stopped (it never backs
	# up, the wheels never turn backwards); let go and press it again to reverse; in reverse the gas
	# stops you and holds you, and you let go and press it again for drive
	for d in ["RWD", "FWD", "AWD"]:
		var bc := rolling(car(d), 50.0)
		bc.auto_gearbox = true
		var low_v := 99.0
		var low_w := 99.0
		var went_back := false
		for i in 600:
			bc.step(1.0 / 120.0, 0.0, 1.0, 0.0, 0.0)
			low_v = minf(low_v, bc.vx)
			low_w = minf(low_w, bc.w_wheel)
			if bc.gear < 0: went_back = true
		check("%s: hold the brake and it stops, and stays stopped" % d, low_v > -0.01 and low_w > -0.01 and not went_back and absf(bc.vx) < 0.05,
			"lowest %.2f m/s, wheel %.2f rad/s, now %.2f" % [low_v, low_w, bc.vx])
		run(bc, 0.3, 0.0, 0.0)
		run(bc, 2.0, 0.0, 1.0)
		check("%s: let go and press it again to reverse" % d, bc.gear < 0 and bc.vx < -0.3, "gear %d, %.2f m/s" % [bc.gear, bc.vx])
		var low_r := -99.0
		for i in 480:
			bc.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
			if i > 240: low_r = maxf(low_r, bc.vx)
		check("%s: in reverse the gas stops it and holds it" % d, bc.gear < 0 and low_r < 0.01 and absf(bc.vx) < 0.05, "gear %d, %.2f m/s" % [bc.gear, bc.vx])
		run(bc, 0.3, 0.0, 0.0)
		run(bc, 2.0, 1.0, 0.0)
		check("%s: let go and press the gas again for drive" % d, bc.gear > 0 and bc.vx > 0.3, "gear %d, %.2f m/s" % [bc.gear, bc.vx])
	# drivetrains: a rear-driver line-locks and smokes the rears; a front-driver's and an all-wheel
	# car's brakes hold the wheels that drive, so no brake burnout; the front-driver's burnout is the
	# reverse-to-drive slam, which can break the CV axle
	var bo := {}
	for d in ["RWD", "FWD", "AWD"]:
		var c0 := car(d)
		c0.auto_gearbox = true
		run(c0, 2.0, 1.0, 1.0)
		bo[d] = [c0.w_wheel * float(c0.spec.tires.radius), c0.vx]
	check("RWD: gas and brake together is a burnout (the rears spin, the car stays put)", float(bo.RWD[0]) > 8.0 and absf(float(bo.RWD[1])) < 0.5, "wheels %.1f m/s, car %.2f" % [float(bo.RWD[0]), float(bo.RWD[1])])
	check("FWD: gas and brake together does nothing but strain", absf(float(bo.FWD[0])) < 1.0 and absf(float(bo.FWD[1])) < 0.3, "wheels %.1f m/s, car %.2f" % [float(bo.FWD[0]), float(bo.FWD[1])])
	check("AWD: the brakes hold all four", absf(float(bo.AWD[0])) < 1.0 and absf(float(bo.AWD[1])) < 0.3, "wheels %.1f m/s, car %.2f" % [float(bo.AWD[0]), float(bo.AWD[1])])
	var slam := func(back_mps: float, roll: float) -> CarSim:
		var c1 := car("FWD")
		c1.auto_gearbox = true
		c1.assist = CarSim.Assist.STREET
		for i in 120 * 6:
			if c1.vx < -back_mps: break
			c1.step(1.0 / 120.0, 0.0, 1.0, 0.0, 0.0)        # in reverse the brake pedal is the gas
		c1.shift(1)
		c1.slam_roll = roll
		return c1
	var ok_slam: CarSim = slam.call(4.0, 0.99)
	var clutch0 := ok_slam.clutch_cond
	var front_spin := 0.0
	for i in 120:
		ok_slam.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
		front_spin = maxf(front_spin, float(ok_slam.wheel_slip[0]))
	run(ok_slam, 2.0, 1.0)
	check("FWD: reverse to drive and stab the gas: the fronts light up", front_spin > 6.0 and not ok_slam.axle_broken and ok_slam.clutch_cond < clutch0 and ok_slam.vx > 2.0,
		"front slip %.1f m/s, clutch %.2f -> %.2f, then %.1f m/s" % [front_spin, clutch0, ok_slam.clutch_cond, ok_slam.vx])
	var bad_slam: CarSim = slam.call(6.0, 0.0)
	run(bad_slam, 0.5, 1.0)
	var v_broke := bad_slam.vx
	run(bad_slam, 2.0, 1.0)
	check("FWD: a slam that goes wrong snaps the CV axle (no drive) and it stays broken till it's fixed",
		bad_slam.axle_broken and bad_slam.vx < maxf(v_broke, 0.0) + 0.5 and bool(bad_slam.wear_state().axle) and CarSim.axle_name("FWD") == "CV AXLE",
		"broken %s, %.1f -> %.1f m/s" % [bad_slam.axle_broken, v_broke, bad_slam.vx])
	check("the slam's risk: free when gentle, worse faster, with more torque and a tired clutch",
		CarSim.slam_risk(1.0, 3000.0, 1.0) == 0.0 and CarSim.slam_risk(6.0, 3000.0, 1.0) > CarSim.slam_risk(3.0, 3000.0, 1.0)
		and CarSim.slam_risk(4.0, 6000.0, 1.0) > CarSim.slam_risk(4.0, 3000.0, 1.0) and CarSim.slam_risk(4.0, 3000.0, 0.2) > CarSim.slam_risk(4.0, 3000.0, 1.0),
		"%.2f / %.2f" % [CarSim.slam_risk(3.0, 3000.0, 1.0), CarSim.slam_risk(6.0, 3000.0, 1.0)])
	# donuts: full lock and full gas from a crawl, no aids: a rear-driver spins round, a front-driver ploughs
	var donut := {}
	for d in ["RWD", "FWD"]:
		var c2 := car(d)
		c2.assist = CarSim.Assist.SIM
		c2.vx = 4.0
		c2.w_wheel = c2.vx / float(c2.spec.tires.radius)
		var spin_rate := 0.0
		var side := 0.0
		for i in 120 * 4:
			c2.step(1.0 / 120.0, 1.0, 0.0, 1.0, 0.0)
			if i > 120 * 2:
				spin_rate += absf(c2.yaw_rate) / (120.0 * 2.0)
				side = maxf(side, absf(c2.vy))
		donut[d] = [spin_rate, side]
	check("RWD: donuts (it rotates hard with the rear out)", float(donut.RWD[0]) > 1.0 and float(donut.RWD[1]) > 1.5, "yaw %.2f rad/s, slide %.1f m/s" % [float(donut.RWD[0]), float(donut.RWD[1])])
	check("FWD: no donuts (it ploughs wide)", float(donut.FWD[1]) < float(donut.RWD[1]) * 0.6, "slide %.1f vs RWD %.1f m/s" % [float(donut.FWD[1]), float(donut.RWD[1])])
	# all-wheel drift, on a built car (twice the torque): the same corner on the gas, a rear-biased
	# centre diff slides, a front-biased one grips
	var drift := {}
	for split in [0.4, 0.8]:
		var built := car("AWD")
		var curve: Array = []
		for pt in built.spec.engine.torque_curve: curve.append([pt[0], float(pt[1]) * 2.0])
		built.spec.engine.torque_curve = curve
		var c3 := rolling(built, 30.0)
		c3.spec.awd_split = split
		c3.assist = CarSim.Assist.SIM
		c3.auto_gearbox = false
		c3.gear = 2
		c3.w_eng = c3.w_wheel * c3.ratio(2)
		var beta := 0.0
		for i in 120 * 2:
			c3.step(1.0 / 120.0, 1.0, 0.0, 0.55, 0.0)
			beta = maxf(beta, absf(atan2(c3.vy, maxf(absf(c3.vx), 1.0))))
		drift[split] = beta
	check("AWD: a rear-biased centre diff drifts, a front-biased one doesn't", float(drift[0.8]) > float(drift[0.4]) * 3.0 and float(drift[0.8]) > 0.3,
		"slip angle %.2f rad at 20/80, %.2f at 60/40" % [float(drift[0.8]), float(drift[0.4])])
	# fuel: cruising sips it, flat out gulps it, dry it doesn't go, premium keeps a hot tune from knocking
	var cruise := rolling(car(), 90.0)
	cruise.burn_fuel = true
	var f0 := cruise.fuel_l
	for i in 120 * 60:
		cruise.step(1.0 / 120.0, clampf(0.25 + (25.0 - cruise.vx) * 0.3, 0.0, 1.0), 0.0, 0.0, 0.0)
	var per_min := f0 - cruise.fuel_l
	var mins := cruise.tank_l / maxf(per_min, 0.001)
	check("a tank lasts most of an hour at 90", mins > 35.0 and mins < 150.0, "%.2f L a minute, %.0f minutes a tank" % [per_min, mins])
	var hard := car()
	hard.burn_fuel = true
	var h0 := hard.fuel_l
	run(hard, 20.0, 1.0)
	var hard_min := (h0 - hard.fuel_l) * 3.0
	check("flat out burns it a lot faster", hard_min > per_min * 2.5, "%.2f vs %.2f L a minute" % [hard_min, per_min])
	var dry := car()
	dry.burn_fuel = true
	dry.fuel_l = 0.0
	run(dry, 5.0, 1.0)
	var dry_v := dry.vx
	dry.add_fuel(6.0, false)
	run(dry, 5.0, 1.0)
	check("dry, it doesn't go; a jerry can and it does", dry_v < 0.5 and dry.vx > 5.0, "%.1f then %.1f m/s" % [dry_v, dry.vx])
	var kr := []
	for prem in [0.0, 1.0]:
		var k := rolling(car(), 60.0)
		k.spec.knock_risk = 3.0
		k.premium = prem
		run(k, 12.0, 1.0)
		kr.append(1.0 - k.engine_health)
	check("premium keeps a hot tune from knocking itself to bits", float(kr[1]) < float(kr[0]) * 0.5 and float(kr[0]) > 0.0, "engine wear %.3f on regular, %.3f on premium" % [float(kr[0]), float(kr[1])])
	var mix := car()
	mix.fuel_l = mix.tank_l * 0.5
	mix.add_fuel(mix.tank_l, true)
	check("half a tank of regular topped up with premium is half premium", absf(mix.premium - 0.5) < 0.01 and absf(mix.fuel_l - mix.tank_l) < 0.01, "%.2f" % mix.premium)
	# a blown engine saved with the car is still blown when it comes back out of the garage
	var blown := car()
	blown._hurt_engine(2.0)
	var reloaded := car()
	reloaded.set_wear(blown.wear_state())
	check("a blown engine stays blown through the save", blown.engine_blown and reloaded.engine_blown and reloaded.power_mult() == 0.0, "health %.2f, blown %s" % [reloaded.engine_health, str(reloaded.engine_blown)])
	var tired := car()
	tired.set_wear({ "engine": 0.4 })
	check("a tired engine isn't a blown one", not tired.engine_blown and tired.power_mult() > 0.5, "%.2f" % tired.power_mult())
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
