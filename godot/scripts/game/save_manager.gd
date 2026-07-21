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
		"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []},
		"modules": {"owned": [], "equipped": []},
		"narrative": {"seen": [], "beats": {}},
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
		data = migrate_from_phaser(parsed)

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

func spend_energy(amount: int) -> bool:
	var cost := maxi(0, amount)
	if int(data["energy"]) < cost:
		return false
	data["energy"] = int(data["energy"]) - cost
	return true

## Importa il minimo stato condiviso dal bridge Phaser senza sovrascrivere i
## campi Godot più ricchi quando sono già presenti. Il bridge resta quindi
## compatibile durante la migrazione, mentre il save canonico cresce in Godot.
func import_bridge_request(request: Dictionary) -> void:
	# Energia e frammenti restano autoritativi da Phaser (valuta della migrazione).
	# Il LIVELLO invece è la scala apparati lato Godot: non deve regredire per un
	# handshake stale o una transizione interna mondo↔nave.
	if request.has("energy"):
		data["energy"] = maxi(0, int(request.get("energy", energy())))
	var outdoor: Dictionary = request.get("outdoorState", {})
	if outdoor.has("fragments"):
		data["fragments"] = maxi(0, int(outdoor.get("fragments", data.get("fragments", 0))))
	var canonical = request.get("godotSave", null)
	if typeof(canonical) == TYPE_DICTIONARY:
		var candidate := migrate_from_phaser(canonical)
		# Applica il save canonico ricevuto solo se non fa regredire il livello.
		if int(candidate.get("level", 0)) >= level():
			data = candidate
	if request.has("playerLevel"):
		set_level(maxi(level(), int(request.get("playerLevel", level()))))

func migrate_from_phaser(source: Dictionary) -> Dictionary:
	## Migrazione idempotente: non scarta campi futuri sconosciuti.
	var migrated := source.duplicate(true)
	for key in _default_data().keys():
		if not migrated.has(key):
			migrated[key] = _default_data()[key].duplicate(true) if typeof(_default_data()[key]) == TYPE_DICTIONARY else _default_data()[key]
	migrated["schemaVersion"] = SCHEMA_VERSION
	return migrated

func bridge_snapshot() -> Dictionary:
	return data.duplicate(true)
