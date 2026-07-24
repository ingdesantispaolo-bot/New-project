class_name ExercisePlayer
extends Control

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")
const EXERCISE_DRAG_BUTTON := preload("res://scripts/ui/exercise_drag_button.gd")
const EXERCISE_DROP_BUTTON := preload("res://scripts/ui/exercise_drop_button.gd")
const EXERCISE_CONNECTION_CANVAS := preload("res://scripts/ui/exercise_connection_canvas.gd")
const EXERCISE_DIAGRAM := preload("res://scripts/ui/exercise_diagram.gd")
const FINAL_CONVERGENCE_DISPLAY := preload("res://scripts/ui/final_convergence_display.gd")

## UI data-driven degli esercizi: riceve una sessione (missione o esame finale) e
## la gioca item per item. Supporta scelta/input, ordering, matching,
## classificazione, hotspot, grafici, circuiti e code-debug. Emette
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
## Emesso dal solo esame trasversale: ogni nodo completato accende il sistema
## corrispondente, indipendentemente dall'esito usato poi per il punteggio.
signal system_resolved(system: String, correct: bool, resolved: int, total_systems: int)
## Richiesta esplicita di aiuto sul concetto corrente. La scena apre il Manuale
## NORA sopra la sessione senza ricrearla; negli esami il pulsante non compare.
signal concept_help_requested(subject: String, topic: String)
## Segnali di apprendimento/relazione privi di effetti economici. Il consumer
## semantico decide come persisterli nello stato NORA.
signal learning_signal(signal_name: String)

var session: Dictionary
var _nodes: Array = []
var _index := 0
var _correct := 0
var _shields := 3
var _energy := 0
var _energy_per_correct := 10
var _started_at_msec := 0
var _answered := false
var _missed: Array = []       # topic sbagliati → ripasso spaziato
var _reviewed_ok: Array = []  # topic di ripasso risolti correttamente
var _topic_seen: Dictionary = {}     # topic -> item incontrati (per mastery per-topic)
var _topic_correct: Dictionary = {}  # topic -> risposte corrette
var _wrong_attempts: Dictionary = {}  # topic -> tentativi errati nella sessione
var _learning_emitted: Dictionary = {}
var _systems_resolved: Dictionary = {}

var _prompt: Label
var _options: VBoxContainer
var _feedback: Label
var _status: Label
var _next_button: Button
var _help_button: Button
var _input: LineEdit
var _convergence_display: FinalConvergenceDisplay

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
var _visual_selected := ""
var _visual_buttons: Dictionary = {}
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
	_started_at_msec = Time.get_ticks_msec()
	_missed = []
	_reviewed_ok = []
	_topic_seen = {}
	_topic_correct = {}
	_wrong_attempts = {}
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

	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_top = 0.04
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.96
	panel.custom_minimum_size = Vector2(640, 480)
	var is_exam := str(session.get("kind", "mission")) == "final_exam"
	panel.add_theme_stylebox_override("panel", _exercise_panel_style(is_exam))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var heading := Label.new()
	heading.name = "ExerciseHeading"
	var transversal := bool(session.get("transversal", false))
	var heading_kind := "PROVA NORA" if str(session.get("kind", "mission")) == "mission" else ("ENIGMA NORA" if str(session.get("kind", "mission")) == "enigma" else "APPARATO · ESAME FINALE")
	heading.text = "CUORE DEI PRIMI · PROVA TRASVERSALE" if transversal else "%s  ·  %s" % [heading_kind, str(session.get("subject", "matematica")).capitalize()]
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
		_convergence_display.setup(Array(session.get("systems", [])))
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

	var options_scroll := ScrollContainer.new()
	options_scroll.name = "ExerciseOptionsScroll"
	options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	options_scroll.custom_minimum_size.y = 180
	box.add_child(options_scroll)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_scroll.add_child(_options)

	_input = LineEdit.new()
	_input.placeholder_text = "Scrivi la risposta e premi Invio"
	_input.visible = false
	_input.text_submitted.connect(func(text): _answer(text))
	box.add_child(_input)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_feedback)

	_help_button = Button.new()
	_help_button.name = "ConceptHelpButton"
	_help_button.text = "SPIEGA CON NORA"
	_help_button.visible = false
	_help_button.custom_minimum_size = Vector2(0, 44)
	_help_button.add_theme_color_override("font_color", Color("06272a"))
	_help_button.add_theme_stylebox_override("normal", _exercise_button_style(Color("6be7d6"), Color("d8fff8")))
	_help_button.pressed.connect(_request_concept_help)
	box.add_child(_help_button)

	_next_button = Button.new()
	_next_button.text = "Avanti"
	_next_button.visible = false
	_next_button.custom_minimum_size = Vector2(0, 42)
	_next_button.add_theme_font_size_override("font_size", 16)
	_next_button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.16, 0.32, 0.30, 0.98), Color(0.96, 0.78, 0.36, 0.72)))
	_next_button.pressed.connect(_advance)
	box.add_child(_next_button)

func _exercise_panel_style(is_exam: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.10, 0.98) if is_exam else Color(0.025, 0.10, 0.12, 0.96)
	style.border_color = Color.WHITE if high_contrast else Color("f6c85f") if is_exam else Color(0.42, 0.9, 0.84, 0.48)
	style.set_border_width_all(4 if high_contrast else 3 if is_exam else 2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	return style

func _exercise_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.WHITE if high_contrast else border
	style.set_border_width_all(3 if high_contrast else 1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	return style

func _show_current() -> void:
	_answered = false
	_feedback.text = ""
	_next_button.visible = false
	if is_instance_valid(_help_button):
		_help_button.visible = false
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
	_visual_selected = ""
	_visual_buttons = {}
	if _index >= _nodes.size():
		_finish()
		return
	var item: Dictionary = _nodes[_index]
	_refresh_status()
	_prompt.text = str(item.get("prompt", ""))
	for child in _options.get_children():
		child.queue_free()
	var fmt := str(item.get("format", "multiple_choice"))
	match fmt:
		"ordering":
			_input.visible = false
			_build_ordering(item)
		"matching":
			_input.visible = false
			_build_matching(item)
		"classification":
			_input.visible = false
			_build_classification(item)
		"hotspot", "graph", "circuit":
			_input.visible = false
			_build_visual_selection(item, fmt)
		"code_debug":
			_input.visible = false
			_build_code_debug(item)
		"multiple_choice":
			_input.visible = false
			for option in item.get("options", []):
				var button := Button.new()
				button.text = str(option)
				button.custom_minimum_size = Vector2(0, 42)
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
			if is_inside_tree():
				_input.grab_focus()

func _refresh_status() -> void:
	if is_instance_valid(_status):
		if bool(session.get("transversal", false)) and _index < _nodes.size():
			var system := str((_nodes[_index] as Dictionary).get("system", "sintesi")).replace("_", " ").capitalize()
			_status.text = "Sistema %d/%d · %s   ·   Stabilità %d" % [_index + 1, _nodes.size(), system, _shields]
		else:
			_status.text = "Esercizio %d/%d   ·   Scudi %d" % [_index + 1, _nodes.size(), _shields]

func _answer(given: String) -> void:
	if _answered:
		return
	var item: Dictionary = _nodes[_index]
	var is_correct := ExerciseInteraction.answers_equivalent(given, str(item.get("answer", "")))
	if not is_correct:
		_spend_shield()
		_register_wrong_attempt(item)
	_score_current(is_correct, item)

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
		_feedback.text = "Giusto! +%d energia" % _energy_per_correct
	else:
		var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
		if audio != null:
			audio.call("play_event", "answerWrong")
		if topic != "":
			_missed.append(topic)
		_feedback.add_theme_color_override("font_color", Color("ffb3ba"))
		_feedback.text = "Non completato. %s" % str(item.get("explanation", ""))
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
		system_resolved.emit(system, is_correct, _systems_resolved.size(), int(Array(session.get("systems", [])).size()))
	_next_button.text = "Fine" if _shields <= 0 else "Avanti"
	_next_button.visible = true

func _lock_interactions() -> void:
	_input.editable = false
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
		button.custom_minimum_size = Vector2(150, 46)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("e7fff8"))
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
		button.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
		button.tooltip_text = "Elemento %s: trascina o premi Invio per inserirlo" % str(elements[i])
		button.call("configure", str(i), "ordering")
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
		slot.custom_minimum_size = Vector2(0, 44)
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

func _ordering_clear_slot(slot_index: int) -> void:
	if _answered or slot_index < 0 or slot_index >= _ordering_state.size():
		return
	var source := str(_ordering_state[slot_index])
	if source == "":
		return
	_ordering_state[slot_index] = ""
	(_mg_buttons[int(source)] as Button).disabled = false
	_refresh_ordering_slots()

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
		lb.pressed.connect(_matching_left.bind(i))
		left_col.add_child(lb)
		_mg_left_buttons.append(lb)
	var rights: Array = []
	for p in pairs:
		rights.append(str((p as Dictionary).get("right", "")))
	_shuffle(rights, _rng)
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
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("e7fff8"))
	b.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
	b.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
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
				break
		_mg_matched += 1
		_mg_selected_left = -1
		if _mg_matched >= pairs.size():
			_score_current(true, item)
	else:
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
		button.custom_minimum_size = Vector2(150, 46)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.96), Color("527980")))
		button.call("configure", key, "classification")
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

# --- HOTSPOT / GRAFICO / CIRCUITO (selezione su superficie diegetica) ---------
func _build_visual_selection(item: Dictionary, fmt: String) -> void:
	var instruction := Label.new()
	instruction.text = {
		"hotspot": "Seleziona il punto corretto nell'immagine.",
		"graph": "Leggi assi e andamento, poi seleziona il punto richiesto.",
		"circuit": "Osserva i collegamenti e seleziona il componente richiesto.",
	}.get(fmt, "Seleziona il punto corretto.")
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var diagram := EXERCISE_DIAGRAM.new()
	diagram.name = "ExerciseDiagram_%s" % fmt
	diagram.call("configure", fmt, item)
	_options.add_child(diagram)
	var points: Array = item.get("hotspots", []) if fmt == "hotspot" else item.get("points", []) if fmt == "graph" else item.get("components", [])
	for point in points:
		var spec := point as Dictionary
		var id := str(spec.get("id", ""))
		var button := Button.new()
		button.name = "VisualChoice_%s" % id.validate_node_name()
		button.text = str(spec.get("label", id))
		button.tooltip_text = str(spec.get("description", button.text))
		button.custom_minimum_size = Vector2(74, 42)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.03, 0.15, 0.18, 0.96), Color("f6c85f")))
		var normalized := _diagram_anchor(spec, fmt)
		button.anchor_left = normalized.x
		button.anchor_right = normalized.x
		button.anchor_top = normalized.y
		button.anchor_bottom = normalized.y
		button.offset_left = -48
		button.offset_right = 48
		button.offset_top = -23
		button.offset_bottom = 23
		button.pressed.connect(_visual_select.bind(id))
		diagram.add_child(button)
		_visual_buttons[id] = button
	_add_interaction_actions(_visual_clear, _visual_submit.bind(item))

func _diagram_anchor(spec: Dictionary, fmt: String) -> Vector2:
	var x := clampf(float(spec.get("x", 0.5)), 0.05, 0.95)
	var y := clampf(float(spec.get("y", 0.5)), 0.05, 0.95)
	if fmt == "graph":
		return Vector2(0.12 + x * 0.80, 0.82 - y * 0.68)
	return Vector2(x, y)

func _visual_select(id: String) -> void:
	if _answered:
		return
	_visual_selected = id
	for key in _visual_buttons.keys():
		var button := _visual_buttons[key] as Button
		button.modulate = Color("f6c85f") if str(key) == id else Color.WHITE
	_flash_feedback("Selezione: %s. Verifica quando sei sicuro." % str((_visual_buttons[id] as Button).text))

func _visual_clear() -> void:
	_visual_selected = ""
	for button in _visual_buttons.values():
		(button as Button).modulate = Color.WHITE

func _visual_submit(item: Dictionary) -> void:
	if _visual_selected == "":
		_flash_feedback("Seleziona prima un punto.")
		return
	_retryable_result(_visual_selected == str(item.get("answer", "")), item, "Quel punto non spiega il fenomeno: osserva di nuovo la struttura.")

# --- CODE DEBUG (righe selezionabili, numerate e leggibili da tastiera) --------
func _build_code_debug(item: Dictionary) -> void:
	var instruction := Label.new()
	instruction.text = "Seleziona la riga che contiene l'errore. Il numero di riga è parte dell'indizio."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("b8d7dc"))
	_options.add_child(instruction)
	var lines: Array = item.get("codeLines", [])
	for index in lines.size():
		var line_number := index + 1
		var button := Button.new()
		button.name = "CodeLine_%02d" % line_number
		button.text = "%02d  │  %s" % [line_number, str(lines[index])]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.025, 0.08, 0.10, 0.98), Color("527980")))
		button.pressed.connect(_code_line_select.bind(line_number))
		_options.add_child(button)
		_visual_buttons[str(line_number)] = button
	_add_interaction_actions(_visual_clear, _code_submit.bind(item))

func _code_line_select(line_number: int) -> void:
	_visual_select(str(line_number))

func _code_submit(item: Dictionary) -> void:
	if _visual_selected == "":
		_flash_feedback("Seleziona prima una riga.")
		return
	_retryable_result(int(_visual_selected) == int(item.get("answerLine", 0)), item, "Quella riga è valida: segui i valori passo per passo e riprova.")

func _add_interaction_actions(undo_callback: Callable, submit_callback: Callable) -> void:
	var actions := HBoxContainer.new()
	actions.name = "InteractionActions"
	actions.add_theme_constant_override("separation", 10)
	var undo := Button.new()
	undo.name = "InteractionUndo"
	undo.text = "ANNULLA"
	undo.custom_minimum_size = Vector2(140, 44)
	undo.focus_mode = Control.FOCUS_ALL
	undo.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.09, 0.15, 0.18, 0.96), Color("75999f")))
	undo.pressed.connect(undo_callback)
	actions.add_child(undo)
	var submit := Button.new()
	submit.name = "InteractionSubmit"
	submit.text = "VERIFICA"
	submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit.custom_minimum_size = Vector2(180, 44)
	submit.focus_mode = Control.FOCUS_ALL
	submit.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.13, 0.38, 0.32, 1.0), Color("8ff6d2")))
	submit.pressed.connect(submit_callback)
	actions.add_child(submit)
	_options.add_child(actions)

func _retryable_result(correct: bool, item: Dictionary, retry_message: String) -> void:
	if correct:
		_score_current(true, item)
		return
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

func _offer_concept_help(item: Dictionary) -> void:
	if not is_instance_valid(_help_button):
		return
	# In esame la soluzione corrente non deve essere raggiungibile dalla prova.
	_help_button.visible = str(session.get("kind", "mission")) != "final_exam" and str(item.get("topic", "")) != ""

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

func _finish() -> void:
	var total := _nodes.size()
	var minimum_correct := int(session.get("minimumCorrect", ceili(float(total) * 0.5)))
	var passed := _shields > 0 and _correct >= minimum_correct
	var audio := get_tree().root.get_node_or_null("NativeAudio") if is_inside_tree() else null
	if audio != null:
		audio.call("set_focus", false)
		audio.call("play_event", "enigmaCompleted" if passed else "sessionDefeated")
	if passed:
		_energy += int(session.get("rewards", {}).get("onComplete", {}).get("energy", 0))
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
