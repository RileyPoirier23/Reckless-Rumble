## 1ton, of the Luchadooros. The club has three leaders: La Calavera runs the streets, El Pulpo
## runs his mouth, and 1ton runs the bays. Enormous man, enormous beard, enormous widow's peak,
## a laminated list of the cars that count, and a mother who has opinions about all of them.
## Show him a car that's on the list and he joins your crew at Covington Auto: bay three,
## hydraulics and donks, and he won't take money for the labour (his mother would hear about it).
class_name OneTon
extends RefCounted

const NAME := "1TON"
const CLUB := "THE LUCHADOOROS"
const LEADERS := [["1TON", "THE BAYS"], ["LA CALAVERA", "THE STREETS"], ["EL PULPO", "HIS MOUTH"]]

## His face: the same man as on The Lucha Lowdown (CageBoss), painted by the same painter.
const FACE := {
	"id": "oneton", "female": false, "age": 31, "attire": "hoodie", "accent": 0x6a4c72, "bg": 0x383444, "expr": "flat",
	"look": { "head": 3, "skin": 3, "hair": 2, "hairColor": 0, "beard": 3, "brows": 2, "eyes": 0, "nose": 1, "ears": 0,
		"scar": 0, "tattoo": 0, "build": 2, "glasses": 0, "widow": 1, "stoned": 0, "beanie": 0, "hat": 0, "iris": -1,
		"freckles": 0, "chain": 1 },
}

static var _face: ImageTexture

static func face() -> ImageTexture:
	if _face == null: _face = ImageTexture.create_from_image(Face._to_image(Face.paint(FACE), Face.P, Face.P))
	return _face

# ------------------------------------------------------------------ the list

## The models on the laminated list: the big rear-drive sedans and coupes a lowrider or a donk
## is made from. (He has them laminated. He will show you.)
const LIST := ["IMPALER", "CAPREES", "MALIBOO", "CUTLESS SUPREMO", "GRAND NASHUNAL", "BROUGHAMM", "TOWN CARR",
	"BONNEVILLAIN", "CROWN VICTORIOUS", "CHARJER"]

static func on_list(spec: Dictionary) -> bool:
	if String(spec.get("drivetrain", "")) != "RWD": return false
	var model := String(spec.get("model", "")).to_upper()
	if model.contains("STRETCH") or model.contains("WAGON"): return false
	for m in LIST:
		if model.begins_with(m): return true
	return false

# ------------------------------------------------------------------ bay three

## Hydraulics: pumps, dumps and batteries in the trunk. Each kit hops higher (metres off the
## ground at the top of a hop), and weighs what it weighs.
const HYD := [
	{ "name": "NONE", "price": 0, "hop": 0.0, "kg": 0.0 },
	{ "name": "TWO PUMPS", "price": 2400, "hop": 0.35, "kg": 70.0 },
	{ "name": "THREE PUMPS", "price": 3600, "hop": 0.6, "kg": 95.0 },
	{ "name": "FOUR PUMPS", "price": 5200, "hop": 0.9, "kg": 125.0 },
]
## Donk kits: a lift and big rims (inches), with the tire that goes on them.
const DONK := [
	{ "name": "STOCK", "price": 0, "rim": 0, "tire": "", "lift": 0.0 },
	{ "name": "24-INCH", "price": 3200, "rim": 24, "tire": "275/25R24", "lift": 0.06 },
	{ "name": "26-INCH", "price": 4400, "rim": 26, "tire": "255/30R26", "lift": 0.1 },
	{ "name": "28-INCH", "price": 5800, "rim": 28, "tire": "265/25R28", "lift": 0.14 },
	{ "name": "30-INCH", "price": 7400, "rim": 30, "tire": "265/25R30", "lift": 0.18 },
]

static func hyd_of(entry: Dictionary) -> int:
	return clampi(int((entry.get("custom", {}) as Dictionary).get("hyd", 0)), 0, HYD.size() - 1)

static func donk_of(entry: Dictionary) -> int:
	return clampi(int((entry.get("custom", {}) as Dictionary).get("donk", 0)), 0, DONK.size() - 1)

## A tire's radius in metres, from its size ("265/25R28").
static func tire_radius(size: String) -> float:
	var a := size.split("/")
	if a.size() < 2: return 0.0
	var b := a[1].split("R")
	if b.size() < 2: return 0.0
	return (float(b[1]) * 25.4 / 2.0 + float(a[0]) * float(b[0]) / 100.0) / 1000.0

## What 1ton's work does to how the car drives: the big wheels gear it up and weigh more, the
## lift raises everything, the pumps and batteries weigh what they weigh and soften the grip.
static func apply(spec: Dictionary, entry: Dictionary) -> Dictionary:
	var h := hyd_of(entry)
	var d := donk_of(entry)
	if h == 0 and d == 0: return spec
	var s := spec.duplicate(true)
	if d > 0:
		var k: Dictionary = DONK[d]
		var r := tire_radius(String(k.tire))
		if r > 0.0 and s.has("tires"):
			s.tires.radius = r
			s.tires.size = String(k.tire)
			s.tires.driven_inertia = float(s.tires.get("driven_inertia", 3.0)) * pow(r / 0.33, 2.0) * 1.3
		s.mass = float(s.mass) + 25.0 * float(k.rim - 20)
		s.cg_height = float(s.get("cg_height", 0.5)) + float(k.lift)
		s.grip = float(s.get("grip", 1.0)) * (1.0 - 0.012 * float(k.rim - 20))
	if h > 0:
		s.mass = float(s.mass) + float(HYD[h].kg)
		s.grip = float(s.get("grip", 1.0)) * 0.97
	return s

## And how it looks, side on and from above: lifted on big rims, or (with pumps and no donk) sitting low.
static func looks(entry: Dictionary, m: Dictionary) -> Dictionary:
	var d := donk_of(entry)
	if d > 0:
		m.drop = -clampf(0.45 + d * 0.14, 0.0, 1.0)
		m.rim_size = 0.84
	elif hyd_of(entry) > 0 and not m.has("drop"):
		m.drop = 0.8
	return m

# ------------------------------------------------------------------ hopping

## One step of a hop: the height (m) and its speed, with the button `held` (the pumps push it up)
## or not (it drops and bounces). `kit` is the hydraulics level. Returns [height, speed].
static func hop_step(h: float, v: float, dt: float, held: bool, kit: int) -> Array:
	var top := float(HYD[clampi(kit, 0, HYD.size() - 1)].hop)
	if top <= 0.0: return [0.0, 0.0]
	if held and h <= 0.02 and v <= 0.0:
		v = sqrt(2.0 * 9.81 * top)                  # the dump: off the ground
	v -= 9.81 * dt
	h += v * dt
	if h <= 0.0:
		h = 0.0
		v = -v * 0.35 if v < -0.6 else 0.0        # a bounce or two on the springs
	return [h, v]

# ------------------------------------------------------------------ what he says

const INTRO := [
	"1TON. THE LUCHADOOROS.",
	"I RUN THE BAYS. LA CALAVERA RUNS THE STREETS. EL PULPO RUNS HIS MOUTH.",
	"YOU'RE FROM COVINGTON AUTO. I KNOW. I HAVE A LIST.",
	"BRING ME A PROPER CAR. IT IS ON THE LIST. THE LIST IS LAMINATED.",
]
const TALK := [
	"MY MOTHER SAYS A CAR SHOULD SIT LOW, LIKE A GOOD MAN. I DON'T KNOW WHAT THAT MEANS. I AGREE WITH IT.",
	"THE BEARD STAYS OUT OF THE PUMPS. MOSTLY.",
	"THREE PUMPS IS A CAR. FOUR PUMPS IS A LIFESTYLE.",
	"MY ABUELA HAD A '64 IMPALER. SHE HOPPED IT AT CHURCH. ONCE. THEY STILL TALK ABOUT IT.",
	"TWENTY-SIX INCHES. MINIMUM. I WROTE IT DOWN. I UNDERLINED IT THREE TIMES.",
	"PEOPLE SAY DONKS ARE TOO BIG. PEOPLE SAY THAT ABOUT ME. WE ARE BOTH FINE.",
	"OKAY, BUT WHAT ABOUT THE HYDRAULICS?",
	"I DO NOT LAUGH. THE BEARD LAUGHS. A LITTLE.",
	"LA CALAVERA SAYS HI. LA CALAVERA DOES NOT SAY HI. I SAY HI FOR HER.",
	"EL PULPO SAYS HE CAN HOP HIGHER THAN ME. EL PULPO IS WRONG ABOUT MANY THINGS.",
]
const NOT_ON_LIST := [
	"NO. THAT IS NOT ON THE LIST. I CHECKED. TWICE. IT IS STILL NOT ON THE LIST.",
	"THAT IS A CAR. IT IS NOT A PROPER CAR. THERE IS A DIFFERENCE. IT IS LAMINATED.",
	"MY MOTHER WOULD NOT GET IN THAT. MY MOTHER GETS IN EVERYTHING.",
]
const JOINS := [
	"THAT. THAT IS ON THE LIST.",
	"I WILL COME TO COVINGTON AUTO. BAY THREE. I DO NOT TAKE MONEY FOR LABOUR. MY MOTHER WOULD HEAR ABOUT IT.",
	"YOU PAY FOR THE PARTS. THE PARTS ARE NOT CHEAP. NOTHING GOOD IS CHEAP. EXCEPT MY MOTHER'S TAMALES. THOSE ARE FREE.",
]
const BAY := [
	"FOUR PUMPS. THE BATTERIES GO IN THE TRUNK. YOUR GROCERIES GO IN YOUR LAP.",
	"TWENTY-EIGHTS. IT WILL TURN LIKE A SHIP. IT WILL LOOK LIKE A KING.",
	"I TORQUED EVERY LUG BY HAND. THE BEARD HELD THE SOCKET.",
	"THE HOP IS IN THE WRIST. AND THE PUMPS. MOSTLY THE PUMPS.",
	"GUS ASKED WHAT A DONK IS. I SHOWED HIM. HE SAT DOWN FOR A WHILE.",
]

## Whether he's in your crew.
static func in_crew(save: Dictionary) -> bool:
	return bool((save.get("crew", {}) as Dictionary).get("oneton", false))

## Show him a car: on the list, he joins (and says so); not, he tells you. Returns his lines.
static func show_car(save: Dictionary, spec: Dictionary, day: int) -> Array:
	if in_crew(save): return [TALK[day % TALK.size()]]
	if not on_list(spec): return [NOT_ON_LIST[day % NOT_ON_LIST.size()]]
	var crew: Dictionary = save.get("crew", {})
	crew.oneton = true
	save.crew = crew
	return JOINS.duplicate()
