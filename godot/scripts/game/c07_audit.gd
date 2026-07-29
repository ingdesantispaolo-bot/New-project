extends SceneTree

## Audit C-07: beat NORA data-driven per i livelli 1→24, distinti, con reveal
## idempotente, accumulo di `seen` e finale stabile oltre la campagna.

func _init() -> void:
	var save := GameSaveManager.new()
	var narrative := NarrativeManager.new()
	narrative.setup(save)

	# Ogni livello 1..24 ha un beat non vuoto, che inizia con "NORA:" ed è distinto.
	var texts := {}
	for level in range(1, 25):
		var beat := narrative.beat_for_level(level)
		assert(beat.begins_with("NORA:"), "beat %d deve iniziare con NORA:" % level)
		texts[beat] = true
	assert(texts.size() == 24, "i 24 beat devono essere distinti")

	# reveal idempotente e accumulo di 'seen'.
	var first := narrative.reveal_level(1)
	assert(bool(first["new"]))
	var again := narrative.reveal_level(1)
	assert(not bool(again["new"]))
	assert(str(again["text"]) == str(first["text"]))
	narrative.reveal_level(2)
	narrative.reveal_level(3)
	assert((save.data["narrative"]["seen"] as Array).size() == 3, "seen accumula i livelli rivelati")

	# Oltre la campagna resta un finale stabile, distinto dal mondo 24.
	assert(narrative.beat_for_level(25) == narrative.beat_for_level(40))
	assert(narrative.beat_for_level(25) != narrative.beat_for_level(24))

	print("C-07 audit OK — 24 beat NORA distinti, reveal idempotente, seen e finale")
	quit(0)
