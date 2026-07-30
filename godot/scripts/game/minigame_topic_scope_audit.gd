extends SceneTree

## Audit del REGISTRO degli argomenti dei minigiochi (30 luglio).
##
## Il guard-rail che mancava. `world_lesson_audit` controlla una direzione sola —
## che una lezione non prometta argomenti che la materia non sa servire — ma
## nessuno controllava l'altra: che un minigioco non EMETTA a runtime un argomento
## che non esiste nel registro della materia.
##
## È il buco da cui è passato il difetto trovato giocando: il generatore
## quantitativo di matematica dichiarava `topic: "sequenze"` senza comparire in
## nessuna tabella, quindi `topics_for()` non lo vedeva e nessun audit poteva
## accorgersene. La padronanza finiva su un argomento che quei mondi non
## insegnano, e la padronanza conta nel gate.
##
## Verifica su TUTTE le materie e TUTTI i livelli 1→24:
##  - ogni nodo dichiara un argomento non vuoto;
##  - l'argomento appartiene al registro della materia (tabelle + banco statico,
##    più i concetti del generatore per matematica);
##  - regressione mirata: l'ordinamento di matematica non presenta interi nudi e
##    resta sugli argomenti dei suoi mondi.

func _init() -> void:
	var content := ContentManager.new()
	var manager := MinigameManager.new()
	_test_registro_argomenti(content, manager)
	_test_ordinamento_matematica_calcolabile(manager)
	_test_logica_ha_ordinamenti_autorati(manager)
	print("Minigame topic scope audit OK — nessun argomento fuori registro")
	quit(0)

## Registro degli argomenti validi per una materia: ciò che il banco statico
## serve, più ciò che le tabelle dei minigiochi dichiarano. Per matematica si
## aggiungono i concetti del generatore, come fa già `world_lesson_audit`: è la
## stessa nozione di "argomento reale", non una seconda.
func _valid_topics(content: ContentManager, subject: String) -> Dictionary:
	var valid: Dictionary = {}
	for t in content.bank_topics(subject):
		valid[str(t)] = true
	for t in MinigameManager.topics_for(subject):
		valid[str(t)] = true
	if subject == "matematica":
		for t in KnowledgeCodex.MATH_CONCEPTS.keys():
			valid[str(t)] = true
	return valid

func _test_registro_argomenti(content: ContentManager, manager: MinigameManager) -> void:
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var valid := _valid_topics(content, str(subject))
		for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("topic-scope:%s:%d" % [str(subject), level])
			var session := manager.build_minigame(str(subject), level, rng)
			var nodes: Array = session.get("nodes", [])
			assert(not nodes.is_empty(), "%s L%d: minigioco senza nodi" % [str(subject), level])
			for node_data in nodes:
				var node: Dictionary = node_data
				var topic := str(node.get("topic", ""))
				assert(
					topic != "",
					"%s L%d: nodo %s senza argomento" % [str(subject), level, str(node.get("id", "?"))])
				assert(
					valid.has(topic),
					"%s L%d: argomento fuori registro: %s (nodo %s)" % [
						str(subject), level, topic, str(node.get("id", "?"))])

func _test_ordinamento_matematica_calcolabile(manager: MinigameManager) -> void:
	# Regressione mirata sul difetto del 30 luglio: gli elementi non possono essere
	# interi nudi, e l'argomento deve essere quello dichiarato dai mondi di
	# matematica (tabelline fino al 12, frazioni dal 13).
	for level in [1, 4, 8, 12, 13, 18, 24]:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("math-order:%d" % level)
		var session := manager.build_minigame("matematica", level, rng)
		var found := false
		for node_data in session.get("nodes", []):
			var node: Dictionary = node_data
			if str(node.get("format", "")) != "ordering":
				continue
			found = true
			var expected := "tabelline" if level <= 12 else "frazioni"
			assert(
				str(node.get("topic", "")) == expected,
				"matematica L%d: ordinamento su argomento %s, atteso %s" % [
					level, str(node.get("topic", "")), expected])
			var items: Array = node.get("items", [])
			assert(items.size() >= 4, "matematica L%d: ordinamento con soli %d elementi" % [level, items.size()])
			for item in items:
				assert(
					not str(item).is_valid_int(),
					"matematica L%d: elemento '%s' è un intero nudo — si ordina senza calcolare" % [
						level, str(item)])
			# L'ordine corretto deve essere una permutazione degli elementi mostrati.
			var correct: Array = node.get("correctOrder", [])
			assert(correct.size() == items.size(), "matematica L%d: correctOrder di lunghezza diversa" % level)
			for item in items:
				assert(correct.has(item), "matematica L%d: elemento '%s' assente da correctOrder" % [level, str(item)])
			# E la spiegazione deve mostrare il calcolo, non solo la sequenza.
			if level <= 12:
				assert(
					"=" in str(node.get("explanation", "")),
					"matematica L%d: la spiegazione deve mostrare i prodotti calcolati" % level)
		assert(found, "matematica L%d: nessun ordinamento nella sessione" % level)

func _test_logica_ha_ordinamenti_autorati(manager: MinigameManager) -> void:
	# La logica non deve più ricevere l'ordinamento di numeri: i suoi argomenti
	# (sequenze, deduzioni, analogie) riguardano regole, non grandezze.
	assert(
		not MinigameManager.NUMERIC_ORDERING_SUBJECTS.has("logica"),
		"la logica non deve usare l'ordinamento quantitativo")
	assert(
		MinigameManager.ORDERING.has("logica"),
		"la logica deve avere ordinamenti autorati")
	var lesson_topics: Dictionary = {}
	for level in [12, 24]:
		for t in WorldLessonCatalog.topics(level):
			lesson_topics[str(t)] = true
	for spec_data in Array(MinigameManager.ORDERING["logica"]):
		var spec: Dictionary = spec_data
		assert(
			lesson_topics.has(str(spec.get("topic", ""))),
			"logica: ordinamento su argomento %s, fuori dalle lezioni dei mondi 12 e 24" % str(spec.get("topic", "")))
		var correct: Array = spec.get("correctOrder", [])
		assert(correct.size() >= 3, "logica: ordinamento troppo corto (%d elementi)" % correct.size())
