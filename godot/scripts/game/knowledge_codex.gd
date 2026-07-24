class_name KnowledgeCodex
extends RefCounted

## Manuale NORA (O-P4): una voce (`ConceptEntry`) per ogni argomento del runtime.
## Ogni voce ha spiegazione breve, esempio svolto, errore tipico (e perché è
## sbagliato) e strategia suggerita da NORA. Per non autorare a mano ~120 topic,
## le voci dei banchi sono RACCOLTE dal contenuto reale (ogni item porta già una
## spiegazione causale); i concetti matematici generati e i topic-cardine dei
## primi mondi sono autorati con più cura.
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
	"tabelline": {"short": "Moltiplicare è contare gruppi uguali: 4×3 sono quattro gruppi da tre.", "example": "6 × 7 = 42", "error": "Sommare invece di moltiplicare (6+7=13).", "why": "La moltiplicazione ripete un gruppo, non lo aggiunge una volta sola."},
	"calcolo": {"short": "Un passo alla volta, rispettando l'ordine delle operazioni.", "example": "12 + 3 × 2 = 12 + 6 = 18", "error": "Fare 12+3 prima di 3×2.", "why": "Moltiplicazioni e divisioni vengono prima di somme e sottrazioni."},
	"divisioni": "Dividere è distribuire in parti uguali o vedere quante volte una quantità sta in un'altra.",
	"frazioni": "Una frazione indica parti di un intero: il denominatore quante parti, il numeratore quante ne prendi.",
	"percentuali": "La percentuale è una frazione su 100: 25% significa 25 ogni 100.",
	"proporzioni": "Una proporzione mette in relazione due rapporti uguali: a sta a b come c sta a d.",
	"potenze": "Una potenza è una moltiplicazione ripetuta: 2³ = 2×2×2.",
	"radici": "La radice è l'operazione inversa della potenza: √9 = 3 perché 3² = 9.",
	"espressioni": "Un'espressione si risolve rispettando parentesi e ordine delle operazioni.",
	"equazioni": "In un'equazione cerchi il valore che rende vera l'uguaglianza, mantenendo l'equilibrio.",
	"geometria": "Le figure hanno proprietà misurabili: perimetro, area, angoli.",
	"coordinate": "Un punto sul piano si individua con due numeri: ascissa e ordinata.",
	"sequenze": "In una sequenza cerchi la regola che genera i termini successivi.",
	"dati": "I dati si organizzano e si leggono per rispondere a una domanda.",
	"statistica": "Media, moda e mediana riassumono un insieme di dati.",
	"problemi": "In un problema traduci le parole in operazioni: cosa sai, cosa cerchi, come li leghi.",
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
func runtime_topics() -> Dictionary:
	var out: Dictionary = {}  # "subject:topic" -> {subject, topic}
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		for topic in content.bank_topics(str(subject)):
			out[_key(str(subject), str(topic))] = {"subject": str(subject), "topic": str(topic)}
	for topic in MATH_CONCEPTS.keys():
		out[_key("matematica", str(topic))] = {"subject": "matematica", "topic": str(topic)}
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
		return _entry(subject, topic, 1, short_text, {"prompt": "", "answer": example, "explanation": short_text}, {"wrong": err, "why": why}, strategy)

	# 2) Raccolta dal banco: usa l'item più semplice come esempio svolto.
	var item := _sample_item(subject, topic)
	if not item.is_empty():
		var short_text: String = str(authored.get("short", "")) if authored.has("short") else str(item.get("explanation", "Concetto di %s." % topic))
		var example := {"prompt": str(item.get("prompt", "")), "answer": str(item.get("answer", "")), "explanation": str(item.get("explanation", ""))}
		var typical := _typical_error(item)
		return _entry(subject, topic, int(item.get("difficulty", 1)), short_text, example, typical, strategy)

	# 3) Fallback (topic senza banco né concetto autorato): voce minima ma reale.
	var short_fb: String = str(authored.get("short", "Concetto di %s in %s." % [topic, subject]))
	return _entry(subject, topic, 1, short_fb, {"prompt": "", "answer": "", "explanation": short_fb}, {"wrong": "", "why": ""}, strategy)

# Errore tipico raccolto da un item a scelta multipla: un distrattore come
# risposta sbagliata plausibile, col perché è sbagliato.
func _typical_error(item: Dictionary) -> Dictionary:
	var answer := str(item.get("answer", ""))
	for opt in item.get("options", []):
		if str(opt) != answer:
			return {"wrong": str(opt), "why": "È un'alternativa plausibile: rileggi il prompt e verifica il significato prima di scegliere."}
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
	return {
		"subject": subject,
		"topic": topic,
		"intro": "Prima di provare, guardiamo insieme: %s" % str(entry.get("shortExplanation", "")),
		"explanation": str(entry.get("shortExplanation", "")),
		"workedExample": example,               # prompt → risposta, con il perché
		"strategy": str(entry.get("noraStrategy", "")),
		"watchOut": typical,                    # errore tipico + perché è sbagliato
	}

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
