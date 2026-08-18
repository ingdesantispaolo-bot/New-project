class_name ExercisePlayer
extends Control

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")
const EXERCISE_DRAG_BUTTON := preload("res://scripts/ui/exercise_drag_button.gd")
const EXERCISE_DROP_BUTTON := preload("res://scripts/ui/exercise_drop_button.gd")
const EXERCISE_CONNECTION_CANVAS := preload("res://scripts/ui/exercise_connection_canvas.gd")
const EXERCISE_DIAGRAM := preload("res://scripts/ui/exercise_diagram.gd")
const MAP_GEOMETRY_CATALOG := preload("res://scripts/visual/map_geometry_catalog.gd")
const ARTIFACT_ATLAS_CATALOG := preload("res://scripts/visual/artifact_atlas_catalog.gd")
const FINAL_CONVERGENCE_DISPLAY := preload("res://scripts/ui/final_convergence_display.gd")

## UI data-driven degli esercizi: riceve una sessione (missione o esame finale) e
## la gioca item per item. Supporta scelta/input, ordering, matching,
## classificazione, hotspot, grafici, circuiti, notazione, carte mute e code-debug. Emette
## `session_finished` con l'esito. Vedi docs/DESIGN_COMPLETO.md §6.
##
## Politica errore: un errore toglie uno scudo e mostra la spiegazione; a scudi
## esauriti la sessione fallisce e va ripetuta (nessun progresso cancellato).

signal session_finished(result: Dictionary)
## Emesso dopo ogni risposta: `built` = risposte corrette finora (avanza solo se
## la risposta era giusta), `total` = numero di esercizi. Serve all'enigma
## ambientale per far crescere la costruzione nel mondo (una campata per risposta
## corretta). Le sessioni normali possono ignorarlo.
signal progress_changed(built: int, total: int)
## Richiesta esplicita di aiuto sul concetto corrente. La scena apre il Manuale
## NORA sopra la sessione senza ricrearla; negli esami il pulsante non compare.
signal concept_help_requested(subject: String, topic: String)
## Segnali di apprendimento/relazione privi di effetti economici. Il consumer
## semantico decide come persisterli nello stato NORA.
signal learning_signal(signal_name: String)
## Terzo errore sullo stesso argomento, in QUESTA sessione, emesso una sola
## volta. Non è un segnale di apprendimento verso NORA: è per il Custode, che
## sdrammatizza senza aiutare e senza che NORA lo commenti. Vedi
## docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B.
signal topic_struggle(topic: String)

## Esito di una singola risposta. I `learning_signal` sono una-volta-per-argomento
## (perseveranza, trasferimento, errore ricorrente): servono alla relazione con
## NORA, non al battito dell'esercizio. Questo segnala ogni risposta, e lo consuma
## il Custode per reagire. Annuncia, non comanda: chi ascolta decide cosa farne.
signal answer_resolved(is_correct: bool)

var session: Dictionary
var _nodes: Array = []
var _index := 0
var _correct := 0
var _shields := 3
var _energy := 0
var _energy_per_correct := 10
## Costo dell'uscita anticipata, letto dalla sessione. Vedi `_build_exit_row()`.
var _abandon_cost := 3
var _abandon_armed := false
var _started_at_msec := 0
var _answered := false
var _missed: Array = []       # topic sbagliati → ripasso spaziato
var _reviewed_ok: Array = []  # topic di ripasso risolti correttamente
var _topic_seen: Dictionary = {}     # topic -> item incontrati (per mastery per-topic)
## Gli argomenti gia' spiegati in QUESTA sessione. Due nodi sullo stesso
## argomento non devono far leggere la stessa scheda due volte: la seconda si
## chiude senza guardarla, e da li' in poi si chiudono tutte.
var _lezioni_mostrate: Dictionary = {}
var _topic_correct: Dictionary = {}  # topic -> risposte corrette
var _wrong_attempts: Dictionary = {}  # topic -> tentativi errati nella sessione
var _struggle_emitted: Dictionary = {}  # topic -> già segnalato in questa sessione
var _maestro_voice: Dictionary = {}
var _learning_emitted: Dictionary = {}
var _systems_resolved: Dictionary = {}

var _prompt: Label
var _options: VBoxContainer
var _feedback: Label
var _status: Label
var _next_button: Button
var _help_button: Button
var _exit_button: Button
var _exit_stay_button: Button
var _exit_notice: Label
var _input: LineEdit
var _input_submit: Button
## L'indizio delle domande aperte: dà la forma della risposta, mai la risposta.
var _hint_button: Button
## Quanti indizi sono già stati scoperti su QUESTA domanda. Riparte a ogni nodo:
## un contatore che non riparte trasformerebbe il terzo indizio in un premio per
## chi ha sbagliato molto prima, che non c'entra niente.
var _hint_level := 0
## Tastierino numerico disegnato dal gioco.
##
## Serve perché su tablet il `LineEdit` da solo **non si riempie**: la tastiera
## di sistema nella build Web arriva solo se l'export ha
## `html/experimental_virtual_keyboard`, e anche con quella accesa dipende dal
## browser. Un esercizio a risposta numerica che non si può rispondere blocca il
## giocatore, e finora non c'era nemmeno un modo per uscirne.
##
## Questo tastierino non dipende da niente: è fatto di bottoni, funziona
## identico su desktop, tablet e Web, e su uno schermo tattile è comunque il
## modo più comodo di scrivere un numero.
var _numpad: GridContainer
var _convergence_display: FinalConvergenceDisplay
var _exercise_panel: PanelContainer
var _options_scroll: ScrollContainer

# Stato dei minigiochi interattivi (formati "ordering" e "matching"). Ogni nodo
# minigioco vale come un esercizio: risolverlo = 1 corretto; gli errori intermedi
# tolgono scudi come una risposta sbagliata.
var _mg_buttons: Array = []       # ordering: pulsanti degli elementi da ordinare
var _mg_left_buttons: Array = []  # matching: colonna sinistra
var _mg_right_buttons: Array = [] # matching: colonna destra (mescolata)
var _mg_expected := 0             # ordering: prossima posizione da riempire
var _mg_selected_left := -1       # matching: indice sinistra selezionato
var _mg_matched := 0              # matching: coppie completate
var _ordering_state: Array = []
var _ordering_slots: Array = []
var _matching_connections: Array = []
var _matching_canvas: Control
var _classification_state: Dictionary = {}
var _classification_buttons: Dictionary = {}
var _classification_selected := ""
var _machine_state: Array = []
var _machine_slots: Array = []
var _machine_buttons: Dictionary = {}
var _machine_readout: Label
var _machine_running := false
var _sample_tests_run: Array = []
var _sample_test_buttons: Dictionary = {}
var _sample_candidate_buttons: Dictionary = {}
var _sample_selected := ""
var _sample_log: Label
var _sample_capsule: PanelContainer
var _sample_capsule_label: Label
var _verb_selection := {"time": "", "mood": "", "form": ""}
var _verb_buttons: Dictionary = {}
var _verb_preview: Label
var _verb_scanner: ColorRect
var _verb_running := false
var _visual_selected := ""
var _visual_buttons: Dictionary = {}
var _visual_diagram: Control
var _cycle_sequence: Array = []
## Quanti indizi il giocatore ha chiesto sul nodo corrente. Si azzera a ogni
## nodo, come gli scudi si azzerano a ogni sessione.
var _clues_revealed := 0
var _clue_button: Button
## Stato del minigioco a scorrimento. Vive nel player e non nel contenuto
## perché cambia mentre si gioca.
var _swipe_index := 0
var _swipe_streak := 0
var _swipe_best := 0
var _swipe_score := 0
var _swipe_right := 0
var _swipe_seconds := 0.0
var _swipe_item: Dictionary = {}
var _rng: RandomNumberGenerator
var high_contrast := false
var reduced_motion := false

func configure_accessibility(use_high_contrast: bool, use_reduced_motion: bool) -> void:
	high_contrast = use_high_contrast
	reduced_motion = use_reduced_motion
	set_meta("high_contrast", high_contrast)
	set_meta("reduced_motion", reduced_motion)

func start_session(new_session: Dictionary) -> void:
	session = new_session
	_maestro_voice = Dictionary(session.get("maestroVoice", {})).duplicate(true)
	var accessibility: Dictionary = session.get("accessibility", {})
	if not accessibility.is_empty():
		configure_accessibility(
			bool(accessibility.get("highContrast", high_contrast)),
			bool(accessibility.get("reducedMotion", reduced_motion))
		)
	_nodes = session.get("nodes", [])
	if OS.has_feature("web") and not _nodes.is_empty():
		var web_format := ExerciseInteraction.format_of(_nodes[0])
		JavaScriptBridge.eval(
			"document.documentElement.dataset.eliExercise = %s;" % JSON.stringify(web_format)
		)
	_index = 0
	_correct = 0
	_shields = int(session.get("shields", 3))
	_energy = 0
	_abandon_armed = false
	_abandon_cost = int(session.get("abandonCost", 3))
	_started_at_msec = Time.get_ticks_msec()
	_missed = []
	_reviewed_ok = []
	_topic_seen = {}
	_lezioni_mostrate = {}
	_topic_correct = {}
	_wrong_attempts = {}
	_struggle_emitted = {}
	_learning_emitted = {}
	_systems_resolved = {}
	_convergence_display = null
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	_energy_per_correct = int(session.get("rewards", {}).get("energyPerCorrect", 10))
	var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
	if audio != null:
		audio.call("play_event", "sessionStarted")
		audio.call("play_subject", str(session.get("subject", "")))
		audio.call("set_focus", true)
	_build_ui()
	_show_current()
	if not _maestro_voice.is_empty() and is_instance_valid(_feedback):
		_feedback.add_theme_color_override("font_color", Color("9fded8"))
		_feedback.text = "NORA · %s: %s" % [
			str(_maestro_voice.get("name", "Maestro")),
			str(_maestro_voice.get("apertura", ""))]
	_show_teaching_overlay()

func _build_ui() -> void:
	for child in get_children():
		# La sessione successiva può iniziare nello stesso frame della precedente.
		# Rimuovere subito evita nomi accessibili duplicati (es. pulsante aiuto)
		# lasciati temporaneamente dai nodi in coda di eliminazione.
		child.free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.07, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_exercise_panel = PanelContainer.new()
	_exercise_panel.anchor_left = 0.08
	_exercise_panel.anchor_top = 0.04
	_exercise_panel.anchor_right = 0.92
	_exercise_panel.anchor_bottom = 0.96
	_exercise_panel.custom_minimum_size = Vector2(640, 480)
	var is_exam := str(session.get("kind", "mission")) == "final_exam"
	_exercise_panel.add_theme_stylebox_override("panel", _exercise_panel_style(is_exam))
	add_child(_exercise_panel)
	# **Il riquadro dell'esercizio deve poter scorrere.** (8 agosto 2026)
	#
	# Segnalazione di gioco: «rispondendo correttamente alla domanda il programma
	# si blocca». Non si bloccava: il pulsante AVANTI finiva **sotto il bordo
	# dello schermo**, e da lì non si poteva più andare avanti — che per chi
	# gioca è la stessa cosa.
	#
	# La causa strutturale era qui: questa colonna stava dentro un PanelContainer
	# senza nessuno scorrimento. Con una domanda lunga, il tastierino numerico e
	# quattro pulsanti in fila, il contenuto superava l'altezza del riquadro e
	# quello che sporgeva non era raggiungibile in nessun modo. È la stessa causa
	# della segnalazione rimasta aperta sulle domande aperte («non permettono di
	# confermare la risposta»): stesso difetto, due sintomi.
	#
	# Adesso, se il contenuto non ci sta, si scorre. Una schermata che scorre è
	# un compromesso; una schermata da cui non si può uscire è un difetto.
	var box_scroll := ScrollContainer.new()
	box_scroll.name = "ExerciseContentScroll"
	box_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_exercise_panel.add_child(box_scroll)
	var box := VBoxContainer.new()
	box.name = "ExerciseContent"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	box_scroll.add_child(box)

	var heading := Label.new()
	heading.name = "ExerciseHeading"
	var transversal := bool(session.get("transversal", false))
	var heading_kind := "SFIDA DI NORA" if str(session.get("kind", "mission")) == "mission" else ("MISTERO DA RISOLVERE" if str(session.get("kind", "mission")) == "enigma" else "APPARATO · SFIDA FINALE")
	heading.text = "CUORE DEI PRIMI · SFIDA DELLE TRE CHIAVI" if transversal else "%s  ·  %s" % [heading_kind, str(session.get("subject", "matematica")).capitalize()]
	heading.add_theme_font_size_override("font_size", 19 if is_exam else 16)
	heading.add_theme_color_override("font_color", Color("f6c85f") if is_exam else Color("6be7d6"))
	box.add_child(heading)

	# Affordance didattica: le materie di ragionamento non hanno limite di tempo.
	# Comunicarlo esplicitamente riduce l'ansia da prestazione e invita a pensare.
	# (Nessuna sessione è cronometrata oggi; qui si dichiara solo la politica per
	# le materie di ragionamento — le fluency non mostrano la riga.)
	if str(session.get("pace", "reasoning")) == "reasoning" and not bool(session.get("timed", false)):
		var pace_hint := Label.new()
		pace_hint.text = "Senza limite di tempo · ragiona con calma"
		pace_hint.add_theme_font_size_override("font_size", 12)
		pace_hint.add_theme_color_override("font_color", Color(0.62, 0.86, 0.82, 0.85))
		box.add_child(pace_hint)

	if transversal:
		_convergence_display = FINAL_CONVERGENCE_DISPLAY.new()
		_convergence_display.name = "FinalConvergenceDisplay"
		_convergence_display.setup(Array(session.get("systems", [])), reduced_motion)
		box.add_child(_convergence_display)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color("f6c85f"))
	box.add_child(_status)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_prompt)

	_options_scroll = ScrollContainer.new()
	_options_scroll.name = "ExerciseOptionsScroll"
	_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_options_scroll.custom_minimum_size.y = 180
	box.add_child(_options_scroll)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_scroll.add_child(_options)

	_input = LineEdit.new()
	_input.placeholder_text = "Scrivi qui"
	_input.visible = false
	# Il tipo viene scelto per il nodo corrente: questo stesso campo serve anche
	# alle risposte testuali e non deve intrappolarle in una tastiera numerica.
	_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_input.text_submitted.connect(func(text): _answer(text))
	box.add_child(_input)
	_numpad = _build_numpad()
	box.add_child(_numpad)
	_input_submit = Button.new()
	_input_submit.name = "TextAnswerSubmit"
	_input_submit.text = "CONFERMA"
	_input_submit.visible = false
	_input_submit.custom_minimum_size = Vector2(0, 52)
	_input_submit.add_theme_font_size_override("font_size", 16)
	_input_submit.add_theme_color_override("font_color", Color("06272a"))
	_input_submit.add_theme_stylebox_override(
		"normal",
		_exercise_button_style(Color("6be7d6"), Color("d8fff8"))
	)
	_input_submit.pressed.connect(func(): _answer(_input.text))
	box.add_child(_input_submit)

	# **L'indizio, disponibile SUBITO.** (7 agosto 2026)
	#
	# Segnalazione di gioco: «le domande aperte non hanno indizi o aiuti». Era
	# vero: `SPIEGA CON NORA` compariva solo DOPO una risposta sbagliata, quindi
	# su una domanda aperta il bambino trovava un campo vuoto e nessun appiglio.
	# Nelle domande a scelta multipla le alternative sono già un aiuto — si
	# ragiona per esclusione; in una domanda aperta non c'è niente.
	#
	# L'indizio non dà la risposta: dà la sua FORMA — quante cifre, che lettera
	# iniziale, quanto è lunga. È lo stesso principio delle spiegazioni: si
	# insegna il metodo, non il risultato. E chi non ne ha bisogno non lo tocca.
	_hint_button = Button.new()
	_hint_button.name = "FreeAnswerHintButton"
	_hint_button.text = "INDIZIO"
	_hint_button.visible = false
	_hint_button.custom_minimum_size = Vector2(0, 48)
	_hint_button.add_theme_font_size_override("font_size", 15)
	_hint_button.pressed.connect(_mostra_indizio)
	box.add_child(_hint_button)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_feedback)

	_help_button = Button.new()
	_help_button.name = "ConceptHelpButton"
	_help_button.text = "SPIEGA CON NORA"
	_help_button.visible = false
	_help_button.custom_minimum_size = Vector2(0, 48)
	_help_button.add_theme_color_override("font_color", Color("06272a"))
	_help_button.add_theme_stylebox_override("normal", _exercise_button_style(Color("6be7d6"), Color("d8fff8")))
	_help_button.pressed.connect(_request_concept_help)
	box.add_child(_help_button)

	_next_button = Button.new()
	# Un nome, perché è il pulsante da cui dipende «si può proseguire»: senza,
	# `exercise_reachability_audit` non potrebbe verificare che sia raggiungibile.
	_next_button.name = "ExerciseNextButton"
	_next_button.text = "CONTINUA"
	_next_button.visible = false
	if is_instance_valid(_input_submit):
		_input_submit.visible = false
		_input_submit.disabled = false
	if is_instance_valid(_hint_button):
		_hint_button.visible = false
	_next_button.custom_minimum_size = Vector2(0, 48)
	_next_button.add_theme_font_size_override("font_size", 16)
	_next_button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.16, 0.32, 0.30, 0.98), Color(0.96, 0.78, 0.36, 0.72)))
	_next_button.pressed.connect(_advance)
	box.add_child(_next_button)

	_build_exit_row(box)

## L'uscita dalla prova.
##
## Fino al 4 agosto 2026 da un esercizio non si usciva: nessun pulsante, nessun
## `ui_cancel`. Bastava un campo che non si riempiva — ed è successo davvero, su
## tablet — perché il bambino restasse chiuso lì dentro senza via d'uscita. Un
## gioco che si studia non può avere stanze senza porta.
##
## Ma la porta ha un prezzo, e deve averlo: senza costo, uscire e rientrare
## diventa il modo più veloce di ripescare domande finché non capitano quelle
## facili, e la prova smette di misurare qualcosa. Il prezzo è dichiarato prima,
## in cifre, e la conferma è un secondo tocco: nessun bambino perde energia per
## un dito storto.
##
## Quello che il prezzo NON tocca è ciò che è stato imparato. Gli argomenti visti
## restano nel Codex anche se la prova non viene consegnata: il gioco non ha mai
## tolto sapere a nessuno, e non comincia qui.
func _build_exit_row(box: VBoxContainer) -> void:
	_exit_notice = Label.new()
	_exit_notice.name = "ExitNotice"
	_exit_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_exit_notice.visible = false
	_exit_notice.add_theme_font_size_override("font_size", 13)
	_exit_notice.add_theme_color_override("font_color", Color("f6c85f"))
	box.add_child(_exit_notice)

	var row := HBoxContainer.new()
	row.name = "ExitRow"
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	_exit_button = Button.new()
	_exit_button.name = "ExerciseExitButton"
	_exit_button.text = "ESCI DALLA PROVA"
	_exit_button.custom_minimum_size = Vector2(0, 48)
	_exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exit_button.add_theme_font_size_override("font_size", 14)
	_exit_button.add_theme_color_override("font_color", Color(0.78, 0.90, 0.88, 0.92))
	_exit_button.add_theme_stylebox_override(
		"normal", _exercise_button_style(Color(0.06, 0.14, 0.16, 0.85), Color(0.42, 0.70, 0.68, 0.35)))
	_exit_button.pressed.connect(_on_exit_pressed)
	row.add_child(_exit_button)

	_exit_stay_button = Button.new()
	_exit_stay_button.name = "ExerciseStayButton"
	_exit_stay_button.text = "RESTO"
	_exit_stay_button.visible = false
	_exit_stay_button.custom_minimum_size = Vector2(120, 48)
	_exit_stay_button.add_theme_font_size_override("font_size", 14)
	_exit_stay_button.add_theme_color_override("font_color", Color("06272a"))
	_exit_stay_button.add_theme_stylebox_override(
		"normal", _exercise_button_style(Color("6be7d6"), Color("d8fff8")))
	_exit_stay_button.pressed.connect(_disarm_exit)
	row.add_child(_exit_stay_button)

## Primo tocco: chiede conferma e dice il prezzo. Secondo tocco: esce.
func _on_exit_pressed() -> void:
	if not _abandon_armed:
		_abandon_armed = true
		_exit_button.text = "ESCO DAVVERO"
		_exit_stay_button.visible = true
		_exit_notice.visible = true
		_exit_notice.text = (
			"Uscire costa %d energia, e l'energia di questa prova non viene consegnata. "
			+ "Quello che hai già imparato resta nel Codex."
		) % _abandon_cost
		return
	_abandon()

func _disarm_exit() -> void:
	_abandon_armed = false
	if is_instance_valid(_exit_button):
		_exit_button.text = "ESCI DALLA PROVA"
	if is_instance_valid(_exit_stay_button):
		_exit_stay_button.visible = false
	if is_instance_valid(_exit_notice):
		_exit_notice.visible = false

func _exercise_panel_style(is_exam: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent := _subject_accent()
	style.bg_color = Color(0.055, 0.075, 0.10, 0.98) if is_exam else Color(0.018, 0.055, 0.07, 0.97).lerp(Color(accent, 0.97), 0.075)
	style.border_color = Color.WHITE if high_contrast else Color("f6c85f") if is_exam else Color(accent, 0.62)
	style.set_border_width_all(4 if high_contrast else 3 if is_exam else 2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	return style

func _subject_accent() -> Color:
	var colors := {
		"matematica": Color("6be7d6"), "italiano": Color("e9a86d"),
		"coding": Color("8fa7ff"), "inglese": Color("72c9ff"),
		"fisica": Color("a2d8ff"), "musica": Color("d7a0ff"),
		"latino": Color("d4b17a"), "elettronica": Color("79e7ff"),
		"geografia": Color("7fd19b"), "scienze": Color("91dc72"),
		"storia": Color("f2c96d"), "logica": Color("b7a2ff"),
	}
	return colors.get(str(session.get("subject", "matematica")).to_lower(), Color("6be7d6"))

func _apply_format_layout(format: String) -> void:
	if not is_instance_valid(_exercise_panel) or not is_instance_valid(_options_scroll):
		return
	var compact := format in ["multiple_choice", "matching", "classification"]
	if bool(session.get("transversal", false)):
		compact = false
	# Lo scorrimento occupa tutto: è un minigioco di reazione, e un riquadro
	# piccolo con due lati stretti non si colpisce di slancio.
	if format == "swipe":
		_exercise_panel.anchor_top = 0.0
		_exercise_panel.anchor_bottom = 1.0
		_exercise_panel.custom_minimum_size.y = 0.0
		_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		return
	_exercise_panel.anchor_top = 0.06 if compact else 0.04
	_exercise_panel.anchor_bottom = 0.74 if compact else 0.96
	_exercise_panel.custom_minimum_size.y = 400.0 if compact else 480.0
	# Lo scroll deve continuare a ricevere l'altezza residua: matching e
	# classificazione includono il CTA verifica nello stesso contenitore.
	_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# **Un contenitore vuoto non occupa spazio.** (8 agosto 2026)
	#
	# Nelle risposte numeriche e in quelle scritte l'interazione non vive qui —
	# il campo, il tastierino e il pulsante di conferma sono fratelli di questo
	# riquadro, non figli. Ma il riquadro restava comunque espanso e con 180 px
	# di minimo: si prendeva tutta l'altezza avanzata pur essendo **vuoto**, e
	# spingeva tastierino e pulsanti oltre il bordo dello schermo.
	#
	# Si vedeva a occhio nudo — un buco di seicento pixel fra la domanda e il
	# tastierino — ed è la causa diretta della segnalazione «il programma si
	# blocca»: non si bloccava, AVANTI era fuori schermo.
	if format in ["numeric_input", "short_answer", "free_text"]:
		_options_scroll.size_flags_vertical = Control.SIZE_FILL
		_options_scroll.custom_minimum_size.y = 0.0
	else:
		_options_scroll.custom_minimum_size.y = 180.0

## Dieci cifre, il segno meno, la virgola e la cancellazione. Niente di più:
## le risposte numeriche del gioco sono interi, decimali o negativi.
##
## I tasti sono da 56 px perché sotto i 44 un dito di bambino sbaglia bersaglio,
## e il tasto di cancellazione sta lontano dallo zero per lo stesso motivo.
func _build_numpad() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "NumericPad"
	grid.columns = 5
	grid.visible = false
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for key in ["7", "8", "9", "−", "C", "4", "5", "6", ",", "←", "1", "2", "3", "0", "OK"]:
		var button := Button.new()
		button.name = "Numpad_%s" % key
		button.text = key
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color("06272a"))
		var fill := Color("6be7d6") if key == "OK" else Color("bfeee6")
		button.add_theme_stylebox_override("normal", _exercise_button_style(fill, Color("d8fff8")))
		button.pressed.connect(_numpad_press.bind(key))
		grid.add_child(button)
	return grid

func _numpad_press(key: String) -> void:
	if not is_instance_valid(_input):
		return
	match key:
		"OK":
			_answer(_input.text)
			return
		"C":
			_input.text = ""
		"←":
			_input.text = _input.text.substr(0, maxi(0, _input.text.length() - 1))
		"−":
			# Il meno solo in testa, e come interruttore: premerlo due volte lo
			# toglie invece di lasciare «−−5».
			_input.text = _input.text.substr(1) if _input.text.begins_with("-") else "-" + _input.text
		",":
			if not _input.text.contains(","):
				_input.text += ","
		_:
			_input.text += key
	_input.caret_column = _input.text.length()

func _exercise_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.WHITE if high_contrast else border
	style.set_border_width_all(3 if high_contrast else 1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	return style

## Primo contatto e ripasso non sono un'altra domanda: una scheda modale copre
## integralmente l'esercizio e lo rende raggiungibile soltanto dopo che lo
## studente ha letto la spiegazione. Il layout è scrollabile e il CTA è alto
## 56 px, quindi resta usabile anche su tablet.
## **Una spiegazione per ogni argomento nuovo, davanti alla sua domanda.**
## (7 agosto 2026)
##
## Prima questa scheda compariva una volta sola, all'apertura della sessione, e
## spiegava l'argomento del PRIMO nodo. Gli altri due arrivavano nudi: misurato,
## il 60,6% delle domande cadeva su un argomento mai spiegato li' dentro.
##
## Adesso la lezione viaggia sul nodo e la scheda compare **subito prima della
## domanda a cui serve**. Metterle tutte in testa sarebbe stato piu' semplice da
## scrivere e peggio da leggere: tre spiegazioni di fila si leggono come un muro
## e non se ne ricorda nessuna. Una spiegazione serve quando serve.
func _show_teaching_overlay() -> void:
	var lesson: Dictionary = session.get("teachingLesson", {})
	var moment := str(session.get("teachingMoment", "none"))
	var linea := str(session.get("teachingLine", ""))
	if _index >= 0 and _index < _nodes.size():
		var nodo: Dictionary = _nodes[_index]
		if nodo.has("teachingLesson"):
			lesson = nodo.get("teachingLesson", {})
			moment = str(nodo.get("teachingMoment", "none"))
			linea = str(nodo.get("teachingLine", ""))
		elif _index > 0:
			# Nodo senza lezione oltre il primo: niente da mostrare. Senza questo
			# ramo il nodo 2 e 3 riproporrebbero la scheda del nodo 1, che e' il
			# difetto opposto e altrettanto fastidioso.
			return
	if lesson.is_empty() or moment == "none":
		return
	if _lezioni_mostrate.has(str(lesson.get("topic", ""))):
		return
	_lezioni_mostrate[str(lesson.get("topic", ""))] = true
	var overlay := Control.new()
	overlay.name = "TeachingOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var scrim := ColorRect.new()
	scrim.color = Color(0.008, 0.025, 0.035, 0.96)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(scrim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.07
	panel.anchor_top = 0.04
	panel.anchor_right = 0.93
	panel.anchor_bottom = 0.96
	panel.add_theme_stylebox_override("panel", _exercise_panel_style(false))
	overlay.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "RIPASSO MIRATO CON NORA" if moment == "re_teach" else "NUOVO CONCETTO · NORA SPIEGA"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color("6be7d6"))
	box.add_child(eyebrow)
	_add_teaching_text(box, linea, Color("f6c85f"), 20)
	_add_teaching_text(box, str(lesson.get("intro", "")), Color("e7fffb"), 17)

	var example: Dictionary = lesson.get("workedExample", {})
	var example_text := str(example.get("prompt", "")).strip_edges()
	var answer := str(example.get("answer", "")).strip_edges()
	var explanation := str(example.get("explanation", "")).strip_edges()
	if answer != "":
		example_text += "\n\nRisultato: %s" % answer
	if explanation != "":
		example_text += "\nPerché: %s" % explanation
	_add_teaching_section(box, "ESEMPIO SVOLTO", example_text)
	_add_teaching_section(box, "METODO DI NORA", str(lesson.get("strategy", "")))

	var watch_out: Dictionary = lesson.get("watchOut", {})
	var warning := str(watch_out.get("wrong", "")).strip_edges()
	var why := str(watch_out.get("why", "")).strip_edges()
	if why != "":
		warning += "\nPerché non funziona: %s" % why
	if warning != "":
		_add_teaching_section(box, "ATTENZIONE A…", warning)

	var begin := Button.new()
	begin.name = "TeachingStartButton"
	begin.text = "HO CAPITO · INIZIA LA PROVA"
	begin.custom_minimum_size = Vector2(0, 56)
	begin.add_theme_font_size_override("font_size", 17)
	begin.add_theme_stylebox_override("normal", _exercise_button_style(Color("147d75"), Color("a7fff2")))
	begin.pressed.connect(_dismiss_teaching_overlay.bind(overlay))
	box.add_child(begin)
	begin.call_deferred("grab_focus")

func _add_teaching_section(box: VBoxContainer, title: String, body: String) -> void:
	if body.strip_edges() == "":
		return
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color("6be7d6"))
	box.add_child(title_label)
	_add_teaching_text(box, body, Color("e7f4f2"), 16)

func _add_teaching_text(box: VBoxContainer, value: String, color: Color, font_size: int) -> void:
	if value.strip_edges() == "":
		return
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)

func _dismiss_teaching_overlay(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	if is_instance_valid(_input) and _input.visible:
		_input.grab_focus()

## Vero se la risposta attesa è un numero: intero, decimale (virgola o punto) o
## negativo. Tutto il resto è testo e vuole la tastiera, non il tastierino.
func _answer_is_numeric(answer: String) -> bool:
	var trimmed := answer.strip_edges()
	if trimmed == "":
		return false
	return RegEx.create_from_string("^-?[0-9]+([.,][0-9]+)?$").search(trimmed) != null

func _show_current() -> void:
	_answered = false
	_feedback.text = ""
	_next_button.visible = false
	if is_instance_valid(_numpad):
		_numpad.visible = false
	if is_instance_valid(_help_button):
		# **La pagina del manuale e' raggiungibile PRIMA di sbagliare.**
		# (7 agosto 2026)
		#
		# Richiesta del committente: le spiegazioni del manuale devono essere
		# «linkate direttamente agli esercizi corrispondenti». Il collegamento
		# c'era gia' — il pulsante apre il manuale sull'argomento di QUESTA
		# domanda — ma compariva solo dopo una risposta sbagliata: era un
		# premio di consolazione, non uno strumento.
		#
		# Un bambino che non sa una cosa deve poterla andare a leggere mentre la
		# sta guardando, non dopo aver preso l'errore. In esame no: li' la prova
		# misura quello che si sa.
		_help_button.visible = str(session.get("kind", "mission")) != "final_exam"
	_mg_expected = 0
	_mg_selected_left = -1
	_mg_matched = 0
	_mg_buttons = []
	_mg_left_buttons = []
	_mg_right_buttons = []
	_ordering_state = []
	_ordering_slots = []
	_matching_connections = []
	_matching_canvas = null
	_classification_state = {}
	_classification_buttons = {}
	_classification_selected = ""
	_machine_state = []
	_machine_slots = []
	_machine_buttons = {}
	_machine_readout = null
	_machine_running = false
	_sample_tests_run = []
	_sample_test_buttons = {}
	_sample_candidate_buttons = {}
	_sample_selected = ""
	_sample_log = null
	_sample_capsule = null
	_sample_capsule_label = null
	_verb_selection = {"time": "", "mood": "", "form": ""}
	_verb_buttons = {}
	_verb_preview = null
	_verb_scanner = null
	_verb_running = false
	_visual_selected = ""
	_visual_buttons = {}
	_visual_diagram = null
	_cycle_sequence = []
	_clues_revealed = 0
	_clue_button = null
	_swipe_index = 0
	_swipe_streak = 0
	_swipe_best = 0
	_swipe_score = 0
	_swipe_right = 0
	_swipe_seconds = 0.0
	_swipe_item = {}
	set_process(false)
	if _index >= _nodes.size():
		_finish()
		return
	var item: Dictionary = _nodes[_index]
	_refresh_status()
	_prompt.text = str(item.get("prompt", ""))
	for child in _options.get_children():
		child.queue_free()
	var fmt := str(item.get("format", "multiple_choice"))
	_apply_format_layout(fmt)
	match fmt:
		"machine_path":
			_input.visible = false
			_build_machine_path(item)
		"mystery_sample":
			_input.visible = false
			_build_mystery_sample(item)
		"verb_decoder":
			_input.visible = false
			_build_verb_decoder(item)
		"ordering":
			_input.visible = false
			_build_ordering(item)
		"matching":
			_input.visible = false
			_build_matching(item)
		"classification":
			_input.visible = false
			_build_classification(item)
		"hotspot", "graph", "circuit", "notation", "map", "number_line", "balance", "timeline", "compose", "trace", "clue":
			_input.visible = false
			_build_visual_selection(item, fmt)
		"cycle":
			_input.visible = false
			_build_cycle(item)
		"code_debug":
			_input.visible = false
			_build_code_debug(item)
		"swipe":
			_input.visible = false
			_build_swipe(item)
		"multiple_choice":
			_input.visible = false
			for option in item.get("options", []):
				var button := Button.new()
				button.text = str(option)
				button.custom_minimum_size = Vector2(0, 48)
				button.add_theme_font_size_override("font_size", 16)
				button.add_theme_color_override("font_color", Color("e7fff8"))
				button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
				button.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
				button.add_theme_stylebox_override("pressed", _exercise_button_style(Color(0.18, 0.40, 0.34, 1.0), Color(0.96, 0.78, 0.36, 0.85)))
				button.pressed.connect(_answer.bind(str(option)))
				_options.add_child(button)
		_:
			_input.visible = true
			_input.text = ""
			_input.editable = true
			_input_submit.visible = true
			_hint_level = 0
			if is_instance_valid(_hint_button):
				# In esame no: lì la prova deve misurare quello che si sa.
				_hint_button.visible = str(session.get("kind", "mission")) != "final_exam"
				_hint_button.disabled = false
				_hint_button.text = "INDIZIO"
			# Il tastierino solo dove la risposta è un numero: per una parola
			# sarebbe d'intralcio, e lì la tastiera di sistema serve davvero.
			var numeric_answer := _answer_is_numeric(str(item.get("answer", "")))
			_input.virtual_keyboard_type = (
				LineEdit.KEYBOARD_TYPE_NUMBER
				if numeric_answer else LineEdit.KEYBOARD_TYPE_DEFAULT)
			if is_instance_valid(_numpad):
				_numpad.visible = numeric_answer
			if is_inside_tree():
				_input.grab_focus()

func _refresh_status() -> void:
	if is_instance_valid(_status):
		if bool(session.get("transversal", false)) and _index < _nodes.size():
			var system := str((_nodes[_index] as Dictionary).get("system", "sintesi")).replace("_", " ").capitalize()
			_status.text = "Parte %d/%d · %s   ·   Stabilità %d" % [_index + 1, _nodes.size(), system, _shields]
		else:
			_status.text = "Tappa %d/%d   ·   Scudi %d" % [_index + 1, _nodes.size(), _shields]

func _answer(given: String) -> void:
	if _answered:
		return
	var item: Dictionary = _nodes[_index]
	var is_correct := ExerciseInteraction.answer_accepted(given, item)
	if not is_correct:
		_spend_shield()
		_register_wrong_attempt(item)
	_score_current(is_correct, item)

# --- IL PONTE DELLE TRASFORMAZIONI -----------------------------------------
# La matematica è una macchina da montare: ogni passaggio usa il risultato del
# precedente e la sfera mostra subito che cosa è successo. Non esiste una
# risposta da scegliere; il bambino costruisce un percorso che funziona.
func _build_machine_path(item: Dictionary) -> void:
	var title := Label.new()
	title.text = str(item.get("title", "Il ponte delle trasformazioni")).to_upper()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("7ad7ff"))
	_options.add_child(title)

	var instruction := Label.new()
	instruction.text = "Scegli le macchine e montale da sinistra a destra. Puoi spostarle prima di avviare la sfera."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)

	var track := HFlowContainer.new()
	track.name = "MachinePathTrack"
	track.add_theme_constant_override("h_separation", 8)
	track.add_theme_constant_override("v_separation", 8)
	_options.add_child(track)

	var start_label := Label.new()
	start_label.text = "PARTENZA\n%d" % int(item.get("start", 0))
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.custom_minimum_size = Vector2(112, 64)
	start_label.add_theme_font_size_override("font_size", 17)
	start_label.add_theme_color_override("font_color", Color("f6c85f"))
	track.add_child(start_label)

	var count := int(item.get("slotCount", 2))
	_machine_state.resize(count)
	_machine_state.fill("")
	for slot_index in count:
		var slot := EXERCISE_DROP_BUTTON.new()
		slot.name = "MachineSlot_%02d" % slot_index
		slot.text = "%d · macchina" % (slot_index + 1)
		slot.custom_minimum_size = Vector2(138, 64)
		slot.add_theme_font_size_override("font_size", 15)
		slot.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.04, 0.13, 0.16, 0.96), Color("527980")))
		slot.call("configure_target", str(slot_index), "machine_path")
		slot.connect("item_dropped", _machine_drop.bind(item))
		slot.pressed.connect(_machine_clear_slot.bind(slot_index, item))
		slot.tooltip_text = "Posto %d del percorso. Tocca per liberarlo." % (slot_index + 1)
		track.add_child(slot)
		_machine_slots.append(slot)

	var target_label := Label.new()
	target_label.text = "TRAGUARDO\n%d" % int(item.get("target", 0))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.custom_minimum_size = Vector2(112, 64)
	target_label.add_theme_font_size_override("font_size", 17)
	target_label.add_theme_color_override("font_color", Color("8ff6d2"))
	track.add_child(target_label)

	_machine_readout = Label.new()
	_machine_readout.name = "MachinePathReadout"
	_machine_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_machine_readout.add_theme_font_size_override("font_size", 16)
	_machine_readout.add_theme_color_override("font_color", Color("d9fff4"))
	_options.add_child(_machine_readout)

	var shelf := HFlowContainer.new()
	shelf.name = "MachineShelf"
	shelf.add_theme_constant_override("h_separation", 8)
	shelf.add_theme_constant_override("v_separation", 8)
	_options.add_child(shelf)
	for raw in Array(item.get("machines", [])):
		var machine := raw as Dictionary
		var id := str(machine.get("id", ""))
		var button := EXERCISE_DRAG_BUTTON.new()
		button.name = "NumberMachine_%s" % id
		button.text = str(machine.get("label", ""))
		button.custom_minimum_size = Vector2(112, 54)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color("e7fff8"))
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.96), Color("6be7d6")))
		button.call("configure", id, "machine_path")
		button.connect("drag_started", _on_drag_started.bind(button))
		button.pressed.connect(_machine_click.bind(id, item))
		button.tooltip_text = "Macchina %s. Trascina o tocca per montarla." % button.text
		shelf.add_child(button)
		_machine_buttons[id] = button

	_refresh_machine_path(item)
	_add_interaction_actions(
		_machine_clear_last.bind(item), _machine_submit.bind(item),
		"SMONTA L'ULTIMA", "AVVIA LA SFERA")

func _machine_click(id: String, item: Dictionary) -> void:
	if _answered or _machine_running:
		return
	var empty := _machine_state.find("")
	if empty < 0:
		_flash_feedback("Il percorso è pieno. Tocca una macchina montata per liberare il posto.")
		return
	_machine_place(id, empty, item)

func _machine_drop(source_id: String, target_id: String, item: Dictionary) -> void:
	_machine_place(source_id, int(target_id), item)

func _machine_place(id: String, slot_index: int, item: Dictionary) -> void:
	if _answered or _machine_running or not _machine_buttons.has(id):
		return
	if slot_index < 0 or slot_index >= _machine_state.size():
		return
	var previous := _machine_state.find(id)
	if previous >= 0:
		_machine_state[previous] = ""
	var displaced := str(_machine_state[slot_index])
	if displaced != "" and _machine_buttons.has(displaced):
		(_machine_buttons[displaced] as Button).disabled = false
	_machine_state[slot_index] = id
	(_machine_buttons[id] as Button).disabled = true
	_refresh_machine_path(item)
	_causal_feedback("snap", _machine_slots[slot_index], 0.98 + float(slot_index) * 0.05)

func _machine_clear_slot(slot_index: int, item: Dictionary) -> void:
	if _answered or _machine_running or slot_index < 0 or slot_index >= _machine_state.size():
		return
	var id := str(_machine_state[slot_index])
	if id == "":
		return
	_machine_state[slot_index] = ""
	if _machine_buttons.has(id):
		(_machine_buttons[id] as Button).disabled = false
	_refresh_machine_path(item)
	_causal_feedback("cancel", _machine_slots[slot_index], 0.94)

func _machine_clear_last(item: Dictionary) -> void:
	for index in range(_machine_state.size() - 1, -1, -1):
		if str(_machine_state[index]) != "":
			_machine_clear_slot(index, item)
			return
	_flash_feedback("Il percorso è già vuoto.")

func _machine_by_id(item: Dictionary, id: String) -> Dictionary:
	for raw in Array(item.get("machines", [])):
		var machine := raw as Dictionary
		if str(machine.get("id", "")) == id:
			return machine
	return {}

func _refresh_machine_path(item: Dictionary) -> void:
	var used: Array = []
	for index in _machine_state.size():
		var id := str(_machine_state[index])
		var slot := _machine_slots[index] as Button
		if id == "":
			slot.text = "%d · macchina" % (index + 1)
			continue
		used.append(id)
		var machine := _machine_by_id(item, id)
		slot.text = "%d · %s" % [index + 1, str(machine.get("label", ""))]
	var result := ExerciseInteraction.evaluate_machine_path(
		int(item.get("start", 0)), used, Array(item.get("machines", [])))
	var values: Array = result.get("values", [])
	var trail: Array = []
	for value in values:
		trail.append(str(value))
	var suffix := ""
	if not bool(result.get("ok", false)):
		suffix = " · Si ferma: %s" % str(result.get("reason", ""))
	elif used.size() < _machine_state.size():
		suffix = " · Mancano %d macchine" % (_machine_state.size() - used.size())
	_machine_readout.text = "Percorso: %s%s" % ["  →  ".join(PackedStringArray(trail)), suffix]

func _machine_submit(item: Dictionary) -> void:
	if _machine_running or _answered:
		return
	if _machine_state.has(""):
		_flash_feedback("Monta tutte le macchine prima di far partire la sfera.")
		return
	var result := ExerciseInteraction.evaluate_machine_path(
		int(item.get("start", 0)), _machine_state, Array(item.get("machines", [])))
	_machine_running = true
	_machine_set_enabled(false)
	var tween := create_tween()
	for slot in _machine_slots:
		tween.tween_callback(_causal_feedback.bind("connect", slot as Control, 1.02))
		if not reduced_motion:
			tween.tween_interval(0.16)
	tween.tween_callback(_finish_machine_run.bind(item, result))

func _finish_machine_run(item: Dictionary, result: Dictionary) -> void:
	_machine_running = false
	var reached := bool(result.get("ok", false)) and int(result.get("value", 0)) == int(item.get("target", 0))
	if reached:
		_machine_readout.text += " · Il ponte si apre!"
		_score_current(true, item)
		return
	var message := ""
	if not bool(result.get("ok", false)):
		message = "La sfera si ferma: %s Cambia una macchina o il suo posto." % str(result.get("reason", ""))
	else:
		message = "La sfera arriva a %d, ma il ponte si apre a %d. Cambia una macchina o il suo posto." % [
			int(result.get("value", 0)), int(item.get("target", 0))]
	_retryable_result(false, item, message)
	if not _answered:
		_machine_set_enabled(true)

func _machine_set_enabled(enabled: bool) -> void:
	for index in _machine_slots.size():
		(_machine_slots[index] as Button).disabled = not enabled
	for id in _machine_buttons.keys():
		(_machine_buttons[id] as Button).disabled = not enabled or _machine_state.has(str(id))

# --- IL CAMPIONE SENZA NOME -----------------------------------------------
# Non si sceglie una risposta al buio: ogni pulsante produce un'osservazione
# reale, conservata nel quaderno. L'identificazione arriva solo dopo gli
# esperimenti e può essere corretta confrontando ciò che non torna.
func _build_mystery_sample(item: Dictionary) -> void:
	var title := Label.new()
	title.text = str(item.get("title", "Il campione senza nome")).to_upper()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("9fe58c"))
	_options.add_child(title)

	var bit_line := Label.new()
	bit_line.text = "BIT: Il campione è sigillato. Io muovo gli strumenti; tu decidi quali prove servono."
	bit_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bit_line.add_theme_color_override("font_color", Color("b8c8ff"))
	_options.add_child(bit_line)

	_sample_capsule = PanelContainer.new()
	_sample_capsule.name = "MysterySampleCapsule"
	_sample_capsule.custom_minimum_size = Vector2(0, 90)
	_sample_capsule.add_theme_stylebox_override("panel", _exercise_button_style(Color(0.05, 0.13, 0.12, 0.98), Color("79dba1")))
	_options.add_child(_sample_capsule)
	_sample_capsule_label = Label.new()
	_sample_capsule_label.text = "CAMPIONE SIGILLATO\n?"
	_sample_capsule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sample_capsule_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sample_capsule_label.add_theme_font_size_override("font_size", 19)
	_sample_capsule_label.add_theme_color_override("font_color", Color("e7fff0"))
	_sample_capsule.add_child(_sample_capsule_label)

	var tools_heading := Label.new()
	tools_heading.text = "STRUMENTI"
	tools_heading.add_theme_font_size_override("font_size", 14)
	tools_heading.add_theme_color_override("font_color", Color("f6c85f"))
	_options.add_child(tools_heading)
	var tools := HFlowContainer.new()
	tools.name = "MysterySampleTools"
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	_options.add_child(tools)
	for raw in Array(item.get("tests", [])):
		var test := raw as Dictionary
		var id := str(test.get("id", ""))
		var button := Button.new()
		button.name = "SampleTest_%s" % id
		button.text = "%s  %s" % [str(test.get("glyph", "◆")), str(test.get("label", "Osserva"))]
		button.custom_minimum_size = Vector2(190, 50)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.20, 0.16, 0.98), Color("79dba1")))
		button.pressed.connect(_sample_run_test.bind(id, item))
		tools.add_child(button)
		_sample_test_buttons[id] = button

	_sample_log = Label.new()
	_sample_log.name = "MysterySampleLog"
	_sample_log.text = "QUADERNO DI BIT · nessuna osservazione"
	_sample_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sample_log.add_theme_font_size_override("font_size", 14)
	_sample_log.add_theme_color_override("font_color", Color("d9efe5"))
	_options.add_child(_sample_log)

	var candidates_heading := Label.new()
	candidates_heading.text = "QUALE MATERIALE SPIEGA TUTTI GLI INDIZI?"
	candidates_heading.add_theme_font_size_override("font_size", 14)
	candidates_heading.add_theme_color_override("font_color", Color("f6c85f"))
	_options.add_child(candidates_heading)
	var candidates := HFlowContainer.new()
	candidates.name = "MysterySampleCandidates"
	candidates.add_theme_constant_override("h_separation", 8)
	candidates.add_theme_constant_override("v_separation", 8)
	_options.add_child(candidates)
	for raw in Array(item.get("samples", [])):
		var sample := raw as Dictionary
		var id := str(sample.get("id", ""))
		var button := Button.new()
		button.name = "SampleCandidate_%s" % id
		button.text = str(sample.get("name", id)).to_upper()
		button.custom_minimum_size = Vector2(125, 46)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.13, 0.16, 0.98), Color("657f85")))
		button.pressed.connect(_sample_select_candidate.bind(id))
		candidates.add_child(button)
		_sample_candidate_buttons[id] = button

	var submit := Button.new()
	submit.name = "MysterySampleSubmit"
	submit.text = "REGISTRA LA SCOPERTA"
	submit.custom_minimum_size = Vector2(0, 50)
	submit.add_theme_font_size_override("font_size", 15)
	submit.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.14, 0.36, 0.25, 1.0), Color("9ff0bd")))
	submit.pressed.connect(_sample_submit.bind(item))
	_options.add_child(submit)

func _sample_run_test(test_id: String, item: Dictionary) -> void:
	if _answered or _sample_tests_run.has(test_id) or not _sample_test_buttons.has(test_id):
		return
	_sample_tests_run.append(test_id)
	var button := _sample_test_buttons[test_id] as Button
	button.disabled = true
	button.text = "✓  %s" % button.text.get_slice("  ", 1)
	var observation := ExerciseInteraction.mystery_sample_result(item, test_id)
	var test := _sample_test_by_id(item, test_id)
	_sample_capsule_label.text = "%s\n%s" % [str(test.get("short", "PROVA")), str(test.get("glyph", "◆"))]
	_refresh_sample_log(item)
	_flash_feedback(observation)
	_causal_feedback("connect", _sample_capsule, 0.98 + float(_sample_tests_run.size()) * 0.05)

func _sample_test_by_id(item: Dictionary, test_id: String) -> Dictionary:
	for raw in Array(item.get("tests", [])):
		var test := raw as Dictionary
		if str(test.get("id", "")) == test_id:
			return test
	return {}

func _refresh_sample_log(item: Dictionary) -> void:
	var rows: Array = []
	for test_id in _sample_tests_run:
		var test := _sample_test_by_id(item, str(test_id))
		rows.append("• %s — %s" % [str(test.get("short", "PROVA")), ExerciseInteraction.mystery_sample_result(item, str(test_id))])
	_sample_log.text = "QUADERNO DI BIT · %d/%d prove\n%s" % [
		_sample_tests_run.size(), Array(item.get("tests", [])).size(),
		"\n".join(PackedStringArray(rows)),
	]

func _sample_select_candidate(sample_id: String) -> void:
	if _answered:
		return
	_sample_selected = sample_id
	for id in _sample_candidate_buttons.keys():
		(_sample_candidate_buttons[id] as Button).modulate = Color("f6c85f") if str(id) == sample_id else Color.WHITE
	_causal_feedback("select", _sample_candidate_buttons[sample_id] as Control, 1.02)

func _sample_submit(item: Dictionary) -> void:
	if _answered:
		return
	var needed := int(item.get("minTests", 2))
	if _sample_tests_run.size() < needed:
		_flash_feedback("Servono almeno %d esperimenti prima di registrare una scoperta." % needed)
		return
	if _sample_selected == "":
		_flash_feedback("Scegli il materiale che spiega tutte le osservazioni.")
		return
	if _sample_selected == str(item.get("answer", "")):
		var name := _sample_name_by_id(item, _sample_selected)
		_sample_capsule_label.text = "CAMPIONE IDENTIFICATO\n%s" % name.to_upper()
		_causal_feedback("connect", _sample_capsule, 1.12)
		_score_current(true, item)
		return
	var mismatch := _sample_first_mismatch(item, _sample_selected)
	var message := (
		"L'ipotesi non spiega la prova %s. Confronta quell'osservazione e prova un altro materiale." % mismatch
		if mismatch != ""
		else "Gli indizi raccolti non bastano a sostenere questa ipotesi. Prova un altro strumento.")
	_retryable_result(false, item, message)
	if not _answered:
		_sample_selected = ""
		for button in _sample_candidate_buttons.values():
			(button as Button).modulate = Color.WHITE

func _sample_first_mismatch(item: Dictionary, candidate_id: String) -> String:
	var results := item.get("results", {}) as Dictionary
	var candidate_results := results.get(candidate_id, {}) as Dictionary
	for test_id in _sample_tests_run:
		if str(candidate_results.get(test_id, "")) != ExerciseInteraction.mystery_sample_result(item, str(test_id)):
			return str(_sample_test_by_id(item, str(test_id)).get("short", ""))
	return ""

func _sample_name_by_id(item: Dictionary, sample_id: String) -> String:
	for raw in Array(item.get("samples", [])):
		var sample := raw as Dictionary
		if str(sample.get("id", "")) == sample_id:
			return str(sample.get("name", sample_id))
	return sample_id

# --- IL MESSAGGIO FUORI TEMPO ----------------------------------------------
# Tre ghiere rendono visibile la grammatica nascosta nella frase. Il giocatore
# non sceglie soltanto una parola: deve prima dichiarare quando accade l'azione
# e con quale intenzione viene raccontata.
func _build_verb_decoder(item: Dictionary) -> void:
	var title := Label.new()
	title.text = str(item.get("title", "Il messaggio fuori tempo")).to_upper()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("f0b57b"))
	_options.add_child(title)

	var nora := Label.new()
	nora.text = "NORA: La frase non è rotta a caso. Il verbo conserva tre tracce: quando, intenzione e forma."
	nora.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nora.add_theme_color_override("font_color", Color("b8c8ff"))
	_options.add_child(nora)

	var evidence := HFlowContainer.new()
	evidence.name = "VerbEvidence"
	evidence.add_theme_constant_override("h_separation", 8)
	evidence.add_theme_constant_override("v_separation", 6)
	_options.add_child(evidence)
	for clue in Array(item.get("clues", [])):
		var chip := Label.new()
		chip.text = "  INDIZIO · %s  " % str(clue)
		chip.add_theme_font_size_override("font_size", 14)
		chip.add_theme_color_override("font_color", Color("f6c85f"))
		evidence.add_child(chip)

	_verb_preview = Label.new()
	_verb_preview.name = "VerbMessagePreview"
	_verb_preview.custom_minimum_size = Vector2(0, 72)
	_verb_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verb_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_verb_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_verb_preview.add_theme_font_size_override("font_size", 20)
	_verb_preview.add_theme_color_override("font_color", Color("fff0df"))
	_options.add_child(_verb_preview)

	_verb_scanner = ColorRect.new()
	_verb_scanner.name = "VerbDecoderScanner"
	_verb_scanner.custom_minimum_size = Vector2(0, 5)
	_verb_scanner.color = Color("f0b57b")
	_verb_scanner.modulate.a = 0.28
	_options.add_child(_verb_scanner)

	_build_verb_axis(item, "time", "1 · QUANDO ACCADE?", Array(item.get("timeChoices", [])))
	_build_verb_axis(item, "mood", "2 · COME VIENE PRESENTATA?", Array(item.get("moodChoices", [])))
	_build_verb_axis(item, "form", "3 · QUALE FORMA COMPLETA LA FRASE?", Array(item.get("forms", [])))
	_refresh_verb_decoder(item)
	_add_interaction_actions(
		_verb_clear.bind(item), _verb_submit.bind(item),
		"AZZERA LE GHIERE", "APRI IL MESSAGGIO")

func _build_verb_axis(item: Dictionary, axis: String, heading: String, entries: Array) -> void:
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("f6c85f"))
	_options.add_child(label)
	var row := HFlowContainer.new()
	row.name = "VerbAxis_%s" % axis
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	_options.add_child(row)
	for raw in entries:
		var entry := raw as Dictionary
		var id := str(entry.get("id", ""))
		var button := Button.new()
		button.name = "VerbChoice_%s_%s" % [axis, id]
		button.text = str(entry.get("label", id))
		button.custom_minimum_size = Vector2(170 if axis == "mood" else 135, 48)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color("e7fff8"))
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.17, 0.20, 0.98), Color("6d858d")))
		button.pressed.connect(_verb_select.bind(axis, id, item))
		row.add_child(button)
		_verb_buttons["%s:%s" % [axis, id]] = button

func _verb_select(axis: String, id: String, item: Dictionary) -> void:
	if _answered or _verb_running:
		return
	_verb_selection[axis] = id
	for key in _verb_buttons.keys():
		if str(key).begins_with("%s:" % axis):
			var button := _verb_buttons[key] as Button
			button.modulate = Color("f6c85f") if str(key) == "%s:%s" % [axis, id] else Color.WHITE
	_refresh_verb_decoder(item)
	_causal_feedback("snap", _verb_buttons["%s:%s" % [axis, id]] as Control, 1.02)

func _verb_clear(item: Dictionary) -> void:
	if _answered or _verb_running:
		return
	_verb_selection = {"time": "", "mood": "", "form": ""}
	for button in _verb_buttons.values():
		(button as Button).modulate = Color.WHITE
	_refresh_verb_decoder(item)
	_causal_feedback("cancel", _verb_scanner, 0.94)

func _refresh_verb_decoder(item: Dictionary) -> void:
	if not is_instance_valid(_verb_preview):
		return
	var result := ExerciseInteraction.evaluate_verb_decoder(item, _verb_selection)
	var time_label := _verb_choice_label(item, "timeChoices", str(_verb_selection.get("time", "")))
	var mood_label := _verb_choice_label(item, "moodChoices", str(_verb_selection.get("mood", "")))
	_verb_preview.text = "%s\n%s · %s" % [
		str(result.get("rendered", "")),
		time_label if time_label != "" else "tempo da scegliere",
		mood_label if mood_label != "" else "modo da scegliere",
	]

func _verb_choice_label(item: Dictionary, field: String, id: String) -> String:
	for raw in Array(item.get(field, [])):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return str(entry.get("label", ""))
	return ""

func _verb_submit(item: Dictionary) -> void:
	if _answered or _verb_running:
		return
	for axis in ["time", "mood", "form"]:
		if str(_verb_selection.get(axis, "")) == "":
			_flash_feedback("Regola tutte e tre le parti prima di aprire il messaggio.")
			return
	var result := ExerciseInteraction.evaluate_verb_decoder(item, _verb_selection)
	_verb_running = true
	_verb_set_enabled(false)
	if reduced_motion:
		_finish_verb_decode(item, result)
		return
	var tween := create_tween()
	tween.tween_property(_verb_scanner, "modulate:a", 1.0, 0.14)
	tween.tween_property(_verb_scanner, "modulate:a", 0.28, 0.18)
	tween.tween_callback(_finish_verb_decode.bind(item, result))

func _finish_verb_decode(item: Dictionary, result: Dictionary) -> void:
	_verb_running = false
	if bool(result.get("correct", false)):
		_verb_preview.text = "%s\nINDIZIO RECUPERATO · %s" % [
			str(result.get("rendered", "")), str(item.get("discovery", ""))]
		_causal_feedback("connect", _verb_scanner, 1.12)
		_score_current(true, item)
		return
	var axis := str(result.get("firstMismatch", "form"))
	var hints := item.get("hints", {}) as Dictionary
	var names := {"time": "Il quando non coincide.", "mood": "L'intenzione della frase non coincide.", "form": "La forma non completa bene la frase."}
	_retryable_result(false, item, "%s %s Cambia una ghiera e riprova." % [
		str(names.get(axis, "La ricostruzione non coincide.")), str(hints.get(axis, ""))])
	if not _answered:
		_verb_set_enabled(true)

func _verb_set_enabled(enabled: bool) -> void:
	for button in _verb_buttons.values():
		(button as Button).disabled = not enabled

# Registra l'esito del nodo CORRENTE (scelta multipla, inserimento o minigioco) e
# mostra il pulsante Avanti. Punto unico di bookkeeping: mastery per-topic,
# energia, ripasso e progresso — così ogni formato rispetta lo stesso contratto.
# Nota: gli scudi li gestisce il chiamante (un errore = uno scudo), perché nei
# minigiochi un errore può capitare prima che il nodo sia risolto.
func _score_current(is_correct: bool, item: Dictionary) -> void:
	if _answered:
		return
	_answered = true
	_lock_interactions()
	var topic := str(item.get("topic", ""))
	if topic != "":
		_topic_seen[topic] = int(_topic_seen.get(topic, 0)) + 1
	answer_resolved.emit(is_correct)
	if is_correct:
		var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
		if audio != null:
			audio.call("play_event", "answerCorrect")
		_correct += 1
		_energy += _energy_per_correct
		if topic != "":
			_topic_correct[topic] = int(_topic_correct.get(topic, 0)) + 1
		if bool(item.get("review", false)) and topic != "":
			_reviewed_ok.append(topic)
		if int(_wrong_attempts.get(topic, 0)) > 0:
			_emit_learning_once("perseverance:%s" % topic, "perseverance")
		if bool(item.get("transfer", false)):
			_emit_learning_once("transfer:%s" % topic, "transfer")
		_feedback.add_theme_color_override("font_color", Color("8ff6c0"))
		_feedback.text = "Funziona! +%d energia" % _energy_per_correct
	else:
		var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
		if audio != null:
			audio.call("play_event", "answerWrong")
		if topic != "":
			_missed.append(topic)
		_feedback.add_theme_color_override("font_color", Color("ffb3ba"))
		_feedback.text = (
			"NORA · %s: %s" % [
				str(_maestro_voice.get("name", "Maestro")),
				str(_maestro_voice.get("rilancio", ""))]
			if not _maestro_voice.is_empty()
			else "Non ha ancora funzionato. %s" % str(item.get("explanation", "")))
		_offer_concept_help(item)
	# La costruzione avanza di una campata per ogni nodo risolto (built = _correct);
	# su errore resta ferma, senza mai regredire.
	progress_changed.emit(_correct, _nodes.size())
	var system := str(item.get("system", ""))
	if system != "":
		if system != "sintesi":
			_systems_resolved[system] = is_correct
		if is_instance_valid(_convergence_display):
			_convergence_display.resolve_system(system, is_correct)
		var convergence_audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
		if convergence_audio != null:
			if system == "sintesi" and is_correct:
				convergence_audio.call("play", "circuit.on", 1.18)
			elif system != "sintesi":
				var total_systems := maxi(1, int(Array(session.get("systems", [])).size()))
				var stage_pitch := lerpf(0.90, 1.16, float(_systems_resolved.size()) / float(total_systems))
				convergence_audio.call("play_event", "enigmaProgress", stage_pitch)
	_next_button.text = "CONCLUDI" if _shields <= 0 else "CONTINUA"
	_next_button.visible = true

func _lock_interactions() -> void:
	_input.editable = false
	if is_instance_valid(_input_submit):
		_input_submit.disabled = true
	_disable_buttons(_options)

func _disable_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			(child as Button).disabled = true
		if child.get_child_count() > 0:
			_disable_buttons(child)

# --- Minigioco: ORDINAMENTO (drag/click in slot numerati, modificabile) --------
func _build_ordering(item: Dictionary) -> void:
	var elements: Array = item.get("items", [])
	_ordering_state.resize(elements.size())
	_ordering_state.fill("")
	var instruction := Label.new()
	instruction.text = "Trascina negli slot oppure tocca un elemento. Tocca uno slot per annullarlo."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var source_row := HFlowContainer.new()
	source_row.name = "OrderingSources"
	source_row.add_theme_constant_override("h_separation", 8)
	source_row.add_theme_constant_override("v_separation", 8)
	_options.add_child(source_row)
	for i in elements.size():
		var button := EXERCISE_DRAG_BUTTON.new()
		button.name = "OrderingItem_%02d" % i
		button.text = str(elements[i])
		button.custom_minimum_size = Vector2(150, 48)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("e7fff8"))
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
		button.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
		button.tooltip_text = "Elemento %s: trascina o premi Invio per inserirlo" % str(elements[i])
		button.call("configure", str(i), "ordering")
		button.connect("drag_started", _on_drag_started.bind(button))
		button.pressed.connect(_ordering_click.bind(i, item))
		source_row.add_child(button)
		_mg_buttons.append(button)
	var slots := VBoxContainer.new()
	slots.name = "OrderingSlots"
	slots.add_theme_constant_override("separation", 6)
	_options.add_child(slots)
	for slot_index in elements.size():
		var slot := EXERCISE_DROP_BUTTON.new()
		slot.name = "OrderingSlot_%02d" % slot_index
		slot.text = "%d · —" % (slot_index + 1)
		slot.custom_minimum_size = Vector2(0, 48)
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.add_theme_font_size_override("font_size", 15)
		slot.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.04, 0.13, 0.16, 0.96), Color("527980")))
		slot.call("configure_target", str(slot_index), "ordering")
		slot.connect("item_dropped", _ordering_drop.bind(item))
		slot.pressed.connect(_ordering_clear_slot.bind(slot_index))
		slot.tooltip_text = "Posizione %d. Premi per svuotarla." % (slot_index + 1)
		slots.add_child(slot)
		_ordering_slots.append(slot)
	_add_interaction_actions(_ordering_undo, _ordering_submit.bind(item))

func _ordering_click(i: int, item: Dictionary) -> void:
	if _answered:
		return
	var empty := _ordering_state.find("")
	if empty < 0:
		_flash_feedback("Tutti gli slot sono pieni: toccane uno per modificarlo.")
		return
	_ordering_place(str(i), empty)

func _ordering_drop(source_id: String, target_id: String, _item: Dictionary) -> void:
	_ordering_place(source_id, int(target_id))

func _ordering_place(source_id: String, target_slot: int) -> void:
	if _answered:
		return
	var source := int(source_id)
	if source < 0 or source >= _mg_buttons.size() or target_slot < 0 or target_slot >= _ordering_state.size():
		return
	var previous_slot := _ordering_state.find(source_id)
	if previous_slot >= 0:
		_ordering_state[previous_slot] = ""
	var displaced := str(_ordering_state[target_slot])
	if displaced != "" and int(displaced) < _mg_buttons.size():
		(_mg_buttons[int(displaced)] as Button).disabled = false
	_ordering_state[target_slot] = source_id
	(_mg_buttons[source] as Button).disabled = true
	_refresh_ordering_slots()
	_causal_feedback("snap", _ordering_slots[target_slot], 0.96 + float(target_slot) * 0.035)

func _ordering_clear_slot(slot_index: int) -> void:
	if _answered or slot_index < 0 or slot_index >= _ordering_state.size():
		return
	var source := str(_ordering_state[slot_index])
	if source == "":
		return
	_ordering_state[slot_index] = ""
	(_mg_buttons[int(source)] as Button).disabled = false
	_refresh_ordering_slots()
	_causal_feedback("cancel", _ordering_slots[slot_index], 0.94)

func _ordering_undo() -> void:
	for index in range(_ordering_state.size() - 1, -1, -1):
		if str(_ordering_state[index]) != "":
			_ordering_clear_slot(index)
			return
	_flash_feedback("Non c'è ancora nulla da annullare.")

func _refresh_ordering_slots() -> void:
	for index in _ordering_slots.size():
		var source := str(_ordering_state[index])
		var slot := _ordering_slots[index] as Button
		slot.text = "%d · —" % (index + 1) if source == "" else "%d · %s" % [index + 1, str((_mg_buttons[int(source)] as Button).text)]
	_mg_expected = _ordering_state.size() - _ordering_state.count("")

func _ordering_submit(item: Dictionary) -> void:
	if _ordering_state.has(""):
		_flash_feedback("Completa tutti gli slot prima di verificare.")
		return
	var given: Array = []
	for source in _ordering_state:
		given.append(str((_mg_buttons[int(source)] as Button).text))
	_retryable_result(given == Array(item.get("correctOrder", [])), item, "L'ordine non è ancora corretto: puoi spostare o annullare gli elementi.")

# --- Minigioco: ABBINAMENTO (drag/click, snap e linee persistenti) -------------
func _build_matching(item: Dictionary) -> void:
	var pairs: Array = item.get("pairs", [])
	var instruction := Label.new()
	instruction.text = "Trascina dalla colonna sinistra oppure seleziona due tessere."
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var row := Control.new()
	row.name = "MatchingBoard"
	row.custom_minimum_size = Vector2(0, maxf(160.0, float(pairs.size()) * 52.0))
	_matching_canvas = EXERCISE_CONNECTION_CANVAS.new()
	_matching_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(_matching_canvas)
	var left_col := VBoxContainer.new()
	left_col.anchor_right = 0.44
	left_col.anchor_bottom = 1.0
	left_col.add_theme_constant_override("separation", 8)
	var right_col := VBoxContainer.new()
	right_col.anchor_left = 0.56
	right_col.anchor_right = 1.0
	right_col.anchor_bottom = 1.0
	right_col.add_theme_constant_override("separation", 8)
	for i in pairs.size():
		var lb := EXERCISE_DRAG_BUTTON.new()
		_style_matching_button(lb, str((pairs[i] as Dictionary).get("left", "")))
		lb.name = "MatchingLeft_%02d" % i
		lb.call("configure", str(i), "matching")
		lb.connect("drag_started", _on_drag_started.bind(lb))
		lb.pressed.connect(_matching_left.bind(i))
		left_col.add_child(lb)
		_mg_left_buttons.append(lb)
	var rights: Array = []
	for p in pairs:
		rights.append(str((p as Dictionary).get("right", "")))
	# La colonna destra non può risultare allineata alla sinistra: l'abbinamento si
	# risolverebbe riga per riga, senza sapere nulla delle coppie.
	ExerciseInteraction.shuffle_avoiding(rights, _rng, rights.duplicate())
	for j in rights.size():
		var rb := EXERCISE_DROP_BUTTON.new()
		_style_matching_button(rb, str(rights[j]))
		rb.name = "MatchingRight_%02d" % j
		rb.call("configure_target", str(rights[j]), "matching")
		rb.connect("item_dropped", _matching_drop.bind(item))
		rb.pressed.connect(_matching_right.bind(str(rights[j]), item))
		right_col.add_child(rb)
		_mg_right_buttons.append(rb)
	row.add_child(left_col)
	row.add_child(right_col)
	_options.add_child(row)

func _style_matching_button(b: Button, text: String) -> void:
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("e7fff8"))
	b.add_theme_color_override("font_disabled_color", Color("d9fff0"))
	b.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
	b.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
	b.add_theme_stylebox_override("disabled", _exercise_button_style(Color(0.08, 0.28, 0.24, 0.96), Color("8ff6d2")))
	b.focus_mode = Control.FOCUS_ALL

func _shuffle(values: Array, random: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var temporary = values[i]
		values[i] = values[j]
		values[j] = temporary

func _matching_left(i: int) -> void:
	if _answered or _mg_left_buttons[i].disabled:
		return
	_mg_selected_left = i
	_causal_feedback("select", _mg_left_buttons[i], 0.94)
	for k in _mg_left_buttons.size():
		var b: Button = _mg_left_buttons[k]
		if not b.disabled:
			b.modulate = Color(1.0, 0.86, 0.5) if k == i else Color(1, 1, 1)

func _matching_drop(source_id: String, target_id: String, item: Dictionary) -> void:
	_mg_selected_left = int(source_id)
	_matching_right(target_id, item)

func _matching_right(value: String, item: Dictionary) -> void:
	if _answered or _mg_selected_left < 0:
		return
	var pairs: Array = item.get("pairs", [])
	var expected := str((pairs[_mg_selected_left] as Dictionary).get("right", ""))
	if value == expected:
		_mg_left_buttons[_mg_selected_left].disabled = true
		_mg_left_buttons[_mg_selected_left].modulate = Color(0.6, 1.0, 0.75)
		for rb in _mg_right_buttons:
			if not rb.disabled and str(rb.text) == value:
				rb.disabled = true
				rb.modulate = Color(0.6, 1.0, 0.75)
				_matching_connections.append({
					"left": _mg_left_buttons[_mg_selected_left],
					"right": rb,
					"color": _matching_color(_mg_matched),
				})
				if is_instance_valid(_matching_canvas):
					_matching_canvas.call("set_connections", _matching_connections)
				_causal_feedback("connect", rb, 0.96 + float(_mg_matched) * 0.07)
				_causal_feedback("snap", _mg_left_buttons[_mg_selected_left], 1.04)
				break
		_mg_matched += 1
		_mg_selected_left = -1
		if _mg_matched >= pairs.size():
			_score_current(true, item)
	else:
		_causal_feedback("error", _mg_left_buttons[_mg_selected_left], 0.88)
		_spend_shield()
		_refresh_status()
		_flash_feedback("Coppia sbagliata: riprova.")
		if _mg_selected_left >= 0 and not _mg_left_buttons[_mg_selected_left].disabled:
			_mg_left_buttons[_mg_selected_left].modulate = Color(1, 1, 1)
		_mg_selected_left = -1
		if _shields <= 0:
			_score_current(false, item)

func _matching_color(index: int) -> Color:
	var palette := [Color("8ff6d2"), Color("f6c85f"), Color("9f8cff"), Color("7ad7ff"), Color("ff9fb6")]
	return palette[index % palette.size()]

# --- CLASSIFICAZIONE (drag/click verso categorie, sempre correggibile) --------
func _build_classification(item: Dictionary) -> void:
	var instruction := Label.new()
	instruction.text = "Sposta ogni tessera nella categoria corretta. Puoi riassegnarla prima di verificare."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var source_row := HFlowContainer.new()
	source_row.name = "ClassificationItems"
	source_row.add_theme_constant_override("h_separation", 8)
	source_row.add_theme_constant_override("v_separation", 8)
	_options.add_child(source_row)
	for value in item.get("items", []):
		var key := str(value)
		var button := EXERCISE_DRAG_BUTTON.new()
		button.name = "ClassificationItem_%s" % key.validate_node_name()
		button.text = key
		button.custom_minimum_size = Vector2(150, 48)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.96), Color("527980")))
		button.call("configure", key, "classification")
		button.connect("drag_started", _on_drag_started.bind(button))
		button.pressed.connect(_classification_select.bind(key))
		button.tooltip_text = "%s: trascina o seleziona per assegnare" % key
		source_row.add_child(button)
		_classification_buttons[key] = button
	var categories := HFlowContainer.new()
	categories.name = "ClassificationCategories"
	categories.add_theme_constant_override("h_separation", 10)
	categories.add_theme_constant_override("v_separation", 10)
	_options.add_child(categories)
	for value in item.get("categories", []):
		var category := str(value)
		var target := EXERCISE_DROP_BUTTON.new()
		target.name = "ClassificationTarget_%s" % category.validate_node_name()
		target.text = category
		target.custom_minimum_size = Vector2(190, 58)
		target.add_theme_font_size_override("font_size", 16)
		target.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.05, 0.16, 0.19, 0.98), Color("8ff6d2")))
		target.call("configure_target", category, "classification")
		target.connect("item_dropped", _classification_drop)
		target.pressed.connect(_classification_category.bind(category))
		target.tooltip_text = "Categoria %s" % category
		categories.add_child(target)
	_add_interaction_actions(_classification_undo, _classification_submit.bind(item))

func _classification_select(key: String) -> void:
	if _answered:
		return
	_classification_selected = key
	for item_key in _classification_buttons.keys():
		var button := _classification_buttons[item_key] as Button
		button.modulate = Color("f6c85f") if str(item_key) == key else Color.WHITE
	_flash_feedback("Ora scegli la categoria per “%s”." % key)
	_causal_feedback("select", _classification_buttons[key], 0.94)

func _classification_category(category: String) -> void:
	if _classification_selected == "":
		_flash_feedback("Prima seleziona una tessera, oppure trascinala qui.")
		return
	_classification_assign(_classification_selected, category)

func _classification_drop(source_id: String, target_id: String) -> void:
	_classification_assign(source_id, target_id)

func _classification_assign(key: String, category: String) -> void:
	if _answered or not _classification_buttons.has(key):
		return
	_classification_state[key] = category
	_classification_selected = ""
	var button := _classification_buttons[key] as Button
	button.text = "%s  →  %s" % [key, category]
	button.modulate = Color(0.72, 1.0, 0.84)
	_flash_feedback("Assegnato a %s. Puoi ancora cambiarlo." % category)
	_causal_feedback("snap", button, 1.02 + float(_classification_state.size()) * 0.025)

func _classification_undo() -> void:
	if _classification_selected != "":
		_classification_selected = ""
		for button in _classification_buttons.values():
			(button as Button).modulate = Color.WHITE
		return
	var keys := _classification_state.keys()
	if keys.is_empty():
		_flash_feedback("Non c'è ancora nulla da annullare.")
		return
	var key := str(keys[keys.size() - 1])
	_classification_state.erase(key)
	var button := _classification_buttons[key] as Button
	button.text = key
	button.modulate = Color.WHITE
	_causal_feedback("cancel", button, 0.92)

func _classification_submit(item: Dictionary) -> void:
	var expected: Dictionary = item.get("assignments", {})
	if _classification_state.size() < expected.size():
		_flash_feedback("Classifica tutte le tessere prima di verificare.")
		return
	var correct := true
	for key in expected.keys():
		if str(_classification_state.get(str(key), "")) != str(expected[key]):
			correct = false
			break
	_retryable_result(correct, item, "Alcune tessere sono nella categoria sbagliata: puoi spostarle e riprovare.")

# --- HOTSPOT / GRAFICO / CIRCUITO / NOTAZIONE / MAPPA (superficie diegetica) --
func _build_visual_selection(item: Dictionary, fmt: String) -> void:
	var instruction := Label.new()
	instruction.text = {
		"hotspot": "Seleziona il punto corretto nell'immagine.",
		"graph": "Leggi assi e andamento, poi seleziona il punto richiesto.",
		"circuit": "Osserva i collegamenti e seleziona il componente richiesto.",
		"notation": "Leggi il pentagramma e seleziona il simbolo richiesto.",
		"map": "Leggi la carta muta e seleziona il luogo richiesto.",
		"number_line": "Guarda dove cadono i valori sulla retta e scegli il punto richiesto.",
		"balance": "I due piatti devono pesare uguale: scegli che cosa manca.",
		"timeline": "Guarda quanto distano fra loro gli eventi e scegli quello richiesto.",
		"compose": "Guarda i pezzi già al posto giusto e scegli quello che completa.",
		"trace": "Segui i passi uno per volta e scegli lo stato finale.",
		"clue": "Scopri gli indizi che ti servono, poi scegli. Meno ne usi, meglio è.",
	}.get(fmt, "Seleziona il punto corretto.")
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var diagram := EXERCISE_DIAGRAM.new()
	diagram.name = "ExerciseDiagram_%s" % fmt
	var diagram_model := item.duplicate(true)
	if fmt == "map":
		diagram_model["geometry"] = MAP_GEOMETRY_CATALOG.map_data(str(item.get("mapId", "")))
	elif fmt == "hotspot" and str(item.get("assetId", "")) != "":
		var atlas := ARTIFACT_ATLAS_CATALOG.atlas_data(str(item.get("assetId", "")))
		diagram_model["image"] = str(atlas.get("image", ""))
		var resolved: Array = []
		var positions := atlas.get("targets", {}) as Dictionary
		for entry in item.get("targets", []):
			var target := (entry as Dictionary).duplicate(true)
			var position := positions.get(str(target.get("id", "")), Vector2(0.5, 0.5)) as Vector2
			target["x"] = position.x
			target["y"] = position.y
			resolved.append(target)
		diagram_model["hotspots"] = resolved
	diagram.call("configure", fmt, diagram_model)
	_visual_diagram = diagram
	_options.add_child(diagram)
	if fmt == "clue":
		_build_clue_button(item)
	var points: Array = (
		diagram_model.get("hotspots", []) if fmt == "hotspot"
		else item.get("points", []) if fmt == "graph"
		else item.get("components", []) if fmt == "circuit"
		else item.get("targets", []) if fmt in ["map", "number_line", "balance", "timeline", "compose", "trace", "clue"]
		else item.get("symbols", [])
	)
	for point in points:
		var spec := point as Dictionary
		var id := str(spec.get("id", ""))
		var button := Button.new()
		button.name = "VisualChoice_%s" % id.validate_node_name()
		var accessible_label := str(spec.get("label", id))
		var blank_hit_target := fmt in ["notation", "map", "number_line", "timeline"] or (fmt == "hotspot" and str(item.get("assetId", "")) != "")
		button.text = "" if blank_hit_target else accessible_label
		button.accessibility_name = accessible_label
		button.set_meta("visual_label", accessible_label)
		button.tooltip_text = str(spec.get("description", accessible_label))
		if fmt == "map":
			button.set_meta("map_target_id", id)
		elif fmt == "hotspot" and str(item.get("assetId", "")) != "":
			button.set_meta("hotspot_target_id", id)
		button.custom_minimum_size = Vector2(120, 72) if fmt == "hotspot" and blank_hit_target else Vector2(72, 56) if fmt == "map" else Vector2(56, 48) if fmt == "notation" else Vector2(74, 48)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 13)
		if blank_hit_target:
			button.add_theme_stylebox_override("normal", _notation_hit_style(Color(0, 0, 0, 0)))
			button.add_theme_stylebox_override("hover", _notation_hit_style(Color(0.42, 0.90, 0.84, 0.22)))
			button.add_theme_stylebox_override("focus", _notation_hit_style(Color(0.96, 0.78, 0.36, 0.34)))
		else:
			button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.03, 0.15, 0.18, 0.96), Color("f6c85f")))
		var normalized: Vector2 = (
			diagram.call("map_anchor", id) if fmt == "map"
			else diagram.call("number_line_anchor", id) if fmt == "number_line"
			else diagram.call("balance_anchor", id) if fmt == "balance"
			else diagram.call("timeline_anchor", id) if fmt == "timeline"
			else diagram.call("compose_anchor", id) if fmt == "compose"
			else diagram.call("trace_anchor", id) if fmt == "trace"
			else diagram.call("clue_anchor", id) if fmt == "clue"
			else diagram.call("notation_anchor", id) if fmt == "notation"
			else diagram.call("hotspot_anchor", id) if fmt == "hotspot" and blank_hit_target
			else _diagram_anchor(spec, fmt)
		)
		button.anchor_left = normalized.x
		button.anchor_right = normalized.x
		button.anchor_top = normalized.y
		button.anchor_bottom = normalized.y
		button.offset_left = -60 if fmt == "hotspot" and blank_hit_target else -36 if fmt == "map" else -28 if fmt == "notation" else -48
		button.offset_right = 60 if fmt == "hotspot" and blank_hit_target else 36 if fmt == "map" else 28 if fmt == "notation" else 48
		button.offset_top = -36 if fmt == "hotspot" and blank_hit_target else -28 if fmt == "map" else -24
		button.offset_bottom = 36 if fmt == "hotspot" and blank_hit_target else 28 if fmt == "map" else 24
		button.pressed.connect(_visual_select.bind(id))
		diagram.add_child(button)
		_visual_buttons[id] = button
	if fmt == "map":
		diagram.call_deferred("layout_map_targets")
	elif fmt == "hotspot" and str(item.get("assetId", "")) != "":
		diagram.call_deferred("layout_hotspot_targets")
	_add_interaction_actions(_visual_clear, _visual_submit.bind(item))

func _diagram_anchor(spec: Dictionary, fmt: String) -> Vector2:
	var x := clampf(float(spec.get("x", 0.5)), 0.05, 0.95)
	var y := clampf(float(spec.get("y", 0.5)), 0.05, 0.95)
	if fmt == "graph":
		return Vector2(0.12 + x * 0.80, 0.82 - y * 0.68)
	return Vector2(x, y)

func _notation_hit_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.96, 0.78, 0.36, 0.82)
	style.set_border_width_all(2 if fill.a > 0.0 else 0)
	style.set_corner_radius_all(12)
	return style

func _visual_select(id: String) -> void:
	if _answered:
		return
	_visual_selected = id
	for key in _visual_buttons.keys():
		var button := _visual_buttons[key] as Button
		button.modulate = Color("f6c85f") if str(key) == id else Color.WHITE
	var selected_button := _visual_buttons[id] as Button
	var selected_label := str(selected_button.get_meta("visual_label", selected_button.text))
	_flash_feedback("Selezione: %s. Verifica quando sei sicuro." % selected_label)
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_feedback", id, "selected")
	_causal_feedback("select", _visual_buttons[id], 0.98)

func _visual_clear() -> void:
	_visual_selected = ""
	for button in _visual_buttons.values():
		(button as Button).modulate = Color.WHITE
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_feedback", "", "")
	_causal_feedback("cancel", _visual_diagram, 0.92)

func _visual_submit(item: Dictionary) -> void:
	if _visual_selected == "":
		_flash_feedback("Seleziona prima un punto.")
		return
	var correct := _visual_selected == str(item.get("answer", ""))
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_feedback", _visual_selected, "correct" if correct else "error")
	if correct and str(item.get("format", "")) == "circuit":
		_causal_feedback("connect", _visual_buttons.get(_visual_selected) as Control, 1.14)
	_retryable_result(correct, item, "Quel punto non spiega il fenomeno: osserva di nuovo la struttura.")

# --- CICLO VISUALE (costruzione della sequenza sullo schema) -----------------
func _build_cycle(item: Dictionary) -> void:
	var instruction := Label.new()
	instruction.text = "Tocca le fasi nell'ordine corretto: le frecce si costruiscono mentre ragioni."
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var diagram := EXERCISE_DIAGRAM.new()
	diagram.name = "ExerciseDiagram_cycle"
	diagram.call("configure", "cycle", item)
	_visual_diagram = diagram
	_options.add_child(diagram)
	var stages: Array = item.get("stages", [])
	for index in stages.size():
		var stage := stages[index] as Dictionary
		var id := str(stage.get("id", ""))
		var label := str(stage.get("label", id))
		var button := Button.new()
		button.name = "CycleStage_%s" % id.validate_node_name()
		button.text = ""
		button.accessibility_name = label
		button.tooltip_text = label
		button.set_meta("visual_label", label)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _notation_hit_style(Color(0, 0, 0, 0)))
		button.add_theme_stylebox_override("hover", _notation_hit_style(Color(0.42, 0.90, 0.84, 0.22)))
		button.add_theme_stylebox_override("focus", _notation_hit_style(Color(0.96, 0.78, 0.36, 0.34)))
		var anchor: Vector2 = diagram.call("cycle_anchor", index, stages.size())
		button.anchor_left = anchor.x
		button.anchor_right = anchor.x
		button.anchor_top = anchor.y
		button.anchor_bottom = anchor.y
		button.offset_left = -55
		button.offset_right = 55
		button.offset_top = -32
		button.offset_bottom = 58
		button.custom_minimum_size = Vector2(110, 90)
		button.pressed.connect(_cycle_select.bind(id))
		diagram.add_child(button)
		_visual_buttons[id] = button
	_add_interaction_actions(_cycle_clear, _cycle_submit.bind(item))

func _cycle_select(id: String) -> void:
	if _answered:
		return
	var existing := _cycle_sequence.find(id)
	if existing >= 0:
		_cycle_sequence.resize(existing)
	else:
		_cycle_sequence.append(id)
	for key in _visual_buttons.keys():
		var selected := _cycle_sequence.has(str(key))
		(_visual_buttons[key] as Button).modulate = Color("f6c85f") if selected else Color.WHITE
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_cycle_sequence", _cycle_sequence, "")
	var label := str((_visual_buttons[id] as Button).get_meta("visual_label", id))
	_flash_feedback("Sequenza aggiornata: %s%s" % [label, "" if existing >= 0 else " è il passo %d." % _cycle_sequence.size()])
	_causal_feedback("select", _visual_buttons[id], 0.98)

func _cycle_clear() -> void:
	_cycle_sequence = []
	for button in _visual_buttons.values():
		(button as Button).modulate = Color.WHITE
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_cycle_sequence", _cycle_sequence, "")
	_causal_feedback("cancel", _visual_diagram, 0.92)

func _cycle_submit(item: Dictionary) -> void:
	var expected: Array = item.get("correctOrder", []).map(func(value): return str(value))
	if _cycle_sequence.size() != expected.size():
		_flash_feedback("Completa tutte le fasi prima di verificare.")
		return
	var correct := _cycle_sequence == expected
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_cycle_sequence", _cycle_sequence, "correct" if correct else "error")
	_retryable_result(correct, item, "L'ordine non chiude ancora il ciclo: tocca una fase per correggere da quel punto.")

# --- CODE DEBUG (righe selezionabili, numerate e leggibili da tastiera) --------
func _build_code_debug(item: Dictionary) -> void:
	var lines: Array = item.get("codeLines", [])
	# La riga che inizia con '#' è la CONSEGNA (l'intento: "atteso: 1, 2, 3"), non un
	# passaggio: non può mai essere la risposta. Prima era resa come un pulsante
	# numerato identico agli altri, quindi era selezionabile — e chi la sceglieva
	# riceveva "Quella riga è valida: segui i valori passo per passo", che per un
	# commento non significa nulla. Segnalato giocando il 30 luglio: su tre righe
	# mostrate una non era nemmeno un candidato.
	var note_text := ""
	for line in lines:
		if _is_code_note(str(line)):
			note_text = str(line).strip_edges().trim_prefix("#").strip_edges()
			break

	var instruction := Label.new()
	instruction.text = (
		"Tocca la riga sbagliata. Le righe numerate sono i passaggi; in grigio la consegna."
		if note_text != ""
		else "Tocca la riga che contiene l'errore.")
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)

	for index in lines.size():
		var raw := str(lines[index])
		if _is_code_note(raw):
			continue
		# Il numero mostrato resta l'indice in `codeLines`, così `answerLine` non
		# cambia significato. La consegna sta sempre in ultima posizione (verificato
		# da `code_debug_clarity_audit`), quindi la numerazione resta contigua.
		var line_number := index + 1
		var button := Button.new()
		button.name = "CodeLine_%02d" % line_number
		button.text = "%02d  │  %s" % [line_number, raw]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 48)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.025, 0.08, 0.10, 0.98), Color("527980")))
		button.pressed.connect(_code_line_select.bind(line_number))
		_options.add_child(button)
		_visual_buttons[str(line_number)] = button

	if note_text != "":
		var note := Label.new()
		note.name = "CodeNote"
		note.text = note_text
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", 14)
		note.add_theme_color_override("font_color", Color("8ba3a7"))
		_options.add_child(note)

	_add_interaction_actions(_visual_clear, _code_submit.bind(item))

## Una riga di consegna, non un passaggio: si legge, non si seleziona.
func _is_code_note(line: String) -> bool:
	return line.strip_edges().begins_with("#")

func _code_line_select(line_number: int) -> void:
	_visual_select(str(line_number))

func _code_submit(item: Dictionary) -> void:
	if _visual_selected == "":
		_flash_feedback("Seleziona prima una riga.")
		return
	_retryable_result(int(_visual_selected) == int(item.get("answerLine", 0)), item, "Quella riga è valida: segui i valori passo per passo e riprova.")

func _add_interaction_actions(
	undo_callback: Callable,
	submit_callback: Callable,
	undo_text: String = "ANNULLA",
	submit_text: String = "PROVA"
) -> void:
	var actions := HBoxContainer.new()
	actions.name = "InteractionActions"
	actions.add_theme_constant_override("separation", 10)
	var undo := Button.new()
	undo.name = "InteractionUndo"
	undo.text = undo_text
	undo.custom_minimum_size = Vector2(140, 48)
	undo.focus_mode = Control.FOCUS_ALL
	undo.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.09, 0.15, 0.18, 0.96), Color("75999f")))
	undo.pressed.connect(undo_callback)
	actions.add_child(undo)
	var submit := Button.new()
	submit.name = "InteractionSubmit"
	submit.text = submit_text
	submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit.custom_minimum_size = Vector2(180, 48)
	submit.focus_mode = Control.FOCUS_ALL
	submit.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.13, 0.38, 0.32, 1.0), Color("8ff6d2")))
	submit.pressed.connect(submit_callback)
	actions.add_child(submit)
	_options.add_child(actions)

func _retryable_result(correct: bool, item: Dictionary, retry_message: String) -> void:
	if correct:
		_score_current(true, item)
		return
	_causal_feedback("error", _options, 0.86)
	_spend_shield()
	_register_wrong_attempt(item)
	_refresh_status()
	_flash_feedback(retry_message)
	_offer_concept_help(item)
	if _shields <= 0:
		_score_current(false, item)

func _spend_shield() -> void:
	_shields -= 1
	# Il finale deve far attraversare tutti i dodici sistemi anche quando un
	# minigioco richiede più tentativi. L'accuratezza resta decisiva per passare,
	# ma la sessione non si tronca prima della sintesi.
	if bool(session.get("completeAllSystems", false)):
		_shields = maxi(1, _shields)

# Feedback temporaneo durante un minigioco (senza chiudere il nodo).
func _flash_feedback(message: String) -> void:
	if is_instance_valid(_feedback):
		_feedback.add_theme_color_override("font_color", Color("ffd37a"))
		_feedback.text = message

## Vocabolario causale comune a tutti i renderer non-MC. Ogni gesto produce
## una firma sonora e visiva distinta; il meta rende il contratto auditabile.
func _causal_feedback(cue: String, target: Control = null, pitch: float = 1.0) -> void:
	set_meta("last_causal_feedback", cue)
	var audio: Node = get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
	var sound_key: String = str({
		"pickup": "ui.select",
		"select": "ui.select",
		"snap": "ui.confirm",
		"connect": "circuit.on",
		"cancel": "ui.cancel",
		"error": "answer.wrong",
	}.get(cue, ""))
	if audio != null and sound_key != "":
		audio.call("play", sound_key, pitch)
	if not is_instance_valid(target):
		return
	target.pivot_offset = target.size * 0.5
	if reduced_motion:
		target.modulate = (
			Color(0.72, 1.0, 0.84) if cue in ["snap", "connect"]
			else Color("f6c85f") if cue in ["pickup", "select"]
			else Color.WHITE
		)
		return
	var original_scale := target.scale
	var original_position := target.position
	var original_modulate := target.modulate
	var accent := (
		Color(0.72, 1.0, 0.84) if cue in ["snap", "connect"]
		else Color("ff9faa") if cue == "error"
		else Color("f6c85f")
	)
	var tween := create_tween()
	if cue == "error":
		target.modulate = accent
		tween.tween_property(target, "position:x", original_position.x - 8.0, 0.045)
		tween.tween_property(target, "position:x", original_position.x + 7.0, 0.055)
		tween.tween_property(target, "position:x", original_position.x, 0.055)
		tween.parallel().tween_property(target, "modulate", original_modulate, 0.18)
	else:
		target.modulate = accent
		target.scale = original_scale * 0.96
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(target, "scale", original_scale * 1.045, 0.10)
		tween.tween_property(target, "scale", original_scale, 0.12)
		tween.parallel().tween_property(target, "modulate", original_modulate, 0.22)

func _on_drag_started(source: Control) -> void:
	_causal_feedback("pickup", source, 0.92)

func _offer_concept_help(item: Dictionary) -> void:
	if not is_instance_valid(_help_button):
		return
	# In esame la soluzione corrente non deve essere raggiungibile dalla prova.
	_help_button.visible = str(session.get("kind", "mission")) != "final_exam" and str(item.get("topic", "")) != ""

## Il pulsante che scopre l'indizio successivo.
##
## Il primo indizio è già scoperto quando la prova comincia: partire da zero
## informazioni non è una scelta strategica, è solo un tocco obbligato prima di
## poter cominciare a pensare.
##
## Scoprire un indizio NON costa energia e non toglie punti. In un gioco che per
## contratto non punisce, il prezzo è soltanto la soddisfazione in meno di
## averne usati pochi — e il rischio, che c'è già: rispondere presto e sbagliare
## costa uno scudo come qualunque altro errore.
## LO SCORRIMENTO. Affermazioni una dopo l'altra: a sinistra se è sbagliata, a
## destra se è corretta, finché il tempo regge.
##
## Tre alternative allo swipe, e non sono un ripiego: due zone da toccare grandi
## quanto mezzo schermo, le frecce della tastiera, e il focus per chi naviga a
## tabulazione. Un gioco che si comanda solo con un gesto esclude chi usa un
## lettore di schermo o una tastiera — e qui il gesto non è il contenuto, è solo
## il modo più rapido di dire due cose.
func _build_swipe(item: Dictionary) -> void:
	_swipe_item = item
	_swipe_index = 0
	_swipe_streak = 0
	_swipe_best = 0
	_swipe_score = 0
	_swipe_right = 0
	_swipe_seconds = float(item.get("seconds", 45.0))

	var diagram := EXERCISE_DIAGRAM.new()
	diagram.name = "ExerciseDiagram_swipe"
	diagram.call("configure", "swipe", item)
	diagram.custom_minimum_size = Vector2(0, 320)
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual_diagram = diagram
	_options.add_child(diagram)

	var riga := HBoxContainer.new()
	riga.name = "SwipeButtons"
	riga.add_theme_constant_override("separation", 12)
	riga.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options.add_child(riga)
	for dati in [
		{"nome": "SwipeWrongButton", "testo": "◀  SBAGLIATO", "giusto": false, "colore": Color("ff8f7e")},
		{"nome": "SwipeRightButton", "testo": "CORRETTO  ▶", "giusto": true, "colore": Color("91dc72")},
	]:
		var b := Button.new()
		b.name = str(dati["nome"])
		b.text = str(dati["testo"])
		b.custom_minimum_size = Vector2(0, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", Color("06272a"))
		b.add_theme_stylebox_override("normal", _exercise_button_style(dati["colore"], Color("d8fff8")))
		b.pressed.connect(_swipe_judge.bind(bool(dati["giusto"])))
		riga.add_child(b)
	_push_swipe_state("")
	set_process(true)

func _process(delta: float) -> void:
	if _answered or str(_swipe_item.get("format", "")) != "swipe":
		return
	_swipe_seconds = maxf(0.0, _swipe_seconds - delta)
	_push_swipe_state("")
	if _swipe_seconds <= 0.0:
		_finish_swipe()

## Giudizio su un'affermazione. La serie **si ferma, non si azzera**: il
## moltiplicatore riparte da uno e i punti già presi restano. Nessun messaggio
## negativo, nessun contatore che crolla — è la stessa regola del legame del
## Custode e dei giorni del diario.
func _swipe_judge(detto_corretto: bool) -> void:
	if _answered:
		return
	var frasi: Array = Array(_swipe_item.get("statements", []))
	if _swipe_index >= frasi.size():
		return
	var vera := bool((frasi[_swipe_index] as Dictionary).get("correct", false))
	var indovinato := detto_corretto == vera
	if indovinato:
		_swipe_right += 1
		_swipe_streak += 1
		_swipe_best = maxi(_swipe_best, _swipe_streak)
		# Il moltiplicatore cresce ma non esplode: oltre il cinque il punteggio
		# diventerebbe una lotteria sull'ultima serie invece che sulla precisione.
		_swipe_score += 10 * mini(5, _swipe_streak)
	else:
		_swipe_streak = 0
	_swipe_index += 1
	_push_swipe_state("right" if indovinato else "wrong")
	if _swipe_index >= frasi.size():
		_finish_swipe()

func _push_swipe_state(flash: String) -> void:
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_swipe_state",
			_swipe_index, _swipe_streak, _swipe_best, _swipe_score, _swipe_seconds, flash)

## Il round finisce quando le affermazioni sono esaurite o il tempo è scaduto.
## Il nodo è superato se la precisione raggiunge la soglia dichiarata: giudicare
## a caso dà il cinquanta per cento, e la soglia sta sopra apposta — è il motivo
## per cui una prova binaria può essere onesta, purché sia lunga.
func _finish_swipe() -> void:
	if _answered:
		return
	set_process(false)
	var frasi: Array = Array(_swipe_item.get("statements", []))
	var giudicate := maxi(1, _swipe_index)
	var precisione := float(_swipe_right) / float(giudicate)
	var soglia := float(_swipe_item.get("minAccuracy", 0.75))
	var superato := precisione >= soglia and _swipe_index >= int(ceil(float(frasi.size()) * 0.6))
	_push_swipe_state("")
	_flash_feedback("%d giuste su %d · serie migliore ×%d · %d punti" % [
		_swipe_right, giudicate, maxi(1, _swipe_best), _swipe_score])
	if not superato:
		_spend_shield()
	_score_current(superato, _swipe_item)

func _build_clue_button(item: Dictionary) -> void:
	_clues_revealed = 1
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_clues_revealed", _clues_revealed)
	var totale := Array(item.get("clues", [])).size()
	_clue_button = Button.new()
	_clue_button.name = "RevealClueButton"
	_clue_button.custom_minimum_size = Vector2(0, 48)
	_clue_button.focus_mode = Control.FOCUS_ALL
	_clue_button.add_theme_font_size_override("font_size", 15)
	_clue_button.add_theme_color_override("font_color", Color("06272a"))
	_clue_button.add_theme_stylebox_override(
		"normal", _exercise_button_style(Color("6be7d6"), Color("d8fff8")))
	_clue_button.pressed.connect(_reveal_clue.bind(totale))
	_options.add_child(_clue_button)
	_refresh_clue_button(totale)

func _reveal_clue(totale: int) -> void:
	if _answered or _clues_revealed >= totale:
		return
	_clues_revealed += 1
	if is_instance_valid(_visual_diagram):
		_visual_diagram.call("set_clues_revealed", _clues_revealed)
	_refresh_clue_button(totale)

func _refresh_clue_button(totale: int) -> void:
	if not is_instance_valid(_clue_button):
		return
	var restano := totale - _clues_revealed
	_clue_button.disabled = restano <= 0
	_clue_button.text = (
		"CHIEDI UN INDIZIO (ne restano %d)" % restano if restano > 0
		else "NESSUN ALTRO INDIZIO")

## L'indizio: la FORMA della risposta, mai la risposta.
##
## Tre gradi, dal più discreto al più esplicito, perché un indizio unico o è
## troppo poco per chi è bloccato o è troppo per chi ci era quasi. Si tocca il
## pulsante una volta in più e si scopre un pezzo in più.
##
## Non svela mai l'ultima lettera né l'ultima cifra: da lì in poi non sarebbe un
## indizio, sarebbe la soluzione scritta a rate.
func _mostra_indizio() -> void:
	if _index < 0 or _index >= _nodes.size():
		return
	var item: Dictionary = _nodes[_index]
	var risposta := str(item.get("answer", "")).strip_edges()
	if risposta.is_empty():
		return
	_hint_level += 1
	var testo := ""
	if _answer_is_numeric(risposta):
		match _hint_level:
			1:
				testo = "È un numero di %d cifre." % risposta.length()
			2:
				testo = "Comincia per %s, e ha %d cifre." % [risposta.substr(0, 1), risposta.length()]
			_:
				# Il primo e l'ultimo estremo di una decina: restringe senza dire.
				var valore := float(risposta)
				var decina: float = floor(valore / 10.0) * 10.0
				testo = "Sta fra %d e %d." % [int(decina), int(decina) + 10]
	else:
		match _hint_level:
			1:
				testo = "Comincia per «%s»." % risposta.substr(0, 1).to_upper()
			2:
				testo = "Comincia per «%s» ed è lunga %d lettere." % [
					risposta.substr(0, 1).to_upper(), risposta.length()]
			_:
				var quante := maxi(1, int(floor(float(risposta.length()) / 2.0)))
				testo = "Comincia con «%s…» ed è lunga %d lettere." % [
					risposta.substr(0, quante), risposta.length()]
	if _hint_level >= 3 and is_instance_valid(_hint_button):
		_hint_button.disabled = true
		_hint_button.text = "INDIZIO ESAURITO"
	_flash_feedback("Indizio: %s" % testo)

func _request_concept_help() -> void:
	if _index < 0 or _index >= _nodes.size():
		return
	var item: Dictionary = _nodes[_index]
	concept_help_requested.emit(str(session.get("subject", "")), str(item.get("topic", "")))

func _register_wrong_attempt(item: Dictionary) -> void:
	var topic := str(item.get("topic", ""))
	if topic == "":
		return
	_wrong_attempts[topic] = int(_wrong_attempts.get(topic, 0)) + 1
	if int(_wrong_attempts[topic]) >= 2:
		_emit_learning_once("recurring_error:%s" % topic, "recurring_error")
	# Al terzo errore sullo stesso argomento, una volta sola: il conteggio vive
	# e muore con la sessione, non con l'argomento. Un bambino che sbaglia la
	# stessa cosa in tre sessioni diverse, su tre giorni diversi, non sta
	# ripetendo un errore — sta ancora imparando, ed è normale.
	if int(_wrong_attempts[topic]) >= 3 and not _struggle_emitted.has(topic):
		_struggle_emitted[topic] = true
		topic_struggle.emit(topic)

func _emit_learning_once(key: String, signal_name: String) -> void:
	if _learning_emitted.has(key):
		return
	_learning_emitted[key] = true
	learning_signal.emit(signal_name)

## Snapshot read-only usato dagli audit per provare che l'apertura del manuale
## non resetta o ricrea la sessione in corso.
func session_cursor() -> Dictionary:
	return {
		"sessionId": str(session.get("sessionId", "")),
		"index": _index,
		"correct": _correct,
		"shields": _shields,
		"answered": _answered,
	}

func _advance() -> void:
	if _shields <= 0:
		_finish()
		return
	_index += 1
	_show_current()
	# La spiegazione dell'argomento nuovo, se questo nodo ne porta una: prima
	# della domanda, non dopo l'errore.
	#
	# **Mai dopo l'ultimo nodo.** `_show_current` chiude la sessione quando
	# l'indice supera i nodi: senza questo controllo si aggiungeva una scheda
	# modale a prova già consegnata — un pannello a tutto schermo che mangia i
	# tocchi sopra una sessione che non esiste più.
	if _index < _nodes.size():
		_show_teaching_overlay()

## Uscita anticipata. La prova non è consegnata: niente esito, niente incontro
## completato, nessuna energia dalla sessione. Restano gli argomenti visti, che
## il chiamante gira al Codex esattamente come per una prova conclusa.
func _abandon() -> void:
	var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
	if audio != null:
		audio.call("set_focus", false)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("delete document.documentElement.dataset.eliExercise;")
	session_finished.emit({
		"sessionId": str(session.get("sessionId", "")),
		"kind": str(session.get("kind", "mission")),
		"correct": _correct,
		"total": _nodes.size(),
		"passed": false,
		"abandoned": true,
		"abandonCost": _abandon_cost,
		# Zero: l'energia di una prova non consegnata non arriva. È questo, non
		# una penale aggiuntiva, a togliere convenienza all'uscire e rientrare
		# finché non capitano le domande facili.
		"energyGained": 0,
		"shieldsLeft": _shields,
		"subject": str(session.get("subject", "")),
		"seconds": maxf(0.0, float(Time.get_ticks_msec() - _started_at_msec) / 1000.0),
		"missed": _missed.duplicate(),
		"reviewedOk": _reviewed_ok.duplicate(),
		"systemsResolved": _systems_resolved.keys(),
		"synthesisResolved": false,
		"topicStats": _build_topic_stats(),
	})

## Il tasto indietro del tablet e l'Esc della tastiera fanno la stessa cosa del
## pulsante: armano la conferma, non escono di colpo.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_instance_valid(_exit_button):
		return
	if event.is_action_pressed("ui_cancel"):
		_on_exit_pressed()
		get_viewport().set_input_as_handled()
		return
	# Frecce: l'alternativa da tastiera ai due lati dello scorrimento.
	if str(_swipe_item.get("format", "")) == "swipe" and not _answered:
		if event.is_action_pressed("ui_left"):
			_swipe_judge(false)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_swipe_judge(true)
			get_viewport().set_input_as_handled()

func _finish() -> void:
	var total := _nodes.size()
	var minimum_correct := int(session.get("minimumCorrect", ceili(float(total) * 0.5)))
	var passed := _shields > 0 and _correct >= minimum_correct
	# Nel finale la soglia numerica non basta: il tredicesimo posto viene
	# assegnato a chi ha risolto il nodo di sintesi. Senza questo vincolo si
	# potrebbe completare la campagna sbagliando proprio l'ultimo nodo.
	if bool(session.get("transversal", false)):
		passed = passed and is_instance_valid(_convergence_display) and _convergence_display.synthesis_resolved
	var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
	if audio != null:
		audio.call("set_focus", false)
		audio.call("play_event", "enigmaCompleted" if passed else "sessionDefeated")
	if passed:
		_energy += int(session.get("rewards", {}).get("onComplete", {}).get("energy", 0))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("delete document.documentElement.dataset.eliExercise;")
	session_finished.emit({
		"sessionId": str(session.get("sessionId", "")),
		"kind": str(session.get("kind", "mission")),
		"correct": _correct,
		"total": total,
		"passed": passed,
		"energyGained": _energy,
		"shieldsLeft": _shields,
		"subject": str(session.get("subject", "")),
		"seconds": maxf(0.0, float(Time.get_ticks_msec() - _started_at_msec) / 1000.0),
		"missed": _missed.duplicate(),
		"reviewedOk": _reviewed_ok.duplicate(),
		"systemsResolved": _systems_resolved.keys(),
		"synthesisResolved": is_instance_valid(_convergence_display) and _convergence_display.synthesis_resolved,
		# Esiti per-argomento della sessione: {topic: {"seen": n, "correct": k}}.
		# Alimentano la mastery per-topic (adattività fine dentro la materia).
		"topicStats": _build_topic_stats(),
	})

func _build_topic_stats() -> Dictionary:
	var stats: Dictionary = {}
	for topic in _topic_seen.keys():
		stats[topic] = {"seen": int(_topic_seen[topic]), "correct": int(_topic_correct.get(topic, 0))}
	return stats
