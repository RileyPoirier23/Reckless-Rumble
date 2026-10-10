## Gus's tool drawer: the things Leo can buy for the counter between shifts, paid out of the
## till (in the story, out of Leo's own money). Papers, Please style: each one makes one check
## the desk already has quicker (or surer), and none of them stamps anything.
##
## A tool works on one kind of fact: pick that fact twice (INSPECT, the same thing again) and
## the tool reads it. The tread gauge reads the tread or the pads on Gus's sheet against the
## safety limits, the date wheel reads any date against the calendar, the loupe reads a plate,
## a VIN or a serial against the stolen list, and the UV lamp reads the seal on a paper (a fake
## doesn't glow). The first three say exactly what the two-pick comparison would say, so a tool
## is never more than a shortcut; the lamp only says whether a paper's real, and a real paper can
## still be out of date.
##
## What Leo owns lives in DeskBook.tools, so it saves with the desk (the story's save, overtime's
## file) and starts over with a fresh book.
class_name DeskTools
extends RefCounted

## The drawer, cheapest first: {id, name, price, rule (the check it's for: offered once that's on
## the wall), what (what it does), gus (what Gus says when you buy it)}.
const TOOLS := [
	{ "id": "gauge", "name": "TREAD GAUGE", "price": 750, "rule": "inspect",
		"what": "PICK THE TREAD OR THE PADS ON GUS'S SHEET TWICE: READ AGAINST THE SAFETY LIMITS. NO FLIPPING THROUGH THE BINDER.",
		"gus": "GUS: \"FRANK'S WAS BRASS. THIS ONE'S PLASTIC. IT STILL KNOWS WHAT 1.6 MILLIMETRES LOOKS LIKE.\"" },
	{ "id": "wheel", "name": "DATE WHEEL", "price": 900, "rule": "reg_valid",
		"what": "PICK ANY DATE TWICE: THE WHEEL COUNTS IT AGAINST TODAY (OR A PULLED FILE'S DATE). NO TRIP TO THE CALENDAR.",
		"gus": "GUS: \"CARDBOARD. NINE HUNDRED DOLLARS. IT'S LAMINATED, KID. THAT'S THE EXPENSIVE PART.\"" },
	{ "id": "loupe", "name": "LOUPE", "price": 1150, "rule": "bolo",
		"what": "PICK A PLATE, A VIN OR A SERIAL TWICE: READ IT AGAINST THE STOLEN LIST. NO SQUINTING AT THE CORKBOARD.",
		"gus": "GUS: \"MY EYES WERE GOOD IN 1981. THIS IS FOR WHEN YOURS AREN'T.\"" },
	{ "id": "lamp", "name": "UV LAMP", "price": 1500, "rule": "bos",
		"what": "PICK THE SEAL ON A PAPER TWICE: A REAL ONE GLOWS, A FAKE DOESN'T. OUT OF DATE IS STILL REAL: READ THE DATES.",
		"gus": "GUS: \"A REAL SEAL LIGHTS UP. A FAKE ONE JUST SITS THERE LOOKING GUILTY. LIKE DARRELL.\"" },
]
## The papers with a seal or a stamp on them (the ones the lamp reads).
const SEALED := ["bos", "permit", "glovebox", "door_inv", "cert", "exempt", "notice", "customs", "invoice"]
## A fake paper is a question about what it was supposed to prove.
const SEAL_TOPIC := { "bos": "bos_forged", "permit": "expired_reg", "glovebox": "insurance_expired", "door_inv": "vin_door_mismatch",
	"cert": "salvage_no_cert", "exempt": "tint", "notice": "wrong_part", "invoice": "hot_part", "customs": "customs_value" }
## The facts each tool reads.
const DATES := ["expiry", "start", "dated", "sold"]
const LISTED := ["plate", "vin", "serial"]

static func tool(id: String) -> Dictionary:
	for t in TOOLS: if String(t.id) == id: return t
	return {}

## What's in the drawer on the evening of `day`: every tool whose check is on the wall by the
## next open day.
static func offered(day: int) -> Array:
	var next := CounterRules.next_open(day)
	return TOOLS.filter(func(t): return CounterRules.rule_active(String(t.rule), next))

## Which of the tools Leo `owned` reads this fact ("" for none).
static func tool_for(f: Dictionary, owned: Array) -> String:
	var k := String(f.get("key", ""))
	if owned.has("gauge") and k == "measure" and f.get("val") is Dictionary and String(f.val.get("kind", "")) in ["tread", "pads"]: return "gauge"
	if owned.has("wheel") and DATES.has(k): return "wheel"
	if owned.has("loupe") and LISTED.has(k): return "loupe"
	if owned.has("lamp") and k == "seal": return "lamp"
	return ""

## A tool on a fact, on `day` (the day the papers are read against), with the stolen list on
## the wall: [what it says, good (true, false or null), the ASK topic a red opens, the tool's
## name]. [] if none of the tools Leo owns reads it.
static func read(c: Dictionary, day: int, bolo_list: Array, f: Dictionary, owned: Array) -> Array:
	var id := tool_for(f, owned)
	var v: Array = []
	match id:
		"gauge": v = CounterRules.compare(c, day, bolo_list, f, { "key": "rule", "val": "inspect", "doc": "" })
		"wheel": v = CounterRules.compare(c, day, bolo_list, f, { "key": "today", "val": CounterRules.today(day), "doc": "" })
		"loupe":
			if not CounterRules.rule_active("bolo", day): v = ["NO STOLEN LIST THAT DAY", null, ""]
			else: v = CounterRules.compare(c, day, bolo_list, f, { "key": "bolo", "val": 0, "doc": "" })
		"lamp": v = seal(c, String(f.get("val", "")))
		_: return []
	return [v[0], v[1], v[2], String(tool(id).name)]

## The UV lamp on a paper's seal: [what it shows, good, ASK topic].
static func seal(c: Dictionary, doc: String) -> Array:
	if not c.get(doc, null) is Dictionary or (c[doc] as Dictionary).is_empty(): return ["NOTHING TO SHINE IT ON", null, ""]
	if not forged(c, doc): return ["IT GLOWS: A REAL ONE", true, ""]
	if doc == "invoice": return ["THE SERIAL'S BEEN WRITTEN OVER", false, "hot_part"]
	return ["NO GLOW: A FAKE", false, String(SEAL_TOPIC.get(doc, ""))]

## A paper somebody's made up or written over: what it names (a VIN, a plate, a door, a person,
## a part number, a serial) isn't the car, the person or the box at the window. A real paper
## that's merely out of date (or a real card for some other car) isn't forged.
static func forged(c: Dictionary, doc: String) -> bool:
	var d: Dictionary = c.get(doc, {}) if c.get(doc, null) is Dictionary else {}
	if d.is_empty(): return false
	var dash := String((c.get("sheet", {}) as Dictionary).get("vin", ""))
	match doc:
		"bos": return String(d.seller) != String(c.reg.owner) or String(d.buyer) != String(c.licence.name) or String(d.vin) != dash
		"permit": return String(d.vin) != dash or String(d.plate) != String(c.car.plate)
		"door_inv": return String(d.vin) != dash or String(d.door) != String(c.sheet.door)
		"cert": return String(d.vin) != dash
		"exempt": return String(d.vin) != dash or String(d.name) != String(c.licence.name)
		"notice": return String(d.was) != String(c.order.no) or String(d.now) != String(c.slip.no)
		"invoice": return String(d.serial) != String((c.get("sheet", {}) as Dictionary).get("serial", d.serial))
	return false
