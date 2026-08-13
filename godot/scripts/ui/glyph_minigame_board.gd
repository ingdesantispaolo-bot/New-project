class_name GlyphMinigameBoard
extends Control

## Scriptorium vettoriale di Livia: la parola resta perfettamente copiata sulla
## pergamena, ma radice e desinenza hanno due colori e conducono a due porte di
## funzione. L'inchiostro che si ritira è il tempo, senza cifre da leggere.

var _radice := "ROS"
var _fine := "A"
var _progresso := 1.0
var _selezionata := -1
var _giusta := -1
var _fase := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(640, 248)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(radice: String, fine: String, reduced_motion: bool) -> void:
	_radice = radice
	_fine = fine
	_progresso = 1.0
	_selezionata = -1
	_giusta = -1
	_reduced_motion = reduced_motion
	queue_redraw()

func imposta_progresso(valore: float) -> void:
	_progresso = clampf(valore, 0.0, 1.0)
	queue_redraw()

func mostra_esito(scelta: int, giusta: int) -> void:
	_selezionata = scelta
	_giusta = giusta
	queue_redraw()

func pulisci_esito() -> void:
	_selezionata = -1
	_giusta = -1
	queue_redraw()

func _process(delta: float) -> void:
	_fase += delta * (0.25 if _reduced_motion else 1.0)
	queue_redraw()

func _draw() -> void:
	if size.x < 320:
		return
	draw_style_box(_stile(Color("211932"), Color("8b69b2"), 18, 2), Rect2(2, 2, size.x - 4, size.y - 4))
	# Parete di glifi: segni astratti e non testo, come un fregio vivo.
	for i in 15:
		var x := 20.0 + float(i) * (size.x - 40.0) / 14.0
		var y := 24.0 + sin(float(i) * 1.7) * 5.0
		var alpha := 0.12 + 0.05 * sin(_fase + float(i))
		draw_arc(Vector2(x, y), 7.0, -2.4, 1.1, 8, Color("c29be8", alpha), 2.0)

	_disegna_calamaio(Vector2(size.x * 0.5, 38))
	var y_carta := lerpf(75.0, 110.0, 1.0 - _progresso)
	_disegna_pergamena(Rect2(size.x * 0.5 - 126, y_carta, 252, 66))

	var porta_y := size.y - 67.0
	var porta_w := minf(230.0, size.x * 0.36)
	_disegna_porta(Rect2(46, porta_y, porta_w, 50), 0)
	_disegna_porta(Rect2(size.x - 46 - porta_w, porta_y, porta_w, 50), 1)
	if _selezionata >= 0:
		var destinazione := Vector2(46 + porta_w * 0.5, porta_y) if _selezionata == 0 else Vector2(size.x - 46 - porta_w * 0.5, porta_y)
		var colore := Color("7ef0b0") if _selezionata == _giusta else Color("ff7e8d")
		var partenza := Vector2(size.x * 0.5, y_carta + 67)
		var via := Vector2(lerpf(partenza.x, destinazione.x, 0.5), partenza.y + 16)
		draw_polyline(PackedVector2Array([partenza, via, destinazione]), colore, 5.0, true)
		draw_circle(destinazione, 8.0, colore)

func _disegna_calamaio(centro: Vector2) -> void:
	# Il livello d'inchiostro è il tempo residuo, leggibile senza numeri.
	var corpo := Rect2(centro.x - 33, centro.y - 18, 66, 35)
	draw_style_box(_stile(Color("342247"), Color("d5a8f2"), 9, 2), corpo)
	var pieno := Rect2(corpo.position.x + 5, corpo.end.y - 5 - 25.0 * _progresso, corpo.size.x - 10, 25.0 * _progresso)
	draw_rect(pieno, Color("8a52c7", 0.92), true)
	draw_line(centro + Vector2(18, -12), centro + Vector2(48, -39), Color("f1d7a0"), 5, true)
	draw_colored_polygon(PackedVector2Array([
		centro + Vector2(44, -43), centro + Vector2(54, -50), centro + Vector2(49, -36)
	]), Color("d5ecdf"))

func _disegna_pergamena(area: Rect2) -> void:
	var ombra := Rect2(area.position + Vector2(0, 6), area.size)
	draw_style_box(_stile(Color("09060d", 0.30), Color.TRANSPARENT, 12, 0), ombra)
	draw_style_box(_stile(Color("f1dfb1"), Color("bd8c55"), 12, 2), area)
	# Rulli laterali e cucitura centrale: la parola è davvero un oggetto che
	# attraversa lo scriptorium, non una domanda sospesa.
	for x in [area.position.x + 7, area.end.x - 7]:
		draw_line(Vector2(x, area.position.y + 8), Vector2(x, area.end.y - 8), Color("a87543"), 7, true)
	var font := ThemeDB.fallback_font
	var misura_radice := font.get_string_size(_radice, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
	var misura_fine := font.get_string_size(_fine, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
	var inizio := area.get_center().x - (misura_radice + misura_fine) * 0.5
	var baseline := area.get_center().y + 11
	draw_string(font, Vector2(inizio, baseline), _radice, HORIZONTAL_ALIGNMENT_LEFT, -1, 31, Color("286b72"))
	draw_string(font, Vector2(inizio + misura_radice, baseline), _fine, HORIZONTAL_ALIGNMENT_LEFT, -1, 31, Color("b16a22"))
	# Piccoli segni di copia perfetta: non cambiano fra le due funzioni.
	for i in 4:
		draw_circle(Vector2(area.position.x + 34 + float(i) * 14, area.end.y - 9), 2, Color("805f45", 0.42))

func _disegna_porta(area: Rect2, indice: int) -> void:
	var colore := Color("72d8cf") if indice == 0 else Color("efb663")
	if _giusta == indice:
		colore = Color("7ef0b0")
	elif _selezionata == indice and _giusta != indice:
		colore = Color("ff7e8d")
	draw_style_box(_stile(Color("172a39"), colore, 12, 2), area)
	var c := area.get_center()
	if indice == 0:
		# Freccia che parte dal soggetto: chi agisce.
		draw_circle(c + Vector2(-28, 0), 9, colore)
		draw_line(c + Vector2(-14, 0), c + Vector2(30, 0), colore, 5, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(30, -9), c + Vector2(43, 0), c + Vector2(30, 9)]), colore)
	else:
		# Freccia che arriva al bersaglio: chi riceve.
		draw_line(c + Vector2(-42, 0), c + Vector2(3, 0), colore, 5, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(3, -9), c + Vector2(16, 0), c + Vector2(3, 9)]), colore)
		draw_circle(c + Vector2(34, 0), 9, colore)

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
