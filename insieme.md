# Eli Quest — Piano di lavoro

Aggiornato al 5 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
[Custode avanzato](docs/CUSTODE_LIVELLO_AVANZATO.md)

---

## Dove ci orientiamo — misurato il 5 agosto 2026

Tre direzioni possibili, e non si equivalgono. Le ho misurate invece di sceglierle
a intuito.

**Profondità degli esercizi — non è il collo di bottiglia.** Nell'esperienza
*giocata* (13 504 nodi su 24 mondi) la scelta multipla è all'**8%**, ogni materia
usa da 8 a 10 formati diversi, e le sessioni che ripropongono lo stesso argomento
nello stesso formato sono **0 su 3 648**. I banchi contano 3 472 item, almeno 15
per argomento, dal 20 al 30% a risposta libera. Qui il lavoro è fatto.

**Le spiegazioni — è qui il buco, ed è grosso.** I tre formati dominanti coprono
il **62% di tutto quello che un bambino gioca**, e nessuno dei tre spiega niente:

| formato | quota del giocato | cosa restituisce dopo la risposta |
|---|---:|---|
| abbinamento | 22% | «Collega ogni elemento a sinistra con quello giusto a destra» |
| ordinamento | 20% | «Ordine giusto: A, B, C» |
| classificazione | 20% | «Ogni tessera va nel gruppo giusto secondo la sua proprietà» |

Le prime e le terze sono **istruzioni**, identiche in ogni materia e in ogni
mondo. La seconda **ripete la risposta**. Nessuna dice un perché. In più, nei
banchi, **1 210 spiegazioni su 3 472 stanno sotto i 40 caratteri**, e 968 di
queste sono l'inglese, dove la spiegazione è tautologica: alla domanda «come si
dice *controllare*?» la spiegazione è «*check*: controllare».

Dove invece le spiegazioni sono state scritte a mano — grafici, circuiti,
notazione, carte — sono ottime: *«Il minimo si trova guardando chi sta più in
BASSO, non chi sta più a sinistra»*. È la prova che il problema non è la capacità
di scriverle: è che per tre formati su dieci non le ha mai scritte nessuno.

**Il divertimento — non si può ancora toccare.** Non esiste una misura, e
soprattutto **nessun bambino ha ancora giocato**. Qualunque modifica fatta adesso
sarebbe indovinare. È l'unica delle tre che richiede il collaudo *prima*, non
dopo.

### La scelta, e dove siamo

**Prima le spiegazioni** — fatto il 5 agosto. Era il 62% del vissuto, misurabile
e cricchettabile, ed è il cuore della promessa didattica: un gioco che dice
«giusto» e «sbagliato» senza dire *perché* sta misurando, non insegnando.

**Poi la varietà delle prove**, che è la parte del divertimento misurabile senza
aver giocato: quante forme diverse ha una sessione. Il resto del divertimento —
il ritmo, il piacere, la voglia di continuare — resta dietro al tuo collaudo, e
nessuna misura lo anticipa.

---

## Le spiegazioni — chiuso il 5 agosto 2026

Tutti e tre i lotti fatti: **3392 item, 3172 spiegazioni distinte, media 86
caratteri** (era 56). I tre formati dominanti hanno 207 spiegazioni proprie,
l'inglese non ripete più la risposta appena data, e le 31 circolari sono
riscritte. Tenuto da `minigame_explanation_audit` e `bank_explanation_audit`.

Resta qui una lezione, perché costa ogni volta che la si dimentica: **la
lunghezza è la metrica sbagliata.** Il piano prevedeva di allungare 242
spiegazioni «sotto i 40 caratteri»; misurandole, quasi tutte erano ottime —
«Pro-nome: al posto del nome», «*Riso* è un cereale e anche una risata». Corte
perché precise. Il difetto vero era essere **circolari**, e misurate così erano
31. I due audit infatti non guardano la lunghezza: guardano che la spiegazione
esista, che non ripeta domanda e risposta, e che **nessuna singola frase copra
più di venti item**.

---

## Il piano — la varietà delle prove (misurato il 5 agosto 2026)

Le spiegazioni sono chiuse. La domanda successiva era: **quali minigiochi
aggiungere per rendere le prove più divertenti?** Misurando, la risposta non è
quella che sembrava.

### Cosa c'è

Dieci formati, ma di due specie molto diverse:

| specie | formati | materie servite |
|---|---|---|
| **universali** | abbinamento, ordinamento, classificazione, grafico, circuito, caccia all'errore | 10–12 ciascuno |
| **distintivi** | notazione, carta, reperti, ciclo | **una sola materia ciascuno** |

I quattro belli — il pentagramma, la carta, i reperti da toccare, il ciclo da
ricomporre — li vede **una materia sola**. Musica ha il pentagramma, geografia
la carta, storia i reperti, scienze il ciclo. Le altre otto materie non li
incontrano mai.

### Il problema vero non è quanti formati ci sono

`format_shape_probe` costruisce 288 sessioni, dodici materie per quattro livelli
per sei estrazioni. Il risultato:

- **288 su 288 aprono con `abbinamento → ordinamento → classificazione`.**
  Sempre. Ogni materia, ogni livello, dal mondo 1 al mondo 24;
- in tutto il gioco esistono **otto forme di sessione**, e differiscono solo
  nella quarta campata;
- **a livello 1 sei materie su dodici hanno una forma fissa al 100%**: latino,
  geografia e storia non hanno nemmeno la quarta campata; inglese, musica e
  logica hanno sempre lo stesso specialista.

Le prime tre mosse sono le stesse tre mosse, sempre, nelle ore che decidono se
un bambino continua. Nessun formato nuovo ripara questo: il piano è cablato in
`build_minigame`.

### Cosa fare, in ordine di resa per costo

**1 · La forma della sessione — fatto il 5 agosto.** Le forme di sessione sono
passate da **8 a 52**, e l'apertura che prima copriva 288 sessioni su 288 ora ne
copre 24. È costato una funzione. Ha scoperto anche un fondo troppo corto in
logica ai primi livelli (il ripasso ripescava lo stesso item quattro volte in
dieci missioni): allargato il fondo con venti item, non la soglia.

**2 · Il `ciclo` a sette materie — fatto il 5 agosto.** Il formato è passato da
**una materia a otto**, con undici glifi nuovi tutti disegnati.
Impostazione originale conservata qui sotto perché la scala dei livelli resta
valida.  Il formato è già costruito e i suoi glifi
sono **disegnati proceduralmente**, non immagini: estenderlo non tocca la
pipeline degli asset. Sette materie hanno un ciclo vero da ricomporre, non
inventato:

| materia | il ciclo | da |
|---|---|---|
| coding | inizializza → condizione → corpo → incremento | L3 |
| matematica | l'aritmetica dell'orologio (modulo) | L6 |
| fisica | potenziale → cinetica → termica | L8 |
| geografia | il ciclo delle rocce | L10 |
| italiano | idea → scaletta → stesura → revisione | L4 |
| storia | domanda → fonti → confronto → tesi | L7 |
| musica | il circolo delle quinte | L16 |

**3 · Tre formati nuovi**, tutti a disegno procedurale:

- **retta numerica** (L1+, matematica) — **fatta.** Sei specifiche, dal «quale
  punto sta sul 7» ai negativi e ai decimali;
- **bilancia** (L5+) — **fatta**, e adattata nella *meccanica* prima che nel
  contenuto: «pareggiare» significa il valore in matematica, il **momento**
  (peso × distanza) in fisica, la resistenza in serie in elettronica, la
  cardinalità in logica, e in musica la **durata** — dove pareggiare vuol dire
  riempire esattamente la battuta, e avanzare spazio è sbagliato quanto
  traboccare. `_validate_balance` verifica l'**aritmetica**, non la forma: una
  bilancia che non pareggia insegnerebbe un'equivalenza falsa;
- **linea del tempo** (L8+, storia · musica · italiano) — **fatta.** Conta la
  *distanza*, non solo l'ordine: fra l'editto di Costantino e la caduta di Roma
  passano 163 anni, fra la caduta e Colombo più di mille — in un ordinamento
  sono due passi identici.

### Tre strutture nuove — fatte il 5 agosto

Non varianti di quelle che ci sono: **verbi di interazione** che il gioco oggi
non ha. Oggi si sa appaiare, mettere in fila, smistare, toccare un punto,
trovare l'errore, rispondere. Manca costruire, eseguire e indagare.

**Il compositore vincolato** — *scegliere i pezzi*, non riordinare quelli dati.
Esistono pezzi sbagliati, ed è lì che sta l'insegnamento.

| materia | che cosa si costruisce | i pezzi sbagliati sono |
|---|---|---|
| italiano | una frase | accordi errati di genere e numero |
| latino | una forma declinata | desinenze di un'altra declinazione |
| inglese | una domanda | l'ausiliare al posto sbagliato |
| coding | un'istruzione | due punti e parentesi mancanti |
| musica | un accordo | note vicine ma fuori dall'accordo |
| matematica | un'espressione che dà un risultato | operazioni nell'ordine sbagliato |

**Il tracciatore** — *eseguire passo per passo* e dichiarare lo stato finale. È
il formato che insegna la cosa più difficile da insegnare a parole: che una
sequenza si simula, non si indovina.

| materia | che cosa si traccia |
|---|---|
| coding | la tabella di traccia: dopo tre giri, quanto vale il contatore? |
| matematica | una catena di operazioni applicata a un numero di partenza |
| elettronica | dove arriva la corrente dopo che quell'interruttore si apre |
| geografia | dove finisce l'acqua che cade in questo punto |
| logica | chi resta dopo aver applicato le eliminazioni in ordine |

**L'indiziario** — *chiedere indizi per identificare*, e ogni indizio costa. È
l'unica struttura che introduce una **scelta strategica**: si può indovinare
subito rischiando, o comprare sicurezza. È anche l'unica che rende visibile una
competenza vera — quale domanda conviene fare.

| materia | si identifica | e gli indizi sono |
|---|---|---|
| storia | un personaggio | epoca, luogo, cosa fece |
| geografia | un Paese | continente, confini, clima |
| scienze | un vivente | classe, ambiente, alimentazione |
| inglese | una parola | classe grammaticale, campo, iniziale |
| logica | la soluzione di un indovinello | vincoli, uno per volta |

Tutte e tre **fatte**: compositore 7 specifiche, tracciatore 6, indiziario 6.

L'indiziario è l'unico con una vera scelta strategica — rispondere presto
rischiando, o scoprire un'altra carta. Nessun indizio costa energia o punti: in
un gioco che per contratto non punisce, il prezzo di una carta in più è la
soddisfazione in meno di averne usate poche, e il rischio c'è già (rispondere
presto e sbagliare costa uno scudo come ogni altro errore). Gli indizi non si
mescolano: l'ordine dal vago al decisivo **è** il contenuto.

Ogni formato ha un controllo che gli altri non hanno, ed è lì che sta il valore
dell'audit: la bilancia verifica **l'aritmetica**, la linea del tempo che due
eventi non si sovrappongano sulla scala, il compositore che le caselle vuote
siano **esattamente una**, il tracciatore che il buco stia **solo alla fine** —
un buco a metà catena renderebbe la simulazione impossibile invece che
difficile. Tutti provati rompendoli.

**4 · Reperti e carta.** Qui ho corretto una convinzione sbagliata scrivendo il
punto: **solo i reperti hanno bisogno di un disegno.** La carta d'Italia è
geometria vettoriale da Natural Earth, non un'immagine, quindi la carta
d'Europa è un lavoro di *dati* — estrarre i poligoni dallo stesso dataset
pubblico — e non aspetta un illustratore.

### Lo scorrimento — e la regola che ha cambiato

Proposta del committente, e ha spostato un guard-rail. Il gioco classificava la
**fluency per materia**: solo matematica poteva essere cronometrata, tutte le
altre no. Ma dentro una materia di ragionamento esistono automatismi veri —
coniugare «loro corrono», riconoscere «un'amica» — dove la velocità *è* la
misura. Dal 5 agosto la fluency è una proprietà dell'**argomento**
(`ContentManager.FLUENCY_TOPICS`), e `guardrails_audit` verifica due cose:
nessuna **missione** è mai cronometrata, e nessun argomento di analisi o
comprensione può essere dichiarato fluency.

Tre scelte che rendono il formato onesto:

- **una prova binaria si indovina al 50%**, quindi è la *lunghezza* a renderla
  seria, non la difficoltà: minimo dieci affermazioni, vere e false in
  equilibrio (fra il 35% e il 65%), soglia di precisione ben sopra il caso;
- **la serie si ferma, non si azzera.** Il moltiplicatore riparte da uno, i
  punti restano, nessun messaggio negativo — la stessa regola del legame del
  Custode e dei giorni del diario;
- **lo swipe non è l'unico comando**: due zone da toccare grandi mezzo schermo e
  le frecce della tastiera. Un gioco che si comanda solo con un gesto esclude
  chi usa una tastiera o un lettore di schermo.

Le affermazioni false non sono numeri a caso: sono gli errori che i bambini
fanno davvero — 3³ = 9, *un'amico*, *eated*, Barcellona capitale della Spagna.

### La scala per livello

Oggi i singoli esercizi sono graduati (`minLevel` per specifica), i **formati**
no. La scala proposta segue la difficoltà cognitiva, non la materia:

| livelli | che cosa si chiede | formati |
|---|---|---|
| **1–4** | riconoscere e appaiare | abbinamento, classificazione, retta numerica |
| **5–10** | mettere in processo | ordinamento, ciclo, bilancia |
| **11–17** | leggere una rappresentazione | grafico, circuito, carta, notazione, linea del tempo |
| **18–24** | manipolare rispettando vincoli | caccia all'errore, bilancia con incognite, reperti |

---

## Il gate: dodici materie, copertura per livello (6 agosto 2026)

Nasce da due segnalazioni di gioco. La prima: «superato l'esame del primo mondo,
non riesco ad accedere al secondo». La seconda, tua: lo studente fa il minimo
indispensabile e sale senza aver faticato.

Misurato prima di toccare niente: aprire il mondo 1 costava **18 esercizi su 3
argomenti**, circa dieci minuti. E dopo il primo mondo il gate non chiedeva più
nulla — la padronanza non decade e la copertura era cumulativa, quindi
ventitré livelli si aprivano da soli.

Tre regole nuove:

1. **Il livello si apre con tutte e dodici le materie**, non con le tre
   strumentali. La pratica smette di essere un extra e diventa la strada:
   è l'unico modo di allenare le materie che il mondo non ospita.
2. **La copertura si conta per livello**, non da sempre. Non chiede argomenti
   *nuovi* — quelli finiscono — ma argomenti *toccati adesso*: tenere allenato
   ciò che si sa, a ogni livello, in ogni materia.
3. **L'esame è più severo**: fino a cinque nodi invece di tre, e per passare ne
   servono tre quarti. Il numero di nodi si adatta agli argomenti che il livello
   propone, perché chiederne più di quelli disponibili obbligava a ripetere lo
   stesso argomento nello stesso formato.

| | prima | dopo |
|---|---:|---:|
| mondo 1 | 18 esercizi | **185** |
| campagna intera | 552 esercizi (~3 h) | **2712 (~15 h)** |
| mondi che costano lavoro | 1 su 24 | **24 su 24** |

E NORA dice che cosa manca — non il Custode, che per contratto non dà mai
vantaggi di gioco: nomina le tre materie più vicine al traguardo, il motivo
(accuratezza, copertura o ritenzione) e dove allenarle.

---

## Le cose da guardare giocando

Le schede di cablaggio (artKit, landmark, cast, tic) sono uscite da qui il
5 agosto 2026: quel lavoro è fatto, è verde e lo tengono gli audit. Riscriverlo
in un piano di lavoro significava rileggere ogni volta istruzioni per qualcosa
di già costruito.

Resta quello che **solo giocando** si può giudicare. Sono i punti in cui una resa
sbagliata non rompe niente e toglie tutto il significato.

- **1 · la conta di nonna Ersilia** va sentita nei primi cinque minuti. È la
  tabellina del 7 e contiene il nome del Tredicesimo. Se il giocatore la salta,
  al mondo 24 non ha la chiave in mano.
- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Se la resa non mostra la direzione dei graffi, il colpo 2 perde metà
  del suo significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Provviste sigillate, appunti impilati, un posto in più
  apparecchiato. Non è una scena di abbandono: è una scena di preparazione.
- **11 · le due datazioni**: nessuna delle due va bruciata, e la resa non deve
  suggerire quale sia «quella giusta».
- **12, 16, 19 · Tracce decisive**: hanno un `ripiego` in `MysteryCatalog`, ed è
  **obbligatorio cablarlo**. Senza, entrare nella Rovina diventa necessario per
  capire il finale, e questo viola il guard-rail «niente blocca il loop».
- **14 · i verbali**: dove dovrebbe esserci il nome della tredicesima voce c'è un
  **buco nella carta**, non una cancellatura. Va reso come un'assenza fisica.
- **17 · le insegne**: è la **prima azione del Tredicesimo** in tutto il gioco
  (`scrive`, poi `risbiadisce`). Una parola sola, ripetuta su ogni insegna
  dell'area, e sparisce uscendo. Nessun effetto sul gioco: costo zero.
- **18 · la voce**: prima volta che il Tredicesimo **parla**. Nessun ritratto,
  nessun corpo. Stanca, mai minacciosa.
- **19 · `chiude`**: la terza azione entra qui. Una porta della nave sigillata per
  un livello, e **deve esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.

### Il mondo 24 · Cuore dei Primi

Non ha residenti suoi: al Cuore convergono **i sei itineranti** e i residenti che
il giocatore ha portato allo stadio 2, **massimo quattro in scena per volta**.

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` risponde con chi è in scena e
`waves_needed()` con quante ondate servono. Contenuto pronto: **una battuta per
ognuno dei 46 residenti** — e ognuna dice cosa quel personaggio ha smesso di
credere, non un saluto — più le sei degli itineranti.

Due vincoli, verificati da `finale_content_audit`:

- **il Cuore non è mai vuoto.** Con zero residenti allo stadio 2 ci sono comunque
  i sei itineranti. Un finale che premia con la solitudine chi ha giocato in un
  altro modo è una punizione travestita da conseguenza;
- **nessuna battuta nomina chi non è venuto.** Gli assenti non si nominano.

`FinaleCatalog.CATTEDRA` ha l'assegnazione del tredicesimo posto. Si innesca
**dopo il nodo di sintesi**, non all'arrivo: il posto va a chi l'ha risolto, non
a chi è arrivato.

---

## Chi fa cosa

| | Claude | Tu |
|---|---|---|
| Tutto il codice, i contenuti e gli audit | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | ✅ |

Con un solo esecutore la revisione incrociata sparisce, e la sostituisce una
regola sola: **niente entra senza un audit che lo tenga.** Vale soprattutto per
il runtime, dove un errore non si vede rileggendo — il 3 agosto una sostituzione
in blocco ha invaso due costruttori che non c'entravano, e non me ne sono
accorto rileggendo il diff: me l'ha detto `minigame_audit`.

---

## Le altre voci aperte

Nessuna si scrive: vogliono un **asset** o una **tua decisione**.

- **Secondo foglio di reperti** — serve un'immagine nuova: gli atlanti dei
  reperti sono `.webp` (`artifact_atlas_catalog.gd`), e senza un disegno il
  formato non si estende.
- **Carta d'Europa** — **non serve un disegno.** Verificato il 5 agosto: la
  carta d'Italia è geometria vettoriale derivata da Natural Earth, dominio
  pubblico (`map_geometry_catalog.gd`), non un'immagine. Per l'Europa servono
  le coordinate dei poligoni dallo stesso dataset — un lavoro di dati, non
  d'arte, e quindi qualcosa che posso fare io se mi dai il via.
- **Accessibilità dei formati visuali** — le etichette identificano senza
  descrivere («Segnaposto A»), che è l'unica scelta che non regala la risposta.
  Ma chi usa un lettore di schermo **non può rispondere a una carta muta**. Vale
  già per grafici e circuiti. Va deciso, non subìto.

---

## Coda tua — il collaudo

I mondi sono cablati, verdi ed esportati: **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

È anche l'unico modo per aprire la terza direzione: **il divertimento non si
misura da qui**, e finché non hai giocato qualunque modifica su quel fronte
sarebbe indovinare.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto (semi troppo espliciti)
   o non capisci cosa sia successo (troppo nascosti)? La taratura vale per tutti
   e sette i colpi: se sbaglia qui, sbaglia sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o sembra che ti
   aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta**: la senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

---

## Invarianti di architettura

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta o beat è
  scritto dentro una scena: tutto viene dal catalogo.
- **I dati non decidono la resa** (niente posizioni sullo schermo nei cataloghi)
  **e la resa non decide i dati** (nessuna scena inventa registri o proprietari).
- **Nessuna immagine contiene testo**: non è traducibile, non è leggibile ad alto
  contrasto e non si corregge senza rigenerarla.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun abitante scrive mastery, energia, gate o ricompense.
- **Prima il contenuto, poi il cricchetto.** Stringere una soglia prima di aver
  scritto il contenuto obbliga a scrivere contenuto per far passare un test.
  All'inverso: **nessun cricchetto si allenta mai.**

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tre materie** (italiano, matematica, inglese), **si
   finisce il gioco con dodici**. Il gate è sulla padronanza, non sul conteggio
   delle missioni.
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha missioni di tutte le
   materie già incontrate.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%** (oggi 17%).
7. **Gli stadi di relazione avanzano su ciò che Eli impara**, mai su oggetti o
   valuta. Lo stadio 2 non richiede l'esame.
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario,
   nuovo a ogni livello, fedele al registro della materia. Cinque criteri su
   sette hanno un cricchetto; «vero» e «alla portata» li può verificare solo una
   rilettura umana.
9. **Almeno 15 item per argomento** (3 agosto 2026). Sotto quella soglia il
   ripasso spaziato dichiara consolidato ciò che è solo memoria di una schermata.
   Tenuto da `topic_density_audit`.
10. **Ogni banco al 20–30% di risposta non a scelta multipla** (4 agosto 2026).
   Una domanda a quattro opzioni si risolve per esclusione senza sapere niente;
   scrivere «rifrazione» in un campo vuoto no. Due formati liberi: `numeric_input`
   per i numeri, `short_answer` per le parole — quest'ultimo accetta le varianti
   dichiarate in `accept`, perché segnare sbagliata una risposta giusta è il modo
   più veloce per far smettere di provare. Il tetto del 30% dice l'altra metà:
   oltre, il banco diventa un dettato, e le domande di ragionamento — dove la
   risposta è una frase — restano giustamente a scelta multipla.
   Tenuto da `free_answer_audit`.

11. **Da una prova si esce sempre, e uscire costa** (4 agosto 2026). Un difetto
   di input non deve poter diventare un blocco totale: su tablet è già successo.
   La porta chiede conferma a due tocchi e costa 3 energie — quanto l'ingresso —
   e l'energia della prova non consegnata non arriva: senza prezzo, uscire e
   rientrare sarebbe il modo più veloce di ripescare domande finché non capitano
   le facili. Con zero energia si esce lo stesso. Gli argomenti visti restano nel
   Codex: il gioco non toglie a nessuno quello che ha imparato.
   Tenuto da `exercise_exit_audit`.

12. **Il Custode avanza in carattere, mai in potere** (4 agosto 2026). Nessun
   aiuto, nessun indizio, nessuna energia, nessuno sconto sul gate. Nel momento
   in cui il compagno diventa utile il bambino comincia a ottimizzarlo, e un
   compagno ottimizzato non è più un compagno. Tenuto da `pet_advanced_audit`.
   Include il terzo errore: al terzo errore sullo stesso argomento nella
   sessione corrente il Custode starnutisce — non aiuta, e NORA non lo commenta,
   perché lei non commenta mai un errore. Tenuto da `pet_struggle_relief_audit`,
   che ha già preso un doppio difetto: `sneeze` mancava dal catalogo, e
   `set_blocked()` interrompeva qualunque combinella a ogni fotogramma in cui un
   pannello restava aperto, non solo alla transizione — quindi anche uno
   starnuto avviato durante una prova sarebbe morto un fotogramma dopo.
   Include la lettura del mondo: *curioso* su un incontro non esplorato,
   *attento* vicino a uno Sbiadito — atmosfera, non informazione: entrambi già
   visibili a schermo. `near_unexplored`/`near_faded` erano dichiarati dal
   primo giorno e mai emessi finché non sono stati agganciati. Tenuto da
   `pet_world_awareness_audit`.

13. **Il diario racconta, non giudica** (5 agosto 2026). Mostra giorni giocati,
   prove superate e cosa sai adesso; non mostra percentuali di errore, non mette
   le materie in classifica e non dà obiettivi. **I giorni giocati sono
   cumulativi e non scendono mai**, come il legame del Custode: una serie che si
   azzera è una minaccia sul domani, non un resoconto di ieri, e questo progetto
   ha già deciso che non punisce chi torna dopo tre giorni. `streak` resta nello
   schema e non si mostra. Tenuto da `diary_audit` e `diary_panel_audit`.

14. **Una chiave del salvataggio senza lettori è un errore** (5 agosto 2026).
   Lo stesso difetto si è ripetuto quattro volte: `gifts`, `daily`, `modules` e
   (fuori dal salvataggio) i segnali `near_unexplored`/`near_faded` erano
   dichiarati insieme al progetto e costruiti solo a metà. Sembravano vivi
   perché stavano nello schema, e tutto ciò che li nominava era coerente con se
   stesso. Ora `save_schema_audit` pretende che ogni chiave compaia in almeno un
   file di produzione fuori dalla dichiarazione: le fixture degli audit non
   contano — `modules` stava in sette audit e in zero righe di gioco.

### Guard-rail narrativi (i tre che si rompono per primi)

- **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato. Chi
  non c'è è *trattenuto dal Silenzio*: sospeso e recuperabile.
- **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
  il gate. Le tre Tracce decisive (mondi 12, 16, 19) hanno un beat di ripiego.
- **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.

---

## Vincoli

- Nessun nuovo banco composto quasi solo da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
- Nessuna ulteriore profondità combinatoria: 33 milioni bastano.
- Le spiegazioni del **lessico** (inglese, italiano) restano come sono: lì
  rivedere l'accoppiata *è* il ripasso.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. La build è
   esportata e giocabile: da qui in poi questo rischio si chiude solo giocando,
   e ogni giorno che passa senza collaudo è lavoro fatto su un'ipotesi.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2667/3500 nodi e 468/500 ms, ed è
   quello a cui stiamo per aggiungere abitanti ed edifici. **Contare i nodi prima
   di aggiungerli**, non dopo.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: la suite intera è passata da **105 a 1295 secondi** — dodici
   volte — con sei audit rossi, e un singolo audit da due secondi ne ha impiegati
   oltre quattrocento. Quattro processi Godot in contemporanea, tre non miei. I
   rossi erano tutti in audit che caricano scene, e nessuno toccava le cose
   cambiate: era contesa, non regressione.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma. Un audit
   singolo (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire —
   è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni lotto

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
stai giudicando la build precedente.
