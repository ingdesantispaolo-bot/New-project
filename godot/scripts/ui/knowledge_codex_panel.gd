class_name KnowledgeCodexPanel
extends Control

## Interfaccia del Manuale NORA. Consuma il contratto didattico KnowledgeCodex
## senza calcolare mastery, ricompense o gate. Lo stato UI dei preferiti vive in
## `codexUi`, separato dagli stati semantici `codex` posseduti dalla didattica.

const KNOWLEDGE_CODEX := preload("res://scripts/game/knowledge_codex.gd")
const NORA_PORTRAIT := preload("res://scripts/ui/nora_portrait.gd")

signal panel_closed

var game_save
var codex: KnowledgeCodex
var context := "practice"
var requested_subject := ""
var requested_topic := ""
var selected_key := ""
var demo_step := 0

var search_field: LineEdit
var subject_filter: OptionButton
var favorites_filter: CheckButton
var entry_list: VBoxContainer
var detail_box: VBoxContainer
var result_count: Label
var nora_portrait: NoraPortrait
var _subject_ids: Array[String] = []

func setup(save_manager, content_manager: ContentManager = null) -> void:
	game_save = save_manager
	codex = KNOWLEDGE_CODEX.new(content_manager)
	_ensure_ui_state()
	_build_ui()

func _ensure_ui_state() -> Dictionary:
	if game_save == null:
		return {"favorites": []}
	if not game_save.data.has("codexUi"):
		game_save.data["codexUi"] = {"favorites": []}
	var ui_state: Dictionary = game_save.data["codexUi"]
	if not ui_state.has("favorites"):
		ui_state["favorites"] = []
	return ui_state

func mark_encountered(subject: String, topics: Array) -> void:
	if game_save == null:
		return
	for topic in topics:
		KNOWLEDGE_CODEX.advance_state(game_save, subject, str(topic), "seen")
	game_save.save()

func open_codex(subject: String = "", topic: String = "", use_context: String = "practice") -> void:
	if codex == null:
		return
	context = use_context
	requested_subject = subject
	requested_topic = topic
	search_field.text = ""
	favorites_filter.button_pressed = false
	_select_subject_filter(subject)
	var key := _key(subject, topic)
	var has_requested_entry := topic != "" and codex.runtime_topics().has(key)
	if has_requested_entry:
		# Impedisce a `_refresh_list` di costruire prima un dettaglio provvisorio:
		# due render nello stesso frame lascerebbero nodi in coda di eliminazione
		# con nomi duplicati, rendendo fragile focus e automazione accessibile.
		selected_key = key
	visible = true
	_refresh_list()
	if has_requested_entry:
		_select_entry(subject, topic)
	elif selected_key == "":
		_select_first_visible()
	search_field.grab_focus()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.open")

func close_panel() -> void:
	if not visible:
		return
	visible = false
	panel_closed.emit()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.close")

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	name = "KnowledgeCodexPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.018, 0.03, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 18)
	safe.add_theme_constant_override("margin_top", 16)
	safe.add_theme_constant_override("margin_right", 18)
	safe.add_theme_constant_override("margin_bottom", 16)
	add_child(safe)

	var panel := PanelContainer.new()
	panel.name = "CodexSurface"
	panel.add_theme_stylebox_override("panel", _panel_style())
	safe.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)
	nora_portrait = NORA_PORTRAIT.new()
	nora_portrait.custom_minimum_size = Vector2(74, 74)
	NoraState.sync_from_progress(game_save)
	nora_portrait.set_integrity(NoraState.integrity(game_save), false, NoraState.trust(game_save))
	header.add_child(nora_portrait)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := Label.new()
	title.text = "MANUALE NORA · MEMORIA DIDATTICA"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("e9fffb"))
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Spiegazioni, esempi svolti, errori tipici e strategie. I dati restano sul dispositivo."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("9fc4bb"))
	title_box.add_child(subtitle)
	var close := Button.new()
	close.name = "CloseCodexButton"
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(104, 48)
	close.pressed.connect(close_panel)
	header.add_child(close)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 10)
	layout.add_child(filters)
	search_field = LineEdit.new()
	search_field.name = "CodexSearch"
	search_field.placeholder_text = "Cerca un concetto, una materia o una spiegazione…"
	search_field.clear_button_enabled = true
	search_field.custom_minimum_size = Vector2(270, 46)
	search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_field.text_changed.connect(func(_value): _refresh_list())
	filters.add_child(search_field)
	subject_filter = OptionButton.new()
	subject_filter.name = "CodexSubjectFilter"
	subject_filter.custom_minimum_size = Vector2(190, 46)
	subject_filter.item_selected.connect(func(_index): _refresh_list())
	filters.add_child(subject_filter)
	favorites_filter = CheckButton.new()
	favorites_filter.name = "CodexFavoritesFilter"
	favorites_filter.text = "★ PREFERITI"
	favorites_filter.custom_minimum_size = Vector2(150, 46)
	favorites_filter.toggled.connect(func(_enabled): _refresh_list())
	filters.add_child(favorites_filter)

	var body := HSplitContainer.new()
	body.name = "CodexBody"
	body.split_offset = 285
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var index_panel := VBoxContainer.new()
	index_panel.custom_minimum_size.x = 245
	body.add_child(index_panel)
	result_count = Label.new()
	result_count.add_theme_color_override("font_color", Color("6be7d6"))
	index_panel.add_child(result_count)
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	index_panel.add_child(list_scroll)
	entry_list = VBoxContainer.new()
	entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_list.add_theme_constant_override("separation", 5)
	list_scroll.add_child(entry_list)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "CodexDetailScroll"
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_scroll)
	detail_box = VBoxContainer.new()
	detail_box.name = "CodexDetail"
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(detail_box)
	_rebuild_subject_filter()

func _rebuild_subject_filter() -> void:
	subject_filter.clear()
	_subject_ids = [""]
	subject_filter.add_item("Tutte le materie")
	var subjects: Array[String] = []
	for value in codex.runtime_topics().values():
		var subject := str(value.get("subject", ""))
		if subject != "" and not subjects.has(subject):
			subjects.append(subject)
	subjects.sort()
	for subject in subjects:
		_subject_ids.append(subject)
		subject_filter.add_item(subject.capitalize())

func _select_subject_filter(subject: String) -> void:
	var index := _subject_ids.find(subject)
	subject_filter.select(maxi(0, index))

func _refresh_list() -> void:
	if codex == null or entry_list == null:
		return
	for child in entry_list.get_children():
		child.queue_free()
	var query := search_field.text.strip_edges().to_lower()
	var subject := _subject_ids[subject_filter.selected] if subject_filter.selected >= 0 and subject_filter.selected < _subject_ids.size() else ""
	var favorites: Array = _ensure_ui_state().get("favorites", [])
	var entries: Array = []
	for value in codex.runtime_topics().values():
		var meta: Dictionary = value
		var entry := codex.entry_for(str(meta.get("subject", "")), str(meta.get("topic", "")))
		var key := _key(str(entry.get("subject", "")), str(entry.get("topic", "")))
		var haystack := "%s %s %s" % [entry.get("subject", ""), entry.get("topic", ""), entry.get("shortExplanation", "")]
		if subject != "" and str(entry.get("subject", "")) != subject:
			continue
		if favorites_filter.button_pressed and not favorites.has(key):
			continue
		if query != "" and query not in haystack.to_lower():
			continue
		entries.append(entry)
	entries.sort_custom(func(a, b): return _key(str(a.get("subject", "")), str(a.get("topic", ""))) < _key(str(b.get("subject", "")), str(b.get("topic", ""))))
	result_count.text = "%d CONCETTI" % entries.size()
	for entry in entries:
		var key := _key(str(entry.get("subject", "")), str(entry.get("topic", "")))
		var button := Button.new()
		button.name = "Concept_%s" % key.replace(":", "_").replace("-", "_")
		var star := "★" if favorites.has(key) else "·"
		var state := KNOWLEDGE_CODEX.state_of(game_save, str(entry.get("subject", "")), str(entry.get("topic", "")))
		button.text = "%s  %s\n%s · %s" % [star, _title(str(entry.get("topic", ""))), str(entry.get("subject", "")).capitalize(), _state_label(state)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 58)
		button.tooltip_text = "Apri %s" % _title(str(entry.get("topic", "")))
		button.pressed.connect(_select_entry.bind(str(entry.get("subject", "")), str(entry.get("topic", ""))))
		entry_list.add_child(button)
	if entries.is_empty():
		_show_empty("Nessun concetto corrisponde ai filtri.")
	elif selected_key == "" or not _visible_entry_exists(entries, selected_key):
		var first: Dictionary = entries[0]
		_select_entry(str(first.get("subject", "")), str(first.get("topic", "")))

func _visible_entry_exists(entries: Array, key: String) -> bool:
	for entry in entries:
		if _key(str(entry.get("subject", "")), str(entry.get("topic", ""))) == key:
			return true
	return false

func _select_first_visible() -> void:
	for child in entry_list.get_children():
		if child is Button:
			(child as Button).pressed.emit()
			return

func _select_entry(subject: String, topic: String) -> void:
	selected_key = _key(subject, topic)
	demo_step = 0
	KNOWLEDGE_CODEX.advance_state(game_save, subject, topic, "consulted")
	game_save.save()
	_render_detail(codex.entry_for_context(subject, topic, context))

func _render_detail(entry: Dictionary) -> void:
	for child in detail_box.get_children():
		child.queue_free()
	var subject := str(entry.get("subject", ""))
	var topic := str(entry.get("topic", ""))
	var heading_row := HBoxContainer.new()
	detail_box.add_child(heading_row)
	var heading := Label.new()
	heading.text = _title(topic)
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("f6c85f"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var favorite := Button.new()
	favorite.name = "ToggleCodexFavorite"
	favorite.text = "★ SALVATO" if _is_favorite(selected_key) else "☆ SALVA"
	favorite.custom_minimum_size = Vector2(126, 46)
	favorite.pressed.connect(_toggle_favorite.bind(selected_key))
	heading_row.add_child(favorite)
	_add_label("%s · difficoltà %d · %s" % [subject.capitalize(), int(entry.get("difficulty", 1)), _state_label(KNOWLEDGE_CODEX.state_of(game_save, subject, topic))], Color("6be7d6"), 13)
	_add_section("IN BREVE", str(entry.get("shortExplanation", "")))

	var example: Dictionary = entry.get("example", {})
	var example_intro := str(example.get("prompt", "")).strip_edges()
	if example_intro == "" and not bool(entry.get("answerHidden", false)):
		example_intro = str(example.get("answer", "")).strip_edges()
	if example_intro == "":
		example_intro = "Applica il metodo un passaggio alla volta."
	_add_section("ESEMPIO GUIDATO", example_intro)
	var demo := Button.new()
	demo.name = "CodexDemoStep"
	demo.text = "MOSTRA PASSO 1"
	demo.custom_minimum_size = Vector2(210, 46)
	demo.pressed.connect(_advance_demo.bind(entry, demo))
	detail_box.add_child(demo)
	var demo_output := Label.new()
	demo_output.name = "CodexDemoOutput"
	demo_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	demo_output.add_theme_color_override("font_color", Color("dffcf6"))
	demo_output.set_meta("entry", entry)
	detail_box.add_child(demo_output)
	if bool(entry.get("answerHidden", false)):
		_add_label("Durante l’esame NORA mostra il metodo, non la soluzione corrente.", Color("ffd37a"), 13)

	var typical: Dictionary = entry.get("typicalError", {})
	var error_text := str(typical.get("wrong", "")).strip_edges()
	var why_text := str(typical.get("why", "")).strip_edges()
	if error_text == "":
		error_text = "Nessun errore tipico validato per questa voce."
	if why_text != "":
		error_text += "\nPerché: %s" % why_text
	_add_section("ERRORE TIPICO", error_text)
	_add_section("STRATEGIA DI NORA", str(entry.get("noraStrategy", "")))
	if is_instance_valid(nora_portrait):
		nora_portrait.speak(str(entry.get("noraStrategy", "")))
	_add_related(subject, topic)

func _advance_demo(entry: Dictionary, button: Button) -> void:
	var output := detail_box.get_node_or_null("CodexDemoOutput") as Label
	if output == null:
		return
	var example: Dictionary = entry.get("example", {})
	var steps := [
		"1 · Individua che cosa chiede il problema:\n%s" % str(example.get("prompt", "Rileggi il concetto.")),
		"2 · Applica la strategia di NORA:\n%s" % str(entry.get("noraStrategy", "")),
	]
	if not bool(entry.get("answerHidden", false)):
		steps.append("3 · Confronta il risultato:\n%s\n%s" % [str(example.get("answer", "")), str(example.get("explanation", ""))])
	demo_step = (demo_step + 1) % (steps.size() + 1)
	if demo_step == 0:
		output.text = ""
		button.text = "MOSTRA PASSO 1"
	else:
		output.text = str(steps[demo_step - 1])
		button.text = "MOSTRA PASSO %d" % (demo_step + 1) if demo_step < steps.size() else "RICOMINCIA"

func _add_related(subject: String, topic: String) -> void:
	_add_label("CONCETTI COLLEGATI", Color("6be7d6"), 14)
	var related := HFlowContainer.new()
	related.name = "CodexRelated"
	related.add_theme_constant_override("h_separation", 8)
	related.add_theme_constant_override("v_separation", 8)
	detail_box.add_child(related)
	var added := 0
	for value in codex.runtime_topics().values():
		if str(value.get("subject", "")) != subject or str(value.get("topic", "")) == topic:
			continue
		var button := Button.new()
		button.text = _title(str(value.get("topic", "")))
		button.custom_minimum_size.y = 44
		button.pressed.connect(_select_entry.bind(subject, str(value.get("topic", ""))))
		related.add_child(button)
		added += 1
		if added >= 6:
			break
	if added == 0:
		var none := Label.new()
		none.text = "Nessun collegamento ancora disponibile."
		related.add_child(none)

func _toggle_favorite(key: String) -> void:
	var ui_state := _ensure_ui_state()
	var favorites: Array = ui_state.get("favorites", [])
	if favorites.has(key):
		favorites.erase(key)
	else:
		favorites.append(key)
	ui_state["favorites"] = favorites
	game_save.save()
	var parts := key.split(":", true, 1)
	_refresh_list()
	if parts.size() == 2:
		_select_entry(parts[0], parts[1])

func _is_favorite(key: String) -> bool:
	return Array(_ensure_ui_state().get("favorites", [])).has(key)

func _show_empty(message: String) -> void:
	for child in detail_box.get_children():
		child.queue_free()
	_add_label(message, Color("9fc4bb"), 16)

func _add_section(title: String, text: String) -> void:
	_add_label(title, Color("6be7d6"), 14)
	_add_label(text if text.strip_edges() != "" else "Contenuto in validazione didattica.", Color("e7f3f5"), 16)

func _add_label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	detail_box.add_child(label)
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.075, 0.99)
	style.border_color = Color(0.42, 0.90, 0.84, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	return style

func _key(subject: String, topic: String) -> String:
	return "%s:%s" % [subject, topic]

func _title(topic: String) -> String:
	return topic.replace("-", " ").replace("_", " ").capitalize()

func _state_label(state: String) -> String:
	return {
		"unknown": "NON INCONTRATO",
		"encountered": "INCONTRATO",
		"consulted": "CONSULTATO",
		"applied": "APPLICATO",
		"consolidated": "CONSOLIDATO",
	}.get(state, state.to_upper())

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
