## "Make your avatar." The game tells the player this is the face and name it'll use if online
## play ever comes. In the story, it's the old manager: the one who ran the counter before
## Frank left Covington Auto to Leo.
extends Node2D

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")

const NAMES := ["DANNY BOUCHARD", "SHERRY LEGER", "RAY MELANSON", "DEB GALLANT", "LOUIS ARSENAULT", "TINA COMEAU",
	"WAYNE STEEVES", "CAROL DOIRON", "MARCEL GOGUEN", "LINDA HACHE"]
const ROWS := ["NAME", "FACE", "LOOK", "AGE", "DONE"]

var seed := 0
var female := 0
var age := 52
var name_text := ""
var row := 0
var name_i := 0
var edit: LineEdit
var t := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Controls.setup()
	rng.randomize()
	seed = rng.randi()
	female = rng.randi() % 2
	edit = LineEdit.new()
	edit.position = Vector2(300, 92)
	edit.size = Vector2(300, 20)
	edit.max_length = 22
	edit.placeholder_text = "TYPE A NAME"
	edit.add_theme_color_override("font_color", BONE)
	edit.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_color = GOLD
	sb.set_border_width_all(1)
	edit.add_theme_stylebox_override("normal", sb)
	edit.add_theme_stylebox_override("focus", sb)
	edit.text_changed.connect(func(s): name_text = s.to_upper())
	add_child(edit)
	edit.grab_focus()

func _process(dt: float) -> void:
	t += dt
	var typing := edit.has_focus() and row == 0
	if Input.is_action_just_pressed("ui_down") and not typing or (Input.is_action_just_pressed("ui_down") and typing):
		row = (row + 1) % ROWS.size()
		if row != 0: edit.release_focus()
	if Input.is_action_just_pressed("ui_up"):
		row = (row + ROWS.size() - 1) % ROWS.size()
		if row == 0: edit.grab_focus()
	var dir := 0
	if Input.is_action_just_pressed("ui_right") and not typing: dir = 1
	if Input.is_action_just_pressed("ui_left") and not typing: dir = -1
	if dir != 0:
		match ROWS[row]:
			"NAME":
				name_i = (name_i + dir + NAMES.size()) % NAMES.size()
				name_text = NAMES[name_i]
				edit.text = name_text
			"FACE": seed = rng.randi()
			"LOOK": female = 1 - female
			"AGE": age = clampi(age + dir * 3, 28, 70)
	if Input.is_action_just_pressed("horn"):           # X / H: a whole new person
		seed = rng.randi()
		female = rng.randi() % 2
		age = 30 + rng.randi() % 38
	if Input.is_action_just_pressed("ui_accept") and not typing:
		if ROWS[row] == "DONE": _done()
		elif ROWS[row] == "FACE": seed = rng.randi()
		elif ROWS[row] == "NAME": edit.grab_focus()
	elif Input.is_action_just_pressed("ui_accept") and typing:
		row = 1
		edit.release_focus()
	queue_redraw()

func _done() -> void:
	if name_text.strip_edges() == "": name_text = NAMES[rng.randi() % NAMES.size()]
	StoryState.avatar = { "name": name_text.strip_edges(), "seed": seed, "female": female, "age": age }
	StoryState.save()
	StoryState.advance(get_tree())

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("16141c"))
	PixelFont.draw(self, Vector2(24, 20), "CREATE YOUR AVATAR", GOLD, 3, INK)
	PixelFont.draw(self, Vector2(24, 50), "THIS IS YOU. IF DRIVEBOSS EVER GETS ONLINE PLAY, THIS IS THE FACE AND NAME", BONE)
	PixelFont.draw(self, Vector2(24, 60), "EVERYONE ELSE WILL SEE. MAKE IT A GOOD ONE.", BONE)
	# the portrait, big, like a licence photo
	draw_rect(Rect2(36, 86, 204, 204), Color("c6d6e8"))
	draw_texture_rect(Face.texture(seed, female, age), Rect2(42, 92, 192, 192), false)
	PixelFont.draw_centered(self, 138, 296, name_text if name_text != "" else "(NO NAME YET)", GOLD if name_text != "" else ASH, 2)
	for k in ROWS.size():
		var y := 96 + k * 34
		var on := k == row
		draw_rect(Rect2(270, y - 6, 340, 28), Color(0.85, 0.64, 0.25, 0.18) if on else Color(1, 1, 1, 0.03))
		PixelFont.draw(self, Vector2(278, y), ROWS[k], GOLD if on else ASH, 2)
		var val := ""
		match ROWS[k]:
			"NAME": val = ""
			"FACE": val = "< NEW FACE >"
			"LOOK": val = "< %s >" % ("FEMININE" if female == 1 else "MASCULINE")
			"AGE": val = "< %d >" % age
			"DONE": val = "THAT'S ME"
		if val != "": PixelFont.draw(self, Vector2(360, y), val, BONE if on else ASH, 2)
	edit.position = Vector2(360, 90)
	edit.size = Vector2(240, 22)
	PixelFont.draw(self, Vector2(24, 318), Hints.fmt("{updown}: PICK A ROW  {leftright}: CHANGE  {horn}: SOMEONE ELSE ENTIRELY  {ui_accept}: DONE"), ASH)
	PixelFont.draw(self, Vector2(24, 330), "LEFT/RIGHT ON NAME PICKS ONE FOR YOU." if Hints.pad else "TYPE YOUR NAME, OR LEFT/RIGHT ON NAME TO PICK ONE.", Color(ASH, 0.7))
