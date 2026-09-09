extends SceneTree

## Vertical slice reale: la Sciarpa del mondo 1 viene portata nel mondo 13,
## costruisce un POI fisico e richiede un gesto prima di registrare la risonanza.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 13
	initial["worlds"] = {"unlocked": range(1, 14), "current": 13}
	initial["cosmetics"] = {
		"unlocked": ["accessory-scarf", "avatar-gold", "pet-comet", "emblem-atom"],
		"equipped": {
			"accessory": "accessory-scarf", "avatar": "avatar-gold",
			"pet": "pet-comet", "emblem": "emblem-atom"},
		"inventory": [],
		"loadout": [],
		"mementoDisplayed": "accessory-scarf",
	}
	var request := NativeWorldState.default_request("artifact-resonance-scene-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 13
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var site := world.find_child("ArtifactResonance", true, false) as Area2D
	assert(site != null, "la Sciarpa esposta non crea il POI nel mondo 13")
	assert(not bool(site.get_meta("completed", true)),
		"la risonanza risulta completata prima del gesto")
	assert(site.get_node_or_null("ResonanceVisual/ResonanceRing") != null,
		"il POI non ha una forma leggibile")
	var player = world.get("player")
	assert(player != null and player.get("visual").get_node_or_null("OutfitPatina") != null,
		"la prima spedizione non lascia una patina visibile sulla tuta")
	var pet = world.get("pet_companion")
	assert(pet != null and pet.get_node_or_null("JourneyMark") != null,
		"la forma del Custode non rende visibile la propria biografia")
	world.call("_activate_artifact_resonance", site)
	assert(bool(site.get_meta("completed", false)), "il gesto non completa il POI")
	var save: GameSaveManager = world.get("game_save")
	var journey: Dictionary = save.data.get("artifactJourney", {})
	assert(Array(journey.get("resonances", [])).has("accessory-scarf:13"),
		"la scena non persiste la risonanza 1->13")
	var interaction_button := world.get("interaction_button") as Button
	if interaction_button != null:
		world.call("_refresh_interaction_button", site)
		assert(interaction_button.disabled, "il POI completato resta azionabile")

	root.remove_child(world)
	world.queue_free()
	print("Artifact resonance scene audit OK — Sciarpa 1->13 visibile, agita e persistente")
	quit(0)
