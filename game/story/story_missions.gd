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
const GENERAL := Vector2(6005, 1500)
const BRY_SHOP := Vector2(6316, 921)           # Bry's Fjord Service, on its lot off Industrial Dr          # the Port Rumble General's emergency doors, on John St by the Rumble Centre
# runway 7: Dom's line, and his cones an eighth of a mile on
const RUNWAY_LINE := Vector2(6612, 1028)
const RUNWAY_END := Vector2(6813, 1028)
const COVERDALE := Vector2(5200, 1882)        # a car in the ditch on Coverdale Rd
const CHAMPAGNE := Vector2(6660, 1270)        # the back row at Champagne Place
const BRIDGE := Vector2(6110, 1600)           # the Gunningsville Bridge
const SCHOOL := Vector2(5840, 1850)           # Port Rumble High, in Riverside
const MINISTRY := Vector2(6250, 1505)         # the Ministry office on Main
const WAREHOUSE := Vector2(6280, 1000)        # Industrial Dr, outside the warehouse
const S_BEND := Vector2(5600, 1180)           # Mountain Rd, the S-bend below the Tim Burtons

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
	# ------------------------------------------------------------------ the first winter
	"launch_control": {
		"title": "LAUNCH CONTROL",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 21.9, "season": "fall", "weather": "clear",
		"intro": ["DOM'S LESSON. RUNWAY 7, TEN O'CLOCK.", "MIA: \"DON'T BE LATE. HE SAYS GRACE WHETHER YOU'RE THERE OR NOT.\""],
		"objectives": [
			{ "text": "GO TO AIRSTRIP 7. DOM'S WAITING ON RUNWAY 7.", "to": AIRSTRIP, "radius": 22.0, "stop": true },
			# Dom's eighth-mile: stage, wait for the tree, go. Under his times for a medal.
			{ "text": "DOM'S EIGHTH-MILE: WAIT FOR GREEN, THEN FLAT OUT TO THE CONES.", "to": RUNWAY_END, "radius": 20.0, "drag": true,
				"from": RUNWAY_LINE, "medals": [10.9, 11.6, 13.0] },
		],
	},
	"fjord_run": {
		"title": "THE WATER PUMP",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 16.4, "season": "fall", "weather": "cloudy",
		"intro": ["GUS: \"BRY'S. INDUSTRIAL DRIVE, NORTHSIDE. HE'S GOT THE PUMP. DON'T LET HIM START.\"", "GUS: \"HE'LL START.\""],
		"objectives": [
			{ "text": "BRY'S FJORD SERVICE, ON INDUSTRIAL DR. PULL ONTO THE LOT AND STOP.", "to": BRY_SHOP, "radius": 16.0, "stop": true },
			{ "text": "BACK TO COVINGTON AUTO WITH THE PUMP. GUS IS WAITING ON IT.", "to": COVINGTON, "radius": 20.0, "stop": true },
		],
	},
	"night_shift": {
		"title": "TOBY'S NIGHT SHIFT",
		"car": "tow", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 1.9, "season": "fall", "weather": "freezing",
		"intro": ["TOBY: \"YOU DRIVE. I'M EATING.\"", "A CAR IN THE DITCH ON COVERDALE RD. FREEZING RAIN. TAKE IT EASY ON THE BRIDGE."],
		"objectives": [
			{ "text": "THE CAR IN THE DITCH ON COVERDALE RD. STOP BESIDE IT.", "to": COVERDALE, "radius": 20.0, "stop": true },
			{ "text": "TOBY: \"COFFEE. THE TIM BURTONS ON MOUNTAIN RD. I'M BUYING.\"", "to": TIMS_MOUNTAIN, "radius": 18.0, "stop": true },
		],
	},
	"johnny_tram": {
		"title": "JOHNNY TRAM",
		"car": "silvio", "start": CHAMPAGNE, "heading": PI,
		"time": 23.2, "season": "fall", "weather": "cloudy",
		"intro": ["THE BACK STREETS TO THE GUNNINGSVILLE BRIDGE. FIRST ONE THERE.", "MIKEY: \"I BELIEVE IN YOU. I'M ALSO FILMING.\""],
		"objectives": [{ "text": "BEAT JOHNNY TRAM TO THE GUNNINGSVILLE BRIDGE.", "to": BRIDGE, "radius": 25.0,
			"race": { "car": "hondo_civil_ess_eye_1999", "paint": "#e8e8ec", "name": "JOHNNY TRAM", "start": Vector2(6660, 1262), "heading": PI, "skill": 0.74, "cap": 33.0 } }],
	},
	"anniversary": {
		"title": "ONE YEAR",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 23.4, "season": "winter", "weather": "snow",
		"intro": ["DECEMBER 6. THE FIRST SNOW.", "UP MOUNTAIN RD, TO THE HAIRPIN."],
		"objectives": [{ "text": "DRIVE UP MOUNTAIN RD TO THE HAIRPIN. STOP AT THE GUARDRAIL.", "to": HAIRPIN, "radius": 22.0, "stop": true }],
	},
	# ------------------------------------------------------------------ the years in between
	"principals_office": {
		"title": "THE PRINCIPAL'S OFFICE",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 14.5, "season": "fall", "weather": "drizzle",
		"intro": ["THE SCHOOL CALLED. ARIES HIT A KID.", "YOU LEFT THE COUNTER IN THE MIDDLE OF A SHIFT. GUS IS NOT HAPPY."],
		"objectives": [
			{ "text": "GET ARIES: PORT RUMBLE HIGH, IN RIVERSIDE. STOP OUT FRONT.", "to": SCHOOL, "radius": 22.0, "stop": true },
			{ "text": "TAKE HER HOME. SHE'S IN THE CAR NOW: DRIVE LIKE IT. ONE HIT AND YOU START AGAIN.", "to": COVINGTON, "radius": 14.0, "stop": true, "gentle": true,
				"gentle_fail": "ARIES: \"LEO.\" YOU HIT SOMETHING. START THAT AGAIN." },
		],
	},
	"road_test": {
		"title": "THE ROAD TEST",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 9.6, "season": "spring", "weather": "clear",
		"intro": ["ARIES'S ROAD TEST IS AT TEN. SHE'S QUIZZING YOU ON STOP SIGNS.", "ARIES: \"FULL STOP. FULL. NOT A LEO STOP.\""],
		"objectives": [{ "text": "THE MINISTRY OFFICE ON MAIN. NOT A SCRATCH: SHE'LL NEVER LET YOU HEAR THE END OF IT.", "to": MINISTRY, "radius": 20.0, "stop": true,
			"gentle": true, "gentle_fail": "ARIES: \"OH MY GOD.\" YOU HIT SOMETHING. START AGAIN." }],
	},
	"seatbelt": {
		"title": "SEATBELT",
		"car": "silvio", "start": WAREHOUSE, "heading": -PI / 2.0,
		"time": 1.3, "season": "summer", "weather": "rain", "impaired": 0.6,
		"intro": ["ARIES: \"SEATBELT.\"", "YOU'RE DRUNK. SHE KNOWS IT. SHE GOT IN ANYWAY.", "HOME. THE LONG WAY, UP MOUNTAIN RD, BECAUSE YOU'RE NOT THINKING."],
		"objectives": [{ "text": "HOME. ARIES IS IN THE PASSENGER SEAT.", "to": S_BEND, "radius": 24.0, "crash_at": true }],
	},
	"the_fox": {
		"title": "RAN WHEN PARKED",
		"car": "tow", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 17.6, "season": "spring", "weather": "cloudy",
		"intro": ["DARRELL'S AT THE TIM BURTONS ON MOUNTAIN RD. WITH THE FOX ON A TRAILER. OF COURSE.", "BRING CASH. HE DOESN'T DO E-TRANSFERS. HE SAYS THEY'RE A GOVERNMENT THING."],
		"objectives": [
			{ "text": "PICK UP THE FOX FROM DARRELL AT THE TIM BURTONS ON MOUNTAIN RD.", "to": TIMS_MOUNTAIN, "radius": 18.0, "stop": true },
			{ "text": "BRING THE FOX HOME TO COVINGTON AUTO. GENTLY: WHATEVER HAPPENED TO IT, IT'S STILL ON IT.", "to": COVINGTON, "radius": 14.0, "stop": true,
				"gentle": true, "gentle_fail": "THE FOX BANGS ON THE HOOK. GUS WOULD KILL YOU. GO BACK AND DO THAT AGAIN." },
		],
	},
	"gus_heart": {
		"title": "THE GENERAL",
		"car": "silvio", "start": COVINGTON, "heading": -PI / 2.0,
		"time": 0.2, "season": "fall", "weather": "clear",
		"intro": ["GUS IS IN THE PASSENGER SEAT. HE'S GREY.", "GUS: \"DON'T YOU DARE SPEED.\"", "GUS: \"...OKAY. SPEED A LITTLE.\""],
		"objectives": [{ "text": "THE PORT RUMBLE GENERAL, ON JOHN ST BY THE RUMBLE CENTRE. QUICK. NOT STUPID.", "to": GENERAL, "radius": 22.0, "stop": true }],
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
			{ "text": "GO TO AIRSTRIP 7 AND PICK UP THE FAMILIA'S CHARJER.", "to": AIRSTRIP, "radius": 22.0, "stop": true, "swap": "charjer",
				"handler": "DOM", "coat": "#16161c", "handover": ["\"THE CHARJER. BAY THREE. NOT A SCRATCH.\"", "\"YOUR HONDO STAYS WITH ME. YOU'LL GET IT BACK. PROBABLY.\""] },
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
	var target: AiCar                 # the car being chased (a "chase" objective), or raced (a "race")
	var _close_t := 0.0               # seconds spent right on its bumper
	# where this objective started (a "gentle" one goes back here after a hit, a race restarts here)
	var _o_set := false
	var _o_at := Vector2.ZERO
	var _o_head := 0.0
	var _o_dmg := 0.0
	var _go_t := -1.0                 # a drag run or a race: seconds since the countdown started (-1: not yet)
	var _hand := ""                   # a handover: "" none, "walk" (they're coming over), "talk", "swap", "away"
	var _hand_t := 0.0
	var _hand_car: AiCar              # the car being handed over (then the one you left)
	var _hand_who: Police.Officer
	var _hand_lines: Array = []
	var _run_t := 0.0                 # a drag run: the clock since green

	func setup(the_drive: Node, mission: Dictionary) -> void:
		drive = the_drive
		m = mission
		z_index = 3050
		z_as_relative = false
		_route()

	func objective() -> Dictionary:
		return m.objectives[k] if k < (m.objectives as Array).size() else {}

	func _route() -> void:
		_o_set = false
		_go_t = -1.0
		var o := objective()
		if o.is_empty(): return
		# a drag run's cones are straight down the runway: no GPS line wandering off round town
		if not o.get("drag", false): drive._on_dest(String(o.text).split(".")[0], o.to)
		drive.hud.objective = String(o.text)

	static func damage_of(car: PlayerCar) -> float:
		return car.damage.front + car.damage.left + car.damage.right + car.damage.rear

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
		if _hand != "":
			_handover_step(dt)
			return
		var car: PlayerCar = drive.car
		if not _o_set:
			_o_set = true
			_o_at = car.sim.pos
			_o_head = car.sim.heading
			_o_dmg = damage_of(car)
		if o.has("chase"):
			_chase(dt, o, car)
			return
		if o.get("drag", false):
			_drag(dt, o, car)
			return
		if o.has("race") and not _race(dt, o, car): return
		if o.get("gentle", false) and damage_of(car) - _o_dmg > 0.04:
			# a hit with somebody in the car who matters: back to where this leg started
			drive._teleport(_o_at, _o_head)
			drive.white_out = 1.0
			drive.hud.post(String(o.get("gentle_fail", "YOU HIT SOMETHING. START AGAIN.")), 5.0)
			_o_dmg = damage_of(car)
			Controls.rumble(0.6, 0.6, 0.3)
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
				_handover(o)
				return
			_next_objective()

	## Picking a car up: it's parked ahead, somebody walks the keys over to your window, says their
	## piece, you get out and into it, and they drive yours away. No teleporting into a car.
	func _handover(o: Dictionary) -> void:
		var car: PlayerCar = drive.car
		_hand = "walk"
		_hand_t = 0.0
		_hand_lines = o.get("handover", ["\"KEYS. NOT A SCRATCH.\""])
		drive.hold_car = true
		car.sim.vx = 0.0
		var spec := SaveGame.load_spec(String(o.swap))
		if o.has("paint"): spec.paint = String(o.paint)
		var at: Vector2 = car.sim.pos + car.sim.forward() * 8.0 + car.sim.right() * 3.2
		_hand_car = AiCar.new()
		drive.ysort.add_child(_hand_car)
		_hand_car.setup_ai(spec, drive.world, drive.skids, drive.hud, at, car.sim.heading, 80)
		_hand_car.traffic = drive.traffic
		_hand_car.hold = true
		drive.traffic.extra.append(_hand_car)
		_hand_who = Police.Officer.new()
		_hand_who.civilian = true
		_hand_who.coat = Color(String(o.get("coat", "#16161c")))
		_hand_who.name_on = String(o.get("handler", "THEM"))
		_hand_who.night = drive.night
		drive.ysort.add_child(_hand_who)
		_hand_who.pos = at - _hand_car.sim.right() * (float(spec.width) * CarArt.CAR_SCALE * 0.5 + 0.5)
		_hand_who.heading = (car.sim.pos - _hand_who.pos).angle()
		drive.hud.post("%s GETS OUT OF THE %s AND WALKS OVER." % [_hand_who.name_on, String(spec.get("model", "CAR")).to_upper()], 4.0)

	func _handover_step(dt: float) -> void:
		var car: PlayerCar = drive.car
		_hand_t += dt
		match _hand:
			"walk":
				var window: Vector2 = car.sim.pos - car.sim.right() * (float(car.spec.width) * CarArt.CAR_SCALE * 0.5 + 0.6) + car.sim.forward() * 0.2
				if _hand_who.walk_to(window, 1.5, dt) or _hand_t > 14.0:
					_hand = "talk"
					_hand_t = 0.0
					_hand_who.heading = (car.sim.pos - _hand_who.pos).angle()
					for i in _hand_lines.size(): drive.hud.post("%s: %s" % [_hand_who.name_on, String(_hand_lines[i])], 3.0 + 2.4 * (_hand_lines.size() - i))
			"talk":
				if _hand_t > 1.6 + 2.4 * _hand_lines.size():
					# the keys change hands: a beat of white, and you're in the other seat
					_hand = "swap"
					_hand_t = 0.0
					drive.white_out = 1.0
					var old_spec: Dictionary = car.spec.duplicate(true)
					var old_at: Vector2 = car.sim.pos
					var old_h: float = car.sim.heading
					var new_at: Vector2 = _hand_car.sim.pos
					var new_h: float = _hand_car.sim.heading
					var id := String(_hand_car.spec.get("id", ""))
					drive.traffic.extra.erase(_hand_car)
					_hand_car.queue_free()
					drive._spawn_story_car(id, new_at, new_h)
					drive._teleport(new_at, new_h)
					# the one you came in stays where you left it, and they take it
					_hand_car = AiCar.new()
					drive.ysort.add_child(_hand_car)
					_hand_car.setup_ai(old_spec, drive.world, drive.skids, drive.hud, old_at, old_h, 81)
					_hand_car.traffic = drive.traffic
					_hand_car.hold = true
					drive.traffic.extra.append(_hand_car)
			"swap":
				if _hand_t > 0.6:
					_hand = "away"
					_hand_t = 0.0
			"away":
				var door: Vector2 = _hand_car.sim.pos - _hand_car.sim.right() * (float(_hand_car.spec.width) * CarArt.CAR_SCALE * 0.5 + 0.5)
				if _hand_who.walk_to(door, 1.4, dt) or _hand_t > 12.0:
					_hand_who.queue_free()
					_hand_who = null
					_hand = ""
					drive.hold_car = false
					_next_objective()

	func _next_objective() -> void:
		k += 1
		obj_t = 0.0
		if k >= (m.objectives as Array).size():
			done = true
			_end_t = 1.0
		else:
			_route()

	## Dom's eighth-mile: the car's put on the line, the tree counts down (amber, amber, amber,
	## green), and the clock runs from green to the cones. Rolling before green is a red light;
	## slower than the last medal time, or stopping short, and it's back to the line.
	func _drag(dt: float, o: Dictionary, car: PlayerCar) -> void:
		var medals: Array = o.get("medals", [11.0, 12.0, 13.0])
		if _go_t < 0.0:
			drive._teleport(o.get("from", car.sim.pos), (o.to - o.get("from", car.sim.pos)).angle())
			_go_t = 0.0
			_run_t = 0.0
		_go_t += dt
		var tree := 2.4
		if _go_t < tree:
			var lit := int(_go_t / 0.8) + 1
			drive.hud.objective = "%s   %s" % [String(o.text), "AMBER  ".repeat(lit).strip_edges()]
			if car.sim.speed() > 1.0:
				drive.hud.post("RED LIGHT. YOU WENT BEFORE GREEN. DOM: \"AGAIN.\"", 4.0)
				_go_t = -1.0
			return
		_run_t += dt
		drive.hud.objective = "GREEN.   %.2f S" % _run_t
		var past: bool = (car.sim.pos - o.from).dot((o.to - o.from).normalized()) >= (o.to - o.from).length()
		if past:
			var tier := ""
			for i in medals.size():
				if _run_t <= float(medals[i]):
					tier = ["gold", "silver", "bronze"][i]
					break
			if tier == "":
				drive.hud.post("%.2f S. TOO SLOW FOR A MEDAL. DOM: \"AGAIN.\"" % _run_t, 5.0)
				_go_t = -1.0
				return
			for t2 in ["gold", "silver", "bronze"]: StoryState.flags.erase("launch_" + t2)
			StoryState.set_flag("launch_" + tier)
			StoryState.last_result = { "eighth": _run_t, "medal": tier }
			drive.hud.post("%.2f S. %s." % [_run_t, tier.to_upper()], 5.0)
			_next_objective()
		elif _run_t > float(medals[medals.size() - 1]) + 4.0:
			drive.hud.post("THAT'S NOT A RUN, KID. BACK TO THE LINE.", 4.0)
			_go_t = -1.0

	## A race: the rival waits for the count, then drives his road to the objective. Get there
	## first and it's yours (true: carry on to the usual arrival check); let him and it's back to
	## the start, both of you.
	func _race(dt: float, o: Dictionary, car: PlayerCar) -> bool:
		var r: Dictionary = o.race
		if target == null:
			_spawn_target(r, o.to)
			target.hold = true
			_go_t = 0.0
		if _go_t >= 0.0:
			_go_t += dt
			var left := 3 - int(_go_t)
			drive.hud.objective = "%s   %s" % [String(o.text), str(left) if left > 0 else "GO"]
			if _go_t >= 3.0:
				target.hold = false
				_go_t = -1.0
			return car.sim.pos.distance_to(o.to) < float(o.radius)
		var mine := car.sim.pos.distance_to(o.to)
		var his := target.sim.pos.distance_to(o.to)
		drive.hud.objective = "%s   %s" % [String(o.text), "YOU'RE AHEAD" if mine < his else "%s IS AHEAD" % String(r.get("name", "HE"))]
		if his < float(o.radius) and mine >= float(o.radius):
			drive.hud.post("%s GOT THERE FIRST. BACK TO THE START." % String(r.get("name", "HE")), 5.0)
			_drop_target()
			drive._teleport(_o_at, _o_head)
			drive.white_out = 1.0
			return false
		if mine < float(o.radius):
			_drop_target()
			return true
		return false

	func _drop_target() -> void:
		if target == null: return
		target.queue_free()
		drive.traffic.extra.erase(target)
		target = null

	## A chase: the target drives its road to the objective's end. Ram it, or stay right on it for
	## two and a half seconds and it's over. Let it get over the hill (or lose it), and it's back to the start.
	func _chase(dt: float, o: Dictionary, car: PlayerCar) -> void:
		if target == null: _spawn_target(o.chase, o.to)
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
			_drop_target()
			_close_t = 0.0
			drive._teleport(m.start, float(m.heading))
			drive.white_out = 1.0

	func _spawn_target(c: Dictionary, to: Vector2) -> void:
		target = AiCar.new()
		drive.ysort.add_child(target)
		var spec := SaveGame.load_spec(String(c.car))
		spec.paint = String(c.get("paint", spec.get("paint", "#16161c")))
		spec.name = String(c.get("name", "DALE HATCH"))
		target.setup_ai(spec, drive.world, drive.skids, drive.hud, c.start, float(c.get("heading", 0.0)), 70)
		target.traffic = drive.traffic
		target.skill = float(c.get("skill", 0.8))
		target.speed_cap = float(c.get("cap", 30.0))
		if c.has("tires"): target.sim.compound = String(c.tires)
		target.sim.warm_tires()
		target.others = [drive.car]
		# his road starts where he is: the router starts at the nearest junction, which can be
		# behind him (and he'd turn round for it)
		var fwd := Vector2.from_angle(float(c.get("heading", 0.0)))
		var r: PackedVector2Array = drive.world.map.route_to(c.start, to)
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
