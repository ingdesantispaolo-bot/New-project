extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("world-life-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var life = world.get("world_life")
	var actors: Array = world.get("npc_actors")
	assert(life != null, "regia WorldLife non montata")
	assert(actors.size() == 4, "cast del mondo 1 senza itinerante o oltre il budget")
	assert(life.debug_state().get("actorCount") == actors.size(), "cast e regia non concordano")

	var anchors: Dictionary = life.get("anchors")
	for actor in actors:
		var npc_id := str(actor.get_meta("id", ""))
		var points: Dictionary = anchors.get(npc_id, {})
		assert(points.has("home") and points.has("work") and points.has("ritrovo"),
			"%s non ha tre ancoraggi" % npc_id)
		for role in ["home", "work", "ritrovo"]:
			var point: Vector2 = points[role]
			assert(world.get("chunks").composition.raw_water_weight(point) < 0.24,
				"%s/%s finisce in acqua" % [npc_id, role])
			assert(not world.get("chunks").composition.is_protected(point, 40.0),
				"%s/%s invade safeRadius o safeRoute" % [npc_id, role])

	# In campo l'abitante non scivola; fuori campo compie un passo lento, non un
	# teletrasporto verso il lavoro.
	var probe := actors[0] as Area2D
	var probe_id := str(probe.get_meta("id", ""))
	probe.global_position = Dictionary(anchors[probe_id])["home"]
	var before := probe.global_position
	life.update("giorno", Vector2.ZERO, Rect2(before - Vector2(200, 150), Vector2(400, 300)), 1.0)
	assert(probe.global_position == before, "abitante mosso mentre era inquadrato")
	life.update("giorno", Vector2.ZERO, Rect2(Vector2(9000, 9000), Vector2(400, 300)), 1.0)
	var walked := probe.global_position.distance_to(before)
	assert(walked > 0.0 and walked <= WorldLife.MOVE_SPEED + 0.1,
		"cammino fuori campo non lento o assente")

	# Porta deterministicamente il cast al Ritrovo: la scena parte da sola e non
	# blocca mai il controller di Eli.
	for actor in actors:
		var npc_id := str(actor.get_meta("id", ""))
		actor.global_position = Dictionary(anchors[npc_id])["ritrovo"]
	var player := world.get("player") as OutdoorPlayerController
	var listening_position: Vector2 = Dictionary(anchors["w01-tobia"])["ritrovo"]
	assert(player.is_physics_processing(), "Eli fermo prima della conversazione")
	life.update("alba", Vector2(9000, 9000), Rect2(Vector2(9000, 9000), Vector2(300, 200)), 0.1)
	var started: Dictionary = life.debug_state()
	assert(bool(started.get("active")) and started.get("sceneId") == "w01-s0",
		"conversazione di stadio 0 non partita")
	assert(int(started.get("lineIndex")) == 0 and not bool(started.get("farewellShown")),
		"la scena non deve iniziare dal congedo")
	assert(player.is_physics_processing(), "la conversazione ha bloccato Eli")

	var base_count := int(started.get("baseLineCount"))
	for index in base_count:
		life.update("alba", listening_position, Rect2(Vector2(9000, 9000), Vector2(300, 200)), 8.0)
		if index < base_count - 1:
			assert(not bool(life.debug_state().get("farewellShown")),
				"Eli ha interrotto la conversazione prima della fine")
	assert(bool(life.debug_state().get("heard")) and bool(life.debug_state().get("farewellShown")),
		"il congedo non e' stato aggiunto soltanto alla fine")
	assert(player.is_physics_processing(), "Eli bloccato durante il congedo")
	life.update("alba", listening_position, Rect2(Vector2(9000, 9000), Vector2(300, 200)), 8.0)
	assert(not bool(life.debug_state().get("active")), "scena non conclusa dopo il congedo")

	# Coda notizie: le piu' vecchie decadono, cap assoluto 8, due usi massimi.
	for index in 10:
		life.enqueue_news({"type": "mission", "world": 1, "level": index})
	assert(Array(life.debug_state().get("news")).size() == WorldLife.NEWS_LIMIT,
		"coda notizie oltre il limite")
	var count_before := Array(life.debug_state().get("news")).size()
	life.call("_consume_news")
	assert(Array(life.debug_state().get("news")).size() == count_before,
		"notizia rimossa prima del secondo uso")
	life.call("_consume_news")
	assert(Array(life.debug_state().get("news")).size() == count_before - 1,
		"notizia non rimossa al secondo uso")
	for _day in WorldLife.NEWS_MAX_DAYS:
		life.call("_age_news")
	assert(Array(life.debug_state().get("news")).is_empty(), "notizie vecchie non decadono")

	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame
	print("WORLD LIFE audit OK - tre ancoraggi, fuori campo, Ritrovo non bloccante, congedo e notizie")
	quit(0)
