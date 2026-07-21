extends SceneTree

## Smoke audit release: profilo nuovo, save canonico, banco multi-materia e
## stato iniziale nave. Non richiede rete o browser.

func _init() -> void:
	var save := GameSaveManager.new()
	assert(save.level() == 1)
	assert(save.energy() == 0)
	assert(save.data.has("narrative"))
	assert(save.data.has("daily"))
	var content := ContentManager.new()
	for subject in ["matematica", "italiano", "inglese", "coding", "fisica", "musica", "latino", "elettronica"]:
		assert((content.build_mission(subject, 1, 1)["nodes"] as Array).size() == 1)
	var hub := HubController.new()
	root.add_child(hub)
	hub.setup(save)
	assert(not hub.request_exam())
	print("C-10 audit OK — nuovo profilo, 8 banchi e Hub iniziale verificati")
	quit(0)
