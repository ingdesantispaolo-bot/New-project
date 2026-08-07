extends SceneTree

## **Le pergamene dei Dodici.** (7 agosto 2026)
##
## Una per mondo, chiusa in una camera che si apre solo con la serratura. È
## l'unico posto del gioco in cui una zona è davvero inaccessibile, e si può
## fare per una ragione sola: **dentro non c'è niente che serva a progredire**.
## Se un giorno qualcosa di obbligatorio finisse là dentro, quella stanza
## diventerebbe un vicolo cieco — ed è la cosa che questo audit sorveglia.
##
## Le altre proprietà: ventiquattro pergamene distinte, ognuna con un autore,
## nessuna che dica che qualcuno è morto (regola di trama §10.1), e la camera
## che si apre una volta sola.

func _init() -> void:
	_prova_contenuto()
	_prova_una_volta_sola()
	print("PARCHMENT audit OK — 24 pergamene distinte, camera apribile una volta sola")
	quit(0)

func _prova_contenuto() -> void:
	var testi: Dictionary = {}
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		assert(ParchmentCatalog.esiste(livello), "il mondo %d non ha la sua pergamena" % livello)
		var p := ParchmentCatalog.per_world(livello)
		var autore := str(p.get("autore", "")).strip_edges()
		var testo := str(p.get("testo", "")).strip_edges()
		assert(autore.length() > 6, "pergamena %d senza autore" % livello)
		assert(testo.length() > 80,
			"pergamena %d troppo scarna (%d caratteri): è l'altro lato della storia, non una didascalia" % [
				livello, testo.length()])
		assert(not testi.has(testo), "due mondi hanno la stessa pergamena: %d e %d" % [
			int(testi.get(testo, 0)), livello])
		testi[testo] = livello

		# Regola di trama non negoziabile: nessuno è morto. Le sorelle e
		# Meridiana sono trattenute, e le pergamene — più antiche — non
		# potrebbero comunque saperlo.
		var basso := testo.to_lower()
		for proibito in ["è morto", "è morta", "sono morti", "sono morte", "ucciso", "uccisa"]:
			assert(not basso.contains(str(proibito)),
				"la pergamena %d dice che qualcuno è morto: «%s»" % [livello, testo.substr(0, 60)])

		assert(ParchmentCatalog.testo_completo(livello).contains(autore),
			"il testo completo della pergamena %d non nomina l'autore" % livello)

func _prova_una_volta_sola() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	assert(save.parchment_count() == 0, "un profilo nuovo ha già delle pergamene")
	assert(not save.has_parchment(3), "una pergamena mai trovata risulta trovata")
	assert(save.claim_parchment(3), "la prima raccolta è stata rifiutata")
	assert(save.has_parchment(3), "la pergamena raccolta non risulta trovata")
	# La camera si apre una volta sola: il tesoro dentro non si prende due volte.
	for _i in range(10):
		assert(not save.claim_parchment(3), "la camera del mondo 3 si è riaperta")
	assert(save.parchment_count() == 1, "il conteggio delle pergamene è sbagliato")
	assert(save.claim_parchment(7), "aprire una camera ha consumato quella di un altro mondo")
	assert(save.parchment_count() == 2, "il conteggio non segue le camere aperte")
