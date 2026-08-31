class_name GameAudioManager
extends Node

## Audio nativo condiviso. Legge il manifest C-18, crea i bus e riproduce musica,
## ambiente, UI e SFX senza dipendere da Howler o dalla shell Web.

const MANIFEST_PATH := "res://assets/audio/audio-manifest.json"
const SETTINGS_PATH := "user://eli-audio-settings.cfg"
const MASTER_VOLUME_STEPS := [1.0, 0.75, 0.5, 0.25]

var manifest: Dictionary = {}
var assets: Dictionary = {}
var _stream_cache: Dictionary = {}
var _music: AudioStreamPlayer
var _music_secondary: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ambience_secondary: AudioStreamPlayer
var _focus: AudioStreamPlayer
var _music_tween: Tween
var _ambience_tween: Tween
var _environment := ""
var _world_soundscape := ""
var _last_played_ms: Dictionary = {}
var _play_count := 0
var _master_volume := 1.0
var _muted := false

func _ready() -> void:
	_load_manifest()
	_configure_buses()
	_load_settings()
	_music = _make_persistent_player("MusicBase", "Music")
	_music_secondary = _make_persistent_player("MusicCrossfade", "Music")
	_ambience = _make_persistent_player("AmbienceBase", "Ambience")
	_ambience_secondary = _make_persistent_player("AmbienceCrossfade", "Ambience")
	_focus = _make_persistent_player("MusicFocus", "Music")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_publish_web_state()

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
	_apply_world_soundscape_mix()
	call_deferred("_publish_web_state")

## Richiamata da ContentPack quando il pacchetto audio finisce di arrivare.
##
## Fino a quel momento `_stream_for()` ha restituito null e i player sono rimasti
## fermi: il mondo era gia' entrato, semplicemente in silenzio. Qui si ripete
## l'ultima richiesta, ora che i file esistono davvero.
func refresh_after_content_load() -> void:
	if _environment == "":
		return
	_apply_world_soundscape_mix()
	call_deferred("_publish_web_state")

func configure_world_soundscape(soundscape: String) -> void:
	# Il profilo sceglie un asset autorato nel manifest. Se manca, il mondo resta
	# giocabile e torna all'ambiente giorno/notte condiviso.
	_world_soundscape = soundscape.to_lower()
	_apply_world_soundscape_mix()
	call_deferred("_publish_web_state")

static func resolve_soundscape_asset(manifest_data: Dictionary, soundscape: String, phase: String) -> String:
	var normalized_phase := "night" if phase.to_lower() in ["night", "notte"] else "day"
	var fallback := "ambience.%s" % normalized_phase
	var soundscape_contract: Dictionary = manifest_data.get("soundscapes", {})
	var by_id: Dictionary = soundscape_contract.get("byId", {})
	var spec: Dictionary = by_id.get(soundscape.to_lower(), {})
	var candidate := str(spec.get("asset", ""))
	var manifest_assets: Dictionary = manifest_data.get("assets", {})
	return candidate if candidate != "" and manifest_assets.has(candidate) else fallback

func _apply_world_soundscape_mix() -> void:
	if not is_instance_valid(_music) or not is_instance_valid(_ambience):
		return
	var ambience_key := resolve_soundscape_asset(manifest, _world_soundscape, _environment)
	_play_loop(_ambience, ambience_key)
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
		"terra-e-vento":
			music_pitch = 0.90
			ambience_pitch = 0.78
			ambience_offset_db = 1.8
		"pulsazioni-vitali":
			music_pitch = 0.96
			ambience_pitch = 0.72
			ambience_offset_db = 2.2
		"voci-in-assemblea":
			music_pitch = 1.04
			ambience_pitch = 1.08
			ambience_offset_db = 1.0
		"coro-dei-sistemi":
			music_pitch = 1.12
			ambience_pitch = 0.88
			ambience_offset_db = 0.4
	if _environment != "":
		_transition_loop("music", "music.%s" % _environment, 0.0, music_pitch)
		_transition_loop("ambience", ambience_key, ambience_offset_db, ambience_pitch)

## Volume dispositivo, condiviso fra i profili. I bus di categoria conservano
## il mix autorato; qui si regola soltanto Master, quindi nessun rapporto fra
## musica, ambiente, interfaccia ed effetti viene perso.
func master_volume_percent() -> int:
	return roundi(_master_volume * 100.0)

func is_muted() -> bool:
	return _muted

func cycle_master_volume() -> void:
	var closest := 0
	var distance := INF
	for index in range(MASTER_VOLUME_STEPS.size()):
		var candidate := float(MASTER_VOLUME_STEPS[index])
		if absf(candidate - _master_volume) < distance:
			distance = absf(candidate - _master_volume)
			closest = index
	set_master_volume(float(MASTER_VOLUME_STEPS[(closest + 1) % MASTER_VOLUME_STEPS.size()]))

func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_settings()
	_save_settings()

func toggle_mute() -> void:
	set_muted(not _muted)

func set_muted(value: bool) -> void:
	_muted = value
	_apply_settings()
	_save_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_master_volume = clampf(float(config.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
		_muted = bool(config.get_value("audio", "muted", false))
	_apply_settings()

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", _master_volume)
	config.set_value("audio", "muted", _muted)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Impostazioni audio non salvate: %d" % error)

func _apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(_master_volume, 0.0001)))
	AudioServer.set_bus_mute(master, _muted)
	call_deferred("_publish_web_state")

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
	_play_count += 1
	call_deferred("_publish_web_state")

func _publish_web_state() -> void:
	if not OS.has_feature("web"):
		return
	var master := AudioServer.get_bus_index("Master")
	var snapshot := {
		"environment": _environment,
		"soundscape": _world_soundscape,
		"musicPlaying": is_instance_valid(_music) and _music.playing,
		"ambiencePlaying": is_instance_valid(_ambience) and _ambience.playing,
		"focusPlaying": is_instance_valid(_focus) and _focus.playing,
		"muted": master >= 0 and AudioServer.is_bus_mute(master),
		"masterVolumePercent": master_volume_percent(),
		"playCount": _play_count,
	}
	JavaScriptBridge.eval("window.__eliAudioState = %s;" % JSON.stringify(snapshot))

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

## Due player per canale permettono una vera dissolvenza incrociata: il nuovo
## paesaggio entra mentre il precedente esce. Il valore autorato nel manifest
## non e' piu' soltanto documentazione.
func _transition_loop(channel: String, key: String, volume_offset_db: float,
		pitch_scale: float) -> void:
	var spec: Dictionary = assets.get(key, {})
	if spec.is_empty():
		return
	var stream := _stream_for(key)
	if stream == null:
		return
	var active := _music if channel == "music" else _ambience
	var standby := _music_secondary if channel == "music" else _ambience_secondary
	var target_volume := float(spec.get("volumeDb", 0.0)) + volume_offset_db
	if active.playing and active.stream == stream:
		active.bus = str(spec.get("bus", active.bus))
		active.volume_db = target_volume
		active.pitch_scale = pitch_scale
		return
	var current_tween := _music_tween if channel == "music" else _ambience_tween
	if is_instance_valid(current_tween):
		current_tween.kill()
	standby.stop()
	standby.stream = stream
	standby.bus = str(spec.get("bus", standby.bus))
	standby.pitch_scale = pitch_scale
	if not active.playing:
		standby.volume_db = target_volume
		standby.play()
	else:
		standby.volume_db = -60.0
		standby.play()
		var seconds := maxf(0.05, float(manifest.get("adaptive", {}).get("crossfadeSeconds", 2.2)))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(active, "volume_db", -60.0, seconds)
		tween.tween_property(standby, "volume_db", target_volume, seconds)
		tween.chain().tween_callback(func(): active.stop())
		if channel == "music":
			_music_tween = tween
		else:
			_ambience_tween = tween
	if channel == "music":
		_music = standby
		_music_secondary = active
	else:
		_ambience = standby
		_ambience_secondary = active

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
