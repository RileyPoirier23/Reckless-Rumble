## The driving half of each story day: where you start, in what, when, in what weather, and
## what you have to do. MissionRunner (below) runs one inside the drive scene.
class_name StoryMissions
extends RefCounted

const COVINGTON := Vector2(5570, 1566)
const TIMS_MOUNTAIN := Vector2(5470, 1132)
const AIRSTRIP := Vector2(6640, 1022)

const MISSIONS := {
	"last_call": {
		"title": "LAST CALL",
		"car": "supreem", "start": Vector2(6280, 1000), "heading": PI / 2.0,
		"time": 1.6, "season": "fall", "weather": "drizzle", "impaired": 0.85,
		"intro": ["YOU'RE DRUNK. YOU'RE HIGH. THE ROAD IS MOVING.", "MIKEY: \"TEXT ME WHEN UR HOME\""],
		"objectives": [{ "text": "GET HOME. (COVINGTON AUTO)", "to": COVINGTON, "radius": 20.0, "crash_ends": true, "max_time": 34.0 }],
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
		# the prologue ends the way it has to: in somebody's car
		if o.get("crash_ends", false):
			var hit: float = car.damage.front + car.damage.left + car.damage.right + car.damage.rear
			if hit > 0.25 or obj_t > float(o.get("max_time", 999.0)) or (car.sim.speed() > 33.0 and obj_t > 8.0):
				_end_text = "..."
				_end_t = 1.2
				done = true
				Controls.rumble(1.0, 1.0, 0.8)
				return
		if car.sim.pos.distance_to(o.to) < float(o.radius) and (not o.get("stop", false) or car.sim.speed() < 2.0):
			if o.get("careful", false):
				var dmg: float = car.damage.front + car.damage.left + car.damage.right + car.damage.rear
				var cost := int(dmg * 2500.0)
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
