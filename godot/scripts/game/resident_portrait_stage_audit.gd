extends SceneTree

const PORTRAIT := preload("res://scripts/ui/npc_portrait.gd")

func _init() -> void:
	assert(NpcCatalog.RESIDENTS.size() == 46, "attesi 46 residenti")
	for npc_id in NpcCatalog.RESIDENTS:
		assert(PORTRAIT.portrait_art_for(str(npc_id)) != null,
			"asset ritratto assente: %s" % npc_id)
		var seen: Array = []
		for stage in [0, 1, 2]:
			var portrait := PORTRAIT.new()
			portrait.configure(str(npc_id), str(NpcCatalog.RESIDENTS[npc_id].get("nome", npc_id)), stage)
			seen.append(int(portrait.get_meta("resident_stage", -1)))
		assert(seen == [0, 1, 2], "%s non espone tre pose di arco" % npc_id)
	var source := FileAccess.open("res://scripts/ui/npc_portrait.gd", FileAccess.READ).get_as_text()
	assert("_draw_stage_gesture" in source and "resident_stage" in source,
		"le tre versioni non cambiano gesto nel ritratto")
	print("RESIDENT PORTRAIT STAGE audit OK - 46 residenti × 3 pose")
	quit(0)
