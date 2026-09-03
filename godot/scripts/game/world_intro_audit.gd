extends SceneTree

## **La soglia di un mondo.** (6 agosto 2026)
##
## La schermata di benvenuto deve reggere per tutti e ventiquattro i mondi, non
## solo per il primo: un titolo vuoto o un briefing mancante al mondo 17 lo
## scoprirebbe un bambino, non io.
##
## Le proprietà tenute qui:
##
##   1. **ogni mondo ha le sue tre risposte** — dove sono, cosa imparo, cosa mi
##      apre — e nessuna è vuota;
##   2. **niente è riciclato**: titoli e briefing distinti mondo per mondo. Una
##      schermata identica in due mondi è peggio di nessuna schermata, perché
##      insegna che leggerla non serve;
##   3. **si vede una volta sola**, e la richiesta è atomica: chiedere e segnare
##      in due tempi la mostrerebbe due volte in un rientro rapido, e una
##      schermata che ricompare si impara a chiudere senza leggerla.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_prova_contenuto()
	_prova_niente_riciclato()
	_prova_una_volta_sola()
	await _prova_spiegazione_mondo_due()
	print("WORLD INTRO audit OK — 24 soglie distinte, guida rileggibile e cinque strumenti spiegati")
	quit(0)

func _prova_spiegazione_mondo_due() -> void:
	for id_data in FieldTools.ids():
		var tool_id := str(id_data)
		var pannello := WorldIntroPanel.new()
		pannello.livello = FieldTools.mondo_di(tool_id)
		pannello.strumento_dovuto = tool_id
		if tool_id == FieldTools.FALCE:
			pannello.strumenti_recuperati = [FieldTools.TORCIA]
		root.add_child(pannello)
		await process_frame
		var testo := ""
		for nodo in pannello.find_children("*", "Label", true, false):
			testo += "\n%s" % str((nodo as Label).text)
		assert(testo.contains("COME FUNZIONANO I LAVORI"),
			"il mondo %d non spiega la sequenza dei lavori" % pannello.livello)
		assert(testo.contains(FieldTools.nome(tool_id)) and testo.contains("Non cercarla nella bottega"),
			"la soglia del mondo %d non spiega dove arriva %s" % [
				pannello.livello, tool_id])
		if tool_id == FieldTools.FALCE:
			assert(testo.contains("STRUMENTI RECUPERATI") and testo.contains(FieldTools.nome(FieldTools.TORCIA)),
				"il mondo 2 non spiega che la torcia arretrata è già nell'inventario")
		pannello.queue_free()
		await process_frame
	var obiettivi := ObjectivePanel.new()
	root.add_child(obiettivi)
	await process_frame
	obiettivi.apri(
		{"titolo": "Passo", "azione": "Azione", "dove": "Qui"},
		{"righe": [], "fatte": 0, "totali": 12, "pronto": false, "dove": "Nel mondo"})
	assert(obiettivi.find_child("ObjectiveWorldGuideButton", true, false) != null,
		"il quadro obiettivi non permette di rileggere la guida del mondo")
	obiettivi.queue_free()
	await process_frame

func _prova_contenuto() -> void:
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var titolo := WorldIntroPanel.titolo_mondo(livello)
		assert(titolo.strip_edges().length() > 3,
			"il mondo %d non ha un nome da mostrare: «%s»" % [livello, titolo])

		# DOVE SONO: il beat di trama.
		var beat := str(NarrativeManager.BEATS.get(livello, ""))
		assert(beat.length() > 40, "il mondo %d non ha un beat di trama leggibile" % livello)

		# COSA IMPARO: briefing e obiettivi.
		var briefing := WorldLessonCatalog.briefing(livello)
		assert(briefing.length() > 40,
			"il mondo %d non ha un briefing: la schermata resterebbe senza guida" % livello)
		var lezione := WorldLessonCatalog.lesson(livello)
		var obiettivi: Array = lezione.get("objectives", [])
		assert(obiettivi.size() >= 2,
			"il mondo %d dichiara %d obiettivi: troppo pochi per dire cosa si impara" % [
				livello, obiettivi.size()])
		for o in obiettivi:
			assert(str(o).strip_edges().length() > 15, "obiettivo vuoto al mondo %d" % livello)

		# La materia della lezione deve essere quella che abita il mondo:
		# se divergessero, la schermata prometterebbe una materia e il mondo ne
		# insegnerebbe un'altra.
		assert(str(lezione.get("subject", "")) == ApparatusConfig.world_subject(livello),
			"il mondo %d promette %s ma ospita %s" % [
				livello, str(lezione.get("subject", "")), ApparatusConfig.world_subject(livello)])

func _prova_niente_riciclato() -> void:
	var titoli: Dictionary = {}
	var briefing: Dictionary = {}
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var t := WorldIntroPanel.titolo_mondo(livello)
		assert(not titoli.has(t), "due mondi hanno lo stesso nome: %d e %d — «%s»" % [
			int(titoli.get(t, 0)), livello, t])
		titoli[t] = livello
		var b := WorldLessonCatalog.briefing(livello)
		assert(not briefing.has(b), "due mondi hanno lo stesso briefing: %d e %d" % [
			int(briefing.get(b, 0)), livello])
		briefing[b] = livello

func _prova_una_volta_sola() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	assert(not save.world_intro_seen(1), "la soglia del mondo 1 risulta già vista")
	assert(save.claim_world_intro(1), "la prima richiesta della soglia è stata rifiutata")
	assert(save.world_intro_seen(1), "la soglia richiesta non risulta vista")
	# Atomica: dieci rientri rapidi non la rimostrano.
	for _i in range(10):
		assert(not save.claim_world_intro(1), "la soglia del mondo 1 si è ripresentata")
	# Ogni mondo ha la sua: vederne una non consuma le altre.
	assert(save.claim_world_intro(2), "vedere la soglia del mondo 1 ha consumato quella del 2")
	assert(not save.world_intro_seen(7), "una soglia mai vista risulta vista")
