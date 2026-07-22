class_name OutdoorShopPanel
extends Control

## Bottega del Relitto. Consuma esclusivamente il catalogo e le API di
## OutdoorGameplay: costi, ownership e gating restano responsabilita del dominio.

signal closed

const SHOP_BACKGROUND: Texture2D = preload("res://assets/shop/reward-shop-bg.webp")
const REWARD_ATLAS: Texture2D = preload("res://assets/shop/reward-items-sheet.png")
const REWARD_ATLAS_DATA := "res://assets/shop/reward-items-sheet.json"

const SLOT_LABELS := {
	"bot": "BIT",
	"avatar": "OUTFIT",
	"accessory": "ACCESSORI",
	"pet": "COMPAGNI",
	"emblem": "EMBLEMI",
	"upgrade": "NORA",
	"decor": "RESTAURI",
}
const SLOT_ORDER := ["bot", "avatar", "accessory", "pet", "emblem", "upgrade", "decor"]
const SLOT_META := {
	"bot": {
		"title": "Livree di Bit",
		"intro": "Ricalibra il guscio luminoso del compagno che veglia sulle tue missioni.",
		"impact": "La nuova livrea appare subito su Bit e nel ritratto di supporto.",
	},
	"avatar": {
		"title": "Outfit da esplorazione",
		"intro": "Costruisci un'identita visiva che racconti quanta strada hai percorso.",
		"impact": "L'outfit equipaggiato accompagna l'esploratore in tutte le aree del Relitto.",
	},
	"accessory": {
		"title": "Moduli e accessori",
		"intro": "Dettagli tecnici, segni di metodo e strumenti per personalizzare l'equipaggio.",
		"impact": "Puoi indossare un accessorio alla volta e sostituirlo senza altri costi.",
	},
	"pet": {
		"title": "Compagni di rotta",
		"intro": "Presenze vive che seguono l'esploratore e reagiscono ai progressi.",
		"impact": "Il compagno scelto ti segue nel mondo e celebra i momenti riusciti.",
	},
	"emblem": {
		"title": "Emblemi di metodo",
		"intro": "Distintivi da esporre per ricordare costanza, curiosita e precisione.",
		"impact": "Un emblema alla volta compare accanto all'esploratore nel mondo.",
	},
	"upgrade": {
		"title": "Potenziamenti NORA",
		"intro": "Moduli permanenti che rendono piu solido il supporto durante le missioni.",
		"impact": "Acquisto permanente registrato nel save; gli effetti sulle missioni non sono ancora attivi in questa build.",
	},
	"decor": {
		"title": "Restauri del Relitto",
		"intro": "Restituisci luce alle aree conquistate e rendi visibile la tua ricostruzione.",
		"impact": "Progetto permanente registrato nel save; la trasformazione delle aree arrivera con le scene native dedicate.",
	},
}

var gameplay: OutdoorGameplay
var _state: Dictionary = {}
var _slot := "bot"
var _selected_id := ""
var _atlas_regions: Dictionary = {}
var _items: GridContainer
var _scroll: ScrollContainer
var _detail_pane: VBoxContainer
var _detail_image: TextureRect
var _detail_category: Label
var _detail_collection: Label
var _detail_rarity: Label
var _detail_name: Label
var _detail_description: Label
var _detail_impact: Label
var _detail_requirements: Label
var _detail_state: Label
var _detail_action: Button
var _category_heading: Label
var _category_intro: Label
var _energy: Label
var _status: Label
var _subtitle: Label
var _category_buttons: Dictionary = {}


func setup(value: OutdoorGameplay) -> void:
	gameplay = value
	_load_atlas_regions()
	_build_ui()
	gameplay.runtime_state_changed.connect(_on_state)
	gameplay.feedback.connect(_on_feedback)
	_on_state(gameplay.runtime_state())


func open_panel() -> void:
	visible = true
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.open")
	_refresh()
	_apply_responsive_layout()


func close_panel() -> void:
	visible = false
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.close")
	closed.emit()


func _build_ui() -> void:
	name = "OutdoorShopPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := TextureRect.new()
	backdrop.name = "ShopBackdrop"
	backdrop.texture = SHOP_BACKGROUND
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.018, 0.025, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.name = "ShopWindow"
	add_child(panel)
	panel.anchor_left = 0.035
	panel.anchor_top = 0.02
	panel.anchor_right = 0.965
	panel.anchor_bottom = 0.98
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", _panel_style())

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	panel.add_child(main)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
	header.add_theme_constant_override("separation", 18)
	main.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 3)
	header.add_child(titles)
	var title := Label.new()
	title.text = "BOTTEGA DEL RELITTO"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("effffb"))
	titles.add_child(title)
	_subtitle = Label.new()
	_subtitle.text = "Trasforma l'energia conquistata in identita, alleati e nuovi spazi da vivere."
	_subtitle.add_theme_font_size_override("font_size", 13)
	_subtitle.add_theme_color_override("font_color", Color("a8c9c3"))
	_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(_subtitle)

	_energy = Label.new()
	_energy.name = "ShopEnergy"
	_energy.custom_minimum_size.x = 150
	_energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_energy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energy.add_theme_font_size_override("font_size", 18)
	_energy.add_theme_color_override("font_color", Color("ffd56a"))
	header.add_child(_energy)

	var close_button := Button.new()
	close_button.name = "CloseShopButton"
	close_button.text = "×"
	close_button.tooltip_text = "Chiudi bottega"
	close_button.custom_minimum_size = Vector2(44, 44)
	close_button.add_theme_font_size_override("font_size", 24)
	_style_button(close_button, Color("88ded0"), false)
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)

	var categories := GridContainer.new()
	categories.name = "ShopCategories"
	categories.columns = SLOT_ORDER.size()
	categories.add_theme_constant_override("h_separation", 5)
	categories.add_theme_constant_override("v_separation", 5)
	main.add_child(categories)
	for slot_name in SLOT_ORDER:
		var button := Button.new()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 40
		button.tooltip_text = str(SLOT_META[slot_name]["intro"])
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_select_slot.bind(slot_name))
		categories.add_child(button)
		_category_buttons[slot_name] = button

	var separator := HSeparator.new()
	separator.modulate = Color(0.55, 0.9, 0.84, 0.35)
	main.add_child(separator)

	var body := HBoxContainer.new()
	body.name = "ShopBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	main.add_child(body)

	var catalog := VBoxContainer.new()
	catalog.name = "ShopCatalog"
	catalog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog.add_theme_constant_override("separation", 8)
	body.add_child(catalog)

	var category_top := HBoxContainer.new()
	category_top.add_theme_constant_override("separation", 12)
	catalog.add_child(category_top)
	var category_copy := VBoxContainer.new()
	category_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_top.add_child(category_copy)
	_category_heading = Label.new()
	_category_heading.add_theme_font_size_override("font_size", 18)
	_category_heading.add_theme_color_override("font_color", Color("effffb"))
	category_copy.add_child(_category_heading)
	_category_intro = Label.new()
	_category_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_category_intro.add_theme_font_size_override("font_size", 12)
	_category_intro.add_theme_color_override("font_color", Color("9fc4bb"))
	category_copy.add_child(_category_intro)

	_scroll = ScrollContainer.new()
	_scroll.name = "ShopScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_theme_stylebox_override("panel", _transparent_style())
	catalog.add_child(_scroll)
	_items = GridContainer.new()
	_items.name = "ShopItems"
	_items.columns = 2
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("h_separation", 8)
	_items.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_items)

	var body_separator := VSeparator.new()
	body_separator.modulate = Color(0.55, 0.9, 0.84, 0.28)
	body.add_child(body_separator)

	_detail_pane = VBoxContainer.new()
	_detail_pane.name = "ShopDetailPane"
	_detail_pane.custom_minimum_size.x = 292
	_detail_pane.add_theme_constant_override("separation", 7)
	body.add_child(_detail_pane)

	var detail_top := HBoxContainer.new()
	detail_top.add_theme_constant_override("separation", 8)
	_detail_pane.add_child(detail_top)
	_detail_category = Label.new()
	_detail_category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_category.add_theme_font_size_override("font_size", 11)
	_detail_category.add_theme_color_override("font_color", Color("88ded0"))
	detail_top.add_child(_detail_category)
	_detail_collection = Label.new()
	_detail_collection.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_detail_collection.add_theme_font_size_override("font_size", 11)
	_detail_collection.add_theme_color_override("font_color", Color("a8c9c3"))
	detail_top.add_child(_detail_collection)

	_detail_image = TextureRect.new()
	_detail_image.name = "ShopDetailPreview"
	_detail_image.custom_minimum_size = Vector2(180, 180)
	_detail_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_pane.add_child(_detail_image)

	_detail_rarity = Label.new()
	_detail_rarity.add_theme_font_size_override("font_size", 11)
	_detail_pane.add_child(_detail_rarity)
	_detail_name = Label.new()
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.add_theme_font_size_override("font_size", 21)
	_detail_name.add_theme_color_override("font_color", Color("f4fffc"))
	_detail_pane.add_child(_detail_name)
	_detail_description = Label.new()
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.add_theme_font_size_override("font_size", 13)
	_detail_description.add_theme_color_override("font_color", Color("b8d2cc"))
	_detail_pane.add_child(_detail_description)

	var detail_separator := HSeparator.new()
	detail_separator.modulate = Color(0.55, 0.9, 0.84, 0.22)
	_detail_pane.add_child(detail_separator)
	_detail_impact = Label.new()
	_detail_impact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_impact.add_theme_font_size_override("font_size", 12)
	_detail_impact.add_theme_color_override("font_color", Color("9fc4bb"))
	_detail_pane.add_child(_detail_impact)
	_detail_requirements = Label.new()
	_detail_requirements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_requirements.add_theme_font_size_override("font_size", 12)
	_detail_pane.add_child(_detail_requirements)
	_detail_state = Label.new()
	_detail_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_state.add_theme_font_size_override("font_size", 11)
	_detail_state.add_theme_color_override("font_color", Color("a8c9c3"))
	_detail_pane.add_child(_detail_state)

	var detail_spacer := Control.new()
	detail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_pane.add_child(detail_spacer)
	_detail_action = Button.new()
	_detail_action.name = "ShopDetailAction"
	_detail_action.custom_minimum_size.y = 46
	_detail_action.add_theme_font_size_override("font_size", 13)
	_detail_pane.add_child(_detail_action)

	var footer_separator := HSeparator.new()
	footer_separator.modulate = Color(0.55, 0.9, 0.84, 0.24)
	main.add_child(footer_separator)
	_status = Label.new()
	_status.name = "ShopStatus"
	_status.text = "Seleziona una ricompensa per esaminarla."
	_status.custom_minimum_size.y = 20
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", Color("a8c9c3"))
	_status.add_theme_font_size_override("font_size", 12)
	main.add_child(_status)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.045, 0.055, 0.965)
	style.border_color = Color(0.42, 0.9, 0.84, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	return style


func _card_style(selected: bool, active: bool, rarity_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.105, 0.12, 0.97) if selected else Color(0.018, 0.07, 0.082, 0.92)
	style.border_color = rarity_color if selected else (Color("ffd56a", 0.72) if active else Color(0.45, 0.76, 0.72, 0.24))
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style


func _style_button(button: Button, accent: Color, filled: bool) -> void:
	button.add_theme_color_override("font_color", Color("effffb"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.66, 0.65, 0.72))
	button.add_theme_stylebox_override("normal", _button_style(accent, filled, 0.22 if filled else 0.08))
	button.add_theme_stylebox_override("hover", _button_style(accent, true, 0.30))
	button.add_theme_stylebox_override("pressed", _button_style(accent.lightened(0.12), true, 0.38))
	button.add_theme_stylebox_override("focus", _button_style(accent.lightened(0.18), filled, 0.24))
	button.add_theme_stylebox_override("disabled", _button_style(Color("708783"), false, 0.05))


func _button_style(accent: Color, filled: bool, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, alpha) if filled else Color(0.02, 0.055, 0.063, 0.88)
	style.border_color = Color(accent, 0.72 if filled else 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(7)
	return style


func _style_category_button(button: Button, active: bool) -> void:
	var accent := Color("79e3d3")
	button.add_theme_color_override("font_color", Color("d9ece8") if not active else Color("ffffff"))
	button.add_theme_stylebox_override("normal", _button_style(accent, active, 0.26 if active else 0.05))
	button.add_theme_stylebox_override("hover", _button_style(accent, true, 0.22))
	button.add_theme_stylebox_override("pressed", _button_style(accent, true, 0.31))
	button.add_theme_stylebox_override("focus", _button_style(accent, active, 0.26 if active else 0.08))


func _select_slot(value: String) -> void:
	if not SLOT_META.has(value):
		return
	_slot = value
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "ui.select")
	_selected_id = _preferred_item_id(value)
	_status.text = str(SLOT_META[value]["intro"])
	_refresh()


func _select_item(id: String) -> void:
	_selected_id = id
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "ui.select")
	_refresh()


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_item(id)


func _on_state(value: Dictionary) -> void:
	_state = value.duplicate(true)
	if is_instance_valid(_items):
		_refresh()


func _on_feedback(message: String) -> void:
	if visible and is_instance_valid(_status):
		_status.text = message


func _refresh() -> void:
	if not is_instance_valid(_items):
		return
	_energy.text = "ENERGIA  ◆  %d" % int(_state.get("energy", 0))
	_update_category_navigation()
	var meta: Dictionary = SLOT_META[_slot]
	_category_heading.text = str(meta["title"])
	_category_intro.text = str(meta["intro"])

	var cosmetics := RewardCatalog.by_slot(_slot)
	if _selected_id.is_empty() or not _contains_id(cosmetics, _selected_id):
		_selected_id = _preferred_item_id(_slot)
	for child in _items.get_children():
		child.free()
	for cosmetic in cosmetics:
		_items.add_child(_build_card(cosmetic))
	_refresh_detail(RewardCatalog.find(_selected_id))


func _update_category_navigation() -> void:
	for slot_name in SLOT_ORDER:
		var button := _category_buttons[slot_name] as Button
		var total := RewardCatalog.by_slot(slot_name).size()
		button.text = "%s  %d/%d" % [SLOT_LABELS[slot_name], _owned_count(slot_name), total]
		button.button_pressed = slot_name == _slot
		_style_category_button(button, slot_name == _slot)


func _build_card(cosmetic: Dictionary) -> Control:
	var id := str(cosmetic.get("id", ""))
	var slot_name := str(cosmetic.get("slot", ""))
	var owned := _is_owned(id)
	var active := _is_active(cosmetic)
	var level := int(_state.get("level", 1))
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))
	var rarity := _rarity(cosmetic)
	var rarity_color: Color = rarity["color"]
	var selected := id == _selected_id

	var card := PanelContainer.new()
	card.name = "Cosmetic_%s" % id
	card.add_to_group("shop_item_card")
	card.set_meta("cosmetic_id", id)
	card.custom_minimum_size = Vector2(0, 134)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "Mostra %s" % str(cosmetic.get("name", id))
	card.add_theme_stylebox_override("panel", _card_style(selected, active, rarity_color))
	card.gui_input.connect(_on_card_input.bind(id))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	card.add_child(row)
	var image := TextureRect.new()
	image.name = "Thumbnail_%s" % id
	image.add_to_group("shop_item_thumbnail")
	image.custom_minimum_size = Vector2(104, 104)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = _item_texture(id)
	image.modulate = Color(0.52, 0.58, 0.58, 0.82) if level < min_level and not owned else Color.WHITE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(image)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)
	var rarity_label := Label.new()
	rarity_label.text = "%s%s" % [str(rarity["label"]), "  ·  ATTIVO" if active else ""]
	rarity_label.add_theme_font_size_override("font_size", 10)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	copy.add_child(rarity_label)
	var name_label := Label.new()
	name_label.text = str(cosmetic.get("name", id))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("effffb"))
	copy.add_child(name_label)
	var description := Label.new()
	description.text = str(cosmetic.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_size_override("font_size", 11)
	description.add_theme_color_override("font_color", Color("9fc4bb"))
	copy.add_child(description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	copy.add_child(bottom)
	var price := Label.new()
	price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.text = _card_price_text(cost, min_level, owned, active)
	price.add_theme_font_size_override("font_size", 10)
	price.add_theme_color_override("font_color", _requirement_color(cosmetic))
	bottom.add_child(price)
	var action := Button.new()
	action.name = "Action_%s" % id
	action.custom_minimum_size = Vector2(104, 32)
	action.add_theme_font_size_override("font_size", 10)
	_configure_action(action, cosmetic, false)
	bottom.add_child(action)
	return card


func _refresh_detail(cosmetic: Dictionary) -> void:
	if cosmetic.is_empty():
		_detail_image.texture = null
		_detail_name.text = "Nessuna ricompensa"
		_detail_action.disabled = true
		return
	var id := str(cosmetic.get("id", ""))
	var rarity := _rarity(cosmetic)
	var owned := _is_owned(id)
	var active := _is_active(cosmetic)
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))
	var level := int(_state.get("level", 1))
	_detail_category.text = str(SLOT_LABELS[_slot])
	_detail_collection.text = "COLLEZIONE  %d/%d" % [_owned_count(_slot), RewardCatalog.by_slot(_slot).size()]
	_detail_image.texture = _item_texture(id)
	_detail_image.modulate = Color(0.6, 0.65, 0.65, 0.9) if level < min_level and not owned else Color.WHITE
	_detail_rarity.text = str(rarity["label"])
	_detail_rarity.add_theme_color_override("font_color", rarity["color"])
	_detail_name.text = str(cosmetic.get("name", id))
	_detail_description.text = str(cosmetic.get("description", ""))
	_detail_impact.text = "IMPATTO\n%s" % str(SLOT_META[_slot]["impact"])
	_detail_requirements.text = _detail_requirement_text(cost, min_level, owned, active)
	_detail_requirements.add_theme_color_override("font_color", _requirement_color(cosmetic))
	_detail_state.text = _detail_state_text(cosmetic)
	_configure_action(_detail_action, cosmetic, true)


func _configure_action(button: Button, cosmetic: Dictionary, detailed: bool) -> void:
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection["callable"])
	var id := str(cosmetic.get("id", ""))
	var slot_name := str(cosmetic.get("slot", ""))
	var owned := _is_owned(id)
	var active := _is_active(cosmetic)
	var level := int(_state.get("level", 1))
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))
	var rarity_color: Color = _rarity(cosmetic)["color"]
	button.disabled = false
	if active and slot_name not in ["upgrade", "decor"]:
		button.text = "RIMUOVI"
		button.pressed.connect(_unequip.bind(slot_name))
	elif active:
		button.text = "REGISTRATO"
		button.disabled = true
	elif owned:
		button.text = "EQUIPAGGIA"
		button.pressed.connect(_equip.bind(id))
	elif level < min_level:
		button.text = ("RAGGIUNGI LIVELLO %d" if detailed else "LIVELLO %d") % min_level
		button.disabled = true
	elif int(_state.get("energy", 0)) < cost:
		button.text = ("ENERGIA INSUFFICIENTE" if detailed else "NON DISPONIBILE")
		button.disabled = true
	else:
		button.text = "ACQUISTA  ◆ %d" % cost if detailed else "ACQUISTA"
		button.pressed.connect(_purchase.bind(id))
	_style_button(button, rarity_color, not button.disabled)


func _card_price_text(cost: int, min_level: int, owned: bool, active: bool) -> String:
	if active:
		return "IN USO"
	if owned:
		return "POSSEDUTO"
	if int(_state.get("level", 1)) < min_level:
		return "RICHIEDE LV %d" % min_level
	return "◆ %d" % cost


func _detail_requirement_text(cost: int, min_level: int, owned: bool, active: bool) -> String:
	if active:
		return "CONFIGURAZIONE ATTIVA"
	if owned:
		return "NELLA TUA COLLEZIONE"
	if int(_state.get("level", 1)) < min_level:
		return "SBLOCCO: LIVELLO %d  ·  COSTO: ◆ %d" % [min_level, cost]
	return "COSTO: ◆ %d  ·  LIVELLO RICHIESTO: %d" % [cost, min_level]


func _detail_state_text(cosmetic: Dictionary) -> String:
	var id := str(cosmetic.get("id", ""))
	var slot_name := str(cosmetic.get("slot", ""))
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))
	if _is_active(cosmetic):
		if slot_name == "upgrade":
			return "Modulo registrato nel save. L'effetto gameplay verra attivato in un blocco dedicato."
		if slot_name == "decor":
			return "Progetto registrato nel save. La relativa scena del Relitto non e ancora disponibile."
		return "Questa ricompensa e gia applicata al Relitto."
	if _is_owned(id):
		return "Acquistata. Puoi equipaggiarla ora senza spendere altra energia."
	if int(_state.get("level", 1)) < min_level:
		return "Continua le missioni per raggiungere il livello necessario."
	var missing := maxi(0, cost - int(_state.get("energy", 0)))
	if missing > 0:
		return "Mancano %d energia: completare esercizi e sistemi alimenta la bottega." % missing
	return "Disponibile ora. L'acquisto usa energia ma non riduce i progressi ottenuti."


func _requirement_color(cosmetic: Dictionary) -> Color:
	var id := str(cosmetic.get("id", ""))
	if _is_owned(id):
		return Color("78e2b0")
	if int(_state.get("level", 1)) < int(cosmetic.get("minLevel", 1)):
		return Color("a5adb0")
	if int(_state.get("energy", 0)) < int(cosmetic.get("cost", 0)):
		return Color("ef9a87")
	return Color("ffd56a")


func _rarity(cosmetic: Dictionary) -> Dictionary:
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))
	if min_level >= 8 or cost >= 3000:
		return {"label": "LEGGENDARIA", "color": Color("ffd75e")}
	if min_level >= 6 or cost >= 1200:
		return {"label": "EPICA", "color": Color("ad94ff")}
	if min_level >= 4 or cost >= 500:
		return {"label": "RARA", "color": Color("6be7d6")}
	return {"label": "COMUNE", "color": Color("9db7bd")}


func _is_owned(id: String) -> bool:
	var unlocked: Array = _state.get("cosmeticsUnlocked", [])
	var inventory: Array = _state.get("cosmeticsInventory", [])
	return unlocked.has(id) or inventory.has(id)


func _is_active(cosmetic: Dictionary) -> bool:
	var id := str(cosmetic.get("id", ""))
	var slot_name := str(cosmetic.get("slot", ""))
	var equipped: Dictionary = _state.get("cosmeticsEquipped", {})
	return str(equipped.get(slot_name, "")) == id or (_is_owned(id) and slot_name in ["upgrade", "decor"])


func _owned_count(slot_name: String) -> int:
	var total := 0
	for cosmetic in RewardCatalog.by_slot(slot_name):
		if _is_owned(str(cosmetic.get("id", ""))):
			total += 1
	return total


func _preferred_item_id(slot_name: String) -> String:
	var equipped: Dictionary = _state.get("cosmeticsEquipped", {})
	var equipped_id := str(equipped.get(slot_name, ""))
	if not equipped_id.is_empty():
		return equipped_id
	var cosmetics := RewardCatalog.by_slot(slot_name)
	return str(cosmetics[0].get("id", "")) if not cosmetics.is_empty() else ""


func _contains_id(cosmetics: Array, id: String) -> bool:
	for cosmetic in cosmetics:
		if str(cosmetic.get("id", "")) == id:
			return true
	return false


func _load_atlas_regions() -> void:
	var source := FileAccess.get_file_as_string(REWARD_ATLAS_DATA)
	var parsed = JSON.parse_string(source)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Atlante ricompense non leggibile: %s" % REWARD_ATLAS_DATA)
		return
	var frames: Dictionary = parsed.get("frames", {})
	for id in frames:
		var entry: Dictionary = frames[id]
		var frame: Dictionary = entry.get("frame", {})
		_atlas_regions[str(id)] = Rect2(
			float(frame.get("x", 0)),
			float(frame.get("y", 0)),
			float(frame.get("w", 128)),
			float(frame.get("h", 128))
		)


func _item_texture(id: String) -> Texture2D:
	if not _atlas_regions.has(id):
		return null
	var texture := AtlasTexture.new()
	texture.atlas = REWARD_ATLAS
	texture.region = _atlas_regions[id]
	return texture


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_items) or not is_instance_valid(_detail_pane):
		return
	# Con stretch/aspect=expand il canvas logico puo restare largo 1280 anche su
	# una finestra fisica da 900 px. Consideriamo entrambe le misure, altrimenti
	# il layout compatto non scatterebbe mai su tablet stretti e portrait Web.
	var logical_width := get_viewport_rect().size.x
	var window_width := float(get_window().size.x) if get_window() != null else logical_width
	var compact := minf(logical_width, window_width) < 980.0
	_items.columns = 1 if compact else 2
	_detail_pane.visible = not compact
	_subtitle.visible = not compact


func _purchase(id: String) -> void:
	var purchased := gameplay.try_purchase_cosmetic(id)
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "reward.unlocked" if purchased else "ui.locked")
	_selected_id = id
	_refresh()


func _equip(id: String) -> void:
	if gameplay.equip_cosmetic(id):
		_status.text = "Equipaggiato: %s" % str(RewardCatalog.find(id).get("name", id))
		var audio := get_node_or_null("/root/NativeAudio")
		if audio != null:
			audio.call("play", "ui.confirm")
	_selected_id = id
	_refresh()


func _unequip(slot_name: String) -> void:
	gameplay.unequip_cosmetic(slot_name)
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "ui.select")
	_status.text = "Elemento rimosso. La ricompensa resta nella tua collezione."
	_refresh()
