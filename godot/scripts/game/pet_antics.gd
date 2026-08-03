class_name PetAntics
extends Node

signal antic_started(antic_id: String, duration: float)
signal antic_finished(antic_id: String)

const MIN_INTERVAL_SEC := 90.0
const CATALOG := {
	"tail": {"label": "Insegue la propria coda", "duration": 3.0},
	"pose": {"label": "Imita la posa di Eli e la sbaglia", "duration": 2.8},
	"nap": {"label": "Si addormenta in piedi e finge di essere sveglio", "duration": 3.2},
	"guard": {"label": "Fa la guardia a un sasso", "duration": 3.4},
}

var _unlocked: Array = []
var _elapsed := 0.0
var _remaining := 0.0
var _active := ""
var _cursor := 0
var _blocked := false
var _reduced_motion := false

func configure(unlocked: Array, reduced_motion: bool) -> void:
	_unlocked.clear()
	for antic_id in unlocked:
		if CATALOG.has(str(antic_id)) and not _unlocked.has(str(antic_id)):
			_unlocked.append(str(antic_id))
	_reduced_motion = reduced_motion
	set_process(not _unlocked.is_empty())

func set_blocked(value: bool) -> void:
	_blocked = value
	if _blocked and _active != "":
		var interrupted := _active
		_active = ""
		_remaining = 0.0
		antic_finished.emit(interrupted)

func is_reduced_motion() -> bool:
	return _reduced_motion

func active_antic() -> String:
	return _active

func _process(delta: float) -> void:
	if _active != "":
		_remaining -= delta
		if _remaining <= 0.0:
			var finished := _active
			_active = ""
			antic_finished.emit(finished)
		return
	if _blocked:
		return
	_elapsed += delta
	if _elapsed >= MIN_INTERVAL_SEC:
		try_start("world")

func try_start(context: String, authorized_sneeze := false) -> String:
	if _active != "" or _unlocked.is_empty():
		return ""
	if context in ["exercise", "exam", "beat"] and not authorized_sneeze:
		return ""
	var antic_id := str(_unlocked[_cursor % _unlocked.size()])
	if context in ["exercise", "exam", "beat"] and antic_id != "sneeze":
		return ""
	_cursor += 1
	_elapsed = 0.0
	_active = antic_id
	_remaining = float(Dictionary(CATALOG[antic_id]).get("duration", 2.5))
	antic_started.emit(_active, _remaining)
	return _active
