extends SceneTree

## Quante ricette di minigioco d'inglese vede ogni livello, e quante di quelle
## sono NUOVE rispetto al livello precedente. Serve a vedere il soffitto: se da
## un certo mondo in poi la colonna «nuove» resta a zero, la materia ha smesso
## di crescere e i mondi che restano ripetono.

func _init() -> void:
	var totali_prima := 0
	print("%5s %8s %7s %s" % ["LIV", "ricette", "nuove", "formati"])
	for level in range(1, 25):
		var formati := MinigameManager.runtime_formats_for("inglese", level)
		var totali := 0
		for fmt in formati:
			totali += MinigameManager.eligible_specs("inglese", str(fmt), level).size()
		print("%5d %8d %7d %s" % [level, totali, totali - totali_prima, ", ".join(formati)])
		totali_prima = totali
	quit(0)
