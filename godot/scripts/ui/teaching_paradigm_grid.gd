class_name TeachingParadigmGrid
extends VBoxContainer

## Il paradigma latino come tabella, non come prosa. Ogni riga corrisponde a
## una voce della tavola autorata; il numero delle righe e' quindi verificabile
## per ID e non dipende da un totale scritto due volte.

const TESTO := Color("d8fff8")
const MUTED := Color(0.72, 0.88, 0.86, 0.78)
const ACCENTO := Color("ffc95c")
const PIENO := Color("6be7d6")

var _tavola: Dictionary = {}

func _init() -> void:
	name = "TeachingParadigmGrid"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

func mostra(tavola: Dictionary) -> void:
	_tavola = tavola.duplicate(true)
	for child in get_children():
		child.queue_free()
	if _tavola.is_empty():
		return
	tooltip_text = descrizione()
	_add_header()
	var conteggi: Dictionary = {}
	for raw in Array(_tavola.get("voci", [])):
		var firma := _firma_forma(str((raw as Dictionary).get("forma", "")))
		if firma != "": conteggi[firma] = int(conteggi.get(firma, 0)) + 1
	for indice in Array(_tavola.get("voci", [])).size():
		var voce: Dictionary = Array(_tavola.get("voci", []))[indice]
		var firma := _firma_forma(str(voce.get("forma", "")))
		var condivisa := int(conteggi.get(firma, 0)) > 1 \
			or str(voce.get("label", "")).to_lower().contains(" e ") \
			or str(voce.get("forma", "")).contains("|")
		_add_cell(indice, voce, condivisa)

func _add_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	add_child(header)
	for spec in [["CASO", 0.34], ["NUMERO", 0.16], ["FORMA", 0.50]]:
		var label := Label.new()
		label.text = str(spec[0])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = float(spec[1])
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", PIENO)
		header.add_child(label)

func _add_cell(indice: int, voce: Dictionary, condivisa: bool) -> void:
	var panel := PanelContainer.new()
	panel.name = "ParadigmCell_%02d" % indice
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 48)
	panel.tooltip_text = "%s. %s" % [str(voce.get("label", "")), str(voce.get("forma", ""))]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.79, 0.36, 0.14) if condivisa else Color(0.18, 0.56, 0.53, 0.12)
	style.border_color = ACCENTO if condivisa else Color(PIENO.r, PIENO.g, PIENO.b, 0.38)
	style.set_border_width_all(2 if condivisa else 1)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(7)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var label_text := str(voce.get("label", ""))
	var lower := label_text.to_lower()
	var numero := "SG / PL"
	if lower.contains("singolare") and not lower.contains("plurale"): numero = "SG"
	elif lower.contains("plurale") and not lower.contains("singolare"): numero = "PL"
	elif not lower.contains("singolare") and not lower.contains("plurale"): numero = "—"
	_add_column(row, label_text.replace(" singolare", "").replace(" plurale", ""), 0.34, TESTO, 14)
	_add_column(row, numero, 0.16, ACCENTO if condivisa else MUTED, 13)
	_add_column(row, str(voce.get("forma", "")), 0.50, ACCENTO if condivisa else TESTO, 14)

func _add_column(parent: HBoxContainer, text: String, ratio: float, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = ratio
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

## La parte prima del primo esempio e' la desinenza strutturale. Due righe con
## la stessa firma, o una riga che ne dichiara due, sono le coincidenze che la
## griglia deve rendere visibili.
func _firma_forma(forma: String) -> String:
	var firma := forma.split("·")[0].strip_edges().to_lower()
	return firma

func descrizione() -> String:
	if _tavola.is_empty(): return ""
	return "Tabella del paradigma %s: %d caselle, con le forme coincidenti evidenziate." % [
		str(_tavola.get("titolo", "")), Array(_tavola.get("voci", [])).size()]

