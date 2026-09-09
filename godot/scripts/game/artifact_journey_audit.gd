extends SceneTree

const ArtifactJourney = preload("res://scripts/game/artifact_journey.gd")

## Audit della bottega come sistema di oggetti vivi. Verifica il contratto di
## tutti gli 87 oggetti, le dodici coppie di risonanza, l'idempotenza e il
## confine assoluto con apprendimento/progressione.

const FORBIDDEN_KEYS := [
	"level", "energy", "mastery", "masteryByTopic", "coverageThisLevel",
	"gateClearedLevel", "missionsBySubject", "apparatus", "worldProgress",
]

func _init() -> void:
	_audit_catalog_contract()
	_audit_resonance_pairs()
	_audit_vertical_slice()
	_audit_active_only_and_idempotence()
	_audit_tools_and_rooms()
	_audit_migration()
	print("Artifact journey audit OK — 87 oggetti, 24 Ricordi, uso persistente e confine didattico")
	quit(0)

func _audit_catalog_contract() -> void:
	assert(RewardCatalog.CATALOG.size() == 87,
		"il catalogo atteso ha 87 oggetti, trovati %d" % RewardCatalog.CATALOG.size())
	var ids: Dictionary = {}
	for raw in RewardCatalog.CATALOG:
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		assert(not id.is_empty() and not ids.has(id), "id vuoto o duplicato: %s" % id)
		ids[id] = true
		var purpose := ArtifactJourney.profile(item)
		for field in ["family", "verb", "method", "use", "trace"]:
			assert(not str(purpose.get(field, "")).strip_edges().is_empty(),
				"%s non dichiara %s" % [id, field])
		assert(not Array(purpose.get("events", [])).is_empty(),
			"%s non ha nessun evento d'uso" % id)

func _audit_resonance_pairs() -> void:
	var memories := RewardCatalog.conquest_items()
	assert(memories.size() == 24, "i Ricordi devono essere 24, trovati %d" % memories.size())
	var by_world: Dictionary = {}
	for raw in memories:
		var item: Dictionary = raw
		var source := int(item.get("requiresHazardWorld", 0))
		assert(source >= 1 and source <= 24 and not by_world.has(source),
			"origine Ricordo mancante o duplicata al mondo %d" % source)
		by_world[source] = str(item.get("id", ""))
	for world in range(1, 25):
		var id := str(by_world.get(world, ""))
		var target := ArtifactJourney.resonance_world(id)
		assert(target == (world + 12 if world <= 12 else world - 12),
			"risonanza errata per %s: %d" % [id, target])
		assert(ArtifactJourney.resonance_world(str(by_world[target])) == world,
			"la coppia del mondo %d non e' reciproca" % world)

func _audit_vertical_slice() -> void:
	var save := _save()
	var cosmetics: Dictionary = save.data["cosmetics"]
	cosmetics["unlocked"] = ["accessory-scarf", "pet-prisma", "avatar-astral"]
	cosmetics["equipped"] = {
		"accessory": "accessory-scarf", "pet": "pet-prisma", "avatar": "avatar-astral"}
	cosmetics["inventory"] = ["nora-prismatic-core"]
	cosmetics["mementoDisplayed"] = "accessory-scarf"
	save.data["cosmetics"] = cosmetics
	var protected := _protected_snapshot(save)
	var entry := ArtifactJourney.begin_expedition(save, 13)
	var resonance: Dictionary = entry.get("resonance", {})
	assert(str(resonance.get("id", "")) == "accessory-scarf",
		"la Sciarpa non riconosce il mondo 13")
	assert(not bool(resonance.get("completed", true)),
		"la risonanza viene consumata entrando invece che agendo")
	var event := ArtifactJourney.activate_resonance(save, "accessory-scarf", 13)
	assert(bool(event.get("first", false)), "la prima risonanza 1->13 non e' nuova")
	var state := ArtifactJourney.item_state(save, "accessory-scarf")
	assert(Array(state.get("resonances", [])).has(13), "la Sciarpa non conserva il mondo 13")
	for witness_id in ["pet-prisma", "avatar-astral", "nora-prismatic-core"]:
		var witness_events := Array(ArtifactJourney.item_state(save, witness_id).get("events", []))
		assert(witness_events.has("resonance:13:accessory-scarf:13"),
			"%s non testimonia la risonanza pur essendo attivo" % witness_id)
	var uses := int(state.get("uses", 0))
	assert(not bool(ArtifactJourney.activate_resonance(save, "accessory-scarf", 13).get("first", true)),
		"la stessa risonanza risulta nuova due volte")
	assert(int(ArtifactJourney.item_state(save, "accessory-scarf").get("uses", 0)) == uses,
		"la risonanza ripetuta aumenta gli usi")
	_assert_protected(save, protected, "risonanza Sciarpa")

	# La direzione inversa usa l'Anello del secondo ciclo nella Radura.
	var reverse := _save()
	var reverse_cosmetics: Dictionary = reverse.data["cosmetics"]
	reverse_cosmetics["inventory"] = ["memento-13-anello-rapporto"]
	reverse_cosmetics["mementoDisplayed"] = "memento-13-anello-rapporto"
	reverse.data["cosmetics"] = reverse_cosmetics
	var reverse_entry := ArtifactJourney.begin_expedition(reverse, 1)
	assert(str(Dictionary(reverse_entry.get("resonance", {})).get("id", "")) ==
		"memento-13-anello-rapporto", "l'Anello non riconosce la Radura")
	assert(bool(ArtifactJourney.activate_resonance(
		reverse, "memento-13-anello-rapporto", 1).get("first", false)),
		"la risonanza 13->1 non si attiva")

func _audit_active_only_and_idempotence() -> void:
	var save := _save()
	var cosmetics: Dictionary = save.data["cosmetics"]
	cosmetics["unlocked"] = ["avatar-gold", "avatar-violet", "pet-comet", "emblem-star"]
	cosmetics["equipped"] = {
		"avatar": "avatar-gold", "pet": "pet-comet", "emblem": "emblem-star"}
	save.data["cosmetics"] = cosmetics
	var first := ArtifactJourney.record_event(save, "expedition", "world-04", 4)
	assert(first.has("avatar-gold") and first.has("pet-comet") and first.has("emblem-star"),
		"gli oggetti preparati non registrano la spedizione")
	assert(not first.has("avatar-violet"), "un outfit posseduto ma non indossato registra un uso")
	var before := int(ArtifactJourney.item_state(save, "avatar-gold").get("uses", 0))
	ArtifactJourney.record_event(save, "expedition", "world-04", 4)
	assert(int(ArtifactJourney.item_state(save, "avatar-gold").get("uses", 0)) == before,
		"lo stesso evento non e' idempotente")
	ArtifactJourney.record_event(save, "expedition", "world-05", 5)
	ArtifactJourney.record_event(save, "expedition", "world-06", 6)
	assert(ArtifactJourney.patina_stage(
		ArtifactJourney.item_state(save, "avatar-gold")) == 2,
		"tre mondi distinti non producono il secondo stadio di patina")

func _audit_tools_and_rooms() -> void:
	var save := _save()
	var cosmetics: Dictionary = save.data["cosmetics"]
	cosmetics["unlocked"] = ["tool-torch", "accessory-jetpack", "emblem-bolt"]
	cosmetics["equipped"] = {
		"accessory": "accessory-jetpack", "emblem": "emblem-bolt"}
	cosmetics["inventory"] = ["decor-laboratorio", "nora-lens"]
	save.data["cosmetics"] = cosmetics
	assert(ArtifactJourney.record_acquired(save, "accessory-jetpack", 2),
		"l'acquisto non apre la biografia")
	var purchased := ArtifactJourney.item_state(save, "accessory-jetpack")
	assert(int(purchased.get("uses", -1)) == 0 and Array(purchased.get("worlds", [])).is_empty(),
		"l'acquisto viene contato come uso o produce patina")
	assert(ArtifactJourney.record_tool_use(save, "tool-torch", "dark-gate", 2),
		"uno strumento posseduto non registra il varco")
	var witnesses := ArtifactJourney.record_event(save, "tool_use", "dark-gate", 2)
	assert(witnesses.has("accessory-jetpack") and witnesses.has("emblem-bolt"),
		"il gesto dello strumento non lascia traccia sugli oggetti compatibili")
	assert(not ArtifactJourney.record_tool_use(save, "tool-scythe", "grass-gate", 2),
		"uno strumento non posseduto registra il varco")
	var changed := ArtifactJourney.record_ship_room(save, "central")
	assert(changed.has("decor-laboratorio") and changed.has("nora-lens"),
		"il Ponte Centrale non usa restauro e Lente posseduti")

func _audit_migration() -> void:
	var old := {"schemaVersion": 4, "level": 1, "energy": 7, "cosmetics": {}}
	var manager := GameSaveManager.new()
	manager.data = manager.migrate_legacy_save(old)
	assert(int(manager.data.get("schemaVersion", 0)) == GameSaveManager.SCHEMA_VERSION,
		"schema non migrato")
	assert(typeof(manager.data.get("artifactJourney", null)) == TYPE_DICTIONARY,
		"un save precedente non riceve artifactJourney")
	assert(int(manager.data.get("energy", 0)) == 7, "la migrazione altera lo stato esistente")

func _save() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _protected_snapshot(save: GameSaveManager) -> Dictionary:
	var out: Dictionary = {}
	for key in FORBIDDEN_KEYS:
		out[key] = save.data.get(key, null)
	return out.duplicate(true)

func _assert_protected(save: GameSaveManager, before: Dictionary, context: String) -> void:
	for key in FORBIDDEN_KEYS:
		assert(save.data.get(key, null) == before.get(key, null),
			"%s ha modificato il campo vietato %s" % [context, key])
