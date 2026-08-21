class_name ProgressBoardPanel
extends Control

## **Il registro dei giocatori**: due schede, CASA e GRUPPO.
##
## CASA sono le caselle di questo tablet — nessuna rete, funziona sempre.
## GRUPPO è un codice condiviso fra più tablet: chi ce l'ha vede gli altri.
##
## La scelta di progetto sta tutta nell'ordine in cui si mostrano le cose. La
## classifica che si apre per prima è **la settimana**, che riparte da sé: chi
## ha cominciato un mese dopo può essere primo lunedì. Il livello c'è, ma non è
## la prima cosa che un bambino legge, perché quella classifica non si recupera
## e la lettura di apertura è quella che resta.
##
## Sotto la tabella, le **medaglie**: in che cosa guida ciascuno. Con dodici
## materie è raro che qualcuno non guidi niente — e chi non guida niente non
## compare affatto, invece di leggere «nessuna medaglia».

const ALTEZZA_TOCCO := 48
const SCHEDA_CASA := "casa"
const SCHEDA_GRUPPO := "gruppo"

signal closed

var _scheda := SCHEDA_CASA
var _asse := "settimana"
var _colonna: VBoxContainer
var _cloud: CloudSave
var _campo: LineEdit
var _messaggio_testo := ""
var _messaggio: Label
## Schede arrivate dal gruppo. Vuoto finché non si legge: la tabella del gruppo
## non inventa righe quando la rete non risponde.
var _schede_gruppo: Array = []
## Invii ancora da fare prima di rileggere il registro. Il Worker regge una
## richiesta alla volta, quindi le schede dei giocatori di casa partono in fila.
var _coda_invii: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloud = CloudSave.new()
	_cloud.name = "CloudSave"
	add_child(_cloud)
	_cloud.finished.connect(_on_cloud)

	var velo := ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.01, 0.04, 0.05, 0.9)
	add_child(velo)

	var margine := MarginContainer.new()
	margine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 20)
	add_child(margine)

	var scorri := ScrollContainer.new()
	scorri.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margine.add_child(scorri)

	_colonna = VBoxContainer.new()
	_colonna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colonna.add_theme_constant_override("separation", 8)
	scorri.add_child(_colonna)

	_disegna()

# ---------------------------------------------------------------- disegno

func _disegna() -> void:
	for figlio in _colonna.get_children():
		_colonna.remove_child(figlio)
		figlio.queue_free()

	_colonna.add_child(_titolo("REGISTRO DEI GIOCATORI"))
	_colonna.add_child(_schede())

	if _scheda == SCHEDA_CASA:
		_disegna_casa()
	else:
		_disegna_gruppo()

	_messaggio = Label.new()
	_messaggio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messaggio.add_theme_font_size_override("font_size", 13)
	_messaggio.add_theme_color_override("font_color", Color("ffd75e"))
	_messaggio.text = _messaggio_testo
	_colonna.add_child(_messaggio)

	var chiudi := Button.new()
	chiudi.text = "CHIUDI"
	chiudi.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	chiudi.pressed.connect(func(): closed.emit())
	_colonna.add_child(chiudi)

func _schede() -> Control:
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 8)
	for voce in [[SCHEDA_CASA, "CASA"], [SCHEDA_GRUPPO, "GRUPPO"]]:
		var b := Button.new()
		b.text = str(voce[1])
		b.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = _scheda == str(voce[0])
		b.pressed.connect(_cambia_scheda.bind(str(voce[0])))
		riga.add_child(b)
	return riga

func _disegna_casa() -> void:
	var schede := ProgressBoard.schede_locali()
	if schede.size() < 2:
		# Con una casella sola non c'è confronto. Invece di disegnare una
		# classifica di una riga — che è una presa in giro — si dice come si fa.
		_colonna.add_child(_nota(
			"Su questo tablet gioca una persona sola, quindi non c'è ancora niente da confrontare.\n\nDal menu di avvio, «CAMBIA» » «+ NUOVO GIOCATORE»: ogni casella ha la sua partita, e qui comincia la sfida."))
		return
	_colonna.add_child(_selettore_asse())
	_colonna.add_child(_tabella(schede))

func _disegna_gruppo() -> void:
	var codice := PlayerProfiles.group_code()
	if codice.is_empty():
		_colonna.add_child(_nota(
			"Un gruppo mette insieme più tablet: una classe, dei cugini, degli amici. Chi ha il codice vede come vanno gli altri.\n\nNel gruppo viaggiano solo NOME e NUMERI. Mai la partita, mai il codice di ripristino: nessuno può toccare il salvataggio di un altro."))

		var crea := Button.new()
		crea.text = "CREA UN GRUPPO NUOVO"
		crea.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		crea.pressed.connect(_crea_gruppo)
		_colonna.add_child(crea)

		_colonna.add_child(_nota("Oppure entra in un gruppo che esiste già:"))
		_campo = LineEdit.new()
		_campo.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		_campo.max_length = 7
		_campo.placeholder_text = "ABC-123"
		_colonna.add_child(_campo)

		var entra := Button.new()
		entra.text = "ENTRA"
		entra.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
		entra.pressed.connect(_entra_nel_gruppo)
		_colonna.add_child(entra)
		return

	var intestazione := Label.new()
	intestazione.text = "Gruppo %s" % codice
	intestazione.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intestazione.add_theme_font_size_override("font_size", 24)
	intestazione.add_theme_color_override("font_color", Color("8ff6d2"))
	_colonna.add_child(intestazione)
	_colonna.add_child(_nota("Chi ha questo codice entra nel registro. Scrivilo agli altri."))

	var azioni := HBoxContainer.new()
	azioni.add_theme_constant_override("separation", 8)
	var aggiorna := Button.new()
	aggiorna.text = "AGGIORNA"
	aggiorna.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	aggiorna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aggiorna.pressed.connect(_pubblica_e_leggi)
	azioni.add_child(aggiorna)
	var esci := Button.new()
	esci.text = "ESCI DAL GRUPPO"
	esci.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	esci.pressed.connect(func():
		# Uscire toglie il codice da QUESTO tablet, non cancella niente per gli
		# altri: le partite non sono qui dentro, e nessuno perde nulla.
		PlayerProfiles.clear_group_code()
		_schede_gruppo = []
		_dico("Uscito dal gruppo. Le partite non sono state toccate.")
		_disegna())
	azioni.add_child(esci)
	_colonna.add_child(azioni)

	if _schede_gruppo.is_empty():
		_colonna.add_child(_nota("Tocca AGGIORNA per leggere il registro."))
		return
	_colonna.add_child(_selettore_asse())
	_colonna.add_child(_tabella(_schede_gruppo))

## La scelta della classifica. La prima voce è quella che riparte, ed è anche
## quella selezionata all'apertura.
func _selettore_asse() -> Control:
	var scelta := OptionButton.new()
	scelta.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	var assi: Array = []
	for a in ProgressBoard.ASSI:
		assi.append(str(Dictionary(a)["id"]))
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		assi.append("materia:%s" % str(subject_data))
	for i in range(assi.size()):
		scelta.add_item(ProgressBoard.etichetta(str(assi[i])), i)
		if str(assi[i]) == _asse:
			scelta.select(i)
	scelta.item_selected.connect(func(indice: int):
		_asse = str(assi[indice])
		_disegna())
	var scatola := VBoxContainer.new()
	scatola.add_theme_constant_override("separation", 4)
	scatola.add_child(scelta)
	for a in ProgressBoard.ASSI:
		if str(Dictionary(a)["id"]) == _asse:
			scatola.add_child(_nota(str(Dictionary(a)["spiega"])))
	return scatola

func _tabella(schede: Array) -> Control:
	var scatola := VBoxContainer.new()
	scatola.add_theme_constant_override("separation", 4)
	var ordinate := ProgressBoard.ordina(schede, _asse)
	for i in range(ordinate.size()):
		var s: Dictionary = ordinate[i]
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 10)

		var posto := Label.new()
		posto.text = "%d." % (i + 1)
		posto.custom_minimum_size = Vector2(34, 0)
		posto.add_theme_font_size_override("font_size", 17)
		posto.add_theme_color_override("font_color", Color("ffd75e") if i == 0 else Color("9fb7bb"))
		riga.add_child(posto)

		var nome := Label.new()
		nome.text = str(s.get("nome", ""))
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.add_theme_font_size_override("font_size", 17)
		nome.add_theme_color_override("font_color", Color("f7fbff"))
		riga.add_child(nome)

		var valore := Label.new()
		valore.text = ProgressBoard.testo_valore(s, _asse)
		valore.add_theme_font_size_override("font_size", 19)
		valore.add_theme_color_override("font_color", Color("8ff6d2"))
		riga.add_child(valore)

		scatola.add_child(riga)

	var medaglie := ProgressBoard.medaglie(schede)
	if not medaglie.is_empty():
		scatola.add_child(_nota("In testa a qualcosa:"))
		for nome_data in medaglie.keys():
			var etichette: Array = []
			for asse in Array(medaglie[nome_data]):
				etichette.append(ProgressBoard.etichetta(str(asse)))
			scatola.add_child(_nota("%s — %s" % [
				str(nome_data), ", ".join(PackedStringArray(etichette))]))
	return scatola

# ---------------------------------------------------------------- azioni

func _cambia_scheda(quale: String) -> void:
	_scheda = quale
	_messaggio_testo = ""
	_disegna()

func _crea_gruppo() -> void:
	# Un codice gruppo non si controlla contro il cloud come quello di
	# ripristino: entrare in un gruppo che esiste già non fa danno — si vede una
	# tabella in più. Sovrascrivere il salvataggio di un altro sì, ed è per
	# questo che lì il controllo c'è.
	var codice := PlayerProfiles.generate_group_code()
	if not PlayerProfiles.set_group_code(codice):
		_dico("Non riesco a creare il gruppo.")
		return
	_dico("Gruppo %s creato. Scrivilo agli altri per farli entrare." % codice)
	_disegna()
	_pubblica_e_leggi()

func _entra_nel_gruppo() -> void:
	var codice := _campo.text.to_upper().strip_edges() if is_instance_valid(_campo) else ""
	if not PlayerProfiles.is_valid_group_code(codice):
		_dico(CloudSave.messaggio_errore(400, "gruppo"))
		return
	PlayerProfiles.set_group_code(codice)
	_disegna()
	_pubblica_e_leggi()

## Prima si pubblicano le schede di casa, poi si rilegge il registro.
##
## Si pubblicano TUTTE le caselle di questo tablet, non solo quella attiva: su
## un tablet di famiglia il registro sarebbe altrimenti incompleto finché ogni
## fratello non apre il gioco di persona, e una tabella con dei buchi si legge
## come un difetto.
func _pubblica_e_leggi() -> void:
	if _cloud.occupato():
		return
	var codice := PlayerProfiles.group_code()
	if codice.is_empty():
		return
	_coda_invii = []
	for p in PlayerProfiles.all():
		var profilo: Dictionary = p
		var id := str(profilo.get("id", ""))
		var save := GameSaveManager.new(str(profilo.get("file", "")))
		save.load_save()
		_coda_invii.append({
			"membro": PlayerProfiles.member_id_of(id),
			"scheda": ProgressBoard.scheda(save, str(profilo.get("name", ""))),
		})
	_dico("Aggiorno il registro…")
	_prossimo_invio()

func _prossimo_invio() -> void:
	var codice := PlayerProfiles.group_code()
	if _coda_invii.is_empty():
		_cloud.leggi_gruppo(codice)
		return
	var voce: Dictionary = _coda_invii.pop_front()
	_cloud.manda_scheda(codice, str(voce["membro"]), Dictionary(voce["scheda"]))

func _on_cloud(esito: Dictionary) -> void:
	match str(esito.get("azione", "")):
		"scheda":
			# Un invio fallito non ferma gli altri: meglio un registro con una
			# riga vecchia che nessun registro.
			_prossimo_invio()
		"gruppo":
			if not bool(esito.get("ok", false)):
				_dico(str(esito.get("errore", "")))
				return
			_schede_gruppo = Array(Dictionary(esito.get("meta", {})).get("membri", []))
			_dico("Registro aggiornato: %d giocatori." % _schede_gruppo.size())
			_disegna()

# ---------------------------------------------------------------- utilità

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
