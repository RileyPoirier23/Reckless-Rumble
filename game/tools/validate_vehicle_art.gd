## The vehicle art validator (DEV ADDITIONS.md, "Validation Gates"): every manifest in
## data/vehicle_art against its car, and, where they've been delivered, each car's showroom sprite
## (art/vehicles/showroom/<id>.png) and runtime slices (art/vehicles/runtime/<id>/). Art that
## isn't there yet is counted as not delivered, not failed, so this runs clean today and gets
## stricter car by car as the art lands. Prints a report; exits 1 on any failure.
##   godot --headless --path game -s tools/validate_vehicle_art.gd
##   godot --headless --path game -s tools/validate_vehicle_art.gd -- --verbose   (every problem, not the first few per car)
extends SceneTree

func _init() -> void:
	var verbose := OS.get_cmdline_user_args().has("--verbose")
	var t0 := Time.get_ticks_msec()
	var problems := {}                  # vehicle id (or file) -> [problem, ...]
	var cars := {}                      # vehicle id -> car id, for every car there should be a manifest for
	for car_id: String in VehicleManifest.car_ids():
		var spec := VehicleManifest.spec_of(car_id)
		if spec.is_empty():
			_fail(problems, car_id, "no spec")
			continue
		var vid := PixCars.art_id(spec)
		if cars.has(vid): _fail(problems, vid, "%s and %s share this vehicle id" % [cars[vid], car_id])
		cars[vid] = car_id
	var files := Array(DirAccess.get_files_at(VehicleManifest.DIR)) if DirAccess.dir_exists_absolute(VehicleManifest.DIR) else []
	var have := {}
	var checked := 0
	var showroom := { "delivered": 0, "missing": 0, "passed": 0 }
	var runtime := { "delivered": 0, "missing": 0, "passed": 0 }
	var approved := 0
	for f: String in files:
		if not f.ends_with(".json"): continue
		var vid := f.get_basename()
		have[vid] = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VehicleManifest.DIR + f))
		if not parsed is Dictionary:
			_fail(problems, vid, "manifest isn't a JSON object")
			continue
		var m: Dictionary = parsed
		if not cars.has(vid):
			_fail(problems, vid, "manifest for a car that isn't in the catalogue or data/cars")
			continue
		var car_id: String = cars[vid]
		if String(m.get("car_id", "")) != car_id: _fail(problems, vid, "car_id %s, the car is %s" % [m.get("car_id", ""), car_id])
		var spec := VehicleManifest.spec_of(car_id)
		var art := CarArt.new(spec, VehicleManifest.FACTORY, 0.0, 1, 1.0, {})
		for p: String in VehicleArtChecks.manifest(m, f, spec, art): _fail(problems, vid, p)
		checked += 1
		var art_ok := true
		# the showroom sprite
		var sp := VehicleManifest.SHOWROOM_DIR + vid + ".png"
		if FileAccess.file_exists(sp):
			showroom.delivered += 1
			var img := VehicleArtChecks.load_png(sp)
			var sp_problems: Array = ["showroom doesn't load"] if img == null else VehicleArtChecks.showroom(img, m)
			var mask := VehicleManifest.SHOWROOM_DIR + "masks/" + vid + "_paint.png"
			if FileAccess.file_exists(mask):
				var mimg := VehicleArtChecks.load_png(mask)
				if mimg == null or mimg.get_size() != VehicleManifest.SHOWROOM_SIZE: sp_problems.append("showroom paint mask isn't 256x96")
			for p2: String in sp_problems: _fail(problems, vid, p2)
			if sp_problems.is_empty(): showroom.passed += 1
			else: art_ok = false
		else:
			showroom.missing += 1
			art_ok = false
		# the runtime slices
		var rd := VehicleManifest.RUNTIME_DIR + vid
		if DirAccess.dir_exists_absolute(rd):
			runtime.delivered += 1
			var rt_problems := VehicleArtChecks.runtime(rd, m)
			for p3: String in rt_problems: _fail(problems, vid, p3)
			if rt_problems.is_empty(): runtime.passed += 1
			else: art_ok = false
		else:
			runtime.missing += 1
			art_ok = false
		var rv: Dictionary = m.get("review", {})
		if bool(rv.get("approved", false)):
			approved += 1
			if not art_ok: _fail(problems, vid, "approved, but its art isn't all delivered and passing")
	for vid2: String in cars:
		if not have.has(vid2): _fail(problems, vid2, "no manifest (run tools/build_vehicle_manifests.gd)")
	# art for cars that have no manifest
	for f4: String in (Array(DirAccess.get_files_at(VehicleManifest.SHOWROOM_DIR)) if DirAccess.dir_exists_absolute(VehicleManifest.SHOWROOM_DIR) else []):
		if f4.ends_with(".png") and not have.has(f4.get_basename()): _fail(problems, f4, "showroom sprite with no manifest")
	for d4: String in (Array(DirAccess.get_directories_at(VehicleManifest.RUNTIME_DIR)) if DirAccess.dir_exists_absolute(VehicleManifest.RUNTIME_DIR) else []):
		if not have.has(d4): _fail(problems, d4, "runtime folder with no manifest")
	# the report
	var n_fail := 0
	for k in problems: n_fail += (problems[k] as Array).size()
	print("\nvehicle art: %d cars, %d manifests checked in %.1f s" % [cars.size(), checked, (Time.get_ticks_msec() - t0) / 1000.0])
	print("  showroom sprites: %d delivered (%d pass), %d not delivered" % [showroom.delivered, showroom.passed, showroom.missing])
	print("  runtime stacks:   %d delivered (%d pass), %d not delivered" % [runtime.delivered, runtime.passed, runtime.missing])
	print("  approved: %d of %d" % [approved, checked])
	for ex: String in VehicleArtChecks.WHEELBASE_EXCEPTIONS:
		if have.has(ex): print("  known wheelbase gap, not failed: %s (%s)" % [ex, VehicleArtChecks.WHEELBASE_EXCEPTIONS[ex]])
	var keys := problems.keys()
	keys.sort()
	for k2: String in keys:
		var ps: Array = problems[k2]
		print("FAIL  %s: %s" % [k2, "; ".join(PackedStringArray(ps if verbose else ps.slice(0, 4)))] + ("" if verbose or ps.size() <= 4 else " (+%d more)" % (ps.size() - 4)))
	print("\n%d failed" % n_fail)
	quit(1 if n_fail > 0 else 0)

func _fail(problems: Dictionary, key: String, what: String) -> void:
	if not problems.has(key): problems[key] = []
	(problems[key] as Array).append(what)
