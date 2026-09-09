extends SceneTree

## R-17: il mondo 1 sta a 546-691 ms su un budget di 500. Questa sonda separa il
## costo che si paga UNA VOLTA SOLA (compilazione degli script, caricamento delle
## risorse) da quello del mondo. Istanzia lo stesso mondo 1 quattro volte di
## seguito e stampa tutti e quattro i tempi.
##
## Se il primo e' alto e i successivi crollano, il rosso e' l'avvio del motore e
## togliere roba al mondo 1 non serve a niente.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": level}
	var request := NativeWorldState.default_request("avvio-probe-%d" % level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = level
	return request

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total

func _misura(level: int) -> Array:
	var started := Time.get_ticks_msec()
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request_for(level))
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var elapsed := Time.get_ticks_msec() - started
	var nodi := _count_nodes(world)
	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
	return [elapsed, nodi]

func _run() -> void:
	print("=== stesso mondo 1, quattro volte di seguito ===")
	for giro in range(4):
		var r: Array = await _misura(1)
		print("giro %d · mondo 1 · %4d ms · %d nodi" % [giro, int(r[0]), int(r[1])])

	print("\n=== e il mondo 13, per confronto, dopo il riscaldamento ===")
	for giro in range(2):
		var r: Array = await _misura(13)
		print("giro %d · mondo 13 · %4d ms · %d nodi" % [giro, int(r[0]), int(r[1])])

	quit(0)
