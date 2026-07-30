extends SceneTree

## Audit dello sblocco del Secondo Viaggio (tappa 1 · S0).
##
## Verifica il contratto della voce di menu: il contatore dei mondi completati è
## corretto e limitato alla scala, la rotta si apre SOLO a campagna completata e
## non esiste una scorciatoia — energia, frammenti o cosmetici non la aprono.
##
## Perché un audit per una voce di menu: è l'unico posto in cui una promessa
## fatta al giocatore («finisci e si apre un altro gioco») può diventare una
## bugia per un errore di un'unità. `worldsCompleted` = livello − 1, e sbagliare
## quel −1 significa mostrare "24/24 · rotta chiusa" a chi ha finito, oppure
## aprire la rotta a chi sta ancora giocando il mondo 24.

const MAX := 24

func _init() -> void:
	_test_profilo_nuovo()
	_test_conteggio_lungo_la_scala()
	_test_apertura_solo_a_campagna_completa()
	_test_conteggio_limitato_alla_scala()
	_test_nessuna_scorciatoia()
	print("Secondo Viaggio unlock audit OK — contatore onesto e rotta non aggirabile")
	quit(0)

func _progress_at_level(level: int) -> Dictionary:
	var save := GameSaveManager.new()
	save.set_level(level)
	return ProgressionManager.new(save).campaign_progress()

func _test_profilo_nuovo() -> void:
	# Al primissimo avvio la voce deve essere disegnabile e dire 0/24, non
	# ereditare un conteggio negativo dal livello 1.
	var progress := ProgressionManager.new(GameSaveManager.new()).campaign_progress()
	assert(int(progress["worldsCompleted"]) == 0, "profilo nuovo: atteso 0 mondi completati")
	assert(int(progress["worldsTotal"]) == MAX, "il totale deve essere la scala dei mondi")
	assert(not bool(progress["complete"]), "profilo nuovo: la rotta deve essere chiusa")

func _test_conteggio_lungo_la_scala() -> void:
	# Al livello L sono completati L-1 mondi: stai GIOCANDO il mondo L, non lo hai
	# finito. È il fuori-di-uno che questo audit esiste per impedire.
	for level in range(1, MAX + 1):
		var progress := _progress_at_level(level)
		assert(
			int(progress["worldsCompleted"]) == level - 1,
			"livello %d: attesi %d mondi completati, trovati %d" % [
				level, level - 1, int(progress["worldsCompleted"])])
		assert(
			not bool(progress["complete"]),
			"livello %d: la campagna non è finita, la rotta deve restare chiusa" % level)

func _test_apertura_solo_a_campagna_completa() -> void:
	# Il confine esatto: al 24 la rotta è ancora chiusa (23/24), al 25 si apre.
	var at_last := _progress_at_level(MAX)
	assert(int(at_last["worldsCompleted"]) == MAX - 1, "al livello 24 devono mancare ancora le riparazioni del 24")
	assert(not bool(at_last["complete"]), "al livello 24 la rotta NON deve essere aperta")

	var beyond := _progress_at_level(MAX + 1)
	assert(int(beyond["worldsCompleted"]) == MAX, "a campagna completata attesi 24/24")
	assert(bool(beyond["complete"]), "a campagna completata la rotta deve aprirsi")

func _test_conteggio_limitato_alla_scala() -> void:
	# Un livello oltre la scala non deve produrre "29/24" nella UI.
	var progress := _progress_at_level(MAX + 6)
	assert(int(progress["worldsCompleted"]) == MAX, "il conteggio deve essere limitato a %d" % MAX)
	assert(bool(progress["complete"]), "oltre la scala la rotta resta aperta")

func _test_nessuna_scorciatoia() -> void:
	# Energia, frammenti e cosmetici non aprono la rotta: solo le riparazioni.
	var save := GameSaveManager.new()
	save.set_level(3)
	save.add_energy(999999)
	save.add_fragments(999999)
	save.data["cosmetics"] = {
		"inventory": ["pet-codex", "avatar-astral", "nora-prismatic-core"],
		"equipped": {"pet": "pet-codex"},
	}
	var progress := ProgressionManager.new(save).campaign_progress()
	assert(not bool(progress["complete"]), "l'energia non può aprire la rotta")
	assert(int(progress["worldsCompleted"]) == 2, "l'energia non può muovere il contatore")
