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

## L'IMPRONTA: la stessa identità, ridotta a un numero.
##
## Serve dove la firma va conservata e non letta — la memoria delle prove superate
## vive nel salvataggio, e tenere per esteso il testo di ogni esercizio risolto
## gonfierebbe ogni file e ogni copia in cloud. Sta qui e non in chi la usa perché
## «stessa prova» deve restare una definizione sola: il save che scrive e la
## selezione che filtra devono chiedersi la stessa cosa, o non si incontrano mai.
static func fingerprint(node: Dictionary) -> int:
	return hash(of(node))

## Come sopra, per chi ha già la firma in mano e non deve ricalcolarla.
static func fingerprint_of(signature: String) -> int:
	return hash(signature)

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
		"machine_path":
			parts.append("%d→%d" % [int(node.get("start", 0)), int(node.get("target", 0))])
			var machines: Array = []
			for entry in Array(node.get("machines", [])):
				var machine := entry as Dictionary
				machines.append("%s:%s:%d" % [
					str(machine.get("id", "")), str(machine.get("op", "")),
					int(machine.get("value", 0)),
				])
			machines.sort()
			parts.append(";".join(PackedStringArray(machines)))
			parts.append("posti=%d" % int(node.get("slotCount", 0)))
		"mystery_sample":
			var sample_ids: Array = []
			for entry in Array(node.get("samples", [])):
				sample_ids.append(str((entry as Dictionary).get("id", "")))
			sample_ids.sort()
			var test_ids: Array = []
			for entry in Array(node.get("tests", [])):
				test_ids.append(str((entry as Dictionary).get("id", "")))
			test_ids.sort()
			parts.append("samples=%s" % ";".join(PackedStringArray(sample_ids)))
			parts.append("tests=%s" % ";".join(PackedStringArray(test_ids)))
			parts.append("hidden=%s" % str(node.get("answer", "")))
		"verb_decoder":
			# Le tessere vengono mescolate, ma il caso grammaticale resta lo stesso:
			# frase, tempo, modo e forma corretti ne definiscono l'identita'.
			parts.append("%s___%s" % [
				str(Array(node.get("segments", ["", ""]))[0]),
				str(Array(node.get("segments", ["", ""]))[1]),
			])
			var solution := node.get("solution", {}) as Dictionary
			parts.append("%s:%s:%s" % [
				str(solution.get("time", "")), str(solution.get("mood", "")),
				str(solution.get("form", "")),
			])
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
		"cycle":
			var stages: Array = []
			for entry in Array(node.get("stages", [])):
				var stage := entry as Dictionary
				stages.append("%s:%s" % [str(stage.get("id", "")), str(stage.get("glyph", ""))])
			stages.sort()
			parts.append(";".join(PackedStringArray(stages)))
			parts.append("→%s" % ";".join(PackedStringArray(_strings(node.get("correctOrder", [])))))
		"graph", "circuit", "hotspot", "notation", "map":
			var field := "points"
			if fmt == "circuit":
				field = "components"
			elif fmt == "hotspot":
				field = "targets" if str(node.get("assetId", "")) != "" else "hotspots"
			elif fmt == "notation":
				field = "symbols"
			elif fmt == "map":
				field = "targets"
			var ids: Array = []
			for entry in Array(node.get(field, [])):
				ids.append(str((entry as Dictionary).get("id", "")))
			ids.sort()
			parts.append(";".join(PackedStringArray(ids)))
			if fmt == "hotspot" and str(node.get("assetId", "")) != "":
				parts.append("atlas=%s" % str(node.get("assetId", "")))
			if fmt == "notation":
				parts.append("clef=%s" % str((node.get("staff", {}) as Dictionary).get("clef", "treble")))
				var notation_symbols: Array = []
				for entry in Array(node.get("symbols", [])):
					var symbol := entry as Dictionary
					notation_symbols.append("%s:%s:%d:%s:%s" % [
						str(symbol.get("id", "")), str(symbol.get("kind", "note")),
						int(symbol.get("staffStep", 0)), str(symbol.get("duration", "")),
						str(symbol.get("accidental", "")),
					])
				notation_symbols.sort()
				parts.append(";".join(PackedStringArray(notation_symbols)))
			elif fmt == "map":
				parts.append(str(node.get("mapId", "")))
				var map_targets: Array = []
				for entry in Array(node.get("targets", [])):
					map_targets.append(str((entry as Dictionary).get("id", "")))
				map_targets.sort()
				parts.append(";".join(PackedStringArray(map_targets)))
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
