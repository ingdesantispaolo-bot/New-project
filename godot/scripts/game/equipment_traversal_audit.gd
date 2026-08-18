extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const EQUIPMENT_GATE := preload("res://scripts/visual/equipment_gate.gd")

## C-P6 #6: strumenti con effetto esplorativo reale e nessun soft-lock sui gate.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(RewardCatalog.find("tool-torch").get("slot", "") == "tool", "torcia assente dal catalogo")
	assert(RewardCatalog.find("tool-scythe").get("slot", "") == "tool", "falce assente dal catalogo")
	assert(RewardCatalog.by_slot("tool").size() >= 2, "categoria strumenti incompleta")

	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["energy"] = 1000
	# Gli strumenti si comprano in bottega, e la bottega si paga in frammenti dal
	# 14 agosto 2026 ([[FragmentEconomy]]): senza questi, l'acquisto della torcia
	# fallirebbe per un motivo che non c'entra niente con la traversata.
	initial["fragments"] = 1000
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	var request := NativeWorldState.default_request("equipment-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	# Le sole aree strumentali del Director sono pratiche opzionali.
	var tool_area: Area2D
	for event in world.get("mission_events"):
		var id := str(event.get("id", ""))
		var area := world.find_child("MissionEvent_%s" % id.replace("-", "_"), true, false) as Area2D
		if area == null:
			continue
		var payload: Dictionary = area.get_meta("payload", {})
		if str(payload.get("requiredTool", "")) != "":
			assert(str(event.get("kind", "")) == "practice", "uno strumento non deve bloccare eventi del gate")
			tool_area = area
			break
	assert(tool_area != null, "manca una deviazione opzionale legata all'equipaggiamento")
	assert(not bool(world.call("_equipment_requirement_met", tool_area)), "il POI deve essere chiuso senza strumento")
	var required := str(Dictionary(tool_area.get_meta("payload", {})).get("requiredTool", ""))
	# Gli strumenti non si comprano più (14 agosto 2026): li consegna il mondo
	# dopo una riparazione. L'audit usa la stessa porta che usa il gioco.
	assert(not world.get("gameplay").try_purchase_cosmetic(required),
		"uno strumento di campo non deve essere acquistabile in bottega")
	assert(world.get("gameplay").reward_manager.deliver_field_tool(required),
		"consegna dello strumento richiesto fallita")
	world.get("gameplay").call("_emit_state")
	await process_frame
	assert(str(world.call("equipped_field_tool")) == required, "lo strumento non è equipaggiato nel runtime")
	assert(bool(world.call("_equipment_requirement_met", tool_area)), "il POI non si apre dopo l'equip")

	var light := world.get("player").get_node("PlayerNightLight") as PointLight2D
	if required == "tool-torch":
		assert(light.energy > 1.0 and light.texture_scale >= 3.0, "la torcia non amplia la luce locale")

	# La falce modifica anche la collisione, non soltanto l'etichetta.
	var gate := EQUIPMENT_GATE.new()
	root.add_child(gate)
	gate.configure("tool-scythe", "")
	await process_frame
	var grass := gate.get_node("TallGrassBlocker") as StaticBody2D
	assert(not gate.is_open() and grass.get_child_count() >= 8, "erba alta non invalicabile")
	gate.set_equipped_tool("tool-scythe")
	await process_frame
	assert(gate.is_open(), "la falce non apre il passaggio")
	for child in grass.get_children():
		assert((child as CollisionShape2D).disabled, "collisione dell'erba ancora attiva")

	world.queue_free()
	gate.queue_free()
	await process_frame
	print("EQUIPMENT TRAVERSAL audit OK — torcia/falce utili, POI opzionali e nessun soft-lock")
	quit(0)
