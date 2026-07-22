extends SceneTree

## Audit C-16 full-Godot: il boot nativo conserva l'economia del save, uno
## stato iniziale esplicito non può far regredire il livello e un profilo nuovo
## può avviare una missione di recupero anche con energia zero.

func _init() -> void:
	_test_boot_preserva_economia()
	_test_initial_save_non_regredisce()
	_test_profilo_nuovo_non_resta_bloccato()
	print("C-16 audit OK — save nativo autoritativo e recupero energia attivo")
	quit(0)

func _test_boot_preserva_economia() -> void:
	var save := GameSaveManager.new()
	save.data["energy"] = 340
	save.data["fragments"] = 17
	save.set_level(5)
	save.apply_launch_state(NativeWorldState.default_request())
	assert(save.energy() == 340, "il boot nativo non deve sovrascrivere l'energia")
	assert(int(save.data.get("fragments", -1)) == 17, "il boot nativo non deve azzerare i frammenti")
	assert(save.level() == 5, "il boot nativo non deve far regredire il livello")

func _test_initial_save_non_regredisce() -> void:
	var save := GameSaveManager.new()
	save.set_level(5)
	var older := GameSaveManager._default_data()
	older["level"] = 3
	older["energy"] = 999
	save.apply_launch_state({"initialSave": older})
	assert(save.level() == 5 and save.energy() == 0, "uno stato esplicito più vecchio deve essere ignorato")

func _test_profilo_nuovo_non_resta_bloccato() -> void:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	gameplay.setup(NativeWorldState.default_request("c16-recovery"), NativeWorldState.empty_result(), false)
	assert(gameplay.game_save.energy() == 0, "fixture profilo nuovo non valida")
	assert(gameplay.try_start_mission({"subject": "matematica"}, "c16-first-mission"), "profilo nuovo bloccato senza energia")
	assert(int(gameplay.result.get("energySpent", -1)) == 0, "il recupero non deve creare spesa fantasma")
