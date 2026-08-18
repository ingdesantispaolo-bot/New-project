class_name GlyphMinigamePanel
extends Control

## **Glifi vivi**: minigioco rapido di Livia.
##
## La parola copiata alla perfezione non basta a decidere la porta. La radice
## azzurra mostra la famiglia; la desinenza dorata mostra che cosa la parola fa.
## La legenda resta davanti al bambino per tutto il turno: il tempo misura il
## riconoscimento di un segno già spiegato, mai la velocità di lettura.

signal risolto(vinto: bool, completati: int, totale: int)

const GLYPH_BOARD := preload("res://scripts/ui/glyph_minigame_board.gd")

var _scheda: Dictionary = {}
var _glifi: Array = []
var _indice := 0
var _giusti := 0
var _errori := 0
var _errori_max := 3
var _secondi_per_glifo := 7.0
var _secondi := 7.0
var _attivo := false
var _risolvendo := false
var _reduced_motion := false

var _board
var _glifo_convinzione: ConvictionGlyph
var _orologio: Label
var _stato: Label
var _porte: Array[Button] = []

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var p: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(p.get("errori", 3))
	_secondi_per_glifo = float(p.get("secondi", 7.0)) * (1.5 if reduced_motion else 1.0)
	var quante := int(p.get("glifi", 6))
	var tutti: Array = Array(_scheda.get("glifi", []))
	_glifi = tutti.slice(0, mini(quante, tutti.size()))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	set_process(true)
	_nuovo_glifo()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "GlyphVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("100a1d", 0.98)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for dati in [
		{"p": Vector2(-370, -220), "c": Color("9b62ce", 0.11)},
		{"p": Vector2(355, 215), "c": Color("e9a84f", 0.09)},
	]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = dati["p"]
		alone.size = Vector2(380, 380)
		alone.add_theme_stylebox_override("panel", _stile(dati["c"], Color.TRANSPARENT, 190, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "GlyphCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("211630"), Color("b889dc"), 24, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta, 1.34)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 22)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 15)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "GlyphColumn"
	colonna.custom_minimum_size = Vector2(670, 0)
	colonna.add_theme_constant_override("separation", 7)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo_convinzione = ConvictionGlyph.new()
	_glifo_convinzione.name = "GlyphConvictionGlyph"
	testata.add_child(_glifo_convinzione)
	var titolo := Label.new()
	titolo.name = "GlyphTitle"
	titolo.text = str(_scheda.get("titolo", "Glifi vivi"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("ecd5ff"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "GlyphBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("f2eaff"))
	colonna.add_child(consegna)

	var guida := Label.new()
	guida.name = "GlyphGuide"
	guida.text = str(_scheda.get("guidaGlifi",
		"RADICE azzurra = famiglia   ·   FINE dorata:  -A / -US / -ER / -X → AGISCE   ·   -AM / -UM / -EM → RICEVE"))
	guida.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guida.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guida.add_theme_font_size_override("font_size", 14)
	guida.add_theme_color_override("font_color", Color("ffd98c"))
	guida.add_theme_stylebox_override("normal", _stile(Color("342344"), Color("765595"), 9, 1))
	colonna.add_child(guida)

	_orologio = Label.new()
	_orologio.name = "GlyphClock"
	_orologio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_orologio.add_theme_font_size_override("font_size", 15)
	_orologio.add_theme_color_override("font_color", Color("d2b2eb"))
	colonna.add_child(_orologio)

	_board = GLYPH_BOARD.new()
	_board.name = "GlyphBoard"
	colonna.add_child(_board)

	var riga_porte := HBoxContainer.new()
	riga_porte.alignment = BoxContainer.ALIGNMENT_CENTER
	riga_porte.add_theme_constant_override("separation", 18)
	colonna.add_child(riga_porte)
	var porte: Array = Array(_scheda.get("porte", ["CHI AGISCE", "CHI RICEVE"]))
	for i in 2:
		var b := Button.new()
		b.name = "GlyphDoor_%d" % i
		b.text = str(porte[i])
		b.tooltip_text = "Invia la pergamena alla funzione: %s" % str(porte[i]).to_lower()
		b.custom_minimum_size = Vector2(290, 58)
		b.add_theme_font_size_override("font_size", 19)
		var colore := Color("286763") if i == 0 else Color("76502c")
		var bordo := Color("79ded4") if i == 0 else Color("efb663")
		b.add_theme_stylebox_override("normal", _stile(colore, bordo, 13, 2))
		b.add_theme_stylebox_override("hover", _stile(colore.lightened(0.12), bordo.lightened(0.18), 13, 3))
		b.pressed.connect(_scegli_porta.bind(i))
		riga_porte.add_child(b)
		_porte.append(b)

	_stato = Label.new()
	_stato.name = "GlyphStatus"
	_stato.custom_minimum_size = Vector2(0, 36)
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("e6d8f2"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "GlyphLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _nuovo_glifo() -> void:
	if _indice >= _glifi.size():
		if is_instance_valid(_glifo_convinzione):
			_glifo_convinzione.imposta_spezzato(true)
		_chiudi(true)
		return
	_risolvendo = false
	_secondi = _secondi_per_glifo
	var voce: Dictionary = _glifi[_indice]
	_board.configura(str(voce.get("radice", "")), str(voce.get("fine", "")), _reduced_motion)
	_orologio.text = "INCHIOSTRO FRESCO  100%"
	_imposta_porte(true)
	_aggiorna("La copia è perfetta. La desinenza dice che cosa fa.")

func _process(delta: float) -> void:
	if not _attivo or _risolvendo:
		return
	_secondi -= delta
	_board.imposta_progresso(_secondi / _secondi_per_glifo)
	if is_instance_valid(_orologio):
		_orologio.text = "INCHIOSTRO FRESCO  %d%%" % int(ceil(100.0 * maxf(0.0, _secondi) / _secondi_per_glifo))
	if _secondi <= 0.0:
		_tempo_finito()

func _tempo_finito() -> void:
	_errori += 1
	if _errori > _errori_max:
		_chiudi(false)
		return
	_secondi = _secondi_per_glifo
	_board.pulisci_esito()
	_aggiorna("L'inchiostro si è asciugato. La parola resta: guarda soltanto la fine dorata.")

func _scegli_porta(porta: int) -> void:
	if not _attivo or _risolvendo or _indice >= _glifi.size():
		return
	var voce: Dictionary = _glifi[_indice]
	var giusta := int(voce.get("funzione", -1))
	_board.mostra_esito(porta, giusta)
	if porta != giusta:
		_errori += 1
		if _errori > _errori_max:
			_chiudi(false)
			return
		_secondi = _secondi_per_glifo
		_aggiorna(str(_scheda.get("correzione", "Guarda la desinenza dorata.")))
		return
	_risolvendo = true
	_imposta_porte(false)
	_giusti += 1
	_aggiorna(str(_scheda.get("successoGlifi",
		"La desinenza ha aperto la porta. La forma copiata da sola non poteva farlo.")))
	if not _reduced_motion:
		await get_tree().create_timer(0.28).timeout
	if not _attivo:
		return
	_indice += 1
	_nuovo_glifo()

func _imposta_porte(abilitate: bool) -> void:
	for b in _porte:
		b.disabled = not abilitate

func _aggiorna(messaggio: String) -> void:
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  passate %d/%d  ·  macchie %d/%d" % [
			messaggio, _giusti, _glifi.size(), _errori, _errori_max]

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	_risolvendo = false
	set_process(false)
	risolto.emit(vinto, _giusti, _glifi.size())

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
