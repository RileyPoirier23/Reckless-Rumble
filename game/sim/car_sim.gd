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
var direct_steer := false             # a steering wheel: steer_in is the road wheels' angle over full lock

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
var _brake_down := false        # the pedals as the auto gearbox sees them: down; let go with the
var _gas_down := false          # car standing still (armed); and whether this press started from
var _brake_armed := false       # a standstill
var _gas_armed := false
var _brake_from_rest := false
var _gas_from_rest := false

# ---- state: the parts that suffer
var engine_health := 1.0
var engine_blown := false
var valves_bent := false
var head_gasket := false
var axle_broken := false        # a reverse-to-drive slam too far: the CV axle, the driveshaft or the transfer case
var slam_roll := -1.0           # tests: what the dice say for the next slam (-1 = roll them)
var _slam_t := 0.0              # just shifted into drive rolling backwards: the next stab of gas is a slam
var coolant_c := 15.0
var oil_c := 15.0
var coolant_level := 1.0
var radiator := 1.0
var body := 1.0
var ambient_c := 15.0
var brake_c := [30.0, 30.0]           # front, rear
var tires: Array = []                 # FL, FR, RL, RR: { tread, temp, flat, lockup }

# ---- the road under the car (set by the world every step)
var surface := "dry"                  # dry, wet, snow, ice, gravel, leaves, grass, mud, water
var compound := "summer"              # summer, winter, allseason, sport, semislick, drag, offroad

# ---- outputs for the renderer / HUD / tests
var rpm := 0.0
var wheel_slip: Array = [0.0, 0.0, 0.0, 0.0]   # sliding speed per wheel (m/s)
var front_locked := false
var messages: Array[String] = []
var odometer_m := 0.0
# ---- fuel (only the car you drive burns it; everybody else's tank never runs dry)
const FUEL_SCALE := 5.0      # the map is drawn small, so a tank lasts like a real one would on it
var burn_fuel := false
var tank_l := 50.0
var fuel_l := 50.0
var premium := 0.0           # how much of what's in the tank is premium (0..1)
var _power_w := 0.0
# what wears out (Gus's service puts them back): the clutch disc, the turbo, the pads, the fluid
var clutch_cond := 1.0
var turbo_cond := 1.0
var pads_mm := 10.0
var fluid := 1.0
var _warned := {}
var _knock_t := 0.0

const SURFACE_MU := { "dry": 1.0, "wet": 0.72, "snow": 0.36, "ice": 0.12, "gravel": 0.62, "leaves": 0.6, "grass": 0.5, "mud": 0.36, "water": 0.25 }
const COMPOUND := {
	"summer": { "dry": 1.05, "wet": 0.95, "snow": 0.55, "ice": 0.55, "gravel": 0.9, "leaves": 0.95, "grass": 0.95, "mud": 0.85, "water": 1.0, "cold_below": 7.0, "opt": 85.0 },
	"winter": { "dry": 0.88, "wet": 0.97, "snow": 1.3, "ice": 1.55, "gravel": 1.0, "leaves": 1.0, "grass": 1.0, "mud": 1.1, "water": 1.0, "cold_below": -30.0, "opt": 45.0 },
	"allseason": { "dry": 0.98, "wet": 0.93, "snow": 0.85, "ice": 0.8, "gravel": 0.95, "leaves": 0.95, "grass": 0.97, "mud": 0.92, "water": 1.0, "cold_below": -5.0, "opt": 60.0 },
	"sport": { "dry": 1.12, "wet": 0.92, "snow": 0.45, "ice": 0.45, "gravel": 0.88, "leaves": 0.9, "grass": 0.92, "mud": 0.8, "water": 0.95, "cold_below": 10.0, "opt": 90.0 },
	"semislick": { "dry": 1.22, "wet": 0.7, "snow": 0.3, "ice": 0.35, "gravel": 0.78, "leaves": 0.7, "grass": 0.8, "mud": 0.6, "water": 0.7, "cold_below": 15.0, "opt": 95.0 },
	"drag": { "dry": 1.08, "wet": 0.75, "snow": 0.35, "ice": 0.35, "gravel": 0.85, "leaves": 0.8, "grass": 0.9, "mud": 0.7, "water": 0.8, "cold_below": 12.0, "opt": 90.0, "launch": 1.3, "lateral": 0.85 },
	"offroad": { "dry": 0.92, "wet": 0.9, "snow": 1.05, "ice": 0.75, "gravel": 1.18, "leaves": 1.1, "grass": 1.2, "mud": 1.4, "water": 1.0, "cold_below": -10.0, "opt": 55.0 },
}

func _init(car_spec: Dictionary) -> void:
	spec = car_spec
	compound = String(spec.tires.get("compound", "summer"))
	tank_l = float(spec.get("tank_l", clampf(float(spec.get("mass", 1400.0)) / 30.0, 30.0, 95.0)))
	fuel_l = tank_l
	reset_parts()

func reset_parts() -> void:
	engine_health = 1.0
	engine_blown = false
	valves_bent = false
	head_gasket = false
	axle_broken = false
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
	clutch_cond = 1.0
	turbo_cond = 1.0
	pads_mm = 10.0
	fluid = 1.0
	_warned = {}

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
	return mu * float(spec.get("grip", 1.0))

static func pacejka(slip: float, b: float, c: float) -> float:
	return sin(c * atan(b * slip))

# ------------------------------------------------------------------ the step

## controls: throttle 0..1, brake 0..1, steer -1..1, handbrake 0..1
func step(dt: float, throttle: float, brake: float, steer_in: float, handbrake: float) -> void:
	messages.clear()
	# auto gearbox: hold the brake at a stop to back up (the brake pedal becomes the gas). Only a
	# press that starts from a standstill counts (stopped, or let go while stopped and only crept
	# since): braking to a stop holds you there however long you stay on it. Let go and press again
	# to reverse; the same with the gas to go from reverse back into drive.
	if auto_gearbox:
		var at_rest := absf(vx) < 0.15
		if brake > 0.3 and not _brake_down:
			_brake_down = true
			_brake_from_rest = at_rest or (_brake_armed and absf(vx) < 0.6)
		elif brake < 0.1 and _brake_down:
			_brake_down = false
			_brake_armed = at_rest
		if throttle > 0.3 and not _gas_down:
			_gas_down = true
			_gas_from_rest = at_rest or (_gas_armed and absf(vx) < 0.6)
		elif throttle < 0.1 and _gas_down:
			_gas_down = false
			_gas_armed = at_rest
		if gear > 0 and absf(vx) < 0.6 and _brake_down and _brake_from_rest and throttle < 0.1:
			reverse_hold += dt
			if reverse_hold > 0.35: gear = -1; shift_timer = 0.15
		elif gear < 0 and absf(vx) < 0.6 and _gas_down and _gas_from_rest and brake < 0.1:
			gear = 1; shift_timer = 0.15; reverse_hold = 0.0
		else:
			reverse_hold = 0.0 if gear > 0 else reverse_hold
		if gear < 0:
			var t := throttle
			throttle = brake
			brake = t
	# steering: less lock at speed, and the wheel can only turn so fast (unless a steering wheel's
	# driving: then the rim turns the road wheels one for one, quick as you turn it)
	var v := speed()
	var max_steer := lerpf(float(spec.steer_lock), 0.11, clampf(v / 42.0, 0.0, 1.0))
	# catching a slide: steering into it may go past the speed limit on lock, up to the slide angle
	var beta := atan2(vy, maxf(absf(vx), 1.0))
	var target := steer_in * max_steer
	if absf(beta) > 0.05 and signf(steer_in) == signf(beta) and vx > 2.0:
		target = steer_in * minf(maxf(max_steer, absf(beta) * 1.15), float(spec.steer_lock))
	# quick hands at parking speed, calmer at speed, and the wheel comes back to centre on its own
	var rate := lerpf(4.5, 2.4, clampf(v / 30.0, 0.0, 1.0))
	if absf(target) < absf(steer) and signf(target) == signf(steer) or absf(steer_in) < 0.05: rate *= 1.6
	if direct_steer:
		target = clampf(steer_in, -1.0, 1.0) * float(spec.steer_lock)
		rate = 15.0
	steer = move_toward(steer, target, rate * dt)
	_slam(dt, throttle)
	var h := dt / SUBSTEPS
	for i in SUBSTEPS:
		_substep(h, throttle, brake, handbrake)
	_heat(dt, throttle)
	_wear_checks(dt, throttle)
	_burn(dt)
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
	# into a forward gear while still rolling backwards: the next stab of gas is a slam
	if to > 0 and gear <= 0 and vx < -1.0: _slam_t = 1.0
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
	# downforce from wings and splitters grows with the square of speed
	var dfz := 0.5 * 1.2 * float(spec.get("cl", 0.0)) * vx * vx
	fz_f += dfz * 0.45
	fz_r += dfz * 0.55
	fz_f = maxf(fz_f, m * G * 0.12)
	fz_r = maxf(fz_r, m * G * 0.12)
	var lat := clampf(m * ay * hcg / track, -0.9, 0.9) * 0.5    # left/right split
	var mu_f := (tire_mu(0) * (fz_f * 0.5 - lat * 0.5) + tire_mu(1) * (fz_f * 0.5 + lat * 0.5)) / fz_f
	var mu_r := (tire_mu(2) * (fz_r * 0.5 - lat * 0.5) + tire_mu(3) * (fz_r * 0.5 + lat * 0.5)) / fz_r
	mu_r *= float(spec.get("rear_grip", 1.07))     # wider rears: road cars understeer at the limit
	# a limited-slip diff keeps both driven wheels pushing out of a corner; drag radials hook
	# straight and wash out sideways
	var lsd_gain := 1.0 + 0.07 * (float(spec.get("lsd", 0.3)) - 0.3) * clampf(absf(ay) / 7.0, 0.0, 1.0) * throttle
	var comp: Dictionary = COMPOUND[compound]
	var dt_s := String(spec.get("drivetrain", "RWD"))
	if dt_s == "FWD": mu_f *= lsd_gain
	else: mu_r *= lsd_gain
	if comp.has("lateral"):
		mu_f *= float(comp.lateral)
		mu_r *= float(comp.lateral)
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
	# --- brakes (fade when hot); burnout = line lock: front brake only, so the rears spin. Only on a
	# rear-driver: a front-driver's line lock would hold the wheels that drive, and all-wheel drive
	# turns all four (the brakes on any of them hold the lot)
	var fade_at: float = float(spec.brakes.get("fade_c", 450.0)) * (0.7 + 0.3 * fluid)     # wet old fluid boils early
	var fade_f := 1.0 - clampf((brake_c[0] - fade_at) / 600.0, 0.0, 0.55)
	var fade_r := 1.0 - clampf((brake_c[1] - fade_at) / 600.0, 0.0, 0.55)
	var pad_k := 1.0 if pads_mm > 2.0 else (0.55 if pads_mm > 0.0 else 0.3)              # metal on metal
	var tb: float = float(spec.brakes.max_torque) * brake * pad_k
	var bias: float = spec.brakes.bias
	var line_lock := throttle > 0.6 and brake > 0.6 and avx < 2.0 and String(spec.get("drivetrain", "RWD")) == "RWD"
	var tb_f := tb * bias * fade_f * (1.5 if line_lock else 1.0)
	var tb_r := 0.0 if line_lock else tb * (1.0 - bias) * fade_r
	tb_r += 3000.0 * handbrake
	# --- engine, clutch, driven wheels
	var ie: float = spec.engine.inertia
	var iw: float = spec.tires.driven_inertia
	var gr := ratio(gear) if shift_timer <= 0.0 and not axle_broken else 0.0
	var eff: float = spec.gearbox.efficiency
	var limiter: float = spec.engine.limiter_rpm
	var e_rpm := w_eng * RPM
	# turbo: spools with rpm and throttle, with lag
	var turbo: Dictionary = spec.engine.get("turbo", {})
	var boost_mult := 1.0
	if not turbo.is_empty():
		var target := clampf((e_rpm - float(turbo.spool_rpm) * 0.6) / (float(turbo.spool_rpm) * 0.5), 0.0, 1.0) * throttle
		# a tired turbo can't make full boost; a dead one makes none
		target *= (0.7 + 0.3 * turbo_cond) if turbo_cond > 0.1 else 0.0
		boost = move_toward(boost, target, h / float(turbo.lag))
		boost_mult = float(turbo.no_boost) + (1.0 - float(turbo.no_boost)) * boost
		if boost > 0.9 and not arcade(): turbo_cond = maxf(0.0, turbo_cond - 0.0005 * h)
	var fuel := throttle if shift_timer <= 0.0 else throttle * 0.15
	if e_rpm >= limiter: fuel = 0.0            # rev limiter cuts fuel
	if engine_blown: fuel = 0.0
	# running on fumes it coughs; dry, it doesn't run at all
	var has_gas := not burn_fuel or fuel_l > 0.0
	if not has_gas or (burn_fuel and fuel_l < 0.8 and randf() < 0.3): fuel = 0.0
	var friction := 12.0 + e_rpm * 0.0045 + (1.0 - fuel) * e_rpm * 0.004 + (35.0 if engine_blown else 0.0)   # pumping losses off the gas
	var te := fuel * curve_torque(e_rpm) * boost_mult * power_mult() - friction
	_power_w = maxf(0.0, (te + friction) * w_eng)
	# idle: the ECU holds idle when nothing else drives the engine
	if not clutch_locked and e_rpm < float(spec.engine.idle_rpm) and not engine_blown and has_gas:
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
	var tc_max: float = float(spec.engine.clutch_torque) * engage * ((0.15 + 0.85 * clutch_cond) if clutch_cond > 0.08 else 0.0)
	# --- the driven axles: FWD drives the front, RWD the rear, AWD both through a locked centre.
	# The handbrake splits an AWD car's rear off so it can still be thrown into a slide.
	var hb_on := handbrake >= 0.5
	var drive_front := dt_s == "FWD" or dt_s == "AWD" or dt_s == "4WD"
	var drive_rear := dt_s != "FWD" and not (hb_on and drive_front)
	var slip_v := w_wheel * r - vx
	var kappa := slip_v / maxf(avx, 4.0)
	var launch_k := float(comp.get("launch", 1.0)) / float(comp.get("lateral", 1.0))
	var f_cap_f := mu_f * fz_f
	var f_cap_r := mu_r * fz_r
	var fx_f := 0.0
	var fx_r := 0.0
	# a driven tire shares one budget between pushing and cornering: wheelspin eats side grip
	# (power oversteer on a rear-driver, power understeer on a front-driver)
	# all-wheel drive: the centre diff decides how the push splits. Rear-biased (a drift build) lets
	# the rear step out under power while the front pulls it straight; front-biased stays planted
	var k_f := 1.0
	var k_r := 1.0
	if drive_front and drive_rear:
		var split := awd_split()
		k_f = clampf((1.0 - split) * 2.0, 0.25, 1.4)
		k_r = clampf(split * 2.0, 0.25, 1.6)
	if drive_rear:
		var cr := _combined(kappa * k_r, alpha_r, f_cap_r)
		fx_r = cr.x * launch_k
		fy_r = cr.y
	if drive_front:
		var cf := _combined(kappa * k_f, alpha_f, f_cap_f)
		fx_f = cf.x * launch_k
		fy_f = cf.y
	# brakes on the driven shaft; ABS (STREET and ARCADE) eases off before the wheels lock
	var t_sh := (tb_f if drive_front else 0.0) + (tb * (1.0 - bias) * fade_r if drive_rear and not line_lock else 0.0)
	if assist != Assist.SIM and kappa < -0.1 and t_sh > 0.0:
		t_sh *= clampf(1.0 - (-0.1 - kappa) * 6.0, 0.25, 1.0)
	if drive_rear: t_sh += 3000.0 * handbrake
	var t_brake_r := t_sh if absf(w_wheel) > 0.05 else 0.0
	var brake_dir := signf(w_wheel)
	var road_t := (fx_f + fx_r) * r
	# a stopped wheel with the brake on stays stopped, up to what the brake can hold (the clutch
	# slips and the engine idles against it, the way an automatic sits at a light)
	var held := t_sh > 0.0 and absf(w_wheel) <= 0.05
	if held: clutch_locked = false
	if clutch_locked and gr != 0.0:
		# engine and wheels turn together
		var i_tot := iw + ie * gr * gr
		var acc := (te * gr * eff - road_t - t_brake_r * brake_dir) / i_tot
		var tc_needed := te - ie * acc * gr
		if absf(tc_needed) > tc_max * 1.05 or engage < 1.0:
			clutch_locked = false
		else:
			var w_was := w_wheel
			w_wheel += acc * h
			# the brakes stop a wheel; they never turn it the other way
			if t_brake_r > 0.0 and signf(w_wheel) != signf(w_was):
				w_wheel = 0.0
				clutch_locked = false
			w_eng = w_wheel * gr
	if not clutch_locked:
		var diff := w_eng - w_wheel * gr
		var tc := clampf(diff * 40.0, -tc_max, tc_max) if gr != 0.0 else 0.0
		w_eng += (te - tc) / ie * h
		# a slipping clutch turns work into heat and wear: about one disc per 4 MJ
		if not arcade(): clutch_cond = maxf(0.0, clutch_cond - absf(tc * diff) * h / 4.0e6)
		var w_before := w_wheel
		var drive_t := tc * gr * eff - road_t
		if held:
			if absf(drive_t) <= t_sh: w_wheel = 0.0
			else: w_wheel += (drive_t - signf(drive_t) * t_sh) / iw * h
		else:
			w_wheel += (drive_t - t_brake_r * brake_dir) / iw * h
			if t_brake_r > 0.0 and signf(w_wheel) != signf(w_before): w_wheel = 0.0
		# fully engaged and not slipping hard any more: lock up
		if gr != 0.0 and engage >= 1.0 and (absf((w_eng - w_wheel * gr) * 40.0) < tc_max * 0.8 or signf(w_eng - w_wheel * gr) != signf(diff)):
			clutch_locked = true
			w_eng = w_wheel * gr
	w_eng = maxf(w_eng, 0.0)
	if not clutch_locked and not engine_blown: w_eng = maxf(w_eng, idle_w() * 0.6)
	rpm = w_eng * RPM
	# --- the free-rolling axles: brake force up to grip; past grip they lock (unless ABS)
	front_locked = false
	var rear_locked := false
	if not drive_front:
		var res := _free_axle(tb_f / r, f_cap_f, sgn, avx, fx_r, m, h, assist == Assist.SIM)
		fx_f = res[0]
		front_locked = res[1]
		if front_locked: fy_f *= 0.12                # locked wheels don't steer
		var mag_f := Vector2(fx_f, fy_f).length()
		if mag_f > f_cap_f and mag_f > 0.0:
			fx_f *= f_cap_f / mag_f
			fy_f *= f_cap_f / mag_f
	if not drive_rear:
		var pedal_r := (0.0 if line_lock else tb * (1.0 - bias) * fade_r) / r
		if hb_on:
			# the handbrake locks a free rear: the classic front-driver handbrake turn
			rear_locked = avx > 0.3
			fx_r = -sgn * f_cap_r * 0.8 if rear_locked else clampf(-fx_f - vx * m / (h * 4.0), -f_cap_r, f_cap_r)
			if rear_locked: fy_r *= 0.18
		else:
			var res_r := _free_axle(pedal_r, f_cap_r, sgn, avx, fx_f, m, h, assist == Assist.SIM)
			fx_r = res_r[0]
			rear_locked = res_r[1]
			if rear_locked: fy_r *= 0.15
		var mag_r2 := Vector2(fx_r, fy_r).length()
		if mag_r2 > f_cap_r and mag_r2 > 0.0:
			fx_r *= f_cap_r / mag_r2
			fy_r *= f_cap_r / mag_r2
	front_w = w_wheel if drive_front else (0.0 if front_locked else vx / r)
	var rear_w := w_wheel if drive_rear else (0.0 if rear_locked else vx / r)
	# --- over-rev: the money shift
	if rpm > limiter + 250.0 and not engine_blown:
		var over := (rpm - limiter - 250.0) / 1000.0
		_hurt_engine((over * over * 0.5 + over * 0.05) * h)
	# --- aero and rolling
	var drag := 0.5 * 1.2 * float(spec.cda) * vx * absf(vx)
	var roll_k: float = { "grass": 0.09, "mud": 0.18, "water": 0.6, "snow": 0.03, "gravel": 0.022 }.get(surface, 0.013)
	var roll := roll_k * m * G * clampf(vx * 4.0, -1.0, 1.0)
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
	var lat_f := absf(v_lat_f * cos(steer) - vx * sin(steer))
	var sl_f := Vector2(slip_v, lat_f).length() if drive_front else (avx if front_locked else lat_f)
	var sl_r := Vector2(slip_v, v_lat_r).length() if drive_rear else (avx if rear_locked else absf(v_lat_r))
	wheel_slip = [sl_f, sl_f, sl_r, sl_r]
	var mag_rt := Vector2(fx_r, fy_r).length()
	_tire_work(0, absf(fy_f) * 0.5 + absf(fx_f) * 0.5, sl_f, h)
	_tire_work(1, absf(fy_f) * 0.5 + absf(fx_f) * 0.5, sl_f, h)
	_tire_work(2, mag_rt * 0.5, sl_r, h)
	_tire_work(3, mag_rt * 0.5, sl_r, h)
	# brakes heat with the work they do
	if not arcade(): pads_mm = maxf(0.0, pads_mm - (tb_f * absf(front_w) + tb_r * absf(rear_w)) * h * 2.0e-8)
	brake_c[0] += tb_f * absf(front_w) * h / 9000.0
	brake_c[1] += tb_r * absf(rear_w) * h / 9000.0

## Combined slip on a driven axle: the slip vector (spin, side) feeds one curve, and the force
## points along it. Mostly-spinning slip uses the longitudinal shape, mostly-sideways the lateral.
static func _combined(kappa: float, alpha: float, cap: float) -> Vector2:
	var ty := tan(clampf(alpha, -1.4, 1.4))
	var s := sqrt(kappa * kappa + ty * ty)
	if s < 1e-6: return Vector2.ZERO
	var w := absf(ty) / s
	var f := cap * pacejka(s, lerpf(12.0, 10.0, w), lerpf(1.45, 1.9, w))
	return Vector2(f * kappa / s, -f * ty / s)

## A free-rolling axle under the brakes: [force along the car, locked?]. Holding still at a stop,
## static friction cancels the push from the other axle up to the grip.
func _free_axle(f_req: float, f_cap: float, sgn: float, avx: float, other_fx: float, m: float, h: float, can_lock: bool) -> Array:
	if f_req <= 0.0: return [0.0, false]
	if avx > 0.3:
		if f_req > f_cap * 0.98 and can_lock: return [-sgn * f_cap * 0.82, true]
		return [-sgn * minf(f_req, f_cap * 0.97), false]
	return [clampf(-other_fx - vx * m / (h * 4.0), -minf(f_req, f_cap), minf(f_req, f_cap)), false]

## How hard the driven wheels are spinning (or locking) against the road, in m/s.
func drive_slip() -> float:
	var dts := String(spec.get("drivetrain", "RWD"))
	if dts == "FWD": return maxf(float(wheel_slip[0]), float(wheel_slip[1]))
	if dts == "AWD" or dts == "4WD": return maxf(maxf(float(wheel_slip[0]), float(wheel_slip[2])), 0.0)
	return maxf(float(wheel_slip[2]), float(wheel_slip[3]))

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

## Knock from an aggressive tune at full load, and the warnings when something's worn out.
func _wear_checks(dt: float, throttle: float) -> void:
	var risk := float(spec.get("knock_risk", 0.0)) * lerpf(1.0, 0.3, premium)     # premium resists knock
	if risk > 0.0 and throttle > 0.7 and rpm > float(spec.engine.redline_rpm) * 0.55 and not engine_blown:
		_hurt_engine(risk * 0.01 * dt)
		_knock_t += dt
		if _knock_t > 3.0:
			_knock_t = 0.0
			say("KNOCK. PINGING UNDER LOAD: BACK OFF THE TUNE OR BUY BETTER FUEL")
	_warn("pads2", pads_mm <= 2.0, "GRINDING: THE BRAKE PADS ARE DOWN TO THE BACKING PLATES")
	_warn("clutch5", clutch_cond < 0.5, "THE CLUTCH SLIPS UNDER LOAD. SMELLS LIKE BURNT TOAST")
	_warn("clutch0", clutch_cond <= 0.08, "THE CLUTCH IS GONE. NO DRIVE")
	if not (spec.engine.get("turbo", {}) as Dictionary).is_empty():
		_warn("turbo4", turbo_cond < 0.4, "BLUE SMOKE: THE TURBO'S EATING OIL")
		_warn("turbo1", turbo_cond <= 0.1, "THE TURBO'S DONE. NO BOOST")

func _warn(key: String, cond: bool, text: String) -> void:
	if cond and not _warned.has(key):
		_warned[key] = true
		say(text)

## Wear state as the save keeps it, and back.
## Fuel burned this step: the engine's work at about 0.34 L a kWh (a petrol engine's 250 g/kWh),
## plus a little to idle.
func _burn(dt: float) -> void:
	if not burn_fuel or fuel_l <= 0.0: return
	var lph := _power_w / 1000.0 * 0.336 + (0.9 if w_eng * RPM > 300.0 else 0.0)
	var was := fuel_l
	fuel_l = maxf(0.0, fuel_l - lph / 3600.0 * FUEL_SCALE * dt)
	if was >= tank_l * 0.15 and fuel_l < tank_l * 0.15: say("FUEL LIGHT'S ON")
	if was > 0.0 and fuel_l <= 0.0: say("OUT OF GAS. IT COUGHS, AND THAT'S IT")

func fuel_frac() -> float:
	return clampf(fuel_l / maxf(tank_l, 1.0), 0.0, 1.0)

## Put fuel in (up to a full tank), keeping track of how much of it is premium.
func add_fuel(litres: float, is_premium: bool) -> float:
	var l := clampf(litres, 0.0, tank_l - fuel_l)
	if l <= 0.0: return 0.0
	premium = (premium * fuel_l + (l if is_premium else 0.0)) / (fuel_l + l)
	fuel_l += l
	return l

func wear_state() -> Dictionary:
	var tread := 0.0
	for t in tires: tread += float(t.tread) / 4.0
	return { "clutch": clutch_cond, "turbo": turbo_cond, "pads": pads_mm, "fluid": fluid,
		"engine": engine_health, "gasket": head_gasket, "tread": tread, "fuel": fuel_frac(), "premium": premium, "axle": axle_broken }

func set_wear(w: Dictionary) -> void:
	clutch_cond = float(w.get("clutch", 1.0))
	turbo_cond = float(w.get("turbo", 1.0))
	pads_mm = float(w.get("pads", 10.0))
	fluid = float(w.get("fluid", 1.0))
	engine_health = minf(engine_health, float(w.get("engine", 1.0)))
	if engine_health <= 0.0: engine_blown = true          # it was blown when it went in the garage
	if bool(w.get("gasket", false)): head_gasket = true
	axle_broken = bool(w.get("axle", false))
	if w.has("tread"):
		for t in tires: t.tread = minf(float(t.tread), float(w.tread))
	fuel_l = tank_l * clampf(float(w.get("fuel", 1.0)), 0.0, 1.0)
	premium = clampf(float(w.get("premium", 0.0)), 0.0, 1.0)

func arcade() -> bool:
	return assist == Assist.ARCADE

## An all-wheel-drive car's share of the push to the rear (the centre diff; 0.5 is even).
func awd_split() -> float:
	return clampf(float(spec.get("awd_split", 0.5)), 0.2, 0.85)

## What breaks when a slam goes wrong, by drivetrain.
static func axle_name(drivetrain: String) -> String:
	match drivetrain:
		"FWD": return "CV AXLE"
		"AWD", "4WD": return "TRANSFER CASE"
	return "DRIVESHAFT"

## The chance a reverse-to-drive slam breaks something: faster backwards, more torque at the wheels
## and a tired clutch (which grabs instead of slipping) all make it likelier. A gentle one is free.
static func slam_risk(back_mps: float, wheel_nm: float, clutch: float) -> float:
	if back_mps < 1.5: return 0.0
	return clampf((back_mps - 1.5) * 0.09 * (wheel_nm / 3000.0) * (1.6 - 0.6 * clutch), 0.0, 0.85)

## The reverse-to-drive slam: shift into drive rolling backwards and stab the gas. The driven wheels
## have to stop and spin the other way, which is a burnout on a front-driver (the only one it's
## got) and a hammer blow to the drivetrain. Hope your car can take it.
func _slam(dt: float, throttle: float) -> void:
	if _slam_t <= 0.0: return
	_slam_t -= dt
	if gear <= 0 or vx > -0.3:
		_slam_t = 0.0
		return
	if throttle < 0.6: return
	_slam_t = 0.0
	var back := -vx
	var wheel_nm := curve_torque(maxf(rpm, float(spec.engine.idle_rpm) * 2.0)) * power_mult() * absf(ratio(1))
	if arcade():
		say("REVERSE TO DRIVE: THE FRONT TIRES LIGHT UP")
		return
	clutch_cond = maxf(0.0, clutch_cond - 0.025 * back)
	var roll := slam_roll if slam_roll >= 0.0 else randf()
	slam_roll = -1.0
	if roll < slam_risk(back, wheel_nm, clutch_cond):
		axle_broken = true
		say("%s SNAPPED: CLUNK. NO DRIVE. TOW IT HOME" % axle_name(String(spec.get("drivetrain", "RWD"))))
	else:
		say("REVERSE TO DRIVE AT %d KM/H: IT HELD. THIS TIME" % int(back * 3.6))

func _hurt_engine(amount: float) -> void:
	if arcade() or engine_blown: return
	engine_health = maxf(0.0, engine_health - amount * float(spec.get("engine_wear", 1.0)))
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
