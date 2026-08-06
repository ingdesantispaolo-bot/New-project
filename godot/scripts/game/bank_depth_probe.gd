extends SceneTree

## Sonda: **quanti esercizi DISTINTI può vedere un bambino** in una materia a un
## dato livello?
##
## Non quanti ne contiene il banco: quanti ne fa uscire la selezione a quel
## livello, che è un'altra cosa — difficoltà e `ERA_GATED_TOPICS` filtrano.
##
## Serve dopo il cambio di gate del 6 agosto 2026: ora il livello si apre solo
## padroneggiando tutte e dodici le materie, quindi ogni livello chiede lavoro in
## ogni materia. Se un banco è sottile lì, il bambino rivede gli stessi esercizi
## e il gate misura memoria di schermata invece di competenza.

const CAMPIONI := 260

func _init() -> void:
	var content := ContentManager.new()
	print("Esercizi distinti raggiungibili per materia e livello")
	print("(%d estrazioni per casella — il numero satura sul pool reale)\n" % CAMPIONI)

	var livelli := [1, 4, 8, 12, 16, 20, 24]
	var intestazione := "%-13s" % "MATERIA"
	for l in livelli:
		intestazione += "%7s" % ("L%d" % l)
	intestazione += "%9s" % "minimo"
	print(intestazione)

	var peggiori: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var riga := "%-13s" % subject
		var minimo := 99999
		for livello in livelli:
			var visti: Dictionary = {}
			for seme in range(CAMPIONI):
				var rng := RandomNumberGenerator.new()
				rng.seed = seme * 7919 + livello * 31
				for node in Array(content.build_mission(subject, livello, 3, {}, rng).get("nodes", [])):
					visti[str((node as Dictionary).get("id", ""))] = true
			riga += "%7d" % visti.size()
			if visti.size() < minimo:
				minimo = visti.size()
			# Soglia di guardia: sotto trenta esercizi distinti, un livello che
			# ne chiede un centinaio ripropone tutto tre volte.
			if visti.size() < 30:
				peggiori.append("%s L%d: %d" % [subject, livello, visti.size()])
		riga += "%9d" % minimo
		print(riga)

	print("")
	if peggiori.is_empty():
		print("Nessuna casella sotto i 30 esercizi distinti.")
	else:
		print("CASELLE SOTTILI (< 30 distinti): %d" % peggiori.size())
		for p in peggiori:
			print("  - %s" % p)
	quit(0)
