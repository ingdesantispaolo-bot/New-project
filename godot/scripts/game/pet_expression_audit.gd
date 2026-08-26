extends SceneTree

## Audit del Custode (tappa 2 · P1–P2). Vedi docs/PET_CUSTODE.md §6.5.
##
## Il controllo che giustifica l'audit è uno: **nessun segnale di errore,
## fallimento o difficoltà può produrre un'espressione negativa** — e non perché
## la mappa oggi sia scritta bene, ma perché di espressioni negative non ne
## esistono nel catalogo. Vedere il proprio compagno deluso dopo una risposta
## sbagliata è vergogna, e la vergogna spegne l'apprendimento: è l'unico canale di
## feedback del gioco che non valuta mai.
##
## Verifica inoltre che il legame sia monotono (non scende in nessuna sequenza di
## eventi), che le espressioni non ancora sbloccate non possano diventare attive,
## e che il compagno non conceda mai vantaggi di gioco.

func _init() -> void:
	_test_catalogo_senza_facce_negative()
	_test_ogni_segnale_ha_una_faccia()
	_test_errori_mai_negativi()
	_test_reazioni_per_specie_e_indole()
	_test_priorita_e_isteresi()
	_test_legame_monotono()
	_test_facce_bloccate_non_attive()
	_test_consegna_iniziale()
	print("Pet expression audit OK — nessuna faccia negativa, legame monotono")
	quit(0)

func _test_catalogo_senza_facce_negative() -> void:
	assert(
		PetExpressionEngine.NEGATIVE_FACES.is_empty(),
		"il catalogo non deve contenere espressioni negative: %s" % str(PetExpressionEngine.NEGATIVE_FACES))
	# Ogni faccia dichiarata dallo stato deve esistere nel catalogo del motore, e
	# viceversa: due elenchi che divergono producono facce mai mostrate o mai sbloccabili.
	for face in PetState.all_faces():
		assert(
			PetExpressionEngine.is_known(str(face)),
			"faccia sbloccabile assente dal catalogo del motore: %s" % str(face))
	for face in PetExpressionEngine.CATALOG.keys():
		assert(
			PetState.all_faces().has(str(face)),
			"faccia nel catalogo ma non sbloccabile da nessun legame: %s" % str(face))

func _test_ogni_segnale_ha_una_faccia() -> void:
	for game_signal in PetExpressionEngine.GAME_SIGNALS:
		var face := PetExpressionEngine.face_for(str(game_signal))
		assert(face != "", "segnale senza faccia: %s" % str(game_signal))
		assert(
			PetExpressionEngine.is_known(face),
			"segnale %s mappato su faccia sconosciuta: %s" % [str(game_signal), face])

func _test_errori_mai_negativi() -> void:
	# `incoraggiante` è l'unica risposta ammessa a un esito negativo.
	for game_signal in PetExpressionEngine.FAILURE_SIGNALS:
		var face := PetExpressionEngine.face_for(str(game_signal))
		assert(
			not PetExpressionEngine.NEGATIVE_FACES.has(face),
			"segnale di fallimento %s su faccia negativa: %s" % [str(game_signal), face])
		assert(
			face == "incoraggiante",
			"segnale di fallimento %s dovrebbe incoraggiare, non %s" % [str(game_signal), face])
	# `offeso` — la sola faccia che somiglia a un rimprovero — non può nascere da un
	# errore: solo dall'inattività, e dura poco.
	for game_signal in PetExpressionEngine.GAME_SIGNALS:
		if PetExpressionEngine.face_for(str(game_signal)) == "offeso":
			assert(
				str(game_signal) == "idle",
				"'offeso' può nascere solo dall'inattività, non da %s" % str(game_signal))
	assert(
		PetExpressionEngine.duration_of("offeso") > 0.0,
		"'offeso' deve scadere da solo, senza input del giocatore")

func _test_reazioni_per_specie_e_indole() -> void:
	var kinds := [
		"dog", "cat", "rabbit", "spark", "comet", "orbit",
		"satellite", "prisma", "luma", "guardiano", "codex",
	]
	for kind in kinds:
		for illustrated_face in ["beato", "stupito"]:
			var art_path := "res://assets/custodi/%s-%s-v2.png" % [kind, illustrated_face]
			assert(ResourceLoader.exists(art_path, "Texture2D"),
				"manca il ritratto %s del Custode %s" % [illustrated_face, kind])
		for temperament in PetState.TEMPERAMENTS:
			assert(PetExpressionEngine.face_for_pet("cuddle", str(temperament), kind) == "beato",
				"la carezza non rende beato %s/%s" % [kind, temperament])
			for game_signal in PetExpressionEngine.GAME_SIGNALS:
				var face := PetExpressionEngine.face_for_pet(str(game_signal), str(temperament), kind)
				assert(PetExpressionEngine.is_known(face),
					"reazione sconosciuta per %s/%s/%s: %s" % [kind, temperament, game_signal, face])
			for game_signal in PetExpressionEngine.FAILURE_SIGNALS:
				assert(PetExpressionEngine.face_for_pet(str(game_signal), str(temperament), kind) == "incoraggiante",
					"%s/%s giudica un errore invece di incoraggiare" % [kind, temperament])
	assert(PetExpressionEngine.face_for("sister_found") == "stupito",
		"una rivelazione della storia deve sorprendere")
	assert(PetExpressionEngine.face_for("near_faded") == "coraggioso",
		"davanti al pericolo il Custode deve farsi coraggio")
	assert(PetExpressionEngine.face_for("learning:improvement") == "sollevato",
		"un miglioramento difficile deve portare sollievo")
	assert(PetExpressionEngine.face_for_pet("idle", "calmo", "cat") == "assonnato",
		"un Custode calmo nel silenzio deve potersi assopire")

func _test_priorita_e_isteresi() -> void:
	# Una faccia a priorità più alta passa sempre.
	assert(
		PetExpressionEngine.should_replace("sereno", 0.0, "festa"),
		"la festa deve poter interrompere il riposo")
	# A priorità pari o minore non si cambia prima dell'isteresi: il muso non
	# sfarfalla fra due stati in mezzo secondo.
	assert(
		not PetExpressionEngine.should_replace("orgoglioso", 0.2, "incoraggiante"),
		"cambio a priorità pari prima dell'isteresi")
	assert(
		not PetExpressionEngine.should_replace("festa", 0.5, "curioso"),
		"una faccia a priorità minore non deve interrompere la festa")
	assert(
		not PetExpressionEngine.should_replace("sereno", 5.0, "sereno"),
		"la stessa faccia non deve ripartire")
	assert(
		not PetExpressionEngine.should_replace("sereno", 5.0, "inesistente"),
		"una faccia sconosciuta non deve mai essere accettata")
	assert(PetExpressionEngine.MIN_HYSTERESIS_SEC >= 1.0, "isteresi troppo corta")

func _test_legame_monotono() -> void:
	var save := GameSaveManager.new()
	var previous := PetState.bond(save)
	# Sequenza avversa: valori negativi, zero, sessioni, coccole, ripetizioni.
	for amount in [-1.0, -0.5, 0.0, 0.02, -10.0, 0.0]:
		PetState.add_bond(save, amount)
		var now := PetState.bond(save)
		assert(now >= previous, "il legame è scemato: %f → %f" % [previous, now])
		previous = now
	for _i in range(200):
		PetState.register_session(save)
		PetState.register_cuddle(save)
		var value := PetState.bond(save)
		assert(value >= previous, "il legame è scemato durante il gioco")
		assert(value <= 1.0, "il legame ha superato 1.0: %f" % value)
		previous = value
	assert(PetState.bond(save) == 1.0, "con abbastanza gioco il legame deve arrivare a 1.0")
	# A legame pieno tutte le facce sono sbloccate.
	for face in PetState.all_faces():
		assert(PetState.has_face(save, str(face)), "faccia non sbloccata a legame pieno: %s" % str(face))

func _test_facce_bloccate_non_attive() -> void:
	var save := GameSaveManager.new()
	var initial := PetState.faces(save)
	assert(initial.size() == 5, "il Custode deve partire con 5 facce, trovate %d" % initial.size())
	# Le espressioni del ciclo (esito, traguardo, carezza) sono disponibili subito:
	# tenerle chiuse renderebbe il compagno piatto proprio nei minuti in cui il
	# bambino gli si affeziona.
	for face in ["sereno", "orgoglioso", "incoraggiante", "festa", "beato"]:
		assert(initial.has(face), "faccia di base non disponibile all'inizio: %s" % face)
	# Le extra non devono essere già lì.
	for step in PetState.BOND_UNLOCKS:
		assert(
			not initial.has(str(step["face"])),
			"faccia da legame già sbloccata all'inizio: %s" % str(step["face"]))
	# E si sbloccano nell'ordine dichiarato, mai prima della soglia.
	var previous_threshold := 0.0
	for step in PetState.BOND_UNLOCKS:
		var threshold := float(step["bond"])
		assert(threshold > previous_threshold, "soglie di legame non crescenti")
		previous_threshold = threshold
		var probe := GameSaveManager.new()
		PetState.add_bond(probe, threshold - 0.01)
		assert(
			not PetState.has_face(probe, str(step["face"])),
			"faccia %s sbloccata sotto la sua soglia" % str(step["face"]))
		PetState.add_bond(probe, 0.01)
		assert(
			PetState.has_face(probe, str(step["face"])),
			"faccia %s non sbloccata alla sua soglia" % str(step["face"]))

func _test_consegna_iniziale() -> void:
	var save := GameSaveManager.new()
	assert(not PetState.is_granted(save), "un profilo nuovo non deve già avere il Custode")
	assert(PetState.grant(save, 1), "la prima consegna deve riuscire")
	assert(PetState.is_granted(save), "dopo la consegna il Custode deve esserci")
	assert(not PetState.grant(save, 1), "la consegna non deve poter avvenire due volte")
	assert(PetState.needs_name(save), "appena consegnato il Custode non ha un nome")
	# Il nome si può rimandare e si può cambiare, ed è tagliato al limite.
	assert(PetState.set_pet_name(save, "   ") == "", "un nome di soli spazi resta vuoto")
	assert(PetState.needs_name(save), "un nome vuoto non conta come nome")
	var long_name := PetState.set_pet_name(save, "Briciolinabellissima")
	assert(
		long_name.length() <= PetState.MAX_NAME_LENGTH,
		"nome non tagliato al limite: %s" % long_name)
	assert(not PetState.needs_name(save), "dopo il nome non deve più chiederlo")
	# Nessun vantaggio di gioco: energia, frammenti e livello non si muovono.
	assert(save.energy() == 0, "il Custode non deve concedere energia")
	assert(save.fragments() == 0, "il Custode non deve concedere frammenti")
	assert(save.level() == 1, "il Custode non deve muovere il livello")
