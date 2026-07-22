class_name GameAudioManager
extends Node

## Audio nativo condiviso. Legge il manifest C-18, crea i bus e riproduce musica,
## ambiente, UI e SFX senza dipendere da Howler o dalla shell Web.

const MANIFEST_PATH := "res://assets/audio/audio-manifest.json"

var manifest: Dictionary = {}
var assets: Dictionary = {}
var _stream_cache: Dictionary = {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _focus: AudioStreamPlayer
var _environment := ""
var _last_played_ms: Dictionary = {}

func _ready() -> void:
	_load_manifest()
	_configure_buses()
	_music = _make_persistent_player("MusicBase", "Music")
	_ambience = _make_persistent_player("AmbienceBase", "Ambience")
	_focus = _make_persistent_player("MusicFocus", "Music")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Manifest audio non disponibile: %s" % MANIFEST_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Manifest audio non valido")
		return
	manifest = parsed
	assets = manifest.get("assets", {})

func _configure_buses() -> void:
	for bus_spec in manifest.get("buses", []):
		var spec: Dictionary = bus_spec
		var bus_name := str(spec.get("name", ""))
		if bus_name == "":
			continue
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, str(spec.get("parent", "Master")))
		AudioServer.set_bus_volume_db(index, float(spec.get("defaultVolumeDb", 0.0)))

func play_environment(phase: String) -> void:
	var normalized := "night" if phase.to_lower() in ["night", "notte"] else "day"
	if normalized == _environment:
		return
	_environment = normalized
	_play_loop(_music, "music.%s" % normalized)
	_play_loop(_ambience, "ambience.%s" % normalized)

func set_focus(active: bool) -> void:
	if active:
		if not _focus.playing:
			_play_loop(_focus, str(manifest.get("adaptive", {}).get("focusLayer", "music.focus")))
	else:
		_focus.stop()

func play_event(event_name: String, pitch_scale: float = 1.0) -> void:
	play(str(manifest.get("events", {}).get(event_name, event_name)), pitch_scale)

func play_subject(subject: String) -> void:
	var key := str(manifest.get("subjects", {}).get(subject, ""))
	if key != "":
		play(key)

func play(key: String, pitch_scale: float = 1.0) -> void:
	var spec: Dictionary = assets.get(key, {})
	if spec.is_empty():
		return
	var now := Time.get_ticks_msec()
	var cooldown := int(spec.get("cooldownMs", 0))
	if now - int(_last_played_ms.get(key, -cooldown - 1)) < cooldown:
		return
	_last_played_ms[key] = now
	var stream := _stream_for(key)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "OneShot_%s" % key.replace(".", "_")
	player.stream = stream
	player.bus = str(spec.get("bus", "SFX"))
	player.volume_db = float(spec.get("volumeDb", 0.0))
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.max_polyphony = maxi(1, int(spec.get("polyphony", 1)))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))

func set_muted(muted: bool) -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)

func _make_persistent_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	add_child(player)
	return player

func _play_loop(player: AudioStreamPlayer, key: String) -> void:
	var spec: Dictionary = assets.get(key, {})
	var stream := _stream_for(key)
	if spec.is_empty() or stream == null:
		return
	if player.playing and player.stream == stream:
		return
	player.stop()
	player.stream = stream
	player.bus = str(spec.get("bus", player.bus))
	player.volume_db = float(spec.get("volumeDb", 0.0))
	player.play()

func _stream_for(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStream
	var spec: Dictionary = assets.get(key, {})
	var stream := load(str(spec.get("path", ""))) as AudioStream
	if stream is AudioStreamWAV and bool(spec.get("loop", false)):
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_stream_cache[key] = stream
	return stream
