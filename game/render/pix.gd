## A small pixel-art canvas: an Image you paint pixel by pixel, the way the CAGE BOSS portraits
## are painted. Ordered dithering for skies and light, scanline polygons, cel-shaded boxes,
## speckle textures, 1px outlines, and stamping one sprite onto another. Paint it once,
## turn it into a texture, draw it scaled up with nearest filtering.
class_name Pix
extends RefCounted

const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const INK := Color("120e14")

var img: Image
var w: int
var h: int
var rng := RandomNumberGenerator.new()

func _init(width := 320, height := 180, seed := 1) -> void:
	w = width
	h = height
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	rng.seed = seed

func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func hex(c: int) -> Color:
	return Color8((c >> 16) & 255, (c >> 8) & 255, c & 255)

## True when (x, y) should take the second colour of a mix that's `t` of the way there.
static func dith(x: int, y: int, t: float) -> bool:
	return t * 16.0 > float(BAYER[(y & 3) * 4 + (x & 3)]) + 0.5

func px(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= w or y >= h or c.a <= 0.0: return
	if c.a >= 0.999: img.set_pixel(x, y, c)
	else: img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

func get_px(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h: return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)

func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	if rw <= 0 or rh <= 0: return
	var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, w, h))
	if r.size.x <= 0 or r.size.y <= 0: return
	if c.a >= 0.999:
		img.fill_rect(r, c)
		return
	for yy in range(r.position.y, r.end.y):
		for xx in range(r.position.x, r.end.x):
			px(xx, yy, c)

## A rect where only some pixels land: a checker/dither at density t (0..1).
func rect_dither(x: int, y: int, rw: int, rh: int, c: Color, t: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if dith(xx, yy, t): px(xx, yy, c)

func hline(x: int, y: int, len: int, c: Color) -> void:
	rect(x, y, len, 1, c)

func vline(x: int, y: int, len: int, c: Color) -> void:
	rect(x, y, 1, len, c)

func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var guard := 0
	while guard < 4000:
		guard += 1
		px(x0, y0, c)
		if x0 == x1 and y0 == y1: break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

## A vertical gradient in `steps` flat bands, dithered at the seams (pixel-art sky).
func grad_v(x: int, y: int, rw: int, rh: int, top: Color, bottom: Color, steps := 6) -> void:
	for yy in rh:
		var f := float(yy) / float(maxi(1, rh - 1)) * float(steps - 1)
		var band := floori(f)
		var frac := f - float(band)
		var c0 := top.lerp(bottom, float(band) / float(steps - 1))
		var c1 := top.lerp(bottom, float(mini(band + 1, steps - 1)) / float(steps - 1))
		for xx in rw:
			px(x + xx, y + yy, c1 if dith(x + xx, y + yy, frac) else c0)

func grad_h(x: int, y: int, rw: int, rh: int, left: Color, right: Color, steps := 5) -> void:
	for xx in rw:
		var f := float(xx) / float(maxi(1, rw - 1)) * float(steps - 1)
		var band := floori(f)
		var frac := f - float(band)
		var c0 := left.lerp(right, float(band) / float(steps - 1))
		var c1 := left.lerp(right, float(mini(band + 1, steps - 1)) / float(steps - 1))
		for yy in rh:
			px(x + xx, y + yy, c1 if dith(x + xx, y + yy, frac) else c0)

## Filled polygon (even-odd scanlines). Points in pixels.
func poly(pts: PackedVector2Array, c: Color, dither_t := 1.0) -> void:
	if pts.size() < 3: return
	var y0 := int(floor(pts[0].y))
	var y1 := y0
	for p in pts:
		y0 = mini(y0, int(floor(p.y)))
		y1 = maxi(y1, int(ceil(p.y)))
	y0 = maxi(y0, 0)
	y1 = mini(y1, h - 1)
	for y in range(y0, y1 + 1):
		var fy := float(y) + 0.5
		var xs: Array[float] = []
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if (a.y <= fy and b.y > fy) or (b.y <= fy and a.y > fy):
				xs.append(a.x + (fy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var xa := int(round(xs[k]))
			var xb := int(round(xs[k + 1]))
			if dither_t >= 1.0: rect(xa, y, xb - xa, 1, c)
			else:
				for x in range(xa, xb):
					if dith(x, y, dither_t): px(x, y, c)
			k += 2

func poly_outline(pts: PackedVector2Array, c: Color) -> void:
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		line(int(round(a.x)), int(round(a.y)), int(round(b.x)), int(round(b.y)), c)

func disc(cx: int, cy: int, r: float, c: Color) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		var half := sqrt(maxf(0.0, r * r - float(dy * dy)))
		var hw := int(round(half))
		rect(cx - hw, cy + dy, hw * 2 + 1, 1, c)

func ellipse(cx: int, cy: int, rx: float, ry: float, c: Color) -> void:
	var ri := int(ceil(ry))
	for dy in range(-ri, ri + 1):
		var f := 1.0 - float(dy * dy) / maxf(0.01, ry * ry)
		if f < 0.0: continue
		var hw := int(round(rx * sqrt(f)))
		rect(cx - hw, cy + dy, hw * 2 + 1, 1, c)

func ring(cx: int, cy: int, r: float, c: Color) -> void:
	var n := maxi(12, int(r * 7.0))
	for i in n:
		var a := TAU * float(i) / float(n)
		px(cx + int(round(cos(a) * r)), cy + int(round(sin(a) * r)), c)

## A soft round glow in a few flat bands (lamps, headlights, the TV): pixel-art light, not dots.
func glow(cx: int, cy: int, r: float, c: Color, strength := 1.0) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var d := sqrt(float(dx * dx + dy * dy)) / r
			if d >= 1.0: continue
			var a := band((1.0 - d) * strength) * 0.55
			if a > 0.0: px(cx + dx, cy + dy, Color(c, a))

## Quantise 0..1 into four flat steps (with a dithered edge between steps).
static func band(t: float) -> float:
	return floor(clampf(t, 0.0, 1.0) * 4.0) / 4.0

## A beam of light from (x0, y0) spreading to the segment (x1, ya)-(x1, yb), fading out.
func beam(x0: int, y0: int, x1: int, ya: int, yb: int, c: Color, strength := 0.7) -> void:
	var dir := 1 if x1 >= x0 else -1
	var n := absi(x1 - x0)
	for i in n:
		var f := float(i) / float(maxi(1, n))
		var top := lerpf(float(y0), float(ya), f)
		var bot := lerpf(float(y0), float(yb), f)
		var x := x0 + i * dir
		var mid := (top + bot) * 0.5
		var half := maxf(1.0, (bot - top) * 0.5)
		for y in range(int(top), int(bot) + 1):
			var edge := 1.0 - absf(float(y) - mid) / half
			var a := band((1.0 - f) * strength * (0.5 + 0.5 * edge)) * 0.45
			if a > 0.0: px(x, y, Color(c, a))

## A cone of light straight down from a lamp at (cx, y0) to the ground at y1, `spread` wide at the bottom.
func cone_down(cx: int, y0: int, y1: int, spread: float, c: Color, strength := 0.5) -> void:
	for y in range(y0, y1):
		var f := float(y - y0) / float(maxi(1, y1 - y0))
		var hw := int(2.0 + spread * f)
		for x in range(cx - hw, cx + hw + 1):
			var edge := 1.0 - absf(float(x - cx)) / float(hw + 1)
			var a := band(strength * 1.6 * (0.35 + 0.65 * edge) * (1.0 - f * 0.4)) * 0.4
			if a > 0.0: px(x, y, Color(c, a))

## Random single pixels: grain, gravel, stars, dust.
func speckle(x: int, y: int, rw: int, rh: int, c: Color, density: float) -> void:
	var n := int(float(rw * rh) * density)
	for i in n:
		px(x + rng.randi() % maxi(1, rw), y + rng.randi() % maxi(1, rh), c)

## A box with a light top/left edge, a dark bottom/right edge and an ink outline.
func box(x: int, y: int, rw: int, rh: int, c: Color, outline := true) -> void:
	rect(x, y, rw, rh, c)
	hline(x, y, rw, c.lightened(0.18))
	vline(x, y, rh, c.lightened(0.1))
	hline(x, y + rh - 1, rw, c.darkened(0.3))
	vline(x + rw - 1, y, rh, c.darkened(0.22))
	if outline: frame(x - 1, y - 1, rw + 2, rh + 2, INK)

func frame(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	hline(x, y, rw, c)
	hline(x, y + rh - 1, rw, c)
	vline(x, y, rh, c)
	vline(x + rw - 1, y, rh, c)

## Wooden planks: vertical boards with seams and grain.
func planks(x: int, y: int, rw: int, rh: int, c: Color, board := 9, vertical := true) -> void:
	rect(x, y, rw, rh, c)
	var k := 0
	if vertical:
		for bx in range(x, x + rw, board):
			var tone := c.darkened(0.04 * float(k % 3))
			rect(bx, y, board, rh, tone)
			vline(bx, y, rh, c.darkened(0.35))
			for g in 3:
				var gx := bx + 2 + rng.randi() % maxi(1, board - 3)
				var gy := y + rng.randi() % maxi(1, rh)
				vline(gx, gy, 3 + rng.randi() % 8, tone.darkened(0.12))
			k += 1
	else:
		for by in range(y, y + rh, board):
			var tone := c.darkened(0.04 * float(k % 3))
			rect(x, by, rw, board, tone)
			hline(x, by, rw, c.darkened(0.3))
			for g in 4:
				hline(x + rng.randi() % maxi(1, rw), by + 1 + rng.randi() % maxi(1, board - 2), 4 + rng.randi() % 10, tone.darkened(0.1))
			k += 1

## Bricks with mortar lines and a little variation in each brick.
func bricks(x: int, y: int, rw: int, rh: int, c: Color, mortar: Color, bw := 8, bh := 4) -> void:
	rect(x, y, rw, rh, mortar)
	var row := 0
	for by in range(y, y + rh, bh):
		var off := (bw / 2) if row % 2 == 1 else 0
		for bx in range(x - off, x + rw, bw):
			var v := rng.randf_range(-0.07, 0.07)
			var bc := c.lightened(v) if v > 0.0 else c.darkened(-v)
			var x0 := maxi(bx, x)
			var x1 := mini(bx + bw - 1, x + rw)
			rect(x0, by, x1 - x0, mini(bh - 1, y + rh - by), bc)
			if x1 - x0 > 2: hline(x0, by, x1 - x0, bc.lightened(0.08))
		row += 1

## Corrugated metal siding.
func siding(x: int, y: int, rw: int, rh: int, c: Color, pitch := 3) -> void:
	rect(x, y, rw, rh, c)
	for sx in range(x, x + rw, pitch):
		vline(sx, y, rh, c.darkened(0.18))
		vline(sx + 1, y, rh, c.lightened(0.06))

## Copy a sprite on (alpha-blended). flip mirrors it left-right.
func stamp(src: Image, x: int, y: int, flip := false, tint := Color(1, 1, 1, 1)) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	for yy in sh:
		for xx in sw:
			var c := src.get_pixel(sw - 1 - xx if flip else xx, yy)
			if c.a <= 0.0: continue
			px(x + xx, y + yy, c * tint)

## 1px ink outline around everything that's been painted (sprites).
func outline(c := INK) -> void:
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0: continue
			var hit := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					hit = true
					break
			if hit: img.set_pixel(x, y, c)

## Shade everything below a line at y (a floor shadow band under furniture etc.)
func darken_rect(x: int, y: int, rw: int, rh: int, amount: float) -> void:
	for yy in range(maxi(0, y), mini(h, y + rh)):
		for xx in range(maxi(0, x), mini(w, x + rw)):
			var c := img.get_pixel(xx, yy)
			if c.a > 0.0: img.set_pixel(xx, yy, c.darkened(amount))

## A little dithered shadow ellipse on the ground.
func shadow(cx: int, cy: int, rx: float, ry: float, strength := 0.55) -> void:
	var ri := int(ceil(ry))
	for dy in range(-ri, ri + 1):
		var f := 1.0 - float(dy * dy) / maxf(0.01, ry * ry)
		if f < 0.0: continue
		var hw := int(round(rx * sqrt(f)))
		for x in range(cx - hw, cx + hw + 1):
			if dith(x, cy + dy, strength):
				var c := get_px(x, cy + dy)
				if c.a > 0.0: img.set_pixel(x, cy + dy, c.darkened(0.45))

## Tiny 3x5 text painted into the image (signs, posters, labels).
func text(x: int, y: int, s: String, c: Color) -> void:
	var cx := x
	for ch in s.to_upper():
		var rows: Array = PixelFont.G.get(ch, PixelFont.G["?"])
		for ry in 5:
			var bits: int = rows[ry]
			for rx in 3:
				if bits & (4 >> rx): px(cx + rx, y + ry, c)
		cx += 4

static func text_w(s: String) -> int:
	return s.length() * 4 - 1
