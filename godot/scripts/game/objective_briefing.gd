class_name ObjectiveBriefing
extends RefCounted

## **Che cosa devo fare adesso, e che cosa manca per il mondo dopo.**
## (7 agosto 2026)
##
## Segnalazione del committente: «dobbiamo spiegare meglio al giocatore cosa deve
## fare, e cosa manca per passare di livello al mondo successivo».
##
## **Perché era illeggibile, e non è colpa della scrittura.** Il gate del livello
## chiede **dodici materie per tre condizioni** — accuratezza, copertura,
## ritenzione — cioè trentasei condizioni insieme. L'HUD ne mostrava due
## percentuali e una frazione di stanze: non era una spiegazione scritta male,
## era un cruscotto al posto di un'istruzione. Un bambino di undici anni davanti
## a «Nucleo: MAT 60% · ITA 20% · ING 0% · stanze 1/12» non sa che cosa toccare.
##
## Qui la stessa verità viene detta in due forme diverse, perché rispondono a due
## domande diverse:
##
##   IL PASSO      una frase sola, **una cosa sola da fare adesso**, con dove
##                 farla. Sta nell'HUD e non chiede di essere aperta.
##   IL PERCORSO   l'elenco ordinato di quello che manca al mondo successivo,
##                 materia per materia, con quanto manca in numeri. Si apre
##                 quando si vuole sapere «quanto ancora».
##
## **La regola di scrittura**: mai un numero senza un'azione accanto. «Padronanza
## 34%» dice uno stato; «rispondi bene a 4 prove di matematica» dice che cosa
## fare. Il primo si legge e si dimentica, il secondo si può eseguire.
##
## **E mai più di una cosa alla volta.** Con trentasei condizioni aperte la
## tentazione è elencarle: sarebbe onesto e inutile. Si nomina la materia **più
## vicina al traguardo**, perché è quella su cui il prossimo quarto d'ora rende
## di più, ed è anche quella che restituisce prima la soddisfazione di aver
## chiuso qualcosa.

## Come si chiamano, per un bambino, le tre condizioni del gate.
##
## I nomi tecnici restano nel codice: qui servono le parole che dicono **che cosa
## fare**, non come si chiama la misura.
const AZIONE := {
	"accuratezza": "rispondi giusto più spesso",
	"copertura": "affronta argomenti nuovi",
	"ritenzione": "recupera i ripassi arretrati",
}

## Il passo successivo: una frase sola.
##
## L'ordine delle priorità non è estetico — è il percorso vero, dal più vicino
## al più lontano. Chiedere di alzare una materia lontana quando l'esame è già
## pronto manderebbe il bambino dalla parte opposta della mappa.
static func passo(runtime: Dictionary, progression) -> Dictionary:
	if bool(runtime.get("complete", false)):
		return {
			"titolo": "La nave è completa",
			"azione": "Tutti e dodici i sistemi sono accesi. Puoi tornare in qualsiasi mondo per allenarti.",
			"dove": "",
		}
	if bool(runtime.get("ready", false)):
		var apparato := str(runtime.get("apparatus", "nucleo")).replace("-", " ")
		return {
			"titolo": "L'esame ti aspetta",
			"azione": "Torna alla nave e supera l'esame di %s: accende la stanza «%s»." % [
				str(runtime.get("focusSubject", "")), apparato],
			"dove": "il portale della nave",
		}
	# L'apparato del mondo: è il traguardo vicino, quello che si chiude qui.
	var materia := str(runtime.get("focusSubject", "matematica"))
	var stato: Dictionary = progression.apparatus_readiness(materia)
	# `materia_in_linea` e non `stato.ready`: il traguardo di questo grado, una
	# volta raggiunto, tiene. Senza, il passo tornava a mandare il bambino sulle
	# prove di una materia che aveva appena chiuso, per un ripasso diventato
	# dovuto mentre giocava altrove — e l'esame, che quel traguardo lo onora,
	# sarebbe rimasto aperto contraddicendo la riga appena letta.
	if not bool(progression.materia_in_linea(materia)):
		return {
			"titolo": "Apri la stanza di %s" % materia,
			"azione": _cosa_manca(stato, true, bool(progression.save.mastery_never_set(materia))),
			"dove": "le prove di %s, qui nel mondo" % materia,
		}
	return {
		"titolo": "Il mondo è a posto: manca il resto del programma",
		"azione": "Apri il quadro degli obiettivi per vedere quali materie restano.",
		"dove": "",
	}

## **Che cosa manca, in una frase, per UNA materia.**
##
## Si nomina una sola delle tre condizioni: la più vicina a chiudersi. Elencarle
## tutte e tre sarebbe corretto e inutilizzabile — chi legge non saprebbe da dove
## cominciare, che è esattamente il difetto da cui questo lotto nasce.
## Pubblica per l'audit: e' la funzione che compone tutte le frasi mostrate, e
## controllarla dall'esterno e' il solo modo di verificarne l'ortografia senza
## costruire una scena.
static func frase_di_stato(stato: Dictionary, con_dove: bool, mai_giocata: bool = false) -> String:
	return _cosa_manca(stato, con_dove, mai_giocata)

static func _cosa_manca(stato: Dictionary, con_dove: bool, mai_giocata: bool = false) -> String:
	var arretrati := int(stato.get("topicsOverdue", 0))
	var visti := int(stato.get("topicsSeen", 0))
	var bersaglio := int(stato.get("topicsTarget", 0))
	var padronanza := float(stato.get("mastery", 0.0))
	var soglia := float(stato.get("masteryThreshold", 0.0))
	# Prima i ripassi: sono la cosa più veloce da chiudere e l'unica che il gioco
	# propone da solo, quindi è anche quella che si chiude senza cercarla.
	if arretrati > 0:
		var coda := "il gioco te li ripropone da solo nelle prove" if con_dove else "riaffrontali"
		if arretrati == 1:
			return "Hai 1 ripasso da recuperare: %s." % coda
		return "Hai %d ripassi da recuperare: %s." % [arretrati, coda]
	if visti < bersaglio:
		var mancano := bersaglio - visti
		# Parole intere, non suffissi incollati: la prima versione componeva
		# «nuovo» + «i» e produceva «argomenti nuovoi». Un errore di ortografia
		# in un gioco che insegna l'italiano non e' un dettaglio, e incollare
		# desinenze e' il modo piu' facile di farne.
		if mancano == 1:
			return "Ti manca 1 argomento nuovo da affrontare (%d su %d fatti)." % [visti, bersaglio]
		return "Ti mancano %d argomenti nuovi da affrontare (%d su %d fatti)." % [
			mancano, visti, bersaglio]
	if padronanza < soglia:
		# Il numero da mostrare è **quante prove**, non la percentuale: una
		# percentuale non dice quanto lavoro manca, un conteggio sì.
		var quante := prove_stimate(padronanza, soglia, mai_giocata)
		return "Sei al %.0f%% e serve il %.0f%%: circa %d %s da superare." % [
			padronanza * 100.0, soglia * 100.0, quante,
			"prova" if quante == 1 else "prove"]
	return "Fatto: questa materia è in linea."

## Quante prove servono, all'incirca, per colmare la distanza di padronanza.
##
## È una **stima dichiarata**, non una promessa: la padronanza sale di più
## quando si è indietro e di meno vicino alla soglia, e dipende da quanto si
## risponde bene. Meglio un numero vicino che una percentuale esatta e muta —
## «tre prove» si può decidere di fare, «34%» no.
## **Il primo contatto è un salto, non un passo.** (24 agosto 2026)
##
## `PASSO_PER_PROVA` descrive la media mobile: da padronanza già fissata, una
## prova quasi perfetta ne aggiunge circa quattro centesimi. Ma la **prima** prova
## di una materia non passa dalla media mobile — `ProgressionManager` la fissa in
## un colpo a `PRUDENZA_PRIMO_CONTATTO` (0,85), che a metà campagna è già sopra
## la soglia.
##
## Senza questa distinzione il quadro leggeva padronanza 0,0 e rispondeva
## «ancora 18 prove» per una materia che se ne chiude con **una**. Misurato sul
## mondo 2 il 24 agosto: dodici materie mai giocate, diciotto o venti prove
## ciascuna, cioè oltre duecento prove annunciate a un bambino per passare al
## mondo 3 — un numero che non guida, spaventa e basta. È il difetto peggiore che
## un numero dichiarato possa avere: essere falso verso l'alto.
##
## `mai_giocata` va passato quando la materia non ha ancora una padronanza nel
## salvataggio ([[GameSaveManager.mastery_never_set]]).
const PRIMO_CONTATTO := 0.85

static func prove_stimate(padronanza: float, soglia: float, mai_giocata: bool = false) -> int:
	if padronanza >= soglia:
		return 0
	# Circa quattro punti di padronanza per prova superata: misurato sul
	# comportamento di `record_mission` a risposte quasi tutte giuste.
	const PASSO_PER_PROVA := 0.04
	if mai_giocata:
		# La prima prova porta di colpo a `PRIMO_CONTATTO`; da lì in poi è la
		# media mobile a fare il resto.
		if PRIMO_CONTATTO >= soglia:
			return 1
		return 1 + clampi(ceili((soglia - PRIMO_CONTATTO) / PASSO_PER_PROVA), 1, 99)
	return clampi(ceili((soglia - padronanza) / PASSO_PER_PROVA), 1, 99)

## **Quante prove mancano ancora a questa materia**, in un numero solo.
##
## Nasce dalla segnalazione del 24 agosto 2026: «ho finito il mondo 1 con tutti i
## compiti assegnati e non passo al mondo 2». Era vera e non era un difetto del
## gate — era che i compiti **non erano tutti dichiarati**. I sette eventi della
## materia del mondo stanno sulla mappa e si vedono finire; le undici palestre
## delle altre materie si vedono finire allo stesso modo, ma finirne una non
## chiude la materia: ne serve un altro giro, e la palestra successiva compare
## altrove. Chi guardava la mappa vedeva tutto spento e concludeva di aver
## finito.
##
## Il quadro degli obiettivi lo diceva già, materia per materia. Quello che
## mancava era dirlo **dove sta il compito**, cioè sul cartello della palestra e
## alla fine della prova. Questa funzione è il numero unico che entrambi mostrano,
## così la mappa e il quadro non possono dissentire.
##
## Zero vuol dire in linea. Il conto è il massimo fra le tre dimensioni, non la
## somma: si giocano insieme, e sommarle prometterebbe più lavoro di quello che
## serve — che è il modo più rapido di far smettere qualcuno.
static func prove_mancanti(stato_materia: Dictionary, mai_giocata: bool = false) -> int:
	if bool(stato_materia.get("ready", false)):
		return 0
	var arretrati := int(stato_materia.get("topicsOverdue", 0))
	var scoperti := maxi(0, int(stato_materia.get("topicsTarget", 0)) - int(stato_materia.get("topicsSeen", 0)))
	var per_padronanza := prove_stimate(
		float(stato_materia.get("mastery", 0.0)),
		float(stato_materia.get("masteryThreshold", 0.0)),
		mai_giocata)
	return maxi(1, maxi(arretrati, maxi(scoperti, per_padronanza)))

## Come sopra, ma partendo dalla progressione e dal nome della materia: è la forma
## che serve al mondo aperto, che ha in mano una materia e non una valutazione.
static func prove_mancanti_di(progression, subject: String) -> int:
	if progression == null:
		return 0
	var stato: Dictionary = progression.readiness()
	var materie: Dictionary = stato.get("subjects", {})
	if not materie.has(subject):
		return 0
	return prove_mancanti(
		Dictionary(materie[subject]), bool(progression.save.mastery_never_set(subject)))

## **Il percorso completo verso il mondo successivo.**
##
## Una riga per materia, ordinate **dalla più vicina al traguardo**: chi apre
## questo quadro vuole sapere che cosa gli conviene fare adesso, e la risposta è
## quasi sempre «finisci quella che hai quasi finito».
##
## Le materie già in linea restano nell'elenco, in fondo, con la spunta. Toglierle
## sarebbe più pulito e sbagliato: vedere quello che si è già chiuso è metà della
## motivazione, e un elenco che si accorcia da solo nasconde i progressi.
static func percorso(progression) -> Dictionary:
	var stato: Dictionary = progression.readiness()
	var materie: Dictionary = stato.get("subjects", {})
	var righe: Array = []
	for chiave in materie.keys():
		var voce: Dictionary = materie[chiave]
		righe.append({
			"materia": str(chiave),
			"fatto": bool(voce.get("ready", false)),
			"nucleo": bool(voce.get("core", false)),
			"progresso": float(voce.get("progress", 0.0)),
			"manca": _cosa_manca(voce, false, bool(progression.save.mastery_never_set(str(chiave)))),
		})
	righe.sort_custom(func(a, b):
		# Le fatte in fondo; fra le aperte, prima quella più vicina.
		if bool(a["fatto"]) != bool(b["fatto"]):
			return not bool(a["fatto"])
		return float(a["progresso"]) > float(b["progresso"]))
	var quante_fatte := 0
	for riga in righe:
		if bool(Dictionary(riga)["fatto"]):
			quante_fatte += 1
	return {
		"righe": righe,
		"fatte": quante_fatte,
		"totali": righe.size(),
		"pronto": bool(stato.get("ready", false)),
		# **Detto una volta, non dodici.** Leggendo il quadro per la prima volta
		# la domanda vera non e' «quanto manca a latino»: e' «e dove si fa
		# latino, se questo mondo e' di matematica?». La risposta e' la stessa
		# per undici materie su dodici, quindi va scritta una volta sola —
		# ripeterla riga per riga la renderebbe invisibile.
		"dove": "Ogni mondo ospita una prova per OGNI materia: le palestre sparse sulla mappa. La materia del mondo apre la sua stanza; le altre si allenano lì, e il quadro dice quante prove mancano a ciascuna.",
	}

## La riga di riepilogo del percorso: «7 materie su 12 in linea».
##
## Il conteggio va detto sempre, anche quando è zero: un elenco senza totale non
## fa capire se si è a un terzo o a un passo dalla fine.
static func riassunto(percorso_dati: Dictionary) -> String:
	var fatte := int(percorso_dati.get("fatte", 0))
	var totali := int(percorso_dati.get("totali", 12))
	if bool(percorso_dati.get("pronto", false)):
		return "Tutte e %d le materie sono in linea: il mondo successivo è aperto." % totali
	return "%d %s su %d in linea. Servono tutte per aprire il mondo successivo: qui sotto c'è quanto manca a ciascuna." % [
		fatte, "materia" if fatte == 1 else "materie", totali]
