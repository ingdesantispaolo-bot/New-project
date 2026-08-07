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
	await _prova_pannello()
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


## Il pannello: la pergamena si legge, non si perde in una riga di HUD.
##
## E' lo stesso difetto gia' commesso col briefing dei mondi, che finiva nella
## riga dei costi d'energia e veniva sostituito dal primo messaggio successivo.
func _prova_pannello() -> void:
	for livello in [1, 12, 24]:
		var pannello := ParchmentPanel.new()
		pannello.livello = livello
		pannello.trovate = 3
		pannello.totali = ApparatusConfig.MAX_LEVEL
		get_root().add_child(pannello)
		# Un frame: in uno script SceneTree `_ready` del pannello non e' ancora
		# passato quando `add_child` ritorna, e i figli non esistono. E' lo
		# stesso motivo per cui le altre prove di scena aspettano.
		await process_frame

		var autore := pannello.find_child("ParchmentAuthor", true, false) as Label
		var testo := pannello.find_child("ParchmentText", true, false) as Label
		var conteggio := pannello.find_child("ParchmentCount", true, false) as Label
		var chiudi := pannello.find_child("CloseButton", true, false) as Button

		assert(autore != null and autore.text.strip_edges() != "",
			"il pannello del mondo %d non mostra l'autore" % livello)
		assert(testo != null and testo.text.length() > 80,
			"il pannello del mondo %d non mostra il testo della pergamena" % livello)
		assert(str(ParchmentCatalog.per_world(livello).get("testo", "")) in testo.text,
			"il pannello del mondo %d mostra un testo che non e' la sua pergamena" % livello)
		assert(conteggio != null and conteggio.text.contains("3"),
			"il pannello non dice quante pergamene sono state trovate")
		# Richiudibile: senza il pulsante il pannello sarebbe una trappola a
		# schermo intero, e Eli resterebbe ferma per sempre.
		assert(chiudi != null, "il pannello della pergamena non si puo' chiudere")
		assert(chiudi.custom_minimum_size.y >= 48.0,
			"il pulsante di chiusura e' sotto il bersaglio minimo per un dito")

		pannello.queue_free()
