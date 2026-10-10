## Karma: what kind of man Leo is turning into, from what he says and what he does. Cool, calm and
## collected (HIGH), somewhere in between (MIDDLE), or reckless and disrespectful (LOW).
##
## Two halves:
## - his choices in the cutscenes, each worth something (CHOICES). It's worked out from the
##   choices on file, so going back in a scene and picking again only counts the last pick;
## - what he does with a car in the story: tickets, running from the police, putting cars into
##   traffic, bringing the Familia's car back without a scratch (DEEDS), capped per day so one
##   bad night doesn't decide everything.
##
## It changes how people talk to him (lines in the script can ask for a tier), what the road
## costs him (the police give a calm driver a little slack and a reckless one none), and how the
## story ends. On LOW, Frankie learned the wrong things from him: he skips his Sunday brake check
## the week somebody cuts his lines, and the last mission is revenge.
class_name Karma
extends RefCounted

const HIGH := 4.0                     # this much and up is HIGH
const LOW := -4.0                     # this little and down is LOW

## Story choices (the flags they set) and what each says about Leo.
const CHOICES := {
	# the party: are you good to drive?
	"cocky": -2.0, "quiet": 0.0, "joke": -1.0,
	# the meet: Dom's bill for Mia's car
	"meet_agree": 1.5, "meet_defiant": -1.5,
	# Darrell's Silvio
	"checked_silvio": 1.0, "blind_buy": -0.5,
	# the kid in Bay 3
	"kid_light": 2.0, "kid_home": 2.0, "kid_closed": -2.0,
	# what Leo tells Frankie, eight months in
	"mentor_dad": 1.5, "mentor_job": 2.0, "mentor_pizza": 0.5,
	# the finale: Hatch at the counter
	"hatch_calm": 1.5, "hatch_threat": -2.0,
}

## Things Leo does with a car, what each is worth, and the most a kind can move it in one day.
const DEEDS := {
	"crash_traffic": [-0.5, 2.0],     # put a car into somebody else's
	"ticket": [-0.5, 1.5],            # pulled over: a ticket
	"pulled_over": [0.25, 0.5],       # ...but he did pull over
	"escape": [-2.0, 4.0],            # ran from the police and got away
	"impound": [-1.0, 2.0],           # ran and got caught
	"hit_police": [-2.0, 4.0],        # drove into a police car
	"careful": [1.0, 1.0],            # the Familia's car back without a scratch
	"careless": [-0.5, 1.0],          # ...with scratches
	"street_race": [-0.5, 1.0],       # raced on a public road
	"tow_done": [0.5, 1.0],           # pulled somebody out of a ditch
}

## Where Leo stands: the choices on file plus what he's done.
static func score() -> float:
	var s := float(StoryState.flags.get("karma_deeds", 0.0))
	for f in CHOICES:
		if StoryState.flag(f): s += float(CHOICES[f])
	return s

static func tier(s := INF) -> String:
	if s == INF: s = score()
	if s >= HIGH: return "high"
	if s <= LOW: return "low"
	return "middle"

## How people would describe him right now (the pause menu, the chapter cards).
static func describe(t := "") -> String:
	var k := t if t != "" else tier()
	if k == "high": return "COOL, CALM AND COLLECTED"
	if k == "low": return "RECKLESS"
	return "SOMEWHERE IN BETWEEN"

## Something Leo did. Only counts in the story, and only up to the kind's cap in a day.
## Returns how much it moved.
static func deed(kind: String) -> float:
	if not StoryState.active or not DEEDS.has(kind): return 0.0
	var d: Array = DEEDS[kind]
	var today: Dictionary = StoryState.flags.get("karma_today", {})
	if int(today.get("day", -1)) != StoryState.day: today = { "day": StoryState.day }
	var used := float(today.get(kind, 0.0))
	var amount := float(d[0])
	var room := float(d[1]) - absf(used)
	if room <= 0.0: return 0.0
	amount = signf(amount) * minf(absf(amount), room)
	today[kind] = used + amount
	StoryState.flags["karma_today"] = today
	StoryState.flags["karma_deeds"] = float(StoryState.flags.get("karma_deeds", 0.0)) + amount
	return amount

## Does a script line's condition hold? {"karma": "low" | "middle" | "high" | "not_low" |
## "not_high"}, {"flag": name}, {"not_flag": name}; all that are given must hold.
static func holds(cond: Dictionary) -> bool:
	if cond.has("karma"):
		var want := String(cond.karma)
		var t := tier()
		var ok := t != "low" if want == "not_low" else (t != "high" if want == "not_high" else t == want)
		if not ok: return false
	if cond.has("flag") and not StoryState.flag(String(cond.flag)): return false
	if cond.has("not_flag") and StoryState.flag(String(cond.not_flag)): return false
	return true

## The police give a calm driver a little slack over the limit and a reckless one none (km/h).
static func police_slack() -> float:
	if not StoryState.active: return 0.0
	match tier():
		"high": return 5.0
		"low": return -5.0
	return 0.0
