extends SceneTree

## **Il Custode legge il mondo: curioso su un incontro, attento vicino a uno
## Sbiadito.** (5 agosto 2026, docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B, punto 6)
##
## `near_unexplored`/`near_faded` erano dichiarati in `pet_expression_engine.gd`
## dal primo giorno del Custode e non erano mai stati emessi: due segnali morti
## quanto lo starnuto lo era prima di questa settimana. Questo audit prova che
## ora partono, che si fermano da soli, e che non reagiscono a quello che non
## conta (portali, landmark, abitanti, un Custode non ancora concesso).
##
## Nessuna delle due reazioni rivela qualcosa che il bambino non veda già:
## l'incontro e lo Sbiadito sono entrambi visibili a schermo. È atmosfera, non
## un vantaggio — coerente con «nessun vantaggio di gioco» del Custode.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = 100
	initial["fragments"] = 0
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("pet-world-awareness-audit")
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

func _run() -> void:
	# Le durate devono restare finite: senza, la faccia resterebbe incollata
	# alla prima occhiata curiosa per il resto della sessione, perché non esiste
	# (e non serve) un segnale esplicito di «te ne sei allontanato».
	assert(PetExpressionEngine.duration_of("curioso") > 0.0,
		"«curioso» a durata indefinita non si pulirebbe mai da solo")
	assert(PetExpressionEngine.duration_of("attento") > 0.0,
		"«attento» a durata indefinita non si pulirebbe mai da solo")

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
	var pet_face: Control = world.get("pet_face")
	var player: Node2D = world.get("player")

	# --- Senza Custode concesso: nessuna delle due reazioni deve partire -------
	var area_finta := Area2D.new()
	area_finta.set_meta("kind", "encounter")
	world.call("_pet_notice_poi", area_finta)
	assert(str(pet_face.call("current_face")) != "curioso",
		"un Custode non concesso ha comunque reagito a un incontro")

	# --- Il Custode concesso -----------------------------------------------
	# «curioso» sblocca a legame 0.25, «attento» a 0.65: un Custode appena
	# concesso non le ha ancora, e `react_to()` rifiuta una faccia non
	# disponibile ripiegando sul volto a riposo. Senza legame pieno qui,
	# l'audit proverebbe solo che il wiring non rompe niente — non che la
	# faccia arriva davvero.
	PetState.grant(save, 1)
	PetState.add_bond(save, 1.0)
	save.save()
	world.call("_refresh_pet_face")
	pet_face = world.get("pet_face")

	# Portale, landmark, abitante: nessuno di questi è «da esplorare».
	for kind in ["portal", "landmark", "npc"]:
		var area := Area2D.new()
		area.set_meta("kind", kind)
		world.call("_pet_notice_poi", area)
		assert(str(pet_face.call("current_face")) != "curioso",
			"il Custode ha reagito a un'area di tipo «%s», che non è un'esplorazione" % kind)
		area.free()

	# Un incontro non completato: qui sì.
	var incontro := Area2D.new()
	incontro.set_meta("kind", "encounter")
	world.call("_pet_notice_poi", incontro)
	assert(str(pet_face.call("current_face")) == "curioso",
		"un incontro non esplorato non ha fatto reagire il Custode")
	incontro.free()

	# La faccia si pulisce da sola: passata la durata, torna disponibile per
	# un'altra reazione anche a priorità pari o minore (qui: di nuovo curiosa).
	await create_timer(PetExpressionEngine.duration_of("curioso") + 0.2).timeout
	assert(str(pet_face.call("current_face")) != "curioso",
		"la faccia curiosa non si è pulita da sola dopo %.1fs" % PetExpressionEngine.duration_of("curioso"))

	# --- Lo Sbiadito ------------------------------------------------------
	assert(str(pet_face.call("current_face")) != "attento",
		"il Custode è già attento prima che ci sia uno Sbiadito nel mondo")
	var enemy := WorldEnemy.new()
	enemy.setup(world, player.global_position + Vector2(60, 0), 1, "matematica", Color("ff7b72"), 0)
	world.get("world_layer").add_child(enemy)
	world.call("_pet_check_faded_proximity")
	assert(str(pet_face.call("current_face")) == "attento",
		"uno Sbiadito a distanza ravvicinata non ha fatto irrigidire il Custode")

	# Fuori dal raggio: il controllo non deve riattivarlo dopo che si è pulito.
	enemy.global_position = player.global_position + Vector2(2000, 0)
	await create_timer(PetExpressionEngine.duration_of("attento") + 0.2).timeout
	world.call("_pet_check_faded_proximity")
	assert(str(pet_face.call("current_face")) != "attento",
		"lo Sbiadito lontano ha comunque fatto reagire il Custode")

	await _cleanup(world)
	print("PET WORLD AWARENESS audit OK — curioso e attento partono, si puliscono da soli, non reagiscono a ciò che non conta")
	quit(0)
