## MarketThing on Leo's phone: today's listings, a listing with its bad phone photo, and the
## chat where you haggle. MEET sends the GPS to the seller; the meetup itself is MarketRunner's.
class_name MarketApp
extends RefCounted

signal meet(listing: Dictionary)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const RED := Color("e0402e")
const BLUE := Color("4a7ab8")

var save: Dictionary
var places: Array = []           # [{ name, p }]
var screen := "list"             # list, detail, offer
var sel := 0
var amount := 0
var _photos := {}
var _rng := RandomNumberGenerator.new()

func setup(the_save: Dictionary, the_places: Array, day: int) -> void:
	save = the_save
	places = the_places
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

## Input while the app is open. Returns false when the app wants the phone to close.
func handle() -> bool:
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

## Does the phone's own back button belong to us right now?
func wants_back() -> bool:
	return screen != "list"

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
	var rows := 6
	var top := clampi(sel - 2, 0, maxi(0, ls.size() - rows))
	var y := r.position.y + 40
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
	PixelFont.draw_centered(ci, r.get_center().x, r.end.y - 24, Hints.fmt("{updown}: SCROLL  {ui_accept}: OPEN"), ASH)

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
	PixelFont.draw_centered(ci, r.get_center().x, r.end.y - 24, Hints.fmt("{ui_accept}: MESSAGE  {use}: MEET  {ui_cancel}: BACK"), BONE)

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
	PixelFont.draw_centered(ci, r.get_center().x, r.end.y - 24, Hints.fmt("{leftright}: $50  {updown}: $500  {ui_accept}: SEND  {ui_cancel}: BACK"), BONE)
