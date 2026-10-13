## Real crashes, real death screens: godot --path game -- --crash-demo <out_dir>
## Puts the car near a tree (country) and a building (downtown), floors it, and saves the
## death screen each time.
extends Node

var main: Node
var out := "user://crash_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--crash-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.traffic.ignore_player = true
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

## Aim at the closest tree to `near` from `dist` metres back, at `speed` m/s.
func _hit_tree(near: Vector2, speed: float) -> void:
	main._teleport(near, 0.0)
	await _wait(0.6)
	var best: Array = []
	var bd := INF
	for key in main.world.chunks:
		for tr in main.world.chunks[key].trees:
			var d: float = (tr[0] as Vector2).distance_to(near)
			if d < bd and d > 6.0:
				bd = d
				best = tr
	var tp: Vector2 = best[0]
	var dir := Vector2.RIGHT.rotated(0.4)
	main._teleport(tp - dir * 9.0, dir.angle())
	main.car.sim.gear = 5
	main.car.sim.vx = speed
	main.car.sim.w_wheel = speed / 0.31
	for n in 12:
		await get_tree().physics_frame
		print("  v=%.1f d=%.1f" % [main.car.sim.speed(), main.car.sim.pos.distance_to(tp)])

func _run() -> void:
	main.sky.forced = true
	var cases := [
		["fall", 14.0, "clear", Vector2(4200, 1900)],
		["winter", 23.0, "snow", Vector2(2600, 2300)],
		["summer", 20.0, "rain", Vector2(5200, 900)],
	]
	for i in cases.size():
		var c: Array = cases[i]
		main.sky.set_season(String(c[0]))
		main._apply_season(String(c[0]))
		main.sky.time_h = float(c[1])
		main.sky.pick_weather(String(c[2]))
		await _hit_tree(c[3], 38.0)
		for n in 120:
			await get_tree().process_frame
			if main.death.visible: break
		await _wait(2.4)
		await _shot("crash_%d_%s" % [i, main.death.info.get("cause", "none")])
		main.death.showing = false
		main.death.visible = false
		main._after_death()
		await _wait(0.5)
	get_tree().quit()
