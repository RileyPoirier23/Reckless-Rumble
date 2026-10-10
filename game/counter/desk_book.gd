## Leo's books at the counter: his notebook (what he's caught people saying, and what he's
## worked out), the station's sticker log (every inspection sticker issued, last fall's pages
## included), the filing cabinet (every work order he's stamped, which is how the regulars and
## the people he turned away remember him, and what the Ministry's auditor pulls), the
## Ministry's tally on him, the seed of the police's weekly stolen lists, and the overtime
## record (the job after the run: the day he's on, the till, the days kept and the streaks).
##
## Static, like StoryState. In the story it lives in StoryState.flags["desk_book"], so it saves
## and starts over with the story; free play starts a fresh book every time, except overtime,
## which keeps the same book in a file of its own (save_overtime / load_overtime).
##
## Hooks for the story: DeskBook.note(id, text, day) writes in the notebook, has_note(id)
## asks, old_log = true brings last fall's pages out of the filing cabinet, last_file(id) says
## what Leo stamped on a scripted customer or a regular last time.
class_name DeskBook
extends RefCounted

## The first sticker Leo puts on a windshield.
const FIRST_STICKER := 601
## Station 0117's sticker log from last fall, Frank's last weeks at the shop: [no, date, plate,
## car]. Read it carefully: 0448 isn't there.
const OLD_LOG := [
	[440, [2018, 11, 19], "KLM 204", "2002 CHEVROLAY CAVA-LAME"], [441, [2018, 11, 20], "BTR 551", "2009 TOYODA CAMREE"],
	[442, [2018, 11, 21], "HWY 016", "1996 FJORD F-ONE-FIDDY"], [443, [2018, 11, 22], "PNC 870", "2011 HONDO CIVIL"],
	[444, [2018, 11, 26], "MRS 311", "2004 DODGY GRAND CARAVANN"], [445, [2018, 11, 27], "DRT 902", "2006 SUBAROO IMPREZZA"],
	[446, [2018, 11, 28], "GLX 128", "2001 FJORD ESCAPED"], [447, [2018, 11, 30], "TBN 645", "1999 BUICKK LE SABOT"],
	[449, [2018, 12, 3], "CVL 387", "2008 TOYODA COROLLY"], [450, [2018, 12, 3], "SHD 019", "2008 CHEVROLAY IMPALER"],
	[451, [2018, 12, 4], "RVR 773", "2012 KEEYA SOUL-LESS"], [452, [2018, 12, 5], "WLK 450", "2007 VOLKSWAGON GOLPH"],
]
## What Leo writes when he finds the gap.
const GAP_NOTE := "STICKER 0448 IS MISSING FROM LAST FALL'S LOG. 0447 IS THERE. 0449 IS THERE. SOMEBODY PULLED A PAGE."

static var notes: Array = []          # [{id, text, day}], oldest first
static var stickers: Array = []       # [{no, day, plate, car, vin}], Leo's own
static var citations := 0             # fined citations, all time (REVOKE_AT of them and the licence goes)
static var warnings := 0              # free ones, all time
static var meetings := 0              # Ministry meetings about the licence
static var old_log := false           # last fall's pages are on the desk
static var flags: Array = []          # story flags the desk has raised and not yet handed over
static var book_seed := 0             # the stolen lists: one a week, made from this (week_list)
## Every work order stamped: [{no, day, stamp, correct, probs, kind, id, seed, of, who, car,
## plate, request, back, pulled, visit, last, list}]. `id` names a regular, a scripted customer or
## a courier ("" for a walk-in), `seed` rebuilds a walk-in's or a box's papers (-1 if it can't),
## `visit` and `last` rebuild a regular's (which visit, and what Leo had stamped on them before
## it), `of` is the file a returning customer came back about, `back` says they did, `list` is
## the seed of the stolen list the papers were read against that day. WALKED is the stamp for a
## regular who drove off at six.
static var files: Array = []
## Inspector Hachey's audit: [{no, day, was, now, right}] for every file he pulled (`right`:
## the first stamp was the right call).
static var audits: Array = []
const MAX_FILES := 400                # the cabinet keeps the newest
## Overtime: {day (the next one to work), cash, week (Friday's tally so far), days (kept this
## time round), streak (right calls in a row), best (the best streak ever), best_days (the most
## days ever kept), calls, right, ended (the licence went: the next overtime starts over)}.
## Empty until overtime starts.
static var overtime := {}
## Where free play keeps overtime between sessions (the tests point it somewhere else).
const OVERTIME_PATH := "user://driveboss_overtime.json"
static var overtime_path := OVERTIME_PATH

## A blank book.
static func reset() -> void:
	notes = []
	stickers = []
	citations = 0
	warnings = 0
	meetings = 0
	old_log = false
	flags = []
	files = []
	audits = []
	book_seed = 0
	overtime = {}

static func to_dict() -> Dictionary:
	var d := { "notes": notes, "stickers": stickers, "citations": citations, "warnings": warnings,
		"meetings": meetings, "old_log": old_log, "files": files, "audits": audits, "book_seed": book_seed }
	if not overtime.is_empty(): d.overtime = overtime
	return d

static func from_dict(d: Dictionary) -> void:
	reset()
	notes = (d.get("notes", []) as Array).duplicate(true)
	stickers = (d.get("stickers", []) as Array).duplicate(true)
	citations = int(d.get("citations", 0))
	warnings = int(d.get("warnings", 0))
	meetings = int(d.get("meetings", 0))
	old_log = bool(d.get("old_log", false))
	# a book from before the weekly lists gets a seed of its own
	book_seed = int(d.get("book_seed", randi()))
	# the save is JSON: numbers come back as floats
	for f in d.get("files", []):
		var rec: Dictionary = (f as Dictionary).duplicate(true)
		for k in ["no", "day", "seed", "of"]: rec[k] = int(rec.get(k, -1 if k == "seed" else 0))
		for k in ["visit", "list"]: if rec.has(k): rec[k] = int(rec[k])
		files.append(rec)
	for a in d.get("audits", []):
		var rec: Dictionary = (a as Dictionary).duplicate(true)
		for k in ["no", "day"]: rec[k] = int(rec.get(k, 0))
		audits.append(rec)
	if d.get("overtime", null) is Dictionary:
		var ot: Dictionary = (d.overtime as Dictionary).duplicate(true)
		for k in ["day", "cash", "days", "streak", "best", "best_days", "calls", "right"]: if ot.has(k): ot[k] = int(ot[k])
		var wk: Dictionary = ot.get("week", {})
		for k in wk: if not wk[k] is Array: wk[k] = int(wk[k])
		overtime = ot

## The book as the story left it (or a fresh one outside the story, with lists of its own).
static func open_book() -> void:
	if StoryState.active and StoryState.flags.get("desk_book", null) is Dictionary: from_dict(StoryState.flags.desk_book)
	else:
		reset()
		book_seed = randi()

## Put the book back in the story's save, and hand the story the flags the desk raised.
static func close_book() -> void:
	if not StoryState.active: return
	for f in flags: StoryState.set_flag(String(f))
	flags = []
	StoryState.flags["desk_book"] = to_dict()

## Raise a story flag (handed over at clock-out).
static func raise(f: String) -> void:
	if not flags.has(f): flags.append(f)

# ------------------------------------------------------------------ the notebook

## Write something in the notebook. False if it's already there.
static func note(id: String, text: String, day: int) -> bool:
	if has_note(id): return false
	notes.append({ "id": id, "text": text, "day": day })
	raise("desk_note_" + id)
	return true

static func has_note(id: String) -> bool:
	return notes.any(func(n): return String(n.id) == id)

# ------------------------------------------------------------------ the sticker log

## The next sticker off the roll.
static func next_sticker() -> int:
	return FIRST_STICKER + stickers.size()

## A sticker goes on a windshield: logged, numbered.
static func issue(day: int, c: Dictionary) -> int:
	var no := next_sticker()
	stickers.append({ "no": no, "day": day, "plate": String(c.car.plate),
		"car": "%d %s %s" % [int(c.car.year), c.car.make, c.car.model], "vin": String(c.sheet.vin) })
	return no

## The log's rows for a page: [{no, date, plate, car}] in order. "old" is last fall's.
static func log_rows(old: bool) -> Array:
	var out: Array = []
	if old:
		for e in OLD_LOG: out.append({ "no": int(e[0]), "date": e[1], "plate": e[2], "car": e[3] })
	else:
		for s in stickers: out.append({ "no": int(s.no), "date": CounterRules.today(int(s.day)), "plate": s.plate, "car": s.car })
	return out

## The sticker numbers missing between two on the same page.
static func gap(a: int, b: int, old: bool) -> Array:
	var have := log_rows(old).map(func(r): return int(r.no))
	var out: Array = []
	for n in range(mini(a, b) + 1, maxi(a, b)):
		if not have.has(n): out.append(n)
	return out

# ------------------------------------------------------------------ the filing cabinet

## File a work order once it's stamped (or once a regular's driven off: stamp WALKED).
## `probs` is what was really wrong with it, read off the papers at the time.
static func file(day: int, c: Dictionary, stamp: String, correct: bool, probs: Array) -> Dictionary:
	var spec: Dictionary = c.get("script", {})
	var id := String(c.get("regular", ""))
	if id == "": id = String(spec.get("id", ""))
	if id == "" and c.has("courier"): id = "courier_" + String(c.courier)
	var who := String(c.licence.name) if c.has("licence") else "%s %s" % [c.person.first, c.person.last]
	var rec := { "no": next_file(), "day": day, "stamp": stamp, "correct": correct, "probs": probs.duplicate(),
		"kind": String(c.kind), "id": id, "seed": int(c.get("seed", -1)), "of": int(spec.get("of", 0)), "who": who,
		"car": "%d %s %s" % [int(c.car.year), c.car.make, c.car.model], "plate": String(c.car.plate), "request": String(c.request) }
	if c.has("want"): rec.want = String(c.want)
	if c.has("list"): rec.list = int(c.list)
	if spec.has("visit"):
		rec.visit = int(spec.visit)
		rec.last = String(spec.get("last", ""))
	files.append(rec)
	# somebody coming back about an old file: that file's done with
	if rec.of > 0:
		var old := file_no(rec.of)
		if not old.is_empty(): old.back = true
	if files.size() > MAX_FILES: files = files.slice(files.size() - MAX_FILES)
	return rec

## The next work order number.
static func next_file() -> int:
	return 1 if files.is_empty() else int(files[files.size() - 1].no) + 1

static func file_no(no: int) -> Dictionary:
	for f in files: if int(f.no) == no: return f
	return {}

## The last file on a regular (or a scripted customer, or a courier) from before `day`: {} if
## Leo's never seen them.
static func last_file(id: String, before_day := 100000) -> Dictionary:
	for i in range(files.size() - 1, -1, -1):
		var f: Dictionary = files[i]
		if String(f.id) == id and int(f.day) < before_day: return f
	return {}

# ------------------------------------------------------------------ the police's stolen lists

## The seed of the stolen list for week `week` (Constable Tremblay brings a new one every week).
static func week_list(week: int) -> int:
	return absi(hash("list_%d_%d" % [book_seed, week]))

# ------------------------------------------------------------------ overtime

## Start overtime on `day` with the book as it is and `cash` in the till (the record's bests carry
## over from any overtime before).
static func start_overtime(day: int, cash: int) -> void:
	var was := overtime
	overtime = { "day": day, "cash": cash, "week": {}, "days": 0, "streak": 0, "calls": 0, "right": 0, "ended": false,
		"best": int(was.get("best", 0)), "best_days": int(was.get("best_days", 0)) }

## A call at the window in overtime: right ones build the streak, a wrong one ends it.
static func tally(correct: bool) -> void:
	if overtime.is_empty(): return
	overtime.calls = int(overtime.calls) + 1
	if correct:
		overtime.right = int(overtime.right) + 1
		overtime.streak = int(overtime.streak) + 1
		overtime.best = maxi(int(overtime.best), int(overtime.streak))
	else: overtime.streak = 0

## Clock-out in overtime: one more day kept, and where tomorrow starts.
static func day_kept(next_day: int, cash: int, week: Dictionary) -> void:
	if overtime.is_empty(): return
	overtime.days = int(overtime.days) + 1
	overtime.best_days = maxi(int(overtime.best_days), int(overtime.days))
	overtime.day = next_day
	overtime.cash = cash
	overtime.week = week.duplicate(true)

## Write the book (overtime and all) to its own file. False if it can't.
static func save_overtime() -> bool:
	var f := FileAccess.open(overtime_path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(to_dict()))
	return true

## The overtime book from its file, if there is one to go back to. False (and the book as it
## was) if there isn't.
static func load_overtime() -> bool:
	if not FileAccess.file_exists(overtime_path): return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(overtime_path))
	if not (d is Dictionary) or not ((d as Dictionary).get("overtime", null) is Dictionary): return false
	from_dict(d)
	return true

## The record from the overtime file, without opening the book ({} if there's none).
static func overtime_on_file() -> Dictionary:
	if not FileAccess.file_exists(overtime_path): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(overtime_path))
	if not (d is Dictionary) or not ((d as Dictionary).get("overtime", null) is Dictionary): return {}
	return d.overtime

# ------------------------------------------------------------------ the Ministry

## Twelve fined citations, or a third Ministry meeting, and the station loses its licence.
static func revoked() -> bool:
	return citations >= CounterRules.REVOKE_AT or meetings >= CounterRules.MEETINGS_TO_REVOKE
