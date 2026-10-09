## The save file: which cars are in your garage, how they look, what shape they're in, and
## which one you drove last. Plain JSON in the user folder.
class_name SaveGame
extends RefCounted

const PATH := "user://driveboss_save.json"
const VERSION := 1

## The cars you start with in free drive. (In the story you start with the Silvio and earn the rest.)
const STARTERS := ["silvio", "supreem", "charjer", "tow"]

static func default_data() -> Dictionary:
	var cars: Array = []
	for id in STARTERS:
		var spec: Dictionary = load_spec(id)
		cars.append({ "id": id, "paint": spec.get("paint", "#c8342c"), "damage": { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, "odo_km": 0.0 })
	return { "version": VERSION, "garage": cars, "current": 0 }

static func load_spec(id: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string("res://data/cars/%s.json" % id)
	var spec = JSON.parse_string(txt)
	return spec if spec is Dictionary else {}

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return default_data()
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (data is Dictionary) or int(data.get("version", 0)) != VERSION: return default_data()
	if (data.garage as Array).is_empty(): return default_data()
	return data

static func write(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(data, "\t"))
