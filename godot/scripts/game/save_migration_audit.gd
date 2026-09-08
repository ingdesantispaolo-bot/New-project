extends SceneTree

## Audit O-P6 (save migration): profili legacy di forme diverse migrano a v4 senza
## crash, senza perdere dati validi, in modo idempotente; i campi nuovi
## (gateConsumed, worlds, worldProgress, spacedRepetition schedule, codex, nora,
## config) vengono aggiunti e il ripasso vecchio "due" convertito.
## Uso: godot --headless --path godot --script res://scripts/game/save_migration_audit.gd

func _all_keys_present(migrated: Dictionary) -> void:
	for key in GameSaveManager._default_data().keys():
		assert(migrated.has(key), "campo mancante dopo migrazione: %s" % key)
	assert(int(migrated["schemaVersion"]) == GameSaveManager.SCHEMA_VERSION, "schemaVersion non aggiornato")

func _init() -> void:
	var mgr := GameSaveManager.new()

	# 1) v0 minimale: solo pochi campi + un campo futuro sconosciuto.
	var v0 := {"schemaVersion": 0, "playerId": "legacy", "level": 5, "energy": 50, "futureField": {"keep": true}}
	var m0 := mgr.migrate_legacy_save(v0)
	_all_keys_present(m0)
	assert(int(m0["level"]) == 5 and int(m0["energy"]) == 50, "livello/energia non preservati")
	assert(bool(m0["futureField"]["keep"]), "campo futuro sconosciuto perso")
	# Mondi riconciliati: 1..5 sbloccati.
	for lvl in range(1, 6):
		assert(Array(m0["worlds"]["unlocked"]).has(lvl), "mondo %d non sbloccato per un save a livello 5" % lvl)
	# Campi nuovi presenti.
	assert(m0.has("codex") and m0.has("nora") and m0.has("config"), "campi O-P4/O-P6 assenti")
	var dialogue_memory: Dictionary = m0["narrative"].get("dialogueMemory", {})
	assert(typeof(dialogue_memory.get("heard", null)) == TYPE_DICTIONARY,
		"memoria dialoghi v4 assente dal ramo narrativo legacy")
	# Idempotenza.
	assert(mgr.migrate_legacy_save(m0) == m0, "migrazione non idempotente (v0)")

	# 2) v1 con ripasso vecchio "due" (contatore) → schedule con topic subito dovuti.
	var v1 := {
		"schemaVersion": 1, "level": 3, "energy": 20,
		"missionsBySubject": {"matematica": 4, "italiano": 2},
		"spacedRepetition": {"due": {"matematica:tabelline": 2}, "history": []},
	}
	var m1 := mgr.migrate_legacy_save(v1)
	_all_keys_present(m1)
	assert(int(m1["missionsBySubject"]["matematica"]) == 4, "conteggio missioni perso")
	assert(m1["spacedRepetition"].has("schedule"), "spacedRepetition non convertito")
	assert(m1["spacedRepetition"]["schedule"].has("matematica:tabelline"), "topic in ripasso perso")
	assert(int(m1["spacedRepetition"]["schedule"]["matematica:tabelline"]["dueAt"]) == 0, "un ripasso pendente deve essere subito dovuto")
	assert(m1["gateConsumed"] == {}, "gateConsumed deve partire vuoto")
	assert(mgr.migrate_legacy_save(m1) == m1, "migrazione non idempotente (v1)")

	# 3) Il vecchio apparato condiviso conserva i gate di Storia nel nuovo
	# Archivio temporale senza sottrarre la riparazione scientifica alla serra.
	var v2 := GameSaveManager._default_data()
	v2["schemaVersion"] = 2
	v2["apparatus"] = {"serra-bio": {"repairedLevel": 23}}
	var m2 := mgr.migrate_legacy_save(v2)
	assert(int(m2["apparatus"]["serra-bio"]["repairedLevel"]) == 23, "riparazione serra persa")
	assert(int(m2["apparatus"]["archivio-temporale"]["repairedLevel"]) == 23, "riparazione Storia non migrata")
	assert(mgr.migrate_legacy_save(m2) == m2, "v4 non idempotente")

	# 4) La forma sperimentale ad array viene convertita senza perdere ascolti.
	var experimental := GameSaveManager._default_data()
	experimental["schemaVersion"] = 3
	experimental["narrative"]["dialogueMemory"] = {
		"heard": ["w01-tobia:uno", "w01-ersilia:due"], "exchanges": 2,
	}
	var m3 := mgr.migrate_legacy_save(experimental)
	assert(bool(m3["narrative"]["dialogueMemory"]["heard"].get("w01-tobia:uno", false)),
		"ascolto sperimentale perso nella migrazione v4")
	assert(mgr.migrate_legacy_save(m3) == m3, "v4 non idempotente")

	# 5) apply_launch_state con un initialSave legacy non deve degradare il livello
	# locale né perdere campi.
	var save := GameSaveManager.new()
	save.set_level(2)
	save.apply_launch_state({"initialSave": {"schemaVersion": 1, "level": 7, "energy": 5}, "playerLevel": 7})
	assert(save.level() == 7, "apply_launch_state deve adottare il livello superiore")
	assert(save.data.has("worlds") and save.data.has("codex"), "apply_launch_state deve migrare a v4")

	print("Save migration audit OK — v0/v1/v2/v3 → v4 idempotente, memoria dialoghi preservata")
	quit(0)
