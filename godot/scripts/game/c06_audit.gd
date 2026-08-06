extends SceneTree

## Audit C-06: HubController espone il gate e guida il loop di riparazione
## (missioni → gate → esame richiesto → riparazione → livello → gate richiuso).

# Il gate del livello chiede TUTTE le materie dal 5 agosto 2026: allenare le
# tre strumentali non basta più, e questo audit descriveva la regola vecchia.
## Evidenza su abbastanza argomenti da soddisfare la COPERTURA a qualunque
## livello. Dal 5 agosto 2026 la copertura richiesta cresce col livello e scala
## con la materia (prima c'era un tetto fisso di tre): una fixture con tre
## argomenti non basta più, e falliva senza che ci fosse niente di rotto.
func _evidenza_larga() -> Dictionary:
	var stats: Dictionary = {}
	for i in range(24):
		stats["t%d" % (i + 1)] = {"seen": 3, "correct": 3}
	return stats

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
		# La copertura si conta PER LIVELLO dal 5 agosto 2026: un argomento solo
		# non la soddisfa più, e non perché il gate sia rotto — perché chiede di
		# toccare più argomenti in questo livello.
		progression.record_topic_stats("matematica", {
			"tabelline": {"seen": 3, "correct": 3}, "calcolo": {"seen": 3, "correct": 3},
			"frazioni": {"seen": 3, "correct": 3}, "numeri": {"seen": 3, "correct": 3},
			"potenze": {"seen": 3, "correct": 3}})
	assert(bool(hub.state()["ready"]), "gate pronto dopo missioni + padronanza + copertura")
	assert(hub.request_exam(), "esame disponibile dopo il gate")
	assert(exam_signals["count"] == 1, "request_exam deve emettere exam_requested")

	# Esame superato → riparazione → livello sale e apparato acceso.
	var level_before := int(hub.state()["level"])
	# Riparare accende una stanza; per salire di livello serve il nucleo.
	assert(progression.repair_apparatus(ApparatusConfig.world_subject(level_before), true))
	assert(int(save.data["apparatus"]["nucleo"]["repairedLevel"]) == level_before)
	for core_data in ApparatusConfig.SUBJECT_CYCLE:
		var core_subject := str(core_data)
		for _round in range(6):
			progression.record_mission(core_subject, 3, 3, 0, true)
			progression.record_topic_stats(core_subject, _evidenza_larga())
	assert(progression.advance_level(), "col nucleo pronto si deve salire")
	assert(int(hub.state()["level"]) == level_before + 1)
	assert(progression.repaired_apparatus_count() == 1, "una sola stanza accesa dopo la prima riparazione")

	print("C-06 audit OK — Hub: gate, esame richiesto e loop riparazione→livello")
	quit(0)
