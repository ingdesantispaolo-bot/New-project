class_name NativeWorldState
extends RefCounted

## Stato transitorio della sessione Godot. Il save persistente resta
## GameSaveManager; qui vivono soltanto seed, presentazione e delta del mondo.

static var _pending_launch_request: Dictionary = {}

static func release_smoke_enabled() -> bool:
	return (
		OS.get_cmdline_user_args().has("--eli-release-smoke")
		or OS.get_cmdline_args().has("--eli-release-smoke")
	)

static func stage_launch_request(request: Dictionary) -> void:
	_pending_launch_request = request.duplicate(true)

static func take_launch_request() -> Dictionary:
	var request := _pending_launch_request.duplicate(true)
	_pending_launch_request.clear()
	return request

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
		"accessibility": {
			"highContrast": false,
			"reducedMotion": false,
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
		# La bottega si paga in frammenti (14 agosto 2026): il riepilogo di
		# sessione ha il suo contatore, come ce l'ha l'energia.
		"fragmentsSpent": 0,
		"completedEncounterIds": [],
		"collectedTreasureIds": [],
		"guardianWins": 0,
		"unlockedRewards": [],
		# Riconoscimenti ottenuti in questa uscita. Sono testimonianze del
		# percorso, non valuta e non progressione didattica.
		"recognitionsEarned": [],
	}

static func result_for(request: Dictionary) -> Dictionary:
	var output := empty_result()
	var state: Dictionary = request.get("outdoorState", {})
	output["completedEncounterIds"] = Array(state.get("completedEncounterIds", [])).duplicate()
	output["collectedTreasureIds"] = Array(state.get("collectedTreasureIds", [])).duplicate()
	return output
