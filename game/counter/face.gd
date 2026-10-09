## Faces drawn pixel by pixel from a seed (the CAGE BOSS portrait idea): skin, hair, brows,
## eyes, nose, mouth, beard, glasses, hats, clothes. Same seed, same face, every time.
class_name Face
extends RefCounted

const W := 32
const H := 40
const SKIN := [Color("f2c9a6"), Color("e0aa82"), Color("c88a62"), Color("a86a44"), Color("7a4a2e"), Color("5a3420")]
const HAIR := [Color("1a1410"), Color("3a2414"), Color("6a4224"), Color("a87a44"), Color("d8b878"), Color("8a8680"), Color("e8e4dc"), Color("8a3a1a")]
const SHIRT := [Color("2c5a8a"), Color("6a2a2a"), Color("2a2a2e"), Color("3a6a3a"), Color("8a6a3a"), Color("5a5a62"), Color("a83a2a"), Color("2a4a6a")]

static var _cache := {}

static func texture(seed: int) -> ImageTexture:
	if _cache.has(seed): return _cache[seed]
	var t := ImageTexture.create_from_image(image(seed))
	_cache[seed] = t
	return t

static func image(seed: int) -> Image:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var skin: Color = SKIN[r.randi() % SKIN.size()]
	var hair: Color = HAIR[r.randi() % HAIR.size()]
	var style := r.randi() % 9
	var beard := r.randi() % 6
	var glasses := r.randf() < 0.22
	var shirt: Color = SHIRT[r.randi() % SHIRT.size()]
	var jacket := r.randi() % 3            # 0 tee, 1 hoodie, 2 flannel
	var wide := r.randi() % 3               # face width
	var old := r.randf() < 0.3
	var eye: Color = [Color("3a2a1a"), Color("2a4a6a"), Color("3a5a3a"), Color("1a1410")][r.randi() % 4]
	var brow := 1 + r.randi() % 2
	var mouth := r.randi() % 3
	var shade := skin.darkened(0.18)
	var line := skin.darkened(0.45)
	# shoulders and clothes
	for y in range(31, H):
		for x in W:
			var half := 6 + (y - 31) * 1.6
			if absf(x - 15.5) <= half + 4:
				var c := shirt
				if jacket == 2 and (x + y) % 4 < 2: c = shirt.darkened(0.25)          # flannel check
				if jacket == 1 and absf(x - 15.5) < 2.5 and y < 36: c = skin.darkened(0.1)
				img.set_pixel(x, y, c)
	if jacket == 1:   # hoodie strings
		img.set_pixel(14, 33, Color.WHITE); img.set_pixel(17, 33, Color.WHITE)
		img.set_pixel(14, 34, Color.WHITE); img.set_pixel(17, 34, Color.WHITE)
	# neck
	for y in range(25, 33):
		for x in range(13, 19): img.set_pixel(x, y, shade)
	# head
	var rx := 7.0 + wide * 0.6
	for y in range(6, 29):
		for x in W:
			var dx := (x + 0.5 - 16.0) / rx
			var dy := (y + 0.5 - 17.0) / 10.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, skin if x < 19 else shade)
	# ears
	for y in range(15, 20):
		img.set_pixel(int(16 - rx) - 1, y, shade)
		img.set_pixel(int(16 + rx), y, shade)
	# eyes, brows, nose, mouth
	for ex in [12, 19]:
		img.set_pixel(ex, 17, Color("f4f0e8"))
		img.set_pixel(ex + 1, 17, eye)
		for b in brow: img.set_pixel(ex + b - 1, 15, hair.darkened(0.2)); img.set_pixel(ex + b, 15, hair.darkened(0.2))
	img.set_pixel(16, 19, shade); img.set_pixel(16, 20, line); img.set_pixel(15, 21, shade); img.set_pixel(17, 21, line)
	var mw := 2 + mouth
	for x in range(16 - mw, 16 + mw - 1): img.set_pixel(x, 24, line)
	if mouth == 2: img.set_pixel(16 - mw, 23, line)          # a smirk
	if old:
		img.set_pixel(10, 19, shade); img.set_pixel(21, 19, shade); img.set_pixel(13, 12, shade); img.set_pixel(18, 12, shade)
	# beard
	if beard >= 3:
		for y in range(21, 29):
			for x in W:
				if img.get_pixel(x, y) == skin or img.get_pixel(x, y) == shade:
					if y >= 23 or absf(x - 16) > 4:
						if not (y == 24 and absf(x - 15.5) < mw): img.set_pixel(x, y, hair if beard == 4 else hair.lerp(skin, 0.35))
	elif beard == 2:   # goatee
		for y in range(25, 29):
			for x in range(14, 19): img.set_pixel(x, y, hair)
	elif beard == 1:   # moustache
		for x in range(13, 19): img.set_pixel(x, 23, hair)
	# hair
	match style:
		0: pass   # bald
		1, 2:     # short / buzz
			for y in range(5, 12 if style == 1 else 10):
				for x in W:
					var dx := (x + 0.5 - 16.0) / (rx + 0.6)
					var dy := (y + 0.5 - 15.0) / 10.0
					if dx * dx + dy * dy <= 1.0 and y < 13: img.set_pixel(x, y, hair)
		3, 4:     # long / mullet
			for y in range(5, 30 if style == 3 else 27):
				for x in W:
					var dx := (x + 0.5 - 16.0) / (rx + 1.6)
					var dy := (y + 0.5 - 15.0) / 11.0
					var inside_face := absf(x - 16) < rx - 1.0 and y > 11
					if dx * dx + dy * dy <= 1.2 and not inside_face and (y < 12 or absf(x - 16) > rx - 2.5): img.set_pixel(x, y, hair)
		5:        # curly
			for y in range(3, 13):
				for x in W:
					var dx := (x + 0.5 - 16.0) / (rx + 2.5)
					var dy := (y + 0.5 - 13.0) / 10.0
					if dx * dx + dy * dy <= 1.0 and (x + y) % 3 != 0: img.set_pixel(x, y, hair)
		6, 7:     # ball cap (brim to the front)
			var cap: Color = SHIRT[(seed >> 3) % SHIRT.size()].lightened(0.1)
			for y in range(5, 12):
				for x in W:
					var dx := (x + 0.5 - 16.0) / (rx + 0.8)
					var dy := (y + 0.5 - 13.0) / 8.5
					if dx * dx + dy * dy <= 1.0 and y < 11: img.set_pixel(x, y, cap)
			for x in range(int(16 - rx), int(16 + rx + 3)): img.set_pixel(x, 11, cap.darkened(0.3))
		8:        # toque
			var tq: Color = [Color("c8342c"), Color("2c5a8a"), Color("3a6a3a")][seed % 3]
			for y in range(3, 12):
				for x in W:
					var dx := (x + 0.5 - 16.0) / (rx + 0.6)
					var dy := (y + 0.5 - 12.0) / 9.0
					if dx * dx + dy * dy <= 1.0: img.set_pixel(x, y, tq if y % 2 == 0 else tq.darkened(0.15))
			img.set_pixel(16, 2, Color.WHITE); img.set_pixel(15, 2, Color.WHITE)
	if glasses:
		for ex in [11, 18]:
			for x in range(ex, ex + 4):
				img.set_pixel(x, 16, Color("1a1a1e")); img.set_pixel(x, 18, Color("1a1a1e"))
			img.set_pixel(ex, 17, Color("1a1a1e")); img.set_pixel(ex + 3, 17, Color("1a1a1e"))
		img.set_pixel(15, 17, Color("1a1a1e")); img.set_pixel(16, 17, Color("1a1a1e"))
	return img
