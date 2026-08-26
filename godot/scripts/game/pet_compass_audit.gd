extends SceneTree

## **La bussola dichiarata e il fiuto.** (19 agosto 2026)
##
## Fino al 18 agosto la freccia del Custode puntava al nodo `world_interactable`
## aperto piu' vicino, **qualunque fosse**: un obiettivo del gate, ma anche un
## forziere, una traccia del mistero, e perfino il portale o un landmark — che
## stanno in quel gruppo e non hanno mai una `completed` a vero, quindi
## risultavano eternamente da fare.
##
## Il difetto non era la freccia sbagliata, era la freccia **onnisciente**. In un
## mondo dove ogni cosa e' gia' indicata non si scopre niente: l'esplorazione
## diventa il percorso di una lista, e le deviazioni — che sono la meta'
## facoltativa del gioco — vengono consegnate come gli obiettivi e quindi
## smettono di essere deviazioni.
##
## Questo audit tiene in piedi le due meta' della riparazione:
##
##   1. **la freccia nomina solo cio' che il gioco ha dichiarato** (gruppo
##      `mission_poi`, gli eventi che contano per il gate) e si spegne quando non
##      ne resta nessuno aperto, invece di ripiegare sul portale — la strada per
##      la nave ha gia' la sua barra di navigazione;
##   2. **il fiuto indica molto meno di quanto indicasse la freccia**: solo
##      deviazioni, solo entro poco piu' di una schermata, e solo come **verso**
##      — nessun nome, nessuna distanza, nessuna destinazione.
##
## Il guard-rail che vale piu' di tutti, ed e' l'ultima prova qui sotto: il fiuto
## non puo' toccare un obiettivo del gate. Il Custode non ha mai aiutato a
## progredire (`pet_state.gd`) e questo lotto non e' il momento di cominciare.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = 200
	initial["fragments"] = 0
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("pet-compass-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

## Un finto nodo di mappa con le sole cose che la bussola e il fiuto guardano.
func _finto(mondo: Node, kind: String, id: String, dove: Vector2) -> Area2D:
	var area := Area2D.new()
	area.name = "Finto_%s" % id.replace("-", "_")
	area.set_meta("kind", kind)
	area.set_meta("id", id)
	area.set_meta("completed", false)
	area.add_to_group("world_interactable")
	mondo.get("world_layer").add_child(area)
	area.global_position = dove
	return area

func _obiettivi_aperti() -> Array:
	var aperti: Array = []
	for nodo in get_nodes_in_group("mission_poi"):
		if nodo is Node2D and not bool((nodo as Node).get_meta("completed", false)):
			aperti.append(nodo)
	return aperti

func _run() -> void:
	root.size = Vector2i(900, 600)
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request())
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame

	var save: GameSaveManager = mondo.get("gameplay").game_save
	PetState.grant(save, 1)
	PetState.add_bond(save, 1.0)
	save.save()
	mondo.call("_refresh_pet_face")
	await process_frame

	var player: Node2D = mondo.get("player")
	var custode = mondo.get("pet_companion")
	var pet_face: Control = mondo.get("pet_face")
	_controlla(is_instance_valid(custode), "nessun Custode nel mondo: l'audit non prova niente")
	if not is_instance_valid(custode):
		await _esito(mondo)
		return

	var aperti := _obiettivi_aperti()
	_controlla(not aperti.is_empty(),
		"il mondo 1 non ha nessun obiettivo di gate aperto: la bussola non ha che cosa indicare")

	# Le deviazioni vere del mondo — forzieri e semi del mistero, che ci sono e
	# stanno dove il seed le ha messe — si mettono da parte per la durata della
	# prova. Non e' comodita': senza, «il fiuto ha sentito» e «il fiuto tace»
	# dipenderebbero dalla disposizione di QUESTO seed, cioe' non proverebbero
	# niente. Con la mappa sgombra ogni risposta e' attribuibile a un solo oggetto.
	var kinds_fiuto: Array = mondo.get_script().get_script_constant_map().get("PET_FIUTO_KINDS", [])
	var deviazioni_vere: Array = []
	for nodo in get_nodes_in_group("world_interactable"):
		if not kinds_fiuto.has(str((nodo as Node).get_meta("kind", ""))):
			continue
		if bool((nodo as Node).get_meta("completed", false)):
			continue
		deviazioni_vere.append(nodo)
		(nodo as Node).set_meta("completed", true)

	# --- 1. La freccia ignora le deviazioni, anche quando sono piu' vicine -----
	# Un forziere e una traccia a due passi da Eli, con gli obiettivi lontani: la
	# vecchia freccia avrebbe puntato al forziere, ed e' esattamente il gesto che
	# trasformava l'esplorazione in una consegna.
	var forziere := _finto(mondo, "treasure", "finto-forziere", player.global_position + Vector2(40, 0))
	var traccia := _finto(mondo, "mystery_trace", "finta-traccia", player.global_position + Vector2(-46, 12))
	var puntato: Vector2 = custode.call("_obiettivo_piu_vicino")
	_controlla(puntato != forziere.global_position,
		"la freccia punta a un forziere: le deviazioni si trovano, non si ricevono")
	_controlla(puntato != traccia.global_position,
		"la freccia punta a una traccia del mistero invece che a un obiettivo")
	if not aperti.is_empty():
		var e_un_obiettivo := false
		for nodo in aperti:
			if (nodo as Node2D).global_position.is_equal_approx(puntato):
				e_un_obiettivo = true
				break
		_controlla(e_un_obiettivo,
			"la freccia indica un punto che non appartiene a nessun obiettivo dichiarato")

	# --- 2. Senza obiettivi aperti la freccia si spegne ------------------------
	# E in particolare non ripiega sul portale, che sta anche lui in
	# `world_interactable` e non e' mai «completato»: due indicatori per la stessa
	# cosa sono uno di troppo.
	for nodo in aperti:
		(nodo as Node).set_meta("completed", true)
	_controlla(custode.call("_obiettivo_piu_vicino") == Vector2.INF,
		"chiusi tutti gli obiettivi la bussola indica ancora qualcosa (il portale?)")
	custode.call("_aggiorna_freccia")
	var freccia := custode.find_child("GuideArrow", true, false) as Node2D
	_controlla(freccia == null or not freccia.visible,
		"la freccia resta accesa senza nessun obiettivo da indicare")
	for nodo in aperti:
		(nodo as Node).set_meta("completed", false)

	# --- 3. Il fiuto sente le deviazioni, e mai un obiettivo ------------------
	var costanti: Dictionary = mondo.get_script().get_script_constant_map()
	var sentito: Dictionary = mondo.call("_deviazione_piu_vicina")
	_controlla(str(sentito.get("id", "")) == "finto-forziere",
		"il fiuto non ha sentito il forziere a quaranta unita' da Eli")
	# **Il guard-rail, e va provato sulla forma e non solo sul caso.** Un obiettivo
	# del gate diventa un nodo di scena `encounter`, `enigma` o `minimission`: se
	# uno solo di questi comparisse fra le cose che il fiuto guarda, il Custode
	# comincerebbe a indicare la strada per salire di livello.
	var fiuto_kinds: Array = costanti.get("PET_FIUTO_KINDS", [])
	_controlla(not fiuto_kinds.is_empty(), "il fiuto non guarda niente: `PET_FIUTO_KINDS` e' vuoto")
	for kind_di_gate in ["encounter", "enigma", "minimission"]:
		_controlla(not fiuto_kinds.has(kind_di_gate),
			"il fiuto guarda anche «%s», che e' un obiettivo del gate" % kind_di_gate)
	# E sul caso: un obiettivo addosso a Eli, piu' vicino di ogni deviazione.
	var obiettivo_addosso := _finto(mondo, "encounter", "finto-obiettivo", player.global_position + Vector2(8, 0))
	obiettivo_addosso.add_to_group("mission_poi")
	sentito = mondo.call("_deviazione_piu_vicina")
	_controlla(str(sentito.get("id", "")) != "finto-obiettivo",
		"il fiuto ha nominato un obiettivo del gate: il Custode sta aiutando a progredire")
	obiettivo_addosso.queue_free()
	await process_frame

	# --- 4. Il raggio e' un raggio -------------------------------------------
	traccia.global_position = player.global_position + Vector2(9000, 0)
	forziere.global_position = player.global_position + Vector2(
		float(costanti.get("PET_FIUTO_RAGGIO", 600.0)) + 200.0, 0)
	_controlla(Dictionary(mondo.call("_deviazione_piu_vicina")).is_empty(),
		"il fiuto sente un forziere oltre il proprio raggio: e' una mappa, non un fiuto")
	forziere.global_position = player.global_position + Vector2(120, 0)

	# --- 5. Un forziere gia' preso non si sente piu' --------------------------
	var delta_sessione: Dictionary = mondo.get("result")
	var raccolti: Array = delta_sessione["collectedTreasureIds"]
	raccolti.append("finto-forziere")
	_controlla(str(Dictionary(mondo.call("_deviazione_piu_vicina")).get("id", "")) != "finto-forziere",
		"il Custode si sporge verso un forziere gia' raccolto")
	raccolti.erase("finto-forziere")

	# --- 6. La faccia scatta una volta sola, il corpo resta girato ------------
	mondo.set("_pet_fiuto_ultimo", "")
	mondo.call("_pet_check_secret_proximity")
	var expected_secret_face := PetExpressionEngine.face_for_pet(
		"near_secret", PetState.temperament(save), str(pet_face.call("current_pet_kind")))
	_controlla(str(pet_face.call("current_face")) == expected_secret_face,
		"trovata una deviazione, il Custode non ha cambiato faccia")
	_controlla(absf(float(custode.get("_fiuto_lato")) - 1.0) < 0.01,
		"il Custode non si e' messo dalla parte della deviazione (a destra di Eli)")
	await create_timer(PetExpressionEngine.duration_of(expected_secret_face) + 0.2).timeout
	mondo.call("_pet_check_secret_proximity")
	_controlla(str(pet_face.call("current_face")) != expected_secret_face,
		"la stessa deviazione fa la stessa smorfia a ogni giro: e' un allarme, non un compagno")

	# Dall'altra parte, il Custode si gira dall'altra parte.
	forziere.global_position = player.global_position + Vector2(-120, 0)
	mondo.call("_pet_check_secret_proximity")
	_controlla(absf(float(custode.get("_fiuto_lato")) + 1.0) < 0.01,
		"la deviazione e' passata a sinistra e il Custode guarda ancora a destra")

	# --- 7. Niente deviazioni, niente sporgenza -------------------------------
	forziere.queue_free()
	traccia.queue_free()
	await process_frame
	mondo.call("_pet_check_secret_proximity")
	_controlla(custode.get("_fiuto") == Vector2.INF,
		"il fiuto resta acceso quando non c'e' piu' niente da sentire")

	await _esito(mondo)

func _esito(mondo: Node) -> void:
	root.remove_child(mondo)
	mondo.queue_free()
	current_scene = null
	await process_frame
	if _rossi.is_empty():
		print("PET COMPASS audit OK — la freccia nomina solo gli obiettivi dichiarati, il fiuto indica un verso e mai il gate")
		quit(0)
		return
	for riga in _rossi:
		printerr("PET COMPASS audit FALLITO — %s" % riga)
	quit(1)
