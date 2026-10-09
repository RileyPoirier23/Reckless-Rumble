## Leo's phone: GIGS (what's on tonight, what it pays, whether it's open) and MARKETTHING (the
## used-car market). Shoulder buttons switch apps. Pick a gig and JobRunner takes it from there;
## pick the one you're on to walk away from it. MEET on a listing hands it to MarketRunner.
class_name JobBoard
extends Control

signal picked(kind: String)
signal quit_job
signal meet(listing: Dictionary)
signal sold(index: int, text: String)

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const RED := Color("e0402e")
const APPS := ["GIGS", "MARKETTHING"]

var sky: WorldSky
var save: Dictionary
var current := ""               # the job you're on ("" for none)
var sel := 0
var app := 0
var market := MarketApp.new()

func _ready() -> void:
	market.meet.connect(func(l: Dictionary): meet.emit(l))
	market.sold.connect(func(i: int, t: String): sold.emit(i, t))

func open(the_sky: WorldSky, the_save: Dictionary, job: String, places: Array) -> void:
	sky = the_sky
	save = the_save
	current = job
	visible = true
	sel = maxi(0, Jobs.ORDER.find(job))
	market.setup(save, places, sky.day, sky.time_h)

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	if Input.is_action_just_pressed("shift_up") or Input.is_action_just_pressed("shift_down"):
		app = (app + 1) % APPS.size()
		return
	if Input.is_action_just_pressed("jobs"):
		visible = false
		return
	if app == 1:
		if Input.is_action_just_pressed("ui_cancel") and not market.wants_back():
			visible = false
			return
		if not market.handle(): visible = false
		return
	var n := Jobs.ORDER.size()
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % n
	if Input.is_action_just_pressed("ui_up"): sel = (sel + n - 1) % n
	if Input.is_action_just_pressed("ui_cancel"):
		visible = false
		return
	if Input.is_action_just_pressed("ui_accept"):
		var k: String = Jobs.ORDER[sel]
		if k == current:
			visible = false
			quit_job.emit()
		elif Jobs.open_now(k, sky.time_h):
			visible = false
			picked.emit(k)

func _draw() -> void:
	if sky == null: return
	# the phone
	var r := Rect2(200, 22, 240, 316)
	draw_rect(r.grow(4), Color("1a1820"))
	draw_rect(r, Color(0.05, 0.05, 0.07))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 18)), Color("14121a"))
	PixelFont.draw(self, r.position + Vector2(6, 5), "%s %s" % [Jobs.weekday(sky.day).substr(0, 3), sky.clock_str()], BONE)
	PixelFont.draw(self, r.position + Vector2(r.size.x - 6 - PixelFont.width("$%d" % int(save.get("cash", 0))), 5), "$%d" % int(save.get("cash", 0)), GOLD)
	# app dock along the bottom
	for i in APPS.size():
		var bx := r.position.x + 6 + i * (r.size.x - 12) / 2.0
		var on := i == app
		draw_rect(Rect2(bx, r.end.y - 14, (r.size.x - 12) / 2.0 - 2, 11), Color(1, 1, 1, 0.12) if on else Color(1, 1, 1, 0.03))
		PixelFont.draw_centered(self, bx + (r.size.x - 12) / 4.0, r.end.y - 12, APPS[i], GOLD if on else ASH)
	if app == 1:
		market.draw_app(self, Rect2(r.position, r.size - Vector2(0, 8)))
		return
	PixelFont.draw_centered(self, r.get_center().x, r.position.y + 24, "GIGS", GOLD, 2)
	var y := r.position.y + 42
	for i in Jobs.ORDER.size():
		var k: String = Jobs.ORDER[i]
		var job: Dictionary = Jobs.KINDS[k]
		var open := Jobs.open_now(k, sky.time_h)
		var h := 48.0
		var box := Rect2(r.position.x + 6, y, r.size.x - 12, h - 4)
		draw_rect(box, Color(1, 1, 1, 0.09) if i == sel else Color(1, 1, 1, 0.03))
		if i == sel: draw_rect(box, GOLD, false, 1.0)
		PixelFont.draw(self, box.position + Vector2(5, 4), String(job.title), BONE if open else ASH)
		var status := "ON IT" if k == current else ("OPEN" if open else "OPENS %s" % Jobs.opens_at(k))
		var scol := GOLD if k == current else (GREEN if open else ASH)
		PixelFont.draw(self, box.position + Vector2(box.size.x - 5 - PixelFont.width(status), 4), status, scol)
		PixelFont.draw(self, box.position + Vector2(5, 14), String(job.pay), GOLD if open else ASH)
		var lines := Hud.wrap_lines(String(job.blurb), 38)
		for li in mini(lines.size(), 2): PixelFont.draw(self, box.position + Vector2(5, 24 + li * 8), lines[li], ASH)
		y += h
	var hint := "{updown}: PICK  {ui_accept}: %s  {shift}: APPS" % ("QUIT THIS JOB" if Jobs.ORDER[sel] == current else "TAKE IT")
	PixelFont.draw_centered(self, r.get_center().x, r.end.y - 26, Hints.fmt(hint), BONE)
