extends SceneTree

## **Quanto costa arrivare al mondo 2 a chi sbaglia qualche volta?**
##
## Segnalazione di gioco del 26 agosto 2026: «ho completato tutto il mondo 1 e non
## riesco ad accedere al mondo 2». Era la seconda volta — la prima, il 24 agosto,
## aveva trovato la copertura e l'aveva resa visibile sui cartelli delle palestre.
##
## La causa nuova era un'altra, e nessuna sonda poteva vederla: **`compiti_bastano`
## e `progression_1to24` giocano sempre rispondendo giusto.** Un bambino che
## risponde giusto sempre non esiste, e il gate era tarato su di lui.
##
## Misurato con questo audit, mediana su cinque semi (fra parentesi il caso
## peggiore), prima e dopo la correzione del 26 agosto:
##
##   accuratezza        prima                dopo
##   100%               16                   16      il mondo offre ~17 prove
##    85%               29  (fino a 36)      20  (25)
##    70%               tre semi su sette    35  (46)
##                      non aprivano MAI
##                      il gate
##
## Quattro cause distinte, tutte e quattro corrette. Nessuna era l'ampiezza del
## gate, che resta a dodici materie come deciso il 5 agosto.
##
## **La padronanza si misurava su tre nodi.** `_padronanza_aggiornata` era una
## media mobile fra sessioni, e una sessione sono TRE nodi: un campione cosi'
## piccolo e' quasi tutto rumore. Ogni materia riceve una sessione ogni dodici,
## quindi la stima si muoveva di un passo per giro di gioco e una sessione
## sfortunata al primo incontro costava cinque giri per essere riassorbita.
##
## **Il ripasso chiedeva la coda vuota.** La dimensione RITENZIONE pretendeva
## `subject_overdue_count == 0`, cioe' nessun ripasso in calendario nell'istante
## del controllo. Ma ogni sessione ne genera di nuovi e una voce esce dal
## calendario solo dopo quattro ripassi riusciti di fila: il conto saliva a sei e
## non scendeva piu'. Adesso conta cio' che e' stato sbagliato e **non ancora
## ripreso**, che e' quello che la dimensione dichiara di misurare — e l'errore
## appena commesso ha una sessione di tempo prima di contare.
##
## **Un argomento di matematica poteva non tornare mai.** La matematica non nasce
## dal banco come le altre undici materie: nasce dal generatore, e gli argomenti
## scritti a mano entrano da `_innesta_banco_matematica`, dove il calendario dei
## ripassi non arrivava. `matematica:statistica` sbagliata una volta restava
## sbagliata per sempre — sulla materia che ABITA il mondo 1, quindi addosso a
## chiunque.
##
## **La soglia del nucleo rendeva il mondo 1 impossibile, non difficile.** La
## padronanza stimata di un bambino al 70% si assesta intorno a 0,767: sopra la
## soglia base (0,70) e sotto quella del nucleo (0,78). Il bonus del nucleo ora
## cresce con la scala invece di essere pieno dal primo mondo. Vedi
## `ApparatusConfig.core_bonus`.
##
## ### Come si legge il tetto
##
## Stessa forma del debito delle scorciatoie: **il tetto si abbassa e mai si
## alza.** Se una modifica ai banchi o alla progressione fa salire il costo, questo
## audit diventa rosso — ed è l'unico modo di accorgersene senza un collaudo.
##
## ### Il bambino simulato è INFORMATO
##
## Dal secondo giro non fa il giro completo delle dodici materie: va su quelle che
## il quadro degli obiettivi dichiara mancanti. È quello che il gioco gli dice di
## fare, e misurare il giro alla cieca misurerebbe un giocatore che il gioco non
## chiede. Se un giorno l'istruzione sparisse dall'interfaccia, questo audit
## resterebbe verde a torto: la guardia dell'istruzione è `objective_clarity`.
##
## Uso: node scripts/run-godot-audits.mjs gate_mondo1

## Sessioni massime perché il gate del livello 1 si apra, per accuratezza.
## SI ABBASSA E MAI SI ALZA.
const TETTO := {
	100: 18,
	85: 24,
	70: 40,
}

const SEMI := [20260826, 7, 99, 1234, 555, 31, 4242]
const GIRI_MASSIMI := 60

## Due generatori, e vanno tenuti separati e SEMINATI TUTTI E DUE.
##
## `rng` decide se il bambino azzecca la risposta; `pesca` decide quali item la
## sessione gli mette davanti. Il secondo esisteva gia' ma non veniva passato:
## `build_mission(..., null, ...)` si costruisce un generatore e lo `randomize()`.
## L'audit misurava quindi una partita diversa a ogni esecuzione — e un tetto
## misurato su una partita diversa ogni volta non e' un tetto. Trovato facendo
## girare due volte di fila la stessa identica revisione e leggendo due numeri.
var rng := RandomNumberGenerator.new()
var pesca := RandomNumberGenerator.new()

func _stats(nodes: Array, giuste: Array) -> Dictionary:
	var stats: Dictionary = {}
	for i in nodes.size():
		var topic := str(Dictionary(nodes[i]).get("topic", "generico"))
		var e: Dictionary = stats.get(topic, {"seen": 0, "correct": 0})
		e["seen"] = int(e["seen"]) + 1
		if bool(giuste[i]):
			e["correct"] = int(e["correct"]) + 1
		stats[topic] = e
	return stats

## Una sessione con la stessa catena di `outdoor_gameplay._on_session_finished`:
## record → topic stats → ripasso spaziato → orologio → traguardi.
func _sessione(save, content, prog, subject: String, conta_per_gate: bool, accuratezza: float) -> void:
	var mission = content.build_mission(
		subject, save.level(), 3, SpacedRepetition.due_map(save), pesca,
		save.mastery_of(subject), save.topic_masteries(subject))
	var nodes: Array = mission.get("nodes", [])
	if nodes.is_empty():
		return
	var giuste: Array = []
	var corrette := 0
	var missed: Array = []
	var reviewed_ok: Array = []
	for node_data in nodes:
		var node: Dictionary = node_data
		var ok := rng.randf() < accuratezza
		giuste.append(ok)
		var topic := str(node.get("topic", "generico"))
		if ok:
			corrette += 1
			if bool(node.get("review", false)):
				reviewed_ok.append(topic)
		else:
			missed.append(topic)
	if conta_per_gate:
		prog.record_mission(subject, corrette, nodes.size(), corrette * 10)
	else:
		prog.record_practice(subject, corrette, nodes.size(), corrette * 10)
	prog.record_topic_stats(subject, _stats(nodes, giuste))
	SpacedRepetition.apply_outcome(save, subject, missed, reviewed_ok)
	SpacedRepetition.tick(save)
	prog.aggiorna_traguardi_di_livello()

## Sessioni servite perché il gate si apra, o -1 se non si è aperto.
func _sessioni_per_aprire(accuratezza: float, seme: int) -> int:
	rng.seed = seme
	pesca.seed = seme * 7919 + 13
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)
	var ospite := ApparatusConfig.world_subject(1)

	for giro in range(1, GIRI_MASSIMI + 1):
		# Primo giro: quello che il mondo mette sulla mappa — cinque prove della
		# materia ospite e una palestra per ciascuna delle altre undici.
		if giro == 1:
			for _i in range(5):
				_sessione(save, content, prog, ospite, true, accuratezza)
			for materia_data in ApparatusConfig.SUBJECT_CYCLE:
				if str(materia_data) != ospite:
					_sessione(save, content, prog, str(materia_data), false, accuratezza)
		else:
			# Giri seguenti: solo le materie che il quadro dichiara mancanti.
			var mancanti: Array = Array(prog.readiness().get("missing", []))
			if mancanti.is_empty():
				return int(SpacedRepetition.session_clock(save))
			for materia_data in mancanti:
				var materia := str(materia_data)
				_sessione(save, content, prog, materia, materia == ospite, accuratezza)
		if Array(prog.readiness().get("missing", [])).is_empty():
			return int(SpacedRepetition.session_clock(save))
	return -1

func _init() -> void:
	var rosso := false
	print("GATE DEL MONDO 1 · sessioni per aprire il livello 2 (mediana su %d semi)" % SEMI.size())
	print("%-14s %-10s %-8s %s" % ["accuratezza", "sessioni", "tetto", "esito"])
	for chiave in TETTO.keys():
		var percentuale := int(chiave)
		var misure: Array = []
		for seme_data in SEMI:
			var n := _sessioni_per_aprire(float(percentuale) / 100.0, int(seme_data))
			if n < 0:
				print("%-14s %s" % ["%d%%" % percentuale,
					"GATE MAI APERTO in %d giri (seme %d)" % [GIRI_MASSIMI, int(seme_data)]])
				rosso = true
				continue
			misure.append(n)
		if misure.is_empty():
			continue
		misure.sort()
		var mediana := int(misure[misure.size() / 2])
		var tetto := int(TETTO[chiave])
		var ok := mediana <= tetto
		if not ok:
			rosso = true
		print("%-14s %-10d %-8d %s   %s" % [
			"%d%%" % percentuale, mediana, tetto, "verde" if ok else "ROSSO", str(misure)])
	if rosso:
		push_error("Il costo del mondo 1 è salito sopra il tetto: il gate si apre solo a chi non sbaglia.")
		quit(1)
		return
	print("\nGATE MONDO 1 audit VERDE")
	quit(0)
