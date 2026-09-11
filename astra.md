# ASTRA × OPUS — Piano eseguibile

Stato: fasi 0–4 verificate; piano completato · 11/09/2026.

**Obiettivo:** migliorare le missioni esistenti collegando esercizi di materie diverse a uno scopo comune. Gli esercizi restano: insegnano, allenano e verificano. Nessun aumento del carico obbligatorio complessivo del mondo.

## Organizzazione

- **Opus:** concetti, prerequisiti, casi, errori, aiuti e dialoghi. **Astra:** interazioni, integrazione, feedback ambientale, persistenza e verifiche. Revisione reciproca.
- Prima di ogni lotto: controllare `git status` e assegnare file. Astra integra i file condivisi; niente scritture concorrenti o export/bake simultanei.
- Riutilizzare Godot, renderer, cataloghi e asset. Conservare trama, fasce correnti, gate e salvataggi. Nessun requisito di studenti/docenti: revisione AI e audit verificano il progetto, non dimostrano efficacia educativa o divertimento umano.

## Fasi sequenziali

| Fase | Opus | Astra | Criterio d'uscita |
|---|---|---|---|
| **0 · Selezione** | Sceglie due competenze del mondo 1 e il nesso tra loro. | Riproduce le attività; identifica renderer, conteggi e attribuzione degli esiti. | Collegamento realizzabile senza nuovo renderer o asset. |
| **1 · Pilota** | Prepara tappe collegate, dimostrazione, variante e feedback. | Migliora la missione raggruppando attività previste e salvandone la conseguenza. | Successo, errore, aiuto e riavvio funzionano; esiti distinti per materia. |
| **2 · Riuso** | Adatta lo schema a due combinazioni di materie diverse. | Integra due missioni usando sistemi esistenti. | Tre missioni interdisciplinari complete; carico e copertura del mondo conservati. |
| **3 · Estensione** | Prepara una missione caratterizzante per mondo. | Integra lotti di massimo 3 mondi: prima 1–12, poi 13–24. | Ogni lotto supera i controlli sotto prima del successivo. |
| **4 · Chiusura** | Controlla progressione concettuale e coerenza narrativa sui 24 mondi. | Verifica gate, save e build Web. | 24 missioni collegate e verificate; nessun difetto bloccante aperto. |

**Pilota:** comprendere la richiesta di un abitante (italiano), ricavarne quantità e raggruppare cristalli (matematica), alimentare un dispositivo esistente. La richiesta determina i dati del calcolo. Riutilizzare formati funzionanti; se non rappresentano questi concetti, scegliere un caso equivalente supportato.

## Materie e difficoltà 1–24

- Il mondo conserva una materia caratterizzante; ogni missione migliorata collega 2–3 materie, fino a 4 nelle sintesi finali. La distribuzione complessiva del mondo copre tutte le materie e conserva i pesi curricolari esistenti: non inserire dodici materie in ogni incarico.
- Una tappa produce un dato, indizio o strumento usato dalla successiva. Ogni materia deve richiedere una decisione verificabile: leggere un testo non certifica italiano; trovare parole inglesi sullo sfondo non certifica inglese.
- Riutilizzare `target_difficulty(level)` (8 fasce, tre livelli ciascuna) e `challenge_level(level)` (1–24). Entro ciascuna terna: primo livello introduce con guida, secondo varia il problema, terzo combina con maggiore autonomia. Ai cambi di fascia insegnare i nuovi prerequisiti; non alzare contemporaneamente tutte le difficoltà.

| Livelli / fascia | Complessità della missione proposta |
|---|---|
| 1–3 / 1 | Due materie, informazioni esplicite, collegamento guidato. |
| 4–6 / 2 | Due materie, scegliere dati e ordine delle azioni. |
| 7–9 / 3 | Due–tre materie, un vincolo e previsione dell'effetto. |
| 10–12 / 4 | Tre materie, diagnosticare un errore con indizi. |
| 13–15 / 5 | Tre materie, riusare competenze in un contesto nuovo. |
| 16–18 / 6 | Tre materie, confrontare strategie con più vincoli. |
| 19–21 / 7 | Tre–quattro materie, pianificare e verificare una soluzione. |
| 22–24 / 8 | Tre–quattro materie, sintesi autonoma e motivazione delle scelte. |

- Ogni tappa dichiara materia, topic, fascia, prerequisiti e ruolo: concetto nuovo / pratica / richiamo. Di norma una sola novità concettuale per missione; le altre competenze sono già introdotte. Richiami più facili non certificano il grado superiore.
- Conservare valutazione per materia/topic: niente voto medio che nasconda una debolezza. Prima riusare sessioni distinte sotto una missione comune; verificare gli attuali percorsi basati su `session.subject`. Non moltiplicare ricompense, sessioni o tick del ripasso. Un errore a monte va corretto con feedback prima di propagare dati alla tappa successiva.

## Contratto minimo di ogni missione

- **Scopo → azione:** bisogno concreto di un abitante; indicare quale decisione richiede la conoscenza. Cambiare etichetta a un quiz non basta.
- **Scoperta:** NORA dimostra un passaggio, Eli completa l'analogo. Informazioni nuove prima dell'uso; approfondimento nel Manuale.
- **Errore:** due errori plausibili con feedback causale; aiuto sul dettaglio, poi sul metodo. Manipolazioni preparatorie senza penalità; demo senza padronanza; consegna valutata dallo scoring esistente.
- **Autonomia:** caso senza suggerimento iniziale e variante con stesso concetto in contesto diverso. Sostituire nodi previsti; se manca spazio, collocare la variante in un incontro successivo.
- **Conseguenza:** cambiamento salvato, breve reazione del personaggio e prossimo scopo. Dare un uso reale al dispositivo riparato quando supportato.

## Profondità e ritmo

- Alternare costruzione, diagnosi, interpretazione e pianificazione con i minigiochi disponibili; evitare sequenze consecutive della stessa azione.
- Nei mondi 13–24 riprendere la materia con un vincolo nuovo, una diagnosi o una scelta di strategia. Numeri più grandi non bastano.
- Mostrare subito l'obiettivo; spiegare vicino all'azione. Raggruppare le attività senza aumentare prove e schermate obbligatorie del mondo.
- Riutilizzare umorismo, Custode e indizi della trama; conseguenze riconoscibili e curiosità sul prossimo incontro, senza nuove ramificazioni.
- Usare il ripasso esistente per le varianti. Marcare trasferimento solo per casi revisionati: difficoltà maggiore o topic diverso non lo garantiscono.

## Corsia parallela: il percorso dello studente (Opus, dal 10/09/2026)

Assegnazione del committente: **Astra le missioni, Opus il percorso fra esercizi, allenamenti ed elementi del mondo.** Segnalazione all'origine: «lo studente segue semplicemente il percorso indicatogli dalle istruzioni; questo toglie stimolo ad esplorazione». Piano e misure in [docs/PERCORSO_STUDENTE.md](docs/PERCORSO_STUDENTE.md).

| Lotto | Owner | Stato | File | Verifica |
|---|---|---|---|---|
| 1 · Nomi dei posti e sguardo intorno | Opus | verificato | `nomi_dei_luoghi.gd`, `percorso_studente.gd`, `percorso_studente_audit.gd`, `percorso_studente_scene_audit.gd`, `outdoor_world.gd` | due guardie verdi; 24 mondi: nomi unici, copertura 97%; scena: 15 targhette con nome |
| 2 · Distanza di lettura del nome | Opus | verificato | `scoperta_luogo.gd`, `outdoor_world.gd`, le due guardie del lotto 1 | tre grammatiche ordinate, 15 targhette nel gruppo, opacità che risponde alla distanza |
| 3 · Il quartiere ha un nome | Opus | verificato | `nomi_dei_luoghi.gd`, `outdoor_world.gd`, `objective_panel.gd` | 67 quartieri sui 24 mondi, 90% delle materie sa dove si allena |
| 4 · La tavola letta sul posto lascia un segno | Opus | verificato | `outdoor_world.gd` | targa che richiama e si spegne, NORA che riprende la scoperta una volta per visita |

**Confine.** Le missioni sono di Astra e questa corsia non apre i suoi file: `exercise_player.gd`, `outdoor_gameplay.gd`, `progression_manager.gd`, `save_manager.gd`, `local_progress_report.gd`, `linked_missions_*.gd`, `obelisk_mission*.gd`. Un lotto che ne avrebbe bisogno si riscrive per farne a meno o aspetta — è il motivo per cui del lotto 4 si fa solo la metà che vive nel mondo.

## Registro Astra — missioni collegate

| Mondo | Owner | Stato | File | Verifica/esito | Difetto aperto |
|---|---|---|---|---|---|
| 1 · L'obelisco che ha smesso di contare | Astra | verificato | `obelisk_mission.gd`, `exercise_player.gd`, `outdoor_gameplay.gd`, progressione/save/report, audit e render probe | 6 varianti; successo, errore, aiuto, abbandono, reload e doppia resolve; italiano e matematica separati; scena reale orizzontale/verticale | nessuno |
| 2 · Le rondini dell'Archivio | Astra | verificato | `linked_missions_first.gd`, runtime condiviso, `linked_missions_audit.gd` | 2 varianti; italiano → matematica → italiano; tre renderer; un solo tick/claim/missione | nessuno |
| 3 · La macchina a cicli | Astra | verificato | stessi file del mondo 2 | 2 varianti; coding → matematica → coding; esiti distinti per materia | nessuno |
| 4 · Il molo che brucia piano | Astra | verificato | stessi file del mondo 2, `linked_missions_render_probe.gd` | 2 varianti; inglese → logica → matematica; scena reale orizzontale/verticale; corretto reset dello scroll fra tappe | nessuno |
| 5 · La grande leva | Astra | verificato | `linked_missions_first.gd`, runtime e audit condivisi | 2 varianti; fisica → matematica → fisica; una missione/claim/tick | nessuno |
| 6 · L'albero che non risuona | Astra | verificato | stessi file del mondo 5 | 2 varianti; musica → matematica → musica; esiti distinti | nessuno |
| 7 · Il cortile murato | Astra | verificato | stessi file del mondo 5, `linked_missions_render_probe.gd` | 2 varianti; latino → logica → matematica; scena reale orizzontale/verticale; autofocus numerico non nasconde più lo scopo | nessuno |
| 8 · Il nodo in cortocircuito | Astra | verificato | `linked_missions_first.gd`, runtime e audit condivisi | 2 varianti; elettronica → matematica → coding; una missione/claim/tick | nessuno |
| 9 · La torre cartografica | Astra | verificato | stessi file del mondo 8 | 2 varianti; geografia → matematica → coding; esiti distinti | nessuno |
| 10 · Le vasche della Serra | Astra | verificato | stessi file del mondo 8, `linked_missions_render_probe.gd` | 2 varianti; scienze → matematica → scienze; scena reale orizzontale/verticale | nessuno |
| 11 · Il portale delle epoche | Astra | verificato | `linked_missions_first.gd`, runtime e audit condivisi | 2 varianti; storia → matematica → storia; una missione/claim/tick | nessuno |
| 12 · Il cuore che si surriscalda | Astra | verificato | stessi file del mondo 11, `linked_missions_render_probe.gd` | 2 varianti; logica → coding → fisica; scena reale orizzontale/verticale | nessuno |
| 13 · L'osservatorio cieco | Astra | verificato | `linked_missions_late.gd`, runtime e audit condivisi | 2 varianti; fisica → matematica → coding; una missione/claim/tick | nessuno |
| 14 · Le voci chiuse nella sala | Astra | verificato | stessi file del mondo 13 | 2 varianti; italiano → matematica → logica; esiti distinti | nessuno |
| 15 · Il mulino della Città Macchina | Astra | verificato | stessi file del mondo 13, `linked_missions_render_probe.gd` | 2 varianti; coding → matematica → fisica; scena reale orizzontale/verticale | nessuno |
| 16 · L'incendio al valico | Astra | verificato | `linked_missions_late.gd`, runtime e audit condivisi | 2 varianti; inglese → matematica → logica; una missione/claim/tick | nessuno |
| 17 · La rete sul fondo | Astra | verificato | stessi file del mondo 16 | 2 varianti; fisica → matematica → scienze; esiti distinti | nessuno |
| 18 · Le canne mute | Astra | verificato | stessi file del mondo 16, `linked_missions_render_probe.gd` | 2 varianti; musica → coding → fisica; scena reale orizzontale/verticale; focus liberato fra renderer | nessuno |
| 19 · Le radici che sollevano le cripte | Astra | verificato | `linked_missions_late.gd`, runtime e audit condivisi | 2 varianti; latino → scienze → logica; una missione/claim/tick | nessuno |
| 20 · La torre che attira i fulmini | Astra | verificato | stessi file del mondo 19 | 2 varianti; elettronica → matematica → coding; esiti distinti | nessuno |
| 21 · Il pilastro tettonico | Astra | verificato | stessi file del mondo 19, `linked_missions_render_probe.gd` | 2 varianti; geografia → matematica → coding; scena reale orizzontale/verticale | nessuno |
| 22 · Il nucleo isolato | Astra | verificato | `linked_missions_late.gd`, runtime e audit condivisi | 2 varianti; scienze → matematica → logica; una missione/claim/tick | nessuno |
| 23 · L'Archivio delle Ere al buio | Astra | verificato | stessi file del mondo 22 | 2 varianti; storia → matematica → italiano; esiti distinti | nessuno |
| 24 · Il Cuore in sovraccarico | Astra | verificato | stessi file del mondo 22, `linked_missions_render_probe.gd` | 2 varianti; logica → matematica → coding; scena reale orizzontale/verticale; reset post-layout verificato | nessuno |

## Chiusura tecnica

- Guardie Astra verdi: `obelisk_mission_audit`, `linked_missions_audit` (46 varianti sui mondi 2–24), `exercise_exit_audit`, `exercise_renderer_audit`, `save_schema_audit`, `content_progression_audit`. Nel giro completo sono verdi anche `progression_1to24_audit`, `world_exam_flow_audit`, `minimission_audit`, `mission_event_director_audit` e `roundtrip_audit`.
- Scene reali catturate e ispezionate sui mondi 4, 7, 10, 12, 15, 18, 21 e 24, in orizzontale e verticale. Le catture hanno fatto emergere e chiudere il difetto di scroll/focus fra renderer.
- Giro completo dell'11/09/2026: **278/278 verdi** in 1040 secondi. Chiusi i nove rossi della baseline e i due contratti trasversali emersi al primo giro di chiusura (`compiti_dichiarati_audit`, ora deterministico, ed `emblem_promises_audit`, allineato ai segni compatibili col font Web).
- Il budget prestazionale distingue ora l'avvio a freddo del motore (limite 1000 ms) dall'istanza del mondo a cache calda (limite 500 ms): la sonda ripetuta misurava lo stesso mondo 1 a 643 ms al primo caricamento e 327–345 ms nei successivi, con identico grafo di scena.
- Build Web esportata e verificata: `2026.09.11-web-loader-2`, PCK **81,37 MiB**, WASM **37,68 MiB**, core **119,05 MiB**. Verdi `release:web`, `audit:web` e `smoke:web:godot`; lo smoke attraversa menu → mondo 1 → nave → esame → mondo 2 → missione, conserva il save, mantiene l'audio e non registra errori console.

## Controlli e consegna

**Opus:** risolvere casi e varianti, cercare ambiguità, soluzioni alternative e scorciatoie; verificare che tutto il necessario sia stato insegnato. **Astra:** provare dal vero ingresso successo, errori ripetuti, aiuti, uscita/rientro; controllare ricompense duplicate, persistenza e progressione con save isolati.

Audit mirati sui comportamenti nuovi; input casuali e replay per rilevare padronanza indebita. Ispezionare scene renderizzate e comandi touch: il solo audit dei dati non basta. Nessuna simulazione AI viene presentata come prova con studenti.

Comandi: `npm run audit:godot -- <filtro>` per lotto; alla chiusura `npm run release:web`, `npm run audit:web`, `npm run smoke:web:godot`; test touch disponibile se cambiano i comandi.

Registro minimo da aggiornare qui: `mondo | owner | stato | file | verifica/esito | difetto aperto`. Stati: da fare / in corso / verificato.

## Confini tecnici

In `godot/scripts/game/`: cataloghi `minimission_catalog.gd`, `character_minigame_catalog.gd`, `world_lesson.gd`; runtime `mission_event_director.gd`, `content_manager.gd`, `exercise_player.gd`; insegnamento `teaching_catalog.gd`, `knowledge_codex.gd`. Seguire [README](README.md) per sorgenti/bake; coordinarsi col [piano fasce](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).

**Fuori scope:** nuovo scheduler temporale, riscrittura mastery, framework di missioni, asset nuovi, multiplayer, altri mondi o ampliamento del Secondo Viaggio.
