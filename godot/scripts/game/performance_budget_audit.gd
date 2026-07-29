extends SceneTree

## C-P6 #7: sonda deterministica dei campioni di mondo. Non sostituisce il
## profiling su tablet reale, ma intercetta regressioni di streaming e scene
## accidentalmente fuori scala prima dell'export.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const SAMPLE_LEVELS := [1, 7, 13, 19, 24]

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": level}
	var request := NativeWorldState.default_request("performance-budget-%d" % level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = level
	return request

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total

func _run() -> void:
	var peak_nodes := 0
	var slowest_msec := 0
	for level in SAMPLE_LEVELS:
		var started := Time.get_ticks_msec()
		var world := WORLD_SCENE.instantiate()
		world.set("launch_request_override", _request_for(level))
		world.set("launch_stream_radius_override", 1)
		root.add_child(world)
		await process_frame
		await process_frame

		var elapsed := Time.get_ticks_msec() - started
		var node_count := _count_nodes(world)
		var chunks: OutdoorChunkManager = world.get("chunks")
		var profile: Dictionary = world.get("world_profile")
		var mobile_budget: Dictionary = profile.get("performanceBudget", {}).get("mobile", {})
		assert(not mobile_budget.is_empty() and int(mobile_budget.get("maxDrawCalls", 0)) > 0,
			"WorldProfile %d privo di budget mobile" % level)
		assert(chunks.loaded.size() <= 9,
			"streaming oltre raggio 1 nel mondo %d: %d chunk" % [level, chunks.loaded.size()])
		# Le tavole pittoriche e i marker sono composti da molti CanvasItem
		# piccoli; il limite intercetta duplicazioni grossolane, mentre le draw
		# call reali restano responsabilità della sonda GPU.
		assert(node_count < 5000,
			"scene graph fuori scala nel mondo %d: %d nodi" % [level, node_count])
		peak_nodes = maxi(peak_nodes, node_count)
		slowest_msec = maxi(slowest_msec, elapsed)
		print("PERFORMANCE BUDGET — mondo %02d: %d ms, %d nodi, %d chunk" % [
			level, elapsed, node_count, chunks.loaded.size()])

		root.remove_child(world)
		world.queue_free()
		await process_frame
		await process_frame

	print("PERFORMANCE BUDGET audit OK — picco %d nodi, avvio headless massimo %d ms" % [
		peak_nodes, slowest_msec])
	quit(0)
