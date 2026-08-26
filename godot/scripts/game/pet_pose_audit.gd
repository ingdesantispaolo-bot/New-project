extends SceneTree

const COMPANION := preload("res://scripts/pet_companion.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var target := OutdoorPlayerController.new()
	root.add_child(target)
	var pet := COMPANION.new()
	root.add_child(pet)
	pet.setup("spark", Color("f6c85f"), target, "vivace", true)
	for signal_name in PetExpressionEngine.GAME_SIGNALS:
		pet.react_to(str(signal_name))
		assert(str(pet.get_meta("expression_pose", "")) == PetExpressionEngine.face_for_pet(str(signal_name), "vivace", "spark"),
			"posa non collegata al segnale %s" % signal_name)
	assert(pet.find_child("PetExpressionPose", true, false) != null,
		"nodo visuale delle pose assente")
	assert(not pet.has_method("grant_reward") and not pet.has_method("write_mastery"),
		"la resa del Custode non deve concedere potere")
	print("PET POSE audit OK - tutti i segnali hanno una posa del corpo")
	quit(0)
