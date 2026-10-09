## The job board on Leo's phone: what's on tonight, what it pays, and whether it's open yet.
## Pick one and JobRunner takes it from there; pick the one you're on to walk away from it.
class_name JobBoard
extends Control

signal picked(kind: String)
signal quit_job

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const RED := Color("e0402e")

var sky: WorldSky
var save: Dictionary
var current := ""               # the job you're on ("" for none)
var sel := 0

func open(the_sky: WorldSky, the_save: Dictionary, job: String) -> void:
	sky = the_sky
	save = the_save
	current = job
	visible = true
	sel = maxi(0, Jobs.ORDER.find(job))

func _process(_dt: float) -> void:
	if not visible: return
	queue_redraw()
	var n := Jobs.ORDER.size()
	if Input.is_action_just_pressed("ui_down"): sel = (sel + 1) % n
	if Input.is_action_just_pressed("ui_up"): sel = (sel + n - 1) % n
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("jobs"):
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
	var r := Rect2(200, 30, 240, 300)
	draw_rect(r.grow(4), Color("1a1820"))
	draw_rect(r, Color(0.05, 0.05, 0.07))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 18)), Color("14121a"))
	PixelFont.draw(self, r.position + Vector2(6, 5), "%s %s" % [Jobs.weekday(sky.day).substr(0, 3), sky.clock_str()], BONE)
	PixelFont.draw(self, r.position + Vector2(r.size.x - 6 - PixelFont.width("$%d" % int(save.get("cash", 0))), 5), "$%d" % int(save.get("cash", 0)), GOLD)
	PixelFont.draw_centered(self, r.get_center().x, r.position.y + 26, "GIGS", GOLD, 2)
	var y := r.position.y + 46
	for i in Jobs.ORDER.size():
		var k: String = Jobs.ORDER[i]
		var job: Dictionary = Jobs.KINDS[k]
		var open := Jobs.open_now(k, sky.time_h)
		var h := 58.0
		var box := Rect2(r.position.x + 6, y, r.size.x - 12, h - 4)
		draw_rect(box, Color(1, 1, 1, 0.09) if i == sel else Color(1, 1, 1, 0.03))
		if i == sel: draw_rect(box, GOLD, false, 1.0)
		PixelFont.draw(self, box.position + Vector2(5, 4), String(job.title), BONE if open else ASH)
		var status := "ON IT" if k == current else ("OPEN" if open else "OPENS %s" % Jobs.opens_at(k))
		var scol := GOLD if k == current else (GREEN if open else ASH)
		PixelFont.draw(self, box.position + Vector2(box.size.x - 5 - PixelFont.width(status), 4), status, scol)
		PixelFont.draw(self, box.position + Vector2(5, 14), String(job.pay), GOLD if open else ASH)
		var lines := Hud.wrap_lines(String(job.blurb), 38)
		for li in mini(lines.size(), 3): PixelFont.draw(self, box.position + Vector2(5, 24 + li * 8), lines[li], ASH)
		y += h
	var hint := "{updown}: PICK  {ui_accept}: %s  {ui_cancel}: CLOSE" % ("QUIT THIS JOB" if Jobs.ORDER[sel] == current else "TAKE IT")
	PixelFont.draw_centered(self, r.get_center().x, r.end.y - 12, Hints.fmt(hint), BONE)
