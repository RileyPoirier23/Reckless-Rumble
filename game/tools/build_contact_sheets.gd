## Review sheets of the showroom sprites, drawn from the exported files (so they show what's in
## art/vehicles/showroom, an artist's file or the painter's), never from the painter itself:
## one set by era (1950s .. 2010s) and one by class, 24 cars a sheet on a dark field, the id,
## year, make and model and the class and archetype under each car. The labels live only here,
## never in the sprites. A faint line one row under each canvas's baseline shows floating or
## sunk wheels, and a lighter box marks the 224x76 footprint.
##   godot --headless --path game -s tools/build_contact_sheets.gd -- [out_dir] [showroom_dir]
## out_dir defaults to res://art/vehicles/contact_sheets, showroom_dir to res://art/vehicles/showroom.
extends SceneTree

const COLS := 4
const PER := 24
const CW := 256
const CH := 96
const LABEL_H := 26
const GAP := 4
const HEAD := 16
const FIELD := Color("1d2025")
const CANVAS := Color("2a2e35")
const FOOT := Color("343943")
const GROUND := Color("4a515c")
const TEXT := Color("ece6da")
const DIM := Color("9aa3ae")
const WARN := Color("e0a040")
const ERAS := [1950, 1960, 1970, 1980, 1990, 2000, 2010]

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "res://art/vehicles/contact_sheets"
	var src: String = a[1] if a.size() > 1 else "res://art/vehicles/showroom"
	if out.begins_with("res://") or out.begins_with("user://"): out = ProjectSettings.globalize_path(out)
	if src.begins_with("res://") or src.begins_with("user://"): src = ProjectSettings.globalize_path(src)
	DirAccess.make_dir_recursive_absolute(out)
	for f in DirAccess.get_files_at(out):
		if f.ends_with(".png") and (f.begins_with("era_") or f.begins_with("class_")): DirAccess.remove_absolute(out.path_join(f))
	var cars: Array = []
	var missing: Array = []
	for pair: Array in load("res://tools/export_showroom.gd").cars():
		var path := src.path_join(String(pair[0]) + ".png")
		if not FileAccess.file_exists(path):
			missing.append(pair[0])
			continue
		cars.append(_card(pair, path))
	var by_era := {}
	for c: Dictionary in cars:
		var era: int = clampi(int(c.year) / 10 * 10, ERAS[0], ERAS[ERAS.size() - 1])
		if not by_era.has(era): by_era[era] = []
		by_era[era].append(c)
	var sheets := 0
	for era in ERAS:
		if by_era.has(era): sheets += _sheets(out, "era_%ds" % era, "%dS" % era, _by_year(by_era[era]))
	var by_cls := {}
	for c: Dictionary in cars:
		if not by_cls.has(c.cls): by_cls[c.cls] = []
		by_cls[c.cls].append(c)
	var order: Array = CarCatalog.CLASSES.duplicate()
	for k in by_cls:
		if not k in order: order.append(k)
	for k in order:
		if by_cls.has(k): sheets += _sheets(out, "class_%s" % k, String(k).to_upper().replace("_", " "), _by_year(by_cls[k]))
	print("%d cars on %d sheets -> %s" % [cars.size(), sheets, out])
	if not missing.is_empty(): print("no showroom file for %d: %s" % [missing.size(), ", ".join(missing.slice(0, 12))])
	quit()

## What a sheet shows of one car.
func _card(pair: Array, path: String) -> Dictionary:
	var s: Dictionary = pair[1]
	var e := CarCatalog.entry(String(pair[2]))
	var cls := String(e.get("class", "fleet" if String(s.get("body", "")) in ["boxtruck", "bus", "semi"] else String(s.get("body", ""))))
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	return {
		"id": String(pair[0]), "img": img, "year": int(s.get("year", 0)), "cls": cls,
		"line": "%d %s %s" % [int(s.get("year", 0)), String(s.get("make", "")), String(s.get("model", ""))],
		"kind": "%s / %s / %s" % [cls, String(e.get("body", s.get("body", ""))), archetype(e if not e.is_empty() else s, cls)],
	}

func _by_year(a: Array) -> Array:
	var b := a.duplicate()
	b.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.year < y.year or (x.year == y.year and String(x.id) < String(y.id)))
	return b

func _sheets(out: String, stem: String, title: String, cars: Array) -> int:
	var n := int(ceil(cars.size() / float(PER)))
	for i in n:
		var batch := cars.slice(i * PER, (i + 1) * PER)
		var rows := int(ceil(batch.size() / float(COLS)))
		var w := COLS * (CW + GAP) + GAP
		var h := HEAD + rows * (CH + LABEL_H + GAP) + GAP
		var p := Pix.new(w, h, 1)
		p.rect(0, 0, w, h, FIELD)
		p.text(GAP, 5, "%s   SHEET %d OF %d   %d CARS" % [title, i + 1, n, cars.size()], TEXT)
		for j in batch.size():
			var c: Dictionary = batch[j]
			var x := GAP + (j % COLS) * (CW + GAP)
			var y := HEAD + (j / COLS) * (CH + LABEL_H + GAP)
			p.rect(x, y, CW, CH, CANVAS)
			p.rect(x + 16, y + 3, 224, 76, FOOT)
			p.hline(x, y + 79, CW, GROUND)
			var img: Image = c.img
			if img.get_size() == Vector2i(CW, CH): p.stamp(img, x, y)
			else: p.text(x + 4, y + 4, "CANVAS %dX%d" % [img.get_width(), img.get_height()], WARN)
			p.text(x + 2, y + CH + 2, String(c.id).to_upper(), TEXT)
			p.text(x + 2, y + CH + 10, String(c.line).to_upper().substr(0, 62), DIM)
			p.text(x + 2, y + CH + 18, String(c.kind).to_upper().replace("_", " ").substr(0, 62), DIM)
		var name := "%s_%02d.png" % [stem, i + 1]
		p.img.save_png(out.path_join(name))
	return n

## The DEV ADDITIONS geometry archetype a car would most likely take, from its body, class,
## size and engine position: a review hint for the sheets, not a manifest.
static func archetype(e: Dictionary, cls: String) -> String:
	var body := String(e.get("body", "sedan"))
	var L := float(e.get("length", 4.5))
	var eng: Dictionary = e.get("engine", {})
	var tokens: Array = e.get("tokens", [])
	match body:
		"kei", "bubble", "trike": return "micro_fwd"
		"hatch": return "micro_fwd" if L < 3.5 else ("compact_fwd" if L < 3.95 else "hatch_fwd")
		"sedan": return "sedan_compact" if L < 4.5 else ("sedan_midsize" if L < 5.0 else "sedan_fullsize")
		"coupe": return "coupe_compact" if L < 4.4 else "coupe_gt"
		"muscle": return "muscle_longhood"
		"sports", "roadster": return "sports_midengine" if String(eng.get("position", "front")) in ["mid", "rear"] else "sports_frontengine"
		"wedge": return "exotic_wedge"
		"wagon": return "wagon_compact" if L < 4.6 else "wagon_fullsize"
		"suv": return "crossover_compact" if cls == "crossover" else ("suv_midsize" if L < 4.9 else "suv_fullsize")
		"offroad": return "offroad_short"
		"pickup":
			if cls in ["hd_pickup", "work_truck"] or tokens.has("dually"): return "pickup_heavy"
			return "pickup_compact" if L < 5.0 else "pickup_half_ton"
		"tow": return "utility_tow"
		"minivan": return "minivan"
		"van": return "van_cargo" if cls in ["van", "work_truck"] else "van_passenger"
	return "fleet_" + body
