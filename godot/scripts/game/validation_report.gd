class_name ValidationReport
extends RefCounted

## Report locale di validazione (O-P6): legge il save canonico e riassume, per
## materia e in aggregato, le dimensioni che contano davvero per giudicare
## l'apprendimento — COPERTURA, CONFIDENZA, RITENZIONE, AIUTI e TEMPO. Nessuna rete
## né telemetria remota: è materiale per docenti/revisori, calcolato in locale.
##
## - copertura   = argomenti distinti incontrati / argomenti disponibili;
## - confidenza  = quanta evidenza abbiamo (missioni superate, normalizzate);
## - ritenzione  = quota di argomenti visti portati a "consolidato" (meno gli
##                 arretrati del ripasso spaziato);
## - aiuti       = argomenti consultati almeno una volta nel Manuale NORA;
## - tempo       = secondi spesi (dagli eventi del progressReport).

const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")
const SpacedRepetition = preload("res://scripts/game/spaced_repetition.gd")
const LearningConfig = preload("res://scripts/game/learning_config.gd")

const CONFIDENCE_TARGET := 10.0   # missioni oltre le quali la confidenza è piena

# Numero di argomenti che la materia può proporre (denominatore della copertura).
static func _total_topics(content, subject: String) -> int:
	if subject == "matematica":
		return KnowledgeCodex.MATH_CONCEPTS.size()
	return content.bank_topics(subject).size()

static func subject_report(save, content, subject: String) -> Dictionary:
	var seen := int(save.topics_seen_count(subject))
	var total := maxi(1, _total_topics(content, subject))
	var coverage := clampf(float(seen) / float(total), 0.0, 1.0)
	var confidence := clampf(float(save.missions_of(subject)) / CONFIDENCE_TARGET, 0.0, 1.0)

	# Ritenzione: quota di argomenti VISTI arrivati a consolidato, penalizzata dagli
	# argomenti arretrati nel ripasso spaziato.
	var consolidated := 0
	for topic in save.topic_masteries(subject).keys():
		if KnowledgeCodex.state_of(save, subject, str(topic)) == KnowledgeCodex.STATE_CONSOLIDATED:
			consolidated += 1
	var overdue := int(SpacedRepetition.subject_overdue_count(save, subject))
	var retention := 0.0
	if seen > 0:
		retention = clampf(float(consolidated - overdue) / float(seen), 0.0, 1.0)

	# Aiuti: argomenti consultati almeno una volta (stato >= consultato).
	var help_used := 0
	var consulted_rank := KnowledgeCodex.STATE_ORDER.find(KnowledgeCodex.STATE_CONSULTED)
	for topic in save.topic_masteries(subject).keys():
		var rank := KnowledgeCodex.STATE_ORDER.find(KnowledgeCodex.state_of(save, subject, str(topic)))
		if rank >= consulted_rank:
			help_used += 1

	# Tempo: somma dei secondi degli eventi della materia.
	var seconds := 0.0
	for event in save.data.get("progressReport", {}).get("events", []):
		if str(event.get("subject", "")) == subject:
			seconds += float(event.get("seconds", 0.0))

	return {
		"subject": subject,
		"mastery": save.mastery_of(subject),
		"coverage": coverage,
		"topicsSeen": seen,
		"topicsTotal": total,
		"confidence": confidence,
		"retention": retention,
		"help": help_used,
		"timeSeconds": seconds,
	}

# Report completo: per materia (solo quelle ATTIVE) + aggregato.
static func build(save, content) -> Dictionary:
	var by_subject: Dictionary = {}
	var cov := 0.0
	var conf := 0.0
	var ret := 0.0
	var total_seconds := 0.0
	var subjects: Array = LearningConfig.active_subjects(save)
	for subject in subjects:
		var r := subject_report(save, content, str(subject))
		by_subject[str(subject)] = r
		cov += float(r["coverage"])
		conf += float(r["confidence"])
		ret += float(r["retention"])
		total_seconds += float(r["timeSeconds"])
	var n := maxi(1, subjects.size())
	return {
		"schoolBand": LearningConfig.school_band(save),
		"curriculum": LearningConfig.curriculum(save),
		"level": save.level(),
		"activeSubjects": subjects,
		"bySubject": by_subject,
		"aggregate": {
			"coverage": cov / float(n),
			"confidence": conf / float(n),
			"retention": ret / float(n),
			"timeSeconds": total_seconds,
			"noraTrust": float(save.data.get("nora", {}).get("trust", 0.5)),
			"noraIntegrity": float(save.data.get("nora", {}).get("integrity", 0.0)),
		},
	}
