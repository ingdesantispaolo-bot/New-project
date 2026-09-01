class_name DiaryPanel
extends Control

## Il diario. Presentazione pura: legge il riepilogo da `PlayDiary` e lo disegna.
## Non calcola statistiche, non scrive nel salvataggio. Vedi `play_diary.gd` per
## il perché delle scelte (giorni cumulativi, nessuna serie da spezzare).
##
## Il tono è quello di un resoconto, non di una pagella. Nessuna percentuale di
## errore, nessuna materia messa in fondo a una classifica, nessun obiettivo da
## raggiungere: dice quanto hai giocato e cosa sai adesso, e si ferma lì.

signal panel_closed

const STATE_ORDER_VISIBILE := [
	KnowledgeCodex.STATE_CONSOLIDATED,
	KnowledgeCodex.STATE_APPLIED,
	KnowledgeCodex.STATE_CONSULTED,
	KnowledgeCodex.STATE_ENCOUNTERED,
]

var game_save
var _content: VBoxContainer
var _high_contrast := false

func setup(save_manager, high_contrast: bool = false) -> void:
	game_save = save_manager
	_high_contrast = high_contrast
	if _content == null:
		_build_ui()

func open_diary() -> void:
	visible = true
	_refresh()

func close_panel() -> void:
	visible = false
	panel_closed.emit()

func _build_ui() -> void:
	name = "DiaryPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	var sfondo := ColorRect.new()
	sfondo.name = "DiaryScrim"
	sfondo.color = Color(0.0, 0.02, 0.03, 0.72)
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sfondo)

	var pannello := PanelContainer.new()
	pannello.name = "DiaryFrame"
	pannello.set_anchors_preset(Control.PRESET_CENTER)
	pannello.anchor_left = 0.5
	pannello.anchor_right = 0.5
	pannello.anchor_top = 0.5
	pannello.anchor_bottom = 0.5
	pannello.offset_left = -300.0
	pannello.offset_right = 300.0
	pannello.offset_top = -260.0
	pannello.offset_bottom = 260.0
	pannello.add_theme_stylebox_override("panel", _panel_style())
	add_child(pannello)

	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 10)
	pannello.add_child(colonna)

	var titolo := Label.new()
	titolo.name = "DiaryTitle"
	titolo.text = "IL DIARIO"
	titolo.add_theme_font_size_override("font_size", 22)
	titolo.add_theme_color_override("font_color", Color("f6c85f"))
	colonna.add_child(titolo)

	var scorrimento := ScrollContainer.new()
	scorrimento.name = "DiaryScroll"
	scorrimento.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scorrimento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonna.add_child(scorrimento)

	_content = VBoxContainer.new()
	_content.name = "DiaryContent"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scorrimento.add_child(_content)

	var chiudi := Button.new()
	chiudi.name = "DiaryCloseButton"
	chiudi.text = "CHIUDI"
	chiudi.custom_minimum_size = Vector2(0, 48)
	chiudi.add_theme_font_size_override("font_size", 16)
	chiudi.add_theme_color_override("font_color", Color("06272a"))
	chiudi.pressed.connect(close_panel)
	colonna.add_child(chiudi)

func _refresh() -> void:
	if _content == null or game_save == null:
		return
	for figlio in _content.get_children():
		figlio.queue_free()
	var r: Dictionary = PlayDiary.summary(game_save)

	# --- Il viaggio -----------------------------------------------------------
	_sezione("IL VIAGGIO")
	var giorni := int(r.get("giorni", 0))
	_riga("Giorni giocati", "%d" % giorni)
	if str(r.get("primoGiorno", "")) != "":
		_riga("Hai cominciato il", str(r["primoGiorno"]))
	_riga("Mondi visitati", "%d" % int(r.get("mondiVisitati", 0)))
	var minuti := int(r.get("minuti", 0))
	_riga("Tempo sulle prove", _durata(minuti))

	# --- Le Quattro Vie ------------------------------------------------------
	# Non e' un voto totale: quattro righe separate impediscono che esplorare,
	# capire e aiutare qualcuno diventino intercambiabili.
	var riconoscimenti: Dictionary = r.get("riconoscimenti", {})
	if int(riconoscimenti.get("facets", 0)) > 0:
		_sezione("LE QUATTRO VIE")
		_riga("Titolo del viaggio", str(riconoscimenti.get("title", "In Cammino")))
		for path_data in Array(riconoscimenti.get("paths", [])):
			var path: Dictionary = path_data
			_riga(str(path.get("name", "Via")), "%d mondi" % int(path.get("count", 0)))
		_nota("Una via si accende una volta per mondo. Le attivita' successive restano nel diario, ma non si possono farmare.")
		var recenti: Array = Array(riconoscimenti.get("recent", []))
		if not recenti.is_empty():
			var ultimi: Array[String] = []
			for index in range(mini(3, recenti.size())):
				var entry: Dictionary = recenti[index]
				ultimi.append("Mondo %d · %s" % [
					int(entry.get("world", 1)), str(entry.get("label", "Progresso"))])
			_nota("Ultimi segni: %s." % "; ".join(ultimi))

	# --- Le prove -------------------------------------------------------------
	_sezione("LE PROVE")
	_riga("Superate", "%d" % int(r.get("proveSuperate", 0)))
	_riga("Affrontate", "%d" % int(r.get("proveAffrontate", 0)))
	var oggi := int(r.get("superateOggi", 0))
	if oggi > 0:
		_riga("Superate oggi", "%d" % oggi)

	# --- Le materie -----------------------------------------------------------
	var materie: Array = Array(r.get("materie", []))
	if not materie.is_empty():
		_sezione("LE MATERIE")
		for voce in materie:
			var riga := voce as Dictionary
			_riga(
				str(riga.get("subject", "")).capitalize(),
				"%d superate su %d" % [int(riga.get("superate", 0)), int(riga.get("prove", 0))])

	# --- Il manuale -----------------------------------------------------------
	var argomenti: Dictionary = r.get("argomenti", {})
	var totale_noti := 0
	for stato in STATE_ORDER_VISIBILE:
		totale_noti += int(argomenti.get(stato, 0))
	if totale_noti > 0:
		_sezione("QUELLO CHE SAI")
		for stato in STATE_ORDER_VISIBILE:
			var quanti := int(argomenti.get(stato, 0))
			if quanti > 0:
				_riga("Argomenti · %s" % KnowledgeCodex.state_label(stato), "%d" % quanti)
		_nota("«Consolidato» vuol dire tre risposte giuste in giorni diversi: "
			+ "non una schermata vista una volta.")

	# --- Il Custode -----------------------------------------------------------
	var custode: Dictionary = r.get("custode", {})
	if not custode.is_empty():
		var nome := str(custode.get("nome", ""))
		_sezione("IL CUSTODE" if nome == "" else "IL CUSTODE · %s" % nome.to_upper())
		_riga("Prove insieme", "%d" % int(custode.get("sessioni", 0)))
		_riga("Legame", "%d%%" % roundi(float(custode.get("legame", 0.0)) * 100.0))
		_riga("Cose che ti ha portato", "%d" % int(custode.get("regali", 0)))

	if giorni <= 1 and int(r.get("proveAffrontate", 0)) == 0:
		_nota("Il diario si riempie giocando. Torna a guardarlo fra qualche giorno.")

# --- Mattoni ------------------------------------------------------------------

func _sezione(titolo: String) -> void:
	var spazio := Control.new()
	spazio.custom_minimum_size.y = 8
	_content.add_child(spazio)
	var etichetta := Label.new()
	etichetta.text = titolo
	etichetta.add_theme_font_size_override("font_size", 14)
	etichetta.add_theme_color_override(
		"font_color", Color.WHITE if _high_contrast else Color("6be7d6"))
	_content.add_child(etichetta)

func _riga(sinistra: String, destra: String) -> void:
	var riga := HBoxContainer.new()
	riga.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var etichetta := Label.new()
	etichetta.text = sinistra
	etichetta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etichetta.add_theme_font_size_override("font_size", 15)
	etichetta.add_theme_color_override("font_color", Color("dff7f2"))
	riga.add_child(etichetta)
	var valore := Label.new()
	valore.text = destra
	valore.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valore.add_theme_font_size_override("font_size", 15)
	valore.add_theme_color_override(
		"font_color", Color.WHITE if _high_contrast else Color("f6c85f"))
	riga.add_child(valore)
	_content.add_child(riga)

func _nota(testo: String) -> void:
	var etichetta := Label.new()
	etichetta.text = testo
	etichetta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etichetta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etichetta.add_theme_font_size_override("font_size", 12)
	etichetta.add_theme_color_override("font_color", Color(0.62, 0.86, 0.82, 0.9))
	_content.add_child(etichetta)

func _durata(minuti: int) -> String:
	if minuti < 60:
		return "%d min" % minuti
	return "%d h %02d min" % [minuti / 60, minuti % 60]

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.075, 0.99)
	style.border_color = Color.WHITE if _high_contrast else Color(0.42, 0.90, 0.84, 0.58)
	style.set_border_width_all(3 if _high_contrast else 2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	return style
