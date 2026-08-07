class_name ReflexDuel
extends RefCounted

## **Il varco: come si scioglie una sacca di Silenzio.** (7 agosto 2026)
##
## Richiesta del committente: gli Sbiaditi devono essere **un pericolo vero**,
## devono **sorvegliare i forzieri**, e si devono poter **eliminare con un
## minigioco di riflessi, in base al progresso del personaggio**.
##
## **Perché di riflessi, e non l'ennesimo esercizio.** Tutto il gioco chiede di
## pensare; questo chiede di *reagire*. È l'unico momento in cui il tempo conta,
## e proprio per questo deve stare **lontano dalle domande** — un cronometro
## sopra una domanda di matematica misura la velocità di lettura, che è l'ultima
## cosa da punire qui. Sopra un varco che si apre e si chiude, invece, il
## cronometro è il gioco.
##
## **Che cosa protegge, e perché si può fare.** Gli Sbiaditi presidiano i
## forzieri, cioè i **frammenti**, cioè i cosmetici. Non presidiano niente che
## serva a progredire: chi non vuole giocare di riflessi finisce la campagna
## esattamente come prima, e si perde solo i vestiti. È la condizione che rende
## lecita una prova di abilità in un gioco che si studia — e se un giorno
## qualcosa di necessario finisse dietro una sacca, questa riga sarebbe la prova
## che è stato un errore.
##
## **Il progresso conta, e conta molto.** Tre leve si muovono insieme con il
## grado di potenza di Eli ([[WorldLight]]):
##
##   - il **varco è più largo** (più tempo utile per colpire);
##   - il **cursore va più piano**;
##   - si possono **sbagliare più colpi** prima di perdere.
##
## E tutte e tre si muovono al contrario con il grado della sacca. Il risultato
## è che una sacca molto più forte di Eli è **oggettivamente difficile** invece
## che semplicemente costosa: è la differenza fra un pedaggio e un pericolo, ed
## era il punto della richiesta.

## Larghezza del varco a grado zero contro una sacca di grado uno, in pixel di
## semi-ampiezza. Il resto sono correzioni.
const VARCO_BASE := 44.0
## Quanto si allarga il varco per ogni grado di potenza di Eli.
const VARCO_PER_GRADO := 11.0
## Quanto si stringe per ogni grado della sacca.
const VARCO_PER_TIER := 5.0
## Sotto questa semi-ampiezza non si scende: un varco che nessun riflesso umano
## puo' centrare non e' difficile, e' rotto — e a un bambino di undici anni
## insegnerebbe soltanto che il gioco bara.
const VARCO_MINIMO := 15.0

## Velocita' del cursore a grado zero contro una sacca di grado uno, px/s.
const VELOCITA_BASE := 250.0
const VELOCITA_PER_TIER := 34.0
const VELOCITA_PER_GRADO := 20.0
const VELOCITA_MINIMA := 150.0
## Oltre questa velocita' il cursore diventa una sfarfallio invece che un
## bersaglio: la difficolta' deve restare leggibile.
const VELOCITA_MASSIMA := 620.0

## Quanto e' larga la pista su cui il cursore va avanti e indietro.
const PISTA := 520.0

## I colpi da mettere a segno, e gli errori concessi.
static func colpi_richiesti(tier: int) -> int:
	return clampi(2 + floori(float(tier) / 2.0), 2, 5)

## **Gli errori concessi crescono solo con Eli.** È la leva più generosa delle
## tre, di proposito: allargare il varco aiuta chi ha già riflessi buoni,
## concedere errori aiuta chi non ne ha — e sono gli stessi bambini che non
## devono essere esclusi da un premio estetico.
static func errori_ammessi(grado: int) -> int:
	return clampi(1 + grado, 1, 5)

static func semi_varco(tier: int, grado: int) -> float:
	return maxf(
		VARCO_MINIMO,
		VARCO_BASE + float(grado) * VARCO_PER_GRADO - float(tier - 1) * VARCO_PER_TIER)

static func velocita(tier: int, grado: int) -> float:
	return clampf(
		VELOCITA_BASE + float(tier - 1) * VELOCITA_PER_TIER - float(grado) * VELOCITA_PER_GRADO,
		VELOCITA_MINIMA, VELOCITA_MASSIMA)

## Tutti i parametri di un duello, in un colpo solo. La scena non ricalcola
## niente di suo: se la difficolta' va ritarata, si ritara qui e l'audit se ne
## accorge.
static func regole(tier: int, grado: int) -> Dictionary:
	return {
		"tier": tier,
		"grado": grado,
		"colpi": colpi_richiesti(tier),
		"errori": errori_ammessi(grado),
		"semiVarco": semi_varco(tier, grado),
		"velocita": velocita(tier, grado),
		"pista": PISTA,
	}

## Il colpo e' andato a segno? `cursore` e `centro` sono posizioni sulla pista.
static func colpito(cursore: float, centro: float, semi: float) -> bool:
	return absf(cursore - centro) <= semi

## **Quanto e' onesta questa difficolta'**, come frazione della pista coperta dal
## varco: e' la probabilita' di centrare a caso, e serve all'audit per dire che
## nessuna combinazione di gradi produce un duello impossibile o regalato.
static func quota_utile(tier: int, grado: int) -> float:
	return clampf(2.0 * semi_varco(tier, grado) / PISTA, 0.0, 1.0)

## Quanto costa perdere: la stessa formula del morso, perche' perdere un duello
## non deve essere peggio che farsi respingere — chi ci prova e sbaglia non puo'
## stare peggio di chi gira alla larga.
static func costo_sconfitta(tier: int, grado: int) -> int:
	return maxi(0, tier - grado) * WorldEnemy.COSTO_PER_GRADO

## Il premio: frammenti. Cresce con la sacca, perche' una sacca piu' forte e'
## una prova piu' difficile, e non con il grado di Eli — allenarsi rende la
## prova piu' facile, e sarebbe doppio anche pagarla di piu'.
static func premio_frammenti(tier: int) -> int:
	return clampi(3 + tier, 4, 11)
