## Scripted demo for screenshots: godot --path game -- --demo <out_dir>
## Presses the same actions a player would and saves a frame at each step.
extends Node

var main: Node
var out := "user://shots"
var t := 0.0
var shot_i := 0
var steps := [
	# [seconds, actions held, shot name or "", toggles at start]
	[1.0, [], "parked", []],
	[4.4, ["throttle"], "", []],
	[0.6, [], "crash", []],
	[1.5, ["brake"], "", []],
	[2.0, ["brake"], "", []],
	[3.0, ["throttle", "brake"], "burnout", []],
	[3.5, ["throttle"], "launch", []],
	[2.0, ["throttle", "steer_right"], "corner", []],
	[1.4, ["throttle", "steer_left", "handbrake"], "handbrake", []],
	[2.0, ["brake"], "", []],
	[1.5, ["throttle"], "night", ["night"]],
	[2.0, ["throttle", "steer_left"], "winter_night", ["season", "season"]],
	[2.0, ["throttle", "steer_right"], "winter_day", ["night"]],
	[2.0, ["throttle"], "spring", ["season"]],
]
var i := -1
var left := 0.0

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)

func _process(dt: float) -> void:
	left -= dt
	if left > 0.0: return
	if i >= 0:
		for act in steps[i][1]: Input.action_release(act)
		if steps[i][2] != "":
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/%02d_%s.png" % [out, i, steps[i][2]])
	i += 1
	if i >= steps.size():
		print("DEMO DONE")
		get_tree().quit()
		return
	for tog in steps[i][3]:
		match tog:
			"night": main._set_night(not main.night)
			"season": main._apply_season(City.ORDER[(City.ORDER.find(main.city.season) + 1) % 4])
	for act in steps[i][1]: Input.action_press(act)
	left = steps[i][0]
