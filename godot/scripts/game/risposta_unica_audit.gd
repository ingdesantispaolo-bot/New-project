extends SceneTree

## **Una domanda, una risposta. Se le risposte giuste sono due, si tira a caso.**
## (24 agosto 2026)
##
## Nasce da due segnalazioni fatte giocando, nello stesso messaggio:
##
##   1. *«Nel coding i segnali di ingresso e di uscita possono essere fraintesi:
##      rispetto a cosa si deve considerare?»* — lo smistamento chiedeva «il dato
##      entra o esce?» senza dire **rispetto a che cosa**. «Chiedere il nome a chi
##      gioca» è un ingresso per il programma e un'uscita per chi legge la domanda
##      a schermo: due risposte difendibili, e la tessera non diceva quale dei due
##      momenti stesse nominando.
##
##   2. *«In italiano possono esserci soluzioni doppie: crisi è singolare o
##      plurale? entrambi, e lo studente tira a caso.»* — lo smistamento
##      singolare/plurale conteneva tre nomi INVARIABILI nudi (città, crisi,
##      specie). La spiegazione dello stesso esercizio diceva già «resta
##      l'articolo a dirlo», ma l'articolo sulla tessera non c'era.
##
## Cercando la stessa forma altrove ne è uscita una terza, che nessuno aveva
## segnalato perché **non si vede**: il correttore normalizza la risposta digitata
## (maiuscole, virgola decimale, zeri finali) e accettava per giuste anche le
## opzioni che quella normalizzazione cancella. `s.upper()` non assegnato lascia
## `'ciao'`, e premere «CIAO» — il distrattore che contiene proprio l'errore da
## capire — veniva contato giusto. Idem «5» contro «5.0» e «4,5» contro «4.5».
##
## Le quattro regole qui sotto sono le tre forme del difetto più il vincolo che
## le tiene insieme. Non misurano il gusto: misurano se esiste più di una
## risposta accettata.
##
## Uso: godot --headless --path godot --script res://scripts/game/risposta_unica_audit.gd

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

const OK := "RISPOSTA UNICA audit VERDE"

## I formati in cui il bambino SCRIVE la risposta: lì il confronto passa dalla
## normalizzazione, e un distrattore che vi si perde dentro diventa una seconda
## risposta giusta.
const LIBERI := ["numeric_input", "short_answer", "free_text"]

## Nomi italiani che non cambiano forma al plurale. Da soli non dicono il numero:
## in uno smistamento singolare/plurale devono arrivare con l'articolo, che è poi
## esattamente ciò che l'esercizio insegna.
const INVARIABILI := [
	"città", "crisi", "specie", "serie", "analisi", "ipotesi", "tesi", "sintesi",
	"virtù", "gioventù", "caffè", "tè", "re", "gru", "brindisi", "bar", "film",
	"sport", "computer", "gorilla", "vaglia", "euro", "sosia", "boia",
]

## Categorie il cui nome, da solo, indica un VERSO e non una classe: dicono «da
## che parte», e da che parte dipende da dove si guarda. Una prova che le usa
## deve dichiarare il punto di riferimento — nella consegna o nel nome stesso
## del bidone.
const VERSI_RELATIVI := [
	"entra", "esce", "entrata", "uscita", "ingresso", "dentro", "fuori",
	"sopra", "sotto", "destra", "sinistra", "avanti", "indietro",
]

## Formule che dichiarano il punto di riferimento in modo esplicito.
const RIFERIMENTO_DICHIARATO := ["rispetto a", "dal punto di vista"]

## L'unico riempimento a testo libero che NON può nominare il verbo: la risposta
## è l'infinito stesso («non fare rumore»), quindi scriverlo nella consegna
## significherebbe regalarla. Resta senza ambiguità per un'altra via — «rumore»
## non si fa con nessun altro verbo — ed è per questo che l'eccezione sta scritta
## qui, con il motivo, invece di allentare la regola per tutti.
const RIEMPIMENTI_SENZA_LEMMA := [
	"italiano-imperativo-infinito-participio-gerundio-non-rumore-quale-forma-e-l-imperativo-negativo-5",
]

func _init() -> void:
	var failures: Array = []
	failures.append_array(_banchi_risposta_libera_correggibile())
	failures.append_array(_riempimenti_nominano_il_verbo())
	failures.append_array(_smistamenti_singolare_plurale())
	failures.append_array(_smistamenti_con_verso_dichiarano_il_riferimento())

	if failures.is_empty():
		print("\n%s — nessuna prova con due risposte accettate" % OK)
		quit(0)
	else:
		print("\nRISPOSTA UNICA ROSSA — %d problemi:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		quit(1)

## REGOLA 1 — un distrattore che il correttore accetta non è un distrattore.
##
## Vale solo per la risposta libera: lì si digita, e il confronto normalizza. La
## scelta multipla si tocca e Godot la confronta esatta, quindi «ciao» contro
## «CIAO» fra le opzioni è una distinzione vera e va tenuta.
func _banchi_risposta_libera_correggibile() -> Array:
	var failures: Array = []
	var cm := ContentManager.new()
	var esaminati := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			if not LIBERI.has(str(item.get("format", "multiple_choice"))):
				continue
			esaminati += 1
			var risposta := str(item.get("answer", ""))
			var alternative: Array = []
			alternative.append_array(Array(item.get("options", [])))
			alternative.append_array(Dictionary(item.get("distractorWhy", {})).keys())
			for alt in alternative:
				if str(alt) == risposta:
					continue
				if ExerciseInteraction.answer_accepted(str(alt), item):
					failures.append(
						"%s / %s: il distrattore «%s» viene accettato come la risposta «%s» — senza opzioni la domanda non si può correggere" % [
							subject, str(item.get("id", "?")), str(alt), risposta])
	print("Regola 1 — distrattori accettati: %d item a risposta libera esaminati" % esaminati)
	return failures

## REGOLA 2 — un riempimento a testo libero deve dire QUALE parola va nel buco.
##
## «Ieri Marta ___ al parco» non chiede una forma verbale: chiede di indovinare
## il verbo che aveva in mente chi ha scritto la domanda. Andò, andava, è andata,
## corse, giocò: tutte completano la frase, una sola è segnata giusta. Nominare
## il verbo fra virgolette basse riporta la prova a quello che voleva misurare —
## la forma, non la fortuna.
func _riempimenti_nominano_il_verbo() -> Array:
	var failures: Array = []
	var cm := ContentManager.new()
	var esaminati := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for entry in cm._load_bank(subject):
			var item := entry as Dictionary
			if not LIBERI.has(str(item.get("format", "multiple_choice"))):
				continue
			var prompt := str(item.get("prompt", ""))
			if not prompt.contains("___"):
				continue
			esaminati += 1
			var id := str(item.get("id", "?"))
			if RIEMPIMENTI_SENZA_LEMMA.has(id):
				continue
			# La parola bersaglio si dichiara fra virgolette basse, come già fa
			# tutto il resto del banco quando cita una parola invece di usarla.
			# Non basta che le virgolette ci siano: la frase con il buco sta già
			# fra virgolette. Serve una citazione SEPARATA, cioè una che il buco
			# non ce l'ha dentro.
			var cita_il_bersaglio := false
			var resto := prompt
			while true:
				var apre := resto.find("«")
				if apre < 0:
					break
				var chiude := resto.find("»", apre + 1)
				if chiude < 0:
					break
				var citazione := resto.substr(apre + 1, chiude - apre - 1)
				if not citazione.contains("___") and citazione.strip_edges() != "":
					cita_il_bersaglio = true
					break
				resto = resto.substr(chiude + 1)
			if not cita_il_bersaglio:
				failures.append(
					"%s / %s: riempimento senza il verbo dichiarato — «%s» ha più di una forma che completa la frase" % [
						subject, id, prompt])
	print("Regola 2 — riempimenti a testo libero: %d esaminati" % esaminati)
	return failures

## REGOLA 3 — nessun nome invariabile nudo in uno smistamento singolare/plurale.
func _smistamenti_singolare_plurale() -> Array:
	var failures: Array = []
	var esaminati := 0
	for subject_data in MinigameManager.CLASSIFICATION.keys():
		var subject := str(subject_data)
		for spec_data in Array(MinigameManager.CLASSIFICATION[subject_data]):
			var spec := spec_data as Dictionary
			var categorie: Array = Array(spec.get("categories", []))
			if not (categorie.has("singolare") and categorie.has("plurale")):
				continue
			esaminati += 1
			for tessera in Dictionary(spec.get("assignments", {})).keys():
				if INVARIABILI.has(str(tessera).strip_edges().to_lower()):
					failures.append(
						"%s / «%s»: la tessera «%s» è un nome invariabile e vale per tutti e due i bidoni — va data con l'articolo" % [
							subject, str(spec.get("prompt", "?")), str(tessera)])
	print("Regola 3 — smistamenti singolare/plurale: %d esaminati" % esaminati)
	return failures

## REGOLA 4 — chi smista per verso deve dire rispetto a che cosa.
func _smistamenti_con_verso_dichiarano_il_riferimento() -> Array:
	var failures: Array = []
	var esaminati := 0
	for subject_data in MinigameManager.CLASSIFICATION.keys():
		var subject := str(subject_data)
		for spec_data in Array(MinigameManager.CLASSIFICATION[subject_data]):
			var spec := spec_data as Dictionary
			var categorie: Array = Array(spec.get("categories", []))
			var nude: Array = []
			for categoria in categorie:
				var testo := str(categoria).strip_edges().to_lower()
				if VERSI_RELATIVI.has(testo):
					nude.append(str(categoria))
			if nude.is_empty():
				continue
			esaminati += 1
			# Il riferimento può stare nella consegna oppure nel nome del bidone
			# («entra nel programma»): se sta nel nome, il bidone non è nudo e
			# non arriva neanche qui.
			var prompt := str(spec.get("prompt", "")).to_lower()
			var dichiarato := false
			for formula in RIFERIMENTO_DICHIARATO:
				if prompt.contains(formula):
					dichiarato = true
					break
			if not dichiarato:
				failures.append(
					"%s / «%s»: i bidoni %s dicono un verso senza dire rispetto a che cosa" % [
						subject, str(spec.get("prompt", "?")), str(nude)])
	print("Regola 4 — smistamenti con bidoni di verso: %d esaminati" % esaminati)
	return failures
