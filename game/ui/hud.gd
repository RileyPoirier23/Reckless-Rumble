## The dashboard, drawn by code: tach, speed, gear, gauges, tires, warnings, controls.
class_name Hud
extends Control

var sim: CarSim
var sky: WorldSky
var player: PlayerCar
var objective := ""
var place := ""
var night := false
var show_help := true
var surface := "dry"
var msgs: Array = []          # [text, time left]

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const RED := Color("e0402e")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")

func post(text: String, secs := 4.0) -> void:
	for m in msgs:
		if m[0] == text:
			m[1] = secs
			return
	msgs.append([text, secs])
	if msgs.size() > 4: msgs.pop_front()

func _process(dt: float) -> void:
	for m in msgs: m[1] -= dt
	msgs = msgs.filter(func(m): return m[1] > 0.0)
	queue_redraw()

func _panel(r: Rect2) -> void:
	draw_rect(r, Color(0.04, 0.035, 0.05, 0.78))
	draw_rect(r, Color(1, 1, 1, 0.08), false, 1.0)

func _draw() -> void:
	if sim == null: return
	var spec := sim.spec
	# ---- tires
	var tx0 := 222.0
	_panel(Rect2(tx0, 296, 76, 60))
	PixelFont.draw_centered(self, tx0 + 38, 299, "TIRES MM", ASH)
	var base := Vector2(tx0 + 26, 306)
	draw_rect(Rect2(base + Vector2(4, 2), Vector2(16, 44)), Color(1, 1, 1, 0.12))
	var spots := [Vector2(-6, 4), Vector2(18, 4), Vector2(-6, 32), Vector2(18, 32)]
	for i in 4:
		var t: Dictionary = sim.tires[i]
		var frac: float = t.tread / float(spec.tires.tread_mm)
		var col := GREEN.lerp(GOLD, clampf(1.0 - frac * 1.6, 0, 1)).lerp(RED, clampf(1.0 - frac * 3.0, 0, 1))
		if t.flat: col = Color("555")
		var p: Vector2 = base + spots[i]
		draw_rect(Rect2(p, Vector2(8, 12)), col)
		var label := "FLAT" if t.flat else "%.1f" % t.tread
		var tx := p.x - 22 if i % 2 == 0 else p.x + 11
		PixelFont.draw(self, Vector2(tx, p.y + 1), label, BONE)
		PixelFont.draw(self, Vector2(tx, p.y + 8), "%d°" % int(t.temp), ASH if t.temp < 120 else RED)
	PixelFont.draw_centered(self, tx0 + 38, 349, sim.compound.to_upper(), ASH)
	# ---- top left: the car
	_panel(Rect2(4, 4, 214, 30))
	var title := "%s %s '%s" % [spec.make, spec.model, str(int(spec.year)).substr(2)]
	PixelFont.draw(self, Vector2(10, 9 if title.length() <= 25 else 11), title, BONE, 2 if title.length() <= 25 else 1)
	var assist_name: String = ["SIM", "STREET", "ARCADE"][sim.assist]
	PixelFont.draw(self, Vector2(10, 24), "%s  -  %s" % [assist_name, "AUTO" if sim.auto_gearbox else "MANUAL"], ASH)
	# ---- top right: the world
	_panel(Rect2(436, 4, 200, 40))
	var season_label: String = sky.season.to_upper()
	PixelFont.draw(self, Vector2(442, 9), "%s  %s" % [sky.clock_str(), season_label], BONE, 2)
	PixelFont.draw(self, Vector2(442, 24), "%s  %d°C" % [sky.label(), int(sky.temperature())], GOLD if sky.weather in ["storm", "blizzard", "freezing", "fog"] else BONE)
	PixelFont.draw(self, Vector2(442, 33), "%s - ROAD: %s" % [place, surface.to_upper()], GOLD if surface in ["ice", "snow", "leaves", "mud", "water"] else ASH)
	# ---- the story objective
	if objective != "":
		var ls := wrap_lines(objective, 50)
		var h := 10 + ls.size() * 8
		_panel(Rect2(222, 38, 210, h))
		for k in ls.size(): PixelFont.draw(self, Vector2(228, 43 + k * 8), ls[k], GOLD)
	# ---- the tell-tales: blinkers and high beams
	if player:
		var on := CarView.blink_on()
		var green := Color("4aff6a")
		if player.view.blink_left and on:
			draw_colored_polygon(PackedVector2Array([Vector2(296, 30), Vector2(306, 23), Vector2(306, 37)]), green)
		if player.view.blink_right and on:
			draw_colored_polygon(PackedVector2Array([Vector2(344, 30), Vector2(334, 23), Vector2(334, 37)]), green)
		if player.beam > 0.5 and player.view.headlights:
			draw_circle(Vector2(320, 30), 6, Color("3a7aff"))
			for k in 4: draw_line(Vector2(312, 25 + k * 3), Vector2(306, 25 + k * 3), Color("3a7aff"), 1.0)
	# ---- warnings
	var my := 44.0 if objective == "" else 56.0 + wrap_lines(objective, 50).size() * 8.0
	for m in msgs:
		var a: float = clampf(m[1], 0.0, 1.0)
		var w := PixelFont.width(m[0], 2) + 16
		draw_rect(Rect2(320 - w / 2.0, my, w, 16), Color(0.5, 0.06, 0.04, 0.85 * a))
		PixelFont.draw_centered(self, 320, my + 4, m[0], Color(1, 1, 1, a), 2)
		my += 20
	if sim.engine_blown:
		PixelFont.draw_centered(self, 320, 128, "ENGINE BLOWN. R TO TOW IT HOME.", RED, 2, INK)
	# ---- controls
	if show_help:
		_panel(Rect2(196, 150, 248, 72))
		var lines := [
			Hints.fmt("DRIVE {drive}  STEER {steer}  HANDBRAKE {handbrake}"),
			Hints.fmt("SHIFT {shift}  AUTO/MANUAL {gearbox}  TOW HOME {reset}"),
			Hints.fmt("BLINKERS {blinkers}  HAZARDS {hazards}"),
			Hints.fmt("HIGH BEAMS {high_beams} (HOLD TO FLASH)  HORN {horn}"),
			Hints.fmt("MAP {map}  USE (GARAGE) {use}"),
			Hints.fmt("HIDE THIS {help}  MENU {menu_back}"),
		]
		for i in lines.size():
			PixelFont.draw(self, Vector2(202, 155 + i * 11), lines[i], BONE if i < 5 else ASH)

func _bar(p: Vector2, label: String, frac: float, col: Color, value: String) -> void:
	PixelFont.draw(self, p, label, ASH)
	draw_rect(Rect2(p.x + 28, p.y, 40, 5), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(p.x + 28, p.y, 40 * clampf(frac, 0, 1), 5), col)
	PixelFont.draw(self, Vector2(p.x + 72, p.y), value, BONE)

static func wrap_lines(text: String, n: int) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" "):
		if cur == "": cur = word
		elif cur.length() + 1 + word.length() <= n: cur += " " + word
		else:
			out.append(cur)
			cur = word
	if cur != "": out.append(cur)
	return out
