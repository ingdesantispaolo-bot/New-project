extends SceneTree

## C-P8.4 — la seconda metà della campagna deve sbloccare contenuto STEM vero,
## senza ottenerlo spostando in avanti quello che serviva ai mondi bassi.
##
## Il pavimento basso è assoluto: ogni formato fisso conserva almeno 2 prove a
## L1 e almeno 4 entro L12. Il pavimento alto misura invece specifiche NUOVE con
## `minLevel > 12`: non basta che la profondità totale a L24 sia maggiore.

const STEM_SUBJECTS := ["matematica", "fisica", "elettronica", "coding", "scienze"]
const FIXED_FORMATS := ["graph", "circuit", "code_debug"]
const MIN_AT_L1 := 2
const MIN_AT_L12 := 4
const MIN_NEW_AFTER_L12 := 2

func _init() -> void:
	var failures: Array = []
	print("Scaglionamento STEM — disponibilità bassa e sblocchi nella seconda metà")
	print("MATERIA/FORMATO             L1   L12   NUOVE L13-24   L24")

	for subject_data in STEM_SUBJECTS:
		var subject := str(subject_data)
		for fmt_data in FIXED_FORMATS:
			var fmt := str(fmt_data)
			var at_l1 := MinigameManager.eligible_specs(subject, fmt, 1).size()
			var at_l12 := MinigameManager.eligible_specs(subject, fmt, 12).size()
			var at_l24 := MinigameManager.eligible_specs(subject, fmt, 24).size()
			var late_unlocks := 0
			for spec_data in Array(MinigameManager.table_for(fmt).get(subject, [])):
				var unlock_level := maxi(1, int((spec_data as Dictionary).get("minLevel", 1)))
				if unlock_level >= 13 and unlock_level <= 24:
					late_unlocks += 1
			print("%-27s %2d   %2d        %2d       %2d" % [
				"%s/%s" % [subject, fmt], at_l1, at_l12, late_unlocks, at_l24])
			if at_l1 < MIN_AT_L1:
				failures.append("%s/%s: solo %d prove a L1 (minimo %d)" % [
					subject, fmt, at_l1, MIN_AT_L1])
			if at_l12 < MIN_AT_L12:
				failures.append("%s/%s: solo %d prove entro L12 (minimo %d)" % [
					subject, fmt, at_l12, MIN_AT_L12])
			if late_unlocks < MIN_NEW_AFTER_L12:
				failures.append("%s/%s: solo %d prove nuove a L13–24 (minimo %d)" % [
					subject, fmt, late_unlocks, MIN_NEW_AFTER_L12])

	if not failures.is_empty():
		printerr("SCAGLIONAMENTO STEM FALLITO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("STEM unlock progression audit OK — basso preservato, almeno 2 prove nuove per formato dopo L12")
	quit(0)
