## Leo's books at the counter: his notebook (what he's caught people saying, and what he's
## worked out), the station's sticker log (every inspection sticker issued, last fall's pages
## included), the filing cabinet (every work order he's stamped, which is how the regulars and
## the people he turned away remember him, and what the Ministry's auditor pulls), and the
## Ministry's tally on him.
##
## Static, like StoryState. In the story it lives in StoryState.flags["desk_book"], so it saves
## and starts over with the story; free play starts a fresh book every time.
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
## Every work order stamped: [{no, day, stamp, correct, probs, kind, id, seed, of, who, car,
## plate, request, back, pulled, visit, last}]. `id` names a regular, a scripted customer or a
## courier ("" for a walk-in), `seed` rebuilds a walk-in's or a box's papers (-1 if it can't),
## `visit` and `last` rebuild a regular's (which visit, and what Leo had stamped on them before
## it), `of` is the file a returning customer came back about, `back` says they did. WALKED is
## the stamp for a regular who drove off at six.
static var files: Array = []
## Inspector Hachey's audit: [{no, day, was, now, right}] for every file he pulled (`right`:
## the first stamp was the right call).
static var audits: Array = []
const MAX_FILES := 400                # the cabinet keeps the newest

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

static func to_dict() -> Dictionary:
	return { "notes": notes, "stickers": stickers, "citations": citations, "warnings": warnings,
		"meetings": meetings, "old_log": old_log, "files": files, "audits": audits }

static func from_dict(d: Dictionary) -> void:
	reset()
	notes = (d.get("notes", []) as Array).duplicate(true)
	stickers = (d.get("stickers", []) as Array).duplicate(true)
	citations = int(d.get("citations", 0))
	warnings = int(d.get("warnings", 0))
	meetings = int(d.get("meetings", 0))
	old_log = bool(d.get("old_log", false))
	# the save is JSON: numbers come back as floats
	for f in d.get("files", []):
		var rec: Dictionary = (f as Dictionary).duplicate(true)
		for k in ["no", "day", "seed", "of"]: rec[k] = int(rec.get(k, -1 if k == "seed" else 0))
		if rec.has("visit"): rec.visit = int(rec.visit)
		files.append(rec)
	for a in d.get("audits", []):
		var rec: Dictionary = (a as Dictionary).duplicate(true)
		for k in ["no", "day"]: rec[k] = int(rec.get(k, 0))
		audits.append(rec)

## The book as the story left it (or a fresh one outside the story).
static func open_book() -> void:
	if StoryState.active and StoryState.flags.get("desk_book", null) is Dictionary: from_dict(StoryState.flags.desk_book)
	else: reset()

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

# ------------------------------------------------------------------ the Ministry

## Twelve fined citations, or a third Ministry meeting, and the station loses its licence.
static func revoked() -> bool:
	return citations >= CounterRules.REVOKE_AT or meetings >= CounterRules.MEETINGS_TO_REVOKE
