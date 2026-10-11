## Every vehicle in the catalogue, side on and from above, stock and in a few fitments: draws,
## has its wheels, and no tyre ever draws through the body. Prints the ones that don't, by body.
##   godot --headless --path game -s tests/catalog_sweep.gd [-- only]
extends SceneTree

var fails := 0

func check(name: String, ok: bool, detail := "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))
	if not ok: fails += 1

## The fitments every car is tried in, on top of stock.
const TRIES := [
	{},
	{ "drop": 1.0, "offset": "stance", "rim": "deepdish", "lip_depth": 1.0, "camber": -8 },
	{ "drop": -1.0, "tire": "mud", "lift": 4, "rim_size": 0.86 },
	{ "offset": "poke", "spacers": 3, "widebody": "widebody", "stagger": "staggered", "tire": "lowpro" },
]

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var only := a[0] if a.size() > 0 else ""
	var ids: Array = CarCatalog.ids() + CarCatalog.fleet_ids()
	if only != "": ids = ids.filter(func(id: String) -> bool: return id.contains(only))
	var side_bad := {}
	var top_bad := {}
	var no_wheels := []
	var empty := []
	var n := 0
	for id: String in ids:
		var spec := CarCatalog.spec(id)
		var body := String(spec.get("body", "?"))
		var d := CarGen.design(spec)
		for m: Dictionary in TRIES:
			n += 1
			# side on
			var c := CarGen._Car.new(160, d, Color("c8342c"), CarGen.looks(m), {}, 0)
			c.run()
			if m.is_empty():
				if c.wheels.size() < 2 and body != "trailer": no_wheels.append(id)
				if c.p.img.get_used_rect().size.x < 40: empty.append(id)
			var hit := _side_clip(c)
			if hit != "": side_bad[id] = "%s %s %s" % [body, str(m), hit]
			# from above
			var p := CarArt.plan_of(spec, m, { "front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0 }, CarArt.CAR_SCALE, d, CarArt._plan_key(spec, m, {}, CarArt.CAR_SCALE))
			var th := _top_clip(p)
			if th != "": top_bad[id] = "%s %s %s" % [body, str(m), th]
	check("every vehicle draws side on", empty.is_empty(), str(empty))
	check("every vehicle has its wheels", no_wheels.is_empty(), str(no_wheels))
	check("no tyre draws through the body side on, in %d renders of %d vehicles" % [n, ids.size()], side_bad.is_empty(), _by_body(side_bad))
	check("no tyre shares a slice with the body over it from above, in %d plans" % n, top_bad.is_empty(), _by_body(top_bad))
	print("\n%d failed" % fails)
	quit(1 if fails > 0 else 0)

func _by_body(bad: Dictionary) -> String:
	var groups := {}
	for id in bad:
		var b := String(bad[id]).split(" ")[0]
		groups[b] = groups.get(b, 0) + 1
	var out := str(groups) + " e.g. "
	var k := 0
	for id in bad:
		out += "%s: %s; " % [id, bad[id]]
		k += 1
		if k >= 4: break
	return out

## Side on: a tyre pixel inside the body, below the band at its top the fitment tucks under the lip.
func _side_clip(c: CarGen._Car) -> String:
	for wv: Array in c.wheels:
		if c.cycled(wv) or c.skirted(wv): continue
		var tc := Vector2(float(wv[1]), float(wv[2]))
		var band := tc.y - c.r_tire + c.tuck * c.r_tire + 1.0
		for yy in range(int(band) + 1, int(tc.y + c.r_tire)):
			for xx in range(int(tc.x - c.r_tire), int(tc.x + c.r_tire) + 1):
				if Vector2(float(xx) + 0.5, float(yy) + 0.5).distance_to(tc) > c.r_tire - 0.8: continue
				if c.body_at(xx, yy): return "(%d,%d)" % [xx, yy]
	return ""

## From above: a tyre's slice inside the body's column over it.
func _top_clip(p: CarArt.Plan) -> String:
	for w: Array in p.wheels:
		var xc: float = w[0]
		var yc: float = w[1]
		var r: float = w[2]
		var ww: int = w[3]
		var s := float(w[5])
		var zmax := 2.0 * r * CarArt.RISE
		for x in range(int(floor(xc - r)), int(ceil(xc + r)) + 1):
			var dx := float(x) + 0.5 - xc
			if absf(dx) > r or x < 0 or x >= p.sx: continue
			var dz := CarArt.RISE * sqrt(maxf(0.0, r * r - dx * dx))
			var zb := maxi(0, int(round(r * CarArt.RISE - dz)))
			var zt := maxi(zb, int(round(r * CarArt.RISE + dz)) - 1)
			var y_out := int(round(yc - ww / 2.0)) + (ww - 1 if s > 0.0 else 0)
			for ring in ww + p.camber:
				var y := y_out - int(s) * ring
				if y < 0 or y >= p.sy: continue
				for z in range(zb, zt + 1):
					var sh := CarArt.wheel_lean(float(z), p.camber, zmax)
					if ring < sh or ring >= sh + ww: continue
					var i := p.idx(x, y)
					if p.h0[i] >= 0 and z >= p.b0[i] and z <= p.h0[i] and (p.m0[i] & 255) != CarArt.M_TIRE:
						return "(%d,%d,z%d) body %d..%d" % [x, y, z, p.b0[i], p.h0[i]]
	return ""
