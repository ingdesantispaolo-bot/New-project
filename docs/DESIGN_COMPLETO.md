# Eli Quest — Design Completo (modello semplificato)

> Design di riferimento del gioco. Direzione e pilastri in
> [VISIONE_DI_GIOCO.md](VISIONE_DI_GIOCO.md); architettura e piano di migrazione
> a motore unico in [ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md).
>
> **Modello semplificato**: le **missioni stanno tutte nel mondo esterno** e si
> tarano sul **livello attuale** del giocatore; la **nave** contiene gli
> **apparati** da riparare superando un **esercizio finale** per ogni livello.
> Progressione lunga: **almeno 20 livelli**.

Indice:
1. [Il loop centrale](#1-il-loop-centrale)
2. [Livelli e progressione](#2-livelli-e-progressione)
3. [Il mondo esterno: le missioni](#3-il-mondo-esterno-le-missioni)
4. [La nave: gli apparati](#4-la-nave-gli-apparati)
5. [Materie e apparati](#5-materie-e-apparati)
6. [Sistema degli esercizi](#6-sistema-degli-esercizi)
7. [Economia dell'energia](#7-economia-dellenergia)
8. [Potenziamenti e acquisti](#8-potenziamenti-e-acquisti)
9. [Storia e NORA](#9-storia-e-nora)
10. [Engagement e ritmo](#10-engagement-e-ritmo)
11. [UX, HUD, onboarding](#11-ux-hud-onboarding)
12. [Accessibilità e benessere](#12-accessibilità-e-benessere)
13. [Telemetria e cruscotto docente](#13-telemetria-e-cruscotto-docente)

---

## 1. Il loop centrale

```
FUORI (mondo esterno) = TUTTE le missioni
   svolgi missioni-esercizio TARATE SUL TUO LIVELLO ATTUALE, per materia
   → guadagni energia + padronanza(materia) + conteggio missioni(materia)

DENTRO (nave) = apparati da riparare
   quando  padronanza(materia) ≥ soglia del livello  E  missioni(materia) ≥ N
   → si sblocca l'ESERCIZIO FINALE dell'apparato di quella materia
   → superandolo RIPARI l'apparato = completi quel livello

AVANZAMENTO
   riparato l'apparato del livello → SALI DI LIVELLO (1 → 20+)
   → si sblocca un NUOVO MONDO ESTERNO con grafica e tema propri
   → le missioni diventano più difficili (tarate sul nuovo livello)
   → la nave si accende, la storia avanza
```

Due luoghi, due funzioni nettamente separate:
- **Il mondo esterno è la palestra**: qui si fa tutto l'allenamento (le missioni).
- **La nave è il traguardo e il cruscotto**: qui si riparano gli apparati (gli
  "esami finali") e si vede la progressione prendere vita.

Niente più missioni sparse nelle stanze: la nave contiene **solo** gli apparati.

---

## 2. Livelli e progressione

- **Fascia di lancio: 10–13 anni** (fine primaria + secondaria di primo grado),
  decisa il 29 luglio 2026. Tutte e **12 le materie sono obbligatorie**: i 24
  mondi sono 12 materie × 2 comparse e il finale accende i dodici sistemi.
- Il giocatore ha **un livello globale L**, da **1 ad almeno 20** (spina dorsale
  della progressione, tarabile fino a 24+).
- La difficoltà segue le **due comparse** di ogni materia, non il solo numero del
  mondo: mondi 1–12 sono l'**introduzione** (difficoltà bersaglio da 1 a 3),
  mondi 13–24 l'**approfondimento** (da 3 a 4). Così ogni materia ha un mondo in
  cui si conosce e uno in cui si approfondisce, comprese le ultime del ciclo.
- **Dopo il mondo 24** le rivisitazioni sono **ripasso mirato**: nel mondo che si
  torna a visitare le prove sono quelle di quel mondo (suoi argomenti, sua banda)
  con priorità agli argomenti deboli e in scadenza di ripasso. Nessuna banda di
  difficoltà oltre la 4. L'esame dell'apparato resta al rango del giocatore.
- L'avanzamento è una **scala di riparazioni**: ogni gradino/livello = riparare
  **un apparato** (esercizio finale) nella nave.
- Ogni livello ha una **materia in focus** (a rotazione): la scala cicla le
  materie con difficoltà crescente, così ogni disciplina torna più volte, sempre
  più su.

### Nucleo e satelliti (decisione del 30 luglio)

**Si sale di livello con tre materie; si finisce il gioco con dodici.**

| | Materie | Ruolo |
|---|---|---|
| **Nucleo** | italiano, matematica, inglese | **Gatano il livello.** Sono le competenze *abilitanti*: leggere, calcolare, comunicare. Le altre nove ci poggiano sopra |
| **Satelliti** | le altre nove | **Non gatano il livello.** Danno ricompense, accendono le stanze della nave e **sono obbligatorie per il finale** |

Due assi che prima erano uno solo:

| Asse | Governato da | Cosa fa |
|---|---|---|
| **Livello** (1→24) | il nucleo | Sale con le tre strumentali; tara la difficoltà di tutto |
| **Apparati** (12 stanze) | ogni materia, quando si vuole | Si riparano a padronanza sufficiente. I tre del nucleo si accendono lungo la strada; i nove satelliti sono la collezione |
| **Mondi** (24) | la materia che li abita | Invariati: lezione, landmark, abitanti, trasformazione. È il posto dove quella materia *vive*, non ciò che sblocca il livello |

Questo è possibile **solo** perché ogni mondo ospita tutte e dodici le materie
(decisione dello stesso giorno): prima il nucleo non era praticabile nel mondo 7.

### Requisiti per salire dal livello L a L+1

Per **ciascuna** delle tre materie del nucleo, **niente conteggio di missioni** —
si sale quando la competenza c'è, non quando si sono fatti abbastanza giri:

1. **Accuratezza**: mastery ≥ soglia del livello.
2. **Copertura**: abbastanza argomenti distinti incontrati (non basta ripetere il
   più facile).
3. **Ritenzione**: nessun argomento arretrato nel ripasso spaziato.

Le dimensioni 2 e 3 non sono un contorno: **senza il conteggio sono loro a
impedire che una serie fortunata apra il gate.** Chi fatica non resta bloccato,
perché la difficoltà adattiva abbassa gli item finché l'accuratezza risale.

### Requisiti per riparare l'apparato della materia S

1. **Padronanza**: mastery di S ≥ soglia.
2. **Esercizio finale**: superare l'esame cumulativo di S (l'atto di riparazione,
   nella nave).

Riparare un apparato **non fa più salire di livello**: accende una stanza. I tre
del nucleo si riparano naturalmente avanzando; i nove satelliti quando si vuole.

### Come si garantisce che tutte le competenze vengano acquisite

Rendere opzionali nove materie è il modo più diretto per non farle fare mai: i
premi sono motivatori più deboli dei gate. Quattro leve, in ordine di forza reale:

1. **Il finale le richiede tutte.** Il Cuore accende dodici sistemi: si apre con
   **dodici stanze accese**, non con ventiquattro livelli. È l'unica garanzia
   strutturale, e sblocca il Secondo Viaggio.
   **Vincolo che ne discende**: la nave deve dichiararlo fin dall'inizio,
   altrimenti si arriva al livello 24 senza latino e si trova una prova a dodici
   sistemi impossibile — un vicolo cieco creato da questa stessa decisione.
2. **La nave visibilmente incompleta.** Nove stanze buie motivano più di
   qualunque contatore. La nave era già la barra di progresso diegetica: ora è
   anche la lista di ciò che manca.
3. **Bonus crescente sulle materie trascurate.** Una materia non toccata da N
   livelli offre ricompense che salgono: pressione **positiva e autocorrettiva**,
   mai una penalità.
4. **Il Custode come collezione.** Facce, combinelle e accessori sbloccati
   toccando materie diverse — l'«esploratore completo» promesso da §3.

Vincoli invariati: nessun premio scavalca una prova di competenza, e nessuno è
punito per non aver fatto i satelliti.

### Argomento CONSOLIDATO (≠ requisito del gate)
Un argomento è dichiarato **consolidato** con **tre risposte corrette in sessioni
distinte**, di cui almeno una a **≥ 3 giorni** dalla prima (decisione del 29
luglio 2026). Rispondere bene tre volte nella stessa mezz'ora non è ritenzione:
serve che la conoscenza sopravviva a una notte di sonno.

Il consolidamento **non è un requisito per avanzare**: se lo fosse, un mondo non
sarebbe completabile in un pomeriggio e la progressione dipenderebbe dal
calendario. È ciò che si dichiara all'adulto (Manuale, report) e la soglia dello
stato "consolidato" nel Codex. La dimensione RITENZIONE del gate continua a
chiedere soltanto che nessun argomento sia arretrato nel ripasso spaziato.

### Una materia CERTIFICATA non si rifà (a quel grado)
Superare l'esame di una materia accende la sua stanza e la **certifica per il
livello corrente**: da quel momento e finché il livello non sale, quella materia
non compare più fra le mancanti del gate e il suo esame non viene più offerto.

Serviva perché due strade la riportavano indietro dopo che era stata passata:

- il **decadimento per trascuratezza** faceva scendere la padronanza sotto soglia
  mentre il bambino lavorava sulle *altre* materie — cioè facendo esattamente ciò
  che il gate chiede. Misurato: certificata con 0,85, dopo 45 sessioni altrove
  scendeva a 0,722 contro una soglia di 0,78, e tornava «da fare» con la stanza
  accesa in bella vista;
- l'**esame restava avviabile**, e ogni ripetizione ripagava gli 80 di energia
  della riparazione: la prova appena superata riproposta con il premio più grosso
  del gioco appeso davanti.

La certificazione vale **solo per il grado in cui è stata presa**. Al livello
successivo, e al secondo passaggio della materia (mondi 13-24), il grado è un
altro e si ricomincia: è la ragione per cui la scala ha ventiquattro mondi e non
dodici. Il decadimento resta e la padronanza mostrata è quella vera — cambia solo
che non può più disfare una prova superata. Tenuto da
`subject_certification_audit.gd`.

### Una materia IN LINEA non ricade perché ne hai giocata un'altra
Estensione della regola precedente alle **undici materie che in un mondo non
hanno un esame**. La certificazione nasce dall'esame d'apparato, e in un mondo se
ne dà uno solo: le altre undici il bambino le porta in linea con le palestre, e
per loro non c'era nessun traguardo registrato.

Segnalazione di gioco del 16 agosto 2026: nel mondo 1, superata la prova di
musica, l'elenco degli obiettivi tornava a chiedere **elettronica**, già portata
in linea poco prima.

La causa **non era il decadimento** — la padronanza misurata restava a 0,900 —
era la **RITENZIONE**. L'orologio del ripasso spaziato è uno solo per tutta la
partita e avanza a ogni sessione risolta, di qualunque materia: un argomento di
elettronica ripassato bene torna dovuto due sessioni dopo, e se quelle due
sessioni sono di musica, elettronica cade da sola. Con dodici materie da tenere
in linea insieme ognuna rimetteva indietro le altre — giocare la cosa giusta
disfaceva il lavoro appena fatto, che è il modo più rapido di convincere un
bambino che il gioco non tiene il conto.

Ora, quando una materia centra tutte e tre le condizioni, il grado a cui l'ha
fatto viene **registrato** (`gateClearedLevel` nel save) e da lì in avanti quella
materia è a posto per quel grado: fuori dall'elenco delle mancanti, esame aperto
se è quella del mondo, e l'arco del suo residente non regredisce.

Quello che **non** cambia, e conta quanto il resto:

- i numeri veri restano veri. `apparatus_readiness` continua a misurare senza
  guardare il traguardo, il ripasso continua a riproporre gli argomenti dovuti e
  NORA continua a dirlo. Il traguardo cambia che cosa il gioco **chiede**, non
  che cosa il gioco **mostra**;
- il traguardo vale per il suo grado e scade salendo di livello, esattamente come
  la certificazione;
- non regala niente: si registra solo raggiungendo davvero le tre condizioni.

Tenuto da `materia_in_linea_audit.gd`.

### Esempio di scala (tunable, dati)
| Livello | Materia in focus | Apparato (stanza) | Missioni richieste (N) | Soglia mastery |
|---|---|---|---|---|
| 1 | matematica | Nucleo | 5 | 0.70 |
| 2 | italiano | Data-core | 5 | 0.70 |
| 3 | coding | Cratere Logico | 6 | 0.72 |
| 4 | inglese | Data-core | 6 | 0.72 |
| 5 | fisica | Ponte di Comando | 6 | 0.74 |
| 6 | musica | Motore a Risonanza | 6 | 0.74 |
| 7 | matematica (avanzata) | Nucleo | 7 | 0.76 |
| … | … (ciclo materie, difficoltà ↑) | … | … | … |
| 20+ | esame trasversale | Ponte Centrale | 10 | 0.85 |

I numeri sono **costanti di bilanciamento** (in un file dati), non fissi nel
codice: si tarano con la telemetria.

### Cosa determina il livello
Il livello globale L è quello **più alto raggiunto**; tara la difficoltà delle
missioni esterne. La mastery per materia e i conteggi missioni sono i **gate**
verso l'esercizio finale del livello corrente.

---

## 3. Il mondo esterno: le missioni

**Tutte** le missioni vivono nei mondi esterni Godot. Ogni livello possiede un
mondo distinto: la procedura distribuisce contenuti dentro un'identità autorata,
non decide l'identità del mondo.

### Un mondo esterno per ogni livello

Ogni `WorldProfile` definisce almeno: tema, famiglia di terreno, topologia,
palette/materiali, vegetazione o architettura, luce/meteo, soundscape, landmark
principale, pool di missioni/eventi e posizione dell'ingresso nave.

- Il nuovo mondo deve essere immediatamente riconoscibile in una cattura senza HUD.
- L'ingresso della nave ha posizione deterministica, area libera riservata,
  percorso iniziale sicuro e indicazione in bussola.
- Il generatore non può collocare ostacoli, acqua, incontri o tesori nella zona
  protetta dell'ingresso.
- I mondi sbloccati sono rivisitabili da una mappa di navigazione della nave.
- Una semplice ricolorazione non soddisfa il criterio di mondo nuovo.

- Una **missione** è una sfida-esercizio (o una breve catena di 2–4 esercizi)
  della materia della missione, **tarata sul livello attuale del giocatore**.
- Le missioni sono **luoghi**: landmark, incontri, beacon. Raggiungerle e
  superarle è il gameplay principale.
- Ogni missione superata: **energia** (con moltiplicatore combo) + **padronanza**
  della sua materia + **+1 al conteggio** di quella materia per il livello.
- **Taratura sul livello**: la difficoltà degli esercizi, il numero di tappe e le
  ricompense scalano con L. Salendo di livello, il mondo si fa più impegnativo.
- **Adattività dentro il livello**: a parità di L, la selezione pesca dalla
  materia/argomento più debole e ripropone come **ripasso** gli argomenti
  sbagliati (bonus riscatto). L'errore ha una penalità morbida (combo/scudo), ma
  non cancella i progressi: al massimo fa fallire e ripetere la missione.
- **Varietà**: missioni di materie diverse convivono nel mondo; toccarne di
  varie dà il bonus "esploratore completo".

Tipi di missione (per non annoiare):
| Tipo | Cosa |
|---|---|
| Prova NORA | combattimento a quiz (esiste): rispondi per "colpire". |
| Missione a tappe | 2–4 esercizi crescenti nello stesso luogo. |
| Enigma ambientale | usa la conoscenza per agire sul mondo (allinea i cristalli, costruisci il ponte). |
| Evento-minigioco | attività breve casuale — ordina, abbina, classifica, costruisci — incontrata sulla mappa o innestata in una missione. |
| Beacon a tempo | missione notturna opzionale, ricompense rare. |

Le Palestre fisse non sono il target finale. Un `MissionEventDirector` sceglie
eventi compatibili con mondo, materia, livello e bisogno didattico. La posizione
non nasce più da una rotazione radiale: la composizione espone **luoghi
semantici** (regioni, strumenti, landmark, sentieri e varchi), raggruppati in
costellazioni. Il Director abbina formato e materia alle affordance del luogo;
seed e casualità risolvono soltanto i pareggi. Una Casa del mestiere illustrata
ospita la materia guida del mondo, mentre strumenti e siti esterni danno una
forma alle prove sul campo. Dettagli e criteri: [ESPLORAZIONE_SEMANTICA.md](ESPLORAZIONE_SEMANTICA.md).
Se il minigioco è una tappa di missione, vale come tappa e non come missione
aggiuntiva; gli eventi di pratica libera migliorano mastery/ripasso ma non
farmano il gate.

---

## 4. La nave: gli apparati

La nave (hub) non contiene missioni: contiene **apparati guasti** da riparare e
mostra la **progressione**.

- Ogni **apparato** è legato a una **materia** e vive in una **stanza**.
- L'apparato ha uno **stato per livello**: guasto → (requisiti soddisfatti) →
  **riparabile** → riparato.
- **Riparare** = avviare l'**esercizio finale** del livello per quella materia:
  un esame cumulativo, più difficile di una missione, che verifica la padronanza.
  Superarlo accende l'apparato e completa il livello.
- **Feedback visivo forte**: la nave si illumina stanza dopo stanza mentre sali
  i 20+ livelli. La nave *è* la barra di progresso, diegetica e soddisfacente.
- **NORA** commenta ogni riparazione: un pezzo della sua mente torna, un beat di
  storia si sblocca.

La stanza mostra chiaramente: *quante missioni mancano*, *quanta padronanza
manca*, e il pulsante "Ripara" attivo solo quando i requisiti sono soddisfatti
(goal-gradient: sai sempre cosa ti separa dal prossimo apparato).

---

## 5. Materie e apparati

Riuso delle stanze/sistemi già esistenti come apparati:

| Apparato (stanza) | Materia/e |
|---|---|
| Nucleo | matematica / logica |
| Cratere Logico | coding |
| Data-core | inglese, italiano |
| Sala dei Glifi | latino |
| Ponte di Comando | fisica, geografia |
| Motore a Risonanza | musica |
| Reattore | elettronica |
| Ponte Centrale | esami trasversali (livelli alti) |

Le materie **ruotano** lungo la scala dei 20+ livelli; alcune stanze ospitano più
materie e vengono riparate più volte, a stadi crescenti.

---

## 6. Sistema degli esercizi

Gli esercizi sono l'anima: **tanti, vari, corretti, spiegati**.

**Formati** (mix): scelta multipla, inserimento numerico/testuale,
ordinamento/sequenza, abbinamento, vero/falso motivato, lettura di grafici/carte,
mini-debug, drag-and-drop, hotspot su immagini/mappe, costruzione di circuiti,
composizione di frasi, tracciamento di grafici, simulazioni e manipolazione
diretta di oggetti nel mondo.

La scelta multipla resta nel repertorio ma non è il formato dominante: come
target iniziale non deve superare un terzo dei nodi di una missione standard.
Un esercizio finale deve usare almeno due famiglie d'interazione e contenere una
prova di trasferimento in un contesto nuovo; non può essere composto soltanto da
scelte multiple.

**Ciclo di un esercizio**
1. Una domanda per schermata, testo breve.
2. Risposta.
3. **Feedback immediato e didattico**: giusto → celebrazione + energia; sbagliato
   → **spiegazione del perché** + **penalità morbida** (azzera la combo, toglie
   uno "scudo" della prova); l'argomento entra nel **ripasso spaziato**.
4. Aggiorna padronanza, streak/combo, energia, conteggio missioni.

**Politica dell'errore.** Ogni errore è **istruttivo** (spiegazione) e ha una
**conseguenza morbida**: perdi la combo e uno scudo; se gli scudi di una prova
finiscono, la missione **fallisce e va ripetuta**. Mai una penalità distruttiva:
non si perde il livello raggiunto né l'energia già guadagnata. Posta in gioco
reale, ma nessun muro che demotiva.

**Missione vs esercizio finale**
- **Missione** (fuori): allenamento, 1–4 esercizi, tarata su L, adattiva.
- **Esercizio finale** (nave): esame del livello per la materia, cumulativo e più
  severo; è il gate che ripara l'apparato. Richiede padronanza reale (mai
  fortuna, mai solo energia).

**Qualità**: ogni esercizio risolvibile e verificato (validatori esistenti);
**nessun item ambiguo o senza spiegazione**.

**Combo**: risposte corrette consecutive → moltiplicatore energia (x1.2→x2)
visibile; l'errore lo azzera e toglie uno scudo della prova (posta in gioco
reale, mai distruttiva).

---

## 7. Economia dell'energia

**L'energia si guadagna SOLO svolgendo missioni** (imparando). Valuta primaria;
i **frammenti** sono la secondaria del mondo (tesori, beacon).

> **Aggiornamento del 14 agosto 2026 — le due valute sono separate.** L'energia
> la fa lo studio e la spendono le prove; i frammenti li fa l'esplorazione e li
> spende la bottega. Prima l'energia faceva tutti e due i mestieri e comprare
> competeva con l'allenarsi. Le tariffe, la taratura misurata e il contenuto dei
> forzieri stanno in [FORZIERI_E_FRAMMENTI.md](FORZIERI_E_FRAMMENTI.md); la
> tabella dei sink qui sotto va letta con «energia» → «frammenti».

### Fonti
- Missioni superate (base + moltiplicatore combo), scalate su L.
- Riparazione di un apparato (grande pacchetto + frammenti).
- Bonus giornaliero + **streak** + **varietà** di materie.
- Tesori/beacon nel mondo.

### Sink (tre motivazioni)
| Sink | Motivazione | Effetto |
|---|---|---|
| Estetica (bottega) | identità/status | outfit, accessori, pet — visibili nel mondo |
| Moduli NORA | potere/comodità | aiuti al gameplay e all'apprendimento |
| Comfort di progressione | ritmo | es. ridurre N missioni residue, ripasso mirato extra |

### Principi
- La **sessione breve quotidiana** deve dare un progresso percepibile; la maratona
  ha **rendimenti calanti** (spacing effect → meglio per l'apprendimento).
- I moduli **non saltano** l'apprendimento: lo rendono più gentile (un indizio
  costa, una seconda chance costa). L'energia si è comunque guadagnata studiando.

---

## 8. Potenziamenti e acquisti

### Moduli NORA (funzionali)
Acquistati con energia, con slot che crescono col livello.
| Modulo | Effetto |
|---|---|
| Indizio | un aiuto sull'esercizio corrente |
| Seconda chance | un secondo tentativo dopo un errore |
| Tempo extra | più tempo nelle prove a tempo |
| Moltiplicatore | potenzia la combo per una sessione |
| Radar tesori | evidenzia tesori/frammenti vicini |
| Torcia | esplora di notte, sblocca beacon |
| Scatto potenziato | sprint più veloce/lungo (già presente) |

### Compagni funzionali (evoluzione dei pet)
Estetica **e** utilità: il Cane fiuta i tesori, il Prisma dà uno scudo-combo, la
Cometa aumenta l'energia delle missioni. **Già visibili nel mondo Godot** (pet
che segue e reagisce).

### Estetica (bottega)
Outfit, accessori, pet, skin del bot: il sink "identità". Livrea/emblema/pet già
resi nel mondo.

---

## 9. Storia e NORA

La storia **cavalca la scala dei livelli**: non un sistema a parte.
- Ogni **apparato riparato** = un pezzo di NORA che torna + un **beat** (un
  frammento della verità sui Primi, o un ricordo di Eli).
- **NORA** guida, incoraggia, spiega, celebra; parte frammentata e diventa piena
  man mano che la nave si accende. Il suo risveglio *è* la progressione.
- **Storie secondarie leggere**: frammenti di memoria (Codex), archi dei compagni
  (una micro-storia per pet equipaggiato), echi/beacon nel mondo. Opzionali,
  danno colore senza appesantire il loop.

Niente "capitoli" separati da gestire: il capitolo è *il livello*.

### Manuale NORA dei concetti

NORA possiede un manuale didattico consultabile dal mondo e dalla nave. Ogni
voce contiene: spiegazione essenziale, prerequisiti, esempio svolto, errore
tipico, strategia suggerita, eventuale dimostrazione interattiva e collegamenti
ai topic vicini.

- Le voci si sbloccano incontrando il concetto, non acquistandole.
- Un errore può proporre la voce pertinente senza obbligare a interrompere la
  missione.
- Durante un esame il manuale non rivela la soluzione: può essere consultato
  prima o dopo la prova secondo le regole del livello.
- Il linguaggio si adatta alla fascia scolastica e supporta testo breve,
  illustrazione, esempio e lettura accessibile.
- Ogni topic usato da missioni o esami deve avere almeno una voce validata.

---

## 10. Engagement e ritmo

- **Daily loop**: obiettivi del giorno ("oggi: 3 missioni · 1 apparato") +
  **streak** con bonus + **varietà** di materie.
- **Combo** visibile sulle missioni consecutive.
- **Cruscotto-nave**: la progressione diegetica (stanze che si accendono) è la
  ricompensa a lungo termine più potente.
- **Collezione**: frammenti, compagni, biomi scoperti.
- **Celebrazione** misurata di vittorie, riparazioni, salite di livello, record.
- **Sorpresa**: beacon notturni, tesori rari, echi.

---

## 11. UX, HUD, onboarding

- **HUD responsivo** (avviato in Godot): energia/frammenti live con popup "+N",
  bioma, fase giorno/notte, **obiettivo pinnato** (prossimo apparato/cosmetico
  con barra "ti manca X").
- **Bussola di livello**: nel mondo, indicatore verso le missioni della materia
  del livello corrente e verso la nave quando l'apparato è riparabile.
- **Stanza-apparato**: mostra requisiti (missioni mancanti, mastery mancante) e
  il pulsante "Ripara" attivo solo quando pronti.
- **Onboarding morbido** guidato da NORA: muoviti → prima missione → primo
  acquisto → prima riparazione. Una domanda per schermata, testi brevi.
- **Input**: tastiera, touch, mouse; layout mobile e desktop.

---

## 12. Accessibilità e benessere

- **Errore con penalità morbida, mai distruttivo**: puoi fallire e ripetere una
  missione, ma non perdi il livello raggiunto né l'energia già guadagnata.
- **Sessioni brevi premiate** (spacing sano); niente spinta alla maratona.
- **Leggibilità**: font ampi, contrasto, "effetti ridotti", testi con outline.
- **Ritmo scelto dallo studente**: mappa aperta, timer solo nei beacon opzionali.

---

## 13. Telemetria e cruscotto docente

- Per-studente: livello, mastery per materia, argomenti deboli, missioni per
  materia, streak, apparati riparati, tempo.
- Per-docente: panoramica classe, argomenti critici, suggerimenti di rinforzo.
- Privacy: dati locali per default; nessuna raccolta non necessaria.

---

## Sintesi

Due luoghi, una scala. **Fuori** si allena (missioni tarate sul livello);
**dentro** si consacra il progresso riparando gli apparati (esami finali) su
**20+ livelli**. Semplice da capire per lo studente, lungo da percorrere, denso
di apprendimento reale. Dettaglio tecnico e save in
[ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md).
