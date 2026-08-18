class_name CycleMinigameStage
extends Control

## Scena vettoriale per l'archetipo del ciclo. Ruggine vede un nastro; Ambra
## vede una staffetta di lanterne e intervalli. La meccanica si trasferisce, il
## materiale resta davvero del personaggio.

var tema := "officina"
var in_coda := 0
var lavorati := 0
var capienza := 24
var automatico := false
var _tempo := 0.0
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(0, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(nuovo_tema: String, reduced_motion: bool) -> void:
	tema = nuovo_tema
	_reduced_motion = reduced_motion
	queue_redraw()

func aggiorna(coda: int, fatti: int, massimo: int, acceso: bool) -> void:
	in_coda = coda
	lavorati = fatti
	capienza = massimo
	automatico = acceso
	queue_redraw()

func _process(delta: float) -> void:
	_tempo += delta
	if automatico and not _reduced_motion:
		queue_redraw()

func _draw() -> void:
	if tema == "musica":
		_disegna_staffetta()
	else:
		_disegna_nastro()

func _disegna_staffetta() -> void:
	var y := size.y * 0.58
	var margine := 44.0
	var quanti := 8
	# Due onde sovrapposte: l'intervallo resta percepibile anche senza audio.
	var onda_a := PackedVector2Array()
	var onda_b := PackedVector2Array()
	for i in 49:
		var x := margine + (size.x - margine * 2.0) * float(i) / 48.0
		var fase := float(i) * 0.55 + _tempo * (4.0 if automatico else 0.0)
		onda_a.append(Vector2(x, y - 26.0 + sin(fase) * 8.0))
		onda_b.append(Vector2(x, y - 26.0 + sin(fase * 0.66 + 1.4) * 5.0))
	draw_polyline(onda_a, Color("84e9df", 0.72), 2.5, true)
	draw_polyline(onda_b, Color("d3a6ff", 0.62), 2.0, true)
	for i in quanti:
		var x := margine + (size.x - margine * 2.0) * float(i) / float(quanti - 1)
		var accesa := i < mini(quanti, lavorati)
		var pulsazione := 1.0
		if automatico and not _reduced_motion and i == posmod(int(_tempo * 8.0), quanti):
			pulsazione = 1.28
		var colore := Color("ffe787") if accesa else Color("536775")
		draw_line(Vector2(x, y + 13), Vector2(x, y + 28), Color("a58259"), 3.0, true)
		draw_circle(Vector2(x, y), 15.0 * pulsazione, Color(colore, 0.16))
		draw_circle(Vector2(x, y), 8.5 * pulsazione, colore)
		draw_arc(Vector2(x, y), 11.0 * pulsazione, PI, TAU, 12, Color("fff4be", 0.72), 2.0, true)
	# Le scintille in attesa restano a sinistra della catena: visive, non testo.
	for i in mini(6, in_coda):
		var p := Vector2(22.0 + float(i % 3) * 8.0, y - 9.0 + float(i / 3) * 15.0)
		draw_circle(p, 3.5, Color("d3a6ff", 0.82))

func _disegna_nastro() -> void:
	var y := size.y * 0.57
	draw_rect(Rect2(30, y - 18, size.x - 60, 38), Color("3a2718"), true)
	draw_line(Vector2(32, y - 18), Vector2(size.x - 32, y - 18), Color("c08a4d"), 3.0)
	for i in 8:
		var x := 52.0 + float(i) * (size.x - 104.0) / 7.0
		draw_circle(Vector2(x, y + 22), 10.0, Color("2a1a0e"))
		draw_circle(Vector2(x, y + 22), 5.0, Color("a87842"))
	for i in mini(10, in_coda):
		var x := 48.0 + float(i) * (size.x - 96.0) / 10.0
		var offset := fmod(_tempo * 34.0, 18.0) if automatico and not _reduced_motion else 0.0
		draw_rect(Rect2(x + offset, y - 11, 18, 18), Color("d7a24d"), true)
		draw_rect(Rect2(x + offset, y - 11, 18, 18), Color("ffe0a1", 0.7), false, 2.0)
