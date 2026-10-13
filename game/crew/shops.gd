## The other garages: mechanic shops round the map that do upgrades and customisation over the
## counter (no waiting on the post), each with its own mechanic, prices and stock. Pull up on the
## lot and stop. Bry's Fjord Service is Bry The Fjord Guy's: turn up in a Fjord and he's in your
## crew, which gets you The Bry Special and twenty percent off anything he does to a Fjord.
class_name Shops
extends Node

const USE_M := 9.0

## id, the name on the sign, where you pull up, the tabs it offers, its markup, the mechanic and
## what they say, and what the crew entry's called once they're in it.
const SHOPS := [
	{ "id": "bry", "name": "BRY'S FJORD SERVICE", "spot": Vector2(6316, 921), "tabs": ["UPGRADES", "LOOKS", "DYNO"], "mult": 1.05, "make": "Fjord",
		"mechanic": "BRY", "crew": "bry", "lines": [
			"FJORD. FOUND ON ROAD. DRIVING. THAT'S WHAT IT STANDS FOR. LOOK IT UP.",
			"A GMZ IS A FJORD FOR PEOPLE WHO'VE GIVEN UP.",
			"CHEVROLAY. THEY PUT THE BOWTIE ON SO YOU KNOW WHO TO BLAME.",
			"MY FIRST CAR WAS A FJORD. MY LAST CAR WILL BE A FJORD. THE HEARSE WILL BE A FJORD.",
			"IT RUSTS, SURE. IT RUSTS WITH DIGNITY.",
			"I'LL WORK ON YOUR CHEVROLAY. I'LL WASH MY HANDS AFTER.",
			"BLUE OVAL. SAY IT WITH ME.",
		] },
	{ "id": "dieppe", "name": "DIEPPE SPEED SHOP", "spot": Vector2(6468, 1363), "tabs": ["UPGRADES", "LOOKS", "DYNO"], "mult": 1.2, "make": "",
		"mechanic": "RENÉ", "crew": "", "lines": [
			"WE DO IT TODAY. THAT'S WHAT THE EXTRA IS FOR.",
			"THE DYNO'S CALIBRATED. MY COUSIN DID IT. HE'S VERY CALIBRATED.",
			"EVERYBODY WANTS MORE BOOST. NOBODY WANTS MORE HEAD GASKET.",
			"THAT'S THE TRACK PRICE. THE STREET PRICE IS THE SAME. WE'RE A SPEED SHOP.",
		] },
	{ "id": "salisbury", "name": "SALISBURY AUTO", "spot": Vector2(3526, 2149), "tabs": ["UPGRADES", "LOOKS"], "mult": 0.92, "make": "",
		"mechanic": "WANDA", "crew": "", "lines": [
			"WE'RE CHEAPER THAN TOWN. WE'RE ALSO IN SALISBURY.",
			"YOU WANT IT PAINTED, I'VE GOT WHATEVER COLOUR'S LEFT ON THE SHELF.",
			"NO DYNO. THE ROAD TO HAVELOCK IS THE DYNO.",
			"PAY AT THE COUNTER. THE DOG'S FRIENDLY. THE CAT ISN'T.",
		] },
]

const BRY_INTRO := [
	"BRY: \"FJORD? ...NO. WHAT IS THAT. WHAT DID YOU BRING ONTO MY LOT.\"",
	"BRY: \"I'LL WORK ON IT. BUT WE'RE NOT FRIENDS UNTIL YOU'RE IN A FJORD.\"",
]
const BRY_JOINS := [
	"BRY: \"NOW THAT. THAT IS A CAR. COME HERE. NO, COME HERE.\"",
	"BRY JOINS YOUR CREW: THE BRY SPECIAL FOR ANY FJORD YOU OWN, AND TWENTY PERCENT OFF HIS WORK ON ONE.",
]

var drive: Node

func setup(the_drive: Node) -> void:
	drive = the_drive
	for s in SHOPS:
		var known := false
		for lm in drive.world.map.landmarks:
			if String(lm.name) == String(s.name): known = true
		if not known: drive.world.map.landmarks.append({ "name": String(s.name), "p": s.spot, "dest": true })

## The shop you're stopped on the lot of, or {}.
func at_shop() -> Dictionary:
	var c: PlayerCar = drive.car
	if c == null or c.sim.speed() > 1.5: return {}
	for s in SHOPS:
		if c.sim.pos.distance_to(s.spot) < USE_M: return s
	return {}

static func in_crew(save: Dictionary, who: String) -> bool:
	return bool((save.get("crew", {}) as Dictionary).get(who, false))

## What a shop charges this car, on its markup: Bry takes a fifth off a Fjord once he's in your crew.
static func mult_for(shop: Dictionary, save: Dictionary, spec: Dictionary) -> float:
	if shop.is_empty(): return 1.0
	var m := float(shop.get("mult", 1.0))
	if String(shop.get("make", "")) != "" and String(spec.get("make", "")) == String(shop.make) and in_crew(save, String(shop.crew)): m *= 0.8
	return m

func _process(_dt: float) -> void:
	var _t0 := Time.get_ticks_usec()
	_process_timed(_dt)
	Prof.lap('crew_shops_process', _t0)

func _process_timed(_dt: float) -> void:
	if drive.car == null or StoryState.active or drive.modal_open(): return
	var s := at_shop()
	if s.is_empty(): return
	drive.hud.prompt(Hints.fmt("{use}: " + String(s.name)))
	if not Input.is_action_just_pressed("use"): return
	if String(s.get("crew", "")) != "": _greet(s)
	drive._store_car()
	drive.garage.open(drive.save, s)

## Bry, the first time and the first time you're in a Fjord.
func _greet(s: Dictionary) -> void:
	var crew: Dictionary = drive.save.get("crew", {})
	var key := String(s.crew)
	var fjord := String(drive.car.spec.get("make", "")) == String(s.get("make", ""))
	if fjord and not bool(crew.get(key, false)):
		crew[key] = true
		crew["met_" + key] = true
		drive.save.crew = crew
		for ln in BRY_JOINS: drive.hud.post(ln, 6.0)
		drive.hud.notify("BRY JOINS YOUR CREW", "award", 2, 6.0)
		SaveGame.write(drive.save)
	elif not bool(crew.get("met_" + key, false)):
		crew["met_" + key] = true
		drive.save.crew = crew
		for ln in BRY_INTRO: drive.hud.post(ln, 5.0)
