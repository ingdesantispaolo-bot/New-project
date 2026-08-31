class_name PauseMenuPanel
extends Control

## **LA PAUSA.** (21 agosto 2026)
##
## Richiesta del committente: si deve poter tornare al menu principale,
## riavviare la missione e cambiare utente.
##
## Fino a oggi due di queste tre cose non esistevano da nessuna parte, e la
## terza — il ritorno al menu — esisteva **solo nella nave**. Chi era nel mondo
## aperto e voleva smettere, ricominciare o passare il tablet al fratello non
## aveva nessuna porta: doveva raggiungere il portale, entrare nella nave e
## cercare lì. Su un tablet, dove l'applicazione non si chiude quasi mai
## davvero, «non c'è la porta» e «non si può» sono la stessa frase.
##
## ## Perché un pannello solo per due scene
##
## Il mondo e la nave non si somigliano in niente, ma la pausa deve somigliare a
## se stessa: stessi comandi, stesso ordine, stesso posto. Un bambino che impara
## a uscire dalla nave deve saper uscire dal mondo senza impararlo di nuovo.
##
## Qui vive **solo la domanda**. Che cosa significhi riavviare, dove porti il
## cambio di giocatore e che cosa vada salvato prima lo decide la scena, che è
## l'unica a saperlo: [[OutdoorWorld]] riapre il suo mondo dal portale,
## [[HubScene]] ci entra dalla nave.
##
## ## Le tre cose che il pannello fa da sé, e non sono decorazione
##
## **Ferma il gioco.** `get_tree().paused` mentre è aperto: la carica dei
## guardiani, gli inseguimenti e l'orologio del giorno non possono correre mentre
## si legge un menu. Il pannello resta vivo perché è `PROCESS_MODE_ALWAYS`, e con
## lui il pannello dei profili — che parla col cloud e ha bisogno di girare.
##
## **Chiede conferma solo per il riavvio.** Tornare al menu e cambiare giocatore
## salvano e non tolgono niente; riavviare invece **sposta**, e chi lo tocca per
## sbaglio si ritrova al portale dall'altra parte della mappa. Una conferma sola,
## dove serve: metterla su tutti e tre insegnerebbe a rispondere «sì» senza
## leggere.
##
## **Dice che la partita è salvata.** Non è una rassicurazione di cortesia: è la
## sola paura che tiene un bambino dentro un gioco che vorrebbe lasciare, e la
## scena la rende vera salvando nell'istante in cui la pausa si apre.

signal ripreso
signal riavvio_chiesto
signal giocatore_scelto(id: String)
signal menu_chiesto

## Bersaglio touch. Più alto dei 44 del contratto di accessibilità, perché qui un
## tocco sbagliato non è un tocco sbagliato: è uscire dal gioco.
const ALTEZZA_TOCCO := 52

const ORO := Color("f4cf69")
const FREDDO := Color("6be7d6")
const TESTO := Color("eaf7ff")

var _cornice: PanelContainer
var _colonna: VBoxContainer
var _profilo: ProfilePanel
var _nome_giocatore := "Giocatore 1"
var _luogo := ""
var _titolo_riavvio := "RIAVVIA IL MONDO"
var _nota_riavvio := ""
var _puo_riavviare := true
var _alto_contrasto := false
## Vero mentre la conferma del riavvio ha preso il posto dei quattro comandi.
var _in_conferma := false

func _init() -> void:
	# Il pannello deve girare **mentre il gioco è fermo**: senza questo, i suoi
	# stessi pulsanti smetterebbero di rispondere nell'istante in cui si apre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.name = "PauseVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.01, 0.035, 0.05, 0.90)
	# STOP e non IGNORE: il velo è anche la garanzia che un dito che manca il
	# pulsante non finisca a muovere Eli sotto il menu.
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_cornice = PanelContainer.new()
	_cornice.name = "PauseCard"
	_cornice.custom_minimum_size = Vector2(380, 0)
	_cornice.add_theme_stylebox_override("panel", _stile_cornice())
	centro.add_child(_cornice)

	var margine := MarginContainer.new()
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 24)
	_cornice.add_child(margine)

	_colonna = VBoxContainer.new()
	_colonna.name = "PauseColumn"
	_colonna.add_theme_constant_override("separation", 10)
	margine.add_child(_colonna)

## **Apre la pausa.** La scena passa quello che solo lei sa: chi gioca, dove si
## trova, e come si chiama qui il riavvio.
##
## `nota_riavvio` non è un aiuto opzionale: è il posto in cui sta scritto **che
## cosa resta** dopo aver riavviato. Un pulsante che ricomincia qualcosa, senza
## quella riga, viene letto come «perdi tutto» e non lo tocca nessuno.
func apri(nome_giocatore: String, luogo: String, titolo_riavvio: String,
		nota_riavvio: String, puo_riavviare: bool, alto_contrasto := false) -> void:
	_nome_giocatore = nome_giocatore
	_luogo = luogo
	_titolo_riavvio = titolo_riavvio
	_nota_riavvio = nota_riavvio
	_puo_riavviare = puo_riavviare
	_alto_contrasto = alto_contrasto
	_in_conferma = false
	_chiudi_profili()
	visible = true
	if is_instance_valid(_cornice):
		_cornice.add_theme_stylebox_override("panel", _stile_cornice())
	_disegna()
	if is_inside_tree():
		get_tree().paused = true

## Chiude e fa ripartire il gioco.
func chiudi() -> void:
	if not visible:
		return
	congeda()
	ripreso.emit()

## Toglie la pausa **senza** emettere niente: la usano le uscite che cambiano
## scena, perché una scena nuova che nascesse con l'albero fermo sarebbe un gioco
## bloccato — e perché non hanno nessun gioco da riprendere.
func congeda() -> void:
	visible = false
	_in_conferma = false
	_chiudi_profili()
	if is_inside_tree():
		get_tree().paused = false

func aperto() -> bool:
	return visible

# ---------------------------------------------------------------- disegno

func _disegna() -> void:
	if not is_instance_valid(_colonna):
		return
	for figlio in _colonna.get_children():
		_colonna.remove_child(figlio)
		figlio.queue_free()

	_colonna.add_child(_titolo("PAUSA"))
	_colonna.add_child(_riga("Giochi come: %s" % _nome_giocatore, FREDDO, 15))
	if not _luogo.is_empty():
		_colonna.add_child(_riga(_luogo, Color("9fb7bb"), 13))
	_colonna.add_child(_spazio(6))

	if _in_conferma:
		_disegna_conferma()
		return

	_colonna.add_child(_pulsante("PauseResumeButton", "RIPRENDI", 20, FREDDO, chiudi))
	_colonna.add_child(_pulsante(
		"PauseVolumeButton", "VOLUME: %d%%" % _volume_percentuale(), 15, TESTO, _cambia_volume))
	_colonna.add_child(_pulsante(
		"PauseMuteButton", "SUONO: %s" % ("DISATTIVATO" if _audio_muto() else "ATTIVO"),
		15, TESTO, _cambia_muto))
	if _puo_riavviare:
		_colonna.add_child(_pulsante(
			"PauseRestartButton", _titolo_riavvio, 16, ORO, _chiedi_conferma))
		if not _nota_riavvio.is_empty():
			_colonna.add_child(_riga(_nota_riavvio, Color("9fb7bb"), 12))
	_colonna.add_child(_pulsante(
		"PauseSwitchPlayerButton", "CAMBIA GIOCATORE", 16, TESTO, _apri_profili))
	_colonna.add_child(_pulsante(
		"PauseMainMenuButton", "MENU PRINCIPALE", 16, TESTO, _chiedi_menu))
	_colonna.add_child(_riga("La partita è già salvata.", Color("8ff6d2"), 12))

func _disegna_conferma() -> void:
	_colonna.add_child(_riga(
		_nota_riavvio if not _nota_riavvio.is_empty() else "Ricominci da capo.", ORO, 14))
	_colonna.add_child(_pulsante(
		"PauseRestartConfirmButton", "SÌ, RIAVVIA", 17, ORO, _conferma_riavvio))
	_colonna.add_child(_pulsante(
		"PauseRestartCancelButton", "NO, TORNO INDIETRO", 15, TESTO, _annulla_riavvio))

func _chiedi_conferma() -> void:
	_in_conferma = true
	_disegna()

func _annulla_riavvio() -> void:
	_in_conferma = false
	_disegna()

func _conferma_riavvio() -> void:
	riavvio_chiesto.emit()

func _chiedi_menu() -> void:
	menu_chiesto.emit()

# ---------------------------------------------------------------- audio

func _audio_manager() -> Node:
	return get_node_or_null("/root/NativeAudio")

func _volume_percentuale() -> int:
	var audio := _audio_manager()
	return int(audio.call("master_volume_percent")) if audio != null else 100

func _audio_muto() -> bool:
	var audio := _audio_manager()
	return bool(audio.call("is_muted")) if audio != null else false

func _cambia_volume() -> void:
	var audio := _audio_manager()
	if audio != null:
		audio.call("cycle_master_volume")
	_disegna()

func _cambia_muto() -> void:
	var audio := _audio_manager()
	if audio != null:
		audio.call("toggle_mute")
	_disegna()

# ---------------------------------------------------------------- i profili

## Il pannello dei profili è quello del menu d'avvio, senza una riga di
## differenza: l'elenco dei bambini, i nomi, i codici di ripristino. Scriverne una
## versione «da pausa» avrebbe voluto dire due elenchi da tenere d'accordo, e il
## giorno in cui divergono il codice cloud sta in quello sbagliato.
##
## Non ha un «annulla», e va bene così: la sua unica uscita è GIOCA, che conferma
## il bambino selezionato — quello di prima, se non se n'è toccato nessun altro.
func _apri_profili() -> void:
	if is_instance_valid(_profilo):
		return
	_profilo = ProfilePanel.new()
	_profilo.name = "PauseProfilePanel"
	_profilo.chosen.connect(_on_profilo_scelto)
	add_child(_profilo)

func _on_profilo_scelto(id: String) -> void:
	_chiudi_profili()
	giocatore_scelto.emit(id)

func _chiudi_profili() -> void:
	if is_instance_valid(_profilo):
		_profilo.queue_free()
	_profilo = null

# ---------------------------------------------------------------- pezzi

func _titolo(testo: String) -> Label:
	var nodo := Label.new()
	nodo.name = "PauseTitle"
	nodo.text = testo
	nodo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nodo.add_theme_font_size_override("font_size", 30)
	nodo.add_theme_color_override("font_color", ORO)
	return nodo

func _riga(testo: String, colore: Color, dimensione: int) -> Label:
	var nodo := Label.new()
	nodo.text = testo
	nodo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nodo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nodo.custom_minimum_size.x = 332
	nodo.add_theme_font_size_override("font_size", dimensione)
	nodo.add_theme_color_override("font_color", colore)
	return nodo

func _spazio(altezza: int) -> Control:
	var nodo := Control.new()
	nodo.custom_minimum_size.y = altezza
	return nodo

## Il nome del nodo arriva dal chiamante e non dal testo: gli audit cercano i
## pulsanti per nome, e un nome ricavato da un'etichetta che cambia con la scena
## («RIAVVIA IL MONDO» nel mondo, «RIENTRA NEL MONDO» dalla nave) sarebbe un
## appiglio che si sposta da solo.
func _pulsante(nome: String, testo: String, dimensione: int,
		colore: Color, azione: Callable) -> Button:
	var nodo := Button.new()
	nodo.name = nome
	nodo.text = testo
	nodo.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	nodo.add_theme_font_size_override("font_size", dimensione)
	nodo.add_theme_color_override("font_color", colore)
	nodo.pressed.connect(azione)
	return nodo

func _stile_cornice() -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color(0.015, 0.075, 0.095, 0.98)
	stile.border_color = Color.WHITE if _alto_contrasto else Color(0.42, 0.91, 0.84, 0.9)
	stile.set_border_width_all(4 if _alto_contrasto else 2)
	stile.set_corner_radius_all(18)
	return stile
