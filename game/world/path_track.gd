## A line of points to drive, and how far along it something is. An AI driver follows one; a
## street race keeps one per car to know who's ahead. It only looks a few points forward from
## where it last was, so a car that cuts a corner doesn't jump to some other part of the line.
class_name PathTrack
extends RefCounted

var pts := PackedVector2Array()
var loop := false
var cum := PackedFloat32Array()    # distance to each point
var seg := 0                       # the segment it's on
var laps := 0
var dist := 0.0                    # how far along (m), counting every lap
var done := false                  # reached the end of a line that doesn't loop

## The line. Points closer than half a metre are merged; a loop closes itself.
func set_path(p: PackedVector2Array, is_loop := false, from := Vector2.INF) -> void:
	pts = PackedVector2Array()
	for q in p:
		if pts.is_empty() or pts[pts.size() - 1].distance_to(q) > 0.5: pts.append(q)
	if is_loop and pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) > 0.5: pts.append(pts[0])
	loop = is_loop
	cum = PackedFloat32Array()
	cum.resize(pts.size())
	var acc := 0.0
	for i in pts.size():
		if i > 0: acc += pts[i - 1].distance_to(pts[i])
		cum[i] = acc
	seg = 0
	laps = 0
	dist = 0.0
	done = false
	if from != Vector2.INF: snap(from)

## The same line with every corner rounded off into an arc of about radius `r` (less where the
## legs are short): a line a car can actually drive, and one whose bends show up as bends.
static func rounded(p: PackedVector2Array, r: float, is_loop := false) -> PackedVector2Array:
	var n := p.size()
	if n < 3 or r <= 0.0: return p
	var closed := is_loop and p[0].distance_to(p[n - 1]) < 0.5
	var m := n - 1 if closed else n
	var out := PackedVector2Array()
	for i in m:
		var b := p[i]
		if not closed and (i == 0 or i == m - 1):
			out.append(b)
			continue
		var a := p[(i - 1 + m) % m]
		var c := p[(i + 1) % m]
		var l1 := a.distance_to(b)
		var l2 := b.distance_to(c)
		var th := absf((b - a).angle_to(c - b)) if l1 > 0.01 and l2 > 0.01 else 0.0
		if th < 0.05:
			out.append(b)
			continue
		var t := minf(r * tan(th / 2.0), minf(l1, l2) * 0.45)
		var p0 := b + (a - b) / l1 * t
		var p2 := b + (c - b) / l2 * t
		var k := clampi(int(th / 0.2) + 2, 3, 10)
		for j in k + 1:
			var u := float(j) / k
			out.append(p0.lerp(b, u).lerp(b.lerp(p2, u), u))
	if closed: out.append(out[0])
	return out

func valid() -> bool:
	return pts.size() >= 2

func length() -> float:
	return cum[cum.size() - 1] if cum.size() > 0 else 0.0

## Where along this lap a point is (m from the start), measured on the current segment.
func proj(p: Vector2) -> float:
	if not valid(): return 0.0
	var a := pts[seg]
	var b := pts[seg + 1]
	var L := a.distance_to(b)
	if L <= 0.0: return cum[seg]
	return cum[seg] + clampf((p - a).dot(b - a) / (L * L), 0.0, 1.0) * L

## The nearest segment, from scratch (after a teleport or a new line).
func snap(p: Vector2) -> void:
	var best := INF
	for i in pts.size() - 1:
		var d := MapData.seg_dist(p, pts[i], pts[i + 1])
		if d < best - 0.01:
			best = d
			seg = i
	dist = laps * length() + proj(p)

## On a loop, a car lined up behind the start is at the end of the lap before the first one.
func behind_start() -> void:
	if loop and dist - laps * length() > length() * 0.5:
		laps -= 1
		dist -= length()

## Move along as the point passes the line's points. Returns how far along it is.
func advance(p: Vector2) -> float:
	var n := pts.size()
	if n < 2: return 0.0
	var best := MapData.seg_dist(p, pts[seg], pts[seg + 1])
	var bi := seg
	var wrapped := false
	for k in range(1, 7):
		var i := seg + k
		var w := false
		if i >= n - 1:
			if not loop: break
			i -= n - 1
			w = true
		var d := MapData.seg_dist(p, pts[i], pts[i + 1])
		if d < best - 0.05:
			best = d
			bi = i
			wrapped = w
	if wrapped: laps += 1
	seg = bi
	dist = laps * length() + proj(p)
	if not loop and seg >= n - 2 and p.distance_to(pts[n - 1]) < 6.0: done = true
	return dist

## How far it is from the line right now.
func off_line(p: Vector2) -> float:
	if not valid(): return 0.0
	return MapData.seg_dist(p, pts[seg], pts[seg + 1])

## The point `s` metres along (wrapping on a loop, clamped otherwise).
func point_at(s: float) -> Vector2:
	if not valid(): return pts[0] if pts.size() == 1 else Vector2.ZERO
	var total := length()
	if loop: s = fposmod(s, total)
	else: s = clampf(s, 0.0, total)
	var lo := 0
	var hi := pts.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if cum[mid] <= s: lo = mid
		else: hi = mid
	var L := cum[hi] - cum[lo]
	return pts[lo].lerp(pts[hi], (s - cum[lo]) / L) if L > 0.0 else pts[lo]

## The way the line runs at `s` (a short chord, so a corner point gives the average).
func dir_at(s: float) -> Vector2:
	var d := point_at(s + 1.5) - point_at(s - 1.5)
	return d.normalized() if d.length() > 0.01 else Vector2.RIGHT
