class_name ExerciseSignature
extends RefCounted

## IDENTITÀ DI CONTENUTO di una prova: due nodi con la stessa firma sono la stessa
## prova **per chi la gioca**, anche se hanno id diversi, elementi mescolati in
## altro ordine o la riga giusta in un'altra posizione.
##
## Perché una definizione sola, e perché è l'abilitatore della Fase 0.
##
## Prima esistevano tre chiavi diverse e incoerenti:
##  1. `ContentManager` deduplicava DENTRO la sessione con `formato|testo`;
##  2. la stessa classe ricordava le prove recenti con `formato|testo|risposta`;
##  3. `variety_audit` misurava con testo + risposta + i payload serializzati.
##
## Da questo scarto nascevano due difetti reali:
##
## - **la memoria anti-ripetizione non scattava sui formati specialisti.** La
##   verifica «l'ho già vista di recente» confrontava la chiave STRETTA con una
##   lista di chiavi LARGHE: combaciavano solo dove la risposta è vuota
##   (abbinamento, ordinamento, smistamento). Per grafico, circuito e caccia
##   all'errore — cioè proprio i formati con le ripetizioni peggiori misurate
##   (fisica ×8, scienze ×7) — il confronto non poteva riuscire mai.
## - **la stessa prova mescolata contava come nuova.** Le righe rimescolate di una
##   caccia all'errore cambiano la risposta (il numero di riga) e l'ordine degli
##   elementi cambia il payload serializzato: la misura vedeva varietà dove il
##   bambino vedeva lo stesso esercizio.
##
## La regola che risolve entrambi: **la firma guarda il contenuto, mai la
## presentazione.** L'ordine in cui gli elementi appaiono è presentazione; quali
## elementi sono e come si risolvono è contenuto. Da qui in avanti la firma è
## anche ciò che rende visibile la profondità delle specifiche a insieme: due
## estrazioni diverse dallo stesso insieme sono due prove diverse, e ora si vede.

static func of(node: Dictionary) -> String:
	var fmt := str(node.get("format", ""))
	var parts: Array = [fmt, str(node.get("prompt", "")).strip_edges()]
	match fmt:
		"matching":
			# Quali coppie, non in che ordine sono state pescate.
			var pairs: Array = []
			for entry in Array(node.get("pairs", [])):
				var pair := entry as Dictionary
				pairs.append("%s→%s" % [str(pair.get("left", "")), str(pair.get("right", ""))])
			pairs.sort()
			parts.append(";".join(PackedStringArray(pairs)))
		"ordering":
			# `items` è la presentazione mescolata: l'esercizio è l'ordine giusto.
			parts.append(";".join(PackedStringArray(_strings(node.get("correctOrder", [])))))
		"classification":
			var assignments := node.get("assignments", {}) as Dictionary
			var rows: Array = []
			for key in assignments.keys():
				rows.append("%s→%s" % [str(key), str(assignments[key])])
			rows.sort()
			parts.append(";".join(PackedStringArray(rows)))
		"code_debug":
			# La riga giusta identificata dal TESTO, non dal numero: rimescolare le
			# righe non crea una prova nuova.
			var lines := _strings(node.get("codeLines", []))
			var index := int(node.get("answerLine", 0)) - 1
			var solution := ""
			if index >= 0 and index < lines.size():
				solution = lines[index]
			var sorted_lines: Array = lines.duplicate()
			sorted_lines.sort()
			parts.append(";".join(PackedStringArray(sorted_lines)))
			parts.append("→%s" % solution)
		"graph", "circuit", "hotspot":
			var field := "points"
			if fmt == "circuit":
				field = "components"
			elif fmt == "hotspot":
				field = "hotspots"
			var ids: Array = []
			for entry in Array(node.get(field, [])):
				ids.append(str((entry as Dictionary).get("id", "")))
			ids.sort()
			parts.append(";".join(PackedStringArray(ids)))
			parts.append("→%s" % str(node.get("answer", "")))
		_:
			# Scelta multipla, risposta numerica e formati ancora pianificati: le
			# opzioni contano come insieme, la risposta come contenuto.
			var options := _strings(node.get("options", []))
			options.sort()
			parts.append(";".join(PackedStringArray(options)))
			parts.append("→%s" % str(node.get("answer", "")))
	return "|".join(PackedStringArray(parts))

static func _strings(value: Variant) -> Array:
	var out: Array = []
	for item in Array(value):
		out.append(str(item))
	return out
