# Eli Quest · Insieme

Registro condiviso per coordinare il lavoro tra Codex (grafica e integrazione
visiva) e il collaboratore (claude opus). Il riferimento di design è costituito
da `docs/VISIONE_DI_GIOCO.md`, `docs/DESIGN_COMPLETO.md` e
`docs/ARCHITETTURA_FULL_GODOT.md`.

## Obiettivo comune

Portare Eli Quest a **full Godot**, mantenendo il loop:

> **Fuori si allenano le missioni · dentro si riparano gli apparati e si sale di livello.**

La grafica deve comunicare un mondo caldo, leggibile e ricco in stile Animal
Crossing; il codice deve rendere il loop giocabile, persistente e verificabile.

## Responsabilità

### Codex · grafica e integrazione visiva

- Direzione artistica, palette, luce, atmosfera e stile Animal Crossing.
- Composizione dei biomi: percorsi, punti focali, masse naturali e quinte.
- Asset bitmap generati o adattati, atlanti trasparenti e loro ottimizzazione.
- Rendering Godot: terreno, chunk, LOD, camera, profondità, giorno/notte.
- Gerarchia visiva di HUD, marker, portale, missioni e apparati.
- Verifica screenshot/export e correzione degli stacchi visivi.

Codex non modifica la semantica di ricompense, salvataggio o progressione senza
segnalarlo nel registro.

### Collaboratore · coding e sistemi Godot

- `SaveManager`, migrazione dal save Phaser e versionamento schema.
- `ContentManager`, banchi esercizi e selezione adattiva.
- `ExercisePlayer` con sessioni `mission` e `final_exam`.
- `ProgressionManager`: livello, mastery, missioni per materia, gate e apparati.
- Collegamento dei POI del mondo a esercizi nativi Godot, senza ritorno a Phaser.
- Hub/nave, riparazione apparati, NORA e stato narrativo.
- Audit, test, parità, round-trip, export Web/Windows e regressioni.

Il collaboratore riusa gli asset esistenti senza crearne di nuovi; quando serve
un elemento visivo apre una richiesta in questo file.

## Regole di collaborazione

1. Un blocco è **in lavorazione** da una sola persona alla volta.
2. Ogni consegna aggiorna la tabella di stato e indica file modificati, test
   eseguiti e dipendenze rimaste.
3. Nessuna modifica deve rompere gli audit esistenti o la parità del generatore.
4. La grafica è render-only quando possibile: non altera collisioni, seed,
   posizioni gameplay o ricompense.
5. Prima di unire due blocchi: `git diff --check`, audit Godot e test pertinenti.

## Roadmap condivisa

| Fase | Risultato | Responsabile primario | Stato |
|---|---|---|---|
| 0 | Save canonico, primo banco, `ExercisePlayer` | Collaboratore | Integrato nella scena outdoor; audit verde |
| 1 | Missioni fuori → gate → esame → apparato → livello | Collaboratore | Missione/esame nativi integrati; polish HUD residuo |
| 2 | Tutte le materie, scala 20+, adattività | Collaboratore | Da iniziare |
| 3 | NORA e storia agganciate ai livelli | Collaboratore | Da iniziare |
| 4 | Generatori nativi prioritari, spegnimento progressivo Phaser | Collaboratore | Da iniziare |
| 5 | Export full Godot unico | Insieme | Da iniziare |
| V-A | Radura Accademia: hero, natura, sentieri, luce e LOD | Codex | Vertical slice visivo presente |
| V-B | Biomi coerenti e transizioni senza seam | Codex | Raccordo cromatico applicato; verifica visiva residua |
| V-C | HUD/marker coerenti con livello, mastery e apparati | Codex | HUD dati runtime e overlay esercizi in polish |
| V-D | Polish finale, accessibilità visiva e performance | Codex | Da iniziare |

## Stato iniziale · 20 luglio 2026

- [x] Documenti bussola aggiornati al loop semplificato.
- [x] Hero Radura Accademia e atlanti naturali v2 integrati.
- [x] Chunk boundary nascoste, composizione procedurale e LOD render-only.
- [x] `SaveManager`, `ContentManager`, `ExercisePlayer` e
  `ProgressionManager` creati.
- [x] Audit loop Fase 1: missioni → gate → riparazione → livello successivo.
- [x] Collegare gli incontri del mondo a `ExercisePlayer` nativo.
- [x] Implementare `final_exam` reale e apparato riparabile nella nave.
- [x] Sostituire l'HUD legacy con progressione livello/materia/mastery.
- [ ] Eliminare completamente lo stacco visivo tra chunk della Radura (raccordo applicato, manca screenshot Web).

## Blocco assegnato al collaboratore · C-01

**Obiettivo:** integrare il loop Fase 1 nel mondo esterno senza modificare la
direzione grafica.

Consegna richiesta:

1. Aggiungere un `ExercisePlayer` overlay alla scena Godot.
2. Convertire un incontro del mondo in `ExerciseSession.kind = "mission"`.
3. Al superamento aggiornare energia, mastery e `missionsBySubject` nel save.
4. Aggiungere il gate per l'apparato matematico e una prima sessione
   `kind = "final_exam"`.
5. Restituire al mondo uno stato runtime leggibile dall'HUD, senza testo
   definitivo: Codex curerà gerarchia, stile e layout.
6. Aggiungere/aggiornare un audit headless per il percorso completo.

Criteri d'uscita C-01:

- missione avviabile e completabile dentro Godot;
- energia consumata all'ingresso e guadagnata solo per risposte corrette;
- gate verificabile e apparato riparabile dopo l'esame finale;
- nessun redirect a Phaser durante il percorso;
- audit e build eseguiti con esito positivo;
- aggiornamento di questa sezione con file, test e limiti residui.

## Blocco grafico Codex · V-01

In parallelo Codex lavorerà su:

1. eliminazione dello stacco tra chunk della Radura;
2. uniformazione di luce/contrasto tra hero e terreno procedurale;
3. riduzione del pannello HUD e preparazione di slot per livello, materia,
   mastery e missioni residue;
4. marker missione/apparato più diegetici e meno tecnici;
5. verifica screenshot a 1280×720 e viewport Web responsive.

Dipendenza: V-01 userà i dati runtime esposti da C-01, ma può procedere subito
su seam, luce e gerarchia visiva.

## Registro consegne

| Data | Persona | Blocco | Modifiche | Verifiche | Prossimo passo |
|---|---|---|---|---|---|
| 2026-07-20 | Codex | V-00 | Hero v2, atlanti v2, composizione, LOD | fixture, round-trip, export Web/Windows | V-01 |
| 2026-07-20 | Collaboratore | C-00 | Scheletro full-Godot e documenti bussola | loop audit Fase 1 verde | C-01 |
| 2026-07-20 | Claude Opus + Codex | C-01/V-01 | Missione ed esame nativi; HUD runtime; raccordo chunk; overlay esercizi tematizzato | editor scan, fixture, round-trip missione+esame verdi | screenshot Web e rifinitura marker |
| 2026-07-20 | Codex | V-01 parziale | Raccordi cromatici sui quattro chunk adiacenti alla Radura; hero meno rettangolare; portale ridotto e integrato con pietre/archi morbidi | editor scan e `git diff --check` verdi; fixture verde; round-trip da riallineare al C-01 | completare HUD dopo il contratto runtime |

## Formato aggiornamento obbligatorio

```text
### Aggiornamento [data] · [persona] · [blocco]
- Fatto:
- File:
- Test/export:
- Limiti o rischi:
- Prossimo passo:
```

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · C-01
- Fatto: audit headless del **percorso completo C-01** (missione nativa → gate →
  esame finale → riparazione apparato → salita di livello) usando l'ExercisePlayer
  reale con risposte simulate; copre anche il caso di missione fallita. Rimosse 3
  variabili membro morte introdotte per errore in `outdoor_world.gd`.
  L'integrazione nel mondo (incontro→missione nativa, terminale apparato→esame,
  `_on_exercise_finished`, `_leave_world` con `godotSave`) risulta già completata
  dal blocco C-01 in corso: non ho toccato quella logica per non entrare in conflitto.
- File: `godot/scripts/game/c01_audit.gd` (nuovo); `godot/scripts/outdoor_world.gd`
  (solo rimozione di 3 var morte).
- Test/export: `godot --headless --path godot --script res://scripts/game/c01_audit.gd`
  e `.../loop_audit.gd` (qui senza Godot: verificati per ispezione).
- Limiti o rischi: in `outdoor_world.gd` `_update_objective` ha **codice morto**
  dopo il primo `return` (~righe 713-718) con una stringa di formato malformata —
  innocuo perché irraggiungibile, ma da ripulire da chi possiede il file. La slice
  usa solo il banco `matematica`; le altre materie richiedono banchi (Fase 2).
- Prossimo passo: eseguire c01_audit + loop_audit verdi in editor; poi Fase 2
  (banchi per tutte le materie) o esporre a Codex il contratto runtime per V-C.

### Aggiornamento 2026-07-20 · Codex (Collaboratore tecnico) · C-01
- Fatto: collegato ogni incontro del mondo al `ExercisePlayer` nativo con
  `ExerciseSession.kind=mission`; consumo energia all'ingresso, ricompense solo
  per risposte corrette, aggiornamento di mastery e `missionsBySubject`.
  Aggiunto terminale gameplay per il `final_exam` del Nucleo: gate missioni +
  mastery, riparazione apparato e avanzamento livello. Eliminato il redirect a
  Phaser durante l'incontro; il portale conserva il bridge legacy per l'uscita.
- File: `godot/scripts/outdoor_world.gd`,
  `godot/scripts/game/save_manager.gd`, `content_manager.gd`,
  `progression_manager.gd`, `exercise_player.gd`, `godot/scripts/save_bridge.gd`,
  `godot/scripts/roundtrip_audit.gd`, `src/integration/outdoorGodotBridge.ts`,
  `src/scenes/OutdoorAdventureScene.ts`, `src/scenes/ExplorableRoomScene.ts`.
- Test/export: `fixture_audit.gd` ✅, `loop_audit.gd` ✅, `roundtrip_audit.gd`
  aggiornato e ✅ (missione nativa + esame finale); nessun redirect durante il
  percorso. Vitest bridge mirato 2/2 ✅; export Web/Windows ✅. I comandi Godot
  richiedono `--log-file` assoluto in questo ambiente.
- Limiti o rischi: il banco nativo disponibile è ancora solo `matematica`;
  il terminale non ha marker grafico dedicato e il layout/HUD resta a Codex.
  I campi `godotSave`, `mastery`, `missionsBySubject` e `apparatus` nel risultato
  sono opzionali per il bridge Phaser e richiedono consumo lato TS nella Fase 2.
  I rami legacy unreachable e il vecchio testo di redirect sono stati rimossi;
  il portale di uscita resta intenzionalmente compatibile col bridge.
- Prossimo passo: Codex può collegare HUD/marker ai dati runtime; poi aggiungere
  i banchi delle altre materie e la scena nave full-Godot.
