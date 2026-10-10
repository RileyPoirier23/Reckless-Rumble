## A steering wheel and pedals. A wheel shows up as a joypad with its own axes: steering on one,
## the pedals on others (each resting at -1, 0 or +1 depending on the make, sometimes both pedals
## on one axis, sometimes on a pedal set with its own plug). Plug one in and the game finds it and offers to set it up (Settings > Wheel
## calibrates it once); this reads it. A wheel is only for driving: the menus never listen to it.
##
## The rim turns the road wheels one for one: with a 900-degree wheel and a car with 32 degrees of
## lock, full lock is about 14 to 1, like a real car. Godot can only rumble a wheel, not push back,
## so turn on your wheel's centring spring in its own software.
class_name Wheel
extends RefCounted

static var device := -1               # the joypad id this session (ids change between sessions)
static var pedals := -1               # its pedals: the wheel itself, or a pedal set on its own plug
static var calibrated := false        # `device` is the wheel Settings > Wheel calibrated (not one just found)
static var test_pads := {}            # the tests plug in pretend controllers: id -> name (the GUID is the name)

## Names that are probably a wheel, for picking one out of what's plugged in.
const NAMES := ["wheel", "g25", "g27", "g29", "g920", "g923", "driving force", "dfgt", "momo", "formula", "thrustmaster",
	"t300", "t150", "t248", "t128", "t500", "t598", "t818", "tmx", "tx racing", "ts-pc", "ts-xw", "t-gt", "ferrari", "fanatec",
	"csl", "clubsport", "podium", "dd pro", "gt dd", "moza", "simucube", "simagic", "cammus", "asetek", "pxn", "openffboard",
	"velocityone", "ffb", "racing", "steering", "speedlink", "accuforce", "direct drive"]
## A pedal set, shifter or handbrake on its own plug isn't the wheel (unless it says it is), but
## it's still part of the rig: it never runs a menu either.
const RIG_PARTS := ["pedal", "shifter", "handbrake", "hand brake", "button box"]
## Wheels by maker and model (vendor id << 16 | product id): SDL's own list of wheels.
const IDS := [0x00791864, 0x11ff0511, 0x1209ffb0,
	0x044fb65d, 0x044fb65e, 0x044fb664, 0x044fb669, 0x044fb66d, 0x044fb66e, 0x044fb66f, 0x044fb677, 0x044fb67f, 0x044fb691, 0x044fb692, 0x044fb696,
	0x046dc24f, 0x046dc260, 0x046dc261, 0x046dc262, 0x046dc266, 0x046dc267, 0x046dc268, 0x046dc269, 0x046dc26d, 0x046dc26e, 0x046dc272,
	0x046dc294, 0x046dc295, 0x046dc298, 0x046dc299, 0x046dc29a, 0x046dc29b, 0x046dca03,
	0x04830522, 0x0483a355, 0x0583a132, 0x0583a133, 0x0583a202, 0x0583b002, 0x0583b005, 0x0583b008, 0x0583b009, 0x0583b018,
	0x0eb70001, 0x0eb70004, 0x0eb70005, 0x0eb70006, 0x0eb70007, 0x0eb70011, 0x0eb70020, 0x0eb70197, 0x0eb7038e, 0x0eb70e03,
	0x16d00d5a, 0x16d00d5f, 0x16d00d60, 0x16d00d61, 0x2433f300, 0x2433f301, 0x2433f303, 0x2433f306, 0x34160301, 0x34160302,
	0x346e0000, 0x346e0002, 0x346e0004, 0x346e0005, 0x346e0006]

## What's plugged in, by id (or the tests' pretend ones).
static func connected() -> Array[int]:
	var out: Array[int] = []
	if not test_pads.is_empty():
		for d in test_pads: out.append(int(d))
		return out
	for d in Input.get_connected_joypads(): out.append(d)
	return out

static func joy_name(dev: int) -> String:
	if not test_pads.is_empty(): return String(test_pads.get(dev, ""))
	return Input.get_joy_name(dev)

static func joy_guid(dev: int) -> String:
	if not test_pads.is_empty(): return String(test_pads.get(dev, ""))
	return Input.get_joy_guid(dev)

## A pad's maker and model, "vendor:product" ("" when the platform doesn't say).
static func ids_of(dev: int) -> String:
	if not test_pads.is_empty(): return ""
	var info := Input.get_joy_info(dev)
	if not info.has("vendor_id") or not info.has("product_id"): return ""
	return "%s:%s" % [str(info.vendor_id), str(info.product_id)]

## Is a pad with this name (and maker and model, when the platform says) a wheel?
static func wheel_name(nm_in: String, vendor := 0, product := 0) -> bool:
	if vendor > 0 and IDS.has((vendor << 16) | product): return true
	var nm := nm_in.to_lower()
	if not nm.contains("wheel"):
		for n in RIG_PARTS:
			if nm.contains(n): return false
	for n in NAMES:
		if nm.contains(n): return true
	return false

static func looks_like_wheel(dev: int) -> bool:
	if not test_pads.is_empty(): return wheel_name(joy_name(dev))
	var info := Input.get_joy_info(dev)
	return wheel_name(joy_name(dev), int(str(info.get("vendor_id", "0"))), int(str(info.get("product_id", "0"))))

## Words in a controller's name that say it's a gamepad (an unknown device that says none of
## these is taken for part of a rig).
const PAD_WORDS := ["pad", "controller", "xbox", "x-box", "playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5",
	"joy-con", "switch", "8bitdo", "joystick", "nintendo", "steam", "stadia", "luna"]

## A wheel, or a pedal set, shifter or handbrake on its own plug. Also anything the engine doesn't
## know as a gamepad and that doesn't call itself one: a wheel whose name we've never seen. (Its
## shifter's buttons share numbers with a pad's D-pad, so it mustn't work the blinkers.)
static func looks_like_rig(dev: int) -> bool:
	if looks_like_wheel(dev): return true
	var nm := joy_name(dev).to_lower()
	for n in RIG_PARTS:
		if nm.contains(n): return true
	if test_pads.is_empty() and not Input.is_joy_known(dev) and nm != "":
		for w in PAD_WORDS:
			if nm.contains(w): return false
		return true
	return false

## The plugged-in pad that was set up as `what` ("" the wheel, "pedals_" its pedal set): by its
## GUID, then its name, then its maker and model (a driver update can change the first two).
static func _find(what: String) -> int:
	for key in ["guid", "name", "ids"]:
		var want := String(GameSettings.get_v("wheel", what + key))
		if want == "": continue
		for d in connected():
			var have := joy_guid(d) if key == "guid" else (joy_name(d) if key == "name" else ids_of(d))
			if have == want: return d
	return -1

## Find the wheel: the calibrated one (and its pedals) among what's plugged in, or else anything
## plugged in that calls itself a wheel (found, not set up yet: see needs_setup).
static func resolve() -> void:
	device = _find("")
	calibrated = device >= 0
	pedals = device
	if String(GameSettings.get_v("wheel", "pedals_guid")) != "" or String(GameSettings.get_v("wheel", "pedals_name")) != "":
		pedals = _find("pedals_")
	if device >= 0: return
	for d in connected():
		if looks_like_wheel(d):
			device = d
			pedals = d
			return

## Driving with it: it's switched on in Settings, it's the wheel that was calibrated, and it and
## its pedals are plugged in.
static func active() -> bool:
	var pads := connected()
	return bool(GameSettings.get_v("wheel", "enabled")) and calibrated and pads.has(device) and pads.has(pedals)

## A wheel's plugged in that's never been set up: the title and the road offer to set it up.
static func needs_setup() -> bool:
	return device >= 0 and not calibrated and connected().has(device)

## Is this joypad part of a rig (the wheel in use, its pedals, or anything else that's a wheel,
## pedals or a shifter)? A rig only drives: it never moves a menu, the counter's cursor or the
## button prompts.
static func is_wheel(dev: int) -> bool:
	return dev >= 0 and (dev == device or dev == pedals or looks_like_rig(dev))

## The controllers that aren't part of a rig: the ones that run the menus.
static func pads() -> Array[int]:
	var out: Array[int] = []
	for d in connected():
		if not is_wheel(d): out.append(d)
	return out

## Every rig part plugged in.
static func devices() -> Array[int]:
	var out: Array[int] = []
	for d in connected():
		if is_wheel(d): out.append(d)
	return out

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

## An axis, or where it rests if it hasn't said anything yet. SDL keeps quiet about an axis until it
## first moves, and Godot reads a quiet axis as exactly 0: for a pedal resting at -1, that's
## halfway down. (A real reading is never exactly 0: SDL's steps fall either side of it.)
static func axis(dev: int, i: int, rest: float) -> float:
	if dev < 0: return rest
	var v := Input.get_joy_axis(dev, i as JoyAxis)
	return rest if v == 0.0 else v

## [gas, brake, steer, handbrake] from the wheel (and its pedals).
static func inputs(lock_rad: float) -> Array:
	var w: Dictionary = GameSettings.data.get("wheel", GameSettings.DEFAULTS.wheel)
	var st := steer(axis(device, int(w.steer_axis), float(w.steer_center)), float(w.steer_center), float(w.steer_min), float(w.steer_max), float(w.steer_sign),
		float(w.rotation), float(w.range), float(w.steer_gamma), float(w.steer_dz), lock_rad, float(w.ratio))
	var gas := pedal(axis(pedals, int(w.gas_axis), float(w.gas_rest)), float(w.gas_rest), float(w.gas_full), float(w.pedal_dz), float(w.pedal_sat))
	var brk := 0.0
	if bool(w.combined):
		# both pedals on one axis: the brake runs it the other way
		brk = pedal(axis(pedals, int(w.gas_axis), float(w.gas_rest)), float(w.gas_rest), float(w.brake_full), float(w.pedal_dz), float(w.pedal_sat))
	else:
		brk = pedal(axis(pedals, int(w.brake_axis), float(w.brake_rest)), float(w.brake_rest), float(w.brake_full), float(w.pedal_dz), float(w.pedal_sat))
	return [gas, brk, st, Input.get_action_strength("handbrake")]
