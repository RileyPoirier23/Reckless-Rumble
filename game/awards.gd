## Employee of the Month: DriveBoss's achievements. Each one is a framed photo on the wall of the
## break room at Covington Auto, and the wall fills up a month at a time: the first photo you earn
## is October 2019, the next November, and so on.
##
## What you've won is kept in its own file (user://driveboss_awards.json), apart from any one save,
## like the trophy case in CageBoss. The counts it checks live in the save's `stats` (bumped where
## things happen: `Awards.bump("pizza_runs")`) or are read off the save itself (street rep, the
## garage, the odometers). Tests and demos never touch the player's file.
class_name Awards
extends RefCounted

static var path := "user://driveboss_awards.json"
static var won := {}                   # id -> { "at": unix time, "n": the order it was won in }
static var _loaded := false
## The drive scene's live save: bump() counts into its stats. Empty off the road (then bump() is a no-op).
static var save_ref: Dictionary = {}

## Every award: what it's called, what it takes, and its photo (where it was taken, what's in it).
const LIST := [
	{ "id": "first_day", "name": "FIRST DAY ON THE JOB", "desc": "DRIVE YOUR FIRST KILOMETRE.", "bg": "lot", "prop": "keys" },
	{ "id": "km_100", "name": "PUTTING ON MILES", "desc": "DRIVE 100 KM.", "bg": "road", "prop": "odo" },
	{ "id": "km_1000", "name": "HIGH MILEAGE", "desc": "DRIVE 1,000 KM.", "bg": "road", "prop": "odo" },
	{ "id": "own_6", "name": "THE LOT'S FILLING UP", "desc": "OWN SIX CARS AT ONCE (THE TOW TRUCK COUNTS).", "bg": "lot", "prop": "keys" },
	{ "id": "own_10", "name": "THE COLLECTION", "desc": "OWN TEN CARS AT ONCE.", "bg": "lot", "prop": "car" },
	{ "id": "parts_1", "name": "BOLTED ON", "desc": "HAVE GUS INSTALL A PART.", "bg": "shop", "prop": "wrench" },
	{ "id": "parts_15", "name": "PARTS CANNON", "desc": "FIFTEEN PARTS ON YOUR CARS AT ONCE.", "bg": "shop", "prop": "box" },
	{ "id": "tuned", "name": "DYNO DAY", "desc": "TUNE A CAR ON THE DYNO.", "bg": "shop", "prop": "gauge" },
	{ "id": "paint", "name": "FRESH COAT", "desc": "CHANGE A CAR'S PAINT AT THE BODY SHOP.", "bg": "shop", "prop": "spray" },
	{ "id": "pizza_10", "name": "EXTRA CHEESE", "desc": "DELIVER TEN PIZZAS.", "bg": "night", "prop": "pizza" },
	{ "id": "pizza_50", "name": "PIZZA DELIRIUM HALL OF FAME", "desc": "DELIVER FIFTY PIZZAS.", "bg": "night", "prop": "pizza" },
	{ "id": "rides_10", "name": "FIVE STARS, PROBABLY", "desc": "GIVE TEN HOPP-IN RIDES.", "bg": "night", "prop": "phone" },
	{ "id": "rides_good", "name": "THE GOOD DRIVER", "desc": "TWENTY-FIVE RIDES WITH A 4.8 RATING OR BETTER.", "bg": "night", "prop": "phone" },
	{ "id": "tows_5", "name": "ON THE HOOK", "desc": "FINISH FIVE TOW CALLS.", "bg": "road", "prop": "hook" },
	{ "id": "cruise", "name": "NIGHT DRIVE", "desc": "25 KM ON ONE NIGHT DRIVE.", "bg": "night", "prop": "moon" },
	{ "id": "race_win", "name": "FIRST WIN", "desc": "WIN A STREET RACE.", "bg": "night", "prop": "flag" },
	{ "id": "rep_10", "name": "THEY KNOW YOUR NAME", "desc": "GET YOUR STREET REP TO 10.", "bg": "night", "prop": "flag" },
	{ "id": "pinks", "name": "PINK SLIP", "desc": "WIN A CAR FOR PINKS.", "bg": "night", "prop": "slip" },
	{ "id": "airstrip", "name": "KING OF THE AIRSTRIP", "desc": "BEAT EVERY RUNG AT DRAG NIGHT.", "bg": "strip", "prop": "trophy" },
	{ "id": "meet_win", "name": "BEST IN SHOW", "desc": "WIN THE MEET AT CHAMPAGNE PLACE.", "bg": "night", "prop": "trophy" },
	{ "id": "ticket", "name": "PAID IN FULL", "desc": "GET A TICKET.", "bg": "police", "prop": "ticket" },
	{ "id": "tickets_5", "name": "FREQUENT FLYER", "desc": "GET FIVE TICKETS.", "bg": "police", "prop": "ticket" },
	{ "id": "escape", "name": "GONE", "desc": "LOSE THE POLICE IN A CHASE.", "bg": "police", "prop": "siren" },
	{ "id": "moose", "name": "WILDLIFE CROSSING", "desc": "HIT A MOOSE. LIVE.", "bg": "woods", "prop": "moose" },
	{ "id": "deer", "name": "OH, DEER", "desc": "HIT A DEER.", "bg": "woods", "prop": "deer" },
	{ "id": "earned_10k", "name": "PAYDAY", "desc": "EARN $10,000 FROM GIGS.", "bg": "lot", "prop": "cash" },
	{ "id": "cash_50k", "name": "MONEY IN THE BANK", "desc": "HAVE $50,000.", "bg": "lot", "prop": "cash" },
	{ "id": "auction", "name": "SOLD!", "desc": "WIN A CAR AT THE IMPOUND AUCTION.", "bg": "lot", "prop": "gavel" },
	{ "id": "salvage_5", "name": "JUNKYARD REGULAR", "desc": "BUY FIVE PARTS AT NORTHSIDE SALVAGE.", "bg": "lot", "prop": "box" },
	{ "id": "sold", "name": "FLIPPED IT", "desc": "SELL A CAR ON MARKETTHING.", "bg": "lot", "prop": "sign" },
	{ "id": "ran_dry", "name": "RUNNING ON FUMES", "desc": "RUN OUT OF GAS.", "bg": "pumps", "prop": "gascan" },
	{ "id": "totaled", "name": "WRITTEN OFF", "desc": "TOTAL A CAR.", "bg": "road", "prop": "wreck" },
]

const MONTHS := ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

static func testing() -> bool:
	return GameSettings.testing()

static func ensure() -> void:
	if not _loaded: load_file()

static func load_file() -> void:
	_loaded = true
	won = {}
	if testing() and path == "user://driveboss_awards.json": return
	if not FileAccess.file_exists(path): return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary): return
	for id in d:
		if d[id] is Dictionary and by_id(String(id)).size() > 0: won[String(id)] = { "at": int(d[id].get("at", 0)), "n": int(d[id].get("n", won.size())) }

static func save_file() -> void:
	if testing() and path == "user://driveboss_awards.json": return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(won, "\t"))

static func by_id(id: String) -> Dictionary:
	for a in LIST:
		if String(a.id) == id: return a
	return {}

static func has(id: String) -> bool:
	ensure()
	return won.has(id)

static func count() -> int:
	ensure()
	return won.size()

## The month on a photo: the first one won is October 2019, then one a month after that.
static func month_of(n: int) -> String:
	var m := (9 + n) % 12
	return "%s %d" % [MONTHS[m], 2019 + int((9 + n) / 12)]

# ------------------------------------------------------------------ the counts

## Count something that happened (on the road, with a save to count into).
static func bump(key: String, n := 1) -> void:
	if save_ref.is_empty(): return
	var st: Dictionary = save_ref.get("stats", {})
	st[key] = int(st.get(key, 0)) + n
	save_ref.stats = st

## Keep the biggest of something (the longest night drive).
static func best(key: String, v: int) -> void:
	if save_ref.is_empty(): return
	var st: Dictionary = save_ref.get("stats", {})
	st[key] = maxi(int(st.get(key, 0)), v)
	save_ref.stats = st

static func stat(save: Dictionary, key: String) -> int:
	return int((save.get("stats", {}) as Dictionary).get(key, 0))

## Kilometres you've driven yourself (not what the odometers said when you got the cars).
static func km(save: Dictionary) -> float:
	return stat(save, "m_driven") / 1000.0

static func parts_on(save: Dictionary) -> int:
	var n := 0
	for c in save.get("garage", []):
		for slot in (c.get("parts", {}) as Dictionary):
			if String(c.parts[slot]) != "": n += 1
	return n

static func tuned(save: Dictionary) -> bool:
	for c in save.get("garage", []):
		if not (c.get("tune", {}) as Dictionary).is_empty(): return true
	return false

## Whether you've done what an award takes.
static func met(id: String, save: Dictionary) -> bool:
	var street: Dictionary = save.get("street", {})
	var rides: Dictionary = save.get("rides", {})
	match id:
		"first_day": return km(save) >= 1.0
		"km_100": return km(save) >= 100.0
		"km_1000": return km(save) >= 1000.0
		"own_6": return (save.get("garage", []) as Array).size() >= 6
		"own_10": return (save.get("garage", []) as Array).size() >= 10
		"parts_1": return parts_on(save) >= 1
		"parts_15": return parts_on(save) >= 15
		"tuned": return tuned(save)
		"paint": return stat(save, "paint_jobs") >= 1
		"pizza_10": return stat(save, "pizza_runs") >= 10
		"pizza_50": return stat(save, "pizza_runs") >= 50
		"rides_10": return int(rides.get("count", 0)) >= 10
		"rides_good": return int(rides.get("count", 0)) >= 25 and Rides.average(save) >= 4.8
		"tows_5": return stat(save, "tows") >= 5
		"cruise": return stat(save, "cruise_best_m") >= 25000
		"race_win": return int(street.get("wins", 0)) >= 1
		"rep_10": return int(street.get("rep", 0)) >= 10
		"pinks": return int(street.get("pinks", 0)) >= 1
		"airstrip": return bool(save.get("airstrip_king", false))
		"meet_win": return int((save.get("meets", {}) as Dictionary).get("wins", 0)) >= 1
		"ticket": return int(save.get("tickets", 0)) >= 1
		"tickets_5": return int(save.get("tickets", 0)) >= 5
		"escape": return stat(save, "escapes") >= 1
		"moose": return stat(save, "hit_moose") >= 1
		"deer": return stat(save, "hit_deer") >= 1
		"earned_10k": return stat(save, "earned") >= 10000
		"cash_50k": return int(save.get("cash", 0)) >= 50000
		"auction": return stat(save, "auction_wins") >= 1
		"salvage_5": return stat(save, "salvage_buys") >= 5
		"sold": return stat(save, "cars_sold") >= 1
		"ran_dry": return stat(save, "ran_dry") >= 1
		"totaled": return stat(save, "totaled") >= 1
	return false

## Check every award against a save; returns the ids just won (and keeps them).
static func check(save: Dictionary) -> Array:
	ensure()
	var fresh: Array = []
	for a in LIST:
		var id := String(a.id)
		if won.has(id): continue
		if met(id, save):
			won[id] = { "at": int(Time.get_unix_time_from_system()), "n": won.size() }
			fresh.append(id)
	if not fresh.is_empty(): save_file()
	return fresh
