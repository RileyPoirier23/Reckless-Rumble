## Story checks: godot --headless --path game -s tests/story_tests.gd
## Every step points at something real, every speaker is in the cast, every set exists, every
## mission starts on a road and can be driven, and the save file round-trips.
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var bad := []
	for st in StoryScript.STEPS:
		match String(st.type):
			"scene": if not StoryScript.SCENES.has(st.id): bad.append(st.id)
			"drive": if not StoryMissions.MISSIONS.has(st.mission): bad.append(st.mission)
			"card", "avatar", "counter": pass
			_: bad.append(st.type)
	check("every step points at a real scene or mission", bad.is_empty(), str(bad))
	var sets := ["party", "airstrip", "office", "lot_dusk", "lot_dusk_charjer", "tims", "apartment", "bay", "black"]
	var who_bad := []
	var set_bad := []
	var lines := 0
	for id in StoryScript.SCENES:
		var sc: Dictionary = StoryScript.SCENES[id]
		if not sets.has(sc.set): set_bad.append(sc.set)
		for ln in sc.lines:
			lines += 1
			var w: String = ln[0]
			if w == "pose":
				if not StoryScript.CAST.has(String(ln[1])): who_bad.append("pose for " + String(ln[1]))
				continue
			if w in ["*", "choice", "set", "cash", "flag", "MANAGER"]: continue
			if not StoryScript.CAST.has(w): who_bad.append(w)
			if (String(ln[1]).length() > 230): who_bad.append("too long: " + String(ln[1]).substr(0, 30))
	for id in StoryScript.SCENES:
		for c in StoryScript.SCENES[id].get("cast", []):
			if not StoryScript.CAST.has(String(c[0])): who_bad.append("cast " + String(c[0]))
			elif PixPeople.image(int(StoryScript.CAST[c[0]].seed), int(StoryScript.CAST[c[0]].female), int(StoryScript.CAST[c[0]].age), PixPeople.OUTFITS.get(c[0], {}), String(c[3]), 0).get_width() != PixPeople.W:
				who_bad.append("sprite " + String(c[0]))
	check("every speaker is in the cast", who_bad.is_empty(), str(who_bad))
	check("every set exists", set_bad.is_empty(), str(set_bad))
	check("there's a story to tell", lines > 100, "%d lines" % lines)
	var used := {}
	for st in StoryScript.STEPS:
		if st.type == "scene": used[st.id] = true
	var unused := []
	for id in StoryScript.SCENES:
		if not used.has(id): unused.append(id)
	check("every scene is in the story", unused.is_empty(), str(unused))
	var map := MapData.get_map()
	for id in StoryMissions.MISSIONS:
		var m: Dictionary = StoryMissions.MISSIONS[id]
		var g := map.ground_at(m.start)
		check("%s: starts on pavement" % id, g == "asphalt", g)
		var spec := SaveGame.load_spec(m.car)
		check("%s: the car exists" % id, not spec.is_empty(), m.car)
		var from: Vector2 = m.start
		for o in m.objectives:
			var r := map.route(from, o.to)
			# the GPS routes node to node; the last stretch is the street the place is on
			check("%s: you can drive to '%s'" % [id, String(o.text).substr(0, 24)], r.size() >= 1 and r[r.size() - 1].distance_to(o.to) < 250.0 and map.ground_at(o.to) == "asphalt")
			from = o.to
	# Frankie: the kid from down the street Leo teaches. Leo has nobody; Frankie isn't his.
	var at := {}
	for k in StoryScript.STEPS.size(): at[String(StoryScript.STEPS[k].get("id", ""))] = k
	check("Frankie: he turns up after Bay 3, and he's still coming round in June",
		int(at.get("the_kid", -1)) > int(at.get("bay_three", 99)) and int(at.get("frankie", -1)) > int(at.get("the_kid", 99)))
	var met_flags := []
	var gus_hatch := false
	for ln in StoryScript.SCENES.the_kid.lines:
		if String(ln[0]) == "flag": met_flags.append(String(ln[1]))
		if String(ln[0]) == "GUS" and String(ln[1]).contains("Dale Hatch"): gus_hatch = true
	check("Frankie: Gus hears the name and says who else used it", gus_hatch and met_flags.has("clue_frankie") and met_flags.has("frankie_met"))
	check("Frankie: he's a kid (a head shorter in the cutscenes)", int(StoryScript.CAST.FRANKIE.age) < 16 and bool(PixPeople.OUTFITS.FRANKIE.get("teen", false)))
	var family := RegEx.create_from_string("\\b(PREGNANT|GIRLFRIEND|BOYFRIEND|WIFE|YOUR SON|MY SON|HIS SON|GRANDPA|GRANDSON|AUNT|UNCLE LEO|DADDY)\\b")
	var hit := ""
	for id in ["the_kid", "frankie"]:
		for ln in StoryScript.SCENES[id].lines:
			var txt := " ".join(PackedStringArray(ln.map(func(x): return str(x)))).to_upper()
			var m := family.search(txt)
			if m: hit += "%s: %s; " % [id, m.get_string()]
	check("Frankie: nobody's partner, nobody's son", hit == "" and not StoryScript.CAST.has("SHAY"), hit)
	# the prologue demo: day one, then the thank-you, then the title
	DemoBuild.forced = true
	var cut := DemoBuild.end_step()
	var cut_ok := String(StoryScript.STEPS[cut].get("title", "")) == "CHAPTER 1" and String(StoryScript.STEPS[cut - 1].get("id", "")) == "home_night"
	StoryState.step = cut - 1
	var before := StoryState.current()
	StoryState.step = cut
	var thanks := StoryState.current()
	StoryState.step = cut + 1
	var credits := StoryState.current()
	StoryState.step = cut + 2
	var after := StoryState.current()
	DemoBuild.forced = false
	StoryState.step = cut
	check("the prologue demo: all of day one, a thank-you instead of CHAPTER 1, the credits, then the title",
		cut_ok and String(before.get("id", "")) == "home_night" and bool(thanks.get("demo_end", false)) and String(credits.type) == "credits"
		and String(after.type) == "end" and String(StoryState.current().get("title", "")) == "CHAPTER 1")
	# the credits: her photo is there, and every line of the roll and the memorial fits the screen
	var wide := ""
	for r in EndCredits.ROLL:
		var sc := 5 if String(r[1]) == "h" else (1 if String(r[1]) == "s" else 2)
		if PixelFont.width(String(r[0]), sc) > 620: wide += String(r[0]) + "; "
	for ln in Hud.wrap_lines(EndCredits.VERSE, 98) + ["I LOVE YOU MEMERE, I'LL KEEP MAKING YOU PROUD", "AUGUST 20TH 1953  -  OCTOBER 7TH 2026", "GRANDMOTHER, SISTER, WIFE AND MOTHER."]:
		if 214 + PixelFont.width(String(ln)) > 632: wide += String(ln) + "; "
	check("the credits: her photo's there and nothing runs off the screen", EndCredits.load_photo() != null and wide == "" and PixelFont.G.has(";"), wide)
	StoryState.step = 0
	# nobody in a cutscene stands in a car (parked behind them, in front of them, or wrecked),
	# and no two cars in a set sit in each other unless they're the same wreck
	var hits := ""
	var stacked := ""
	for id in StoryScript.SCENES:
		var sc: Dictionary = StoryScript.SCENES[id]
		var scene_sets := [String(sc.set)]
		for ln in sc.lines:
			if String(ln[0]) == "set": scene_sets.append(String(ln[1]))
		for c in sc.get("cast", []):
			var poses := [String(c[3])]
			for ln in sc.lines:
				if String(ln[0]) == "pose" and String(ln[1]) == String(c[0]): poses.append(String(ln[2]))
			for pose in poses:
				var img := PixPeople.sprite(String(c[0]), String(pose), 0).get_image()
				var u := img.get_used_rect()
				var left := int(c[1]) - img.get_width() / 2 + (u.position.x if int(c[2]) > 0 else img.get_width() - u.end.x)
				var body := Rect2(left, StorySets.FEET_Y - img.get_height() + u.position.y, u.size.x, u.size.y)
				for st in scene_sets:
					for v in StorySets.vehicles_in(String(st)):
						var o := body.intersection(v.rect)
						if o.size.x > 1 and o.size.y > 1: hits += "%s: %s (%s) in a car in %s; " % [id, String(c[0]), pose, st]
	for st in ["party", "airstrip", "office", "lot_dusk", "lot_dusk_charjer", "tims", "apartment", "bay"]:
		var vs := StorySets.vehicles_in(st)
		for a in vs.size():
			for b in range(a + 1, vs.size()):
				if String(vs[a].wreck) != "" and vs[a].wreck == vs[b].wreck: continue
				var o: Rect2 = (vs[a].rect as Rect2).intersection(vs[b].rect)
				if o.size.x > 1 and o.size.y > 1: stacked += "%s: cars %d and %d; " % [st, a, b]
	check("cutscenes: nobody stands in a car", hits == "", hits)
	check("cutscenes: no two cars sit in each other (apart from the wreck)", stacked == "", stacked)
	# prompts follow the device
	Controls.setup()
	Hints.pad = false
	check("keyboard prompts say keyboard keys", Hints.key("ui_accept") == "ENTER" and Hints.key("handbrake") == "SPACE", Hints.key("ui_accept") + "/" + Hints.key("handbrake"))
	Hints.pad = true
	Hints.playstation = false
	check("controller prompts say pad buttons", Hints.key("ui_accept") == "A" and Hints.key("throttle") == "RT" and Hints.key("handbrake") == "B", Hints.key("ui_accept") + "/" + Hints.key("throttle"))
	check("keyboard-only bits drop out on a pad", not Hints.fmt("SHIFT {shift}  TOW {reset}").contains("TOW"), Hints.fmt("SHIFT {shift}  TOW {reset}"))
	check("auto/manual is on L3", Hints.fmt("AUTO {gearbox}") == "AUTO L3", Hints.fmt("AUTO {gearbox}"))
	Hints.playstation = true
	check("PlayStation names", Hints.key("ui_accept") == "CROSS", Hints.key("ui_accept"))
	Hints.pad = false
	# a cutscene's instructions: poses happen, money changes hands once, and a choice made again
	# only keeps the last pick
	StoryState.cash = 340
	StoryState.flags = {}
	var sc: Variant = load("res://story/story_scene.gd").new()
	sc.step = { "type": "scene" }
	sc.cast = { "DOM": { "x": 200, "facing": -1, "pose": "crossed" }, "SAL": { "x": 250, "facing": -1, "pose": "pockets" } }
	sc.lines = [["DOM", "Everybody. Quiet."], ["pose", "DOM", "bow"], ["pose", "SAL", "bow"], ["DOM", "Lord."], ["cash", -340],
		["choice", [["Yes.", "said_yes"], ["No.", "said_no"]]], ["DOM", "Amen."]]
	sc.press()
	sc.press()
	sc._process(0.0)
	check("pose lines change poses and take no press", int(sc.i) == 3 and String(sc.cast.DOM.pose) == "bow" and String(sc.cast.SAL.pose) == "bow", "line %d, %s/%s" % [int(sc.i), sc.cast.DOM.pose, sc.cast.SAL.pose])
	sc.shown = 99.0
	sc.press()
	sc._process(0.0)
	sc.back()
	check("back skips the instructions and puts the poses back", int(sc.i) == 3 and String(sc.cast.DOM.pose) == "bow", "line %d" % int(sc.i))
	sc.press()
	sc._process(0.0)
	check("going back over a cash line doesn't pay it twice", StoryState.cash == 0, "$%d" % StoryState.cash)
	sc.press()
	sc.back()
	sc.choice_sel = 1
	sc.press()
	check("a choice made again keeps only the last pick", StoryState.flag("said_no") and not StoryState.flag("said_yes"), str(StoryState.flags))
	sc.free()
	# the save round-trips
	StoryState.new_game()
	StoryState.step = 7
	StoryState.avatar = { "name": "RAY MELANSON", "seed": 42, "female": 0, "age": 55 }
	StoryState.set_flag("owes_familia")
	StoryState.save()
	StoryState.step = 0
	StoryState.avatar = {}
	StoryState.load_game()
	check("the story save round-trips", StoryState.step == 7 and StoryState.manager() == "RAY MELANSON" and StoryState.flag("owes_familia"))
	check("lines fill in the old manager's name", StoryState.fill("{MANAGER}'S MUG") == "RAY MELANSON'S MUG")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(StoryState.PATH))
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
