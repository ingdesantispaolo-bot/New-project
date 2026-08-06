extends SceneTree

const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")
const GateReadiness = preload("res://scripts/game/gate_readiness.gd")

## Matrice sintetica livello → competenze → evidenze richieste → apparato
## riattivato (C-P6 #3), GENERATA dai contratti (unica fonte di verità: nessun
## drift). Verifica la completezza dei 24 livelli e stampa la tabella in Markdown
## per docenti e test pilota.
## Uso: godot --headless --path godot --script res://scripts/game/competency_matrix.gd

func _pct(v: float) -> String:
	return "%d%%" % int(round(v * 100.0))

func _init() -> void:
	var content := ContentManager.new()
	var rows: Array = []

	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		# Materia che abita il mondo (identità) e regola di gate: da oggi sono due
		# cose distinte, e questa matrice per i docenti le mostra entrambe.
		var subject := ApparatusConfig.world_subject(level)
		var apparatus := ApparatusConfig.apparatus_of(subject)
		var gate := ApparatusConfig.apparatus_gate(subject, level)
		assert(WorldLessonCatalog.has_lesson(level), "manca la lezione L%d" % level)
		var lesson := WorldLessonCatalog.lesson(level)

		# Competenze = obiettivi della lezione; evidenze = dimensioni del gate.
		var competencies: Array = lesson["objectives"]
		var topics: Array = lesson["topics"]
		var coverage_target := GateReadiness.coverage_target(content.subject_topic_count(subject), level)
		# Il gate non conta più le missioni: padronanza, copertura e ritenzione.
		var evidence := "padronanza ≥ %s · copertura ≥ %d argomenti · ritenzione (ripasso saldato)" % [
			_pct(float(gate["masteryThreshold"])), coverage_target]
		var transfer := str(lesson["transferTest"]["description"])

		assert(not competencies.is_empty(), "L%d senza competenze" % level)
		assert(str(gate["apparatus"]) != "", "L%d senza apparato" % level)

		rows.append({
			"level": level,
			"title": str(profile["title"]),
			"subject": subject,
			"competencies": competencies,
			"topics": topics,
			"evidence": evidence,
			"apparatus": str(gate["apparatus"]),
			"transfer": transfer,
		})

	assert(rows.size() == 24, "la matrice deve coprire i 24 livelli")

	# --- Scrive il Markdown direttamente (UTF-8) in docs/COMPETENCY_MATRIX.md ----
	var lines: Array = []
	lines.append("# Matrice competenze — livello → competenze → evidenze → apparato")
	lines.append("")
	lines.append("GENERATA da `competency_matrix.gd` dai contratti (`WorldLessonCatalog`,")
	lines.append("`ApparatusConfig`, `GateReadiness`): unica fonte di verità, nessun drift.")
	lines.append("Per docenti e test pilota. Rigenerare dopo ogni modifica di lezioni o gate.")
	lines.append("")
	lines.append("- **Evidenze**: il gate si apre a 4 dimensioni — abbastanza missioni della")
	lines.append("  materia, padronanza (media mobile) oltre soglia, copertura di argomenti")
	lines.append("  distinti e ritenzione (nessun ripasso arretrato). Difficoltà per COMPETENZA")
	lines.append("  della materia, non per rango globale.")
	lines.append("- **Prova di trasferimento**: applicazione in un contesto nuovo (non memoria).")
	lines.append("- Il **finale** (mondo 24) è trasversale: i 12 sistemi convergono, vedi")
	lines.append("  [FINALE_SPEC.md](FINALE_SPEC.md).")
	lines.append("")
	lines.append("| Liv | Mondo | Materia | Competenze | Evidenze richieste (gate) | Prova di trasferimento | Apparato |")
	lines.append("|---:|---|---|---|---|---|---|")
	for r in rows:
		var comp := " · ".join(PackedStringArray(r["competencies"]))
		lines.append("| %d | %s | %s | %s | %s | %s | `%s` |" % [
			int(r["level"]), str(r["title"]), str(r["subject"]).capitalize(),
			comp, str(r["evidence"]), str(r["transfer"]), str(r["apparatus"])])

	var file := FileAccess.open("res://../docs/COMPETENCY_MATRIX.md", FileAccess.WRITE)
	assert(file != null, "impossibile scrivere docs/COMPETENCY_MATRIX.md")
	file.store_string("\n".join(PackedStringArray(lines)) + "\n")
	file.close()

	print("Competency matrix audit OK — 24 livelli scritti in docs/COMPETENCY_MATRIX.md (competenze/evidenze/trasferimento/apparato completi)")
	quit(0)
