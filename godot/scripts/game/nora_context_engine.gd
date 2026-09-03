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
	"geografia": "mappa stellare",
	"scienze": "banco di osservazione",
	"storia": "linea del tempo",
	"logica": "griglia logica",
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
	"geografia": "leggi prima gli assi della mappa, poi la posizione",
	"scienze": "osserva, ipotizza, cambia una cosa sola, verifica",
	"storia": "colloca l'evento nel tempo e chiediti da quale fonte lo sai",
	"logica": "trova la regola nascosta, poi applicala al passo successivo",
}

# Genere grammaticale della label, per l'articolo in "Apro il/la…"/"Questo/a…"
# (il prototipo TS usava un template unico "Questo ${kindLabel}" anche per
# label femminili come "tavola latina": qui l'accordo è corretto).
const SUBJECT_FEMININE := {
	"coding": true, "musica": true, "latino": true,
	"geografia": true, "scienze": false, "storia": true, "logica": true,
}

static func subject_label(subject: String) -> String:
	return str(SUBJECT_LABELS.get(subject, "sistema"))

static func subject_method(subject: String) -> String:
	return str(SUBJECT_METHODS.get(subject, "osserva il sintomo chiave prima di agire"))

static func _is_feminine(subject: String) -> bool:
	return bool(SUBJECT_FEMININE.get(subject, false))

## Come si presenta ad aprire una sessione, per atto. Riusa `NoraVoice.atto_di`
## invece di ripetere le soglie 9/17: due tabelle che dividono la campagna in
## atti e non si parlano fra loro sono come si è rotto l'indirizzo di NORA
## (vedi `nora_voice.gd`) — qui non doveva ripetersi. Il primo atto è la frase
## originale (analisi tecnica e sola); il secondo la fa insieme, non da sola;
## il terzo si tira indietro apposta, perché non dare mai la risposta è
## ormai una scelta e non un limite.
const APERTURA_PER_ATTO := {
	"atto1": "Prima diagnosi, poi risposta",
	"atto2": "Ragioniamo insieme, non ti guido io",
	"atto3": "Tu decidi il primo passo, io guardo",
}
const RIPASSO_PER_ATTO := {
	"atto1": "Ti resto vicina",
	"atto2": "Lo conosci già: fidati di quello che ricordi",
	"atto3": "Ci sei già arrivata una volta: ci arrivi di nuovo",
}

## Frase d'apertura sessione (missione o enigma), con metodo per materia. Se
## la sessione contiene topic in ripasso spaziato, NORA lo segnala invece
## della diagnosi standard (equivalente del beat "open" con recurrent>=1 in
## NoraContextEngine.ts, qui derivato dal flag `review` già in ContentManager).
## `level` è opzionale (default il primo atto) per i chiamanti che non hanno
## ancora un livello — un'unica sessione senza narrativa non deve rompersi.
## **`voce` è il Maestro sveglio di questa materia**, o un dizionario vuoto.
##
## È la regia annunciata da [[MaestriCatalog]] e mai scritta: quando l'apparato
## di una materia è riparato, l'apertura della sessione non è più la formula di
## NORA ma la battuta di chi quella materia la insegnava. La frase del metodo
## resta attaccata in coda — è la parte che serve al bambino, e non si perde
## perché la voce è cambiata.
##
## Il ripasso non prende la voce del Maestro: quel momento parla di **te** e di
## un inciampo tuo, e a dirlo dev'essere la persona che ti accompagna, non la
## materia. Vedi `docs/TRAMA_E_MISTERO.md` §6.1.4 e §7.
static func open_line(subject: String, is_review: bool, level: int = 1, voce: Dictionary = {}) -> String:
	var feminine := _is_feminine(subject)
	var atto := NoraVoice.atto_di(level)
	if is_review:
		var demonstrative := "Questa" if feminine else "Questo"
		var chiusura := str(RIPASSO_PER_ATTO.get(atto, RIPASSO_PER_ATTO["atto1"]))
		return "%s %s ti ha già fatto inciampare. %s: %s." % [demonstrative, subject_label(subject), chiusura, subject_method(subject)]
	var aperture: Array = Array(voce.get("apertura", []))
	if not aperture.is_empty():
		var indice := posmod(level + subject.hash(), aperture.size())
		return "%s %s" % [str(aperture[indice]), subject_method(subject).capitalize() + "."]
	var article := "la" if feminine else "il"
	var apertura := str(APERTURA_PER_ATTO.get(atto, APERTURA_PER_ATTO["atto1"]))
	return "Apro %s %s. %s: %s." % [article, subject_label(subject), apertura, subject_method(subject)]
