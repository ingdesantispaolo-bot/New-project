extends SceneTree

const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var hub := (load(HUB_SCENE) as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame

	var bridge := hub.find_child("WalkableShipBridge", true, false)
	var player := hub.find_child("ShipPlayer", true, false) as CharacterBody2D
	assert(bridge != null and player != null, "ponte o controller camminabile assente")
	assert(player.get_script() == load("res://scripts/player_controller.gd"),
		"la nave non riusa il controller del mondo esterno")
	var doors := bridge.find_children("ShipDoor_*", "Area2D", true, false)
	assert(doors.size() == ApparatusConfig.SUBJECT_CYCLE.size() and doors.size() == 12,
		"la nave deve avere dodici porte raggiungibili, trovate %d" % doors.size())
	var subjects: Array = []
	for door in doors:
		var at: Vector2 = door.position
		assert(absf(at.x) < 342.0 and absf(at.y) < 212.0,
			"porta fuori dal ponte camminabile: %s" % door.name)
		assert(door.get_node_or_null("DoorThreshold") != null,
			"soglia fisica assente: %s" % door.name)
		subjects.append(str(door.get_meta("subject", "")))
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		assert(subjects.has(str(subject)), "porta materia assente: %s" % subject)

	var controller: HubController = hub.get("controller")
	var state := controller.runtime_state()
	assert(Dictionary(state.get("rooms", {})).size() == ShipRoomCatalog.ids().size(),
		"runtime_state non espone lo stato di tutti i ponti")
	for room_id in ShipRoomCatalog.ids():
		var activation: Dictionary = Dictionary(state["rooms"]).get(str(room_id), {})
		assert(activation.has("stage") and activation.has("ratio"),
			"stato acceso/spento incompleto per %s" % room_id)

	assert(hub.find_child("WorldMapButton", true, false) != null,
		"mappa dei mondi non raggiungibile dalla nave")
	assert(hub.find_child("BackToWorldButton", true, false) != null,
		"ritorno al mondo non disponibile")
	var source_file := FileAccess.open("res://scripts/hub_scene.gd", FileAccess.READ)
	var source := source_file.get_as_text()
	assert("ShipActivationModel.activation_for_room" not in source,
		"la scena calcola lo stato delle stanze invece di leggerlo dal runtime")
	var nodes := _count_nodes(hub)
	assert(nodes < 3500, "ponte oltre il budget assoluto: %d nodi" % nodes)
	print("SHIP SCENE audit OK - 12 porte, controller condiviso, runtime_state, %d nodi" % nodes)
	quit(0)

func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count
