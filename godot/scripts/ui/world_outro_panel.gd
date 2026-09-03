class_name WorldOutroPanel
extends Control

## **La pagina di uscita da un mondo**: la lettura che si legge quando un mondo
## si chiude. Gemella di [[WorldIntroPanel]], che copriva la metà d'ingresso
## della stessa richiesta del committente.
##
## **Il difetto che chiude.** `WorldLessonCatalog` ha un `debrief` per tutti e
## ventiquattro i mondi, e il file di ingresso lo dichiarava per iscritto: *«il
## testo di chiusura di un mondo resta senza lettore: è un lotto suo, perché
## appartiene all'uscita e non all'ingresso»*. Era vero da settimane. Questo è
## quel lotto.
##
## **E fa una cosa in più del debrief.** La richiesta era doppia: pagine di
## uscita, *e* una storia che non sia criptica per un ragazzo di undici anni. I
## beat di NORA raccontano per allusioni — «uno raschiato con una lama,
## dall'interno» — ed è ciò che li rende belli. Qui accanto c'è la stessa cosa
## detta in chiaro ([[WorldReadings]] · parte `storia`): chi aveva capito
## conferma, chi non aveva capito capisce, e nessuno dei due viene trattato da
## piccolo.
##
## Si apre da sola quando l'apparato del mondo torna in linea. È saltabile come
## tutto il resto della narrazione (§10.2): un bottone, sempre lo stesso posto.

signal chiusa

const ALTEZZA_TOCCO := 52

var livello := 1
var _colonna: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.01, 0.045, 0.06, 0.95)
	add_child(velo)

	var margine := MarginContainer.new()
	margine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 22)
	add_child(margine)

	var scorri := ScrollContainer.new()
	scorri.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margine.add_child(scorri)

	_colonna = VBoxContainer.new()
	_colonna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colonna.add_theme_constant_override("separation", 10)
	scorri.add_child(_colonna)

	_disegna()

func _disegna() -> void:
	var lvl := clampi(livello, 1, ApparatusConfig.MAX_LEVEL)
	var lettura := WorldReadings.lettura(lvl)

	var occhiello := Label.new()
	occhiello.text = "MONDO %d · PRIMA DI RIPARTIRE" % lvl
	occhiello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	occhiello.add_theme_font_size_override("font_size", 13)
	occhiello.add_theme_color_override("font_color", Color("f6c85f"))
	_colonna.add_child(occhiello)

	var titolo := Label.new()
	titolo.name = "ReadingTitle"
	titolo.text = str(lettura.get("titolo", WorldIntroPanel.titolo_mondo(lvl))).to_upper()
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titolo.add_theme_font_size_override("font_size", 30)
	titolo.add_theme_color_override("font_color", Color("f7fbff"))
	_colonna.add_child(titolo)

	# **La tavola del mondo.** È la stessa pittura che `ChunkGround` stende sotto
	# il terreno per dare a questo posto la sua identità di colore: finora si
	# vedeva solo di sbieco, sotto l'erba e le strade. Qui sta in cima alla
	# pagina, intera, e chi legge riconosce il posto da cui sta uscendo.
	var percorso := WorldReadings.tavola(lvl)
	if percorso != "" and ResourceLoader.exists(percorso):
		var tavola := TextureRect.new()
		tavola.name = "ReadingPlate"
		tavola.texture = load(percorso)
		tavola.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tavola.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tavola.custom_minimum_size = Vector2(0, 168)
		tavola.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_colonna.add_child(tavola)

	# La riga di NORA sul mondo appena chiuso. È il `debrief` che esisteva da
	# settimane e che nessuna schermata mostrava.
	var debrief := WorldLessonCatalog.debrief(lvl)
	if debrief != "":
		_colonna.add_child(_riquadro(debrief, Color("d7f7ee"), 16, "NORA"))

	# Le quattro parti, nell'ordine deciso in [[WorldReadings]].
	for parte_data in WorldReadings.PARTI:
		var parte: Dictionary = parte_data
		var testo := str(lettura.get(str(parte["chiave"]), "")).strip_edges()
		if testo == "":
			continue
		_colonna.add_child(_sezione(str(parte["titolo"])))
		_colonna.add_child(_paragrafo(testo, Color("eef7f4"), 16))

	var chiudi := Button.new()
	chiudi.name = "ContinueButton"
	chiudi.text = "AVANTI"
	chiudi.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	chiudi.add_theme_font_size_override("font_size", 20)
	chiudi.pressed.connect(func(): chiusa.emit())
	_colonna.add_child(chiudi)

# ---------------------------------------------------------------- mattoni

func _sezione(testo: String) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color("8ff6d2"))
	return l

func _paragrafo(testo: String, colore: Color, dim: int) -> Label:
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	return l

func _riquadro(testo: String, colore: Color, dim: int, chi: String) -> Control:
	var pannello := PanelContainer.new()
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color(0.03, 0.11, 0.13, 0.85)
	stile.border_color = Color(0.96, 0.78, 0.37, 0.55)
	stile.set_border_width_all(1)
	stile.set_corner_radius_all(12)
	pannello.add_theme_stylebox_override("panel", stile)

	var margine := MarginContainer.new()
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 14)
	pannello.add_child(margine)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margine.add_child(box)
	box.add_child(_sezione(chi))
	box.add_child(_paragrafo(testo, colore, dim))
	return pannello
