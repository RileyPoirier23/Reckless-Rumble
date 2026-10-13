## Frames for a short preview clip: an evening drive down Route 112 and into town, the lights
## coming on, saved one PNG a frame to make a video of. godot --path game -- --preview-frames <dir>
## (PF_SECS=12 PF_FPS=20 PF_TIME=19.2 change the length, the rate and the hour.)
extends Node

var main: Node
var out := "user://preview_frames"
var fps := 20.0
var secs := 12.0

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--preview-frames")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	if OS.get_environment("PF_FPS") != "": fps = float(OS.get_environment("PF_FPS"))
	if OS.get_environment("PF_SECS") != "": secs = float(OS.get_environment("PF_SECS"))
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.police.enabled = false
	main.traffic.enabled = false          # a clean run: nothing to run into
	main.wildlife.enabled = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _run() -> void:
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = float(OS.get_environment("PF_TIME")) if OS.get_environment("PF_TIME") != "" else 19.2
	main.sky.snap()
	# the highway in from the west, then the autopilot follows the route into town
	var map: MapData = main.world.map
	var path: PackedVector2Array = map.route(Vector2(4600, 1300), Vector2(5570, 1566))
	if path.size() < 3: path = map.route(Vector2(3150, 1600), Vector2(3150, 120))
	var i0 := 0
	main._teleport(path[i0], (path[i0 + 1] - path[i0]).angle())
	await _wait(2.0)
	main.hud.msgs.clear()
	var c: PlayerCar = main.car
	var n := int(secs * fps)
	var seg := i0
	for f in n:
		# drive it: aim at the next point on the route, a cruising speed
		var nxt: Vector2 = path[mini(seg + 1, path.size() - 1)]
		var tgt: Vector2 = path[mini(seg + 2, path.size() - 1)]
		if c.sim.pos.distance_to(nxt) < 8.0: seg = mini(seg + 1, path.size() - 2)
		# in the right-hand lane, not down the centre line
		var dir := (tgt - nxt).normalized() if tgt != nxt else c.sim.forward()
		tgt += Vector2(-dir.y, dir.x) * 1.9
		var want := (tgt - c.sim.pos).angle()
		# steered for it (the sim keeps the car on its wheels; this just points it down the road)
		c.sim.heading = lerp_angle(c.sim.heading, want, 0.12)
		c.sim.vx = minf(c.sim.vx + 0.35, 19.0)
		c.sim.vy *= 0.8
		await _wait(1.0 / fps)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [out, f])
	print("frames ", n)
	get_tree().quit()
