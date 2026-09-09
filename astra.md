# ASTRA × OPUS — Piano eseguibile

Stato: da iniziare · 09/09/2026. Sostituisce il piano precedente.

**Obiettivo:** nei 24 mondi, capire serve ad agire, aiutare gli abitanti e aprire possibilità. Migliorare missioni esistenti senza aumentare le prove obbligatorie.

## Organizzazione

- **Opus:** concetti, prerequisiti, casi, errori, aiuti e dialoghi. **Astra:** interazioni, integrazione, feedback ambientale, persistenza e verifiche. Revisione reciproca.
- Prima di ogni lotto: controllare `git status` e assegnare file. Astra integra i file condivisi; niente scritture concorrenti o export/bake simultanei.
- Riutilizzare Godot, renderer, cataloghi e asset. Conservare trama, fasce correnti, gate e salvataggi. Nessun requisito di studenti/docenti: revisione AI e audit verificano il progetto, non dimostrano efficacia educativa o divertimento umano.

## Fasi sequenziali

| Fase | Opus | Astra | Criterio d'uscita |
|---|---|---|---|
| **0 · Selezione** | Analizza una missione del mondo 1: concetto e due errori tipici. | La riproduce; identifica renderer, agganci, numero di prove e interruzioni obbligatorie. | Intervento scelto, realizzabile senza nuovo renderer o asset. |
| **1 · Pilota** | Prepara dimostrazione, caso autonomo, variante e feedback. | Sostituisce la missione e collega una conseguenza persistente. | Successo, errore, aiuto e riavvio funzionano; carico obbligatorio non aumentato. |
| **2 · Riuso** | Adatta lo schema a italiano e coding; revisiona soluzioni e ambiguità. | Integra due missioni usando sistemi esistenti. | Tre missioni complete; componenti comuni estratti solo dove servono. |
| **3 · Estensione** | Prepara una missione caratterizzante per mondo. | Integra lotti di massimo 3 mondi: prima 1–12, poi 13–24. | Ogni lotto supera i controlli sotto prima del successivo. |
| **4 · Chiusura** | Controlla progressione concettuale e coerenza narrativa sui 24 mondi. | Verifica gate, save e build Web. | 24 missioni collegate e verificate; nessun difetto bloccante aperto. |

**Pilota:** raggruppare cristalli per alimentare un dispositivo della Radura. Usare un'interazione manipolabile esistente che rappresenti davvero il concetto; se manca, scegliere un problema equivalente già supportato. Collegare una macchina presente, senza costruire nuova navigazione.

## Contratto minimo di ogni missione

- **Scopo → azione:** bisogno concreto di un abitante; indicare quale decisione richiede la conoscenza. Cambiare etichetta a un quiz non basta.
- **Scoperta:** NORA dimostra un passaggio, Eli completa l'analogo. Informazioni nuove prima dell'uso; approfondimento nel Manuale.
- **Errore:** due errori plausibili con feedback causale; aiuto sul dettaglio, poi sul metodo. Manipolazioni preparatorie senza penalità; demo senza padronanza; consegna valutata dallo scoring esistente.
- **Autonomia:** caso senza suggerimento iniziale e variante con stesso concetto in contesto diverso. Sostituire nodi previsti; se manca spazio, collocare la variante in un incontro successivo.
- **Conseguenza:** cambiamento salvato, breve reazione del personaggio e prossimo scopo. Dare un uso reale al dispositivo riparato quando supportato.

## Profondità e ritmo

- Alternare costruzione, diagnosi, interpretazione e pianificazione con i minigiochi disponibili; evitare sequenze consecutive della stessa azione.
- Nei mondi 13–24 riprendere la materia con un vincolo nuovo, una diagnosi o una scelta di strategia. Numeri più grandi non bastano.
- Mostrare subito l'obiettivo; spiegare vicino all'azione. Non aumentare prove e schermate obbligatorie rispetto alla missione sostituita.
- Riutilizzare umorismo, Custode e indizi della trama; conseguenze riconoscibili e curiosità sul prossimo incontro, senza nuove ramificazioni.
- Usare il ripasso esistente per le varianti. Marcare trasferimento solo per casi revisionati: difficoltà maggiore o topic diverso non lo garantiscono.

## Controlli e consegna

**Opus:** risolvere casi e varianti, cercare ambiguità, soluzioni alternative e scorciatoie; verificare che tutto il necessario sia stato insegnato. **Astra:** provare dal vero ingresso successo, errori ripetuti, aiuti, uscita/rientro; controllare ricompense duplicate, persistenza e progressione con save isolati.

Audit mirati sui comportamenti nuovi; input casuali e replay per rilevare padronanza indebita. Ispezionare scene renderizzate e comandi touch: il solo audit dei dati non basta. Nessuna simulazione AI viene presentata come prova con studenti.

Comandi: `npm run audit:godot -- <filtro>` per lotto; alla chiusura `npm run release:web`, `npm run audit:web`, `npm run smoke:web:godot`; test touch disponibile se cambiano i comandi.

Registro minimo da aggiornare qui: `mondo | owner | stato | file | verifica/esito | difetto aperto`. Stati: da fare / in corso / verificato.

## Confini tecnici

In `godot/scripts/game/`: cataloghi `minimission_catalog.gd`, `character_minigame_catalog.gd`, `world_lesson.gd`; runtime `mission_event_director.gd`, `content_manager.gd`, `exercise_player.gd`; insegnamento `teaching_catalog.gd`, `knowledge_codex.gd`. Seguire [README](README.md) per sorgenti/bake; coordinarsi col [piano fasce](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).

**Fuori scope:** nuovo scheduler temporale, riscrittura mastery, framework di missioni, asset nuovi, multiplayer, altri mondi o ampliamento del Secondo Viaggio.
