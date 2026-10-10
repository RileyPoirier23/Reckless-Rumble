## The prologue demo: a build with the "demo" feature tag (the DEMO export presets) plays day one
## (the drunk drive, the meet, the first shift at the counter, the evening's drives) and stops at
## the CHAPTER 1 card with a thank-you, then the credits and the memorial. The title only offers
## the prologue, the settings, the credits and quit.
## --prologue-build on the command line does the same in the editor or a test.
class_name DemoBuild
extends RefCounted

const END_CARD := { "type": "card", "title": "THANKS FOR PLAYING", "sub": "THE DRIVEBOSS PROLOGUE",
	"small": "THAT'S DAY ONE. CHAPTER 1 AND THE REST OF PORT RUMBLE ARE IN THE FULL GAME. FROM THE MAKER OF CAGE BOSS.",
	"demo_end": true }

static var forced := false          # tests

static func on() -> bool:
	return forced or OS.has_feature("demo") or OS.get_cmdline_user_args().has("--prologue-build")

## The step the demo stops at: the card that ends day one.
static func end_step() -> int:
	for k in StoryScript.STEPS.size():
		if bool(StoryScript.STEPS[k].get("day_ends", false)): return k
	return StoryScript.STEPS.size()

## Where the saved story is, without loading it (-1: no save).
static func saved_step() -> int:
	if not StoryState.has_save(): return -1
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(StoryState.PATH))
	return int((d as Dictionary).get("step", 0)) if d is Dictionary else -1
