class_name ContentManager
extends RefCounted

## Carica i banchi di esercizi (JSON prodotti da scripts/build-exercise-banks.mjs)
## e costruisce le missioni selezionando item vicini alla difficoltà del livello.
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §3 (strategia "bake prima, port poi").

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

# Difficoltà target in base al livello del giocatore.
static func target_difficulty(level: int) -> int:
	return clampi(1 + (level - 1) / 3, 1, 4)

# Costruisce una sessione-missione: alcuni item della materia vicini alla
# difficoltà del livello. `rng` opzionale per selezione deterministica nei test.
# Selezione adattiva: prima i topic in ripasso spaziato (`review_due` = mappa
# "subject:topic" -> conteggio, dagli errori passati), poi item vicini alla
# difficoltà del livello. Gli item di ripasso sono marcati `review:true`.
func build_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null) -> Dictionary:
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
		var generated := MathExerciseGenerator.new().build_nodes(level, node_count, generator, _recent_math_signatures, review_topics)
		return _session(subject, level, generated)
	var items := _load_bank(subject)
	var target := target_difficulty(level)
	var review_pool: Array = []
	var near_pool: Array = []
	for item in items:
		var key := "%s:%s" % [subject, str(item.get("topic", ""))]
		if int(review_due.get(key, 0)) > 0:
			review_pool.append(item)
		elif abs(int(item.get("difficulty", 1)) - target) <= 1:
			near_pool.append(item)
	if near_pool.is_empty() and review_pool.is_empty():
		near_pool = items.duplicate()
	var chosen: Array = []
	_drain_into(chosen, review_pool, node_count, generator, true)
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
func build_enigma(subject: String, level: int, node_count: int = 4, review_due: Dictionary = {}, rng: RandomNumberGenerator = null) -> Dictionary:
	var session := build_mission(subject, level, node_count, review_due, rng)
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
func build_final_exam(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null) -> Dictionary:
	var exam := build_mission(subject, level, node_count, {}, rng)
	exam["sessionId"] = "final-exam-%s-lvl%d" % [subject, level]
	exam["kind"] = "final_exam"
	exam["shields"] = 2
	exam["rewards"] = {"energyPerCorrect": 12, "onComplete": {"energy": 40, "fragments": 4}}
	return exam
