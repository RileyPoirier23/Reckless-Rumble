## "YOU DIED BECAUSE..." The meme death screens: what killed you, picked to match what you hit,
## what you were driving and how (drunk, on ice, in reverse, with your blinker on...).
## A caption is [cause, car, [conditions], text]. "*" matches anything. The more specific a
## caption is to what just happened, the likelier it shows up.
class_name DeathMemes
extends RefCounted

const CAPTIONS := [
	# ---------------------------------------------------------------- trees
	["tree", "*", [], "YOU DIED BECAUSE YOU TRIED TO OVERTAKE A TREE. THE TREE WAS NOT MOVING."],
	["tree", "*", [], "YOU DIED BECAUSE THAT TREE HAS BEEN STANDING THERE SINCE 1890 AND IT WASN'T ABOUT TO MOVE FOR YOU."],
	["tree", "*", [], "YOU DIED BECAUSE YOU HUGGED A TREE AT 110 KM/H. THE TREE DID NOT HUG BACK."],
	["tree", "*", ["fall"], "YOU DIED BECAUSE YOU WANTED TO SEE THE FALL COLOURS UP CLOSE."],
	["tree", "*", ["fall"], "YOU DIED BECAUSE WET LEAVES HAVE THE GRIP OF A BANANA PEEL AND YOU HAVE THE BRAKING OF A BANANA."],
	["tree", "*", ["winter"], "YOU DIED BECAUSE YOU RUN ALL-SEASONS. NEW BRUNSWICK HAS A FIFTH SEASON."],
	["tree", "*", ["ice"], "YOU DIED BECAUSE YOU FOUND THE BLACK ICE. CONGRATULATIONS. IT FOUND YOU BACK."],
	["tree", "*", ["night", "nolights"], "YOU DIED BECAUSE YOUR HEADLIGHTS WERE OFF. SO WERE THE TREE'S."],
	["tree", "*", ["impaired"], "YOU DIED BECAUSE YOU SAW TWO TREES AND AIMED BETWEEN THEM."],
	["tree", "*", ["rain"], "YOU DIED BECAUSE YOU HYDROPLANED ON TIRES YOU SWORE HAD 'ONE MORE SEASON' IN THEM."],
	["tree", "silvio", ["handbrake"], "YOU DIED BECAUSE YOU PULLED THE E-BRAKE AND SAID 'WATCH THIS.'"],
	["tree", "silvio", [], "YOU DIED BECAUSE YOU STARTED A TANDEM WITH A MAPLE. THE MAPLE WON ON STYLE POINTS."],
	["tree", "silvio", ["wheeloff"], "YOU DIED BECAUSE YOUR MARKETTHING WHEEL SPACERS NUKED YOUR WHEEL BEARINGS."],
	["tree", "supreem", [], "YOU DIED BECAUSE A 1986 TOYODA HAS THE CRUMPLE ZONE OF A FILING CABINET."],
	["tree", "supreem", [], "YOU DIED BECAUSE YOU TRUSTED 33-YEAR-OLD BRAKES. THEY TRUSTED YOU TOO. EVERYBODY WAS WRONG."],
	["tree", "charjer", [], "YOU DIED BECAUSE YOU LEFT CARS AND COFFEE IN A CHARJER. A TREE WAS IN ATTENDANCE."],
	["tree", "charjer", [], "YOU DIED BECAUSE 370 HORSEPOWER AND ZERO BRAIN CELLS IS A WELL-KNOWN COMBINATION."],
	["tree", "tow", [], "YOU DIED BECAUSE YOU TRIED TO TOW A TREE WITHOUT HOOKING IT UP FIRST."],
	["tree", "tow", [], "YOU DIED BECAUSE NOW TOBY HAS TO CALL A TOW TRUCK FOR HIS TOW TRUCK."],
	# ---------------------------------------------------------------- buildings
	["building", "*", [], "YOU DIED BECAUSE YOU TRIED TO USE THE DRIVE-THRU WITHOUT USING THE DRIVE-THRU."],
	["building", "*", [], "YOU DIED BECAUSE THAT BUILDING HAS A CONCRETE FOUNDATION. YOU HAVE 1.6 MM OF TREAD."],
	["building", "*", [], "YOU DIED BECAUSE YOU TRIED TO TAKE A SHORTCUT THROUGH SOMEBODY'S LIVING ROOM."],
	["building", "*", ["downtown"], "YOU DIED BECAUSE YOU TREATED MAIN STREET LIKE A DRAG STRIP. MAIN STREET IS MADE OF BRICK."],
	["building", "*", ["reverse"], "YOU DIED BECAUSE YOU BACKED INTO A BUILDING AT HIGHWAY SPEED. HONESTLY? IMPRESSIVE."],
	["building", "*", ["impaired"], "YOU DIED BECAUSE YOU TRIED TO PARK INSIDE THE LIQUOR STORE."],
	["building", "*", ["night"], "YOU DIED BECAUSE THE SIGN SAID OPEN 24 HOURS AND YOU TOOK IT PERSONALLY."],
	["building", "*", ["ice"], "YOU DIED BECAUSE THE TOWN SALTED THE ROADS ON TUESDAY. TODAY IS NOT TUESDAY."],
	["building", "charjer", [], "YOU DIED BECAUSE YOU GAVE A CHARJER A STRAIGHT LINE AND THE STRAIGHT LINE ENDED."],
	["building", "silvio", [], "YOU DIED BECAUSE YOU TRIED TO DRIFT A PARKING LOT THAT WAS ONE BUILDING TOO SMALL."],
	["building", "supreem", [], "YOU DIED BECAUSE THE SUPREEM IS FROM 1986, AND SO IS ITS IDEA OF AN AIRBAG: YOUR FACE."],
	["building", "tow", [], "YOU DIED BECAUSE THE BUILDING DID NOT NEED A TOW. IT NEEDED YOU TO STOP."],
	# ---------------------------------------------------------------- guardrails and bridges
	["rail", "*", [], "YOU DIED BECAUSE THE GUARDRAIL WAS INSTALLED BY THE LOWEST BIDDER. SO WAS YOUR CAR."],
	["rail", "*", [], "YOU DIED BECAUSE THE GUARDRAIL DID ITS JOB. YOU JUST DIDN'T DO YOURS."],
	["rail", "*", ["winter"], "YOU DIED BECAUSE BRIDGES FREEZE BEFORE THE ROAD DOES. THE SIGN SAID SO. YOU DON'T READ SIGNS."],
	["rail", "*", ["impaired"], "YOU DIED BECAUSE THE BRIDGE WAS TWO LANES WIDE AND YOU NEEDED FOUR."],
	["rail", "tow", [], "YOU DIED BECAUSE THREE TONNES OF FJORD WRECKER IS MORE THAN ANY GUARDRAIL SIGNED UP FOR."],
	# ---------------------------------------------------------------- the river
	["water", "*", [], "YOU DIED BECAUSE THE CHOCOLATE RIVER IS NOT ACTUAL CHOCOLATE."],
	["water", "*", [], "YOU DIED BECAUSE YOU TRIED TO SURF THE TIDAL BORE IN A CAR."],
	["water", "*", [], "YOU DIED BECAUSE THE GPS SAID 'TURN RIGHT' AND YOU DIDN'T SEE THE RIVER. THE GPS DID."],
	["water", "*", ["winter"], "YOU DIED BECAUSE THE ICE WAS 'PROBABLY THICK ENOUGH.'"],
	["water", "*", ["impaired"], "YOU DIED BECAUSE YOU TOOK THE SCENIC ROUTE. INTO THE SCENERY."],
	["water", "supreem", [], "YOU DIED BECAUSE A 1986 TOYODA DOES NOT FLOAT. IT RUSTS. FASTER NOW."],
	["water", "silvio", [], "YOU DIED BECAUSE THE SILVIO IS REAR-WHEEL DRIVE, NOT AMPHIBIOUS."],
	["water", "charjer", [], "YOU DIED BECAUSE A CHARJER WEIGHS TWO TONNES AND THE RIVER WEIGHS MORE."],
	["water", "tow", [], "YOU DIED BECAUSE THERE IS NO TOW TRUCK FOR THE BOTTOM OF THE PETITCODIAC."],
	# ---------------------------------------------------------------- other cars
	["traffic", "*", ["headon"], "YOU DIED BECAUSE YOU PLAYED CHICKEN WITH A MINIVAN. THE MINIVAN HAD THREE KIDS IN THE BACK AND NOTHING LEFT TO LOSE."],
	["traffic", "*", ["headon"], "YOU DIED BECAUSE YOU DROVE ON THE BRITISH SIDE OF THE ROAD. THIS IS NOT BRITAIN."],
	["traffic", "*", ["headon", "impaired"], "YOU DIED BECAUSE BOTH LANES LOOKED LIKE YOUR LANE."],
	["traffic", "*", ["rear"], "YOU DIED BECAUSE YOU WERE TAILGATING SO HARD YOU BECAME PART OF HIS CAR."],
	["traffic", "*", ["rear"], "YOU DIED BECAUSE THE GUY IN FRONT BRAKED FOR A SQUIRREL AND YOU DID NOT BRAKE FOR THE GUY."],
	["traffic", "*", ["tbone"], "YOU DIED BECAUSE THE LIGHT WAS 'BASICALLY GREEN.'"],
	["traffic", "*", ["tbone"], "YOU DIED BECAUSE YOU TREATED A FOUR-WAY STOP AS A FOUR-WAY SUGGESTION."],
	["traffic", "*", ["blink"], "YOU DIED BECAUSE YOU USED YOUR BLINKER AND NOBODY IN PORT RUMBLE KNEW WHAT IT MEANT."],
	["traffic", "*", ["ice"], "YOU DIED BECAUSE YOU BRAKED ON ICE. THE ICE DOES NOT CARE THAT YOU BRAKED."],
	["traffic", "*", ["fast"], "YOU DIED BECAUSE YOU WERE LATE FOR WORK. NOW YOU'RE LATE FOR EVERYTHING."],
	["traffic", "silvio", [], "YOU DIED BECAUSE YOU TRIED TO DRIFT THROUGH TRAFFIC LIKE IT WAS A MUSIC VIDEO."],
	["traffic", "charjer", [], "YOU DIED BECAUSE YOU MERGED LIKE A CHARJER OWNER. WHICH YOU ARE. WERE."],
	["traffic", "supreem", [], "YOU DIED BECAUSE THE OTHER CAR HAD SIX AIRBAGS AND YOU HAD A CASSETTE DECK."],
	["traffic", "tow", [], "YOU DIED BECAUSE YOU MADE YOUR OWN TOW CALL. AND THE OTHER GUY'S."],
	# ---------------------------------------------------------------- the edge of the world
	["edge", "*", [], "YOU DIED BECAUSE YOU DROVE OFF THE EDGE OF THE MAP. THE DEV DIDN'T BUILD PAST HERE. SORRY."],
	["edge", "*", [], "YOU DIED BECAUSE THERE IS NOTHING PAST HAVELOCK. WE CHECKED."],
	# ---------------------------------------------------------------- anything at all
	["*", "*", ["fast"], "YOU DIED BECAUSE THE SPEEDOMETER WENT PAST 160 AND YOU TOOK THAT AS A PERSONAL CHALLENGE."],
	["*", "*", ["flat"], "YOU DIED BECAUSE YOU DROVE ON A FLAT FOR FOUR KILOMETRES BECAUSE 'IT'S FINE.'"],
	["*", "*", ["hot"], "YOU DIED BECAUSE THE TEMP GAUGE WAS IN THE RED AND YOU THOUGHT RED MEANT FAST."],
	["*", "*", ["impaired"], "YOU DIED BECAUSE 'I'M GOOD TO DRIVE' WAS A LIE AND YOU KNEW IT."],
	["*", "*", ["wheeloff"], "YOU DIED BECAUSE YOU TORQUED YOUR LUG NUTS 'TO FEEL.' THE FEELING WAS WRONG."],
	["*", "*", [], "YOU DIED BECAUSE CARS DON'T HAVE A PAUSE BUTTON. WELL. THIS ONE DOES NOW."],
]

static var _last := ""

## The conditions that hold for this crash (see the caption list for the names).
static func conditions(info: Dictionary) -> Array:
	var c: Array = []
	for k in ["fall", "winter", "summer", "spring"]:
		if String(info.get("season", "")) == k: c.append(k)
	if info.get("night", false): c.append("night")
	if info.get("night", false) and not info.get("lights", true): c.append("nolights")
	var surf := String(info.get("surface", ""))
	if surf == "ice": c.append("ice")
	if surf == "snow": c.append("snow")
	if String(info.get("weather", "")) in ["rain", "drizzle", "storm"]: c.append("rain")
	for k in ["impaired", "handbrake", "reverse", "blink", "flat", "hot", "wheeloff"]:
		if info.get(k, false): c.append(k)
	if float(info.get("speed_kmh", 0.0)) > 160.0: c.append("fast")
	if String(info.get("style", "")) == "downtown": c.append("downtown")
	var sub := String(info.get("sub", ""))
	if sub != "": c.append(sub)
	return c

## Pick a caption for a crash. More specific captions are much likelier; never the same twice in a row.
static func pick(info: Dictionary, rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var have := conditions(info)
	var cause := String(info.get("cause", "*"))
	var car := String(info.get("car", ""))
	var pool: Array = []
	var total := 0.0
	for e in CAPTIONS:
		if e[0] != "*" and e[0] != cause: continue
		if e[1] != "*" and e[1] != car: continue
		var ok := true
		for need in e[2]:
			if not have.has(need):
				ok = false
				break
		if not ok: continue
		var score := (3.0 if e[1] != "*" else 0.0) + 2.0 * float((e[2] as Array).size()) + (1.0 if e[0] != "*" else 0.0)
		var wt := 1.0 + score * score
		if e[3] == _last: wt *= 0.02
		pool.append([e[3], wt])
		total += wt
	if pool.is_empty(): return CAPTIONS[CAPTIONS.size() - 1][3]
	var r := rng.randf() * total
	for e in pool:
		r -= float(e[1])
		if r <= 0.0:
			_last = e[0]
			return e[0]
	_last = pool[pool.size() - 1][0]
	return _last
