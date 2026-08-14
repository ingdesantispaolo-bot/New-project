extends SceneTree

const REACTION := preload("res://scripts/visual/world_learning_reaction.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Il runtime inoltra anche una missione ordinaria senza calcolare la resa.
	var gameplay := OutdoorGameplay.new()
	gameplay.active_session_context = {
		"kind": "mission", "encounterId": "ordinary-node", "theme": "matematica",
	}
	var relayed: Array = []
	gameplay.enigma_progress.connect(func(built, total, theme, encounter_id):
		relayed.append([built, total, theme, encounter_id]))
	gameplay.notify_progress(2, 3)
	assert(relayed == [[2, 3, "matematica", "ordinary-node"]],
		"il progresso della missione ordinaria non raggiunge la scena")

	# Ogni tipo d'incontro usa lo stesso contratto set_stage e lascia che il
	# visual già configurato per bioma scelga che cosa cambia.
	for kind in ["mission", "practice", "enigma", "minimission"]:
		var reaction := REACTION.new()
		reaction.setup("radure", kind, Color("6be7d6"))
		root.add_child(reaction)
		reaction.set_stage(1, 3)
		assert(reaction.active_parts.size() == 5, "%s non costruisce la propria reazione" % kind)
		assert((reaction.active_parts[0] as CanvasItem).visible,
			"%s non rende visibile il primo passaggio" % kind)
		assert(not bool(reaction.get("completed")), "%s si completa al primo passaggio" % kind)
		reaction.queue_free()

	print("EVENT PROGRESS VISUAL audit OK - missioni ordinarie e 4 tipi reagiscono per nodo")
	quit(0)
