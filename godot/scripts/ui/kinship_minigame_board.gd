class_name KinshipMinigameBoard
extends Control

## Albero etimologico vettoriale di Zeno. La parola antica è la radice incisa
## nella pietra; i parenti moderni emergono come foglie illuminate. Le linee
## rendono visibile che gli indizi non sono suggerimenti scollegati ma membri
## della stessa famiglia.

var _antica := "AQUA"
var _parenti: Array = []
var _visibili := 0
var _ipotesi := ""
var _esito := 0 # -1 errore, 0 neutro, 1 corretto
var _fase := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(650, 250)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(antica: String, parenti: Array, reduced_motion: bool) -> void:
	_antica = antica
	_parenti = parenti.duplicate(true)
	_visibili = 0
	_ipotesi = ""
	_esito = 0
	_reduced_motion = reduced_motion
	queue_redraw()

func mostra_parenti(quanti: int) -> void:
	_visibili = clampi(quanti, 0, _parenti.size())
	queue_redraw()

func imposta_ipotesi(testo: String) -> void:
	_ipotesi = testo
	_esito = 0
	queue_redraw()

func mostra_esito(corretto: bool) -> void:
	_esito = 1 if corretto else -1
	queue_redraw()

func _process(delta: float) -> void:
	_fase += delta * (0.18 if _reduced_motion else 0.7)
	queue_redraw()

func _draw() -> void:
	if size.x < 320:
		return
	draw_style_box(_stile(Color("0e1b28"), Color("496f85"), 18, 2), Rect2(2, 2, size.x - 4, size.y - 4))
	# Rovina in ombra: archi e incisioni danno un luogo all'albero senza asset.
	for i in 9:
		var x := 22.0 + float(i) * (size.x - 44.0) / 8.0
		draw_line(Vector2(x, 18), Vector2(x + sin(float(i)) * 7, size.y - 16), Color("7e98a5", 0.07), 2)
	draw_arc(Vector2(size.x * 0.5, size.y + 70), size.x * 0.43, PI + 0.35, TAU - 0.35, 42, Color("6e8e9e", 0.14), 9)

	var radice := Vector2(size.x * 0.5, size.y - 52)
	var foglia_sx := Vector2(size.x * 0.26, 72)
	var foglia_dx := Vector2(size.x * 0.74, 72)
	var nodo := Vector2(size.x * 0.5, 145)
	# Radici sotterranee e tronco centrale.
	for offset in [-1.0, 0.0, 1.0]:
		draw_bezier(radice + Vector2(0, 22), radice + Vector2(offset * 75, 35), radice + Vector2(offset * 120, 45), radice + Vector2(offset * 150, 55), Color("9b774f", 0.48), 4)
	draw_line(radice, nodo, Color("b78a55"), 9, true)
	draw_line(nodo, foglia_sx, Color("b78a55"), 7, true)
	draw_line(nodo, foglia_dx, Color("b78a55"), 7, true)
	draw_circle(nodo, 10, Color("e1b56f"))

	_disegna_tavola(Rect2(radice.x - 88, radice.y - 30, 176, 58), _antica, Color("d6b976"))
	_disegna_foglia(Rect2(foglia_sx.x - 135, foglia_sx.y - 43, 270, 86), 0)
	_disegna_foglia(Rect2(foglia_dx.x - 135, foglia_dx.y - 43, 270, 86), 1)

	# L'ipotesi è una targhetta provvisoria, non una risposta scolpita: può essere
	# cambiata finché la famiglia non la sostiene.
	if _ipotesi != "":
		var colore := Color("82e6d0") if _esito >= 0 else Color("ff8794")
		if _esito == 1:
			colore = Color("8ff0a8")
		var area := Rect2(size.x * 0.5 - 105, 160, 210, 36)
		draw_style_box(_stile(Color("17313a"), colore, 10, 2), area)
		_disegna_testo(area, "IPOTESI: " + _ipotesi.to_upper(), 16, colore)

func _disegna_tavola(area: Rect2, testo: String, colore: Color) -> void:
	draw_style_box(_stile(Color("33383b"), Color("8d9b9c"), 10, 2), area)
	for i in 4:
		draw_line(area.position + Vector2(16 + i * 34, 10), area.position + Vector2(24 + i * 34, area.size.y - 10), Color("eef4e8", 0.06), 2)
	_disegna_testo(area, testo, 26, colore)

func _disegna_foglia(area: Rect2, indice: int) -> void:
	var visibile := indice < _visibili and indice < _parenti.size()
	var pulsazione := 0.03 * sin(_fase * 3.0 + float(indice)) if visibile and not _reduced_motion else 0.0
	var bordo := Color("6ed7c2", 0.88 + pulsazione) if visibile else Color("667985", 0.32)
	var sfondo := Color("163b3d", 0.97) if visibile else Color("15212a", 0.86)
	draw_style_box(_stile(sfondo, bordo, 18, 2), area)
	# Nervature della foglia, visibili anche prima della parola.
	draw_line(Vector2(area.position.x + 16, area.get_center().y), Vector2(area.end.x - 16, area.get_center().y), Color(bordo, 0.42), 2)
	for i in 5:
		var x := area.position.x + 38 + float(i) * 42
		draw_line(Vector2(x, area.get_center().y), Vector2(x + 12, area.position.y + 14), Color(bordo, 0.24), 1.5)
	if not visibile:
		_disegna_testo(area, "PARENTE NELL'OMBRA", 15, Color("718691"))
		return
	var voce: Dictionary = _parenti[indice]
	var sopra := Rect2(area.position.x + 8, area.position.y + 9, area.size.x - 16, 27)
	var sotto := Rect2(area.position.x + 12, area.position.y + 40, area.size.x - 24, 35)
	_disegna_testo(sopra, str(voce.get("parola", "")), 18, Color("a8f3df"))
	_disegna_testo(sotto, str(voce.get("indizio", "")), 12, Color("d8eee7"))

func _disegna_testo(area: Rect2, testo: String, dimensione: int, colore: Color) -> void:
	var font := ThemeDB.fallback_font
	var misura := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, dimensione)
	var x := area.get_center().x - misura.x * 0.5
	var y := area.get_center().y + misura.y * 0.32
	draw_string(font, Vector2(x, y), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, dimensione, colore)

func draw_bezier(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, colore: Color, spessore: float) -> void:
	var punti := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0
		var u := 1.0 - t
		punti.append(u * u * u * a + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * b)
	draw_polyline(punti, colore, spessore, true)

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
