extends SceneTree

## Audit C-07: beat NORA data-driven per i livelli 1→6, distinti, con reveal
## idempotente, accumulo di `seen` e clamp oltre il primo arco.

func _init() -> void:
	var save := GameSaveManager.new()
	var narrative := NarrativeManager.new()
	narrative.setup(save)

	# Ogni livello 1..6 ha un beat non vuoto, che inizia con "NORA:" ed è distinto.
	var texts := {}
	for level in range(1, 7):
		var beat := narrative.beat_for_level(level)
		assert(beat.begins_with("NORA:"), "beat %d deve iniziare con NORA:" % level)
		texts[beat] = true
	assert(texts.size() == 6, "i 6 beat devono essere distinti")

	# reveal idempotente e accumulo di 'seen'.
	var first := narrative.reveal_level(1)
	assert(bool(first["new"]))
	var again := narrative.reveal_level(1)
	assert(not bool(again["new"]))
	assert(str(again["text"]) == str(first["text"]))
	narrative.reveal_level(2)
	narrative.reveal_level(3)
	assert((save.data["narrative"]["seen"] as Array).size() == 3, "seen accumula i livelli rivelati")

	# Oltre il primo arco il beat è clampato al livello 6.
	assert(narrative.beat_for_level(12) == narrative.beat_for_level(6))

	print("C-07 audit OK — 6 beat NORA distinti, reveal idempotente, seen e clamp")
	quit(0)
