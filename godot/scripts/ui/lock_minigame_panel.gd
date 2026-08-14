class_name LockMinigamePanel
extends Control

## **IL CHIAVISTELLO** — la serratura del forziere. (14 agosto 2026)
##
## Un quadrante. Al centro il numero che apre; attorno, tessere con operazioni
## che girano piano. Si tocca quella che fa il numero. Ogni tessera giusta fa
## scattare un dente dell'anello esterno; quando scattano tutti, il forziere si
## apre. Le regole e i numeri vengono da [[LockChallenge]], qui vive solo la
## messa in scena — ed è una divisione che conta, perché questo pannello si vede
## decine di volte per mondo e la logica dietro deve poter essere collaudata
## senza aprire una finestra.
##
## **Le scelte di resa, e perché ognuna.**
##
## - **Tutto in un disegno solo** (`_disegna`): anello, denti, tessere, alone e
##   lancetta del tempo stanno in un unico `_draw` sul quadrante. Un albero di
##   nodi per ventiquattro elementi che ruotano costerebbe più del disegno stesso,
##   e su tablet il budget è quello che è (`WorldProfileCatalog.performance_budget`).
##   I numeri restano `Label`, perché il testo va scalato dal tema e non dal codice.
## - **Il tempo è un arco che si consuma**, non una barra: sta attorno al
##   bersaglio, quindi si legge **senza staccare gli occhi** dal numero da fare.
##   Una barra in basso costringerebbe a guardare altrove proprio mentre si conta.
## - **L'errore non lampeggia di rosso.** La tessera sbagliata si spegne e resta
##   lì, il quadrante trema un istante. Il rosso su un bambino di dieci anni che
##   sta contando in fretta è una punizione, e qui non c'è niente da punire:
##   sbagliare non toglie nulla, toglie solo tempo.
## - **Il dente che scatta ha il suo istante**: lampo, scatto e un anello che si
##   allarga. È l'unico momento in cui il pannello si prende mezzo secondo, ed è
##   quello che rende l'apertura una piccola vittoria invece di un passaggio.
##
## **Accessibilità.** Con `reduced_motion` le tessere non ruotano e il tempo è più
## lungo (`LockChallenge.TEMPO_RIDOTTO`); con `high_contrast` i bordi diventano
## pieni e l'alone sparisce. Si gioca col dito, col mouse e con la tastiera —
## i tasti 1-6 scelgono la tessera, perché su desktop contare e cercare il mouse
## sono due lavori diversi.
##
## **Si può sempre uscire**, e uscire non costa niente: il forziere resta chiuso e
## si riprova quando si vuole, con numeri nuovi.

signal risolto(vinto: bool, pulito: bool)

const RAGGIO_QUADRANTE := 176.0
const RAGGIO_TESSERE := 126.0
const RAGGIO_TESSERA := 36.0
const DURATA_SCATTO := 0.42

var regole: Dictionary = {}
var titolo_forziere := "forziere"
var reduced_motion := false
var high_contrast := false

var _rng := RandomNumberGenerator.new()
var _dente := {}
var _denti_fatti := 0
var _errori := 0
var _tempo := 0.0
var _tempo_massimo := 1.0
var _attivo := false
var _angolo := 0.0
var _scatto := 0.0
var _tremore := 0.0
var _spente: Dictionary = {}

var _quadrante: Control
var _bersaglio_label: Label
var _titolo: Label
var _stato: Label
var _etichette: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	set_process(true)

## Avvia una sfida. `seme` cambia a ogni tentativo: rifare a memoria un
## chiavistello fallito non deve essere possibile.
func avvia(regole_sfida: Dictionary, titolo: String, seme: int,
		movimento_ridotto: bool, contrasto: bool) -> void:
	regole = regole_sfida.duplicate(true)
	titolo_forziere = titolo
	reduced_motion = movimento_ridotto
	high_contrast = contrasto
	_rng.seed = seme
	_denti_fatti = 0
	_errori = 0
	_angolo = 0.0
	_scatto = 0.0
	_tremore = 0.0
	_attivo = true
	visible = true
	_titolo.text = str(regole.get("nome", "chiavistello")).to_upper()
	_nuovo_dente()
	_entrata()

## L'ingresso: il quadrante arriva da poco più piccolo e si assesta. Mezzo
## quarto di secondo, non di più — il chiavistello si apre decine di volte per
## mondo, e un'animazione che si fa notare alla decima diventa un'attesa.
func _entrata() -> void:
	if reduced_motion or not is_instance_valid(_quadrante):
		return
	_quadrante.pivot_offset = _quadrante.size * 0.5
	_quadrante.scale = Vector2.ONE * 0.92
	modulate.a = 0.0
	var entrata := create_tween()
	entrata.set_parallel(true)
	entrata.tween_property(_quadrante, "scale", Vector2.ONE, 0.22).set_trans(
		Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrata.tween_property(self, "modulate:a", 1.0, 0.16)

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "LockVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.015, 0.045, 0.07, 0.90)
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var colonna := VBoxContainer.new()
	colonna.name = "LockColumn"
	colonna.add_theme_constant_override("separation", 10)
	centro.add_child(colonna)

	_titolo = Label.new()
	_titolo.name = "LockTitle"
	_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titolo.add_theme_font_size_override("font_size", 22)
	_titolo.add_theme_color_override("font_color", Color("f4cf69"))
	colonna.add_child(_titolo)

	_stato = Label.new()
	_stato.name = "LockStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 13)
	_stato.add_theme_color_override("font_color", Color("9fd8d2"))
	colonna.add_child(_stato)

	_quadrante = Control.new()
	_quadrante.name = "LockDial"
	_quadrante.custom_minimum_size = Vector2(RAGGIO_QUADRANTE * 2.0, RAGGIO_QUADRANTE * 2.0)
	_quadrante.draw.connect(_disegna)
	_quadrante.gui_input.connect(_tocco)
	colonna.add_child(_quadrante)

	_bersaglio_label = Label.new()
	_bersaglio_label.name = "LockTarget"
	_bersaglio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bersaglio_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bersaglio_label.add_theme_font_size_override("font_size", 46)
	_bersaglio_label.add_theme_color_override("font_color", Color("f2fbff"))
	_bersaglio_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quadrante.add_child(_bersaglio_label)

	var fuga := Button.new()
	fuga.name = "LockLeaveButton"
	fuga.text = "LASCIA STARE"
	fuga.custom_minimum_size = Vector2(0, 42)
	fuga.add_theme_font_size_override("font_size", 13)
	fuga.pressed.connect(func():
		if not _attivo:
			return
		_attivo = false
		visible = false
		risolto.emit(false, false))
	colonna.add_child(fuga)

func _nuovo_dente() -> void:
	_dente = LockChallenge.genera_dente(_rng, regole)
	_spente.clear()
	_tempo_massimo = float(regole.get("secondi", 5.0))
	_tempo = _tempo_massimo
	_bersaglio_label.text = str(int(_dente.get("bersaglio", 0)))
	_costruisci_etichette()
	_aggiorna_stato()

## Le etichette delle tessere: una `Label` per tessera, riposizionata a ogni
## frame sul cerchio. Il testo va al tema (dimensioni, font, accessibilità di
## sistema); la forma sotto la disegna il quadrante.
func _costruisci_etichette() -> void:
	for etichetta in _etichette:
		if is_instance_valid(etichetta):
			etichetta.queue_free()
	_etichette.clear()
	var tessere: Array = _dente.get("tessere", [])
	for indice in tessere.size():
		var etichetta := Label.new()
		etichetta.name = "LockTile%d" % indice
		etichetta.text = str(Dictionary(tessere[indice]).get("testo", ""))
		etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etichetta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etichetta.add_theme_font_size_override("font_size", 19)
		etichetta.add_theme_color_override("font_color", Color("eaf7ff"))
		etichetta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_quadrante.add_child(etichetta)
		_etichette.append(etichetta)

func _process(delta: float) -> void:
	if not is_instance_valid(_quadrante):
		return
	if _scatto > 0.0:
		_scatto = maxf(0.0, _scatto - delta)
	if _tremore > 0.0:
		_tremore = maxf(0.0, _tremore - delta * 2.4)
	if _attivo:
		_angolo += deg_to_rad(float(regole.get("rotazione", 0.0))) * delta
		_tempo -= delta
		if _tempo <= 0.0:
			_fallisci()
	_posiziona_etichette()
	_quadrante.queue_redraw()

func _centro_quadrante() -> Vector2:
	return _quadrante.size * 0.5

func _posizione_tessera(indice: int, totale: int) -> Vector2:
	var passo := TAU / float(maxi(totale, 1))
	var angolo := _angolo + passo * float(indice) - PI * 0.5
	return _centro_quadrante() + Vector2(cos(angolo), sin(angolo)) * RAGGIO_TESSERE

func _posiziona_etichette() -> void:
	var tessere: Array = _dente.get("tessere", [])
	for indice in _etichette.size():
		var etichetta: Label = _etichette[indice]
		if not is_instance_valid(etichetta):
			continue
		var punto := _posizione_tessera(indice, tessere.size())
		etichetta.size = Vector2(RAGGIO_TESSERA * 2.0, 26)
		etichetta.position = punto - etichetta.size * 0.5
		etichetta.modulate.a = 0.34 if _spente.has(indice) else 1.0
	if is_instance_valid(_bersaglio_label):
		_bersaglio_label.size = Vector2(120, 56)
		_bersaglio_label.position = _centro_quadrante() - _bersaglio_label.size * 0.5

func _tocco(event: InputEvent) -> void:
	if not _attivo or not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventScreenTouch and not event.pressed:
		return
	var punto: Vector2 = event.position
	var tessere: Array = _dente.get("tessere", [])
	for indice in tessere.size():
		if punto.distance_to(_posizione_tessera(indice, tessere.size())) <= RAGGIO_TESSERA + 6.0:
			scegli(indice)
			return

func _unhandled_input(event: InputEvent) -> void:
	if not _attivo or not visible:
		return
	# I tasti 1-6: su desktop cercare il mouse mentre si conta è un secondo
	# lavoro, e questo minigioco misura il primo.
	if event is InputEventKey and event.pressed and not event.echo:
		var codice := int(event.keycode)
		if codice >= KEY_1 and codice <= KEY_6:
			scegli(codice - KEY_1)
			get_viewport().set_input_as_handled()

## L'indice della tessera che apre il dente corrente, o -1 se non c'è sfida in
## corso. Pubblico perché lo usano gli audit di scena: un minigioco che si può
## giocare solo con le dita non si può collaudare, e questo si vede decine di
## volte per mondo.
func indice_giusto() -> int:
	var tessere: Array = _dente.get("tessere", [])
	for indice in tessere.size():
		if bool(Dictionary(tessere[indice]).get("giusta", false)):
			return indice
	return -1

func attivo() -> bool:
	return _attivo

## Sceglie una tessera. È la stessa porta che usano il dito, il mouse e i tasti.
func scegli(indice: int) -> void:
	var tessere: Array = _dente.get("tessere", [])
	if indice < 0 or indice >= tessere.size() or _spente.has(indice):
		return
	var tessera: Dictionary = tessere[indice]
	if bool(tessera.get("giusta", false)):
		_denti_fatti += 1
		_scatto = DURATA_SCATTO
		_suona("enigmaProgress", 1.24)
		if _denti_fatti >= int(regole.get("denti", 2)):
			_attivo = false
			visible = false
			risolto.emit(true, _errori == 0)
			return
		_nuovo_dente()
		return
	# Sbagliare spegne quella tessera e basta: niente rosso, niente rimprovero.
	# Il costo è il tempo che si è già speso a calcolarla.
	_errori += 1
	_spente[indice] = true
	_tremore = 1.0
	# Il suono NON è quello della risposta sbagliata degli esercizi: sbagliare una
	# tessera qui non è sbagliare una domanda, ed equipararli insegnerebbe al
	# bambino che il chiavistello lo sta valutando. È un tocco sordo — lo stesso
	# campione del suggerimento, più grave.
	_suona("hintShown", 0.72)
	_aggiorna_stato()

func _fallisci() -> void:
	_attivo = false
	visible = false
	risolto.emit(false, false)

func _aggiorna_stato() -> void:
	if not is_instance_valid(_stato):
		return
	_stato.text = "%s · denti %d/%d" % [
		titolo_forziere, _denti_fatti, int(regole.get("denti", 2))]

func _suona(evento: String, tono: float) -> void:
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", evento, tono)

## Il quadrante intero, in un disegno solo.
func _disegna() -> void:
	var centro := _centro_quadrante()
	var tremore := Vector2.ZERO
	if _tremore > 0.0 and not reduced_motion:
		tremore = Vector2(sin(_tremore * 46.0) * 5.0 * _tremore, 0.0)
	centro += tremore

	var accento := Color("f4cf69")
	var freddo := Color("6be7d6")

	# **Denti e tempo devono parlare due lingue diverse.** Alla prima stesura erano
	# due archi ciano concentrici e a colpo d'occhio sembravano una corona sola:
	# il bambino non sapeva quale delle due lo stesse rincorrendo. Adesso i denti
	# sono segmenti spessi e distanziati, spenti finché non scattano, accesi d'oro
	# dopo; il tempo è un filo sottile, più interno, che cambia colore mentre
	# finisce. Forma diversa, spessore diverso, colore diverso.
	var denti := int(regole.get("denti", 2))
	for indice in range(denti):
		var gap := 0.16
		var da := -PI * 0.5 + TAU * float(indice) / float(denti) + gap
		var a := -PI * 0.5 + TAU * float(indice + 1) / float(denti) - gap
		var fatto := indice < _denti_fatti
		var colore := accento if fatto else Color(0.17, 0.35, 0.40, 0.95)
		var spessore := 13.0 if fatto else 8.0
		if fatto and _scatto > 0.0 and indice == _denti_fatti - 1:
			spessore += 9.0 * (_scatto / DURATA_SCATTO)
		# Il binario spento sotto il dente: fa vedere quanti denti mancano anche
		# quando sono tutti da fare.
		_quadrante.draw_arc(centro, RAGGIO_QUADRANTE, da, a, 32,
			Color(0.05, 0.13, 0.16, 0.9), 15.0, true)
		_quadrante.draw_arc(centro, RAGGIO_QUADRANTE, da, a, 32, colore, spessore, true)

	# L'arco del tempo: sottile, più interno, attorno al bersaglio — così si legge
	# senza staccare gli occhi dal numero da fare.
	var quota := clampf(_tempo / maxf(_tempo_massimo, 0.01), 0.0, 1.0)
	var colore_tempo := Color("7ad7ff").lerp(Color("ffb066"), 1.0 - quota)
	_quadrante.draw_arc(centro, RAGGIO_QUADRANTE - 30.0, 0.0, TAU, 64,
		Color(0.06, 0.14, 0.18, 0.75), 3.0, true)
	_quadrante.draw_arc(centro, RAGGIO_QUADRANTE - 30.0, -PI * 0.5,
		-PI * 0.5 + TAU * quota, 72, Color(colore_tempo, 0.95), 4.5, true)

	# Il pozzo centrale: alone morbido dietro il numero da fare.
	# La sfumatura del pozzo: otto passi sottili invece di quattro grossi. Con
	# quattro si vedevano i gradini, e un alone a scalini su un fondo scuro si
	# legge come un difetto di resa.
	if not high_contrast:
		for passo in range(8):
			var raggio := 44.0 + float(passo) * 5.5
			_quadrante.draw_circle(centro, raggio, Color(freddo, 0.028))
	# Il pozzo batte quando resta meno di un terzo del tempo. È l'urgenza detta
	# senza colorare di rosso il numero che il bambino sta guardando.
	var urgenza := 1.0 - clampf(quota / 0.34, 0.0, 1.0)
	var battito := 0.0
	if urgenza > 0.0 and not reduced_motion:
		battito = sin(float(Time.get_ticks_msec()) * 0.012) * 3.0 * urgenza
	_quadrante.draw_circle(centro, 44.0 + battito, Color(0.03, 0.09, 0.12, 0.94))
	_quadrante.draw_arc(centro, 44.0 + battito, 0.0, TAU, 48,
		Color(accento, 0.75 + urgenza * 0.25), 2.5 + urgenza * 1.5, true)

	# Le tessere.
	var tessere: Array = _dente.get("tessere", [])
	for indice in tessere.size():
		var punto := _posizione_tessera(indice, tessere.size()) + tremore
		var spenta := _spente.has(indice)
		var riempimento := Color(0.05, 0.12, 0.15, 0.45) if spenta 			else Color(0.09, 0.20, 0.25, 0.98)
		var bordo := Color(freddo, 0.22) if spenta else Color(freddo, 0.95)
		if high_contrast and not spenta:
			riempimento = Color(0.02, 0.07, 0.10, 1.0)
			bordo = Color("ffffff")
		# Un'ombra sotto ogni tessera: senza, gli esagoni sembrano incollati sul
		# fondo e il quadrante perde profondità proprio dove si guarda di più.
		_quadrante.draw_circle(punto + Vector2(0, 5.0), RAGGIO_TESSERA * 0.92,
			Color(0.0, 0.02, 0.03, 0.30))
		if not high_contrast and not spenta:
			_quadrante.draw_circle(punto, RAGGIO_TESSERA + 8.0, Color(freddo, 0.07))
		_quadrante.draw_colored_polygon(_esagono(punto, RAGGIO_TESSERA), riempimento)
		var contorno := _esagono(punto, RAGGIO_TESSERA)
		contorno.append(contorno[0])
		_quadrante.draw_polyline(contorno, bordo, 2.0, true)

	# Il lampo dello scatto: un anello che si allarga e svanisce.
	if _scatto > 0.0 and not reduced_motion:
		var t := 1.0 - (_scatto / DURATA_SCATTO)
		_quadrante.draw_arc(centro, 52.0 + t * 120.0, 0.0, TAU, 64,
			Color(accento, 0.55 * (1.0 - t)), 4.0, true)

func _esagono(centro: Vector2, raggio: float) -> PackedVector2Array:
	var punti := PackedVector2Array()
	for indice in range(6):
		var angolo := TAU * float(indice) / 6.0 - PI / 6.0
		punti.append(centro + Vector2(cos(angolo), sin(angolo)) * raggio)
	return punti
