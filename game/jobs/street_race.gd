## Street racing after dark: Marco with the clipboard posts a route, three locals show up with
## whatever they drive, everybody pays the buy-in and the winner takes the pot (Marco keeps a
## tenth for organizing). The checkpoints come up on the GPS one at a time; miss one and you go
## back for it. The police don't love any of this.
class_name StreetRace
extends Node2D

signal closed(won: int)

## The routes: waypoints the race goes through (snapped to the road graph), laps, buy-in.
const ROUTES := [
	{ "id": "main_mile", "name": "THE MAIN STREET MILE", "laps": 1, "loop": false, "buy_in": 150,
		"pts": [Vector2(5470, 1631), Vector2(6000, 1548), Vector2(6500, 1462), Vector2(6800, 1420)],
		"blurb": "COVINGTON CORNER TO DIEPPE ON MAIN. STRAIGHT, FAST, AND FULL OF BUSES." },
	{ "id": "downtown", "name": "THE DOWNTOWN BOX", "laps": 2, "loop": true, "buy_in": 300,
		"pts": [Vector2(5760, 1390), Vector2(6250, 1390), Vector2(6250, 1505), Vector2(5760, 1583)],
		"blurb": "ST GEORGE, KING, MAIN, LUTZ. TWO LAPS. FOUR CORNERS THAT KNOW YOUR NAME." },
	{ "id": "riverside", "name": "RIVERSIDE LOOP", "laps": 2, "loop": true, "buy_in": 300,
		"pts": [Vector2(5560, 1850), Vector2(6120, 1850), Vector2(6120, 1970), Vector2(5560, 1970)],
		"blurb": "CLEVELAND AND TRITES, TWICE. THE HOUSES ARE CLOSE AND THE CURTAINS TWITCH." },
	{ "id": "northend", "name": "NORTH END SPRINT", "laps": 1, "loop": false, "buy_in": 500,
		"pts": [Vector2(5780, 1110), Vector2(6260, 1110), Vector2(6260, 1390), Vector2(5900, 1390), Vector2(5900, 1562)],
		"blurb": "MORTON, CHESTER, ST GEORGE, DOWN VAUGHAN HARVEY TO MAIN. NO LAPS. NO SECOND CHANCES." },
]

## Who shows up. Each brings a car about as quick as yours.
const RACERS := [
	{ "name": "TYLER 'TAILLIGHTS' THIBODEAU", "skill": 0.84, "line": "\"Get a good look at these.\" He means his taillights." },
	{ "name": "MONIQUE ARSENAULT", "skill": 0.88, "line": "\"Don't scratch it. It's my mother's.\"" },
	{ "name": "DUSTIN FROM THE CAR WASH", "skill": 0.8, "line": "\"I waxed it for this. Twice.\"" },
	{ "name": "KAYLA 'KICKDOWN' LANDRY", "skill": 0.86, "line": "\"It's an automatic. On purpose.\"" },
	{ "name": "OLD MAN BOUDREAU", "skill": 0.9, "line": "\"I was racing Main Street before they paved it.\"" },
	{ "name": "BRAYDEN WITH THE SUBWOOFER", "skill": 0.78, "line": "You hear him two blocks before you see him." },
	{ "name": "CHANTAL 'THE ACCOUNTANT' GOGUEN", "skill": 0.92, "line": "\"I've done the math. You lose.\"" },
]
const CLASSES := ["sports", "jdm", "muscle", "pony", "hot_hatch", "rally", "exotic", "coupe", "euro", "compact", "sedan"]
const CUT := 0.10             # Marco's tenth
const DNF_S := 45.0           # after the winner's in, this long to finish
const CHECK_M := 22.0         # how close counts as through a checkpoint

var drive: Node
var route: Dictionary
var track := PathTrack.new()  # the player's progress
var path := PackedVector2Array()
var total := 0.0              # race distance (m), all laps
var checks: Array = []        # s-values the player must pass, in order
var check_i := 0
var racers: Array[AiCar] = []
var info: Array = []          # per racer: { name, line, car, skill }
var finish_t := {}            # racer index (-1 = you) -> time
var state := "grid"           # grid, race, done
var t := 0.0
var clock := 0.0
var _rb_t := 0.0
var panel: RaceHud

## Pure: the route's waypoints snapped to the road graph and joined up with GPS routes.
static func build_path(map: MapData, r: Dictionary) -> PackedVector2Array:
	var wp: Array = r.pts
	var out := PackedVector2Array()
	var n := wp.size() + (1 if r.loop else 0)
	for i in n - 1:
		var leg := map.route(wp[i], wp[(i + 1) % wp.size()])
		for p in leg:
			if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.5: out.append(p)
	return out

## What the winner takes home: the pot, less Marco's cut.
static func purse(buy_in: int, field: int) -> int:
	return int(round(buy_in * field * (1.0 - CUT)))

## How quick a car is, for matching the field: horsepower per tonne.
static func hp_per_t(spec: Dictionary) -> float:
	return Parts.peaks(spec).x / maxf(float(spec.mass) / 1000.0, 0.3)

## Three catalogue cars near this power-to-weight (some quicker, some not).
static func pick_cars(rng: RandomNumberGenerator, player_spec: Dictionary, n: int) -> Array:
	var want := hp_per_t(player_spec)
	var pool: Array = []
	for cls in CLASSES:
		for id in CarCatalog.by_class(cls): pool.append(id)
	var scored: Array = []
	for id in pool:
		if String(id) == String(player_spec.get("id", "")): continue
		var s := CarCatalog.spec(String(id))
		scored.append([absf(log(hp_per_t(s) / maxf(want, 1.0))) + rng.randf() * 0.12, id])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	var out: Array = []
	for i in mini(n, scored.size()): out.append(scored[i][1])
	return out

func setup(the_drive: Node, r: Dictionary, rng: RandomNumberGenerator) -> void:
	drive = the_drive
	route = r
	z_index = 3050
	z_as_relative = false
	var map: MapData = drive.world.map
	path = PathTrack.rounded(build_path(map, r), 10.0, bool(r.loop))
	var lap := 0.0
	for i in path.size() - 1: lap += path[i].distance_to(path[i + 1])
	# a sprint runs on past the line so nobody brakes for it
	var run := path.duplicate()
	if not r.loop:
		var d := (path[path.size() - 1] - path[path.size() - 2]).normalized()
		run.append(path[path.size() - 1] + d * 200.0)
	track.set_path(run, r.loop)
	total = lap * int(r.laps)
	# checkpoints: every waypoint, every lap, then the line
	var wp_s: Array = []
	var probe := PathTrack.new()
	probe.set_path(path, false)
	for w in r.pts:
		var best := 0.0
		var bd := INF
		for i in path.size():
			if path[i].distance_to(map.g_pos[map.nearest_node(w)]) < bd:
				bd = path[i].distance_to(map.g_pos[map.nearest_node(w)])
				best = probe.cum[i]
		wp_s.append(best)
	for l in int(r.laps):
		for s in wp_s:
			if l == 0 and float(s) < 1.0: continue
			checks.append(float(s) + lap * l)
	checks.append(total)
	# the grid: two by two, you in one of the slots. A loop lines up on its last straight, before
	# the line; a sprint lines up on its first one (the start of a sprint can be a dead end).
	var slots: Array = []
	var heads: Array = []
	for i in 4:
		var s := -(7.0 + 7.5 * (i / 2)) if r.loop else 9.5 - 7.5 * (i / 2)
		var d := track.dir_at(s)
		slots.append(track.point_at(s) + Vector2(-d.y, d.x) * (-2.3 if i % 2 == 0 else 2.3))
		heads.append(d.angle())
	var mine := rng.randi() % 4
	var cars := pick_cars(rng, drive.car.spec, 3)
	var names := RACERS.duplicate()
	for i in names.size():
		var j := rng.randi() % names.size()
		var tmp: Variant = names[i]
		names[i] = names[j]
		names[j] = tmp
	var k := 0
	for i in 4:
		if i == mine: continue
		var a := AiCar.new()
		drive.ysort.add_child(a)
		var spec := CarCatalog.spec(String(cars[k]))
		spec.paint = "#%02x%02x%02x" % [rng.randi_range(30, 230), rng.randi_range(30, 230), rng.randi_range(30, 230)]
		a.setup_ai(spec, drive.world, drive.skids, drive.hud, slots[i], float(heads[i]), 60 + k)
		a.traffic = drive.traffic
		a.skill = float(names[k].skill)
		a.hold = true
		a.set_path(run, r.loop, 0.0)
		racers.append(a)
		drive.traffic.extra.append(a)
		var e := CarCatalog.entry(String(cars[k]))
		info.append({ "name": names[k].name, "line": names[k].line, "car": "%s %s" % [String(e.make).to_upper(), String(e.model).to_upper()], "skill": float(names[k].skill) })
		k += 1
	for a in racers:
		var o: Array = []
		for b in racers:
			if b != a: o.append(b)
		o.append(drive.car)
		a.others = o
		if r.loop: a.track.behind_start()
	drive._teleport(slots[mine], float(heads[mine]))
	drive.car.locked = true
	track.snap(drive.car.sim.pos)
	if r.loop: track.behind_start()
	# Marco's crew blocks the side streets for the night: no new traffic on the route, and what's
	# there (out of sight) is gone
	var box := Rect2(path[0], Vector2.ZERO)
	for q in path: box = box.expand(q)
	drive.traffic.hush = box.grow(40.0)
	panel = RaceHud.new()
	panel.race = self
	panel.size = Vector2(640, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive.get_node("HudLayer").add_child(panel)
	drive.hud.post("MARCO: \"WINNER TAKES $%d. NO CRYING.\"" % purse(int(r.buy_in), 4), 4.0)
	drive._on_dest("CHECKPOINT", track.point_at(checks[0]), true)

static func clock_str(sec: float) -> String:
	return "%d:%04.1f" % [int(sec) / 60, fmod(sec, 60.0)]

func racing() -> bool:
	return state == "race"

## The grid: nobody moves until the lights.
func holding() -> bool:
	return state == "grid"

func _process(dt: float) -> void:
	queue_redraw()
	if drive.car == null: return
	t += dt
	match state:
		"grid":
			if t > 4.0:
				state = "race"
				clock = 0.0
				for a in racers: a.hold = false
				drive.police.add_heat(8.0)
		"race":
			clock += dt
			_progress()
			_rubber_band(dt)
			# the winner's in and you're not: you have a little while
			if not finish_t.is_empty() and not finish_t.has(-1):
				var first := INF
				for k in finish_t: first = minf(first, float(finish_t[k]))
				if clock - first > DNF_S:
					_end()
		"done":
			if t > 7.0: closed.emit(_winnings())

func _progress() -> void:
	var c: PlayerCar = drive.car
	track.advance(c.sim.pos)
	if check_i < checks.size():
		var p := track.point_at(float(checks[check_i]))
		if c.sim.pos.distance_to(p) < CHECK_M or (check_i == checks.size() - 1 and track.dist >= total - 2.0 and c.sim.pos.distance_to(p) < CHECK_M * 1.5):
			check_i += 1
			if check_i >= checks.size():
				finish_t[-1] = clock
				_end()
			else:
				drive._on_dest("CHECKPOINT", track.point_at(float(checks[check_i])), true)
				drive.audio.tick = 1.0
	for i in racers.size():
		if finish_t.has(i): continue
		if racers[i].track.dist >= total:
			finish_t[i] = clock
			racers[i].speed_cap = 11.0
			if finish_t.size() == 1: drive.hud.post("%s TAKES IT." % info[i].name, 3.0)

## Close racing: the leaders lift a little, the ones at the back try harder.
func _rubber_band(dt: float) -> void:
	_rb_t -= dt
	if _rb_t > 0.0: return
	_rb_t = 1.0
	var me := progress(-1)
	for i in racers.size():
		var gap := racers[i].track.dist - me
		racers[i].skill = clampf(float(info[i].skill) - clampf(gap / 500.0, -0.06, 0.07), 0.7, 0.97)

## How far along a racer is (-1 = you): you only count up to the next checkpoint you owe.
func progress(i: int) -> float:
	if i >= 0: return racers[i].track.dist
	if check_i >= checks.size(): return total + 1.0
	return minf(track.dist, float(checks[check_i]))

## The running order, as racer indexes (-1 = you): finished first, by time; then by distance.
func order() -> Array:
	var ids: Array = [-1]
	for i in racers.size(): ids.append(i)
	ids.sort_custom(func(a, b):
		var fa := finish_t.has(a)
		var fb := finish_t.has(b)
		if fa and fb: return float(finish_t[a]) < float(finish_t[b])
		if fa != fb: return fa
		return progress(a) > progress(b))
	return ids

func place() -> int:
	return order().find(-1) + 1

func _winnings() -> int:
	return purse(int(route.buy_in), racers.size() + 1) if finish_t.has(-1) and place() == 1 else 0

func _end() -> void:
	if state == "done": return
	state = "done"
	t = 0.0
	drive.clear_route()
	var won := _winnings()
	var st: Dictionary = drive.save.get("street", { "races": 0, "wins": 0 })
	st.races = int(st.races) + 1
	if won > 0: st.wins = int(st.wins) + 1
	drive.save.street = st
	if won > 0: drive.hud.post("YOU WIN. MARCO COUNTS OUT $%d LIKE IT HURTS HIM." % won, 6.0)
	elif finish_t.has(-1): drive.hud.post("P%d. MARCO: \"THERE'S ALWAYS NEXT FRIDAY.\"" % place(), 5.0)
	else: drive.hud.post("DNF. EVERYBODY ELSE IS ALREADY AT THE TIM'S.", 5.0)
	for a in racers: a.speed_cap = 11.0

## Everybody goes home.
func close() -> void:
	drive.traffic.hush = Rect2()
	for a in racers:
		drive.traffic.extra.erase(a)
		a.queue_free()
	racers.clear()
	if panel: panel.queue_free()

func _draw() -> void:
	if state == "done" or check_i >= checks.size(): return
	var p := track.point_at(float(checks[check_i]))
	var pulse := 0.5 + 0.5 * sin(t * 5.0)
	var last := check_i == checks.size() - 1
	var col := Color(1, 1, 1) if last else Color(0.3, 1.0, 0.5)
	draw_arc(p * CarArt.PX, CHECK_M * 0.6 * CarArt.PX, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.3 + 0.35 * pulse), 4.0)
	if last:
		# a chequered strip across the road at the line
		var d := track.dir_at(float(checks[check_i]))
		var rt := Vector2(-d.y, d.x)
		for i in 10:
			var a := (p + rt * (i - 5) * 1.2) * CarArt.PX
			draw_rect(Rect2(a, Vector2(1.2, 1.2) * CarArt.PX), Color.WHITE if i % 2 == 0 else Color.BLACK)


## The lights, the running order and the results.
class RaceHud extends Control:
	var race: StreetRace

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if race == null: return
		var gold := Color("d9a441")
		var bone := Color("f3ead2")
		var ash := Color("8a8478")
		if race.state == "grid":
			# tonight's field (down the left, out of the way of the cars), and the lights
			var card := Rect2(4, 102, 196, 14 + race.info.size() * 36)
			draw_rect(card, Color(0, 0, 0, 0.7))
			draw_rect(card, gold, false, 1.0)
			PixelFont.draw(self, card.position + Vector2(5, 4), "TONIGHT: %d LAP%s, $%d IN" % [int(race.route.laps), "" if int(race.route.laps) == 1 else "S", int(race.route.buy_in)], gold)
			for i in race.info.size():
				var y := card.position.y + 15 + i * 36
				PixelFont.draw(self, Vector2(card.position.x + 5, y), String(race.info[i].name).substr(0, 31), bone)
				PixelFont.draw(self, Vector2(card.position.x + 5, y + 8), String(race.info[i].car).substr(0, 31), gold.darkened(0.2))
				var ls := Hud.wrap_lines(String(race.info[i].line).to_upper(), 31)
				for li in mini(ls.size(), 2): PixelFont.draw(self, Vector2(card.position.x + 9, y + 17 + li * 8), ls[li], ash)
			var n := 3 - int(race.t - 1.0)
			var txt := "READY" if race.t < 1.0 else (str(n) if n >= 1 else "GO")
			PixelFont.draw_centered(self, 320, 120, txt, gold, 4, Color(0, 0, 0, 0.8))
		var order := race.order()
		# the running order, top left under the car panel, with the checkpoint and the clock
		var r := Rect2(4, 38, 196, 24 + order.size() * 9)
		draw_rect(r, Color(0, 0, 0, 0.55))
		var laps := int(race.route.laps)
		var lap := mini(laps, int(race.progress(-1) / maxf(race.total / laps, 1.0)) + 1)
		PixelFont.draw(self, r.position + Vector2(5, 4), "%s  LAP %d/%d" % [race.route.name, maxi(lap, 1), laps], gold)
		for i in order.size():
			var id: int = order[i]
			var who: String = "YOU" if id == -1 else String(race.info[id].name)
			PixelFont.draw(self, r.position + Vector2(5, 14 + i * 9), "%d. %s" % [i + 1, who.substr(0, 28)], bone if id == -1 else ash)
			if race.finish_t.has(id):
				var tail := StreetRace.clock_str(float(race.finish_t[id]))
				PixelFont.draw(self, r.position + Vector2(r.size.x - 5 - PixelFont.width(tail), 14 + i * 9), tail, bone)
		var cp := "CHECKPOINT %d/%d" % [mini(race.check_i + 1, race.checks.size()), race.checks.size()]
		PixelFont.draw(self, r.position + Vector2(5, r.size.y - 9), cp, ash)
		var ck := StreetRace.clock_str(race.clock)
		PixelFont.draw(self, r.position + Vector2(r.size.x - 5 - PixelFont.width(ck), r.size.y - 9), ck, bone)
		if race.state == "done":
			var p := race.place()
			var won := race._winnings()
			var title := "YOU WIN" if won > 0 else ("P%d" % p if race.finish_t.has(-1) else "DNF")
			PixelFont.draw_centered(self, 320, 110, title, gold, 4, Color(0, 0, 0, 0.8))
			if won > 0: PixelFont.draw_centered(self, 320, 150, "+$%d" % won, Color("6fbf5a"), 2, Color(0, 0, 0, 0.8))
