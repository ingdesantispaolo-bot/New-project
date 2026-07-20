extends SceneTree

func _init() -> void:
	for level in [1, 2, 6, 12, 20, 24]:
		var gate := ApparatusConfig.level_gate(level)
		assert(int(gate["level"]) == level)
		assert(int(gate["missionsRequired"]) >= 5)
		assert(float(gate["masteryThreshold"]) >= 0.70 and float(gate["masteryThreshold"]) <= 0.90)
		assert(str(gate["subject"]) != "")
		assert(str(gate["apparatus"]) != "")
	var save := GameSaveManager.new()
	var progression := ProgressionManager.new(save)
	save.set_level(1)
	for _i in range(5):
		progression.record_mission("matematica", 3, 3, 10, true)
	assert(progression.can_repair())
	assert(progression.repair_and_advance(true))
	assert(save.level() == 2)
	assert(save.missions_of("matematica") == 0)
	assert(save.data["apparatus"]["nucleo"]["repairedLevel"] == 1)
	print("C-05 audit OK — gate livelli 1/2/6/12/20/24 e reset apparato verificati")
	quit(0)
