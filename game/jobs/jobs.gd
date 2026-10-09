## The evening jobs: what's on the board, where they go, and what they pay. Pure data and
## functions; JobRunner runs a job in the drive scene and DragStrip runs Drag Night.
class_name Jobs
extends RefCounted

const COVINGTON := Vector2(5570, 1566)
const IMPOUND := Vector2(6250, 960)           # Northside impound lot, in the industrial park

## kind -> board entry. "open" is [from, to] in hours; "to" past 24 runs past midnight.
const KINDS := {
	"pizza": { "title": "PIZZA DELIRIUM", "open": [17.0, 23.0],
		"blurb": "Thirty minutes or it's free. Corner hard and the pizza ends up on the lid.",
		"pay": "$6 A RUN + TIPS" },
	"tow": { "title": "TOW CALL", "open": [0.0, 24.0],
		"blurb": "Somebody's in the ditch. Toby's wrecker, the boom, and a slow drive back.",
		"pay": "$90 + $2.50/KM, MORE AT NIGHT AND IN WEATHER" },
	"drag": { "title": "DRAG NIGHT AT AIRSTRIP 7", "open": [19.0, 27.0],
		"blurb": "Eighth-mile bracket racing. Set a dial-in, beat the tree, don't break out.",
		"pay": "PURSE AND SIDE BETS" },
	"cruise": { "title": "NIGHT DRIVE", "open": [21.0, 29.0],
		"blurb": "No job. No phone. No GPS voice. Just the road and the radio you don't have yet.",
		"pay": "NOTHING. THAT'S THE POINT." },
}
const ORDER := ["pizza", "tow", "drag", "cruise"]

## The drag ladder at Airstrip 7, slowest crew first. Each racer: car, how fast they react,
## how close they run to their dial-in, entry fee, and what they say.
const LADDER := [
	{ "name": "PERCY 'PAPERBOY' LEBLANC", "car": "chevrolay_shovette_1984", "rt": [0.35, 0.65], "spread": 0.30, "fee": 20,
		"line": "\"I deliver papers in this thing. I am FAST at delivering papers.\"" },
	{ "name": "THE GALLANT TWINS", "car": "hondo_civil_ess_eye_1999", "rt": [0.25, 0.50], "spread": 0.22, "fee": 40,
		"line": "\"One of us drives. Neither of us will tell you which.\"" },
	{ "name": "DOUG FROM THE PARTS COUNTER", "car": "fjord_mustank_1988", "rt": [0.20, 0.40], "spread": 0.15, "fee": 60,
		"line": "\"That's a forty-dollar part you're running there. I sold it to you.\"" },
	{ "name": "SHAYLA RICHARD", "car": "toyoda_supreem_twin_turbo_1995", "rt": [0.12, 0.30], "spread": 0.10, "fee": 100,
		"line": "\"Two turbos. One attitude. Try to keep up on the tree.\"" },
	{ "name": "BIG MARC GAUDET", "car": "chevrolay_shovelle_ess_ess_1970", "rt": [0.08, 0.22], "spread": 0.07, "fee": 150,
		"line": "\"Your dad used to run this lane. He never broke out. Not once.\"" },
	{ "name": "JOHNNY TRAM", "car": "fjord_gt_fourty_ish_2005", "rt": [0.03, 0.14], "spread": 0.04, "fee": 250,
		"line": "\"Airstrip 7 is mine. You can rent it for an eighth of a mile.\"" },
]

## Is a job open at this hour of the day (0..24)?
static func open_now(kind: String, hour: float) -> bool:
	var o: Array = KINDS[kind].open
	var from: float = o[0]
	var to: float = o[1]
	if to <= 24.0: return hour >= from and hour < to
	return hour >= from or hour < to - 24.0

static func opens_at(kind: String) -> String:
	var from: float = KINDS[kind].open[0]
	return "%02d:00" % int(from)

## Pizza: $6 a delivery plus a tip of $2 + $8 x on-time x condition. Late is measured in
## grace periods: one full grace late and the tip is just the $2.
static func pizza_pay(late_s: float, grace_s: float, condition: float) -> Dictionary:
	var on_time := maxf(0.0, 1.0 - maxf(0.0, late_s) / maxf(grace_s, 1.0))
	var tip := 2.0 + 8.0 * on_time * clampf(condition, 0.0, 1.0)
	return { "base": 6, "tip": int(round(tip)), "total": 6 + int(round(tip)) }

## Real seconds to make a delivery of this route length: a fair city pace plus a cushion.
static func pizza_limit(route_m: float) -> float:
	return route_m / 11.0 * 1.25 + 25.0

## Tow pay: $90 a hook, $2.50 a km towed, $40 at night, $60 in bad weather.
static func tow_pay(km: float, night: bool, bad_weather: bool) -> int:
	return int(round(90.0 + 2.5 * maxf(km, 0.0) + (40.0 if night else 0.0) + (60.0 if bad_weather else 0.0)))

static func bad_weather(weather: String) -> bool:
	return weather in ["rain", "storm", "snow", "blizzard", "freezing", "fog", "drizzle"]

static func is_night(hour: float) -> bool:
	return hour >= 21.0 or hour < 6.0

## What the drag rung costs and pays.
static func drag_purse(rung: int) -> Dictionary:
	var r: Dictionary = LADDER[clampi(rung, 0, LADDER.size() - 1)]
	var fee := int(r.fee)
	return { "fee": fee, "win": fee * 2 + 25 * (rung + 1) + (500 if rung == LADDER.size() - 1 else 0) }

## Bracket racing: the slower dial-in leaves first by the difference, first to the line wins,
## and running quicker than your own dial-in (breaking out) loses. A red light loses outright.
## Each lane: { dial, rt, et, red }. Returns 0 (left lane) or 1 (right lane) and why.
static func drag_winner(a: Dictionary, b: Dictionary) -> Dictionary:
	if bool(a.red) and bool(b.red): return { "lane": 0 if float(a.rt) > float(b.rt) else 1, "why": "BOTH RED. THE LATER ONE TAKES IT." }
	if bool(a.red): return { "lane": 1, "why": "RED LIGHT" }
	if bool(b.red): return { "lane": 0, "why": "RED LIGHT" }
	var out_a := float(a.dial) - float(a.et)
	var out_b := float(b.dial) - float(b.et)
	if out_a > 0.0 and out_b > 0.0: return { "lane": 0 if out_a < out_b else 1, "why": "BOTH BROKE OUT. THE SMALLER BREAKOUT WINS." }
	if out_a > 0.0: return { "lane": 1, "why": "BREAKOUT" }
	if out_b > 0.0: return { "lane": 0, "why": "BREAKOUT" }
	var dmax := maxf(float(a.dial), float(b.dial))
	var fin_a := (dmax - float(a.dial)) + float(a.rt) + float(a.et)
	var fin_b := (dmax - float(b.dial)) + float(b.rt) + float(b.et)
	return { "lane": 0 if fin_a <= fin_b else 1, "why": "FIRST TO THE STRIPE" }

# ------------------------------------------------------------------ places on the map

## Pizza Delirium is the PIZZA shop closest to Covington Auto: where it is, and the road in front.
static func pizza_shop(map: MapData) -> Dictionary:
	var best := {}
	var best_d := INF
	for b in map.buildings:
		if String(b.name) != "PIZZA": continue
		var c: Vector2 = (b.r as Rect2).get_center()
		var d := c.distance_to(COVINGTON)
		if d < best_d:
			best_d = d
			best = b
	if best.is_empty(): return { "p": road_point(map, COVINGTON), "building": {} }
	return { "p": road_point(map, (best.r as Rect2).get_center()), "building": best }

## The point on the nearest road (where a car can stop), or the point itself if none is near.
static func road_point(map: MapData, m: Vector2) -> Vector2:
	var r := map.nearest_road(m, 80.0)
	return r.point if not r.is_empty() else m

## Addresses for a pizza run: houses between min_d and max_d metres away, each with the road
## in front of it and a street number.
static func addresses(map: MapData, rng: RandomNumberGenerator, from: Vector2, n: int, min_d := 250.0, max_d := 1400.0) -> Array:
	var houses: Array = []
	for b in map.buildings:
		if String(b.kind) != "house": continue
		var c: Vector2 = (b.r as Rect2).get_center()
		var d := c.distance_to(from)
		if d >= min_d and d <= max_d: houses.append(c)
	var out: Array = []
	var tries := 0
	while out.size() < n and not houses.is_empty() and tries < 60:
		tries += 1
		var c: Vector2 = houses[rng.randi() % houses.size()]
		var rd := map.nearest_road(c, 60.0)
		if rd.is_empty(): continue
		var p: Vector2 = rd.point
		var dup := false
		for o in out:
			if (o.p as Vector2).distance_to(p) < 60.0: dup = true
		if dup: continue
		out.append({ "p": p, "house": c, "label": "%d %s" % [10 + rng.randi() % 380, String(rd.road.name)] })
	return out

## A car broken down on a shoulder somewhere between min_d and max_d metres away.
static func tow_spot(map: MapData, rng: RandomNumberGenerator, from: Vector2, min_d := 500.0, max_d := 2500.0) -> Dictionary:
	for i in 200:
		var rd: Dictionary = map.roads[rng.randi() % map.roads.size()]
		if not String(rd.cls) in ["street", "arterial", "rural", "gravel"]: continue
		var pts: PackedVector2Array = rd.pts
		if pts.size() < 2: continue
		var k := rng.randi() % (pts.size() - 1)
		var a := pts[k]
		var b := pts[k + 1]
		if a.distance_to(b) < 20.0: continue
		var p := a.lerp(b, 0.3 + rng.randf() * 0.4)
		var d := p.distance_to(from)
		if d < min_d or d > max_d: continue
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var at := p + side * (float(rd.w) * 0.5 + 1.2)
		return { "p": at, "road_p": p, "heading": dir.angle(), "road": String(rd.name) }
	return {}

static func weekday(day: int) -> String:
	return ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"][posmod(day, 7)]
