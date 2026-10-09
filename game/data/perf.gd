## Performance numbers for a spec, measured by actually driving it in the sim: a launch on dry,
## flat, warm pavement with the automatic box. 0-100 km/h, the quarter mile, and top speed.
## Cached, because the garage asks a lot.
class_name Perf
extends RefCounted

static var _cache := {}

static func estimate(spec: Dictionary) -> Dictionary:
	var key := JSON.stringify(spec).hash()
	if _cache.has(key): return _cache[key]
	var c := CarSim.new(spec)
	c.set_ambient(20.0)
	c.cold_start()
	c.coolant_c = 90.0
	c.oil_c = 95.0
	c.assist = CarSim.Assist.STREET
	c.auto_gearbox = true
	c.surface = "dry"
	for i in 4: c.tires[i].temp = float(CarSim.COMPOUND[c.compound].opt)
	var dt := 1.0 / 60.0
	var t := 0.0
	var dist := 0.0
	var zero100 := -1.0
	var quarter := -1.0
	var top := 0.0
	var still := 0.0
	var th := 0.6
	while t < 40.0:
		# a good launch: as much throttle as the tyres will take, no more
		var slip := maxf(float(c.wheel_slip[2]), float(c.wheel_slip[3]))
		th = clampf(th + (3.0 * dt if slip < 1.2 else -8.0 * dt), 0.25, 1.0)
		c.step(dt, th, 0.0, 0.0, 0.0)
		t += dt
		var v := c.speed()
		dist += v * dt
		if zero100 < 0.0 and v >= 27.78: zero100 = t
		if quarter < 0.0 and dist >= 402.3: quarter = t
		if v > top + 0.05:
			top = v
			still = 0.0
		else:
			still += dt
			if still > 3.0 and t > 12.0: break
	var out := { "zero100": zero100, "quarter": quarter, "top_kmh": top * 3.6, "peaks": Parts.peaks(spec) }
	_cache[key] = out
	return out
