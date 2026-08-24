extends SceneTree

## Sonda: **ogni sacca del mondo ha un gesto?** Elenca ruolo, area di sfida e
## cartiglio di tutte le sacche vive, mondo per mondo.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _apri(livello: int) -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("sacche-ruoli-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _i in range(40):
		await process_frame
	return world

func _run() -> void:
	for livello in [1, 7]:
		var world := await _apri(livello)
		print("\n--- MONDO %d" % livello)
		print("%-26s %-11s %-14s %s" % ["NODO", "RUOLO", "AFFRONTABILE", "CARTIGLIO"])
		for sacca in get_nodes_in_group("world_enemy"):
			if not world.is_ancestor_of(sacca):
				continue
			var sfida = sacca.find_child("EnemyChallenge", true, false)
			var label = sacca.get_node_or_null("EnemyLabel")
			print("%-26s %-11s %-14s %s" % [
				str(sacca.name).substr(0, 25), str(sacca.get("ruolo")),
				"si" if sfida != null else "NO",
				str(label.text) if label != null else "-"])
		world.queue_free()
		await process_frame
	quit(0)
