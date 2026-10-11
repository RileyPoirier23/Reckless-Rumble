## The camera round a car: one car, 16 camera headings (two rows of eight) for each of the three
## tilts (overhead, angled, low, top to bottom), the way the
## game's camera turns and squashes (Camera2D rotation, zoom.y * squash, CarView.screen_up):
## godot --path game --rendering-driver opengl3 -s tests/orbit_sheet.gd -- <out_dir> [car ...]
## car: coupe, pickup, van, stance, ambulance, police, semi, moving (a coupe leaning into a
## turn with its wheels steered), or a catalogue id.
extends SceneTree

const N := 16
const CELL := Vector2i(220, 180)
const ZOOM := 2.6

var root2: Node2D
var cam: Camera2D

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://orbit"
	DirAccess.make_dir_recursive_absolute(out)
	var cars: Array = a.slice(1) if a.size() > 1 else ["coupe", "pickup", "van", "stance", "ambulance", "moving"]
	_run(out, cars)

func _run(out: String, cars: Array) -> void:
	for f in 2: await process_frame
	for which: String in cars:
		var sheet := Image.create(CELL.x * N / 2, CELL.y * 6, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("5c6266"))
		var tilts := ["overhead", "angled", "low"]
		for t in tilts.size():
			CarView.set_angle(tilts[t])
			for k in N:
				var rot := TAU * float(k) / float(N)
				_scene(which, rot)
				for f in 3: await process_frame
				await RenderingServer.frame_post_draw
				var img := get_root().get_texture().get_image()
				var c := img.get_size() / 2
				sheet.blit_rect(img, Rect2i(c - CELL / 2, CELL), Vector2i((k % (N / 2)) * CELL.x, (t * 2 + k / (N / 2)) * CELL.y))
		sheet.save_png("%s/orbit_%s.png" % [out, which])
		print("saved ", which)
	CarView.set_angle("angled")
	CarView.screen_up = Vector2(0, -1)
	quit()

## One car at the origin heading east, and the camera turned `rot` round it, as drive.gd does.
func _scene(which: String, rot: float) -> void:
	if root2 != null: root2.free()
	root2 = Node2D.new()
	get_root().add_child(root2)
	var bg := ColorRect.new()
	bg.color = Color("5c6266")
	bg.size = Vector2(4000, 4000)
	bg.position = Vector2(-2000, -2000)
	bg.z_index = -10
	root2.add_child(bg)
	# a road line under it, so the ground's squash shows
	var line := ColorRect.new()
	line.color = Color("d8d0a0")
	line.size = Vector2(400, 1)
	line.position = Vector2(-200, 24)
	line.z_index = -5
	root2.add_child(line)
	cam = Camera2D.new()
	cam.ignore_rotation = false
	cam.rotation = rot
	cam.zoom = Vector2(ZOOM / 2.0, ZOOM / 2.0 * CarView.squash)
	root2.add_child(cam)
	CarView.screen_up = Vector2(0, -1).rotated(rot)
	var id := "silvio"
	var mods := {}
	var paint := Color("c8342c")
	match which:
		"coupe": pass
		"pickup":
			id = "fjord_f_one_fiddy_2015"
			paint = Color("2c4a8a")
		"van": id = "fjord_econolean_1995"
		"stance": mods = { "offset": "stance", "drop": 1.0, "rim": "deepdish", "lip_depth": 1.0, "spoiler": "gt", "kit": { "lip": true, "skirts": true } }
		"ambulance":
			id = "fjord_e_fiddy_ambulanz_2014"
			paint = Color("f2f2ee")
		"police": id = "charjer"
		"semi": id = "kenwerth_tee_six_eighty_ate_2016"
		"moving": pass
		_: id = which
	var spec := CarCatalog.spec(id)
	var v := CarView.new()
	v.art = CarArt.new(spec, paint, 0.0, 3, CarArt.CAR_SCALE, mods)
	v.heading = 0.0
	if which == "moving":
		v.steer = 0.45
		v._steer_vis = 0.45
		v.lean = Vector2(0.6, 1.4)
		v.braking = true
		v.headlights = true
	root2.add_child(v)
	# the camera's centre on the car's middle, a little up the stack
	cam.position = CarView.screen_up * v.art.roof_z * 0.4
