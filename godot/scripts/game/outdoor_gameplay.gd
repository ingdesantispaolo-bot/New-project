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

## Ogni quanto la copia in cloud può rifarsi. Il piano gratuito di Cloudflare
## regge mille scritture al giorno: senza un freno, sette punti di salvataggio
## in una sessione lunga lo consumerebbero per un errore di progettazione, non
## per uso. Tre minuti perdono al massimo tre minuti di gioco.
const CLOUD_MIRROR_INTERVAL_MS := 180000

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
## Luce del mondo (0..1), grado di potenza, e se QUESTA prova ha fatto salire di
## grado. La scena disegna; qui non si sa niente di nebbie e di aure.
signal world_light_changed(luce: float, grado: int, salito: bool)

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
## Copia di sicurezza in cloud: nasce alla prima occasione utile e resta nulla
## finché il profilo attivo non ha un codice — cioè sempre, negli audit.
var _cloud: CloudSave = null
var _ultimo_specchio_ms := 0

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
	# Con dodici materie l'elenco completo sarebbe illeggibile: si nominano le
	# tre più vicine al traguardo, perché sono quelle su cui conviene tornare
	# adesso, e si dice quante ne restano in tutto.
	var ordinate := mancanti.duplicate()
	ordinate.sort_custom(func(a, b):
		var da: Dictionary = Dictionary(stato.get("subjects", {})).get(str(a), {})
		var db: Dictionary = Dictionary(stato.get("subjects", {})).get(str(b), {})
		return float(da.get("progress", 0.0)) > float(db.get("progress", 0.0)))
	var pezzi: Array = []
	for materia_data in ordinate.slice(0, 3):
		var materia := str(materia_data)
		var dettaglio: Dictionary = Dictionary(stato.get("subjects", {})).get(materia, {})
		var motivi: Array = Array(dettaglio.get("reasons", []))
		pezzi.append("%s (%s)" % [materia, ", ".join(PackedStringArray(motivi))] if not motivi.is_empty() else materia)
	var coda := ""
	if ordinate.size() > pezzi.size():
		coda = " e altre %d" % (ordinate.size() - pezzi.size())
	return ("%s Per salire di livello servono TUTTE le materie a questo grado. "
		+ "Più vicine: %s%s. Si allenano negli incontri di pratica sparsi nel mondo.") % [
		testa, ", ".join(PackedStringArray(pezzi)), coda]

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
	_persist()
	_emit_state()

## Salva su disco e, quando ha senso, rispecchia in cloud.
##
## Il disco è la verità e non ha condizioni: si scrive sempre. Il cloud è una
## copia, e vale la regola che tiene in piedi tutto il resto — se non risponde,
## non succede niente e si continua a giocare. Nessun esito viene mostrato al
## bambino: una copia di sicurezza che interrompe la partita per annunciarsi ha
## sbagliato mestiere.
func _persist(forza_cloud: bool = false) -> void:
	game_save.save()
	_mirror_cloud(forza_cloud)

func _mirror_cloud(forza: bool) -> void:
	# Senza profili non esiste codice, quindi non esiste copia in cloud: è lo
	# stato di un'installazione appena avviata e di tutti gli audit.
	if not PlayerProfiles.has_profiles():
		return
	var id := PlayerProfiles.active_id()
	var codice := PlayerProfiles.code_of(id)
	if codice.is_empty():
		return
	var ora := Time.get_ticks_msec()
	if not forza and ora - _ultimo_specchio_ms < CLOUD_MIRROR_INTERVAL_MS:
		return
	if _cloud == null:
		_cloud = CloudSave.new()
		_cloud.name = "CloudMirror"
		add_child(_cloud)
	if _cloud.occupato():
		return
	# Il tempo si segna adesso, non a risposta arrivata: se il cloud è
	# irraggiungibile, riprovare a ogni salvataggio riempirebbe la sessione di
	# richieste destinate a fallire.
	_ultimo_specchio_ms = ora
	_cloud.carica(codice, game_save.data, str(PlayerProfiles.find(id).get("name", "")))

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
	_persist()
	return session

## Quante estrazioni tentare prima di rassegnarsi a riproporre qualcosa di già
## visto. Sei bastano: il repertorio di una materia si satura molto prima.
const PRACTICE_RIESTRAZIONI := 6

## Nessun tetto al catalogo interattivo — e la storia di questa costante vale
## più del suo valore.
##
## Il 6 agosto 2026 ci avevo messo 0.5, cioè metà sessione dai banchi, per
## riparare una scarsità che avevo misurato: «al livello 1 il catalogo offre da
## 5 a 16 quesiti distinti». Quel numero era **sbagliato**, e in un modo che si
## vedeva solo leggendo i costruttori: nei formati interattivi il `prompt` è una
## COSTANTE — ogni abbinamento del gioco dice «Abbina ogni elemento alla sua
## coppia», qualunque siano le coppie. Contando i testi, tutti gli abbinamenti
## risultavano un esercizio solo.
##
## Contando il CONTENUTO, il catalogo produce da 354 a 826 nodi distinti già al
## livello 1. Rimisurata la rigiocata con l'identità giusta: 91% di inediti al
## secondo viaggio, **con o senza il tetto, identico**. Il tetto non serviva a
## niente e costava metà della forma interattiva, che è il motivo per cui la
## pratica esiste.
##
## Resta a 1.0 come promemoria: se un giorno servisse davvero un tetto, prima si
## misura con `practice_node_fingerprint`, non con i testi.
const PRACTICE_QUOTA_CATALOGO := 1.0

## Una sessione di pratica fatta di quesiti che il bambino NON ha appena visto.
##
## Nasce da una segnalazione di gioco del 6 agosto 2026: lo studente rifaceva la
## stessa location e ritrovava gli stessi quesiti identici, salendo di padronanza
## senza imparare niente. Misurato prima di intervenire: rigiocando dieci volte,
## **il 55% dei quesiti di pratica erano gli stessi** (fino all'83% in geografia
## al livello 1), contro il 13% delle missioni — che è normale sovrapposizione
## d'estrazione.
##
## La causa non era il caso: i due costruttori estraggono davvero a sorte. Era il
## **fondo**. Il repertorio dei minigiochi per geografia e storia al livello 1
## conta cinque quesiti distinti in tutto, e una sessione ne consuma quattro o
## cinque: la seconda volta non poteva che essere la prima.
##
## Quindi si procede in tre passi, in ordine di preferenza:
##
##   1. si scartano i quesiti già visti di recente (memoria nel salvataggio);
##   2. si riestrae dal catalogo dei minigiochi per rimpiazzarli, perché la
##      forma interattiva è il motivo per cui la pratica esiste;
##   3. quando il catalogo è esaurito si attinge ai **banchi**, che di fondo ne
##      hanno (dai 23 ai 30 esercizi distinti per casella, misurati). Meglio un
##      quesito di forma più semplice ma nuovo che un abbinamento già fatto.
##
## Se anche i banchi non bastano si riempie con quello che c'è: una sessione
## vuota sarebbe un vicolo cieco, e un vicolo cieco è peggio di una ripetizione.
func _build_practice_session(subject: String) -> Dictionary:
	var livello := _learning_level()
	var session := minigame_manager.build_minigame(subject, livello)
	var voluti := Array(session.get("nodes", [])).size()
	if voluti == 0:
		return session

	var evita := game_save.recent_practice(subject)
	var visti_qui: Dictionary = {}      # niente doppioni dentro la stessa sessione
	var tenuti: Array = []
	var scartati: Array = []

	var raccogli := func(nodi: Array) -> void:
		for n in nodi:
			if tenuti.size() >= voluti:
				return
			var nodo: Dictionary = n
			var impronta := GameSaveManager.practice_node_fingerprint(nodo)
			if visti_qui.has(impronta):
				continue
			if evita.has(impronta):
				scartati.append(nodo)
				continue
			visti_qui[impronta] = true
			tenuti.append(nodo)

	# Il catalogo per primo, ma fino al tetto: è la forma interattiva che dà
	# valore alla pratica, non la quantità.
	var tetto := maxi(1, int(ceil(float(voluti) * PRACTICE_QUOTA_CATALOGO)))
	raccogli.call(Array(session.get("nodes", [])).slice(0, tetto))
	var tentativi := 0
	while tenuti.size() < tetto and tentativi < PRACTICE_RIESTRAZIONI:
		tentativi += 1
		raccogli.call(Array(minigame_manager.build_minigame(subject, livello).get("nodes", [])).slice(0, tetto))

	if tenuti.size() < voluti:
		# Il resto dai banchi, che di fondo ne hanno. Si chiede con abbondanza
		# perché il filtro dei già visti ne scarterà una parte.
		var mancano := voluti - tenuti.size()
		var missione := content_manager.build_mission(
			subject, livello, mancano * 3, _due(),
			null, game_save.mastery_of(subject), game_save.topic_masteries(subject))
		raccogli.call(Array(missione.get("nodes", [])))

	# Se i banchi non sono bastati si torna al catalogo senza tetto: meglio un
	# abbinamento in più che una sessione corta.
	tentativi = 0
	while tenuti.size() < voluti and tentativi < PRACTICE_RIESTRAZIONI:
		tentativi += 1
		raccogli.call(Array(minigame_manager.build_minigame(subject, livello).get("nodes", [])))

	# Ultima risorsa: si riammettono i già visti, i più vecchi per primi. Non
	# capita quasi mai, e quando capita è meglio di una sessione vuota.
	var i := 0
	while tenuti.size() < voluti and i < scartati.size():
		tenuti.append(scartati[i])
		i += 1

	session["nodes"] = tenuti
	return session

# Minigioco: un incontro risolto con formati interattivi (abbina/ordina) della
# materia. Stessa pipeline delle missioni — conta per il gate dell'apparato,
# aggiorna mastery per-topic ed energia; cambia solo la resa dei nodi.
## Energia guadagnata superando un lavoretto in bottega.
##
## La bottega finora sapeva solo SPENDERE: si entrava per comprare e si usciva
## piu' poveri. Un luogo che toglie e basta non e' un posto dove si torna.
## Il lavoretto e' l'unica prova del gioco che PAGA invece di costare, e per
## questo non conta per il gate: se contasse, diventerebbe la strada piu' comoda
## e nessuno andrebbe piu' a praticare nel mondo.
const LAVORETTO_PAGA := 9

## Un turno di lavoro in bottega: si gioca la materia del mondo e si viene
## pagati. Ingresso gratuito — un lavoro che si paga per fare non e' un lavoro.
func try_start_lavoretto(subject: String, encounter_id: String) -> bool:
	if session_active():
		return false
	var session := _build_practice_session(subject)
	if Array(session.get("nodes", [])).is_empty():
		return false
	var impronte: Array = []
	for n in Array(session.get("nodes", [])):
		impronte.append(GameSaveManager.practice_node_fingerprint(n as Dictionary))
	active_session_context = {
		"kind": "lavoretto", "encounterId": encounter_id, "subject": subject,
		"impronte": impronte,
	}
	session["abandonCost"] = EXERCISE_ABANDON_COST
	session_requested.emit(session)
	_emit_state()
	return true

## `sconto` dimezza il costo d'ingresso: lo usa la casa del mestiere.
##
## Lo sconto non e' una ricompensa, e' informazione. Un bambino che paga meno in
## un certo edificio capisce da solo a che cosa serve quell'edificio, senza che
## nessuno glielo spieghi — ed e' il modo piu' economico di dare un senso a un
## luogo sulla mappa.
func try_start_minigame(payload: Dictionary, encounter_id: String, sconto: bool = false) -> bool:
	if session_active():
		return false
	if Array(result.get("completedEncounterIds", [])).has(encounter_id):
		_present_feedback("Minigioco già completato.", "system")
		return false
	var subject := _subject_for_payload(payload)
	var session := _build_practice_session(subject)
	if Array(session.get("nodes", [])).is_empty():
		_present_feedback("Minigioco non disponibile per %s." % subject, "system")
		return false
	_charge_exercise_entry(0.5 if sconto else 1.0)
	# I testi dei quesiti viaggiano nel contesto: alla chiusura finiscono nella
	# memoria della pratica, così la prossima palestra non li ripropone. Il
	# player non li restituisce, e leggerli qui è l'unico punto in cui esistono
	# di sicuro.
	var impronte: Array = []
	for n in Array(session.get("nodes", [])):
		impronte.append(GameSaveManager.practice_node_fingerprint(n as Dictionary))
	active_session_context = {
		"kind": "minigame", "encounterId": encounter_id, "subject": subject,
		"impronte": impronte,
	}
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
## `fattore` scala il costo d'ingresso: 1.0 ovunque, 0.5 nella casa del
## mestiere. Il minimo resta 1 quando il fattore non e' zero — un ingresso
## gratuito non e' uno sconto, e' un'altra cosa.
func _charge_exercise_entry(fattore: float = 1.0) -> int:
	var costo := maxi(1, int(round(float(EXERCISE_ENERGY_COST) * fattore))) if fattore > 0.0 else 0
	if costo <= 0:
		return 0
	if game_save.energy() < costo:
		return 0
	if not game_save.spend_energy(costo):
		return 0
	result["energySpent"] = int(result.get("energySpent", 0)) + costo
	return costo

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
	# Dichiarata qui e non nel ramo dell'esame: serve in fondo alla funzione, per
	# decidere se la copia in cloud debba partire subito invece di aspettare.
	var salito_di_livello := false

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
	# Il LAVORETTO in bottega: paga e non conta per niente altro. Allena la
	# padronanza come la pratica — le domande sono le stesse — ma non chiude
	# incontri e non apre apparati.
	if kind == "lavoretto":
		progression_manager.record_practice(subject, correct, total, 0)
		if passed:
			var paga := LAVORETTO_PAGA
			game_save.add_energy(paga)
			result["energyEarned"] = int(result.get("energyEarned", 0)) + paga
			game_save.remember_practice_prints(subject, Array(context.get("impronte", [])))
			_present_feedback("Turno finito. +%d energia, e il banco è in ordine." % paga, "system")
		else:
			_present_feedback("Turno saltato: niente paga, ma niente danni.", "system")
		_persist()
		_emit_state()
		return

	# I minigiochi sono PRATICA: allenano padronanza ed energia ma non contano per
	# il gate (nessun add_mission). Dal 6 agosto 2026 una palestra SUPERATA si
	# chiude, perché rifarla identica era diventata una scorciatoia.
	if kind == "minigame":
		progression_manager.record_practice(subject, correct, total, gained)
	else:
		progression_manager.record_mission(subject, correct, total, gained, passed)
	var codex_advanced: Array = progression_manager.record_topic_stats(
		subject, exercise_result.get("topicStats", {}))
	progress_report.record(game_save.level(), subject, game_save.mastery_of(subject), 1 if passed else 0, float(exercise_result.get("seconds", 0.0)))
	if passed:
		PlayDiary.register_passed_today(game_save)
		# **La ricompensa immediata.** Ogni prova superata scopre un pezzo di
		# mondo e fa crescere la potenza: e' il ciclo che il collaudo ha trovato
		# mancante: prima l'unico momento in cui succedeva qualcosa era l'esame,
		# a mezz'ora di distanza.
		var luce := WorldLight.accendi(game_save, _world_id())
		var salito_grado := WorldLight.avanza_potenza(game_save)
		world_light_changed.emit(luce, WorldLight.grado(game_save), salito_grado)
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
		# Quello che ha appena visto non deve tornare alla prossima palestra. Si
		# ricorda SEMPRE, superata o no: rifare identici gli esercizi sbagliati è
		# la scorciatoia più tentante di tutte — si impara la risposta, non la
		# regola.
		game_save.remember_practice_prints(subject, Array(context.get("impronte", [])))

		if passed:
			# Superata: QUESTA location è finita e sparisce dalla mappa.
			#
			# Segnalazione di gioco del 6 agosto 2026: lo studente rifaceva la
			# stessa palestra all'infinito per far salire la padronanza. Il ramo
			# che chiude un incontro esisteva solo per missioni ed enigmi — la
			# pratica non veniva mai chiusa, e il controllo in `try_start_minigame`
			# leggeva una lista che nessuno riempiva: era codice morto.
			#
			# La pratica resta comunque disponibile: il direttore ne rigenera una
			# altrove al rientro nel mondo (vedi `mission_event_director.gd`), e
			# ogni materia ne ha una propria. Chiudere questa non chiude la strada.
			var practice_id := str(context.get("encounterId", ""))
			if practice_id != "":
				var chiusi: Array = result["completedEncounterIds"]
				if not chiusi.has(practice_id):
					chiusi.append(practice_id)
				game_save.mark_encounter_completed(_world_id(), practice_id)
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
			salito_di_livello = game_save.level() > livello_prima
			var apparatus_bonus := maxi(0, game_save.energy() - energy_before - gained)
			result["energyEarned"] = int(result.get("energyEarned", 0)) + apparatus_bonus
			_award_fragments(4)
			if salito_di_livello:
				_present_feedback("%s Livello %d." % [nora_voice.line("victory"), game_save.level()], "nora")
				current_narrative = str(narrative_manager.reveal_level(game_save.level()).get("text", current_narrative))
			else:
				_present_feedback(_manca_per_salire(subject), "nora")
		else:
			_present_feedback(nora_voice.line("defeat"), "nora")
	# Forzato: salire di livello è il momento che fa più male perdere, ed è anche
	# raro — non consuma il piano gratuito come farebbe una copia a ogni prova.
	_persist(salito_di_livello)
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
	_persist()
	_present_feedback("Acquistato: %s" % str(cosmetic.get("name", id)), "system")
	_emit_state()
	return true

func equip_cosmetic(id: String) -> bool:
	if not reward_manager.equip(id):
		return false
	_persist()
	_emit_state()
	return true

func unequip_cosmetic(slot: String) -> void:
	reward_manager.unequip(slot)
	_persist()
	_emit_state()

# Raccolta tesoro: solo frammenti (l'energia si guadagna con gli esercizi). Il
# tesoro è persistente nel save canonico del mondo: raccolto una volta, non torna
# nemmeno dopo un reboot. `treasure_id` è l'id univoco della cassa (dalla scena).
func collect_treasure(payload: Dictionary, treasure_id: String = "") -> void:
	var id := treasure_id if treasure_id != "" else str(payload.get("treasureId", payload.get("id", "")))
	if id != "" and not game_save.mark_treasure_collected(_world_id(), id):
		return  # già raccolto in questo mondo: nessuna doppia ricompensa
	_award_fragments(int(payload.get("rewardFragments", 0)))
	_persist()
	_emit_state()

# Concede frammenti aggiornando SIA il delta di sessione (riepilogo/HUD) SIA il
# save canonico (O-P0.4): la valuta sopravvive a un reboot.
func _award_fragments(amount: int) -> void:
	if amount == 0:
		return
	result["fragmentsEarned"] = int(result.get("fragmentsEarned", 0)) + amount
	game_save.add_fragments(amount)

func _emit_state() -> void:
	# L'atto in cui parla NORA. Qui e non nei punti di chiamata: `_emit_state`
	# passa dopo ogni cosa che può far salire di livello, quindi la voce non può
	# restare indietro di un mondo — e restare indietro non darebbe errore, si
	# sentirebbe soltanto come una NORA che non ha ancora scoperto quello che ha
	# appena detto al giocatore.
	nora_voice.level = game_save.level()
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
