extends SceneTree

## Il diario dentro il mondo: il bottone c'è, il pannello si apre, i numeri
## mostrati sono quelli veri, e il mondo si ferma mentre lo leggi.
##
## Perché serve oltre a `diary_audit` (che prova la logica isolata): un
## riepilogo giusto che nessuno disegna vale quanto un campo `daily` che nessuno
## scrive — cioè niente. È esattamente il difetto che ha reso necessario questo
## lavoro, e non voglio ripeterlo un piano più su.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = 100
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("diary-panel-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _cleanup(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.free()
		audio.set("_stream_cache", {})
	await create_timer(0.15).timeout

func _testi(nodo: Node) -> String:
	var out := ""
	for etichetta in nodo.find_children("*", "Label", true, false):
		out += (etichetta as Label).text + "\n"
	return out

func _run() -> void:
	root.size = Vector2i(1000, 700)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request())
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var gameplay := world.get("gameplay") as OutdoorGameplay
	var save := gameplay.game_save
	var pannello: Control = world.get("diary_panel")
	var bottone := world.find_child("OpenDiaryButton", true, false) as Button
	var player: Node2D = world.get("player")

	assert(pannello != null, "il diario non esiste nel mondo")
	assert(bottone != null, "manca il bottone del diario nell'HUD")
	assert(bottone.custom_minimum_size.y >= 44.0,
		"bersaglio touch del diario troppo basso: %d" % bottone.custom_minimum_size.y)
	assert(not pannello.visible, "il diario è aperto senza che nessuno l'abbia chiesto")

	# Dati veri da mostrare.
	PlayDiary.register_day(save, "2026-08-01")
	PlayDiary.register_day(save, "2026-08-02")
	PlayDiary.register_day(save, "2026-08-03")
	save.data["progressReport"] = {"events": [
		{"level": 1, "subject": "matematica", "mastery": 0.5, "missions": 1, "seconds": 120.0},
		{"level": 1, "subject": "matematica", "mastery": 0.6, "missions": 0, "seconds": 90.0},
		{"level": 1, "subject": "storia", "mastery": 0.4, "missions": 1, "seconds": 60.0},
	]}

	bottone.pressed.emit()
	await process_frame
	assert(pannello.visible, "il bottone non ha aperto il diario")
	assert(not player.is_physics_processing(),
		"il mondo continua a girare sotto il diario aperto")

	var testo := _testi(pannello)
	assert(testo.contains("Giorni giocati"), "il diario non mostra i giorni giocati")
	# Riga esatta, non «contiene 3»: un 3 qualunque a schermo passerebbe per caso
	# e l'audit direbbe verde su un numero sbagliato.
	assert(testo.contains("Giorni giocati\n3\n"),
		"i giorni giocati non sono 3 come registrato:\n%s" % testo)
	assert(testo.contains("Superate\n2\n"),
		"le prove superate non sono 2 come registrato:\n%s" % testo)
	assert(testo.contains("Affrontate\n3\n"),
		"le prove affrontate non sono 3 come registrato:\n%s" % testo)
	assert(testo.contains("Superate"), "il diario non mostra le prove superate")
	assert(testo.contains("Matematica") and testo.contains("Storia"),
		"il diario non mostra le materie giocate")
	assert(testo.contains("2026-08-01"), "il diario non dice da quando giochi")
	# Il tono: nessuna percentuale di errore, nessun obiettivo da raggiungere.
	for vietato in ["fallit", "sbagliat", "obiettivo", "% di errore"]:
		assert(not testo.to_lower().contains(vietato),
			"il diario usa un tono da pagella: contiene «%s»" % vietato)

	var chiudi := pannello.find_child("DiaryCloseButton", true, false) as Button
	assert(chiudi != null, "il diario non ha un modo per chiuderlo")
	chiudi.pressed.emit()
	await process_frame
	assert(not pannello.visible, "il diario non si è chiuso")
	assert(player.is_physics_processing(), "il mondo non è ripartito dopo il diario")

	await _cleanup(world)
	print("DIARY PANEL audit OK — bottone, apertura, numeri veri, mondo fermo, chiusura")
	quit(0)
