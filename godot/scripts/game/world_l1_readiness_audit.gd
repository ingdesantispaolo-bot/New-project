extends SceneTree

## Lotto L1: rende esplicito che i mondi 1-6 non stanno solo ereditando un
## runtime che compila, ma rispettano l'intero giro dei mondi 7-10.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const CHUNK_GROUND := preload("res://scripts/chunk_ground.gd")
const EXPECTED := {
	1: {"theme": "radura", "artKit": "natura-rovine"},
	2: {"theme": "archive", "artKit": "carta-e-foglie"},
	3: {"theme": "crater", "artKit": "macchine-e-loop"},
	4: {"theme": "signal_bay", "artKit": "segnali-e-onde"},
	5: {"theme": "motion_forge", "artKit": "leve-e-carrelli"},
	6: {"theme": "resonance_garden", "artKit": "cristalli-vibranti"},
	7: {"theme": "glyph_ruins", "artKit": "pietra-e-iscrizioni"},
	8: {"theme": "circuit_delta", "artKit": "generatori-e-cavi"},
	9: {"theme": "charted_archipelago", "artKit": "mappe-e-quote"},
	10: {"theme": "symbiosis_greenhouse", "artKit": "flora-e-fauna"},
	11: {"theme": "history_threshold", "artKit": "reperti-e-prime-civiltà"},
	12: {"theme": "rule_labyrinth", "artKit": "muri-mobili"},
	13: {"theme": "orbital_desert", "artKit": "strumenti-astrali"},
	14: {"theme": "voices_library", "artKit": "libri-e-eco"},
	15: {"theme": "machine_city", "artKit": "automi-e-cavi"},
	16: {"theme": "language_frontier", "artKit": "insegne-multilingua"},
	17: {"theme": "force_ocean", "artKit": "pressione-e-flussi"},
	18: {"theme": "sound_cathedral", "artKit": "canne-e-archi"},
	19: {"theme": "root_necropolis", "artKit": "epigrafi-e-radici"},
	20: {"theme": "electromagnetic_storm", "artKit": "sensori-e-scariche"},
	21: {"theme": "fractured_atlas", "artKit": "strati-e-climi"},
	22: {"theme": "deep_biosphere", "artKit": "cellule-e-energia"},
	23: {"theme": "hall_of_eras", "artKit": "mosaici-manoscritti-e-fonti"},
}

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = level
	initial["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	if level == 5:
		initial["apparatus"] = {"ponte-comando": {"repairedLevel": 1}}
	var request := NativeWorldState.default_request("world-l1-readiness-%d" % level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = level
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	return request

func _run() -> void:
	root.size = Vector2i(900, 600)
	var levels: Array = EXPECTED.keys()
	var requested := OS.get_environment("ELI_READINESS_LEVELS").strip_edges()
	if requested != "":
		levels = []
		for token in requested.split(",", false):
			var level := int(token.strip_edges())
			if EXPECTED.has(level) and not levels.has(level):
				levels.append(level)
	levels.sort()
	for level in levels:
		await _check_world(level)
	print("World readiness OK - mondi %s cablati" % ",".join(levels.map(func(level): return str(level))))
	quit(0)

func _check_world(level: int) -> void:
	var world = WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request_for(level))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var expected: Dictionary = EXPECTED[level]
	var chunks := world.get("chunks") as OutdoorChunkManager
	assert(chunks != null and chunks.composition != null, "mondo %d senza composizione" % level)
	assert(chunks.composition.visual_theme == str(expected["theme"]),
		"mondo %d: tema visuale non specifico" % level)
	var underpaint := str(CHUNK_GROUND.IDENTITY_UNDERPAINT_PATHS.get(expected["theme"], ""))
	if level == 1:
		assert(CHUNK_GROUND.UNDERPAINT_ACADEMY != null,
			"mondo 1: underpaint Accademia assente dalla pipeline")
	else:
		assert(underpaint != "" and ResourceLoader.exists(underpaint),
			"mondo %d: underpaint specifico assente dalla pipeline" % level)

	var buildings: Array = world.get("world_buildings")
	assert(buildings.size() == 3, "mondo %d: non ha i tre edifici" % level)
	var roles: Array = []
	for building in buildings:
		roles.append(str(building.get_meta("building_role", "")))
		assert(str(building.get_meta("artKit", "")) == str(expected["artKit"]),
			"mondo %d: edificio non vestito col proprio artKit" % level)
	for role in ["work_home", "ritrovo", "first_ruin"]:
		assert(roles.has(role), "mondo %d: manca edificio %s" % [level, role])

	var actors: Array = world.get("npc_actors")
	assert(actors.size() == 4, "mondo %d: cast non entro il budget 3+1" % level)
	var expected_cast: Dictionary = NpcCatalog.for_world(level)
	for npc_id in Array(expected_cast.get("residents", [])) + Array(expected_cast.get("bislacchi", [])):
		assert(actors.any(func(actor): return str(actor.get_meta("id", "")) == str(npc_id)),
			"mondo %d: manca %s" % [level, npc_id])
	assert(actors.filter(func(actor): return str(actor.get_meta("id", "")).begins_with("itin-")).size() == 1,
		"mondo %d: deve avere un solo itinerante" % level)
	var life = world.get("world_life")
	assert(life != null and int(life.debug_state().get("actorCount", 0)) == 4,
		"mondo %d: regia di vita non monta tutto il cast" % level)
	for actor in actors:
		var anchors: Dictionary = Dictionary(life.get("anchors")).get(str(actor.get_meta("id", "")), {})
		for role in ["home", "work", "ritrovo"]:
			assert(anchors.has(role), "mondo %d: ancoraggio %s assente" % [level, role])

	var artifacts := get_nodes_in_group("mystery_artifact").filter(
		func(artifact): return world.is_ancestor_of(artifact))
	# Le tracce delle sorelle passano dalla stessa API dei semi, non dal vecchio
	# array locale: l'audit deve contare ciò che la scena costruisce davvero.
	var expected_seeds := MysteryCatalog.semi_for(level).size()
	assert(artifacts.size() == expected_seeds + 1,
		"mondo %d: Traccia o semi fisici mancanti" % level)
	for artifact in artifacts:
		var position: Vector2 = artifact.global_position
		assert(not chunks.composition.is_protected(position, 40.0),
			"mondo %d: Traccia/seme dentro safeRadius o safeRoute" % level)
		assert(chunks.composition.raw_water_weight(position) < 0.24,
			"mondo %d: Traccia/seme in acqua" % level)

	for stage in [0, 1, 2]:
		var scene := RitrovoCatalog.scene_for(level, stage)
		assert(not scene.is_empty() and not RitrovoCatalog.lines_of(str(scene.get("id", "")), false).is_empty(),
			"mondo %d: conversazione Ritrovo stadio %d assente" % [level, stage])
	var trace := MysteryCatalog.traccia_for(level)
	assert(not trace.is_empty() and Array(trace.get("testo", [])).size() <= 3,
		"mondo %d: Traccia assente o oltre tre schermate" % level)

	var player := world.get("player") as OutdoorPlayerController
	assert(player != null and player.is_physics_processing(),
		"mondo %d: Eli bloccata senza avere aperto dialoghi" % level)
	assert(not world.get("dialogue_box").visible,
		"mondo %d: dialogo obbligatorio all'ingresso" % level)
	if level == 5:
		assert(not Dictionary(world.call("_maestro_voice_for_session", {
			"subject": "fisica", "sessionId": "l1-physics"
		})).is_empty(), "mondo 5: la voce di Leva non si accende")
		assert(Dictionary(world.call("_maestro_voice_for_session", {
			"subject": "geografia", "sessionId": "l1-geography"
		})).is_empty(), "mondo 5: la voce della geografia si accende prima dell'incontro")

	if level == 1:
		world.call("_open_npc_dialogue", "w01-ersilia")
		var dialogue = world.get("dialogue_box")
		var pages: Array = dialogue.get("screens")
		assert(pages.size() == 3, "mondo 1: la conta di Ersilia non sta in tre schermate")
		var heard := "\n".join(pages)
		for verse in Array(NpcCatalog.CONTA_ERSILIA.get("versi", [])):
			assert(heard.contains(str(verse)), "mondo 1: verso della conta non offerto al primo incontro")
		for page_index in pages.size():
			dialogue.call("advance")
		assert(bool(Dictionary(world.get("game_save").data.get("narrative", {})).get("ersiliaCountHeard", false)),
			"mondo 1: la conta conclusa non resta nello stato narrativo")

	world.queue_free()
	await process_frame
	await process_frame
