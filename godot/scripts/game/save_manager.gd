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
		"masteryByTopic": {},       # "subject:topic" -> float 0..1 (adattività fine)
		"missionsBySubject": {},    # subject -> int (azzerato al salire di livello)
		"apparatus": {},            # id -> {repairedLevel:int}
		"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []},
		"modules": {"owned": [], "equipped": []},
		"narrative": {"seen": [], "beats": {}},
		"progressReport": {"events": []},
		"daily": {"date": "", "missions": 0, "streak": 0},
		"spacedRepetition": {"due": {}, "history": []},
	}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		data = migrate_legacy_save(parsed)

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

# --- Padronanza per-argomento (adattività fine dentro la materia) -------------
# Chiave "subject:topic". Un topic mai incontrato torna -1.0 (sconosciuto), così
# la selezione può distinguere "debole" (basso ma visto) da "nuovo" (mai visto).
func topic_key(subject: String, topic: String) -> String:
	return "%s:%s" % [subject, topic]

func topic_mastery_of(subject: String, topic: String) -> float:
	return float(data.get("masteryByTopic", {}).get(topic_key(subject, topic), -1.0))

func set_topic_mastery(subject: String, topic: String, value: float) -> void:
	if not data.has("masteryByTopic"):
		data["masteryByTopic"] = {}
	data["masteryByTopic"][topic_key(subject, topic)] = clampf(value, 0.0, 1.0)

# Mappa topic -> mastery per una materia (solo i topic già incontrati). Serve alla
# selezione per privilegiare gli argomenti più deboli.
func topic_masteries(subject: String) -> Dictionary:
	var out: Dictionary = {}
	var prefix := "%s:" % subject
	for key in data.get("masteryByTopic", {}).keys():
		if str(key).begins_with(prefix):
			out[str(key).trim_prefix(prefix)] = float(data["masteryByTopic"][key])
	return out

func add_mission(subject: String) -> void:
	data["missionsBySubject"][subject] = missions_of(subject) + 1

func reset_missions() -> void:
	data["missionsBySubject"] = {}

func set_apparatus_repaired(id: String, repaired_level: int) -> void:
	data["apparatus"][id] = {"repairedLevel": repaired_level}

func set_level(value: int) -> void:
	data["level"] = value

func spend_energy(amount: int) -> bool:
	var cost := maxi(0, amount)
	if int(data["energy"]) < cost:
		return false
	data["energy"] = int(data["energy"]) - cost
	return true

## Applica uno stato iniziale esplicito per audit/import controllati. Il normale
## boot nativo non ne fornisce uno e mantiene il save locale autoritativo.
func apply_launch_state(request: Dictionary) -> void:
	var canonical = request.get("initialSave", null)
	if typeof(canonical) == TYPE_DICTIONARY:
		var candidate := migrate_legacy_save(canonical)
		if int(candidate.get("level", 0)) >= level():
			data = candidate
	if request.has("playerLevel"):
		set_level(maxi(level(), int(request.get("playerLevel", level()))))

func migrate_legacy_save(source: Dictionary) -> Dictionary:
	## Migrazione idempotente: non scarta campi futuri sconosciuti.
	var migrated := source.duplicate(true)
	for key in _default_data().keys():
		if not migrated.has(key):
			migrated[key] = _default_data()[key].duplicate(true) if typeof(_default_data()[key]) == TYPE_DICTIONARY else _default_data()[key]
	migrated["schemaVersion"] = SCHEMA_VERSION
	return migrated

func snapshot() -> Dictionary:
	return data.duplicate(true)
