## A long burnout in a lot, then the cloud left behind: godot --path game -- --smoke-demo <out_dir>
extends Node

var main: Node
var out := "user://smoke_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--smoke-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	var mx := 0.0
	var rr := 0.0
	for p in main.smoke_field.puffs:
		mx = maxf(mx, p.thick)
		rr = maxf(rr, p.r)
	print("shot ", name, "  puffs ", main.smoke_field.puffs.size(), "  thickest %.2f  biggest %.0f  burnout %.1f s" % [mx, rr, main.car.burn_t])

func _run() -> void:
	main.sky.set_season("summer")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 13.0
	main.traffic.enabled = false
	# the big lot at the mall
	main._teleport(Vector2(5935, 1445), 0.0)
	await _wait(1.0)
	main.hud.msgs.clear()
	Input.action_press("brake")
	Input.action_press("throttle")
	for t in [1, 3, 6]:
		await _wait(float(t) - (0.0 if t == 1 else (1.0 if t == 3 else 3.0)))
		await _shot("burnout_%ds" % t)
	Input.action_release("throttle")
	Input.action_release("brake")
	main.hold_car = true
	await _wait(6.0)
	await _shot("after_6s")
	await _wait(14.0)
	await _shot("after_20s")
	get_tree().quit()
