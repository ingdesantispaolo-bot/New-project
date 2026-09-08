extends SceneTree

## **Quanta roba c'e' davvero in un mondo, e quanta di quella roba mente.**
##
## Due misure in una passata sui ventiquattro mondi:
##
##   1. l'arredo procedurale che sopravvive al filtro di profilo (ostacoli e
##      prop), perche' `chunk_manager._profile_filtered_chunk` scala la quota per
##      livello e negli ultimi mondi la porta a zero;
##   2. i varchi da attrezzo costruiti sulle palestre. Dal 4 settembre 2026
##      `_create_profile_event` non mette piu' `requiredTool` nel payload, ma
##      continua a costruire un `EquipmentGate` su OGNI palestra: con la stringa
##      vuota il catalogo dei disegni ricade sulla colonna 0 (la torcia) e la
##      targhetta dice «PASSAGGIO APERTO» dove non c'e' mai stato un passaggio.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 600)
	print("mondo | ostacoli | prop | forzieri | palestre | varchi-fantasma | tracce | abitanti | edifici")
	for livello in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		await _misura(int(livello))
	quit(0)

func _misura(livello: int) -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 400
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("arredo-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello

	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", request)
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	await process_frame
	await process_frame

	var chunks = mondo.get("chunks")
	var seme := str(mondo.get("world_seed"))
	var bordi: Rect2 = chunks.world_bounds()
	var dimensione := float(OutdoorChunkManager.CHUNK_SIZE)
	var ostacoli := 0
	var prop := 0
	var forzieri := 0
	for cy in range(floori(bordi.position.y / dimensione), floori(bordi.end.y / dimensione) + 1):
		for cx in range(floori(bordi.position.x / dimensione), floori(bordi.end.x / dimensione) + 1):
			if not chunks.call("_chunk_intersects_playfield", chunks.call("_chunk_rect", cx, cy)):
				continue
			var filtrato: Dictionary = chunks.call(
				"_profile_filtered_chunk", chunks.generator.generate_chunk(seme, cx, cy))
			ostacoli += Array(filtrato.get("obstacles", [])).size()
			prop += Array(filtrato.get("props", [])).size()
			forzieri += Array(filtrato.get("treasures", [])).size()

	var palestre := 0
	for evento_data in Array(mondo.get("mission_events")):
		if str(Dictionary(evento_data).get("kind", "")) == "practice":
			palestre += 1
	var fantasma := 0
	var etichette: Array = []
	for nodo in mondo.get_tree().get_nodes_in_group("equipment_gate"):
		if not mondo.is_ancestor_of(nodo):
			continue
		if str(nodo.get("required_tool")) == "":
			fantasma += 1
			var targhetta := nodo.get_node_or_null("EquipmentRequirement") as Label
			var disegno := nodo.get_node_or_null("FieldGateArt") as Sprite2D
			if targhetta != null and etichette.size() < 1:
				etichette.append("«%s» + disegno %s" % [
					targhetta.text, "presente" if disegno != null and disegno.texture != null else "assente"])

	var tracce := 0
	for nodo in mondo.get_tree().get_nodes_in_group("mystery_artifact"):
		if mondo.is_ancestor_of(nodo):
			tracce += 1
	print("%5d | %8d | %4d | %8d | %8d | %15d | %6d | %8d | %7d %s" % [
		livello, ostacoli, prop, forzieri, palestre, fantasma, tracce,
		Array(mondo.get("npc_actors")).size(), Array(mondo.get("world_buildings")).size(),
		("· " + str(etichette[0])) if not etichette.is_empty() else ""])

	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame
