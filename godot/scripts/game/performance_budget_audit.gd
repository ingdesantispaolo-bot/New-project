extends SceneTree

## C-P6 #7: sonda deterministica dei campioni di mondo. Non sostituisce il
## profiling su tablet reale, ma intercetta regressioni di streaming e scene
## accidentalmente fuori scala prima dell'export. Il primo caricamento paga
## anche compilazione e cache del motore: lo sorvegliamo con un limite distinto,
## poi misuriamo i mondi a cache calda contro il budget di scena.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const SAMPLE_LEVELS := [1, 7, 13, 19, 24]
const COLD_START_BUDGET_MSEC := 1000
const WORLD_START_BUDGET_MSEC := 500

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

func _warm_up() -> int:
	var started := Time.get_ticks_msec()
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request_for(1))
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var elapsed := Time.get_ticks_msec() - started
	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
	return elapsed

func _run() -> void:
	var cold_start_msec := await _warm_up()
	assert(cold_start_msec < COLD_START_BUDGET_MSEC,
		"avvio a freddo oltre budget: %d ms" % cold_start_msec)
	print("PERFORMANCE BUDGET — avvio a freddo: %d/%d ms" % [
		cold_start_msec, COLD_START_BUDGET_MSEC])
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
		assert(int(mobile_budget.get("targetFps", 0)) == 30
			and int(mobile_budget.get("minSteadyFps", 0)) >= 24
			and int(mobile_budget.get("maxMemoryMiB", 0)) <= 128,
			"budget tablet definitivo assente nel mondo %d" % level)
		assert(chunks.loaded.size() <= 9,
			"streaming oltre raggio 1 nel mondo %d: %d chunk" % [level, chunks.loaded.size()])
		# Le tavole pittoriche e i marker sono composti da molti CanvasItem
		# piccoli; il limite intercetta duplicazioni grossolane, mentre le draw
		# call reali restano responsabilità della sonda GPU.
		assert(node_count < 3500,
			"scene graph fuori scala nel mondo %d: %d nodi" % [level, node_count])
		peak_nodes = maxi(peak_nodes, node_count)
		slowest_msec = maxi(slowest_msec, elapsed)
		print("PERFORMANCE BUDGET — mondo %02d: %d ms, %d nodi, %d chunk" % [
			level, elapsed, node_count, chunks.loaded.size()])

		root.remove_child(world)
		world.queue_free()
		await process_frame
		await process_frame

	assert(slowest_msec < WORLD_START_BUDGET_MSEC,
		"istanza mondo oltre budget: %d ms" % slowest_msec)
	print("PERFORMANCE BUDGET audit OK — picco %d/3500 nodi, mondo %d/%d ms, freddo %d/%d ms" % [
		peak_nodes, slowest_msec, WORLD_START_BUDGET_MSEC,
		cold_start_msec, COLD_START_BUDGET_MSEC])
	quit(0)
