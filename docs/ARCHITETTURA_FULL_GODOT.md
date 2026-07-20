# Architettura & Migrazione a Full Godot

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
