extends SceneTree

## Headless smoke test for the Godot side of the bridge:
## spawn world -> collect treasure -> start encounter -> emit pending result.
## Phaser-side persistence and NORA completion are covered by Vitest bridge
## tests; the browser navigation itself remains a manual Web check.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/outdoor_world.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var chunks: Dictionary = scene.get("chunks").get("loaded")
	var origin: Dictionary = chunks["chunk-0_0"]["data"]
	var player: Node = scene.get("player")

	var treasure: Dictionary = origin["treasures"][0]
	var treasure_area := _find_area(scene, "treasure", str(treasure["id"]))
	assert(treasure_area != null)
	player.position = Vector2(treasure["x"], treasure["y"])
	scene.call("on_interactable_entered", treasure_area, player)
	scene.call("_interact")
	var treasure_result: Dictionary = scene.get("result")
	assert(treasure_result["collectedTreasureIds"].has(treasure["id"]))
	assert(int(treasure_result["energyEarned"]) > 0)

	var encounter: Dictionary = origin["encounters"][0]
	var encounter_area := _find_area(scene, "encounter", str(encounter["id"]))
	assert(encounter_area != null)
	player.position = Vector2(encounter["x"], encounter["y"])
	scene.call("on_interactable_entered", encounter_area, player)
	scene.call("_interact")
	var pending_result: Dictionary = scene.get("result")
	assert(pending_result.has("pendingEncounter"))
	assert(pending_result["pendingEncounter"]["id"] == encounter["id"])
	print("Outdoor Godot round-trip smoke OK")
	quit(0)

func _find_area(node: Node, kind: String, id: String) -> Area2D:
	for child in node.get_children():
		if child is Area2D and str(child.get_meta("kind", "")) == kind and str(child.get_meta("id", "")) == id:
			return child
		var nested := _find_area(child, kind, id)
		if nested != null:
			return nested
	return null
