extends SceneTree

## Le coppie (materia, formato) piu' povere: al livello 1 e al livello 24.
##
## Serve a distinguere due cose che nella tabella dell'audit si somigliano:
## una coppia povera PER SEMPRE, e una coppia povera SOLO ALL'INIZIO perche' le
## specifiche hanno un `minLevel` alto. Il rimedio e' diverso.

func _init() -> void:
	print("%-13s %-14s %8s %8s" % ["MATERIA", "FORMATO", "L1", "L24"])
	var rows: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			var low := MinigameManager.format_depth(subject, fmt, 1)
			var high := MinigameManager.format_depth(subject, fmt, 24)
			if high <= 0:
				continue
			rows.append({"s": subject, "f": fmt, "l1": low, "l24": high})
	rows.sort_custom(func(a, b): return int(a["l24"]) < int(b["l24"]))
	for row in rows:
		if int(row["l24"]) < 10000:
			print("%-13s %-14s %8d %8d" % [row["s"], row["f"], int(row["l1"]), int(row["l24"])])
	print("\ncoppie sotto 10.000 al L24: %d su %d" % [
		rows.filter(func(r): return int(r["l24"]) < 10000).size(), rows.size()])
	print("coppie sotto 100 al L24: %d" % rows.filter(func(r): return int(r["l24"]) < 100).size())
	print("coppie povere solo al L1 (L1<100 ma L24>=10.000): %d" % rows.filter(
		func(r): return int(r["l1"]) < 100 and int(r["l24"]) >= 10000).size())
	quit(0)
