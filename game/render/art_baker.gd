## Painting a tree or a bush pixel by pixel takes milliseconds, and driving fast brings a new
## size or variant into view every few frames: done on the main thread, that's the stutter. So
## out on the road the painting happens on a background thread (a Painter the drive scene owns).
## Until a sprite's ready, whatever's closest that's already painted (same kind, same season,
## nearest size) stands in, and when the real one lands the layers that used a stand-in are
## redrawn. At the start, right after a teleport, and anywhere there's no Painter (tests, sheets,
## cutscenes), it paints straight away.
class_name ArtBaker
extends RefCounted

static var painter: Painter           # the drive scene's background painter (null: paint straight away)
static var sync_until := -1           # paint straight away up to this process frame (the start, a teleport)
static var stood_in := false          # a draw used a stand-in since this was last cleared
static var landed_n := 0              # bumps whenever painted sprites land (time to redraw stand-ins)
static var _pending := {}
static var _caches := {}              # owner -> { key: texture }
static var _looks := {}               # "owner|look" -> { r: texture }: what a stand-in can be

## The texture for `key` (painted by `paint`, which returns an Image), or the nearest stand-in
## while it's painted, or null if there's nothing to stand in yet.
static func get_tex(owner: String, key: String, look: String, r: int, paint: Callable) -> ImageTexture:
	var cache: Dictionary = _caches.get_or_add(owner, {})
	if cache.has(key): return cache[key]
	if painter == null or Engine.get_process_frames() <= sync_until:
		return _store(owner, key, look, r, paint.call())
	_queue(owner, key, look, r, paint, true)
	stood_in = true
	return _stand_in(owner, look, r)

## Queue a sprite to be painted in the background without drawing it (warming the cache).
static func want(owner: String, key: String, look: String, r: int, paint: Callable) -> void:
	if painter == null or (_caches.get_or_add(owner, {}) as Dictionary).has(key): return
	_queue(owner, key, look, r, paint, false)

static func _queue(owner: String, key: String, look: String, r: int, paint: Callable, urgent: bool) -> void:
	var pk := owner + "#" + key
	if _pending.has(pk):
		if urgent and not bool(_pending[pk]):
			_pending[pk] = true
			painter.add([owner, key, look, r, paint], true)        # wanted on screen now: to the front
		return
	_pending[pk] = urgent
	painter.add([owner, key, look, r, paint], urgent)

## On the main thread: the Painter hands back what it painted. True when anything new landed.
static func landed(batch: Array) -> bool:
	for d in batch:
		var pk := String(d[0]) + "#" + String(d[1])
		if not _pending.has(pk): continue
		_store(String(d[0]), String(d[1]), String(d[2]), int(d[3]), d[4])
		_pending.erase(pk)
	if not batch.is_empty(): landed_n += 1
	return not batch.is_empty()

static func busy() -> bool:
	return not _pending.is_empty()

static func _store(owner: String, key: String, look: String, r: int, img: Image) -> ImageTexture:
	var cache: Dictionary = _caches.get_or_add(owner, {})
	if cache.has(key): return cache[key]
	var t := ImageTexture.create_from_image(img)
	cache[key] = t
	(_looks.get_or_add(owner + "|" + look, {}) as Dictionary)[r] = t
	return t

static func _stand_in(owner: String, look: String, r: int) -> ImageTexture:
	var byr: Dictionary = _looks.get(owner + "|" + look, {})
	var best: ImageTexture = null
	var bd := 1 << 30
	for rr: int in byr:
		if absi(rr - r) < bd:
			bd = absi(rr - r)
			best = byr[rr]
	return best


## One background thread painting sprites off a queue (what's wanted on screen first, warming
## second), handing them back to the main thread a few a frame. It stops with its scene.
class Painter extends Node:
	signal art_landed
	var _thread := Thread.new()
	var _mutex := Mutex.new()
	var _sem := Semaphore.new()
	var _urgent: Array = []
	var _warm: Array = []
	var _out: Array = []
	var _quit := false

	func _ready() -> void:
		_thread.start(_run)

	## Any other slow, read-only work (a chunk's ground survey): `fn` runs here, `done` gets its
	## result back on the main thread.
	func work(fn: Callable, done: Callable) -> void:
		add(["work", fn, done], true)

	func add(job: Array, urgent: bool) -> void:
		_mutex.lock()
		if urgent: _urgent.append(job)
		else: _warm.append(job)
		_mutex.unlock()
		_sem.post()

	func _run() -> void:
		while true:
			_sem.wait()
			_mutex.lock()
			if _quit:
				_mutex.unlock()
				return
			var job: Array = _urgent.pop_back() if not _urgent.is_empty() else (_warm.pop_front() if not _warm.is_empty() else [])
			_mutex.unlock()
			if job.is_empty(): continue
			var res: Array
			if String(job[0]) == "work": res = ["work", job[2], (job[1] as Callable).call()]
			else: res = [job[0], job[1], job[2], job[3], (job[4] as Callable).call()]
			_mutex.lock()
			_out.append(res)
			_mutex.unlock()

	func _process(_dt: float) -> void:
		var _t0 := Time.get_ticks_usec()
		_process_timed(_dt)
		Prof.lap('art_baker', _t0)

	func _process_timed(_dt: float) -> void:
		if _out.is_empty(): return
		_mutex.lock()
		var batch := _out.slice(0, 8)           # a few a frame: making textures isn't free either
		_out = _out.slice(8)
		_mutex.unlock()
		var art: Array = []
		for d in batch:
			if String(d[0]) == "work":
				if (d[1] as Callable).is_valid(): (d[1] as Callable).call(d[2])
			else: art.append(d)
		if ArtBaker.landed(art): art_landed.emit()

	func _exit_tree() -> void:
		_mutex.lock()
		_quit = true
		_mutex.unlock()
		_sem.post()
		_thread.wait_to_finish()
		if ArtBaker.painter == self: ArtBaker.painter = null
		ArtBaker._pending.clear()
