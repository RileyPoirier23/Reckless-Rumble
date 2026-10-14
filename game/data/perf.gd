## Performance numbers for a spec, measured by actually driving it in the sim: a launch on dry,
## flat, warm pavement with the automatic box. 0-100 km/h, the 60-foot, eighth and quarter mile,
## and top speed.
## Cached, because the garage asks a lot.
class_name Perf
extends RefCounted

static var _cache := {}

static func estimate(spec: Dictionary) -> Dictionary:
	var key := JSON.stringify(spec).hash()
	if _cache.has(key): return _cache[key]
	var out := measure(spec)
	_cache[key] = out
	return out

## The cached numbers for a spec, or {} when it hasn't been on the dyno yet.
static func cached(spec: Dictionary) -> Dictionary:
	return _cache.get(JSON.stringify(spec).hash(), {})

## Keep numbers measured elsewhere (on a worker thread, say). The cache is only ever written
## from the main thread.
static func store(spec: Dictionary, out: Dictionary) -> void:
	_cache[JSON.stringify(spec).hash()] = out

## The run itself: a couple of thousand sim steps, so a good fraction of a second. Pure, so it
## can run on a worker thread.
static func measure(spec: Dictionary) -> Dictionary:
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
	var eighth := -1.0
	var sixty := -1.0
	var eighth_kmh := 0.0
	var top := 0.0
	var still := 0.0
	var th := 0.6
	while t < 40.0:
		# a good launch: as much throttle as the tyres will take, no more
		var slip := c.drive_slip()
		th = clampf(th + (3.0 * dt if slip < 1.2 else -8.0 * dt), 0.25, 1.0)
		c.step(dt, th, 0.0, 0.0, 0.0)
		t += dt
		var v := c.speed()
		dist += v * dt
		if zero100 < 0.0 and v >= 27.78: zero100 = t
		if sixty < 0.0 and dist >= 18.29: sixty = t
		if eighth < 0.0 and dist >= 201.17:
			eighth = t
			eighth_kmh = v * 3.6
		if quarter < 0.0 and dist >= 402.3: quarter = t
		if v > top + 0.05:
			top = v
			still = 0.0
		else:
			still += dt
			if still > 3.0 and t > 12.0: break
	var out := { "zero100": zero100, "quarter": quarter, "eighth": eighth, "eighth_kmh": eighth_kmh, "sixty": sixty,
		"top_kmh": top * 3.6, "peaks": Parts.peaks(spec) }
	return out
