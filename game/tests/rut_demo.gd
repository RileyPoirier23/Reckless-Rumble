## Off the road across a field and through the brush: the ruts and the flattened growth behind.
##   godot --path game -- --rut-demo <out_dir>
extends Node

var main: Node
var out := "user://rut_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--rut-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name, "  marks ", main.skids.alphas.size(), "  surface ", main.car.sim.surface)

func _run() -> void:
	main.traffic.enabled = false
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 13.0
	for season in ["summer", "winter"]:
		main.sky.set_season(season)
		main.skids.clear()
		# out in a farm field (where the trees are few), off a country road
		var map: MapData = main.world.map
		var at := Vector2(4600, 1700)
		var head := 0.0
		for i in 400:
			var q := Vector2(3600 + (i % 20) * 70.0, 1500 + (i / 20) * 50.0)
			if map.field_noise.get_noise_2d(q.x, q.y) < 0.35 or map.ground_at(q) != "grass": continue
			if not map.road_at(q, 25.0).is_empty(): continue
			var ok := true
			for t in 8:
				var q2 := q + Vector2(t * 5.0, 0)
				if map.field_noise.get_noise_2d(q2.x, q2.y) < 0.3 or map.ground_at(q2) != "grass" or not map.road_at(q2, 4.0).is_empty(): ok = false
			if ok:
				at = q
				break
		main._teleport(at, head)
		await _wait(1.0)
		main.hud.msgs.clear()
		main.car.sim.vx = 9.0
		Input.action_press("throttle", 0.35)
		await _wait(2.0)
		Input.action_press("steer_left", 0.4)
		await _wait(2.0)
		Input.action_release("throttle")
		Input.action_release("steer_left")
		Input.action_press("brake")
		await _wait(1.5)
		Input.action_release("brake")
		main.zoom_mult = 0.7
		await _wait(0.8)
		await _shot("field_" + season)
		main.zoom_mult = 1.0
	get_tree().quit()
