## Plays a story step that isn't driving or the counter: a cutscene (a set drawn by code and a
## dialogue box with CAGE BOSS portraits) or a title card. Back and forward through the lines,
## pick choices, and the story moves on when it's done.
extends Node2D

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")

const CPS := 55.0                 # typewriter: characters a second

var step: Dictionary
var lines: Array = []
var i := 0
var shown := 0.0
var set_name := "black"
var choice_sel := 0
var t := 0.0
var history: Array = []           # [set, cast poses] at each line (so going back restores both)
var demo := false
var cast := {}                     # who -> { x, facing, pose } for the people standing in the set
var _paid := {}                    # "cash" lines already counted (going back and forward again doesn't pay twice)

func _ready() -> void:
	Controls.setup()
	step = StoryState.current()
	if step.is_empty() or String(step.get("type", "")) == "end":
		get_tree().change_scene_to_file.call_deferred("res://title.tscn")
		return
	if step.type == "scene":
		var sc: Dictionary = StoryScript.SCENES[step.id]
		set_name = sc.set
		lines = sc.lines
		for c in sc.get("cast", []):
			cast[String(c[0])] = { "x": int(c[1]), "facing": int(c[2]), "pose": String(c[3]) }
	demo = OS.get_cmdline_user_args().has("--story-demo")

func _process(dt: float) -> void:
	t += dt
	if step.type == "scene" and i < lines.size(): shown += dt * CPS
	# instructions run as soon as they come up (a run of them all at once: two people bow together)
	while step.type == "scene" and i < lines.size() and String(lines[i][0]) in ["set", "cash", "flag", "pose"]:
		var ln: Array = lines[i]
		match String(ln[0]):
			"set":
				set_name = ln[1]
				_next()
			"cash":
				if not _paid.has(i):
					_paid[i] = true
					StoryState.cash += int(ln[1])
				_next()
			"flag":
				StoryState.set_flag(ln[1])
				_next()
			"pose":
				if cast.has(String(ln[1])): cast[String(ln[1])].pose = String(ln[2])
				_next()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("click") or Input.is_action_just_pressed("use"):
		press()
	if Input.is_action_just_pressed("shift_down") or Input.is_action_just_pressed("ui_text_backspace"):
		back()
	if _is_choice():
		var opts: Array = lines[i][1]
		if Input.is_action_just_pressed("ui_down"): choice_sel = (choice_sel + 1) % opts.size()
		if Input.is_action_just_pressed("ui_up"): choice_sel = (choice_sel + opts.size() - 1) % opts.size()
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("ui_back_pad"):
		get_tree().change_scene_to_file("res://title.tscn")
	queue_redraw()

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _is_choice():
			var opts: Array = lines[i][1]
			for k in opts.size():
				if _choice_rect(k, opts.size()).has_point(get_global_mouse_position()):
					choice_sel = k
		press()

func _poses() -> Dictionary:
	var d := {}
	for who in cast: d[who] = cast[who].pose
	return d

func _is_choice() -> bool:
	return step.type == "scene" and i < lines.size() and String(lines[i][0]) == "choice"

## Forward: finish the line if it's still typing, otherwise the next line.
func press() -> void:
	if step.type == "card":
		StoryState.advance(get_tree())
		return
	if i >= lines.size(): return
	if _is_choice():
		# back up and pick again: only the last pick counts
		for o in lines[i][1]: StoryState.flags.erase(String(o[1]))
		var opt: Array = lines[i][1][choice_sel]
		StoryState.set_flag(opt[1])
		_next()
		return
	var full := StoryState.fill(String(lines[i][1])).length()
	if shown < full:
		shown = full
		return
	_next()

func _next() -> void:
	history.append([set_name, _poses()])
	i += 1
	shown = 0.0
	choice_sel = 0
	if i >= lines.size():
		StoryState.advance(get_tree())

func back() -> void:
	# step back to the previous spoken line (instructions don't count)
	var j := i - 1
	while j >= 0 and String(lines[j][0]) in ["set", "cash", "flag", "pose"]: j -= 1
	if j < 0: return
	while history.size() > j:
		var h: Array = history.pop_back()
		set_name = h[0]
		for who in h[1]: cast[who].pose = h[1][who]
	i = j
	shown = 9999.0

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	if step.is_empty(): return
	if step.type == "card":
		_card()
		return
	StorySets.draw(self, set_name, t)
	var ln: Array = lines[i] if i < lines.size() else ["*", ""]
	var who := String(ln[0])
	var talking := cast.has(who) and shown < StoryState.fill(String(ln[1])).length()
	_people(who, talking)
	if i >= lines.size(): return
	if who == "choice":
		_choices(ln[1])
	elif not who in ["set", "cash", "flag", "pose"]:
		if who != "*" and not cast.has(who) and who != "MANAGER": _phone(who, StoryState.fill(String(ln[1])))
		_box(who, StoryState.fill(String(ln[1])))

## The cast, standing in the set (2x), the one talking lit and bobbing, the rest a touch darker.
func _people(speaker: String, talking: bool) -> void:
	var order := cast.keys()
	order.sort_custom(func(a, b): return cast[a].x < cast[b].x)
	var k := 0
	for who in order:
		var c: Dictionary = cast[who]
		var is_speaker: bool = who == speaker
		var frame := 1 if (is_speaker and talking and int(t * 9.0) % 2 == 0) else 0
		var tex := PixPeople.sprite(String(who), String(c.pose), frame)
		var bob := 0.0
		if is_speaker and talking: bob = -2.0 * absf(sin(t * 9.0))
		elif fmod(t + float(k) * 0.9, 3.2) < 0.35: bob = -2.0           # breathing
		var x := float(c.x) * 2.0
		var y := StorySets.FEET_Y * 2.0 - 128.0 + bob
		# a soft shadow on the floor
		draw_rect(Rect2(x - 16, 254, 32, 4), Color(0, 0, 0, 0.28))
		var mod := Color(1, 1, 1) if (is_speaker or speaker == "*" or not cast.has(speaker)) else Color(0.78, 0.78, 0.82)
		if int(c.facing) < 0:
			draw_set_transform(Vector2(x, y), 0.0, Vector2(-1, 1))
			draw_texture_rect(tex, Rect2(-26, 0, 52, 128), false, mod)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(tex, Rect2(x - 26, y, 52, 128), false, mod)
		k += 1

## Texts from people who aren't there: Leo's phone, up in the corner, with the message on it.
func _phone(who: String, text: String) -> void:
	var r := Rect2(470, 26, 132, 220)
	draw_rect(r.grow(4), Color("0e0e12"))
	draw_rect(r.grow(4), Color("3a3a40"), false, 2.0)
	draw_rect(r, Color("e8e4dc"))
	var cst: Dictionary = StoryScript.CAST.get(who, {})
	var col := Color(cst.get("color", "8a8478"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 22)), col.darkened(0.3))
	if not cst.is_empty():
		draw_texture_rect(Face.small_texture(int(cst.seed), int(cst.female), int(cst.age)), Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), false)
	PixelFont.draw(self, r.position + Vector2(23, 8), String(cst.get("name", who)), Color("f3ead2"))
	# the bubble
	var shown_text := text.substr(0, int(shown))
	var ls := _wrap(shown_text, 28)
	var bh := 8.0 + ls.size() * 9.0
	var by := r.position.y + 32.0
	draw_rect(Rect2(r.position.x + 6, by, r.size.x - 18, bh), Color("ffffff"))
	draw_rect(Rect2(r.position.x + 6, by, r.size.x - 18, bh), Color("c8c4bc"), false, 1.0)
	for k in mini(ls.size(), 18):
		PixelFont.draw(self, Vector2(r.position.x + 10, by + 5 + k * 9), ls[k], Color("1a1614"))
	if int(t * 2.0) % 2 == 0 and shown < text.length():
		draw_rect(Rect2(r.position.x + 8, r.end.y - 14, 18, 8), Color("d8d4cc"))
		PixelFont.draw(self, Vector2(r.position.x + 10, r.end.y - 12), "...", Color("6a6a70"))

func _card() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b090d"))
	var a := clampf(t * 1.5, 0.0, 1.0)
	PixelFont.draw_centered(self, 320, 120, String(step.title), Color(GOLD, a), 5, INK)
	if String(step.get("sub", "")) != "":
		PixelFont.draw_centered(self, 320, 162, String(step.sub), Color(BONE, a), 3)
	PixelFont.draw_centered(self, 320, 200, String(step.get("small", "")), Color(ASH, a), 1)
	if t > 1.0: PixelFont.draw_centered(self, 320, 320, Hints.fmt("PRESS {ui_accept}"), Color(BONE, 0.4 + 0.3 * sin(t * 4.0)))

func _box(who: String, text: String) -> void:
	var r := Rect2(8, 262, 624, 92)
	draw_rect(r, Color(0.04, 0.035, 0.05, 0.94))
	draw_rect(r, Color(1, 1, 1, 0.14), false, 1.0)
	var x0 := 20.0
	if who != "*":
		var cast: Dictionary = StoryScript.CAST.get(who, {})
		var tex: ImageTexture
		var name := who
		var col := GOLD
		if cast.is_empty() and who == "MANAGER":
			tex = Face.texture(int(StoryState.avatar.seed), int(StoryState.avatar.female), int(StoryState.avatar.age))
			name = StoryState.manager()
		elif not cast.is_empty():
			tex = Face.texture(int(cast.seed), int(cast.female), int(cast.age))
			name = cast.name
			col = Color(cast.color)
		if tex:
			draw_rect(Rect2(14, 268, 68, 68), Color(col, 0.9))
			draw_texture_rect(tex, Rect2(16, 270, 64, 64), false)
			x0 = 92.0
		draw_rect(Rect2(x0 - 2, 266, PixelFont.width(name, 2) + 10, 14), Color(col.darkened(0.55), 0.95))
		PixelFont.draw(self, Vector2(x0 + 3, 269), name, col.lightened(0.2), 2)
	var shown_text := text.substr(0, int(shown))
	var ls := _wrap(shown_text, int((620.0 - x0) / 8.0))
	var y := 288.0 if who != "*" else 276.0
	var tc := BONE if who != "*" else Color("c8c0a8")
	for k in mini(ls.size(), 4):
		PixelFont.draw(self, Vector2(x0, y + k * 14), ls[k], tc, 2)
	if shown >= text.length():
		PixelFont.draw(self, Vector2(600, 340), ">" if int(t * 3.0) % 2 == 0 else " ", GOLD, 2)
	PixelFont.draw(self, Vector2(14, 342), Hints.fmt("{ui_accept} NEXT  {shift_down} BACK  {menu_back} MENU"), Color(ASH, 0.6))

func _choice_rect(k: int, n: int) -> Rect2:
	return Rect2(120, 270 - (n - k) * 22, 400, 18)

func _choices(opts: Array) -> void:
	draw_rect(Rect2(8, 262, 624, 92), Color(0.04, 0.035, 0.05, 0.94))
	PixelFont.draw(self, Vector2(20, 272), "LEO:", GOLD, 2)
	PixelFont.draw(self, Vector2(20, 300), Hints.fmt("{updown}: PICK  {ui_accept}: SAY IT"), Color(ASH, 0.7))
	for k in opts.size():
		var r := _choice_rect(k, opts.size())
		var on := k == choice_sel
		draw_rect(r, Color(0.85, 0.64, 0.25, 0.3) if on else Color(0, 0, 0, 0.75))
		draw_rect(r, GOLD if on else Color(1, 1, 1, 0.2), false, 1.0)
		PixelFont.draw(self, r.position + Vector2(8, 5), String(opts[k][0]), GOLD if on else BONE)

static func _wrap(text: String, n: int) -> Array[String]:
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
