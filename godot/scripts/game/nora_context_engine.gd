class_name NoraContextEngine
extends RefCounted

## Frasi contestuali di NORA per materia (C-15), adattamento di
## src/core/NoraContextEngine.ts: la tassonomia "kind" del prototipo Phaser
## (language/latin/circuit/math/english/robot/coding/music/physics) è
## rimappata sulle 8 materie del gioco Godot. "robot" non ha equivalente qui
## e non è stato portato.

const SUBJECT_LABELS := {
	"matematica": "terminale numerico",
	"italiano": "segnale linguistico",
	"inglese": "comando inglese",
	"coding": "console algoritmica",
	"fisica": "banco fisico",
	"musica": "sequenza musicale",
	"latino": "tavola latina",
	"elettronica": "circuito",
}

const SUBJECT_METHODS := {
	"matematica": "nomina il vincolo, poi fai un passaggio alla volta",
	"italiano": "cerca prima chi fa cosa, poi scegli la forma più chiara",
	"inglese": "isola azione, limite e condizione: il resto è rumore",
	"coding": "simula una riga alla volta: stato, ciclo, uscita",
	"fisica": "metti insieme grandezza, unità e modello prima del numero",
	"musica": "aggancia la nota guida, poi conta posizione e intervallo",
	"latino": "parti dalla desinenza: funzione, numero, poi senso",
	"elettronica": "segui il percorso della corrente prima di toccare i pezzi",
}

# Genere grammaticale della label, per l'articolo in "Apro il/la…"/"Questo/a…"
# (il prototipo TS usava un template unico "Questo ${kindLabel}" anche per
# label femminili come "tavola latina": qui l'accordo è corretto).
const SUBJECT_FEMININE := {
	"coding": true, "musica": true, "latino": true,
}

static func subject_label(subject: String) -> String:
	return str(SUBJECT_LABELS.get(subject, "sistema"))

static func subject_method(subject: String) -> String:
	return str(SUBJECT_METHODS.get(subject, "osserva il sintomo chiave prima di agire"))

static func _is_feminine(subject: String) -> bool:
	return bool(SUBJECT_FEMININE.get(subject, false))

## Frase d'apertura sessione (missione o enigma), con metodo per materia. Se
## la sessione contiene topic in ripasso spaziato, NORA lo segnala invece
## della diagnosi standard (equivalente del beat "open" con recurrent>=1 in
## NoraContextEngine.ts, qui derivato dal flag `review` già in ContentManager).
static func open_line(subject: String, is_review: bool) -> String:
	var feminine := _is_feminine(subject)
	if is_review:
		var demonstrative := "Questa" if feminine else "Questo"
		return "%s %s ti ha già fatto inciampare. Ti resto vicina: %s." % [demonstrative, subject_label(subject), subject_method(subject)]
	var article := "la" if feminine else "il"
	return "Apro %s %s. Prima diagnosi, poi risposta: %s." % [article, subject_label(subject), subject_method(subject)]
