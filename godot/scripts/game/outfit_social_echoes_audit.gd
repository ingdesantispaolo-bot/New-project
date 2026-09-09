extends SceneTree

## Undici ruoli riconosciuti socialmente, una volta per persona. La reazione
## cambia con la patina e il registro dell'abitante, ma non apre contenuti.

const ECHOES := preload("res://scripts/game/outfit_social_echoes.gd")
const ArtifactJourney := preload("res://scripts/game/artifact_journey.gd")
const NPC_CATALOG := preload("res://scripts/game/npc_catalog.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PROTECTED_KEYS := [
	"level", "energy", "mastery", "masteryByTopic", "coverageThisLevel",
	"gateClearedLevel", "missionsBySubject", "apparatus", "worldProgress",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_audit_contract()
	await _audit_dialogue_integration()
	print("Outfit social echoes audit OK — 11 ruoli, patina e memoria per abitante")
	quit(0)

func _audit_contract() -> void:
	var catalog_ids: Array = []
	for item_data in RewardCatalog.by_slot("avatar"):
		catalog_ids.append(str(Dictionary(item_data).get("id", "")))
	var echo_ids := ECHOES.ids()
	assert(catalog_ids.size() == 11 and echo_ids.size() == 11,
		"catalogo ed echi devono contenere esattamente undici outfit")
	var titles: Dictionary = {}
	for id_data in catalog_ids:
		var id := str(id_data)
		assert(echo_ids.has(id), "%s non ha identita' sociale" % id)
		var echo := ECHOES.echo(id)
		var lines: Array = Array(echo.get("lines", []))
		assert(not str(echo.get("title", "")).is_empty() and lines.size() == 3,
			"%s non ha titolo e tre stadi di reazione" % id)
		for line_data in lines:
			assert(not str(line_data).strip_edges().is_empty(), "%s contiene una reazione vuota" % id)
		var title := str(echo.get("title", ""))
		assert(not titles.has(title), "due outfit condividono la stessa identita' sociale")
		titles[title] = id
		assert(Array(ArtifactJourney.profile(id).get("events", [])).has(ECHOES.EVENT_KIND),
			"%s non puo' ricordare chi lo ha riconosciuto" % id)
	assert(ECHOES.line("avatar-engineer", 0, "burbero") !=
		ECHOES.line("avatar-engineer", 2, "burbero"),
		"la patina non cambia la lettura sociale dell'outfit")
	assert(ECHOES.line("avatar-engineer", 2, "burbero") !=
		ECHOES.line("avatar-engineer", 2, "caloroso"),
		"il registro dell'abitante non cambia la voce della reazione")

func _audit_dialogue_integration() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 4
	initial["worlds"] = {"unlocked": range(1, 5), "current": 1}
	initial["cosmetics"] = {
		"unlocked": ["avatar-engineer"], "equipped": {"avatar": "avatar-engineer"},
		"inventory": [], "loadout": [], "mementoDisplayed": "",
	}
	initial["artifactJourney"] = {"resonances": [], "items": {
		"avatar-engineer": {
			"uses": 3, "worlds": [1, 2, 3],
			"events": [
				"minimission:1:repair-a", "minimission:2:repair-b", "minimission:3:repair-c"],
			"resonances": [],
		},
	}}
	var request := NativeWorldState.default_request("outfit-social-echoes-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world: Node = WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var save: GameSaveManager = world.get("game_save")
	var protected := _snapshot(save)
	var pages: Array = ["Battuta ordinaria."]
	var data: Dictionary = NPC_CATALOG.resident("w01-tobia")
	assert(bool(world.call(
		"_append_outfit_social_echo", "w01-tobia", data, "", pages)),
		"Tobia non riconosce l'outfit al primo dialogo ordinario")
	assert(str(pages[0]).contains("Un'Ingegnere") and str(pages[0]).contains("Non sto dicendo"),
		"la pagina non combina ruolo, patina e registro burbero")
	assert(Array(ArtifactJourney.item_state(save, "avatar-engineer").get("events", [])).has(
		"social_echo:1:w01-tobia"), "l'outfit non ricorda chi lo ha riconosciuto")
	var repeated_pages: Array = ["Seconda battuta ordinaria."]
	assert(not bool(world.call(
		"_append_outfit_social_echo", "w01-tobia", data, "", repeated_pages)),
		"lo stesso abitante ripete il riconoscimento dello stesso outfit")
	assert(repeated_pages == ["Seconda battuta ordinaria."],
		"un riconoscimento gia' visto altera ancora il dialogo")
	var mission_pages: Array = ["Richiesta urgente."]
	assert(not bool(world.call(
		"_append_outfit_social_echo", "w01-ersilia",
		NPC_CATALOG.resident("w01-ersilia"), "richiesta", mission_pages)),
		"l'outfit interrompe una richiesta di missione")
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
			"il riconoscimento sociale modifica il campo vietato %s" % key)
