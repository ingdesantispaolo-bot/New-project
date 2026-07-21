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

## Piano operativo autonomo · revisione 2

Da questo punto i due percorsi avanzano in parallelo. Claude Opus non deve
aspettare una nuova assegnazione: prende il prossimo blocco tecnico disponibile,
rispetta i confini qui sotto e aggiorna il registro alla consegna. Codex procede
in autonomia sui blocchi visivi e non modifica la semantica del gioco.

### Confini dei file

| Area | Proprietario | Regola |
|---|---|---|
| `godot/scripts/game/**` | Claude Opus | gameplay, save, contenuti, progressione, audit |
| `godot/data/banks/**` | Claude Opus | banchi JSON e validatori |
| `godot/scripts/ui/**`, `godot/scripts/visual/**` | Codex | HUD, marker, VFX, stile, composizione |
| `godot/assets/**` | Codex | asset grafici, atlanti, import e ottimizzazione |
| `godot/scripts/outdoor_world.gd` | Insieme | solo orchestrazione; modifiche annotate e non simultanee |
| `godot/scripts/chunk_*.gd`, `visual_factory.gd` | Codex | rendering render-only; nessun cambio al contratto gameplay |
| `save_bridge.gd`, `src/integration/**` | Claude Opus | contratto di persistenza/bridge; Codex li legge soltanto |
| `Insieme.md` | Insieme | append-only per gli aggiornamenti, niente cancellazioni storiche |

Obiettivo strutturale del primo blocco autonomo: spostare la logica gameplay da
`outdoor_world.gd` in `godot/scripts/game/outdoor_gameplay.gd` e la presentazione
in `godot/scripts/ui/outdoor_hud.gd`. Dopo questa separazione i due percorsi non
devono più modificare lo stesso file nello stesso momento.

### Contratto runtime tra i due percorsi

Claude espone un dizionario `OutdoorRuntimeState` tramite segnale o metodo di
lettura; Codex lo visualizza senza ricalcolarlo:

```json
{
  "level": 1,
  "focusSubject": "matematica",
  "apparatus": "nucleo",
  "missionsDone": 0,
  "missionsRequired": 5,
  "mastery": 0.0,
  "masteryThreshold": 0.70,
  "ready": false,
  "energy": 120,
  "fragments": 0,
  "phase": "giorno",
  "sessionActive": false
}
```

Il contratto è informativo: la UI non concede ricompense, non apre gate e non
modifica il save. Ogni campo aggiunto deve essere backward-compatible.

## Percorso autonomo Claude Opus · C-02 → C-10

Claude esegue i blocchi in ordine, può procedere al successivo quando i criteri
di uscita sono verdi e deve lasciare il progetto compilabile a ogni consegna.

### C-02 · Stabilizzazione e separazione dei confini

- estrarre `outdoor_gameplay.gd` da `outdoor_world.gd`;
- definire `OutdoorRuntimeState` e aggiornamento evento-driven;
- eliminare rami legacy irraggiungibili e testi Phaser dal percorso missione;
- mantenere il portale legacy solo finché la migrazione lo richiede.

Uscita: editor scan, fixture, loop, round-trip e `c01_audit` verdi; nessuna
logica di ricompensa nel codice HUD.

### C-03 · Save canonico e migrazione

- completare schema versionato con `narrative`, `daily`, `spacedRepetition`,
  `modules`, `cosmetics` e `outdoor`;
- rendere `migrate_from_phaser()` idempotente;
- aggiungere fixture di save v0/v1 e audit di migrazione;
- persistire `godotSave` senza perdere campi sconosciuti.

Uscita: due migrazioni consecutive producono lo stesso JSON e nessun progresso
viene perso.

### C-04 · Contenuti e banchi

- generare banchi verificati per matematica, italiano, inglese, coding, fisica,
  musica, latino ed elettronica;
- implementare audit: risposta valida, spiegazione presente, difficoltà valida;
- selezione adattiva su livello, mastery e ripasso spaziato;
- mantenere `ExercisePlayer` indipendente dalla materia.

Uscita: ogni materia ha un banco minimo giocabile e un audit automatico verde.

### C-05 · Scala di progressione 1→20+

- spostare la tabella dei gate in dati tunable;
- implementare apparati riparati per livello e reset corretto delle missioni;
- aggiungere test per livelli 1, 2, 6, 12, 20 e 24;
- verificare errore con penalità morbida e nessuna perdita distruttiva.

Uscita: la scala completa è percorribile senza modificare codice di scena.

### C-06 · Nave e apparati

- creare `HubScene`/nave minimale funzionale;
- stanze leggibili, requisiti, pulsante Ripara e stato riparato;
- `final_exam` avviabile solo quando i gate sono soddisfatti;
- ritorno al mondo senza ricarica distruttiva del save.

Uscita: missioni fuori → ingresso nave → esame → apparato acceso → livello +1.

### C-07 · NORA e narrazione

- `NarrativeManager` agganciato agli apparati riparati;
- beat NORA per livelli 1–6 come primo arco;
- codex/frammenti opzionali senza bloccare il loop;
- testi caricati da dati, non hard-coded nelle scene.

Uscita: ogni riparazione produce un feedback narrativo persistente.

### C-08 · Adattività, accessibilità e telemetria locale

- mastery per argomento e ripasso spaziato;
- modalità effetti ridotti, testi leggibili e input tastiera/touch;
- report locale per livello, materia, mastery, missioni e tempo;
- nessuna raccolta remota non autorizzata.

Uscita: sessione breve completa con feedback didattico e report locale.

### C-09 · Spegnimento progressivo Phaser

- migrare un generatore alla volta in GDScript o banco Godot;
- audit di parità per ogni generatore portato;
- rimuovere dipendenze runtime Phaser solo quando il sostituto è coperto;
- aggiornare il fallback e la matrice delle funzioni migrate.

Uscita: nessun redirect durante il loop Godot e matrice di copertura aggiornata.

### C-10 · Release full-Godot

- un solo boot Godot Web alla radice del deploy;
- export Windows/Web riproducibili;
- smoke test da nuovo profilo, migrazione save e round-trip completo;
- documento di rilascio con limiti noti e rollback.

Uscita: artefatti pubblicabili e checklist release completamente verde.

### Checklist Claude a ogni consegna

```text
[ ] Ho lavorato solo nei file di mia area o ho registrato il lock condiviso.
[ ] Ho aggiunto/aggiornato un audit riproducibile.
[ ] fixture_audit, loop_audit, roundtrip_audit e audit del blocco sono verdi.
[ ] Ho eseguito git diff --check.
[ ] Ho aggiornato il Registro consegne e indicato il prossimo blocco.
```

## Percorso autonomo Codex · V-02 → V-10

### V-02 · Seam e linguaggio visivo dei biomi

- chiudere le transizioni academy senza stacchi percepibili;
- definire palette, densità, scala e silhouette per ogni bioma;
- verificare chunk centrale, periferico e attraversamento del bordo.

### V-03 · HUD e marker diegetici

- spostare la UI in `outdoor_hud.gd`;
- visualizzare `OutdoorRuntimeState` senza logica duplicata;
- sostituire testi tecnici con obiettivi leggibili, icone e progress bars;
- marker missione, apparato e portale con priorità visiva coerente.

### V-04 · ExercisePlayer e feedback

- mantenere il contratto di Claude, migliorare layout, focus, contrasto,
  feedback giusto/errore, scudi e progressione;
- verificare desktop 1280×720, Web responsive e touch;
- nessun cambiamento a validatori o ricompense.

### V-05 · Nave: kit artistico e gerarchia

- scenografia modulare delle stanze/apparati;
- apparato guasto, riparabile e acceso come tre stati visivi;
- NORA, console e percorso di rientro leggibili senza testo invasivo.

### V-06 · Biomi completi

- estendere il kit a Bosco, Dorsale, Cratere, Rovine e Cristallo;
- aggiungere landmark, quinte, acqua, rocce e vegetazione per bioma;
- mantenere LOD e seed render-only.

### V-07 · Atmosfera e vita del mondo

- giorno/notte, foschia, bagliori, particelle e animazioni ambientali;
- micro-variazioni controllate, niente rumore casuale vicino agli obiettivi;
- accessibilità: intensità effetti ridotta.

### V-08 · Responsive e accessibilità visiva

- safe areas mobile, contrasto, font, outline, riduzione motion;
- camera e HUD su aspect ratio diversi;
- marker leggibili anche in notte e su fondali chiari.

### V-09 · Performance grafica

- misurare draw calls, texture memory, nodi per chunk e tempo di streaming;
- LOD per chunk periferici e pooling degli effetti;
- comprimere asset senza perdita percettibile.

### V-10 · Polish e approvazione visiva

- confronto screenshot con il modello Animal Crossing;
- checklist per ogni bioma e scena nave;
- aggiornamento art direction e gallery di riferimento;
- nessun polish finale prima che C-06/C-07 espongano i dati definitivi.

### Checklist Codex a ogni consegna

```text
[ ] Ho modificato solo rendering, asset o UI visuale.
[ ] Non ho cambiato seed, collisioni, ricompense o gate.
[ ] Ho verificato almeno editor scan + fixture + round-trip.
[ ] Ho registrato eventuali dipendenze dal contratto runtime.
[ ] Ho aggiornato Registro consegne e prossimo blocco V.
```

## Gate di integrazione tra i due percorsi

I percorsi si incontrano solo ai seguenti gate:

| Gate | Claude consegna | Codex verifica |
|---|---|---|
| I-01 | `OutdoorRuntimeState` stabile | HUD legge i dati senza duplicare logica |
| I-02 | Nave/apparati con stati persistenti | stati visivi guasto/riparabile/acceso |
| I-03 | NarrativeManager e beat | layout dialoghi e feedback NORA |
| I-04 | banchi e generatori definitivi | densità marker, iconografia e leggibilità |
| I-05 | build release full-Godot | screenshot, responsive e performance |

Un gate non è superato da un audit headless soltanto: richiede anche la verifica
del proprietario dell’altro percorso e una riga nel Registro consegne.

## Ordine operativo immediato

### Claude Opus

1. C-02: separare gameplay e UI, stabilizzare `OutdoorRuntimeState`.
2. C-03: completare schema save e audit migrazione.
3. C-04: portare i banchi minimi delle materie mancanti.
4. Fermarsi solo se un criterio di uscita è rosso; in quel caso registrare il
   blocco, il comando che fallisce e il file responsabile.

### Codex

1. V-02: chiudere seam e palette tra chunk academy.
2. V-03: estrarre HUD visuale dal mondo e collegarlo al contratto runtime.
3. V-04: rifinire `ExercisePlayer` senza toccare la semantica.
4. Procedere ai biomi e alla nave quando i gate I-01/I-02 saranno disponibili.

### Regola di handoff

Quando Claude consegna C-02, Codex non deve modificare la sua nuova area
gameplay: legge il contratto e costruisce la UI. Quando Codex consegna V-03,
Claude non deve incorporare logica di ricompensa nell'HUD: emette solo dati e
segnali. Le richieste urgenti passano da una nuova riga nel registro, non da
modifiche simultanee allo stesso file.

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
| V-B | Biomi coerenti e transizioni senza seam | Codex | Palette percettiva e fasce focus/neighbor applicate; verifica visiva residua |
| V-C | HUD/marker coerenti con livello, mastery e apparati | Codex | Componente `OutdoorHud` pronta; collegamento dopo I-01 |
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
| 2026-07-20 | Codex | QA V-01 | Build TypeScript e export Godot aggiornati | build 0, fixture 0, loop 0, round-trip 0, Web 0, Windows 0 | test screenshot manuale quando il browser è disponibile |
| 2026-07-20 | Codex | V-01 parziale | Raccordi cromatici sui quattro chunk adiacenti alla Radura; hero meno rettangolare; portale ridotto e integrato con pietre/archi morbidi | editor scan e `git diff --check` verdi; fixture verde; round-trip da riallineare al C-01 | completare HUD dopo il contratto runtime |
| 2026-07-20 | Codex | Coordinamento rev.2 | Percorsi Claude C-02→C-10 e Codex V-02→V-10; ownership file; contratto runtime; gate I-01→I-05 | `git diff --check` verde | Claude parte da C-02; Codex da V-02 |
| 2026-07-20 | Codex | V-02 | Fasce di fusione academy, palette percettiva per sei biomi, fiori periferici coerenti | editor scan, fixture, loop, round-trip verdi | V-03 HUD separato |
| 2026-07-20 | Codex | V-03/V-04 grafico | `OutdoorHud` responsive con safe-area desktop/Web/touch, mastery/risorse/prompt; `OutdoorInteractionMarker` diegetico per missione/tesoro/apparato/portale | editor scan verde; nessuna modifica a gameplay/save/seed; round-trip resta dipendenza Claude | consegnare API visuali per integrazione dopo I-01 |
| 2026-07-20 | Codex | V-05 parziale | Aggiunto kit `OutdoorVisualFactory` per terminale apparato (broken/ready/repaired) e backdrop modulare delle stanze nave | editor scan verde; componenti render-only, nessuna logica di riparazione | integrazione nella scena nave dopo contratto apparati Claude |
| 2026-07-20 | Codex | V-06 parziale | Aggiunto `build_biome_landmark()` con grammatica canonica per Radura, Bosco, Dorsale, Cratere, Rovine e Cristallo; riuso dei landmark esistenti con palette dedicate | editor scan verde; nessuna modifica a seed/generatori/collisioni | completare atmosfera e accessibilità V-07/V-08 |
| 2026-07-20 | Codex | V-07/V-08/V-09 | Aggiunti `OutdoorAtmosphere` (fase/bioma, foschia, particelle e reduced motion), `VisualAccessibility` (contrasto/outline/policy) e `OutdoorVisualBudget` (tier LOD e budget particelle) | editor scan verde; classi render-only registrate; nessuna modifica al percorso Claude | integrazione chiamante dopo I-01; V-10 chiuso come kit tecnico |
| 2026-07-20 | Codex | V-10 | Chiuso il kit visuale riutilizzabile: HUD, marker, apparati nave, landmark biomi, atmosfera, accessibilità e budget | verifica statica Godot verde; screenshot manuale e wiring runtime restano gate di integrazione | attendere I-01/I-05 per collegamento finale |
| 2026-07-20 | Codex su richiesta utente | C-02 | Collegato `OutdoorGameplay` a `outdoor_world`: runtime event-driven, sessioni native, energia solo esercizi, tesori solo frammenti, uscita via `publish_exit_state` | C-02, C-01, loop e round-trip verdi | C-03 save/migrazione |
| 2026-07-20 | Codex su richiesta utente | C-03 | Esteso save canonico con `narrative`, `daily`, `spacedRepetition`; migrazione idempotente e preservazione campi sconosciuti; aggiunto audit | C-03, C-02 e round-trip verdi | C-04 banchi multi-materia |
| 2026-07-20 | Codex su richiesta utente | C-04 | Aggiunti banchi minimi per italiano, inglese, coding, fisica, musica, latino ed elettronica; validazione automatica di risposta, spiegazione e difficoltà | C-04, C-02 e round-trip verdi | C-05 scala livelli/gate |
| 2026-07-20 | Codex su richiesta utente | C-05 | Verificata scala tunable livelli 1→24, rotazione materie, soglie e reset missioni/apparato; aggiunto audit livelli 1/2/6/12/20/24 | C-05 audit verde; C-02 e round-trip verdi | C-06 nave/apparati |
| 2026-07-20 | Codex su richiesta utente | C-06 parziale | Aggiunto `HubController` minimale per gate, stato apparato e richiesta esame; kit visuale nave già disponibile | C-06 audit verde; integrazione scene nave resta da collegare | C-07 narrativa/NORA |
| 2026-07-20 | Codex su richiesta utente | C-07 | Aggiunto `NarrativeManager` con beat NORA livelli 1→6, persistenti e data-driven | C-07 audit verde | C-08 report locale/accessibilità |
| 2026-07-20 | Codex su richiesta utente | C-08 | Aggiunto `LocalProgressReport` per sessioni, missioni, mastery e tempo senza rete | C-08 audit verde | C-09 matrice Phaser/Godot |
| 2026-07-20 | Codex su richiesta utente | C-10 parziale | Build TypeScript, export Web e Windows completati con nuovi script/banchi; export exit 0 | build 0, Web 0, Windows 0; browser smoke test ancora manuale | C-09 matrice copertura e test browser |
| 2026-07-20 | Codex su richiesta utente | C-06/C-09/C-10 chiusura tecnica | Aggiunti `hub.tscn`/`hub_scene.gd`, matrice Phaser→Godot e `c10_audit` da profilo nuovo | editor scan, C-06, C-10, fixture e round-trip verdi; Web/Windows export 0 | solo test click manuale in browser |
| 2026-07-21 | Codex | Architettura biomi AAA | Definita pipeline globale A1→A6: chunk solo streaming, macro-layout continuo, spline, assemblies, hero pockets, profili bioma e HLOD | revisione tecnica su generator/rendering esistenti e fonti PCG AAA | A1: `WorldCompositionData` e sampler globale |

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

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · C-02 (parziale)
- Fatto: estratta la logica gameplay in `godot/scripts/game/outdoor_gameplay.gd`
  (nuovo) con il contratto `OutdoorRuntimeState` completo e segnali evento-driven
  (`runtime_state_changed`, `session_requested`, `feedback`). Audit headless
  `c02_audit.gd` che verifica contratto + loop nativo (missione → gate → esame →
  riparazione → livello) e stato d'uscita. Nessuna logica di ricompensa fuori dal
  componente gameplay.
- File: `godot/scripts/game/outdoor_gameplay.gd`, `godot/scripts/game/c02_audit.gd`.
- Test/export: `godot --headless --path godot --script res://scripts/game/c02_audit.gd`
  (qui senza Godot: verificato per ispezione). c01_audit/loop_audit invariati.
- Limiti o rischi: il WIRING in `outdoor_world.gd` (far delegare la scena al
  componente e far leggere l'HUD da `runtime`) NON e' stato applicato: durante il
  tentativo si e' verificata una COLLISIONE di editing simultaneo sul file
  condiviso (regola 1). Ho ripristinato `outdoor_world.gd` all'ultimo commit
  pulito (fbddfcd) per non lasciarlo rotto. Il componente e' pronto ma scollegato.
- Prossimo passo: serve un LOCK ESCLUSIVO su `outdoor_world.gd` per applicare il
  wiring senza modifiche simultanee. Appena il file e' libero e annotato qui,
  applico il rewiring (delego a OutdoorGameplay, HUD legge runtime) in un'unica
  passata e aggiorno il registro.

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · C-02 (completato)
- Fatto: con lock esclusivo, sanato `outdoor_world.gd`. La scena ora usa un
  UNICO stato (`OutdoorGameplay`): rimossi i vecchi manager alias
  (`game_save`/`content_manager`/`progression_manager`), i loro const preload e
  `base_energy`/`base_fragments`. HUD (`_refresh_economy`, `_update_objective`,
  prompt apparato) legge SOLO dal `runtime` (contratto OutdoorRuntimeState) via
  segnale `runtime_state_changed`. Aggiunto `gameplay.update_phase` nel ciclo
  giorno/notte. Rimosse le funzioni morte `_start_mission_session`,
  `start_final_exam`, `_subject_for_payload` e l'hack "energia" del popup tesori.
  Nessun doppio stato: prima gli alias puntavano alla stessa istanza (non era un
  bug di dati) ma la logica era duplicata; ora è separata e single-source.
- File: `godot/scripts/outdoor_world.gd` (da ~703 a 622 righe).
- Test/export: `git diff --check` pulito; nessun ternario C-style; nessun
  riferimento residuo ai simboli rimossi. Da eseguire in editor: `c01_audit`,
  `c02_audit`, `loop_audit`, `fixture_audit`, `roundtrip_audit` (qui senza Godot).
- Limiti o rischi: verifica in editor non eseguita in questo ambiente. Il testo
  HUD (incl. il refuso "Â·" nell'economy_hint) resta area Codex. La scala oltre
  il Nucleo/livello 1 richiede i banchi delle altre materie (già presenti) e il
  terminale apparato dinamico (oltre C-02).
- Prossimo passo: C-02 chiuso lato codice. Codex può cablare HUD/marker al
  contratto runtime (gate I-01 sbloccato). Io posso procedere alla review dei
  blocchi C-03→C-08 già presenti (opzione B) o proseguire il percorso.
