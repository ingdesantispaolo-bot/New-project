extends SceneTree

const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")

## Audit O-P4 (Manuale): il KnowledgeCodex copre OGNI argomento del runtime con una
## voce completa, la consultazione in esame non rivela la risposta, e lo stato di
## conoscenza avanza (senza regredire) sconosciuto → consolidato.
## Uso: godot --headless --path godot --script res://scripts/game/knowledge_codex_audit.gd

func _init() -> void:
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)

	# 1) Copertura: ogni topic del runtime ha una voce non vuota.
	var cov := codex.coverage()
	assert(bool(cov["ok"]), "argomenti senza voce di manuale: %s" % str(cov["missing"]))

	var topics := codex.runtime_topics()
	var count := 0
	for key in topics.keys():
		var meta: Dictionary = topics[key]
		var e := codex.entry_for(str(meta["subject"]), str(meta["topic"]))
		assert(str(e.get("shortExplanation", "")).strip_edges() != "", "spiegazione vuota: %s" % key)
		assert(str(e.get("noraStrategy", "")).strip_edges() != "", "strategia NORA vuota: %s" % key)
		assert(e.has("example") and e.has("typicalError"), "voce incompleta: %s" % key)
		count += 1
	assert(count >= 100, "il manuale deve coprire i ~120 topic del runtime, trovati %d" % count)

	# 2) Consultazione: in esame il manuale non rivela la risposta del nodo.
	assert(not KnowledgeCodex.can_reveal_answer("final_exam"), "in esame la risposta resta nascosta")
	assert(KnowledgeCodex.can_reveal_answer("mission"), "in missione il manuale è pieno")
	var exam_entry := codex.entry_for_context("italiano", "scuola-studio", "final_exam")
	assert(str(exam_entry.get("example", {}).get("answer", "")) == "", "l'esame non deve mostrare la risposta d'esempio")
	assert(bool(exam_entry.get("answerHidden", false)), "la voce d'esame deve segnalare la risposta nascosta")

	# 3) Stato di conoscenza: avanza e non regredisce.
	var save := GameSaveManager.new()
	assert(KnowledgeCodex.state_of(save, "matematica", "tabelline") == KnowledgeCodex.STATE_UNKNOWN)
	KnowledgeCodex.advance_state(save, "matematica", "tabelline", "seen")
	assert(KnowledgeCodex.state_of(save, "matematica", "tabelline") == KnowledgeCodex.STATE_ENCOUNTERED)
	KnowledgeCodex.advance_state(save, "matematica", "tabelline", "correct")
	assert(KnowledgeCodex.state_of(save, "matematica", "tabelline") == KnowledgeCodex.STATE_APPLIED)
	KnowledgeCodex.advance_state(save, "matematica", "tabelline", "consolidated")
	assert(KnowledgeCodex.state_of(save, "matematica", "tabelline") == KnowledgeCodex.STATE_CONSOLIDATED)
	KnowledgeCodex.advance_state(save, "matematica", "tabelline", "seen")  # non deve regredire
	assert(KnowledgeCodex.state_of(save, "matematica", "tabelline") == KnowledgeCodex.STATE_CONSOLIDATED)

	print("Knowledge codex audit OK — %d voci, copertura completa, consultazione in esame protetta, stati monotoni" % count)
	quit(0)
