## The radio: three stations out of Port Rumble, on while you drive. A line every so often: the
## DJ, the news, the weather and the traffic, the ads, and the odd call-in about whatever you've
## been up to (the heat on you, your name on the street, the awards). N switches stations (or off),
## and Settings > UI turns it off for good. Text only: the songs are whatever you're humming.
class_name Radio
extends Node

const STATIONS := [
	{ "id": "ckpr", "name": "CKPR 101.1 THE RUMBLE", "tag": "101.1" },
	{ "id": "bore", "name": "103.9 THE BORE", "tag": "103.9" },
	{ "id": "cjmb", "name": "CJMB 90.7 COMMUNITY", "tag": "90.7" },
]
const EVERY_S := Vector2(26.0, 48.0)      # between lines, driving
const NIGHT_DRIVE_K := 0.6                # on a Night Drive the radio's the company: more of it

## What each station says when nothing in particular is going on.
const IDLE := {
	"ckpr": [
		"THAT WAS THE TRAGICALLY HIPSTERS. THIS IS THE RUMBLE. WE'LL PLAY IT AGAIN AT FOUR.",
		"TWO IN A ROW, NO TALKING. I LIED. I'M TALKING. THIS IS THE RUMBLE.",
		"COMING UP: THE DRIVE-HOME BLOCK. SAME SONGS AS THE DRIVE-IN BLOCK. YOU WON'T MIND.",
		"RUMBLE REQUEST LINE: 'ANYTHING BUT THE SONG YOU JUST PLAYED.' YOU GOT IT, BUDDY.",
		"THIS ONE GOES OUT TO EVERYBODY SITTING AT THE CAUSEWAY LIGHT. IT'S LONG. WE KNOW.",
		"NEXT HOUR: THE RUMBLE'S TOP NINE AT NINE. IT'S TEN SONGS. NOBODY'S FIXED THE SIGN.",
		"IF YOU'RE DRIVING, KEEP DRIVING. IF YOU'RE PARKED, WHY ARE YOU LISTENING TO THIS.",
		"THE RUMBLE: PORT RUMBLE'S ONLY ROCK STATION, BY DEFAULT.",
		"THAT ONE WAS FOR DARRELL. DARRELL, CALL YOUR BROTHER.",
		"NEW FROM THE SALISBURY BOYS: A SONG ABOUT A TRUCK. IT'S ABOUT A TRUCK.",
		"RUMBLE ROCK BLOCK, SPONSORED BY NOBODY. CALL US. WE'RE CHEAP.",
		"IF YOU HEAR A MOOSE, THAT'S NOT THE SONG. THAT'S A MOOSE.",
		"THE RUMBLE'S SUMMER JAM IS IN FEBRUARY THIS YEAR. DON'T ASK.",
		"THAT WAS NICKELBOX. WE HAVE TO PLAY ONE AN HOUR. IT'S IN THE LICENCE.",
		"CALLER SAYS WE PLAY THE SAME TWELVE SONGS. WE PLAY THIRTEEN.",
		"COMING UP: A SONG YOUR DAD LIKES. HE'S RIGHT, IT'S GOOD.",
	],
	"bore": [
		"THE BORE, 103.9. TALK, NEWS, AND A MAN NAMED GARY WHO WON'T GET OFF THE LINE.",
		"CITY COUNCIL MET FOR FOUR HOURS LAST NIGHT AND AGREED THE ROADS ARE BAD.",
		"GARY FROM DIEPPE: 'THE ROUNDABOUT IS A PLOT.' GARY, WE'VE TALKED ABOUT THIS.",
		"THE TIDAL BORE RUNS AT 2:40 TODAY. BRING A COFFEE. IT'S A WAVE. IT'S ONE WAVE.",
		"A CALLER SAYS SOMEBODY'S DOING DONUTS IN THE CHAMPAGNE PLACE LOT AGAIN. THE MALL SAYS CALL THE POLICE. THE POLICE SAY CALL THE MALL.",
		"THE PROVINCE SAYS THE CAUSEWAY WILL BE FIXED BY SPRING. IT DIDN'T SAY WHICH SPRING.",
		"GAS IS UP TWO CENTS. GARY HAS A THEORY. GARY, YOU'RE ON.",
		"THE RUMBLE CENTRE HAS A HOCKEY GAME TONIGHT. THE PARKING IS A GAME TOO.",
		"COMING UP AFTER THE NEWS: WHY YOUR CHEVROLAY DOES THAT. SPOILER: IT'S A CHEVROLAY.",
		"THE MAYOR WAS ASKED ABOUT THE POTHOLE ON MAIN. THE MAYOR SAID 'WHICH ONE.' FAIR.",
		"A REMINDER FROM THE MINISTRY: YOUR INSPECTION STICKER IS NOT A SUGGESTION.",
		"THIS IS THE BORE. WE'RE NOT PROUD OF THE NAME EITHER.",
		"THE CASINO SAYS IT'S THE BEST-LIT PARKING LOT IN THE PROVINCE. THAT'S THE WHOLE AD.",
		"GARY WANTS TO KNOW WHY THE AIRSTRIP HAS LIGHTS IF NOTHING LANDS THERE. GARY, WE DON'T KNOW EITHER.",
		"THE PLOW CONTRACT WENT TO THE SAME COMPANY. THE SAME COMPANY IS THE MAYOR'S COUSIN. WE'RE TOLD THAT'S FINE.",
		"THE BORE NEWS DESK, WHICH IS A DESK: NOTHING HAPPENED. BACK TO GARY.",
	],
	"cjmb": [
		"CJMB COMMUNITY RADIO. THE BINGO NUMBERS ARE COMING UP. YOU HAVE TIME. YOU ALWAYS HAVE TIME.",
		"THE HAVELOCK LEGION HAS A TURKEY DINNER SATURDAY. BRING A FOLDING CHAIR. THEY MEAN IT.",
		"LOST: ONE BROWN DOG, ANSWERS TO 'BUDDY' OR TO FOOD. LAST SEEN ON COVERDALE RD.",
		"THE SALISBURY FIRE DEPARTMENT IS SELLING CALENDARS. THE FIREMEN ARE IN THEM. CLOTHED.",
		"FROM MEMERE'S KITCHEN: THIS WEEK, A FRICOT. YOU WILL NEED A CHICKEN AND AN AFTERNOON.",
		"THE ACADIAN HOUR IS NEXT. IT'S TWO HOURS.",
		"SOMEBODY LEFT A LADDER AT THE CHURCH. IT'S A GOOD LADDER. COME GET YOUR LADDER.",
		"FOR SALE: A SNOWBLOWER, TWO-STAGE, RUNS. ASK FOR GERRY. HE WILL TELL YOU ABOUT IT.",
		"THE RIVERSIDE YARD SALE IS SATURDAY, RAIN OR SHINE. MOSTLY RAIN.",
		"THIS IS CJMB, PORT RUMBLE, DIEPPE, SALISBURY AND WHOEVER'S LISTENING IN HAVELOCK.",
		"THE FIDDLE CONTEST IS SUNDAY. THERE IS ONE FIDDLER. HE IS STILL NERVOUS.",
		"TODAY'S SWAP SHOP: A CANOE FOR A GENERATOR. NO MONEY. THAT'S THE RULE.",
		"THE PORT RUMBLE HIGH BAND NEEDS A TUBA. ANY TUBA.",
		"HAPPY BIRTHDAY TO RAYMOND, 61. RAYMOND, YOUR SISTER CALLED IT IN. SHE SAYS CALL HER.",
		"THE LIBRARY HAS A SEED SWAP SATURDAY. BRING SEEDS. TAKE SEEDS. IT'S NOT COMPLICATED.",
	],
}

## The weather, by station and by what's falling.
const WEATHER := {
	"clear": ["CLEAR SKIES OUT THERE. ENJOY IT. IT'S THE MARITIMES, IT'S TEMPORARY.", "NOT A CLOUD. THE WEATHER GUY HAS NOTHING TO DO. HE'S SWEEPING."],
	"cloudy": ["CLOUDY. JUST CLOUDY. THAT'S THE WHOLE FORECAST.", "OVERCAST, WITH A CHANCE OF STAYING OVERCAST."],
	"rain": ["RAIN ON THE ROADS: LEAVE A GAP. LEAVE TWO.", "IT'S COMING DOWN. THE CAUSEWAY'S A CAR WASH."],
	"fog": ["FOG ON THE RIVER AND UP MOUNTAIN RD. LOW BEAMS. HIGH BEAMS JUST LIGHT UP THE FOG.", "YOU CAN'T SEE THE BRIDGE FROM THE BRIDGE. TAKE IT EASY."],
	"snow": ["SNOW. THE PLOWS ARE OUT ON THE MAIN ROADS FIRST. THE SIDE STREETS, EVENTUALLY.", "IT'S SNOWING AND EVERYBODY'S FORGOTTEN HOW TO DRIVE AGAIN."],
	"freezing": ["FREEZING RAIN. IF YOU DON'T HAVE TO GO OUT, DON'T. IF YOU'RE OUT, GO HOME SLOWLY.", "BLACK ICE ON THE BRIDGES. THE SALT TRUCKS ARE COMING. THEY'RE ALWAYS COMING."],
	"storm": ["THUNDER OVER THE RIVER. IF YOU'RE ON THE CAUSEWAY, YOU'VE GOT THE BEST SEAT AND THE WORST ONE.", "A STORM'S ROLLING THROUGH. THE RUMBLE CENTRE LOT IS GOING TO BE A LAKE."],
	"drizzle": ["DRIZZLE. NOT RAIN. THE WEATHER GUY WAS VERY CLEAR THAT IT'S NOT RAIN.", "A GREY ONE. THE WIPERS ON INTERMITTENT, THE SLOW ONE."],
	"blizzard": ["BLIZZARD WARNING. THE HIGHWAY'S A WALL OF WHITE PAST MAGNET HILL. STAY IN TOWN.", "IF YOU CAN SEE THE CAR IN FRONT OF YOU, YOU'RE TOO CLOSE. IF YOU CAN'T, SLOW DOWN."],
}
const HOURS := {
	"dawn": ["GOOD MORNING, PORT RUMBLE. THE TIM BURTONS LINE IS ALREADY ROUND THE BUILDING.", "SIX A.M. YOU'RE EITHER STARTING OR FINISHING. EITHER WAY, COFFEE."],
	"day": ["MIDDAY. THE ROADS ARE QUIET, THE WAY THEY'RE QUIET BEFORE THE SCHOOLS LET OUT.", "LUNCH HOUR DOWNTOWN. GOOD LUCK PARKING."],
	"rush": ["IT'S THE DRIVE HOME. MAIN'S BACKED UP TO THE CAUSEWAY. IT'S ALWAYS BACKED UP TO THE CAUSEWAY.", "FIVE O'CLOCK. THE WHEELER'S CRAWLING. TAKE THE BACK WAY. EVERYBODY'S TAKING THE BACK WAY."],
	"evening": ["THE SUN'S GOING DOWN OVER MAGNET HILL. THAT'S THE BEST VIEW IN THE CITY, AND IT'S FREE.", "EVENING. THE LIGHTS ARE COMING ON DOWNTOWN."],
	"night": ["IT'S LATE. IF YOU'RE OUT THERE, SO ARE THE DEER. AND THE POLICE.", "THE NIGHT SHIFT. US, THE NURSES, AND WHOEVER'S DRIVING ROUND WITH NOWHERE TO BE."],
}
const SEASONS := {
	"fall": ["LEAVES ON THE BACK ROADS. WET LEAVES ARE ICE WITH BETTER COLOURS.", "THE FROST IS COMING. GET YOUR WINTERS BOOKED BEFORE EVERYBODY ELSE REMEMBERS."],
	"winter": ["MINUS TWENTY WITH THE WIND. YOUR CAR DOESN'T WANT TO START EITHER.", "THE SNOWBANKS ON MAIN ARE TALLER THAN THE PARKING METERS. THE METERS STILL WORK."],
	"spring": ["POTHOLE SEASON. THE CITY CALLS IT SPRING.", "THE RIVER'S UP AND BROWN. BROWNER."],
	"summer": ["TWENTY-SIX AND SUNNY. THE WHOLE PROVINCE IS AT PARLEE BEACH. THE ROADS ARE YOURS.", "A HOT ONE. THE ASPHALT'S SOFT ON THE WHEELER. YOU CAN SMELL IT."],
}
## Call-ins and news about you: picked by what the save says you've been up to.
const ABOUT_YOU := {
	"heat": ["THE POLICE ARE ASKING FOR TIPS ABOUT A CAR SEEN SPEEDING THROUGH TOWN. THEY DESCRIBED IT. IT SOUNDS LIKE YOURS.",
		"A CALLER SAYS THE POLICE WERE CHASING SOMEBODY DOWN MAIN LAST NIGHT. THE POLICE SAY 'NO COMMENT.' THAT'S A YES."],
	"rep": ["GARY SAYS THERE WAS STREET RACING ON THE DOWNTOWN BOX AGAIN. GARY, HOW DO YOU KNOW IT'S CALLED THE DOWNTOWN BOX.",
		"WORD ON THE STREET, WHICH IS WHERE WE GET OUR WORDS: SOMEBODY NEW IS WINNING MARCO'S RACES."],
	"awards": ["SHOUT-OUT TO THE EMPLOYEE OF THE MONTH AT COVINGTON AUTO. THEY HAVE A WALL. IT'S A WHOLE WALL.",
		"COVINGTON AUTO'S COUNTER IS OPEN MORNINGS. THE KID'S FAIR, WE HEAR. MOSTLY."],
	"debt": ["A CALLER ASKS IF THE FAMILIA STILL RUNS THINGS ON THE NORTH SIDE. WE'RE GOING TO A COMMERCIAL."],
	"tow": ["TOBY'S TOWING SAYS IT'S BEEN A BUSY WEEK IN THE DITCHES. TOBY SAYS THANK YOU. HE MEANS IT, SORT OF."],
}
const ADS := [
	"THE LARGE STOP: DIESEL, FRIES, AND THE BEST COFFEE ON THE TRANS-CANADA. ALSO THE ONLY COFFEE ON THE TRANS-CANADA.",
	"CANADIAN TIRED: WE HAVE THE THING. WE DON'T KNOW WHERE. COME LOOK.",
	"DIEPPE SPEED SHOP: WE DO IT TODAY. THAT'S WHAT THE EXTRA IS FOR.",
	"ROCKAUTTO.CA: THE PART YOU NEED, IN A BOX WITH THE PART YOU DIDN'T.",
	"BRY'S FJORD SERVICE: FJORDS. ALSO OTHER CARS, IF YOU MUST.",
	"MARKETTHING: SOMEBODY'S COUSIN IS SELLING IT. RUNS WHEN PARKED.",
	"PIZZA DELIRIUM: THIRTY MINUTES OR IT'S FREE. THE DRIVER DOESN'T KNOW THAT.",
	"HOPP-IN: THE RIDE APP. FIVE STARS, OR DON'T.",
	"CASINO RUMBLE: THE LIGHTS ARE ON. SOMEBODY'S WINNING. NOT YOU, STATISTICALLY.",
	"ULTRAMARGE: GAS, LOTTERY, AND A BATHROOM WE'D RATHER NOT TALK ABOUT.",
]

var drive: Node
var station := 0            # index into STATIONS, -1 for off
var _t := 20.0
var rng := RandomNumberGenerator.new()
var _recent: Array[String] = []

func setup(the_drive: Node) -> void:
	drive = the_drive
	rng.randomize()
	if not bool(GameSettings.get_v("ui", "radio")): station = -1

func on() -> bool:
	return station >= 0 and bool(GameSettings.get_v("ui", "radio"))

## N: the next station, then off, then round again.
func next_station() -> void:
	station = station + 1
	if station >= STATIONS.size(): station = -1
	drive.hud.notify("RADIO: " + (String(STATIONS[station].name) if station >= 0 else "OFF"), "status", 1, 2.5)
	_t = 4.0

func _process(dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_process_timed(dt)
	Prof.lap('world_radio_process', _t0)

func _process_timed(dt: float) -> void:
	if drive.car == null or not on() or StoryState.active and not drive.free_roam: return
	if drive.modal_open() or drive.car.sim.speed() < 3.0: return
	var k := NIGHT_DRIVE_K if drive.jobs.kind == "cruise" else 1.0
	_t -= dt / k
	if _t > 0.0: return
	_t = rng.randf_range(EVERY_S.x, EVERY_S.y)
	var line := pick(STATIONS[station].id, drive.sky, drive.save, rng)
	if line == "": return
	drive.hud.post("[%s] %s" % [String(STATIONS[station].tag), line], 6.0)

## Something to say on this station right now. Pure, so the tests can ask.
func pick(st: String, sky: WorldSky, save: Dictionary, r: RandomNumberGenerator) -> String:
	var pools: Array = []
	var w: Array = []
	pools.append(IDLE[st]); w.append(5.0)
	var wk := String(sky.weather)
	if WEATHER.has(wk): pools.append(WEATHER[wk]); w.append(2.0 if wk in ["rain", "snow", "freezing", "fog", "storm", "blizzard"] else 0.6)
	var h := float(sky.time_h)
	var slot := "night"
	if h >= 5.0 and h < 9.0: slot = "dawn"
	elif h >= 9.0 and h < 15.5: slot = "day"
	elif h >= 15.5 and h < 18.0: slot = "rush"
	elif h >= 18.0 and h < 21.5: slot = "evening"
	pools.append(HOURS[slot]); w.append(1.0)
	if SEASONS.has(String(sky.season)): pools.append(SEASONS[sky.season]); w.append(0.8)
	pools.append(ADS); w.append(2.0 if st != "cjmb" else 0.7)
	if st != "ckpr":
		if float(save.get("heat", 0.0)) > 30.0: pools.append(ABOUT_YOU.heat); w.append(2.5)
		if int((save.get("street", {}) as Dictionary).get("rep", 0)) >= 2: pools.append(ABOUT_YOU.rep); w.append(1.2)
		if int((save.get("stats", {}) as Dictionary).get("tows", 0)) >= 3: pools.append(ABOUT_YOU.tow); w.append(0.8)
		if StoryState.active and StoryState.debt > 0: pools.append(ABOUT_YOU.debt); w.append(0.6)
		if Awards.count() >= 3: pools.append(ABOUT_YOU.awards); w.append(0.8)
	var total := 0.0
	for x in w: total += float(x)
	var pick_w := r.randf() * total
	var pool: Array = pools[0]
	for i in pools.size():
		pick_w -= float(w[i])
		if pick_w <= 0.0:
			pool = pools[i]
			break
	# not the same line again soon, if the pool has another
	var line := String(pool[r.randi() % pool.size()])
	for tries in 6:
		if not _recent.has(line): break
		line = String(pool[r.randi() % pool.size()])
	_recent.append(line)
	if _recent.size() > 8: _recent.pop_front()
	return line

## Every line the radio can say (the tests read them for slurs and real brands).
static func all_lines() -> Array[String]:
	var out: Array[String] = []
	for st in IDLE: for l in IDLE[st]: out.append(String(l))
	for k in WEATHER: for l in WEATHER[k]: out.append(String(l))
	for k in HOURS: for l in HOURS[k]: out.append(String(l))
	for k in SEASONS: for l in SEASONS[k]: out.append(String(l))
	for k in ABOUT_YOU: for l in ABOUT_YOU[k]: out.append(String(l))
	for l in ADS: out.append(String(l))
	return out
