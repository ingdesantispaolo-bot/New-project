class_name RhythmCountPanel
extends Control

## La conta sotto il pane: gioco riflessivo di pattern, senza cronometro. Il
## bambino completa una filastrocca numerica posando pagnotte in ordine; può
## annullare, confrontare e riprovare. La regola emerge dai sette semi fra i
## battiti, non viene regalata nella consegna.

signal risolto(vinto: bool, completati: int, totale: int)

const RHYTHM_BOARD := preload("res://scripts/ui/rhythm_count_board.gd")
const STROFE := [
	{"sequenza": [7, 14, 21, 28, 35], "scelte": [21, 28, 30, 35, 36]},
	{"sequenza": [14, 21, 28, 35, 42], "scelte": [28, 32, 35, 40, 42]},
	{"sequenza": [28, 35, 42, 49, 56], "scelte": [42, 47, 49, 54, 56]},
	{"sequenza": [35, 42, 49, 56, 63], "scelte": [49, 55, 56, 61, 63]},
	{"sequenza": [49, 56, 63, 70, 77], "scelte": [63, 68, 70, 75, 77]},
]

var _scheda: Dictionary = {}
var _strofe: Array = []
var _indice := 0
var _inseriti: Array = []
var _errori := 0
var _errori_max := 4
var _attivo := false
var _reduced_motion := false

var _board
var _glifo: ConvictionGlyph
var _scelte: Array[Button] = []
var _stato: Label
var _conferma: Button
var _annulla: Button

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var p: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(p.get("errori", 4))
	var quante := mini(int(p.get("strofe", 3)), STROFE.size())
	_strofe = STROFE.slice(0, quante)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_nuova_strofa()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "RhythmVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("160d09", 0.98)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "RhythmCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("302017"), Color("e0a158"), 24, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta, 1.42)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 22)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 15)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.custom_minimum_size = Vector2(680, 0)
	colonna.add_theme_constant_override("separation", 8)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "RhythmConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.text = str(_scheda.get("titolo", "La conta sotto il pane"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("ffe1a3"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("fff2d2"))
	colonna.add_child(consegna)
	_board = RHYTHM_BOARD.new()
	_board.name = "RhythmBoard"
	colonna.add_child(_board)
	var riga := HBoxContainer.new()
	riga.name = "RhythmChoices"
	riga.alignment = BoxContainer.ALIGNMENT_CENTER
	riga.add_theme_constant_override("separation", 7)
	colonna.add_child(riga)
	for i in 5:
		var b := Button.new()
		b.name = "RhythmLoaf_%d" % i
		b.custom_minimum_size = Vector2(92, 52)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(_scegli.bind(i))
		riga.add_child(b)
		_scelte.append(b)
	var azioni := HBoxContainer.new()
	azioni.alignment = BoxContainer.ALIGNMENT_CENTER
	azioni.add_theme_constant_override("separation", 10)
	colonna.add_child(azioni)
	_annulla = Button.new()
	_annulla.name = "RhythmUndoButton"
	_annulla.text = "RIPRENDI L'ULTIMA"
	_annulla.custom_minimum_size = Vector2(220, 48)
	_annulla.pressed.connect(_annulla_ultima)
	azioni.add_child(_annulla)
	_conferma = Button.new()
	_conferma.name = "RhythmConfirmButton"
	_conferma.text = "INFORNA LA STROFA"
	_conferma.custom_minimum_size = Vector2(240, 48)
	_conferma.pressed.connect(_verifica)
	azioni.add_child(_conferma)
	_stato = Label.new()
	_stato.name = "RhythmStatus"
	_stato.custom_minimum_size = Vector2(0, 38)
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("f6d7a0"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "RhythmLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _nuova_strofa() -> void:
	if _indice >= _strofe.size():
		_glifo.imposta_spezzato(true)
		_chiudi(true)
		return
	_inseriti.clear()
	var strofa: Dictionary = _strofe[_indice]
	var scelte: Array = Array(strofa["scelte"])
	for i in _scelte.size():
		_scelte[i].text = str(scelte[i])
		_scelte[i].disabled = false
	_board.configura(Array(strofa["sequenza"]), _inseriti, _reduced_motion)
	_aggiorna("Due pagnotte sono già in fila. Continua lo stesso battito.")

func _scegli(indice_scelta: int) -> void:
	if not _attivo or _inseriti.size() >= 3:
		return
	var scelte: Array = Array(Dictionary(_strofe[_indice])["scelte"])
	var valore := int(scelte[indice_scelta])
	if valore in _inseriti:
		return
	_inseriti.append(valore)
	_scelte[indice_scelta].disabled = true
	_board.aggiorna_inseriti(_inseriti)
	_board.evidenzia(_inseriti.size() + 1)
	_aggiorna("Pagnotta posata. Puoi riprenderla prima di infornare.")

func _annulla_ultima() -> void:
	if not _attivo or _inseriti.is_empty():
		return
	var valore := int(_inseriti.pop_back())
	var scelte: Array = Array(Dictionary(_strofe[_indice])["scelte"])
	var posizione := scelte.find(valore)
	if posizione >= 0:
		_scelte[posizione].disabled = false
	_board.aggiorna_inseriti(_inseriti)
	_aggiorna("La pagnotta è tornata sul banco.")

func _verifica() -> void:
	if not _attivo:
		return
	if _inseriti.size() < 3:
		_aggiorna("La strofa ha ancora battiti vuoti.")
		return
	var soluzione: Array = Array(Dictionary(_strofe[_indice])["sequenza"]).slice(2)
	var corretta := _inseriti == soluzione
	_board.mostra_esito(corretta)
	if not corretta:
		_errori += 1
		if _errori > _errori_max:
			_chiudi(false)
			return
		_aggiorna("Il canto inciampa: fra due pagnotte il salto deve restare identico. Riprendile e prova ancora.")
		return
	_aggiorna("La strofa cammina sempre dello stesso salto: sette semi, sette passi.")
	for b in _scelte:
		b.disabled = true
	if not _reduced_motion:
		await get_tree().create_timer(0.35).timeout
	if not _attivo:
		return
	_indice += 1
	_nuova_strofa()

func _aggiorna(messaggio: String) -> void:
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  strofe %d/%d  ·  esitazioni %d/%d" % [
			messaggio, _indice, _strofe.size(), _errori, _errori_max]

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _indice if not vinto else _strofe.size(), _strofe.size())

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
