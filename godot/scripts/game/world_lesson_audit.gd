extends SceneTree

const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")
const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")

## Audit O-P2/O-P5: la specifica didattica di TUTTI i 24 mondi è completa, coerente
## con la scala e col WorldProfile, referenzia topic REALI, ha prove di
## trasferimento, testi di NORA, criteri di trasformazione ambientale, e la
## difficoltà dipende dalla COMPETENZA della materia (non dal rango globale).
## Uso: godot --headless --path godot --script res://scripts/game/world_lesson_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var levels := WorldLessonCatalog.all_levels()
	assert(levels.size() == 24, "servono lezioni per tutti i 24 mondi, trovate %d" % levels.size())

	# Insieme dei topic di matematica validi: banco + concetti del generatore.
	var math_valid: Dictionary = {}
	for t in content.bank_topics("matematica"):
		math_valid[str(t)] = true
	for t in KnowledgeCodex.MATH_CONCEPTS.keys():
		math_valid[str(t)] = true

	for level in levels:
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

		# Trasformazione ambientale (criteri semantici per Codex).
		var env := WorldLessonCatalog.environment_transform(level)
		assert(str(env.get("trigger", "")) != "" and str(env.get("effect", "")) != "", "L%d: trasformazione ambientale incompleta" % level)

		# I topic referenziati devono essere REALI.
		var topics: Array = lesson["topics"]
		assert(not topics.is_empty(), "L%d: topic mancanti" % level)
		if subject == "matematica":
			for t in topics:
				assert(math_valid.has(str(t)), "L%d: topic matematica inesistente: %s" % [level, str(t)])
		else:
			var bank := content.bank_topics(subject)
			for t in topics:
				assert(bank.has(str(t)), "L%d: topic %s inesistente nel banco %s" % [level, str(t), subject])

		assert(str(lesson["difficultyDriver"]) == "subjectMastery", "L%d: la difficoltà deve dipendere dalla competenza" % level)

	# La difficoltà dipende dalla COMPETENZA (non solo dal rango): a livello FISSO,
	# alzare la mastery alza la difficoltà effettiva.
	var it_low := content.effective_difficulty("italiano", 2, 0.2)
	var it_high := content.effective_difficulty("italiano", 2, 0.9)
	assert(it_high > it_low, "italiano: la difficoltà a pari livello deve crescere con la competenza (%d→%d)" % [it_low, it_high])
	var ma_low := ContentManager.math_effective_level(1, 0.2)
	var ma_high := ContentManager.math_effective_level(1, 0.9)
	assert(ma_high > ma_low, "matematica: il livello efficace a pari rango deve crescere con la competenza (%d→%d)" % [ma_low, ma_high])

	print("WorldLesson audit OK — 24 mondi: obiettivi, topic reali, trasferimento, NORA, trasformazione ambientale e difficoltà per competenza")
	quit(0)
