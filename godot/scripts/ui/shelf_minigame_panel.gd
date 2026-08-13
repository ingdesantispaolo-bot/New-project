class_name ShelfMinigamePanel
extends Control

## **Lo scaffale che non si vede**: il minigioco di Corinna. (9 agosto 2026)
##
## Corinna crede che «l'ordine giusto è quello che si vede», e per questo mette
## le parole in fila dalla più corta alla più lunga: è l'unico ordine che si può
## controllare a occhio.
##
## Il gioco le presenta **già ordinate per lunghezza** — l'ordine di Corinna, in
## bella vista — e chiede di rimetterle sugli scaffali. Chi segue la lunghezza
## sbaglia, perché la lunghezza non dice niente sulla funzione: «re» e «va» sono
## lunghe uguali e vanno su scaffali diversi. È l'esca, ed è tutto il gioco.
##
## **Nessun cronometro, e non è una dimenticanza.** È l'altra famiglia rispetto
## al mucchio di Tobia: lì la fretta era il punto, qui sarebbe il difetto —
## mettere fretta a chi deve accorgersi di una regola invisibile misura l'ansia,
## non l'idea. Il gioco finisce quando le parole finiscono, o quando gli errori
## concessi si esauriscono.
##
## **Perché gli errori concessi non scendono mai a zero.** Sbagliare è il modo in
## cui si scopre che la lunghezza non funziona: una prova in cui il primo tocco
## decide tutto non si gioca, si subisce. Ogni errore mostra la parola tornare al
## suo posto, che è l'informazione che serve.

signal risolto(vinto: bool, giuste: int, totale: int)

var _scheda: Dictionary = {}
var _parole: Array = []            # [{testo, scaffale}]
var _indice := 0
var _giuste := 0
var _errori := 0
var _errori_max := 3
var _attivo := false
var _reduced_motion := false

var _parola: Label
var _esca: Label
var _scheda_parola: PanelContainer
var _stato: Label
var _pulsanti: Array = []

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(parametri.get("errori", 3))
	var quante := int(parametri.get("parole", 8))
	var tutte: Array = Array(_scheda.get("parole", []))
	# **L'esca, che è tutto il gioco.**
	#
	# Le voci arrivano ordinate secondo un criterio che si vede benissimo e che
	# **non c'entra niente** con lo scaffale giusto. Per Corinna è la lunghezza:
	# «re» e «va» sono lunghe uguali e vanno su scaffali diversi. Per Danio è
	# quante persone lo ripetono, per Vesca quanto è forte una specie: chi segue
	# il numero grande sbaglia, ed è esattamente la cosa da capire.
	#
	# Una voce può quindi avere due forme: `[testo, scaffale]` — e allora l'esca è
	# la lunghezza — oppure `[testo, scaffale, etichetta, valore]`, e allora
	# l'esca è il valore, scritto sotto la parola perché sia impossibile
	# ignorarlo. Presentarle mescolate toglierebbe al gioco la sua unica bugia.
	tutte.sort_custom(func(a, b): return _peso_esca(a) < _peso_esca(b))
	_parole = []
	for voce in tutte.slice(0, mini(quante, tutte.size())):
		var riga: Array = Array(voce)
		_parole.append({
			"testo": str(riga[0]),
			"scaffale": int(riga[1]),
			"esca": str(riga[2]) if riga.size() > 2 else "",
		})
	_indice = 0
	_giuste = 0
	_errori = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_mostra()

## Quanto «pesa» una voce per l'ordinamento-esca: chi pesa meno viene mostrato
## per primo. Con quattro elementi il criterio è il valore dichiarato, al
## contrario (il numero più grande in cima, come farebbe una classifica); con
## due è la lunghezza del testo.
func _peso_esca(voce: Variant) -> float:
	var riga: Array = Array(voce)
	if riga.size() > 3:
		return -float(riga[3])
	return float(str(riga[0]).length())

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "ShelfVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.03, 0.05, 0.09, 0.94)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for alone_data in [
		{"pos": Vector2(-330, -190), "color": Color("5a8bc7", 0.10)},
		{"pos": Vector2(310, 210), "color": Color("e6bd55", 0.09)},
	]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = Vector2(alone_data["pos"])
		alone.size = Vector2(360, 360)
		alone.add_theme_stylebox_override("panel", _stile_pannello(
			Color(alone_data["color"]), Color(0, 0, 0, 0), 180, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "ShelfCard"
	carta.add_theme_stylebox_override("panel", _stile_pannello(
		Color("101d35", 0.98), Color("e6bd55", 0.78), 22, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right"]:
		margine.add_theme_constant_override(lato, 30)
	for lato in ["margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "ShelfColumn"
	colonna.custom_minimum_size = Vector2(520, 0)
	colonna.add_theme_constant_override("separation", 14)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "ShelfConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "ShelfTitle"
	titolo.text = str(_scheda.get("titolo", "Lo scaffale"))
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "ShelfBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("e7fffb"))
	colonna.add_child(consegna)

	_scheda_parola = PanelContainer.new()
	_scheda_parola.name = "ShelfWordCard"
	_scheda_parola.custom_minimum_size = Vector2(0, 92)
	_scheda_parola.add_theme_stylebox_override("panel", _stile_pannello(
		Color("18375a", 0.94), Color("72d8cf", 0.72), 16, 2))
	colonna.add_child(_scheda_parola)
	var pila := VBoxContainer.new()
	pila.alignment = BoxContainer.ALIGNMENT_CENTER
	_scheda_parola.add_child(pila)
	_parola = Label.new()
	_parola.name = "ShelfWord"
	_parola.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_parola.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parola.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_parola.add_theme_font_size_override("font_size", 34)
	_parola.add_theme_color_override("font_color", Color("8ff6d2"))
	pila.add_child(_parola)
	# L'esca dichiarata, sotto la parola. Non è un aiuto: è la cosa che sembra
	# contare e non conta, e va vista bene perché la si possa scartare.
	_esca = Label.new()
	_esca.name = "ShelfLure"
	_esca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_esca.add_theme_font_size_override("font_size", 14)
	_esca.add_theme_color_override("font_color", Color("c8a7d8"))
	pila.add_child(_esca)

	var riga := HBoxContainer.new()
	riga.name = "ShelfRow"
	riga.add_theme_constant_override("separation", 12)
	colonna.add_child(riga)
	var scaffali: Array = Array(_scheda.get("scaffali", ["A", "B"]))
	var larghezza_scaffale: float = floor((520.0 - 12.0 * float(maxi(0, scaffali.size() - 1))) /
		float(maxi(1, scaffali.size())))
	for i in scaffali.size():
		var b := Button.new()
		b.name = "Shelf_%d" % i
		b.text = str(scaffali[i])
		b.custom_minimum_size = Vector2(larghezza_scaffale, 92)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 17 if scaffali.size() > 2 else 20)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_color_override("font_color", Color("f6f0dc"))
		b.add_theme_color_override("font_hover_color", Color("ffffff"))
		b.add_theme_stylebox_override("normal", _stile_pannello(
			Color("4a3023", 0.96), Color("b98b4c", 0.86), 14, 2))
		b.add_theme_stylebox_override("hover", _stile_pannello(
			Color("69452c", 0.98), Color("f4cf69", 0.96), 14, 3))
		b.add_theme_stylebox_override("pressed", _stile_pannello(
			Color("2f775f", 0.98), Color("8ff6d2", 0.96), 14, 3))
		b.add_theme_stylebox_override("focus", _stile_pannello(
			Color("60402b", 0.98), Color("f4cf69"), 14, 3))
		b.pressed.connect(_scegli.bind(i))
		riga.add_child(b)
		_pulsanti.append(b)

	_stato = Label.new()
	_stato.name = "ShelfStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 15)
	_stato.add_theme_color_override("font_color", Color("aee9e4"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "ShelfLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 46)
	lascia.pressed.connect(func():
		if _attivo:
			_attivo = false
			risolto.emit(false, _giuste, _parole.size()))
	colonna.add_child(lascia)

func _stile_pannello(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
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

func _mostra() -> void:
	if _indice >= _parole.size():
		_attivo = false
		risolto.emit(true, _giuste, _parole.size())
		return
	if is_instance_valid(_parola):
		_parola.text = str(Dictionary(_parole[_indice])["testo"])
	if is_instance_valid(_esca):
		_esca.text = str(Dictionary(_parole[_indice]).get("esca", ""))
	if is_instance_valid(_scheda_parola):
		_scheda_parola.modulate = Color.WHITE
		_scheda_parola.add_theme_stylebox_override("panel", _stile_pannello(
			Color("18375a", 0.94), Color("72d8cf", 0.72), 16, 2))
	_aggiorna_stato("")

func _scegli(scaffale: int) -> void:
	if not _attivo or _indice >= _parole.size():
		return
	var voce: Dictionary = _parole[_indice]
	if int(voce["scaffale"]) == scaffale:
		_giuste += 1
		_indice += 1
		_mostra()
		return
	_errori += 1
	if is_instance_valid(_scheda_parola):
		_scheda_parola.add_theme_stylebox_override("panel", _stile_pannello(
			Color("4b2234", 0.96), Color("ff8d9d", 0.92), 16, 2))
		if not _reduced_motion:
			var tween := _scheda_parola.create_tween()
			tween.tween_property(_scheda_parola, "modulate", Color("ffb2bd"), 0.08)
			tween.tween_property(_scheda_parola, "modulate", Color.WHITE, 0.16)
	if _errori > _errori_max:
		_attivo = false
		risolto.emit(false, _giuste, _parole.size())
		return
	# La parola resta: sbagliare non la fa sparire, la rimette davanti. È così
	# che si scopre che la lunghezza non c'entra — riprovandoci sulla stessa.
	_aggiorna_stato(str(_scheda.get("correzione",
		"Non è il suo scaffale. Guarda che cosa FA la parola, non quanto è lunga.")))

func _aggiorna_stato(messaggio: String) -> void:
	if not is_instance_valid(_stato):
		return
	var coda := "Sistemate %d su %d · errori %d/%d" % [
		_giuste, _parole.size(), _errori, _errori_max]
	_stato.text = "%s\n%s" % [messaggio, coda] if messaggio != "" else coda
