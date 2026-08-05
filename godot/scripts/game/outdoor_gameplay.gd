class_name OutdoorGameplay
extends Node

const ENIGMA_RETRY_COOLDOWN_SECONDS := 20

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

## Costo dell'uscita anticipata da una prova. Uguale all'ingresso: uscire e
## rientrare costa il doppio di restare, che è esattamente la differenza che
## serve perché ripescare le domande non convenga.
##
## Non blocca mai: se l'energia non basta si prende quella che c'è e si arriva a
## zero. Una porta che si apre solo se hai i soldi non è una porta.
const EXERCISE_ABANDON_COST := 3

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
## Stesso messaggio con provenienza esplicita. `feedback` resta per consumer
## legacy (bottega/audit); la scena usa questo per non far pronunciare a NORA
## errori tecnici, costi o messaggi di sistema.
signal feedback_presented(message: String, source: String)
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

## Il messaggio di fine pratica. Nomina al massimo **due** argomenti: tre righe
## di elenco su una sessione di quattro esercizi si leggono come un registro
## contabile, e il punto è il contrario.
##
## Se nessun argomento è avanzato — capita, quando erano già tutti applicati —
## non si inventa un premio: si dice che il manuale è già a posto su quelle cose.
## Una ricompensa finta la si riconosce subito, e svaluta quelle vere.
func _practice_feedback(advanced: Array, gained: int) -> String:
	if advanced.is_empty():
		return "%s Il manuale su questo era già a posto: hai tenuto allenato quello che sai. +%d energia" % [
			nora_voice.line("solve"), gained]
	var parts: Array = []
	for entry in advanced.slice(0, 2):
		var row := entry as Dictionary
		parts.append("«%s» ora è %s" % [
			str(row["topic"]).replace("-", " "),
			KnowledgeCodex.state_label(str(row["a"])),
		])
	var altri := advanced.size() - parts.size()
	var coda := " e altri %d" % altri if altri > 0 else ""
	return "%s Nel manuale: %s%s. +%d energia" % [
		nora_voice.line("solve"), ", ".join(PackedStringArray(parts)), coda, gained]

## Il messaggio dopo un'uscita anticipata.
##
## Non rimprovera e non consola: dice il fatto e quello che resta. NORA non è
## mai delusa da Eli — è un guard-rail narrativo del gioco — e uscire da una
## prova è una cosa che si può fare, non un fallimento da commentare.
## Che cosa manca per salire di livello, detto per nome.
##
## L'apparato si ripara con la materia del mondo; il LIVELLO si apre col nucleo
## — italiano, matematica e inglese insieme. Sono due cose diverse, ed è giusto
## che lo siano: si può accendere una stanza senza essere pronti ad andare
## avanti. Ma se il gioco non lo dice, superare l'esame e restare fermi sembra
## un difetto invece di un traguardo parziale.
##
## Il messaggio nomina le materie mancanti e dove si allenano, perché «ti manca
## il nucleo» non dice a un bambino che cosa fare adesso.
func _manca_per_salire(subject: String) -> String:
	var testa := "Apparato di %s riparato: una stanza della nave è accesa." % subject
	var stato: Dictionary = progression_manager.readiness()
	var mancanti: Array = Array(stato.get("missing", []))
	if mancanti.is_empty():
		return "%s Il livello si aprirà appena il nucleo è pronto." % testa
	var pezzi: Array = []
	for materia_data in mancanti:
		var materia := str(materia_data)
		var dettaglio: Dictionary = Dictionary(stato.get("subjects", {})).get(materia, {})
		var motivi: Array = Array(dettaglio.get("reasons", []))
		pezzi.append("%s (%s)" % [materia, ", ".join(PackedStringArray(motivi))] if not motivi.is_empty() else materia)
	return ("%s Per salire di livello serve anche il nucleo: manca %s. "
		+ "Le trovi negli incontri di pratica sparsi in questo mondo — quelli che non contano per il gate.") % [
		testa, ", ".join(PackedStringArray(pezzi))]

func _abandon_feedback(costo: int, advanced: Array) -> String:
	var testa := "Prova chiusa."
	if costo > 0:
		testa = "Prova chiusa. −%d energia." % costo
	if advanced.is_empty():
		return "%s Quello che hai visto resta nel manuale. Quando vuoi si ricomincia." % testa
	var parts: Array = []
	for entry in advanced.slice(0, 2):
		var row := entry as Dictionary
		parts.append("«%s» ora è %s" % [
			str(row["topic"]).replace("-", " "),
			KnowledgeCodex.state_label(str(row["a"])),
		])
	return "%s Nel manuale però qualcosa è rimasto: %s." % [
		testa, ", ".join(PackedStringArray(parts))]

func _present_feedback(message: String, source: String = "system") -> void:
	feedback.emit(message)
	feedback_presented.emit(message, source)

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

# ID del mondo visitato nel save persistente. È distinto dal rango `level`:
# dalla nave si può tornare in un mondo già sbloccato senza contaminare incontri,
# tesori o posizione della frontiera didattica corrente.
func _world_id() -> String:
	return str(game_save.current_world())

## Livello con cui costruire una prova nel mondo VISITATO (decisione utente del
## 29 luglio: le rivisitazioni sono ripasso mirato). Tornando in un mondo già
## superato la prova deve essere quella di QUEL mondo — i suoi argomenti, la sua
## banda di difficoltà — non quella della frontiera corrente: altrimenti chi torna
## al mondo 5 dopo il 24 riceve difficoltà massima e nessuna preferenza per gli
## argomenti di quel mondo (la lezione del livello corrente è di un'altra materia,
## quindi la preferenza si spegne da sola). La competenza reale continua a pesare
## attraverso la mastery, che alza o abbassa la difficoltà dentro quella banda.
##
## L'ESAME dell'apparato NON usa questo livello: è la prova del gate corrente e
## resta al rango del giocatore, così il ripasso non offre una scorciatoia.
func _learning_level() -> int:
	var world := int(game_save.current_world())
	var rank := int(game_save.level())
	if world > 0 and world < rank:
		return world
	return rank

# Vero se il mondo visitato è un ritorno su terreno già superato.
func is_revisit() -> bool:
	return _learning_level() != int(game_save.level())

## Stato relazionale semantico di un mondo. La scena usa questo dato per
## scegliere chi puo' convergere al Cuore, senza ricalcolare i progressi.
func relationship_stage(world_level: int) -> int:
	var bucket := game_save.world_progress(str(world_level))
	var completed := Array(bucket.get("completedEncounterIds", [])).size()
	if completed >= 3:
		return 2
	if completed >= 1:
		return 1
	return 0

func stage2_worlds() -> Array:
	var out: Array = []
	for world_level in range(1, ApparatusConfig.MAX_LEVEL):
		if relationship_stage(world_level) >= 2:
			out.append(world_level)
	return out

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
	var world_subject := str(progress.get("worldSubject", "matematica"))
	var mastery_threshold := float(progress.get("masteryThreshold", 0.0))
	# Padronanza per ciascuna materia del nucleo: è ciò che apre il livello, e
	# l'HUD la mostra come tre barre invece di un contatore di missioni.
	var core: Array = []
	var readiness: Dictionary = progress.get("readiness", {})
	var subjects: Dictionary = readiness.get("subjects", {})
	for subject in Array(progress.get("coreSubjects", [])):
		var evaluation: Dictionary = subjects.get(str(subject), {})
		core.append({
			"subject": str(subject),
			"mastery": float(evaluation.get("mastery", 0.0)),
			"progress": float(evaluation.get("progress", 0.0)),
			"ready": bool(evaluation.get("ready", false)),
			"reasons": Array(evaluation.get("reasons", [])).duplicate(),
		})
	return {
		"level": game_save.level(),
		# Ritorno su un mondo già superato: le prove sono ripasso di QUEL mondo
		# (vedi `_learning_level`). Campo read-only per l'HUD, che può dirlo al
		# bambino; nessun effetto su gate o ricompense.
		"revisit": is_revisit(),
		"learningLevel": _learning_level(),
		# Materia che ABITA il mondo (identità). Non è ciò che apre il livello.
		"focusSubject": world_subject,
		"apparatus": str(progress.get("apparatus", "nucleo")),
		# Il gate del livello: le tre del nucleo, senza conteggio di missioni.
		"coreSubjects": Array(progress.get("coreSubjects", [])).duplicate(),
		"core": core,
		"coreProgress": float(progress.get("progress", 0.0)),
		# Le materie del nucleo che mancano per SALIRE DI LIVELLO. Era qui dal
		# principio e non la leggeva nessuno: l'HUD mostrava «apparato pronto» e
		# taceva che il livello dipende da altro. Un bambino ha superato l'esame
		# del mondo 1 e non ha capito perché il mondo 2 restasse chiuso.
		"coreMissing": Array(progress.get("missing", [])).duplicate(),
		# Missioni svolte nella materia del mondo. **Non sono più un requisito**: il
		# livello si apre con la padronanza del nucleo. Restano come informazione —
		# quante ne hai fatte, quante ne offre il mondo — perché sono un dato vero e
		# perché toglierle avrebbe rotto mezza UI per nessun guadagno.
		"missionsDone": game_save.missions_toward_gate(world_subject),
		"missionsRequired": MissionEventDirector.HOST_EVENTS,
		"missionsRemaining": maxi(
			0, MissionEventDirector.HOST_EVENTS - game_save.missions_toward_gate(world_subject)),
		"missionProgress": clampf(
			float(game_save.missions_toward_gate(world_subject))
			/ float(maxi(1, MissionEventDirector.HOST_EVENTS)), 0.0, 1.0),
		"mastery": game_save.mastery_of(world_subject),
		"masteryThreshold": mastery_threshold,
		"masteryProgress": clampf(
			game_save.mastery_of(world_subject) / maxf(0.001, mastery_threshold), 0.0, 1.0),
		"ready": bool(progress.get("ready", false)),
		# Le stanze accese: è questa collezione, non il livello, ad aprire il Cuore.
		"apparatusRepaired": int(progress.get("apparatusRepaired", 0)),
		"apparatusTotal": int(progress.get("apparatusTotal", 12)),
		# Le tre dimensioni del gate (accuratezza/copertura/ritenzione) per l'HUD:
		# mostra PERCHÉ non è pronto, senza ricalcolare lato UI.
		"readiness": readiness,
		"complete": bool(progress.get("complete", false)),
		"energy": game_save.energy(),
		# Frammenti canonici (O-P0.4): fonte unica nel save, coerente dopo un reboot.
		"fragments": game_save.fragments(),
		"phase": current_phase,
		"sessionActive": session_active(),
		"stage2Worlds": stage2_worlds(),
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

# ---------------------------------------------------------------------------
# Ciclo delle sessioni
# ---------------------------------------------------------------------------

func try_start_mission(payload: Dictionary, encounter_id: String) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		_present_feedback("Incontro già completato.", "system")
		return false
	var subject := _subject_for_payload(payload)
	# C-P3: il percorso live usa il mix validato da O-P3. I renderer emettono
	# soltanto l'esito del contratto comune; scoring/mastery restano qui e
	# nell'ExercisePlayer.
	var session := content_manager.build_varied_mission(subject, _learning_level(), 3, _due(), null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		_present_feedback("Banco esercizi non disponibile per %s." % subject, "system")
		return false
	session = _decorate_teaching_session(session, subject)
	_charge_exercise_entry()
	active_session_context = {"kind": "mission", "encounterId": encounter_id, "subject": subject}
	var nora_line := str(session.get("teachingLine", NoraContextEngine.open_line(subject, _has_review_node(session))))
	_present_feedback(nora_line, "nora")
	# Il prezzo dell'uscita lo decide qui la semantica, non il player: così
	# la cifra mostrata al bambino e quella addebitata sono la stessa.
	session["abandonCost"] = EXERCISE_ABANDON_COST
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
		_present_feedback("Enigma già risolto.", "system")
		return false
	var retry_seconds := enigma_retry_seconds(encounter_id)
	if retry_seconds > 0:
		_present_feedback(
			"Ricostruzione instabile · nessuna ricompensa · ricalibrazione %d s" % retry_seconds,
			"warning")
		return false
	var subject := _subject_for_payload(payload)
	var session := content_manager.build_enigma(subject, _learning_level(), 4, _due(), null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		_present_feedback("Banco esercizi non disponibile per %s." % subject, "system")
		return false
	session = _decorate_teaching_session(session, subject)
	_charge_exercise_entry()
	var theme := str(session.get("theme", "ponte"))
	active_session_context = {"kind": "enigma", "encounterId": encounter_id, "subject": subject, "theme": theme}
	var nora_line := str(session.get("teachingLine", NoraContextEngine.open_line(subject, _has_review_node(session))))
	_present_feedback(nora_line, "nora")
	# Il prezzo dell'uscita lo decide qui la semantica, non il player: così
	# la cifra mostrata al bambino e quella addebitata sono la stessa.
	session["abandonCost"] = EXERCISE_ABANDON_COST
	session_requested.emit(session)
	# Stato iniziale della costruzione (0 campate) così la resa parte da "rotto".
	enigma_progress.emit(0, int(session.get("stages", session.get("nodes", []).size())), theme, encounter_id)
	_emit_state()
	return true

func enigma_retry_seconds(encounter_id: String) -> int:
	if game_save == null or encounter_id == "":
		return 0
	return game_save.enigma_cooldown_remaining(_world_id(), encounter_id)

## Inserisce l'insegnamento nel flusso live, non soltanto nel Manuale. Al primo
## incontro NORA presenta la mini-lezione prima della domanda; dopo un errore
## nuovamente dovuto la stessa UI diventa ripasso mirato. Lo stato "seen" viene
## registrato qui, quando la lezione è effettivamente consegnata al renderer.
func _decorate_teaching_session(source: Dictionary, subject: String) -> Dictionary:
	var session := source.duplicate(true)
	var topic := ""
	for raw_node in Array(session.get("nodes", [])):
		var node: Dictionary = raw_node
		topic = str(node.get("topic", "")).strip_edges()
		if topic != "":
			break
	if topic == "":
		return session
	var moment := KnowledgeCodex.teaching_moment(game_save, subject, topic)
	if moment == "none":
		return session
	var lesson := KnowledgeCodex.new(content_manager).mini_lesson(subject, topic)
	if lesson.is_empty():
		return session
	session["teachingMoment"] = moment
	session["teachingTopic"] = topic
	session["teachingLine"] = KnowledgeCodex.teach_line(moment)
	session["teachingLesson"] = lesson
	KnowledgeCodex.advance_state(game_save, subject, topic, "seen")
	game_save.save()
	return session

# Minigioco: un incontro risolto con formati interattivi (abbina/ordina) della
# materia. Stessa pipeline delle missioni — conta per il gate dell'apparato,
# aggiorna mastery per-topic ed energia; cambia solo la resa dei nodi.
func try_start_minigame(payload: Dictionary, encounter_id: String) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		_present_feedback("Minigioco già completato.", "system")
		return false
	var subject := _subject_for_payload(payload)
	var session := minigame_manager.build_minigame(subject, _learning_level())
	if Array(session.get("nodes", [])).is_empty():
		_present_feedback("Minigioco non disponibile per %s." % subject, "system")
		return false
	_charge_exercise_entry()
	active_session_context = {"kind": "minigame", "encounterId": encounter_id, "subject": subject}
	_present_feedback(NoraContextEngine.open_line(subject, false), "nora")
	# Il prezzo dell'uscita lo decide qui la semantica, non il player: così
	# la cifra mostrata al bambino e quella addebitata sono la stessa.
	session["abandonCost"] = EXERCISE_ABANDON_COST
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
	# L'esame è quello dell'apparato della materia che ABITA il mondo: si ripara
	# una stanza per volta, e la stanza è quella del mondo in cui ti trovi.
	var subject := ApparatusConfig.world_subject(game_save.level())
	if not progression_manager.can_repair_apparatus(subject):
		_emit_state()
		return false
	var session := content_manager.build_final_exam(subject, game_save.level(), 3, null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
	if Array(session.get("nodes", [])).is_empty():
		_present_feedback("Esame non disponibile.", "system")
		return false
	_charge_exercise_entry()
	active_session_context = {
		"kind": "final_exam",
		"subject": subject,
		"apparatus": ApparatusConfig.apparatus_of(subject),
	}
	# Il prezzo dell'uscita lo decide qui la semantica, non il player: così
	# la cifra mostrata al bambino e quella addebitata sono la stessa.
	session["abandonCost"] = EXERCISE_ABANDON_COST
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

	# Prova abbandonata: si paga l'uscita, non si registra alcun esito e non si
	# completa niente. Gli argomenti visti vanno comunque al Codex — quello che
	# il bambino ha imparato non gli viene tolto perché ha chiuso la porta.
	if bool(exercise_result.get("abandoned", false)):
		var costo := mini(EXERCISE_ABANDON_COST, game_save.energy())
		if costo > 0 and game_save.spend_energy(costo):
			result["energySpent"] = int(result.get("energySpent", 0)) + costo
		var usciti_avanzati: Array = progression_manager.record_topic_stats(
			subject, exercise_result.get("topicStats", {}))
		_update_spaced_repetition(subject, exercise_result)
		_present_feedback(_abandon_feedback(costo, usciti_avanzati), "nora")
		_emit_state()
		return
	# I minigiochi sono PRATICA ripetibile: allenano padronanza ed energia ma non
	# contano per il gate (nessun add_mission) e non completano un incontro.
	if kind == "minigame":
		progression_manager.record_practice(subject, correct, total, gained)
	else:
		progression_manager.record_mission(subject, correct, total, gained, passed)
	var codex_advanced: Array = progression_manager.record_topic_stats(
		subject, exercise_result.get("topicStats", {}))
	progress_report.record(game_save.level(), subject, game_save.mastery_of(subject), 1 if passed else 0, float(exercise_result.get("seconds", 0.0)))
	if passed:
		PlayDiary.register_passed_today(game_save)
	_update_spaced_repetition(subject, exercise_result)
	result["energyEarned"] = int(result.get("energyEarned", 0)) + maxi(0, gained)
	if kind == "minigame":
		# Pratica: nessun gate, nessun completamento persistente → rigiocabile.
		#
		# Il messaggio nomina il **Codex**, non l'energia. La pratica non apre
		# apparati e non fa salire di livello: l'unica cosa che lascia è un
		# argomento che avanza nel manuale di NORA. Dirlo con l'energia in testa
		# insegnava al bambino che la pratica serve a fare punti — e la prima
		# volta che i punti non gli servono, smette. Dirlo col Codex insegna che
		# serve a sapere una cosa in più, che è vero ed è il motivo per cui gli
		# eventi di pratica esistono.
		if passed:
			_present_feedback(_practice_feedback(codex_advanced, gained), "nora")
		else:
			_present_feedback(nora_voice.line("defeat"), "nora")
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
				game_save.clear_enigma_cooldown(_world_id(), encounter_id)
				enigma_progress.emit(total, total, str(context.get("theme", "ponte")), str(context.get("encounterId", "")))
				_present_feedback("%s +%d energia" % [nora_voice.line("solve"), gained], "nora")
			else:
				game_save.set_enigma_cooldown(
					_world_id(), encounter_id, ENIGMA_RETRY_COOLDOWN_SECONDS)
				_present_feedback(
					"Ricostruzione instabile · nessuna ricompensa · ricalibrazione %d s" %
					ENIGMA_RETRY_COOLDOWN_SECONDS,
					"warning")
		else:
			if passed:
				_present_feedback("%s +%d energia · padronanza aggiornata" % [nora_voice.line("solve"), gained], "nora")
			else:
				_present_feedback(nora_voice.line("defeat"), "nora")
	else:
		if passed:
			# `repair_and_advance` risponde «riparato OPPURE salito»: le due cose
			# sono separate da quando l'apparato e il livello sono assi distinti.
			# Prima si guardava solo quel booleano e si annunciava «Livello N» —
			# con N invariato quando il livello non era salito. Un bambino ha
			# superato l'esame del mondo 1, ha letto «Livello 1» come una
			# vittoria, e non ha capito perché il mondo 2 restasse chiuso.
			var livello_prima := game_save.level()
			progression_manager.repair_and_advance(true)
			var salito := game_save.level() > livello_prima
			var apparatus_bonus := maxi(0, game_save.energy() - energy_before - gained)
			result["energyEarned"] = int(result.get("energyEarned", 0)) + apparatus_bonus
			_award_fragments(4)
			if salito:
				_present_feedback("%s Livello %d." % [nora_voice.line("victory"), game_save.level()], "nora")
				current_narrative = str(narrative_manager.reveal_level(game_save.level()).get("text", current_narrative))
			else:
				_present_feedback(_manca_per_salire(subject), "nora")
		else:
			_present_feedback(nora_voice.line("defeat"), "nora")
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
		_present_feedback(reason if reason != "" else "Cosmetico non disponibile.", "system")
		return false
	var cosmetic := RewardCatalog.find(id)
	var cost := int(cosmetic.get("cost", 0))
	if not game_save.spend_energy(cost):
		_present_feedback("Energia insufficiente per \"%s\"." % str(cosmetic.get("name", id)), "system")
		return false
	result["energySpent"] = int(result.get("energySpent", 0)) + cost
	reward_manager.unlock_and_equip(id)
	game_save.save()
	_present_feedback("Acquistato: %s" % str(cosmetic.get("name", id)), "system")
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
