extends SceneTree

## Audit C-06: HubController espone il gate e guida il loop di riparazione
## (missioni → gate → esame richiesto → riparazione → livello → gate richiuso).

func _init() -> void:
	var save := GameSaveManager.new()
	save.data["energy"] = 200
	var hub := HubController.new()
	root.add_child(hub)
	var exam_signals := {"count": 0}
	hub.exam_requested.connect(func(): exam_signals["count"] += 1)
	hub.setup(save)

	assert(not hub.request_exam(), "esame non disponibile prima del gate")
	assert(exam_signals["count"] == 0)
	assert(not bool(hub.state()["ready"]))
	assert(str(hub.state()["apparatus"]) == "nucleo")

	var progression := hub.progression
	for _i in range(5):
		progression.record_mission("matematica", 3, 3, 0, true)
		# Evidenza per-argomento per la dimensione COPERTURA del gate.
		progression.record_topic_stats("matematica", {"tabelline": {"seen": 3, "correct": 3}})
	assert(bool(hub.state()["ready"]), "gate pronto dopo missioni + padronanza + copertura")
	assert(hub.request_exam(), "esame disponibile dopo il gate")
	assert(exam_signals["count"] == 1, "request_exam deve emettere exam_requested")

	# Esame superato → riparazione → livello sale e apparato acceso.
	var level_before := int(hub.state()["level"])
	assert(progression.repair_and_advance(true))
	assert(int(hub.state()["level"]) == level_before + 1)
	assert(int(save.data["apparatus"]["nucleo"]["repairedLevel"]) == level_before)
	assert(not bool(hub.state()["ready"]), "dopo la riparazione il gate del nuovo livello è chiuso")

	print("C-06 audit OK — Hub: gate, esame richiesto e loop riparazione→livello")
	quit(0)
