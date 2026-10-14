## A stopwatch for the frame: where the time goes, by section, when a probe asks (`on`).
## Prof.lap("name", t0) adds the microseconds since t0 to that section and returns now.
class_name Prof

static var on := false
static var acc := {}
static var calls := {}

static func lap(name: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	if on:
		acc[name] = int(acc.get(name, 0)) + (now - t0)
		calls[name] = int(calls.get(name, 0)) + 1
	return now

static func reset() -> void:
	acc = {}
	calls = {}

## "name 12.3ms (4 calls)" per section, biggest first, averaged over `frames`.
static func report(frames: int) -> String:
	var keys := acc.keys()
	keys.sort_custom(func(a, b): return acc[a] > acc[b])
	var out: Array = []
	for k in keys:
		out.append("%s %.2fms/%d" % [k, acc[k] / 1000.0 / maxf(1.0, frames), int(calls[k] / maxf(1.0, frames))])
	return ", ".join(out)
