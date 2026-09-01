extends SceneTree

const ProgressRecognition = preload("res://scripts/game/progress_recognition.gd")

## Le Quattro Vie devono riconoscere tutto senza diventare una nuova economia,
## una classifica o una scorciatoia da farming.

func _init() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var energia := save.energy()
	var frammenti := save.fragments()
	var mastery := save.mastery_of("matematica")

	var capire := ProgressRecognition.record(
		save, "mission", "missione-tobia", 1, {"subject": "matematica"})
	assert(str(capire.get("path", "")) == ProgressRecognition.COMPRENDERE,
		"una missione non accende Comprendere")
	assert(bool(capire.get("newFacet", false)), "la prima missione non accende la faccia")

	var costruire := ProgressRecognition.record(save, "enigma", "ponte-1", 1)
	var esplorare := ProgressRecognition.record(save, "hazard", "world-danger-01", 1)
	var legame := ProgressRecognition.record(save, "resident", "gioco-w01-tobia", 1)
	assert(str(costruire.get("path", "")) == ProgressRecognition.COSTRUIRE,
		"un enigma non accende Costruire")
	assert(str(esplorare.get("path", "")) == ProgressRecognition.ESPLORARE,
		"un pericolo non accende Esplorare")
	assert(str(legame.get("path", "")) == ProgressRecognition.LEGAMI,
		"aiutare un abitante non accende i Legami")

	var summary := ProgressRecognition.summary(save)
	assert(int(summary.get("facets", 0)) == 4, "il primo mondo non ha quattro facce")
	assert(str(summary.get("title", "")) == "Primo Segno",
		"quattro vie non sbloccano il primo titolo")

	# Idempotenza: lo stesso fatto non puo' essere rivendicato due volte.
	assert(ProgressRecognition.record(save, "mission", "missione-tobia", 1).is_empty(),
		"la stessa missione e' stata riconosciuta due volte")
	assert(int(ProgressRecognition.summary(save).get("facets", 0)) == 4,
		"un duplicato ha gonfiato le facce")

	# Una seconda esplorazione nello stesso mondo resta registrata, ma la via era
	# gia' accesa: i forzieri numerosi non devono dominare il ritratto.
	var secondo_tesoro := ProgressRecognition.record(save, "treasure", "cassa-2", 1)
	assert(not bool(secondo_tesoro.get("newFacet", true)),
		"un secondo ritrovamento ha acceso due volte Esplorare nello stesso mondo")
	assert(int(ProgressRecognition.summary(save).get("facets", 0)) == 4,
		"la densita' dei tesori ha aumentato il totale delle facce")
	assert(int(Dictionary(ProgressRecognition.summary(save).get("byKind", {})).get("treasure", 0)) == 1,
		"il secondo ritrovamento non e' rimasto nel diario")

	# Nessuna economia o competenza viene toccata dal riconoscimento.
	assert(save.energy() == energia, "il riconoscimento ha cambiato l'energia")
	assert(save.fragments() == frammenti, "il riconoscimento ha coniato frammenti")
	assert(is_equal_approx(save.mastery_of("matematica"), mastery),
		"il riconoscimento ha cambiato la padronanza")
	assert(ProgressRecognition.record(save, "sconosciuto", "x", 1).is_empty(),
		"un tipo sconosciuto e' entrato nel ritratto")

	# Il riepilogo del diario legge la stessa fonte, senza un secondo conteggio.
	var diary := PlayDiary.summary(save)
	assert(int(Dictionary(diary.get("riconoscimenti", {})).get("facets", 0)) == 4,
		"il diario non espone le Quattro Vie")

	# Migrazione additiva: un vecchio save senza la chiave riceve uno stato sano.
	var legacy := GameSaveManager._default_data()
	legacy.erase("recognition")
	var migrated := save.migrate_legacy_save(legacy)
	assert(migrated.has("recognition"), "la migrazione perde il registro")
	var migrated_save := GameSaveManager.new()
	migrated_save.data = migrated
	assert(int(ProgressRecognition.summary(migrated_save).get("facets", -1)) == 0,
		"un vecchio save nasce con riconoscimenti inventati")

	print("PROGRESS RECOGNITION audit OK - quattro vie, niente farming, economia intatta")
	quit(0)
