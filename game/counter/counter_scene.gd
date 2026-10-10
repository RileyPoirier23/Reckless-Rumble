## The counter at Covington Auto, Papers, Please style: a shift on the clock, a line in the lot.
##
## The shift runs 8:00 to 18:00 on the wall clock (ten real minutes). Customers queue in the lot
## (you see them through the bay door), and whoever's next leans on the horn if you take more
## than an hour and a half with one. At six the lot empties and the money drives off with it.
##
## Everything is drawn by code in _draw(). Papers lie on the desk and can be dragged.
## INSPECT: pick one fact, then another, and Leo compares them (a VIN against a VIN, a date
## against the calendar, a photo against the face, a plate against the stolen list, a reading
## or a paper against a rule in the binder). A red verdict puts a question on the ASK list: the
## customer explains, lies, or pulls the paper out of a pocket that makes it fine (if that paper
## checks out too). Then stamp the work order. Two Ministry warnings a shift, then citations.
## Pick what somebody said, then Leo's notebook, and he writes it down. The sticker log keeps
## every sticker the station has issued.
##
## Every stamp goes in the filing cabinet (DeskBook.files): the regulars and the people Leo
## turned away come back knowing what he stamped (regulars.gd). From week 5 the courier brings
## the bay's parts (sign for the box, or send it back); from week 6 the police list has stolen
## part serials on it too; in week 7 Inspector Hachey pulls two old files a day (a walk-in, a
## regular, a box), covers the stamp with his thumb and watches Leo stamp them again; week 8 is
## winter tires and studs. Constable Tremblay's stolen list is new every week, and every file
## keeps the one it was read against, so a file Hachey pulls is read against its own week's.
##
## OVERTIME (free play, after week 8 on the week picker, or KEEP WORKING at the end of the run):
## the job after the run, one day after another from Monday, December 2, through the winter
## into spring and on. Every rule stays up, so the dates on them bite: winters on working cars
## till April 30, studs out of season from May 1. The record (days kept, the streak of right
## calls, the best streak) and the book ride along in DeskBook's overtime file, saved at
## clock-out.
##
## The room makes a few quiet sounds (DeskAudio): the horn from the lot, the stamp, paper, the
## wall clock, and the till when somebody takes money off the shop.
##
## GUS'S TOOL DRAWER (off the day-end sheet): a tread gauge, a date wheel, a loupe and a UV lamp,
## paid out of the till (in the story, out of Leo's own money). Each one reads one kind of fact
## when Leo picks it twice (DeskTools); none of them stamps anything. The RELAXED CLOCK (on the
## morning brief, next to the week picker) runs the same day half as long again in real time.
##
## Mouse; keyboard alone (arrows move a cursor, Space clicks and drags); or a controller (left
## stick moves the cursor, D-pad left/right jumps to the next thing, A clicks and drags, Y
## inspects, X asks, B cancels, LB/RB turn the binder's tabs, D-pad up/down the books).
class_name CounterScene
extends Node2D

const BOOTH := Rect2(0, 0, 150, 360)
const WINDOW := Rect2(150, 0, 320, 112)
const LOT := Rect2(150, 0, 320, 32)
const DESK := Rect2(150, 112, 320, 196)
const TRAY := Rect2(150, 308, 320, 52)
const WALL := Rect2(470, 0, 170, 360)
const BOARD := Rect2(474, 50, 162, 182)          # the bulletin, or the binder
const BOOK := Rect2(156, 116, 308, 188)           # a book open on the desk
const NOTEBOOK_ICON := Rect2(476, 318, 77, 38)
const LOG_ICON := Rect2(557, 318, 77, 38)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const RED := Color("e0402e")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const BLUE := Color("4a7ab8")
const PAPER_INK := Color("2a2420")
const PAPER_DIM := Color("7a7064")

const BUTTONS := [
	{ "id": "INSPECT", "label": "INSPECT", "key": "inspect", "col": Color("c8b070") },
	{ "id": "APPROVED", "label": "APPROVE", "key": "desk_approve", "col": Color("4a8a3a") },
	{ "id": "DENIED", "label": "DENY", "key": "desk_deny", "col": Color("a8342a") },
	{ "id": "REPORT", "label": "REPORT", "key": "desk_report", "col": Color("3a5a8a") },
	{ "id": "WRENCH", "label": "BAY 3", "key": "desk_wrench", "col": Color("3a3438") },
]

## The desk's own buttons, on top of the game's (Controls): keyboard and controller.
const ACTIONS := {
	"desk_click": [KEY_SPACE, KEY_ENTER, JOY_BUTTON_A],
	"desk_ask": [KEY_A, JOY_BUTTON_X],
	"desk_cancel": [KEY_BACKSPACE, JOY_BUTTON_B],
	"desk_notebook": [KEY_N, JOY_BUTTON_DPAD_UP],
	"desk_log": [KEY_L, JOY_BUTTON_DPAD_DOWN],
	"desk_tab_prev": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
	"desk_tab_next": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
	"desk_snap_prev": [KEY_PAGEUP, JOY_BUTTON_DPAD_LEFT],
	"desk_snap_next": [KEY_TAB, JOY_BUTTON_DPAD_RIGHT],
	"desk_approve": [KEY_1], "desk_deny": [KEY_2], "desk_report": [KEY_3], "desk_wrench": [KEY_4],
	"desk_relax": [KEY_R, JOY_BUTTON_START],
}
## The relaxed clock: a day at the counter takes this many times as long in real time.
const RELAXED_STRETCH := 1.5
## The UV lamp's light.
const UV := Color("b49cff")

## Gus, the first morning. Fix 3: Frank ran the shop; the counter was somebody else's.
const BRIEFS := {
	0: ["GUS LEANS ON THE DOORFRAME.", "\"FRONT COUNTER'S YOURS, KID. YOUR DAD RAN THIS SHOP TWENTY YEARS. THE COUNTER WAS SOMEBODY ELSE'S. NOW IT'S YOURS.\"", "\"IF THE PAPERS DON'T MATCH THE CAR, IT DOESN'T GET A STICKER. I READ THE VIN OFF THE DASH MYSELF. READ EVERY PAPER. EVERY ONE.\""],
	1: ["A FAX FROM THE MINISTRY CURLS OUT OF THE MACHINE.", "\"EXPIRED REGISTRATIONS ARE NOW YOUR PROBLEM.\"", "GUS: \"CHECK THE DATE AGAINST THE CALENDAR. THE CALENDAR DOESN'T LIE.\""],
	2: ["ANOTHER FAX. GUS DOESN'T EVEN LOOK UP.", "\"NO INSURANCE, NO SERVICE. AND THE LICENCE HAS TO BE THE OWNER'S.\"", "GUS: \"YOUR DAD USED TO SAY THE PAPERWORK IS THE JOB. THE WRENCHING IS THE FUN PART.\""],
	3: ["CONSTABLE TREMBLAY DROPS OFF A STOLEN LIST AND A BOX OF BURTON BITS.", "\"PIN THAT UP. ONE OF THOSE ROLLS IN, YOU CALL ME. YOU DON'T TOUCH IT.\"", "THEN MIA TORTELLINI CALLS. \"THE FAMILY'S SENDING CARS. YOU STILL OWE US A CAR, LEO. BAY 3. NO PAPERS.\""],
	4: ["LAST FAX OF THE WEEK.", "\"PEOPLE ARE LENDING EACH OTHER LICENCES. CHECK THE PHOTO.\"", "GUS: \"RENT'S DUE TONIGHT. AND I HEARD THERE'S A NEW GUY ASKING AROUND ABOUT 'NEW NUMBERS'. BE SMART.\""],
	8: ["YESTERDAY WAS THANKSGIVING. GUS, LEO, ARIES AND MIKEY ATE A STORE-BOUGHT TURKEY IN THE OFFICE. NOBODY SAID HIS NAME. THERE WAS A PLATE NOBODY USED.", "A FAX: \"SERVICE HISTORY. ODOMETERS GO UP.\"", "GUS: \"AND THE BULLETIN'S FULL. GOT YOU A BINDER. TABS AND EVERYTHING. DON'T SAY I NEVER GAVE YOU NOTHING.\""],
	9: ["GUS HANGS UP THE PHONE LIKE IT OWES HIM MONEY.", "\"HATCH MOTORS. SAYS HE'S BRINGING A CAR OVER. HIMSELF.\" HE SAYS IT LIKE A WEATHER REPORT. THEN HE GOES AND STANDS IN BAY 2 FOR A WHILE."],
	10: ["A FAX: \"A NEW OWNER HAS 10 DAYS TO REGISTER. A DATED BILL OF SALE COVERS THE NAME.\"", "GUS: \"SO WHEN THE NAMES DON'T MATCH, ASK. IF THEY'VE GOT A BILL OF SALE, READ IT LIKE IT OWES YOU MONEY.\""],
	11: ["FRIDAY.", "GUS: \"BILLS TONIGHT. TRY NOT TO GET FINED INTO THE GROUND BEFORE NOON.\""],
	14: ["A FAX: \"THE VIN ON THE DOOR JAMB MUST MATCH THE DASH.\"", "GUS: \"I PUT THE DOOR ON MY SHEET NOW. A NEW DOOR'S FINE IF A BODY SHOP BILLED FOR IT. A NEW DOOR WITH NO BILL IS SOMEBODY ELSE'S DOOR.\""],
	15: ["A FAX: \"A TEMPORARY PERMIT COVERS AN EXPIRED REGISTRATION. SAME VIN, DATES THAT COVER TODAY.\"", "GUS: \"SO NOW WHEN THEY SAY THERE'S A PAPER IN THE CAR, SOMETIMES THERE IS. HELL OF A WORLD.\""],
	16: ["GUS: \"DARRELL'S COMING BY WITH A TRADE-IN. YOU MET DARRELL.\"", "HE LETS THAT SIT. \"COUNT HIS KAYS. COUNT 'EM TWICE.\""],
	17: ["A FAX: \"OUT-OF-PROVINCE CARS ON A NEW REGISTRATION NEED A FULL INSPECTION.\"", "GUS: \"FULL ONE'S A HUNDRED AND FORTY. PEOPLE FROM AWAY BOOK THE SAFETY AND CALL IT EVEN. IT'S NOT EVEN.\""],
	18: ["FRIDAY. GUS'S PHONE SAYS FIRST FROST BY THE WEEKEND.", "GUS: \"MY PHONE SAYS A LOT OF THINGS. GET THE WINTER TIRE PEOPLE IN AND OUT.\""],
	21: ["A FAX: \"SALVAGE BRAND: NO STICKER WITHOUT A STRUCTURAL CERTIFICATE.\"", "GUS: \"AND IF IT WAS SALVAGE IN NOVA SCOTIA AND IT'S CLEAN HERE, THAT'S NOT A MIRACLE. THAT'S A WASHED TITLE. YOU REPORT THAT.\""],
	24: ["HALLOWEEN. A MEMO FROM THE MINISTRY: \"MASKS COME OFF AT THE COUNTER.\"", "GUS IS WEARING A HOCKEY HELMET. NOBODY ASKS HIM WHY. ASK THE CUSTOMERS, THOUGH."],
	25: ["FRIDAY, NOVEMBER 1. THE MINISTRY TALLIES THE MONTH TONIGHT.", "GUS: \"SMILE. THEY CAN'T SEE YOU, BUT SMILE.\""],
	28: ["NOVEMBER. THE FIRST SNOW DIDN'T STICK. THE FAX DID.", "\"WINDOW TINT: FRONT SIDE WINDOWS MUST PASS 70% OF LIGHT.\"",
		"GUS: \"LIGHT METER'S ON MY SHEET NOW. SEVENTY OR BETTER. UNDER THAT IT'S NOT A WINDOW, IT'S A WALL. SOME OF 'EM HAVE A DOCTOR'S FORM. READ THE FORM.\""],
	30: ["GUS OPENED AN ACCOUNT WITH FUNDY PARTS SUPPLY. THE BAY'S PARTS COME BY COURIER NOW, RIGHT TO THE WINDOW.",
		"GUS: \"OUR ORDER PRINTS OFF THE PC. THE BOX COMES WITH A SLIP. NUMBERS DON'T MATCH, IT'S NOT OUR PART. THE STUFF FROM THE STATES HAS A CUSTOMS FORM. IT BETTER SAY WHAT WE PAID. I TAPED A PAGE IN THE BINDER.\""],
	32: ["FRIDAY. BILLS TONIGHT.", "GUS: \"DARRELL CALLED. SAYS HE'S 'IN THE AREA.' DARRELL'S ALWAYS IN THE AREA.\""],
	36: ["YESTERDAY WAS REMEMBRANCE DAY. GUS STOOD AT THE CENOTAPH ON MAIN STREET AT ELEVEN, IN HIS GOOD COAT. HE DOES IT EVERY YEAR. HE DOESN'T SAY WHO FOR.",
		"A FAX: \"EXHAUST: NO HOLES. 95 DB MAX AT 3,000 RPM.\"",
		"GUS: \"I HOLD IT AT THREE GRAND AND READ THE METER. OVER NINETY-FIVE, IT FAILS. A HOLE, IT FAILS. I DON'T CARE HOW QUIET THE HOLE IS.\""],
	42: ["A MAN IN A GREY RAINCOAT IS AT THE DOOR AT 7:45 WITH A BRIEFCASE AND A THERMOS. INSPECTOR HACHEY. THE MINISTRY.",
		"\"GOOD MORNING. DON'T MIND ME. I'M JUST GOING TO STAND HERE AND BE THE MINISTRY.\" TWICE A DAY THIS WEEK HE PULLS ONE OF YOUR OLD WORK ORDERS, COVERS THE STAMP WITH HIS THUMB, AND WATCHES YOU STAMP IT AGAIN.",
		"GUS: \"IF YOU WERE RIGHT THE FIRST TIME, YOU'LL BE RIGHT AGAIN. IF YOU WEREN'T... READ THE PAPER.\""],
	43: ["HACHEY'S AT THE DOOR AT 7:45 AGAIN. SAME THERMOS. GUS MAKES HIM A COFFEE ANYWAY. HACHEY WRITES DOWN THAT GUS MADE HIM A COFFEE."],
	44: ["GUS: \"HE ASKED ME HOW LONG I'VE WORKED HERE. I SAID SINCE 1981. HE WROTE DOWN 1981. THEN HE UNDERLINED IT.\""],
	45: ["HACHEY BRINGS MUFFINS. NOBODY KNOWS IF IT'S A TEST. GUS EATS ONE ANYWAY.", "GUS: \"IF IT'S A TEST, I PASSED.\""],
	46: ["FRIDAY. THE LAST DAY OF THE AUDIT. HACHEY'S REPORT GOES TO FREDERICTON TONIGHT.", "GUS: \"WHATEVER HE WRITES, THE SHOP'S STILL HERE MONDAY. PROBABLY.\""],
	38: ["CONSTABLE TREMBLAY TAPES A STRIP ONTO THE BOTTOM OF THE STOLEN LIST AND DOESN'T STAY FOR COFFEE. PARTS, BY SERIAL NUMBER. SOMEBODY'S BEEN TAKING CATALYTIC CONVERTERS OFF CARS IN THE CHAMPAGNE PLACE LOT WITH A BATTERY SAW.",
		"\"A PART ON THAT LIST, ON A CAR OR IN A BOX, YOU CALL ME. YOU DON'T SIGN FOR IT. YOU DON'T PUT IT BACK ON.\"",
		"GUS: \"I READ THE SERIAL OFF THE PART MYSELF. NOT OFF THE INVOICE. AN INVOICE IS WHAT SOMEBODY WISHES WAS TRUE.\""],
	49: ["MONDAY. IT SNOWED OVERNIGHT AND IT STUCK. THE LOT'S FULL OF PEOPLE WHO WANTED THEIR WINTERS ON LAST WEEK.",
		"A FAX: \"WINTER TIRES REQUIRED ON TAXIS, RIDESHARES AND COMMERCIAL VEHICLES, DEC 1 TO APR 30.\" THE MINISTRY WANTS THEM ON BEFORE THE STICKER, NOT AFTER.",
		"GUS: \"THE OWNERSHIP SAYS WHAT IT'S FOR NOW. THE TIRES ARE ON MY SHEET. A CAB ON ALL-SEASONS DOESN'T GET A STICKER. A CAB HERE TO GET ITS WINTERS ON GETS ITS WINTERS ON.\""],
	50: ["GUS: \"EVERY CAB IN PORT RUMBLE NEEDS A STICKER BY SUNDAY. HALF OF 'EM ARE IN OUR LOT. THE OTHER HALF ARE AT LINDSAY'S. SHE'S FASTER. WE'RE RIGHT.\""],
	51: ["A FAX: \"STUDDED TIRES: OCT 15 TO APR 30 ONLY.\"", "GUS: \"READ THE DATES ON THAT ONE. THEN READ THE CALENDAR. THEN READ 'EM BOTH AGAIN.\""],
	52: ["THURSDAY. IT'S THANKSGIVING IN THE STATES. THE PARCEL DRIVER SAYS OHIO'S CLOSED. OHIO'S WEBSITE ISN'T.",
		"GUS: \"THE AMERICANS GET A TURKEY AND A FOUR-DAY WEEKEND. WE GET ROCKBOTTOM'S EMAILS.\""],
	53: ["FRIDAY, NOVEMBER 29. THE LAST SHIFT BEFORE DECEMBER. THE CALENDAR ON THE WALL'S DOWN TO ITS LAST PAGE.",
		"GUS: \"CABS ON WINTERS. MINISTRY'S QUIET. RENT'S DUE. SAME AS EVERY FRIDAY, ONLY COLDER.\""],
}
## For mornings nobody wrote anything down.
const MORNINGS := ["GUS READS THE CANADIAN TIRED FLYER LIKE IT'S SCRIPTURE.", "THE COFFEE MAKER MAKES A NOISE LIKE IT'S DYING. IT'S BEEN DYING SINCE 1997.",
	"SOMEBODY'S ALREADY IN THE LOT AT 7:40, ENGINE RUNNING. THERE'S ALWAYS SOMEBODY.", "GUS: \"SAME RULES AS YESTERDAY. SAME PEOPLE, TOO, PROBABLY.\""]
## Gus, standing behind you on your first day, one tip per customer.
const TIPS := [
	"GUS: DRAG THE PAPERS AROUND. THEN INSPECT ({inspect}) AND PICK THE VIN ON THE OWNERSHIP, THEN THE VIN ON MY SHEET.",
	"GUS: ...THAT'S A NAPKIN. I DIDN'T SEE A NAPKIN. WHAT HAPPENS IN BAY 3 IS YOUR BUSINESS NOW. (BAY 3 PAYS DOWN WHAT YOU OWE.)",
	"GUS: FIND SOMETHING WRONG AND YOU CAN ASK ({desk_ask}) ABOUT IT. MOST OF 'EM LIE. SOME OF 'EM HAVE A PAPER.",
	"GUS: THE CLOCK'S RUNNING. MINISTRY GIVES YOU TWO WARNINGS A DAY. AFTER THAT IT'S A HUNDRED BUCKS A MISTAKE.",
	"GUS: LAST ONE. THEN WE LOCK UP AND YOU GO DEAL WITH WHATEVER YOU'RE DEALING WITH.",
]
const TAB_SHORT := { "INSPECTION": "INSP.", "DOCUMENTS": "DOCS", "POLICE": "POLICE", "MINISTRY": "MIN.", "SEASONAL": "SEAS.", "PARTS": "PARTS" }
const TAB_COL := { "INSPECTION": Color("c8a030"), "DOCUMENTS": Color("6a9a5a"), "POLICE": Color("4a6aa8"), "MINISTRY": Color("a84a3a"),
	"SEASONAL": Color("8a5aa0"), "PARTS": Color("a8743a") }
## First open day of each week of free play (OVERTIME comes after them on the picker).
const WEEK_DAYS := [0, 8, 14, 21, 28, 36, 42, 49]
## Overtime's notices: what the calendar brings on the first open day on or after [month, day].
const OT_NOTICES := [
	[[12, 1], "A FAX: FROM DECEMBER 1, WINTER TIRES ON TAXIS, RIDESHARES AND COMMERCIAL VEHICLES ARE THE LAW ON THE ROAD TOO, NOT JUST AT THE STICKER. TILL APRIL 30."],
	[[12, 24], "CHRISTMAS EVE. GUS HANGS A STRING OF LIGHTS OVER THE STOLEN LIST. HALF OF THEM WORK. HE SAYS THAT'S THE SPIRIT."],
	[[1, 2], "A NEW YEAR. THE SAME BINDER. GUS WRITES THE YEAR ON THE CALENDAR IN PEN, SO NOBODY FORGETS."],
	[[4, 15], "A FAX: STUDDED TIRES COME OFF BY APRIL 30. FROM MAY 1 THEY'RE OUT OF SEASON, AND A CAR ON STUDS DOESN'T GET A STICKER."],
	[[5, 1], "MAY. STUD SEASON'S OVER TILL OCTOBER 15: STUDS ON A STICKER JOB FAIL. AND THE WORKING CARS DON'T NEED THEIR WINTERS TILL NOVEMBER 25."],
	[[10, 15], "OCTOBER 15. STUD SEASON AGAIN. GUS: \"THEY'LL ALL BE BACK ON BY FRIDAY. LISTEN FOR THE CRUNCH.\""],
	[[11, 25], "A FAX: WINTER TIRES ON TAXIS, RIDESHARES AND COMMERCIAL VEHICLES BEFORE THE STICKER, FROM TODAY TILL APRIL 30. AGAIN."],
]
## Overtime mornings nobody wrote anything down, by the month.
const OT_MORNINGS := {
	12: ["THE PLOW BURIED THE LOT ENTRANCE AGAIN. GUS SHOVELS IT OUT IN HIS GOOD COAT. NOBODY ASKS ABOUT THE COAT.",
		"SOMEBODY LEFT A TIN OF COOKIES ON THE COUNTER. NO NAME. GUS EATS ONE AND DECLARES THEM SAFE."],
	1: ["MINUS TWENTY-SIX WITH THE WIND. THE COFFEE MAKER WON'T START. GUS TALKS IT ROUND.",
		"THE CABS ARE IN THE LOT BY SEVEN WITH THEIR ENGINES RUNNING. THE EXHAUST HANGS THERE LIKE FOG."],
	2: ["IT SNOWED. IT SNOWED YESTERDAY TOO. GUS HAS STOPPED MENTIONING IT.", "MINUS TWENTY-SIX WITH THE WIND. THE COFFEE MAKER WON'T START. GUS TALKS IT ROUND."],
	3: ["MUD SEASON. GUS PUTS CARDBOARD DOWN BY THE DOOR. THE MUD WALKS AROUND IT.", "THE POTHOLES ARE BACK. THE LOT'S FULL OF PEOPLE WHO FOUND ONE."],
	4: ["THE POTHOLES ARE BACK. THE LOT'S FULL OF PEOPLE WHO FOUND ONE.", "THE SNOWBANK BY THE BAY DOOR IS DOWN TO A GREY LUMP. GUS GIVES IT A WEEK."],
	5: ["THE FIRST WARM MORNING. GUS OPENS THE BAY DOORS AND STANDS IN THE SUN FOR A MINUTE.", "BLACKFLIES. GUS SAYS THEY DON'T BITE HIM. THEY DO."],
	6: ["BLACKFLIES. GUS SAYS THEY DON'T BITE HIM. THEY DO.", "THE FIRST WARM MORNING. GUS OPENS THE BAY DOORS AND STANDS IN THE SUN FOR A MINUTE."],
	7: ["A MINIVAN FROM AWAY ASKS THE WAY TO MAGNET HILL. GUS GIVES IT. MOSTLY RIGHT.", "TOO HOT FOR THE BAY. GUS WORKS IN HIS UNDERSHIRT AND DARES ANYBODY TO SAY SOMETHING."],
	8: ["TOO HOT FOR THE BAY. GUS WORKS IN HIS UNDERSHIRT AND DARES ANYBODY TO SAY SOMETHING.", "A MINIVAN FROM AWAY ASKS THE WAY TO MAGNET HILL. GUS GIVES IT. MOSTLY RIGHT."],
	9: ["BACK-TO-SCHOOL TRAFFIC ON MAIN ST. THE BUSES GET THEIR STICKERS SOMEWHERE ELSE. GUS SAYS THANK GOODNESS."],
	10: ["THE LEAVES ARE DOWN AND IN EVERY GUTTER ON MAIN ST.", "FIRST FROST. THE LINE FOR WINTER TIRES STARTS AT SEVEN."],
	11: ["FIRST FROST. THE LINE FOR WINTER TIRES STARTS AT SEVEN.", "THE LEAVES ARE DOWN AND IN EVERY GUTTER ON MAIN ST."],
}
## What the stamps say on a box (signing for it) and on a pulled file.
const STAMP_WORD := { "APPROVED": "APPROVED", "DENIED": "DENIED", "REPORT": "REPORTED", "WRENCH": "BAY 3" }
const BOX_WORD := { "APPROVED": "SIGNED FOR", "DENIED": "REFUSED", "REPORT": "REPORTED", "WRENCH": "BAY 3" }

var rules: CounterRules
var day := 0
var c: Dictionary = {}               # the customer at the window
var phase := "brief"                  # brief, idle, counter, stamping, result, day_end, drawer, week_end, month_end, revoked
var docs: Array = []                  # [{id, pos, fresh}] back to front
var drag := -1
var drag_off := Vector2.ZERO
var inspecting := false
var pick_a: Dictionary = {}
var verdict: Dictionary = {}          # {a, b, text, good, t}
var stamped := ""
var stamp_t := 0.0
var result: Dictionary = {}
var cur := Vector2(320, 200)
var pad_cursor := false
var car_view: CarView
var demo := false
var story: Dictionary = {}            # the story step, when this shift is part of the story
var tutorial := false
var chapter := 1

# the shift
var clock := 0.0                      # minutes since 8:00
var arrivals: Array = []              # [{t, c}] still on their way
var waiting: Array = []               # in the lot, first in line first
var walked: Array = []                # who drove off at closing
var served := 0
var since := 0.0                      # when the customer at the window stepped up
var next_honk := 0.0
var honk_t := 0.0
var warnings_used := 0
var _qid := 0
var _qtex := {}                       # queue car pictures by customer

# the room's sounds
var audio: DeskAudio                  # null when there's no tree to play in (the tests)
var heard: Array = []                 # every sound the desk asked for, newest last
var _tick_acc := 0.0
var _tock := false

# ASK
var topics: Array = []                # what Leo has proven wrong with this one, newest first
var asked: Array = []
var said: Dictionary = {}             # the last exchange: {q, a, clue}

# the binder and the books
var tab := 0
var book := ""                        # "", "notebook" or "log": open on the desk
var log_old := false                  # the log is open at last fall's pages
var week_pick := 0                    # free play: which week to start in
var fresh := true                     # nothing played yet this session
var overtime := false                 # the job after the run (DeskBook.overtime keeps the record)

# Gus's tool drawer (DeskTools; what's bought is in DeskBook.tools)
var drawer_sel := 0                   # the tool the cursor's on
var drawer_line := ""                 # what Gus said last
var drawer_armed := false             # the cursor's been off the drawer since the sheet came up (a click straight through goes home)
var lit := {}                         # the UV lamp: doc -> it glowed (true) or didn't, for this customer

# the books of the shop
var cash := CounterRules.START_CASH
var day_log := {}
var week := {}
var bills_paid: Array = []
var month := { "seen": 0, "correct": 0, "citations": 0, "earned": 0 }

## Register the desk's buttons (safe to call more than once).
static func setup_actions() -> void:
	Controls.setup()
	Controls.add_actions(ACTIONS)

func _ready() -> void:
	setup_actions()
	rules = CounterRules.new(506 + int(Time.get_unix_time_from_system()) % 100000)
	rules.make_bolo()
	car_view = CarView.new()
	car_view.position = Vector2(WINDOW.position.x + 160, 72)
	car_view.scale = Vector2(1.5, 1.5)
	add_child(car_view)
	audio = DeskAudio.new()
	add_child(audio)
	if StoryState.active and String(StoryState.current().get("type", "")) == "counter":
		story = StoryState.current()
		tutorial = bool(story.get("tutorial", false))
		chapter = int(story.get("chapter", 1))
	DeskBook.open_book()
	if story.has("old_log"): DeskBook.old_log = bool(story.old_log)
	_new_week()
	start_day(int(story.get("day", 0)))
	if OS.get_cmdline_user_args().has("--counter-demo"):
		demo = true
		var d: Node = load("res://tests/counter_demo.gd").new()
		d.scene = self
		add_child(d)

# ------------------------------------------------------------------ the day

func _new_week() -> void:
	week = { "earned": 0, "dirty": 0, "fines": 0, "fees": 0, "citations": 0, "warnings": 0, "heat": 0, "trust": 0, "reviews": 0, "correct": 0, "seen": 0 }

func start_day(d: int) -> void:
	day = d
	# Constable Tremblay's list for the week (the same one all week, a new one on Monday)
	rules.use_list(DeskBook.week_list(CounterRules.week_of(day)))
	var extra: Array = story.get("customers", [])
	arrivals = rules.shift(day, heat(), extra, chapter)
	if tutorial: arrivals = _tutorial_line(arrivals)
	# audit week: Hachey pulls a file at 9:30 and at 2:00 (which one, he decides when he gets here)
	for at in CounterRules.audit_times(day): arrivals.append({ "t": at, "c": rules.hachey(day) })
	arrivals.sort_custom(func(a, b): return a.t < b.t)
	waiting = []
	walked = []
	served = 0
	clock = 0.0
	warnings_used = 0
	c = {}
	book = ""
	inspecting = false
	verdict = {}
	tab = _newest_tab()
	day_log = { "earned": 0, "dirty": 0, "fines": 0, "fees": 0, "citations": [], "warnings": [], "heat": 0, "trust": 0, "reviews": 0,
		"correct": 0, "seen": 0, "walked": 0, "walked_money": 0, "stickers": [], "audits": 0, "audits_same": 0, "audits_wrong": 0 }
	# last fall's sticker log comes out of the filing cabinet (in free play, a week early)
	if day >= 29 or (story.is_empty() and day >= 22): DeskBook.old_log = true
	phase = "brief"
	if car_view != null: car_view.visible = false

## The first morning: a short line, all there at 8, with the Familia's first napkin second in it.
func _tutorial_line(sh: Array) -> Array:
	var regs := sh.filter(func(x): return x.c.kind == "regular").slice(0, 4)
	var fam := rules.familia(day)
	fam.napkin = "BAY 3. NEW NUMBERS. DOM SAYS WELCOME TO THE FAMILY. -S"
	regs.insert(1, { "t": 0.0, "c": fam })
	for i in regs.size(): regs[i].t = [2.0, 9.0, 18.0, 30.0, 44.0][i]
	return regs

func heat() -> int:
	return int(week.get("heat", 0)) + int(day_log.get("heat", 0))

## The stolen list counts once it's on the wall. A file Hachey pulls is read against the list
## from its own week (the Ministry's copy goes up over this week's while it's on the desk).
func bolo_now() -> Array:
	if _filed(): return CounterRules.audit_list(c, rules.bolo)
	return rules.bolo if CounterRules.rule_active("bolo", day) else []

## A pulled file is on the desk.
func _filed() -> bool:
	return c.get("kind", "") == "audit" and c.has("audit")

## The shift clock: arrivals join the line, the next one honks, six o'clock empties the lot.
func tick(dt: float) -> void:
	if not phase in ["idle", "counter", "stamping", "result"]: return
	var rate := clock_rate()
	if phase == "idle":
		# nobody at the window: the afternoon drags by fast (and if nobody else is coming, faster)
		rate *= 12.0 if not arrivals.is_empty() else 60.0
	clock = minf(CounterRules.SHIFT_LEN, clock + dt * rate)
	# the wall clock, once a second (and not while the afternoon's racing by)
	_tick_acc += dt
	if _tick_acc >= 1.0:
		_tick_acc = fmod(_tick_acc, 1.0)
		if phase != "idle" and clock < CounterRules.SHIFT_LEN:
			_tock = not _tock
			# a little louder in the last hour
			sfx("tock" if _tock else "tick", 1.0, 3.0 if clock >= CounterRules.SHIFT_LEN - 60.0 else 0.0)
	while not arrivals.is_empty() and float(arrivals[0].t) <= clock:
		var cc: Dictionary = arrivals.pop_front().c
		if cc.kind == "audit" and not cc.has("audit"):
			cc = _pull_file(cc)
			if cc.is_empty(): continue
		cc.qid = _qid
		cc.arrived = clock
		_qid += 1
		# the Ministry doesn't wait in line
		if cc.kind == "audit": waiting.push_front(cc)
		else: waiting.append(cc)
	if clock >= CounterRules.SHIFT_LEN:
		arrivals = []
		if not waiting.is_empty():
			walked.append_array(waiting)
			waiting = []
	if phase == "idle":
		if not waiting.is_empty(): next_customer()
		elif clock >= CounterRules.SHIFT_LEN: close_up()
	if phase in ["counter", "stamping"] and not waiting.is_empty() and clock - since > CounterRules.HONK_AFTER and clock >= next_honk:
		honk_t = 1.4
		next_honk = clock + 25.0
		sfx("honk", 0.97 + 0.06 * float(int(clock) % 3) / 2.0)
	honk_t = maxf(0.0, honk_t - dt)

## Minutes on the wall clock per real second with somebody at the window: ten real minutes a
## day, fifteen on the relaxed clock (and the first morning goes at half speed). Only the pace:
## the line, the honking and every rule are counted in the clock's own minutes.
func clock_rate() -> float:
	var rate := CounterRules.SHIFT_LEN / CounterRules.REAL_SECONDS
	if tutorial: rate *= 0.5
	if DeskBook.relaxed: rate /= RELAXED_STRETCH
	return rate

## RELAXED CLOCK on the morning brief: on or off, kept in the book.
func toggle_relaxed() -> void:
	if phase != "brief": return
	DeskBook.relaxed = not DeskBook.relaxed
	sfx("page", 1.1 if DeskBook.relaxed else 0.95, -4.0)

## Hachey's turn at the cabinet: he pulls one of Leo's old work orders and brings it to the
## window. Nothing to pull yet, and he comes back in an hour (once, before the afternoon's out).
func _pull_file(slot: Dictionary) -> Dictionary:
	var rec := CounterRules.pull(DeskBook.files, day, rules.rng)
	var c2 := CounterRules.audit_customer(rec) if not rec.is_empty() else {}
	if c2.is_empty():
		if clock + 60.0 < CounterRules.SHIFT_LEN - 60.0 and not slot.get("retry", false):
			slot.retry = true
			arrivals.append({ "t": clock + 60.0, "c": slot })
			arrivals.sort_custom(func(a, b): return a.t < b.t)
		return {}
	rec.pulled = true
	c2.queue_car = slot.car
	return c2

## A sound from the room (logged, so the tests can hear it too).
func sfx(sound_name: String, pitch := 1.0, gain_db := 0.0) -> void:
	heard.append(sound_name)
	if heard.size() > 64: heard.pop_front()
	if audio != null and audio.is_inside_tree(): audio.play(sound_name, pitch, gain_db)

func next_customer() -> void:
	if waiting.is_empty():
		phase = "idle"
		c = {}
		car_view.visible = false
		return
	c = waiting.pop_front()
	since = clock
	next_honk = clock + CounterRules.HONK_AFTER
	phase = "counter"
	stamped = ""
	inspecting = false
	pick_a = {}
	verdict = {}
	topics = []
	asked = []
	said = {}
	book = ""
	lit = {}
	# a pulled file has no car in the bay: it's long gone
	if c.kind != "audit":
		var spec := { "length": c.car.len, "width": c.car.wid, "wheelbase": float(c.car.get("wheelbase", float(c.car.len) * 0.6)), "body": c.car.get("side_body", "sedan") }
		car_view.art = CarArt.new(spec, Color(c.car.paint), 0.15 if c.get("sheet", {}).get("rust", false) else 0.0, c.person.face)
		car_view.heading = 0.0
	car_view.visible = c.kind != "audit"
	docs = []
	var order := ["work", "order", "reg", "licence", "insurance", "glovebox", "history", "old_reg", "cert", "bos", "permit", "door_inv",
		"exempt", "invoice", "slip", "customs", "notice", "sheet", "letter"]
	for id in order:
		if c.docs.has(id) and not c.hidden.has(id): docs.append({ "id": id, "pos": _home(id, docs.size()), "fresh": 0.0 })
	if c.napkin != "": docs.append({ "id": "napkin", "pos": _home("napkin", docs.size()), "fresh": 0.0 })
	# a pulled file opens at its cover sheet (the work order, or a box's slip), Hachey's thumb on the stamp
	var cover := _doc_index(_stamp_doc())
	if c.kind == "audit" and cover >= 0: _raise(cover)
	sfx("paper")

## Where each paper lands when it's handed over. Gus's sheet sits as low as it can and still
## show its last row above the tray.
func _home(id: String, n: int) -> Vector2:
	if id == "sheet": return Vector2(226, minf(222.0, DESK.end.y - _doc_size("sheet").y - 2.0))
	var spots := { "work": Vector2(156, 116), "reg": Vector2(306, 118), "licence": Vector2(158, 186), "insurance": Vector2(306, 194),
		"glovebox": Vector2(306, 194), "sheet": Vector2(226, 222), "napkin": Vector2(380, 240), "history": Vector2(196, 150),
		"old_reg": Vector2(290, 148), "cert": Vector2(176, 236), "letter": Vector2(346, 150), "exempt": Vector2(176, 150),
		"order": Vector2(156, 118), "slip": Vector2(304, 122), "customs": Vector2(300, 212), "notice": Vector2(170, 214),
		"invoice": Vector2(186, 140) }
	return spots.get(id, Vector2(212 + n * 6, 136 + n * 4))

## The paper the stamp goes on: the work order, or a courier's packing slip.
func _stamp_doc() -> String:
	return "slip" if c.has("slip") else "work"

func stamp(s: String) -> void:
	if phase != "counter": return
	stamped = s
	stamp_t = 0.0 if demo else 0.8
	phase = "stamping"
	inspecting = false
	book = ""
	var i := _doc_index(_stamp_doc())
	if i >= 0: _raise(i)
	sfx("stamp", 0.96 + 0.08 * float(served % 3) / 2.0)

func _resolve() -> void:
	result = CounterRules.judge(c, stamped, jday(), bolo_now())
	var pen := CounterRules.penalty(c, result, warnings_used)
	result.fine = int(pen.fine)
	result.warning = bool(pen.warning)
	if result.citation != "":
		if result.warning:
			warnings_used += 1
			DeskBook.warnings += 1
			day_log.warnings.append(result.citation)
		else:
			DeskBook.citations += 1
			day_log.citations.append(result.citation)
	result.sticker = 0
	if stamped == "APPROVED" and CounterRules.INSPECTIONS.has(c.request) and c.kind != "audit":
		result.sticker = DeskBook.issue(day, c)
		day_log.stickers.append(result.sticker)
	for f in result.get("flags", []): DeskBook.raise(String(f))
	# overtime: every call counts toward the streak, or ends it
	if overtime:
		result.streak_was = int(DeskBook.overtime.get("streak", 0))
		result.best_was = int(DeskBook.overtime.get("best", 0))
		DeskBook.tally(bool(result.correct))
	# into the filing cabinet: the regulars and the people turned away remember it; Hachey pulls it
	if c.kind == "audit":
		DeskBook.audits.append({ "no": int(c.audit.no), "day": day, "was": String(c.audit.stamp), "now": stamped, "right": bool(c.audit.correct) })
		day_log.audits += 1
		if result.correct: day_log.audits_same += 1
		# the same wrong call twice: no citation, but it's in his report
		if result.get("wrong_twice", false):
			day_log.audits_wrong += 1
			DeskBook.raise("desk_audit_wrong_twice")
	else:
		DeskBook.file(day, c, stamped, bool(result.correct), CounterRules.find_problems(c, day, bolo_now()))
	for k in ["heat", "trust", "dirty"]: day_log[k] += int(result[k])
	day_log.earned += int(result.money)
	day_log.fines += result.fine
	day_log.fees += int(result.get("fee", 0))
	day_log.reviews += int(result.review)
	day_log.seen += 1
	if result.correct: day_log.correct += 1
	cash += int(result.money) + int(result.dirty) - result.fine - int(result.get("fee", 0))
	if result.fine + int(result.get("fee", 0)) > 0: sfx("till")
	served += 1
	phase = "result"

## The day the papers are read against: today, or the day on a pulled file.
func jday() -> int:
	return int(c.audit.day) if _filed() else day

## Six o'clock: whoever's still in the lot drives off with their money.
func close_up() -> void:
	walked.append_array(waiting)
	waiting = []
	arrivals = []
	clock = CounterRules.SHIFT_LEN
	day_log.walked = walked.size()
	day_log.walked_money = 0
	for w in walked:
		day_log.walked_money += CounterRules.walked_pay(w)
		# the regulars (and whoever came back) remember being left in the lot
		var spec: Dictionary = w.get("script", {})
		if String(w.get("regular", "")) != "" or int(spec.get("of", 0)) > 0: DeskBook.file(day, w, "WALKED", true, [])
	c = {}
	book = ""
	inspecting = false
	car_view.visible = false
	phase = "day_end"
	# the stamps were where the drawer is: a click that lands there before the cursor's moved off goes home
	drawer_armed = not DRAWER_HANDLE.has_point(cur)

func end_day() -> void:
	if not story.is_empty():
		_clock_out()
		return
	for k in ["earned", "dirty", "fines", "fees", "heat", "trust", "reviews", "correct", "seen"]: week[k] += day_log[k]
	week.citations += day_log.citations.size()
	week.warnings += day_log.warnings.size()
	for k in ["seen", "correct", "earned"]: month[k] += day_log[k]
	month.citations += day_log.citations.size()
	var next := CounterRules.next_open(day)
	# the bills come due on the last open day of the week (Friday, unless Friday's a holiday)
	var closes := CounterRules.week_closes(day)
	if closes:
		_pay_bills()
		if week.citations >= 4: DeskBook.meetings += 1
		phase = "week_end"
	if overtime: _keep_day(next, closes)
	if not closes: start_day(next)

## Overtime's clock-out: one more day kept, and the book saved with tomorrow in it (and the
## week's tally, unless the week's done). A licence gone at the week's end ends this overtime.
func _keep_day(next: int, closes: bool) -> void:
	DeskBook.day_kept(next, cash, {} if closes else week)
	if closes and DeskBook.revoked(): DeskBook.overtime.ended = true
	DeskBook.save_overtime()

## CLOCK OUT: Leo's pay for the day (a cut of the shop's take), Bay 3 cash goes straight to
## the Familia, the desk's flags go to the story, and the story carries on into the evening.
func _clock_out() -> void:
	var wage := 60 + int(day_log.earned * 0.15)
	StoryState.cash += wage
	StoryState.debt = maxi(0, StoryState.debt - int(day_log.dirty))
	StoryState.last_result = { "earned": day_log.earned, "dirty": day_log.dirty, "fines": day_log.fines, "fees": day_log.fees, "correct": day_log.correct,
		"seen": day_log.seen, "wage": wage, "walked": day_log.walked, "warnings": day_log.warnings.size(), "citations": day_log.citations.size() }
	if DeskBook.revoked(): DeskBook.raise("desk_licence_revoked")
	DeskBook.close_book()
	StoryState.advance(get_tree())

func _pay_bills() -> void:
	bills_paid = []
	for b in CounterRules.BILLS:
		var paid: bool = cash >= int(b[1])
		if paid: cash -= int(b[1])
		bills_paid.append([b[0], b[1], paid])

## After Friday's bills: the next week, the end of the month, or the end of the licence. In
## overtime there's always a next week, licence permitting.
func _after_week() -> void:
	if DeskBook.revoked():
		phase = "revoked"
	elif day >= CounterRules.LAST_DAY and not overtime:
		phase = "month_end"
	else:
		_new_week()
		start_day(CounterRules.next_open(day))

func _quit() -> void:
	get_tree().change_scene_to_file("res://title.tscn")

## OVERTIME on the week picker: back to the overtime on file (the day it got to, the till, the
## book and the record), or, if there isn't one or its licence went, a new one from Monday,
## December 2 with a fresh book (the bests stay on the record).
func _pick_overtime() -> void:
	overtime = true
	# (the overtime on file keeps its own clock and tools; a new one keeps the clock on the picker)
	var clock_was := DeskBook.relaxed
	var had := DeskBook.load_overtime()
	if not had or bool(DeskBook.overtime.get("ended", false)):
		var record: Dictionary = DeskBook.overtime.duplicate(true) if had else {}
		DeskBook.reset()
		DeskBook.book_seed = randi()
		DeskBook.overtime = record
		DeskBook.relaxed = clock_was
		DeskBook.start_overtime(CounterRules.OVERTIME_START, CounterRules.START_CASH)
	cash = int(DeskBook.overtime.cash)
	_new_week()
	week.merge(DeskBook.overtime.get("week", {}), true)
	start_day(int(DeskBook.overtime.day))

## Back to the eight weeks on the picker: a fresh book (no tools in the drawer) and a fresh till,
## on whichever clock the picker shows.
func _leave_overtime() -> void:
	if not overtime: return
	overtime = false
	var clock_was := DeskBook.relaxed
	DeskBook.reset()
	DeskBook.relaxed = clock_was
	DeskBook.book_seed = randi()
	cash = CounterRules.START_CASH
	_new_week()

## KEEP WORKING at the end of the run: overtime from Monday, December 2 with this run's book
## (the regulars and the people turned away remember it, and Hachey pulls from it) and what's
## left in the till. It takes the place of any overtime on file; the bests stay.
func _continue_overtime() -> void:
	DeskBook.overtime = DeskBook.overtime_on_file()
	DeskBook.start_overtime(CounterRules.next_open(day), cash)
	overtime = true
	_new_week()
	start_day(CounterRules.next_open(day))

# ------------------------------------------------------------------ Gus's tool drawer

## The front of the drawer under the desk, below the day-end sheet (where the stamps sit by day).
const DRAWER_HANDLE := Rect2(150, 330, 320, 29)

## What pays for a tool: the till, or in the story Leo's own money (the shop's till there is
## only the day's).
func purse() -> int:
	return StoryState.cash if not story.is_empty() else cash

func purse_label() -> String:
	return "YOUR OWN MONEY" if not story.is_empty() else "IN THE TILL"

## What's in the drawer tonight (a tool turns up once its check is on the wall).
func drawer_tools() -> Array:
	return DeskTools.offered(day)

## Off the day-end sheet: Gus pulls the drawer open, at the first tool Leo hasn't got.
func open_drawer() -> void:
	var ts := drawer_tools()
	if phase != "day_end" or ts.is_empty(): return
	phase = "drawer"
	drawer_sel = 0
	for i in ts.size():
		if not DeskBook.tools.has(String(ts[i].id)):
			drawer_sel = i
			break
	# (the keys and the pad buy whatever the cursor's on; a mouse click puts the cursor where it clicks)
	cur = _drawer_rect(drawer_sel).get_center()
	drawer_line = "GUS: \"FRANK BOUGHT HIS OFF THE TOOL TRUCK. I KNOW THE GUY. PAY TONIGHT, IT'S IN THE DRAWER IN THE MORNING.\"" if DeskBook.tools.is_empty() \
		else "GUS: \"SHOPPING AGAIN? THE TRUCK GUY'S GOING TO NAME A BOAT AFTER YOU.\""
	sfx("page", 0.8, -2.0)

## Buy tool `id`: false (and Gus says why) if Leo's got one or can't cover it.
func buy_tool(id: String) -> bool:
	var t := DeskTools.tool(id)
	if t.is_empty() or not drawer_tools().any(func(x): return String(x.id) == id): return false
	if DeskBook.tools.has(id):
		drawer_line = "GUS: \"YOU'VE GOT ONE. IT'S IN THE DRAWER. THE DRAWER'S RIGHT THERE.\""
		return false
	var price := int(t.price)
	if purse() < price:
		drawer_line = "GUS: \"YOU'RE $%d SHORT, KID. IT'LL STILL BE HERE.\"" % (price - purse())
		return false
	if story.is_empty(): cash -= price
	else: StoryState.cash -= price
	DeskBook.tools.append(id)
	drawer_line = String(t.gus)
	sfx("till")
	return true

## A row of the drawer, and which row is under `p` (-1 for none).
func _drawer_rect(i: int) -> Rect2:
	return Rect2(122, 84 + i * 45, 396, 41)

func _drawer_row_at(p: Vector2) -> int:
	for i in drawer_tools().size():
		if _drawer_rect(i).has_point(p): return i
	return -1

func _drawer_shut_rect() -> Rect2:
	return Rect2(220, 308, 200, 13)

## A click in the drawer: on a tool, buy it; on SHUT IT, back to the sheet.
func _drawer_press() -> void:
	var i := _drawer_row_at(cur)
	if i >= 0:
		drawer_sel = i
		buy_tool(String(drawer_tools()[i].id))
	elif _drawer_shut_rect().has_point(cur): phase = "day_end"

## The cursor moved: in the drawer, the tool it's over is the one picked; on the day-end sheet,
## once it's been off the drawer's front, a click on the front opens it.
func _drawer_hover() -> void:
	if phase == "day_end" and not DRAWER_HANDLE.has_point(cur): drawer_armed = true
	if phase != "drawer": return
	var i := _drawer_row_at(cur)
	if i >= 0: drawer_sel = i

# ------------------------------------------------------------------ ASK

## The questions Leo can put to the customer: what he's proven wrong (newest first), then
## the ones he can always ask.
func ask_list() -> Array:
	if c.is_empty() or phase != "counter": return []
	var out: Array = topics.duplicate()
	for t in CounterRules.standing_topics(c, day):
		if not out.has(t): out.append(t)
	return out

## ASK with the button: the newest question not asked yet.
func ask_next() -> void:
	var l := ask_list()
	for t in l:
		if not asked.has(t):
			ask(t)
			return
	if not l.is_empty(): ask(l[0])

func ask(topic: String) -> void:
	if phase != "counter": return
	var ans := CounterRules.answer(c, topic, jday())
	said = { "q": String(CounterRules.QUESTIONS.get(topic, "...")), "a": String(ans.get("line", "...")), "clue": ans.get("clue", {}) }
	if not asked.has(topic): asked.append(topic)
	var doc := String(ans.get("doc", ""))
	if doc != "" and c.get("hidden", []).has(doc): _hand_over(doc)
	if ans.get("unmask", false): c.mask = ""

## A paper comes out of a pocket and lands on top of the pile.
func _hand_over(doc: String) -> void:
	c.hidden.erase(doc)
	if not c.docs.has(doc): c.docs.append(doc)
	docs.append({ "id": doc, "pos": Vector2(232, 128), "fresh": 1.6 })
	sfx("paper", 1.08)

# ------------------------------------------------------------------ the binder and the books

func _tabs_today() -> Array:
	var out: Array = []
	for t in CounterRules.TABS:
		if t == "MINISTRY" or CounterRules.rules_for(day).any(func(r): return r.tab == t): out.append(t)
	return out

## The tab with today's newest rule on it, so the binder opens where the news is.
func _newest_tab() -> int:
	var tabs := _tabs_today()
	var best := 0
	for r in CounterRules.rules_for(day):
		if tabs.has(r.tab): best = tabs.find(r.tab)
	return best

func _tab_step(dir: int) -> void:
	if book == "log" and DeskBook.old_log:
		log_old = not log_old
		return
	# the day-end sheet: LB/RB pull Gus's drawer open; in it, they move along the tools
	if phase == "day_end":
		open_drawer()
		return
	if phase == "drawer":
		drawer_sel = posmod(drawer_sel + dir, maxi(1, drawer_tools().size()))
		cur = _drawer_rect(drawer_sel).get_center()
		pad_cursor = true
		return
	if phase == "month_end":
		if dir > 0: _continue_overtime()
		return
	if phase == "brief" and story.is_empty() and fresh:
		# the eight weeks, then OVERTIME
		var at := WEEK_DAYS.size() if overtime else CounterRules.week_of(day) - 1
		week_pick = posmod(at + dir, WEEK_DAYS.size() + 1)
		if week_pick == WEEK_DAYS.size(): _pick_overtime()
		else:
			_leave_overtime()
			start_day(WEEK_DAYS[week_pick])
		return
	if CounterRules.binder(day): tab = posmod(tab + dir, _tabs_today().size())

func open_book(which: String) -> void:
	if not phase in ["idle", "counter"]: return
	book = "" if book == which else which
	pick_a = {} if not inspecting else pick_a
	drag = -1
	sfx("page", 1.0 if book != "" else 1.15, 0.0 if book != "" else -4.0)

# ------------------------------------------------------------------ input

func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		cur = get_global_mouse_position()
		pad_cursor = false
		if drag >= 0: _drag_to(cur)
		_drawer_hover()
		_pointer()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		cur = get_global_mouse_position()
		if e.pressed: press()
		else: drag = -1
		_pointer()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		_toggle_inspect()

## The mouse pointer: a closed hand while a paper's being dragged, a finger over something to
## press or pick up, the arrow otherwise.
func _pointer() -> void:
	var shape := Input.CURSOR_ARROW
	if drag >= 0: shape = Input.CURSOR_DRAG
	else:
		for i in BUTTONS.size():
			if _button_rect(i).has_point(cur): shape = Input.CURSOR_POINTING_HAND
		if phase == "counter" and book == "" and not inspecting and _doc_at(cur) >= 0: shape = Input.CURSOR_POINTING_HAND
		if inspecting and not field_at(cur).is_empty(): shape = Input.CURSOR_POINTING_HAND
	Input.set_default_cursor_shape(shape)

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _process(dt: float) -> void:
	_move_cursor(dt)
	if Input.is_action_just_pressed("desk_click"): press()
	if Input.is_action_just_released("desk_click"): drag = -1
	if Input.is_action_just_pressed("inspect"): _toggle_inspect()
	if Input.is_action_just_pressed("desk_ask"): ask_next()
	if Input.is_action_just_pressed("desk_cancel"): _cancel()
	if Input.is_action_just_pressed("desk_notebook"): open_book("notebook")
	if Input.is_action_just_pressed("desk_log"): open_book("log")
	if Input.is_action_just_pressed("desk_tab_prev"): _tab_step(-1)
	if Input.is_action_just_pressed("desk_tab_next"): _tab_step(1)
	if Input.is_action_just_pressed("desk_snap_next"): snap(1)
	if Input.is_action_just_pressed("desk_snap_prev"): snap(-1)
	if Input.is_action_just_pressed("desk_relax"): toggle_relaxed()
	for b in BUTTONS:
		if b.id != "INSPECT" and Input.is_action_just_pressed(b.key): stamp(b.id)
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("ui_back_pad"):
		if inspecting or book != "" or phase == "drawer": _cancel()
		else: _quit()
	tick(dt)
	if phase == "stamping":
		stamp_t -= dt
		if stamp_t <= 0.0: _resolve()
	if not verdict.is_empty():
		verdict.t -= dt
		if verdict.t <= 0.0: verdict = {}
	for d in docs: d.fresh = maxf(0.0, float(d.fresh) - dt)
	queue_redraw()

## The left stick, or the arrow keys, push the cursor around (and whatever it's dragging).
func _move_cursor(dt: float) -> void:
	var stick := Controls.stick()
	var keys := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
	var move := Vector2.ZERO
	if stick.length() > 0.2: move = stick * stick.length() * 260.0
	elif keys != Vector2.ZERO: move = keys.normalized() * 170.0
	if move == Vector2.ZERO: return
	pad_cursor = true
	cur = (cur + move * dt).clamp(Vector2.ZERO, Vector2(639, 359))
	if drag >= 0: _drag_to(cur)
	_drawer_hover()

func press() -> void:
	match phase:
		"brief":
			fresh = false
			phase = "idle"
			return
		"result":
			if clock >= CounterRules.SHIFT_LEN: close_up()
			else: next_customer()
			return
		"day_end":
			if drawer_armed and DRAWER_HANDLE.has_point(cur) and not drawer_tools().is_empty(): open_drawer()
			else: end_day()
			return
		"drawer":
			_drawer_press()
			return
		"week_end":
			_after_week()
			return
		"month_end", "revoked":
			_quit()
			return
		"stamping":
			return
	# idle or at the counter
	if book != "":
		if book == "log" and _log_tab_rect().has_point(cur):
			_tab_step(1)
			return
		if not BOOK.has_point(cur) and not _shelf_hit() and not inspecting:
			book = ""
			return
	for i in BUTTONS.size():
		if _button_rect(i).has_point(cur):
			if BUTTONS[i].id == "INSPECT": _toggle_inspect()
			else: stamp(BUTTONS[i].id)
			return
	for row in _ask_rows():
		if row.r.has_point(cur):
			ask(row.topic)
			return
	if CounterRules.binder(day):
		var tabs := _tabs_today()
		for i in tabs.size():
			if _tab_rect(i, tabs.size()).has_point(cur):
				tab = i
				return
	if inspecting:
		var f := field_at(cur)
		if not f.is_empty(): pick(f)
		return
	if NOTEBOOK_ICON.has_point(cur):
		open_book("notebook")
		return
	if LOG_ICON.has_point(cur):
		open_book("log")
		return
	if book != "" or phase != "counter": return
	var d := _doc_at(cur)
	if d >= 0:
		d = _raise(d)
		drag = d
		drag_off = cur - docs[d].pos
		sfx("paper", 1.2, -6.0)

func _shelf_hit() -> bool:
	return NOTEBOOK_ICON.has_point(cur) or LOG_ICON.has_point(cur)

func _toggle_inspect() -> void:
	if not phase in ["counter", "idle"]: return
	inspecting = not inspecting
	pick_a = {}

func _cancel() -> void:
	if inspecting and not pick_a.is_empty(): pick_a = {}
	elif inspecting: inspecting = false
	elif book != "": book = ""
	elif phase == "drawer": phase = "day_end"

## Jump the cursor to the next (or previous) thing worth pointing at, in reading order.
func snap(dir: int) -> void:
	var pts := targets()
	if pts.is_empty(): return
	pts.sort_custom(func(a, b): return _order_key(a) < _order_key(b))
	var k := _order_key(cur)
	var to: Vector2 = pts[0] if dir > 0 else pts[pts.size() - 1]
	if dir > 0:
		for p in pts:
			if _order_key(p) > k + 0.5:
				to = p
				break
	else:
		for i in range(pts.size() - 1, -1, -1):
			if _order_key(pts[i]) < k - 0.5:
				to = pts[i]
				break
	cur = to
	pad_cursor = true
	_drawer_hover()

func _order_key(p: Vector2) -> float:
	return floorf(p.y / 10.0) * 1000.0 + p.x

## Everything the cursor can usefully land on right now.
func targets() -> Array:
	var out: Array = []
	if phase == "drawer":
		for i in drawer_tools().size(): out.append(_drawer_rect(i).get_center())
		out.append(_drawer_shut_rect().get_center())
		return out
	if inspecting:
		for f in fields(): out.append((f.r as Rect2).get_center().round())
		return out
	if phase == "counter" and book == "":
		for d in docs: out.append((d.pos as Vector2) + Vector2(24, 4))
	for i in BUTTONS.size(): out.append(_button_rect(i).get_center())
	for row in _ask_rows(): out.append((row.r as Rect2).get_center())
	if CounterRules.binder(day):
		var n := _tabs_today().size()
		for i in n: out.append(_tab_rect(i, n).get_center())
	out.append(NOTEBOOK_ICON.get_center())
	out.append(LOG_ICON.get_center())
	return out

func _drag_to(p: Vector2) -> void:
	var size := _doc_size(docs[drag].id)
	var np: Vector2 = p - drag_off
	np.x = clampf(np.x, DESK.position.x - size.x * 0.4, DESK.end.x - size.x * 0.6)
	np.y = clampf(np.y, DESK.position.y, DESK.end.y - 16)
	docs[drag].pos = np.round()

func _raise(i: int) -> int:
	var d: Dictionary = docs[i]
	docs.remove_at(i)
	docs.append(d)
	return docs.size() - 1

func _doc_index(id: String) -> int:
	for i in docs.size():
		if docs[i].id == id: return i
	return -1

func _doc_at(p: Vector2) -> int:
	for i in range(docs.size() - 1, -1, -1):
		if Rect2(docs[i].pos, _doc_size(docs[i].id)).has_point(p): return i
	return -1

func _button_rect(i: int) -> Rect2:
	return Rect2(TRAY.position.x + 4 + i * 63, TRAY.position.y + 6, 59, 40)

# ------------------------------------------------------------------ fields and comparing

## Every fact on screen you can pick: {r, key, val, doc, row, label}. Papers in front win.
func fields() -> Array:
	var out: Array = []
	if not phase in ["counter", "idle"]: return out
	if book != "": out.append_array(_book_fields())
	elif phase == "counter":
		for i in range(docs.size() - 1, -1, -1): out.append_array(_doc_fields(docs[i]))
	var audit: bool = phase == "counter" and c.kind == "audit"
	if phase == "counter":
		var bub := _bubble()
		out.append({ "r": bub.r, "key": "says", "val": { "text": bub.text, "clue": bub.clue }, "doc": "", "label": "WHAT THEY SAID" })
		out.append({ "r": _face_rect(), "key": "person", "val": c.face_shown, "doc": "", "label": "INSPECTOR HACHEY" if audit else "THE PERSON AT THE COUNTER" })
		# a pulled file: the car's long gone, and its day is the date on the work order
		if not audit: out.append({ "r": _plate_rect(), "key": "plate", "val": c.car.plate, "doc": "car", "row": "PLATE", "label": "THE PLATE ON THE CAR" })
	if not audit: out.append({ "r": Rect2(474, 4, 54, 42), "key": "today", "val": CounterRules.today(day), "doc": "", "label": "TODAY" })
	for blk in _rule_blocks():
		if blk.has("rule"): out.append({ "r": blk.r, "key": "rule", "val": blk.rule.id, "doc": "", "label": "THE RULE: " + String(blk.lines[0]) })
	if CounterRules.rule_active("bolo", jday()):
		out.append({ "r": _bolo_rect(), "key": "bolo", "val": 0, "doc": "", "label": "THE STOLEN LIST FROM THAT WEEK" if _filed() else "THE STOLEN LIST" })
	out.append({ "r": NOTEBOOK_ICON, "key": "notebook", "val": 0, "doc": "", "label": "LEO'S NOTEBOOK" })
	return out

func field_at(p: Vector2) -> Dictionary:
	# the top paper under the cursor hides the ones under it
	var top := _doc_at(p) if book == "" else -1
	for f in fields():
		if f.r.has_point(p):
			if f.get("doc", "") in docs.map(func(d): return d.id) and top >= 0 and f.doc != docs[top].id: continue
			return f
	return {}

func pick(f: Dictionary) -> void:
	if pick_a.is_empty():
		pick_a = f
		return
	if pick_a.r == f.r:
		# the same thing twice: a tool out of Gus's drawer reads it (or, with nothing that reads
		# it, Leo puts it back down)
		use_tool(f)
		pick_a = {}
		return
	var v := compare(pick_a, f)
	_say(v, { "a": pick_a, "b": f })
	pick_a = {}

## A verdict on the desk (and a red one puts its question on the ASK list).
func _say(v: Array, at: Dictionary) -> void:
	verdict = { "a": at.a, "b": at.b, "text": v[0], "good": v[1], "t": 4.0 }
	if v.size() > 3: verdict.tool = String(v[3])
	if v[1] == false and String(v[2]) != "":
		topics.erase(v[2])
		topics.push_front(v[2])

## A tool on one fact: the tread gauge, the date wheel, the loupe or the UV lamp, whichever
## reads it (DeskTools). False if none of Leo's does.
func use_tool(f: Dictionary) -> bool:
	if c.is_empty(): return false
	var v := DeskTools.read(c, jday(), bolo_now(), f, DeskBook.tools)
	if v.is_empty(): return false
	_say(v, { "a": f, "b": f })
	if String(f.key) == "seal": lit[String(f.val)] = v[1] == true
	sfx("page", 1.3, -8.0)
	return true

## Leo reads two things side by side: [what he concludes, good (true/false/null), ASK topic].
## The papers, the wall and the window go to the rules; what people say goes in the notebook;
## the sticker log is checked for gaps.
func compare(a: Dictionary, b: Dictionary) -> Array:
	var pair := [a.key, b.key]
	if pair.has("says"):
		var s: Dictionary = a if a.key == "says" else b
		var o: Dictionary = b if a.key == "says" else a
		if o.key in ["notebook", "note"]: return _jot(s.val)
		return ["NOTHING TO COMPARE", null, ""]
	if a.key == "sticker" and b.key == "sticker": return _sticker_gap(int(a.val), int(b.val))
	return CounterRules.compare(c, jday(), bolo_now(), a, b)

## Something somebody said, against the notebook: write it down, or catch them out.
func _jot(v: Dictionary) -> Array:
	var clue: Dictionary = v.get("clue", {})
	if clue.is_empty(): return ["NOTHING WORTH WRITING DOWN", null, ""]
	var id := String(clue.get("id", ""))
	if clue.has("catch") and DeskBook.has_note(String(clue.catch)):
		DeskBook.raise("desk_caught_" + id)
		return ["THAT'S NOT WHAT THE BOOK SAYS", false, ""]
	if DeskBook.note(id, String(clue.get("note", v.get("text", ""))), day): return ["WRITTEN IN THE NOTEBOOK", true, ""]
	return ["ALREADY IN THE NOTEBOOK", null, ""]

## Two stickers from the log: anything missing between them?
func _sticker_gap(a: int, b: int) -> Array:
	var missing := DeskBook.gap(a, b, log_old)
	if missing.is_empty(): return ["IN ORDER", true, ""]
	if log_old and missing.has(448):
		DeskBook.note("sticker_gap", DeskBook.GAP_NOTE, day)
		DeskBook.raise("desk_sticker_gap")
	return ["%04d IS MISSING" % int(missing[0]) if missing.size() == 1 else "%d STICKERS MISSING" % missing.size(), false, ""]

# ------------------------------------------------------------------ documents

const DOC_W := 160.0
const PAPER := { "work": Color("efe2b0"), "reg": Color("cfe0c4"), "licence": Color("c6d6e8"), "insurance": Color("ecd2cc"),
	"glovebox": Color("f2c6d6"), "sheet": Color("e8e6de"), "napkin": Color("f4f2ec"), "history": Color("dcd4f0"),
	"old_reg": Color("e8dcb8"), "bos": Color("f0ecd8"), "permit": Color("f4e08a"), "door_inv": Color("d8e8e8"),
	"cert": Color("e4ecd0"), "letter": Color("f6f0e2"), "exempt": Color("e0e8f4"), "order": Color("e4ecec"),
	"slip": Color("f0e6d0"), "customs": Color("e8d8e8"), "notice": Color("f4f0c8"), "invoice": Color("ece2cc") }

func _rows(id: String) -> Array:
	return CounterRules.doc_rows(c, id, jday())

func _doc_size(id: String) -> Vector2:
	match id:
		"licence": return Vector2(DOC_W, 58)
		"napkin": return Vector2(92, 18 + wrap_text(c.napkin, 20).size() * 8)
		"work", "slip": return Vector2(DOC_W, 14 + _rows(id).size() * 9 + 18)
		"letter": return Vector2(118, 16 + (c.letter.get("lines", []) as Array).size() * 8)
		"history": return Vector2(DOC_W + 12, 14 + _rows(id).size() * 9 + 4)
	return Vector2(DOC_W, 14 + _rows(id).size() * 9 + 4)

func _row_x(id: String) -> float:
	return 40.0 if id == "licence" else 4.0

func _title(id: String) -> String:
	var t := String(CounterRules.DOC_TITLES.get(id, ""))
	if id == "old_reg": t += " - " + String(c.old_reg.prov)
	if id == "slip": t += " - " + String(c.slip.supplier)
	if id == "work" and c.kind == "audit": t = "WORK ORDER %04d (FILE COPY)" % int(c.audit.no)
	return t

func _doc_fields(d: Dictionary) -> Array:
	var out: Array = []
	var rows := _rows(d.id)
	var x0 := _row_x(d.id)
	var size := _doc_size(d.id)
	# with the UV lamp, the seal's a thing to pick too (first, so it's what's under the cursor)
	if DeskBook.tools.has("lamp") and DeskTools.SEALED.has(String(d.id)):
		out.append({ "r": Rect2(d.pos + _seal_at(size) - Vector2(8, 8), Vector2(16, 16)), "key": "seal", "val": String(d.id),
			"label": "THE SEAL ON THE %s" % _title(d.id).split(" - ")[0], "doc": d.id, "row": "SEAL" })
	for i in rows.size():
		if rows[i][2] == "": continue
		out.append({ "r": Rect2(d.pos + Vector2(x0, 12 + i * 9), Vector2(size.x - x0 - 4, 8)), "key": rows[i][2], "val": rows[i][3],
			"label": "%s ON THE %s" % [rows[i][0], _title(d.id).split(" - ")[0]], "doc": d.id, "row": rows[i][0] })
	if d.id == "licence":
		out.append({ "r": Rect2(d.pos + Vector2(4, 13), Vector2(32, 32)), "key": "photo", "val": c.licence.face, "label": "THE LICENCE PHOTO", "doc": d.id, "row": "PHOTO" })
	return out

func _draw_doc(d: Dictionary) -> void:
	var size := _doc_size(d.id)
	var r := Rect2(d.pos, size)
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	var paper: Color = PAPER.get(d.id, Color("eeeeee"))
	draw_rect(r, paper)
	draw_rect(r, paper.darkened(0.35), false, 1.0)
	if float(d.get("fresh", 0.0)) > 0.0: draw_rect(r.grow(2), Color(GOLD, minf(1.0, float(d.fresh))), false, 2.0)
	match String(d.id):
		"napkin":
			for i in 6: draw_rect(Rect2(r.position + Vector2(4 + i * 15, 3), Vector2(8, 1)), paper.darkened(0.08))
			var ls := wrap_text(c.napkin, 20)
			for i in ls.size(): PixelFont.draw(self, r.position + Vector2(6, 9 + i * 8), ls[i], Color("2a3a7a"))
			return
		"letter":
			draw_rect(Rect2(r.position, Vector2(size.x, 11)), Color("1e2a3a"))
			PixelFont.draw_centered(self, r.get_center().x, r.position.y + 3, String(c.letter.get("title", "")), GOLD)
			var lines: Array = c.letter.get("lines", [])
			for i in lines.size(): PixelFont.draw(self, r.position + Vector2(6, 15 + i * 8), String(lines[i]), PAPER_INK)
			return
	draw_rect(Rect2(r.position, Vector2(size.x, 10)), paper.darkened(0.18))
	PixelFont.draw(self, r.position + Vector2(4, 3), _title(d.id), PAPER_INK)
	var rows := _rows(d.id)
	var x0 := _row_x(d.id)
	var lw := 32.0
	for row in rows: lw = maxf(lw, PixelFont.width(String(row[0])) + 4.0)
	if d.id == "history": lw = 48.0
	for i in rows.size():
		var p: Vector2 = r.position + Vector2(x0, 14 + i * 9)
		PixelFont.draw(self, p, rows[i][0], PAPER_DIM)
		PixelFont.draw(self, p + Vector2(lw, 0), str(rows[i][1]), RED.darkened(0.3) if rows[i][2] == "brand" and rows[i][3] == "SALVAGE" else PAPER_INK)
	match String(d.id):
		"licence":
			draw_rect(Rect2(r.position + Vector2(3, 12), Vector2(34, 34)), paper.darkened(0.3))
			draw_texture(_face_tex(c.licence.face, true), r.position + Vector2(4, 13))
		"permit", "cert", "door_inv", "bos", "glovebox", "exempt", "notice", "customs", "invoice":
			# a stamp or a seal: real ones and fakes look the same from here (under the UV lamp, they don't)
			_draw_seal(r.position + _seal_at(size), paper, String(d.id))
	if String(d.id) == _stamp_doc(): _draw_stamp_box(r, paper)

## Where a paper's seal sits, from its top-left corner.
func _seal_at(size: Vector2) -> Vector2:
	return Vector2(size.x - 14, size.y - 12)

## A seal: a faint ring; a violet one once the UV lamp's in the drawer; lit up (or dead) once
## the lamp's been on it.
func _draw_seal(at: Vector2, paper: Color, id: String) -> void:
	if lit.has(id):
		if lit[id]:
			draw_circle(at, 10.0, Color(UV, 0.25))
			draw_circle(at, 7.0, Color(UV, 0.85))
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(at + Vector2(cos(a), sin(a)) * 8.0, at + Vector2(cos(a), sin(a)) * 11.0, Color(UV, 0.7), 1.0)
			draw_circle(at, 7.0, Color.WHITE, false, 1.0)
		else:
			draw_circle(at, 7.0, Color(0.16, 0.14, 0.2, 0.75))
			draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), RED, 1.0)
			draw_line(at + Vector2(4, -4), at + Vector2(-4, 4), RED, 1.0)
		return
	var ring := Color(UV.darkened(0.2), 0.8) if DeskBook.tools.has("lamp") else Color(paper.darkened(0.35), 0.5)
	draw_circle(at, 7.0, ring, false, 1.0)

## The box the stamp lands in. On a pulled file, Hachey's thumb is over the old one.
func _draw_stamp_box(r: Rect2, paper: Color) -> void:
	var box := Rect2(r.position + Vector2(r.size.x - 70, r.size.y - 17), Vector2(66, 14))
	draw_rect(box, paper.darkened(0.12))
	if stamped == "":
		var audit: bool = c.kind == "audit"
		var box_word := ("SIGN AGAIN" if audit else "SIGN HERE") if c.has("slip") else ("STAMP AGAIN" if audit else "STAMP HERE")
		PixelFont.draw_centered(self, box.get_center().x, box.position.y + 5, box_word, PAPER_DIM)
		if audit:
			# the thumb, on the old stamp
			var th := Rect2(box.position + Vector2(-46, 0), Vector2(40, 14))
			draw_rect(th, paper.darkened(0.12))
			draw_rect(Rect2(th.position + Vector2(4, 2), Vector2(32, 10)), Color("d8a888"))
			draw_rect(Rect2(th.position + Vector2(26, 3), Vector2(8, 8)), Color("ecc8b0"))
		return
	var col: Color = Color("2f7a2a") if stamped == "APPROVED" else (Color("a8282a") if stamped == "DENIED" else (Color("2a4a8a") if stamped == "REPORT" else Color("3a3438")))
	draw_rect(box.grow(1), col, false, 2.0)
	var word: String = (BOX_WORD if c.has("slip") else STAMP_WORD)[stamped]
	PixelFont.draw_centered(self, box.get_center().x, box.position.y + 3, word, col, 2 if PixelFont.width(word, 2) <= box.size.x - 2 else 1)

# ------------------------------------------------------------------ the books

func _book_rows() -> Array:
	var out: Array = []
	if book == "notebook":
		for n in DeskBook.notes:
			var d := CounterRules.today(int(n.day))
			out.append({ "key": "note", "val": n.id, "head": "%s %d" % [CounterRules.MONTHS[d[1] - 1], d[2]], "lines": wrap_text(String(n.text), 62) })
	else:
		for r in DeskBook.log_rows(log_old):
			out.append({ "key": "sticker", "val": int(r.no), "head": "%04d" % int(r.no),
				"lines": ["%s   %-8s %s" % [CounterRules.date_str(r.date), r.plate, r.car]] })
	return out

## Where each book row sits: [{r, row}], the newest pages last (and only as many as fit).
func _book_layout() -> Array:
	var out: Array = []
	var y := BOOK.position.y + 26
	var rows := _book_rows()
	var lh := 8.0
	var fit: Array = []
	var total := 0.0
	for i in range(rows.size() - 1, -1, -1):
		var h: float = (rows[i].lines as Array).size() * lh + (0.0 if book == "notebook" else 3.0)
		if total + h > BOOK.size.y - 40: break
		total += h
		fit.push_front(rows[i])
	for row in fit:
		var h: float = (row.lines as Array).size() * lh + (0.0 if book == "notebook" else 3.0)
		out.append({ "r": Rect2(BOOK.position.x + 8, y, BOOK.size.x - 16, h - 2), "row": row })
		y += h
	return out

func _book_fields() -> Array:
	var out: Array = []
	for e in _book_layout():
		var row: Dictionary = e.row
		var label := ("THE NOTE FROM " if book == "notebook" else "STICKER ") + String(row.head)
		out.append({ "r": e.r, "key": row.key, "val": row.val, "doc": book, "label": label })
	return out

func _log_tab_rect() -> Rect2:
	return Rect2(BOOK.end.x - 108, BOOK.position.y + 4, 100, 11)

func _draw_book() -> void:
	draw_rect(Rect2(BOOK.position + Vector2(3, 3), BOOK.size), Color(0, 0, 0, 0.45))
	var nb := book == "notebook"
	var paper := Color("efe8d0") if nb else Color("e4e2d8")
	draw_rect(BOOK, paper)
	draw_rect(BOOK, paper.darkened(0.4), false, 1.0)
	if nb:
		for i in 19: draw_rect(Rect2(BOOK.position.x + 2, BOOK.position.y + 33 + i * 8, BOOK.size.x - 4, 1), Color("b8c8d8"))
		draw_rect(Rect2(BOOK.position.x + 40, BOOK.position.y, 1, BOOK.size.y), Color("d89090"))
		for i in 10: draw_circle(Vector2(BOOK.position.x + 6, BOOK.position.y + 14 + i * 18), 2.0, Color("2a2420"))
		PixelFont.draw(self, BOOK.position + Vector2(46, 8), "LEO'S NOTEBOOK", Color("2a3a7a"), 2)
	else:
		draw_rect(Rect2(BOOK.position, Vector2(BOOK.size.x, 18)), Color("3a4a3a"))
		PixelFont.draw(self, BOOK.position + Vector2(6, 6), "INSPECTION STICKERS - STATION 0117", BONE)
		var tab_r := _log_tab_rect()
		if DeskBook.old_log:
			draw_rect(tab_r, Color("e4e2d8") if log_old else Color("5a6a5a"))
			PixelFont.draw_centered(self, tab_r.get_center().x, tab_r.position.y + 3, "LAST FALL (2018)" if log_old else "THIS FALL (2019)", PAPER_INK if log_old else BONE)
	var lay := _book_layout()
	if lay.is_empty():
		var empty := "NOTHING YET. GUS SAYS WRITE DOWN ANYTHING THAT DOESN'T SIT RIGHT. (INSPECT WHAT SOMEBODY SAYS, THEN THIS NOTEBOOK.)" if nb else "NO STICKERS ISSUED YET. APPROVE AN INSPECTION AND IT GOES IN HERE."
		var ls := wrap_text(empty, 56)
		for i in ls.size(): PixelFont.draw(self, BOOK.position + Vector2(46, 26 + i * 8), ls[i], PAPER_DIM)
	for e in lay:
		var row: Dictionary = e.row
		var r: Rect2 = e.r
		PixelFont.draw(self, r.position + Vector2(6 if nb else 0, 0), String(row.head), Color("a8282a") if nb else PAPER_INK)
		var lines: Array = row.lines
		for i in lines.size(): PixelFont.draw(self, r.position + Vector2(38 if nb else 26, i * 8), String(lines[i]), Color("2a3a7a") if nb else PAPER_INK)
	var foot := Hints.fmt("{desk_cancel}: CLOSE  {desk_tab_next}: OTHER PAGES") if not nb and DeskBook.old_log else Hints.fmt("{desk_cancel}: CLOSE")
	PixelFont.draw(self, Vector2(BOOK.position.x + 36, BOOK.end.y - 10), foot, PAPER_DIM)

# ------------------------------------------------------------------ drawing

## The customer's face (or the licence photo): a CAGE BOSS-style portrait that matches the
## person's sex and the age on the date of birth.
func _face_tex(face_seed: int, small := false) -> ImageTexture:
	var fem := int(c.person.get("fem", 0))
	var age := face_age()
	return Face.small_texture(face_seed, fem, age) if small else Face.texture(face_seed, fem, age)

## How old the customer looks: their age on the date on the papers (in overtime, a year or two
## on from the run, and a birthday at a time).
func face_age() -> int:
	return CounterRules.age_on(c.person.dob, jday())

## Who's at the window: the customer, or (with a pulled file) Inspector Hachey.
func _window_tex() -> ImageTexture:
	var w: Dictionary = c.get("window", {})
	if w.is_empty(): return _face_tex(c.face_shown)
	return Face.texture(int(w.face), int(w.fem), window_age())

## How old whoever's at the window looks: the customer, or Hachey as old as he is today.
func window_age() -> int:
	var w: Dictionary = c.get("window", {})
	return face_age() if w.is_empty() else CounterRules.age_on(w.dob, day)

func _face_rect() -> Rect2:
	return Rect2(11, 10, 128, 128)   # the 64px portrait at 2x, above the counter top (y 142)

func _plate_rect() -> Rect2:
	return Rect2(WINDOW.position.x + 18, 84, 56, 20)

func _bolo_rect() -> Rect2:
	return Rect2(476, 236, 158, 76)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("1c1a1e"))
	_draw_booth()
	_draw_window()
	_draw_wall()
	# desk
	draw_rect(DESK, Color("5a4232"))
	for i in 12: draw_line(Vector2(DESK.position.x, DESK.position.y + 8 + i * 16), Vector2(DESK.end.x, DESK.position.y + 10 + i * 16), Color("4e382a"), 1.0)
	if phase in ["counter", "stamping", "result"]:
		for d in docs: _draw_doc(d)
	if phase == "idle" and book == "":
		PixelFont.draw_centered(self, DESK.get_center().x, DESK.get_center().y - 4, "NOBODY AT THE WINDOW.", Color(BONE, 0.5), 2)
		PixelFont.draw_centered(self, DESK.get_center().x, DESK.get_center().y + 14, "GUS IS READING THE FLYER AGAIN.", Color(BONE, 0.4))
	if book != "": _draw_book()
	_draw_tray()
	if phase in ["counter", "stamping", "idle"]: _draw_inspect()
	match phase:
		"brief": _draw_brief()
		"result": _draw_result()
		"day_end": _draw_day_end()
		"drawer": _draw_drawer()
		"week_end": _draw_week_end()
		"month_end": _draw_month_end()
		"revoked": _draw_revoked()
	if tutorial and phase in ["counter", "stamping"] and served < TIPS.size():
		var ls := wrap_text(Hints.fmt(TIPS[served]), 74)
		_panel(Rect2(150, 32, 320, 6 + ls.size() * 8), 0.92)
		for k in ls.size(): PixelFont.draw(self, Vector2(156, 35 + k * 8), ls[k], Color("c8c0a8"))
	if pad_cursor or demo: _draw_cursor()

func _panel(r: Rect2, a := 0.9) -> void:
	draw_rect(r, Color(0.04, 0.035, 0.05, a))
	draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)

## What the customer's saying right now: their opener, or the answer to the last question.
## {r, lines: [[text, colour]], text, clue}
func _bubble() -> Dictionary:
	var lines: Array = []
	var text := ""
	var clue: Dictionary = {}
	if said.is_empty():
		text = _speech()
		clue = c.get("clue", {})
	else:
		for l in wrap_text("LEO: " + String(said.q), 33): lines.append([l, Color("8a6a20")])
		text = String(said.a)
		clue = said.get("clue", {})
	for l in wrap_text(text, 33): lines.append([l, INK])
	return { "r": Rect2(6, 156, 138, 8 + lines.size() * 8), "lines": lines, "text": text, "clue": clue }

func _speech() -> String:
	var s := String(c.get("says", ""))
	if s == "":
		match c.kind:
			"familia": s = "DOM SENT ME. HE SAYS YOU'D UNDERSTAND THE NAPKIN."
			"sting": s = "HEY. A BUDDY SAID YOU CAN HELP ME OUT. I GOT CASH."
			_:
				var asks := { "SAFETY INSPECTION": "HI. I NEED A SAFETY INSPECTION.", "FULL INSPECTION": "HI. THE REGISTRY SAYS I NEED THE FULL INSPECTION.",
					"OIL CHANGE": "JUST AN OIL CHANGE, PLEASE.", "BRAKE JOB": "MY BRAKES ARE GRINDING. CAN YOU DO A BRAKE JOB?",
					"WINTER TIRES ON": "HI. I NEED MY WINTER TIRES PUT ON.", "SUMMER TIRES ON": "HI. WINTERS OFF, SUMMERS ON, PLEASE. I'M DONE WITH WINTER.",
					"CHECK ENGINE LIGHT": "MY CHECK ENGINE LIGHT IS ON. AGAIN." }
				s = String(asks.get(c.request, "HI."))
	if since - float(c.get("arrived", since)) > 120.0: s = "FINALLY. " + s
	return s

## The questions under the speech bubble: [{r, topic}].
func _ask_rows() -> Array:
	var out: Array = []
	if phase != "counter" or c.is_empty(): return out
	var y: float = _bubble().r.end.y + 18
	for t in ask_list().slice(0, 6):
		out.append({ "r": Rect2(6, y, 138, 10), "topic": t })
		y += 11
	return out

func _draw_booth() -> void:
	draw_rect(BOOTH, Color("2a2a32"))
	draw_rect(Rect2(0, 0, 150, 150), Color("3a3a44"))
	for i in 7: draw_rect(Rect2(0, i * 22, 150, 1), Color("34343c"))
	if phase in ["counter", "stamping", "result"]:
		draw_texture_rect(_window_tex(), _face_rect(), false)
		if String(c.get("mask", "")) != "": _draw_mask(String(c.mask))
		# the counter top and the glass
		draw_rect(Rect2(0, 142, 150, 8), Color("6a5a48"))
		draw_rect(Rect2(8, 8, 134, 134), Color(0.7, 0.85, 1.0, 0.06))
		draw_line(Vector2(20, 14), Vector2(48, 42), Color(1, 1, 1, 0.12), 2.0)
		var bub := _bubble()
		var br: Rect2 = bub.r
		draw_rect(br, BONE)
		draw_colored_polygon(PackedVector2Array([Vector2(60, br.position.y), Vector2(76, br.position.y), Vector2(70, br.position.y - 8)]), BONE)
		var lines: Array = bub.lines
		for i in lines.size(): PixelFont.draw(self, br.position + Vector2(5, 5 + i * 8), String(lines[i][0]), lines[i][1])
		if not (bub.clue as Dictionary).is_empty(): draw_rect(br.grow(1), Color(GOLD, 0.5 + 0.3 * sin(Time.get_ticks_msec() / 300.0)), false, 1.0)
		var rows := _ask_rows()
		if not rows.is_empty():
			PixelFont.draw(self, Vector2(6, rows[0].r.position.y - 10), Hints.fmt("{desk_ask}: ASK"), GOLD)
			for row in rows:
				var r: Rect2 = row.r
				var done: bool = asked.has(row.topic)
				var hot: bool = r.has_point(cur) and phase == "counter"
				var proven: bool = topics.has(row.topic)
				draw_rect(r, Color("4a3a2a") if hot else Color("33302e"))
				draw_rect(Rect2(r.position, Vector2(2, r.size.y)), RED if proven else ASH)
				PixelFont.draw(self, r.position + Vector2(6, 2), String(CounterRules.TOPIC_LABEL.get(row.topic, row.topic)), Color(BONE, 0.45) if done else BONE)
				if done: PixelFont.draw(self, r.position + Vector2(r.size.x - 22, 2), "ASKED", Color(ASH, 0.8))
	elif phase == "idle":
		draw_rect(Rect2(0, 142, 150, 8), Color("6a5a48"))
		PixelFont.draw_centered(self, 75, 64, "NEXT!", ASH, 2)
		PixelFont.draw_centered(self, 75, 84, "(NOBODY)", Color(ASH, 0.6))
	else:
		draw_rect(Rect2(0, 142, 150, 8), Color("6a5a48"))
		PixelFont.draw_centered(self, 75, 70, "CLOSED", ASH, 2)
	if phase in ["idle", "counter", "stamping", "result"]:
		if overtime: PixelFont.draw(self, Vector2(6, 330), "SERVED %d  LOT %d  STREAK %d" % [served, waiting.size(), int(DeskBook.overtime.get("streak", 0))], ASH)
		else: PixelFont.draw(self, Vector2(6, 330), "SERVED %d   IN THE LOT %d" % [served, waiting.size()], ASH)
	PixelFont.draw(self, Vector2(6, 342), Hints.fmt("{inspect}: INSPECT  {desk_snap_next}: NEXT THING") if Hints.pad else Hints.fmt("{desk_notebook}: NOTEBOOK  {desk_log}: LOG"), Color(ASH, 0.7))
	PixelFont.draw(self, Vector2(6, 351), Hints.fmt("{menu_back}: MENU"), Color(ASH, 0.6))

## Halloween: whatever's over their face, drawn over the portrait at the portrait's 2x.
func _draw_mask(kind: String) -> void:
	var o := _face_rect().position
	var px := func(x: int, y: int, w: int, h: int, col: Color) -> void:
		draw_rect(Rect2(o + Vector2(x * 2, y * 2), Vector2(w * 2, h * 2)), col)
	match kind:
		"GOALIE":
			for y in range(9, 52):
				var hw := int(15.0 * sqrt(maxf(0.0, 1.0 - pow((y - 29.0) / 22.0, 2.0))))
				px.call(32 - hw, y, hw * 2, 1, Color("ece8dc") if y > 12 else Color("d8d2c4"))
			px.call(22, 24, 8, 4, INK)
			px.call(35, 24, 8, 4, INK)
			for i in 4: px.call(25 + i * 4, 40, 2, 3, INK)
			px.call(31, 12, 2, 10, Color("b8302a"))
		"PUMPKIN":
			for y in range(10, 54):
				var hw := int(20.0 * sqrt(maxf(0.0, 1.0 - pow((y - 32.0) / 22.0, 2.0))))
				px.call(32 - hw, y, hw * 2, 1, Color("e07a1e") if posmod(floori(y / 3.0), 2) == 0 else Color("d06a14"))
			px.call(30, 6, 4, 5, Color("3a5a2a"))
			for i in 4: px.call(22 + i, 26 - i, 8 - i * 2, 1, INK)
			for i in 4: px.call(36 + i, 26 - i, 8 - i * 2, 1, INK)
			px.call(22, 38, 20, 3, INK)
			px.call(26, 41, 4, 2, INK)
			px.call(34, 41, 4, 2, INK)
		_:
			px.call(10, 8, 44, 56, Color("eeeeea"))
			px.call(12, 6, 40, 2, Color("eeeeea"))
			px.call(22, 24, 6, 8, INK)
			px.call(36, 24, 6, 8, INK)
			px.call(29, 40, 6, 6, INK)

func _draw_window() -> void:
	draw_rect(WINDOW, Color("6a6c70"))
	# the bay: concrete, a drain, the lift posts, the window frame
	draw_rect(Rect2(WINDOW.position + Vector2(0, 32), Vector2(WINDOW.size.x, 80)), Color("8a8a86"))
	for i in 8: draw_rect(Rect2(WINDOW.position.x + i * 40 + 6, 34, 1, 76), Color("7e7e7a"))
	draw_rect(Rect2(WINDOW.position.x + 60, 38, 6, 56), Color("c8a030"))
	draw_rect(Rect2(WINDOW.position.x + 236, 38, 6, 56), Color("c8a030"))
	_draw_lot()
	if phase in ["counter", "stamping", "result"] and c.kind == "audit":
		var box: bool = c.has("slip")
		PixelFont.draw_centered(self, WINDOW.get_center().x, 60, "MINISTRY AUDIT: %s %04d, %s" % ["PACKING SLIP" if box else "WORK ORDER", int(c.audit.no),
			CounterRules.date_str(CounterRules.today(int(c.audit.day)))], INK)
		PixelFont.draw_centered(self, WINDOW.get_center().x, 72, "THE VAN'S LONG GONE. THE PAPERS AREN'T." if box else "THE CAR'S LONG GONE. THE PAPERS AREN'T.", Color("3a3a40"))
		PixelFont.draw_centered(self, WINDOW.get_center().x, 84, "THE SIGNATURE'S UNDER HACHEY'S THUMB." if box else "THE STAMP'S UNDER HACHEY'S THUMB.", Color("3a3a40"))
	elif phase in ["counter", "stamping", "result"]:
		var pr := _plate_rect()
		draw_rect(pr, Color("e8e4d4"))
		draw_rect(pr, Color("2a4a8a"), false, 1.0)
		PixelFont.draw_centered(self, pr.get_center().x, pr.position.y + 2, "PORT RUMBLE", Color("2a4a8a"))
		PixelFont.draw_centered(self, pr.get_center().x, pr.position.y + 9, c.car.plate, INK, 1)
		draw_rect(Rect2(pr.position + Vector2(3, 16), Vector2(pr.size.x - 6, 1)), Color("2a4a8a"))
		draw_line(pr.position + Vector2(56, 10), Vector2(car_view.position.x - float(c.car.len) * 9.0, car_view.position.y), Color(1, 1, 1, 0.25), 1.0)
		PixelFont.draw(self, WINDOW.position + Vector2(96, 100), "%d %s %s" % [int(c.car.year), c.car.make, c.car.model], BONE)
		# what the catalogue knows about this one, the first thing anybody notices in the bay
		var quirk := String(c.car.get("quirk", ""))
		if quirk != "":
			if quirk.length() > 76: quirk = quirk.substr(0, 73) + "..."
			PixelFont.draw_centered(self, WINDOW.get_center().x, 36, quirk, Color("3a3a40"))
	draw_rect(WINDOW, Color("2a2a30"), false, 3.0)

## The lot through the bay door's windows: the line, nose to tail, first in line nearest the door.
func _draw_lot() -> void:
	draw_rect(LOT, Color("2e3036"))
	var glass := Rect2(LOT.position + Vector2(4, 3), Vector2(LOT.size.x - 8, LOT.size.y - 5))
	draw_rect(glass, Color("6c7a88"))
	draw_rect(Rect2(glass.position.x, glass.end.y - 6, glass.size.x, 6), Color("4a4c50"))
	for i in range(1, 5): draw_rect(Rect2(glass.position.x + i * glass.size.x / 5.0, glass.position.y, 2, glass.size.y), Color("2e3036"))
	var x := glass.end.x - 6.0
	var shown := 0
	for i in waiting.size():
		var w: Dictionary = waiting[i]
		var tex := _queue_tex(w)
		var bob := -1.0 if i == 0 and honk_t > 0.0 and int(honk_t * 12.0) % 2 == 0 else 0.0
		x -= float(w.get("_qlen", 30))
		if x < glass.position.x + 30:
			PixelFont.draw(self, Vector2(glass.position.x + 4, glass.position.y + 3), "+%d" % (waiting.size() - shown), BONE)
			break
		draw_texture(tex, Vector2(x - 22, glass.end.y - 3 - (tex.get_height() - 8) + bob))
		shown += 1
		x -= 5.0
	if honk_t > 0.0 and not waiting.is_empty():
		var hx := glass.end.x - 40
		draw_rect(Rect2(hx, glass.position.y + 1, 30, 9), RED)
		PixelFont.draw(self, Vector2(hx + 3, glass.position.y + 3), "HONK!", BONE)
	if waiting.is_empty() and phase in ["idle", "counter", "result", "stamping"]:
		PixelFont.draw(self, Vector2(glass.position.x + 6, glass.position.y + 4), "THE LOT: EMPTY" if arrivals.is_empty() or clock >= CounterRules.SHIFT_LEN else "THE LOT", Color(BONE, 0.6))
	draw_rect(LOT, Color("2a2a30"), false, 2.0)

## A small side view of a waiting car, cached per customer.
func _queue_tex(w: Dictionary) -> ImageTexture:
	var id: int = int(w.get("qid", 0))
	if _qtex.has(id): return _qtex[id]
	var car: Dictionary = w.get("queue_car", w.car)
	var qlen := clampi(int(float(car.len) * 8.0), 30, 46)
	w._qlen = qlen
	var img := PixCars.image(qlen, PixCars.body_of({ "body": car.get("side_body", "sedan") }), Color(car.paint))
	var t := ImageTexture.create_from_image(img)
	_qtex[id] = t
	return t

func _draw_wall() -> void:
	draw_rect(WALL, Color("4a4038"))
	# calendar
	var t := CounterRules.today(day)
	draw_rect(Rect2(474, 4, 54, 42), Color("f0ece0"))
	draw_rect(Rect2(474, 4, 54, 10), RED)
	PixelFont.draw_centered(self, 501, 7, CounterRules.day_name(day), BONE)
	PixelFont.draw_centered(self, 501, 17, "%s %d" % [CounterRules.MONTHS[t[1] - 1], t[0]], INK)
	PixelFont.draw_centered(self, 501, 26, str(t[2]), INK, 2)
	_draw_clock(Vector2(553, 22))
	# cash, heat, the Familia and the Ministry's patience
	_panel(Rect2(578, 4, 58, 42), 0.6)
	PixelFont.draw(self, Vector2(581, 7), "$%d" % cash, GREEN if cash >= 0 else RED)
	PixelFont.draw(self, Vector2(581, 16), "HEAT %d" % heat(), RED if heat() > 30 else BONE)
	PixelFont.draw(self, Vector2(581, 25), "FAM %+d" % (int(week.get("trust", 0)) + int(day_log.get("trust", 0))), BONE)
	PixelFont.draw(self, Vector2(581, 35), "WARN", ASH)
	for i in CounterRules.WARNINGS:
		var r := Rect2(602 + i * 8, 35, 6, 6)
		draw_rect(r, RED if i < warnings_used else Color("2a2622"))
		draw_rect(r, ASH, false, 1.0)
	_draw_board()
	# the stolen list: this week's, or the Ministry's copy of the one from a pulled file's week
	if CounterRules.rule_active("bolo", jday()):
		var br := _bolo_rect()
		var list := bolo_now()
		draw_rect(br, Color("f2f0e8"))
		draw_rect(Rect2(br.position, Vector2(br.size.x, 9)), (TAB_COL["MINISTRY"] as Color) if _filed() else BLUE)
		PixelFont.draw(self, br.position + Vector2(3, 2), _list_title(), BONE)
		var cars := CounterRules.bolo_cars(list)
		# from week 6 the parts share the sheet, and the cars close up to make room
		var parts: Array = CounterRules.bolo_parts(list) if CounterRules.rule_active("hot", jday()) else []
		var pitch := 10.0 if parts.is_empty() else 7.0
		for i in cars.size():
			var b: Dictionary = cars[i]
			PixelFont.draw(self, br.position + Vector2(4, 12 + i * pitch), b.plate, INK)
			# a long name stops at the edge of the sheet
			var car_name := String(b.car)
			var fit := floori((br.size.x - 40.0) / 4.0)
			if car_name.length() > fit: car_name = car_name.substr(0, fit - 1) + "."
			PixelFont.draw(self, br.position + Vector2(36, 12 + i * pitch), car_name, PAPER_DIM)
		if not parts.is_empty():
			var py: float = br.position.y + 12 + cars.size() * pitch
			draw_rect(Rect2(br.position.x + 3, py, br.size.x - 6, 1), Color(BLUE, 0.6))
			PixelFont.draw(self, Vector2(br.position.x + 4, py + 2), "PARTS, BY SERIAL", BLUE)
			for i in parts.size():
				var pp := Vector2(br.position.x + 4 + (i % 2) * 80, py + 9 + floori(i / 2.0) * 7)
				PixelFont.draw(self, pp, "%s %s" % [parts[i].serial, parts[i].part], INK)
		draw_circle(br.position + Vector2(br.size.x / 2, 1), 2, RED)
	elif _filed():
		PixelFont.draw(self, Vector2(478, 260), "(NO STOLEN LIST YET ON %s.)" % CounterRules.month_day(CounterRules.today(jday())), ASH)
	else:
		PixelFont.draw(self, Vector2(478, 260), "(A CORKBOARD. EMPTY FOR NOW.)", ASH)
	_draw_shelf()

## The stolen list's heading: the week it's for, or the date on a pulled file.
func _list_title() -> String:
	if _filed(): return "STOLEN AS OF %s - FILE COPY" % CounterRules.month_day(CounterRules.today(jday()))
	return "POLICE - STOLEN - WEEK OF %s" % CounterRules.month_day(CounterRules.today(day - posmod(day, 7)))

## The wall clock: 8 to 6, and the minutes ticking.
func _draw_clock(o: Vector2) -> void:
	var late := clock >= CounterRules.SHIFT_LEN - 60.0
	draw_circle(o, 18.0, Color("2a2622"))
	draw_circle(o, 16.0, Color("f0ece0"))
	for i in 12:
		var a := TAU * i / 12.0
		var tick_len := 3.0 if i % 3 == 0 else 1.5
		draw_line(o + Vector2(sin(a), -cos(a)) * 15.0, o + Vector2(sin(a), -cos(a)) * (15.0 - tick_len), INK, 1.0)
	var mins := 480.0 + clock
	var ha := TAU * fmod(mins / 60.0, 12.0) / 12.0
	var ma := TAU * fmod(mins, 60.0) / 60.0
	draw_line(o, o + Vector2(sin(ha), -cos(ha)) * 8.0, INK, 2.0)
	draw_line(o, o + Vector2(sin(ma), -cos(ma)) * 12.0, RED if late else INK, 1.0)
	draw_circle(o, 1.5, RED)
	PixelFont.draw_centered(self, o.x, o.y + 20, CounterRules.clock_str(clock), RED if late else BONE)

## The rules on the wall: one bulletin, or the binder open at a tab. [{r, rule?, lines, new}]
func _rule_blocks() -> Array:
	var out: Array = []
	var by := BOARD.position.y + 12.0
	var list: Array = CounterRules.rules_for(day)
	var extra: Array = []
	if CounterRules.binder(day):
		by += 12.0
		var tabs := _tabs_today()
		var tab_name: String = tabs[clampi(tab, 0, tabs.size() - 1)]
		list = list.filter(func(r): return r.tab == tab_name)
		if tab_name == "MINISTRY": extra = CounterRules.MINISTRY_LINES
	for r in list:
		var ls := wrap_text(r.text, 38)
		out.append({ "r": Rect2(BOARD.position.x + 3, by, BOARD.size.x - 6, ls.size() * 7), "rule": r, "lines": ls, "today": r.day == day })
		by += ls.size() * 7 + 3
	for t in extra:
		var ls := wrap_text(t, 38)
		out.append({ "r": Rect2(BOARD.position.x + 3, by, BOARD.size.x - 6, ls.size() * 7), "lines": ls, "today": false })
		by += ls.size() * 7 + 3
	return out

func _tab_rect(i: int, n: int) -> Rect2:
	var w := floorf((BOARD.size.x - 4) / n)
	return Rect2(BOARD.position.x + 2 + i * w, BOARD.position.y + 11, w - 2, 10)

func _draw_board() -> void:
	var binder := CounterRules.binder(day)
	if binder:
		draw_rect(Rect2(BOARD.position - Vector2(2, 2), BOARD.size + Vector2(4, 4)), Color("1e2a3a"))
		for i in 3: draw_rect(Rect2(BOARD.position.x + 30 + i * 50, BOARD.position.y - 3, 8, 4), Color("b8b8b8"))
	draw_rect(BOARD, Color("e8e4d8"))
	PixelFont.draw(self, BOARD.position + Vector2(4, 3), "MINISTRY BINDER - INSPECTION STATIONS" if binder else "MINISTRY BULLETIN - INSPECTION STATIONS", PAPER_INK)
	if binder:
		var tabs := _tabs_today()
		for i in tabs.size():
			var r := _tab_rect(i, tabs.size())
			var col: Color = TAB_COL.get(tabs[i], ASH)
			var on: bool = i == clampi(tab, 0, tabs.size() - 1)
			draw_rect(r, col if on else col.darkened(0.45))
			PixelFont.draw_centered(self, r.get_center().x, r.position.y + 3, TAB_SHORT.get(tabs[i], tabs[i]), BONE)
			if CounterRules.rules_for(day).any(func(x): return x.tab == tabs[i] and x.day == day):
				draw_rect(Rect2(r.end.x - 4, r.position.y - 2, 4, 4), RED)
	for blk in _rule_blocks():
		var col := RED.darkened(0.2) if blk.today else PAPER_INK
		if not blk.has("rule"): col = PAPER_DIM
		var ls: Array = blk.lines
		for i in ls.size(): PixelFont.draw(self, blk.r.position + Vector2(1, i * 7), String(ls[i]), col)
	if binder: PixelFont.draw(self, Vector2(BOARD.position.x + 4, BOARD.end.y - 9), Hints.fmt("{desk_tab_prev}/{desk_tab_next}: TURN THE TABS"), PAPER_DIM)

## The shelf under the corkboard: Leo's notebook and the sticker log.
func _draw_shelf() -> void:
	draw_rect(Rect2(472, 356, 166, 3), Color("6a5a48"))
	for spec in [[NOTEBOOK_ICON, "NOTEBOOK", "desk_notebook", Color("2a3a6a"), DeskBook.notes.size()], [LOG_ICON, "STICKER LOG", "desk_log", Color("3a4a3a"), DeskBook.stickers.size()]]:
		var r: Rect2 = spec[0]
		var hot: bool = r.has_point(cur) and phase in ["idle", "counter"]
		var open: bool = (book == "notebook" and spec[2] == "desk_notebook") or (book == "log" and spec[2] == "desk_log")
		var col: Color = spec[3]
		draw_rect(Rect2(r.position + Vector2(4, 2), Vector2(30, r.size.y - 4)), col.lightened(0.2) if hot or open else col)
		draw_rect(Rect2(r.position + Vector2(4, 2), Vector2(4, r.size.y - 4)), col.darkened(0.4))
		draw_rect(Rect2(r.position + Vector2(12, 10), Vector2(18, 6)), Color(BONE, 0.85))
		PixelFont.draw(self, r.position + Vector2(38, 6), String(spec[1]).split(" ")[0], BONE)
		if String(spec[1]).contains(" "): PixelFont.draw(self, r.position + Vector2(38, 14), String(spec[1]).split(" ")[1], BONE)
		PixelFont.draw(self, r.position + Vector2(38, 24), Hints.fmt("{%s}" % spec[2]), GOLD)
		if int(spec[4]) > 0: PixelFont.draw(self, r.position + Vector2(14, 22), str(spec[4]), BONE)

func _draw_tray() -> void:
	draw_rect(TRAY, Color("2a2420"))
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var r := _button_rect(i)
		var on: bool = phase == "counter" and r.has_point(cur)
		var col: Color = b.col
		if b.id == "INSPECT" and inspecting: col = GOLD
		if phase != "counter" and not (b.id == "INSPECT" and phase == "idle"): col = col.darkened(0.35)
		draw_rect(r, col.lightened(0.15) if on else col)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), col.darkened(0.4))
		PixelFont.draw_centered(self, r.get_center().x, r.position.y + 10, b.label, BONE, 2, INK)
		var sub := Hints.fmt("{%s}" % b.key) if b.id == "INSPECT" or not Hints.pad else Hints.fmt("POINT + {desk_click}")
		if b.id == "WRENCH": sub = "OFF BOOKS" if Hints.pad else sub + " OFF BOOKS"
		PixelFont.draw_centered(self, r.get_center().x, r.position.y + 26, sub, Color(BONE, 0.7))

func _draw_inspect() -> void:
	if inspecting:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.85, 0.7, 0.2, 0.06))
		var h := field_at(cur)
		if not h.is_empty(): draw_rect(h.r.grow(1), Color(GOLD, 0.8), false, 1.0)
		if not pick_a.is_empty():
			draw_rect(pick_a.r.grow(2), GOLD, false, 2.0)
			draw_line(pick_a.r.get_center(), cur, Color(GOLD, 0.6), 1.0)
		var tip := Hints.fmt("INSPECT: PICK SOMETHING  {desk_cancel}: STOP") if pick_a.is_empty() else "COMPARE %s WITH...?" % pick_a.label
		if tip.length() > 74: tip = tip.substr(0, 71) + "...?"
		var w := PixelFont.width(tip) + 10
		_panel(Rect2(310 - w / 2.0, 113, w, 11))
		PixelFont.draw_centered(self, 310, 116, tip, GOLD)
		# ...or the same thing again, for a tool out of the drawer that reads it
		var tool_id := DeskTools.tool_for(pick_a, DeskBook.tools) if not pick_a.is_empty() else ""
		if tool_id != "":
			var again := "...OR PICK IT AGAIN: THE %s" % String(DeskTools.tool(tool_id).name)
			var aw := PixelFont.width(again) + 10
			_panel(Rect2(310 - aw / 2.0, 125, aw, 11))
			PixelFont.draw_centered(self, 310, 128, again, UV)
	if not verdict.is_empty():
		var col: Color = GREEN if verdict.good == true else (RED if verdict.good == false else ASH)
		var a: Dictionary = verdict.a
		var b: Dictionary = verdict.b
		draw_rect(a.r.grow(2), col, false, 2.0)
		draw_rect(b.r.grow(2), col, false, 2.0)
		draw_line(a.r.get_center(), b.r.get_center(), col, 1.0)
		var mid: Vector2 = (a.r.get_center() + b.r.get_center()) / 2.0
		# a tool reading one thing: the reading sits just under it (so the thing stays in sight),
		# the tool's name to its left
		var tool_name := String(verdict.get("tool", ""))
		var tw := PixelFont.width(tool_name) + 8.0 if tool_name != "" else 0.0
		if a.r == b.r: mid.y = a.r.end.y + 11.0
		var w := PixelFont.width(verdict.text, 2) + 12
		mid.x = clampf(mid.x, w / 2.0 + 4.0 + tw, 638 - w / 2.0)
		draw_rect(Rect2(mid.x - w / 2.0, mid.y - 8, w, 16), Color(col.darkened(0.55), 0.95))
		draw_rect(Rect2(mid.x - w / 2.0, mid.y - 8, w, 16), col, false, 1.0)
		PixelFont.draw_centered(self, mid.x, mid.y - 4, verdict.text, BONE, 2)
		if tool_name != "":
			var tr := Rect2(mid.x - w / 2.0 - tw - 2.0, mid.y - 6, tw, 12)
			draw_rect(tr, Color(0.1, 0.07, 0.18, 0.95))
			draw_rect(tr, UV, false, 1.0)
			PixelFont.draw_centered(self, tr.get_center().x, tr.position.y + 4, tool_name, UV)
		if verdict.good == false and not topics.is_empty() and phase == "counter":
			var hint := Hints.fmt("{desk_ask}: ASK ABOUT IT")
			var hw := PixelFont.width(hint) + 8
			_panel(Rect2(mid.x - hw / 2.0, mid.y + 8, hw, 11), 0.95)
			PixelFont.draw_centered(self, mid.x, mid.y + 11, hint, GOLD)

func _brief_paras() -> Array:
	if tutorial:
		# fix 2: the old manager's name stays off the screen in Years 1 and 2
		return ["CLOCK IN: 8:00 A.M. GUS IS LEANING ON THE DOORFRAME WITH A COFFEE THAT SAYS WORLD'S OKAYEST BOSS.",
			"\"THAT'S THE OLD MANAGER'S MUG. I SAID DON'T TOUCH THE MUG. FINE. KEEP IT. READ EVERY PAPER.\"",
			"\"I'LL BE RIGHT BEHIND YOU. NOT HELPING. JUST BEHIND YOU.\""]
	if overtime: return _overtime_brief()
	var paras: Array = BRIEFS.get(day, [MORNINGS[day % MORNINGS.size()]]).duplicate()
	if DeskBook.old_log and (day == 29 or (story.is_empty() and day == 22)):
		paras.append("GUS DROPS A BINDER ON THE DESK. \"LAST FALL'S STICKER LOG. MINISTRY WANTS 'EM ALL TOGETHER.\" HE DOESN'T LOOK AT IT. HE DOESN'T LOOK AT IT VERY HARD.")
	return paras

## An overtime morning: the first one, what the calendar brings (a notice, or a holiday the shop
## was shut for), a new stolen list on the week's first day, and Hachey's car in the lot.
func _overtime_brief() -> Array:
	var paras: Array = []
	var ot: Dictionary = DeskBook.overtime
	var prev := day - 1
	while prev > CounterRules.LAST_DAY and not CounterRules.is_open(prev): prev -= 1
	if int(ot.get("days", 0)) == 0:
		paras.append("OVERTIME. THE EIGHT WEEKS ARE DONE. THE JOB ISN'T. EVERY RULE IN THE BINDER STAYS UP, AND THE DATES ON THEM COME ROUND.")
		paras.append("GUS: \"SAME RULES. ALL OF 'EM. READ THE CALENDAR BEFORE YOU READ THE TIRES.\"")
	var shut: Array = []
	for x in range(prev + 1, day):
		if CounterRules.holiday(x) != "" and not shut.has(CounterRules.holiday(x)): shut.append(CounterRules.holiday(x))
	if not shut.is_empty(): paras.append("THE SHOP WAS SHUT FOR %s." % " AND ".join(shut))
	var noticed := false
	for n in OT_NOTICES:
		for x in range(prev + 1, day + 1):
			var tx := CounterRules.today(x)
			if int(tx[1]) == int(n[0][0]) and int(tx[2]) == int(n[0][1]):
				paras.append(String(n[1]))
				noticed = true
	if not noticed and int(ot.get("days", 0)) > 0:
		var pool: Array = OT_MORNINGS.get(int(CounterRules.today(day)[1]), MORNINGS)
		paras.append(String(pool[posmod(day, pool.size())]))
	if CounterRules.week_of(prev) != CounterRules.week_of(day) and int(ot.get("days", 0)) > 0:
		paras.append("CONSTABLE TREMBLAY'S NEW STOLEN LIST IS ON THE CORKBOARD. LAST WEEK'S IS IN THE FILES.")
	var hachey := CounterRules.audit_times(day)
	if not hachey.is_empty():
		paras.append("INSPECTOR HACHEY'S GREY SEDAN IS IN THE LOT AT 7:45. HE'S \"JUST PASSING THROUGH.\" HE'LL PULL A FILE AT %s" % CounterRules.clock_str(float(hachey[0])))
	return paras

func _draw_brief() -> void:
	var r := Rect2(50, 30, 540, 300)
	_panel(r, 0.95)
	var t := CounterRules.today(day)
	PixelFont.draw_centered(self, 320, 44, "%s, %s" % [CounterRules.day_name(day), CounterRules.date_str(t)], GOLD, 3, INK)
	var head := "WEEK %d AT COVINGTON AUTO." % CounterRules.week_of(day)
	if overtime: head = "OVERTIME, DAY %d AT COVINGTON AUTO." % (int(DeskBook.overtime.get("days", 0)) + 1)
	PixelFont.draw_centered(self, 320, 66, head + "  THE WINDOW OPENS AT 8. CLOCK-OUT IS AT 6.", ASH)
	var y := 84.0
	for para in _brief_paras():
		for l in wrap_text(para, 64):
			PixelFont.draw(self, Vector2(70, y), l, BONE, 2)
			y += 13
		y += 5
	var news := CounterRules.RULES.filter(func(x): return x.day == day)
	if not news.is_empty():
		PixelFont.draw(self, Vector2(70, y + 2), "NEW IN THE BINDER:" if CounterRules.binder(day) else "NEW ON THE BULLETIN:", RED)
		y += 12
		for n in news:
			for l in wrap_text(n.text, 110):
				PixelFont.draw(self, Vector2(70, y), l, BONE)
				y += 8
	if overtime:
		PixelFont.draw_centered(self, 320, 274, "OVERTIME SAVES AT EVERY CLOCK-OUT.", ASH)
		PixelFont.draw_centered(self, 320, 286, _record_line(), GOLD)
	elif story.is_empty() and fresh and day == WEEK_DAYS[WEEK_DAYS.size() - 1]:
		PixelFont.draw_centered(self, 320, 286, "AFTER WEEK 8: OVERTIME. DECEMBER, THE WINTER, THE SPRING, AND ON.", ASH)
	# the week picker (free play's first morning) and, next to it, the wall clock's pace
	var relax := relax_line()
	var relax_col := GOLD if DeskBook.relaxed else ASH
	if story.is_empty() and fresh:
		var pick := "< OVERTIME >" if overtime else "< WEEK %d OF %d >" % [CounterRules.week_of(day), CounterRules.WEEKS]
		PixelFont.draw_centered(self, 210, 300, Hints.fmt("{desk_tab_prev}  %s  {desk_tab_next}" % pick), GOLD)
		PixelFont.draw_centered(self, 440, 300, relax, relax_col)
	else: PixelFont.draw_centered(self, 320, 300, relax, relax_col)
	PixelFont.draw_centered(self, 320, 314, Hints.fmt("{desk_click}: OPEN THE WINDOW"), Color(BONE, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)))

## The relaxed clock's line on the brief: what it is, and the button that flips it.
func relax_line() -> String:
	var mins := roundi(CounterRules.SHIFT_LEN / clock_rate() / 60.0)
	return Hints.fmt("{desk_relax}: RELAXED CLOCK %s (%d MIN A DAY)" % ["ON" if DeskBook.relaxed else "OFF", mins])

func _draw_result() -> void:
	var r := Rect2(164, 126, 292, 174)
	_panel(r, 0.94)
	var good: bool = result.correct
	var title: String = {"APPROVED": "APPROVED", "DENIED": "DENIED", "REPORT": "REPORTED TO POLICE", "WRENCH": "BAY 3, NO PAPERS"}[stamped]
	if c.has("slip") and stamped in ["APPROVED", "DENIED"]: title = BOX_WORD[stamped]
	if c.kind == "audit": title = "THE SAME STAMP" if good else "A DIFFERENT STAMP"
	PixelFont.draw_centered(self, 310, 134, title, GOLD, 2)
	if overtime and result.has("streak_was"):
		var streak := int(DeskBook.overtime.get("streak", 0))
		var st := "STREAK %d" % streak
		var col := GREEN if good else RED
		if not good and int(result.streak_was) > 0: st = "STREAK OVER AT %d" % int(result.streak_was)
		elif good and streak > int(result.get("best_was", streak)):
			st = "NEW BEST: %d" % streak
			col = GOLD
		PixelFont.draw(self, Vector2(r.end.x - 6 - PixelFont.width(st), r.position.y + 4), st, col)
	var y := 152.0
	for l in wrap_text(result.line, 66):
		PixelFont.draw(self, Vector2(174, y), l, BONE)
		y += 8
	y += 4
	if result.money > 0: PixelFont.draw(self, Vector2(174, y), "+$%d FOR THE SHOP" % result.money, GREEN, 2); y += 14
	if result.dirty > 0: PixelFont.draw(self, Vector2(174, y), "+$%d CASH. NO RECEIPT." % result.dirty, GOLD, 2); y += 14
	if int(result.get("fee", 0)) > 0: PixelFont.draw(self, Vector2(174, y), "-$%d OFF THE SHOP" % int(result.fee), RED, 2); y += 14
	if int(result.sticker) > 0: PixelFont.draw(self, Vector2(174, y), "STICKER %04d ON THE WINDSHIELD. IN THE LOG." % int(result.sticker), BONE); y += 10
	if result.citation != "":
		if result.warning: PixelFont.draw(self, Vector2(174, y), "MINISTRY WARNING %d OF %d. NO FINE. THIS TIME." % [warnings_used, CounterRules.WARNINGS], GOLD)
		else: PixelFont.draw(self, Vector2(174, y), "MINISTRY CITATION  -$%d" % result.fine, RED, 2)
		y += 10 if result.warning else 14
		for l in wrap_text(result.citation, 66):
			PixelFont.draw(self, Vector2(174, y), l, RED.lightened(0.3))
			y += 8
	if result.heat > 0: PixelFont.draw(self, Vector2(174, y + 2), "HEAT +%d" % result.heat, RED); y += 10
	if result.trust != 0: PixelFont.draw(self, Vector2(174, y + 2), "FAMILIA %+d" % result.trust, ASH); y += 10
	if c.kind == "regular" and not good and result.citation == "":
		PixelFont.draw(self, Vector2(174, y + 2), "THERE WAS NOTHING WRONG WITH THAT ONE.", ASH)
	var last := clock >= CounterRules.SHIFT_LEN
	PixelFont.draw_centered(self, 310, 288, Hints.fmt("{desk_click}: CLOSE UP FOR THE DAY") if last else (Hints.fmt("{desk_click}: NEXT!") if not waiting.is_empty() else Hints.fmt("{desk_click}: BACK TO THE WINDOW")), Color(BONE, 0.7))

## The day's tally, one line each: [label, value, colour]. Every value is short enough to sit at
## the labels' size (the reasons go in the small print underneath).
func _day_end_rows() -> Array:
	var rows: Array = [["CUSTOMERS", "%d (%d RIGHT)" % [day_log.seen, day_log.correct], BONE]]
	var w: int = day_log.walked
	rows.append(["DROVE OFF AT SIX", "%d (-$%d)" % [w, day_log.walked_money] if w > 0 else "NOBODY", GOLD if w > 0 else ASH])
	rows.append(["SHOP MONEY", "+$%d" % day_log.earned, GREEN])
	rows.append(["CASH, NO RECEIPTS", "+$%d" % day_log.dirty, GOLD])
	if day_log.fees > 0: rows.append(["PARTS SENT BACK", "-$%d" % day_log.fees, RED])
	rows.append(["WARNINGS", "%d OF %d" % [day_log.warnings.size(), CounterRules.WARNINGS], BONE])
	var n: int = day_log.citations.size()
	rows.append(["CITATIONS", "%d (-$%d)" % [n, day_log.fines] if day_log.fines > 0 else str(n), RED if day_log.fines > 0 else BONE])
	if day_log.audits > 0:
		var twice: int = day_log.get("audits_wrong", 0)
		rows.append(["FILES PULLED", "%d, %d THE SAME" % [day_log.audits, day_log.audits_same] + (" (%d WRONG TWICE)" % twice if twice > 0 else ""), BONE])
	rows.append(["REVIEWS", "%+d STARS" % day_log.reviews, BONE])
	rows.append(["HEAT / FAMILIA", "%+d / %+d" % [day_log.heat, day_log.trust], BONE])
	if overtime:
		var ot: Dictionary = DeskBook.overtime
		rows.append(["OVERTIME", "DAY %d, STREAK %d (BEST %d)" % [int(ot.get("days", 0)) + 1, int(ot.get("streak", 0)), int(ot.get("best", 0))], GOLD])
	rows.append(["CASH ON HAND", "$%d" % cash, GREEN if cash >= 0 else RED])
	return rows

const LEDGER_L := 136.0                # the day-end tally's left edge (labels)...
const LEDGER_R := 504.0                # ...and right edge (values line up on it)
const LEDGER_PITCH := 15.0             # one row of it

## One line of a tally: the label on the left, the value on the right, dots between, both at 2x.
func _ledger_row(y: float, label: String, value: String, col: Color, left := LEDGER_L, right := LEDGER_R, label_col := ASH) -> void:
	PixelFont.draw(self, Vector2(left, y), label, label_col, 2)
	var vx := right - PixelFont.width(value, 2)
	PixelFont.draw(self, Vector2(vx, y), value, col, 2)
	var x := left + PixelFont.width(label, 2) + 8.0
	while x < vx - 8.0:
		draw_rect(Rect2(x, y + 8, 2, 1), Color(ASH, 0.35))
		x += 6.0

func _draw_day_end() -> void:
	var r := Rect2(110, 30, 420, 300)
	_panel(r, 0.96)
	PixelFont.draw_centered(self, 320, 42, "6:00 P.M. %s IS DONE" % CounterRules.day_name(day), GOLD, 3, INK)
	var y := 66.0
	for row in _day_end_rows():
		_ledger_row(y, String(row[0]), String(row[1]), row[2])
		y += LEDGER_PITCH
	# the small print: what the Ministry wrote down, and where the licence stands
	draw_rect(Rect2(LEDGER_L, y, LEDGER_R - LEDGER_L, 1), Color(ASH, 0.3))
	y += 6
	for l in _small_print():
		PixelFont.draw(self, Vector2(LEDGER_L, y), l, RED.lightened(0.3))
		y += 8
	PixelFont.draw(self, Vector2(LEDGER_L, y + 2), "LICENCE: %d OF %d CITATIONS, %d OF %d MINISTRY MEETINGS." % [DeskBook.citations, CounterRules.REVOKE_AT, DeskBook.meetings, CounterRules.MEETINGS_TO_REVOKE], ASH)
	if not story.is_empty():
		PixelFont.draw_centered(self, 320, 296, "LEO'S PAY: $%d.  BAY 3 CASH GOES TO THE FAMILIA: OWED $%d." % [60 + int(day_log.earned * 0.15), maxi(0, StoryState.debt - int(day_log.dirty))], GOLD)
		PixelFont.draw_centered(self, 320, 312, Hints.fmt("{desk_click}: CLOCK OUT"), Color(BONE, 0.7 + 0.3 * sin(Time.get_ticks_msec() / 250.0)), 2)
	else:
		var friday := CounterRules.week_closes(day)
		PixelFont.draw_centered(self, 320, 312, Hints.fmt("{desk_click}: PAY THE BILLS") if friday else Hints.fmt("{desk_click}: GO HOME"), Color(BONE, 0.7))
	_draw_drawer_handle()

## Under the day-end sheet: the front of Gus's tool drawer, and how to pull it open (pulled
## out, with no label, while it's open).
func _draw_drawer_handle(open := false) -> void:
	var ts := drawer_tools()
	if ts.is_empty(): return
	var h := DRAWER_HANDLE
	var hot: bool = drawer_armed and h.has_point(cur) and not open
	draw_rect(h, Color("6a4e38") if hot else Color("5a4232"))
	for i in 3: draw_line(Vector2(h.position.x + 2, h.position.y + 6 + i * 8), Vector2(h.end.x - 2, h.position.y + 7 + i * 8), Color("4e382a"), 1.0)
	draw_rect(h, Color("2e2018"), false, 2.0)
	if open: return
	# the pull, brass when there's something in there Leo hasn't got and can pay for
	var can := ts.any(func(t): return not DeskBook.tools.has(String(t.id)) and purse() >= int(t.price))
	var label := Hints.fmt("{desk_tab_next}: GUS'S TOOL DRAWER")
	var pull := Rect2(h.get_center().x - PixelFont.width(label) / 2.0 - 8, h.position.y + 7, PixelFont.width(label) + 16, 13)
	draw_rect(pull, Color("2e2018"))
	draw_rect(pull, GOLD if can else ASH, false, 1.0)
	PixelFont.draw_centered(self, h.get_center().x, pull.position.y + 4, label, GOLD if can else BONE)

## Gus's tool drawer: what's in it tonight, what it does, what it costs, and the money to pay.
func _draw_drawer() -> void:
	_draw_drawer_handle(true)
	var r := Rect2(110, 30, 420, 300)
	_panel(r, 0.97)
	# the inside of the drawer: a wooden lip along the top
	draw_rect(Rect2(r.position.x + 8, r.position.y + 6, r.size.x - 16, 24), Color("5a4232"))
	draw_rect(Rect2(r.position.x + 8, r.position.y + 28, r.size.x - 16, 2), Color("3e2c20"))
	PixelFont.draw_centered(self, 320, 40, "GUS'S TOOL DRAWER", GOLD, 3, INK)
	var money := purse()
	PixelFont.draw_centered(self, 320, 66, "%s: $%d" % [purse_label(), money], GREEN if money >= 0 else RED, 2)
	var ts := drawer_tools()
	for i in ts.size():
		var t: Dictionary = ts[i]
		var row := _drawer_rect(i)
		var owned := DeskBook.tools.has(String(t.id))
		var on := i == drawer_sel
		draw_rect(row, Color(1, 1, 1, 0.07) if on else Color(1, 1, 1, 0.03))
		draw_rect(row, GOLD if on else Color(1, 1, 1, 0.12), false, 1.0)
		_draw_tool_icon(String(t.id), row.position + Vector2(16, 20))
		PixelFont.draw(self, row.position + Vector2(34, 5), String(t.name), BONE if not owned else Color(BONE, 0.6), 2)
		var tag := "OWNED" if owned else "$%d" % int(t.price)
		var tag_col: Color = GREEN if owned else (BONE if money >= int(t.price) else RED.lightened(0.2))
		PixelFont.draw(self, Vector2(row.end.x - 6 - PixelFont.width(tag, 2), row.position.y + 5), tag, tag_col, 2)
		var ls := wrap_text(String(t.what), 88)
		for k in mini(2, ls.size()): PixelFont.draw(self, row.position + Vector2(34, 20 + k * 8), ls[k], Color(BONE, 0.5) if owned else ASH)
	var y := 84.0 + ts.size() * 45.0 + 4.0
	for l in wrap_text(drawer_line, 94):
		PixelFont.draw(self, Vector2(124, y), l, Color("c8c0a8"))
		y += 8
	PixelFont.draw_centered(self, 320, 296, Hints.fmt("{desk_tab_prev}/{desk_tab_next}: PICK  {desk_click}: BUY IT"), GOLD)
	var shut := _drawer_shut_rect()
	PixelFont.draw_centered(self, shut.get_center().x, shut.position.y + 4, Hints.fmt("{desk_cancel}: SHUT THE DRAWER"), Color(BONE, 0.85) if shut.has_point(cur) else Color(BONE, 0.6))

## A tool, drawn small, centred on `at`.
func _draw_tool_icon(id: String, at: Vector2) -> void:
	match id:
		"gauge":
			# a pen-shaped depth gauge: the barrel with its scale, the pin out the bottom, a tire's tread under it
			draw_rect(Rect2(at + Vector2(-3, -11), Vector2(6, 15)), Color("c8a030"))
			for k in 4: draw_rect(Rect2(at + Vector2(-3, -9 + k * 3), Vector2(3, 1)), INK)
			draw_rect(Rect2(at + Vector2(-1, 4), Vector2(2, 5)), Color("d8d8d0"))
			for k in 4: draw_rect(Rect2(at + Vector2(-11 + k * 6, 9), Vector2(4, 3)), Color("3a3438"))
		"wheel":
			draw_circle(at, 10.0, Color("e8e0c8"))
			draw_circle(at, 6.5, Color("c8342c"))
			draw_circle(at, 2.0, INK)
			for k in 12:
				var a := TAU * k / 12.0
				draw_line(at + Vector2(cos(a), sin(a)) * 8.0, at + Vector2(cos(a), sin(a)) * 10.0, INK, 1.0)
		"loupe":
			draw_circle(at + Vector2(-2, -2), 7.0, Color("9ab8d0"))
			draw_circle(at + Vector2(-2, -2), 7.0, Color("2a2a30"), false, 2.0)
			draw_line(at + Vector2(3, 3), at + Vector2(9, 9), Color("2a2a30"), 3.0)
		"lamp":
			draw_rect(Rect2(at + Vector2(-10, -4), Vector2(20, 8)), Color("2a2430"))
			draw_rect(Rect2(at + Vector2(-8, -2), Vector2(16, 4)), UV)
			draw_rect(Rect2(at + Vector2(-12, 4), Vector2(24, 6)), Color(UV, 0.25))

## What the Ministry wrote down today, wrapped to the sheet: four lines at most.
func _small_print() -> Array:
	var out: Array = []
	for cit in day_log.citations + day_log.warnings:
		var ls := wrap_text("- " + String(cit), 90)
		for i in ls.size(): out.append(ls[i] if i == 0 else "  " + ls[i])
	if out.size() > 4: out = out.slice(0, 3) + ["  ...AND MORE. THE MINISTRY KEEPS THE REST."]
	return out

func _draw_week_end() -> void:
	var r := Rect2(80, 20, 480, 320)
	_panel(r, 0.97)
	PixelFont.draw_centered(self, 320, 32, "FRIDAY NIGHT. THE BILLS.", GOLD, 3, INK)
	var y := 60.0
	var short := 0
	for b in bills_paid:
		_ledger_row(y, String(b[0]), ("$%d" % b[1]) if b[2] else "CAN'T PAY", GREEN if b[2] else RED, 110.0, 530.0, BONE)
		if not b[2]: short += int(b[1])
		y += 15
	_ledger_row(y + 2, "LEFT IN THE TILL", "$%d" % cash, BONE, 110.0, 530.0)
	y += 26
	var lines: Array = []
	if short == 0: lines.append("EVERYTHING'S PAID. GUS COUNTS THE TILL TWICE AND NODS ONCE. FROM GUS, THAT'S A PARADE.")
	for b in bills_paid:
		if b[2]: continue
		match b[0]:
			"RENT ON THE GARAGE": lines.append("THE LANDLORD TAPES A NOTICE TO THE BAY DOOR. YOU HAVE UNTIL THE END OF THE MONTH.")
			"THE FAMILIA (FOR MIA'S CAR)": lines.append("SATURDAY MORNING YOUR CAR HAS NO WINDSHIELD. THERE'S A NAPKIN ON THE SEAT: \"FRIDAY. -M\"")
			"ARIES'S HOCKEY": lines.append("ARIES SAYS IT'S FINE, SHE DIDN'T WANT TO PLAY THIS SEASON ANYWAY. SHE'S LYING.")
			"GUS'S PAY": lines.append("GUS DOESN'T SAY A WORD ABOUT HIS PAY. HE SHOWS UP SATURDAY ANYWAY.")
	if week.heat >= 50: lines.append("A CAR PARKS ACROSS THE STREET ALL WEEKEND. NOBODY GETS OUT.")
	if week.trust >= 15: lines.append("DOM SENDS A TRAY OF LASAGNA. NOBODY KNOWS HOW HE GOT INTO THE GARAGE.")
	elif week.trust <= -30: lines.append("SOMEBODY LETS THE AIR OUT OF ALL FOUR OF YOUR TIRES. NEATLY.")
	if week.citations >= 4: lines.append("THE MINISTRY WANTS A MEETING ABOUT YOUR INSPECTION LICENCE. (MEETING %d OF %d.)" % [DeskBook.meetings, CounterRules.MEETINGS_TO_REVOKE])
	if week.reviews >= 8: lines.append("COVINGTON AUTO HITS 4.6 STARS. SOMEONE WRITES \"JUST LIKE WHEN FRANK RAN IT.\"")
	for para in lines:
		for l in wrap_text(para, 76):
			PixelFont.draw(self, Vector2(100, y), l, BONE)
			y += 8
		y += 5
	if overtime: PixelFont.draw_centered(self, 320, 286, _record_line(), GOLD)
	PixelFont.draw_centered(self, 320, 300, "%s. %s. %s. %s." % [_count(week.seen, "CUSTOMER"), _count(week.correct, "RIGHT CALL"), _count(week.warnings, "WARNING"), _count(week.citations, "CITATION")], ASH)
	var nxt := "THE LICENCE" if DeskBook.revoked() else ("THE END OF THE MONTH" if day >= CounterRules.LAST_DAY and not overtime else "NEXT WEEK")
	PixelFont.draw_centered(self, 320, 318, Hints.fmt("{desk_click}: " + nxt), Color(BONE, 0.7))

## Inspector Hachey's report on the week: one line, the way the Ministry writes them. A wrong
## call stamped the same way twice is consistent, and he says so; he also says it was wrong.
func audit_verdict() -> String:
	var pulled := DeskBook.audits.size()
	var same := DeskBook.audits.filter(func(a): return String(a.was) == String(a.now)).size()
	var twice := DeskBook.audits.filter(func(a): return String(a.was) == String(a.now) and not bool(a.get("right", true))).size()
	if pulled == 0: return "HACHEY'S REPORT: \"NO FILES PULLED. THE STATION WAS VERY BUSY. SO WAS I.\""
	var tally := "HACHEY'S REPORT: %d %s PULLED, %d STAMPED THE SAME TWICE." % [pulled, "FILE" if pulled == 1 else "FILES", same]
	if same == pulled and twice > 0: return tally + " \"STATION 0117 AGREES WITH ITSELF. %s WRONG BOTH TIMES.\"" % ("ONE WAS" if twice == 1 else "%d WERE" % twice)
	if same == pulled: return tally + " \"STATION 0117 AGREES WITH ITSELF.\" HE UNDERLINES IT."
	return tally + " \"STATION 0117 HAS OPINIONS. SEVERAL. ABOUT THE SAME CARS.\""

func _draw_month_end() -> void:
	_panel(Rect2(80, 40, 480, 280), 0.97)
	PixelFont.draw_centered(self, 320, 54, "NOVEMBER 29. THE SNOW STUCK.", GOLD, 3, INK)
	var y := 90.0
	var ls := ["%d WEEKS AT THE COUNTER. %s, %s, $%d FOR THE SHOP." % [CounterRules.WEEKS, _count(month.seen, "CUSTOMER"), _count(month.correct, "RIGHT CALL"), month.earned],
		"%s ON %s. %s ON YOUR LICENCE." % [_count(DeskBook.stickers.size(), "STICKER"), _count(DeskBook.stickers.size(), "WINDSHIELD"), _count(DeskBook.citations, "CITATION")],
		audit_verdict(),
		"GUS LOCKS UP. \"NOT BAD, KID.\" HE THINKS ABOUT IT. \"NOT GOOD EITHER. BUT NOT BAD.\"",
		"THE FULL GAME HAS EIGHT YEARS OF THESE."]
	for para in ls:
		for l in wrap_text(para, 52):
			PixelFont.draw(self, Vector2(108, y), l, BONE, 2)
			y += 13
		y += 6
	PixelFont.draw_centered(self, 320, 296, Hints.fmt("{desk_tab_next}: KEEP WORKING (OVERTIME)"), GOLD)
	PixelFont.draw_centered(self, 320, 308, Hints.fmt("{desk_click}: BACK TO THE MENU"), Color(BONE, 0.7))

## "1 STICKER", "2 STICKERS".
static func _count(n: int, what: String) -> String:
	return "%d %s%s" % [n, what, "" if n == 1 else "S"]

## Overtime's running record, one line.
func _record_line() -> String:
	var ot: Dictionary = DeskBook.overtime
	return "DAYS KEPT %d.  STREAK %d.  BEST STREAK %d." % [int(ot.get("days", 0)), int(ot.get("streak", 0)), int(ot.get("best", 0))]

## The short fail ending: the Daily Clutch's front page.
func _draw_revoked() -> void:
	var r := Rect2(120, 24, 400, 312)
	draw_rect(r, Color("e8e2d0"))
	draw_rect(r, INK, false, 2.0)
	PixelFont.draw_centered(self, 320, 34, "THE DAILY CLUTCH", INK, 3)
	draw_rect(Rect2(130, 58, 380, 2), INK)
	PixelFont.draw_centered(self, 320, 66, "PORT RUMBLE  -  %s" % CounterRules.date_str(CounterRules.today(day)), PAPER_DIM)
	PixelFont.draw_centered(self, 320, 86, "COVINGTON AUTO LOSES", INK, 2)
	PixelFont.draw_centered(self, 320, 102, "ITS INSPECTION LICENCE", INK, 2)
	var y := 126.0
	var when := "" if overtime else " IN A MONTH"
	for l in wrap_text("THE MINISTRY PULLED STATION 0117'S LICENCE THIS WEEK AFTER %d CITATIONS%s. \"WE GAVE THE COVINGTON KID EVERY CHANCE,\" SAID A SPOKESPERSON, WHO DID NOT. THE SHOP WILL KEEP DOING OIL CHANGES. A HANDWRITTEN SIGN ON THE DOOR SAYS \"STILL OPEN. MOSTLY.\"" % [DeskBook.citations, when], 70):
		PixelFont.draw(self, Vector2(140, y), l, PAPER_INK)
		y += 9
	if overtime: PixelFont.draw_centered(self, 320, 296, "OVERTIME: %d DAYS KEPT. BEST STREAK %d." % [int(DeskBook.overtime.get("days", 0)), int(DeskBook.overtime.get("best", 0))], PAPER_INK)
	PixelFont.draw_centered(self, 320, 312, Hints.fmt("{desk_click}: BACK TO THE MENU"), PAPER_DIM)

func _draw_cursor() -> void:
	var p := cur.round()
	var col := GOLD if inspecting else BONE
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(0, 10), p + Vector2(3, 7), p + Vector2(7, 7)]), INK)
	draw_colored_polygon(PackedVector2Array([p + Vector2(1, 2), p + Vector2(1, 8), p + Vector2(3, 6), p + Vector2(5, 6)]), col)

## Word-wraps to what `n` characters of the old fixed-width font took up (the HUD's wrap).
static func wrap_text(text: String, n: int) -> Array[String]:
	return Hud.wrap_lines(text, n)
