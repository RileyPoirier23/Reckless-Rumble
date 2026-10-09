## Where you are in the story, and everything the story remembers about you. One static
## state shared by every scene (cutscenes, the counter, the drive), saved to its own file.
##
## The story is a list of steps (StoryScript.STEPS). Each step is one of:
## - "scene":   a cutscene (StoryScene plays it)
## - "avatar":  make the old manager (the avatar screen)
## - "counter": a shift at the counter (CLOCK IN ... CLOCK OUT)
## - "drive":   the evening in your car, with a mission
## - "card":    a title card ("CHAPTER 1: WRONG TURF", "SIX MONTHS LATER")
class_name StoryState
extends RefCounted

const PATH := "user://driveboss_story.json"

static var active := false          # true while playing the story (not the free modes)
static var step := 0
static var flags := {}
static var cash := 340              # Leo's own money (the shop's books are the counter's)
static var debt := 4200             # what the Familia says Mia's car was worth (it wasn't)
static var day := 0                 # story days since the crash
static var avatar := { "name": "", "seed": 0, "female": 0, "age": 52 }
static var last_result := {}        # the last mission or shift's outcome, for the next scene to mention

static func new_game() -> void:
	step = 0
	flags = {}
	cash = 340
	debt = 4200
	day = 0
	avatar = { "name": "", "seed": 0, "female": 0, "age": 52 }
	last_result = {}
	active = true
	save()

static func has_save() -> bool:
	return FileAccess.file_exists(PATH)

static func load_game() -> bool:
	if not has_save(): return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (d is Dictionary): return false
	step = int(d.get("step", 0))
	flags = d.get("flags", {})
	cash = int(d.get("cash", 340))
	debt = int(d.get("debt", 4200))
	day = int(d.get("day", 0))
	avatar = d.get("avatar", avatar)
	last_result = d.get("last_result", {})
	active = true
	return true

static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify({ "step": step, "flags": flags, "cash": cash, "debt": debt, "day": day,
		"avatar": avatar, "last_result": last_result }, "\t"))

static func current() -> Dictionary:
	if step < 0 or step >= StoryScript.STEPS.size(): return { "type": "end" }
	return StoryScript.STEPS[step]

## Move on to the next step and go to whichever scene plays it.
static func advance(tree: SceneTree) -> void:
	step += 1
	var s := current()
	if s.get("day_ends", false): day += 1
	save()
	go(tree)

static func go(tree: SceneTree) -> void:
	var s := current()
	match String(s.type):
		"scene", "card": tree.change_scene_to_file("res://story/story.tscn")
		"avatar": tree.change_scene_to_file("res://story/avatar.tscn")
		"counter": LoadingScreen.go(tree, "res://counter.tscn", "COVINGTON AUTO: CLOCKING IN")
		"drive": LoadingScreen.go(tree, "res://drive.tscn", String(StoryMissions.MISSIONS.get(String(s.get("mission", "")), {}).get("title", "THE ROAD")))
		_:
			active = false
			tree.change_scene_to_file("res://title.tscn")

static func flag(k: String) -> bool:
	return bool(flags.get(k, false))

static func set_flag(k: String, v = true) -> void:
	flags[k] = v

## The old manager's name, for lines that use it (falls back to a placeholder).
static func manager() -> String:
	var n: String = String(avatar.get("name", ""))
	return n if n != "" else "THE OLD MANAGER"

## Replace {MANAGER}, {CASH}, {DEBT} in a line.
static func fill(t: String) -> String:
	return t.replace("{MANAGER}", manager()).replace("{CASH}", str(cash)).replace("{DEBT}", str(debt))
