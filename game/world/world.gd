## The world you drive in: MapData streamed in 64 m chunks around the camera.
##
## Each chunk draws its own patch in layers (ground, river, lots and shoulders, asphalt,
## markings, rails, weather on the road, then trees and poles above the cars), owns its
## trees' collision, and puts its buildings into the y-sorted layer while it's alive.
## The sky decides what the road is like; this decides where the road is.
class_name World
extends Node2D

const PX := CarArt.PX
const CHUNK := 64.0
const MAX_NEW_PER_FRAME := 3

var map: MapData
var sky: WorldSky
var ysort: Node2D
var chunks := {}                        # Vector2i -> Chunk
var _want: Array[Vector2i] = []
var _dirty: Array[Vector2i] = []
var road_key := ""
var asphalt: ImageTexture
var patch := FastNoiseLite.new()
var forest := FastNoiseLite.new()
var road_geo: Array = []                # per road: { L, R, SL, SR } offset polylines
var river_l := PackedVector2Array()     # river banks, sampled
var river_r := PackedVector2Array()
var mud_l := PackedVector2Array()
var mud_r := PackedVector2Array()
var night := false

# buckets: which map things belong to which chunk
var _b_build := {}
var _b_light := {}
var _b_sign := {}
var _b_lot := {}
var _b_seg := {}
var _b_river := {}
var _b_rail := {}
var _b_bridge := {}
var _b_cross := {}

func _init() -> void:
	map = MapData.get_map()
	patch.seed = 9
	patch.frequency = 0.09
	forest.seed = 31
	forest.frequency = 0.006
	asphalt = _asphalt_tile()
	_geometry()
	_bucket()

func setup(the_sky: WorldSky, the_ysort: Node2D) -> void:
	sky = the_sky
	ysort = the_ysort
	road_key = sky.road_key()
	# the edge of the map
	var walls := StaticBody2D.new()
	add_child(walls)
	var B := MapData.BOUNDS
	for r in [Rect2(B.position.x - 20, B.position.y - 20, B.size.x + 40, 20), Rect2(B.position.x - 20, B.end.y, B.size.x + 40, 20),
			Rect2(B.position.x - 20, B.position.y, 20, B.size.y), Rect2(B.end.x, B.position.y, 20, B.size.y)]:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = r.size * PX
		cs.shape = sh
		cs.position = (r.position + r.size / 2.0) * PX
		walls.add_child(cs)

static func ck(m: Vector2) -> Vector2i:
	return Vector2i(floori(m.x / CHUNK), floori(m.y / CHUNK))

static func light_tex(c: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(c.r, c.g, c.b, 1.0), Color(c.r, c.g, c.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

func _light_tex(c: Color) -> GradientTexture2D:
	return light_tex(c)

func ambient() -> float:
	return sky.temperature()

## What's under the tires (metres).
func surface_at(m: Vector2) -> String:
	var g := map.ground_at(m)
	return sky.surface(g, map.road_rank_at(m), patch.get_noise_2d(m.x, m.y))

# ------------------------------------------------------------------ precomputed geometry

func _offsets(pts: PackedVector2Array, d: float) -> Array:
	var L := PackedVector2Array()
	var R := PackedVector2Array()
	for i in pts.size():
		var n := Vector2.ZERO
		if i > 0: n += (pts[i] - pts[i - 1]).normalized().orthogonal()
		if i < pts.size() - 1: n += (pts[i + 1] - pts[i]).normalized().orthogonal()
		n = n.normalized()
		var k := 1.0
		if i > 0 and i < pts.size() - 1:
			var seg_n := (pts[i + 1] - pts[i]).normalized().orthogonal()
			k = 1.0 / maxf(0.5, n.dot(seg_n))
		L.append(pts[i] + n * d * k)
		R.append(pts[i] - n * d * k)
	return [L, R]

func _geometry() -> void:
	for r in map.roads:
		var hw: float = r.w / 2.0
		var sh: float = MapData.CLS[r.cls].shoulder
		var a := _offsets(r.pts, hw)
		var b := _offsets(r.pts, hw + sh)
		road_geo.append({ "L": a[0], "R": a[1], "SL": b[0], "SR": b[1] })
	# the river, sampled every 6 m with ragged banks
	var pts := map.river_pts
	for i in pts.size() - 1:
		var A := pts[i]
		var B := pts[i + 1]
		var n := int(A.distance_to(B) / 6.0)
		var nrm := (B - A).normalized().orthogonal()
		for k in n:
			var t := float(k) / n
			var c := A.lerp(B, t)
			var hw := lerpf(map.river_hw[i], map.river_hw[i + 1], t) + map.noise.get_noise_2d(c.x * 3.0, c.y * 3.0) * 4.0
			river_l.append(c + nrm * hw)
			river_r.append(c - nrm * hw)
			mud_l.append(c + nrm * (hw + 10.0 + map.noise.get_noise_2d(c.x * 7.0, c.y) * 3.0))
			mud_r.append(c - nrm * (hw + 10.0 + map.noise.get_noise_2d(c.x, c.y * 7.0) * 3.0))

func _add(b: Dictionary, k: Vector2i, v) -> void:
	if not b.has(k): b[k] = []
	b[k].append(v)

func _bucket_rect(b: Dictionary, r: Rect2, v) -> void:
	var c0 := ck(r.position)
	var c1 := ck(r.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1): _add(b, Vector2i(x, y), v)

func _bucket() -> void:
	for b in map.buildings: _add(_b_build, ck(b.r.get_center()), b)
	for l in map.lights: _add(_b_light, ck(l.p), l)
	for sg in map.wild_signs: _add(_b_sign, ck(sg.p), sg)
	for l in map.lots: _bucket_rect(_b_lot, l.r, l)
	for ri in map.roads.size():
		var g: Dictionary = road_geo[ri]
		var SL: PackedVector2Array = g.SL
		var SR: PackedVector2Array = g.SR
		for si in SL.size() - 1:
			var r := Rect2(SL[si], Vector2.ZERO).expand(SL[si + 1]).expand(SR[si]).expand(SR[si + 1])
			_bucket_rect(_b_seg, r, [ri, si])
	for i in mud_l.size() - 1:
		var r := Rect2(mud_l[i], Vector2.ZERO).expand(mud_l[i + 1]).expand(mud_r[i]).expand(mud_r[i + 1])
		_bucket_rect(_b_river, r, i)
	for i in map.rail_pts.size() - 1:
		var r := Rect2(map.rail_pts[i], Vector2.ZERO).expand(map.rail_pts[i + 1]).grow(4.0)
		_bucket_rect(_b_rail, r, i)
	for br in map.bridges:
		_bucket_rect(_b_bridge, Rect2(br.a, Vector2.ZERO).expand(br.b).grow(br.w), br)
	for c in map.crossings: _add(_b_cross, ck(c.p), c)

# ------------------------------------------------------------------ streaming

## Keep the chunks around the view alive; make a few new ones per frame, nearest first.
func update_view(center_m: Vector2, half_m: Vector2) -> void:
	var c0 := ck(center_m - half_m - Vector2(CHUNK, CHUNK) * 0.75)
	var c1 := ck(center_m + half_m + Vector2(CHUNK, CHUNK) * 0.75)
	var want := {}
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1): want[Vector2i(x, y)] = true
	var missing: Array[Vector2i] = []
	for k in want:
		if not chunks.has(k): missing.append(k)
	var cc := ck(center_m)
	missing.sort_custom(func(a, b): return (a - cc).length_squared() < (b - cc).length_squared())
	for i in mini(MAX_NEW_PER_FRAME, missing.size()):
		_make(missing[i])
	# drop the ones well out of view
	for k in chunks.keys():
		if k.x < c0.x - 2 or k.x > c1.x + 2 or k.y < c0.y - 2 or k.y > c1.y + 2:
			chunks[k].release()
			chunks.erase(k)
	# the weather changed the road: redraw a couple of chunks a frame
	var key := sky.road_key()
	if key != road_key:
		road_key = key
		_dirty = []
		for k in chunks: _dirty.append(k)
		_dirty.sort_custom(func(a, b): return (a - cc).length_squared() < (b - cc).length_squared())
	for i in mini(3, _dirty.size()):
		var k: Vector2i = _dirty.pop_front()
		if chunks.has(k): chunks[k].redraw_weather()

## Fill a radius right away (at the start, and after a teleport).
func warm(center_m: Vector2, half_m: Vector2) -> void:
	for i in 40:
		var before := chunks.size()
		update_view(center_m, half_m)
		if chunks.size() == before: break

func _make(k: Vector2i) -> void:
	var c := Chunk.new()
	c.world = self
	c.key = k
	c.rect = Rect2(Vector2(k) * CHUNK, Vector2(CHUNK, CHUNK))
	add_child(c)
	c.build()
	c.set_night(night)
	chunks[k] = c

func set_night(on: bool) -> void:
	if on == night: return
	night = on
	for k in chunks: chunks[k].set_night(on)

## The light sources in the live chunks (the light pool picks the nearest).
func live_lights() -> Array:
	var out: Array = []
	for k in chunks: out.append_array(_b_light.get(k, []))
	return out

func live_crossings() -> Array:
	var out: Array = []
	for k in chunks: out.append_array(_b_cross.get(k, []))
	return out

# ------------------------------------------------------------------ drawing helpers

func _asphalt_tile() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 64:
		for x in 64:
			var v := 0.2 + rng.randf() * 0.035
			if rng.randf() < 0.03: v += 0.05
			if rng.randf() < 0.015: v -= 0.05
			img.set_pixel(x, y, Color(v, v, v * 1.05))
	return ImageTexture.create_from_image(img)

func asphalt_tint() -> Color:
	var t := Color(1, 1, 1)
	t = t.lerp(Color(0.68, 0.71, 0.8), clampf(sky.wet * 1.4, 0.0, 1.0))
	t = t.lerp(Color(3.2, 3.3, 3.5), clampf(sky.snow_cover * 0.9, 0.0, 0.85))
	return t

static var _ground_shader: Shader
static var _ground_detail: ImageTexture

## Smooth colour between cells (linear), then a pixel-art grass texture on top at two scales so
## it never looks tiled, dirt specks, summer flowers, fall leaf litter, and snow that flattens it all.
static func ground_shader() -> Shader:
	if _ground_shader: return _ground_shader
	_ground_shader = Shader.new()
	_ground_shader.code = """shader_type canvas_item;
uniform sampler2D detail : filter_nearest, repeat_enable;
uniform vec2 origin = vec2(0.0);
uniform float cells = 18.0;
uniform float snow = 0.0;
uniform float flowers = 0.0;
uniform float fall = 0.0;
void fragment() {
	vec2 cpx = vec2(cells * 48.0);
	vec2 wp = floor(origin + UV * cpx);
	vec3 base = texture(TEXTURE, UV).rgb;
	vec4 d = texture(detail, wp / 256.0);
	vec4 d2 = texture(detail, wp / 256.0 * 0.29 + vec2(0.37, 0.71));
	float amp = 1.0 - snow * 0.75;
	float lum = ((d.r - 0.5) * 0.5 + (d2.r - 0.5) * 0.35) * amp;
	lum = floor(lum * 10.0 + 0.5) / 10.0;
	vec3 c = base * (1.0 + lum);
	c = mix(c, base * vec3(0.8, 0.7, 0.56), d.g * 0.85 * amp);
	if (d.b > 0.75 && flowers > 0.5 && snow < 0.3) c = mix(c, vec3(0.96, 0.92, 0.78), 0.85);
	else if (d.b > 0.6 && d.b <= 0.75 && flowers > 0.5 && snow < 0.3) c = mix(c, vec3(0.95, 0.82, 0.25), 0.8);
	if (d2.b > 0.62 && fall > 0.5 && snow < 0.3) c = mix(c, mix(vec3(0.78, 0.33, 0.12), vec3(0.9, 0.62, 0.16), d.r), 0.75);
	COLOR = vec4(c, 1.0);
}"""
	return _ground_shader

static func ground_detail() -> ImageTexture:
	if _ground_detail: return _ground_detail
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var noise := FastNoiseLite.new()
	noise.seed = 77
	noise.frequency = 0.05
	var lum := PackedFloat32Array()
	lum.resize(S * S)
	for y in S:
		for x in S:
			# tileable noise: sample a torus
			var ax := float(x) / S * TAU
			var ay := float(y) / S * TAU
			var v := noise.get_noise_3d(cos(ax) * 40.0, sin(ax) * 40.0 + cos(ay) * 40.0, sin(ay) * 40.0)
			lum[y * S + x] = 0.5 + v * 0.25
	# grass blades: a light stroke with a dark root
	for i in 2600:
		var x := rng.randi() % S
		var y := rng.randi() % S
		var h := rng.randi_range(2, 4)
		var lean := rng.randi_range(-1, 1)
		for k in h:
			var px := (x + (lean if k == h - 1 else 0) + S) % S
			var py := (y - k + S) % S
			lum[py * S + px] = clampf(lum[py * S + px] + 0.22, 0.0, 1.0)
		lum[((y + 1) % S) * S + x] = clampf(lum[((y + 1) % S) * S + x] - 0.2, 0.0, 1.0)
	for y in S:
		for x in S:
			img.set_pixel(x, y, Color(lum[y * S + x], 0.0, 0.0, 1.0))
	# dirt specks and bare patches
	for i in 700:
		var x := rng.randi() % S
		var y := rng.randi() % S
		var c := img.get_pixel(x, y)
		c.g = rng.randf_range(0.5, 1.0)
		img.set_pixel(x, y, c)
		if rng.randf() < 0.3: img.set_pixel((x + 1) % S, y, c)
	# flowers (b > 0.75 white daisies, 0.6..0.75 yellow) and leaf litter
	for i in 160:
		var x := rng.randi() % S
		var y := rng.randi() % S
		var c := img.get_pixel(x, y)
		c.b = rng.randf_range(0.6, 1.0)
		img.set_pixel(x, y, c)
	_ground_detail = ImageTexture.create_from_image(img)
	return _ground_detail

func ground_color(m: Vector2, zone: Dictionary) -> Color:
	var s := sky.season
	var n := patch.get_noise_2d(m.x * 0.4, m.y * 0.4)
	var c: Color
	match zone.style:
		"downtown": c = Color("8a8780")
		"industrial": c = Color("6a6458")
		_:
			var f := map.field_noise.get_noise_2d(m.x, m.y)
			var fields: bool = zone.style == "rural" and f > 0.22
			match s:
				"summer": c = Color("4a6a32") if not fields else Color("7a8a3a")
				"fall": c = Color("5a5a32") if not fields else Color("9a7a3a")
				"winter": c = Color("4a5a3a")
				"spring": c = Color("4e5a34") if not fields else Color("6a5434")
			if fields and int(m.x / 4.0) % 2 == 0: c = c.darkened(0.08)    # crop rows
			if zone.style == "rural" and forest.get_noise_2d(m.x, m.y) > 0.05 and not fields: c = c.darkened(0.25)
	c = c.lightened(n * 0.06)
	var snow := clampf(sky.snow_cover * 1.6, 0.0, 1.0)
	if snow > 0.0: c = c.lerp(Color("e2e6ee").lightened(n * 0.04), snow)
	return c


## One 64 m square of the world.
class Chunk extends Node2D:
	var world: World
	var key: Vector2i
	var rect: Rect2
	var layers := {}
	var body: StaticBody2D
	var nodes: Array[Node] = []           # things it put in the y-sort layer
	var trees: Array = []                 # [pos, kind, size, seed]
	var decor: Array = []                 # [pos, kind, radius px, seed]: undergrowth, rocks, flowers, bales
	var signals: Array[Node2D] = []

	func build() -> void:
		_soil_layer()
		for spec in [["ground", -4000], ["water", -3999], ["base", -3998], ["decor", -3998], ["road", -3997], ["marks", -3996], ["rail", -3995], ["weather", -3994], ["canopy", 3000]]:
			var L := Layer.new()
			L.chunk = self
			L.kind = spec[0]
			L.z_index = spec[1]
			L.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			add_child(L)
			layers[spec[0]] = L
		body = StaticBody2D.new()
		add_child(body)
		_trees()
		for b in world._b_build.get(key, []):
			var n := BuildingNode.new()
			n.setup(b)
			world.ysort.add_child(n)
			nodes.append(n)
		# bridge rails: you can hit them
		for br in world._b_bridge.get(key, []):
			var dir: Vector2 = (br.b - br.a).normalized()
			for side in [-1.0, 1.0]:
				var off: Vector2 = dir.orthogonal() * side * (br.w / 2.0 + 0.6)
				var cs := CollisionShape2D.new()
				var seg := SegmentShape2D.new()
				seg.a = (br.a + off) * PX
				seg.b = (br.b + off) * PX
				cs.shape = seg
				body.add_child(cs)

	var soil: Sprite2D
	var soil_mat: ShaderMaterial

	## The ground itself: an 18x18 map of cell colours (one cell of border so neighbouring
	## chunks blend into each other), smoothed and textured by the ground shader.
	func _soil_layer() -> void:
		soil = Sprite2D.new()
		soil.centered = false
		soil.z_index = -4001
		soil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		soil_mat = ShaderMaterial.new()
		soil_mat.shader = World.ground_shader()
		soil_mat.set_shader_parameter("detail", World.ground_detail())
		soil.material = soil_mat
		add_child(soil)
		paint_soil()

	func paint_soil() -> void:
		var n := int(World.CHUNK / 4.0) + 2
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for gy in n:
			for gx in n:
				var m := rect.position + Vector2(gx - 1 + 0.5, gy - 1 + 0.5) * 4.0
				img.set_pixel(gx, gy, world.ground_color(m, world.map.zone_at(m)))
		soil.texture = ImageTexture.create_from_image(img)
		# the sprite covers n cells; shift it so cell 1 lines up with the chunk's corner
		soil.scale = Vector2(4.0 * PX, 4.0 * PX)
		soil.position = (rect.position - Vector2(4.0, 4.0)) * PX
		soil_mat.set_shader_parameter("origin", soil.position)
		soil_mat.set_shader_parameter("cells", float(n))
		soil_mat.set_shader_parameter("snow", clampf(world.sky.snow_cover * 1.6, 0.0, 1.0))
		soil_mat.set_shader_parameter("flowers", 1.0 if world.sky.season in ["summer", "spring"] else 0.0)
		soil_mat.set_shader_parameter("fall", 1.0 if world.sky.season == "fall" else 0.0)

	## Which tree grows here: conifers in the woods (in stands, not salt-and-pepper), maples and
	## oaks in town, cedar hedges, tamarack in the wet spots, the odd dead snag.
	const SPECIES := {
		"forest": [["spruce", 34], ["fir", 24], ["pine", 9], ["tamarack", 5], ["birch", 10], ["maple", 8], ["aspen", 6], ["snag", 2]],
		"rural": [["maple", 26], ["birch", 14], ["aspen", 14], ["spruce", 18], ["oak", 7], ["pine", 8], ["fir", 6], ["snag", 4], ["tamarack", 3]],
		"town": [["maple", 34], ["oak", 15], ["birch", 9], ["spruce", 12], ["cedar", 16], ["pine", 5], ["aspen", 5], ["fir", 4]],
		"downtown": [["maple", 48], ["oak", 22], ["cedar", 18], ["birch", 12]],
	}
	const SPECIES_SIZE := { "spruce": Vector2(2.0, 3.6), "fir": Vector2(1.6, 2.8), "pine": Vector2(3.0, 4.6), "tamarack": Vector2(1.8, 3.0),
		"birch": Vector2(1.8, 3.0), "maple": Vector2(2.4, 4.2), "aspen": Vector2(1.6, 2.8), "oak": Vector2(3.2, 4.8), "cedar": Vector2(1.2, 2.0), "snag": Vector2(1.6, 2.8) }

	func _species(rng: RandomNumberGenerator, style: String, p: Vector2) -> String:
		var set := "town"
		if style == "rural": set = "forest" if world.forest.get_noise_2d(p.x, p.y) > 0.05 else "rural"
		elif style in ["oldtown", "commercial", "downtown", "industrial"]: set = "downtown"
		var table: Array = SPECIES[set]
		# stands: a slow noise tilts the odds so you get a patch of birch, a patch of fir...
		var stand := world.forest.get_noise_2d(p.x * 3.1 + 900.0, p.y * 3.1 - 400.0)
		var total := 0.0
		var weights: Array[float] = []
		for k in table.size():
			var wgt := float(table[k][1]) * (1.0 + 1.6 * maxf(0.0, stand * (1.0 if k % 2 == 0 else -1.0)))
			weights.append(wgt)
			total += wgt
		var r := rng.randf() * total
		for k in table.size():
			r -= weights[k]
			if r <= 0.0: return String(table[k][0])
		return String(table[0][0])

	## The low stuff between the trees: what grows depends on where you are.
	func _maybe_decor(rng: RandomNumberGenerator, z: Dictionary, p: Vector2, near_builds: Array) -> void:
		var q := p + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))
		var g := world.map.ground_at(q)
		if g == "mud":
			if rng.randf() < 0.55: decor.append([q, "cattail", rng.randi_range(10, 16), rng.randi()])
			return
		if g != "grass": return
		if not world.map.road_at(q, 3.5).is_empty() or world.map.rail_near(q, 3.0): return
		for b in near_builds:
			if b.r.grow(1.5).has_point(q): return
		var roadside := not world.map.road_at(q, 9.0).is_empty()
		var table: Array
		match String(z.style):
			"rural":
				if roadside: table = [["lupine", 20], ["grass", 24], ["alder", 14], ["flowers", 10], ["rocks", 4], ["shrub", 8], ["", 14]]
				elif world.map.field_noise.get_noise_2d(q.x, q.y) > 0.22:
					var barren := world.forest.get_noise_2d(q.x * 0.5 + 3000.0, q.y * 0.5)
					if barren > 0.25: table = [["blueberry", 60], ["boulder", 4], ["rocks", 6], ["", 30]]
					else: table = [["grass", 16], ["flowers", 12], ["bale", 4], ["boulder", 2], ["lupine", 4], ["", 50]]
				elif world.forest.get_noise_2d(q.x, q.y) > 0.05: table = [["fern", 28], ["shrub", 16], ["stump", 7], ["log", 8], ["boulder", 7], ["grass", 6], ["", 20]]
				else: table = [["shrub", 16], ["grass", 18], ["flowers", 10], ["boulder", 5], ["stump", 3], ["alder", 8], ["", 30]]
			"residential", "village": table = [["shrub", 14], ["flowers", 8], ["grass", 6], ["rocks", 2], ["", 70]]
			_: table = [["shrub", 6], ["", 94]]
		var total := 0.0
		for e in table: total += float(e[1])
		var r := rng.randf() * total
		var kind := ""
		for e in table:
			r -= float(e[1])
			if r <= 0.0:
				kind = String(e[0])
				break
		if kind == "": return
		var size: Vector2i = DECOR_SIZE.get(kind, Vector2i(8, 14))
		decor.append([q, kind, rng.randi_range(size.x, size.y), rng.randi()])

	const DECOR_SIZE := { "shrub": Vector2i(15, 27), "alder": Vector2i(21, 33), "boulder": Vector2i(9, 21), "rocks": Vector2i(18, 27),
		"stump": Vector2i(9, 13), "log": Vector2i(21, 36), "lupine": Vector2i(15, 24), "flowers": Vector2i(15, 27), "fern": Vector2i(12, 21),
		"grass": Vector2i(12, 21), "cattail": Vector2i(15, 24), "bale": Vector2i(13, 16), "blueberry": Vector2i(27, 48) }

	func release() -> void:
		for n in nodes: n.queue_free()
		nodes.clear()
		queue_free()

	func set_night(on: bool) -> void:
		for n in nodes:
			if n is BuildingNode: n.windows.visible = on

	func redraw_weather() -> void:
		paint_soil()
		for k in ["ground", "road", "base", "weather", "canopy", "decor"]: layers[k].queue_redraw()

	func _trees() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = key.x * 92821 + key.y * 68917
		var zone := world.map.zone_at(rect.get_center())
		var step := 7.0
		var near_builds: Array = []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				near_builds.append_array(world._b_build.get(key + Vector2i(dx, dy), []))
		for gy in int(CHUNK / step):
			for gx in int(CHUNK / step):
				var p := rect.position + Vector2(gx + rng.randf(), gy + rng.randf()) * step
				var roll := rng.randf()
				var z := world.map.zone_at(p)
				var dens := 0.0
				match z.style:
					"rural":
						var f := world.forest.get_noise_2d(p.x, p.y)
						if world.map.field_noise.get_noise_2d(p.x, p.y) > 0.22: dens = 0.01
						else: dens = 0.75 if f > 0.05 else 0.08
					"residential", "village": dens = 0.12
					"oldtown", "commercial": dens = 0.03
				if roll > dens:
					_maybe_decor(rng, z, p, near_builds)
					continue
				if world.map.ground_at(p) != "grass": continue
				if not world.map.road_at(p, 5.0).is_empty():
					_maybe_decor(rng, z, p, near_builds)
					continue
				if world.map.rail_near(p, 5.0): continue
				var blocked := false
				for b in near_builds:
					if b.r.grow(3.0).has_point(p): blocked = true
				if blocked: continue
				var kind := _species(rng, z.style, p)
				var size: float = SPECIES_SIZE.get(kind, Vector2(2.2, 4.0)).x + rng.randf() * (SPECIES_SIZE.get(kind, Vector2(2.2, 4.0)).y - SPECIES_SIZE.get(kind, Vector2(2.2, 4.0)).x)
				trees.append([p, kind, size, rng.randi()])
				var cs := CollisionShape2D.new()
				var sh := CircleShape2D.new()
				sh.radius = 0.5 * PX
				cs.shape = sh
				cs.position = p * PX
				body.add_child(cs)


class Layer extends Node2D:
	var chunk: Chunk
	var kind := ""

	func _draw() -> void:
		var w := chunk.world
		match kind:
			"ground": _ground(w)
			"water": _water(w)
			"base": _base(w)
			"road": _road(w)
			"marks": _marks(w)
			"rail": _rail(w)
			"weather": _weather(w)
			"canopy": _canopy(w)
			"decor": _decor(w)

	## Quads straight to the GPU as two triangles: never fails, even when a sharp bend folds it.
	func _quad(pts: PackedVector2Array, col: Color) -> void:
		draw_primitive(pts, PackedColorArray([col, col, col, col]), PackedVector2Array())

	func _px(r: Rect2) -> Rect2:
		return Rect2(r.position * PX, r.size * PX)

	func _ground(w: World) -> void:
		# (the grass and dirt are the chunk's soil sprite, under this layer)
		# sidewalks under the city streets
		for e in w._b_seg.get(chunk.key, []):
			var rd: Dictionary = w.map.roads[e[0]]
			if rd.zone == "" or rd.cls in ["rural", "gravel"]: continue
			var g: Dictionary = w.road_geo[e[0]]
			var a: Vector2 = rd.pts[e[1]]
			var b: Vector2 = rd.pts[e[1] + 1]
			# the sidewalk's outer edge stays where an 11 m street's was, so the city doesn't move
			var side: float = rd.w / 2.0 + 2.5 + (maxf(0.0, 11.0 - float(rd.w)) / 2.0 if rd.cls == "street" else 0.0)
			var nrm: Vector2 = (b - a).normalized().orthogonal() * side
			var col := Color("9a968e").lerp(Color("e8ecf2"), clampf(w.sky.snow_cover * 1.4, 0, 1))
			_quad(PackedVector2Array([(a + nrm) * PX, (b + nrm) * PX, (b - nrm) * PX, (a - nrm) * PX]), col)

	func _water(w: World) -> void:
		var winter := w.sky.season == "winter"
		for i in w._b_river.get(chunk.key, []):
			var mud := PackedVector2Array([w.mud_l[i] * PX, w.mud_l[i + 1] * PX, w.mud_r[i + 1] * PX, w.mud_r[i] * PX])
			_quad(mud, Color("6a4a32") if not winter else Color("b8b0a8"))
			var water := PackedVector2Array([w.river_l[i] * PX, w.river_l[i + 1] * PX, w.river_r[i + 1] * PX, w.river_r[i] * PX])
			# the Chocolate River: brown with silt; ice floes in winter
			_quad(water, Color("7a5638") if not winter else Color("9aa4ae"))
			var c: Vector2 = (w.river_l[i] + w.river_r[i]) / 2.0
			if i % 3 == 0:
				draw_line((c + Vector2(-3, 0)) * PX, (c + Vector2(4, 0)) * PX, Color(0.62, 0.45, 0.3) if not winter else Color(0.9, 0.93, 0.96), 2.0)

	func _base(w: World) -> void:
		var tint := w.asphalt_tint()
		# lots
		for l in w._b_lot.get(chunk.key, []):
			var r := _px(l.r)
			match l.kind:
				"gravel": draw_rect(r, Color("8a8070").lerp(Color("e0e4ea"), clampf(w.sky.snow_cover * 1.2, 0, 1)))
				"park":
					draw_rect(r, w.ground_color(l.r.get_center(), { "style": "residential" }))
					draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2 * PX), Vector2(r.size.x, 2 * PX)), Color("9a968e"))
				_: draw_texture_rect(w.asphalt, r, true, tint)
		# gravel shoulders and bridge decks
		for e in w._b_seg.get(chunk.key, []):
			var rd: Dictionary = w.map.roads[e[0]]
			if MapData.CLS[rd.cls].shoulder <= 0.0: continue
			var g: Dictionary = w.road_geo[e[0]]
			var si: int = e[1]
			var poly := PackedVector2Array([g.SL[si] * PX, g.SL[si + 1] * PX, g.SR[si + 1] * PX, g.SR[si] * PX])
			_quad(poly, Color("8a8070").lerp(Color("e0e4ea"), clampf(w.sky.snow_cover * 1.2, 0, 1)))
		for br in w._b_bridge.get(chunk.key, []):
			var dir: Vector2 = (br.b - br.a).normalized()
			var n: Vector2 = dir.orthogonal() * (br.w / 2.0 + 1.2)
			_quad(PackedVector2Array([(br.a + n) * PX, (br.b + n) * PX, (br.b - n) * PX, (br.a - n) * PX]), Color("a8a49c"))
			_quad(PackedVector2Array([(br.a - n) * PX, (br.b - n) * PX, (br.b - n + Vector2(0.8, 1.6)) * PX, (br.a - n + Vector2(0.8, 1.6)) * PX]), Color(0, 0, 0, 0.35))

	func _road(w: World) -> void:
		var tint := w.asphalt_tint()
		for e in w._b_seg.get(chunk.key, []):
			var rd: Dictionary = w.map.roads[e[0]]
			var g: Dictionary = w.road_geo[e[0]]
			var si: int = e[1]
			var pts := PackedVector2Array([g.L[si] * PX, g.L[si + 1] * PX, g.R[si + 1] * PX, g.R[si] * PX])
			if rd.cls == "gravel":
				_quad(pts, Color("9a8e78").lerp(Color("e6eaf0"), clampf(w.sky.snow_cover * 1.3, 0, 1)))
				continue
			var uvs := PackedVector2Array()
			for p in pts: uvs.append(p / 64.0)
			draw_primitive(pts, PackedColorArray([tint, tint, tint, tint]), uvs, w.asphalt)

	func _other_road(w: World, p: Vector2, ri: int) -> bool:
		for e in w.map._road_index.get(w.map._cell(p), []):
			if e[0] == ri: continue
			var r: Dictionary = w.map.roads[e[0]]
			if r.limited != w.map.roads[ri].limited: continue
			if MapData.seg_dist(p, r.pts[e[1]], r.pts[e[1] + 1]) < r.w / 2.0 + 1.0: return true
		return false

	func _line(w: World, ri: int, si: int, off: float, col: Color, dash: float, width: float) -> void:
		var rd: Dictionary = w.map.roads[ri]
		var a: Vector2 = rd.pts[si]
		var b: Vector2 = rd.pts[si + 1]
		var L := a.distance_to(b)
		if L < 0.1: return
		var dir := (b - a) / L
		var o := dir.orthogonal() * off
		var s := 0.0
		while s < L:
			var e := minf(s + (dash if dash > 0.0 else 2.0), L)
			var p := a + dir * s
			if chunk.rect.grow(2.0).has_point(p) and not _other_road(w, p + o, ri):
				draw_line((p + o) * PX, (a + dir * e + o) * PX, col, width)
			s += dash * 2.0 if dash > 0.0 else 2.0

	func _marks(w: World) -> void:
		var snowy := clampf(w.sky.snow_cover * 1.5, 0.0, 0.85)
		var yellow := Color("d8b23a").lerp(Color(0.9, 0.9, 0.95, 0.15), snowy)
		var white := Color("d8d8d0").lerp(Color(0.9, 0.9, 0.95, 0.15), snowy)
		for e in w._b_seg.get(chunk.key, []):
			var ri: int = e[0]
			var si: int = e[1]
			var rd: Dictionary = w.map.roads[ri]
			match rd.cls:
				"highway":
					# the median: grass and a guard rail, then the lanes
					var a: Vector2 = rd.pts[si]
					var b: Vector2 = rd.pts[si + 1]
					var n := (b - a).normalized().orthogonal() * 2.0
					_quad(PackedVector2Array([(a + n) * PX, (b + n) * PX, (b - n) * PX, (a - n) * PX]), w.ground_color(a, { "style": "rural" }))
					draw_line(a * PX, b * PX, Color("b8bcc0"), 2.0)
					for sd in [-1.0, 1.0]:
						_line(w, ri, si, sd * 2.3, yellow, 0.0, 2.0)
						_line(w, ri, si, sd * 6.0, white, 3.0, 2.0)
						_line(w, ri, si, sd * 9.8, white, 0.0, 2.0)
				"arterial":
					_line(w, ri, si, -0.25, yellow, 0.0, 2.0)
					_line(w, ri, si, 0.25, yellow, 0.0, 2.0)
					_line(w, ri, si, -4.0, white, 3.0, 2.0)
					_line(w, ri, si, 4.0, white, 3.0, 2.0)
				"street":
					_line(w, ri, si, 0.0, yellow, 0.0, 1.5)
				"rural":
					_line(w, ri, si, 0.0, yellow, 3.0, 2.0)
					_line(w, ri, si, -(float(rd.w) / 2.0 - 0.4), white, 0.0, 1.5)
					_line(w, ri, si, float(rd.w) / 2.0 - 0.4, white, 0.0, 1.5)
				"ramp":
					_line(w, ri, si, -(float(rd.w) / 2.0 - 0.4), white, 0.0, 1.5)
					_line(w, ri, si, float(rd.w) / 2.0 - 0.4, white, 0.0, 1.5)
		# parking stalls
		for l in w._b_lot.get(chunk.key, []):
			if not l.lines: continue
			var r: Rect2 = l.r
			if l.kind == "runway":
				for x in range(int(r.position.x) + 8, int(r.end.x) - 8, 14):
					draw_rect(Rect2(Vector2(x, r.get_center().y - 0.3) * PX, Vector2(7, 0.6) * PX), white)
				PixelFont.draw(self, (r.position + Vector2(4, 6)) * PX, l.name, white, 6)
				continue
			for x in range(int(r.position.x) + 3, int(r.end.x) - 2, 3):
				draw_rect(Rect2(Vector2(x, r.position.y + 1) * PX, Vector2(0.15, 5) * PX), white)
				if r.size.y > 16: draw_rect(Rect2(Vector2(x, r.end.y - 6) * PX, Vector2(0.15, 5) * PX), white)
			if l.name != "": PixelFont.draw(self, (r.position + Vector2(4, r.size.y / 2.0 - 1)) * PX, l.name, Color(white, 0.32), 2)

	func _rail(w: World) -> void:
		var snowy := w.sky.snow_cover > 0.3
		for i in w._b_rail.get(chunk.key, []):
			var a: Vector2 = w.map.rail_pts[i]
			var b: Vector2 = w.map.rail_pts[i + 1]
			var L := a.distance_to(b)
			var dir := (b - a) / L
			var n := dir.orthogonal()
			var s := 0.0
			while s < L:
				var p := a + dir * s
				if chunk.rect.grow(1.0).has_point(p):
					draw_line((p + n * 1.3) * PX, (p - n * 1.3) * PX, Color("4a3628") if not snowy else Color("8a7a70"), 3.0)
				s += 0.7
			# clip the rails to this chunk roughly: only draw the part inside
			var t0 := 0.0
			var t1 := 1.0
			draw_line((a + n * 0.72 + dir * t0) * PX, (a + n * 0.72 + (b - a) * t1) * PX, Color("a8acb0"), 2.0)
			draw_line((a - n * 0.72 + dir * t0) * PX, (a - n * 0.72 + (b - a) * t1) * PX, Color("a8acb0"), 2.0)

	func _weather(w: World) -> void:
		var sky := w.sky
		if sky.wet < 0.15 and sky.snow_cover < 0.15 and sky.ice < 0.1 and sky.season != "fall": return
		var r := chunk.rect
		var step := 2.0
		for gy in int(World.CHUNK / step):
			for gx in int(World.CHUNK / step):
				var m := r.position + Vector2(gx, gy) * step + Vector2(1, 1)
				var g := w.map.ground_at(m)
				if g != "asphalt" and g != "gravel":
					if sky.season == "fall" and g == "grass" and w.patch.get_noise_2d(m.x * 2.0, m.y * 2.0) > 0.35:
						draw_rect(Rect2(m * PX, Vector2(3, 2)), [Color("c8642a"), Color("d8a03a"), Color("8a3a22")][(gx + gy) % 3])
					continue
				var s := w.surface_at(m)
				match s:
					"ice": draw_circle(m * PX + Vector2(12, 12), step * PX * 0.8, Color(0.62, 0.72, 0.86, 0.3))
					"wet":
						# puddles: small, in the low spots, catching the light
						var pn := w.patch.get_noise_2d(m.x * 2.3, m.y * 2.3)
						if pn > 0.62 - sky.wet * 0.12:
							var rad := (0.6 + (pn - 0.5) * 2.5) * PX
							draw_circle(m * PX + Vector2(6, 6), rad, Color(0.22, 0.27, 0.36, 0.42))
							draw_line(m * PX + Vector2(6 - rad * 0.5, 6 - rad * 0.3), m * PX + Vector2(6 + rad * 0.3, 6 - rad * 0.3), Color(0.75, 0.82, 0.95, 0.3), 1.0)
					"leaves": draw_rect(Rect2(m * PX, Vector2(3, 2)), Color("c8642a"))
		# snow banks along the edges of plowed roads
		if sky.snow_cover > 0.3:
			for e in w._b_seg.get(chunk.key, []):
				var rd: Dictionary = w.map.roads[e[0]]
				if MapData.CLS[rd.cls].rank < 3 or rd.zone != "": continue
				var g: Dictionary = w.road_geo[e[0]]
				var si: int = e[1]
				draw_line(g.L[si] * PX, g.L[si + 1] * PX, Color(0.9, 0.92, 0.96, 0.8), 0.6 * PX)
				draw_line(g.R[si] * PX, g.R[si + 1] * PX, Color(0.9, 0.92, 0.96, 0.8), 0.6 * PX)

	func _decor(w: World) -> void:
		var s := w.sky.season
		var snow := w.sky.snow_cover > 0.25
		for d in chunk.decor:
			var r: int = d[2]
			var tex := DecorArt.texture(String(d[1]), s, snow, int(d[3]), r)
			draw_texture(tex, ((d[0] as Vector2) * PX - DecorArt.origin(r)).round())

	func _canopy(w: World) -> void:
		var s := w.sky.season
		var snow := w.sky.snow_cover > 0.25
		# the high masts and the crossbucks (the streetlight poles, the signals and the signs are
		# RoadFurniture's, which stands them up the right way however the camera turns)
		for l in w._b_light.get(chunk.key, []):
			var p: Vector2 = l.p * PX
			match String(l.type):
				"led_flood":
					draw_rect(Rect2(p + Vector2(-1, -2), Vector2(3, 3)), Color("2a2a2e"))
					draw_rect(Rect2(p + Vector2(-3, -3), Vector2(7, 2)), Color("4a4a50"))
				"highmast":
					draw_rect(Rect2(p + Vector2(-6, -6), Vector2(12, 12)), Color("3a3a40"))
				"rail":
					draw_line(p + Vector2(-6, -6), p + Vector2(6, 6), Color("e8e8e0"), 2.0)
					draw_line(p + Vector2(-6, 6), p + Vector2(6, -6), Color("e8e8e0"), 2.0)
		for t in chunk.trees:
			var p: Vector2 = t[0] * PX
			var r := int(float(t[2]) * PX)
			var tex := TreeArt.texture(String(t[1]), s, snow, int(t[3]), r)
			draw_texture(tex, (p - TreeArt.origin(r)).round())
