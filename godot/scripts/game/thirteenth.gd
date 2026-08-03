class_name ThirteenthDirector
extends RefCounted

## Regia effimera del Tredicesimo. I testi restano nel catalogo: questo oggetto
## decide soltanto quando una manifestazione puo' avvenire e applica i due
## guard-rail di percorso/memoria prima che la scena li possa vedere.

const CATALOG := preload("res://scripts/game/thirteenth_catalog.gd")

var world := 0
var seed := ""
var forgotten_residents: Array = []
var active_owner := ""
var _voice_cursor := 0

func setup(
	world_level: int,
	campaign_seed: String,
	previously_forgotten: Array = [],
	mission_owner: String = ""
) -> void:
	world = world_level
	seed = campaign_seed
	forgotten_residents = previously_forgotten.duplicate()
	active_owner = mission_owner
	_voice_cursor = 0

func is_present() -> bool:
	return world >= CATALOG.PRIMO_MONDO_AZIONE

## Ogni visita mostra al massimo un gesto ambientale, oltre alla voce. La
## sequenza e' stabile per mondo: i render e le visite ripetute non cambiano a
## seconda del frame in cui la scena e' stata caricata.
func ambient_action() -> String:
	if not is_present():
		return ""
	var schedule := ["scrive", "risbiadisce", "smemora", "chiude"]
	return schedule[posmod(world - CATALOG.PRIMO_MONDO_AZIONE, schedule.size())]

func action_data(action_id: String) -> Dictionary:
	if not CATALOG.actions_at(world).has(action_id):
		return {}
	return CATALOG.action(action_id)

## Restituisce un residente eleggibile e lo consuma. Il proprietario della
## missione aperta e chi e' gia' stato smemorato non entrano mai nel sorteggio.
func choose_forgotten_resident(resident_ids: Array) -> String:
	if action_data("smemora").is_empty():
		return ""
	var eligible: Array = []
	for raw_id in resident_ids:
		var npc_id := str(raw_id)
		if npc_id == "" or npc_id == active_owner or forgotten_residents.has(npc_id):
			continue
		eligible.append(npc_id)
	eligible.sort()
	if eligible.is_empty():
		return ""
	var index := posmod(hash("%s:%d:smemora" % [seed, world]), eligible.size())
	var selected := str(eligible[index])
	forgotten_residents.append(selected)
	return selected

## Una rotta e' chiudibile solo se non porta alla sala apparati corrente e ne
## resta almeno un'altra aperta. Senza una vera alternativa non viene simulata
## alcuna chiusura: il mondo aperto, che ha un solo portale, passa [] qui.
func choose_closed_route(routes: Array, current_apparatus_room: String) -> String:
	if action_data("chiude").is_empty():
		return ""
	var eligible: Array = []
	var open_count := 0
	for raw_route in routes:
		var route: Dictionary = raw_route
		if not bool(route.get("open", true)):
			continue
		open_count += 1
		var route_id := str(route.get("id", ""))
		if route_id != "" and route_id != current_apparatus_room and not bool(route.get("onlyPath", false)):
			eligible.append(route_id)
	if open_count < 2 or eligible.is_empty():
		return ""
	eligible.sort()
	return str(eligible[posmod(hash("%s:%d:chiude" % [seed, world]), eligible.size())])

## Una battuta per visita, non un dialogo modale. Il chiamante puo' mostrarne le
## schermate come didascalia e lasciare Eli in movimento.
func next_voice() -> Dictionary:
	var lines := CATALOG.lines_for(world)
	if lines.is_empty():
		return {}
	var entry: Dictionary = lines[_voice_cursor % lines.size()]
	_voice_cursor += 1
	return entry.duplicate(true)

func debug_state() -> Dictionary:
	return {
		"world": world,
		"present": is_present(),
		"ambientAction": ambient_action(),
		"activeOwner": active_owner,
		"forgottenResidents": forgotten_residents.duplicate(),
	}
