extends SceneTree

## **La serie moltiplica l'energia e non tocca l'apprendimento.** (13 agosto 2026)
##
## Questo audit esiste per una ragione sola, ed è la decisione vincolante 15: una
## serie di risposte giuste è la prima funzione del gioco che **premia la
## prestazione**, e in un gioco che si studia è esattamente il punto in cui si
## comincia a vendere l'apprendimento senza accorgersene. Basta che un giorno
## qualcuno faccia dipendere la padronanza dall'energia guadagnata — sembra
## innocuo, sono due numeri che salgono insieme — e da quel momento un bambino
## veloce sale di livello prima di uno lento a parità di ciò che sa.
##
## Le quattro cose che verifica:
##
## 1. **L'aritmetica**: monotona, con un tetto, e il tetto è raggiungibile
##    giocando una sessione vera.
## 2. **Il tetto di una sessione**: nessuna prova, per quanto lunga e perfetta,
##    paga più del doppio della tariffa piatta.
## 3. **La padronanza non guarda l'energia**: due sessioni con gli stessi esiti e
##    con energie diversissime lasciano la stessa padronanza. È la prova
##    comportamentale, non una lettura del codice.
## 4. **La serie vive dentro la prova**: si spezza sull'errore e riparte da capo
##    alla prova successiva.

const PLAYER := preload("res://scripts/game/exercise_player.gd")

## Quanto paga una risposta giusta nelle sessioni vere (`ContentManager`): dieci
## nelle missioni, dodici negli esami. Se un giorno cambiano, questo audit deve
## continuare a misurare i valori veri e non due costanti sue.
const BASI_VERE := [10, 12]

## La sessione ordinaria più lunga. Il tetto della serie deve stare dentro questo
## numero, o sarebbe una scala dipinta sul muro.
const NODI_SESSIONE_PIU_LUNGA := 5

var errori: Array = []
var player: Control

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_l_aritmetica()
	_il_tetto_di_una_sessione()
	_la_padronanza_non_guarda_l_energia()
	await _la_serie_vive_dentro_la_prova()
	if errori.is_empty():
		print("COMBO audit VERDE — serie con tetto, raggiungibile, e padronanza intatta")
	else:
		printerr("COMBO audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **L'aritmetica.** La prima risposta non è una serie; da lì il moltiplicatore
## sale di un passo per volta e si ferma. I cinque valori sono pinnati perché
## sono una decisione di design, non un dettaglio: se qualcuno li cambia deve
## passare da qui e dire perché.
func _l_aritmetica() -> void:
	var attesi := {1: 1.0, 2: 1.25, 3: 1.5, 4: 1.75, 5: 2.0}
	for serie in attesi:
		_controlla(is_equal_approx(Combo.moltiplicatore(serie), float(attesi[serie])),
			"serie %d: moltiplicatore %.3f invece di %.2f" % [
				serie, Combo.moltiplicatore(serie), float(attesi[serie])])
	_controlla(is_equal_approx(Combo.moltiplicatore(0), 1.0),
		"a serie zero il moltiplicatore non vale uno")
	# Monotonia e tetto, fino ben oltre qualunque sessione reale.
	for serie in range(1, 60):
		var qui := Combo.moltiplicatore(serie)
		_controlla(qui >= Combo.moltiplicatore(serie - 1),
			"serie %d: il moltiplicatore scende" % serie)
		_controlla(qui <= Combo.MASSIMO,
			"serie %d: il moltiplicatore supera il tetto (%.2f)" % [serie, qui])
		for voce in BASI_VERE:
			# Una risposta giusta non può mai pagare meno della tariffa piatta:
			# la serie aggiunge, non sostituisce.
			var base := int(voce)
			_controlla(Combo.energia(base, serie) >= base,
				"base %d, serie %d: la risposta paga %d, meno della tariffa piatta" % [
					base, serie, Combo.energia(base, serie)])
	# **Il tetto deve essere raggiungibile giocando.** Un massimo che nessuna
	# sessione può toccare è una promessa che non si mantiene mai.
	_controlla(Combo.serie_al_massimo() <= NODI_SESSIONE_PIU_LUNGA,
		"il tetto arriva alla %da giusta di fila, ma la sessione più lunga ne ha %d" % [
			Combo.serie_al_massimo(), NODI_SESSIONE_PIU_LUNGA])
	_controlla(is_equal_approx(Combo.moltiplicatore(Combo.serie_al_massimo()), Combo.MASSIMO),
		"alla serie dichiarata come massima il moltiplicatore non è al tetto")
	# La soglia di visibilità: un «×1» sempre a schermo non segnalerebbe niente.
	_controlla(not Combo.visibile(1) and Combo.visibile(Combo.SERIE_VISIBILE),
		"la soglia di visibilità della serie non è coerente con se stessa")
	_controlla(Combo.etichetta(3) == "×1,5" and Combo.etichetta(5) == "×2",
		"l'etichetta della serie non è leggibile: %s / %s" % [
			Combo.etichetta(3), Combo.etichetta(5)])

## **Il tetto di una sessione.** È il vincolo che tiene in piedi l'economia: il
## catalogo della bottega è tarato sul totale d'energia della campagna, e una
## serie che potesse triplicarlo lo svuoterebbe a metà strada.
func _il_tetto_di_una_sessione() -> void:
	for voce in BASI_VERE:
		var base := int(voce)
		for nodi in range(1, 21):
			var con_serie := 0
			for k in range(1, nodi + 1):
				con_serie += Combo.energia(base, k)
			var piatto := base * nodi
			_controlla(float(con_serie) <= float(piatto) * Combo.MASSIMO,
				"base %d, %d nodi perfetti: %d energia contro %d piatti, oltre il tetto" % [
					base, nodi, con_serie, piatto])
			_controlla(con_serie >= piatto,
				"base %d, %d nodi perfetti: la serie fa guadagnare meno della tariffa piatta" % [
					base, nodi])

## **La prova che conta.** Stessi esiti, energie diversissime: la padronanza deve
## essere identica al centesimo. Se un giorno qualcuno legge l'energia dentro il
## calcolo della padronanza, questo controllo diventa rosso lo stesso giorno.
func _la_padronanza_non_guarda_l_energia() -> void:
	var contenuti := ContentManager.new()
	for esito in [[3, 4, true], [1, 4, false], [4, 4, true]]:
		var corrette := int(esito[0])
		var totali := int(esito[1])
		var superata := bool(esito[2])
		var povera := GameSaveManager.new()
		var ricca := GameSaveManager.new()
		var pm_povera := ProgressionManager.new(povera, contenuti)
		var pm_ricca := ProgressionManager.new(ricca, contenuti)
		pm_povera.record_mission("matematica", corrette, totali, 0, superata)
		pm_ricca.record_mission("matematica", corrette, totali, 9999, superata)
		_controlla(
			is_equal_approx(povera.mastery_of("matematica"), ricca.mastery_of("matematica")),
			"missione %d/%d: la padronanza cambia con l'energia (%.4f contro %.4f)" % [
				corrette, totali,
				povera.mastery_of("matematica"), ricca.mastery_of("matematica")])
		_controlla(
			povera.missions_toward_gate("matematica") == ricca.missions_toward_gate("matematica"),
			"missione %d/%d: il conteggio del gate cambia con l'energia" % [corrette, totali])
		# Non vacuo: l'energia deve essere davvero arrivata, altrimenti il
		# controllo sopra proverebbe soltanto che il parametro viene ignorato.
		_controlla(ricca.energy() > povera.energy(),
			"missione %d/%d: l'energia non arriva affatto, il confronto non prova niente" % [
				corrette, totali])
		var p_pratica := GameSaveManager.new()
		var r_pratica := GameSaveManager.new()
		ProgressionManager.new(p_pratica, contenuti).record_practice("matematica", corrette, totali, 0)
		ProgressionManager.new(r_pratica, contenuti).record_practice("matematica", corrette, totali, 9999)
		_controlla(
			is_equal_approx(
				p_pratica.mastery_of("matematica"), r_pratica.mastery_of("matematica")),
			"pratica %d/%d: la padronanza cambia con l'energia" % [corrette, totali])

# --------------------------------------------------------------------- runtime

func _nodo(indice: int) -> Dictionary:
	return {
		"format": "multiple_choice",
		"prompt": "Domanda %d della prova di serie." % (indice + 1),
		"options": ["giusta", "sbagliata"],
		"answer": "giusta",
		"topic": "serie-audit",
		"difficulty": 1,
		"explanation": "La risposta giusta è la prima opzione.",
	}

func _sessione(nodi: int, base: int) -> Dictionary:
	var elenco: Array = []
	for i in range(nodi):
		elenco.append(_nodo(i))
	return {
		"sessionId": "combo-audit-%d" % nodi,
		"kind": "mission",
		"subject": "matematica",
		"nodes": elenco,
		"shields": 3,
		"pace": "reasoning",
		"timed": false,
		# `onComplete` vuoto: qui si misura la serie, e un premio di fine prova
		# renderebbe il conto illeggibile.
		"rewards": {"energyPerCorrect": base, "onComplete": {}},
	}

func _rispondi(giusta: bool) -> void:
	player.call("_answer", "giusta" if giusta else "sbagliata")
	await process_frame

func _avanza() -> void:
	player.call("_advance")
	await process_frame

## **La serie vive dentro la prova.** Tre cose in un giro solo: paga davvero
## quello che promette, si spezza sull'errore, e riparte da capo alla prova dopo.
func _la_serie_vive_dentro_la_prova() -> void:
	player = PLAYER.new()
	root.add_child(player)
	var esiti: Array = []
	player.session_finished.connect(func(res): esiti.append(res))

	# --- Prova perfetta: cinque giuste di fila, la serie arriva al tetto.
	var base := 10
	player.start_session(_sessione(5, base))
	await process_frame
	var atteso := 0
	for k in range(1, 6):
		atteso += Combo.energia(base, k)
		await _rispondi(true)
		if k == Combo.SERIE_VISIBILE:
			var badge := player.find_child("ComboBadge", true, false) as Label
			_controlla(badge != null and badge.visible and Combo.etichetta(k) in badge.text,
				"alla %da giusta di fila la serie non compare nel badge" % k)
		await _avanza()
	_controlla(esiti.size() == 1, "la prova perfetta non si è chiusa")
	if esiti.size() == 1:
		var esito: Dictionary = esiti[0]
		_controlla(int(esito.get("energyGained", -1)) == atteso,
			"prova perfetta: %d energia invece di %d" % [
				int(esito.get("energyGained", -1)), atteso])
		_controlla(int(esito.get("comboBest", 0)) == 5,
			"prova perfetta: la serie migliore risulta %d invece di 5" % int(esito.get("comboBest", 0)))
		_controlla(int(esito.get("comboEnergy", 0)) == atteso - base * 5,
			"prova perfetta: l'energia attribuita alla serie non torna")
		# Il tetto vale anche misurato sull'esito vero, non solo sulla formula.
		_controlla(float(esito.get("energyGained", 0)) <= float(base * 5) * Combo.MASSIMO,
			"prova perfetta: l'energia supera il doppio della tariffa piatta")

	# --- L'errore spezza la serie, e la giusta dopo riparte dalla tariffa piena.
	esiti.clear()
	player.start_session(_sessione(4, base))
	await process_frame
	await _rispondi(true)     # serie 1
	await _avanza()
	await _rispondi(true)     # serie 2 → ×1,25
	await _avanza()
	await _rispondi(false)    # spezzata
	await _avanza()
	await _rispondi(true)     # serie 1 di nuovo
	await _avanza()
	_controlla(esiti.size() == 1, "la prova con errore non si è chiusa")
	if esiti.size() == 1:
		var con_errore: Dictionary = esiti[0]
		var atteso_errore := Combo.energia(base, 1) + Combo.energia(base, 2) + Combo.energia(base, 1)
		_controlla(int(con_errore.get("energyGained", -1)) == atteso_errore,
			"dopo l'errore la serie non riparte da capo: %d energia invece di %d" % [
				int(con_errore.get("energyGained", -1)), atteso_errore])
		_controlla(int(con_errore.get("comboBest", 0)) == 2,
			"dopo l'errore la serie migliore risulta %d invece di 2" % int(con_errore.get("comboBest", 0)))

	# --- La serie non attraversa le prove: la prima giusta della prova nuova
	# paga la tariffa piatta anche se quella prima era finita in alto.
	esiti.clear()
	player.start_session(_sessione(2, base))
	await process_frame
	await _rispondi(true)
	await _avanza()
	await _rispondi(true)
	await _avanza()
	if esiti.size() == 1:
		var nuova: Dictionary = esiti[0]
		_controlla(
			int(nuova.get("energyGained", -1)) == Combo.energia(base, 1) + Combo.energia(base, 2),
			"la serie è sopravvissuta alla fine della prova precedente")
		_controlla(int(nuova.get("comboBest", 0)) == 2,
			"la serie migliore della prova nuova risulta %d invece di 2" % int(nuova.get("comboBest", 0)))

	root.remove_child(player)
	player.queue_free()
	await process_frame
