extends SceneTree

## **La guardia della regola delle dispense.** (11 settembre 2026)
##
## Regola di progetto in `docs/REGOLA_DISPENSE.md`, richiesta del committente:
## «le prove devono essere applicazioni che lo studente deve fare di concetti
## spiegati. La spiegazione di poche frasi di NORA non è sufficiente.»
##
## Le tre guardie che esistevano già rispondono tutte alla domanda «il bambino ha
## VISTO questa cosa almeno una volta?»: `teach_before_ask_audit` per l'argomento,
## `fact_level_teaching_audit` per il fatto pescato, `tavole_riferimento_audit`
## per la risposta-nome. Nessuna risponde a «gli è stata INSEGNATA?», e la
## differenza è misurata: la scheda che NORA mostra spiega con **290 caratteri**
## in media su tutti e 300 gli argomenti del runtime.
##
## Qui si controllano cinque cose, in ordine di quanto costa ripararle:
##
##   1. **la copertura** — ogni coppia (argomento, fascia) che il banco interroga
##      ha una dispensa che la copre. Il debito delle materie non ancora
##      convertite sta nel tetto qui sotto, e il tetto si abbassa e mai si alza;
##   2. **la sostanza** — ogni dispensa supera i minimi di `Dispense`;
##   3. **il legame** — ogni item che dichiara `applica` punta a una dispensa che
##      esiste, dello stesso argomento, e la cui banda non viene DOPO la fascia
##      dell'item: non si applica una lezione non ancora arrivata;
##   4. **il vocabolario** — nessuna notazione compare in una domanda prima che
##      una dispensa l'abbia introdotta;
##   5. **il percorso** — giocando davvero, la dispensa arriva davanti alla prima
##      domanda che la applica.
##
## Uso: godot --headless --path godot --script res://scripts/game/dispense_audit.gd

const VERDE := "DISPENSE audit VERDE"

## **Il registro del debito.** Quanti argomenti di una materia possono ancora
## restare senza dispensa. Coding è la prima materia convertita e sta a zero; per
## le altre il numero è quello misurato il giorno in cui la regola è stata
## fissata, e da lì può solo scendere.
##
## **Alzare un tetto per far passare una build è il solo modo di rendere questa
## regola una decorazione.** Stessa disciplina del tetto di
## `bank_scorciatoie_audit`: si paga una materia alla volta, e il numero nuovo si
## scrive solo dopo averlo misurato.
const TETTO_ARGOMENTI_SCOPERTI := {
	"coding": 0,
	"matematica": 34,
	"italiano": 30,
	"inglese": 47,
	# Quarta materia convertita, 11 settembre 2026: ventidue dispense.
	"latino": 0,
	# Seconda materia convertita, 11 settembre 2026: diciassette dispense.
	"storia": 0,
	# Terza materia convertita, 11 settembre 2026: sedici dispense.
	"geografia": 0,
	# Quinta materia convertita, 11 settembre 2026: sedici dispense.
	"scienze": 0,
	"fisica": 12,
	"elettronica": 8,
	"logica": 6,
	"musica": 8,
}

## **Il tetto del vocabolario non dichiarato**, per materia. Gli item scritti
## prima della regola non portano `applica`: su di loro il controllo 4 non può
## essere un rosso, ma può essere un numero che scende. Zero significa «questa
## materia non usa nessuna notazione che nessuna dispensa abbia introdotto».
const TETTO_NOTAZIONI_NON_INSEGNATE := {
	"coding": 0,
}

## Quante sessioni per livello nel controllo del percorso.
const SESSIONI := 12

## **Le notazioni che un bambino non può dedurre.** Una per riga, e nessuna è una
## parola italiana: sono simboli, o parole seguite da una parentesi, o parole
## inglesi che in italiano non esistono. È la differenza che ha fatto fallire il
## primo tentativo — cercando `in`, `del` e `continue` come parole si trovavano
## centinaia di falsi allarmi dentro la prosa italiana delle domande.
const NOTAZIONI := [
	# funzioni e metodi: la parentesi aperta li rende inconfondibili
	"print(", "input(", "int(", "str(", "float(", "bool(", "list(", "len(",
	"range(", "sum(", "max(", "min(", "abs(", "round(", "sorted(", "type(",
	".append(", ".split(", ".join(", ".strip(", ".replace(", ".upper(",
	".lower(", ".sort(", ".isdigit(", ".count(", ".index(", ".pop(",
	".insert(", ".remove(", ".reverse(",
	# operatori composti
	"//", "**", "==", "!=", ">=", "<=", "+=", "-=", "*=",
	# argomenti con nome e formati
	"reverse=True", "end=", "sep=", ":.2f",
	# parole del linguaggio che l'italiano non ha
	"for ", "while ", "elif ", "else:", "def ", "return", "break",
	"True", "False", "None",
]

## `%` va cercato solo nel codice: nella prosa italiana compare come segno di
## percentuale. Stessa ragione per `/`, che nelle domande fa da barra normale.
const NOTAZIONI_SOLO_NEL_CODICE := ["%", "/"]

## **Le materie in cui la risposta si IMPARA invece di calcolarla.** (11 settembre
## 2026, con storia)
##
## Il controllo 4b — la risposta di richiamo deve comparire nel testo della
## dispensa — vale solo qui, e la ragione è la differenza fra due tipi di domanda.
## In storia «chi fondò Roma secondo la leggenda?» ha una risposta che si può solo
## aver letta: se il documento non dice «Romolo», la domanda è impossibile, ed è
## esattamente quella che il committente ha chiesto di non scrivere.
##
## In coding invece la risposta è il RISULTATO di un procedimento: alla domanda
## «che cosa stampa print("sala" + "nord")» si risponde «salanord», una parola che
## in nessuna dispensa comparirà mai, né deve. Pretendere che ci sia vorrebbe dire
## vietare di chiedere qualunque cosa nuova, cioè vietare gli esercizi.
##
## La distinzione non è per materia per comodità: è che in storia l'oggetto da
## imparare è il fatto, in coding è il metodo. L'elenco cresce con geografia e
## latino, che hanno la stessa forma (vedi `tavole_riferimento_audit`).
const MATERIE_DI_RICHIAMO := ["storia", "geografia", "latino", "scienze"]

var errori: Array = []
var misure: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 40:
		errori.append(messaggio)

func _init() -> void:
	_la_copertura()
	_la_sostanza()
	_il_legame()
	_il_vocabolario()
	_la_risposta_sta_nel_documento()
	_il_percorso()

	for riga in misure:
		print("  %s" % str(riga))
	if errori.is_empty():
		print(VERDE)
	else:
		printerr("DISPENSE audit ROSSO — %d problemi:" % errori.size())
		for e in errori:
			printerr("  - %s" % str(e))
	quit(0 if errori.is_empty() else 1)

# --- 1. la copertura -----------------------------------------------------------

func _la_copertura() -> void:
	var content := ContentManager.new()
	for materia_data in ApparatusConfig.SUBJECT_CYCLE:
		var materia := str(materia_data)
		var argomenti: Array = content.bank_topics(materia)
		if argomenti.is_empty():
			continue
		var coperti: Array = Dispense.argomenti_coperti(materia)
		var scoperti: Array = []
		for topic_data in argomenti:
			if not coperti.has(str(topic_data)):
				scoperti.append(str(topic_data))
		var tetto := int(TETTO_ARGOMENTI_SCOPERTI.get(materia, 0))
		misure.append("%s · argomenti senza dispensa: %d su %d (tetto %d)" % [
			materia, scoperti.size(), argomenti.size(), tetto])
		if scoperti.size() > tetto:
			_fallisci("%s: %d argomenti senza dispensa, il tetto e' %d — %s" % [
				materia, scoperti.size(), tetto, ", ".join(PackedStringArray(scoperti.slice(0, 6)))])
		# **Un tetto che non scende mai non serve a niente.** Se il debito è già
		# stato pagato, il tetto va riscritto nello stesso commit: lasciarlo alto
		# permette a un contenuto nuovo di rientrare nel debito senza accorgersene.
		if scoperti.size() < tetto:
			_fallisci("%s: gli argomenti senza dispensa sono scesi a %d, il tetto e' rimasto a %d — abbassalo" % [
				materia, scoperti.size(), tetto])
		# La copertura per FASCIA: un argomento con la sola banda bassa lascia
		# scoperte le fasce alte, e sarebbe passato guardando i soli argomenti.
		for topic_data2 in argomenti:
			var topic := str(topic_data2)
			if not coperti.has(topic):
				continue
			for fascia in range(1, 9):
				if not _il_banco_interroga(content, materia, topic, fascia):
					continue
				if Dispense.per_argomento(materia, topic, fascia).is_empty():
					_fallisci("%s:%s fascia %d: il banco interroga ma nessuna dispensa copre quella fascia" % [
						materia, topic, fascia])

func _il_banco_interroga(content: ContentManager, materia: String, topic: String, fascia: int) -> bool:
	for raw in content._load_bank(materia):
		var item: Dictionary = raw
		if str(item.get("topic", "")) == topic and int(item.get("difficulty", 1)) == fascia:
			return true
	return false

# --- 2. la sostanza ------------------------------------------------------------

func _la_sostanza() -> void:
	var piu_corta := 99999
	var totale := 0
	for id in Dispense.DISPENSE.keys():
		var d: Dictionary = Dispense.DISPENSE[id]
		for problema in Dispense.problemi_di_sostanza(str(id), d):
			_fallisci(str(problema))
		var lunghezza := Dispense.lunghezza_sezioni(d)
		piu_corta = min(piu_corta, lunghezza)
		totale += lunghezza
	var quante: int = Dispense.DISPENSE.size()
	if quante > 0:
		misure.append("dispense scritte: %d · sezioni, media %d caratteri, la piu' corta %d (minimo %d)" % [
			quante, totale / quante, piu_corta, Dispense.MINIMO_SEZIONI])

# --- 3. il legame --------------------------------------------------------------

func _il_legame() -> void:
	var content := ContentManager.new()
	var applicano := 0
	var applicati: Dictionary = {}
	for materia_data in ApparatusConfig.SUBJECT_CYCLE:
		var materia := str(materia_data)
		for raw in content._load_bank(materia):
			var item: Dictionary = raw
			var id_dispensa := str(item.get("applica", "")).strip_edges()
			if id_dispensa == "":
				continue
			applicano += 1
			applicati[id_dispensa] = true
			var d := Dispense.per_id(id_dispensa)
			if d.is_empty():
				_fallisci("%s: applica «%s», che non esiste" % [str(item.get("id", "")), id_dispensa])
				continue
			if str(d.get("subject", "")) != materia or str(d.get("topic", "")) != str(item.get("topic", "")):
				_fallisci("%s: applica «%s», che parla di %s:%s" % [
					str(item.get("id", "")), id_dispensa,
					str(d.get("subject", "")), str(d.get("topic", ""))])
				continue
			var fasce: Array = d.get("fasce", [])
			var fascia := int(item.get("difficulty", 1))
			if fasce.size() == 2 and int(fasce[0]) > fascia:
				_fallisci("%s sta alla fascia %d e applica «%s», che comincia alla %d: la lezione arriva dopo la domanda" % [
					str(item.get("id", "")), fascia, id_dispensa, int(fasce[0])])
	misure.append("item che dichiarano `applica`: %d, su %d dispense diverse" % [applicano, applicati.size()])
	# **Una dispensa che nessuno applica è contenuto scritto e mai collegato**, il
	# difetto ricorrente di questo progetto. Non è un rosso finché la materia sta
	# nel debito — gli item vecchi non dichiarano niente — ma va misurato.
	var orfane: Array = []
	for id in Dispense.DISPENSE.keys():
		if not applicati.has(str(id)):
			orfane.append(str(id))
	if not orfane.is_empty():
		misure.append("dispense che nessun item dichiara di applicare: %d" % orfane.size())

# --- 4. il vocabolario ---------------------------------------------------------

## **Il vocabolario si unisce per MATERIA, non per argomento.** Una domanda sui
## cicli stampa, e `print(` è introdotto dalla dispensa delle variabili: chiedere
## che ogni notazione stia nella dispensa del SUO argomento avrebbe prodotto
## trecento rossi e nessuna informazione. Quello che questo controllo garantisce
## è l'altra cosa, e conta davvero: **nessuna notazione compare a una fascia
## prima di quella in cui una dispensa la introduce.** Una domanda di fascia 2
## che mostra `sorted(` — introdotto dalla banda alta delle liste — è esattamente
## la domanda che il committente ha chiesto di non scrivere.
func _il_vocabolario() -> void:
	var content := ContentManager.new()
	for materia_data in ApparatusConfig.SUBJECT_CYCLE:
		var materia := str(materia_data)
		if Dispense.argomenti_coperti(materia).is_empty():
			continue
		# **Una materia che non dichiara nessuna notazione non va scandita.**
		# (11 settembre 2026, con storia) Il catalogo qui sopra è di simboli e
		# parole del Python; le dispense di storia dichiarano «feudalesimo» e
		# «pòlis», che non ci compaiono. Scandire storia lo stesso produrrebbe
		# solo falsi allarmi — una domanda con una parentesi diventa una «riga di
		# codice» e un `/` fra due date basta ad accenderla. Per storia il
		# controllo che conta è il 4b, qui sotto.
		if not _dichiara_notazioni(materia):
			continue
		var fuori: Dictionary = {}
		var fuori_dichiarati := 0
		for raw in content._load_bank(materia):
			var item: Dictionary = raw
			var fascia := int(item.get("difficulty", 1))
			var ammesse := _vocabolario_di_materia(materia, fascia)
			var testo := _testo_interrogato(item)
			var righe_di_codice := _righe_di_codice(testo)
			for notazione_data in NOTAZIONI:
				var notazione := str(notazione_data)
				if not testo.contains(notazione):
					continue
				if ammesse.has(notazione):
					continue
				_segnala_notazione(item, materia, notazione, fascia, fuori)
				if str(item.get("applica", "")).strip_edges() != "":
					fuori_dichiarati += 1
			for notazione_data2 in NOTAZIONI_SOLO_NEL_CODICE:
				var notazione2 := str(notazione_data2)
				if not righe_di_codice.contains(notazione2):
					continue
				if ammesse.has(notazione2):
					continue
				_segnala_notazione(item, materia, notazione2, fascia, fuori)
				if str(item.get("applica", "")).strip_edges() != "":
					fuori_dichiarati += 1
		var tetto := int(TETTO_NOTAZIONI_NON_INSEGNATE.get(materia, 0))
		misure.append("%s · notazioni usate prima di essere insegnate: %d (tetto %d)" % [
			materia, fuori.size(), tetto])
		for chiave in fuori.keys():
			misure.append("    %s" % str(fuori[chiave]))
		# Su un item che DICHIARA la sua dispensa non c'è tetto che tenga: quello
		# è contenuto scritto sotto la regola, e la regola dice che deve applicare
		# ciò che è stato spiegato.
		if fuori_dichiarati > 0:
			_fallisci("%s: %d notazioni non insegnate dentro item che dichiarano `applica` — lì il tetto non vale" % [
				materia, fuori_dichiarati])
		if fuori.size() > tetto:
			_fallisci("%s: %d notazioni usate prima di essere insegnate, il tetto e' %d" % [
				materia, fuori.size(), tetto])
		if fuori.size() < tetto:
			_fallisci("%s: le notazioni non insegnate sono scese a %d, il tetto e' rimasto a %d — abbassalo" % [
				materia, fuori.size(), tetto])

func _segnala_notazione(item: Dictionary, materia: String, notazione: String, fascia: int, fuori: Dictionary) -> void:
	var chiave := "%s|%s|%d" % [materia, notazione, fascia]
	if fuori.has(chiave):
		return
	fuori[chiave] = "«%s» alla fascia %d (%s:%s, es. %s)" % [
		notazione, fascia, materia, str(item.get("topic", "")), str(item.get("id", ""))]

## Vero se almeno una voce di `insegna` di questa materia sta nel catalogo delle
## notazioni. È il modo di dire «questa materia ha una notazione da insegnare»
## senza scriverne l'elenco una seconda volta.
func _dichiara_notazioni(materia: String) -> bool:
	for voce_data in _vocabolario_di_materia(materia, 8):
		var voce := str(voce_data)
		if NOTAZIONI.has(voce) or NOTAZIONI_SOLO_NEL_CODICE.has(voce):
			return true
	return false

## L'unione delle notazioni che le dispense della materia hanno introdotto fino a
## questa fascia compresa.
func _vocabolario_di_materia(materia: String, fascia: int) -> Array:
	var out: Array = []
	for id in Dispense.DISPENSE.keys():
		var d: Dictionary = Dispense.DISPENSE[id]
		if str(d.get("subject", "")) != materia:
			continue
		var fasce: Array = d.get("fasce", [])
		if fasce.size() != 2 or int(fasce[0]) > fascia:
			continue
		for voce in d.get("insegna", []):
			if not out.has(str(voce)):
				out.append(str(voce))
	return out

## Tutto ciò che il bambino legge prima di rispondere: la domanda e le alternative.
## La spiegazione NON entra: arriva dopo, e può nominare cose nuove apposta.
func _testo_interrogato(item: Dictionary) -> String:
	var pezzi: Array = [str(item.get("prompt", ""))]
	for opzione in item.get("options", []):
		pezzi.append(str(opzione))
	pezzi.append(str(item.get("answer", "")))
	return "\n".join(PackedStringArray(pezzi))

## Le sole righe che sembrano codice. Serve per i due segni che in italiano hanno
## un altro mestiere: `%` come percentuale e `/` come barra.
func _righe_di_codice(testo: String) -> String:
	var tenute: Array = []
	for riga_data in testo.split("\n"):
		var riga := str(riga_data)
		var nuda := riga.strip_edges()
		if nuda == "":
			continue
		var rientrata := riga.begins_with("    ") or riga.begins_with("\t")
		var assegna := nuda.contains("=") and not nuda.contains(" e ") and not nuda.contains(" la ")
		var chiama := nuda.contains("(") and nuda.contains(")")
		if rientrata or assegna or chiama or nuda.ends_with(":"):
			tenute.append(riga)
	return "\n".join(PackedStringArray(tenute))

# --- 4b. la risposta sta nel documento -----------------------------------------

## **«Solo dopo si può fare una domanda.»** (11 settembre 2026)
##
## È la frase della richiesta, tradotta in una misura. Nelle materie di richiamo
## una domanda che chiede un NOME è rispondibile solo da chi quel nome lo ha
## letto: se la dispensa dichiarata non lo contiene, la domanda è impossibile per
## costruzione, e nessuna delle altre guardie se ne accorge — `teach_before_ask`
## vede una lezione, `tavole_riferimento` vede una tavola, e nessuna delle due
## guarda se la risposta ci sia davvero dentro.
##
## Chi decide che una domanda è «di richiamo» è `KnowledgeCodex.recall_fact`, la
## stessa regola che usa il runtime: non una regola nuova inventata qui.
##
## Il confronto è sul testo INTERO della dispensa — sezioni, glossario, esempi,
## apertura — perché il bambino legge tutto, non solo le sezioni.
func _la_risposta_sta_nel_documento() -> void:
	var content := ContentManager.new()
	for materia_data in MATERIE_DI_RICHIAMO:
		var materia := str(materia_data)
		var controllati := 0
		var dentro := 0
		for raw in content._load_bank(materia):
			var item: Dictionary = raw
			var id_dispensa := str(item.get("applica", "")).strip_edges()
			if id_dispensa == "":
				continue
			var richiamo := KnowledgeCodex.recall_fact(item)
			if richiamo.is_empty():
				continue
			var d := Dispense.per_id(id_dispensa)
			if d.is_empty():
				continue
			controllati += 1
			var etichetta := str(richiamo.get("label", ""))
			# Il giudizio sta in `Dispense.insegna_la_risposta`, non qui: lo usa
			# anche `tavole_riferimento_audit` per accettare una dispensa al posto
			# di una tavola, e due copie della stessa regola prima o poi divergono.
			# Comprende il caso della risposta costruita con una `regola`: «XIII
			# secolo» non compare in nessun documento e non deve comparire.
			if Dispense.insegna_la_risposta(id_dispensa, etichetta):
				dentro += 1
				continue
			_fallisci("%s chiede «%s» e la sua dispensa «%s» non lo dice da nessuna parte" % [
				str(item.get("id", "")), etichetta, id_dispensa])
		if controllati > 0:
			misure.append("%s · risposte di richiamo che stanno nel documento: %d/%d" % [
				materia, dentro, controllati])

# --- 5. il percorso ------------------------------------------------------------

## Il materiale può essere perfetto e non arrivare: è il difetto ricorrente del
## progetto — contenuto scritto e mai collegato. Qui si gioca davvero.
func _il_percorso() -> void:
	var gameplay := OutdoorGameplay.new()
	gameplay.content_manager = ContentManager.new()
	gameplay.game_save = GameSaveManager.new("user://dispense-audit.json")
	var con_dispensa := 0
	var senza_dispensa := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var subject := str(ApparatusConfig.world_subject(level))
		if Dispense.argomenti_coperti(subject).is_empty():
			continue
		for giro in range(SESSIONI):
			# Seme dichiarato: un audit che sorteggia a caso è verde stamattina e
			# rosso stasera senza che nessuno abbia toccato niente.
			var rng := RandomNumberGenerator.new()
			rng.seed = 7700 + level * 131 + giro
			var sessione: Dictionary = gameplay.content_manager.build_varied_mission(
				subject, level, 3, {}, rng,
				gameplay.game_save.mastery_of(subject),
				gameplay.game_save.topic_masteries(subject))
			var nodi: Array = sessione.get("nodes", [])
			if nodi.is_empty():
				continue
			# Chi era nuovo PRIMA della decorazione: dopo, la decorazione stessa
			# ha già segnato l'argomento come incontrato.
			var attesi: Array = []
			var visti_qui: Dictionary = {}
			for indice in range(nodi.size()):
				var nodo: Dictionary = nodi[indice]
				var topic := str(nodo.get("topic", ""))
				if visti_qui.has(topic):
					continue
				visti_qui[topic] = true
				if KnowledgeCodex.teaching_moment(gameplay.game_save, subject, topic) == "none":
					continue
				if Dispense.per_argomento(subject, topic, int(nodo.get("difficulty", 1))).is_empty():
					continue
				attesi.append({"indice": indice, "topic": topic})
			sessione = gameplay._decorate_teaching_session(sessione, subject)
			var decorati: Array = sessione.get("nodes", [])
			for atteso_data in attesi:
				var atteso: Dictionary = atteso_data
				var decorato: Dictionary = decorati[int(atteso["indice"])]
				var lezione: Dictionary = decorato.get("teachingLesson", {})
				if str(lezione.get("dispensaId", "")) != "":
					con_dispensa += 1
					continue
				senza_dispensa += 1
				_fallisci("%s livello %d · «%s»: primo incontro senza la sua dispensa davanti" % [
					subject, level, str(atteso["topic"])])
	var totale := con_dispensa + senza_dispensa
	if totale > 0:
		misure.append("percorso giocato · primi incontri aperti da una dispensa: %d/%d (%.1f%%)" % [
			con_dispensa, totale, 100.0 * float(con_dispensa) / float(totale)])
	else:
		_fallisci("percorso giocato: nessun primo incontro misurato, il controllo non ha verificato niente")
