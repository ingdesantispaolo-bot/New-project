class_name ProfilePanel
extends Control

## **Chi sta giocando** — e il codice per ritrovare la propria partita altrove.
##
## Tre schermate sole, perché chi le usa ha dieci anni:
##   ELENCO  → le caselle dei giocatori, con il livello di ciascuno;
##   NOME    → una riga di testo per creare o rinominare;
##   CODICE  → il codice di ripristino e i due pulsanti del cloud.
##
## La regola che governa tutto il pannello: **niente si perde senza che qualcuno
## l'abbia chiesto**. Scaricare dal cloud sostituisce una partita, quindi non
## avviene mai da solo e mai prima di aver mostrato che cosa sta per arrivare —
## nome e livello del salvataggio remoto. Vedi `cloud_save.gd`, regola 2.

signal chosen(id: String)

const VISTA_ELENCO := "elenco"
const VISTA_NOME := "nome"
const VISTA_CODICE := "codice"

const ALTEZZA_TOCCO := 48   # bersaglio minimo per un dito su tablet

var _vista := VISTA_ELENCO
var _colonna: VBoxContainer
var _cloud: CloudSave
var _campo: LineEdit
var _messaggio: Label
## Il testo dell'ultimo messaggio, tenuto FUORI dall'etichetta: ogni ridisegno
## ricostruisce i nodi da zero, e senza questa copia l'esito di un'operazione
## sparirebbe proprio nel momento in cui il pannello si aggiorna per mostrarlo.
var _messaggio_testo := ""

## Profilo su cui agiscono NOME e CODICE.
var _id_in_lavorazione := ""
## Vero se la schermata NOME sta creando invece di rinominare.
var _sto_creando := false
## Salvataggio scaricato in attesa di conferma: finché è qui, non ha toccato
## niente. È la forma tecnica della regola «niente si perde senza che qualcuno
## l'abbia chiesto».
var _in_attesa_di_conferma: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloud = CloudSave.new()
	_cloud.name = "CloudSave"
	add_child(_cloud)
	_cloud.finished.connect(_on_cloud)

	var velo := ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.01, 0.04, 0.05, 0.88)
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var pannello := PanelContainer.new()
	pannello.custom_minimum_size = Vector2(400, 0)
	pannello.add_theme_stylebox_override("panel", _stile_pannello())
	centro.add_child(pannello)

	var margine := MarginContainer.new()
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 24)
	pannello.add_child(margine)

	_colonna = VBoxContainer.new()
	_colonna.add_theme_constant_override("separation", 10)
	margine.add_child(_colonna)

	PlayerProfiles.bootstrap()
	_disegna()

# ---------------------------------------------------------------- disegno

func _disegna() -> void:
	for figlio in _colonna.get_children():
		_colonna.remove_child(figlio)
		figlio.queue_free()
	match _vista:
		VISTA_NOME:
			_disegna_nome()
		VISTA_CODICE:
			_disegna_codice()
		_:
			_disegna_elenco()

func _disegna_elenco() -> void:
	_colonna.add_child(_titolo("CHI GIOCA?"))
	var attivo := PlayerProfiles.active_id()
	for p in PlayerProfiles.all():
		var profilo: Dictionary = p
		var id := str(profilo.get("id", ""))
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 8)

		var scelta := Button.new()
		scelta.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		scelta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scelta.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Il livello accanto al nome: è così che un bambino riconosce la propria
		# casella anche se il fratello gli ha messo un nome simile.
		scelta.text = "%s   ·   livello %d" % [str(profilo.get("name", "")), _livello_di(id)]
		if id == attivo:
			scelta.text = "▸ " + scelta.text
		scelta.add_theme_font_size_override("font_size", 17)
		scelta.pressed.connect(_scegli.bind(id))
		riga.add_child(scelta)

		var rinomina := Button.new()
		rinomina.text = "✎"
		rinomina.tooltip_text = "Cambia nome"
		rinomina.custom_minimum_size = Vector2(ALTEZZA_TOCCO, ALTEZZA_TOCCO)
		rinomina.pressed.connect(_apri_nome.bind(id, false))
		riga.add_child(rinomina)

		var codice := Button.new()
		codice.text = "☁"
		codice.tooltip_text = "Codice di ripristino"
		codice.custom_minimum_size = Vector2(ALTEZZA_TOCCO, ALTEZZA_TOCCO)
		codice.pressed.connect(_apri_codice.bind(id))
		riga.add_child(codice)

		_colonna.add_child(riga)

	if PlayerProfiles.count() < PlayerProfiles.MAX_PROFILES:
		var nuovo := Button.new()
		nuovo.text = "+  NUOVO GIOCATORE"
		nuovo.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		nuovo.pressed.connect(_apri_nome.bind("", true))
		_colonna.add_child(nuovo)
	else:
		# Onesto sul perché non si può aggiungere, invece di un pulsante spento.
		_colonna.add_child(_nota(
			"Le caselle sono %d, tutte piene. Per riusarne una, cambiale nome con ✎: la partita che c'è dentro resta." % PlayerProfiles.MAX_PROFILES))

	_colonna.add_child(_chiudi("GIOCA"))

func _disegna_nome() -> void:
	_colonna.add_child(_titolo("NUOVO GIOCATORE" if _sto_creando else "CAMBIA NOME"))
	_campo = LineEdit.new()
	_campo.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	_campo.max_length = PlayerProfiles.NAME_MAX_CHARS
	_campo.placeholder_text = "Come ti chiami?"
	if not _sto_creando:
		_campo.text = str(PlayerProfiles.find(_id_in_lavorazione).get("name", ""))
	_campo.text_submitted.connect(func(_t): _conferma_nome())
	_colonna.add_child(_campo)
	_campo.grab_focus()

	if not _sto_creando:
		_colonna.add_child(_nota("Cambiare nome non tocca la partita: resta tutta lì."))

	var conferma := Button.new()
	conferma.text = "CONFERMA"
	conferma.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	conferma.pressed.connect(_conferma_nome)
	_colonna.add_child(conferma)
	_colonna.add_child(_indietro())

func _disegna_codice() -> void:
	_colonna.add_child(_titolo("CODICE DI RIPRISTINO"))
	var codice := PlayerProfiles.code_of(_id_in_lavorazione)

	_colonna.add_child(_nota(
		"Il codice serve per ritrovare questa partita su un altro tablet. Scrivilo su un foglio: senza, la partita vive solo qui."))

	if codice.is_empty():
		_colonna.add_child(_nota("Questa partita non ha ancora un codice."))
		var crea := Button.new()
		crea.text = "CREA IL CODICE"
		crea.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		crea.pressed.connect(_crea_codice)
		_colonna.add_child(crea)
	else:
		var mostra := Label.new()
		mostra.text = codice
		mostra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mostra.add_theme_font_size_override("font_size", 34)
		mostra.add_theme_color_override("font_color", Color("8ff6d2"))
		_colonna.add_child(mostra)

		var copia := Button.new()
		copia.text = "COPIA IL CODICE"
		copia.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		copia.pressed.connect(func():
			DisplayServer.clipboard_set(codice)
			_dico("Codice copiato."))
		_colonna.add_child(copia)

		var salva := Button.new()
		salva.text = "SALVA ADESSO IN CLOUD"
		salva.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		salva.pressed.connect(_salva_in_cloud)
		_colonna.add_child(salva)

	var separatore := HSeparator.new()
	_colonna.add_child(separatore)
	_colonna.add_child(_nota("Hai già un codice da un altro tablet?"))

	_campo = LineEdit.new()
	_campo.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	_campo.max_length = 9
	_campo.placeholder_text = "ABCD-1234"
	_colonna.add_child(_campo)

	var ripristina := Button.new()
	ripristina.text = "RIPRISTINA"
	ripristina.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	ripristina.pressed.connect(_chiedi_ripristino)
	_colonna.add_child(ripristina)

	if not _in_attesa_di_conferma.is_empty():
		_colonna.add_child(_conferma_sostituzione())

	_messaggio = Label.new()
	_messaggio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messaggio.add_theme_font_size_override("font_size", 13)
	_messaggio.add_theme_color_override("font_color", Color("ffd75e"))
	_messaggio.text = _messaggio_testo
	_colonna.add_child(_messaggio)

	_colonna.add_child(_indietro())

## Il momento pericoloso: sta per sparire una partita. Il bambino deve vedere
## COSA arriva e COSA se ne va prima di decidere — non un «sei sicuro?» generico.
func _conferma_sostituzione() -> Control:
	var scatola := VBoxContainer.new()
	scatola.add_theme_constant_override("separation", 6)

	var meta: Dictionary = _in_attesa_di_conferma.get("meta", {})
	var dati: Dictionary = _in_attesa_di_conferma.get("dati", {})
	var nome_remoto := str(meta.get("nome", ""))
	var quando := int(meta.get("salvatoIl", 0))

	var testo := "Dal cloud arriva: %s, livello %d%s.\nSu questo tablet c'è: %s, livello %d.\nLa partita di questo tablet sparisce." % [
		nome_remoto if not nome_remoto.is_empty() else "una partita",
		int(dati.get("level", 1)),
		"" if quando <= 0 else ", salvata il %s" % _data(quando),
		str(PlayerProfiles.find(_id_in_lavorazione).get("name", "")),
		_livello_di(_id_in_lavorazione),
	]
	var avviso := Label.new()
	avviso.text = testo
	avviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	avviso.add_theme_font_size_override("font_size", 14)
	avviso.add_theme_color_override("font_color", Color("ffb3a8"))
	scatola.add_child(avviso)

	var si := Button.new()
	si.text = "SOSTITUISCI"
	si.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	si.pressed.connect(_applica_ripristino)
	scatola.add_child(si)

	var no := Button.new()
	no.text = "LASCIA COM'È"
	no.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	no.pressed.connect(func():
		_in_attesa_di_conferma = {}
		_disegna())
	scatola.add_child(no)
	return scatola

# ---------------------------------------------------------------- azioni

func _scegli(id: String) -> void:
	PlayerProfiles.set_active(id)
	PlayerProfiles.touch(id)
	_disegna()

func _apri_nome(id: String, creando: bool) -> void:
	_id_in_lavorazione = id
	_sto_creando = creando
	_vista = VISTA_NOME
	_disegna()

func _apri_codice(id: String) -> void:
	_id_in_lavorazione = id
	_in_attesa_di_conferma = {}
	_messaggio_testo = ""
	_vista = VISTA_CODICE
	_disegna()

func _conferma_nome() -> void:
	var testo := _campo.text if is_instance_valid(_campo) else ""
	if _sto_creando:
		var nuovo := PlayerProfiles.create(testo)
		if not nuovo.is_empty():
			PlayerProfiles.set_active(str(nuovo["id"]))
	else:
		PlayerProfiles.rename(_id_in_lavorazione, testo)
	_vista = VISTA_ELENCO
	_disegna()

func _crea_codice() -> void:
	if _cloud.occupato():
		return
	_dico("Cerco un codice libero…")
	_cloud.riserva_codice()

func _salva_in_cloud() -> void:
	if _cloud.occupato():
		return
	var codice := PlayerProfiles.code_of(_id_in_lavorazione)
	if codice.is_empty():
		return
	_dico("Salvo in cloud…")
	_cloud.carica(codice, _dati_di(_id_in_lavorazione),
		str(PlayerProfiles.find(_id_in_lavorazione).get("name", "")))

func _chiedi_ripristino() -> void:
	if _cloud.occupato():
		return
	var codice := _campo.text.to_upper().strip_edges() if is_instance_valid(_campo) else ""
	if not PlayerProfiles.is_valid_code(codice):
		_dico(CloudSave.messaggio_errore(400, "scarica"))
		return
	_dico("Cerco la partita…")
	_cloud.scarica(codice)

## Qui, e solo qui, un salvataggio viene sostituito.
func _applica_ripristino() -> void:
	var dati: Dictionary = _in_attesa_di_conferma.get("dati", {})
	var codice := str(_in_attesa_di_conferma.get("codice", ""))
	if dati.is_empty():
		return
	var save := GameSaveManager.new(PlayerProfiles.save_path_of(_id_in_lavorazione))
	# Passa dalla migrazione come qualunque salvataggio letto da disco: quello in
	# cloud può essere stato scritto da una versione precedente del gioco.
	save.data = save.migrate_legacy_save(dati)
	save.save()
	# Il codice diventa quello ripristinato: da adesso questa casella e quel
	# codice sono la stessa partita. Se il codice è già di un'altra casella
	# locale, `set_code` rifiuta — due caselle sullo stesso codice si
	# sovrascriverebbero a vicenda.
	if not PlayerProfiles.set_code(_id_in_lavorazione, codice):
		_dico("Partita ripristinata. Il codice però è già usato da un'altra casella su questo tablet, quindi resta legato a quella.")
	else:
		_dico("Fatto: la partita è tornata.")
	_in_attesa_di_conferma = {}
	_disegna()

func _on_cloud(esito: Dictionary) -> void:
	if not bool(esito.get("ok", false)):
		_dico(str(esito.get("errore", "")))
		return
	match str(esito.get("azione", "")):
		"riserva":
			var codice := str(esito.get("codice", ""))
			if PlayerProfiles.set_code(_id_in_lavorazione, codice):
				# Il codice si assegna e la partita parte subito: un codice
				# scritto su un foglio che non contiene niente è peggio di
				# nessun codice.
				_cloud.carica(codice, _dati_di(_id_in_lavorazione),
					str(PlayerProfiles.find(_id_in_lavorazione).get("name", "")))
				_disegna()
				_dico("Codice creato. Scrivilo su un foglio.")
			else:
				_dico("Non riesco ad assegnare il codice. Riprova.")
		"carica":
			_dico("Partita salvata in cloud.")
		"scarica":
			_in_attesa_di_conferma = esito
			_disegna()

# ---------------------------------------------------------------- utilità

func _dati_di(id: String) -> Dictionary:
	var save := GameSaveManager.new(PlayerProfiles.save_path_of(id))
	save.load_save()
	return save.data

func _livello_di(id: String) -> int:
	var save := GameSaveManager.new(PlayerProfiles.save_path_of(id))
	save.load_save()
	return save.level()

func _data(unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return "%02d/%02d/%d" % [int(d["day"]), int(d["month"]), int(d["year"])]

func _dico(testo: String) -> void:
	_messaggio_testo = testo
	if is_instance_valid(_messaggio):
		_messaggio.text = testo

func _titolo(testo: String) -> Label:
	var l := Label.new()
	l.text = testo
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color("f7fbff"))
	return l

func _nota(testo: String) -> Label:
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color("9fb7bb"))
	return l

func _indietro() -> Button:
	var b := Button.new()
	b.text = "INDIETRO"
	b.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	b.pressed.connect(func():
		_vista = VISTA_ELENCO
		_in_attesa_di_conferma = {}
		_disegna())
	return b

func _chiudi(testo: String) -> Button:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO + 8)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func():
		var id := PlayerProfiles.active_id()
		PlayerProfiles.touch(id)
		chosen.emit(id))
	return b

func _stile_pannello() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.015, 0.075, 0.095, 0.98)
	s.border_color = Color(0.42, 0.91, 0.84, 0.9)
	s.set_border_width_all(2)
	s.set_corner_radius_all(18)
	return s
