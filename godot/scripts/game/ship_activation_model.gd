class_name ShipActivationModel
extends RefCounted

## Deriva la riattivazione visiva della nave esclusivamente dalla progressione
## didattica persistita. Nessuna valuta o acquisto cosmetico concede potenza.

const STAGES := [
	{"id": "offline", "title": "SISTEMA INERTE", "short": "o", "minimum": 0.0},
	{"id": "ignition", "title": "RIACCENSIONE", "short": "o", "minimum": 0.001},
	{"id": "routing", "title": "RETE PARZIALE", "short": "o", "minimum": 0.20},
	{"id": "synchronized", "title": "SINCRONIZZATO", "short": "o", "minimum": 0.50},
	{"id": "full_power", "title": "PIENA POTENZA", "short": "•", "minimum": 0.999},
]

## I nodi di una stanza: un nodo per ogni livello la cui materia ospite appartiene
## a quella stanza. Usa `world_subject()` e non il gate del livello — dal 30 luglio
## il gate è il nucleo per tutti i livelli, quindi ricavarne la stanza darebbe
## sempre le stesse tre.
static func gates_for_room(room_id: String) -> Array:
	var gates: Array = []
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var subject := ApparatusConfig.world_subject(level)
		var apparatus := ApparatusConfig.apparatus_of(subject)
		if ShipRoomCatalog.room_for_apparatus(apparatus) == room_id:
			gates.append({
				"level": level,
				"subject": subject,
				"apparatus": apparatus,
				"masteryThreshold": ApparatusConfig.mastery_threshold(level),
			})
	return gates

static func activation_for_room(save, room_id: String) -> Dictionary:
	var gates := gates_for_room(room_id)
	var completed := 0
	for gate in gates:
		var apparatus := str(gate.get("apparatus", ""))
		var repaired_level := int(save.data.get("apparatus", {}).get(apparatus, {}).get("repairedLevel", 0))
		if repaired_level >= int(gate.get("level", 0)):
			completed += 1

	var partial := 0.0
	var current_gate := ApparatusConfig.level_gate(save.level())
	if save.level() <= ApparatusConfig.MAX_LEVEL \
	and ShipRoomCatalog.room_for_apparatus(str(current_gate.get("apparatus", ""))) == room_id:
		var subject := ApparatusConfig.world_subject(save.level())
		# Il conteggio missioni non fa più parte del gate: l'avanzamento della tacca
		# è la sola padronanza della materia della stanza.
		var mastery_ratio := clampf(
			save.mastery_of(subject) / maxf(0.001, float(current_gate.get("masteryThreshold", 0.7))),
			0.0, 1.0)
		# Il gate pronto arriva all'85% della propria tacca: l'ultimo impulso viene
		# concesso soltanto dall'esame superato.
		partial = mastery_ratio * 0.85

	var total := gates.size()
	var ratio := clampf((float(completed) + partial) / float(maxi(1, total)), 0.0, 1.0)
	var stage_index := _stage_index(ratio, completed, total)
	var stage: Dictionary = STAGES[stage_index]
	return {
		"roomId": room_id,
		"ratio": ratio,
		"percent": int(round(ratio * 100.0)),
		"completed": completed,
		"total": total,
		"partial": partial,
		"stage": stage_index,
		"stageId": str(stage["id"]),
		"title": str(stage["title"]),
		"short": str(stage["short"]),
		"segments": _segments(completed, total, partial),
	}

static func _stage_index(ratio: float, completed: int, total: int) -> int:
	if total > 0 and completed >= total:
		return 4
	if ratio <= 0.0001:
		return 0
	if ratio < 0.20:
		return 1
	if ratio < 0.50:
		return 2
	return 3

static func _segments(completed: int, total: int, partial: float) -> String:
	var cells := PackedStringArray()
	for index in total:
		if index < completed:
			cells.append("◊")
		elif index == completed and partial > 0.001:
			cells.append("◊")
		else:
			cells.append("·")
	return " ".join(cells)
