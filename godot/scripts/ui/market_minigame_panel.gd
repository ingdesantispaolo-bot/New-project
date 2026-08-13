class_name MarketMinigamePanel
extends Control

## **Il mercato delle venti parole**: il minigioco di Vecchio Lino.
##
## Il cliente chiede in inglese; le cassette mostrano **che cosa c'è dentro**, in
## italiano e in cifre. Per servirlo bisogna sapere che `three` sono 3 e che
## `tonight` non è domani: le venti parole di Lino bastano a farsi capire, non a
## capire.
##
## **La cassetta giusta non deve contenere nessuna parola della richiesta**, e non
## è un dettaglio di stile. Nella prima stesura le scelte erano «ONE silver fish
## / THREE silver fish / FIVE silver fish» sotto la richiesta «Three silver fish,
## please»: bastava accoppiare le lettere, e tutte e cinque le richieste si
## servivano **senza sapere una parola d'inglese**. Un gioco così non smentiva la
## convinzione di Lino — gli dava ragione. È lo stesso errore del mucchio di
## Tobia alla prima taratura, e `market_minigame_audit` adesso lo impedisce.

signal risolto(vinto: bool, completati: int, totale: int)

const TURNI := [
	{"richiesta": "Three silver fish, please.", "tipo": "QUANTITÀ", "scelte": ["2 pesci d'argento", "3 pesci d'argento", "5 pesci d'argento"], "giusta": 1},
	{"richiesta": "Fresh fish for tomorrow, please.", "tipo": "TEMPO", "scelte": ["pesce fresco per oggi", "pesce fresco per domani", "pesce fresco per ieri"], "giusta": 1},
	{"richiesta": "I need the small blue net.", "tipo": "QUALITÀ", "scelte": ["rete piccola rossa", "rete grande blu", "rete piccola blu"], "giusta": 2},
	{"richiesta": "Two strong ropes, please.", "tipo": "QUANTITÀ", "scelte": ["1 corda robusta", "2 corde robuste", "4 corde robuste"], "giusta": 1},
	{"richiesta": "Bring a warm coat tonight.", "tipo": "TEMPO", "scelte": ["cappotto caldo adesso", "cappotto caldo stasera", "cappotto caldo domani"], "giusta": 1},
]

var _scheda: Dictionary = {}
var _turni: Array = []
var _indice := 0
var _giuste := 0
var _errori := 0
var _errori_max := 3
var _attivo := false
var _richiesta: Label
var _categoria: Label
var _stato: Label
var _cassette: Array[Button] = []

func avvia(scheda: Dictionary, _reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	var p: Dictionary = _scheda.get("parametri", {})
	_errori_max = int(p.get("errori", 3))
	# **I turni sono il vestito.** La trappola — *richieste quasi uguali, un solo
	# dettaglio decide* — vale per Lino al banco, per Talia al valico e per Elmo
	# davanti alla stessa scena vista da tre punti. Quando la scheda porta i suoi
	# `turni`, questi restano il caso del molo.
	var repertorio: Array = Array(_scheda.get("turni", TURNI))
	if repertorio.is_empty():
		repertorio = TURNI
	_turni = repertorio.slice(0, mini(int(p.get("richieste", 3)), repertorio.size()))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_mostra()

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "MarketVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("13242b", 0.97)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	# Luci del molo: profondità e atmosfera, senza immagine testuale.
	for pos in [Vector2(-340, -230), Vector2(340, 205)]:
		var luce := Panel.new()
		luce.mouse_filter = Control.MOUSE_FILTER_IGNORE
		luce.set_anchors_preset(Control.PRESET_CENTER)
		luce.position = pos
		luce.size = Vector2(330, 330)
		luce.add_theme_stylebox_override("panel", _stile(Color("48b7b3", 0.09), Color.TRANSPARENT, 170, 0))
		add_child(luce)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "MarketCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("243c38"), Color("e5bd68"), 24, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 26)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "MarketColumn"
	colonna.custom_minimum_size = Vector2(650, 0)
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)
	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	colonna.add_child(testata)
	var glifo := ConvictionGlyph.new()
	glifo.name = "MarketConvictionGlyph"
	testata.add_child(glifo)
	var titolo := Label.new()
	titolo.name = "MarketTitle"
	titolo.text = str(_scheda.get("titolo", "Il mercato"))
	titolo.add_theme_font_size_override("font_size", 25)
	titolo.add_theme_color_override("font_color", Color("ffe4a1"))
	testata.add_child(titolo)
	var consegna := Label.new()
	consegna.name = "MarketBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_color_override("font_color", Color("e5fff4"))
	colonna.add_child(consegna)
	_categoria = Label.new()
	_categoria.name = "MarketClue"
	_categoria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_categoria.add_theme_font_size_override("font_size", 14)
	_categoria.add_theme_color_override("font_color", Color("84e3d4"))
	colonna.add_child(_categoria)
	_richiesta = Label.new()
	_richiesta.name = "MarketRequest"
	_richiesta.custom_minimum_size = Vector2(0, 82)
	_richiesta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_richiesta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_richiesta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_richiesta.add_theme_font_size_override("font_size", 23)
	_richiesta.add_theme_color_override("font_color", Color("ffffff"))
	_richiesta.add_theme_stylebox_override("normal", _stile(Color("31504c"), Color("72d8cf"), 16, 2))
	colonna.add_child(_richiesta)
	var banco := HBoxContainer.new()
	banco.name = "MarketStalls"
	banco.alignment = BoxContainer.ALIGNMENT_CENTER
	banco.add_theme_constant_override("separation", 12)
	colonna.add_child(banco)
	for i in 3:
		var cassetta := Button.new()
		cassetta.name = "MarketCrate_%d" % i
		cassetta.custom_minimum_size = Vector2(196, 112)
		cassetta.add_theme_font_size_override("font_size", 17)
		cassetta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cassetta.add_theme_stylebox_override("normal", _stile(Color("68452b"), Color("d6a760"), 14, 2))
		cassetta.add_theme_stylebox_override("hover", _stile(Color("835733"), Color("ffe49b"), 14, 3))
		cassetta.add_theme_stylebox_override("pressed", _stile(Color("2f7768"), Color("8ff6d2"), 14, 3))
		cassetta.pressed.connect(_scegli.bind(i))
		banco.add_child(cassetta)
		_cassette.append(cassetta)
	_stato = Label.new()
	_stato.name = "MarketStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_color_override("font_color", Color("d1f6ed"))
	colonna.add_child(_stato)
	var lascia := Button.new()
	lascia.name = "MarketLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 46)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

func _mostra() -> void:
	if _indice >= _turni.size():
		_chiudi(true)
		return
	var turno: Dictionary = _turni[_indice]
	_richiesta.text = "“%s”" % str(turno["richiesta"])
	_categoria.text = "%s · %s" % [str(_scheda.get("indizio", "UNA PAROLA DECISIVA")), str(turno["tipo"])]
	for i in _cassette.size():
		var simbolo := str(_scheda.get("simboloScelta", "▰"))
		_cassette[i].text = ("%s\n" % simbolo if not simbolo.is_empty() else "") + str(turno["scelte"][i])
		_cassette[i].disabled = false
		# La cassetta segnata in rosso torna di legno a ogni cliente. Senza questo
		# il rosso restava addosso per tutta la partita, e al terzo cliente il
		# banco mostrava un errore che non c'entrava più niente.
		_cassette[i].add_theme_stylebox_override("normal", _stile(Color("68452b"), Color("d6a760"), 14, 2))
	_aggiorna(str(_scheda.get("guida", "Scegli la cassetta che rispetta tutta la richiesta.")))

func _scegli(scelta: int) -> void:
	if not _attivo:
		return
	var turno: Dictionary = _turni[_indice]
	if scelta == int(turno["giusta"]):
		_giuste += 1
		_indice += 1
		_mostra()
		return
	_errori += 1
	_cassette[scelta].add_theme_stylebox_override("normal", _stile(Color("642f38"), Color("ff9ba6"), 14, 3))
	if _errori > _errori_max:
		_chiudi(false)
		return
	_aggiorna(str(_scheda.get("correzione",
		"Quasi: cambia un dettaglio del cliente. Rileggilo e scegli ancora.")))

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	risolto.emit(vinto, _giuste, _turni.size())

func _aggiorna(messaggio: String) -> void:
	if is_instance_valid(_stato):
		_stato.text = "%s  ·  %s %d/%d  ·  errori %d/%d" % [
			messaggio, str(_scheda.get("contatore", "Clienti")), _giuste, _turni.size(), _errori, _errori_max]

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile

func _adatta_verticale(carta: Control) -> void:
	await get_tree().process_frame
	if get_viewport_rect().size.y > get_viewport_rect().size.x and is_instance_valid(carta):
		carta.pivot_offset = carta.size * 0.5
		carta.scale = Vector2(1.55, 1.55)
