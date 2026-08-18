extends SceneTree

## Integrazione C-ART-5/6 sui mondi reali: non basta che cataloghi e widget
## esistano separati. Qui i beat chiudono nel pannello, Squadra usa il proprio
## reperto, Orsolo il proprio pool e il caso profondo resta sull'attore finché
## una prova della sua materia non lo ricompone.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request(world_level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = world_level
	initial["worlds"] = {"unlocked": range(1, world_level + 1), "current": world_level}
	initial["narrative"] = {"tracesSeen": ["21"]}
	var request := NativeWorldState.default_request("c-art-world-staging-%d" % world_level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["accessibility"] = {"reducedMotion": true, "highContrast": false}
	request["accessibilityExplicit"] = true
	request["stageNarrativeBeatsInFixture"] = true
	return request

func _open_world(world_level: int) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request(world_level))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _run() -> void:
	root.size = Vector2i(900, 600)
	await _assert_tredicesimo_choice()
	await _assert_world_23_staging()
	print("C-ART world staging audit OK — quattro scelte in scena, smemora profondo visibile fino alla prova")
	quit(0)

func _assert_tredicesimo_choice() -> void:
	var world := await _open_world(22)
	await create_timer(2.55).timeout
	var dialogue: DialogueBox = world.get("dialogue_box")
	assert(dialogue.visible and dialogue.npc_id == "stance-beat-tredicesimo-domanda",
		"la domanda del Tredicesimo non entra in scena nel mondo 22")
	dialogue.close_dialogue()
	await process_frame
	_assert_open_choice(world, "tredicesimo-domanda")
	_press_first_choice(world)
	await process_frame
	dialogue.close_dialogue()
	assert(StanceChoices.risposta(world.get("game_save").data, "tredicesimo-domanda") != "",
		"la domanda del Tredicesimo non resta nel save")
	await _cleanup(world)

func _assert_world_23_staging() -> void:
	var world := await _open_world(23)
	var save: GameSaveManager = world.get("game_save")
	var deep_id := str(world.get("thirteenth_deep_forgotten_npc"))
	assert(deep_id != "" and not NpcCatalog.resident(deep_id).is_empty(),
		"smemora profondo non sceglie un residente nel mondo 23")
	assert(deep_id != str(world.call("_active_mission_owner")),
		"smemora profondo colpisce il proprietario della missione")
	var deep_actor: Area2D = null
	for actor in world.get("npc_actors"):
		if str(actor.get_meta("id", "")) == deep_id:
			deep_actor = actor
			break
	assert(deep_actor != null and bool(deep_actor.get_meta("deep_forgotten", false)),
		"il caso profondo esiste nel save ma non sull'attore")

	# Meridiana arriva dai sensori lunghi, poi apre il pannello.
	await create_timer(2.55).timeout
	var dialogue: DialogueBox = world.get("dialogue_box")
	assert(dialogue.visible and dialogue.npc_id == "stance-beat-meridiana-riga",
		"la riga di Meridiana non arriva sui sensori lunghi")
	dialogue.close_dialogue()
	await process_frame
	_assert_open_choice(world, "meridiana-riga")
	_press_first_choice(world)
	await process_frame
	dialogue.close_dialogue()

	# Orsolo usa esattamente `prova_accettata`; chiuderla apre la sua scelta.
	world.call("_open_npc_dialogue", "itin-orsolo")
	assert(dialogue.visible and Array(dialogue.screens).size() > 0,
		"Orsolo non mostra la prova accettata")
	assert("più piano" in " ".join(PackedStringArray(dialogue.screens)).to_lower(),
		"il «mah» non si fa più piano")
	dialogue.close_dialogue()
	await process_frame
	_assert_open_choice(world, "orsolo-prova")
	_press_first_choice(world)
	await process_frame
	dialogue.close_dialogue()

	# La scelta di Squadra nasce dal suo fascicolo, non da una voce generica.
	var squad_artifact: Area2D = null
	for artifact in get_nodes_in_group("world_interactable"):
		if artifact is Area2D and world.is_ancestor_of(artifact):
			var payload: Dictionary = artifact.get_meta("payload", {})
			if str(payload.get("sorella", "")) == "Squadra":
				squad_artifact = artifact
				break
	assert(squad_artifact != null, "il fascicolo di Squadra non è nel mondo 23")
	world.call("_open_mystery_artifact", squad_artifact)
	dialogue.close_dialogue()
	await process_frame
	_assert_open_choice(world, "squadra-quaderno")
	_press_first_choice(world)
	await process_frame
	dialogue.close_dialogue()

	# Parlarci non basta: il visuale e l'override restano. Solo la prova della
	# sua materia li ricompone, mostrando anche il lampo di ritorno.
	# Prima rendiamo irrilevanti le richieste di questa fixture: il proprietario
	# ha precedenza per contratto ed è verificato dagli audit missione.
	var ownership = world.get("mission_ownership_flow")
	ownership.set("_completed", world.get("mission_events").map(
		func(event): return str((event as Dictionary).get("id", ""))))
	var protected_state := {
		"energy": save.energy(),
		"missions": save.data.get("missionProgress", {}).duplicate(true),
		"mastery": save.data.get("mastery", {}).duplicate(true),
	}
	world.call("_open_npc_dialogue", deep_id)
	assert(dialogue.visible and "scopo" in dialogue.role_label.text.to_lower(),
		"il dialogo profondo non sostituisce quello ordinario")
	dialogue.close_dialogue()
	await process_frame
	assert(str(world.get("thirteenth_deep_forgotten_npc")) == deep_id \
		and bool(deep_actor.get_meta("deep_forgotten", false)),
		"parlare ha risolto il caso profondo")
	assert(save.energy() == int(protected_state["energy"])
		and save.data.get("missionProgress", {}) == protected_state["missions"]
		and save.data.get("mastery", {}) == protected_state["mastery"],
		"smemora profondo ha toccato energia, missioni o mastery")
	var subject := NpcArc.materia_di(deep_id)
	world.get("gameplay").active_session_context = {
		"kind": "minigame", "encounterId": "", "subject": subject}
	world.call("_on_exercise_finished", {
		"kind": "minigame", "subject": subject, "correct": 1, "total": 1,
		"passed": true, "energyGained": 0, "topicStats": {}, "seconds": 1.0,
	})
	await process_frame
	assert(str(world.get("thirteenth_deep_forgotten_npc")) == "",
		"la prova della materia non restituisce il mestiere")
	assert(not bool(deep_actor.get_meta("deep_forgotten", true))
		and bool(deep_actor.get_meta("deep_memory_return_visible", false)),
		"il ritorno passa soltanto dal dialogo")
	dialogue.close_dialogue()
	await _cleanup(world)

func _assert_open_choice(world: Node, choice_id: String) -> void:
	var panel: TeachingChoicePanel = world.get("teaching_choice_panel")
	assert(panel != null and panel.visible, "%s: il pannello non si apre" % choice_id)
	assert(str(world.get_meta("last_stance_choice_opened", "")) == choice_id,
		"%s: si è aperta la scelta sbagliata" % choice_id)
	assert(panel.find_child("SkipChoice", true, false) != null,
		"%s: la scelta non è saltabile" % choice_id)

func _press_first_choice(world: Node) -> void:
	var panel: TeachingChoicePanel = world.get("teaching_choice_panel")
	var button := panel.choices.get_child(0) as Button
	button.pressed.emit()

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
	await create_timer(0.12).timeout
