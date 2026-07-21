class_name OutdoorShopPanel
extends Control

## Presentazione della bottega C-14. Consuma esclusivamente il catalogo e le
## API di OutdoorGameplay; non decide costi, ownership o gating.

signal closed

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

var gameplay: OutdoorGameplay
var _state: Dictionary = {}
var _slot := "bot"
var _items: VBoxContainer
var _energy: Label
var _status: Label
var _category_buttons: Dictionary = {}

func setup(value: OutdoorGameplay) -> void:
	gameplay = value
	_build_ui()
	gameplay.runtime_state_changed.connect(_on_state)
	gameplay.feedback.connect(_on_feedback)
	_on_state(gameplay.runtime_state())

func open_panel() -> void:
	visible = true
	_refresh()

func close_panel() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	name = "OutdoorShopPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.025, 0.035, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "ShopWindow"
	panel.anchor_left = 0.10
	panel.anchor_top = 0.07
	panel.anchor_right = 0.90
	panel.anchor_bottom = 0.93
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	panel.add_child(main)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title := Label.new()
	title.text = "BOTTEGA DEL RELITTO"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("e7fff8"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "L'energia conquistata negli esercizi diventa identita, compagni e restauri."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("9fc4bb"))
	titles.add_child(subtitle)
	_energy = Label.new()
	_energy.add_theme_font_size_override("font_size", 18)
	_energy.add_theme_color_override("font_color", Color("f6c85f"))
	header.add_child(_energy)
	var close_button := Button.new()
	close_button.name = "CloseShopButton"
	close_button.text = "CHIUDI"
	close_button.custom_minimum_size = Vector2(96, 42)
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)

	var categories := HBoxContainer.new()
	categories.name = "ShopCategories"
	categories.add_theme_constant_override("separation", 6)
	main.add_child(categories)
	for slot_name in SLOT_ORDER:
		var button := Button.new()
		button.text = str(SLOT_LABELS[slot_name])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(100, 36)
		button.pressed.connect(_select_slot.bind(slot_name))
		categories.add_child(button)
		_category_buttons[slot_name] = button

	var separator := HSeparator.new()
	main.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.name = "ShopScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	_items = VBoxContainer.new()
	_items.name = "ShopItems"
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("separation", 8)
	scroll.add_child(_items)

	_status = Label.new()
	_status.name = "ShopStatus"
	_status.text = "Scegli una categoria."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", Color("9fc4bb"))
	_status.add_theme_font_size_override("font_size", 13)
	main.add_child(_status)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.075, 0.095, 0.985)
	style.border_color = Color(0.42, 0.9, 0.84, 0.48)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(22)
	return style

func _card_style(active: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.18, 0.19, 0.96) if active else Color(0.035, 0.12, 0.14, 0.9)
	style.border_color = Color("f6c85f", 0.72) if active else Color(0.42, 0.9, 0.84, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(10)
	return style

func _select_slot(value: String) -> void:
	_slot = value
	_refresh()

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
	_energy.text = "ENERGIA  %d" % int(_state.get("energy", 0))
	for slot_name in _category_buttons:
		(_category_buttons[slot_name] as Button).button_pressed = slot_name == _slot
	for child in _items.get_children():
		child.queue_free()
	for cosmetic in RewardCatalog.by_slot(_slot):
		_items.add_child(_build_card(cosmetic))

func _build_card(cosmetic: Dictionary) -> Control:
	var id := str(cosmetic.get("id", ""))
	var slot_name := str(cosmetic.get("slot", ""))
	var unlocked: Array = _state.get("cosmeticsUnlocked", [])
	var inventory: Array = _state.get("cosmeticsInventory", [])
	var equipped: Dictionary = _state.get("cosmeticsEquipped", {})
	var owned := unlocked.has(id) or inventory.has(id)
	var active := str(equipped.get(slot_name, "")) == id or (owned and (slot_name == "upgrade" or slot_name == "decor"))
	var level := int(_state.get("level", 1))
	var min_level := int(cosmetic.get("minLevel", 1))
	var cost := int(cosmetic.get("cost", 0))

	var card := PanelContainer.new()
	card.name = "Cosmetic_%s" % id
	card.add_to_group("shop_item_card")
	card.set_meta("cosmetic_id", id)
	card.add_theme_stylebox_override("panel", _card_style(active))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var swatch := PanelContainer.new()
	swatch.custom_minimum_size = Vector2(54, 54)
	var swatch_style := StyleBoxFlat.new()
	var color := OutdoorVisualFactory.hex_color(int(cosmetic.get("color", 0x6be7d6)))
	swatch_style.bg_color = Color(color, 0.22)
	swatch_style.border_color = color
	swatch_style.set_border_width_all(2)
	swatch_style.set_corner_radius_all(27)
	swatch.add_theme_stylebox_override("panel", swatch_style)
	row.add_child(swatch)
	var symbol := Label.new()
	# Simbolo vettoriale/font-safe: i glifi emoji del catalogo restano dati, ma
	# non sono necessari alla leggibilita Web della scheda.
	symbol.text = _safe_symbol(slot_name)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_color_override("font_color", color.lightened(0.26))
	symbol.add_theme_font_size_override("font_size", 22)
	swatch.add_child(symbol)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var name_label := Label.new()
	name_label.text = str(cosmetic.get("name", id))
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("e7fff8"))
	copy.add_child(name_label)
	var description := Label.new()
	description.text = str(cosmetic.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color("9fc4bb"))
	copy.add_child(description)
	var requirements := Label.new()
	requirements.text = "%d energia%s" % [cost, ("  ·  livello %d" % min_level) if min_level > 1 else ""]
	requirements.add_theme_font_size_override("font_size", 12)
	requirements.add_theme_color_override("font_color", Color("f6c85f"))
	copy.add_child(requirements)

	var action := Button.new()
	action.name = "Action_%s" % id
	action.custom_minimum_size = Vector2(122, 44)
	if active and slot_name != "upgrade" and slot_name != "decor":
		action.text = "RIMUOVI"
		action.pressed.connect(_unequip.bind(slot_name))
	elif active:
		action.text = "INSTALLATO"
		action.disabled = true
	elif owned:
		action.text = "EQUIPAGGIA"
		action.pressed.connect(_equip.bind(id))
	elif level < min_level:
		action.text = "LIVELLO %d" % min_level
		action.disabled = true
	else:
		action.text = "ACQUISTA"
		action.disabled = int(_state.get("energy", 0)) < cost
		action.pressed.connect(_purchase.bind(id))
	row.add_child(action)
	return card

func _safe_symbol(slot_name: String) -> String:
	return {"bot": "B", "avatar": "A", "accessory": "+", "pet": "P", "emblem": "*", "upgrade": "N", "decor": "D"}.get(slot_name, "·")

func _purchase(id: String) -> void:
	gameplay.try_purchase_cosmetic(id)
	_refresh()

func _equip(id: String) -> void:
	if gameplay.equip_cosmetic(id):
		_status.text = "Equipaggiato: %s" % str(RewardCatalog.find(id).get("name", id))
	_refresh()

func _unequip(slot_name: String) -> void:
	gameplay.unequip_cosmetic(slot_name)
	_status.text = "Elemento rimosso."
	_refresh()

