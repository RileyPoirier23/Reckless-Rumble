## Every vehicle family in every view, for looking over by eye:
## godot --path game --rendering-driver opengl3 -s tests/vehicle_demo.gd -- <out_dir> [mode] [only]
## mode: side (PixCars.image_of, 2x), top (CarView at each camera angle and six headings, at the
## game's zoom), stance (every drop and fitment, both views), steer (front wheels at every heading),
## dmg (crashed and worn), garage (CarView.paint_stack), all (the default). only: a name filter.
extends SceneTree

const HEADS := [0.0, 45.0, 90.0, 135.0, 180.0, 270.0]
const ZOOM := 2.6

var out := "user://vehicle_shots"
var only := ""
var root2: Node2D
var cam: Camera2D

## [label, spec source (catalogue id, json name or a spec), mods, damage]
func roster() -> Array:
	var r: Array = [
		["sedan", "fjord_crown_victorious_2005", {}],
		["sedan_old", "fjord_fairlame_1957", {}],
		["coupe", "silvio", {}],
		["muscle", "charjer", {}],
		["hatch", "fjord_escorted_1987", {}],
		["wagon", "fjord_country_square_1978", {}],
		["pickup", "fjord_f_one_fiddy_2015", {}],
		["dually", "fjord_f_three_fiddy_dually_2017", {}],
		["suv", "chevrolay_suburbian_2015", {}],
		["offroad", "jepp_wranglur_1995", {}],
		["van", "fjord_econolean_1995", {}],
		["minivan", "dodgy_grand_caravann_2016", {}],
		["kei", "daihatsoo_hijinx_1999", {}],
		["kei_truck", "suzooki_carrie_1998", {}],
		["mid", "acurra_en_ess_eks_1991", {}],
		["wedge", "pontiak_fieryo_1985", {}],
		["roadster", "mazduh_myata_1990", {}],
		["bubble", "volkswagon_beetel_1967", {}],
		["bus", "grumpman_metro_snore_forty_2012", {}],
		["schoolbus", "internashnal_skool_boss_2011", {}],
		["semi", "kenwerth_tee_six_eighty_ate_2016", {}],
		["daycab", "freightlinear_cascadeeya_2013", {}],
		["trailer", { "body": "trailer", "length": 13.6, "width": 2.55, "track": 2.1 }, { "decal": 1 }],
		["boxtruck", "internashnal_dura_snore_box_2015", {}],
		["stepvan", "grumpman_step_up_van_2004", {}],
		["packer", "macc_el_arr_packer_2009", {}],
		["tow", "tow", {}],
		["police", "charjer", { "police": true }],
		["fire", "fire", {}],
		["ambulance", "ambulance", {}],
		["ambulanz", "fjord_e_fiddy_ambulanz_2014", {}],
	]
	return r.filter(func(v: Array) -> bool: return only == "" or String(v[0]).contains(only))

func spec_of(src: Variant) -> Dictionary:
	if src is Dictionary: return src
	var s := CarCatalog.spec(String(src))
	if not s.has("id"): s["id"] = String(src)
	return s

func paint_of(src: Variant, s: Dictionary) -> Color:
	if src is Dictionary: return Color("e8e8e8")
	if String(src) == "charjer": return Color("1e1e24")
	return Color(String(s.get("paint", "#c8342c")))

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	var mode := a[1] if a.size() > 1 else "all"
	if a.size() > 2: only = a[2]
	DirAccess.make_dir_recursive_absolute(out)
	_run(mode)

func _run(mode: String) -> void:
	if mode in ["side", "all"]: _side()
	if mode in ["stance", "all"]: await _stance()
	if mode in ["top", "all"]: await _top()
	if mode in ["steer", "all"]: await _steer()
	if mode in ["dmg", "all"]: await _dmg()
	if mode in ["garage", "all"]: await _garage()
	if mode in ["lit", "all"]: await _lit()
	print("done")
	quit()

# ------------------------------------------------------------------ side

func _side() -> void:
	var cars := roster()
	var cols := 3
	var cw := 560
	var ch := 200
	var rows := int(ceil(cars.size() / float(cols)))
	var img := Image.create(cols * cw, rows * ch, false, Image.FORMAT_RGBA8)
	img.fill(Color("8a9aa8"))
	for i in cars.size():
		var c: Array = cars[i]
		var s := spec_of(c[1])
		var L := float(s.get("length", 4.5))
		var len := int(minf(PixCars.length_px(L), 500.0))
		var shot := PixCars.image_of(s, len, paint_of(c[1], s), c[2])
		var at := Vector2i((i % cols) * cw + 8, (i / cols) * ch + ch - 14 - shot.get_height())
		img.blend_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), at)
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out + "/side.png")
	# each one on its own, big
	for c: Array in cars:
		var s := spec_of(c[1])
		var L := float(s.get("length", 4.5))
		var shot := PixCars.image_of(s, int(minf(PixCars.length_px(L), 460.0)), paint_of(c[1], s), c[2])
		var bg := Image.create(shot.get_width(), shot.get_height(), false, Image.FORMAT_RGBA8)
		bg.fill(Color("8a9aa8"))
		bg.blend_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i.ZERO)
		bg.resize(bg.get_width() * 3, bg.get_height() * 3, Image.INTERPOLATE_NEAREST)
		bg.save_png("%s/side_%s.png" % [out, c[0]])

# ------------------------------------------------------------------ top-down

func _scene() -> void:
	if root2 != null: root2.free()
	root2 = Node2D.new()
	get_root().add_child(root2)
	var bg := ColorRect.new()
	bg.color = Color("5c6266")
	bg.size = Vector2(20000, 20000)
	bg.position = Vector2(-10000, -10000)
	bg.z_index = -10
	root2.add_child(bg)
	cam = Camera2D.new()
	root2.add_child(cam)
	cam.enabled = true

func _view(s: Dictionary, paint: Color, mods: Dictionary, h: float, at: Vector2, dmg: Variant = 0.0) -> CarView:
	var v := CarView.new()
	v.art = CarArt.new(s, paint, dmg, 3, CarArt.CAR_SCALE, mods)
	v.heading = h
	v.position = at
	root2.add_child(v)
	if mods.get("police", false):
		var bar := AiCar.LightBar.new()
		bar.heading = h
		bar.width = float(s.get("width", 1.8))
		bar.roof = v.roof_px()
		bar.along = v.art.roof_mid.x
		bar.half_px = v.art.roof_w * 0.5
		bar.position = at
		bar.z_index = 1
		root2.add_child(bar)
	return v

func _shoot(name: String) -> void:
	for f in 6: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/%s.png" % [out, name])

## Six headings in a 3 x 2 grid at the game's zoom (or less, for the long ones).
func _top() -> void:
	for ang: String in ["overhead", "angled", "low"]:
		CarView.set_angle(ang)
		for c: Array in roster():
			_scene()
			var s := spec_of(c[1])
			var L := float(s.get("length", 4.5)) * CarArt.PX * CarArt.CAR_SCALE
			var gap := maxf(L, 40.0) + 14.0
			var gy := gap + 34.0 * CarView.lift_k / CarView.squash
			var z := minf(ZOOM, 620.0 / (3.0 * gap))
			z = minf(z, 350.0 / (2.0 * gy * CarView.squash))
			cam.zoom = Vector2(z, z * CarView.squash)
			for i in HEADS.size():
				var at := Vector2((i % 3 - 1) * gap, (i / 3 - 0.5) * gy)
				_view(s, paint_of(c[1], s), c[2], deg_to_rad(HEADS[i]), at)
			await _shoot("top_%s_%s" % [c[0], ang])
	CarView.set_angle("angled")

## The stanced Silvio: every drop and fitment, side by side and from above.
func _stance() -> void:
	var s := spec_of("silvio")
	var fits := ["stock", "flush", "poke", "tucked", "stance", "stretch"]
	var drops := [0.0, 0.5, 1.0]
	var cw := 300
	var ch := 120
	var img := Image.create(fits.size() * cw, drops.size() * 2 * ch, false, Image.FORMAT_RGBA8)
	img.fill(Color("8a9aa8"))
	for j in drops.size():
		for i in fits.size():
			for k in 2:
				var m := { "offset": fits[i], "drop": drops[j], "rim": "deepdish" if k == 0 else "fivespoke", "lip_depth": 1.0 if k == 0 else 0.4 }
				var shot := PixCars.image_of(s, 260, Color("c8342c"), m)
				img.blend_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(i * cw, (j * 2 + k) * ch + ch - 6 - shot.get_height()))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out + "/stance_side.png")
	var big := PixCars.image_of(s, 300, Color("c8342c"), { "offset": "stance", "drop": 1.0, "rim": "deepdish", "lip_depth": 1.0 })
	big.resize(big.get_width() * 4, big.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(out + "/stance_big.png")
	for ang: String in ["overhead", "angled", "low"]:
		CarView.set_angle(ang)
		for j in 2:
			_scene()
			cam.zoom = Vector2(2.0, 2.0 * CarView.squash)
			for i in fits.size():
				var m := { "offset": fits[i], "drop": 1.0 if j == 0 else 0.5, "rim": "deepdish", "lip_depth": 1.0 }
				_view(s, Color("c8342c"), m, deg_to_rad([20.0, 160.0][j]), Vector2((i % 3 - 1) * 100.0, (i / 3 - 0.5) * 80.0 / CarView.squash))
			await _shoot("stance_top_%s_%d" % [ang, j])
	CarView.set_angle("angled")

## The front wheels at every heading and steer, big.
func _steer() -> void:
	var s := spec_of(String(only) if only != "" and CarCatalog.has(only) else "silvio")
	for ang: String in ["overhead", "low"]:
		CarView.set_angle(ang)
		_scene()
		cam.zoom = Vector2(1.0, 1.0 * CarView.squash)
		var steers := [-0.6, -0.3, 0.0, 0.3, 0.6]
		var heads := [0.0, 45.0, 90.0, 135.0, 180.0, 270.0]
		for i in heads.size():
			for j in steers.size():
				var v := _view(s, Color("c8342c"), { "rim": "fivespoke" }, deg_to_rad(heads[i]), Vector2((j - 2) * 120, (i - 2.5) * 56))
				v.steer = steers[j]
				v._steer_vis = steers[j]
		await _shoot("steer_%s" % ang)
	CarView.set_angle("angled")

## Crashed and worn: front, rear, side hits; lost bumpers, broken lamps; dirt, rust, decals.
func _dmg() -> void:
	var cars := ["silvio", "fjord_crown_victorious_2005", "fjord_f_one_fiddy_2015", "ambulance"]
	var dmgs := [{ "front": 0.9, "left": 0.6 }, { "rear": 0.9, "right": 0.7 }, { "left": 0.9, "right": 0.9 }, 0.0]
	var wear := { "wear": { "dirt": 0.5, "rust": 0.6, "dents": 0.6, "primer": "hood" }, "decal": 2, "sign": "taxi" }
	for ang: String in ["overhead", "low"]:
		CarView.set_angle(ang)
		_scene()
		cam.zoom = Vector2(0.85, 0.85 * CarView.squash)
		for i in cars.size():
			var s := spec_of(cars[i])
			for j in dmgs.size():
				var m: Dictionary = wear if j == 3 else {}
				_view(s, paint_of(cars[i], s), m, deg_to_rad([30.0, 150.0, 300.0, 210.0][j]), Vector2((j - 1.5) * 150, (i - 1.5) * 100))
		await _shoot("dmg_%s" % ang)
	# and the side view
	var img := Image.create(4 * 380, 4 * 150, false, Image.FORMAT_RGBA8)
	img.fill(Color("8a9aa8"))
	var sides := [{ "front": 0.9, "glass": 1.0, "lights": 1.0, "bumper": 1.0 }, { "rear": 0.9, "roof": 0.6 }, { "flat": 1, "wheel_off": 2 }, {}]
	for i in cars.size():
		var s := spec_of(cars[i])
		for j in sides.size():
			var m: Dictionary = { "rust": 0.6 } if j == 3 else {}
			var shot := PixCars.image_of(s, int(minf(PixCars.length_px(float(s.get("length", 4.5))) * 0.8, 340.0)), paint_of(cars[i], s), m, sides[j])
			img.blend_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(j * 380, i * 150 + 144 - shot.get_height()))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out + "/dmg_side.png")
	CarView.set_angle("angled")

## The garage's preview: the stack painted straight onto a canvas.
func _garage() -> void:
	_scene()
	cam.zoom = Vector2(1.0, 1.0)
	var cv := GarageCanvas.new()
	cv.cars = []
	var opts := [{}, { "rim": "deepdish", "offset": "stance", "drop": 1.0 }, { "spoiler": "gt", "kit": { "lip": true, "skirts": true, "diffuser": true } },
		{ "drop": -1.0, "tire": "mud", "rollbar": true, "lightbar": true, "bash": true, "spare": true }, { "roof": "rack", "fenders": "flared", "hood": "vented" },
		{ "livery": "flames", "stripes": "racing", "underglow": "#30a0ff", "exhaust": "quad" }]
	for i in opts.size():
		var src: String = "silvio" if i != 3 else "fjord_f_one_fiddy_2015"
		var s := spec_of(src)
		cv.cars.append([CarArt.new(s, Color("c8342c"), 0.0, 1, CarArt.CAR_SCALE, opts[i]), Vector2((i % 3 - 1) * 110, (i / 3 - 0.5) * 80), deg_to_rad([0.0, 30.0, 150.0, 210.0, 270.0, 90.0][i])])
	root2.add_child(cv)
	await _shoot("garage")

class GarageCanvas extends Node2D:
	var cars: Array
	func _draw() -> void:
		for c: Array in cars: CarView.paint_stack(self, c[0], c[1], c[2])

## Every lamp lit, at night-ish, at the low angle, so a lamp off the body shows.
func _lit() -> void:
	for ang: String in ["overhead", "low"]:
		CarView.set_angle(ang)
		for c: Array in roster():
			_scene()
			var s := spec_of(c[1])
			var L := float(s.get("length", 4.5)) * CarArt.PX * CarArt.CAR_SCALE
			var gap := maxf(L, 40.0) + 14.0
			var gy := gap + 34.0 * CarView.lift_k / CarView.squash
			var z := minf(ZOOM, 620.0 / (3.0 * gap))
			z = minf(z, 350.0 / (2.0 * gy * CarView.squash))
			cam.zoom = Vector2(z, z * CarView.squash)
			CarView.night = 0.7
			for i in HEADS.size():
				var at := Vector2((i % 3 - 1) * gap, (i / 3 - 0.5) * gy)
				var v := _view(s, paint_of(c[1], s), c[2], deg_to_rad(HEADS[i]), at)
				v.headlights = true
				v.braking = i % 2 == 0
				v.reversing = i == 3
				v.blink_left = true
				v.beacons = true
			await _shoot("lit_%s_%s" % [c[0], ang])
	CarView.night = 0.0
	CarView.set_angle("angled")
