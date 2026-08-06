extends SceneTree

## Sonda: **quanto TEMPO costa uscire da un mondo**, non quanti esercizi.
##
## Contare gli esercizi è ingannevole, e la differenza non è piccola: una scelta
## multipla si risolve in dieci secondi, un abbinamento da sei coppie ne chiede
## quaranta, un round a scorrimento supera il minuto perché contiene dodici
## affermazioni dentro un nodo solo. Un mondo «da 113 esercizi» può durare il
## doppio di un altro con lo stesso numero.
##
## Qui si simula il percorso vero — missioni della materia del mondo, pratica
## (minigiochi) per le altre undici — e si pesa ogni nodo con una stima di durata
## per formato. Le stime sono dichiarate qui sopra e vanno tarate col collaudo:
## sono un ordine di grandezza, non un cronometro.

const DURATA := {
	"multiple_choice": 12.0,
	"numeric_input": 20.0,
	"short_answer": 22.0,
	"matching": 42.0,
	"ordering": 34.0,
	"classification": 38.0,
	"cycle": 34.0,
	"graph": 26.0,
	"circuit": 28.0,
	"notation": 24.0,
	"map": 26.0,
	"hotspot": 24.0,
	"code_debug": 30.0,
	"number_line": 20.0,
	"balance": 26.0,
	"timeline": 26.0,
	"compose": 24.0,
	"trace": 32.0,
	"clue": 40.0,
	"swipe": 55.0,   # un round intero: dodici affermazioni in un nodo solo
}

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

func _durata(nodes: Array) -> float:
	var t := 0.0
	for node in nodes:
		t += float(DURATA.get(str((node as Dictionary).get("format", "multiple_choice")), 15.0))
	return t

func _init() -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var prog := ProgressionManager.new(save, content)
	var rng := RandomNumberGenerator.new()

	print("Tempo per uscire da un mondo — percorso vero (missioni + pratica)\n")
	print("%-6s %-13s %9s %9s %10s" % ["MONDO", "MATERIA", "nodi", "minuti", "cumulato"])
	var minuti_tot := 0.0
	var costi: Array = []
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if save.level() != livello:
			break
		var focus := ApparatusConfig.world_subject(livello)
		var secondi := 0.0
		var nodi := 0
		var giri := 0
		while (not prog.can_repair() or not prog.can_level_up()) and giri < 200:
			# La materia del mondo: MISSIONE dal banco (conta per il gate).
			var mission: Dictionary = content.build_mission(
				focus, livello, 3, {}, null, save.mastery_of(focus), save.topic_masteries(focus))
			var mn: Array = mission.get("nodes", [])
			prog.record_mission(focus, mn.size(), mn.size(), 0)
			prog.record_topic_stats(focus, _topic_stats(mn))
			secondi += _durata(mn)
			nodi += mn.size()
			# Le altre: PRATICA (minigiochi), ma **solo quelle che mancano**.
			#
			# È il percorso di un bambino guidato: dal 6 agosto NORA nomina le
			# materie non ancora pronte, quindi non c'è motivo di allenare
			# quelle già a posto. Praticarle tutte a ogni giro — come faceva la
			# prima versione di questa sonda — sovrastima il costo e gonfia lo
			# squilibrio fra i mondi.
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
				secondi += _durata(pn)
				nodi += pn.size()
			giri += 1
		if giri >= 200:
			print("  (fermo al mondo %d)" % livello)
			break
		# L'esame.
		var esame := content.build_final_exam(focus, livello, 3)
		secondi += _durata(esame.get("nodes", []))
		nodi += Array(esame.get("nodes", [])).size()
		prog.repair_apparatus(focus, true)
		prog.advance_level()
		var minuti := secondi / 60.0
		minuti_tot += minuti
		costi.append(minuti)
		print("%-6d %-13s %9d %9.1f %10.1f" % [livello, focus, nodi, minuti, minuti_tot])

	if costi.is_empty():
		quit(1)
		return
	var minimo := 9999.0
	var massimo := 0.0
	for c in costi:
		minimo = minf(minimo, float(c))
		massimo = maxf(massimo, float(c))
	print("\nCampagna: %.1f ore · mondo più corto %.1f min · più lungo %.1f min · squilibrio %.1fx" % [
		minuti_tot / 60.0, minimo, massimo, massimo / maxf(minimo, 0.01)])
	quit(0)
