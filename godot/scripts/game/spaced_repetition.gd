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
		var gia_in_calendario := schedule.has(key)
		var entry: Dictionary = schedule.get(key, {"dueAt": 0, "interval": FIRST_INTERVAL, "lapses": 0})
		entry["interval"] = FIRST_INTERVAL
		entry["dueAt"] = clock + FIRST_INTERVAL
		entry["lapses"] = int(entry.get("lapses", 0)) + 1
		# **Ripreso vuol dire tornato sopra, non azzeccato.**
		#
		# Un argomento sbagliato per la PRIMA volta apre un debito: il gate aspetta
		# che il bambino ci torni. Se era gia' in calendario, il fatto stesso che
		# sia ricomparso in una sessione dice che ci e' tornato — e il debito si
		# chiude anche se stavolta e' andata di nuovo storta.
		#
		# Chiedere che il ripasso riuscisse era la seconda causa del blocco del 26
		# agosto: a ogni sessione nascono errori nuovi, e pretendere che tutti i
		# vecchi siano stati anche *superati* metteva la coda in equilibrio invece
		# che in discesa — misurata ferma fra tre e cinque per sessanta giri. E
		# soprattutto **misurava due volte la stessa cosa**: se il bambino continua
		# a sbagliare quell'argomento e' l'ACCURATEZZA a doverlo dire, che e' la
		# dimensione fatta per quello. La ritenzione risponde a un'altra domanda,
		# ed e' quella scritta in `GateReadiness`: ci sei tornato?
		entry["ripreso"] = gia_in_calendario
		schedule[key] = entry
	for topic in reviewed_ok:
		var key := "%s:%s" % [subject, str(topic)]
		if not schedule.has(key):
			continue
		var entry: Dictionary = schedule[key]
		# Ripreso: l'argomento sbagliato e' stato rivisto e stavolta e' andato.
		# Il calendario continua a riproporlo — e' il suo mestiere — ma il debito
		# verso il gate e' chiuso.
		entry["ripreso"] = true
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
## **Quanti argomenti sbagliati e non ancora ripresi ha questa materia.**
##
## Nasce da un blocco misurato il 26 agosto 2026 (`gate_mondo1_audit`): il gate
## del livello chiedeva `subject_overdue_count == 0`, cioe' **la coda dei ripassi
## vuota nell'istante del controllo**. In un gioco dove ogni sessione di tre nodi
## produce quasi mezzo errore nuovo, e dove una voce esce dal calendario solo dopo
## quattro ripassi riusciti di fila (intervallo 1→2→4→8), quella condizione e' un
## bersaglio che si sposta: si chiudono due arretrati e intanto ne nascono due.
## Misurato: con un bambino all'85% il conto degli arretrati di matematica saliva
## a sei e non scendeva piu', e il gate non si apriva in sessanta giri di gioco.
##
## L'intenzione dichiarata della dimensione RITENZIONE e' un'altra, e sta scritta
## in `GateReadiness`: «cio' che era stato sbagliato e' stato ripreso». Ripreso,
## non consolidato. Il calendario continua a riproporre l'argomento — quello e' il
## suo mestiere e non cambia — ma **il debito verso il gate si chiude alla prima
## ripresa riuscita**, che e' esattamente quello che la frase promette.
##
## Le voci nate prima di questa distinzione non hanno il campo: contano come
## riprese, perche' erano gia' state trattate col metro di prima e togliere un
## traguardo a chi lo aveva e' il difetto che si sta correggendo.
static func da_riprendere_count(save, subject: String) -> int:
	var sr := _sr(save)
	var clock := int(sr.get("sessionClock", 0))
	var prefix := "%s:" % subject
	var count := 0
	for key in sr["schedule"].keys():
		if not str(key).begins_with(prefix):
			continue
		var entry: Dictionary = sr["schedule"][key]
		if bool(entry.get("ripreso", true)):
			continue
		# **L'errore appena fatto non conta ancora.** Il calendario lo rimette in
		# fila per la sessione dopo: contarlo subito vorrebbe dire rimproverare il
		# bambino di non essere gia' tornato su una cosa che ha sbagliato dieci
		# secondi fa. Con un errore ogni due o tre risposte quel conto non tocca
		# mai lo zero, e la dimensione resta chiusa per sempre — misurato.
		if int(entry.get("dueAt", 0)) > clock:
			continue
		count += 1
	return count

static func subject_overdue_count(save, subject: String) -> int:
	var sr := _sr(save)
	var clock := int(sr.get("sessionClock", 0))
	var prefix := "%s:" % subject
	var count := 0
	for key in sr["schedule"].keys():
		if str(key).begins_with(prefix) and int(sr["schedule"][key].get("dueAt", 0)) <= clock:
			count += 1
	return count
