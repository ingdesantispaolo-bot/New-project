class_name LandmarkTavolaPanel
extends Control

## **Quello che si vede avvicinandosi al grande landmark del mondo.**
## (5 settembre 2026) Vedi [[LandmarkTavolaCatalog]] per il contenuto e il
## perché di questa scelta.
##
## Stessa forma del riquadro di NORA in `exercise_player.gd`, corretta oggi
## stesso su un difetto vero — «HO CAPITO» finiva sotto il bordo perché stava in
## fondo a una colonna scorrevole dentro un `PanelContainer`, che si adatta al
## contenuto e cresce oltre i propri ancoraggi. Qui il pulsante nasce già fuori
## dallo scorrimento, ancorato al fondo del riquadro: non c'è una versione di
## questo pannello che possa ripetere quell'errore.

signal chiusa

const NORA_FIGURA := preload("res://scripts/game/nora_figura.gd")
## Spazio riservato al pulsante che chiude, fuori da ogni scorrimento.
const ALTEZZA_CHIUSURA := 56.0

var _pulsante: Button

func apri(cosa: String, scoperta: String, tipo: String, dati: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var scrim := ColorRect.new()
	scrim.color = Color(0.01, 0.03, 0.04, 0.94)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	# Un `Panel`, non un `PanelContainer`: e' ancorato, non cresce col
	# contenuto. Vedi il commento in cima sul difetto che questa scelta evita.
	var carta := Panel.new()
	carta.name = "LandmarkTavolaCard"
	carta.anchor_left = 0.08
	carta.anchor_top = 0.06
	carta.anchor_right = 0.92
	carta.anchor_bottom = 0.94
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color("06201d", 0.97)
	stile.border_color = Color("6be7d6", 0.55)
	stile.border_width_left = 2
	stile.border_width_top = 2
	stile.border_width_right = 2
	stile.border_width_bottom = 2
	stile.corner_radius_top_left = 18
	stile.corner_radius_top_right = 18
	stile.corner_radius_bottom_left = 18
	stile.corner_radius_bottom_right = 18
	carta.add_theme_stylebox_override("panel", stile)
	add_child(carta)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carta.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20.0
	scroll.offset_right = -20.0
	scroll.offset_top = 20.0
	scroll.offset_bottom = -(ALTEZZA_CHIUSURA + 20.0)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "TROVATO ESPLORANDO"
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", Color("6be7d6"))
	box.add_child(eyebrow)

	var testo_cosa := Label.new()
	testo_cosa.text = cosa
	testo_cosa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	testo_cosa.add_theme_font_size_override("font_size", 17)
	testo_cosa.add_theme_color_override("font_color", Color("eafffa"))
	box.add_child(testo_cosa)

	if tipo != "":
		var figura := NORA_FIGURA.new()
		figura.mostra(tipo, dati)
		figura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(figura)

	var testo_scoperta := Label.new()
	testo_scoperta.text = scoperta
	testo_scoperta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	testo_scoperta.add_theme_font_size_override("font_size", 15)
	testo_scoperta.add_theme_color_override("font_color", Color("f6c85f"))
	box.add_child(testo_scoperta)

	_pulsante = Button.new()
	_pulsante.name = "LandmarkTavolaCloseButton"
	_pulsante.text = "HO VISTO"
	_pulsante.custom_minimum_size = Vector2(0, 48)
	_pulsante.add_theme_font_size_override("font_size", 16)
	_pulsante.pressed.connect(_chiudi)
	carta.add_child(_pulsante)
	_pulsante.anchor_left = 0.0
	_pulsante.anchor_right = 1.0
	_pulsante.anchor_top = 1.0
	_pulsante.anchor_bottom = 1.0
	_pulsante.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pulsante.offset_left = 20.0
	_pulsante.offset_right = -20.0
	_pulsante.offset_top = -(ALTEZZA_CHIUSURA - 4.0)
	_pulsante.offset_bottom = -12.0
	_pulsante.call_deferred("grab_focus")

func _chiudi() -> void:
	chiusa.emit()
