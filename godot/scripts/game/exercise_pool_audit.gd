extends SceneTree

## Audit del MECCANISMO a insieme (Fase 0). Nessun contenuto nuovo da verificare:
## qui si verifica che l'infrastruttura regga, prima di versarci dentro duemila
## elementi nelle fasi successive.
##
## Verifica quattro cose, in ordine di gravità se saltassero:
##  1. **determinismo** — stesso seed, stessa prova: è un invariante del progetto
##     intero, e un'estrazione è il posto più facile dove perderlo;
##  2. **nessuna prova ambigua** — le estrazioni rispettano gli stessi vincoli che
##     `ExerciseInteraction.validate` pretende, applicati PRIMA di costruire il
##     nodo invece che dopo (validare a posteriori scopre il difetto quando il
##     bambino l'ha già in mano);
##  3. **coesistenza** — specifiche statiche e a insieme convivono nella stessa
##     tabella, altrimenti la migrazione non sarebbe incrementale e ogni fase
##     dovrebbe convertire tutto in un colpo solo;
##  4. **identità di contenuto** — la firma condivisa distingue due estrazioni
##     diverse e collassa la stessa prova ripresentata in altro ordine. Senza
##     questo la profondità aggiunta nelle Fasi 1–3 sarebbe invisibile sia alla
##     memoria anti-ripetizione sia alla misura.
##
## Il punto 3 usa specifiche sintetiche perché in Fase 0 non esiste ancora
## contenuto a insieme per ordinamento e smistamento. È deliberato: il meccanismo
## deve essere provato *prima* di autorare, non dopo.

# Insieme sintetico di ordinamento: 12 voci, se ne pescano 4 → C(12,4) = 495.
const ORDERING_POOL := {
	"topic": "prova",
	"kind": "pool",
	"draw": 4,
	"prompt": "Ordina dal più piccolo al più grande.",
	"pool": [
		{"label": "due", "value": 2.0}, {"label": "tre", "value": 3.0},
		{"label": "cinque", "value": 5.0}, {"label": "sette", "value": 7.0},
		{"label": "undici", "value": 11.0}, {"label": "tredici", "value": 13.0},
		{"label": "diciassette", "value": 17.0}, {"label": "diciannove", "value": 19.0},
		{"label": "ventitré", "value": 23.0}, {"label": "ventinove", "value": 29.0},
		{"label": "trentuno", "value": 31.0}, {"label": "trentasette", "value": 37.0},
	],
}

# Insieme sintetico di smistamento: 12 tessere su 3 contenitori, se ne pescano 6.
const CLASSIFICATION_POOL := {
	"topic": "prova",
	"draw": 6,
	"prompt": "Metti ogni tessera nel gruppo giusto.",
	"categories": ["alfa", "beta", "gamma"],
	"assignments": {
		"a1": "alfa", "a2": "alfa", "a3": "alfa", "a4": "alfa",
		"b1": "beta", "b2": "beta", "b3": "beta", "b4": "beta",
		"g1": "gamma", "g2": "gamma", "g3": "gamma", "g4": "gamma",
	},
}

## Difficoltà usata dalle prove sintetiche: quella centrale della campagna.
## Da quando esiste il gradiente (Fase 4) i costruttori ricevono una DIFFICOLTÀ,
## non un livello — passare qui un numero di livello darebbe un'estrazione
## silenziosamente diversa da quella che il gioco produce.
const LEVEL := 13
const EXPECTED_DRAW := 4   # `draw` dichiarato = numero alla difficoltà centrale

const RUNS := 200

func _init() -> void:
	_test_conteggio_combinazioni()
	_test_determinismo()
	_test_estrazioni_valide()
	_test_coesistenza()
	_test_copertura_categorie()
	_test_insiemi_riempibili()
	_test_identita_di_contenuto()
	print("Exercise pool audit OK — il meccanismo a insieme regge: deterministico, senza ambiguità, coesistente")
	quit(0)

## Il conto è la ragione per cui esiste tutto il piano: se sbaglia, il piano
## punta al bersaglio sbagliato.
func _test_conteggio_combinazioni() -> void:
	assert(ExercisePool.combinations(32, 4) == 35960, "C(32,4) = 35960")
	assert(ExercisePool.combinations(40, 3) == 9880, "C(40,3) = 9880")
	assert(ExercisePool.combinations(24, 4) == 10626, "C(24,4) = 10626")
	assert(ExercisePool.combinations(18, 5) == 8568, "C(18,5) = 8568")
	assert(ExercisePool.combinations(8, 8) == 1, "pescare tutto = una prova sola")
	assert(ExercisePool.combinations(5, 9) == 0, "non si pesca più di quanto c'è")
	# Copertura: da 4+4+4 tessere sceglierne 6 toccando tutti e tre i gruppi.
	# C(12,6) = 924, meno le estrazioni che lasciano un gruppo vuoto.
	var covering := ExercisePool.covering_combinations([4, 4, 4], 6)
	assert(covering > 0 and covering < ExercisePool.combinations(12, 6),
		"la copertura deve escludere qualche estrazione, non tutte né nessuna: %d" % covering)
	assert(ExercisePool.covering_combinations([4, 4, 4], 2) == 0,
		"due tessere non possono toccare tre gruppi")

func _test_determinismo() -> void:
	var manager := MinigameManager.new()
	for seed_value in [1, 7, 99, 12345]:
		var first := _build_all(manager, int(seed_value))
		var second := _build_all(manager, int(seed_value))
		assert(first == second,
			"stesso seed, prova diversa: il determinismo è saltato (seed %d)" % int(seed_value))

func _build_all(manager: MinigameManager, seed_value: int) -> Array:
	var signatures: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for node_data in manager.build_minigame(str(subject_data), 13, rng).get("nodes", []):
			signatures.append(ExerciseSignature.of(node_data as Dictionary))
	# Anche i due formati a insieme sintetici, che nessuna materia serve ancora.
	var rng_pool := RandomNumberGenerator.new()
	rng_pool.seed = seed_value
	signatures.append(ExerciseSignature.of(
		manager._ordering_node("logica", ORDERING_POOL, LEVEL, 0, rng_pool, 0)))
	signatures.append(ExerciseSignature.of(
		manager._classification_node("logica", CLASSIFICATION_POOL, LEVEL, 0, rng_pool, 1)))
	return signatures

## Ogni estrazione deve superare la validazione REALE del gioco, non una copia
## indulgente: è lo stesso controllo che gira sui contenuti autorati.
func _test_estrazioni_valide() -> void:
	var manager := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var problems: Array = []
	for run in range(RUNS):
		for node in [
			manager._ordering_node("logica", ORDERING_POOL, LEVEL, 0, rng, 0),
			manager._classification_node("logica", CLASSIFICATION_POOL, LEVEL, 0, rng, 1),
		]:
			var report := ExerciseInteraction.validate(node)
			if not bool(report["ok"]):
				problems.append("%s: %s" % [str(node.get("format", "")), str(report["errors"])])
	# Anche gli abbinamenti veri di tutte le materie, che ora passano dal
	# meccanismo: la conversione non deve aver rotto contenuto già consegnato.
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		for level in [1, 6, 13, 24]:
			for run in range(20):
				for node_data in manager.build_minigame(str(subject_data), level, rng).get("nodes", []):
					var node := node_data as Dictionary
					var report := ExerciseInteraction.validate(node)
					if not bool(report["ok"]):
						problems.append("%s L%d %s: %s" % [
							str(subject_data), level, str(node.get("format", "")), str(report["errors"])])
	if not problems.is_empty():
		printerr("ESTRAZIONI NON VALIDE — %d problemi (primi 10):" % problems.size())
		for problem in problems.slice(0, 10):
			printerr("  - %s" % problem)
		quit(1)

## Le due forme devono convivere nella stessa tabella: è la condizione che rende
## ogni fase spedibile invece di richiedere una conversione totale.
func _test_coesistenza() -> void:
	var manager := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var static_spec := {"topic": "prova", "prompt": "Ordina.", "correctOrder": ["uno", "due", "tre", "quattro"]}
	var seen_static: Dictionary = {}
	var seen_pool: Dictionary = {}
	for run in range(RUNS):
		seen_static[ExerciseSignature.of(manager._ordering_node("logica", static_spec, LEVEL, 0, rng, 0))] = true
		seen_pool[ExerciseSignature.of(manager._ordering_node("logica", ORDERING_POOL, LEVEL, 0, rng, 0))] = true
	assert(seen_static.size() == 1,
		"una specifica statica è UNA prova, comunque la si mescoli: viste %d" % seen_static.size())
	assert(seen_pool.size() > 50,
		"un insieme da 495 combinazioni deve produrre molte prove diverse in %d giri: viste %d" % [
			RUNS, seen_pool.size()])
	# E la profondità dichiarata deve corrispondere alla forma della specifica.
	assert(MinigameManager.spec_depth("ordering", static_spec, LEVEL) == 1, "statica = profondità 1")
	assert(MinigameManager.spec_depth("ordering", ORDERING_POOL, LEVEL) == ExercisePool.combinations(12, EXPECTED_DRAW),
		"insieme = C(12,%d)" % EXPECTED_DRAW)

## Un contenitore vuoto non è una prova più facile: è una prova rotta.
func _test_copertura_categorie() -> void:
	var manager := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for run in range(RUNS):
		var node := manager._classification_node("logica", CLASSIFICATION_POOL, LEVEL, 0, rng, 0)
		var used: Dictionary = {}
		for key in (node["assignments"] as Dictionary).keys():
			used[str((node["assignments"] as Dictionary)[key])] = true
		assert(used.size() == Array(CLASSIFICATION_POOL["categories"]).size(),
			"estrazione con un contenitore vuoto: %d gruppi su %d" % [
				used.size(), Array(CLASSIFICATION_POOL["categories"]).size()])
		assert((node["items"] as Array).size() == int(CLASSIFICATION_POOL["draw"]),
			"estratte %d tessere invece di %d" % [
				(node["items"] as Array).size(), int(CLASSIFICATION_POOL["draw"])])

## Ogni insieme autorato deve poter riempire la sua estrazione rispettando i
## vincoli di unicità. Se non ci riesce produce prove corte a runtime — e le prove
## corte le scopre il bambino, non l'audit.
func _test_insiemi_riempibili() -> void:
	var problems: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for level in [1, 13, 24]:
			for spec_data in MinigameManager.eligible_specs(subject, "matching", level):
				var spec := spec_data as Dictionary
				var count := MinigameManager.matching_draw(spec, level)
				if count < ExerciseInteraction.MIN_PAIRS:
					problems.append("%s L%d «%s»: estrae %d coppie, il minimo è %d" % [
						subject, level, str(spec.get("topic", "?")), count, ExerciseInteraction.MIN_PAIRS])
				if not ExercisePool.can_fill(spec, "pairs", count, MinigameManager.MATCHING_UNIQUE):
					problems.append("%s L%d «%s»: l'insieme non può riempire %d coppie distinte" % [
						subject, level, str(spec.get("topic", "?")), count])
	if not problems.is_empty():
		printerr("INSIEMI NON RIEMPIBILI — %d problemi:" % problems.size())
		for problem in problems:
			printerr("  - %s" % problem)
		quit(1)

## La firma guarda il contenuto, mai la presentazione: è ciò che rende visibile la
## profondità e ciò che fa scattare la memoria anti-ripetizione.
func _test_identita_di_contenuto() -> void:
	var base := {
		"format": "code_debug", "prompt": "Trova l'errore.", "topic": "prova",
		"codeLines": ["a = 1", "b = 2", "c = 3"], "answerLine": 2, "answer": "2",
	}
	var shuffled := {
		"format": "code_debug", "prompt": "Trova l'errore.", "topic": "prova",
		"codeLines": ["c = 3", "b = 2", "a = 1"], "answerLine": 2, "answer": "2",
	}
	assert(ExerciseSignature.of(base) == ExerciseSignature.of(shuffled),
		"rimescolare le righe non crea una prova nuova")
	var different := {
		"format": "code_debug", "prompt": "Trova l'errore.", "topic": "prova",
		"codeLines": ["c = 3", "b = 2", "a = 1"], "answerLine": 1, "answer": "1",
	}
	assert(ExerciseSignature.of(base) != ExerciseSignature.of(different),
		"un'altra riga giusta è un'altra prova")
	var order_a := {"format": "ordering", "prompt": "Ordina.",
		"items": ["b", "a", "c"], "correctOrder": ["a", "b", "c"]}
	var order_b := {"format": "ordering", "prompt": "Ordina.",
		"items": ["c", "b", "a"], "correctOrder": ["a", "b", "c"]}
	assert(ExerciseSignature.of(order_a) == ExerciseSignature.of(order_b),
		"gli elementi mescolati diversamente sono la stessa prova")
	var order_c := {"format": "ordering", "prompt": "Ordina.",
		"items": ["c", "b", "a"], "correctOrder": ["c", "b", "a"]}
	assert(ExerciseSignature.of(order_a) != ExerciseSignature.of(order_c),
		"un ordine giusto diverso è un'altra prova")
	var match_a := {"format": "matching", "prompt": "Abbina.",
		"pairs": [{"left": "x", "right": "1"}, {"left": "y", "right": "2"}]}
	var match_b := {"format": "matching", "prompt": "Abbina.",
		"pairs": [{"left": "y", "right": "2"}, {"left": "x", "right": "1"}]}
	assert(ExerciseSignature.of(match_a) == ExerciseSignature.of(match_b),
		"le stesse coppie in altro ordine sono la stessa prova")
