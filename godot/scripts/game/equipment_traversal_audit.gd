extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const EQUIPMENT_GATE := preload("res://scripts/visual/equipment_gate.gd")

## C-P6 #6: strumenti con effetto esplorativo reale e nessun soft-lock sui gate.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for tool_id in FieldTools.ids():
		assert(RewardCatalog.find(str(tool_id)).get("slot", "") == "tool",
			"strumento «%s» assente dal catalogo delle ricompense" % tool_id)
	assert(RewardCatalog.by_slot("tool").size() >= FieldTools.ids().size(),
		"categoria strumenti incompleta")

	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["energy"] = 1000
	# I frammenti restano nella fixture per provare che uno strumento non diventa
	# acquistabile neppure quando si avrebbe abbastanza per pagarlo.
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

	# **Possedere apre; equipaggiare non c'entra.** (19 agosto 2026)
	#
	# Con cinque strumenti, far dipendere una porta dallo slot indossato
	# significherebbe tornare in bottega davanti a ogni rovo. La prova mette in
	# mano DUE attrezzi, ne indossa uno, e pretende che si apra la porta
	# dell'altro.
	var altro := ""
	for tool_id in FieldTools.ids():
		if str(tool_id) != required \
				and not world.get("gameplay").reward_manager.owned(str(tool_id)):
			altro = str(tool_id)
			break
	assert(altro != "", "manca un secondo strumento non ancora posseduto per la prova")
	assert(world.get("gameplay").reward_manager.deliver_field_tool(altro),
		"consegna del secondo strumento fallita")
	world.get("gameplay").reward_manager.equip(altro)
	world.get("gameplay").call("_emit_state")
	await process_frame
	assert(str(world.call("equipped_field_tool")) == altro,
		"lo slot indossato non è cambiato: la prova successiva non proverebbe niente")
	assert(bool(world.call("_equipment_requirement_met", tool_area)),
		"la porta si è richiusa perché lo strumento non è quello indossato: una chiave che hai è una chiave che hai")

	# Gli ostacoli che BLOCCANO modificano la collisione, non soltanto l'etichetta.
	# Si prova su tutti, non solo sulla falce: leva e soffietto sono arrivati dopo
	# e senza questo ciclo sarebbero potuti nascere come cartelli dipinti.
	for tool_id in FieldTools.ids():
		if not FieldTools.blocca(str(tool_id)):
			continue
		var gate := EQUIPMENT_GATE.new()
		root.add_child(gate)
		gate.configure(str(tool_id), [])
		await process_frame
		var blocco := gate.get_node("GateBlocker") as StaticBody2D
		assert(not gate.is_open() and blocco != null and blocco.get_child_count() >= 8,
			"«%s»: ostacolo dichiarato bloccante ma senza collisione" % tool_id)
		gate.set_strumenti([str(tool_id)])
		await process_frame
		assert(gate.is_open(), "«%s» non apre il proprio passaggio" % tool_id)
		for child in blocco.get_children():
			assert((child as CollisionShape2D).disabled,
				"«%s»: collisione ancora attiva dopo l'apertura" % tool_id)
		gate.queue_free()

	# E quelli che RIVELANO non devono avere collisione: torcia e lente non
	# fermano il passo, rendono illeggibile. Sono due sensazioni diverse, e un
	# muro invisibile davanti a un'iscrizione sarebbe la sensazione sbagliata.
	for tool_id in FieldTools.ids():
		if FieldTools.blocca(str(tool_id)):
			continue
		var gate := EQUIPMENT_GATE.new()
		root.add_child(gate)
		gate.configure(str(tool_id), [])
		await process_frame
		assert(gate.get_node_or_null("GateBlocker") == null,
			"«%s» ferma il passo: doveva soltanto nascondere" % tool_id)
		assert(not gate.is_open(), "«%s» nasce già aperto senza lo strumento" % tool_id)
		gate.queue_free()

	world.queue_free()
	await process_frame
	print("EQUIPMENT TRAVERSAL audit OK — cinque strumenti utili, possesso e non equip, POI opzionali e nessun soft-lock")
	quit(0)
