class_name ShipActivationModel
extends RefCounted

## Deriva la riattivazione visiva della nave esclusivamente dalla progressione
## didattica persistita. Nessuna valuta o acquisto cosmetico concede potenza.

const STAGES := [
	{"id": "offline", "title": "SISTEMA INERTE", "short": "○", "minimum": 0.0},
	{"id": "ignition", "title": "RIACCENSIONE", "short": "◔", "minimum": 0.001},
	{"id": "routing", "title": "RETE PARZIALE", "short": "◑", "minimum": 0.20},
	{"id": "synchronized", "title": "SINCRONIZZATO", "short": "◕", "minimum": 0.50},
	{"id": "full_power", "title": "PIENA POTENZA", "short": "●", "minimum": 0.999},
]

static func gates_for_room(room_id: String) -> Array:
	var gates: Array = []
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var gate := ApparatusConfig.level_gate(level)
		if ShipRoomCatalog.room_for_apparatus(str(gate.get("apparatus", ""))) == room_id:
			gates.append(gate)
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
		var subject := str(current_gate.get("subject", "matematica"))
		# Progresso VERSO il gate corrente (non il cumulativo): a un ciclo successivo
		# il nodo non deve apparire già pieno per il lavoro del ciclo precedente.
		var mission_ratio := clampf(float(save.missions_toward_gate(subject)) / float(maxi(1, int(current_gate.get("missionsRequired", 1)))), 0.0, 1.0)
		var mastery_ratio := clampf(save.mastery_of(subject) / maxf(0.001, float(current_gate.get("masteryThreshold", 0.7))), 0.0, 1.0)
		# Il gate pronto arriva all'85% della propria tacca: l'ultimo impulso viene
		# concesso soltanto dall'esame superato.
		partial = minf(mission_ratio, mastery_ratio) * 0.85

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
			cells.append("◆")
		elif index == completed and partial > 0.001:
			cells.append("◇")
		else:
			cells.append("·")
	return " ".join(cells)
