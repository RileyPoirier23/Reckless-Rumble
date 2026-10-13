## How smooth is it at speed? Drives a car flat out down a long road and records every frame's
## time, and what the world built on the frames that ran long:
##   godot --path game --rendering-driver opengl3 -s tests/perf_probe.gd -- [mps] [seconds]
extends SceneTree

var main: Node
var frames: Array = []
var built: Array = []

func _initialize() -> void:
	main = load("res://drive.tscn").instantiate()
	root.add_child(main)
	_run()

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _run() -> void:
	await _wait(2.0)
	var a := OS.get_cmdline_user_args()
	var mps := float(a[0]) if a.size() > 0 else 45.0
	var secs := float(a[1]) if a.size() > 1 else 20.0
	# down Route 112 and on, following the road (no trees in the way: what's measured is the
	# world streaming past, not a crash)
	var path: PackedVector2Array = main.world.map.route(Vector2(3150, 1600), Vector2(3150, 120))
	var at: Vector2 = path[0]
	main._teleport(at, (path[1] - path[0]).angle())
	main.world.warm(at, Vector2(80, 50))
	await _wait(3.0)                     # (past the loading: what's measured is the driving)
	var t := 0.0
	var s := 0.0
	var last := Time.get_ticks_usec()
	while t < secs:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		t += ms / 1000.0
		s += mps * minf(ms / 1000.0, 0.1)
		var p := _along(path, s)
		var q := _along(path, s + 3.0)
		main.car.sim.pos = p
		main.car.sim.heading = (q - p).angle()
		main.car.sim.vx = mps
		main.car.sim.vy = 0.0
		main.car.sim.yaw_rate = 0.0
		frames.append(ms)
	frames.sort()
	var n := frames.size()
	var over := frames.filter(func(x): return x > 25.0).size()
	print("frames %d  median %.1f ms  p95 %.1f  p99 %.1f  max %.1f  over 25 ms: %d" % [n, frames[n / 2], frames[int(n * 0.95)], frames[int(n * 0.99)], frames[n - 1], over])
	quit()

func _along(path: PackedVector2Array, d: float) -> Vector2:
	for i in path.size() - 1:
		var L := path[i].distance_to(path[i + 1])
		if d <= L: return path[i].lerp(path[i + 1], d / maxf(L, 0.01))
		d -= L
	return path[path.size() - 1]
