class_name ExercisePlayer
extends Control

## UI data-driven degli esercizi: riceve una sessione (missione o esame finale) e
## la gioca item per item. Supporta scelta multipla e inserimento. Emette
## `session_finished` con l'esito. Vedi docs/DESIGN_COMPLETO.md §6.
##
## Politica errore: un errore toglie uno scudo e mostra la spiegazione; a scudi
## esauriti la sessione fallisce e va ripetuta (nessun progresso cancellato).

signal session_finished(result: Dictionary)

var session: Dictionary
var _nodes: Array = []
var _index := 0
var _correct := 0
var _shields := 3
var _energy := 0
var _energy_per_correct := 10
var _answered := false

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
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

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
	_next_button.pressed.connect(_advance)
	box.add_child(_next_button)

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
			button.pressed.connect(_answer.bind(str(option)))
			_options.add_child(button)
	else:
		_input.visible = true
		_input.text = ""
		_input.editable = true
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
	if given.strip_edges() == str(item.get("answer", "")).strip_edges():
		_correct += 1
		_energy += _energy_per_correct
		_feedback.add_theme_color_override("font_color", Color("8ff6c0"))
		_feedback.text = "Giusto! +%d energia" % _energy_per_correct
	else:
		_shields -= 1
		_feedback.add_theme_color_override("font_color", Color("ffb3ba"))
		_feedback.text = "Non corretto. %s" % str(item.get("explanation", ""))
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
		"correct": _correct,
		"total": total,
		"passed": passed,
		"energyGained": _energy,
		"shieldsLeft": _shields,
		"subject": str(session.get("subject", "")),
	})
