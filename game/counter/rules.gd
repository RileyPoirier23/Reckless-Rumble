## The counter at Covington Auto: who walks in, what papers they carry, what's wrong with
## them, what they say when you ASK, and what each stamp costs you. Pure logic (no drawing),
## so it can be tested headless.
##
## The generator injects problems; `find_problems` finds them again by reading only the
## documents (including the ones a customer only hands over when you ASK), the car and the
## wall. The tests check that the two always agree, so every problem in the game can actually
## be caught by a player who looks, and an exception only holds when its proof does.
##
## Days count from Monday 7 October 2019 (day 0). Weekends, Thanksgiving and Remembrance Day
## are closed. The rules arrive on the days in RULES: Year 1, weeks 1 to 8 (bible section 3.8):
## the Ministry's audit in week 7, and winter in week 8. From week 5 the courier brings the
## shop's parts to the window (bible section 3.2): a box, a packing slip, and our own order to
## read it against. From week 6 the police list has stolen part serials on it as well as cars.
##
## Walk-ins and the courier's boxes are made from seeds of their own, so a file can be pulled
## out of the cabinet and rebuilt exactly (the audit, and the people who come back: see
## regulars.gd). A regular's visit rebuilds from who they are and what Leo stamped last time.
class_name CounterRules
extends RefCounted

const YEAR := 2019                      # Year 1 of the story
const WEEK_START := [YEAR, 10, 7]       # Monday, October 7
const DAYS := ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const VIN_CHARS := "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
## Days the shop is shut besides the weekends.
const CLOSED := { 7: "THANKSGIVING", 35: "REMEMBRANCE DAY" }
const LAST_DAY := 53                    # Friday 29 November: the end of week eight, the first week of winter
const WEEKS := 8

# ------------------------------------------------------------------ the shift
const SHIFT_LEN := 600.0                # minutes on the clock, 8:00 to 18:00
const REAL_SECONDS := 600.0             # ...in ten real minutes
const HONK_AFTER := 90.0                # minutes on one customer before the next one leans on the horn
const WARNINGS := 2                     # free Ministry warnings a shift
const REVOKE_AT := 12                   # citations (after the warnings) that cost the licence
const MEETINGS_TO_REVOKE := 3           # ...or this many Ministry meetings (four citations in a week is a meeting)

# the Ministry's rules: what's checked from which day, and which tab of the binder it lives in
# (PARTS is Gus's own page, taped in)
const TABS := ["INSPECTION", "DOCUMENTS", "POLICE", "MINISTRY", "SEASONAL", "PARTS"]
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
	{ "day": 28, "id": "tint", "tab": "INSPECTION", "text": "WINDOW TINT: FRONT SIDE WINDOWS MUST PASS 70% OF LIGHT. A MINISTRY MEDICAL EXEMPTION COVERS IT: THIS VIN, THIS DRIVER, NOT EXPIRED." },
	{ "day": 30, "id": "courier", "tab": "PARTS", "text": "GUS: SIGN FOR A BOX ONLY IF THE PACKING SLIP MATCHES OUR ORDER: PART NO. AND SHIP TO. A SUPPLIER'S SUPERSESSION NOTICE COVERS A NEW PART NO. FROM THE STATES, CUSTOMS MUST DECLARE WHAT WE PAID." },
	{ "day": 36, "id": "noise", "tab": "INSPECTION", "text": "EXHAUST: NO HOLES. 95 DB MAX AT 3,000 RPM." },
	{ "day": 38, "id": "hot", "tab": "POLICE", "text": "POLICE: STOLEN PART SERIALS ARE ON THE LIST. GUS READS THE SERIAL OFF THE PART, NOT THE INVOICE. ON THE LIST, ON A CAR OR IN A BOX: REPORT IT." },
	{ "day": 42, "id": "audit", "tab": "MINISTRY", "text": "AUDIT WEEK: THE INSPECTOR PULLS TWO OF YOUR WORK ORDERS A DAY. STAMP EACH ONE AGAIN. DISAGREEING WITH YOUR OWN STAMP IS A CITATION." },
	{ "day": 49, "id": "winter", "tab": "SEASONAL", "text": "WINTER TIRES REQUIRED ON TAXIS, RIDESHARES AND COMMERCIAL VEHICLES, DEC 1 TO APR 30. FROM NOV 25, NO STICKER FOR ONE WITHOUT THEM." },
	{ "day": 51, "id": "studs", "tab": "SEASONAL", "text": "STUDDED TIRES: OCT 15 TO APR 30 ONLY." },
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
	"tint": "tint", "noise": "noise", "wrong_part": "courier", "customs_value": "courier", "ship_to": "courier",
	"hot_part": "hot", "no_winter_tires": "winter", "studs_out_of_season": "studs",
}
## Problems the right answer to is REPORT, not DENY.
const REPORT_PROBLEMS := ["stolen", "title_washed", "hot_part"]
## Problems that come in a courier's box, not a customer's car. (A stolen part comes either way:
## customer(day, "hot_part") is a car, courier(day, "hot_part") a box.)
const COURIER_PROBLEMS := ["wrong_part", "customs_value", "ship_to"]
## The exceptions: a discrepancy -> [the document that can explain it, the rule that makes it count].
const PROOFS := {
	"name_mismatch": ["bos", "bos"], "expired_reg": ["permit", "permit"], "no_insurance": ["glovebox", "insured"],
	"vin_door_mismatch": ["door_inv", "door"], "salvage_no_cert": ["cert", "salvage"],
	"tint": ["exempt", "tint"], "wrong_part": ["notice", "courier"],
}
const TINT_MIN := 70                    # % of light through the front side windows
const NOISE_MAX := 95                   # dB at 3,000 rpm

# ------------------------------------------------------------------ hot parts (week 6) and winter (week 8)

## What gets stolen off cars for its parts: [on the invoice, on Gus's sheet, on the police list].
const HOT_PARTS := [["CATALYTIC CONVERTER", "CAT CONVERTER", "CAT"], ["AIRBAG MODULE, DRIVER", "AIRBAG MODULE", "AIRBAG"],
	["ALLOY RIMS (SET OF 4)", "ALLOY RIMS", "RIMS"], ["STEREO HEAD UNIT", "STEREO", "STEREO"], ["TRANSMISSION, USED", "TRANSMISSION", "TRANS"]]
## How many part serials the police list carries.
const HOT_LISTED := 4
## Where somebody got the part on their car.
const PART_SELLERS := ["MARKETTHING (PRIVATE SALE)", "SALISBURY SALVAGE", "DIEPPE AUTO RECYCLERS", "THE FLEA MARKET ON MAIN", "FUNDY PARTS SUPPLY"]
## What the ownership says the car's for (PRIVATE, or one of these) once winter tires care. These
## need winter tires on from NOV 25 (at the stations) or DEC 1 (on the road) to APR 30.
const WINTER_USES := ["TAXI", "RIDESHARE", "COMMERCIAL"]
const WINTER_SEASON := [[11, 25], [4, 30]]
const STUD_SEASON := [[10, 15], [4, 30]]
## Gus's word for the tires on the car.
const TIRE_TEXT := { "ALL-SEASON": "ALL-SEASONS", "SUMMER": "SUMMERS", "WINTER": "WINTERS", "STUDDED": "STUDDED WINTERS" }

# ------------------------------------------------------------------ the courier (week 5 on)

const SHOP := "COVINGTON AUTO"
## The two people who bring the boxes: Fundy's own van, and the parcel company from the border.
const COURIERS := {
	"fundy": { "person": { "first": "RHEAL", "last": "BOURQUE", "face": 311707, "fem": 0, "dob": [1968, 5, 30], "address": "FUNDY PARTS SUPPLY" },
		"car": "chevrolay_expresso_2010", "paint": "#e8e4dc", "supplier": "FUNDY PARTS SUPPLY" },
	"parcel": { "person": { "first": "DENISE", "last": "ARSENAULT", "face": 522119, "fem": 1, "dob": [1985, 9, 9], "address": "MARITIME PARCEL" },
		"car": "fjord_transitory_2016", "paint": "#6a2a4a", "supplier": "ROCKBOTTOMAUTO.COM" },
}
## What the bay orders: [part, what we pay, the job that's waiting on it].
const ORDER_PARTS := [
	["BRAKE PADS, FRONT (SET)", 48, "BRAKE JOB"], ["BRAKE ROTORS, FRONT (PAIR)", 96, "BRAKE JOB"],
	["CALIPER, FRONT LEFT", 84, "BRAKE JOB"], ["MUFFLER, DIRECT FIT", 138, "SAFETY INSPECTION"],
	["TAIL LIGHT ASSEMBLY, LEFT", 76, "SAFETY INSPECTION"], ["OXYGEN SENSOR, UPSTREAM", 62, "CHECK ENGINE LIGHT"],
	["IGNITION COILS (SET OF 4)", 118, "CHECK ENGINE LIGHT"], ["OIL FILTERS (CASE OF 12)", 54, "OIL CHANGE"],
	["TIRE VALVE STEMS (BAG OF 50)", 31, "WINTER TIRES ON"], ["WHEEL BEARING, FRONT", 79, "SAFETY INSPECTION"],
]
## From week 6 Gus orders some parts used, off Fundy's used shelf: those come with a serial.
## [part, what we pay, the job], in the order of HOT_PARTS (a cat, an airbag, rims).
const USED_PARTS := [["CATALYTIC CONVERTER, USED", 210, "CHECK ENGINE LIGHT"], ["AIRBAG MODULE, USED", 165, "SAFETY INSPECTION"],
	["ALLOY RIMS, USED (SET OF 4)", 240, "WINTER TIRES ON"]]
## Boxes that came to the wrong Covington.
const WRONG_SHIPTO := ["COVINGTON DENTAL", "COVINGTON AUTO BODY", "LINDSAY'S LUBE & INSPECT", "COVINGTON HOME HARDWARE"]
const FAMILIA_SHIPTO := "COVINGTON - BAY 3 - SAL"
const RESTOCK := 0.15                   # what a supplier keeps when you send back a part you signed for
const CUSTOMS_PENALTY := 75             # the broker's bill for a false declaration you signed for
const DOCTORS := ["DR. LEGER", "DR. MALLET", "DR. CHIASSON", "DR. MACLEAN"]

# ------------------------------------------------------------------ the audit (week 7)

## Inspector Hachey, the Ministry, at the window in audit week.
const HACHEY := { "first": "GERARD", "last": "HACHEY", "face": 425117, "fem": 0, "dob": [1957, 2, 11], "address": "THE MINISTRY, FREDERICTON" }
const HACHEY_CAR := { "catalogue": "fjord_crown_victorious_2005", "paint": "#8a8e94" }
## When he pulls a file: 9:30 and 2:00.
const AUDIT_TIMES := [90.0, 360.0]
## A file is re-judged from its papers alone: no face at the window, no car in the bay, no
## stolen list (cars or parts) from that week.
const UNAUDITABLE := ["stolen", "photo_mismatch", "hot_part"]

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
	{ "make": "VOLKSWAGON", "model": "GOLPH", "len": 4.2, "wid": 1.78, "body": "hatch" },
	{ "make": "DODGY", "model": "GRAND CRAVIN'", "len": 5.1, "wid": 1.95, "body": "minivan" },
	{ "make": "KEEYA", "model": "SOUL-LESS", "len": 4.1, "wid": 1.8, "body": "hatch" },
]
const PAINTS := ["#c8342c", "#2c5a8a", "#e8e4dc", "#2a2a2e", "#8a8e94", "#3a6a3a", "#d8a03a", "#6a2a4a", "#4a6a8a", "#b8b0a0"]
const ZONES := ["residential", "residential", "commercial", "rural", "downtown", "village"]
const REQUESTS := ["SAFETY INSPECTION", "SAFETY INSPECTION", "OIL CHANGE", "BRAKE JOB", "WINTER TIRES ON", "CHECK ENGINE LIGHT"]
const INSPECTIONS := ["SAFETY INSPECTION", "FULL INSPECTION"]
const INSURERS := ["PETITCODIAC MUTUAL", "TIDAL BORE INSURANCE", "FUNDY GENERAL"]
const SHOPS := ["COVINGTON AUTO", "LINDSAY'S LUBE", "CANADIAN TIRED", "HUBCAP CITY OIL&GO", "RIVERVIEW TIRE", "SALISBURY GAS BAR"]
const BODY_SHOPS := ["DIEPPE COLLISION", "BOUDREAU BODY & PAINT", "FENDER BENDERS LTD"]
const INSPECTORS := ["J. GOGUEN, LIC. 4471", "R. MAILLET, LIC. 2290", "D. STEEVES, LIC. 3318"]
const PROVINCES := ["NOVA SCOTIA", "QUEBEC", "ONTARIO", "P.E.I.", "NEWFOUNDLAND"]
const MASKS := ["GOALIE", "PUMPKIN", "GHOST"]
# what each job brings into the shop (a delivery brings nothing until the job it's for goes ahead)
const PAY := { "SAFETY INSPECTION": 75, "FULL INSPECTION": 140, "OIL CHANGE": 70, "BRAKE JOB": 320, "WINTER TIRES ON": 110, "CHECK ENGINE LIGHT": 140, "DELIVERY": 0 }
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
	"local": "SO. WHICH TIM BURTONS DO YOU GO TO?",
	"tint": "THOSE WINDOWS ARE TOO DARK.", "noise": "YOUR EXHAUST FAILS.", "wrong_part": "THAT'S NOT THE PART WE ORDERED.",
	"customs_value": "CUSTOMS SAYS WE PAID SOMETHING ELSE.", "ship_to": "THIS BOX ISN'T ADDRESSED TO US.",
	"hot_part": "THAT SERIAL'S ON THE POLICE LIST.", "no_winter_tires": "IT'S A WORKING CAR. IT NEEDS WINTERS ON FOR A STICKER.",
	"studs_out_of_season": "IT'S NOT STUD SEASON.",
}
## Small talk from people who actually live here.
const LOCAL_LINES := ["THE MOUNTAIN TIM BURTONS. LIKE A NORMAL PERSON.", "THE ONE ON MAIN. THE DRIVE-THRU KID THERE'S SEEN THINGS.",
	"I DON'T GO TO TIM BURTONS. I GO TO THE GAS BAR IN SALISBURY. THEIR COFFEE TASTES LIKE THE GAS. I RESPECT THAT.",
	"WHICHEVER ONE HAS THE SHORTEST LINE. SO NONE OF THEM.", "MOUNTAIN RD. MY SISTER-IN-LAW WORKS THE WINDOW. SHE HATES ME. FREE BURTON BITS, THOUGH."]
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
	"vin_door_mismatch": ["SOMEBODY BACKED INTO ME AT THE CANADIAN TIRED. THE NEW DOOR CAME OFF A CAR AT THE PICK-N-PRAY.",
		"THAT DOOR'S ALWAYS BEEN LIKE THAT.", "DOORS HAVE VINS? SINCE WHEN? WHO'S CHECKING DOORS?"],
	"out_of_province": ["I'M FROM AWAY. TORONTO. IS IT NORMAL EVERYBODY HERE WAVES AT ME?",
		"IT PASSED IN NOVA SCOTIA. NOVA SCOTIA IS VERY STRICT. ABOUT LOBSTERS.", "THE FULL ONE COSTS MORE. I'M NOT MADE OF MONEY. I'M MADE OF LOANS."],
	"salvage_no_cert": ["IT'S BEEN FIXED. MY BROTHER-IN-LAW DID IT. HE'S VERY GOOD WITH A HAMMER.", "SALVAGE JUST MEANS IT'S BEEN SAVED. LIKE A SOUL.",
		"THE CERTIFICATE'S AT HOME. ON THE FRIDGE. UNDER A MAGNET SHAPED LIKE A LOBSTER."],
	"title_washed": ["THEY SAY SALVAGE, NEW BRUNSWICK SAYS CLEAN. I TRUST NEW BRUNSWICK.", "THE BRAND FELL OFF IN THE MOVE. LIKE A HUBCAP.",
		"WHAT BRAND? I DON'T SEE A BRAND."],
	"tint": ["IT'S FACTORY. THE FACTORY WAS MY COUSIN'S GARAGE.", "I'M SENSITIVE TO LIGHT. AND TO POLICE.",
		"THAT'S NOT TINT. THAT'S DIRT. I'LL WASH IT IN THE SPRING.", "MY BUDDY DID IT FOR FREE. HE SAID IT WAS LEGAL. HE SAID IT FROM INSIDE A VERY DARK CAR."],
	"noise": ["IT'S SUPPOSED TO SOUND LIKE THAT. IT'S A SPORTS CAR. SPIRITUALLY.", "THE HOLE'S FOR PERFORMANCE. IT LETS THE NOISE OUT.",
		"THAT'S NOT THE EXHAUST, THAT'S THE RADIO. I LISTEN TO A LOT OF EXHAUST.", "THE NEIGHBOURS LOVE IT. THEY TELL ME EVERY MORNING. AT SIX."],
	"wrong_part": ["I JUST DRIVE THE VAN, BUD. SIGN OR DON'T.", "THE WAREHOUSE PICKS 'EM. THE WAREHOUSE IS ONE GUY NAMED RODNEY.",
		"IT'S PROBABLY THE SAME PART. THEY'RE ALL KIND OF THE SAME PART."],
	"customs_value": ["I DON'T WRITE THE CUSTOMS FORMS. I JUST CARRY THEM. VERY CAREFULLY.", "THE AMERICANS FILL THOSE OUT. THEY USE A DIFFERENT KIND OF NUMBERS.",
		"LOWER'S BETTER, RIGHT? LESS TAX? I'M ON YOUR SIDE HERE."],
	"ship_to": ["IT SAYS COVINGTON. YOU'RE COVINGTON. CLOSE ENOUGH FOR THE VAN.", "THE SCANNER SAYS THIS STOP. I DON'T ARGUE WITH THE SCANNER. IT HAS A TEMPER.",
		"THERE'S A LOT OF COVINGTONS. YOU'RE THE ONE WITH THE PARKING."],
	"hot_part": ["I GOT IT OFF A GUY ON MARKETTHING. WE MET IN THE CHAMPAGNE PLACE LOT AT MIDNIGHT. VERY PROFESSIONAL. HE HAD A HEADLAMP.",
		"THE SERIAL'S A COINCIDENCE. THERE'S ONLY SO MANY NUMBERS.", "IT FELL OFF A TRUCK. LIKE, ACTUALLY FELL. I WAS BEHIND THE TRUCK.",
		"THE INVOICE SAYS WHAT IT SAYS. READ THE INVOICE. WHY ARE YOU READING THE PART?"],
	"hot_part_box": ["I JUST DRIVE THE VAN. RODNEY BUYS THE USED STUFF. WHO RODNEY BUYS IT FROM, I DON'T KNOW. I'M STARTING TO WANT TO KNOW.",
		"USED PARTS COME OFF USED CARS. WHERE THE USED CARS COME FROM, I DON'T ASK. IT'S A RULE. RODNEY'S RULE."],
	"no_winter_tires": ["THE WINTERS ARE IN MY BROTHER-IN-LAW'S SHED. HE'S IN FLORIDA. THE SHED'S LOCKED.",
		"THEY'RE ALL-SEASONS. IT SAYS ALL SEASONS. WINTER'S A SEASON. READ THE TIRE.", "I ONLY DO THE AIRPORT RUN. THE AIRPORT'S PLOWED.",
		"IT'S NOT DECEMBER YET. I'LL PUT 'EM ON NOVEMBER THIRTY-FIRST."],
	"studs_out_of_season": ["I LEAVE 'EM ON ALL YEAR. SAVES A TRIP.", "IT COULD SNOW. IT'S NEW BRUNSWICK. IT SNOWED IN JUNE ONCE. I WAS THERE.",
		"THE STUDS ARE FOR GRIP. I GRIP YEAR-ROUND."],
}
## What people say as they hand over a proof. Same words whether it's real or not.
const PROOF_LINES := {
	"bos": ["I BOUGHT IT THURSDAY. HERE'S THE BILL OF SALE. SIGNED AND DATED. MY HANDWRITING'S A CRIME, BUT IT'S A LEGAL ONE.",
		"I JUST BOUGHT IT. HERE. BILL OF SALE. HE WROTE IT ON THE HOOD."],
	"permit": ["THE REGISTRY GAVE ME A TEMPORARY. HERE. IT'S GOT A HOLOGRAM. WELL, A STICKER.", "TEMPORARY PERMIT. THE LINEUP WAS TWO HOURS, I'M NOT GOING BACK."],
	"glovebox": ["OH WAIT. GLOVEBOX. HANG ON.", "...THE PINK CARD? IT'S PINK? WHY DIDN'T ANYBODY SAY IT WAS PINK."],
	"door_inv": ["BODY SHOP DID THE DOOR. I'VE GOT THE BILL RIGHT HERE. WORST $900 I EVER SPENT.", "NEW DOOR. HERE'S THE INVOICE. THEY EVEN MATCHED THE PAINT. ALMOST."],
	"cert": ["HERE'S THE STRUCTURAL. THE GUY IN SALISBURY SIGNED IT ON HIS TAILGATE.", "STRUCTURAL CERTIFICATE. FRAME'S STRAIGHTER THAN ME."],
	"exempt": ["MY DOCTOR SIGNED THE MINISTRY FORM. FOR MY EYES. HERE.", "MEDICAL EXEMPTION. IT'S IN THE VISOR. EVERYTHING'S IN THE VISOR."],
	"notice": ["OH, THERE'S A NOTE IN THE BOX. NEW NUMBER, SAME PART, IT SAYS.", "THE SUPPLIER CHANGED THE NUMBER. HERE'S THE PAPER. THEY CHANGE IT EVERY TIME THEY GET A NEW INTERN."],
}
## The courier at the window, by who brings it.
const COURIER_SAYS := {
	"fundy": ["FUNDY PARTS. ONE BOX FOR COVINGTON. SIGN HERE. AND HERE. AND... NO, JUST HERE.", "MORNING. RODNEY PACKED THIS ONE. I'D CHECK IT. I'D CHECK ANYTHING RODNEY PACKED.",
		"BOX FOR YOU. IT RATTLES. RODNEY SAYS IT'S SUPPOSED TO RATTLE."],
	"parcel": ["PARCEL FROM THE STATES. THERE'S A CUSTOMS FORM. THERE'S ALWAYS A CUSTOMS FORM.", "ROCKBOTTOM. IT CROSSED THE BORDER TWICE. DON'T ASK ME HOW. I JUST DRIVE.",
		"SIGNATURE FOR THE BOX FROM OHIO. IT'S BEEN ON A JOURNEY."],
}
## Fundy's driver remembers the last box you signed for, or didn't.
const COURIER_AGAIN := {
	"DENIED": "THE RIGHT ONE THIS TIME. RODNEY TRIPLE-CHECKED. RODNEY'S NEVER CHECKED ANYTHING ONCE.",
	"DENIED_WRONG": "YOU SENT BACK A GOOD BOX LAST TIME. RODNEY TOOK IT PERSONALLY. RODNEY TAKES EVERYTHING PERSONALLY.",
	"APPROVED_WRONG": "HOW'D THAT LAST PART FIT? RODNEY WANTS TO KNOW. RODNEY KNOWS.",
	"REPORT": "THE COPS WENT THROUGH RODNEY'S WHOLE USED SHELF. RODNEY'S ON A BREAK. A LONG ONE. THIS ONE'S NEW. I CHECKED.",
}
## Inspector Hachey: what he says when he puts a file on the desk, and when you ASK him things.
const HACHEY_SAYS := ["GOOD MORNING. DON'T MIND ME. I'M JUST GOING TO STAND HERE AND BE THE MINISTRY.",
	"ONE OF YOURS. I'VE COVERED THE STAMP WITH MY THUMB. STAMP IT AGAIN, PLEASE. TAKE YOUR TIME. I'M TIMING IT.",
	"A FILE FROM YOUR CABINET. YOU'VE SEEN IT BEFORE. HAVE ANOTHER LOOK.",
	"I PICKED THIS ONE AT RANDOM. THE MINISTRY'S RANDOM IS VERY CAREFUL."]
## ...and when the file he pulls is a box: the Ministry doesn't care what's in the parts room, only that you agree with yourself.
const HACHEY_BOX := "ONE OF YOUR BOXES. THE MINISTRY DOESN'T CARE WHAT'S IN YOUR PARTS ROOM. THE MINISTRY CARES IF YOU SIGN THE SAME WAY TWICE."
const HACHEY_LOCAL := "THE ONE ON MAIN. I TAKE IT BLACK. I WRITE DOWN HOW LONG THE LINE IS."
const HACHEY_ASK := "I'M NOT THE CUSTOMER, MR. COVINGTON. I'M THE MINISTRY. THE FILE IS THE CUSTOMER."
const MASK_LINES := ["IT'S A COSTUME. IT'S HALLOWEEN, BUD.", "OH. RIGHT. FORGOT I HAD IT ON. IT'S VERY COMFORTABLE.", "...FINE. BUT YOU'RE NO FUN."]
## Undercover people don't know local things. Ask them anything and they stumble.
const STING_ASK := ["THE, UH... TIM BURTONS? THE ONE ON MOUNTAIN STREET. AVENUE. MOUNTAIN... PLACE?",
	"WHICH TIM BURTONS? THE... BIG ONE? BY THE... MALL. THE MALL ONE.", "MY BUDDY FROM THE PORT, HE SAYS YOU'RE GOOD. BIG GUY. YOU KNOW. HIM."]

var rng := RandomNumberGenerator.new()
var bolo: Array = []                    # [{plate, vin, car}] on the police list this week

func _init(start_seed := 506) -> void:
	rng.seed = start_seed

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

## Is a date inside a season that runs [month, day] to [month, day] (across New Year's)?
static func in_season(d: Array, season: Array) -> bool:
	var md: int = int(d[1]) * 100 + int(d[2])
	var from: int = int(season[0][0]) * 100 + int(season[0][1])
	var to: int = int(season[1][0]) * 100 + int(season[1][1])
	if from > to: return md >= from or md <= to
	return md >= from and md <= to

## "NOV 27" for a verdict.
static func month_day(d: Array) -> String:
	return "%s %d" % [MONTHS[d[1] - 1], d[2]]

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

## A supplier's part number: Fundy's are FP-, RockBottom's are longer and American.
func part_no(states: bool) -> String:
	if states: return "RB%d-%04d" % [100 + rng.randi() % 900, rng.randi() % 10000]
	return "FP-%05d" % (rng.randi() % 100000)

## The part number one digit over: the wrong part, in the right box.
func part_tweak(p: String) -> String:
	var at: Array[int] = []
	for i in p.length(): if p[i] >= "0" and p[i] <= "9": at.append(i)
	var i: int = at[at.size() - 1 - rng.randi() % mini(3, at.size())]
	var d := int(p[i])
	return p.substr(0, i) + str((d + 1 + rng.randi() % 9) % 10) + p.substr(i + 1)

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

## A part's serial number: two letters and six digits.
func serial() -> String:
	var L := "ABCDEFGHJKLMNPRSTUVWXYZ"
	return "%s%s-%06d" % [L[rng.randi() % L.length()], L[rng.randi() % L.length()], rng.randi() % 1000000]

## The serial one digit off: what an invoice says when somebody's been at it with a pen.
func serial_tweak(sn: String) -> String:
	var i := 3 + rng.randi() % 6
	var d := int(sn[i])
	return sn.substr(0, i) + str((d + 1 + rng.randi() % 9) % 10) + sn.substr(i + 1)

## The stolen list for the week (seeded so the wall and the cars agree): cars by plate and VIN,
## and the parts the police are after, by serial (they only count from week 6). The serials
## come from their own generator, so the cars on the list don't change when the parts join it.
func make_bolo(n := 6) -> void:
	bolo = []
	for i in n:
		var m := model()
		bolo.append({ "plate": plate(), "vin": vin(), "car": "%s %s" % [m.make, m.model] })
	var h := CounterRules.new(hash(String(bolo[0].vin) if n > 0 else "hot"))
	for i in HOT_LISTED:
		# the first two are the kind Fundy's used shelf sells too
		var k := h.rng.randi() % (USED_PARTS.size() if i < 2 else HOT_PARTS.size())
		bolo.append({ "serial": h.serial(), "part": HOT_PARTS[k][2], "kind": k })

## The cars on a stolen list, and the parts.
static func bolo_cars(list: Array) -> Array:
	return list.filter(func(b): return (b as Dictionary).has("plate"))

static func bolo_parts(list: Array) -> Array:
	return list.filter(func(b): return (b as Dictionary).has("serial"))

## Is this serial on the list?
static func listed(sn: String, list: Array) -> bool:
	return sn != "" and list.any(func(b): return String((b as Dictionary).get("serial", "")) == sn)

## A customer for `day`. `want` forces a problem (for tests and scripts; "clean" forces none);
## otherwise it's rolled. `fixed` pins parts of them down: person, car (a partial dict, or
## "catalogue": id), request, and "plain" (no random extras: no exceptions, transfers or masks).
func customer(day: int, want := "", fixed := {}) -> Dictionary:
	if COURIER_PROBLEMS.has(want): return courier(day, want)
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
			"surface": float(car.rust_look) > 0.05, "tint": 80, "db": 85, "hole": false },
		"work": { "name": name, "plate": car.plate, "car": desc },
		"flags": [], "napkin": "", "docs": ["work", "reg", "licence", "insurance", "sheet"], "hidden": [],
		"ask": {}, "exception": {}, "says": "", "clue": {},
	}
	for i in 4: c.sheet.tread.append(snappedf(2.4 + rng.randf() * 6.0, 0.1))
	for i in 2: c.sheet.pads.append(snappedf(3.5 + rng.randf() * 7.0, 0.1))
	# Gus's light meter and sound meter: factory glass, a tired but legal muffler
	c.sheet.tint = 72 + rng.randi() % 17
	c.sheet.db = 78 + rng.randi() % 15
	# clean variety once the rules know about it: cars from away, and rebuilt salvage with its certificate
	if not plain:
		if rule_active("oop", day) and rng.randf() < 0.15: _transfer(c, day)
		if rule_active("salvage", day) and not want in ["salvage_no_cert", "title_washed"] and rng.randf() < 0.1:
			_brand_salvage(c)
			c.cert = { "vin": car.vin, "by": INSPECTORS[rng.randi() % INSPECTORS.size()], "issued": date_add(t, -(3 + rng.randi() % 200)) }
			c.docs.append("cert")
		# a part put on somewhere else, invoice and all (and nothing wrong with it)
		if rule_active("hot", day) and rng.randf() < 0.14: _new_part(c, day)
	# what the ownership says it's for, and the tires Gus finds on it, once winter tires matter
	if rule_active("winter", day): _winterize(c, plain)
	# what's wrong with it (only problems the rules check today, so nothing is unfair)
	var options: Array = []
	for pr in PROBLEM_RULE:
		if possible(pr, day) and not COURIER_PROBLEMS.has(pr): options.append(pr)
	var prob := "" if want == "clean" else want
	if want == "" and rng.randf() < 0.45 and not options.is_empty():
		prob = options[rng.randi() % options.size()]
	if prob != "": _inject(c, prob, day)
	elif want == "" and rng.randf() < 0.18: excuse(c, day)
	if not plain and rule_active("masks", day) and rng.randf() < 0.35: c.mask = MASKS[rng.randi() % MASKS.size()]
	_ensure_history(c, day)
	_settle(c, day)
	return c

## Can this problem turn up today? Its rule is on the wall, and (for the seasonal ones) it's
## the season for it: in late November studs are legal, so nobody's out of stud season.
static func possible(prob: String, day: int) -> bool:
	if not rule_active(String(PROBLEM_RULE.get(prob, "")), day): return false
	if prob == "studs_out_of_season": return not in_season(today(day), STUD_SEASON)
	if prob == "no_winter_tires": return in_season(today(day), WINTER_SEASON)
	return true

## Winter: what the ownership says the car's for, and the tires on it. Somebody in for their
## winters is on the other ones.
func _winterize(c: Dictionary, plain: bool) -> void:
	var body := String(c.car.get("body", "sedan"))
	var u := rng.randf()
	var use := "PRIVATE"
	if not plain:
		if body in ["pickup", "van", "boxtruck"]: use = "COMMERCIAL" if u < 0.35 else "PRIVATE"
		elif u < 0.08: use = "TAXI"
		elif u < 0.16: use = "RIDESHARE"
	c.reg.use = use
	var t := rng.randf()
	if c.request == "WINTER TIRES ON": c.sheet.tires = "SUMMER" if t < 0.2 else "ALL-SEASON"
	else: c.sheet.tires = "WINTER" if t < 0.45 else ("STUDDED" if t < 0.6 else ("ALL-SEASON" if t < 0.93 else "SUMMER"))

## A working car up for its sticker in the winter season without winter tires on.
static func winter_short(c: Dictionary, day: int) -> bool:
	if not rule_active("winter", day) or not c.has("reg") or not WINTER_USES.has(String(c.reg.get("use", "PRIVATE"))): return false
	return in_season(today(day), WINTER_SEASON) and not String(c.sheet.get("tires", "WINTER")) in ["WINTER", "STUDDED"]

## Studs on the car, out of stud season.
static func studs_out(c: Dictionary, day: int) -> bool:
	return rule_active("studs", day) and String(c.get("sheet", {}).get("tires", "")) == "STUDDED" and not in_season(today(day), STUD_SEASON)

## Anybody up for a sticker has their tires sorted, unless that's the problem they came with.
## (Run after anything that might have turned the job into an inspection.)
static func _settle(c: Dictionary, day: int) -> void:
	if not c.has("sheet") or not c.sheet.has("tires") or not INSPECTIONS.has(c.request): return
	var flags: Array = c.get("flags", [])
	if winter_short(c, day) and not flags.has("no_winter_tires"): c.sheet.tires = "WINTER"
	if studs_out(c, day) and not flags.has("studs_out_of_season"): c.sheet.tires = "WINTER"

## A part put on somewhere else, and the invoice that came with it. Gus reads the serial off
## the part itself, onto his sheet.
func _new_part(c: Dictionary, day: int) -> void:
	var hp: Array = HOT_PARTS[rng.randi() % HOT_PARTS.size()]
	var sn := serial()
	c.sheet.part = hp[1]
	c.sheet.serial = sn
	c.invoice = { "seller": PART_SELLERS[rng.randi() % PART_SELLERS.size()], "part": hp[0], "serial": sn,
		"date": date_add(today(day), -(2 + rng.randi() % 90)), "paid": 60 + rng.randi() % 40 * 25 }
	if not c.docs.has("invoice"): c.docs.append("invoice")

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

## Branded salvage, here and (if it came from away) on the old ownership too: the brand
## followed it honestly.
func _brand_salvage(c: Dictionary) -> void:
	c.reg.brand = "SALVAGE"
	if c.has("old_reg"): c.old_reg.brand = "SALVAGE"

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
	if (prob == "stolen" and bolo.is_empty()) or (prob == "hot_part" and bolo_parts(bolo).is_empty()): make_bolo()
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
			var cars := bolo_cars(bolo)
			var b: Dictionary = cars[rng.randi() % cars.size()]
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
			_brand_salvage(c)
			c.erase("cert")
			c.docs.erase("cert")
			if rng.randf() < 0.4: _proof(c, "salvage_no_cert", day, "bad")
		"title_washed":
			if String(c.reg.prev) == "": _transfer(c, day)
			c.old_reg.brand = "SALVAGE"
			c.reg.brand = "CLEAN"
			c.request = "FULL INSPECTION"
		"tint":
			c.request = inspection_job(c)
			c.sheet.tint = _dark()
			if rng.randf() < 0.4: _proof(c, "tint", day, "bad")
		"noise":
			c.request = inspection_job(c)
			# too loud, or a hole (a hole can be quiet enough and still fail)
			if rng.randf() < 0.5: c.sheet.db = NOISE_MAX + 1 + rng.randi() % 16
			else: c.sheet.hole = true
		"hot_part":
			# a part off somebody else's car: its serial's on the list. The invoice says so too,
			# or (somebody's been at it with a pen) one digit different
			var parts := bolo_parts(bolo)
			var b: Dictionary = parts[rng.randi() % parts.size()]
			_new_part(c, day)
			var hp: Array = HOT_PARTS[int(b.kind)]
			c.sheet.part = hp[1]
			c.sheet.serial = b.serial
			c.invoice.part = hp[0]
			c.invoice.serial = b.serial
			if rng.randf() < 0.4:
				var fake := serial_tweak(String(b.serial))
				while listed(fake, bolo): fake = serial_tweak(String(b.serial))
				c.invoice.serial = fake
		"no_winter_tires":
			c.request = inspection_job(c)
			var body := String(c.car.get("body", "sedan"))
			c.reg.use = "COMMERCIAL" if body in ["pickup", "van", "boxtruck"] else ["TAXI", "RIDESHARE"][rng.randi() % 2]
			c.sheet.tires = "SUMMER" if rng.randf() < 0.2 else "ALL-SEASON"
		"studs_out_of_season":
			c.request = inspection_job(c)
			c.sheet.tires = "STUDDED"
	c.flags.append(prob)

## Film on the front windows: 5% to 65% of the light gets through.
func _dark() -> int:
	return 5 + (rng.randi() % 13) * 5

## The proof a customer pulls out when you ASK: `how` is "valid", "bad" (forged or out of
## date), or for a bill of sale "bos_expired"/"bos_forged". It stays hidden until asked for.
func _proof(c: Dictionary, base: String, day: int, how: String) -> void:
	var t := today(day)
	var doc: String = PROOFS[base][0]
	var dash: String = String(c.sheet.vin) if c.has("sheet") else ""
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
		"exempt":
			# a medical exemption is the driver's, for one car, and it runs out
			var d := { "name": c.licence.name, "vin": dash, "dr": DOCTORS[rng.randi() % DOCTORS.size()], "expires": date_add(t, 20 + rng.randi() % 700) }
			if bad:
				match rng.randi() % 3:
					0: d.expires = date_add(t, -(1 + rng.randi() % 200))
					1: d.vin = vin_tweak(dash)
					2: d.name = other_name(String(c.licence.name))
			c.exempt = d
		"notice":
			# the supplier's notice: the number we ordered is now the number on the box
			var d := { "supplier": c.slip.supplier, "was": c.order.no, "now": c.slip.no, "dated": date_add(t, -(2 + rng.randi() % 60)) }
			if bad:
				if rng.randf() < 0.5: d.was = part_tweak(String(c.order.no))
				else: d.now = part_tweak(String(c.slip.no))
			c.notice = d
	if not c.hidden.has(doc): c.hidden.append(doc)
	c.exception = { "problem": base, "doc": doc, "valid": not bad }
	var lines: Array = PROOF_LINES[doc]
	c.ask[base] = { "line": lines[rng.randi() % lines.size()], "doc": doc }

## Something on the papers looks wrong, but the customer has the proof that makes it fine
## (in a pocket until you ASK). Picks a discrepancy whose exception is in the rules today.
func excuse(c: Dictionary, day: int, base := "") -> bool:
	var bases: Array = []
	for b in PROOFS:
		# a box's papers can only explain a box; a car's, a car
		if COURIER_PROBLEMS.has(b) != c.has("slip"): continue
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
			_brand_salvage(c)
			c.erase("cert")
			c.docs.erase("cert")
		"tint":
			c.request = inspection_job(c)
			c.sheet.tint = _dark()
		"wrong_part": c.slip.no = part_tweak(String(c.order.no))
	_proof(c, base, day, "valid")
	if c.has("sheet"):
		_ensure_history(c, day)
		_settle(c, day)
	return true

## Thursday on: one of the Familia's cars. Something's wrong with it, and there's a napkin.
func familia(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch" if rng.randf() < 0.5 else "plate_mismatch", { "plain": true })
	c.kind = "familia"
	c.napkin = ["DOM SAYS MAKE IT CLEAN. FAMILY PRICE. -S", "NEW NUMBERS ON THIS ONE. NO PAPERWORK. -S", "YOU KNOW WHAT TO DO. DOM SAYS HI. -S"][rng.randi() % 3]
	c.request = "\"DETAILING\""
	c.erase("history")
	c.docs.erase("history")
	return c

## Someone who isn't who he says he is asks for the thing you shouldn't do.
func sting(day: int) -> Dictionary:
	var c := customer(day, "vin_mismatch", { "plain": true })
	c.kind = "sting"
	c.napkin = "HEARD YOU DO NEW NUMBERS. $800 CASH. NO QUESTIONS. -A FRIEND OF A FRIEND"
	c.request = "\"DETAILING\""
	c.erase("history")
	c.docs.erase("history")
	return c

## Week 5 on: the courier at the window with a box for the bay. Our order (printed off the
## counter PC) against their packing slip, and from the States a customs form too. `want`
## forces a problem ("clean" for none). `fam`: the Familia's box, addressed to Bay 3.
func courier(day: int, want := "", fam := false) -> Dictionary:
	var t := today(day)
	var states := want == "customs_value" or (want != "ship_to" and want != "hot_part" and not fam and rng.randf() < 0.35)
	var who: Dictionary = COURIERS["parcel" if states else "fundy"]
	var p := person()
	p.merge((who.person as Dictionary).duplicate(true), true)
	var m := model(String(who.car))
	var part: Array = ORDER_PARTS[rng.randi() % ORDER_PARTS.size()]
	# from week 6 some of it comes off Fundy's used shelf, with a serial on it (a stolen one, if
	# that's what's wanted: off the list, in a kind the shelf sells)
	var used := -1
	var hot: Dictionary = {}
	if want == "hot_part":
		if bolo_parts(bolo).is_empty(): make_bolo()
		var ps := bolo_parts(bolo).filter(func(b): return int(b.kind) < USED_PARTS.size())
		hot = ps[rng.randi() % ps.size()]
		used = int(hot.kind)
	elif not states and not fam and rule_active("hot", day) and rng.randf() < 0.3:
		used = rng.randi() % USED_PARTS.size()
	if used >= 0: part = USED_PARTS[used]
	var no := part_no(states)
	var paid := roundi(float(part[1]) * (0.72 if states else 0.92)) + rng.randi() % 12
	var c := {
		"person": p, "kind": "familia" if fam else "courier", "courier": "parcel" if states else "fundy", "request": "DELIVERY",
		"car": { "make": m.make, "model": m.model, "year": m.year, "paint": String(who.paint), "len": m.len, "wid": m.wid,
			"wheelbase": m.wheelbase, "body": m.body, "side_body": m.side_body, "class": m["class"], "cat": m.id, "quirk": "",
			"rust_look": 0.0, "plate": plate(), "vin": vin(), "odo": 40000 + rng.randi() % 200000 },
		"face_shown": p.face, "mask": "",
		"order": { "supplier": String(who.supplier), "no": no, "part": part[0], "job": part[2], "for": LAST[rng.randi() % LAST.size()],
			"paid": paid, "shipto": SHOP },
		"slip": { "supplier": String(who.supplier), "no": no, "part": part[0], "qty": 1, "shipto": SHOP,
			"shipped": date_add(t, -(1 + rng.randi() % 5)) },
		"flags": [], "napkin": "", "docs": ["order", "slip"], "hidden": [], "ask": {}, "exception": {}, "says": "", "clue": {},
	}
	if states:
		c.customs = { "from": "ROCKBOTTOMAUTO.COM, OHIO", "contents": part[0], "value": paid }
		c.docs.append("customs")
	if used >= 0: c.slip.serial = serial()
	var prob := "" if want == "clean" else want
	if fam: prob = "ship_to"
	elif want == "" and rng.randf() < 0.4:
		var opts: Array = ["wrong_part", "wrong_part", "ship_to"]
		if states: opts.append("customs_value")
		# (whether it rolls doesn't depend on what's on the list, so a box rebuilds the same without it)
		if used >= 0: opts.append("hot_part")
		prob = opts[rng.randi() % opts.size()]
	match prob:
		"wrong_part":
			c.slip.no = part_tweak(no)
			if rng.randf() < 0.35: _proof(c, "wrong_part", day, "bad")
		"customs_value":
			# declared low to skip the duty (or high, by a tired clerk in Ohio)
			c.customs.value = maxi(15, floori(paid / (2.0 + rng.randi() % 3))) if rng.randf() < 0.75 else paid * 2 + rng.randi() % 40
		"ship_to": c.slip.shipto = FAMILIA_SHIPTO if fam else WRONG_SHIPTO[rng.randi() % WRONG_SHIPTO.size()]
		"hot_part":
			# the serial off the box is one the police are after (if none of that kind is listed,
			# the box is one of the kind that is)
			if hot.is_empty():
				if bolo_parts(bolo).is_empty(): make_bolo()
				var ps := bolo_parts(bolo).filter(func(b): return int(b.kind) == used)
				if ps.is_empty(): ps = bolo_parts(bolo).filter(func(b): return int(b.kind) < USED_PARTS.size())
				hot = ps[rng.randi() % ps.size()]
				var u: Array = USED_PARTS[int(hot.kind)]
				c.order.part = u[0]
				c.order.job = u[2]
				c.slip.part = u[0]
			c.slip.serial = String(hot.serial)
	if prob != "": c.flags.append(prob)
	elif want == "" and rng.randf() < 0.15: excuse(c, day, "wrong_part")
	var lines: Array = COURIER_SAYS[c.courier]
	c.says = lines[rng.randi() % lines.size()]
	if fam:
		# it came on Fundy's truck, on the shop's account: Fundy's driver doesn't want to know
		c.courier = "familia"
		c.says = "BOX FOR BAY 3. ON YOUR ACCOUNT. SAL SAID YOU'D KNOW. I DON'T KNOW. I DON'T WANT TO KNOW."
		c.napkin = "DON'T OPEN IT. DON'T SHAKE IT. BAY 3. DOM SAYS THANK YOU. -S"
	elif not states:
		# Fundy's driver remembers the last box you signed for, or didn't
		var last := DeskRegulars.outcome("courier_fundy", day)
		if COURIER_AGAIN.has(last): c.says = COURIER_AGAIN[last]
	return c

## Stings come every other Friday while the heat is up (and the first Friday, to say hello).
static func sting_day(day: int, heat: int) -> bool:
	return day == 4 or (posmod(day, 7) == 4 and week_of(day) % 2 == 1 and heat >= 30)

## The day at the window: who arrives when. [{t (minutes since 8:00), c}], in order.
## `extra` is a story step's own customers (ids from data/story_customers.json, or specs).
## The regulars come on their own days, and the people you turned away come back (both read
## DeskBook, so what you stamped before decides who's in the line and what they bring).
func shift(day: int, heat := 0, extra: Array = [], chapter := 1) -> Array:
	var out: Array = []
	var lo := 40.0 - minf(10.0, day * 0.5)
	var hi := 75.0 - minf(14.0, day * 0.7)
	var t := 4.0 + rng.randf() * 14.0
	while t < 555.0:
		out.append({ "t": t, "c": walk_in(day) })
		t += rng.randf_range(lo, hi)
	var specs: Array = []
	for id in scheduled(chapter, day): specs.append(story_spec(id))
	for e in extra: specs.append(story_spec(e) if e is String else e)
	specs.append_array(DeskRegulars.visits(day))
	specs.append_array(DeskRegulars.returns(day))
	# a scripted Familia car takes the Thursday napkin's place; from week six it's sometimes a box
	var fam_scripted := specs.any(func(s): return String((s as Dictionary).get("kind", "")) == "familia")
	if (posmod(day, 7) == 3 or day == 4) and not fam_scripted:
		var box := rule_active("noise", day) and rng.randf() < 0.5
		out.append({ "t": 60.0 + rng.randf() * 360.0, "c": courier(day, "", true) if box else familia(day) })
	if sting_day(day, heat): out.append({ "t": 120.0 + rng.randf() * 300.0, "c": sting(day) })
	if rule_active("courier", day) and rng.randf() < 0.8: out.append({ "t": 50.0 + rng.randf() * 340.0, "c": box(day) })
	for s in specs:
		if (s as Dictionary).is_empty(): continue
		out.append({ "t": arrive_of(s), "c": scripted(s, day) })
	out.sort_custom(func(a, b): return a.t < b.t)
	return out

## A walk-in off the street, made from a seed of their own so their file can be rebuilt later
## (the audit pulls it; if you turned them away, they come back).
func walk_in(day: int, want := "") -> Dictionary:
	var s := rng.randi()
	var r := CounterRules.new(s)
	r.bolo = bolo
	var c := r.customer(day, want)
	c.seed = s
	if want != "": c.want = want
	return c

## The courier with a box, made from a seed of its own like a walk-in, so its file rebuilds.
func box(day: int, want := "") -> Dictionary:
	var s := rng.randi()
	var r := CounterRules.new(s)
	r.bolo = bolo
	var c := r.courier(day, want)
	c.seed = s
	if want != "": c.want = want
	return c

## A file's papers as they were on the day: a walk-in or a box from its seed, a regular's visit
## from who they are and what Leo had stamped on them before, somebody back about an old file
## from that file. {} if it doesn't rebuild (scripted customers, the Familia, the sting). A
## stolen car's plate, or a stolen part's serial, came off that week's list, so those don't
## rebuild the same; nobody asks.
static func rebuild(rec: Dictionary) -> Dictionary:
	var day := int(rec.get("day", 0))
	var kind := String(rec.get("kind", ""))
	var id := String(rec.get("id", ""))
	if kind == "regular" and id != "" and rec.has("visit"):
		return CounterRules.new().scripted(DeskRegulars.spec(id, int(rec.visit), String(rec.get("last", ""))), day)
	if kind == "regular" and int(rec.get("of", 0)) > 0 and int(rec.get("seed", -1)) < 0:
		var orig := DeskBook.file_no(int(rec.of))
		if orig.is_empty(): return {}
		var o: Dictionary = orig.duplicate(true)
		o.erase("back")
		var spec := DeskRegulars.back_spec(o)
		return {} if spec.is_empty() else CounterRules.new().scripted(spec, day)
	var s := int(rec.get("seed", -1))
	if s < 0: return {}
	var want := String(rec.get("want", ""))
	var c := CounterRules.new(s).courier(day, want) if kind == "courier" else CounterRules.new(s).customer(day, want)
	c.seed = s
	if want != "": c.want = want
	return c

## When Inspector Hachey pulls a file in audit week (minutes since 8:00).
static func audit_times(day: int) -> Array:
	return AUDIT_TIMES.duplicate() if rule_active("audit", day) else []

## Can Hachey pull this file? A walk-in, a regular's visit, somebody back about an old file or
## a courier's box: approved (signed for) or denied (sent back), judged from papers alone, not
## pulled before, not from the future, and one that rebuilds.
static func auditable(rec: Dictionary, day: int) -> bool:
	if not String(rec.get("kind", "")) in ["regular", "courier"] or rec.get("pulled", false): return false
	if not String(rec.get("stamp", "")) in ["APPROVED", "DENIED"] or int(rec.day) > day: return false
	for p in rec.get("probs", []): if UNAUDITABLE.has(String(p)): return false
	if int(rec.get("seed", -1)) >= 0: return true
	if rec.has("visit") and String(rec.get("id", "")) != "": return true
	return int(rec.get("of", 0)) > 0 and not DeskBook.file_no(int(rec.of)).is_empty()

## The file he pulls from the cabinet: an older one if there is one (today's if that's all
## there is). {} if there's nothing to pull.
static func pull(files: Array, day: int, r: RandomNumberGenerator) -> Dictionary:
	var older: Array = files.filter(func(f): return auditable(f, day) and int(f.day) < day)
	var pool: Array = older if not older.is_empty() else files.filter(func(f): return auditable(f, day))
	if pool.is_empty(): return {}
	return pool[r.randi() % pool.size()]

## The file on the desk: every paper the customer had that day (out of their pockets too),
## the stamp under Hachey's thumb, and Hachey at the window.
static func audit_customer(rec: Dictionary) -> Dictionary:
	var c := rebuild(rec)
	if c.is_empty(): return {}
	for h in c.hidden: if not c.docs.has(h): c.docs.append(h)
	c.hidden = []
	c.mask = ""
	c.kind = "audit"
	# the Ministry's at the window now: the customer's own lines and story left with them
	c.erase("script")
	c.regular = ""
	c.ask = {}
	c.clue = {}
	c.napkin = ""
	c.audit = { "no": int(rec.no), "day": int(rec.day), "stamp": String(rec.stamp), "correct": bool(rec.correct), "who": String(rec.get("who", "")) }
	c.window = HACHEY.duplicate(true)
	var box := c.has("slip")
	c.says = "%s %04d. %s. %s" % ["PACKING SLIP" if box else "WORK ORDER", int(rec.no), date_str(today(int(rec.day))),
		HACHEY_BOX if box else HACHEY_SAYS[int(rec.no) % HACHEY_SAYS.size()]]
	c.erase("seed")
	return c

## Hachey in the line before he's pulled anything: the Ministry's car in the lot.
func hachey(day: int) -> Dictionary:
	var m := model(String(HACHEY_CAR.catalogue))
	return { "kind": "audit", "request": "AUDIT", "person": HACHEY.duplicate(true),
		"car": { "make": m.make, "model": m.model, "year": m.year, "paint": String(HACHEY_CAR.paint), "len": m.len, "wid": m.wid,
			"wheelbase": m.wheelbase, "side_body": m.side_body, "plate": "GOV %03d" % (100 + day) } }

## What the shop loses when somebody drives off at six (deliveries and the Ministry cost nothing).
static func walked_pay(c: Dictionary) -> int:
	if c.kind in ["audit", "courier"]: return 0
	return int(PAY.get(c.request, 80))

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

## A scripted customer: the same papers every time (seeded by the id, or "seed"), their own
## lines, and what each stamp does to the story. See data/story_customers.json for the keys.
func scripted(spec: Dictionary, day: int) -> Dictionary:
	var r := CounterRules.new(hash(String(spec.get("seed", spec.get("id", "story")))))
	r.bolo = bolo
	# a member of the cast wears their own face (JSON numbers come in as floats)
	var who: Dictionary = (spec.get("person", {}) as Dictionary).duplicate()
	var cast: Dictionary = StoryScript.CAST.get(String(spec.get("cast", "")), {})
	if not cast.is_empty():
		if not who.has("face"): who.face = int(cast.seed)
		if not who.has("fem"): who.fem = int(cast.female)
		if not who.has("dob"): who.dob = [YEAR - int(cast.age), 6, 15]
	for k in ["face", "fem"]: if who.has(k): who[k] = int(who[k])
	if who.has("dob"): who.dob = (who.dob as Array).map(func(x): return int(x))
	var fcar: Dictionary = (spec.get("car", {}) as Dictionary).duplicate()
	if fcar.has("year"): fcar.year = int(fcar.year)
	var fixed := { "person": who, "car": fcar, "plain": true }
	if spec.has("request"): fixed.request = spec.request
	var prob := String(spec.get("problem", "clean"))
	var c := r.customer(day, prob if prob != "" else "clean", fixed)
	if spec.get("from_away", false):
		r._transfer(c, day)
		r._ensure_history(c, day)
	if spec.has("excuse"): r.excuse(c, day, String(spec.excuse))
	# a proof that won't hold up, for a problem whose proof keeps its name when it's bad (a bad
	# bill of sale is bos_forged, and a bad pink card is expired insurance: ask for those instead)
	if spec.get("forged", false) and PROOFS.has(prob) and not prob in ["name_mismatch", "no_insurance"]: r._proof(c, prob, day, "bad")
	for k in ["reg", "licence", "insurance", "sheet", "work", "invoice"]:
		if spec.has("papers") and (spec.papers as Dictionary).has(k) and c.has(k): (c[k] as Dictionary).merge(spec.papers[k], true)
	_settle(c, day)
	c.kind = String(spec.get("kind", "story"))
	c.script = spec
	c.regular = String(spec.get("regular", ""))
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
	if doc == "notice": return d.was == c.order.no and d.now == c.slip.no and date_cmp(d.dated, t) <= 0
	var dash: String = c.sheet.vin
	match doc:
		"bos": return bos_check(c, day) == ""
		"permit", "glovebox": return d.vin == dash and date_cmp(d.from, t) <= 0 and date_cmp(d.to, t) >= 0
		"door_inv": return d.vin == dash and d.door == c.sheet.door and date_cmp(d.date, t) <= 0
		"cert": return d.vin == dash and date_cmp(d.issued, t) <= 0
		"exempt": return d.vin == dash and d.name == c.licence.name and date_cmp(d.expires, t) >= 0
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
## the stolen list on the wall (cars, and from week 6 part serials), the person's face.
static func find_problems(c: Dictionary, day: int, bolo_list: Array) -> Array:
	if c.has("slip"): return _box_problems(c, day, bolo_list)
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
			if b.get("plate", "") == c.car.plate or b.get("vin", "") == dash: out.append("stolen")
	if rule_active("hot", day) and listed(String(sheet.get("serial", "")), bolo_list): out.append("hot_part")
	if rule_active("photo", day) and c.face_shown != c.licence.face: out.append("photo_mismatch")
	if rule_active("odo", day) and odo_rolled(c): out.append("odo_rollback")
	if rule_active("oop", day) and String(reg.get("prev", "")) != "" and c.request != "FULL INSPECTION": out.append("out_of_province")
	if rule_active("salvage", day):
		if String(reg.get("brand", "CLEAN")) == "SALVAGE" and not proof_ok(c, "salvage_no_cert", day): out.append("salvage_no_cert")
		if c.has("old_reg") and String(c.old_reg.brand) == "SALVAGE" and String(reg.get("brand", "CLEAN")) != "SALVAGE": out.append("title_washed")
	if rule_active("tint", day) and INSPECTIONS.has(c.request) and int(sheet.get("tint", 100)) < TINT_MIN and not proof_ok(c, "tint", day):
		out.append("tint")
	if rule_active("noise", day) and INSPECTIONS.has(c.request) and (bool(sheet.get("hole", false)) or int(sheet.get("db", 0)) > NOISE_MAX):
		out.append("noise")
	if INSPECTIONS.has(c.request):
		if winter_short(c, day): out.append("no_winter_tires")
		if studs_out(c, day): out.append("studs_out_of_season")
	return out

## A courier's box against our order: who it's for, the part number, what customs says we
## paid, and (a used part) whether its serial's on the stolen list.
static func _box_problems(c: Dictionary, day: int, bolo_list: Array) -> Array:
	var out: Array = []
	if not rule_active("courier", day): return out
	var o: Dictionary = c.order
	var s: Dictionary = c.slip
	if s.shipto != o.shipto: out.append("ship_to")
	if s.no != o.no and not proof_ok(c, "wrong_part", day): out.append("wrong_part")
	if c.has("customs") and int(c.customs.value) != int(o.paid): out.append("customs_value")
	if rule_active("hot", day) and listed(String(s.get("serial", "")), bolo_list): out.append("hot_part")
	return out

# ------------------------------------------------------------------ the desk: what Leo can put side by side

## Every paper that can land on the desk.
const DOC_TITLES := { "work": "WORK ORDER - COVINGTON AUTO", "reg": "VEHICLE REGISTRATION", "licence": "DRIVER'S LICENCE",
	"insurance": "PROOF OF INSURANCE", "glovebox": "PINK CARD (FROM THE GLOVEBOX)", "sheet": "GUS'S SHEET (READ OFF THE CAR)",
	"history": "SERVICE HISTORY", "old_reg": "OLD OWNERSHIP", "bos": "BILL OF SALE", "permit": "TEMPORARY PERMIT",
	"door_inv": "BODY SHOP INVOICE", "cert": "STRUCTURAL CERTIFICATE", "napkin": "", "letter": "",
	"exempt": "TINT EXEMPTION - MINISTRY", "order": "OUR ORDER - PARTSWEB 98", "slip": "PACKING SLIP",
	"customs": "CUSTOMS DECLARATION", "notice": "SUPERSESSION NOTICE", "invoice": "PARTS INVOICE" }
## What Leo can ASK about, in two or three words.
const TOPIC_LABEL := {
	"vin_mismatch": "THE VIN", "plate_mismatch": "THE PLATE", "fails_inspection": "WHY IT FAILS", "expired_reg": "THE REGISTRATION",
	"no_insurance": "THE INSURANCE", "insurance_expired": "THE INSURANCE DATES", "insurance_vin": "THE INSURANCE VIN",
	"name_mismatch": "WHOSE CAR IT IS", "stolen": "THE STOLEN LIST", "photo_mismatch": "THE PHOTO", "odo_rollback": "THE ODOMETER",
	"bos_expired": "THE SALE DATE", "bos_forged": "THE BILL OF SALE", "vin_door_mismatch": "THE DOOR", "out_of_province": "WHERE IT'S FROM",
	"salvage_no_cert": "THE SALVAGE BRAND", "title_washed": "THE OLD BRAND", "mask": "THE MASK", "local": "SMALL TALK",
	"tint": "THE TINT", "noise": "THE EXHAUST", "wrong_part": "THE PART NUMBER", "customs_value": "THE DECLARED VALUE", "ship_to": "WHO IT'S FOR",
	"hot_part": "THE SERIAL NUMBER", "no_winter_tires": "THE TIRES", "studs_out_of_season": "THE STUDS",
}
## Which papers a mismatch points at, by the kind of fact and the paper that's wrong.
const _TOPIC_BY_DOC := {
	"vin": { "reg": "vin_mismatch", "insurance": "insurance_vin", "glovebox": "insurance_vin", "bos": "bos_forged",
		"permit": "expired_reg", "cert": "salvage_no_cert", "door_inv": "vin_door_mismatch", "sheet": "vin_door_mismatch", "exempt": "tint" },
	"plate": { "reg": "plate_mismatch", "work": "plate_mismatch", "permit": "expired_reg" },
	"name": { "bos": "bos_forged", "exempt": "tint" }, "owner": { "bos": "bos_forged" },
	"part": { "order": "wrong_part", "slip": "wrong_part", "notice": "wrong_part" },
	"paid": { "order": "customs_value", "customs": "customs_value" },
	"shipto": { "order": "ship_to", "slip": "ship_to" },
	"serial": { "invoice": "hot_part", "sheet": "hot_part", "slip": "hot_part" },
}
const _DATE_TOPIC := { "reg": "expired_reg", "permit": "expired_reg", "insurance": "insurance_expired", "glovebox": "insurance_expired",
	"bos": "bos_expired", "cert": "salvage_no_cert", "door_inv": "vin_door_mismatch", "exempt": "tint", "notice": "wrong_part" }

## The rows of a paper: [label, text, fact key ("" if there's nothing to compare), value].
## Fact keys: name, owner, plate, vin, car, job, expiry, start, sold, dated, brand, prov, odo, km,
## measure, photo, serial, use. The papers only grow rows once a rule makes them matter.
static func doc_rows(c: Dictionary, id: String, day: int) -> Array:
	var raw = c.get(id, {})
	var d: Dictionary = raw if raw is Dictionary else {}
	match id:
		"work":
			var rows := [["NAME", c.work.name, "name", c.work.name], ["PLATE", c.work.plate, "plate", c.work.plate],
				["CAR", c.work.car, "car", c.work.car], ["WORK", c.request, "job", c.request]]
			# a pulled file carries its own date: that's "today" for everything on it
			if c.has("audit"): rows.append(["FILED", date_str(today(int(c.audit.day))), "today", today(int(c.audit.day))])
			return rows
		"reg":
			var rows := [["OWNER", d.owner, "owner", d.owner], ["ADDRESS", d.address, "", null], ["CAR", d.car, "car", d.car],
				["PLATE", d.plate, "plate", d.plate], ["VIN", d.vin, "vin", d.vin], ["EXPIRES", date_str(d.expires), "expiry", d.expires]]
			if rule_active("oop", day): rows.append(["PREV.", "NEW BRUNSWICK" if String(d.get("prev", "")) == "" else "TRANSFER FROM " + String(d.prev), "prov", String(d.get("prev", ""))])
			if rule_active("salvage", day): rows.append(["BRAND", d.get("brand", "CLEAN"), "brand", d.get("brand", "CLEAN")])
			if rule_active("winter", day): rows.append(["USE", d.get("use", "PRIVATE"), "use", d.get("use", "PRIVATE")])
			return rows
		"licence": return [["NAME", d.name, "name", d.name], ["BORN", date_str(d.dob), "", null], ["ADDR", d.address, "", null],
			["NO.", d.number, "", null], ["EXPIRES", date_str(d.expires), "expiry", d.expires]]
		"insurance", "glovebox": return [["INSURED", d.holder, "name", d.holder], ["COMPANY", d.insurer, "", null],
			["POLICY", d.policy, "", null], ["VIN", d.vin, "vin", d.vin], ["FROM", date_str(d.from), "start", d.from], ["TO", date_str(d.to), "expiry", d.to]]
		"sheet":
			var treads: Array = d.tread
			var pd: Array = d.pads
			var rows := [["VIN", d.vin, "vin", d.vin]]
			if rule_active("door", day): rows.append(["DOOR", d.door, "vin", d.door])
			rows.append_array([["ODO", "%d KM" % d.odo, "odo", d.odo],
				["TREAD", "FL %.1f FR %.1f RL %.1f RR %.1f" % [treads[0], treads[1], treads[2], treads[3]], "measure", { "kind": "tread", "v": treads }],
				["PADS", "FRONT %.1f  REAR %.1f" % [pd[0], pd[1]], "measure", { "kind": "pads", "v": pd }],
				["LIGHTS", "ALL WORKING" if d.lights else "LEFT TAIL OUT", "measure", { "kind": "lights", "v": d.lights }],
				["RUST", ("SURFACE ONLY" if d.get("surface", false) else "NONE") if not d.rust else "THROUGH THE ROCKER", "measure", { "kind": "rust", "v": d.rust }]])
			# the light meter and the sound meter join the sheet with their rules
			if rule_active("tint", day):
				var vlt := int(d.get("tint", 80))
				rows.append(["TINT", "FRONT SIDES %d%% LIGHT" % vlt, "measure", { "kind": "tint", "v": vlt }])
			if rule_active("noise", day):
				var db := int(d.get("db", 85))
				var hole: bool = d.get("hole", false)
				rows.append(["EXHAUST", "%d DB AT 3000, %s" % [db, "A HOLE" if hole else "NO HOLES"], "measure", { "kind": "noise", "v": { "db": db, "hole": hole } }])
			# a part that went on somewhere else: its serial, off the part
			if rule_active("hot", day) and d.has("serial"): rows.append(["PART", "%s %s" % [d.part, d.serial], "serial", d.serial])
			if rule_active("winter", day):
				var tires := String(d.get("tires", "WINTER"))
				rows.append(["TIRES", TIRE_TEXT.get(tires, tires), "measure", { "kind": "tires", "v": tires }])
			return rows
		"history":
			var rows: Array = []
			var hist: Array = c.get("history", [])
			for i in hist.size():
				var e: Dictionary = hist[i]
				rows.append([date_str(e.date), "%-18s %7d KM" % [e.shop, e.km], "km", { "km": int(e.km), "date": e.date }])
			return rows
		"old_reg": return [["PROVINCE", d.prov, "", null], ["OWNER", d.owner, "owner", d.owner], ["VIN", d.vin, "vin", d.vin],
			["PLATE", d.plate + " (" + String(d.prov) + ")", "", null], ["BRAND", d.brand, "brand", d.brand], ["ISSUED", date_str(d.issued), "dated", d.issued]]
		"bos": return [["SELLER", d.seller, "owner", d.seller], ["BUYER", d.buyer, "name", d.buyer], ["VIN", d.vin, "vin", d.vin],
			["PRICE", "$%d" % int(d.price), "", null], ["SOLD", date_str(d.sold), "sold", d.sold]]
		"permit": return [["PLATE", d.plate, "plate", d.plate], ["VIN", d.vin, "vin", d.vin],
			["FROM", date_str(d.from), "start", d.from], ["TO", date_str(d.to), "expiry", d.to]]
		"door_inv": return [["SHOP", d.shop, "", null], ["CAR VIN", d.vin, "vin", d.vin], ["DOOR", d.door, "vin", d.door],
			["DATE", date_str(d.date), "dated", d.date], ["AMOUNT", "$%d" % int(d.amount), "", null]]
		"cert": return [["VIN", d.vin, "vin", d.vin], ["SIGNED", d.by, "", null], ["ISSUED", date_str(d.issued), "dated", d.issued]]
		"exempt": return [["DRIVER", d.name, "name", d.name], ["VIN", d.vin, "vin", d.vin], ["SIGNED", d.dr, "", null],
			["EXPIRES", date_str(d.expires), "expiry", d.expires]]
		"order": return [["FROM", d.supplier, "", null], ["PART NO.", d.no, "part", d.no], ["PART", d.part, "", null],
			["FOR", "%s - %s" % [String(d.job).replace(" LIGHT", ""), d["for"]], "", null], ["PAID", "$%d" % int(d.paid), "paid", int(d.paid)], ["SHIP TO", d.shipto, "shipto", d.shipto]]
		"slip":
			var rows := [["SHIP TO", d.shipto, "shipto", d.shipto], ["PART NO.", d.no, "part", d.no], ["PART", d.part, "", null],
				["QTY", str(int(d.qty)), "", null], ["SHIPPED", date_str(d.shipped), "", null]]
			if d.has("serial"): rows.append(["SERIAL", d.serial, "serial", d.serial])
			if c.has("audit"): rows.append(["FILED", date_str(today(int(c.audit.day))), "today", today(int(c.audit.day))])
			return rows
		"customs": return [["FROM", d.from, "", null], ["CONTENTS", d.contents, "", null], ["DECLARED", "$%d" % int(d.value), "paid", int(d.value)]]
		"notice": return [["WAS NO.", d.was, "part", d.was], ["NOW NO.", d.now, "part", d.now], ["DATED", date_str(d.dated), "dated", d.dated]]
		"invoice": return [["SOLD BY", d.seller, "", null], ["PART", d.part, "", null], ["SERIAL", d.serial, "serial", d.serial],
			["DATE", date_str(d.date), "", null], ["PAID", "$%d" % int(d.paid), "", null]]
	return []

## A door's VIN (on Gus's sheet or on the body shop's invoice), not the car's.
static func _is_door(f: Dictionary) -> bool:
	return f.get("key", "") == "vin" and String(f.get("row", "")) == "DOOR"

## What a fact should say if its paper is honest: the car itself is the truth for VINs and
## plates, the licence for the customer's name, the ownership for the owner's.
static func _should_be(c: Dictionary, f: Dictionary) -> Variant:
	match String(f.key):
		"vin": return c.sheet.door if _is_door(f) and f.get("doc", "") == "door_inv" else c.sheet.vin
		"plate": return c.car.plate
		"name": return c.licence.name
		"owner": return c.reg.owner
		"serial": return c.sheet.get("serial", f.val) if c.has("sheet") else f.val
	return f.val

## Which paper is lying in a mismatch, as an ASK topic.
static func _culprit(c: Dictionary, a: Dictionary, b: Dictionary) -> String:
	var k: String = a.key
	if k == "brand": return "title_washed"
	if _is_door(a) != _is_door(b): return "vin_door_mismatch"
	var by: Dictionary = _TOPIC_BY_DOC.get(k, {})
	for f in [a, b]:
		if f.val != _should_be(c, f): return String(by.get(String(f.get("doc", "")), "name_mismatch" if k in ["name", "owner"] else ""))
	for f in [a, b]:
		var tp := String(by.get(String(f.get("doc", "")), ""))
		if tp != "": return tp
	return ""

## Leo reads two facts side by side: [what he concludes, good (true, false or null), the ASK
## topic a red verdict opens ("" if none)]. Facts are {key, val, doc, row}; the rules on the
## wall are {key: "rule", val: rule id}.
static func compare(c: Dictionary, day: int, bolo_list: Array, a: Dictionary, b: Dictionary) -> Array:
	var ka: String = a.key
	var kb: String = b.key
	var pair := [ka, kb]
	var t := today(day)
	if ka == kb and ka in ["name", "owner", "plate", "vin", "car", "brand", "part", "paid", "shipto", "serial"]:
		if a.val == b.val: return ["MATCH", true, ""]
		return ["MISMATCH", false, _culprit(c, a, b)]
	if pair.has("owner") and pair.has("name"):
		if a.get("doc", "") == "bos" and b.get("doc", "") == "bos": return ["SELLER AND BUYER", null, ""]
		if "exempt" in [a.get("doc", ""), b.get("doc", "")]:
			return ["SAME PERSON", true, ""] if a.val == b.val else ["NOT THE DRIVER ON THE EXEMPTION", false, "tint"]
		return ["SAME PERSON", true, ""] if a.val == b.val else ["NOT THE OWNER", false, "name_mismatch"]
	if ka == "km" and kb == "km":
		var early: Dictionary = a.val if date_cmp(a.val.date, b.val.date) <= 0 else b.val
		var late: Dictionary = b.val if early == a.val else a.val
		if int(late.km) < int(early.km): return ["THE MILEAGE WENT DOWN", false, "odo_rollback"]
		return ["THE MILEAGE WENT UP", true, ""]
	if ka == kb: return ["NOTHING TO COMPARE", null, ""]
	var other: Dictionary = b if ka == "today" or ka == "rule" else a
	var fixed: Dictionary = a if other == b else b
	if fixed.key == "today":
		var d = other.val
		var topic := String(_DATE_TOPIC.get(String(other.get("doc", "")), ""))
		match String(other.key):
			"expiry": return ["EXPIRED " + date_str(d), false, topic] if date_cmp(d, t) < 0 else ["STILL VALID", true, ""]
			"start": return ["NOT IN EFFECT YET", false, topic] if date_cmp(d, t) > 0 else ["IN EFFECT", true, ""]
			"dated": return ["DATED IN THE FUTURE", false, topic] if date_cmp(d, t) > 0 else ["DATED BEFORE TODAY", true, ""]
			"sold": return _sold(d, t)
			"measure":
				# the tires against the calendar: is it stud season?
				if String((d as Dictionary).get("kind", "")) == "tires" and rule_active("studs", day): return _stud_verdict(c, day)
	if pair.has("photo") and pair.has("person"):
		if c.has("audit"): return ["THAT'S HACHEY. THE CUSTOMER'S LONG GONE", null, ""]
		if String(c.get("mask", "")) != "": return ["CAN'T SEE A FACE UNDER THAT MASK", null, "mask"]
		return ["SAME PERSON", true, ""] if a.val == b.val else ["THAT'S NOT THEM", false, "photo_mismatch"]
	if pair.has("bolo") and (pair.has("plate") or pair.has("vin") or pair.has("serial")):
		var x: Dictionary = a if ka != "bolo" else b
		if x.key == "serial": return _hot_verdict(day, bolo_list, String(x.val))
		for e in bolo_list:
			if e.get(x.key, "") == x.val: return ["ON THE STOLEN LIST", false, "stolen"]
		return ["NOT ON THE LIST", true, ""]
	if pair.has("odo") and pair.has("km"):
		var km: Dictionary = a.val if ka == "km" else b.val
		var odo: int = int(b.val if ka == "km" else a.val)
		if int(km.km) > odo: return ["%d KM BEFORE, %d KM NOW" % [int(km.km), odo], false, "odo_rollback"]
		return ["UNDER TODAY'S ODOMETER", true, ""]
	if pair.has("job") and pair.has("prov"):
		return _from_away(c)
	if fixed.key == "rule": return _against_rule(c, day, bolo_list, String(fixed.val), other)
	return ["NOTHING TO COMPARE", null, ""]

## A part's serial against the stolen list.
static func _hot_verdict(day: int, bolo_list: Array, sn: String) -> Array:
	if not rule_active("hot", day): return ["NO PARTS ON THE LIST YET", null, ""]
	return ["SERIAL ON THE STOLEN LIST", false, "hot_part"] if listed(sn, bolo_list) else ["SERIAL NOT ON THE LIST", true, ""]

## What the ownership says the car's for, and its tires, against the winter rule.
static func _winter_verdict(c: Dictionary, day: int) -> Array:
	var use := String(c.reg.get("use", "PRIVATE"))
	var tires := String(c.sheet.get("tires", "WINTER"))
	var on := "%s ON %s" % [use, TIRE_TEXT.get(tires, tires)]
	if not WINTER_USES.has(use): return ["PRIVATE: ITS TIRES, ITS BUSINESS", true, ""]
	if not in_season(today(day), WINTER_SEASON): return ["%s, OUT OF WINTER" % use, true, ""]
	if tires in ["WINTER", "STUDDED"]: return [on, true, ""]
	if not INSPECTIONS.has(c.request): return [on + ". NOT A STICKER JOB", null, ""]
	return [on + ": NO STICKER", false, "no_winter_tires"]

## Studs against the calendar.
static func _stud_verdict(c: Dictionary, day: int) -> Array:
	var t := today(day)
	if String(c.sheet.get("tires", "")) != "STUDDED": return ["NO STUDS", true, ""]
	if in_season(t, STUD_SEASON): return ["STUDS ON %s: IN SEASON" % month_day(t), true, ""]
	if not INSPECTIONS.has(c.request): return ["STUDS ON %s. NOT A STICKER JOB" % month_day(t), null, ""]
	return ["STUDS ON %s: OUT OF SEASON" % month_day(t), false, "studs_out_of_season"]

static func _sold(d: Array, t: Array) -> Array:
	var n := days_between(d, t)
	if n < 0: return ["SOLD IN THE FUTURE", false, "bos_forged"]
	if n > 10: return ["SOLD %d DAYS AGO: OVER 10" % n, false, "bos_expired"]
	return ["SOLD %d DAYS AGO" % n, true, ""]

static func _from_away(c: Dictionary) -> Array:
	if String(c.reg.get("prev", "")) == "": return ["REGISTERED HERE", true, ""]
	if c.request == "FULL INSPECTION": return ["FROM AWAY: FULL INSPECTION BOOKED", true, ""]
	return ["FROM AWAY: NEEDS THE FULL INSPECTION", false, "out_of_province"]

## A fact held up against a rule on the wall.
static func _against_rule(c: Dictionary, day: int, bolo_list: Array, rule: String, f: Dictionary) -> Array:
	var k: String = f.key
	match rule:
		"inspect":
			if k != "measure": return ["NOTHING TO COMPARE", null, ""]
			var m: Dictionary = f.val
			match m.kind:
				"tread":
					for x in m.v: if x < 1.6: return ["%.1f MM TREAD: FAILS" % x, false, "fails_inspection"]
					return ["TREAD PASSES", true, ""]
				"pads":
					for x in m.v: if x < 3.0: return ["%.1f MM PADS: FAILS" % x, false, "fails_inspection"]
					return ["PADS PASS", true, ""]
				"lights": return ["LIGHTS WORK", true, ""] if m.v else ["A LIGHT IS OUT: FAILS", false, "fails_inspection"]
				"rust": return ["RUSTED THROUGH: FAILS", false, "fails_inspection"] if m.v else ["NO RUST-THROUGH", true, ""]
		"odo":
			if k in ["odo", "km"]: return ["THE ODOMETER WENT BACKWARDS", false, "odo_rollback"] if odo_rolled(c) else ["READINGS ONLY GO UP", true, ""]
		"bos":
			if k == "sold": return _sold(f.val, today(day))
		"door":
			if _is_door(f) and f.get("doc", "") == "sheet": return ["DOOR MATCHES THE DASH", true, ""] if f.val == c.sheet.vin else ["NOT THIS CAR'S DOOR", false, "vin_door_mismatch"]
		"oop":
			if k in ["prov", "job"]: return _from_away(c)
		"reg_valid":
			if k == "expiry" and f.get("doc", "") == "reg":
				return ["EXPIRED: NO SERVICE", false, "expired_reg"] if date_cmp(f.val, today(day)) < 0 else ["REGISTRATION VALID", true, ""]
		"salvage":
			if k == "brand":
				if String(f.val) != "SALVAGE":
					if c.has("old_reg") and String(c.old_reg.brand) == "SALVAGE": return ["CLEAN HERE. WHAT ABOUT THE OLD ONE?", null, ""]
					return ["CLEAN TITLE", true, ""]
				if c.has("cert") and not c.get("hidden", []).has("cert"): return ["SALVAGE: CHECK THE CERTIFICATE", null, ""]
				return ["SALVAGE, NO STRUCTURAL CERTIFICATE", false, "salvage_no_cert"]
		"masks":
			if k == "person": return ["MASK ON: ASK", null, "mask"] if String(c.get("mask", "")) != "" else ["NO MASK", true, ""]
		"tint":
			if k == "measure" and String(f.val.kind) == "tint":
				var vlt := int(f.val.v)
				return ["%d%% LIGHT: TOO DARK" % vlt, false, "tint"] if vlt < TINT_MIN else ["%d%% LIGHT: CLEAR ENOUGH" % vlt, true, ""]
		"noise":
			if k == "measure" and String(f.val.kind) == "noise":
				var m: Dictionary = f.val.v
				if m.hole: return ["A HOLE IN THE EXHAUST: FAILS", false, "noise"]
				return ["%d DB AT 3000: OVER 95" % int(m.db), false, "noise"] if int(m.db) > NOISE_MAX else ["%d DB, NO HOLES: PASSES" % int(m.db), true, ""]
		"courier":
			if k == "shipto": return ["ADDRESSED TO US", true, ""] if String(f.val) == SHOP else ["NOT ADDRESSED TO US", false, "ship_to"]
		"hot":
			if k == "serial": return _hot_verdict(day, bolo_list, String(f.val))
		"winter":
			if k == "use" or (k == "measure" and String(f.val.kind) == "tires"): return _winter_verdict(c, day)
		"studs":
			if k == "measure" and String(f.val.kind) == "tires": return _stud_verdict(c, day)
	return ["NOTHING TO COMPARE", null, ""]

## Everything on the desk and the wall as facts (no positions): the papers (with the ones
## still in the customer's pocket when `pockets`), the calendar, the face, the plate on the
## car, the stolen list and the rules. What the tests compare in pairs.
static func desk_facts(c: Dictionary, day: int, pockets := true) -> Array:
	var out: Array = []
	var ids: Array = c.docs.duplicate()
	if pockets:
		for h in c.get("hidden", []): if not ids.has(h): ids.append(h)
	for id in ids:
		for row in doc_rows(c, id, day):
			if row[2] != "": out.append({ "key": row[2], "val": row[3], "doc": id, "row": row[0] })
		if id == "licence": out.append({ "key": "photo", "val": c.licence.face, "doc": id, "row": "PHOTO" })
	out.append({ "key": "today", "val": today(day), "doc": "" })
	# a pulled file has no customer at the window and no car in the bay
	if not c.has("audit"):
		out.append({ "key": "person", "val": c.face_shown, "doc": "" })
		out.append({ "key": "plate", "val": c.car.plate, "doc": "car", "row": "PLATE" })
	if rule_active("bolo", day): out.append({ "key": "bolo", "val": 0, "doc": "" })
	for r in rules_for(day): out.append({ "key": "rule", "val": r.id, "doc": "" })
	return out

## What Leo can ask without proving anything first: where the insurance card is, what's
## under the mask, and small talk (which undercover people are bad at).
static func standing_topics(c: Dictionary, day: int) -> Array:
	var out: Array = []
	if String(c.get("mask", "")) != "": out.append("mask")
	var shown_glovebox: bool = c.has("glovebox") and not c.get("hidden", []).has("glovebox")
	if c.has("reg") and rule_active("insured", day) and (c.get("insurance", {}) as Dictionary).is_empty() and not shown_glovebox: out.append("no_insurance")
	out.append("local")
	return out

## What a customer says when you ASK about `topic`: {line, doc (handed over), unmask, clue}.
static func answer(c: Dictionary, topic: String) -> Dictionary:
	var h := absi(int(c.person.face) + hash(topic))
	if topic == "mask": return { "line": MASK_LINES[h % MASK_LINES.size()], "unmask": true }
	if c.get("ask", {}).has(topic): return c.ask[topic]
	match c.kind:
		"sting": return { "line": STING_ASK[h % STING_ASK.size()] }
		"familia": return { "line": "DOM SAYS YOU DON'T ASK. HE SAYS IT NICE, BUT HE SAYS IT." }
		"audit": return { "line": HACHEY_LOCAL if topic == "local" else HACHEY_ASK }
	if topic == "local": return { "line": LOCAL_LINES[h % LOCAL_LINES.size()] }
	# the courier has his own excuses for a box
	var pool: Array = EXCUSES.get(topic + "_box", EXCUSES.get(topic, [])) if c.has("slip") else EXCUSES.get(topic, [])
	if pool.is_empty(): return { "line": "I DON'T KNOW ANYTHING ABOUT THAT. I JUST DRIVE IT." }
	return { "line": pool[h % pool.size()] }

## What a citation costs: the first WARNINGS a shift are free (police matters never are).
static func fine_for(c: Dictionary, warnings_used: int) -> int:
	if c.kind == "sting": return 2000
	return 0 if warnings_used < WARNINGS else FINE

## What a stamp's citation costs on the day: {fine, warning}. A warning is logged and free.
static func penalty(c: Dictionary, r: Dictionary, warnings_used: int) -> Dictionary:
	if String(r.get("citation", "")) == "": return { "fine": 0, "warning": false }
	if c.kind == "sting" or r.get("police", false): return { "fine": 2000 if c.kind == "sting" else FINE * 2, "warning": false }
	var f := fine_for(c, warnings_used)
	return { "fine": f, "warning": f == 0 }

## What the stamp did. Returns { money, dirty, citation, heat, trust, review, line, correct, flags }
static func judge(c: Dictionary, stamp: String, day: int, bolo_list: Array) -> Dictionary:
	var r := _judge(c, stamp, day, bolo_list)
	r.flags = []
	var spec: Dictionary = c.get("script", {})
	if spec.is_empty(): return r
	# a scripted customer: their own lines and what the story remembers
	if not spec.get("quiet", false): r.flags.append("desk_%s_%s" % [spec.get("id", "story"), stamp.to_lower()])
	var o: Dictionary = spec.get("outcomes", {}).get(stamp, {})
	for k in ["line", "citation"]: if o.has(k): r[k] = String(o[k])
	for k in ["money", "dirty", "heat", "trust", "review"]: if o.has(k): r[k] = int(o[k])
	if o.has("correct"): r.correct = bool(o.correct)
	for f in o.get("flags", []): r.flags.append(String(f))
	return r

static func _judge(c: Dictionary, stamp: String, day: int, bolo_list: Array) -> Dictionary:
	var r := { "money": 0, "dirty": 0, "citation": "", "heat": 0, "trust": 0, "review": 0, "line": "", "correct": true, "fee": 0 }
	if c.kind == "audit": return _judge_audit(c, stamp, r)
	var probs := find_problems(c, day, bolo_list)
	if c.kind == "courier": return _judge_box(c, stamp, probs, r)
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
	if probs.has("stolen") or probs.has("title_washed") or probs.has("hot_part"):
		# a stolen car, a stolen part on a car (both the police's), or a washed title (the Ministry's)
		var hot := probs.has("stolen") or probs.has("hot_part")
		var part := not probs.has("stolen") and probs.has("hot_part")
		match stamp:
			"REPORT":
				r.heat = -5
				r.line = "The police tow it. A cop says thanks without looking up." if hot else "The Ministry takes the file. Somebody in another province is about to have a very bad week."
				if part: r.line = "Constable Tremblay takes a statement and the serial. The part's evidence now. So, for a while, is the car."
			"APPROVED":
				r.correct = false
				r.police = hot
				r.heat = 25 if hot else 10
				r.citation = "YOU WORKED ON A STOLEN CAR. IT WAS ON THE LIST ON YOUR WALL" if hot else "STICKERED A WASHED SALVAGE TITLE. THE BRAND WAS ON THE OLD OWNERSHIP"
				if part: r.citation = "PUT A STOLEN PART BACK ON THE ROAD. ITS SERIAL WAS ON THE LIST ON YOUR WALL"
			"DENIED":
				r.correct = false
				if hot:
					r.citation = "STOLEN CAR SENT BACK ON THE ROAD. IT WAS ON THE LIST: REPORT IT"
					if part: r.citation = "SENT A STOLEN PART BACK ON THE ROAD. ITS SERIAL WAS ON THE LIST: REPORT IT"
					r.police = true
				else: r.line = "\"Fine. I'll go to Lindsay's. She passes anything with a pulse.\" Somebody should've reported that title."
			"WRENCH":
				r.correct = false
				r.heat = 40
				r.citation = "OFF-BOOKS WORK ON A STOLEN CAR" if hot else "OFF-BOOKS WORK ON A WASHED SALVAGE CAR"
				if part: r.citation = "OFF-BOOKS WORK ON A CAR WITH A STOLEN PART ON IT"
		return r
	match stamp:
		"APPROVED":
			if bad:
				r.correct = false
				r.citation = _citation_for(probs[0])
				r.line = ["They drive off happy. The Ministry won't be.", "\"Pleasure doing business.\" It was not, legally speaking.",
					"Gus watches them go and doesn't say anything. Loudly."][int(c.person.face) % 3]
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

## Signing for a box (APPROVED) or sending it back (DENIED). A right box lets the job that was
## waiting on it go ahead; a wrong one costs the shop, not the licence: the Ministry doesn't
## care what's in your parts room.
static func _judge_box(c: Dictionary, stamp: String, probs: Array, r: Dictionary) -> Dictionary:
	var o: Dictionary = c.order
	# ...but the police care what's in it: a stolen part is theirs, never a free warning
	if probs.has("hot_part"):
		match stamp:
			"REPORT":
				r.heat = -5
				r.line = "Constable Tremblay takes the box, and the driver's statement. It's mostly about Rodney."
			"APPROVED":
				r.correct = false
				r.police = true
				r.heat = 15
				r.citation = "SIGNED FOR A STOLEN PART. ITS SERIAL WAS ON THE LIST ON YOUR WALL"
				r.line = "Gus carries it to the bay. A week later a cruiser parks across the street, and somebody asks Gus where he gets his used parts."
			"DENIED":
				r.correct = false
				r.police = true
				r.citation = "SENT A STOLEN PART BACK OUT IN THE VAN. ITS SERIAL WAS ON THE LIST: REPORT IT"
				r.line = "The box goes back in the van. The next shop on the route signs for it."
			"WRENCH":
				r.correct = false
				r.heat = 30
				r.citation = "A STOLEN PART, OFF THE BOOKS, IN BAY 3"
				r.line = "The courier looks at Bay 3. Then at the box. Then at you. \"I didn't see that. I don't see anything. I'm a van.\""
		return r
	match stamp:
		"APPROVED":
			if probs.is_empty():
				r.money = int(PAY.get(String(o.job), 0))
				r.line = "Gus carries the box to the bay like it's a casserole. The %s for %s goes ahead." % [String(o.job).to_lower(), String(o["for"])]
			else:
				r.correct = false
				match String(probs[0]):
					"ship_to": r.line = "%s calls about their box. Gus drives it over on his lunch and comes back quieter." % String(c.slip.shipto)
					"customs_value":
						r.fee = CUSTOMS_PENALTY
						r.line = "The broker's letter comes Thursday: a false declaration, signed for by you. The penalty's on the shop."
					_:
						r.fee = maxi(5, roundi(float(o.paid) * RESTOCK))
						r.line = "It's the wrong part. It doesn't fit. Fundy takes it back, minus 15% for the trouble."
		"DENIED":
			if probs.is_empty():
				r.correct = false
				r.review = -1
				r.line = "The %s waiting on that box waits another day. So does the customer. Loudly, online." % String(o.job).to_lower()
			else:
				r.line = ["\"Fair enough.\" The box goes back in the van. The right one's on tomorrow's truck.", "\"I'll tell Rodney.\" The box goes back in the van. Rodney will not be told."][int(c.person.face) % 2]
		"REPORT":
			r.correct = false
			r.heat = 3
			r.review = -1
			r.line = "The police come to look at a box of %s. They look at it hard. It stays a box of %s." % [String(o.part).to_lower(), String(o.part).to_lower()]
		"WRENCH":
			r.correct = false
			r.line = "The courier looks at Bay 3. Then at you. \"I just need a signature, man.\""
	return r

## Audit week: Hachey covers your stamp with his thumb and you stamp the file again. The
## Ministry wants a station that agrees with itself.
##
## The same wrong stamp twice is consistent, and the bible only cites disagreeing: no new
## citation (the first one, if there was one, stands), but it goes in his report.
static func _judge_audit(c: Dictionary, stamp: String, r: Dictionary) -> Dictionary:
	var was := String(c.audit.stamp)
	var box := c.has("slip")
	var word := { "APPROVED": "SIGNED FOR" if box else "APPROVED", "DENIED": "REFUSED" if box else "DENIED", "REPORT": "REPORTED", "WRENCH": "BAY 3" }
	if stamp == was:
		var after := "He ticks a box." if c.audit.correct else "He writes something else down too, and doesn't say what."
		r.line = "He lifts his thumb: %s. \"Consistent.\" %s" % [word.get(was, was), after]
		r.wrong_twice = not c.audit.correct
		return r
	r.correct = false
	r.citation = "AUDIT: YOUR OWN %s SAYS %s. TODAY YOU SAY %s. THE MINISTRY WOULD LIKE YOU TO PICK ONE" % ["PACKING SLIP" if box else "WORK ORDER", word.get(was, was), word.get(stamp, stamp)]
	r.line = "He lifts his thumb. Your own stamp says %s. He looks at it for a long time." % word.get(was, was)
	if not c.audit.correct: r.line = "He lifts his thumb. Your own stamp says %s. \"So it was wrong then, or it's wrong now.\" He writes down both." % word.get(was, was)
	if stamp == "WRENCH":
		r.heat = 10
		r.line = "You just offered the Ministry Bay 3. Hachey writes that down in full."
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
		"tint": return "PASSED FRONT WINDOWS THAT DON'T LET 70% OF THE LIGHT THROUGH"
		"noise": return "PASSED AN EXHAUST WITH A HOLE IN IT, OR OVER 95 DB"
		"no_winter_tires": return "STICKERED A TAXI, RIDESHARE OR COMMERCIAL VEHICLE WITHOUT WINTER TIRES"
		"studs_out_of_season": return "STICKERED A CAR ON STUDS OUT OF SEASON"
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
		"tint": return "\"I'll peel it. With my teeth, probably.\""
		"noise": return "\"It's not loud. You're quiet.\" The car argues the point all the way out of the lot."
		"no_winter_tires": return "\"I'll put 'em on November thirty-first.\" There isn't one."
		"studs_out_of_season": return "\"They're my lucky studs.\" They're out of season. So's the luck."
	return "They leave, muttering."
