extends SceneTree

## Gate visuale C-P5, ondata C. Verifica i mondi 9–12 in scene reali:
## topologie, ingresso nave, landmark, semantica, reazioni e budget Web/mobile.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

const SPECS := {
	9: {
		"theme": "charted_archipelago",
		"landmark": "cartographyTower",
		"underpaint": "res://assets/arcipelago-cartografico-underpaint-v1.png",
		"texture": "res://assets/arcipelago-torre-cartografica-v1.png",
		"water": 3,
	},
	10: {
		"theme": "symbiosis_greenhouse",
		"landmark": "livingDome",
		"underpaint": "res://assets/serra-simbiosi-underpaint-v1.png",
		"texture": "res://assets/serra-cupola-vivente-v1.png",
		"water": 2,
	},
	11: {
		"theme": "civic_city",
		"landmark": "pactPalace",
		"underpaint": "res://assets/citta-patti-underpaint-v1.png",
		"texture": "res://assets/citta-palazzo-patti-v1.png",
		"water": 0,
	},
	12: {
		"theme": "rule_labyrinth",
		"landmark": "labyrinthHeart",
		"underpaint": "res://assets/labirinto-regole-underpaint-v1.png",
		"texture": "res://assets/labirinto-cuore-regole-v1.png",
		"water": 0,
	},
}

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 12
	initial["worlds"] = {"unlocked": range(1, 13), "current": level}
	var request := NativeWorldState.default_request("p5-wave-c-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int) -> Node:
	print("P5 WAVE C audit — caricamento mondo %d" % level)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _dispose(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _assert_world(world: Node, level: int, spec: Dictionary) -> Dictionary:
	var profile: Dictionary = world.get("world_profile")
	assert(int(profile.get("level", 0)) == level, "profilo scena errato")
	var chunks: OutdoorChunkManager = world.get("chunks")
	var composition := chunks.composition
	assert(composition.visual_theme == spec["theme"], "tema errato per mondo %d" % level)
	assert(composition.paths.size() >= 3, "topologia autorata insufficiente")
	assert(composition.identity_regions.size() >= 2, "regioni identitarie insufficienti")
	assert(composition.identity_props.size() >= 5, "props identitari insufficienti")
	assert(composition.protected_corridors.size() == 1, "corridoio nave assente")
	assert(composition.waters.size() == int(spec["water"]), "firma acqua errata")

	var portal := world.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null and portal.global_position.distance_to(profile["shipEntrance"]["position"]) < 0.01,
		"ingresso nave non coincide con WorldProfile")
	assert(world.find_child("ShipEntrance_*", true, false) != null, "ingresso nave non autorato")
	var hero := world.find_child("ProfileHeroLandmark", true, false) as Node2D
	assert(hero != null and str(hero.get_meta("landmark_kind", "")) == str(spec["landmark"]),
		"landmark eroe errato")
	var semantics := WorldLessonCatalog.environment_transform(level)
	assert(str(hero.get_meta("transform_trigger", "")) == str(semantics["trigger"])
		and str(hero.get_meta("transform_effect", "")) == str(semantics["effect"]),
		"il landmark non consuma environmentTransform")
	assert(hero.global_position.distance_to(portal.global_position) > float(profile["shipEntrance"]["safeRadius"]),
		"landmark dentro la zona nave")
	var hero_art := hero.find_child("Landmark*Art", true, false) as CanvasItem
	assert(hero_art != null, "arte landmark nominata assente")
	var profile_reaction := world.find_child("ProfileEnvironmentTransform", true, false)
	assert(profile_reaction != null
		and Array(profile_reaction.get("active_parts")).size() == 5
		and str(profile_reaction.get_meta("transform_effect", "")) == str(semantics["effect"]),
		"trasformazione globale assente")

	var first_event := world.find_child("MissionEvent_*", true, false)
	assert(first_event != null, "nessuna missione visualizzata")
	var reaction := first_event.get_node_or_null("LearningReaction")
	assert(reaction != null
		and Array(reaction.get("active_parts")).size() == 5
		and str(reaction.get_meta("transform_trigger", "")) == str(semantics["trigger"]),
		"reazione locale assente")
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
	var inactive_color := hero_art.modulate
	world.call("_sync_profile_environment_transform", false)
	var visible_parts := 0
	for part in profile_reaction.get("active_parts"):
		if part.visible:
			visible_parts += 1
	assert(visible_parts > 0 and hero_art.modulate != inactive_color,
		"il progresso didattico non modifica l’ambiente")

	for tier in ["web", "mobile"]:
		var budget: Dictionary = profile["performanceBudget"][tier]
		var mission_pois := world.get_tree().get_nodes_in_group("mission_poi").size()
		assert(mission_pois <= int(budget["maxActivePois"]), "POI oltre budget %s" % tier)
		assert(floori(float(budget["streamRadius"]) / float(OutdoorChunkManager.CHUNK_SIZE)) <= 1,
			"streaming oltre budget %s" % tier)
	assert(chunks.active_radius <= 2 and chunks.loaded.size() <= 25, "troppi chunk residenti")

	assert(ResourceLoader.exists(str(spec["underpaint"])), "underpaint mancante")
	var landmark_texture := load(str(spec["texture"])) as Texture2D
	assert(landmark_texture != null, "texture landmark mancante")
	var landmark_image := landmark_texture.get_image()
	assert(landmark_image != null and landmark_image.get_pixel(0, 0).a < 0.05,
		"il landmark deve avere sfondo realmente trasparente")
	return {
		"path": composition.paths.map(func(path): return str(path["id"])),
		"regions": composition.identity_regions.map(func(region): return str(region["kind"])),
		"props": composition.identity_props.map(func(prop): return str(prop["kind"])),
	}

func _cleanup_audio() -> void:
	var audio := root.get_node_or_null("NativeAudio")
	if audio == null:
		return
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
				child.queue_free()
	audio.set("_stream_cache", {})

func _run() -> void:
	print("P5 WAVE C audit — avvio")
	var signatures: Array[Dictionary] = []
	for level in range(9, 13):
		var world := await _open_world(level)
		signatures.append(_assert_world(world, level, SPECS[level]))
		await _dispose(world)
	for left in range(signatures.size()):
		for right in range(left + 1, signatures.size()):
			assert(signatures[left]["path"] != signatures[right]["path"], "topologie duplicate")
			assert(signatures[left]["regions"] != signatures[right]["regions"], "architetture duplicate")
			assert(signatures[left]["props"] != signatures[right]["props"], "kit prop duplicati")
	_cleanup_audio()
	await process_frame
	await create_timer(0.10).timeout
	print("P5 WAVE C audit OK — mondi 9/12 distinti, semantica, nave, reazioni e budget")
	quit(0)
