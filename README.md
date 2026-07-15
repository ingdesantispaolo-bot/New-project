# Eli Quest - Accademia delle Missioni

Web game 2D educativo in TypeScript, Vite, Phaser 4 e Howler.js. Eli Quest unisce missioni narrative, esercizi procedurali, teoria spiegata da NORA, allenamento rapido e ricompense di energia in un unico percorso interdisciplinare.

La direzione attuale non e piu solo "MVP laboratorio": il gioco ruota intorno a missioni procedurali e capitoli narrativi, con la Palestra della Mente usata sia come riscaldamento autonomo sia come evento bonus dentro le missioni.

## Avvio

```bash
npm install
npm run dev
```

Per provare da tablet sulla stessa rete Wi-Fi:

```bash
npm run dev:lan
```

Poi apri dal tablet `http://IP_DEL_PC:5173`.

Build di produzione:

```bash
npm run build
npm run preview
```

La build è già portabile per hosting gratuito statico:

```bash
npm run build
```

Guida completa: `docs/TABLET_AND_DEPLOY.md`.

## Struttura

- `src/core`: sistemi condivisi, salvataggio, audio, mission engine, competenze.
- `src/data`: missioni, puzzle, dialoghi e competenze modificabili.
- `src/scenes`: scene Phaser principali e puzzle.
- `src/ui`: componenti UI Phaser riusabili.
- `src/types`: tipi TypeScript per missioni, puzzle e salvataggi.
- `docs`: design, architettura, pedagogia, formato missioni e roadmap.

## Stato attuale

### Missioni e percorso

- Main menu con nuova missione, continua, Storia, Diario, Bottega, Giocatori e Classifiche.
- Hub e stanze esplorabili con avatar, console, hotspot, feedback ambientale e NORA presente in scena.
- Campagna a capitoli con fase Esplora e fase Prova.
- Missioni procedurali miste con timer opzionale, vite, score, competenze, seed, salvataggio e ripresa.
- Prove disciplinari in matematica, italiano, inglese, latino, elettronica, fisica, coding, robotica e musica.
- Missioni storiche/classiche ancora presenti: Laboratorio, Serra Biologica, Fabbrica dei Numeri, Archivio delle Parole e Citta Intelligente.

### NORA, teoria e ripasso

- NORA commenta errori, successi, streak, indizi e momenti narrativi.
- Catalogo teorico in `src/data/theoryCatalog.ts`, con capsule brevi ma dense per matematica, italiano, inglese, latino, elettronica, fisica, coding e musica.
- Le capsule contengono definizione, regole, metodo, esempio, trappole, spiegazione in voce NORA, competenze collegate e visualizzazione.
- Atlante teoria e pannello NORA affiancano gli esercizi per trasformare l'errore in ripasso guidato.

### Palestra della Mente

- Palestra autonoma con record per profondita.
- Giochi logico-memoria gia presenti: Sequenza Luminosa, Memory, Codice Segreto, Sequenze Logiche, Bilancia Logica, Griglia Lampo, Firewall NORA.
- Giochi multidisciplinari aggiunti:
  - Tabelline Reactor;
  - Calcolo Mentale;
  - Geo Atlante, capitali/continenti;
  - Geo Rilievi, geografia fisica base.
- I quattro giochi nuovi possono partire anche in modalita `missionBonus`: round brevi, risultato strutturato e ritorno controllato alla missione.

### Eventi bonus in missione

- Le missioni possono proporre una "Frattura energetica" dopo alcune console risolte.
- L'evento sceglie uno tra Tabelline, Calcolo Mentale, Geo Atlante e Geo Rilievi in base al contesto della run.
- Massimo 2 eventi per missione normale, massimo 1 nelle Prove Capitolo.
- Nessuna penalita se l'evento viene ignorato o fallito.
- Ricompense: energia bonus e, con precisione alta, stabilita timer.
- Stato salvato in `ProceduralRunSave.bonusEvents`, per evitare doppie ricompense.

### Sistemi di progressione

- `localStorage` per salvataggi locali e profili giocatore.
- Competenze persistenti, memoria degli errori, autonomia di mastery e report giocatore.
- Energia come valuta per Bottega e cosmetici.
- Missione del giorno, bonus varieta e loop di ricompensa giornaliero.
- Classifiche locali top 20 per esercizio, missione e focus.

## MVP storico implementato

- Main menu con nuova missione, continua e diario.
- Hub esplorabile iniziale con accesso al laboratorio.
- Missione 1 continua nel laboratorio.
- Laboratorio esplorabile con avatar, oggetti cliccabili, pannello di ispezione e indizi progressivi.
- Puzzle circuito con interruttore, resistenza, LED e feedback.
- Serratura matematica con indizi progressivi.
- Micro-istruzione inglese con scelta green/red.
- Riparazione di messaggio tecnico in italiano.
- Puzzle robot a griglia con sequenza di comandi.
- Diario finale con badge narrativi.
- Missione 2 “La Serra Biologica” con tre piante, sensori, turni, tabella dati e grafico.
- Missione 3 “La Fabbrica dei Numeri” con macchine industriali, filtri pari/multipli, trasformazioni e ordini di produzione.
- Missione 4 “Archivio delle Parole” con messaggi corrotti, filtro indizi, istruzione bilingue e rapporto finale.
- `localStorage` per salvataggio.
- Profili giocatore locali con report personale e classifiche top 20 per esercizio, missione e focus.
- AudioManager Howler con suoni sintetici placeholder.
- Supporto tablet landscape, overlay orientamento, touch target ampliati, manifest PWA e service worker leggero.

## Dove modificare missioni e puzzle

- Missioni: `src/data/missions.ts`
- Missioni procedurali: `src/procedural/ProceduralDirector.ts`, `src/procedural/generators/*`
- Regole run procedurali: `src/core/ProceduralRunRules.ts`
- Scene missione procedurale: `src/scenes/ProceduralMissionScene.ts`
- Palestra e giochi bonus: `src/scenes/LogicGymScene.ts`
- Tipi eventi bonus Palestra: `src/types/logicGymBonus.ts`
- Oggetti esplorabili del laboratorio: `src/data/laboratoryObjects.ts`
- Dati della serra: `src/data/greenhouse.ts`
- Dati della fabbrica numerica: `src/data/numberFactory.ts`
- Dati dell'archivio linguistico: `src/data/wordArchive.ts`
- Puzzle: `src/data/puzzles.ts`
- Dialoghi: `src/data/dialogues.ts`
- Competenze: `src/data/competencies.ts`
- Teoria NORA: `src/data/theoryCatalog.ts`

Le scene leggono questi dati e aggiornano flag/competenze tramite `MissionEngine`, `SaveSystem` e `CompetencyTracker`.

## Qualita e verifica

Comandi principali:

```bash
npm run build
npm test
```

Per modifiche a scene o canvas, verificare anche a runtime con browser:

- assenza di pagina nera;
- console senza errori JavaScript;
- screenshot desktop/tablet quando cambia il layout;
- ritorno corretto tra scene, soprattutto per missioni, Palestra ed eventi bonus.

## Giocatori, salvataggi e classifiche

Dal menu principale:

- `Giocatori`: crea o seleziona profili locali e legge il report del giocatore attivo.
- `Classifiche`: mostra i migliori 20 risultati salvati nel browser per missione, focus ed esercizio.

Ogni profilo ha un salvataggio separato per run in corso, diario, competenze, record allenamento e progressi. Le classifiche sono locali al browser/tablet e mostrano i migliori risultati attribuiti ai diversi giocatori. Non serve backend nella versione attuale; in futuro `PlayerSystem` e `SaveSystem` potranno essere sostituiti con adapter remoti.
