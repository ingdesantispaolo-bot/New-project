extends SceneTree

## Audit C-08: report locale (nessuna rete), aggregazione e clamp dei valori.

func _init() -> void:
	var empty := LocalProgressReport.new()
	assert(int(empty.summary()["sessions"]) == 0, "report vuoto: nessuna sessione")

	var report := LocalProgressReport.new()
	report.record(1, "matematica", 0.72, 3, 95.0)
	report.record(2, "italiano", 0.81, 5, 120.0)
	var summary := report.summary()
	assert(int(summary["sessions"]) == 2)
	assert(int(summary["missions"]) == 8)
	assert(float(summary["seconds"]) == 215.0)
	assert(not summary.has("remote") and not summary.has("url"), "nessuna telemetria remota")

	# Valori fuori range vengono normalizzati (mastery in [0,1], non negativi).
	report.record(3, "coding", 1.5, -2, -10.0)
	var last: Dictionary = report.summary()["events"][2]
	assert(float(last["mastery"]) == 1.0, "mastery clampata a 1.0")
	assert(int(last["missions"]) == 0, "missions non negative")
	assert(float(last["seconds"]) == 0.0, "seconds non negativi")

	print("C-08 audit OK — report locale, aggregazione, clamp e nessuna rete")
	quit(0)
