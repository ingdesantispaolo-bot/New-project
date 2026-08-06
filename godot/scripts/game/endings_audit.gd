extends SceneTree

## **Il Lascito e i cinque epiloghi.** (6 agosto 2026)
##
## Due cose vanno tenute ferme, e sono entrambe di progetto, non di codice.
##
## **1 · Nessun finale si compra.** Se frammenti, cosmetici o ore giocate
## pesassero nel punteggio, un bambino potrebbe comprarsi un epilogo migliore —
## e un gioco che si studia non può vendere il proprio finale. Qui si verifica
## che spendere e accumulare non muovano il Lascito di un centesimo.
##
## **2 · Nessun finale è una punizione.** Cambiano per *che cosa* hai fatto, non
## per *quanto vali*. Nessuna riga può nominare ciò che il giocatore NON ha
## fatto: sarebbe la cosa peggiore che questo gioco possa dire a un bambino di
## undici anni dopo venti ore, ed è lo stesso guard-rail del Cuore dei Primi.
##
## In più: il difetto storico degli oggetti. Quattro «upgrade» promettevano
## meccaniche inesistenti nel loop Godot — aiuti, impulsi, vite — ereditate dal
## prototipo Phaser. Costavano fino a 1600 frammenti e non facevano niente.

func _init() -> void:
	_prova_dimensioni()
	_prova_non_si_compra()
	_prova_non_scende()
	_prova_epiloghi()
	_prova_curriculum()
	_prova_oggetti_onesti()
	print("ENDINGS audit OK — %d epiloghi, nessuno comprabile, nessuno punitivo" % EndingsCatalog.tutti().size())
	quit(0)

func _nuovo() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _prova_dimensioni() -> void:
	var somma := 0.0
	for peso in LegacyScore.PESI.values():
		somma += float(peso)
	assert(is_equal_approx(somma, 1.0), "i pesi del Lascito non sommano a 1: %.3f" % somma)

	# Un salvataggio nuovo non vale ESATTAMENTE zero, e ha ragione: il mondo 1 è
	# già aperto, quindi la ROTTA parte da 1/24. Si pretende che sia trascurabile,
	# non nullo: pretendere lo zero sarebbe pretendere che il gioco non sia
	# ancora cominciato.
	var vuoto := LegacyScore.valuta(_nuovo())
	assert(float(vuoto["totale"]) < 0.02,
		"un salvataggio nuovo parte già alto: %.3f" % float(vuoto["totale"]))
	# **Chi non ha fatto niente riceve l'epilogo piu' magro**, e dal 6 agosto
	# (seconda passata) e' voluto: prima riceveva ROTTA APERTA come tutti, quindi
	# il finale non dipendeva da quanto avevi imparato e il gioco non chiedeva
	# niente. IL SILENZIO TIENE non insulta nessuno — dice che i sistemi sono
	# spenti e che il Tredicesimo e' tornato alla diga.
	assert(str(vuoto["finale"]) == "silenzio",
		"chi non ha ancora fatto niente riceve gia' un epilogo pieno")

	# Il nucleo pesa doppio: è la direzione presa il 6 agosto, e deve vedersi.
	var solo_nucleo := _nuovo()
	var solo_satelliti := _nuovo()
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject_data)
		if ApparatusConfig.is_core(s):
			solo_nucleo.data["mastery"][s] = 1.0
		else:
			solo_satelliti.data["mastery"][s] = 1.0
	var per_materia_nucleo := LegacyScore.padronanza(solo_nucleo) / 3.0
	var per_materia_altre := LegacyScore.padronanza(solo_satelliti) / 9.0
	assert(per_materia_nucleo > per_materia_altre * 1.5,
		"una materia del nucleo non pesa più di una satellite nel Lascito")

	# Tutto al massimo: il totale arriva a 1 e apre l'epilogo lungo.
	var pieno := _pieno()
	assert(float(LegacyScore.valuta(pieno)["totale"]) > 0.95,
		"con tutto al massimo il Lascito non arriva a uno")
	assert(str(LegacyScore.valuta(pieno)["finale"]) == "fondo",
		"con tutto al massimo non si apre l'epilogo lungo")

func _pieno() -> GameSaveManager:
	var save := _nuovo()
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		save.data["mastery"][str(subject_data)] = 1.0
	var codex: Dictionary = {}
	for i in range(LegacyScore.META_CONSOLIDATI):
		codex["materia:arg%d" % i] = KnowledgeCodex.STATE_CONSOLIDATED
	save.data["codex"] = codex
	var mondi: Dictionary = {}
	var per_mondo := int(ceil(float(LegacyScore.META_INCONTRI) / 24.0))
	for w in range(1, 25):
		var ids: Array = []
		for k in range(per_mondo):
			ids.append("evt-%d-%d" % [w, k])
		mondi[str(w)] = {"completedEncounterIds": ids}
	save.data["worldProgress"] = mondi
	var aperti: Array = []
	for w in range(1, 25):
		aperti.append(w)
	save.data["worlds"] = {"unlocked": aperti, "current": 24}
	var visti: Array = []
	for b in range(LegacyScore.META_BEAT):
		visti.append("beat-%d" % b)
	save.data["narrative"] = {"seen": visti, "beats": {}}
	return save

## Il controllo che vale più di tutti: **il finale non si compra**.
func _prova_non_si_compra() -> void:
	var save := _nuovo()
	save.data["mastery"]["italiano"] = 0.5
	var prima := float(LegacyScore.valuta(save)["totale"])

	# Ricchezza, acquisti, ore: niente di tutto questo deve spostare il Lascito.
	save.data["fragments"] = 999999
	save.data["energy"] = 99999
	save.data["cosmetics"] = {
		"unlocked": RewardCatalog.CATALOG.map(func(c): return str((c as Dictionary)["id"])),
		"equipped": {"avatar": "avatar-astral", "accessory": "accessory-halo"},
		"inventory": ["nora-prismatic-core", "nora-shield", "nora-lens", "nora-reserve"],
	}
	save.data["daily"] = {"date": "2026-08-06", "days": 400, "missions": 9999, "streak": 0, "recent": []}
	save.data["progressReport"] = {"events": []}
	for i in range(500):
		Array(save.data["progressReport"]["events"]).append(
			{"level": 1, "subject": "italiano", "mastery": 0.5, "missions": 1, "seconds": 60.0})

	var dopo := float(LegacyScore.valuta(save)["totale"])
	assert(is_equal_approx(prima, dopo),
		"il Lascito è cambiato comprando e giocando a vuoto: %.4f → %.4f. Il finale si può comprare." % [prima, dopo])

## Nessuna dimensione scende mai da sola: stesso guard-rail del diario.
func _prova_non_scende() -> void:
	var save := _nuovo()
	var precedente := 0.0
	for passo in range(1, 13):
		save.data["mastery"][str(ApparatusConfig.SUBJECT_CYCLE[passo - 1])] = 0.8
		var ora := float(LegacyScore.valuta(save)["totale"])
		assert(ora >= precedente, "il Lascito è sceso avanzando: %.4f → %.4f" % [precedente, ora])
		precedente = ora

func _prova_epiloghi() -> void:
	# **Che cosa resta vietato dopo la svolta severa.** Non le frasi negative —
	# quelle adesso servono — ma il **giudizio sulla persona**. La differenza e'
	# tutta qui: «tre sistemi restano spenti» parla del mondo ed e' un motivo per
	# tornare; «non sei stato all'altezza» parla del bambino e chiude il gioco.
	# Restano fuori anche pieta' e consolazione, che sono l'altra faccia del
	# buonismo: un epilogo severo non compatisce.
	var proibite := [
		"non sei stato", "non sei stata", "non sei all'altezza", "non vali",
		"hai fallito", "sei incapace", "sei pigr", "deludente", "delusione",
		"peccato", "purtroppo", "mi dispiace per te",
	]
	for id_data in EndingsCatalog.tutti():
		var id := str(id_data)
		var e := EndingsCatalog.per_id(id)
		assert(not str(e.get("titolo", "")).strip_edges().is_empty(), "%s non ha titolo" % id)
		assert(not str(e.get("sottotitolo", "")).strip_edges().is_empty(), "%s non ha sottotitolo" % id)
		var righe: Array = e.get("righe", [])
		assert(righe.size() >= 4, "%s ha solo %d righe: un epilogo è una scena, non un avviso" % [id, righe.size()])
		for i in range(righe.size()):
			var riga := str(righe[i])
			# L'ULTIMA riga può essere corta, e spesso deve esserlo: una chiusa
			# è un colpo secco. «Sorella. Andiamo a prenderla» sta in trentacinque
			# caratteri ed è la riga migliore dell'epilogo lungo — una regola che
			# la vietasse starebbe difendendo la lunghezza invece della scrittura.
			var minimo := 20 if i == righe.size() - 1 else 40
			assert(riga.length() > minimo, "riga troppo scarna in %s: «%s»" % [id, riga])
			var basso := riga.to_lower()
			for frase_data in proibite:
				assert(not basso.contains(str(frase_data)),
					"l'epilogo «%s» nomina ciò che il giocatore NON ha fatto: «%s»" % [id, riga])
			# Guard-rail della trama: nessuno è morto.
			for morte in ["è morta", "è morto", "sono morti", "sono morte"]:
				assert(not basso.contains(str(morte)),
					"un epilogo dichiara una morte, contro il guard-rail della trama: «%s»" % riga)

	# L'epilogo lungo è il più lungo: è ciò che lo distingue, non un premio.
	var fondo: Array = EndingsCatalog.per_id("fondo")["righe"]
	for id_data in EndingsCatalog.tutti():
		if str(id_data) == "fondo":
			continue
		assert(fondo.size() >= Array(EndingsCatalog.per_id(str(id_data))["righe"]).size(),
			"l'epilogo lungo non è il più lungo: %s ha più righe" % str(id_data))

	# Un identificativo sconosciuto non deve lasciare il gioco senza finale.
	assert(str(EndingsCatalog.per_id("inesistente")["id"]) == "rotta",
		"un epilogo sconosciuto non ricade su quello di base")

	# Ogni epilogo dev'essere raggiungibile: uno scritto e mai mostrato è
	# contenuto morto, ed è il difetto che questo progetto trova più spesso.
	var raggiunti: Dictionary = {}
	# I quattro epiloghi "per dominante" vivono nella fascia di mezzo: sotto
	# SOGLIA_COMPLETO comanda la fascia, non la specializzazione. Costruirli a
	# totale basso — come faceva la prima versione di questa prova — li rendeva
	# irraggiungibili senza che nessuno se ne accorgesse.
	for dominante in ["ritenzione", "mondo", "indagine", "padronanza"]:
		var d := {"padronanza": 0.5, "ritenzione": 0.5, "mondo": 0.5, "rotta": 0.5, "indagine": 0.5, "totale": 0.5}
		d[dominante] = 0.95
		raggiunti[LegacyScore.finale_di(d)] = true
	var equilibrato := {"padronanza": 0.5, "ritenzione": 0.5, "mondo": 0.5, "rotta": 0.5, "indagine": 0.5, "totale": 0.5}
	raggiunti[LegacyScore.finale_di(equilibrato)] = true
	raggiunti[LegacyScore.finale_di({"totale": 0.0})] = true
	raggiunti[LegacyScore.finale_di({"totale": 0.30})] = true
	raggiunti[LegacyScore.finale_di({"totale": 1.0})] = true

	# Le fasce nell'ordine giusto: un profilo migliore non puo' ricevere un
	# epilogo piu' magro di uno peggiore.
	assert(str(LegacyScore.finale_di({"totale": 0.10})) == "silenzio", "fascia bassa sbagliata")
	assert(str(LegacyScore.finale_di({"totale": 0.30})) == "incompleto", "fascia media-bassa sbagliata")
	assert(str(LegacyScore.finale_di({"totale": 0.95})) == "fondo", "fascia alta sbagliata")
	for id_data in EndingsCatalog.tutti():
		assert(raggiunti.has(str(id_data)),
			"l'epilogo «%s» non è raggiungibile da nessun profilo di gioco" % str(id_data))

## La coda di curriculum: l'epilogo deve nominare le materie di QUEL giocatore.
##
## E' la parte che lo rende suo invece che generico. Deve nominare sempre anche
## la materia forte: un bilancio che dice solo la mancanza non e' severita', e'
## una nota sul registro.
func _prova_curriculum() -> void:
	var save := _nuovo()
	# Tutte le materie a meta', poi una alta e una bassa: senza impostarle tutte
	# le altre varrebbero zero e la "piu' bassa" sarebbe una qualsiasi di quelle,
	# non quella scelta. E' un errore da fixture, ed e' lo stesso che rende
	# inutili molte prove: preparare uno stato che non e' quello che si vuole
	# misurare.
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		save.data["mastery"][str(subject_data)] = 0.5
	save.data["mastery"]["matematica"] = 0.9
	save.data["mastery"]["geografia"] = 0.05
	var e := EndingsCatalog.per_save(save)
	var coda := str(Array(e["righe"])[Array(e["righe"]).size() - 1])
	assert(coda.to_lower().contains("matematica"),
		"la coda non nomina la materia che ha portato il giocatore fin qui: «%s»" % coda)
	assert(coda.to_lower().contains("geografia"),
		"la coda non nomina la materia rimasta indietro: «%s»" % coda)
	assert(Dictionary(e["curriculum"]).has("inLinea"), "la coda non riporta i sistemi in linea")

	# Con tutto in linea la coda cambia tono: non si inventa una mancanza.
	var pieno := _pieno()
	var coda_piena := str(Array(EndingsCatalog.per_save(pieno)["righe"]).pop_back())
	assert(coda_piena.to_lower().contains("dodici sistemi"),
		"con tutto acceso la coda non lo dice: «%s»" % coda_piena)

## Nessun oggetto può promettere ciò che il gioco non fa.
func _prova_oggetti_onesti() -> void:
	# Le meccaniche che NON esistono in questo loop. Quattro «upgrade» le
	# promettevano, ereditate dal prototipo Phaser: costavano fino a 1600
	# frammenti e non facevano niente.
	# Frasi INTERE, non frammenti: il primo tentativo cercava «aiut» e pescava la
	# parola «aiuto» dentro una provenienza legittima — «ha smesso di credere che
	# chiedere aiuto sia pigrizia», che è il senso di quel personaggio. Un
	# controllo che vieta una parola vieta anche le frasi buone che la contengono.
	var inesistenti := [
		"non consuma aiuti", "recuperare due vite", "recupera due vite",
		"gli impulsi", "carica nora", "energia prismatica permanente",
	]
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var testo := ("%s %s" % [str(voce.get("description", "")), str(voce.get("origine", ""))]).to_lower()
		for promessa_data in inesistenti:
			assert(not testo.contains(str(promessa_data)),
				"«%s» promette «%s», che in questo gioco non esiste" % [
					str(voce.get("name", voce.get("id", ""))), str(promessa_data)])
		# La provenienza: è l'unico valore che un cosmetico può avere, visto che
		# per contratto didattico non dà vantaggi nelle prove.
		assert(str(voce.get("origine", "")).strip_edges().length() > 25,
			"«%s» non ha una provenienza nella storia" % str(voce.get("id", "")))
