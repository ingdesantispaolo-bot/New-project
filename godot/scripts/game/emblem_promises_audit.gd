extends SceneTree

## Cinque promesse, tre testimonianze ciascuna, nessun premio. Verifica anche
## che la promessa completa sia leggibile sul corpo di Eli e non solo nel save.

const PROMISES := preload("res://scripts/game/emblem_promises.gd")
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
	_audit_progress_and_boundary()
	await _audit_visual_completion()
	print("Emblem promises audit OK — 5 promesse, 3 testimonianze, resa visiva")
	quit(0)

func _audit_contract() -> void:
	var catalog_ids: Array = []
	for item_data in RewardCatalog.by_slot("emblem"):
		catalog_ids.append(str(Dictionary(item_data).get("id", "")))
	var promise_ids := PROMISES.ids()
	assert(catalog_ids.size() == 5 and promise_ids.size() == 5,
		"catalogo e promesse devono contenere esattamente cinque emblemi")
	var titles: Dictionary = {}
	for id_data in catalog_ids:
		var id := str(id_data)
		assert(promise_ids.has(id), "%s non ha una promessa" % id)
		var promise := PROMISES.promise(id)
		for field in ["title", "statement", "evidence", "completion"]:
			assert(not str(promise.get(field, "")).strip_edges().is_empty(),
				"%s non dichiara %s" % [id, field])
		assert(int(promise.get("required", 0)) == 3, "%s non richiede tre testimonianze" % id)
		assert(not Array(promise.get("events", [])).is_empty(), "%s non osserva eventi" % id)
		var title := str(promise.get("title", ""))
		assert(not titles.has(title), "due emblemi dichiarano la stessa promessa")
		titles[title] = id

func _audit_progress_and_boundary() -> void:
	var star_state := {"events": [
		"expedition:1:world-01", "expedition:1:seconda", "expedition:4:world-04"]}
	var star_progress := PROMISES.progress("emblem-star", star_state)
	assert(int(star_progress.get("count", 0)) == 2,
		"la Stella conta due volte lo stesso mondo")
	star_state["events"].append("expedition:9:world-09")
	assert(bool(PROMISES.progress("emblem-star", star_state).get("complete", false)),
		"tre mondi non completano la promessa della Stella")

	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var cosmetics: Dictionary = save.data["cosmetics"]
	cosmetics["unlocked"] = ["emblem-crown"]
	cosmetics["equipped"] = {"emblem": "emblem-crown"}
	save.data["cosmetics"] = cosmetics
	var protected := _snapshot(save)
	for index in range(3):
		ArtifactJourney.record_event(save, "minimission", "repair-%d" % index, index + 1)
	var crown := PROMISES.progress(
		"emblem-crown", ArtifactJourney.item_state(save, "emblem-crown"))
	assert(bool(crown.get("complete", false)),
		"tre riparazioni non completano la promessa della Corona")
	assert(ArtifactJourney.status_line(save, "emblem-crown").contains("3/3"),
		"la bottega non puo' rendere leggibile la promessa completa")
	_assert_unchanged(save, protected)

func _audit_visual_completion() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 4
	initial["worlds"] = {"unlocked": range(1, 5), "current": 4}
	initial["cosmetics"] = {
		"unlocked": ["emblem-atom"], "equipped": {"emblem": "emblem-atom"},
		"inventory": [], "loadout": [], "mementoDisplayed": "",
	}
	initial["artifactJourney"] = {"resonances": [], "items": {
		"emblem-atom": {
			"uses": 3, "worlds": [1, 2, 3],
			"events": [
				"mystery:1:trace-a", "treasure:2:chest-b", "mystery:3:trace-c"],
			"resonances": [],
		},
	}}
	var request := NativeWorldState.default_request("emblem-promises-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 4
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world: Node = WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var player = world.get("player")
	var visual: Node = player.get("visual") if player != null else null
	assert(visual != null and visual.get_node_or_null("EmblemWitness") != null,
		"le testimonianze dell'emblema non compaiono su Eli")
	assert(visual.get_node_or_null("EmblemWitness/PromiseRing") != null,
		"una promessa completa non riceve l'anello visivo")
	for index in range(1, 4):
		var seal := visual.get_node_or_null("EmblemWitness/WitnessSeal%d" % index) as Label
		assert(seal != null and seal.text == "◆", "la testimonianza %d non e' piena" % index)
	root.remove_child(world)
	world.queue_free()
	await process_frame

func _snapshot(save: GameSaveManager) -> Dictionary:
	var out: Dictionary = {}
	for key in PROTECTED_KEYS:
		out[key] = save.data.get(key, null)
	return out.duplicate(true)

func _assert_unchanged(save: GameSaveManager, before: Dictionary) -> void:
	for key in PROTECTED_KEYS:
		assert(save.data.get(key, null) == before.get(key, null),
			"la promessa modifica il campo vietato %s" % key)
