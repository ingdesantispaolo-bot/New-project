extends SceneTree

## Rilievi C-P6 #1/#5/#12: sui 24 profili la scenografia deve provenire dalla
## grammatica autorata del livello. Nessun landmark/prop casuale legacy può
## sovrapporsi alla mappa; il landmark eroe resta perché ha una trasformazione
## didattica esplicita e progressiva.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const BANNED_LEGACY_LABELS := [
	"Albero dei Percorsi",
	"Nucleo Antico",
	"Porta dell'Atlante",
	"Spira Logica",
	"Nido Prisma",
	"Forgia Esterna",
]

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = level
	initial["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	var request := NativeWorldState.default_request("world-visual-triage")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _open_world(level: int) -> Node:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request_for(level))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	return world

func _assert_profile_visuals(world: Node, level: int) -> void:
	var chunks := world.get("chunks") as OutdoorChunkManager
	assert(chunks != null and chunks.composition != null, "mondo %d senza composizione" % level)
	assert(not chunks.composition.identity_props.is_empty(), "mondo %d senza prop identitari" % level)
	for entry in chunks.loaded.values():
		var data: Dictionary = entry["data"]
		assert(Array(data.get("props", [])).is_empty(),
			"mondo %d: prop procedurali fuori grammatica ancora attivi" % level)
		assert(Array(data.get("landmarks", [])).is_empty(),
			"mondo %d: landmark casuali legacy ancora attivi" % level)
	for node in world.find_children("*", "Label", true, false):
		var label := node as Label
		for banned in BANNED_LEGACY_LABELS:
			assert(str(banned) not in label.text,
				"mondo %d: etichetta legacy fuori contesto '%s'" % [level, banned])
	var hero := world.find_child("ProfileHeroLandmark", true, false) as Node2D
	var reaction := world.find_child("ProfileEnvironmentTransform", true, false) as WorldLearningReaction
	assert(hero != null and reaction != null, "mondo %d: landmark autorato o reazione assenti" % level)
	assert(str(hero.get_meta("transform_trigger", "")) != "", "mondo %d: landmark senza causa didattica" % level)
	assert(str(hero.get_meta("transform_effect", "")) != "", "mondo %d: landmark senza effetto leggibile" % level)
	assert(not reaction.active_parts.is_empty(), "mondo %d: landmark senza fasi visuali" % level)

func _dispose(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _cleanup_audio() -> void:
	var audio := root.get_node_or_null("NativeAudio")
	if audio == null:
		return
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
				child.free()
	audio.set("_stream_cache", {})

func _run() -> void:
	root.size = Vector2i(900, 600)
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var world := await _open_world(level)
		_assert_profile_visuals(world, level)
		await _dispose(world)
	_cleanup_audio()
	await create_timer(0.15).timeout
	print("WORLD VISUAL TRIAGE audit OK — 24 profili senza prop/landmark legacy, scenografia autorata e reattiva")
	quit(0)
