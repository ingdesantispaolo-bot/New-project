extends SceneTree

## Verifica che la potenza dei sette ponti sia una proiezione monotona dei 24
## livelli didattici e che il progresso pre-esame non conceda una tacca intera.

func _init() -> void:
	var save := GameSaveManager.new()
	var fresh := ShipActivationModel.activation_for_room(save, "central")
	assert(int(fresh["stage"]) == 0 and float(fresh["ratio"]) == 0.0, "una nave nuova deve essere inerte")

	var host := ApparatusConfig.world_subject(1)
	var gate := ApparatusConfig.apparatus_gate(host, 1)
	save.add_mission(host)
	save.set_mastery(host, float(gate["masteryThreshold"]))
	var ready := ShipActivationModel.activation_for_room(save, "central")
	assert(float(ready["ratio"]) > 0.0, "lo studio deve illuminare progressivamente il ponte")
	assert(int(ready["completed"]) == 0, "il gate pronto non equivale all'esame superato")

	save.set_apparatus_repaired(str(gate["apparatus"]), 1)
	save.set_level(2)
	save.reset_missions()
	var repaired := ShipActivationModel.activation_for_room(save, "central")
	assert(int(repaired["completed"]) == 1, "il livello superato deve accendere un nodo")
	assert(float(repaired["ratio"]) > float(fresh["ratio"]), "la riattivazione deve essere monotona")

	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		save.set_apparatus_repaired(
			ApparatusConfig.apparatus_of(ApparatusConfig.world_subject(level)), level)
	save.set_level(ApparatusConfig.MAX_LEVEL + 1)
	var completed_progression := ProgressionManager.new(save)
	assert(completed_progression.is_complete(), "il livello successivo all'ultimo gate deve chiudere la campagna")
	assert(not completed_progression.can_level_up(), "a campagna completa non si sale oltre")
	var gate_total := 0
	for room_id in ShipRoomCatalog.ids():
		var activation := ShipActivationModel.activation_for_room(save, str(room_id))
		gate_total += int(activation["total"])
		assert(int(activation["stage"]) == 4, "%s non raggiunge piena potenza" % room_id)
		assert(int(activation["percent"]) == 100, "%s non arriva al 100%%" % room_id)
	assert(gate_total == ApparatusConfig.MAX_LEVEL, "ogni gate deve alimentare esattamente un ponte")
	assert(ShipRoomCatalog.room_for_apparatus("cratere-logico") == "central", "Coding/Logica devono alimentare il Ponte Centrale")
	assert(ShipRoomCatalog.room_for_apparatus("archivio-temporale") == "data_core", "Storia deve alimentare il Data-core")
	assert(ShipRoomCatalog.room_for_subject("storia") == "data_core", "Storia deve essere presentata nel Data-core")
	print("SHIP ACTIVATION audit OK - 24 gate, 7 ponti, 5 fasi monotone")
	quit(0)
