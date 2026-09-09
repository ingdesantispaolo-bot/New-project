extends SceneTree

## Le forme cambiano metodo, mai potere: 11 profili completi e distinti, tre
## punti realmente percorribili, una resa visiva nella tana e una sola traccia
## persistente per evento.

const METHODS := preload("res://scripts/game/pet_field_methods.gd")
const ArtifactJourney := preload("res://scripts/game/artifact_journey.gd")
const PET_COMPANION := preload("res://scripts/pet_companion.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PROTECTED_KEYS := [
	"level", "energy", "mastery", "masteryByTopic", "coverageThisLevel",
	"gateClearedLevel", "missionsBySubject", "apparatus",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_audit_contract()
	await _audit_real_path()
	await _audit_world_integration()
	print("Pet field methods audit OK — 11 forme, percorsi distinti e nessun vantaggio")
	quit(0)

func _audit_contract() -> void:
	var catalog_ids: Array = []
	for item_data in RewardCatalog.by_slot("pet"):
		catalog_ids.append(str(Dictionary(item_data).get("id", "")))
	var method_ids := METHODS.ids()
	assert(catalog_ids.size() == 11 and method_ids.size() == 11,
		"catalogo e metodi devono contenere esattamente undici forme")
	var titles: Dictionary = {}
	var paths: Dictionary = {}
	for id_data in catalog_ids:
		var id := str(id_data)
		assert(method_ids.has(id), "%s non ha un metodo da campo" % id)
		var method := METHODS.method(id)
		for field in ["title", "verb", "glyph", "departure", "completion"]:
			assert(not str(method.get(field, "")).strip_edges().is_empty(),
				"%s non dichiara %s" % [id, field])
		var points: Array = Array(method.get("points", []))
		assert(points.size() == 3 and Vector2(points[2]) == Vector2.ZERO,
			"%s non conclude il percorso entrando nella tana" % id)
		var title := str(method.get("title", ""))
		var path_key := JSON.stringify(points)
		assert(not titles.has(title), "due forme condividono lo stesso metodo %s" % title)
		assert(not paths.has(path_key), "due forme condividono la stessa traiettoria")
		titles[title] = id
		paths[path_key] = id
		assert(Array(ArtifactJourney.profile(id).get("events", [])).has("den"),
			"%s non puo' conservare il proprio metodo nelle tane" % id)
	# L'esito non riceve mai la forma come parametro: lo stesso id di tana deve
	# quindi restituire lo stesso risultato per tutte le undici configurazioni.
	for index in range(24):
		var den_id := "audit-den-%d" % index
		var expected := PetErrand.esito_di(den_id)
		for _pet_id in method_ids:
			assert(PetErrand.esito_di(den_id) == expected,
				"la forma altera l'esito della tana %s" % den_id)

func _audit_real_path() -> void:
	var companion = PET_COMPANION.new()
	root.add_child(companion)
	companion.setup("orbit", Color("f6c85f"), null, "quieto", true)
	companion.global_position = Vector2.ZERO
	companion.manda_percorso([Vector2(18, 0), Vector2(18, 18), Vector2(36, 18)])
	assert(not companion.arrivato(), "il percorso risulta concluso prima di partire")
	for _step in range(20):
		companion.call("_process", 0.1)
	assert(companion.arrivato(), "il Custode non percorre davvero i tre punti")
	companion.torna()
	assert(not companion.arrivato() and companion.visible,
		"il Custode non torna correttamente al seguito")
	root.remove_child(companion)
	companion.queue_free()
	await process_frame

func _audit_world_integration() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 6
	initial["energy"] = 41
	initial["worlds"] = {"unlocked": range(1, 7), "current": 6}
	initial["pet"] = {"granted": true, "name": "Lume"}
	initial["cosmetics"] = {
		"unlocked": ["pet-prisma"],
		"equipped": {"pet": "pet-prisma"},
		"inventory": [], "loadout": [], "mementoDisplayed": "",
	}
	var request := NativeWorldState.default_request("pet-field-methods-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 6
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world: Node = WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var den := world.find_child("Tana_0", true, false) as Area2D
	assert(den != null, "il mondo di prova non costruisce una tana")
	var method := METHODS.method("pet-prisma")
	world.call("_mostra_metodo_tana", den, "pet-prisma", method)
	var path := den.get_node_or_null("PetDenMethod/MethodPath") as Line2D
	assert(path != null and path.get_point_count() == 3,
		"la tana non mostra la traiettoria specifica del Prisma")
	var save: GameSaveManager = world.get("game_save")
	var protected := _snapshot(save)
	var gameplay = world.get("gameplay")
	var changed: Array = gameplay.record_artifact_event(
		"den", "pet-field-method-audit", ["pet-prisma"])
	assert(changed.has("pet-prisma"), "il metodo del Prisma non entra nella biografia")
	assert(Array(ArtifactJourney.item_state(save, "pet-prisma").get("events", [])).has(
		"den:6:pet-field-method-audit"), "la traccia della tana non e' persistente")
	_assert_unchanged(save, protected)
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
			"il metodo del Custode modifica il campo vietato %s" % key)
