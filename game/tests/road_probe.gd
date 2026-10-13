## Headless probe of the road graph: the junctions that are too sharp, the stubs, the kinks and
## the dead ends. godot --headless --path game -s tests/road_probe.gd
extends SceneTree

func _init() -> void:
	var m := MapData.get_map()
	var B := MapData.BOUNDS
	var acute := 0
	var stubs := 0
	var kinks := 0
	var dead := 0
	var dup := 0
	for n in m.g_pos.size():
		var adj: Array = m.g_adj[n]
		var p: Vector2 = m.g_pos[n]
		if adj.size() == 1:
			var at_edge := p.x <= B.position.x + 2 or p.y <= B.position.y + 2 or p.x >= B.end.x - 2 or p.y >= B.end.y - 2
			if not at_edge:
				dead += 1
				if dead <= 40: print("DEAD  %s %s" % [p, adj[0][2].name])
			continue
		if adj.size() >= 3:
			for i in adj.size():
				var e: Array = adj[i]
				if e[1] < 6.0 and m.g_adj[e[0]].size() >= 3:
					stubs += 1
					if stubs <= 40: print("STUB  %.1f m at %s (%s)" % [e[1], p, e[2].name])
				for j in range(i + 1, adj.size()):
					var f: Array = adj[j]
					var d1: Vector2 = (m.g_pos[e[0]] - p).normalized()
					var d2: Vector2 = (m.g_pos[f[0]] - p).normalized()
					var ang := rad_to_deg(acos(clampf(d1.dot(d2), -1, 1)))
					if ang < 40.0 and e[2] != f[2]:
						acute += 1
						if acute <= 60: print("ACUTE %.0f deg at %s  %s / %s" % [ang, p, e[2].name, f[2].name])
		if adj.size() == 2 and adj[0][2] == adj[1][2]:
			var d1: Vector2 = (m.g_pos[adj[0][0]] - p).normalized()
			var d2: Vector2 = (m.g_pos[adj[1][0]] - p).normalized()
			var turn := 180.0 - rad_to_deg(acos(clampf(d1.dot(d2), -1, 1)))
			if turn > 50.0:
				kinks += 1
				if kinks <= 40: print("KINK  %.0f deg at %s (%s)" % [turn, p, adj[0][2].name])
	# nodes almost on top of each other (two junctions a car length apart)
	for n in m.g_pos.size():
		if m.g_adj[n].size() < 3: continue
		for e in m.g_adj[n]:
			if e[1] < 12.0 and e[1] >= 6.0 and m.g_adj[e[0]].size() >= 3 and e[0] > n:
				dup += 1
				if dup <= 40: print("CLOSE %.1f m  %s - %s (%s)" % [e[1], m.g_pos[n], m.g_pos[e[0]], e[2].name])
	print("nodes %d  acute %d  stubs %d  close %d  kinks %d  dead-ends %d" % [m.g_pos.size(), acute, stubs, dup, kinks, dead])
	quit()
