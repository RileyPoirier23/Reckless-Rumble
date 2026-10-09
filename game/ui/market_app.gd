## MarketThing on Leo's phone. BUY: today's listings, a listing with its bad phone photo, and the
## chat where you haggle; MEET sends the GPS to the seller (the meetup itself is MarketRunner's).
## SELL: your garage, an ad for one of your cars, and whoever answers it.
class_name MarketApp
extends RefCounted

signal meet(listing: Dictionary)
signal sold(index: int, text: String)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const RED := Color("e0402e")
const BLUE := Color("4a7ab8")

var save: Dictionary
var places: Array = []           # [{ name, p }]
var screen := "list"             # BUY: list, detail, offer. SELL: garage, price, offers
var tab := 0                     # 0 BUY, 1 SELL
var sel := 0
var gsel := 0
var osel := 0
var amount := 0
var now_h := 0.0
var toast := ""
var _toast_until := 0
var _photos := {}
var _rng := RandomNumberGenerator.new()

func setup(the_save: Dictionary, the_places: Array, day: int, hour := 12.0) -> void:
	save = the_save
	places = the_places
	now_h = day * 24.0 + hour
	for ad in Market.ads(save): Market.roll_offers(ad, now_h)
	var m: Dictionary = save.get("market", {})
	if int(m.get("day", -1)) != day:
		var keep: Array = []
		for l in m.get("listings", []):
			if int(l.get("deal", -1)) > 0 and not l.get("sold", false): keep.append(l)      # deals you made stay open
		m = { "day": day, "listings": keep + Market.listings_for_day(day, places.size()) }
		save.market = m
	_rng.seed = int(Time.get_ticks_usec())

func listings() -> Array:
	return save.market.listings

func current() -> Dictionary:
	var ls := listings()
	return ls[clampi(sel, 0, ls.size() - 1)] if not ls.is_empty() else {}

func place_name(l: Dictionary) -> String:
	return String(places[int(l.place) % places.size()].name) if not places.is_empty() else "SOMEWHERE"

func _say(s: String) -> void:
	toast = s
	_toast_until = Time.get_ticks_msec() + 3500

## Input while the app is open. Returns false when the app wants the phone to close.
func handle() -> bool:
	if screen in ["list", "garage"] and (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")):
		tab = 1 - tab
		screen = "garage" if tab == 1 else "list"
		return true
	if tab == 1: return _handle_sell()
	var ls := listings()
	if ls.is_empty(): return true
	match screen:
		"list":
			if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % ls.size()
			if Input.is_action_just_pressed("ui_up"): sel = (sel + ls.size() - 1) % ls.size()
			if Input.is_action_just_pressed("ui_accept"): screen = "detail"
		"detail":
			if Input.is_action_just_pressed("ui_cancel"):
				screen = "list"
				return true
			if Input.is_action_just_pressed("ui_accept"):
				var l := current()
				amount = int(l.deal) if int(l.deal) > 0 else int(round(float(l.ask) * 0.85 / 50.0)) * 50
				screen = "offer"
			if Input.is_action_just_pressed("use"):
				meet.emit(current())
				return false
		"offer":
			if Input.is_action_just_pressed("ui_cancel"):
				screen = "detail"
				return true
			if Input.is_action_just_pressed("ui_right"): amount += 50
			if Input.is_action_just_pressed("ui_left"): amount = maxi(50, amount - 50)
			if Input.is_action_just_pressed("ui_up"): amount += 500
			if Input.is_action_just_pressed("ui_down"): amount = maxi(50, amount - 500)
			if Input.is_action_just_pressed("ui_accept"):
				var res := Market.offer(current(), amount, _rng)
				if res.kind == "counter": amount = int(res.amount)
	return true

func _handle_sell() -> bool:
	var g: Array = save.garage
	gsel = clampi(gsel, 0, g.size() - 1)
	match screen:
		"garage":
			if Input.is_action_just_pressed("ui_down"): gsel = (gsel + 1) % g.size()
			if Input.is_action_just_pressed("ui_up"): gsel = (gsel + g.size() - 1) % g.size()
			if Input.is_action_just_pressed("ui_accept"):
				if not Market.ad_for(save, gsel).is_empty():
					screen = "offers"
					osel = 0
				else:
					var why := Market.cant_sell(save, gsel)
					if why != "": _say(why)
					else:
						amount = maxi(100, int(round(Market.your_value(g[gsel]) * 1.1 / 100.0)) * 100)
						screen = "price"
		"price":
			if Input.is_action_just_pressed("ui_cancel"):
				screen = "garage"
				return true
			if Input.is_action_just_pressed("ui_right"): amount += 100
			if Input.is_action_just_pressed("ui_left"): amount = maxi(100, amount - 100)
			if Input.is_action_just_pressed("ui_up"): amount += 1000
			if Input.is_action_just_pressed("ui_down"): amount = maxi(100, amount - 1000)
			if Input.is_action_just_pressed("ui_accept"):
				Market.list_car(save, gsel, amount, now_h)
				SaveGame.write(save)
				_say("LISTED AT $%d. NOW YOU WAIT. GERALD WILL BE IN TOUCH." % amount)
				screen = "garage"
		"offers":
			var ad := Market.ad_for(save, gsel)
			if ad.is_empty() or Input.is_action_just_pressed("ui_cancel"):
				screen = "garage"
				return true
			var n := (ad.offers as Array).size() + 1
			if Input.is_action_just_pressed("ui_down"): osel = (osel + 1) % n
			if Input.is_action_just_pressed("ui_up"): osel = (osel + n - 1) % n
			if Input.is_action_just_pressed("ui_accept"):
				if osel == n - 1:
					Market.unlist(save, ad)
					SaveGame.write(save)
					_say("AD'S DOWN.")
					screen = "garage"
				else:
					var o: Dictionary = ad.offers[(ad.offers as Array).size() - 1 - osel]      # newest first
					var res := Market.accept(save, ad, o)
					_say(String(res.text))
					if int(res.index) >= 0:
						sold.emit(int(res.index), String(res.text))
						gsel = 0
						screen = "garage"
	return true

## Does the phone's own back button belong to us right now?
func wants_back() -> bool:
	return not screen in ["list", "garage"]

func _photo(l: Dictionary) -> ImageTexture:
	var key := int(l.uid)
	if _photos.has(key): return _photos[key]
	var spec := CarCatalog.spec(String(l.car))
	var full := PixCars.showroom(spec, 150, Color(String(l.paint)), { "year": int(l.year) })
	var img := full.get_region(full.get_used_rect().grow(6).intersection(Rect2i(Vector2i.ZERO, full.get_size())))
	# a bad phone photo: a dark driveway, a little flash glare, never quite level
	var out := Image.create(img.get_width() + 10, img.get_height() + 6, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = key
	var dark := rng.randf_range(0.0, 0.45)
	out.fill(Color("3a3e44").darkened(dark))
	out.fill_rect(Rect2i(0, out.get_height() - 14, out.get_width(), 14), Color("2a2c30").darkened(dark))
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(5, 0))
	if rng.randf() < 0.5:
		for y in 10:
			for x in 14:
				out.set_pixel(out.get_width() - 30 + x + y / 3, 8 + y, Color(1, 1, 0.9, 0.5).blend(out.get_pixel(out.get_width() - 30 + x + y / 3, 8 + y)))
	if rng.randf() < 0.3:
		out.fill_rect(Rect2i(0, out.get_height() - 24, 16, 24), Color("c89878"))          # a thumb
	var tex := ImageTexture.create_from_image(out)
	_photos[key] = tex
	return tex

func draw_app(ci: CanvasItem, r: Rect2) -> void:
	var ls := listings()
	PixelFont.draw_centered(ci, r.get_center().x, r.position.y + 24, "MARKETTHING", BLUE.lightened(0.3), 2)
	if Time.get_ticks_msec() < _toast_until:
		var tl := Hud.wrap_lines(toast, 36)
		var ty := r.end.y - 40 - tl.size() * 9
		ci.draw_rect(Rect2(r.position.x + 6, ty - 3, r.size.x - 12, tl.size() * 9 + 5), Color(0.1, 0.12, 0.2, 0.95))
		for k in tl.size(): PixelFont.draw_centered(ci, r.get_center().x, ty + k * 9, tl[k], BONE)
	if screen in ["list", "garage"]:
		for t in 2:
			var tx := r.position.x + 40 + t * (r.size.x - 80)
			var on := t == tab
			PixelFont.draw_centered(ci, tx, r.position.y + 40, ["BUY", "SELL"][t], BONE if on else ASH)
			if on: ci.draw_rect(Rect2(tx - 14, r.position.y + 49, 28, 1), BLUE.lightened(0.3))
	if tab == 1:
		match screen:
			"garage": _draw_garage(ci, r)
			"price": _draw_price(ci, r)
			"offers": _draw_offers(ci, r)
		return
	if ls.is_empty():
		PixelFont.draw_centered(ci, r.get_center().x, r.position.y + 80, "NOTHING TODAY. EVEN DARRELL'S QUIET.", ASH)
		return
	match screen:
		"list": _draw_list(ci, r, ls)
		"detail": _draw_detail(ci, r, current())
		"offer": _draw_chat(ci, r, current())

func _status(l: Dictionary) -> Array:
	if bool(l.get("ghosted", false)): return ["GHOSTED", ASH]
	if int(l.deal) > 0: return ["DEAL $%d" % int(l.deal), GREEN]
	return ["$%d" % int(l.ask), GOLD]

func _draw_list(ci: CanvasItem, r: Rect2, ls: Array) -> void:
	var rows := 5
	var top := clampi(sel - 2, 0, maxi(0, ls.size() - rows))
	var y := r.position.y + 56
	for i in range(top, mini(ls.size(), top + rows)):
		var l: Dictionary = ls[i]
		var box := Rect2(r.position.x + 6, y, r.size.x - 12, 38)
		ci.draw_rect(box, Color(1, 1, 1, 0.09) if i == sel else Color(1, 1, 1, 0.03))
		if i == sel: ci.draw_rect(box, BLUE.lightened(0.2), false, 1.0)
		var e := CarCatalog.entry(String(l.car))
		PixelFont.draw(ci, box.position + Vector2(5, 4), String(l.title).substr(0, 36).to_upper(), BONE)
		var st := _status(l)
		PixelFont.draw(ci, box.position + Vector2(5, 14), String(st[0]), st[1])
		PixelFont.draw(ci, box.position + Vector2(70, 14), "%s KM  %s" % [Market._km(int(l.km_claimed)), String(e.get("class", "")).to_upper().replace("_", " ")], ASH)
		PixelFont.draw(ci, box.position + Vector2(5, 24), "%s - %s" % [String(Market.SELLERS[String(l.seller)].name), place_name(l)], ASH)
		y += 40
	_hint(ci, r, Hints.fmt("{updown}: SCROLL  {ui_accept}: OPEN  {leftright}: SELL"), ASH)

func _draw_detail(ci: CanvasItem, r: Rect2, l: Dictionary) -> void:
	var tex := _photo(l)
	var px := r.position.x + (r.size.x - tex.get_width()) / 2.0
	ci.draw_texture(tex, Vector2(px, r.position.y + 36))
	var y := r.position.y + 40 + tex.get_height()
	var e := CarCatalog.entry(String(l.car))
	PixelFont.draw(ci, Vector2(r.position.x + 8, y), "%d %s %s" % [int(l.year), String(e.make).to_upper(), String(e.model).to_upper()], BONE)
	var st := _status(l)
	PixelFont.draw(ci, Vector2(r.end.x - 8 - PixelFont.width(String(st[0])), y), String(st[0]), st[1])
	y += 10
	PixelFont.draw(ci, Vector2(r.position.x + 8, y), "%s KM.  %s  %s" % [Market._km(int(l.km_claimed)), String(e.get("drivetrain", "")), String(Market.SELLERS[String(l.seller)].name)], ASH)
	y += 10
	var known: Array = l.get("known", [])
	var said := "SELLER SAYS: " + (", ".join(known.map(func(f): return String(Market.FAULTS[f].label))) if not known.is_empty() else "NOTHING WRONG WITH IT. OF COURSE.")
	for ln in Hud.wrap_lines(said, 38):
		PixelFont.draw(ci, Vector2(r.position.x + 8, y), ln, GOLD if not known.is_empty() else ASH)
		y += 9
	for ln in Hud.wrap_lines(String(e.get("blurb", "")), 38).slice(0, 3):
		PixelFont.draw(ci, Vector2(r.position.x + 8, y), ln, ASH)
		y += 9
	PixelFont.draw(ci, Vector2(r.position.x + 8, y + 2), "MEET AT: %s" % place_name(l), BONE)
	_hint(ci, r, Hints.fmt("{ui_accept}: MESSAGE  {use}: MEET  {ui_cancel}: BACK"), BONE)

func _draw_chat(ci: CanvasItem, r: Rect2, l: Dictionary) -> void:
	var chat: Array = l.chat
	var y := r.position.y + 40
	for msg in chat.slice(maxi(0, chat.size() - 8)):
		var mine := String(msg[0]) == "you"
		var lines := Hud.wrap_lines(String(msg[1]), 28)
		var w := 0
		for ln in lines: w = maxi(w, PixelFont.width(ln))
		var bx := r.end.x - 12 - w if mine else r.position.x + 10
		ci.draw_rect(Rect2(bx - 3, y - 2, w + 6, lines.size() * 9 + 3), BLUE if mine else Color("2a2830"))
		for ln in lines:
			PixelFont.draw(ci, Vector2(bx, y), ln, BONE)
			y += 9
		y += 5
	var oy := r.end.y - 52
	ci.draw_rect(Rect2(r.position.x + 6, oy - 4, r.size.x - 12, 22), Color(1, 1, 1, 0.06))
	if bool(l.get("ghosted", false)):
		PixelFont.draw_centered(ci, r.get_center().x, oy + 2, "THEY LEFT YOU ON SEEN.", ASH)
	elif int(l.deal) > 0:
		PixelFont.draw_centered(ci, r.get_center().x, oy + 2, "DEAL AT $%d. GO MEET THEM." % int(l.deal), GREEN)
	else:
		PixelFont.draw_centered(ci, r.get_center().x, oy, "YOUR OFFER: $%d  (ASK $%d)" % [amount, int(l.ask)], GOLD, 1)
		PixelFont.draw_centered(ci, r.get_center().x, oy + 9, "%d%% OF ASKING" % int(100.0 * amount / maxf(1.0, float(l.ask))), ASH)
	_hint(ci, r, Hints.fmt("{leftright}: $50  {updown}: $500  {ui_accept}: SEND  {ui_cancel}: BACK"), BONE)

# ------------------------------------------------------------------ SELL

func _car_name(id: String) -> String:
	var e := CarCatalog.entry(id)
	if e.is_empty(): e = SaveGame.load_spec(id)
	return "%s %s" % [String(e.get("make", "")).to_upper(), String(e.get("model", "")).to_upper()]

func _draw_garage(ci: CanvasItem, r: Rect2) -> void:
	var g: Array = save.garage
	var rows := 6
	var top := clampi(gsel - 2, 0, maxi(0, g.size() - rows))
	var y := r.position.y + 56
	for i in range(top, mini(g.size(), top + rows)):
		var entry: Dictionary = g[i]
		var box := Rect2(r.position.x + 6, y, r.size.x - 12, 32)
		ci.draw_rect(box, Color(1, 1, 1, 0.09) if i == gsel else Color(1, 1, 1, 0.03))
		if i == gsel: ci.draw_rect(box, BLUE.lightened(0.2), false, 1.0)
		PixelFont.draw(ci, box.position + Vector2(5, 4), _car_name(String(entry.id)).substr(0, 36), BONE)
		var ad := Market.ad_for(save, i)
		var st := ""
		var col := ASH
		if i == int(save.get("current", 0)): st = "YOU'RE DRIVING IT"
		elif String(entry.id) == "tow": st = "TOBY'S"
		elif not ad.is_empty():
			var deals := (ad.offers as Array).filter(func(o): return String(o.kind) != "msg").size()
			st = "LISTED $%d  -  %d MESSAGE%s, %d OFFER%s" % [int(ad.ask), (ad.offers as Array).size(), "" if (ad.offers as Array).size() == 1 else "S", deals, "" if deals == 1 else "S"]
			col = GREEN if deals > 0 else GOLD
		else: st = "GUS SAYS IT'S WORTH ABOUT $%d" % Market.your_value(entry)
		PixelFont.draw(ci, box.position + Vector2(5, 16), st, col)
		y += 35
	_hint(ci, r, Hints.fmt("{updown}: PICK  {ui_accept}: AD / OFFERS  {leftright}: BUY"), ASH)

func _draw_price(ci: CanvasItem, r: Rect2) -> void:
	var entry: Dictionary = save.garage[gsel]
	var worth := Market.your_value(entry)
	var y := r.position.y + 44
	PixelFont.draw_centered(ci, r.get_center().x, y, "SELL THE " + _car_name(String(entry.id)).substr(0, 28), BONE)
	PixelFont.draw_centered(ci, r.get_center().x, y + 12, "%s KM ON IT" % Market._km(int(entry.get("odo_km", 0.0))), ASH)
	PixelFont.draw_centered(ci, r.get_center().x, y + 34, "ASKING", ASH)
	PixelFont.draw_centered(ci, r.get_center().x, y + 46, "$%d" % amount, GOLD, 3)
	PixelFont.draw_centered(ci, r.get_center().x, y + 80, "GUS SAYS ABOUT $%d" % worth, ASH)
	var ratio := float(amount) / maxf(float(worth), 1.0)
	var mood := "PRICED TO MOVE. EXPECT LOWBALLS ANYWAY." if ratio < 0.95 else ("FAIR. SOMEBODY WILL BITE." if ratio < 1.2 else ("HOPEFUL." if ratio < 1.5 else "DREAMING. ONLY GERALD WILL WRITE."))
	for ln in Hud.wrap_lines(mood, 36):
		PixelFont.draw_centered(ci, r.get_center().x, y + 96, ln, GREEN if ratio < 1.2 else (GOLD if ratio < 1.5 else RED))
		y += 9
	_hint(ci, r, Hints.fmt("{leftright}: $100  {updown}: $1000  {ui_accept}: POST IT  {ui_cancel}: BACK"), BONE)

func _draw_offers(ci: CanvasItem, r: Rect2) -> void:
	var ad := Market.ad_for(save, gsel)
	if ad.is_empty(): return
	var offers: Array = (ad.offers as Array).duplicate()
	offers.reverse()
	var y := r.position.y + 40
	PixelFont.draw(ci, Vector2(r.position.x + 8, y), String(ad.title).substr(0, 36), BONE)
	PixelFont.draw(ci, Vector2(r.position.x + 8, y + 10), "ASKING $%d" % int(ad.ask), GOLD)
	y += 24
	if offers.is_empty():
		PixelFont.draw(ci, Vector2(r.position.x + 8, y + 4), "NOTHING YET. CHECK BACK LATER.", ASH)
		y += 18
	var rows := 5
	var top := clampi(osel - 2, 0, maxi(0, offers.size() + 1 - rows))
	for i in range(top, mini(offers.size() + 1, top + rows)):
		var on := i == osel
		if i == offers.size():
			var box := Rect2(r.position.x + 6, y, r.size.x - 12, 12)
			ci.draw_rect(box, Color(1, 1, 1, 0.09) if on else Color(1, 1, 1, 0.03))
			if on: ci.draw_rect(box, RED, false, 1.0)
			PixelFont.draw(ci, box.position + Vector2(5, 3), "TAKE THE AD DOWN", RED if on else ASH)
			break
		var o: Dictionary = offers[i]
		var lines := Hud.wrap_lines(String(o.text).to_upper(), 36).slice(0, 2)
		var box := Rect2(r.position.x + 6, y, r.size.x - 12, 13 + lines.size() * 8)
		ci.draw_rect(box, Color(1, 1, 1, 0.09) if on else Color(1, 1, 1, 0.03))
		if on: ci.draw_rect(box, BLUE.lightened(0.2), false, 1.0)
		var b: Dictionary = Market.BUYERS[String(o.buyer)]
		PixelFont.draw(ci, box.position + Vector2(5, 3), String(b.name), BONE)
		if String(o.kind) != "msg":
			var amt := "$%d" % int(o.amount)
			PixelFont.draw(ci, box.position + Vector2(box.size.x - 5 - PixelFont.width(amt), 3), amt, GREEN)
		for k in lines.size(): PixelFont.draw(ci, box.position + Vector2(5, 12 + k * 8), lines[k], ASH)
		y += box.size.y + 3
	_hint(ci, r, Hints.fmt("{updown}: PICK  {ui_accept}: TAKE IT  {ui_cancel}: BACK"), BONE)

## The key hints along the bottom, on two lines when they don't fit on one.
func _hint(ci: CanvasItem, r: Rect2, text: String, col: Color) -> void:
	var parts := text.split("  ")
	var lines: Array[String] = [""]
	for part in parts:
		var cur: String = lines[lines.size() - 1]
		var tryit := part if cur == "" else cur + "  " + part
		if PixelFont.width(tryit) > r.size.x - 14 and cur != "": lines.append(part)
		else: lines[lines.size() - 1] = tryit
	var y := r.end.y - 24 - (lines.size() - 1) * 9
	for ln in lines:
		PixelFont.draw_centered(ci, r.get_center().x, y, ln, col)
		y += 9
