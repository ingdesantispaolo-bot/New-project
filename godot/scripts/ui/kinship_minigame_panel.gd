class_name KinshipMinigamePanel
extends Control

## **Parenti nell'ombra**: il minigioco riflessivo di Zeno.
##
## Si formula prima un'ipotesi, poi si illuminano due parenti moderni e si può
## correggere la scelta. Confermare è possibile soltanto dopo entrambi gli
## indizi: una somiglianza singola può essere un caso, una famiglia è un metodo.

signal risolto(vinto: bool, completati: int, totale: int)

const KINSHIP_BOARD := preload("res://scripts/ui/kinship_minigame_board.gd")

var _scheda: Dictionary = {}
var _famiglie: Array = []
var _indice := 0
var _completate := 0
var _scelta := -1
var _indizi := 0
var _indizi_richiesti := 2
var _errori := 0
var _errori_max := 5
var _attivo := false
var _risolvendo := false
var _reduced_motion := false

var _board
var _glifo: ConvictionGlyph
var _ipotesi: Array[Button] = []
var _illumina: Button
var _annulla: Button
var _conferma: Button
var _stato: Label

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var p: Dictionary = _scheda.get("parametri", {})
	_indizi_richiesti = int(p.get("indizi", 2))
	_errori_max = int(p.get("errori", 5))
	var quante := int(p.get("famiglie", 3))
	var tutte: Array = Array(_scheda.get("famiglie", []))
	_famiglie = tutte.slice(0, mini(quante, tutte.size()))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_nuova_famiglia()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "KinshipVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("07131e", 0.98)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for dati in [
		{"p": Vector2(-360, -225), "c": Color("5ab7bd", 0.09)},
		{"p": Vector2(350, 220), "c": Color("d9a95b", 0.08)},
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
	carta.name = "KinshipCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("102536"), Color("6cb4bf"), 24, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta, 1.32)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 22)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 15)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "KinshipColumn"
	colonna.custom_minimum_size = Vector2(690, 0)
	colonna.add_theme_constant_override("separation", 7)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "KinshipConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "KinshipTitle"
	titolo.text = str(_scheda.get("titolo", "Parenti nell'ombra"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("d4fbf1"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "KinshipBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("e9f8f4"))
	colonna.add_child(consegna)

	var metodo := Label.new()
	metodo.name = "KinshipMethod"
	metodo.text = "1  IPOTIZZA   »   2  ILLUMINA DUE PARENTI   »   3  TIENI O CAMBIA   »   4  CONFERMA"
	metodo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metodo.add_theme_font_size_override("font_size", 13)
	metodo.add_theme_color_override("font_color", Color("f1c979"))
	colonna.add_child(metodo)

	_board = KINSHIP_BOARD.new()
	_board.name = "KinshipBoard"
	colonna.add_child(_board)

	var scelte := HBoxContainer.new()
	scelte.name = "KinshipChoices"
	scelte.alignment = BoxContainer.ALIGNMENT_CENTER
	scelte.add_theme_constant_override("separation", 9)
	colonna.add_child(scelte)
	for i in 3:
		var b := Button.new()
		b.name = "KinshipHypothesis_%d" % i
		b.custom_minimum_size = Vector2(185, 50)
		b.tooltip_text = "Formula o modifica l'ipotesi %d" % (i + 1)
		b.pressed.connect(_scegli.bind(i))
		scelte.add_child(b)
		_ipotesi.append(b)

	var azioni := HBoxContainer.new()
	azioni.alignment = BoxContainer.ALIGNMENT_CENTER
	azioni.add_theme_constant_override("separation", 9)
	colonna.add_child(azioni)
	_annulla = Button.new()
	_annulla.name = "KinshipUndoButton"
	_annulla.text = "ANNULLA IPOTESI"
	_annulla.custom_minimum_size = Vector2(170, 50)
	_annulla.pressed.connect(_annulla_scelta)
	azioni.add_child(_annulla)
	_illumina = Button.new()
	_illumina.name = "KinshipClueButton"
	_illumina.text = "ILLUMINA UN PARENTE"
	_illumina.custom_minimum_size = Vector2(230, 52)
	_illumina.add_theme_stylebox_override("normal", _stile(Color("285d5b"), Color("78d9ca"), 13, 2))
	_illumina.add_theme_stylebox_override("hover", _stile(Color("34736e"), Color("c6fff2"), 13, 3))
	_illumina.pressed.connect(_mostra_indizio)
	azioni.add_child(_illumina)
	_conferma = Button.new()
	_conferma.name = "KinshipConfirmButton"
	_conferma.text = "CONFERMA LA PARENTELA"
	_conferma.custom_minimum_size = Vector2(235, 52)
	_conferma.add_theme_stylebox_override("normal", _stile(Color("66512c"), Color("e5c374"), 13, 2))
	_conferma.add_theme_stylebox_override("hover", _stile(Color("80683b"), Color("fff0b0"), 13, 3))
	_conferma.pressed.connect(_verifica)
	azioni.add_child(_conferma)

	_stato = Label.new()
	_stato.name = "KinshipStatus"
	_stato.custom_minimum_size = Vector2(0, 36)
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("dcefea"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "KinshipLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _nuova_famiglia() -> void:
	if _indice >= _famiglie.size():
		if is_instance_valid(_glifo):
			_glifo.imposta_spezzato(true)
		_chiudi(true)
		return
	_scelta = -1
	_indizi = 0
	_risolvendo = false
	var famiglia: Dictionary = _famiglie[_indice]
	var significati: Array = Array(famiglia.get("significati", []))
	for i in _ipotesi.size():
		_ipotesi[i].text = str(significati[i]).to_upper()
	_board.configura(str(famiglia.get("antica", "")), Array(famiglia.get("parenti", [])), _reduced_motion)
	_imposta_interazione(true)
	_aggiorna("Prima formula un'ipotesi: non deve essere già certa per essere utile.")

func _scegli(indice: int) -> void:
	if not _attivo or _risolvendo:
		return
	_scelta = indice
	_board.imposta_ipotesi(_ipotesi[indice].text)
	_aggiorna("Ipotesi segnata. Ora cerca se una famiglia la sostiene.")

func _annulla_scelta() -> void:
	if not _attivo or _risolvendo:
		return
	_scelta = -1
	_board.imposta_ipotesi("")
	_aggiorna("Ipotesi annullata. Gli indizi scoperti restano validi.")

func _mostra_indizio() -> void:
	if not _attivo or _risolvendo:
		return
	if _scelta < 0:
		_aggiorna("Prima fai un'ipotesi: così l'indizio può confermarla oppure cambiarla.")
		return
	if _indizi >= _indizi_richiesti:
		_aggiorna("La famiglia è illuminata. Tieni l'ipotesi o cambiala, poi conferma.")
		return
	_indizi += 1
	_board.mostra_parenti(_indizi)
	if _indizi < _indizi_richiesti:
		_aggiorna("Un parente può somigliare per caso. Illuminane ancora uno.")
	else:
		_aggiorna("Due rami raccontano la stessa cosa. Tieni l'ipotesi o cambiala.")

func _verifica() -> void:
	if not _attivo or _risolvendo:
		return
	if _scelta < 0:
		_aggiorna("Manca un'ipotesi da verificare.")
		return
	if _indizi < _indizi_richiesti:
		_aggiorna("Serve tutta la famiglia: illumina due parenti prima di confermare.")
		return
	var famiglia: Dictionary = _famiglie[_indice]
	var giusta := int(famiglia.get("giusta", -1))
	if _scelta != giusta:
		_errori += 1
		_board.mostra_esito(false)
		if _errori > _errori_max:
			_chiudi(false)
			return
		_aggiorna("L'ipotesi non spiega entrambi i parenti. Cambiala: gli indizi restano.")
		return
	_board.mostra_esito(true)
	_risolvendo = true
	_imposta_interazione(false)
	_completate += 1
	_aggiorna("La famiglia sostiene l'ipotesi. Questo non è un tiro: è una prova.")
	if not _reduced_motion:
		await get_tree().create_timer(0.4).timeout
	if not _attivo:
		return
	_indice += 1
	_nuova_famiglia()

func _imposta_interazione(abilitata: bool) -> void:
	for b in _ipotesi:
		b.disabled = not abilitata
	_annulla.disabled = not abilitata
	_illumina.disabled = not abilitata
	_conferma.disabled = not abilitata

func _aggiorna(messaggio: String) -> void:
	for i in _ipotesi.size():
		_ipotesi[i].modulate = Color.WHITE if i == _scelta else Color("acc5c2")
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  famiglie %d/%d  ·  indizi %d/%d  ·  revisioni %d/%d" % [
			messaggio, _completate, _famiglie.size(), _indizi, _indizi_richiesti, _errori, _errori_max]

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	_risolvendo = false
	risolto.emit(vinto, _completate, _famiglie.size())

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
