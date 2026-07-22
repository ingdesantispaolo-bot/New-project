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
	"cittadinanza": "serra-bio",
	"logica": "cratere-logico",
}

# Ordine di rotazione delle materie lungo la scala.
const SUBJECT_CYCLE := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "cittadinanza", "logica",
]

# Gate del livello: {level, subject, apparatus, missionsRequired, masteryThreshold}.
static func level_gate(level: int) -> Dictionary:
	var lvl := clampi(level, 1, MAX_LEVEL)
	var subject: String = SUBJECT_CYCLE[(lvl - 1) % SUBJECT_CYCLE.size()]
	var cycle := (lvl - 1) / SUBJECT_CYCLE.size()  # 0,1,2,… : difficoltà crescente
	var missions := 5 + cycle
	var mastery := minf(0.70 + float(lvl - 1) * 0.007, 0.90)
	return {
		"level": lvl,
		"subject": subject,
		"apparatus": SUBJECT_APPARATUS.get(subject, "nucleo"),
		"missionsRequired": missions,
		"masteryThreshold": mastery,
	}
