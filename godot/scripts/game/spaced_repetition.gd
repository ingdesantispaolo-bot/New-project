class_name SpacedRepetition
extends RefCounted

## Ripasso spaziato con PIANIFICAZIONE TEMPORALE reale (O-P0.7). Sostituisce il
## vecchio contatore di errori ("due" += 1) con uno scheduler a intervalli
## espansivi in stile SM-2 semplificato.
##
## L'OROLOGIO è un contatore di sessioni di apprendimento (`sessionClock`), non il
## tempo di parete: è deterministico, testabile headless e indipendente dal ritmo
## reale di gioco. Ogni sessione risolta fa `tick`; ogni topic ha un `dueAt` (in
## unità-sessione) che dice quando ripresentarlo:
##   - sbagliato → torna dovuto quasi subito (intervallo 1) e alza le `lapses`;
##   - ripassato bene mentre era dovuto → l'intervallo raddoppia (1→2→4→…→MAX),
##     allontanando il ripasso: la conoscenza consolidata torna più di rado.
##
## Un topic è "dovuto" (`due`) quando esiste a schedule e `dueAt <= sessionClock`.
## `due_map` fornisce alla selezione la stessa forma attesa da ContentManager
## ("subject:topic" -> 1), così il consumer non cambia.

const FIRST_INTERVAL := 1
const MAX_INTERVAL := 8

static func _sr(save) -> Dictionary:
	if not save.data.has("spacedRepetition"):
		save.data["spacedRepetition"] = {"sessionClock": 0, "schedule": {}, "history": []}
	var sr: Dictionary = save.data["spacedRepetition"]
	if not sr.has("schedule"):
		sr["schedule"] = {}
	if not sr.has("sessionClock"):
		sr["sessionClock"] = 0
	return sr

static func session_clock(save) -> int:
	return int(_sr(save).get("sessionClock", 0))

# Avanza l'orologio di una sessione. Va chiamato una volta per sessione risolta.
static func tick(save) -> void:
	var sr := _sr(save)
	sr["sessionClock"] = int(sr.get("sessionClock", 0)) + 1

# Applica gli esiti di una sessione: i topic sbagliati rientrano in ripasso a
# breve; i ripassi risolti vengono allontanati (intervallo raddoppiato). `missed`
# e `reviewed_ok` sono elenchi di topic (stringhe) restituiti dall'ExercisePlayer.
static func apply_outcome(save, subject: String, missed: Array, reviewed_ok: Array) -> void:
	var sr := _sr(save)
	var schedule: Dictionary = sr["schedule"]
	var clock := int(sr.get("sessionClock", 0))
	for topic in missed:
		var key := "%s:%s" % [subject, str(topic)]
		var entry: Dictionary = schedule.get(key, {"dueAt": 0, "interval": FIRST_INTERVAL, "lapses": 0})
		entry["interval"] = FIRST_INTERVAL
		entry["dueAt"] = clock + FIRST_INTERVAL
		entry["lapses"] = int(entry.get("lapses", 0)) + 1
		schedule[key] = entry
	for topic in reviewed_ok:
		var key := "%s:%s" % [subject, str(topic)]
		if not schedule.has(key):
			continue
		var entry: Dictionary = schedule[key]
		var next_interval := mini(int(entry.get("interval", FIRST_INTERVAL)) * 2, MAX_INTERVAL)
		# Se l'intervallo cresciuto supererebbe il massimo, il topic è considerato
		# consolidato: esce dallo schedule (non serve più ripianificarlo).
		if int(entry.get("interval", FIRST_INTERVAL)) >= MAX_INTERVAL:
			schedule.erase(key)
		else:
			entry["interval"] = next_interval
			entry["dueAt"] = clock + next_interval
			schedule[key] = entry
	sr["schedule"] = schedule

# Mappa dei topic DOVUTI ora ("subject:topic" -> 1) nella forma attesa dalla
# selezione (ContentManager tratta come ripasso ogni chiave con valore > 0).
static func due_map(save) -> Dictionary:
	var sr := _sr(save)
	var clock := int(sr.get("sessionClock", 0))
	var out: Dictionary = {}
	for key in sr["schedule"].keys():
		if int(sr["schedule"][key].get("dueAt", 0)) <= clock:
			out[key] = 1
	return out

# Quanti topic di una materia sono dovuti (scaduti) adesso: dimensione RITENZIONE
# del gate (O-P0.6). 0 = niente ripasso arretrato per la materia.
static func subject_overdue_count(save, subject: String) -> int:
	var sr := _sr(save)
	var clock := int(sr.get("sessionClock", 0))
	var prefix := "%s:" % subject
	var count := 0
	for key in sr["schedule"].keys():
		if str(key).begins_with(prefix) and int(sr["schedule"][key].get("dueAt", 0)) <= clock:
			count += 1
	return count
