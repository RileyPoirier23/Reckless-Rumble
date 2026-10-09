## The counter at Covington Auto: who walks in, what papers they carry, what's wrong with
## them, what they say when you ASK, and what each stamp costs you. Pure logic (no drawing),
## so it can be tested headless.
##
## The generator injects problems; `find_problems` finds them again by reading only the
## documents (including the ones a customer only hands over when you ASK), the car and the
## wall. The tests check that the two always agree, so every problem in the game can actually
## be caught by a player who looks, and an exception only holds when its proof does.
##
## Days count from Monday 7 October 2019 (day 0). Weekends and Thanksgiving are closed. The
## rules arrive on the days in RULES: Year 1, weeks 1 to 4 (bible section 3.8).
class_name CounterRules
extends RefCounted

const YEAR := 2019                      # Year 1 of the story
const WEEK_START := [YEAR, 10, 7]       # Monday, October 7
const DAYS := ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const VIN_CHARS := "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
## Days the shop is shut besides the weekends.
const CLOSED := { 7: "THANKSGIVING" }
const LAST_DAY := 25                    # Friday 1 November: the end of week four

# ------------------------------------------------------------------ the shift
const SHIFT_LEN := 600.0                # minutes on the clock, 8:00 to 18:00
const REAL_SECONDS := 600.0             # ...in ten real minutes
const HONK_AFTER := 90.0                # minutes on one customer before the next one leans on the horn
const WARNINGS := 2                     # free Ministry warnings a shift
const REVOKE_AT := 12                   # citations (after the warnings) that cost the licence
const MEETINGS_TO_REVOKE := 3           # ...or this many Ministry meetings (four citations in a week is a meeting)

# the Ministry's rules: what's checked from which day, and which tab of the binder it lives in
const TABS := ["INSPECTION", "DOCUMENTS", "POLICE", "MINISTRY", "SEASONAL"]
const RULES := [
	{ "day": 0, "id": "match", "tab": "INSPECTION", "text": "THE CAR MUST MATCH ITS REGISTRATION: PLATE AND VIN." },
	{ "day": 0, "id": "inspect", "tab": "INSPECTION", "text": "SAFETY INSPECTIONS: TREAD 1.6 MM+, PADS 3 MM+, ALL LIGHTS, NO RUST-THROUGH." },
	{ "day": 1, "id": "reg_valid", "tab": "DOCUMENTS", "text": "NO SERVICE ON AN EXPIRED REGISTRATION." },
	{ "day": 2, "id": "insured", "tab": "DOCUMENTS", "text": "NO INSURANCE, NO SERVICE. THE CARD MUST COVER THIS VIN, TODAY." },
	{ "day": 2, "id": "owner", "tab": "DOCUMENTS", "text": "THE LICENCE NAME MUST MATCH THE REGISTERED OWNER." },
	{ "day": 3, "id": "bolo", "tab": "POLICE", "text": "POLICE: REPORT ANY CAR ON THE STOLEN LIST. DO NOT TOUCH IT." },
	{ "day": 4, "id": "photo", "tab": "DOCUMENTS", "text": "THE LICENCE PHOTO MUST BE THE PERSON AT THE COUNTER." },
	{ "day": 8, "id": "odo", "tab": "DOCUMENTS", "text": "SERVICE HISTORY: ODOMETER READINGS ONLY GO UP. INSPECTIONS BRING THEIR SERVICE HISTORY." },
	{ "day": 10, "id": "bos", "tab": "DOCUMENTS", "text": "A NEW OWNER HAS 10 DAYS TO REGISTER. A DATED BILL OF SALE COVERS A NAME MISMATCH: SELLER IS THE OWNER, BUYER IS THE LICENCE, SAME VIN." },
	{ "day": 14, "id": "door", "tab": "INSPECTION", "text": "THE VIN ON THE DOOR JAMB MUST MATCH THE DASH. A BODY SHOP INVOICE FOR THAT REPLACEMENT DOOR COVERS IT." },
	{ "day": 15, "id": "permit", "tab": "DOCUMENTS", "text": "A TEMPORARY PERMIT COVERS AN EXPIRED REGISTRATION: SAME VIN, DATES THAT COVER TODAY." },
	{ "day": 17, "id": "oop", "tab": "MINISTRY", "text": "OUT-OF-PROVINCE CARS ON A NEW REGISTRATION NEED A FULL INSPECTION." },
	{ "day": 21, "id": "salvage", "tab": "MINISTRY", "text": "SALVAGE BRAND: NO STICKER WITHOUT A STRUCTURAL CERTIFICATE. A BRAND ON THE OLD OWNERSHIP THAT'S GONE FROM THE NEW ONE: REPORT IT." },
	{ "day": 24, "id": "masks", "tab": "SEASONAL", "text": "HALLOWEEN: MASKS COME OFF AT THE COUNTER. ASK." },
]
## Lines on the Ministry tab that aren't checks you make, but checks made on you.
const MINISTRY_LINES := ["TWO MINISTRY WARNINGS A SHIFT. FROM THE THIRD MISTAKE, $100 A CITATION.",
	"TWELVE CITATIONS, OR A THIRD MINISTRY MEETING, AND THE STATION LOSES ITS INSPECTION LICENCE."]
## More than this many rules and the bulletin turns into a binder.
const BULLETIN_MAX := 7

# problem -> the rule that catches it
const PROBLEM_RULE := {
	"vin_mismatch": "match", "plate_mismatch": "match", "fails_inspection": "inspect",
	"expired_reg": "reg_valid", "no_insurance": "insured", "insurance_expired": "insured",
	"insurance_vin": "insured", "name_mismatch": "owner", "stolen": "bolo", "photo_mismatch": "photo",
	"odo_rollback": "odo", "bos_expired": "bos", "bos_forged": "bos", "vin_door_mismatch": "door",
	"out_of_province": "oop", "salvage_no_cert": "salvage", "title_washed": "salvage",
}
## Problems the right answer to is REPORT, not DENY.
const REPORT_PROBLEMS := ["stolen", "title_washed"]
## The exceptions: a discrepancy -> [the document that can explain it, the rule that makes it count].
const PROOFS := {
	"name_mismatch": ["bos", "bos"], "expired_reg": ["permit", "permit"], "no_insurance": ["glovebox", "insured"],
	"vin_door_mismatch": ["door_inv", "door"], "salvage_no_cert": ["cert", "salvage"],
}

const FIRST := ["MARC", "JOEL", "DANIELLE", "KAYLA", "BRANDON", "NATALIE", "LUC", "SHAWN", "CHANTAL", "TYLER", "MELANIE", "JASON", "AMBER", "RENE", "KRISTA", "DEREK", "SYLVIE", "COREY", "JESSICA", "PAUL", "MONIQUE", "TRAVIS", "ASHLEY", "GILLES", "BRITTANY", "DYLAN", "NICOLE", "ROGER", "TAMMY", "KEVIN"]
const WOMEN := ["DANIELLE", "KAYLA", "NATALIE", "CHANTAL", "MELANIE", "AMBER", "KRISTA", "SYLVIE", "JESSICA", "MONIQUE", "ASHLEY", "BRITTANY", "NICOLE", "TAMMY"]
const LAST := ["LEBLANC", "CORMIER", "GALLANT", "ARSENAULT", "DOUCETTE", "RICHARD", "MELANSON", "LANDRY", "THIBODEAU", "MACDONALD", "MACLEOD", "GAUDET", "BOURQUE", "SAVOIE", "ROBICHAUD", "BABINEAU", "LEGER", "COMEAU", "GOGUEN", "BELLIVEAU", "DUPUIS", "HACHE", "MAILLET", "STEEVES", "WILSON", "OUELLETTE", "BOUDREAU", "MALLET", "VAUTOUR", "DOIRON"]
const STREETS := ["MAIN ST", "ST GEORGE BLVD", "MOUNTAIN RD", "ELMWOOD DR", "HIGHFIELD ST", "CLOVERDALE RD", "BOTSFORD ST", "KING ST", "CHURCH ST", "SHEDIAC RD"]
## The short list, for when the catalogue isn't there (and for the stolen list's fallback).
const CARS := [
	{ "make": "HONDO", "model": "CIVIL", "len": 4.4, "wid": 1.7, "body": "sedan" },
	{ "make": "TOYODA", "model": "COROLLY", "len": 4.5, "wid": 1.72, "body": "sedan" },
	{ "make": "FJORD", "model": "ESCAPED", "len": 4.4, "wid": 1.8, "body": "suv" },
	{ "make": "DODGY", "model": "CHARJER", "len": 5.0, "wid": 1.9, "body": "sedan" },
	{ "make": "CHEVROLAY", "model": "CAVA-LAME", "len": 4.6, "wid": 1.7, "body": "sedan" },
	{ "make": "FJORD", "model": "F-ONE-FIDDY", "len": 5.4, "wid": 2.0, "body": "pickup" },
	{ "make": "SUBAROO", "model": "IMPREZZA", "len": 4.4, "wid": 1.74, "body": "hatch" },
	{ "make": "VOLKSWAGON", "model": "GULF", "len": 4.2, "wid": 1.78, "body": "hatch" },
	{ "make": "DODGY", "model": "GRAND CRAVIN'", "len": 5.1, "wid": 1.95, "body": "minivan" },
	{ "make": "KEEYA", "model": "SOUL-LESS", "len": 4.1, "wid": 1.8, "body": "hatch" },
]
const PAINTS := ["#c8342c", "#2c5a8a", "#e8e4dc", "#2a2a2e", "#8a8e94", "#3a6a3a", "#d8a03a", "#6a2a4a", "#4a6a8a", "#b8b0a0"]
const ZONES := ["residential", "residential", "commercial", "rural", "downtown", "village"]
const REQUESTS := ["SAFETY INSPECTION", "SAFETY INSPECTION", "OIL CHANGE", "BRAKE JOB", "WINTER TIRES ON", "CHECK ENGINE LIGHT"]
const INSPECTIONS := ["SAFETY INSPECTION", "FULL INSPECTION"]
const INSURERS := ["MARITIME MUTUAL", "TIDEWATER INSURANCE", "FUNDY GENERAL"]
const SHOPS := ["COVINGTON AUTO", "LINDSAY'S LUBE", "CANADIAN TIRED", "HUBCAP CITY OIL&GO", "RIVERVIEW TIRE", "SALISBURY GAS BAR"]
const BODY_SHOPS := ["DIEPPE COLLISION", "BOUDREAU BODY & PAINT", "FENDER BENDERS LTD"]
const INSPECTORS := ["J. GOGUEN, LIC. 4471", "R. MAILLET, LIC. 2290", "D. STEEVES, LIC. 3318"]
const PROVINCES := ["NOVA SCOTIA", "QUEBEC", "ONTARIO", "P.E.I.", "NEWFOUNDLAND"]
const MASKS := ["GOALIE", "PUMPKIN", "GHOST"]
# what each job brings into the shop
const PAY := { "SAFETY INSPECTION": 75, "FULL INSPECTION": 140, "OIL CHANGE": 70, "BRAKE JOB": 320, "WINTER TIRES ON": 110, "CHECK ENGINE LIGHT": 140 }
# what Friday night takes back out
const BILLS := [["RENT ON THE GARAGE", 1100], ["THE FAMILIA (FOR MIA'S CAR)", 400], ["ARIES'S HOCKEY", 120], ["GUS'S PAY", 800]]
const FINE := 100
const START_CASH := 300

# ------------------------------------------------------------------ what people say when you ASK

## What Leo asks, by the discrepancy he's pointing at.
const QUESTIONS := {
	"vin_mismatch": "THE VIN ON YOUR OWNERSHIP ISN'T THE ONE ON THE CAR.", "plate_mismatch": "THAT'S NOT THE PLATE ON YOUR OWNERSHIP.",
	"fails_inspection": "IT FAILS. YOU KNOW IT FAILS, RIGHT?", "expired_reg": "YOUR REGISTRATION'S EXPIRED.",
	"no_insurance": "I NEED YOUR INSURANCE.", "insurance_expired": "YOUR INSURANCE RAN OUT.",
	"insurance_vin": "THIS CARD'S FOR A DIFFERENT CAR.", "name_mismatch": "THE CAR'S NOT IN YOUR NAME.",
	"stolen": "THIS CAR'S ON THE POLICE LIST.", "photo_mismatch": "THAT'S NOT YOU ON THE LICENCE.",
	"odo_rollback": "THE ODOMETER WENT BACKWARDS.", "bos_expired": "THIS BILL OF SALE'S OLDER THAN TEN DAYS.",
	"bos_forged": "THIS BILL OF SALE DOESN'T ADD UP.", "vin_door_mismatch": "THE DOOR'S FROM A DIFFERENT CAR.",
	"out_of_province": "THIS CAR'S FROM AWAY. IT NEEDS THE FULL INSPECTION.", "salvage_no_cert": "IT'S BRANDED SALVAGE. WHERE'S THE STRUCTURAL?",
	"title_washed": "IT WAS SALVAGE IN THE OTHER PROVINCE. HERE IT'S CLEAN?", "mask": "CAN YOU TAKE THAT OFF?",
}
## Explanations, by discrepancy: lies, and true things that don't change a thing.
const EXCUSES := {
	"vin_mismatch": ["THE VIN'S DIFFERENT BECAUSE I HAD THE DASH REPLACED. WITH A DIFFERENT DASH. FROM A DIFFERENT CAR. THAT'S NORMAL?",
		"MUST BE A TYPO AT THE REGISTRY. THEY'RE VERY BUSY.", "MY COUSIN DID THE PAPERS. HE'S NOT GREAT WITH LETTERS, BUT HE'S HONEST.",
		"THAT'S THE OLD VIN. IT GOT A NEW ONE. FOR ITS BIRTHDAY."],
	"plate_mismatch": ["ME AND MY COUSIN SWAPPED PLATES FOR LUCK. HIS LUCK'S BEEN BAD. MINE'S ABOUT TO BE, I GUESS.",
		"THOSE ARE MY WINTER PLATES.", "I FOUND THAT PLATE IN A DITCH. FINDERS KEEPERS IS A LAW, RIGHT?"],
	"fails_inspection": ["IF IT FAILS, CAN YOU FAIL IT GENTLY? IT'S BEEN THROUGH A LOT.", "THE RUST ISN'T THROUGH. IT'S JUST VERY COMMITTED.",
		"IT MAKES A NOISE TURNING LEFT. SO I DON'T TURN LEFT ANYMORE. I GO RIGHT THREE TIMES.", "HOW MUCH TO JUST... PASS IT? HYPOTHETICALLY. LIKE IN A MOVIE."],
	"expired_reg": ["I'VE BEEN MEANING TO RENEW IT. SINCE MAY.", "I DON'T HAVE THE NEW ONE, BUT I HAVE A VERY DETAILED MEMORY OF IT.",
		"IT'S NOT EXPIRED. IT'S RESTING."],
	"no_insurance": ["INSURANCE? UH, IT'S IN MY OTHER CAR.", "INSURANCE IS A SCAM ANYWAY. MY UNCLE SAYS.",
		"I'M A VERY CAREFUL DRIVER. THAT'S A KIND OF INSURANCE."],
	"insurance_expired": ["IS THE INSURANCE SUPPOSED TO BE EXPIRED? I THOUGHT THAT MEANT IT WAS MATURE.",
		"THE NEW CARD'S IN THE MAIL. THE MAIL'S IN SUSSEX.", "I PAID IT. I THINK. MY WIFE PAYS IT. SHE LEFT."],
	"insurance_vin": ["THAT'S THE CARD FOR MY OTHER CAR. SAME COLOUR, THOUGH.", "THEY'RE BOTH INSURED. SPIRITUALLY THEY'RE THE SAME CAR.",
		"THE GIRL AT THE INSURANCE SAID IT WAS FINE. SHE WAS VERY NICE."],
	"name_mismatch": ["IT'S MY BUDDY'S CAR. HE SAID IT'S COOL.",
		"C'EST PAS MON CHAR, C'EST LE CHAR A MON COUSIN. MAIS C'EST MOI QUI LE DRIVE, SO C'EST QUASIMENT MON CHAR.",
		"THAT'S MY MAIDEN NAME. ON THE CAR. THE CAR WAS MARRIED BEFORE."],
	"stolen": ["STOLEN? IT'S BEEN IN THE FAMILY FOR WEEKS.", "I BOUGHT IT OFF A GUY IN A PARKING LOT. HE HAD A RECEIPT. ON A NAPKIN.", "NO IT ISN'T."],
	"photo_mismatch": ["MY LICENCE PHOTO'S FROM BEFORE THE BEARD. AND THE DIVORCE. AND THE OTHER BEARD.", "I GOT A HAIRCUT.",
		"THE CAMERA ADDS TEN POUNDS. AND A DIFFERENT NOSE."],
	"odo_rollback": ["THE DASH GOT SWAPPED. THE OLD ONE HAD MORE... EXPERIENCE.", "THOSE OLD ONES ARE IN MILES. OR FEET. SOMETHING AMERICAN.",
		"THIS THING'S GOT 600,000 ON IT. THE ODOMETER ONLY GOES TO 299,999, SO WE'RE ON LAP THREE.", "THE GARAGE WROTE IT DOWN WRONG. ALL FOUR TIMES."],
	"bos_expired": ["I BOUGHT IT A WHILE AGO. TEN DAYS IS MORE OF A SUGGESTION, RIGHT?", "I WAS GOING TO REGISTER IT. THEN IT WAS HUNTING SEASON.",
		"HE PUT THE DATE HE STARTED THINKING ABOUT SELLING IT."],
	"bos_forged": ["THE GUY SPELLS HIS NAME DIFFERENT ON WEEKENDS.", "I WROTE IT UP MYSELF. FROM MEMORY. HE WAS THERE IN SPIRIT.",
		"LOOK AT THAT SIGNATURE. YOU CAN'T FAKE A SIGNATURE LIKE THAT. I TRIED."],
	"vin_door_mismatch": ["SOMEBODY BACKED INTO ME AT THE CANADIAN TIRED. THE NEW DOOR CAME OFF A CAR AT THE PICK-N-PULL.",
		"THAT DOOR'S ALWAYS BEEN LIKE THAT.", "DOORS HAVE VINS? SINCE WHEN? WHO'S CHECKING DOORS?"],
	"out_of_province": ["I'M FROM AWAY. TORONTO. IS IT NORMAL EVERYBODY HERE WAVES AT ME?",
		"IT PASSED IN NOVA SCOTIA. NOVA SCOTIA IS VERY STRICT. ABOUT LOBSTERS.", "THE FULL ONE COSTS MORE. I'M NOT MADE OF MONEY. I'M MADE OF LOANS."],
	"salvage_no_cert": ["IT'S BEEN FIXED. MY BROTHER-IN-LAW DID IT. HE'S VERY GOOD WITH A HAMMER.", "SALVAGE JUST MEANS IT'S BEEN SAVED. LIKE A SOUL.",
		"THE CERTIFICATE'S AT HOME. ON THE FRIDGE. UNDER A MAGNET SHAPED LIKE A LOBSTER."],
	"title_washed": ["THEY SAY SALVAGE, NEW BRUNSWICK SAYS CLEAN. I TRUST NEW BRUNSWICK.", "THE BRAND FELL OFF IN THE MOVE. LIKE A HUBCAP.",
		"WHAT BRAND? I DON'T SEE A BRAND."],
}
## What people say as they hand over a proof. Same words whether it's real or not.
const PROOF_LINES := {
	"bos": ["I BOUGHT IT THURSDAY. HERE'S THE BILL OF SALE. SIGNED AND DATED. MY HANDWRITING'S A CRIME, BUT IT'S A LEGAL ONE.",
		"I JUST BOUGHT IT. HERE. BILL OF SALE. HE WROTE IT ON THE HOOD."],
	"permit": ["THE REGISTRY GAVE ME A TEMPORARY. HERE. IT'S GOT A HOLOGRAM. WELL, A STICKER.", "TEMPORARY PERMIT. THE LINEUP WAS TWO HOURS, I'M NOT GOING BACK."],
	"glovebox": ["OH WAIT. GLOVEBOX. HANG ON.", "...THE PINK CARD? IT'S PINK? WHY DIDN'T ANYBODY SAY IT WAS PINK."],
	"door_inv": ["BODY SHOP DID THE DOOR. I'VE GOT THE BILL RIGHT HERE. WORST $900 I EVER SPENT.", "NEW DOOR. HERE'S THE INVOICE. THEY EVEN MATCHED THE PAINT. ALMOST."],
	"cert": ["HERE'S THE STRUCTURAL. THE GUY IN SALISBURY SIGNED IT ON HIS TAILGATE.", "STRUCTURAL CERTIFICATE. FRAME'S STRAIGHTER THAN ME."],
}
const MASK_LINES := ["IT'S A COSTUME. IT'S HALLOWEEN, BUD.", "OH. RIGHT. FORGOT I HAD IT ON. IT'S VERY COMFORTABLE.", "...FINE. BUT YOU'RE NO FUN."]
## Undercover people don't know local things. Ask them anything and they stumble.
const STING_ASK := ["I GOT THE PAPERS DONE AT THE, UH... THE TIM BURTONS? THE ONE ON MOUNTAIN STREET?",
	"WHICH TIM'S? THE... BIG ONE? BY THE... MALL. THE MALL ONE.", "MY BUDDY FROM THE PORT, HE SAYS YOU'RE GOOD. BIG GUY. YOU KNOW. HIM."]

var rng := RandomNumberGenerator.new()
var bolo: Array = []                    # [{plate, vin, car}] on the police list this week

func _init(seed := 506) -> void:
	rng.seed = seed

# ------------------------------------------------------------------ dates and the calendar

## day offset from the start of the week -> [y, m, d]
static func date_add(base: Array, days: int) -> Array:
	var t := Time.get_unix_time_from_datetime_dict({ "year": base[0], "month": base[1], "day": base[2], "hour": 12 })
	var d := Time.get_datetime_dict_from_unix_time(t + days * 86400)
	return [d.year, d.month, d.day]

static func date_str(d: Array) -> String:
	return "%s %02d %d" % [MONTHS[d[1] - 1], d[2], d[0]]

static func date_cmp(a: Array, b: Array) -> int:
	for i in 3:
		if a[i] != b[i]: return -1 if a[i] < b[i] else 1
	return 0

## Days from `a` to `b` (positive when b is later).
static func days_between(a: Array, b: Array) -> int:
	var ta := Time.get_unix_time_from_datetime_dict({ "year": a[0], "month": a[1], "day": a[2], "hour": 12 })
	var tb := Time.get_unix_time_from_datetime_dict({ "year": b[0], "month": b[1], "day": b[2], "hour": 12 })
	return roundi((tb - ta) / 86400.0)

static func today(day: int) -> Array:
	return date_add(WEEK_START, day)

static func day_name(day: int) -> String:
	return DAYS[posmod(day, 7)]

static func week_of(day: int) -> int:
	return floori(day / 7.0) + 1

## Open for business: a weekday that isn't a holiday.
static func is_open(day: int) -> bool:
	return posmod(day, 7) < 5 and not CLOSED.has(day)

## The next day the shop opens after `day`.
static func next_open(day: int) -> int:
	var d := day + 1
	while not is_open(d): d += 1
	return d

## The shift clock as the wall shows it: minutes since 8:00 -> "10:42 A.M."
static func clock_str(minutes: float) -> String:
	var t := 480 + int(minutes)
	var h := floori(t / 60.0)
	return "%d:%02d %s" % [posmod(h - 1, 12) + 1, posmod(t, 60), "A.M." if h < 12 else "P.M."]

static func rules_for(day: int) -> Array:
	return RULES.filter(func(r): return r.day <= day)

static func rule_active(id: String, day: int) -> bool:
	for r in RULES:
		if r.id == id: return r.day <= day
	return false

## The bulletin turns into a binder once there are too many rules to pin up.
static func binder(day: int) -> bool:
	return rules_for(day).size() > BULLETIN_MAX

# ------------------------------------------------------------------ the catalogue

static var _cat: Script = null
static var _cat_tried := false

## The parody car catalogue, loaded only if it's there.
static func catalogue() -> Script:
	if not _cat_tried:
		_cat_tried = true
		if ResourceLoader.exists("res://data/catalog.gd"): _cat = load("res://data/catalog.gd")
	return _cat

## A catalogue line turned into what the counter needs (make, model, year, size, paint, rust).
static func _from_catalogue(e: Dictionary, paint: String) -> Dictionary:
	var art: Dictionary = e.get("art", {})
	var quirk := ""
	var cat := catalogue()
	if cat != null:
		var qt: Dictionary = cat.get_script_constant_map().get("QUIRK_TEXT", {})
		for k in art:
			if qt.has(k): quirk = String(qt[k]).to_upper()
	return { "id": String(e.id), "make": String(e.make).to_upper(), "model": String(e.model).to_upper(), "year": int(e.year),
		"class": String(e["class"]), "body": String(e.body), "side_body": String(e.get("side_body", "sedan")),
		"len": float(e.length), "wid": float(e.width), "wheelbase": float(e.wheelbase), "paint": paint,
		"rust": float(art.get("rust", 0.0)), "quirk": quirk }

## A car for the counter: from the catalogue (weighted like a town's traffic, rust and all),
## or the short list. `cat_id` asks for one catalogue car by id.
func model(cat_id := "") -> Dictionary:
	var cat := catalogue()
	if cat != null:
		if cat_id != "":
			var e: Dictionary = cat.call("entry", cat_id)
			if not e.is_empty():
				var paints: Array = e.get("paints", PAINTS)
				return _from_catalogue(e, String(paints[rng.randi() % paints.size()]))
		else:
			for tries in 6:
				var e: Dictionary = cat.call("random_traffic", rng, ZONES[rng.randi() % ZONES.size()])
				if not e.is_empty() and int(e.year) <= YEAR: return _from_catalogue(e, String(e.paint))
	var cm: Dictionary = CARS[rng.randi() % CARS.size()]
	return { "id": "", "make": cm.make, "model": cm.model, "year": 1998 + rng.randi() % 21, "class": "sedan",
		"body": cm.body, "side_body": "van" if cm.body == "minivan" else cm.body, "len": cm.len, "wid": cm.wid,
		"wheelbase": float(cm.len) * 0.6, "paint": PAINTS[rng.randi() % PAINTS.size()], "rust": 0.0, "quirk": "" }

# ------------------------------------------------------------------ generators

func vin() -> String:
	var s := ""
	for i in 17: s += VIN_CHARS[rng.randi() % VIN_CHARS.length()]
	return s

## a VIN that's one or two characters off: the kind you only catch if you read it
func vin_tweak(v: String) -> String:
	var out := v
	var n := 1 + rng.randi() % 2
	var used: Array[int] = []
	while used.size() < n:
		var i := 9 + rng.randi() % 8
		if used.has(i): continue
		used.append(i)
		var ch := out[i]
		var r := ch
		while r == ch: r = VIN_CHARS[rng.randi() % VIN_CHARS.length()]
		out = out.substr(0, i) + r + out.substr(i + 1)
	return out

func plate() -> String:
	var L := "ABCDEFGHJKLMNPRSTUVWXYZ"
	return "%s%s%s %03d" % [L[rng.randi() % L.length()], L[rng.randi() % L.length()], L[rng.randi() % L.length()], rng.randi() % 1000]

func plate_tweak(p: String) -> String:
	var digits := int(p.substr(4))
	var nd := digits
	while nd == digits: nd = (digits + 1 + rng.randi() % 9) % 1000
	return p.substr(0, 4) + "%03d" % nd

func person() -> Dictionary:
	var first: String = FIRST[rng.randi() % FIRST.size()]
	return {
		"first": first, "last": LAST[rng.randi() % LAST.size()], "fem": 1 if WOMEN.has(first) else 0,
		"dob": [1950 + rng.randi() % 50, 1 + rng.randi() % 12, 1 + rng.randi() % 28],
		"address": "%d %s" % [10 + rng.randi() % 990, STREETS[rng.randi() % STREETS.size()]],
		"face": rng.randi(),
	}

## Somebody else's name (a different surname, so it can't be a coincidence).
func other_name(n: String) -> String:
	var o := person()
	while n.ends_with(" " + String(o.last)): o = person()
	return "%s %s" % [o.first, o.last]

## The stolen list for the week (seeded so the wall and the cars agree).
func make_bolo(n := 6) -> void:
	bolo = []
	for i in n:
		var m := model()
		bolo.append({ "plate": plate(), "vin": vin(), "car": "%s %s" % [m.make, m.model] })

## A customer for `day`. `want` forces a problem (for tests and scripts; "clean" forces none);
## otherwise it's rolled. `fixed` pins parts of them down: person, car (a partial dict, or
## "catalogue": id), request, and "plain" (no random extras: no exceptions, transfers or masks).
func customer(day: int, want := "", fixed := {}) -> Dictionary:
	var p := person()
	if fixed.has("person"): p.merge(fixed.person, true)
	var fcar: Dictionary = fixed.get("car", {})
	var m := model(String(fcar.get("catalogue", "")))
	var t := today(day)
	var age := maxi(1, YEAR - int(m.year))
	var car := {
		"make": m.make, "model": m.model, "year": m.year, "paint": m.paint, "len": m.len, "wid": m.wid,
		"wheelbase": m.wheelbase, "body": m.body, "side_body": m.side_body, "class": m["class"], "cat": m.id,
		"quirk": m.quirk, "rust_look": m.rust, "plate": plate(), "vin": vin(),
		"odo": clampi(age * (9000 + rng.randi() % 14000) + rng.randi() % 5000, 4000, 480000),
	}
	car.merge(fcar, true)
	var plain: bool = fixed.get("plain", false)
	var name := "%s %s" % [p.first, p.last]
	var desc := "%d %s %s" % [car.year, car.make, car.model]
	var c := {
		"person": p, "car": car, "request": String(fixed.get("request", REQUESTS[rng.randi() % REQUESTS.size()])), "kind": "regular",
		"face_shown": p.face, "mask": "",
		"reg": { "owner": name, "address": p.address, "plate": car.plate, "vin": car.vin, "car": desc,
			"expires": date_add(t, 30 + rng.randi() % 330), "brand": "CLEAN", "prev": "" },
		"licence": { "name": name, "dob": p.dob, "address": p.address, "face": p.face,
			"number": "%s%07d" % [String(p.last).substr(0, 1), rng.randi() % 10000000], "expires": date_add(t, 60 + rng.randi() % 1400) },
		"insurance": { "holder": name, "insurer": INSURERS[rng.randi() % INSURERS.size()], "vin": car.vin,
			"from": date_add(t, -(10 + rng.randi() % 300)), "to": date_add(t, 20 + rng.randi() % 300),
			"policy": "P-%06d" % (rng.randi() % 1000000) },
		"sheet": { "vin": car.vin, "door": car.vin, "odo": car.odo, "tread": [], "pads": [], "lights": true, "rust": false,
			"surface": float(car.rust_look) > 0.05 },
		"work": { "name": name, "plate": car.plate, "car": desc },
		"flags": [], "napkin": "", "docs": ["work", "reg", "licence", "insurance", "sheet"], "hidden": [],
		"ask": {}, "exception": {}, "says": "", "clue": {},
	}
	for i in 4: c.sheet.tread.append(snappedf(2.4 + rng.randf() * 6.0, 0.1))
	for i in 2: c.sheet.pads.append(snappedf(3.5 + rng.randf() * 7.0, 0.1))
	# clean variety once the rules know about it: cars from away, and rebuilt salvage with its certificate
	if not plain:
		if rule_active("oop", day) and rng.randf() < 0.15: _transfer(c, day)
		if rule_active("salvage", day) and not want in ["salvage_no_cert", "title_washed"] and rng.randf() < 0.1:
			c.reg.brand = "SALVAGE"
			c.cert = { "vin": car.vin, "by": INSPECTORS[rng.randi() % INSPECTORS.size()], "issued": date_add(t, -(3 + rng.randi() % 200)) }
			c.docs.append("cert")
	# what's wrong with it (only problems the rules check today, so nothing is unfair)
	var options: Array = []
	for pr in PROBLEM_RULE:
		if rule_active(PROBLEM_RULE[pr], day): options.append(pr)
	var prob := "" if want == "clean" else want
	if want == "" and rng.randf() < 0.45 and not options.is_empty():
		prob = options[rng.randi() % options.size()]
	if prob != "": _inject(c, prob, day)
	elif want == "" and rng.randf() < 0.18: excuse(c, day)
	if not plain and rule_active("masks", day) and rng.randf() < 0.35: c.mask = MASKS[rng.randi() % MASKS.size()]
	_ensure_history(c, day)
	return c

## The inspection this car needs: the full one if it's new here from out of province.
static func inspection_job(c: Dictionary) -> String:
	return "FULL INSPECTION" if String(c.reg.get("prev", "")) != "" else "SAFETY INSPECTION"

## A car that's just come over from another province: the old ownership comes along, and it
## needs the full inspection.
func _transfer(c: Dictionary, day: int) -> void:
	var prov: String = PROVINCES[rng.randi() % PROVINCES.size()]
	c.reg.prev = prov
	c.old_reg = { "prov": prov, "owner": c.reg.owner, "vin": c.sheet.vin, "plate": plate(), "brand": "CLEAN",
		"issued": date_add(today(day), -(200 + rng.randi() % 2000)) }
	if not c.docs.has("old_reg"): c.docs.append("old_reg")
	c.request = "FULL INSPECTION"

## The car is in somebody else's name.
func _other_owner(c: Dictionary) -> void:
	c.reg.owner = other_name(c.licence.name)
	if c.has("old_reg"): c.old_reg.owner = c.reg.owner

## Dated odometer readings from past services, the last one at `top` km.
func _history(top: int, day: int) -> Array:
	var out: Array = []
	var km := top
	var back := 25 + rng.randi() % 120
	for i in 3 + rng.randi() % 2:
		if km < 1000: break
		out.push_front({ "date": date_add(today(day), -back), "km": km, "shop": SHOPS[rng.randi() % SHOPS.size()] })
		km -= 5000 + rng.randi() % 16000
		back += 120 + rng.randi() % 220
	return out

## Inspections bring their service history once the odometer rule is up.
func _ensure_history(c: Dictionary, day: int) -> void:
	if not rule_active("odo", day) or not INSPECTIONS.has(c.request) or c.has("history"): return
	c.history = _history(maxi(1500, int(c.sheet.odo) - 400 - rng.randi() % 9000), day)
	c.docs.append("history")

func _inject(c: Dictionary, prob: String, day: int) -> void:
	var t := today(day)
	if prob == "stolen" and bolo.is_empty(): make_bolo()
	match prob:
		"vin_mismatch": c.reg.vin = vin_tweak(c.car.vin)
		"plate_mismatch": c.reg.plate = plate_tweak(c.car.plate)
		"fails_inspection":
			c.request = inspection_job(c)
			match rng.randi() % 4:
				0: c.sheet.tread[rng.randi() % 4] = snappedf(0.4 + rng.randf() * 1.1, 0.1)
				1: c.sheet.pads[rng.randi() % 2] = snappedf(0.8 + rng.randf() * 2.0, 0.1)
				2: c.sheet.lights = false
				3: c.sheet.rust = true
		"expired_reg":
			c.reg.expires = date_add(t, -(1 + rng.randi() % 200))
			if rule_active("permit", day) and rng.randf() < 0.4: _proof(c, "expired_reg", day, "bad")
		"no_insurance":
			c.insurance = {}
			c.docs.erase("insurance")
		"insurance_expired": c.insurance.to = date_add(t, -(1 + rng.randi() % 90))
		"insurance_vin": c.insurance.vin = vin_tweak(c.car.vin)
		"name_mismatch": _other_owner(c)
		"bos_expired", "bos_forged":
			_other_owner(c)
			_proof(c, "name_mismatch", day, prob)
		"stolen":
			# the plate on the car is on the stolen list (and the papers were made to match)
			var b: Dictionary = bolo[rng.randi() % bolo.size()]
			c.car.plate = b.plate
			c.reg.plate = b.plate
			c.work.plate = b.plate
		"photo_mismatch":
			c.face_shown = int(c.person.face) ^ (1 + rng.randi() % 0xffff)
		"odo_rollback":
			c.request = inspection_job(c)
			# the real mileage was higher; somebody wound the dash back since the last service
			c.history = _history(int(c.sheet.odo) + 15000 + rng.randi() % 90000, day)
			if not c.docs.has("history"): c.docs.append("history")
		"vin_door_mismatch":
			c.sheet.door = vin()
			if rng.randf() < 0.4: _proof(c, "vin_door_mismatch", day, "bad")
		"out_of_province":
			if String(c.reg.prev) == "": _transfer(c, day)
			c.request = ["SAFETY INSPECTION", "OIL CHANGE", "BRAKE JOB", "WINTER TIRES ON"][rng.randi() % 4]
		"salvage_no_cert":
			c.reg.brand = "SALVAGE"
			c.erase("cert")
			c.docs.erase("cert")
			if rng.randf() < 0.4: _proof(c, "salvage_no_cert", day, "bad")
		"title_washed":
			if String(c.reg.prev) == "": _transfer(c, day)
			c.old_reg.brand = "SALVAGE"
			c.reg.brand = "CLEAN"
			c.request = "FULL INSPECTION"
	c.flags.append(prob)

## The proof a customer pulls out when you ASK: `how` is "valid", "bad" (forged or out of
## date), or for a bill of sale "bos_expired"/"bos_forged". It stays hidden until asked for.
func _proof(c: Dictionary, base: String, day: int, how: String) -> void:
	var t := today(day)
	var doc: String = PROOFS[base][0]
	var dash: String = c.sheet.vin
	var bad := how != "valid"
	match doc:
		"bos":
			var d := { "seller": c.reg.owner, "buyer": c.licence.name, "vin": dash, "price": 400 + rng.randi() % 80 * 100,
				"sold": date_add(t, -(rng.randi() % 10)) }
			if how == "bos_expired": d.sold = date_add(t, -(11 + rng.randi() % 60))
			elif bad:
				match rng.randi() % 3:
					0: d.seller = other_name(String(c.reg.owner))
					1: d.vin = vin_tweak(dash)
					2: d.buyer = other_name(String(c.licence.name))
			c.bos = d
		"permit":
			var d := { "plate": c.car.plate, "vin": dash, "from": date_add(t, -(1 + rng.randi() % 20)), "to": date_add(t, 2 + rng.randi() % 28) }
			if bad:
				if rng.randf() < 0.5:
					d.from = date_add(t, -(40 + rng.randi() % 30))
					d.to = date_add(t, -(1 + rng.randi() % 25))
				else: d.vin = vin_tweak(dash)
			c.permit = d
		"glovebox":
			c.glovebox = c.insurance if not c.insurance.is_empty() else { "holder": c.licence.name, "insurer": INSURERS[0], "vin": dash,
				"from": date_add(t, -30), "to": date_add(t, 200), "policy": "P-%06d" % (rng.randi() % 1000000) }
			if bad: c.glovebox.to = date_add(t, -(1 + rng.randi() % 60))
			c.insurance = {}
			c.docs.erase("insurance")
		"door_inv":
			var d := { "shop": BODY_SHOPS[rng.randi() % BODY_SHOPS.size()], "vin": dash, "door": c.sheet.door,
				"date": date_add(t, -(5 + rng.randi() % 300)), "amount": 600 + rng.randi() % 9 * 50 }
			if bad: d.door = vin_tweak(String(c.sheet.door))
			c.door_inv = d
		"cert":
			var d := { "vin": dash, "by": INSPECTORS[rng.randi() % INSPECTORS.size()], "issued": date_add(t, -(3 + rng.randi() % 200)) }
			if bad: d.vin = vin_tweak(dash)
			c.cert = d
	if not c.hidden.has(doc): c.hidden.append(doc)
	c.exception = { "problem": base, "doc": doc, "valid": not bad }
	var lines: Array = PROOF_LINES[doc]
	c.ask[base] = { "line": lines[rng.randi() % lines.size()], "doc": doc }

## Something on the papers looks wrong, but the customer has the proof that makes it fine
## (in a pocket until you ASK). Picks a discrepancy whose exception is in the rules today.
func excuse(c: Dictionary, day: int, base := "") -> bool:
	var bases: Array = []
	for b in PROOFS:
		if rule_active(PROBLEM_RULE[b], day) and rule_active(PROOFS[b][1], day): bases.append(b)
	if base == "":
		if bases.is_empty(): return false
		base = bases[rng.randi() % bases.size()]
	elif not bases.has(base): return false
	match base:
		"name_mismatch": _other_owner(c)
		"expired_reg": c.reg.expires = date_add(today(day), -(1 + rng.randi() % 60))
		"vin_door_mismatch": c.sheet.door = vin()
		"salvage_no_cert":
			c.reg.brand = "SALVAGE"
			c.erase("cert")
			c.docs.erase("cert")
	_proof(c, base, day, "valid")
	return true

## Thursday on: one of the Familia's cars. Something's wrong with it, and there's a napkin.
func familia(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch" if rng.randf() < 0.5 else "plate_mismatch")
	c.kind = "familia"
	c.napkin = ["DOM SAYS MAKE IT CLEAN. FAMILY PRICE. -S", "NEW NUMBERS ON THIS ONE. NO PAPERWORK. -S", "YOU KNOW WHAT TO DO. DOM SAYS HI. -S"][rng.randi() % 3]
	c.request = "\"DETAILING\""
	c.erase("history")
	c.docs.erase("history")
	return c

## Someone who isn't who he says he is asks for the thing you shouldn't do.
func sting(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch")
	c.kind = "sting"
	c.napkin = "HEARD YOU DO NEW NUMBERS. $800 CASH. NO QUESTIONS. -A FRIEND OF A FRIEND"
	c.request = "\"DETAILING\""
	c.erase("history")
	c.docs.erase("history")
	return c

## Stings come every other Friday while the heat is up (and the first Friday, to say hello).
static func sting_day(day: int, heat: int) -> bool:
	return day == 4 or (posmod(day, 7) == 4 and week_of(day) % 2 == 1 and heat >= 30)

## The day at the window: who arrives when. [{t (minutes since 8:00), c}], in order.
## `extra` is a story step's own customers (ids from data/story_customers.json, or specs).
func shift(day: int, heat := 0, extra: Array = [], chapter := 1) -> Array:
	var out: Array = []
	var lo := 40.0 - minf(10.0, day * 0.5)
	var hi := 75.0 - minf(14.0, day * 0.7)
	var t := 4.0 + rng.randf() * 14.0
	while t < 555.0:
		out.append({ "t": t, "c": customer(day) })
		t += rng.randf_range(lo, hi)
	if posmod(day, 7) == 3 or day == 4: out.append({ "t": 60.0 + rng.randf() * 360.0, "c": familia(day) })
	if sting_day(day, heat): out.append({ "t": 120.0 + rng.randf() * 300.0, "c": sting(day) })
	var specs: Array = []
	for id in scheduled(chapter, day): specs.append(story_spec(id))
	for e in extra: specs.append(story_spec(e) if e is String else e)
	for s in specs:
		if (s as Dictionary).is_empty(): continue
		out.append({ "t": arrive_of(s), "c": scripted(s, day) })
	out.sort_custom(func(a, b): return a.t < b.t)
	return out

## A day's customers in the order they turn up (the shift without the times).
func day_line(day: int) -> Array:
	return shift(day).map(func(x): return x.c)

# ------------------------------------------------------------------ scripted customers

const STORY_PATH := "res://data/story_customers.json"
static var _story: Dictionary = {}

## data/story_customers.json: "customers" (id -> spec) and "schedule" (chapter -> day -> [ids]).
static func story_data() -> Dictionary:
	if _story.is_empty() and FileAccess.file_exists(STORY_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(STORY_PATH))
		if d is Dictionary: _story = d
	return _story

## The ids booked for a chapter's day.
static func scheduled(chapter: int, day: int) -> Array:
	var sch: Dictionary = story_data().get("schedule", {})
	var ch: Dictionary = sch.get(str(chapter), {})
	return ch.get(str(day), [])

## A scripted customer's spec by id ({} if there's no such customer).
static func story_spec(id) -> Dictionary:
	if id is Dictionary: return id
	var all: Dictionary = story_data().get("customers", {})
	var s: Dictionary = all.get(String(id), {})
	if not s.is_empty() and not s.has("id"): s["id"] = String(id)
	return s

## "10:15" (or minutes since 8:00) -> minutes since 8:00.
static func arrive_of(spec: Dictionary) -> float:
	var a = spec.get("arrive", 120)
	if a is String:
		var hm := (a as String).split(":")
		return clampf(int(hm[0]) * 60.0 + (int(hm[1]) if hm.size() > 1 else 0) - 480.0, 0.0, SHIFT_LEN - 30.0)
	return clampf(float(a), 0.0, SHIFT_LEN - 30.0)

## A scripted customer: the same papers every time (seeded by the id), their own lines,
## and what each stamp does to the story. See data/story_customers.json for the keys.
func scripted(spec: Dictionary, day: int) -> Dictionary:
	var r := CounterRules.new(hash(String(spec.get("id", "story"))))
	r.bolo = bolo
	var fixed := { "person": spec.get("person", {}), "car": spec.get("car", {}), "plain": true }
	if spec.has("request"): fixed.request = spec.request
	var prob := String(spec.get("problem", "clean"))
	var c := r.customer(day, prob if prob != "" else "clean", fixed)
	if spec.has("excuse"): r.excuse(c, day, String(spec.excuse))
	for k in ["reg", "licence", "insurance", "sheet", "work"]:
		if spec.has("papers") and (spec.papers as Dictionary).has(k): (c[k] as Dictionary).merge(spec.papers[k], true)
	c.kind = String(spec.get("kind", "story"))
	c.script = spec
	c.napkin = String(spec.get("napkin", c.napkin))
	c.says = String(spec.get("says", ""))
	c.clue = spec.get("clue", {})
	if spec.has("mask"): c.mask = String(spec.mask)
	if spec.has("letter"):
		c.letter = spec.letter
		c.docs.append("letter")
	for topic in spec.get("ask", {}): c.ask[topic] = spec.ask[topic]
	if c.kind != "regular" and c.kind != "story":
		c.erase("history")
		c.docs.erase("history")
	return c

# ------------------------------------------------------------------ reading the papers

## The insurance card on the desk, or the one in the glovebox.
static func insurance_of(c: Dictionary) -> Dictionary:
	var ins: Dictionary = c.get("insurance", {})
	return ins if not ins.is_empty() else c.get("glovebox", {})

## A bill of sale against the papers: "" if it covers the name mismatch, else what's wrong.
static func bos_check(c: Dictionary, day: int) -> String:
	if not rule_active("bos", day) or not c.has("bos"): return "name_mismatch"
	var b: Dictionary = c.bos
	if b.seller != c.reg.owner or b.buyer != c.licence.name or b.vin != c.sheet.vin: return "bos_forged"
	var age := days_between(b.sold, today(day))
	if age < 0 or age > 10: return "bos_expired"
	return ""

## Does the customer's proof for `base` check out, read only from the papers?
static func proof_ok(c: Dictionary, base: String, day: int) -> bool:
	if not PROOFS.has(base): return false
	var doc: String = PROOFS[base][0]
	if not rule_active(PROOFS[base][1], day) or not c.has(doc): return false
	var d: Dictionary = c[doc]
	var t := today(day)
	var dash: String = c.sheet.vin
	match doc:
		"bos": return bos_check(c, day) == ""
		"permit", "glovebox": return d.vin == dash and date_cmp(d.from, t) <= 0 and date_cmp(d.to, t) >= 0
		"door_inv": return d.vin == dash and d.door == c.sheet.door and date_cmp(d.date, t) <= 0
		"cert": return d.vin == dash and date_cmp(d.issued, t) <= 0
	return false

## The service history disagrees with the odometer: a reading above today's, or one that went down.
static func odo_rolled(c: Dictionary) -> bool:
	var prev := -1
	for e in c.get("history", []):
		if int(e.km) > int(c.sheet.odo) or int(e.km) < prev: return true
		prev = int(e.km)
	return false

## Every problem a careful player could prove today, read only from what's on the desk:
## the documents (and the ones they'd get by asking), the car in the window, the rules,
## the stolen list on the wall, the person's face.
static func find_problems(c: Dictionary, day: int, bolo_list: Array) -> Array:
	var out: Array = []
	var t := today(day)
	var reg: Dictionary = c.reg
	var sheet: Dictionary = c.sheet
	var dash: String = sheet.vin
	if rule_active("match", day):
		if reg.vin != dash: out.append("vin_mismatch")
		if reg.plate != c.car.plate: out.append("plate_mismatch")
	if rule_active("door", day) and String(sheet.get("door", dash)) != dash and not proof_ok(c, "vin_door_mismatch", day):
		out.append("vin_door_mismatch")
	if rule_active("inspect", day) and INSPECTIONS.has(c.request):
		var fail := false
		for x in sheet.tread: if x < 1.6: fail = true
		for x in sheet.pads: if x < 3.0: fail = true
		if not sheet.lights or sheet.rust: fail = true
		if fail: out.append("fails_inspection")
	if rule_active("reg_valid", day) and date_cmp(reg.expires, t) < 0 and not proof_ok(c, "expired_reg", day): out.append("expired_reg")
	if rule_active("insured", day):
		var ins := insurance_of(c)
		if ins.is_empty(): out.append("no_insurance")
		else:
			if date_cmp(ins.to, t) < 0: out.append("insurance_expired")
			if ins.vin != dash: out.append("insurance_vin")
	if rule_active("owner", day) and c.licence.name != reg.owner:
		var b := bos_check(c, day)
		if b != "": out.append(b)
	if rule_active("bolo", day):
		for b in bolo_list:
			if b.plate == c.car.plate or b.vin == dash: out.append("stolen")
	if rule_active("photo", day) and c.face_shown != c.licence.face: out.append("photo_mismatch")
	if rule_active("odo", day) and odo_rolled(c): out.append("odo_rollback")
	if rule_active("oop", day) and String(reg.get("prev", "")) != "" and c.request != "FULL INSPECTION": out.append("out_of_province")
	if rule_active("salvage", day):
		if String(reg.get("brand", "CLEAN")) == "SALVAGE" and not proof_ok(c, "salvage_no_cert", day): out.append("salvage_no_cert")
		if c.has("old_reg") and String(c.old_reg.brand) != String(reg.get("brand", "CLEAN")): out.append("title_washed")
	return out

## What a customer says when you ASK about `topic`: {line, doc (handed over), unmask}.
static func answer(c: Dictionary, topic: String) -> Dictionary:
	var h := absi(int(c.person.face) + hash(topic))
	if topic == "mask": return { "line": MASK_LINES[h % MASK_LINES.size()], "unmask": true }
	if c.get("ask", {}).has(topic): return c.ask[topic]
	match c.kind:
		"sting": return { "line": STING_ASK[h % STING_ASK.size()] }
		"familia": return { "line": "DOM SAYS YOU DON'T ASK. HE SAYS IT NICE, BUT HE SAYS IT." }
	var pool: Array = EXCUSES.get(topic, [])
	if pool.is_empty(): return { "line": "I DON'T KNOW ANYTHING ABOUT THAT. I JUST DRIVE IT." }
	return { "line": pool[h % pool.size()] }

## What a citation costs: the first WARNINGS a shift are free (police matters never are).
static func fine_for(c: Dictionary, warnings_used: int) -> int:
	if c.kind == "sting": return 2000
	return 0 if warnings_used < WARNINGS else FINE

## What the stamp did. Returns { money, dirty, citation, heat, trust, review, line, correct, flags }
static func judge(c: Dictionary, stamp: String, day: int, bolo_list: Array) -> Dictionary:
	var r := _judge(c, stamp, day, bolo_list)
	r.flags = []
	var spec: Dictionary = c.get("script", {})
	if spec.is_empty(): return r
	# a scripted customer: their own lines and what the story remembers
	r.flags.append("desk_%s_%s" % [spec.get("id", "story"), stamp.to_lower()])
	var o: Dictionary = spec.get("outcomes", {}).get(stamp, {})
	for k in ["line", "citation"]: if o.has(k): r[k] = String(o[k])
	for k in ["money", "dirty", "heat", "trust", "review"]: if o.has(k): r[k] = int(o[k])
	if o.has("correct"): r.correct = bool(o.correct)
	for f in o.get("flags", []): r.flags.append(String(f))
	return r

static func _judge(c: Dictionary, stamp: String, day: int, bolo_list: Array) -> Dictionary:
	var probs := find_problems(c, day, bolo_list)
	var r := { "money": 0, "dirty": 0, "citation": "", "heat": 0, "trust": 0, "review": 0, "line": "", "correct": true }
	match c.kind:
		"familia":
			match stamp:
				"WRENCH": r.dirty = 600; r.trust = 10; r.heat = 4; r.line = "\"Dom says thanks. Family looks after family.\""
				"DENIED": r.trust = -15; r.line = "\"...I'll tell Dom you were busy.\" He doesn't look at you."
				"REPORT": r.trust = -60; r.heat = -5; r.line = "Twenty minutes later a black Charjer idles across the street. For an hour."
				_: r.trust = -5; r.line = "\"Wrong stamp, kid.\""
			r.correct = stamp == "WRENCH"
			return r
		"sting":
			match stamp:
				"WRENCH": r.heat = 60; r.citation = "UNDERCOVER STING: VIN TAMPERING. $2,000 FINE AND A FILE WITH YOUR NAME ON IT"; r.correct = false; r.line = "He badges you. \"Thought so.\""
				"DENIED": r.line = "\"No worries, man. Wrong garage.\" He writes something in his phone."
				"REPORT": r.heat = -15; r.line = "The cops come and go. One of them shakes your hand. The Familia hears about it."; r.trust = -10
				_: r.line = "He leaves."
			return r
	var bad := not probs.is_empty()
	if probs.has("stolen") or probs.has("title_washed"):
		var hot := probs.has("stolen")
		match stamp:
			"REPORT":
				r.heat = -5
				r.line = "The police tow it. A cop says thanks without looking up." if hot else "The Ministry takes the file. Somebody in another province is about to have a very bad week."
			"APPROVED":
				r.correct = false
				r.heat = 25 if hot else 10
				r.citation = "YOU WORKED ON A STOLEN CAR. IT WAS ON THE LIST ON YOUR WALL" if hot else "STICKERED A WASHED SALVAGE TITLE. THE BRAND WAS ON THE OLD OWNERSHIP"
			"DENIED":
				r.correct = false
				if hot: r.citation = "STOLEN CAR SENT BACK ON THE ROAD. IT WAS ON THE LIST: REPORT IT"
				else: r.line = "\"Fine. I'll go to Lindsay's. She passes anything with a pulse.\" Somebody should've reported that title."
			"WRENCH": r.correct = false; r.heat = 40; r.citation = "OFF-BOOKS WORK ON A STOLEN CAR" if hot else "OFF-BOOKS WORK ON A WASHED SALVAGE CAR"
		return r
	match stamp:
		"APPROVED":
			if bad:
				r.correct = false
				r.citation = _citation_for(probs[0])
			else:
				r.money = PAY.get(c.request, 80)
				r.review = 1
				r.line = ["\"Thanks, bud.\"", "\"Same time next year.\"", "\"Your dad would be proud.\"", "\"Cash okay?\"", "\"Frank used to give out a sucker after. I'm not asking. I'm just saying there was a tradition.\""][int(c.person.face) % 5]
		"DENIED":
			if bad:
				r.line = _denied_line(probs[0])
			else:
				r.correct = false
				r.review = -1
				r.line = "\"There's nothing wrong with my papers!\" A one-star review appears an hour later."
				if not c.get("exception", {}).is_empty(): r.line = "\"I HAD THE PAPER RIGHT HERE. YOU NEVER ASKED.\" A one-star review appears an hour later."
		"REPORT":
			r.correct = false
			r.review = -1
			r.heat = 3
			r.line = "The police show up for nothing. They are not amused, and neither is your customer."
		"WRENCH":
			r.correct = false
			r.heat = 8
			r.citation = "OFF-BOOKS WORK ON A CUSTOMER CAR (NO WORK ORDER, NO RECEIPT)"
	return r

static func _citation_for(p: String) -> String:
	match p:
		"vin_mismatch": return "VIN ON THE REGISTRATION DOESN'T MATCH THE CAR"
		"plate_mismatch": return "PLATE ON THE REGISTRATION DOESN'T MATCH THE CAR"
		"fails_inspection": return "PASSED A CAR THAT FAILS INSPECTION"
		"expired_reg": return "SERVICED A CAR WITH AN EXPIRED REGISTRATION"
		"no_insurance": return "SERVICED AN UNINSURED CAR"
		"insurance_expired": return "INSURANCE WAS EXPIRED"
		"insurance_vin": return "INSURANCE CARD COVERS A DIFFERENT VIN"
		"name_mismatch": return "LICENCE NAME DOESN'T MATCH THE REGISTERED OWNER"
		"photo_mismatch": return "THE LICENCE BELONGS TO SOMEBODY ELSE"
		"odo_rollback": return "PASSED A CAR WITH A ROLLED-BACK ODOMETER. THE SERVICE HISTORY SAID SO"
		"bos_expired": return "BILL OF SALE WAS OLDER THAN TEN DAYS"
		"bos_forged": return "ACCEPTED A BILL OF SALE THAT DIDN'T MATCH THE PAPERS"
		"vin_door_mismatch": return "DOOR-JAMB VIN DIDN'T MATCH THE DASH"
		"out_of_province": return "OUT-OF-PROVINCE CAR WITHOUT THE FULL INSPECTION"
		"salvage_no_cert": return "STICKERED A SALVAGE CAR WITHOUT A STRUCTURAL CERTIFICATE"
	return "PAPERWORK PROBLEM"

static func _denied_line(p: String) -> String:
	match p:
		"vin_mismatch": return "\"Must be a typo at the registry.\" Sure it is."
		"plate_mismatch": return "\"I swapped plates with my cousin, it's fine.\" It is not fine."
		"fails_inspection": return "\"How much to just... pass it?\" Gus coughs very loudly."
		"expired_reg": return "\"I've been MEANING to renew it.\""
		"no_insurance", "insurance_expired", "insurance_vin": return "\"Insurance is a scam anyway.\""
		"name_mismatch": return "\"It's my buddy's car. He said it's cool.\""
		"photo_mismatch": return "\"I got a haircut.\" And a new face, apparently."
		"odo_rollback": return "\"It's a very young car for its age.\" It is not."
		"bos_expired", "bos_forged": return "\"The guy who sold it to me seemed really nice.\""
		"vin_door_mismatch": return "\"It's a GOOD door.\" It's somebody else's door."
		"out_of_province": return "\"Fine. I'll book the full one. In Toronto we just... had cars.\""
		"salvage_no_cert": return "\"My brother-in-law's going to be very hurt.\""
	return "They leave, muttering."
