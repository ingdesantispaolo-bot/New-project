extends SceneTree

## Audit O-P1: i 24 `WorldProfile` sono validi, distinti e coerenti con la scala.
## Uso: godot --headless --path godot --script res://scripts/game/world_profile_audit.gd

func _init() -> void:
	var report := WorldProfileCatalog.validate_all()
	if not bool(report["ok"]):
		for lvl in report["errors"].keys():
			push_error("Profilo livello %s: %s" % [lvl, str(report["errors"][lvl])])
		quit(1)
		return
	assert(int(report["count"]) == 24, "devono esistere 24 profili")

	# Coerenza col ciclo materie e distinzione d'identità.
	var subjects_seen: Dictionary = {}
	for lvl in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var p := WorldProfileCatalog.profile(lvl)
		var subject := str(p["learningFocus"]["subject"])
		assert(subject == str(ApparatusConfig.level_gate(lvl)["subject"]), "focus livello %d incoerente" % lvl)
		subjects_seen[subject] = true
		# Ogni mondo deve stare dentro l'area giocabile e con spawn raggiungibile.
		var spawn: Vector2 = p["spawn"]
		assert(spawn.length() <= float(p["worldHalfExtent"]) * 1.5, "spawn fuori area livello %d" % lvl)
		# Almeno un formato non-scelta-multipla ammesso (varietà, target O-P3).
		var formats: Array = p["eventPools"]["formats"]
		var has_non_mc := false
		for f in formats:
			if str(f) != "multiple_choice":
				has_non_mc = true
		assert(has_non_mc, "il livello %d deve ammettere formati oltre la scelta multipla" % lvl)

	assert(subjects_seen.size() == 12, "i 24 mondi devono coprire tutte le 12 materie")

	print("WorldProfile audit OK — 24 profili validi, distinti, coerenti con la scala e con formati vari")
	quit(0)
