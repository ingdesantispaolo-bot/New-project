extends SceneTree

## Copertura autoriale completa dei Ricordi: ventiquattro contratti, dodici
## coppie reciproche e nessun fallback generico. La prova di scena usa la
## Foglia di sintassi (2 -> 14), non la vertical slice Sciarpa/Anello.

const RESONANCES := preload("res://scripts/game/memento_resonances.gd")
const ARTIFACTS := preload("res://scripts/game/artifact_journey.gd")
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PROTECTED_KEYS := [
	"level", "energy", "fragments", "mastery", "masteryByTopic",
	"coverageThisLevel", "gateClearedLevel", "missionsBySubject", "apparatus",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_audit_contracts()
	_audit_persistence()
	await _audit_scene()
	print("Memento resonances audit OK — 24/24 autoriali, 12 firme e confine intatto")
	quit(0)

func _audit_contracts() -> void:
	var catalog_ids: Array = []
	for item_data in RewardCatalog.CATALOG:
		var item: Dictionary = item_data
		if ARTIFACTS.is_memento(item):
			catalog_ids.append(str(item.get("id", "")))
	assert(catalog_ids.size() == 24, "il catalogo non espone ventiquattro Ricordi")
	assert(RESONANCES.ids().size() == catalog_ids.size(),
		"la matrice non copre esattamente i ventiquattro Ricordi")

	var actions: Dictionary = {}
	var lines: Dictionary = {}
	var traces: Dictionary = {}
	var motifs: Dictionary = {}
	for item_id_data in catalog_ids:
		var item_id := str(item_id_data)
		var contract := RESONANCES.resonance(item_id)
		assert(not contract.is_empty(), "%s usa ancora il fallback generico" % item_id)
		var source := int(contract.get("source", 0))
		var target := int(contract.get("target", 0))
		var pair_id := int(contract.get("pair", 0))
		var direction := int(contract.get("direction", 0))
		assert(source == int(RewardCatalog.find(item_id).get("requiresHazardWorld", 0)),
			"%s non parte dal proprio mondo" % item_id)
		assert(target == ARTIFACTS.resonance_world(item_id),
			"%s non raggiunge il mondo gemello" % item_id)
		assert(pair_id == mini(source, target) and direction in [-1, 1],
			"%s non dichiara coppia o direzione valida" % item_id)
		for key in ["action", "prompt", "line", "trace", "motif"]:
			assert(not str(contract.get(key, "")).strip_edges().is_empty(),
				"%s non dichiara %s" % [item_id, key])
		var action := str(contract.get("action", ""))
		var line := str(contract.get("line", ""))
		var trace := str(contract.get("trace", ""))
		assert(not actions.has(action), "due Ricordi chiedono lo stesso gesto: %s" % action)
		assert(not lines.has(line), "due Ricordi hanno la stessa lettura")
		assert(not traces.has(trace), "due Ricordi lasciano la stessa traccia")
		actions[action] = item_id
		lines[line] = item_id
		traces[trace] = item_id
		motifs[str(contract.get("motif", ""))] = true
		assert(ARTIFACTS.resonance_line(item_id, target) == line,
			"%s non usa la propria lettura autoriale" % item_id)
		assert(not line.contains("riconosce un legame fra"),
			"%s espone ancora il testo di fallback" % item_id)

	assert(actions.size() == 24 and lines.size() == 24 and traces.size() == 24,
		"gesti, letture e tracce devono essere unici 24/24")
	assert(motifs.size() == 12, "servono dodici firme visive, una per coppia")
	for pair_id in range(1, 13):
		var members := RESONANCES.pair_members(pair_id)
		assert(members.size() == 2, "la coppia %d non contiene due Ricordi" % pair_id)
		var first := RESONANCES.resonance(str(members[0]))
		var second := RESONANCES.resonance(str(members[1]))
		assert(int(first.get("source", 0)) == int(second.get("target", 0))
			and int(first.get("target", 0)) == int(second.get("source", 0)),
			"la coppia %d non e' reciproca" % pair_id)
		assert(str(first.get("motif", "")) == str(second.get("motif", ""))
			and int(first.get("direction", 0)) == -int(second.get("direction", 0)),
			"la coppia %d non condivide firma con direzioni opposte" % pair_id)

func _audit_persistence() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var item_id := "memento-09-ago-cartografico"
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	cosmetics["unlocked"] = [item_id]
	cosmetics["mementoDisplayed"] = item_id
	save.data["cosmetics"] = cosmetics
	var protected := _snapshot(save)
	var entry := ARTIFACTS.begin_expedition(save, 21)
	var payload: Dictionary = entry.get("resonance", {})
	assert(str(payload.get("action", "")) == "ALLARGA LA SCALA"
		and str(payload.get("motif", "")) == "maps_systems",
		"l'ingresso perde gesto o firma dell'Ago cartografico")
	var first := ARTIFACTS.activate_resonance(save, item_id, 21)
	assert(bool(first.get("first", false)) and str(first.get("trace", "")) == "Coordinate aperte in sistema",
		"la prima attivazione non conserva la traccia specifica")
	var uses := int(ARTIFACTS.item_state(save, item_id).get("uses", 0))
	var repeated := ARTIFACTS.activate_resonance(save, item_id, 21)
	assert(not bool(repeated.get("first", true))
		and int(ARTIFACTS.item_state(save, item_id).get("uses", 0)) == uses,
		"ripetere la risonanza gonfia la biografia")
	_assert_unchanged(save, protected)

func _audit_scene() -> void:
	root.size = Vector2i(1280, 720)
	var initial := GameSaveManager._default_data()
	initial["level"] = 14
	initial["worlds"] = {"unlocked": range(1, 15), "current": 14}
	initial["cosmetics"] = {
		"unlocked": ["memento-02-foglia-sintassi"],
		"equipped": {}, "inventory": [], "loadout": [],
		"mementoDisplayed": "memento-02-foglia-sintassi",
	}
	var request := NativeWorldState.default_request("memento-resonances-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 14
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var site := world.find_child("ArtifactResonance", true, false) as Area2D
	assert(site != null, "la Foglia non crea la risonanza nel mondo 14")
	var payload: Dictionary = site.get_meta("payload", {})
	assert(str(payload.get("action", "")) == "APRI LE NERVATURE",
		"la scena non riceve il gesto specifico")
	assert(site.get_node_or_null("ResonanceVisual/ResonanceSignature/SignaturePath") != null,
		"la coppia parole-voci non ha una firma fisica")
	var reading := site.get_node_or_null("ResonanceVisual/ResonanceReading") as Label
	assert(reading != null and reading.text == str(payload.get("prompt", "")),
		"il sito non presenta il gesto prima dell'azione")
	var button := world.get("interaction_button") as Button
	if button != null:
		world.call("_refresh_interaction_button", site)
		assert(button.text == "APRI LE NERVATURE", "il comando resta generico")
	var save: GameSaveManager = world.get("game_save")
	var protected := _snapshot(save)
	world.call("_activate_artifact_resonance", site)
	assert(reading.text == "TRACCIA · Sintassi con punto di vista",
		"il gesto non lascia la traccia specifica nella scena")
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
			"la risonanza modifica il campo vietato %s" % key)
