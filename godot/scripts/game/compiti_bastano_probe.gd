extends SceneTree

## Sonda: **completando TUTTI gli eventi che il mondo mette sulla mappa, il gate
## a dodici materie si apre?**
##
## Nasce dalla segnalazione: «ho finito il mondo 1 con tutti i compiti assegnati
## ma non passo al mondo 2». `world_unlock_probe` gioca solo le missioni del
## focus; qui si apre il **mondo vero**, si legge l'elenco degli eventi che ha
## generato e si gioca tutto una volta ciascuno, sempre giusto — il massimo che
## uno studente diligente puo' fare senza rimacinare le palestre.
##
## Il gate resta quello a dodici materie: si chiede a `evaluate_core` con la
## lista intera, cosi' la misura non dipende da come e' tarato in questo momento.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const NODI_MISSIONE := 3
const NODI_ENIGMA := 4
const NODI_PRATICA := 3

func _init() -> void:
	call_deferred("_run")

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

func _gioca(save, content, prog, subject: String, quanti: int, conta_per_gate: bool) -> int:
	var mission: Dictionary = content.build_mission(
		subject, save.level(), quanti, SpacedRepetition.due_map(save),
		null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	if nodes.is_empty():
		return 0
	if conta_per_gate:
		prog.record_mission(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	else:
		prog.record_practice(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))
	return nodes.size()

func _quanti_eventi(eventi: Array, materia: String) -> int:
	var n := 0
	for e in eventi:
		if str(Dictionary(e).get("subject", "")) == materia:
			n += 1
	return n

func _apri(livello: int) -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 900
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("compiti-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	for _i in range(12):
		await process_frame
	return world

func _run() -> void:
	print("\nTutti gli eventi del mondo, una volta ciascuno — il gate a DODICI materie si apre?\n")
	print("%-6s %-8s %-9s %-11s %-7s %s" % [
		"MONDO", "EVENTI", "ESERCIZI", "MATERIE OK", "APRE?", "che cosa manca"])
	for livello in [1, 2, 5, 12]:
		var world := await _apri(livello)
		var eventi: Array = Array(world.get("mission_events"))
		var save := GameSaveManager.new()
		save.set_level(livello)
		var content := ContentManager.new()
		var prog := ProgressionManager.new(save, content)
		var esercizi := 0
		for e in eventi:
			var evento: Dictionary = e
			var materia := str(evento.get("subject", ""))
			var conta := bool(evento.get("countsForGate", false))
			var quanti := NODI_PRATICA
			if conta:
				quanti = NODI_ENIGMA if str(evento.get("kind", "")) == "enigma" else NODI_MISSIONE
			esercizi += _gioca(save, content, prog, materia, quanti, conta)
		prog.aggiorna_traguardi_di_livello()
		var conteggi: Dictionary = {}
		for s in ApparatusConfig.SUBJECT_CYCLE:
			conteggi[str(s)] = content.reachable_topic_count(str(s), livello)
		var stato := GateReadiness.evaluate_core(
			save, ApparatusConfig.mastery_threshold(livello), conteggi,
			Array(ApparatusConfig.SUBJECT_CYCLE))
		var mancanti: Array = stato.get("missing", [])
		var motivi: Dictionary = {}
		for m in mancanti:
			for r in Array(Dictionary(stato["subjects"])[str(m)].get("reasons", [])):
				motivi[str(r)] = int(motivi.get(str(r), 0)) + 1
		print("%-6d %-8d %-9d %-11s %-7s %s" % [
			livello, eventi.size(), esercizi, "%d/12" % (12 - mancanti.size()),
			"SI" if bool(stato["ready"]) else "NO", str(motivi)])
		for m in mancanti:
			var v: Dictionary = Dictionary(stato["subjects"])[str(m)]
			print("        %-13s visti %d / servono %d argomenti · padronanza %.2f / %.2f · eventi nel mondo: %d" % [
				str(m), int(save.topics_seen_this_level(str(m))),
				GateReadiness.coverage_target(int(conteggi.get(str(m), -1)), livello, ApparatusConfig.is_core(str(m))),
				float(v.get("mastery", 0.0)), float(v.get("threshold", v.get("masteryThreshold", 0.0))),
				_quanti_eventi(eventi, str(m))])
		world.queue_free()
		await process_frame
	quit(0)
