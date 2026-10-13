## Somebody on the shoulder with the hazards on, now and then, out on the country roads and the
## highway: a dead battery, an empty tank, a flat, a belt. Pull up, stop and give them a hand
## (or don't). Helping is a karma deed, and sometimes a few bucks; it costs you a bit of gas when
## it's the jerry can. They drive off once they're sorted, or wait for Toby.
class_name Roadside
extends Node

const EVERY_S := Vector2(240.0, 480.0)    # between breakdowns, free driving
const FIRST_S := 150.0
const AHEAD_M := Vector2(120.0, 230.0)    # where they are: ahead of you, out of sight
const HELP_M := 12.0                      # stop within this of them
const HELP_S := 3.0                       # the hand takes this long
const GONE_M := 500.0                     # you've left them behind

## What's wrong, and what helping does: cash to you, gas off you (litres), and the karma deed.
const OUTCOMES := [
	{ "id": "battery", "w": 3.0, "cash": 40, "fuel": 0.0, "stay": false,
		"text": "A DEAD BATTERY. YOU GIVE THEM A BOOST OFF YOURS. \"YOU'RE THE COVINGTON KID, EH? HERE. FOR THE TROUBLE.\" $40." },
	{ "id": "gas", "w": 2.0, "cash": 20, "fuel": 4.0, "stay": false,
		"text": "OUT OF GAS. YOU POUR THEM WHAT'S IN THE JERRY CAN. THEY'LL MAKE THE ULTRAMARGE. \"THANKS, KID. TWENTY FOR THE GAS.\"" },
	{ "id": "flat", "w": 2.0, "cash": 0, "fuel": 0.0, "stay": false,
		"text": "A FLAT. YOU HOLD THE LIGHT WHILE THEY FIGHT THE SPARE. TWENTY MINUTES. \"THANKS, KID. I OWE YOU ONE.\"" },
	{ "id": "toby", "w": 1.5, "cash": 0, "fuel": 0.0, "stay": true,
		"text": "THEY'VE ALREADY CALLED TOBY. HE'S TWENTY MINUTES OUT. THEY WAVE YOU ON. \"NICE CAR, KID.\"" },
	{ "id": "belt", "w": 1.0, "cash": 0, "fuel": 0.0, "stay": true,
		"text": "A BELT. NOBODY FIXES A BELT ON THE SHOULDER. YOU LEND THEM YOUR PHONE AND THEY CALL FOR A RIDE. \"APPRECIATE IT, KID.\"" },
]
const SPOTTED := ["SOMEBODY'S ON THE SHOULDER UP AHEAD WITH THE HAZARDS ON.", "HAZARDS ON THE SHOULDER AHEAD. SOMEBODY'S HAVING A NIGHT.", "A CAR ON THE SHOULDER AHEAD, FOUR-WAYS GOING."]

var drive: Node
var enabled := true
var rng := RandomNumberGenerator.new()
var car: TrafficCar = null
var at := Vector2.ZERO
var outcome := {}
var _next_t := FIRST_S
var _help_t := -1.0                 # counting while you're giving the hand
var _leave_t := -1.0                # then they go
var helped := 0

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.randomize()

## Only out on the road with nothing else on: no mission, no job, no scene.
func quiet() -> bool:
	return enabled and drive.car != null and drive.mission == null and String(drive.jobs.kind) in ["", "cruise"] \
		and not drive.modal_open() and not drive.hold_car and drive.incidents.scenes.is_empty()

func _process(dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_process_timed(dt)
	Prof.lap('world_roadside_process', _t0)

func _process_timed(dt: float) -> void:
	if drive.car == null: return
	if car == null:
		if not quiet(): return
		_next_t -= dt
		if _next_t <= 0.0:
			_next_t = rng.randf_range(EVERY_S.x, EVERY_S.y)
			_spawn(drive.car.sim.pos, drive.car.sim.forward())
		return
	if not is_instance_valid(car) or car.gone:
		car = null
		return
	var me: Vector2 = drive.car.sim.pos
	if me.distance_to(at) > GONE_M:
		_release(true)
		return
	if _leave_t >= 0.0:
		_leave_t -= dt
		if _leave_t <= 0.0: _release(bool(outcome.get("stay", false)))
		return
	if _help_t >= 0.0:
		_help_t += dt
		drive.hud.prompt("GIVING THEM A HAND...")
		if _help_t >= HELP_S: _done()
		return
	if me.distance_to(at) < HELP_M and drive.car.sim.speed() < 1.5 and not drive.modal_open():
		drive.hud.prompt(Hints.fmt("{use}: GIVE THEM A HAND"))
		if Input.is_action_just_pressed("use"):
			_help_t = 0.0
			outcome = pick_outcome(rng, float(drive.car.sim.fuel_l))

## Which trouble it is: weighted, and never the jerry can when you haven't the gas to spare.
static func pick_outcome(r: RandomNumberGenerator, my_fuel := 99.0) -> Dictionary:
	var total := 0.0
	for o in OUTCOMES:
		if float(o.fuel) > 0.0 and my_fuel < float(o.fuel) + 6.0: continue
		total += float(o.w)
	var x := r.randf() * total
	for o in OUTCOMES:
		if float(o.fuel) > 0.0 and my_fuel < float(o.fuel) + 6.0: continue
		x -= float(o.w)
		if x <= 0.0: return o
	return OUTCOMES[0]

## A car on the shoulder of a road with a shoulder, a couple of hundred metres up the road.
func _spawn(me: Vector2, fwd: Vector2) -> void:
	var traffic: Traffic = drive.traffic
	var map: MapData = drive.world.map
	for attempt in 10:
		var p := me + fwd.rotated(rng.randf_range(-0.6, 0.6)) * rng.randf_range(AHEAD_M.x, AHEAD_M.y)
		var n := map.nearest_node(p)
		if n < 0 or map.g_adj[n].is_empty(): continue
		var e: Array = map.g_adj[n][rng.randi() % map.g_adj[n].size()]
		var road: Dictionary = e[2]
		if float(MapData.CLS[road.cls].shoulder) <= 0.0: continue        # the country roads and the highway only
		var a := n
		var b: int = e[0]
		var L := map.g_pos[a].distance_to(map.g_pos[b])
		if L < 90.0: continue
		var s := rng.randf_range(40.0, L - 40.0)
		var off := float(road.w) / 2.0 + 1.2                             # on the gravel, off the asphalt
		var spot := traffic.lane_point(a, b, s, off)
		if spot.distance_to(me) < 80.0 or traffic.hush.has_point(spot): continue
		var c := traffic.place_car(a, b, s, off)
		if c == null: continue
		c.state = "parked"
		c.held = true
		c.v = 0.0
		c.view.blink_left = true
		c.view.blink_right = true
		car = c
		at = spot
		_help_t = -1.0
		_leave_t = -1.0
		drive.hud.post(String(SPOTTED[rng.randi() % SPOTTED.size()]), 4.0)
		return

func _done() -> void:
	_help_t = -1.0
	drive.hud.post(String(outcome.text), 7.0)
	if int(outcome.cash) > 0: drive.save.cash = int(drive.save.cash) + int(outcome.cash)
	if float(outcome.fuel) > 0.0: drive.car.sim.fuel_l = maxf(0.0, float(drive.car.sim.fuel_l) - float(outcome.fuel))
	Karma.deed("helped")
	Awards.bump("helped")
	helped += 1
	_leave_t = 5.0 if not bool(outcome.get("stay", false)) else 2.0

## They go (back into traffic), or they stay put with the hazards on until you're gone.
func _release(forget_only: bool) -> void:
	if is_instance_valid(car) and not car.gone and not forget_only:
		car.state = "drive"
		car.held = false
		car.view.blink_left = false
		car.view.blink_right = false
	elif is_instance_valid(car) and forget_only:
		car.held = false                     # traffic can clean it up once it's far enough
	car = null
	outcome = {}
	_help_t = -1.0
	_leave_t = -1.0
