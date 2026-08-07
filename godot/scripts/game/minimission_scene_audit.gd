extends SceneTree

## **L'incarico, giocato davvero.** (7 agosto 2026)
##
## Il catalogo lo verifica `minimission_audit` senza costruire niente. Questo
## invece apre dei mondi veri e cammina il percorso completo: il POI esiste, si
## apre, la sessione è del tipo giusto, e — la parte che vale — **quando finisce
## il mondo è cambiato, e resta cambiato al rientro**.
##
## Quest'ultimo è il controllo che distingue una minimissione da un esercizio con
## una didascalia sopra. Se un giorno il posto tornasse com'era ricaricando il
## mondo, il lotto avrebbe perso il suo unico motivo di esistere e nessun altro
## audit se ne accorgerebbe.
##
## Tre mondi e non ventiquattro: costruire una scena di mondo costa, il catalogo
## è già coperto altrove, e qui interessa il percorso — che è lo stesso ovunque.
## I tre scelti hanno tre forme diverse apposta.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
## Mondo 1 riaccendere, mondo 4 spegnere, mondo 10 liberare. La forma «riparare»
## è coperta dalla stessa strada (è l'unica che non tocca né la luce né l'energia).
const MONDI := [1, 4, 10]

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = level
	initial["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	# Energia sufficiente ad aprire l'incarico anche quando costa una volta e
	# mezzo: qui si prova il percorso, non l'economia.
	initial["energy"] = 200
	var request := NativeWorldState.default_request("minimission-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int, save_data: Dictionary = {}) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	var request := _request_for(level)
	if not save_data.is_empty():
		request["initialSave"] = save_data
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _incarico(world: Node) -> Area2D:
	for node in get_nodes_in_group("enigma_poi"):
		if not (node is Area2D) or node.is_queued_for_deletion():
			continue
		if not world.is_ancestor_of(node):
			continue
		if str((node as Area2D).get_meta("kind", "")) == "minimission":
			return node as Area2D
	return null

func _run() -> void:
	for level in MONDI:
		var world := await _open_world(level)
		var poi := _incarico(world)
		assert(poi != null, "mondo %d senza incarico sulla mappa" % level)
		var payload: Dictionary = poi.get_meta("payload", {})
		var atteso := MinimissionCatalog.incarico(level)
		assert(str(payload.get("forma", "")) == str(atteso["forma"]),
			"mondo %d: il POI porta la forma sbagliata" % level)
		assert(str(payload.get("titolo", "")) == str(atteso["titolo"]),
			"mondo %d: il POI non porta il titolo dell'incarico" % level)
		# Il guasto si vede prima di interagire: senza, il bambino non ha nessun
		# motivo di avvicinarsi, che è il difetto da cui il lotto nasce.
		assert(poi.get_node_or_null("IncaricoGuasto") != null,
			"mondo %d: nessun segno visibile del guasto" % level)
		assert(poi.get_node_or_null("IncaricoEsito") == null,
			"mondo %d: l'esito è già disegnato su un incarico aperto" % level)

		var gameplay := world.get("gameplay") as OutdoorGameplay
		var id := str(poi.get_meta("id", ""))
		var aperta: bool = gameplay.try_start_minimission(payload, id)
		assert(aperta, "mondo %d: l'incarico non si apre" % level)
		var sessione: Dictionary = gameplay.active_session_context
		assert(str(sessione.get("kind", "")) == "minimission",
			"mondo %d: tipo di sessione errato" % level)
		assert(str(sessione.get("theme", "")) == str(atteso["forma"]),
			"mondo %d: la resa userebbe il tema di un enigma" % level)

		# Superata: il mondo deve cambiare.
		var nodi := 3
		world.call("_on_exercise_finished", {
			"kind": "minimission",
			"subject": str(payload.get("subject", "matematica")),
			"correct": nodi,
			"total": nodi,
			"passed": true,
			"energyGained": 10,
			"topicStats": {},
		})
		await process_frame
		await process_frame
		var save = gameplay.game_save
		assert(save.has_minimission(level),
			"mondo %d: la riparazione non risulta fatta nel salvataggio" % level)
		assert(poi.get_node_or_null("IncaricoEsito") != null,
			"mondo %d: il mondo non è cambiato dopo la riparazione" % level)
		assert(poi.get_node_or_null("IncaricoGuasto") == null,
			"mondo %d: il guasto è ancora disegnato dopo la riparazione" % level)
		if str(atteso["forma"]) == MinimissionCatalog.FORMA_RIACCENDERE:
			assert(WorldLight.prove_nel_mondo(save, str(level)) >= 4,
				"mondo %d: riaccendere non ha scoperto niente" % level)

		# **Resta cambiato.** Si riapre il mondo con quel salvataggio: l'esito
		# deve essere già lì, e il guasto no.
		var snapshot: Dictionary = save.snapshot()
		world.queue_free()
		await process_frame
		var ritorno := await _open_world(level, snapshot)
		var poi2 := _incarico(ritorno)
		if poi2 != null:
			assert(poi2.get_node_or_null("IncaricoEsito") != null,
				"mondo %d: rientrando, il posto è tornato com'era" % level)
			assert(not poi2.is_in_group("world_interactable"),
				"mondo %d: una riparazione fatta si può rifare" % level)
		ritorno.queue_free()
		await process_frame

	print("MINIMISSION SCENE audit VERDE")
	quit(0)
