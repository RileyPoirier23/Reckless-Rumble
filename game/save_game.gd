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
	return ensure({ "version": VERSION, "garage": cars, "current": 0 })

## A car's driving spec: the hand-made JSON in data/cars, or else the catalogue's.
static func load_spec(id: String) -> Dictionary:
	if not FileAccess.file_exists("res://data/cars/%s.json" % id): return CarCatalog.spec(id)
	var txt := FileAccess.get_file_as_string("res://data/cars/%s.json" % id)
	var spec = JSON.parse_string(txt)
	return spec if spec is Dictionary else {}

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return default_data()
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (data is Dictionary) or int(data.get("version", 0)) != VERSION: return default_data()
	if (data.garage as Array).is_empty(): return default_data()
	return ensure(data)

static func write(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(data, "\t"))


const START_CASH := 6500

## Fill in anything an older save is missing: money, the clock, orders, the parts shelf, and
## every car's installed parts and looks.
static func ensure(data: Dictionary) -> Dictionary:
	if not data.has("cash"): data.cash = START_CASH
	if not data.has("clock_h"): data.clock_h = 0.0          # game hours since the save began
	if not data.has("orders"): data.orders = []              # [{ part, arrives_h }]
	if not data.has("shelf"): data.shelf = []                # parts delivered, not installed
	for car in data.garage:
		if not car.has("parts"): car.parts = {}             # slot -> part id
		if not car.has("looks"): car.looks = {}
		if not car.has("tune"): car.tune = {}               # the dyno tune: boost, timing
		if not car.has("wear"): car.wear = {}               # clutch, turbo, pads, fluid (CarSim.wear_state)
		if not car.has("installing"): car.installing = []   # [{ slot, part, done_h }] Gus is on it
	return data

## The spec the sim drives for a car in the garage: its base spec with every part bolted on.
static func car_spec(entry: Dictionary) -> Dictionary:
	return Parts.apply(load_spec(String(entry.id)), entry.get("parts", {}), entry.get("tune", {}))

## Installs Gus has finished by now: they move from the bench onto the car. Returns
## [[car index, part id], ...] for the reveal.
static func finish_installs(data: Dictionary) -> Array:
	var done: Array = []
	for i in (data.garage as Array).size():
		var car: Dictionary = data.garage[i]
		var left: Array = []
		for job in car.get("installing", []):
			if float(data.get("clock_h", 0.0)) >= float(job.done_h):
				car.parts[String(job.slot)] = String(job.part)
				done.append([i, String(job.part)])
			else:
				left.append(job)
		car.installing = left
	return done

## How a car looks (for the side-view art): its own looks, plus what its parts show off.
static func car_looks(entry: Dictionary) -> Dictionary:
	var m: Dictionary = (entry.get("looks", {}) as Dictionary).duplicate(true)
	var kit: Dictionary = m.get("kit", {})
	for sl in entry.get("parts", {}):
		var fx := Parts.effects(String(entry.parts[sl]))
		if fx.has("spoiler") and String(m.get("spoiler", "none")) == "none": m.spoiler = fx.spoiler
		if fx.get("kit_lip", false): kit.lip = true
		if fx.has("caliper") and not m.has("caliper"): m.caliper = Color(String(fx.caliper))
		if fx.has("drop") and not m.has("drop"): m.drop = maxf(0.0, float(fx.drop))
	if not kit.is_empty(): m.kit = kit
	if m.has("caliper") and m.caliper is String: m.caliper = Color(String(m.caliper))
	if m.has("rim_color") and m.rim_color is String: m.rim_color = Color(String(m.rim_color))
	if m.has("stripe_color") and m.stripe_color is String: m.stripe_color = Color(String(m.stripe_color))
	return m
