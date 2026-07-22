class_name NativeWorldState
extends RefCounted

## Stato transitorio della sessione Godot. Il save persistente resta
## GameSaveManager; qui vivono soltanto seed, presentazione e delta del mondo.

static func default_request(seed: String = "outdoor-dev-1") -> Dictionary:
	return {
		"schemaVersion": GameSaveManager.SCHEMA_VERSION,
		"playerId": "local",
		"worldSeed": seed,
		"playerLevel": 1,
		"avatar": {"outfit": "avatar-base", "accessory": "", "pet": ""},
		"avatarVisual": {
			"bodyColor": 0x6be7d6,
			"accessory": null,
			"pet": {"id": "pet-spark", "kind": "spark", "color": 0xf6c85f},
		},
		"outdoorState": {
			"completedEncounterIds": [],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"fragments": 0,
		},
	}

static func empty_result() -> Dictionary:
	return {
		"schemaVersion": GameSaveManager.SCHEMA_VERSION,
		"energyEarned": 0,
		"energySpent": 0,
		"fragmentsEarned": 0,
		"completedEncounterIds": [],
		"collectedTreasureIds": [],
		"guardianWins": 0,
		"unlockedRewards": [],
	}

static func result_for(request: Dictionary) -> Dictionary:
	var output := empty_result()
	var state: Dictionary = request.get("outdoorState", {})
	output["completedEncounterIds"] = Array(state.get("completedEncounterIds", [])).duplicate()
	output["collectedTreasureIds"] = Array(state.get("collectedTreasureIds", [])).duplicate()
	return output
