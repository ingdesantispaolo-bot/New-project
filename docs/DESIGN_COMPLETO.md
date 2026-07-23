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

- Il giocatore ha **un livello globale L**, da **1 ad almeno 20** (spina dorsale
  della progressione, tarabile fino a 24+).
- L'avanzamento è una **scala di riparazioni**: ogni gradino/livello = riparare
  **un apparato** (esercizio finale) nella nave.
- Ogni livello ha una **materia in focus** (a rotazione): la scala cicla le
  materie con difficoltà crescente, così ogni disciplina torna più volte, sempre
  più su.

### Requisiti per riparare l'apparato del livello L (materia S)
1. **Missioni esterne**: aver superato almeno **N missioni di S** (calibrate su L).
2. **Padronanza**: mastery di S ≥ **soglia del livello** (es. 70–80%).
3. **Esercizio finale**: superare l'esame cumulativo di S al livello L (l'atto di
   riparazione, nella nave).

Superato → **apparato riparato**, **livello completato**, si sale a **L+1**.
Il nuovo livello apre anche il relativo **WorldProfile**; i mondi precedenti
restano visitabili per ripasso, collezione e contenuti secondari.

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
è variabile ma deterministica rispetto al seed; una quota minima di eventi utili
è garantita vicino ai percorsi raggiungibili, per evitare blocchi dovuti al caso.
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
