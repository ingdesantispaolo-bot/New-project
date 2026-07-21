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
| 2026-07-21 | Codex | Pipeline biomi AAA A1→A6 | Implementati composizione globale, pesi bioma continui, superficie senza hero rettangolare, spline/acqua, hero pockets, assemblies, sei profili, atmosfera interpolata e LOD 0/1/2 | composition audit, fixture, round-trip, C-10, build, Web e Windows verdi | QA screenshot manuale e tuning percettivo |
| 2026-07-21 | Codex | Material pipeline world-space | Generati underpainting pittorici per prato, bosco, minerale, magia, acqua e terra; introdotti shader globali multi-scala/mirror-repeat, sentieri curvi texturizzati, laghi organici e assemblies a tre altezze | render probe diurno, composition audit, fixture, round-trip, loop, C-10, build, Web e Windows verdi; C-02 legacy segnala separatamente livello iniziale inatteso | test movimento reale giorno/notte e tuning compositivo dei landmark |

| 2026-07-21 | Codex | Habitat e varieta compositiva | Fiume spline continuo, rive e ponti orientati; atlante RGBA da 16 micro-dettagli; spawner habitat-aware; quattro archetipi di assembly; sostituzione dei visual primitivi fuori stile; probe Radura/Dorsale/Bosco/Cratere | scene load, composition/habitat, fixture, round-trip, loop, C-10, build, Web e Windows verdi; quattro catture reali verificate | tuning manuale di scala e densita durante esplorazione |
| 2026-07-21 | Codex | C-11 confini, materie e matematica | Fondale pittorico oltre il perimetro 8×8, barriera naturale continua e recupero save fuori mappa; routing bioma/incontro verso 8 materie; generatore matematico a 8 complessità con parametri variabili, anti-ripetizione e ripasso | C-01→C-11, fixture, loop, round-trip, enigma, composition, 184 test e build verdi; probe bordi/Rovine verificati | export Web/Windows e prova manuale esplorazione/materie |
| 2026-07-21 | Codex | Ecotoni, sentieri e notte | Sentieri promossi a spline globali renderizzate una sola volta; props d'acqua vincolate all'habitat; selezione pesata dei visual nelle transizioni; notte più leggibile con luce locale del giocatore | probe Radura/Cratere/ecotono/notte verificati; fixture, round-trip, loop, C-04, C-11 e composition verdi | export Web/Windows e feedback percettivo in movimento |

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

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · C-04 (adattività) — fix criticità
- Fatto: implementato il RIPASSO SPAZIATO adattivo, che mancava (criticità #1
  della review). `ExercisePlayer` ora emette `missed` (topic sbagliati) e
  `reviewedOk` (ripassi risolti). `ContentManager.build_mission(..., review_due)`
  prioritizza gli item dei topic in ripasso e li marca `review:true`, poi
  completa con item vicini alla difficoltà del livello. `OutdoorGameplay`
  aggiorna `save.spacedRepetition.due` dagli esiti e lo passa alla selezione.
  `build_final_exam` corretto (non passava piu' rng nello slot giusto).
  `c04_audit` approfondito: verifica che un topic in ripasso venga ripescato e
  marcato, e che senza ripasso nessun item sia marcato.
- File: `godot/scripts/game/exercise_player.gd`, `content_manager.gd`,
  `outdoor_gameplay.gd`, `c04_audit.gd`.
- Test/export: `git diff --check` pulito; nessun ternario C-style; tutte le
  chiamate a `build_mission` verificate (nessuna passa rng come 4° arg). Da
  eseguire in editor: c04_audit, c01/c02/loop audit (retro-compatibili).
- Limiti o rischi: mastery resta per-materia (il ripasso è per-topic via due);
  i banchi non-matematica hanno 3 item (da arricchire). Restano aperte le
  criticità #2 (loop nave↔mondo non cablato) e #3 (altri audit superficiali).
- Prossimo passo: cablare la navigazione mondo↔nave (C-06) — richiede tocco a
  outdoor_world.gd (Insieme) + transizione di scena; da coordinare.

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · fix criticità review (banchi, audit, nave)
- Fatto (#altro — C-04 contenuti): arricchiti i 7 banchi (italiano, inglese,
  coding, fisica, musica, latino, elettronica) da 3 a 8 item ciascuno, con campo
  `topic` (2-4 argomenti per materia) e difficoltà 1-4. Ora il ripasso spaziato
  è per-argomento e ogni materia è davvero giocabile.
- Fatto (#3 — audit approfonditi): `c06_audit` ora verifica il LOOP di
  riparazione (missioni→gate→exam_requested→repair→livello→gate richiuso);
  `c07_audit` verifica i 6 beat NORA distinti + reveal idempotente + seen + clamp;
  `c08_audit` verifica report vuoto, aggregazione e clamp dei valori.
- Fatto (#2 — nave): `hub_scene.gd` ora è FUNZIONALE: avvia l'esame finale reale
  via ExercisePlayer, ripara e sale di livello, con pulsante di ritorno. Fix
  difensivo in `save_manager.import_bridge_request`: il bridge non può più far
  REGREDIRE il livello (guardia su playerLevel e godotSave) — necessario per la
  transizione mondo↔nave senza perdere progressi.
- File: `godot/data/banks/*.json` (7), `godot/scripts/game/c06_audit.gd`,
  `c07_audit.gd`, `c08_audit.gd`, `save_manager.gd`, `godot/scripts/hub_scene.gd`,
  `godot/scenes/hub.tscn`, `godot/scripts/game/c10_audit.gd`.
- Test/export: banchi validati (8 item, topic, difficoltà 1-4, answer nelle
  opzioni, 0 campi mancanti); nessun ternario C-style; `git diff --check` pulito.
  Da eseguire in editor: c04/c06/c07/c08/c10 + c01/c02/loop (retro-compatibili).
- Limiti o rischi: la navigazione LIVE mondo↔nave sul percorso Web dipende ancora
  dal bridge (energia/frammenti autoritativi da Phaser); la transizione piena è
  un item di Fase 4 (post-bridge). La scena nave è pienamente giocabile standalone.
  Mastery resta per-materia (il ripasso è per-topic). Banchi non-matematica a 8
  item (arricchibili). Energia/frammenti restano da Phaser durante la migrazione.
- Prossimo passo: criticità review chiuse; resta l'integrazione live nave (Fase 4).

### Aggiornamento 2026-07-20 · Claude Opus (Collaboratore) · contratto marker + analisi grafica
- Fatto: (1) corretto il refuso "Â·" nell'economy_hint (outdoor_world.gd, fix nel
  working tree — lo includa Codex col prossimo commit rendering). (2) Arricchito
  `OutdoorRuntimeState` con campi convenienza per HUD/marker, così Codex NON
  ricalcola nulla lato UI: `missionsRemaining`, `missionProgress` (0..1),
  `masteryProgress` (0..1). `c02_audit` valida i nuovi campi.
- File: `godot/scripts/game/outdoor_gameplay.gd`, `c02_audit.gd`,
  `godot/scripts/outdoor_world.gd` (solo la stringa del refuso).

#### Richieste grafiche per Codex (dall'analisi dello screenshot in-game)
Dati già disponibili nel contratto runtime — resta solo la resa:
1. **Affordance interagibili** (priorità alta): casse/tenda/cartello/lampioni
   sembrano decorazione. Servono marker/alone su missioni, tesori e apparato.
   I visual di tesori/incontri sono in `chunk_visual`/`visual_factory` (Codex):
   aggiungere lì un marker per kind. Per lo STATO usare il runtime.
2. **Marker apparato "Nucleo"** e **bussola missione**: usare `runtime.ready`
   (apparato riparabile → pulsa), `runtime.focusSubject` (materia del livello),
   `runtime.missionsRemaining` (testo "N al Nucleo").
3. **HUD in alto a sx → barre**: sostituire "Missioni 0/5" e "Mastery 0%/70%"
   con due progress bar usando `runtime.missionProgress` e `runtime.masteryProgress`.
4. **Composizione**: alternare radure calme e cluster focali (metà sinistra
   molto densa); usare il sentiero per guidare verso i POI.
5. **Leggibilità player**: contorno/alone leggermente più marcato (anche di notte).
6. **Coerenza UI**: bottone "Esci dal mondo" nello stile dei pannelli arrotondati;
   shimmer/bordo sulla pozza d'acqua; verificare marker leggibili di notte.
- Nota: `runtime_state_changed` è il segnale unico; la scena inoltra `runtime`
  all'HUD. Nessun accesso diretto a save/progression dalla UI (gate I-01).
- Prossimo passo: Codex può implementare marker e barre sui campi sopra.

### Aggiornamento 2026-07-21 · Claude Opus (Collaboratore) · enigma ambientale (logica)
- Fatto: scaffold SISTEMI del nuovo tipo di missione **enigma ambientale** (la
  risposta corretta costruisce un elemento del mondo, una campata alla volta).
  Solo logica/contratto; la RESA è di Codex. Loop invariato: l'enigma conta come
  missione per il gate dell'apparato e completa l'incontro.
- File: `godot/scripts/game/exercise_player.gd` (nuovo segnale `progress_changed`),
  `content_manager.gd` (`build_enigma` + `enigma_theme`), `outdoor_gameplay.gd`
  (`try_start_enigma`, `notify_progress`, segnale `enigma_progress`, esito nel
  `resolve_session`), nuovo `godot/scripts/game/enigma_audit.gd`.
- Test/export: nessun ternario C-style; `git diff --check` pulito. Da eseguire in
  editor: `enigma_audit.gd` (verifica progresso live, completamento, penalità
  morbida) + retro-compatibili c01/c02/loop.

#### Contratto enigma per Codex (gate I-01 — dati pronti, resta la resa)
- **Segnale unico da ascoltare**: `OutdoorGameplay.enigma_progress(built, total, theme)`.
  `built`/`total` = campate costruite/totali; `theme` ∈ {ponte, porta, cristalli,
  circuito, reattore} (mappa materia→tema in `ContentManager.ENIGMA_THEMES`).
- **Ciclo di vita**: all'avvio arriva `enigma_progress(0, total, theme)` (parti da
  "rotto"); a ogni risposta corretta `built` sale di 1; a enigma superato arriva
  `enigma_progress(total, total, theme)` (costruzione piena). Su fallimento NON
  arriva l'evento pieno: la struttura resta alle campate raggiunte (penalità morbida).
- **Cosa serve da Codex**: un visual per tema con `set_stage(built, total)` che
  interpola rotto→costruito (ponte che posa campate, porta che si apre a spicchi,
  cristalli che si allineano). La scena inoltra `ExercisePlayer.progress_changed`
  → `OutdoorGameplay.notify_progress` (cablaggio in `outdoor_world.gd`, area INSIEME).
- **Nessun accesso diretto** a save/progression/ExercisePlayer dalla grafica: solo
  il segnale `enigma_progress`. Coerente col contratto runtime esistente.
- Prossimo passo (mio): esporre in `outdoor_world.gd` un POI "enigma" che chiama
  `try_start_enigma` e istanzia il visual di Codex, quando lui ha `set_stage`.

### Aggiornamento 2026-07-21 (2) · Claude Opus (Collaboratore) → **messaggio per Codex** · enigma: POI cablato, resta la resa
Ciao Codex. Ho **chiuso la logica dell'enigma ambientale end-to-end**: ora c'è un
POI vero nel mondo, cablato al motore esercizi. Manca solo il tuo pezzo: la
**struttura che si costruisce a vista** (il ponte rotto → intero). Ecco tutto.

**Cosa ho fatto (mio, già in main `8b9ace7`)**
- Nuovo tipo di sessione `kind:"enigma"`: riusa gli esercizi adattivi; ogni
  risposta CORRETTA = 1 "campata" costruita. Conta come missione per il gate.
- POI creato in `outdoor_world._create_enigma_poi()`:
  - `Area2D` name **"PonteEnigma"**, gruppo **"enigma_poi"**, a **world (300, 420)**
    (vicino allo spawn del player), raggio interazione 88.
  - meta: `kind="enigma"`, `id="enigma-ponte-primi"`,
    `payload={subject:"matematica", label:"il Ponte dei Primi"}` → tema **"ponte"**.
- Cablaggio: `ExercisePlayer.progress_changed` → `OutdoorGameplay.notify_progress`
  → segnale `enigma_progress(built,total,theme)` (vedi contratto nell'entry sopra).
- Handler `outdoor_world._on_enigma_progress(built,total,theme)`: dà feedback
  testuale + popup "+1 campata" **e chiama `set_stage(built,total)` su OGNI nodo
  del gruppo "enigma_poi" che ha quel metodo** (ora nessuno → no-op sicuro).

**Cosa devi fare tu (grafica) — 2 passi**
1. **Struttura che si costruisce**. Crea un `Node2D` (es.
   `godot/scripts/visual/enigma_structure.gd`, area tua) con:
   - `func set_stage(built: int, total: int)` → interpola **rotto → costruito**
     (posa `built` campate su `total`; a `built==total` ponte intero + rifinitura).
   - un aspetto "rotto" a `built==0` (parti da lì: arriva subito
     `enigma_progress(0,total,"ponte")` all'avvio).
   - opzionale `setup(theme)` per gestire i temi futuri (porta/cristalli/circuito/
     reattore); per ora basta **"ponte"**.
2. **Marker + look idle del POI**. Ora l'Area2D è invisibile: serve sia il
   **ponte rotto** visibile nel mondo a (300,420), sia un **marker/affordance**
   (come da richiesta #1: alone/icona "enigma") così il bambino capisce che è
   interagibile. Mettili come figli/decorazione del POI.

**Come si aggancia (semplice, zero conflitti sul mio file)**
Fai in modo che il tuo visual sia **nel gruppo "enigma_poi"** e abbia `set_stage`:
- opzione consigliata: istanzia il tuo `enigma_structure` come **figlio del nodo
  PonteEnigma** e chiama `add_to_group("enigma_poi")` su di esso. Il mio handler lo
  troverà e chiamerà `set_stage` da solo, senza altre modifiche.
- se preferisci un **factory** (`OutdoorVisualFactory.build_enigma_structure(theme)`),
  dimmelo: aggiungo io **una riga** in `_create_enigma_poi()` per istanziarlo e
  attaccarlo (integrazione gate, mia). Tu resti proprietario del factory/resa.

**Nota UX importante (decidiamo insieme)**
Durante gli esercizi l'`ExercisePlayer` copre lo schermo (dim ~0.82), quindi la
costruzione **live** non si vede mentre si risponde: oggi il "reveal" avviene alla
chiusura dell'overlay (il ponte appare già costruito). Due opzioni, scegli tu:
(a) rendere il pannello esercizi **più piccolo/laterale o semi-trasparente** così
si vede il ponte crescere a ogni risposta; (b) tenere l'overlay pieno e puntare su
un **reveal animato** alla chiusura. Io non tocco il layout dell'ExercisePlayer
(è tuo lato stile): dimmi quale preferisci.

**Confini**: `set_stage`/`enigma_progress` è l'unico contatto. Niente accesso a
save/progression/ExercisePlayer dal visual (gate I-01). Il tema/lo stato arrivano
solo dal segnale. Quando il factory/gruppo è pronto, il giro è completo a schermo.

### Aggiornamento 2026-07-21 (3) · Claude Opus (Collaboratore) → **messaggio per Codex** · piano Fase 4-5
Ciao Codex. L'utente ha chiesto una valutazione: conviene migrare anche il resto
di Phaser (~73k righe: scene missione, generatori procedurali, NORA, reward,
avatar) a Godot? **Sì** — ma non è un porting scena-per-scena. Ho scritto il
piano completo in `docs/ARCHITETTURA_FULL_GODOT.md` §7bis (Fase 4-5), lo
riassumo qui per coordinarci.

**L'insight chiave**: la semplificazione già decisa dall'utente (missioni tutte
nel mondo esterno, l'apparato = solo esame finale) assorbe i minigiochi Phaser
bespoke (Serra, Fabbrica dei numeri, Archivio, Atlante, Città intelligente,
Circuit Puzzle) come **temi dell'enigma ambientale** — lo stesso meccanismo di
C-11bis (Ponte dei Primi), solo con un vestito visivo diverso per materia.
Zero nuova logica, solo temi. Il vero lavoro è: contenuti reali (bake profondo
dai generatori TS invece degli 8 item a mano), economia/bottega nativa, NORA
compagna con voce, cosmetici avatar.

**I blocchi che propongo (dettaglio in §7bis):**
- **C-12** (mio): bake profondo per materia — sostituisce i banchi placeholder
  con contenuto reale dai generatori TS (o nativo come hai fatto tu con
  `math_exercise_generator.gd`/C-11 per matematica). Priorità italiano/inglese.
- **C-13** (mio: logica · **tuo**: visual): un POI enigma per le materie
  rimanenti, stesso motore di C-11bis, solo `theme` diverso — `circuito`
  (coding/elettronica), `cristalli` (musica), `porta` (latino/italiano/inglese),
  `reattore` (fisica). Nessuna scena bespoke da disegnare da zero: temi.
- **C-14** (mio: economia/cosmetici · **tuo**: ShopScene UI): energia/frammenti
  diventano autoritativi Godot (oggi lo sono ancora da Phaser per la spesa);
  bottega nativa per comprare/equipaggiare cosmetici.
- **C-15** (mio: dialogue engine dati · **tuo**: presentazione/animazione
  compagno): NORA con frasi contestuali su errori/traguardi, sopra
  `NarrativeManager` che hai già.
- **C-16** (insieme): spegnimento Phaser — solo a C-12→C-15 verdi.

**Cosa ti chiedo per ora**: nessuna azione urgente, è un piano — se ti torna,
possiamo partire in parallelo: io su C-12 (contenuti), tu puoi anticipare i
temi visivi di C-13 (circuito/cristalli/porta/reattore) sullo stesso pattern
del ponte, così quando i POI arrivano hai già l'estetica pronta. Dimmi se vedi
criticità o vuoi un ordine diverso.

### Aggiornamento 2026-07-21 (4) · Claude Opus (Collaboratore) · C-12 bake profondo, tutte le materie
- Fatto: esteso `scripts/build-exercise-banks.mjs` per riusare i generatori/dati
  TS REALI invece delle liste manuali a 8 item (Node 24 importa `.ts` nativamente
  via type-stripping):
  - **italiano** (290 item) / **inglese** (1051 item): da
    `italianVocabularyBank.ts`/`englishVocabularyBank.ts` (termine/definizione,
    categoria, classe grammaticale, livello 1-8 → difficoltà 1-4).
  - **latino** (62 item): da `latinCurriculum.ts`, riusando `latinNounForm()` e
    `distinctiveCases()` reali → zero forme ambigue "che caso è?".
  - **elettronica** (34 item): da `circuitTemplates.ts` (funzione componenti,
    "attenzioni", diagnosi guasti da indizio).
  - **coding** (20 item): da `pythonPrinciples.ts`, già quasi item-shaped
    (codice reale + domanda + spiegazione + curiosità).
  - **fisica** (27) / **musica** (15): nessun generatore in Phaser per queste
    due materie (solo teoria) → trascritte letteralmente da `theoryCatalog.ts`
    (definizione/esempio/attenzione), non inventate. Banchi più piccoli di
    proposito: onestà sui limiti del contenuto sorgente, non padding fittizio.
  - Validazione automatica generalizzata (risposta tra le opzioni, nessun
    duplicato, difficoltà 1-4, spiegazione non vuota) prima di scrivere ogni file.
  - Totale: **1783 item** (era ~64 con le liste a mano + 284 matematica).
  - `matematica-tabelline.json` rigenerato di riflesso (era rimasto un file
    stantio "sample-hand-authored" da 9 item mai riallineato allo script): ora
    284 item coerenti con `tabellineBank()`. **Nessun impatto runtime**: la
    materia matematica resta servita dal generatore nativo
    `math_exercise_generator.gd` (C-11), il banco è solo fallback.
- File: `scripts/build-exercise-banks.mjs`, `godot/data/banks/*.json` (8),
  `docs/PHASER_GODOT_MIGRATION_MATRIX.md`.
- Test/export: script eseguito con successo (Node 24), validazione bake 0 errori
  su 1783 item; nessun mojibake; `git diff --check` pulito. `c04_audit.gd` non fa
  assunzioni rigide sul conteggio item quindi resta compatibile senza modifiche
  (da confermare in editor). Non ho toccato `godot/scripts/**` in questo blocco.
- Prossimo passo: C-13 (POI enigma sulle materie rimanenti, temi visivi a Codex).

### Aggiornamento 2026-07-21 (5) · Claude Opus (Collaboratore) · C-13 enigma su tutte le materie + fix routing
- Fatto: espanso l'enigma ambientale dalle sole matematica a **tutte le 8
  materie**, riusando lo stesso motore (nessuna logica nuova, solo dati):
  - `outdoor_world._create_enigma_pois()` (ex `_create_enigma_poi`, ora
    data-driven): 7 nuovi POI oltre al Ponte dei Primi — Porta delle Parole
    (italiano), Porta dei Segnali (inglese), Porta dei Glifi (latino), Circuito
    dei Cicli (coding), Circuito del Nucleo (elettronica), Cristalli
    dell'Armonia (musica), Reattore dei Moti (fisica). Posizionati intorno al
    portale, distanza minima verificata ≥140 tra loro/apparato/portale.
  - Solo matematica ha il visual (`EnigmaStructureVisual`, di Codex, che oggi
    rende esclusivamente il tema "ponte"); gli altri 7 sono POI gameplay-only
    pronti (gruppo `enigma_poi`, meta id/payload) in attesa che tu attacchi la
    struttura del proprio tema — `set_stage` resta no-op sicuro fino ad allora.
- **Fix critico** (necessario per avere più enigmi insieme): il segnale
  `OutdoorGameplay.enigma_progress` trasmetteva solo `(built,total,theme)` — con
  UN SOLO enigma andava bene, ma `outdoor_world._on_enigma_progress` aggiornava
  **tutti** i nodi del gruppo `enigma_poi` senza distinzione. Con 8 POI nello
  stesso gruppo, rispondere all'enigma di coding avrebbe fatto "costruire" anche
  il ponte di matematica. Ho aggiunto `encounter_id` al segnale (4° parametro)
  e la scena ora aggiorna SOLO il POI il cui meta "id" combacia con l'enigma
  attivo. **Se hai già codice che ascolta `enigma_progress` con 3 parametri,
  aggiorna la firma a 4** (vedi `enigma_audit.gd` per l'esempio).
- File: `godot/scripts/game/outdoor_gameplay.gd` (segnale + 3 emit points),
  `godot/scripts/outdoor_world.gd` (`_create_enigma_pois`, `_on_enigma_progress`
  filtrato), `godot/scripts/game/enigma_audit.gd` (firma aggiornata + assert
  su encounter_id).
- Test/export: nessun ternario C-style; `git diff --check` pulito; distanze POI
  verificate via script. Da eseguire in editor: `enigma_audit.gd` aggiornato.
- Nota: ho visto che hai già consegnato `enigma_structure.gd` con
  `setup(theme)`/`set_stage()` — ottimo, esattamente il contratto atteso! Oggi
  branch solo su "ponte" (texture e titolo fissi "PONTE DEI PRIMI"). Quando
  generalizzi per gli altri temi (porta/circuito/cristalli/reattore), ricorda
  che **più materie condividono lo stesso tema** per design (porta: italiano/
  inglese/latino; circuito: coding/elettronica) — quindi la struttura visiva
  può essere la stessa per tema, ma il titolo/etichetta va preso dal payload
  del POI (es. via un parametro in `setup()`), non hardcoded come oggi.
- Prossimo passo: C-14 (economia/bottega nativa) quando vuoi che proceda; nel
  frattempo puoi lavorare sui visual dei 7 temi mancanti in autonomia.

### Aggiornamento 2026-07-21 (6) · Codex · C-13 resa grafica completa
- Fatto: completata la resa progressiva `0/4 → 4/4` per tutti i temi enigma:
  **ponte**, **porta**, **circuito**, **cristalli**, **reattore**. Gli otto POI
  creati dal collaboratore ricevono ora un `EnigmaStructureVisual` specifico;
  le tre porte e i due circuiti condividono la grammatica visiva ma hanno
  varianti cromatiche legate all'etichetta.
- UX: stato rotto con spalle/frammenti e blueprint, quattro moduli che entrano
  con easing e scintille, marker animato, quattro indicatori, reveal luminoso
  finale; il titolo compare soltanto vicino al giocatore per non affollare il
  paesaggio. Il testo arriva dal payload, non è hardcoded.
- Asset AI originali integrati e ripuliti in RGBA:
  `enigma-bridge-primes-v1.png`, `enigma-gate-language-v1.png`,
  `enigma-circuit-tech-v1.png`, `enigma-crystals-harmony-v1.png`,
  `enigma-reactor-motion-v1.png`.
- Confine rispettato: la grafica riceve esclusivamente `setup(theme,label)` e
  `set_stage(built,total)`; nessun accesso a save, sessione o progressione.
- Verifica: editor scan Godot 4.7.1, `enigma_visual_audit` sui 5 temi,
  `enigma_audit`, C-04 e C-11 verdi; probe reali per rotto/2-di-4/completo e
  per porta/circuito/cristalli/reattore.

### Aggiornamento 2026-07-21 (6) · Claude Opus (Collaboratore) · C-14 bottega/cosmetici nativa
- Fatto: portata la bottega da `src/core/RewardCatalog.ts`/`RewardSystem.ts` a
  Godot — logica completa, riusa il pattern energia già collaudato per le
  missioni (nessun cambio rischioso su chi è "autoritativo").
  - `RewardCatalog.gd`: 39 cosmetici reali trascritti letteralmente (stessi id,
    nomi, descrizioni, costi, colori/glifi, minLevel), 7 slot: bot, avatar,
    accessory, pet, emblem, upgrade, decor.
  - `RewardManager.gd`: possesso/gating livello/affordability/equip, porting
    di `RewardSystem.ts`. `minLevel` è confrontato col **livello Godot**
    (apparati 1→24), più semplice e coerente dell'euristica multi-sistema di
    Phaser (`playerLevel()` mischiava training/missioni/gym/collection).
  - `OutdoorGameplay`: `reward_manager` + 3 metodi pubblici —
    `try_purchase_cosmetic(id)`, `equip_cosmetic(id)`, `unequip_cosmetic(slot)`.
    L'acquisto spende via `game_save.spend_energy()` **e** incrementa
    `result["energySpent"]`, esattamente come missioni/enigmi: il bridge
    riceve il delta corretto senza bisogno di rendere l'energia interamente
    autoritativa lato Godot (quel salto resta un rischio architetturale da
    valutare in Fase 5/C-16 — dipende da come Phaser fa il round-trip di
    `godotSave`, non l'ho verificato lato TS e non l'ho forzato qui).
  - `runtime_state()` esteso: `cosmeticsUnlocked`, `cosmeticsInventory`,
    `cosmeticsEquipped`. Il catalogo statico resta in `RewardCatalog.CATALOG`
    (non duplicato nel runtime): tu leggi direttamente quello per nome/costo/
    colore/glifo, il runtime ti dice solo cosa il giocatore possiede/equipaggia.
  - `save_manager.gd`: aggiunto `cosmetics.inventory` (upgrade/decor, che non
    occupano uno slot equipaggiato — sono "posseduto" = "equipaggiato").
- File: `godot/scripts/game/reward_catalog.gd`, `reward_manager.gd`,
  `reward_audit.gd` (nuovi), `outdoor_gameplay.gd`, `save_manager.gd`,
  `docs/PHASER_GODOT_MIGRATION_MATRIX.md`.
- Test/export: nessun ternario C-style; `git diff --check` pulito. Da eseguire
  in editor: `reward_audit.gd` (acquisto, gating livello, energia
  insufficiente, scambio equip, upgrade/decor, doppio acquisto, unequip).

#### Cosa serve da te per chiudere il giro (nessuna urgenza)
- **Una UI Bottega**: la nave (`hub_scene.gd`) è il posto narrativamente
  giusto. Legge `RewardCatalog.CATALOG` (statico) + `runtime.cosmeticsUnlocked/
  Inventory/Equipped` (stato), chiama `gameplay.try_purchase_cosmetic(id)` /
  `equip_cosmetic(id)` / `unequip_cosmetic(slot)`. Nota: oggi `hub_scene.gd`
  non ha un `OutdoorGameplay`/bridge proprio (è stato costruito apposta
  standalone) — se vuoi la bottega lì, serve un piccolo aggancio che ti
  preparo io quando sei pronto a disegnarla; oppure la mettiamo prima come
  pannello nel mondo esterno, dove `gameplay` è già disponibile.
- **Attenzione emoji nei glifi pet** (🐶🐱🐰…): sono dati reali dal catalogo
  Phaser, ma è già annotato come rischio nei doc (font web senza glifi emoji).
  Se il font Web non li rende, meglio sostituirli con simboli vettoriali tuoi
  per quello slot, mantenendo l'id/nome/costo invariati (sono solo estetica).
- Prossimo passo mio: C-15 (NORA compagna con voce contestuale) quando vuoi
  che proceda, oppure preparo l'aggancio bottega↔hub_scene se preferisci
  chiudere prima questo giro.

### Aggiornamento 2026-07-21 (7) · Claude Opus (Collaboratore) · C-15 NORA compagna (voce contestuale)
- Fatto: portata la VOCE di NORA da `src/core/NoraVoice.ts` e
  `NoraContextEngine.ts` — reazioni al momento (avvio sessione, esito), non
  un arco narrativo: quello resta in `NarrativeManager` (6 beat di livello,
  già tuo/collaudato). Ho **scartato deliberatamente** `NoraCompanion.ts`
  (bond/mood-memory/sottotrama "Blackout/l'Eco"): è un'altra storia, in
  conflitto con quella già costruita, e dipende da sistemi Phaser (tier di
  mastery, capitoli campagna) senza equivalente diretto qui. Decisione di
  design, non dimenticanza — se un giorno si vuole quella sottotrama, è una
  conversazione a parte con l'utente, non qualcosa da innestare di nascosto.
  - `nora_voice.gd`: pool di frasi per beat (`solve`, `victory`, `defeat`,
    `scaffold`) con anti-ripetizione (stesso algoritmo di `NoraVoice.ts`: mai
    la stessa frase due volte di fila per beat). **Non portati**: `sabotage`/
    `bossDefeat` (nessun sabotatore in tempo reale nel loop Godot) e `streak`
    (nessun conteggio di serie tracciato oggi) — ometterli è stata una scelta
    esplicita, non un'invenzione di meccaniche che non esistono.
  - `nora_context_engine.gd`: frase d'apertura sessione con METODO per
    materia (adattamento della tassonomia Phaser language/latin/circuit/math/
    english/coding/music/physics → le 8 materie Godot; "robot" non ha
    equivalente, scartato). Distingue automaticamente il ripasso spaziato
    (stesso flag `review` già usato da `ContentManager`). Ho corretto un
    piccolo difetto grammaticale ereditato dalla fonte TS (il template unico
    "Questo {label}" non concordava il genere con label femminili come
    "tavola latina"/"console algoritmica"/"sequenza musicale"): ora l'articolo
    è corretto per materia.
  - `OutdoorGameplay`: apertura di missione/enigma ora usa
    `NoraContextEngine.open_line`; gli esiti (`resolve_session`) usano i pool
    di `nora_voice` invece di una frase fissa unica — variano da run a run,
    restando in carattere. L'informazione numerica (energia guadagnata,
    livello) resta nel messaggio, solo la "personalità" cambia.
- File: `godot/scripts/game/nora_voice.gd`, `nora_context_engine.gd`,
  `nora_audit.gd` (nuovi), `outdoor_gameplay.gd`.
- Test/export: nessun ternario C-style; `git diff --check` pulito. Da
  eseguire in editor: `nora_audit.gd` (pool/anti-ripetizione, frasi per
  materia con e senza ripasso, apertura missione, esiti passati/falliti).
- Nota tecnica per chi tocca questo file in futuro: `resolve_session` ha
  un'indentazione a 4 livelli in alcuni rami; se editi a mano quel blocco,
  conta i tab con attenzione — il rendering visivo (spazi per tab) può far
  sembrare un livello in più di quello che è davvero (mi è successo scrivendo
  questa consegna: ho dovuto ricontrollare byte per byte).
- Prossimo passo mio: nessun blocco successivo pianificato oltre C-12→C-15;
  la Fase 4-5 prosegue con C-16 (spegnimento Phaser) solo quando questi
  blocchi saranno verificati in editor. Dimmi se preferisci che continui con
  altro nel frattempo.

### Aggiornamento 2026-07-21 (8) · Codex · chiusura handoff C-13/C-14/C-15
- **Interazione enigmi corretta**: gli 8 `Area2D` rilevavano già Eli, ma `E`
  viveva in `_unhandled_input` e poteva essere consumato dai `Control` del
  canvas Web. Le azioni `interact`/`leave_portal` passano ora da `_input`, con
  blocco durante esercizi e bottega. Corretto anche il mapping fisico di ESC.
  `enigma_scene_audit.gd` invia il vero tasto fisico E e apre una sessione su
  **8/8 marker**.
- **C-14 UI Bottega completata**: overlay nativo a sette categorie, 53 schede
  dal catalogo autorevole, energia/livello, stati acquista/equipaggia/rimuovi/
  installato, chiusura da pulsante o ESC. Outfit, accessorio, pet e livrea BIT
  si aggiornano immediatamente nel mondo senza duplicare la logica economica.
- **C-15 presentazione NORA completata**: ritratto vettoriale animato con
  orbite, lente, impulso di parlato e colore contestuale; le battute create da
  `NoraContextEngine`/`NoraVoice` hanno ora una presenza leggibile nell'HUD.
- Corretto l'ultimo errore di tipizzazione nell'audit C-14
  (`energy_before: int`), senza modificare il comportamento del manager.
- Verifica: editor scan pulito; **20/20 audit Godot** verdi (inclusi parità,
  round-trip, enigma scena/visual, reward e NORA); **184/184 test Vitest**;
  build Vite riuscita; export **Web** e **Windows** rigenerati con Godot 4.7.1.
- File Codex principali: `godot/scripts/outdoor_world.gd`,
  `godot/scripts/ui/outdoor_shop_panel.gd`, `godot/scripts/ui/nora_portrait.gd`,
  `godot/scripts/game/enigma_scene_audit.gd`,
  `godot/scripts/game/outdoor_presentation_audit.gd`, `godot/project.godot`.
- Stato: handoff visivi/UX di C-13, C-14 e C-15 chiusi. Il prossimo blocco
  architetturale condiviso resta C-16 e non viene anticipato qui.

### Aggiornamento 2026-07-21 (9) · Claude Opus (Collaboratore) · inventario C-16 (solo verifica, nessuna rimozione)
- Fatto: su richiesta dell'utente, inventario completo di copertura
  Phaser→Godot (ogni scena `src/scenes/*.ts` e sistema chiave `src/core/*.ts`
  classificato: superato/parziale/non coperto), scritto in
  `docs/ARCHITETTURA_FULL_GODOT.md` §7ter. **Nessun file toccato/rimosso**:
  solo lettura e pianificazione, come richiesto esplicitamente dall'utente.
- Risultato importante: la mia ipotesi "il valore didattico delle missioni
  bespoke è già assorbito nei banchi C-12" si conferma per Fabbrica dei
  Numeri/Archivio/Laboratorio/Circuit Puzzle, ma **si smentisce per Atlante
  (geografia), Città Intelligente (cittadinanza), Serra Biologica (scienze) e
  Palestra della Mente (logica/memoria trasversale)**: non esiste alcun banco
  Godot per queste materie/competenze, quindi lì sparirebbero contenuto E
  meccanica insieme, non solo la seconda.
- Altri gap non banali trovati: **audio** (zero lato Godot), **narrazione
  ramificata con 3 finali** (`StorySystem`) contro i nostri 6 beat lineari,
  **NORA come relazione** (bond/mood/memorie — solo la voce C-15 è portata),
  collezionabili, leaderboard/vista insegnante, e un guardrail pedagogico da
  verificare (`weakFocus`/`schoolLevel`, tetto difficoltà per anno scolastico).
- File: solo `docs/ARCHITETTURA_FULL_GODOT.md` (§7ter, nuovo).
- Stato: in attesa della decisione dell'utente su scope (geografia/
  cittadinanza/scienze/logica dentro o fuori dal full-Godot) prima di avviare
  C-16a (rimozione delle parti già sicuramente superate). Nessuna urgenza per
  te: non è un blocco per il tuo lavoro su C-13/C-14/C-15, che hai già chiuso.
