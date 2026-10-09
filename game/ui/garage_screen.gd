## The garage at Covington Auto: the cars you own, side by side in the bays. Pick one to take
## out, or have Gus straighten out the one you just brought back.
class_name GarageScreen
extends Control

signal picked(index: int)
signal repaired(index: int)
signal closed

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")
const RED := Color("e0402e")

const GUS := [
	"\"TAKE WHAT YOU WANT. BRING IT BACK IN ONE PIECE.\"",
	"\"THAT ONE MAKES A NOISE. NOT A GOOD NOISE.\"",
	"\"YOUR FATHER WOULD'VE HAD THAT RUNNING BY LUNCH.\"",
	"\"DON'T PARK IT ON THE GRASS. THE GRASS HAS FEELINGS.\"",
]

var data: Dictionary
var specs: Array = []
var views: Array[CarView] = []
var sel := 0
var current := 0
var _line := 0

func open(save: Dictionary) -> void:
	data = save
	current = int(data.current)
	sel = current
	_line = randi() % GUS.size()
	for v in views: v.queue_free()
	views.clear()
	specs.clear()
	var n := (data.garage as Array).size()
	for i in n:
		var car: Dictionary = data.garage[i]
		var spec := SaveGame.load_spec(car.id)
		specs.append(spec)
		var v := CarView.new()
		v.art = CarArt.new(spec, Color(car.paint), car.damage, 3)
		v.heading = -PI / 2.0
		v.position = Vector2(_bay_x(i, n), 170)
		v.scale = Vector2(1.6, 1.6)
		add_child(v)
		views.append(v)
	visible = true

func _bay_x(i: int, n: int) -> float:
	return 320.0 + (float(i) - (n - 1) / 2.0) * 140.0

func _process(_dt: float) -> void:
	if not visible: return
	CarView.screen_up = Vector2(0, -1)
	if Input.is_action_just_pressed("ui_right"): sel = (sel + 1) % specs.size()
	if Input.is_action_just_pressed("ui_left"): sel = (sel + specs.size() - 1) % specs.size()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("use"):
		picked.emit(sel)
		visible = false
	if Input.is_action_just_pressed("horn") or Input.is_action_just_pressed("reset"):
		repaired.emit(sel)
		var car: Dictionary = data.garage[sel]
		views[sel].art = CarArt.new(specs[sel], Color(car.paint), car.damage, 3)
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("map") or Input.is_action_just_pressed("handbrake"):
		visible = false
		closed.emit()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("1c1a1e"))
	# the shop floor: concrete, bay lines, the lift posts
	draw_rect(Rect2(0, 90, 640, 200), Color("5a5a58"))
	for i in specs.size() + 1:
		var x := _bay_x(i, specs.size()) - 70.0
		draw_rect(Rect2(x - 1, 90, 2, 200), Color("c8a030"))
	draw_rect(Rect2(0, 80, 640, 10), Color("2a2a30"))
	PixelFont.draw(self, Vector2(12, 12), "THE GARAGE", GOLD, 3, INK)
	PixelFont.draw(self, Vector2(12, 40), "COVINGTON AUTO - BAYS 1 TO %d" % specs.size(), ASH)
	PixelFont.draw(self, Vector2(12, 52), "GUS: " + GUS[_line], BONE)
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var car: Dictionary = data.garage[i]
		var x := _bay_x(i, specs.size())
		if i == sel: draw_rect(Rect2(x - 66, 92, 132, 196), Color(0.85, 0.64, 0.25, 0.15))
		var name := "%s %s" % [spec.make, spec.model]
		PixelFont.draw_centered(self, x, 236, name.to_upper(), GOLD if i == sel else BONE)
		PixelFont.draw_centered(self, x, 246, "'%s" % str(int(spec.year)).substr(2), ASH)
		var dmg: float = 0.0
		for k in car.damage: dmg += float(car.damage[k])
		var cond := "MINT" if dmg < 0.05 else ("DINGED" if dmg < 0.6 else ("BEAT UP" if dmg < 1.6 else "A WRECK"))
		PixelFont.draw_centered(self, x, 258, cond, Color("6fbf5a") if dmg < 0.05 else (GOLD if dmg < 1.6 else RED))
		if i == current: PixelFont.draw_centered(self, x, 270, "(OUT FRONT)", ASH)
	var s: Dictionary = specs[sel]
	PixelFont.draw(self, Vector2(12, 300), String(s.get("blurb", "")).to_upper().substr(0, 150), BONE)
	PixelFont.draw(self, Vector2(12, 312), "%s - %s - %d KG - DASH: %s - GPS: %s" % [String(s.engine.name).to_upper(), s.get("drivetrain", "RWD"), int(s.mass), String(s.get("dash", "")).to_upper(), String(s.get("gps", "")).to_upper()], ASH)
	PixelFont.draw(self, Vector2(12, 336), Hints.fmt("{leftright}: PICK  {use}: TAKE IT OUT  {horn}: GUS FIXES IT UP  {ui_cancel}: CLOSE"), ASH)
