extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://scripts/outdoor_world.gd", FileAccess.READ)
	assert(file != null, "scena mondo assente")
	var source := file.get_as_text()
	assert("pending_minimission_reveal" in source,
		"la minimissione è ancora visibile dal primo ingresso")
	assert("WorldLight.prove_nel_mondo" in source,
		"la comparsa non distingue un mondo appena iniziato da uno già giocato")
	assert("func _reveal_pending_minimissions" in source,
		"manca la regia di comparsa mentre si gioca")
	var light_hook := source.find("func _on_world_light_changed")
	var reveal_call := source.find("_reveal_pending_minimissions()", light_hook)
	assert(light_hook >= 0 and reveal_call > light_hook and reveal_call - light_hook < 400,
		"la prima prova riuscita non accende la minimissione")
	assert("TRANS_BACK" in source.substr(reveal_call, 1600),
		"la comparsa non ha una transizione visuale percepibile")
	print("MINIMISSION REVEAL audit OK - assente all'ingresso, si accende alla prima prova")
	quit(0)
