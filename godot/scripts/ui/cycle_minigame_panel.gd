class_name CycleMinigamePanel
extends Control

## **Cento giri, tre mosse**: il minigioco di Ruggine.
##
## Il nastro non si svuota azionando il braccio a mano: ogni gesto sposta un
## pezzo e intanto ne arrivano altri. Tre mosse registrate una volta, invece,
## vengono ripetute dal braccio per tutto il lotto. Non è un quiz sui cicli: è
## il momento in cui la soluzione manuale smette visibilmente di reggere.

signal risolto(vinto: bool, completati: int, totale: int)

const COMANDI := ["PRENDI", "GIRA", "POSA"]
const SCHEMI := [[0, 1, 2], [1, 0, 2], [2, 1, 0], [0, 2, 1], [1, 2, 0], [2, 0, 1]]

var _scheda: Dictionary = {}
var _programma: Array[int] = []
var _schema: Array = []
var _ripetizioni := 3
var _fatti := 0
var _secondi := 18.0
var _attivo := false
var _reduced_motion := false

var _slot: Label
var _nastro: Label
var _stato: Label
var _cronometro: Label
var _avvia: Button

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_ripetizioni = int(parametri.get("ripetizioni", 3))
	_secondi = float(parametri.get("secondi", 18.0)) * (1.5 if reduced_motion else 1.0)
	_schema = Array(SCHEMI[posmod(int(_scheda.get("world", 3)) - 3, SCHEMI.size())])
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna()
	set_process(true)

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "CycleVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("17100b", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "CycleCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("302015"), Color("f4cf69"), 22, 2))
	centro.add_child(carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "CycleColumn"
	colonna.custom_minimum_size = Vector2(540, 0)
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "CycleConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "CycleTitle"
	titolo.text = str(_scheda.get("titolo", "Cento giri, tre mosse"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.name = "CycleBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("fff3dd"))
	colonna.add_child(consegna)
	_cronometro = Label.new()
	_cronometro.name = "CycleClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 20)
	_cronometro.add_theme_color_override("font_color", Color("ffca78"))
	colonna.add_child(_cronometro)
	_nastro = Label.new()
	_nastro.name = "CycleBelt"
	_nastro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nastro.add_theme_font_size_override("font_size", 26)
	_nastro.add_theme_color_override("font_color", Color("ffe2aa"))
	colonna.add_child(_nastro)
	_slot = Label.new()
	_slot.name = "CycleProgram"
	_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot.custom_minimum_size = Vector2(0, 64)
	_slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot.add_theme_font_size_override("font_size", 20)
	_slot.add_theme_color_override("font_color", Color("8ff6d2"))
	_slot.add_theme_stylebox_override("normal", _stile(Color("1c332d"), Color("72d8cf"), 14, 2))
	colonna.add_child(_slot)
	var comandi := HBoxContainer.new()
	comandi.alignment = BoxContainer.ALIGNMENT_CENTER
	comandi.add_theme_constant_override("separation", 8)
	colonna.add_child(comandi)
	for i in COMANDI.size():
		var b := Button.new()
		b.name = "CycleCommand_%d" % i
		b.text = str(COMANDI[i])
		b.custom_minimum_size = Vector2(150, 54)
		b.pressed.connect(_aggiungi.bind(i))
		comandi.add_child(b)
	_avvia = Button.new()
	_avvia.name = "CycleRunButton"
	_avvia.text = "AVVIA IL BRACCIO"
	_avvia.custom_minimum_size = Vector2(0, 52)
	_avvia.pressed.connect(_esegui)
	colonna.add_child(_avvia)
	_stato = Label.new()
	_stato.name = "CycleStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_color_override("font_color", Color("ffdfa0"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "CycleLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _aggiungi(comando: int) -> void:
	if not _attivo or _programma.size() >= 3:
		return
	_programma.append(comando)
	_aggiorna("Il braccio ricorda tre mosse.")

func _esegui() -> void:
	if not _attivo or _programma.size() != 3:
		_aggiorna("Al braccio mancano delle mosse.")
		return
	if _programma == _schema:
		_fatti = _ripetizioni
		_aggiorna("Il braccio continua da solo: il nastro è libero.")
		_chiudi(true)
		return
	_programma.clear()
	_aggiorna("Questa sequenza inceppa il braccio. Puoi cambiarla.")

func _process(delta: float) -> void:
	if not _attivo:
		return
	_secondi -= delta
	if _secondi <= 0.0:
		_secondi = 0.0
		_aggiorna("Il nastro ha traboccato.")
		_chiudi(false)
		return
	_aggiorna()

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	set_process(false)
	risolto.emit(vinto, _fatti, _ripetizioni)

func _aggiorna(messaggio: String = "") -> void:
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi al trabocco" % maxf(0.0, _secondi)
	if is_instance_valid(_nastro):
		_nastro.text = "Nastro: %d pezzi da lavorare" % max(0, _ripetizioni - _fatti)
	if is_instance_valid(_slot):
		var parole: Array[String] = []
		for comando in _programma:
			parole.append(str(COMANDI[comando]))
		while parole.size() < 3:
			parole.append("—")
		_slot.text = "  ".join(parole)
	if is_instance_valid(_stato):
		_stato.text = messaggio if messaggio != "" else "Registra una breve sequenza e prova il braccio."

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
