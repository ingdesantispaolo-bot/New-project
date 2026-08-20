extends SceneTree

## Nomi di edificio già incontrati: due mondi con lo stesso nome renderebbero
## indistinguibili due posti, ed è il difetto da cui nasce il catalogo esteso.
var _nomi_visti: Dictionary = {}

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for level in range(1, 25):
		var profile := WorldProfileCatalog.profile(level)
		var specs := BuildingCatalog.for_world(level, profile)
		assert(specs.size() == 3, "mondo %d senza tre edifici" % level)
		var roles: Array = specs.map(func(spec): return str(spec.get("role", "")))
		for role in BuildingCatalog.ROLES:
			assert(roles.has(role), "mondo %d senza ruolo %s" % [level, role])
		for spec in specs:
			assert(str(spec.get("artKit", "")) == str(profile.get("artKit", "")),
				"edificio non vestito per artKit nel mondo %d" % level)
			var art_path := str(spec.get("artPath", ""))
			assert(not art_path.is_empty() and ResourceLoader.exists(art_path),
				"asset illustrato mancante nel mondo %d: %s" % [level, art_path])
			var art_cell: Vector2i = spec.get("artAtlasCell", Vector2i(-1, -1))
			assert(art_cell == Vector2i(posmod(level - 1, 4), int((level - 1) / 4)),
				"edificio %s del mondo %d senza cella illustrata propria" % [str(spec.get("role", "")), level])
			var prop_path := str(spec.get("activityPropPath", ""))
			if not prop_path.is_empty():
				assert(ResourceLoader.exists(prop_path),
					"oggetto di attivita' mancante nel mondo %d: %s" % [level, prop_path])
			var role := str(spec.get("role", ""))
			var label := str(spec.get("label", ""))
			var resident_owner := str(spec.get("residentOwner", ""))
			if role == "first_ruin" or level == WorldProfileCatalog.MAX_LEVEL:
				assert(resident_owner == "", "la Rovina del mondo %d appartiene a un residente" % level)
			else:
				assert(not resident_owner.is_empty(),
					"il luogo %s del mondo %d non ha una conseguenza per-residente" % [role, level])
				assert(int(NpcCatalog.resident(resident_owner).get("world", 0)) == level,
					"il luogo %s del mondo %d è attribuito a %s" % [role, level, resident_owner])
			# **Ogni mondo ha i suoi tre nomi.** (6 agosto 2026)
			#
			# Prima i nomi esistevano solo per il mondo 1 e gli altri ventitre
			# ricevevano «Casa del mestiere», «Ritrovo», «Rovina dei Primi» —
			# identiche ovunque. Questa prova chiedeva soltanto che i nomi del
			# mondo 1 non trapelassero altrove, ed era verde mentre ventitre
			# mondi condividevano le stesse tre etichette: guardava la cosa
			# sbagliata.
			assert(label.strip_edges().length() > 4,
				"edificio senza nome nel mondo %d (ruolo %s)" % [level, role])
			for generico in ["Casa del mestiere", "Ritrovo", "Rovina dei Primi"]:
				assert(label != generico,
					"il mondo %d usa ancora l'etichetta generica «%s»" % [level, generico])
			var chiave := "%s|%s" % [label, role]
			assert(not _nomi_visti.has(label),
				"il nome «%s» compare in due mondi: %d e %d" % [
					label, int(_nomi_visti.get(label, 0)), level])
			_nomi_visti[label] = level
	await _test_world_one()
	_test_generated_fallback()
	print("Building audit OK — 3 ruoli × 24 mondi, finestre a stadio e Rovina allineata")
	quit(0)

func _test_world_one() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("building-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var buildings: Array = world.get("world_buildings")
	assert(buildings.size() == 3, "fixture mondo 1 senza tre edifici reali")
	var ruin: Node2D = null
	var per_residente: Dictionary = {}
	var composition = world.get("chunks").composition
	for building in buildings:
		var actor := building as Node2D
		var role := str(actor.get_meta("building_role", ""))
		assert(actor.get_node_or_null("BuildingLabel") != null, "edificio senza etichetta accessibile")
		assert(bool(actor.get_meta("generated_art", false)),
			"edificio %s del mondo 1 senza tavola illustrata" % role)
		assert(actor.get_node_or_null("GeneratedBuildingVisual/GeneratedBuildingArt") != null,
			"edificio %s del mondo 1 senza sprite illustrato" % role)
		if role == "work_home":
			assert(bool(actor.get_meta("generated_art", false)),
				"la Casa del Conto non usa il pilot illustrato")
			assert(actor.get_node_or_null("GeneratedBuildingVisual/GeneratedBuildingArt") != null,
				"Casa del Conto senza edificio generato")
			assert(actor.get_node_or_null("GeneratedBuildingVisual/GeneratedActivityProp") != null,
				"Casa del Conto senza stazione di attivita'")
			assert(Array(actor.get_meta("activity_tags", [])).has("matematica"),
				"Casa del Conto non dichiara la materia che ospita")
		if role == "first_ruin":
			ruin = actor
		else:
			assert(composition.raw_water_weight(actor.global_position) < 0.24,
				"edificio %s in acqua" % role)
			assert(not composition.is_protected(actor.global_position, 80.0),
				"edificio %s su area protetta" % role)
			var resident_owner := str(actor.get_meta("resident_owner", ""))
			assert(resident_owner in ["w01-tobia", "w01-ersilia"],
				"luogo del mondo 1 senza proprietario residente: %s" % role)
			var consequence := actor.get("resident_consequence") as Node2D
			assert(consequence != null, "%s non ha una conseguenza visibile nel proprio luogo" % resident_owner)
			assert(consequence.get_child_count() == 0,
				"la conseguenza di %s deve restare un solo nodo procedurale" % resident_owner)
			assert(int(consequence.get_meta("resident_stage", -1)) == 0,
				"%s parte già cambiato senza che Eli abbia fatto niente" % resident_owner)
			per_residente[resident_owner] = consequence
		for glow in Array(actor.get("window_glows")):
			assert(not (glow as CanvasItem).visible, "finestra accesa allo stadio 0")
	assert(ruin != null and ruin.global_position.distance_to(world.call("_hero_landmark_position")) < 0.1,
		"Rovina non allineata al landmark eroe")
	var ritrovo: Vector2 = world.call("ritrovo_position")
	assert(ritrovo.distance_to(world.get("world_profile").get("spawn", Vector2.ZERO)) > 100.0,
		"Ritrovo privo di ancoraggio distinto")
	var tobia := per_residente["w01-tobia"] as Node2D
	var ersilia := per_residente["w01-ersilia"] as Node2D
	(tobia.get_parent() as Node).call("set_stage", 1)
	(ersilia.get_parent() as Node).call("set_stage", 1)
	assert(str(tobia.get_meta("visual_semantic", "")) == "counting-guides",
		"Tobia salta dal mucchio alla soluzione senza una conseguenza intermedia")
	assert(str(ersilia.get_meta("visual_semantic", "")) == "noticed-rhythm",
		"Ersilia salta dal cesto alla soluzione senza una conseguenza intermedia")
	(tobia.get_parent() as Node).call("set_stage", 0)
	(ersilia.get_parent() as Node).call("set_stage", 0)

	# La prova che vale il lotto: convincere Tobia cambia il mucchio di Tobia,
	# non il pane di Ersilia. Il vecchio `_npc_story_stage()` le avrebbe mossi
	# entrambi perché vedeva un solo contatore per tutto il mondo.
	var result: Dictionary = world.get("result")
	result["collectedTreasureIds"].append("gioco-w01-tobia")
	world.call("_update_building_stages")
	assert(int(tobia.get_meta("resident_stage", -1)) == 2,
		"la vittoria di Tobia non cambia il suo mucchio")
	assert(str(tobia.get_meta("visual_semantic", "")) == "groups-of-ten",
		"il mucchio finale di Tobia non mostra gruppi di dieci")
	assert(int(ersilia.get_meta("resident_stage", -1)) == 0,
		"convincere Tobia cambia anche il luogo di Ersilia")
	assert(str(ersilia.get_meta("visual_semantic", "")) == "ordinary-bread-basket",
		"il luogo iniziale di Ersilia è punitivo o già risolto")
	result["collectedTreasureIds"].append("gioco-w01-ersilia")
	world.call("_update_building_stages")
	assert(str(ersilia.get_meta("visual_semantic", "")) == "seven-beat-bread",
		"la vittoria di Ersilia non rende visibile il ritmo di sette")

	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame

func _test_generated_fallback() -> void:
	var fallback := BuildingActor.new()
	fallback.configure({
		"id": "fallback-building", "role": "work_home", "label": "Ripiego sicuro",
		"world": 1, "artPath": "res://assets/non-esiste.png",
	}, 0, false, true)
	assert(not bool(fallback.get_meta("generated_art", false)),
		"un asset assente non deve fingere di essere stato caricato")
	assert(fallback.get_node_or_null("PavilionVisual") != null,
		"asset assente senza fallback vettoriale")
	fallback.free()
