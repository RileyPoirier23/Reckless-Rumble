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
			"card", "avatar", "counter", "credits": pass
			_: bad.append(st.type)
	check("every step points at a real scene or mission", bad.is_empty(), str(bad))
	var sets := ["party", "airstrip", "office", "lot_dusk", "lot_dusk_charjer", "tims", "tims_snow", "apartment", "bay", "bay_fox", "hairpin", "hairpin_gap", "meet", "black"]
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
			if w in ["*", "choice", "set", "cast", "cash", "debt", "flag", "MANAGER"]: continue
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
			# whoever he's chasing or racing starts on the road too, and a drag run starts on the runway
			for key in ["chase", "race"]:
				if o.has(key): check("%s: the %s car starts on pavement" % [id, key], map.ground_at(o[key].start) == "asphalt" and not SaveGame.load_spec(String(o[key].car)).is_empty(), String(o[key].car))
			if o.get("drag", false): check("%s: the drag run starts on the runway" % id, map.ground_at(o.from) == "asphalt" and (o.to as Vector2).distance_to(o.from) > 150.0)
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
	# the drunk drive ends at the fence at the end of Airstrip Rd (the meet's on the other side),
	# not wherever you happen to crash
	var lc: Dictionary = StoryMissions.MISSIONS.last_call.objectives[0]
	check("the prologue's crash is at the airstrip fence, not wherever you crash", bool(lc.get("crash_at", false)) and not lc.has("crash_ends")
		and (lc.to as Vector2).distance_to(StoryMissions.AIRSTRIP) < 40.0)
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
	check("the credits: her photo's there and nothing runs off the screen", EndCredits.load_photo() != null and wide == "" and PixelFont.has_glyph(";"), wide)
	StoryState.step = 0
	# nobody in a cutscene stands in a car (parked behind them, in front of them, or wrecked),
	# and no two cars in a set sit in each other (one wreck's cars only touch where they folded)
	var hits := ""
	var stacked := ""
	var sets_used := {}
	for id in StoryScript.SCENES:
		var sc: Dictionary = StoryScript.SCENES[id]
		# walk the scene: where it is and who's standing there change as it goes ("set", "cast")
		var where := String(sc.set)
		sets_used[where] = true
		var here := {}
		for c in sc.get("cast", []):
			here[String(c[0])] = c
			hits += _stand(id, c, String(c[3]), where)
		for ln in sc.lines:
			match String(ln[0]):
				"set":
					where = String(ln[1])
					sets_used[where] = true
				"cast":
					here = {}
					for c in ln[1]:
						here[String(c[0])] = c
						hits += _stand(id, c, String(c[3]), where)
				"pose":
					if here.has(String(ln[1])): hits += _stand(id, here[String(ln[1])], String(ln[2]), where)
	# every set any scene uses, and a wreck's cars really meet (a crash, not two parked cars)
	var apart := ""
	for st in sets_used:
		var vs := StorySets.vehicles_in(String(st))
		for a in vs.size():
			var wreck := String(vs[a].wreck)
			var gap := 999.0
			for b in vs.size():
				if b == a: continue
				var ra: Rect2 = vs[a].rect
				var rb: Rect2 = vs[b].rect
				var o := ra.intersection(rb)
				var same := wreck != "" and String(vs[b].wreck) == wreck
				if b > a and o.size.x > (3 if same else 1) and o.size.y > 1: stacked += "%s: cars %d and %d (%dpx); " % [st, a, b, int(o.size.x)]
				if same: gap = minf(gap, maxf(maxf(rb.position.x - ra.end.x, ra.position.x - rb.end.x), maxf(rb.position.y - ra.end.y, ra.position.y - rb.end.y)))
			if wreck != "" and gap > 2.0: apart += "%s: car %d of %s is %s px off the rest; " % [st, a, wreck, str(gap)]
	check("cutscenes: every scene's set was checked for cars", sets_used.has("airstrip") and sets_used.size() >= 8, str(sets_used.keys()))
	check("cutscenes: nobody stands in a car", hits == "", hits)
	check("cutscenes: no two cars sit in each other (a wreck's only touch)", stacked == "", stacked)
	check("cutscenes: a wreck's cars meet where they hit", apart == "", apart)
	# nobody in a cutscene calls Leo son, sir or Frank's boy: he's "kid", or Leo
	var address := RegEx.create_from_string("\\b(SON|SIR|MA'AM|MADAM|YOUNG MAN|YOUNG LADY|[A-Z]+'S BOY)\\b")
	var called := ""
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			if ln.size() < 2 or not ln[1] is String: continue
			var m := address.search(String(ln[1]).to_upper())
			if m: called += "%s: %s; " % [id, m.get_string()]
	check("cutscenes: nobody calls Leo son, sir or somebody's boy", called == "", called)
	# the death screen's crash pictures: the other car meets Leo's nose and never sits in it,
	# head-on, rear-ended or T-boned, slow or fast, with a wheel off or not
	var crashed := ""
	for sub in ["headon", "rear", "tbone"]:
		for kmh: float in [60.0, 100.0, 160.0]:
			for pair in [["coupe", 4.52, "van"], ["tow", 6.6, "sedan"], ["hatch", 4.62, "pickup"], ["sedan", 5.04, "hatch"]]:
				var info := { "cause": "traffic", "sub": sub, "body": pair[0], "length": pair[1], "other_body": pair[2], "speed_kmh": kmh, "wheeloff": kmh > 95.0 }
				DeathScreen.paint_scene(info, 7)
				var cs: Array = DeathScreen.cars
				var what := "%s %s into a %s at %d" % [sub, pair[0], pair[2], int(kmh)]
				if cs.size() != 2:
					crashed += "%s: %d cars; " % [what, cs.size()]
					continue
				var ra: Rect2i = cs[0]
				var rb: Rect2i = cs[1]
				var o := ra.intersection(rb)
				var gap := maxi(rb.position.x - ra.end.x, ra.position.x - rb.end.x)
				if o.size.x > 2 and o.size.y > 1: crashed += "%s: %dpx inside; " % [what, o.size.x]
				elif gap > 1: crashed += "%s: %dpx apart; " % [what, gap]
	check("death screen: a traffic crash's two cars meet where they hit, never one in the other", crashed == "", crashed)
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
	_karma()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)


# ------------------------------------------------------------------ karma and the endings

## Play the steps from the first one, as a Leo with these flags, and list the scenes and drives
## that would play (the conditional steps skipped the way StoryState.advance skips them).
func _path(flags: Dictionary) -> Array:
	StoryState.flags = flags.duplicate()
	var out: Array = []
	for st in StoryScript.STEPS:
		if not StoryState.step_on(st): continue
		if st.type == "scene": out.append(String(st.id))
		elif st.type == "drive": out.append(String(st.mission))
	return out

func _karma() -> void:
	var was := StoryState.flags.duplicate()
	var was_active := StoryState.active
	StoryState.active = true
	StoryState.day = 3
	# every choice in the script is worth something (or deliberately nothing)
	var missing := []
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			if String(ln[0]) != "choice": continue
			for o in ln[1]:
				if not Karma.CHOICES.has(String(o[1])): missing.append(String(o[1]))
	check("karma: every choice in the script counts for something", missing.is_empty(), str(missing))
	# a calm Leo and a reckless one
	StoryState.flags = { "quiet": true, "meet_agree": true, "checked_silvio": true, "kid_light": true, "mentor_job": true }
	check("karma: the careful answers make him HIGH", Karma.tier() == "high", "%.1f" % Karma.score())
	StoryState.flags = { "cocky": true, "meet_defiant": true, "blind_buy": true, "kid_closed": true }
	check("karma: the cocky ones make him LOW", Karma.tier() == "low", "%.1f" % Karma.score())
	StoryState.flags = { "quiet": true, "meet_agree": true }
	check("karma: a bit of both is the middle", Karma.tier() == "middle", "%.1f" % Karma.score())
	# going back in a scene and picking again only counts the last pick
	StoryState.flags = { "cocky": true }
	var cocky := Karma.score()
	StoryState.flags.erase("cocky")
	StoryState.flags["quiet"] = true
	check("karma: pick again and only the last pick counts", Karma.score() > cocky and is_equal_approx(Karma.score(), 0.0), "%.1f then %.1f" % [cocky, Karma.score()])
	# what he does on the road, capped per day
	StoryState.flags = {}
	for i in 10: Karma.deed("crash_traffic")
	check("karma: ten crashes in one night count for no more than the cap", is_equal_approx(Karma.score(), -2.0), "%.1f" % Karma.score())
	StoryState.day = 4
	Karma.deed("escape")
	check("karma: running from the police counts, the next day too", is_equal_approx(Karma.score(), -4.0) and Karma.tier() == "low", "%.1f" % Karma.score())
	StoryState.active = false
	var before := Karma.score()
	Karma.deed("escape")
	check("karma: outside the story (the lot, the counter's free mode) nothing counts", is_equal_approx(Karma.score(), before))
	StoryState.active = true
	# the police give a calm driver a little slack and a reckless one none
	StoryState.flags = { "kid_light": true, "kid_home": true, "mentor_job": true }
	var calm := Karma.police_slack()
	StoryState.flags = { "cocky": true, "kid_closed": true, "meet_defiant": true }
	check("karma: the police give a calm Leo slack and a reckless one none", calm > 0.0 and Karma.police_slack() < 0.0, "%.0f / %.0f" % [calm, Karma.police_slack()])
	# lines for one kind of Leo
	check("karma: a line for a reckless Leo plays for him and not for a calm one",
		Karma.holds({ "karma": "low" }) and not Karma.holds({ "karma": "high" }) and Karma.holds({ "karma": "not_high" }) and not Karma.holds({ "karma": "not_low" }))
	check("karma: lines can follow a choice made earlier", Karma.holds({ "flag": "cocky" }) and not Karma.holds({ "flag": "quiet" }) and Karma.holds({ "not_flag": "quiet" }))
	# every kind of Leo hears something different from Gus, Frankie and Hatch
	var tiered := { "low": 0, "high": 0 }
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			if ln.size() > 2 and ln[2] is Dictionary and (ln[2] as Dictionary).has("karma") and tiered.has(String(ln[2].karma)): tiered[String(ln[2].karma)] += 1
	check("karma: people talk to a reckless Leo and a calm one differently", int(tiered.low) >= 8 and int(tiered.high) >= 8, str(tiered))
	# the endings: settled by the night of the first snow, by what Leo taught Frankie
	var safe := _path({ "frankie_safe": true })
	var hurt := _path({ "frankie_hurt": true })
	var dead := _path({ "frankie_dead": true })
	check("endings: HIGH, Frankie did his Sunday check: the long way down, Hatch arrested", safe.has("long_way_down") and safe.has("clean_end") and not safe.has("funeral") and not safe.has("the_mountain"), str(safe.slice(-4)))
	check("endings: MIDDLE, Frankie skipped it once: the snowbank, Hatch gone", hurt.has("snowbank") and hurt.has("middle_end") and not hurt.has("clean_end") and not hurt.has("funeral"), str(hurt.slice(-4)))
	check("endings: LOW, Frankie dies, then the revenge mission", dead.has("funeral") and dead.has("the_mountain") and dead.has("street_end") and dead.find("funeral") < dead.find("the_mountain") and not dead.has("clean_end"), str(dead.slice(-4)))
	# the night of the first snow settles it from the tier, one flag each
	var first: Array = StoryScript.SCENES.first_snow.lines
	var settle := {}
	for ln in first:
		if String(ln[0]) == "flag" and ln.size() > 2: settle[String(ln[2].karma)] = String(ln[1])
	check("endings: each tier settles one ending", settle == { "high": "frankie_safe", "middle": "frankie_hurt", "low": "frankie_dead" }, str(settle))
	check("endings: the revenge mission is a chase up the Mountain", StoryMissions.MISSIONS.the_mountain.objectives[0].has("chase"))
	check("credits: on the Mountain ending, Frankie's line has his years", EndCredits.line_text("FRANKIE, FROM DOWN THE STREET").contains("2026"))
	# the years in between are written: a card for every chapter, in order, and nothing left saying otherwise
	var cards := []
	var unwritten := false
	for st in StoryScript.STEPS:
		if st.type == "card" and String(st.title).begins_with("CHAPTER"): cards.append(String(st.title))
		if str(st).contains("STILL BEING WRITTEN") or str(st).contains("go here"): unwritten = true
	check("story: chapters 1 to 8, in order, all written", cards == ["CHAPTER 1", "CHAPTER 2", "CHAPTER 3", "CHAPTER 4", "CHAPTER 5", "CHAPTER 6", "CHAPTER 7", "CHAPTER 8"] and not unwritten, str(cards))
	# the keys in Mikey's hat: take them and it's the S-bend and Tremblay; leave them and Aries drives
	var took := _path({ "keys_take": true })
	var left := _path({ "keys_hat": true })
	check("chapter 4: take the keys, drive drunk with Aries, get pulled over at the S-bend", took.has("seatbelt") and took.has("pulled_over") and not took.has("aries_drives"), str(took))
	check("chapter 4: leave them in the hat and Aries drives you home", left.has("aries_drives") and not left.has("seatbelt") and left.has("day_one"))
	# asking Dom about D.: now (and he's hurt), or four years later (and he points at the initials)
	check("D.: ask Dom in year two, or in year six, never both", _path({ "d_confront": true }).has("d_for_dom") and not _path({ "d_confront": true }).has("not_d")
		and _path({ "d_quiet": true }).has("not_d") and not _path({ "d_quiet": true }).has("d_for_dom"))
	# the clue trail runs in order before the finale: the book, the skid marks, the tapes, the carbon
	# copy, the cut line, the money; and Hatch's slip at the counter still comes after all of it
	var at := {}
	for k in StoryScript.STEPS.size(): at[String(StoryScript.STEPS[k].get("id", ""))] = k
	var order := []
	for id in ["bay_three", "night_shift", "the_tapes", "carbon_copy", "the_fox", "confession", "follow_money", "hatch_counter"]: order.append(int(at.get(id, -1)))
	var sorted := order.duplicate()
	sorted.sort()
	check("the clues come in order, and all of them before Hatch slips", order == sorted and not order.has(-1), str(order))
	check("the Silvio is Frankie's before the first snow (Leo gives it to him at eighteen)", int(at.get("eighteen", 99)) < int(at.get("first_snow", -1)))
	check("endings: Hatch trips over the green book Gus told Leo about",
		str(StoryScript.SCENES.bay_three.lines).contains("green book") and str(StoryScript.SCENES.hatch_counter.lines).contains("green book"))
	_flags_and_voices()
	StoryState.flags = was
	StoryState.active = was_active


## No dead flags, no dead choices, and everybody gets their moments: every flag the script sets
## (a "flag" line, a choice, a medal on the runway) is read back somewhere (a line, an option or a
## step that asks for it, or the credits), every choice counts for karma, each chapter has Mikey,
## Aries, Gus and Frankie in it, Toby and Tremblay get real scenes, and the house rules hold.
func _flags_and_voices() -> void:
	var set_here := {}            # flag -> where it's set
	var read := {}                # flag -> true
	var read_code := { "frankie_dead": true }     # EndCredits.line_text reads this one
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			var w := String(ln[0])
			if w == "flag": set_here[String(ln[1])] = id
			if w == "choice":
				for o in ln[1]:
					set_here[String(o[1])] = id
					if o.size() > 2 and o[2] is Dictionary: _reads(o[2], read)
			if ln.size() > 2 and ln[2] is Dictionary: _reads(ln[2], read)
	for st in StoryScript.STEPS:
		if st.has("if"): _reads(st["if"], read)
	for t in ["gold", "silver", "bronze"]: set_here["launch_" + t] = "launch_control"
	var dead := []
	for f in set_here:
		if not read.has(f) and not read_code.has(f): dead.append("%s (%s)" % [f, set_here[f]])
	check("flags: every flag the story sets is read back somewhere", dead.is_empty(), str(dead))
	var unset := []
	for f in read:
		if not set_here.has(f): unset.append(f)
	check("flags: every flag a line asks for is one the story can set", unset.is_empty(), str(unset))
	# every choice changes something later on: at least one line or step asks for each option
	var dead_choice := []
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			if String(ln[0]) != "choice": continue
			for o in ln[1]:
				if not read.has(String(o[1])): dead_choice.append(String(o[1]))
	check("choices: every option is paid off somewhere later", dead_choice.is_empty(), str(dead_choice))
	# the chapters: who speaks in each (a line in a scene, in the cast or on the phone)
	var chapters := {}
	var cur := "PROLOGUE"
	for st in StoryScript.STEPS:
		if st.type == "card" and (String(st.title).begins_with("CHAPTER") or String(st.title) == "PROLOGUE"): cur = String(st.title)
		if st.type != "scene": continue
		if not chapters.has(cur): chapters[cur] = {}
		for ln in StoryScript.SCENES[st.id].lines:
			var w := String(ln[0])
			if w in ["*", "choice", "set", "cast", "cash", "debt", "flag", "pose"]: continue
			chapters[cur][w.rstrip("0123456789")] = true
	var quiet := []
	for ch in chapters:
		for who in ["MIKEY", "ARIES", "GUS", "FRANKIE"]:
			if who == "FRANKIE" and ch == "PROLOGUE": continue
			if not chapters[ch].has(who): quiet.append("%s: no %s" % [ch, who])
	check("chapters: Mikey, Aries, Gus and Frankie each get a moment in every chapter", quiet.is_empty() and chapters.size() == 9, str(quiet) + " " + str(chapters.keys()))
	var toby := 0
	var tremblay := 0
	for id in StoryScript.SCENES:
		var sc: Dictionary = StoryScript.SCENES[id]
		var standing: Array = (sc.get("cast", []) as Array).map(func(c): return String(c[0]))
		if standing.has("TOBY"): toby += 1
		if standing.has("TREMBLAY"): tremblay += 1
	check("Toby and Tremblay each stand in scenes of their own, not just on the phone", toby >= 2 and tremblay >= 2, "%d / %d" % [toby, tremblay])
	# the house rules: nobody named Vinny, Hatch calls Leo kid and Frank Frankie
	var vinny := false
	var hatch_kid := false
	var hatch_frankie := false
	for id in StoryScript.SCENES:
		for ln in StoryScript.SCENES[id].lines:
			if ln.size() < 2 or not ln[1] is String: continue
			var t := String(ln[1])
			if t.to_upper().contains("VINNY"): vinny = true
			if String(ln[0]) == "HATCH":
				if t.contains("kid"): hatch_kid = true
				if t.contains("Frankie"): hatch_frankie = true
	check("house rules: nobody's called Vinny; Hatch says kid and calls Frank Frankie", not vinny and hatch_kid and hatch_frankie)
	var ai := RegEx.create_from_string("\\b(AI|A\\.I\\.|ARTIFICIAL INTELLIGENCE|GENERATED)\\b")
	var credits_ai := ""
	for r in EndCredits.ROLL:
		if ai.search(String(r[0]).to_upper()): credits_ai += String(r[0]) + "; "
	check("credits: no mention of AI", credits_ai == "", credits_ai)
	# Aries is alive at the end of every ending, and still Leo's sister
	var aries_end := true
	for id in ["clean_end", "middle_end", "street_end"]:
		if not str(StoryScript.SCENES[id].lines).contains("ARIES"): aries_end = false
	check("Aries is there in every ending", aries_end)


func _reads(cond: Dictionary, into: Dictionary) -> void:
	if cond.has("flag"): into[String(cond.flag)] = true
	if cond.has("not_flag"): into[String(cond.not_flag)] = true


## Is this person, in this pose, standing in one of the set's cars? ("" if not)
func _stand(id: String, c: Array, pose: String, st: String) -> String:
	var img := PixPeople.sprite(String(c[0]), pose, 0).get_image()
	var u := img.get_used_rect()
	var left := int(c[1]) - img.get_width() / 2 + (u.position.x if int(c[2]) > 0 else img.get_width() - u.end.x)
	var body := Rect2(left, StorySets.FEET_Y - img.get_height() + u.position.y, u.size.x, u.size.y)
	var out := ""
	for v in StorySets.vehicles_in(st):
		var o := body.intersection(v.rect)
		if o.size.x > 1 and o.size.y > 1: out += "%s: %s (%s) in a car in %s; " % [id, String(c[0]), pose, st]
	return out
