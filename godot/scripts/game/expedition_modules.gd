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
## **Perché pochi e non sette.** Perché sono quelli che **funzionano davvero**.
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

const FELPA := "module-hush"
const ZAVORRA := "module-ballast"

## **Due moduli ritirati, due nuovi.** (21 agosto 2026)
##
## «Serbatoio ampliato» e «Bobina larga» potenziavano l'impulso, e l'impulso non
## c'è più: `costo_delle_sacche_probe` ha misurato che dal mondo 2 in poi nessuna
## sacca costa energia, quindi non restava niente da comprare con una carica.
## Erano 650 energia su 950 — due terzi della sezione — spesi per potenziare una
## meccanica senza lavoro, cioè esattamente il difetto che questo file dice di
## aver chiuso il 6 agosto.
##
## La regola con cui ho scelto i due che li sostituiscono: **il numero deve
## esistere già nel codice, e non deve saturare col grado di Eli.** È la lezione
## della misura che ha ucciso l'impulso — il morso si azzera perché è scritto
## come differenza fra due gradi, e qualunque cosa scritta così sparisce da sola.
## Questi due non sono differenze di grado:
##
##   - **quanto lontano una sacca ti nota** (`world_enemy`: 190 + grado × 12).
##     Cresce col grado della SACCA e non cala mai con quello di Eli;
##   - **quanto ti sposta lo spintone** (`outdoor_world`: 104 unità). È una
##     costante, e nessuno l'ha mai scalata.

## Quanto si accorcia la vista di una sacca con l'andatura felpata. Poco più di
## un quarto: abbastanza da poter costeggiare un presidio invece di doverlo
## attraversare, troppo poco perché la mappa diventi vuota. Una sacca che non
## nota più nessuno non è un pericolo disinnescato, è un pericolo cancellato.
const VISTA_PIENA := 1.0
const VISTA_FELPATA := 0.72

## Quanto lontano ti butta uno spintone, con e senza zavorra. Non si azzera: una
## sacca deve continuare a spostarti, o l'anello del presidio smette di essere un
## ostacolo e resta un disegno.
const SPINTA_PIENA := 104.0
const SPINTA_ZAVORRATA := 62.0

## Gli identificativi dei moduli, per gli audit e per la bottega.
static func ids() -> Array:
	return [FELPA, ZAVORRA]

static func posseduto(save, id: String) -> bool:
	if save == null:
		return false
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	return Array(cosmetics.get("inventory", [])).has(id)

## Quanto lontano una sacca si accorge di Eli, in frazione della sua vista
## piena. L'andatura felpata la accorcia; senza il modulo resta uno.
static func vista_delle_sacche(save) -> float:
	return VISTA_FELPATA if posseduto(save, FELPA) else VISTA_PIENA

## Quanto lontano butta uno spintone.
static func spinta_del_morso(save) -> float:
	return SPINTA_ZAVORRATA if posseduto(save, ZAVORRA) else SPINTA_PIENA
