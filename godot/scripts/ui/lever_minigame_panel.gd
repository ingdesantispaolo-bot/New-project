class_name LeverMinigamePanel
extends Control

const LEVER_MINIGAME_BOARD := preload("res://scripts/ui/lever_minigame_board.gd")

## **Fulcro!**: l'archetipo della leva. (12 agosto 2026)
##
## Gerbo crede che «le leve sono trucchi da deboli». Il gioco non gli chiede che
## cos'è un momento: gli mette davanti un masso che **con la sua forza non si
## alza**, e un punto d'appoggio che si può spostare.
##
## La regola è quella vera: si solleva se `FORZA × (braccio della mano) ≥ peso ×
## (braccio del masso)`. La forza della mano è **fissa e non si può aumentare**,
## quindi spingere più forte non è nemmeno un'opzione offerta — l'unica cosa che
## cambia è dove sta il fulcro. Non c'è una spiegazione da leggere: si prova, la
## trave non si muove, si sposta l'appoggio, e a un certo punto il masso sale.
##
## **Il fulcro torna sempre indietro dopo ogni masso.** Senza questo il gioco
## sarebbe «trova la posizione buona una volta»: con questo è un gesto che si
## impara e si ripete, e più avanti nei mondi il peso cresce e la posizione buona
## si stringe. Al mondo 24 ce n'è **una sola**, e va trovata in fretta.
##
## Perdere costa secondi e nient'altro: il masso rotola indietro e si ricomincia.

signal risolto(vinto: bool, sollevati: int, totale: int)

## La forza della mano, in unità arbitrarie. È **costante in tutti i mondi**, ed è
## il perno dell'intero gioco: se crescesse col mondo, spingere più forte
## tornerebbe una strategia e la convinzione di Gerbo non cadrebbe mai.
const FORZA := 10.0
const POSIZIONI := 12          # 0 = il masso, 12 = le mani
const FULCRO_INIZIALE := 8     # lontano dal masso: la posizione «da forza bruta»

var _scheda: Dictionary = {}
var _peso := 20.0
var _fulcro := FULCRO_INIZIALE
var _da_sollevare := 3
var _sollevati := 0
var _secondi := 22.0
var _penalita := 1.6
var _attivo := false
var _messaggio := ""
var _reduced_motion := false

var _trave
var _cronometro: Label
var _stato: Label
var _glifo: ConvictionGlyph
var _pulsanti: Array[Button] = []

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_peso = float(parametri.get("peso", 20.0))
	_da_sollevare = int(parametri.get("massi", 3))
	_secondi = float(parametri.get("secondi", 22.0))
	_penalita = float(parametri.get("penalita", 1.6))
	if reduced_motion:
		_secondi *= 1.5
	_fulcro = FULCRO_INIZIALE
	_sollevati = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna("Il masso è a terra.")
	set_process(true)

## Si solleva? La domanda che il gioco pone col legno invece che con le parole.
static func solleva(peso: float, fulcro: int) -> bool:
	if fulcro <= 0 or fulcro >= POSIZIONI:
		return false
	return FORZA * float(POSIZIONI - fulcro) >= peso * float(fulcro)

## La posizione più lontana dal masso che ancora funziona: serve all'audit, che
## deve poter dire «una soluzione esiste» senza rifare il gioco.
static func fulcro_utile(peso: float) -> int:
	for f in range(1, POSIZIONI):
		if solleva(peso, f):
			return f
	return -1

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "LeverVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("1a1206", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for posizione in [Vector2(-340, -215), Vector2(330, 205)]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = posizione
		alone.size = Vector2(340, 340)
		alone.add_theme_stylebox_override("panel", _stile(Color("d8a24a", 0.09), Color.TRANSPARENT, 170, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "LeverCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("2c2113", 0.99), Color("e6bd55", 0.8), 22, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "LeverColumn"
	colonna.custom_minimum_size = Vector2(600, 0)
	colonna.add_theme_constant_override("separation", 10)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "LeverConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "LeverTitle"
	titolo.text = str(_scheda.get("titolo", "Fulcro!"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "LeverBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("fff1d8"))
	colonna.add_child(consegna)

	_cronometro = Label.new()
	_cronometro.name = "LeverClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 19)
	_cronometro.add_theme_color_override("font_color", Color("ffca78"))
	colonna.add_child(_cronometro)

	# La tavola è vettoriale: la distanza fra masso, cuneo e mani si legge senza
	# formule e rimane nitida su qualunque densità di schermo.
	_trave = LEVER_MINIGAME_BOARD.new()
	_trave.name = "LeverBeam"
	_trave.configura(_peso, _fulcro, _reduced_motion)
	colonna.add_child(_trave)

	var etichetta := Label.new()
	etichetta.name = "LeverFulcrumLabel"
	etichetta.text = "DOVE APPOGGI IL CUNEO"
	etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta.add_theme_font_size_override("font_size", 13)
	etichetta.add_theme_color_override("font_color", Color("c9a878"))
	colonna.add_child(etichetta)

	var riga := GridContainer.new()
	riga.name = "LeverFulcrumRow"
	riga.columns = POSIZIONI - 1
	riga.add_theme_constant_override("h_separation", 4)
	colonna.add_child(riga)
	for posizione in range(1, POSIZIONI):
		var b := Button.new()
		b.name = "LeverFulcrum_%d" % posizione
		b.text = "%d" % posizione
		b.custom_minimum_size = Vector2(46, 46)
		b.focus_mode = Control.FOCUS_ALL
		b.tooltip_text = "Appoggia il cuneo a %d passi dal masso" % posizione
		b.pressed.connect(_sposta.bind(posizione))
		b.add_theme_stylebox_override("normal", _stile(Color("3b2a18"), Color("8e683b"), 9, 1))
		b.add_theme_stylebox_override("hover", _stile(Color("634525"), Color("f4cf69"), 9, 2))
		b.add_theme_stylebox_override("focus", _stile(Color("594020"), Color("fff0a8"), 9, 3))
		riga.add_child(b)
		_pulsanti.append(b)

	var spingi := Button.new()
	spingi.name = "LeverPushButton"
	spingi.text = "SPINGI"
	spingi.custom_minimum_size = Vector2(0, 58)
	spingi.add_theme_font_size_override("font_size", 20)
	spingi.add_theme_stylebox_override("normal", _stile(Color("4a3023", 0.96), Color("b98b4c", 0.86), 14, 2))
	spingi.add_theme_stylebox_override("hover", _stile(Color("69452c", 0.98), Color("f4cf69", 0.96), 14, 3))
	spingi.add_theme_stylebox_override("pressed", _stile(Color("2f775f", 0.98), Color("8ff6d2", 0.96), 14, 3))
	spingi.pressed.connect(_spingi)
	colonna.add_child(spingi)

	_stato = Label.new()
	_stato.name = "LeverStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("ffdfa0"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "LeverLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _sposta(posizione: int) -> void:
	if not _attivo:
		return
	_fulcro = posizione
	if is_instance_valid(_trave):
		_trave.imposta_fulcro(_fulcro)
	_aggiorna("Cuneo a %d." % posizione)

func _spingi() -> void:
	if not _attivo:
		return
	if not solleva(_peso, _fulcro):
		_secondi -= _penalita
		if is_instance_valid(_trave):
			_trave.mostra_esito(false)
		_aggiorna("La trave non si muove. Il masso rotola indietro.")
		return
	_sollevati += 1
	if is_instance_valid(_trave):
		_trave.mostra_esito(true)
	# Il cuneo torna dov'era: il gesto va rifatto, e diventa un gesto.
	_fulcro = FULCRO_INIZIALE
	if _sollevati >= _da_sollevare:
		if is_instance_valid(_glifo):
			_glifo.imposta_spezzato(true)
		_aggiorna("Su. Tutti.")
		_chiudi(true)
		return
	if is_instance_valid(_trave):
		_trave.imposta_fulcro(_fulcro)
	_aggiorna("Su! E ne arriva un altro.")

func _process(delta: float) -> void:
	if not _attivo:
		return
	_secondi -= delta
	if _secondi <= 0.0:
		_secondi = 0.0
		_aggiorna("Il tempo è finito.")
		_chiudi(false)
		return
	_aggiorna("")

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	set_process(false)
	risolto.emit(vinto, _sollevati, _da_sollevare)

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio = messaggio
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi" % maxf(0.0, _secondi)
	for i in _pulsanti.size():
		var selezionato := i + 1 == _fulcro
		_pulsanti[i].add_theme_color_override("font_color", Color("16231f") if selezionato else Color("f7dfb1"))
		if selezionato:
			_pulsanti[i].add_theme_stylebox_override("normal", _stile(Color("f1c85e"), Color("fff3b0"), 9, 3))
		else:
			_pulsanti[i].add_theme_stylebox_override("normal", _stile(Color("3b2a18"), Color("8e683b"), 9, 1))
	if is_instance_valid(_stato):
		_stato.text = "%s   ·   sollevati %d/%d" % [_messaggio, _sollevati, _da_sollevare]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
