## The dashboard, drawn by code: tach, speed, gear, gauges, tires, warnings, controls.
class_name Hud
extends Control

var sim: CarSim
var city: City
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
	# ---- tach
	var c := Vector2(48, 312)
	var R := 38.0
	_panel(Rect2(4, 266, 186, 90))
	var max_rpm := 8000.0
	var a0 := deg_to_rad(135.0)
	var sweep := deg_to_rad(270.0)
	draw_arc(c, R, a0, a0 + sweep, 48, Color(1, 1, 1, 0.15), 3.0)
	var red_a := a0 + sweep * float(spec.engine.redline_rpm) / max_rpm
	draw_arc(c, R, red_a, a0 + sweep, 16, RED, 3.0)
	for k in 9:
		var a := a0 + sweep * k / 8.0
		var p1 := c + Vector2(cos(a), sin(a)) * (R - 6)
		var p2 := c + Vector2(cos(a), sin(a)) * (R - 1)
		draw_line(p1, p2, BONE if k < 7 else RED, 1.0)
		PixelFont.draw_centered(self, (c + Vector2(cos(a), sin(a)) * (R - 12)).x, (c + Vector2(cos(a), sin(a)) * (R - 12)).y - 2, str(k), ASH)
	var ra := a0 + sweep * clampf(sim.rpm / max_rpm, 0.0, 1.06)
	draw_line(c, c + Vector2(cos(ra), sin(ra)) * (R - 3), RED if sim.rpm > float(spec.engine.redline_rpm) else GOLD, 2.0)
	draw_circle(c, 3, BONE)
	var g := "R" if sim.gear < 0 else ("N" if sim.gear == 0 else str(sim.gear))
	PixelFont.draw_centered(self, c.x, c.y + 10, g, BONE, 3)
	PixelFont.draw_centered(self, c.x, c.y + 28, "AUTO" if sim.auto_gearbox else "MANUAL", ASH)
	# ---- speed
	var kmh := int(round(sim.speed() * 3.6))
	PixelFont.draw(self, Vector2(96, 276), "%3d" % kmh, BONE, 4, INK)
	PixelFont.draw(self, Vector2(152, 290), "KM/H", ASH)
	PixelFont.draw(self, Vector2(96, 300), "%5d RPM" % int(sim.rpm), ASH)
	# ---- gauges
	var y := 310.0
	_bar(Vector2(96, y), "BOOST", sim.boost, GOLD, "%.1f BAR" % (sim.boost * 0.7)); y += 9
	_bar(Vector2(96, y), "WATER", clampf((sim.coolant_c - 40.0) / 90.0, 0, 1), RED if sim.coolant_c > 110.0 else BONE, "%d°C" % int(sim.coolant_c)); y += 9
	_bar(Vector2(96, y), "OIL", clampf((sim.oil_c - 20.0) / 120.0, 0, 1), RED if sim.oil_c < 45.0 else BONE, "%d°C" % int(sim.oil_c)); y += 9
	_bar(Vector2(96, y), "ENGINE", sim.engine_health, GREEN.lerp(RED, 1.0 - sim.engine_health), "%d%%" % int(sim.engine_health * 100)); y += 9
	_bar(Vector2(96, y), "BODY", sim.body, GREEN.lerp(RED, 1.0 - sim.body), "%d%%" % int(sim.body * 100))
	# ---- tires
	_panel(Rect2(560, 266, 76, 90))
	PixelFont.draw_centered(self, 598, 270, "TIRES MM", ASH)
	var base := Vector2(586, 282)
	draw_rect(Rect2(base + Vector2(4, 6), Vector2(16, 50)), Color(1, 1, 1, 0.12))
	var spots := [Vector2(-6, 8), Vector2(18, 8), Vector2(-6, 40), Vector2(18, 40)]
	for i in 4:
		var t: Dictionary = sim.tires[i]
		var frac: float = t.tread / float(spec.tires.tread_mm)
		var col := GREEN.lerp(GOLD, clampf(1.0 - frac * 1.6, 0, 1)).lerp(RED, clampf(1.0 - frac * 3.0, 0, 1))
		if t.flat: col = Color("555")
		var p: Vector2 = base + spots[i]
		draw_rect(Rect2(p, Vector2(8, 14)), col)
		var label := "FLAT" if t.flat else "%.1f" % t.tread
		var tx := p.x - 22 if i % 2 == 0 else p.x + 11
		PixelFont.draw(self, Vector2(tx, p.y + 1), label, BONE)
		PixelFont.draw(self, Vector2(tx, p.y + 8), "%d°" % int(t.temp), ASH if t.temp < 120 else RED)
	PixelFont.draw_centered(self, 598, 340, sim.compound.to_upper(), ASH)
	# ---- top left: the car
	_panel(Rect2(4, 4, 196, 30))
	PixelFont.draw(self, Vector2(10, 9), "%s %s '%s" % [spec.make, spec.model, str(int(spec.year)).substr(2)], BONE, 2)
	var assist_name: String = ["SIM", "STREET", "ARCADE"][sim.assist]
	PixelFont.draw(self, Vector2(10, 24), "%s  -  %d KM ON THE ODO" % [assist_name, int(sim.odometer_m / 1000.0) + 214310], ASH)
	# ---- top right: the world
	_panel(Rect2(456, 4, 180, 30))
	var season_label: String = City.SEASONS[city.season].label
	PixelFont.draw(self, Vector2(462, 9), "%s - %s" % [season_label, "NIGHT" if night else "DAY"], BONE, 2)
	PixelFont.draw(self, Vector2(462, 24), "%d°C OUTSIDE  -  ROAD: %s" % [int(city.ambient()), surface.to_upper()], GOLD if surface in ["ice", "snow", "leaves"] else ASH)
	# ---- warnings
	var my := 44.0
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
		_panel(Rect2(206, 266, 348, 90))
		var lines := [
			"DRIVE  W/S OR RT/LT     STEER  A/D OR LEFT STICK",
			"HANDBRAKE  SPACE OR B     SHIFT  E/Q OR RB/LB",
			"GEARBOX AUTO/MANUAL  G OR Y     RESET  R OR BACK",
			"NIGHT  N OR D-UP     SEASON  M OR D-RIGHT",
			"TIRES SUMMER/WINTER  T OR D-DOWN",
			"ASSISTS SIM/STREET/ARCADE  P OR D-LEFT",
			"HIDE THIS  F1 OR START     MENU  ESC",
		]
		for i in lines.size():
			PixelFont.draw(self, Vector2(212, 271 + i * 11), lines[i], BONE if i < 6 else ASH)

func _bar(p: Vector2, label: String, frac: float, col: Color, value: String) -> void:
	PixelFont.draw(self, p, label, ASH)
	draw_rect(Rect2(p.x + 28, p.y, 40, 5), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(p.x + 28, p.y, 40 * clampf(frac, 0, 1), 5), col)
	PixelFont.draw(self, Vector2(p.x + 72, p.y), value, BONE)
