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

## **Quanti esercizi almeno consegnano una correzione specifica.** SI ALZA E MAI
## SI ABBASSA — è il cricchetto al contrario, e vale la stessa regola: una
## modifica che lo fa scendere è una regressione, non una scelta.
## Il 28 agosto 2026 sono tutti e 3584 (erano 3569 prima dei quindici sulle radici).
const PAVIMENTO_CORREZIONI := 3584

## **Quante frasi di correzione ci sono in tutto.** Anche questo si alza e mai si
## abbassa — con un'eccezione dichiarata, ed è successa lo stesso giorno in cui il
## numero è nato.
##
## Erano 15015, e sono scese a 14537 **migliorando**: la passata sulle domande
## vicine attaccava a una domanda su «rosae» il perché di «2», che è la risposta a
## «quanti numeri distingue la declinazione latina». Vera, e assurda — nessun
## bambino scrive «2» a una domanda su una parola. Cinquecentoventitré correzioni
## così sono uscite, e al loro posto ne sono entrate quarantacinque scritte a mano
## per i quindici esercizi che restavano scoperti.
##
## **Un cricchetto su un numero che conta anche il rumore protegge il rumore.**
## Quando si scopre che lo faceva, il numero si ritara e si scrive perché: è
## l'unica eccezione onesta alla regola, e va usata solo con la misura in mano.
const PAVIMENTO_FRASI := 14600

## **Sotto quanti esercizi un argomento può cavarsela con una riga sola.**
##
## Sopra questa soglia il bambino incontra l'argomento troppe volte perché una
## frase basti: la rileggerebbe fino a esaurimento, e una riga ripetuta insegna a
## saltare la riga. Quaranta è dove passa oggi il confine fra i diciotto argomenti
## affollati e tutti gli altri; abbassarlo vuol dire scrivere più livelli, mai
## meno.
const AFFOLLATO := 40

## **Quante materie hanno almeno una figura.** SI ALZA E MAI SI ABBASSA.
##
## Il 27 agosto sono **dieci su dodici**. Restano fuori fisica e scienze: nei loro
## testi non c'è niente che si possa estrarre con certezza in un diagramma — le
## conversioni di unità in fisica sono tre esercizi su 157 — e disegnare comunque
## vorrebbe dire decorare. Una figura che si accende su tre prove è codice morto
## con una bella spiegazione sopra, ed è lo stesso motivo per cui la bilancia
## dell'uguale non è stata fatta.
const MATERIE_CON_FIGURA := 10

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
	_i_livelli(cm)
	_due_voci_non_dicono_lo_stesso(cm)
	_ogni_voce_ha_il_suo_contenuto(cm)
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
	var con_correzione := 0
	var totale_item := 0
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			totale_item += 1
			var perche: Dictionary = item.get("distractorWhy", {})
			if perche.is_empty():
				continue
			con_correzione += 1
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
	print("1. LA CONSEGNA   %d frasi scritte per l'errore, %d consegnate · %d esercizi su %d ne hanno almeno una" % [
		con_why, consegnati, con_correzione, totale_item])
	if con_why > 0 and consegnati < con_why:
		_fallisci("%d frasi su %d non raggiungono il bambino" % [con_why - consegnati, con_why])
	if con_why < PAVIMENTO_FRASI:
		_fallisci("le frasi di correzione sono %d: erano %d, e questo numero non deve scendere" % [
			con_why, PAVIMENTO_FRASI])
	if con_correzione < PAVIMENTO_CORREZIONI:
		_fallisci("solo %d esercizi consegnano una correzione: erano %d, e questo numero non deve scendere" % [
			con_correzione, PAVIMENTO_CORREZIONI])

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
	var per_materia: Dictionary = {}
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
			per_materia[subject] = int(per_materia.get(subject, 0)) + 1
			var figura = NORA_FIGURA.new()
			figura.mostra(tipo, Dictionary(scelta.get("dati", {})))
			if figura.descrizione().strip_edges() == "":
				_fallisci("%s · %s: figura «%s» senza descrizione a parole" % [
					subject, str(item.get("id", "?")), tipo])
			figura.free()
	var materie_coperte := per_materia.size()
	var scoperte: Array = []
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		if not per_materia.has(str(subject_dato)):
			scoperte.append(str(subject_dato))
	print("5. LE FIGURE     %d prove hanno un disegno · %d materie su 12 (senza: %s)" % [
		con_figura, materie_coperte, ", ".join(PackedStringArray(scoperte))])
	print("                 %s" % str(per_tipo))
	if con_figura <= 0:
		_fallisci("nessun esercizio riceve una figura: il disegno non arriva a nessuno")
	if materie_coperte < MATERIE_CON_FIGURA:
		_fallisci("solo %d materie hanno una figura: erano %d, e questo numero non deve scendere" % [
			materie_coperte, MATERIE_CON_FIGURA])

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

## 7. **Un argomento affollato non può avere una riga sola.**
##
## Il meccanismo dei livelli è nato il 26 agosto e per un giorno l'ha usato un
## argomento su 249. Diciotto argomenti hanno quaranta o più esercizi e insieme ne
## coprono 1325: con una riga sola NORA la ripeteva fino a esaurimento della
## pazienza, e la memoria delle dodici impronte rimanda il problema senza
## risolverlo.
##
## Questa misura non giudica che cosa dicono i livelli — non può — ma che
## **esistano**: è meccanica, e vale la pena averla perché il difetto che previene
## si ripresenta ogni volta che si aggiungono esercizi a un argomento esistente.
func _i_livelli(cm: ContentManager) -> void:
	var conta: Dictionary = {}
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		for entry in cm._load_bank(subject):
			var chiave := "%s:%s" % [subject, str((entry as Dictionary).get("topic", ""))]
			conta[chiave] = int(conta.get(chiave, 0)) + 1
	var affollati := 0
	var con_livelli := 0
	var coperti := 0
	for chiave in conta.keys():
		if int(conta[chiave]) < AFFOLLATO:
			continue
		affollati += 1
		coperti += int(conta[chiave])
		var pezzi := str(chiave).split(":")
		var v := NoraExplanations.voce(str(pezzi[0]), str(pezzi[1]))
		var quanti := NoraExplanations.livelli_di(v, true).size()
		if quanti >= 2:
			con_livelli += 1
		else:
			_fallisci("%s ha %d esercizi e una riga sola di NORA: serve almeno un secondo livello" % [
				str(chiave), int(conta[chiave])])
	print("7. I LIVELLI     %d argomenti con %d+ esercizi (%d prove in tutto), %d con più livelli" % [
		affollati, AFFOLLATO, coperti, con_livelli])

## 8. **Due argomenti vivi non possono insegnare la stessa cosa con le stesse
##    parole.**
##
## Le voci sono 249 e nessuno le legge tutte insieme: e' cosi' che
## `fisica:onde-luce` era finita a ripetere `fisica:onde` parola per parola senza
## dire niente sulla luce, e che tre voci di italiano insegnavano tutte a
## «metterci davanti io». La memoria delle dodici impronte non aiuta: sono
## argomenti diversi, quindi impronte diverse, e il bambino le sente tutt'e due.
##
## Si confrontano solo gli argomenti **vivi** — quelli che i banchi propongono
## davvero — perche' le altre 118 voci aspettano contenuti che non esistono
## ancora, e un rosso su quelle direbbe una cosa che non riguarda nessuno.
##
## Il confronto e' sullo scheletro: via la punteggiatura e le parole corte, e si
## guarda quante parole lunghe hanno in comune. Non e' un giudizio di qualita' —
## non lo sarebbe mai — e' la stessa domanda che si farebbe un lettore: «questa
## non l'ho gia' letta?».
const SOMIGLIANZA_MASSIMA := 0.6

func _ossatura(riga: String) -> Dictionary:
	var fuori: Dictionary = {}
	for parola in riga.to_lower().replace(",", " ").replace(".", " ").replace(":", " ").split(" ", false):
		var pulita := str(parola).strip_edges()
		if pulita.length() >= 5:
			fuori[pulita] = true
	return fuori

## **Vivo vuol dire «il gioco lo sa servire», e i banchi sono solo meta' della
## risposta.**
##
## Scritta il 27 agosto, questa guardia guardava solo i banchi e confrontava 131
## argomenti su 248. L'errore veniva da una convinzione sbagliata — «le voci senza
## un banco aspettano contenuti che non esistono» — smentita dalla misura il 28:
## `MinigameManager.topics_for()` ne serve **206**, di cui 117 in nessun banco, e
## sono contenuto reale che una lezione puo' promettere e il mondo consegna.
##
## Delle 249 voci di NORA ne resta scoperta **una sola**. Chi cambia questa
## funzione tenga le due fonti insieme: guardarne una sola e' esattamente il modo
## in cui questa guardia e' nata mezza cieca.
static func _argomenti_vivi(cm: ContentManager) -> Array:
	var vivi: Array = []
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		var visti: Dictionary = {}
		for entry in cm._load_bank(subject):
			visti[str((entry as Dictionary).get("topic", ""))] = true
		for topic in MinigameManager.topics_for(subject):
			visti[str(topic)] = true
		for topic in visti.keys():
			vivi.append([subject, str(topic)])
	return vivi

func _due_voci_non_dicono_lo_stesso(cm: ContentManager) -> void:
	var vivi: Array = _argomenti_vivi(cm)
	var righe: Array = []
	for coppia in vivi:
		var v := NoraExplanations.voce(str(coppia[0]), str(coppia[1]))
		for corretto in [true, false]:
			for riga in NoraExplanations.livelli_di(v, bool(corretto)):
				righe.append({"chi": "%s:%s" % [coppia[0], coppia[1]], "testo": str(riga),
					"ossa": _ossatura(str(riga))})
	var gemelle := 0
	for a in range(righe.size()):
		for b in range(a + 1, righe.size()):
			var ua: Dictionary = righe[a]["ossa"]
			var ub: Dictionary = righe[b]["ossa"]
			if ua.size() < 4 or ub.size() < 4:
				continue
			if str(righe[a]["chi"]) == str(righe[b]["chi"]):
				continue
			var comuni := 0
			for parola in ua.keys():
				if ub.has(parola):
					comuni += 1
			var quota := float(comuni) / float(mini(ua.size(), ub.size()))
			if quota > SOMIGLIANZA_MASSIMA:
				gemelle += 1
				_fallisci("%s e %s dicono quasi la stessa cosa (%.0f%%): «%s»" % [
					str(righe[a]["chi"]), str(righe[b]["chi"]), quota * 100.0,
					str(righe[a]["testo"]).substr(0, 60)])
	print("8. NIENTE GEMELLE %d righe di NORA su argomenti vivi, %d coppie troppo simili" % [
		righe.size(), gemelle])

## 9. **Nessuna voce di NORA senza contenuto, e nessun contenuto senza voce.**
##
## Nasce da un errore mio, del 27 agosto: avevo dichiarato che «118 voci aspettano
## contenuti che non esistono ancora», guardando i banchi e basta. La misura del
## giorno dopo dice un'altra cosa — `MinigameManager.topics_for()` serve 206
## argomenti, di cui **117 in nessun banco** — e di voci scoperte ce n'era una
## sola, `matematica:radici`, adesso chiusa con otto esercizi.
##
## Il conto va nelle due direzioni, perche' i due difetti sono diversi e tutti e
## due reali:
##
##   una VOCE SENZA CONTENUTO   e' una spiegazione scritta che nessuno leggera'
##                              mai: lavoro fatto e sepolto;
##   un CONTENUTO SENZA VOCE    e' un argomento su cui NORA non ha niente da
##                              dire, e il bambino resta con la sola
##                              riformulazione dell'esercizio.
##
## Zero e zero il 28 agosto 2026. Se un giorno si aggiunge un argomento a un banco
## o a un minigioco, questa misura chiede la sua voce prima che il contenuto
## arrivi in mano a qualcuno.
func _ogni_voce_ha_il_suo_contenuto(cm: ContentManager) -> void:
	var serviti: Dictionary = {}
	for coppia in _argomenti_vivi(cm):
		serviti["%s:%s" % [str(coppia[0]), str(coppia[1])]] = true
	var voci: Array = NoraExplanations.argomenti()
	var senza_contenuto: Array = []
	for v in voci:
		if not serviti.has(str(v)):
			senza_contenuto.append(str(v))
	var senza_voce: Array = []
	for k in serviti.keys():
		if not voci.has(str(k)):
			senza_voce.append(str(k))
	print("9. NIENTE ORFANI %d voci, %d argomenti serviti · voci senza contenuto %d, contenuti senza voce %d" % [
		voci.size(), serviti.size(), senza_contenuto.size(), senza_voce.size()])
	for v in senza_contenuto:
		_fallisci("la voce «%s» e' scritta ma nessun banco e nessun minigioco serve quell'argomento" % str(v))
	for k in senza_voce:
		_fallisci("l'argomento «%s» e' giocabile ma NORA non ha niente da dirne" % str(k))
