extends SceneTree

## Verifica il contratto che l'audit degli asset non puo' vedere: controlli
## utente sul Master e due player realmente sovrapposti durante il crossfade.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio := root.get_node_or_null("NativeAudio") as GameAudioManager
	assert(audio != null, "NativeAudio non caricato")
	for bus_name in ["Music", "Ambience", "SFX", "UI"]:
		assert(AudioServer.get_bus_index(bus_name) >= 0, "bus audio assente: %s" % bus_name)

	var original_volume := audio.master_volume_percent()
	var original_muted := audio.is_muted()
	audio.set_master_volume(0.5)
	audio.set_muted(true)
	assert(audio.master_volume_percent() == 50, "volume Master non applicato")
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "muto Master non applicato")

	var panel := PauseMenuPanel.new()
	root.add_child(panel)
	await process_frame
	panel.apri("Audit", "Mondo audio", "RIAVVIA", "", false)
	assert(panel.find_child("PauseVolumeButton", true, false) is Button,
		"controllo volume non esposto nella pausa")
	assert(panel.find_child("PauseMuteButton", true, false) is Button,
		"controllo muto non esposto nella pausa")
	panel.congeda()
	panel.queue_free()

	audio.play_environment("day")
	await process_frame
	audio.play_environment("night")
	await process_frame
	var music_players := 0
	for child in audio.get_children():
		if child is AudioStreamPlayer and str(child.name).begins_with("Music") and child.playing:
			music_players += 1
	assert(music_players >= 2, "giorno/notte non si sovrappongono durante il crossfade")

	audio.set_master_volume(float(original_volume) / 100.0)
	audio.set_muted(original_muted)
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
	print("AUDIO CONTROLS audit OK - volume, muto e crossfade attivi")
	quit(0)
