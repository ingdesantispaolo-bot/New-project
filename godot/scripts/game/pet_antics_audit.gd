extends SceneTree

const ANTICS := preload("res://scripts/game/pet_antics.gd")

func _init() -> void:
	var scheduler := ANTICS.new()
	root.add_child(scheduler)
	scheduler.configure(PetState.BASE_ANTICS, false)
	for context in ["exercise", "exam", "beat"]:
		assert(scheduler.try_start(context) == "", "combinella partita durante %s" % context)
	var sequence: Array[String] = []
	for _i in range(PetState.BASE_ANTICS.size()):
		var antic_id: String = scheduler.try_start("world")
		assert(antic_id != "", "combinella di mondo non partita")
		sequence.append(antic_id)
		scheduler._active = ""
	assert(sequence == PetState.BASE_ANTICS, "ordine non deterministico: %s" % str(sequence))
	assert(scheduler.try_start("world") != "", "fixture interruzione non partita")
	scheduler.set_blocked(true)
	assert(scheduler.active_antic() == "", "combinella continua entrando in una sessione")
	assert(ANTICS.MIN_INTERVAL_SEC >= 90.0, "combinelle troppo frequenti")
	var save := GameSaveManager.new()
	var energy_before := save.energy()
	var fragments_before := save.fragments()
	var level_before := save.level()
	assert(PetState.antics(save).size() == 4, "il Custode deve partire con quattro combinelle")
	assert(save.energy() == energy_before and save.fragments() == fragments_before
		and save.level() == level_before, "le combinelle hanno toccato progressione o economia")
	scheduler.configure(PetState.BASE_ANTICS, true)
	assert(scheduler.is_reduced_motion(), "riduzione movimento non acquisita")
	print("Pet antics audit OK — 4 combinelle, 90s, nessuna durante sessione/esame/beat")
	quit(0)
