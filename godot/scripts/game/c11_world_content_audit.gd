extends SceneTree

## Regressione congiunta: perimetro 8x8 coperto, routing multi-materia e
## generazione matematica progressiva/anti-ripetizione.

func _init() -> void:
	_audit_world_boundary()
	_audit_math_progression()
	_audit_subject_routing()
	print("C-11 audit OK - confini naturali, 8 materie e matematica progressiva")
	quit(0)

func _audit_world_boundary() -> void:
	var manager := OutdoorChunkManager.new()
	root.add_child(manager)
	manager.configure("c11-boundary")
	var bounds := manager.world_bounds()
	assert(bounds.size == Vector2(7168, 7168), "il mondo deve restare 8x8 chunk")
	var recovered := manager.clamp_to_world(Vector2(-99999, 99999))
	assert(recovered.x > bounds.position.x and recovered.y < bounds.end.y, "recupero salvataggio fuori mappa")
	assert(manager.has_node("WorldBoundary/BoundaryBackdrop"), "fondale oltre confine assente")
	assert(manager.has_node("GlobalNavigationPaths"), "sentieri globali assenti")
	assert(manager.get_node("GlobalNavigationPaths").get_child_count() == 3, "ogni spline deve essere renderizzata una volta")
	var canopy := manager.get_node("WorldBoundary/NaturalBoundaryCanopy")
	assert(canopy.get_child_count() >= 100, "cintura naturale troppo rada")
	manager.queue_free()

func _audit_math_progression() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 74291
	var first := content.build_mission("matematica", 1, 6, {}, rng)
	var second := content.build_mission("matematica", 1, 6, {}, rng)
	var first_signatures := {}
	for node in first["nodes"]:
		first_signatures[str(node["signature"])] = true
	for node in second["nodes"]:
		assert(not first_signatures.has(str(node["signature"])), "esercizio matematico ripetuto nella missione successiva")
	var advanced := content.build_mission("matematica", 24, 25, {}, rng)
	var topics := {}
	for node in advanced["nodes"]:
		assert(int(node["difficulty"]) == 8, "livello 24 deve usare complessita 8")
		topics[str(node["topic"])] = true
	assert(topics.size() >= 14, "repertorio avanzato troppo stretto")
	assert(topics.has("equazioni") and topics.has("coordinate") and topics.has("statistica"), "mancano famiglie matematiche avanzate")
	var review := content.build_mission("matematica", 5, 3, {"matematica:tabelline": 2}, rng)
	var review_found := false
	for node in review["nodes"]:
		if str(node["topic"]) == "tabelline" and bool(node.get("review", false)):
			review_found = true
	assert(review_found, "ripasso tabelline non prioritario")

func _audit_subject_routing() -> void:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": 0},
		"initialSave": {
			"schemaVersion": 1, "playerId": "c11", "level": 1, "energy": 500, "fragments": 0,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"cosmetics": {"unlocked": [], "equipped": {}}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0, "completedEncounterIds": [], "collectedTreasureIds": []}
	var requested := {"session": {}}
	gameplay.session_requested.connect(func(session): requested["session"] = session)
	gameplay.setup(request, result, false)
	var cases := [
		[{"biome": "academy", "kind": "times"}, "matematica"],
		[{"biome": "academy", "kind": "mental"}, "italiano"],
		[{"biome": "wild", "kind": "times"}, "inglese"],
		[{"biome": "wild", "kind": "physicalGeo"}, "fisica"],
		[{"biome": "logic", "kind": "times"}, "coding"],
		[{"biome": "logic", "kind": "mental"}, "elettronica"],
		[{"biome": "crystal", "kind": "guardian"}, "musica"],
		[{"biome": "ruins", "kind": "mental"}, "latino"],
	]
	for index in range(cases.size()):
		requested["session"] = {}
		assert(gameplay.try_start_mission(cases[index][0], "c11-enc-%d" % index), "incontro multi-materia non avviabile")
		var session: Dictionary = requested["session"]
		assert(str(session["subject"]) == str(cases[index][1]), "routing materia errato per %s" % cases[index][0])
		gameplay.resolve_session({
			"subject": session["subject"], "correct": session["nodes"].size(), "total": session["nodes"].size(),
			"passed": true, "energyGained": 30, "missed": [], "reviewedOk": [],
		})
	gameplay.queue_free()
