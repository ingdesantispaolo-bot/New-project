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
}

var _cache: Dictionary = {}  # subject -> Array item

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
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var chosen: Array = []
	_drain_into(chosen, review_pool, node_count, generator, true)
	_drain_into(chosen, near_pool, node_count, generator, false)
	while chosen.size() < node_count and not items.is_empty():
		chosen.append(items[generator.randi_range(0, items.size() - 1)].duplicate())
	return {
		"sessionId": "mission-%s-lvl%d" % [subject, level],
		"kind": "mission",
		"subject": subject,
		"level": level,
		"nodes": chosen,
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
