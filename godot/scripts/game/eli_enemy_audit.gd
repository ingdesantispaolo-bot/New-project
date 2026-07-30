extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PLAYER := preload("res://scripts/player_controller.gd")

## C-P6 #7/#8: Eli usa le 4 direzioni del foglio a 20 frame; le anomalie
## ostacolano senza sottrarre progresso e l'impulso è disponibile su tablet.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Animazione direzionale: il vecchio runtime restava sempre sul frame (0,0).
	var controller := PLAYER.new()
	var presentation := OutdoorVisualFactory.build_player(Color("6be7d6"))
	controller.add_child(presentation)
	controller.visual = presentation.get_node("Visual")
	root.add_child(controller)
	var sprite := controller.visual.find_child("EliSprite", true, false) as Sprite2D
	assert(sprite != null and sprite.texture is AtlasTexture, "sprite Eli non animabile")
	var sheet := (sprite.texture as AtlasTexture).atlas
	assert(sheet.resource_path.ends_with("eli-adventure-girl-sheet-v2.png"),
		"il runtime non usa il foglio pittorico C-P6 approvato")
	assert(sheet.get_width() == 480 and sheet.get_height() == 384,
		"foglio Eli non conforme al contratto 5x4 da 96 px")
	controller.velocity = Vector2.RIGHT * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 192.0, "direzione destra non usa la riga che guarda a destra")
	assert((sprite.texture as AtlasTexture).region.position.x > 0.0, "camminata ferma sul frame idle")
	controller.velocity = Vector2.LEFT * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 288.0, "direzione sinistra non usa la riga che guarda a sinistra")
	controller.velocity = Vector2.UP * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 96.0, "direzione su non usa la riga corretta")
	controller.velocity = Vector2.DOWN * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 0.0, "direzione giù non usa la riga corretta")
	controller.velocity = Vector2.ZERO
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 0.0, "Eli cambia direzione quando si ferma")
	controller.play_pulse_action()
	controller.call("_animate", 0.01)
	assert((sprite.texture as AtlasTexture).region.position.x == 384.0, "posa impulso assente")
	controller.queue_free()

	var initial := GameSaveManager._default_data()
	initial["level"] = 7
	initial["energy"] = 500
	initial["worlds"] = {"unlocked": range(1, 8), "current": 7}
	var request := NativeWorldState.default_request("eli-enemy-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 7
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var enemies := get_nodes_in_group("world_enemy")
	assert(enemies.size() == 2, "il mondo 7 deve scalare a due anomalie, trovate %d" % enemies.size())
	var pulse := world.find_child("CombatPulseButton", true, false) as Button
	assert(pulse != null and pulse.custom_minimum_size.x >= 64.0 and pulse.custom_minimum_size.y >= 64.0, "impulso touch insufficiente")

	var player: CharacterBody2D = world.get("player")
	var first: Node2D = enemies[0]
	first.global_position = player.global_position + Vector2(54, 0)
	first.set("anchor", first.global_position)
	var energy_before := int(world.get("game_save").energy())
	world.call("_combat_pulse")
	await process_frame
	assert(bool(first.call("is_stunned")), "l'impulso non stabilizza l'anomalia vicina")
	assert(int(world.get("game_save").energy()) == energy_before, "il combattimento non deve tassare l'energia didattica")
	assert(pulse.disabled, "cooldown dell'impulso non comunicato al touch")

	var second: Node2D = enemies[1]
	second.global_position = player.global_position - Vector2(28, 0)
	var before_contact := player.global_position
	world.call("_on_enemy_contact", second, player)
	assert(player.global_position.distance_to(before_contact) > 40.0, "il nemico non ostacola/respinge Eli")
	assert(int(world.get("game_save").energy()) == energy_before, "il contatto non deve togliere energia o mastery")

	world.queue_free()
	await process_frame
	print("ELI/ENEMY audit OK — 20 frame direzionali, ostacoli per livello e impulso touch non punitivo")
	quit(0)
