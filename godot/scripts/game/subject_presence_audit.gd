extends SceneTree

## **Tutte e dodici le materie in ogni mondo.** Vincolo didattico dichiarato
## dall'utente il 3 agosto 2026, e da oggi un contratto verificato.
##
## Perché serve un audit se la cosa già funziona: oggi la proprietà è
## **emergente**, non garantita. Nasce dal fatto che
## `MissionEventDirector.other_subjects()` restituisce tutte e undici le altre
## materie del ciclo. Basta che qualcuno aggiunga un filtro ragionevolissimo —
## «solo le materie già sbloccate», «solo quelle con banco sufficiente» — e la
## proprietà sparisce senza che nessun test diventi rosso. È esattamente il tipo
## di regola che si perde in una rifattorizzazione fatta in buona fede.
##
## E ha una conseguenza didattica grossa, che è il motivo per cui l'utente l'ha
## posta come vincolo: se ogni materia è in ogni mondo **dal primo**, allora
## nessuna materia viene incontrata per la prima volta a metà campagna, e la
## difficoltà per livello non chiede mai a un bambino di partire dal terzo
## gradino di una scala che non ha mai salito.
##
## Ha anche una ragione dentro la storia, e non è un ornamento: i Primi
## credevano che le discipline fossero **dodici finestre sulla stessa stanza**
## (`docs/TRAMA_E_MISTERO.md` §4.1). Il circuito della nave non era un giro di
## lezioni, era una ricerca. Un mondo con dentro una materia sola tradirebbe la
## tesi su cui è costruito il finale.

## Quante materie devono comparire in ogni mondo: tutte.
const MATERIE_ATTESE := 12

## Quante devono essere **raggiungibili** entro il raggio di gioco. Oggi il caso
## peggiore è 11 (mondo 8): un evento di pratica cade oltre il raggio perché il
## direttore li distribuisce fino a `reach + 350`. Il bersaglio è 12 — questo è
## un pavimento contro le regressioni, non un traguardo.
const MIN_RAGGIUNGIBILI := 11

func _init() -> void:
	var failures: Array = []
	print("Tutte le dodici materie in ogni mondo\n")
	print("%-7s %-14s %9s %9s" % ["MONDO", "OSPITE", "PRESENTI", "RAGG."])

	var mondi_pieni := 0
	for level in range(1, 25):
		var focus := ApparatusConfig.world_subject(level)
		var profile := WorldProfileCatalog.profile(level)
		var events: Array = MissionEventDirector.plan(profile, {}, "presence-audit-%d" % level)

		var presenti: Dictionary = {}
		var raggiungibili: Dictionary = {}
		var pratiche: Dictionary = {}
		for entry in events:
			var e := entry as Dictionary
			var subject := str(e.get("subject", ""))
			presenti[subject] = true
			if bool(e.get("reachable", false)):
				raggiungibili[subject] = true
			if str(e.get("kind", "")) == "practice":
				pratiche[subject] = int(pratiche.get(subject, 0)) + 1

		if presenti.size() != MATERIE_ATTESE:
			var mancanti: Array = []
			for subject in ApparatusConfig.SUBJECT_CYCLE:
				if not presenti.has(str(subject)):
					mancanti.append(str(subject))
			failures.append("mondo %d: %d materie su %d — mancano %s" % [
				level, presenti.size(), MATERIE_ATTESE, ", ".join(PackedStringArray(mancanti))])
		if raggiungibili.size() < MIN_RAGGIUNGIBILI:
			failures.append("mondo %d: solo %d materie raggiungibili entro il raggio (minimo %d)" % [
				level, raggiungibili.size(), MIN_RAGGIUNGIBILI])
		if raggiungibili.size() == MATERIE_ATTESE:
			mondi_pieni += 1

		# La materia ospite non deve avere un evento di pratica: i suoi eventi
		# contano per il gate, e un doppione confonderebbe il conteggio.
		if pratiche.has(focus):
			failures.append("mondo %d: la materia ospite «%s» ha anche un evento di pratica" % [
				level, focus])
		# Ognuna delle altre undici ne deve avere **esattamente uno**: due
		# sarebbero pratica bloccata, zero sarebbe una materia assente.
		for subject in ApparatusConfig.SUBJECT_CYCLE:
			if str(subject) == focus:
				continue
			var quante := int(pratiche.get(str(subject), 0))
			if quante != 1:
				failures.append("mondo %d: «%s» ha %d eventi di pratica, atteso 1" % [
					level, str(subject), quante])

		print("%-7d %-14s %9d %9d" % [level, focus, presenti.size(), raggiungibili.size()])

	print("\nmondi con tutte e dodici raggiungibili: %d su 24" % mondi_pieni)
	if mondi_pieni < 24:
		print("(il bersaglio è 24: il direttore distribuisce le pratiche fino a")
		print(" `reach + 350`, quindi qualcuna può cadere oltre il raggio)")

	if not failures.is_empty():
		printerr("VINCOLO DELLE DODICI MATERIE VIOLATO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nSubject presence audit OK — dodici materie in ognuno dei 24 mondi")
	quit(0)
