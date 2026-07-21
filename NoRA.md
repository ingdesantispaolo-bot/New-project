# NoRA — Report tecnico di *Eli Quest*

> **A chi è rivolto.** A uno studente di Ingegneria Informatica al secondo anno.
> L'obiettivo non è documentare ogni riga, ma spiegare **come è fatto** questo
> progetto reale: quali linguaggi e framework usa, *perché*, e quali tecniche —
> alcune semplici, alcune avanzate — lo tengono in piedi. Dove serve, trovi il
> file esatto da aprire per vedere la cosa "dal vivo".

---

## 0. In una frase

*Eli Quest* è un videogioco educativo per bambini in cui si esplora un mondo,
si risolvono esercizi scolastici (matematica, italiano, inglese, coding, fisica,
musica, latino, elettronica) e si "riparano" apparati di un'astronave salendo di
livello. Tecnicamente è un progetto **in migrazione**: nato come gioco web
(TypeScript + Phaser) sta passando a un **motore unico Godot**. Capire il perché
di questa doppia natura è la chiave per capire tutta l'architettura.

---

## 1. Colpo d'occhio: due mondi tecnologici

Nel repository convivono due stack. Non è un errore né spreco: è una migrazione
**incrementale**, fatta apposta per non rompere il gioco funzionante mentre se ne
costruisce la versione definitiva.

| | Stack A — Web (origine) | Stack B — Godot (destinazione) |
|---|---|---|
| **Linguaggio** | TypeScript | GDScript |
| **Motore / framework** | Phaser 4 | Godot 4.3 |
| **Build / tooling** | Vite, Node.js | Editor Godot + export |
| **Dove vive** | `src/` | `godot/` |
| **Ruolo oggi** | gioco completo, "verità" storica | mondo esterno + loop nativo |

La regola mentale è semplice: **`src/` = il gioco di ieri, `godot/` = il gioco di
domani**. Un ponte software (il *bridge*, §6.3) li tiene in contatto durante la
transizione.

> **Lezione di ingegneria n.1.** In un progetto reale non si riscrive tutto da
> zero in un colpo solo ("big bang rewrite"): è il modo più veloce per rompere
> tutto. Si migra **a fette**, mantenendo sempre una versione funzionante. Qui la
> strategia ha persino un nome interno: *"bake prima, port poi"* (§6.2).

---

## 2. I linguaggi, e *come* sono usati

### 2.1 TypeScript (lato web, `src/`)

TypeScript è JavaScript **con i tipi**. JavaScript da solo ti lascia scrivere
`giocatore.energia = "molta"` e te ne accorgi solo quando crasha davanti
all'utente. TypeScript aggiunge un controllo *a tempo di compilazione*: dichiari
che `energia: number` e il compilatore ti blocca prima ancora di eseguire.

Nel progetto TS è usato in modo "serio e strutturato": circa **260 file**,
organizzati in `src/core/` (i sistemi: esercizi, punteggi, ricompense, salvataggi,
audio…) e `src/data/` (i contenuti: banchi di parole, template di esercizi,
mappe). Nota come i nomi dei file siano già una mappa mentale del gioco:
`MissionEngine.ts`, `MasterySystem.ts`, `RewardSystem.ts`, `SaveSystem.ts`. Questo
si chiama **separazione delle responsabilità**: ogni sistema fa una cosa sola.

L'entry point è minuscolo — `src/main.ts` — e questo è un buon segno:

```ts
const game = new Phaser.Game(gameConfig);
```

Tutto il resto è nei sistemi. Il `main` si limita ad accendere il motore.

### 2.2 GDScript (lato Godot, `godot/scripts/`)

GDScript è il linguaggio nativo di Godot. Assomiglia a Python (indentazione,
sintassi pulita) ma è pensato per i videogiochi: ha tipi per vettori 2D, nodi di
scena, segnali. È **gradualmente tipizzato**: puoi scrivere `var x := 3` (tipo
dedotto) o `var energia: int = 200` (esplicito). Nel progetto la tipizzazione è
usata quasi ovunque — è una scelta di qualità, perché rende il codice più leggibile
e cattura errori prima.

Due idiomi GDScript che incontrerai spesso e vale la pena riconoscere subito:

- **`class_name`**: in cima a un file, `class_name ContentManager` registra quella
  classe *globalmente*. Da qualunque altro script puoi fare `ContentManager.new()`
  senza importare nulla. È l'equivalente di una classe pubblica auto-registrata.
- **`signal`**: il meccanismo di comunicazione (vedi §5.1).

---

## 3. I framework/motori, e *come* sono usati

### 3.1 Phaser 4 (motore di gioco 2D per il web)

Phaser è un motore di gioco 2D che gira nel **browser**, disegnando su una `<canvas>`
HTML5. Ti dà il *game loop* (il ciclo che ridisegna la scena ~60 volte al secondo),
la gestione di sprite, input, fisica arcade, scene. Nel progetto è la fondazione del
gioco web: `new Phaser.Game(...)` in `main.ts`.

### 3.2 Godot 4.3 (motore di gioco completo)

Godot è un motore **stand-alone** (ha un suo editor visuale) che esporta verso
desktop, mobile e — importante qui — **web via WebAssembly**. Il concetto centrale
di Godot è l'**albero di nodi**: una scena è un albero di oggetti (`Node2D`, `Label`,
`Button`, `CanvasLayer`…), ognuno con una responsabilità. Uno script GDScript si
"attacca" a un nodo e ne guida il comportamento.

Vedi `godot/project.godot`: la scena principale è `outdoor_world.tscn`, la
risoluzione 1280×720, il renderer è *GL Compatibility* (scelto per girare bene
anche su hardware modesto e nel browser). I comandi (WASD, E per interagire) sono
mappati lì come *input actions* — un'astrazione utile: il codice reagisce all'azione
`"interact"`, non al tasto fisico, così rebindare i tasti non tocca la logica.

### 3.3 Il tooling attorno (Node.js, Vite, Vitest, Sharp)

Questi non sono "il gioco", sono gli **attrezzi da officina**:

- **Node.js** esegue JavaScript *fuori* dal browser: lo si usa per gli script di
  build in `scripts/` (generano immagini, audio, mappe, banchi di esercizi).
- **Vite** è il *bundler/dev server*: durante lo sviluppo serve la app con
  ricarica istantanea; in build compila TS e impacchetta tutto per la
  distribuzione (`npm run build`).
- **Vitest** è il framework di test (vedi `src/core/__tests__/`).
- **Sharp** è una libreria per elaborare immagini (ridimensiona/ottimizza gli
  asset in fase di build).

> **Lezione di ingegneria n.2.** Distingui sempre le tre fasi: *build time* (Node
> prepara gli asset e compila), *bundling* (Vite impacchetta), *run time* (Phaser o
> Godot eseguono). Molta della "magia avanzata" di questo progetto (§6.2) succede a
> **build time**, non mentre il bambino gioca.

---

## 4. Le due idee architetturali portanti

Se ricordi solo due parole di questo report, siano queste: **event-driven** e
**data-driven**.

### 4.1 Data-driven: i contenuti sono dati, non codice

Un esercizio non è scritto come `if`/`else` nel codice. È un **dato** — un oggetto
JSON — con questa forma (un `ExerciseItem`):

```json
{
  "prompt": "Quanto fa 7 × 8?",
  "format": "multiple_choice",
  "options": ["54", "56", "63", "49"],
  "answer": "56",
  "topic": "tabelline",
  "difficulty": 3,
  "explanation": "7 × 8 = 56."
}
```

Il codice che *gioca* l'esercizio non sa nulla di matematica: sa solo mostrare un
prompt, delle opzioni, confrontare la risposta con `answer` e mostrare
`explanation`. Aggiungere mille esercizi nuovi **non richiede toccare il codice**,
solo aggiungere dati. Questo è il cuore del design *data-driven*, e spiega perché i
banchi vivono in `godot/data/banks/*.json`.

### 4.2 Event-driven: i pezzi si parlano tramite eventi

Nessun componente "tira i fili" degli altri chiamandoli direttamente. Chi ha una
novità **la annuncia** (emette un evento/segnale); chi è interessato **ascolta**.
Questo tiene i pezzi disaccoppiati: l'HUD non deve sapere *come* funziona la
progressione, ascolta solo "lo stato è cambiato, ecco quello nuovo".

Lato Godot il meccanismo sono i **signal**; lato web c'è un `EventBus.ts`. Sono la
stessa idea (il pattern *Observer/Publish-Subscribe*) in due lingue.

---

## 5. Come i pezzi comunicano davvero (con esempi dal codice)

### 5.1 Segnali Godot: annuncia, non comandare

Guarda l'inizio di `godot/scripts/game/outdoor_gameplay.gd`:

```gdscript
signal runtime_state_changed(state: Dictionary)  # stato aggiornato
signal session_requested(session: Dictionary)    # la scena mostra l'ExercisePlayer
signal feedback(message: String)                 # messaggio per l'HUD
```

`OutdoorGameplay` contiene la **logica** del gioco (ricompense, livelli, salvataggi).
Quando qualcosa cambia, *non* va a modificare l'HUD: emette
`runtime_state_changed` con una fotografia dello stato. L'HUD e i sistemi grafici
si sono "abbonati" a quel segnale (`.connect(...)`) e si aggiornano da soli. Se
domani cambi la grafica dell'HUD, la logica non se ne accorge nemmeno.

### 5.2 Il "contratto" come single source of truth

Nota un dettaglio da progetto maturo: c'è **una sola** funzione che produce lo
stato leggibile, `runtime_state()`, e restituisce sempre lo stesso dizionario
"contratto":

```gdscript
return {
    "level": game_save.level(),
    "focusSubject": ...,
    "missionsDone": ..., "missionsRequired": ...,
    "missionsRemaining": ..., "missionProgress": ...,   # comodità per la UI
    "mastery": ..., "masteryThreshold": ..., "masteryProgress": ...,
    "ready": ..., "energy": ..., "fragments": ...,
    "phase": ..., "sessionActive": ...,
}
```

Perché è importante? Perché la UI **non ricalcola nulla**. Se la barra di progresso
avesse la sua formula e la logica ne avesse un'altra, prima o poi divergerebbero
(bug classico: "il numero in alto dice 3/5 ma la barra è a metà"). Qui c'è **una
sola fonte di verità** e tutti la leggono. I campi come `missionProgress`
(già normalizzato 0..1) sono lì apposta perché chi disegna non debba dividere a mano.

> **Lezione di ingegneria n.3 — Single Source of Truth.** Ogni fatto deve avere un
> unico posto dove è calcolato. Duplicare un calcolo "per comodità" è debito che si
> paga con bug di disallineamento.

### 5.3 La sessione esercizi è una piccola macchina a stati

`godot/scripts/game/exercise_player.gd` è un ottimo esempio di **macchina a stati
finiti (FSM)** minimale, il pane quotidiano dell'ingegnere. Gli stati sono impliciti
nelle variabili `_index` (quale esercizio), `_answered` (ha già risposto?),
`_shields` (vite rimaste). Il flusso:

```
mostra esercizio  →  attesa risposta  →  valuta  →  [Avanti]  →  esercizio successivo
                                             │
                                        scudi = 0  →  fine (fallito)
                     tutti gli esercizi finiti      →  fine (calcola "passed")
```

La regola di superamento è una riga sola e vale la pena leggerla:

```gdscript
var passed := _shields > 0 and _correct * 2 >= total
```

Cioè: "non hai esaurito gli scudi **e** hai preso almeno metà degli esercizi"
(`_correct * 2 >= total` è il modo intero, senza divisioni e arrotondamenti, di
scrivere `_correct >= total/2`). Un trucchetto piccolo ma pulito: evitare la
divisione floating-point quando basta l'aritmetica intera.

Quando finisce, **non modifica il resto del gioco**: emette `session_finished` con
un risultato (quanti giusti, `passed`, energia, e i `topic` sbagliati). Chi ha
lanciato la sessione decide cosa farne. Di nuovo: annuncia, non comanda.

---

## 6. I "trucchi avanzati" (il cuore ingegneristico)

Qui vivono le tecniche che distinguono un progetto giocattolo da uno vero.

### 6.1 ⭐ PRNG deterministico e **parità cross-language**

Questo è il pezzo più bello del progetto, e merita attenzione.

Il gioco genera mondo e contenuti in modo **procedurale** (non disegnati a mano ma
calcolati). Per farlo serve casualità. Ma la casualità "vera" ha un problema: se il
mondo web (TypeScript) e il mondo Godot (GDScript) usassero due generatori diversi,
lo *stesso seed* produrrebbe due mondi diversi — e la migrazione sarebbe
incoerente. La soluzione: usare lo **stesso identico** generatore pseudo-casuale nei
due linguaggi, in modo che, dato lo stesso seed, producano **la stessa sequenza bit
per bit**.

L'algoritmo è **mulberry32** (un PRNG veloce a stato singolo) con seed derivato da
un hash **FNV-1a** della stringa. Confronta i due lati:

TypeScript (`scripts/build-exercise-banks.mjs`):
```js
a += 0x6d2b79f5;
let t = a;
t = Math.imul(t ^ (t >>> 15), t | 1);
t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
```

GDScript (`godot/scripts/deterministic_rng.gd`):
```gdscript
state = (state + 0x6D2B79F5) & 0xFFFFFFFF
var t := state
t = _imul(t ^ (t >> 15), t | 1)
t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & 0xFFFFFFFF
return float(t) / 4294967296.0
```

È **lo stesso algoritmo tradotto**. Ci sono però sottigliezze da veri ingegneri:

- In JS, `Math.imul` è la moltiplicazione a **32 bit** con overflow (JS di norma usa
  float a 64 bit; qui serve il comportamento intero a 32 bit). In GDScript gli interi
  sono a 64 bit, quindi bisogna **mascherare a mano** con `& 0xFFFFFFFF` dopo ogni
  operazione per emulare i 32 bit. Dimenticare una maschera = divergenza silenziosa.
- Il commento nel file GDScript avverte: *"Ogni estrazione deve coincidere bit a bit…
  non modificare la sequenza senza rigenerare le fixture di parità"*. Esistono cioè
  dei **test di parità** (`scripts/build-outdoor-fixtures.mjs` + `fixture_audit.gd`)
  che verificano che le due implementazioni non abbiano preso strade diverse.

Anche l'ordine in cui si consumano i numeri conta: guarda `shuffle()` (Fisher-Yates)
— il commento specifica *"consuma esattamente (n-1) estrazioni"*, perché se un lato
ne consumasse una in più, tutte le estrazioni successive sarebbero sfasate.

> **Lezione di ingegneria n.4 — Determinismo.** "Stesso input → stesso output" è una
> proprietà preziosissima: rende i bug **riproducibili**, i test possibili, e qui
> permette a due motori diversi di generare mondi identici. La casualità dei
> videogiochi non è quasi mai casuale: è *pseudo*-casuale e controllata.

### 6.2 La pipeline *"bake prima, port poi"*

Portare *tutti* i generatori di contenuti da TypeScript a GDScript in un colpo
sarebbe enorme e rischioso. La scorciatoia intelligente:

1. **Bake** (a build time, con Node): gli script in `scripts/` — es.
   `build-exercise-banks.mjs` — eseguono la logica TS *già collaudata* e ne
   "cuociono" il risultato in file JSON statici dentro `godot/data/`.
2. **Port** (a run time, in Godot): `ContentManager` in Godot si limita a
   **caricare** quei JSON, senza dover reimplementare i generatori.

Così Godot ottiene contenuti corretti *da subito*, e la riscrittura vera dei
generatori si fa con calma, materia per materia. È esattamente il commento in cima a
`content_manager.gd`: *"bake prima, port poi"*.

### 6.3 Save canonico, migrazione idempotente e il *bridge*

Il salvataggio (`godot/scripts/game/save_manager.gd`) mostra parecchie accortezze da
software che gira "in produzione" su dati reali di utenti:

- **Migrazione non distruttiva** (`migrate_from_phaser`): quando carica un vecchio
  salvataggio, aggiunge i campi mancanti *senza buttare via campi sconosciuti*.
  Perché? Se una versione futura salvasse un campo nuovo e una vecchia lo cancellasse
  al caricamento, si perderebbero dati. La funzione è anche **idempotente**:
  applicarla due volte dà lo stesso risultato.
- **Regole di autorità** su chi "vince" quando due fonti disaccordano. Esempio reale
  e sottile: durante la migrazione, energia e frammenti restano autoritativi dal lato
  Phaser (sono la "valuta" storica), **ma il livello no**:

  ```gdscript
  # Applica il save canonico ricevuto solo se non fa regredire il livello.
  if int(candidate.get("level", 0)) >= level():
      data = candidate
  ```

  Questo *guard* impedisce un bug fastidioso: un handshake "vecchio" (stale) che
  riporterebbe il giocatore a un livello inferiore. In sistemi distribuiti si chiama
  gestire dati *stale*; qui è in miniatura ma è lo stesso ragionamento.

Il **bridge** è il ponte software tra i due mondi durante la migrazione: passa uno
stato minimo (JSON) tra Phaser e Godot. È dichiaratamente **temporaneo** — l'obiettivo
finale (motore unico Godot) è farlo sparire.

### 6.4 Generazione del mondo a *chunk*

Il mondo esterno non è una mappa gigante caricata tutta insieme, ma è diviso in
**chunk** (porzioni) generati e distrutti man mano che il giocatore si muove
(`chunk_manager.gd`, `chunk_ground.gd`, `chunk_visual.gd`). Ogni chunk è generato in
modo deterministico dal suo seed (§6.1), quindi tornare indietro rigenera *lo stesso*
pezzo di mondo. È la stessa tecnica dei mondi "infiniti" tipo Minecraft, in piccolo:
memoria costante, mondo potenzialmente illimitato.

---

## 7. Le logiche semplici (ma che fanno il gioco)

Non tutto è un trucco raffinato: molta robustezza viene da logiche lineari fatte
bene. Vale la pena vederne il flusso complessivo, perché è **il loop educativo** del
gioco:

```
     ┌─────────────────────────────────────────────────────────┐
     │  MONDO ESTERNO                                            │
     │  • esplori, trovi "incontri" (POI)                        │
     │  • parte una MISSIONE = sessione di esercizi adattivi     │
     │        ↓ risposte giuste → energia + padronanza ↑         │
     │  • ripeti finché: missioni fatte ≥ richieste  E           │
     │                   padronanza ≥ soglia   →  GATE PRONTO    │
     └───────────────────────────┬─────────────────────────────┘
                                 │ ready == true
     ┌───────────────────────────▼─────────────────────────────┐
     │  ESAME FINALE dell'apparato                              │
     │  • superato → l'apparato è RIPARATO → LIVELLO +1         │
     │  • le missioni si azzerano, la soglia sale un po'        │
     └─────────────────────────────────────────────────────────┘
                       (ripeti per ~20+ livelli)
```

Alcune logiche semplici degne di nota:

- **Difficoltà adattiva** (`content_manager.gd`): la difficoltà target si ricava dal
  livello con una formula lineare e limitata —
  `clampi(1 + (level - 1) / 3, 1, 4)`. Il `clamp` (limitare tra min e max) è
  l'utility più usata in tutto il gioco: impedisce a un valore di uscire dal suo
  intervallo lecito.
- **Ripasso spaziato** (*spaced repetition*): gli argomenti sbagliati finiscono in una
  mappa `spacedRepetition.due` (`"materia:argomento" → quante volte`), e le missioni
  successive li **ripescano con priorità**. Quando li risolvi, il contatore scende.
  È la stessa idea delle flashcard (Anki): rivedi di più ciò che sbagli. Semplice da
  scrivere, potente per l'apprendimento.
- **Penalità morbida**: sbagliare toglie uno "scudo" e mostra la spiegazione; a scudi
  esauriti la missione fallisce e si ripete, ma **non si perde mai** progresso
  distruttivamente. È una scelta di *design* codificata nella FSM di §5.3.

> **Lezione di ingegneria n.5.** La qualità di un software si vede spesso nei
> **casi limite** gestiti con logiche banali: un `clamp`, un `max()` che impedisce
> una regressione, un default sensato quando manca un dato. Non è codice
> spettacolare, ma è ciò che evita i crash e i bug in mano agli utenti.

---

## 8. Come si verifica che funzioni: gli *audit* headless

Il progetto non ha (ancora) un motore grafico nei test automatici, ma usa una
tecnica elegante: **audit headless**. Sono script GDScript che estendono
`SceneTree` (l'albero di scena di Godot) e girano **senza finestra grafica**
(`godot --headless`), pilotando la logica come farebbe un giocatore e verificando
le invarianti con `assert`.

Esempio (`godot/scripts/game/c02_audit.gd`): l'audit fa partire missioni finte
finché il gate diventa `ready`, poi lancia l'esame, e verifica che il livello sia
salito di 1 e le missioni si siano azzerate:

```gdscript
assert(int(gameplay.runtime_state()["level"]) == level_before + 1, "livello avanzato")
assert(int(gameplay.runtime_state()["missionsDone"]) == 0, "conteggio azzerato")
```

C'è un audit per ogni blocco importante (`c01`…`c10`, `loop_audit`, `fixture_audit`
per la parità RNG). Lato web, invece, i test sono **unit test Vitest** in
`src/core/__tests__/`. Due mondi, stessa filosofia: **non fidarti, verifica**, e
fallo in automatico.

> **Lezione di ingegneria n.6.** Un test headless che pilota la *logica* senza la
> *grafica* è veloce, deterministico e girabile a ogni commit. Separare "cosa fa il
> gioco" (logica, testabile) da "come appare" (presentazione) è ciò che rende
> possibile testarlo — ed è la stessa separazione che vedi ovunque nel codice.

---

## 9. Il filo rosso: **separare la semantica dalla presentazione**

Se rileggi tutto, un principio ritorna a ogni livello:

- `OutdoorGameplay` (logica) è separato da HUD/scena (presentazione), e comunicano
  per segnali.
- `ExercisePlayer` valuta ed emette un risultato; **chi** ha chiesto la sessione
  decide le conseguenze.
- La logica dei contenuti (banchi JSON) è separata dal codice che li gioca.
- Gli audit testano la logica senza toccare la grafica.

Questa è, in fondo, la lezione più importante che questo progetto insegna a un
ingegnere: **tieni separato ciò che il sistema *fa* da come lo *mostra***. È ciò che
permette a due persone di lavorare in parallelo (uno sulla logica, uno sulla
grafica), a due motori di coesistere durante una migrazione, e ai test di esistere.

---

## 10. Mappa rapida "dove guardo se voglio vedere…"

| Voglio capire… | Apri… |
|---|---|
| L'avvio del gioco web | `src/main.ts` |
| I sistemi di gioco web | `src/core/*.ts` |
| I contenuti (dati) web | `src/data/**` |
| Il PRNG deterministico | `godot/scripts/deterministic_rng.gd` + `scripts/build-exercise-banks.mjs` |
| La logica del mondo esterno | `godot/scripts/game/outdoor_gameplay.gd` |
| La sessione di esercizi (FSM) | `godot/scripts/game/exercise_player.gd` |
| Selezione/difficoltà esercizi | `godot/scripts/game/content_manager.gd` |
| Il salvataggio e la migrazione | `godot/scripts/game/save_manager.gd` |
| Il gate/livelli/apparati | `godot/scripts/game/progression_manager.gd`, `apparatus_config.gd` |
| I test/audit | `godot/scripts/**/c*_audit.gd`, `src/core/__tests__/**` |
| La visione e l'architettura | `docs/VISIONE_DI_GIOCO.md`, `docs/ARCHITETTURA_FULL_GODOT.md`, `docs/DESIGN_COMPLETO.md` |

---

### Glossario lampo

- **PRNG**: *Pseudo-Random Number Generator*, generatore di numeri pseudo-casuali:
  deterministico, quindi riproducibile dato il seed.
- **Seed**: il valore iniziale da cui il PRNG deriva tutta la sequenza.
- **Idempotente**: un'operazione che, applicata più volte, dà lo stesso risultato di
  una volta sola.
- **Data-driven**: comportamento guidato da dati (JSON) invece che da codice.
- **Event-driven / Observer**: i componenti comunicano annunciando eventi, non
  chiamandosi a vicenda.
- **FSM**: *Finite State Machine*, macchina a stati finiti.
- **Bake**: pre-calcolare a build time un risultato per servirlo pronto a run time.
- **Headless**: eseguito senza interfaccia grafica.
- **Clamp**: forzare un valore dentro un intervallo `[min, max]`.
- **Single source of truth**: un unico posto dove un dato è calcolato/deciso.

*— Documento didattico. Il codice citato è reale e consultabile ai percorsi indicati.*
