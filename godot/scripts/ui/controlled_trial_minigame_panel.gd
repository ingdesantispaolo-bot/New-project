class_name ControlledTrialMinigamePanel
extends Control

## **Una cosa per volta**: l'archetipo della prova controllata. (12 agosto 2026)
##
## Ortensia crede che «se cambio tutto, prima o poi funziona». Gru crede che
## «l'errore è solo sfortuna». Sferza crede che «se non legge, spingi di più».
## Sono la stessa convinzione detta in tre mestieri: **che la causa si trovi per
## forza bruta**. Il gioco le smonta tutte e tre nello stesso modo.
##
## Ci sono N manopole e **una sola conta davvero**. Si sceglie una
## configurazione, si prova, e si vede se funziona. Le prove sono contate: sono
## esattamente N+1, cioè quante ne servono cambiando **una cosa per volta** a
## partire da una base. Chi cambia tutto a caso le brucia senza sapere niente.
##
## **Non c'è una punizione per chi cambia due manopole**: sarebbe una regola del
## gioco, e questo non è un gioco di regole. C'è che l'esito, in quel caso, **non
## dice quale delle due** — e il gioco lo scrive, perché è la frase che deve
## restare. La stretta è tutta lì: il numero di prove è finito, e l'informazione
## che ogni prova ti dà dipende da come l'hai impostata.
##
## Alla fine si nomina la causa. Sbagliare il nome è concesso: si può nominare
## di nuovo finché restano errori.
##
## Niente cronometro — è riflessione. Fretta e metodo non stanno nella stessa
## stanza.

signal risolto(vinto: bool, prove_usate: int, prove_totali: int)

var _scheda: Dictionary = {}
var _fattori: Array = []           # [{nome, valori: [basso, alto]}]
var _causa := 0
var _configurazione: Array[int] = []
var _ultima_provata: Array[int] = []
var _prove_usate := 0
var _prove_totali := 4
var _errori := 0
var _errori_max := 2
var _attivo := false
var _messaggio := ""

var _esito: Label
var _stato: Label
var _glifo: ConvictionGlyph
var _manopole: Array[Button] = []
var _accuse: Array[Button] = []

func avvia(scheda: Dictionary, _reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var parametri: Dictionary = _scheda.get("parametri", {})
	var quanti := int(parametri.get("fattori", 3))
	_prove_totali = int(parametri.get("prove", quanti + 1))
	_errori_max = int(parametri.get("errori", 2))
	var tutti: Array = Array(_scheda.get("fattori", []))
	_fattori = tutti.slice(0, mini(quanti, tutti.size()))
	# La causa dipende dal mondo, non dal caso: chi riprova ritrova lo stesso
	# problema, e riprovare serve a mettere alla prova un metodo — non la fortuna.
	_causa = posmod(int(_scheda.get("world", 10)) * 3 + 1, maxi(1, _fattori.size()))
	_configurazione = []
	for i in _fattori.size():
		_configurazione.append(0)
	_ultima_provata = []
	_prove_usate = 0
	_errori = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna("Tutte le manopole sono al primo scatto.")

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "TrialVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("08180f", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for posizione in [Vector2(-330, -210), Vector2(320, 200)]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = posizione
		alone.size = Vector2(340, 340)
		alone.add_theme_stylebox_override("panel", _stile(Color("57c98a", 0.09), Color.TRANSPARENT, 170, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "TrialCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("11301f", 0.99), Color("8ff6d2", 0.78), 22, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "TrialColumn"
	colonna.custom_minimum_size = Vector2(600, 0)
	colonna.add_theme_constant_override("separation", 10)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "TrialConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "TrialTitle"
	titolo.text = str(_scheda.get("titolo", "Una cosa per volta"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("8ff6d2"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "TrialBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("e4fff1"))
	colonna.add_child(consegna)

	var manopole := VBoxContainer.new()
	manopole.name = "TrialKnobs"
	manopole.add_theme_constant_override("separation", 6)
	colonna.add_child(manopole)
	for i in _fattori.size():
		var b := Button.new()
		b.name = "TrialKnob_%d" % i
		b.custom_minimum_size = Vector2(0, 52)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_stylebox_override("normal", _stile(Color("1b3f2a", 0.96), Color("57c98a", 0.8), 12, 2))
		b.add_theme_stylebox_override("hover", _stile(Color("27573a", 0.98), Color("8ff6d2", 0.96), 12, 3))
		b.pressed.connect(_gira.bind(i))
		manopole.add_child(b)
		_manopole.append(b)

	var prova := Button.new()
	prova.name = "TrialRunButton"
	prova.text = "PROVA"
	prova.custom_minimum_size = Vector2(0, 56)
	prova.add_theme_font_size_override("font_size", 20)
	prova.pressed.connect(_prova)
	colonna.add_child(prova)

	_esito = Label.new()
	_esito.name = "TrialOutcome"
	_esito.custom_minimum_size = Vector2(0, 64)
	_esito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_esito.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_esito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_esito.add_theme_font_size_override("font_size", 17)
	_esito.add_theme_color_override("font_color", Color("d8ffe9"))
	_esito.add_theme_stylebox_override("normal", _stile(Color("173926", 0.96), Color("57c98a", 0.7), 14, 2))
	colonna.add_child(_esito)

	var etichetta := Label.new()
	etichetta.name = "TrialAccuseLabel"
	etichetta.text = str(_scheda.get("domanda", "QUALE DELLE MANOPOLE È LA CAUSA?"))
	etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta.add_theme_font_size_override("font_size", 13)
	etichetta.add_theme_color_override("font_color", Color("a7d8bd"))
	colonna.add_child(etichetta)

	var accuse := GridContainer.new()
	accuse.name = "TrialAccuseRow"
	accuse.columns = mini(3, maxi(1, _fattori.size()))
	accuse.add_theme_constant_override("h_separation", 6)
	accuse.add_theme_constant_override("v_separation", 6)
	colonna.add_child(accuse)
	for i in _fattori.size():
		var b := Button.new()
		b.name = "TrialAccuse_%d" % i
		b.text = str(Dictionary(_fattori[i]).get("nome", "?"))
		b.custom_minimum_size = Vector2(180, 48)
		b.pressed.connect(_accusa.bind(i))
		accuse.add_child(b)
		_accuse.append(b)

	_stato = Label.new()
	_stato.name = "TrialStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("bfe8d3"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "TrialLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _gira(fattore: int) -> void:
	if not _attivo:
		return
	_configurazione[fattore] = 1 - int(_configurazione[fattore])
	_aggiorna("")

## Una prova. L'esito è onesto: funziona se e solo se la manopola che conta è
## sull'altro scatto. Quello che il gioco aggiunge non è un premio né una
## punizione — è **quanto quell'esito ti dice**, e dipende da quante cose hai
## mosso dall'ultima volta.
func _prova() -> void:
	if not _attivo:
		return
	if _prove_usate >= _prove_totali:
		_aggiorna("Le prove sono finite. Resta da dire quale.")
		return
	_prove_usate += 1
	var cambiate: Array[String] = []
	if not _ultima_provata.is_empty():
		for i in _configurazione.size():
			if int(_configurazione[i]) != int(_ultima_provata[i]):
				cambiate.append(str(Dictionary(_fattori[i]).get("nome", "?")))
	var riuscita := int(_configurazione[_causa]) == 1
	var testa := str(_scheda.get("successo", "Funziona.")) if riuscita else str(
		_scheda.get("fallimento", "Non funziona."))
	if cambiate.size() > 1:
		# La frase che deve restare, e per cui esiste tutto il minigioco.
		_esito.text = "%s\nMa fra una prova e l'altra sono cambiate %d cose (%s): questo esito non dice quale." % [
			testa, cambiate.size(), ", ".join(cambiate)]
	elif cambiate.size() == 1:
		_esito.text = "%s\nDall'ultima prova è cambiata solo «%s»." % [testa, cambiate[0]]
	else:
		_esito.text = testa
	_ultima_provata = _configurazione.duplicate()
	_aggiorna("")

func _accusa(fattore: int) -> void:
	if not _attivo:
		return
	if fattore == _causa:
		if is_instance_valid(_glifo):
			_glifo.imposta_spezzato(true)
		_aggiorna("Era quella.")
		_chiudi(true)
		return
	_errori += 1
	# **Sbagliare il nome costa una prova.** (21 agosto 2026) Prima nominare
	# era gratis, quindi si poteva tirare a indovinare senza toccare le
	# manopole: il metodo che questo gioco insegna era aggirabile ignorandolo.
	# Adesso un nome sbagliato consuma quello che consumerebbe un esperimento,
	# perche' e' quello che e': un tentativo speso senza aver isolato niente.
	_prove_usate = mini(_prove_usate + 1, _prove_totali)
	if _errori > _errori_max:
		_aggiorna("Non era quella, e i tentativi sono finiti.")
		_chiudi(false)
		return
	_aggiorna("Non è «%s»: quando cambia solo lei, l'esito non cambia." % str(
		Dictionary(_fattori[fattore]).get("nome", "?")))

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _prove_usate, _prove_totali)

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio = messaggio
	for i in _manopole.size():
		var fattore: Dictionary = _fattori[i]
		var valori: Array = Array(fattore.get("valori", ["basso", "alto"]))
		var scatto := int(_configurazione[i])
		_manopole[i].text = "%s:   %s" % [
			str(fattore.get("nome", "?")),
			str(valori[scatto]) if scatto < valori.size() else str(scatto)]
	if is_instance_valid(_stato):
		_stato.text = "%s   ·   prove %d/%d   ·   errori %d/%d" % [
			_messaggio, _prove_usate, _prove_totali, _errori, _errori_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
