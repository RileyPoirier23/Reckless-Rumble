## Full-body pixel people for the cutscenes, built from the same look as their CAGE BOSS portrait
## (skin tone, hair style and colour, beard, glasses, clothes), so the person standing in the
## scene is the person in the dialogue box. Lit from the upper left, ink outline, 26x64.
## Poses: stand, crossed, pockets, cup, phone, bow, point, hips, wave.
## Each person has two frames: mouth shut and mouth open (for talking).
class_name PixPeople
extends RefCounted

const W := 26
const H := 64
const C := 13                 # centre column

static var _cache := {}

## Outfit overrides for the cast (otherwise the portrait's attire and colour are used).
## kind: shirt, hoodie, jersey, suit, tracksuit, coveralls, hivis, police, leather, plaid, dress_shirt
const OUTFITS := {
	"LEO": { "kind": "hoodie", "top": 0x3c4250, "bottom": 0x2e3a52, "shoes": 0xd8d4cc },
	"MIKEY": { "kind": "hoodie", "top": 0x4e6a43, "bottom": 0x2a2a30, "hat": "cap_back", "hat_c": 0xc8342c, "shoes": 0xf0f0f0 },
	"GUS": { "kind": "coveralls", "top": 0x2c3a5a, "bottom": 0x2c3a5a, "patch": true, "shoes": 0x3a2a1c },
	"DOM": { "kind": "suit", "top": 0x16161c, "bottom": 0x16161c, "shirt": 0x2a2a30, "chain": true, "shoes": 0x0e0e10 },
	"MIA": { "kind": "leather", "top": 0x1a1618, "inner": 0x9a2030, "bottom": 0x1e1e26, "shoes": 0x0e0e10 },
	"SAL": { "kind": "tracksuit", "top": 0x5a1e28, "bottom": 0x5a1e28, "chain": true, "shoes": 0xf0f0f0 },
	"ARIES": { "kind": "hoodie", "top": 0x6a4c8a, "bottom": 0x2a2a3a, "shoes": 0xe8e0d0, "teen": true },
	"FRANKIE": { "kind": "hoodie", "top": 0x8a2e26, "bottom": 0x34343c, "hat": "cap", "hat_c": 0x2a3a5a, "shoes": 0xe8e4dc, "teen": true },
	"TOBY": { "kind": "hivis", "top": 0x2a2a30, "bottom": 0x3a3a34, "hat": "cap", "hat_c": 0x1e1e22, "shoes": 0x5a3a1c },
	"TREMBLAY": { "kind": "police", "top": 0x1c2232, "bottom": 0x1c2232, "hat": "police", "shoes": 0x0e0e10 },
	"DARRELL": { "kind": "plaid", "top": 0x9a2a24, "bottom": 0x3a4a62, "hat": "trucker", "hat_c": 0x3a5a3a, "shoes": 0x5a3a1c },
}

const HAIR_GREY := 0xb8b4ac

## The sprite for a cast member (or any seed). frame 0 = mouth shut, 1 = talking.
static func sprite(who: String, pose := "stand", frame := 0) -> ImageTexture:
	var key := "%s|%s|%d" % [who, pose, frame]
	if _cache.has(key): return _cache[key]
	var cast: Dictionary = StoryScript.CAST.get(who, {})
	var seed := int(cast.get("seed", who.hash()))
	var female := int(cast.get("female", -1))
	var age := int(cast.get("age", -1))
	if who == "MANAGER" and not StoryState.avatar.is_empty():
		seed = int(StoryState.avatar.seed)
		female = int(StoryState.avatar.female)
		age = int(StoryState.avatar.age)
	var t := ImageTexture.create_from_image(image(seed, female, age, OUTFITS.get(who, {}), pose, frame))
	_cache[key] = t
	return t

static func image(seed: int, female: int, age: int, outfit: Dictionary, pose: String, frame: int) -> Image:
	var civ := Face.civilian(seed, female, age)
	var b := _Body.new(civ, outfit, pose, frame)
	b.paint()
	return b.p.img


class _Body:
	var p: Pix
	var look: Dictionary
	var fem: bool
	var age: int
	var pose: String
	var frame: int
	var o: Dictionary
	var skin: Color
	var skin_d: Color
	var skin_l: Color
	var hair: Color
	var hair_d: Color
	var top: Color
	var bottom: Color
	var kind: String
	var tw := 12               # torso width
	var dy := 0                # teens are shorter: everything above the legs moves down
	var head_y := 5
	var torso_y := 19
	var leg_y := 38
	var foot_y := 61

	func _init(civ: Dictionary, outfit: Dictionary, the_pose: String, the_frame: int) -> void:
		p = Pix.new(W, H, int(civ.id.hash()))
		look = civ.look
		fem = civ.female
		age = civ.age
		pose = the_pose
		frame = the_frame
		o = outfit
		skin = Pix.hex(Face.SKIN_TONES[int(look.skin)])
		skin_d = skin.darkened(0.2)
		skin_l = skin.lightened(0.1)
		var grey := clampf((float(age) - 42.0) / 26.0, 0.0, 0.85)
		hair = Pix.hex(Face.HAIR_COLORS[int(look.hairColor)]).lerp(Pix.hex(HAIR_GREY), grey)
		hair_d = hair.darkened(0.3)
		kind = String(o.get("kind", ""))
		if kind == "":
			kind = { "shirt": "shirt", "hoodie": "hoodie", "jersey": "jersey", "suit": "suit", "tracksuit": "tracksuit" }.get(String(civ.attire), "shirt")
		top = Pix.hex(int(o.get("top", civ.accent)))
		bottom = Pix.hex(int(o.get("bottom", 0x2e3a52)))
		tw = [10, 12, 12, 14][clampi(int(look.build), 0, 3)]
		if fem: tw -= 1
		if o.get("teen", false) or age < 16:
			dy = 5
			tw -= 1
		head_y += dy
		torso_y += dy
		leg_y += dy

	func paint() -> void:
		_legs()
		_torso()
		_arms_back()
		_neck()
		_head()
		_hair()
		_face()
		_hat()
		_arms_front()
		p.outline(Color("120e14"))

	# ------------------------------------------------------------ legs and shoes
	func _legs() -> void:
		var pants := bottom
		if kind == "coveralls" or kind == "tracksuit" or kind == "police": pants = bottom
		var lw := 4
		for side in [-1, 1]:
			var x0: int = C - lw - 1 + (0 if side < 0 else lw + 2) - (0 if side < 0 else 1)
			if side < 0: x0 = C - lw - 1
			else: x0 = C + 1
			p.rect(x0, leg_y, lw, foot_y - leg_y, pants)
			p.vline(x0 + lw - 1, leg_y, foot_y - leg_y, pants.darkened(0.2))
			p.vline(x0, leg_y + 2, foot_y - leg_y - 2, pants.lightened(0.08))
			# knee crease and jeans wear
			p.hline(x0 + 1, leg_y + 11, 2, pants.darkened(0.15))
			if kind == "tracksuit": p.vline(x0 + (0 if side < 0 else lw - 1), leg_y, foot_y - leg_y, Color("e8e8e8"))
			if kind == "police": p.vline(x0 + (0 if side < 0 else lw - 1), leg_y, foot_y - leg_y, Color("d8b030"))
			var sc := Pix.hex(int(o.get("shoes", 0x2a221c)))
			p.rect(x0 - (1 if side < 0 else 0), foot_y, lw + 2, 2, sc)
			p.hline(x0 - (1 if side < 0 else 0), foot_y + 1, lw + 2, sc.darkened(0.35))
		# belt
		p.rect(C - tw / 2, leg_y - 1, tw, 2, Color("1a1614") if kind != "police" else Color("0e0e10"))
		if kind != "coveralls" and kind != "hoodie" and kind != "leather": p.px(C, leg_y - 1, Color("b89848"))

	# ------------------------------------------------------------ torso and clothes
	func _torso() -> void:
		var x0 := C - tw / 2
		var hgt := leg_y - torso_y
		var c := top
		match kind:
			"suit", "leather":
				p.rect(x0, torso_y, tw, hgt, c)
				var inner := Pix.hex(int(o.get("inner", o.get("shirt", 0xe8e4dc))))
				# the open front: shirt V, lapels
				for y in range(torso_y, torso_y + 12):
					var hw := 1 + (y - torso_y) / 4
					p.rect(C - hw, y, hw * 2, 1, inner)
				p.line(C - 2, torso_y, C - 4, torso_y + 9, c.lightened(0.25))
				p.line(C + 1, torso_y, C + 3, torso_y + 9, c.lightened(0.15))
				if kind == "suit": p.vline(C, torso_y + 10, 8, c.darkened(0.25))
				else: p.rect(x0 + 1, torso_y + 13, tw - 2, 1, c.lightened(0.18))   # jacket zip line
			"hoodie":
				p.rect(x0, torso_y, tw, hgt, c)
				p.rect(x0 + 2, torso_y + 11, tw - 4, 4, c.darkened(0.15))                # front pocket
				p.hline(x0 + 2, torso_y + 11, tw - 4, c.darkened(0.25))
				p.vline(C - 2, torso_y + 1, 4, Color("e8e4dc"))                          # drawstrings
				p.vline(C + 1, torso_y + 1, 3, Color("e8e4dc"))
				p.rect(x0 - 1, torso_y - 2, tw + 2, 3, c.darkened(0.1))                  # the hood, bunched behind the neck
				p.rect(x0, leg_y - 3, tw, 2, c.darkened(0.12))                           # waistband
			"jersey":
				p.rect(x0, torso_y, tw, hgt, c)
				p.rect(x0, torso_y + 13, tw, 2, Color("e8e4dc"))
				p.text(C - 3, torso_y + 5, str((int(look.skin) * 7 + 9) % 99), Color("e8e4dc"))
			"tracksuit":
				p.rect(x0, torso_y, tw, hgt, c)
				p.vline(C, torso_y + 1, hgt - 2, c.lightened(0.3))                         # zip
				p.rect(C - 2, torso_y, 4, 2, c.darkened(0.2))
			"coveralls":
				p.rect(x0, torso_y, tw, hgt, c)
				p.vline(C, torso_y + 2, hgt - 2, c.darkened(0.25))
				if o.get("patch", false):
					p.rect(C - 5, torso_y + 4, 4, 2, Color("e8e4dc"))
					p.px(C - 4, torso_y + 4, Color("c8342c"))
				p.rect(x0 + 1, torso_y + 10, 3, 3, c.darkened(0.15))                     # chest pocket with a pen
				p.vline(x0 + 2, torso_y + 9, 2, Color("c8342c"))
			"hivis":
				p.rect(x0, torso_y, tw, hgt, c)
				var vest := Color("f08a1c")
				p.rect(x0, torso_y + 1, 4, hgt - 3, vest)
				p.rect(x0 + tw - 4, torso_y + 1, 4, hgt - 3, vest)
				p.rect(x0, torso_y + 9, 4, 1, Color("d8dce0"))
				p.rect(x0 + tw - 4, torso_y + 9, 4, 1, Color("d8dce0"))
				p.rect(x0, torso_y + 13, 4, 1, Color("d8dce0"))
				p.rect(x0 + tw - 4, torso_y + 13, 4, 1, Color("d8dce0"))
			"police":
				p.rect(x0, torso_y, tw, hgt, c)
				p.rect(x0 + 1, torso_y + 4, 2, 2, Color("d8b030"))                       # badge
				p.rect(x0, torso_y - 1, tw, 2, c.lightened(0.12))
				p.rect(x0 - 1, torso_y, 2, 2, c.lightened(0.2))                          # epaulettes
				p.rect(x0 + tw - 1, torso_y, 2, 2, c.lightened(0.2))
				p.rect(x0 + tw - 4, leg_y - 4, 3, 3, Color("101012"))                     # radio
				p.px(x0 + tw - 3, leg_y - 6, Color("101012"))
			"plaid":
				p.rect(x0, torso_y, tw, hgt, c)
				for y in range(torso_y, leg_y):
					for x in range(x0, x0 + tw):
						if (x % 4 == 0) or (y % 4 == 0): p.px(x, y, c.darkened(0.35))
						if x % 4 == 0 and y % 4 == 0: p.px(x, y, Color("1a1012"))
				p.vline(C, torso_y + 2, hgt - 2, Color("e8dcc0"))                            # buttons
			_:
				p.rect(x0, torso_y, tw, hgt, c)
				p.rect(C - 2, torso_y, 4, 2, c.darkened(0.25))                             # collar
		# light from the upper left: shade the right side, catch the left shoulder
		p.darken_rect(x0 + tw - 2, torso_y, 2, hgt, 0.18)
		p.hline(x0 + 1, torso_y, 3, top.lightened(0.18))
		# shoulders round off
		p.px(x0, torso_y, Color(0, 0, 0, 0))
		p.img.set_pixel(x0, torso_y, Color(0, 0, 0, 0))
		p.img.set_pixel(x0 + tw - 1, torso_y, Color(0, 0, 0, 0))
		if o.get("chain", false) or int(look.get("chain", 0)) == 1:
			for k in 5: p.px(C - 2 + k, torso_y + 1 + (1 if k > 0 and k < 4 else 0) + (1 if k == 2 else 0), Color("e8c040"))

	func _neck() -> void:
		p.rect(C - 1, torso_y - 3 + (1 if pose == "bow" else 0), 3, 3, skin_d)

	# ------------------------------------------------------------ head
	func _head_rows() -> Array:
		# half-widths from the crown down: a rounded skull, cheeks, a jaw that narrows
		var jaw := 3 if fem else 4
		return [3, 4, 4, 5, 5, 5, 5, 5, 4, jaw, 2]

	func _head() -> void:
		var rows := _head_rows()
		var y0 := head_y + (1 if pose == "bow" else 0)
		for k in rows.size():
			var hw: int = rows[k]
			p.rect(C - hw + 1, y0 + k, hw * 2 - 1, 1, skin)
			p.px(C + hw - 1, y0 + k, skin_d)                         # shadow side
			if k >= 2 and k <= 6: p.px(C - hw + 1, y0 + k, skin_l)   # lit cheek
		# the ear on the shadow side
		p.px(C - 5, y0 + 6, skin_d)
		p.px(C - 5, y0 + 7, skin_d)

	func _face() -> void:
		var y0 := head_y + (1 if pose == "bow" else 0)
		var down := 1 if pose == "phone" else 0
		var eye_y := y0 + 5 + down
		var ink := Color("2a1e18")
		var brow := hair_d if int(look.hair) != 0 else skin.darkened(0.35)
		if pose == "bow":
			p.hline(C - 2, eye_y + 1, 2, ink)
			p.hline(C + 2, eye_y + 1, 2, ink)
		else:
			# eyes look the way the head turns (facing right; the sprite flips for left)
			p.px(C - 1, eye_y, ink)
			p.px(C + 3, eye_y, ink)
			if not fem or true: pass
			p.px(C - 2, eye_y, Color("f0ece4"))
			p.px(C + 2, eye_y, Color("f0ece4"))
			p.hline(C - 2, eye_y - 2 + (1 if int(look.brows) == 2 else 0), 2, brow)
			p.hline(C + 2, eye_y - 2 + (1 if int(look.brows) == 2 else 0), 2, brow)
		# nose: a shadow on the far side and a nostril
		p.px(C + 3, eye_y + 2, skin_d)
		p.px(C + 2, eye_y + 2, skin.darkened(0.1))
		# mouth
		var mouth := Color("7a3a34") if not fem else Color("9a3a44")
		if frame == 1:
			p.rect(C, eye_y + 4, 3, 2, Color("3a1418"))
			p.px(C + 1, eye_y + 4, Color("e8e0d8"))
		else:
			p.hline(C, eye_y + 4, 3, mouth)
			if String(look.get("expr", "")) == "smirk": p.px(C + 3, eye_y + 3, mouth)
		# beard
		match int(look.beard):
			1, 5:
				for y in range(eye_y + 3, y0 + 11):
					for x in range(C - 3, C + 5):
						if (x + y) % 2 == 0 and p.get_px(x, y).to_rgba32() == skin.to_rgba32(): p.px(x, y, skin.darkened(0.22))
			2:
				p.hline(C - 1, eye_y + 3, 5, hair_d)
				p.rect(C, eye_y + 5, 3, 2, hair)
			3, 6:
				for y in range(eye_y + 2, y0 + 12 + (2 if int(look.beard) == 6 else 0)):
					for x in range(C - 4, C + 6):
						var cur := p.get_px(x, y)
						if cur.a > 0.0 and not (y == eye_y + 4 and x >= C and x <= C + 2):
							p.px(x, y, hair if (x + y) % 3 != 0 else hair_d)
				if int(look.beard) == 6: p.rect(C - 2, y0 + 11, 6, 3, hair)
			4:
				p.vline(C - 4, eye_y + 1, 4, hair_d)
				p.hline(C - 3, y0 + 10, 7, hair_d)
		# glasses
		if int(look.glasses) > 0:
			# at this size, glasses are a frame line over the eyes and a glint on each lens
			var g := Color("1a1614") if int(look.glasses) == 2 else Color("5a5a62")
			p.hline(C - 3, eye_y - 1, 8, g)
			p.px(C - 3, eye_y, g)
			p.px(C + 4, eye_y, g)
			p.px(C - 2, eye_y, Color("c8dce8"))
			p.px(C + 2, eye_y, Color("c8dce8"))
		if int(look.scar) > 0: p.px(C - 2, eye_y + 2, skin.darkened(0.3))

	func _hair() -> void:
		var y0 := head_y + (1 if pose == "bow" else 0)
		var hs := int(look.hair)
		var hl := hair.lightened(0.18)
		match hs:
			0:
				p.px(C - 2, y0 + 1, skin.lightened(0.3))          # the shine
				p.px(C - 4, y0 + 5, hair_d)                       # a fringe at the sides
				p.px(C - 4, y0 + 4, hair_d)
			1:
				for x in range(C - 3, C + 4): p.px(x, y0, hair_d if x % 2 == 0 else hair)
				p.hline(C - 4, y0 + 1, 9, hair_d)
				p.px(C - 4, y0 + 2, hair_d)
			2, 3:
				p.rect(C - 3, y0 - 1, 7, 1, hair)
				p.rect(C - 4, y0, 9, 2, hair)
				p.rect(C - 5, y0 + 1, 2, 4, hair)                # back and side
				p.hline(C - 3, y0 - 1, 3, hl)
				if hs == 3:
					p.rect(C - 1, y0 - 2, 6, 2, hair)              # the quiff
					p.hline(C, y0 - 2, 3, hl)
				p.px(C + 4, y0 + 2, hair)                          # sideburn
			4:
				p.rect(C - 1, y0 - 3, 3, 4, hair)
				p.vline(C - 1, y0 - 3, 4, hl)
				p.px(C - 4, y0 + 3, hair_d)
			5, 9:
				p.rect(C - 4, y0 - 1, 9, 2, hair)
				p.rect(C - 5, y0, 3, 12 + (4 if fem else 0), hair)       # down the back
				p.rect(C + 3, y0 + 1, 2, 3, hair)
				p.vline(C - 6, y0 + 3, 9 + (4 if fem else 0), hair_d)
				p.hline(C - 2, y0 - 1, 4, hl)
				if hs == 9:
					p.px(C, y0 - 1, hair_d)                          # middle part
					p.vline(C + 4, y0 + 3, 7, hair)                  # waves down the near side
					p.vline(C + 5, y0 + 5, 5, hair_d)
			6:
				for x in range(C - 4, C + 5):
					p.vline(x, y0 - 1, 2, hair if x % 2 == 0 else hair_d)
				if fem: p.rect(C - 6, y0 + 2, 2, 10, hair)
			7:
				p.rect(C - 4, y0 - 1, 9, 2, hair)
				p.rect(C - 5, y0, 2, 4, hair)
				p.rect(C - 7, y0 + 1, 3, 3, hair)                   # the bun / ponytail
				p.px(C - 7, y0 + 1, hl)
				if fem: p.vline(C - 7, y0 + 4, 6, hair)
			8:
				for y in range(y0 - 3, y0 + 5):
					for x in range(C - 6, C + 6):
						var d := Vector2(x - C, (y - y0 - 1) * 1.3).length()
						if d < 6.5 and (y < y0 + 2 or x < C - 3):
							p.px(x, y, hl if (x * 3 + y) % 5 == 0 else (hair_d if (x + y * 2) % 4 == 0 else hair))
		if fem and hs in [2, 3]:
			p.rect(C - 5, y0 + 1, 2, 9, hair)                      # a bob
			p.rect(C + 4, y0 + 2, 1, 6, hair)

	func _hat() -> void:
		var y0 := head_y + (1 if pose == "bow" else 0)
		var h := String(o.get("hat", ""))
		if h == "" and int(look.beanie) == 1: h = "beanie"
		var hc := Pix.hex(int(o.get("hat_c", 0x2a2a30)))
		match h:
			"cap":
				p.rect(C - 4, y0 - 1, 9, 3, hc)
				p.hline(C - 3, y0 - 1, 4, hc.lightened(0.15))
				p.rect(C + 3, y0 + 1, 4, 1, hc.darkened(0.2))         # the bill, facing forward
			"cap_back":
				p.rect(C - 4, y0 - 1, 9, 3, hc)
				p.rect(C - 7, y0 + 1, 4, 1, hc.darkened(0.2))         # backwards
				p.hline(C - 3, y0 - 1, 4, hc.lightened(0.15))
			"trucker":
				p.rect(C - 4, y0 - 2, 9, 4, Color("e8e4dc"))
				p.rect(C - 4, y0 - 2, 9, 2, hc)
				p.rect(C + 3, y0 + 1, 4, 1, hc.darkened(0.2))
				p.rect(C - 3, y0, 3, 2, Color("d8d4cc"))
			"beanie":
				p.rect(C - 4, y0 - 2, 9, 4, hc)
				p.hline(C - 4, y0 + 1, 9, hc.darkened(0.25))
				p.px(C, y0 - 3, hc.lightened(0.2))
			"police":
				p.rect(C - 4, y0 - 2, 9, 3, Color("1c2232"))
				p.rect(C - 4, y0, 9, 1, Color("d8b030"))
				p.rect(C + 3, y0 + 1, 3, 1, Color("0e0e12"))
				p.px(C, y0 - 1, Color("d8b030"))

	# ------------------------------------------------------------ arms
	func _sleeve() -> Color:
		match kind:
			"hivis": return top
			"leather", "suit": return top.lightened(0.05)
		return top

	func _short_sleeves() -> bool:
		return kind == "shirt" or kind == "jersey"

	## The far arm (behind the body, on the shadow side): mostly hidden, a sliver shows.
	func _arms_back() -> void:
		var x := C - tw / 2 - 3
		var s := _sleeve().darkened(0.15)
		match pose:
			"crossed", "bow", "phone", "hips":
				p.rect(x, torso_y + 1, 3, 9, s)
			_:
				p.rect(x, torso_y + 1, 3, 15, s)
				if _short_sleeves(): p.rect(x, torso_y + 7, 3, 9, skin_d)
				if pose != "pockets": p.rect(x, torso_y + 16, 3, 3, skin_d)

	## The near arm, over the body.
	func _arms_front() -> void:
		var xr := C + tw / 2
		var s := _sleeve()
		var sk := skin
		match pose:
			"stand", "pockets", "wave":
				if pose == "wave":
					p.rect(xr, torso_y - 6, 3, 8, s)
					p.rect(xr, torso_y - 9, 3, 3, sk)
					p.rect(xr, torso_y + 1, 3, 2, s)
				else:
					p.rect(xr, torso_y + 1, 3, 15, s)
					p.vline(xr + 2, torso_y + 1, 15, s.darkened(0.2))
					if _short_sleeves(): p.rect(xr, torso_y + 7, 3, 9, sk)
					if pose == "stand":
						p.rect(xr, torso_y + 16, 3, 3, sk)
						p.px(xr + 2, torso_y + 18, skin_d)
					else:
						p.hline(xr - 1, torso_y + 15, 3, s.darkened(0.3))   # into the pocket
			"crossed":
				p.rect(xr, torso_y + 1, 3, 8, s)
				p.rect(C - tw / 2 - 1, torso_y + 8, tw + 3, 4, s)        # forearms folded across
				p.hline(C - tw / 2 - 1, torso_y + 8, tw + 3, s.lightened(0.12))
				p.hline(C - tw / 2 - 1, torso_y + 11, tw + 3, s.darkened(0.25))
				p.rect(C - tw / 2 - 1, torso_y + 9, 2, 2, sk)
				p.rect(xr - 1, torso_y + 9, 2, 2, sk)
			"cup":
				p.rect(xr, torso_y + 1, 3, 9, s)
				p.rect(xr, torso_y + 9, 6, 3, s)
				if _short_sleeves(): p.rect(xr, torso_y + 9, 6, 3, sk)
				p.rect(xr + 5, torso_y + 9, 2, 3, sk)
				p.rect(xr + 5, torso_y + 4, 4, 6, Color("c8242c"))       # the red cup
				p.hline(xr + 5, torso_y + 4, 4, Color("f0ece4"))
				p.vline(xr + 8, torso_y + 5, 5, Color("8e1a20"))
			"phone":
				p.rect(xr, torso_y + 1, 3, 7, s)
				p.rect(C, torso_y + 6, xr - C + 2, 3, s)
				p.rect(C - 1, torso_y + 3, 3, 3, sk)
				p.rect(C - 1, torso_y + 1, 3, 4, Color("16161c"))         # the phone
				p.px(C, torso_y + 2, Color("8ad0ff"))
				p.px(C, torso_y + 3, Color("8ad0ff"))
			"bow":
				p.rect(xr, torso_y + 1, 3, 8, s)
				p.rect(C - 2, torso_y + 8, xr - C + 4, 3, s)
				p.rect(C - 2, torso_y + 11, 4, 3, sk)                    # hands folded
				p.vline(C, torso_y + 11, 3, skin_d)
			"point":
				p.rect(xr, torso_y + 1, 3, 3, s)
				p.rect(xr, torso_y + 1, 9, 3, s)
				p.rect(xr + 9, torso_y + 1, 2, 3, sk)
				p.px(xr + 11, torso_y + 1, sk)
			"hips":
				p.rect(xr, torso_y + 1, 3, 6, s)
				p.rect(xr + 1, torso_y + 6, 3, 6, s)
				p.rect(xr - 1, torso_y + 12, 3, 3, sk)
				p.rect(C - tw / 2 - 4, torso_y + 6, 3, 6, s.darkened(0.15))
		if kind == "hivis" and pose in ["stand", "pockets"]:
			p.hline(xr, torso_y + 10, 3, Color("d8dce0"))
		if kind == "tracksuit" and pose in ["stand", "pockets", "crossed"]:
			p.vline(xr + 2, torso_y + 1, 14, Color("e8e8e8"))
