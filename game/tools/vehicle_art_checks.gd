## The vehicle art validation gates (DEV ADDITIONS.md, "Validation Gates") as plain functions, so
## the validator (tools/validate_vehicle_art.gd) runs them over every car and the tests
## (tests/vehicle_art_tests.gd) can run them on pictures they make up. Each returns a list of
## problems, empty when the thing passes.
class_name VehicleArtChecks
extends RefCounted

const DIM_TOL := 0.011             # m: a manifest's sizes against the spec's (they're copied, so rounding only)
const PX_TOL := 1.0                # px at 12 px/m: the art's own length against the spec's
const AXLE_TOL := 1.5 / 12.0       # m: the axles' spacing against the wheelbase (a pixel and a half)
const MEASURE_TOL := 0.002         # m: an anchor against the same anchor measured again
const BASELINE_TOL := 1            # px: a round tyre may stop one row above the ground line
const WHEEL_RATIO_TOL := 0.07      # showroom: the wheels' spacing over the car's length, against the manifest's

## Cars whose art puts the wheels somewhere the sim's wheelbase doesn't: known, and waiting on a
## fix in the painter or the table (not in the manifest, which says where the wheels are drawn).
## The validator lists these instead of failing them; take a line out once the car is fixed.
const WHEELBASE_EXCEPTIONS := {
	"minni_cupper_1965": "CarGen's hand-drawn icon puts the wheels at the corners (wr 0.08, wf 0.92, about 2.56 m apart); the table says 2.04 m",
	"peeled_pee_fifty_1963": "a tyre can't sit closer than its own radius to the ends of a 1.37 m car, so the art's axles are under 1 m apart; the table says 1.27 m",
}

const REQUIRED := {
	"display": ["make", "model", "trim", "year"],
	"classification": ["class", "body", "era", "archetype"],
	"dimensions_m": ["length", "width", "wheelbase"],
	"art": ["showroom", "runtime_dir", "slice_count", "front_axis", "pixels_per_metre"],
	"anchors": ["front_axle_m", "rear_axle_m", "front_bumper_m", "rear_bumper_m", "roof_z_slice", "exhaust_side"],
	"review": ["reference_notes", "artist", "reviewer", "approved"],
}
const EXHAUST_SIDES := ["rear_right", "rear_left", "rear_both", "side_both", "hidden"]

## A manifest against its car. `art` is the car drawn from above at 12 px/m (CarArt, scale 1),
## passed in so a caller drawing it anyway doesn't draw it twice.
static func manifest(m: Dictionary, file_name: String, spec: Dictionary, art: CarArt = null) -> Array:
	var out: Array = []
	if int(m.get("schema_version", 0)) != VehicleManifest.SCHEMA_VERSION: out.append("schema_version is not %d" % VehicleManifest.SCHEMA_VERSION)
	for k: String in ["vehicle_id", "car_id", "slots", "masks"]:
		if not m.has(k): out.append("no %s" % k)
	for sec: String in REQUIRED:
		if not m.get(sec) is Dictionary:
			out.append("no %s" % sec)
			continue
		for k2: String in REQUIRED[sec]:
			if not (m[sec] as Dictionary).has(k2): out.append("no %s.%s" % [sec, k2])
	if not out.is_empty(): return out
	var vid := String(m.vehicle_id)
	if file_name != vid + ".json": out.append("file %s holds vehicle %s" % [file_name, vid])
	if CarCatalog.slug(vid) != vid: out.append("vehicle id %s is not snake_case" % vid)
	if spec.is_empty():
		out.append("car %s has no spec" % m.car_id)
		return out
	if PixCars.art_id(spec) != vid: out.append("vehicle id %s, but the car's art id is %s" % [vid, PixCars.art_id(spec)])
	# who it is
	var disp: Dictionary = m.display
	if String(disp.make) != String(spec.get("make", "")) or String(disp.model) != String(spec.get("model", "")) or int(disp.year) != int(spec.get("year", 0)):
		out.append("display %s %s %d is not the car's" % [disp.make, disp.model, int(disp.year)])
	if int(disp.year) > VehicleManifest.MAX_YEAR: out.append("model year %d is past %d" % [int(disp.year), VehicleManifest.MAX_YEAR])
	var c: Dictionary = m.classification
	if not VehicleArchetypes.is_valid(String(c.archetype)): out.append("archetype %s is not one of the 25" % c.archetype)
	elif String(c.archetype) != VehicleArchetypes.of(spec): out.append("archetype %s, the table says %s" % [c.archetype, VehicleArchetypes.of(spec)])
	if String(c.era) != VehicleArchetypes.era(int(disp.year)): out.append("era %s for a %d car" % [c.era, int(disp.year)])
	if String(c.body) != String(spec.get("body", "")): out.append("body %s, the car's is %s" % [c.body, spec.get("body", "")])
	# how big
	var dm: Dictionary = m.dimensions_m
	for k3: String in ["length", "width", "wheelbase"]:
		if absf(float(dm[k3]) - float(spec.get(k3, 0.0))) > DIM_TOL:
			out.append("%s %.3f m, the spec says %.3f m" % [k3, float(dm[k3]), float(spec.get(k3, 0.0))])
	# where the art goes
	var a: Dictionary = m.art
	if String(a.showroom) != VehicleManifest.SHOWROOM_DIR + vid + ".png": out.append("showroom path %s" % a.showroom)
	if String(a.runtime_dir) != VehicleManifest.RUNTIME_DIR + vid: out.append("runtime dir %s" % a.runtime_dir)
	if int(a.slice_count) != VehicleManifest.SLICES: out.append("slice_count %d, not %d" % [int(a.slice_count), VehicleManifest.SLICES])
	if String(a.front_axis) != "+x": out.append("front axis %s, not +x" % a.front_axis)
	if int(a.pixels_per_metre) != VehicleManifest.PPM: out.append("%d px/m, not %d" % [int(a.pixels_per_metre), VehicleManifest.PPM])
	# the anchors: in order along the car, the axles a wheelbase apart, and where the car really has them
	var an: Dictionary = m.anchors
	var fa := float(an.front_axle_m)
	var ra := float(an.rear_axle_m)
	var fb := float(an.front_bumper_m)
	var rb := float(an.rear_bumper_m)
	if not (fb >= fa and fa > ra and ra >= rb): out.append("anchors out of order: bumper %.3f, axle %.3f, axle %.3f, bumper %.3f" % [fb, fa, ra, rb])
	var wb := float(spec.get("wheelbase", 0.0))
	if absf((fa - ra) - wb) > AXLE_TOL and not (spec.get("art", {}) as Dictionary).has("tractor") and not WHEELBASE_EXCEPTIONS.has(vid):
		out.append("axles %.3f m apart, the wheelbase is %.3f m" % [fa - ra, wb])
	if absf((fb - rb) - float(spec.get("length", 0.0))) > PX_TOL / VehicleManifest.PPM + 0.001:
		out.append("bumpers %.3f m apart, the car is %.3f m long" % [fb - rb, float(spec.get("length", 0.0))])
	if not String(an.exhaust_side) in EXHAUST_SIDES: out.append("exhaust side %s" % an.exhaust_side)
	if art != null:
		var meas := VehicleManifest.anchors(spec, art)
		for k4: String in ["front_axle_m", "rear_axle_m", "front_bumper_m", "rear_bumper_m"]:
			if absf(float(an[k4]) - float(meas[k4])) > MEASURE_TOL: out.append("%s %.3f, the art puts it at %.3f" % [k4, float(an[k4]), float(meas[k4])])
		if str(an.get("rear_axles_m", [])) != str(meas.rear_axles_m): out.append("rear_axles_m %s, the art's are %s" % [str(an.get("rear_axles_m", [])), str(meas.rear_axles_m)])
		if int(an.roof_z_slice) != int(meas.roof_z_slice): out.append("roof_z_slice %d, the art's roof is at %d" % [int(an.roof_z_slice), int(meas.roof_z_slice)])
		if String(an.exhaust_side) != String(meas.exhaust_side): out.append("exhaust %s, the art's comes out %s" % [an.exhaust_side, meas.exhaust_side])
		out.append_array(wheels_under_anchors(spec, art, an))
	# the slots: only what the body shop sells and the code draws on this car
	var vocab := VehicleManifest.vocabulary()
	var slots: Dictionary = m.slots
	for s: String in slots:
		if not vocab.has(s):
			out.append("slot %s isn't one the code knows" % s)
			continue
		var vals: Array = slots[s]
		if vals.is_empty() or vals[0] != vocab[s][0]: out.append("slot %s doesn't start with %s" % [s, vocab[s][0]])
		var seen := {}
		for v: Variant in vals:
			if not v is String or not (vocab[s] as Array).has(v):
				out.append("slot %s has %s, which the code can't draw" % [s, str(v)])
				continue
			if seen.has(v): out.append("slot %s lists %s twice" % [s, v])
			seen[v] = true
			if not VehicleManifest.fits(spec, s, String(v)): out.append("slot %s has %s, which the garage won't fit on this car" % [s, v])
	for s2: String in vocab:
		if not slots.has(s2): out.append("no slot %s" % s2)
	if m.masks != VehicleManifest.MASKS: out.append("masks %s, not %s" % [str(m.masks), str(VehicleManifest.MASKS)])
	var rv: Dictionary = m.review
	var note := String(rv.reference_notes)
	if note.strip_edges() == "" or note.contains("\n"): out.append("reference_notes must be one line")
	if not rv.approved is bool: out.append("approved isn't true or false")
	elif bool(rv.approved) and (String(rv.artist) == "" or String(rv.reviewer) == ""): out.append("approved with no artist or reviewer")
	return out

## The axle anchors over the wheels the car is drawn with: from above, the back tyres' pixels
## are there in the bottom slices at the back axle and the front wheels (their own stack, to
## steer) are centred on the front axle; side on, CarGen's wheels sit at the same spots.
static func wheels_under_anchors(spec: Dictionary, art: CarArt, an: Dictionary) -> Array:
	var out: Array = []
	var ppm := art.px
	var img := art.atlas.get_image()
	var cx := art.size.x / 2.0
	var cy := art.size.y / 2.0
	var half_track := float(an.get("track_m", 0.0)) * ppm / 2.0
	# a semi tractor's anchor is the middle of its tandem: look for the tyres on both its axles
	var tractor := (spec.get("art", {}) as Dictionary).has("tractor")
	var axles: Array = [float(an.rear_axle_m) * ppm]
	if tractor:
		axles = []
		for w: Array in art.wheel_rears:
			var wx := snappedf((w[0] as Vector2).x, 0.01)
			if not axles.has(wx): axles.append(wx)
	for ax: float in axles:
		var xr := int(floor(cx + ax))
		for side: float in [-1.0, 1.0]:
			var yr := int(floor(cy + side * half_track))
			var hit := false
			for z in mini(3, art.n):
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var x: int = z * art.size.x + clampi(xr + dx, 0, art.size.x - 1)
						var y: int = clampi(yr + dy, 0, art.size.y - 1)
						if img.get_pixel(x, y).a > 0.5: hit = true
			if not hit: out.append("no back tyre under the axle at %.3f m (%s side)" % [ax / ppm, "left" if side < 0.0 else "right"])
	if art.wheel_tex == null or art.wheel_tex.get_image().get_used_rect().size.x == 0: out.append("no front wheel stack")
	for v: Vector2 in art.wheel_spots:
		if absf(v.x / ppm - float(an.front_axle_m)) > MEASURE_TOL: out.append("a front wheel at %.3f m, the anchor says %.3f m" % [v.x / ppm, float(an.front_axle_m)])
	# side on: CarGen's wheel spots, in metres from the middle of the car
	var d := CarGen.design(spec)
	var L := float(spec.get("length", d.L))
	var len := 400
	var spots := CarGen.wheel_spots(len, d)
	var side_r := ((float(spots[0][0]) - 22.0) / len - 0.5) * L
	var side_f := ((float(spots[1][0]) - 22.0) / len - 0.5) * L
	if absf(side_f - float(an.front_axle_m)) > AXLE_TOL: out.append("side view's front wheel at %.3f m, the anchor says %.3f m" % [side_f, float(an.front_axle_m)])
	if not tractor and absf(side_r - float(an.rear_axle_m)) > AXLE_TOL: out.append("side view's back wheel at %.3f m, the anchor says %.3f m" % [side_r, float(an.rear_axle_m)])
	return out

## A showroom sprite: 256x96 RGBA, hard edges, the car inside the 224x76 footprint with clear
## padding round it, its tyres on the ground line at y=78 and spaced like the manifest's axles.
static func showroom(img: Image, m: Dictionary) -> Array:
	var out: Array = []
	var sz := VehicleManifest.SHOWROOM_SIZE
	if img.get_size() != sz: out.append("showroom is %dx%d, not %dx%d" % [img.get_width(), img.get_height(), sz.x, sz.y])
	if img.get_format() != Image.FORMAT_RGBA8: out.append("showroom isn't RGBA (format %d)" % img.get_format())
	if not out.is_empty(): return out
	var whitelist: Array = (m.get("art", {}) as Dictionary).get("alpha_whitelist", [])
	if not whitelist.has("showroom"):
		var partial := partial_alpha(img)
		if partial > 0: out.append("showroom has %d partly transparent pixels (blur or antialiasing)" % partial)
	var used := img.get_used_rect()
	if used.size.x == 0:
		out.append("showroom is empty")
		return out
	var fp := VehicleManifest.SHOWROOM_FOOTPRINT
	if used.size.x > fp.x or used.size.y > fp.y: out.append("showroom footprint %dx%d is past %dx%d" % [used.size.x, used.size.y, fp.x, fp.y])
	if used.position.x < 1 or used.position.y < 1 or used.end.x > sz.x - 1: out.append("showroom car touches the edge of the canvas (no clear padding)")
	var low := used.end.y - 1
	var base := VehicleManifest.SHOWROOM_BASELINE
	if low > base or low < base - BASELINE_TOL: out.append("showroom's lowest pixels on row %d, the ground is row %d" % [low, base])
	# the wheels: the runs of pixels along the bottom rows. Mud flaps and plow blades touch the
	# ground too, so it's enough that two of the runs are spaced like the axles (as a share of
	# the car's length)
	var runs := _bottom_runs(img, low)
	if runs.size() < 2:
		out.append("showroom shows %d wheel(s) on the ground, not two" % runs.size())
		return out
	var an: Dictionary = m.get("anchors", {})
	var span := float(an.get("front_bumper_m", 0.0)) - float(an.get("rear_bumper_m", 0.0))
	if span > 0.0:
		# (a tractor's front wheels against either of its back axles)
		var wants: Array = []
		for r: Variant in an.get("rear_axles_m", [an.rear_axle_m]): wants.append((float(an.front_axle_m) - float(r)) / span)
		var best := 9.0
		var want := float(wants[0])
		for i in runs.size():
			for j in range(i + 1, runs.size()):
				var got := (float(runs[j]) - float(runs[i])) / float(used.size.x)
				for w: float in wants:
					if absf(got - w) < absf(best - want):
						best = got
						want = w
		if absf(best - want) > WHEEL_RATIO_TOL:
			out.append("showroom wheels %.2f of the length apart, the axles %.2f" % [best, want])
	return out

## Where the tyres touch: the middles of the runs of solid pixels on the bottom two rows.
static func _bottom_runs(img: Image, low: int) -> Array:
	var cols := PackedByteArray()
	cols.resize(img.get_width())
	for x in img.get_width():
		for y in [low, low - 1]:
			if y >= 0 and img.get_pixel(x, y).a > 0.5: cols[x] = 1
	var out: Array = []
	var start := -1
	for x in img.get_width() + 1:
		var on := x < img.get_width() and cols[x] == 1
		if on and start < 0: start = x
		elif not on and start >= 0:
			if x - start >= 2: out.append((start + x - 1) / 2.0)
			start = -1
	return out

## Pixels neither solid nor clear.
static func partial_alpha(img: Image) -> int:
	var n := 0
	var data := img.get_data()
	if img.get_format() != Image.FORMAT_RGBA8: return 0
	for i in range(3, data.size(), 4):
		if data[i] != 0 and data[i] != 255: n += 1
	return n

## Clear pixels that aren't clear black (they halo when the slices are filtered or tinted).
static func dirty_clear(img: Image) -> int:
	var n := 0
	var data := img.get_data()
	if img.get_format() != Image.FORMAT_RGBA8: return 0
	for i in range(0, data.size(), 4):
		if data[i + 3] == 0 and (data[i] != 0 or data[i + 1] != 0 or data[i + 2] != 0): n += 1
	return n

## A runtime folder: exactly body_00..body_15 on one canvas, RGBA, hard edges, clear black,
## big enough for the car at 12 px/m; the paint and lamp masks; the bumpers that come off.
static func runtime(dir: String, m: Dictionary) -> Array:
	var out: Array = []
	var files := Array(DirAccess.get_files_at(dir))
	var want: Array = []
	for z in VehicleManifest.SLICES: want.append("body_%02d.png" % z)
	for f: String in files:
		if f.begins_with("body_") and f.ends_with(".png") and not want.has(f): out.append("extra slice %s" % f)
	var whitelist: Array = (m.get("art", {}) as Dictionary).get("alpha_whitelist", [])
	var canvas := Vector2i(-1, -1)
	for f2: String in want:
		if not files.has(f2):
			out.append("missing %s" % f2)
			continue
		var img := load_png(dir.path_join(f2))
		if img == null:
			out.append("%s doesn't load" % f2)
			continue
		if canvas.x < 0: canvas = img.get_size()
		elif img.get_size() != canvas: out.append("%s is %dx%d, body_00 is %dx%d" % [f2, img.get_width(), img.get_height(), canvas.x, canvas.y])
		if img.get_format() != Image.FORMAT_RGBA8:
			out.append("%s isn't RGBA" % f2)
			continue
		if not whitelist.has(f2):
			var partial := partial_alpha(img)
			if partial > 0: out.append("%s has %d partly transparent pixels" % [f2, partial])
		var dirty := dirty_clear(img)
		if dirty > 0: out.append("%s has %d clear pixels that aren't clear black" % [f2, dirty])
	var dm: Dictionary = m.get("dimensions_m", {})
	if canvas.x > 0:
		var need := Vector2i(int(round(float(dm.get("length", 0.0)) * VehicleManifest.PPM)), int(round(float(dm.get("width", 0.0)) * VehicleManifest.PPM)))
		if canvas.x < need.x or canvas.y < need.y: out.append("canvas %dx%d is smaller than the car at %d px/m (%dx%d)" % [canvas.x, canvas.y, VehicleManifest.PPM, need.x, need.y])
	var masks := dir.path_join("masks")
	var mfiles := Array(DirAccess.get_files_at(masks)) if DirAccess.dir_exists_absolute(masks) else []
	for mk: String in m.get("masks", VehicleManifest.MASKS):
		if not _has_layer(mfiles, "mask_" + mk): out.append("no masks/mask_%s.png" % mk)
	for lk: String in m.get("light_masks", VehicleManifest.LIGHT_MASKS):
		if not _has_layer(mfiles, "light_" + lk): out.append("no masks/light_%s.png" % lk)
	var det := dir.path_join("detachable")
	var dfiles := Array(DirAccess.get_files_at(det)) if DirAccess.dir_exists_absolute(det) else []
	for end: String in ["front", "rear"]:
		var found := false
		for f3: String in dfiles:
			if f3.ends_with(".png") and f3.contains(end): found = true
		if not found: out.append("no detachable %s bumper" % end)
	return out

## A mask as one picture (mask_paint.png) or one per slice (mask_paint_00.png ...).
static func _has_layer(files: Array, stem: String) -> bool:
	return files.has(stem + ".png") or files.has(stem + "_00.png")

## A PNG straight off the disk (not the imported texture, so its own format shows).
static func load_png(path: String) -> Image:
	if not FileAccess.file_exists(path): return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return img
