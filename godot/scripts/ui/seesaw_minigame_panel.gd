class_name SeesawMinigamePanel
extends Control

## **L'altalena delle prove**: il minigioco di Tilla.
##
## Si sposta una cesta, si dichiara una previsione e solo dopo si prova. Le tre
## configurazioni vengono osservate da Gerbo, da Gerbo girato e da nessuno: il
## risultato dipende da pesi e distanze, non da chi crede a Tilla.

signal risolto(vinto: bool, completati: int, totale: int)

const SEESAW_BOARD := preload("res://scripts/ui/seesaw_minigame_board.gd")
const ROUND := [
	{"sx": 2, "dsx": 4, "dx": 4, "soluzione": 2, "osservatore": 0},
	{"sx": 3, "dsx": 2, "dx": 2, "soluzione": 3, "osservatore": 1},
	{"sx": 4, "dsx": 1, "dx": 1, "soluzione": 4, "osservatore": 2},
]
const OSSERVATORI := ["GERBO GUARDA", "GERBO È GIRATO", "NESSUNO GUARDA"]

var _scheda: Dictionary = {}
var _round_totali := 3
var _round := 0
var _distanza_dx := 4
var _previsione := 99
var _errori := 0
var _errori_max := 5
var _attivo := false
var _reduced_motion := false

var _board
var _osservatore: Label
var _stato: Label
var _distanze: Array[Button] = []
var _previsioni: Array[Button] = []

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

static func esito(massa_sx: int, distanza_sx: int, massa_dx: int, distanza_dx: int) -> int:
	var sinistra := massa_sx * distanza_sx
	var destra := massa_dx * distanza_dx
	return -1 if sinistra > destra else 1 if destra > sinistra else 0

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "SeesawVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("0c1f20", 0.97)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for dati in [{"p": Vector2(-350, -220), "c": Color("66d7c7", 0.09)}, {"p": Vector2(330, 210), "c": Color("f4b565", 0.09)}]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = dati["p"]
		alone.size = Vector2(350, 350)
		alone.add_theme_stylebox_override("panel", _stile(dati["c"], Color.TRANSPARENT, 175, 0))
		add_child(alone)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "SeesawCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("153638"), Color("7adfd2"), 24, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 22)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "SeesawColumn"
	colonna.custom_minimum_size = Vector2(650, 0)
	colonna.add_theme_constant_override("separation", 8)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "SeesawConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "SeesawTitle"
	titolo.text = str(_scheda.get("titolo", "L'altalena delle prove"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("c8fff4"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.name = "SeesawBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("e8fff9"))
	colonna.add_child(consegna)
	_osservatore = Label.new()
	_osservatore.name = "SeesawObserver"
	_osservatore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_osservatore.add_theme_font_size_override("font_size", 14)
	_osservatore.add_theme_color_override("font_color", Color("ffd790"))
	colonna.add_child(_osservatore)
	_board = SEESAW_BOARD.new()
	_board.name = "SeesawBoard"
	colonna.add_child(_board)
	var etichetta_distanza := Label.new()
	etichetta_distanza.text = "DOVE METTI LA CESTA ARANCIONE?"
	etichetta_distanza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta_distanza.add_theme_color_override("font_color", Color("f7bd7b"))
	colonna.add_child(etichetta_distanza)
	var distanze := HBoxContainer.new()
	distanze.alignment = BoxContainer.ALIGNMENT_CENTER
	distanze.add_theme_constant_override("separation", 10)
	colonna.add_child(distanze)
	for d in range(1, 5):
		var b := Button.new()
		b.name = "SeesawDistance_%d" % d
		b.text = "%d" % d
		b.custom_minimum_size = Vector2(92, 48)
		b.tooltip_text = "Metti la cesta a %d tacche dal centro" % d
		b.pressed.connect(_scegli_distanza.bind(d))
		distanze.add_child(b)
		_distanze.append(b)
	var etichetta_previsione := Label.new()
	etichetta_previsione.text = "PRIMA DI PROVARE: CHE COSA SUCCEDERÀ?"
	etichetta_previsione.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta_previsione.add_theme_color_override("font_color", Color("bcece5"))
	colonna.add_child(etichetta_previsione)
	var previsioni := HBoxContainer.new()
	previsioni.alignment = BoxContainer.ALIGNMENT_CENTER
	previsioni.add_theme_constant_override("separation", 10)
	colonna.add_child(previsioni)
	for dati in [{"t": "GIÙ A SINISTRA", "v": -1}, {"t": "IN EQUILIBRIO", "v": 0}, {"t": "GIÙ A DESTRA", "v": 1}]:
		var b := Button.new()
		b.name = "SeesawPredict_%d" % (int(dati["v"]) + 1)
		b.text = str(dati["t"])
		b.custom_minimum_size = Vector2(182, 50)
		b.pressed.connect(_scegli_previsione.bind(int(dati["v"])))
		previsioni.add_child(b)
		_previsioni.append(b)
	var prova := Button.new()
	prova.name = "SeesawRunButton"
	prova.text = "PROVA L'ALTALENA"
	prova.custom_minimum_size = Vector2(0, 56)
	prova.add_theme_font_size_override("font_size", 19)
	prova.add_theme_stylebox_override("normal", _stile(Color("315f58"), Color("87e7d8"), 14, 2))
	prova.add_theme_stylebox_override("hover", _stile(Color("3d776d"), Color("c8fff4"), 14, 3))
	prova.pressed.connect(_prova)
	colonna.add_child(prova)
	_stato = Label.new()
	_stato.name = "SeesawStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("d4f8f1"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "SeesawLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _avvia_round() -> void:
	if _round >= _round_totali:
		_chiudi(true)
		return
	var dati: Dictionary = ROUND[_round]
	_distanza_dx = 4
	_previsione = 99
	_osservatore.text = OSSERVATORI[int(dati["osservatore"])]
	_board.configura(int(dati["sx"]), int(dati["dsx"]), int(dati["dx"]), _distanza_dx, int(dati["osservatore"]), _reduced_motion)
	_aggiorna("Sposta la cesta, poi fai una previsione.")

func _scegli_distanza(distanza: int) -> void:
	if not _attivo:
		return
	_distanza_dx = distanza
	_board.imposta_distanza(distanza)
	_aggiorna("Cesta arancione a %d tacche." % distanza)

func _scegli_previsione(previsione: int) -> void:
	if not _attivo:
		return
	_previsione = previsione
	_aggiorna("Previsione registrata. Ora prova.")

func _prova() -> void:
	if not _attivo or _previsione == 99:
		_aggiorna("Prima scegli che cosa pensi che succederà.")
		return
	var dati: Dictionary = ROUND[_round]
	var risultato := esito(int(dati["sx"]), int(dati["dsx"]), int(dati["dx"]), _distanza_dx)
	_board.mostra_esito(risultato)
	if _previsione != risultato:
		_errori += 1
		if _errori > _errori_max:
			_chiudi(false)
			return
		_aggiorna("La previsione non torna: guarda quale braccio scende e riprova.")
		return
	if risultato != 0:
		_errori += 1
		if _errori > _errori_max:
			_chiudi(false)
			return
		_aggiorna("Avevi previsto bene. Ora riesci a portarla in equilibrio?")
		return
	_round += 1
	if _round >= _round_totali:
		_chiudi(true)
		return
	_aggiorna("In equilibrio. Cambia chi guarda, non cambia la regola.")
	call_deferred("_avvia_round")

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _round, _round_totali)

func _aggiorna(messaggio: String) -> void:
	for i in _distanze.size():
		_distanze[i].modulate = Color.WHITE if i + 1 == _distanza_dx else Color("b8c8c5")
	for i in _previsioni.size():
		_previsioni[i].modulate = Color.WHITE if i - 1 == _previsione else Color("b8c8c5")
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  equilibri %d/%d  ·  tentativi errati %d/%d" % [messaggio, _round, _round_totali, _errori, _errori_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile

func _adatta_verticale(carta: Control) -> void:
	await get_tree().process_frame
	if get_viewport_rect().size.y > get_viewport_rect().size.x and is_instance_valid(carta):
		carta.pivot_offset = carta.size * 0.5
		carta.scale = Vector2(1.42, 1.42)
