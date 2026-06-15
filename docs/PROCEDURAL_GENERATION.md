# Procedural Generation

## Obiettivo

La generazione procedurale di Eli Quest non produce quiz casuali. Produce missioni esplorative nuove, riproducibili e validate, mantenendo coerenza narrativa e valore didattico.

La prima missione procedurale è **Laboratorio Sempre Diverso**: una stanza riconfigurata dell'Accademia con segnale italiano corrotto, circuito guasto, terminale numerico, istruzione inglese e robot su griglia.

## Seed

Ogni missione ha un seed leggibile, salvato nel diario e nel `localStorage`.

Usiamo seed perché:

- lo stesso seed deve ricreare la stessa missione;
- un adulto o un docente può condividere una missione precisa;
- i bug possono essere riprodotti;
- la difficoltà può crescere senza perdere controllo.

I generatori non usano `Math.random`. Usano `Random`, un PRNG deterministico inizializzato dal seed.

## Architettura

File principali:

- `src/procedural/Random.ts`: PRNG deterministico.
- `src/procedural/SeedManager.ts`: seed casuali, giornalieri e basati su difficoltà.
- `src/procedural/DifficultyModel.ts`: parametri 1-8.
- `src/procedural/ProceduralDirector.ts`: punto di ingresso per generare una missione completa.
- `src/procedural/MissionGenerator.ts`: assembla mappa, obiettivi, puzzle, ricompense e competenze.
- `src/procedural/PuzzleGenerator.ts`: coordina i generatori specifici.
- `src/procedural/ValidationEngine.ts`: rigenera fino a un limite, poi usa fallback sicuro.
- `src/procedural/solvers`: solver per griglia, circuiti e matematica.
- `src/procedural/validators`: controlli di risolvibilità, coerenza e qualita didattica.
- `src/procedural/simulators`: simulatori per Serra, Fabbrica e Archivio.
- `src/data/procedural`: template controllati.

## Generator Nuovi

Per aggiungere un generatore:

1. Definire template controllati in `src/data/procedural`.
2. Creare un generator in `src/procedural/generators`.
3. Creare o aggiornare un validator.
4. Usare un solver se la risolvibilità non è ovvia.
5. Collegarlo in `PuzzleGenerator` o in un futuro generator specifico di missione.
6. Aggiungere fallback sicuro.

Il generatore deve restituire anche:

- soluzione;
- indizi progressivi;
- competenze allenate;
- testo narrativo breve;
- dati necessari alla scena Phaser.

## Validazione

La validazione serve a evitare missioni didatticamente sbagliate.

Esempi:

- un puzzle matematico deve avere soluzione intera e finita;
- una griglia robot deve avere percorso da start a chiave e da chiave a uscita;
- una frase corrotta deve avere una correzione univoca tra opzioni distinte;
- un circuito deve avere guasti riparabili e diagnosticabili;
- una mappa deve avere hotspot richiesti e non sovrapposti.

Se un candidato fallisce, `ValidationEngine` rigenera. Dopo il limite massimo usa un fallback noto e sicuro.

## Difficoltà

La difficoltà 1-5 regola:

- numero di stanze;
- numero di puzzle;
- complessità matematica;
- dimensione della griglia robot;
- numero ostacoli;
- complessità del circuito;
- indizi disponibili.

La difficoltà non deve solo aumentare numeri. Deve aumentare il carico di ragionamento: più vincoli, più passaggi, meno indizi diretti.

## Narrativa

La missione procedurale resta diegetica:

- gli hotspot sono oggetti della stanza;
- ogni puzzle modifica uno stato della missione;
- la porta finale si apre solo quando tutti i sistemi sono coerenti;
- il diario registra seed, indizi, puzzle e competenze.

La generazione non deve trasformare Eli Quest in una lista di esercizi.

## Stanza Sistemica

`Laboratorio Sempre Diverso` usa un grafo di dipendenze:

1. il testo riparato rende affidabili i log;
2. il circuito stabile alimenta il terminale;
3. il codice numerico sblocca il modulo inglese;
4. il comando inglese autorizza il robot;
5. il robot porta la chiave alla porta.

Il giocatore può osservare i sistemi fuori ordine, ma l'intervento operativo viene bloccato con feedback diegetico se mancano dati affidabili.

## Qualita Delle Sfide

Il `ChallengeQualityValidator` respinge contenuti con soluzione troppo breve, risposta trovabile per tentativi banali, distrattori deboli, meno di 2-3 passaggi cognitivi o indizi incoerenti. Questo controllo completa solver e validator tecnici: una missione deve essere risolvibile e pedagogicamente sensata.

## Estensione Futura

Biologia:

- generatori di piante con bisogni diversi;
- validator che controllano soglie salvabili;
- solver turn-based per assicurare che almeno una strategia salvi le piante.

Storia:

- timeline generate da eventi controllati;
- validator su ordine cronologico;
- distrattori plausibili ma non ambigui.

Geografia:

- mappe con coordinate e scale;
- solver su percorsi e orientamento;
- validator su raggiungibilità e coerenza delle coordinate.

Scienze:

- sistemi con variabili osservabili;
- simulatori semplici e reversibili;
- feedback basato su cause, non su voto.
