class_name PileMinigamePanel
extends Control

## **Il mucchio che non finisce**: il minigioco di Tobia. (9 agosto 2026)
##
## Un mucchio di cristalli e un tempo che non basta a contarli uno per uno. Si
## tocca un cristallo per metterlo da parte — e finché si fa così non si arriva
## in fondo. Ma toccando un cristallo mentre altri nove gli stanno vicino, si
## raccoglie **tutta la decina in un colpo**: e allora il conto torna.
##
## **La scoperta non è spiegata da nessuno.** La consegna dice solo «quanti
## cristalli ci sono?». Il gioco mostra i pezzi già disposti in file da dieci —
## la forma suggerisce il gesto senza nominarlo — e la prima volta che una decina
## sparisce insieme il bambino capisce, e non lo dimentica più. Se la consegna
## dicesse «raggruppa per dieci», la scoperta diventerebbe un'istruzione da
## eseguire: la stessa azione, con dentro zero.
##
## **Perché è un gioco di velocità e non di calcolo.** Il numero finale è facile
## — sono decine e un resto. Difficile è **arrivarci in tempo**, e si arriva in
## tempo solo cambiando strategia. Il cronometro qui è legittimo, mentre sopra
## una domanda scritta non lo sarebbe: non misura quanto in fretta leggi, misura
## se hai trovato la scorciatoia.
##
## **Perdere non punisce**: il deposito chiude, Tobia ricomincia da capo, e si
## può riprovare subito. È la stessa regola del varco e delle minimissioni —
## niente su questa mappa può fermare la progressione.

signal risolto(vinto: bool, raccolti: int, totale: int)

const CRISTALLO := preload("res://assets/minigames/tobia-crystal-v1.png")
const LATO := 40.0
const PASSO_FILA := 46.0
const SPAZIO_CINQUINE := 8.0
const PER_FILA := 10
const LARGHEZZA_GRIGLIA := PER_FILA * LATO + SPAZIO_CINQUINE

var _scheda: Dictionary = {}
var _totale := 0
var _raccolti := 0
var _restanti: Array = []          # indici ancora sul tavolo
var _secondi := 0.0
var _attivo := false
var _reduced_motion := false

var _griglia: Control
var _cronometro: Label
var _conta: Label
var _pezzi: Dictionary = {}        # indice -> Control

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_totale = int(parametri.get("pezzi", 30))
	_secondi = float(parametri.get("secondi", 15.0))
	if _reduced_motion:
		# Più tempo, stesso gioco: chi ha bisogno di meno fretta non deve per
		# questo perdere la scoperta, che è la parte che conta.
		_secondi *= 1.5
	_raccolti = 0
	_restanti = []
	for i in range(_totale):
		_restanti.append(i)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	set_process(true)

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "PileVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.02, 0.06, 0.05, 0.93)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	# Due aloni larghi fanno appartenere il pannello alla Radura senza aggiungere
	# un fondale illustrato che competerebbe con i pezzi da contare.
	for alone_data in [
		{"pos": Vector2(0.14, 0.18), "color": Color(0.16, 0.72, 0.48, 0.10)},
		{"pos": Vector2(0.86, 0.78), "color": Color(0.96, 0.72, 0.24, 0.09)},
	]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = Vector2(
			(float(alone_data["pos"].x) - 0.5) * 900.0,
			(float(alone_data["pos"].y) - 0.5) * 600.0)
		alone.size = Vector2(360, 360)
		alone.add_theme_stylebox_override("panel", _stile_pannello(
			Color(alone_data["color"]), Color(0, 0, 0, 0), 180, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "PileCard"
	carta.add_theme_stylebox_override("panel", _stile_pannello(
		Color("092b28", 0.98), Color("e6bd55", 0.82), 22, 2))
	centro.add_child(carta)
	MinigamePanelLayout.adapt_vertical(self, carta)
	var margine := MarginContainer.new()
	margine.add_theme_constant_override("margin_left", 28)
	margine.add_theme_constant_override("margin_right", 28)
	margine.add_theme_constant_override("margin_top", 22)
	margine.add_theme_constant_override("margin_bottom", 22)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "PileColumn"
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "PileConvictionGlyph"
	testata.add_child(glifo)

	var titolo := Label.new()
	titolo.name = "PileTitle"
	titolo.text = str(_scheda.get("titolo", "Il mucchio"))
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "PileBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.custom_minimum_size = Vector2(LARGHEZZA_GRIGLIA + 24.0, 0)
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("e7fffb"))
	colonna.add_child(consegna)

	_cronometro = Label.new()
	_cronometro.name = "PileClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 20)
	_cronometro.add_theme_color_override("font_color", Color("8ff6d2"))
	colonna.add_child(_cronometro)

	_griglia = Control.new()
	_griglia.name = "PileGrid"
	var file := ceili(float(_totale) / float(PER_FILA))
	_griglia.custom_minimum_size = Vector2(LARGHEZZA_GRIGLIA, float(file) * PASSO_FILA)
	colonna.add_child(_griglia)
	for fila in range(file):
		_griglia.add_child(_crea_vassoio_fila(fila))
	for i in range(_totale):
		_griglia.add_child(_crea_pezzo(i))

	_conta = Label.new()
	_conta.name = "PileCount"
	_conta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_conta.add_theme_font_size_override("font_size", 22)
	_conta.add_theme_color_override("font_color", Color("f4cf69"))
	colonna.add_child(_conta)
	_aggiorna_stato()

	var lascia := Button.new()
	lascia.name = "PileLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 46)
	lascia.pressed.connect(func():
		if _attivo:
			_attivo = false
			risolto.emit(false, _raccolti, _totale))
	colonna.add_child(lascia)

## Un cristallo. Le file da dieci non sono una decorazione: sono l'**indizio**
## che rende scopribile la strategia senza dirla.
func _crea_pezzo(indice: int) -> Control:
	var pezzo := Button.new()
	pezzo.name = "Crystal_%02d" % indice
	pezzo.custom_minimum_size = Vector2(LATO, LATO)
	var colonna := indice % PER_FILA
	pezzo.position = Vector2(
		float(colonna) * LATO + (SPAZIO_CINQUINE if colonna >= 5 else 0.0),
		float(indice / PER_FILA) * PASSO_FILA + 2.0)
	pezzo.icon = CRISTALLO
	pezzo.expand_icon = true
	#  su Button e' una COSTANTE DI TEMA, non una proprieta':
	# assegnarla direttamente fallisce a runtime e fa cadere l'intero script.
	pezzo.add_theme_constant_override("icon_max_width", 34)
	pezzo.tooltip_text = "Cristallo %d" % (indice + 1)
	pezzo.focus_mode = Control.FOCUS_ALL
	pezzo.add_theme_stylebox_override("normal", _stile_pulsante_cristallo(Color(0, 0, 0, 0)))
	pezzo.add_theme_stylebox_override("hover", _stile_pulsante_cristallo(Color("72f0b4", 0.16)))
	pezzo.add_theme_stylebox_override("pressed", _stile_pulsante_cristallo(Color("f4cf69", 0.24)))
	pezzo.add_theme_stylebox_override("focus", _stile_pulsante_cristallo(Color("f4cf69", 0.18), true))
	pezzo.pressed.connect(_tocca.bind(indice))
	_pezzi[indice] = pezzo
	return pezzo

## Il vassoio e la pausa fra i due gruppi da cinque fanno leggere ogni fila
## come una decina prima ancora che il bambino abbia contato i singoli pezzi.
## Non c'e' un numero stampato: l'indizio e' nella disposizione, quindi resta
## una scoperta e non diventa un'istruzione.
func _crea_vassoio_fila(fila: int) -> Panel:
	var vassoio := Panel.new()
	vassoio.name = "TenTray_%02d" % fila
	vassoio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vassoio.position = Vector2(0, float(fila) * PASSO_FILA)
	vassoio.size = Vector2(LARGHEZZA_GRIGLIA, PASSO_FILA - 2.0)
	var quanti := mini(PER_FILA, _totale - fila * PER_FILA)
	var bordo := Color("e6bd55", 0.62) if quanti == PER_FILA else Color("72f0b4", 0.30)
	vassoio.add_theme_stylebox_override("panel", _stile_pannello(
		Color("0f463b", 0.48), bordo, 12, 1))
	return vassoio

func _stile_pulsante_cristallo(sfondo: Color, evidenza: bool = false) -> StyleBoxFlat:
	var stile := _stile_pannello(sfondo, Color("f4cf69", 0.92) if evidenza else Color(0, 0, 0, 0), 9, 2 if evidenza else 0)
	stile.content_margin_left = 3
	stile.content_margin_right = 3
	stile.content_margin_top = 3
	stile.content_margin_bottom = 3
	return stile

func _stile_pannello(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile


## **Il gesto che cambia tutto.**
##
## Toccare un cristallo isolato ne toglie uno. Toccarne uno che ha ancora nove
## compagni nella sua fila li toglie **tutti e dieci**: la fila è un gruppo, e il
## gruppo si prende in un colpo solo.
##
## Non c'è nessun pulsante «raggruppa» e nessuna spiegazione: il gesto è lo
## stesso, cambia solo dove lo si fa. È questa la differenza fra scoprire una
## strategia e riceverne l'istruzione.
func _tocca(indice: int) -> void:
	if not _attivo or not _restanti.has(indice):
		return
	var fila := indice / PER_FILA
	var compagni: Array = []
	for altro in _restanti:
		if int(altro) / PER_FILA == fila:
			compagni.append(int(altro))
	var gruppo := int(Dictionary(_scheda.get("parametri", {})).get("gruppo", PER_FILA))
	var presi: Array = compagni if compagni.size() >= gruppo else [indice]
	for preso in presi:
		_restanti.erase(preso)
		_raccolti += 1
		var nodo := _pezzi.get(preso, null) as Control
		if is_instance_valid(nodo):
			if _reduced_motion:
				nodo.queue_free()
			else:
				nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
				nodo.pivot_offset = nodo.size * 0.5
				var tween := nodo.create_tween().set_parallel(true)
				tween.tween_property(nodo, "scale", Vector2(1.22, 1.22), 0.12)
				tween.tween_property(nodo, "modulate:a", 0.0, 0.12)
				tween.chain().tween_callback(nodo.queue_free)
	_aggiorna_stato()
	if _restanti.is_empty():
		_attivo = false
		risolto.emit(true, _raccolti, _totale)

func _aggiorna_stato() -> void:
	if is_instance_valid(_conta):
		_conta.text = "Contati %d · ne restano %d" % [_raccolti, _restanti.size()]
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi" % maxf(0.0, _secondi)

func _process(delta: float) -> void:
	if not _attivo:
		return
	_secondi -= delta
	if _secondi <= 0.0:
		_secondi = 0.0
		_attivo = false
		_aggiorna_stato()
		risolto.emit(false, _raccolti, _totale)
		return
	_aggiorna_stato()
