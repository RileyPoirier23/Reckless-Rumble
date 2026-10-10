## The lot, and everything past it: free drive from Port Rumble out to Salisbury and Havelock.
## The clock runs, the weather turns, the lights come on, and the GPS knows the way.
extends Node2D

const PX := CarArt.PX
const CARS := ["silvio", "supreem", "charjer", "tow"]
const START := Vector2(5570, 1566)          # Covington Auto's lot, nose at the bay doors

var world: World
var sky: WorldSky
var skids: Skids
var ysort: Node2D
var car: PlayerCar
var cam: Camera2D
var dark: CanvasModulate
var lights: LightPool
var traffic: Traffic
var furniture: RoadFurniture
var hud: Hud
var dash: DashView
var gps: GpsView
var map_screen: MapScreen
var audio: EngineAudio
var snow_fx: CPUParticles2D
var rain_fx: CPUParticles2D
var fog_rect: ColorRect
var flash_rect: ColorRect
var white_out := 0.0             # a white flash that fades on its own (a black-out in the prologue)
var clouds: Node2D
var sight: Sight                # what Leo can see past the buildings
var car_i := 0
var _light_t := 0.0
var _water_t := 0.0
var night := false
var zoom_mult := 1.0
var cam_rot := 0.0
var _season_seen := ""
var _blink_was := false
var dest := { "name": "", "p": Vector2.ZERO }
var save: Dictionary
var garage: GarageScreen
var mission: StoryMissions.MissionRunner
var blur_rect: ColorRect
var _save_t := 30.0
var death: DeathScreen
var _dying := false
var jobs: JobRunner
var job_board: JobBoard
var market: MarketRunner
var police: Police
var fuel: FuelStop
var salvage: SalvageYard
var auction: Auction
var wildlife: Wildlife
var luchadooros: Luchadooros
var pause_menu: PauseMenu
var award_card: AwardCard
var _award_t := 2.0
var awards_due: Array = []    # won, card not shown yet (it waits until you've stopped)
var awards_on := true         # tests and demos stage their own scenes: no cards stopping them
var furniture_watch := true   # (and no stop signs and red lights going on the police's sheet)
var hold_car := false          # a scene (or a test) has the car stopped
var free_roam := true          # not a test, a demo or a story mission: the calendar carries over
const GARAGE_DOOR := Rect2(5546, 1556, 48, 12)     # in front of Covington Auto's bay doors

func _ready() -> void:
	Controls.setup()
	save = SaveGame.read()
	Awards.save_ref = save
	sky = WorldSky.new()
	sky.time_h = 17.5
	sky.set_season("fall")
	world = World.new()
	add_child(world)
	skids = Skids.new()
	skids.z_index = -3993
	add_child(skids)
	sight = Sight.new()
	sight.drive = self
	add_child(sight)
	ysort = Node2D.new()          # cars and buildings: sorted by depth toward the camera each frame
	add_child(ysort)
	world.setup(sky, ysort)
	lights = LightPool.new()
	add_child(lights)
	lights.setup(world, sky)
	clouds = Clouds.new()
	clouds.sky = sky
	clouds.z_index = 3100
	add_child(clouds)
	# the HUD layer
	var layer := CanvasLayer.new()
	layer.name = "HudLayer"
	add_child(layer)
	fog_rect = ColorRect.new()
	fog_rect.size = Vector2(640, 360)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.color = Color(1, 1, 1, 0)
	layer.add_child(fog_rect)
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(640, 360)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	layer.add_child(flash_rect)
	hud = Hud.new()
	hud.size = Vector2(640, 360)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.sky = sky
	layer.add_child(hud)
	dash = DashView.new()
	dash.size = Vector2(640, 360)
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dash)
	gps = GpsView.new()
	gps.size = Vector2(640, 360)
	gps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gps.world = world
	gps.map = world.map
	gps.sky = sky
	layer.add_child(gps)
	map_screen = MapScreen.new()
	map_screen.size = Vector2(640, 360)
	map_screen.map = world.map
	map_screen.world = world
	map_screen.visible = false
	map_screen.chosen.connect(_on_dest)
	layer.add_child(map_screen)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.ignore_rotation = false
	add_child(cam)
	cam.make_current()
	dark = CanvasModulate.new()
	add_child(dark)
	snow_fx = _weather(Color(1, 1, 1, 0.9), Vector2(-8, 28), 260, 1.0)
	rain_fx = _weather(Color(0.7, 0.78, 0.9, 0.55), Vector2(-30, 260), 300, 0.0)
	audio = EngineAudio.new()
	add_child(audio)
	# double vision, for the nights Leo shouldn't be driving
	blur_rect = ColorRect.new()
	blur_rect.size = Vector2(640, 360)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;
uniform vec2 offset = vec2(0.0);
void fragment() {
	vec4 a = texture(screen_tex, SCREEN_UV);
	vec4 b = texture(screen_tex, SCREEN_UV + offset);
	vec4 c = texture(screen_tex, SCREEN_UV - offset * 0.6);
	COLOR = vec4(mix(a.rgb, (b.rgb + c.rgb) * 0.5, amount * 0.5), 1.0);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	blur_rect.material = mat
	blur_rect.visible = false
	get_node("HudLayer").add_child(blur_rect)
	get_node("HudLayer").move_child(blur_rect, 0)
	death = DeathScreen.new()
	death.continued.connect(_after_death)
	get_node("HudLayer").add_child(death)
	garage = GarageScreen.new()
	garage.size = Vector2(640, 360)
	garage.visible = false
	garage.picked.connect(_on_garage_pick)
	garage.repaired.connect(_on_garage_repair)
	garage.closed.connect(_on_garage_closed)
	get_node("HudLayer").add_child(garage)
	job_board = JobBoard.new()
	job_board.size = Vector2(640, 360)
	job_board.visible = false
	job_board.picked.connect(_on_job_picked)
	job_board.quit_job.connect(func(): jobs.finish(false))
	get_node("HudLayer").add_child(job_board)
	pause_menu = PauseMenu.new()
	pause_menu.quit_to_title.connect(_quit_to_title)
	get_node("HudLayer").add_child(pause_menu)
	award_card = AwardCard.new()
	get_node("HudLayer").add_child(award_card)
	jobs = JobRunner.new()
	add_child(jobs)
	jobs.setup(self)
	market = MarketRunner.new()
	add_child(market)
	market.setup(self)
	job_board.meet.connect(market.start)
	job_board.sold.connect(_on_car_sold)
	police = Police.new()
	add_child(police)
	police.setup(self)
	fuel = FuelStop.new()
	add_child(fuel)
	fuel.setup(self)
	salvage = SalvageYard.new()
	add_child(salvage)
	salvage.setup(self)
	auction = Auction.new()
	add_child(auction)
	auction.setup(self)
	wildlife = Wildlife.new()
	add_child(wildlife)
	wildlife.setup(self)
	luchadooros = Luchadooros.new()
	add_child(luchadooros)
	luchadooros.setup(self)
	# the soak tests and the screenshot demos stage their own scenes: no patrols wandering in
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with("-test") or arg.ends_with("-demo"):
			police.enabled = false
			wildlife.enabled = false
			free_roam = false
			awards_on = false
			furniture_watch = false
	if StoryState.active: free_roam = false
	if free_roam: _restore_calendar()
	if StoryState.active and String(StoryState.current().get("type", "")) == "drive":
		_start_mission(StoryMissions.MISSIONS[StoryState.current().mission])
	else:
		_spawn_car(int(save.get("current", 0)), START, -PI / 2.0)
	traffic = Traffic.new()
	add_child(traffic)
	traffic.setup(world, sky, ysort, car)
	furniture = RoadFurniture.new()
	add_child(furniture)
	furniture.setup(self)
	furniture.watch_on = furniture_watch
	world.warm(car.sim.pos, Vector2(40, 25))
	hud.show_help = bool(GameSettings.get_v("ui", "controls_card"))   # F1 (or the pause menu) shows the controls
	_apply_settings()
	var iw := get_node_or_null("/root/InputWatch")
	if iw:
		iw.settings_changed.connect(_apply_settings)
		iw.wheel_found.connect(_wheel_found)
	if Wheel.needs_setup(): _wheel_found.call_deferred(Input.get_joy_name(Wheel.device))
	if OS.get_cmdline_user_args().has("--traffic-demo"):
		var td: Node = load("res://tests/traffic_demo.gd").new()
		td.main = self
		add_child(td)
	elif OS.get_cmdline_user_args().has("--traffic-test"):
		var tt: Node = load("res://tests/traffic_test.gd").new()
		tt.main = self
		add_child(tt)
	elif OS.get_cmdline_user_args().has("--world-demo"):
		var wd: Node = load("res://tests/world_demo.gd").new()
		wd.main = self
		add_child(wd)
	elif OS.get_cmdline_user_args().has("--veg-demo"):
		var vd: Node = load("res://tests/veg_demo.gd").new()
		vd.main = self
		add_child(vd)
	elif OS.get_cmdline_user_args().has("--market-demo"):
		var md: Node = load("res://tests/market_demo.gd").new()
		md.main = self
		add_child(md)
	elif OS.get_cmdline_user_args().has("--sight-demo"):
		var sd: Node = load("res://tests/sight_demo.gd").new()
		sd.main = self
		add_child(sd)
	elif OS.get_cmdline_user_args().has("--wild-demo"):
		var wd2: Node = load("res://tests/wild_demo.gd").new()
		wd2.main = self
		add_child(wd2)
	elif OS.get_cmdline_user_args().has("--auction-demo"):
		var ad: Node = load("res://tests/auction_demo.gd").new()
		ad.main = self
		add_child(ad)
	elif OS.get_cmdline_user_args().has("--meet-demo"):
		var mtd: Node = load("res://tests/meet_demo.gd").new()
		mtd.main = self
		add_child(mtd)
	elif OS.get_cmdline_user_args().has("--salvage-demo"):
		var sd: Node = load("res://tests/salvage_demo.gd").new()
		sd.main = self
		add_child(sd)
	elif OS.get_cmdline_user_args().has("--crew-demo"):
		var cd: Node = load("res://tests/crew_demo.gd").new()
		cd.main = self
		add_child(cd)
	elif OS.get_cmdline_user_args().has("--furniture-demo"):
		var fd2: Node = load("res://tests/furniture_demo.gd").new()
		fd2.main = self
		add_child(fd2)
	elif OS.get_cmdline_user_args().has("--pause-demo"):
		var pd: Node = load("res://tests/pause_demo.gd").new()
		pd.main = self
		add_child(pd)
	elif OS.get_cmdline_user_args().has("--fuel-demo"):
		var fd: Node = load("res://tests/fuel_demo.gd").new()
		fd.main = self
		add_child(fd)
	elif OS.get_cmdline_user_args().has("--race-demo"):
		var rd: Node = load("res://tests/race_demo.gd").new()
		rd.main = self
		add_child(rd)
	elif OS.get_cmdline_user_args().has("--race-test"):
		var rt: Node = load("res://tests/race_test.gd").new()
		rt.main = self
		add_child(rt)
	elif OS.get_cmdline_user_args().has("--jobs-demo"):
		var jd: Node = load("res://tests/jobs_demo.gd").new()
		jd.main = self
		add_child(jd)
	elif OS.get_cmdline_user_args().has("--crash-demo"):
		var cd: Node = load("res://tests/crash_demo.gd").new()
		cd.main = self
		add_child(cd)
	elif OS.get_cmdline_user_args().has("--demo"):
		var d: Node = load("res://tests/demo.gd").new()
		d.main = self
		add_child(d)

func _spawn_car(i: int, at: Vector2, heading: float) -> void:
	if car: _store_car()
	car_i = i
	var entry: Dictionary = save.garage[i] if i < (save.garage as Array).size() else { "id": CARS[i % CARS.size()], "paint": "", "damage": {} }
	var spec: Dictionary = SaveGame.car_spec(entry)
	var kit := { "hyd": OneTon.hyd_of(entry), "stance": OneTon.stance(entry) }
	if String(entry.get("paint", "")) != "": spec.paint = entry.paint
	var old_v := Vector2.ZERO
	if car:
		old_v = car.sim.world_velocity()
		car.queue_free()
	car = PlayerCar.new()
	ysort.add_child(car)
	car.setup(spec, world, skids, hud, at, heading)
	car.hyd = int(kit.hyd)
	car.stance = kit.stance
	car.fatal.connect(_on_fatal)
	car.sim.set_world_velocity(old_v)
	hud.sim = car.sim
	hud.player = car
	hud.diag_style = String(spec.get("dash", "analog90"))
	if traffic: traffic.player = car
	dash.sim = car.sim
	dash.style = String(spec.get("dash", "analog90"))
	gps.sim = car.sim
	gps.style = String(spec.get("gps", "tomtum"))
	map_screen.sim = car.sim
	audio.sim = car.sim
	_apply_car_settings()
	for k in car.damage: car.damage[k] = float(entry.get("damage", {}).get(k, 0.0))
	car.damage_bucket = -2
	car.sim.set_wear(entry.get("wear", {}))
	car.sim.burn_fuel = true
	save.current = i
	cam_rot = heading + PI / 2.0
	cam.global_position = car.global_position
	if dest.name != "": gps.set_route(world.map.route(at, dest.p), dest.name)

## A story mission: its car, its time and weather, and the runner that checks the objectives.
func _start_mission(m: Dictionary) -> void:
	_spawn_story_car(String(m.car), m.start, float(m.heading))
	sky.set_season(String(m.season))
	sky.time_h = float(m.time)
	sky.pick_weather(String(m.weather))
	sky.forced = true
	_season_seen = sky.season
	var w: Dictionary = WorldSky.WEATHER[String(m.weather)]
	sky.cloud = w.cloud; sky.fog = w.fog; sky.rain = w.rain; sky.snow = w.snow
	car.impaired = float(m.get("impaired", 0.0))
	if m.has("tires"): car.sim.compound = String(m.tires)        # (December: Gus put the winters on)
	for o in m.objectives:
		if o.get("crash_ends", false): car.can_die = false
	if m.get("gasket", false): car.sim.head_gasket = true
	mission = StoryMissions.MissionRunner.new()
	add_child(mission)
	mission.setup(self, m)
	world.warm(m.start, Vector2(40, 25))

## Story cars aren't from your garage: they're whatever the story puts you in.
func _spawn_story_car(id: String, at: Vector2, heading: float) -> void:
	if car: car.queue_free()
	car = null
	car_i = -1
	var spec: Dictionary = SaveGame.load_spec(id)
	car = PlayerCar.new()
	ysort.add_child(car)
	car.setup(spec, world, skids, hud, at, heading)
	_hook_car(spec, at, heading)

func _swap_story_car(id: String) -> void:
	var at := car.sim.pos + car.sim.right() * 3.0
	var h := car.sim.heading
	var imp := car.impaired
	_spawn_story_car(id, at, h)
	car.impaired = imp
	_teleport(at, h)

func _hook_car(spec: Dictionary, at: Vector2, heading: float) -> void:
	car.fatal.connect(_on_fatal)
	hud.sim = car.sim
	hud.player = car
	hud.diag_style = String(spec.get("dash", "analog90"))
	if traffic: traffic.player = car
	dash.sim = car.sim
	dash.style = String(spec.get("dash", "analog90"))
	gps.sim = car.sim
	gps.style = String(spec.get("gps", "tomtum"))
	map_screen.sim = car.sim
	audio.sim = car.sim
	_apply_car_settings()
	cam_rot = heading + PI / 2.0
	cam.global_position = car.global_position

## A crash you don't walk away from: a beat of slow motion, then the death screen.
func _on_fatal(info: Dictionary) -> void:
	var z := world.map.zone_at(car.sim.pos)
	info.style = String(z.style)
	info.time_h = sky.time_h
	info.season = sky.season
	info.weather = sky.weather
	info.night = night
	info.driver = "LEO" if StoryState.active or StoryState.avatar.is_empty() else "AVATAR"
	if car.spec.get("id", "") == "tow" and StoryState.active: info.driver = "LEO"
	info.place = String(z.label) if String(z.label) != "" else "COUNTRY"
	info.car_name = "%s %s '%s" % [String(car.spec.get("make", "")), String(car.spec.get("model", "")), str(int(car.spec.get("year", 0)) % 100).pad_zeros(2)]
	if mission: mission.set_process(false)
	hud.objective = ""
	audio.horn = false
	# slow motion while the camera pulls in on the wreck, then a freeze-frame without the HUD
	_dying = true
	Awards.bump("totaled")
	cam.position_smoothing_enabled = false
	Engine.time_scale = 0.25
	await get_tree().create_timer(1.0, true, false, true).timeout
	var layer := get_node("HudLayer")
	var was: Array = []
	for c in layer.get_children():
		was.append(c.visible)
		if c is CanvasItem: c.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var i := 0
	for c in layer.get_children():
		if c is CanvasItem: c.visible = was[i]
		i += 1
	Engine.time_scale = 1.0
	death.open(info, shot)

func _after_death() -> void:
	_dying = false
	cam.position_smoothing_enabled = true
	if StoryState.active:
		# try the drive again from the start
		StoryState.go(get_tree())
		return
	if jobs.active():
		jobs.finish(false)
		hud.post("THE JOB'S OFF. NOBODY TIPS A WRECK.", 4.0)
	police.clear()
	wildlife.clear()
	car.dead = false
	car.respawn()
	_teleport(car.start_pos, car.start_heading)
	if car_i >= 0:
		for k in save.garage[car_i].damage: save.garage[car_i].damage[k] = 0.0
	hud.post("GUS TOWED WHAT WAS LEFT TO THE SHOP AND REBUILT IT. HE'S NOT TALKING TO YOU.", 6.0)

## Write the car you're driving back into the save (its paint and its dents).
func _store_car() -> void:
	if car == null or car_i < 0 or car_i >= (save.garage as Array).size(): return
	save.garage[car_i].damage = car.damage.duplicate()
	save.garage[car_i].paint = "#" + car.paint.to_html(false)
	save.garage[car_i].odo_km = float(save.garage[car_i].get("odo_km", 0.0)) + car.sim.odometer_m / 1000.0
	save.garage[car_i].wear = car.sim.wear_state()
	Awards.bump("m_driven", int(car.sim.odometer_m))
	car.sim.odometer_m = 0.0

func _on_garage_pick(i: int) -> void:
	_store_car()
	_spawn_car(i, START, -PI / 2.0)
	_teleport(START, -PI / 2.0)
	SaveGame.write(save)
	var spec: Dictionary = car.spec
	hud.post("%s %s. GUS: \"KEYS ARE IN IT.\"" % [String(spec.make).to_upper(), String(spec.model).to_upper()], 3.0)

## Back out of the garage: whatever Gus bolted on or the body shop did goes on the car.
func _on_garage_closed() -> void:
	if car_i >= 0:
		var at := car.sim.pos
		var h := car.sim.heading
		_spawn_car(car_i, at, h)
		_teleport(at, h)
	SaveGame.write(save)

## Orders from ROCKAUTTO.CA arrive on the game clock and wait on the bench.
func _deliveries(dt: float) -> void:
	if free_roam: _keep_calendar()
	save.clock_h = float(save.get("clock_h", 0.0)) + dt * sky.rate
	var left: Array = []
	for o in save.get("orders", []):
		if float(save.clock_h) >= float(o.arrives_h):
			if bool(o.get("dud", false)):
				hud.post("GUS: \"THAT %s FROM LLOYD'S? %s. IT'S IN THE SCRAP BIN.\"" % [Parts.name_of(String(o.part)), String(o.get("why", "IT'S JUNK"))], 7.0)
				continue
			save.shelf.append(o.part)
			if o.get("yard", false): hud.post("GUS: \"THE YARD TRUCK DROPPED OFF A %s. IT'S DIRTY, BUT IT'S ON THE BENCH.\"" % Parts.name_of(String(o.part)), 6.0)
			else: hud.post("GUS: \"A BOX CAME FOR YOU. %s. IT'S ON THE BENCH.\"" % Parts.name_of(String(o.part)), 6.0)
		else:
			left.append(o)
	save.orders = left
	# Gus finishing an install: the part goes on, and the car you're in gets it right away
	for d in SaveGame.finish_installs(save):
		var ci: int = d[0]
		var spec_d := SaveGame.load_spec(String(save.garage[ci].id))
		hud.post("GUS: \"THE %s IS IN THE %s. GO GIVE IT THE BEANS.\"" % [Parts.name_of(String(d[1])), String(spec_d.get("model", "CAR")).to_upper()], 7.0)
		if ci == car_i and not garage.visible:
			_store_car()
			var at := car.sim.pos
			var h := car.sim.heading
			_spawn_car(car_i, at, h)
			_teleport(at, h)
			car.sim.set_world_velocity(Vector2.ZERO)
		SaveGame.write(save)

func _on_garage_repair(i: int) -> void:
	if i == car_i: _store_car()
	# the body's on the house; worn parts aren't
	var w: Dictionary = save.garage[i].get("wear", {})
	var turbo := not (SaveGame.car_spec(save.garage[i]).engine.get("turbo", {}) as Dictionary).is_empty()
	var jobs: Array = []
	var cost := 0
	if float(w.get("pads", 10.0)) < 6.0:
		jobs.append("PADS")
		cost += 140
	if float(w.get("fluid", 1.0)) < 0.8:
		jobs.append("FLUID")
		cost += 60
	if float(w.get("clutch", 1.0)) < 0.7:
		jobs.append("CLUTCH")
		cost += 520
	if turbo and float(w.get("turbo", 1.0)) < 0.7:
		jobs.append("TURBO REBUILD")
		cost += 780
	if bool(w.get("gasket", false)):
		jobs.append("HEAD GASKET")
		cost += 900
	if bool(w.get("axle", false)):
		jobs.append(CarSim.axle_name(String(SaveGame.car_spec(save.garage[i]).get("drivetrain", "RWD"))))
		cost += 380
	if float(w.get("engine", 1.0)) < 0.7:
		jobs.append("ENGINE REBUILD")
		cost += 1500
	if w.has("tread") and float(w.tread) < 3.0:
		jobs.append("TIRES")
		cost += 480
	if cost > 0:
		if int(save.cash) >= cost:
			save.cash = int(save.cash) - cost
			save.garage[i].wear = {}
			garage._say("GUS: \"%s. $%d. AND I FIXED THE DENTS FOR FREE.\"" % [", ".join(jobs), cost])
		else:
			garage._say("GUS: \"IT NEEDS %s. THAT'S $%d. COME BACK WITH MONEY. DENTS ARE FIXED.\"" % [", ".join(jobs), cost])
	for k in save.garage[i].damage: save.garage[i].damage[k] = 0.0
	if i == car_i:
		for k in car.damage: car.damage[k] = 0.0
		car.damage_bucket = -2
		car.sim.reset_parts()
		car.sim.set_wear(save.garage[i].get("wear", {}))       # unpaid wear stays worn
	SaveGame.write(save)

func _exit_tree() -> void:
	if StoryState.active: return
	_store_car()
	SaveGame.write(save)

## The car you're in is gone (pink slips): you get dropped at Gus's in whatever's left.
func lose_current_car() -> void:
	var i := car_i
	if i < 0 or i >= (save.garage as Array).size(): return
	# lost at pinks while it was up on MarketThing: the ad comes down with it
	var ad := Market.ad_for(save, i)
	if not ad.is_empty(): Market.unlist(save, ad)
	(save.garage as Array).remove_at(i)
	car_i = -1
	var next := 0
	for k in (save.garage as Array).size():
		if String(save.garage[k].id) != "tow":
			next = k
			break
	save.current = next
	_spawn_car(next, START, -PI / 2.0)
	_teleport(START, -PI / 2.0)
	hud.post("MARCO'S COUSIN DROPS YOU AT GUS'S. GUS DOESN'T ASK. GUS KNOWS.", 6.0)

## A car went out of the garage on MarketThing: everything after it moved up a slot.
func _on_car_sold(index: int, text: String) -> void:
	Awards.bump("cars_sold")
	if car_i > index: car_i -= 1
	hud.post(text, 6.0)
	SaveGame.write(save)

func _on_job_picked(k: String) -> void:
	jobs.start(k)

## A job can put you in a different car (the tow calls take Toby's wrecker) and give yours back.
func job_swap_car(id: String) -> void:
	_store_car()
	var at := car.sim.pos
	var h := car.sim.heading
	_spawn_story_car(id, at, h)
	_teleport(at, h)

func job_restore_car(msg := "TOBY TAKES THE WRECKER BACK. YOUR OWN KEYS FEEL LIGHT.") -> void:
	var at := car.sim.pos
	var h := car.sim.heading
	car_i = -1
	_spawn_car(int(save.get("current", 0)), at, h)
	_teleport(at, h)
	hud.post(msg, 4.0)

func clear_route() -> void:
	dest = { "name": "", "p": Vector2.ZERO }
	gps.set_route(PackedVector2Array(), "")

func _on_dest(name: String, at: Vector2, quiet := false) -> void:
	dest = { "name": name, "p": at }
	gps.set_route(world.map.route(car.sim.pos, at), name)

func _weather(col: Color, vel: Vector2, amount: int, size: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 2.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(620, 360)
	p.direction = vel.normalized()
	p.spread = 6.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel.length() * 0.8
	p.initial_velocity_max = vel.length() * 1.2
	p.color = col
	p.scale_amount_min = 1.0 + size
	p.scale_amount_max = 1.5 + size
	p.z_index = 3200
	p.emitting = false
	if size == 0.0:
		var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		p.texture = ImageTexture.create_from_image(img)
	cam.add_child(p)
	return p

func _tip_used(key: String) -> void:
	var seen: Array = save.get("tips_seen", [])
	if not seen.has(key):
		seen.append(key)
		save.tips_seen = seen

## The settings the drive scene follows (Settings: difficulty, UI, graphics), at start and on change.
## A wheel's plugged in that's never been set up: say where to set it up (it doesn't steer yet,
## and it never runs a menu).
func _wheel_found(nm: String) -> void:
	hud.post("WHEEL FOUND: %s. SET IT UP: %s, THEN SET UP THE WHEEL." % [nm.to_upper().substr(0, 28), Hints.fmt("{pause}")], 7.0)

func _apply_settings(_section := "") -> void:
	hud.verbosity = GameSettings.chatter_level()
	hud.show_diag = bool(GameSettings.get_v("ui", "scan_tool"))
	zoom_mult = float(GameSettings.get_v("ui", "camera_zoom"))
	police.strictness = GameSettings.police_strictness()
	wildlife.rate = GameSettings.wildlife_rate()
	# rain and snow: fewer drops at half (changing the count restarts them, so only on a change)
	var wx := GameSettings.weather_amount()
	for fx: CPUParticles2D in [rain_fx, snow_fx]:
		if not fx.has_meta("full"): fx.set_meta("full", fx.amount)
		var n := maxi(1, int(int(fx.get_meta("full")) * maxf(wx, 0.1)))
		if fx.amount != n: fx.amount = n
	clouds.visible = bool(GameSettings.get_v("graphics", "clouds"))
	skids.visible = bool(GameSettings.get_v("graphics", "skids"))
	sight.on = bool(GameSettings.get_v("graphics", "sight"))
	if car: _apply_car_settings()

## The car you're in: the driving aids and the gearbox you picked.
func _apply_car_settings() -> void:
	car.sim.assist = GameSettings.assist()
	car.sim.auto_gearbox = not GameSettings.manual()
	car.smoke_on = bool(GameSettings.get_v("graphics", "smoke"))

## Employee of the Month: check now and then; a new one goes up on the HUD right away, and its
## card comes up the next time you're stopped with nothing else going on.
func _awards(dt: float) -> void:
	if not awards_on: return
	_award_t -= dt
	if _award_t <= 0.0:
		_award_t = 2.0
		for id in Awards.check(save):
			awards_due.append(id)
			hud.notify("EMPLOYEE OF THE MONTH: %s" % String(Awards.by_id(id).name), "award", 2, 5.0)
	if awards_due.is_empty() or _dying or StoryState.active: return
	# stopped (an automatic creeps at idle), and nothing else going on
	if car.sim.speed() > 1.5 or modal_open() or jobs.active() or police.chasing(): return
	hud.stepped_aside = true
	dash.visible = false
	gps.visible = false
	hud.queue_redraw()
	police.hud_panel.queue_redraw()
	award_card.open(String(awards_due.pop_front()))

## ESC / START: everything on the screen steps aside (the game stops, so it won't on its own).
func _pause() -> void:
	hud.stepped_aside = true
	dash.visible = false
	gps.visible = false
	hud.queue_redraw()
	police.hud_panel.queue_redraw()
	pause_menu.open()

## Pause > Quit to title: save where you are first (not mid-story: the story saves itself).
func _quit_to_title() -> void:
	get_tree().paused = false
	if not StoryState.active:
		_store_car()
		if free_roam: _keep_calendar()
		SaveGame.write(save)
	StoryState.active = false
	get_tree().change_scene_to_file("res://title.tscn")

## Whether a menu or a panel has the screen (the HUD hides under it).
func modal_open() -> bool:
	return job_board.visible or market.panel_open() or (jobs.strip != null and jobs.strip.state in ["signin", "slip"]) \
		or fuel.open() or salvage.open() or auction.open() or luchadooros.open() or (jobs.meet != null and jobs.meet.state == "results") \
		or map_screen.visible or death.visible or (garage != null and garage.visible) or pause_menu.visible or award_card.visible

## First-run tips, once a save: after a few seconds of plain driving (no job, no race, no chase),
## one at a time, and never one you've already used.
## The GPS keeps up with you: take another road and it works out a new way from where you are
## (like a real one, "rerouting"), and a place you picked off the map clears when you get there.
var _gps_t := 0.0
func _gps_upkeep(dt: float) -> void:
	if String(dest.name) == "" or car == null: return
	_gps_t += dt
	if _gps_t < 1.0: return
	_gps_t = 0.0
	var p := car.sim.pos
	# arrived (a place off the map; jobs and the story say when you've arrived themselves)
	if free_roam and not StoryState.active and not jobs.active() and p.distance_to(dest.p) < 28.0 and car.sim.speed() < 6.0:
		hud.notify("YOU'VE ARRIVED: %s." % String(dest.name), "status", 1, 3.0)
		clear_route()
		return
	var r: PackedVector2Array = gps.route
	if r.size() < 2: return
	var off := INF
	for i in r.size() - 1: off = minf(off, p.distance_to(Geometry2D.get_closest_point_to_segment(p, r[i], r[i + 1])))
	# off the route, but on a road (off-road in a field there's no better way to give)
	if off > 35.0 and not world.map.nearest_road(p, 20.0).is_empty():
		gps.set_route(world.map.route(p, dest.p), String(dest.name))
		hud.diag_event("GPS: REROUTING")

## In the story, people notice when Leo turns into somebody else: say so when his tier changes.
var _karma_tier := ""
func _karma_watch() -> void:
	if not StoryState.active: return
	var t := Karma.tier()
	if _karma_tier != "" and t != _karma_tier:
		var line := ""
		match t:
			"low": line = "WORD GETS AROUND: PEOPLE ARE CALLING LEO RECKLESS. GUS HAS HEARD. SO HAS FRANKIE."
			"high": line = "WORD GETS AROUND: LEO'S COOL, CALM AND COLLECTED. FRANKIE'S WATCHING HOW HE DOES IT."
			_: line = "PEOPLE ARE GIVING LEO ANOTHER LOOK." if _karma_tier == "low" else "PEOPLE ARE STARTING TO WONDER ABOUT LEO."
		hud.notify(line, "status", 2, 6.0)
	_karma_tier = t

## Free roam with nothing on: say what you can do, so there's always a next step on the screen.
const IDLE_LINE := "FREE DRIVE. {jobs}: GIGS FOR MONEY. {map}: THE MAP. THE GARAGE IS AT COVINGTON AUTO."
var _auto_obj := ""                 # the line this put up (it only ever replaces its own)
func _idle_objective() -> void:
	var want := ""
	if free_roam and not StoryState.active and not jobs.active():
		want = Hints.fmt(IDLE_LINE) if String(dest.name) == "" else "HEADING TO %s. THE GPS HAS THE WAY." % String(dest.name)
	if hud.objective == "" or hud.objective == _auto_obj:
		hud.objective = want
		_auto_obj = want

const TIPS := [
	["map", "{map}: THE MAP. PICK A PLACE AND THE GPS TAKES YOU THERE."],
	["jobs", "{jobs}: GIGS. PIZZA, TOW CALLS, RIDES, RACES."],
	["help", "{help}: THE CONTROLS, WHENEVER YOU NEED THEM."],
	["diag", "THE SCAN TOOL UNDER THE DASH SHOWS WHAT YOUR CAR IS COMPLAINING ABOUT."],
]
var _tip_t := 0.0
func _tips(dt: float) -> void:
	if not free_roam or StoryState.active or jobs.active() or police.chasing() or hud.stepped_aside: return
	if not bool(GameSettings.get_v("ui", "tips")): return
	if not hud.msgs.is_empty() or car.sim.speed() < 2.0:
		return
	_tip_t += dt
	if _tip_t < 8.0: return
	_tip_t = 0.0
	var seen: Array = save.get("tips_seen", [])
	for t in TIPS:
		if seen.has(t[0]): continue
		# used it already: no need to say
		if (t[0] == "map" and map_screen.visible) or (t[0] == "jobs" and job_board.visible): continue
		seen.append(t[0])
		save.tips_seen = seen
		hud.notify(Hints.fmt(String(t[1])), "tip")
		return

## Gas and brake together at a standstill in a car that can't do a brake burnout: say so, once a
## save, and what it can do instead.
var _bo_t := 0.0
func _burnout_tip(dt: float) -> void:
	var dts := String(car.spec.get("drivetrain", "RWD"))
	if dts == "RWD" or car.sim.speed() > 1.0 or Controls.trigger("throttle") < 0.6 or Controls.trigger("brake") < 0.6:
		_bo_t = 0.0
		return
	_bo_t += dt
	var key := "burnout_" + ("fwd" if dts == "FWD" else "awd")
	var seen: Array = save.get("tips_seen", [])
	if _bo_t < 1.2 or seen.has(key): return
	seen.append(key)
	save.tips_seen = seen
	if dts == "FWD":
		hud.notify(Hints.fmt("FRONT-WHEEL DRIVE: THE BRAKES HOLD THE WHEELS THAT DRIVE. NO BURNOUT. ROLL BACK IN REVERSE, {shift_up} INTO DRIVE AND STAB THE GAS. IF YOU TRUST YOUR CV AXLES."), "tip")
	else:
		hud.notify("ALL-WHEEL DRIVE: THE BRAKES HOLD ALL FOUR. NO BURNOUT. AWD IS FOR DRIFTING: A REAR-BIASED CENTRE DIFF LETS THE BACK STEP OUT.", "tip")

## A burnout on the HUD: the seconds while it lasts, the time when it's done (a good one is remembered).
func _burnout_count() -> void:
	if car.burn_t > 1.0: hud.prompt("BURNOUT  %.1f S" % car.burn_t)
	if car.burn_last > 0.0:
		var secs := car.burn_last
		car.burn_last = 0.0
		if secs < 3.0: return
		var best := float(save.get("burnout_best", 0.0))
		if secs > best:
			save.burnout_best = secs
			hud.notify("BURNOUT: %.1f S. YOUR BEST. THE NEIGHBOURS HAVE OPINIONS." % secs, "status", 1, 4.0)
		else:
			hud.notify("BURNOUT: %.1f S (BEST %.1f)." % [secs, best], "status", 1, 3.0)

## Free roam picks up the calendar where the last session left it: the day (so Saturday's auction
## is still on Saturday), the hour and the season.
func _restore_calendar() -> void:
	var c: Dictionary = save.get("cal", {})
	if c.is_empty(): return
	sky.day = int(c.get("day", 0))
	sky.set_season(String(c.get("season", "fall")))
	sky._season_day = int(c.get("season_day", 0))
	sky.time_h = float(c.get("time_h", 17.5))

func _keep_calendar() -> void:
	save.cal = { "day": sky.day, "time_h": sky.time_h, "season": sky.season, "season_day": sky._season_day }

func _apply_season(s: String, reset := true) -> void:
	if reset: sky.set_season(s)
	car.sim.set_ambient(sky.temperature())
	skids.clear()
	var tips := {
		"summer": "SUMMER. GRIP EVERYWHERE. THUNDERSTORMS ROLL IN AFTER HOT DAYS.",
		"fall": "FALL. WET LEAVES ARE ICE WITH A NICER COLOUR. FOG ON THE RIVER.",
		"winter": "WINTER. SNOW, BLIZZARDS, FREEZING RAIN. SUMMER TIRES ARE HOCKEY PUCKS: GUS SELLS WINTERS.",
		"spring": "SPRING. RAIN, MUD AND POTHOLES. FREEZING RAIN ON COLD NIGHTS.",
	}
	hud.notify(tips[s], "tip")

func _process(dt: float) -> void:
	if garage and garage.visible:
		CarView.screen_up = Vector2(0, -1)      # the garage is drawn straight on
		return
	sky.step(dt)
	if sky.season != _season_seen:
		if _season_seen != "": _apply_season(sky.season, false)
		_season_seen = sky.season
	# a menu or a panel is up: the HUD steps aside rather than poking out round its edges
	var modal := modal_open()
	hud.stepped_aside = modal
	dash.visible = not modal
	gps.visible = not modal
	_tips(dt)
	_gps_upkeep(dt)
	_idle_objective()
	_karma_watch()
	_burnout_tip(dt)
	_burnout_count()
	_awards(dt)
	# the chase cam: behind the car and turning with it, so up on the screen is always ahead.
	# It swings round a little slower than the car, so you can see a slide happen.
	var target := car.sim.heading + PI / 2.0
	if car.sim.vx < -2.0: target = cam_rot      # reversing: don't spin the world around
	cam_rot = lerp_angle(cam_rot, target, 1.0 - exp(-3.2 * dt))
	cam.rotation = cam_rot
	if car.impaired > 0.0:
		# the world won't hold still
		var tt := Time.get_ticks_msec() / 1000.0
		cam.rotation += sin(tt * 0.7) * 0.07 * car.impaired
		blur_rect.visible = bool(GameSettings.get_v("graphics", "blur"))
		blur_rect.material.set_shader_parameter("amount", car.impaired * (0.7 + 0.3 * sin(tt * 1.3)))
		blur_rect.material.set_shader_parameter("offset", Vector2(sin(tt * 0.9), cos(tt * 0.6)) * 0.012 * car.impaired)
	else:
		blur_rect.visible = false
	var up := Vector2(0, -1).rotated(cam_rot)
	CarView.screen_up = up
	var spd := car.sim.speed()
	var ahead := up * HudLayout.look_ahead(spd)     # see more of what's ahead, more as you go faster
	if _dying:
		# the death cam: in close on the wreck
		cam.global_position = cam.global_position.lerp(car.global_position, minf(1.0, 3.0 * dt / maxf(Engine.time_scale, 0.05)))
		cam.zoom = cam.zoom.lerp(Vector2(2.6, 2.6), minf(1.0, 2.5 * dt / maxf(Engine.time_scale, 0.05)))
	else:
		cam.global_position = car.global_position + ahead
		var z := HudLayout.zoom_at(spd) * zoom_mult        # in close; pulls back with speed
		cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.5 * dt)
	var r := Vector2(320, 180).length() / cam.zoom.x
	var half_px := Vector2(r, r)
	traffic.step(dt, cam.global_position / PX)
	# the GPS shows the police (flashing when they're after you) and whoever you're racing
	var bl: Array = []
	var flash := fmod(Time.get_ticks_msec() / 250.0, 2.0) < 1.0
	for k in police.cruisers:
		bl.append([k.sim.pos, (Color(1, 0.2, 0.15) if flash else Color(0.3, 0.5, 1.0)) if k.siren else Color(0.35, 0.5, 0.95)])
	if jobs.race:
		for a in jobs.race.racers: bl.append([a.sim.pos, Color("d9a441")])
	gps.blips = bl
	if not StoryState.active: _deliveries(dt)
	_save_t -= dt
	if _save_t <= 0.0 and not StoryState.active:
		_save_t = 30.0
		_store_car()
		SaveGame.write(save)
	_depth_sort(up)
	sight.update_sight(dt, car.global_position, r)
	# the blinker relay clicks
	var b_on := CarView.blink_on() and (car.view.blink_left or car.view.blink_right)
	if b_on != _blink_was:
		_blink_was = b_on
		audio.tick = 1.0
	world.update_view(cam.global_position / PX, half_px / PX)
	# light: the sky colour, the lights, headlights, windows
	dark.color = sky.ambient_color()
	var lamps := sky.lights_on(30)
	if lamps != night:
		night = lamps
		world.set_night(night)
	car.lights_on = night or sky.fog > 0.4 or sky.rain > 0.5 or sky.snow > 0.5
	car.tail_light.visible = car.lights_on or car.view.braking
	_light_t -= dt
	if _light_t <= 0.0:
		_light_t = 0.12
		lights.refresh(cam.global_position, half_px)
	lights.animate(dt)
	dash.lit = night
	dash.beacons = car.beacons
	# the weather you can see
	var wind := sky.wind_dir * sky.wind
	var wx := GameSettings.weather_amount()
	rain_fx.emitting = sky.rain > 0.08 and wx > 0.0
	snow_fx.emitting = sky.snow > 0.08 and wx > 0.0
	rain_fx.modulate.a = clampf(sky.rain * 1.3, 0.2, 1.0)
	snow_fx.modulate.a = clampf(sky.snow * 1.3, 0.25, 1.0)
	rain_fx.direction = (Vector2(wind.x * 6.0, 260)).normalized()
	snow_fx.direction = (Vector2(wind.x * 3.0, 28 + absf(wind.y))).normalized()
	snow_fx.initial_velocity_min = 24.0 + sky.wind * 4.0
	snow_fx.initial_velocity_max = 34.0 + sky.wind * 6.0
	var fogc := Color(0.75, 0.77, 0.8) if sky.daylight() > 0.4 else Color(0.18, 0.2, 0.26)
	if sky.snow > 0.5: fogc = Color(0.9, 0.92, 0.96) if sky.daylight() > 0.4 else Color(0.3, 0.32, 0.4)
	fog_rect.color = Color(fogc.r, fogc.g, fogc.b, sky.fog * 0.55)
	white_out = maxf(0.0, white_out - dt * 0.8)
	flash_rect.color = Color(1, 1, 1, maxf(white_out, sky.flash * 0.55 * (1.0 if bool(GameSettings.get_v("graphics", "flashes")) else 0.0)))
	if sky.thunder_in >= 0.0 and sky.thunder_in < dt:
		Controls.rumble(0.4, 0.8, 0.6)
	# the car's world
	car.sim.set_ambient(sky.temperature())
	hud.surface = car.sim.surface
	hud.place = world.map.zone_at(car.sim.pos).label if world.map.zone_at(car.sim.pos).label != "" else "COUNTRY"
	audio.throttle = car.throttle_in
	# into the river (when the car can't die there, Toby tows you out instead)
	if car.sim.surface == "water" and (not car.can_die or car.sim.assist == CarSim.Assist.ARCADE):
		_water_t += dt
		if _water_t > 1.2:
			_water_t = 0.0
			hud.post("YOU DROVE INTO THE CHOCOLATE RIVER. TOBY TOWS YOU OUT. AGAIN.", 5.0)
			var rd := world.map.nearest_road(car.sim.pos, 400.0)
			if not rd.is_empty(): _teleport(rd.point, rd.dir.angle())
	else:
		_water_t = 0.0
	# Magnet Hill: on the hill road, the car rolls "uphill" (it's an optical illusion; so is this)
	if car.sim.pos.distance_to(Vector2(5080, 800)) < 60.0 and car.throttle_in < 0.05 and car.sim.speed() < 6.0:
		car.sim.set_world_velocity(car.sim.world_velocity() + Vector2(-0.6, -0.5).normalized() * 0.9 * dt)
	_inputs()

## Cars and buildings drawn back to front along the camera's view (y-sort, but for a camera
## that turns).
func _depth_sort(up: Vector2) -> void:
	var c := cam.global_position
	for n in ysort.get_children():
		if not (n is Node2D) or n.has_meta("no_sort"): continue        # (tire smoke keeps itself under its car)
		var p: Vector2 = n.sort_point() if n.has_method("sort_point") else n.global_position
		n.z_index = 1000 + clampi(int((p - c).dot(-up) / 2.0), -950, 950)

## Put the car somewhere, stopped dead: the body and the wheels too (wheels left spinning from
## before would drive it off again, or creep it out of a parking spot with the handbrake on).
func _teleport(at: Vector2, heading: float) -> void:
	car.sim.vx = 0.0
	car.sim.vy = 0.0
	car.sim.yaw_rate = 0.0
	car.sim.w_wheel = 0.0
	car.sim.front_w = 0.0
	car.sim.clutch_locked = false
	car.sim.pos = at
	car.sim.heading = heading
	cam_rot = heading + PI / 2.0
	car.position = at * PX
	cam.global_position = car.global_position
	cam.reset_smoothing()
	world.warm(at, Vector2(40, 25))

func _inputs() -> void:
	if car: car.locked = job_board.visible or market.panel_open() or (jobs.strip != null and jobs.strip.state in ["signin", "slip"]) \
		or (jobs.race != null and jobs.race.holding()) or police.writing() or hold_car or fuel.open() or salvage.open() or auction.open() or luchadooros.open() \
		or (jobs.meet != null and jobs.meet.state == "results")
	if garage.visible or death.visible or car.dead: return
	if job_board.visible or market.panel_open() or fuel.open() or salvage.open() or auction.open() or luchadooros.open(): return
	if Input.is_action_just_pressed("jobs") and not StoryState.active and jobs.strip == null and market.stage != "test":
		_tip_used("jobs")
		job_board.open(sky, save, jobs.kind, Market.places(world.map))
		return
	# the garage: pull up to the bay doors and stop
	if not StoryState.active and GARAGE_DOOR.has_point(car.sim.pos) and car.sim.speed() < 2.0:
		hud.prompt(Hints.fmt("{use}: THE GARAGE"))
		if Input.is_action_just_pressed("use"):
			_store_car()
			garage.open(save)
			return
	if Input.is_action_just_pressed("map"):
		_tip_used("map")
		if map_screen.visible: map_screen.visible = false
		else:
			# what you're meant to be doing goes on the map too
			map_screen.current_name = String(dest.name)
			map_screen.current_p = dest.p if String(dest.name) != "" else Vector2.INF
			map_screen.open()
	if map_screen.visible: return
	if Input.is_action_just_pressed("gearbox"):
		car.sim.auto_gearbox = not car.sim.auto_gearbox
		hud.diag_event("GEARBOX: AUTOMATIC" if car.sim.auto_gearbox else Hints.fmt("GEARBOX: MANUAL. {shift} TO SHIFT"))
		GameSettings.set_v("controls", "transmission", "auto" if car.sim.auto_gearbox else "manual")
		GameSettings.save_file()
	if Input.is_action_just_pressed("help"):
		_tip_used("help")
		hud.show_help = not hud.show_help
	if Input.is_action_just_pressed("reset") and police.chasing():
		hud.post("TOBY ISN'T TOWING YOU OUT OF A POLICE CHASE.", 3.0)
	elif Input.is_action_just_pressed("reset") and fuel.out_of_gas() and car.sim.speed() < 1.0:
		fuel.jerry_can()
	elif Input.is_action_just_pressed("reset"):
		car.respawn()
		world.warm(car.sim.pos, Vector2(40, 25))
	if Input.is_action_just_pressed("pause") and not _dying:
		_pause()
		return
	audio.horn = Input.is_action_pressed("horn")
	# an H-shifter: a gear's button held is that gear; let go and it's in neutral
	for gi in Controls.GEARS.size():
		var act: String = Controls.GEARS[gi][0]
		var g := -1 if act == "gear_r" else gi + 1
		if Input.is_action_just_pressed(act):
			car.sim.auto_gearbox = false
			if g >= 0 or absf(car.sim.vx) < 1.5: car.sim.shift(g)
		elif Input.is_action_just_released(act) and car.sim.gear == g:
			car.sim.shift(0)
	if not car.sim.auto_gearbox:
		if Input.is_action_just_pressed("shift_up"): car.sim.shift(car.sim.gear + 1)
		if Input.is_action_just_pressed("shift_down"): car.sim.shift(car.sim.gear - 1)
	elif car.sim.gear < 0 and Input.is_action_just_pressed("shift_up"):
		car.sim.shift(1)          # the lever from R to D, rolling or not (a front-driver's only burnout)


## Cloud shadows drifting over everything on a cloudy day.
class Clouds extends Node2D:
	var sky: WorldSky
	var tex: GradientTexture2D
	var off := Vector2.ZERO
	func _ready() -> void:
		tex = World.light_tex(Color(0, 0, 0))
	func _process(dt: float) -> void:
		off += sky.wind_dir * (2.0 + sky.wind) * dt * CarArt.PX
		queue_redraw()
	func _draw() -> void:
		var a := sky.cloud * 0.22 * sky.daylight() * (1.0 - sky.rain * 0.6)
		if a < 0.01: return
		var cam := get_viewport().get_camera_2d()
		if cam == null: return
		var c := cam.global_position
		var cell := 900.0
		var base := ((c - off) / cell).floor()
		for y in range(-2, 3):
			for x in range(-2, 3):
				var k := base + Vector2(x, y)
				var h := int(absf(k.x * 7919.0 + k.y * 104729.0)) % 1000
				var p := k * cell + off + Vector2(h % 300, (h * 7) % 300)
				var s := 500.0 + float(h % 400)
				draw_texture_rect(tex, Rect2(p - Vector2(s, s * 0.6), Vector2(s * 2.0, s * 1.2)), false, Color(1, 1, 1, a))
