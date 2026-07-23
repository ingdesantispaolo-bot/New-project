extends SceneTree

## Gate visuale C-P5, ondata A. Verifica in modo isolato i mondi 3–4 senza
## dipendere dai contenuti curricolari O-P5 ancora in consegna.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 4
	initial["worlds"] = {"unlocked": [1, 2, 3, 4], "current": level}
	var request := NativeWorldState.default_request("p5-wave-a-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int) -> Node:
	print("P5 WAVE A audit — caricamento mondo %d" % level)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	# Un solo chunk basta per verificare l'integrazione della scena; i budget
	# Web/HLOD vengono controllati separatamente sui valori autorati.
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	print("P5 WAVE A audit — scena mondo %d pronta" % level)
	return world

func _dispose(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _assert_wave_world(world: Node, level: int, theme: String, landmark_kind: String) -> Dictionary:
	var profile: Dictionary = world.get("world_profile")
	assert(int(profile.get("level", 0)) == level, "profilo scena errato")
	var chunks: OutdoorChunkManager = world.get("chunks")
	var composition := chunks.composition
	assert(composition.visual_theme == theme, "tema visuale errato per mondo %d" % level)
	assert(composition.paths.size() >= 3, "topologia autorata insufficiente")
	assert(composition.identity_regions.size() >= 3, "regioni identitarie insufficienti")
	assert(composition.identity_props.size() >= 5, "props identitari insufficienti")
	assert(composition.protected_corridors.size() == 1, "corridoio nave assente")

	var portal := world.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null and portal.global_position.distance_to(profile["shipEntrance"]["position"]) < 0.01,
		"ingresso nave non coincide con WorldProfile")
	assert(world.find_child("ShipEntrance_*", true, false) != null, "ingresso nave non autorato")
	var hero := world.find_child("ProfileHeroLandmark", true, false) as Node2D
	assert(hero != null and str(hero.get_meta("landmark_kind", "")) == landmark_kind,
		"landmark eroe errato")
	var semantics := WorldLessonCatalog.environment_transform(level)
	assert(str(hero.get_meta("transform_trigger", "")) == str(semantics["trigger"])
		and str(hero.get_meta("transform_effect", "")) == str(semantics["effect"]),
		"il landmark non consuma environmentTransform")
	assert(hero.global_position.distance_to(portal.global_position) > float(profile["shipEntrance"]["safeRadius"]),
		"landmark dentro la zona nave")
	var profile_reaction := world.find_child("ProfileEnvironmentTransform", true, false)
	assert(profile_reaction != null
		and str(profile_reaction.get_meta("transform_effect", "")) == str(semantics["effect"]),
		"trasformazione globale del profilo assente")

	var first_event := world.find_child("MissionEvent_*", true, false)
	assert(first_event != null, "nessuna missione visualizzata")
	var reaction := first_event.get_node_or_null("LearningReaction")
	assert(reaction != null and Array(reaction.get("active_parts")).size() == 5,
		"trasformazione ambientale progressiva assente")
	assert(str(reaction.get_meta("transform_trigger", "")) == str(semantics["trigger"]),
		"il POI non consuma il trigger didattico")
	var gate_event: Dictionary = {}
	for event_data in world.get("mission_events"):
		if bool(event_data.get("countsForGate", false)):
			gate_event = event_data
			break
	assert(not gate_event.is_empty(), "evento gate assente")
	var result_state: Dictionary = world.get("result")
	var completed_ids: Array = result_state.get("completedEncounterIds", [])
	completed_ids.append(str(gate_event["id"]))
	result_state["completedEncounterIds"] = completed_ids
	world.set("result", result_state)
	var hero_art := hero.find_child("Landmark*Art", true, false) as CanvasItem
	var inactive_color := hero_art.modulate
	world.call("_sync_profile_environment_transform", false)
	var visible_profile_parts := 0
	for part in profile_reaction.get("active_parts"):
		if part.visible:
			visible_profile_parts += 1
	assert(visible_profile_parts > 0, "il successo didattico non trasforma il landmark globale")
	assert(hero_art.modulate != inactive_color, "il landmark non riflette il progresso didattico")

	var budget: Dictionary = profile["performanceBudget"]["web"]
	var mission_pois := world.get_tree().get_nodes_in_group("mission_poi").size()
	assert(mission_pois <= int(budget["maxActivePois"]), "POI oltre il budget Web")
	var web_stream_radius := floori(float(budget["streamRadius"]) / float(OutdoorChunkManager.CHUNK_SIZE))
	assert(web_stream_radius <= 1, "il tier Web deve mantenere al massimo 9 chunk residenti")
	assert(chunks.active_radius <= 2, "streaming oltre il raggio HLOD previsto")
	assert(chunks.loaded.size() <= 25, "troppi chunk residenti")

	var underpaint_name := (
		"res://assets/cratere-logico-underpaint-v1.png"
		if level == 3 else
		"res://assets/baia-segnali-underpaint-v1.png"
	)
	assert(ResourceLoader.exists(underpaint_name), "underpaint identitario mancante")
	var landmark_texture_path := (
		"res://assets/cratere-cycle-machine-v1.png"
		if level == 3 else
		"res://assets/baia-radio-lighthouse-v1.png"
	)
	var landmark_texture := load(landmark_texture_path) as Texture2D
	assert(landmark_texture != null, "texture landmark mancante")
	var landmark_image := landmark_texture.get_image()
	assert(landmark_image != null and landmark_image.get_pixel(0, 0).a < 0.05,
		"il landmark deve avere sfondo realmente trasparente")
	return {
		"theme": composition.visual_theme,
		"pathSignature": composition.paths.map(func(path): return str(path["id"])),
		"regionSignature": composition.identity_regions.map(func(region): return str(region["kind"])),
		"waterCount": composition.waters.size(),
		"loadedChunks": chunks.loaded.size(),
		"missionPois": mission_pois,
	}

func _run() -> void:
	print("P5 WAVE A audit — avvio")
	var crater_world := await _open_world(3)
	var crater := _assert_wave_world(crater_world, 3, "crater", "cycleMachine")
	await _dispose(crater_world)

	var bay_world := await _open_world(4)
	var bay := _assert_wave_world(bay_world, 4, "signal_bay", "signalLighthouse")
	await _dispose(bay_world)

	assert(crater["pathSignature"] != bay["pathSignature"], "i mondi condividono la topologia")
	assert(crater["regionSignature"] != bay["regionSignature"], "i mondi condividono l'architettura")
	assert(int(crater["waterCount"]) == 0 and int(bay["waterCount"]) == 2,
		"la Baia deve avere canali, il Cratere deve essere asciutto")
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.queue_free()
		audio.set("_stream_cache", {})
	await process_frame
	await process_frame
	print("P5 WAVE A audit OK — mondi 3/4 distinti, nave, landmark, reazioni, HLOD e budget Web")
	quit(0)
