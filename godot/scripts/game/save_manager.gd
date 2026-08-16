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

## Percorso storico, usato quando nessun profilo è stato ancora creato. Dal
## 6 agosto 2026 il file non è più uno solo: ogni profilo ha il suo (vedi
## `player_profiles.gd`). Questa costante resta il caso «un solo giocatore», che
## è anche quello di tutti gli audit.
const SAVE_PATH := "user://eli-quest-save.json"
const SCHEMA_VERSION := 3

var data: Dictionary = _default_data()

## Su quale file lavora QUESTA istanza. Deciso una volta alla costruzione e mai
## più: un manager che cambiasse file sotto i piedi scriverebbe metà partita in
## un profilo e metà in un altro.
var path: String = SAVE_PATH

## Senza argomenti segue il profilo attivo — e senza profili è il percorso
## storico, quindi il comportamento è identico a prima del multi-profilo.
## Il percorso esplicito serve a chi deve leggere un profilo che non è quello
## attivo, come l'elenco di avvio che mostra il livello di ciascun bambino.
func _init(save_path: String = "") -> void:
	path = save_path if not save_path.is_empty() else PlayerProfiles.active_save_path()

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
		# Argomenti PRATICATI in questo livello, materia per materia. Si azzera
		# salendo di livello.
		#
		# Non conta gli argomenti «nuovi»: quelli finiscono — una materia ne ha
		# otto o venti — e un gate che ne chiede sempre di inediti diventa
		# impossibile al terzo giro. Conta quelli **toccati adesso**, anche se
		# già noti. È la differenza fra chiedere di imparare altro e chiedere di
		# tenere allenato ciò che si sa: la seconda si può fare a ogni livello.
		"coverageThisLevel": {},    # subject -> [argomenti toccati in questo livello]
		# **Le materie portate in linea, e a quale grado.** (16 agosto 2026)
		#
		# Una materia che ha soddisfatto tutte e tre le condizioni del gate a
		# questo livello resta soddisfatta fino al livello successivo. Senza questo
		# la ritenzione la faceva ricadere fra quelle da fare per il solo fatto che
		# lo studente stava giocando **un'altra** materia: l'orologio del ripasso
		# spaziato e' unico e avanza a ogni sessione. Vedi
		# `GateReadiness.in_linea_a_questo_livello`.
		#
		# Si conserva il LIVELLO, non un booleano: al passaggio successivo della
		# materia il grado e' un altro e il traguardo va riconquistato, esattamente
		# come per `apparatus.repairedLevel`.
		"gateClearedLevel": {},     # subject -> livello a cui e' andata in linea
		# Impronte dei quesiti di PRATICA già visti di recente, materia per
		# materia. Nasce da una segnalazione di gioco del 6 agosto 2026: lo
		# studente rifaceva la stessa location e ritrovava gli stessi quesiti
		# identici, guadagnando padronanza senza imparare niente.
		#
		# Sono numeri, non testi: l'impronta del testo della domanda. Serve solo a
		# rispondere «questo l'ha già visto?», e conservare le domande per esteso
		# gonfierebbe ogni salvataggio e ogni copia in cloud.
		"recentPractice": {},       # subject -> [impronte, dalla più vecchia]
		# Le prove SUPERATE: le impronte degli esercizi chiusi correttamente e senza
		# sbagliare, materia per materia. A differenza di `recentPractice` — una
		# finestra corta, e solo per la palestra — questa memoria vale per OGNI tipo
		# di prova e non è un «di recente»: una prova risolta non torna a chiedere la
		# stessa cosa. Vedi la sezione «Prove superate» in fondo.
		"solvedExercises": {},      # subject -> [impronte, dalla più vecchia]
		# Quando ogni materia è stata praticata l'ultima volta, in SESSIONI
		# giocate (non in giorni reali). Serve al decadimento della padronanza:
		# vedi `ProgressionManager.applica_decadimento`.
		"masteryTouchedAt": {},     # subject -> orologio di sessione
		# Il massimo storico di padronanza per materia: è il riferimento del
		# pavimento sotto cui il decadimento non scende.
		"masteryPeak": {},          # subject -> float 0..1
		# Mondi di cui è già stata letta la schermata di benvenuto. Si mostra una
		# volta sola: riproporla a ogni rientro la trasformerebbe in una porta da
		# chiudere, e una cosa che si impara a chiudere non si legge più.
		"worldIntroSeen": [],       # [livelli]
		# Le pergamene dei Dodici gia' trovate. Sono l'altro lato della storia —
		# quello di chi c'era — e nessuna e' obbligatoria: chi non esplora
		# finisce il gioco lo stesso, gli manca il perche' e non il cosa.
		"parchments": [],           # [livelli]
		# Le riparazioni dei Dodici portate a termine: una per mondo. A differenza
		# delle pergamene queste NON sono facoltative — prendono il posto di un
		# evento-gate, quindi contano per aprire l'apparato — ma restano segnate a
		# parte perche' il Lascito le pesa piu' di un incontro qualsiasi: sono i
		# posti che il giocatore ha davvero cambiato.
		"minimissions": [],         # [livelli]
		# La luce riconquistata in ogni mondo e la potenza cumulativa di Eli.
		# Nascono dal collaudo del 7 agosto 2026: il ciclo di ricompensa durava
		# mezz'ora, e queste due misure lo riportano a una prova. Vedi
		# `world_light.gd`.
		"worldLight": {},           # "livello" -> prove superate li'
		"powerRuns": 0,             # prove superate in tutta la partita
		# Le cariche dell'impulso stabilizzante: si guadagnano superando prove e
		# si spendono contro le sacche. Vedi `pulse_charge.gd` — prima di questa
		# chiave l'impulso era gratuito e il morso non lo pagava nessuno.
		"pulse": {"charges": 0, "progress": 0},
		"apparatus": {},            # id -> {repairedLevel:int}
		# Mondi (O-P1): livelli sbloccati (destinazioni di viaggio dalla nave) e
		# mondo attualmente giocato. Il rango `level` è la frontiera di
		# progressione; `worlds.current` può puntare a un mondo già scoperto quando
		# si rivisita. Lo stato persistente per mondo vive in `worldProgress`.
		"worlds": {"unlocked": [1], "current": 1},
		"worldProgress": {},        # "level" -> {completedEncounterIds, collectedTreasureIds, clearedHazardIds, enigmaCooldowns}
		"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []},
		"narrative": {"seen": [], "beats": {}},
		"progressReport": {"events": []},
		"daily": {"date": "", "missions": 0, "streak": 0},
		# Ripasso spaziato con PIANIFICAZIONE TEMPORALE reale (O-P0.7): un orologio
		# di sessioni monotòno e, per ogni "subject:topic", quando ripresentarlo.
		"spacedRepetition": {"sessionClock": 0, "schedule": {}, "history": []},
		# Manuale NORA (O-P4): stato di conoscenza per argomento ("subject:topic" ->
		# unknown/encountered/consulted/applied/consolidated).
		"codex": {},
		# Evidenza di ritenzione per argomento (decisione 29 luglio 2026): sessioni
		# distinte risolte bene e distanza in tempo REALE tra la prima e l'ultima.
		# Alimenta lo stato "consolidato"; vedi topic_evidence.gd.
		"topicEvidence": {},
		# Stato relazionale di NORA (O-P4): integrità nave, ricordi, fiducia.
		"nora": {"integrity": 0.0, "memory": 0, "trust": 0.5},
		# Configurazione dell'esperienza (O-P6): fascia scolastica, curriculum e
		# materie attive. Fascia di lancio decisa il 29 luglio 2026: 10-13 anni
		# (fine primaria + medie). Le 12 materie sono tutte obbligatorie.
		"config": {
			"schoolBand": LearningConfig.BAND_LAUNCH,
			"curriculum": "base",
			"activeSubjects": [],
			"touchControls": {"side": "right", "size": "large", "opacity": 1.0},
		},
		"accessibility": {
			"highContrast": false,
			"reducedMotion": false,
		},
	}

func load_save() -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		data = migrate_legacy_save(parsed)
		# `data` è un altro dizionario: l'indice delle prove superate va rifatto,
		# o resterebbe quello del profilo precedente.
		if _solved_index_built:
			_rebuild_solved_index()

func save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
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

## Vero se questa materia non è mai stata giocata. Serve a distinguere «zero
## perché non l'hai mai vista» da «zero perché sbagli tutto»: sono due stati
## molto diversi e la media mobile non li distingueva.
func mastery_never_set(subject: String) -> bool:
	return not Dictionary(data.get("mastery", {})).has(subject)

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
	# Aver aggiornato la padronanza di un argomento SIGNIFICA averlo toccato in
	# questo livello: la copertura si registra qui, nell'unico punto che ogni
	# percorso attraversa. Tenerla solo in `record_topic_stats` la faceva
	# mancare a chiunque costruisse uno stato per altra via.
	mark_topic_this_level(subject, topic)

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

## Segna che in questo livello si è lavorato su questo argomento.
func mark_topic_this_level(subject: String, topic: String) -> void:
	if not data.has("coverageThisLevel"):
		data["coverageThisLevel"] = {}
	var per_materia: Dictionary = data["coverageThisLevel"]
	var elenco: Array = Array(per_materia.get(subject, []))
	if not elenco.has(topic):
		elenco.append(topic)
	per_materia[subject] = elenco

## Quanti argomenti distinti sono stati toccati in questa materia DA QUANDO è
## cominciato il livello. È questa la copertura che il gate misura.
func topics_seen_this_level(subject: String) -> int:
	return Array(data.get("coverageThisLevel", {}).get(subject, [])).size()

## Azzera il conteggio del livello. Si chiama salendo: il livello nuovo
## ricomincia a contare, mentre padronanza e argomenti conosciuti restano.
func reset_coverage_this_level() -> void:
	data["coverageThisLevel"] = {}

## Registra che questa materia ha raggiunto tutte e tre le condizioni del gate al
## livello indicato. Monotono: un traguardo non si toglie, e al livello dopo
## smette di valere da solo perche' quello che si conserva e' il grado.
func set_subject_cleared(subject: String, cleared_level: int) -> void:
	if not data.has("gateClearedLevel"):
		data["gateClearedLevel"] = {}
	var precedente := int(Dictionary(data["gateClearedLevel"]).get(subject, 0))
	data["gateClearedLevel"][subject] = maxi(precedente, cleared_level)

## A quale grado questa materia e' andata in linea. 0 = mai.
func subject_cleared_level(subject: String) -> int:
	return int(Dictionary(data.get("gateClearedLevel", {})).get(subject, 0))

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
			"enigmaCooldowns": {},
			"resume": {},
		}
	var bucket: Dictionary = data["worldProgress"][world_id]
	if not bucket.has("resume"):
		bucket["resume"] = {}
	if not bucket.has("enigmaCooldowns"):
		bucket["enigmaCooldowns"] = {}
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

func mark_treasure_collected(world_id: String, treasure_id: String) -> bool:
	return _mark_world_id(world_id, "collectedTreasureIds", treasure_id)

func set_enigma_cooldown(
	world_id: String,
	encounter_id: String,
	duration_seconds: int,
	now_unix: int = -1
) -> void:
	if encounter_id == "":
		return
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	var cooldowns: Dictionary = _world_bucket(world_id)["enigmaCooldowns"]
	cooldowns[encounter_id] = now + maxi(0, duration_seconds)

func enigma_cooldown_remaining(
	world_id: String,
	encounter_id: String,
	now_unix: int = -1
) -> int:
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	var cooldowns: Dictionary = _world_bucket(world_id)["enigmaCooldowns"]
	return maxi(0, int(cooldowns.get(encounter_id, 0)) - now)

func clear_enigma_cooldown(world_id: String, encounter_id: String) -> void:
	var cooldowns: Dictionary = _world_bucket(world_id)["enigmaCooldowns"]
	cooldowns.erase(encounter_id)

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

## A quale livello è stata accesa la stanza di questo apparato. 0 = mai accesa.
##
## Il numero non è decorativo: distingue «questa materia l'ha già superata **a
## questo grado**» da «l'aveva superata dodici mondi fa». Sulla prima il gioco non
## deve tornare a chiedere niente; sulla seconda sì, perché il secondo passaggio
## della materia è un grado di difficoltà nuovo. Prima esisteva solo il setter e
## ogni lettore si frugava dentro `data` da sé — tre punti diversi con la stessa
## catena di `get`, che è il modo in cui due di loro finiscono per dissentire.
func apparatus_repaired_level(id: String) -> int:
	return int(Dictionary(data.get("apparatus", {})).get(id, {}).get("repairedLevel", 0))

func set_level(value: int) -> void:
	data["level"] = value

func spend_energy(amount: int) -> bool:
	var cost := maxi(0, amount)
	if int(data["energy"]) < cost:
		return false
	data["energy"] = int(data["energy"]) - cost
	return true

## Lo scarico dei frammenti, che fino al 14 agosto 2026 non esisteva: la valuta
## aveva `add_fragments` e nient'altro, e la bottega si pagava in energia. Vedi
## [[FragmentEconomy]] per il perché della separazione.
func spend_fragments(amount: int) -> bool:
	var cost := maxi(0, amount)
	if fragments() < cost:
		return false
	data["fragments"] = fragments() - cost
	return true

## Applica uno stato iniziale esplicito per audit/import controllati. Il normale
## boot nativo non ne fornisce uno e mantiene il save locale autoritativo.
func apply_launch_state(request: Dictionary) -> void:
	var canonical = request.get("initialSave", null)
	if typeof(canonical) == TYPE_DICTIONARY:
		var candidate := migrate_legacy_save(canonical)
		if int(candidate.get("level", 0)) >= level():
			data = candidate
			if _solved_index_built:
				_rebuild_solved_index()
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
	migrated = _migrate_renamed_subjects(migrated)
	migrated = _migrate_history_apparatus(migrated)
	migrated["schemaVersion"] = SCHEMA_VERSION
	return migrated

# Rinomina materia (cittadinanza → storia): i vecchi salvataggi conservano la
# competenza sotto la vecchia chiave; la rimappiamo così la progressione non va
# persa. Idempotente: se la vecchia chiave non c'è, non fa nulla.
const RENAMED_SUBJECTS := {"cittadinanza": "storia"}

func _migrate_renamed_subjects(migrated: Dictionary) -> Dictionary:
	for old_key in RENAMED_SUBJECTS:
		var new_key: String = RENAMED_SUBJECTS[old_key]
		var mastery: Dictionary = migrated.get("mastery", {})
		if mastery.has(old_key):
			if not mastery.has(new_key):
				mastery[new_key] = mastery[old_key]
			mastery.erase(old_key)
		_rename_prefixed_keys(migrated.get("masteryByTopic", {}), old_key + ":", new_key + ":")
		var sr: Dictionary = migrated.get("spacedRepetition", {})
		if typeof(sr) == TYPE_DICTIONARY:
			_rename_prefixed_keys(sr.get("schedule", {}), old_key + ":", new_key + ":")
	return migrated

# Storia non condivide più la serra con Scienze: i save che avevano già
# superato il primo o il secondo gate storico conservano la riparazione nel
# nuovo Archivio temporale. La serra resta intatta per i livelli scientifici.
func _migrate_history_apparatus(migrated: Dictionary) -> Dictionary:
	var apparatus: Dictionary = migrated.get("apparatus", {})
	if apparatus.has("archivio-temporale"):
		return migrated
	var old_level := int(Dictionary(apparatus.get("serra-bio", {})).get("repairedLevel", 0))
	if old_level >= 11:
		apparatus["archivio-temporale"] = {"repairedLevel": old_level}
	return migrated

func _rename_prefixed_keys(d: Dictionary, old_prefix: String, new_prefix: String) -> void:
	for key in d.keys():   # keys() è una copia: erase durante l'iterazione è sicuro
		var ks := str(key)
		if ks.begins_with(old_prefix):
			var nk := new_prefix + ks.substr(old_prefix.length())
			if not d.has(nk):
				d[nk] = d[key]
			d.erase(key)

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

# --- Pratica già vista (6 agosto 2026) ----------------------------------------

## Quante impronte si conservano per materia.
##
## Una sessione di pratica ne consuma quattro o cinque, e il repertorio più
## sottile misurato ne contiene cinque in tutto: ricordarne troppe lascerebbe la
## materia senza NIENTE di ammissibile e il filtro dovrebbe arrendersi sempre.
## Ventiquattro coprono circa cinque sessioni, che è la distanza oltre la quale
## rivedere un esercizio è ripasso e non ripetizione.
const RECENT_PRACTICE_MAX := 24

## L'impronta di un quesito è il suo CONTENUTO, non il suo identificativo.
##
## Prima versione (6 agosto 2026, mattina): era il solo `prompt`. Sbagliata, e in
## un modo che si vedeva solo leggendo i costruttori — nei formati interattivi il
## prompt è una **costante**: ogni abbinamento del gioco dice «Abbina ogni
## elemento alla sua coppia», qualunque siano le coppie. Con quell'impronta due
## abbinamenti completamente diversi risultavano lo stesso esercizio, e la
## memoria del già visto, dopo UN abbinamento, scartava tutti gli abbinamenti
## successivi. La pratica finiva spinta verso i banchi non perché il catalogo
## fosse esaurito, ma perché il filtro non sapeva distinguerlo.
##
## Ora si guarda quello che il bambino vede davvero: il testo E il contenuto —
## le coppie, le tessere, le opzioni. Fuori restano `id` (cambia a ogni
## estrazione senza che cambi niente) e `difficulty` (è una proprietà della
## sessione, non del quesito).
const IMPRONTA_IGNORA := ["id", "difficulty"]

static func practice_fingerprint(prompt: String) -> int:
	return hash(prompt.strip_edges().to_lower())

static func practice_node_fingerprint(node: Dictionary) -> int:
	var pulito: Dictionary = {}
	for chiave in node.keys():
		if IMPRONTA_IGNORA.has(str(chiave)):
			continue
		pulito[str(chiave)] = node[chiave]
	return hash(JSON.stringify(pulito))

func remember_practice(subject: String, prompts: Array) -> void:
	var impronte: Array = []
	for p in prompts:
		impronte.append(practice_fingerprint(str(p)))
	remember_practice_prints(subject, impronte)

## Come sopra, ma con le impronte già calcolate: è la via che usa il gioco, dove
## i nodi ci sono per intero e non serve ridurli al solo testo.
func remember_practice_prints(subject: String, impronte: Array) -> void:
	var tutte: Dictionary = data.get("recentPractice", {})
	var coda: Array = Array(tutte.get(subject, []))
	for grezza in impronte:
		var impronta := int(grezza)
		# Riportare in fondo un'impronta già presente, invece di duplicarla:
		# un esercizio rivisto ora è «visto ora», non «visto tre sessioni fa».
		coda.erase(impronta)
		coda.append(impronta)
	while coda.size() > RECENT_PRACTICE_MAX:
		coda.remove_at(0)
	tutte[subject] = coda
	data["recentPractice"] = tutte

## Le impronte da evitare, come insieme per la ricerca rapida.
func recent_practice(subject: String) -> Dictionary:
	var out: Dictionary = {}
	for impronta in Array(Dictionary(data.get("recentPractice", {})).get(subject, [])):
		out[int(impronta)] = true
	return out

# --- Prove superate (15 agosto 2026) ------------------------------------------

## **Una prova superata non si richiede più.**
##
## Fino a oggi il gioco aveva una sola memoria di ciò che lo studente aveva già
## visto — `recentPractice` — e serviva a un caso solo: la palestra, dove il
## difetto era stato segnalato. Missioni, enigmi, riparazioni ed esami pescavano
## dallo stesso banco senza guardare niente: bastava rifare la stessa location, o
## anche solo tornare nel mondo, per ritrovare parola per parola l'esercizio a cui
## si era già risposto bene. Ed è il modo peggiore in cui una domanda può tornare:
## chi l'ha risolta ricorda la RISPOSTA, non il ragionamento, e la rifà giusta
## senza imparare niente — la padronanza sale e la competenza no.
##
## Due scelte dentro questa memoria, e nessuna delle due è ovvia:
##
## **Superata vuol dire risolta pulita.** Un esercizio chiuso correttamente ma
## dopo un errore NON è superato e resta disponibile: è esattamente quello che
## conviene rivedere. Il giudizio lo dà l'ExercisePlayer, che è l'unico posto a
## sapere quanti tentativi sono serviti.
##
## **Il ripasso spaziato passa sopra.** Quando un argomento è dovuto, la selezione
## preferisce comunque una prova mai risolta su quell'argomento; se non ne restano,
## ripropone una superata invece di saltare il ripasso. Un ripasso mancato è un
## danno più grande di una domanda già vista.
##
## **Il tetto, e perché è questo.** Duecentocinquantasei impronte per materia sono
## circa ottanta missioni della stessa materia: molto oltre un ciclo di visite al
## suo mondo, e chi le supera ha comunque svuotato il banco a quella difficoltà —
## lì la prova più anziana che rientra è ripasso, non ripetizione. Il tetto serve
## perché questa memoria è l'unica del salvataggio che cresce con le ore giocate:
## dodici materie al massimo pesano una trentina di KB, e la copia in cloud
## (`cloud/index.ts`) si ferma a 256 KB. Un salvataggio che non entra più nel
## cloud sarebbe un danno molto peggiore di una domanda ripetuta.
const SOLVED_MAX := 256

## L'impronta di una prova superata è la sua IDENTITÀ DI CONTENUTO
## (`ExerciseSignature`), non il testo grezzo né l'id: due estrazioni della stessa
## prova con gli elementi mescolati sono la stessa prova per chi la gioca, e l'id
## cambia a ogni estrazione senza che cambi niente. Si conserva l'hash e non la
## firma per esteso: serve solo a rispondere «questa l'ha già risolta?», e i testi
## gonfierebbero ogni salvataggio e ogni copia in cloud.
static func solved_fingerprint(node: Dictionary) -> int:
	return ExerciseSignature.fingerprint(node)

## Indice vivo delle prove superate: {materia: {impronta: true}}.
##
## Esiste come OGGETTO STABILE apposta. `ContentManager` se lo tiene per
## riferimento una volta sola (vedi `solved_by_subject`) e lo consulta a ogni
## costruzione: se ogni scrittura lo sostituisse, il selettore continuerebbe a
## leggere una fotografia vecchia e le prove appena risolte tornerebbero subito.
## Perciò qui si svuota e si riempie, mai si riassegna.
var _solved_index: Dictionary = {}
var _solved_index_built := false

func solved_index() -> Dictionary:
	if not _solved_index_built:
		_rebuild_solved_index()
	return _solved_index

func _rebuild_solved_index() -> void:
	_solved_index.clear()
	var tutte: Dictionary = data.get("solvedExercises", {})
	for subject in tutte.keys():
		_solved_index[str(subject)] = _solved_set(Array(tutte[subject]))
	_solved_index_built = true

func _solved_set(coda: Array) -> Dictionary:
	var out: Dictionary = {}
	for impronta in coda:
		out[int(impronta)] = true
	return out

## Le impronte già superate in una materia, come insieme per la ricerca rapida.
func solved_exercises(subject: String) -> Dictionary:
	return Dictionary(solved_index().get(subject, {}))

func has_solved(subject: String, node: Dictionary) -> bool:
	return solved_exercises(subject).has(solved_fingerprint(node))

## Segna come superate le impronte passate. Idempotente: una prova già in elenco
## resta dov'è invece di essere riportata in fondo — al contrario di
## `remember_practice_prints`, dove l'ordine è la finestra e conta il «visto ora».
## Qui l'ordine serve solo a decidere che cosa cede per primo quando si arriva al
## tetto, e la più anziana è la scelta giusta.
func remember_solved(subject: String, impronte: Array) -> void:
	if subject == "" or impronte.is_empty():
		return
	var tutte: Dictionary = data.get("solvedExercises", {})
	var coda: Array = Array(tutte.get(subject, []))
	for grezza in impronte:
		var impronta := int(grezza)
		if not coda.has(impronta):
			coda.append(impronta)
	while coda.size() > SOLVED_MAX:
		coda.remove_at(0)
	tutte[subject] = coda
	data["solvedExercises"] = tutte
	if _solved_index_built:
		_solved_index[subject] = _solved_set(coda)

## Come sopra ma per l'esito di una sessione intera, dove i nodi possono venire da
## materie diverse: l'esame di mondo aggiunge due prove di nucleo e il finale del
## Cuore ne attraversa dodici. La materia la porta scritta il nodo.
func remember_solved_map(per_materia: Dictionary) -> void:
	for subject in per_materia.keys():
		remember_solved(str(subject), Array(per_materia[subject]))

# --- Trascuratezza (6 agosto 2026, svolta severa) -----------------------------

## Segna che una materia è stata praticata adesso.
func touch_subject(subject: String, orologio: int) -> void:
	var tutte: Dictionary = data.get("masteryTouchedAt", {})
	tutte[subject] = orologio
	data["masteryTouchedAt"] = tutte

## Da quante sessioni una materia non viene praticata. Una materia mai toccata
## non è «trascurata»: non è ancora cominciata, e va trattata come tale — punire
## chi non ha ancora incontrato una materia sarebbe punirlo per l'ordine dei
## mondi, che non decide lui.
func sessions_since(subject: String, orologio: int) -> int:
	var tutte: Dictionary = data.get("masteryTouchedAt", {})
	if not tutte.has(subject):
		return -1
	return maxi(0, orologio - int(tutte[subject]))

## Vero se questo mondo non ha ancora mostrato la sua soglia. Segna e risponde
## in un colpo solo: due chiamanti che chiedessero prima e segnassero poi
## potrebbero mostrarla due volte in un rientro rapido.
func claim_world_intro(level: int) -> bool:
	var visti: Array = Array(data.get("worldIntroSeen", []))
	if visti.has(level):
		return false
	visti.append(level)
	data["worldIntroSeen"] = visti
	return true

func world_intro_seen(level: int) -> bool:
	return Array(data.get("worldIntroSeen", [])).has(level)

## Un hazard sgombrato resta sgombrato: il pedaggio si paga una volta sola.
func mark_hazard_cleared(world_id: String, hazard_id: String) -> bool:
	var progresso := world_progress(world_id)
	var puliti: Array = Array(progresso.get("clearedHazardIds", []))
	if puliti.has(hazard_id):
		return false
	puliti.append(hazard_id)
	progresso["clearedHazardIds"] = puliti
	var tutti: Dictionary = data.get("worldProgress", {})
	tutti[world_id] = progresso
	data["worldProgress"] = tutti
	return true

## Una sacca sciolta nel varco resta sciolta: chi ha vinto il duello non deve
## rigiocarlo per lo stesso forziere. Vive nel progresso del mondo insieme agli
## hazard sgombrati, che e' la stessa specie di fatto: una cosa che era li' e non
## c'e' piu'.
func mark_enemy_defeated(world_id: String, enemy_id: String) -> bool:
	var progresso := world_progress(world_id)
	var sciolte: Array = Array(progresso.get("defeatedEnemyIds", []))
	if sciolte.has(enemy_id):
		return false
	sciolte.append(enemy_id)
	progresso["defeatedEnemyIds"] = sciolte
	var tutti: Dictionary = data.get("worldProgress", {})
	tutti[world_id] = progresso
	data["worldProgress"] = tutti
	return true

func enemy_defeated(world_id: String, enemy_id: String) -> bool:
	return Array(world_progress(world_id).get("defeatedEnemyIds", [])).has(enemy_id)

## Segna una pergamena come trovata. Ritorna falso se c'era gia': la camera si
## apre una volta sola, e il tesoro dentro non si raccoglie due volte.
func claim_parchment(level: int) -> bool:
	var trovate: Array = Array(data.get("parchments", []))
	if trovate.has(level):
		return false
	trovate.append(level)
	data["parchments"] = trovate
	return true

func has_parchment(level: int) -> bool:
	return Array(data.get("parchments", [])).has(level)

func parchment_count() -> int:
	return Array(data.get("parchments", [])).size()

## Segna come chiusa la riparazione di un mondo. Ritorna falso se c'era gia': il
## mondo si cambia una volta sola, e ripagarla al rientro sarebbe la stessa
## scorciatoia della palestra ripetuta.
func claim_minimission(level: int) -> bool:
	var fatte: Array = Array(data.get("minimissions", []))
	if fatte.has(level):
		return false
	fatte.append(level)
	data["minimissions"] = fatte
	return true

func has_minimission(level: int) -> bool:
	return Array(data.get("minimissions", [])).has(level)

func minimission_count() -> int:
	return Array(data.get("minimissions", [])).size()

func mastery_peak(subject: String) -> float:
	return float(Dictionary(data.get("masteryPeak", {})).get(subject, 0.0))

func set_mastery_peak(subject: String, value: float) -> void:
	var tutti: Dictionary = data.get("masteryPeak", {})
	# Solo verso l'alto: è un massimo storico, e un massimo che scende non è un
	# massimo — sarebbe un pavimento che insegue la caduta.
	tutti[subject] = maxf(float(tutti.get(subject, 0.0)), clampf(value, 0.0, 1.0))
	data["masteryPeak"] = tutti

func snapshot() -> Dictionary:
	return data.duplicate(true)
