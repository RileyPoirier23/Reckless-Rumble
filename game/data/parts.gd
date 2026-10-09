## Every performance part you can order for a car, and what it does to the physics.
## A car has one part per slot (or stock). Parts.apply(spec, installed) returns the spec the
## sim drives: torque curve reshaped, turbos bolted on, gearing changed, weight gone, grip,
## brakes, aero. Prices in CAD. Shipping is from ROCKAUTTO.CA (the shop computer) or the
## Snap-Off truck; Gus installs.
##
## Effects: torque (x all rpm), torque_lo (x low end), torque_hi (x top end), redline (+rpm),
## turbo ({spool_rpm, lag, no_boost}: bolts a turbo or blower on, or replaces it), inertia (x),
## clutch (+N·m), final (x), shift (x shift time), mass (+kg), cg (+m), rear_grip (+),
## grip (x), steer (+rad), brakes (x), fade (+°C), cda (+), cl (downforce coefficient),
## compound (tyres), lsd (0 open .. 1 locked), drop (looks: ride height), wear (x engine wear).
class_name Parts
extends RefCounted

const SLOTS := ["intake", "exhaust", "headers", "cams", "ecu", "induction", "intercooler", "clutch", "flywheel",
	"final", "lsd", "suspension", "swaybar", "weight", "steering", "pads", "brakes", "tires", "aero"]

const SLOT_NAMES := { "intake": "INTAKE", "exhaust": "EXHAUST", "headers": "HEADERS", "cams": "CAMSHAFTS", "ecu": "ECU / TUNE",
	"induction": "TURBO / BLOWER", "intercooler": "INTERCOOLER", "clutch": "CLUTCH", "flywheel": "FLYWHEEL", "final": "FINAL DRIVE",
	"lsd": "DIFFERENTIAL", "suspension": "SUSPENSION", "swaybar": "SWAY BARS", "weight": "WEIGHT", "steering": "STEERING",
	"pads": "BRAKE PADS", "brakes": "BRAKE KIT", "tires": "TIRES", "aero": "AERO" }

const GROUPS := [["ENGINE", ["intake", "exhaust", "headers", "cams", "ecu", "induction", "intercooler"]],
	["DRIVETRAIN", ["clutch", "flywheel", "final", "lsd"]],
	["CHASSIS", ["suspension", "swaybar", "weight", "steering"]],
	["BRAKES & TIRES", ["pads", "brakes", "tires"]],
	["AERO", ["aero"]]]

## id: [slot, name, price, days to ship, effects, blurb]
const CATALOG := {
	# ---------------------------------------------------------------- intake
	"intake_kandm": ["intake", "K&M COLD AIR INTAKE", 289, 2, { "torque": 1.03, "torque_hi": 1.02 }, "IT GOES WHOOSH. YOUR MOTHER WILL HATE IT."],
	"intake_injenuity": ["intake", "INJEN-UITY SHORT RAM", 349, 2, { "torque": 1.04, "torque_hi": 1.03 }, "SHORT RAM. LONG WARRANTY. MEDIUM GAINS."],
	"intake_sock": ["intake", "OPEN FILTER ON A STICK", 39, 1, { "torque": 1.01 }, "FROM MARKETTHING. THE GUY SAID 'TRUST ME.'"],
	# ---------------------------------------------------------------- exhaust
	"exh_magnaflown": ["exhaust", "MAGNAFLOWN CAT-BACK", 689, 3, { "torque": 1.03, "torque_hi": 1.03 }, "DEEP TONE. CONSTABLE TREMBLAY WILL ALSO ENJOY THE DEEP TONE."],
	"exh_borlah": ["exhaust", "BORLAH ATAK CAT-BACK", 1290, 3, { "torque": 1.04, "torque_hi": 1.05 }, "LOUD ENOUGH TO SET OFF CAR ALARMS IN SALISBURY."],
	"exh_straight": ["exhaust", "STRAIGHT PIPE (TOBY'S COUSIN)", 120, 1, { "torque": 1.05, "torque_lo": 0.95 }, "WELDED IN A DRIVEWAY. FAILS INSPECTION. YOUR INSPECTION."],
	# ---------------------------------------------------------------- headers
	"hdr_jbah": ["headers", "JBAH SHORTY HEADERS", 540, 3, { "torque": 1.03, "torque_hi": 1.04 }, "STAINLESS. SHINY. YOU'LL NEVER SEE THEM AGAIN."],
	"hdr_long": ["headers", "LONG TUBE HEADERS", 980, 4, { "torque": 1.05, "torque_lo": 0.97, "torque_hi": 1.07 }, "TOP END FOR DAYS. THE BOTTOM END IS ON VACATION."],
	# ---------------------------------------------------------------- cams
	"cam_comp": ["cams", "COMP-ROMISE STREET CAMS", 760, 4, { "torque_lo": 0.97, "torque_hi": 1.08, "redline": 300 }, "A LITTLE LUMPY AT IDLE. PEOPLE WILL TURN AROUND."],
	"cam_tomeii": ["cams", "TOMEII PONCAMS STAGE 2", 1390, 5, { "torque_lo": 0.92, "torque_hi": 1.14, "redline": 600 }, "IDLES LIKE IT'S ANGRY AT YOU PERSONALLY."],
	# ---------------------------------------------------------------- ECU
	"ecu_cobbled": ["ecu", "COBBLED ACCESSPORT TUNE", 750, 2, { "torque": 1.06, "redline": 200 }, "PLUG IT INTO THE OBD PORT. FEEL SMARTER THAN YOU ARE."],
	"ecu_apexii": ["ecu", "APEXII POWER FC STANDALONE", 1590, 4, { "torque": 1.09, "redline": 400 }, "A WHOLE NEW BRAIN FOR THE CAR. THE CAR DIDN'T ASK."],
	"ecu_laptop": ["ecu", "TOBY'S COUSIN'S LAPTOP TUNE", 150, 0, { "torque": 1.11, "redline": 500, "wear": 2.5 }, "HE DID IT IN THE TIM'S LOT. THE LAPTOP HAD STICKERS. WHAT COULD GO WRONG."],
	# ---------------------------------------------------------------- forced induction
	"ind_garrette": ["induction", "GARRETTE GT28 TURBO KIT", 3990, 6, { "torque": 1.38, "turbo": { "spool_rpm": 3300, "lag": 0.5, "no_boost": 0.72 } }, "FREE POWER. EXCEPT THE $3,990. AND THE LAG. AND YOUR MARRIAGE."],
	"ind_greddy": ["induction", "GREDDDY T518Z KIT", 5290, 7, { "torque": 1.55, "turbo": { "spool_rpm": 3900, "lag": 0.7, "no_boost": 0.65 } }, "BIGGER TURBO, BIGGER NUMBERS, BIGGER PAUSE BEFORE THE NUMBERS."],
	"ind_single": ["induction", "BIG SINGLE (BIGGER THAN YOUR CAR)", 7990, 9, { "torque": 1.85, "turbo": { "spool_rpm": 4700, "lag": 1.0, "no_boost": 0.55 }, "wear": 1.6 }, "NOTHING, NOTHING, NOTHING, EVERYTHING, A TREE."],
	"ind_whippled": ["induction", "WHIPPLED ROOTS BLOWER", 6490, 8, { "torque": 1.32, "turbo": { "spool_rpm": 1000, "lag": 0.08, "no_boost": 0.86 } }, "INSTANT TORQUE. SOUNDS LIKE A JET HAVING A BAD DAY."],
	"ind_upgrade": ["induction", "BIGGER STOCK-FRAME TURBO", 2290, 5, { "torque": 1.18, "turbo": { "spool_rpm": 3500, "lag": 0.6, "no_boost": 0.68 } }, "LOOKS STOCK. ISN'T. GREAT FOR INSPECTIONS. NOT THAT YOU'D KNOW ANYTHING ABOUT THAT."],
	# ---------------------------------------------------------------- intercooler
	"ic_mishimotoh": ["intercooler", "MISHIMOTOH FRONT MOUNT", 690, 3, { "torque": 1.04, "boost_only": true }, "COLD AIR IS DENSE AIR. LIKE YOUR COUSIN."],
	# ---------------------------------------------------------------- clutch / flywheel / final / diff
	"clutch_s1": ["clutch", "EXEDY-ISH STAGE 1 CLUTCH", 420, 3, { "clutch": 150 }, "HOLDS A LITTLE MORE. YOUR LEFT LEG WON'T NOTICE."],
	"clutch_s3": ["clutch", "ACT-UP STAGE 3 PUCK CLUTCH", 980, 4, { "clutch": 500 }, "ON OR OFF. NOTHING IN BETWEEN. LIKE GUS."],
	"fly_light": ["flywheel", "FIDANZA-ISH LIGHTWEIGHT FLYWHEEL", 460, 3, { "inertia": 0.7 }, "REVS LIKE A SEWING MACHINE. STALLS LIKE A BEGINNER."],
	"final_short": ["final", "SHORT FINAL DRIVE (+10%)", 640, 4, { "final": 1.1 }, "QUICKER OFF THE LINE. 3,500 RPM ON THE HIGHWAY. ENJOY THE DRONE."],
	"final_long": ["final", "TALL FINAL DRIVE (-10%)", 640, 4, { "final": 0.9 }, "MORE TOP SPEED. ALSO MORE WAITING."],
	"lsd_kaaz": ["lsd", "KAAZ-ISH 1.5-WAY LSD", 1450, 5, { "lsd": 0.7 }, "BOTH WHEELS PUSH. FINALLY. A TEAM PLAYER."],
	"lsd_osgiggle": ["lsd", "OS GIGGLE 2-WAY LSD", 2190, 6, { "lsd": 0.85 }, "CLUNKS IN PARKING LOTS. SINGS IN CORNERS."],
	"lsd_welded": ["lsd", "WELDED DIFF (TOBY DID IT)", 90, 0, { "lsd": 1.0, "rear_grip": -0.03 }, "THE POOR MAN'S LSD. THE TIRES ARE THE ONES WHO ARE POOR."],
	# ---------------------------------------------------------------- chassis
	"susp_springs": ["suspension", "EIBACHH LOWERING SPRINGS", 390, 2, { "cg": -0.03, "grip": 1.02, "drop": 0.5 }, "THIRTY MILLIMETRES CLOSER TO THE ROAD AND TO GOD."],
	"susp_coilover": ["suspension", "TEENZ FLEX Z COILOVERS", 1290, 4, { "cg": -0.05, "grip": 1.05, "drop": 0.7 }, "ADJUSTABLE. YOU WON'T ADJUST THEM. NOBODY DOES."],
	"susp_race": ["suspension", "BC RACING-ISH BR COILOVERS", 1690, 5, { "cg": -0.06, "grip": 1.07, "drop": 0.85 }, "STIFF ENOUGH TO READ A COIN. HEADS."],
	"susp_air": ["suspension", "AIR RIDE (SLAMMED)", 3490, 6, { "cg": -0.07, "grip": 0.98, "drop": 1.0 }, "AIRED OUT AT THE TIM'S. DOESN'T CORNER. DOESN'T HAVE TO."],
	"susp_lift": ["suspension", "3-INCH LIFT KIT", 1190, 4, { "cg": 0.08, "grip": 0.96, "drop": -0.8 }, "FOR WHEN YOU NEED TO SEE OVER EVERYONE'S OPINIONS."],
	"sway_rear": ["swaybar", "WHITELINEZ REAR SWAY BAR", 320, 2, { "rear_grip": -0.03, "grip": 1.01 }, "MORE ROTATION. THE BACK END WANTS TO BE THE FRONT END."],
	"sway_front": ["swaybar", "FRONT + REAR SWAY BAR SET", 560, 3, { "grip": 1.03 }, "FLAT THROUGH THE CORNERS. LIKE THE MARITIMES."],
	"wt_gut": ["weight", "GUTTED INTERIOR", 0, 0, { "mass": -85.0 }, "NO SEATS IN THE BACK. NO CARPET. NO FRIENDS IN THE BACK EITHER."],
	"wt_carbon": ["weight", "CARBON HOOD + TRUNK", 1490, 6, { "mass": -24.0, "cg": -0.005 }, "WEAVE PATTERN SO SHINY YOU CAN SEE YOUR DEBT."],
	"wt_full": ["weight", "FULL STRIP (CAGE, LEXAN, NO A/C)", 2290, 5, { "mass": -140.0, "cg": -0.01 }, "IT'S A RACE CAR NOW. IT'S ALSO 31 DEGREES INSIDE IN JULY."],
	"steer_angle": ["steering", "WISEFAB-ISH ANGLE KIT", 1390, 6, { "steer": 0.18 }, "MORE LOCK THAN A CHURCH ON MONDAY."],
	"steer_quick": ["steering", "QUICK RACK", 690, 4, { "steer": 0.05 }, "LESS ARM, MORE CAR."],
	# ---------------------------------------------------------------- brakes
	"pads_hawke": ["pads", "HAWKE HPS PADS", 160, 2, { "brakes": 1.08, "fade": 120.0 }, "DUSTY. GRIPPY. WORTH IT."],
	"pads_race": ["pads", "HAWKE DTC-60 RACE PADS", 340, 3, { "brakes": 1.15, "fade": 260.0 }, "SQUEAL AT EVERY STOP SIGN. STOP AT EVERY STOP SIGN."],
	"brk_brenbo": ["brakes", "BRENBO 4-POT BIG BRAKE KIT", 2890, 7, { "brakes": 1.3, "fade": 180.0, "caliper": "c8242c" }, "RED CALIPERS. ADDS 20 HORSEPOWER (SPIRITUALLY)."],
	"brk_wilwood": ["brakes", "WILLWOOD 6-POT KIT", 3890, 8, { "brakes": 1.45, "fade": 260.0, "caliper": "d8b020" }, "STOPS LIKE IT OWES YOU MONEY."],
	# ---------------------------------------------------------------- tires
	"tire_allseason": ["tires", "TOYODA-ISH ALL-SEASONS", 520, 2, { "compound": "allseason" }, "ALL SEASONS. NONE OF THEM WELL."],
	"tire_winter": ["tires", "BLIZZACK WINTERS", 780, 2, { "compound": "winter" }, "THE LAW SAYS DEC 1. THE ROAD SAYS NOV 2."],
	"tire_sport": ["tires", "FALKIN AZENIS SPORT", 960, 3, { "compound": "sport" }, "STICKY WHEN WARM. TERRIFYING WHEN COLD."],
	"tire_semi": ["tires", "NITTOO NT01 SEMI-SLICKS", 1480, 4, { "compound": "semislick", "grip": 1.03 }, "THE TREAD IS A SUGGESTION. RAIN IS A THREAT."],
	"tire_drag": ["tires", "MICKEY TOMPSON-ISH ET STREETS", 1290, 4, { "compound": "drag" }, "HOOKS LIKE VELCRO STRAIGHT. TURNS LIKE A SHOPPING CART."],
	"tire_at": ["tires", "BFGOODRITCH ALL-TERRAINS", 1190, 3, { "compound": "offroad" }, "FOR THE BACK ROADS. AND THE FRONT LAWNS."],
	# ---------------------------------------------------------------- aero
	"aero_lip": ["aero", "FRONT SPLITTER", 390, 3, { "cl": 0.08, "cda": 0.01, "kit_lip": true }, "SCRAPES ON EVERY DRIVEWAY. WORTH IT. PROBABLY."],
	"aero_ducktail": ["aero", "DUCKTAIL SPOILER", 450, 3, { "cl": 0.1, "cda": 0.01, "spoiler": "ducktail" }, "SUBTLE. SAYS 'I KNOW A GUY.'"],
	"aero_wing": ["aero", "STREET WING", 690, 4, { "cl": 0.2, "cda": 0.03, "spoiler": "wing" }, "SAYS 'I HAVE A GUY.'"],
	"aero_gt": ["aero", "GT WING + SPLITTER", 1890, 6, { "cl": 0.42, "cda": 0.07, "spoiler": "gt", "kit_lip": true }, "SAYS 'I AM THE GUY.' MORE GRIP ABOVE 100 KM/H. MORE LOOKS AT THE TIM'S."],
}

## Parts that only make sense on some cars.
static func fits(id: String, spec: Dictionary) -> bool:
	var p: Array = CATALOG[id]
	var has_turbo: bool = not (spec.engine.get("turbo", {}) as Dictionary).is_empty()
	var body := String(spec.get("body", "sedan"))
	match String(p[0]):
		"intercooler": return has_turbo or String(spec.get("_induction", "")) != ""
		"induction":
			if id == "ind_upgrade": return has_turbo
		"aero":
			if body in ["pickup", "tow", "van", "suv"] and id != "aero_lip": return false
		"tires":
			if id == "tire_at": return true
	if id == "susp_lift": return body in ["pickup", "tow", "suv", "wagon"]
	if id == "susp_air": return not body in ["tow"]
	return true

static func slot(id: String) -> String:
	return String(CATALOG[id][0]) if CATALOG.has(id) else ""

static func name_of(id: String) -> String:
	return String(CATALOG[id][1]) if CATALOG.has(id) else "STOCK"

static func price(id: String) -> int:
	return int(CATALOG[id][2]) if CATALOG.has(id) else 0

static func days(id: String) -> int:
	return int(CATALOG[id][3]) if CATALOG.has(id) else 0

static func blurb(id: String) -> String:
	return String(CATALOG[id][5]) if CATALOG.has(id) else ""

static func effects(id: String) -> Dictionary:
	return CATALOG[id][4] if CATALOG.has(id) else {}

static func in_slot(sl: String) -> Array:
	var out: Array = []
	for id in CATALOG:
		if String(CATALOG[id][0]) == sl: out.append(id)
	return out

## The spec the sim drives, with every installed part applied. Never changes the original.
static func apply(base: Dictionary, installed: Dictionary) -> Dictionary:
	var s: Dictionary = base.duplicate(true)
	var e: Dictionary = s.engine
	var tq := 1.0
	var lo := 1.0
	var hi := 1.0
	var boost_only := 1.0
	var wear := 1.0
	for sl in installed:
		var id := String(installed[sl])
		if not CATALOG.has(id): continue
		var fx: Dictionary = effects(id)
		if fx.has("turbo"):
			s._induction = id
			e.turbo = (fx.turbo as Dictionary).duplicate()
		if fx.get("boost_only", false): boost_only *= float(fx.get("torque", 1.0))
		else: tq *= float(fx.get("torque", 1.0))
		lo *= float(fx.get("torque_lo", 1.0))
		hi *= float(fx.get("torque_hi", 1.0))
		wear *= float(fx.get("wear", 1.0))
		if fx.has("redline"):
			e.redline_rpm = float(e.redline_rpm) + float(fx.redline)
			e.limiter_rpm = float(e.limiter_rpm) + float(fx.redline)
		if fx.has("inertia"): e.inertia = float(e.inertia) * float(fx.inertia)
		if fx.has("clutch"): e.clutch_torque = float(e.clutch_torque) + float(fx.clutch)
		if fx.has("final"): s.gearbox.final = float(s.gearbox.final) * float(fx.final)
		if fx.has("shift"): s.gearbox.shift_time = float(s.gearbox.shift_time) * float(fx.shift)
		if fx.has("mass"): s.mass = float(s.mass) + float(fx.mass)
		if fx.has("cg"): s.cg_height = maxf(0.3, float(s.cg_height) + float(fx.cg))
		if fx.has("rear_grip"): s.rear_grip = float(s.get("rear_grip", 1.07)) + float(fx.rear_grip)
		if fx.has("grip"): s.grip = float(s.get("grip", 1.0)) * float(fx.grip)
		if fx.has("steer"): s.steer_lock = float(s.steer_lock) + float(fx.steer)
		if fx.has("brakes"): s.brakes.max_torque = float(s.brakes.max_torque) * float(fx.brakes)
		if fx.has("fade"): s.brakes.fade_c = float(s.brakes.get("fade_c", 450.0)) + float(fx.fade)
		if fx.has("cda"): s.cda = float(s.cda) + float(fx.cda)
		if fx.has("cl"): s.cl = float(s.get("cl", 0.0)) + float(fx.cl)
		if fx.has("compound"): s.tires.compound = String(fx.compound)
		if fx.has("lsd"): s.lsd = float(fx.lsd)
	if not (e.get("turbo", {}) as Dictionary).is_empty(): tq *= boost_only
	# reshape the torque curve: low end below half the redline, top end above 60% of it
	var red := float(e.redline_rpm)
	var curve: Array = []
	for pt in e.torque_curve:
		var rpm := float(pt[0])
		var k := tq
		k *= lerpf(lo, 1.0, clampf(rpm / (red * 0.5), 0.0, 1.0))
		k *= lerpf(1.0, hi, clampf((rpm - red * 0.6) / (red * 0.4), 0.0, 1.0))
		curve.append([rpm, float(pt[1]) * k])
	# a higher redline needs the curve to keep going up there
	var last: Array = curve[curve.size() - 1]
	if float(e.limiter_rpm) > float(last[0]):
		curve.append([float(e.limiter_rpm), float(last[1]) * 0.9])
	e.torque_curve = curve
	s.engine_wear = wear
	return s

## Peak power (hp) and torque (N·m) from a spec's curve (at full boost).
static func peaks(spec: Dictionary) -> Vector2:
	var best_hp := 0.0
	var best_tq := 0.0
	for pt in spec.engine.torque_curve:
		var rpm := float(pt[0])
		var tqv := float(pt[1])
		best_tq = maxf(best_tq, tqv)
		best_hp = maxf(best_hp, tqv * rpm / 7120.9)      # N·m × rpm → hp
	return Vector2(best_hp, best_tq)
