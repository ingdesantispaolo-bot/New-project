extends SceneTree

const SUBJECTS := [
	"matematica", "italiano", "coding", "inglese",
	"fisica", "musica", "latino", "elettronica",
	"geografia", "scienze", "storia", "logica",
]
const TOOLS := [
	"tool-torch", "tool-scythe", "tool-lever", "tool-lens", "tool-bellows",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var station_regions: Dictionary = {}
	for subject in SUBJECTS:
		var station := SubjectStationArt.build(subject, false)
		assert(station.texture is AtlasTexture, "stazione %s senza regione di atlante" % subject)
		var region := station.texture as AtlasTexture
		assert(region.atlas.resource_path.ends_with("subject-stations-atlas-v1.png"),
			"stazione %s usa l'atlante sbagliato" % subject)
		var key := str(region.region.position)
		assert(not station_regions.has(key), "due materie condividono la stessa cella: %s" % subject)
		station_regions[key] = true
		station.free()
	assert(station_regions.size() == 12, "l'atlante non espone dodici stazioni distinte")

	for tool_id in TOOLS:
		var closed := FieldGateArt.build(tool_id, false)
		var opened := FieldGateArt.build(tool_id, true)
		assert(closed.texture is AtlasTexture and opened.texture is AtlasTexture,
			"ostacolo %s senza regioni" % tool_id)
		assert((closed.texture as AtlasTexture).region.position.y
			!= (opened.texture as AtlasTexture).region.position.y,
			"ostacolo %s non cambia tavola quando si apre" % tool_id)
		closed.free()
		opened.free()

	var paths: Dictionary = {}
	for level in range(1, 25):
		var path := ChapterArt.path_for_world(level)
		assert(ResourceLoader.exists(path), "tavola narrativa assente al mondo %d" % level)
		paths[path] = true
	assert(paths.size() == 6, "servono sei tavole narrative, trovate %d" % paths.size())

	var authored_cells: Dictionary = {}
	var subject_cells: Dictionary = {}
	for level in range(1, 24):
		for spec_data in BuildingCatalog.for_world(level, WorldProfileCatalog.profile(level)):
			var owner := str((spec_data as Dictionary).get("residentOwner", ""))
			if owner.is_empty():
				continue
			var outcome := ResidentOutcomeArt.build(owner)
			assert(outcome.texture is AtlasTexture, "%s senza esito di atlante" % owner)
			var key := str(outcome.get_meta("atlas_cell"))
			if bool(outcome.get_meta("authored_outcome")):
				authored_cells[key] = true
			else:
				subject_cells[key] = true
			outcome.free()
	assert(authored_cells.size() == 10, "servono dieci esiti autoriali")
	assert(subject_cells.size() == 12, "servono dodici esiti disciplinari")

	var intro := WorldIntroPanel.new()
	intro.livello = 1
	get_root().add_child(intro)
	await process_frame
	assert(intro.find_child("ChapterArt", true, false) != null,
		"la soglia del mondo non mostra la tavola narrativa")
	intro.queue_free()
	print("GENERATED ART audit OK - 12 stazioni, 10 ostacoli, 6 tavole e 46 esiti residenti")
	quit(0)
