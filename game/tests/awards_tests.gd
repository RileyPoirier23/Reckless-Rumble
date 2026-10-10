## Employee of the Month: what each award takes, the file it's kept in, and that the wall and the
## card hold their text:  godot --headless --path game -s tests/awards_tests.gd
## Works on a scratch awards file; never touches the player's.
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

## A save that's done everything once over.
func _veteran() -> Dictionary:
	var s := SaveGame.default_data()
	for i in 10: (s.garage as Array).append({ "id": "silvio", "paint": "#ffffff", "parts": { "turbo": "turbo_small", "exhaust": "exhaust_cat" }, "tune": {} })
	s.garage[0].tune = { "boost": 1.1 }
	s.cash = 60000
	s.street = { "races": 20, "wins": 12, "rep": 14, "pinks": 1 }
	s.rides = { "count": 30, "stars": 147 }
	s.airstrip_king = true
	s.meets = { "count": 3, "wins": 1 }
	s.tickets = 6
	s.stats = { "m_driven": 1200000, "paint_jobs": 1, "pizza_runs": 60, "tows": 5, "cruise_best_m": 30000, "escapes": 1,
		"hit_moose": 1, "hit_deer": 2, "earned": 12000, "auction_wins": 1, "salvage_buys": 5, "cars_sold": 1, "ran_dry": 1, "totaled": 1 }
	return s

func _init() -> void:
	Awards.path = "user://awards_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Awards.path))
	Awards.load_file()
	var ids := {}
	var dup := ""
	for a in Awards.LIST:
		if ids.has(a.id): dup += String(a.id) + " "
		ids[a.id] = true
	check("every award has its own id", dup == "", dup)
	check("the wall holds every award without scrolling", Awards.LIST.size() <= EmployeeWall.COLS * EmployeeWall.ROWS, "%d" % Awards.LIST.size())
	# a fresh save has won nothing; one that's done it all has won everything
	var fresh := SaveGame.default_data()
	var early := ""
	for a in Awards.LIST:
		if Awards.met(String(a.id), fresh): early += String(a.id) + " "
	check("a new save hasn't earned anything", early == "", early)
	var vet := _veteran()
	var missing := ""
	for a in Awards.LIST:
		if not Awards.met(String(a.id), vet): missing += String(a.id) + " "
	check("every award can be earned", missing == "", missing)
	# the edges
	var s := SaveGame.default_data()
	s.stats = { "m_driven": 999 }
	check("999 m isn't a kilometre", not Awards.met("first_day", s))
	s.stats.m_driven = 1000
	check("1,000 m is", Awards.met("first_day", s))
	s.rides = { "count": 25, "stars": 115 }
	check("25 rides at 4.6 isn't the good driver", not Awards.met("rides_good", s))
	s.rides.stars = 120
	check("25 rides at 4.8 is", Awards.met("rides_good", s))
	# counting into the live save
	var live := SaveGame.default_data()
	Awards.save_ref = {}
	Awards.bump("pizza_runs")
	check("no save on the road: nothing to count into", not live.stats.has("pizza_runs"))
	Awards.save_ref = live
	for i in 10: Awards.bump("pizza_runs")
	Awards.best("cruise_best_m", 30000)
	Awards.best("cruise_best_m", 5000)
	check("bump counts into the save", Awards.stat(live, "pizza_runs") == 10)
	check("best keeps the biggest", Awards.stat(live, "cruise_best_m") == 30000)
	# winning them: in order, a month apart, kept in the file
	var got := Awards.check(live)
	check("check finds what you've just done", got.has("pizza_10") and got.has("cruise"), str(got))
	check("...and only that", got.size() == 2, str(got))
	check("checking again doesn't win them twice", Awards.check(live).is_empty())
	check("the first photo is October 2019", Awards.month_of(0) == "OCTOBER 2019")
	check("then a month at a time, into the new year", Awards.month_of(3) == "JANUARY 2020" and Awards.month_of(15) == "JANUARY 2021", Awards.month_of(3))
	check("the photos are numbered in the order they were won", int(Awards.won.pizza_10.n) == 0 and int(Awards.won.cruise.n) == 1)
	Awards.won = {}
	Awards.load_file()
	check("what you've won survives a restart", Awards.has("pizza_10") and Awards.has("cruise") and Awards.count() == 2)
	var f := FileAccess.open(Awards.path, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	Awards.load_file()
	check("a broken file starts the wall empty", Awards.count() == 0)
	f = FileAccess.open(Awards.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({ "pizza_10": { "at": 1, "n": 0 }, "no_such_award": { "at": 1, "n": 1 } }))
	f.close()
	Awards.load_file()
	check("an award that no longer exists is dropped", Awards.has("pizza_10") and not Awards.has("no_such_award"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Awards.path))
	Awards.save_ref = {}
	# the save keeps its stats
	check("an old save gets a stats book", SaveGame.ensure({ "garage": [] }).has("stats"))
	_layout()
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

func _layout() -> void:
	var bad := ""
	# the frames: on the screen, apart, above the detail panel
	var n := Awards.LIST.size()
	for i in n:
		var r := EmployeeWall.frame_rect(i)
		if not Rect2(0, 0, 640, 360).encloses(r.grow(2)): bad += "frame %d off screen; " % i
		if r.end.y + 2 > EmployeeWall.DETAIL.position.y: bad += "frame %d on the detail panel; " % i
		if r.position.y < 34: bad += "frame %d on the heading; " % i
		for j in range(i + 1, n):
			if r.grow(2).intersects(EmployeeWall.frame_rect(j).grow(2)): bad += "frames %d and %d touch; " % [i, j]
	# the plate fits the month; the detail fits the name and what it takes
	var plate_w := EmployeeWall.FRAME.x - 24
	if PixelFont.width("SEP 2026") > plate_w - 2: bad += "the plate is too small for the month; "
	var tx := EmployeeWall.DETAIL.position.x + 8 + EmployeeWall.PHOTO.x * 1.5 + 10
	for a in Awards.LIST:
		if tx + PixelFont.width(String(a.name) + " (NOT YET)", 2) > EmployeeWall.DETAIL.end.x - 4: bad += "%s runs off the detail panel; " % a.name
		if Hud.wrap_lines(String(a.desc), int((EmployeeWall.DETAIL.end.x - tx - 8) / 4)).size() > 3: bad += "%s: too much to say; " % a.name
		# the card
		if PixelFont.width(String(a.name), 2) > AwardCard.PANEL.size.x - 16: bad += "%s too wide for the card; " % a.name
		if Hud.wrap_lines(String(a.desc), 72).size() > 2: bad += "%s: the card's description runs over; " % a.name
	if EmployeeWall.DETAIL.end.y + 4 > EmployeeWall.HINT_Y: bad += "the detail panel runs into the hint; "
	# the card's photo sits between the heading and the name
	var ph_y := AwardCard.PANEL.position.y + 40
	if ph_y < AwardCard.PANEL.position.y + 26 + 8: bad += "the card's photo is on the month; "
	if ph_y + EmployeeWall.PHOTO.y * 2.0 + 5 + 2 > ph_y + EmployeeWall.PHOTO.y * 2.0 + 12: bad += "the card's frame is on the name; "
	if ph_y + EmployeeWall.PHOTO.y * 2.0 + 28 + 9 + 7 > AwardCard.PANEL.end.y - 34: bad += "the card's description is on the count; "
	check("nothing on the wall or the card runs into anything", bad == "", bad)
