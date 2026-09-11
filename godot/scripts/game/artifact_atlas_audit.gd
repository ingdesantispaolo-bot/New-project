extends SceneTree

## Guardia C-R1: ogni atlante dichiarato deve essere importabile, avere la
# stessa griglia 4x1 e servire almeno un contenuto runtime valido.

func _init() -> void:
	var failures: Array = []
	_check(ArtifactAtlasCatalog.ATLASES.size() >= 2, "esiste ancora un solo atlante", failures)
	for atlas_id in ArtifactAtlasCatalog.ATLASES.keys():
		var data := ArtifactAtlasCatalog.atlas_data(str(atlas_id))
		var path := str(data.get("image", ""))
		_check(ResourceLoader.exists(path), "%s: immagine assente %s" % [str(atlas_id), path], failures)
		var texture := load(path) as Texture2D
		_check(texture != null, "%s: immagine non importabile" % str(atlas_id), failures)
		if texture != null:
			_check(texture.get_width() == 960 and texture.get_height() == 200,
				"%s: dimensioni %dx%d, attese 960x200" % [str(atlas_id), texture.get_width(), texture.get_height()], failures)
		var targets := data.get("targets", {}) as Dictionary
		_check(targets.size() == 4, "%s: attesi quattro bersagli" % str(atlas_id), failures)
		for target in targets.values():
			var point := target as Vector2
			_check(point.x > 0.0 and point.x < 1.0 and point.y > 0.0 and point.y < 1.0,
				"%s: bersaglio fuori dal foglio" % str(atlas_id), failures)

	var electronics_specs: Array = MinigameManager.HOTSPOT.get("elettronica", [])
	_check(electronics_specs.size() >= 2, "l'atlante elettronico non ha due contenuti runtime", failures)
	var manager := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 8102026
	for index in electronics_specs.size():
		var node := manager.call("_hotspot_node", "elettronica", electronics_specs[index], 2, rng, index) as Dictionary
		var validation := ExerciseInteraction.validate(node)
		_check(bool(validation.get("ok", false)), "hotspot elettronico %d non valido: %s" % [index, str(validation.get("errors", []))], failures)

	if not failures.is_empty():
		printerr("ARTIFACT ATLAS AUDIT ROSSO — %d problemi" % failures.size())
		for failure in failures: printerr("  - %s" % failure)
		quit(1)
		return
	print("Artifact atlas audit OK — 2 fogli 960x200, 8 bersagli semantici, elettronica servita")
	quit(0)

func _check(condition: bool, message: String, failures: Array) -> void:
	if not condition: failures.append(message)
