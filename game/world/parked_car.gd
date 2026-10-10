## A car parked at the curb, in a driveway or in a lot: a traffic car that never drives. No sim,
## no lane, no lights; solid to drive into (it takes the hit, slides, and stays dented where it
## stops), and drawn from the same art as everything on the road.
class_name ParkedCar
extends TrafficCar

## Parks it: `body` as CarCatalog.random_traffic gives it (its looks already dressed).
func park(the_traffic: Traffic, body: Dictionary, at: Vector2, h: float) -> void:
	traffic = the_traffic
	spec = body.duplicate()
	paint = Color(String(body.paint))
	looks = body.get("looks", {})
	length = float(body.length) * CarArt.CAR_SCALE
	width = float(body.width) * CarArt.CAR_SCALE
	pos = at
	heading = h
	state = "parked"
	# the nearest stretch of road, so a shove that rolls it back toward a lane has one to look at
	a = traffic.map.nearest_node(at)
	b = int(traffic.map.g_adj[a][0][0]) if not traffic.map.g_adj[a].is_empty() else a
	sync_to_physics = false
	shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, width) * PX * Vector2(0.95, 0.9)
	shape.shape = rect
	add_child(shape)
	var art_cues: Dictionary = body.get("art", {})
	if art_cues.has("tractor"): _hook_trailer(body)
	view = CarView.new()
	view.still = true
	view.build(spec, paint, 0.0, rng.randi(), CarArt.CAR_SCALE, looks)
	add_child(view)
	head_light = PointLight2D.new()
	head_light.visible = false
	add_child(head_light)
	position = pos * PX
	shape.rotation = heading
	view.heading = heading

## Only moves when something's shoved it: then it slides to a stop and stays there.
func drive(dt: float) -> void:
	_tow(dt)
	if state == "wrecked":
		view.still = false
		_wrecked(dt)
		if state == "drive": state = "parked"
	_place()
	view.headlights = false
	view.braking = false
	head_light.visible = false
	if state == "parked" and wreck_t > 6.0: view.still = true
