extends SceneTree

## Rilievo C-P6 #9: il fallimento di un enigma non premia, avvia un cooldown
## persistente fra i tentativi e lo rende leggibile nel comando touch. Nessun
## timer viene applicato durante l'esercizio.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = 100
	initial["fragments"] = 0
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("enigma-cooldown-audit")
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
	root.size = Vector2i(900, 600)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request())
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var area: Area2D = null
	for node in get_nodes_in_group("enigma_poi"):
		if node is Area2D and world.is_ancestor_of(node):
			area = node as Area2D
			break
	assert(area != null, "enigma live assente")
	var encounter_id := str(area.get_meta("id", ""))
	var gameplay := world.get("gameplay") as OutdoorGameplay
	var save := gameplay.game_save
	var player := world.get("player") as CharacterBody2D
	var exercise := world.get("exercise_player") as ExercisePlayer
	var button := world.find_child("ContextInteractButton", true, false) as Button
	var fragments_before := save.fragments()
	var energy_before := save.energy()

	player.global_position = area.global_position
	world.call("on_interactable_entered", area, player)
	world.call("_interact")
	await process_frame
	assert(exercise.visible and str(exercise.session.get("kind", "")) == "enigma")
	assert(not bool(exercise.session.get("timed", false)), "l'enigma non deve avere timer durante la prova")
	world.call("_on_exercise_finished", {
		"kind": "enigma",
		"subject": str(exercise.session.get("subject", "matematica")),
		"correct": 0,
		"total": 4,
		"passed": false,
		"energyGained": 0,
		"topicStats": {},
	})
	await process_frame
	assert(save.fragments() == fragments_before, "un enigma fallito ha assegnato frammenti")
	assert(save.energy() == energy_before - OutdoorGameplay.EXERCISE_ENERGY_COST,
		"il tentativo deve consumare solo il costo di ingresso")
	assert(not Array(world.get("result").get("completedEncounterIds", [])).has(encounter_id),
		"enigma fallito marcato come completato")
	var remaining := gameplay.enigma_retry_seconds(encounter_id)
	assert(remaining > 0 and remaining <= OutdoorGameplay.ENIGMA_RETRY_COOLDOWN_SECONDS,
		"cooldown non avviato")
	assert(button.visible and button.disabled and "RICALIBRAZIONE" in button.text,
		"countdown non leggibile sul comando touch")
	var source := world.find_child("FeedbackSource", true, false) as Label
	var feedback := world.find_child("FeedbackText", true, false) as Label
	assert(source != null and source.text == "RICALIBRAZIONE", "feedback negativo senza fonte visuale")
	assert(feedback != null and "nessuna ricompensa" in feedback.text.to_lower(),
		"feedback negativo non spiega la conseguenza")
	var cooldowns: Dictionary = save.world_progress("1").get("enigmaCooldowns", {})
	assert(cooldowns.has(encounter_id), "cooldown non persistito nel mondo")

	var energy_after_failure := save.energy()
	assert(not gameplay.try_start_enigma(area.get_meta("payload"), encounter_id),
		"tentativo immediato non bloccato")
	assert(save.energy() == energy_after_failure, "un tentativo bloccato ha consumato energia")

	# Prova deterministica della scadenza senza attendere nel test.
	save.set_enigma_cooldown("1", encounter_id, 20, 100)
	assert(save.enigma_cooldown_remaining("1", encounter_id, 105) == 15)
	assert(save.enigma_cooldown_remaining("1", encounter_id, 121) == 0)
	world.call("_refresh_prompt")
	assert(not button.disabled and button.text == "RICOSTRUISCI",
		"l'enigma non torna disponibile dopo la scadenza")

	await _cleanup(world)
	print("ENIGMA COOLDOWN audit OK — no reward, costo singolo, feedback touch, persistenza e scadenza")
	quit(0)
