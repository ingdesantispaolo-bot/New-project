class_name RadioMinigamePanel
extends Control

## **Radio di burrasca**: il minigioco di Marea.
##
## Ogni luce riceve lo stesso bisogno espresso in parole diverse. Inseguire le
## singole parole manda il messaggio alla luce sbagliata; cogliere l'intenzione
## lo salva prima che il disturbo lo cancelli.

signal risolto(vinto: bool, completati: int, totale: int)

const LUCI := ["RIPARO", "AIUTO", "ATTENZIONE"]
const MESSAGGI := [
	["Le onde stanno salendo: cerco un posto calmo.", 0],
	["La mia barca entra acqua, mandate qualcuno.", 1],
	["Scogli davanti alla nebbia! Non passate di qui.", 2],
	["Posso attraccare dove il vento non mi prende?", 0],
	["Motore fermo: mi serve una mano, subito.", 1],
	["La campana suona: il canale non è sicuro.", 2],
	["Cerco una baia chiusa per aspettare la pioggia.", 0],
	["Non riesco a voltare la vela da solo.", 1],
	["Una corrente tira verso le rocce a est.", 2],
]

var _scheda: Dictionary = {}
var _coda: Array = []
var _indice := 0
var _giuste := 0
var _errori := 0
var _errori_max := 2
var _secondi := 5.0
var _attivo := false
var _reduced_motion := false
## **Il messaggio all'utente sopravvive al cronometro.** `_process` ridipinge la
## riga di stato a ogni fotogramma per aggiornare i secondi: senza tenere qui
## l'ultima frase, il riscontro dell'errore restava leggibile 16 millesimi di
## secondo, cioè non era leggibile affatto.
var _messaggio_corrente := ""

var _messaggio: Label
var _stato: Label
var _cronometro: Label

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(parametri.get("errori", 2))
	_secondi = float(parametri.get("secondi", 5.0)) * (1.5 if reduced_motion else 1.0)
	_coda = MESSAGGI.slice(0, int(parametri.get("messaggi", 5)))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_mostra()
	set_process(true)

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "RadioVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("071429", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "RadioCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("102a43"), Color("5dd6ff"), 22, 2))
	centro.add_child(carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "RadioColumn"
	colonna.custom_minimum_size = Vector2(560, 0)
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "RadioConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "RadioTitle"
	titolo.text = str(_scheda.get("titolo", "Radio di burrasca"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("b7efff"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.name = "RadioBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("e9faff"))
	colonna.add_child(consegna)
	_cronometro = Label.new()
	_cronometro.name = "RadioClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 19)
	_cronometro.add_theme_color_override("font_color", Color("ffd68a"))
	colonna.add_child(_cronometro)
	_messaggio = Label.new()
	_messaggio.name = "RadioMessage"
	_messaggio.custom_minimum_size = Vector2(0, 96)
	_messaggio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_messaggio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_messaggio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messaggio.add_theme_font_size_override("font_size", 21)
	_messaggio.add_theme_color_override("font_color", Color("dffbff"))
	_messaggio.add_theme_stylebox_override("normal", _stile(Color("153b58"), Color("72d8cf"), 14, 2))
	colonna.add_child(_messaggio)
	var luci := HBoxContainer.new()
	luci.alignment = BoxContainer.ALIGNMENT_CENTER
	luci.add_theme_constant_override("separation", 8)
	colonna.add_child(luci)
	for i in LUCI.size():
		var b := Button.new()
		b.name = "RadioLight_%d" % i
		b.text = str(LUCI[i])
		b.custom_minimum_size = Vector2(170, 58)
		b.pressed.connect(_scegli.bind(i))
		luci.add_child(b)
	_stato = Label.new()
	_stato.name = "RadioStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_color_override("font_color", Color("b9e8f7"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "RadioLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _mostra() -> void:
	if _indice >= _coda.size():
		_chiudi(true)
		return
	_secondi = float(Dictionary(_scheda.get("parametri", {})).get("secondi", 5.0)) * (1.5 if _reduced_motion else 1.0)
	_messaggio.text = "~ " + str(_coda[_indice][0]) + " ~"
	_aggiorna("Ascolta di che cosa ha bisogno, non le parole che usa.")

func _scegli(luce: int) -> void:
	if not _attivo:
		return
	if luce == int(_coda[_indice][1]):
		_giuste += 1
		_indice += 1
		_mostra()
		return
	_errori += 1
	if _errori > _errori_max:
		_chiudi(false)
		return
	_aggiorna("Quella luce non risponde al bisogno. Riprova il messaggio.")

func _process(delta: float) -> void:
	if not _attivo:
		return
	_secondi -= delta
	if _secondi <= 0.0:
		_secondi = 0.0
		_errore_tempo()
	_aggiorna()

func _errore_tempo() -> void:
	_errori += 1
	if _errori > _errori_max:
		_chiudi(false)
		return
	_aggiorna("Il disturbo ha portato via il messaggio. La radio lo ripete.")
	_mostra()

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	set_process(false)
	risolto.emit(vinto, _giuste, _coda.size())

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio_corrente = messaggio
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi di segnale" % maxf(0.0, _secondi)
	if is_instance_valid(_stato):
		_stato.text = "%s  Messaggi %d/%d · errori %d/%d" % [
			_messaggio_corrente, _giuste, _coda.size(), _errori, _errori_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
