extends SceneTree

## **Nessun mondo può diventare un vicolo cieco.** (5 agosto 2026)
##
## Nasce da una segnalazione di gioco: «ho superato l'esame del primo mondo e non
## riesco ad accedere al secondo». Era vero, ed era riproducibile.
##
## ### Perché 116 audit non l'avevano visto
##
## `progression_1to24_audit` dichiara la campagna 1→24 percorribile, e non mente
## su quello che fa: a ogni livello gioca missioni della materia del mondo **e
## missioni delle tre materie del nucleo**. Solo che nel gioco vero un mondo
## offre missioni che contano per il gate soltanto per la propria materia
## (`mission_event_director`: `countsForGate: true` solo sul focus). Le altre
## materie ci sono, ma come **pratica**, e la pratica per contratto non tocca il
## gate.
##
## L'audit simulava quindi un giocatore che non può esistere. È lo stesso difetto
## che questa settimana ha nascosto un HUD morto e un export nella cartella
## sbagliata: **coerente con se stesso, scollegato dalla realtà**.
##
## ### Che cosa verifica questo audit
##
## Il caso peggiore *realistico*: un bambino che fa esattamente quello che il
## gioco gli indica — le missioni del mondo — e non cerca gli eventi di pratica,
## che il gioco stesso presenta come facoltativi. Dopo l'esame deve succedere
## almeno una cosa fra: sale di livello, **oppure** il gioco gli dice per nome
## che cosa manca e dove trovarlo. Restare fermi senza spiegazione è il vicolo
## cieco, e un gioco per bambini non può averne.

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

func _missione(save, content, prog, subject: String) -> void:
	var mission: Dictionary = content.build_mission(
		subject, save.level(), 3, SpacedRepetition.due_map(save),
		null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	prog.record_mission(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))

func _init() -> void:
	var failures: Array = []

	# --- 1. Il mondo 1 con un giocatore che segue solo le indicazioni ----------
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)
	var focus := ApparatusConfig.world_subject(1)
	var giri := 0
	while not prog.can_repair() and giri < 300:
		_missione(save, content, prog, focus)
		giri += 1

	if not prog.can_repair():
		failures.append("mondo 1: l'esame non si sblocca nemmeno dopo 300 missioni")
	var livello_prima := save.level()
	prog.repair_apparatus(focus, true)
	prog.advance_level()
	var salito := save.level() > livello_prima

	# Se non è salito — ed è legittimo, il nucleo è un gate voluto — il gioco
	# DEVE saper dire che cosa manca. Un elenco vuoto qui significa che il
	# bambino resta fermo senza sapere perché: è il vicolo cieco.
	if not salito:
		var stato: Dictionary = prog.readiness()
		var mancanti: Array = Array(stato.get("missing", []))
		if mancanti.is_empty():
			failures.append(
				"mondo 1: il livello non sale e il gioco non sa dire che cosa manca")
		for materia_data in mancanti:
			var dettaglio: Dictionary = Dictionary(stato.get("subjects", {})).get(str(materia_data), {})
			if Array(dettaglio.get("reasons", [])).is_empty():
				failures.append("mondo 1: «%s» manca senza un motivo leggibile" % str(materia_data))
		print("mondo 1: esame superato, livello fermo — mancano %s (atteso, ma va detto)" % str(mancanti))
	else:
		print("mondo 1: esame superato e livello salito")

	# --- 2. Nessun mondo è irraggiungibile una volta sbloccato -----------------
	# Il viaggio dipende solo da `worlds.unlocked`: se un livello sale senza
	# sbloccare il mondo corrispondente, la destinazione non compare nella carta
	# e il giocatore resta fermo con il livello giusto.
	var save2 := GameSaveManager.new()
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		save2.set_level(livello)
		save2.unlock_world(livello)
		if not save2.is_world_unlocked(livello):
			failures.append("mondo %d: sbloccato ma `is_world_unlocked` dice di no" % livello)

	# --- 3. Ogni mondo ha di che aprire il proprio apparato --------------------
	# Se la materia di un mondo non avesse abbastanza argomenti nel banco, il suo
	# esame non si sbloccherebbe mai e quel mondo sarebbe un vicolo cieco per
	# chiunque, non solo per chi salta la pratica.
	var cm := ContentManager.new()
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var materia := ApparatusConfig.world_subject(livello)
		var argomenti := cm.subject_topic_count(materia)
		var richiesti := GateReadiness.coverage_target(argomenti, livello)
		if argomenti < richiesti:
			failures.append("mondo %d (%s): %d argomenti nel banco, ne servono %d per la copertura" % [
				livello, materia, argomenti, richiesti])
		var esame := cm.build_final_exam(materia, livello, 3)
		if Array(esame.get("nodes", [])).is_empty():
			failures.append("mondo %d (%s): l'esame finale è vuoto" % [livello, materia])

	if failures.is_empty():
		print("\nNo dead end audit OK — nessun mondo blocca senza spiegazione")
		quit(0)
	else:
		print("\nVICOLO CIECO — %d problemi:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		quit(1)
