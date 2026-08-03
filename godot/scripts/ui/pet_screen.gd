class_name PetScreen
extends Control

## Schermata del Custode. È un editor del solo stato affettivo/cosmetico: non
## concede risorse e non conosce mastery, missioni o gate.

signal closed
signal customization_changed

const STATE := preload("res://scripts/game/pet_state.gd")
const FACE_WIDGET := preload("res://scripts/ui/pet_face_widget.gd")

var _save
var _high_contrast := false
var _reduced_motion := false
var _portrait: Control
var _name_field: LineEdit
var _temperament: OptionButton
var _resting: OptionButton
var _palette_row: HBoxContainer
var _album: Label
var _face_gallery: GridContainer
var _collections: Label

func _ready() -> void:
	name = "PetScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()

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
	shade.color = Color(0.005, 0.025, 0.035, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "PetScreenPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.custom_minimum_size = Vector2(620, 520)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	_portrait = FACE_WIDGET.new()
	_portrait.name = "PetScreenPortrait"
	_portrait.custom_minimum_size = Vector2(94, 94)
	header.add_child(_portrait)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = "IL MIO CUSTODE"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "ClosePetScreen"
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(108, 48)
	close.pressed.connect(close_screen)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	_name_field = LineEdit.new()
	_name_field.name = "PetScreenName"
	_name_field.max_length = STATE.MAX_NAME_LENGTH
	_name_field.placeholder_text = "Nome (massimo 12 caratteri)"
	_name_field.custom_minimum_size.y = 48
	_name_field.text_submitted.connect(func(_value: String): _save_name())
	content.add_child(_section("NOME", _name_field))
	var save_name := Button.new()
	save_name.name = "SavePetName"
	save_name.text = "SALVA NOME"
	save_name.custom_minimum_size.y = 44
	save_name.pressed.connect(_save_name)
	content.add_child(save_name)

	_palette_row = HBoxContainer.new()
	_palette_row.name = "PetLiveryChoices"
	_palette_row.add_theme_constant_override("separation", 10)
	content.add_child(_section("LIVREA", _palette_row))
	for index in range(STATE.LIVERIES.size()):
		var palette: Array = STATE.LIVERIES[index]
		var button := Button.new()
		button.name = "PetLivery%d" % index
		button.text = "●  ●"
		button.tooltip_text = "Livrea %d" % (index + 1)
		button.custom_minimum_size = Vector2(92, 48)
		button.add_theme_color_override("font_color", OutdoorVisualFactory.hex_color(int(palette[0])))
		button.add_theme_color_override("font_pressed_color", OutdoorVisualFactory.hex_color(int(palette[1])))
		button.pressed.connect(_choose_livery.bind(index))
		_palette_row.add_child(button)

	_temperament = OptionButton.new()
	_temperament.name = "PetTemperament"
	_temperament.custom_minimum_size.y = 48
	for value in STATE.TEMPERAMENTS:
		_temperament.add_item(str(value).capitalize())
	_temperament.item_selected.connect(_choose_temperament)
	content.add_child(_section("INDOLE · cambia come reagisce, mai cosa prova", _temperament))

	_resting = OptionButton.new()
	_resting.name = "PetRestingFace"
	_resting.custom_minimum_size.y = 48
	_resting.item_selected.connect(_choose_resting)
	content.add_child(_section("VOLTO A RIPOSO", _resting))

	var album_box := VBoxContainer.new()
	album_box.add_theme_constant_override("separation", 8)
	_face_gallery = GridContainer.new()
	_face_gallery.name = "PetFaceGallery"
	_face_gallery.columns = 5
	_face_gallery.add_theme_constant_override("h_separation", 12)
	_face_gallery.add_theme_constant_override("v_separation", 8)
	album_box.add_child(_face_gallery)
	_album = Label.new()
	_album.name = "PetFaceAlbum"
	_album.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_album.add_theme_color_override("font_color", Color("9fc4bb"))
	album_box.add_child(_album)
	content.add_child(_section("ALBUM DELLE FACCE", album_box))
	_collections = Label.new()
	_collections.name = "PetCollections"
	_collections.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_section("RICORDI", _collections))

func _section(title_text: String, body: Control) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("ffd75e"))
	section.add_child(title)
	section.add_child(body)
	return section

func _refresh() -> void:
	if _save == null or not is_instance_valid(_name_field):
		return
	_name_field.text = STATE.name_of(_save)
	_portrait.configure(
		STATE.name_of(_save), STATE.livery(_save), STATE.temperament(_save),
		STATE.resting_face(_save), STATE.bond(_save), STATE.faces(_save),
		_reduced_motion)
	var temperament_index := STATE.TEMPERAMENTS.find(STATE.temperament(_save))
	_temperament.select(maxi(0, temperament_index))
	_resting.clear()
	var unlocked := STATE.faces(_save)
	for face in unlocked:
		_resting.add_item(str(face).capitalize())
	var resting_index := unlocked.find(STATE.resting_face(_save))
	_resting.select(maxi(0, resting_index))
	for child in _face_gallery.get_children():
		child.queue_free()
	var locked_faces: Array[String] = []
	for face in STATE.all_faces():
		if unlocked.has(face):
			var card := VBoxContainer.new()
			card.custom_minimum_size = Vector2(86, 106)
			var preview := FACE_WIDGET.new()
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.configure("", STATE.livery(_save), STATE.temperament(_save), str(face), STATE.bond(_save), unlocked, true)
			preview.set_preview_face(str(face))
			card.add_child(preview)
			var caption := Label.new()
			caption.text = str(face).capitalize()
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 11)
			caption.add_theme_color_override("font_color", Color("dff7f2"))
			card.add_child(caption)
			_face_gallery.add_child(card)
		else:
			locked_faces.append(str(face).capitalize())
	_album.text = (
		"Da scoprire: %s" % ", ".join(PackedStringArray(locked_faces))
		if not locked_faces.is_empty() else "Album completo")
	var antics_count := STATE.antics(_save).size()
	var gifts := STATE.gifts(_save)
	_collections.text = "Legame %d%% · %d sessioni insieme\nCombinelle viste: %d · Cose che ti ha portato: %d" % [
		roundi(STATE.bond(_save) * 100.0), STATE.sessions_together(_save), antics_count, gifts.size()]

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
	_refresh()
	customization_changed.emit()

func _apply_style() -> void:
	var panel := get_node_or_null("PetScreenPanel") as PanelContainer
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.09, 0.11, 0.98)
	style.border_color = Color.WHITE if _high_contrast else Color("ffd75e")
	style.set_border_width_all(4 if _high_contrast else 2)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
