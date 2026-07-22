extends SceneTree

## Smoke test dell'esame che accende realmente un nodo e completa la sequenza
## celebrativa senza lasciare overlay o burst bloccati.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var hub := (load("res://scenes/hub.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame
	var save: GameSaveManager = hub.get("save")
	save.data = GameSaveManager._default_data()
	var gate := ApparatusConfig.level_gate(1)
	for _index in int(gate["missionsRequired"]):
		save.add_mission(str(gate["subject"]))
	save.set_mastery(str(gate["subject"]), float(gate["masteryThreshold"]))
	var controller: HubController = hub.get("controller")
	controller.refresh()
	await hub.call("_on_exam_finished", {
		"passed": true,
		"subject": str(gate["subject"]),
		"correct": 3,
		"total": 3,
		"seconds": 1.0,
	})
	var activation := ShipActivationModel.activation_for_room(save, "central")
	assert(save.level() == 2, "l'esame non ha avanzato il livello")
	assert(int(activation["completed"]) == 1, "la sequenza non ha acceso il nodo del ponte")
	var celebration := hub.find_child("ActivationCelebration", true, false) as Control
	assert(celebration != null and not celebration.visible, "overlay celebrativo rimasto visibile")
	var material: ShaderMaterial = hub.get("background_material")
	assert(float(material.get_shader_parameter("transition_burst")) <= 0.001, "burst shader non terminato")
	print("SHIP REACTIVATION SEQUENCE audit OK - esame, nodo, VFX e chiusura overlay")
	quit(0)
