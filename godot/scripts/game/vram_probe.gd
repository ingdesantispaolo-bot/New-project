extends SceneTree

## Misura la VRAM texture REALMENTE residente mentre un mondo e' caricato.
##
## Serve perche' il conto statico sugli asset ("somma di tutte le texture")
## sovrastima di molto: le underpaint identitarie, i landmark e i ritratti NPC
## sono per-mondo, quindi non stanno in memoria tutti insieme. Va lanciata SENZA
## `--headless`: il driver dummy non alloca texture e riporterebbe zero.
##
##   Godot --path godot --rendering-driver opengl3 --script scripts/game/vram_probe.gd

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
## Il mondo 1 torna due volte, in testa e in coda: se il rilascio delle cache
## funziona le due letture coincidono, altrimenti la seconda porta con se' il
## peso di tutti i mondi visitati nel mezzo. E' il controllo che distingue un
## leak da una semplice differenza di contenuti tra mondi.
const SAMPLE_LEVELS := [1, 7, 13, 19, 24, 1]

func _init() -> void:
	call_deferred("_run")

func _request_for(level: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": level}
	var request := NativeWorldState.default_request("vram-probe-%d" % level)
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = level
	return request

func _mib(bytes: float) -> float:
	return snappedf(bytes / 1048576.0, 0.1)

func _run() -> void:
	# Baseline: cosa e' gia' residente prima di caricare qualunque mondo.
	await process_frame
	await process_frame
	var baseline := float(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	print("VRAM baseline (nessun mondo): %s MiB" % _mib(baseline))

	var peak := 0.0
	for level in SAMPLE_LEVELS:
		var world := WORLD_SCENE.instantiate()
		world.set("launch_request_override", _request_for(level))
		root.add_child(world)
		for _i in range(8):
			await process_frame

		var texture_bytes := float(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
		var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		peak = maxf(peak, texture_bytes)
		print("VRAM mondo %02d: %s MiB texture | %d draw call" % [
			level, _mib(texture_bytes), draw_calls])

		root.remove_child(world)
		world.queue_free()
		for _i in range(4):
			await process_frame

	print("VRAM PROBE — picco texture residenti: %s MiB" % _mib(peak))
	quit(0)
