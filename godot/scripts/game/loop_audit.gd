extends SceneTree

## Audit headless del loop di Fase 1: missioni esterne → gate → riparazione
## apparato → salita di livello. Non richiede rendering.
## Uso: godot --headless --path godot --script res://scripts/game/loop_audit.gd

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save)

	assert(save.level() == 1)
	assert(not prog.can_repair())

	var gate := prog.current_gate()
	var subject := str(gate["subject"])
	var apparatus := str(gate["apparatus"])

	# Svolge missioni (tutte corrette) finché il gate del livello non si apre.
	var missions_played := 0
	while not prog.can_repair() and missions_played < 200:
		var mission := content.build_mission(subject, save.level(), 3)
		var total := int(mission["nodes"].size())
		if total == 0:
			push_error("Banco vuoto per '%s': esegui `node scripts/build-exercise-banks.mjs`" % subject)
			quit(1)
			return
		prog.record_mission(subject, total, total, total * 10)
		missions_played += 1

	assert(prog.can_repair(), "il gate deve aprirsi dopo missioni + padronanza")

	var level_before := save.level()
	var advanced := prog.repair_and_advance(true)
	assert(advanced, "la riparazione deve avanzare di livello")
	assert(save.level() == level_before + 1)
	assert(save.missions_of(subject) == 0, "conteggio missioni azzerato al salire")
	assert(int(save.data["apparatus"][apparatus]["repairedLevel"]) == level_before)

	print("Loop Fase 1 OK — riparato '%s' (materia %s), ora livello %d dopo %d missioni; energia %d" % [apparatus, subject, save.level(), missions_played, save.energy()])
	quit(0)
