## MarketThing screenshots: godot --path game -- --market-demo <out_dir>
extends Node

var main: Node
var out := "user://market_shots"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--market-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	main.save.cash = 14000
	main.save.erase("market")          # fresh listings, not whatever the last run left behind
	_run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func _run() -> void:
	main.sky.time_h = 15.0
	await _wait(1.0)
	main.job_board.open(main.sky, main.save, "", Market.places(main.world.map))
	main.job_board.app = 1
	await _wait(0.4)
	await _shot("1_list")
	var m: MarketApp = main.job_board.market
	m.sel = 2
	m.screen = "detail"
	await _wait(0.4)
	await _shot("2_detail")
	m.screen = "offer"
	m.amount = int(int(m.current().ask) * 0.8 / 50.0) * 50
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var res := Market.offer(m.current(), m.amount, rng)
	if res.kind == "counter": m.amount = int(res.amount)
	await _wait(0.4)
	await _shot("3_chat")
	main.job_board.visible = false
	# the meetup
	var l: Dictionary = m.current()
	l.seller = "flipper"
	l.ghosted = false
	if not (l.faults as Array).has("head_gasket"): l.faults.append("head_gasket")
	main.market.start(l)
	main._teleport(main.market.place.p, 0.0)
	await _wait(1.0)
	main.market.open_meet()
	var p = main.market.panel
	for c in ["hood", "dipstick", "coolant_cap", "creeper"]:
		p.log_line("%s: %s" % [String(Market.CHECKS[c].label), main.market.do_check(c)])
	p.sel = 3
	await _wait(0.4)
	await _shot("4_meetup")
	get_tree().quit()
