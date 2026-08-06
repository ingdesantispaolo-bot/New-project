class_name ApparatusConfig
extends RefCounted

## Scala di progressione (dati tunable). Per ogni livello definisce quale
## apparato/materia riparare e i gate: quante missioni della materia servono e
## quale soglia di padronanza. Le materie ruotano lungo la scala con difficoltà
## crescente; oltre la tabella esplicita si usa una formula ciclica → 20+ livelli.
##
## Vedi docs/DESIGN_COMPLETO.md §2 (Livelli e progressione).

const MAX_LEVEL := 24

const SUBJECT_APPARATUS := {
	"matematica": "nucleo",
	"coding": "cratere-logico",
	"italiano": "data-core",
	"inglese": "data-core",
	"fisica": "ponte-comando",
	"musica": "motore-risonanza",
	"latino": "sala-glifi",
	"elettronica": "reattore",
	"geografia": "ponte-comando",
	"scienze": "serra-bio",
	"storia": "archivio-temporale",
	"logica": "cratere-logico",
}

# Ordine di rotazione delle materie lungo la scala.
const SUBJECT_CYCLE := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "storia", "logica",
]

## Materie del NUCLEO: le uniche che gatano il livello (decisione del 30 luglio).
## Sono le competenze abilitanti — leggere, calcolare, comunicare — su cui le
## altre nove poggiano. Le satelliti danno ricompense, accendono le stanze della
## nave e restano obbligatorie per il finale, ma non fermano la progressione.
## Vedi docs/DESIGN_COMPLETO.md §2.
const CORE_SUBJECTS := ["italiano", "matematica", "inglese"]

static func is_core(subject: String) -> bool:
	return CORE_SUBJECTS.has(subject)

## Materia che ABITA il mondo del livello: ne determina lezione, landmark,
## abitanti e trasformazione ambientale.
##
## Distinta da `level_gate()` di proposito. Finché le due cose coincidevano una
## sola funzione bastava; da quando il livello è gatato dal nucleo e il mondo
## resta caratterizzato dalla sua materia, confonderle significherebbe far
## dipendere l'identità di ventiquattro mondi dalla regola di progressione — e
## cambiarne una romperebbe l'altra.
static func world_subject(level: int) -> String:
	var lvl := clampi(level, 1, MAX_LEVEL)
	return str(SUBJECT_CYCLE[(lvl - 1) % SUBJECT_CYCLE.size()])

## Apparato (stanza della nave) di una materia.
static func apparatus_of(subject: String) -> String:
	return str(SUBJECT_APPARATUS.get(subject, "nucleo"))

## Soglia di padronanza del livello: cresce piano lungo la scala.
static func mastery_threshold(level: int) -> float:
	return minf(0.70 + float(clampi(level, 1, MAX_LEVEL) - 1) * 0.007, 0.90)

## Gate del LIVELLO: **tutte** le materie, con la soglia di padronanza.
##
## Non contiene più `subject` né `missionsRequired`. Prima il gate era «una materia
## e N missioni»; dal 30 luglio si sale con la competenza nelle tre strumentali e
## **senza conteggio di giri**. Chi cerca «quale materia abita il mondo N» usa
## `world_subject()`: sono due domande diverse, e tenerle nella stessa funzione
## faceva dipendere l'identità dei mondi dalla regola di progressione.
##
## Dal 5 agosto 2026 le materie sono dodici, non tre. Questo descrittore era
## rimasto a tre mentre la regola era già cambiata: chi lo leggeva per sapere
## «che cosa serve per salire» otteneva una risposta vecchia — e il portale, che
## la usa per accendersi, non si accendeva mai.
static func level_gate(level: int) -> Dictionary:
	var lvl := clampi(level, 1, MAX_LEVEL)
	return {
		"level": lvl,
		"coreSubjects": Array(SUBJECT_CYCLE).duplicate(),
		"masteryThreshold": mastery_threshold(lvl),
	}

## Gate di un APPARATO: padronanza della sua materia. Riparare un apparato non fa
## salire di livello — accende una stanza.
static func apparatus_gate(subject: String, level: int) -> Dictionary:
	return {
		"subject": subject,
		"apparatus": apparatus_of(subject),
		"masteryThreshold": mastery_threshold(level),
		"core": is_core(subject),
	}
