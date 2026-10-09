## Leo's books at the counter: his notebook (what he's caught people saying, and what he's
## worked out), the station's sticker log (every inspection sticker issued, last fall's pages
## included), and the Ministry's tally on him.
##
## Static, like StoryState. In the story it lives in StoryState.flags["desk_book"], so it saves
## and starts over with the story; free play starts a fresh book every time.
##
## Hooks for the story: DeskBook.note(id, text, day) writes in the notebook, has_note(id)
## asks, old_log = true brings last fall's pages out of the filing cabinet.
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
	[451, [2018, 12, 4], "RVR 773", "2012 KEEYA SOUL-LESS"], [452, [2018, 12, 5], "WLK 450", "2007 VOLKSWAGON GULF"],
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

## A blank book.
static func reset() -> void:
	notes = []
	stickers = []
	citations = 0
	warnings = 0
	meetings = 0
	old_log = false
	flags = []

static func to_dict() -> Dictionary:
	return { "notes": notes, "stickers": stickers, "citations": citations, "warnings": warnings,
		"meetings": meetings, "old_log": old_log }

static func from_dict(d: Dictionary) -> void:
	reset()
	notes = (d.get("notes", []) as Array).duplicate(true)
	stickers = (d.get("stickers", []) as Array).duplicate(true)
	citations = int(d.get("citations", 0))
	warnings = int(d.get("warnings", 0))
	meetings = int(d.get("meetings", 0))
	old_log = bool(d.get("old_log", false))

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

# ------------------------------------------------------------------ the Ministry

## Twelve fined citations, or a third Ministry meeting, and the station loses its licence.
static func revoked() -> bool:
	return citations >= CounterRules.REVOKE_AT or meetings >= CounterRules.MEETINGS_TO_REVOKE
