class_name PetScreen
extends Control

## Schermata del Custode. E' un editor del solo stato affettivo/cosmetico: non
## concede risorse e non conosce mastery, missioni o gate.

signal closed
signal customization_changed

const STATE := preload("res://scripts/game/pet_state.gd")
const FACE_WIDGET := preload("res://scripts/ui/pet_face_widget.gd")

const INK := Color("06191f")
const PANEL := Color("09242a")
const GOLD := Color("ffd75e")
const MINT := Color("8ff6d2")
const TEXT := Color("e9fbf7")
const MUTED := Color("9fc4bb")

var _save
var _high_contrast := false
var _reduced_motion := false
var _portrait: Control
var _title: Label
var _subtitle: Label
var _bond_label: Label
var _bond_bar: ProgressBar
var _name_field: LineEdit
var _temperament: OptionButton
var _resting: OptionButton
var _palette_row: HBoxContainer
var _palette_buttons: Array[Button] = []
var _album: Label
var _face_gallery: GridContainer
var _collections: Label

func _ready() -> void:
	name = "PetScreen"
	# Figlio diretto di CanvasLayer: usa coordinate viewport esplicite, non anchor
	# relativi a un Control genitore che qui non esiste.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_sync_to_viewport()
	if not get_viewport().size_changed.is_connected(_sync_to_viewport):
		get_viewport().size_changed.connect(_sync_to_viewport)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()

func _sync_to_viewport() -> void:
	# PetScreen vive direttamente sotto un CanvasLayer, non sotto un altro
	# Control: gli anchor non hanno quindi un rettangolo genitore da seguire.
	# Copiare il visible rect rende backdrop e centratura indipendenti dal formato.
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

func configure(save, high_contrast: bool, reduced_motion: bool) -> void:
	_save = save
	_high_contrast = high_contrast
	_reduced_motion = reduced_motion
	_apply_style()
	_refresh()

func open_screen() -> void:
	_refresh()
	visible = true
	if is_instance_valid(_name_field):
		_name_field.grab_focus()

func close_screen() -> void:
	visible = false
	closed.emit()

func _build() -> void:
	var shade := ColorRect.new()
	shade.name = "PetScreenBackdrop"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.025, 0.035, 0.91)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	# Il contenitore centrale resta corretto anche quando il canvas viene scalato.
	# Il vecchio preset calcolava invece gli offset prima di conoscere il viewport
	# e, su tablet, lasciava la scheda incollata all'angolo in alto a sinistra.
	var center := CenterContainer.new()
	center.name = "PetScreenCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 34.0
	center.offset_top = 26.0
	center.offset_right = -34.0
	center.offset_bottom = -26.0
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "PetScreenPanel"
	panel.custom_minimum_size = Vector2(820, 610)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	box.add_child(header)

	_portrait = FACE_WIDGET.new()
	_portrait.name = "PetScreenPortrait"
	_portrait.call("set_display_size", 116.0)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_portrait)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 2)
	header.add_child(identity)
	var eyebrow := Label.new()
	eyebrow.text = "IL MIO CUSTODE"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", GOLD)
	identity.add_child(eyebrow)
	_title = Label.new()
	_title.text = "Custode"
	_title.add_theme_font_size_override("font_size", 29)
	_title.add_theme_color_override("font_color", TEXT)
	identity.add_child(_title)
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 13)
	_subtitle.add_theme_color_override("font_color", MUTED)
	identity.add_child(_subtitle)
	var bond_row := HBoxContainer.new()
	bond_row.add_theme_constant_override("separation", 10)
	identity.add_child(bond_row)
	_bond_label = Label.new()
	_bond_label.custom_minimum_size.x = 100.0
	_bond_label.add_theme_font_size_override("font_size", 12)
	_bond_label.add_theme_color_override("font_color", MINT)
	bond_row.add_child(_bond_label)
	_bond_bar = ProgressBar.new()
	_bond_bar.name = "PetBondProgress"
	_bond_bar.max_value = 100.0
	_bond_bar.show_percentage = false
	_bond_bar.custom_minimum_size = Vector2(250, 10)
	_bond_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_row.add_child(_bond_bar)

	var close := Button.new()
	close.name = "ClosePetScreen"
	close.text = "CHIUDI  X"
	close.custom_minimum_size = Vector2(116, 48)
	close.tooltip_text = "Torna al mondo"
	close.pressed.connect(close_screen)
	header.add_child(close)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color(GOLD, 0.42))
	box.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.name = "PetScreenScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var settings_grid := GridContainer.new()
	settings_grid.columns = 2
	settings_grid.add_theme_constant_override("h_separation", 12)
	settings_grid.add_theme_constant_override("v_separation", 12)
	settings_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(settings_grid)

	_name_field = LineEdit.new()
	_name_field.name = "PetScreenName"
	_name_field.max_length = STATE.MAX_NAME_LENGTH
	_name_field.placeholder_text = "Nome (massimo 12 caratteri)"
	_name_field.custom_minimum_size.y = 48
	_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_field.text_submitted.connect(func(_value: String): _save_name())
	var save_name := Button.new()
	save_name.name = "SavePetName"
	save_name.text = "SALVA"
	save_name.custom_minimum_size = Vector2(92, 48)
	save_name.pressed.connect(_save_name)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.add_child(_name_field)
	name_row.add_child(save_name)
	settings_grid.add_child(_section("NOME", name_row))

	_temperament = OptionButton.new()
	_temperament.name = "PetTemperament"
	_temperament.custom_minimum_size.y = 48
	_temperament.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in STATE.TEMPERAMENTS:
		_temperament.add_item(str(value).capitalize())
	_temperament.item_selected.connect(_choose_temperament)
	settings_grid.add_child(_section("INDOLE - IL SUO MODO DI REAGIRE", _temperament))

	_palette_row = HBoxContainer.new()
	_palette_row.name = "PetLiveryChoices"
	_palette_row.add_theme_constant_override("separation", 8)
	_palette_buttons.clear()
	for index in range(STATE.LIVERIES.size()):
		var button := Button.new()
		button.name = "PetLivery%d" % index
		button.text = "%d" % (index + 1)
		button.tooltip_text = "Scegli la livrea %d" % (index + 1)
		button.custom_minimum_size = Vector2(76, 48)
		button.pressed.connect(_choose_livery.bind(index))
		_palette_row.add_child(button)
		_palette_buttons.append(button)
	settings_grid.add_child(_section("LIVREA", _palette_row))

	_resting = OptionButton.new()
	_resting.name = "PetRestingFace"
	_resting.custom_minimum_size.y = 48
	_resting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resting.item_selected.connect(_choose_resting)
	settings_grid.add_child(_section("VOLTO A RIPOSO", _resting))

	var album_box := VBoxContainer.new()
	album_box.add_theme_constant_override("separation", 8)
	_face_gallery = GridContainer.new()
	_face_gallery.name = "PetFaceGallery"
	_face_gallery.columns = 7
	_face_gallery.add_theme_constant_override("h_separation", 10)
	_face_gallery.add_theme_constant_override("v_separation", 10)
	album_box.add_child(_face_gallery)
	_album = Label.new()
	_album.name = "PetFaceAlbum"
	_album.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_album.add_theme_color_override("font_color", MUTED)
	album_box.add_child(_album)
	content.add_child(_section("ALBUM DELLE ESPRESSIONI", album_box))

	_collections = Label.new()
	_collections.name = "PetCollections"
	_collections.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_collections.add_theme_color_override("font_color", TEXT)
	content.add_child(_section("RICORDI DEL VIAGGIO", _collections))

func _section(title_text: String, body: Control) -> PanelContainer:
	var section := PanelContainer.new()
	section.add_to_group("pet_screen_section")
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 12)
	section.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	column.add_child(body)
	return section

func _refresh() -> void:
	if _save == null or not is_instance_valid(_name_field):
		return
	var pet_name := STATE.name_of(_save)
	_name_field.text = pet_name
	var cosmetics: Dictionary = _save.data.get("cosmetics", {})
	var equipped: Dictionary = cosmetics.get("equipped", {})
	var pet_id := str(equipped.get("pet", ""))
	if pet_id.is_empty():
		pet_id = "pet-spark"
	_title.text = pet_name if not pet_name.is_empty() else "Il tuo Custode"
	_subtitle.text = "%s - %d sessioni insieme" % [
		STATE.temperament(_save).capitalize(), STATE.sessions_together(_save)]
	var bond_percent := roundi(STATE.bond(_save) * 100.0)
	_bond_label.text = "LEGAME  %d%%" % bond_percent
	_bond_bar.value = bond_percent
	_portrait.configure(
		pet_name, STATE.livery(_save), STATE.temperament(_save),
		STATE.resting_face(_save), STATE.bond(_save), STATE.faces(_save),
		_reduced_motion, pet_id.trim_prefix("pet-"))
	var temperament_index := STATE.TEMPERAMENTS.find(STATE.temperament(_save))
	_temperament.select(maxi(0, temperament_index))
	_resting.clear()
	var unlocked := STATE.faces(_save)
	for face in unlocked:
		_resting.add_item(str(face).capitalize())
	var resting_index := unlocked.find(STATE.resting_face(_save))
	_resting.select(maxi(0, resting_index))
	var selected_livery := STATE.LIVERIES.find(STATE.livery(_save))
	for index in range(_palette_buttons.size()):
		_style_palette_button(_palette_buttons[index], STATE.LIVERIES[index], index == selected_livery)
	for child in _face_gallery.get_children():
		child.queue_free()
	var locked_faces: Array[String] = []
	for face in STATE.all_faces():
		if unlocked.has(face):
			var card := VBoxContainer.new()
			card.custom_minimum_size = Vector2(88, 108)
			var preview := FACE_WIDGET.new()
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.configure(
				"", STATE.livery(_save), STATE.temperament(_save), str(face),
				STATE.bond(_save), unlocked, true, pet_id.trim_prefix("pet-"))
			preview.set_preview_face(str(face))
			card.add_child(preview)
			var caption := Label.new()
			caption.text = str(face).capitalize()
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 11)
			caption.add_theme_color_override("font_color", TEXT)
			card.add_child(caption)
			_face_gallery.add_child(card)
		else:
			locked_faces.append(str(face).capitalize())
	_album.text = (
		"Ancora da scoprire: %s" % ", ".join(PackedStringArray(locked_faces))
		if not locked_faces.is_empty() else "Album completo - le avete vissute tutte insieme.")
	var antics_count := STATE.antics(_save).size()
	var gifts := STATE.gifts(_save)
	_collections.text = "Legame %d%% - %d sessioni insieme\nCombinelle: %d su %d - Cose che ti ha portato: %d%s" % [
		bond_percent, STATE.sessions_together(_save), antics_count,
		PetAntics.total_count(), gifts.size(), _gift_list(gifts)]

## Le cose portate dal Custode non sono un inventario: sono un diario del
## viaggio, letto dall'ultimo regalo fino al primo sasso.
func _gift_list(gifts: Array) -> String:
	if gifts.is_empty():
		return ""
	var lines: Array = []
	for i in range(gifts.size() - 1, maxi(-1, gifts.size() - 9), -1):
		var entry := gifts[i] as Dictionary
		lines.append("- %s - mondo %d" % [
			PetGifts.label_of(str(entry.get("id", ""))), int(entry.get("world", 0))])
	var remaining := gifts.size() - lines.size()
	if remaining > 0:
		lines.append("- e altre %d cose" % remaining)
	return "\n" + "\n".join(PackedStringArray(lines))

func _save_name() -> void:
	if _save == null:
		return
	STATE.set_pet_name(_save, _name_field.text)
	_commit()

func _choose_livery(index: int) -> void:
	if _save == null or index < 0 or index >= STATE.LIVERIES.size():
		return
	STATE.set_livery(_save, STATE.LIVERIES[index])
	_commit()

func _choose_temperament(index: int) -> void:
	if _save == null or index < 0 or index >= STATE.TEMPERAMENTS.size():
		return
	STATE.set_temperament(_save, str(STATE.TEMPERAMENTS[index]))
	_commit()

func _choose_resting(index: int) -> void:
	if _save == null:
		return
	var unlocked := STATE.faces(_save)
	if index >= 0 and index < unlocked.size():
		STATE.set_resting_face(_save, str(unlocked[index]))
		_commit()

func _commit() -> void:
	_save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "pet.equip")
	_refresh()
	customization_changed.emit()

func _apply_style() -> void:
	var panel := get_node_or_null("PetScreenCenter/PetScreenPanel") as PanelContainer
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color.WHITE if _high_contrast else GOLD
	style.set_border_width_all(4 if _high_contrast else 2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)
	for node in get_tree().get_nodes_in_group("pet_screen_section"):
		if not is_ancestor_of(node):
			continue
		var section_style := StyleBoxFlat.new()
		section_style.bg_color = INK if _high_contrast else Color("0b2a30")
		section_style.border_color = Color.WHITE if _high_contrast else Color(GOLD, 0.22)
		section_style.set_border_width_all(1)
		section_style.set_corner_radius_all(12)
		(node as PanelContainer).add_theme_stylebox_override("panel", section_style)
	_style_progress_bar()

func _style_progress_bar() -> void:
	if not is_instance_valid(_bond_bar):
		return
	var background := StyleBoxFlat.new()
	background.bg_color = Color("163b40")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.WHITE if _high_contrast else MINT
	fill.set_corner_radius_all(5)
	_bond_bar.add_theme_stylebox_override("background", background)
	_bond_bar.add_theme_stylebox_override("fill", fill)

func _style_palette_button(button: Button, palette: Array, selected: bool) -> void:
	if palette.size() < 2:
		return
	var primary := OutdoorVisualFactory.hex_color(int(palette[0]))
	var secondary := OutdoorVisualFactory.hex_color(int(palette[1]))
	var normal := StyleBoxFlat.new()
	normal.bg_color = primary.darkened(0.68)
	normal.border_color = Color.WHITE if _high_contrast else secondary
	normal.set_border_width_all(3 if selected else 1)
	normal.set_corner_radius_all(10)
	if selected:
		normal.shadow_color = Color(secondary, 0.42)
		normal.shadow_size = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = primary.darkened(0.50)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", secondary)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	button.text = ("OK %d" if selected else "%d") % (button.get_index() + 1)
