class_name PetAntics
extends Node

signal antic_started(antic_id: String, duration: float)
signal antic_finished(antic_id: String)

const MIN_INTERVAL_SEC := 90.0

## Il repertorio completo delle sedici combinelle promesse da docs/PET_CUSTODE.md
## §3.2. Fino al 4 agosto 2026 ce n'erano quattro, e il legame non ne sbloccava
## nessun'altra: un bambino a legame pieno dopo venti mondi vedeva le stesse
## quattro del primo giorno.
##
## `sneeze` è l'unica ammessa dentro una prova o un beat di NORA, e il codice la
## cercava già da mesi in un catalogo che non la conteneva — quel ramo non poteva
## scattare. È progettata apposta per rovinare un momento solenne: per questo è
## la più corta, ed è l'unica che NORA commenta ogni volta.
const CATALOG := {
	# Le quattro di partenza: ci sono dal primo minuto.
	"tail": {"label": "Insegue la propria coda", "duration": 3.0},
	"pose": {"label": "Imita la posa di Eli e la sbaglia", "duration": 2.8},
	"nap": {"label": "Si addormenta in piedi e finge di essere sveglio", "duration": 3.2},
	"guard": {"label": "Fa la guardia a un sasso", "duration": 3.4},
	# Sbloccate dal legame.
	"sit": {"label": "Prova a sedersi su una superficie troppo piccola. Ci riprova", "duration": 3.4},
	"sneeze": {"label": "Starnutisce esattamente nel momento più solenne", "duration": 1.6},
	"hide": {"label": "Si nasconde dietro Eli, poi finge di non averlo fatto", "duration": 3.0},
	"fountain": {"label": "Cerca di bere dalla fontana e ci finisce dentro", "duration": 3.6},
	"sniff": {"label": "Annusa uno Sbiadito, cambia idea, torna indietro con dignità", "duration": 3.4},
	"dash": {"label": "Corre avanti entusiasta e poi non ricorda perché", "duration": 2.9},
	"shadow": {"label": "Scopre la propria ombra e la tratta come un'estranea", "duration": 3.1},
	"echo": {"label": "Abbaia in una galleria e risponde al proprio eco", "duration": 3.2},
	"leaf": {"label": "Insegue una foglia e perde clamorosamente", "duration": 2.8},
	"stack": {"label": "Prova a portare due sassi insieme. Ne perde tre", "duration": 3.3},
	"stare": {"label": "Fissa un punto vuoto del muro con enorme convinzione", "duration": 3.5},
	"bow": {"label": "Fa l'inchino a una porta chiusa e aspetta che risponda", "duration": 3.0},
}

## Combinelle sbloccate al salire del legame. Le quattro di base non sono qui:
## quelle ci sono da subito, perché un compagno che non fa niente finché non lo
## meriti non è un compagno.
const BOND_UNLOCKS := [
	{"bond": 0.10, "antic": "sit"},
	{"bond": 0.20, "antic": "shadow"},
	{"bond": 0.30, "antic": "dash"},
	{"bond": 0.40, "antic": "leaf"},
	{"bond": 0.50, "antic": "sneeze"},
	{"bond": 0.60, "antic": "fountain"},
	{"bond": 0.70, "antic": "echo"},
	{"bond": 0.80, "antic": "hide"},
	{"bond": 0.85, "antic": "stack"},
	{"bond": 0.90, "antic": "sniff"},
	{"bond": 0.95, "antic": "stare"},
	{"bond": 1.00, "antic": "bow"},
]

## Quante combinelle sono raggiungibili in tutto. Serve all'album e all'audit.
static func total_count() -> int:
	return CATALOG.size()

static func label_of(antic_id: String) -> String:
	return str(Dictionary(CATALOG.get(antic_id, {})).get("label", ""))

## Che cosa fa il Custode quando incontra un abitante ricorrente.
## Vedi docs/PET_CUSTODE.md §3.4.
##
## Reazione fissa e coerente: è il modo più economico di far sentire che il mondo
## è uno solo. Il Custode non riconosce «un personaggio», riconosce *quella*
## persona, e la riconosce sempre allo stesso modo — come fanno i cani.
##
## Nessuna di queste righe dà informazioni utili al gioco. Se il Custode
## segnalasse chi ha una missione, diventerebbe un indicatore e smetterebbe di
## essere un compagno.
const OPINIONI := {
	"itin-lucilla": {
		"signal": "meet_beloved",
		"line": "%s la vede e perde ogni compostezza. È l'unica persona che preferisce a te, e lei lo sa.",
	},
	"itin-orsolo": {
		"signal": "meet_shy",
		"line": "%s si mette dietro di te. Orsolo dice che i pet non gli piacciono, e nessuno dei due ci crede.",
	},
	"itin-vera": {
		"signal": "meet_fond",
		"line": "Vera lo adora e sbaglia il suo nome anche stavolta. %s non se n'è mai accorto.",
	},
	"itin-nima": {
		"signal": "meet_shy",
		"line": "%s prova a mangiare una mappa. Nima ha smesso di stupirsi tre mondi fa.",
	},
	"itin-cinabro": {
		"signal": "meet_fond",
		"line": "%s si siede su un piede di Cinabro e non si muove più. Cinabro non commenta.",
	},
	"itin-sesto": {
		"signal": "meet_beloved",
		"line": "%s e Sesto si riconoscono con enorme sorpresa. Succede ogni volta: si dimenticano a vicenda.",
	},
	"w03-sesto": {
		"signal": "meet_beloved",
		"line": "%s e Sesto si riconoscono con enorme sorpresa. Succede ogni volta: si dimenticano a vicenda.",
	},
}

## L'opinione del Custode su questo abitante, o vuoto se non ne ha.
static func opinion_for(npc_id: String) -> Dictionary:
	return Dictionary(OPINIONI.get(npc_id, {})).duplicate()

var _unlocked: Array = []
var _elapsed := 0.0
var _remaining := 0.0
var _active := ""
var _cursor := 0
var _blocked := false
var _reduced_motion := false

func configure(unlocked: Array, reduced_motion: bool) -> void:
	_unlocked.clear()
	for antic_id in unlocked:
		if CATALOG.has(str(antic_id)) and not _unlocked.has(str(antic_id)):
			_unlocked.append(str(antic_id))
	_reduced_motion = reduced_motion
	set_process(not _unlocked.is_empty())

## Il chiamante lo richiama a ogni fotogramma finché un pannello resta aperto
## (`outdoor_world._process`), non solo al momento in cui si apre. Senza la
## guardia sulla TRANSIZIONE, ogni chiamata con `value=true` interromperebbe
## anche una combinella appena avviata con `authorized_sneeze` — uccidendo lo
## starnuto un fotogramma dopo averlo fatto partire. È il secondo motivo, oltre
## al catalogo mancante, per cui lo starnuto non era mai comparso.
func set_blocked(value: bool) -> void:
	if _blocked == value:
		return
	_blocked = value
	if _blocked and _active != "":
		var interrupted := _active
		_active = ""
		_remaining = 0.0
		antic_finished.emit(interrupted)

func is_reduced_motion() -> bool:
	return _reduced_motion

func active_antic() -> String:
	return _active

func _process(delta: float) -> void:
	if _active != "":
		_remaining -= delta
		if _remaining <= 0.0:
			var finished := _active
			_active = ""
			antic_finished.emit(finished)
		return
	if _blocked:
		return
	_elapsed += delta
	if _elapsed >= MIN_INTERVAL_SEC:
		try_start("world")

## Avvia lo starnuto senza passare dal turno del catalogo. `try_start` sceglie
## la prossima combinella per rotazione: va bene per il caso ambientale, in cui
## non importa quale tocchi, ma qui non è il caso a decidere il momento — è il
## gioco, al terzo errore sullo stesso argomento, per rompere la spirale senza
## aiutare. Se lo starnuto non è ancora sbloccato dal legame, o il Custode sta
## già facendo altro, non succede niente: meglio silenzio che una combinella
## a caso al posto sbagliato.
func force_sneeze() -> String:
	if _active != "" or not _unlocked.has("sneeze"):
		return ""
	_elapsed = 0.0
	_active = "sneeze"
	_remaining = float(Dictionary(CATALOG["sneeze"]).get("duration", 1.6))
	antic_started.emit(_active, _remaining)
	return _active

func try_start(context: String, authorized_sneeze := false) -> String:
	if _active != "" or _unlocked.is_empty():
		return ""
	if context in ["exercise", "exam", "beat"] and not authorized_sneeze:
		return ""
	var antic_id := str(_unlocked[_cursor % _unlocked.size()])
	if context in ["exercise", "exam", "beat"] and antic_id != "sneeze":
		return ""
	_cursor += 1
	_elapsed = 0.0
	_active = antic_id
	_remaining = float(Dictionary(CATALOG[antic_id]).get("duration", 2.5))
	antic_started.emit(_active, _remaining)
	return _active
