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
	assert(assets.size() == 36, "il pacchetto deve esporre 36 asset audio")
	assert(subjects.size() == 12, "serve un cue per tutte le 12 materie")
	assert(events.size() >= 9, "eventi gameplay audio incompleti")

	var loops := 0
	for key in assets:
		var spec: Dictionary = assets[key]
		var resource_path := str(spec.get("path", ""))
		assert(resource_path.begins_with("res://assets/audio/"), "%s: path fuori pacchetto" % key)
		var stream := load(resource_path) as AudioStream
		assert(stream != null, "%s: stream non caricabile" % key)
		assert(stream.get_length() >= 0.05, "%s: stream vuoto" % key)
		if bool(spec.get("loop", false)):
			loops += 1
			assert(absf(stream.get_length() - 16.0) < 0.02, "%s: loop non sincronizzato" % key)

	for subject in subjects:
		assert(assets.has(str(subjects[subject])), "%s: cue materia mancante" % subject)
	for event in events:
		assert(assets.has(str(events[event])), "%s: cue evento mancante" % event)
	assert(loops == 5, "servono cinque loop adattivi")
	print("C-18 AUDIO ASSET audit OK - 36 stream, 12 materie, 5 loop adattivi")
	quit(0)
