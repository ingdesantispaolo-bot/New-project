class_name PetExpressionEngine
extends RefCounted

## Segnale di gioco → espressione del Custode. Logica pura: non emette segnali
## propri, non tocca salvataggio, mastery o energia. Vedi docs/PET_CUSTODE.md §2.2.
##
## GUARDRAIL, il più importante di tutto il compagno: **non esistono espressioni
## negative**. `NEGATIVE_FACES` è vuota per costruzione, e ogni segnale di errore,
## fallimento o scudo perso mappa su `incoraggiante`. Vedere il proprio compagno
## deluso dopo una risposta sbagliata è vergogna, e la vergogna spegne
## l'apprendimento: è l'unico posto del gioco dove il feedback non valuta mai.
##
## `offeso` è l'unica faccia che somiglia a un rimprovero, ed è comica per
## costruzione: nasce dall'inattività (non da un errore), dura pochi secondi e si
## scioglie **da sola**, senza che il giocatore debba fare niente.

## Vuota, e deve restare vuota: l'audit lo verifica.
const NEGATIVE_FACES: Array = []

## priority = chi vince quando due espressioni sono in gioco insieme.
## duration = per quanto resta prima di tornare al volto a riposo (0 = fino a
## quando la condizione che l'ha causata resta vera).
const CATALOG := {
	"sereno": {"priority": 0, "duration": 0.0},
	"offeso": {"priority": 10, "duration": 3.0},
	# «curioso» e «attento» erano indefinite (0.0 = restano finché qualcosa non
	# le sostituisce) da quando i segnali sono stati dichiarati — ma finché
	# `near_unexplored`/`near_faded` non erano mai emessi, nessuno se n'era
	# accorto: senza un segnale esplicito di «te ne sei allontanato», la faccia
	# sarebbe rimasta incollata alla prima occhiata curiosa per il resto della
	# sessione. Una durata finita si pulisce da sola.
	"curioso": {"priority": 20, "duration": 3.0},
	"assonnato": {"priority": 22, "duration": 3.4},
	"attento": {"priority": 30, "duration": 2.5},
	"concentrato": {"priority": 40, "duration": 0.0},
	"impicciato": {"priority": 50, "duration": 2.0},
	"stupito": {"priority": 55, "duration": 2.6},
	"orgoglioso": {"priority": 60, "duration": 2.2},
	"incoraggiante": {"priority": 60, "duration": 2.2},
	"sollevato": {"priority": 62, "duration": 2.6},
	"coraggioso": {"priority": 65, "duration": 2.6},
	"beato": {"priority": 70, "duration": 2.4},
	"festa": {"priority": 80, "duration": 3.0},
}

## Ogni segnale del gioco ha una faccia. Nessun buco: l'audit verifica che la
## mappa copra tutti i segnali dichiarati in `GAME_SIGNALS`.
const SIGNAL_FACES := {
	# Ciclo dell'esercizio
	"answer_correct": "orgoglioso",
	"answer_wrong": "incoraggiante",
	"session_start": "concentrato",
	"session_passed": "festa",
	"session_failed": "incoraggiante",
	# Traguardi
	"mission_complete": "festa",
	"apparatus_repaired": "festa",
	"topic_consolidated": "festa",
	# Segnali di apprendimento di NORA (NoraState)
	"learning:perseverance": "coraggioso",
	"learning:improvement": "sollevato",
	"learning:transfer": "festa",
	"learning:help_request": "incoraggiante",
	"learning:recurring_error": "incoraggiante",
	# Lettura del mondo
	"near_unexplored": "curioso",
	"near_faded": "coraggioso",
	# Il fiuto (19 agosto 2026): una deviazione non catalogata — un forziere, una
	# traccia — dalle parti di Eli. Stessa faccia di `near_unexplored`, e non è una
	# svista: la curiosità è la stessa. Quello che distingue i due segnali non è il
	# volto, è il **corpo** — solo il fiuto fa cambiare fianco al Custode e lo fa
	# sporgere (`pet_companion.fiuta`). La faccia dice come si sente, il corpo dice
	# dove: è la sola informazione che il Custode dà, ed è volutamente vaga.
	"near_secret": "curioso",
	# Il Custode riconosce un abitante (docs/PET_CUSTODE.md §3.4)
	"meet_beloved": "festa",
	"meet_shy": "impicciato",
	"meet_fond": "beato",
	# Relazione
	"cuddle": "beato",
	"antic": "impicciato",
	"idle": "offeso",
	# I momenti che contano per il bambino (14 agosto 2026). Il Custode non aiuta
	# e non anticipa niente: reagisce a cose che sono **già a schermo**, ed è
	# l'unica forma di presenza che la decisione 12 gli consente.
	"pet_granted": "festa",
	"power_grade_up": "orgoglioso",
	"sister_found": "stupito",
	# **Quando la storia si ribalta.** (2 settembre 2026) La ricognizione dei
	# contenuti aveva segnato il Custode come «narrativamente muto»: diciotto
	# segnali, un'indole, una collezione — e non compariva in nessuno dei
	# ventiquattro beat né in nessuno dei sette colpi di scena. Il compagno
	# costante del giocatore era l'unica presenza che, quando NORA diceva la cosa
	# più grossa della partita, non faceva niente.
	#
	# Non gli si fa dire una battuta: non parla, ed è giusto così. Alza la testa.
	# È «attento» e non «stupito» perché il Custode legge il Silenzio, non le
	# notizie: quello che sente non è la sorpresa, è che qualcosa è cambiato.
	"story_reveal": "attento",
}

## Segnali che il gioco può emettere. Serve all'audit per provare che la mappa non
## abbia buchi, e a chi collega la scena per sapere che cosa può inviare.
const GAME_SIGNALS := [
	"answer_correct", "answer_wrong", "session_start", "session_passed",
	"session_failed", "mission_complete", "apparatus_repaired",
	"topic_consolidated", "learning:perseverance", "learning:improvement",
	"learning:transfer", "learning:help_request", "learning:recurring_error",
	"near_unexplored", "near_faded", "near_secret",
	"meet_beloved", "meet_shy", "meet_fond",
	"cuddle", "antic", "idle",
	"pet_granted", "power_grade_up", "sister_found", "story_reveal",
]

## Segnali che rappresentano un esito negativo per il giocatore. Nessuno di questi
## può mappare su una faccia negativa — verificato dall'audit.
const FAILURE_SIGNALS := [
	"answer_wrong", "session_failed", "learning:help_request",
	"learning:recurring_error",
]

const MIN_HYSTERESIS_SEC := 1.2

static func face_for(game_signal: String) -> String:
	return str(SIGNAL_FACES.get(game_signal, "sereno"))

## La storia decide l'emozione di base; specie e indole decidono la sfumatura.
## I segnali didattici restano invarianti: un errore e' SEMPRE incoraggiante e
## una carezza e' SEMPRE beata. Le differenze riguardano soltanto incontri e
## comicita', dove un Guardiano serio non reagisce come una Cometa vivace.
static func face_for_pet(game_signal: String, temperament: String, pet_kind: String) -> String:
	var base := face_for(game_signal)
	var kind := pet_kind.trim_prefix("pet-")
	match game_signal:
		"answer_wrong", "session_failed", "learning:help_request", "learning:recurring_error":
			return "incoraggiante"
		"cuddle":
			return "beato"
		"meet_beloved":
			if temperament in ["calmo", "serio"] or kind in ["cat", "guardiano", "codex"]:
				return "beato"
			return "festa"
		"meet_shy":
			if temperament == "serio" or kind in ["guardiano", "codex"]:
				return "attento"
			return "impicciato"
		"near_secret":
			if temperament in ["vivace", "buffo"] and kind not in ["guardiano", "codex"]:
				return "stupito"
			return "curioso"
		"idle":
			if temperament == "calmo" or kind in ["cat", "rabbit", "orbit", "luma"]:
				return "assonnato"
			return "offeso"
		_:
			return base

## Linguaggio affettivo visivo. Non cambia quanto il Custode vuole bene a Eli:
## cambia come lo mostra nel ritratto durante una carezza.
static func affection_style(temperament: String, pet_kind: String) -> String:
	var kind := pet_kind.trim_prefix("pet-")
	if kind in ["dog", "spark", "comet"]:
		return "esuberante"
	if kind in ["rabbit", "prisma", "luma"]:
		return "dolce"
	if kind in ["orbit", "satellite", "codex"]:
		return "luminoso"
	if kind in ["cat", "guardiano"]:
		return "composto"
	match temperament:
		"calmo": return "dolce"
		"buffo": return "esuberante"
		"serio": return "composto"
		_: return "esuberante"

static func priority_of(face: String) -> int:
	return int(Dictionary(CATALOG.get(face, {})).get("priority", 0))

static func duration_of(face: String) -> float:
	return float(Dictionary(CATALOG.get(face, {})).get("duration", 0.0))

static func is_known(face: String) -> bool:
	return CATALOG.has(face)

## Decide se un segnale nuovo deve sostituire l'espressione corrente.
## Una faccia a priorità più alta passa sempre; a priorità pari o minore passa solo
## se quella corrente è scaduta e l'isteresi è rispettata, così il muso non
## sfarfalla fra due stati in mezzo secondo.
static func should_replace(
	current_face: String,
	current_elapsed: float,
	candidate_face: String
) -> bool:
	if not is_known(candidate_face):
		return false
	if current_face == "" or not is_known(current_face):
		return true
	if candidate_face == current_face:
		return false
	if priority_of(candidate_face) > priority_of(current_face):
		return true
	if current_elapsed < MIN_HYSTERESIS_SEC:
		return false
	var hold := duration_of(current_face)
	return hold <= 0.0 or current_elapsed >= hold

## L'indole non cambia COSA fa il Custode, solo come: ampiezza e ritardo della
## reazione. Quattro indoli × quattordici facce danno molto comportamento percepito al
## prezzo di quattro curve.
const TEMPERAMENTS := {
	"vivace": {"amplitude": 1.35, "delay": 0.0, "bounce": true},
	"calmo": {"amplitude": 0.75, "delay": 0.4, "bounce": false},
	"buffo": {"amplitude": 1.20, "delay": 0.2, "bounce": true},
	"serio": {"amplitude": 0.85, "delay": 0.1, "bounce": false},
}

static func temperament_profile(temperament: String) -> Dictionary:
	return Dictionary(TEMPERAMENTS.get(temperament, TEMPERAMENTS["vivace"])).duplicate()
