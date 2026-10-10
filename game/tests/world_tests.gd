## Headless tests for the map, the sky and the cars: godot --headless --path game -s tests/world_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	# ---- the map
	var t := Time.get_ticks_msec()
	var m := MapData.get_map()
	var ms := Time.get_ticks_msec() - t
	check("map builds fast", ms < 1500, "%d ms" % ms)
	check("map has the places", m.landmarks.filter(func(l): return l.dest).size() >= 12, "%d destinations" % m.landmarks.size())
	check("Covington Auto's lot is pavement", m.ground_at(Vector2(5570, 1566)) == "asphalt")
	check("Main St downtown is a road", not m.road_at(Vector2(6000, 1548)).is_empty())
	var in_lane := 0
	for l in m.lights:
		if not String(l.type) in MapData.FLUSH_LIGHTS and not m.road_at(l.p, 0.8).is_empty(): in_lane += 1
	check("no lamp post stands in a road", in_lane == 0, "%d in a lane" % in_lane)
	check("the Petitcodiac runs past downtown", m.river_at(Vector2(5950, 1650)) == 1)
	check("the causeway is a bridge over it", m.ground_at(Vector2(5700, 1680)) == "asphalt" and m.river_at(Vector2(5700, 1680)) == 1)
	var far := 0
	var unreachable := ""
	for l in m.landmarks:
		if not l.dest: continue
		var r := m.route(Vector2(5570, 1566), l.p)
		if r.size() < 1 or r[r.size() - 1].distance_to(l.p) > 250.0:
			far += 1
			unreachable = l.name
	check("the GPS can route to every destination", far == 0, unreachable)
	var r2 := m.route(Vector2(5570, 1566), Vector2(805, 2755))
	var L := 0.0
	for i in r2.size() - 1: L += r2[i].distance_to(r2[i + 1])
	check("Covington Auto to Havelock is a real drive", L > 4500.0 and L < 9000.0, "%.0f m (about %.0f real km)" % [L, L * 8.0 / 1000.0])
	var bad := 0
	for b in m.buildings:
		if b.kind in ["tower", "pumps"]: continue
		if not m.road_at(b.r.get_center(), 0.0).is_empty():
			bad += 1
			print("   on a road: ", b.kind, " ", b.name, " ", b.r, " ", m.road_at(b.r.get_center(), 0.0).road.name)
	check("no building sits on a road", bad == 0, "%d" % bad)
	check("Salisbury has a rail crossing", m.crossings.any(func(c): return m.zone_at(c.p).id == "salisbury"))
	var kinds := {}
	for l in m.lights: kinds[l.type] = true
	check("many kinds of light", kinds.size() >= 12, ", ".join(kinds.keys()))
	# ---- the sky
	var s := WorldSky.new(1)
	for season in ["summer", "fall", "winter", "spring"]:
		s.set_season(season)
		s.time_h = 2.0
		var night := s.daylight()
		s.time_h = 12.5
		var noon := s.daylight()
		check("%s: dark at 2 a.m., light at noon" % season, night < 0.05 and noon > 0.95)
	s.set_season("winter")
	var w_set := s.sunset()
	s.set_season("summer")
	check("winter sunsets come earlier", w_set < s.sunset() - 3.0, "%.1f vs %.1f" % [w_set, s.sunset()])
	s.set_season("summer")
	s.time_h = 23.0
	check("streetlights on at night", s.lights_on(5))
	s.time_h = 12.0
	check("streetlights off at noon", not s.lights_on(5))
	s.wet = 0.0
	s.pick_weather("rain")
	s.forced = true
	for i in 600: s.step(1.0)
	check("rain soaks the road", s.wet > 0.5 and s.surface("asphalt", 2, 0.0) == "wet", "wet %.2f" % s.wet)
	s.pick_weather("clear")
	s.time_h = 11.0
	for i in 1800: s.step(1.0)
	check("sun dries it again", s.wet < 0.2, "wet %.2f" % s.wet)
	s.set_season("winter")
	s.snow_cover = 0.0
	s.pick_weather("snow")
	for i in 900: s.step(1.0)
	check("snow piles up in winter", s.snow_cover > 0.3 and s.surface("asphalt", 2, 0.0) == "snow", "cover %.2f" % s.snow_cover)
	check("the highway is plowed first", s.surface("asphalt", 5, 0.0) != "snow" or s.snow_cover > 0.6)
	s.snow_cover = 0.0
	s.ice = 0.0
	s.pick_weather("freezing")
	for i in 900: s.step(1.0)
	check("freezing rain makes black ice", s.ice > 0.3 and s.surface("asphalt", 2, 0.9) == "ice", "ice %.2f" % s.ice)
	check("off the road is grass, mud or snow", s.surface("grass", 0, 0.0) in ["grass", "mud", "snow"])
	# ---- the cars
	for id in ["silvio", "supreem", "charjer", "tow"]:
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/%s.json" % id))
		var art := CarArt.new(spec, Color(spec.paint))
		check("%s: drawn" % id, art.slices.size() == CarArt.SLICES)
		check("%s: has a dash and a GPS" % id, spec.has("dash") and spec.has("gps"))
		var c := CarSim.new(spec)
		c.set_ambient(20.0)
		c.coolant_c = 88.0
		c.oil_c = 95.0
		var tt := 0.0
		while c.speed() < 100.0 / 3.6 and tt < 30.0:
			c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
			tt += 1.0 / 120.0
		var top := 0.0
		for i in 120 * 50:
			c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
			top = maxf(top, c.speed() * 3.6)
		check("%s: 0-100 and top speed are sane" % id, tt > 4.0 and tt < 20.0 and top > 140.0 and top < 300.0, "0-100 in %.1f s, top %d km/h" % [tt, int(top)])
		var lost := {}
		for surf in ["dry", "grass"]:
			var k := CarSim.new(spec)
			k.set_ambient(20.0)
			k.vx = 60.0 / 3.6
			k.w_wheel = k.vx / float(spec.tires.radius)
			k.surface = surf
			k.auto_gearbox = false
			k.gear = 0
			for i in 240: k.step(1.0 / 120.0, 0.0, 0.0, 0.0, 0.0)
			lost[surf] = 60.0 - k.speed() * 3.6
		check("%s: grass slows you down" % id, lost.grass > lost.dry + 3.0, "coasting 2 s in neutral from 60: dry -%.1f, grass -%.1f km/h" % [lost.dry, lost.grass])
	# ---- mud: slow going, but a rear-drive car on summer tires isn't stuck in it for good
	var sp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/silvio.json"))
	var mc := CarSim.new(sp)
	mc.set_ambient(10.0)
	mc.surface = "mud"
	var mt := 0.0
	while mc.speed() < 2.0 and mt < 8.0:
		mc.step(1.0 / 120.0, 0.6, 0.0, 0.0, 0.0)
		mc.surface = "mud"
		mt += 1.0 / 120.0
	check("a rear-drive car crawls out of mud", mc.speed() >= 2.0, "%.1f m/s after %.1f s" % [mc.speed(), mt])
	# ---- the emergency vehicles: drawn, and they get going (a fire truck's no rocket, but it moves)
	for id in ["ambulance", "fire"]:
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/%s.json" % id))
		var art := CarArt.new(spec, Color(spec.paint))
		check("%s: drawn" % id, art.slices.size() == CarArt.SLICES)
		var c := CarSim.new(spec)
		c.set_ambient(15.0)
		var tt := 0.0
		while c.speed() < 50.0 / 3.6 and tt < 20.0:
			c.step(1.0 / 120.0, 1.0, 0.0, 0.0, 0.0)
			tt += 1.0 / 120.0
		check("%s: 0-50 km/h in under 12 s" % id, tt < 12.0, "%.1f s" % tt)
	# ---- a crash scene shuts its lane: traffic won't turn into it
	var tr := Traffic.new()
	tr.map = m
	var jn := -1
	for n in m.g_adj.size():
		var streets := 0
		for e in m.g_adj[n]:
			if String(e[2].cls) == "street": streets += 1
		if streets == m.g_adj[n].size() and streets >= 3:
			jn = n
			break
	check("found a street junction to test", jn >= 0)
	if jn >= 0:
		var from: int = m.g_adj[jn][0][0]
		var tc := TrafficCar.new()
		tc.rng.seed = 7
		var exits: Array = []
		for e in m.g_adj[jn]:
			if e[0] != from: exits.append(e[0])
		for x in exits.slice(1): tr.blocked[Vector2i(jn, x)] = true
		var always := true
		for i in 30:
			if tr.next_node(from, jn, tc) != exits[0]: always = false
		check("traffic goes round a shut lane", always)
		tc.free()
	tr.free()
	check("hit and run and staying both count", Karma.DEEDS.has("hit_run") and Karma.DEEDS.has("stayed") and Karma.DEEDS.hit_run[0] < 0.0 and Karma.DEEDS.stayed[0] > 0.0)
	# ---- line of sight: a building's shadow, and a building in the way
	var sq := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var sh := Sight.shadow_of(sq, Vector2(-200, 50), 2000.0)
	check("behind a building is in its shadow", Geometry2D.is_point_in_polygon(Vector2(400, 50), sh) and Geometry2D.is_point_in_polygon(Vector2(400, 150), sh))
	check("beside it and in front of it aren't", not Geometry2D.is_point_in_polygon(Vector2(50, 600), sh) and not Geometry2D.is_point_in_polygon(Vector2(-100, 50), sh))
	check("no shadow from inside the building", Sight.shadow_of(sq, Vector2(50, 50), 2000.0).is_empty())
	CarView.screen_up = Vector2(0, -1)
	var bn := BuildingNode.new()
	bn.setup({ "r": Rect2(0, 0, 10, 10), "h": 30, "kind": "shop" })
	var top := bn.global_position + bn.fp.position          # the north-west corner, world px
	check("a car just behind a building is under it", bn.covers(top + Vector2(bn.fp.size.x / 2.0, -bn.hpx * 0.5)))
	check("a car in front of it isn't", not bn.covers(bn.global_position + Vector2(bn.fp.size.x / 2.0, 20.0)))
	check("a car well behind it isn't", not bn.covers(top + Vector2(bn.fp.size.x / 2.0, -bn.hpx - 60.0)))
	var pumps := BuildingNode.new()
	pumps.data = { "kind": "pumps" }
	check("gas pumps don't block sight", not pumps.blocks_sight() and bn.blocks_sight())
	pumps.free()
	bn.free()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
