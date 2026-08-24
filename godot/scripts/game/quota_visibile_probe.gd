extends SceneTree

## Sonda: **il cartello della palestra dice quante prove mancano?**
##
## \u00c8 la met\u00e0 visibile della correzione del 24 agosto 2026: il quadro degli
## obiettivi lo diceva gi\u00e0, la mappa no. Qui si legge la riga che Eli vede
## avvicinandosi a una palestra, senza aprire nessun pannello.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	# Con gli attrezzi del mondo: senza, il cartello parla del varco e non della
	# quota, e la sonda misurerebbe un'altra cosa.
	initial["cosmetics"] = {"unlocked": FieldTools.consegnati_entro(2), "equipped": {}}
	var request := NativeWorldState.default_request("quota-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _i in range(40):
		await process_frame
	var eli: Node2D = world.get("player")
	var viste := 0
	for nodo in get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or str(nodo.get_meta("kind", "")) != "minigame":
			continue
		if viste >= 14:
			break
		viste += 1
		var area := nodo as Area2D
		eli.global_position = area.global_position
		world.set("nearby", [area])
		world.call("_refresh_prompt")
		var payload: Dictionary = area.get_meta("payload", {})
		print("QUOTA| %-12s attrezzo=%-6s | %s" % [
			str(payload.get("subject", "?")),
			"ok" if bool(world.call("_equipment_requirement_met", area)) else "MANCA",
			str(world.get("feedback_label").text)])
	if viste == 0:
		print("QUOTA| nessuna palestra sulla mappa: la sonda non sta misurando niente")
	quit(0)
