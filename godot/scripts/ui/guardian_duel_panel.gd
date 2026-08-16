class_name GuardianDuelPanel
extends Control

## **IL DUELLO** — il combattimento contro un guardiano. (16 agosto 2026)
##
## Il guardiano illustrato sta in alto e porta i suoi **sigilli**. Sotto di lui
## una barra che si riempie: è la sua **carica**, cioè il tempo raccontato dalla
## parte di chi ti sta davanti. Al centro la **corda di risonanza**: una scala su
## cui una tacca segna il sigillo e un ago segna l'**impulso** di Eli. In basso le
## **rune**: ogni tocco è un colpo, e cambia l'impulso. Quando l'ago cade
## esattamente sulla tacca, il sigillo si spezza.
##
## Le regole e i numeri vengono da [[GuardianDuel]]; qui vive solo la messa in
## scena — ed è la stessa divisione del chiavistello, per la stessa ragione: la
## difficoltà di ventiquattro mondi si collauda meglio senza aprire una finestra.
##
## ## Le scelte di resa, e perché ognuna
##
## - **La corda di risonanza è il pezzo che insegna.** Un numero da raggiungere,
##   scritto e basta, dice solo *quanto*; una scala dice **quanto manca**, e a
##   colpo d'occhio. Un bambino che vede l'ago fermo a un terzo della corda sa
##   che gli serve un ×3 prima di averlo calcolato — e quello, l'ordine di
##   grandezza, è la prima cosa che fa un calcolatore veloce. La zona **oltre** il
##   sigillo è disegnata e barrata: superare si vede prima ancora di leggere.
## - **La catena resta scritta** (`4 → ×6 → 24 → +9 → 33`). È il quaderno del
##   duello: il bambino rilegge la propria strada mentre la percorre, ed è l'unico
##   posto del gioco dove il ragionamento resta visibile dopo essere stato fatto.
## - **Il guardiano è l'illustrazione vera** del mondo
##   ([[GuardianVisualCatalog]]), la stessa che si vede sulla mappa. Combattere
##   contro un rettangolo colorato dopo aver visto un drago sarebbe la rottura di
##   promessa più economica e più stupida di tutto il gioco.
## - **Niente rosso quando si incassa.** Il guardiano para in ambra e avanza di
##   un passo; l'ago torna indietro. Il rosso su un bambino che sta contando in
##   fretta è un rimprovero, e qui non c'è niente da rimproverare: si è sbagliata
##   una strada, non una risposta.
## - **Il suono sale con la vicinanza.** Ogni colpo suona `enigmaProgress` con
##   l'intonazione legata a quanto ci si è avvicinati al sigillo: l'orecchio
##   impara la distanza prima degli occhi. Il colpo che manca **non** suona come
##   una risposta sbagliata — equipararli insegnerebbe che il duello sta
##   valutando quello che il bambino sa, e non è così.
##
## ## Accessibilità
##
## Con `reduced_motion` niente tremori, niente ondeggio e la carica è più lenta
## (`GuardianDuel.TEMPO_RIDOTTO`, applicato nelle regole); con `high_contrast` i
## bordi diventano pieni e gli aloni spariscono. Si gioca col dito, col mouse e
## con i tasti 1-6 — su desktop cercare il mouse mentre si conta è un secondo
## lavoro, e questo minigioco misura il primo.
##
## **Si può sempre andarsene**, e andarsene non costa niente: il guardiano resta
## dov'è. L'unica cosa peggiore di un combattimento difficile è un combattimento
## difficile da cui non si esce.

signal risolto(vinto: bool, netto: bool)

const GUARDIAN_VISUALS := preload("res://scripts/game/guardian_visual_catalog.gd")

const LARGHEZZA := 660.0
const ALTEZZA_ARENA := 332.0
const ALTEZZA_RUNE := 116.0

## **Le quote dell'arena**, dall'alto in basso. Stanno tutte qui perché l'arena è
## un disegno solo e le sue fasce non devono potersi sovrapporre per distrazione:
## alla prima stesura il numero dell'impulso finiva addosso all'ago e la carica
## del guardiano gli passava attraverso, e non c'era nessun posto in cui quel
## difetto fosse visibile se non guardando la sonda.
const Y_SIGILLI := 14.0
const Y_ARTE := 26.0
const LATO_ARTE := 160.0
const Y_TARGA := 150.0
const ALTEZZA_TARGA := 56.0
const Y_CARICA := 214.0
const Y_IMPULSO := 228.0
const Y_CORDA := 282.0
const ALTEZZA_CORDA := 14.0
const Y_CATENA := 306.0
const RUNA_LARGA := 96.0
const RUNA_ALTA := 84.0
const RUNA_GAP := 12.0
## Quanto della corda sta oltre il sigillo. Un quarto: abbastanza per vedere di
## quanto si è sfondato, non tanto da schiacciare la parte che conta.
const CORDA_OLTRE := 1.38

const DURATA_COLPO := 0.42
const DURATA_ROTTURA := 0.78
const DURATA_PARATA := 0.62

const ORO := Color("f4cf69")
const FREDDO := Color("6be7d6")
const GHIACCIO := Color("7ad7ff")
const AMBRA := Color("ffb066")
const TESTO := Color("eaf7ff")

var regole: Dictionary = {}
var nome_guardiano := "Guardiano"
var reduced_motion := false
var high_contrast := false

var _rng := RandomNumberGenerator.new()
var _scambio: Dictionary = {}
var _rune: Array = []
var _usate: Dictionary = {}
var _impulso := 0
var _catena: Array = []
var _sigilli_rotti := 0
var _tenuta := 2
var _colpi_dati := 0
var _netto := true
var _attivo := false
## Il fermo-immagine fra uno scambio e l'altro: il sigillo che si spezza e il
## colpo che si incassa hanno diritto al loro istante. Senza, i numeri nuovi
## comparirebbero nello stesso fotogramma in cui i vecchi hanno fatto il loro
## lavoro, e il combattimento non avrebbe respiro.
var _in_pausa := false

var _tempo := 0.0
var _tempo_massimo := 1.0
var _colpo := 0.0
var _colpo_indice := -1
var _rottura := 0.0
var _parata := 0.0
var _tremore := 0.0
var _onda := 0.0

var _arte: Texture2D
## L'attesa fra uno scambio e l'altro, tenuta per nome. Senza il riferimento
## un'attesa vecchia sopravvive alla sfida che l'ha creata e riapre uno scambio
## che nessuno ha chiesto: succede a chi rigioca lo stesso pannello, ed è il
## genere di difetto che si vede solo nella sonda visuale.
var _attesa: Tween
var _arena: Control
var _rune_zona: Control
var _titolo: Label
var _sigillo_label: Label
var _impulso_label: Label
var _catena_label: Label
var _stato: Label
var _rune_label: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	set_process(true)

## Avvia un duello. `seme` cambia a ogni sfida: rifare a memoria un duello perso
## non deve essere possibile — la seconda volta si calcolerebbe di meno, che è
## esattamente la cosa che questo minigioco esiste per non permettere.
func avvia(regole_duello: Dictionary, nome: String, seme: int,
		movimento_ridotto: bool, contrasto: bool) -> void:
	regole = regole_duello.duplicate(true)
	nome_guardiano = nome
	reduced_motion = movimento_ridotto
	high_contrast = contrasto
	_rng.seed = seme
	if _attesa != null and _attesa.is_valid():
		_attesa.kill()
	_sigilli_rotti = 0
	_tenuta = int(regole.get("tenuta", 2))
	_netto = true
	_attivo = true
	_in_pausa = false
	_colpo = 0.0
	_colpo_indice = -1
	_rottura = 0.0
	_parata = 0.0
	_tremore = 0.0
	visible = true
	_arte = GUARDIAN_VISUALS.texture_for(int(regole.get("mondo", 1)))
	_titolo.text = "%s · %s" % [nome_guardiano.to_upper(), str(regole.get("nome", "sigillo"))]
	_nuovo_scambio()
	_entrata()

func attivo() -> bool:
	return _attivo

## La strada più corta per il sigillo di adesso, come indici di rune. Pubblica
## perché la usano gli audit di scena: un combattimento che si può giocare solo
## con le dita non si può collaudare, e questo decide se un forziere si apre.
func sequenza_vincente() -> Array:
	if _scambio.is_empty():
		return []
	var disponibili: Array = []
	for indice in _rune.size():
		if not _usate.has(indice):
			disponibili.append(indice)
	var mappa: Array = []
	var mano: Array = []
	for indice in disponibili:
		mappa.append(indice)
		mano.append(_rune[indice])
	var colpi_rimasti := int(regole.get("colpi", 3)) - _colpi_dati
	var percorso := GuardianDuel.percorso_minimo(
		_impulso, int(_scambio.get("bersaglio", 0)), mano, maxi(colpi_rimasti, 1))
	var fuori: Array = []
	for passo in percorso:
		fuori.append(int(mappa[int(passo)]))
	return fuori

func _entrata() -> void:
	if reduced_motion:
		return
	modulate.a = 0.0
	var entrata := create_tween()
	entrata.tween_property(self, "modulate:a", 1.0, 0.18)

# --- Costruzione --------------------------------------------------------------

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "DuelVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.015, 0.04, 0.065, 0.92)
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var colonna := VBoxContainer.new()
	colonna.name = "DuelColumn"
	colonna.custom_minimum_size = Vector2(LARGHEZZA, 0)
	colonna.add_theme_constant_override("separation", 6)
	centro.add_child(colonna)

	_titolo = Label.new()
	_titolo.name = "DuelTitle"
	_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titolo.add_theme_font_size_override("font_size", 20)
	_titolo.add_theme_color_override("font_color", ORO)
	colonna.add_child(_titolo)

	_arena = Control.new()
	_arena.name = "DuelArena"
	_arena.custom_minimum_size = Vector2(LARGHEZZA, ALTEZZA_ARENA)
	_arena.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.draw.connect(_disegna_arena)
	colonna.add_child(_arena)

	_sigillo_label = _etichetta("DuelSealValue", 40, ORO)
	_arena.add_child(_sigillo_label)
	_impulso_label = _etichetta("DuelImpulseValue", 30, GHIACCIO)
	_arena.add_child(_impulso_label)
	_catena_label = _etichetta("DuelChain", 16, Color("9fd8d2"))
	_arena.add_child(_catena_label)

	_rune_zona = Control.new()
	_rune_zona.name = "DuelRunes"
	_rune_zona.custom_minimum_size = Vector2(LARGHEZZA, ALTEZZA_RUNE)
	_rune_zona.draw.connect(_disegna_rune)
	_rune_zona.gui_input.connect(_tocco)
	colonna.add_child(_rune_zona)

	_stato = Label.new()
	_stato.name = "DuelStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 14)
	_stato.add_theme_color_override("font_color", Color("9fd8d2"))
	colonna.add_child(_stato)

	var fuga := Button.new()
	fuga.name = "DuelLeaveButton"
	fuga.text = "LASCIA PERDERE"
	fuga.custom_minimum_size = Vector2(0, 46)
	fuga.add_theme_font_size_override("font_size", 14)
	# Andarsene non costa niente e non è una sconfitta: il guardiano resta dov'è.
	fuga.pressed.connect(_rinuncia)
	colonna.add_child(fuga)

func _etichetta(nome_nodo: String, dimensione: int, colore: Color) -> Label:
	var etichetta := Label.new()
	etichetta.name = nome_nodo
	etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etichetta.add_theme_font_size_override("font_size", dimensione)
	etichetta.add_theme_color_override("font_color", colore)
	etichetta.add_theme_constant_override("outline_size", 5)
	etichetta.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.05, 0.9))
	etichetta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etichetta

# --- Uno scambio --------------------------------------------------------------

func _nuovo_scambio() -> void:
	_scambio = GuardianDuel.genera_scambio(_rng, regole)
	_rune = Array(_scambio.get("rune", []))
	_usate.clear()
	_impulso = int(_scambio.get("partenza", 1))
	_catena = [str(_impulso)]
	_colpi_dati = 0
	_tempo_massimo = GuardianDuel.secondi_del_sigillo(regole, _sigilli_rotti)
	_tempo = _tempo_massimo
	_sigillo_label.text = str(int(_scambio.get("bersaglio", 0)))
	_costruisci_rune()
	_aggiorna_testi()

func _costruisci_rune() -> void:
	for etichetta in _rune_label:
		if is_instance_valid(etichetta):
			etichetta.queue_free()
	_rune_label.clear()
	for indice in _rune.size():
		var etichetta := _etichetta("DuelRune%d" % indice, 26, TESTO)
		etichetta.text = str(Dictionary(_rune[indice]).get("testo", ""))
		_rune_zona.add_child(etichetta)
		_rune_label.append(etichetta)

## **Un colpo.** È la sola porta: dito, mouse, tasti e audit passano di qui.
func colpisci(indice: int) -> void:
	if not _attivo or _in_pausa or indice < 0 or indice >= _rune.size() or _usate.has(indice):
		return
	var runa: Dictionary = _rune[indice]
	var esito := GuardianDuel.applica(_impulso, runa)
	if esito < 0:
		# La runa spenta non è un errore: non entra, e basta. Non costa un colpo,
		# non costa tenuta, non fa rumore di sbaglio. Costa il tempo che ci si è
		# messi a provarla — che è già la lezione sulla divisibilità.
		_tremore = 0.5
		_suona("hintShown", 0.62)
		return
	var bersaglio := int(_scambio.get("bersaglio", 0))
	var prima := absi(bersaglio - _impulso)
	_usate[indice] = true
	_impulso = esito
	_colpi_dati += 1
	_catena.append(str(runa.get("testo", "")))
	_catena.append(str(_impulso))
	_colpo = DURATA_COLPO
	_colpo_indice = indice
	_aggiorna_testi()

	if _impulso == bersaglio:
		_spezza_sigillo()
		return
	# L'intonazione sale con la vicinanza: l'orecchio impara la distanza prima
	# degli occhi, ed è la stessa cosa che fa la corda con lo sguardo.
	var dopo := absi(bersaglio - _impulso)
	var avvicinamento := clampf(1.0 - float(dopo) / float(maxi(prima, 1)), 0.0, 1.0)
	_suona("enigmaProgress", 0.88 + avvicinamento * 0.5)
	if _colpi_dati >= int(regole.get("colpi", 3)):
		_incassa()
		return
	# **La strada chiusa.** Se con le rune rimaste il sigillo non si fa più, il
	# guardiano chiude lo scambio subito: far scorrere la carica su una partita
	# già persa non insegna niente e sembra soltanto una punizione lunga.
	if sequenza_vincente().is_empty():
		_incassa()

func _spezza_sigillo() -> void:
	_sigilli_rotti += 1
	if _colpi_dati > int(_scambio.get("minimi", 99)):
		_netto = false
	_rottura = DURATA_ROTTURA
	_in_pausa = true
	_suona("enigmaCompleted", 1.0 + float(_sigilli_rotti) * 0.06)
	_aggiorna_testi()
	if _sigilli_rotti >= int(regole.get("sigilli", 2)):
		_attivo = false
		# Mezzo secondo per vedere l'ultimo sigillo andare in pezzi: è l'unico
		# momento in cui questo pannello si prende del tempo, ed è quello che
		# rende la vittoria una vittoria invece di un passaggio.
		_dopo(0.55, func(): risolto.emit(true, _netto))
		return
	_dopo(DURATA_ROTTURA, _riprendi)

## **Il guardiano colpisce.** Succede quando la carica è piena, quando i colpi
## sono finiti senza risonanza, o quando la strada si è chiusa. Costa un punto di
## tenuta e riapre lo scambio con numeri nuovi: non si resta mai bloccati su un
## sigillo che non si è saputo fare.
func _incassa() -> void:
	if not _attivo or _in_pausa:
		return
	_tenuta -= 1
	_netto = false
	_parata = DURATA_PARATA
	_tremore = 1.0
	_in_pausa = true
	# NON è il suono della risposta sbagliata: incassare un colpo in un duello e
	# sbagliare una domanda sono due cose diverse, e il gioco non deve mai
	# lasciar credere che il guardiano stia valutando quello che il bambino sa.
	_suona("sessionDefeated", 1.05)
	_aggiorna_testi()
	if _tenuta <= 0:
		_attivo = false
		_dopo(0.45, func(): risolto.emit(false, false))
		return
	_dopo(DURATA_PARATA, _riprendi)

func _riprendi() -> void:
	if not _attivo:
		return
	_in_pausa = false
	_nuovo_scambio()

## Un'attesa che con `reduced_motion` resta breve ma non sparisce: anche chi ha
## bisogno di meno movimento ha diritto a vedere che cosa è appena successo.
func _dopo(secondi: float, cosa: Callable) -> void:
	if _attesa != null and _attesa.is_valid():
		_attesa.kill()
	_attesa = create_tween()
	_attesa.tween_interval(0.22 if reduced_motion else secondi)
	_attesa.tween_callback(cosa)

func _rinuncia() -> void:
	if not _attivo:
		return
	_attivo = false
	visible = false
	risolto.emit(false, false)

# --- Ciclo --------------------------------------------------------------------

func _process(delta: float) -> void:
	if not is_instance_valid(_arena):
		return
	_onda += delta
	_colpo = maxf(0.0, _colpo - delta)
	_rottura = maxf(0.0, _rottura - delta)
	_parata = maxf(0.0, _parata - delta)
	_tremore = maxf(0.0, _tremore - delta * 2.2)
	if _attivo and not _in_pausa:
		_tempo -= delta
		if _tempo <= 0.0:
			_tempo = 0.0
			_incassa()
	_posiziona()
	_arena.queue_redraw()
	_rune_zona.queue_redraw()

func _aggiorna_testi() -> void:
	if not is_instance_valid(_stato):
		return
	_impulso_label.text = str(_impulso)
	_catena_label.text = _riga_catena()
	# La tenuta di Eli si scrive con un segno diverso da quello dei sigilli del
	# guardiano: due tondi non si confondono con due rombi d'oro, e in un
	# combattimento sapere di chi è la vita che si sta guardando è tutto.
	_stato.text = "sigilli %d/%d · colpi %d/%d · tenuta %s" % [
		_sigilli_rotti, int(regole.get("sigilli", 2)),
		_colpi_dati, int(regole.get("colpi", 3)),
		"●".repeat(maxi(_tenuta, 0))]

## La catena come la si rilegge: `4 → ×6 → 24 → +9 → 33`. Se diventa lunga si
## taglia in testa — quello che serve è la parte vicina a dove si è adesso.
##
## Prima del primo colpo la catena sarebbe un numero solo, cioè la ripetizione
## del numero già scritto sull'ago. Quel posto vale di più occupato dall'unica
## istruzione che questo minigioco ha bisogno di dare, e che sparisce da sé
## appena serve meno.
func _riga_catena() -> String:
	if _catena.size() <= 1:
		return "porta l'impulso esatto sul sigillo, un colpo alla volta"
	var pezzi: Array = _catena.duplicate()
	while pezzi.size() > 9:
		pezzi.remove_at(0)
	return " → ".join(PackedStringArray(pezzi))

func _posiziona() -> void:
	var centro_x := _arena.size.x * 0.5
	_sigillo_label.size = Vector2(180, ALTEZZA_TARGA - 4.0)
	_sigillo_label.position = Vector2(centro_x - 90, Y_TARGA + 2.0)
	_catena_label.size = Vector2(_arena.size.x - 40, 24)
	_catena_label.position = Vector2(20, Y_CATENA)
	# L'ago porta con sé il proprio numero: il valore dell'impulso sta sopra il
	# punto in cui l'impulso è arrivato, e non in un angolo da cui bisognerebbe
	# tornare indietro con gli occhi a ogni colpo.
	var ago := _punto_corda(_impulso)
	_impulso_label.size = Vector2(120, 34)
	_impulso_label.position = Vector2(
		clampf(ago - 60.0, 12.0, maxf(_arena.size.x - 132.0, 12.0)), Y_IMPULSO)

func _tocco(event: InputEvent) -> void:
	if not _attivo:
		return
	var premuto: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not premuto:
		return
	var punto: Vector2 = event.position
	for indice in _rune.size():
		if _rettangolo_runa(indice).grow(4.0).has_point(punto):
			colpisci(indice)
			return

func _unhandled_input(event: InputEvent) -> void:
	if not _attivo or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var codice := int(event.keycode)
		if codice >= KEY_1 and codice <= KEY_6:
			colpisci(codice - KEY_1)
			get_viewport().set_input_as_handled()

func _suona(evento: String, tono: float) -> void:
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", evento, tono)

# --- La corda di risonanza ----------------------------------------------------

func _corda_rect() -> Rect2:
	return Rect2(50.0, Y_CORDA, maxf(_arena.size.x - 100.0, 1.0), ALTEZZA_CORDA)

## Dove cade un valore sulla corda. La scala arriva a un terzo abbondante oltre
## il sigillo: chi sfonda vede **di quanto**, e chi sfonda molto trova l'ago
## appoggiato al fondo con la punta piegata — informazione, non punizione.
func _punto_corda(valore: int) -> float:
	var rect := _corda_rect()
	var bersaglio := maxi(int(_scambio.get("bersaglio", 1)), 1)
	var scala := float(bersaglio) * CORDA_OLTRE
	return rect.position.x + rect.size.x * clampf(float(valore) / scala, 0.0, 1.0)

# --- Disegno ------------------------------------------------------------------

func _disegna_arena() -> void:
	var scossa := Vector2.ZERO
	if _tremore > 0.0 and not reduced_motion:
		scossa = Vector2(sin(_tremore * 52.0) * 6.0 * _tremore, 0.0)
	var centro_x := _arena.size.x * 0.5 + scossa.x
	var bersaglio := int(_scambio.get("bersaglio", 0))

	_disegna_sigilli(centro_x)
	_disegna_guardiano(centro_x)
	_disegna_carica(centro_x)
	_disegna_corda(scossa, bersaglio)
	_disegna_colpo(scossa)
	# Il lampo del colpo incassato passa sopra tutto: è ambra e non rosso, perché
	# è un colpo preso in un duello e non una risposta sbagliata.
	if _parata > 0.0:
		_arena.draw_rect(Rect2(Vector2.ZERO, _arena.size),
			Color(AMBRA, 0.16 * (_parata / DURATA_PARATA)))

func _disegna_sigilli(centro_x: float) -> void:
	var quanti := int(regole.get("sigilli", 2))
	var passo := 30.0
	var partenza := centro_x - passo * float(quanti - 1) * 0.5
	for indice in range(quanti):
		var punto := Vector2(partenza + passo * float(indice), Y_SIGILLI)
		var rotto := indice < _sigilli_rotti
		var rombo := PackedVector2Array([
			punto + Vector2(0, -11), punto + Vector2(9, 0),
			punto + Vector2(0, 11), punto + Vector2(-9, 0),
		])
		if rotto:
			# Un sigillo spezzato non sparisce: resta il suo guscio vuoto, così
			# si vede da quanti se ne è già venuti fuori.
			var contorno := rombo.duplicate()
			contorno.append(contorno[0])
			_arena.draw_polyline(contorno, Color(ORO, 0.34), 1.6, true)
		else:
			_arena.draw_colored_polygon(rombo, Color(ORO, 0.92) if not high_contrast else Color.WHITE)
			if not high_contrast:
				_arena.draw_circle(punto, 15.0, Color(ORO, 0.10))

func _disegna_guardiano(centro_x: float) -> void:
	var respiro := 0.0
	if not reduced_motion:
		respiro = sin(_onda * 1.6) * 4.0
	# Quando incassa avanza di un passo; quando perde un sigillo arretra. Il
	# combattimento si legge dalla posizione del guardiano prima che dai numeri.
	var spinta := 0.0
	if _parata > 0.0:
		spinta = 14.0 * (_parata / DURATA_PARATA)
	if _rottura > 0.0:
		spinta = -18.0 * (_rottura / DURATA_ROTTURA)
	# Il riquadro è quadrato: l'illustrazione del guardiano è quadrata, e
	# schiacciarla per far posto ai numeri sarebbe la prima cosa che si nota.
	var rect := Rect2(centro_x - LATO_ARTE * 0.5, Y_ARTE + respiro + spinta,
		LATO_ARTE, LATO_ARTE)

	if not high_contrast:
		_arena.draw_circle(rect.get_center() + Vector2(0, 6), 92.0, Color(FREDDO, 0.05))
		_arena.draw_circle(rect.get_center() + Vector2(0, 6), 62.0, Color(FREDDO, 0.05))
	if _arte != null:
		var tinta := Color.WHITE
		if _rottura > 0.0:
			var lampo := _rottura / DURATA_ROTTURA
			tinta = Color(1.0 + lampo, 1.0 + lampo, 1.0 + lampo, 1.0)
		elif _parata > 0.0:
			tinta = Color.WHITE.lerp(AMBRA, 0.55 * (_parata / DURATA_PARATA))
		_arena.draw_texture_rect(_arte, rect, false, tinta)
	else:
		# Senza illustrazione resta una sagoma leggibile: il duello non deve mai
		# dipendere da un file che potrebbe non essere stato esportato.
		_arena.draw_colored_polygon(PackedVector2Array([
			rect.get_center() + Vector2(0, -66), rect.get_center() + Vector2(52, 0),
			rect.get_center() + Vector2(0, 66), rect.get_center() + Vector2(-52, 0),
		]), Color(0.10, 0.22, 0.28, 0.96))

	# La parata: uno scudo d'ambra che si chiude davanti al guardiano. Due archi
	# invece di uno, perché a un arco solo il gesto si legge come un alone e non
	# come una difesa — e questo è il fotogramma in cui il bambino deve capire in
	# un colpo d'occhio che il colpo l'ha preso lui.
	if _parata > 0.0:
		var quota := _parata / DURATA_PARATA
		var perno := Vector2(rect.get_center().x, rect.end.y - 6.0)
		_arena.draw_arc(perno, 92.0, PI * 0.10, PI * 0.90, 40, Color(AMBRA, 0.9 * quota), 7.0, true)
		_arena.draw_arc(perno, 78.0, PI * 0.18, PI * 0.82, 32, Color(AMBRA, 0.45 * quota), 3.0, true)
	# La rottura: anelli che si allargano dal petto.
	if _rottura > 0.0 and not reduced_motion:
		var t := 1.0 - (_rottura / DURATA_ROTTURA)
		for anello in range(2):
			var raggio := 40.0 + t * (130.0 + float(anello) * 40.0)
			_arena.draw_arc(rect.get_center(), raggio, 0.0, TAU, 48,
				Color(ORO, 0.5 * (1.0 - t)), 3.0, true)

	# Il cartiglio del sigillo, sul petto: il numero da fare sta addosso a chi lo
	# porta, non in un angolo dell'interfaccia.
	var targa := Rect2(centro_x - 92.0, Y_TARGA, 184.0, ALTEZZA_TARGA)
	_arena.draw_rect(targa, Color(0.02, 0.07, 0.10, 0.92))
	_arena.draw_rect(targa, Color(ORO, 0.85 if not high_contrast else 1.0), false, 2.0)

func _disegna_carica(centro_x: float) -> void:
	var quota := clampf(_tempo / maxf(_tempo_massimo, 0.01), 0.0, 1.0)
	var carica := 1.0 - quota
	var larghezza := 300.0
	var rect := Rect2(centro_x - larghezza * 0.5, Y_CARICA, larghezza, 9.0)
	_arena.draw_rect(rect, Color(0.05, 0.12, 0.16, 0.9))
	var colore := GHIACCIO.lerp(AMBRA, carica)
	_arena.draw_rect(Rect2(rect.position, Vector2(rect.size.x * carica, rect.size.y)),
		Color(colore, 0.95))
	_arena.draw_rect(rect, Color(colore, 0.5), false, 1.2)
	# Vicino al colpo la barra pulsa: l'urgenza detta senza colorare di rosso il
	# numero che il bambino sta guardando.
	if carica > 0.72 and not reduced_motion:
		var battito := (sin(_onda * 14.0) * 0.5 + 0.5) * (carica - 0.72) / 0.28
		_arena.draw_rect(rect.grow(3.0 + battito * 3.0), Color(AMBRA, 0.28 * battito), false, 2.0)

func _disegna_corda(scossa: Vector2, bersaglio: int) -> void:
	var rect := _corda_rect()
	rect.position += scossa
	var tacca := _punto_corda(bersaglio) + scossa.x

	# Il binario, e la zona oltre il sigillo: barrata, perché superare si deve
	# vedere prima di leggerlo.
	_arena.draw_rect(rect, Color(0.04, 0.11, 0.15, 0.95))
	var oltre := Rect2(tacca, rect.position.y, rect.end.x - tacca, rect.size.y)
	if oltre.size.x > 0.0:
		_arena.draw_rect(oltre, Color(AMBRA, 0.12))
		var passo := 9.0
		var x := oltre.position.x
		while x < oltre.end.x:
			_arena.draw_line(Vector2(x, oltre.position.y),
				Vector2(x - 6.0, oltre.end.y), Color(AMBRA, 0.18), 1.0)
			x += passo
	# Il tratto già percorso.
	var ago := _punto_corda(_impulso) + scossa.x
	_arena.draw_rect(Rect2(rect.position, Vector2(maxf(ago - rect.position.x, 0.0), rect.size.y)),
		Color(FREDDO, 0.42))
	_arena.draw_rect(rect, Color(FREDDO, 0.55 if not high_contrast else 1.0), false, 1.4)

	# La tacca del sigillo: alta, dorata, con la sua ombra.
	_arena.draw_line(Vector2(tacca, rect.position.y - 16.0),
		Vector2(tacca, rect.end.y + 12.0), Color(0.01, 0.03, 0.05, 0.8), 6.0)
	_arena.draw_line(Vector2(tacca, rect.position.y - 15.0),
		Vector2(tacca, rect.end.y + 11.0), ORO, 3.0)

	# L'ago dell'impulso: un triangolo che punta alla corda.
	var oltre_sigillo := _impulso > bersaglio
	var colore_ago := AMBRA if oltre_sigillo else GHIACCIO
	var punta := Vector2(ago, rect.position.y - 2.0)
	_arena.draw_colored_polygon(PackedVector2Array([
		punta, punta + Vector2(11, -17), punta + Vector2(-11, -17),
	]), colore_ago)
	_arena.draw_line(punta, Vector2(ago, rect.end.y + 8.0), Color(colore_ago, 0.75), 2.0)
	if not high_contrast:
		_arena.draw_circle(Vector2(ago, rect.get_center().y), 13.0, Color(colore_ago, 0.10))

	# Le tacche di lettura: un quarto, metà, tre quarti del sigillo. Servono a
	# stimare senza contare — «sono a metà» è un pensiero più veloce di «sono a 21».
	for frazione in [0.25, 0.5, 0.75]:
		var x := _punto_corda(int(round(float(bersaglio) * frazione))) + scossa.x
		_arena.draw_line(Vector2(x, rect.end.y + 2.0), Vector2(x, rect.end.y + 7.0),
			Color(FREDDO, 0.4), 1.0)

func _disegna_colpo(scossa: Vector2) -> void:
	if _colpo <= 0.0 or _colpo_indice < 0 or reduced_motion:
		return
	var quota := _colpo / DURATA_COLPO
	# Il colpo parte dalla runa e arriva alla corda: si vede *da dove* è venuto,
	# e a fine scambio la catena scritta racconta la stessa cosa in parole.
	var da := _rettangolo_runa(_colpo_indice).get_center() + Vector2(0, _arena.size.y + 12.0)
	var a := Vector2(_punto_corda(_impulso), _corda_rect().get_center().y) + scossa
	_arena.draw_line(da, a, Color(GHIACCIO, 0.28 * quota), 8.0 + 6.0 * quota, true)
	_arena.draw_line(da, a, Color(TESTO, 0.85 * quota), 2.0 + 3.0 * quota, true)
	_arena.draw_arc(a, 8.0 + (1.0 - quota) * 26.0, 0.0, TAU, 28,
		Color(GHIACCIO, 0.8 * quota), 3.0, true)

func _rettangolo_runa(indice: int) -> Rect2:
	var quante := maxi(_rune.size(), 1)
	var totale := RUNA_LARGA * float(quante) + RUNA_GAP * float(quante - 1)
	var larghezza := LARGHEZZA
	if is_instance_valid(_rune_zona) and _rune_zona.size.x > 1.0:
		larghezza = _rune_zona.size.x
	var x := (larghezza - totale) * 0.5 + float(indice) * (RUNA_LARGA + RUNA_GAP)
	return Rect2(x, 14.0, RUNA_LARGA, RUNA_ALTA)

func _disegna_rune() -> void:
	for indice in _rune.size():
		var rect := _rettangolo_runa(indice)
		var runa: Dictionary = _rune[indice]
		var usata := _usate.has(indice)
		var entra := GuardianDuel.applicabile(_impulso, runa)
		var etichetta: Label = _rune_label[indice] if indice < _rune_label.size() else null
		if is_instance_valid(etichetta):
			etichetta.size = Vector2(rect.size.x, 34)
			etichetta.position = Vector2(rect.position.x, rect.get_center().y - 17.0)
			etichetta.modulate.a = 0.22 if usata else (0.40 if not entra else 1.0)

		var riempimento := Color(0.07, 0.17, 0.22, 0.98)
		var bordo := Color(FREDDO, 0.9)
		if usata:
			riempimento = Color(0.03, 0.08, 0.11, 0.55)
			bordo = Color(FREDDO, 0.16)
		elif not entra:
			riempimento = Color(0.04, 0.10, 0.13, 0.85)
			bordo = Color(FREDDO, 0.28)
		if high_contrast and not usata and entra:
			riempimento = Color(0.01, 0.05, 0.08, 1.0)
			bordo = Color.WHITE

		if not usata and entra and not high_contrast:
			_rune_zona.draw_circle(rect.get_center() + Vector2(0, 4), rect.size.x * 0.62,
				Color(FREDDO, 0.05))
		_rune_zona.draw_colored_polygon(_pietra(rect.grow(-1.0)), Color(0.0, 0.02, 0.03, 0.35))
		_rune_zona.draw_colored_polygon(_pietra(rect), riempimento)
		var contorno := _pietra(rect)
		contorno.append(contorno[0])
		_rune_zona.draw_polyline(contorno, bordo, 2.0, true)

		# La runa che non entra porta la sua sbarra: `÷4` su 30 non si può fare,
		# e vederlo scritto insegna la divisibilità meglio di una spiegazione.
		if not entra and not usata:
			_rune_zona.draw_line(rect.position + Vector2(14, rect.size.y - 14),
				rect.position + Vector2(rect.size.x - 14, 14), Color(FREDDO, 0.35), 2.0)
		# Il numero del tasto, per chi gioca da tastiera.
		if indice < 6:
			_rune_zona.draw_string(ThemeDB.fallback_font,
				rect.position + Vector2(8, 16), str(indice + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(TESTO, 0.34))
		# Il lampo del colpo appena dato.
		if indice == _colpo_indice and _colpo > 0.0:
			var quota := _colpo / DURATA_COLPO
			_rune_zona.draw_polyline(contorno, Color(GHIACCIO, 0.9 * quota), 3.0 + 2.0 * quota, true)

## La forma della runa: un rettangolo con gli angoli tagliati, cioè una pietra.
## Non è un esagono e non è un cerchio — il chiavistello è fatto di esagoni che
## girano, e due minigiochi che si somigliano si confondono nel ricordo.
func _pietra(rect: Rect2) -> PackedVector2Array:
	var taglio := 14.0
	return PackedVector2Array([
		rect.position + Vector2(taglio, 0),
		rect.position + Vector2(rect.size.x - taglio, 0),
		rect.position + Vector2(rect.size.x, taglio),
		rect.position + Vector2(rect.size.x, rect.size.y - taglio),
		rect.position + Vector2(rect.size.x - taglio, rect.size.y),
		rect.position + Vector2(taglio, rect.size.y),
		rect.position + Vector2(0, rect.size.y - taglio),
		rect.position + Vector2(0, taglio),
	])
