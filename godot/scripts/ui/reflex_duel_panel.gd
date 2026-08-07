class_name ReflexDuelPanel
extends Control

## **Il varco**: il duello di riflessi contro una sacca di Silenzio.
##
## Un cursore corre avanti e indietro su una pista; un tratto luminoso e' il
## varco. Si tocca COLPISCI quando il cursore ci passa dentro. Servono N colpi
## a segno prima di esaurire gli errori concessi — e quanto e' largo il varco,
## quanto corre il cursore e quanti errori si possono fare li decide
## [[ReflexDuel]] dal grado di Eli e dal grado della sacca.
##
## **Perche' una barra e non una mira.** Un bersaglio da centrare col dito
## premia chi ha uno schermo grande e una mano ferma; una barra a una dimensione
## chiede solo il momento giusto, e si gioca uguale su un tablet appoggiato al
## tavolo e su uno tenuto in mano. E' lo stesso motivo per cui il gioco non ha
## mai chiesto precisione di puntamento.
##
## **Accessibilita'.** Con `reduced_motion` il cursore va piu' piano e il varco
## e' piu' largo: chi ha bisogno di meno movimento non deve per questo perdere
## il premio. Il pannello si puo' sempre abbandonare, e abbandonare non costa
## niente — l'unica cosa peggiore di un minigioco difficile e' un minigioco
## difficile da cui non si esce.

signal risolto(vinto: bool)

const ALTEZZA_PISTA := 74.0

var regole: Dictionary = {}
var nome_sacca := "Sbiadito"
var reduced_motion := false

var _cursore := 0.0
var _direzione := 1.0
var _centro := 0.0
var _colpi := 0
var _errori := 0
var _attivo := false
var _rng := RandomNumberGenerator.new()

var _pista: Control
var _titolo: Label
var _stato: Label
var _pulsante: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	set_process(true)

func avvia(regole_duello: Dictionary, nome: String, ridotto: bool) -> void:
	regole = regole_duello.duplicate(true)
	nome_sacca = nome
	reduced_motion = ridotto
	if reduced_motion:
		# Piu' lento e piu' largo: la stessa prova, con piu' tempo per leggerla.
		regole["velocita"] = float(regole.get("velocita", 250.0)) * 0.62
		regole["semiVarco"] = float(regole.get("semiVarco", 44.0)) * 1.35
	_rng.seed = hash("%s-%d" % [nome, Time.get_ticks_msec()])
	_colpi = 0
	_errori = 0
	_cursore = 0.0
	_direzione = 1.0
	_attivo = true
	_nuovo_centro()
	_aggiorna_stato()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "DuelVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.02, 0.05, 0.08, 0.86)
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var colonna := VBoxContainer.new()
	colonna.name = "DuelColumn"
	colonna.custom_minimum_size = Vector2(ReflexDuel.PISTA + 40.0, 0)
	colonna.add_theme_constant_override("separation", 14)
	centro.add_child(colonna)

	_titolo = Label.new()
	_titolo.name = "DuelTitle"
	_titolo.text = "IL VARCO"
	_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titolo.add_theme_font_size_override("font_size", 26)
	_titolo.add_theme_color_override("font_color", Color("f4cf69"))
	colonna.add_child(_titolo)

	_stato = Label.new()
	_stato.name = "DuelStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_font_size_override("font_size", 14)
	_stato.add_theme_color_override("font_color", Color("aee9e4"))
	colonna.add_child(_stato)

	_pista = Control.new()
	_pista.name = "DuelTrack"
	_pista.custom_minimum_size = Vector2(ReflexDuel.PISTA, ALTEZZA_PISTA)
	_pista.draw.connect(_disegna_pista)
	colonna.add_child(_pista)

	_pulsante = Button.new()
	_pulsante.name = "DuelStrikeButton"
	_pulsante.text = "COLPISCI"
	_pulsante.custom_minimum_size = Vector2(0, 62)
	_pulsante.add_theme_font_size_override("font_size", 22)
	_pulsante.pressed.connect(_colpisci)
	colonna.add_child(_pulsante)

	var fuga := Button.new()
	fuga.name = "DuelLeaveButton"
	fuga.text = "LASCIA PERDERE"
	fuga.custom_minimum_size = Vector2(0, 46)
	fuga.add_theme_font_size_override("font_size", 14)
	# Andarsene non costa niente e non e' una sconfitta: la sacca resta dov'e'.
	fuga.pressed.connect(func():
		if not _attivo:
			return
		_attivo = false
		risolto.emit(false))
	colonna.add_child(fuga)

func _process(delta: float) -> void:
	if not _attivo:
		return
	var meta := float(regole.get("pista", ReflexDuel.PISTA))
	_cursore += _direzione * float(regole.get("velocita", 250.0)) * delta
	if _cursore >= meta:
		_cursore = meta
		_direzione = -1.0
	elif _cursore <= 0.0:
		_cursore = 0.0
		_direzione = 1.0
	if is_instance_valid(_pista):
		_pista.queue_redraw()

func _nuovo_centro() -> void:
	var meta := float(regole.get("pista", ReflexDuel.PISTA))
	var semi := float(regole.get("semiVarco", 44.0))
	# Il varco non nasce mai a ridosso di un bordo: li' il cursore inverte e ci
	# resta dentro un istante di piu', che sarebbe un colpo regalato.
	_centro = _rng.randf_range(semi + 20.0, meta - semi - 20.0)

func _colpisci() -> void:
	if not _attivo:
		return
	var semi := float(regole.get("semiVarco", 44.0))
	if ReflexDuel.colpito(_cursore, _centro, semi):
		_colpi += 1
		if _colpi >= int(regole.get("colpi", 3)):
			_attivo = false
			_stato.text = "La sacca si scioglie."
			risolto.emit(true)
			return
		_nuovo_centro()
	else:
		_errori += 1
		if _errori > int(regole.get("errori", 2)):
			_attivo = false
			_stato.text = "Il varco si è chiuso."
			risolto.emit(false)
			return
	_aggiorna_stato()

func _aggiorna_stato() -> void:
	if not is_instance_valid(_stato):
		return
	_stato.text = "%s · colpi %d/%d · errori %d/%d" % [
		nome_sacca, _colpi, int(regole.get("colpi", 3)),
		_errori, int(regole.get("errori", 2))]

func _disegna_pista() -> void:
	var larghezza := float(regole.get("pista", ReflexDuel.PISTA))
	var semi := float(regole.get("semiVarco", 44.0))
	var meta_altezza := ALTEZZA_PISTA * 0.5
	_pista.draw_rect(Rect2(0, meta_altezza - 12.0, larghezza, 24.0),
		Color(1, 1, 1, 0.10))
	_pista.draw_rect(
		Rect2(_centro - semi, meta_altezza - 16.0, semi * 2.0, 32.0),
		Color("6be7d6", 0.55))
	_pista.draw_rect(Rect2(_cursore - 3.0, meta_altezza - 26.0, 6.0, 52.0),
		Color("f4cf69"))

func _unhandled_input(event: InputEvent) -> void:
	if not _attivo:
		return
	# La barra spaziatrice fa quello che fa il pulsante: su desktop il duello si
	# gioca con una mano sola, e su tablet il pulsante resta l'unica via.
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_colpisci()
		get_viewport().set_input_as_handled()
