## Time of day and the weather. Pure logic (no nodes), so it runs the same in tests.
##
## The clock runs at one game minute per real second (a day is 24 minutes). Sunrise and
## sunset follow Moncton's real ones for each season. Weather drifts from one state to the
## next on its own, and leaves things behind on the road: water, snow, black ice.
class_name WorldSky
extends RefCounted

const SUN := { "summer": [5.5, 21.1], "fall": [7.3, 18.6], "winter": [7.9, 16.6], "spring": [6.5, 20.0] }
const BASE_TEMP := { "summer": 22.0, "fall": 8.0, "winter": -9.0, "spring": 5.0 }

const WEATHER := {
	"clear":    { "cloud": 0.05, "rain": 0.0, "snow": 0.0, "fog": 0.0,  "wind": 2.0,  "label": "CLEAR" },
	"cloudy":   { "cloud": 0.75, "rain": 0.0, "snow": 0.0, "fog": 0.0,  "wind": 4.0,  "label": "OVERCAST" },
	"drizzle":  { "cloud": 0.85, "rain": 0.3, "snow": 0.0, "fog": 0.15, "wind": 3.0,  "label": "DRIZZLE" },
	"rain":     { "cloud": 0.92, "rain": 0.7, "snow": 0.0, "fog": 0.1,  "wind": 7.0,  "label": "RAIN" },
	"storm":    { "cloud": 1.0,  "rain": 1.0, "snow": 0.0, "fog": 0.05, "wind": 13.0, "label": "THUNDERSTORM" },
	"fog":      { "cloud": 0.5,  "rain": 0.0, "snow": 0.0, "fog": 0.85, "wind": 0.6,  "label": "FOG" },
	"snow":     { "cloud": 0.9,  "rain": 0.0, "snow": 0.6, "fog": 0.15, "wind": 4.0,  "label": "SNOW" },
	"blizzard": { "cloud": 1.0,  "rain": 0.0, "snow": 1.0, "fog": 0.5,  "wind": 17.0, "label": "BLIZZARD" },
	"freezing": { "cloud": 0.92, "rain": 0.6, "snow": 0.0, "fog": 0.1,  "wind": 5.0,  "label": "FREEZING RAIN" },
}
# how likely each weather is, by season
const ODDS := {
	"summer": { "clear": 45, "cloudy": 22, "drizzle": 6, "rain": 10, "storm": 9, "fog": 8 },
	"fall":   { "clear": 22, "cloudy": 28, "drizzle": 10, "rain": 20, "storm": 4, "fog": 16 },
	"winter": { "clear": 24, "cloudy": 28, "snow": 26, "blizzard": 10, "freezing": 8, "fog": 4 },
	"spring": { "clear": 24, "cloudy": 28, "drizzle": 12, "rain": 22, "fog": 9, "freezing": 5 },
}

var season := "summer"
var day := 0                   # days since the start
const SEASON_DAYS := 4         # a season lasts four game days (about an hour and a half)
const SEASON_ORDER := ["summer", "fall", "winter", "spring"]
var _season_day := 0
var time_h := 8.0              # 0..24
var rate := 1.0 / 60.0         # game hours per real second
var weather := "clear"
var weather_left := 3.0        # game hours until the weather turns
var forced := false

# what the air is doing right now (blends toward the current weather)
var cloud := 0.05
var rain := 0.0
var snow := 0.0
var fog := 0.0
var wind := 2.0
var wind_dir := Vector2(-1, 0.3).normalized()

# what's left on the road
var wet := 0.0
var snow_cover := 0.0
var ice := 0.0

var flash := 0.0               # lightning, 0..1
var thunder_in := -1.0         # seconds until the thunder after a flash (-1 = none)
var _next_strike := 6.0
var rng := RandomNumberGenerator.new()

func _init(seed := 506) -> void:
	rng.seed = seed

func set_season(s: String) -> void:
	season = s
	# start each season the way it usually looks
	match s:
		"summer": wet = 0.0; snow_cover = 0.0; ice = 0.0
		"fall": wet = 0.45; snow_cover = 0.0; ice = 0.0
		"winter": wet = 0.0; snow_cover = 0.55; ice = 0.25
		"spring": wet = 0.5; snow_cover = 0.05; ice = 0.0
	pick_weather()

func pick_weather(force := "") -> void:
	if force != "":
		weather = force
	else:
		var odds: Dictionary = ODDS[season]
		var total := 0
		for k in odds: total += int(odds[k])
		var roll := rng.randi() % total
		for k in odds:
			roll -= int(odds[k])
			if roll < 0:
				weather = k
				break
	weather_left = 1.5 + rng.randf() * 4.5

func next_weather() -> void:
	var keys: Array = ODDS[season].keys()
	var i := keys.find(weather)
	pick_weather(keys[(i + 1) % keys.size()])

func label() -> String:
	return WEATHER[weather].label

# ------------------------------------------------------------------ the sun

func sunrise() -> float: return SUN[season][0]
func sunset() -> float: return SUN[season][1]

## 0 at night, 1 in full day, smooth through dawn and dusk.
func daylight() -> float:
	var up := smoothstep(sunrise() - 0.6, sunrise() + 0.7, time_h)
	var down := 1.0 - smoothstep(sunset() - 0.7, sunset() + 0.6, time_h)
	return clampf(minf(up, down), 0.0, 1.0)

## How golden the light is (dawn and dusk).
func golden() -> float:
	var d := daylight()
	return clampf(1.0 - absf(d * 2.0 - 1.0), 0.0, 1.0) * (1.0 - cloud * 0.7)

## The colour everything is multiplied by.
func ambient_color() -> Color:
	var night := Color(0.15, 0.17, 0.33)
	var day := Color(1, 1, 1)
	var d := daylight()
	var c := night.lerp(day, d)
	var dawn := time_h < 12.0
	c = c.lerp(Color(1.0, 0.62, 0.48) if not dawn else Color(1.0, 0.72, 0.62), golden() * 0.55)
	# clouds and rain take the colour out and the light down
	var dim := 1.0 - cloud * 0.2 * d - rain * 0.12 - snow * 0.05
	var lum := c.get_luminance()
	c = c.lerp(Color(lum, lum, lum * 1.04), cloud * 0.35 * d)
	c = Color(c.r * dim, c.g * dim, c.b * dim)
	if flash > 0.0: c = c.lerp(Color(1.4, 1.4, 1.6), flash * 0.8)
	return c

## Are the lights on? Each photocell is a little different.
func lights_on(seed: int) -> bool:
	var dark := 1.0 - daylight() + cloud * 0.12 + fog * 0.15 + rain * 0.08
	return dark > 0.62 + float(seed % 100) / 100.0 * 0.12

func temperature() -> float:
	var swing := 5.0 * (1.0 - cloud * 0.6)
	var t: float = BASE_TEMP[season] + swing * sin((time_h - 9.0) / 24.0 * TAU)
	if weather == "freezing": t = minf(t, -1.5)
	if snow > 0.2: t = minf(t, -0.5)
	return t

func clock_str() -> String:
	var h := int(time_h)
	var m := int((time_h - h) * 60.0)
	return "%d:%02d %s" % [12 if h % 12 == 0 else h % 12, m, "AM" if h < 12 else "PM"]

# ------------------------------------------------------------------ time passing

func step(dt: float) -> void:
	var dh := dt * rate
	time_h += dh
	if time_h >= 24.0:
		time_h -= 24.0
		day += 1
		_season_day += 1
		if _season_day >= SEASON_DAYS:
			# the season turns overnight; the roads keep what's on them and the weather follows
			_season_day = 0
			season = SEASON_ORDER[(SEASON_ORDER.find(season) + 1) % 4]
			pick_weather()
	weather_left -= dh
	if weather_left <= 0.0 and not forced: pick_weather()
	var w: Dictionary = WEATHER[weather]
	var k := clampf(dh / 0.4, 0.0, 1.0)          # blends over about 25 game minutes
	cloud = lerpf(cloud, w.cloud, k)
	fog = lerpf(fog, w.fog, k)
	wind = lerpf(wind, w.wind, k)
	var temp := temperature()
	var precip_rain: float = w.rain
	var precip_snow: float = w.snow
	if precip_rain > 0.0 and temp < -0.5 and weather != "freezing":
		precip_snow = precip_rain       # too cold for rain: it snows
		precip_rain = 0.0
	if precip_snow > 0.0 and temp > 2.0:
		precip_rain = precip_snow
		precip_snow = 0.0
	rain = lerpf(rain, precip_rain, k)
	snow = lerpf(snow, precip_snow, k)
	wind_dir = wind_dir.rotated((rng.randf() - 0.5) * dh * 0.6)
	# the road: rain soaks it, sun and wind dry it, snow piles up, cold turns water to ice
	var d := daylight()
	wet = clampf(wet + rain * dh * 1.6 - dh * (0.12 + 0.5 * d * (1.0 - cloud)) * (1.0 if temp > 0.0 else 0.2), 0.0, 1.0)
	snow_cover = clampf(snow_cover + snow * dh * 0.9 - dh * 0.25 * maxf(0.0, temp - 1.0), 0.0, 1.0)
	if temp < -0.3:
		var freeze := minf(wet, dh * 0.6)
		wet -= freeze
		ice += freeze
		if weather == "freezing": ice += rain * dh * 0.8
	else:
		ice -= dh * 0.6 * maxf(0.2, temp)
	ice = clampf(ice, 0.0, 1.0)
	# lightning
	flash = maxf(0.0, flash - dt * 3.5)
	if thunder_in >= 0.0: thunder_in -= dt
	if weather == "storm" and rain > 0.6:
		_next_strike -= dt
		if _next_strike <= 0.0:
			flash = 1.0
			thunder_in = 0.4 + rng.randf() * 2.5
			_next_strike = 4.0 + rng.randf() * 14.0

## The surface the tires feel, from the kind of ground and what the weather left on it.
## `rank` is how important the road is (busy roads get plowed and salted first),
## `n` is a bit of local noise (-1..1) so ice and puddles come in patches.
func surface(ground: String, rank: int, n: float) -> String:
	match ground:
		"water": return "water"
		"mud": return "mud" if snow_cover < 0.3 else "snow"
		"asphalt":
			var plow := 0.4 if rank >= 4 else (0.7 if rank >= 3 else 1.0)
			var s := snow_cover * plow
			if ice > 0.12 and n > 0.75 - ice * 0.9 * (1.15 - plow * 0.3): return "ice"
			if s > 0.22: return "snow"
			if wet > 0.22: return "wet"
			if season == "fall" and rank <= 3 and n > 0.5: return "leaves"
			return "dry"
		"gravel":
			if ice > 0.2 and n > 0.7 - ice * 0.6: return "ice"
			if snow_cover > 0.2: return "snow"
			if wet > 0.6: return "mud"
			return "gravel"
		"grass":
			if snow_cover > 0.15: return "snow"
			if wet > 0.45: return "mud"
			return "grass"
	return "dry"

## Coarse steps of the road state, so the world only redraws when something visibly changes.
func road_key() -> String:
	return "%s%d%d%d" % [season, int(wet * 3.99), int(snow_cover * 3.99), int(ice * 2.99)]
