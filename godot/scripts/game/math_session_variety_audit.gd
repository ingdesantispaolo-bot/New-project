extends SceneTree

## Regressione del 3 agosto 2026: aggiungere un formato alla tavolozza ha spostato
## la sequenza casuale e rivelato sessioni matematiche con due nodi diversi ma la
## stessa coppia (formato, argomento). `format_mix_audit` difende i seed del
## percorso giocato; questo audit martella direttamente il generatore su tutti i
## livelli, con sessioni della lunghezza reale di missioni ed enigmi/esami.

const SEEDS_PER_LEVEL := 128
const NODE_COUNTS := [3, 4]

func _init() -> void:
	var failures: Array = []
	var sessions := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		for sample in range(SEEDS_PER_LEVEL):
			for node_count in NODE_COUNTS:
				var rng := RandomNumberGenerator.new()
				rng.seed = 730_000 + level * 10_000 + sample * 17 + int(node_count)
				var recent: Array = []
				var nodes := MathExerciseGenerator.new().build_nodes(
					level, int(node_count), rng, recent)
				sessions += 1
				var seen: Dictionary = {}
				for node_data in nodes:
					var node := node_data as Dictionary
					var key := "%s|%s" % [
						str(node.get("format", "")), str(node.get("topic", ""))]
					if seen.has(key):
						failures.append(
							"L%d seed %d (%d nodi): %s ripetuto" % [
								level, sample, int(node_count), key])
						break
					seen[key] = true

	if not failures.is_empty():
		printerr("VARIETÀ MATEMATICA FALLITA — %d sessioni con ripetizioni:" % failures.size())
		for failure in failures.slice(0, 20):
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Math session variety audit OK — %d sessioni, nessun (formato, argomento) ripetuto" % sessions)
	quit(0)
