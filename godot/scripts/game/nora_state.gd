class_name NoraState
extends RefCounted

## Stato relazionale di NORA (O-P4): integrità (quanto la nave/NORA è tornata
## online), memoria (ricordi recuperati) e fiducia verso Eli. Vive nel save.
##
## GUARDRAIL DIDATTICO: la fiducia NON dipende dalle sole risposte giuste. Cresce
## dai segnali di APPRENDIMENTO — perseveranza dopo un errore, richiesta d'aiuto,
## miglioramento della padronanza, trasferimento a un caso nuovo. Un singolo
## "corretto" non muove la fiducia (altrimenti si farma la relazione indovinando).
## L'errore ricorrente non abbassa la fiducia: NORA sostiene, non giudica.

const DEFAULT := {"integrity": 0.0, "memory": 0, "trust": 0.5}

# Guadagno di fiducia per segnale (0 = nessun effetto, es. la sola correttezza).
const TRUST_DELTA := {
	"perseverance": 0.06,
	"improvement": 0.05,
	"transfer": 0.06,
	"help_request": 0.03,
	"recurring_error": 0.0,
	"correct": 0.0,
}

# Reazioni di NORA ai segnali: sostegno e riconoscimento dello SFORZO, mai la
# risposta. Sono battute di relazione, distinte dai messaggi di sistema.
const REACTIONS := {
	"recurring_error": "Questo nodo ti resiste: torniamo indietro di un passo, insieme. Non è un giudizio, è una mappa.",
	"help_request": "Bene che tu chieda: consultare è imparare, non copiare. Guardiamo il metodo.",
	"perseverance": "Hai ripreso dopo un inciampo. È esattamente così che si ripara un sistema — e una rotta.",
	"improvement": "Vedo che migliori: la tua padronanza cresce, e con lei la mia fiducia.",
	"transfer": "Hai applicato il concetto a un caso nuovo: questo è capire davvero, non ricordare a memoria.",
}

static func _nora(save) -> Dictionary:
	if not save.data.has("nora"):
		save.data["nora"] = DEFAULT.duplicate(true)
	var n: Dictionary = save.data["nora"]
	for key in DEFAULT.keys():
		if not n.has(key):
			n[key] = DEFAULT[key]
	return n

static func integrity(save) -> float:
	return float(_nora(save).get("integrity", 0.0))

static func memory(save) -> int:
	return int(_nora(save).get("memory", 0))

static func trust(save) -> float:
	return float(_nora(save).get("trust", 0.5))

# Allinea integrità e memoria al progresso della nave: quanti apparati sono stati
# riparati (memoria = ricordi recuperati; integrità = frazione della nave online).
static func sync_from_progress(save) -> void:
	# Un apparato fisico ospita più nodi lungo i 24 livelli; contare soltanto le
	# chiavi del dizionario fermava NORA a 7/24 anche a campagna completata.
	# Ogni gate è online quando il repairedLevel dell'apparato ha raggiunto quel
	# livello, lo stesso criterio usato da ShipActivationModel.
	var repaired := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var gate := ApparatusConfig.level_gate(level)
		var apparatus := str(gate.get("apparatus", ""))
		var repaired_level := int(save.data.get("apparatus", {}).get(apparatus, {}).get("repairedLevel", 0))
		if repaired_level >= level:
			repaired += 1
	var n := _nora(save)
	n["memory"] = repaired
	n["integrity"] = clampf(float(repaired) / float(ApparatusConfig.MAX_LEVEL), 0.0, 1.0)

# Registra un segnale di apprendimento e aggiorna la fiducia di conseguenza.
# Ritorna la reazione testuale di NORA (o "" se il segnale non ne ha una).
static func register(save, signal_name: String) -> String:
	var n := _nora(save)
	n["trust"] = clampf(float(n.get("trust", 0.5)) + float(TRUST_DELTA.get(signal_name, 0.0)), 0.0, 1.0)
	return str(REACTIONS.get(signal_name, ""))

static func reaction(signal_name: String) -> String:
	return str(REACTIONS.get(signal_name, ""))
