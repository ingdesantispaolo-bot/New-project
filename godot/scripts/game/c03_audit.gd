extends SceneTree

## Audit C-03: migrazione idempotente e preservazione dei campi sconosciuti.

func _init() -> void:
	var legacy := {
		"schemaVersion": 0, "playerId": "legacy", "level": 3, "energy": 77,
		"missionsBySubject": {"matematica": 2}, "futureField": {"keep": true},
	}
	var manager := GameSaveManager.new()
	var first := manager.migrate_legacy_save(legacy)
	var second := manager.migrate_legacy_save(first)
	assert(first == second, "la migrazione deve essere idempotente")
	assert(first.has("narrative"))
	assert(first.has("daily"))
	assert(first.has("spacedRepetition"))
	assert(bool(first["futureField"]["keep"]))
	assert(int(first["level"]) == 3)
	print("C-03 audit OK — migrazione idempotente, campi estesi e sconosciuti preservati")
	quit(0)
