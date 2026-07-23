extends SceneTree

const ValidationReport = preload("res://scripts/game/validation_report.gd")
const LearningConfig = preload("res://scripts/game/learning_config.gd")

## Audit O-P6 (report + config): il report locale ha le 5 dimensioni per ogni
## materia attiva, in intervalli validi, e rispetta la configurazione (fascia e
## materie attive).
## Uso: godot --headless --path godot --script res://scripts/game/validation_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var save := GameSaveManager.new()
	var prog := ProgressionManager.new(save, content)

	# Un po' di progresso reale: missioni + evidenza per-argomento su due materie.
	for _i in range(6):
		var m := content.build_mission("matematica", 1, 3)
		prog.record_mission("matematica", 3, 3, 10)
		prog.record_topic_stats("matematica", _stats(m))
		var mi := content.build_mission("italiano", 2, 3)
		prog.record_mission("italiano", 3, 3, 10)
		prog.record_topic_stats("italiano", _stats(mi))
	save.data["progressReport"] = {"events": [{"level": 1, "subject": "matematica", "seconds": 42.0}]}

	# Report completo.
	var report := ValidationReport.build(save, content)
	assert(report.has("aggregate") and report.has("bySubject"), "report incompleto")
	assert(str(report["schoolBand"]) == "primaria", "fascia di default attesa")
	assert(Array(report["activeSubjects"]).size() == 12, "di default tutte le materie sono attive")
	assert(report["bySubject"].size() == 12, "il report deve coprire le materie attive")

	for subject in report["bySubject"].keys():
		var r: Dictionary = report["bySubject"][subject]
		for dim in ["coverage", "confidence", "retention"]:
			var v := float(r[dim])
			assert(v >= 0.0 and v <= 1.0, "%s.%s fuori range: %f" % [subject, dim, v])
		assert(int(r["help"]) >= 0 and float(r["timeSeconds"]) >= 0.0, "aiuti/tempo non validi")
	# Le materie esercitate hanno copertura e confidenza > 0.
	assert(float(report["bySubject"]["matematica"]["coverage"]) > 0.0, "matematica esercitata deve avere copertura")
	assert(float(report["bySubject"]["italiano"]["confidence"]) > 0.0, "italiano esercitato deve avere confidenza")
	assert(float(report["bySubject"]["matematica"]["timeSeconds"]) >= 42.0, "il tempo deve confluire nel report")

	# La configurazione filtra le materie del report.
	LearningConfig.set_school_band(save, "secondaria-1")
	assert(LearningConfig.set_active_subjects(save, ["matematica", "italiano", "logica"]))
	var report2 := ValidationReport.build(save, content)
	assert(str(report2["schoolBand"]) == "secondaria-1", "la fascia configurata deve comparire")
	assert(report2["bySubject"].size() == 3, "il report deve limitarsi alle materie attive")
	assert(not report2["bySubject"].has("latino"), "una materia disattivata non deve comparire nel report")

	print("Validation audit OK — report con copertura/confidenza/ritenzione/aiuti/tempo per materia, configurazione fascia+materie rispettata")
	quit(0)

func _stats(mission: Dictionary) -> Dictionary:
	var stats: Dictionary = {}
	for node in mission.get("nodes", []):
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats
