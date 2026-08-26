extends SceneTree

## **Quello che il bambino riceve davvero.** (12 agosto 2026)
##
## Richiesta del committente: «fai una revisione totale delle spiegazioni di
## NORA. Le trovo scarse.»
##
## `bank_explanation_audit` guarda che cosa c'è **scritto nei banchi**: nessuna
## spiegazione vuota, nessuna che ripeta domanda e risposta, nessuna usata da
## mezzo banco. Sono controlli giusti ed erano tutti verdi mentre il difetto più
## grosso era in piedi — perché nessuno di quei controlli guarda **se la
## spiegazione arriva**, né **se dice un perché**.
##
## Le due cose che questo audit tiene, e che quello non poteva vedere:
##
##   1. **la spiegazione arriva su tutt'e due gli esiti.** Rispondendo giusto
##      `exercise_player` mostrava soltanto «Giusto! +N energia». Il gioco è
##      tarato perché il bambino risponda bene la maggior parte delle volte:
##      quindi la maggior parte delle volte non riceveva niente;
##   2. **quello che riceve aggiunge qualcosa.** Non basta che una stringa
##      arrivi: deve portare parole che il bambino non aveva già davanti agli
##      occhi nella domanda, nella risposta e nella spiegazione dell'item.
##
## ### Perché qui non si misura «contiene un perché»
##
## La prima stesura pretendeva un nesso causale riconosciuto da una lista di
## parole-spia, e ha bocciato **trenta voci scritte bene**: «Le parentesi servono
## a dire *questo prima*» spiega una causa senza contenere «perché», e «L'uguale
## è una bilancia in equilibrio» non ha nessuna parola-spia ed è la voce migliore
## del gruppo. Una lista di parole non sa giudicare se una frase spiega — è lo
## stesso errore dei digrammi impossibili, e la lezione è la stessa: **un'euristica
## può scegliere, non giudicare.**
##
## Quello che si può misurare esattamente è **quanto NORA aggiunge**, e si misura
## come già fa `bank_explanation_audit`: le parole che restano tolte quelle che
## il bambino aveva sotto gli occhi.

const OK := "NORA EXPLANATION audit VERDE"
## Quota minima di prove in cui NORA aggiunge parole sue a quelle dell'item.
## È un cricchetto: si può alzare, mai abbassare. Prima del livello per argomento
## valeva **zero sulle risposte giuste**, perché non arrivava niente.
const QUOTA_MINIMA := 0.90
## Quante parole nuove deve portare, come minimo, quello che NORA dice: parole
## che non stavano già nella domanda, nella risposta o nella spiegazione.
const RESIDUO_MINIMO := 12
## Lunghezza sotto la quale una voce non sta spiegando niente.
const MINIMO_UTILE := 30

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_ogni_argomento_del_runtime_ha_la_sua_voce()
	_nessuna_voce_e_una_copia()
	_le_voci_dicono_qualcosa()
	_quello_che_il_bambino_riceve()
	if errori.is_empty():
		print(OK)
	else:
		printerr("NORA EXPLANATION audit ROSSO")
		for errore in errori.slice(0, 25):
			printerr("  - %s" % errore)
		printerr("  (%d in tutto)" % errori.size())
	quit(0 if errori.is_empty() else 1)

## Quanti argomenti dei MINIGIOCHI possono ancora stare senza il perché di NORA.
##
## Il 15 agosto 2026 il registro degli argomenti ha smesso di ignorare i
## minigiochi (`KnowledgeCodex.runtime_topics`), e con loro sono comparsi 111
## argomenti che il gioco serve da sempre e che questo audit non aveva mai
## guardato. Non erano muti — la loro spiegazione sta nella spec del minigioco e
## il Manuale adesso la raccoglie — ma il **perché causale di NORA**, quello
## scritto a mano, ce l'hanno solo i topic dei banchi.
##
## Questo numero è un debito dichiarato, e serve a una cosa sola: **può scendere,
## non salire**. Chi aggiunge un minigioco nuovo senza la sua voce lo trova
## rosso; chi scrive una voce mancante lo fa scendere e lo aggiorna qui.
const DEBITO_MINIGIOCHI := 111

## **Nessun argomento del runtime senza il suo perché.** Un argomento scoperto è
## un argomento su cui NORA non ha niente da aggiungere, e sono proprio quelli in
## cui il bambino resta con la riformulazione del banco.
##
## La garanzia è piena sui **banchi** — lì un buco è un errore — e a debito
## dichiarato sui **minigiochi**, dove i buchi sono 111 e sono elencati sopra.
func _ogni_argomento_del_runtime_ha_la_sua_voce() -> void:
	var codex := KnowledgeCodex.new()
	var scoperti_banco: Array = []
	var scoperti_minigioco: Array = []
	for chiave_dato in codex.runtime_topics().keys():
		var chiave := str(chiave_dato)
		if NoraExplanations.VOCI.has(chiave):
			continue
		var meta: Dictionary = codex.runtime_topics()[chiave]
		if str(meta.get("fonte", "banco")) == "banco":
			scoperti_banco.append(chiave)
		else:
			scoperti_minigioco.append(chiave)
	scoperti_banco.sort()
	scoperti_minigioco.sort()
	if not scoperti_banco.is_empty():
		_fallisci("argomenti di banco senza il perché di NORA (%d): %s" % [
			scoperti_banco.size(), ", ".join(scoperti_banco.slice(0, 10))])
	if scoperti_minigioco.size() > DEBITO_MINIGIOCHI:
		_fallisci("il debito dei minigiochi è salito a %d (dichiarato %d): %s" % [
			scoperti_minigioco.size(), DEBITO_MINIGIOCHI,
			", ".join(scoperti_minigioco.slice(0, 10))])
	else:
		print("  argomenti di minigioco senza il perché di NORA: %d su %d dichiarati" % [
			scoperti_minigioco.size(), DEBITO_MINIGIOCHI])

## **Nessuna voce copiata da un'altra.** Due argomenti con lo stesso perché
## vogliono dire che uno dei due non è stato pensato — ed è il modo in cui un
## livello autorato si degrada in un riempitivo.
func _nessuna_voce_e_una_copia() -> void:
	var visti: Dictionary = {}
	for chiave in NoraExplanations.VOCI.keys():
		var voce: Dictionary = NoraExplanations.VOCI[chiave]
		for campo in ["perche", "come"]:
			var testo := str(voce.get(campo, "")).strip_edges()
			var firma := "%s|%s" % [campo, testo]
			if visti.has(firma):
				_fallisci("%s e %s hanno lo stesso «%s»" % [visti[firma], chiave, campo])
			visti[firma] = str(chiave)

## Ogni voce deve avere tutt'e due i campi, e nessuno dei due può essere il nome
## dell'argomento riscritto: «le sequenze servono per le sequenze» non spiega.
func _le_voci_dicono_qualcosa() -> void:
	for chiave_dato in NoraExplanations.VOCI.keys():
		var chiave := str(chiave_dato)
		var voce: Dictionary = NoraExplanations.VOCI[chiave]
		var argomento := chiave.split(":")[1].replace("-", " ")
		for campo in ["perche", "come"]:
			var testo := str(voce.get(campo, "")).strip_edges()
			if testo.length() < MINIMO_UTILE:
				_fallisci("%s · %s: troppo corto per dire qualcosa — «%s»" % [chiave, campo, testo])
			if testo.to_lower() == argomento:
				_fallisci("%s · %s: è il nome dell'argomento riscritto" % [chiave, campo])

## **La misura che conta.** Per ogni item di ogni banco si costruisce la frase
## che NORA direbbe davvero, sui due esiti, e si guarda **quanto aggiunge** a
## quello che il bambino aveva già davanti. Non è quello che è scritto nei
## banchi: è quello che arriva.
func _quello_che_il_bambino_riceve() -> void:
	var cm := ContentManager.new()
	var totale := 0
	var aggiungono := 0
	var mute := 0
	print("%-14s %6s %10s %7s" % ["MATERIA", "prove", "aggiungono", "mute"])
	for subject_dato in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_dato)
		var quante := 0
		var buone := 0
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			var topic := str(item.get("topic", ""))
			var spiegazione := str(item.get("explanation", ""))
			var noto := "%s %s" % [str(item.get("prompt", "")), str(item.get("answer", ""))]
			for corretto in [true, false]:
				# La memoria si azzera a ogni prova: qui si misura CHE COSA NORA
				# ha da dire su questo item, non l'ordine in cui lo direbbe in una
				# partita. Passare la memoria viva farebbe dipendere il verdetto
				# dall'ordine di lettura del banco, che non significa niente.
				NoraExplanations.dimentica_tutto()
				var commento := NoraExplanations.commento(item, subject, bool(corretto), "")
				var pezzi: Array = []
				for chiave in ["correzione", "caso", "regola"]:
					var pezzo := str(commento.get(chiave, "")).strip_edges()
					if pezzo != "":
						pezzi.append(pezzo)
				var detta := "\n".join(PackedStringArray(pezzi))
				totale += 1
				quante += 1
				if detta.strip_edges() == "":
					mute += 1
					_fallisci("%s · %s: NORA non dice niente" % [subject, str(item.get("id", "?"))])
					continue
				if _residuo(detta, noto) >= RESIDUO_MINIMO:
					aggiungono += 1
					buone += 1
		print("%-14s %6d %10d %7s" % [subject, quante, buone, ""])
	if totale == 0:
		_fallisci("nessun item letto: la misura non sta guardando niente")
		return
	var quota := float(aggiungono) / float(totale)
	print("\nProve in cui NORA aggiunge parole sue: %.1f%% (minimo %.0f%%)" % [
		100.0 * quota, 100.0 * QUOTA_MINIMA])
	if quota < QUOTA_MINIMA:
		_fallisci("solo il %.1f%% di quello che NORA dice aggiunge qualcosa (minimo %.0f%%)" % [
			100.0 * quota, 100.0 * QUOTA_MINIMA])
	if mute > 0:
		_fallisci("%d prove in cui NORA resta muta" % mute)

## Quanto pesa, in caratteri, quello che c'è nella frase di NORA e non c'era già
## sotto gli occhi del bambino. Stesso conto di `bank_explanation_audit`.
func _residuo(detta: String, noto: String) -> int:
	var viste: Dictionary = {}
	for parola in _parole(noto):
		viste[parola] = true
	var nuove := 0
	for parola in _parole(detta):
		if not viste.has(parola):
			nuove += str(parola).length() + 1
	return nuove

func _parole(testo: String) -> Array:
	var pulito := ""
	for c in testo.to_lower():
		pulito += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c in "àèéìòù" else " "
	var out: Array = []
	for parola in pulito.split(" ", false):
		if str(parola).length() > 1:
			out.append(str(parola))
	return out
