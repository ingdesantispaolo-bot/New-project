extends SceneTree

## **Il duello delle voci è tarato, e ogni scambio si può vincere?**
## (17 agosto 2026)
##
## `verb_conjugation_audit` risponde di una cosa sola: che le voci siano giuste.
## Qui si controlla il **gioco** che ci sta sopra.
##
## Il controllo che nessun collaudo a mano può fare è sempre lo stesso, e qui
## morde più che nel duello delle cifre: **con le caselle che non esistono, tre
## rune giuste possono benissimo non bastare**. Dall'indicativo futuro semplice
## al condizionale passato non si arriva né cambiando prima il modo (il
## condizionale non ha il futuro) né cambiando prima il tempo (l'indicativo non
## ha il «passato»). Uno scambio così lascerebbe un bambino a guardare la carica
## che scende senza capire perché — e non lo si scopre giocando, perché capita
## una volta ogni tanto.
##
## In più, una regola che vale solo per la grammatica: **il bersaglio non può
## mentire.** Dai mondi 10 in su il sigillo mostra una voce vera di un altro
## verbo, e quella voce deve individuare **una casella sola**. «cantaste» è
## passato remoto e congiuntivo imperfetto insieme: mostrarla e poi dire «no,
## intendevo l'altra» sarebbe la bugia peggiore che un gioco di grammatica possa
## raccontare a un bambino che ha ragione.

const OK := "VERB DUEL audit VERDE"
static var GRADI: int = WorldLight.SOGLIE.size()
const TIER_MAX := 8
const CAMPIONI := 200

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	_le_fasce_coprono_i_ventiquattro_mondi()
	_nessuna_combinazione_impossibile()
	_il_progresso_aiuta_sempre()
	_il_colpo_e_onesto()
	_ogni_scambio_si_puo_vincere()
	_le_due_materie_pesano_uguale()
	if errori.is_empty():
		print(OK)
	else:
		printerr("VERB DUEL audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## La difficoltà non può mai scendere salendo di mondo, e la campagna deve
## sentirsi crescere: dal solo indicativo con tre tempi a tutti e tre i modi con
## nove, dalla catena da due a quella da tre, dall'etichetta scritta alla voce da
## riconoscere.
func _le_fasce_coprono_i_ventiquattro_mondi() -> void:
	var passi_prima := 0
	var caselle_prima := 0
	for mondo in range(1, 25):
		var fascia := VerbDuel.fascia_per_mondo(mondo)
		_controlla(not fascia.is_empty(), "mondo %d senza fascia" % mondo)
		var caselle := VerbDuel.caselle_di(fascia)
		var passi := int(fascia.get("passi", 0))
		_controlla(passi >= passi_prima,
			"mondo %d: la catena si accorcia (%d dopo %d)" % [mondo, passi, passi_prima])
		_controlla(caselle.size() >= caselle_prima,
			"mondo %d: le caselle diminuiscono (%d dopo %d)" % [mondo, caselle.size(), caselle_prima])
		# Con `passi` assi da cambiare servono almeno `passi` rune giuste più due
		# esche, o la mano è una risposta con dei riempitivi intorno.
		_controlla(int(fascia.get("mano", 0)) >= passi + 2,
			"mondo %d: la mano non tiene la strada giusta più due esche" % mondo)
		# E servono abbastanza caselle da poterne scegliere due che differiscono
		# di `passi` assi: con un modo solo non si può chiedere di cambiarne tre.
		var modi := Array(fascia.get("modi", [])).size()
		_controlla(passi <= 2 + (1 if modi > 1 else 0),
			"mondo %d: si chiedono %d assi ma i modi disponibili sono %d" % [mondo, passi, modi])
		_controlla(VerbDuel.verbi_di(fascia).size() >= 4,
			"mondo %d: meno di quattro verbi in campo, si ripetono subito" % mondo)
		passi_prima = passi
		caselle_prima = caselle.size()
	var prima := VerbDuel.fascia_per_mondo(1)
	var ultima := VerbDuel.fascia_per_mondo(24)
	_controlla(int(ultima["passi"]) > int(prima["passi"]),
		"la catena finale non è più lunga di quella iniziale")
	_controlla(VerbDuel.caselle_di(ultima).size() >= VerbDuel.caselle_di(prima).size() * 3,
		"le caselle finali non sono sensibilmente più delle iniziali")
	_controlla(str(prima["bersaglio"]) == "descrizione" and str(ultima["bersaglio"]) == "campione",
		"la progressione del bersaglio non va dalla descrizione alla voce da riconoscere")

## **I due bordi.** Nessuna combinazione di mondo e gradi deve produrre un duello
## che non si può vincere, né uno che si vince senza guardare.
func _nessuna_combinazione_impossibile() -> void:
	for mondo in [1, 7, 12, 17, 24]:
		for tier in range(1, TIER_MAX + 1):
			for grado in range(GRADI):
				var regole := VerbDuel.regole(mondo, tier, grado)
				var passi := int(regole["passi"])
				var per_colpo := float(regole["secondi"]) / float(passi)
				# Un colpo qui è «leggi il sigillo, capisci quale asse muovere,
				# trova la runa»: sotto i due secondi non si sta più misurando
				# la grammatica.
				_controlla(per_colpo >= 2.0,
					"mondo %d T%d grado %d: %.1fs per colpo, è una gara di dita" %
					[mondo, tier, grado, per_colpo])
				_controlla(per_colpo <= 8.5,
					"mondo %d T%d grado %d: %.1fs per colpo, il guardiano non è un pericolo" %
					[mondo, tier, grado, per_colpo])
				_controlla(int(regole["sigilli"]) >= 2 and int(regole["sigilli"]) <= 4,
					"mondo %d T%d: %d sigilli" % [mondo, tier, int(regole["sigilli"])])
				_controlla(int(regole["tenuta"]) >= 2,
					"grado %d: meno di due colpi incassabili" % grado)
				_controlla(int(regole["colpi"]) > passi,
					"mondo %d: nessun colpo di riserva, un asse sbagliato chiuderebbe lo scambio" % mondo)
	for mondo in range(1, 25):
		_controlla(float(VerbDuel.regole(mondo, 4, 2, true)["secondi"])
				> float(VerbDuel.regole(mondo, 4, 2, false)["secondi"]),
			"mondo %d: il movimento ridotto non allunga la carica" % mondo)

func _il_progresso_aiuta_sempre() -> void:
	for mondo in [1, 12, 24]:
		for tier in range(1, TIER_MAX + 1):
			for grado in range(1, GRADI):
				var ora := VerbDuel.regole(mondo, tier, grado)
				var prima := VerbDuel.regole(mondo, tier, grado - 1)
				_controlla(float(ora["secondi"]) >= float(prima["secondi"]),
					"mondo %d T%d: salendo al grado %d la carica si accorcia" % [mondo, tier, grado])
				_controlla(int(ora["tenuta"]) >= int(prima["tenuta"]),
					"grado %d: si incassano meno colpi del grado precedente" % grado)

## Il giudizio del colpo: quello che la runa dice è quello che la runa fa, e
## quello che non si può fare non si può fare **perché lo dice la grammatica**.
func _il_colpo_e_onesto() -> void:
	var ind_pres := {"modo": "indicativo", "tempo": "presente", "persona": 0}
	var esito := VerbDuel.applica(ind_pres, VerbDuel.runa("tempo", "imperfetto"))
	_controlla(str(esito.get("tempo", "")) == "imperfetto" and str(esito.get("modo", "")) == "indicativo",
		"la runa del tempo non sposta il tempo")
	_controlla(int(VerbDuel.applica(ind_pres, VerbDuel.runa("persona", 4)).get("persona", -1)) == 4,
		"la runa della persona non sposta la persona")
	# La casella che non esiste: il condizionale non ha l'imperfetto.
	var ind_imp := {"modo": "indicativo", "tempo": "imperfetto", "persona": 0}
	_controlla(VerbDuel.applica(ind_imp, VerbDuel.runa("modo", "condizionale")).is_empty(),
		"si arriva al «condizionale imperfetto», che non esiste")
	# E il congiuntivo non ha il passato remoto.
	var cong := {"modo": "congiuntivo", "tempo": "presente", "persona": 0}
	_controlla(VerbDuel.applica(cong, VerbDuel.runa("tempo", "passato remoto")).is_empty(),
		"si arriva al «congiuntivo passato remoto», che non esiste")
	# La runa che non sposta niente non è un colpo.
	_controlla(VerbDuel.applica(ind_pres, VerbDuel.runa("tempo", "presente")).is_empty(),
		"una runa che lascia la casella dov'è viene contata come colpo")
	_controlla(VerbDuel.applica(ind_pres, VerbDuel.runa("persona", 0)).is_empty(),
		"una runa della persona già giusta viene contata come colpo")
	# Il cercatore: una strada che esiste si trova nell'ordine che funziona, e
	# una che non esiste non si inventa.
	var mano: Array = [
		VerbDuel.runa("modo", "congiuntivo"),
		VerbDuel.runa("tempo", "imperfetto"),
		VerbDuel.runa("persona", 4),
	]
	var da := {"modo": "indicativo", "tempo": "presente", "persona": 0}
	var a := {"modo": "congiuntivo", "tempo": "imperfetto", "persona": 4}
	_controlla(VerbDuel.percorso_minimo(da, a, mano, 4).size() == 3,
		"la strada verso il congiuntivo imperfetto voi non viene trovata")
	# **L'ordine conta, e qui si vede**: dal futuro semplice, cambiare prima il
	# modo è impossibile — il condizionale non ha il futuro. Con le sole due rune
	# la strada non c'è, e il cercatore non deve inventarla.
	var stretta: Array = [
		VerbDuel.runa("modo", "condizionale"), VerbDuel.runa("tempo", "passato"),
	]
	var futuro := {"modo": "indicativo", "tempo": "futuro semplice", "persona": 0}
	var cond_pass := {"modo": "condizionale", "tempo": "passato", "persona": 0}
	_controlla(VerbDuel.percorso_minimo(futuro, cond_pass, stretta, 4).is_empty(),
		"viene trovata una strada che passa da caselle inesistenti")
	# Con la runa di passaggio, invece, la strada c'è ed è lunga tre.
	var larga: Array = stretta.duplicate()
	larga.append(VerbDuel.runa("tempo", "presente"))
	_controlla(VerbDuel.percorso_minimo(futuro, cond_pass, larga, 4).size() == 3,
		"con la runa di passaggio la strada verso il condizionale passato non si trova")

## **Il controllo che nessuno può fare a mano.** Migliaia di scambi generati e
## risolti davvero, fascia per fascia.
func _ogni_scambio_si_puo_vincere() -> void:
	var rng := RandomNumberGenerator.new()
	for mondo in [1, 5, 10, 15, 20, 24]:
		var regole := VerbDuel.regole(mondo, 4, 2)
		var passi := int(regole["passi"])
		var colpi := int(regole["colpi"])
		var mano := int(regole["mano"])
		var senza_strada := 0
		var lunghezza_sbagliata := 0
		var mani_sbagliate := 0
		var spente_in_partenza := 0
		var bersagli_ambigui := 0
		var campione_uguale := 0
		var sigilli_abbinabili := 0
		var voci_vuote := 0
		for campione in range(CAMPIONI):
			rng.seed = hash("voci-%d-%d" % [mondo, campione])
			var scambio := VerbDuel.genera_scambio(rng, regole)
			var rune: Array = scambio.get("rune", [])
			var da: Dictionary = scambio.get("partenza", {})
			var a: Dictionary = scambio.get("bersaglio", {})
			if rune.size() != mano:
				mani_sbagliate += 1
			# Le rune non si ripetono: due pietre identiche sono una scelta finta.
			var viste: Dictionary = {}
			for runa in rune:
				var chiave := "%s|%s" % [str(runa.get("asse", "")), str(runa.get("valore", ""))]
				if viste.has(chiave):
					mani_sbagliate += 1
					break
				viste[chiave] = true
			var percorso := VerbDuel.percorso_minimo(da, a, rune, colpi)
			if percorso.is_empty():
				senza_strada += 1
			elif percorso.size() != passi:
				lunghezza_sbagliata += 1
			var vive := 0
			for runa in rune:
				if VerbDuel.applicabile(da, runa):
					vive += 1
			if vive < 2:
				spente_in_partenza += 1
			# La voce di Eli non può mai essere vuota lungo la strada.
			if VerbDuel.voce_di(scambio, da).is_empty() or VerbDuel.voce_di(scambio, a).is_empty():
				voci_vuote += 1
			# **Il bersaglio non mente, e non si abbina.**
			#
			# La seconda meta' nasce dalla misura di `voci_valore_probe`
			# (21 agosto 2026): un finto giocatore che non sapeva niente di verbi,
			# e leggeva soltanto le parole del sigillo per toccare le rune con lo
			# stesso testo, vinceva il **99% degli scambi dei primi nove mondi**.
			# Il sigillo diceva «INDICATIVO IMPERFETTO · voi» e una runa diceva
			# «imperfetto»: due parole uguali da accostare, e il duello misurava la
			# vista invece della grammatica.
			#
			# Da qui in avanti **nessuna parola del sigillo puo' comparire su una
			# runa**. E' la riga che tiene in piedi il valore didattico di questo
			# minigioco: se un giorno tornasse comodo scrivere il nome del tempo
			# sul cartiglio, il duello tornerebbe un gioco di abbinamento senza che
			# nessuno se ne accorga rileggendo il codice.
			var sigillo: Dictionary = scambio.get("sigillo", {})
			# Il confronto e' per PAROLA INTERA e non per sottostringa: «studiare»
			# contiene «tu», e un giocatore che accosta parole non accosta pezzi di
			# parola. Cercare la sottostringa rendeva rosso un sigillo onesto.
			var parole_sigillo := _parole(str(sigillo.get("testo", ""))
				+ " " + str(sigillo.get("sotto", "")))
			for runa in rune:
				for parola in _parole(str(runa.get("testo", ""))):
					if parole_sigillo.has(parola):
						sigilli_abbinabili += 1
					if sigilli_abbinabili > 0:
						break
				if sigilli_abbinabili > 0:
					break
			if str(sigillo.get("tipo", "")) == "campione":
				var campione_verbo := VerbConjugator.verbo_per_infinito(str(sigillo.get("campione", "")))
				if campione_verbo.is_empty():
					bersagli_ambigui += 1
				elif VerbConjugator.caselle_che_danno(campione_verbo, str(sigillo["testo"])) != 1:
					bersagli_ambigui += 1
				if str(sigillo.get("campione", "")) == str(scambio.get("infinito", "")):
					campione_uguale += 1
		_controlla(senza_strada == 0,
			"mondo %d: %d scambi su %d non si possono vincere" % [mondo, senza_strada, CAMPIONI])
		_controlla(lunghezza_sbagliata == 0,
			"mondo %d: %d scambi non sono lunghi i %d passi promessi" % [mondo, lunghezza_sbagliata, passi])
		_controlla(mani_sbagliate == 0,
			"mondo %d: %d mani con il numero sbagliato di rune o con doppioni" % [mondo, mani_sbagliate])
		_controlla(spente_in_partenza == 0,
			"mondo %d: %d scambi si aprono con meno di due rune giocabili" % [mondo, spente_in_partenza])
		_controlla(voci_vuote == 0,
			"mondo %d: %d scambi con una voce vuota" % [mondo, voci_vuote])
		_controlla(bersagli_ambigui == 0,
			"mondo %d: %d sigilli mostrano una voce che vale per più di una casella" % [mondo, bersagli_ambigui])
		_controlla(campione_uguale == 0,
			"mondo %d: %d sigilli usano lo stesso verbo di Eli, cioè la risposta in chiaro" % [mondo, campione_uguale])
		_controlla(sigilli_abbinabili == 0,
			"mondo %d: %d sigilli contengono la parola di una runa — si vince abbinando, senza sapere niente di verbi" % [
				mondo, sigilli_abbinabili])

## Le parole di una stringa, ridotte a lettere minuscole e senza punteggiatura.
## «lui/lei» sono due parole, e vanno confrontate come tali.
func _parole(testo: String) -> Dictionary:
	var fuori: Dictionary = {}
	var pulito := testo.to_lower()
	for segno in ["/", ",", ".", ";", ":", "·", "«", "»", "'", "(", ")"]:
		pulito = pulito.replace(segno, " ")
	for parola in pulito.split(" ", false):
		if not str(parola).strip_edges().is_empty():
			fuori[str(parola).strip_edges()] = true
	return fuori

## **Nessuna delle due materie può essere la strada conveniente.** Sigilli,
## tenuta, colpi di riserva e premio devono coincidere: se una fosse più
## generosa, un bambino imparerebbe a cercare i guardiani di quella invece di
## quelli che ha voglia di affrontare — e la materia diventerebbe una tassa
## invece che una scelta.
func _le_due_materie_pesano_uguale() -> void:
	for mondo in [1, 7, 12, 17, 24]:
		for tier in [1, 4, 8]:
			for grado in [0, 4, 8]:
				var voci := VerbDuel.regole(mondo, tier, grado)
				var cifre := GuardianDuel.regole(mondo, tier, grado)
				_controlla(int(voci["sigilli"]) == int(cifre["sigilli"]),
					"mondo %d T%d: sigilli diversi fra le due materie" % [mondo, tier])
				_controlla(int(voci["tenuta"]) == int(cifre["tenuta"]),
					"grado %d: tenuta diversa fra le due materie" % grado)
				_controlla(int(voci["colpi"]) - int(voci["passi"])
						== int(cifre["colpi"]) - int(cifre["passi"]),
					"i colpi di riserva non coincidono fra le due materie")
	# E la materia di un guardiano è stabile: lo stesso identificativo dà sempre
	# la stessa risposta, o tornare a riprovare sarebbe una lotteria.
	for prova in range(50):
		var id := "guardia-tesoro-%d" % prova
		_controlla(DuelRules.materia(id) == DuelRules.materia(id),
			"la materia di «%s» cambia fra una domanda e l'altra" % id)
	# Le due materie devono comparire **entrambe**: un sorteggio che pesca sempre
	# la stessa faccia non è un sorteggio.
	var conteggio := {DuelRules.CIFRE: 0, DuelRules.VOCI: 0}
	for prova in range(400):
		conteggio[DuelRules.materia("guardia-%d" % prova)] += 1
	_controlla(int(conteggio[DuelRules.CIFRE]) > 100 and int(conteggio[DuelRules.VOCI]) > 100,
		"le due materie non si alternano: %d conti contro %d voci su 400" % [
			int(conteggio[DuelRules.CIFRE]), int(conteggio[DuelRules.VOCI])])
