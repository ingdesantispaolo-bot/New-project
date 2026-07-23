extends SceneTree

## Cattura GPU dell'unico ingresso nave nel mondo, nello stato gate pronto.

const OUTPUT_DIR := "res://../artifacts/world"
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame

	var save: GameSaveManager = world.get("game_save")
	save.set_level(1)
	save.reset_missions()
	var progression: ProgressionManager = world.get("progression_manager")
	var gate := progression.current_gate()
	var subject := str(gate.get("subject", "matematica"))
	for index in range(int(gate.get("missionsRequired", 1))):
		save.add_mission(subject)
	save.set_mastery(subject, float(gate.get("masteryThreshold", 0.7)))
	# Evidenza per-argomento: la readiness del gate richiede anche COPERTURA.
	for topic in ["a", "b", "c"]:
		save.set_topic_mastery(subject, topic, float(gate.get("masteryThreshold", 0.7)))
	world.get("gameplay").call("_emit_state")

	var portal := world.find_child("ExitPortal", true, false) as Node2D
	var player := world.get("player") as CharacterBody2D
	player.global_position = portal.global_position + Vector2(210, 115)
	player.set_physics_process(false)
	await _settle()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if await _capture("ingresso-nave-esame-pronto-wide.png") != OK:
		push_error("SHIP ENTRY RENDER probe: renderer grafico non disponibile")
		quit(2)
		return

	# Layout tablet: Eli entra nel raggio del portale e deve comparire il grande
	# comando contestuale, senza dipendere da tastiera o tasto E.
	root.size = Vector2i(1024, 768)
	player.global_position = portal.global_position + Vector2(42, 18)
	var portal_area: Area2D = null
	for child in portal.get_children():
		if child is Area2D and str(child.get_meta("kind", "")) == "portal":
			portal_area = child
			break
	if portal_area == null:
		push_error("SHIP ENTRY RENDER probe: area portale assente")
		quit(2)
		return
	world.call("on_interactable_entered", portal_area, player)
	await _settle()
	if await _capture("ingresso-nave-touch-tablet.png") != OK:
		push_error("SHIP ENTRY RENDER probe: cattura tablet non disponibile")
		quit(2)
		return
	root.size = Vector2i(800, 1280)
	await _settle()
	if await _capture("ingresso-nave-touch-tablet-portrait.png") != OK:
		push_error("SHIP ENTRY RENDER probe: cattura tablet portrait non disponibile")
		quit(2)
		return
	print("SHIP ENTRY RENDER probe OK - wide + touch tablet landscape/portrait")
	quit(0)

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.18).timeout

func _capture(file_name: String) -> Error:
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name]))
