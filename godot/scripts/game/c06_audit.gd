extends SceneTree

func _init() -> void:
	var save := GameSaveManager.new()
	save.data["energy"] = 200
	var hub := HubController.new()
	root.add_child(hub)
	hub.setup(save)
	assert(not hub.request_exam(), "esame non disponibile prima del gate")
	var progression := hub.progression
	for _i in range(5):
		progression.record_mission("matematica", 3, 3, 0, true)
	assert(hub.request_exam(), "esame disponibile dopo il gate")
	assert(bool(hub.state()["ready"]))
	assert(str(hub.state()["apparatus"]) == "nucleo")
	print("C-06 audit OK — HubController espone gate e stato apparato")
	quit(0)
