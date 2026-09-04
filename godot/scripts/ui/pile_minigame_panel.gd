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
## Dove sta ogni cristallo: indice -> (fila, colonna). Prima era implicito
## nell'indice, e proprio per questo il mucchio era sempre tutto in file piene.
var _posti: Dictionary = {}
var _file := 0

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
	_disponi()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	set_process(true)

## **Quanti pezzi nascono in file piene.** Una funzione sola, perché il conto
## serve anche a chi tara il cronometro.
##
## `character_minigame_audit` calcolava per conto suo «file piene più il resto»,
## cioè `floor(pezzi/gruppo) + pezzi%gruppo`: per quarantadue pezzi faceva sei
## tocchi, mentre il pannello ne costruiva quindici. **Un audit che si immagina
## la disposizione invece di chiederla è verde su un gioco rotto**, ed è
## esattamente quello che è successo per due settimane. Adesso la chiede qui.
## Gli sparsi restano **una manciata**, non un quinto che cresce col mondo: se
## crescessero in proporzione, salendo di livello aumenterebbe soprattutto il
## lavoro che nessuna strategia può abbreviare, e il gioco diventerebbe più lungo
## invece che più esigente.
const SPARSI_MASSIMI := 15

static func in_fila_per(totale: int, gruppo: int) -> int:
	if gruppo <= 0:
		return 0
	var sparsi := mini(totale / 5, SPARSI_MASSIMI)
	var in_fila := (totale - sparsi) / gruppo * gruppo
	return mini(maxi(gruppo, in_fila), totale)

## **I tocchi di chi ha capito.** Uno per ogni fila piena — presa dalla testa —
## più uno per ogni corsa di sparsi. Gli sparsi nascono a due o tre per fila,
## quindi il caso peggiore per chi gioca bene è due per fila.
static func tocchi_ottimali(totale: int, gruppo: int) -> int:
	var in_fila := in_fila_per(totale, gruppo)
	var sparsi := maxi(0, totale - in_fila)
	return int(in_fila / gruppo) + int(ceil(float(sparsi) / 2.0))

## **I tocchi di chi conta uno per uno**, cioè la strategia che Tobia difende.
static func tocchi_uno_per_uno(totale: int, _gruppo: int) -> int:
	return totale

## **I tocchi di chi tocca a caso**, che è il terzo giocatore da battere e per due
## settimane non lo guardava nessuno.
##
## Con la regola «da dove tocchi fino in fondo», svuotare una fila di `n` pezzi
## toccando a caso costa in media l'`n`-esimo numero armonico: il primo tocco
## cade uniformemente e lascia dietro di sé una fila più corta, e la ricorsione
## `T(n) = 1 + (1/n)·Σ T(j)` ha per soluzione esattamente `H(n)`. Per una fila da
## dieci sono 2,93 tocchi contro l'unico che serve a chi la prende dalla testa:
## **è quel rapporto a rendere il cronometro un giudice invece che un contorno.**
static func tocchi_a_caso(totale: int, gruppo: int) -> float:
	var in_fila := in_fila_per(totale, gruppo)
	var sparsi := maxi(0, totale - in_fila)
	var file := int(in_fila / maxi(1, gruppo))
	# Gli sparsi nascono a due o tre per fila: la media dei due casi armonici.
	var file_sparse := float(sparsi) / 2.5
	return float(file) * _armonico(gruppo) + file_sparse * ((_armonico(2) + _armonico(3)) * 0.5)

static func _armonico(n: int) -> float:
	var somma := 0.0
	for i in range(1, maxi(1, n) + 1):
		somma += 1.0 / float(i)
	return somma

## **Il mucchio misto.** (21 agosto 2026, rivisto il 4 settembre)
##
## Fino al 20 agosto i cristalli nascevano tutti in file da dieci, e la
## conseguenza era che **ogni tocco ne prendeva dieci**: la scoperta non si
## poteva mancare perche' non esisteva un'altra mossa.
##
## Adesso una parte del mucchio sta in file piene e il resto e' **sparso**: due
## o tre pezzi per fila. Il bambino sente sulla mano la differenza fra le due
## cose — la fila che sparisce insieme e il granello che va preso da solo — e
## quella differenza e' la lezione.
##
## Il mucchio misto da solo non bastava, ed e' misurato: con la vecchia regola
## del tocco chi giocava a caso faceva **quindici tocchi contro i quindici** di
## chi aveva capito. Quello che ha creato la differenza e' la regola di `_tocca`
## — si prende da dove si tocca fino in fondo alla fila — non la disposizione.
func _disponi() -> void:
	_posti.clear()
	var rng := RandomNumberGenerator.new()
	# Deterministico sul personaggio: lo stesso mucchio, ogni volta che si torna.
	rng.seed = int(hash("mucchio::%s::%d" % [str(_scheda.get("npc", "")), _totale]))
	var gruppo := int(Dictionary(_scheda.get("parametri", {})).get("gruppo", PER_FILA))
	# **La disposizione la decide `in_fila_per`, e la decide per tutti.** Prima il
	# conto stava scritto qui e una seconda copia — diversa — viveva dentro
	# `character_minigame_audit`. Una funzione sola perché il cronometro si tara
	# su questa disposizione, non su un'idea di questa disposizione.
	var in_fila := in_fila_per(_totale, gruppo)
	var fila := 0
	var indice := 0
	while indice < in_fila:
		for colonna in range(gruppo):
			_posti[indice] = Vector2i(fila, colonna)
			indice += 1
		fila += 1
	# Gli sparsi: due o tre per fila, in colonne che non si toccano.
	while indice < _totale:
		var quanti := mini(2 + rng.randi_range(0, 1), _totale - indice)
		var colonne: Array = []
		for _c in range(quanti):
			var colonna := rng.randi_range(0, PER_FILA - 1)
			var giri := 0
			while colonne.has(colonna) and giri < PER_FILA:
				colonna = (colonna + 3) % PER_FILA
				giri += 1
			colonne.append(colonna)
		for colonna in colonne:
			_posti[indice] = Vector2i(fila, int(colonna))
			indice += 1
		fila += 1
	_file = fila

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
	_griglia.custom_minimum_size = Vector2(LARGHEZZA_GRIGLIA, float(_file) * PASSO_FILA)
	colonna.add_child(_griglia)
	for fila in range(_file):
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
	var posto: Vector2i = _posti.get(indice, Vector2i(indice / PER_FILA, indice % PER_FILA))
	var colonna := int(posto.y)
	pezzo.position = Vector2(
		float(colonna) * LATO + (SPAZIO_CINQUINE if colonna >= 5 else 0.0),
		float(posto.x) * PASSO_FILA + 2.0)
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


## **Il gesto che cambia tutto: si prende da dove si tocca fino in fondo.**
## (4 settembre 2026)
##
## Toccare un cristallo porta via **lui e tutti quelli che lo seguono nella sua
## fila**. Toccare il primo di una fila piena la prende tutta in un colpo;
## toccarne uno a metà ne prende solo la coda, e quello che resta a sinistra va
## ripreso pezzo per pezzo.
##
## Non c'è nessun pulsante «raggruppa» e nessuna spiegazione: **il gesto è lo
## stesso, cambia solo dove lo si fa** — che è la regola dichiarata di questo
## minigioco fin dal primo giorno. Quello che cambia dal 4 settembre è che adesso
## *dove* lo si fa conta davvero.
##
## **Perché è stato necessario cambiarla.** Fino a ieri un tocco su una fila
## ancora intera prendeva tutti e dieci **ovunque cadesse**. Conseguenza: non
## esisteva una mossa sbagliata, quindi chi toccava a caso faceva esattamente i
## tocchi di chi aveva capito — misurati, quindici contro quindici — e
## `minigiochi_cieco_probe` vinceva cento partite su cento. Nessuna taratura del
## cronometro poteva separarli, perché non c'era niente da separare: la scoperta
## non era una scoperta, era il comportamento predefinito.
##
## Adesso la differenza fra sapere e non sapere è il numero di tocchi, ed è per
## quel numero che il cronometro è tarato.
func _tocca(indice: int) -> void:
	if not _attivo or not _restanti.has(indice):
		return
	var posto_tocco: Vector2i = _posti.get(indice, Vector2i(indice / PER_FILA, 0))
	var fila := int(posto_tocco.x)
	var da_colonna := int(posto_tocco.y)
	var presi: Array = []
	for altro in _restanti:
		var posto: Vector2i = _posti.get(int(altro), Vector2i(int(altro) / PER_FILA, 0))
		if int(posto.x) == fila and int(posto.y) >= da_colonna:
			presi.append(int(altro))
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
