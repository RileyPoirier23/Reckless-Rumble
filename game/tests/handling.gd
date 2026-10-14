## Driving maneuvers for checking the aids: a lane change at 100, full lock at 60, the gas mid-corner
## at 40, lifting off mid-corner at 80, and braking into a turn from 90. Used by physics_tests and
## tests/handling_probe.gd (the table).
extends RefCounted

const DT := 1.0 / 120.0
const MOVES := ["lane_change_100", "full_lock_60", "corner_gas_40", "lift_off_80", "brake_turn_90"]

## The worst slide (degrees between where the car points and where it's going, at speed) in one
## maneuver, driven with the keyboard's ramps through the player's aids (PlayerCar.aids).
static func worst_slide(spec: Dictionary, assist: int, m: String) -> float:
	var c := CarSim.new(spec)
	c.assist = assist
	c.set_ambient(20.0)
	c.auto_gearbox = true
	var v0: float = { "lane_change_100": 100.0, "full_lock_60": 60.0, "corner_gas_40": 40.0, "lift_off_80": 80.0, "brake_turn_90": 90.0 }[m] / 3.6
	# rolling at speed in a sensible gear, the way physics_tests' rolling() does it
	c.vx = v0
	c.w_wheel = c.vx / float(c.spec.tires.radius)
	c.gear = 1
	while c.gear < int(c.spec.gearbox.gears.size()) and c.w_wheel * c.ratio(c.gear) * 60.0 / TAU > float(c.spec.engine.redline_rpm) * 0.7: c.gear += 1
	c.w_eng = c.w_wheel * c.ratio(c.gear)
	c.clutch_locked = true
	var kb := [0.0, 0.0, 0.0]
	var worst := 0.0
	var t := 0.0
	while t < 4.0:
		var th := 0.0
		var br := 0.0
		var st := 0.0
		match m:
			"lane_change_100":
				th = 0.4
				st = 1.0 if t < 0.5 else (-1.0 if t < 1.0 else 0.0)
			"full_lock_60":
				th = 0.3
				st = 1.0
			"corner_gas_40":
				th = 1.0 if t > 0.5 else 0.3
				st = 0.6
			"lift_off_80":
				th = 0.8 if t < 0.6 else 0.0
				st = 0.7
			"brake_turn_90":
				br = 1.0 if t < 1.2 else 0.0
				st = 0.8 if t > 0.3 else 0.0
		# the keyboard's ramps (Controls.drive_inputs)
		kb[0] = move_toward(float(kb[0]), th, DT * (4.0 if th > float(kb[0]) else 8.0))
		kb[1] = move_toward(float(kb[1]), br, DT * (6.0 if br > float(kb[1]) else 12.0))
		var s0: float = kb[2]
		var turning_in := absf(st) > absf(s0) and (signf(st) == signf(s0) or is_zero_approx(s0))
		kb[2] = move_toward(s0, st, DT * (3.5 if turning_in else 7.0))
		var aided := PlayerCar.aids(c, float(kb[0]), float(kb[2]), 0.0, 99.0, false, 1.0, 0.0)
		c.esc_off = bool(aided[2])
		c.step(DT, float(aided[0]), float(kb[1]), float(aided[1]), 0.0)
		if c.speed() > 5.0:
			worst = maxf(worst, absf(atan2(c.vy, maxf(absf(c.vx), 0.1))))
		t += DT
	return rad_to_deg(worst)
