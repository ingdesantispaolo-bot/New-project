extends SceneTree

## **Che cosa vede davvero uno studente al primo livello di una materia?**
##
## Nasce da una segnalazione di gioco del 14 agosto 2026: «gli esercizi di
## matematica del primo livello sono troppo semplici». Prima di crederci o di
## smentirla si guarda che cosa il gioco consegna davvero — non che cosa contiene
## il banco, che è un'altra domanda.
##
## Misura tre cose, separate perché arrivano da tre strade diverse:
##
##   MISSIONI   `build_varied_mission`, la strada del gate (banco + catalogo)
##   PRATICA    `build_minigame`, gli eventi di pratica sparsi nel mondo
##   BANCO      la composizione grezza, per capire da dove viene ciò che esce
##
## Uso: `node scripts/run-godot-audits.mjs` non lo esegue (non è un `_audit`).
##   godot --headless --path godot --script res://scripts/game/first_level_probe.gd

const MATERIE := ["matematica"]
const LIVELLI := [1]
const CAMPIONI := 40
## Le tre condizioni che contano: la prima sessione in assoluto (padronanza mai
## impostata), quella dopo una sessione perfetta (0,85 = soglia del nudge) e
## quella di chi sta a metà.
const PADRONANZE := [0.0, 0.6, 0.85]

func _init() -> void:
	for materia_data in MATERIE:
		var materia := str(materia_data)
		_banco(materia)
		for livello_data in LIVELLI:
			_consegnato(materia, int(livello_data))
	quit(0)

func _banco(materia: String) -> void:
	var cm := ContentManager.new()
	var items := cm._load_bank(materia)
	var per_difficolta: Dictionary = {}
	var argomenti_per_difficolta: Dictionary = {}
	for voce in items:
		var item: Dictionary = voce
		var d := int(item.get("difficulty", 1))
		per_difficolta[d] = int(per_difficolta.get(d, 0)) + 1
		if not argomenti_per_difficolta.has(d):
			argomenti_per_difficolta[d] = {}
		argomenti_per_difficolta[d][str(item.get("topic", "?"))] = true
	print("\n=== BANCO %s — %d voci ===" % [materia.to_upper(), items.size()])
	for d in [1, 2, 3, 4]:
		var quanti := int(per_difficolta.get(d, 0))
		var argomenti: Array = Dictionary(argomenti_per_difficolta.get(d, {})).keys()
		argomenti.sort()
		print("  difficoltà %d: %3d voci · %d argomenti %s" % [
			d, quanti, argomenti.size(), str(argomenti)])

func _consegnato(materia: String, livello: int) -> void:
	for padronanza_data in PADRONANZE:
		_con_padronanza(materia, livello, float(padronanza_data))

func _con_padronanza(materia: String, livello: int, mastery: float) -> void:
	var cm := ContentManager.new()
	print("\n=== CONSEGNATO · %s livello %d · padronanza %.2f ===" % [
		materia.to_upper(), livello, mastery])
	print("  difficoltà bersaglio %d → effettiva %d · livello matematico %d" % [
		ContentManager.target_difficulty(livello),
		cm.effective_difficulty(materia, livello, mastery),
		ContentManager.math_effective_level(livello, mastery)])

	for strada in ["missione", "pratica"]:
		var per_topic: Dictionary = {}
		var per_difficolta: Dictionary = {}
		var per_formato: Dictionary = {}
		var esempi: Array = []
		var totale := 0
		for giro in range(CAMPIONI):
			var sessione: Dictionary = (
				cm.build_varied_mission(materia, livello, 3, {}, null, mastery, {})
				if strada == "missione"
				else MinigameManager.new().build_minigame(materia, livello))
			for nodo_data in Array(sessione.get("nodes", [])):
				var nodo: Dictionary = nodo_data
				totale += 1
				var topic := str(nodo.get("topic", "?"))
				per_topic[topic] = int(per_topic.get(topic, 0)) + 1
				var d := int(nodo.get("difficulty", 0))
				per_difficolta[d] = int(per_difficolta.get(d, 0)) + 1
				var fmt := str(nodo.get("format", "multiple_choice"))
				per_formato[fmt] = int(per_formato.get(fmt, 0)) + 1
				var prompt := str(nodo.get("prompt", "")).strip_edges()
				if esempi.size() < 12 and not esempi.has(prompt):
					esempi.append(prompt)
		print("  -- %s: %d nodi su %d sessioni" % [strada.to_upper(), totale, CAMPIONI])
		var chiavi_topic: Array = per_topic.keys()
		chiavi_topic.sort_custom(func(a, b): return int(per_topic[a]) > int(per_topic[b]))
		for k in chiavi_topic:
			print("       %-26s %4d  (%4.1f%%)" % [
				str(k), int(per_topic[k]), 100.0 * float(per_topic[k]) / float(maxi(1, totale))])
		print("       difficoltà: %s" % str(per_difficolta))
		print("       formati:    %s" % str(per_formato))
		for e in esempi:
			print("       · %s" % e)
