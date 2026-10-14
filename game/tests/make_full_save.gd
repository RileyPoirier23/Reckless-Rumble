## A finished game, for testing: every car in the garage, every part on the shelf, the story
## done (the good ending), every award, max rep, a fat wallet.
##   godot --headless --path game -s tests/make_full_save.gd -- <out_dir>
## writes driveboss_save.json, driveboss_story.json and driveboss_awards.json there. Drop the
## three into the game's user folder (Windows: %APPDATA%\Godot\app_userdata\DriveBoss\).
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0] if a.size() > 0 else "user://full_save"
	DirAccess.make_dir_recursive_absolute(out)
	# the garage: the story cars and the wrecker first, then the whole catalogue
	var garage: Array = []
	var ids: Array = ["silvio", "supreem", "charjer", "tow"]
	for id in CarCatalog.ids():
		if not ids.has(id): ids.append(id)
	for id in ids:
		var spec: Dictionary = SaveGame.load_spec(String(id))
		if spec.is_empty(): continue
		garage.append({ "id": String(id), "paint": String(spec.get("paint", "#8a8e94")), "damage": { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 },
			"parts": {}, "looks": {}, "tune": {}, "wear": { "fuel": 1.0 }, "installing": [], "odo_km": 12000.0, "story": id in ["silvio", "supreem", "charjer"] })
	var shelf: Array = []
	for pid in Parts.CATALOG: shelf.append(String(pid))
	var save := {
		"version": SaveGame.VERSION, "garage": garage, "current": 0, "cash": 2500000, "clock_h": 900.0, "orders": [], "shelf": shelf,
		"stats": { "km": 2500.0, "pizza": 60, "rides": 60, "tows": 20, "cruise": 10, "helped": 12, "earned": 60000, "tuned": 5, "paint": 5, "escape": 3,
			"hit_moose": 1, "hit_deer": 2, "ran_dry": 1, "totaled": 1, "auction": 2, "sold": 3, "salvage": 8, "tickets": 5, "races": 40, "race_win": 25 },
		"street": { "races": 60, "wins": 50, "rep": 10, "pinks": 6 }, "drag_rung": Jobs.LADDER.size() - 1, "airstrip_king": true,
		"meets": { "count": 20, "wins": 10 }, "rides": { "count": 60, "stars": 290 }, "salvage": { "day": 0, "bought": [] },
		"crew": { "oneton": true, "bry": true }, "heat": 0.0, "tickets": 5, "warnings": 3, "tips_seen": [], "burnout_best": 90.0,
		"cal": { "day": 140, "time_h": 9.0, "season": "summer", "season_day": 12 },
	}
	_write(out + "/driveboss_save.json", save)
	# the story: done, the way it goes when Leo raised Frankie right
	var flags := { "frankie_safe": true, "mentor_dad": true, "kid_home": true, "gift_dont": true, "johnny_fair": true, "tremblay_trust": true,
		"money_sign": true, "fleet_no": true, "aries_rules": true, "sal_tremblay": true, "pinks_return": true, "keys_take": true, "karma_deeds": 24.0 }
	# (parked on the credits: CONTINUE rolls them again and comes back to the title)
	_write(out + "/driveboss_story.json", { "step": StoryScript.STEPS.size() - 1, "flags": flags, "cash": 48000, "debt": 0, "day": 140,
		"avatar": { "name": "LEO", "seed": 7, "female": 0, "age": 52 }, "last_result": {} })
	# every award
	Awards.path = out + "/driveboss_awards.json"
	Awards.won = {}
	var n := 0
	for aw in Awards.LIST:
		n += 1
		Awards.won[String(aw.id)] = { "at": int(Time.get_unix_time_from_system()) - (40 - n) * 86400, "n": n }
	Awards.save_file()
	print("full save: %d cars, %d parts, %d awards, story step %d -> %s" % [garage.size(), shelf.size(), Awards.won.size(), StoryScript.STEPS.size() - 1, out])
	quit()

func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
