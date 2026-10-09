## Build variants like the reference sheet: godot --headless --path game -s tests/build_sheet.gd -- <out.png>
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[a.size() - 1] if a.size() > 0 else "user://builds.png"
	var W := 768
	var H := 480
	var p := Pix.new(W, H, 1)
	p.grad_v(0, 0, W, H, Color("e8eef4"), Color("cdd8e4"), 6)
	var red := Color("a8232d")
	var green := Color("2e5a2c")
	var len := 200
	var builds := [
		["STOCK", "coupe", red, { "rim": "mesh", "year": 1991 }],
		["STOCK", "pickup", green, { "rim": "steel", "year": 1988 }],
		["STREET", "coupe", red, { "rim": "fivespoke", "rim_color": Color("a8783a"), "drop": 0.6, "spoiler": "ducktail", "kit": { "lip": true, "skirts": true }, "year": 1991 }],
		["OFFROAD", "pickup", green, { "rim": "beadlock", "drop": -1.0, "rollbar": true, "lightbar": true, "spare": true, "bash": true, "year": 1988 }],
		["DRIFT", "coupe", red, { "rim": "deepdish", "drop": 0.8, "spoiler": "gt", "fenders": "flared", "livery": "slash", "exhaust": "dual", "hood": "vented", "kit": { "lip": true }, "year": 1991 }],
		["LOW", "pickup", green, { "rim": "fivespoke", "drop": 1.0, "bed": "tonneau", "smooth": true, "exhaust": "dual", "year": 1988 }],
	]
	for k in builds.size():
		var b: Array = builds[k]
		var x := 30 + (k % 2) * 380
		var y := 130 + (k / 2) * 150
		PixCars.draw(p, x, y, len, String(b[1]), b[2], {}, false, 0.0, b[3])
		p.text(x + len / 2 - Pix.text_w(String(b[0])) / 2, y + 12, String(b[0]), Color("3a5a8a"))
	p.img.save_png(out)
	quit()
