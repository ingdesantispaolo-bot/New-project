class_name TraceMinigamePanel
extends Control

## **La traccia fuori dalla testa**: l'archetipo della memoria esternalizzata.
## (12 agosto 2026)
##
## **Che cosa c'era di debole.** Nella prima stesura la stanza restava visibile
## mentre si componeva la striscia: si copiava una riga da sopra a sotto. Sesto
## crede che «se non me lo ricordo, vuol dire che non l'ho mai saputo» — per
## smentirlo bisogna **prima provare a ricordare e non riuscirci**. Un gioco in
## cui non si tenta mai la memoria non dice niente sulla memoria.
##
## **Adesso ci sono due tempi, e in mezzo cala la nebbia.**
##
##   1. **La stanza è aperta.** I segnali sono lì, in ordine. Si può guardare e
##      basta, oppure toccarli per **posarli sulla striscia** — che è il gesto
##      del prendere appunti, ma nessuno lo chiama così;
##   2. **la nebbia.** La stanza sparisce. Adesso bisogna rifare il percorso. Chi
##      ha la striscia la legge; chi non ce l'ha deve ricordare, e più avanti nei
##      mondi i segnali sono troppi perché regga.
##
## **La consegna non nomina la striscia**, ed è la regola del lotto: dire «prendi
## appunti» trasformerebbe la scoperta in un'istruzione da eseguire. La striscia
## sta lì, vuota, con le sue caselle. Chi la ignora perde una volta e capisce —
## e perdere non toglie niente.
##
## **Niente cronometro**: è un gioco di riflessione. Mettere fretta a chi deve
## accorgersi che la memoria non basta misurerebbe l'ansia, non l'idea.
##
## Segnali e cornice arrivano dalla scheda: per Sesto sono i gesti di un mestiere
## perduto, per Alma le coordinate di isole che la nebbia cancella.

signal risolto(vinto: bool, completati: int, totale: int)

const SEGNALI_PREDEFINITI := ["PONTE", "CHIAVE", "LENTE", "CAMPANA", "RUOTA", "MORSA", "PERNO"]

var _scheda: Dictionary = {}
var _vocabolario: Array = SEGNALI_PREDEFINITI
var _percorso: Array[int] = []
var _striscia: Array[int] = []
var _tentativo: Array[int] = []
var _errori := 0
var _errori_max := 3
var _attivo := false
var _velata := false
var _messaggio := ""

var _stanza: Label
var _striscia_label: Label
var _tentativo_label: Label
var _stato: Label
var _glifo: ConvictionGlyph
var _vela: Button
var _pulsanti: Array[Button] = []

func avvia(scheda: Dictionary, _reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var parametri: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(parametri.get("errori", 3))
	var quanti := int(parametri.get("segnali", 4))
	_vocabolario = Array(_scheda.get("segnali", SEGNALI_PREDEFINITI))
	if _vocabolario.size() < 3:
		_vocabolario = SEGNALI_PREDEFINITI
	quanti = clampi(quanti, 3, _vocabolario.size())
	# Il percorso è una permutazione stabile del mondo: due partite nello stesso
	# mondo si assomigliano, due mondi diversi no. Niente casualità, perché un
	# percorso che cambia a ogni tentativo punirebbe chi riprova.
	_percorso = []
	var seme := int(_scheda.get("world", 3)) * 7 + 3
	var disponibili: Array[int] = []
	for i in _vocabolario.size():
		disponibili.append(i)
	for passo in quanti:
		var scelto := posmod(seme + passo * 5, disponibili.size())
		_percorso.append(disponibili[scelto])
		disponibili.remove_at(scelto)
	_striscia = []
	_tentativo = []
	_errori = 0
	_velata = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna("La stanza è aperta.")

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "TraceVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("101025", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for posizione in [Vector2(-330, -210), Vector2(320, 200)]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = posizione
		alone.size = Vector2(340, 340)
		alone.add_theme_stylebox_override("panel", _stile(Color("8ba8ff", 0.09), Color.TRANSPARENT, 170, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "TraceCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("202148", 0.99), Color("8ba8ff", 0.8), 22, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "TraceColumn"
	colonna.custom_minimum_size = Vector2(580, 0)
	colonna.add_theme_constant_override("separation", 10)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "TraceConvictionGlyph"
	testata.add_child(_glifo)
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
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("f4f2ff"))
	colonna.add_child(consegna)

	_stanza = Label.new()
	_stanza.name = "TraceRoom"
	_stanza.custom_minimum_size = Vector2(0, 76)
	_stanza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stanza.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stanza.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stanza.add_theme_font_size_override("font_size", 20)
	_stanza.add_theme_color_override("font_color", Color("aee9e4"))
	_stanza.add_theme_stylebox_override("normal", _stile(Color("172b4a", 0.96), Color("72d8cf", 0.78), 14, 2))
	colonna.add_child(_stanza)

	# La striscia vuota è l'unico invito che il gioco si concede. Nessuna parola
	# la spiega: ha delle caselle, e le caselle chiedono di essere riempite.
	_striscia_label = Label.new()
	_striscia_label.name = "TraceStrip"
	_striscia_label.custom_minimum_size = Vector2(0, 62)
	_striscia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_striscia_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_striscia_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_striscia_label.add_theme_font_size_override("font_size", 17)
	_striscia_label.add_theme_color_override("font_color", Color("ffe3a0"))
	_striscia_label.add_theme_stylebox_override("normal", _stile(Color("3d2d31", 0.96), Color("f4cf69", 0.8), 14, 2))
	colonna.add_child(_striscia_label)

	_tentativo_label = Label.new()
	_tentativo_label.name = "TraceAttempt"
	_tentativo_label.custom_minimum_size = Vector2(0, 52)
	_tentativo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tentativo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tentativo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tentativo_label.add_theme_font_size_override("font_size", 17)
	_tentativo_label.add_theme_color_override("font_color", Color("8ff6d2"))
	_tentativo_label.add_theme_stylebox_override("normal", _stile(Color("1c332d", 0.94), Color("72d8cf", 0.7), 14, 2))
	colonna.add_child(_tentativo_label)

	var segnali := GridContainer.new()
	segnali.name = "TraceSignals"
	segnali.columns = mini(4, _vocabolario.size())
	segnali.add_theme_constant_override("h_separation", 7)
	segnali.add_theme_constant_override("v_separation", 7)
	colonna.add_child(segnali)
	for i in _vocabolario.size():
		var b := Button.new()
		b.name = "TraceSignal_%d" % i
		b.text = str(_vocabolario[i])
		b.custom_minimum_size = Vector2(136, 50)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_stylebox_override("normal", _stile(Color("2b2f5c", 0.96), Color("8ba8ff", 0.8), 12, 2))
		b.add_theme_stylebox_override("hover", _stile(Color("3b407a", 0.98), Color("dce5ff", 0.96), 12, 3))
		b.add_theme_stylebox_override("pressed", _stile(Color("2f775f", 0.98), Color("8ff6d2", 0.96), 12, 3))
		b.pressed.connect(_tocca.bind(i))
		segnali.add_child(b)
		_pulsanti.append(b)

	_vela = Button.new()
	_vela.name = "TraceVeilButton"
	_vela.text = "CALA LA NEBBIA"
	_vela.custom_minimum_size = Vector2(0, 52)
	_vela.pressed.connect(_cala_la_nebbia)
	colonna.add_child(_vela)

	_stato = Label.new()
	_stato.name = "TraceStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("d5d8ff"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "TraceLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

## Lo stesso gesto ha due significati, e cambia con la nebbia: a stanza aperta
## **posa un segno sulla striscia**, a stanza velata **rifà il percorso**. È la
## stessa mano che prima annota e poi esegue.
func _tocca(segnale: int) -> void:
	if not _attivo:
		return
	if not _velata:
		if _striscia.size() >= _percorso.size():
			return
		_striscia.append(segnale)
		_aggiorna("Sulla striscia: %s." % str(_vocabolario[segnale]))
		return
	if _tentativo.size() >= _percorso.size():
		return
	_tentativo.append(segnale)
	if int(_tentativo[_tentativo.size() - 1]) != int(_percorso[_tentativo.size() - 1]):
		_errori += 1
		_tentativo.clear()
		if _errori > _errori_max:
			_aggiorna("La nebbia ha coperto tutto troppe volte.")
			_chiudi(false)
			return
		_aggiorna("Non era questo il seguito. Il percorso riparte da capo.")
		return
	if _tentativo.size() == _percorso.size():
		if is_instance_valid(_glifo):
			_glifo.imposta_spezzato(true)
		_aggiorna("Il percorso è arrivato in fondo con la stanza chiusa.")
		_chiudi(true)
		return
	_aggiorna("")

func _cala_la_nebbia() -> void:
	if not _attivo or _velata:
		return
	_velata = true
	_vela.disabled = true
	_vela.text = "LA STANZA È CHIUSA"
	if _striscia.is_empty():
		_aggiorna("La stanza non c'è più. Adesso il percorso ce l'hai solo tu.")
	else:
		_aggiorna("La stanza non c'è più. La striscia sì.")

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _tentativo.size() if not vinto else _percorso.size(), _percorso.size())

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio = messaggio
	if is_instance_valid(_stanza):
		if _velata:
			_stanza.text = "N E B B I A"
		else:
			var lettura: Array[String] = []
			for segnale in _percorso:
				lettura.append(str(_vocabolario[segnale]))
			_stanza.text = "STANZA:   " + "   →   ".join(lettura)
	if is_instance_valid(_striscia_label):
		var segni: Array[String] = []
		for segnale in _striscia:
			segni.append(str(_vocabolario[segnale]))
		while segni.size() < _percorso.size():
			segni.append("▢")
		_striscia_label.text = "STRISCIA:   " + "   ".join(segni)
	if is_instance_valid(_tentativo_label):
		var passi: Array[String] = []
		for segnale in _tentativo:
			passi.append(str(_vocabolario[segnale]))
		while passi.size() < _percorso.size():
			passi.append("▢")
		_tentativo_label.text = "PERCORSO:   " + "   ".join(passi)
	if is_instance_valid(_stato):
		_stato.text = "%s   ·   errori %d/%d" % [_messaggio, _errori, _errori_max]

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
