class_name GameSaveManager
extends RefCounted

## Save canonico del gioco (full-Godot). Fonte di verità dello stato del
## giocatore: livello, energia/frammenti, padronanza per materia, conteggio
## missioni del livello corrente, stato apparati, cosmetici, moduli.
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §6 (Contratti dati).

const SAVE_PATH := "user://eli-quest-save.json"
const SCHEMA_VERSION := 1

var data: Dictionary = _default_data()

static func _default_data() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"playerId": "local",
		"level": 1,
		"energy": 0,
		"fragments": 0,
		"mastery": {},              # subject -> float 0..1
		"missionsBySubject": {},    # subject -> int (azzerato al salire di livello)
		"apparatus": {},            # id -> {repairedLevel:int}
		"cosmetics": {"unlocked": [], "equipped": {}},
		"modules": {"owned": [], "equipped": []},
	}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("schemaVersion", 0)) == SCHEMA_VERSION:
		data = parsed

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func level() -> int:
	return int(data["level"])

func energy() -> int:
	return int(data["energy"])

func mastery_of(subject: String) -> float:
	return float(data["mastery"].get(subject, 0.0))

func missions_of(subject: String) -> int:
	return int(data["missionsBySubject"].get(subject, 0))

func add_energy(amount: int) -> void:
	data["energy"] = int(data["energy"]) + amount

func set_mastery(subject: String, value: float) -> void:
	data["mastery"][subject] = clampf(value, 0.0, 1.0)

func add_mission(subject: String) -> void:
	data["missionsBySubject"][subject] = missions_of(subject) + 1

func reset_missions() -> void:
	data["missionsBySubject"] = {}

func set_apparatus_repaired(id: String, repaired_level: int) -> void:
	data["apparatus"][id] = {"repairedLevel": repaired_level}

func set_level(value: int) -> void:
	data["level"] = value
