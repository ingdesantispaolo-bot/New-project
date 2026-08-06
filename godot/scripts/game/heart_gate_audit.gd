extends SceneTree

## Audit del CUORE: si apre con dodici stanze accese, non con ventiquattro livelli.
##
## Chiude il vicolo cieco creato dalla decisione del 30 luglio. Da quando il
## livello è gatato dal solo nucleo (italiano, matematica, inglese), un giocatore
## poteva arrivare al livello 24 senza aver mai toccato latino — e trovarsi davanti
## la prova a dodici sistemi del Cuore, che non avrebbe potuto superare. Una
## partita chiusa in un angolo senza averlo fatto capire.
##
## Verifica:
##  - al livello 24 con stanze mancanti il Cuore NON si apre, e il gioco sa dire
##    quali mancano;
##  - con dodici stanze accese si apre;
##  - non si può oltrepassare l'ultimo gradino lasciando materie mai affrontate;
##  - il conteggio delle stanze è esposto DAL PRIMO LIVELLO, non solo alla fine.

func _init() -> void:
	_test_cuore_chiuso_con_stanze_spente()
	_test_cuore_aperto_con_dodici_stanze()
	_test_ultimo_gradino_richiede_le_stanze()
	_test_obiettivo_dichiarato_dall_inizio()
	print("Heart gate audit OK — il Cuore richiede dodici stanze, dichiarate dall'inizio")
	quit(0)

func _core_ready_save(level: int) -> GameSaveManager:
	var save := GameSaveManager.new()
	save.set_level(level)
	var threshold := ApparatusConfig.mastery_threshold(level)
	# Dal 5 agosto 2026 il livello si apre con TUTTE le materie, non con le tre
	# strumentali: per costruire un salvataggio «pronto a salire» vanno portate
	# sopra soglia tutte e dodici. E con abbastanza argomenti, perché la
	# copertura richiesta cresce col livello e scala con la materia.
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		save.set_mastery(s, maxf(threshold, 0.95))
		for i in range(24):
			save.set_topic_mastery(s, "t%d" % i, 1.0)
	return save

func _repair(save: GameSaveManager, subjects: Array) -> void:
	for subject in subjects:
		save.set_apparatus_repaired(ApparatusConfig.apparatus_of(str(subject)), 1)

func _test_cuore_chiuso_con_stanze_spente() -> void:
	var save := _core_ready_save(ApparatusConfig.MAX_LEVEL)
	var prog := ProgressionManager.new(save)
	# Solo il nucleo affrontato: è lo scenario esatto del vicolo cieco.
	_repair(save, ApparatusConfig.CORE_SUBJECTS)
	assert(prog.can_level_up(), "il nucleo è pronto: il livello sarebbe aperto")
	assert(not prog.can_open_heart(), "il Cuore NON deve aprirsi con nove stanze spente")
	var missing := prog.missing_apparatus_subjects()
	assert(
		missing.size() == ApparatusConfig.SUBJECT_CYCLE.size() - ApparatusConfig.CORE_SUBJECTS.size(),
		"devono mancare nove stanze, trovate %d" % missing.size())
	# Il gioco deve saper DIRE cosa manca: una porta chiusa senza spiegazione è un
	# difetto quanto la porta impossibile.
	for subject in missing:
		assert(not ApparatusConfig.is_core(str(subject)), "il nucleo risulta spento per errore")
		assert(str(subject) != "", "nome materia mancante vuoto")

func _test_cuore_aperto_con_dodici_stanze() -> void:
	var save := _core_ready_save(ApparatusConfig.MAX_LEVEL)
	var prog := ProgressionManager.new(save)
	_repair(save, ApparatusConfig.SUBJECT_CYCLE)
	assert(prog.all_apparatus_repaired(), "dodici stanze accese")
	assert(prog.missing_apparatus_subjects().is_empty(), "nessuna stanza mancante")
	assert(prog.can_open_heart(), "con dodici stanze il Cuore deve aprirsi")

func _test_ultimo_gradino_richiede_le_stanze() -> void:
	var save := _core_ready_save(ApparatusConfig.MAX_LEVEL)
	var prog := ProgressionManager.new(save)
	_repair(save, ApparatusConfig.CORE_SUBJECTS)
	assert(not prog.advance_level(), "non si chiude la campagna con nove materie mai toccate")
	assert(save.level() == ApparatusConfig.MAX_LEVEL, "il livello non deve muoversi")
	_repair(save, ApparatusConfig.SUBJECT_CYCLE)
	assert(prog.advance_level(), "con dodici stanze l'ultimo gradino si supera")
	assert(prog.is_complete(), "la campagna deve risultare completa")

func _test_obiettivo_dichiarato_dall_inizio() -> void:
	# Il conteggio delle stanze è nel contratto già al livello 1: l'obiettivo si
	# scopre all'inizio, non al mondo 24.
	var save := _core_ready_save(1)
	var prog := ProgressionManager.new(save)
	var progress := prog.repair_progress()
	assert(progress.has("apparatusRepaired"), "il contratto deve esporre le stanze accese")
	assert(
		int(progress["apparatusTotal"]) == ApparatusConfig.SUBJECT_CYCLE.size(),
		"il totale delle stanze deve essere dodici")
	assert(int(progress["apparatusRepaired"]) == 0, "a inizio partita nessuna stanza accesa")
	assert(not prog.can_open_heart(), "al livello 1 il Cuore non è aperto")
