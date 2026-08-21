extends SceneTree

## Tappa 2 · P4/P7: personalizzazione persistente, tocco lungo e indole del
## corpo. Verifica anche che il pannello non possa concedere vantaggi di gioco.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const FACE_WIDGET := preload("res://scripts/ui/pet_face_widget.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_state_contract()
	assert(FACE_WIDGET.press_action(0.2) == "cuddle", "tocco breve non classificato come carezza")
	assert(FACE_WIDGET.press_action(FACE_WIDGET.LONG_PRESS_SEC) == "screen",
		"pressione lunga non apre la schermata")
	await _test_world_screen()
	print("Pet customization audit OK — tocco lungo, stato cosmetico e indole persistenti")
	quit(0)

func _test_state_contract() -> void:
	var save := GameSaveManager.new()
	PetState.grant(save, 1)
	var energy_before := save.energy()
	var fragments_before := save.fragments()
	var level_before := save.level()
	assert(PetState.set_temperament(save, "calmo") == "calmo", "indole valida non salvata")
	assert(PetState.set_temperament(save, "punitivo") == "calmo", "indole estranea accettata")
	assert(PetState.set_livery(save, PetState.LIVERIES[2]) == PetState.LIVERIES[2],
		"livrea valida non salvata")
	var palette_before := PetState.livery(save)
	PetState.set_livery(save, [0, 0])
	assert(PetState.livery(save) == palette_before, "livrea non autorizzata accettata")
	assert(PetState.set_resting_face(save, "curioso") == "sereno",
		"volto bloccato usato come riposo")
	PetState.add_bond(save, 0.25)
	assert(PetState.set_resting_face(save, "curioso") == "curioso",
		"volto sbloccato non selezionabile")
	assert(save.energy() == energy_before and save.fragments() == fragments_before
		and save.level() == level_before,
		"la personalizzazione ha toccato economia o progressione")

func _test_world_screen() -> void:
	var initial := GameSaveManager._default_data()
	var pet := PetState.DEFAULT.duplicate(true)
	pet["grantedAtLevel"] = 1
	pet["name"] = "Briciola"
	initial["pet"] = pet
	initial["cosmetics"] = {
		"unlocked": ["pet-guardiano"],
		"equipped": {"pet": "pet-guardiano"},
		"inventory": [],
	}
	var request := NativeWorldState.default_request("pet-customization-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var face := world.get("pet_face") as Control
	var screen := world.get("pet_screen") as Control
	var player := world.get("player") as OutdoorPlayerController
	var companion := world.get("pet_companion") as OutdoorPetCompanion
	assert(face != null and face.visible, "volto del Custode consegnato non visibile")
	assert(companion != null, "Custode gratuito senza corpo perché non acquistato in bottega")
	assert(face.call("current_pet_kind") == "guardiano",
		"il pulsante del Custode non mostra la forma equipaggiata")
	var body_art := companion.find_child("PetGeneratedArt", true, false) as Sprite2D
	assert(body_art != null and body_art.texture.resource_path.ends_with("guardiano-v1.png"),
		"il corpo nel mondo non usa la stessa forma del pulsante")
	assert(screen != null and not screen.visible, "schermata Custode aperta all'avvio")
	face.emit_signal("screen_requested")
	await process_frame
	assert(screen.visible, "tocco lungo non apre la schermata reale")
	assert(not player.is_physics_processing(), "Eli continua a muoversi dietro la schermata")
	for control_name in ["ClosePetScreen", "PetScreenName", "SavePetName", "PetTemperament"]:
		var control := screen.find_child(control_name, true, false) as Control
		assert(control != null and control.custom_minimum_size.y >= 44.0,
			"bersaglio touch assente o piccolo: %s" % control_name)
	var panel := screen.find_child("PetScreenPanel", true, false) as PanelContainer
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(style != null and style.border_width_left >= 4 and style.border_color == Color.WHITE,
		"contrasto elevato non applicato alla schermata Custode")
	var gallery := screen.find_child("PetFaceGallery", true, false) as GridContainer
	assert(gallery != null and gallery.get_child_count() == PetState.faces(world.get("game_save")).size(),
		"l'album non mostra una faccetta per ogni espressione sbloccata")
	var preview_faces: Array = []
	for card in gallery.get_children():
		var preview := card.get_child(0) as PetFaceWidget
		assert(preview != null, "anteprima faccetta assente dall'album")
		preview_faces.append(preview.current_face())
	var unique_faces: Dictionary = {}
	for face_id in preview_faces:
		unique_faces[str(face_id)] = true
	assert(preview_faces.size() == 5 and unique_faces.size() == preview_faces.size(),
		"l'album ripete la stessa espressione al posto delle faccette distinte")

	var save := world.get("game_save") as GameSaveManager
	var energy_before: int = save.energy()
	screen.call("_choose_temperament", 3)
	assert(PetState.temperament(save) == "serio", "scelta indole non propagata al save")
	assert(save.energy() == energy_before, "il pannello ha concesso energia")
	screen.call("close_screen")
	await process_frame
	assert(not screen.visible and player.is_physics_processing(),
		"chiusura non restituisce il controllo a Eli")

	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
	await process_frame
	await process_frame
