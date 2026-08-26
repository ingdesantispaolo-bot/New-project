extends SceneTree

## **La guardia delle spiegazioni.** (26 agosto 2026)
##
## Segnalazione dello studente: «le spiegazioni di NORA servono a poco, ci sono
## molte scritte inutili e ripetute, poca sostanza e poca chiarezza». Le
## spiegazioni sono il cuore della didattica di questo gioco: se cedono, non
## rimane niente che valga la pena difendere.
##
## ### Che cosa questo audit misura, e che cosa NON misura
##
## **Non giudica la qualità di una spiegazione.** Non può, e provarci è un errore
## già pagato: `ha_causa()` — una lista di parole-spia — era stata usata come
## metro di qualità e aveva bocciato trenta voci fra le migliori del gioco, perché
## «L'uguale è una bilancia in equilibrio» non contiene nessuna parola-spia ed è la
## spiegazione migliore del suo gruppo.
##
## Misura **solo cose meccaniche e verificabili**, ognuna delle quali corrisponde a
## un difetto che è stato trovato davvero:
##
##   1. LA CONSEGNA    ogni item che porta `distractorWhy` deve consegnare la
##                     frase giusta all'alternativa giusta. Misurato prima della
##                     correzione: 3082 item su 3569 la portavano e **nessuno la
##                     consegnava** — `distractorWhy` non entrava affatto nel
##                     percorso della prova.
##   2. L'ECO          nessuna spiegazione deve aprire ripetendo la risposta che
##                     il bambino ha appena dato. Erano 1159 su 3569 (il 32%).
##   3. LA RIPETIZIONE nessuna frase-scheletro può comparire piu' di TETTO_FRASE
##                     volte sull'insieme dei banchi. Il tetto e' a cricchetto:
##                     **si abbassa e mai si alza**, come quello delle scorciatoie.
##   4. IL SILENZIO    NORA non ripete una riga gia' detta di recente. Con dodici
##                     impronte di memoria, una sessione simulata non deve mai
##                     sentire due volte la stessa.
##   5. LE FIGURE      ogni figura che un item dichiara deve essere disegnabile e
##                     avere una descrizione a parole per chi non la vede.
##
## Uso: node scripts/run-godot-audits.mjs nora_spiegazione_utile

## Quante volte al massimo una stessa frase-scheletro (numeri esclusi) puo'
## comparire fra tutte le spiegazioni dei dodici banchi.
##
## SI ABBASSA E MAI SI ALZA. Alla nascita, il 26 agosto 2026, il massimo misurato
## e' 91 — «Cerchi quante volte il N sta dentro M», la coda del fattore mancante,
## dove i numeri SONO il contenuto e lo scheletro identico non e' un difetto.
## Prima della pulizia il massimo era 254: «cambiare l'ordine non cambia il
## prodotto», identica parola per parola, che adesso NORA dice una volta sola.
const TETTO_FRASE := 95

## Sotto questa lunghezza una frase non fa testo: «Fa 12.» ripetuta non e'
## tappezzeria, e' una risposta.
const FRASE_MINIMA := 25

const NORA_FIGURA = preload("res://scripts/game/nora_figura.gd")
const PLAYER := preload("res://scripts/game/exercise_player.gd")

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var cm := ContentManager.new()
	_la_consegna(cm)
	_l_eco(cm)
	_la_ripetizione(cm)
	_il_silenzio(cm)
	_le_figure(cm)
	await _sullo_schermo()
	if not errori.is_empty():
		for messaggio in errori.slice(0, 12):
			push_error(str(messaggio))
		push_error("NORA SPIEGAZIONE UTILE: %d problemi" % errori.size())
		quit(1)
		return
	print("\nNORA SPIEGAZIONE UTILE audit VERDE")
	quit(0)

## 1. Ogni `distractorWhy` scritto deve arrivare al bambino che ha toccato QUELLA
##    alternativa. E' la voce G-N1 del piano, e la sola in cui il contenuto
##    esisteva gia': mancava il filo.
func _la_consegna(cm: ContentManager) -> void:
	var con_why := 0
	var consegnati := 0
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			var perche: Dictionary = item.get("distractorWhy", {})
			if perche.is_empty():
				continue
			for scelta_dato in perche.keys():
				var scelta := str(scelta_dato)
				con_why += 1
				NoraExplanations.dimentica_tutto()
				var commento := NoraExplanations.commento(item, subject, false, scelta)
				if str(commento.get("correzione", "")) == str(perche[scelta]):
					consegnati += 1
				else:
					_fallisci("%s · %s: la frase di «%s» non arriva a chi la tocca" % [
						subject, str(item.get("id", "?")), scelta])
	print("1. LA CONSEGNA   %d frasi scritte per l'errore, %d consegnate" % [con_why, consegnati])
	if con_why > 0 and consegnati < con_why:
		_fallisci("%d frasi su %d non raggiungono il bambino" % [con_why - consegnati, con_why])

## 2. Una spiegazione che apre ripetendo la risposta appena data non spiega: fa
##    rileggere. E' la regola 1 del contratto, ed e' meccanica.
func _l_eco(cm: ContentManager) -> void:
	var totale := 0
	var eco := 0
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			totale += 1
			var risposta := str(item.get("answer", "")).strip_edges().to_lower()
			if risposta.length() <= 2:
				continue
			var testo := str(item.get("explanation", "")).strip_edges().to_lower()
			testo = testo.trim_prefix("\"").trim_prefix("«")
			if testo.begins_with(risposta):
				eco += 1
	var quota := 100.0 * float(eco) / float(maxi(1, totale))
	print("2. L'ECO         %d spiegazioni su %d aprono con la risposta (%.1f%%)" % [
		eco, totale, quota])
	# Non zero: in qualche materia la risposta E' l'inizio naturale della frase
	# («Roma fu fondata...» a una domanda su Roma). Il tetto tiene la coda corta.
	if quota > 6.0:
		_fallisci("il %.1f%% delle spiegazioni riapre con la risposta (tetto 6%%)" % quota)

## 3. La stessa frase, a meno dei numeri, non puo' tappezzare i banchi.
func _la_ripetizione(cm: ContentManager) -> void:
	var conteggi: Dictionary = {}
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		for entry in cm._load_bank(str(subject_dato)):
			var item := entry as Dictionary
			for frase in str(item.get("explanation", "")).split(". ", false):
				var scheletro := RegEx.create_from_string("\\d+").sub(
					str(frase).strip_edges(), "#", true)
				if scheletro.length() < FRASE_MINIMA:
					continue
				conteggi[scheletro] = int(conteggi.get(scheletro, 0)) + 1
	var peggiore := 0
	var quale := ""
	for scheletro in conteggi.keys():
		if int(conteggi[scheletro]) > peggiore:
			peggiore = int(conteggi[scheletro])
			quale = str(scheletro)
	print("3. LA RIPETIZIONE frase piu' ripetuta: %d volte (tetto %d) — «%s»" % [
		peggiore, TETTO_FRASE, quale.substr(0, 60)])
	if peggiore > TETTO_FRASE:
		_fallisci("una frase compare %d volte (tetto %d): «%s»" % [peggiore, TETTO_FRASE, quale])

## 4. NORA non si ripete. Si simula una sessione lunga su UN argomento — il caso
##    peggiore, perche' `LESSON_TOPIC_SHARE` riserva due nodi su tre agli
##    argomenti della lezione del mondo — e nessuna riga deve tornare.
func _il_silenzio(cm: ContentManager) -> void:
	var ripetute := 0
	var dette_in_tutto := 0
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		var per_argomento: Dictionary = {}
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			var topic := str(item.get("topic", ""))
			var elenco: Array = per_argomento.get(topic, [])
			if elenco.size() < 20:
				elenco.append(item)
			per_argomento[topic] = elenco
		for topic_dato in per_argomento.keys():
			NoraExplanations.dimentica_tutto()
			var sentite: Dictionary = {}
			for item_dato in per_argomento[topic_dato]:
				var commento := NoraExplanations.commento(
					item_dato as Dictionary, subject, true, "", NoraExplanations.memoria())
				NoraExplanations.registra(Array(commento.get("impronte", [])))
				var regola := str(commento.get("regola", "")).strip_edges()
				if regola == "":
					continue
				dette_in_tutto += 1
				if sentite.has(regola):
					ripetute += 1
					_fallisci("%s · %s: NORA ripete «%s»" % [
						subject, str(topic_dato), regola.substr(0, 40)])
				sentite[regola] = true
	print("4. IL SILENZIO   %d righe di NORA in venti prove per argomento, %d ripetute" % [
		dette_in_tutto, ripetute])

## 5. Una figura dichiarata deve disegnarsi e deve sapersi dire a parole.
func _le_figure(cm: ContentManager) -> void:
	var con_figura := 0
	var per_tipo: Dictionary = {}
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			var scelta: Dictionary = NORA_FIGURA.per_item(item, subject)
			if scelta.is_empty():
				continue
			con_figura += 1
			var tipo := str(scelta.get("tipo", ""))
			per_tipo[tipo] = int(per_tipo.get(tipo, 0)) + 1
			var figura = NORA_FIGURA.new()
			figura.mostra(tipo, Dictionary(scelta.get("dati", {})))
			if figura.descrizione().strip_edges() == "":
				_fallisci("%s · %s: figura «%s» senza descrizione a parole" % [
					subject, str(item.get("id", "?")), tipo])
			figura.free()
	print("5. LE FIGURE     %d prove hanno un disegno: %s" % [con_figura, str(per_tipo)])
	if con_figura <= 0:
		_fallisci("nessun esercizio riceve una figura: il disegno non arriva a nessuno")

## 6. **La correzione arriva sullo schermo, non solo dalla funzione.**
##
## Le cinque misure sopra interrogano `NoraExplanations`, che è esattamente ciò
## che faceva anche il codice di prima: `distractorWhy` era scritto, corretto e
## raggiungibile da chiunque lo chiamasse — solo che **nel gioco non lo chiamava
## nessuno**. Un audit che si ferma alla funzione avrebbe dichiarato verde il
## difetto da cui questo lotto nasce.
##
## Qui si costruisce un ExercisePlayer vero, gli si dà una prova a scelta
## multipla, si tocca l'alternativa sbagliata e si legge che cosa c'è scritto nel
## nodo che il bambino guarda.
func _sullo_schermo() -> void:
	var item := {
		"format": "multiple_choice",
		"prompt": "Quanto fa 7 × 8?",
		"topic": "tabelline",
		"subject": "matematica",
		"difficulty": 2,
		"answer": "56",
		"options": ["56", "54", "63", "48"],
		"explanation": "Sette gruppi da otto: 56.",
		"distractorWhy": {
			"54": "È 6 × 9: due tabelline vicine che si confondono.",
			"63": "È 7 × 9, una riga più in là.",
			"48": "È 6 × 8, una riga più indietro.",
		},
	}
	var player: Control = PLAYER.new()
	root.add_child(player)
	player.start_session({
		"sessionId": "nora-utile", "kind": "mission", "subject": "matematica",
		"nodes": [item], "shields": 3, "pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {}},
	})
	await process_frame
	await process_frame
	NoraExplanations.dimentica_tutto()
	player.call("_answer", "54")
	await process_frame

	var lezione: RichTextLabel = player.find_child("NoraLesson", true, false)
	var figura: Control = player.find_child("NoraFigure", true, false)
	if lezione == null:
		_fallisci("il pannello della lezione non esiste nella scena")
	elif not lezione.visible:
		_fallisci("il pannello della lezione resta invisibile dopo un errore")
	elif not lezione.text.contains("6 × 9"):
		_fallisci("sullo schermo non arriva il perche' dell'alternativa toccata: «%s»" % lezione.text)
	else:
		print("6. SULLO SCHERMO il bambino che tocca «54» legge: %s" % lezione.text.replace("
", " · "))
	if figura == null or not figura.visible:
		_fallisci("la figura non compare su una moltiplicazione 7 × 8")
	else:
		print("                 e vede: %s" % figura.call("descrizione"))
	player.queue_free()
