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
var history: Array = []           # set name at each line (so going back restores the set)
var demo := false

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
	demo = OS.get_cmdline_user_args().has("--story-demo")

func _process(dt: float) -> void:
	t += dt
	if step.type == "scene" and i < lines.size():
		shown += dt * CPS
		var ln: Array = lines[i]
		# instructions run as soon as they come up
		match String(ln[0]):
			"set":
				set_name = ln[1]
				_next()
			"cash":
				StoryState.cash += int(ln[1])
				_next()
			"flag":
				StoryState.set_flag(ln[1])
				_next()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("click") or Input.is_action_just_pressed("use"):
		press()
	if Input.is_action_just_pressed("shift_down") or Input.is_action_just_pressed("ui_text_backspace"):
		back()
	if _is_choice():
		var opts: Array = lines[i][1]
		if Input.is_action_just_pressed("ui_down"): choice_sel = (choice_sel + 1) % opts.size()
		if Input.is_action_just_pressed("ui_up"): choice_sel = (choice_sel + opts.size() - 1) % opts.size()
	if Input.is_action_just_pressed("menu_back"):
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

func _is_choice() -> bool:
	return step.type == "scene" and i < lines.size() and String(lines[i][0]) == "choice"

## Forward: finish the line if it's still typing, otherwise the next line.
func press() -> void:
	if step.type == "card":
		StoryState.advance(get_tree())
		return
	if i >= lines.size(): return
	if _is_choice():
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
	history.append(set_name)
	i += 1
	shown = 0.0
	choice_sel = 0
	if i >= lines.size():
		StoryState.advance(get_tree())

func back() -> void:
	# step back to the previous spoken line (instructions don't count)
	var j := i - 1
	while j >= 0 and String(lines[j][0]) in ["set", "cash", "flag"]: j -= 1
	if j < 0: return
	while history.size() > j: set_name = history.pop_back()
	i = j
	shown = 9999.0

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	if step.is_empty(): return
	if step.type == "card":
		_card()
		return
	StorySets.draw(self, set_name, t)
	if i >= lines.size(): return
	var ln: Array = lines[i]
	if String(ln[0]) == "choice":
		_choices(ln[1])
	elif not String(ln[0]) in ["set", "cash", "flag"]:
		_box(String(ln[0]), StoryState.fill(String(ln[1])))

func _card() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b090d"))
	var a := clampf(t * 1.5, 0.0, 1.0)
	PixelFont.draw_centered(self, 320, 120, String(step.title), Color(GOLD, a), 5, INK)
	if String(step.get("sub", "")) != "":
		PixelFont.draw_centered(self, 320, 162, String(step.sub), Color(BONE, a), 3)
	PixelFont.draw_centered(self, 320, 200, String(step.get("small", "")), Color(ASH, a), 1)
	if t > 1.0: PixelFont.draw_centered(self, 320, 320, "PRESS A / ENTER", Color(BONE, 0.4 + 0.3 * sin(t * 4.0)))

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
	PixelFont.draw(self, Vector2(14, 342), "A/ENTER NEXT   LB/BACKSPACE BACK   ESC MENU", Color(ASH, 0.6))

func _choice_rect(k: int, n: int) -> Rect2:
	return Rect2(120, 270 - (n - k) * 22, 400, 18)

func _choices(opts: Array) -> void:
	draw_rect(Rect2(8, 262, 624, 92), Color(0.04, 0.035, 0.05, 0.94))
	PixelFont.draw(self, Vector2(20, 272), "LEO:", GOLD, 2)
	PixelFont.draw(self, Vector2(20, 300), "UP/DOWN TO PICK, A/ENTER TO SAY IT", Color(ASH, 0.7))
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
