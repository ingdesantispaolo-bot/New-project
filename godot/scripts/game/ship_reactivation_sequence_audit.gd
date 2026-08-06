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
	var host := ApparatusConfig.world_subject(1)
	var gate := ApparatusConfig.apparatus_gate(host, 1)
	save.add_mission(host)
	save.set_mastery(host, ApparatusConfig.subject_mastery_threshold(host, save.level()))
	# Il gate P0 usa quattro dimensioni: oltre a confidenza e accuratezza,
	# l'audit deve preparare anche una copertura reale di topic. La ritenzione è
	# soddisfatta perché il save nuovo non contiene ripassi arretrati.
	for topic in ["audit-a", "audit-b", "audit-c"]:
		save.set_topic_mastery(host, topic, 1.0)
	var controller: HubController = hub.get("controller")
	controller.refresh()
	assert(controller.progression.can_repair_apparatus(host),
		"fixture nave incompleta: il gate a quattro dimensioni non è pronto")
	await hub.call("_on_exam_finished", {
		"passed": true,
		"subject": host,
		"correct": 3,
		"total": 3,
		"seconds": 1.0,
	})
	var activation := ShipActivationModel.activation_for_room(save, "central")
	# L'esame accende la stanza; il livello lo apre il nucleo, allenato altrove.
	assert(
		int(save.data.get("apparatus", {}).get(ApparatusConfig.apparatus_of(host), {}).get("repairedLevel", 0)) == 1,
		"l'esame deve accendere la stanza")
	assert(int(activation["completed"]) == 1, "la sequenza non ha acceso il nodo del ponte")
	var celebration := hub.find_child("ActivationCelebration", true, false) as Control
	assert(celebration != null and not celebration.visible, "overlay celebrativo rimasto visibile")
	var material: ShaderMaterial = hub.get("background_material")
	assert(float(material.get_shader_parameter("transition_burst")) <= 0.001, "burst shader non terminato")
	assert(str(hub.get_meta("last_milestone_kind", "")) == "ship_reactivation",
		"regia del traguardo non classificata")
	assert(Array(hub.get_meta("last_milestone_cues", [])).has("focus")
		and Array(hub.get_meta("last_milestone_cues", [])).has("ignition")
		and Array(hub.get_meta("last_milestone_cues", [])).has("reveal"),
		"la sequenza non contiene i tre tempi di regia")
	assert(bool(hub.get_meta("last_milestone_complete", false)),
		"sequenza non arrivata al ripristino finale")
	var background := hub.get("background") as TextureRect
	assert(background != null and background.scale.is_equal_approx(Vector2.ONE),
		"camera simulata non ripristinata")
	print("SHIP REACTIVATION SEQUENCE audit OK - focus, accensione, reveal, audio e chiusura")
	quit(0)
