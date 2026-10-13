## Tree sprite sheet: godot --headless --path game -s tests/tree_sheet.gd -- <out.png>
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://trees.png"
	var sheet := Image.create(900, 560, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("4e6a32"))
	var t0 := Time.get_ticks_msec()
	var n := 0
	var row := 0
	for season in ["summer", "fall", "winter", "winter_snow"]:
		var col := 0
		for kind in ["spruce", "maple", "birch"]:
			for v in 3:
				var snow: bool = season == "winter_snow"
				var s: String = "winter" if snow else season
				var tex := TreeArt.texture(kind, s, snow, v + row, 28 + v * 8)
				n += 1
				sheet.blend_rect(tex.get_image(), Rect2i(Vector2i.ZERO, tex.get_size()), Vector2i(10 + col * 98, 10 + row * 136))
				col += 1
		row += 1
	print("%d trees in %d ms" % [n, Time.get_ticks_msec() - t0])
	sheet.save_png(out)
	quit()
