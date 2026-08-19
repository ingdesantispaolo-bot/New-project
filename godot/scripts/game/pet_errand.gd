class_name PetErrand
extends RefCounted

## **LE TANE: il Custode fa qualcosa.** (19 agosto 2026)
##
## Il difetto, misurato leggendo il gioco: il Custode ha diciotto segnali, dieci
## espressioni, quattro indoli, sedici combinelle, un legame che sale, i regali,
## e Lucilla che gli parla — e **non fa mai niente**. È uno specchio affettivo
## con una freccia sopra. `STATO_CONTENUTI_E_NARRATIVA` §3.3f lo dice della
## storia («è narrativamente muto»); vale identico per il gioco.
##
## E c'è un secondo difetto che questa cosa risolve insieme al primo: **tutte e
## dodici le cose interattive della mappa finivano in un pannello.** Avvicinati,
## premi, si apre una finestra. La tana è la prima interazione del gioco in cui
## si preme e non si apre niente: si **guarda il proprio compagno andare**.
##
## ## La forma
##
## Una fenditura, una tana, un tubo crollato: un posto in cui Eli non entra e il
## Custode sì. Si manda lui. Sparisce dentro, si sente rumore, e dopo qualche
## secondo esce — con un regalo, con una manciata di frammenti, o con niente e
## una figura barbina, che è l'esito più frequente e il migliore.
##
## ## I guard-rail, che sono quelli di sempre
##
## Il Custode **non dà vantaggi di gioco** (`pet_state.gd`). Quindi da una tana
## non esce mai energia, mai padronanza, mai un pezzo di gate, mai uno strumento.
## Escono **frammenti** — cioè cosmetici — e **regali**, che per contratto non
## servono a niente. È la stessa linea che rende lecito mettere un duello davanti
## a un forziere: si può chiudere solo ciò che non serve a imparare.
##
## E non si può fallire: una tana dà sempre qualcosa, foss'anche solo una riga.
## Non c'è modo di sprecarla, non c'è un tempo, non c'è un'abilità. È l'unico
## posto del gioco che non chiede niente a nessuno.

## Quanto ci mette là dentro. Quattro secondi: abbastanza da diventare un'attesa
## — che è la ragione per cui la scena esiste — e non tanto da annoiare chi ne
## trova la seconda.
const DURATA := 4.0

## Gli esiti, con quanto pesano. La figura barbina vince su tutto perché è la
## cosa che il Custode fa meglio, ed è l'unica che non si può comprare altrove.
const ESITI := [
	{"id": "niente", "peso": 5},
	{"id": "regalo", "peso": 3},
	{"id": "frammenti", "peso": 2},
]

## I frammenti di una tana andata bene. Pochi: un forziere di lascito ne vale
## dieci volte tanto, e una tana che pagasse come un forziere insegnerebbe a
## cercare tane invece che a giocare.
const FRAMMENTI := 18

## Che cosa si vede da fuori. La tana non promette niente — non ha un cartello
## con scritto «premio» — perché la cosa che si va a prendere non è il contenuto.
const DESCRIZIONI := [
	"Una fenditura nella roccia, larga un gatto.",
	"Un tubo crollato che continua sotto la terra.",
	"Una tana sotto le radici, con l'erba pettinata all'ingresso.",
	"Una crepa nel muro dei Primi, con l'aria che ne esce tiepida.",
	"Un buco fra due lastre, e dentro qualcosa che luccica appena.",
]

## Quando Eli non ha ancora un Custode. Non è un rifiuto: è un'informazione, e
## dice esattamente di che cosa ci sarebbe bisogno.
const SENZA_CUSTODE := "Là sotto non ci passi. Ci vorrebbe qualcuno più piccolo di te."

## La riga con cui lo si manda. Il nome del Custode arriva da fuori.
static func riga_di_partenza(nome: String) -> String:
	var chi := nome.strip_edges()
	return "%s si infila dentro senza pensarci un attimo." % (chi if chi != "" else "Il Custode")

## L'esito, deciso dall'identificativo della tana: la stessa tana dà sempre la
## stessa cosa, in questa partita e nella prossima. Una tana che cambiasse premio
## fra un tentativo e l'altro insegnerebbe soltanto a riprovare — ed è la ragione
## per cui non si può riprovare comunque (una tana svuotata resta svuotata).
static func esito_di(tana_id: String) -> String:
	var totale := 0
	for voce in ESITI:
		totale += int(Dictionary(voce)["peso"])
	var tiro := posmod(hash("%s:tana" % tana_id), totale)
	for voce in ESITI:
		tiro -= int(Dictionary(voce)["peso"])
		if tiro < 0:
			return str(Dictionary(voce)["id"])
	return "niente"

static func descrizione_di(tana_id: String) -> String:
	return str(DESCRIZIONI[posmod(hash("%s:desc" % tana_id), DESCRIZIONI.size())])

## Le figure barbine: quello che il Custode riporta quando non riporta niente.
## Sono la maggioranza degli esiti ed è voluto — il momento è lui che esce, non
## quello che ha in bocca.
const BARBINE := [
	"Esce a marcia indietro, con una ragnatela in testa, e finge che fosse il piano.",
	"Esce, si guarda intorno con aria di trionfo, e non ha portato assolutamente niente.",
	"Rimane incastrato un secondo, si libera da solo, e ti guarda come se non fosse successo.",
	"Esce starnutendo tre volte di fila. Dentro c'era solo polvere.",
	"Torna con la faccia di chi ha visto qualcosa di enorme. Non c'era niente.",
	"Esce dalla parte sbagliata, a sei passi da dove era entrato, e sembra sorpreso quanto te.",
]

static func barbina_di(tana_id: String) -> String:
	return str(BARBINE[posmod(hash("%s:barbina" % tana_id), BARBINE.size())])

## Il commento di NORA. Non ride del Custode — non è mai il bersaglio di nessuno
## tranne sé stesso — e non spiega la battuta: prende appunti, che è la cosa più
## divertente che possa fare e insieme quello che è.
const APPUNTI := [
	"NORA: «Annotato. Metodo: entrare. Risultato: uscire».",
	"NORA: «Sto tenendo un registro di queste spedizioni. Non ha ancora una colonna dei successi».",
	"NORA: «Interessante. Ho scritto “interessante” perché non sapevo cos'altro scrivere».",
	"NORA: «Il tuo compagno ha una teoria. Non me l'ha spiegata».",
]

static func appunto_di(tana_id: String) -> String:
	return str(APPUNTI[posmod(hash("%s:nora" % tana_id), APPUNTI.size())])
