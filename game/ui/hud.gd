## The driving HUD, drawn by code. Everything sits where HudLayout says, and nothing is drawn over
## the road ahead of the car:
## - the car bar (top left) and the clock bar (top right);
## - the info column (top middle): the objective, one subtitle at a time (who's talking, or a
##   notice), and the prompt for what you can do right here ([F] THE GARAGE);
## - the scan tool (above the dash): the car's fault codes, the tires and the warning lights, where
##   the car's own complaints go instead of across the windshield;
## - the controls card, only when you ask for it (F1 / START).
class_name Hud
extends Control

var sim: CarSim
var sky: WorldSky
var player: PlayerCar
var objective := ""
var place := ""
var night := false
var show_help := false
var show_diag := true          # Settings > UI: the scan tool under the dash
var surface := "dry"
var stepped_aside := false     # a menu or a panel is up: the HUD steps aside
var diag_style := "analog90"   # the scan tool matches the dash
var msgs: Array = []           # the subtitle queue: { who, text, kind, prio, t }; msgs[0] is showing
var clock := 0.0               # seconds since the HUD started
var verbosity := 2             # chatter: 0 off, 1 low, 2 full (the settings screen sets it)

var _prompt := ""
var _prompt_t := 0.0
var _seen := {}                # text -> when it was last shown (so the same line doesn't nag)
var _idle_since := 0.0         # when the subtitle lane last went quiet
var _last_chatter := -100.0
var _event := ""               # the scan tool's last event line
var _event_t := 0.0
var _timed := {}               # code -> [text, sev, time left]: events that set a code for a bit
var _codes_shown := {}
var _flash_t := 0.0

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const RED := Color("e0402e")
const ASH := Color("8a8478")
const GREEN := Color("6fbf5a")
const BLUE := Color("6aa8ff")

const QUEUE_MAX := 5
const REPEAT_S := 25.0         # the same line won't come back for this long (unless it matters)
const CHATTER_GAP := 15.0      # flavour talk: at most one line this often...
const CHATTER_IDLE := 4.0      # ...and only once the lane has been quiet this long

# ------------------------------------------------------------------ what other code calls

## Somebody says something: GUS, LLOYD, a passenger. One line at a time, at the top.
func say(who: String, text: String, prio := 1, secs := -1.0) -> void:
	_queue({ "who": who.strip_edges(), "text": text.strip_edges(), "kind": "say", "prio": prio, "t": secs })

## A notice: money, a job starting or ending, the police. kind: status, award, police, tip, warn.
func notify(text: String, kind := "status", prio := 1, secs := -1.0) -> void:
	_queue({ "who": "", "text": text.strip_edges(), "kind": kind, "prio": prio, "t": secs })

## Flavour talk (the crowd at the meet, a chatty passenger): only when the lane's been quiet a
## while, and not too often. Returns whether it went up.
func chatter(who: String, text: String) -> bool:
	if not chatter_ready(): return false
	_last_chatter = clock
	say(who, text, 0)
	return true

## Whether a line of flavour talk would go up right now.
func chatter_ready() -> bool:
	if verbosity <= 0: return false
	var gap := CHATTER_GAP * (2.0 if verbosity == 1 else 1.0)
	return msgs.is_empty() and clock - _idle_since >= CHATTER_IDLE and clock - _last_chatter >= gap

## What you can do right here ("{use}: THE GARAGE"): set it every frame you want it shown.
func prompt(text: String) -> void:
	_prompt = text
	_prompt_t = 0.12

## The old way in, kept so every caller works: a short post is a prompt, "WHO: \"...\"" is
## somebody talking, anything else is a notice.
func post(text: String, secs := 4.0) -> void:
	if secs <= 0.25:
		prompt(text)
		return
	var who := ""
	var body := text
	var k := text.find(": \"")
	if k > 0 and k <= 32 and text.substr(0, k) == text.substr(0, k).to_upper() and not text.substr(0, k).contains("."):
		who = text.substr(0, k)
		body = text.substr(k + 2)
		if body.begins_with("\"") and body.count("\"") == 2 and body.ends_with("\""): body = body.substr(1, body.length() - 2)
	if who != "": say(who, body, 1, secs)
	else: notify(text, "status", 1, secs)

## Something the car reported (CarSim.say): it goes on the scan tool, never across the screen.
func diag_event(text: String) -> void:
	var t := text.to_upper()
	# the ones that come every frame while they're true: the scan tool reads those off the car itself
	if t.begins_with("COLD ENGINE") or t.begins_with("OVERHEATING"): return
	if t.begins_with("KNOCK"): _timed["P0325"] = ["KNOCK - BACK OFF THE TUNE", 1, 4.0]
	if t.begins_with("MONEY SHIFT"): t = "SHIFT BLOCKED: TOO MANY RPM"
	_event = t.substr(0, 50)
	_event_t = 4.0
	# no scan tool (Settings > UI): what it would have shown comes up as a note instead
	if not show_diag: notify(_event, "status", 1, 3.0)

# ------------------------------------------------------------------ the queue

func _queue(e: Dictionary) -> void:
	var text := String(e.text)
	if text == "": return
	for m in msgs:
		if String(m.text) == text and String(m.who) == String(e.who):
			if float(e.t) > 0.0: m.t = maxf(float(m.t), float(e.t))
			return
	if int(e.prio) <= 1 and _seen.has(text) and clock - float(_seen[text]) < REPEAT_S: return
	var dur := clampf(2.4 + 0.045 * (text.length() + String(e.who).length()), 2.5, 7.0)
	if float(e.t) > 0.0: dur = clampf(float(e.t), 2.0, 7.0)
	e.t = dur
	e.dur = dur
	# a line that matters cuts in ahead of chatter
	if not msgs.is_empty() and int(e.prio) > int(msgs[0].prio):
		msgs.insert(0, e)
		_shown(e)
	else:
		msgs.append(e)
		if msgs.size() == 1: _shown(e)
	while msgs.size() > QUEUE_MAX:
		var drop := 1
		for i in range(1, msgs.size()):
			if int(msgs[i].prio) < int(msgs[drop].prio): drop = i
		msgs.remove_at(drop)

func _shown(e: Dictionary) -> void:
	_seen[String(e.text)] = clock

func _process(dt: float) -> void:
	clock += dt
	if not msgs.is_empty():
		msgs[0].t = float(msgs[0].t) - dt
		if float(msgs[0].t) <= 0.0:
			msgs.pop_front()
			if msgs.is_empty(): _idle_since = clock
			else: _shown(msgs[0])
	_prompt_t -= dt
	if _prompt_t <= 0.0: _prompt = ""
	_event_t -= dt
	_flash_t -= dt
	for k in _timed.keys():
		_timed[k][2] = float(_timed[k][2]) - dt
		if float(_timed[k][2]) <= 0.0: _timed.erase(k)
	queue_redraw()

## The lines the current subtitle takes (who: text, wrapped).
func sub_lines() -> Array[String]:
	if msgs.is_empty(): return []
	var e: Dictionary = msgs[0]
	var s := String(e.text) if String(e.who) == "" else "%s: %s" % [String(e.who), String(e.text)]
	var ls := wrap_lines(s, HudLayout.SUB_CHARS)
	if ls.size() > HudLayout.SUB_MAX_LINES:
		ls = ls.slice(0, HudLayout.SUB_MAX_LINES)
		ls[ls.size() - 1] = clip(ls[ls.size() - 1], HudLayout.SUB_CHARS)
	return ls

func obj_lines() -> Array[String]:
	if objective == "": return []
	var ls := wrap_lines(objective, HudLayout.OBJ_CHARS)
	if ls.size() > HudLayout.OBJ_MAX_LINES: ls = ls.slice(0, HudLayout.OBJ_MAX_LINES)
	return ls

func prompt_text() -> String:
	return _prompt

# ------------------------------------------------------------------ drawing

func _panel(r: Rect2, a := 0.78) -> void:
	draw_rect(r, Color(0.04, 0.035, 0.05, a))
	draw_rect(r, Color(1, 1, 1, 0.08), false, 1.0)

func _draw() -> void:
	if sim == null or stepped_aside: return
	var spec := sim.spec
	# ---- top left: the car
	var cb := HudLayout.CAR_BAR
	_panel(cb)
	var title := "%s %s '%s" % [spec.make, spec.model, str(int(spec.year)).substr(2)]
	var big := PixelFont.width(title, 2) <= cb.size.x - 12
	PixelFont.draw(self, cb.position + Vector2(6, 5 if big else 7), title if big else title.substr(0, 50), BONE, 2 if big else 1)
	var assist_name: String = ["SIM", "STREET", "ARCADE"][sim.assist]
	PixelFont.draw(self, cb.position + Vector2(6, 20), "%s  -  %s" % [assist_name, "AUTO" if sim.auto_gearbox else "MANUAL"], ASH)
	# ---- top right: the world
	var kb := HudLayout.CLOCK_BAR
	_panel(kb)
	PixelFont.draw(self, kb.position + Vector2(6, 5), "%s  %s" % [sky.clock_str(), sky.season.to_upper()], BONE, 2)
	PixelFont.draw(self, kb.position + Vector2(6, 20), "%s  %d°C" % [sky.label(), int(sky.temperature())], GOLD if sky.weather in ["storm", "blizzard", "freezing", "fog"] else BONE)
	var where := "%s - ROAD: %s" % [place, surface.to_upper()]
	if PixelFont.width(where) > kb.size.x - 12: where = where.substr(0, int((kb.size.x - 12) / 4.0))
	PixelFont.draw(self, kb.position + Vector2(6, 29), where, GOLD if surface in ["ice", "snow", "leaves", "mud", "water"] else ASH)
	# ---- the info column: objective, subtitle, prompt
	var ol := obj_lines()
	var sl := sub_lines()
	var pr := prompt_text()
	if sim.engine_blown and pr == "": pr = Hints.fmt("{reset}: CALL TOBY FOR A TOW") if Hints.key("reset") != "" else "ENGINE SEIZED: TOBY'S ON HIS WAY"
	var col := HudLayout.info(ol.size(), sl.size(), pr != "")
	if not ol.is_empty():
		var r: Rect2 = col[0]
		_panel(r)
		for k in ol.size(): PixelFont.draw(self, r.position + Vector2(6, 4 + k * 8), ol[k], GOLD)
	if not sl.is_empty():
		var r: Rect2 = col[1]
		var e: Dictionary = msgs[0]
		var a := clampf(float(e.t) * 2.0, 0.0, 1.0) * clampf((float(e.dur) - float(e.t)) * 6.0 + 0.3, 0.0, 1.0)
		_panel(r, 0.82 * a)
		var accent := { "say": GOLD, "award": GOLD, "police": BLUE, "warn": RED, "tip": GREEN }.get(String(e.kind), ASH) as Color
		draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(accent, a))
		var who_w := 0.0
		if String(e.who) != "": who_w = PixelFont.width(String(e.who) + ":") + 4
		for k in sl.size():
			var ln: String = sl[k]
			var p := r.position + Vector2(6, 4 + k * 8)
			if k == 0 and who_w > 0.0:
				PixelFont.draw(self, p, String(e.who) + ":", Color(accent, a))
				PixelFont.draw(self, p + Vector2(who_w, 0), ln.substr(String(e.who).length() + 2), Color(BONE, a))
			else:
				PixelFont.draw(self, p, ln, Color(BONE if String(e.kind) != "award" else GOLD, a))
	if pr != "":
		var r: Rect2 = col[2]
		var w := minf(PixelFont.width(pr) + 14, r.size.x)
		var pill := Rect2(r.position.x + (r.size.x - w) / 2.0, r.position.y, w, r.size.y)
		draw_rect(pill, Color(0.05, 0.05, 0.07, 0.85))
		draw_rect(pill, Color(GOLD, 0.7), false, 1.0)
		PixelFont.draw_centered(self, pill.get_center().x, pill.position.y + 4, pr.substr(0, int((r.size.x - 14) / 4.0)), BONE)
	# ---- the scan tool
	_diag()
	# ---- the controls card, when asked for
	if show_help:
		var hr := HudLayout.HELP
		_panel(hr, 0.9)
		var lines := [
			Hints.fmt("DRIVE {drive}  STEER {steer}  HANDBRAKE {handbrake}"),
			Hints.fmt("SHIFT {shift}  AUTO/MANUAL {gearbox}  TOW HOME {reset}"),
			Hints.fmt("BLINKERS {blinkers}  HAZARDS {hazards}"),
			Hints.fmt("BACK UP: STOP, LET GO, THEN HOLD {brake}"),
			Hints.fmt("HIGH BEAMS {high_beams} (HOLD TO FLASH)  HORN {horn}"),
			Hints.fmt("MAP {map}  GIGS {jobs}  USE {use}"),
			Hints.fmt("HIDE THIS {help}  PAUSE, SETTINGS {pause}"),
		]
		for i in lines.size():
			PixelFont.draw(self, hr.position + Vector2(6, 5 + i * 11), String(lines[i]).substr(0, 60), BONE if i < lines.size() - 1 else ASH)

# ------------------------------------------------------------------ the scan tool

## The colours of the scan tool, after the dash it's clipped under: [case, screen, text, dim, warn, bad].
func _diag_palette() -> Array:
	match diag_style:
		"digital80": return [Color("15171a"), Color("04140a"), Color("5aff8a"), Color("1f5a33"), Color("e8ff5a"), Color("ff6a4a")]
		"tft": return [Color("1a1a1f"), Color("0a0a10"), Color("e8eaf0"), Color("4a4c58"), Color("ffb030"), Color("ff3a3a")]
		"truck": return [Color("2a2218"), Color("140c04"), Color("ff9a3a"), Color("5a3a18"), Color("ffd05a"), Color("ff4a2a")]
	return [Color("1c1a16"), Color("1a1206"), Color("ffb030"), Color("5a3e12"), Color("ffe080"), Color("ff5a3a")]

## The car's codes right now, worst first: [code, text, severity 0 info / 1 warn / 2 bad].
func codes() -> Array:
	var out: Array = []
	if sim == null: return out
	if sim.engine_blown: out.append(["P0000", "ENGINE SEIZED", 2])
	if sim.burn_fuel and sim.fuel_l <= 0.05: out.append(["P0087", "OUT OF FUEL", 2])
	if sim.head_gasket: out.append(["P0301", "HEAD GASKET", 2])
	if sim.valves_bent: out.append(["P0300", "VALVES BENT - MISFIRE", 2])
	if sim.coolant_c > 112.0: out.append(["P0217", "OVERHEATING %d°C" % int(sim.coolant_c), 2])
	var flat := false
	var worst := 99.0
	for t in sim.tires:
		if bool(t.flat): flat = true
		worst = minf(worst, float(t.tread))
	if flat: out.append(["C0750", "TIRE FLAT", 2])
	if sim.clutch_cond <= 0.08: out.append(["P0700", "NO CLUTCH - NO DRIVE", 2])
	elif sim.clutch_cond < 0.5: out.append(["P0700", "CLUTCH SLIPPING", 1])
	if not (sim.spec.engine.get("turbo", {}) as Dictionary).is_empty():
		if sim.turbo_cond <= 0.1: out.append(["P0299", "TURBO DEAD - NO BOOST", 2])
		elif sim.turbo_cond < 0.4: out.append(["P0299", "TURBO BURNING OIL", 1])
	if sim.pads_mm <= 2.0: out.append(["C1000", "PADS METAL ON METAL", 2])
	elif sim.pads_mm < 3.5: out.append(["C1000", "PADS LOW %.1f MM" % sim.pads_mm, 1])
	if sim.radiator < 0.85: out.append(["P0118", "COOLANT LEAK", 1])
	if worst < 1.6: out.append(["C0751", "TREAD LOW %.1f MM" % worst, 1])
	if sim.burn_fuel and sim.fuel_l > 0.05 and sim.fuel_frac() < 0.15: out.append(["P0460", "FUEL LOW", 1])
	for k in _timed: out.append([k, String(_timed[k][0]), int(_timed[k][1])])
	if sim.oil_c < 45.0 and not sim.engine_blown: out.append(["P0128", "COLD - KEEP IT UNDER 4K", 0])
	out.sort_custom(func(a, b): return int(a[2]) > int(b[2]))
	return out

func _diag() -> void:
	if not show_diag: return
	var r := HudLayout.DIAG
	var pal := _diag_palette()
	var cs := codes()
	# a new warning makes the scan tool flash; it never goes up on the windshield
	var now := {}
	for c in cs:
		now[String(c[0])] = true
		if int(c[2]) >= 1 and not _codes_shown.has(String(c[0])): _flash_t = 1.5
	_codes_shown = now
	draw_rect(r, pal[0])
	var flash_on := _flash_t > 0.0 and fmod(_flash_t, 0.3) > 0.15
	draw_rect(r, (pal[5] as Color) if flash_on else Color(1, 1, 1, 0.12), false, 1.0)
	var scr := Rect2(r.position + Vector2(3, 3), r.size - Vector2(6, 6))
	draw_rect(scr, pal[1])
	var x0 := scr.position.x
	var y0 := scr.position.y
	PixelFont.draw(self, Vector2(x0 + 3, y0 + 2), "J1939 FLEET" if diag_style == "truck" else "OBD-II SCAN", pal[3])
	# the warning lights along the top
	var tx := scr.end.x - 4
	var blink := CarView.blink_on()
	var lights: Array = []
	if player and player.view.blink_right and blink: lights.append([">", GREEN])
	if sim.coolant_c > 112.0: lights.append(["TEMP", pal[5]])
	if not cs.is_empty() and int(cs[0][2]) >= 1 and String(cs[0][0]).begins_with("P"): lights.append(["CEL", pal[4]])
	if sim.burn_fuel and sim.fuel_frac() < 0.15 and (sim.fuel_frac() > 0.04 or blink): lights.append(["FUEL", Color("ffb030")])
	if player and player.beam > 0.5 and player.view.headlights: lights.append(["HI", BLUE])
	if player and player.view.blink_left and blink: lights.append(["<", GREEN])
	for l in lights:
		var w := PixelFont.width(String(l[0]))
		tx -= w
		PixelFont.draw(self, Vector2(tx, y0 + 2), String(l[0]), l[1])
		tx -= 5
	# the tires, top down: green to red by tread, grey and crossed when flat
	var tb := Vector2(x0 + 3, y0 + 10)
	var spots := [Vector2(0, 0), Vector2(9, 0), Vector2(0, 13), Vector2(9, 13)]
	var tread_mm := float(sim.spec.tires.tread_mm)
	for i in 4:
		var t: Dictionary = sim.tires[i]
		var frac: float = float(t.tread) / maxf(tread_mm, 0.1)
		var c := GREEN.lerp(GOLD, clampf(1.0 - frac * 1.6, 0, 1)).lerp(RED, clampf(1.0 - frac * 3.0, 0, 1))
		var p: Vector2 = tb + spots[i]
		if bool(t.flat):
			draw_rect(Rect2(p, Vector2(6, 10)), Color("555"))
			draw_line(p, p + Vector2(6, 10), INK, 1.0)
		else:
			draw_rect(Rect2(p, Vector2(6, 10)), c)
			if float(t.temp) >= 120.0: draw_rect(Rect2(p, Vector2(6, 10)), RED, false, 1.0)
	# the codes
	var cx := x0 + 22
	var cy := y0 + 10
	if cs.is_empty():
		PixelFont.draw(self, Vector2(cx, cy), "NO CODES", pal[3])
		var worst := 99.0
		for t in sim.tires: worst = minf(worst, float(t.tread))
		PixelFont.draw(self, Vector2(cx, cy + 8), "TREAD %.1f MM  CLT %d°C  OIL %d°C" % [worst, int(sim.coolant_c), int(sim.oil_c)], pal[3])
	else:
		for k in mini(cs.size(), 3):
			var c: Array = cs[k]
			var colr: Color = [pal[2], pal[4], pal[5]][int(c[2])]
			var line := "%s %s" % [String(c[0]), String(c[1])]
			if k == 2 and cs.size() > 3: line = "+%d MORE CODES" % (cs.size() - 2)
			PixelFont.draw(self, Vector2(cx, cy + k * 8), line.substr(0, 46), colr)
	# the last thing that happened, fading
	if _event_t > 0.0 and cs.size() < 3:
		PixelFont.draw(self, Vector2(cx, scr.end.y - 7), _event.substr(0, 46), Color(pal[2], clampf(_event_t, 0.0, 1.0)))

# ------------------------------------------------------------------ helpers

func _bar(p: Vector2, label: String, frac: float, col_: Color, value: String) -> void:
	PixelFont.draw(self, p, label, ASH)
	draw_rect(Rect2(p.x + 28, p.y, 40, 5), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(p.x + 28, p.y, 40 * clampf(frac, 0, 1), 5), col_)
	PixelFont.draw(self, Vector2(p.x + 72, p.y), value, BONE)

## `text` cut short with "..." to fit in what `n` old fixed-width characters took up.
static func clip(text: String, n: int) -> String:
	var max_w := n * 4 - 1
	var t := text
	while t.length() > 0 and PixelFont.width(t + "...") > max_w: t = t.substr(0, t.length() - 1)
	return t.strip_edges() + "..."

## Word-wraps `text` into lines no wider than `n` characters of the old fixed-width font took up
## (n * 4 - 1 px): measured in pixels, since the letters aren't all one width any more.
static func wrap_lines(text: String, n: int) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	var max_w := n * 4 - 1
	for word in text.split(" "):
		if cur == "": cur = word
		elif PixelFont.width(cur + " " + word) <= max_w: cur += " " + word
		else:
			out.append(cur)
			cur = word
	if cur != "": out.append(cur)
	return out
