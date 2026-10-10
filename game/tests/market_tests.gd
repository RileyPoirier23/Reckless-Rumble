## MarketThing: listings, sellers, haggling, and the promise the desk makes too: every hidden
## fault can be caught at the meetup.  godot --headless --path game -s tests/market_tests.gd
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

func _init() -> void:
	var map := MapData.get_map()
	var places := Market.places(map)
	check("meetup places exist", places.size() >= 6, "%d" % places.size())
	var bad_p: Array = []
	for p in places:
		if map.ground_at(p.p) != "asphalt" or map.route(Jobs.COVINGTON, p.p).size() < 2: bad_p.append(p.name)
	check("every meetup place is on a road you can route to", bad_p.is_empty(), str(bad_p))
	# listings
	var a := Market.listings_for_day(3, places.size())
	var b := Market.listings_for_day(3, places.size())
	check("6 to 10 listings a day, the same each time you look", a.size() >= 6 and a.size() <= 10 and JSON.stringify(a) == JSON.stringify(b), "%d" % a.size())
	var bad_ask: Array = []
	var all: Array = []
	for d in 40: all.append_array(Market.listings_for_day(d, places.size()))
	for l in all:
		var cents := int(l.ask) % 100
		if not cents in [0, 99, 69]: bad_ask.append(l.ask)
	check("asking prices end in 00, 99 or 69", bad_ask.is_empty(), str(bad_ask.slice(0, 5)))
	# every fault is provable at the meetup
	var unprovable: Array = []
	for f in Market.FAULTS:
		var checks: Array = Market.FAULTS[f].checks
		if checks.is_empty(): unprovable.append(f)
		for c in checks:
			var l := { "faults": [f], "km": 241000, "km_claimed": 140000, "checked": [] }
			if not (Market.inspect(l, String(c)).found as Array).has(f): unprovable.append("%s via %s" % [f, c])
	check("every hidden fault shows up on at least one check", unprovable.is_empty(), str(unprovable))
	var clean := Market.inspect({ "faults": [], "km": 1, "km_claimed": 1, "checked": [] }, "dipstick")
	check("a clean car checks out clean", (clean.found as Array).is_empty())
	# honesty
	var lied := 0
	var told := 0
	for l in all:
		var s: Dictionary = Market.SELLERS[String(l.seller)]
		if (l.faults as Array).is_empty(): continue
		if bool(s.honest) and not s.has("scam"): told += 1 if not (l.known as Array).is_empty() or (l.faults as Array) == ["rolled_odo"] else 0
		elif not (l.known as Array).is_empty(): lied += 1
	check("honest sellers say what's wrong; the rest never do", told > 0 and lied == 0, "told %d, dishonest disclosures %d" % [told, lied])
	# haggling
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var l1 := Market.listing("silvio", rng, 1, places.size())
	l1.seller = "flipper"
	l1.patience = 40
	check("full asking price is a yes", Market.offer(l1.duplicate(true), int(l1.ask), rng).kind == "yes")
	var lowl: Dictionary = l1.duplicate(true)
	var r1 := Market.offer(lowl, int(int(l1.ask) * 0.5), rng)
	check("a lowball gets a lowball reply and costs patience", r1.kind == "lowball" and int(lowl.patience) == 15)
	Market.offer(lowl, int(int(l1.ask) * 0.5), rng)
	check("enough lowballs and they ghost you", bool(lowl.ghosted))
	var sc: Dictionary = l1.duplicate(true)
	sc.seller = "scammer"
	check("the scammer wants a deposit", Market.offer(sc, 100, rng).kind == "scam")
	var yes_r := 0
	for i in 200:
		var lt: Dictionary = l1.duplicate(true)
		lt.seller = "grandma"
		lt.patience = 90
		if Market.offer(lt, int(int(l1.ask) * 0.96), rng).kind == "yes": yes_r += 1
	check("a fair offer to a fair seller often works", yes_r > 60, "%d of 200" % yes_r)
	# value
	check("more kilometres, less value", Market.value(10000.0, 300000, []) < Market.value(10000.0, 50000, []))
	check("faults cost value", Market.value(10000.0, 100000, ["head_gasket"]) < Market.value(10000.0, 100000, []) * 0.6)
	# buying: the car comes home with its faults
	var bought := { "car": "nissun_skylion_gee_tee_arr_1991", "paint": "#2a2a2e", "km": 210000, "faults": ["worn_clutch", "head_gasket"], "deal": 9000, "ask": 9500 }
	var entry := Market.to_garage(bought)
	var spec := SaveGame.car_spec(entry)
	var sim := CarSim.new(spec)
	sim.set_wear(entry.wear)
	check("bought cars bring their faults home", sim.clutch_cond < 0.3 and sim.head_gasket and not spec.is_empty(), "clutch %.2f" % sim.clutch_cond)
	check("selling gets a fair-ish offer", Market.sell_offer(entry, rng) > 0)
	# selling your own
	var save := SaveGame.default_data()
	save.cash = 1000
	save.current = 0
	var worth := Market.your_value(save.garage[1])
	check("your car has a value", worth > 200, "$%d" % worth)
	var parted: Dictionary = (save.garage[1] as Dictionary).duplicate(true)
	parted.parts = { "intake": "intake_kandm" }
	check("parts you put on add a little", Market.your_value(parted) > worth)
	var bent: Dictionary = (save.garage[1] as Dictionary).duplicate(true)
	bent.damage = { "front": 1.0, "rear": 0.5, "left": 0.0, "right": 0.0 }
	check("a bent car is worth less", Market.your_value(bent) < worth)
	check("you can't sell the car you're in", Market.cant_sell(save, 0) != "")
	var tow_i := -1
	for i in (save.garage as Array).size():
		if String(save.garage[i].id) == "tow": tow_i = i
	check("you can't sell Toby's wrecker", tow_i < 0 or Market.cant_sell(save, tow_i) != "")
	check("you can sell another of yours", Market.cant_sell(save, 1) == "")
	check("nobody bites at 4 a.m. like they do at 6 p.m.", Market.bite_odds(1000, 1000, 4.0) < Market.bite_odds(1000, 1000, 18.0) * 0.5)
	check("a dreamer's price gets fewer bites", Market.bite_odds(3000, 1000, 18.0) < Market.bite_odds(1000, 1000, 18.0) * 0.3)
	var ad := Market.list_car(save, 1, worth, 3.0 * 24.0 + 17.0)
	check("listing it marks the car", Market.ad_for(save, 1) == ad and Market.garage_index(save, int(ad.uid)) == 1)
	var got := Market.roll_offers(ad, 5.0 * 24.0 + 17.0)
	var again := Market.roll_offers(ad, 5.0 * 24.0 + 17.0)
	var offers := got.filter(func(o): return o.kind == "offer")
	var scams := got.filter(func(o): return o.kind == "scam")
	check("two days at a fair price brings answers", got.size() >= 3, "%d" % got.size())
	check("looking again doesn't make up more", again.is_empty())
	var over := false
	for o in offers: over = over or int(o.amount) > int(ad.ask)
	check("real buyers never offer over asking", not over)
	var dupe := Market.list_car(SaveGame.default_data(), 1, worth, 0.0)
	var many: Array = []
	dupe.uid = 99
	for k in 30:
		dupe.last_h = float(k * 200)
		many.append_array(Market.roll_offers(dupe, float(k * 200 + 199)))
	var caps := many.filter(func(o): return o.kind == "scam")
	var caps_ok := not caps.is_empty()
	for o in caps: caps_ok = caps_ok and int(o.amount) > int(dupe.ask) and String(o.text).to_lower().contains("cheque")
	check("the captain always pays over asking, by cheque", caps_ok, "%d scams" % caps.size())
	var kinds := {}
	for o in many: kinds[String(o.buyer)] = true
	check("all sorts answer an ad", kinds.size() >= 6, str(kinds.keys()))
	var n0 := (save.garage as Array).size()
	if not offers.is_empty():
		var res := Market.accept(save, ad, offers[0])
		check("taking an offer sells the car and pays", (save.garage as Array).size() == n0 - 1 and int(save.cash) == 1000 + int(offers[0].amount) and int(res.index) == 1, str(res))
		check("the ad comes down with it", Market.ads(save).is_empty())
	else:
		check("taking an offer sells the car and pays", false, "no offers rolled")
	var s2 := SaveGame.default_data()
	s2.cash = 500
	s2.current = 2
	var ad2 := Market.list_car(s2, 1, 3000, 0.0)
	var r2 := Market.accept(s2, ad2, { "buyer": "scammer", "kind": "scam", "amount": 4000, "text": "" })
	check("the cheque bounces: car gone, no money", (s2.garage as Array).size() == 3 and int(s2.cash) == 500 and String(r2.text).contains("BOUNCES"))
	check("selling a car ahead of yours keeps you in yours", int(s2.current) == 1)
	var ad3 := Market.list_car(s2, 0, 3000, 0.0)
	var r3 := Market.accept(s2, ad3, { "buyer": "tirekicker", "kind": "msg", "amount": 0, "text": "" })
	check("Gerald's questions aren't offers", int(r3.index) == -1 and (s2.garage as Array).size() == 3)
	Market.unlist(s2, ad3)
	check("taking the ad down", Market.ads(s2).is_empty() and not (s2.garage[0] as Dictionary).has("for_sale"))
	# the impound auction
	var sat := 5
	check("the auction is on Saturdays", Jobs.weekday(sat) == "SATURDAY" and Auction.is_day(sat) and not Auction.is_day(sat + 1))
	var al := Auction.lots_for(sat)
	check("four lots, the same all day", al.size() == Auction.LOTS and str(al) == str(Auction.lots_for(sat)))
	var opens_low := true
	var racer_parts := 0
	var parts_fit := true
	var no_keys := 0
	for d in 60:
		for l in Auction.lots_for(d):
			if int(l.open) > maxi(100, int(int(l.worth) * 0.3)) or int(l.open) < 100: opens_low = false
			if not bool(l.keys): no_keys += 1
			var lp: Dictionary = l.parts
			if not lp.is_empty():
				racer_parts += 1
				for sl in lp:
					if Parts.slot(String(lp[sl])) != String(sl) or not Parts.fits(String(lp[sl]), CarCatalog.spec(String(l.car))): parts_fit = false
	check("lots open at about a fifth of what they're worth", opens_low)
	check("a street racer's car still has his parts on it, and they fit", racer_parts > 10 and parts_fit, "%d lots" % racer_parts)
	check("some come without keys", no_keys > 20 and no_keys < 120, "%d of 240" % no_keys)
	check("Lyle's steps: $50, then $100, then $250", Auction.step(500) == 50 and Auction.step(2000) == 100 and Auction.step(8000) == 250)
	var ar := RandomNumberGenerator.new()
	ar.seed = 3
	var lim := Auction.limits(al[0], ar)
	var lim_ok := lim.size() == Auction.BIDDERS.size()
	for i in lim.size():
		var bd: Dictionary = Auction.BIDDERS[i]
		if int(lim[i]) < int(float(al[0].worth) * float(bd.top[0])) - 1 or int(lim[i]) > int(float(al[0].worth) * float(bd.top[1])) + 1: lim_ok = false
	check("each bidder has a limit, somewhere around what it's worth", lim_ok, str(lim))
	# $1,990 on a $1,999 ask: a counter splits the difference, it doesn't round up past the ask
	var off_range: Array = []
	var counters := 0
	for sd in 400:
		var hl := { "seller": "flipper", "ask": 1999, "patience": 999, "ghosted": false, "deal": -1, "chat": [] }
		var hr := RandomNumberGenerator.new()
		hr.seed = sd
		var ans := Market.offer(hl, 1990, hr)
		if String(ans.kind) == "counter":
			counters += 1
			if int(ans.amount) > 1999 or int(ans.amount) < 1990: off_range.append(int(ans.amount))
	check("a counter-offer lands between your offer and the ask", counters > 0 and off_range.is_empty(), "%d counters, out of range: %s" % [counters, str(off_range.slice(0, 3))])
	# a check under the hood at five to midnight: ten minutes later it's tomorrow, and the parts
	# truck's clock moved too
	var sky := WorldSky.new()
	sky.day = 4
	sky.time_h = 23.95
	var sv := { "clock_h": 120.0 }
	SaveGame.pass_hours(sky, sv, 1.0 / 6.0)
	check("ten minutes at the meetup runs past midnight into the next day", sky.day == 5 and absf(sky.time_h - 0.1167) < 0.01 and absf(float(sv.clock_h) - 120.1667) < 0.01,
		"day %d %.3f h, clock %.3f" % [sky.day, sky.time_h, float(sv.clock_h)])
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)
