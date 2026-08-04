extends SceneTree

## Quante materie compaiono davvero in ogni mondo, e a che difficolta'.
##
## Serve a rispondere a una domanda precisa: il vincolo "tutte le dodici materie
## in ogni mondo" e' gia' soddisfatto, oppure no?

func _init() -> void:
	var cm := ContentManager.new()

	print("%-8s %-14s %12s %s" % ["MONDO", "OSPITE", "RAGG./TOT", "eventi per genere"])
	for level in range(1, 25):
		var focus := ApparatusConfig.world_subject(level)
		var profile := WorldProfileCatalog.profile(level)
		var events: Array = MissionEventDirector.plan(profile, {}, "presence-%d" % level)
		var subjects: Dictionary = {}
		var kinds: Dictionary = {}
		for entry in events:
			var e := entry as Dictionary
			subjects[str(e.get("subject", ""))] = true
			var k := str(e.get("kind", ""))
			kinds[k] = int(kinds.get(k, 0)) + 1
		var raggiungibili: Dictionary = {}
		for entry in events:
			var e := entry as Dictionary
			if bool(e.get("reachable", false)):
				raggiungibili[str(e.get("subject", ""))] = true
		var parts: Array = []
		for k in kinds.keys():
			parts.append("%s:%d" % [k, int(kinds[k])])
		parts.sort()
		print("%-8d %-14s %5d/%-6d %s" % [level, focus, raggiungibili.size(), subjects.size(), ", ".join(PackedStringArray(parts))])

	print("\n=== DIFFICOLTA' DI UNA MATERIA NON OSPITE, mondo per mondo ===")
	print("(storia: ospite ai mondi 11 e 23, altrove evento di pratica)")
	print("%-8s %-10s %s" % ["MONDO", "BANDA", "note"])
	for level in [1, 3, 5, 6, 8, 10, 11, 13, 19, 23, 24]:
		var band := cm.effective_difficulty("storia", level, -1.0)
		var nota := "ospite" if ApparatusConfig.world_subject(level) == "storia" else "pratica"
		print("%-8d %-10d %s" % [level, band, nota])

	print("\n=== E CON PADRONANZA BASSA (chi fatica) ===")
	for level in [11, 13, 19, 23]:
		print("mondo %-3d banda %d (mastery 0.3)" % [level, cm.effective_difficulty("storia", level, 0.3)])
	quit(0)
