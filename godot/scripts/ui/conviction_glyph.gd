class_name ConvictionGlyph
extends Control

## Segno unico per la convinzione dei residenti.
##
## Intatto e' un nodo chiuso: l'idea che il personaggio non riesce ancora a
## mettere in discussione. Spezzato conserva la stessa silhouette, ma le due
## meta' si separano e lasciano passare una scintilla. Nessuna lettera e nessun
## simbolo culturale: deve funzionare uguale in matematica, lingue e scienze.

var spezzato := false
var colore := Color("f4cf69")

func _ready() -> void:
	custom_minimum_size = Vector2(46, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func imposta_spezzato(valore: bool) -> void:
	if spezzato == valore:
		return
	spezzato = valore
	queue_redraw()

func _draw() -> void:
	var centro := size * 0.5
	var spostamento := 3.5 if spezzato else 0.0
	var sinistra := centro + Vector2(-spostamento, 0)
	var destra := centro + Vector2(spostamento, 0)
	draw_circle(centro, 20.0, Color(colore, 0.16))
	draw_arc(sinistra, 13.0, PI * 0.48, PI * 1.52, 18, colore, 3.2, true)
	draw_arc(destra, 13.0, -PI * 0.52, PI * 0.52, 18, colore, 3.2, true)
	if spezzato:
		var lampo := PackedVector2Array([
			centro + Vector2(-1, -13), centro + Vector2(4, -4),
			centro + Vector2(-3, 2), centro + Vector2(2, 13),
		])
		draw_polyline(lampo, Color("e7fffb"), 2.2, true)
		draw_circle(centro, 2.8, Color("8ff6d2"))
