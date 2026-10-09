## MarketThing, the used-car market: listings every morning off the catalogue, sellers who lie
## (or don't), haggling, and the meetup checks that catch what the listing doesn't say.
## Pure data and functions; MarketApp is the phone app and MarketRunner runs meetups.
class_name Market
extends RefCounted

## Seller types: asking price as a share of value, the lowest share they'll take, whether they
## say what's wrong, patience for lowballs, and what they sound like.
const SELLERS := {
	"grandma": { "name": "MARGUERITE (78)", "ask": [0.95, 1.05], "floor": 0.92, "honest": true, "patience": 90,
		"hi": "It was my husband's. He'd want it to go to a nice boy.", "yes": "Oh good. Come by after supper. I'll make tea.",
		"low": "Oh dear. I don't think Roger would like that.", "counter": "Could you do %s? For Roger." },
	"flipper": { "name": "KYLE B.", "ask": [1.25, 1.45], "floor": 0.80, "honest": false, "patience": 40,
		"hi": "no lowballs i know what i have", "yes": "deal. cash only. no test drives after dark",
		"low": "lol", "counter": "%s firm. got 3 other guys asking" },
	"darrell": { "name": "DARRELL", "ask": [1.10, 1.30], "floor": 0.75, "honest": false, "patience": 60, "sixty_nine": true,
		"hi": "selling for my wife's husband. runs mint", "yes": "SOLD. dont tell my wife", "low": "come on bud",
		"counter": "%s and ill throw in a air freshener" },
	"ghost": { "name": "T. LEBLANC", "ask": [1.0, 1.2], "floor": 0.88, "honest": true, "patience": 50, "ghost": 0.4,
		"hi": "is this still available? yes", "yes": "ok", "low": "...", "counter": "%s?" },
	"scammer": { "name": "JOHN SMITH 4471", "ask": [0.5, 0.7], "floor": 0.5, "honest": true, "patience": 99, "scam": true,
		"hi": "Hello dear friend. Car is available. Shipping included.", "yes": "Please send e-transfer deposit $200 to hold",
		"low": "Ok friend. Send deposit first.", "counter": "Ok %s. Send deposit $200 first." },
	"estate": { "name": "THE THERIAULT ESTATE", "ask": [0.7, 0.9], "floor": 0.85, "honest": true, "patience": 80,
		"hi": "Selling Dad's car. He kept it nice. Mostly.", "yes": "Okay. It's what he'd want.", "low": "That's a bit low for Dad's car.",
		"counter": "Would you do %s?" },
	"trader": { "name": "JAY-P", "ask": [1.0, 1.3], "floor": 0.85, "honest": true, "patience": 60,
		"hi": "open to trades. jet ski, sled, four wheeler, or ur car plus cash", "yes": "deal bud", "low": "no but whats ur trade",
		"counter": "%s or a sled" },
}
const SELLER_ODDS := [["grandma", 1.0], ["flipper", 2.0], ["darrell", 1.2], ["ghost", 1.0], ["scammer", 0.5], ["estate", 0.8], ["trader", 1.0]]

## Hidden faults: what they do to the car you buy, what they take off its value, and which
## meetup checks give them away (every fault has at least one).
const FAULTS := {
	"head_gasket": { "label": "HEAD GASKET GOING", "value": 0.55, "checks": ["dipstick", "coolant_cap", "smoke"], "wear": { "gasket": true } },
	"rolled_odo": { "label": "ODOMETER ROLLED BACK", "value": 0.8, "checks": ["oil_sticker"], "wear": {} },
	"worn_clutch": { "label": "CLUTCH SLIPPING", "value": 0.85, "checks": ["test_drive"], "wear": { "clutch": 0.28 } },
	"dead_turbo": { "label": "TURBO DONE", "value": 0.7, "checks": ["smoke", "test_drive"], "wear": { "turbo": 0.08 }, "turbo": true },
	"bald_tires": { "label": "BALD TIRES", "value": 0.95, "checks": ["tread"], "wear": { "tread": 1.5 } },
	"worn_pads": { "label": "PADS TO THE METAL", "value": 0.95, "checks": ["creeper", "test_drive"], "wear": { "pads": 0.8 } },
	"frame_rust": { "label": "FRAME RUST", "value": 0.65, "checks": ["creeper"], "wear": {} },
	"cold_start": { "label": "HARD COLD START (WARMED UP TO HIDE IT)", "value": 0.85, "checks": ["hood"], "wear": { "engine": 0.8 } },
}

## The checks at a meetup and what you see with and without each fault.
const CHECKS := {
	"hood": { "label": "TOUCH THE HOOD", "fault": { "cold_start": "WARM. HE STARTED IT BEFORE YOU GOT HERE. WHY?" }, "ok": "STONE COLD. GOOD SIGN." },
	"dipstick": { "label": "PULL THE DIPSTICK", "fault": { "head_gasket": "MILKSHAKE. CHOCOLATE MILK ON THE STICK." }, "ok": "AMBER. A BIT DARK. FINE." },
	"coolant_cap": { "label": "OPEN THE COOLANT CAP (COLD)", "fault": { "head_gasket": "AN OILY FILM ON THE COOLANT. BUBBLES WHEN IT IDLES." }, "ok": "GREEN, SWEET, NO FILM." },
	"smoke": { "label": "WATCH IT START", "fault": { "head_gasket": "SWEET WHITE SMOKE THAT DOESN'T CLEAR.", "dead_turbo": "BLUE SMOKE WHEN IT REVS. THE TURBO'S EATING OIL." }, "ok": "A PUFF, THEN NOTHING." },
	"oil_sticker": { "label": "ODOMETER VS THE OIL STICKER", "fault": { "rolled_odo": "THE STICKER SAYS %s KM. THE DASH SAYS %s." }, "ok": "STICKER AND DASH AGREE." },
	"creeper": { "label": "CREEPER LIGHT UNDERNEATH", "fault": { "frame_rust": "THE FRAME RAILS ARE MOSTLY RUST AND HOPE.", "worn_pads": "THE PADS ARE PAPER-THIN. YOU CAN SEE THE ROTOR SCORING." }, "ok": "DRY, SOLID, NO FRESH UNDERCOATING HIDING ANYTHING." },
	"tread": { "label": "TREAD GAUGE", "fault": { "bald_tires": "2 MM. BALD AS GUS." }, "ok": "PLENTY OF TREAD." },
	"test_drive": { "label": "TEST DRIVE", "fault": { "worn_clutch": "IT SLIPS UNDER POWER. RPM UP, SPEED NOT.", "dead_turbo": "NO BOOST AT ALL. IT'S A SLOW CAR NOW.", "worn_pads": "THE BRAKES GRIND AND IT TAKES FOREVER TO STOP." }, "ok": "DRIVES LIKE IT SHOULD." },
}
const CHECK_ORDER := ["hood", "smoke", "dipstick", "coolant_cap", "oil_sticker", "tread", "creeper", "test_drive"]

const TITLES := ["%s runs great needs nothing", "%s - MUST GO", "%s first $%s takes it", "%s project, good bones",
	"%s, garage kept (mostly)", "%s winter beater", "%s no rust (some rust)", "%s needs TLC", "%s lady driven", "%s sleeper"]

## Where sellers meet you: the Tim Burtons lots, the towns, the big parking lots. Each with
## the road point in front of it.
static func places(map: MapData) -> Array:
	var out: Array = []
	var tims := 0
	for l in map.landmarks:
		var n := String(l.name)
		if n == "TIM BURTONS":
			tims += 1
			var rd := map.nearest_road(l.p, 60.0)
			out.append({ "name": "TIM BURTONS #%d" % tims, "p": rd.get("point", l.p) })
		elif bool(l.get("dest", false)) and not n in ["COVINGTON AUTO", "AIRSTRIP 7", "LIME QUARRY", "HAVELOCK AIRFIELD"]:
			var rd2 := map.nearest_road(l.p, 80.0)
			out.append({ "name": n, "p": rd2.get("point", l.p) })
	return out

## Today's listings: 6 to 10, the same every time for a given day.
static func listings_for_day(day: int, place_count: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90001 + day * 7919
	var ids := CarCatalog.ids()
	var out: Array = []
	var n := 6 + rng.randi() % 5
	for k in n:
		var id: String = ids[rng.randi() % ids.size()]
		out.append(listing(id, rng, day * 100 + k, place_count))
	return out

static func pick_seller(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for s in SELLER_ODDS: total += float(s[1])
	var roll := rng.randf() * total
	for s in SELLER_ODDS:
		roll -= float(s[1])
		if roll <= 0.0: return String(s[0])
	return "flipper"

## One listing for a catalogue car.
static func listing(id: String, rng: RandomNumberGenerator, uid: int, place_count: int) -> Dictionary:
	var e := CarCatalog.entry(id)
	var spec := CarCatalog.spec(id)
	var year := int(e.get("year", 2000))
	var age := maxi(0, CarCatalog.GAME_YEAR - year)
	var km := int(clampf(float(age) * 16000.0 * rng.randf_range(0.5, 1.4), 2000.0, 480000.0))
	var seller := pick_seller(rng)
	var s: Dictionary = SELLERS[seller]
	var turbo := not (spec.engine.get("turbo", {}) as Dictionary).is_empty()
	var faults: Array = []
	var odds := clampf(0.08 + float(age) * 0.012, 0.08, 0.45)
	for f in FAULTS:
		if f == "dead_turbo" and not turbo: continue
		if f == "rolled_odo" and (bool(s.honest) or km < 120000): continue
		if f == "cold_start" and bool(s.honest): continue
		if rng.randf() < odds * (1.4 if not bool(s.honest) else 0.8): faults.append(f)
	var km_claimed := int(km * 0.58) if faults.has("rolled_odo") else km
	var v := value(float(e.get("price", 5000.0)), km, faults)
	var ask := ask_price(v * rng.randf_range(float(s.ask[0]), float(s.ask[1])), bool(s.get("sixty_nine", false)))
	var paints: Array = e.get("paints", ["#8a8e94"])
	var title_t: String = TITLES[rng.randi() % TITLES.size()]
	var short := "%d %s %s" % [year, String(e.make).to_lower(), String(e.model).to_lower()]
	var title := title_t % [short, str(ask)] if title_t.count("%s") == 2 else title_t % short
	return { "uid": uid, "car": id, "year": year, "km": km, "km_claimed": km_claimed, "faults": faults,
		"known": faults.filter(func(f): return f != "rolled_odo") if bool(s.honest) and not s.has("scam") else [],
		"seller": seller, "ask": ask, "value": int(v), "paint": paints[rng.randi() % paints.size()],
		"title": title, "place": rng.randi() % maxi(1, place_count), "patience": int(s.patience),
		"deal": -1, "ghosted": false, "checked": [], "chat": [[seller, String(s.hi)]] }

## What it's really worth: base x mileage x condition (the faults).
static func value(base: float, km: int, faults: Array) -> float:
	var k := clampf(1.25 - float(km) / 400000.0, 0.35, 1.2)
	for f in faults: k *= float(FAULTS[f].value)
	return base * k

## Asking prices end in 00, 99 or 69.
static func ask_price(x: float, sixty_nine := false) -> int:
	var h := int(round(x / 100.0)) * 100
	if sixty_nine: return maxi(169, h - 31)
	return maxi(200, h - (1 if int(x) % 3 == 0 else 0))

## The seller's answer to an offer. Returns { kind: yes/counter/lowball/ghosted/scam, amount, text }
## and updates the listing's patience and deal.
static func offer(l: Dictionary, amount: int, rng: RandomNumberGenerator) -> Dictionary:
	var s: Dictionary = SELLERS[String(l.seller)]
	if bool(l.ghosted): return { "kind": "ghosted", "amount": 0, "text": "(seen)" }
	if s.has("ghost") and rng.randf() < float(s.ghost):
		l.ghosted = true
		return { "kind": "ghosted", "amount": 0, "text": "(seen)" }
	var r := float(amount) / float(l.ask)
	var res := {}
	if s.has("scam"):
		res = { "kind": "scam", "amount": amount, "text": String(s.yes) }
	elif r >= 1.0:
		res = { "kind": "yes", "amount": amount, "text": String(s.yes) }
	elif r < float(s.floor):
		l.patience = int(l.patience) - 25
		res = { "kind": "lowball", "amount": 0, "text": String(s.low) }
	elif rng.randf() < pow((r - float(s.floor)) / (1.0 - float(s.floor)), 1.5):
		res = { "kind": "yes", "amount": amount, "text": String(s.yes) }
	else:
		l.patience = int(l.patience) - 10
		var c := (amount + int(l.ask)) / 2
		c = (c / 100) * 100 + 69 if bool(s.get("sixty_nine", false)) else int(round(c / 50.0)) * 50
		res = { "kind": "counter", "amount": c, "text": String(s.counter) % ("$" + str(c)) }
	if int(l.patience) <= 0 and res.kind != "yes":
		l.ghosted = true
		res = { "kind": "ghosted", "amount": 0, "text": "(seen)" }
	if res.kind == "yes": l.deal = amount
	(l.chat as Array).append(["you", "$%d?" % amount])
	(l.chat as Array).append([String(l.seller), String(res.text)])
	return res

## What a check at the meetup shows for this listing.
static func inspect(l: Dictionary, check: String) -> Dictionary:
	var c: Dictionary = CHECKS[check]
	var found: Array = []
	var lines: Array = []
	for f in l.faults:
		if (c.fault as Dictionary).has(f):
			found.append(f)
			var t := String(c.fault[f])
			if f == "rolled_odo": t = t % [_km(int(l.km)), _km(int(l.km_claimed))]
			lines.append(t)
	if lines.is_empty(): lines.append(String(c.ok))
	if not (l.checked as Array).has(check): (l.checked as Array).append(check)
	return { "found": found, "text": " ".join(lines) }

static func _km(n: int) -> String:
	var s := str(n)
	return s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3) if s.length() > 3 else s

## The wear the car arrives with, from its faults and its age.
static func wear_for(l: Dictionary) -> Dictionary:
	var w := { "pads": 6.0 if int(l.km) > 80000 else 9.0, "fluid": 0.7 if int(l.km) > 100000 else 0.95,
		"clutch": clampf(1.0 - float(l.km) / 600000.0, 0.5, 1.0), "turbo": clampf(1.0 - float(l.km) / 700000.0, 0.5, 1.0) }
	for f in l.faults:
		var fw: Dictionary = FAULTS[f].wear
		for k in fw: w[k] = fw[k]
	return w

## The garage entry for a car you just bought.
static func to_garage(l: Dictionary) -> Dictionary:
	return { "id": String(l.car), "paint": String(l.paint), "damage": {}, "parts": {}, "looks": {}, "tune": {},
		"wear": wear_for(l), "installing": [], "odo_km": float(l.km), "bought": int(l.deal if int(l.deal) > 0 else l.ask) }

## What someone will pay for your car (a quick private sale): value x 0.8 to 1.0.
static func sell_offer(entry: Dictionary, rng: RandomNumberGenerator) -> int:
	var e := CarCatalog.entry(String(entry.id))
	var faults: Array = []
	var w: Dictionary = entry.get("wear", {})
	if bool(w.get("gasket", false)): faults.append("head_gasket")
	if float(w.get("clutch", 1.0)) < 0.5: faults.append("worn_clutch")
	if float(w.get("turbo", 1.0)) < 0.3: faults.append("dead_turbo")
	var v := value(float(e.get("price", 5000.0)), int(entry.get("odo_km", 150000.0)), faults)
	return int(round(v * rng.randf_range(0.8, 1.0) / 50.0)) * 50
