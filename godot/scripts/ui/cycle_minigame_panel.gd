class_name CycleMinigamePanel
extends Control

## **Cento giri, tre mosse**: l'archetipo del ciclo. (12 agosto 2026)
##
## **Che cosa c'era di rotto, e perché era rotto nel punto peggiore.** La prima
## stesura non aveva il modo manuale: si sceglievano tre mosse fra sei
## permutazioni possibili, senza un indizio, e si premeva AVVIA. Ruggine crede
## che «i cicli sono per i pigri» e il suo arco dice che *riavvia la macchina a
## mano cento volte al giorno e ne è fiera*: un gioco in cui la mano non esiste
## non può smentirla. Le ripetizioni risparmiate erano perfino un numero
## dichiarato (`_fatti = _ripetizioni`), non una cosa che accadeva.
##
## **Adesso la mano c'è, ed è la prima cosa che si tocca.** Ogni pezzo del nastro
## si lavora con tre gesti in sequenza, e i gesti sono **facili**: il pezzo dice
## sempre in che stato è, quindi non c'è niente da indovinare. Solo che intanto
## il nastro continua a riempirsi, e la mano perde terreno — non per un
## fotogramma di fretta, per aritmetica: si sgombra a 0,74 pezzi al secondo e ne
## arrivano 0,47. `character_minigame_audit` tiene quel margine.
##
## **Il braccio è la scoperta.** Le stesse tre mosse, registrate una volta,
## vengono ripetute da sole finché il nastro è vuoto. Non lo dice la consegna:
## il registratore è lì, con tre caselle vuote, e chi ha appena lavorato a mano
## sa già che cosa scriverci dentro. Scoprirlo è il gioco; riceverlo come
## istruzione sarebbe la stessa azione con dentro zero.
##
## **Non è un pannello di Ruggine, è un archetipo.** Gesti, nome del pezzo e
## cornice arrivano dalla scheda: Ambra ci manda intervalli alle lanterne
## lontane, Numa ci fa attraversare i secoli a una radice. La trappola resta la
## stessa perché la stessa è la convinzione: *quello che si fa a mano non scala*.

signal risolto(vinto: bool, completati: int, totale: int)

const COMANDI_PREDEFINITI := ["PRENDI", "GIRA", "POSA"]
## Quanto rende il braccio, in secondi per pezzo. Non è generosità: il braccio
## deve vincere **visibilmente**, altrimenti il bambino non capisce di aver
## scoperto qualcosa, capisce di essere stato fortunato.
const SECONDI_PER_PEZZO_BRACCIO := 0.25

var _scheda: Dictionary = {}
var _comandi: Array = COMANDI_PREDEFINITI
var _nome_pezzo := "pezzo"
var _in_coda := 0                  # pezzi ancora da lavorare
var _lavorati := 0
var _obiettivo := 0
var _capienza := 24
var _passo_gesto := 0              # a che punto è il pezzo che ho in mano
var _programma: Array[int] = []
var _braccio_acceso := false
var _accumulo := 0.0               # frazione di pezzo che il braccio sta finendo
var _arrivo := 2.2
var _dall_ultimo_arrivo := 0.0
## **Il tetto della mano**, in secondi fra un gesto e il successivo.
##
## Senza questo il gioco si vinceva a mano **a forza di dita**: tre tocchi per
## pezzo a un quarto di secondo l'uno fanno 1,3 pezzi al secondo, più di quanti
## ne arrivino, e la convinzione di Ruggine sarebbe uscita confermata da chi
## picchia veloce. È esattamente l'errore del mucchio di Tobia alla prima
## taratura. Col tetto il ritmo massimo della mano è un numero noto, e l'audit
## ci fa sopra l'aritmetica: la mano non può vincere, per chiunque.
var _cooldown := 0.34
var _dal_ultimo_gesto := 0.0
var _secondi := 30.0
var _attivo := false
var _reduced_motion := false
var _messaggio := ""

var _nastro: Label
var _pezzo_in_mano: Label
var _slot: Label
var _stato: Label
var _cronometro: Label
var _glifo: ConvictionGlyph
var _pulsanti_gesto: Array[Button] = []
var _avvia: Button

func avvia(scheda: Dictionary, reduced_motion: bool) -> void:
	_scheda = scheda.duplicate(true)
	_reduced_motion = reduced_motion
	var parametri: Dictionary = _scheda.get("parametri", {})
	_comandi = Array(_scheda.get("comandi", COMANDI_PREDEFINITI))
	if _comandi.size() != 3:
		_comandi = COMANDI_PREDEFINITI
	_nome_pezzo = str(_scheda.get("pezzo", "pezzo"))
	_obiettivo = int(parametri.get("pezzi", 12))
	_in_coda = _obiettivo
	_capienza = int(parametri.get("capienza", 24))
	_arrivo = float(parametri.get("arrivo", 2.2))
	_cooldown = float(parametri.get("cooldown", 0.34))
	_dal_ultimo_gesto = _cooldown
	_secondi = float(parametri.get("secondi", 30.0))
	if _reduced_motion:
		# Chi ha bisogno di meno fretta non deve per questo perdere la scoperta,
		# che è la parte che conta. Il nastro rallenta insieme al cronometro,
		# altrimenti il regalo sarebbe finto.
		_secondi *= 1.5
		_arrivo *= 1.5
	_lavorati = 0
	_passo_gesto = 0
	_programma = []
	_braccio_acceso = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci()
	_attivo = true
	_aggiorna()
	set_process(true)

func _costruisci() -> void:
	var velo := ColorRect.new()
	velo.name = "CycleVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color("17100b", 0.96)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	for posizione in [Vector2(-340, -220), Vector2(330, 200)]:
		var alone := Panel.new()
		alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alone.set_anchors_preset(Control.PRESET_CENTER)
		alone.position = posizione
		alone.size = Vector2(340, 340)
		alone.add_theme_stylebox_override("panel", _stile(Color("f4cf69", 0.08), Color.TRANSPARENT, 170, 0))
		add_child(alone)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var carta := PanelContainer.new()
	carta.name = "CycleCard"
	carta.add_theme_stylebox_override("panel", _stile(Color("302015", 0.99), Color("f4cf69", 0.8), 22, 2))
	centro.add_child(carta)
	call_deferred("_adatta_verticale", carta)
	var margine := MarginContainer.new()
	for lato in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margine.add_theme_constant_override(lato, 24)
	carta.add_child(margine)
	var colonna := VBoxContainer.new()
	colonna.name = "CycleColumn"
	colonna.custom_minimum_size = Vector2(560, 0)
	colonna.add_theme_constant_override("separation", 10)
	margine.add_child(colonna)

	var testata := HBoxContainer.new()
	testata.alignment = BoxContainer.ALIGNMENT_CENTER
	testata.add_theme_constant_override("separation", 8)
	colonna.add_child(testata)
	_glifo = ConvictionGlyph.new()
	_glifo.name = "CycleConvictionGlyph"
	testata.add_child(_glifo)
	var titolo := Label.new()
	titolo.name = "CycleTitle"
	titolo.text = str(_scheda.get("titolo", "Cento giri, tre mosse"))
	titolo.add_theme_font_size_override("font_size", 24)
	titolo.add_theme_color_override("font_color", Color("f4cf69"))
	testata.add_child(titolo)

	var consegna := Label.new()
	consegna.name = "CycleBrief"
	consegna.text = str(_scheda.get("consegna", ""))
	consegna.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consegna.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consegna.add_theme_font_size_override("font_size", 15)
	consegna.add_theme_color_override("font_color", Color("fff3dd"))
	colonna.add_child(consegna)

	_cronometro = Label.new()
	_cronometro.name = "CycleClock"
	_cronometro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cronometro.add_theme_font_size_override("font_size", 19)
	_cronometro.add_theme_color_override("font_color", Color("ffca78"))
	colonna.add_child(_cronometro)

	_nastro = Label.new()
	_nastro.name = "CycleBelt"
	_nastro.custom_minimum_size = Vector2(0, 58)
	_nastro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nastro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_nastro.add_theme_font_size_override("font_size", 20)
	_nastro.add_theme_color_override("font_color", Color("ffe2aa"))
	_nastro.add_theme_stylebox_override("normal", _stile(Color("3a2718", 0.96), Color("b98b4c", 0.8), 14, 2))
	colonna.add_child(_nastro)

	# **La mano.** Lo stato del pezzo è sempre scritto: il gesto giusto non si
	# indovina, si legge. La difficoltà non deve stare nel capire cosa fare —
	# deve stare nel fatto che farlo, tutte le volte, non basta.
	_pezzo_in_mano = Label.new()
	_pezzo_in_mano.name = "CycleHand"
	_pezzo_in_mano.custom_minimum_size = Vector2(0, 46)
	_pezzo_in_mano.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pezzo_in_mano.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pezzo_in_mano.add_theme_font_size_override("font_size", 17)
	_pezzo_in_mano.add_theme_color_override("font_color", Color("8ff6d2"))
	colonna.add_child(_pezzo_in_mano)

	var comandi := HBoxContainer.new()
	comandi.name = "CycleCommands"
	comandi.alignment = BoxContainer.ALIGNMENT_CENTER
	comandi.add_theme_constant_override("separation", 8)
	colonna.add_child(comandi)
	for i in _comandi.size():
		var b := Button.new()
		b.name = "CycleCommand_%d" % i
		b.text = str(_comandi[i])
		b.custom_minimum_size = Vector2(160, 56)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_stylebox_override("normal", _stile(Color("4a3023", 0.96), Color("b98b4c", 0.86), 14, 2))
		b.add_theme_stylebox_override("hover", _stile(Color("69452c", 0.98), Color("f4cf69", 0.96), 14, 3))
		b.add_theme_stylebox_override("pressed", _stile(Color("2f775f", 0.98), Color("8ff6d2", 0.96), 14, 3))
		b.pressed.connect(_gesto.bind(i))
		comandi.add_child(b)
		_pulsanti_gesto.append(b)

	# **Il registratore.** Tre caselle vuote e nessuna spiegazione: chi ha appena
	# lavorato a mano sa già che cosa scriverci.
	_slot = Label.new()
	_slot.name = "CycleProgram"
	_slot.custom_minimum_size = Vector2(0, 60)
	_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot.add_theme_font_size_override("font_size", 19)
	_slot.add_theme_color_override("font_color", Color("8ff6d2"))
	_slot.add_theme_stylebox_override("normal", _stile(Color("1c332d", 0.96), Color("72d8cf", 0.8), 14, 2))
	colonna.add_child(_slot)

	var riga := HBoxContainer.new()
	riga.alignment = BoxContainer.ALIGNMENT_CENTER
	riga.add_theme_constant_override("separation", 8)
	colonna.add_child(riga)
	var registra := Button.new()
	registra.name = "CycleRecordButton"
	registra.text = "REGISTRA IL GESTO CHE HAI IN MANO"
	registra.custom_minimum_size = Vector2(330, 50)
	registra.pressed.connect(_registra)
	riga.add_child(registra)
	var pulisci := Button.new()
	pulisci.name = "CycleClearButton"
	pulisci.text = "CANCELLA"
	pulisci.custom_minimum_size = Vector2(140, 50)
	pulisci.pressed.connect(func():
		if _attivo and not _braccio_acceso:
			_programma.clear()
			_aggiorna("Caselle vuote."))
	riga.add_child(pulisci)

	_avvia = Button.new()
	_avvia.name = "CycleRunButton"
	_avvia.text = "AVVIA IL BRACCIO"
	_avvia.custom_minimum_size = Vector2(0, 52)
	_avvia.pressed.connect(_esegui)
	colonna.add_child(_avvia)

	_stato = Label.new()
	_stato.name = "CycleStatus"
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.add_theme_color_override("font_color", Color("ffdfa0"))
	colonna.add_child(_stato)

	var lascia := Button.new()
	lascia.name = "CycleLeaveButton"
	lascia.text = "LASCIA PERDERE"
	lascia.custom_minimum_size = Vector2(0, 44)
	lascia.pressed.connect(func(): if _attivo: _chiudi(false))
	colonna.add_child(lascia)

## Un gesto della mano. Vale solo se è quello che il pezzo sta aspettando — e il
## pezzo lo dice, quindi sbagliare non è una punizione, è una svista che costa
## il tempo di riprovare.
func _gesto(comando: int) -> void:
	if not _attivo or _braccio_acceso:
		return
	if _in_coda <= 0:
		return
	if _dal_ultimo_gesto < _cooldown:
		# La mano non è ancora tornata. Nessun rimprovero: il gesto semplicemente
		# non c'è, com'è per una mano vera.
		return
	_dal_ultimo_gesto = 0.0
	if comando != _passo_gesto:
		_aggiorna("Il %s aspetta «%s»." % [_nome_pezzo, str(_comandi[_passo_gesto])])
		return
	_passo_gesto += 1
	if _passo_gesto >= _comandi.size():
		_passo_gesto = 0
		_in_coda -= 1
		_lavorati += 1
		_aggiorna("Uno. E intanto ne arrivano altri.")
		_controlla_fine()
		return
	_aggiorna("")

## Registrare non è scrivere di nuovo la sequenza a memoria: è **mettere nella
## casella il gesto che si sta facendo adesso**. Chi ha lavorato a mano ha già
## il ritmo in mano, e il registratore ne prende una copia.
func _registra() -> void:
	if not _attivo or _braccio_acceso or _programma.size() >= _comandi.size():
		return
	_programma.append(_passo_gesto)
	_aggiorna("Casella %d: «%s»." % [_programma.size(), str(_comandi[_passo_gesto])])

func _esegui() -> void:
	if not _attivo or _braccio_acceso:
		return
	if _programma.size() != _comandi.size():
		_aggiorna("Al braccio mancano delle caselle: ne vuole %d." % _comandi.size())
		return
	var giusto := true
	for i in _programma.size():
		if int(_programma[i]) != i:
			giusto = false
	if not giusto:
		_programma.clear()
		_aggiorna("Il braccio si inceppa: in quest'ordine il %s non passa. Puoi rifarle." % _nome_pezzo)
		return
	_braccio_acceso = true
	_accumulo = 0.0
	for pulsante in _pulsanti_gesto:
		pulsante.disabled = true
	_avvia.disabled = true
	_aggiorna("Il braccio ha preso il giro e continua da solo.")

func _process(delta: float) -> void:
	if not _attivo:
		return
	var passo := delta
	_secondi -= passo
	_dall_ultimo_arrivo += passo
	_dal_ultimo_gesto += passo
	if not _braccio_acceso:
		var pronta := _dal_ultimo_gesto >= _cooldown
		for pulsante in _pulsanti_gesto:
			pulsante.disabled = not pronta
	# **Il nastro non aspetta.** È l'unica ragione per cui la mano perde: non la
	# fretta delle dita, il fatto che il lavoro arriva mentre lo si fa.
	while _dall_ultimo_arrivo >= _arrivo:
		_dall_ultimo_arrivo -= _arrivo
		_in_coda += 1
		if _in_coda >= _capienza:
			_aggiorna("Il nastro ha traboccato.")
			_chiudi(false)
			return
	if _braccio_acceso and _in_coda > 0:
		_accumulo += passo
		while _accumulo >= SECONDI_PER_PEZZO_BRACCIO and _in_coda > 0:
			_accumulo -= SECONDI_PER_PEZZO_BRACCIO
			_in_coda -= 1
			_lavorati += 1
		if _controlla_fine():
			return
	if _secondi <= 0.0:
		_secondi = 0.0
		_aggiorna("Il turno è finito e il nastro è ancora pieno.")
		_chiudi(false)
		return
	_aggiorna("")

func _controlla_fine() -> bool:
	if _in_coda > 0:
		return false
	if is_instance_valid(_glifo):
		_glifo.imposta_spezzato(true)
	_aggiorna("Nastro vuoto.")
	_chiudi(true)
	return true

func _chiudi(vinto: bool) -> void:
	if not _attivo:
		return
	_attivo = false
	set_process(false)
	risolto.emit(vinto, _lavorati, maxi(_obiettivo, _lavorati))

func _aggiorna(messaggio: String = "") -> void:
	if messaggio != "":
		_messaggio = messaggio
	if is_instance_valid(_cronometro):
		_cronometro.text = "%.0f secondi di turno" % maxf(0.0, _secondi)
	if is_instance_valid(_nastro):
		_nastro.text = "NASTRO: %d %s in attesa  ·  capienza %d" % [_in_coda, _nome_pezzo, _capienza]
	if is_instance_valid(_pezzo_in_mano):
		if _braccio_acceso:
			_pezzo_in_mano.text = "Il braccio ripete da solo. Lavorati: %d" % _lavorati
		elif _in_coda <= 0:
			_pezzo_in_mano.text = "Nessun %s in attesa." % _nome_pezzo
		else:
			_pezzo_in_mano.text = "Il %s in mano aspetta: «%s»   (lavorati %d)" % [
				_nome_pezzo, str(_comandi[_passo_gesto]), _lavorati]
	if is_instance_valid(_slot):
		var parole: Array[String] = []
		for comando in _programma:
			parole.append(str(_comandi[comando]))
		while parole.size() < _comandi.size():
			parole.append("▢")
		_slot.text = "IL BRACCIO RIPETE:   " + "   ".join(parole)
	if is_instance_valid(_stato):
		_stato.text = _messaggio

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile

func _adatta_verticale(carta: Control) -> void:
	await get_tree().process_frame
	var viewport_size := get_viewport_rect().size
	if viewport_size.y <= viewport_size.x or not is_instance_valid(carta):
		return
	carta.pivot_offset = carta.size * 0.5
	carta.scale = Vector2(2.0, 2.0)
