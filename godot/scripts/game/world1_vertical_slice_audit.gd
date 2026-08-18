extends SceneTree

## Definition of done della Radura Accademia: casa illustrata, tre famiglie di
## apparati sul campo, segnali di scoperta, enigma-varco, minimissione-obelisco e
## trasformazioni persistenti devono convivere nella scena reale.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const ACTIVITY_SITE := preload("res://scripts/visual/world1_activity_site.gd")
const COMPLETED_FIXTURE := "evt-1-gate-2"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for art_path in ACTIVITY_SITE.ASSETS.values():
		assert(ResourceLoader.exists(str(art_path)), "asset di sito mancante: %s" % str(art_path))

	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	initial["worldProgress"] = {
		"1": {
			"completedEncounterIds": [COMPLETED_FIXTURE],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"resume": {},
		},
	}
	var request := NativeWorldState.default_request("world1-vertical-slice-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": false}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var house: Node2D = null
	for building_data in Array(world.get("world_buildings")):
		var building := building_data as Node2D
		if str(building.get_meta("building_role", "")) == "work_home":
			house = building
			break
	assert(house != null and bool(house.get_meta("generated_art", false)),
		"Casa del Conto non integrata nella scena reale")
	assert(house.get_node_or_null("GeneratedBuildingVisual/GeneratedActivityProp") != null,
		"Casa del Conto senza Stazione del Conto")

	var regular_sites := 0
	var families: Dictionary = {}
	var clusters: Dictionary = {}
	var has_enigma := false
	var has_crossing_enigma := false
	var has_minimission := false
	var incomplete_gate_count := 0
	var cue_types: Dictionary = {}
	var first_live_site: Area2D = null
	for event_data in Array(world.get("mission_events")):
		var event: Dictionary = event_data
		if not bool(event.get("countsForGate", false)):
			continue
		clusters[str(event.get("locationCluster", ""))] = true
		var event_id := str(event.get("id", ""))
		var node := world.find_child("MissionEvent_%s" % event_id.replace("-", "_"), true, false) as Area2D
		assert(node != null, "evento-gate assente dalla scena: %s" % event_id)
		var is_completed := event_id == COMPLETED_FIXTURE
		var cue := node.get_node_or_null("DiscoveryCue")
		if is_completed:
			assert(cue == null, "un sito completato continua a chiamare il giocatore")
		else:
			incomplete_gate_count += 1
			assert(cue != null, "evento %s senza segnale di scoperta" % event_id)
			var cue_type := str(cue.get_meta("cue_type", ""))
			assert(cue_type in ["proximity", "local_clue", "distant_signal"],
				"evento %s con segnale non interpretabile" % event_id)
			cue_types[cue_type] = true

		match str(event.get("kind", "")):
			"mission":
				regular_sites += 1
				var site := node.get_node_or_null("World1ActivitySite")
				assert(site != null, "missione matematica senza apparato illustrato: %s" % event_id)
				var expected_family := ACTIVITY_SITE.family_for_format(str(event.get("format", "")))
				assert(str(site.get_meta("site_family", "")) == expected_family,
					"apparato incoerente con il formato di %s" % event_id)
				assert(site.get_node_or_null("GeneratedSiteArt") != null,
					"apparato %s ricaduto nel fallback" % event_id)
				families[expected_family] = true
				if is_completed:
					assert(str(site.get_meta("state", "")) == "restored",
						"apparato completato non trasformato")
					assert((site.get_node("CompletionHalo") as CanvasItem).visible,
						"apparato completato senza esito visibile")
				elif first_live_site == null:
					first_live_site = node
			"enigma":
				has_enigma = true
				assert(node.get_node_or_null("EnigmaStructureVisual") != null,
					"enigma senza struttura trasformabile")
				if event.has("crossingId") and event.has("bridgeCenter"):
					has_crossing_enigma = true
			"minimission":
				has_minimission = true
				assert(node.get_node_or_null("IncaricoGuasto") != null,
					"obelisco spento senza guasto visibile")

	assert(regular_sites == 4, "la Radura deve avere quattro siti ordinari, trovati %d" % regular_sites)
	assert(families.size() == 3 and families.has("measure") and families.has("sequence") and families.has("matching"),
		"le quattro prove non coprono le tre famiglie di apparati")
	assert(clusters.size() >= 3, "percorso principale concentrato in meno di tre costellazioni")
	assert(has_enigma and has_crossing_enigma and has_minimission,
		"mancano enigma, varco o riaccensione dell'obelisco")
	assert(incomplete_gate_count == MissionEventDirector.HOST_EVENTS + MissionEventDirector.GATE_SURPLUS - 1,
		"numero di segnali incoerente con gli eventi ancora aperti")
	assert(not cue_types.is_empty(), "nessun linguaggio di scoperta presente")

	assert(first_live_site != null, "manca un sito disponibile per il collaudo di progresso")
	var live_event: Dictionary = first_live_site.get_meta("directorEvent", {})
	world.get("gameplay").active_session_context = {
		"kind": str(live_event.get("kind", "mission")),
		"encounterId": str(live_event.get("id", "")),
		"subject": "matematica",
	}
	world.call("_on_exercise_progress", 1, 3)
	var site := first_live_site.get_node("World1ActivitySite")
	var visible_parts := 0
	for part in Array(site.get("progress_parts")):
		if (part as CanvasItem).visible:
			visible_parts += 1
	assert(visible_parts > 0 and visible_parts < 5,
		"una risposta non produce un avanzamento parziale sull'apparato")
	world.call("_complete_learning_reaction", str(live_event.get("id", "")))
	assert(str(site.get_meta("state", "")) == "restored",
		"il completamento non resta visibile nel luogo")
	assert(not first_live_site.is_in_group("world_interactable"),
		"il sito restaurato resta una prova attiva")

	root.remove_child(world)
	world.queue_free()
	print("World 1 vertical slice audit OK - casa, 4 siti, 3 apparati, varco, obelisco e trasformazioni")
	quit(0)
