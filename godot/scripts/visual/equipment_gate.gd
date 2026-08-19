class_name EquipmentGate
extends Node2D

## Segnaletica e barriera fisica per deviazioni opzionali legate agli strumenti.
##
## **Una chiave che hai è una chiave che hai.** (19 agosto 2026)
##
## Fino al 18 agosto il varco guardava lo strumento **equipaggiato**, e con due
## attrezzi in tutto la cosa reggeva a stento: davanti a un rovo si tornava in
## bottega a cambiare arnese. Con cinque strumenti ([[FieldTools]]) quella non è
## più una meccanica, è un pedaggio — e non è nemmeno il contratto giusto: in un
## gioco fatto di chiavi, una chiave non si equipaggia, si **ha**.
##
## Quindi il varco riceve l'elenco degli strumenti posseduti. Lo slot equipaggiato
## resta, ma decide solo **quale attrezzo Eli porta addosso** (la torcia accende
## la sua luce, la livrea cambia): nessuna porta ne dipende più.
##
## Le due specie di ostacolo, dichiarate dal catalogo (`FieldTools.blocca`):
##
##   - **bloccano**: falce, leva, soffietto. C'è una collisione, e senza
##     l'attrezzo non ci si passa;
##   - **rivelano**: torcia e lente. Non fermano il passo, rendono illeggibile —
##     ed è una sensazione diversa che meritava una forma diversa.

var required_tool := ""
var strumenti: Array = []
var blocker: StaticBody2D
var label: Label
## La tinta dell'ostacolo, decisa una volta sola in `configure`.
##
## Nasceva da `RewardCatalog.find()` a ogni chiamata — cioè una scansione lineare
## di settanta voci dentro `_draw`, che gira a ogni ridisegno di ogni varco della
## mappa. Un colore che non cambia mai non si ricalcola.
var _tinta := Color("ffc76b")

## `posseduti` è l'elenco degli strumenti che il giocatore ha. Accetta anche una
## stringa singola per i chiamanti storici: un attrezzo solo è una lista di uno.
func configure(required: String, posseduti = []) -> void:
	required_tool = required
	strumenti = _lista(posseduti)
	_tinta = _calcola_tinta()
	add_to_group("equipment_gate")
	if FieldTools.blocca(required_tool):
		_build_blocker()
	_build_label()
	_apply_state()
	queue_redraw()

func set_strumenti(posseduti) -> void:
	strumenti = _lista(posseduti)
	_apply_state()
	queue_redraw()

## Compatibilità con chi passava un solo strumento equipaggiato. Resta perché il
## contratto vecchio è ancora leggibile in giro, e perché una lista di uno è
## esattamente ciò che quel contratto significava.
func set_equipped_tool(value: String) -> void:
	set_strumenti(value)

func _lista(posseduti) -> Array:
	if posseduti is Array:
		return (posseduti as Array).duplicate()
	var uno := str(posseduti)
	return [uno] if uno != "" else []

func is_open() -> bool:
	return required_tool == "" or strumenti.has(required_tool)

## La barriera fisica: dieci cerchi in anello. La forma è la stessa per tutti gli
## ostacoli che bloccano — cambia il disegno, non la collisione — perché il
## giocatore deve poter prevedere dove si ferma senza studiare ogni attrezzo.
func _build_blocker() -> void:
	blocker = StaticBody2D.new()
	# Il nome era «TallGrassBlocker» finché l'unico ostacolo fisico era l'erba.
	# Adesso lo condividono falce, leva e soffietto, e un nome che nomina l'erba
	# davanti a una lastra di pietra sarebbe una bugia lasciata nell'albero.
	blocker.name = "GateBlocker"
	for index in range(10):
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		shape.position = Vector2.RIGHT.rotated(TAU * float(index) / 10.0) * 50.0
		blocker.add_child(shape)
	add_child(blocker)

func _build_label() -> void:
	label = Label.new()
	label.name = "EquipmentRequirement"
	label.position = Vector2(-58, 48)
	label.custom_minimum_size.x = 116
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_color", _tinta)
	add_child(label)

## Il colore dell'ostacolo. Viene dal catalogo delle ricompense, così l'attrezzo
## in bottega e la porta nel mondo sono della stessa tinta senza che nessuno
## debba ricordarsi di tenerle allineate. Si legge una volta, alla costruzione.
func _calcola_tinta() -> Color:
	var rgb := int(RewardCatalog.find(required_tool).get("color", 0xffc76b))
	return Color(
		float((rgb >> 16) & 0xff) / 255.0,
		float((rgb >> 8) & 0xff) / 255.0,
		float(rgb & 0xff) / 255.0)

func _apply_state() -> void:
	var open := is_open()
	if is_instance_valid(blocker):
		for child in blocker.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", open)
	if is_instance_valid(label):
		# Aperto, la targhetta smette di chiedere e dice che è fatta. Chiusa,
		# **nomina l'attrezzo**: «SERVE QUALCOSA» manda a indovinare, e con cinque
		# strumenti indovinare è un lavoro.
		label.text = "PASSAGGIO APERTO" if open else "SERVE %s" % _parola_chiave()
		label.modulate.a = 0.58 if open else 1.0

func _parola_chiave() -> String:
	match required_tool:
		FieldTools.TORCIA: return "TORCIA"
		FieldTools.FALCE: return "FALCE"
		FieldTools.LEVA: return "LEVA"
		FieldTools.LENTE: return "LENTE"
		FieldTools.SOFFIETTO: return "SOFFIETTO"
	return "UNO STRUMENTO"

func _draw() -> void:
	var open := is_open()
	var tinta := _tinta
	match required_tool:
		FieldTools.TORCIA:
			_disegna_oscurita(open, tinta)
		FieldTools.FALCE:
			_disegna_erba(open)
		FieldTools.LEVA:
			_disegna_lastra(open, tinta)
		FieldTools.LENTE:
			_disegna_iscrizione(open, tinta)
		FieldTools.SOFFIETTO:
			_disegna_silenzio(open, tinta)

## **Oscurità.** Non ferma il passo: toglie la vista. Aperta, il velo si assottiglia.
func _disegna_oscurita(open: bool, tinta: Color) -> void:
	draw_circle(Vector2.ZERO, 74.0, Color(0.025, 0.035, 0.075, 0.16 if open else 0.72))
	draw_arc(Vector2.ZERO, 64.0, 0.0, TAU, 48, Color(tinta, 0.72), 3.0, true)
	for index in range(6):
		var point := Vector2.RIGHT.rotated(TAU * float(index) / 6.0) * 55.0
		draw_circle(point, 3.0, Color(tinta, 0.86 if open else 0.38))

## **Erba alta.** I fili si abbassano quando la falce c'è.
func _disegna_erba(open: bool) -> void:
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		var radius := 49.0 + sin(float(index) * 2.17) * 6.0
		var base := Vector2.RIGHT.rotated(angle) * radius
		var height := 7.0 if open else 25.0 + float(index % 4) * 3.0
		var color := Color(0.45, 0.72, 0.28, 0.38 if open else 0.95)
		draw_line(base, base + Vector2(0, -height), color, 4.0, true)

## **Lastra sigillata.** Una pietra squadrata con la fenditura al centro: aperta,
## si sposta di lato e mostra il buio sotto. È l'unico ostacolo che, una volta
## superato, *resta visibile come superato* invece di sparire — una lastra
## scostata è la prova che di lì si è passati.
func _disegna_lastra(open: bool, tinta: Color) -> void:
	var scostamento := 16.0 if open else 0.0
	if open:
		draw_rect(Rect2(-46, -34, 92, 68), Color(0.02, 0.04, 0.06, 0.9), true)
	var pietra := PackedVector2Array([
		Vector2(-46 + scostamento, -34), Vector2(46 + scostamento, -30),
		Vector2(42 + scostamento, 34), Vector2(-42 + scostamento, 30),
	])
	draw_colored_polygon(pietra, Color(0.34, 0.36, 0.40, 0.55 if open else 0.98))
	draw_polyline(pietra + PackedVector2Array([pietra[0]]), Color(tinta, 0.7 if open else 1.0), 3.0, true)
	if not open:
		# La fenditura: il punto in cui la leva entra. Si vede da lontano ed è
		# l'unica indicazione di *come* si apre.
		draw_line(Vector2(-40, 2), Vector2(40, 6), Color(0.06, 0.07, 0.09, 0.92), 5.0, true)

## **Iscrizione illeggibile.** Una targa con i segni ridotti a graffi. Con la
## lente i graffi diventano righe nette: non si apre niente, si *capisce*.
func _disegna_iscrizione(open: bool, tinta: Color) -> void:
	draw_rect(Rect2(-44, -30, 88, 60), Color(0.16, 0.17, 0.2, 0.92), true)
	draw_rect(Rect2(-44, -30, 88, 60), Color(tinta, 0.8), false, 3.0, true)
	for riga in range(4):
		var y := -18.0 + float(riga) * 12.0
		if open:
			draw_line(Vector2(-34, y), Vector2(30 - float(riga % 2) * 10.0, y),
				Color(tinta, 0.95), 3.0, true)
			continue
		# Chiusa: frammenti staccati, come una scritta di cui restano i pezzi.
		for pezzo in range(3):
			var x := -34.0 + float(pezzo) * 24.0 + sin(float(riga * 3 + pezzo)) * 4.0
			draw_line(Vector2(x, y), Vector2(x + 9.0, y), Color(tinta, 0.34), 2.5, true)

## **Banco di Silenzio denso.** Una massa opaca che respinge. Col soffietto si
## dirada e restano solo le volute ai bordi.
func _disegna_silenzio(open: bool, tinta: Color) -> void:
	var opacita := 0.18 if open else 0.86
	for strato in range(3):
		var raggio := 58.0 - float(strato) * 13.0
		draw_circle(Vector2(0, float(strato) * 4.0 - 4.0), raggio,
			Color(0.58, 0.60, 0.66, opacita * (0.5 + float(strato) * 0.25)))
	for voluta in range(7):
		var angolo := TAU * float(voluta) / 7.0
		var da := Vector2.RIGHT.rotated(angolo) * 46.0
		var a := Vector2.RIGHT.rotated(angolo + 0.5) * (62.0 if open else 54.0)
		draw_line(da, a, Color(tinta, 0.75 if open else 0.45), 3.0, true)
