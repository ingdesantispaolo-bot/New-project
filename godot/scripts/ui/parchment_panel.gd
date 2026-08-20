class_name ParchmentPanel
extends Control

## **La pergamena dei Dodici**, letta come si legge un documento.
##
## Nasce da un difetto che questo progetto ha già commesso una volta: il
## briefing dei mondi finiva nella riga di feedback dell'HUD, cioè nella stessa
## riga dei costi d'energia e degli avvisi di sistema, e veniva sostituito dal
## primo messaggio successivo. Un paragrafo che merita di essere letto, in quella
## posizione, non viene letto.
##
## La pergamena è il testo più denso che il gioco consegni fuori da una lezione —
## è l'altro lato della storia, la voce di chi c'era quattrocento anni prima — e
## sarebbe finita nello stesso posto. Qui ha lo spazio e il tempo che chiede.
##
## Si chiude e basta: una pergamena è un documento, non una decisione. Non c'è
## niente da scegliere e nessuna conseguenza da spiegare.

signal chiusa

const ALTEZZA_TOCCO := 52

var livello := 1
var trovate := 0
var totali := 24
var high_contrast := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Più scuro della soglia del mondo: qui si legge un documento, e lo sfondo
	# deve sparire invece di accompagnare.
	velo.color = Color(0.02, 0.015, 0.035, 0.95)
	add_child(velo)

	var margine := MarginContainer.new()
	margine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 26)
	add_child(margine)

	var centro := CenterContainer.new()
	margine.add_child(centro)

	var pannello := PanelContainer.new()
	pannello.custom_minimum_size = Vector2(420, 0)
	var stile := SurfaceStyles.parchment(high_contrast)
	# Carta vecchia, non vetro: è l'unico pannello del gioco che non è
	# un'interfaccia della nave ma un oggetto trovato.
	pannello.add_theme_stylebox_override("panel", stile)
	centro.add_child(pannello)

	var interno := MarginContainer.new()
	for lato in ["left", "top", "right", "bottom"]:
		interno.add_theme_constant_override("margin_%s" % lato, 26)
	pannello.add_child(interno)

	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 14)
	interno.add_child(colonna)

	var occhiello := Label.new()
	occhiello.name = "ParchmentCount"
	occhiello.text = "PERGAMENA %d DI %d" % [trovate, totali]
	occhiello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	occhiello.add_theme_font_size_override("font_size", 12)
	# Ocra su carta scura era leggibile; su carta chiara sta a 1,8:1. Questi due
	# secondari sono rimasti indietro quando la superficie è cambiata, e li ha
	# presi `tavole_guard_audit`: adesso 5,8:1 sulla texture e 5,5:1 sul ripiego.
	occhiello.add_theme_color_override("font_color", Color.BLACK if high_contrast else Color("6b5427"))
	colonna.add_child(occhiello)

	var scheda := ParchmentCatalog.per_world(livello)

	var autore := Label.new()
	autore.name = "ParchmentAuthor"
	autore.text = str(scheda.get("autore", ""))
	autore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	autore.add_theme_font_size_override("font_size", 20)
	autore.add_theme_color_override("font_color", Color.BLACK if high_contrast else Color("392814"))
	colonna.add_child(autore)

	var riga := HSeparator.new()
	colonna.add_child(riga)

	var testo := Label.new()
	testo.name = "ParchmentText"
	testo.text = "«%s»" % str(scheda.get("testo", ""))
	testo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	testo.add_theme_font_size_override("font_size", 17)
	testo.add_theme_color_override("font_color", Color.BLACK if high_contrast else Color("24180d"))
	colonna.add_child(testo)

	var nota := Label.new()
	# Dice a che cosa serve quello che ha appena letto, senza spiegargli la
	# storia: le pergamene sono l'altro lato, e il bambino deve poter fare da sé
	# il collegamento con quello che NORA gli racconta.
	nota.text = "Scritta dai Dodici, quattrocento anni prima che tu arrivassi."
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.add_theme_font_size_override("font_size", 12)
	nota.add_theme_color_override("font_color", Color.BLACK if high_contrast else Color("6b5427"))
	colonna.add_child(nota)

	var chiudi := Button.new()
	chiudi.name = "CloseButton"
	chiudi.text = "RIPONI"
	chiudi.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	chiudi.add_theme_font_size_override("font_size", 18)
	chiudi.pressed.connect(func(): chiusa.emit())
	colonna.add_child(chiudi)
	chiudi.grab_focus()
