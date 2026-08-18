extends SceneTree

## **Quanta energia produce una campagna, e quanto costa il catalogo?**
##
## Serve a G-5 e sblocca G-4: il catalogo della bottega costa 72.600 energia su 55
## voci, e nessuno ha mai misurato quanta energia una campagna intera ne produca.
## Aggiungere un secondo rubinetto — i moduli di spedizione — a un'economia mai
## misurata sarebbe indovinare due volte.
##
## Simula il percorso vero come `power_curve_probe`, e per ogni sessione calcola
## l'energia **con le stesse regole del gioco**: la tariffa dichiarata dalla
## sessione, moltiplicata dalla serie ([[Combo]]), più il premio di completamento,
## meno il costo d'ingresso.
##
## Due scenari, perché la differenza è enorme e nessuno dei due è «quello vero»:
## il bambino che non sbaglia mai e quello che ne sbaglia una su cinque. La serie
## amplifica la distanza: chi non sbaglia la porta al tetto, chi sbaglia la
## ricomincia da uno.
##
## Uso: godot --headless --path godot --script res://scripts/game/economy_probe.gd

const COSTO_INGRESSO := 3          # OutdoorGameplay.EXERCISE_ENERGY_COST
const CATALOGO := 72600            # somma dei costi in RewardCatalog

## Durata stimata per formato, in secondi. **Rispecchia `time_cost_probe.DURATA`**
## e va tenuta allineata a mano: sono due sonde, non due verità. Serve qui perché
## la domanda di G-5 non è quanta energia rende un mondo, ma quanta ne rende **al
## minuto** — se un mondo facile paga più in fretta di uno difficile, tornare
## indietro diventa il modo più veloce di fare energia, e l'energia smette di
## misurare quello che si è imparato.
const DURATA := {
	"multiple_choice": 12.0, "numeric_input": 20.0, "short_answer": 22.0,
	"matching": 42.0, "ordering": 34.0, "classification": 38.0, "cycle": 34.0,
	"graph": 26.0, "circuit": 28.0, "notation": 24.0, "map": 26.0,
	"hotspot": 24.0, "code_debug": 30.0, "number_line": 20.0, "balance": 26.0,
	"timeline": 26.0, "compose": 24.0, "trace": 32.0, "clue": 40.0, "swipe": 55.0,
}

static func _durata(nodes: Array) -> float:
	var t := 0.0
	for node in nodes:
		t += float(DURATA.get(str((node as Dictionary).get("format", "multiple_choice")), 15.0))
	return t

## Ogni quante risposte ne sbaglia una, per scenario. 0 = non sbaglia mai.
const SCENARI := [
	{"nome": "senza errori", "ogni": 0},
	{"nome": "una su cinque", "ogni": 5},
]

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str((node as Dictionary).get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

## L'energia di una sessione, con le regole vere: tariffa per nodo moltiplicata
## dalla serie, premio di completamento se superata, meno l'ingresso.
## `ogni` = ogni quante risposte se ne sbaglia una (0 = mai).
func _energia_sessione(session: Dictionary, ogni: int, contatore: Array) -> int:
	var nodi: Array = session.get("nodes", [])
	var premi: Dictionary = session.get("rewards", {})
	var base := int(premi.get("energyPerCorrect", 10))
	var guadagno := 0
	var serie := 0
	var giuste := 0
	for _n in nodi:
		contatore[0] += 1
		var sbagliata: bool = ogni > 0 and int(contatore[0]) % ogni == 0
		if sbagliata:
			serie = 0
			continue
		serie += 1
		giuste += 1
		guadagno += Combo.energia(base, serie)
	# Superata se non si è esaurito nessuno scudo oltre il consentito: qui basta
	# la soglia di metà nodi, che è il criterio del player per le missioni.
	if giuste >= int(ceil(float(nodi.size()) * 0.5)):
		guadagno += int(Dictionary(premi.get("onComplete", {})).get("energy", 0))
	return guadagno - COSTO_INGRESSO

func _init() -> void:
	print("Economia della campagna — entrate contro catalogo\n")
	print("Catalogo bottega: %d energia su 55 voci\n" % CATALOGO)
	print("%-16s %10s %10s %10s %9s" % [
		"SCENARIO", "sessioni", "lorde", "nette", "% catalogo"])
	for scenario_data in SCENARI:
		var scenario: Dictionary = scenario_data
		_simula(str(scenario["nome"]), int(scenario["ogni"]))
	quit(0)

func _simula(nome: String, ogni: int) -> void:
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var prog := ProgressionManager.new(save, content)
	var rng := RandomNumberGenerator.new()
	var contatore := [0]
	var lorde := 0
	var sessioni := 0
	var per_mondo: Array = []
	var secondi_per_mondo: Array = []

	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if save.level() != livello:
			break
		var focus := ApparatusConfig.world_subject(livello)
		var mondo := 0
		var secondi := 0.0
		var giri := 0
		while (not prog.can_repair() or not prog.can_level_up()) and giri < 200:
			var mission: Dictionary = content.build_mission(
				focus, livello, 3, {}, null, save.mastery_of(focus), save.topic_masteries(focus))
			var mn: Array = mission.get("nodes", [])
			mondo += _energia_sessione(mission, ogni, contatore)
			secondi += _durata(mn)
			sessioni += 1
			prog.record_mission(focus, mn.size(), mn.size(), 0)
			prog.record_topic_stats(focus, _topic_stats(mn))
			var stato: Dictionary = prog.readiness()
			var mancanti: Array = Array(stato.get("missing", []))
			for subject_data in ApparatusConfig.SUBJECT_CYCLE:
				var s := str(subject_data)
				if s == focus or not mancanti.has(s):
					continue
				rng.seed = giri * 977 + livello * 13 + s.hash()
				var pratica: Dictionary = mg.build_minigame(s, livello, rng)
				var pn: Array = pratica.get("nodes", [])
				mondo += _energia_sessione(pratica, ogni, contatore)
				secondi += _durata(pn)
				sessioni += 1
				prog.record_practice(s, pn.size(), pn.size(), 0)
				prog.record_topic_stats(s, _topic_stats(pn))
			giri += 1
		if giri >= 200:
			break
		var esame := content.build_final_exam(focus, livello, 3)
		mondo += _energia_sessione(esame, ogni, contatore)
		secondi += _durata(esame.get("nodes", []))
		sessioni += 1
		prog.repair_apparatus(focus, true)
		prog.advance_level()
		lorde += mondo
		per_mondo.append(mondo)
		secondi_per_mondo.append(secondi)

	var nette := lorde
	print("%-16s %10d %10d %10d %8.0f%%" % [
		nome, sessioni, lorde + sessioni * COSTO_INGRESSO, nette,
		100.0 * float(nette) / float(CATALOGO)])
	if not per_mondo.is_empty():
		print("      mondo   energia   minuti   en./min")
		var per_minuto: Array = []
		for i in range(per_mondo.size()):
			var min_mondo: float = maxf(0.01, float(secondi_per_mondo[i]) / 60.0)
			var ritmo: float = float(per_mondo[i]) / min_mondo
			per_minuto.append(ritmo)
			print("      %5d   %7d   %6.1f   %7.1f" % [
				i + 1, int(per_mondo[i]), min_mondo, ritmo])
		var lento := 9999.0
		var veloce := 0.0
		for r in per_minuto:
			lento = minf(lento, float(r))
			veloce = maxf(veloce, float(r))
		print("      ritmo più lento %.1f en./min · più veloce %.1f · squilibrio %.2fx
" % [
			lento, veloce, veloce / maxf(lento, 0.01)])
