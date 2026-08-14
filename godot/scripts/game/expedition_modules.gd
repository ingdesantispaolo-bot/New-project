class_name ExpeditionModules
extends RefCounted

## **I moduli di spedizione.** (14 agosto 2026)
##
## L'unica cosa che la bottega vende oltre alla bellezza, e nasce da una
## contraddizione fra due documenti che avevano ragione tutti e due.
## [DESIGN_COMPLETO](../../docs/DESIGN_COMPLETO.md) §8 prometteva sette moduli
## NORA — indizio, seconda chance, tempo extra; il lotto del 6 agosto aveva
## deciso il contrario, e con una ragione solida: *«un consumabile utile diventa
## una scorciatoia per non sapere»*.
##
## La distinzione che li concilia è **dove agisce il modulo**. Un modulo che
## tocca una **prova** è una scorciatoia per non sapere. Un modulo che tocca la
## **mappa** no: è la stessa distinzione che rende lecito mettere un duello di
## riflessi davanti a un forziere di cosmetici. Quindi qui dentro non c'è né
## potrà mai esserci niente che sfiori una domanda, la padronanza, la copertura,
## la ritenzione, un gate o un esame — è la decisione vincolante 15, e
## `expedition_module_audit` la verifica sul comportamento invece che a parole.
##
## **Perché tre e non sette.** Perché tre sono quelli che **funzionano davvero**.
## Il radar dei forzieri e il raggio della torcia chiedono una resa che ancora non
## esiste, e un oggetto che promette una meccanica inesistente è già stato il
## difetto del 6 agosto — quattro upgrade che costavano fino a 1600 frammenti e
## non facevano nulla. Entreranno con la loro resa, non prima.
##
## **Perché permanenti e non consumabili.** Misurato il 14 agosto: il catalogo
## costa 72.600 energia e una campagna intera ne produce fra 42.758 e 53.783,
## cioè fra il 59% e il 74%. Non c'è energia in eccesso da drenare. Tre
## potenziamenti definitivi costano insieme 950 — l'1,3% del catalogo — e la
## scelta in bottega esiste senza che i cosmetici se ne accorgano. Un consumabile
## sarebbe un rubinetto senza fondo su un'economia già stretta.
##
## Non serve una chiave nuova nel salvataggio: `cosmetics.inventory` raccoglie
## già gli acquisti permanenti che non si equipaggiano, e ha i suoi lettori. La
## chiave `modules`, dichiarata e mai costruita, resta sepolta dov'è.

const SERBATOIO := "module-tank"
const BOBINA := "module-coil"
const PASSO := "module-stride"

## Una carica d'impulso in più. Una, non due: il tetto esiste perché la scelta
## *passo o giro attorno* continui a esistere, e comprarsela via del tutto
## sarebbe comprarsi il gioco.
const CARICA_EXTRA := 1

## Il raggio dell'impulso, base e ampliato. La bobina larga vale circa un terzo
## in più: si sente attraversando un gruppo di sacche, e non trasforma l'impulso
## in un'arma che pulisce lo schermo.
const RAGGIO_BASE := 168.0
const RAGGIO_AMPIO := 230.0

## Il moltiplicatore dello scatto. Il passo lungo aggiunge circa un quinto: è la
## differenza fra arrivare e arrivare prima, non fra potere e non potere.
const SCATTO_BASE := 1.65
const SCATTO_LUNGO := 1.95

## Gli identificativi dei moduli, per gli audit e per la bottega.
static func ids() -> Array:
	return [SERBATOIO, BOBINA, PASSO]

static func posseduto(save, id: String) -> bool:
	if save == null:
		return false
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	return Array(cosmetics.get("inventory", [])).has(id)

## Quante cariche d'impulso può tenere in tasca Eli.
static func cariche_massime(save, base: int) -> int:
	return base + (CARICA_EXTRA if posseduto(save, SERBATOIO) else 0)

## Il raggio entro cui l'impulso stabilizza le sacche.
static func raggio_impulso(save) -> float:
	return RAGGIO_AMPIO if posseduto(save, BOBINA) else RAGGIO_BASE

## Quanto va più veloce lo scatto.
static func moltiplicatore_scatto(save) -> float:
	return SCATTO_LUNGO if posseduto(save, PASSO) else SCATTO_BASE
