class_name KnowledgeCodex
extends RefCounted

## Manuale NORA (O-P4): una voce (`ConceptEntry`) per ogni argomento del runtime.
## Ogni voce ha spiegazione breve, esempio svolto, errore tipico (e perché è
## sbagliato) e strategia suggerita da NORA.
##
## **Una premessa di questo file era falsa, e la correzione è del 12 agosto
## 2026.** Diceva: «per non autorare a mano ~120 topic, le voci dei banchi sono
## RACCOLTE dal contenuto reale, perché ogni item porta già una spiegazione
## causale». Misurato: su 3412 item **l'8%** contiene un nesso causale, gli altri
## riformulano il fatto. La raccolta quindi non raccoglieva spiegazioni, e i
## topic autorati a mano erano **due**.
##
## Adesso il livello per argomento esiste davvero e sta in `NoraExplanations`:
## 135 voci con il perché e il come, scritte una volta per argomento invece che
## ripetute item per item. Il banco continua a fornire l'**esempio svolto**, che
## è il lavoro per cui va bene.
##
## Stato per argomento (nel save): sconosciuto → incontrato → consultato →
## applicato → consolidato. Regole di consultazione: durante l'esame il manuale
## NON rivela la risposta corrente (aiuta a ragionare, non a copiare).
##
## Contratto read-only per Codex (C-P4): l'interfaccia legge le voci e lo stato,
## non calcola mastery né concede progresso.

# --- Stati di conoscenza -------------------------------------------------------
const STATE_UNKNOWN := "unknown"
const STATE_ENCOUNTERED := "encountered"
const STATE_CONSULTED := "consulted"
const STATE_APPLIED := "applied"
const STATE_CONSOLIDATED := "consolidated"
const STATE_ORDER := [STATE_UNKNOWN, STATE_ENCOUNTERED, STATE_CONSULTED, STATE_APPLIED, STATE_CONSOLIDATED]

# Argomenti prodotti dal generatore di matematica (il banco statico ha solo
# "tabelline"): concetti scolastici noti, autorati brevemente.
const MATH_CONCEPTS := {
	# `prompt` e `answer` separati: l'esempio svolto deve mostrare la DOMANDA e
	# poi la risposta, altrimenti la scheda dice «Risultato: 6 × 7 = 42» senza
	# aver mai posto la domanda — e un esempio senza domanda non insegna il
	# procedimento, mostra un fatto.
	"tabelline": {"short": "Moltiplicare è contare gruppi uguali: 4×3 sono quattro gruppi da tre.", "prompt": "Quanto fa 6 × 7?", "example": "42", "error": "Sommare invece di moltiplicare (6+7=13).", "why": "La moltiplicazione ripete un gruppo, non lo aggiunge una volta sola.", "how": "Sei gruppi da sette: 7, 14, 21, 28, 35, 42."},
	"calcolo": {"short": "Un passo alla volta, rispettando l'ordine delle operazioni.", "prompt": "Quanto fa 12 + 3 × 2?", "example": "18", "error": "Fare 12+3 prima di 3×2.", "why": "Moltiplicazioni e divisioni vengono prima di somme e sottrazioni.", "how": "Prima 3 × 2 = 6, poi 12 + 6 = 18."},
	"divisioni": {"short": "Dividere è distribuire in parti uguali o vedere quante volte una quantità sta in un'altra.", "prompt": "24 caramelle divise fra 4 bambini: quante ne riceve ciascuno?", "example": "6", "error": "Rispondere 4, il numero di bambini invece di quante caramelle a testa.", "why": "Il risultato della divisione è la dimensione di ogni parte, non quante parti ci sono.", "how": "Quante volte 4 ci sta in 24? Sei volte, perché 4×6=24."},
	"frazioni": {"short": "Una frazione indica parti di un intero: il denominatore quante parti, il numeratore quante ne prendi.", "prompt": "Una pizza è tagliata in 8 fette uguali. Se ne mangi 3, che frazione hai mangiato?", "example": "3/8", "error": "Scrivere 8/3, scambiando numeratore e denominatore.", "why": "Il denominatore è il numero di fette totali, il numeratore quante ne hai prese: l'ordine non è a caso.", "how": "Conta prima in quante parti è tagliato il tutto, poi quante ne prendi."},
	"percentuali": {"short": "La percentuale è una frazione su 100: 25% significa 25 ogni 100.", "prompt": "In una classe di 20 alunni, il 25% ha gli occhi verdi. Quanti alunni sono?", "example": "5", "error": "Rispondere 25, confondendo la percentuale con il numero di alunni.", "why": "Il 25% non è un numero di persone: è una frazione della classe, e va calcolato su quanti alunni ci sono davvero.", "how": "25% è un quarto: 20 diviso 4 fa 5."},
	"proporzioni": {"short": "Una proporzione mette in relazione due rapporti uguali: a sta a b come c sta a d.", "prompt": "3 penne costano 6 euro. Quanto costano 5 penne, allo stesso prezzo unitario?", "example": "10 euro", "error": "Rispondere 8 euro, sommando 2 euro a caso.", "why": "Il prezzo cresce nella stessa proporzione delle penne, non di una quantità fissa.", "how": "Ogni penna costa 2 euro (6÷3): 5 penne costano 5×2=10 euro."},
	"potenze": {"short": "Una potenza è una moltiplicazione ripetuta: 2³ = 2×2×2.", "prompt": "Quanto fa 2³?", "example": "8", "error": "Rispondere 6, calcolando 2×3 invece della potenza.", "why": "L'esponente dice quante volte la base compare in una moltiplicazione, non per quanto va moltiplicata una sola volta.", "how": "2×2×2: prima 2×2=4, poi 4×2=8."},
	"radici": {"short": "La radice è l'operazione inversa della potenza: √9 = 3 perché 3² = 9.", "prompt": "Quanto vale √16?", "example": "4", "error": "Rispondere 8, dividendo 16 per 2 invece di cercare la radice.", "why": "La radice quadrata cerca il numero che moltiplicato per sé stesso dà 16, non la sua metà.", "how": "Cerca il numero che moltiplicato per sé stesso fa 16: 4×4=16, quindi √16=4."},
	"espressioni": {"short": "Un'espressione si risolve rispettando parentesi e ordine delle operazioni.", "prompt": "Quanto fa 3 + (4 × 2)?", "example": "11", "error": "Rispondere 14, facendo 3+4 prima della parentesi.", "why": "Il contenuto della parentesi va risolto per primo, sempre, indipendentemente da dove si trova nell'espressione.", "how": "Prima la parentesi: 4×2=8. Poi 3+8=11."},
	"equazioni": {"short": "In un'equazione cerchi il valore che rende vera l'uguaglianza, mantenendo l'equilibrio.", "prompt": "Risolvi: x + 5 = 12.", "example": "x = 7", "error": "Rispondere x = 17, sommando invece di sottrarre.", "why": "Per isolare x devi togliere il 5 da entrambe le parti, non aggiungerlo: l'uguaglianza va mantenuta in equilibrio.", "how": "Sottrai 5 da entrambi i lati: x = 12 − 5 = 7."},
	"geometria": {"short": "Le figure hanno proprietà misurabili: perimetro, area, angoli.", "prompt": "Un rettangolo è largo 4 cm e lungo 6 cm. Qual è la sua area?", "example": "24 cm²", "error": "Rispondere 20 cm², calcolando il perimetro invece dell'area.", "why": "L'area misura la superficie (base per altezza), il perimetro misura il contorno: sono domande diverse.", "how": "Area del rettangolo = base × altezza: 4 × 6 = 24 cm²."},
	"coordinate": {"short": "Un punto sul piano si individua con due numeri: ascissa e ordinata.", "prompt": "Quali sono le coordinate del punto che sta 3 a destra dell'origine e 2 in alto?", "example": "(3, 2)", "error": "Scrivere (2, 3), scambiando l'ordine.", "why": "La prima coordinata è sempre quanto si va in orizzontale, la seconda quanto si va in verticale: l'ordine non si può invertire.", "how": "Prima conta quanto vai a destra (3), poi quanto vai in su (2)."},
	"sequenze": {"short": "In una sequenza cerchi la regola che genera i termini successivi.", "prompt": "Qual è il numero che continua la sequenza: 2, 5, 8, 11, …?", "example": "14", "error": "Rispondere 13, sommando 2 invece di 3.", "why": "La regola va trovata guardando la differenza reale fra i termini dati, non supposta.", "how": "Ogni termine è il precedente più 3 (5−2=3, 8−5=3): 11+3=14."},
	"dati": {"short": "I dati si organizzano e si leggono per rispondere a una domanda.", "prompt": "Un grafico mostra le vendite di gelati per mese. A luglio la barra arriva a 80, a dicembre a 20. In quale mese si vendono più gelati?", "example": "Luglio", "error": "Rispondere dicembre, leggendo l'asse al contrario.", "why": "Il valore lo dà l'altezza della barra rispetto all'asse, non la sua posizione nel grafico.", "how": "Confronta le altezze: 80 è più alto di 20, quindi luglio vende di più."},
	"statistica": {"short": "Media, moda e mediana riassumono un insieme di dati.", "prompt": "In un gruppo, quattro persone hanno 10 anni e una ne ha 40. Qual è la media delle età?", "example": "16 anni", "error": "Rispondere 10, che è la moda e non la media.", "why": "La media somma tutti i valori e divide per quante persone sono: un valore molto diverso dagli altri la sposta, mentre la moda resta il valore più frequente.", "how": "Somma le età: 10+10+10+10+40=80. Dividi per 5 persone: 80÷5=16."},
	"problemi": {"short": "In un problema traduci le parole in operazioni: cosa sai, cosa cerchi, come li leghi.", "prompt": "Marco ha 15 figurine. Ne regala 4 e ne compra altre 6. Quante figurine ha ora?", "example": "17", "error": "Rispondere 13, dimenticando di aggiungere quelle comprate dopo aver tolto quelle regalate.", "why": "Il problema ha due operazioni in sequenza, non una sola: bisogna seguire l'ordine degli eventi.", "how": "Parti da 15, togli le 4 regalate (15−4=11), poi aggiungi le 6 comprate (11+6=17)."},
}

# Voci autorate con cura per i topic-cardine dei primi due mondi (O-P2).
const AUTHORED := {
	"italiano:pensiero-linguaggio": {"short": "Le parole nominano cose, azioni, qualità: dare a ciascuna il suo posto rende il pensiero chiaro.", "strategy": "Cerca prima chi fa cosa, poi scegli la forma più chiara."},
	"italiano:scuola-studio": {"short": "Il lessico della scuola: strumenti, luoghi e azioni dell'imparare.", "strategy": "Collega la parola a un'immagine o a un'azione che conosci."},
}

var content: ContentManager  # per raccogliere gli esempi dai banchi reali

func _init(content_manager: ContentManager = null) -> void:
	content = content_manager if content_manager != null else ContentManager.new()

func _key(subject: String, topic: String) -> String:
	return "%s:%s" % [subject, topic]

# Tutti gli argomenti che il runtime può PROPORRE in missioni/enigmi/esami: i
# topic dei banchi (12 materie) più i concetti generati dalla matematica.
## **Tutti gli argomenti che il gioco serve davvero.** (15 agosto 2026)
##
## Fino a ieri erano i topic dei **banchi** più i concetti di matematica. Mancavano
## quelli dei **minigiochi**, ed è per questo che la scheda «NUOVO CONCETTO» è
## potuta uscire vuota su «numeri» mentre `codex_teaching_audit` restava verde:
## l'audit chiedeva conto solo degli argomenti che questa funzione elencava, e
## quello non c'era. Un registro che non elenca metà di ciò che esiste rende
## inutile ogni controllo costruito sopra.
##
## `fonte` dice da dove viene l'argomento: chi verifica può pretendere l'esempio
## con la risposta dai banchi (che ce l'hanno) senza pretenderlo dai minigiochi
## (dove la risposta è un gesto sulla tavola, non una parola).
## Cache del registro degli argomenti: vedi `runtime_topics`.
var _registro_topics: Dictionary = {}

func runtime_topics() -> Dictionary:
	# **Si costruisce una volta sola.** Dal 15 agosto il registro scandisce anche
	# le tabelle dei minigiochi, che sono grandi: ricostruirlo a ogni chiamata ha
	# fatto sforare il tempo al Manuale, che lo interroga dentro un ciclo su tutte
	# le voci. Il contenuto è statico per istanza, quindi la cache non può
	# invecchiare.
	if not _registro_topics.is_empty():
		return _registro_topics
	var out: Dictionary = {}  # "subject:topic" -> {subject, topic, fonte}
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		for topic in content.bank_topics(str(subject)):
			out[_key(str(subject), str(topic))] = {
				"subject": str(subject), "topic": str(topic), "fonte": "banco"}
	for topic in MATH_CONCEPTS.keys():
		out[_key("matematica", str(topic))] = {
			"subject": "matematica", "topic": str(topic), "fonte": "banco"}
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		for topic in MinigameManager.topics_for(str(subject)):
			var chiave := _key(str(subject), str(topic))
			if out.has(chiave):
				continue
			out[chiave] = {"subject": str(subject), "topic": str(topic), "fonte": "minigioco"}
	_registro_topics = out
	return out

# Item del banco più semplice (difficoltà minima) per un argomento: è l'esempio
# più adatto a una prima spiegazione. Ritorna {} se il banco non lo contiene.
func _sample_item(subject: String, topic: String) -> Dictionary:
	var best: Dictionary = {}
	var best_diff := 99
	for item in content._load_bank(subject):
		if str(item.get("topic", "")) == topic:
			var d := int(item.get("difficulty", 1))
			if d < best_diff:
				best_diff = d
				best = item
	return best

# Voce del manuale per un argomento. Autorata se disponibile, altrimenti raccolta
# dal contenuto reale del banco; ha sempre spiegazione, esempio, errore tipico e
# strategia (accessibilità: mai una voce vuota per un topic del runtime).
func entry_for(subject: String, topic: String) -> Dictionary:
	var strategy := NoraContextEngine.subject_method(subject)
	var authored: Dictionary = AUTHORED.get(_key(subject, topic), {})
	if authored.has("strategy"):
		strategy = str(authored["strategy"])

	# 1) Matematica generata: concetti autorati.
	if subject == "matematica" and MATH_CONCEPTS.has(topic):
		var mc = MATH_CONCEPTS[topic]
		var short_text := str(mc) if typeof(mc) != TYPE_DICTIONARY else str(mc.get("short", ""))
		var example := "" if typeof(mc) != TYPE_DICTIONARY else str(mc.get("example", ""))
		var err := "" if typeof(mc) != TYPE_DICTIONARY else str(mc.get("error", ""))
		var why := "" if typeof(mc) != TYPE_DICTIONARY else str(mc.get("why", ""))
		var domanda := "" if typeof(mc) != TYPE_DICTIONARY else str(mc.get("prompt", ""))
		var come := "" if typeof(mc) != TYPE_DICTIONARY else str(mc.get("how", ""))
		if domanda.is_empty():
			# Concetti senza esempio autorato: l'esempio e' la spiegazione stessa,
			# ed e' meglio dirlo che fingere un procedimento che non c'e'.
			domanda = "Guardiamo un caso: %s" % short_text
		return _entry(subject, topic, 1, short_text,
			{"prompt": domanda, "answer": example, "explanation": come if not come.is_empty() else short_text},
			{"wrong": err, "why": why}, strategy)

	# **Il perché dell'argomento, quando c'è, batte la raccolta dal banco.**
	#
	# La riga di commento in cima a questo file diceva che le voci si potevano
	# raccogliere dai banchi «perché ogni item porta già una spiegazione
	# causale». Misurata, quella premessa era falsa: su 3412 item **l'8%**
	# contiene un nesso, gli altri riformulano il fatto. Il manuale raccoglieva
	# quindi riformulazioni, e a un bambino che apre la voce di «declinazione
	# terza» diceva «il genitivo indica la specificazione». Sapeva già.
	#
	# `NoraExplanations` porta il livello che mancava, scritto una volta per
	# argomento invece che ripetuto item per item. Quando c'è, è lui a fare la
	# spiegazione breve e la strategia; l'item resta l'esempio svolto, che è il
	# lavoro per cui va bene.
	var causale := NoraExplanations.voce(subject, topic)
	var item := _sample_item(subject, topic)
	if not item.is_empty():
		# **Niente spiegazione finta.** (15 agosto 2026)
		# Il valore di ripiego era «Concetto di <topic>.», che non spiega niente e
		# occupa il posto di una spiegazione. Meglio vuoto: chi presenta la scheda
		# sa distinguere «non ho niente da dire» da una frase che gira a vuoto, e
		# una sezione senza contenuto non viene proprio costruita.
		var short_text: String = str(item.get("explanation", ""))
		if authored.has("short"):
			short_text = str(authored["short"])
		elif not causale.is_empty():
			short_text = str(causale.get("perche", short_text))
		if not causale.is_empty() and not authored.has("strategy"):
			strategy = str(causale.get("come", strategy))
		var example := {"prompt": str(item.get("prompt", "")), "answer": str(item.get("answer", "")), "explanation": str(item.get("explanation", ""))}
		var typical := _typical_error(item)
		return _entry(subject, topic, int(item.get("difficulty", 1)), short_text, example, typical, strategy)

	# 3) Fallback (topic senza banco né concetto autorato): voce minima ma reale.
	# Stessa regola del ramo sopra: se non c'è una spiegazione vera la voce resta
	# vuota. E l'esempio svolto NON ripete la spiegazione: un esempio senza
	# domanda non è un esempio, ed è ciò che produceva schede in cui sotto
	# «ESEMPIO SVOLTO» compariva solo un «Perché:» che rigirava il titolo.
	var short_fb: String = str(authored.get("short", ""))
	if not authored.has("short") and not causale.is_empty():
		short_fb = str(causale.get("perche", short_fb))
	if not causale.is_empty() and not authored.has("strategy"):
		strategy = str(causale.get("come", strategy))
	# **Prima di arrendersi: la spiegazione può stare nel minigioco.** (15 agosto
	# 2026) Gli argomenti serviti dai minigiochi non stanno nei banchi, quindi
	# `_sample_item` non li trova — ma le loro spec portano spesso una
	# spiegazione causale già scritta e già giocata. Misurato: erano 111 gli
	# argomenti su 245 senza lezione, quasi tutti di qui.
	var da_minigioco := MinigameManager.spiegazione_di_topic(subject, topic)
	if not da_minigioco.is_empty():
		if short_fb.strip_edges() == "":
			short_fb = str(da_minigioco.get("explanation", ""))
		var domanda := str(da_minigioco.get("prompt", ""))
		if domanda != "":
			return _entry(subject, topic, 1, short_fb,
				{"prompt": domanda, "answer": "", "explanation": str(da_minigioco.get("explanation", ""))},
				{"wrong": "", "why": ""}, strategy)
	return _entry(subject, topic, 1, short_fb, {"prompt": "", "answer": "", "explanation": ""}, {"wrong": "", "why": ""}, strategy)

# Errore tipico raccolto da un item a scelta multipla: un distrattore come
# risposta sbagliata plausibile, col perché è sbagliato.
#
# `distractorWhy` (13 agosto 2026: prima lessico italiano/inglese, poi
# declinazioni latine) porta la frase già pronta, calcolata al bake dai dati
# reali dell'item — non testo inventato qui in Godot, e non una sola frase
# uguale per tutti come prima. Ogni generatore la scrive nella lingua giusta
# per la sua materia (un vocabolo "vuol dire", una forma "si scriverebbe").
# Dove manca (materie non ancora coperte) resta la frase generica: meglio
# onesta che finta specifica.
func _typical_error(item: Dictionary) -> Dictionary:
	var answer := str(item.get("answer", ""))
	var why_map: Dictionary = item.get("distractorWhy", {})
	for opt in item.get("options", []):
		var opt_str := str(opt)
		if opt_str != answer:
			if why_map.has(opt_str):
				return {"wrong": opt_str, "why": str(why_map[opt_str])}
			return {"wrong": opt_str, "why": "È un'alternativa plausibile: rileggi il prompt e verifica il significato prima di scegliere."}
	return {"wrong": "", "why": ""}

func _entry(subject: String, topic: String, difficulty: int, short_text: String, example: Dictionary, typical: Dictionary, strategy: String) -> Dictionary:
	return {
		"subject": subject,
		"topic": topic,
		"difficulty": clampi(difficulty, 1, 4),
		"shortExplanation": short_text,
		"example": example,
		"typicalError": typical,
		"noraStrategy": strategy,
	}

# --- Copertura ----------------------------------------------------------------
# Ritorna {ok, missing: Array} — ogni topic del runtime ha una voce non vuota.
func coverage() -> Dictionary:
	var missing: Array = []
	for key in runtime_topics().keys():
		var meta: Dictionary = runtime_topics()[key]
		var entry := entry_for(str(meta["subject"]), str(meta["topic"]))
		if str(entry.get("shortExplanation", "")).strip_edges() == "" or str(entry.get("noraStrategy", "")).strip_edges() == "":
			missing.append(key)
	return {"ok": missing.is_empty(), "missing": missing}

# --- Stato di conoscenza nel save ---------------------------------------------
static func _codex(save) -> Dictionary:
	if not save.data.has("codex"):
		save.data["codex"] = {}
	return save.data["codex"]

static func state_of(save, subject: String, topic: String) -> String:
	return str(_codex(save).get("%s:%s" % [subject, topic], STATE_UNKNOWN))

static func _rank(state: String) -> int:
	var i := STATE_ORDER.find(state)
	return i if i >= 0 else 0

## Come si chiama uno stato quando lo si dice a un bambino di dieci anni.
##
## Gli identificatori interni sono inglesi e vanno benissimo nel codice; nel
## momento in cui una di queste parole compare a schermo deve essere italiana e
## deve dire una cosa che si capisce senza spiegazione. «Applicato» un bambino lo
## capisce; `applied` no.
const STATE_LABELS := {
	STATE_UNKNOWN: "da scoprire",
	STATE_ENCOUNTERED: "incontrato",
	STATE_CONSULTED: "consultato",
	STATE_APPLIED: "applicato",
	STATE_CONSOLIDATED: "consolidato",
}

static func state_label(state: String) -> String:
	return str(STATE_LABELS.get(state, state))

# Fa AVANZARE lo stato (mai regredire) verso il minimo coerente con l'evento:
#   "seen"→incontrato, "consulted"→consultato, "correct"→applicato,
#   "consolidated"→consolidato.
static func advance_state(save, subject: String, topic: String, event: String) -> void:
	var target := STATE_ENCOUNTERED
	match event:
		"seen": target = STATE_ENCOUNTERED
		"consulted": target = STATE_CONSULTED
		"correct": target = STATE_APPLIED
		"consolidated": target = STATE_CONSOLIDATED
		_: target = STATE_ENCOUNTERED
	var key := "%s:%s" % [subject, topic]
	var current := str(_codex(save).get(key, STATE_UNKNOWN))
	if _rank(target) > _rank(current):
		_codex(save)[key] = target

# --- Regole di consultazione --------------------------------------------------
# Durante l'ESAME il manuale è consultabile ma NON rivela la risposta corrente:
# resta la strategia/spiegazione, non l'esempio con la soluzione del nodo in corso.
static func can_reveal_answer(context: String) -> bool:
	return context != "final_exam"

# Voce filtrata per il contesto: in esame nasconde la soluzione dell'esempio.
func entry_for_context(subject: String, topic: String, context: String) -> Dictionary:
	var entry := entry_for(subject, topic)
	if not can_reveal_answer(context):
		var ex: Dictionary = entry.get("example", {}).duplicate(true)
		ex["answer"] = ""
		ex["explanation"] = ""
		entry["example"] = ex
		entry["answerHidden"] = true
	return entry

# --- Insegnamento (playthrough #13: gli esercizi non devono solo interrogare) --
# Una MINI-LEZIONE istruttiva per l'argomento: NORA/atlante SPIEGANO prima di
# chiedere. Assembla la voce in un'unità didattica — intro, spiegazione, esempio
# SVOLTO (con risposta e perché), strategia e trabocchetto da evitare. È la
# conoscenza che il gioco produce, non solo la verifica.
func mini_lesson(subject: String, topic: String) -> Dictionary:
	var entry := entry_for(subject, topic)
	var example: Dictionary = entry.get("example", {})
	var typical: Dictionary = entry.get("typicalError", {})
	var _spiegazione := str(entry.get("shortExplanation", "")).strip_edges()
	return {
		"subject": subject,
		"topic": topic,
		# L'intro esiste solo se c'è qualcosa da introdurre: «Prima di provare,
		# guardiamo insieme:» seguito dal nulla era la forma peggiore di tutte,
		# perché prometteva una spiegazione nella stessa riga in cui non la dava.
		"intro": ("Prima di provare, guardiamo insieme: %s" % _spiegazione)
			if _spiegazione != "" else "",
		"explanation": str(entry.get("shortExplanation", "")),
		"workedExample": example,               # prompt → risposta, con il perché
		"strategy": str(entry.get("noraStrategy", "")),
		"watchOut": typical,                    # errore tipico + perché è sbagliato
	}

## **Questa lezione ha qualcosa da insegnare?** (15 agosto 2026)
##
## Nasce da una segnalazione con schermata: la scheda «NUOVO CONCETTO · NORA
## SPIEGA» diceva «Prima di provare, guardiamo insieme: Concetto di numeri in
## matematica», poi «ESEMPIO SVOLTO» seguito dal nulla, e sotto «Perché: Concetto
## di numeri in matematica» — la stessa frase vuota due volte, con in mezzo il
## titolo di un esempio che non esisteva.
##
## Il danno non è estetico. Una scheda che promette di spiegare e non spiega
## insegna al bambino che le spiegazioni di NORA si saltano, e da quel momento le
## salta **tutte**, comprese quelle scritte bene. Meglio nessuna scheda.
##
## La sostanza è **una spiegazione vera o un esempio con la sua domanda**. La
## strategia da sola non basta: «nomina il vincolo, poi fai un passaggio alla
## volta» è un buon promemoria accanto a un contenuto, e un guscio da solo.
static func lezione_ha_sostanza(lesson: Dictionary) -> bool:
	if lesson.is_empty():
		return false
	if str(lesson.get("explanation", "")).strip_edges() != "":
		return true
	var esempio: Dictionary = lesson.get("workedExample", {})
	return str(esempio.get("prompt", "")).strip_edges() != ""

# Momento d'insegnamento quando si AVVIA un esercizio su questo argomento:
#   "pre_teach"  → primo incontro assoluto: NORA insegna prima di chiedere;
#   "re_teach"   → errore ricorrente (già sbagliato e di nuovo dovuto): si rivede;
#   "none"       → già applicato e non arretrato: l'atlante resta consultabile.
static func teaching_moment(save, subject: String, topic: String) -> String:
	var key := "%s:%s" % [subject, topic]
	var sr: Dictionary = save.data.get("spacedRepetition", {})
	var schedule: Dictionary = sr.get("schedule", {})
	var clock := int(sr.get("sessionClock", 0))
	if schedule.has(key):
		var e: Dictionary = schedule[key]
		if int(e.get("lapses", 0)) >= 1 and int(e.get("dueAt", 0)) <= clock:
			return "re_teach"
	if state_of(save, subject, topic) == STATE_UNKNOWN:
		return "pre_teach"
	return "none"

# Frase con cui NORA introduce il momento d'insegnamento (distinta dai messaggi
# di sistema e dal prompt dell'esercizio).
static func teach_line(moment: String) -> String:
	match moment:
		"pre_teach":
			return "Nuovo concetto: te lo spiego prima di metterti alla prova. Imparare viene prima di rispondere."
		"re_teach":
			return "Questo ti è già sfuggito una volta: rivediamolo insieme, poi riprovi con un metodo in più."
		_:
			return ""
