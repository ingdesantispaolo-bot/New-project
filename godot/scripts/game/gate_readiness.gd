class_name GateReadiness
extends RefCounted

## Readiness del gate a QUATTRO dimensioni (O-P0.6). Il vecchio gate apriva con
## "N missioni superate" + "media mobile ≥ soglia": due segnali facili da farmare
## e ciechi rispetto a cosa il bambino ha davvero coperto e trattenuto. Qui la
## prontezza richiede tutte e quattro le condizioni:
##
##   1. ACCURATEZZA  — la padronanza (media mobile) raggiunge la soglia del gate.
##   2. CONFIDENZA   — abbastanza evidenza: missioni NUOVE della materia verso il
##                     gate corrente ≥ quelle richieste (usa il conteggio "toward"
##                     che non riconta il lavoro già consumato ai gate passati).
##   3. COPERTURA    — sono stati incontrati abbastanza argomenti distinti della
##                     materia (non basta ripetere sempre lo stesso topic facile).
##   4. RITENZIONE   — nessun argomento della materia è arretrato nel ripasso
##                     spaziato: ciò che era stato sbagliato è stato ripreso.
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
static func evaluate(save, gate: Dictionary, total_topics: int = -1) -> Dictionary:
	var subject := str(gate["subject"])
	var missions_required := int(gate["missionsRequired"])
	var mastery_threshold := float(gate["masteryThreshold"])

	var toward := int(save.missions_toward_gate(subject))
	var mastery := float(save.mastery_of(subject))
	var seen := int(save.topics_seen_count(subject))
	var target := coverage_target(total_topics)
	var overdue := int(SpacedRepetition.subject_overdue_count(save, subject))

	var accuracy_ok := mastery >= mastery_threshold
	var confidence_ok := toward >= missions_required
	var coverage_ok := seen >= target
	var retention_ok := overdue == 0

	var reasons: Array = []
	if not accuracy_ok:
		reasons.append("accuratezza")
	if not confidence_ok:
		reasons.append("confidenza")
	if not coverage_ok:
		reasons.append("copertura")
	if not retention_ok:
		reasons.append("ritenzione")

	return {
		"subject": subject,
		"ready": accuracy_ok and confidence_ok and coverage_ok and retention_ok,
		"reasons": reasons,
		"accuracy": accuracy_ok,
		"confidence": confidence_ok,
		"coverage": coverage_ok,
		"retention": retention_ok,
		# Dettagli per HUD/report (letti, non ricalcolati, da Codex).
		"mastery": mastery,
		"masteryThreshold": mastery_threshold,
		"missionsToward": toward,
		"missionsRequired": missions_required,
		"topicsSeen": seen,
		"topicsTarget": target,
		"topicsOverdue": overdue,
	}
