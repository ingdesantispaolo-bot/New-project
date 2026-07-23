# Architettura & Migrazione a Full Godot

> **Snapshot 22 luglio 2026:** il target descritto qui è ora il runtime di
> produzione. Boot, mondo, esercizi, bottega, nave, NORA, report, audio e save
> sono Godot; `OutdoorSaveBridge` è stato rimosso e l'export Web 4.7.1 parte
> direttamente dalla main scene nativa. Le sezioni storiche sotto restano come
> motivazione e cronologia del percorso.

> Come si costruisce il gioco descritto in [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md),
> con l'obiettivo confermato in [VISIONE_DI_GIOCO.md](VISIONE_DI_GIOCO.md): **un
> unico motore Godot**, niente Phaser, niente bridge, niente ricariche di pagina.
> Principio guida: **migrazione incrementale, sempre spedibile** — mai un mese "al
> buio".

Indice:
1. [Stato attuale](#1-stato-attuale)
2. [Architettura target (full Godot)](#2-architettura-target-full-godot)
3. [Il grande nodo: i contenuti](#3-il-grande-nodo-i-contenuti)
4. [Save e migrazione dei progressi](#4-save-e-migrazione-dei-progressi)
5. [Struttura del progetto Godot](#5-struttura-del-progetto-godot)
6. [Contratti dati](#6-contratti-dati)
7. [Piano a fasi con criteri d'uscita](#7-piano-a-fasi-con-criteri-duscita)
8. [Build e deploy](#8-build-e-deploy)
9. [Rischi e mitigazioni](#9-rischi-e-mitigazioni)

---

## 1. Stato attuale

- **Phaser = cervello**: tutte le scene di gioco, i **generatori procedurali**
  (matematica, inglese, italiano, coding, …) con **solver/validatori**, il
  **save** (localStorage), reward/mastery/campagna, hub-stanze, bottega, prove
  NORA. È la parte più grande e preziosa (i generatori sono i "gioielli").
- **Godot = corpo**: mondo esterno procedurale (rendering, streaming, biomi,
  giorno/notte), **generatore a parità** col TS, cosmetici/pet/HUD economia.
- **Bridge**: JSON via `JavaScriptBridge`/localStorage con **round-trip a
  ricarica di pagina** (difetto principale da eliminare).
- **Deploy**: Vite → GitHub Pages (Phaser) + export Godot Web in
  `public/godot/outdoor/`.

## 2. Architettura target (full Godot)

Un solo progetto Godot che contiene **mondo + narrazione + esercizi + save +
economia + UI**. Niente Phaser, niente bridge.

```
┌──────────────────────── Godot (unico motore) ────────────────────────┐
│  Autoload (singleton, sempre attivi)                                  │
│   SaveManager · EconomyManager · MasteryManager · ContentManager      │
│   NarrativeManager · ProgressionManager · AudioManager · Settings     │
│   WorldProfileCatalog · MissionEventDirector · KnowledgeCodex         │
│                                                                       │
│  Scene principali                                                     │
│   BootScene → HubScene (Relitto) ⇄ WorldScene (mondo esterno)         │
│   ExercisePlayer (motore esercizi data-driven, condiviso da tutti)    │
│   ShopScene · SkillTreeScene · CodexScene · ReportScene               │
│                                                                       │
│  Contenuti                                                            │
│   Banchi di esercizi (JSON, caricati on-demand) + generatori GDScript │
└───────────────────────────────────────────────────────────────────────┘
```

Vantaggi: esperienza **senza cuciture** (l'esercizio si apre *dentro* il mondo,
non ricarica la pagina), un solo save, un solo deploy, un solo linguaggio.

L'espansione AAA-didattica usa una sola `WorldScene`, configurata da 24
`WorldProfile` sbloccabili. Il profilo controlla identità visuale, composizione,
audio, missioni, eventi e ingresso nave autorato; non si duplicano 24 scene
monolitiche. Il motore esercizi espone renderer/interazioni specializzate e il
`KnowledgeCodex` fornisce le spiegazioni di NORA. Piano operativo e criteri in
[PIANO_EVOLUZIONE_AAA_DIDATTICO.md](PIANO_EVOLUZIONE_AAA_DIDATTICO.md).

## 3. Il grande nodo: i contenuti

I generatori procedurali TS (con validatori/solver) sono il valore più alto e la
parte più costosa da portare. **Strategia ibrida** per arrivare a full-Godot
senza riscrivere tutto in una volta:

### 3a. Bake dei banchi (via veloce, subito)
Uno **script Node offline** (riusa i generatori TS esistenti + i validatori) che
produce **grandi banchi di esercizi in JSON**, per materia e per livello di
difficoltà, già verificati e con spiegazioni.

- Godot li carica **on-demand** (fetch del solo banco necessario, non tutto nel
  `.pck`) e li seleziona con logica adattiva (mastery, ripasso spaziato).
- Vantaggio: nessun porting dei generatori per partire; qualità garantita dai
  validatori esistenti; contenuto enorme (decine di migliaia di item) ma finito.
- Aggiornabile a ogni build. Il seed/anti-ripetizione vive in Godot.

### 3b. Porting dei generatori prioritari (via completa, nel tempo)
Per le materie a più alto volume/valore, si porta il generatore in **GDScript**
per **varietà runtime infinita** (come già fatto per il mondo esterno, con
fixture di parità). Si inizia dai più semplici e usati (tabelline, calcolo
mentale) e si procede per priorità.

> Regola: **bake prima, port poi**. Ogni materia diventa "nativa Godot" quando il
> suo generatore è portato; fino ad allora usa il banco. In entrambi i casi il
> giocatore vede la stessa cosa: il motore `ExercisePlayer` è data-driven.

### 3c. Motore esercizi data-driven
Un unico `ExercisePlayer` in Godot che **renderizza un `ExerciseItem`** (schema
in §6) qualunque sia la materia o la fonte (banco o generatore). Aggiungere una
materia = fornire item conformi, **non** una nuova UI.

## 4. Save e migrazione dei progressi

**Obiettivo: nessuno studente perde i progressi nel passaggio.**

- **Schema canonico** definito in Godot (`SaveManager`), versionato.
- **Web**: Godot e Phaser condividono lo stesso `localStorage` (stessa origine).
  In transizione, `SaveManager` può **importare una volta** le chiavi del save
  Phaser esistente (via `JavaScriptBridge`) e convertirle nello schema canonico.
- **Desktop**: file `user://` (già usato dal bridge attuale).
- **Migrazione**: funzione `migrate_from_phaser()` idempotente, eseguita al primo
  avvio full-Godot; poi il save Godot diventa l'unica fonte di verità.

## 5. Struttura del progetto Godot

Autoload (singleton):
| Manager | Responsabilità |
|---|---|
| `SaveManager` | schema canonico, load/save, migrazione, versioning |
| `EconomyManager` | energia, frammenti, fonti/sink, combo, moltiplicatori |
| `MasteryManager` | padronanza per materia, materia più debole, ripasso spaziato |
| `ProgressionManager` | livello 1→20+, avanzamento per **riparazione apparati**, gate (mastery + conteggio missioni per materia), slot moduli |
| `ContentManager` | carica banchi on-demand + generatori GDScript; seleziona item adattivi |
| `NarrativeManager` | capitoli, beat, dialoghi NORA, frammenti, side-quest |
| `AudioManager` | musica/effetti (sostituisce howler) |
| `SettingsManager` | accessibilità, effetti ridotti, lingua |

Scene:
- `BootScene` → `HubScene` (Relitto: bottega, skill tree, NORA, mappa) ⇄
  `WorldScene` (mondo esterno, già esistente e ricco).
- `ExercisePlayer` (overlay/scene condivisa): riceve un `ExerciseSession` (lista
  di `ExerciseItem`) e gestisce presentazione, risposta, feedback, ricompense.
- `ShopScene`, `SkillTreeScene`, `CodexScene`, `ReportScene`.

I POI del mondo (percorsi didattici, prove NORA, enigmi) **aprono
`ExercisePlayer` in-scena** — niente ricarica, niente bridge.

## 6. Contratti dati

### ExerciseItem (l'unità di contenuto)
```json
{
  "id": "math-times-000123",
  "subject": "matematica",
  "topic": "tabelline",
  "difficulty": 2,
  "format": "multiple_choice",
  "prompt": "Quanto fa 7 × 8?",
  "options": ["54", "56", "63", "49"],
  "answer": "56",
  "explanation": "7 × 8 = 56. Puoi pensarlo come 7 × 8 = 7 × 10 − 7 × 2.",
  "assets": {}
}
```
`format` ∈ { multiple_choice, numeric_input, text_input, ordering, matching,
true_false, chart_read, mini_debug, … }. Il motore rende ogni formato.

### ExerciseSession (una missione esterna o un esercizio finale)
```json
{
  "sessionId": "mission-math-lvl3-00042",
  "kind": "mission",                 // "mission" (fuori) | "final_exam" (apparato)
  "subject": "coding",
  "level": 3,                        // taratura sul livello del giocatore
  "nodes": ["coding-seq-01", "coding-loop-03", "coding-debug-07"],
  "shields": 3,                      // scudi: gli errori li consumano
  "rewards": { "energyPerCorrect": 10, "onComplete": { "energy": 60, "fragments": 4 } }
}
```
- `kind: "mission"` — allenamento nel mondo esterno, tarato su `level`, conta nel
  `missionsBySubject` del livello.
- `kind: "final_exam"` — la **riparazione dell'apparato** nella nave: cumulativo,
  più severo, sbloccato solo quando i gate sono soddisfatti.

### Save (schema canonico, estratto)
```json
{
  "schemaVersion": 1,
  "playerId": "local",
  "level": 1,
  "energy": 0, "fragments": 0,
  "mastery": { "matematica": 0.0, "coding": 0.0 },
  "missionsBySubject": { "matematica": 0, "coding": 0 },
  "apparatus": { "nucleo": { "repairedLevel": 0 }, "data-core": { "repairedLevel": 0 } },
  "spacedRepetition": { "matematica:tabelline": { "due": 3, "lapses": 1 } },
  "modules": { "owned": [], "equipped": [] },
  "cosmetics": { "unlocked": [], "equipped": {} },
  "narrative": { "beatsSeen": [], "fragments": [] },
  "outdoor": { "collectedTreasureIds": [] },
  "daily": { "date": "YYYY-MM-DD", "streak": 1, "objectives": [] }
}
```
- `level`: spina dorsale (1→20+); tara la difficoltà delle missioni esterne.
- `missionsBySubject`: conteggio missioni superate per materia **al livello
  corrente** (gate per l'esercizio finale; azzerato al salire di livello).
- `apparatus.<id>.repairedLevel`: fino a quale livello quell'apparato è riparato.
- Avanzamento: riparato l'apparato del livello → `level++`, la nave si accende.

Il banco di esercizi è **separato** dal save (contenuto vs stato del giocatore).

## 7. Piano a fasi con criteri d'uscita

Ogni fase è **giocabile e pubblicabile**. Non si passa alla successiva finché i
criteri d'uscita non sono verdi.

### Fase 0 — Preparazione (fondamenta condivise)
- `SaveManager` canonico in Godot + `migrate_from_phaser()`.
- `ExercisePlayer` data-driven con 2–3 formati (multiple_choice, numeric_input).
- Script Node di **bake** di un primo banco (es. matematica/tabelline) → JSON.
- **Uscita**: in Godot posso giocare un esercizio da banco, con feedback e
  ricompensa, e il save persiste; i progressi Phaser importati una volta.

### Fase 1 — Il loop base (livello + missioni + un apparato)
- Missioni esterne come `ExerciseSession kind:"mission"` tarate sul `level`;
  conteggio `missionsBySubject` + mastery; **un apparato** riparabile con
  esercizio finale → `level++`.
- Combo di serie, moduli NORA base, compagni funzionali; HUD obiettivo (avviato).
- **Uscita**: giro completo *missioni fuori → gate → ripara apparato → sali di
  livello*, in Godot, per una materia bakata.

### Fase 2 — Tutte le materie + adattività + scala 20+
- Bake dei banchi per **tutte** le materie; apparati e scala di 20+ livelli
  (tabella dati); taratura sul livello; selezione adattiva su mastery + ripasso
  spaziato.
- **Uscita**: la scala completa è percorribile in Godot; Phaser non serve più per
  giocare gli esercizi *bakati*.

### Fase 3 — Narrazione sulla scala
- `NarrativeManager`: NORA che si risveglia a ogni apparato riparato, beat di
  storia, frammenti, archi compagni. La storia **cavalca i livelli** (niente
  capitoli separati).
- **Uscita**: la progressione 1→20+ racconta la storia dei Primi capo a coda.

### Fase 4 — Generatori nativi (varietà infinita) + spegnimento Phaser
- Porting in GDScript dei generatori prioritari (parità con fixture, come per il
  mondo esterno); le altre materie restano su banco.
- Rimozione progressiva delle scene Phaser man mano che ogni funzione è coperta.
- **Uscita**: nessuna dipendenza runtime da Phaser.

### Fase 5 — Full Godot
- Rimozione di Phaser, del bridge e della build Vite di gioco. Un solo export
  Godot Web servito su GitHub Pages alla radice.
- **Uscita**: il repo builda **un solo** artefatto; Phaser cancellato.

## 7bis. Piano operativo Fase 4-5 (blocchi Claude/Codex, luglio 2026)

> Aggiornamento dopo il consuntivo C-01→C-11: il loop base (Fase 0-1), tutte le
> materie a banco (Fase 2 minima), la nave/apparati, la narrazione a 6 beat e la
> telemetria locale sono **migrati e verdi** (vedi `docs/PHASER_GODOT_MIGRATION_MATRIX.md`).
> Codex ha già iniziato la Fase 4 di sua iniziativa: `math_exercise_generator.gd`
> (C-11) genera matematica **nativa** in GDScript (8 complessità, anti-ripetizione,
> ripasso), sostituendo il banco statico per quella materia. L'enigma ambientale
> (C-11bis, ponte dei Primi) è il primo esempio di missione che rende visibile nel
> mondo l'esito dello studio.
>
> **Domanda posta dall'utente**: conviene migrare anche il resto di Phaser?
> **Risposta**: sì, con una precisazione che riduce di molto il lavoro percepito.
>
> Il codice Phaser rimasto (~73k righe: 36k scene, 18k generatori procedurali,
> 11k dati, 8k core: NORA, reward, mastery, avatar, impostazioni) sembra enorme,
> ma **non va portato 1:1**. Due osservazioni chiudono il problema:
>
> 1. **I "gioielli" sono i generatori di contenuto** (mathTemplates,
>    englishTemplates/vocabularyBank, italianVocabularyBank, latinCurriculum,
>    circuitTemplates, pythonPrinciples…), non le scene. Vanno **bakati** (o
>    portati nativi come per matematica) dentro il `ContentManager` esistente:
>    stesso contratto `ExerciseItem`, nessuna nuova UI.
> 2. **Le scene-minigioco bespoke** (Serra biologica, Fabbrica dei numeri,
>    Archivio delle parole, Atlante, Città intelligente, Circuit Puzzle, Logic
>    Gym) **non richiedono un porting scena-per-scena**: la semplificazione già
>    decisa dall'utente (missioni tutte nel mondo esterno, apparato = esame
>    finale) le assorbe come **temi dell'enigma ambientale**, il meccanismo già
>    costruito in C-11bis. "Fabbrica dei numeri" diventa il tema visivo
>    `circuito`/`ingranaggi`, "Serra" diventa un tema `cristalli`/`serra`, ecc.
>    Stessa logica dati-driven, vestito diverso per materia — a costo Codex, non
>    a costo di nuova logica.
>
> Il vero lavoro restante non è "riscrivere 78 scene", è: **profondità dei
> contenuti**, **economia/bottega nativa** (oggi energia/frammenti restano
> autoritativi da Phaser), **compagna NORA con voce contestuale**, **cosmetici
> avatar**, **report/classifica locali** (nessun elemento è remoto: la
> `LeaderboardScene` filtra record locali, si assorbe in `LocalProgressReport`).

### Blocchi proposti (continuano la numerazione C-xx già in uso in `insieme.md`)

| Blocco | Owner | Contenuto | Riusa | Uscita |
|---|---|---|---|---|
| **C-12** | Claude (logica) | Bake profondo per materia: generalizzare lo script di bake per usare i generatori TS reali (o portarli nativi come C-11) invece delle liste manuali a 8 item. Priorità: italiano, inglese → coding, elettronica → fisica, musica, latino. | `ContentManager`, `build-exercise-banks.mjs` | Ogni materia ≥ 80-100 item su 4 fasce di difficoltà, validati (risposta nelle opzioni, spiegazione non vuota) |
| **C-13** | Claude (logica) + Codex (visual per tema) | Un POI enigma per le materie rimanenti, riusando il motore C-11bis: nessuna scena bespoke, solo `theme` diverso (`circuito`→coding/elettronica, `cristalli`→musica, `porta`→latino/italiano/inglese, `reattore`→fisica). | `ContentManager.build_enigma`, `OutdoorGameplay.try_start_enigma`/`enigma_progress` | 8 POI enigma nel mondo, ognuno con audit come `enigma_audit.gd` |
| **C-14** | Claude (logica: economia/cosmetici) + Codex (ShopScene UI) | Economia e Bottega native: `EconomyManager`/`RewardCatalog`/equip cosmetici in GDScript; energia/frammenti diventano autoritativi Godot (rimuove la dipendenza dal bridge per la spesa). | Save canonico esistente (`cosmetics`, `modules`) | Si compra ed equipaggia un cosmetico dentro Godot, senza bridge |
| **C-15** | Claude (dialogue engine data-driven) + Codex (presentazione/animazione compagno) | NORA compagna: port di `NoraVoice`/`NoraCompanion`/`NoraContextEngine` come frasi contestuali agganciate a errori/traguardi, sopra `NarrativeManager` esistente. | `NarrativeManager`, `feedback` signal | NORA reagisce con frasi contestuali dentro Godot (errore, traguardo, ripasso) |
| **C-16** | Claude + Codex insieme | Spegnimento Phaser (Fase 5): solo dopo C-12→C-15 verdi + parità fixture. Rimozione bridge, scene Phaser, build Vite di gioco; un solo export Godot Web servito da Pages. | matrice C-09 | Repo builda un solo artefatto; nessuna dipendenza runtime da Phaser |

Decisioni aperte da confermare con l'utente (non bloccanti, si può default e
correggere dopo): ordine di priorità materie in C-12 (proposto: italiano/inglese
prima perché più giocate); se mantenere `LeaderboardScene` come classifica
locale in C-14/C-15 o eliminarla (il salvataggio non prevede rete, quindi è
comunque solo cosmetica di presentazione).

## 7ter. Inventario di copertura Phaser→Godot e piano di rimozione sicura (C-16, verifica luglio 2026)

> C-12→C-15 sono chiusi e verificati **in editor** (non solo per ispezione):
> 20/20 audit Godot verdi, 184/184 test Vitest, build/export Web e Windows
> rigenerati. Prima di toccare qualunque cosa esecutiva o il deploy Pages
> (l'unica parte di C-16 che è davvero irreversibile/ad alto impatto), è stato
> fatto un inventario completo — file per file, non per assunzione — di cosa
> in `src/` è già superato da Godot e cosa no. **Nessuna rimozione è ancora
> avvenuta**: questo è solo l'inventario e il piano.

### Risultato chiave: l'ipotesi "contenuto assorbito, solo meccanica persa" si conferma parzialmente

Per **Fabbrica dei Numeri, Archivio delle Parole, Laboratorio e Circuit Puzzle**
è vera: il contenuto (matematica/italiano/inglese/elettronica/coding) vive già
nei banchi nativi Godot (C-12), quindi solo la meccanica bespoke (nastri
trasportatori, ispezione oggetti, tester circuito) va persa — accettabile.

**Si smentisce invece per quattro aree**: **Atlante** (geografia), **Città
Intelligente** (cittadinanza/scienze civiche), **Serra Biologica** (scienze),
**Palestra della Mente/LogicGym** (logica e memoria trasversali). Non esiste
alcun banco Godot per queste materie/competenze — gli 8 banchi Godot sono solo
matematica, italiano, inglese, coding, fisica, musica, latino, elettronica. Per
queste quattro aree **sparirebbero sia il contenuto sia la meccanica**, non solo
la seconda.

> **Decisione presa (2026-07-21):** il full-Godot resta sulle **8 materie
> attuali**. Geografia, cittadinanza, scienze e logica/memoria trasversale sono
> **fuori scope**: le scene Atlante, Città Intelligente, Serra Biologica e
> Palestra della Mente (con i sistemi smartCity/greenhouse/atlas/logicGym)
> saranno rimosse insieme a Phaser in C-16, senza essere bakate in banchi
> Godot. Non è un gap da colmare: è una riduzione di scope voluta.

### (a) Superati — sicuri da rimuovere per primi (nessuna decisione prodotto)
Scene: `BootScene`, `HubScene` (il vecchio), `JournalScene`, `RewardShopScene`,
`AvatarEquipmentScene`, `MathLockScene`, `mainMenu/MainMenuNavigation.ts`.
Core: `MapLayoutSystem`, `TiledSceneRenderer`, `PropRenderer`, `AssetPipeline`,
`SceneAssetLoader`, `SceneNavigator`, `GameConfig`, `DialogueSystem`,
`ReadableTextSystem`, `NumberFactorySolver`, `ExerciseVariantSystem` (questi
ultimi due cadono insieme alle scene bespoke associate).
(`RewardShopScene`/`AvatarEquipmentScene`: il catalogo è trascritto letteralmente
in `reward_catalog.gd`; solo la resa di alcuni accessori/pet è più generica —
downgrade estetico minore già accettato in C-14.)

### (b) Parziali — completare qualcosa o accettare consapevolmente il downgrade
- `ProceduralMissionScene` + tutto `procedural/*`: varietà infinita a seed →
  banchi precompilati (~1783 item). Downgrade di varietà già accettato in C-12.
- `MainMenuScene`, `ExplorableRoomScene`: l'esperienza "atrio" (narrazione,
  daily panel, scelta focus) sparisce; il loop sostanziale resta.
- `MasteryScene`, `CompetencyTracker`: dato aggregato (`mastery_of`) presente,
  granularità per sotto-competenza e UI "albero" persi.
- `SettingsScene`, `SettingsSystem`: solo l'accessibilità visiva è coperta
  (`visual_accessibility.gd`); audio/testo/qualità grafica/pressure-mode no.
- `PlayerReportScene`, `TrainingAssessment`: dato grezzo presente
  (`local_progress_report.gd`), sintesi/voto/UI persi.
- `NumberFactoryScene`, `WordArchiveScene`, `LaboratoryScene`,
  `CircuitPuzzleScene`, `RobotCodingScene` (parzialmente): assorbimento
  didattico plausibile nei banchi nativi, meccanica bespoke persa.
- `MathStudyScene`, `NoraKnowledge`, `HintLadder`/`ExplanationBuilder`/
  `MistakeAnalyzer`: teoria sfogliabile e spiegazioni testuali specifiche
  senza equivalente diretto.
- `weakFocus`/`schoolLevel` (tetto di difficoltà per anno scolastico): da
  verificare esplicitamente lato Godot — è un guardrail pedagogico, non solo
  estetico; non va perso silenziosamente.

### (c) Non coperti — richiedono una decisione prodotto
- **Audio**: `AudioManager` — zero suoni/musica lato Godot oggi.
- **Narrazione strutturata**: `StorySystem` (diario + 3 bivi + 3 finali),
  `DiarioScene`, `FinaleScene`, `CampaignScene`, `ProgressionSystem`,
  `CampaignSystem`, `ChapterTrial` — Godot ha solo 6 beat lineari fissi
  (`narrative_manager.gd`), nessuna ramificazione/scelta/epilogo.
- **NORA come relazione**: `NoraCompanion` (bond/mood/memorie), `NoraScene` —
  solo la voce contestuale (C-15) è portata, non il legame.
- **Identità/casa persistente**: `AcademyScene`, `AcademySystem` (ali,
  emblemi, trofei) — la nave Godot è funzionale, non personalizzabile.
- **Collezionabili**: `CollectionScene`, `CollectionSystem` (12 frammenti lore).
- **Meta-progressione sociale/adulta**: `LeaderboardScene`,
  `TeacherDashboardScene`.
- **Minigiochi bespoke senza contenuto assorbito**: `RobotCodingScene`,
  `BossScene` (boss multi-dominio + memoria), `LogicGymScene`+`logicGym/*`.
- **Reference/studio libero**: `CodexScene`.
- **Utility di sistema**: `ViewportSystem` (tablet/orientamento/fullscreen),
  `BackupSystem` (export/import save manuale).

### Piano a fasi per C-16 (nessuna eseguita ancora)
1. **C-16a** (sicura, nessuna decisione prodotto): rimuovere la lista (a).
2. **C-16b**: per ogni voce (b), decidere esplicitamente "accetto il downgrade"
   o "completo prima" (in particolare `weakFocus`/`schoolLevel`: verificare se
   Godot ha già un tetto di difficoltà equivalente prima di accettare la perdita).
3. **C-16c** (decisione prodotto, blocca il resto): audio, narrazione
   ramificata/finali, companion NORA, identità nave, collezionabili,
   leaderboard/teacher dashboard. **Risolto (2026-07-21):**
   geografia/cittadinanza/scienze/logica trasversale = fuori scope, si rimuovono
   con Phaser senza bakare.
4. **Solo dopo 16a-16c risolti**: rimozione di bridge, build Vite di gioco, e
   cambio della pipeline Pages per servire l'export Godot Web alla radice.
   Questo è l'unico passo davvero irreversibile/ad alto impatto di C-16.

## 7quater. Scope ampliato: 12 materie + audio + narrazione + NORA (decisione 2026-07-21 sera)

> L'utente ha **rovesciato** la riduzione di scope di §7ter: geografia,
> cittadinanza, scienze e logica **entrano** in Godot; inoltre vuole audio
> sofisticato, narrazione ampliata e coerente, e la relazione NORA integrata
> nella storia. Il guardrail difficoltà resta **per livello raggiunto, non per
> anno scolastico** (Godot già fa così: `target_difficulty(level)`; il tetto
> `capDifficultyToSchoolYear` di Phaser NON va portato).

### Fatto in questo giro (contenuto delle 4 nuove materie)
- Banchi bakati e collegati: **geografia** (82 item, autorato — capitali/
  continenti/fisica/Italia, fatti mainstream), **scienze** (13 — metodo/materia/
  viventi + derivati dal simulatore serra reale), **cittadinanza** (10 — regole
  civiche di `smartCity.ts` + nucleo di educazione civica), **logica** (22 —
  generatore deterministico di sequenze/esclusioni). Totale gioco: **12 materie,
  1910 item**.
- Collegati in `ContentManager.BANKS`, `ENIGMA_THEMES` (mappa/serra/rete/griglia),
  `NoraContextEngine` (label + metodo per materia). `c04_audit` esteso a 12.
- **"Memoria" (Simon, griglia lampo) NON è entrata**: è meccanica interattiva a
  tempo, non rappresentabile come `ExerciseItem`. Solo la parte "logica" è
  bakabile; la memoria vera richiede un mini-gioco bespoke → decisione a parte.

### Blocchi successivi (design/asset, richiedono Codex e/o decisioni)
| Blocco | Contenuto | Owner | Nota |
|---|---|---|---|
| **C-17** ✅ | Banchi 4 nuove materie + wiring | Claude | fatto (questo giro); restano da ampliare scienze/cittadinanza (item pochi) |
| **C-18** | **Audio sofisticato**: bus musica/effetti/ambiente, hook sui segnali esistenti (feedback, session, enigma_progress, solve/defeat), musica adattiva per fase giorno/notte e per esito | Claude (logica `AudioManager.gd` + hook) + Codex (asset audio: riusare/rigenerare i WAV di `src/assets/audio/generated`, o nuovi) | Godot ha `AudioStreamPlayer`/bus nativi; nessun Howler. Serve decisione asset. |
| **C-19** | **Narrazione ampliata e coerente**: da 6 beat lineari a un arco che copre la scala 1→24 con la cornice apparati/nave/enigmi; **relazione NORA** (bond che cresce coi traguardi, memorie sbloccate a milestone) intessuta nella storia, non una schermata a parte | Claude (dati/logica narrativa + bond) + Codex (presentazione) | Richiede un **design pass** prima di implementare: struttura dell'arco, cosa si sblocca a quale livello, come il bond si lega ai progressi reali. |
| **C-16** | Spegnimento Phaser | insieme | ora più lontano: prima si completano le 12 materie + audio + narrazione, poi si rimuove Phaser. Le 4 scene bespoke (Atlante/Città/Serra/Palestra) diventano rimovibili perché il **contenuto** è assorbito nei banchi (la meccanica bespoke si perde, come per le altre). |

### Decisioni di design ancora aperte (servono all'utente)
1. **Pacing degli apparati**: 12 materie su una scala 1→24. Le nuove entrano nel
   ciclo di riparazione (`ApparatusConfig.SUBJECT_CYCLE`, oggi 6 materie) o
   restano solo come enigmi/missioni esterne senza un apparato dedicato? Cambia
   il ritmo della progressione — non l'ho forzato, è una scelta di gioco.
2. **Profondità contenuti nuovi**: scienze/cittadinanza hanno pochi item (13/10)
   perché il materiale sorgente era sottile; geografia/logica sono più ricchi.
   Ampliare tutti a ~40-80 item come le materie forti?
3. **Memoria come mini-gioco**: costruire un bespoke (Simon/griglia lampo) in
   Godot, o lasciarla fuori e tenere solo "logica"?
4. **Struttura narrativa** (C-19): quanti archi, quali milestone, tono — da
   definire insieme prima di scrivere.

## 8. Build e deploy

- **Durante la migrazione**: resta la Pages Phaser; l'export Godot vive in
  `public/godot/…` (come oggi). L'ingresso al mondo è già **unificato**
  (Godot se disponibile, Phaser fallback) — vedi `src/integration/outdoorEntry.ts`.
- **A full-Godot**: la pipeline Pages pubblica direttamente l'**export Godot Web**
  alla radice del sito; niente più `tsc`/Vite per il gioco.
- **Dimensione**: tenere i **banchi di esercizi fuori dal `.pck`** (fetch
  on-demand) per un caricamento iniziale ragionevole; comprimere gli asset;
  valutare `git-lfs` per i binari grandi (il `.wasm` pesa decine di MB).
- **Parità/qualità**: gli script di audit (`fixture_audit.gd`, `roundtrip_audit.gd`)
  restano la rete di sicurezza; aggiungere audit per i banchi (ogni item ha
  risposta valida e spiegazione).

## 9. Rischi e mitigazioni

| Rischio | Mitigazione |
|---|---|
| Porting generatori enorme | **Bake prima**; portare solo i generatori ad alto valore, nel tempo |
| Perdita progressi studenti | `migrate_from_phaser()` idempotente; save canonico versionato |
| Peso del download web | banchi on-demand fuori dal `.pck`; compressione asset |
| Qualità contenuti in Godot | riuso dei **validatori TS** in fase di bake; audit sui banchi |
| Regressioni durante la migrazione | ogni fase spedibile con criteri d'uscita; ingresso unificato con fallback |
| Font/emoji nel web export | usare glifi testuali sicuri o font con i glifi inclusi (già evitate emoji nell'HUD) |

---

## Sintesi operativa

1. Costruire **SaveManager + ExercisePlayer + bake** (Fase 0): è la spina dorsale
   del full-Godot.
2. Bake di tutte le materie e trasformarle in **percorsi nel mondo** (Fasi 1–2).
3. Aggiungere la **narrazione** (Fase 3).
4. Portare i **generatori** e **spegnere Phaser** (Fasi 4–5).

Il primo mattone concreto da prototipare è la coppia **`ExercisePlayer`
(data-driven) + primo banco bakato**: dimostra l'intero modello full-Godot su una
materia, senza toccare il resto.
