# Eli Quest - Accademia delle Missioni

MVP web game 2D in TypeScript, Vite, Phaser 3 e Howler.js. La prima missione, "Il Laboratorio Spento", integra elettronica, matematica, coding, italiano, inglese operativo e problem solving dentro una missione continua.

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

## MVP implementato

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
- Oggetti esplorabili del laboratorio: `src/data/laboratoryObjects.ts`
- Dati della serra: `src/data/greenhouse.ts`
- Dati della fabbrica numerica: `src/data/numberFactory.ts`
- Dati dell'archivio linguistico: `src/data/wordArchive.ts`
- Puzzle: `src/data/puzzles.ts`
- Dialoghi: `src/data/dialogues.ts`
- Competenze: `src/data/competencies.ts`

Le scene leggono questi dati e aggiornano flag/competenze tramite `MissionEngine`, `SaveSystem` e `CompetencyTracker`.

## Giocatori e classifiche

Dal menu principale:

- `Giocatori`: crea o seleziona profili locali e legge il report del giocatore attivo.
- `Classifiche`: mostra i migliori 20 risultati salvati nel browser per missione, focus ed esercizio.

I dati sono salvati in `localStorage` con chiave separata dal salvataggio principale. Non serve backend nella versione attuale; in futuro `PlayerSystem` potrà essere sostituito con un adapter remoto.
