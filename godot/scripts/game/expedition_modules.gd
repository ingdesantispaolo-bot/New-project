class_name ExpeditionModules
extends RefCounted

## **I moduli di spedizione.** (14 agosto 2026 · riscritti il 2 settembre 2026)
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
## ---
##
## # La bardatura (2 settembre 2026)
##
## **Il difetto misurato:** su settanta voci del catalogo, **due** cambiavano
## qualcosa. Le altre sessantotto erano colore. E le due che facevano qualcosa
## erano permanenti, sempre attive e mai in conflitto fra loro: comprarle non era
## una decisione, era una formalità rimandata. Un negozio in cui la risposta
## giusta è sempre «sì, prima o poi» non insegna niente sulla gestione di
## qualcosa, e il committente ha chiesto esattamente il contrario — che lo
## studente **debba saper gestire risorse e oggetti**.
##
## La correzione ha due metà, e nessuna delle due funziona da sola:
##
##   **Più cose che fanno.** Sei moduli invece di due, e ognuno appeso a un
##   numero che *esisteva già nel codice*: la vista delle sacche, la spinta del
##   morso, la velocità del passo, il raggio del cono della torcia, il raggio del
##   radar dei forzieri, quanto rende una cassa. Nessuno promette una meccanica
##   che va scritta dopo — è il difetto del 6 agosto, e non si ripete.
##
##   **Meno posti di quanti se ne possiedano.** Si comprano tutti, se ne
##   **portano pochi**: due all'inizio, tre dal mondo 9, quattro dal 17. È la
##   bardatura, e trasforma l'acquisto in una scelta due volte — una quando si
##   spende, una ogni volta che si parte. Chi entra in un mondo buio porta il
##   riflettore; chi attraversa un presidio porta la felpata e la zavorra; chi
##   vuole il Custode di cristallo porta il taccuino e rinuncia alla comodità.
##   Nessuna configurazione è la migliore, ed è tutto il punto.
##
## **La bardatura si cambia in bottega.** Non per attrito: perché è lì che si
## prepara una spedizione, e dà al luogo una ragione di esistere anche quando non
## si sta comprando niente. Una bottega in cui si entra una volta per slot è un
## menu; una in cui si torna a decidere è un posto.
##
## **Perché permanenti e non consumabili.** Misurato il 14 agosto: il catalogo
## costa quanto una campagna e mezza, e non c'è valuta in eccesso da drenare. Un
## consumabile sarebbe un rubinetto senza fondo su un'economia già stretta; la
## bardatura ottiene la stessa tensione (non puoi avere tutto adesso) senza
## chiedere al bambino di ricomprare quello che ha già.
##
## Non serve una chiave nuova nel salvataggio per il possesso:
## `cosmetics.inventory` raccoglie già gli acquisti permanenti che non si
## equipaggiano. La bardatura invece è una chiave nuova — `cosmetics.loadout` —
## perché è l'unica cosa qui dentro che **cambia senza che si spenda niente**, e
## infilarla in `equipped` (un id per slot) avrebbe reso impossibile portarne più
## d'uno.

const FELPA := "module-hush"
const ZAVORRA := "module-ballast"
const PASSO := "module-stride"
const RIFLETTORE := "module-lantern"
const RABDOMANTE := "module-divining"
const TACCUINO := "module-ledger"

## **Due moduli ritirati, due nuovi.** (21 agosto 2026)
##
## «Serbatoio ampliato» e «Bobina larga» potenziavano l'impulso, e l'impulso non
## c'è più: `costo_delle_sacche_probe` ha misurato che dal mondo 2 in poi nessuna
## sacca costa energia, quindi non restava niente da comprare con una carica.
## Erano 650 energia su 950 — due terzi della sezione — spesi per potenziare una
## meccanica senza lavoro, cioè esattamente il difetto che questo file dice di
## aver chiuso il 6 agosto.
##
## La regola con cui sono scelti i moduli, e con cui vanno scelti quelli che
## verranno: **il numero deve esistere già nel codice, e non deve saturare col
## grado di Eli.** È la lezione della misura che ha ucciso l'impulso — il morso
## si azzera perché è scritto come differenza fra due gradi, e qualunque cosa
## scritta così sparisce da sola.
##
## | modulo | numero che tocca | dove vive quel numero |
## |---|---|---|
## | Andatura felpata | quanto lontano una sacca ti nota | `world_enemy` 190 + grado × 12 |
## | Zavorra da campo | quanto ti sposta lo spintone | `outdoor_world` 104 unità |
## | Passo da spedizione | quanto veloce cammini | `player_controller.speed` 260 |
## | Riflettore | il cono di luce davanti a te | `ExpeditionModulePresentation` |
## | Rabdomante | il raggio a cui i forzieri si segnalano | `ExpeditionModulePresentation` |
## | Taccuino del cambio | quanto rende una cassa | `_svuota_forziere` |
##
## Le due righe della resa non sono un progetto: **il disegno esisteva già ed era
## spento.** `ExpeditionModulePresentation` costruisce da settimane il cono
## direzionale della torcia e il segnale sopra i forzieri leggendo due numeri
## (`torchRadius`, `treasureRadarRadius`) che **nessuno pubblicava**. Erano i due
## moduli rinviati «a quando la resa esisterà»: la resa è arrivata prima della
## semantica, e per qualche settimana il gioco ha avuto due strumenti costruiti e
## mai accesi.
const CATALOGO := [FELPA, ZAVORRA, PASSO, RIFLETTORE, RABDOMANTE, TACCUINO]

## **Quanti se ne portano.** Due, poi tre, poi quattro: la bardatura cresce con
## gli apparati riparati, cioè con la sola spina dorsale del gioco. Non arriva
## mai a sei — il giorno in cui si porta tutto è il giorno in cui la bardatura
## smette di essere una scelta e torna a essere un elenco.
const POSTI_BASE := 2
const LIVELLO_TERZO_POSTO := 9
const LIVELLO_QUARTO_POSTO := 17

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

## La velocità del passo. Il +14% non è una scorciatoia verso niente — non c'è
## una sola prova a tempo sulla mappa — è quanto costa attraversare un mondo, e
## un mondo che si attraversa più in fretta è un mondo che si esplora di più.
const PASSO_BASE := 260.0
const PASSO_SPEDIZIONE := 296.0

## Il cono di luce davanti a Eli, in unità di mondo. Zero significa «nessun
## cono», ed è quello che vede chi non porta il riflettore: la torcia continua a
## fare la sua luce tonda intorno (quella è la chiave, e le chiavi non si
## comprano — [[FieldTools]]), il riflettore aggiunge la direzione.
##
## **Serve la torcia.** Un riflettore senza lampada non illumina, e la resa lo sa
## già: `ExpeditionModulePresentation` accende il cono solo con `tool-torch` in
## mano. È l'unico modulo che dipende da un'altra cosa, ed è voluto — è ciò che
## lo lega al mondo che consegna la torcia invece che a una riga di listino.
const RAGGIO_TORCIA_SPENTO := 0.0
const RAGGIO_TORCIA := 232.0

## Il raggio entro cui un forziere ancora chiuso alza il proprio segnale. Non
## rivela la mappa e non apre niente: dice «qui vicino c'è qualcosa», che è la
## differenza fra passare accanto a una cassa e trovarla. Volutamente corto —
## poco più di uno schermo — perché un radar che vede tutto il mondo cancella
## l'esplorazione invece di premiarla.
const RAGGIO_RADAR_SPENTO := 0.0
const RAGGIO_RADAR := 300.0

## Quanto rende un forziere con e senza il taccuino. È il solo modulo che paga in
## valuta, ed è messo lì apposta: è l'unico che chiede di rinunciare a una
## comodità adesso per comprare qualcosa di più grosso dopo. Vale **solo sui
## forzieri** — quello che si trova — e mai sul premio di una prova: la
## ricompensa di una prova non è merce.
const RESA_PIENA := 1.0
const RESA_TACCUINO := 1.18

## Gli identificativi dei moduli, per gli audit e per la bottega.
static func ids() -> Array:
	return CATALOGO.duplicate()

## Quanti posti ha la bardatura a questo punto della campagna.
static func posti(save) -> int:
	if save == null:
		return POSTI_BASE
	var livello := int(save.level())
	var totale := POSTI_BASE
	if livello >= LIVELLO_TERZO_POSTO:
		totale += 1
	if livello >= LIVELLO_QUARTO_POSTO:
		totale += 1
	return totale

static func posseduto(save, id: String) -> bool:
	if save == null:
		return false
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	return Array(cosmetics.get("inventory", [])).has(id)

## I moduli posseduti, in ordine di catalogo. È la lista da cui si sceglie.
static func posseduti(save) -> Array:
	var out: Array = []
	for id in CATALOGO:
		if posseduto(save, str(id)):
			out.append(str(id))
	return out

## **La bardatura, ripulita.** Legge la chiave del salvataggio e la riconcilia
## con la realtà: niente che non sia un modulo, niente che non si possieda,
## niente oltre i posti disponibili. Un salvataggio vecchio, o uno in cui i posti
## siano cambiati sotto i piedi, non deve poter regalare un effetto in più.
static func bardatura(save) -> Array:
	if save == null:
		return []
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	var grezza: Array = Array(cosmetics.get("loadout", []))
	var out: Array = []
	var massimo := posti(save)
	for id_data in grezza:
		var id := str(id_data)
		if out.size() >= massimo:
			break
		if CATALOGO.has(id) and posseduto(save, id) and not out.has(id):
			out.append(id)
	return out

static func in_bardatura(save, id: String) -> bool:
	return bardatura(save).has(id)

static func posti_liberi(save) -> int:
	return maxi(0, posti(save) - bardatura(save).size())

static func _scrivi_bardatura(save, lista: Array) -> void:
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	cosmetics["loadout"] = lista.duplicate()
	save.data["cosmetics"] = cosmetics

## Mettere un modulo in bardatura. Falso se non si possiede, se c'è già, o se i
## posti sono finiti: la scelta di che cosa togliere resta al giocatore, perché
## una bardatura che si riorganizza da sola non è la decisione di nessuno.
static func porta(save, id: String) -> bool:
	if save == null or not posseduto(save, id) or in_bardatura(save, id):
		return false
	if posti_liberi(save) <= 0:
		return false
	var lista := bardatura(save)
	lista.append(id)
	_scrivi_bardatura(save, lista)
	return true

static func lascia(save, id: String) -> bool:
	if save == null or not in_bardatura(save, id):
		return false
	var lista := bardatura(save)
	lista.erase(id)
	_scrivi_bardatura(save, lista)
	return true

## **Comprato è portato, se c'è posto.** Un bambino che spende ottocento
## frammenti e non vede succedere niente ha imparato che comprare non serve — la
## stessa lezione che il catalogo «che si scusava» insegnava a parole. Quando i
## posti sono pieni non si scavalca niente: la bottega lo dice, e la scelta di
## che cosa lasciare a bordo resta di chi ha pagato.
static func porta_se_c_e_posto(save, id: String) -> bool:
	return CATALOGO.has(id) and porta(save, id)

## Quanto lontano una sacca si accorge di Eli, in frazione della sua vista
## piena. L'andatura felpata la accorcia; senza il modulo resta uno.
static func vista_delle_sacche(save) -> float:
	return VISTA_FELPATA if in_bardatura(save, FELPA) else VISTA_PIENA

## Quanto lontano butta uno spintone.
static func spinta_del_morso(save) -> float:
	return SPINTA_ZAVORRATA if in_bardatura(save, ZAVORRA) else SPINTA_PIENA

## Quanto veloce cammina Eli fuori dalla nave.
static func passo(save) -> float:
	return PASSO_SPEDIZIONE if in_bardatura(save, PASSO) else PASSO_BASE

## Il raggio del cono della torcia. Lo consuma `ExpeditionModulePresentation`,
## che lo accende soltanto con la torcia in mano.
static func raggio_torcia(save) -> float:
	return RAGGIO_TORCIA if in_bardatura(save, RIFLETTORE) else RAGGIO_TORCIA_SPENTO

## Il raggio entro cui i forzieri chiusi si segnalano.
static func raggio_radar(save) -> float:
	return RAGGIO_RADAR if in_bardatura(save, RABDOMANTE) else RAGGIO_RADAR_SPENTO

## Il moltiplicatore di quello che rende un forziere. Solo i forzieri.
static func resa_dei_forzieri(save) -> float:
	return RESA_TACCUINO if in_bardatura(save, TACCUINO) else RESA_PIENA
