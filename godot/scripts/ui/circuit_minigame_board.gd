class_name CircuitMinigameBoard
extends Control

## Rete riconfigurabile del Circuito mutante.
##
## I dati autoriali non contengono coordinate: questo renderer costruisce tre
## corsie e permuta i collegamenti a ogni schema. La corrente illumina soltanto
## il tratto raggiunto; agli incroci i fili non diventano nodi. Per procedere si
## deve quindi leggere il flusso, non ricordare dov'era il pulsante precedente.

signal nodo_scelto(corretto: bool)
signal schema_acceso

const BOARD_SIZE := Vector2(540, 260)
const RIGHE_Y := [64.0, 130.0, 196.0]
const COLOR_FILO := Color("45647a", 0.62)
const COLOR_CORRENTE := Color("62f2d4")
const COLOR_ORO := Color("f4cf69")
const COLOR_ERRORE := Color("ff8295")

var _round := 0
var _passaggi := 3
var _mappature: Array = []
var _righe_corrette: Array[int] = []
var _riga_iniziale := 0
var _riga_lampada := 0
var _passaggio_attivo := 0
var _pulsanti: Array[Button] = []
var _nodo_errato := Vector2i(-1, -1)
var _fase := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

func configura(indice_round: int, passaggi: int, reduced_motion: bool) -> void:
	_round = indice_round
	_passaggi = clampi(passaggi, 2, 6)
	_reduced_motion = reduced_motion
	_passaggio_attivo = 0
	_nodo_errato = Vector2i(-1, -1)
	for pulsante in _pulsanti:
		if is_instance_valid(pulsante):
			# Esce dall'albero subito: `queue_free` da solo aspetterebbe fine frame e
			# i nuovi interruttori riceverebbero nomi automatici proprio durante la
			# riconfigurazione.
			remove_child(pulsante)
			pulsante.queue_free()
	_pulsanti.clear()
	_costruisci_rete()
	_costruisci_interruttori()
	set_process(not _reduced_motion)
	queue_redraw()

func passaggio_attivo() -> int:
	return _passaggio_attivo

func numero_interruttori() -> int:
	return _pulsanti.size()

func riga_corretta(passaggio: int) -> int:
	return _righe_corrette[passaggio] if passaggio >= 0 and passaggio < _righe_corrette.size() else -1

func _costruisci_rete() -> void:
	_mappature.clear()
	_righe_corrette.clear()
	_riga_iniziale = posmod(_round * 2 + 1, 3)
	var riga := _riga_iniziale
	var permutazioni := [
		[0, 1, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0], [1, 0, 2], [0, 2, 1],
	]
	for passaggio in _passaggi:
		var indice := posmod(_round * 3 + passaggio * 2 + 1, permutazioni.size())
		var mappa: Array = Array(permutazioni[indice]).duplicate()
		_mappature.append(mappa)
		riga = int(mappa[riga])
		_righe_corrette.append(riga)
	_riga_lampada = riga

func _costruisci_interruttori() -> void:
	for passaggio in _passaggi:
		for riga in 3:
			var pulsante := Button.new()
			pulsante.name = "CircuitSwitch_%d_%d" % [passaggio, riga]
			pulsante.text = "◊"
			pulsante.tooltip_text = "Interruttore %d, fila %d" % [passaggio + 1, riga + 1]
			pulsante.accessibility_name = pulsante.tooltip_text
			pulsante.custom_minimum_size = Vector2(48, 48)
			pulsante.size = Vector2(48, 48)
			pulsante.position = _posizione_nodo(passaggio, riga) - pulsante.size * 0.5
			pulsante.focus_mode = Control.FOCUS_ALL
			pulsante.add_theme_font_size_override("font_size", 28)
			pulsante.add_theme_color_override("font_color", Color("b8d7df"))
			pulsante.add_theme_color_override("font_hover_color", Color.WHITE)
			pulsante.add_theme_color_override("font_pressed_color", COLOR_ORO)
			pulsante.add_theme_stylebox_override("normal", _stile_nodo(Color("152d3b"), Color("50758a"), 2))
			pulsante.add_theme_stylebox_override("hover", _stile_nodo(Color("1d4650"), COLOR_CORRENTE, 3))
			pulsante.add_theme_stylebox_override("pressed", _stile_nodo(Color("375638"), COLOR_ORO, 3))
			pulsante.add_theme_stylebox_override("focus", _stile_nodo(Color("203d49"), COLOR_ORO, 3))
			pulsante.pressed.connect(_premuto.bind(passaggio, riga, pulsante))
			add_child(pulsante)
			_pulsanti.append(pulsante)

func _premuto(passaggio: int, riga: int, pulsante: Button) -> void:
	if _passaggio_attivo >= _passaggi:
		return
	if passaggio != _passaggio_attivo or riga != riga_corretta(_passaggio_attivo):
		_nodo_errato = Vector2i(passaggio, riga)
		pulsante.add_theme_stylebox_override("normal", _stile_nodo(Color("51283a"), COLOR_ERRORE, 3))
		nodo_scelto.emit(false)
		queue_redraw()
		var timer := get_tree().create_timer(0.10 if _reduced_motion else 0.38)
		timer.timeout.connect(_ripristina_errore.bind(passaggio, riga, pulsante))
		return
	pulsante.text = "◊"
	pulsante.disabled = true
	pulsante.add_theme_color_override("font_disabled_color", COLOR_ORO)
	pulsante.add_theme_stylebox_override("disabled", _stile_nodo(Color("235548"), COLOR_CORRENTE, 3))
	_passaggio_attivo += 1
	_nodo_errato = Vector2i(-1, -1)
	nodo_scelto.emit(true)
	queue_redraw()
	if _passaggio_attivo >= _passaggi:
		schema_acceso.emit()

func _ripristina_errore(passaggio: int, riga: int, pulsante) -> void:
	if is_instance_valid(pulsante) and not pulsante.disabled:
		pulsante.add_theme_stylebox_override("normal", _stile_nodo(Color("152d3b"), Color("50758a"), 2))
	if _nodo_errato == Vector2i(passaggio, riga):
		_nodo_errato = Vector2i(-1, -1)
		queue_redraw()

func _process(delta: float) -> void:
	_fase = fmod(_fase + delta * 2.4, TAU)
	queue_redraw()

func _draw() -> void:
	draw_style_box(_stile_quadro(), Rect2(Vector2.ZERO, BOARD_SIZE))
	for x in range(28, int(BOARD_SIZE.x), 34):
		for y in range(24, int(BOARD_SIZE.y), 34):
			draw_circle(Vector2(x, y), 1.2, Color("6f9ca8", 0.14))

	var x_sorgente := 40.0
	var x_precedente := x_sorgente
	for passaggio in _passaggi:
		var x_nodo := _x_nodo(passaggio)
		for riga_sorgente in 3:
			var riga_destino := int(Array(_mappature[passaggio])[riga_sorgente])
			var acceso := _tratto_corretto(passaggio, riga_sorgente) and passaggio <= _passaggio_attivo
			_disegna_filo(
				Vector2(x_precedente, RIGHE_Y[riga_sorgente]),
				Vector2(x_nodo, RIGHE_Y[riga_destino]), acceso)
		x_precedente = x_nodo

	var x_lampada := BOARD_SIZE.x - 40.0
	for riga in 3:
		var acceso_finale := _passaggio_attivo >= _passaggi and riga == _riga_lampada
		_disegna_filo(Vector2(x_precedente, RIGHE_Y[riga]), Vector2(x_lampada, RIGHE_Y[riga]), acceso_finale)

	_disegna_batteria(Vector2(x_sorgente, RIGHE_Y[_riga_iniziale]))
	_disegna_lampada(Vector2(x_lampada, RIGHE_Y[_riga_lampada]), _passaggio_attivo >= _passaggi)
	if _nodo_errato.x >= 0:
		draw_arc(_posizione_nodo(_nodo_errato.x, _nodo_errato.y), 31.0, 0, TAU, 28, COLOR_ERRORE, 3.0, true)

func _tratto_corretto(passaggio: int, riga_sorgente: int) -> bool:
	var attesa := _riga_iniziale if passaggio == 0 else _righe_corrette[passaggio - 1]
	return riga_sorgente == attesa

func _disegna_filo(da: Vector2, a: Vector2, acceso: bool) -> void:
	var meta_x := (da.x + a.x) * 0.5
	var punti := PackedVector2Array([da, Vector2(meta_x, da.y), Vector2(meta_x, a.y), a])
	if acceso:
		draw_polyline(punti, Color(COLOR_CORRENTE, 0.18), 9.0, true)
		draw_polyline(punti, COLOR_CORRENTE, 3.4, true)
		if not _reduced_motion:
			var indice := int(floor((sin(_fase) * 0.5 + 0.5) * float(punti.size() - 1)))
			draw_circle(punti[indice], 4.0, COLOR_ORO)
	else:
		draw_polyline(punti, COLOR_FILO, 2.2, true)

func _disegna_batteria(posizione: Vector2) -> void:
	draw_circle(posizione, 27.0, Color("163b45"))
	draw_arc(posizione, 27.0, 0, TAU, 30, COLOR_CORRENTE, 3.0, true)
	draw_line(posizione + Vector2(-8, -10), posizione + Vector2(-8, 10), COLOR_ORO, 3.0, true)
	draw_line(posizione + Vector2(5, -16), posizione + Vector2(5, 16), COLOR_ORO, 4.0, true)

func _disegna_lampada(posizione: Vector2, accesa: bool) -> void:
	var colore := COLOR_ORO if accesa else Color("69808b")
	if accesa:
		draw_circle(posizione, 35.0, Color(COLOR_ORO, 0.17))
		for i in 8:
			var direzione := Vector2.RIGHT.rotated(float(i) * TAU / 8.0)
			draw_line(posizione + direzione * 24.0, posizione + direzione * 31.0, COLOR_ORO, 2.2, true)
	draw_circle(posizione, 18.0, Color(colore, 0.20))
	draw_arc(posizione, 18.0, PI, TAU, 22, colore, 3.2, true)
	draw_line(posizione + Vector2(-11, 8), posizione + Vector2(11, 8), colore, 3.0, true)
	draw_line(posizione + Vector2(-7, 14), posizione + Vector2(7, 14), colore, 3.0, true)

func _x_nodo(passaggio: int) -> float:
	if _passaggi <= 1:
		return BOARD_SIZE.x * 0.5
	return 120.0 + float(passaggio) * (BOARD_SIZE.x - 240.0) / float(_passaggi - 1)

func _posizione_nodo(passaggio: int, riga: int) -> Vector2:
	return Vector2(_x_nodo(passaggio), RIGHE_Y[riga])

func _stile_nodo(sfondo: Color, bordo: Color, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(26)
	return stile

func _stile_quadro() -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color("081a24", 0.98)
	stile.border_color = Color("397389", 0.74)
	stile.set_border_width_all(2)
	stile.set_corner_radius_all(18)
	return stile
