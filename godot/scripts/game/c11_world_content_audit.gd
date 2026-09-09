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
	# La complessità FINE del generatore arriva a 8 al livello 24; sul nodo viaggia
	# il contratto comune usa ora la stessa scala 1..8 della complessità.
	assert(MathExerciseGenerator.complexity_for_level(24) == 8, "livello 24 deve usare complessita 8")
	for node in advanced["nodes"]:
		topics[str(node["topic"])] = true
	assert(topics.size() >= 14, "repertorio avanzato troppo stretto")
	_audit_banda_al_ventiquattro()
	assert(topics.has("equazioni") and topics.has("coordinate") and topics.has("statistica"), "mancano famiglie matematiche avanzate")
	var review := content.build_mission("matematica", 5, 3, {"matematica:tabelline": 2}, rng)
	var review_found := false
	for node in review["nodes"]:
		if str(node["topic"]) == "tabelline" and bool(node.get("review", false)):
			review_found = true
	assert(review_found, "ripasso tabelline non prioritario")

## **La banda del mondo 24, misurata invece che sperata.** (6 settembre 2026)
##
## La selezione ammette una tolleranza di ±1 attorno alla fascia del mondo per
## dare varietà e costruire il gradiente riscaldamento/finale. Al mondo 24 sono
## quindi lecite soltanto le fasce 7 e 8, e la 8 deve dominare. Quaranta semi
## verificano sia la media complessiva sia la missione peggiore: un solo seme
## nasconderebbe facilmente un impoverimento del banco.
const SEMI_BANDA := 40
const QUOTA_BANDA_MASSIMA := 80.0     # % di nodi in banda 8 su tutti i semi
const QUOTA_BANDA_PEGGIORE := 68.0    # % nella missione peggiore

func _audit_banda_al_ventiquattro() -> void:
	var in_banda_massima := 0
	var totale := 0
	var peggiore := 100.0
	for seme in range(SEMI_BANDA):
		var content := ContentManager.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + seme
		var nodi: Array = content.build_mission("matematica", 24, 25, {}, rng)["nodes"]
		if nodi.is_empty():
			continue
		var massima := 0
		for node in nodi:
			var banda := int(node.get("difficulty", 0))
			assert(banda >= 7, "al livello 24 un nodo è sceso alla banda %d, sotto la tolleranza di ±1" % banda)
			totale += 1
			if banda == ContentManager.DIFFICULTY_BANDS:
				massima += 1
				in_banda_massima += 1
		var quota := 100.0 * float(massima) / float(nodi.size())
		peggiore = minf(peggiore, quota)
	assert(totale > 0, "nessun nodo campionato al livello 24")
	var media := 100.0 * float(in_banda_massima) / float(totale)
	print("banda al mondo 24: %.1f%% in banda 8 (missione peggiore %.1f%%)" % [media, peggiore])
	assert(media >= QUOTA_BANDA_MASSIMA,
		"al livello 24 la banda massima è scesa al %.1f%%, sotto il pavimento di %.1f%%" % [media, QUOTA_BANDA_MASSIMA])
	assert(peggiore >= QUOTA_BANDA_PEGGIORE,
		"una missione del livello 24 ha solo il %.1f%% di banda massima, sotto il pavimento di %.1f%%" % [peggiore, QUOTA_BANDA_PEGGIORE])

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
