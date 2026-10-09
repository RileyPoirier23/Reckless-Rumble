## The instrument cluster, in the car's own style. Every car gets the dash it came with:
## - analog90:  white-on-black needles, orange backlight at night (Silvio, 1991)
## - digital80: a glowing VFD bar-graph dash, the 1986 idea of the future (Supreem)
## - tft:       a modern screen with rings and a big digital speed (Charjer, 2015)
## - truck:     big chrome-ringed gauges, oil pressure, volts, the tow lights (the wrecker)
class_name DashView
extends Control

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const ASH := Color("8a8478")
const RED := Color("e0402e")
const GOLD := Color("d9a441")

var sim: CarSim
var style := "analog90"
var lit := false          # backlight on (headlights on)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if sim == null: return
	match style:
		"digital80": _digital80()
		"tft": _tft()
		"truck": _truck()
		_: _analog90()

func _kmh() -> float: return sim.speed() * 3.6
func _gear() -> String: return "R" if sim.gear < 0 else ("N" if sim.gear == 0 else str(sim.gear))
func _redline() -> float: return float(sim.spec.engine.redline_rpm)
func _fuel() -> float: return sim.fuel_frac()

## A needle gauge: centre, radius, value 0..1, ticks, labels.
func _gauge(c: Vector2, r: float, frac: float, face: Color, ink: Color, needle: Color, ticks: int, labels: Array, red_from := 2.0, sweep_deg := 260.0) -> void:
	draw_circle(c, r + 2, Color("0e0c10"))
	draw_circle(c, r, face)
	var a0 := deg_to_rad(90.0 + (360.0 - sweep_deg) / 2.0)
	var sweep := deg_to_rad(sweep_deg)
	if red_from <= 1.0: draw_arc(c, r - 3, a0 + sweep * red_from, a0 + sweep, 12, RED, 3.0)
	for k in ticks + 1:
		var a := a0 + sweep * float(k) / ticks
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (r - 6), c + d * (r - 1), ink, 1.0)
		if k < labels.size() and str(labels[k]) != "":
			var lp := c + d * (r - 11)
			PixelFont.draw_centered(self, lp.x, lp.y - 2, str(labels[k]), ink)
	var na := a0 + sweep * clampf(frac, 0.0, 1.05)
	draw_line(c, c + Vector2(cos(na), sin(na)) * (r - 3), needle, 2.0)
	draw_circle(c, 2.5, Color("2a2a2e"))

func _seg7(p: Vector2, ch: String, h: float, on: Color, off: Color) -> void:
	# a seven-segment digit, h tall
	const SEG := { "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc",
		"8": "abcdefg", "9": "abcdfg", "-": "g", " ": "", "R": "eg", "N": "ceg", "P": "abefg" }
	var w := h * 0.55
	var t := maxf(1.0, h * 0.13)
	var segs: String = SEG.get(ch, "")
	var rects := { "a": Rect2(p.x + t, p.y, w - 2 * t, t), "b": Rect2(p.x + w - t, p.y + t, t, h / 2 - t * 1.5), "c": Rect2(p.x + w - t, p.y + h / 2 + t * 0.5, t, h / 2 - t * 1.5),
		"d": Rect2(p.x + t, p.y + h - t, w - 2 * t, t), "e": Rect2(p.x, p.y + h / 2 + t * 0.5, t, h / 2 - t * 1.5), "f": Rect2(p.x, p.y + t, t, h / 2 - t * 1.5), "g": Rect2(p.x + t, p.y + h / 2 - t / 2, w - 2 * t, t) }
	for k in rects: draw_rect(rects[k], on if segs.contains(k) else off)

func _bars(p: Vector2, n: int, frac: float, w: float, h: float, gap: float, cols: Array, off: Color, vertical := false) -> void:
	for i in n:
		var f := float(i) / n
		var col: Color = cols[0] if f < 0.7 else (cols[1] if f < 0.85 else cols[2])
		var on := f < frac
		var r := Rect2(p + Vector2(i * (w + gap), 0), Vector2(w, h)) if not vertical else Rect2(p + Vector2(0, -(i + 1) * (h + gap)), Vector2(w, h))
		draw_rect(r, col if on else off)

# ------------------------------------------------------------------ styles

func _analog90() -> void:
	draw_rect(Rect2(4, 262, 214, 94), Color("141216"))
	draw_rect(Rect2(4, 262, 214, 94), Color("2a2830"), false, 2.0)
	var face := Color("101012")
	var ink := Color("f2a040") if lit else Color("e8e8e0")
	var needle := Color("ff6a1a")
	var max_rpm := 8000.0
	_gauge(Vector2(48, 306), 38, sim.rpm / max_rpm, face, ink, needle, 8, ["0", "1", "2", "3", "4", "5", "6", "7", "8"], _redline() / max_rpm)
	_gauge(Vector2(174, 306), 38, _kmh() / 240.0, face, ink, needle, 12, ["0", "", "40", "", "80", "", "120", "", "160", "", "200", "", "240"])
	PixelFont.draw_centered(self, 48, 320, "X1000 RPM", Color(ink, 0.7))
	PixelFont.draw_centered(self, 174, 320, "KM/H", Color(ink, 0.7))
	# the boost gauge and the middle stack
	_gauge(Vector2(111, 282), 15, sim.boost, face, ink, needle, 4, [], 2.0, 200.0)
	PixelFont.draw_centered(self, 111, 290, "BOOST", Color(ink, 0.6))
	draw_rect(Rect2(97, 300, 28, 18), Color("08080a"))
	PixelFont.draw_centered(self, 111, 303, _gear(), Color("ff8a2a") if lit else BONE, 2)
	_mini_bar(Vector2(90, 324), "H", "C", clampf((sim.coolant_c - 40.0) / 90.0, 0, 1), ink)
	_mini_bar(Vector2(90, 333), "F", "E", _fuel(), ink)
	draw_rect(Rect2(93, 343, 38, 9), Color("08080a"))
	PixelFont.draw(self, Vector2(95, 345), "%06d" % (int(sim.odometer_m / 1000.0) + 214310), Color("e8e8e0"))

func _mini_bar(p: Vector2, hi: String, lo: String, frac: float, ink: Color) -> void:
	PixelFont.draw(self, p, lo, Color(ink, 0.7))
	draw_rect(Rect2(p.x + 6, p.y + 1, 30, 3), Color("2a2a2e"))
	draw_rect(Rect2(p.x + 6, p.y + 1, 30 * frac, 3), ink)
	PixelFont.draw(self, p + Vector2(38, 0), hi, Color(ink, 0.7))

func _digital80() -> void:
	var on := Color("40f0c0")
	var amber := Color("ffb030")
	var off := Color(0.05, 0.09, 0.08)
	if not lit:
		on = on.darkened(0.15)
	draw_rect(Rect2(4, 262, 214, 94), Color("0a0c0c"))
	draw_rect(Rect2(4, 262, 214, 94), Color("3a3430"), false, 3.0)
	draw_rect(Rect2(10, 268, 202, 82), Color("060808"))
	# the bar-graph tach across the top, green to amber to red
	PixelFont.draw(self, Vector2(14, 271), "RPM X1000", Color(on, 0.7))
	var max_rpm := 7000.0
	_bars(Vector2(14, 279), 35, sim.rpm / max_rpm, 4, 7, 1.5, [on, amber, RED], off)
	for k in 8: PixelFont.draw(self, Vector2(13 + k * 27.5, 289), str(k), Color(on, 0.6))
	# big digital speed
	var kmh := "%3d" % int(_kmh())
	for i in 3: _seg7(Vector2(54 + i * 21, 298), kmh[i], 34, on, off)
	PixelFont.draw(self, Vector2(120, 324), "KM/H", on)
	# gear, and the little vertical bar stacks
	draw_rect(Rect2(16, 300, 26, 34), Color("0c1210"))
	_seg7(Vector2(21, 304), _gear(), 24, amber, off)
	_bars(Vector2(158, 338), 8, clampf((sim.coolant_c - 40.0) / 90.0, 0, 1), 10, 3, 1, [on, amber, RED], off, true)
	_bars(Vector2(176, 338), 8, _fuel(), 10, 3, 1, [on, on, on], off, true)
	_bars(Vector2(194, 338), 8, clampf((sim.oil_c - 20.0) / 120.0, 0, 1), 10, 3, 1, [on, amber, RED], off, true)
	PixelFont.draw(self, Vector2(157, 341), "TMP", Color(on, 0.7))
	PixelFont.draw(self, Vector2(175, 341), "GAS", Color(on, 0.7))
	PixelFont.draw(self, Vector2(193, 341), "OIL", Color(on, 0.7))
	if sim.coolant_c > 110.0: PixelFont.draw(self, Vector2(16, 340), "ENGINE HOT", RED)

func _tft() -> void:
	var accent := Color("e0202a")
	draw_rect(Rect2(4, 262, 214, 94), Color("08080a"))
	draw_rect(Rect2(4, 262, 214, 94), Color("1e1e24"), false, 2.0)
	var glow := 1.0 if lit else 0.8
	# rings: rpm left, speed right
	for side in 2:
		var c := Vector2(46 if side == 0 else 176, 308)
		var frac := sim.rpm / 7000.0 if side == 0 else _kmh() / 260.0
		var a0 := deg_to_rad(140.0)
		var sweep := deg_to_rad(260.0)
		draw_arc(c, 36, a0, a0 + sweep, 40, Color("2a2a30"), 4.0)
		draw_arc(c, 36, a0, a0 + sweep * clampf(frac, 0.0, 1.0), 40, accent * glow, 4.0)
		draw_arc(c, 31, a0, a0 + sweep, 40, Color("1a1a1e"), 1.0)
		var big := "%d" % int(sim.rpm / 100.0 * 100.0) if side == 0 else "%d" % int(_kmh())
		PixelFont.draw_centered(self, c.x, c.y - 6, big if side == 1 else "%.1f" % (sim.rpm / 1000.0), BONE, 2 if side == 1 else 2)
		PixelFont.draw_centered(self, c.x, c.y + 10, "KM/H" if side == 1 else "X1000 RPM", ASH)
	# the middle screen: gear, mode, temps, a little car with its tires
	draw_rect(Rect2(88, 270, 46, 80), Color("101014"))
	PixelFont.draw_centered(self, 111, 274, ("D" if sim.auto_gearbox else "M") + _gear(), accent, 3)
	PixelFont.draw_centered(self, 111, 296, ["SIM", "STREET", "ARCADE"][sim.assist], ASH)
	draw_rect(Rect2(104, 306, 14, 26), Color("3a3a42"))
	for i in 4:
		var t: Dictionary = sim.tires[i]
		var p := Vector2(100 if i % 2 == 0 else 119, 308 if i < 2 else 324)
		draw_rect(Rect2(p, Vector2(3, 6)), Color("6fbf5a") if t.tread > 3.0 else (GOLD if t.tread > 1.6 else RED))
	PixelFont.draw_centered(self, 111, 338, "%d°C" % int(sim.coolant_c), BONE if sim.coolant_c < 110 else RED)

func _truck() -> void:
	draw_rect(Rect2(4, 262, 214, 94), Color("1a1814"))
	draw_rect(Rect2(4, 262, 214, 94), Color("3a3630"), false, 2.0)
	var face := Color("0c0c0e")
	var ink := Color("9aff9a") if lit else Color("ecece4")
	var needle := Color("ff3a1a")
	var chrome := Color("c8ccd0")
	# the big speedo in the middle, with a chrome ring
	draw_circle(Vector2(111, 308), 44, chrome)
	_gauge(Vector2(111, 308), 41, _kmh() / 160.0, face, ink, needle, 8, ["0", "20", "40", "60", "80", "100", "120", "140", "160"])
	PixelFont.draw_centered(self, 111, 322, "KM/H", Color(ink, 0.7))
	# the odometer drum
	draw_rect(Rect2(93, 330, 36, 9), Color("e8e4dc"))
	PixelFont.draw(self, Vector2(95, 332), "%06d" % (int(sim.odometer_m / 1000.0) + 388120), INK)
	# four small gauges: tach, oil pressure, volts, temp; plus fuel
	var small := [[Vector2(36, 286), sim.rpm / 6000.0, "RPM"], [Vector2(36, 332), clampf(0.3 + sim.rpm / 9000.0, 0, 1) * (0.0 if sim.engine_blown else 1.0), "OIL"],
		[Vector2(186, 286), 0.55 + sin(Time.get_ticks_msec() / 4000.0) * 0.02, "VOLTS"], [Vector2(186, 332), clampf((sim.coolant_c - 40.0) / 90.0, 0, 1), "TEMP"]]
	for g in small:
		draw_circle(g[0], 21, chrome.darkened(0.2))
		_gauge(g[0], 19, g[1], face, ink, needle, 4, [], 2.0, 180.0)
		PixelFont.draw_centered(self, g[0].x, g[0].y + 6, g[2], Color(ink, 0.7))
	draw_rect(Rect2(64, 268, 22, 9), Color("08080a"))
	PixelFont.draw_centered(self, 75, 270, _gear(), ink)
	# the tow lights switch (it's always on; Toby never turns it off)
	draw_rect(Rect2(140, 268, 30, 9), Color("ffa020") if int(Time.get_ticks_msec() / 400) % 2 == 0 else Color("5a3a10"))
	PixelFont.draw_centered(self, 155, 270, "TOW", INK)
