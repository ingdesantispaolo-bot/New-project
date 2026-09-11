# La regola delle dispense: nessuna domanda senza un documento che la insegni

*Fissata l'11 settembre 2026, su richiesta del committente. Vale per tutte e
dodici le materie, senza eccezioni e senza scadenza.*

## La richiesta, parola per parola

> «Le prove devono essere applicazioni che lo studente deve fare di concetti
> spiegati. Non presumere che debba sapere concetti che nessuno gli ha spiegato
> e non è utile chiedere cose che non può sapere. Questo deve valere per tutte
> le materie. Le domande devono essere rielaborazione e utilizzo di un concetto
> spiegato. Nella storia ad esempio si deve preparare un documento da presentare
> allo studente dove si racconta un contesto preciso e dettagliato. Solo dopo si
> può fare una domanda. **La spiegazione di poche frasi di NORA non è
> sufficiente.**»

## Perché la frase finale è la parte importante

Il gioco aveva già tre difese contro la domanda impossibile, costruite una dopo
l'altra fra agosto e settembre, e ognuna ha riparato un difetto vero:

| Strato | Che cosa garantisce | Guardia |
|---|---|---|
| `KnowledgeCodex.mini_lesson` | ogni ARGOMENTO nuovo arriva con una scheda davanti | `teach_before_ask_audit` |
| `KnowledgeCodex.fact_lesson` | un ordinamento a insieme insegna i FATTI che pesca | `fact_level_teaching_audit` |
| `TavoleRiferimento` | una risposta-nome ha una linea del tempo o una carta su cui impararla | `tavole_riferimento_audit` |

Tutte e tre rispondono alla domanda «il bambino ha visto questa cosa almeno una
volta?». Nessuna risponde a «gli è stata **insegnata**?».

La differenza si misura, e il numero è questo. Costruendo per tutti i 300
argomenti del runtime la scheda che NORA mostrerebbe, e contando i soli
caratteri con cui NORA **spiega** — l'introduzione e il metodo, senza il testo
dell'esempio, che è un item del banco e non una spiegazione:

    tutte le materie   300 argomenti   media 290 caratteri
    matematica          40 argomenti   media 191
    logica               9 argomenti   media 264
    storia              14 argomenti   media 271
    coding              29 argomenti   media 276
    geografia           13 argomenti   media 276
    scienze             21 argomenti   media 287
    italiano            41 argomenti   media 297
    musica               9 argomenti   media 305
    inglese             60 argomenti   media 310
    fisica              24 argomenti   media 334
    elettronica         24 argomenti   media 352
    latino              16 argomenti   media 352

**Duecentonovanta caratteri: quarantacinque parole, tre frasi.** È esattamente
quello che il committente ha chiamato «poche frasi», e non è un difetto di
scrittura: quelle frasi sono spesso ottime. È un difetto di **formato**. Tre
frasi possono ricordare un concetto a chi lo ha già studiato; non possono
insegnarlo a chi lo incontra per la prima volta. E l'unico posto in cui questo
gioco incontra un concetto per la prima volta è quella scheda.

Per storia e geografia il difetto ha una forma ancora più netta: la scheda dice
*perché* le capitali stanno dove stanno, la tavola dice *che* Oslo è la capitale
della Norvegia, e in mezzo manca la cosa che un libro di scuola mette per prima
— **il racconto**: chi, dove, quando, contro chi, con quale conseguenza. Senza
quello, «in che anno cadde l'Impero Romano d'Occidente?» resta una domanda a cui
o si sa rispondere o non si sa, che è la definizione di domanda inutile.

## La regola

> **1. Ogni domanda è l'applicazione di un concetto già presentato per intero.**
> Non il richiamo di un nome mai detto, non il riconoscimento di una notazione
> mai mostrata: la rielaborazione di qualcosa che il gioco ha spiegato.
>
> **2. La presentazione per intero si chiama DISPENSA.** È un documento, non un
> avviso: un titolo, un contesto preciso e dettagliato diviso in sezioni, il
> vocabolario dei termini che userà, almeno due esempi svolti, il metodo, e
> l'errore tipico con il suo perché.
>
> **3. La dispensa arriva prima.** Non accanto, non dopo l'errore: prima della
> prima domanda che la applica, e lo studente ci resta dentro finché non chiude
> la scheda.
>
> **4. Una domanda può usare solo ciò che la sua dispensa ha introdotto**, o ciò
> che hanno introdotto le dispense delle fasce precedenti. Una notazione, un
> termine tecnico o un fatto che non compare in nessuna di quelle non può
> comparire in una domanda.
>
> **5. Il legame è dichiarato, non dedotto.** L'item scrive `applica: "<id della
> dispensa>"`. Chi scrive una domanda deve poter indicare il paragrafo che la
> rende rispondibile; se non ci riesce, la domanda non va scritta — va scritta
> prima la dispensa.

## Che cos'è una dispensa, nel dettaglio

Stessa forma per tutte e dodici le materie. Cambia il contenuto, non lo schema.

| Campo | Che cosa contiene | Minimo verificato |
|---|---|---|
| `titolo` | il nome del documento, non dell'argomento | — |
| `sezioni` | il documento: da due a cinque paragrafi, ognuno con il suo sottotitolo | **1200 caratteri** in totale |
| `glossario` | i termini tecnici che le domande useranno, spiegati qui | **2 voci** |
| `esempi` | esempi SVOLTI: domanda, risposta, e perché quella risposta | **2 esempi**, ognuno con il suo perché |
| `metodo` | come si arriva alla risposta da soli la prossima volta | **60 caratteri** |
| `errore` | l'errore tipico e perché non funziona | entrambi i campi pieni |
| `fasce` | l'intervallo di fasce 1..8 che questa dispensa copre | — |
| `insegna` | le notazioni esatte che autorizza nelle domande | — |

Milleduecento caratteri contro duecentonovanta: **quattro volte** la scheda di
oggi. Non è una soglia scelta a caso — è la lunghezza sotto la quale, provando a
scriverne una, non ci stanno insieme un contesto e un esempio.

### Per storia e geografia: il contesto è il documento

È il caso che il committente ha nominato. Le `sezioni` di una dispensa di storia
**raccontano**: dove, quando, chi comandava, che cosa stava cambiando, che cosa
è successo dopo. La domanda sulla data viene dopo il racconto e dentro il
racconto, e la sua risposta si può ricostruire dal testo anche da chi la data non
la ricorda. Le tavole di riferimento non spariscono: restano la mappa e la linea
del tempo su cui il racconto si appoggia, cioè la figura del documento.

## Come si verifica

`dispense_audit.gd`, e controlla cinque cose:

1. **la copertura** — ogni coppia (argomento, fascia) che il banco interroga ha
   una dispensa che la copre;
2. **la sostanza** — ogni dispensa supera i minimi della tabella qui sopra;
3. **il legame** — ogni item che dichiara `applica` punta a una dispensa che
   esiste, dello stesso argomento, e la cui fascia non viene DOPO quella
   dell'item (non si applica una lezione non ancora arrivata);
4. **il vocabolario** — nelle righe di codice di una domanda di coding non
   compare nessuna notazione che le dispense fino a quella fascia non abbiano
   dichiarato in `insegna`;
5. **il percorso** — giocando davvero, la dispensa arriva davanti alla prima
   domanda che la applica.

### Il registro del debito, e la sola direzione in cui si muove

Le dodici materie non si convertono in un giorno. L'audit porta un **tetto per
materia**: quanti argomenti possono ancora restare senza dispensa. Il tetto si
abbassa e non si alza mai — stessa disciplina del tetto delle scorciatoie in
`bank_scorciatoie_audit`. Alzarlo per far passare una build è il solo modo di
rendere questa regola una decorazione.

Stato all'apertura del registro, misurato sui banchi dell'11 settembre 2026:

| Materia | Argomenti del banco | Senza dispensa |
|---|---|---|
| **coding** | 13 | **0** — convertita l'11 settembre |
| **storia** | 9 | **0** — convertita l'11 settembre |
| **geografia** | 8 | **0** — convertita l'11 settembre |
| **latino** | 15 | **0** — convertita l'11 settembre |
| inglese | 47 | 47 |
| matematica | 34 | 34 |
| italiano | 30 | 30 |
| fisica | 12 | 12 |
| scienze | 8 | 8 |
| elettronica | 8 | 8 |
| musica | 8 | 8 |
| logica | 6 | 6 |

## Coding, la prima materia convertita

Che cosa è costato, perché serve a stimare le altre undici:

| | |
|---|---|
| dispense scritte | **26** — tredici argomenti × due bande |
| lunghezza media delle sezioni | **1559 caratteri** (la più corta 1313) |
| item nuovi che le applicano | **91**, in `scripts/banks/coding-applicazioni.mjs` |
| item del banco coding | da 329 a **420** |
| notazioni usate prima di essere insegnate | **0** |
| primi incontri aperti da una dispensa, giocando | **100%** |

Le due bande sono `fasce: [1, 4]` e `fasce: [5, 8]`. Spezzare in otto avrebbe
prodotto otto documenti che si ripetono; tenerne uno solo avrebbe messo i cicli
annidati davanti a chi non ha ancora visto un ciclo.

Il controllo 4 ha trovato subito qualcosa, ed è il genere di cosa per cui
esiste: un distrattore di fascia 4 mostrava `.strip(`, che le dispense
introducono nella banda alta. Una domanda di fascia 4 che chiede di riconoscere
una notazione spiegata alla fascia 5 è esattamente la domanda che questa regola
vieta, e nessuna delle guardie precedenti l'avrebbe vista.

## Storia, la materia su cui la regola era stata chiesta

| | |
|---|---|
| dispense scritte | **17** — otto argomenti × due bande, più `medioevo`, che il banco interroga solo alle fasce 6-8 |
| item nuovi che le applicano | **58**, in `scripts/banks/storia-applicazioni.mjs` |
| item del banco storia | da 239 a **297** |
| risposte di richiamo presenti nel documento | **18/18** |

Qui le sezioni **raccontano** invece di spiegare un meccanismo, e le date sono le
stesse di `TAVOLE_STORIA`, controllate una per una: le due cose devono stare in
piedi insieme, perché il bambino le vede tutte e due.

### Il controllo 4b: la risposta deve stare nel documento

È «solo dopo si può fare una domanda» tradotto in una misura, e vale nelle
materie di richiamo (`MATERIE_DI_RICHIAMO`, oggi storia). Se un item chiede un
nome e la dispensa che dichiara non lo contiene, la domanda è impossibile per
costruzione. Nessuna guardia precedente lo vedeva: `teach_before_ask` vede una
lezione, `tavole_riferimento` vede una tavola, e **nessuna delle due guarda se la
risposta ci sia davvero dentro**.

Non vale in coding, e la ragione è la differenza fra due tipi di domanda: là la
risposta è il *risultato* di un procedimento — `print("sala" + "nord")` dà
`salanord`, parola che in nessun documento comparirà mai né deve. Pretenderla
significherebbe vietare gli esercizi.

Quando la risposta è il risultato di una **regola** e non un fatto — «a quale
secolo appartiene il 1215?» ha infinite risposte e una regola sola — la dispensa
dichiara `regole`, espressioni regolari. Non è un'invenzione: `TavoleRiferimento`
aveva già lo stesso campo per lo stesso problema, e una sua voce porta già
l'espressione dei secoli.

### Una dispensa vale una tavola

`tavole_riferimento_audit` chiedeva «esiste un posto in cui il bambino può
imparare questa risposta prima che gliela si chieda», e quel posto poteva essere
solo una tavola. Ora può essere anche la dispensa che l'item dichiara: è un
riferimento più forte, non più debole — milleduecento caratteri di documento, e
la presenza della risposta verificata. Il giudizio lo dà una sola funzione,
`Dispense.insegna_la_risposta`, usata da entrambe le guardie: scritto due volte,
prima o poi diverge.

## Geografia, il caso più difficile dei tre

| | |
|---|---|
| dispense scritte | **16** — otto argomenti × due bande |
| item nuovi che le applicano | **48**, in `scripts/banks/geografia-applicazioni.mjs` |
| item del banco geografia | da 288 a **336** |
| risposte di richiamo presenti nel documento | **22/22** |

Perché è il più difficile lo diceva già la misura del 1 settembre: **il 78% delle
domande di geografia ha per risposta un nome**, e su `capitali` e `continenti` è
il 100%. Nessuna dispensa può risolverlo elencando i nomi — quello lo fanno già
le quarantanove tavole, e ripeterlo creerebbe due copie che divergono.

La divisione del lavoro è questa:

| | dice |
|---|---|
| la tavola | Oslo, in fondo a un fiordo |
| la dispensa | le capitali antiche stanno dove passava il commercio, e la Norvegia è tutta costa |

Il primo è un nome da imparare. Il secondo è un **criterio che si applica a un
Paese mai visto** — ed è per questo che quasi tutte le domande nuove chiedono di
applicarlo: perché i deserti stiano tutti sulla stessa fascia, perché una capitale
possa non essere la città più grande, perché un fiume corto porti più acqua di uno
lunghissimo.

Anche qui il controllo 4b ha trovato subito qualcosa: una risposta scritta «La
carta politica» mentre il documento dice «una carta politica». Il controllo
confronta il testo esatto, ed è giusto che lo faccia — una risposta che il
documento non pronuncia nella stessa forma è una risposta che il bambino non può
ricavare da lì.

## Latino, dove la domanda impossibile è di FORMA

| | |
|---|---|
| dispense scritte | **22** |
| item nuovi che le applicano | **59**, in `scripts/banks/latino-applicazioni.mjs` |
| item del banco latino | da 331 a **389** |
| risposte di richiamo coperte dal documento o dalle sue regole | **41/41** |

Il latino non ha il difetto di storia e geografia — la domanda di nome — ma uno
suo: la domanda di **forma**. «Da *rosa*, quale forma useresti per dire *della
rosa*?» non si deduce da niente: o si è vista la tabella, o si tira a indovinare.

**Ventidue dispense e non trenta.** I sette argomenti di declinazione hanno una
dispensa sola che copre tutte e otto le fasce (`BANDA_INTERA`): le caselle di un
paradigma sono una tabella, e una tabella non si divide in «prime quattro fasce»
e «ultime quattro» senza che i due documenti si ripetano mezzi a vicenda. Gli
argomenti concettuali — i casi, i verbi, le frasi, l'etimologia, il vocabolario —
restano su due bande, perché lì un prima e un dopo esistono davvero.

Qui le `regole` fanno il lavoro pesante, e per un motivo aritmetico: le forme
costruibili sono centinaia, elencarle nel testo sarebbe assurdo, e una riga di
espressione regolare copre un intero gruppo di radici. Il controllo 4b ha trovato
esattamente il caso che giustifica il meccanismo: un item chiedeva *puellam*
applicando la dispensa dei casi, che quella forma non la scrive ma **insegna a
costruirla** (l'accusativo singolare della prima declinazione è -am). La
riparazione giusta non era cambiare la domanda: era far dichiarare alla dispensa
l'insieme delle forme che insegna a costruire.

## Che cosa NON cambia

- **Le tavole restano.** Una dispensa di geografia racconta perché un fiume ha
  scavato una città dove l'ha scavata; la tavola dice dove passa. Servono
  entrambe, e la dispensa può citarne una.
- **NORA resta la voce.** Le dispense non sono scritte al posto suo: le legge
  lei, con le sue parole, e il suo `perche`/`come` resta il richiamo breve per
  chi la dispensa l'ha già letta.
- **Una prova superata non torna** (vedi [PEDAGOGY.md](PEDAGOGY.md)). Anche una
  dispensa letta non torna intera: dal secondo incontro in poi resta consultabile
  ma non ferma più lo studente.
