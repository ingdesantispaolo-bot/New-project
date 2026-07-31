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
	"curioso": {"priority": 20, "duration": 0.0},
	"attento": {"priority": 30, "duration": 0.0},
	"concentrato": {"priority": 40, "duration": 0.0},
	"impicciato": {"priority": 50, "duration": 2.0},
	"orgoglioso": {"priority": 60, "duration": 2.2},
	"incoraggiante": {"priority": 60, "duration": 2.2},
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
	"learning:perseverance": "orgoglioso",
	"learning:improvement": "orgoglioso",
	"learning:transfer": "festa",
	"learning:help_request": "incoraggiante",
	"learning:recurring_error": "incoraggiante",
	# Lettura del mondo
	"near_unexplored": "curioso",
	"near_faded": "attento",
	# Relazione
	"cuddle": "beato",
	"antic": "impicciato",
	"idle": "offeso",
}

## Segnali che il gioco può emettere. Serve all'audit per provare che la mappa non
## abbia buchi, e a chi collega la scena per sapere che cosa può inviare.
const GAME_SIGNALS := [
	"answer_correct", "answer_wrong", "session_start", "session_passed",
	"session_failed", "mission_complete", "apparatus_repaired",
	"topic_consolidated", "learning:perseverance", "learning:improvement",
	"learning:transfer", "learning:help_request", "learning:recurring_error",
	"near_unexplored", "near_faded", "cuddle", "antic", "idle",
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
## reazione. Quattro indoli × dieci facce danno molto comportamento percepito al
## prezzo di quattro curve.
const TEMPERAMENTS := {
	"vivace": {"amplitude": 1.35, "delay": 0.0, "bounce": true},
	"calmo": {"amplitude": 0.75, "delay": 0.4, "bounce": false},
	"buffo": {"amplitude": 1.20, "delay": 0.2, "bounce": true},
	"serio": {"amplitude": 0.85, "delay": 0.1, "bounce": false},
}

static func temperament_profile(temperament: String) -> Dictionary:
	return Dictionary(TEMPERAMENTS.get(temperament, TEMPERAMENTS["vivace"])).duplicate()
