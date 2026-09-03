class_name FieldTools
extends RefCounted

## **Gli strumenti non si comprano: te li dà chi li usa.** (14 agosto 2026)
##
## La torcia e la falce sono le uniche due voci del catalogo che **aprono il
## mondo** invece di decorarlo: senza, certe deviazioni restano chiuse. Erano
## anche le due più economiche — 140 e 180 — e con l'economia dei frammenti
## tarata il 14 agosto un solo forziere di lascito (240–320) le pagava entrambe.
## Le uniche due chiavi del gioco erano diventate un acquisto automatico al primo
## baule.
##
## Ribilanciare il prezzo sarebbe stato il rimedio ovvio e sbagliato: qualunque
## cifra si scelga, resta una riga di listino. **Il difetto vero era che
## stessero in vendita.** Una torcia comprata è un numero che scende; una torcia
## che ti mette in mano il fabbro dopo che gli hai rimesso in piedi il mulino è
## un momento — e a costo zero di contenuto, perché la scena in cui succede
## esiste già ed è la minimissione.
##
## ---
##
## # L'arcipelago (19 agosto 2026)
##
## **Il difetto misurato:** gli strumenti erano **due**, consegnati entrambi
## entro il mondo 2. Dal mondo 3 in poi non esisteva più, in tutta la campagna,
## **una sola porta chiusa**. Un gioco con due chiavi date subito non ha
## verticalità: ha un tutorial sugli attrezzi e poi ventidue mondi piatti.
##
## E i mondi erano già rivisitabili dalla navigazione della nave — mancava solo
## la **ragione** per tornarci.
##
## Adesso gli strumenti sono **cinque**, distribuiti sull'arco della campagna, e
## ognuno riapre i mondi che stanno dietro:
##
## | strumento | mondo | materia ospite | che cosa apre |
## |---|---:|---|---|
## | Torcia | 1 | matematica | l'oscurità |
## | Falce | 2 | italiano | l'erba alta |
## | Leva dei Primi | 5 | fisica | le lastre sigillate |
## | Lente dei Primi | 7 | latino | le iscrizioni illeggibili |
## | Soffietto | 11 | storia | i banchi di Silenzio denso |
##
## Ogni strumento è la **materia del mondo che lo consegna**, e non è un
## abbellimento: la leva è il gesto della fisica, la lente quello del latino, il
## soffietto quello di chi scava. Chi riceve l'attrezzo ha appena passato una
## settimana di gioco su quella materia.
##
## **Come si torna indietro.** Il salvataggio registra le porte che hai visto e
## non potevi aprire (`toolGates`): quando l'attrezzo arriva, il gioco ti dice in
## quali mondi ti sta aspettando qualcosa. Senza quel registro un nuovo strumento
## sarebbe soltanto una riga di dialogo — è l'elenco che trasforma ventiquattro
## mondi in fila in un arcipelago.
##
## ---
##
## **Quando arriva.** Alla **prima riparazione portata a termine in un mondo**
## (`OutdoorGameplay.minimission_completed`), se ne è dovuto ancora uno *per quel
## mondo o per uno precedente*. Le minimissioni prendono il posto del primo
## evento-gate del mondo (`MinimissionCatalog`), quindi ci passano tutti: nessun
## bambino può restare senza strumenti per non aver esplorato abbastanza — che
## sarebbe il modo peggiore di legare l'esplorazione all'esplorazione. E chi
## salta la riparazione di un mondo riceve comunque l'arretrato al mondo dopo.
##
## Guard-rail, invariati: la consegna **non costa niente**, non toglie frammenti,
## non tocca energia né padronanza, e non può essere mancata. Uno strumento è una
## chiave, e in questo gioco le chiavi non si vendono a chi impara. E **niente di
## necessario sta dietro un attrezzo**: solo deviazioni — forzieri, palestre
## facoltative, tracce — mai un evento che apra il livello.

const TORCIA := "tool-torch"
const FALCE := "tool-scythe"
const LEVA := "tool-lever"
const LENTE := "tool-lens"
const SOFFIETTO := "tool-bellows"

## Il catalogo, in ordine di consegna. `mondo` è il primo mondo in cui lo si può
## ricevere; `ostacolo` e `arnese` sono le parole con cui il gioco ne parla
## quando una porta resta chiusa, e stanno qui perché la scena non deve avere una
## catena di `if` che cresce a ogni attrezzo nuovo.
##
## `blocca` dice se l'ostacolo è **fisico** (una collisione che ferma il passo)
## o soltanto di lettura. Torcia e lente non bloccano: rivelano. È la differenza
## fra «non ci passi» e «non ci capisci niente», e sono due sensazioni diverse
## che meritavano due forme diverse.
const STRUMENTI := [
	{
		"id": TORCIA, "mondo": 1, "blocca": false,
		"nome": "la Torcia da ricognizione",
		"ostacolo": "Oscurità impenetrabile",
		"consegna": "%s ti mette in mano una torcia: «Là sotto non ci si vede. Tienila tu, io di notte non ci vado più».",
		"consegna_anonima": "Qualcuno ti lascia una torcia sul bordo del lavoro finito. Là sotto non ci si vede.",
	},
	{
		"id": FALCE, "mondo": 2, "blocca": true,
		"nome": "la Falce da campo",
		"ostacolo": "Erba alta invalicabile",
		"consegna": "%s ti allunga la falce: «L'erba alta ricresce comunque. Almeno tu passa».",
		"consegna_anonima": "Sul lavoro finito resta una falce, con il manico riavvolto di fresco. L'erba alta ricresce comunque.",
	},
	{
		"id": LEVA, "mondo": 5, "blocca": true,
		"nome": "la Leva dei Primi",
		"ostacolo": "Lastra sigillata",
		"consegna": "%s ti passa una barra di ferro nero: «I Primi chiudevano tutto con le pietre. Non erano forti — sapevano dove spingere».",
		"consegna_anonima": "Appoggiata al lavoro finito c'è una barra di ferro nero, lucida da una parte sola. I Primi chiudevano tutto con le pietre.",
	},
	{
		"id": LENTE, "mondo": 7, "blocca": false,
		"nome": "la Lente dei Primi",
		"ostacolo": "Iscrizione illeggibile",
		"consegna": "%s ti mette in mano un disco di vetro spesso: «Le scritte sbiadite ci sono ancora. È l'occhio che non arriva più».",
		"consegna_anonima": "Sul lavoro finito qualcuno ha lasciato un disco di vetro spesso, con il bordo consumato dalle dita. Le scritte sbiadite ci sono ancora.",
	},
	{
		"id": SOFFIETTO, "mondo": 11, "blocca": true,
		"nome": "il Soffietto",
		"ostacolo": "Banco di Silenzio denso",
		"consegna": "%s ti allunga un soffietto da forgia: «Il Silenzio si posa come la polvere. E come la polvere, si soffia via».",
		"consegna_anonima": "Sul lavoro finito resta un soffietto da forgia, con il cuoio rappezzato. Il Silenzio si posa come la polvere.",
	},
]

## L'ordine di consegna, per identificativo.
const ORDINE := [TORCIA, FALCE, LEVA, LENTE, SOFFIETTO]

static func ids() -> Array:
	return ORDINE.duplicate()

static func is_field_tool(cosmetic_id: String) -> bool:
	return ORDINE.has(cosmetic_id)

## La voce del catalogo, **per riferimento**.
##
## La prima stesura tornava `duplicate(true)`, e questa funzione sta sotto a
## `mondo_di`, `nome`, `ostacolo` e `blocca`: una copia profonda per ogni
## etichetta disegnata, per ogni varco costruito, per ogni riga di prompt. Il
## catalogo è una costante e nessuno lo scrive; copiarlo era un costo puro.
static func voce(id: String) -> Dictionary:
	for strumento in STRUMENTI:
		if str(Dictionary(strumento)["id"]) == id:
			return strumento
	return {}

## Il mondo in cui questo strumento viene consegnato. Zero se non è uno strumento.
static func mondo_di(id: String) -> int:
	return int(voce(id).get("mondo", 0))

## Vero se l'ostacolo di questo strumento ferma il passo invece di limitarsi a
## nascondere. Torcia e lente rivelano; falce, leva e soffietto bloccano.
static func blocca(id: String) -> bool:
	return bool(voce(id).get("blocca", false))

## Come il gioco chiama l'ostacolo, quando la porta resta chiusa.
static func ostacolo(id: String) -> String:
	return str(voce(id).get("ostacolo", "Passaggio chiuso"))

## Come il gioco chiama l'attrezzo.
static func nome(id: String) -> String:
	return str(voce(id).get("nome", "lo strumento"))

## **Il prossimo strumento dovuto a questo mondo**, o stringa vuota.
##
## «Dovuto a questo mondo» e non «il prossimo in assoluto»: chi arriva al mondo 7
## senza aver mai finito una riparazione al 5 riceve prima la leva, poi la lente
## al mondo dopo. Gli arretrati non si perdono e non si accavallano — uno per
## riparazione, in ordine.
static func dovuto(reward_manager, livello: int) -> String:
	if reward_manager == null:
		return ""
	for strumento in STRUMENTI:
		var voce_strumento: Dictionary = strumento
		if int(voce_strumento["mondo"]) > livello:
			break
		if not reward_manager.owned(str(voce_strumento["id"])):
			return str(voce_strumento["id"])
	return ""

## Gli strumenti già consegnabili a questo mondo.
static func consegnati_entro(livello: int) -> Array:
	var out: Array = []
	for strumento in STRUMENTI:
		if int(Dictionary(strumento)["mondo"]) <= livello:
			out.append(str(Dictionary(strumento)["id"]))
	return out

## **Gli strumenti che possono chiudere una porta in questo mondo**: quelli già
## consegnabili, **più il prossimo**.
##
## Il «più uno» è tutta la verticalità di questo lotto. Senza, un mondo
## conterrebbe solo porte che il giocatore può già aprire e non ci sarebbe niente
## da lasciarsi indietro; con due o tre attrezzi di anticipo, mezzo mondo sarebbe
## chiuso al primo passaggio e l'esplorazione diventerebbe una lista di rimandi.
## Uno solo: c'è sempre qualcosa che non si apre, e non è mai troppo.
static func varchi_del_mondo(livello: int) -> Array:
	var out := consegnati_entro(livello)
	for strumento in STRUMENTI:
		var id := str(Dictionary(strumento)["id"])
		if not out.has(id):
			out.append(id)
			break
	return out

## La riga con cui lo consegna chi ti ha appena visto lavorare. Il nome di chi
## parla arriva da fuori: è il proprietario della riparazione, e cambia da mondo
## a mondo senza che questo file debba saperlo.
##
## Nessuna delle righe è un complimento: è gente che ti passa un attrezzo perché
## adesso ha senso che tu ce l'abbia, non perché sei stata brava.
static func riga_di_consegna(tool_id: String, chi: String) -> String:
	var strumento := voce(tool_id)
	if strumento.is_empty():
		return ""
	var nome_di_chi := chi.strip_edges()
	if nome_di_chi == "":
		return str(strumento.get("consegna_anonima", ""))
	return str(strumento.get("consegna", "%s ti passa un attrezzo.")) % nome_di_chi

## Il motivo che la bottega mostra quando qualcuno cerca uno strumento a listino.
## Non dice «non disponibile»: dice dove si prende, perché un rifiuto che non
## indirizza è solo una porta chiusa.
static func motivo_non_in_vendita() -> String:
	return "Non è in vendita: te lo dà chi lo usa, quando completi la prima riparazione del suo mondo."

## Indicazione completa e uniforme per bottega, varchi e guida del mondo.
## Se ogni schermata inventasse la propria frase, la falce finirebbe di nuovo
## per sembrare un acquisto mancante invece di una chiave guadagnata sul campo.
static func come_si_ottiene(id: String) -> String:
	var mondo := mondo_di(id)
	if mondo <= 0:
		return motivo_non_in_vendita()
	var titolo := str(WorldProfileCatalog.profile(mondo).get("title", "mondo %d" % mondo))
	return "NON SI COMPRA · Si riceve completando la prima riparazione del mondo %d, %s." % [
		mondo, titolo]
