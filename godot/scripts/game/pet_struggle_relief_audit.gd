extends SceneTree

## **Il Custode sdrammatizza al terzo errore sullo stesso argomento.** (4 agosto
## 2026, docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B)
##
## Non aiuta — non deve, è un guard-rail del Custode — e NORA non lo commenta:
## è coerente con «l'errore non ha conseguenze narrative», e qui l'errore è
## proprio la ragione per cui il Custode si muove. Se NORA parlasse in quel
## momento, il gesto smetterebbe di essere una gag e diventerebbe un rimprovero
## travestito da rapporto tecnico.
##
## Due livelli: la logica del conteggio (`ExercisePlayer`, senza scena) e
## l'integrazione nel mondo (il Custode reagisce, NORA resta zitta).

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_prova_conteggio()
	await _prova_integrazione()
	print("PET STRUGGLE RELIEF audit OK — segnale una volta a sessione, Custode reagisce, NORA tace")
	quit(0)

# --- 1. Il conteggio, senza scena --------------------------------------------

func _stesso_argomento(n: int) -> Dictionary:
	var nodes: Array = []
	for i in range(n):
		nodes.append({
			"id": "struggle-audit-%d" % i, "subject": "matematica", "topic": "misure",
			"difficulty": 1, "format": "multiple_choice", "prompt": "Domanda %d" % i,
			"options": ["giusta", "sbagliata-a", "sbagliata-b", "sbagliata-c"],
			"answer": "giusta", "explanation": "",
		})
	return {
		"sessionId": "struggle-audit", "kind": "mission", "subject": "matematica",
		"level": 1, "nodes": nodes, "shields": n + 2, "pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 30, "fragments": 2}},
	}

func _prova_conteggio() -> void:
	var player := ExercisePlayer.new()
	root.add_child(player)
	var segnalati: Array = []
	player.topic_struggle.connect(func(topic): segnalati.append(topic))

	player.start_session(_stesso_argomento(5))
	for i in range(2):
		player.call("_answer", "sbagliata-a")
		player.call("_advance")
	assert(segnalati.is_empty(), "il segnale è partito prima del terzo errore")
	player.call("_answer", "sbagliata-a")
	assert(segnalati == ["misure"], "il terzo errore non ha segnalato l'argomento")
	player.call("_advance")
	player.call("_answer", "sbagliata-a")
	assert(segnalati == ["misure"], "il quarto errore ha segnalato di nuovo: deve essere una volta a sessione")

	# Una nuova sessione azzera il conteggio: non è l'argomento a pesare, è la sessione.
	player.start_session(_stesso_argomento(3))
	segnalati.clear()
	player.call("_answer", "sbagliata-a")
	player.call("_advance")
	player.call("_answer", "sbagliata-a")
	player.call("_advance")
	assert(segnalati.is_empty(), "la sessione precedente non si è azzerata")
	player.call("_answer", "sbagliata-a")
	assert(segnalati == ["misure"], "la nuova sessione non segnala più il terzo errore")

	player.queue_free()

# --- 2. L'integrazione nel mondo ---------------------------------------------

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = 100
	initial["fragments"] = 0
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("pet-struggle-integration-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _cleanup(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.free()
		audio.set("_stream_cache", {})
	await create_timer(0.15).timeout

func _prova_integrazione() -> void:
	root.size = Vector2i(900, 600)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request())
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var gameplay := world.get("gameplay") as OutdoorGameplay
	var save := gameplay.game_save
	# Legame pieno: lo starnuto è sbloccato solo dal legame (0.50), e qui si
	# vuole provare che PARTE, non che manca lo sblocco.
	PetState.grant(save, 1)
	PetState.add_bond(save, 1.0)
	save.save()
	# `_spawn_pet` è già passato una volta in `_ready`, quando il Custode non
	# era ancora concesso: senza rifarlo esplicitamente `pet_companion` resta
	# nullo, esattamente come farebbe `_grant_pet_if_needed` a runtime.
	world.call("_refresh_pet_face")
	world.call("_respawn_pet_companion")
	var pet_companion: Node = world.get("pet_companion")
	assert(pet_companion != null, "il Custode concesso non ha generato un corpo nel mondo")
	pet_companion.call("configure_antics", PetState.antics(save))

	var exercise := world.get("exercise_player") as ExercisePlayer
	var pet_face: Control = world.get("pet_face")
	var feedback_label := world.get("feedback_label") as Label

	gameplay.active_session_context = {
		"kind": "mission", "encounterId": "struggle-integration", "subject": "matematica"}
	exercise.visible = true
	exercise.start_session(_stesso_argomento(4))
	await process_frame

	exercise.call("_answer", "sbagliata-a")
	exercise.call("_advance")
	exercise.call("_answer", "sbagliata-a")
	exercise.call("_advance")
	await process_frame
	feedback_label.text = "PRIMA DEL TERZO ERRORE"
	var antics: Node = pet_companion.get("_antics")
	assert(antics.active_antic() == "", "il Custode sta già facendo qualcosa prima del terzo errore")

	# Il conteggio del duetto è a quota 2: senza il silenzio dedicato, il
	# prossimo starnutire sarebbe ESATTAMENTE il terzo, e il duetto commenterebbe
	# per la regola generale «una combinella su tre». Metterlo qui prova che il
	# silenzio del terzo-errore vince su quella regola, non che la regola non è
	# mai scattata per caso.
	world.set("_pet_antic_count", 2)

	exercise.call("_answer", "sbagliata-a")
	await process_frame

	assert(antics.active_antic() == "sneeze",
		"il terzo errore non ha fatto starnutire il Custode (era: %s)" % antics.active_antic())
	# La faccia non è un contratto di questa funzione: lo stesso evento è anche
	# un errore, e «incoraggiante» (priorità 60) vince legittimamente su
	# «impicciato» (priorità 50) per lo stesso motivo per cui vince sempre dopo
	# una risposta sbagliata. È corretto così — la reazione del volto resta
	# quella del conforto, lo starnuto è un secondo gesto fisico sotto, non un
	# annuncio in faccia che «questo errore è speciale».
	var faccia := str(pet_face.call("current_face"))
	assert(faccia in ["incoraggiante", "impicciato"],
		"faccia inattesa dopo il terzo errore: «%s»" % faccia)
	assert(not PetExpressionEngine.NEGATIVE_FACES.has(faccia),
		"il terzo errore ha prodotto una faccia negativa: «%s»" % faccia)
	assert(feedback_label.text == "PRIMA DEL TERZO ERRORE",
		"NORA ha commentato lo starnuto da terzo errore: «%s»" % feedback_label.text)

	await _cleanup(world)
