class_name ExerciseInteraction
extends RefCounted

const MapGeometryCatalog = preload("res://scripts/visual/map_geometry_catalog.gd")
const ArtifactAtlasCatalog = preload("res://scripts/visual/artifact_atlas_catalog.gd")

## Contratto COMUNE degli esercizi (O-P3). Ogni nodo, qualunque sia il formato,
## rispetta lo stesso contratto: presentazione (`prompt`), argomento (`topic`),
## difficoltà, spiegazione causale e i campi-soluzione del proprio formato. Lo
## SCORING, gli scudi (tentativi), la mastery e il progresso sono di competenza
## esclusiva dell'ExercisePlayer (`_score_current`): nessun formato concede
## progresso fuori da questo contratto comune. Codex implementa solo presentazione
## e validazione dell'interazione, mai ricompense o gate.
##
## Questo file è la fonte di verità del contratto e il VALIDATORE dei contenuti:
## ambiguità, soluzione unica, input equivalenti, duplicati, accessibilità
## linguistica (prompt/spiegazione non vuoti).

# Formati con renderer disponibili nell'ExercisePlayer.
const IMPLEMENTED := [
	"multiple_choice", "numeric_input", "short_answer", "ordering", "matching",
	"classification", "hotspot", "graph", "circuit", "notation", "map", "cycle", "code_debug",
	"number_line", "balance", "timeline", "compose", "trace", "clue",
]
# La simulazione usa la stessa futura API visuale, ma non entra nelle missioni
# finché non possiede un modello disciplinare validato.
const PLANNED := ["simulation"]

const MIN_OPTIONS := 3      # scelta multipla: risposta + almeno 2 distrattori
const MIN_PAIRS := 3        # abbinamento: almeno 3 coppie
const MIN_ORDER := 2        # ordinamento: almeno 2 elementi

static func format_of(node: Dictionary) -> String:
	return str(node.get("format", "multiple_choice"))

## Mescola EVITANDO una disposizione vietata — di norma la soluzione. Una prova
## che si presenta già risolta non chiede nulla: basta premere in fila. Con pochi
## elementi la probabilità non è affatto trascurabile (una volta su sei con tre
## elementi, e con tre elementi si gioca spesso), quindi va esclusa, non sperata.
## Se dopo alcuni tentativi il caso non aiuta, si forza uno scambio.
static func shuffle_avoiding(values: Array, rng: RandomNumberGenerator, forbidden: Array) -> void:
	if values.size() < 2:
		return
	for attempt in range(8):
		for i in range(values.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = values[i]
			values[i] = values[j]
			values[j] = tmp
		if values != forbidden:
			return
	# Fallback deterministico: scambia i primi due elementi diversi tra loro.
	for i in range(values.size() - 1):
		if str(values[i]) != str(values[i + 1]):
			var tmp = values[i]
			values[i] = values[i + 1]
			values[i + 1] = tmp
			return

static func is_multiple_choice(node: Dictionary) -> bool:
	return format_of(node) == "multiple_choice"

static func is_implemented(fmt: String) -> bool:
	return IMPLEMENTED.has(fmt)

# Normalizza un input numerico/testuale per il confronto di EQUIVALENZA: spazi,
# virgola decimale, zeri finali. Serve al contratto "input equivalenti" (es.
# "12", "12.0" e "12,0" sono la stessa risposta).
static func normalize_answer(value: String) -> String:
	var s := value.strip_edges().to_lower().replace(",", ".")
	if s.is_valid_float():
		return String.num(s.to_float(), 6).rstrip("0").rstrip(".")
	return s

static func answers_equivalent(a: String, b: String) -> bool:
	return normalize_answer(a) == normalize_answer(b)

## Vera se la risposta data vale per questo nodo, contando anche le forme
## alternative dichiarate in `accept`.
##
## Serve alla risposta libera a testo: «to check» e «check» sono la stessa
## risposta, e un bambino che scrive la prima ha capito esattamente quanto uno
## che scrive la seconda. Segnare sbagliata una risposta giusta è il modo più
## veloce per far smettere di provare — vale più della comodità di confrontare
## una stringa sola.
static func answer_accepted(given: String, node: Dictionary) -> bool:
	if answers_equivalent(given, str(node.get("answer", ""))):
		return true
	for alternativa in Array(node.get("accept", [])):
		if answers_equivalent(given, str(alternativa)):
			return true
	return false

# Valida un nodo. Ritorna {ok: bool, errors: Array[String]}.
## Glifi disegnabili da `exercise_diagram._draw_cycle_glyph`. Chi ne aggiunge
## uno alla lista deve aggiungerlo anche lì, o la fase resta muta a schermo.
const CYCLE_GLYPHS := [
	"sun", "water", "cloud", "rain", "plant", "air", "animal", "soil", "leaf",
	"sugar", "oxygen", "carbon", "egg", "larva", "chrysalis", "butterfly",
	"gear", "arrow", "check", "clock", "rock", "fire", "pen", "note", "book",
	"question", "bolt",
]

static func validate(node: Dictionary) -> Dictionary:
	var errors: Array = []
	var fmt := format_of(node)

	# --- Comuni a tutti i formati (accessibilità linguistica + tracciabilità) ---
	if str(node.get("prompt", "")).strip_edges() == "":
		errors.append("prompt vuoto")
	if str(node.get("topic", "")).strip_edges() == "":
		errors.append("topic mancante (serve a mastery/copertura)")
	var diff := int(node.get("difficulty", 0))
	if diff < 1 or diff > 4:
		errors.append("difficoltà fuori scala 1..4: %d" % diff)
	if str(node.get("explanation", "")).strip_edges() == "":
		errors.append("spiegazione causale mancante")

	if not IMPLEMENTED.has(fmt) and not PLANNED.has(fmt):
		errors.append("formato sconosciuto: %s" % fmt)
		return {"ok": errors.is_empty(), "errors": errors}

	match fmt:
		"multiple_choice":
			_validate_multiple_choice(node, errors)
		"numeric_input":
			if str(node.get("answer", "")).strip_edges() == "":
				errors.append("risposta mancante (numeric_input)")
		"short_answer":
			# Risposta libera a testo: una parola o poco più, scritta dal
			# giocatore. Serve alla decisione «ogni banco al 20-30% di non
			# scelta multipla» nelle materie in cui la risposta non è un numero.
			if str(node.get("answer", "")).strip_edges() == "":
				errors.append("risposta mancante (short_answer)")
			# Una risposta lunga non si può digitare senza sbagliare: sotto i
			# trenta caratteri si scrive, sopra si copia a memoria.
			if str(node.get("answer", "")).length() > 30:
				errors.append("risposta troppo lunga per essere digitata (%d caratteri)" % str(node.get("answer", "")).length())
		"ordering":
			_validate_ordering(node, errors)
		"matching":
			_validate_matching(node, errors)
		"classification":
			_validate_classification(node, errors)
		"hotspot":
			_validate_hotspot(node, errors)
		"graph":
			_validate_selectable_points(node, "points", errors)
		"circuit":
			_validate_circuit(node, errors)
		"notation":
			_validate_notation(node, errors)
		"map":
			_validate_map(node, errors)
		"cycle":
			_validate_cycle(node, errors)
		"number_line":
			_validate_number_line(node, errors)
		"balance":
			_validate_balance(node, errors)
		"timeline":
			_validate_timeline(node, errors)
		"compose":
			_validate_compose(node, errors)
		"trace":
			_validate_trace(node, errors)
		"clue":
			_validate_clue(node, errors)
		"code_debug":
			_validate_code_debug(node, errors)
		_:
			# Formato pianificato (renderer non ancora consegnato): il contratto
			# di dettaglio verrà validato quando i contenuti saranno prodotti.
			pass

	return {"ok": errors.is_empty(), "errors": errors}

static func _validate_multiple_choice(node: Dictionary, errors: Array) -> void:
	var options: Array = node.get("options", [])
	var answer := str(node.get("answer", "")).strip_edges()
	if options.size() < MIN_OPTIONS:
		errors.append("scelta multipla con meno di %d opzioni" % MIN_OPTIONS)
	if answer == "":
		errors.append("risposta mancante (multiple_choice)")
	var seen: Dictionary = {}
	var answer_present := false
	for opt in options:
		var o := str(opt).strip_edges()
		if o == "":
			errors.append("opzione vuota")
		if seen.has(o):
			errors.append("opzione duplicata: %s" % o)
		seen[o] = true
		if o == answer:
			answer_present = true
	if answer != "" and not answer_present:
		errors.append("la risposta non è tra le opzioni: %s" % answer)

static func _validate_ordering(node: Dictionary, errors: Array) -> void:
	var items: Array = node.get("items", [])
	var order: Array = node.get("correctOrder", [])
	if items.size() < MIN_ORDER:
		errors.append("ordinamento con meno di %d elementi" % MIN_ORDER)
	if order.size() != items.size():
		errors.append("correctOrder di lunghezza diversa dagli elementi")
	# correctOrder deve essere una permutazione degli items (stesso multiinsieme).
	var a := items.map(func(x): return str(x)); a.sort()
	var b := order.map(func(x): return str(x)); b.sort()
	if a != b:
		errors.append("correctOrder non è una permutazione degli elementi")
	# Gli elementi non possono essere presentati NELL'ORDINE GIUSTO: l'esercizio
	# sarebbe già risolto e si supererebbe premendo in fila, senza ordinare nulla.
	if items.size() >= 2 and items.map(func(x): return str(x)) == order.map(func(x): return str(x)):
		errors.append("gli elementi sono già nell'ordine corretto: la prova si risolve da sola")
	var seen: Dictionary = {}
	for x in order:
		var s := str(x)
		if seen.has(s):
			errors.append("elemento duplicato nell'ordine: %s" % s)
		seen[s] = true

static func _validate_matching(node: Dictionary, errors: Array) -> void:
	var pairs: Array = node.get("pairs", [])
	if pairs.size() < MIN_PAIRS:
		errors.append("abbinamento con meno di %d coppie" % MIN_PAIRS)
	var lefts: Dictionary = {}
	var rights: Dictionary = {}
	for p in pairs:
		var left := str((p as Dictionary).get("left", "")).strip_edges()
		var right := str((p as Dictionary).get("right", "")).strip_edges()
		if left == "" or right == "":
			errors.append("coppia con lato vuoto")
		# Lati sinistri duplicati o destri duplicati → abbinamento ambiguo.
		if lefts.has(left):
			errors.append("sinistra duplicata (ambiguo): %s" % left)
		if rights.has(right):
			errors.append("destra duplicata (ambiguo): %s" % right)
		lefts[left] = true
		rights[right] = true

static func _validate_classification(node: Dictionary, errors: Array) -> void:
	var items: Array = node.get("items", [])
	var categories: Array = node.get("categories", [])
	var assignments: Dictionary = node.get("assignments", {})
	if items.size() < 2:
		errors.append("classificazione con meno di 2 elementi")
	if categories.size() < 2:
		errors.append("classificazione con meno di 2 categorie")
	var valid_categories: Dictionary = {}
	for category in categories:
		valid_categories[str(category)] = true
	for item in items:
		var key := str(item)
		if not assignments.has(key):
			errors.append("categoria mancante per: %s" % key)
		elif not valid_categories.has(str(assignments[key])):
			errors.append("categoria sconosciuta per %s: %s" % [key, str(assignments[key])])

static func _validate_selectable_points(node: Dictionary, field: String, errors: Array) -> void:
	var points: Array = node.get(field, [])
	var answer := str(node.get("answer", ""))
	if points.size() < 2:
		errors.append("%s con meno di 2 punti" % field)
	var ids: Dictionary = {}
	for point in points:
		var id := str((point as Dictionary).get("id", ""))
		if id == "":
			errors.append("%s con id vuoto" % field)
		elif ids.has(id):
			errors.append("%s con id duplicato: %s" % [field, id])
		ids[id] = true
	if answer == "" or not ids.has(answer):
		errors.append("risposta non presente in %s: %s" % [field, answer])

static func _validate_hotspot(node: Dictionary, errors: Array) -> void:
	var atlas_id := str(node.get("assetId", ""))
	if atlas_id == "":
		_validate_selectable_points(node, "hotspots", errors)
		return
	if not ArtifactAtlasCatalog.has_atlas(atlas_id):
		errors.append("atlante illustrato sconosciuto: %s" % atlas_id)
		return
	var targets: Array = node.get("targets", [])
	var answer := str(node.get("answer", ""))
	if targets.size() < 2:
		errors.append("hotspot semantico con meno di 2 bersagli")
	var ids: Dictionary = {}
	for entry in targets:
		var target := entry as Dictionary
		var id := str(target.get("id", ""))
		if id == "":
			errors.append("bersaglio hotspot con id vuoto")
		elif ids.has(id):
			errors.append("bersaglio hotspot duplicato: %s" % id)
		elif not ArtifactAtlasCatalog.has_target(atlas_id, id):
			errors.append("bersaglio %s assente dall'atlante %s" % [id, atlas_id])
		ids[id] = true
		if str(target.get("label", "")).strip_edges() == "":
			errors.append("bersaglio hotspot senza etichetta accessibile: %s" % id)
	if answer == "" or not ids.has(answer):
		errors.append("risposta hotspot non presente nei bersagli: %s" % answer)

static func _validate_circuit(node: Dictionary, errors: Array) -> void:
	var components: Array = node.get("components", [])
	var answer := str(node.get("answer", ""))
	if components.size() < 2:
		errors.append("circuito con meno di 2 componenti")
	var ids: Dictionary = {}
	for component in components:
		var id := str((component as Dictionary).get("id", ""))
		if id == "":
			errors.append("componente con id vuoto")
		elif ids.has(id):
			errors.append("componente duplicato: %s" % id)
		ids[id] = true
	for edge in node.get("connections", []):
		if not edge is Array or edge.size() < 2:
			errors.append("connessione circuito non valida")
			continue
		if not ids.has(str(edge[0])) or not ids.has(str(edge[1])):
			errors.append("connessione verso componente sconosciuto")
	if answer == "" or not ids.has(answer):
		errors.append("risposta circuito non presente: %s" % answer)

## La retta numerica: due o più posizioni sulla stessa scala, una sola giusta.
##
## I controlli che contano sono due. Il primo: ogni bersaglio deve cadere DENTRO
## la scala disegnata, altrimenti finisce fuori dal riquadro e diventa
## impossibile da toccare. Il secondo: due bersagli non possono avere lo stesso
## valore, perché occuperebbero lo stesso punto e la domanda avrebbe due
## risposte sovrapposte a schermo.
## La bilancia. Il controllo che vale non è di forma: è **aritmetico**.
##
## La risposta giusta deve pareggiare davvero i due piatti, e le altre no. Senza
## questa verifica una specifica scritta male passerebbe tutti i controlli
## strutturali e insegnerebbe un'equivalenza falsa — che è peggio di non
## insegnare niente. È lo stesso genere di controllo che il 3 agosto ha scoperto
## 94 domande finite sulla specifica sbagliata: la forma era perfetta, i dati no.
## LINEA DEL TEMPO. Il controllo proprio: due eventi non possono cadere così
## vicini da sovrapporsi a schermo. Su una scala di quattro secoli due date a un
## anno di distanza diventano lo stesso pixel, e la domanda smette di avere una
## risposta toccabile.
const TIMELINE_MIN_SEPARAZIONE := 0.02

## L'INDIZIARIO. I controlli propri sono due, e riguardano entrambi il fatto
## che gli indizi vanno **in ordine di forza**.
##
## Il primo indizio è già scoperto quando la prova comincia, quindi da solo non
## deve bastare: se restringesse già a una sola risposta, tutti gli altri
## sarebbero decorazione e la scelta strategica sparirebbe. Per questo si chiede
## che gli indizi siano almeno tre — con due, «il primo non basta» significa
## «il secondo decide», che è una domanda a due passi, non un'indagine.
##
## Quello che una macchina NON può controllare è che ogni indizio sia davvero
## più stringente del precedente: lo giudica chi legge. L'audit lo dice invece
## di fingere di verificarlo.
static func _validate_clue(node: Dictionary, errors: Array) -> void:
	var clues: Array = node.get("clues", [])
	if clues.size() < 3:
		errors.append("indiziario con %d indizi: sotto i tre non c'è nessuna scelta da fare" % clues.size())
	if clues.size() > 5:
		errors.append("indiziario con più di 5 indizi: le carte non ci stanno a schermo")
	for i in clues.size():
		var testo := str((clues[i] as Dictionary).get("text", "")).strip_edges()
		if testo == "":
			errors.append("indizio %d vuoto" % (i + 1))
		elif testo.length() < 12:
			errors.append("indizio %d troppo corto per dire qualcosa: «%s»" % [i + 1, testo])
	_valida_candidati(node, errors, "indiziario", 3, 5)

static func _validate_timeline(node: Dictionary, errors: Array) -> void:
	var minimo := float(node.get("min", 0.0))
	var massimo := float(node.get("max", 0.0))
	var estensione := massimo - minimo
	if estensione <= 0.0:
		errors.append("linea del tempo con scala vuota o rovesciata")
		return
	var targets: Array = node.get("targets", [])
	if targets.size() < 2:
		errors.append("linea del tempo con meno di 2 eventi")
	if targets.size() > 6:
		errors.append("linea del tempo con più di 6 eventi: troppo fitta per un dito")
	var ids: Dictionary = {}
	var posizioni: Array = []
	for entry in targets:
		var b := entry as Dictionary
		var id := str(b.get("id", ""))
		if id == "" or ids.has(id):
			errors.append("evento con id vuoto o duplicato: %s" % id)
		ids[id] = true
		if str(b.get("label", "")).strip_edges() == "":
			errors.append("evento senza etichetta accessibile: %s" % id)
		var v := float(b.get("value", 0.0))
		if v < minimo or v > massimo:
			errors.append("evento «%s» fuori scala: %s" % [id, v])
		posizioni.append((v - minimo) / estensione)
	posizioni.sort()
	for i in range(1, posizioni.size()):
		if absf(float(posizioni[i]) - float(posizioni[i - 1])) < TIMELINE_MIN_SEPARAZIONE:
			errors.append("due eventi troppo vicini sulla scala: si sovrappongono a schermo")
			break
	if not ids.has(str(node.get("answer", ""))):
		errors.append("la risposta della linea del tempo non è fra gli eventi")

## COMPOSITORE. Il controllo proprio: deve esserci **esattamente una** casella
## vuota. Zero e non c'è niente da fare; due e la risposta non è più una sola.
static func _validate_compose(node: Dictionary, errors: Array) -> void:
	var slots: Array = node.get("slots", [])
	if slots.size() < 2:
		errors.append("composizione con meno di 2 caselle")
	var vuote := 0
	for entry in slots:
		if str((entry as Dictionary).get("text", "")).strip_edges() == "":
			vuote += 1
	if vuote != 1:
		errors.append("la composizione ha %d caselle vuote: ne serve esattamente una" % vuote)
	_valida_candidati(node, errors, "composizione", 2, 5)

## TRACCIATORE. Il controllo proprio: l'ultimo passo deve essere quello coperto,
## e tutti gli altri devono mostrare il proprio stato. Un buco a metà catena
## renderebbe la simulazione impossibile invece che difficile.
static func _validate_trace(node: Dictionary, errors: Array) -> void:
	var steps: Array = node.get("steps", [])
	if steps.size() < 3:
		errors.append("traccia con meno di 3 passi: non c'è niente da simulare")
	for i in steps.size():
		var vuoto := str((steps[i] as Dictionary).get("state", "")).strip_edges() == ""
		if vuoto and i != steps.size() - 1:
			errors.append("passo %d senza stato: il buco deve stare solo alla fine" % i)
		if not vuoto and i == steps.size() - 1:
			errors.append("l'ultimo passo mostra già lo stato: non c'è domanda")
		if str((steps[i] as Dictionary).get("label", "")).strip_edges() == "":
			errors.append("passo %d senza descrizione" % i)
	_valida_candidati(node, errors, "traccia", 2, 5)

## Candidati offerti sotto un disegno: ids unici, etichette accessibili, e la
## risposta deve essere uno di loro. Comune a composizione e traccia.
static func _valida_candidati(node: Dictionary, errors: Array, nome: String, minimo: int, massimo: int) -> void:
	var targets: Array = node.get("targets", [])
	if targets.size() < minimo:
		errors.append("%s con meno di %d candidati" % [nome, minimo])
	if targets.size() > massimo:
		errors.append("%s con più di %d candidati: la fila non ci sta" % [nome, massimo])
	var ids: Dictionary = {}
	for entry in targets:
		var b := entry as Dictionary
		var id := str(b.get("id", ""))
		if id == "" or ids.has(id):
			errors.append("%s: candidato con id vuoto o duplicato «%s»" % [nome, id])
		ids[id] = true
		if str(b.get("label", "")).strip_edges() == "":
			errors.append("%s: candidato senza etichetta accessibile «%s»" % [nome, id])
	if not ids.has(str(node.get("answer", ""))):
		errors.append("%s: la risposta non è fra i candidati" % nome)

static func _validate_balance(node: Dictionary, errors: Array) -> void:
	var sinistra := _somma_piatto(node.get("left", []))
	var destra := _somma_piatto(node.get("right", []))
	var lato := str(node.get("gapSide", "right"))
	if lato not in ["left", "right"]:
		errors.append("lato del posto vuoto sconosciuto: %s" % lato)
	var targets: Array = node.get("targets", [])
	if targets.size() < 2:
		errors.append("bilancia con meno di 2 candidati")
	if targets.size() > 5:
		errors.append("bilancia con più di 5 candidati: la fila non ci sta a schermo")
	var ids: Dictionary = {}
	var giusti := 0
	for entry in targets:
		var candidato := entry as Dictionary
		var id := str(candidato.get("id", ""))
		if id == "":
			errors.append("candidato della bilancia con id vuoto")
		elif ids.has(id):
			errors.append("candidato duplicato: %s" % id)
		ids[id] = true
		if str(candidato.get("label", "")).strip_edges() == "":
			errors.append("candidato senza etichetta accessibile: %s" % id)
		var valore := float(candidato.get("value", 0.0))
		var pareggia := (
			is_equal_approx(sinistra, destra + valore) if lato == "right"
			else is_equal_approx(sinistra + valore, destra))
		if pareggia:
			giusti += 1
			if id != str(node.get("answer", "")):
				errors.append("il candidato «%s» pareggia la bilancia ma non è la risposta" % id)
		elif id == str(node.get("answer", "")):
			errors.append("la risposta «%s» NON pareggia: %s contro %s" % [
				id, sinistra, destra + valore if lato == "right" else sinistra + valore])
	if giusti != 1:
		errors.append("la bilancia ha %d candidati che pareggiano: ne serve esattamente uno" % giusti)
	if not ids.has(str(node.get("answer", ""))):
		errors.append("la risposta della bilancia non è fra i candidati")

static func _somma_piatto(voci) -> float:
	var totale := 0.0
	for entry in Array(voci):
		totale += float((entry as Dictionary).get("value", 0.0))
	return totale

static func _validate_number_line(node: Dictionary, errors: Array) -> void:
	var minimo := float(node.get("min", 0.0))
	var massimo := float(node.get("max", 0.0))
	if massimo <= minimo:
		errors.append("retta numerica con scala vuota o rovesciata (%s → %s)" % [minimo, massimo])
	if float(node.get("tick", 0.0)) <= 0.0:
		errors.append("retta numerica senza passo delle tacche")
	var targets: Array = node.get("targets", [])
	if targets.size() < 2:
		errors.append("retta numerica con meno di 2 posizioni selezionabili")
	if targets.size() > 6:
		errors.append("retta numerica con più di 6 posizioni: bersagli troppo fitti per un dito")
	var ids: Dictionary = {}
	var valori: Dictionary = {}
	for entry in targets:
		var bersaglio := entry as Dictionary
		var id := str(bersaglio.get("id", ""))
		if id == "":
			errors.append("posizione della retta con id vuoto")
		elif ids.has(id):
			errors.append("posizione della retta duplicata: %s" % id)
		ids[id] = true
		if str(bersaglio.get("label", "")).strip_edges() == "":
			errors.append("posizione della retta senza etichetta accessibile: %s" % id)
		var v := float(bersaglio.get("value", 0.0))
		if v < minimo or v > massimo:
			errors.append("posizione «%s» fuori dalla scala: %s non sta fra %s e %s" % [id, v, minimo, massimo])
		var chiave := "%.4f" % v
		if valori.has(chiave):
			errors.append("due posizioni sullo stesso valore (%s): si sovrappongono a schermo" % v)
		valori[chiave] = true
	if not ids.has(str(node.get("answer", ""))):
		errors.append("la risposta della retta non è una delle posizioni offerte")

static func _validate_notation(node: Dictionary, errors: Array) -> void:
	var staff := node.get("staff", {}) as Dictionary
	var clef := str(staff.get("clef", "treble"))
	if clef not in ["treble", "bass"]:
		errors.append("chiave musicale non supportata: %s" % clef)
	var symbols: Array = node.get("symbols", [])
	var answer := str(node.get("answer", ""))
	if symbols.size() < 2:
		errors.append("notazione con meno di 2 simboli selezionabili")
	if symbols.size() > 7:
		errors.append("notazione con più di 7 simboli: target touch troppo fitti")
	var ids: Dictionary = {}
	for entry in symbols:
		var symbol := entry as Dictionary
		var id := str(symbol.get("id", ""))
		if id == "":
			errors.append("simbolo musicale con id vuoto")
		elif ids.has(id):
			errors.append("simbolo musicale duplicato: %s" % id)
		ids[id] = true
		if str(symbol.get("label", "")).strip_edges() == "":
			errors.append("simbolo musicale senza etichetta accessibile: %s" % id)
		var kind := str(symbol.get("kind", "note"))
		if kind not in ["note", "rest", "accidental"]:
			errors.append("tipo di simbolo musicale non supportato: %s" % kind)
		var staff_step := int(symbol.get("staffStep", 99))
		if staff_step < -4 or staff_step > 12:
			errors.append("staffStep fuori scala -4..12: %s" % id)
		if kind in ["note", "rest"]:
			var duration := str(symbol.get("duration", "quarter"))
			if duration not in ["whole", "half", "quarter", "eighth"]:
				errors.append("durata musicale non supportata: %s" % duration)
		elif str(symbol.get("accidental", "")) not in ["sharp", "flat", "natural"]:
			errors.append("alterazione musicale non supportata: %s" % str(symbol.get("accidental", "")))
	if answer == "" or not ids.has(answer):
		errors.append("risposta notazione non presente: %s" % answer)

static func _validate_cycle(node: Dictionary, errors: Array) -> void:
	var stages: Array = node.get("stages", [])
	var correct_order: Array = node.get("correctOrder", [])
	if stages.size() < 3:
		errors.append("ciclo con meno di 3 fasi")
	if correct_order.size() != stages.size():
		errors.append("correctOrder del ciclo di lunghezza diversa dalle fasi")
	var ids: Dictionary = {}
	var labels: Dictionary = {}
	var presented: Array = []
	for entry in stages:
		var stage := entry as Dictionary
		var id := str(stage.get("id", ""))
		var label := str(stage.get("label", "")).strip_edges()
		var glyph := str(stage.get("glyph", ""))
		presented.append(id)
		if id == "":
			errors.append("fase del ciclo con id vuoto")
		elif ids.has(id):
			errors.append("fase del ciclo duplicata: %s" % id)
		ids[id] = true
		if label == "":
			errors.append("fase del ciclo senza etichetta accessibile: %s" % id)
		elif labels.has(label):
			errors.append("etichetta del ciclo duplicata: %s" % label)
		labels[label] = true
		# I glifi sono tutti DISEGNATI in `exercise_diagram.gd`, non immagini:
		# aggiungerne uno costa qualche riga di `draw_*` e nessun asset. È la
		# ragione per cui il ciclo si è potuto estendere da una materia a otto.
		if glyph not in CYCLE_GLYPHS:
			errors.append("glifo del ciclo non supportato: %s" % glyph)
	var expected := correct_order.map(func(value): return str(value))
	var sorted_ids: Array = ids.keys()
	sorted_ids.sort()
	var sorted_expected: Array = expected.duplicate()
	sorted_expected.sort()
	if sorted_ids != sorted_expected:
		errors.append("correctOrder del ciclo non è una permutazione delle fasi")
	if stages.size() >= 3 and presented == expected:
		errors.append("le fasi del ciclo sono già presentate nell'ordine corretto")

static func _validate_map(node: Dictionary, errors: Array) -> void:
	var map_id := str(node.get("mapId", ""))
	if not MapGeometryCatalog.has_map(map_id):
		errors.append("carta muta sconosciuta: %s" % map_id)
		return
	var targets: Array = node.get("targets", [])
	if targets.size() < 2:
		errors.append("carta muta con meno di 2 bersagli")
	var available: Array = MapGeometryCatalog.target_ids(map_id)
	var ids: Dictionary = {}
	for entry in targets:
		var target := entry as Dictionary
		var id := str(target.get("id", ""))
		if id == "":
			errors.append("bersaglio carta con id vuoto")
		elif ids.has(id):
			errors.append("bersaglio carta duplicato: %s" % id)
		elif not available.has(id):
			errors.append("bersaglio %s assente dalla carta %s" % [id, map_id])
		ids[id] = true
		if str(target.get("label", "")).strip_edges() == "":
			errors.append("bersaglio carta senza etichetta accessibile: %s" % id)
	var answer := str(node.get("answer", ""))
	if answer == "" or not ids.has(answer):
		errors.append("risposta carta non presente: %s" % answer)

static func _validate_code_debug(node: Dictionary, errors: Array) -> void:
	var lines: Array = node.get("codeLines", [])
	var answer_line := int(node.get("answerLine", 0))
	if lines.size() < 2:
		errors.append("code-debug con meno di 2 righe")
	if answer_line < 1 or answer_line > lines.size():
		errors.append("answerLine fuori dal codice: %d" % answer_line)
		return
	# Una riga che inizia con '#' è la consegna, non un passaggio: non è
	# selezionabile e quindi non può essere la risposta. Senza questo controllo un
	# nodo poteva dichiarare come soluzione una riga che il giocatore non può
	# nemmeno scegliere — prova impossibile, e nessun audit se ne accorgeva.
	if str(lines[answer_line - 1]).strip_edges().begins_with("#"):
		errors.append("answerLine punta a una riga di consegna: %d" % answer_line)
	var candidates := 0
	for line in lines:
		if not str(line).strip_edges().begins_with("#"):
			candidates += 1
	if candidates < 2:
		errors.append("code-debug con meno di 2 righe selezionabili")

# Valida un'intera sessione: nodi non vuoti, scudi ≥ 1 e ogni nodo conforme.
# Ritorna {ok, errors: Array[String]} con gli errori prefissati dall'indice nodo.
static func validate_session(session: Dictionary) -> Dictionary:
	var errors: Array = []
	var nodes: Array = session.get("nodes", [])
	if nodes.is_empty():
		errors.append("sessione senza nodi")
	if int(session.get("shields", 0)) < 1:
		errors.append("scudi < 1")
	for i in nodes.size():
		var res := validate(nodes[i])
		if not bool(res["ok"]):
			for e in res["errors"]:
				errors.append("nodo %d: %s" % [i, str(e)])
	return {"ok": errors.is_empty(), "errors": errors}

# Rapporto di scelta multipla in un insieme di nodi (0..1). Serve alla policy
# "scelta multipla non dominante" (target ≤ 0.33 nelle missioni standard).
static func multiple_choice_ratio(nodes: Array) -> float:
	if nodes.is_empty():
		return 0.0
	var mc := 0
	for n in nodes:
		if is_multiple_choice(n):
			mc += 1
	return float(mc) / float(nodes.size())

# Formati distinti presenti in un insieme di nodi.
static func distinct_formats(nodes: Array) -> Array:
	var seen: Dictionary = {}
	for n in nodes:
		seen[format_of(n)] = true
	return seen.keys()
