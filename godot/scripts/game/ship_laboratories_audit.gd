extends SceneTree

## Sette restauri, sette laboratori, tre decisioni ciascuno. La sintesi e'
## sostituibile; la biografia conta il laboratorio una volta e la progressione
## resta intatta.

const LABS := preload("res://scripts/game/ship_laboratories.gd")
const ArtifactJourney := preload("res://scripts/game/artifact_journey.gd")
const HUB_SCENE := preload("res://scenes/hub.tscn")
const PROTECTED_KEYS := [
	"level", "energy", "mastery", "masteryByTopic", "coverageThisLevel",
	"gateClearedLevel", "missionsBySubject", "apparatus", "worldProgress",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_audit_contract()
	_audit_storage()
	await _audit_hub_integration()
	print("Ship laboratories audit OK — 7 laboratori, sintesi persistente e confine didattico")
	quit(0)

func _audit_contract() -> void:
	var ids := LABS.ids()
	assert(ids.size() == 7 and ids.size() == ShipRoomCatalog.ids().size(),
		"servono sette laboratori, uno per stanza")
	var decorations: Dictionary = {}
	var titles: Dictionary = {}
	for room_id_data in ShipRoomCatalog.ids():
		var room_id := str(room_id_data)
		assert(ids.has(room_id), "%s non ha laboratorio" % room_id)
		var lab := LABS.laboratory(room_id)
		var decor_id := str(lab.get("decor", ""))
		assert(decor_id == str(ShipRoomCatalog.room(room_id).get("restoration", "")),
			"il laboratorio %s non appartiene al restauro della stanza" % room_id)
		assert(not decorations.has(decor_id), "due laboratori usano lo stesso restauro")
		decorations[decor_id] = room_id
		var title := str(lab.get("title", ""))
		assert(not title.is_empty() and not titles.has(title),
			"titolo laboratorio vuoto o duplicato in %s" % room_id)
		titles[title] = room_id
		assert(not str(lab.get("intro", "")).is_empty()
			and not str(lab.get("completion", "")).is_empty(),
			"%s non ha cornice narrativa completa" % room_id)
		var steps: Array = Array(lab.get("steps", []))
		assert(steps.size() == 3, "%s non contiene tre decisioni" % room_id)
		for step_data in steps:
			var step: Dictionary = step_data
			var options: Array = Array(step.get("options", []))
			assert(not str(step.get("prompt", "")).is_empty() and options.size() == 2,
				"%s contiene una decisione incompleta" % room_id)
			for option_data in options:
				var option: Dictionary = option_data
				assert(not str(option.get("label", "")).is_empty()
					and not str(option.get("meaning", "")).is_empty(),
					"%s contiene un'opzione muta" % room_id)
		assert(Array(ArtifactJourney.profile(decor_id).get("events", [])).has(LABS.EVENT_KIND),
			"%s non puo' registrare il proprio laboratorio" % decor_id)

func _audit_storage() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var protected := _snapshot(save)
	var first := LABS.store_reflection(save, "bio", [0, 1, 0])
	assert(bool(first.get("completed", false)) and str(first.get("summary", "")).contains("ambiente"),
		"la Serra non costruisce una sintesi dalle scelte")
	var second := LABS.store_reflection(save, "bio", [1, 0, 1])
	assert(Array(second.get("choices", [])) == [1, 0, 1]
		and Array(LABS.reflection(save, "bio").get("choices", [])) == [1, 0, 1],
		"rifare il laboratorio non sostituisce la sintesi")
	assert(LABS.store_reflection(save, "bio", [0, 9, 0]).is_empty(),
		"una scelta inesistente viene accettata")
	_assert_unchanged(save, protected)

func _audit_hub_integration() -> void:
	root.size = Vector2i(1280, 720)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	initial["cosmetics"] = {
		"unlocked": [], "equipped": {},
		"inventory": ["decor-laboratorio"], "loadout": [], "mementoDisplayed": "",
	}
	var hub: Node = HUB_SCENE.instantiate()
	hub.set("launch_save_override", initial)
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	var button := hub.find_child("LaboratoryButton", true, false) as Button
	assert(button != null and not button.disabled,
		"il restauro posseduto non rende accessibile il laboratorio")
	var save: GameSaveManager = hub.get("save")
	var protected := _snapshot(save)
	hub.call("_open_laboratory")
	var panel := hub.find_child("ShipLaboratoryPanel", true, false) as Control
	assert(panel != null and panel.visible, "il pulsante non apre il laboratorio")
	assert(panel.find_child("LaboratoryPrompt", true, false) != null,
		"il laboratorio non rende leggibile la decisione")
	panel.call("_choose", 0)
	panel.call("_choose", 1)
	panel.call("_choose", 0)
	var reflection := LABS.reflection(save, "central")
	assert(bool(reflection.get("completed", false))
		and Array(reflection.get("choices", [])) == [0, 1, 0],
		"la UI non persiste la sintesi del Banco dei legami")
	var decor_state := ArtifactJourney.item_state(save, "decor-laboratorio")
	assert(Array(decor_state.get("events", [])).has("ship_lab:0:central"),
		"il laboratorio non entra nella biografia del restauro")
	var uses := int(decor_state.get("uses", 0))
	panel.call("open_lab", "central", reflection)
	panel.call("_choose", 1)
	panel.call("_choose", 1)
	panel.call("_choose", 1)
	assert(int(ArtifactJourney.item_state(save, "decor-laboratorio").get("uses", 0)) == uses,
		"rifare il laboratorio gonfia gli usi del restauro")
	assert(Array(LABS.reflection(save, "central").get("choices", [])) == [1, 1, 1],
		"la seconda lettura non sostituisce la prima")
	_assert_unchanged(save, protected)
	root.remove_child(hub)
	hub.queue_free()
	await process_frame

func _snapshot(save: GameSaveManager) -> Dictionary:
	var out: Dictionary = {}
	for key in PROTECTED_KEYS:
		out[key] = save.data.get(key, null)
	return out.duplicate(true)

func _assert_unchanged(save: GameSaveManager, before: Dictionary) -> void:
	for key in PROTECTED_KEYS:
		assert(save.data.get(key, null) == before.get(key, null),
			"il laboratorio modifica il campo vietato %s" % key)
