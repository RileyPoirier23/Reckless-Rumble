extends SceneTree
func _init() -> void:
	var rules = CounterRules.new(7)
	var white := 0
	var n := 0
	var seen := {}
	for day in range(1, 60, 4):
		for i in 4:
			var c: Dictionary = rules.customer(day) if i < 3 else rules.walk_in(day)
			if c.is_empty() or not c.has("car") or String(c.get("kind", "")) == "audit": continue
			var spec := { "cat": String(c.car.get("cat", "")), "length": c.car.len, "width": c.car.wid, "wheelbase": float(c.car.get("wheelbase", float(c.car.len) * 0.6)), "body": c.car.get("side_body", "sedan") }
			var art := CarArt.new(spec, Color(c.car.paint), 0.15 if c.get("sheet", {}).get("rust", false) else 0.0, c.person.face)
			n += 1
			var img: Image = art._imgs.atlas if art._imgs != null and art._imgs.atlas != null else null
			if img == null:
				print("NOART %s body %s" % [spec.cat, spec.body])
				continue
			var op := 0
			var wh := 0
			for y in img.get_height():
				for x in img.get_width():
					var px := img.get_pixel(x, y)
					if px.a < 0.5: continue
					op += 1
					if px.r > 0.85 and px.g > 0.85 and px.b > 0.85: wh += 1
			var frac := float(wh) / maxf(1.0, float(op))
			if frac > 0.4:
				white += 1
				var key := "%s|%s" % [spec.cat, spec.body]
				if not seen.has(key):
					seen[key] = true
					print("WHITE %s body %s paint %s: %.0f%% white of %d px, atlas %dx%d, slices %d" % [spec.cat, spec.body, str(c.car.paint), frac * 100.0, op, img.get_width(), img.get_height(), art.n])
	print("%d of %d bay cars come out white" % [white, n])
	quit()
