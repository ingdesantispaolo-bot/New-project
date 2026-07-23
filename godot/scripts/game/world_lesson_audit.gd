extends SceneTree

const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")

## Audit O-P2: la specifica didattica dei mondi 1 e 2 è completa, coerente con la
## scala e col WorldProfile, referenzia topic REALI, ha prove di trasferimento e
## testi di NORA, e la difficoltà dipende dalla COMPETENZA della materia (non dal
## rango globale).
## Uso: godot --headless --path godot --script res://scripts/game/world_lesson_audit.gd

func _init() -> void:
	var content := ContentManager.new()

	for level in [1, 2]:
		assert(WorldLessonCatalog.has_lesson(level), "manca la lezione del livello %d" % level)
		var lesson := WorldLessonCatalog.lesson(level)
		var subject := str(lesson["subject"])

		# Coerenza con la scala di progressione e col WorldProfile.
		assert(subject == str(ApparatusConfig.level_gate(level)["subject"]), "focus lezione L%d incoerente con la scala" % level)
		assert(subject == str(WorldProfileCatalog.profile(level)["learningFocus"]["subject"]), "focus lezione L%d incoerente col profilo" % level)

		# Contenuto didattico completo.
		assert(not Array(lesson["objectives"]).is_empty(), "L%d: obiettivi mancanti" % level)
		assert(not Array(lesson["prerequisites"]).is_empty(), "L%d: prerequisiti mancanti" % level)
		var actions: Array = lesson["conceptActions"]
		assert(not actions.is_empty(), "L%d: azioni-concetto mancanti" % level)
		for ca in actions:
			assert(str(ca["concept"]) != "" and str(ca["worldAction"]) != "", "L%d: azione-concetto incompleta" % level)

		# Prova di trasferimento: contesto nuovo + formati dichiarati.
		var tt: Dictionary = lesson["transferTest"]
		assert(str(tt["description"]) != "" and bool(tt["novelContext"]), "L%d: prova di trasferimento incompleta" % level)
		assert(not Array(tt["formats"]).is_empty(), "L%d: formati della prova mancanti" % level)

		# Testi di NORA: briefing, feedback (errore/serie) e debrief.
		assert(WorldLessonCatalog.briefing(level) != "", "L%d: briefing NORA mancante" % level)
		assert(WorldLessonCatalog.debrief(level) != "", "L%d: debrief NORA mancante" % level)
		assert(WorldLessonCatalog.feedback(level, "onError") != "", "L%d: feedback errore mancante" % level)
		assert(WorldLessonCatalog.feedback(level, "onStreak") != "", "L%d: feedback serie mancante" % level)

		# I topic referenziati devono essere REALI (prodotti dal contenuto).
		var topics: Array = lesson["topics"]
		assert(not topics.is_empty(), "L%d: topic mancanti" % level)
		if subject == "italiano":
			var bank := content.bank_topics("italiano")
			for t in topics:
				assert(bank.has(str(t)), "L%d: topic italiano inesistente nel banco: %s" % [level, str(t)])
		elif subject == "matematica":
			var produced: Dictionary = {}
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for _i in range(24):
				var mission := content.build_mission("matematica", level, 3, {}, rng)
				for node in mission.get("nodes", []):
					produced[str(node.get("topic", ""))] = true
			for t in topics:
				assert(produced.has(str(t)), "L%d: topic matematica non prodotto: %s" % [level, str(t)])

		assert(str(lesson["difficultyDriver"]) == "subjectMastery", "L%d: la difficoltà deve dipendere dalla competenza" % level)

	# Prova che la difficoltà dipende dalla COMPETENZA della materia e non solo dal
	# rango: a livello FISSO, alzare la mastery alza la difficoltà effettiva.
	var it_low := content.effective_difficulty("italiano", 2, 0.2)
	var it_high := content.effective_difficulty("italiano", 2, 0.9)
	assert(it_high > it_low, "italiano: la difficoltà a pari livello deve crescere con la competenza (%d→%d)" % [it_low, it_high])
	var ma_low := ContentManager.math_effective_level(1, 0.2)
	var ma_high := ContentManager.math_effective_level(1, 0.9)
	assert(ma_high > ma_low, "matematica: il livello efficace a pari rango deve crescere con la competenza (%d→%d)" % [ma_low, ma_high])

	print("WorldLesson audit OK — L1/L2: obiettivi, topic reali, prova di trasferimento, NORA e difficoltà per competenza")
	quit(0)
