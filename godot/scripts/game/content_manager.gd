class_name ContentManager
extends RefCounted

## Carica i banchi di esercizi (JSON prodotti da scripts/build-exercise-banks.mjs)
## e costruisce le missioni selezionando item vicini alla difficoltà del livello.
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §3 (strategia "bake prima, port poi").

## Ritmo cognitivo della materia (decisione didattica): le materie di RAGIONAMENTO
## non hanno mai limite di tempo — il bambino deve poter pensare senza pressione.
## Solo la matematica (tabelline) è "fluency", una competenza di rapidità/automatismo
## e l'unica per cui un tempo avrebbe senso didattico. Oggi NESSUNA materia è
## cronometrata (l'ExercisePlayer è turn-based): questa classificazione garantisce
## che, se mai si introdurrà un tempo su una fluency, il ragionamento resti esente,
## e alimenta l'affordance "senza limite di tempo" mostrata all'utente.
const PACE_REASONING := "reasoning"
const PACE_FLUENCY := "fluency"
const SUBJECT_PACE := {
	"matematica": PACE_FLUENCY,
	"italiano": PACE_REASONING,
	"inglese": PACE_REASONING,
	"coding": PACE_REASONING,
	"fisica": PACE_REASONING,
	"musica": PACE_REASONING,
	"latino": PACE_REASONING,
	"elettronica": PACE_REASONING,
	"geografia": PACE_REASONING,
	"scienze": PACE_REASONING,
	"cittadinanza": PACE_REASONING,
	"logica": PACE_REASONING,
}

# Ritmo della materia (default: ragionamento, cioè senza tempo — la scelta prudente
# per ogni materia nuova finché non è deliberatamente marcata "fluency").
static func subject_pace(subject: String) -> String:
	return str(SUBJECT_PACE.get(subject, PACE_REASONING))

# Vero se la materia NON deve mai avere limite di tempo (tutte tranne le fluency).
static func is_untimed(subject: String) -> bool:
	return subject_pace(subject) != PACE_FLUENCY

const BANKS := {
	"matematica": "res://data/banks/matematica-tabelline.json",
	"italiano": "res://data/banks/italiano-base.json",
	"inglese": "res://data/banks/inglese-base.json",
	"coding": "res://data/banks/coding-base.json",
	"fisica": "res://data/banks/fisica-base.json",
	"musica": "res://data/banks/musica-base.json",
	"latino": "res://data/banks/latino-base.json",
	"elettronica": "res://data/banks/elettronica-base.json",
	# Materie nuove (scope ampliato 2026-07-21). La difficoltà è tarata sul
	# LIVELLO (target_difficulty) come tutte le altre: nessun tetto per anno
	# scolastico (guardrail per livello raggiunto, non per età).
	"geografia": "res://data/banks/geografia-base.json",
	"scienze": "res://data/banks/scienze-base.json",
	"cittadinanza": "res://data/banks/cittadinanza-base.json",
	"logica": "res://data/banks/logica-base.json",
}

var _cache: Dictionary = {}  # subject -> Array item
var _difficulty_ranges: Dictionary = {}  # subject -> Vector2i(min,max) difficoltà nel banco
var _recent_math_signatures: Array = []
var _mission_serial := 0

func _load_bank(subject: String) -> Array:
	if _cache.has(subject):
		return _cache[subject]
	var items: Array = []
	if BANKS.has(subject):
		var path: String = BANKS[subject]
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed = JSON.parse_string(file.get_as_text())
				if typeof(parsed) == TYPE_DICTIONARY:
					items = parsed.get("items", [])
	_cache[subject] = items
	return items

# Difficoltà target in base al SOLO livello del giocatore (banda 1-4). È la base;
# la difficoltà effettiva la corregge con la mastery e la calibra sul banco reale.
static func target_difficulty(level: int) -> int:
	return clampi(1 + (level - 1) / 3, 1, 4)

# Correzione di difficoltà secondo la padronanza (mastery 0..1): chi fatica scende
# di un gradino, chi padroneggia sale. `mastery < 0` = sconosciuta → nessun nudge
# (fallback solo-livello, retro-compatibile con chiamanti/audit che non la passano).
static func mastery_nudge(mastery: float) -> int:
	if mastery < 0.0:
		return 0
	if mastery >= 0.85:
		return 1
	if mastery < 0.5:
		return -1
	return 0

# Range di difficoltà REALMENTE presente nel banco della materia (cache). Serve a
# calibrare la selezione per materia: senza, un target 4 su una materia il cui
# banco arriva a 2 (es. italiano) svuoterebbe la finestra e cadrebbe nel casuale.
func subject_difficulty_range(subject: String) -> Vector2i:
	if _difficulty_ranges.has(subject):
		return _difficulty_ranges[subject]
	var items := _load_bank(subject)
	var lo := 4
	var hi := 1
	for item in items:
		var d := clampi(int(item.get("difficulty", 1)), 1, 4)
		lo = mini(lo, d)
		hi = maxi(hi, d)
	if items.is_empty() or lo > hi:
		lo = 1
		hi = 4
	var span := Vector2i(lo, hi)
	_difficulty_ranges[subject] = span
	return span

# Numero di argomenti DISTINTI che la materia può proporre (dal banco). Alimenta
# la dimensione COPERTURA del gate (GateReadiness). Per la matematica, generata a
# runtime, il banco statico può non elencare topic: in tal caso torna 0 e la
# copertura ripiega sul minimo assoluto (la copertura vissuta la traccia comunque
# `masteryByTopic`, popolato dai topic del generatore).
func subject_topic_count(subject: String) -> int:
	var topics: Dictionary = {}
	for item in _load_bank(subject):
		var topic := str(item.get("topic", ""))
		if topic != "":
			topics[topic] = true
	return topics.size()

# Difficoltà EFFETTIVA per materia: banda di livello + nudge di mastery, poi
# calibrata (clamp) sul range che il banco può davvero servire. Così la selezione
# resta significativa su ogni materia, anche con banchi di ampiezza diversa.
func effective_difficulty(subject: String, level: int, mastery: float = -1.0) -> int:
	var span := subject_difficulty_range(subject)
	return clampi(target_difficulty(level) + mastery_nudge(mastery), span.x, span.y)

# Livello efficace per il generatore matematico: la mastery sposta il livello di
# ±3 (≈ ±1 gradino di complessità), così anche la matematica generata è adattiva.
static func math_effective_level(level: int, mastery: float = -1.0) -> int:
	return maxi(1, level + mastery_nudge(mastery) * 3)

# Costruisce una sessione-missione: alcuni item della materia vicini alla
# difficoltà del livello. `rng` opzionale per selezione deterministica nei test.
# Selezione adattiva: prima i topic in ripasso spaziato (`review_due` = mappa
# "subject:topic" -> conteggio, dagli errori passati), poi item vicini alla
# difficoltà del livello. Gli item di ripasso sono marcati `review:true`.
# `topic_mastery` = {topic: float 0..1} degli argomenti già incontrati: la
# selezione privilegia gli argomenti PIÙ DEBOLI (mastery < soglia), così il
# bambino esercita dentro la materia proprio ciò che padroneggia meno.
const WEAK_TOPIC_THRESHOLD := 0.6

func build_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	_mission_serial += 1
	if subject == "matematica":
		var review_topics: Array = []
		for key in review_due.keys():
			var prefix := "matematica:"
			if str(key).begins_with(prefix) and int(review_due[key]) > 0:
				review_topics.append(str(key).trim_prefix(prefix))
		# La mastery sposta il livello efficace: matematica generata adattiva.
		var generated := MathExerciseGenerator.new().build_nodes(math_effective_level(level, mastery), node_count, generator, _recent_math_signatures, review_topics)
		return _session(subject, level, generated)
	var items := _load_bank(subject)
	# Difficoltà efficace: livello + mastery, calibrata sul range reale del banco.
	var target := effective_difficulty(subject, level, mastery)
	var review_pool: Array = []
	var weak_near_pool: Array = []  # item vicini alla difficoltà su argomenti deboli
	var near_pool: Array = []       # gli altri item vicini alla difficoltà
	for item in items:
		var topic := str(item.get("topic", ""))
		if int(review_due.get("%s:%s" % [subject, topic], 0)) > 0:
			review_pool.append(item)
		elif abs(int(item.get("difficulty", 1)) - target) <= 1:
			var tm := float(topic_mastery.get(topic, -1.0))
			if tm >= 0.0 and tm < WEAK_TOPIC_THRESHOLD:
				weak_near_pool.append(item)
			else:
				near_pool.append(item)
	if review_pool.is_empty() and weak_near_pool.is_empty() and near_pool.is_empty():
		near_pool = items.duplicate()
	var chosen: Array = []
	# Priorità: ripasso spaziato → argomenti deboli → resto vicino → riempimento.
	_drain_into(chosen, review_pool, node_count, generator, true)
	_drain_into(chosen, weak_near_pool, node_count, generator, false)
	_drain_into(chosen, near_pool, node_count, generator, false)
	while chosen.size() < node_count and not items.is_empty():
		chosen.append(items[generator.randi_range(0, items.size() - 1)].duplicate())
	return _session(subject, level, chosen)

func _session(subject: String, level: int, nodes: Array) -> Dictionary:
	return {
		"sessionId": "mission-%s-lvl%d-%d" % [subject, level, _mission_serial],
		"kind": "mission",
		"subject": subject,
		"level": level,
		"nodes": nodes,
		"shields": 3,
		# Ritmo cognitivo e limite di tempo: le materie di ragionamento sono sempre
		# non cronometrate (`timed=false`). Nessuna sessione è cronometrata oggi;
		# il campo rende la politica esplicita, verificabile e leggibile dalla UI.
		"pace": subject_pace(subject),
		"timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 30, "fragments": 2}},
	}

# Sposta item unici da `pool` in `chosen` (fino a node_count), marcando il ripasso.
func _drain_into(chosen: Array, pool: Array, node_count: int, generator: RandomNumberGenerator, review: bool) -> void:
	var work := pool.duplicate()
	while chosen.size() < node_count and not work.is_empty():
		var idx := generator.randi_range(0, work.size() - 1)
		var item: Dictionary = work[idx].duplicate()
		work.remove_at(idx)
		if review:
			item["review"] = true
		chosen.append(item)

# Tema visivo dell'enigma per materia: la logica è identica, cambia solo la
# "costruzione" che Codex rende (ponte, cristalli, porta…). Default: "ponte".
const ENIGMA_THEMES := {
	"matematica": "ponte",
	"coding": "circuito",
	"musica": "cristalli",
	"latino": "porta",
	"fisica": "reattore",
	"inglese": "porta",
	"italiano": "porta",
	"elettronica": "circuito",
	# Materie nuove: temi visivi da rendere (Codex). Fallback "ponte" se assente.
	"geografia": "mappa",
	"scienze": "serra",
	"cittadinanza": "rete",
	"logica": "griglia",
}

static func enigma_theme(subject: String) -> String:
	return str(ENIGMA_THEMES.get(subject, "ponte"))

## Enigma ambientale: una missione la cui risposta corretta costruisce, campata
## per campata, un elemento del mondo (il ponte, la porta…). Riusa la selezione
## adattiva di `build_mission`; ogni esercizio corrisponde a una "campata"
## (`stages` = node_count), così il progresso misura QUANTI hai capito, non la
## grandezza dei numeri. Contratto in più rispetto alla missione: `theme` e
## `stages` per la resa (vedi OutdoorGameplay.enigma_progress, gate I-01).
func build_enigma(subject: String, level: int, node_count: int = 4, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	var session := build_mission(subject, level, node_count, review_due, rng, mastery, topic_mastery)
	session["sessionId"] = "enigma-%s-lvl%d" % [subject, level]
	session["kind"] = "enigma"
	session["theme"] = enigma_theme(subject)
	session["stages"] = int(session.get("nodes", []).size())
	session["shields"] = 3
	session["rewards"] = {"energyPerCorrect": 10, "onComplete": {"energy": 35, "fragments": 3}}
	return session

## Esame cumulativo dell'apparato corrente. In questa prima slice riusa il
## banco matematico della missione ma cambia il contratto: kind=final_exam e
## ricompensa di riparazione gestita da ProgressionManager.
func build_final_exam(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	var exam := build_mission(subject, level, node_count, {}, rng, mastery, topic_mastery)
	exam["sessionId"] = "final-exam-%s-lvl%d" % [subject, level]
	exam["kind"] = "final_exam"
	exam["shields"] = 2
	exam["rewards"] = {"energyPerCorrect": 12, "onComplete": {"energy": 40, "fragments": 4}}
	return exam
