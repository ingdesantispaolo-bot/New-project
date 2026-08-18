extends SceneTree

## **Quanta potenza ha Eli quando incontra le sacche di quel mondo?**
##
## Serve a tarare le soglie di [[WorldLight]] con un numero invece che a occhio.
## La scala attuale è stata scritta quando i mondi non erano ancora ventiquattro
## e si ferma a 140 prove: bisogna sapere a che mondo un giocatore reale arriva a
## quel conto, e quanto forte è la minaccia in quel momento.
##
## Simula il percorso vero, come `time_cost_probe`: la missione della materia del
## mondo più la pratica delle materie che il gate dichiara mancanti, fino a
## superare il livello. Ogni sessione superata vale **una prova** — è la stessa
## unità che `WorldLight.avanza_potenza` conta nel gioco.
##
## Uso: godot --headless --path godot --script res://scripts/game/power_curve_probe.gd

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str((node as Dictionary).get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

## Il grado delle sacche di un mondo, com'è calcolato in `world_enemy.gd`.
func _tier_sacche(livello: int) -> int:
	return clampi(1 + floori(float(livello - 1) / 3.0), 1, 8)

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var prog := ProgressionManager.new(save, content)
	var rng := RandomNumberGenerator.new()

	print("Potenza contro minaccia, mondo per mondo\n")
	print("%-6s %-13s %7s %9s %7s %7s %8s" % [
		"MONDO", "MATERIA", "prove", "cumulate", "grado", "sacche", "scarto"])
	var prove_totali := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if save.level() != livello:
			break
		var focus := ApparatusConfig.world_subject(livello)
		var prove := 0
		var giri := 0
		while (not prog.can_repair() or not prog.can_level_up()) and giri < 200:
			var mission: Dictionary = content.build_mission(
				focus, livello, 3, {}, null, save.mastery_of(focus), save.topic_masteries(focus))
			var mn: Array = mission.get("nodes", [])
			prog.record_mission(focus, mn.size(), mn.size(), 0)
			prog.record_topic_stats(focus, _topic_stats(mn))
			prove += 1
			var stato: Dictionary = prog.readiness()
			var mancanti: Array = Array(stato.get("missing", []))
			for subject_data in ApparatusConfig.SUBJECT_CYCLE:
				var s := str(subject_data)
				if s == focus or not mancanti.has(s):
					continue
				rng.seed = giri * 977 + livello * 13 + s.hash()
				var pratica: Dictionary = mg.build_minigame(s, livello, rng)
				var pn: Array = pratica.get("nodes", [])
				prog.record_practice(s, pn.size(), pn.size(), 0)
				prog.record_topic_stats(s, _topic_stats(pn))
				prove += 1
			giri += 1
		if giri >= 200:
			print("  (fermo al mondo %d)" % livello)
			break
		prove += 1   # l'esame
		prog.repair_apparatus(focus, true)
		prog.advance_level()
		prove_totali += prove
		# Il grado si legge con la scala vigente, applicata al conto simulato.
		var finto := GameSaveManager.new()
		finto.data["powerRuns"] = prove_totali
		var grado := WorldLight.grado(finto)
		var tier := _tier_sacche(livello)
		print("%-6d %-13s %7d %9d %7d %7d %8d" % [
			livello, focus, prove, prove_totali, grado, tier, grado - tier])
	print("\nProve in tutta la campagna: %d" % prove_totali)
	print("Soglie vigenti: %s" % str(WorldLight.SOGLIE.map(func(v): return int(Dictionary(v)["prove"]))))
	quit(0)
