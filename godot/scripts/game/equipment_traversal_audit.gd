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
	# Raggio 2 e non 0: i forzieri arrivano dallo streaming dei chunk, e con raggio
	# zero non ne esiste nessuno da provare. Prima bastava zero perché il varco si
	# cercava fra gli eventi del Director, che nascono con la scena.
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	for _giro in range(30):
		await process_frame

	# **Dove sta un varco, e dove non sta.** (riscritto il 4 settembre 2026)
	#
	# Fino a oggi questa prova cercava una PALESTRA chiusa da uno strumento, e
	# pretendeva che ce ne fosse una. Era la meccanica giusta provata sul nodo
	# sbagliato: le palestre sono una per materia, quindi una palestra chiusa è
	# una materia chiusa, e il gate le chiede tutte e dodici. Chi arrivava al
	# mondo 2 senza la falce ne allenava sette — vedi
	# `materie_raggiungibili_audit`, nato da quella segnalazione.
	#
	# Le porte adesso stanno solo dove il progetto ha sempre detto: sui forzieri,
	# davanti ai frammenti. La prova qui sotto non cambia di sostanza — un POI
	# chiuso che si apre quando lo strumento arriva — cambia su che cosa gira, e
	# aggiunge la riga che prima mancava: **niente varchi sulle palestre**.
	var tool_area: Area2D
	for nodo in world.get_tree().get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or not world.is_ancestor_of(nodo):
			continue
		var area := nodo as Area2D
		var payload: Dictionary = area.get_meta("payload", {})
		if str(payload.get("requiredTool", "")) == "":
			continue
		assert(not bool(payload.get("countsForGate", false)),
			"uno strumento non deve bloccare eventi del gate")
		assert(str(area.get_meta("kind", "")) != "minigame",
			"una palestra è dietro uno strumento: è una per materia, quindi è la materia a essere chiusa")
		if not bool(world.call("_equipment_requirement_met", area)):
			tool_area = area
			break
	assert(tool_area != null, "manca una deviazione opzionale chiusa da uno strumento")
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
