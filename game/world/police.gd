## The Port Rumble Police. Patrol cars cruise the city at the limit and notice when you don't.
## They light you up: pull over and it's a ticket from Constable Tremblay. Keep going and it's a
## chase: heat climbs, more cars come, and when they box you in it's the impound lot. Get out
## of sight long enough and they lose you; the heat cools off slowly after that.
class_name Police
extends Node2D

signal busted(fine: int, impound: bool)

const SPOT_M := 60.0          # how far a patrol car sees you, with a clear line (m)
const CHASE_SPOT_M := 120.0   # how far they see you once they're looking for you
const OVER_KMH := 20.0        # how far over the limit before they bother
const STOP_S := 10.0          # lit up: this long to slow down and pull over
const LOSE_S := 14.0          # out of their sight this long and they've lost you
const BUST_S := 2.5           # stopped with a cruiser on you this long: that's it
const BUST_M := 14.0
const CRUISER := "charjer"
const PAINT := "#e9e9ec"
const IMPOUND_FEE := 450
const GARAGE_LOT := Rect2(5516, 1526, 108, 72)       # Covington Auto's lot
const CITY := ["downtown", "oldtown", "residential", "commercial", "industrial"]

var drive: Node
var cruisers: Array[AiCar] = []
var state := "calm"           # calm, stop (lit up: pull over), chase
var lost_t := 0.0
var bust_t := 0.0
var chase_t := 0.0
var stop_t := 0.0
var write_t := 0.0            # the constable's writing the ticket: you sit there
var top_over := 0.0           # the worst km/h over the limit they saw
var offences: Array = []      # what goes on the ticket: speeding, racing, fleeing, ramming
var seen := false             # somebody can see you right now
var enabled := true
var strictness := 1.0          # Settings > Difficulty: relaxed 0.6, normal 1, strict 1.5
var rng := RandomNumberGenerator.new()
var hud_panel: PoliceHud
var _route_t := 0.0
var _spawn_t := 2.0
var _next_id := 0
var _hits := 0


## How strict they are (Settings > Difficulty): how far over they let slide, how long they give you
## to pull over, how long they keep looking.
func over_kmh() -> float:
	return OVER_KMH / maxf(strictness, 0.1)

func stop_s() -> float:
	return STOP_S / maxf(strictness, 0.1)

func lose_s() -> float:
	return LOSE_S * strictness

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.seed = int(Time.get_ticks_usec())
	hud_panel = PoliceHud.new()
	hud_panel.police = self
	hud_panel.size = Vector2(640, 360)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive.get_node("HudLayer").add_child(hud_panel)

# ------------------------------------------------------------------ the rules (pure: tested)

## The posted limit on a class of road, in km/h, the way the signs round it.
static func limit_kmh(cls: String) -> float:
	return snappedf(float(Traffic.SPEED.get(cls, 13.9)) * 3.6, 10.0)

## What the ticket costs. Speeding: $100 + $8 a km/h past 15 over, doubled at 50 over (that's
## stunt driving). Street racing $1,500. Running from them $1,000. Hitting a cruiser $800.
static func fine(over_kmh: float, what: Array) -> int:
	var f := 0.0
	if what.has("speeding") or over_kmh > 15.0:
		f += 100.0 + 8.0 * maxf(0.0, over_kmh - 15.0)
		if over_kmh >= 50.0: f *= 2.0
	if what.has("racing"): f += 1500.0
	if what.has("fleeing"): f += 1000.0
	if what.has("ramming"): f += 800.0
	if what.has("stunting"): f += 400.0
	return int(round(f / 5.0)) * 5

## Do they take the car? When the heat's high, or you raced, or you ran for a long time.
static func impounds(heat: float, what: Array, chase_s: float) -> bool:
	return heat >= 60.0 or what.has("racing") or (what.has("fleeing") and chase_s > 40.0)

## How many patrol cars are around: more in the city, more the hotter you are.
static func want_cruisers(heat: float, style: String, chasing: bool) -> int:
	var n := (1 if style in CITY else 0) + int(heat / 30.0)
	if chasing: n += 1
	return clampi(n, 0, 4)

func heat() -> float:
	return float(drive.save.get("heat", 0.0))

func add_heat(n: float) -> void:
	drive.save.heat = clampf(heat() + n, 0.0, 100.0)

func chasing() -> bool:
	return state != "calm"

func writing() -> bool:
	return write_t > 0.0

# ------------------------------------------------------------------ the frame

func _physics_process(dt: float) -> void:
	var c: PlayerCar = drive.car
	if c == null or c.dead or not enabled or StoryState.active:
		if not cruisers.is_empty() and (c == null or not c.dead): clear()
		return
	if write_t > 0.0:
		write_t -= dt
		return
	_manage(dt, c)
	var spotter: AiCar = null
	var close := INF
	seen = false
	for k in cruisers:
		var d: float = k.sim.pos.distance_to(c.sim.pos)
		close = minf(close, d)
		if _sees(k, c, d):
			seen = true
			spotter = k
		k.night = drive.night
	match state:
		"calm":
			add_heat(-0.06 * dt)
			if spotter and not _legal_here(c):
				var over := _over_kmh(c)
				if _racing(): _light_up(spotter, "racing", over)
				elif over > over_kmh(): _light_up(spotter, "speeding", over)
		"stop":
			stop_t += dt
			top_over = maxf(top_over, _over_kmh(c) if seen else 0.0)
			_steer_chasers(dt, c)
			if _bust_check(dt, c, close): return
			# they gave you a chance
			if stop_t > stop_s() and (c.sim.speed() > 12.0 or close > 90.0):
				state = "chase"
				offences.append("fleeing")
				add_heat(15.0)
				drive.hud.post("THEY'RE NOT ASKING ANYMORE.", 4.0)
		"chase":
			chase_t += dt
			add_heat(1.2 * dt)
			_steer_chasers(dt, c)
			if _bust_check(dt, c, close): return
			lost_t = 0.0 if seen else lost_t + dt
			if lost_t > lose_s(): _lost()
	# drive into a police car and it goes on the ticket (them hitting you doesn't)
	if c.hit_police < _hits: _hits = c.hit_police          # a different car
	if c.hit_police > _hits:
		_hits = c.hit_police
		if not offences.has("ramming"):
			offences.append("ramming")
			add_heat(20.0)
			drive.hud.post("YOU HIT A POLICE CAR. THAT'S A DIFFERENT KIND OF PAPERWORK.", 4.0)
			if state == "calm" and not cruisers.is_empty(): _light_up(_nearest(c), "ramming", 0.0)

## The airstrip on drag night is legal (ish). So is the garage lot.
func _legal_here(c: PlayerCar) -> bool:
	return DragStrip.RUNWAY.has_point(c.sim.pos) or GARAGE_LOT.has_point(c.sim.pos)

func _racing() -> bool:
	return drive.jobs.kind == "street" and drive.jobs.race != null and drive.jobs.race.racing()

func _over_kmh(c: PlayerCar) -> float:
	var road: Dictionary = drive.world.map.road_at(c.sim.pos).get("road", {})
	if road.is_empty(): return 0.0
	return c.sim.speed() * 3.6 - limit_kmh(String(road.cls))

## Can this car see you? Close enough, and no building in the way.
func _sees(k: AiCar, c: PlayerCar, d: float) -> bool:
	var reach := CHASE_SPOT_M if chasing() and k.siren else SPOT_M
	if drive.night and not c.lights_on: reach *= 0.6        # running dark at night
	if d > reach: return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(k.global_position, c.global_position)
	var skip: Array[RID] = [k.get_rid(), c.get_rid()]
	for i in 4:
		q.exclude = skip
		var hit := space.intersect_ray(q)
		if hit.is_empty(): return true
		if hit.collider is BuildingNode: return false
		skip.append(hit.rid)
	return true

## A patrol car that's seen something (the meet's burnouts) lights you up.
func pull_over(k: AiCar, why: String) -> void:
	_light_up(k, why, 0.0)

func _light_up(k: AiCar, why: String, over: float) -> void:
	state = "stop"
	stop_t = 0.0
	lost_t = 0.0
	bust_t = 0.0
	chase_t = 0.0
	offences = [why]
	top_over = maxf(0.0, over)
	for o in cruisers:
		if o == k or o.sim.pos.distance_to(k.sim.pos) < 500.0: _to_chase(o)
	add_heat(25.0 if why == "racing" else 4.0 + over * 0.15)
	drive.hud.post("PORT RUMBLE POLICE. THE RACE IS OVER. PULL OVER." if why == "racing" else "PORT RUMBLE POLICE. PULL OVER.", 5.0)

func _to_chase(k: AiCar) -> void:
	k.siren = true
	k.limits = false
	k.skill = 0.9
	k.speed_cap = 58.0
	k.others = []

## Every so often, a fresh route to where you're going to be.
func _steer_chasers(dt: float, c: PlayerCar) -> void:
	_route_t -= dt
	if _route_t > 0.0: return
	_route_t = 0.7
	for k in cruisers:
		if not k.siren: continue
		var d: float = k.sim.pos.distance_to(c.sim.pos)
		var ahead := c.sim.pos + c.sim.world_velocity() * clampf(d / 45.0, 0.2, 1.4)
		if c.sim.speed() < 3.0 and d < 60.0:
			# you've stopped: they pull in behind you
			var behind := c.sim.pos - c.sim.forward() * (float(c.spec.length) * CarArt.CAR_SCALE * 0.5 + 3.0)
			k.set_path(PackedVector2Array([k.sim.pos, behind]))
			k.speed_cap = 12.0
		elif state == "stop":
			# lit up, not running (yet): they sit on your bumper and wait for you to pull over
			var tail := c.sim.pos - c.sim.forward() * (float(c.spec.length) * CarArt.CAR_SCALE * 0.5 + 9.0)
			k.set_path(_route(k.sim.pos, tail, k.sim.forward()) if d > 45.0 else PackedVector2Array([k.sim.pos, tail, tail + c.sim.world_velocity() * 0.6]))
			k.speed_cap = c.sim.speed() + 5.0 if d < 30.0 else 58.0
		elif d < 45.0 and _sees(k, c, d):
			k.set_path(PackedVector2Array([k.sim.pos, ahead, ahead + c.sim.world_velocity() * 0.8 + c.sim.forward() * 4.0]))
			k.speed_cap = maxf(c.sim.speed() + 6.0, 9.0) if d < 18.0 else 58.0
		else:
			k.set_path(_route(k.sim.pos, ahead, k.sim.forward()))
			k.speed_cap = 58.0

## A road route from a car, without driving back to a junction it's already past.
func _route(from: Vector2, to: Vector2, fwd: Vector2) -> PackedVector2Array:
	var r: PackedVector2Array = drive.world.map.route(from, to)
	var out := PackedVector2Array([from])
	var i := 0
	while i < r.size() - 1 and r[i].distance_to(from) < 30.0 and (r[i] - from).dot(fwd) < 0.0: i += 1
	for j in range(i, r.size()): out.append(r[j])
	out.append(to)
	return out

func _bust_check(dt: float, c: PlayerCar, close: float) -> bool:
	if close < BUST_M and c.sim.speed() < 2.5: bust_t += dt
	else: bust_t = maxf(0.0, bust_t - dt * 0.5)
	if bust_t >= BUST_S:
		_bust(c)
		return true
	return false

func _bust(c: PlayerCar) -> void:
	var f := fine(top_over, offences)
	var take := impounds(heat(), offences, chase_t)
	if take: f += IMPOUND_FEE
	drive.save.cash = int(drive.save.get("cash", 0)) - f
	drive.save.tickets = int(drive.save.get("tickets", 0)) + 1
	var lines: Array = []
	if top_over > 15.0: lines.append("%d IN A %d" % [int(top_over + _limit_here(c)), int(_limit_here(c))])
	for o in offences:
		if o != "speeding": lines.append({ "racing": "STREET RACING", "fleeing": "FAILING TO STOP", "ramming": "DAMAGE TO A POLICE VEHICLE", "stunting": "STUNT DRIVING" }[o])
	var what := ", ".join(lines) if not lines.is_empty() else "BEING YOU, AT NIGHT, IN THAT"
	drive.hud.post("CONSTABLE TREMBLAY: \"LICENCE AND REGISTRATION.\"", 4.0)
	drive.hud.post("TICKET: %s. $%d." % [what, f], 7.0)
	if drive.jobs.active() and drive.jobs.kind in ["street", "pizza"]: drive.jobs.finish(false)
	if take:
		drive.hud.post("THEY TOW IT TO THE NORTHSIDE IMPOUND. $%d TO GET IT OUT. YOU PAY IT." % IMPOUND_FEE, 7.0)
		drive.save.heat = 10.0
		drive._teleport(Jobs.IMPOUND, 0.0)
	else:
		drive.save.heat = heat() * 0.5
		write_t = 3.0
	SaveGame.write(drive.save)
	busted.emit(f, take)
	_stand_down()

func _nearest(c: PlayerCar) -> AiCar:
	var best: AiCar = null
	var bd := INF
	for k in cruisers:
		var d := k.sim.pos.distance_to(c.sim.pos)
		if d < bd:
			bd = d
			best = k
	return best

func _limit_here(c: PlayerCar) -> float:
	var road: Dictionary = drive.world.map.road_at(c.sim.pos).get("road", {})
	return limit_kmh(String(road.cls)) if not road.is_empty() else 50.0

func _lost() -> void:
	drive.hud.post("YOU LOST THEM. FOR NOW. THEY KNOW THE CAR.", 5.0)
	_stand_down()

## Sirens off; back to cruising.
func _stand_down() -> void:
	state = "calm"
	offences = []
	bust_t = 0.0
	lost_t = 0.0
	chase_t = 0.0
	top_over = 0.0
	for k in cruisers:
		k.siren = false
		k.limits = true
		k.skill = 0.7
		k.speed_cap = 99.0
		k.set_path(PackedVector2Array())

## Patrol cars come and go out of your sight: enough of them for how hot you are.
func _manage(dt: float, c: PlayerCar) -> void:
	for k in cruisers.duplicate():
		var d: float = k.sim.pos.distance_to(c.sim.pos)
		if d > (1100.0 if k.siren else 650.0): _remove(k)
	var style := String(drive.world.map.zone_at(c.sim.pos).get("style", "rural"))
	_spawn_t -= dt
	if cruisers.size() < want_cruisers(heat(), style, chasing()) and _spawn_t <= 0.0:
		_spawn_t = 6.0 if chasing() else 20.0
		_spawn(c)
	# patrols: a new beat when they get where they were going
	for k in cruisers:
		if k.siren: continue
		if not k.track.valid() or k.track.done:
			var to := c.sim.pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(150.0, 450.0)
			k.set_path(_route(k.sim.pos, drive.world.map.nearest_road(to, 200.0).get("point", to), k.sim.forward()))

func _spawn(c: PlayerCar) -> void:
	var map: MapData = drive.world.map
	for tries in 8:
		var p := c.sim.pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(220.0, 380.0)
		var n := map.nearest_node(p)
		if n < 0: continue
		var at := map.g_pos[n]
		if at.distance_to(c.sim.pos) < 170.0 or map.g_adj[n].is_empty(): continue
		var nb: int = map.g_adj[n][rng.randi() % map.g_adj[n].size()][0]
		var k := spawn_at(at, (map.g_pos[nb] - at).angle())
		k.set_path(PackedVector2Array([at, map.g_pos[nb]]))
		return

## A patrol car, here, pointing this way.
func spawn_at(at: Vector2, h: float) -> AiCar:
	var k := AiCar.new()
	drive.ysort.add_child(k)
	var spec := SaveGame.load_spec(CRUISER)
	spec.paint = PAINT
	spec.name = "PORT RUMBLE POLICE"
	k.setup_ai(spec, drive.world, drive.skids, drive.hud, at, h, 40 + _next_id % 8)
	_next_id += 1
	k.traffic = drive.traffic
	k.lights = Color(1, 0.2, 0.2)
	k.limits = true
	k.skill = 0.7
	cruisers.append(k)
	drive.traffic.extra.append(k)
	if chasing(): _to_chase(k)
	return k

func _remove(k: AiCar) -> void:
	cruisers.erase(k)
	drive.traffic.extra.erase(k)
	k.queue_free()

## Everybody off the road (a story scene, a new car, a test).
func clear() -> void:
	for k in cruisers.duplicate(): _remove(k)
	state = "calm"
	offences = []

## The corner of the HUD where the heat shows, and the light bar when they're on you.
class PoliceHud extends Control:
	var police: Police
	var t := 0.0

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _draw() -> void:
		if police == null or police.drive == null or StoryState.active or police.drive.hud.stepped_aside: return
		var h := police.heat()
		# nothing to show until the first pip lights
		if h < 10.0 and not police.chasing(): return
		# just over the GPS, whichever GPS this car has
		var r := HudLayout.police_rect(String(police.drive.gps.style), police.chasing())
		draw_rect(r, Color(0, 0, 0, 0.55))
		PixelFont.draw(self, r.position + Vector2(6, 4), "HEAT", Color("f3ead2"))
		for i in 5:
			var lit := h >= 20.0 * i + 10.0
			var col := Color("e0402e") if lit else Color(1, 1, 1, 0.12)
			draw_rect(Rect2(r.position.x + 34 + i * 12, r.position.y + 3, 9, 6), col)
		if not police.chasing(): return
		var red := fmod(t * 3.0, 1.0) < 0.5
		var bar := Rect2(r.position.x, r.position.y + 13, r.size.x, 9)
		draw_rect(bar, Color(0.7, 0.08, 0.06, 0.85) if red else Color(0.1, 0.2, 0.75, 0.85))
		var msg := ""
		if police.state == "stop":
			msg = "PULL OVER  %d" % int(ceilf(maxf(0.0, police.stop_s() - police.stop_t)))
		elif police.seen:
			msg = "PURSUIT"
		else:
			msg = "LOSING THEM  %d" % int(ceilf(maxf(0.0, police.lose_s() - police.lost_t)))
		if police.bust_t > 0.3: msg = "STOPPING... %d" % int(ceilf(Police.BUST_S - police.bust_t))
		PixelFont.draw_centered(self, bar.get_center().x, bar.position.y + 2, msg, Color.WHITE)
