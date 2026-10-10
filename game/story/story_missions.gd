## The driving half of each story day: where you start, in what, when, in what weather, and
## what you have to do. MissionRunner (below) runs one inside the drive scene.
class_name StoryMissions
extends RefCounted

const COVINGTON := Vector2(5570, 1566)
const TIMS_MOUNTAIN := Vector2(5470, 1132)
const AIRSTRIP := Vector2(6640, 1022)
const AIRSTRIP_FENCE := Vector2(6620, 1034)     # where Airstrip Rd ends at the runway: the Familia's meet is on the other side
# the Mountain: Mountain Rd climbs from Main to the hairpin, then Magnet Hill Rd goes over the hill
const MOUNTAIN_FOOT := Vector2(5950, 1545)
const HAIRPIN := Vector2(5180, 860)
const HILL_TOP := Vector2(5000, 720)
const GENERAL := Vector2(6005, 1500)          # the Port Rumble General's emergency doors, on John St by the Rumble Centre

const MISSIONS := {
	"last_call": {
		"title": "LAST CALL",
		"car": "supreem", "start": Vector2(6280, 1000), "heading": -PI / 2.0,      # facing the way the shortcut goes
		"time": 1.6, "season": "fall", "weather": "drizzle", "impaired": 0.85,
		"intro": ["YOU'RE DRUNK. YOU'RE HIGH. THE ROAD IS MOVING.", "MIKEY: \"TEXT ME WHEN UR HOME\"", "THE SHORTCUT HOME IS AIRSTRIP RD, PAST THE OLD RUNWAY. PROBABLY."],
		# the prologue ends the way it has to: through the fence at the end of Airstrip Rd, into the
		# Familia's meet. A crash anywhere before that, Leo blacks out and comes to back on the road.
		"objectives": [{ "text": "GET HOME. THE SHORTCUT: AIRSTRIP RD, PAST THE OLD RUNWAY.", "to": AIRSTRIP_FENCE, "radius": 16.0, "crash_at": true }],
	},
	"runs_great": {
		"title": "RUNS GREAT",
		"car": "tow", "start": Vector2(5570, 1566), "heading": -PI / 2.0,
		"time": 18.2, "season": "fall", "weather": "clear",
		"intro": ["TOBY'S WRECKER. DON'T TOUCH THE BOOM.", "MEET THE SELLER AT THE TIM BURTONS ON MOUNTAIN RD."],
		"objectives": [{ "text": "MEET THE SELLER AT TIM BURTONS (MOUNTAIN RD). STOP IN THE LOT.", "to": TIMS_MOUNTAIN, "radius": 18.0, "stop": true }],
	},
	"drive_it_home": {
		"title": "IT RUNS. GREAT.",
		"car": "silvio", "start": Vector2(5470, 1130), "heading": -PI / 2.0,
		"time": 22.4, "season": "fall", "weather": "cloudy", "gasket": true,
		"intro": ["YOUR CAR. $840. IT'S LEAKING SOMETHING.", "GET IT HOME BEFORE IT GETS HOT."],
		"objectives": [{ "text": "DRIVE IT HOME TO COVINGTON AUTO. STOP AT THE BAY DOORS.", "to": COVINGTON, "radius": 14.0, "stop": true }],
	},
	# ------------------------------------------------------------------ the finale
	"long_way_down": {
		"title": "THE LONG WAY DOWN",
		"car": "supreem", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 23.9, "season": "winter", "weather": "snow", "tires": "winter",
		"intro": ["GUS REBUILT DAD'S SUPREEM. IT TOOK HIM SIX WINTERS.", "FRANKIE'S AT THE TIM BURTONS ON MOUNTAIN RD. DON'T LET HIM DRIVE THAT CAR ANOTHER METRE."],
		"objectives": [{ "text": "GET TO FRANKIE: THE TIM BURTONS ON MOUNTAIN RD. STOP IN THE LOT. TREMBLAY'S ON HER WAY.", "to": TIMS_MOUNTAIN, "radius": 18.0, "stop": true }],
	},
	"snowbank": {
		"title": "SNOWBANK",
		"car": "supreem", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 23.9, "season": "winter", "weather": "snow", "tires": "winter",
		"intro": ["FRANKIE'S IN A SNOWBANK AT THE HAIRPIN. HIS ARM'S BENT WRONG.", "QUICK. NOT STUPID."],
		"objectives": [
			{ "text": "GET TO FRANKIE: THE SNOWBANK AT THE HAIRPIN, THE TOP OF MOUNTAIN RD.", "to": HAIRPIN, "radius": 22.0, "stop": true },
			{ "text": "GET HIM TO THE PORT RUMBLE GENERAL, ON JOHN ST BY THE RUMBLE CENTRE. QUICK. NOT STUPID.", "to": GENERAL, "radius": 22.0, "stop": true },
		],
	},
	"the_mountain": {
		"title": "THE MOUNTAIN",
		"car": "supreem", "start": MOUNTAIN_FOOT, "heading": -2.2524,         # facing up Mountain Rd
		"time": 23.0, "season": "winter", "weather": "snow", "tires": "winter",
		"intro": ["HATCH'S CHARJER, UP MOUNTAIN RD, LIKE EVERY NIGHT.", "TREMBLAY: \"LEO. DON'T.\""],
		# a chase: he drives the road to the top of the hill; catch him first (ram him, or sit on
		# his bumper long enough that he's got nowhere to go)
		"objectives": [{ "text": "CATCH DALE HATCH BEFORE HE'S OVER THE HILL.", "to": HILL_TOP, "radius": 25.0,
			"chase": { "car": "charjer", "paint": "#16161c", "start": Vector2(5868, 1444), "heading": -2.2524, "skill": 0.78, "cap": 30.0, "tires": "winter" } }],
	},
	"detailing": {
		"title": "DETAILING",
		"car": "silvio", "start": Vector2(5570, 1566), "heading": -PI / 2.0,
		"time": 20.8, "season": "fall", "weather": "fog",
		"intro": ["MIA: \"AIRSTRIP 7. BLACK CHARJER. BAY 3. NOT A SCRATCH.\""],
		"objectives": [
			{ "text": "GO TO AIRSTRIP 7 AND PICK UP THE FAMILIA'S CHARJER.", "to": AIRSTRIP, "radius": 22.0, "stop": true, "swap": "charjer" },
			{ "text": "BRING IT TO COVINGTON AUTO. NOT A SCRATCH: EVERY DENT COMES OFF YOUR DEBT, THE WRONG WAY.", "to": COVINGTON, "radius": 14.0, "stop": true, "careful": true },
		],
	},
}


## Runs a mission inside the drive scene: objective text, the GPS route, the marker on the
## ground, the rules (stop here, don't crash, don't take too long) and what happens after.
class MissionRunner extends Node2D:
	var drive: Node
	var m: Dictionary
	var k := 0                    # which objective
	var t := 0.0
	var obj_t := 0.0
	var done := false
	var _intro_i := 0
	var _end_t := -1.0
	var _end_text := ""
	var _hit_seen := 0.0              # damage already blacked out for
	var target: AiCar                 # the car being chased (a "chase" objective)
	var _close_t := 0.0               # seconds spent right on its bumper

	func setup(the_drive: Node, mission: Dictionary) -> void:
		drive = the_drive
		m = mission
		z_index = 3050
		z_as_relative = false
		_route()

	func objective() -> Dictionary:
		return m.objectives[k] if k < (m.objectives as Array).size() else {}

	func _route() -> void:
		var o := objective()
		if o.is_empty(): return
		drive._on_dest(String(o.text).split(".")[0], o.to)
		drive.hud.objective = String(o.text)

	func _process(dt: float) -> void:
		t += dt
		obj_t += dt
		queue_redraw()
		if _end_t >= 0.0:
			_end_t -= dt
			drive.flash_rect.color = Color(1, 1, 1, clampf(1.0 - _end_t, 0.0, 1.0))
			if _end_t <= 0.0: _finish()
			return
		var intro: Array = m.get("intro", [])
		if _intro_i < intro.size() and t > 0.6 + _intro_i * 2.2:
			drive.hud.post(String(intro[_intro_i]), 5.0)
			_intro_i += 1
		var o := objective()
		if o.is_empty() or done: return
		var car: PlayerCar = drive.car
		if o.has("chase"):
			_chase(dt, o, car)
			return
		if o.get("crash_at", false):
			# the end of the road: through the fence, into the meet
			if car.sim.pos.distance_to(o.to) < float(o.radius):
				_end_text = "..."
				_end_t = 1.2
				done = true
				Controls.rumble(1.0, 1.0, 0.8)
				return
			# anywhere else, a black-out: back on the road a little way before it, and keep going
			var hit: float = car.damage.front + car.damage.left + car.damage.right + car.damage.rear
			if hit - _hit_seen > 0.25:
				_hit_seen = hit
				_black_out(car)
				return
		if car.sim.pos.distance_to(o.to) < float(o.radius) and (not o.get("stop", false) or car.sim.speed() < 2.0):
			if o.get("careful", false):
				var dmg: float = car.damage.front + car.damage.left + car.damage.right + car.damage.rear
				var cost := int(dmg * 2500.0)
				Karma.deed("careless" if cost > 0 else "careful")
				if cost > 0:
					StoryState.debt += cost
					drive.hud.post("MIA ADDS $%d TO YOUR DEBT. FOR THE SCRATCHES." % cost, 5.0)
				else:
					StoryState.debt -= 300
					drive.hud.post("NOT A SCRATCH. MIA TAKES $300 OFF. SHE ALMOST SMILES.", 5.0)
				StoryState.last_result = { "careful_damage": dmg }
			if o.has("swap"):
				drive._swap_story_car(String(o.swap))
			k += 1
			obj_t = 0.0
			if k >= (m.objectives as Array).size():
				done = true
				_end_t = 1.0
			else:
				_route()

	## A chase: the target drives its road to the objective's end. Ram it, or stay right on it for
	## two and a half seconds and it's over. Let it get over the hill (or lose it), and it's back to the start.
	func _chase(dt: float, o: Dictionary, car: PlayerCar) -> void:
		if target == null: _spawn_target(o)
		var d := car.sim.pos.distance_to(target.sim.pos)
		var rammed := car.last_hit == target and Engine.get_physics_frames() - car.hit_frame < 4 and car.sim.speed() > 5.0
		_close_t = _close_t + dt if d < 10.0 else maxf(0.0, _close_t - dt * 0.5)
		drive.hud.objective = "%s   HATCH: %d M AHEAD" % [String(o.text), int(d)]
		if rammed or _close_t > 2.5:
			target.hold = true
			done = true
			_end_t = 1.0
			Controls.rumble(1.0, 1.0, 0.6)
			return
		if target.sim.pos.distance_to(o.to) < float(o.radius) or d > 650.0:
			drive.hud.post("HE'S OVER THE HILL. HE COMES BACK DOWN EVERY NIGHT, LEO. AGAIN." if d <= 650.0 else "YOU LOST HIM. AGAIN.", 5.0)
			target.queue_free()
			drive.traffic.extra.erase(target)
			target = null
			_close_t = 0.0
			drive._teleport(m.start, float(m.heading))
			drive.white_out = 1.0

	func _spawn_target(o: Dictionary) -> void:
		var c: Dictionary = o.chase
		target = AiCar.new()
		drive.ysort.add_child(target)
		var spec := SaveGame.load_spec(String(c.car))
		spec.paint = String(c.get("paint", spec.get("paint", "#16161c")))
		spec.name = "DALE HATCH"
		target.setup_ai(spec, drive.world, drive.skids, drive.hud, c.start, float(c.get("heading", 0.0)), 70)
		target.traffic = drive.traffic
		target.skill = float(c.get("skill", 0.8))
		target.speed_cap = float(c.get("cap", 30.0))
		if c.has("tires"): target.sim.compound = String(c.tires)
		target.others = [drive.car]
		# his road starts where he is: the router starts at the nearest junction, which can be
		# behind him (and he'd turn round for it)
		var fwd := Vector2.from_angle(float(c.get("heading", 0.0)))
		var r: PackedVector2Array = drive.world.map.route_to(c.start, o.to)
		var path := PackedVector2Array([c.start])
		var ahead := false
		for p in r:
			if not ahead and (p - (c.start as Vector2)).dot(fwd) < 5.0: continue
			ahead = true
			path.append(p)
		target.set_path(path, false, 10.0)
		drive.traffic.extra.append(target)

	## A crash on the way: the screen goes white, and Leo is back on the road behind where it
	## happened, stopped, facing the right way.
	func _black_out(car: PlayerCar) -> void:
		var route: PackedVector2Array = drive.gps.route
		var at := car.sim.pos
		var h := car.sim.heading
		if route.size() >= 2:
			var k := 0
			for i in route.size():
				if route[i].distance_squared_to(car.sim.pos) < route[k].distance_squared_to(car.sim.pos): k = i
			var back := maxi(0, k - 1)
			var nxt := mini(route.size() - 1, back + 1)
			at = route[back].lerp(route[nxt], 0.3)
			h = (route[nxt] - route[back]).angle()
		drive._teleport(at, h)
		car.sim.set_world_velocity(Vector2.ZERO)
		drive.white_out = 1.0
		drive.hud.post("YOU BLACK OUT FOR A SECOND. WHEN YOU COME TO, YOU'RE STILL ON THE ROAD. SOMEHOW.", 5.0)
		Controls.rumble(0.8, 0.8, 0.5)

	func _finish() -> void:
		drive.hud.objective = ""
		StoryState.advance(get_tree())

	func _draw() -> void:
		var o := objective()
		if o.is_empty() or done: return
		# a ring on the ground where you're going
		var p: Vector2 = o.to * CarArt.PX
		var r := float(o.radius) * CarArt.PX
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		draw_arc(p, r, 0.0, TAU, 48, Color(1.0, 0.75, 0.2, 0.35 + 0.3 * pulse), 4.0)
		draw_arc(p, r * 0.6, 0.0, TAU, 32, Color(1.0, 0.75, 0.2, 0.2), 2.0)
