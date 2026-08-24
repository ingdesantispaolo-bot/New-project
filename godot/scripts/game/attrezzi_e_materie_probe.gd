extends SceneTree

## Sonda: **con gli attrezzi che uno studente ha davvero, quante materie pu\u00f2
## allenare in questo mondo?**
##
## Il gate chiede tutte e dodici. Ogni mondo dedica una palestra a ciascuna delle
## altre undici — ma una palestra pu\u00f2 stare dietro un varco che chiede un
## attrezzo. Se l'unica palestra di latino \u00e8 dietro la falce e la falce non ce
## l'hai, latino non si allena qui: e il gate lo chiede lo stesso.
##
## Si misurano due scenari: **senza attrezzi** (chi arriva senza aver mai
## finito una riparazione) e **con quelli dovuti al mondo**
## (`FieldTools.consegnati_entro`), cio\u00e8 lo studente diligente.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _apri(livello: int, attrezzi: Array) -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	initial["cosmetics"] = {"unlocked": attrezzi.duplicate(), "equipped": {}}
	var request := NativeWorldState.default_request("attrezzi-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _i in range(30):
		await process_frame
	return world

func _materie_allenabili(world: Node) -> Array:
	var aperte: Dictionary = {}
	for nodo in get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or not world.is_ancestor_of(nodo):
			continue
		var kind := str(nodo.get_meta("kind", ""))
		if kind != "minigame" and kind != "encounter" and kind != "enigma":
			continue
		if not bool(world.call("_equipment_requirement_met", nodo)):
			continue
		var payload: Dictionary = nodo.get_meta("payload", {})
		var materia := str(payload.get("subject", ""))
		if not materia.is_empty():
			aperte[materia] = true
	return aperte.keys()

func _run() -> void:
	print("ATTREZZI| %-6s %-16s %-16s %-16s %s" % [
		"MONDO", "SENZA ATTREZZI", "ALL'ARRIVO", "CON I DOVUTI", "materie chiuse dai varchi"])
	for livello in [1, 2, 3, 5, 7, 11]:
		var senza := await _apri(livello, [])
		var a := _materie_allenabili(senza).size()
		senza.queue_free()
		await process_frame
		var attrezzi := FieldTools.consegnati_entro(livello)
		var con := await _apri(livello, attrezzi)
		var aperte := _materie_allenabili(con)
		var chiuse: Array = []
		for s in ApparatusConfig.SUBJECT_CYCLE:
			if not aperte.has(str(s)):
				chiuse.append(str(s))
		con.queue_free()
		await process_frame
		# Lo stato vero di chi ARRIVA in questo mondo: ha gli attrezzi dei mondi
		# precedenti, non ancora quello che si consegna qui.
		var in_arrivo := FieldTools.consegnati_entro(maxi(1, livello - 1))
		var mondo_arrivo := await _apri(livello, in_arrivo)
		var aperte_arrivo := _materie_allenabili(mondo_arrivo)
		mondo_arrivo.queue_free()
		await process_frame
		print("ATTREZZI| %-6d %-16s %-16s %-16s %s" % [
			livello, "%d/12" % a, "%d/12" % aperte_arrivo.size(),
			"%d/12" % aperte.size(), str(chiuse)])
	quit(0)
