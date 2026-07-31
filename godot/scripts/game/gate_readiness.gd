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
const COVERAGE_CAP := 3
const MIN_TOPICS_UNKNOWN := 2

# Quanti argomenti distinti servono per la copertura della materia. Il tetto basso
# evita il deadlock: chiediamo "hai toccato più di un argomento facile", non "hai
# coperto metà del banco" (impossibile finché la difficoltà del livello è bassa).
static func coverage_target(total_topics: int) -> int:
	if total_topics <= 0:
		return MIN_TOPICS_UNKNOWN
	return clampi(int(ceil(COVERAGE_FRACTION * float(total_topics))), 1, mini(COVERAGE_CAP, total_topics))

# Valuta la prontezza. Ritorna ogni dimensione (bool + dettaglio numerico), la
# lista dei motivi non soddisfatti e il verdetto complessivo `ready`.
static func evaluate_subject(
	save, subject: String, mastery_threshold: float, total_topics: int = -1
) -> Dictionary:
	var mastery := float(save.mastery_of(subject))
	var seen := int(save.topics_seen_count(subject))
	var target := coverage_target(total_topics)
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
static func evaluate_core(
	save, mastery_threshold: float, topics_by_subject: Dictionary = {}
) -> Dictionary:
	var subjects: Dictionary = {}
	var missing: Array = []
	var ready := true
	var total_progress := 0.0
	for subject in ApparatusConfig.CORE_SUBJECTS:
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
		"coreSubjects": Array(ApparatusConfig.CORE_SUBJECTS).duplicate(),
		"subjects": subjects,
		"missing": missing,
		"masteryThreshold": mastery_threshold,
		# Media dei tre avanzamenti: una sola barra riassuntiva per l'HUD compatto,
		# accanto alle tre di dettaglio.
		"progress": total_progress / float(maxi(1, ApparatusConfig.CORE_SUBJECTS.size())),
	}
