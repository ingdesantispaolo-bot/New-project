class_name DuelStage
extends Control

## **Il campo del duello**: quello che due guardiani hanno in comune qualunque
## cosa chiedano. (17 agosto 2026)
##
## Nasce dividendo in due il pannello del 16 agosto, quando il duello era uno
## solo ed era di calcolo. Il giorno dopo ne è arrivato un secondo, di verbi, e
## la scelta era fra copiare quattrocento righe o riconoscere che **il
## combattimento è lo stesso e cambia soltanto la domanda**.
##
## Qui vive tutto ciò che non dipende dalla materia:
##
## - il guardiano illustrato, i suoi **sigilli**, la sua **carica** che si riempie;
## - la **tenuta** di Eli, i **colpi** contati, la pausa dopo ogni scambio;
## - il colpo che parte dalla runa, il sigillo che si spezza, la parata in ambra;
## - l'uscita che non costa niente, i tasti 1-6, il contrasto e il movimento ridotto.
##
## Le sottoclassi mettono **il campo centrale e le rune**: la corda di risonanza
## e le pietre con le operazioni ([[GuardianDuelPanel]]), la griglia dei modi e
## dei tempi con le rune dei tre assi ([[VerbDuelPanel]]).
##
## **Perché una classe base e non un pannello con un interruttore.** Un pannello
## solo che disegnasse ora una scala di numeri ora una tabella di verbi avrebbe
## due volte le variabili e metà della leggibilità, e ogni ritocco a una materia
## sarebbe un rischio per l'altra. Qui la materia non può rompere il
## combattimento, e il combattimento si tara in un posto solo.

signal risolto(vinto: bool, netto: bool)

const GUARDIAN_VISUALS := preload("res://scripts/game/guardian_visual_catalog.gd")
const CHAPTER_ART := preload("res://scripts/visual/chapter_art.gd")

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

## La geometria dell'arena, che ogni materia ritocca in `_init`: la corda di
## risonanza sta in poco spazio, la griglia dei verbi ne vuole molto di più.
var geo := {
	"larghezza": 660.0, "arena": 332.0, "rune": 116.0,
	"ySigilli": 14.0, "yArte": 26.0, "latoArte": 160.0,
	"yTarga": 150.0, "altezzaTarga": 56.0, "yCarica": 214.0,
	"larghezzaCarica": 300.0,
}

var _rng := RandomNumberGenerator.new()
var _scambio: Dictionary = {}
var _rune: Array = []
var _usate: Dictionary = {}
var _catena: Array = []
var _sigilli_rotti := 0
var _tenuta := 2
var _colpi_dati := 0
var _netto := true
var _attivo := false
## Il fermo-immagine fra uno scambio e l'altro: il sigillo che si spezza e il
## colpo che si incassa hanno diritto al loro istante.
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
var _chapter_backdrop: TextureRect
var _veil: ColorRect
var _attesa: Tween
var _arena: Control
var _rune_zona: Control
var _colonna: VBoxContainer
var _titolo: Label
var _sigillo_label: Label
var _sigillo_sotto: Label
var _catena_label: Label
var _stato: Label
var _rune_label: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	set_process(true)

## Avvia un duello. `seme` cambia a ogni sfida: rifare a memoria un duello perso
## non deve essere possibile — la seconda volta si penserebbe di meno, che è
## esattamente la cosa che questi minigiochi esistono per non permettere.
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
	_chapter_backdrop.texture = CHAPTER_ART.texture_for_world(int(regole.get("mondo", 1)))
	_chapter_backdrop.visible = not high_contrast
	_veil.color = Color(0.015, 0.04, 0.065, 0.97 if high_contrast else 0.78)
	var materia := ""
	match str(regole.get("materia", "")):
		DuelRules.VOCI:
			materia = "ITALIANO"
		DuelRules.CIFRE:
			materia = "MATEMATICA"
	var parti := PackedStringArray([nome_guardiano.to_upper()])
	if not materia.is_empty():
		parti.append(materia)
	parti.append(str(regole.get("nome", "sfida")))
	_titolo.text = " · ".join(parti)
	_nuovo_scambio()
	_entrata()

func attivo() -> bool:
	return _attivo

func _entrata() -> void:
	if reduced_motion:
		return
	modulate.a = 0.0
	var entrata := create_tween()
	entrata.tween_property(self, "modulate:a", 1.0, 0.18)

# --- Costruzione --------------------------------------------------------------

func _costruisci() -> void:
	_chapter_backdrop = TextureRect.new()
	_chapter_backdrop.name = "DuelChapterBackdrop"
	_chapter_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapter_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chapter_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_chapter_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chapter_backdrop)

	_veil = ColorRect.new()
	_veil.name = "DuelVeil"
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(0.015, 0.04, 0.065, 0.78)
	add_child(_veil)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_colonna = VBoxContainer.new()
	_colonna.name = "DuelColumn"
	_colonna.custom_minimum_size = Vector2(float(geo["larghezza"]), 0)
	_colonna.add_theme_constant_override("separation", 6)
	centro.add_child(_colonna)

	_titolo = Label.new()
	_titolo.name = "DuelTitle"
	_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titolo.add_theme_font_size_override("font_size", 20)
	_titolo.add_theme_color_override("font_color", ORO)
	_colonna.add_child(_titolo)

	_arena = Control.new()
	_arena.name = "DuelArena"
	_arena.custom_minimum_size = Vector2(float(geo["larghezza"]), float(geo["arena"]))
	_arena.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.draw.connect(_disegna_arena)
	_colonna.add_child(_arena)

	_sigillo_label = etichetta("DuelSealValue", 34, ORO)
	_arena.add_child(_sigillo_label)
	_sigillo_sotto = etichetta("DuelSealHint", 13, Color("c9b98a"))
	_arena.add_child(_sigillo_sotto)
	_catena_label = etichetta("DuelChain", 16, Color("9fd8d2"))
	_arena.add_child(_catena_label)

	_rune_zona = Control.new()
	_rune_zona.name = "DuelRunes"
	_rune_zona.custom_minimum_size = Vector2(float(geo["larghezza"]), float(geo["rune"]))
	_rune_zona.draw.connect(_disegna_rune)
	_rune_zona.gui_input.connect(_tocco)
	_colonna.add_child(_rune_zona)

	_stato = Label.new()
	_stato.name = "DuelStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 14)
	_stato.add_theme_color_override("font_color", Color("9fd8d2"))
	_colonna.add_child(_stato)

	var fuga := Button.new()
	fuga.name = "DuelLeaveButton"
	fuga.text = "LASCIA PERDERE"
	fuga.custom_minimum_size = Vector2(0, 46)
	fuga.add_theme_font_size_override("font_size", 14)
	# Andarsene non costa niente e non è una sconfitta: il guardiano resta dov'è.
	fuga.pressed.connect(_rinuncia)
	_colonna.add_child(fuga)

	_costruisci_campo()

func etichetta(nome_nodo: String, dimensione: int, colore: Color) -> Label:
	var nodo := Label.new()
	nodo.name = nome_nodo
	nodo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nodo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nodo.add_theme_font_size_override("font_size", dimensione)
	nodo.add_theme_color_override("font_color", colore)
	nodo.add_theme_constant_override("outline_size", 5)
	nodo.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.05, 0.9))
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return nodo

# --- I ganci della materia ----------------------------------------------------
#
# Le sottoclassi riempiono questi cinque. Il combattimento non sa niente di
# numeri né di verbi, e non deve saperlo.

## Etichette in più che servono alla materia (la voce di Eli, l'impulso…).
func _costruisci_campo() -> void:
	pass

## Prepara lo scambio nuovo: rune, catena, testo del sigillo, tempo.
func _nuovo_scambio() -> void:
	pass

## Rimette a posto le etichette della materia, ogni fotogramma.
func _posiziona_campo() -> void:
	pass

## Disegna il campo centrale (la corda, la griglia…).
func _disegna_campo(_scossa: Vector2) -> void:
	pass

## Disegna le rune in mano.
func _disegna_rune() -> void:
	pass

## Colpisce con la runa `indice`. È la sola porta: dito, mouse, tasti e audit.
func colpisci(_indice: int) -> void:
	pass

## La strada più corta verso il sigillo di adesso, come indici di rune. Pubblica
## perché la usano gli audit di scena: un combattimento che si può giocare solo
## con le dita non si può collaudare, e questo decide se un forziere si apre.
func sequenza_vincente() -> Array:
	return []

## Il rettangolo della runa `indice` nello spazio della sua zona. In fila per le
## cifre, a griglia per le voci — le pietre dei verbi portano parole intere.
func rettangolo_runa(_indice: int) -> Rect2:
	return Rect2()

# --- Lo scambio, il colpo, la parata ------------------------------------------

## Ogni materia lo chiama quando l'impulso è arrivato sul sigillo.
func spezza_sigillo() -> void:
	_sigilli_rotti += 1
	if _colpi_dati > int(_scambio.get("minimi", 99)):
		_netto = false
	_rottura = DURATA_ROTTURA
	_in_pausa = true
	suona("enigmaCompleted", 1.0 + float(_sigilli_rotti) * 0.06)
	aggiorna_stato()
	if _sigilli_rotti >= int(regole.get("sigilli", 2)):
		_attivo = false
		# Mezzo secondo per vedere l'ultimo sigillo andare in pezzi: è l'unico
		# momento in cui questo pannello si prende del tempo, ed è quello che
		# rende la vittoria una vittoria invece di un passaggio.
		dopo(0.55, func(): risolto.emit(true, _netto))
		return
	dopo(DURATA_ROTTURA, _riprendi)

## **Il guardiano colpisce.** Succede quando la carica è piena, quando i colpi
## sono finiti senza risultato, o quando la strada si è chiusa. Costa un punto di
## tenuta e riapre lo scambio con numeri — o voci — nuovi: non si resta mai
## bloccati su un sigillo che non si è saputo fare.
func incassa() -> void:
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
	suona("sessionDefeated", 1.05)
	aggiorna_stato()
	if _tenuta <= 0:
		_attivo = false
		dopo(0.45, func(): risolto.emit(false, false))
		return
	dopo(DURATA_PARATA, _riprendi)

func _riprendi() -> void:
	if not _attivo:
		return
	_in_pausa = false
	_nuovo_scambio()

## Un'attesa che con `reduced_motion` resta breve ma non sparisce: anche chi ha
## bisogno di meno movimento ha diritto a vedere che cosa è appena successo.
func dopo(secondi: float, cosa: Callable) -> void:
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

## Segna il colpo appena dato: il lampo sulla runa e il fascio verso il campo.
func segna_colpo(indice: int) -> void:
	_colpo = DURATA_COLPO
	_colpo_indice = indice

## La runa non entra: non è un errore, non costa un colpo, non fa rumore di
## sbaglio. Costa il tempo che ci si è messi a provarla, che è già la lezione.
func runa_spenta() -> void:
	_tremore = 0.5
	suona("hintShown", 0.62)

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
			incassa()
	_posiziona()
	_arena.queue_redraw()
	_rune_zona.queue_redraw()

func aggiorna_stato() -> void:
	if not is_instance_valid(_stato):
		return
	# La tenuta di Eli si scrive con un segno diverso da quello dei sigilli del
	# guardiano: due tondi non si confondono con due rombi d'oro, e in un
	# combattimento sapere di chi è la vita che si sta guardando è tutto.
	_stato.text = "sigilli %d/%d · colpi %d/%d · tenuta %s" % [
		_sigilli_rotti, int(regole.get("sigilli", 2)),
		_colpi_dati, int(regole.get("colpi", 3)),
		"•".repeat(maxi(_tenuta, 0))]

func _posiziona() -> void:
	var centro_x := _arena.size.x * 0.5
	var alto_targa := float(geo["altezzaTarga"])
	# Quando c'è la riga piccola sotto («da temere»), quella grande le lascia il
	# posto invece di appoggiarcisi sopra: nella sonda le due righe si toccavano.
	var con_sotto := not str(_sigillo_sotto.text).is_empty()
	_sigillo_label.size = Vector2(340, alto_targa - (22.0 if con_sotto else 4.0))
	_sigillo_label.position = Vector2(centro_x - 170, float(geo["yTarga"]) + 1.0)
	_sigillo_sotto.size = Vector2(340, 17)
	_sigillo_sotto.position = Vector2(centro_x - 170,
		float(geo["yTarga"]) + alto_targa - 20.0)
	_catena_label.size = Vector2(_arena.size.x - 40, 24)
	_catena_label.position = Vector2(20, float(geo["arena"]) - 28.0)
	_posiziona_campo()

func _tocco(event: InputEvent) -> void:
	if not _attivo:
		return
	var premuto: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not premuto:
		return
	var punto: Vector2 = event.position
	for indice in _rune.size():
		if rettangolo_runa(indice).grow(4.0).has_point(punto):
			colpisci(indice)
			return

func _unhandled_input(event: InputEvent) -> void:
	if not _attivo or not visible:
		return
	# I tasti 1-6: su desktop cercare il mouse mentre si pensa è un secondo
	# lavoro, e questi minigiochi misurano il primo.
	if event is InputEventKey and event.pressed and not event.echo:
		var codice := int(event.keycode)
		if codice >= KEY_1 and codice <= KEY_6:
			colpisci(codice - KEY_1)
			get_viewport().set_input_as_handled()

func suona(evento: String, tono: float) -> void:
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", evento, tono)

# --- Disegno condiviso --------------------------------------------------------

func _disegna_arena() -> void:
	var scossa := Vector2.ZERO
	if _tremore > 0.0 and not reduced_motion:
		scossa = Vector2(sin(_tremore * 52.0) * 6.0 * _tremore, 0.0)
	var centro_x := _arena.size.x * 0.5 + scossa.x
	_disegna_sigilli(centro_x)
	_disegna_guardiano(centro_x)
	_disegna_carica(centro_x)
	_disegna_campo(scossa)
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
		var punto := Vector2(partenza + passo * float(indice), float(geo["ySigilli"]))
		var rombo := PackedVector2Array([
			punto + Vector2(0, -11), punto + Vector2(9, 0),
			punto + Vector2(0, 11), punto + Vector2(-9, 0),
		])
		if indice < _sigilli_rotti:
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
	var lato := float(geo["latoArte"])
	var rect := Rect2(centro_x - lato * 0.5, float(geo["yArte"]) + respiro + spinta, lato, lato)

	if not high_contrast:
		_arena.draw_circle(rect.get_center() + Vector2(0, 6), lato * 0.58, Color(FREDDO, 0.05))
		_arena.draw_circle(rect.get_center() + Vector2(0, 6), lato * 0.39, Color(FREDDO, 0.05))
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
			rect.get_center() + Vector2(0, -lato * 0.41), rect.get_center() + Vector2(lato * 0.32, 0),
			rect.get_center() + Vector2(0, lato * 0.41), rect.get_center() + Vector2(-lato * 0.32, 0),
		]), Color(0.10, 0.22, 0.28, 0.96))

	# La parata: uno scudo d'ambra che si chiude davanti al guardiano.
	if _parata > 0.0:
		var quota := _parata / DURATA_PARATA
		var perno := Vector2(rect.get_center().x, rect.end.y - 6.0)
		_arena.draw_arc(perno, lato * 0.58, PI * 0.10, PI * 0.90, 40, Color(AMBRA, 0.9 * quota), 7.0, true)
		_arena.draw_arc(perno, lato * 0.49, PI * 0.18, PI * 0.82, 32, Color(AMBRA, 0.45 * quota), 3.0, true)
	# La rottura: anelli che si allargano dal petto.
	if _rottura > 0.0 and not reduced_motion:
		var t := 1.0 - (_rottura / DURATA_ROTTURA)
		for anello in range(2):
			var raggio := 40.0 + t * (130.0 + float(anello) * 40.0)
			_arena.draw_arc(rect.get_center(), raggio, 0.0, TAU, 48,
				Color(ORO, 0.5 * (1.0 - t)), 3.0, true)

	# Il cartiglio del sigillo, sul petto: quello che c'è da fare sta addosso a
	# chi lo porta, non in un angolo dell'interfaccia.
	var targa := Rect2(centro_x - 178.0, float(geo["yTarga"]), 356.0, float(geo["altezzaTarga"]))
	_arena.draw_rect(targa, Color(0.02, 0.07, 0.10, 0.92))
	_arena.draw_rect(targa, Color(ORO, 0.85 if not high_contrast else 1.0), false, 2.0)

func _disegna_carica(centro_x: float) -> void:
	var quota := clampf(_tempo / maxf(_tempo_massimo, 0.01), 0.0, 1.0)
	var carica := 1.0 - quota
	var larghezza := float(geo["larghezzaCarica"])
	var rect := Rect2(centro_x - larghezza * 0.5, float(geo["yCarica"]), larghezza, 9.0)
	_arena.draw_rect(rect, Color(0.05, 0.12, 0.16, 0.9))
	var colore := GHIACCIO.lerp(AMBRA, carica)
	_arena.draw_rect(Rect2(rect.position, Vector2(rect.size.x * carica, rect.size.y)),
		Color(colore, 0.95))
	_arena.draw_rect(rect, Color(colore, 0.5), false, 1.2)
	# Vicino al colpo la barra pulsa: l'urgenza detta senza colorare di rosso
	# quello che il bambino sta guardando.
	if carica > 0.72 and not reduced_motion:
		var battito := (sin(_onda * 14.0) * 0.5 + 0.5) * (carica - 0.72) / 0.28
		_arena.draw_rect(rect.grow(3.0 + battito * 3.0), Color(AMBRA, 0.28 * battito), false, 2.0)

## Il fascio del colpo: parte dalla runa toccata e arriva dove la materia dice.
## Si vede **da dove** è venuto, e a fine scambio la catena scritta racconta la
## stessa cosa in parole.
func disegna_fascio(verso: Vector2) -> void:
	if _colpo <= 0.0 or _colpo_indice < 0 or reduced_motion:
		return
	var quota := _colpo / DURATA_COLPO
	var da := rettangolo_runa(_colpo_indice).get_center() + Vector2(0, _arena.size.y + 12.0)
	_arena.draw_line(da, verso, Color(GHIACCIO, 0.28 * quota), 8.0 + 6.0 * quota, true)
	_arena.draw_line(da, verso, Color(TESTO, 0.85 * quota), 2.0 + 3.0 * quota, true)
	_arena.draw_arc(verso, 8.0 + (1.0 - quota) * 26.0, 0.0, TAU, 28,
		Color(GHIACCIO, 0.8 * quota), 3.0, true)

## La forma della runa: un rettangolo con gli angoli tagliati, cioè una pietra.
## Non è un esagono e non è un cerchio — il chiavistello dei forzieri è fatto di
## esagoni che girano, e due minigiochi che si somigliano si confondono nel
## ricordo.
func pietra(rect: Rect2) -> PackedVector2Array:
	var taglio := minf(14.0, rect.size.y * 0.24)
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

## Disegna una pietra nei suoi tre stati, uguale per tutte le materie: viva,
## **spenta** (qui non entra, e porta la sua sbarra) o **consumata**.
func disegna_pietra(indice: int, rect: Rect2, entra: bool, usata: bool) -> void:
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

	# L'alone segue la **forma** della pietra e non un raggio calcolato sulla sua
	# larghezza: le pietre delle voci sono larghe il doppio di quelle delle cifre,
	# e un cerchio proporzionato alla larghezza diventava una macchia scura dietro
	# tutta la fila. Visto solo nella sonda visuale.
	if not usata and entra and not high_contrast:
		_rune_zona.draw_colored_polygon(pietra(rect.grow(7.0)), Color(FREDDO, 0.05))
	_rune_zona.draw_colored_polygon(pietra(rect.grow(-1.0)), Color(0.0, 0.02, 0.03, 0.35))
	_rune_zona.draw_colored_polygon(pietra(rect), riempimento)
	var contorno := pietra(rect)
	contorno.append(contorno[0])
	_rune_zona.draw_polyline(contorno, bordo, 2.0, true)

	if not entra and not usata:
		_rune_zona.draw_line(rect.position + Vector2(14, rect.size.y - 14),
			rect.position + Vector2(rect.size.x - 14, 14), Color(FREDDO, 0.35), 2.0)
	# Il numero del tasto, per chi gioca da tastiera.
	if indice < 6:
		_rune_zona.draw_string(ThemeDB.fallback_font,
			rect.position + Vector2(8, 16), str(indice + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(TESTO, 0.34))
	if indice == _colpo_indice and _colpo > 0.0:
		var quota := _colpo / DURATA_COLPO
		_rune_zona.draw_polyline(contorno, Color(GHIACCIO, 0.9 * quota), 3.0 + 2.0 * quota, true)
