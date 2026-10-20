## Writes data/vehicle_art/<vehicle_id>.json for every car (see VehicleManifest), then prints how
## the cars spread over the archetypes, the eras and the spec's quotas.
##   godot --headless --path game -s tools/build_vehicle_manifests.gd
##   godot --headless --path game -s tools/build_vehicle_manifests.gd -- --check
## --check writes nothing: it rebuilds every manifest in memory and exits 1 if any file on disk
## differs from what the cars say now (or is missing, or belongs to no car).
## --only <text> does just the cars whose id has <text> in it (a batch, or a quick look).
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var check := args.has("--check")
	var only := ""
	if args.has("--only") and args.find("--only") + 1 < args.size(): only = args[args.find("--only") + 1]
	var t0 := Time.get_ticks_msec()
	if not check: DirAccess.make_dir_recursive_absolute(VehicleManifest.DIR)
	var written := 0
	var stale: Array = []
	var seen := {}
	var by_arch := {}
	var by_era := {}
	var by_band := {}
	var by_quota := {}
	var odd: Array = []
	var catalogue := {}
	for id: String in CarCatalog.ids() + CarCatalog.fleet_ids(): catalogue[id] = true
	for car_id: String in VehicleManifest.car_ids():
		if only != "" and not car_id.contains(only): continue
		var m := VehicleManifest.rebuild(car_id)
		if m.is_empty():
			push_error("no spec for %s" % car_id)
			stale.append(car_id)
			continue
		var vid := String(m.vehicle_id)
		if seen.has(vid):
			push_error("two cars share the vehicle id %s: %s and %s" % [vid, seen[vid], car_id])
			stale.append(vid)
			continue
		seen[vid] = car_id
		var text := VehicleManifest.to_text(m)
		var path := VehicleManifest.path_of(vid)
		var old := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
		if check:
			if old != text: stale.append(vid)
		elif old != text:
			var f := FileAccess.open(path, FileAccess.WRITE)
			f.store_string(text)
			f.close()
			written += 1
		# the spread is over the cars people own (the catalogue and the hand-made cars); the
		# fleet and the incidents' trucks are counted on their own line
		var c: Dictionary = m.classification
		if not catalogue.has(car_id) or String(c["class"]) == "fleet":
			odd.append("%s (%s)" % [vid, c.archetype])
			continue
		by_arch[c.archetype] = int(by_arch.get(c.archetype, 0)) + 1
		by_era[c.era] = int(by_era.get(c.era, 0)) + 1
		by_band[c.era_band] = int(by_band.get(c.era_band, 0)) + 1
		by_quota[c.quota_class] = int(by_quota.get(c.quota_class, 0)) + 1
	# manifests for cars that are gone
	var on_disk := DirAccess.get_files_at(VehicleManifest.DIR) if DirAccess.dir_exists_absolute(VehicleManifest.DIR) else PackedStringArray()
	for f2: String in on_disk:
		if only == "" and f2.ends_with(".json") and not seen.has(f2.get_basename()): stale.append(f2.get_basename() + " (no car)")
	var total := 0
	for k in by_arch: total += int(by_arch[k])
	print("\n%d manifests, %d cars on the archetypes (+%d fleet and service vehicles)" % [seen.size(), total, odd.size()])
	print("\nper archetype:")
	for a: String in VehicleArchetypes.names():
		print("  %-20s %4d" % [a, int(by_arch.get(a, 0))])
	print("\nper era:")
	var eras := by_era.keys()
	eras.sort()
	for e: String in eras: print("  %-8s %4d" % [e, int(by_era[e])])
	print("\nper era quota (spec count of 300, the catalogue's count, its share scaled to 300):")
	for b: String in VehicleArchetypes.ERA_BANDS:
		var n := int(by_band.get(b, 0))
		print("  %-10s quota %3d   have %4d   scaled %5.1f" % [b, int(VehicleArchetypes.ERA_BANDS[b]), n, 300.0 * n / maxf(1.0, total)])
	print("\nper class quota:")
	for q: String in VehicleArchetypes.QUOTA_CLASSES:
		var n2 := int(by_quota.get(q, 0))
		print("  %-16s quota %3d   have %4d   scaled %5.1f" % [q, int(VehicleArchetypes.QUOTA_CLASSES[q]), n2, 300.0 * n2 / maxf(1.0, total)])
	print("\nfleet and service: %s" % ", ".join(PackedStringArray(odd)))
	if check:
		print("\n%d stale: %s" % [stale.size(), str(stale.slice(0, 12))])
		print("%d failed" % (1 if not stale.is_empty() else 0))
	else:
		print("\n%d written, %d unchanged, in %.1f s" % [written, seen.size() - written, (Time.get_ticks_msec() - t0) / 1000.0])
		if not stale.is_empty(): print("problems: %s" % str(stale))
	quit(1 if not stale.is_empty() else 0)
