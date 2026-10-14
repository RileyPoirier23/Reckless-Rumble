## The garage's side-view previews, drawn ahead of time. Painting one is a good part of a
## second, and the garage used to draw the car you'd just picked while you waited: now every
## car in the lot is painted in the background (the ones round your pick first) the moment the
## game loads or the garage opens, kept for the session, and written to user://previews so the
## next session has them at once. One painter at a time, so the game keeps its frames.
class_name PreviewBake
extends Node

static var me: PreviewBake
const DIR := "user://previews"
const LEN := 250                      # the preview's length in px for a car under 5.5 m
const LEN_LONG := 270

var _cache := {}                      # key -> ImageTexture
var _queue: Array = []                # [key, spec, len, paint, looks, dmg], front first
var _queued := {}
var _task := -1
var _job: Array = []
var _img: Image

func _ready() -> void:
	me = self
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))

func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if me == self: me = null

## The key a car's preview is filed under: the car, its paint, its looks and its dents.
static func key_of(entry: Dictionary, paint: String, looks: Dictionary) -> String:
	return "%s|%s|%s|%s" % [entry.id, paint, JSON.stringify(looks), JSON.stringify(entry.get("damage", {}))]

static func len_for(spec: Dictionary) -> int:
	return LEN if float(spec.get("length", 4.6)) < 5.5 else LEN_LONG

## The preview, if it's drawn (in memory or on disk); null while it's still to come.
func get_tex(key: String) -> ImageTexture:
	if _cache.has(key): return _cache[key]
	var path := _path(key)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null:
			var t := ImageTexture.create_from_image(img)
			_cache[key] = t
			return t
	return null

## Ask for one (to the front: it's wanted now).
func want(key: String, spec: Dictionary, paint: Color, looks: Dictionary, dmg: Dictionary, urgent := false) -> void:
	if _cache.has(key) or _queued.has(key):
		if urgent and _queued.has(key):
			for i in _queue.size():
				if String(_queue[i][0]) == key:
					var j: Array = _queue[i]
					_queue.remove_at(i)
					_queue.push_front(j)
					break
		return
	if FileAccess.file_exists(_path(key)): return
	_queued[key] = true
	var job := [key, spec, len_for(spec), paint, looks, dmg]
	if urgent: _queue.push_front(job)
	else: _queue.append(job)

## Everything in a lot, nearest the pick first.
func prime(garage: Array, order: Array, pick_pos: int) -> void:
	var n := order.size()
	for k in n:
		# out from the pick: +1, -1, +2, -2 ...
		var step := (k + 1) / 2 if k % 2 == 1 else -((k + 1) / 2)
		var pos := pick_pos + step
		if pos < 0 or pos >= n: continue
		var i: int = order[pos]
		var entry: Dictionary = garage[i]
		var spec := SaveGame.load_spec(String(entry.id))
		if spec.is_empty(): continue
		var looks := SaveGame.car_looks(entry)
		looks.year = int(spec.get("year", 2000))
		var paint := String(entry.paint)
		var key := key_of(entry, paint, looks)
		if _cache.has(key) or _queued.has(key): continue
		var dmg := damage_mods(entry)
		if dmg.is_empty() and _authored(spec, looks, paint, key): continue
		want(key, spec, Color(paint), looks, dmg)

## The dents the painter draws: only the big ones.
static func damage_mods(entry: Dictionary) -> Dictionary:
	var dmg := {}
	var d: Dictionary = entry.get("damage", {})
	if float(d.get("front", 0.0)) > 0.3: dmg.front = float(d.front) * 0.6
	if float(d.get("rear", 0.0)) > 0.3: dmg.rear = float(d.rear) * 0.6
	return dmg

## A stock car with an authored sprite: that's the preview, no painting.
func _authored(spec: Dictionary, looks: Dictionary, paint: String, key: String) -> bool:
	for mk in looks:
		if not mk in PixCars.COSMETIC_KEYS: return false
	var img := PixCars.authored(PixCars.art_id(spec), Color(paint))
	if img == null: return false
	_cache[key] = ImageTexture.create_from_image(img)
	return true

func busy() -> bool:
	return _task >= 0 or not _queue.is_empty()

func _process(_dt: float) -> void:
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task): return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		var key := String(_job[0])
		_queued.erase(key)
		if _img != null:
			_cache[key] = ImageTexture.create_from_image(_img)
			_img.save_png(_path(key))
		_img = null
		_job = []
	if _queue.is_empty(): return
	_job = _queue.pop_front()
	var spec: Dictionary = _job[1]
	var len: int = _job[2]
	var paint: Color = _job[3]
	var looks: Dictionary = _job[4]
	var dmg: Dictionary = _job[5]
	_task = WorkerThreadPool.add_task(func() -> void: _img = PixCars.image_of(spec, len, paint, looks, dmg), false, "garage preview")

static func _path(key: String) -> String:
	return "%s/%s.png" % [DIR, key.md5_text()]
