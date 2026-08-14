class_name EstimateMinigamePanel
extends Control

## **Orbita a occhio**: l'archetipo della stima che converge. (12 agosto 2026)
##
## Solano crede che «stimare è tirare a indovinare». È la convinzione più
## difficile da smontare a parole, perché a parole si somigliano davvero. Si
## smonta con un numero: **quanti tiri servono**.
##
## Il bersaglio è nascosto in un intervallo. A ogni tiro il gioco dice soltanto
## *troppo corto* o *troppo lungo*. Chi usa quel riscontro dimezza ogni volta
## l'intervallo e arriva in una manciata di tiri; chi tira a caso deve incappare
## nella casella giusta, e le caselle sono molte di più dei tiri concessi.
##
## Il numero dei tiri **è tarato su quel confronto**: `character_minigame_audit`
## verifica in ogni mondo che la ricerca guidata dal riscontro entri nei tiri
## disponibili e che quella cieca non ci entri. È la differenza fra stimare e
## indovinare, scritta in aritmetica invece che in una spiegazione.
##
## Lo stesso archetipo serve a Nerea (la profondità, dove la prima sensazione del
## corpo è sistematicamente sbagliata e il riscontro la corregge) e a Silo (il
## volume che sotto una soglia non arriva e sopra un'altra satura). Cambia la
## grandezza, non la scoperta.

signal risolto(vinto: bool, presi: int, totale: int)

const PASSI := [-25, -5, -1, 1, 5, 25]

var _scheda: Dictionary = {}
var _intervallo := 120
var _tolleranza := 4
var _tiri_max := 7
var _tiri := 0
var _bersagli := 3
var _presi := 0
var _valore := 0
var _bersaglio := 0
var _secondi := 22.0
var _attivo := false
var _messaggio := ""

var _quadrante: Label
var _riscontro: Label
var _cronometro: Label
var _stato: Label
var _glifo: ConvictionGlyph

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var parametri: Dictionary = _scheda.get("parametri", {})
	_intervallo = int(parametri.get("intervallo", 120))
	_tolleranza = int(parametri.get("tolleranza", 4))
	_tiri_max = int(parametri.get("tiri", 7))
	_bersagli = int(parametri.get("bersagli", 3))
	_secondi = float(parametri.get("secondi", 22.0))
	if reduced_motion:
		_secondi *= 1.5
	_presi = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_nuovo_bersaglio()
	_attivo = true
	set_process(true)

## I bersagli dipendono dal mondo e dal numero d'ordine, non dal caso: due
## partite nello stesso mondo pongono lo stesso problema, e riprovare mette alla
## prova il metodo invece della fortuna.
func _nuovo_bersaglio() -> void:
	var seme := int(_scheda.get("world", 13)) * 37 + _presi * 61 + 17
	_bersaglio = 1 + posmod(seme, maxi(1, _intervallo - 1))
	_valore = int(round(float(_intervallo) / 2.0))
	_tiri = 0
	_messaggio = str(_scheda.get("apertura", "Un bersaglio nuovo, e non si vede."))
	if is_instance_valid(_riscontro):
		_riscontro.text = "—"
	_aggiorna("")

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "EstimateVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("0b1226", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for posizione in [Vector2(-330, -210), Vector2(320, 200)]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = posizione
		alone.size = Vector2(340, 340)
		alone.add_theme_stylebox_override("panel", _stile(Color("7f9dff", 0.09), Color.TRANSPARENT, 170, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "EstimateCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("16204a", 0.99), Color("9db4ff", 0.78), 22, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "EstimateColumn"
	colonna.custom_minimum_size = Vector2(580, 0)
	colonna.add_theme_constant_override("separation", 10)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "EstimateConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "EstimateTitle"
	titolo.text = str(_scheda.get("titolo", "Orbita a occhio"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("c9d6ff"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "EstimateBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("edf1ff")	)
	colonna.add_child(consegna)

	_cronometro = Label.new()
	_cronometro.name = "EstimateClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 19)
	_cronometro.add_theme_color_override("font_color", Color("ffca78"))
	colonna.add_child(_cronometro)

	_quadrante = Label.new()
	_quadrante.name = "EstimateDial"
	_quadrante.custom_minimum_size = Vector2(0, 76)
	_quadrante.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quadrante.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quadrante.add_theme_font_size_override("font_size", 30)
	_quadrante.add_theme_color_override("font_color", Color("8ff6d2"))
	_quadrante.add_theme_stylebox_override("normal", _stile(Color("1d2a5c", 0.96), Color("72d8cf", 0.78), 14, 2))
	colonna.add_child(_quadrante)

	_riscontro = Label.new()
	_riscontro.name = "EstimateFeedback"
	_riscontro.custom_minimum_size = Vector2(0, 52)
	_riscontro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_riscontro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_riscontro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_riscontro.add_theme_font_size_override("font_size", 19)
	_riscontro.add_theme_color_override("font_color", Color("ffd68a"))
	colonna.add_child(_riscontro)

	var passi := GridContainer.new()
	passi.name = "EstimateSteps"
	passi.columns = PASSI.size()
	passi.add_theme_constant_override("h_separation", 6)
	colonna.add_child(passi)
	for i in PASSI.size():
		var b := Button.new()
		b.name = "EstimateStep_%d" % i
		b.text = "%+d" % int(PASSI[i])
		b.custom_minimum_size = Vector2(84, 52)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_regola.bind(int(PASSI[i])))
		passi.add_child(b)

	var tira := Button.new()
	tira.name = "EstimateFireButton"
	tira.text = str(_scheda.get("azione", "LANCIA"))
	tira.custom_minimum_size = Vector2(0, 58)
	tira.add_theme_font_size_override("font_size", 20)
	tira.add_theme_stylebox_override("normal", _stile(Color("24356f", 0.96), Color("9db4ff", 0.86), 14, 2))
	tira.add_theme_stylebox_override("hover", _stile(Color("2f4791", 0.98), Color("dce5ff", 0.96), 14, 3))
	tira.add_theme_stylebox_override("pressed", _stile(Color("2f775f", 0.98), Color("8ff6d2", 0.96), 14, 3))
	tira.pressed.connect(_tira)
	colonna.add_child(tira)

	_stato = Label.new()
	_stato.name = "EstimateStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("bcc7f0"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "EstimateLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _regola(passo: int) -> void:
	if not _attivo:
		return
	_valore = clampi(_valore + passo, 0, _intervallo)
	_aggiorna("")

func _tira() -> void:
	if not _attivo:
		return
	_tiri += 1
	var scarto := _valore - _bersaglio
	if absi(scarto) <= _tolleranza:
		_presi += 1
		if _presi >= _bersagli:
			if is_instance_valid(_glifo):
				_glifo.imposta_spezzato(true)
			_aggiorna("Preso. Tutti.")
			_chiudi(true)
			return
		_riscontro.text = str(_scheda.get("centro", "Centro."))
		_nuovo_bersaglio()
		return
	if _tiri >= _tiri_max:
		_aggiorna("I tiri per questo bersaglio sono finiti. Ne arriva un altro.")
		_nuovo_bersaglio()
		return
	# **Solo la direzione, mai la distanza.** Dare anche lo scarto renderebbe il
	# secondo tiro esatto e non ci sarebbe niente da imparare.
	_riscontro.text = str(_scheda.get("corto", "Troppo corto.")) if scarto < 0 else str(
		_scheda.get("lungo", "Troppo lungo."))
	_aggiorna("")

func _process(delta: float) -> void:
	if not _attivo:
		return
	_secondi -= delta
	if _secondi <= 0.0:
		_secondi = 0.0
		_aggiorna("La finestra si è chiusa.")
		_chiudi(false)
		return
	_aggiorna("")

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	set_process(false)
	risolto.emit(vinto, _presi, _bersagli)

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio = messaggio
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi" % maxf(0.0, _secondi)
	if is_instance_valid(_quadrante):
		_quadrante.text = "%s   %d" % [str(_scheda.get("grandezza", "")), _valore]
	if is_instance_valid(_stato):
		_stato.text = "%s   ·   presi %d/%d   ·   tiri %d/%d" % [
			_messaggio, _presi, _bersagli, _tiri, _tiri_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
