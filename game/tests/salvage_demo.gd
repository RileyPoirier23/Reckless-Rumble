## Northside Salvage screenshots: godot --path game -- --salvage-demo <out_dir>
extends Node

var main: Node
var out := "user://salvage_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--salvage-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 1400
	main.save.erase("salvage")
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
	main.sky.time_h = 11.0
	var y: SalvageYard = main.salvage
	main._teleport(SalvageYard.OFFICE + Vector2(30, 30), -PI * 0.75)
	await _wait(1.5)
	await _shot("1_the_yard")
	main._teleport(SalvageYard.OFFICE, -PI / 2.0)
	main.car.sim.clutch_cond = 0.3
	main.car.sim.pads_mm = 2.5
	await _wait(1.0)
	await _shot("2_pull_up")
	y.panel.open()
	await _wait(0.4)
	await _shot("3_the_pile")
	var pile := y.today()
	for i in pile.size():
		if pile[i].kind == "wear" and y.cant_swap(String(pile[i].id)) == "":
			y.panel.sel = i
			y.panel.note = y.buy(i)
			break
	await _wait(0.3)
	await _shot("4_the_nephew")
	for id in ["exh_magnaflown", "intake_sock", "intake_sock"]: main.save.shelf.append(id)
	y.panel.tab = 1
	y.panel.sel = 0
	y.panel.note = ""
	await _wait(0.3)
	await _shot("5_sell")
	y.panel.visible = false
	main.sky.time_h = 21.5
	await _wait(1.0)
	await _shot("6_closed_at_night")
	print("SALVAGE DEMO DONE")
	get_tree().quit()
