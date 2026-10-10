## Crash scene screenshots: two cars tangled, then the police, ambulance and fire truck rolling in,
## the cones out and the lane shut: godot --path game -- --incident-demo <out_dir>
extends Node

var main: Node
var out := "user://incident_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--incident-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	var inc: Incidents = main.incidents
	var info := ""
	for sc in inc.scenes:
		info += "%s t=%.0f units=%d parked=%d cones=%d wrecks=%d  " % [sc.phase, sc.t, sc.units.size(), sc.parked.filter(func(p): return is_instance_valid(p[0]) and p[0].hold).size(), sc.cones.size(), sc.wrecks.size()]
	print("shot ", name, "  ", info)

func _run() -> void:
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 19.4
	main.hold_car = true
	var inc: Incidents = main.incidents
	inc.enabled = false              # only the one we make
	await _wait(1.0)
	var sc: Incidents.Scene = null
	for i in 10:
		sc = inc.stage(main.car.sim.pos)
		if sc: break
	if sc == null:
		print("no scene")
		get_tree().quit()
		return
	# watch from across the road, a little back from the wreck
	var map: MapData = main.world.map
	var dir: Vector2 = (map.g_pos[sc.b] - map.g_pos[sc.a]).normalized()
	main._teleport(sc.at - dir * 22.0 + dir.orthogonal() * 4.0, dir.angle())
	print("scene at ", sc.at, " lane ", sc.lane, " road ", sc.road)
	await _wait(2.0)
	main.hud.msgs.clear()
	await _shot("1_crash")
	Engine.time_scale = 4.0
	var t := 0.0
	var shot_rolling := false
	while t < 30.0 and sc.phase != "working":
		await _wait(0.5)
		t += 0.5
		if int(t * 2) % 10 == 0:
			for i in sc.parked.size():
				var u: AiCar = sc.parked[i][0]
				if is_instance_valid(u): print("  t%.0f unit%d d_stop=%.0f v=%.1f hold=%s track_valid=%s done=%s pathpts=%d" % [t, i, u.sim.pos.distance_to(sc.parked[i][1]), u.sim.speed(), u.hold, u.track.valid(), u.track.done, u.track.pts.size() if "pts" in u.track else -1])
		if not shot_rolling and sc.units.size() > 0 and is_instance_valid(sc.units[0]) and sc.units[0].sim.pos.distance_to(main.car.sim.pos) < 90.0:
			shot_rolling = true
			Engine.time_scale = 1.0
			await _shot("2_rolling")
			Engine.time_scale = 4.0
	Engine.time_scale = 1.0
	await _wait(1.0)
	main.hud.msgs.clear()
	await _shot("3_working")
	main.zoom_mult = 0.6
	await _wait(1.5)
	await _shot("4_wide")
	# from in front of the wreck, looking back down the lane at everybody
	main._teleport(sc.at + dir * 16.0 - dir.orthogonal() * 0.0 + dir.orthogonal() * 3.6, dir.angle() + PI)
	main.zoom_mult = 0.75
	await _wait(1.5)
	main.hud.msgs.clear()
	await _shot("5_scene")
	main._teleport(sc.at - dir * 30.0 + dir.orthogonal() * 3.6, dir.angle() + PI)
	await _wait(1.5)
	await _shot("6_cones")
	# the work trucks in a row, in daylight: the wrecker, the ambulance, the fire engine
	inc.close(sc)
	main.sky.time_h = 13.0
	var at: Vector2 = main.car.sim.pos
	var side := dir.orthogonal()
	var row: Array = []
	for i in 3:
		var id: String = ["tow", "ambulance", "fire"][i]
		var k := AiCar.new()
		main.ysort.add_child(k)
		var spec := SaveGame.load_spec(id)
		k.setup_ai(spec, main.world, main.skids, main.hud, at + side * (5.0 + 3.6 * i) + dir * 4.0, dir.angle(), 90 + i)
		k.hold = true
		row.append(k)
	main.zoom_mult = 1.0
	await _wait(1.5)
	main.hud.msgs.clear()
	await _shot("7_trucks")
	for k in row: k.queue_free()
	# and one you caused: hit a car, then drive off
	main.zoom_mult = 1.0
	inc.close(sc)
	print("open scenes after close: ", inc.scenes.size(), "  blocked: ", main.traffic.blocked.size())
	inc.enabled = true
	main.free_roam = true
	var heat0: float = main.police.heat()
	var victim: TrafficCar = null
	for c in main.traffic.cars:
		if c.state == "drive" and c.pos.distance_to(main.car.sim.pos) < 200.0: victim = c
	if victim:
		victim.hit(Vector2(9, 0), victim.pos)
		var mine: Incidents.Scene = inc.reported(victim, 9.5, true)
		print("reported: ", mine != null)
		main._teleport(victim.pos + Vector2(0, 160), 0.0)
		await _wait(0.5)
		print("left: ", mine.left if mine else "-", "  heat ", heat0, " -> ", main.police.heat(), "  karma deeds ", StoryState.flags.get("karma_deeds", 0.0))
	get_tree().quit()
