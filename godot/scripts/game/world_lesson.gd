class_name WorldLessonCatalog
extends RefCounted

## Specifica DIDATTICA dei mondi (O-P2). Mentre `WorldProfile` descrive l'identità
## strutturale del mondo, la lezione dice COSA si impara e COME il mondo lo
## rappresenta: obiettivi, prerequisiti, topic runtime coinvolti, azioni diegetiche
## che incarnano i concetti, prova di trasferimento e testi di NORA (briefing,
## feedback, debrief). Coperti i livelli 1 e 2 (vertical slice); estensibile a 24
## in O-P5. I `topics` referenziano argomenti REALI dei banchi (validati in audit).
##
## `difficultyDriver` = "subjectMastery": la difficoltà dipende dalla competenza
## della materia (mastery per-materia/topic), non dal rango globale dell'avventura.

const LESSONS := {
	1: {
		"subject": "matematica",
		"objectives": [
			"Padroneggiare le tabelline entro il 10 con sicurezza e rapidità.",
			"Riconoscere la moltiplicazione come somma di gruppi uguali.",
			"Risolvere piccoli problemi a storia scegliendo l'operazione giusta.",
		],
		"prerequisites": [
			"Contare entro il 100.",
			"Addizione e sottrazione entro il 20.",
		],
		"topics": ["tabelline", "problemi"],
		"conceptActions": [
			{"concept": "moltiplicazione come gruppi uguali", "worldAction": "conta i cristalli disposti in filari uguali e trova quanti sono in tutto"},
			{"concept": "la tabellina come addizione ripetuta veloce", "worldAction": "accendi le pietre-numero saltando di 2, di 3, di 5 lungo il sentiero"},
			{"concept": "problema a storia", "worldAction": "aiuta un abitante della radura a dividere il raccolto in parti uguali"},
		],
		"transferTest": {
			"description": "Un problema mai visto, ambientato nella radura, che chiede di scegliere l'operazione giusta e applicarla.",
			"formats": ["numeric_input", "multiple_choice"],
			"novelContext": true,
		},
		"nora": {
			"briefing": "La Radura Accademia si accende con i numeri. Oggi impari a vedere i gruppi: moltiplicare è contare più in fretta. Ogni tabellina che padroneggi accende una parte della nave.",
			"onError": "Numero sbagliato, non strategia sbagliata. Torna ai gruppi: quante volte, quanti per volta?",
			"onStreak": "Stai andando spedita: la moltiplicazione è già un tuo automatismo.",
			"debrief": "Il Nucleo risponde. Hai trasformato il conteggio in padronanza: la radura è più luminosa e la nave un passo più viva.",
		},
		"difficultyDriver": "subjectMastery",
	},
	2: {
		"subject": "italiano",
		"objectives": [
			"Ampliare il lessico per domìni tematici (scuola, casa, natura, pensiero).",
			"Riconoscere la classe grammaticale di una parola (nome, verbo, aggettivo…).",
			"Cogliere il significato di una parola dal contesto.",
		],
		"prerequisites": [
			"Leggere parole e frasi semplici.",
			"Riconoscere lettere e sillabe.",
		],
		"topics": ["scuola-studio", "pensiero-linguaggio", "natura-ambiente", "casa-famiglia"],
		"conceptActions": [
			{"concept": "classi di parole", "worldAction": "abbina ogni parola alla sua classe per aprire i cancelli-frase dell'Archivio"},
			{"concept": "significato in contesto", "worldAction": "scegli la parola giusta per completare l'iscrizione sul ponte delle frasi"},
			{"concept": "campi semantici", "worldAction": "raccogli le parole dello stesso tema per ricomporre uno scaffale dell'Archivio"},
		],
		"transferTest": {
			"description": "Riconoscere il significato o la classe di una parola nuova, incontrata in un tema diverso da quello di studio.",
			"formats": ["multiple_choice", "matching"],
			"novelContext": true,
		},
		"nora": {
			"briefing": "L'Archivio delle Parole custodisce il linguaggio. Oggi dai a ogni parola il suo posto: che cosa significa e a quale classe appartiene. Le parole giuste ricostruiscono i ponti dell'Archivio.",
			"onError": "Rileggi con calma. Cerca prima chi fa cosa, poi scegli la forma più chiara.",
			"onStreak": "Le parole ti obbediscono: l'Archivio si riordina mentre procedi.",
			"debrief": "Uno scaffale dopo l'altro, l'Archivio torna leggibile. Il tuo lessico è cresciuto: la nave registra nuove parole nella memoria di bordo.",
		},
		"difficultyDriver": "subjectMastery",
	},
}

static func has_lesson(level: int) -> bool:
	return LESSONS.has(level)

# Lezione completa del livello (copia difensiva). Il `subject` coincide con la
# scala di progressione (verificato in audit).
static func lesson(level: int) -> Dictionary:
	if not LESSONS.has(level):
		return {}
	return (LESSONS[level] as Dictionary).duplicate(true)

static func objectives(level: int) -> Array:
	return Array(lesson(level).get("objectives", []))

static func topics(level: int) -> Array:
	return Array(lesson(level).get("topics", []))

# Testi di NORA per l'aggancio didattico (briefing all'avvio, feedback, debrief a
# fine livello). Ritorna "" se il livello non ha ancora una lezione autorata.
static func briefing(level: int) -> String:
	return str(lesson(level).get("nora", {}).get("briefing", ""))

static func debrief(level: int) -> String:
	return str(lesson(level).get("nora", {}).get("debrief", ""))

static func feedback(level: int, kind: String) -> String:
	# kind: "onError" | "onStreak"
	return str(lesson(level).get("nora", {}).get(kind, ""))
