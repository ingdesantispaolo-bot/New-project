extends SceneTree

## **Il guardiano, giocato davvero.** (7 agosto 2026)
##
## `guardian_duel_audit` verifica la taratura senza costruire niente. Qui si apre
## un mondo vero e si controlla la catena che il committente ha chiesto:
##
##   1. sui forzieri scoperti compare una guardiana;
##   2. finché è viva **il forziere non si apre** — è il senso di «proteggono i
##      bauli», e senza questo controllo resterebbe una decorazione;
##   3. la si può affrontare (esiste il gesto, non solo il danno subìto);
##   4. il duello **si apre e si vince giocandolo**: dal 16 agosto 2026 il
##      combattimento è di calcolo, e l'audit lo gioca davvero — genera lo
##      scambio, cerca la strada e la percorre. Senza questo, un difetto nella
##      generazione lascerebbe un bambino fermo davanti a un guardiano
##      invincibile e nessun controllo se ne accorgerebbe;
##   5. sciolta, il forziere si apre **e resta aperto**: rientrando nel mondo la
##      guardiana non ricompare, altrimenti si rigiocherebbe il duello per un
##      premio già preso.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const LIVELLO := 3

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _apri(save_data: Dictionary = {}) -> Node:
	var initial := save_data if not save_data.is_empty() else GameSaveManager._default_data()
	if save_data.is_empty():
		initial["level"] = LIVELLO
		initial["energy"] = 300
		initial["worlds"] = {"unlocked": range(1, LIVELLO + 1), "current": LIVELLO}
	var request := NativeWorldState.default_request("guardian-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = LIVELLO
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	# **Qui i pezzi di mappa servono davvero.** Gli altri audit di scena li
	# spengono per andare veloci; questo verifica una cosa che nasce dai forzieri,
	# e i forzieri arrivano coi pezzi di mappa. Senza raggio non c'e' niente da
	# sorvegliare e l'audit misurerebbe il vuoto.
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	current_scene = world
	# Le guardiane nascono nel giro periodico, non alla costruzione: i forzieri
	# arrivano coi pezzi di mappa. Qualche fotogramma serve per forza.
	for _i in range(6):
		await process_frame
	return world

func _guardiani(world: Node) -> Array:
	var out: Array = []
	for sacca in get_nodes_in_group("world_enemy"):
		if world.is_ancestor_of(sacca) and not str(sacca.get("treasure_id")).is_empty():
			out.append(sacca)
	return out

func _run() -> void:
	var world := await _apri()
	var guardiani := _guardiani(world)
	_controlla(not guardiani.is_empty(), "nessun forziere sorvegliato in tutto il mondo")
	if guardiani.is_empty():
		_esito()
		return

	var guardia: Node2D = guardiani[0]
	var treasure_id := str(guardia.get("treasure_id"))
	_controlla(world.call("_guardiano_di", treasure_id) == guardia,
		"il mondo non sa quale guardiano difende quale forziere")

	# **Il forziere non si apre.** Si prova a raccoglierlo: i frammenti non
	# devono muoversi e il tesoro non deve risultare raccolto.
	var save: GameSaveManager = world.get("game_save")
	var frammenti_prima := save.fragments()
	var forziere := _area_forziere(world, treasure_id)
	_controlla(forziere != null, "il forziere sorvegliato non è più sulla mappa")
	if forziere != null:
		world.set("nearby", [forziere])
		world.call("_interact")
		await process_frame
		_controlla(save.fragments() == frammenti_prima,
			"il forziere sorvegliato si è aperto lo stesso")
		_controlla(not Array(Dictionary(world.get("result")).get("collectedTreasureIds", [])).has(treasure_id),
			"il forziere sorvegliato risulta raccolto")

	# Si può affrontare: il gesto esiste.
	_controlla(guardia.find_child("EnemyChallenge", true, false) != null,
		"il guardiano non si può affrontare")

	# **Il duello, giocato per davvero.** Si apre il pannello e si spezzano i
	# sigilli con la strada che il pannello stesso dichiara. Nessuna scorciatoia
	# interna: se la generazione producesse uno scambio senza strada, o se il
	# combattimento non si chiudesse da solo, qui l'audit resterebbe appeso al
	# guardiano esattamente come ci resterebbe un bambino.
	var guardia_id := str(guardia.get_meta("guardId", ""))
	# **Le due materie arrivano davvero in scena** (17 agosto 2026). Prima di
	# giocare il duello vero si controlla che ogni guardiano apra il pannello
	# della materia che dichiara: un guardiano marcato VOCI che aprisse il campo
	# dei conti sarebbe un cartiglio bugiardo sulla mappa, e il bambino avrebbe
	# scelto di avvicinarsi per una ragione sbagliata.
	await _ogni_guardiano_apre_la_sua_materia(world, guardiani)

	await _il_duello_si_gioca(world, guardia)

	# Vinto il duello: la sacca si scioglie e il fatto resta scritto.
	_controlla(save.enemy_defeated(str(LIVELLO), guardia_id),
		"una sacca sciolta non risulta sciolta nel salvataggio")
	_controlla(save.fragments() > frammenti_prima,
		"vincere il duello non ha lasciato frammenti")

	# **Resta sciolta.** Si riapre il mondo con quel salvataggio: quella
	# guardiana non deve ricomparire.
	var snapshot: Dictionary = save.snapshot()
	world.queue_free()
	await process_frame
	var ritorno := await _apri(snapshot)
	for sacca in _guardiani(ritorno):
		_controlla(str(sacca.get_meta("guardId", "")) != guardia_id,
			"la guardiana sciolta è tornata: il duello si rigiocherebbe per lo stesso premio")
	ritorno.queue_free()
	await process_frame
	_esito()

## Apre il duello di ogni guardiano in vista e controlla che la scena
## corrisponda alla materia dichiarata dal cartiglio, che lo scambio nasca
## giocabile e che uscirne sia gratis. È il controllo che tiene onesta la
## promessa fatta sulla mappa.
func _ogni_guardiano_apre_la_sua_materia(world: Node, guardiani: Array) -> void:
	var viste: Dictionary = {}
	for sacca in guardiani:
		var guardia_id := str(sacca.get_meta("guardId", ""))
		var materia := DuelRules.materia(guardia_id)
		if viste.has(materia):
			continue
		viste[materia] = true
		world.call("_sfida_guardiano", sacca)
		await process_frame
		var pannello = world.get("duel_panel")
		if pannello == null:
			errori.append("il guardiano «%s» non apre nessun duello" % guardia_id)
			continue
		var giusto: bool = (pannello is VerbDuelPanel) if materia == DuelRules.VOCI \
			else (pannello is GuardianDuelPanel)
		_controlla(giusto,
			"il guardiano «%s» dichiara %s ma apre «%s»" % [guardia_id, materia, pannello.name])
		_controlla(str(Dictionary(pannello.get("regole")).get("materia", "")) == materia,
			"le regole aperte non sono quelle della materia dichiarata da «%s»" % guardia_id)
		_controlla(not Array(pannello.call("sequenza_vincente")).is_empty(),
			"il duello di «%s» si apre senza nessuna strada verso il sigillo" % guardia_id)
		# Andarsene è gratis: il pulsante c'è e chiude tutto senza conseguenze.
		var uscita := pannello.find_child("DuelLeaveButton", true, false) as Button
		_controlla(uscita != null, "dal duello di «%s» non si può uscire" % guardia_id)
		if uscita != null:
			uscita.emit_signal("pressed")
			await process_frame
		_controlla(world.get("duel_panel") == null,
			"uscire dal duello di «%s» non chiude il pannello" % guardia_id)
	_controlla(not viste.is_empty(), "nessun guardiano ha aperto un duello")
	# **Le materie mancanti si forzano.** Un mondo di prova piccolo può avere tre
	# guardiani che cadono tutti dalla stessa parte del sorteggio, e un verde che
	# ha visto una materia sola non dice niente sull'altra. Qui si riscrive
	# l'identificativo di un guardiano perché cada dall'altra parte: è la stessa
	# strada che percorre il gioco — è `guardId` a decidere la materia — e alla
	# fine l'identificativo torna quello vero.
	for materia in DuelRules.MATERIE:
		if viste.has(str(materia)) or guardiani.is_empty():
			continue
		var sacca: Node2D = guardiani[guardiani.size() - 1]
		var vero := str(sacca.get_meta("guardId", ""))
		var finto := _identificativo_per(str(materia))
		if finto.is_empty():
			errori.append("nessun identificativo produce la materia «%s»" % str(materia))
			continue
		sacca.set_meta("guardId", finto)
		world.call("_sfida_guardiano", sacca)
		await process_frame
		var pannello = world.get("duel_panel")
		_controlla(pannello != null, "forzando la materia «%s» non si apre nessun duello" % str(materia))
		if pannello != null:
			var giusto: bool = (pannello is VerbDuelPanel) if str(materia) == DuelRules.VOCI \
				else (pannello is GuardianDuelPanel)
			_controlla(giusto, "la materia «%s» apre il pannello sbagliato" % str(materia))
			_controlla(not Array(pannello.call("sequenza_vincente")).is_empty(),
				"il duello di «%s» si apre senza nessuna strada" % str(materia))
			var uscita := pannello.find_child("DuelLeaveButton", true, false) as Button
			if uscita != null:
				uscita.emit_signal("pressed")
				await process_frame
		sacca.set_meta("guardId", vero)
		viste[str(materia)] = true
	print("  materie messe in scena: %s" % ", ".join(PackedStringArray(viste.keys())))

## Un identificativo qualunque che cada sulla materia voluta. Non inventa niente:
## interroga la stessa funzione che usa il gioco.
func _identificativo_per(materia: String) -> String:
	for tentativo in range(200):
		var id := "guardia-audit-%d" % tentativo
		if DuelRules.materia(id) == materia:
			return id
	return ""

## **Gioca il duello fino in fondo.** Chiede al pannello la strada più corta per
## il sigillo di adesso e la percorre, sigillo dopo sigillo.
##
## Le attese sono su un timer vero e non su un numero di fotogrammi: fra un
## sigillo e l'altro il pannello si prende il suo istante (il sigillo che si
## spezza, il guardiano che arretra), e in headless i fotogrammi passano tanto in
## fretta che contarli non direbbe niente sul tempo trascorso.
func _il_duello_si_gioca(world: Node, guardia: Node2D) -> void:
	world.call("_sfida_guardiano", guardia)
	await process_frame
	var pannello = world.get("duel_panel")
	_controlla(pannello != null, "affrontare il guardiano non apre il duello")
	if pannello == null:
		return
	_controlla(bool(pannello.call("attivo")), "il duello si apre già risolto")
	var finito := false
	var scambi := 0
	while scambi < 12:
		# Il pannello può essersi già chiuso da solo: vinto l'ultimo sigillo lo
		# libera il mondo, e da lì in poi non gli si chiede più niente.
		if not is_instance_valid(pannello) or not bool(pannello.call("attivo")):
			finito = true
			break
		scambi += 1
		var strada: Array = pannello.call("sequenza_vincente")
		if strada.is_empty():
			errori.append("il duello propone uno scambio senza nessuna strada verso il sigillo")
			break
		for passo in strada:
			pannello.call("colpisci", int(passo))
		await create_timer(1.1).timeout
	_controlla(finito,
		"il duello non si chiude nemmeno giocando la strada giusta a ogni scambio")
	# E la vittoria arriva al mondo da sola: il pannello si chiude, la sacca si
	# scioglie, nessuno chiama niente a mano.
	await create_timer(1.1).timeout
	_controlla(world.get("duel_panel") == null,
		"vinto il duello, il pannello resta aperto sopra il mondo")

func _area_forziere(world: Node, treasure_id: String) -> Area2D:
	for nodo in get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or not world.is_ancestor_of(nodo):
			continue
		if str(nodo.get_meta("kind", "")) == "treasure" and str(nodo.get_meta("id", "")) == treasure_id:
			return nodo as Area2D
	return null

func _esito() -> void:
	if errori.is_empty():
		print("GUARDIAN SCENE audit VERDE")
	else:
		printerr("GUARDIAN SCENE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
