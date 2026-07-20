class_name OutdoorSaveBridge
extends RefCounted

## Small, versioned bridge between the Phaser shell and this Godot module.
## The Web export can replace the in-memory transport with JavaScriptBridge;
## the desktop slice uses a JSON file passed through --outdoor-request/--outdoor-result.

const SCHEMA_VERSION := 1
const REQUEST_PATH := "user://eli-quest-outdoor-request.json"
const RESULT_PATH := "user://eli-quest-outdoor-result.json"

func is_web() -> bool:
	return OS.has_feature("web")

func default_request(seed: String = "outdoor-dev-1") -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"playerId": "local",
		"worldSeed": seed,
		"playerLevel": 1,
		"avatar": {"outfit": "avatar-base", "accessory": "", "pet": ""},
		# Anteprima desktop: livrea ciano + pet scintilla, così il compagno si
		# vede anche senza dati reali dalla bottega Phaser.
		"avatarVisual": {
			"bodyColor": 0x6be7d6,
			"accessory": null,
			"pet": {"id": "pet-spark", "kind": "spark", "color": 0xf6c85f},
		},
		"energy": 120,
		"nextReward": {"name": "Outfit Oro", "cost": 220, "rarity": "raro"},
		"outdoorState": {
			"completedEncounterIds": [],
			"collectedTreasureIds": [],
			"clearedHazardIds": [],
			"fragments": 0
		}
	}

func load_request() -> Dictionary:
	if is_web():
		var browser_request = JavaScriptBridge.eval("window.__ELI_OUTDOOR_REQUEST__ || JSON.parse(window.localStorage.getItem('eli-quest-outdoor-request') || 'null')", true)
		if typeof(browser_request) == TYPE_DICTIONARY and int(browser_request.get("schemaVersion", 0)) == SCHEMA_VERSION:
			return browser_request
	if not FileAccess.file_exists(REQUEST_PATH):
		return default_request()
	var file := FileAccess.open(REQUEST_PATH, FileAccess.READ)
	if file == null:
		return default_request()
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return default_request()
	return parsed

func write_result(result: Dictionary) -> void:
	var payload := result.duplicate(true)
	payload["schemaVersion"] = SCHEMA_VERSION
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload))
	if is_web():
		var encoded := JSON.stringify(payload)
		JavaScriptBridge.eval("window.__ELI_OUTDOOR_RESULT__ = %s; window.localStorage.setItem('eli-quest-outdoor-result', JSON.stringify(window.__ELI_OUTDOOR_RESULT__)); window.dispatchEvent(new CustomEvent('eli-outdoor-result', { detail: window.__ELI_OUTDOOR_RESULT__ }));" % encoded, true)

func publish_result_and_return(result: Dictionary, return_url: String) -> void:
	var payload := result.duplicate(true)
	payload["schemaVersion"] = SCHEMA_VERSION
	if is_web():
		var encoded := JSON.stringify(payload)
		var target_url := return_url if return_url != "" else "/"
		# Delay navigation by one browser tick: quitting the Godot runtime in the
		# same JS evaluation can otherwise cancel the Phaser return on Web.
		JavaScriptBridge.eval("window.__ELI_OUTDOOR_RESULT__ = %s; window.localStorage.setItem('eli-quest-outdoor-result', JSON.stringify(window.__ELI_OUTDOOR_RESULT__)); window.setTimeout(function(){ window.location.href = %s; }, 50);" % [encoded, JSON.stringify(target_url)], true)
		return
	else:
		write_result(payload)

func empty_result() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"energyEarned": 0,
		"energySpent": 0,
		"fragmentsEarned": 0,
		"completedEncounterIds": [],
		"collectedTreasureIds": [],
		"guardianWins": 0,
		"unlockedRewards": [],
		# Campi opzionali C-01: il bridge Phaser legacy li ignora, mentre il
		# percorso full-Godot conserva il save canonico senza ricaricare la scena.
		"godotSave": {},
		"level": 1,
		"missionsBySubject": {},
		"mastery": {},
		"apparatus": {}
	}

func result_from_request(request: Dictionary) -> Dictionary:
	var result := empty_result()
	var state: Dictionary = request.get("outdoorState", {})
	result["completedEncounterIds"] = Array(state.get("completedEncounterIds", [])).duplicate()
	result["collectedTreasureIds"] = Array(state.get("collectedTreasureIds", [])).duplicate()
	return result
