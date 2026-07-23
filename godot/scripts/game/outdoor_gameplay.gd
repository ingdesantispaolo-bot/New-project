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
var minigame_manager := MinigameManager.new()
var progression_manager: ProgressionManager
var reward_manager: RewardManager
var nora_voice := NoraVoice.new()
var narrative_manager := NarrativeManager.new()
var progress_report := LocalProgressReport.new()
var current_narrative := ""
var result: Dictionary                           # delta della sessione mondo corrente
var active_session_context: Dictionary = {}
var base_fragments := 0
var current_phase := "giorno"

func setup(request: Dictionary, session_result: Dictionary, load_local_save: bool = true) -> void:
	result = session_result
	game_save = GameSaveManager.new()
	if load_local_save:
		game_save.load_save()
	game_save.apply_launch_state(request)
	content_manager = ContentManager.new()
	# ContentManager prima di ProgressionManager: serve alla dimensione COPERTURA
	# del gate (numero di argomenti che la materia può proporre).
	progression_manager = ProgressionManager.new(game_save, content_manager)
	reward_manager = RewardManager.new(game_save)
	narrative_manager.setup(game_save)
	progress_report.setup(game_save)
	current_narrative = str(narrative_manager.reveal_level(game_save.level()).get("text", ""))
	# Frammenti CANONICI (O-P0.4): la valuta vive nel save, non nello stato
	# transitorio della sessione, così un reboot non la perde. Riconciliazione una
	# tantum: se un save precedente portava frammenti solo nel bridge transitorio,
	# li adottiamo nel canonico (max), poi il canonico è la fonte autoritativa.
	var bridged_fragments := int(request.get("outdoorState", {}).get("fragments", 0))
	if bridged_fragments > game_save.fragments():
		game_save.add_fragments(bridged_fragments - game_save.fragments())
	base_fragments = game_save.fragments()
	# Incontri/tesori CANONICI: idrata il delta della sessione dal save del mondo
	# corrente (merge additivo: aggiunge solo id già risolti, non ne toglie mai),
	# così ciò che era già stato completato non viene riproposto dopo un reboot.
	_hydrate_world_progress()
	game_save.save()
	_emit_state()

# ID del mondo corrente nel save persistente: un mondo per livello (mappa dei 24).
func _world_id() -> String:
	return str(game_save.level())

# Fonde nel `result` di sessione gli id già risolti nel save canonico del mondo.
func _hydrate_world_progress() -> void:
	var bucket := game_save.world_progress(_world_id())
	var completed: Array = result.get("completedEncounterIds", [])
	for id in bucket.get("completedEncounterIds", []):
		if not completed.has(id):
			completed.append(id)
	result["completedEncounterIds"] = completed
	var treasures: Array = result.get("collectedTreasureIds", [])
	for id in bucket.get("collectedTreasureIds", []):
		if not treasures.has(id):
			treasures.append(id)
	result["collectedTreasureIds"] = treasures

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
		# Le 4 dimensioni del gate (accuratezza/copertura/confidenza/ritenzione) per
		# l'HUD: mostra PERCHÉ il gate non è pronto, senza ricalcolare lato UI.
		"readiness": progress.get("readiness", {}),
		"complete": bool(progress.get("complete", false)),
		"energy": game_save.energy(),
		# Frammenti canonici (O-P0.4): fonte unica nel save, coerente dopo un reboot.
		"fragments": game_save.fragments(),
		"phase": current_phase,
		"sessionActive": session_active(),
		"narrative": current_narrative,
		"progressReport": progress_report.summary(),
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
	if bool(progress.get("complete", false)):
		return "Nave completamente riattivata · tutti i 24 nodi sono online"
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
	var session := content_manager.build_mission(subject, game_save.level(), 3, _due(), null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Banco esercizi non disponibile per %s." % subject)
		return false
	_charge_exercise_entry()
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
	var session := content_manager.build_enigma(subject, game_save.level(), 4, _due(), null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Banco esercizi non disponibile per %s." % subject)
		return false
	_charge_exercise_entry()
	var theme := str(session.get("theme", "ponte"))
	active_session_context = {"kind": "enigma", "encounterId": encounter_id, "subject": subject, "theme": theme}
	feedback.emit(NoraContextEngine.open_line(subject, _has_review_node(session)))
	session_requested.emit(session)
	# Stato iniziale della costruzione (0 campate) così la resa parte da "rotto".
	enigma_progress.emit(0, int(session.get("stages", session.get("nodes", []).size())), theme, encounter_id)
	_emit_state()
	return true

# Minigioco: un incontro risolto con formati interattivi (abbina/ordina) della
# materia. Stessa pipeline delle missioni — conta per il gate dell'apparato,
# aggiorna mastery per-topic ed energia; cambia solo la resa dei nodi.
func try_start_minigame(payload: Dictionary, encounter_id: String) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		feedback.emit("Minigioco già completato.")
		return false
	var subject := _subject_for_payload(payload)
	var session := minigame_manager.build_minigame(subject, game_save.level())
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Minigioco non disponibile per %s." % subject)
		return false
	_charge_exercise_entry()
	active_session_context = {"kind": "minigame", "encounterId": encounter_id, "subject": subject}
	feedback.emit(NoraContextEngine.open_line(subject, false))
	session_requested.emit(session)
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
	var session := content_manager.build_final_exam(subject, game_save.level(), 3, null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		feedback.emit("Esame non disponibile.")
		return false
	_charge_exercise_entry()
	active_session_context = {"kind": "final_exam", "subject": subject, "apparatus": str(gate.get("apparatus", "nucleo"))}
	session_requested.emit(session)
	_emit_state()
	return true

## Il loop educativo deve restare sempre avviabile. Con almeno 3 energia si
## applica il costo normale; sotto soglia l'ingresso diventa di recupero e non
## consuma il residuo. In questo modo un profilo nuovo o un acquisto in bottega
## non possono bloccare per sempre l'unico modo di riguadagnare energia.
func _charge_exercise_entry() -> int:
	if game_save.energy() < EXERCISE_ENERGY_COST:
		return 0
	if not game_save.spend_energy(EXERCISE_ENERGY_COST):
		return 0
	result["energySpent"] = int(result.get("energySpent", 0)) + EXERCISE_ENERGY_COST
	return EXERCISE_ENERGY_COST

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
	var kind := str(context.get("kind", "mission"))
	# I minigiochi sono PRATICA ripetibile: allenano padronanza ed energia ma non
	# contano per il gate (nessun add_mission) e non completano un incontro.
	if kind == "minigame":
		progression_manager.record_practice(subject, correct, total, gained)
	else:
		progression_manager.record_mission(subject, correct, total, gained, passed)
	progression_manager.record_topic_stats(subject, exercise_result.get("topicStats", {}))
	progress_report.record(game_save.level(), subject, game_save.mastery_of(subject), 1 if passed else 0, float(exercise_result.get("seconds", 0.0)))
	_update_spaced_repetition(subject, exercise_result)
	result["energyEarned"] = int(result.get("energyEarned", 0)) + maxi(0, gained)
	if kind == "minigame":
		# Pratica: nessun gate, nessun completamento persistente → rigiocabile.
		if passed:
			feedback.emit("%s +%d energia · pratica completata" % [nora_voice.line("solve"), gained])
		else:
			feedback.emit(nora_voice.line("defeat"))
	elif kind == "mission" or kind == "enigma":
		var encounter_id := str(context.get("encounterId", ""))
		if passed and encounter_id != "":
			var completed: Array = result["completedEncounterIds"]
			if not completed.has(encounter_id):
				completed.append(encounter_id)
			# Incontro persistente nel save canonico del mondo (O-P0.4).
			game_save.mark_encounter_completed(_world_id(), encounter_id)
			_award_fragments(3 if kind == "enigma" else 2)
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
			_award_fragments(4)
			feedback.emit("%s Livello %d." % [nora_voice.line("victory"), game_save.level()])
			current_narrative = str(narrative_manager.reveal_level(game_save.level()).get("text", current_narrative))
		elif passed:
			feedback.emit("Il gate non è più disponibile: riprova le missioni richieste.")
		else:
			feedback.emit(nora_voice.line("defeat"))
	game_save.save()
	_emit_state()

# ---------------------------------------------------------------------------
# Bottega (C-14): acquisto/equip cosmetici. La spesa passa da spend_energy() E
# da result.energySpent, esattamente come le missioni, così il riepilogo della
# sessione resta coerente senza duplicare l'economia del save canonico.
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

# Raccolta tesoro: solo frammenti (l'energia si guadagna con gli esercizi). Il
# tesoro è persistente nel save canonico del mondo: raccolto una volta, non torna
# nemmeno dopo un reboot. `treasure_id` è l'id univoco della cassa (dalla scena).
func collect_treasure(payload: Dictionary, treasure_id: String = "") -> void:
	var id := treasure_id if treasure_id != "" else str(payload.get("treasureId", payload.get("id", "")))
	if id != "" and not game_save.mark_treasure_collected(_world_id(), id):
		return  # già raccolto in questo mondo: nessuna doppia ricompensa
	_award_fragments(int(payload.get("rewardFragments", 0)))
	game_save.save()
	_emit_state()

# Concede frammenti aggiornando SIA il delta di sessione (riepilogo/HUD) SIA il
# save canonico (O-P0.4): la valuta sopravvive a un reboot.
func _award_fragments(amount: int) -> void:
	if amount == 0:
		return
	result["fragmentsEarned"] = int(result.get("fragmentsEarned", 0)) + amount
	game_save.add_fragments(amount)

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

# Argomenti DOVUTI ora ("subject:topic" -> 1) dallo scheduler temporale: forma
# attesa dalla selezione di ContentManager (ogni chiave con valore > 0 è ripasso).
func _due() -> Dictionary:
	return SpacedRepetition.due_map(game_save)

# Applica gli esiti al ripasso spaziato (O-P0.7): i topic sbagliati rientrano a
# breve, quelli ripassati bene vengono allontanati (intervallo espansivo), e
# l'orologio delle sessioni avanza di un passo.
func _update_spaced_repetition(subject: String, exercise_result: Dictionary) -> void:
	SpacedRepetition.apply_outcome(game_save, subject, exercise_result.get("missed", []), exercise_result.get("reviewedOk", []))
	SpacedRepetition.tick(game_save)
