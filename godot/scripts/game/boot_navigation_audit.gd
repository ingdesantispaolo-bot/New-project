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
	assert(str(ProjectSettings.get_setting("application/run/main_scene")) == BOOT_SCENE,
		"run/main_scene deve puntare al menu Godot nativo")

	var boot_scene: PackedScene = load(BOOT_SCENE)
	var boot: Node = boot_scene.instantiate()
	root.add_child(boot)
	current_scene = boot
	await process_frame
	var play_button := boot.find_child("PlayButton", true, false) as Button
	assert(play_button != null and play_button.text == "GIOCA", "il menu deve esporre il pulsante GIOCA")
	play_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
		"GIOCA deve aprire il mondo nativo")
	assert(current_scene.get("game_save") != null and current_scene.get("progression_manager") != null,
		"il mondo deve inizializzare gameplay e progressione senza errori di script")
	assert(str(current_scene.get("request").get("worldSeed", "")) != "",
		"il mondo nativo deve inizializzare la propria sessione")

	current_scene.call("_leave_world")
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == HUB_SCENE,
		"il portale nativo deve entrare nella nave")
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

	print("C-16 boot/navigation audit OK — menu -> mondo -> nave -> mondo")
	quit(0)
