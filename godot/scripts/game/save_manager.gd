class_name GameSaveManager
extends RefCounted

## Save canonico del gioco (full-Godot). Fonte di verità dello stato del
## giocatore: rango dell'avventura (level), economia (energia/frammenti),
## competenza per materia/argomento (mastery / masteryByTopic), evidenza per il
## gate (missioni cumulative + soglia già "consumata"), stato apparati e stato
## persistente dei mondi (incontri, tesori, hazard).
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §6 (Contratti dati) e O-P0 in insieme.md.
##
## SEPARAZIONE DEGLI STATI (O-P0.5):
##   - `level`            → rango dell'avventura (quale mondo/apparato).
##   - `mastery`/`byTopic`→ competenza per materia e per argomento (persistente).
##   - `missionsBySubject`→ evidenza CUMULATIVA di missioni superate per materia
##                          (non si azzera mai: il lavoro non va perso, O-P0.3).
##   - `gateConsumed`     → quante missioni per materia erano già state "spese"
##                          all'ultima apertura del gate di quella materia; il
##                          progresso verso il gate corrente è la differenza.
##   - `apparatus`        → stato della nave (nodi riparati).
##   - `worldProgress`    → stato persistente di ogni mondo (incontri/tesori).

const SAVE_PATH := "user://eli-quest-save.json"
const SCHEMA_VERSION := 2

var data: Dictionary = _default_data()

static func _default_data() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"playerId": "local",
		"level": 1,                 # rango dell'avventura
		"energy": 0,
		"fragments": 0,             # valuta canonica (persistente, O-P0.4)
		"mastery": {},              # subject -> float 0..1
		"masteryByTopic": {},       # "subject:topic" -> float 0..1 (adattività fine)
		"missionsBySubject": {},    # subject -> int CUMULATIVO (mai azzerato, O-P0.3)
		"gateConsumed": {},         # subject -> int già speso ai gate passati
		"apparatus": {},            # id -> {repairedLevel:int}
		# Mondi (O-P1): livelli sbloccati (destinazioni di viaggio dalla nave) e
		# mondo attualmente giocato. Il rango `level` è la frontiera di
		# progressione; `worlds.current` può puntare a un mondo già scoperto quando
		# si rivisita. Lo stato persistente per mondo vive in `worldProgress`.
		"worlds": {"unlocked": [1], "current": 1},
		"worldProgress": {},        # "level" -> {completedEncounterIds, collectedTreasureIds, clearedHazardIds}
		"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []},
		"modules": {"owned": [], "equipped": []},
		"narrative": {"seen": [], "beats": {}},
		"progressReport": {"events": []},
		"daily": {"date": "", "missions": 0, "streak": 0},
		# Ripasso spaziato con PIANIFICAZIONE TEMPORALE reale (O-P0.7): un orologio
		# di sessioni monotòno e, per ogni "subject:topic", quando ripresentarlo.
		"spacedRepetition": {"sessionClock": 0, "schedule": {}, "history": []},
		# Manuale NORA (O-P4): stato di conoscenza per argomento ("subject:topic" ->
		# unknown/encountered/consulted/applied/consolidated).
		"codex": {},
		# Stato relazionale di NORA (O-P4): integrità nave, ricordi, fiducia.
		"nora": {"integrity": 0.0, "memory": 0, "trust": 0.5},
		# Configurazione dell'esperienza (O-P6): fascia scolastica, curriculum e
		# materie attive (tutte e 12 di default; configurabili senza toccare il codice).
		"config": {"schoolBand": "primaria", "curriculum": "base", "activeSubjects": []},
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

func fragments() -> int:
	return int(data.get("fragments", 0))

func mastery_of(subject: String) -> float:
	return float(data["mastery"].get(subject, 0.0))

# Missioni CUMULATIVE superate per materia (mai azzerate). Usare
# `missions_toward_gate` per il progresso verso il gate corrente.
func missions_of(subject: String) -> int:
	return int(data["missionsBySubject"].get(subject, 0))

# Missioni già "spese" ai gate precedenti di questa materia (high-water mark).
func gate_consumed_of(subject: String) -> int:
	return int(data.get("gateConsumed", {}).get(subject, 0))

# Progresso verso il gate CORRENTE della materia: missioni cumulative meno quelle
# già consumate quando il gate della materia fu aperto l'ultima volta. Così il
# lavoro nelle materie non correnti non va perso e le ricomparse cicliche della
# stessa materia (es. matematica al livello 1 e 13) richiedono missioni NUOVE.
func missions_toward_gate(subject: String) -> int:
	return maxi(0, missions_of(subject) - gate_consumed_of(subject))

func add_energy(amount: int) -> void:
	data["energy"] = int(data["energy"]) + amount

func add_fragments(amount: int) -> void:
	data["fragments"] = maxi(0, fragments() + amount)

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
# selezione per privilegiare gli argomenti più deboli e alla copertura del gate.
func topic_masteries(subject: String) -> Dictionary:
	var out: Dictionary = {}
	var prefix := "%s:" % subject
	for key in data.get("masteryByTopic", {}).keys():
		if str(key).begins_with(prefix):
			out[str(key).trim_prefix(prefix)] = float(data["masteryByTopic"][key])
	return out

# Numero di argomenti DISTINTI della materia già incontrati (copertura vissuta).
func topics_seen_count(subject: String) -> int:
	return topic_masteries(subject).size()

func add_mission(subject: String) -> void:
	data["missionsBySubject"][subject] = missions_of(subject) + 1

# Apre il gate: segna come "consumate" le missioni cumulative attuali della
# materia. Da chiamare quando l'apparato viene riparato (O-P0.3): non azzera il
# conteggio (il lavoro resta) ma sposta il punto di partenza del gate successivo.
func consume_gate(subject: String) -> void:
	if not data.has("gateConsumed"):
		data["gateConsumed"] = {}
	data["gateConsumed"][subject] = missions_of(subject)

# Azzeramento completo dell'evidenza missioni (setup di test / render probe).
# Non è usato dal loop di gioco: la progressione usa `consume_gate`.
func reset_missions() -> void:
	data["missionsBySubject"] = {}
	data["gateConsumed"] = {}

# --- Mondi sbloccati e mondo corrente (O-P1) ----------------------------------
func _worlds() -> Dictionary:
	if not data.has("worlds"):
		data["worlds"] = {"unlocked": [1], "current": 1}
	return data["worlds"]

func unlocked_worlds() -> Array:
	return Array(_worlds().get("unlocked", [1])).duplicate()

func is_world_unlocked(world_level: int) -> bool:
	return unlocked_worlds().has(world_level)

func unlock_world(world_level: int) -> void:
	var w := _worlds()
	var list: Array = w.get("unlocked", [1])
	if not list.has(world_level):
		list.append(world_level)
		list.sort()
		w["unlocked"] = list

func current_world() -> int:
	return int(_worlds().get("current", 1))

func set_current_world(world_level: int) -> void:
	_worlds()["current"] = world_level

# --- Stato persistente dei mondi (O-P0.4) -------------------------------------
# Ogni mondo (per livello) ricorda incontri completati, tesori raccolti e hazard
# neutralizzati, così rivisitarlo non ripropone ciò che è già stato risolto.
func _world_bucket(world_id: String) -> Dictionary:
	if not data.has("worldProgress"):
		data["worldProgress"] = {}
	if not data["worldProgress"].has(world_id):
		data["worldProgress"][world_id] = {
			"completedEncounterIds": [],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {},
		}
	var bucket: Dictionary = data["worldProgress"][world_id]
	if not bucket.has("resume"):
		bucket["resume"] = {}
	return bucket

func world_progress(world_id: String) -> Dictionary:
	return _world_bucket(world_id).duplicate(true)

func _mark_world_id(world_id: String, field: String, id: String) -> bool:
	if id == "":
		return false
	var bucket := _world_bucket(world_id)
	var list: Array = bucket[field]
	if list.has(id):
		return false
	list.append(id)
	bucket[field] = list
	return true

func mark_encounter_completed(world_id: String, encounter_id: String) -> bool:
	return _mark_world_id(world_id, "completedEncounterIds", encounter_id)

func is_encounter_completed(world_id: String, encounter_id: String) -> bool:
	return Array(_world_bucket(world_id)["completedEncounterIds"]).has(encounter_id)

func mark_treasure_collected(world_id: String, treasure_id: String) -> bool:
	return _mark_world_id(world_id, "collectedTreasureIds", treasure_id)

func mark_hazard_cleared(world_id: String, hazard_id: String) -> bool:
	return _mark_world_id(world_id, "clearedHazardIds", hazard_id)

func world_resume(world_id: String) -> Dictionary:
	return Dictionary(_world_bucket(world_id).get("resume", {})).duplicate(true)

func set_world_resume(world_id: String, position: Vector2, day_clock: float) -> void:
	_world_bucket(world_id)["resume"] = {
		"playerX": position.x,
		"playerY": position.y,
		"dayClock": day_clock,
	}

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
	## Migrazione idempotente: non scarta campi futuri sconosciuti e ricostruisce
	## i default mancanti (retro-compatibile con save v1).
	var migrated := source.duplicate(true)
	var defaults := _default_data()
	for key in defaults.keys():
		if not migrated.has(key):
			migrated[key] = defaults[key].duplicate(true) if typeof(defaults[key]) == TYPE_DICTIONARY else defaults[key]
	migrated = _migrate_spaced_repetition(migrated)
	migrated = _migrate_worlds(migrated)
	migrated["schemaVersion"] = SCHEMA_VERSION
	return migrated

# Mondi (O-P1): un save a livello N deve avere sbloccati i mondi 1..N (frontiera
# di progressione) senza perdere sblocchi extra (mondi rivisitabili). `current`
# resta se valido, altrimenti punta al livello corrente. Idempotente.
func _migrate_worlds(migrated: Dictionary) -> Dictionary:
	var w: Dictionary = migrated.get("worlds", {"unlocked": [1], "current": 1})
	var level_now := int(migrated.get("level", 1))
	var unlocked: Dictionary = {}   # set per dedup
	for v in w.get("unlocked", []):
		unlocked[int(v)] = true
	for lvl in range(1, mini(level_now, 24) + 1):
		unlocked[lvl] = true
	var list: Array = unlocked.keys()
	list.sort()
	w["unlocked"] = list
	if not list.has(int(w.get("current", 0))):
		w["current"] = clampi(level_now, 1, 24)
	migrated["worlds"] = w
	return migrated

# Ripasso spaziato v1 → v2: il vecchio {"due": {key: conteggio}} diventa uno
# schedule con topic subito dovuti (dueAt 0), così nessun ripasso pendente va
# perso. Un save già v2 (ha "schedule") viene lasciato invariato.
func _migrate_spaced_repetition(migrated: Dictionary) -> Dictionary:
	var sr: Dictionary = migrated.get("spacedRepetition", {})
	if sr.has("schedule"):
		if not sr.has("sessionClock"):
			sr["sessionClock"] = 0
		if not sr.has("history"):
			sr["history"] = []
		migrated["spacedRepetition"] = sr
		return migrated
	var schedule: Dictionary = {}
	for key in sr.get("due", {}).keys():
		var count := int(sr["due"][key])
		if count > 0:
			schedule[key] = {"dueAt": 0, "interval": 1, "lapses": count}
	migrated["spacedRepetition"] = {
		"sessionClock": 0,
		"schedule": schedule,
		"history": sr.get("history", []),
	}
	return migrated

func snapshot() -> Dictionary:
	return data.duplicate(true)
