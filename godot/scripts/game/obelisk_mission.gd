extends RefCounted

## Pilota interdisciplinare: tre esercizi, lo stesso obelisco e una ricompensa.
## Il racconto determina i gruppi; il conto alimenta l'obelisco; il carico
## delle casse riusa il principio in un contesto diverso. Nessun nuovo renderer.
static func build(source: Dictionary, variant: int = 0) -> Dictionary:
	var session := source.duplicate(true)
	var groups := 2 + posmod(variant, 2)
	var each := 3 + posmod(floori(float(variant) / 2.0), 3)
	var total := groups * each
	var answer := "%d filari con %d cristalli ciascuno" % [groups, each]
	var wrong_sum := "%d cristalli in tutto" % [groups + each]
	var wrong_reserve := "Solo i due cristalli di riserva"
	var narrative := "Abaco voleva illuminare il sentiero. Dispose %d filari, con %d cristalli in ciascun filare. Lasciò due cristalli di riserva nella cassetta. Poi il Silenzio spense tutto.\n\nQuali cristalli aveva preparato per illuminare il sentiero?" % [groups, each]
	var reading := {
		"id": "obelisk-reading-%d" % variant,
		"subject": "italiano", "topic": "testo-narrativo", "difficulty": 1,
		"format": "multiple_choice", "prompt": narrative,
		"options": [wrong_reserve, answer, wrong_sum], "answer": answer,
		"explanation": "Abaco prepara i filari per il sentiero. I due cristalli nella cassetta sono una riserva: non fanno parte dei filari. Nel racconto, scopo e azione dicono quali dati usare.",
		"distractorWhy": {
			wrong_reserve: "La cassetta conserva una riserva. Il racconto dice che Abaco ha disposto i filari per illuminare il sentiero.",
			wrong_sum: "Il racconto distingue il numero di filari dai cristalli in ciascuno. Sommare i due numeri non descrive la disposizione.",
		},
		"missionStep": "Il messaggio di Abaco",
		"missionOutput": "Il messaggio indica %d filari da %d cristalli; i due di riserva restano nella cassetta." % [groups, each],
		"missionTeaching": "Nel racconto cerca chi agisce, che cosa fa e perché. Se un giardiniere prepara aiuole e mette da parte dei semi, i semi di riserva non sono ancora nelle aiuole.",
	}
	var count := {
		"id": "obelisk-count-%d" % variant,
		"subject": "matematica", "topic": "tabelline", "difficulty": 1,
		"format": "machine_path",
		"title": "Il contatore dell'obelisco",
		"prompt": "Il messaggio ci ha dato %d filari da %d cristalli. Parti da zero: prepara un filare, poi ripetilo per tutti i filari. Monta le due macchine per alimentare l'obelisco." % [groups, each],
		"start": 0, "target": total, "slotCount": 2,
		"machines": [
			{"id": "filare", "op": "add", "value": each, "label": "+%d · un filare" % each},
			{"id": "ripeti", "op": "multiply", "value": groups, "label": "×%d · tutti i filari" % groups},
			{"id": "somma", "op": "add", "value": groups, "label": "+%d" % groups},
		],
		"solution": ["filare", "ripeti"],
		"explanation": "Un filare contiene %d cristalli. Ripeterlo %d volte dà %d cristalli: la moltiplicazione conta gruppi uguali. Moltiplicare lo zero prima di preparare il filare non aggiunge nulla." % [each, groups, total],
		"missionStep": "Il conto diventa luce",
		"missionOutput": "I %d cristalli dei filari alimentano l'obelisco. Resta da preparare la scorta per il sentiero." % total,
		"missionTeaching": "Per contare gruppi uguali, prepara un gruppo e ripetilo. Due vassoi con sei semi ciascuno contengono 6 + 6 = 12 semi, cioè 6 × 2. Nella macchina, prima aggiungi 6 allo zero, poi moltiplica per 2.",
		"machineGoal": "l'obelisco", "machineSuccess": "Il conto dell'obelisco torna!",
	}
	var reserve_each := each + 1
	var reserve := {
		"id": "obelisk-reserve-%d" % variant,
		"subject": "matematica", "topic": "problemi", "difficulty": 1,
		"format": "numeric_input",
		"prompt": "La luce raggiunge i %d tratti del sentiero, uno per filare. Per le prossime riparazioni prepara una cassa per ogni tratto, con %d cristalli in ogni cassa. Quanti cristalli devi portare in tutto?" % [groups, reserve_each],
		"answer": str(groups * reserve_each),
		"explanation": "Le casse sono %d, una per ciascun tratto, e ognuna contiene %d cristalli. Il totale è %d × %d = %d. Il numero di gruppi viene dal sentiero, ma ora ogni gruppo è una cassa." % [groups, reserve_each, groups, reserve_each, groups * reserve_each],
		"missionStep": "La scorta del sentiero", "transfer": true,
		"missionOutput": "La scorta è pronta. L'obelisco può tornare a contare e il sentiero si illumina.",
		"missionHints": ["Quante casse servono, se c'è un tratto per ogni filare?", "Ogni cassa contiene la stessa quantità: puoi contare gruppi uguali, come prima."],
	}
	session["nodes"] = [reading, count, reserve]
	session["stages"] = 3
	session["interdisciplinary"] = true
	session["missionTitle"] = "L'obelisco che ha smesso di contare"
	session["sessionId"] = "obelisk-linked-%d" % variant
	return session
