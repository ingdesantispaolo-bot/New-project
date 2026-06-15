# Architecture

## Stack

- TypeScript
- Vite
- Phaser 4.1
- Howler.js
- Dati missione in TypeScript
- `localStorage` per MVP senza backend
- Asset pipeline WebP/AVIF + atlas TexturePacker-compatible

## Scene Phaser

- `BootScene`: carica il salvataggio.
- `PreloadScene`: genera texture placeholder.
- `MainMenuScene`: menu principale.
- `HubScene`: spazio iniziale dell'Accademia.
- `LaboratoryScene`: missione continua e hotspot.
- `GreenhouseScene`: missione serra con piante, sensori, turni, tabella dati e grafico.
- `NumberFactoryScene`: missione industriale con ordini numerici, macchine, filtri, traccia-espressione e completamento dati-driven.
- `WordArchiveScene`: missione linguistica con restauro messaggi, filtro indizi, istruzione bilingue e rapporto finale.
- `ProceduralMissionScene`: missione esplorativa generata da seed con hotspot, puzzle validati, diario procedurale e dipendenze sistemiche tra segnale, circuito, terminale, inglese, robot e porta.
- `PlayerReportScene`: selezione giocatori, report personale, punti forti e ultimi risultati.
- `LeaderboardScene`: classifiche locali filtrabili per esercizio, missione e focus.
- `CircuitPuzzleScene`: puzzle elettronico.
- `MathLockScene`: serratura numerica.
- `RobotCodingScene`: puzzle coding a griglia.
- `JournalScene`: diario, badge e competenze.

## Core Systems

- `SaveSystem`: serializza stato, flags, inventario, competenze e diario.
- `MissionEngine`: legge missioni, calcola obiettivi attivi e completa step.
- `CompetencyTracker`: aggiorna competenze.
- `AudioManager`: usa Howler con piccoli WAV locali generati dalla pipeline asset, caricati come loop e SFX reali.
- `FeedbackSystem`: pubblica messaggi formativi.
- `DialogueSystem`: recupera dialoghi dati-driven.
- `InventorySystem`: gestisce oggetti raccolti.
- `EventBus`: canale eventi Phaser condiviso.
- `ProceduralDirector`: genera missioni procedurali complete da seed, difficoltà e focus competenze.
- `MissionDependencyGraph`: governa la catena causale della missione procedurale. Un sistema può essere osservato fuori ordine, ma l'intervento viene bloccato se i prerequisiti non sono affidabili.
- `ValidationEngine`: rigenera contenuti non validi e applica fallback sicuri.
- `AssetPipeline`: descrive asset di produzione, provenienza, runtime key e formato ottimizzato.
- `SceneNavigator`: carica dinamicamente missioni e puzzle quando servono, riducendo il bundle iniziale.
- `MapLayoutSystem`: legge layout Tiled JSON e permette di spostare hotspot, pannelli, macchine, piante e carte fuori dal codice scena.
- `PlayerSystem`: gestisce profili giocatore locali, risultati storici e classifiche top 20 per esercizio, missione e focus.

## Rendering E Asset Pipeline

Il rendering resta Phaser, ma ora è organizzato per produzione:

- fondali pittorici in `src/assets/images/*-painted-bg.png`;
- export ottimizzati `webp` e `avif` tramite `scripts/optimize-assets.mjs`;
- atlas `src/assets/sprites/eli-quest-atlas.webp` con JSON compatibile TexturePacker;
- script `scripts/build-visual-assets.mjs` per generare glyph, flare, particelle e placeholder sostituibili;
- contratti mappa in `src/assets/maps/*.ldtk.json`, mappe Tiled artistiche in `src/assets/maps/tiled/*.tiled.json` e layout runtime compatti in `src/assets/maps/runtime/*.layout.json`;
- `scripts/build-tiled-tileset.mjs` genera il primo tileset Tiled.
- `scripts/build-tiled-maps.mjs` converte i contratti in Tiled JSON, aggiunge layer artistici e valida gli ID semantici richiesti;
- chunk separati Vite per `phaser` e `howler`, così il codice gioco resta distinto dal motore.
- dynamic import per scene pesanti: Laboratorio, Serra, Fabbrica, Archivio, Procedurale e puzzle dedicati diventano chunk caricati a richiesta.

`VisualKit` è il punto comune per qualità visiva: parallax multilivello, fondali pittorici, grading leggero, particelle da atlas, pannelli glass meno geometrici, scanline, vignette, transizioni cinematiche e feedback animati.

In produzione gli asset generati vanno sostituiti mantenendo stabili le runtime key:

- `bg-*-painted` per i fondali;
- `eli-atlas` per sprite e UI glyph;
- frame name come `particle-diamond`, `soft-flare`, `ui-corner`, `robot-core`.

## Procedural Systems

La cartella `src/procedural` contiene lo strato di generazione controllata:

- `Random`: PRNG deterministico, usato al posto di `Math.random` nei generatori.
- `SeedManager`: crea seed leggibili, casuali, giornalieri o legati alla difficoltà.
- `DifficultyModel`: legge preset 1-8 da `src/data/procedural/difficultyPresets.ts`.
- `MissionGenerator`, `MapGenerator`, `PuzzleGenerator`: assemblano missioni, stanza e puzzle.
- `generators`: matematica, robot, circuito, lingua italiana e inglese operativo.
- `validators`: controllano correttezza, risolvibilità e qualita didattica tramite `ChallengeQualityValidator`.
- `solvers`: BFS per griglia, controllo grafo circuito, verifica soluzione matematica.
- `simulators`: motori dedicati per Serra, Fabbrica e Archivio, usati per separare regole didattiche e UI.

Le console procedurali sono state avviate come componenti estraibili: `LanguageRepairConsole`, `CircuitConsole`, `MathTerminal` e `RobotConsole`. La scena resta orchestratore narrativo; i componenti assorbiranno progressivamente rendering, feedback e stato locale.

## Flusso Dati

Le scene non dovrebbero possedere lo stato permanente. Completano azioni chiamando `MissionEngine`, che aggiorna `SaveSystem` e competenze. Le scene rileggono lo stato al riavvio o su evento.

## Salvataggi

Il salvataggio vive in `localStorage` con chiave `eli-quest-save-v1`. Contiene:

- missione attiva;
- missioni completate;
- inventario;
- flag narrativi;
- punteggi competenze;
- diario.
- run procedurale corrente con seed, difficoltà, missione generata, puzzle risolti e indizi usati.
- stato interno della Serra: turno, pianta selezionata, valori sensori, salute e storico grafico;
- stato interno della Fabbrica: ordine corrente, valore del nucleo, espressione, macchine attraversate e ordini completati.

I dati multi-giocatore vivono in una chiave separata, `eli-quest-players-v1`, per non rompere il salvataggio esistente. Contengono:

- profili giocatore;
- giocatore attivo;
- risultati storici attribuiti al profilo;
- risultati normalizzati per classifica: categoria, chiave, difficoltà, punteggio, tempo, indizi, tentativi e seed.

Le classifiche sono locali al browser/tablet. Sono già modellate come record serializzabili, quindi un backend futuro potrà sincronizzarle senza cambiare le scene.

## Espandibilita

La struttura e pronta per un backend futuro: `SaveSystem` e il punto da sostituire con un adapter Supabase/Firebase mantenendo stabile il resto del gioco.

Lo strato procedurale è pronto per backend o contenuti remoti perché il seed e il formato missione generato sono serializzabili. In futuro si potrà salvare solo seed+difficoltà e rigenerare lato client, oppure salvare l'intero run validato per audit didattico.
