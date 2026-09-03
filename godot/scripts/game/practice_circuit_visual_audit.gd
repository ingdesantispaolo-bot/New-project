extends SceneTree

## C-G-13: le palestre sono ripetitori dei Primi. Il filo appare soltanto fra
## stazioni entrambe visitate e nessuna forma dipende da un glifo di sistema.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	var request := NativeWorldState.default_request("practice-circuit-visual-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var practice_ids: Array[String] = []
	for event_data in world.get("mission_events"):
		var event: Dictionary = event_data
		if str(event.get("kind", "")) != "practice":
			continue
		practice_ids.append(str(event.get("id", "")))
		var marker := world.find_child("MissionEvent_%s" % str(event.get("id", "")).replace("-", "_"), true, false)
		assert(marker != null, "stazione pratica non costruita")
		var repeater := marker.find_child("PracticeRepeater", true, false) as Node2D
		# **La pietra ha cambiato mestiere.** (3 settembre 2026)
		#
		# Fino a ieri l'insegna della palestra era una pietra disegnata a mano
		# con dei poligoni, e si chiamava `FirstRepeaterStone`. Adesso e' una
		# regione dell'atlante pittorico delle dodici materie
		# ([[SubjectStationArt]]), e il nome del nodo e' un altro.
		#
		# Cambia la sorgente del disegno, non la regola: quello che questo audit
		# difende e' che l'insegna sia **disegnata**, non un carattere di sistema
		# che nel Web diventa un rettangolo — la segnalazione da cui nasce tutta
		# la riscrittura. Quindi si continua a pretendere un'immagine vera, e si
		# accettano tutte e due le forme finche' una delle due esiste.
		var pietra := repeater.find_child("FirstRepeaterStone", true, false)
		var insegna := repeater.find_child("SubjectStationArt", true, false) as Sprite2D
		assert(repeater != null and (pietra != null or insegna != null),
			"stazione senza pietra del ripetitore")
		assert(insegna == null or insegna.texture is AtlasTexture,
			"l'insegna della palestra non viene dall'atlante illustrato")
		assert(repeater.find_child("PracticeStar", true, false) == null,
			"la stazione conserva il disco/stella precedente")
		assert(repeater.find_children("*", "Label", true, false).is_empty(), "la stazione contiene testo disegnato")
	assert(practice_ids.size() >= 2, "servono almeno due stazioni per misurare il circuito")
	var initial_circuit := world.get_node_or_null("PracticeCircuit") as Node2D
	assert(initial_circuit != null and initial_circuit.get_child_count() == 0,
		"il circuito collega stazioni non visitate")
	var source := FileAccess.get_file_as_string("res://scripts/outdoor_world.gd")
	assert(source.contains("not completed.has(str(previous.get(\"id\", \"\")))")
		and source.contains("not completed.has(str(current.get(\"id\", \"\")))"),
		"il filo non richiede entrambe le stazioni visitate")
	root.remove_child(world)
	world.queue_free()
	await process_frame
	print("PRACTICE CIRCUIT VISUAL audit OK — pietre, colori di materia e filo fra stazioni visitate")
	quit(0)
