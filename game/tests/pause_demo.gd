## Pause menu screenshots: godot --path game -- --pause-demo <out_dir>
extends Node

var main: Node
var out := "user://pause_shots"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	var k := a.find("--pause-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	main.sky.time_h = 21.0
	await _wait(1.0)
	var pm: PauseMenu = main.pause_menu
	main._pause()
	await _wait(0.3)
	print("paused: ", get_tree().paused, "  modal: ", main.modal_open())
	await _shot("1_paused")
	pm.card = true
	await _wait(0.3)
	await _shot("2_controls_card")
	pm.card = false
	pm.settings.open()
	pm.settings.tab = 4
	await _wait(0.3)
	await _shot("3_settings_in_game")
	pm.close()
	await _wait(0.3)
	print("resumed: ", not get_tree().paused)
	get_tree().quit()
