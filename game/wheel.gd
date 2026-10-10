## A steering wheel and pedals. A wheel shows up as a joypad with its own axes: steering on one,
## the pedals on others (each resting at -1, 0 or +1 depending on the make, sometimes both pedals
## on one axis). Settings > Wheel calibrates it once; this reads it.
##
## The rim turns the road wheels one for one: with a 900-degree wheel and a car with 32 degrees of
## lock, full lock is about 14 to 1, like a real car. Godot can only rumble a wheel, not push back,
## so turn on your wheel's centring spring in its own software.
class_name Wheel
extends RefCounted

static var device := -1               # the joypad id this session (ids change between sessions)

## Names and vendor ids that are probably a wheel, for picking one out of the connected pads.
const NAMES := ["wheel", "g29", "g920", "g923", "driving force", "thrustmaster", "t300", "t150", "tmx", "t248", "fanatec", "moza", "momo", "racing"]

static func looks_like_wheel(dev: int) -> bool:
	var nm := Input.get_joy_name(dev).to_lower()
	for n in NAMES:
		if nm.contains(n): return true
	return false

## Find the calibrated wheel among what's plugged in (by its GUID, then its name).
static func resolve() -> void:
	device = -1
	var guid := String(GameSettings.get_v("wheel", "guid"))
	var nm := String(GameSettings.get_v("wheel", "name"))
	for d in Input.get_connected_joypads():
		if guid != "" and Input.get_joy_guid(d) == guid:
			device = d
			return
	for d in Input.get_connected_joypads():
		if nm != "" and Input.get_joy_name(d) == nm:
			device = d
			return

static func active() -> bool:
	return bool(GameSettings.get_v("wheel", "enabled")) and device >= 0 and Input.get_connected_joypads().has(device)

## A pedal, 0 (at rest) to 1 (floored), whichever way the axis runs, with a dead zone at the top
## of the travel and a little saturation at the bottom.
static func pedal(raw: float, rest: float, full: float, dz := 0.03, sat := 0.97) -> float:
	if is_equal_approx(full, rest): return 0.0
	var v := clampf((raw - rest) / (full - rest), 0.0, 1.0)
	return clampf((v - dz) / maxf(sat - dz, 0.01), 0.0, 1.0)

## The rim, -1 (full left lock) to 1 (full right lock). `rotation` is how far the wheel turns lock
## to lock in its driver (900, 540, 270...); `range_deg` how many of those degrees give full lock
## on the road wheels (0 = work it out: real-car gearing, `ratio` to 1, but never past the rim).
static func steer(raw: float, center: float, mn: float, mx: float, sgn: float, rotation: float, range_deg: float,
		gamma := 1.0, dz := 0.0, lock_rad := 0.55, ratio := 14.0) -> float:
	var a := 0.0
	if raw > center: a = (raw - center) / maxf(mx - center, 0.001)
	else: a = (raw - center) / maxf(center - mn, 0.001)
	a = clampf(a * sgn, -1.0, 1.0)
	if absf(a) < dz: a = 0.0
	elif dz > 0.0: a = signf(a) * (absf(a) - dz) / (1.0 - dz)
	a = signf(a) * pow(absf(a), gamma)
	var g := range_deg
	if g <= 0.0: g = minf(rotation, 2.0 * rad_to_deg(lock_rad) * ratio)
	return clampf(a * rotation / maxf(g, 1.0), -1.0, 1.0)

static func axis(i: int) -> float:
	return Input.get_joy_axis(device, i as JoyAxis) if device >= 0 else 0.0

## [gas, brake, steer, handbrake] from the wheel.
static func inputs(lock_rad: float) -> Array:
	var w: Dictionary = GameSettings.data.get("wheel", GameSettings.DEFAULTS.wheel)
	var st := steer(axis(int(w.steer_axis)), float(w.steer_center), float(w.steer_min), float(w.steer_max), float(w.steer_sign),
		float(w.rotation), float(w.range), float(w.steer_gamma), float(w.steer_dz), lock_rad, float(w.ratio))
	var gas := pedal(axis(int(w.gas_axis)), float(w.gas_rest), float(w.gas_full), float(w.pedal_dz), float(w.pedal_sat))
	var brk := 0.0
	if bool(w.combined):
		# both pedals on one axis: the brake runs it the other way
		brk = pedal(axis(int(w.gas_axis)), float(w.gas_rest), float(w.brake_full), float(w.pedal_dz), float(w.pedal_sat))
	else:
		brk = pedal(axis(int(w.brake_axis)), float(w.brake_rest), float(w.brake_full), float(w.pedal_dz), float(w.pedal_sat))
	return [gas, brk, st, Input.get_action_strength("handbrake")]
