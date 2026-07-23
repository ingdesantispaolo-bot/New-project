# Piano di evoluzione AAA didattico

Stato: **decisione di prodotto approvata il 23 luglio 2026**.

Questo piano trasforma Eli Quest da vertical slice con mondo procedurale ed
esercizi in overlay a un'avventura in cui la conoscenza cambia nave, NORA, Eli e
mondi esterni. Le cinque decisioni qui sotto sono requisiti, non polish.

## Obiettivi non negoziabili

1. Ogni livello 1–24 sblocca un nuovo mondo esterno graficamente e
   tematicamente distinto.
2. I minigiochi delle Palestre diventano eventi casuali nelle missioni e sulla
   mappa; le stazioni fisse non sono il target finale.
3. Ogni mondo ha una resa di alto livello e un ingresso nave deterministico,
   sicuro e riconoscibile.
4. NORA spiega i concetti importanti e li raccoglie in un manuale consultabile.
5. Gli esercizi usano interazioni varie; la scelta multipla resta minoritaria.

## Contratti architetturali

### `WorldProfile`

Una sola scena Godot viene configurata con un profilo per livello. Ogni profilo
deve dichiarare:

| Campo | Responsabilità |
|---|---|
| `id`, `level`, `title` | Identità e sblocco |
| `learningFocus` | Materia e competenze centrali |
| `terrainFamily`, `topology` | Terreno, altimetria, acqua e percorsi |
| `artKit`, `heroLandmarks` | Asset modulari e almeno un landmark unico |
| `lighting`, `weather`, `soundscape` | Atmosfera visiva e sonora |
| `missionGrammar`, `eventPools` | Tipi di missione e minigiochi ammessi |
| `shipEntrance` | Posizione/rotazione autorata e raggio protetto |
| `spawn`, `safeRoute` | Punto iniziale e percorso garantito |
| `performanceBudget` | Budget per tier Web/mobile/desktop |

La generazione procedurale riempie il profilo, ma non può cambiarne l'identità o
invadere `shipEntrance.safeRadius`.

### `MissionEventDirector`

Il direttore sceglie eventi in base a mondo, livello, materia, topic deboli,
ripasso dovuto e cronologia recente.

- Stesso seed e stesso stato producono gli stessi eventi.
- Gli eventi casuali non possono bloccare la progressione: il focus del livello
  ha sempre abbastanza missioni/eventi raggiungibili per aprire il gate.
- Non ripete lo stesso formato o prompt nelle ultime sessioni configurate.
- Un minigioco dentro una missione è una tappa, non una missione extra.
- Un evento libero di pratica aggiorna mastery e ripasso, ma non il conteggio
  del gate.
- La posizione casuale rispetta navigabilità, distanza, visibilità e budget.

### `KnowledgeCodex` — Manuale NORA

Ogni `ConceptEntry` contiene:

- materia, topic, fascia/difficoltà e prerequisiti;
- spiegazione breve e spiegazione estesa;
- esempio svolto passo per passo;
- errore tipico e perché è sbagliato;
- strategia/metodo suggerito da NORA;
- eventuale illustrazione o dimostrazione interattiva;
- collegamenti a concetti precedenti e successivi;
- stato: sconosciuto, incontrato, consultato, applicato, consolidato.

Il manuale è accessibile dal diario della nave e dal menu del mondo. Durante
l'allenamento NORA può aprire la voce pertinente; durante l'esame non mostra la
risposta corrente.

### `ExerciseInteraction`

Il motore comune mantiene scoring, scudi, mastery, accessibilità e report; ogni
formato implementa soltanto presentazione e validazione dell'interazione.

Famiglie previste:

1. scelta multipla e vero/falso motivato;
2. input numerico o testuale;
3. ordinamento e timeline;
4. abbinamento con drag/linee;
5. classificazione in categorie;
6. hotspot su immagini, mappe e diagrammi;
7. costruzione di frasi e trasformazioni linguistiche;
8. grafici: lettura, punti, pendenza e confronto;
9. circuiti: collega componenti, misura, diagnostica;
10. codice: trace, riordino, completa e debug;
11. simulazioni di fisica/scienze;
12. manipolazione diegetica nel mondo.

Target iniziale di qualità:

- scelta multipla ≤ 33% dei nodi di una missione standard;
- almeno due famiglie di interazione per missione a tappe;
- esame finale con almeno due formati e una prova di trasferimento;
- ogni errore produce feedback causale, non soltanto la risposta corretta;
- tastiera, mouse e touch equivalenti; effetti ridotti e contrasto verificati.

## Mappa provvisoria dei 24 mondi

I nomi sono di lavoro, ma la distinzione richiesta è vincolante.

| Livello | Mondo | Focus | Identità principale |
|---:|---|---|---|
| 1 | Radura Accademia | matematica | natura luminosa, rovine introduttive |
| 2 | Archivio delle Parole | italiano | biblioteche vegetali, ponti di frasi |
| 3 | Cratere Logico | coding | canyon modulari, macchine e loop |
| 4 | Baia dei Segnali | inglese | porto radio, boe e messaggi lontani |
| 5 | Officine del Moto | fisica | rotaie, leve, rampe e meccanismi |
| 6 | Giardino della Risonanza | musica | flora sonora, vento e cristalli |
| 7 | Rovine dei Glifi | latino | città antica, iscrizioni e acquedotti |
| 8 | Delta dei Circuiti | elettronica | acqua conduttiva, nodi e generatori |
| 9 | Arcipelago Cartografico | geografia | isole, quote e rotte |
| 10 | Serra delle Simbiosi | scienze | ecosistemi vivi e osservazione |
| 11 | Città dei Patti | cittadinanza | quartieri, servizi e decisioni comuni |
| 12 | Labirinto delle Regole | logica | geometrie mobili e deduzione |
| 13 | Deserto delle Orbite | matematica | osservatorio, ombre e traiettorie |
| 14 | Biblioteca delle Voci | italiano | narrazioni, prospettive e memoria |
| 15 | Città Macchina | coding | automi, reti e sistemi concorrenti |
| 16 | Frontiera delle Lingue | inglese | scambi, viaggi e comunicazione |
| 17 | Oceano delle Forze | fisica | correnti, galleggiamento e pressione |
| 18 | Cattedrale del Suono | musica | grandi spazi, armonia e riverbero |
| 19 | Necropoli delle Radici | latino | etimologie, archivi e discendenze |
| 20 | Tempesta Elettromagnetica | elettronica | campi, sensori e reti instabili |
| 21 | Atlante Fratturato | geografia | placche, climi e sistemi territoriali |
| 22 | Biosfera Profonda | scienze | adattamento, cellule ed energia |
| 23 | Concilio delle Colonie | cittadinanza | negoziazione e beni comuni |
| 24 | Cuore dei Primi | logica/trasversale | convergenza dei sistemi e finale |

Ogni mondo richiede almeno una silhouette, topologia, famiglia di materiali,
atmosfera, landmark, soundscape e grammatica di missione diversi dal precedente.
I kit possono condividere componenti, ma non la composizione finale.

## Esperienza di un livello

1. NORA presenta il nuovo segnale e il concetto-obiettivo.
2. La navigazione della nave apre il nuovo mondo.
3. Eli arriva presso l'ingresso autorato del Relitto.
4. Il mondo propone una rotta principale e deviazioni opzionali.
5. Missioni e minigiochi casuali raccolgono evidenze di competenza.
6. Il Manuale NORA si arricchisce con concetti, esempi ed errori incontrati.
7. Quando copertura, mastery e ritenzione sono sufficienti, la nave invia il
   richiamo di rientro.
8. Eli torna allo stesso ingresso e raggiunge l'apparato corretto.
9. La prova finale verifica applicazione e trasferimento.
10. L'apparato si riattiva, NORA recupera una memoria e si apre il mondo seguente.

## Roadmap per priorità

### P0 — Correggere il loop prima di espanderlo

- Rendere disponibili missioni ripetibili naturali per tutte le 12 materie.
- Rimuovere il terminale d'esame dal mondo: l'esame vive soltanto nella nave.
- Conservare il lavoro svolto nelle materie non correnti.
- Rendere persistenti frammenti e stato rilevante dei mondi.
- Aggiungere un audit che completi realmente i livelli 1–24 tramite le stesse
  azioni disponibili al giocatore.

**Uscita:** nessun livello richiede reload artificiale, scorciatoie o injection
di dati per essere completato.

### P1 — Fondazioni dei mondi

- Implementare `WorldProfileCatalog`.
- Separare seed globale, `worldId` e seed locale.
- Salvare mondi sbloccati, mondo corrente e punti di viaggio.
- Riservare `shipEntrance.safeRadius` prima della generazione.
- Aggiungere mappa di navigazione nella nave e ritorno al mondo scelto.

**Uscita:** una scena carica profili diversi senza duplicazione e garantisce
ingresso nave, spawn e percorso sicuro.

### P2 — Vertical slice livelli 1 e 2

- Portare Radura Accademia al nuovo contratto.
- Costruire Archivio delle Parole con identità realmente diversa.
- Inserire minigiochi come eventi casuali delle missioni.
- Collegare sblocco livello 2 → nuovo mondo → ritorno nave.
- Produrre capture GPU desktop e compatte senza HUD per confronto.

**Uscita:** un osservatore distingue immediatamente i due mondi e il loop
completo funziona senza POI palestra fisso.

### P3 — Salto di qualità degli esercizi

- Stabilizzare le API `ExerciseInteraction`.
- Rifinire ordering e matching con drag, slot e linee.
- Implementare classificazione, hotspot, grafici, circuiti e code-debug.
- Convertire una missione completa per ogni materia a formato non dominante MC.
- Creare esame finale multi-formato e prova di trasferimento.

**Uscita:** scelta multipla entro il target e nessun esame solo quiz.

### P4 — Manuale e relazione NORA

- Implementare `KnowledgeCodex` e schema `ConceptEntry`.
- Generare/autorare una voce per ogni topic runtime.
- Collegare errori, briefing e debrief alle voci pertinenti.
- Aggiungere ricerca, filtri per materia, preferiti e stato di consolidamento.
- Espandere NORA a 24 beat, integrità, memoria e fiducia.

**Uscita:** ogni concetto valutato ha una spiegazione consultabile e NORA
riconosce almeno obiettivo, errore ricorrente e miglioramento.

### P5 — Produzione dei 24 mondi

Procedere per gate, senza aprire tutta la produzione in parallelo:

1. mondi 1–4: onboarding e pipeline;
2. mondi 5–8: meccanica, suono e circuiti;
3. mondi 9–12: sistemi naturali/sociali e chiusura primo ciclo;
4. mondi 13–20: varianti avanzate con nuovi verbi di Eli;
5. mondi 21–24: convergenza interdisciplinare e finale.

Ogni ondata entra solo dopo audit di gameplay, didattica, visuale e performance
dell'ondata precedente.

### P6 — Pass AAA e validazione didattica

- Art direction unificata, animazioni, camera e soundscape per mondo.
- Reattività ambientale alle missioni e alle riparazioni.
- Budget Web/mobile, streaming, texture/audio e tempi di caricamento.
- Playtest con studenti e docenti; revisione dei concetti con esperti.
- Accessibilità: input, contrasto, riduzione movimento, lettura e linguaggio.
- Telemetria locale utile a valutare copertura, ritenzione e trasferimento.

**Uscita:** ogni mondo è riconoscibile, performante e didatticamente verificato;
la conoscenza produce un cambiamento osservabile nel gioco.

## Definition of Done globale

- 24 livelli → 24 `WorldProfile` distinti e rivisitabili.
- 24 ingressi nave autorati, raggiungibili e protetti dalla procedura.
- Nessuna Palestra fissa necessaria al loop; minigiochi distribuiti dal direttore.
- Ogni materia può completare il proprio gate senza reload o farming improprio.
- Ogni topic runtime ha almeno una voce del Manuale NORA.
- Scelta multipla entro il target; finali multi-formato e con trasferimento.
- Progressione completa 1→24 verificata automaticamente e con playtest umano.
- Ogni livello cambia almeno nave, NORA e mondo; i traguardi maggiori cambiano
  anche i verbi disponibili a Eli.
