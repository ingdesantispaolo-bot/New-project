class_name PileMinigamePanel
extends Control

## **Il deposito delle decine**: il minigioco di Tobia, ricostruito da zero.
##
## Non si contano piu' decine di cristalli sotto cronometro. Il bambino prepara
## tre ordini costruendo ogni quantita' con casse da dieci e pezzi sciolti. La
## sfida e' leggere il valore posizionale, non cercare un gesto segreto o essere
## piu' rapido con il dito. Un errore mostra la differenza e lascia correggere il
## carico; l'unico modo di perdere e' abbandonare volontariamente.

signal risolto(vinto: bool, raccolti: int, totale: int)

const CRISTALLO := preload("res://assets/minigames/tobia-crystal-v1.png")
const COLORE_FONDO := Color("092b28")
const COLORE_CARTA := Color("0d3933")
const COLORE_ORO := Color("f4cf69")
const COLORE_MENTA := Color("82f1cf")
const COLORE_TESTO := Color("e9fffa")

var _scheda: Dictionary = {}
var _obiettivi: Array[int] = []
var _ordine := 0
var _consegnati := 0
var _decine := 0
var _unita := 0
var _attivo := false
var _in_chiusura := false
var _ordine_completato := false
var _reduced_motion := false

var _ordine_label: Label
var _bersaglio_label: Label
var _decine_label: Label
var _unita_label: Label
var _equazione: Label
var _feedback: Label
var _banchina: HBoxContainer
var _casse: GridContainer
var _sciolti: GridContainer
var _controlla: Button
var _comandi: Array[Button] = []


func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	var raw_obiettivi: Array = Array(parametri.get("obiettivi", [24, 30, 43]))
	_obiettivi.clear()
	for valore in raw_obiettivi:
		var numero := clampi(int(valore), 10, 99)
		if not _obiettivi.has(numero):
			_obiettivi.append(numero)
	if _obiettivi.is_empty():
		_obiettivi = [24, 30, 43]
	_ordine = 0
	_consegnati = 0
	_decine = 0
	_unita = 0
	_attivo = true
	_in_chiusura = false
	_ordine_completato = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_mostra_ordine()


static func valore(decine: int, unita: int) -> int:
	return maxi(0, decine) * 10 + clampi(unita, 0, 9)


static func scomponi(numero: int) -> Vector2i:
	var pulito := clampi(numero, 0, 99)
	return Vector2i(pulito / 10, pulito % 10)


func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "PileVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.015, 0.055, 0.05, 0.95)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var carta := PanelContainer.new()
	carta.name = "PileCard"
	carta.custom_minimum_size = Vector2(540, 0)
	carta.add_theme_stylebox_override("panel", _stile(COLORE_FONDO, COLORE_ORO, 22, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta)

	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 26)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 20)
	carta.add_child(margine)

	var colonna := VBoxContainer.new()
	colonna.name = "PileColumn"
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 10)
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "PileConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "PileTitle"
	titolo.text = str(_scheda.get("titolo", "Il deposito delle decine"))
	titolo.add_theme_font_size_override("font_size", 26)
	titolo.add_theme_color_override("font_color", COLORE_ORO)
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "PileBrief"
	consegna.text = str(_scheda.get("consegna", "Prepara gli ordini con casse da 10 e cristalli sciolti."))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 16)
	consegna.add_theme_color_override("font_color", COLORE_TESTO)
	colonna.add_child(consegna)

	var ordine_box := PanelContainer.new()
	ordine_box.name = "PileOrder"
	ordine_box.add_theme_stylebox_override("panel", _stile(COLORE_CARTA, Color("3f8976"), 14, 1))
	colonna.add_child(ordine_box)
	var ordine_colonna := VBoxContainer.new()
	ordine_colonna.add_theme_constant_override("separation", 2)
	ordine_box.add_child(ordine_colonna)
	_ordine_label = Label.new()
	_ordine_label.name = "PileProgress"
	_ordine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ordine_label.add_theme_font_size_override("font_size", 14)
	_ordine_label.add_theme_color_override("font_color", COLORE_MENTA)
	ordine_colonna.add_child(_ordine_label)
	_bersaglio_label = Label.new()
	_bersaglio_label.name = "PileTarget"
	_bersaglio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bersaglio_label.add_theme_font_size_override("font_size", 31)
	_bersaglio_label.add_theme_color_override("font_color", COLORE_ORO)
	ordine_colonna.add_child(_bersaglio_label)

	_banchina = HBoxContainer.new()
	_banchina.name = "PilePackingBay"
	_banchina.custom_minimum_size = Vector2(0, 102)
	_banchina.add_theme_constant_override("separation", 12)
	colonna.add_child(_banchina)
	var casse_box := _contenitore_banchina("CASSE", true)
	_banchina.add_child(casse_box)
	_casse = casse_box.find_child("PileCrates", true, false) as GridContainer
	var sciolti_box := _contenitore_banchina("SCIOLTI", false)
	_banchina.add_child(sciolti_box)
	_sciolti = sciolti_box.find_child("PileLoose", true, false) as GridContainer

	var controlli := HBoxContainer.new()
	controlli.name = "PileControls"
	controlli.alignment = BoxContainer.ALIGNMENT_CENTER
	controlli.add_theme_constant_override("separation", 12)
	colonna.add_child(controlli)
	controlli.add_child(_selettore("CASSE DA 10", true))
	controlli.add_child(_selettore("UNITÀ", false))

	_equazione = Label.new()
	_equazione.name = "PileEquation"
	_equazione.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equazione.add_theme_font_size_override("font_size", 22)
	_equazione.add_theme_color_override("font_color", COLORE_TESTO)
	colonna.add_child(_equazione)

	_feedback = Label.new()
	_feedback.name = "PileFeedback"
	_feedback.text = "Componi il numero, poi consegna."
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size = Vector2(0, 42)
	_feedback.add_theme_font_size_override("font_size", 15)
	_feedback.add_theme_color_override("font_color", COLORE_MENTA)
	colonna.add_child(_feedback)

	_controlla = Button.new()
	_controlla.name = "PileCheckButton"
	_controlla.text = "CONSEGNA"
	_controlla.custom_minimum_size = Vector2(0, 50)
	_controlla.add_theme_font_size_override("font_size", 18)
	_controlla.pressed.connect(_verifica)
	colonna.add_child(_controlla)

	var lascia := Button.new()
	lascia.name = "PileLeaveButton"
	lascia.text = "ESCI"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(_abbandona)
	colonna.add_child(lascia)


func _contenitore_banchina(etichetta: String, per_casse: bool) -> PanelContainer:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", _stile(Color("0b302c"), Color("286b5b"), 13, 1))
	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 5)
	box.add_child(colonna)
	var titolo := Label.new()
	titolo.text = etichetta
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.add_theme_font_size_override("font_size", 13)
	titolo.add_theme_color_override("font_color", COLORE_MENTA)
	colonna.add_child(titolo)
	var griglia := GridContainer.new()
	griglia.name = "PileCrates" if per_casse else "PileLoose"
	griglia.columns = 5
	griglia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	griglia.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonna.add_child(griglia)
	return box


func _selettore(etichetta: String, per_decine: bool) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(220, 74)
	box.add_theme_stylebox_override("panel", _stile(COLORE_CARTA, Color("3f8976"), 12, 1))
	var riga := HBoxContainer.new()
	riga.alignment = BoxContainer.ALIGNMENT_CENTER
	riga.add_theme_constant_override("separation", 8)
	box.add_child(riga)
	var meno := Button.new()
	meno.name = "PileRemoveTen" if per_decine else "PileRemoveOne"
	meno.text = "−"
	meno.tooltip_text = "Togli una cassa" if per_decine else "Togli un cristallo"
	meno.custom_minimum_size = Vector2(46, 46)
	meno.add_theme_font_size_override("font_size", 24)
	meno.pressed.connect((_cambia_decine if per_decine else _cambia_unita).bind(-1))
	riga.add_child(meno)
	_comandi.append(meno)
	var centro := VBoxContainer.new()
	centro.custom_minimum_size = Vector2(78, 0)
	centro.add_theme_constant_override("separation", 0)
	riga.add_child(centro)
	var label := Label.new()
	label.text = etichetta
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", COLORE_MENTA)
	centro.add_child(label)
	var valore_label := Label.new()
	valore_label.name = "PileTensValue" if per_decine else "PileUnitsValue"
	valore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valore_label.add_theme_font_size_override("font_size", 25)
	valore_label.add_theme_color_override("font_color", COLORE_ORO)
	centro.add_child(valore_label)
	if per_decine:
		_decine_label = valore_label
	else:
		_unita_label = valore_label
	var piu := Button.new()
	piu.name = "PileAddTen" if per_decine else "PileAddOne"
	piu.text = "+"
	piu.tooltip_text = "Aggiungi una cassa da 10" if per_decine else "Aggiungi un cristallo"
	piu.custom_minimum_size = Vector2(46, 46)
	piu.add_theme_font_size_override("font_size", 24)
	piu.pressed.connect((_cambia_decine if per_decine else _cambia_unita).bind(1))
	riga.add_child(piu)
	_comandi.append(piu)
	return box


func _mostra_ordine() -> void:
	_decine = 0
	_unita = 0
	_ordine_completato = false
	_ordine_label.text = "ORDINE %d DI %d" % [_ordine + 1, _obiettivi.size()]
	_bersaglio_label.text = "PREPARA %d CRISTALLI" % _obiettivi[_ordine]
	_feedback.text = "Componi il numero, poi consegna."
	_feedback.add_theme_color_override("font_color", COLORE_MENTA)
	_controlla.text = "CONSEGNA"
	_controlla.disabled = false
	_aggiorna_carico()


func _cambia_decine(delta: int) -> void:
	if not _attivo or _in_chiusura:
		return
	_decine = clampi(_decine + delta, 0, 9)
	_aggiorna_carico()


func _cambia_unita(delta: int) -> void:
	if not _attivo or _in_chiusura:
		return
	_unita = clampi(_unita + delta, 0, 9)
	_aggiorna_carico()


func _aggiorna_carico() -> void:
	_decine_label.text = str(_decine)
	_unita_label.text = str(_unita)
	_equazione.text = "%d decine + %d unità  =  %d" % [_decine, _unita, valore(_decine, _unita)]
	_svuota(_casse)
	_svuota(_sciolti)
	for indice in range(_decine):
		_casse.add_child(_crea_cassa(indice))
	for indice in range(_unita):
		_sciolti.add_child(_crea_cristallo(indice))
	for bottone in _comandi:
		bottone.disabled = not _attivo or _in_chiusura


func _crea_cassa(indice: int) -> PanelContainer:
	var cassa := PanelContainer.new()
	cassa.name = "TenCrate_%02d" % indice
	cassa.custom_minimum_size = Vector2(40, 48)
	cassa.add_theme_stylebox_override("panel", _stile(Color("503d20"), COLORE_ORO, 7, 2))
	var numero := Label.new()
	numero.text = "10"
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.add_theme_font_size_override("font_size", 16)
	numero.add_theme_color_override("font_color", COLORE_ORO)
	cassa.add_child(numero)
	return cassa


func _crea_cristallo(indice: int) -> TextureRect:
	var cristallo := TextureRect.new()
	cristallo.name = "LooseCrystal_%02d" % indice
	cristallo.texture = CRISTALLO
	cristallo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cristallo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cristallo.custom_minimum_size = Vector2(34, 42)
	cristallo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cristallo


func _verifica() -> void:
	if not _attivo or _in_chiusura:
		return
	if _ordine_completato:
		if _ordine + 1 >= _obiettivi.size():
			_concludi()
		else:
			_ordine += 1
			_mostra_ordine()
		return
	var ottenuto := valore(_decine, _unita)
	var richiesto := _obiettivi[_ordine]
	if ottenuto != richiesto:
		var differenza := absi(richiesto - ottenuto)
		_feedback.text = ("Mancano %d. Correggi decine o unita'." if ottenuto < richiesto else "Ce ne sono %d in piu'. Correggi il carico.") % differenza
		_feedback.add_theme_color_override("font_color", Color("ffb985"))
		return
	_consegnati += 1
	var parti := scomponi(richiesto)
	_feedback.text = "Esatto: %d decine e %d unità fanno %d." % [parti.x, parti.y, richiesto]
	_feedback.add_theme_color_override("font_color", COLORE_MENTA)
	_ordine_completato = true
	for bottone in _comandi:
		bottone.disabled = true
	_controlla.text = "AVANTI" if _ordine + 1 < _obiettivi.size() else "CONCLUDI"


func _concludi() -> void:
	_in_chiusura = true
	_controlla.text = "ORDINI COMPLETATI"
	_controlla.disabled = true
	for bottone in _comandi:
		bottone.disabled = true
	if _reduced_motion:
		_emetti_vittoria()
		return
	var tween := create_tween()
	tween.tween_interval(0.45)
	tween.tween_callback(_emetti_vittoria)


func _emetti_vittoria() -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(true, _consegnati, _obiettivi.size())


func _abbandona() -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(false, _consegnati, _obiettivi.size())


func _svuota(nodo: Node) -> void:
	if not is_instance_valid(nodo):
		return
	for figlio in nodo.get_children():
		figlio.queue_free()


func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	stile.content_margin_left = 10
	stile.content_margin_right = 10
	stile.content_margin_top = 8
	stile.content_margin_bottom = 8
	return stile
