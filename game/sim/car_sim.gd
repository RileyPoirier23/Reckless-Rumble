## The car, as physics. No drawing here: this runs the same in the game, in tests and headless.
##
## Top-down bicycle model (front and rear axle) with weight transfer, a Pacejka-style tire
## curve, a friction circle (spinning tires lose side grip: that's how drifts happen), a
## clutch between the engine and the driven wheels, and the parts that wear out or break:
## valves (over-rev), head gasket (overheating), bearings (revving a cold engine), tread,
## tire heat, brake fade, the radiator.
##
## Units: metres, seconds, kilograms, newtons, radians. Heading 0 = +x; +y is screen-down,
## so positive steer and positive yaw turn right (clockwise on screen).
class_name CarSim
extends RefCounted

const G := 9.81
const RPM := 60.0 / TAU   # rad/s -> rpm
const SUBSTEPS := 12

# assist presets
enum Assist { SIM, STREET, ARCADE }

var spec: Dictionary
var assist := Assist.SIM
var auto_gearbox := true

# ---- state: body
var pos := Vector2.ZERO
var heading := 0.0
var vx := 0.0          # forward speed (m/s)
var vy := 0.0          # sideways speed, + = right
var yaw_rate := 0.0
var steer := 0.0       # front wheel angle (rad)
var ax := 0.0          # last longitudinal accel (for weight transfer and the body lean)
var ay := 0.0

# ---- state: drivetrain
var gear := 1          # -1 R, 0 N, 1..n
var w_eng := 0.0       # engine speed (rad/s)
var w_wheel := 0.0     # driven-axle wheel speed (rad/s)
var front_w := 0.0     # front wheel speed (only used for the lock-up look)
var clutch_locked := false
var shift_timer := 0.0
var boost := 0.0       # 0..1 of max boost
var reverse_hold := 0.0

# ---- state: the parts that suffer
var engine_health := 1.0
var engine_blown := false
var valves_bent := false
var head_gasket := false
var coolant_c := 15.0
var oil_c := 15.0
var coolant_level := 1.0
var radiator := 1.0
var body := 1.0
var ambient_c := 15.0
var brake_c := [30.0, 30.0]           # front, rear
var tires: Array = []                 # FL, FR, RL, RR: { tread, temp, flat, lockup }

# ---- the road under the car (set by the world every step)
var surface := "dry"                  # dry, wet, snow, ice, gravel, leaves
var compound := "summer"              # summer, winter

# ---- outputs for the renderer / HUD / tests
var rpm := 0.0
var wheel_slip: Array = [0.0, 0.0, 0.0, 0.0]   # sliding speed per wheel (m/s)
var front_locked := false
var messages: Array[String] = []
var odometer_m := 0.0

const SURFACE_MU := { "dry": 1.0, "wet": 0.72, "snow": 0.36, "ice": 0.12, "gravel": 0.62, "leaves": 0.6 }
const COMPOUND := {
	"summer": { "dry": 1.05, "wet": 0.95, "snow": 0.55, "ice": 0.55, "gravel": 0.9, "leaves": 0.95, "cold_below": 7.0, "opt": 85.0 },
	"winter": { "dry": 0.88, "wet": 0.97, "snow": 1.3, "ice": 1.55, "gravel": 1.0, "leaves": 1.0, "cold_below": -30.0, "opt": 45.0 },
}

func _init(car_spec: Dictionary) -> void:
	spec = car_spec
	reset_parts()

func reset_parts() -> void:
	engine_health = 1.0
	engine_blown = false
	valves_bent = false
	head_gasket = false
	coolant_c = ambient_c
	oil_c = ambient_c
	coolant_level = 1.0
	radiator = 1.0
	body = 1.0
	brake_c = [ambient_c, ambient_c]
	tires = []
	for i in 4:
		tires.append({ "tread": float(spec.tires.tread_mm), "temp": ambient_c, "flat": false })
	w_eng = idle_w()
	clutch_locked = false

func idle_w() -> float:
	return float(spec.engine.idle_rpm) / RPM

func set_ambient(c: float) -> void:
	ambient_c = c

## A cold start: everything at outside temperature.
func cold_start() -> void:
	coolant_c = ambient_c
	oil_c = ambient_c
	brake_c = [ambient_c, ambient_c]
	for t in tires: t.temp = ambient_c

# ------------------------------------------------------------------ helpers

func ratio(g: int) -> float:
	if g == 0: return 0.0
	if g < 0: return -float(spec.gearbox.reverse) * float(spec.gearbox.final)
	return float(spec.gearbox.gears[g - 1]) * float(spec.gearbox.final)

func gear_count() -> int:
	return spec.gearbox.gears.size()

func speed() -> float:
	return Vector2(vx, vy).length()

func forward() -> Vector2:
	return Vector2(cos(heading), sin(heading))

func right() -> Vector2:
	return Vector2(-sin(heading), cos(heading))

func world_velocity() -> Vector2:
	return forward() * vx + right() * vy

func set_world_velocity(v: Vector2) -> void:
	vx = v.dot(forward())
	vy = v.dot(right())

func say(m: String) -> void:
	if not messages.has(m): messages.append(m)

## Engine torque at full throttle for this rpm (N·m), before boost and damage.
func curve_torque(r: float) -> float:
	var c: Array = spec.engine.torque_curve
	if r <= c[0][0]: return c[0][1] * maxf(0.0, r / c[0][0])
	for i in range(1, c.size()):
		if r <= c[i][0]:
			var t: float = (r - c[i - 1][0]) / (c[i][0] - c[i - 1][0])
			return lerpf(c[i - 1][1], c[i][1], t)
	return c[c.size() - 1][1]

func power_mult() -> float:
	if engine_blown: return 0.0
	return sqrt(engine_health)

## Grip of one tire on the current surface: surface × compound × temperature × tread.
func tire_mu(i: int) -> float:
	var t: Dictionary = tires[i]
	var comp: Dictionary = COMPOUND[compound]
	var mu: float = SURFACE_MU[surface] * comp[surface]
	# rubber has a temperature window: summer tires go hard and useless in the cold
	if t.temp < comp.cold_below: mu *= 0.78
	mu *= 1.0 - clampf(absf(t.temp - comp.opt) - 25.0, 0.0, 90.0) / 220.0
	var tread: float = t.tread / float(spec.tires.tread_mm)
	if surface == "dry":
		mu *= 1.0 + (1.0 - tread) * 0.04       # slicks are grippier on dry... until they're cords
	else:
		mu *= 0.3 + 0.7 * tread                 # but tread is what clears water and snow
	if t.tread <= 0.6: mu *= 0.75
	if t.flat: mu *= 0.3
	return mu

static func pacejka(slip: float, b: float, c: float) -> float:
	return sin(c * atan(b * slip))

# ------------------------------------------------------------------ the step

## controls: throttle 0..1, brake 0..1, steer -1..1, handbrake 0..1
func step(dt: float, throttle: float, brake: float, steer_in: float, handbrake: float) -> void:
	messages.clear()
	# auto gearbox: hold brake at a stop to back up (the brake pedal becomes the gas)
	if auto_gearbox:
		if gear > 0 and absf(vx) < 0.6 and brake > 0.3 and throttle < 0.1:
			reverse_hold += dt
			if reverse_hold > 0.35: gear = -1; shift_timer = 0.15
		elif gear < 0 and absf(vx) < 0.6 and throttle > 0.3 and brake < 0.1:
			gear = 1; shift_timer = 0.15; reverse_hold = 0.0
		else:
			reverse_hold = 0.0 if gear > 0 else reverse_hold
		if gear < 0:
			var t := throttle
			throttle = brake
			brake = t
	# steering: less lock at speed, and the wheel can only turn so fast
	var v := speed()
	var max_steer := lerpf(float(spec.steer_lock), 0.11, clampf(v / 42.0, 0.0, 1.0))
	steer = move_toward(steer, steer_in * max_steer, 2.8 * dt)
	var h := dt / SUBSTEPS
	for i in SUBSTEPS:
		_substep(h, throttle, brake, handbrake)
	_heat(dt, throttle)
	if auto_gearbox: _auto_shift(dt, throttle)
	odometer_m += absf(vx) * dt

func shift(to: int) -> void:
	if to == gear or to > gear_count() or to < -1: return
	# Street: no catastrophic money shift (the rest still hurts)
	if assist != Assist.SIM and to > 0 and w_wheel * ratio(to) * RPM > float(spec.engine.limiter_rpm) + 1200.0:
		say("MONEY SHIFT BLOCKED: that gear would put you at %d rpm" % int(w_wheel * ratio(to) * RPM))
		return
	# the money shift: the clutch comes up and the wheels drag the engine past what it can take
	var forced := w_wheel * ratio(to) * RPM if to > 0 else 0.0
	if to > 0 and to < gear and forced > float(spec.engine.limiter_rpm) + 1800.0 and not arcade() and not engine_blown:
		valves_bent = true
		_hurt_engine(0.45 + clampf((forced - float(spec.engine.limiter_rpm) - 1800.0) / 6000.0, 0.0, 0.5))
		say("VALVES BENT: money shift to %d rpm" % int(forced))
	gear = to
	since_shift = 0.0
	shift_timer = float(spec.gearbox.shift_time)
	clutch_locked = false

var since_shift := 9.0

func _auto_shift(dt: float, throttle: float) -> void:
	since_shift += dt
	if gear < 1 or shift_timer > 0.0 or since_shift < 0.8: return
	var red := float(spec.engine.redline_rpm)
	var r: float = spec.tires.radius
	# shift on road speed, so wheelspin doesn't make it hunt
	var road := absf(vx) / r * ratio(gear) * RPM
	if road > red - 250.0 and gear < gear_count() and throttle > 0.2:
		shift(gear + 1)
	elif gear > 1:
		var down := absf(vx) / r * ratio(gear - 1) * RPM
		# kick down only if the lower gear lands well under the shift point
		var after_up := (red - 250.0) * ratio(gear) / ratio(gear - 1)
		if road < minf(1800.0 + 1600.0 * throttle, after_up * 0.8) and down < red - 1200.0:
			shift(gear - 1)

func _substep(h: float, throttle: float, brake: float, handbrake: float) -> void:
	var m: float = spec.mass
	var L: float = spec.wheelbase
	var a: float = spec.cg_front
	var b: float = L - a
	var hcg: float = spec.cg_height
	var r: float = spec.tires.radius
	var track: float = spec.track
	var iz: float = m * a * b * 1.05
	# --- loads, with weight transfer from the last accelerations
	var fz_f: float = m * G * b / L - m * ax * hcg / L
	var fz_r: float = m * G * a / L + m * ax * hcg / L
	fz_f = maxf(fz_f, m * G * 0.12)
	fz_r = maxf(fz_r, m * G * 0.12)
	var lat := clampf(m * ay * hcg / track, -0.9, 0.9) * 0.5    # left/right split
	var mu_f := (tire_mu(0) * (fz_f * 0.5 - lat * 0.5) + tire_mu(1) * (fz_f * 0.5 + lat * 0.5)) / fz_f
	var mu_r := (tire_mu(2) * (fz_r * 0.5 - lat * 0.5) + tire_mu(3) * (fz_r * 0.5 + lat * 0.5)) / fz_r
	mu_r *= float(spec.get("rear_grip", 1.07))     # wider rears: road cars understeer at the limit
	# --- speeds at each axle
	var avx := absf(vx)
	var sgn := 1.0 if vx >= 0.0 else -1.0
	var v_lat_f := vy + a * yaw_rate
	var v_lat_r := vy - b * yaw_rate
	var den := maxf(avx, 1.5)
	var alpha_f := atan2(v_lat_f, den) - steer * sgn
	var alpha_r := atan2(v_lat_r, den)
	var fy_f := -mu_f * fz_f * pacejka(alpha_f, 10.0, 1.9)
	var fy_r := -mu_r * fz_r * pacejka(alpha_r, 10.0, 1.9)
	# --- brakes (fade when hot); burnout = line lock: front brake only
	var fade_f := 1.0 - clampf((brake_c[0] - 450.0) / 600.0, 0.0, 0.55)
	var fade_r := 1.0 - clampf((brake_c[1] - 450.0) / 600.0, 0.0, 0.55)
	var tb: float = float(spec.brakes.max_torque) * brake
	var bias: float = spec.brakes.bias
	var line_lock := throttle > 0.6 and brake > 0.6 and avx < 2.0
	var tb_f := tb * bias * fade_f * (1.5 if line_lock else 1.0)
	var tb_r := 0.0 if line_lock else tb * (1.0 - bias) * fade_r
	tb_r += 3000.0 * handbrake
	# --- engine, clutch, driven wheels
	var ie: float = spec.engine.inertia
	var iw: float = spec.tires.driven_inertia
	var gr := ratio(gear) if shift_timer <= 0.0 else 0.0
	var eff: float = spec.gearbox.efficiency
	var limiter: float = spec.engine.limiter_rpm
	var e_rpm := w_eng * RPM
	# turbo: spools with rpm and throttle, with lag
	var turbo: Dictionary = spec.engine.get("turbo", {})
	var boost_mult := 1.0
	if not turbo.is_empty():
		var target := clampf((e_rpm - float(turbo.spool_rpm) * 0.6) / (float(turbo.spool_rpm) * 0.5), 0.0, 1.0) * throttle
		boost = move_toward(boost, target, h / float(turbo.lag))
		boost_mult = float(turbo.no_boost) + (1.0 - float(turbo.no_boost)) * boost
	var fuel := throttle if shift_timer <= 0.0 else throttle * 0.15
	if e_rpm >= limiter: fuel = 0.0            # rev limiter cuts fuel
	if engine_blown: fuel = 0.0
	var friction := 12.0 + e_rpm * 0.0045 + (35.0 if engine_blown else 0.0)
	var te := fuel * curve_torque(e_rpm) * boost_mult * power_mult() - friction
	# idle: the ECU holds idle when nothing else drives the engine
	if not clutch_locked and e_rpm < float(spec.engine.idle_rpm) and not engine_blown:
		te += 160.0 * (1.0 - e_rpm / float(spec.engine.idle_rpm)) + friction
	# anti-stall: the auto-clutch opens before the engine drops under idle
	if clutch_locked and w_eng * RPM < float(spec.engine.idle_rpm) * 0.85: clutch_locked = false
	# clutch engagement: launches slip the clutch, shifts open it
	var engage := 0.0
	if gr != 0.0 and handbrake < 0.5:
		var wheel_e_rpm := absf(w_wheel * gr) * RPM
		# launch: the auto-clutch lets the engine rev toward a launch rpm that rises with throttle,
		# then bites; once rolling (or already locked) it stays fully in
		var launch := 1100.0 + 2600.0 * throttle
		if clutch_locked or wheel_e_rpm > 1500.0: engage = 1.0
		else: engage = clampf((e_rpm - launch * 0.75) / (launch * 0.55), 0.06 if throttle < 0.05 else 0.0, 1.0)
	if handbrake >= 0.5: clutch_locked = false
	var tc_max: float = float(spec.engine.clutch_torque) * engage
	# rear slip ratio and force
	var slip_v := w_wheel * r - vx
	var kappa := slip_v / maxf(avx, 4.0)
	var f_cap_r := mu_r * fz_r
	var fx_r := f_cap_r * pacejka(kappa, 12.0, 1.45)
	# combined slip: a tire that's spinning or locked has little side grip left
	fy_r /= 1.0 + 5.0 * kappa * kappa
	# rear friction circle: wheelspin eats side grip
	var mag_r := Vector2(fx_r, fy_r).length()
	if mag_r > f_cap_r and mag_r > 0.0:
		fy_r *= f_cap_r / mag_r
		fx_r *= f_cap_r / mag_r
	var t_brake_r := tb_r if absf(w_wheel) > 0.05 else 0.0
	var brake_dir := signf(w_wheel)
	if clutch_locked and gr != 0.0:
		# engine and wheels turn together
		var i_tot := iw + ie * gr * gr
		var acc := (te * gr * eff - fx_r * r - t_brake_r * brake_dir) / i_tot
		var tc_needed := te - ie * acc * gr
		if absf(tc_needed) > tc_max * 1.05 or engage < 1.0:
			clutch_locked = false
		else:
			w_wheel += acc * h
			w_eng = w_wheel * gr
	if not clutch_locked:
		var diff := w_eng - w_wheel * gr
		var tc := clampf(diff * 40.0, -tc_max, tc_max) if gr != 0.0 else 0.0
		w_eng += (te - tc) / ie * h
		var w_before := w_wheel
		w_wheel += (tc * gr * eff - fx_r * r - t_brake_r * brake_dir) / iw * h
		if t_brake_r > 0.0 and signf(w_wheel) != signf(w_before): w_wheel = 0.0
		# fully engaged and not slipping hard any more: lock up
		if gr != 0.0 and engage >= 1.0 and (absf((w_eng - w_wheel * gr) * 40.0) < tc_max * 0.8 or signf(w_eng - w_wheel * gr) != signf(diff)):
			clutch_locked = true
			w_eng = w_wheel * gr
	w_eng = maxf(w_eng, 0.0)
	if not clutch_locked and not engine_blown: w_eng = maxf(w_eng, idle_w() * 0.6)
	rpm = w_eng * RPM
	# front axle is free-rolling: brake force up to grip; past grip it locks (unless ABS)
	var fx_f := 0.0
	var f_brake_req := tb_f / r
	var f_cap := mu_f * fz_f
	front_locked = false
	if avx > 0.3 and f_brake_req > 0.0:
		if f_brake_req > f_cap * 0.98 and assist == Assist.SIM:
			front_locked = true
			fx_f = -sgn * f_cap * 0.82
			fy_f *= 0.12          # locked wheels don't steer
		else:
			fx_f = -sgn * minf(f_brake_req, f_cap * 0.97)
	elif avx <= 0.3 and f_brake_req > 0.0:
		# holding still: static friction cancels the push from the rear, up to the grip
		fx_f = clampf(-fx_r - vx * m / (h * 4.0), -minf(f_brake_req, f_cap), minf(f_brake_req, f_cap))
	front_w = 0.0 if front_locked else vx / r
	# front friction circle
	var mag_f := Vector2(fx_f, fy_f).length()
	if mag_f > f_cap and mag_f > 0.0:
		fx_f *= f_cap / mag_f
		fy_f *= f_cap / mag_f
	# --- over-rev: the money shift
	if rpm > limiter + 250.0 and not engine_blown:
		var over := (rpm - limiter - 250.0) / 1000.0
		_hurt_engine((over * over * 0.5 + over * 0.05) * h)
	# --- aero and rolling
	var drag := 0.5 * 1.2 * float(spec.cda) * vx * absf(vx)
	var roll := 0.013 * m * G * clampf(vx * 4.0, -1.0, 1.0)
	# --- integrate the body
	var fx := fx_r + fx_f * cos(steer) - fy_f * sin(steer) - drag - roll
	var fy := fy_r + fy_f * cos(steer) + fx_f * sin(steer)
	var mz := a * (fy_f * cos(steer) + fx_f * sin(steer)) - b * fy_r
	var dvx := fx / m + vy * yaw_rate
	var dvy := fy / m - vx * yaw_rate
	vx += dvx * h
	vy += dvy * h
	yaw_rate += mz / iz * h
	# below walking pace, blend to the kinematic model so parking isn't twitchy
	if avx < 2.0:
		var k := 1.0 - avx / 2.0
		yaw_rate = lerpf(yaw_rate, vx * tan(steer) / L, k * 0.5)
		vy = lerpf(vy, 0.0, k * 0.3)
	ax = lerpf(ax, fx / m, 0.02)
	ay = lerpf(ay, fy / m, 0.02)
	heading += yaw_rate * h
	pos += world_velocity() * h
	if shift_timer > 0.0: shift_timer -= h
	# --- tires: wear and heat from sliding
	var sl_f := absf(v_lat_f * cos(steer) - vx * sin(steer)) if not front_locked else avx
	var sl_r := Vector2(slip_v, v_lat_r).length()
	wheel_slip = [sl_f, sl_f, sl_r, sl_r]
	_tire_work(0, absf(fy_f) * 0.5 + absf(fx_f) * 0.5, sl_f, h)
	_tire_work(1, absf(fy_f) * 0.5 + absf(fx_f) * 0.5, sl_f, h)
	_tire_work(2, mag_r * 0.5, sl_r, h)
	_tire_work(3, mag_r * 0.5, sl_r, h)
	# brakes heat with the work they do
	brake_c[0] += tb_f * absf(front_w) * h / 9000.0
	brake_c[1] += tb_r * absf(w_wheel) * h / 9000.0

func _tire_work(i: int, force: float, slide: float, h: float) -> void:
	var t: Dictionary = tires[i]
	var p := force * slide                                 # sliding power (W)
	var wear := p * 9.0e-6 * h * (1.6 if compound == "winter" and ambient_c > 15.0 else 1.0)
	if arcade(): wear *= 0.2
	t.tread = maxf(0.0, t.tread - wear)
	t.temp += (p * 0.0022 - (t.temp - ambient_c) * (0.08 + absf(vx) * 0.006) - maxf(0.0, t.temp - 160.0) * 0.6) * h
	if t.tread <= 0.0 and not t.flat and not arcade():
		t.flat = true
		say("BLOWOUT: %s tire is down to the cords" % ["front left", "front right", "rear left", "rear right"][i])

func arcade() -> bool:
	return assist == Assist.ARCADE

func _hurt_engine(amount: float) -> void:
	if arcade() or engine_blown: return
	engine_health = maxf(0.0, engine_health - amount)
	if engine_health <= 0.0:
		engine_blown = true
		say("ENGINE BLOWN")

## Heat once per frame: coolant, oil, the head gasket, cold-engine wear, brake cooling.
func _heat(dt: float, throttle: float) -> void:
	var power := maxf(0.0, curve_torque(rpm) * throttle * power_mult()) * w_eng   # W at the crank
	var q := (power * 0.95 + 2500.0 + w_eng * 6.0) if not engine_blown else 0.0
	var airflow := 0.2 + absf(vx) / 22.0
	if coolant_c > 96.0: airflow += 0.55                                           # the fan
	var stat := clampf((coolant_c - 82.0) / 10.0, 0.04, 1.0)                        # thermostat
	var cool := 820.0 * airflow * radiator * coolant_level * stat * (coolant_c - ambient_c)
	coolant_c += (q - cool) / 32000.0 * dt
	oil_c += ((coolant_c + rpm / 900.0) - oil_c) * 0.04 * dt
	# a holed radiator leaks
	if radiator < 0.85: coolant_level = maxf(0.05, coolant_level - (0.85 - radiator) * 0.004 * dt)
	if coolant_c > 118.0 and not engine_blown:
		_hurt_engine((coolant_c - 118.0) * 0.0009 * dt)
		if coolant_c > 128.0 and not head_gasket and not arcade():
			head_gasket = true
			_hurt_engine(0.35)
			say("HEAD GASKET BLOWN: it cooked at %d°C" % int(coolant_c))
		elif not head_gasket:
			say("OVERHEATING")
	if head_gasket: coolant_level = maxf(0.05, coolant_level - 0.003 * dt)
	# revving a cold engine wears it: the oil is still thick
	if oil_c < 45.0 and rpm > 4200.0 and not engine_blown:
		_hurt_engine((rpm - 4200.0) / 1000.0 * 0.0006 * dt)
		say("COLD ENGINE: let it warm up")
	for i in 2:
		brake_c[i] -= (brake_c[i] - ambient_c) * (0.04 + absf(vx) * 0.004) * dt

## A crash: impact speed along the contact normal (m/s), and where it hit
## (front, rear, side) in the car's own frame.
func impact(v_n: float, where: String) -> void:
	if v_n < 1.5 or arcade(): return
	body = maxf(0.0, body - v_n * v_n * 0.0012)
	if where == "front" and v_n > 4.0:
		var was := radiator
		radiator = maxf(0.0, radiator - (v_n - 4.0) * 0.06)
		if was >= 0.85 and radiator < 0.85: say("RADIATOR HOLED: it's leaking coolant")
	if v_n > 14.0:
		_hurt_engine((v_n - 14.0) * 0.03)
	if v_n > 6.0:
		# a hard hit knocks the alignment and can pop a tire
		var i := 0 if where == "front" else (2 if where == "rear" else randi() % 4)
		if v_n > 12.0 and not tires[i].flat:
			tires[i].flat = true
			say("TIRE BLOWN in the crash")
