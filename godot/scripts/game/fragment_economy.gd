class_name FragmentEconomy
extends RefCounted

## **L'economia dei frammenti, in un posto solo.** (14 agosto 2026)
##
## Nasce da un difetto che era rimasto invisibile perché nessuno l'aveva mai
## sommato: i frammenti avevano **solo sorgenti e nessuno scarico**. La bottega
## si pagava in energia (`OutdoorGameplay.try_purchase_cosmetic` chiamava
## `spend_energy`), i moduli di spedizione pure, e `spend_fragments` non esisteva
## proprio. Il numero viola nell'HUD saliva per ventiquattro mondi e non comprava
## niente — e i forzieri che lo producevano erano, di conseguenza, una
## distrazione con una ricompensa immaginaria.
##
## **La correzione è separare i due lavori dell'energia.** Prima l'energia faceva
## due mestieri in conflitto: pagava l'ingresso alle prove *e* comprava i
## cosmetici. Misurato da `economy_probe`, il catalogo costa il 59–74% di tutta
## l'energia che una campagna produce: comprarsi un cappello **competeva con
## l'allenarsi**, che in un gioco che si studia è l'incentivo storto peggiore che
## si possa mettere in un'economia. Adesso:
##
##   ENERGIA     la fa lo studio, la spendono le prove. Non compra più niente.
##   FRAMMENTI   li fa l'esplorazione, li spende la bottega.
##
## Chi esplora si compra la bellezza; chi non esplora non perde niente di
## didattico, perché nessun cosmetico tocca una domanda (decisione vincolante 15,
## `ExpeditionModules`). E il Lascito continua a **non pesare i frammenti**
## (`LegacyScore`): il finale resta l'unica cosa che non si compra.
##
## **La taratura non è a occhio.** `fragment_economy_probe` conta i forzieri
## generati nei ventiquattro mondi con gli stessi vincoli del gioco: 1018
## raggiungibili, 6374 frammenti alle tariffe vecchie, cioè **17,6 volte meno di
## quanto costa il catalogo**. Le tariffe qui sotto portano quel rapporto dove
## stava l'energia prima della separazione — una campagna intera compra circa due
## terzi del catalogo, mai tutto: un catalogo comprabile per intero è un catalogo
## senza scelte.

## Quanto vale una prova risolta nel mondo. Le tre tariffe stanno nello stesso
## rapporto di prima (3 / 2 / 4): a cambiare è la scala, non l'equilibrio fra le
## fonti — quello era già stato tarato e non c'era ragione di rifarlo.
const PREMIO_INCONTRO := 35
const PREMIO_MISSIONE := 25
const PREMIO_RIPARAZIONE := 50

## La camera del mondo: la si apre una volta sola per mondo, dietro una serratura
## che chiede la materia. È la fonte fissa più ricca, e deve restare la più ricca.
const PREMIO_CAMERA := 150

## Il minigioco di un personaggio: si vince una volta sola, e la ricompensa vera
## è quello che cambia nel suo luogo. I frammenti sono il di più.
const PREMIO_MINIGIOCO := 45

## Il varco: sciogliere la guardiana che sorveglia un forziere. Cresce col tier
## perché la prova cresce, e sta sotto al forziere che protegge — il premio è la
## cassa, non il duello.
static func premio_varco(tier: int) -> int:
	return clampi((3 + tier) * 11, 45, 125)

## Il Pericolo del Mondo e' unico, visibile e richiede una prova completa. Paga
## meno di un lascito ricco perche' la ricompensa principale e' il Sigillo nel
## ritratto delle Quattro Vie, ma abbastanza da avvicinare davvero un acquisto.
## Ventiquattro vittorie aggiungono 3.320 frammenti alla campagna: una fonte
## misurabile, non un rubinetto infinito.
static func premio_pericolo(threat_tier: int) -> int:
	return 80 + clampi(threat_tier, 1, 5) * 20
