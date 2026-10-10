## Impound auction screenshots: godot --path game -- --auction-demo <out_dir>
extends Node

var main: Node
var out := "user://auction_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--auction-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 6000
	main.save.erase("auction")
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
	var au: Auction = main.auction
	main._teleport(Auction.GATE + Vector2(30, 20), -PI * 0.8)
	await _wait(1.5)
	await _shot("1_impound_lot")
	main._teleport(Auction.GATE, -PI / 2.0)
	main.car.sim.set_world_velocity(Vector2.ZERO)
	au.start()
	# show a lot with a racer's parts on it, if today has one
	for i in au.lots.size():
		if not (au.lots[i].parts as Dictionary).is_empty():
			au.lot_i = i - 1
			au._next_lot()
			break
	await _wait(1.0)
	await _shot("2_on_the_block")
	au.panel.say(au.you_bid())
	await _wait(2.5)
	await _shot("3_bidding_war")
	for i in au.tops.size(): au.tops[i] = 0
	au.panel.say(au.you_bid())
	await _wait(6.0)
	await _shot("4_sold")
	print("AUCTION DEMO DONE")
	get_tree().quit()
