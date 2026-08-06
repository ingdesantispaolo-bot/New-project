extends SceneTree

## Verifica C-16 del percorso realmente servito: menu nativo -> mondo -> nave
## -> mondo. L'audit usa gli stessi change_scene_to_file dei pulsanti live.
## Uso: godot --headless --path godot --script res://scripts/game/boot_navigation_audit.gd

const BOOT_SCENE := "res://scenes/boot_menu.tscn"
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Il percorso più vincolante viene giocato nel viewport tablet target. Il
	# round-trip desktop è coperto da roundtrip_audit.gd.
	root.size = Vector2i(900, 600)
	assert(str(ProjectSettings.get_setting("application/run/main_scene")) == BOOT_SCENE,
		"run/main_scene deve puntare al menu Godot nativo")

	var boot_scene: PackedScene = load(BOOT_SCENE)
	var boot: Node = boot_scene.instantiate()
	root.add_child(boot)
	current_scene = boot
	await process_frame
	var play_button := boot.find_child("PlayButton", true, false) as Button
	assert(play_button != null and play_button.text == "GIOCA", "il menu deve esporre il pulsante GIOCA")
	var boot_hint := boot.find_child("BootInputHint", true, false) as Label
	assert(boot_hint != null and "Tocca GIOCA" in boot_hint.text,
		"il boot deve dichiarare il percorso touch, non soltanto la tastiera")
	assert(play_button.size.y >= 58.0 and play_button.get_global_rect().intersection(root.get_visible_rect()).has_area(),
		"GIOCA deve restare un bersaglio touch visibile nel viewport tablet")
	play_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
		"GIOCA deve aprire il mondo nativo")
	assert(current_scene.get("game_save") != null and current_scene.get("progression_manager") != null,
		"il mondo deve inizializzare gameplay e progressione senza errori di script")
	assert(str(current_scene.get("request").get("worldSeed", "")) != "",
		"il mondo nativo deve inizializzare la propria sessione")
	# Il save di sviluppo può essere rimasto su un gate già pronto: porta
	# esplicitamente l'audit nella fase missioni prima di verificare l'HUD.
	var gameplay = current_scene.get("gameplay")
	var save = current_scene.get("game_save")
	save.set_level(1)
	save.data["worlds"] = {"unlocked": [1], "current": 1}
	save.reset_missions()
	save.set_mastery("matematica", 0.0)
	gameplay.call("_emit_state")
	await process_frame
	assert(current_scene.find_child("NucleoApparatusTerminal", true, false) == null,
		"l'esame finale non deve avere un terminale nel mondo esterno")
	assert(not current_scene.has_method("start_final_exam"),
		"la scena mondo non deve esporre una scorciatoia all'esame finale")
	var guide_button := current_scene.find_child("GuideToShipButton", true, false) as Button
	assert(guide_button != null and guide_button.text == "SEGUI LA MISSIONE",
		"prima del gate l'HUD deve esporre la rotta della missione")
	var ship_navigation := current_scene.find_child("ShipNavigation", true, false) as Label
	assert(ship_navigation != null and "PARLA CON" in ship_navigation.text,
		"prima della richiesta la bussola deve indicare il proprietario")
	var mission_nodes := get_nodes_in_group("mission_poi")
	var max_required := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		max_required = maxi(max_required, MissionEventDirector.HOST_EVENTS)
	assert(mission_nodes.size() >= max_required,
		"i settori caricati devono contenere abbastanza POI unici per aprire qualunque gate")
	var first_mission := mission_nodes[0] as Area2D
	var routed_payload: Dictionary = current_scene.call("_mission_payload_for", first_mission)
	assert(str(routed_payload.get("subject", "")) == str(current_scene.get("world_profile").get("learningFocus", {}).get("subject", "")),
		"gli eventi del Director devono mantenere il focus autorato dal WorldProfile")
	assert(bool(first_mission.get_meta("directorEvent", {}).get("countsForGate", false)),
		"la bussola deve puntare soltanto a eventi che contano per il gate")
	var outdoor_player := current_scene.get("player") as CharacterBody2D
	assert(outdoor_player != null, "il mondo deve contenere Eli")
	var context_button := current_scene.find_child("ContextInteractButton", true, false) as Button
	assert(context_button != null, "il mondo deve esporre il comando touch contestuale")
	guide_button.pressed.emit()
	var owner := current_scene.call("_npc_actor_by_id", "w01-tobia") as Area2D
	assert(owner != null and outdoor_player.get("touch_target").distance_to(owner.global_position) < 0.01,
		"SEGUI LA MISSIONE deve portare prima da Tobia, senza teleport")
	current_scene.call("_open_npc_dialogue", "w01-tobia")
	var request_box := current_scene.get("dialogue_box") as Control
	assert(request_box.visible, "la richiesta di Tobia deve precedere la missione")
	request_box.call("close_dialogue")
	await process_frame
	# Tablet: un tap sul POI deve impostare l'avvicinamento e avviare la stessa
	# interazione del tasto E quando Eli entra nel raggio.
	var assigned_route: Dictionary = current_scene.call("_ownership_navigation_target")
	var touch_mission := assigned_route.get("node") as Area2D
	assert(touch_mission != null and str(assigned_route.get("message", "")).begins_with("Richiesta ricevuta"),
		"serve la missione appena affidata per l'audit touch")
	var touch_event := InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = current_scene.get_viewport().get_canvas_transform() * touch_mission.global_position
	current_scene.call("_unhandled_input", touch_event)
	assert(current_scene.get("pending_touch_interaction") == touch_mission,
		"il tap sul POI deve memorizzare l'interazione in arrivo")
	assert(outdoor_player.get("touch_target").distance_to(current_scene.call("_touch_approach_position", touch_mission)) < 0.01,
		"il tap deve guidare Eli a distanza d'interazione, non al centro del POI")
	outdoor_player.global_position = touch_mission.global_position
	current_scene.call("_update_pending_touch_interaction")
	await process_frame
	var touch_exercise: ExercisePlayer = current_scene.get("exercise_player")
	assert(touch_exercise.visible and str(touch_exercise.session.get("kind", "")) in ["mission", "enigma"],
		"all'arrivo il tap deve aprire una tappa-gate senza tasto E")
	current_scene.call("_on_exercise_finished", {
		"kind": str(touch_exercise.session.get("kind", "mission")),
		"subject": str(touch_exercise.session.get("subject", "matematica")),
		"correct": 0, "total": 3, "passed": false, "energyGained": 0,
		"topicStats": {},
	})
	await process_frame

	var portal := current_scene.find_child("ExitPortal", true, false) as Node2D
	assert(portal != null, "il mondo deve contenere l'ingresso nave deterministico")
	var ready_gate: Dictionary = current_scene.get("progression_manager").current_gate()
	var ready_threshold := float(ready_gate.get("masteryThreshold", 0.7))
	# L'esame dell'apparato dipende dalla materia che ABITA il mondo; il livello dal
	# nucleo. La fixture soddisfa entrambi.
	var ready_subjects: Array = Array(ready_gate.get("coreSubjects", [])).duplicate()
	var host_subject := ApparatusConfig.world_subject(save.level())
	if not ready_subjects.has(host_subject):
		ready_subjects.append(host_subject)
	for subject_data in ready_subjects:
		var ready_subject := str(subject_data)
		save.add_mission(ready_subject)
		save.set_mastery(ready_subject, ready_threshold)
		# La readiness richiede anche COPERTURA per argomento.
		# La copertura richiesta scala col livello e con la materia.
		for topic in ["t0","t1","t2","t3","t4","t5","t6","t7","t8","t9","t10","t11","t12","t13","t14","t15","t16","t17","t18","t19","t20","t21","t22","t23"]:
			save.set_topic_mastery(ready_subject, topic, ready_threshold)
	gameplay.call("_emit_state")
	await process_frame
	assert(bool(portal.get("gate_ready")), "il portale deve cambiare stato quando l'esame è pronto")
	assert("ESAME PRONTO" in ship_navigation.text,
		"la bussola deve richiamare il rientro quando il gate è pronto")
	assert(guide_button.text == "RAGGIUNGI LA NAVE",
		"quando il gate è pronto il comando missione deve diventare rientro nave")
	var ready_objective := current_scene.find_child("CurrentObjective", true, false) as Label
	assert(ready_objective != null and "Raggiungi la nave" in ready_objective.text,
		"l'obiettivo deve sostituire i requisiti con il richiamo alla nave")
	var portal_area: Area2D = null
	for child in portal.get_children():
		if child is Area2D and str(child.get_meta("kind", "")) == "portal":
			portal_area = child
			break
	assert(portal_area != null, "l'ingresso nave deve essere interagibile")
	guide_button.pressed.emit()
	assert(outdoor_player.get("touch_target").distance_to(portal.global_position) < 0.01,
		"il pulsante deve guidare Eli al portale senza cambiare scena")
	assert(current_scene.scene_file_path == WORLD_SCENE,
		"Raggiungi la nave non deve teletrasportare fuori dal mondo")
	outdoor_player.global_position = portal.global_position
	current_scene.call("on_interactable_entered", portal_area, outdoor_player)
	assert(context_button.visible and context_button.text == "ENTRA NELLA NAVE",
		"vicino al portale il tablet deve mostrare un pulsante contestuale grande")
	context_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == HUB_SCENE,
		"l'interazione con l'ingresso nativo deve entrare nella nave")
	var map_button := current_scene.find_child("WorldMapButton", true, false) as Button
	assert(map_button != null, "la nave deve esporre la mappa dei mondi")
	map_button.pressed.emit()
	var map_overlay := current_scene.find_child("WorldMapOverlay", true, false) as Control
	assert(map_overlay != null and map_overlay.visible, "la mappa deve aprirsi come overlay touch")
	var world_one_button := current_scene.find_child("WorldTravel_01", true, false) as Button
	var world_two_button := current_scene.find_child("WorldTravel_02", true, false) as Button
	assert(world_one_button != null and not world_one_button.disabled and "CORRENTE" in world_one_button.text,
		"il mondo corrente deve essere riconoscibile e selezionabile")
	assert(world_two_button != null and world_two_button.disabled and "BLOCCATO" in world_two_button.text,
		"il mondo non sbloccato deve essere visivamente bloccato")
	var close_map := current_scene.find_child("CloseWorldMapButton", true, false) as Button
	close_map.pressed.emit()
	assert(not map_overlay.visible, "la mappa deve chiudersi senza lasciare la nave")
	var back_button := current_scene.find_child("BackToWorldButton", true, false) as Button
	assert(back_button != null and not back_button.disabled, "la nave deve offrire Torna al mondo")
	var viewport_rect := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	assert(back_button.is_visible_in_tree() and back_button.get_global_rect().intersection(viewport_rect).has_area(),
		"Torna al mondo deve essere realmente visibile e cliccabile nel viewport")
	back_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
		"Torna al mondo deve riaprire outdoor_world.tscn")

	var ending_scene := current_scene
	root.remove_child(ending_scene)
	ending_scene.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.free()
		audio.set("_stream_cache", {})
	await create_timer(0.15).timeout
	print("C-16 boot/navigation audit OK — touch POI -> missione, menu -> mondo -> nave -> mondo")
	quit(0)
