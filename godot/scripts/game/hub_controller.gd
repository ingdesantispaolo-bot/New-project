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
	# La stanza è quella della materia che abita il mondo corrente; la prontezza è
	# quella dell'APPARATO (padronanza di quella materia), non del livello.
	var subject := ApparatusConfig.world_subject(save.level())
	var apparatus := ApparatusConfig.apparatus_of(subject)
	var repaired_level := int(save.data.get("apparatus", {}).get(apparatus, {}).get("repairedLevel", 0))
	# All'ultimo mondo la prova è il CUORE, che si apre con le dodici stanze accese.
	var is_heart := save.level() >= ApparatusConfig.MAX_LEVEL
	var ready := (
		progression.can_open_heart() if is_heart
		else progression.can_repair_apparatus(subject))
	return {
		"level": save.level(),
		"apparatus": apparatus,
		"subject": subject,
		"ready": ready,
		"complete": progression.is_complete(),
		"repairedLevel": repaired_level,
		"isHeart": is_heart,
		"apparatusRepaired": progression.repaired_apparatus_count(),
		"apparatusTotal": ApparatusConfig.SUBJECT_CYCLE.size(),
		"missingApparatus": progression.missing_apparatus_subjects(),
	}

func request_exam() -> bool:
	if save.level() >= ApparatusConfig.MAX_LEVEL:
		if not progression.can_open_heart():
			return false
	elif not progression.can_repair_apparatus(ApparatusConfig.world_subject(save.level())):
		return false
	exam_requested.emit()
	return true

func refresh() -> void:
	_emit_state()

func _emit_state() -> void:
	state_changed.emit(state())
