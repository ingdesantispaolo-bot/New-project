class_name FieldTools
extends RefCounted

## **Gli strumenti non si comprano: te li dà chi li usa.** (14 agosto 2026)
##
## La torcia e la falce sono le uniche due voci del catalogo che **aprono il
## mondo** invece di decorarlo: senza, certe deviazioni restano chiuse
## (`ChunkManager` marca un forziere su tre con `requiredTool`). Erano anche le
## due più economiche — 140 e 180 — e con l'economia dei frammenti tarata il 14
## agosto un solo forziere di lascito (240–320) le pagava entrambe. Le uniche
## due chiavi del gioco erano diventate un acquisto automatico al primo baule.
##
## Ribilanciare il prezzo sarebbe stato il rimedio ovvio e sbagliato: qualunque
## cifra si scelga, resta una riga di listino. **Il difetto vero era che
## stessero in vendita.** Una torcia comprata è un numero che scende; una torcia
## che ti mette in mano il fabbro dopo che gli hai rimesso in piedi il mulino è
## un momento — e a costo zero di contenuto, perché la scena in cui succede
## esiste già ed è la minimissione.
##
## **Quando arriva.** Alla **prima riparazione portata a termine in un mondo**
## (`OutdoorGameplay.minimission_completed`), se ne manca ancora una. Le
## minimissioni prendono il posto del primo evento-gate del mondo
## (`MinimissionCatalog`), quindi ci passano tutti: nessun bambino può restare
## senza strumenti per non aver esplorato abbastanza — che sarebbe il modo
## peggiore di legare l'esplorazione all'esplorazione.
##
## **L'ordine è quello del bisogno**, non della bellezza: prima la torcia, perché
## il buio chiude più deviazioni dell'erba alta.
##
## Guard-rail: la consegna **non costa niente**, non toglie frammenti, non tocca
## energia né padronanza, e non può essere mancata. Uno strumento è una chiave,
## e in questo gioco le chiavi non si vendono a chi impara.

const TORCIA := "tool-torch"
const FALCE := "tool-scythe"

## L'ordine di consegna. Chi arriva alla seconda riparazione ha già la torcia e
## riceve la falce; chi le ha entrambe non riceve più niente.
const ORDINE := [TORCIA, FALCE]

static func ids() -> Array:
	return ORDINE.duplicate()

static func is_field_tool(cosmetic_id: String) -> bool:
	return ORDINE.has(cosmetic_id)

## Il prossimo strumento dovuto, o stringa vuota se li ha già tutti.
static func dovuto(reward_manager) -> String:
	if reward_manager == null:
		return ""
	for id in ORDINE:
		if not reward_manager.owned(str(id)):
			return str(id)
	return ""

## La riga con cui lo consegna chi ti ha appena visto lavorare. Il nome di chi
## parla arriva da fuori: è il proprietario della riparazione, e cambia da mondo
## a mondo senza che questo file debba saperlo.
##
## Le due righe dicono la stessa cosa in due modi, e nessuna delle due è un
## complimento: è gente che ti passa un attrezzo perché adesso ha senso che tu ce
## l'abbia, non perché sei stata brava.
static func riga_di_consegna(tool_id: String, chi: String) -> String:
	var nome := chi.strip_edges()
	if tool_id == TORCIA:
		return ("%s ti mette in mano una torcia: «Là sotto non ci si vede. Tienila tu, io di notte non ci vado più».") % nome \
			if nome != "" \
			else "Qualcuno ti lascia una torcia sul bordo del lavoro finito. Là sotto non ci si vede."
	return ("%s ti allunga la falce: «L'erba alta ricresce comunque. Almeno tu passa».") % nome \
		if nome != "" \
		else "Sul lavoro finito resta una falce, con il manico riavvolto di fresco. L'erba alta ricresce comunque."

## Il motivo che la bottega mostra quando qualcuno cerca uno strumento a listino.
## Non dice «non disponibile»: dice dove si prende, perché un rifiuto che non
## indirizza è solo una porta chiusa.
static func motivo_non_in_vendita() -> String:
	return "Non è in vendita: te lo dà chi lo usa, quando gli finisci una riparazione."
