extends SceneTree

## C-P6 #8: il contratto accessibilità attraversa il mondo, non soltanto il
## renderer degli esercizi. Verifica anche bersagli touch essenziali.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 20
	initial["worlds"] = {"unlocked": range(1, 21), "current": 20}
	var request := NativeWorldState.default_request("accessibility-release-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 20
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}

	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	assert(bool(world.get("high_contrast")), "contrasto elevato non acquisito dal mondo")
	assert(bool(world.get("reduced_motion")), "riduzione movimento non acquisita dal mondo")
	var player := world.get("player") as OutdoorPlayerController
	assert(player != null and player.reduced_motion, "Eli non riceve la riduzione movimento")
	var camera := world.get("camera") as Camera2D
	assert(camera != null and not camera.position_smoothing_enabled,
		"camera smoothing ancora attivo con riduzione movimento")
	var exercise := world.get("exercise_player") as ExercisePlayer
	assert(exercise != null and exercise.high_contrast and exercise.reduced_motion,
		"preferenze non propagate agli esercizi")

	var enemies := get_nodes_in_group("world_enemy")
	assert(enemies.size() == 4, "tier tardo deve istanziare quattro anomalie")
	for enemy in enemies:
		assert(bool(enemy.get("reduced_motion")), "anomalia non rispetta riduzione movimento")

	for button_name in [
		"ContextInteractButton",
		"CombatPulseButton",
		"OpenKnowledgeCodexButton",
	]:
		var button := world.find_child(button_name, true, false) as Button
		assert(button != null and button.custom_minimum_size.y >= 44.0,
			"bersaglio touch insufficiente: %s" % button_name)

	var panel_style: StyleBoxFlat = world.call("_panel_style")
	assert(panel_style.border_width_left >= 3 and panel_style.border_color == Color.WHITE,
		"contrasto elevato non applicato ai pannelli del mondo")
	var weather := world.get("world_weather_particles") as CPUParticles2D
	assert(weather == null or not weather.emitting,
		"particelle atmosferiche ancora animate con riduzione movimento")

	var first_enemy := enemies[0] as Node2D
	first_enemy.global_position = player.global_position + Vector2(48, 0)
	world.call("_combat_pulse")
	var pulse := world.find_child("EliCombatPulse", true, false) as Node2D
	assert(pulse != null and pulse.scale.x <= 1.36,
		"impulso usa ancora l'espansione ampia con riduzione movimento")
	await create_timer(0.16).timeout
	assert(not is_instance_valid(pulse) or pulse.is_queued_for_deletion(),
		"feedback ridotto dell'impulso non viene ritirato")

	world.queue_free()
	await process_frame
	print("ACCESSIBILITY RELEASE audit OK — touch, contrasto elevato e riduzione movimento attraversano il mondo")
	quit(0)
