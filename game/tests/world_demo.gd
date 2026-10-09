## Screenshots around the map: godot --path game -- --world-demo <out_dir>
## Teleports to places, sets the time, season and weather, switches cars, and saves a frame.
extends Node

var main: Node
var out := "user://world_shots"

const SHOTS := [
	# name, where, heading, season, hour, weather, car, map open
	["covington_dusk", Vector2(5580, 1577), -1.57, "fall", 18.4, "cloudy", 0, false],
	["downtown_night_led_neon", Vector2(6075, 1528), 0.0, "summer", 22.5, "clear", 0, false],
	["main_st_rain_night", Vector2(6150, 1522), 2.9, "fall", 21.0, "rain", 1, false],
	["causeway_day", Vector2(5700, 1680), 1.57, "summer", 13.0, "clear", 2, false],
	["salisbury_snow_day", Vector2(3440, 2150), 3.3, "winter", 11.0, "snow", 3, false],
	["big_stop_night", Vector2(3530, 2010), 0.5, "winter", 20.5, "clear", 0, false],
	["havelock_fog_night", Vector2(805, 2745), 3.14, "fall", 23.0, "fog", 1, false],
	["route_880_storm", Vector2(2400, 2390), 3.3, "summer", 16.0, "storm", 2, false],
	["tch_interchange_night", Vector2(5180, 860), 3.0, "spring", 1.0, "drizzle", 3, false],
	["casino_night", Vector2(5300, 760), -0.5, "summer", 23.5, "clear", 2, false],
	["mall_lot_night", Vector2(6680, 1300), 0.0, "winter", 2.0, "freezing", 0, false],
	["industrial_storm_night", Vector2(6280, 980), 1.0, "summer", 0.5, "storm", 1, false],
	["airstrip_dawn", Vector2(6700, 1022), 0.0, "spring", 6.6, "fog", 2, false],
	["map_screen", Vector2(5580, 1577), -1.57, "fall", 12.0, "clear", 0, true],
]
const ROAD_SHOTS := [
	["dt_intersection", Vector2(5970, 1445), 0.0],
	["dt_main_mountain", Vector2(5950, 1540), 0.0],
	["northend_grid", Vector2(5860, 1250), 0.0],
	["rural_curve_106", Vector2(4800, 1765), 0.0],
	["lutes_rd", Vector2(4550, 1450), 1.57],
	["tch_mountain_interchange", Vector2(5180, 860), 0.0],
	["tch_rural", Vector2(4000, 1400), 0.0],
	["salisbury_center", Vector2(3440, 2130), 0.0],
	["salisbury_bridge", Vector2(3440, 2230), 1.57],
	["havelock_cross", Vector2(805, 2750), 0.0],
	["gravel_backroad", Vector2(2300, 2000), 1.57],
	["riverside_coverdale", Vector2(5800, 1786), 0.0],
	["dieppe_wheeler", Vector2(6500, 1300), 0.0],
	["causeway_end", Vector2(5700, 1600), 1.57],
	["map_edge_106", Vector2(2880, 3260), 1.57],
	["covington_corner", Vector2(5540, 1520), 0.0],
]
var shots: Array = SHOTS
var i := -1
var wait := 0.0

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var k := a.find("--world-demo")
	if k >= 0 and k + 1 < a.size(): out = a[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	main.hud.show_help = false
	if a.has("--roads"):
		shots = []
		for r in ROAD_SHOTS: shots.append([r[0], r[1], r[2], "summer", 12.0, "clear", 0, false])
		main.get_node("HudLayer").visible = false

func _process(dt: float) -> void:
	wait -= dt
	if wait > 0.0: return
	if i >= 0:
		get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, i, shots[i][0]])
	i += 1
	if i >= shots.size():
		print("WORLD DEMO DONE")
		get_tree().quit()
		return
	var s: Array = shots[i]
	main.map_screen.visible = false
	main._spawn_car(s[6], s[1], s[2])
	main.sky.set_season(s[3])
	main.sky.pick_weather(s[5])
	main.sky.forced = true
	main.sky.time_h = s[4]
	# let the weather settle in fully
	var w: Dictionary = WorldSky.WEATHER[s[5]]
	main.sky.cloud = w.cloud; main.sky.fog = w.fog; main.sky.rain = w.rain; main.sky.snow = w.snow; main.sky.wind = w.wind
	if s[5] in ["rain", "storm", "drizzle"]: main.sky.wet = 0.8
	if s[5] == "freezing": main.sky.ice = 0.6
	if s[5] == "storm": main.sky.flash = 0.0
	main._teleport(s[1], s[2])
	if s[7]:
		main._on_dest("HAVELOCK", Vector2(805, 2755))
		main.map_screen.open()
	elif shots == SHOTS and (i == 2 or i == 4):
		main._on_dest("HAVELOCK", Vector2(805, 2755))
	wait = 1.4
	if shots != SHOTS:
		main.zoom_mult = 0.5
		main.cam.zoom = Vector2(0.5, 0.5)
		wait = 2.5
