extends SceneTree

## C-P6 #8: il contratto accessibilità attraversa il mondo, non soltanto il
## renderer degli esercizi. Verifica anche bersagli touch essenziali.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# C-ART-9: i materiali sono condivisi nel gioco normale e spariscono davvero
	# (non solo per colore) quando si chiede il contrasto elevato.
	for surface in [
		SurfaceStyles.ship(false), SurfaceStyles.parchment(false),
		SurfaceStyles.desk(false, Color("6be7d6"), false),
	]:
		assert(surface is StyleBoxTexture, "superficie condivisa senza texture piastrellabile")
	for surface in [
		SurfaceStyles.ship(true), SurfaceStyles.parchment(true),
		SurfaceStyles.desk(true, Color("6be7d6"), false),
	]:
		var flat := surface as StyleBoxFlat
		assert(flat != null and flat.border_color == Color.WHITE and flat.border_width_left >= 4,
			"contrasto elevato non spegne la superficie illustrata")
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
		# Lo scatto (19 agosto 2026) è un comando di gioco a tutti gli effetti, e su
		# tablet è anche l'unica corsa che esista: sta nella lista dei bersagli
		# touch come gli altri.
		"ScattoButton",
		"OpenKnowledgeCodexButton",
		"CustomizeTouchControlsButton",
	]:
		var button := world.find_child(button_name, true, false) as Button
		assert(button != null and button.custom_minimum_size.y >= 44.0,
			"bersaglio touch insufficiente: %s" % button_name)
	var action := world.find_child("ContextInteractButton", true, false) as Button
	assert(action.visible and action.disabled,
		"il comando AZIONE deve restare visibile anche lontano dai POI")
	assert(str(action.text).contains("AVVICINATI"),
		"il comando AZIONE inattivo non spiega come abilitarlo")
	var customizer := world.find_child("TouchControlsCustomizer", true, false) as PanelContainer
	assert(customizer != null, "pannello di personalizzazione touch assente")
	world.set("touch_controls_settings", {"side": "left", "size": "standard", "opacity": 0.72})
	world.call("_apply_touch_controls_layout")
	var pulse_button := world.find_child("CombatPulseButton", true, false) as Button
	assert(action.anchor_left == 0.5 and pulse_button.anchor_left == 0.0
		and action.custom_minimum_size.y >= 64.0,
		"preset touch mancino/standard non applicato")
	# Tutte le azioni sotto lo stesso pollice: è il senso della preferenza di lato,
	# e un comando che resta dall'altra parte la rende inutile.
	var scatto_button := world.find_child("ScattoButton", true, false) as Button
	assert(scatto_button != null and scatto_button.anchor_left == pulse_button.anchor_left,
		"lo scatto non segue il lato scelto per i comandi touch")
	assert(scatto_button.offset_bottom <= pulse_button.offset_top,
		"lo scatto si sovrappone all'impulso invece di stargli sopra")
	assert(is_equal_approx(action.modulate.a, 0.72),
		"visibilità personalizzata dei comandi non applicata")

	var panel_style := world.call("_panel_style") as StyleBoxFlat
	assert(panel_style != null and panel_style.border_width_left >= 3 and panel_style.border_color == Color.WHITE,
		"contrasto elevato non applicato ai pannelli del mondo")
	var weather := world.get("world_weather_particles") as CPUParticles2D
	assert(weather == null or not weather.emitting,
		"particelle atmosferiche ancora animate con riduzione movimento")

	var first_enemy := enemies[0] as Node2D
	first_enemy.global_position = player.global_position + Vector2(48, 0)
	# L'impulso costa una carica dal 14 agosto 2026: senza, non si accende e qui
	# non ci sarebbe nessuna onda da misurare. La carica si accredita come la
	# otterrebbe il giocatore — superando prove.
	for _prova in range(PulseCharge.PROVE_PER_CARICA):
		PulseCharge.accredita(world.get("game_save"))
	world.call("_combat_pulse")
	var pulse := world.find_child("EliCombatPulse", true, false) as Node2D
	assert(pulse != null and pulse.scale.x <= 1.36,
		"impulso usa ancora l'espansione ampia con riduzione movimento")
	await create_timer(0.16).timeout
	assert(not is_instance_valid(pulse) or pulse.is_queued_for_deletion(),
		"feedback ridotto dell'impulso non viene ritirato")

	exercise.start_session({
		"kind": "practice",
		"subject": "italiano",
		"nodes": [{
			"format": "short_answer",
			"prompt": "Scrivi sì",
			"answer": "sì",
			"explanation": "Risposta test.",
		}],
	})
	var text_submit := exercise.find_child("TextAnswerSubmit", true, false) as Button
	assert(text_submit != null and text_submit.visible and text_submit.custom_minimum_size.y >= 48.0,
		"risposta testuale ancora dipendente dal tasto Invio")

	world.queue_free()
	await process_frame
	print("ACCESSIBILITY RELEASE audit OK — touch, contrasto elevato e riduzione movimento attraversano il mondo")
	quit(0)
