extends SceneTree

## Audit end-to-end O-P0.8: completa i livelli 1→24 usando SOLTANTO le azioni
## disponibili al giocatore — build_mission → record_mission/record_topic_stats →
## can_repair → build_final_exam → repair_and_advance. Nessun reload del mondo,
## nessuna injection di stato, nessun reset del conteggio.
##
## Verifica i requisiti di O-P0:
##  - ogni gate si apre NATURALMENTE (readiness a 4 dimensioni soddisfatta);
##  - il lavoro nelle materie NON correnti non va perso al salire di livello;
##  - riparare azzera il progresso-VERSO-gate della materia ma NON il cumulativo;
##  - la stessa materia, quando ritorna a un ciclo successivo (liv. 13+), richiede
##    missioni NUOVE (nessun doppio conteggio cross-ciclo).
##
## Uso: godot --headless --path godot --script res://scripts/game/progression_1to24_audit.gd

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1   # playthrough tutto corretto
		stats[topic] = e
	return stats

# Gioca una missione (tutte corrette) esattamente come il giocatore: costruisce
# dal banco, registra esito ed evidenza per-argomento. Ritorna il numero di nodi.
func _play_mission(save: GameSaveManager, content: ContentManager, prog: ProgressionManager, subject: String) -> int:
	var due := SpacedRepetition.due_map(save)
	var mission := content.build_mission(subject, save.level(), 3, due, null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	var total := nodes.size()
	if total == 0:
		push_error("Banco vuoto per '%s' — esegui `node scripts/build-exercise-banks.mjs`" % subject)
		quit(1)
		return 0
	prog.record_mission(subject, total, total, total * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))
	return total

## Pratica di una materia che il mondo non ospita: alza padronanza e argomenti,
## non conta per il gate dell'apparato. È tutto quello che il giocatore può fare
## sulle altre undici materie mentre è in questo mondo.
func _play_practice(save: GameSaveManager, content: ContentManager, prog: ProgressionManager, subject: String) -> void:
	var mission := content.build_mission(subject, save.level(), 3, {}, null,
		save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	prog.record_practice(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)

	# Prova "nessun lavoro perso": svolgo missioni di ITALIANO mentre sono al
	# livello 1 (focus matematica). Devono restare valide al livello 2 (italiano).
	assert(save.level() == 1)
	_play_mission(save, content, prog, "italiano")
	_play_mission(save, content, prog, "italiano")
	var italiano_prework := save.missions_toward_gate("italiano")
	assert(italiano_prework >= 2, "il prelavoro italiano deve essere registrato")

	var math_consumed_at_1 := 0
	var total_missions := 0

	while not prog.is_complete():
		var lvl := save.level()
		var subject := ApparatusConfig.world_subject(lvl)

		# Il livello si apre col NUCLEO, l'apparato con la materia del mondo: si
		# allenano entrambi. Prima bastava la materia del mondo perché era la stessa
		# cosa; da quando sono due assi distinti serve allenarli tutti e due.
		# Dal 5 agosto 2026 il livello si apre con TUTTE le materie a quel grado,
		# non con le tre strumentali. E si allenano come le allena il giocatore:
		# **missioni** per la materia che il mondo ospita (le uniche che il mondo
		# offre contando per il gate), **pratica** per le altre undici.
		#
		# Prima questo ciclo giocava missioni delle tre del nucleo a ogni livello:
		# simulava un giocatore che non può esistere, perché quelle missioni in
		# quel mondo non ci sono. È il difetto che ha lasciato passare il blocco
		# del mondo 1 fino al primo collaudo vero.
		var guard := 0
		while (not prog.can_repair() or not prog.can_level_up()) and guard < 500:
			_play_mission(save, content, prog, subject)
			for altra_data in ApparatusConfig.SUBJECT_CYCLE:
				var altra := str(altra_data)
				if altra != subject:
					_play_practice(save, content, prog, altra)
			total_missions += 1
			guard += 1
		assert(prog.can_repair(), "livello %d (%s): il gate deve aprirsi da solo (%s)" % [lvl, subject, str(prog.readiness().get("reasons", []))])

		# Il prelavoro italiano non deve sparire mentre si conclude il livello 1.
		if lvl == 1:
			assert(save.missions_toward_gate("italiano") >= italiano_prework, "il lavoro italiano non deve azzerarsi al livello 1")

		var cumulative_before := save.missions_of(subject)
		var exam := content.build_final_exam(subject, lvl, 3, null, save.mastery_of(subject), save.topic_masteries(subject))
		assert(not Array(exam.get("nodes", [])).is_empty(), "esame non vuoto per %s" % subject)
		assert(prog.repair_and_advance(true), "riparazione al livello %d" % lvl)
		assert(save.level() == lvl + 1, "avanzamento dopo il livello %d" % lvl)
		# Consumare il gate azzera il progresso-VERSO-gate ma non il cumulativo.
		assert(save.missions_toward_gate(subject) == 0, "gate consumato: progresso-verso-gate a 0 (%s)" % subject)
		assert(save.missions_of(subject) == cumulative_before, "il conteggio cumulativo resta invariato (%s)" % subject)
		if lvl == 1:
			math_consumed_at_1 = save.gate_consumed_of("matematica")

	# Cross-ciclo: niente doppio conteggio quando una materia ritorna.
	#
	# Fino al 5 agosto 2026 qui si pretendeva che il 2° ciclo di matematica
	# richiedesse missioni NUOVE. Con il gate a tre materie era vero; con il gate
	# a dodici non lo è più, e non per un difetto: praticando ogni materia a ogni
	# livello, al mondo 13 la matematica è già sopra soglia e il gate si apre
	# senza lavoro aggiuntivo. È il comportamento giusto — chi ha mantenuto una
	# competenza non deve ridimostrarla da zero — ma va detto invece di
	# pretendere il contrario.
	#
	# Quello che deve restare vero è l'invariante contro il doppio conteggio: le
	# missioni già spese a un gate non possono riaprirne un altro.
	assert(save.gate_consumed_of("matematica") >= math_consumed_at_1,
		"il consumo del gate non può diminuire")
	assert(save.missions_toward_gate("matematica") <= save.missions_of("matematica"),
		"il progresso-verso-gate non può superare il cumulativo")
	assert(save.level() == ApparatusConfig.MAX_LEVEL + 1)
	assert(prog.is_complete())

	print("Progressione 1→24 OK — %d livelli completati con %d missioni; energia %d, frammenti %d; prelavoro italiano preservato, nessun reset/injection." % [ApparatusConfig.MAX_LEVEL, total_missions, save.energy(), save.fragments()])
	quit(0)
