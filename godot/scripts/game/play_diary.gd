class_name PlayDiary
extends RefCounted

## Il diario: quanto hai giocato, quante prove hai superato, cosa sai adesso.
##
## **Perché esiste.** Fino al 5 agosto 2026 il gioco misurava moltissimo — dodici
## materie, mastery per argomento, ripasso spaziato, evidenza di ritenzione — e
## non mostrava niente di tutto questo al bambino. `daily` era nel salvataggio
## dal primo giorno e **non lo scriveva né lo leggeva nessuno**: i giorni giocati
## non esistevano proprio. Un bambino che gioca da tre settimane non aveva modo
## di vedere che ha giocato da tre settimane.
##
## **La decisione che conta: niente serie da spezzare.** La tentazione ovvia è la
## *streak* — «sette giorni di fila!» — che è anche il campo già previsto nello
## schema. Ma questo progetto ha un guard-rail esplicito contro il punire
## l'assenza (`pet_state.gd`: «un gioco che si studia non può punire chi torna
## dopo tre giorni... produce senso di colpa, che è esattamente ciò che spegne
## l'apprendimento»). Una serie che si azzera è una minaccia sul domani, non un
## resoconto di ieri: il giorno in cui si rompe, il bambino non ha perso niente
## di reale, ma il gioco gli dice che sì.
##
## Quindi si contano i **giorni giocati**, cumulativi e monòtoni, esattamente
## come il legame del Custode. Un numero che sale e non scende mai. Chi torna
## dopo un mese trova ventidue e non zero.
##
## **Cosa NON fa.** Non mostra percentuali di errore, non classifica le materie
## da peggiore a migliore, non dà obiettivi. Il diario racconta quello che hai
## fatto; non ti dice cosa avresti dovuto fare.

const DEFAULT := {
	"date": "",       # ultimo giorno registrato (ISO, ora locale)
	"firstDate": "",  # primo giorno in assoluto
	"days": 0,        # giorni distinti giocati — cumulativo, non scende mai
	"missions": 0,    # prove superate oggi (si azzera a ogni nuovo giorno)
	"streak": 0,      # mantenuto per lo schema, MAI mostrato: vedi sopra
}

# --- Accesso al salvataggio ----------------------------------------------------
# Migrazione non distruttiva e idempotente, come `PetState`: un salvataggio
# vecchio guadagna le chiavi mancanti senza perdere quelle che ha già.
static func _daily(save) -> Dictionary:
	if not save.data.has("daily"):
		save.data["daily"] = DEFAULT.duplicate(true)
	var daily: Dictionary = save.data["daily"]
	for key in DEFAULT.keys():
		if not daily.has(key):
			daily[key] = DEFAULT[key]
	return daily

## Registra che oggi si è giocato. Idempotente entro la giornata: chiamarla dieci
## volte in un pomeriggio conta un giorno solo.
##
## `today` si può forzare per gli audit; a runtime è la data locale.
## Ritorna vero se questa chiamata ha aperto un giorno nuovo.
static func register_day(save, today: String = "") -> bool:
	var giorno := today if today != "" else Time.get_date_string_from_system()
	var daily := _daily(save)
	if str(daily.get("date", "")) == giorno:
		return false
	if str(daily.get("firstDate", "")) == "":
		daily["firstDate"] = giorno
	daily["date"] = giorno
	daily["days"] = int(daily.get("days", 0)) + 1
	# Le prove superate sono un contatore del giorno: riparte con la giornata.
	daily["missions"] = 0
	return true

static func days_played(save) -> int:
	return int(_daily(save).get("days", 0))

static func first_day(save) -> String:
	return str(_daily(save).get("firstDate", ""))

static func last_day(save) -> String:
	return str(_daily(save).get("date", ""))

## Una prova superata oggi. Serve solo alla riga «oggi» del diario.
static func register_passed_today(save) -> void:
	var daily := _daily(save)
	daily["missions"] = int(daily.get("missions", 0)) + 1

static func passed_today(save) -> int:
	return int(_daily(save).get("missions", 0))

# --- Il riepilogo --------------------------------------------------------------

## Tutto quello che il pannello mostra, calcolato dal salvataggio. Logica pura:
## non scrive niente, così si può chiamare per disegnare senza effetti collaterali.
static func summary(save) -> Dictionary:
	var eventi: Array = Array(save.data.get("progressReport", {}).get("events", []))
	var affrontate := eventi.size()
	var superate := 0
	var secondi := 0.0
	# Le prove abbandonate non sono qui dentro: `resolve_session` esce prima di
	# registrarle. Una prova chiusa non conta come tentativo fallito, e il
	# diario non deve farla ricomparire come tale.
	var per_materia: Dictionary = {}
	for voce in eventi:
		var evento := voce as Dictionary
		var materia := str(evento.get("subject", ""))
		superate += int(evento.get("missions", 0))
		secondi += float(evento.get("seconds", 0.0))
		if not per_materia.has(materia):
			per_materia[materia] = {"subject": materia, "prove": 0, "superate": 0, "mastery": 0.0}
		var riga: Dictionary = per_materia[materia]
		riga["prove"] = int(riga["prove"]) + 1
		riga["superate"] = int(riga["superate"]) + int(evento.get("missions", 0))

	var mastery: Dictionary = save.data.get("mastery", {})
	for materia in per_materia.keys():
		per_materia[materia]["mastery"] = clampf(float(mastery.get(materia, 0.0)), 0.0, 1.0)

	# Le materie in ordine di quante prove hai affrontato: il diario racconta
	# dove sei stato, non dove sei bravo. Nessuna classifica per punteggio.
	var materie: Array = per_materia.values()
	materie.sort_custom(func(a, b): return int(a["prove"]) > int(b["prove"]))

	return {
		"giorni": days_played(save),
		"primoGiorno": first_day(save),
		"ultimoGiorno": last_day(save),
		"superateOggi": passed_today(save),
		"proveAffrontate": affrontate,
		"proveSuperate": superate,
		"minuti": int(secondi / 60.0),
		"mondiVisitati": Array(save.data.get("worlds", {}).get("unlocked", [])).size(),
		"materie": materie,
		"argomenti": _conteggio_argomenti(save),
		"custode": _riepilogo_custode(save),
	}

## Quanti argomenti in ciascuno stato del manuale di NORA. È la statistica che
## dice davvero cosa il bambino sa: `consolidated` significa tre risposte
## corrette in sessioni distinte, a giorni di distanza — non una schermata vista.
static func _conteggio_argomenti(save) -> Dictionary:
	var out := {}
	for stato in KnowledgeCodex.STATE_ORDER:
		out[str(stato)] = 0
	# Il codex salva una stringa per chiave ("materia:argomento" -> stato), non
	# un dizionario: vedi `KnowledgeCodex.state_of()`.
	var codex: Dictionary = save.data.get("codex", {})
	for chiave in codex.keys():
		var stato := str(codex[chiave])
		if out.has(stato):
			out[stato] = int(out[stato]) + 1
	return out

static func _riepilogo_custode(save) -> Dictionary:
	if not PetState.is_granted(save):
		return {}
	return {
		"nome": PetState.name_of(save),
		"sessioni": PetState.sessions_together(save),
		"legame": PetState.bond(save),
		"regali": PetState.gifts(save).size(),
	}
