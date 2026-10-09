## HOPP-IN, the ride app: who's in the back, what they pay, and how they rate you. Pure data and
## functions; JobRunner runs the rides.
class_name Rides
extends RefCounted

const BASE := 3.5              # $ for getting in
const PER_KM := 1.25           # $ a (real) km
const MAP_KM := 8.0            # the map is drawn at about 1:8
const CLEANING := 50
const DEACTIVATE_BELOW := 4.2  # stars, averaged, once you've done a few

## Who calls a ride: when they're about, how much shaking they'll stand (g), what they care about,
## and what they say.
const TYPES := {
	"hurry": { "hours": [6.0, 22.0], "w": 1.0, "tol": 0.8, "wants_speed": true,
		"names": ["KAYLEE", "JORDAN", "MARC-ANDRE", "BRITTANY"],
		"hi": ["\"I'M LATE FOR MY SHIFT AT THE CALL CENTRE. LIKE, LATE LATE.\"", "\"CAN YOU GO FASTER? I'LL TIP. PROBABLY.\""],
		"talk": ["\"YOU CAN GO ON YELLOW. EVERYBODY GOES ON YELLOW.\"", "\"MY BOSS IS TEXTING ME IN ALL CAPS.\""] },
	"nervous": { "hours": [9.0, 20.0], "w": 1.0, "tol": 0.3,
		"names": ["MEMERE THERIAULT", "MRS. GALLANT", "AUNT RITA", "MR. BOURQUE"],
		"hi": ["\"I'M GOING TO BINGO, DEAR. THERE'S NO RUSH. THERE'S NEVER A RUSH.\"", "\"MY GRANDSON SET THIS UP ON MY PHONE. ARE YOU THE CAR?\""],
		"talk": ["\"OH! OH. YOU'RE FINE. YOU'RE FINE.\"", "\"MY LATE HUSBAND DROVE A CAR JUST LIKE THIS. SLOWER.\""] },
	"chatty": { "hours": [7.0, 23.0], "w": 1.2, "tol": 0.55,
		"names": ["GERRY", "DENISE", "PAUL-EMILE", "SHANE"],
		"hi": ["\"HOW'S IT GOING? YOU'RE NOT FROM AWAY, ARE YOU?\"", "\"GOOD NIGHT FOR A DRIVE. I SAY THAT EVERY NIGHT.\""],
		"talk": ["\"I JUST BOUGHT A SNOWBLOWER. TWO-STAGE. YOU WANT TO HEAR ABOUT IT?\"", "\"MY COUSIN WORKS AT THE REFINERY. NOT THE ONE YOU'RE THINKING OF.\"", "\"THEY'RE PUTTING A ROUNDABOUT IN. NOBODY KNOWS HOW TO DO A ROUNDABOUT.\""] },
	"party": { "hours": [22.0, 28.0], "w": 1.6, "tol": 0.45, "sick": true,
		"names": ["TYLER & THE BOYS", "CHELSEA (AND HER FRIEND)", "BIG DAVE", "THE BACHELORETTE PARTY"],
		"hi": ["\"ARE YOU OUR RIDE? YOU'RE NOT OUR RIDE. YOU'LL DO.\"", "\"CAN WE STOP AT TIM BURTONS? NO? OKAY. OKAY.\""],
		"talk": ["\"TURN IT UP. THERE'S NO RADIO? TURN UP THE ENGINE.\"", "\"I LOVE YOU, MAN. I DON'T KNOW YOU. I LOVE YOU.\""] },
	"quiet": { "hours": [0.0, 24.0], "w": 0.8, "tol": 1.2,
		"names": ["A GUY IN A HOODIE", "NURSE ON NIGHTS", "SOMEONE'S DAD"],
		"hi": ["(THEY NOD. THE HEADPHONES STAY IN.)", "\"HEY.\""],
		"talk": ["(TINNY MUSIC FROM THE HEADPHONES.)"] },
}
const ORDER := ["hurry", "nervous", "chatty", "party", "quiet"]

static func _in_hours(t: Dictionary, hour: float) -> bool:
	var from: float = t.hours[0]
	var to: float = t.hours[1]
	if to <= 24.0: return hour >= from and hour < to
	return hour >= from or hour < to - 24.0

## Who's calling at this hour.
static func pick_type(hour: float, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	var total := 0.0
	for k in ORDER:
		if _in_hours(TYPES[k], hour):
			pool.append(k)
			total += float(TYPES[k].w)
	var x := rng.randf() * total
	for k in pool:
		x -= float(TYPES[k].w)
		if x <= 0.0: return k
	return "quiet"

## The fare for a ride of this many map metres.
static func fare(route_m: float) -> int:
	return int(round(BASE + PER_KM * route_m / 1000.0 * MAP_KM))

## How long they expect it to take (s), for the ones in a hurry.
static func expected_s(route_m: float) -> float:
	return route_m / 12.0 + 20.0

## The stars: start at five, lose them for shaking them about (past what they'll stand), for
## speeding, for hitting things, for being slow when they're late, and for making them sick.
## `rough` is the g-seconds past their tolerance, `over` the km/h-seconds over the limit.
static func stars(kind: String, rough: float, over: float, hits: int, late_s: float, sick: bool) -> int:
	var t: Dictionary = TYPES[kind]
	var s := 5.0 - rough * 1.2 - hits * 1.5
	if t.has("wants_speed"):
		s -= clampf(late_s / 30.0, 0.0, 2.0)
		s += 0.5 if late_s < -20.0 else 0.0
	else:
		s -= over / 300.0
	if sick: s = 1.0
	return clampi(int(round(s)), 1, 5)

static func tip(fare_d: int, star: int) -> int:
	return int(round(fare_d * [0.0, 0.0, 0.0, 0.0, 0.1, 0.2][star]))

## Your average, and whether HOPP-IN has had enough of you for today.
static func average(save: Dictionary) -> float:
	var r: Dictionary = save.get("rides", {})
	return float(r.get("stars", 0)) / maxf(float(r.get("count", 0)), 1.0) if int(r.get("count", 0)) > 0 else 5.0

static func deactivated(save: Dictionary, day: int) -> bool:
	return int(save.get("rides", {}).get("off_day", -1)) == day

## Record a ride; returns true when that's it for today.
static func record(save: Dictionary, star: int, day: int) -> bool:
	var r: Dictionary = save.get("rides", { "count": 0, "stars": 0 })
	r.count = int(r.get("count", 0)) + 1
	r.stars = int(r.get("stars", 0)) + star
	# the app averages your last few; a run of bad ones and you're off for the day
	var recent: Array = r.get("recent", [])
	recent.append(star)
	if recent.size() > 5: recent = recent.slice(recent.size() - 5)
	r.recent = recent
	var off := false
	if recent.size() >= 3:
		var sum := 0.0
		for x in recent: sum += float(x)
		if sum / recent.size() < DEACTIVATE_BELOW and star <= 3:
			r.off_day = day
			r.recent = []
			off = true
	save.rides = r
	return off
