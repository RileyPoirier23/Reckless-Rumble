## Where everything on the driving screen goes, at the 640x360 the HUD is drawn at. Every widget
## reads its rect from here, so nothing is placed by eye, and tests/hud_layout_tests.gd can check
## that no two of them overlap and that none of them sits on the car.
##
##   +--------- CAR ---------+-------- INFO --------+-------- CLOCK -------+
##   | name, assist, gearbox | objective            | time, weather, road  |
##   +-----------------------+ subtitle (who: line) +----------------------+
##   | JOB slot (race order, | prompt  [F] GARAGE   |          RIGHT slot  |
##   | the meet, the grid)   |                      |          (drag tree) |
##   |                       |         the car      |                      |
##   +------- DIAG ----------+                      |           police bar |
##   | the scan tool         |                      |                      |
##   +------- DASH ----------+                      +-------- GPS ---------+
class_name HudLayout
extends RefCounted

const SCREEN := Rect2(0, 0, 640, 360)
const SAFE := Rect2(2, 2, 636, 356)

const CAR_BAR := Rect2(4, 4, 214, 30)
const CLOCK_BAR := Rect2(436, 4, 200, 40)
const INFO_X := 222.0
const INFO_W := 210.0
const INFO_BOTTOM := 104.0               # the column never reaches the road ahead of the car
const JOB := Rect2(4, 38, 196, 172)       # the left column: race order and grid, the meet
const RIGHT := Rect2(582, 48, 52, 132)    # the drag tree
const DIAG := Rect2(4, 214, 214, 44)      # the scan tool under the dash
const DASH := Rect2(4, 262, 214, 94)
const HELP := Rect2(204, 97, 248, 83)     # the controls card (F1 / START), above the car

## Subtitles wrap at this many characters (scale 1: 4 px a character, 210 px less padding).
const SUB_CHARS := 49
const SUB_MAX_LINES := 3
const OBJ_CHARS := 50
const OBJ_MAX_LINES := 4

## The camera, as drive.gd frames the car: the car sits below the screen's middle by how far the
## camera looks ahead, scaled by the zoom.
const LOOK_BASE := 40.0
const LOOK_GAIN := 0.14
const LOOK_MAX := 50.0
const ZOOM_REST := 1.55
const ZOOM_FAST := 1.0
const ZOOM_FULL_MS := 50.0

static func zoom_at(speed: float) -> float:
	return lerpf(ZOOM_REST, ZOOM_FAST, clampf(speed / ZOOM_FULL_MS, 0.0, 1.0))

static func look_ahead(speed: float) -> float:
	return LOOK_BASE + minf(speed * CarArt.PX * LOOK_GAIN, LOOK_MAX)

## The screen box the player's car can be in at this speed (the chase cam lags in a slide, so
## the car can swing to either side: up to `swing` radians).
static func car_zone(speed: float, len_m: float, wid_m: float, swing := 0.5) -> Rect2:
	var z := zoom_at(speed)
	var cy := 180.0 + look_ahead(speed) * z
	var l := len_m * CarArt.PX * CarArt.CAR_SCALE * z
	var w := wid_m * CarArt.PX * CarArt.CAR_SCALE * z
	var hx := absf(sin(swing)) * l * 0.5 + w * 0.5
	var hy := l * 0.5
	return Rect2(320.0 - hx, cy - hy, hx * 2.0, hy * 2.0)

## The info column's pieces for this many objective and subtitle lines: [objective, subtitle, prompt].
static func info(obj_lines: int, sub_lines: int, has_prompt: bool) -> Array:
	var y := 4.0
	var obj := Rect2()
	if obj_lines > 0:
		obj = Rect2(INFO_X, y, INFO_W, 6.0 + 8.0 * obj_lines)
		y = obj.end.y + 2.0
	var sub := Rect2()
	if sub_lines > 0:
		sub = Rect2(INFO_X, y, INFO_W, 6.0 + 8.0 * sub_lines)
		y = sub.end.y + 2.0
	var pr := Rect2()
	if has_prompt: pr = Rect2(INFO_X, y, INFO_W, 12.0)
	return [obj, sub, pr]

## The GPS bezel for each style (gps.gd draws inside it).
static func gps_rect(style: String) -> Rect2:
	match style:
		"phone": return Rect2(530, 210, 102, 146)
		"builtin": return Rect2(430, 262, 206, 94)
		"trucker": return Rect2(460, 250, 176, 106)
	return Rect2(470, 248, 166, 108)

## The heat and pursuit bar, just above the GPS.
static func police_rect(style: String, chasing: bool) -> Rect2:
	var g := gps_rect(style)
	var w := maxf(g.size.x, 150.0)
	var x := minf(g.position.x, 636.0 - w)
	var h := 22.0 if chasing else 12.0
	return Rect2(x, g.position.y - 6.0 - h, w, h)
