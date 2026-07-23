extends SceneTree

## Gate Opus P1 (O-P1): fixture deterministiche del MissionEventDirector su tutti
## i 24 mondi. Verifica determinismo, disponibilità delle missioni (non-blocco),
## rispetto della zona nave, varietà dei formati e distinzione dei tipi di evento.
## Uso: godot --headless --path godot --script res://scripts/game/mission_event_director_audit.gd

func _context_for(level: int) -> Dictionary:
	return {
		"missionsRequired": int(ApparatusConfig.level_gate(level).get("missionsRequired", 5)),
		"weakTopics": ["alpha", "beta"],
		"dueTopics": ["ripasso-1"],
		"recentFormats": ["multiple_choice"],
	}

func _init() -> void:
	var seed_a := "seed-fixture-A"
	var seed_b := "seed-fixture-B"

	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var subject := str(profile["learningFocus"]["subject"])
		var ctx := _context_for(level)
		var required := int(ctx["missionsRequired"])

		# 1) Determinismo: stesso seed + stato → eventi identici.
		var run1 := MissionEventDirector.plan(profile, ctx, seed_a)
		var run2 := MissionEventDirector.plan(profile, ctx, seed_a)
		assert(run1 == run2, "livello %d: il director deve essere deterministico" % level)
		# Seed diverso → almeno una posizione diversa (varietà tra mondi/seed).
		var run3 := MissionEventDirector.plan(profile, ctx, seed_b)
		assert(run3.size() == run1.size(), "livello %d: la struttura non dipende dal seed" % level)
		assert(run3 != run1, "livello %d: seed diversi devono produrre una disposizione diversa" % level)

		# 2) Disponibilità / non-blocco: abbastanza eventi-gate del focus raggiungibili.
		var reachable := MissionEventDirector.reachable_gate_events(run1, subject)
		assert(reachable >= required, "livello %d: eventi-gate raggiungibili %d < richiesti %d" % [level, reachable, required])

		var ship: Vector2 = profile["shipEntrance"]["position"]
		var safe_radius := float(profile["shipEntrance"]["safeRadius"])
		var half_extent := float(profile["worldHalfExtent"])
		var has_mission := false
		var has_enigma := false
		var has_practice := false
		var last_format := ""
		for e in run1:
			# 3) Zona nave: nessun evento entro il raggio protetto.
			var pos: Vector2 = e["position"]
			assert(pos.distance_to(ship) >= safe_radius, "livello %d: evento %s dentro la zona nave" % [level, str(e["id"])])
			# Dentro l'area giocabile.
			assert(absf(pos.x - ship.x) <= half_extent + 1.0 and absf(pos.y - ship.y) <= half_extent + 1.0, "livello %d: evento fuori area" % level)
			# 4) Nessun formato ripetuto tra eventi consecutivi.
			var fmt := str(e["format"])
			assert(fmt != last_format, "livello %d: formato ripetuto consecutivo (%s)" % [level, fmt])
			last_format = fmt
			# La pratica non conta per il gate; missioni/enigmi sì.
			match str(e["kind"]):
				"mission":
					has_mission = true
					assert(bool(e["countsForGate"]), "la missione deve contare per il gate")
				"enigma":
					has_enigma = true
					assert(bool(e["countsForGate"]), "l'enigma deve contare per il gate")
				"practice":
					has_practice = true
					assert(not bool(e["countsForGate"]), "la pratica NON deve contare per il gate")
			# Il topic suggerito, se presente, viene dai candidati (ripasso/deboli).
			var hint := str(e["topicHint"])
			if hint != "":
				assert(hint == "ripasso-1" or hint == "alpha" or hint == "beta", "topicHint fuori dai candidati")

		assert(has_mission, "livello %d: manca almeno una missione-tappa" % level)
		assert(has_practice, "livello %d: manca almeno un evento di pratica" % level)
		# L'enigma è presente dove la grammatica lo ammette (multipli di 3 e non solo).
		if int(profile["missionGrammar"].get("enigma", 0)) > 0:
			assert(has_enigma, "livello %d: la grammatica ammette enigmi ma nessuno è stato generato" % level)

	print("MissionEventDirector audit OK — 24 mondi: deterministico, missioni disponibili, zona nave rispettata, formati vari")
	quit(0)
