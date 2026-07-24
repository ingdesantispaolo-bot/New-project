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
var _world_soundscape := ""
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
	_apply_world_soundscape_mix()

func configure_world_soundscape(soundscape: String) -> void:
	# I loop restano condivisi e leggeri per Web, ma ogni profilo ottiene un mix
	# riconoscibile. Non modifica eventi didattici né stato di progressione.
	_world_soundscape = soundscape.to_lower()
	_apply_world_soundscape_mix()

func _apply_world_soundscape_mix() -> void:
	if not is_instance_valid(_music) or not is_instance_valid(_ambience):
		return
	var music_pitch := 1.0
	var ambience_pitch := 1.0
	var ambience_offset_db := 0.0
	match _world_soundscape:
		"ingranaggi-ritmici":
			music_pitch = 0.92
			ambience_pitch = 0.78
			ambience_offset_db = 1.5
		"onde-e-radio":
			music_pitch = 1.04
			ambience_pitch = 0.88
			ambience_offset_db = 2.0
		"metallo-e-vapore":
			music_pitch = 0.90
			ambience_pitch = 0.72
			ambience_offset_db = 2.4
		"campane-di-cristallo":
			music_pitch = 1.12
			ambience_pitch = 1.18
			ambience_offset_db = 1.2
		"eco-di-pietra":
			music_pitch = 0.86
			ambience_pitch = 0.82
			ambience_offset_db = 0.8
		"ronzio-e-acqua":
			music_pitch = 1.06
			ambience_pitch = 0.76
			ambience_offset_db = 2.6
		"gabbiani-e-risacca":
			music_pitch = 1.08
			ambience_pitch = 0.90
			ambience_offset_db = 2.2
		"vita-brulicante":
			music_pitch = 1.12
			ambience_pitch = 1.06
			ambience_offset_db = 1.8
		"folla-e-campane":
			music_pitch = 0.98
			ambience_pitch = 1.12
			ambience_offset_db = 1.4
		"scatti-e-silenzi":
			music_pitch = 0.88
			ambience_pitch = 0.70
			ambience_offset_db = -1.0
		"vento-di-sabbia":
			music_pitch = 0.86
			ambience_pitch = 0.66
			ambience_offset_db = 1.8
		"sussurri-narranti":
			music_pitch = 0.94
			ambience_pitch = 1.16
			ambience_offset_db = -0.6
		"clic-e-segnali":
			music_pitch = 1.08
			ambience_pitch = 0.82
			ambience_offset_db = 2.0
		"mercato-poliglotta":
			music_pitch = 1.14
			ambience_pitch = 1.10
			ambience_offset_db = 1.6
		"abisso-e-bolle":
			music_pitch = 0.82
			ambience_pitch = 0.66
			ambience_offset_db = 2.0
		"riverbero-armonico":
			music_pitch = 1.08
			ambience_pitch = 1.22
			ambience_offset_db = 0.6
		"silenzio-antico":
			music_pitch = 0.78
			ambience_pitch = 0.62
			ambience_offset_db = -1.8
		"statica-e-tuoni":
			music_pitch = 0.94
			ambience_pitch = 0.84
			ambience_offset_db = 2.8
	_music.pitch_scale = music_pitch
	_ambience.pitch_scale = ambience_pitch
	if _environment != "":
		var ambience_spec: Dictionary = assets.get("ambience.%s" % _environment, {})
		_ambience.volume_db = float(ambience_spec.get("volumeDb", 0.0)) + ambience_offset_db

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
	if spec.is_empty():
		return
	var stream := _stream_for(key)
	if stream == null:
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
	var path := str(spec.get("path", "")).strip_edges()
	if path == "" or not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream is AudioStreamWAV and bool(spec.get("loop", false)):
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_stream_cache[key] = stream
	return stream
