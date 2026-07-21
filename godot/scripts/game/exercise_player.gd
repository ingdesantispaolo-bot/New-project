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
var _answered := false
var _missed: Array = []       # topic sbagliati → ripasso spaziato
var _reviewed_ok: Array = []  # topic di ripasso risolti correttamente

var _prompt: Label
var _options: VBoxContainer
var _feedback: Label
var _status: Label
var _next_button: Button
var _input: LineEdit

func start_session(new_session: Dictionary) -> void:
	session = new_session
	_nodes = session.get("nodes", [])
	_index = 0
	_correct = 0
	_shields = int(session.get("shields", 3))
	_energy = 0
	_missed = []
	_reviewed_ok = []
	_energy_per_correct = int(session.get("rewards", {}).get("energyPerCorrect", 10))
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
	if _index >= _nodes.size():
		_finish()
		return
	var item: Dictionary = _nodes[_index]
	_status.text = "Esercizio %d/%d   ·   Scudi %d" % [_index + 1, _nodes.size(), _shields]
	_prompt.text = str(item.get("prompt", ""))
	for child in _options.get_children():
		child.queue_free()
	var fmt := str(item.get("format", "multiple_choice"))
	if fmt == "multiple_choice":
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
	else:
		_input.visible = true
		_input.text = ""
		_input.editable = true
		if is_inside_tree():
			_input.grab_focus()

func _answer(given: String) -> void:
	if _answered:
		return
	_answered = true
	_input.editable = false
	for child in _options.get_children():
		if child is Button:
			(child as Button).disabled = true
	var item: Dictionary = _nodes[_index]
	var topic := str(item.get("topic", ""))
	if given.strip_edges() == str(item.get("answer", "")).strip_edges():
		_correct += 1
		_energy += _energy_per_correct
		if bool(item.get("review", false)) and topic != "":
			_reviewed_ok.append(topic)
		_feedback.add_theme_color_override("font_color", Color("8ff6c0"))
		_feedback.text = "Giusto! +%d energia" % _energy_per_correct
	else:
		_shields -= 1
		if topic != "":
			_missed.append(topic)
		_feedback.add_theme_color_override("font_color", Color("ffb3ba"))
		_feedback.text = "Non corretto. %s" % str(item.get("explanation", ""))
	# La costruzione avanza di una campata per ogni risposta corretta (built =
	# _correct); su errore resta ferma, senza mai regredire.
	progress_changed.emit(_correct, _nodes.size())
	_next_button.text = "Fine" if _shields <= 0 else "Avanti"
	_next_button.visible = true

func _advance() -> void:
	if _shields <= 0:
		_finish()
		return
	_index += 1
	_show_current()

func _finish() -> void:
	var total := _nodes.size()
	var passed := _shields > 0 and _correct * 2 >= total
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
		"missed": _missed.duplicate(),
		"reviewedOk": _reviewed_ok.duplicate(),
	})
