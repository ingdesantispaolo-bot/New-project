class_name RhythmCountBoard
extends Control

## Il forno di Ersilia rende visibile la filastrocca: ogni pagnotta occupa un
## battito sulla stessa linea e i sette semi sul dorso mostrano il salto senza
## trasformarlo in una spiegazione scritta. Numeri, ritmo e oggetti restano tre
## rappresentazioni dello stesso pattern.

var _sequenza: Array = []
var _inseriti: Array = []
var _selezionato := -1
var _esito := 0
var _fase := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(650, 238)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(sequenza: Array, inseriti: Array, reduced_motion: bool) -> void:
	_sequenza = sequenza.duplicate()
	_inseriti = inseriti.duplicate()
	_selezionato = -1
	_esito = 0
	_reduced_motion = reduced_motion
	queue_redraw()

func aggiorna_inseriti(inseriti: Array) -> void:
	_inseriti = inseriti.duplicate()
	_esito = 0
	queue_redraw()

func evidenzia(indice: int) -> void:
	_selezionato = indice
	queue_redraw()

func mostra_esito(corretto: bool) -> void:
	_esito = 1 if corretto else -1
	queue_redraw()

func _process(delta: float) -> void:
	_fase += delta * (0.18 if _reduced_motion else 0.8)
	queue_redraw()

func _draw() -> void:
	if size.x < 320 or _sequenza.is_empty():
		return
	draw_style_box(_stile(Color("25170f"), Color("b77b43"), 18, 2), Rect2(2, 2, size.x - 4, size.y - 4))
	# Mattoni del forno e bocca luminosa: la sequenza vive in un luogo, non in
	# una riga di quiz sospesa.
	for r in 4:
		for c in 9:
			var x := 13.0 + float(c) * (size.x - 26.0) / 9.0 + (28.0 if r % 2 else 0.0)
			var y := 12.0 + float(r) * 30.0
			draw_rect(Rect2(x, y, 58, 24), Color("7d4930", 0.22), false, 1.0)
	var bagliore := 0.04 if _reduced_motion else 0.06 + 0.025 * sin(_fase * 2.2)
	draw_circle(Vector2(size.x * 0.5, 132), 106, Color("ffb54c", bagliore))
	draw_arc(Vector2(size.x * 0.5, 153), 88, PI, TAU, 30, Color("d29355", 0.55), 8)

	var n := _sequenza.size()
	var passo := (size.x - 96.0) / float(maxi(1, n - 1))
	var y := 151.0
	draw_line(Vector2(48, y + 41), Vector2(size.x - 48, y + 41), Color("d7a35f", 0.62), 5, true)
	for i in n:
		var x := 48.0 + float(i) * passo
		var valore := int(_sequenza[i])
		var visibile := i < 2 or i - 2 < _inseriti.size()
		var valore_mostrato := valore if i < 2 else int(_inseriti[i - 2]) if visibile else -1
		_disegna_pagnotta(Vector2(x, y), valore_mostrato, i == _selezionato, _esito)
		if i < n - 1:
			# Sette semi fra una pagnotta e l'altra: la regolarità si può vedere
			# prima di saperla nominare.
			for seme in 7:
				var sx := x + (float(seme) + 1.0) * passo / 8.0
				draw_circle(Vector2(sx, y + 42), 2.2, Color("f4c96d", 0.76))

func _disegna_pagnotta(centro: Vector2, valore: int, selezionata: bool, esito: int) -> void:
	var bordo := Color("f0c06d")
	if selezionata:
		bordo = Color("fff1a3")
	if esito == 1 and selezionata:
		bordo = Color("83efad")
	elif esito == -1 and selezionata:
		bordo = Color("ff8185")
	var area := Rect2(centro - Vector2(39, 27), Vector2(78, 54))
	draw_style_box(_stile(Color("c77a39"), bordo, 24, 3), area)
	for taglio in [-18.0, 0.0, 18.0]:
		draw_line(centro + Vector2(taglio - 6, -15), centro + Vector2(taglio + 1, -5), Color("f4c982", 0.9), 3, true)
	var testo := str(valore) if valore >= 0 else "?"
	var font := ThemeDB.fallback_font
	var misura := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 21)
	draw_string(font, centro + Vector2(-misura.x * 0.5, 16), testo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("3b2317"))

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
