## Death screen screenshots: godot --path game -s tests/death_demo.gd -- <out_dir>
extends SceneTree

const CASES := [
	{ "cause": "tree", "car": "silvio", "body": "coupe", "paint": "#c8c8cc", "length": 4.52, "speed_kmh": 120.0, "season": "fall", "time_h": 14.0, "weather": "clear", "wheeloff": true },
	{ "cause": "tree", "car": "supreem", "body": "hatch", "paint": "#c8342c", "length": 4.62, "speed_kmh": 95.0, "season": "winter", "time_h": 23.0, "weather": "snow", "night": true, "surface": "ice" },
	{ "cause": "building", "car": "charjer", "body": "sedan", "paint": "#1e1e24", "length": 5.04, "speed_kmh": 140.0, "season": "summer", "time_h": 21.5, "weather": "clear", "night": true, "style": "downtown" },
	{ "cause": "traffic", "sub": "headon", "car": "tow", "body": "tow", "paint": "#e8e4dc", "length": 6.6, "speed_kmh": 110.0, "season": "summer", "time_h": 12.0, "weather": "rain", "other_body": "van", "other_paint": "#2c5a8a" },
	{ "cause": "traffic", "sub": "tbone", "car": "silvio", "body": "coupe", "paint": "#2c5a8a", "length": 4.52, "speed_kmh": 90.0, "season": "spring", "time_h": 18.5, "weather": "clear", "other_body": "sedan", "other_paint": "#d8a03a", "blink": true },
	{ "cause": "traffic", "sub": "rear", "car": "charjer", "body": "sedan", "paint": "#7a1a1a", "length": 5.04, "speed_kmh": 100.0, "season": "fall", "time_h": 9.0, "weather": "fog", "other_body": "hatch", "other_paint": "#e8e8e8" },
	{ "cause": "water", "car": "supreem", "body": "hatch", "paint": "#c8342c", "length": 4.62, "speed_kmh": 60.0, "season": "summer", "time_h": 15.0, "weather": "clear" },
	{ "cause": "rail", "car": "tow", "body": "tow", "paint": "#e8e4dc", "length": 6.6, "speed_kmh": 105.0, "season": "winter", "time_h": 11.0, "weather": "cloudy" },
	{ "cause": "edge", "car": "silvio", "body": "coupe", "paint": "#e8a020", "length": 4.52, "speed_kmh": 100.0, "season": "summer", "time_h": 13.0, "weather": "clear" },
]

var out := "user://death_shots"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[a.size() - 1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()

func _run() -> void:
	Controls.setup()
	await create_timer(0.2).timeout
	var ds := DeathScreen.new()
	root.add_child(ds)
	for k in CASES.size():
		var info: Dictionary = CASES[k].duplicate()
		info.paint = Color(info.paint)
		if info.has("other_paint"): info.other_paint = Color(info.other_paint)
		ds.open(info)
		ds.t = 3.0
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("%s/death_%d_%s.png" % [out, k, info.cause])
		print("shot ", k, " ", ds.caption)
	quit()
