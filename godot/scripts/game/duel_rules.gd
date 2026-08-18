class_name DuelRules
extends RefCounted

## **Le regole del combattimento, indipendenti dalla materia.** (17 agosto 2026)
##
## Nate il 16 agosto dentro [[GuardianDuel]], quando il duello era uno solo ed
## era di calcolo. Il giorno dopo il committente ne ha chiesto un secondo — di
## **italiano**, sui modi e i tempi verbali — con i guardiani che sfidano
## nell'una o nell'altra materia. Da lì la separazione: quello che riguarda il
## **combattimento** sta qui e vale per entrambi; quello che riguarda la
## **materia** sta in [[GuardianDuel]] (le cifre) e in [[VerbDuel]] (le voci).
##
## La divisione non è estetica. Un guardiano deve fare la stessa paura e chiedere
## lo stesso impegno qualunque cosa domandi: se la variante di italiano avesse
## una sua tenuta, una sua carica e un suo prezzo della sconfitta, i due duelli
## si scalibrerebbero l'uno rispetto all'altro alla prima modifica, e un bambino
## imparerebbe a cercare i guardiani della materia più conveniente invece di
## quelli che ha voglia di affrontare.
##
## Quello che è condiviso, e perché:
##
## - **quanti sigilli** porta il guardiano (il suo grado);
## - **quanta tenuta** ha Eli (il suo grado di potenza);
## - **quanto dura la carica**, e di quanto si accorcia a ogni sigillo;
## - **quanto costa perdere** e **quanto paga vincere**;
## - **quale materia** tocca a quale guardiano.
##
## Quello che resta alla materia: i numeri o le voci, le rune, il campo di gioco
## e la lunghezza della catena.

## **Il colpo di riserva.** I colpi concessi sono i passi della strada giusta più
## uno. Vale per entrambe le materie e per la stessa ragione: senza riserva un
## colpo sbagliato chiuderebbe lo scambio, e nessuno userebbe mai le rune che
## servono a rimediare — la sottrazione nel duello delle cifre, il ritorno
## all'indicativo in quello delle voci.
const COLPO_DI_RISERVA := 1

## Quanto tempo dà ogni grado di potenza di Eli, e quanto ne toglie ogni grado
## del guardiano: **allenarsi deve servire**, e un guardiano più forte deve
## essere più duro.
const SECONDI_PER_GRADO := 0.55
const SECONDI_PER_TIER := 0.5
## Il tetto del vantaggio: oltre, il grado massimo regalerebbe il duello.
const SECONDI_BONUS_MASSIMO := 3.5
## Il pavimento assoluto. Sei secondi e mezzo per tre colpi sono poco più di due
## secondi a colpo: sotto non si misura più la competenza, si misura la velocità
## del dito — che a un bambino non si insegna.
const SECONDI_MINIMI := 6.5

## Quanto si accorcia la carica dopo ogni sigillo spezzato. Il combattimento
## accelera mentre lo si vince.
const ACCELERAZIONE := 0.9

## Quanto si allunga tutto con `reduced_motion`.
const TEMPO_RIDOTTO := 1.4

## Le due materie. I nomi sono quelli che il gioco mostra sul cartiglio del
## guardiano, perché avvicinarsi sia una **scelta informata** e non una lotteria:
## sulla mappa si legge già se quel guardiano chiede conti o voci.
const CIFRE := "cifre"
const VOCI := "voci"
const MATERIE := [CIFRE, VOCI]
const NOMI_MATERIA := {CIFRE: "CONTI", VOCI: "VOCI"}

## **Che materia chiede questo guardiano.**
##
## Decisa dall'identificativo e non dal caso del momento: lo stesso guardiano
## chiede sempre la stessa cosa, in questa partita e nella prossima. Un guardiano
## che cambia materia fra un tentativo e l'altro toglierebbe senso al tornare —
## chi ha perso su una voce difficile deve poter tornare a **quella**, altrimenti
## allenarsi non paga e il duello diventa una slot machine.
##
## Non segue la materia del mondo, di proposito: le due materie devono comparire
## in tutti e ventiquattro i mondi, o un bambino che gioca il mondo di scienze
## non vedrebbe mai un verbo.
static func materia(guard_id: String) -> String:
	return str(MATERIE[posmod(hash(guard_id), MATERIE.size())])

## **Quanti sigilli porta un guardiano.** Cresce col suo grado, non col mondo: è
## la stessa cifra che decide quanto fa male il morso, e un guardiano che sulla
## mappa è più minaccioso deve esserlo anche da vicino.
static func sigilli_richiesti(tier: int) -> int:
	return clampi(2 + floori(float(tier - 1) / 3.0), 2, 4)

## **Quanti colpi può incassare Eli**, e cresce solo con il suo grado di potenza.
## È la leva più generosa, di proposito: dare più tempo aiuta chi è già rapido,
## dare più tenuta aiuta chi ci mette di più — e sono gli stessi bambini che non
## devono restare fuori da un premio estetico.
static func tenuta_di(grado: int) -> int:
	return clampi(2 + floori(float(grado) / 2.0), 2, 6)

## La carica, a partire dalla base della fascia della materia.
static func secondi_di(base: float, tier: int, grado: int, movimento_ridotto := false) -> float:
	var secondi := clampf(
		base + float(grado) * SECONDI_PER_GRADO - float(tier - 1) * SECONDI_PER_TIER,
		SECONDI_MINIMI, base + SECONDI_BONUS_MASSIMO)
	return secondi * TEMPO_RIDOTTO if movimento_ridotto else secondi

## La carica del sigillo N-esimo: si accorcia a ogni sigillo spezzato, mai sotto
## il minimo assoluto.
static func secondi_del_sigillo(regole_duello: Dictionary, sigilli_rotti: int) -> float:
	var secondi := float(regole_duello.get("secondi", 10.0))
	return maxf(SECONDI_MINIMI, secondi * pow(ACCELERAZIONE, float(maxi(sigilli_rotti, 0))))

## Quanto costa perdere: **la stessa formula del morso**, perché provarci e
## sbagliare non può stare peggio che girare alla larga. Se costasse di più, la
## scelta razionale sarebbe non giocare.
static func costo_sconfitta(tier: int, grado: int) -> int:
	return maxi(0, tier - grado) * WorldEnemy.COSTO_PER_GRADO

## Il premio: frammenti, cioè cosmetici. Cresce col guardiano e non col grado di
## Eli — allenarsi rende il duello più facile, e sarebbe doppio anche pagarlo di
## più. È lo stesso premio per entrambe le materie: **nessuna delle due può
## essere la strada conveniente**.
static func premio_frammenti(tier: int) -> int:
	return FragmentEconomy.premio_varco(tier)

## Il pezzo comune di regole che ogni materia mette nella propria tabella.
static func telaio(world_level: int, tier: int, grado: int, base_secondi: float,
		passi: int, movimento_ridotto: bool) -> Dictionary:
	return {
		"mondo": clampi(world_level, 1, 24),
		"tier": tier,
		"grado": grado,
		"sigilli": sigilli_richiesti(tier),
		"tenuta": tenuta_di(grado),
		"passi": passi,
		"colpi": passi + COLPO_DI_RISERVA,
		"secondi": secondi_di(base_secondi, tier, grado, movimento_ridotto),
	}

static func riga_di_vittoria(netto: bool) -> String:
	return "Duello netto: ogni sigillo al colpo giusto." if netto \
		else "L'ultimo sigillo si spezza."

static func riga_di_sconfitta() -> String:
	return "Il guardiano regge. Resta lì dov'è: si torna quando vuoi."
