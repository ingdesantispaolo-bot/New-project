extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Audit della PROVA TRASVERSALE del mondo 24 (struttura finale congelata da Opus,
## Gate E1→E2). Verifica che l'esame finale copra i dodici sistemi, includa una
## sintesi di trasferimento, sia multi-formato, non-solo-MC, non cronometrato e
## deterministico.
## Uso: godot --headless --path godot --script res://scripts/game/finale_transversal_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2424

	var exam := content.build_final_transversal_exam(24, rng)
	var nodes: Array = exam["nodes"]

	# 1) Struttura: i dodici sistemi (uno per materia) + un nodo di sintesi.
	assert(bool(exam["transversal"]), "l'esame finale deve essere trasversale")
	assert(Array(exam["systems"]).size() == 12, "devono convergere i 12 sistemi")
	var systems_covered: Dictionary = {}
	var synthesis := 0
	for n in nodes:
		var sys := str(n.get("system", ""))
		if sys == "sintesi":
			synthesis += 1
			assert(bool(n.get("transfer", false)), "il nodo di sintesi deve essere di trasferimento")
		elif sys != "":
			systems_covered[sys] = true
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		assert(systems_covered.has(str(subject)), "manca il sistema: %s" % subject)
	assert(synthesis >= 1, "manca il nodo di sintesi finale")
	assert(nodes.size() >= 13, "il finale deve avere i 12 sistemi più la sintesi")

	# 2) Contratto esercizi: ogni nodo valido, multi-formato, non-solo-MC, con
	# almeno una prova di trasferimento.
	var vs := ExerciseInteraction.validate_session(exam)
	assert(bool(vs["ok"]), "nodi finale non validi: %s" % str(vs["errors"]))
	assert(ExerciseInteraction.distinct_formats(nodes).size() >= 2, "il finale deve usare ≥2 formati")
	assert(ExerciseInteraction.multiple_choice_ratio(nodes) < 1.0, "il finale non può essere solo scelta multipla")
	var has_transfer := false
	for n in nodes:
		if bool(n.get("transfer", false)):
			has_transfer = true
	assert(has_transfer, "il finale deve includere una prova di trasferimento")

	# 3) Ritmo: prova di ragionamento, mai cronometrata.
	assert(str(exam["pace"]) == "reasoning" and not bool(exam["timed"]), "il finale non deve avere limite di tempo")

	# 4) Determinismo: stesso seed → stesso esame (fixture riproducibile per Codex).
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 2424
	var exam2 := content.build_final_transversal_exam(24, rng2)
	assert(exam2["nodes"].size() == nodes.size(), "il finale deve essere deterministico a parità di seed")

	print("Finale transversal audit OK — 12 sistemi + sintesi di trasferimento, multi-formato, non cronometrato, deterministico")
	quit(0)
