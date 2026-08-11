class_name ShelfMinigamePanel
extends Control

## **Lo scaffale che non si vede**: il minigioco di Corinna. (9 agosto 2026)
##
## Corinna crede che «l'ordine giusto è quello che si vede», e per questo mette
## le parole in fila dalla più corta alla più lunga: è l'unico ordine che si può
## controllare a occhio.
##
## Il gioco le presenta **già ordinate per lunghezza** — l'ordine di Corinna, in
## bella vista — e chiede di rimetterle sugli scaffali. Chi segue la lunghezza
## sbaglia, perché la lunghezza non dice niente sulla funzione: «re» e «va» sono
## lunghe uguali e vanno su scaffali diversi. È l'esca, ed è tutto il gioco.
##
## **Nessun cronometro, e non è una dimenticanza.** È l'altra famiglia rispetto
## al mucchio di Tobia: lì la fretta era il punto, qui sarebbe il difetto —
## mettere fretta a chi deve accorgersi di una regola invisibile misura l'ansia,
## non l'idea. Il gioco finisce quando le parole finiscono, o quando gli errori
## concessi si esauriscono.
##
## **Perché gli errori concessi non scendono mai a zero.** Sbagliare è il modo in
## cui si scopre che la lunghezza non funziona: una prova in cui il primo tocco
## decide tutto non si gioca, si subisce. Ogni errore mostra la parola tornare al
## suo posto, che è l'informazione che serve.

signal risolto(vinto: bool, giuste: int, totale: int)

var _scheda: Dictionary = {}
var _parole: Array = []            # [{testo, scaffale}]
var _indice := 0
var _giuste := 0
var _errori := 0
var _errori_max := 3
var _attivo := false

var _parola: Label
var _stato: Label
var _pulsanti: Array = []

func avvia(scheda: Dictionary, _reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var parametri: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(parametri.get("errori", 3))
	var quante := int(parametri.get("parole", 8))
	var tutte: Array = Array(_scheda.get("parole", []))
	# **Ordinate per lunghezza**: è l'ordine di Corinna, ed è l'esca. Presentarle
	# mescolate toglierebbe al gioco la sua unica bugia, che è quella che il
	# bambino deve smascherare.
	tutte.sort_custom(func(a, b): return str(a[0]).length() < str(b[0]).length())
	_parole = []
	for voce in tutte.slice(0, mini(quante, tutte.size())):
		_parole.append({"testo": str(voce[0]), "scaffale": int(voce[1])})
	_indice = 0
	_giuste = 0
	_errori = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_mostra()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "ShelfVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.03, 0.05, 0.09, 0.94)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var colonna := VBoxContainer.new()
	colonna.name = "ShelfColumn"
	colonna.custom_minimum_size = Vector2(520, 0)
	colonna.add_theme_constant_override("separation", 14)
	centro.add_child(colonna)

	var titolo := Label.new()
	titolo.name = "ShelfTitle"
	titolo.text = str(_scheda.get("titolo", "Lo scaffale"))
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	colonna.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "ShelfBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("e7fffb"))
	colonna.add_child(consegna)

	_parola = Label.new()
	_parola.name = "ShelfWord"
	_parola.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parola.add_theme_font_size_override("font_size", 40)
	_parola.add_theme_color_override("font_color", Color("8ff6d2"))
	colonna.add_child(_parola)

	var riga := HBoxContainer.new()
	riga.name = "ShelfRow"
	riga.add_theme_constant_override("separation", 12)
	colonna.add_child(riga)
	var scaffali: Array = Array(_scheda.get("scaffali", ["A", "B"]))
	for i in scaffali.size():
		var b := Button.new()
		b.name = "Shelf_%d" % i
		b.text = str(scaffali[i])
		b.custom_minimum_size = Vector2(240, 84)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_scegli.bind(i))
		riga.add_child(b)
		_pulsanti.append(b)

	_stato = Label.new()
	_stato.name = "ShelfStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 15)
	_stato.add_theme_color_override("font_color", Color("aee9e4"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "ShelfLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 46)
	lascia.pressed.connect(func():
		if _attivo:
			_attivo = false
			risolto.emit(false, _giuste, _parole.size()))
	colonna.add_child(lascia)

func _mostra() -> void:
	if _indice >= _parole.size():
		_attivo = false
		risolto.emit(true, _giuste, _parole.size())
		return
	if is_instance_valid(_parola):
		_parola.text = str(Dictionary(_parole[_indice])["testo"])
	_aggiorna_stato("")

func _scegli(scaffale: int) -> void:
	if not _attivo or _indice >= _parole.size():
		return
	var voce: Dictionary = _parole[_indice]
	if int(voce["scaffale"]) == scaffale:
		_giuste += 1
		_indice += 1
		_mostra()
		return
	_errori += 1
	if _errori > _errori_max:
		_attivo = false
		risolto.emit(false, _giuste, _parole.size())
		return
	# La parola resta: sbagliare non la fa sparire, la rimette davanti. È così
	# che si scopre che la lunghezza non c'entra — riprovandoci sulla stessa.
	_aggiorna_stato("Non è il suo scaffale. Guarda che cosa FA la parola, non quanto è lunga.")

func _aggiorna_stato(messaggio: String) -> void:
	if not is_instance_valid(_stato):
		return
	var coda := "Sistemate %d su %d · errori %d/%d" % [
		_giuste, _parole.size(), _errori, _errori_max]
	_stato.text = "%s\n%s" % [messaggio, coda] if messaggio != "" else coda
