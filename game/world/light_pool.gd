## The lights. The map has well over a thousand of them; a pool of real 2D lights is handed
## to the nearest few dozen around the camera, ten times a second.
##
## Each kind of light looks and behaves differently: old orange sodium streetlights (some
## buzzing, some dead), cold white LEDs downtown and in the new suburbs, blue-green mercury
## yard lights on the farms, porch lights, gas-station canopies, high-mast lights at the
## highway exits, neon shop signs, the blue bridge lights, the casino's colour sweep, red
## tower beacons, railway crossing flashers and traffic signals.
class_name LightPool
extends Node2D

const PX := CarArt.PX
const N := 56

const TYPES := {
	"sodium":         { "c": Color(1.0, 0.6, 0.24), "s": 2.6, "e": 1.15 },
	"sodium_flicker": { "c": Color(1.0, 0.6, 0.24), "s": 2.6, "e": 1.15, "flicker": true },
	"led":            { "c": Color(0.86, 0.93, 1.0), "s": 2.4, "e": 1.0 },
	"led_flood":      { "c": Color(0.9, 0.95, 1.0), "s": 3.6, "e": 1.2 },
	"lamp":           { "c": Color(1.0, 0.84, 0.6), "s": 1.6, "e": 0.9 },
	"mercury":        { "c": Color(0.62, 0.95, 0.82), "s": 2.0, "e": 0.9 },
	"porch":          { "c": Color(1.0, 0.76, 0.46), "s": 1.0, "e": 0.75 },
	"canopy":         { "c": Color(0.95, 0.98, 1.0), "s": 3.0, "e": 1.45 },
	"neon":           { "c": Color(1.0, 0.3, 0.6), "s": 1.3, "e": 1.0, "buzz": true },
	"neon_red":       { "c": Color(1.0, 0.2, 0.15), "s": 1.3, "e": 1.0 },
	"highmast":       { "c": Color(1.0, 0.64, 0.3), "s": 5.0, "e": 1.25 },
	"bridge":         { "c": Color(0.3, 0.5, 1.0), "s": 1.4, "e": 0.95 },
	"casino":         { "c": Color(1, 1, 1), "s": 3.2, "e": 1.3, "sweep": true },
	"runway":         { "c": Color(0.35, 0.55, 1.0), "s": 0.6, "e": 1.3 },
	"aviation":       { "c": Color(1.0, 0.08, 0.06), "s": 1.2, "e": 1.4, "blink": 1.4 },
	"rail":           { "c": Color(1.0, 0.1, 0.06), "s": 1.2, "e": 1.5, "rail": true },
	"signal":         { "c": Color(0.2, 1.0, 0.4), "s": 0.9, "e": 1.1, "signal": true },
}
const NEON := [Color(1.0, 0.25, 0.55), Color(0.25, 0.85, 1.0), Color(0.55, 1.0, 0.3), Color(1.0, 0.45, 0.15), Color(0.8, 0.3, 1.0), Color(1.0, 0.9, 0.3)]

var world: World
var sky: WorldSky
var pool: Array[PointLight2D] = []
var assigned: Array = []          # source dict per pool light (or null)
var tex: GradientTexture2D
var _t := 0.0
var train_near := false            # set by the drive scene when the train is close to a crossing

func setup(the_world: World, the_sky: WorldSky) -> void:
	world = the_world
	sky = the_sky
	tex = World.light_tex(Color.WHITE)
	for i in N:
		var l := PointLight2D.new()
		l.texture = tex
		l.visible = false
		l.shadow_enabled = false
		add_child(l)
		pool.append(l)
		assigned.append(null)

func refresh(center_px: Vector2, half_px: Vector2) -> void:
	var view := Rect2(center_px - half_px, half_px * 2.0).grow(28.0 * PX)
	var cand: Array = []
	for src in world.live_lights():
		var p: Vector2 = src.p * PX
		if not view.has_point(p): continue
		if src.type == "dead": continue
		if not _on(src): continue
		cand.append([p.distance_squared_to(center_px), src])
	cand.sort_custom(func(a, b): return a[0] < b[0])
	for i in N:
		if i < cand.size():
			assigned[i] = cand[i][1]
			pool[i].position = cand[i][1].p * PX + Vector2(0, -6)
			var t: Dictionary = TYPES.get(cand[i][1].type, TYPES.sodium)
			pool[i].texture_scale = float(t.s) * (1.0 + sky.fog * 0.35)
			pool[i].visible = true
		else:
			assigned[i] = null
			pool[i].visible = false

func _on(src: Dictionary) -> bool:
	var typ: String = src.type
	if typ in ["aviation", "signal"]: return sky.daylight() < 0.7
	if typ == "rail": return train_near
	return sky.lights_on(int(src.seed) & 0xffff)

## Animate: flicker, buzz, blink, sweep, cycle. Called every frame.
func animate(dt: float) -> void:
	_t += dt
	var dark := clampf(1.15 - sky.daylight(), 0.0, 1.0)
	for i in N:
		var src = assigned[i]
		if src == null: continue
		var l := pool[i]
		var t: Dictionary = TYPES.get(src.type, TYPES.sodium)
		var col: Color = t.c
		var e: float = float(t.e) * dark * (1.0 + sky.fog * 0.25)
		var seed: int = int(src.seed) & 0xffff
		if src.type == "neon":
			col = src.get("color") if src.get("color") != null else NEON[seed % NEON.size()]
		if t.has("flicker"):
			# a dying sodium lamp: mostly on, sometimes stutters off
			var ph := fmod(_t * 1.3 + seed * 0.37, 7.0)
			if ph > 6.2: e *= 0.15 if int(_t * 18.0) % 2 == 0 else 0.8
		if t.has("buzz") and fmod(_t + seed * 0.11, 11.0) > 10.6: e *= 0.3 if int(_t * 25.0) % 2 == 0 else 1.0
		if t.has("blink"): e *= 1.0 if fmod(_t + seed * 0.3, float(t.blink)) < 0.5 else 0.0
		if t.has("sweep"): col = Color.from_hsv(fmod(_t * 0.12 + seed * 0.2, 1.0), 0.75, 1.0)
		if t.has("rail"): e *= 1.0 if (int(_t * 2.0) + seed) % 2 == 0 else 0.0
		if t.has("signal"):
			# the same cycle the traffic obeys (the main road's lights)
			var st := Traffic.signal_state(Traffic.signal_offset(src.get("j", src.p)), 0)
			col = Color(0.2, 1.0, 0.45) if st == "green" else (Color(1.0, 0.7, 0.1) if st == "amber" else Color(1.0, 0.12, 0.1))
		l.color = col
		l.energy = e
