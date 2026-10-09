## The loading screen between everything: a car from the garage of the universe driving past
## the Maritimes at some hour of the day, and a card underneath with a tip, a bit of Port
## Rumble lore, a fake local ad or some car trivia. Loads the next scene on a thread while you
## read, waits a moment so you can, then goes.
##   LoadingScreen.go(get_tree(), "res://drive.tscn", "AIRSTRIP 7")
class_name LoadingScreen
extends Node2D

const INK := Color("0b090d")
const BONE := Color("f3ead2")
const GOLD := Color("d9a441")
const ASH := Color("8a8478")

const MIN_TIME := 2.4

static var next_path := "res://title.tscn"
static var label := ""
static var _seen: Array = []

## Everything the loading card can say. [kind, text]. Kinds: TIP, LORE, AD, TRIVIA, GUS.
const CARDS := [
	["TIP", "THE INSPECTION COUNTER: CHECK THE VIN ON THE OWNERSHIP AGAINST THE VIN ON THE DASH. GUS READS IT OFF THE CAR HIMSELF. TRUST GUS."],
	["TIP", "TREAD UNDER 1.6 MM IS A FAIL. THE CUSTOMER WILL TELL YOU IT'S FINE. THE CUSTOMER IS NOT THE MINISTRY."],
	["TIP", "COLD TIRES DON'T GRIP. GIVE THEM A FEW KILOMETRES BEFORE YOU TRY ANYTHING STUPID."],
	["TIP", "WINTER TIRES IN WINTER, SUMMER TIRES IN SUMMER. ALL-SEASONS IN NEW BRUNSWICK IS A COIN TOSS WITH YOUR LIFE."],
	["TIP", "BLACK ICE LOOKS LIKE WET ROAD. IF IT'S BELOW ZERO AND THE ROAD LOOKS WET, IT ISN'T WET."],
	["TIP", "THE TEMPERATURE GAUGE IS NOT DECORATIVE. A BLOWN HEAD GASKET IS A VERY EXPENSIVE WAY TO MAKE STEAM."],
	["TIP", "HOLD THE HIGH BEAM BUTTON TO FLASH. TAP IT TO SWITCH. THE GUY COMING THE OTHER WAY WILL THANK YOU. HE WON'T, BUT HE SHOULD."],
	["TIP", "BLINKERS CANCEL THEMSELVES WHEN YOU STRAIGHTEN OUT. NOBODY ELSE IN PORT RUMBLE USES THEM, BUT YOU COULD BE THE FIRST."],
	["TIP", "THE GPS LIKES HIGHWAYS. YOU MIGHT NOT. PICK A PLACE ON THE MAP AND IT'LL GET YOU THERE ITS WAY."],
	["TIP", "PULL UP TO THE BAY DOORS AT COVINGTON AUTO AND STOP. THAT'S YOUR GARAGE. EVERYTHING YOU OWN IS IN THERE, INCLUDING REGRET."],
	["TIP", "GRASS, MUD AND GRAVEL ALL GRIP LESS THAN PAVEMENT. THE DITCH GRIPS EXACTLY ONCE."],
	["TIP", "A BUMPER THAT FALLS OFF CAN BE REPLACED. A FACE THAT GOES THROUGH A WINDSHIELD IS HARDER."],
	["TIP", "THE FAMILIA PAYS IN CASH. THE MINISTRY PAYS IN CONSEQUENCES. YOU CAN ONLY OWE ONE OF THEM SO MUCH."],
	["TIP", "MANUAL GEARBOX: SHIFT BEFORE THE REDLINE, NOT AT IT. THE LIMITER IS A WARNING, NOT A TARGET."],
	["TIP", "DRIVING DRUNK IN DRIVEBOSS IS A STORY BEAT, NOT A STRATEGY. IN REAL LIFE IT'S NEITHER. CALL A CAB."],
	["LORE", "PORT RUMBLE SITS ON THE CHOCOLATE RIVER. IT'S BROWN BECAUSE OF THE MUD, NOT THE CHOCOLATE. PEOPLE STILL ASK."],
	["LORE", "TWICE A DAY THE TIDAL BORE COMES UP THE RIVER. IT'S A WAVE ABOUT AS TALL AS A SHIN. TOURISTS CLAP."],
	["LORE", "MAGNET HILL: PUT YOUR CAR IN NEUTRAL AND IT ROLLS UPHILL. IT'S AN OPTICAL ILLUSION. SO IS THE PRICE OF GAS."],
	["LORE", "COVINGTON AUTO HAS BEEN ON THE CORNER SINCE 1987. FRANK COVINGTON BOUGHT IT WITH A LOAN, A HANDSHAKE AND SOMETHING NOBODY TALKS ABOUT."],
	["LORE", "THERE ARE THREE TIM BURTONS IN PORT RUMBLE. LOCALS HAVE OPINIONS ABOUT ALL OF THEM. THE MOUNTAIN ROAD ONE HAS THE LAMP THAT WORKS."],
	["LORE", "SALISBURY IS HALFWAY TO EVERYWHERE. THAT'S THE WHOLE PITCH."],
	["LORE", "HAVELOCK HAS A RODEO, A CHURCH AND A GUY WHO WILL WELD ANYTHING FOR A CASE OF BEER. THREE OF THE GREAT INSTITUTIONS."],
	["LORE", "AIRSTRIP 7 HASN'T SEEN A PLANE SINCE 1994. IT SEES A LOT OF CARS. THE COPS KNOW. THE COPS HAVE CARS TOO."],
	["LORE", "DOM TORTELLINI SAYS GRACE BEFORE EVERY MEET. HE ALSO SAYS IT BEFORE EVERY 'CONVERSATION.' NOBODY ASKS WHAT THAT MEANS."],
	["LORE", "THE NORTHSIDE INDUSTRIAL PARK MAKES THINGS YOU'VE NEVER HEARD OF FOR COMPANIES YOU'VE NEVER HEARD OF. IT EMPLOYS EVERYONE'S UNCLE."],
	["LORE", "THE LUTES MOUNTAIN TOWERS BLINK RED ALL NIGHT. YOU CAN SEE THEM FROM ANYWHERE. TEENAGERS USE THEM TO FIND THEIR WAY HOME. ALLEGEDLY."],
	["LORE", "IN PORT RUMBLE A FOUR-WAY STOP IS A SOCIAL EXPERIMENT. EVERYBODY WAVES EVERYBODY ELSE THROUGH UNTIL SOMEBODY DIES OF OLD AGE."],
	["AD", "CANADIAN TIRED: WE HAVE ONE OF EVERYTHING AND NONE OF WHAT YOU CAME IN FOR. MONEY BACK IN MONEY WE MADE UP."],
	["AD", "MARKETTHING.CA: BUY A STRANGER'S PROBLEMS AT A FAIR PRICE. 'RUNS GREAT' MEANS IT RUNS. 'GREAT' IS NEGOTIABLE."],
	["AD", "IRVIN GAS: WE'RE ON EVERY CORNER. WE ARE THE CORNER. WE OWN THE ROAD THAT LEADS TO THE CORNER."],
	["AD", "TIM BURTONS: ROLL UP THE RIMSHOT. WIN A DONUT, A COFFEE, OR NOTHING, WHICH IS WHAT YOU'LL WIN."],
	["AD", "DEALS ON WHEELS USED CARS, SALISBURY: NO CREDIT? BAD CREDIT? ACTIVE WARRANT? COME ON DOWN. WE DON'T ASK. WE DON'T KNOW HOW."],
	["AD", "SNAP-OFF TOOLS: THE TRUCK COMES TO YOU. SO DO THE PAYMENTS. FOREVER."],
	["AD", "THE DONAIR HUT: OPEN TILL 3. SWEET SAUCE ON EVERYTHING. EVERYTHING. DON'T ASK FOR IT ON THE SIDE. HE GETS UPSET."],
	["AD", "ROCKAUTTO.CA: EVERY PART FOR EVERY CAR, SHIPPED IN A BOX TEN TIMES TOO BIG. ORDER FROM THE SHOP COMPUTER. GUS WILL SIGN FOR IT."],
	["AD", "MARITIME TINT & TUNES: WINDOW TINT SO DARK YOU CAN'T SEE OUT. SUBWOOFERS SO BIG YOU CAN'T SEE IN. PERFECT BALANCE."],
	["AD", "COVINGTON AUTO: SAFETIES, REPAIRS, AND NO QUESTIONS. WELL. SOME QUESTIONS. GUS HAS QUESTIONS."],
	["TRIVIA", "THE NISSUN SILVIO WAS SOLD AS A SENSIBLE COUPE FOR SENSIBLE PEOPLE. NONE OF THEM ARE LEFT. THEY'RE ALL SIDEWAYS NOW."],
	["TRIVIA", "THE '86 TOYODA SUPREEM HAS A STRAIGHT SIX AND A CASSETTE DECK THAT ONLY PLAYS SIDE B."],
	["TRIVIA", "THE DODGY CHARJER IS THE ONLY FOUR-DOOR CAR THAT CAN GET A NOISE COMPLAINT WHILE PARKED."],
	["TRIVIA", "THE FJORD F-ONE-FIDDY HAS BEEN THE BEST-SELLING VEHICLE IN NEW BRUNSWICK EVERY YEAR SINCE TRUCKS WERE INVENTED. PROBABLY BEFORE."],
	["TRIVIA", "A TIRE AT HIGHWAY SPEED SPINS ABOUT 14 TIMES A SECOND. A TIRE IN THE DITCH SPINS AS MANY TIMES AS YOU'RE WILLING TO WATCH."],
	["TRIVIA", "BRAKE FLUID ABSORBS WATER OVER TIME. OLD FLUID BOILS SOONER. FRANK COVINGTON CHANGED HIS EVERY YEAR. REMEMBER THAT."],
	["TRIVIA", "A ROUND HAY BALE WEIGHS AS MUCH AS A SMALL CAR. IT DOES NOT MOVE OUT OF THE WAY LIKE A SMALL CAR."],
	["GUS", "\"A CAR WILL TELL YOU EVERYTHING THAT'S WRONG WITH IT. MOST PEOPLE JUST TURN THE RADIO UP.\""],
	["GUS", "\"THERE'S TWO KINDS OF CUSTOMERS. THE ONES WHO LIE TO YOU, AND THE ONES WHO LIE TO THEMSELVES. CHARGE THE SECOND KIND MORE.\""],
	["GUS", "\"YOUR FATHER COULD HEAR A BAD WHEEL BEARING FROM THE COFFEE MACHINE. I COULD HEAR HIM HEARING IT.\""],
	["GUS", "\"DON'T TOUCH THE MUG.\""],
	["GUS", "\"RUST IS JUST THE CAR GOING BACK TO WHERE IT CAME FROM. SO ARE WE ALL. PASS ME THE 10 MIL.\""],
	["GUS", "\"NEVER TRUST A MAN WHO WASHES HIS ENGINE. HE'S HIDING SOMETHING, AND IT'S A LEAK.\""],
]

## Go somewhere, through the loading screen.
static func go(tree: SceneTree, path: String, where := "") -> void:
	next_path = path
	label = where
	tree.change_scene_to_file.call_deferred("res://ui/loading.tscn")

var t := 0.0
var card: Array = []
var lines: Array[String] = []
var big := true
var car_tex: ImageTexture
var car_len := 220
var body := "coupe"
var mods := {}
var paint := Color.RED
var hour := 12.0
var wheels: Array = []        # [x offset, radius]
var wheel_frames: Array[ImageTexture] = []
var rng := RandomNumberGenerator.new()
var requested := false
var done := false

func _ready() -> void:
	rng.randomize()
	# never the same card twice in a row (or in the last dozen)
	var pick: Array = CARDS[rng.randi() % CARDS.size()]
	for tries in 20:
		pick = CARDS[rng.randi() % CARDS.size()]
		if not _seen.has(pick[1]): break
	_seen.append(pick[1])
	if _seen.size() > 12: _seen.pop_front()
	card = pick
	lines = BigFont.wrap(String(card[1]), 600, 2, false)
	big = lines.size() <= 3
	if not big: lines = BigFont.wrap(String(card[1]), 600, 1, true)
	# a car out of the garage of the universe, tuned at random
	var bodies := PixCars.BODIES.keys()
	body = String(bodies[rng.randi() % bodies.size()])
	var paints := ["#c8342c", "#2c5a8a", "#e8e4dc", "#1e1e24", "#e8a020", "#2a6a3a", "#6a2a4a", "#d8d4c8", "#4a6a8a", "#8a8e94"]
	paint = Color(paints[rng.randi() % paints.size()])
	mods = { "rim": PixCars.RIMS[rng.randi() % PixCars.RIMS.size()], "drop": rng.randf() * 0.8,
		"spoiler": ["none", "none", "ducktail", "wing", "gt"][rng.randi() % 5], "finish": ["gloss", "gloss", "metallic", "matte", "pearl"][rng.randi() % 5],
		"tint": rng.randf(), "stripes": ["none", "none", "none", "racing", "side"][rng.randi() % 5], "lights_on": true }
	if rng.randf() < 0.3: mods.kit = { "lip": true, "skirts": true }
	car_tex = ImageTexture.create_from_image(PixCars.image(car_len, body, paint, mods))
	var b: Dictionary = PixCars.BODIES[body]
	var r := float(b.wheel) * car_len
	wheels = [[20 + float(b.wr) * car_len, r], [20 + float(b.wf) * car_len, r]]
	for k in 8:
		var img := Pix.new(int(r * 2.0) + 4, int(r * 2.0) + 4, 1)
		PixCars.wheel(img, int(r) + 2, int(r) + 2, r, String(mods.rim), false, mods, float(k) * TAU / 40.0)
		wheel_frames.append(ImageTexture.create_from_image(img.img))
	hour = [8.0, 13.0, 18.6, 22.5][rng.randi() % 4]
	ResourceLoader.load_threaded_request(next_path)
	requested = true

func _process(dt: float) -> void:
	t += dt
	queue_redraw()
	if done: return
	var st := ResourceLoader.load_threaded_get_status(next_path)
	if st == ResourceLoader.THREAD_LOAD_LOADED and t >= MIN_TIME:
		done = true
		var ps := ResourceLoader.load_threaded_get(next_path) as PackedScene
		get_tree().change_scene_to_packed(ps)
	elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		done = true
		get_tree().change_scene_to_file(next_path)

func _progress() -> float:
	var arr := []
	ResourceLoader.load_threaded_get_status(next_path, arr)
	var real: float = arr[0] if arr.size() > 0 else 0.0
	return minf(real, t / MIN_TIME)

# ------------------------------------------------------------------ drawing

func _sky_cols() -> Array:
	if hour < 6.0 or hour > 21.0: return [Color("05070f"), Color("1a2238"), Color("0e1220"), Color("06090a")]
	if hour > 17.5: return [Color("2a2448"), Color("f0884a"), Color("4a3a5a"), Color("1e2a1e")]
	if hour < 9.0: return [Color("6a8ab8"), Color("f0c8a0"), Color("6a7a9a"), Color("24402a")]
	return [Color("4a7ab8"), Color("b8d0e0"), Color("5a6a88"), Color("2a4a2a")]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), INK)
	var c := _sky_cols()
	var night := hour < 6.0 or hour > 21.0
	# sky
	for k in 6:
		var f := float(k) / 5.0
		draw_rect(Rect2(0, k * 30, 640, 31), (c[0] as Color).lerp(c[1], f))
	if night:
		for k in 40:
			draw_rect(Rect2((k * 97) % 640, (k * 53) % 120, 2, 2), Color(1, 1, 1, 0.5 + 0.5 * sin(t * 2.0 + k)))
	# far hills (slow), treeline (faster), poles (fast), road dashes (fastest)
	var speed := 260.0
	for x in range(0, 660, 4):
		var hx := float(x) + fmod(t * speed * 0.08, 4.0)
		var hy := 150.0 + sin((float(x) + t * speed * 0.08) * 0.012) * 14.0 + sin((float(x) + t * speed * 0.08) * 0.031) * 6.0
		draw_rect(Rect2(hx - 4, hy, 4, 200 - hy), c[2])
	var tree_c: Color = c[3]
	for k in 40:
		var tx := fposmod(float(k) * 37.0 - t * speed * 0.35, 700.0) - 30.0
		var th := 18.0 + float((k * 13) % 11)
		draw_colored_polygon(PackedVector2Array([Vector2(tx, 200 - th), Vector2(tx - 8, 202), Vector2(tx + 8, 202)]), tree_c)
	draw_rect(Rect2(0, 200, 640, 60), (c[3] as Color).darkened(0.2))
	for k in 4:
		var px := fposmod(float(k) * 190.0 - t * speed * 0.7, 760.0) - 60.0
		draw_rect(Rect2(px, 120, 4, 90), Color("3a2a1e") if not night else Color("100c08"))
		draw_rect(Rect2(px - 10, 126, 24, 3), Color("3a2a1e") if not night else Color("100c08"))
	draw_line(Vector2(-10, 128), Vector2(650, 132), Color(0, 0, 0, 0.6), 1.0)
	draw_rect(Rect2(0, 236, 640, 24), Color("2e2e34") if not night else Color("141418"))
	for k in 8:
		var dx := fposmod(float(k) * 100.0 - t * speed, 800.0) - 80.0
		draw_rect(Rect2(dx, 247, 40, 2), Color("e8c040") if not night else Color("6a5a20"))
	# the car, bobbing a hair on its springs, wheels spinning
	var cx := 200.0 + sin(t * 0.6) * 20.0
	var bob := 1.0 if fmod(t, 0.5) < 0.07 else 0.0
	var top := 252.0 - float(car_tex.get_height()) + 8.0 + bob
	draw_texture(car_tex, Vector2(cx, top))
	var fr: ImageTexture = wheel_frames[int(t * 30.0) % wheel_frames.size()]
	for w in wheels:
		draw_texture(fr, Vector2(cx + float(w[0]) - w[1] - 2.0, 252.0 - w[1] * 2.0 - 2.0 + bob))
	if night:
		draw_colored_polygon(PackedVector2Array([Vector2(cx + car_len + 18, 228), Vector2(cx + car_len + 260, 210), Vector2(cx + car_len + 260, 258)]), Color(1, 0.95, 0.75, 0.12))
	# the card
	var kind := String(card[0])
	var col: Color = { "TIP": GOLD, "LORE": Color("7ab8e0"), "AD": Color("e0402e"), "TRIVIA": Color("6fbf5a"), "GUS": Color("c8c0a8") }.get(kind, GOLD)
	var name: String = { "TIP": "TIP", "LORE": "PORT RUMBLE", "AD": "A WORD FROM OUR SPONSORS", "TRIVIA": "CAR TRIVIA", "GUS": "GUS SAYS" }.get(kind, kind)
	draw_rect(Rect2(8, 268, 624, 84), Color(0.04, 0.035, 0.05, 0.96))
	draw_rect(Rect2(8, 268, 624, 84), Color(1, 1, 1, 0.14), false, 1.0)
	draw_rect(Rect2(16, 262, PixelFont.width(name, 2) + 12, 14), col.darkened(0.55))
	PixelFont.draw(self, Vector2(22, 265), name, col.lightened(0.2), 2)
	for k in mini(lines.size(), 4):
		if big: BigFont.draw(self, Vector2(20, 284 + k * 17), lines[k], BONE, 2, false, INK)
		else: BigFont.draw(self, Vector2(20, 284 + k * 12), lines[k], BONE, 1, true)
	# progress, and where we're going
	var pr := _progress()
	draw_rect(Rect2(20, 340, 440, 4), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(20, 340, 440 * pr, 4), col)
	var where := ("LOADING " + label) if label != "" else "LOADING"
	PixelFont.draw(self, Vector2(624 - PixelFont.width(where), 338), where + ".".repeat(int(t * 3.0) % 4), ASH)
