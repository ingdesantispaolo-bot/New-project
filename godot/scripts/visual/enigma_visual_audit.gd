extends SceneTree

func _init() -> void:
	var cases := [
		["ponte", "il Ponte dei Primi"], ["porta", "la Porta delle Parole"],
		["circuito", "il Circuito dei Cicli"], ["cristalli", "i Cristalli dell'Armonia"],
		["reattore", "il Reattore dei Moti"],
		["mappa", "la Mappa Stellare"], ["serra", "la Serra Bio"],
		["rete", "la Rete Civica"], ["griglia", "la Griglia Logica"],
	]
	for test_case in cases:
		var visual := EnigmaStructureVisual.new()
		visual.setup(str(test_case[0]), str(test_case[1]))
		root.add_child(visual)
		await process_frame
		assert(visual.is_in_group("enigma_poi"), "visual enigma non registrato nel gruppo")
		assert(visual.has_method("set_stage"), "contratto set_stage assente")
		assert(visual.get_node("Campata1") != null and visual.get_node("Campata4") != null, "quattro moduli non creati per %s" % test_case[0])
		visual.set_stage(2, 4)
		await process_frame
		assert(visual.get_node("Campata1").visible and visual.get_node("Campata2").visible, "progresso 2/4 non visibile")
		assert(not visual.get_node("Campata3").visible, "modulo futuro mostrato troppo presto")
		visual.set_stage(4, 4)
		await process_frame
		assert(visual.get_node("Campata4").visible, "struttura completa non visibile")
		assert(visual.get_node("CompletionGlow").energy > 0.0, "rifinitura finale assente")
		visual.queue_free()
		await process_frame
	print("ENIGMA VISUAL audit OK - 9 temi, progressione, marker e completamento")
	quit(0)
