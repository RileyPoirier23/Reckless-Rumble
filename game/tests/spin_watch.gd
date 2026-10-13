## Catches a car going round in circles: a lap and a quarter of heading inside a few metres over
## the last twelve seconds. note() every quarter second; it returns "" or what it saw.
class_name SpinWatch

var _spin := {}
var _seen := {}

func note(id: int, pos: Vector2, heading: float, t: float, label := "") -> String:
	if not _spin.has(id): _spin[id] = []
	var sp: Array = _spin[id]
	sp.append([t, pos, heading])
	while sp.size() > 48: sp.pop_front()
	if sp.size() < 40 or _seen.has(id): return ""
	var turned := 0.0
	var lo: Vector2 = sp[0][1]
	var hi: Vector2 = sp[0][1]
	for i in range(1, sp.size()):
		turned += absf(angle_difference(float(sp[i - 1][2]), float(sp[i][2])))
		lo = lo.min(sp[i][1])
		hi = hi.max(sp[i][1])
	if turned > 2.5 * PI and (hi - lo).length() < 14.0:
		_seen[id] = true
		var tr := ""
		for i in range(sp.size() - 24, sp.size(), 2): tr += " (%.1f,%.1f)h%.0f" % [sp[i][1].x, sp[i][1].y, rad_to_deg(sp[i][2])]
		return "%s going round in circles at (%.0f,%.0f): turned %.0f deg in 12 s within %.0f m\n      trace%s" % [label, pos.x, pos.y, rad_to_deg(turned), (hi - lo).length(), tr]
	return ""
