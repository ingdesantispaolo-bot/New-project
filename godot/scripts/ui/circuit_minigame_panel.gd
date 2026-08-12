class_name CircuitMinigamePanel
extends Control

## **Il circuito mutante**: il minigioco di Ciro. (12 agosto 2026)
##
## La batteria alimenta una sola corsia della rete. Ogni nodo corretto accende il
## tratto successivo; a ogni lampada accesa la rete si riconfigura. Ricordare le
## posizioni funziona esattamente una volta, mentre seguire il flusso funziona
## sempre: e' la convinzione di Ciro che fallisce dentro la meccanica.
##
## Non c'e' cronometro. Il terzo pilot deve dimostrare che una prova impegnativa
## puo' venire da trasformazioni e distrattori, non dalla fretta. Un errore non
## resetta i nodi gia' capiti e mostra dove la corrente non arriva.

signal risolto(vinto: bool, completati: int, totale: int)

var _scheda: Dictionary = {}
var _schemi_totali := 3
var _passaggi := 3
var _errori_massimi := 4
var _schema_corrente := 0
var _errori := 0
var _attivo := false
var _reduced_motion := false

var _quadro: CircuitMinigameBoard
var _stato: Label
var _feedback: Label
var _glifo: ConvictionGlyph

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_schemi_totali = int(parametri.get("schemi", 3))
	_passaggi = int(parametri.get("passaggi", 3))
	_errori_massimi = int(parametri.get("errori", 4))
	_schema_corrente = 0
	_errori = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_avvia_schema()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "CircuitVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("020d16", 0.95)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	for alone_data in [
		{"pos": Vector2(-380, -210), "color": Color("1bdcc4", 0.10)},
		{"pos": Vector2(350, 200), "color": Color("ffc85a", 0.10)},
	]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = Vector2(alone_data["pos"])
		alone.size = Vector2(390, 390)
		alone.add_theme_stylebox_override("panel", _stile(
			Color(alone_data["color"]), Color.TRANSPARENT, 195, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "CircuitCard"
	carta.add_theme_stylebox_override("panel", _stile(
		Color("071c29", 0.99), Color("57dccc", 0.78), 24, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 18)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 18)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "CircuitColumn"
	colonna.custom_minimum_size = Vector2(550, 0)
	colonna.add_theme_constant_override("separation", 8)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "CircuitConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "CircuitTitle"
	titolo.text = str(_scheda.get("titolo", "Il circuito mutante"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "CircuitBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("dffbf7"))
	colonna.add_child(consegna)

	_stato = Label.new()
	_stato.name = "CircuitStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 16)
	_stato.add_theme_color_override("font_color", Color("8ff6d2"))
	colonna.add_child(_stato)

	_quadro = CircuitMinigameBoard.new()
	_quadro.name = "CircuitBoard"
	_quadro.nodo_scelto.connect(_nodo_scelto)
	_quadro.schema_acceso.connect(_schema_acceso)
	colonna.add_child(_quadro)

	_feedback = Label.new()
	_feedback.name = "CircuitFeedback"
	_feedback.custom_minimum_size = Vector2(0, 34)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.add_theme_font_size_override("font_size", 15)
	_feedback.add_theme_color_override("font_color", Color("bdd9df"))
	colonna.add_child(_feedback)

	var lascia := Button.new()
	lascia.name = "CircuitLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 46)
	lascia.pressed.connect(func():
		if _attivo:
			_attivo = false
			risolto.emit(false, _schema_corrente, _schemi_totali))
	colonna.add_child(lascia)

func _avvia_schema() -> void:
	if _schema_corrente >= _schemi_totali:
		_attivo = false
		_glifo.imposta_spezzato(true)
		risolto.emit(true, _schemi_totali, _schemi_totali)
		return
	_quadro.configura(_schema_corrente, _passaggi, _reduced_motion)
	_feedback.text = "La batteria pulsa. Quale nodo riceve davvero il lampo?"
	_feedback.add_theme_color_override("font_color", Color("bdd9df"))
	_aggiorna_stato()

func _nodo_scelto(corretto: bool) -> void:
	if not _attivo:
		return
	if corretto:
		_feedback.text = "Il lampo passa: il tratto successivo si è acceso."
		_feedback.add_theme_color_override("font_color", Color("8ff6d2"))
	else:
		_errori += 1
		_feedback.text = "Qui il lampo non arriva. Riparti dall'ultimo nodo acceso."
		_feedback.add_theme_color_override("font_color", Color("ff9aad"))
		if _errori > _errori_massimi:
			_attivo = false
			risolto.emit(false, _schema_corrente, _schemi_totali)
			return
	_aggiorna_stato()

func _schema_acceso() -> void:
	if not _attivo:
		return
	_schema_corrente += 1
	if _schema_corrente >= _schemi_totali:
		_avvia_schema()
		return
	_feedback.text = "Accesa! Il Delta sposta di nuovo tutti i collegamenti…"
	_feedback.add_theme_color_override("font_color", Color("f4cf69"))
	_aggiorna_stato()
	if _reduced_motion:
		call_deferred("_avvia_schema")
	else:
		var timer := get_tree().create_timer(0.55)
		timer.timeout.connect(_avvia_schema)

func _aggiorna_stato() -> void:
	if is_instance_valid(_stato):
		_stato.text = "SCHEMA %d/%d  ·  NODO %d/%d  ·  ERRORI %d/%d" % [
			mini(_schema_corrente + 1, _schemi_totali), _schemi_totali,
			mini(_quadro.passaggio_attivo() + 1, _passaggi), _passaggi,
			_errori, _errori_massimi]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile

func _adatta_verticale(carta: Control) -> void:
	await get_tree().process_frame
	var viewport_size := get_viewport_rect().size
	if viewport_size.y <= viewport_size.x or not is_instance_valid(carta):
		return
	carta.pivot_offset = carta.size * 0.5
	carta.scale = Vector2(2.0, 2.0)
