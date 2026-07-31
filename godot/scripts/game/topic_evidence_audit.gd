extends SceneTree

const TopicEvidence = preload("res://scripts/game/topic_evidence.gd")
const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")

## Decisione utente del 29 luglio 2026: un argomento è CONSOLIDATO con tre
## risposte corrette in sessioni distinte, di cui almeno una a ≥ 3 giorni dalla
## prima. Questo audit fissa il criterio e, soprattutto, ciò che NON deve
## succedere: che tre risposte nella stessa mezz'ora bastino, e che il tempo
## diventi un requisito per avanzare nel gioco.
## Uso: godot --headless --path godot --script res://scripts/game/topic_evidence_audit.gd

const DAY := 86400.0
const T0 := 1_800_000_000.0   # istante arbitrario: l'orologio è iniettato

func _init() -> void:
	_test_stessa_sessione_non_conta()
	_test_tre_sessioni_in_giornata_non_bastano()
	_test_tre_sessioni_in_tre_giorni_consolidano()
	_test_il_gate_non_richiede_il_consolidamento()
	_test_save_vecchio_senza_evidenza()
	TopicEvidence.set_clock(-1.0)
	print("Topic evidence audit OK — consolidato solo con 3 sessioni distinte e ≥3 giorni; il gate resta libero dal calendario")
	quit(0)

# Tre risposte giuste nella STESSA sessione valgono una prova sola.
func _test_stessa_sessione_non_conta() -> void:
	var save := _new_save()
	TopicEvidence.set_clock(T0)
	for i in range(3):
		TopicEvidence.record_correct(save, "scienze", "ecosistema", 4)
	assert(TopicEvidence.correct_sessions(save, "scienze", "ecosistema") == 1,
		"la stessa sessione non può valere tre prove")
	assert(not TopicEvidence.is_consolidated(save, "scienze", "ecosistema"), "una sessione non consolida")

# Tre sessioni distinte ma tutte nello stesso pomeriggio: non è ritenzione.
func _test_tre_sessioni_in_giornata_non_bastano() -> void:
	var save := _new_save()
	for i in range(3):
		TopicEvidence.set_clock(T0 + float(i) * 900.0)   # un quarto d'ora l'una dall'altra
		TopicEvidence.record_correct(save, "storia", "egizi", i)
	assert(TopicEvidence.correct_sessions(save, "storia", "egizi") == 3, "tre sessioni distinte contate")
	assert(not TopicEvidence.is_consolidated(save, "storia", "egizi"),
		"senza distanza nel tempo non c'è consolidamento")
	var progress := TopicEvidence.progress(save, "storia", "egizi")
	assert(float(progress["spanDays"]) < 1.0 and int(progress["correctSessions"]) == 3,
		"il report deve dire che mancano i giorni, non le prove")

# Il percorso reale: tre sessioni corrette distribuite su tre giorni, passando
# dalla pipeline vera (record_topic_stats) e non dall'API di basso livello.
func _test_tre_sessioni_in_tre_giorni_consolidano() -> void:
	var save := _new_save()
	var progression := ProgressionManager.new(save)
	var stats := {"frazioni": {"seen": 2, "correct": 2}}
	# Tre sessioni: oggi, domani e fra tre giorni — l'ultima a ≥ 3 giorni dalla
	# prima, che è ciò che il criterio chiede (non "tre giorni consecutivi").
	for day in [0.0, 1.0, 3.0]:
		TopicEvidence.set_clock(T0 + float(day) * DAY + 600.0)
		progression.record_topic_stats("matematica", stats)
		SpacedRepetition.tick(save)
	assert(TopicEvidence.correct_sessions(save, "matematica", "frazioni") == 3, "tre sessioni distinte")
	assert(TopicEvidence.span_seconds(save, "matematica", "frazioni") >= 3.0 * DAY - 1.0, "distanza di tre giorni")
	assert(TopicEvidence.is_consolidated(save, "matematica", "frazioni"), "criterio soddisfatto")
	assert(KnowledgeCodex.state_of(save, "matematica", "frazioni") == "consolidated",
		"il Manuale deve dichiarare consolidato l'argomento")
	assert(TopicEvidence.consolidated_topics(save, "matematica") == ["frazioni"], "elenco per il report")

	# Una padronanza altissima raggiunta in un pomeriggio NON consolida più.
	var quick := _new_save()
	var quick_progression := ProgressionManager.new(quick)
	TopicEvidence.set_clock(T0)
	for i in range(6):
		quick_progression.record_topic_stats("matematica", stats)
		SpacedRepetition.tick(quick)
	assert(quick.topic_mastery_of("matematica", "frazioni") >= 0.85, "padronanza alta raggiunta in giornata")
	assert(KnowledgeCodex.state_of(quick, "matematica", "frazioni") != "consolidated",
		"la padronanza alta da sola non è ritenzione")

# Il consolidamento NON entra nel gate: un mondo deve restare completabile in un
# pomeriggio, altrimenti la progressione dipenderebbe dal calendario.
func _test_il_gate_non_richiede_il_consolidamento() -> void:
	var save := _new_save()
	var progression := ProgressionManager.new(save)
	var subject := ApparatusConfig.world_subject(save.level())
	TopicEvidence.set_clock(T0)
	var guard := 0
	while not progression.can_repair() and guard < 40:
		progression.record_mission(subject, 3, 3, 0, true)
		progression.record_topic_stats(subject, {"a": {"seen": 1, "correct": 1}, "b": {"seen": 1, "correct": 1}, "c": {"seen": 1, "correct": 1}})
		SpacedRepetition.tick(save)
		guard += 1
	assert(progression.can_repair(), "il gate si apre nella stessa giornata")
	assert(TopicEvidence.consolidated_topics(save, subject).is_empty(),
		"nessun argomento è consolidato in giornata: il gate non lo richiede")

# Un save precedente non ha `topicEvidence`: né errori né perdita di progresso.
func _test_save_vecchio_senza_evidenza() -> void:
	var save := GameSaveManager.new()
	var legacy := {"schemaVersion": 1, "playerId": "local", "level": 3, "energy": 10, "mastery": {"italiano": 0.7}}
	save.data = save.migrate_legacy_save(legacy)
	assert(save.data.has("topicEvidence"), "la migrazione aggiunge l'evidenza di ritenzione")
	assert(TopicEvidence.correct_sessions(save, "italiano", "sintassi") == 0, "nessuna evidenza pregressa")
	assert(not TopicEvidence.is_consolidated(save, "italiano", "sintassi"), "niente consolidamenti regalati")
	assert(float(save.mastery_of("italiano")) == 0.7, "la padronanza precedente resta")

func _new_save() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save
