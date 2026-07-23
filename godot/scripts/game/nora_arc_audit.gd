extends SceneTree

const NoraState = preload("res://scripts/game/nora_state.gd")

## Audit O-P4 (arco NORA): 24 beat narrativi DISTINTI (uno nuovo per livello), la
## fiducia guidata dall'APPRENDIMENTO (non dalla sola correttezza) e integrità/
## memoria allineate al progresso della nave.
## Uso: godot --headless --path godot --script res://scripts/game/nora_arc_audit.gd

func _init() -> void:
	var save := GameSaveManager.new()
	var nm := NarrativeManager.new()
	nm.setup(save)

	# 1) 24 beat distinti e non vuoti (ogni livello ha un beat nuovo).
	var seen: Dictionary = {}
	for lvl in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var text := nm.beat_for_level(lvl)
		assert(text.strip_edges() != "", "beat vuoto al livello %d" % lvl)
		assert(not seen.has(text), "beat duplicato al livello %d" % lvl)
		seen[text] = true
	assert(seen.size() == 24, "servono 24 beat distinti, trovati %d" % seen.size())
	assert(bool(nm.reveal_level(3).get("new", false)), "un livello mai visto deve risultare nuovo")

	# 2) Guardrail fiducia: la sola risposta giusta NON muove la fiducia; sforzo,
	# crescita, aiuto e trasferimento sì.
	var t0 := NoraState.trust(save)
	NoraState.register(save, "correct")
	assert(NoraState.trust(save) == t0, "la sola correttezza non deve alzare la fiducia")
	NoraState.register(save, "perseverance")
	NoraState.register(save, "improvement")
	NoraState.register(save, "transfer")
	NoraState.register(save, "help_request")
	assert(NoraState.trust(save) > t0, "perseveranza/miglioramento/trasferimento/aiuto devono alzare la fiducia")
	# L'errore ricorrente non abbassa la fiducia (NORA sostiene, non giudica).
	var t1 := NoraState.trust(save)
	NoraState.register(save, "recurring_error")
	assert(NoraState.trust(save) >= t1, "l'errore ricorrente non deve abbassare la fiducia")
	# Ogni segnale-chiave ha una reazione di NORA.
	for sig in ["recurring_error", "help_request", "perseverance", "improvement", "transfer"]:
		assert(NoraState.reaction(sig) != "", "manca la reazione di NORA per: %s" % sig)

	# 3) Integrità e memoria seguono il progresso della nave (apparati riparati).
	assert(NoraState.memory(save) == 0 and NoraState.integrity(save) == 0.0)
	save.set_apparatus_repaired("nucleo", 1)
	save.set_apparatus_repaired("data-core", 2)
	NoraState.sync_from_progress(save)
	assert(NoraState.memory(save) == 2, "la memoria deve contare i ricordi/apparati recuperati")
	assert(NoraState.integrity(save) > 0.0 and NoraState.integrity(save) <= 1.0, "l'integrità deve crescere col progresso")

	print("NORA arc audit OK — 24 beat distinti, fiducia guidata dall'apprendimento, integrità/memoria dal progresso")
	quit(0)
