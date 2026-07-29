extends RefCounted

## Evidenza di CONSOLIDAMENTO di un argomento (decisione utente del 29 luglio
## 2026): un topic è consolidato quando il bambino lo ha risolto correttamente in
## **tre sessioni distinte**, di cui almeno una a **≥ 3 giorni di distanza** dalla
## prima. È l'unico criterio, tra quelli valutati, che misura la ritenzione e non
## la fortuna di una serata: rispondere bene tre volte in mezz'ora non è sapere.
##
## PERCHÉ UN SECONDO OROLOGIO. Il ripasso spaziato (`SpacedRepetition`) usa di
## proposito un orologio di SESSIONI, deterministico e testabile headless: non sa
## nulla di giorni. Qui serve invece tempo di parete, quindi teniamo le due cose
## separate — le sessioni distinte le conta il `sessionClock`, la distanza in
## giorni la misura questo modulo. La sorgente di tempo è INIETTABILE
## (`set_clock`), altrimenti gli audit dipenderebbero dal giorno in cui girano.
##
## COSA NON FA: il consolidamento NON è un requisito del gate. La dimensione
## RITENZIONE continua a chiedere che nessun argomento sia arretrato nel ripasso.
## Se il gate pretendesse tre giorni, un bambino non potrebbe finire un mondo in
## un pomeriggio — inaccettabile in classe. Il consolidamento è ciò che si dichiara
## all'adulto (Manuale, report) e la soglia dello stato "consolidato" nel Codex.
##
## Forma nel save (`topicEvidence`), additiva e retro-compatibile:
##   "subject:topic" -> {sessions: [clock…], firstAt: unix, lastAt: unix}

const MIN_CORRECT_SESSIONS := 3
const MIN_SPAN_SECONDS := 3 * 86400   # tre giorni pieni
const MAX_TRACKED_SESSIONS := 8       # basta la storia recente: il save resta piccolo

# Orologio iniettabile: < 0 significa "usa il tempo reale di sistema".
static var _clock_override := -1.0

## Fissa il tempo per i test (secondi unix). `-1` ripristina l'orologio reale.
static func set_clock(seconds: float) -> void:
	_clock_override = seconds

static func now_seconds() -> float:
	if _clock_override >= 0.0:
		return _clock_override
	return float(Time.get_unix_time_from_system())

static func _store(save) -> Dictionary:
	if not save.data.has("topicEvidence"):
		save.data["topicEvidence"] = {}
	return save.data["topicEvidence"]

static func _key(subject: String, topic: String) -> String:
	return "%s:%s" % [subject, topic]

## Registra una sessione risolta correttamente su questo argomento. `session_clock`
## viene dal ripasso spaziato: due prove nella STESSA sessione contano una volta
## sola, altrimenti tre risposte di fila nella stessa missione "consoliderebbero".
static func record_correct(save, subject: String, topic: String, session_clock: int) -> void:
	var store := _store(save)
	var key := _key(subject, topic)
	var entry: Dictionary = store.get(key, {"sessions": [], "firstAt": 0.0, "lastAt": 0.0})
	var sessions: Array = entry.get("sessions", [])
	if sessions.has(session_clock):
		return
	sessions.append(session_clock)
	while sessions.size() > MAX_TRACKED_SESSIONS:
		sessions.pop_front()
	var now := now_seconds()
	entry["sessions"] = sessions
	if float(entry.get("firstAt", 0.0)) <= 0.0:
		entry["firstAt"] = now
	entry["lastAt"] = now
	store[key] = entry

## Sessioni distinte con esito corretto su questo argomento.
static func correct_sessions(save, subject: String, topic: String) -> int:
	return int(Array(_store(save).get(_key(subject, topic), {}).get("sessions", [])).size())

## Distanza in secondi tra la prima e l'ultima prova corretta.
static func span_seconds(save, subject: String, topic: String) -> float:
	var entry: Dictionary = _store(save).get(_key(subject, topic), {})
	return maxf(0.0, float(entry.get("lastAt", 0.0)) - float(entry.get("firstAt", 0.0)))

static func is_consolidated(save, subject: String, topic: String) -> bool:
	return correct_sessions(save, subject, topic) >= MIN_CORRECT_SESSIONS \
		and span_seconds(save, subject, topic) >= float(MIN_SPAN_SECONDS)

## Dettaglio leggibile per il report dell'adulto: quanto manca al consolidamento.
static func progress(save, subject: String, topic: String) -> Dictionary:
	var sessions := correct_sessions(save, subject, topic)
	var span := span_seconds(save, subject, topic)
	return {
		"topic": topic,
		"correctSessions": sessions,
		"requiredSessions": MIN_CORRECT_SESSIONS,
		"spanDays": span / 86400.0,
		"requiredDays": float(MIN_SPAN_SECONDS) / 86400.0,
		"consolidated": sessions >= MIN_CORRECT_SESSIONS and span >= float(MIN_SPAN_SECONDS),
	}

## Argomenti consolidati di una materia (per il report e il Manuale).
static func consolidated_topics(save, subject: String) -> Array:
	var out: Array = []
	var prefix := "%s:" % subject
	for key in _store(save).keys():
		var k := str(key)
		if not k.begins_with(prefix):
			continue
		var topic := k.trim_prefix(prefix)
		if is_consolidated(save, subject, topic):
			out.append(topic)
	out.sort()
	return out
