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

## Chi gioca, e dove vive la partita (6 agosto 2026)

Due guasti diversi con la stessa conseguenza — venti ore che spariscono — e una
sola causa: il salvataggio era **un file solo, a percorso fisso**.

| | che cosa succedeva | ora |
|---|---|---|
| due fratelli, un tablet | giocavano lo stesso salvataggio senza saperlo | una casella per ciascuno, fino a sei |
| stesso bambino, tablet diverso | niente da fare: l'export Web vive in IndexedDB, legato a quel browser | un **codice di ripristino** per casella |

Il Worker in cloud è in linea dal 6 agosto
(`https://eli-quest-save.ing-desantis-paolo.workers.dev`, sorgente in `cloud/`).
Nessun account, nessuna email: la chiave è un codice di otto caratteri, che non
identifica nessuno — un gioco per bambini di 10-13 anni che chiedesse un dato
personale si porterebbe dietro un obbligo di consenso.

Le tre regole che governano il codice, e il motivo di ciascuna:

1. **Il locale è la verità, il cloud è una copia.** Se il Worker non risponde
   non succede niente e si continua a giocare.
2. **Non si scarica mai da soli.** Il Worker non fonde due salvataggi: l'ultimo
   che scrive vince. Un caricamento automatico all'avvio potrebbe sostituire la
   partita buona con una vecchia. Prima di sostituire, il gioco mostra che cosa
   arriva e che cosa se ne va.
3. **Un codice si occupa solo se è libero.** Prima di assegnarlo si chiede al
   cloud se esiste già. Senza, due bambini potrebbero finire sullo stesso
   salvataggio: l'unico incidente davvero grave qui.

Due scelte che sembrano mancanze e non lo sono. **Non si cancella un profilo**:
butterebbe via il lavoro di un bambino con un tocco, sul dispositivo di un
altro, in sua assenza — chi vuole riusare una casella la rinomina. E **senza
l'elenco dei profili tutto si comporta come prima**, sul percorso storico: è per
questo che il cambiamento non ha toccato nessuna delle prove esistenti, e che il
primo profilo *adotta* la partita già in corso invece di ripartire dal livello 1.

---

## Il registro dei giocatori (6 agosto 2026)

Una tabella per confrontarsi, «per dare un po' di sfida». Sembra una funzione
innocua ed è il posto dove questo gioco può farsi più male da solo: una
classifica per livello premia chi ha cominciato prima, e chi arriva un mese dopo
è ultimo per sempre senza poterci fare niente. Subito dopo aver legato la
progressione alla padronanza invece che alla velocità, sarebbe un contrordine.

Da qui tre famiglie di misure che convivono:

| | che cosa misura | si recupera? |
|---|---|---|
| **La settimana** | prove superate negli ultimi 7 giorni | **sì**, riparte da sé |
| Il viaggio · Le cose sapute · I giorni | livello, argomenti consolidati, giorni giocati | no, raccontano la strada fatta |
| Le dodici materie | padronanza per materia | dodici classifiche invece di una |

La classifica che si apre per prima è **la settimana**: la lettura di apertura è
quella che resta. E sotto la tabella ci sono le **medaglie** — in che cosa guida
ciascuno: con dodici materie è raro che qualcuno non guidi niente, e chi non
guida niente non compare affatto invece di leggere «nessuna medaglia».

Due schede. **CASA** sono le caselle di questo tablet: nessuna rete, funziona
sempre. **GRUPPO** è un codice condiviso fra più tablet — una classe, dei
cugini. Nel gruppo viaggia solo un riepilogo di numeri: mai il salvataggio, mai
il codice di ripristino, perché quello sovrascrive una partita e nel registro lo
vedrebbe tutta la classe.

Regole che non si toccano, tutte ereditate dal guard-rail del Custode e del
diario: **nessuna misura scende per un'assenza**, niente serie da spezzare, e a
parità di valore l'ordine è alfabetico — se dipendesse dall'ordine di lettura,
due bambini a pari merito si scavalcherebbero a turno senza aver fatto niente.

---

## La pratica ripeteva gli stessi quesiti (6 agosto 2026)

Segnalazione di gioco: «lo studente supera le prove di una location, è tentato
di rifare la stessa location, e ritrova gli stessi quesiti identici».

Misurato prima di toccare niente, rigiocando dieci volte:

| | quesiti identici al primo giro | distinti per casella |
|---|---:|---:|
| **pratica** (minigiochi) | **55%**, fino all'83% in geografia L1 | 5–19 |
| missioni (banchi) | 13% — normale sovrapposizione | 23–30 |

La causa non era il caso: entrambi i costruttori estraggono davvero a sorte. Era
il **fondo**. Geografia e storia al livello 1 avevano cinque quesiti distinti in
tutto, e una sessione ne consuma quattro: la seconda volta non poteva che essere
la prima.

Sotto, un secondo difetto che nessuno aveva notato: in `resolve_session` il ramo
che chiude un incontro era `mission or enigma`. **La pratica non veniva mai
chiusa**, e il controllo in `try_start_minigame` leggeva una lista che nessuno
riempiva — codice morto dal giorno in cui è stato scritto.

Tre riparazioni:

1. **la palestra superata si chiude e sparisce dalla mappa**, subito, non al
   rientro;
2. **la successiva nasce altrove**, con identificativo `-r1`, `-r2`… Senza,
   una materia avrebbe offerto una pratica per visita e per allenarne dodici si
   sarebbe dovuto tornare alla nave quattro volte per mondo: la ripetizione
   sparisce, ma al posto suo arriva una corvée;
3. **i quesiti già visti non tornano**: il salvataggio ne ricorda le impronte, e
   quando il catalogo interattivo si esaurisce la composizione attinge ai
   **banchi**, che di fondo ne hanno. Meglio un quesito di forma più semplice ma
   nuovo che un abbinamento già fatto.

Misurato dopo: **55% → 20%** su dieci giri, fondo per casella da 5–19 a **27–33**,
e **almeno sette giri consecutivi interamente nuovi** ovunque. Il cricchetto in
`practice_variety_audit` ne pretende cinque: sotto il misurato per non diventare
rosso a ogni oscillazione, sopra il vissuto realistico — una materia ha una
palestra per mondo, non sette.

Resta un limite dichiarato: oltre i dodici giri consecutivi sulla stessa materia
allo stesso livello la ripetizione è **aritmetica**, non un difetto. Trenta
quesiti non bastano a cinquanta estrazioni. Con le palestre che si chiudono, quel
regime non si raggiunge giocando.

---

## Rigiocare da capo, e una misura sbagliata (6 agosto 2026)

Domanda: chi ricomincia dal primo livello trova prove inedite?

**Prima risposta, sbagliata.** Misurando, il mondo 1 risultava al 13% di inediti
e il catalogo interattivo sembrava avere 5–16 quesiti per materia contro i
53–508 dei banchi. Conclusione: la pratica pesca dal pozzo piccolo. Messo un
tetto — metà sessione dai banchi — il numero saliva al 50%.

**Perché era sbagliata.** L'identità di un quesito era il suo `prompt`. Ma nei
formati interattivi il prompt è una **costante**: ogni abbinamento del gioco dice
«Abbina ogni elemento alla sua coppia», qualunque siano le coppie. Contando i
testi, tutti gli abbinamenti erano un esercizio solo — e la stessa svista era
dentro la memoria del già visto, che dopo UN abbinamento scartava tutti gli
abbinamenti successivi.

**Misura vera, contando il contenuto:**

| | prompt (sbagliato) | contenuto (giusto) |
|---|---:|---:|
| catalogo a L1 | 5–16 | **354–826** |
| inediti al 2° viaggio | 33% | **91%** |
| ripetizioni nel 1° viaggio | — | **zero** su 540 |

Col tetto o senza, gli inediti restano al 91%: il tetto non serviva a niente e
costava metà della forma interattiva. Rimosso.

**Quello che resta vero della segnalazione.** Il bambino non contava i contenuti:
vedeva la stessa consegna, lo stesso argomento, la stessa spiegazione, con coppie
che si sovrappongono. Il numero magro non è quello dei nodi ma quello delle
**specifiche** ammesse ai primi livelli:

| materia | specifiche a L1 | a L10 |
|---|---:|---:|
| matematica | **4** | 13 |
| coding · fisica · elettronica · geografia · scienze · storia | **6** | 12–18 |
| inglese · musica · logica | 7 | 14–21 |
| latino | 8 | 16 |
| italiano | 11 | 21 |

È lì che si allarga il catalogo, ed è lavoro di contenuto: più angolazioni e più
argomenti nei primi mondi, non più coppie dentro le stesse specifiche.

**La lezione, che costa ogni volta che la si dimentica:** una metrica che sembra
ovvia può misurare un'altra cosa. Il prompt sembrava l'identità di un esercizio
ed era l'etichetta del formato. Prima di riparare su un numero, guardare da dove
viene quel numero.

---

## Il catalogo delle ricette (6 agosto 2026)

Una **ricetta** (`spec`) e' un tipo di esercizio: un argomento, una consegna, una
spiegazione e un serbatoio di contenuti da cui pescare. Il bambino percepisce la
varieta' qui, non nei contenuti: mille coppie dentro la stessa ricetta restano
«la stessa domanda».

Al mondo 1 le ricette ammesse erano da 4 a 11 per materia, e in matematica due
delle quattro erano perfino la STESSA esperienza — espressione da calcolare,
risultato da abbinare. Quattro tappe le hanno portate tutte a **dieci**:

| materia | prima | dopo |
|---|---:|---:|
| matematica | 4 | 10 |
| coding, fisica, elettronica, geografia, scienze, storia | 6 | 10 |
| inglese, musica, logica | 7 | 10 |
| latino | 8 | 10 |
| italiano | 11 | 11 |

Il criterio non era «piu' esercizi» ma **azioni mentali che mancavano**:

- coding non aveva ne' condizioni ne' cicli, le due idee che distinguono un
  programma da un elenco di ordini;
- fisica non aveva le forze, che sono meta' del programma;
- elettronica non aveva ne' la diagnosi di un guasto ne' la sicurezza;
- scienze non aveva il METODO, che e' la materia stessa;
- storia non aveva le FONTI, cioe' il mestiere dello storico invece dell'elenco
  delle date;
- latino non aveva l'ETIMOLOGIA, che a quell'eta' e' il motivo per studiarlo.

**Lezione della tappa 4**, pagata con una prova rossa: le tre ricette di musica
erano nate con serbatoi da otto voci contro le venti-trenta di quelle vicine, e
`variety_audit` ha visto salire musica L1 al 23% di ripetizioni (massimo 17%).
Una ricetta nuova con un serbatoio piccolo puo' PEGGIORARE la varieta' invece di
migliorarla. Regola: un serbatoio nuovo si allinea a quelli della materia, non
al minimo che basta a far girare il codice.

**Prossimo giro, gia' deciso: portare tutte le materie a 15 ricette al mondo 1.**
Vale la pena farlo dopo un collaudo vero — sei materie del mondo 1 sono cambiate
molto, e conviene sapere se la differenza si sente prima di scriverne altre
sessanta.

---

## Il rango del nucleo: italiano, matematica, inglese (6 agosto 2026)

Direzione decisa dal committente: queste tre devono contare piu' delle altre
nove, in contenuto, in prove e nel gioco.

**La tensione da governare, detta subito.** Il 5 agosto il gate era passato da
tre materie a dodici, per impedire di salire facendo il minimo. Rimettere le tre
al centro rischiava di riportare il problema. La soluzione non e' **quali**
materie fermano la progressione — restano tutte e dodici — ma **quanto alta e'
l'asticella di ciascuna**.

| | soglia al mondo 1 | copertura per livello |
|---|---:|---:|
| nucleo (italiano, matematica, inglese) | **0,78** | base **+1 argomento** |
| le altre nove | 0,70 | base |

Il bonus e' `ApparatusConfig.CORE_MASTERY_BONUS`, e vale ovunque perche' e'
applicato dentro `GateReadiness.evaluate_subject`, cioe' nell'unico punto da cui
passa ogni valutazione: HUD, portale, report e audit leggono tutti lo stesso
numero e non possono dissentire.

Perche' 0,08 e non 0,15: piu' in basso il bambino non si accorge della
differenza e il rango torna una dichiarazione; molto piu' in alto chi e' debole
proprio in queste tre resta fermo — e sono le tre materie in cui essere deboli
e' piu' comune.

**La prova di nucleo.** L'esame di un mondo era solo della materia ospite: in
ventuno mondi su ventiquattro il nucleo non compariva nel momento decisivo. Un
bambino impara che cosa conta da dove viene interrogato, non da quello che gli
si dice. Ora ogni esame porta **due nodi** dalle materie del nucleo diverse da
quella del mondo. Due e non tre: l'esame resta della materia del mondo, e
trasformarlo in un esame generale cancellerebbe il senso di riparare QUELLA
stanza.

**Costo misurato:** campagna da 20 a **21,1 ore**, mondo piu' lungo da 62 a 72
minuti. Avevo previsto un aumento del 30-40%: era **+5%**. Seconda previsione a
occhio smentita dalla misura in due giorni — la regola resta misurare prima.

**Leve studiate e NON attivate** (restano qui, con il loro perche'):

- *presenza nel mondo*: due luoghi invece di uno per le tre quando non sono
  ospiti, da 16 a 19 per mondo. Tocca il direttore degli eventi e va rimisurato
  il tempo per mondo;
- *ripasso piu' stretto* per gli argomenti del nucleo: poco visibile subito,
  molto efficace sulla ritenzione a distanza;
- *voce del gioco*: NORA nomina per prime le tre, le loro stanze sono il cuore
  della nave, il registro mostra il nucleo a parte;
- *contenuto*: il giro a 15 ricette parte dalle tre, e un cricchetto che
  pretenda per loro un fondo di banco piu' alto — oggi e' gia' vero di fatto
  (matematica 498, inglese 508, italiano 365 quesiti a L1 contro 53-144 delle
  altre) ma niente lo protegge.

---

## I personaggi: analisi e riparazione della voce (6 agosto 2026)

Analisi fatta sui file, non sui documenti. Il cast e' grosso e ben costruito:

| chi | quanti | battute | carattere dichiarato |
|---|---:|---:|---|
| Residenti | 46 (2 per mondo) | ~2231 | ruolo, tic, arco, registro, convinzione, bisogno |
| Ritrovo (parlano fra loro) | - | 1029 righe | - |
| Bislacchi | 23 (1 per mondo) | 4 ciascuno | ruolo, tic, registro |
| Itineranti | 6 ricorrenti | 139 | funzione di gioco |
| Il Tredicesimo | 1 | 327 righe | antagonista |
| **NORA** | 1 | **53 in tutto** | **nessuno** |
| Custode | 1 | 0 (muto per contratto) | espressioni |
| Eli | 1 | 0 | - |

**Quello che gia' funziona.** L'arco narrativo e' la parte migliore del
progetto: 24 beat, sette ribaltamenti, e `mystery_audit` che pretende almeno
tre semi nei mondi precedenti a ogni colpo di scena — e' raro che una
rivelazione sia verificata da un test. Il Tredicesimo e' un antagonista che non
attacca: chiede, avverte, supplica, ed e' stanco invece che cattivo. I Dodici
Maestri non sono dodici personaggi ma dodici inflessioni di NORA, una per
materia: progressione narrativa senza un cast in piu' da gestire.

**Il difetto trovato: la voce era distribuita al contrario.** NORA parla dopo
ogni prova — venti o venticinque volte per mondo — e aveva dodici battute in
tutto; un Bislacco di sfondo, incontrato una volta sola, ne ha quattro. Chi
parlava di piu' aveva il repertorio piu' piccolo. Ed era l'unico personaggio del
gioco senza carattere dichiarato.

Terzo difetto, il piu' sottile: **l'arco e il momento non si parlavano**. Al
mondo 19, appena scoperto che il Tredicesimo l'ha costruita, NORA diceva ancora
«Sistema stabilizzato! Hai seguito il metodo» — la stessa frase del mondo 1.

**Riparato in quattro punti:**

1. carattere dichiarato come per ogni residente. Il tic non e' inventato: e' gia'
   nel primo beat («Non di nuovo — scusa, non so perche' l'ho detto») e al mondo
   16. NORA si interrompe e si corregge perche' ha una memoria manomessa, quindi
   il tic **e'** la trama;
2. repertorio in **tre atti** (1-8, 9-16, 17-24) allineati ai ribaltamenti: da
   12 battute a **68**, e le battute di un atto non compaiono negli altri;
3. i **ricordi**: una volta su quattro, dopo una prova risolta, NORA si
   interrompe e dice una cosa che c'entra con la storia e non con l'esercizio.
   Non esistono nell'atto primo — la' non ha ancora scoperto niente, e sarebbe
   il gioco che si anticipa da solo;
4. `nora_voice_audit` come cricchetto: nessun pozzo sotto le quattro battute,
   atti disgiunti, nessun ricordo nel primo atto, e nessuna lode alla PERSONA
   invece che all'azione.

**Restano aperte due cose, dichiarate:**

- **Eli non parla mai.** Legittimo, ma con NORA che le si rivolge di continuo il
  rischio e' che il bambino si senta spiegato invece che interpellato;
- **il Custode e' muto per contratto** (non deve dare vantaggi di gioco) ed e'
  l'unico personaggio sempre presente che non puo' commentare niente.

---

## Oggetti, bottega e i cinque epiloghi (6 agosto 2026)

### Il difetto trovato negli oggetti

Quattro «upgrade» promettevano meccaniche **che non esistono** in questo loop:
«il primo indizio di ogni run non consuma aiuti», «gli impulsi NORA si
caricano», «una carica NORA puo' recuperare due vite». Aiuti, impulsi e vite
sono del prototipo Phaser: qui non c'e' niente di tutto cio'. Costavano da 360 a
1600 frammenti e non facevano nulla. Riscritti su cio' che sono davvero — pezzi
della nave che si accendono — e `endings_audit` ora vieta a qualunque oggetto di
promettere una meccanica inesistente.

### Il valore degli oggetti: la provenienza

Un cosmetico non puo' dare vantaggi nelle prove, per contratto didattico. Allora
il suo unico valore possibile e' **da dove viene**. Tutti e 55 gli oggetti hanno
ora una `origine` mostrata in bottega: chi lo aveva, in quale mondo, perche' lo
ha lasciato.

Prima: «Bit Lime — Verde acido brillante per il tuo compagno.» Un colore.
Adesso, sotto: «Vernice avanzata dai segnavia della radura: Tobia ne aveva un
barattolo di troppo.»

### Il Lascito, e la regola che lo governa

`LegacyScore` pesa cinque dimensioni: padronanza (30%, con il nucleo che conta
doppio), ritenzione (25%), mondo (20%), rotta (15%), indagine (10%).

**Non pesano frammenti, cosmetici, ore giocate ne' velocita'.** Se pesassero, un
bambino potrebbe **comprarsi un finale migliore**, e un gioco che si studia non
puo' vendere il proprio epilogo. E' la prova piu' importante dell'audit: si
riempie un salvataggio di ricchezza, acquisti e ore e si verifica che il Lascito
non si muova di un centesimo.

### I cinque epiloghi

**Nessuno e' un finale brutto.** Cambiano per *che cosa* hai fatto, non per
*quanto vali*, e nessuna riga nomina cio' che il giocatore NON ha fatto — un
epilogo che dicesse «hai fatto poco» a un bambino dopo venti ore sarebbe la cosa
peggiore che questo gioco possa fare.

| epilogo | si apre quando | che cosa dice |
|---|---|---|
| **ROTTA APERTA** | profilo equilibrato | hai rimesso in moto una cosa ferma |
| **IL REGISTRO CHE RESTA** | domina la ritenzione | il sapere che tieni smentisce la tesi del Silenzio |
| **IL CIRCUITO** | domina il mondo | dodici mondi tornano a parlarsi, e non per merito della nave |
| **SULLA SOGLIA** | domina l'indagine | il Tredicesimo ti dice l'ultima cosa che gli restava |
| **LA TREDICESIMA CATTEDRA** | domina la padronanza | il posto va a chi tiene dodici modi di capire insieme |
| **C'E' QUALCOSA. VENITE.** | Lascito >= 0,82 | non si aspetta Meridiana: si va a prenderla |

Il sesto non e' «il migliore»: e' **il piu' lungo**, e non aggiunge una
ricompensa — aggiunge una partenza. La dominante si calcola sullo scarto dalla
media e non sul valore assoluto: senza quella normalizzazione vincerebbe sempre
la ROTTA, che sale da sola avanzando.

### Cosa manca, dichiarato

`FinaleCatalog` — le 46 battute del Cuore dei Primi e il cast condizionale — e'
letto **solo da un audit**: nessuna scena lo mostra. Gli epiloghi nuovi sono
allo stesso stadio: dati e selezione pronti, regia da fare. E' un lotto di
scena, non di contenuto.

I **consumabili** non sono stati aggiunti: in un gioco che si studia un
consumabile utile diventa una scorciatoia per non sapere, e uno inutile e' un
altro oggetto bugiardo. Se servono, l'unica forma difendibile e' estetica e
temporanea (l'aspetto di un mondo per una sessione), mai qualcosa che tocchi una
prova.

---

## La svolta severa (6 agosto 2026, seconda passata)

Indicazione del committente: «possiamo essere un pochino severi, lasciandoci un
buonismo completo alle spalle… se il gioco e' troppo facile non stimola».

**Il principio applicato, perche' non tutta la severita' funziona:** severi verso
il **lavoro**, mai verso la **persona**. «Tre sistemi restano spenti e il
Tredicesimo torna alla diga» e' duro ed e' un motivo per tornare. «Non sei stato
all'altezza» e' altrettanto duro e chiude il gioco. Il primo parla del mondo, il
secondo del bambino: `endings_audit` vieta il secondo e permette il primo.

### Gli epiloghi: da sei a otto, e due sono incompleti

Prima ogni profilo riceveva un epilogo dignitoso e la differenza era solo di
sapore: l'esito non dipendeva mai da quanto avevi imparato.

| epilogo | soglia | che cosa dice |
|---|---|---|
| **IL SILENZIO TIENE** | Lascito < 0,22 | tre sistemi accesi su dodici, i sensori lunghi non rispondono, il Tredicesimo torna a tenere |
| **IL CIRCUITO INCOMPLETO** | < 0,38 | la nave rifiuta la rotta lunga: «sei arrivata piu' vicino di tutte. Vicino non basta a chi aspetta da quattrocento anni» |
| rotta · registro · circuito · soglia · cattedra | fascia media | per dominante |
| **C'E' QUALCOSA. VENITE.** | >= 0,82 | si va a prendere Meridiana |

Un salvataggio appena cominciato riceve ora IL SILENZIO TIENE, non ROTTA APERTA.

**La coda di curriculum.** Ogni epilogo chiude nominando le materie vere di quel
giocatore: «7 sistemi su 12 in linea. Matematica ci ha portati fin qui;
geografia e' rimasta al buio, e la nave se ne accorge.» Nomina **sempre anche la
forza**: un bilancio che dice solo la mancanza non e' severita', e' una nota sul
registro.

### La penalita' meccanica: la padronanza decade

Il difetto vero era questo. La padronanza non scendeva mai: un bambino portava
una materia sopra soglia **una volta** e non la toccava piu' per venti mondi. Il
gate a dodici materie chiedeva lavoro la prima volta e mai piu'.

Ora decade, **misurata in sessioni giocate e non in giorni reali**: colpisce la
scelta di ignorare una materia mentre si continua a giocare, non l'assenza di
chi torna dopo una settimana. Chi chiude il gioco per un mese ritrova quello che
aveva.

Tre difese, ognuna contro un modo di rendere stupida la penalita':

- **franchigia** di dodici sessioni: alternare fra materie e' cio' che il gioco
  chiede, punirlo sarebbe punire chi fa la cosa giusta;
- **pavimento** a meta' del proprio massimo: una spirale da cui non si risale
  non e' severita', e' un vicolo cieco travestito;
- **mai praticata non decade**: una materia non ancora incontrata non e'
  trascurata, e l'ordine dei mondi non lo decide il bambino.

Misurato da `decay_audit`: duecento sessioni ignorando geografia la riportano
**sotto la soglia del gate** — il livello si richiude finche' non la si riprende
— e dodici sessioni la recuperano. Costo della campagna invariato (21,1 ore):
la penalita' colpisce chi si specializza, non chi gioca tutte le materie.

### Cosa NON e' stato reso severo, e perche'

- **il diario e il legame col Custode** restano senza serie da spezzare: sono
  misure di presenza, e punire l'assenza produce senso di colpa, che spegne
  l'apprendimento invece di stimolarlo;
- **il costo d'uscita** da una prova resta fisso: e' gia' il doppio di restare;
- **nessun vicolo cieco**, in nessun epilogo: la nave riparte sempre e la
  partita resta rigiocabile. E' l'unica cosa del guard-rail vecchio rimasta in
  piedi.

---

## Come i minigiochi completano la gamma (misurato il 6 agosto 2026)

Indagine su tutte e dodici le materie e sette livelli, confrontando che cosa
porta il BANCO e che cosa porta il CATALOGO interattivo.

### Sui formati: complementarita' totale

I due insiemi sono **perfettamente disgiunti**, in ogni materia:

| sorgente | formati | che cosa misura |
|---|---|---|
| banco | scelta multipla, numerico, risposta breve | **sapere**: si chiede e si risponde |
| minigiochi | abbinamento, ordinamento, classificazione, grafico, circuito, bilancia, caccia all'errore, linea del tempo, compositore, tracciatore, indiziario, scorrimento… | **fare**: si manipola qualcosa |

Non e' una ripartizione casuale: e' la ragione per cui i minigiochi esistono. Un
gioco fatto dei soli banchi sarebbe un questionario.

### Sugli argomenti: complementarita' disuguale, e il motivo e' interessante

Su 241 etichette di argomento: **45 solo banco, 92 comuni, 104 solo minigioco**.

Guardando dentro, il rapporto cambia da materia a materia e non a caso:

- **inglese** (21 argomenti solo-minigioco) e' il caso piu' chiaro. I due
  vocabolari sono ortogonali per costruzione: il banco copre i **campi
  semantici** (food-shopping, travel-places, body-health, jobs-community), i
  minigiochi coprono la **grammatica** (articles, comparatives, contractions,
  irregular-past, third-person, wh-question). Lessico da una parte, strutture
  dall'altra;
- **coding** (14) aggiunge concetti che il banco non tocca mai: logica
  booleana, diagramma di flusso, indentazione, efficienza, validazione, binario.
  Il banco in cambio porta solo `stile` e `stringhe`;
- **musica** e **latino** (1) sono quasi sovrapposti: li' il minigioco aggiunge
  la forma, non l'argomento.

### Il difetto che l'indagine ha fatto emergere

La dimensione COPERTURA del gate conta gli argomenti **toccati**, e il bersaglio
si calcola su `reachable_topic_count`, che campiona il **banco**. Ma la pratica
marca anche argomenti che esistono **solo** nel catalogo interattivo — 104 su
241.

Conseguenza: in inglese, coding, scienze, fisica ed elettronica un bambino puo'
soddisfare la copertura del livello toccando argomenti che **l'esame non
verifichera' mai**, perche' l'esame nasce dal banco. Il bersaglio e' calcolato su
un insieme e il conteggio su un altro.

Non e' grave dove i vocabolari coincidono (musica, latino), ed e' massimo dove
divergono di piu' — che sono proprio le materie in cui i minigiochi danno il
contributo migliore. Le due riparazioni possibili:

1. **contare per la copertura solo gli argomenti del banco** — semplice, ma
   butta via il fatto che la grammatica inglese imparata nei minigiochi e'
   apprendimento vero;
2. **allineare i vocabolari**, cioe' portare nel banco gli argomenti che oggi
   vivono solo nei minigiochi. Piu' lavoro, ma e' quello giusto: se un argomento
   vale per la copertura, deve poter comparire in un esame.

---

## Dare senso al girovagare: studio (6 agosto 2026)

Richiesta: la mappa sembra solo un modo per accedere agli esercizi. Si vorrebbe
esplorare evitando pericoli, trovando tesori, liberando percorsi con prove
speciali, e edifici che offrano un minigioco proprio (la bottega che fa
guadagnare energia).

**La scoperta dello studio: quasi tutta questa macchina esiste gia'.** Non
serve costruirla — serve accenderla e collegarla. Inventario misurato:

### Vivo e funzionante

| cosa | dove | stato |
|---|---|---|
| **tesori** | `chunk_visual._build_treasures` | piazzati per chunk. Dal mondo 2, **un terzo richiede la torcia e un terzo la falce**: «tesori nascosti che chiedono uno strumento» c'e' gia' |
| **strumenti** | `EquipmentGate` | torcia e falce cancellano deviazioni opzionali. Per contratto **non bloccano mai il gate**: chi non esplora non resta indietro nella progressione |
| **passaggi che si aprono** | `WorldCompositionData.crossings` | un guado con un `eventId`: superato quell'enigma, l'acqua diventa attraversabile. «Liberare percorsi con una prova speciale» **c'e' gia'** |
| **nemici** | `world_enemy.gd` | presenti e piazzati nel mondo |
| **edifici** | tre per mondo, ora con 72 nomi propri | |
| **bottega** | `outdoor_shop_panel` (817 righe) | funziona |

### Morto o scollegato — ed e' qui che sta il lavoro

1. **Gli `hazard` non esistono.** Il salvataggio ha `clearedHazardIds`, e la
   parola «hazard» compare in **tutto l'albero degli script una volta sola**:
   in `save_manager`. Nessuno li crea, nessuno li legge. E' un campo di
   salvataggio senza produttore ne' consumatore — il quarto caso di questa
   specie trovato in due giorni.
2. **Gli edifici non sono interagibili.** `building_actor` imposta i metadati
   ma non entra mai nel gruppo `world_interactable` e non ha un'area di
   collisione: sono scenografia. I settantadue nomi nuovi si leggono e basta.
3. **La bottega e' un pulsante dell'HUD, non un luogo.** Si apre da
   `_open_shop`, agganciato a un bottone in alto. Il mondo ha una `work_home` e
   un `ritrovo` con un nome proprio, e la bottega non sta ne' nell'uno ne'
   nell'altro.
4. **Un solo guado per mondo.** `data.crossings` e' un array di un elemento.
   La meccanica piu' interessante che il gioco possiede — una prova che apre
   fisicamente una parte di mappa — accade una volta per mondo.

### La proposta, in ordine di resa per costo

**Tappa A — gli edifici diventano luoghi.** Aggiungere a `building_actor`
l'area di interazione che gia' hanno i POI, e dare a ciascuno dei tre ruoli una
funzione:

- **work_home** → il minigioco della materia del mondo, a costo d'energia
  ridotto: e' la casa del mestiere, allenarsi li' costa meno che in mezzo al
  campo;
- **ritrovo** → le conversazioni fra abitanti (`ritrovo_catalog`, 1029 righe
  gia' scritte) e la **bottega**: si compra dove la gente si incontra, che e'
  come funziona una piazza;
- **first_ruin** → un frammento di trama del circuito. Non un esercizio: una
  riga che si aggiunge al Codex. E' la rovina dei Primi, e le ventiquattro
  messe in fila raccontano che qualcuno e' passato di qui prima.

**Tappa B — la bottega guadagna energia con un minigioco.** Oggi la bottega
spende soltanto. Un minigioco specifico — «conta il resto», «pesa la merce» —
con ricompensa in energia da' un motivo per tornarci che non sia comprare.

**Tappa C — gli hazard, finalmente.** Il campo di salvataggio c'e' gia'. Un
hazard e' un tratto che costa energia ad attraversare, oppure che chiede una
prova lampo per essere superato: e' la parte «evitando pericoli» della
richiesta, ed e' l'unica che va costruita da zero.

**Tappa D — piu' di un guado.** Portare i passaggi da uno a due o tre per
mondo, e legarli a prove speciali diverse. E' la meccanica che rende la mappa
una cosa che si apre invece di una cosa che si attraversa.

**Il rischio da tenere d'occhio**, ed e' il motivo per cui A viene prima di C:
ogni cosa che costa energia sulla mappa toglie prove fatte. Il costo della
campagna e' oggi 21,1 ore misurate; una mappa piena di pedaggi la allunga senza
insegnare niente di piu'. Gli strumenti esistenti seguono gia' la regola giusta
— **niente sulla mappa puo' bloccare il gate** — e le tappe nuove devono
rispettarla.

---

## I meccanismi di mappa su tutti i mondi (7 agosto 2026)

Le tappe A-D erano state scritte guardando il mondo 1. Misurate su tutti e
ventiquattro, due incoerenze:

1. **Gli hazard dipendevano dal primo dado.** Il piazzamento provava UNA
   posizione e, se cadeva in acqua o in zona protetta, rinunciava: otto mondi ne
   ricevevano meno di tre, due (L17, L21) ne ricevevano uno. Il numero di
   pericoli variava per niente. **Riparato**: dodici tentativi, come gia' faceva
   il piazzamento dei nemici dieci righe piu' su nello stesso file.
2. **Diciotto mondi su ventiquattro non hanno nessun guado**, perche' non hanno
   torrenti. Non e' un difetto del codice — un guado senza acqua non esiste — ma
   e' un limite grosso: la meccanica che apre fisicamente la mappa, quella che
   ho appena portato da uno a tre, **vive in sei mondi su ventiquattro**.

Mondi con almeno un guado: 4, 8, 9, 16, 17, 22.

**Chiuso il 7 agosto 2026.** Dove manca l'acqua la composizione mette uno
sbarramento di terra — una frana, un cancello dei Primi, una parete incisa — con
la **stessa struttura dati** del guado: l'enigma ci si aggancia senza che nessuna
riga a monte cambi. Ora ogni mondo ha almeno un passaggio da aprire: **sei
d'acqua, diciotto di terra**.

I due tipi non convivono mai nello stesso mondo — dove c'e' l'acqua comanda
l'acqua — perche' guadi e muri insieme renderebbero illeggibile che cosa apre
che cosa.

**Il muro e' un segmento, non un anello**: si puo' sempre girargli attorno.
Aprirlo e' una scorciatoia, non un permesso. E' l'unico modo di rispettare la
regola di tutta la mappa — niente che sta qui puo' fermare la progressione — e
un muro che chiudesse davvero rischierebbe di isolare un POI del gate, difetto
che scoprirebbe un bambino e non un audit.

`world_mechanics_audit` tiene tutto questo: tre hazard e tre edifici piazzabili
in ogni mondo, guadi mai oltre il tetto, e il numero di mondi con acqua
registrato come misura — se scende, la generazione e' cambiata senza dirlo.

---

## La camera sigillata e le pergamene dei Dodici (7 agosto 2026)

Idea del committente, e migliore di quella che avevo proposto io: invece di uno
sbarramento aggirabile, una **zona davvero inaccessibile**, apribile solo con una
prova dedicata, e dentro un tesoro speciale con una **pergamena della storia**.

**Perche' qui chiudere e' sicuro, e altrove no.** Il rischio del vicolo cieco —
quello che tiene gli sbarramenti a forma di segmento — sparisce quando **dentro
non c'e' niente che serva a progredire**. Chi non entra finisce il gioco lo
stesso: gli manca il perche', non il cosa. E' l'unico posto del gioco in cui una
zona e' chiusa davvero, ed e' anche l'unico in cui si puo' fare.

**La storia adattata.** Le ventiquattro pergamene sono l'**altro lato** della
vicenda. I beat di NORA la raccontano dal suo, al presente, mentre accade; le
pergamene sono la voce dei Dodici, scritta quattrocento anni prima da chi c'era.
NORA deduce, i Dodici testimoniano — e ogni tanto si contraddicono fra loro, che
e' la stessa lezione di metodo che il gioco insegna in storia: due fonti che
dicono cose diverse, e bisogna scegliere di quale fidarsi.

L'arco delle pergamene attraversa la trama e la incrocia senza doppiarla: dal
verbale della Prima Cattedra («una cattedra in piu' che nessuno ha voluto
occupare») fino alla riga incisa dall'interno al mondo 24 («avevamo torto su una
cosa sola: che non sarebbe venuto nessuno»). In mezzo, l'undicesima che annota
due date diverse senza dire a quale crede, la dodicesima che conta tredici
schede vuote, e il verbale finale di mano ignota — undici voti a favore, uno
contrario, e il contrario era il suo.

Vale la regola di trama §10.1: **nessuno e' morto**, e le pergamene, essendo piu'
antiche, non potrebbero comunque saperlo — dicono quello che sapevano allora.

`parchment_audit` tiene: ventiquattro pergamene distinte, ognuna con un autore,
nessuna che dica che qualcuno e' morto, e la camera che si apre una volta sola.

---

## «E adesso che faccio?» (7 agosto 2026)

Segnalazione del committente: «dobbiamo spiegare meglio al giocatore cosa deve
fare, e cosa manca per passare di livello al mondo successivo».

### Il difetto non era la scrittura

L'HUD diceva: «Livello 1 · Materia matematica / Apparato: nucleo · padronanza
34%/45% / Nucleo: MAT 60% · ITA 20% · ING 0% · stanze 1/12». Sei numeri e
nessun verbo.

Ma il problema vero e' piu' profondo di una frase scritta male: il gate del
livello chiede **dodici materie per tre condizioni** — accuratezza, copertura,
ritenzione — cioe' **trentasei condizioni insieme**. Riassumerle in due
percentuali non e' una spiegazione corta: e' una spiegazione assente. Un
bambino di undici anni non poteva ricavarne che cosa toccare, perche' i numeri
mostrati non erano nemmeno quelli che il gate guardava.

### Due forme per due domande diverse

| | |
|---|---|
| **IL PASSO** | una frase, **una cosa sola da fare**, con dove farla. Sta nell'HUD e non chiede di essere aperta |
| **IL PERCORSO** | le dodici materie ordinate dalla piu' vicina, con quanto manca a ciascuna. Dietro il pulsante «CHE COSA DEVO FARE?» |

Il pulsante sta **accanto all'obiettivo**, non in un menu: la domanda nasce
guardando l'obiettivo, e la risposta deve stare a un dito.

### Le due regole di scrittura, e sono l'unica cosa che conta

**Mai un numero senza un'azione.** «Padronanza 34%» dice uno stato; «sei al 40%
e serve il 78%: circa 10 prove da superare» dice che cosa fare. Per questo la
distanza si mostra **in prove**, non in percentuale: una percentuale non dice
quanto lavoro manca, un conteggio si'.

**Mai piu' di una cosa alla volta.** Con trentasei condizioni aperte la
tentazione e' elencarle: sarebbe onesto e inutile. Si nomina la materia piu'
vicina al traguardo — quella su cui il prossimo quarto d'ora rende di piu'.

E una terza, nel quadro: **detto una volta, non dodici**. Leggendolo la prima
volta la domanda vera non e' «quanto manca a latino», e' «e dove si fa latino,
se questo mondo e' di matematica?». La risposta e' la stessa per undici materie
su dodici, quindi c'e' una riga sola in cima all'elenco.

### L'errore che ho trovato leggendo, non controllando

La prima versione stampava «Ti mancano 2 argomenti **nuovoi**»: componevo
«nuovo» + «i» per il plurale. Tutti i controlli passavano — la frase aveva un
verbo ed era della lunghezza giusta — e l'ho visto solo stampando quello che il
bambino avrebbe letto.

Il primo rimedio cercava sequenze di vocali «impossibili» in italiano: sbagliato
due volte, perche' «Hai» e «Sei» sono parole normali e perche' non si indovina
la morfologia di una lingua con un elenco di digrammi. Ora l'audit confronta le
frasi con quelle **attese per esteso**: nessun falso allarme, e niente passa.

---

## Elettronica: si impara facendo (7 agosto 2026)

Prima materia portata fino in fondo sulla direttiva «minigiochi che insegnano,
scelta multipla solo nell'esame». Elettronica perche' e' quella da cui e' nata
la segnalazione, e perche' e' il caso peggiore: un decenne non ha mai visto un
rele' ne' un condensatore.

### Una correzione a quello che avevo detto io

Avevo riferito «la scelta multipla e' il 70-80% di ogni banco, toglierla e' il
ribaltamento del programma di contenuto». Il numero era giusto ma descriveva la
cosa sbagliata: e' la composizione del **banco**, non dell'**esperienza**.
Misurata l'esperienza, il costruttore di sessioni mescolava gia' pesantemente
con le forme interattive: **la scelta multipla era il ~20%**. Il lavoro da fare
era un quinto di quello che avevo stimato.

### Che cosa e' cambiato

La manopola c'era gia' (`MC_TARGET_RATIO`, 0,20 per tutti): ora e' per materia,
e per elettronica vale **zero**.

Portata a zero la scelta multipla, il posto se l'e' preso la **risposta
aperta**: 36-38%. Guardando che cosa chiedeva — «come si chiama il componente
che accumula carica fra due armature?» — e' **peggio** della scelta multipla a
quest'eta': quella la parola almeno te la mostra. Sono domande di nomenclatura,
e sapere che si dice «condensatore» non e' aver capito che cosa fa. Fuori
dall'esame sono uscite anche quelle.

Misurato dopo, su otto livelli: **0% di domande secche** nelle sessioni di
apprendimento, tutto portato da abbina, classifica, ordina, costruisci il
circuito, trova il guasto, leggi il grafico. L'**esame** resta al 65-72% di
domande dirette, ed e' voluto: misurare e' un'altra attivita' dall'imparare.

Vale solo per elettronica. In italiano e in inglese una risposta aperta e'
esattamente la prova giusta — si scrive la parola perche' l'obiettivo E' saperla
scrivere — e toglierla li' sarebbe un danno.

### Le spiegazioni, riviste

Uscita la scelta multipla, **le spiegazioni dei minigiochi SONO la lezione**.
Rilette tutte e 67. Le venti di circuito, guasti e classificazione erano buone:
dicono il perche' e nominano l'errore tipico.

Il punto debole erano i **grafici**: undici spiegazioni su ventuno erano la
stessa frase ripetuta («il minimo si trova guardando chi sta piu' in BASSO…»),
e insegnavano a leggere un grafico, non elettronica. Riscritte: il metodo di
lettura resta, ma adesso ognuna dice anche che cosa significa quel punto in un
circuito — «poca corrente vuol dire poca carica che passa ogni secondo: il LED
illumina meno».

### Il controllo che tiene

`elettronica_hands_on_audit` verifica tre cose, e la terza tiene in piedi le
altre due: zero domande secche fuori dall'esame a otto livelli; l'esame che
misura ancora; e almeno quattro formati diversi con **nessuno sopra il 50%** —
sostituire la scelta multipla con un unico minigioco ripetuto sarebbe lo stesso
difetto con un altro nome.

Serve perche' il mix nasce da una tavolozza: se un giorno si assottiglia — un
`minLevel` spostato, una specifica tolta — la sostituzione non trova piu'
materiale e **le domande secche tornano da sole**, senza che nessuno lo abbia
deciso.

### Estenderla alle altre undici

Il costo vero e' la **tavolozza dei minigiochi**: elettronica ce l'aveva gia'
profonda (ventuno argomenti coperti, sette formati). Dove e' piu' magra, portare
la scelta multipla a zero lascerebbe buchi — e l'audit lo direbbe subito, che e'
il motivo per cui e' scritto sui formati e non solo sulla percentuale.

---

## Insegnare prima di chiedere (7 agosto 2026)

Segnalazione del committente, ed e' un richiamo alla promessa del prodotto:
«gli esercizi di fisica e circuiti interrogano su argomenti di non competenza
per un bambino di 10 anni. Lo scopo del programma e' didattico non
interrogatorio su argomenti mai visti. Ripeto: dobbiamo insegnare e non testare
competenze che il bambino non ha mai visto».

### La misura, che ha dato ragione alla segnalazione e l'ha allargata

Il meccanismo «NORA spiega prima di chiedere» esisteva da tempo. Leggeva pero'
il topic del **primo nodo** della sessione e si fermava li' — e una sessione ha
tre nodi, spesso su argomenti diversi.

Misurato su 1440 nodi in dodici materie: **il 60,6% delle domande arrivava su un
argomento mai spiegato in quella sessione**. E in modo uniforme: matematica 68,
italiano 77, fisica 73, elettronica 73. Non era un difetto di fisica — era la
regola, e fisica ed elettronica lo facevano solo notare di piu' perche' i loro
argomenti sono i piu' lontani dall'esperienza di un bambino.

**Dopo la correzione: 0,1%**, e i pochi residui erano un difetto del mio
controllo (due nodi sullo stesso argomento: la lezione sta sul primo, ed e'
giusto cosi').

### Che cosa e' cambiato

| | |
|---|---|
| la lezione copre **ogni** argomento nuovo | `outdoor_gameplay.gd`, `_decorate_teaching_session` |
| la scheda compare **davanti alla sua domanda**, non tutta in testa | `exercise_player.gd`, lezione sul nodo |
| il manuale e' raggiungibile **prima** di sbagliare | `SPIEGA CON NORA` sempre visibile fuori dall'esame |
| l'esempio svolto di matematica aveva la risposta ma non la domanda | `knowledge_codex.gd`, `prompt`/`answer` separati |
| il controllo che tiene tutto | `teach_before_ask_audit` |

Tre spiegazioni di fila all'inizio si leggono come un muro e non se ne ricorda
nessuna: la scheda compare quando serve, ed e' il motivo per cui la lezione
viaggia sul nodo invece che sulla sessione.

### I quesiti che non insegnavano niente

Quarantotto item su 3412 erano generati da modelli: «Quale affermazione descrive
correttamente <etichetta>?» e «Lavorando su <etichetta>, quale errore bisogna
evitare?». Chiedono di riconoscere la definizione di un'**etichetta**, con
distrattori «veri ma di un altro argomento» — non si puo' rispondere senza aver
letto quella frase esatta, e la spiegazione lo ammetteva: «le altre sono vere ma
parlano d'altro».

I **26** di fisica e musica sono stati riscritti in domande concrete: il chilo di
piombo e il chilo di piume, le racchette da neve, il lampo e il tuono, la battuta
di 4/4 con dentro una minima. La spiegazione adesso dice il **procedimento**, non
il verdetto.

Riscrivendoli avevo messo la risposta giusta sempre in prima posizione, e le
opzioni **non vengono rimescolate a runtime**: sarebbe stato un regalo. Ora la
posizione e' distribuita in modo uniforme e deterministico dall'id.

### Quello che NON e' stato fatto, e quanto costa

La richiesta contiene una seconda meta' che e' un programma, non una
correzione: **«minigiochi che insegnino i concetti, e domande a scelta multipla
solo nell'esame di livello»**.

Misurato: la scelta multipla e' il **70-80% di ogni banco**, in tutte e dodici le
materie (2545 item su 3412). Toglierla fuori dall'esame vuol dire che le forme
interattive devono reggere **quattro esercizi su cinque** invece di uno su
cinque. Non e' una modifica: e' il ribaltamento del programma di contenuto, e
farlo a meta' lascerebbe i mondi senza niente da estrarre.

Restano aperte, dichiarate: i **22 quesiti sui componenti elettronici** (rele',
condensatore) — li' il problema non e' la forma della domanda ma il fatto che un
decenne non ha mai visto l'oggetto, e la risposta giusta e' un minigioco che
glielo faccia montare; e i **dialoghi con NORA** che spieghino i concetti.

---

## Gli Sbiaditi diventano un pericolo: i guardiani e il varco (7 agosto 2026)

Richiesta del committente: «i nemici devono essere un pericolo e rendere
sfidante muoversi nella mappa, i nemici proteggono i bauli con i frammenti.
Sarebbe interessante poterli eliminare con un minigioco di riflessi ed in base
al progresso del personaggio».

**Perche' prima non erano un pericolo.** Le sacche pattugliavano il vuoto e
facevano perdere energia a chi passava di li'. Quella e' una **tassa**, non un
pericolo: non c'era niente da difendere e quindi niente da conquistare. Un
pericolo e' qualcosa che sta **fra te e una cosa che vuoi** — e allora
avvicinarsi diventa una decisione invece che un incidente.

**Cosa sorvegliano, e perche' proprio quello.** I forzieri contengono
frammenti, cioe' cosmetici: **niente che serva a progredire**. E' la condizione
che rende lecito mettere una prova di abilita' davanti a un premio in un gioco
che si studia — chi non vuole giocare di riflessi finisce la campagna
esattamente come prima, e si perde solo i vestiti. Se un giorno qualcosa di
necessario finisse dietro una sacca, questa riga e' la prova che e' un errore.

**Il varco.** Un cursore corre su una pista, un tratto e' il varco, si colpisce
quando ci passa dentro. Tre leve si muovono col grado di potenza di Eli: il
varco e' **piu' largo**, il cursore va **piu' piano**, si possono sbagliare
**piu' colpi**. Tutte e tre si muovono al contrario col grado della sacca. Una
sacca molto piu' forte diventa cosi' *oggettivamente difficile* invece che
semplicemente costosa: e' la differenza fra un pedaggio e un pericolo.

**La misura che ha cambiato il progetto in corsa.** Alla prima versione ogni
forziere aveva la sua guardiana: **da otto a quindici in vista insieme**. Non e'
un pericolo, e' un assedio — e un assedio non si affronta, si evita. Ora ne e'
difeso circa **uno su tre**, deciso dall'identificativo del forziere (stabile:
un premio a volte difeso e a volte no insegnerebbe solo a riprovare), con un
tetto di **quattro guardiani vivi** e un raggio franco attorno allo spawn.
Misurato dopo: da uno a quattro. La scelta fra prendere il forziere facile o
guadagnarsi quello difeso e' il gioco.

**Due regole che l'audit protegge** (`reflex_duel_audit`): nessuna combinazione
di gradi produce un varco sotto il 5% della pista (a quel punto non e'
difficile, e' casuale) ne' sopra il 50% (a quel punto e' un regalo); e
**perdere il duello non costa mai piu' di un morso** — se costasse di piu', la
scelta razionale sarebbe girare alla larga, e il minigioco non lo giocherebbe
nessuno.

---

## Le minimissioni: piano ed esecuzione (7 agosto 2026)

Nasce dalla domanda rimasta aperta dopo il collaudo — «cosa puo' succedere sulla
mappa che non sia un esercizio?» — e dalla risposta del committente: minimissioni
che **cambiano la mappa**. Liberare degli animali, spegnere un incendio,
aggiustare un faro, riparare un mulino.

### Che cosa e' stato costruito, e che cosa e' stato misurato

Il piano qui sotto e' stato eseguito nella stessa giornata, dopo la direttiva
esplicita del committente: **«accolgo sostituire e non aggiungere»**.

| pezzo | dove |
|---|---|
| i ventiquattro incarichi scritti | `minimission_catalog.gd` |
| la sostituzione | `mission_event_director.gd`: l'incarico prende l'**ultimo** slot-gate |
| la sessione, il grado e il rischio | `outdoor_gameplay.gd`, `try_start_minimission` |
| il mondo che cambia | `outdoor_world.gd`, `_disegna_incarico` / `_esito_visivo` |
| il Lascito che le pesa | `legacy_score.gd`: una riparazione vale tre incontri |
| i due controlli | `minimission_audit` (catalogo, forme, sostituzione) e `minimission_scene_audit` (si apre, cambia, **resta cambiato**) |

**La misura che conta.** `time_cost_probe` prima: **21,1 ore**. Dopo: **21,1
ore**. La sostituzione ha tenuto al minuto — l'incarico eredita le tre campate
della missione che ha preso il posto, e il conto degli esercizi del mondo non
cambia di uno. Non e' una previsione: e' la stessa sonda, prima e dopo.

**Una correzione in corsa che vale la pena ricordare.** Il primo tentativo
metteva l'incarico allo slot 0, che e' un enigma quando il mondo ne ha uno: nei
mondi con un enigma solo l'incarico **lo cancellava**, e il mondo perdeva una
meccanica invece di guadagnarne una. L'hanno detto `enigma_cooldown_audit` e
`enigma_scene_audit` diventando rossi, ed e' esattamente il mestiere loro:
sostituire e' giusto, ma va sostituita la cosa giusta.

**Una deviazione dichiarata.** Il piano prevedeva un **timer** per la forma
SPEGNERE. Non c'e': un cronometro mentre si legge una domanda misura la
velocita' di lettura, che in un gioco che si studia — e che ha fra i suoi vincoli
la dislessia — e' l'ultima cosa da punire. Il rischio e' stato messo altrove e
solo per chi entra sotto il grado consigliato: **ogni risposta sbagliata fa
allargare il danno** e costa un'energia in piu'. Stessa pressione, e non colpisce
chi legge piano.

**Quello che resta da fare** e' la comparsa procedurale (oggi l'incarico c'e' dal
primo ingresso, in un punto deciso dal seme; non «si accende» mentre giochi) e
gli epiloghi che le **nominano** una per una: oggi le contano soltanto.

---

### Il ribaltamento, in una riga

Oggi l'esercizio e' il **fine** e il luogo e' la cornice. Nelle minimissioni
l'esercizio e' il **mezzo** e il cambiamento del mondo e' il fine. Non e' una
sfumatura: e' la differenza fra «fai tre esercizi e la barra sale» e «l'incendio
si sta allargando, tre risposte giuste e lo spegni». Lo sforzo e' identico, il
motivo no — ed e' il motivo che il collaudo ha trovato mancante.

### Cosa esiste gia', e va riusato invece di rifatto

| pezzo | dove | a cosa serve qui |
|---|---|---|
| **l'enigma a campate** | `enigma_progress`, `EnigmaStructureVisual` | E' **gia' una minimissione**: ogni risposta giusta costruisce una campata del ponte, e alla fine il ponte c'e'. E' il prototipo funzionante di tutto il lotto |
| `LearningReaction` | su ogni POI | il luogo reagisce alla singola risposta, non solo alla fine |
| `environment_transform` | `world_lesson.gd` | ogni mondo dichiara gia' come cambia quando la lezione e' fatta |
| guadi e sbarramenti | `crossings` | una prova che apre fisicamente un passaggio: gia' in piedi |
| gradi di potenza | `world_light.gd` | la forza acquisita, che oggi serve solo contro le sacche |

**L'enigma va guardato bene**: e' l'unico posto del gioco dove una prova produce
gia' un oggetto nel mondo. Le minimissioni sono quello, generalizzato a cinque o
sei forme invece di una.

### Le forme, e perche' queste

Quattro archetipi bastano a coprire ventiquattro mondi senza ripetersi, perche'
ognuno chiede un'**azione mentale** diversa e non solo una scenografia diversa:

- **SPEGNERE** (incendio, falla, cortocircuito) — c'e' un timer: se non arrivi
  in tempo il danno si estende. E' l'archetipo del RISCHIO, ed e' l'unico con
  una pressione temporale;
- **LIBERARE** (animali in gabbia, un ponte crollato su qualcuno, una porta
  bloccata) — nessun timer, ma il numero di prove dipende da quanti sono. E'
  l'archetipo della RICOMPENSA VISIBILE: gli animali restano nel mondo;
- **RIPARARE** (mulino, faro, pompa, telaio) — a campate, come l'enigma: ogni
  risposta rimette un pezzo, e la macchina alla fine **funziona** e fa qualcosa
  (il mulino macina, il faro illumina un tratto di mappa);
- **RIACCENDERE** (un quartiere, una serra, una linea) — la piu' legata alla
  luce: l'area attorno si scopre in modo permanente.

### Dove sta l'imprevedibilita', e dove NON deve stare

**Procedurale il QUANDO e il DOVE, autoriale il COSA.** Gli eventi compaiono a
sorpresa (un incendio si accende, degli animali scappano) in punti che dipendono
dal seme del mondo; ma il testo, la materia e il numero di prove sono scritti a
mano per mondo, perche' e' la parte che porta la storia.

Il contrario — testi generati, posizioni fisse — darebbe varieta' dove non serve
e ripetizione dove fa male. E' la stessa lezione delle ricette: la varieta' che
conta e' quella delle **azioni**, non quella dei parametri.

### Il rischio, e come lega alla forza

La forza acquisita oggi serve solo a non farsi mordere. Nelle minimissioni serve
a **poter provare**:

- una minimissione ha un grado richiesto: sotto quel grado si puo' tentare, ma
  il tempo concesso e' minore e il costo d'ingresso maggiore;
- fallire non punisce: l'evento **resta li'** e si puo' tornare piu' forti. E'
  la differenza fra un gioco difficile e un gioco che si smette — e vale il
  guard-rail di sempre, **niente sulla mappa puo' fermare la progressione**;
- riuscire sotto il grado richiesto e' il momento migliore del gioco, e va
  celebrato: e' la storia che un bambino racconta a voce.

### La storia che le tiene insieme

Non ventiquattro incarichi scollegati: **le riparazioni che i Dodici hanno
lasciato a meta'**. Quando il Silenzio e' arrivato, ognuno ha abbandonato una
cosa a meta' — e in ogni mondo quella cosa e' ancora li', ferma da quattrocento
anni. E' il filo che lega gia' le pergamene (la voce dei Dodici) e gli apparati
della nave (le stanze da riaccendere): le minimissioni sono la **terza faccia**
della stessa vicenda, quella che si tocca con le mani.

Il finale ne guadagna gratis: il Lascito puo' pesare quante ne hai chiuse, e gli
epiloghi possono nominarle.

### Le tappe

1. **una forma sola, un mondo solo** — RIPARARE al mondo 1, riusando la
   meccanica a campate dell'enigma. Serve a misurare il tempo che aggiunge e a
   vedere se il collaudo la sente diversa da un esercizio;
2. **le altre tre forme**, un mondo ciascuna;
3. **l'imprevedibilita'**: comparsa procedurale, timer dello SPEGNERE, grado
   richiesto;
4. **ventiquattro incarichi scritti**, uno per mondo, legati alle pergamene;
5. **il Lascito e gli epiloghi** ne tengono conto.

**Da misurare prima di allargare** (tappa 1 -> 2): quanto allunga il mondo. La
campagna sta a 21,1 ore e il collaudo ha gia' detto «faticoso»: se una
minimissione aggiunge dieci minuti per mondo, sono quattro ore in piu'. La
risposta giusta e' probabilmente **sostituire**, non aggiungere — una
minimissione al posto di N prove sparse, non in piu'.

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
