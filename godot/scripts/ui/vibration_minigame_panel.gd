class_name VibrationMinigamePanel
extends Control

## **Corde sotto le dita**: Oreste confronta la stessa struttura ricevuta in
## due modi. In alto il banco la rende come pressioni sotto il palmo; in basso
## tre corde la rendono come onde. Il giocatore può riprodurre, scegliere,
## annullare e confrontare senza cronometro.

signal risolto(vinto: bool, completati: int, totale: int)

const VIBRATION_BOARD := preload("res://scripts/ui/vibration_minigame_board.gd")
const PATTERN_A := [1.0, 0.35, 0.65, 0.35]
const PATTERN_B := [0.35, 1.0, 0.35, 0.65]
const PATTERN_C := [0.65, 0.35, 1.0, 0.35]
const PATTERN_D := [1.0, 0.35, 0.35, 1.0]
const PATTERN_E := [0.35, 0.65, 1.0, 0.65]
const ROUND := [
	{"target": PATTERN_A, "corde": [PATTERN_C, PATTERN_A, PATTERN_B], "giusta": 1},
	{"target": PATTERN_D, "corde": [PATTERN_D, PATTERN_E, PATTERN_A], "giusta": 0},
	{"target": PATTERN_B, "corde": [PATTERN_E, PATTERN_C, PATTERN_B], "giusta": 2},
	{"target": PATTERN_C, "corde": [PATTERN_A, PATTERN_C, PATTERN_D], "giusta": 1},
	{"target": PATTERN_E, "corde": [PATTERN_B, PATTERN_D, PATTERN_E], "giusta": 2},
]

var _scheda: Dictionary = {}
var _round_totali := 3
var _round := 0
var _selezionata := -1
var _errori := 0
var _errori_max := 5
var _attivo := false
var _risolvendo := false
var _reduced_motion := false

var _board
var _glifo: ConvictionGlyph
var _stato: Label
var _corde: Array[Button] = []
var _confronta: Button
var _annulla: Button

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var p: Dictionary = _scheda.get("parametri", {})
	_round_totali = mini(int(p.get("prove", 3)), ROUND.size())
	_errori_max = int(p.get("errori", 5))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_avvia_round()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "VibrationVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("07191f", 0.98)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for dati in [
		{"p": Vector2(-360, -230), "c": Color("58d8cc", 0.10)},
		{"p": Vector2(350, 220), "c": Color("ffc86f", 0.09)},
	]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = dati["p"]
		alone.size = Vector2(370, 370)
		alone.add_theme_stylebox_override("panel", _stile(dati["c"], Color.TRANSPARENT, 185, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "VibrationCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("102d34"), Color("64d8ce"), 24, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta, 1.32)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 22)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 16)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "VibrationColumn"
	colonna.custom_minimum_size = Vector2(680, 0)
	colonna.add_theme_constant_override("separation", 7)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "VibrationConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "VibrationTitle"
	titolo.text = str(_scheda.get("titolo", "Corde sotto le dita"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("d8fff8"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "VibrationBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("e5faf7"))
	colonna.add_child(consegna)

	var legenda := HBoxContainer.new()
	legenda.alignment = BoxContainer.ALIGNMENT_CENTER
	legenda.add_theme_constant_override("separation", 22)
	colonna.add_child(legenda)
	for testo in ["PALMO · pressione", "CORDA · ampiezza"]:
		var l := Label.new()
		l.text = testo
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("ffd98a") if testo.begins_with("PALMO") else Color("96e9df"))
		legenda.add_child(l)

	_board = VIBRATION_BOARD.new()
	_board.name = "VibrationBoard"
	colonna.add_child(_board)

	var comandi := HBoxContainer.new()
	comandi.alignment = BoxContainer.ALIGNMENT_CENTER
	comandi.add_theme_constant_override("separation", 9)
	colonna.add_child(comandi)
	var ripeti := Button.new()
	ripeti.name = "VibrationReplayButton"
	ripeti.text = "SENTI / OSSERVA ANCORA"
	ripeti.tooltip_text = "Riproduci di nuovo il tremito: resta sempre visibile sul banco"
	ripeti.custom_minimum_size = Vector2(210, 50)
	ripeti.pressed.connect(_riproduci)
	comandi.add_child(ripeti)
	for i in 3:
		var b := Button.new()
		b.name = "VibrationString_%d" % i
		b.text = "CORDA %s" % ["I", "II", "III"][i]
		b.tooltip_text = "Confronta la corda %d con il tremito nel palmo" % (i + 1)
		b.custom_minimum_size = Vector2(128, 50)
		b.pressed.connect(_scegli.bind(i))
		comandi.add_child(b)
		_corde.append(b)

	var azioni := HBoxContainer.new()
	azioni.alignment = BoxContainer.ALIGNMENT_CENTER
	azioni.add_theme_constant_override("separation", 10)
	colonna.add_child(azioni)
	_annulla = Button.new()
	_annulla.name = "VibrationUndoButton"
	_annulla.text = "ANNULLA SCELTA"
	_annulla.custom_minimum_size = Vector2(210, 52)
	_annulla.pressed.connect(_annulla_scelta)
	azioni.add_child(_annulla)
	_confronta = Button.new()
	_confronta.name = "VibrationCompareButton"
	_confronta.text = "APPOGGIA LA MANO E CONFRONTA"
	_confronta.custom_minimum_size = Vector2(360, 54)
	_confronta.add_theme_font_size_override("font_size", 17)
	_confronta.add_theme_stylebox_override("normal", _stile(Color("2c625c"), Color("8ce7dc"), 13, 2))
	_confronta.add_theme_stylebox_override("hover", _stile(Color("3a7b72"), Color("d7fff8"), 13, 3))
	_confronta.pressed.connect(_verifica)
	azioni.add_child(_confronta)

	_stato = Label.new()
	_stato.name = "VibrationStatus"
	_stato.custom_minimum_size = Vector2(0, 34)
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("d5f4ef"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "VibrationLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _avvia_round() -> void:
	if _round >= _round_totali:
		_chiudi(true)
		return
	_selezionata = -1
	_risolvendo = false
	var dati: Dictionary = ROUND[_round]
	_board.configura(Array(dati["target"]), Array(dati["corde"]), -1, _reduced_motion)
	_imposta_interazione(true)
	_aggiorna("Osserva quali colpi sono lievi, medi o forti, e in quale ordine arrivano.")
	call_deferred("_riproduci")

func _riproduci() -> void:
	if _attivo and not _risolvendo:
		_board.riproduci_tremito()

func _scegli(indice: int) -> void:
	if not _attivo or _risolvendo:
		return
	_selezionata = indice
	_board.seleziona(indice)
	_aggiorna("Corda %s scelta. Puoi confrontarla o annullare." % ["I", "II", "III"][indice])

func _annulla_scelta() -> void:
	if not _attivo or _risolvendo:
		return
	_selezionata = -1
	_board.seleziona(-1)
	_aggiorna("Scelta annullata. Il tremito resta sul banco.")

func _verifica() -> void:
	if not _attivo or _risolvendo:
		return
	if _selezionata < 0:
		_aggiorna("Prima scegli una corda. Puoi riascoltare con gli occhi quante volte vuoi.")
		return
	var dati: Dictionary = ROUND[_round]
	var giusta := int(dati["giusta"])
	_board.mostra_esito(_selezionata, giusta)
	if _selezionata != giusta:
		_errori += 1
		if _errori > _errori_max:
			_chiudi(false)
			return
		_aggiorna("Non è lo stesso gesto: confronta forza e ordine dei quattro impulsi, poi riprova.")
		return
	_risolvendo = true
	_imposta_interazione(false)
	_aggiorna("È lo stesso ritmo: il palmo lo chiama pressione, la corda ampiezza.")
	if not _reduced_motion:
		await get_tree().create_timer(0.45).timeout
	if not _attivo:
		return
	_round += 1
	if _round >= _round_totali:
		if is_instance_valid(_glifo):
			_glifo.imposta_spezzato(true)
		_chiudi(true)
		return
	_avvia_round()

func _imposta_interazione(abilitata: bool) -> void:
	for b in _corde:
		b.disabled = not abilitata
	_confronta.disabled = not abilitata
	_annulla.disabled = not abilitata

func _aggiorna(messaggio: String) -> void:
	for i in _corde.size():
		_corde[i].modulate = Color.WHITE if i == _selezionata else Color("a9c6c3")
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  accordi %d/%d  ·  tentativi errati %d/%d" % [
			messaggio, _round, _round_totali, _errori, _errori_max]

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	_risolvendo = false
	risolto.emit(vinto, _round_totali if vinto else _round, _round_totali)

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
