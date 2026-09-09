extends SceneTree

## C-R3: alla stessa distanza di streaming ogni mondo deve avere almeno la
## densita' visuale del mondo 18 misurato l'8 settembre 2026. Il pavimento non
## pretende la sovrabbondanza dell'Accademia: impedisce soltanto che un tema
## escluso dagli atlanti naturali torni a essere un prato con due prop.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const NODE_FLOOR := 59
const FINAL_THEMES := {
	21: "fractured_atlas",
	22: "deep_biosphere",
	23: "hall_of_eras",
	24: "first_heart",
}

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = level
	initial["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	var request := NativeWorldState.default_request("world-scenography-density")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	# Il rilievo C-R3 e' stato fatto alla distanza normale di streaming: nove
	# celle attorno a Eli, poi media per chunk. Un solo chunk misura soprattutto
	# quanto e' protetta l'area di ingresso, non la scenografia del mondo.
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _node2d_count(node: Node) -> int:
	var total := 1 if node is Node2D else 0
	# Un MultiMesh e' un solo contenitore ma disegna piu' forme vere. Contare il
	# contenitore farebbe risultare piu' povera proprio l'ottimizzazione GPU.
	if node is MultiMeshInstance2D and (node as MultiMeshInstance2D).multimesh != null:
		total = maxi(1, (node as MultiMeshInstance2D).multimesh.instance_count)
	for child in node.get_children():
		total += _node2d_count(child)
	return total

func _themed_count(node: Node, theme: String) -> int:
	var total := 0
	if node is Node2D and str(node.get_meta("scenery_theme", "")) == theme:
		total += 1
	for child in node.get_children():
		total += _themed_count(child, theme)
	return total

func _named_layer_count(node: Node, layer_name: String) -> int:
	var layer := node.get_node_or_null(layer_name)
	return _node2d_count(layer) if layer != null else 0

func _dispose(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _cleanup_audio() -> void:
	var audio := root.get_node_or_null("NativeAudio")
	if audio == null:
		return
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
				child.free()
	audio.set("_stream_cache", {})

func _run() -> void:
	var minimum := 1000000.0
	var minimum_world := 0
	var failures: Array[String] = []
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var world := await _open_world(level)
		var chunks := world.get("chunks") as OutdoorChunkManager
		assert(chunks != null and not chunks.loaded.is_empty(), "mondo %d senza chunk" % level)
		var total := 0
		var themed_total := 0
		var themed_layers := 0
		var assemblies_total := 0
		var details_total := 0
		for entry_data in chunks.loaded.values():
			var entry: Dictionary = entry_data
			var chunk := entry.get("node") as OutdoorChunkVisual
			assert(chunk != null, "mondo %d senza chunk visuale" % level)
			total += _node2d_count(chunk)
			assemblies_total += _named_layer_count(chunk, "BiomeAssemblies") + _named_layer_count(chunk, "ThemeAssemblies")
			details_total += _named_layer_count(chunk, "HabitatDetails") + _named_layer_count(chunk, "ThemeHabitatDetails")
			if FINAL_THEMES.has(level):
				var theme := str(FINAL_THEMES[level])
				themed_total += _themed_count(chunk, theme)
				if chunk.get_node_or_null("ThemeAssemblies") != null and chunk.get_node_or_null("ThemeHabitatDetails") != null:
					themed_layers += 1
		var count := float(total) / float(chunks.loaded.size())
		print("  mondo %02d %-24s %.1f nodi/chunk (assembly %.1f, dettagli %.1f)" % [level, chunks.composition.visual_theme, count, float(assemblies_total) / chunks.loaded.size(), float(details_total) / chunks.loaded.size()])
		if count < minimum:
			minimum = count
			minimum_world = level
		if count < NODE_FLOOR:
			failures.append("mondo %d: %.1f nodi visuali/chunk" % [level, count])
		if FINAL_THEMES.has(level):
			var theme := str(FINAL_THEMES[level])
			assert(chunks.composition.visual_theme == theme, "mondo %d: tema finale inatteso" % level)
			assert(themed_layers == chunks.loaded.size(),
				"mondo %d: strati tematici assenti in %d chunk" % [level, chunks.loaded.size() - themed_layers])
			assert(themed_total >= 8 * chunks.loaded.size(),
				"mondo %d: vocabolario %s non materializzato nel chunk" % [level, theme])
		await _dispose(world)
	_cleanup_audio()
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("  sotto soglia: %s" % failure)
	if not failures.is_empty():
		printerr("SCENOGRAPHY DENSITY audit FALLITO - %d mondi sotto %d nodi/chunk" % [failures.size(), NODE_FLOOR])
		quit(1)
		return
	print("SCENOGRAPHY DENSITY audit OK - 24 mondi >= %d nodi/chunk; minimo mondo %d: %.1f" % [NODE_FLOOR, minimum_world, minimum])
	quit(0)
