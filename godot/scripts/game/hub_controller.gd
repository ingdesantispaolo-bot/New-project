class_name HubController
extends Node

## Controller minimale della nave: espone stato leggibile alle stanze/UI.
## La riparazione effettiva resta in ProgressionManager dopo final_exam.

signal state_changed(state: Dictionary)
signal exam_requested

var save: GameSaveManager
var progression: ProgressionManager

func setup(save_manager: GameSaveManager) -> void:
	save = save_manager
	# ContentManager alla progressione: la readiness del gate della nave usa la
	# dimensione COPERTURA con lo stesso metro del mondo esterno (coerenza gate).
	progression = ProgressionManager.new(save, ContentManager.new())
	_emit_state()

func state() -> Dictionary:
	if not is_instance_valid(save):
		return {}
	var gate := progression.current_gate()
	var apparatus := str(gate.get("apparatus", "nucleo"))
	var repaired_level := int(save.data.get("apparatus", {}).get(apparatus, {}).get("repairedLevel", 0))
	return {"level": save.level(), "apparatus": apparatus, "subject": str(gate.get("subject", "matematica")), "ready": progression.can_repair(), "complete": progression.is_complete(), "repairedLevel": repaired_level}

func request_exam() -> bool:
	if not progression.can_repair():
		return false
	exam_requested.emit()
	return true

func refresh() -> void:
	_emit_state()

func _emit_state() -> void:
	state_changed.emit(state())
