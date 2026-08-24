extends SceneTree

## **Finiti i compiti dichiarati, il mondo successivo si apre.** (24 agosto 2026)
##
## Nasce da una segnalazione di gioco vera: «ho finito il mondo 1 con tutti i
## compiti assegnati e non passo al mondo 2».
##
## La segnalazione era vera, e il difetto non era l'ampiezza del gate. Era che
## **la lista dei compiti e la lista di quello che il gate chiede non erano la
## stessa lista**. Sulla mappa si vedono finire i sette eventi della materia del
## mondo e le undici palestre delle altre; ma finire una palestra non chiude la
## materia — ne serve un altro giro, e la successiva nasce altrove. Chi guardava
## la mappa la vedeva spenta e concludeva di aver finito.
##
## Questo audit tiene chiuso quel buco per sempre, e lo tiene chiuso dal lato
## giusto: non verifica che il gate sia facile, verifica che **il gioco dica
## quanto manca e che quel numero sia vero**. Cioè:
##
##   1. per ogni mondo e per ogni materia il gioco sa dire quante prove mancano
##      (`ObjectiveBriefing.prove_mancanti`), zero incluso;
##   2. facendo esattamente quelle prove — nient'altro, nessuna scorciatoia — il
##      gate del livello si apre;
##   3. il numero non mente per eccesso: non deve promettere lavoro che non
##      serve, o il quadro diventerebbe una minaccia invece di una guida.
##
## Il punto 2 è quello che `world_unlock_probe` non poteva vedere: quella sonda
## gioca solo le missioni del focus, ed è cieca sulle altre undici materie.

## Quante tornate di «fai quello che il quadro dice» si concedono prima di
## dichiarare bloccato un mondo. Il quadro ricalcola dopo ogni prova, quindi il
## conto scende: se dopo venti tornate non è sceso a zero, il numero non guida.
const TORNATE_MASSIME := 20

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _topic_stats(nodes: Array) -> Dictionary:
	var stats: Dictionary = {}
	for node in nodes:
		var topic := str(node.get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

## Una prova superata: la materia del mondo conta come missione, le altre come
## pratica. È esattamente la distinzione che fa il gioco.
func _prova(save, content, prog, subject: String, e_il_mondo: bool) -> void:
	var mission: Dictionary = content.build_mission(
		subject, save.level(), 3, SpacedRepetition.due_map(save),
		null, save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	if nodes.is_empty():
		return
	if e_il_mondo:
		prog.record_mission(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	else:
		prog.record_practice(subject, nodes.size(), nodes.size(), nodes.size() * 10)
	prog.record_topic_stats(subject, _topic_stats(nodes))

func _init() -> void:
	var peggior_mondo := 0
	var peggior_prove := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var save := GameSaveManager.new()
		save.set_level(livello)
		var content := ContentManager.new()
		var prog := ProgressionManager.new(save, content)
		var focus := ApparatusConfig.world_subject(livello)
		var prove := 0
		var tornate := 0
		var aperto := false
		while tornate < TORNATE_MASSIME:
			var percorso := ObjectiveBriefing.percorso(prog)
			if bool(percorso.get("pronto", false)):
				aperto = true
				break
			tornate += 1
			# Si fa **solo** quello che il quadro dichiara mancante, una prova per
			# materia a tornata: se il numero fosse una bugia, questo ciclo non
			# arriverebbe mai a zero.
			var stato: Dictionary = prog.readiness()
			var materie: Dictionary = stato.get("subjects", {})
			for chiave in materie.keys():
				var subject := str(chiave)
				if ObjectiveBriefing.prove_mancanti(Dictionary(materie[subject])) <= 0:
					continue
				_prova(save, content, prog, subject, subject == focus)
				prove += 1
			prog.aggiorna_traguardi_di_livello()
		_controlla(aperto,
			"mondo %d: seguendo i compiti dichiarati il livello non si apre" % livello)
		_controlla(prog.can_repair(),
			"mondo %d: i compiti dichiarati non aprono l'esame dell'apparato" % livello)
		if prove > peggior_prove:
			peggior_prove = prove
			peggior_mondo = livello
		# Il numero non deve promettere lavoro inutile: appena il quadro dice
		# zero su tutte, il gate deve essere davvero aperto — non «quasi».
		var finale := ObjectiveBriefing.percorso(prog)
		for riga_dati in Array(finale.get("righe", [])):
			var riga: Dictionary = riga_dati
			if bool(riga.get("fatto", false)):
				continue
			errori.append("mondo %d: il quadro dice pronto ma %s risulta ancora da fare" % [
				livello, str(riga.get("materia", ""))])

	if errori.is_empty():
		print("COMPITI DICHIARATI audit VERDE — 24 mondi si aprono seguendo il quadro")
		print("  il mondo pi\u00f9 caro \u00e8 il %d: %d prove" % [peggior_mondo, peggior_prove])
		quit(0)
		return
	print("COMPITI DICHIARATI audit ROSSO")
	for e in errori:
		print("  - %s" % str(e))
	assert(false, "i compiti dichiarati non bastano ad aprire il mondo successivo")
	quit(1)
