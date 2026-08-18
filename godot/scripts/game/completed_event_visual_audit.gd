extends SceneTree

## Rilievo C-P6 #3: una missione conclusa deve lasciare la trasformazione
## ambientale, non la sfera/caption né un'area ancora interagibile. Verifica sia
## l'idratazione dal save sia la dissolvenza nel percorso live.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const PERSISTED_MISSION_ID := "evt-1-gate-2"

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	initial["worldProgress"] = {
		"1": {
			"completedEncounterIds": [PERSISTED_MISSION_ID],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {},
		},
	}
	var request := NativeWorldState.default_request("completed-event-visual-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

## Il segno che una tappa è ancora DA FARE. Erano la sfera e la caption; nel
## mondo 1, per matematica, la sfera è stata sostituita da `World1ActivitySite` —
## il sito di attività della fetta verticale. L'audit cercava solo la sfera, e nel
## mondo 1 non ne trovava più nessuna: rosso da settimane su un gioco sano.
##
## Qui si chiede il concetto, non il nodo: esiste un richiamo visivo, e non è
## ancora nello stato «fatto».
func _richiamo_vivo(area: Area2D) -> bool:
	if area.get_node_or_null("EventMarker") != null:
		return true
	var sito := area.get_node_or_null("World1ActivitySite")
	return sito != null and not bool(sito.get("completed"))

func _assert_retired(area: Area2D, context: String) -> void:
	assert(bool(area.get_meta("completed", false)), "%s: stato visuale non completato" % context)
	assert(area.get_node_or_null("EventMarker") == null, "%s: sfera ancora visibile" % context)
	assert(area.get_node_or_null("EventCaption") == null, "%s: caption ancora visibile" % context)
	# Il sito di attività non si rimuove — è la trasformazione conquistata — ma
	# deve passare allo stato «fatto», altrimenti continua a invitare.
	var sito := area.get_node_or_null("World1ActivitySite")
	assert(sito == null or bool(sito.get("completed")),
		"%s: il sito di attività invita ancora" % context)
	assert(area.get_node_or_null("LearningReaction") != null, "%s: trasformazione ottenuta rimossa" % context)
	assert(bool(area.get_node("LearningReaction").get("completed")), "%s: trasformazione non completa" % context)
	assert(not area.is_in_group("world_interactable") and not area.is_in_group("mission_poi"),
		"%s: missione conclusa ancora interagibile" % context)
	var collision := area.get_node("EventCollision") as CollisionShape2D
	assert(collision.disabled, "%s: collisione della missione ancora attiva" % context)

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

	var persisted := world.find_child(
		"MissionEvent_%s" % PERSISTED_MISSION_ID.replace("-", "_"), true, false) as Area2D
	assert(persisted != null, "fixture persistita non istanziata")
	assert(str(persisted.get_meta("kind", "")) == "encounter", "la fixture deve essere una sfera ordinaria")
	_assert_retired(persisted, "caricamento save")

	var live: Area2D = null
	for node in get_nodes_in_group("mission_poi"):
		if node is Area2D and world.is_ancestor_of(node) and str(node.get_meta("kind", "")) == "encounter":
			if _richiamo_vivo(node as Area2D):
				live = node as Area2D
				break
	assert(live != null, "manca una missione live da completare")
	var live_id := str(live.get_meta("id", ""))
	var player := world.get("player") as CharacterBody2D
	var owner_id := str(Dictionary(live.get_meta("payload", {})).get("ownerNpc", ""))
	if owner_id != "":
		world.call("_open_npc_dialogue", owner_id)
		var request_box := world.get("dialogue_box") as Control
		assert(request_box.visible, "richiesta del proprietario non mostrata")
		request_box.call("close_dialogue")
		await process_frame
	player.global_position = live.global_position
	world.call("on_interactable_entered", live, player)
	world.call("_interact")
	await process_frame
	var exercise := world.get("exercise_player") as ExercisePlayer
	assert(exercise.visible and str(exercise.session.get("kind", "")) == "mission")
	world.call("_on_exercise_finished", {
		"kind": "mission",
		"subject": str(exercise.session.get("subject", "matematica")),
		"correct": 3,
		"total": 3,
		"passed": true,
		"energyGained": 30,
		"topicStats": {},
	})
	await process_frame
	await create_timer(0.45).timeout
	assert(Array(world.get("result").get("completedEncounterIds", [])).has(live_id),
		"completamento live non persistito nel risultato")
	_assert_retired(live, "completamento live")

	await _cleanup(world)
	print("COMPLETED EVENT VISUAL audit OK — sfera ritirata, trasformazione persistente, nessuna interazione fantasma")
	quit(0)
