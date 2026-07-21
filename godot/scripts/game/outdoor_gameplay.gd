class_name OutdoorGameplay
extends Node

## Logica gameplay del mondo esterno, estratta da outdoor_world.gd (C-02):
## possiede save/contenuti/progressione, il ciclo delle sessioni (missione,
## enigma ambientale ed esame finale) e l'economia; espone lo stato leggibile
## `OutdoorRuntimeState`.
##
## SEPARAZIONE: qui vive solo la SEMANTICA (ricompense, gate, save). La scena e
## l'HUD leggono lo stato via `runtime_state()` / segnale `runtime_state_changed`
## e non devono ricalcolare né concedere nulla. Vedi `insieme.md` (contratto
## runtime) e docs/DESIGN_COMPLETO.md.
##
## OutdoorRuntimeState:
## { level, focusSubject, apparatus, missionsDone, missionsRequired, mastery,
##   masteryThreshold, ready, energy, fragments, phase, sessionActive }

const EXERCISE_ENERGY_COST := 3

const BIOME_ENCOUNTER_SUBJECTS := {
	"academy:times": "matematica",
	"academy:mental": "italiano",
	"wild:times": "inglese",
	"wild:physicalGeo": "fisica",
	"logic:times": "coding",
	"logic:mental": "elettronica",
	"crystal:mental": "musica",
	"crystal:guardian": "musica",
	"geo:capital": "inglese",
	"geo:physicalGeo": "fisica",
	"ruins:mental": "latino",
	"ruins:capital": "italiano",
	"ruins:guardian": "elettronica",
}

const ENCOUNTER_SUBJECT_FALLBACK := {
	"times": "matematica", "mental": "italiano", "capital": "inglese",
	"physicalGeo": "fisica", "guardian": "coding",
}

signal runtime_state_changed(state: Dictionary)  # stato aggiornato (evento-driven)
signal session_requested(session: Dictionary)    # la scena mostra l'ExercisePlayer
signal feedback(message: String)                 # messaggio testuale per l'HUD
## Progresso dell'enigma ambientale per la resa (Codex): `built` campate costruite
## su `total`, con `theme` (ponte/porta/…) ed `encounter_id` per instradare
## l'aggiornamento al POI giusto quando più enigmi coesistono nel mondo (con un
## solo enigma non serviva, con più POI dello stesso gruppo sì: senza id la
## scena aggiornerebbe la visuale di TUTTI gli enigmi, non solo quello attivo).
## La scena inoltra qui il segnale `progress_changed` dell'ExercisePlayer via
## `notify_progress`; la grafica si abbona SOLO a questo (gate I-01).
signal enigma_progress(built: int, total: int, theme: String, encounter_id: String)

var game_save: GameSaveManager
var content_manager: ContentManager
var progression_manager: ProgressionManager
var reward_manager: RewardManager
var nora_voice := NoraVoice.new()
var result: Dictionary                           # risultato bridge (handshake d'uscita)
var active_session_context: Dictionary = {}
var base_fragments := 0
var current_phase := "giorno"

func setup(request: Dictionary, bridge_result: Dictionary, load_local_save: bool = true) -> void:
	result = bridge_result
	base_fragments = int(request.get("outdoorState", {}).get("fragments", 0))
	game_save = GameSaveManager.new()
	if load_local_save:
		game_save.load_save()
	game_save.import_bridge_request(request)
	content_manager = ContentManager.new()
	progression_manager = ProgressionManager.new(game_save)
	reward_manager = RewardManager.new(game_save)
	_emit_state()

# ---------------------------------------------------------------------------
# Stato leggibile (contratto runtime)
# ---------------------------------------------------------------------------

func session_active() -> bool:
	return not active_session_context.is_empty()

func runtime_state() -> Dictionary:
	var progress := progression_manager.repair_progress()
	var missions_done := int(progress.get("missionsDone", 0))
	var missions_required := int(progress.get("missionsRequired", 0))
	var mastery := float(progress.get("mastery", 0.0))
	var mastery_threshold := float(progress.get("masteryThreshold", 0.0))
	return {
		"level": game_save.level(),
		"focusSubject": str(progress.get("subject", "matematica")),
		"apparatus": str(progress.get("apparatus", "nucleo")),
		"missionsDone": missions_done,
		"missionsRequired": missions_required,
		# Campi convenienza per HUD/marker (Codex): non ricalcolare lato UI.
		"missionsRemaining": maxi(0, missions_required - missions_done),
		"missionProgress": clampf(float(missions_done) / float(maxi(1, missions_required)), 0.0, 1.0),
		"mastery": mastery,
		"masteryThreshold": mastery_threshold,
		"masteryProgress": clampf(mastery / maxf(0.001, mastery_threshold), 0.0, 1.0),
		"ready": bool(progress.get("ready", false)),
		"energy": game_save.energy(),
		"fragments": base_fragments + int(result.get("fragmentsEarned", 0)),
		"phase": current_phase,
		"sessionActive": session_active(),
		# Bottega (C-14): catalogo statico in RewardCatalog.CATALOG, qui solo lo
		# stato del giocatore. Codex non ricalcola owned/equipped lato UI.
		"cosmeticsUnlocked": Array(game_save.data.get("cosmetics", {}).get("unlocked", [])).duplicate(),
		"cosmeticsInventory": Array(game_save.data.get("cosmetics", {}).get("inventory", [])).duplicate(),
		"cosmeticsEquipped": Dictionary(game_save.data.get("cosmetics", {}).get("equipped", {})).duplicate(),
	}

func update_phase(phase: String) -> void:
	if phase != current_phase:
		current_phase = phase
		_emit_state()

func apparatus_prompt() -> String:
	var progress := progression_manager.repair_progress()
	if bool(progress.get("ready", false)):
		return "Premi E per affrontare l'esame finale del Nucleo"
	return "Nucleo: %d/%d missioni · padronanza %.0f%%/%.0f%%" % [
		int(progress.get("missionsDone", 0)), int(progress.get("missionsRequired", 0)),
		float(progress.get("mastery", 0.0)) * 100.0, float(progress.get("masteryThreshold", 0.0)) * 100.0]

# ---------------------------------------------------------------------------
# Ciclo delle sessioni
# ---------------------------------------------------------------------------

func try_start_mission(payload: Dictionary, encounter_id: String) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		feedback.emit("Incontro già completato.")
		return false
	var subject := _subject_for_payload(payload)
	var session := content_manager.build_mission(subject, game_save.level(), 3, _due())
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Banco esercizi non disponibile per %s." % subject)
		return false
	if not game_save.spend_energy(EXERCISE_ENERGY_COST):
		feedback.emit("Energia insufficiente: servono %d energia." % EXERCISE_ENERGY_COST)
		return false
	result["energySpent"] = int(result.get("energySpent", 0)) + EXERCISE_ENERGY_COST
	active_session_context = {"kind": "mission", "encounterId": encounter_id, "subject": subject}
	feedback.emit(NoraContextEngine.open_line(subject, _has_review_node(session)))
	session_requested.emit(session)
	_emit_state()
	return true

# Enigma ambientale: come una missione, ma la sessione costruisce un elemento del
# mondo (ponte/porta…) mentre si risponde. Conta a tutti gli effetti come missione
# per il gate dell'apparato; il tema per la resa viaggia nel contesto e nel segnale.
func try_start_enigma(payload: Dictionary, encounter_id: String) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		feedback.emit("Enigma già risolto.")
		return false
	var subject := _subject_for_payload(payload)
	var session := content_manager.build_enigma(subject, game_save.level(), 4, _due())
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Banco esercizi non disponibile per %s." % subject)
		return false
	if not game_save.spend_energy(EXERCISE_ENERGY_COST):
		feedback.emit("Energia insufficiente: servono %d energia." % EXERCISE_ENERGY_COST)
		return false
	result["energySpent"] = int(result.get("energySpent", 0)) + EXERCISE_ENERGY_COST
	var theme := str(session.get("theme", "ponte"))
	active_session_context = {"kind": "enigma", "encounterId": encounter_id, "subject": subject, "theme": theme}
	feedback.emit(NoraContextEngine.open_line(subject, _has_review_node(session)))
	session_requested.emit(session)
	# Stato iniziale della costruzione (0 campate) così la resa parte da "rotto".
	enigma_progress.emit(0, int(session.get("stages", session.get("nodes", []).size())), theme, encounter_id)
	_emit_state()
	return true

# Inoltro del progresso dall'ExercisePlayer (la scena connette qui
# `progress_changed`): rilancia `enigma_progress` con tema ed encounter_id solo
# durante un enigma, ignorando le sessioni normali.
func notify_progress(built: int, total: int) -> void:
	if str(active_session_context.get("kind", "")) != "enigma":
		return
	enigma_progress.emit(built, total, str(active_session_context.get("theme", "ponte")), str(active_session_context.get("encounterId", "")))

func try_start_final_exam() -> bool:
	if session_active():
		return false
	if not progression_manager.can_repair():
		_emit_state()
		return false
	var gate := progression_manager.current_gate()
	var subject := str(gate.get("subject", "matematica"))
	var session := content_manager.build_final_exam(subject, game_save.level(), 3)
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Esame non disponibile.")
		return false
	if not game_save.spend_energy(EXERCISE_ENERGY_COST):
		feedback.emit("Energia insufficiente: servono %d energia per l'esame." % EXERCISE_ENERGY_COST)
		return false
	result["energySpent"] = int(result.get("energySpent", 0)) + EXERCISE_ENERGY_COST
	active_session_context = {"kind": "final_exam", "subject": subject, "apparatus": str(gate.get("apparatus", "nucleo"))}
	session_requested.emit(session)
	_emit_state()
	return true

# Risolve la sessione conclusa dall'ExercisePlayer: aggiorna save, progressione,
# ricompense e (per l'esame) ripara l'apparato salendo di livello.
func resolve_session(exercise_result: Dictionary) -> void:
	var context := active_session_context.duplicate(true)
	active_session_context = {}
	var subject := str(context.get("subject", exercise_result.get("subject", "matematica")))
	var gained := int(exercise_result.get("energyGained", 0))
	var correct := int(exercise_result.get("correct", 0))
	var total := int(exercise_result.get("total", 0))
	var passed := bool(exercise_result.get("passed", false))
	var energy_before := game_save.energy()
	progression_manager.record_mission(subject, correct, total, gained, passed)
	_update_spaced_repetition(subject, exercise_result)
	result["energyEarned"] = int(result.get("energyEarned", 0)) + maxi(0, gained)
	var kind := str(context.get("kind", "mission"))
	if kind == "mission" or kind == "enigma":
		var encounter_id := str(context.get("encounterId", ""))
		if passed and encounter_id != "":
			var completed: Array = result["completedEncounterIds"]
			if not completed.has(encounter_id):
				completed.append(encounter_id)
			result["fragmentsEarned"] = int(result.get("fragmentsEarned", 0)) + (3 if kind == "enigma" else 2)
		if kind == "enigma":
			# La costruzione si completa solo se l'enigma è superato; altrimenti
			# resta alle campate raggiunte e la scena la ripristina alla ripetizione.
			if passed:
				enigma_progress.emit(total, total, str(context.get("theme", "ponte")), str(context.get("encounterId", "")))
				feedback.emit("%s +%d energia" % [nora_voice.line("solve"), gained])
			else:
				feedback.emit(nora_voice.line("defeat"))
		else:
			if passed:
				feedback.emit("%s +%d energia · padronanza aggiornata" % [nora_voice.line("solve"), gained])
			else:
				feedback.emit(nora_voice.line("defeat"))
	else:
		if passed and progression_manager.repair_and_advance(true):
			var apparatus_bonus := maxi(0, game_save.energy() - energy_before - gained)
			result["energyEarned"] = int(result.get("energyEarned", 0)) + apparatus_bonus
			result["fragmentsEarned"] = int(result.get("fragmentsEarned", 0)) + 4
			feedback.emit("%s Livello %d." % [nora_voice.line("victory"), game_save.level()])
		elif passed:
			feedback.emit("Il gate non è più disponibile: riprova le missioni richieste.")
		else:
			feedback.emit(nora_voice.line("defeat"))
	game_save.save()
	_emit_state()

# ---------------------------------------------------------------------------
# Bottega (C-14): acquisto/equip cosmetici. La spesa passa da spend_energy() E
# da result.energySpent, esattamente come le missioni: così il bridge riceve
# il delta corretto senza bisogno di rendere l'energia autoritativa lato Godot
# (quel salto resta un rischio da valutare in Fase 5/C-16, non qui).
# ---------------------------------------------------------------------------

func try_purchase_cosmetic(id: String) -> bool:
	if not reward_manager.can_afford(id):
		var reason := reward_manager.unavailable_reason(id)
		feedback.emit(reason if reason != "" else "Cosmetico non disponibile.")
		return false
	var cosmetic := RewardCatalog.find(id)
	var cost := int(cosmetic.get("cost", 0))
	if not game_save.spend_energy(cost):
		feedback.emit("Energia insufficiente per \"%s\"." % str(cosmetic.get("name", id)))
		return false
	result["energySpent"] = int(result.get("energySpent", 0)) + cost
	reward_manager.unlock_and_equip(id)
	game_save.save()
	feedback.emit("Acquistato: %s" % str(cosmetic.get("name", id)))
	_emit_state()
	return true

func equip_cosmetic(id: String) -> bool:
	if not reward_manager.equip(id):
		return false
	game_save.save()
	_emit_state()
	return true

func unequip_cosmetic(slot: String) -> void:
	reward_manager.unequip(slot)
	game_save.save()
	_emit_state()

# Raccolta tesoro: solo frammenti (l'energia si guadagna con gli esercizi).
func collect_treasure(payload: Dictionary) -> void:
	result["fragmentsEarned"] = int(result.get("fragmentsEarned", 0)) + int(payload.get("rewardFragments", 0))
	_emit_state()

# Prepara il risultato per il bridge Phaser all'uscita (portale legacy).
func publish_exit_state() -> void:
	game_save.save()
	result["godotSave"] = game_save.bridge_snapshot()
	result["level"] = game_save.level()
	result["missionsBySubject"] = game_save.data.get("missionsBySubject", {}).duplicate(true)
	result["mastery"] = game_save.data.get("mastery", {}).duplicate(true)
	result["apparatus"] = game_save.data.get("apparatus", {}).duplicate(true)

func _emit_state() -> void:
	runtime_state_changed.emit(runtime_state())

# Vero se la sessione contiene almeno un item in ripasso spaziato (marcato
# `review:true` da ContentManager): usato per la frase d'apertura di NORA.
func _has_review_node(session: Dictionary) -> bool:
	for node in session.get("nodes", []):
		if bool(node.get("review", false)):
			return true
	return false

func _subject_for_payload(payload: Dictionary) -> String:
	var explicit := str(payload.get("subject", "")).strip_edges().to_lower()
	if explicit != "":
		return explicit
	var biome := str(payload.get("biome", "")).strip_edges()
	var kind := str(payload.get("kind", "")).strip_edges()
	var habitat_key := "%s:%s" % [biome, kind]
	return str(BIOME_ENCOUNTER_SUBJECTS.get(habitat_key, ENCOUNTER_SUBJECT_FALLBACK.get(kind, "matematica")))

# Mappa del ripasso spaziato ("subject:topic" -> conteggio) usata dalla selezione.
func _due() -> Dictionary:
	return game_save.data.get("spacedRepetition", {}).get("due", {})

# I topic sbagliati entrano/salgono in ripasso; i ripassi risolti scendono.
func _update_spaced_repetition(subject: String, exercise_result: Dictionary) -> void:
	if not game_save.data.has("spacedRepetition"):
		game_save.data["spacedRepetition"] = {"due": {}, "history": []}
	var due: Dictionary = game_save.data["spacedRepetition"].get("due", {})
	for topic in exercise_result.get("missed", []):
		var key := "%s:%s" % [subject, str(topic)]
		due[key] = int(due.get(key, 0)) + 1
	for topic in exercise_result.get("reviewedOk", []):
		var key := "%s:%s" % [subject, str(topic)]
		var value := int(due.get(key, 0)) - 1
		if value <= 0:
			due.erase(key)
		else:
			due[key] = value
	game_save.data["spacedRepetition"]["due"] = due
