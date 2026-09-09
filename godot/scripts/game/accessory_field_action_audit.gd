extends SceneTree

## Verifica sia il contratto 9/9 sia una rotta fisica completa. Il Jetpack e'
## scelto perche' rende evidente la proprieta' decisiva della meccanica: ogni
## tappa cambia posizione e non puo' essere consumata restando fermi.

const ACTIONS := preload("res://scripts/game/accessory_field_actions.gd")
const ArtifactJourney := preload("res://scripts/game/artifact_journey.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PROTECTED_KEYS := [
	"level", "energy", "mastery", "masteryByTopic", "coverageThisLevel",
	"gateClearedLevel", "missionsBySubject", "apparatus", "worldProgress",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_audit_contract()
	var initial := GameSaveManager._default_data()
	initial["level"] = 9
	initial["energy"] = 37
	initial["worlds"] = {"unlocked": range(1, 10), "current": 9}
	initial["cosmetics"] = {
		"unlocked": ["accessory-jetpack", "avatar-gold"],
		"equipped": {"accessory": "accessory-jetpack", "avatar": "avatar-gold"},
		"inventory": [], "loadout": [], "mementoDisplayed": "",
	}
	var world: Node = await _build_world(initial)
	var site := world.find_child("AccessoryFieldAction", true, false) as Area2D
	assert(site != null, "il Jetpack equipaggiato non crea la rotta nel mondo")
	assert(str(site.get_meta("accessory_id", "")) == "accessory-jetpack",
		"la rotta non appartiene all'accessorio equipaggiato")
	assert(not bool(site.get_meta("completed", true)),
		"una rotta nuova risulta gia' completata")
	assert(site.get_node_or_null("AccessoryFieldVisual/AccessoryFieldCue") != null,
		"la rotta non rende leggibile la tappa corrente")
	var save: GameSaveManager = world.get("game_save")
	var protected := _snapshot(save)
	var first_position := site.position
	world.call("_advance_accessory_field_action", site)
	assert(site.position != first_position, "la prima tappa non richiede uno spostamento")
	assert(int(Dictionary(site.get_meta("payload", {})).get("stage", 0)) == 1,
		"la prima tappa non avanza la sequenza")
	var second_position := site.position
	world.call("_advance_accessory_field_action", site)
	assert(site.position != second_position, "la seconda tappa non richiede uno spostamento")
	world.call("_advance_accessory_field_action", site)
	assert(bool(site.get_meta("completed", false)), "la terza tappa non chiude la rotta")
	assert(world.find_child("AccessoryRouteLeg1", true, false) != null,
		"il percorso non lascia una traccia visibile nel mondo")
	var state: Dictionary = ArtifactJourney.item_state(save, "accessory-jetpack")
	assert(Array(state.get("events", [])).has(
		ACTIONS.event_signature("accessory-jetpack", 9)),
		"la rotta completa non entra nella biografia del Jetpack")
	_assert_unchanged(save, protected)
	var interaction_button := world.get("interaction_button") as Button
	if interaction_button != null:
		world.call("_refresh_interaction_button", site)
		assert(interaction_button.disabled, "una rotta completa resta azionabile")

	var persisted := save.data.duplicate(true)
	root.remove_child(world)
	world.queue_free()
	await process_frame
	var revisited: Node = await _build_world(persisted)
	var revisited_site := revisited.find_child("AccessoryFieldAction", true, false) as Area2D
	assert(revisited_site != null and bool(revisited_site.get_meta("completed", false)),
		"rientrando nel mondo la rotta del Jetpack dimentica il completamento")
	root.remove_child(revisited)
	revisited.queue_free()
	print("Accessory field action audit OK — 9 profili, rotta in tre tappe e persistenza")
	quit(0)

func _audit_contract() -> void:
	var catalog_ids: Array = []
	for item_data in RewardCatalog.by_slot("accessory"):
		catalog_ids.append(str(Dictionary(item_data).get("id", "")))
	var action_ids := ACTIONS.ids()
	assert(catalog_ids.size() == 9 and action_ids.size() == 9,
		"catalogo e azioni devono contenere esattamente nove accessori")
	for id_data in catalog_ids:
		var id := str(id_data)
		assert(action_ids.has(id), "%s non ha un'azione ambientale" % id)
		var action := ACTIONS.action(id)
		assert(not str(action.get("title", "")).is_empty(), "%s non ha titolo" % id)
		assert(not str(action.get("action", "")).is_empty(), "%s non ha verbo" % id)
		assert(Array(action.get("steps", [])).size() == 3, "%s non ha tre tappe" % id)
		assert(not str(action.get("completion", "")).is_empty(), "%s non ha chiusura NORA" % id)
		assert(Array(ArtifactJourney.profile(id).get("events", [])).has(ACTIONS.EVENT_KIND),
			"%s non puo' registrare la conclusione della propria rotta" % id)

func _build_world(initial: Dictionary) -> Node:
	var request := NativeWorldState.default_request("accessory-field-action-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 9
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	return world

func _snapshot(save: GameSaveManager) -> Dictionary:
	var out: Dictionary = {}
	for key in PROTECTED_KEYS:
		out[key] = save.data.get(key, null)
	return out.duplicate(true)

func _assert_unchanged(save: GameSaveManager, before: Dictionary) -> void:
	for key in PROTECTED_KEYS:
		assert(save.data.get(key, null) == before.get(key, null),
			"l'azione dell'accessorio modifica il campo vietato %s" % key)
