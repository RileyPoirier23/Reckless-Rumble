## The studio card at startup: a shutter opens on 506 CLICKS, the click, and on to the title.
## Any key, button or click skips it. Demos and tests go straight through.
extends Node2D

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const LIFE := 3.0                 # seconds on screen before it goes to the title on its own
const CLICK_AT := 0.55            # the shutter's done opening, the click lands

var t := 0.0
var _left := false
var _clicked := false
var _player: AudioStreamPlayer

func _ready() -> void:
	if not OS.get_cmdline_user_args().is_empty() or GameSettings.testing():
		_go()
		return
	_player = AudioStreamPlayer.new()
	_player.stream = _click_sound()
	_player.volume_db = -6.0
	add_child(_player)

func _go() -> void:
	if _left: return
	_left = true
	get_tree().change_scene_to_file.call_deferred("res://title.tscn")

func _input(e: InputEvent) -> void:
	if _left: return
	var skip: bool = (e is InputEventKey and e.pressed and not e.echo) \
		or (e is InputEventJoypadButton and e.pressed) \
		or (e is InputEventMouseButton and e.pressed)
	if skip: _go()

func _process(dt: float) -> void:
	if _left: return
	t += dt
	if t >= CLICK_AT and not _clicked:
		_clicked = true
		if _player != null: _player.play()
	if t >= LIFE: _go()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), INK)
	if _left: return
	var c := Vector2(320, 164)
	# the shutter: six blades sliding open from a point, then the logo behind them lights up
	var open := smoothstep(0.0, 1.0, clampf(t / CLICK_AT, 0.0, 1.0))
	var flash := 1.0 - clampf((t - CLICK_AT) / 0.25, 0.0, 1.0) if t >= CLICK_AT else 0.0
	var fade := 1.0 - clampf((t - (LIFE - 0.45)) / 0.45, 0.0, 1.0)
	var lit := clampf((t - CLICK_AT) / 0.2, 0.0, 1.0) * fade
	# the logo: a camera iris ring round the 506, CLICKS under it
	if lit > 0.0:
		var gold := Color(GOLD, lit)
		draw_arc(c, 70.0, 0.0, TAU, 48, Color(gold, 0.35 * lit), 3.0)
		for k in 6:
			var a := k * TAU / 6.0 + t * 0.25
			draw_line(c + Vector2.from_angle(a) * 62.0, c + Vector2.from_angle(a + 0.35) * 72.0, Color(gold, 0.6 * lit), 2.0)
		PixelFont.draw_centered(self, c.x, c.y - 30.0, "506", gold, 8, Color(INK, lit))
		PixelFont.draw_centered(self, c.x, c.y + 44.0, "CLICKS", Color(BONE, lit), 3, Color(INK, lit))
		PixelFont.draw_centered(self, c.x, 282.0, "PRESENTS", Color(ASH, lit * 0.9), 1)
	# the blades, over the logo, parting to the edges
	var r := 420.0 * open
	for k in 6:
		var a0 := k * TAU / 6.0
		var a1 := a0 + TAU / 6.0
		var pts := PackedVector2Array([c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a0) * 900.0,
			c + Vector2.from_angle(a1) * 900.0, c + Vector2.from_angle(a1) * r])
		draw_colored_polygon(pts, Color("16141b"))
		draw_line(c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a0) * 900.0, Color(0.3, 0.28, 0.32), 1.0)
	if flash > 0.0: draw_rect(Rect2(0, 0, 640, 360), Color(1.0, 0.96, 0.85, 0.55 * flash))
	PixelFont.draw(self, Vector2(8, 350), Hints.fmt("{ui_accept}: SKIP"), Color(ASH, 0.5 * fade))

## A camera's click: a short burst of noise with a bright edge, made here (no file).
static func _click_sound() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.09)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 506
	for i in n:
		var tt := float(i) / rate
		var env := exp(-tt * 70.0)
		var v := (rng.randf() * 2.0 - 1.0) * 0.6 * env + sin(tt * TAU * 1900.0) * 0.5 * exp(-tt * 140.0) \
			+ sin(tt * TAU * 420.0) * 0.25 * exp(-tt * 40.0)
		var s := int(clampf(v, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w
