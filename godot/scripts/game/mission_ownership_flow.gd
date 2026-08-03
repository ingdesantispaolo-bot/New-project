class_name MissionOwnershipFlow
extends RefCounted

## Stato effimero del flusso A2. Non scrive save, mastery, energia o gate: decide
## soltanto quale volto precede e segue una sessione già gestita dal gameplay.

const NPCS := preload("res://scripts/game/npc_catalog.gd")

var world := 0
var _events: Array = []
var _completed: Array = []
var _requested: Dictionary = {}
var _active_event := ""
var _pending_return: Dictionary = {}

func setup(world_level: int, events: Array, completed_ids: Array) -> void:
	world = world_level
	_events = events.duplicate(true)
	_completed = completed_ids.duplicate()
	_requested.clear()
	_active_event = ""
	_pending_return.clear()

func owner_of(event_id: String) -> String:
	var event := event_data(event_id)
	return NPCS.owner_for(world, str(event.get("kind", ""))) if not event.is_empty() else ""

func event_data(event_id: String) -> Dictionary:
	for raw_event in _events:
		var event: Dictionary = raw_event
		if str(event.get("id", "")) == event_id:
			return event.duplicate(true)
	return {}

func requires_request(event_id: String) -> bool:
	return owner_of(event_id) != "" and not bool(_requested.get(event_id, false))

func can_start(event_id: String) -> bool:
	return not requires_request(event_id)

func assignment_for(npc_id: String) -> Dictionary:
	if not _pending_return.is_empty():
		return {}
	if _active_event != "":
		return {}
	# Dopo un fallimento l'incarico resta richiesto e riprovabile: parlare di
	# nuovo col proprietario non deve aprirne un secondo in parallelo.
	for raw_event in _events:
		var outstanding: Dictionary = raw_event
		var outstanding_id := str(outstanding.get("id", ""))
		if bool(_requested.get(outstanding_id, false)) and not _completed.has(outstanding_id):
			return {}
	for raw_event in _events:
		var event: Dictionary = raw_event
		var event_id := str(event.get("id", ""))
		if event_id == "" or _completed.has(event_id):
			continue
		if owner_of(event_id) == npc_id and not bool(_requested.get(event_id, false)):
			return event.duplicate(true)
	return {}

func accept_request(npc_id: String) -> Dictionary:
	var event := assignment_for(npc_id)
	if event.is_empty():
		return {}
	var event_id := str(event.get("id", ""))
	_requested[event_id] = true
	_active_event = event_id
	return event

func record_result(event_id: String, passed: bool) -> Dictionary:
	var owner := owner_of(event_id)
	if owner == "" or not bool(_requested.get(event_id, false)):
		return {}
	_pending_return = {"eventId": event_id, "ownerNpc": owner, "passed": passed}
	if passed and not _completed.has(event_id):
		_completed.append(event_id)
	return _pending_return.duplicate(true)

func pending_return_for(npc_id: String) -> Dictionary:
	if str(_pending_return.get("ownerNpc", "")) != npc_id:
		return {}
	return _pending_return.duplicate(true)

func consume_return(npc_id: String) -> Dictionary:
	var result := pending_return_for(npc_id)
	if result.is_empty():
		return {}
	_pending_return.clear()
	_active_event = ""
	return result

func navigation() -> Dictionary:
	if not _pending_return.is_empty():
		return {"kind": "npc", "id": str(_pending_return.get("ownerNpc", "")), "phase": "return"}
	if _active_event != "":
		return {"kind": "event", "id": _active_event, "phase": "mission"}
	for raw_event in _events:
		var requested_event: Dictionary = raw_event
		var requested_id := str(requested_event.get("id", ""))
		if bool(_requested.get(requested_id, false)) and not _completed.has(requested_id):
			return {"kind": "event", "id": requested_id, "phase": "mission"}
	# La rotta principale presenta prima la missione dello specialista; l'enigma
	# del testimone resta disponibile e conserva il proprio proprietario.
	for preferred_kind in ["mission", "enigma"]:
		for raw_event in _events:
			var event: Dictionary = raw_event
			if str(event.get("kind", "")) != preferred_kind:
				continue
			var event_id := str(event.get("id", ""))
			if event_id == "" or _completed.has(event_id) or bool(_requested.get(event_id, false)):
				continue
			var owner := owner_of(event_id)
			if owner != "":
				return {"kind": "npc", "id": owner, "phase": "request", "eventId": event_id}
	return {}
