class_name ContentManager
extends RefCounted

## Carica i banchi di esercizi (JSON prodotti da scripts/build-exercise-banks.mjs)
## e costruisce le missioni selezionando item vicini alla difficoltà del livello.
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §3 (strategia "bake prima, port poi").

const BANKS := {
	"matematica": "res://data/banks/matematica-tabelline.json",
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
func build_mission(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null) -> Dictionary:
	var items := _load_bank(subject)
	var target := target_difficulty(level)
	var pool: Array = []
	for item in items:
		if abs(int(item.get("difficulty", 1)) - target) <= 1:
			pool.append(item)
	if pool.is_empty():
		pool = items.duplicate()
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var chosen: Array = []
	var count := mini(node_count, pool.size())
	for i in range(count):
		chosen.append(pool[generator.randi_range(0, pool.size() - 1)])
	return {
		"sessionId": "mission-%s-lvl%d" % [subject, level],
		"kind": "mission",
		"subject": subject,
		"level": level,
		"nodes": chosen,
		"shields": 3,
		"rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 30, "fragments": 2}},
	}

## Esame cumulativo dell'apparato corrente. In questa prima slice riusa il
## banco matematico della missione ma cambia il contratto: kind=final_exam e
## ricompensa di riparazione gestita da ProgressionManager.
func build_final_exam(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null) -> Dictionary:
	var exam := build_mission(subject, level, node_count, rng)
	exam["sessionId"] = "final-exam-%s-lvl%d" % [subject, level]
	exam["kind"] = "final_exam"
	exam["shields"] = 2
	exam["rewards"] = {"energyPerCorrect": 12, "onComplete": {"energy": 40, "fragments": 4}}
	return exam
