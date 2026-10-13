## Side-view car sheet: godot --headless --path game -s tests/car_sheet.gd -- <out.png>
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://cars.png"
	var p := Pix.new(760, 560, 1)
	p.grad_v(0, 0, 760, 560, Color("6a7a8a"), Color("3a3e44"), 6)
	var t0 := Time.get_ticks_msec()
	var rows := [
		["coupe", 4.52, Color("c8342c"), {}], ["hatch", 4.62, Color("d8d4c8"), {}], ["sedan", 5.04, Color("1e1e24"), {}],
		["muscle", 4.8, Color("2c6a3a"), { "stripes": "racing", "stripe_color": Color("f0ece4") }], ["wagon", 4.8, Color("6a4a2a"), {}], ["suv", 4.7, Color("4a6a8a"), {}],
		["pickup", 5.6, Color("2a5a3a"), {}], ["tow", 6.6, Color("e8e4dc"), {}], ["van", 5.1, Color("8a8e94"), {}],
		["coupe", 4.52, Color("e8a020"), { "rim": "turbofan", "rim_color": Color("1a1a1e"), "caliper": Color("e0402e"), "drop": 1.0, "spoiler": "gt", "kit": { "lip": true, "skirts": true, "diffuser": true }, "tint": 0.8, "finish": "metallic", "exhaust": "dual" }],
		["hatch", 4.62, Color("2a4aa8"), { "rim": "dish", "rim_color": Color("e8c040"), "stripes": "rally", "stripe_color": Color("f0ece4"), "spoiler": "ducktail", "finish": "pearl" }],
		["sedan", 5.04, Color("6a2a4a"), { "rim": "multispoke", "finish": "matte", "drop": 0.6, "spoiler": "wing" }],
	]
	for k in rows.size():
		var row: Array = rows[k]
		var len := PixCars.length_px(float(row[1]) * 0.62)
		var x := 20 + (k % 3) * 250
		var y := 120 + (k / 3) * 135
		PixCars.draw(p, x, y, len, String(row[0]), row[2], {}, false, 0.0, row[3])
		p.text(x, y + 6, String(row[0]).to_upper(), Color("f0ece4"))
	print("drew in %d ms" % (Time.get_ticks_msec() - t0))
	# one at full cutscene scale
	var big := Pix.new(400, 160, 2)
	big.grad_v(0, 0, 400, 160, Color("8a9aaa"), Color("4a4e54"), 5)
	PixCars.draw(big, 20, 140, PixCars.length_px(4.52), "coupe", Color("c8342c"), {}, false, 0.0, { "rim": "fivespoke" })
	PixCars.draw(big, 200, 140, PixCars.length_px(4.62) - 10, "hatch", Color("d8d4c8"), {}, true)
	big.img.save_png(out.replace(".png", "_big.png"))
	p.img.save_png(out)
	quit()
