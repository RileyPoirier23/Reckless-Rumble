## Contact sheets of the whole catalogue, for looking over by eye: every vehicle side on
## (headless), and from above at two headings (needs a window):
##   godot --headless --path game -s tests/catalog_sheet.gd -- <out_dir> side [only]
##   godot --path game --rendering-driver opengl3 -s tests/catalog_sheet.gd -- <out_dir> top [only]
## 48 to a sheet, labelled with the id, in catalogue order (hand-made first, then the table).
extends SceneTree

const COLS := 6
const PER := 48
var out := "user://catalog_sheets"
var root2: Node2D
var cam: Camera2D

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	var mode := a[1] if a.size() > 1 else "side"
	var only := a[2] if a.size() > 2 else ""
	DirAccess.make_dir_recursive_absolute(out)
	var ids: Array = CarCatalog.ids() + CarCatalog.fleet_ids()
	if only != "": ids = ids.filter(func(id: String) -> bool: return id.contains(only))
	if mode == "side":
		_side(ids)
		quit()
	else:
		_top(ids)

func _side(ids: Array) -> void:
	var cw := 230
	var ch := 96
	for sheet in int(ceil(ids.size() / float(PER))):
		var batch: Array = ids.slice(sheet * PER, (sheet + 1) * PER)
		var rows := int(ceil(batch.size() / float(COLS)))
		var p := Pix.new(COLS * cw, rows * ch, 1)
		p.rect(0, 0, COLS * cw, rows * ch, Color("7a8a98"))
		for i in batch.size():
			var id: String = batch[i]
			var s := CarCatalog.spec(id)
			var L := float(s.get("length", 4.5))
			var shot := PixCars.image_of(s, int(minf(PixCars.length_px(L) * 0.6, 200.0)), Color(String(s.get("paint", "#c8342c"))), {})
			var x := (i % COLS) * cw + 6
			var y := (i / COLS) * ch + ch - 12 - shot.get_height()
			p.stamp(shot, x, y)
			p.text(x, (i / COLS) * ch + ch - 9, id.substr(0, 34).to_upper(), Color("f0ece4"))
		p.img.save_png("%s/side_%02d.png" % [out, sheet])
		print("sheet side_%02d: %s .. %s" % [sheet, batch[0], batch[batch.size() - 1]])

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

func _top(ids: Array) -> void:
	CarView.set_angle("angled")
	# twelve to a sheet, two headings each, at the game's zoom (the window is 640 x 360 world px)
	var per := 12
	for sheet in int(ceil(ids.size() / float(per))):
		var batch: Array = ids.slice(sheet * per, (sheet + 1) * per)
		_scene()
		var cols := 4
		var cw := 160.0
		var ch := 112.0 / CarView.squash
		cam.zoom = Vector2(1.0, CarView.squash)
		for i in batch.size():
			var id: String = batch[i]
			var s := CarCatalog.spec(id)
			var paint := Color(String(s.get("paint", "#c8342c")))
			var at := Vector2((i % cols - 1.5) * cw, (i / cols - 1.0) * ch)
			for j in 2:
				var v := CarView.new()
				v.art = CarArt.new(s, paint, 0.0, 3, CarArt.CAR_SCALE, {})
				v.heading = deg_to_rad(35.0 if j == 0 else 200.0)
				v.position = at + Vector2((j - 0.5) * 76.0, -8.0 / CarView.squash)
				root2.add_child(v)
			var lbl := Label.new()
			lbl.text = id.substr(0, 26).to_upper()
			lbl.position = at + Vector2(-76, 30.0 / CarView.squash)
			lbl.scale = Vector2(0.5, 0.5 / CarView.squash)
			lbl.add_theme_font_size_override("font_size", 14)
			root2.add_child(lbl)
		for f in 8: await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/top_%02d.png" % [out, sheet])
		print("sheet top_%02d: %s .. %s" % [sheet, batch[0], batch[batch.size() - 1]])
	quit()
