## Nothing on the driving screen overlaps anything else, sits on the car, or runs out of its box:
##   godot --headless --path game -s tests/hud_layout_tests.gd
## Never loads the drive scene (that would read and write the real save).
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var L := HudLayout
	var fixed := { "car bar": L.CAR_BAR, "clock bar": L.CLOCK_BAR, "info column": Rect2(L.INFO_X, 4, L.INFO_W, L.INFO_BOTTOM - 4),
		"job column": L.JOB, "right slot": L.RIGHT, "scan tool": L.DIAG, "dash": L.DASH }
	var inside := true
	for k in fixed:
		if not L.SAFE.encloses(fixed[k]): inside = false
	check("every panel is on the screen", inside)
	var styles := ["tomtum", "phone", "builtin", "trucker"]
	var clash := ""
	for st in styles:
		for chasing in [false, true]:
			var rects := fixed.duplicate()
			rects["gps"] = L.gps_rect(st)
			rects["police bar"] = L.police_rect(st, chasing)
			var names := rects.keys()
			for i in names.size():
				if not L.SAFE.encloses(rects[names[i]]): clash += "%s off screen (%s); " % [names[i], st]
				for j in range(i + 1, names.size()):
					if (rects[names[i]] as Rect2).grow(1.0).intersects((rects[names[j]] as Rect2).grow(1.0)):
						clash += "%s / %s (%s%s); " % [names[i], names[j], st, ", chase" if chasing else ""]
	check("no two panels overlap, with any GPS, heat or chase", clash == "", clash)
	var help_clash := ""
	for k in fixed:
		if k != "info column" and L.HELP.intersects(fixed[k]): help_clash += k + " "
	check("the controls card sits clear of the panels", help_clash == "", help_clash)
	# the car: at every speed, for the longest and widest thing in the catalogue, with the chase cam lagging
	var long_m := 0.0
	var wide_m := 0.0
	for id in CarCatalog.ids():
		var e := CarCatalog.entry(String(id))
		long_m = maxf(long_m, float(e.get("length", 4.5)))
		wide_m = maxf(wide_m, float(e.get("width", 1.8)))
	var on_car := ""
	for v in range(0, 61, 2):
		var zone := L.car_zone(float(v), long_m, wide_m, 0.5)
		for k in fixed:
			if (fixed[k] as Rect2).intersects(zone): on_car += "%s at %d m/s; " % [k, v]
		for st in styles:
			if L.gps_rect(st).intersects(zone) or L.police_rect(st, true).intersects(zone): on_car += "%s gps/police at %d m/s; " % [st, v]
	check("nothing sits on the car (%.1f x %.1f m, any speed)" % [long_m, wide_m], on_car == "", on_car.substr(0, 300))
	# the info column at its fullest stays above the road
	var col: Array = L.info(L.OBJ_MAX_LINES, L.SUB_MAX_LINES, true)
	check("objective + subtitle + prompt fit the info column", (col[2] as Rect2).end.y <= L.INFO_BOTTOM, "bottom %.0f" % (col[2] as Rect2).end.y)
	# the widest letters there are, wrapped the way the HUD wraps them
	var ws := ""
	for i in 40: ws += "WMWM MWW " if i % 2 == 0 else "MOW WWMWM "
	var too_wide := 0
	for ln in Hud.wrap_lines(ws.strip_edges(), L.SUB_CHARS):
		if PixelFont.width(ln) > L.INFO_W - 12: too_wide += 1
	for ln in Hud.wrap_lines(ws.strip_edges(), L.OBJ_CHARS):
		if PixelFont.width(ln) > L.INFO_W - 10: too_wide += 1
	check("subtitle and objective lines fit the column's width", too_wide == 0 and PixelFont.width(Hud.clip(ws, L.SUB_CHARS)) <= L.INFO_W - 12, "%d too wide" % too_wide)
	# the left column at its fullest: the race order (four cars), the grid card (three rivals)
	var order_end := 38.0 + 24.0 + 9.0 * 4.0
	var grid_end := 102.0 + 22.0 + 3.0 * 26.0
	check("the race order and the grid card fit the left column", order_end < 102.0 and grid_end <= L.JOB.end.y, "grid ends %.0f" % grid_end)
	# every car's name fits its bar (scale 2 when it fits, otherwise scale 1 and cut)
	var too_long := ""
	for id in CarCatalog.ids():
		var e := CarCatalog.entry(String(id))
		var t := "%s %s '%s" % [e.get("make", ""), e.get("model", ""), str(int(e.get("year", 2000))).substr(2)]
		var w := PixelFont.width(t, 2) if PixelFont.width(t, 2) <= L.CAR_BAR.size.x - 12 else PixelFont.width(t.substr(0, 50))
		if w > L.CAR_BAR.size.x - 12: too_long += t + "; "
	check("every car's name fits the car bar", too_long == "", too_long.substr(0, 200))
	# the HUD itself: flood it and it still shows one line at a time, and the car's complaints stay
	# on the scan tool
	var hud := Hud.new()
	hud.sky = WorldSky.new()
	hud.sim = CarSim.new(SaveGame.load_spec("silvio"))
	for i in 20: hud.post("SOMETHING HAPPENED, NUMBER %d. IT'S A LONG LINE SO IT WRAPS ONTO A SECOND ONE." % i, 5.0)
	check("twenty posts at once: one subtitle, a short queue", hud.msgs.size() <= Hud.QUEUE_MAX and hud.sub_lines().size() <= L.SUB_MAX_LINES, "%d queued" % hud.msgs.size())
	hud.msgs.clear()
	hud.post("{use}: THE GARAGE", 0.15)
	check("a per-frame prompt goes in the prompt slot, not the subtitles", hud.prompt_text() != "" and hud.msgs.is_empty())
	hud.post("GUS: \"A BOX CAME FOR YOU.\"", 6.0)
	check("WHO: \"...\" is somebody talking", hud.msgs.size() == 1 and String(hud.msgs[0].who) == "GUS" and String(hud.msgs[0].text) == "A BOX CAME FOR YOU.", str(hud.msgs))
	hud.msgs.clear()
	for i in 200: hud.diag_event("COLD ENGINE: let it warm up")
	hud.diag_event("OVERHEATING")
	check("the car's constant complaints never reach the subtitles", hud.msgs.is_empty())
	hud.sim.oil_c = 20.0
	var cold := hud.codes().any(func(c): return c[0] == "P0128")
	hud.sim.coolant_c = 125.0
	var hot := hud.codes().any(func(c): return c[0] == "P0217")
	check("cold and hot show up as codes on the scan tool", cold and hot)
	var longest := 0
	hud.sim.engine_blown = true
	hud.sim.head_gasket = true
	hud.sim.valves_bent = true
	hud.sim.pads_mm = 1.0
	hud.sim.clutch_cond = 0.05
	for t in hud.sim.tires: t.flat = true
	for c in hud.codes(): longest = maxi(longest, PixelFont.width("%s %s" % [c[0], c[1]]))
	check("every code line fits the scan tool's screen", longest <= L.DIAG.size.x - 6 - 22 - 2, "%d px" % longest)
	hud.say("GUS", "ONE")
	hud.say("GUS", "ONE")
	check("the same line twice queues once", hud.msgs.size() == 1)
	hud.free()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
