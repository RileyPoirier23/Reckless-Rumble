## Vegetation screenshots: godot --path game -- --veg-demo <out_dir>
extends Node

var main: Node
var out := "user://veg_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--veg-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.traffic.ignore_player = true
	main.get_node("HudLayer").visible = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _run() -> void:
	main.sky.forced = true
	main.sky.time_h = 13.0
	main.sky.pick_weather("clear")
	var spots := [Vector2(4200, 1900), Vector2(2600, 2300), Vector2(5200, 900), Vector2(1500, 2500)]
	for season in ["summer", "fall", "winter"]:
		main.sky.set_season(season)
		main._apply_season(season)
		if season == "winter": main.sky.snow_cover = 0.8
		for i in spots.size():
			main._teleport(spots[i], 0.3)
			main.zoom_mult = 1.0
			await _wait(2.5 if i == 0 else 1.5)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/veg_%s_%d.png" % [out, season, i])
			print("shot ", season, " ", i)
	get_tree().quit()
