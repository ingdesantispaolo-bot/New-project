class_name GateReadiness
extends RefCounted

## Readiness a TRE dimensioni, per materia. Il gate del livello le richiede tutte
## e tre su ciascuna delle materie del NUCLEO (italiano, matematica, inglese); la
## riparazione di un apparato le richiede sulla propria materia.
##
##   1. ACCURATEZZA  — la padronanza (media mobile) raggiunge la soglia.
##   2. COPERTURA    — sono stati incontrati abbastanza argomenti distinti della
##                     materia (non basta ripetere sempre lo stesso topic facile).
##   3. RITENZIONE   — nessun argomento della materia è arretrato nel ripasso
##                     spaziato: ciò che era stato sbagliato è stato ripreso.
##
## La quarta dimensione — CONFIDENZA, cioè "N missioni superate" — è stata
## **rimossa** il 30 luglio per decisione dell'utente: si sale quando la competenza
## c'è, non quando si sono fatti abbastanza giri.
##
## Copertura e ritenzione non sono un contorno: **senza il conteggio sono loro a
## impedire che una serie fortunata apra il gate.** E chi fatica non resta
## bloccato, perché la difficoltà adattiva abbassa gli item finché l'accuratezza
## risale — lo sforzo porta comunque da qualche parte.
##
## `total_topics` è il numero di argomenti che la materia PUÒ proporre (dal banco).
## Se ignoto (≤ 0), la copertura ripiega su un minimo assoluto di argomenti visti,
## così il gate resta significativo anche senza il catalogo dei topic.

# Frazione di argomenti distinti da incontrare, con un tetto basso: bastano pochi
# argomenti distinti, non metà del banco (a bassa difficoltà pochi sono
# raggiungibili). MIN_TOPICS_UNKNOWN è il minimo quando il totale è ignoto.
const COVERAGE_FRACTION := 0.34
## La frazione di materia richiesta all'ultimo livello. Non è 1.0: pretendere
## ogni singolo argomento renderebbe il gate ostaggio dell'argomento più raro.
const COVERAGE_FRACTION_MAX := 0.80
## Quanti argomenti al massimo si chiedono PER LIVELLO. Quattro sono raggiungibili
## in ogni materia a ogni livello, e moltiplicati per dodici materie fanno il
## lavoro vero: è il prodotto che rende serio il gate, non il singolo numero.
const COVERAGE_PER_LEVEL_CAP := 5
const COVERAGE_CAP := 3   # storico, non più usato dal calcolo
const MIN_TOPICS_UNKNOWN := 2

# Quanti argomenti distinti servono per la copertura della materia. Il tetto basso
# evita il deadlock: chiediamo "hai toccato più di un argomento facile", non "hai
# coperto metà del banco" (impossibile finché la difficoltà del livello è bassa).
## Quanti argomenti bisogna aver toccato in una materia perché conti come
## coperta, **a questo livello**.
##
## Fino al 5 agosto 2026 era una frazione con un tetto fisso di tre: matematica
## (8 argomenti) e italiano (21) chiedevano entrambe tre argomenti, al mondo 1
## come al mondo 24. La conseguenza si è vista misurando: una volta superata la
## soglia al primo livello, tutti i ventitré successivi si aprivano **senza
## lavoro aggiuntivo** — la padronanza non decade e la copertura non cresceva.
## L'intera campagna costava quanto il primo mondo.
##
## Ora la copertura sale col livello: al primo si chiede poco più di un assaggio,
## all'ultimo quasi tutta la materia. È questo che rende vero «padroneggiare le
## materie a quel grado di difficoltà»: ogni mondo chiede una fetta più larga di
## programma, in tutte e dodici.
static func coverage_target(total_topics: int, level: int = 1) -> int:
	if total_topics <= 0:
		return MIN_TOPICS_UNKNOWN
	# Il primo mondo chiede un argomento per materia: dodici materie da zero
	# sono già il lavoro più grosso della campagna, e aggiungere ampiezza lì
	# significa solo allontanare il momento in cui il bambino vede il mondo 2.
	if level <= 1:
		return 1
	var passo := clampf(float(clampi(level, 1, 24) - 1) / 23.0, 0.0, 1.0)
	var frazione := lerpf(COVERAGE_FRACTION, COVERAGE_FRACTION_MAX, passo)
	var richiesti := int(ceil(frazione * float(total_topics)))
	# Tetto per livello, e non è una rinuncia: la copertura si conta ORA — gli
	# argomenti toccati da quando il livello è cominciato — e un livello propone
	# solo una fetta del banco. Senza tetto il gate chiedeva otto argomenti dove
	# la selezione ne offriva quattro: non difficile, **impossibile**.
	# Misurato su italiano al livello 2 prima di questo limite.
	return clampi(richiesti, 1, mini(COVERAGE_PER_LEVEL_CAP, total_topics))

# Valuta la prontezza. Ritorna ogni dimensione (bool + dettaglio numerico), la
# lista dei motivi non soddisfatti e il verdetto complessivo `ready`.
static func evaluate_subject(
	save, subject: String, mastery_threshold: float, total_topics: int = -1
) -> Dictionary:
	var mastery := float(save.mastery_of(subject))
	# Copertura DI QUESTO LIVELLO, non cumulativa: si contano gli argomenti
	# visti da quando il livello è cominciato. Prima era il totale di sempre, e
	# la conseguenza misurata era che dopo il primo mondo il gate non chiedeva
	# più niente — 24 livelli al prezzo di uno.
	var seen := int(save.topics_seen_this_level(subject))
	var target := coverage_target(total_topics, int(save.level()))
	var overdue := int(SpacedRepetition.subject_overdue_count(save, subject))

	var accuracy_ok := mastery >= mastery_threshold
	var coverage_ok := seen >= target
	var retention_ok := overdue == 0

	var reasons: Array = []
	if not accuracy_ok:
		reasons.append("accuratezza")
	if not coverage_ok:
		reasons.append("copertura")
	if not retention_ok:
		reasons.append("ritenzione")

	return {
		"subject": subject,
		"ready": accuracy_ok and coverage_ok and retention_ok,
		"reasons": reasons,
		"accuracy": accuracy_ok,
		"coverage": coverage_ok,
		"retention": retention_ok,
		# Dettagli per HUD/report (letti, non ricalcolati, dalla presentazione).
		"mastery": mastery,
		"masteryThreshold": mastery_threshold,
		# Quanto manca, già normalizzato 0..1: chi disegna non deve dividere a mano.
		"progress": clampf(mastery / maxf(mastery_threshold, 0.01), 0.0, 1.0),
		"topicsSeen": seen,
		"topicsTarget": target,
		"topicsOverdue": overdue,
	}

## Prontezza del LIVELLO: tutte e tre le dimensioni su ciascuna delle materie del
## nucleo. `topics_by_subject` porta il numero di argomenti che ogni materia può
## proporre (per la copertura); se manca, la copertura ripiega sul minimo assoluto.
## Le materie che aprono il LIVELLO. Erano le tre strumentali; dal 5 agosto 2026
## sono tutte, perché il livello dichiara di certificare quel grado di
## difficoltà — e certificarlo su un quarto del programma non lo certifica.
const GATE_SUBJECTS := ApparatusConfig.SUBJECT_CYCLE

static func evaluate_core(
	save, mastery_threshold: float, topics_by_subject: Dictionary = {}
) -> Dictionary:
	var subjects: Dictionary = {}
	var missing: Array = []
	var ready := true
	var total_progress := 0.0
	# **Tutte e dodici, non più tre.** (5 agosto 2026, decisione del committente
	# dopo un collaudo vero.)
	#
	# Il gate chiedeva italiano, matematica e inglese. Con quello un bambino
	# saliva di livello in 18 esercizi su 3 argomenti — circa dieci minuti — e le
	# altre nove materie poteva non toccarle mai: gli eventi di pratica c'erano,
	# ma erano facoltativi e il gioco non li chiedeva. La strada più corta
	# premiava chi non praticava.
	#
	# Ora il livello si apre solo padroneggiando **tutte le materie a quel
	# livello di difficoltà**. La pratica smette di essere un extra e diventa la
	# strada: è l'unico modo di alzare le materie che il mondo non ospita.
	#
	# Costo misurato (`effort_probe`): 180 esercizi contro 18, circa un'ora per
	# mondo rispondendo sempre giusto.
	for subject in GATE_SUBJECTS:
		var s := str(subject)
		var evaluation := evaluate_subject(
			save, s, mastery_threshold, int(topics_by_subject.get(s, -1)))
		subjects[s] = evaluation
		total_progress += float(evaluation["progress"])
		if not bool(evaluation["ready"]):
			ready = false
			missing.append(s)
	return {
		"ready": ready,
		"coreSubjects": Array(GATE_SUBJECTS).duplicate(),
		"subjects": subjects,
		"missing": missing,
		"masteryThreshold": mastery_threshold,
		# Media dei tre avanzamenti: una sola barra riassuntiva per l'HUD compatto,
		# accanto alle tre di dettaglio.
		"progress": total_progress / float(maxi(1, GATE_SUBJECTS.size())),
	}
