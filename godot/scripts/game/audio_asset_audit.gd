extends SceneTree

const MANIFEST_PATH := "res://assets/audio/audio-manifest.json"

func _init() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null, "manifest audio C-18 assente")
	var parsed = JSON.parse_string(file.get_as_text())
	assert(typeof(parsed) == TYPE_DICTIONARY, "manifest audio C-18 non valido")
	var manifest: Dictionary = parsed
	var assets: Dictionary = manifest.get("assets", {})
	var subjects: Dictionary = manifest.get("subjects", {})
	var events: Dictionary = manifest.get("events", {})
	var soundscape_contract: Dictionary = manifest.get("soundscapes", {})
	var soundscapes: Dictionary = soundscape_contract.get("byId", {})
	# Il piano ne stimava 22; la fonte autoritativa contiene 24 terrainFamily e
	# 24 soundscape distinti. L'audit segue i profili reali, non la stima.
	assert(soundscapes.size() == WorldProfileCatalog.IDENTITIES.size(),
		"serve un soundscape per ogni profilo reale")
	assert(assets.size() == 36 + soundscapes.size(),
		"il pacchetto deve esporre 36 asset base più i soundscape")
	assert(subjects.size() == 12, "serve un cue per tutte le 12 materie")
	assert(events.size() >= 9, "eventi gameplay audio incompleti")

	var base_loops := 0
	var long_loops := 0
	for key in assets:
		var spec: Dictionary = assets[key]
		var resource_path := str(spec.get("path", ""))
		assert(resource_path.begins_with("res://assets/audio/"), "%s: path fuori pacchetto" % key)
		var stream := load(resource_path) as AudioStream
		assert(stream != null, "%s: stream non caricabile" % key)
		assert(stream.get_length() >= 0.05, "%s: stream vuoto" % key)
		if bool(spec.get("loop", false)):
			if str(spec.get("role", "")) == "world":
				long_loops += 1
				assert(stream.get_length() >= 59.98, "%s: soundscape sotto il minuto" % key)
			else:
				base_loops += 1
				assert(absf(stream.get_length() - 16.0) < 0.02, "%s: loop base non sincronizzato" % key)

	var used_assets: Dictionary = {}
	var motif_counts: Dictionary = {}
	for identity_data in WorldProfileCatalog.IDENTITIES:
		var identity: Dictionary = identity_data
		var soundscape := str(identity.get("soundscape", ""))
		var terrain := str(identity.get("terrainFamily", ""))
		assert(soundscapes.has(soundscape), "%s: soundscape senza asset" % soundscape)
		var spec: Dictionary = soundscapes.get(soundscape, {})
		assert(str(spec.get("terrainFamily", "")) == terrain,
			"%s: terrainFamily disallineata" % soundscape)
		var asset_key := str(spec.get("asset", ""))
		assert(assets.has(asset_key), "%s: chiave asset assente" % soundscape)
		assert(not used_assets.has(asset_key), "%s: due mondi condividono lo stesso file" % asset_key)
		used_assets[asset_key] = true
		var motif := str(spec.get("motif", ""))
		motif_counts[motif] = int(motif_counts.get(motif, 0)) + 1

	var max_neighbours := int(soundscape_contract.get("maxFamilyNeighbours", 0))
	for motif in motif_counts:
		assert(int(motif_counts[motif]) - 1 <= max_neighbours,
			"%s condivide il motivo con troppe famiglie" % motif)
	assert(GameAudioManager.resolve_soundscape_asset(manifest, "assente", "night") == "ambience.night",
		"soundscape mancante non torna al fallback notte")
	var first_soundscape := str(WorldProfileCatalog.IDENTITIES[0].get("soundscape", ""))
	assert(GameAudioManager.resolve_soundscape_asset(manifest, first_soundscape, "day")
		== str(Dictionary(soundscapes[first_soundscape]).get("asset", "")),
		"soundscape presente non viene risolto dal runtime")

	for subject in subjects:
		assert(assets.has(str(subjects[subject])), "%s: cue materia mancante" % subject)
	for event in events:
		assert(assets.has(str(events[event])), "%s: cue evento mancante" % event)
	assert(base_loops == 5, "servono cinque loop adattivi di fallback")
	assert(long_loops == soundscapes.size(), "non tutti i soundscape sono loop lunghi")
	print("C-G8 AUDIO ASSET audit OK - %d soundscape da un minuto, fallback intatto" % soundscapes.size())
	quit(0)
