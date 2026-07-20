extends SceneTree

func _init() -> void:
	var report := LocalProgressReport.new()
	report.record(1, "matematica", 0.72, 3, 95.0)
	report.record(2, "italiano", 0.81, 5, 120.0)
	var summary := report.summary()
	assert(int(summary["sessions"]) == 2)
	assert(int(summary["missions"]) == 8)
	assert(float(summary["seconds"]) == 215.0)
	assert(not summary.has("remote") and not summary.has("url"))
	print("C-08 audit OK — report locale, mastery e telemetria senza rete")
	quit(0)
