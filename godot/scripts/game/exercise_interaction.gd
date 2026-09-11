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
	"number_line", "balance", "timeline", "compose", "trace", "clue", "swipe", "machine_path",
	"mystery_sample", "verb_decoder", "griglia", "porte",
	"breadboard", "rhythm_fill", "causal_chain", "robot_grid", "blank_map",
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
	# La scelta multipla si TOCCA, non si digita: l'opzione arriva identica a
	# come sta scritta nel banco, quindi qui il confronto dev'essere esatto.
	# La normalizzazione serve a chi scrive — «12», «12.0» e «12,0» sono la
	# stessa risposta battuta a tastiera — e su un elenco di opzioni fa danno,
	# perché rende giusto un distrattore: in `coding-stringhe-123` la domanda è
	# proprio maiuscole contro minuscole (`.upper()` non assegnato) e «CIAO»,
	# cioè il distrattore che contiene l'errore da capire, veniva contato
	# giusto. Lo stesso vale per «5» contro «5.0» sulla divisione di Python.
	# Segnalato giocando, insieme alle soluzioni doppie di italiano.
	if is_multiple_choice(node):
		# `strip_edges` e basta: il contratto (`_validate_multiple_choice`) gia'
		# confronta le opzioni con la risposta a bordi tagliati, quindi qui la
		# stessa tolleranza — e nessuna in piu'.
		var scelta := given.strip_edges()
		if scelta == str(node.get("answer", "")).strip_edges():
			return true
		for alternativa in Array(node.get("accept", [])):
			if scelta == str(alternativa).strip_edges():
				return true
		return false
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
	if diff < 1 or diff > 8:
		errors.append("difficoltà fuori scala 1..8: %d" % diff)
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
		"machine_path":
			_validate_machine_path(node, errors)
		"mystery_sample":
			_validate_mystery_sample(node, errors)
		"verb_decoder":
			_validate_verb_decoder(node, errors)
		"breadboard":
			_validate_breadboard(node, errors)
		"rhythm_fill":
			_validate_rhythm_fill(node, errors)
		"causal_chain":
			_validate_causal_chain(node, errors)
		"robot_grid":
			_validate_robot_grid(node, errors)
		"blank_map":
			_validate_blank_map(node, errors)
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
		"swipe":
			_validate_swipe(node, errors)
		"code_debug":
			_validate_code_debug(node, errors)
		"griglia":
			_validate_griglia(node, errors)
		"porte":
			_validate_porte(node, errors)
		_:
			# Formato pianificato (renderer non ancora consegnato): il contratto
			# di dettaglio verrà validato quando i contenuti saranno prodotti.
			pass

	return {"ok": errors.is_empty(), "errors": errors}

## Percorso di macchine numeriche. Il bambino monta trasformazioni in fila e
## avvia una sfera di energia: il risultato e' prodotto dal sistema, non scelto
## da un elenco. Sono ammesse anche soluzioni alternative, purche' portino
## davvero al valore richiesto.
static func _validate_machine_path(node: Dictionary, errors: Array) -> void:
	var slot_count := int(node.get("slotCount", 0))
	var machines: Array = node.get("machines", [])
	if slot_count < 2 or slot_count > 4:
		errors.append("percorso macchine con numero di posti fuori scala 2..4")
	if machines.size() <= slot_count:
		errors.append("percorso macchine senza almeno una macchina alternativa")
	var ids: Dictionary = {}
	for raw in machines:
		var machine := raw as Dictionary
		var id := str(machine.get("id", "")).strip_edges()
		var op := str(machine.get("op", ""))
		var value := int(machine.get("value", 0))
		if id == "":
			errors.append("macchina senza id")
		elif ids.has(id):
			errors.append("id macchina duplicato: %s" % id)
		ids[id] = true
		if not op in ["add", "subtract", "multiply", "divide"]:
			errors.append("operazione macchina sconosciuta: %s" % op)
		if value <= 0:
			errors.append("valore macchina non positivo: %s" % id)
		if str(machine.get("label", "")).strip_edges() == "":
			errors.append("macchina senza etichetta: %s" % id)
	var solution: Array = node.get("solution", [])
	if solution.size() != slot_count:
		errors.append("soluzione percorso di lunghezza diversa dai posti")
	for raw_id in solution:
		if not ids.has(str(raw_id)):
			errors.append("soluzione usa macchina inesistente: %s" % str(raw_id))
	var result := evaluate_machine_path(int(node.get("start", 0)), solution, machines)
	if not bool(result.get("ok", false)):
		errors.append("la soluzione dichiarata si blocca")
	elif int(result.get("value", 0)) != int(node.get("target", 0)):
		errors.append("la soluzione dichiarata non raggiunge il traguardo")

## Esegue un percorso scelto dal giocatore. Questa funzione e' condivisa fra
## validatore e renderer: il contenuto non puo' promettere una regola e la UI
## applicarne un'altra.
static func evaluate_machine_path(start: int, path: Array, machines: Array) -> Dictionary:
	var by_id: Dictionary = {}
	for raw in machines:
		var machine := raw as Dictionary
		by_id[str(machine.get("id", ""))] = machine
	var current := start
	var values: Array = [current]
	for index in path.size():
		var id := str(path[index])
		if not by_id.has(id):
			return {"ok": false, "value": current, "values": values, "blockedAt": index, "reason": "Macchina non trovata."}
		var machine := by_id[id] as Dictionary
		var amount := int(machine.get("value", 0))
		match str(machine.get("op", "")):
			"add": current += amount
			"subtract": current -= amount
			"multiply": current *= amount
			"divide":
				if amount == 0 or current % amount != 0:
					return {
						"ok": false, "value": current, "values": values,
						"blockedAt": index,
						"reason": "%d non si divide in %d parti uguali." % [current, amount],
					}
				current = int(current / amount)
			_:
				return {"ok": false, "value": current, "values": values, "blockedAt": index, "reason": "Macchina sconosciuta."}
		values.append(current)
	return {"ok": true, "value": current, "values": values, "blockedAt": -1, "reason": ""}

## Laboratorio investigativo: il giocatore sceglie esperimenti, osserva le
## reazioni di un campione sconosciuto e solo dopo formula un'ipotesi. La tabella
## delle proprietà è condivisa da validatore e renderer, così ogni indizio è
## davvero coerente con il materiale nascosto.
static func _validate_mystery_sample(node: Dictionary, errors: Array) -> void:
	var samples: Array = node.get("samples", [])
	var tests: Array = node.get("tests", [])
	var results := node.get("results", {}) as Dictionary
	var answer := str(node.get("answer", ""))
	if samples.size() < 3 or samples.size() > 5:
		errors.append("mistero con numero di materiali fuori scala 3..5")
	if tests.size() < 3 or tests.size() > 4:
		errors.append("mistero con numero di esperimenti fuori scala 3..4")
	var sample_ids: Dictionary = {}
	for raw in samples:
		var sample := raw as Dictionary
		var id := str(sample.get("id", "")).strip_edges()
		if id == "" or str(sample.get("name", "")).strip_edges() == "":
			errors.append("materiale senza id o nome")
		elif sample_ids.has(id):
			errors.append("materiale duplicato: %s" % id)
		sample_ids[id] = true
	if not sample_ids.has(answer):
		errors.append("il campione nascosto non è fra i materiali")
	var test_ids: Dictionary = {}
	for raw in tests:
		var test := raw as Dictionary
		var id := str(test.get("id", "")).strip_edges()
		if id == "" or str(test.get("label", "")).strip_edges() == "":
			errors.append("esperimento senza id o nome")
		elif test_ids.has(id):
			errors.append("esperimento duplicato: %s" % id)
		test_ids[id] = true
	var min_tests := int(node.get("minTests", 0))
	if min_tests < 1 or min_tests > tests.size():
		errors.append("numero minimo di esperimenti non valido")
	var fingerprints: Dictionary = {}
	for sample_id in sample_ids.keys():
		if not results.has(sample_id):
			errors.append("risultati mancanti per %s" % sample_id)
			continue
		var sample_results := results[sample_id] as Dictionary
		var fingerprint: Array = []
		for test_id in test_ids.keys():
			var observation := str(sample_results.get(test_id, "")).strip_edges()
			if observation == "":
				errors.append("risultato mancante: %s/%s" % [sample_id, test_id])
			fingerprint.append(observation)
		var key := "|".join(PackedStringArray(fingerprint))
		if fingerprints.has(key):
			errors.append("due materiali reagiscono allo stesso modo: %s e %s" % [str(fingerprints[key]), sample_id])
		fingerprints[key] = sample_id

static func mystery_sample_result(node: Dictionary, test_id: String) -> String:
	var answer := str(node.get("answer", ""))
	var results := node.get("results", {}) as Dictionary
	return str((results.get(answer, {}) as Dictionary).get(test_id, ""))

## Decodificatore verbale. Il giocatore ricostruisce tre informazioni diverse:
## tempo, modo e forma del verbo. Separarle impedisce di indovinare una parola
## senza capire perche' funziona nella frase.
static func _validate_verb_decoder(node: Dictionary, errors: Array) -> void:
	var solution := node.get("solution", {}) as Dictionary
	var valid_axes := {"time": "timeChoices", "mood": "moodChoices", "form": "forms"}
	for axis in valid_axes.keys():
		var entries: Array = node.get(str(valid_axes[axis]), [])
		if entries.size() < 3 or entries.size() > 6:
			errors.append("decodificatore: %s con numero di scelte fuori scala 3..6" % axis)
		var ids: Dictionary = {}
		for raw in entries:
			var entry := raw as Dictionary
			var id := str(entry.get("id", "")).strip_edges()
			if id == "" or str(entry.get("label", "")).strip_edges() == "":
				errors.append("decodificatore: scelta %s senza id o etichetta" % axis)
			elif ids.has(id):
				errors.append("decodificatore: id duplicato %s/%s" % [axis, id])
			ids[id] = true
		if not ids.has(str(solution.get(axis, ""))):
			errors.append("decodificatore: soluzione %s non presente nelle scelte" % axis)
	var segments: Array = node.get("segments", [])
	if segments.size() != 2 or (str(segments[0]).strip_edges() == "" and str(segments[1]).strip_edges() == ""):
		errors.append("decodificatore: frase spezzata non valida")
	var hints := node.get("hints", {}) as Dictionary
	for axis in ["time", "mood", "form"]:
		if str(hints.get(axis, "")).strip_edges() == "":
			errors.append("decodificatore: indizio mancante per %s" % axis)
	if str(node.get("discovery", "")).strip_edges() == "":
		errors.append("decodificatore: scoperta narrativa mancante")
	if node.has("axisTitles"):
		var axis_titles: Array = node.get("axisTitles", [])
		if axis_titles.size() != 3:
			errors.append("decodificatore: axisTitles deve contenere tre titoli")
		else:
			for title in axis_titles:
				if str(title).strip_edges() == "":
					errors.append("decodificatore: titolo di ghiera vuoto")
	if not bool(evaluate_verb_decoder(node, solution).get("correct", false)):
		errors.append("decodificatore: soluzione dichiarata non valida")

static func evaluate_verb_decoder(node: Dictionary, selected: Dictionary) -> Dictionary:
	var solution := node.get("solution", {}) as Dictionary
	var first_mismatch := ""
	for axis in ["time", "mood", "form"]:
		if str(selected.get(axis, "")) != str(solution.get(axis, "")):
			first_mismatch = axis
			break
	var form_label := "_____"
	for raw in Array(node.get("forms", [])):
		var form := raw as Dictionary
		if str(form.get("id", "")) == str(selected.get("form", "")):
			form_label = str(form.get("label", "_____"))
			break
	var segments: Array = node.get("segments", [])
	var rendered := ""
	if segments.size() == 2:
		rendered = ("%s %s %s" % [str(segments[0]).strip_edges(), form_label, str(segments[1]).strip_edges()]).strip_edges()
	return {
		"correct": first_mismatch == "",
		"firstMismatch": first_mismatch,
		"rendered": rendered,
	}

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
## LO SCORRIMENTO. Tre controlli, e il primo è il più importante.
##
## **1. Solo su argomenti fluency.** Il cronometro misura una competenza reale
## dove la risposta deve essere automatica — coniugare, le tabelline, un vocabolo
## — e misura ansia dappertutto altrove. `ContentManager.FLUENCY_TOPICS` decide,
## e un argomento non elencato lì non può avere un round a tempo.
##
## **2. Abbastanza affermazioni.** Una prova binaria si indovina al cinquanta per
## cento: su sei affermazioni la fortuna basta a passare, su sedici no. È la
## lunghezza a rendere onesto il formato, non la difficoltà delle singole frasi.
##
## **3. Vere e false in equilibrio.** Se le corrette fossero tre su sedici, la
## strategia vincente sarebbe rispondere sempre «sbagliato» senza leggere.
const SWIPE_MIN_FRASI := 10
const SWIPE_MIN_QUOTA_VERE := 0.35

static func _validate_swipe(node: Dictionary, errors: Array) -> void:
	var subject := str(node.get("subject", ""))
	var topic := str(node.get("topic", ""))
	if not ContentManager.is_fluency_topic(subject, topic):
		errors.append("«%s/%s» non è un argomento fluency: il cronometro qui misurerebbe ansia" % [
			subject, topic])
	var frasi: Array = node.get("statements", [])
	if frasi.size() < SWIPE_MIN_FRASI:
		errors.append("scorrimento con %d affermazioni: sotto %d si passa tirando a indovinare" % [
			frasi.size(), SWIPE_MIN_FRASI])
	var vere := 0
	var viste: Dictionary = {}
	for entry in frasi:
		var frase := entry as Dictionary
		var testo := str(frase.get("text", "")).strip_edges()
		if testo == "":
			errors.append("affermazione vuota")
			continue
		if viste.has(testo):
			errors.append("affermazione ripetuta: «%s»" % testo)
		viste[testo] = true
		if typeof(frase.get("correct")) != TYPE_BOOL:
			errors.append("affermazione senza verdetto vero/falso: «%s»" % testo)
		elif bool(frase["correct"]):
			vere += 1
	if not frasi.is_empty():
		var quota := float(vere) / float(frasi.size())
		if quota < SWIPE_MIN_QUOTA_VERE or quota > 1.0 - SWIPE_MIN_QUOTA_VERE:
			errors.append(
				"solo il %d%% di affermazioni vere: sbilanciato, conviene rispondere sempre uguale"
				% int(round(quota * 100.0)))
	var soglia := float(node.get("minAccuracy", 0.0))
	if soglia < 0.6 or soglia > 0.95:
		errors.append("soglia di precisione fuori scala (%s): sotto 0,6 passa il caso" % soglia)
	if float(node.get("seconds", 0.0)) < 20.0:
		errors.append("meno di 20 secondi: non è fluenza, è fretta")

## **La griglia degli incroci.** Il contratto verifica la cosa che non si vede
## guardando lo schermo: che gli indizi lascino in piedi UNA sola assegnazione.
##
## Una griglia con due soluzioni non è più difficile, è rotta — il bambino
## ragiona bene e la verifica gli dice che ha sbagliato. E una con zero soluzioni
## è peggio ancora. Qui si contano per forza bruta: con quattro righe sono
## ventiquattro casi, e costano meno di un difetto trovato giocando.
static func _validate_griglia(node: Dictionary, errors: Array) -> void:
	var soggetti: Array = node.get("soggetti", [])
	var attributi: Array = node.get("attributi", [])
	var indizi: Array = node.get("indizi", [])
	var soluzione: Dictionary = node.get("soluzione", {})
	if soggetti.size() < 3:
		errors.append("griglia con %d righe: sotto le tre non c'è niente da incrociare" % soggetti.size())
	if attributi.size() != soggetti.size():
		errors.append("griglia non quadrata: %d righe e %d colonne" % [soggetti.size(), attributi.size()])
	if indizi.size() < 2:
		errors.append("griglia con %d indizi: sotto i due non si deduce, si indovina" % indizi.size())
	if indizi.size() > 6:
		errors.append("griglia con %d indizi: la colonna non ci sta a schermo" % indizi.size())
	for i in indizi.size():
		if str((indizi[i] as Dictionary).get("text", "")).strip_edges().length() < 12:
			errors.append("indizio %d troppo corto per dire qualcosa" % (i + 1))
	# La soluzione deve essere una corrispondenza uno a uno: ogni soggetto ha un
	# attributo, e nessun attributo è di due soggetti.
	var usati: Dictionary = {}
	for soggetto in soggetti:
		var chiave := str(soggetto)
		if not soluzione.has(chiave):
			errors.append("griglia senza soluzione per «%s»" % chiave)
			continue
		var valore := str(soluzione[chiave])
		if not attributi.has(valore):
			errors.append("griglia: «%s» assegnato a «%s», che non è una colonna" % [chiave, valore])
		if usati.has(valore):
			errors.append("griglia: «%s» assegnato a due righe" % valore)
		usati[valore] = true
	if not errors.is_empty():
		return
	var quante := _griglia_compatibili(node)
	if quante == 0:
		errors.append("griglia senza soluzione: gli indizi si contraddicono")
	elif quante > 1:
		errors.append("griglia con %d soluzioni: gli indizi non bastano a chiuderne una sola" % quante)

## Quante assegnazioni sono compatibili con gli indizi. Gli indizi si rileggono
## dal loro TESTO, che è l'unica cosa che il bambino vede: se una frase dice una
## cosa e la struttura ne dice un'altra, è la frase ad avere ragione.
static func _griglia_compatibili(node: Dictionary) -> int:
	var soggetti: Array = node.get("soggetti", [])
	var attributi: Array = node.get("attributi", [])
	var frasi: Array = []
	for indizio in node.get("indizi", []):
		frasi.append(str((indizio as Dictionary).get("text", "")))
	var valide := 0
	for candidata in _permutazioni_di(soggetti.size()):
		var assegnazione: Dictionary = {}
		for i in soggetti.size():
			assegnazione[str(soggetti[i])] = str(attributi[int(candidata[i])])
		var ok := true
		for frase in frasi:
			if not _griglia_frase_regge(str(frase), assegnazione, soggetti, attributi):
				ok = false
				break
		if ok:
			valide += 1
	return valide

## Un indizio regge se il testo è coerente con l'assegnazione. Due forme sole,
## le stesse che il generatore produce: «X non <verbo> Y» e «Chi <verbo> Y è X
## oppure Z». Una terza forma qui non verrebbe capita, ed è il motivo per cui il
## generatore non ne inventa altre senza passare da qui.
static func _griglia_frase_regge(
		frase: String, assegnazione: Dictionary, soggetti: Array, attributi: Array) -> bool:
	var nominati: Array = []
	for soggetto in soggetti:
		if frase.contains(str(soggetto)):
			nominati.append(str(soggetto))
	var colonna := ""
	for attributo in attributi:
		if frase.contains(str(attributo)):
			colonna = str(attributo)
	if colonna == "" or nominati.is_empty():
		return true   # frase che non parla di questa griglia: non vincola nulla
	if frase.contains(" non "):
		for nome in nominati:
			if str(assegnazione.get(nome, "")) == colonna:
				return false
		return true
	for nome in nominati:
		if str(assegnazione.get(nome, "")) == colonna:
			return true
	return false

static func _permutazioni_di(n: int) -> Array:
	if n <= 0:
		return [[]]
	if n == 1:
		return [[0]]
	var out: Array = []
	for coda in _permutazioni_di(n - 1):
		for posto in range(n):
			var nuova: Array = Array(coda).duplicate()
			nuova.insert(posto, n - 1)
			out.append(nuova)
	return out

## **Le porte.** Quattro righe, una per combinazione, e nessuna ripetuta: se una
## combinazione manca o compare due volte la tavola di verità è incompleta, e
## una tavola incompleta insegna la regola sbagliata.
##
## Si controlla anche che la porta non sia degenere — tutte accese o tutte
## spente — perché lì si passa toccando quattro volte lo stesso pulsante.
static func _validate_porte(node: Dictionary, errors: Array) -> void:
	var righe: Array = node.get("righe", [])
	var soluzione: Dictionary = node.get("soluzione", {})
	var ingressi: Array = node.get("ingressi", [])
	if ingressi.size() != 2:
		errors.append("porta con %d ingressi: la tavola qui ne vuole due" % ingressi.size())
	if str(node.get("condizione", "")).strip_edges() == "":
		errors.append("porta senza condizione dichiarata: non si sa quando deve accendersi")
	if righe.size() != 4:
		errors.append("porta con %d casi invece di quattro: la tavola è incompleta" % righe.size())
	var viste: Dictionary = {}
	var accese := 0
	for riga_data in righe:
		var riga: Dictionary = riga_data
		var chiave := str(riga.get("id", ""))
		if chiave == "" or viste.has(chiave):
			errors.append("porta: riga con id vuoto o duplicato «%s»" % chiave)
		viste[chiave] = true
		var combinazione := "%s%s" % [str(bool(riga.get("a", false))), str(bool(riga.get("b", false)))]
		if viste.has(combinazione):
			errors.append("porta: la combinazione %s compare due volte" % combinazione)
		viste[combinazione] = true
		if str(riga.get("label", "")).strip_edges() == "":
			errors.append("porta: riga «%s» senza etichetta leggibile" % chiave)
		if not soluzione.has(chiave):
			errors.append("porta: nessun verdetto per la riga «%s»" % chiave)
		elif bool(soluzione[chiave]):
			accese += 1
	if righe.size() == 4 and (accese == 0 or accese == 4):
		errors.append("porta degenere: %d casi accesi su quattro, si passa rispondendo sempre uguale" % accese)

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
		errors.append("retta numerica con scala vuota o rovesciata (%s » %s)" % [minimo, massimo])
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

# --- FIRME DI MATERIA -------------------------------------------------------
# Questi valutatori sono deliberatamente indipendenti dalla UI. Il renderer
# mostra il sistema; il verdetto viene sempre dal modello qui sotto, cosi' audit,
# mouse e touch eseguono la stessa regola.

static func _validate_breadboard(node: Dictionary, errors: Array) -> void:
	var components: Array = node.get("componenti", [])
	var sockets: Array = node.get("zoccoli", [])
	var goal := node.get("obiettivo", {}) as Dictionary
	var solutions: Array = node.get("soluzioni", [])
	if components.size() < 3:
		errors.append("banco di prova con meno di 3 componenti")
	if sockets.size() < 3:
		errors.append("banco di prova con meno di 3 zoccoli")
	var component_ids: Dictionary = {}
	for raw in components:
		var component := raw as Dictionary
		var id := str(component.get("id", "")).strip_edges()
		if id == "" or str(component.get("label", "")).strip_edges() == "":
			errors.append("componente senza id o etichetta")
		elif component_ids.has(id):
			errors.append("componente duplicato: %s" % id)
		component_ids[id] = true
	var socket_ids: Dictionary = {}
	var nodes: Dictionary = {}
	for raw in sockets:
		var socket := raw as Dictionary
		var id := str(socket.get("id", "")).strip_edges()
		var from_node := str(socket.get("da", "")).strip_edges()
		var to_node := str(socket.get("a", "")).strip_edges()
		if id == "" or from_node == "" or to_node == "" or from_node == to_node:
			errors.append("zoccolo malformato: %s" % id)
		elif socket_ids.has(id):
			errors.append("zoccolo duplicato: %s" % id)
		socket_ids[id] = true
		nodes[from_node] = true
		nodes[to_node] = true
	if not nodes.has(str(goal.get("da", ""))) or not nodes.has(str(goal.get("a", ""))):
		errors.append("obiettivo del banco fuori dalla maglia")
	for required in Array(goal.get("deveIncludere", [])):
		if not component_ids.has(str(required)):
			errors.append("obiettivo usa componente inesistente: %s" % str(required))
	if solutions.size() < 2:
		errors.append("banco di prova senza almeno due topologie valide")
	for raw in solutions:
		var solution := raw as Dictionary
		for socket_id in solution.keys():
			if not socket_ids.has(str(socket_id)):
				errors.append("soluzione usa zoccolo inesistente: %s" % str(socket_id))
			if not component_ids.has(str(solution[socket_id])):
				errors.append("soluzione usa componente inesistente: %s" % str(solution[socket_id]))
		if not bool(evaluate_breadboard(node, solution).get("correct", false)):
			errors.append("topologia dichiarata non raggiunge l'obiettivo")

static func evaluate_breadboard(node: Dictionary, placements: Dictionary) -> Dictionary:
	var by_component: Dictionary = {}
	for raw in Array(node.get("componenti", [])):
		var component := raw as Dictionary
		by_component[str(component.get("id", ""))] = component
	var adjacency: Dictionary = {}
	var open_by_node: Dictionary = {}
	var used: Dictionary = {}
	for raw in Array(node.get("zoccoli", [])):
		var socket := raw as Dictionary
		var socket_id := str(socket.get("id", ""))
		var from_node := str(socket.get("da", ""))
		var to_node := str(socket.get("a", ""))
		var component_id := str(placements.get(socket_id, ""))
		if component_id == "" or not by_component.has(component_id):
			if not open_by_node.has(from_node): open_by_node[from_node] = to_node
			if not open_by_node.has(to_node): open_by_node[to_node] = from_node
			continue
		if used.has(component_id):
			return {"correct": false, "powered": false, "openNode": from_node,
				"reason": "Lo stesso componente non puo' occupare due zoccoli."}
		used[component_id] = true
		var component := by_component[component_id] as Dictionary
		if str(component.get("tipo", "conduttore")) == "aperto":
			open_by_node[from_node] = to_node
			open_by_node[to_node] = from_node
			continue
		if not adjacency.has(from_node): adjacency[from_node] = []
		if not adjacency.has(to_node): adjacency[to_node] = []
		(adjacency[from_node] as Array).append({"node": to_node, "component": component_id})
		(adjacency[to_node] as Array).append({"node": from_node, "component": component_id})
	var goal := node.get("obiettivo", {}) as Dictionary
	var start := str(goal.get("da", ""))
	var finish := str(goal.get("a", ""))
	var required: Array = goal.get("deveIncludere", [])
	var queue: Array = [{"node": start, "path": []}]
	var visited: Dictionary = {}
	var first_open := start
	while not queue.is_empty():
		var state := queue.pop_front() as Dictionary
		var current := str(state.get("node", ""))
		var path: Array = state.get("path", [])
		var visit_key := "%s|%s" % [current, ",".join(PackedStringArray(path))]
		if visited.has(visit_key): continue
		visited[visit_key] = true
		if open_by_node.has(current): first_open = current
		if current == finish:
			var includes_all := true
			for required_id in required:
				if not path.has(str(required_id)): includes_all = false
			if includes_all:
				return {"correct": true, "powered": true, "openNode": "", "reason": ""}
		for edge_data in Array(adjacency.get(current, [])):
			var edge := edge_data as Dictionary
			var next_path := path.duplicate()
			next_path.append(str(edge.get("component", "")))
			queue.append({"node": str(edge.get("node", "")), "path": next_path})
	return {"correct": false, "powered": false, "openNode": first_open,
		"reason": "La corrente si ferma al nodo %s: il percorso resta aperto." % first_open}

static func _validate_rhythm_fill(node: Dictionary, errors: Array) -> void:
	var meter := float(node.get("metro", 0.0))
	if meter <= 0.0:
		errors.append("battuta con metro non positivo")
	var available: Array = node.get("disponibili", [])
	var ids: Dictionary = {}
	for raw in available:
		var token := raw as Dictionary
		var id := str(token.get("id", ""))
		if id == "" or float(token.get("valore", 0.0)) <= 0.0:
			errors.append("durata disponibile malformata")
		elif ids.has(id):
			errors.append("durata disponibile duplicata: %s" % id)
		ids[id] = true
	for raw in Array(node.get("battuta", [])):
		var beat := raw as Dictionary
		if float(beat.get("valore", 0.0)) <= 0.0:
			errors.append("valore fisso della battuta non positivo")
	var solutions: Array = node.get("soluzioni", [])
	if solutions.size() < 2:
		errors.append("battuta senza almeno due riempimenti validi")
	for raw in solutions:
		var solution: Array = raw
		for token_id in solution:
			if not ids.has(str(token_id)):
				errors.append("soluzione ritmica usa durata inesistente: %s" % str(token_id))
		if not bool(evaluate_rhythm_fill(node, solution).get("correct", false)):
			errors.append("soluzione ritmica non completa il metro")

static func evaluate_rhythm_fill(node: Dictionary, selected: Array) -> Dictionary:
	var by_id: Dictionary = {}
	for raw in Array(node.get("disponibili", [])):
		var token := raw as Dictionary
		by_id[str(token.get("id", ""))] = token
	var total := 0.0
	for raw in Array(node.get("battuta", [])):
		total += float((raw as Dictionary).get("valore", 0.0))
	for raw_id in selected:
		var id := str(raw_id)
		if not by_id.has(id):
			return {"correct": false, "total": total, "remaining": float(node.get("metro", 0.0)) - total,
				"reason": "Durata sconosciuta."}
		total += float((by_id[id] as Dictionary).get("valore", 0.0))
	var meter := float(node.get("metro", 0.0))
	return {"correct": absf(total - meter) < 0.001, "total": total,
		"remaining": meter - total, "reason": ""}

static func _validate_causal_chain(node: Dictionary, errors: Array) -> void:
	var events: Array = node.get("eventi", [])
	if events.size() < 3:
		errors.append("catena causale con meno di 3 eventi")
	var ids: Dictionary = {}
	for raw in events:
		var event := raw as Dictionary
		var id := str(event.get("id", ""))
		if id == "" or str(event.get("testo", "")).strip_edges() == "" or not event.has("anno"):
			errors.append("evento causale malformato")
		elif ids.has(id):
			errors.append("evento causale duplicato: %s" % id)
		ids[id] = true
	for field in ["nessi", "nessiFalsi"]:
		for raw in Array(node.get(field, [])):
			var edge := raw as Dictionary
			if not ids.has(str(edge.get("da", ""))) or not ids.has(str(edge.get("a", ""))):
				errors.append("nesso %s punta a evento inesistente" % field)
			if field == "nessiFalsi" and str(edge.get("perche", "")).strip_edges() == "":
				errors.append("nesso falso senza spiegazione")
			if field == "nessi" and not bool(evaluate_causal_link(node, str(edge.get("da", "")), str(edge.get("a", ""))).get("accepted", false)):
				errors.append("nesso corretto incoerente: %s -> %s" % [str(edge.get("da", "")), str(edge.get("a", ""))])
	if Array(node.get("nessi", [])).size() < 2:
		errors.append("catena causale con meno di 2 nessi")

static func _causal_event(node: Dictionary, event_id: String) -> Dictionary:
	for raw in Array(node.get("eventi", [])):
		var event := raw as Dictionary
		if str(event.get("id", "")) == event_id: return event
	return {}

static func evaluate_causal_link(node: Dictionary, from_id: String, to_id: String) -> Dictionary:
	var from_event := _causal_event(node, from_id)
	var to_event := _causal_event(node, to_id)
	if from_event.is_empty() or to_event.is_empty() or from_id == to_id:
		return {"accepted": false, "reason": "Scegli due eventi diversi."}
	var from_year := int(from_event.get("anno", 0))
	var to_year := int(to_event.get("anno", 0))
	if to_year < from_year:
		return {"accepted": false, "backward": true,
			"reason": "%s e' del %d: non puo' causare %s, che e' del %d." % [
				str(from_event.get("testo", from_id)), from_year,
				str(to_event.get("testo", to_id)), to_year]}
	for raw in Array(node.get("nessiFalsi", [])):
		var edge := raw as Dictionary
		if str(edge.get("da", "")) == from_id and str(edge.get("a", "")) == to_id:
			return {"accepted": false, "backward": false, "reason": str(edge.get("perche", "Nesso non sostenuto."))}
	for raw in Array(node.get("nessi", [])):
		var edge := raw as Dictionary
		if str(edge.get("da", "")) == from_id and str(edge.get("a", "")) == to_id:
			return {"accepted": true, "backward": false, "reason": ""}
	return {"accepted": false, "backward": false, "reason": "La fonte non sostiene questo nesso."}

static func evaluate_causal_chain(node: Dictionary, selected: Array) -> Dictionary:
	var wanted: Dictionary = {}
	for raw in Array(node.get("nessi", [])):
		var edge := raw as Dictionary
		wanted["%s>%s" % [str(edge.get("da", "")), str(edge.get("a", ""))]] = true
	var found: Dictionary = {}
	for raw in selected:
		var edge := raw as Dictionary
		var result := evaluate_causal_link(node, str(edge.get("da", "")), str(edge.get("a", "")))
		if not bool(result.get("accepted", false)): return {"correct": false, "reason": str(result.get("reason", ""))}
		found["%s>%s" % [str(edge.get("da", "")), str(edge.get("a", ""))]] = true
	return {"correct": found.size() == wanted.size(), "reason": ""}

static func _grid_point(value: Variant) -> Vector2i:
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)

static func _validate_robot_grid(node: Dictionary, errors: Array) -> void:
	var grid := node.get("griglia", {}) as Dictionary
	var width := int(grid.get("larghezza", 0))
	var height := int(grid.get("altezza", 0))
	if width < 3 or width > 8 or height < 3 or height > 8:
		errors.append("griglia robot fuori scala 3..8")
	var start := _grid_point(node.get("partenza", {}))
	var goal := _grid_point(node.get("obiettivo", {}))
	for point in [start, goal]:
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			errors.append("punto del robot fuori griglia")
	var ops: Dictionary = {}
	for raw in Array(node.get("istruzioni", [])):
		var instruction := raw as Dictionary
		var id := str(instruction.get("id", ""))
		var op := str(instruction.get("op", ""))
		if id == "" or op not in ["forward", "left", "right"]:
			errors.append("istruzione robot malformata: %s" % id)
		ops[id] = true
	var max_steps := int(node.get("maxPassi", 0))
	if max_steps < 2 or max_steps > 20:
		errors.append("maxPassi robot fuori scala 2..20")
	if node.has("soluzione"):
		var solution: Array = node.get("soluzione", [])
		for id in solution:
			if not ops.has(str(id)): errors.append("programma usa istruzione inesistente: %s" % str(id))
		if not bool(evaluate_robot_grid(node, solution).get("correct", false)):
			errors.append("programma dichiarato non raggiunge l'obiettivo")

static func evaluate_robot_grid(node: Dictionary, program: Array) -> Dictionary:
	var grid := node.get("griglia", {}) as Dictionary
	var width := int(grid.get("larghezza", 0))
	var height := int(grid.get("altezza", 0))
	var blocked: Dictionary = {}
	for raw in Array(grid.get("ostacoli", [])):
		blocked[str(_grid_point(raw))] = true
	var by_id: Dictionary = {}
	for raw in Array(node.get("istruzioni", [])):
		var instruction := raw as Dictionary
		by_id[str(instruction.get("id", ""))] = str(instruction.get("op", ""))
	var position := _grid_point(node.get("partenza", {}))
	var goal := _grid_point(node.get("obiettivo", {}))
	var direction := int((node.get("partenza", {}) as Dictionary).get("direzione", 1))
	var directions := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var trail: Array = [position]
	var executed := 0
	for raw_id in program:
		if executed >= int(node.get("maxPassi", 0)): break
		var id := str(raw_id)
		if not by_id.has(id): return {"correct": false, "reason": "Istruzione sconosciuta.", "trail": trail, "steps": executed, "direction": direction}
		match str(by_id[id]):
			"left": direction = posmod(direction - 1, 4)
			"right": direction = posmod(direction + 1, 4)
			"forward":
				var next: Vector2i = position + directions[direction]
				if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height or blocked.has(str(next)):
					return {"correct": false, "reason": "Il robot urta al passo %d." % (executed + 1), "trail": trail, "steps": executed + 1, "direction": direction}
				position = next
				trail.append(position)
		executed += 1
		if position == goal:
			return {"correct": true, "reason": "", "trail": trail, "steps": executed, "direction": direction}
	return {"correct": position == goal, "reason": "Il robot non ha raggiunto il bersaglio.", "trail": trail, "steps": executed, "direction": direction}

static func _validate_blank_map(node: Dictionary, errors: Array) -> void:
	var map_id := str(node.get("mapId", ""))
	if not MapGeometryCatalog.has_map(map_id):
		errors.append("carta da completare sconosciuta: %s" % map_id)
		return
	var available := MapGeometryCatalog.target_ids(map_id)
	var anchors: Array = node.get("ancore", [])
	if anchors.size() < 3:
		errors.append("carta da completare con meno di 3 ancore")
	for raw in anchors:
		var anchor_id := str(raw.get("id", "") if raw is Dictionary else raw)
		if not available.has(anchor_id): errors.append("ancora %s assente dalla carta %s" % [anchor_id, map_id])
	var labels: Array = node.get("etichette", [])
	if labels.size() < 3:
		errors.append("carta da completare con meno di 3 etichette")
	var label_ids: Dictionary = {}
	for raw in labels:
		var label := raw as Dictionary
		var id := str(label.get("id", ""))
		var anchor := str(label.get("ancora", ""))
		if id == "" or str(label.get("testo", "")).strip_edges() == "": errors.append("etichetta carta malformata")
		elif label_ids.has(id): errors.append("etichetta carta duplicata: %s" % id)
		label_ids[id] = true
		if not available.has(anchor): errors.append("etichetta %s punta ad ancora inesistente" % id)
	var tolerance := float(node.get("tolleranza", 0.0))
	if tolerance <= 0.0 or tolerance > 0.25:
		errors.append("tolleranza carta fuori scala 0..0.25")
	for raw in Array(node.get("percorso", [])):
		if not available.has(str(raw)): errors.append("percorso usa ancora inesistente: %s" % str(raw))

static func evaluate_blank_map(node: Dictionary, placements: Dictionary, route: Array = []) -> Dictionary:
	var map_id := str(node.get("mapId", ""))
	var map_data := MapGeometryCatalog.map_data(map_id)
	var targets := map_data.get("targets", {}) as Dictionary
	var bounds := map_data.get("bounds", Rect2()) as Rect2
	var tolerance := float(node.get("tolleranza", 0.08))
	for raw in ([] if str(node.get("modalita", "etichette")) == "percorso" else Array(node.get("etichette", []))):
		var label := raw as Dictionary
		var id := str(label.get("id", ""))
		var expected := str(label.get("ancora", ""))
		if not placements.has(id): return {"correct": false, "reason": "Manca l'etichetta %s." % str(label.get("testo", id))}
		var placed = placements[id]
		if placed is String:
			if str(placed) != expected: return {"correct": false, "reason": "%s non e' vicino alla sua ancora." % str(label.get("testo", id))}
		elif placed is Vector2:
			var world_point: Vector2 = targets.get(expected, Vector2.INF)
			var normalized := Vector2((world_point.x - bounds.position.x) / bounds.size.x, 1.0 - (world_point.y - bounds.position.y) / bounds.size.y)
			if (placed as Vector2).distance_to(normalized) > tolerance:
				return {"correct": false, "reason": "%s e' fuori dalla zona corretta." % str(label.get("testo", id))}
		else:
			return {"correct": false, "reason": "Posizione dell'etichetta non valida."}
	var expected_route: Array = node.get("percorso", [])
	if not expected_route.is_empty():
		if route.size() != expected_route.size(): return {"correct": false, "reason": "La rotta non tocca tutte le ancore."}
		for index in expected_route.size():
			if str(route[index]) != str(expected_route[index]):
				return {"correct": false, "reason": "La rotta cambia ordine all'ancora %d." % (index + 1)}
	return {"correct": true, "reason": ""}

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
