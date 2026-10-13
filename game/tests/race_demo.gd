## Street race and police screenshots: godot --path game -- --race-demo <out_dir>
extends Node

var main: Node
var out := "user://race_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--race-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 900
	main.save.heat = 0.0
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	main.sky.set_season("fall")
	main.sky.pick_weather("clear")
	main.sky.forced = true
	main.sky.time_h = 22.5
	await _wait(1.0)
	main.job_board.open(main.sky, main.save, "", Market.places(main.world.map))
	main.job_board.sel = Jobs.ORDER.find("street")
	await _wait(0.4)
	await _shot("1_board")
	main.job_board.visible = false
	var j: JobRunner = main.jobs
	j.start("street")
	j.race_route = StreetRace.ROUTES[1]
	j.race_start = StreetRace.build_path(main.world.map, j.race_route)[0]
	main._teleport(j.race_start - Vector2(30, 0), 0.0)
	await _wait(1.2)
	await _shot("2_meet_marco")
	j.sign_in()
	main.car.can_die = false
	await _wait(2.2)
	await _shot("3_grid")
	var race: StreetRace = j.race
	while not race.racing(): await _wait(0.1)
	await _wait(0.3)
	# you go too: down the route at a racer's clip
	var s := race.track.proj(main.car.sim.pos) + race.track.laps * race.track.length()
	s = await _drive(race.track, s, 150)
	await _shot("4_racing")
	# a patrol car on the next corner sees the whole thing
	var p: Police = main.police
	p.enabled = true
	var c: PlayerCar = main.car
	var at := race.track.point_at(s + 26.0) + c.sim.right() * 7.0
	var cop := p.spawn_at(at, (c.sim.pos - at).angle())
	cop.set_path(PackedVector2Array([at, at + (c.sim.pos - at).normalized() * 2.0]))
	s = await _drive(race.track, s, 40)
	await _wait(0.2)
	await _shot("5_lit_up")
	p.state = "chase"
	if not p.offences.has("fleeing"): p.offences.append("fleeing")
	main.save.heat = 64.0
	s = await _drive(race.track, s, 60)
	var f := c.sim.forward()
	cop.sim.pos = c.sim.pos - f * 13.0
	cop.sim.heading = c.sim.heading
	cop.sim.vx = c.sim.vx
	s = await _drive(race.track, s, 25)
	await _shot("6_pursuit")
	main.hold_car = true
	await _wait(4.0)
	await _shot("7_boxed_in")
	await _wait(4.0)
	await _shot("8_ticket")
	print("RACE DEMO DONE")
	get_tree().quit()

## Drive the player along a track for some physics frames at a steady racing speed.
func _drive(track: PathTrack, s: float, frames: int) -> float:
	var c: PlayerCar = main.car
	for i in frames:
		var v := minf(22.0, 8.0 + i * 0.3)
		s += v / 60.0
		var d := track.dir_at(s)
		c.sim.pos = track.point_at(s)
		c.sim.heading = d.angle()
		c.sim.vx = v
		c.sim.vy = 0.0
		c.sim.yaw_rate = 0.0
		await get_tree().physics_frame
	return s
