class_name TraceMinigamePanel
extends Control

## **La traccia fuori dalla testa**: il minigioco di Sesto.
##
## I segnali della stanza restano davanti a Eli finché non li ha trasformati in
## una striscia esterna. Quando arriva la nebbia, quella striscia guida il
## braccio senza dover ricordare nulla: ciò che Sesto ha perso non era sparito,
## aveva solo bisogno di un posto dove restare.

signal risolto(vinto: bool, completati: int, totale: int)

const SEGNALI := ["PONTE", "CHIAVE", "LENTE", "CAMPANA", "RUOTA"]
const PERCORSI := [[0, 2, 1], [1, 0, 2], [2, 1, 0], [0, 1, 2], [1, 2, 0], [2, 0, 1]]

var _scheda: Dictionary = {}
var _percorso: Array = []
var _traccia: Array[int] = []
var _errori := 0
var _errori_max := 3
var _attivo := false
var _velata := false

var _stanza: Label
var _traccia_label: Label
var _stato: Label

func avvia(scheda: Dictionary, _reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var parametri: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(parametri.get("errori", 3))
	var quanti := int(parametri.get("segnali", 3))
	_percorso = Array(PERCORSI[posmod(int(_scheda.get("world", 3)) - 3, PERCORSI.size())]).slice(0, quanti)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "TraceVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("101025", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "TraceCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("202148"), Color("8ba8ff"), 22, 2))
	centro.add_child(carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "TraceColumn"
	colonna.custom_minimum_size = Vector2(560, 0)
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "TraceConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "TraceTitle"
	titolo.text = str(_scheda.get("titolo", "La traccia"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("dce5ff"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.name = "TraceBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("f4f2ff"))
	colonna.add_child(consegna)
	_stanza = Label.new()
	_stanza.name = "TraceRoom"
	_stanza.custom_minimum_size = Vector2(0, 76)
	_stanza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stanza.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stanza.add_theme_font_size_override("font_size", 22)
	_stanza.add_theme_color_override("font_color", Color("aee9e4"))
	_stanza.add_theme_stylebox_override("normal", _stile(Color("172b4a"), Color("72d8cf"), 14, 2))
	colonna.add_child(_stanza)
	_traccia_label = Label.new()
	_traccia_label.name = "TraceStrip"
	_traccia_label.custom_minimum_size = Vector2(0, 64)
	_traccia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_traccia_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_traccia_label.add_theme_font_size_override("font_size", 18)
	_traccia_label.add_theme_color_override("font_color", Color("ffe3a0"))
	_traccia_label.add_theme_stylebox_override("normal", _stile(Color("3d2d31"), Color("f4cf69"), 14, 2))
	colonna.add_child(_traccia_label)
	var segnali := HBoxContainer.new()
	segnali.alignment = BoxContainer.ALIGNMENT_CENTER
	segnali.add_theme_constant_override("separation", 7)
	colonna.add_child(segnali)
	for i in _percorso.size():
		var b := Button.new()
		b.name = "TraceSignal_%d" % i
		b.text = str(SEGNALI[i])
		b.custom_minimum_size = Vector2(165, 50)
		b.pressed.connect(_aggiungi.bind(i))
		segnali.add_child(b)
	var verifica := Button.new()
	verifica.name = "TraceVeilButton"
	verifica.text = "VELA LA STANZA"
	verifica.custom_minimum_size = Vector2(0, 52)
	verifica.pressed.connect(_vela_e_verifica)
	colonna.add_child(verifica)
	_stato = Label.new()
	_stato.name = "TraceStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_color_override("font_color", Color("d5d8ff"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "TraceLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _aggiungi(segnale: int) -> void:
	if not _attivo or _velata or _traccia.size() >= _percorso.size():
		return
	_traccia.append(segnale)
	_aggiorna("La traccia resta sul tavolo.")

func _vela_e_verifica() -> void:
	if not _attivo or _traccia.size() != _percorso.size():
		_aggiorna("La traccia non è completa.")
		return
	_velata = true
	if _traccia == _percorso:
		_aggiorna("La stanza sparisce. La traccia guida il braccio fino in fondo.")
		_chiudi(true)
		return
	_errori += 1
	_traccia.clear()
	_velata = false
	if _errori > _errori_max:
		_aggiorna("La nebbia ha coperto tutto troppe volte.")
		_chiudi(false)
		return
	_aggiorna("La traccia non portava fuori. Puoi lasciarne un'altra.")

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _percorso.size() if vinto else _traccia.size(), _percorso.size())

func _aggiorna(messaggio: String = "") -> void:
	if is_instance_valid(_stanza):
		var lettura: Array[String] = []
		for segnale in _percorso:
			lettura.append(str(SEGNALI[segnale]))
		_stanza.text = "NEBBIA" if _velata else "STANZA:  " + "  →  ".join(lettura)
	if is_instance_valid(_traccia_label):
		var segni: Array[String] = []
		for segnale in _traccia:
			segni.append(str(SEGNALI[segnale]))
		while segni.size() < _percorso.size():
			segni.append("—")
		_traccia_label.text = "TRACCIA:  " + "  →  ".join(segni)
	if is_instance_valid(_stato):
		_stato.text = "%s  Errori %d/%d" % [messaggio if messaggio != "" else "Scegli i segnali nell'ordine in cui servono.", _errori, _errori_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
