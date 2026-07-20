extends SceneTree

func _init() -> void:
	var save := GameSaveManager.new()
	var narrative := NarrativeManager.new()
	narrative.setup(save)
	var first := narrative.reveal_level(1)
	var second := narrative.reveal_level(1)
	assert(str(first["text"]).begins_with("NORA:"))
	assert(str(second["text"]) == str(first["text"]))
	assert((save.data["narrative"]["seen"] as Array).size() == 1)
	assert(narrative.beat_for_level(6) != "")
	print("C-07 audit OK — beat NORA 1→6 data-driven e persistente")
	quit(0)
