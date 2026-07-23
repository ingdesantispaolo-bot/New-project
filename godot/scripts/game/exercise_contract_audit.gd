extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Gate Opus P3 (O-P3): il contenuto di OGNI formato consegnato rispetta il
## contratto comune ExerciseInteraction (nessuna ambiguità, soluzione unica,
## niente duplicati, spiegazione causale), gli esami finali sono multi-formato con
## prova di trasferimento (mai solo scelta multipla) e la scelta multipla non è
## dominante nelle missioni a formati vari.
## Uso: godot --headless --path godot --script res://scripts/game/exercise_contract_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var minigame := MinigameManager.new()
	var subjects: Array = ApparatusConfig.SUBJECT_CYCLE
	var validated := 0

	# 1) Tutti gli item dei banchi statici (12 materie) rispettano il contratto.
	for subject in subjects:
		for item in content._load_bank(str(subject)):
			var res := ExerciseInteraction.validate(item)
			assert(bool(res["ok"]), "banco %s · %s: %s" % [subject, str(item.get("id", "?")), str(res["errors"])])
			validated += 1

	# 2) La matematica GENERATA rispetta il contratto a più livelli.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for level in [1, 4, 7, 10, 13, 20]:
		for _i in range(6):
			var mission := content.build_mission("matematica", level, 3, {}, rng)
			var vs := ExerciseInteraction.validate_session(mission)
			assert(bool(vs["ok"]), "matematica generata L%d: %s" % [level, str(vs["errors"])])
			validated += int(mission.get("nodes", []).size())

	# 3) I minigiochi (abbina/ordina) di ogni materia rispettano il contratto.
	for subject in subjects:
		var mg := minigame.build_minigame(str(subject), 5, rng)
		var vmg := ExerciseInteraction.validate_session(mg)
		assert(bool(vmg["ok"]), "minigioco %s: %s" % [subject, str(vmg["errors"])])
		validated += int(mg.get("nodes", []).size())

	# 4) Enigmi ambientali: stesso contratto delle missioni.
	for subject in subjects:
		var enigma := content.build_enigma(str(subject), 3, 4, {}, rng)
		var ve := ExerciseInteraction.validate_session(enigma)
		assert(bool(ve["ok"]), "enigma %s: %s" % [subject, str(ve["errors"])])

	# 5) Esami finali: multi-formato + nodo di trasferimento, MAI solo scelta multipla.
	for subject in subjects:
		var exam := content.build_final_exam(str(subject), 6, 3, rng)
		var nodes: Array = exam.get("nodes", [])
		var vex := ExerciseInteraction.validate_session(exam)
		assert(bool(vex["ok"]), "esame %s: %s" % [subject, str(vex["errors"])])
		var formats := ExerciseInteraction.distinct_formats(nodes)
		assert(formats.size() >= 2, "esame %s: servono ≥2 formati, trovati %s" % [subject, str(formats)])
		assert(ExerciseInteraction.multiple_choice_ratio(nodes) < 1.0, "esame %s: non può essere solo scelta multipla" % subject)
		var has_transfer := false
		for n in nodes:
			if bool(n.get("transfer", false)):
				has_transfer = true
		assert(has_transfer, "esame %s: manca una prova di trasferimento" % subject)

	# 6) Missioni a formati vari: la scelta multipla non è dominante (≤ 1/3).
	for subject in subjects:
		var varied := content.build_varied_mission(str(subject), 4, 3, {}, rng)
		var vv := ExerciseInteraction.validate_session(varied)
		assert(bool(vv["ok"]), "missione varia %s: %s" % [subject, str(vv["errors"])])
		var ratio := ExerciseInteraction.multiple_choice_ratio(varied.get("nodes", []))
		assert(ratio <= 0.34, "missione varia %s: scelta multipla dominante (%.2f)" % [subject, ratio])

	# Riferimento: rapporto MC medio delle missioni STANDARD (informativo).
	var std_mc := 0.0
	for subject in subjects:
		std_mc += ExerciseInteraction.multiple_choice_ratio(content.build_mission(str(subject), 4, 3, {}, rng).get("nodes", []))
	std_mc /= float(subjects.size())

	print("Exercise contract audit OK — %d item validati; esami multi-formato+trasferimento; missioni varie ≤1/3 MC (standard MC medio %.0f%%)" % [validated, std_mc * 100.0])
	quit(0)
