class_name ExercisePlayer
extends Control

## UI data-driven degli esercizi: riceve una sessione (missione o esame finale) e
## la gioca item per item. Supporta scelta multipla e inserimento. Emette
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

var _prompt: Label
var _options: VBoxContainer
var _feedback: Label
var _status: Label
var _next_button: Button
var _input: LineEdit

# Stato dei minigiochi interattivi (formati "ordering" e "matching"). Ogni nodo
# minigioco vale come un esercizio: risolverlo = 1 corretto; gli errori intermedi
# tolgono scudi come una risposta sbagliata.
var _mg_buttons: Array = []       # ordering: pulsanti degli elementi da ordinare
var _mg_left_buttons: Array = []  # matching: colonna sinistra
var _mg_right_buttons: Array = [] # matching: colonna destra (mescolata)
var _mg_expected := 0             # ordering: prossima posizione da riempire
var _mg_selected_left := -1       # matching: indice sinistra selezionato
var _mg_matched := 0              # matching: coppie completate
var _rng: RandomNumberGenerator

func start_session(new_session: Dictionary) -> void:
	session = new_session
	_nodes = session.get("nodes", [])
	_index = 0
	_correct = 0
	_shields = int(session.get("shields", 3))
	_energy = 0
	_started_at_msec = Time.get_ticks_msec()
	_missed = []
	_reviewed_ok = []
	_topic_seen = {}
	_topic_correct = {}
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
		child.queue_free()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.07, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(660, 440)
	panel.add_theme_stylebox_override("panel", _exercise_panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var heading := Label.new()
	var heading_kind := "PROVA NORA" if str(session.get("kind", "mission")) == "mission" else ("ENIGMA NORA" if str(session.get("kind", "mission")) == "enigma" else "APPARATO · ESAME FINALE")
	heading.text = "%s  ·  %s" % [heading_kind, str(session.get("subject", "matematica")).capitalize()]
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("6be7d6"))
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

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color("f6c85f"))
	box.add_child(_status)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.custom_minimum_size = Vector2(620, 0)
	box.add_child(_prompt)

	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	box.add_child(_options)

	_input = LineEdit.new()
	_input.placeholder_text = "Scrivi la risposta e premi Invio"
	_input.visible = false
	_input.text_submitted.connect(func(text): _answer(text))
	box.add_child(_input)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size = Vector2(620, 0)
	box.add_child(_feedback)

	_next_button = Button.new()
	_next_button.text = "Avanti"
	_next_button.visible = false
	_next_button.custom_minimum_size = Vector2(0, 42)
	_next_button.add_theme_font_size_override("font_size", 16)
	_next_button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.16, 0.32, 0.30, 0.98), Color(0.96, 0.78, 0.36, 0.72)))
	_next_button.pressed.connect(_advance)
	box.add_child(_next_button)

func _exercise_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.10, 0.12, 0.96)
	style.border_color = Color(0.42, 0.9, 0.84, 0.48)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	return style

func _exercise_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	return style

func _show_current() -> void:
	_answered = false
	_feedback.text = ""
	_next_button.visible = false
	_mg_expected = 0
	_mg_selected_left = -1
	_mg_matched = 0
	_mg_buttons = []
	_mg_left_buttons = []
	_mg_right_buttons = []
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
		_status.text = "Esercizio %d/%d   ·   Scudi %d" % [_index + 1, _nodes.size(), _shields]

func _answer(given: String) -> void:
	if _answered:
		return
	var item: Dictionary = _nodes[_index]
	var is_correct := given.strip_edges() == str(item.get("answer", "")).strip_edges()
	if not is_correct:
		_shields -= 1
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
	# La costruzione avanza di una campata per ogni nodo risolto (built = _correct);
	# su errore resta ferma, senza mai regredire.
	progress_changed.emit(_correct, _nodes.size())
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

# --- Minigioco: ORDINAMENTO (tocca gli elementi nell'ordine giusto) -----------
func _build_ordering(item: Dictionary) -> void:
	var elements: Array = item.get("items", [])
	for i in elements.size():
		var button := Button.new()
		button.text = str(elements[i])
		button.custom_minimum_size = Vector2(0, 42)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("e7fff8"))
		button.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
		button.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
		button.pressed.connect(_ordering_click.bind(i, item))
		_options.add_child(button)
		_mg_buttons.append(button)

func _ordering_click(i: int, item: Dictionary) -> void:
	if _answered:
		return
	var button: Button = _mg_buttons[i]
	if button.disabled:
		return
	var correct: Array = item.get("correctOrder", [])
	if _mg_expected < correct.size() and str(button.text) == str(correct[_mg_expected]):
		button.disabled = true
		button.modulate = Color(0.6, 1.0, 0.75)
		_mg_expected += 1
		if _mg_expected >= correct.size():
			_score_current(true, item)
	else:
		_shields -= 1
		_refresh_status()
		_flash_feedback("Non è l'ordine giusto: riprova.")
		if _shields <= 0:
			_score_current(false, item)

# --- Minigioco: ABBINAMENTO (collega ogni elemento sinistra al suo destra) -----
func _build_matching(item: Dictionary) -> void:
	var pairs: Array = item.get("pairs", [])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)
	for i in pairs.size():
		var lb := _matching_button(str((pairs[i] as Dictionary).get("left", "")))
		lb.pressed.connect(_matching_left.bind(i))
		left_col.add_child(lb)
		_mg_left_buttons.append(lb)
	var rights: Array = []
	for p in pairs:
		rights.append(str((p as Dictionary).get("right", "")))
	_shuffle(rights, _rng)
	for j in rights.size():
		var rb := _matching_button(str(rights[j]))
		rb.pressed.connect(_matching_right.bind(str(rights[j]), item))
		right_col.add_child(rb)
		_mg_right_buttons.append(rb)
	row.add_child(left_col)
	row.add_child(right_col)
	_options.add_child(row)

func _matching_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 40)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("e7fff8"))
	b.add_theme_stylebox_override("normal", _exercise_button_style(Color(0.08, 0.22, 0.23, 0.92), Color(0.42, 0.9, 0.84, 0.28)))
	b.add_theme_stylebox_override("hover", _exercise_button_style(Color(0.12, 0.34, 0.31, 0.98), Color(0.52, 0.96, 0.78, 0.75)))
	return b

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
				break
		_mg_matched += 1
		_mg_selected_left = -1
		if _mg_matched >= pairs.size():
			_score_current(true, item)
	else:
		_shields -= 1
		_refresh_status()
		_flash_feedback("Coppia sbagliata: riprova.")
		if _mg_selected_left >= 0 and not _mg_left_buttons[_mg_selected_left].disabled:
			_mg_left_buttons[_mg_selected_left].modulate = Color(1, 1, 1)
		_mg_selected_left = -1
		if _shields <= 0:
			_score_current(false, item)

# Feedback temporaneo durante un minigioco (senza chiudere il nodo).
func _flash_feedback(message: String) -> void:
	if is_instance_valid(_feedback):
		_feedback.add_theme_color_override("font_color", Color("ffd37a"))
		_feedback.text = message

func _advance() -> void:
	if _shields <= 0:
		_finish()
		return
	_index += 1
	_show_current()

func _finish() -> void:
	var total := _nodes.size()
	var passed := _shields > 0 and _correct * 2 >= total
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
		# Esiti per-argomento della sessione: {topic: {"seen": n, "correct": k}}.
		# Alimentano la mastery per-topic (adattività fine dentro la materia).
		"topicStats": _build_topic_stats(),
	})

func _build_topic_stats() -> Dictionary:
	var stats: Dictionary = {}
	for topic in _topic_seen.keys():
		stats[topic] = {"seen": int(_topic_seen[topic]), "correct": int(_topic_correct.get(topic, 0))}
	return stats
