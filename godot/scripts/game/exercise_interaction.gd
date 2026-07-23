class_name ExerciseInteraction
extends RefCounted

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
	"multiple_choice", "numeric_input", "ordering", "matching",
	"classification", "hotspot", "graph", "circuit", "code_debug",
]
# La simulazione usa la stessa futura API visuale, ma non entra nelle missioni
# finché non possiede un modello disciplinare validato.
const PLANNED := ["simulation"]

const MIN_OPTIONS := 3      # scelta multipla: risposta + almeno 2 distrattori
const MIN_PAIRS := 3        # abbinamento: almeno 3 coppie
const MIN_ORDER := 2        # ordinamento: almeno 2 elementi

static func format_of(node: Dictionary) -> String:
	return str(node.get("format", "multiple_choice"))

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

# Valida un nodo. Ritorna {ok: bool, errors: Array[String]}.
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
		"ordering":
			_validate_ordering(node, errors)
		"matching":
			_validate_matching(node, errors)
		"classification":
			_validate_classification(node, errors)
		"hotspot":
			_validate_selectable_points(node, "hotspots", errors)
		"graph":
			_validate_selectable_points(node, "points", errors)
		"circuit":
			_validate_circuit(node, errors)
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

static func _validate_code_debug(node: Dictionary, errors: Array) -> void:
	var lines: Array = node.get("codeLines", [])
	var answer_line := int(node.get("answerLine", 0))
	if lines.size() < 2:
		errors.append("code-debug con meno di 2 righe")
	if answer_line < 1 or answer_line > lines.size():
		errors.append("answerLine fuori dal codice: %d" % answer_line)

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
