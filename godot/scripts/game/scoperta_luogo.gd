class_name ScopertaLuogo
extends RefCounted

## **Un posto si nota prima di potersi leggere.** (10 settembre 2026)
##
## Secondo lotto della corsia del percorso studente (`docs/PERCORSO_STUDENTE.md`).
## Il primo ha dato un nome ai posti; questo decide **da quanto lontano quel nome
## si legge**, ed e' il pezzo che separa una mappa con gli spilli da un paesaggio.
##
## ## La misura che sta sotto
##
## La finestra e' 1280x720 unita' di mondo e la telecamera non ha zoom: da dove
## sta Eli il bordo dello schermo e' a 640 unita' in orizzontale e 360 in
## verticale, cioe' **734 di mezza diagonale**. Le targhette dei diciotto punti
## d'interesse erano opache sempre: appena un posto entrava nello schermo il suo
## nome era gia' leggibile. Tradotto in gioco: **non esiste il momento in cui hai
## visto qualcosa e non sai ancora che cos'e'** — e quel momento e' l'unico
## contenuto che l'esplorazione abbia mai avuto da offrire.
##
## ## Perche' NON si generalizza il segnale del mondo 1
##
## `_make_world1_discovery_cue` disegna un rombo su un'asta sopra il punto
## d'interesse. Accenderlo su tutti e ventiquattro i mondi — che era la prima
## idea, scritta nel piano — significherebbe **432 spilli fluttuanti**: sarebbe
## rispondere a «sembra un elenco» aggiungendo icone all'elenco. Il rombo resta
## dov'e', sui sette punti di gate della Radura, che e' la fetta verticale in cui
## e' stato collaudato.
##
## Quello che si generalizza e' la **grammatica**, cioe' `discoveryCue`, che il
## direttore calcola per tutti i punti di tutti i mondi e che fuori dagli audit
## non leggeva nessuno. Il socket dichiara gia' quanto e' vistoso il posto su cui
## sta la prova:
##
##   `distant_signal`  regioni, landmark e varchi — cose grandi, fatte per essere
##                     viste da lontano. Il nome si legge quasi appena entrano
##                     nello schermo;
##   `local_clue`      strumenti — un banco, una bilancia, un leggio. Si vede che
##                     c'e' qualcosa; per sapere che cos'e' bisogna avvicinarsi;
##   `proximity`       i cippi lungo i sentieri. **Non si annunciano**: si
##                     trovano camminandoci accanto.
##
## ## Le due garanzie che rendono la cosa sicura
##
## **Niente diventa irraggiungibile.** Cambia solo l'opacita' di un'etichetta: il
## nodo, la collisione, il raggio d'interazione e PORTAMI restano identici. Un
## bambino che apre il quadro degli obiettivi e preme PORTAMI arriva al cippo
## esattamente come prima — il pavimento di accessibilita' non si tocca, e' la
## regola di tutta la corsia.
##
## **In alto contrasto i nomi restano accesi.** Chi ha bisogno di leggere tutto
## non deve pagare l'atmosfera: la dissolvenza e' un effetto, e gli effetti si
## spengono. Vale anche per il movimento ridotto, dove il nome si accende di
## colpo invece di sfumare.

const DISTANT_SIGNAL := "distant_signal"
const LOCAL_CLUE := "local_clue"
const PROXIMITY := "proximity"

## Da quanto lontano il **nome** di un posto si legge, per grammatica del luogo.
##
## I tre numeri stanno sotto la mezza diagonale dello schermo (734) e sopra il
## raggio d'interazione (88): dentro questa forbice c'e' spazio per tutti e tre i
## momenti — vedo che c'e' qualcosa, capisco che cos'e', ci arrivo.
const LETTURA := {
	DISTANT_SIGNAL: 620.0,
	LOCAL_CLUE: 380.0,
	PROXIMITY: 220.0,
}

## Il ripiego per una grammatica sconosciuta e' **la piu' generosa**, non la piu'
## stretta: se un giorno la composizione dichiarasse un `visibility` nuovo, il
## difetto dev'essere un nome che si legge troppo presto — brutto e innocuo — e
## mai un nome che non si legge mai, che somiglia a un posto rotto.
const LETTURA_RIPIEGO := 620.0

## L'ultimo tratto prima della distanza di lettura, in cui il nome sfuma invece
## di comparire di colpo. Centoquaranta unita' sono circa un secondo di cammino:
## abbastanza perche' si veda che sta arrivando, troppo poco per aspettare fermi.
const DISSOLVENZA := 140.0

static func distanza_di_lettura(cue: String) -> float:
	return float(LETTURA.get(cue, LETTURA_RIPIEGO))

## Un posto di questa grammatica si fa notare da lontano?
##
## Falso per `proximity`, ed e' l'unico buco voluto della mappa: i cippi lungo i
## sentieri sono la cosa che si trova camminando invece che leggendo. Restano
## raggiungibili con PORTAMI, quindi il buco non chiude niente a nessuno.
static func si_annuncia(cue: String) -> bool:
	return cue != PROXIMITY

## Quanto e' leggibile il nome di questo posto da questa distanza: 0 invisibile,
## 1 pieno.
##
## `sempre_leggibile` e' l'alto contrasto: la dissolvenza e' atmosfera, e
## l'atmosfera non puo' costare la leggibilita' a chi ne ha bisogno.
## `senza_sfumatura` e' il movimento ridotto: acceso o spento, niente rampa.
static func opacita_del_nome(
	cue: String, distanza: float,
	sempre_leggibile: bool = false, senza_sfumatura: bool = false
) -> float:
	if sempre_leggibile:
		return 1.0
	var soglia := distanza_di_lettura(cue)
	if distanza <= soglia:
		return 1.0
	if senza_sfumatura:
		return 0.0
	if distanza >= soglia + DISSOLVENZA:
		return 0.0
	return clampf(1.0 - (distanza - soglia) / DISSOLVENZA, 0.0, 1.0)
