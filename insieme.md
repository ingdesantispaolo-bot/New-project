# Eli Quest — Piano operativo condiviso

Aggiornato al 23 luglio 2026.

Questo file contiene soltanto lavoro aperto, decisioni da valutare e passaggi di
consegna tra **Codex** e **Opus**. Non è un registro storico.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)

## Obiettivo corrente

Portare il gioco a un loop realmente completabile e didatticamente credibile:

1. missioni esterne accessibili per tutte le materie;
2. prova finale esclusivamente nella nave;
3. apprendimento che alimenta nave, NORA, Eli e mondo;
4. un nuovo mondo esterno per ogni livello 1–24;
5. minigiochi distribuiti come eventi di missione;
6. esercizi vari, con scelta multipla non dominante;
7. Manuale NORA consultabile;
8. qualità visiva, sonora e prestazionale coerente su Web e dispositivi modesti.

L’ordine P1→P6 è vincolante. Non si avvia la produzione estesa dei 24 mondi
prima di aver superato i gate P1–P3.

---

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance ed export.

### C-P1 — Fondazioni dei mondi

- [ ] Implementare una sola `WorldScene` configurabile dai `WorldProfile` di
  Opus, senza creare 24 scene monolitiche.
- [ ] Applicare per profilo terreno, topologia, art kit, luce, meteo, audio,
  landmark, mission grammar e budget visuale.
- [ ] Riservare `shipEntrance.safeRadius` prima di generare terreno, acqua,
  ostacoli, POI e decorazioni.
- [ ] Garantire spawn, percorso sicuro e accessibilità dell’ingresso nave.
- [ ] Implementare nella nave la mappa dei mondi sbloccati e il viaggio verso un
  mondo già scoperto.
- [ ] Rendere visivamente distinguibili mondo bloccato, nuovo, corrente,
  completato e rivisitabile.
- [ ] Collegare caricamento e ritorno senza perdere posizione, stato o progressi.
- [ ] Collegare il `MissionEventDirector` agli spawn e rimuovere le Palestre
  fisse soltanto dopo fixture deterministiche e verifica in gioco.

**Gate Codex P1:** almeno due profili si caricano nella stessa scena, con ingressi
nave deterministici e senza contaminazioni di stato.

### C-P2 — Vertical slice dei mondi 1 e 2

- [ ] Portare **Radura Accademia** al contratto definitivo `WorldProfile`.
- [ ] Costruire **Archivio delle Parole** con topologia, materiali, atmosfera,
  landmark, soundscape e missioni riconoscibilmente differenti.
- [ ] Inserire nel percorso eventi-minigioco scelti dal `MissionEventDirector`.
- [ ] Far modificare l’ambiente alle risposte corrette, non soltanto l’overlay.
- [ ] Produrre confronti GPU senza HUD a viewport desktop e compatto.
- [ ] Verificare streaming, collisioni, leggibilità e ingresso nave su Web.

**Gate Codex P2:** i mondi 1 e 2 sono distinguibili a colpo d’occhio e il
passaggio livello 1 → mondo 2 funziona nel gioco reale.

### C-P3 — Interazioni didattiche

- [ ] Rifinire `ordering` con drag, slot numerati, annullamento e feedback.
- [ ] Rifinire `matching` con drag o click, linee, snap e stato delle coppie.
- [ ] Implementare renderer accessibili per classificazione e hotspot.
- [ ] Implementare i primi renderer specialistici: grafico, circuito e
  code-debug.
- [ ] Preparare l’API visuale per simulazioni e manipolazione diegetica.
- [ ] Assicurare parità mouse/tastiera/touch nei renderer didattici e nelle
  schermate modali non ancora coperte da audit touch.
- [ ] Supportare contrasto elevato, effetti ridotti e testi lunghi senza
  overflow.
- [ ] Rendere la prova finale visivamente distinta da una missione ordinaria.

**Gate Codex P3:** una missione usa almeno due famiglie di interazione e nessun
renderer modifica direttamente mastery, save o ricompense.

### C-P4 — Manuale e presenza di NORA

- [ ] Costruire l’interfaccia `KnowledgeCodex` nel diario della nave.
- [ ] Permettere consultazione dal mondo senza perdere la sessione.
- [ ] Implementare ricerca, filtri per materia, preferiti e collegamenti tra
  concetti.
- [ ] Rendere esempi, errori tipici e dimostrazioni interattive.
- [ ] Collegare le fasi di integrità di NORA a ritratto, animazioni, colore,
  audio e nave.
- [ ] Separare chiaramente battute di NORA, messaggi di sistema e prompt input.

**Gate Codex P4:** da un errore si può raggiungere la spiegazione corretta e
tornare alla missione; NORA non pronuncia messaggi tecnici generici.

### C-P5 — Produzione visuale dei mondi

Produrre i mondi soltanto dopo approvazione del gate precedente:

- [ ] ondata A: mondi 3–4;
- [ ] ondata B: mondi 5–8;
- [ ] ondata C: mondi 9–12;
- [ ] ondata D: mondi 13–20;
- [ ] ondata E: mondi 21–24 e finale.

Per ogni mondo:

- [ ] silhouette e topologia proprie;
- [ ] materiali, vegetazione o architettura proprie;
- [ ] luce, meteo e soundscape propri;
- [ ] landmark principale e ingresso nave autorati;
- [ ] almeno una trasformazione ambientale legata all’apprendimento;
- [ ] HLOD, streaming e budget Web verificati;
- [ ] capture di riferimento approvata.

### C-P6 — Pass AAA e consegna

- [ ] Regia, camera, animazioni, transizioni e sound design per i traguardi.
- [ ] Coerenza di art direction tra Eli, mondi, nave, NORA e UI.
- [ ] Compressione audio, texture e pacchetto Web senza perdita percettibile.
- [ ] Profili prestazionali per desktop, mobile e hardware scolastico.
- [ ] Test input/aspect ratio/accessibilità.
- [ ] Export Web riproducibile con smoke test della build pubblicabile.

---

## Compiti Opus

Opus è responsabile di progressione, save, didattica, contenuti, narrativa,
contratti dati, selezione adattiva e audit semantici.

### O-P1 — Contratti dei mondi e degli eventi

- [x] Definire schema e validatore `WorldProfile`. — *`world_profile.gd`
  (`WorldProfileCatalog`): schema, geometria base autorata (ingresso nave a
  origine, `safeRadius`, spawn, percorso sicuro) e `validate`/`validate_all`.*
- [x] Consegnare i 24 profili con id, livello, focus, mission grammar, art brief,
  ingresso nave, spawn, percorso sicuro e budget. — *24 profili dalla mappa AAA,
  distinti e con focus derivato da `ApparatusConfig` (unica fonte di verità).*
- [x] Versionare nel save mondi sbloccati, mondo corrente, punti di viaggio e
  stato persistente. — *save v2 `worlds` {unlocked, current} + metodi
  `unlock_world`/`current_world`; migrazione riconcilia 1..livello. Stato
  persistente per mondo già in `worldProgress` (O-P0.4).*
- [x] Implementare `MissionEventDirector` deterministico. — *`mission_event_director.gd`:
  `plan(profile, context, worldSeed)` con RNG seminato da worldSeed+livello.*
- [x] Garantire una quota di eventi del focus livello entro distanza
  raggiungibile. — *`missionsRequired + 2` eventi-gate del focus, tutti
  raggiungibili; `reachable_gate_events()` per il controllo di non-blocco.*
- [x] Evitare ripetizioni recenti di formato, topic e prompt. — *`_next_format`
  evita il formato precedente e quelli recenti; `topicHint` ruota su ripasso/deboli.*
- [x] Distinguere tappa di missione, evento libero di pratica ed enigma
  persistente. — *`kind` ∈ {mission, enigma, practice}; solo la pratica ha
  `countsForGate=false`.*
- [x] Fornire a Codex un contratto read-only; il visuale non decide ricompense o
  completamenti. — *il director ritorna posizioni/formati/soggetti; conteggi e
  ricompense restano in ProgressionManager/outdoor_gameplay.*

**Gate Opus P1:** fixture deterministiche dimostrano disponibilità delle missioni,
assenza di blocchi e rispetto della zona nave. → *implementato e **verificato**:
`mission_event_director_audit` e `world_profile_audit` **verdi** su tutti i 24
mondi (determinismo, ≥ missioni richieste raggiungibili, nessun evento in zona
nave, formati vari).*

### O-P2 — Specifica didattica dei primi due mondi

- [ ] Definire obiettivi, prerequisiti, topic e prove di trasferimento dei
  livelli 1 e 2.
- [ ] Scrivere mission grammar ed event pool di Radura Accademia e Archivio
  delle Parole.
- [ ] Stabilire quali azioni nel mondo rappresentano davvero i concetti.
- [ ] Consegnare briefing, feedback e debrief NORA dei due livelli.
- [ ] Validare che la difficoltà dipenda dalla competenza della materia e non
  soltanto dal rango globale.

### O-P3 — Contratti e contenuti degli esercizi

- [ ] Stabilizzare `ExerciseInteraction`: input, validazione, feedback,
  tentativi, scoring e accessibilità.
- [ ] Fornire contenuti per ordinamento, matching, classificazione, hotspot,
  grafici, circuiti, code-debug e simulazioni.
- [ ] Portare la scelta multipla a un target iniziale ≤33% dei nodi standard,
  da rivalutare con playtest.
- [ ] Impedire esami finali composti soltanto da scelta multipla.
- [ ] Richiedere almeno due formati e una prova di trasferimento per ogni finale.
- [ ] Migliorare spiegazioni causali, distrattori e copertura dei banchi corti.
- [ ] Aggiungere validator per ambiguità, soluzioni, input equivalenti,
  accessibilità linguistica e duplicati.
- [ ] Registrare evidenza per topic, difficoltà, aiuti, tentativi e ritenzione.

**Gate Opus P3:** audit contenuti e scoring verdi per ogni renderer consegnato a
Codex; nessun formato concede progresso fuori dal contratto comune.

### O-P4 — Manuale e arco di NORA

- [ ] Definire schema `ConceptEntry` e stati sconosciuto → consolidato.
- [ ] Garantire almeno una voce di manuale per ogni topic usato dal runtime.
- [ ] Scrivere spiegazione breve, esempio, errore tipico e strategia NORA.
- [ ] Stabilire regole di consultazione durante pratica, missione ed esame.
- [ ] Espandere la storia da sei beat a un arco completo di 24 livelli.
- [ ] Definire integrità, memoria e fiducia di NORA nel save.
- [ ] Far reagire NORA a errore ricorrente, richiesta di aiuto, perseveranza,
  miglioramento e trasferimento.
- [ ] Evitare che fiducia o progressione narrativa dipendano soltanto dalle
  risposte corrette.

**Gate Opus P4:** ogni valutazione rimanda a un concetto documentato e ogni
livello ha un beat narrativo nuovo.

### O-P5 — Contenuti dei mondi 3–24

Per ogni ondata:

- [ ] curriculum e prerequisiti;
- [ ] mission grammar ed event pool;
- [ ] briefing/debrief e beat NORA;
- [ ] manuale dei nuovi concetti;
- [ ] prove finali di copertura e trasferimento;
- [ ] criteri per la trasformazione ambientale;
- [ ] audit didattici e di raggiungibilità.

Opus consegna un’ondata soltanto quando quella precedente ha superato il gate
integrato con Codex.

### O-P6 — Validazione

- [ ] Report locale utile: copertura, confidenza, ritenzione, aiuti e tempo.
- [ ] Configurazione per fascia scolastica, curriculum e materie attive.
- [ ] Piano di playtest con studenti, docenti e revisori disciplinari.
- [ ] Guardrail contro grinding, ansia, timer impropri e ricompense che falsano
  la mastery.
- [ ] Audit completo di save migration e compatibilità dei profili esistenti.

---

## Gate di consegna Codex ↔ Opus

| Gate | Consegna Opus | Lavoro Codex | Verifica finale |
|---|---|---|---|
| G1 Mondi | `WorldProfile` + fixture | loader, ingresso nave, navigazione | due profili senza stato contaminato |
| G2 Eventi | `MissionEventDirector` read-only | spawn e resa diegetica | evento deterministico e raggiungibile |
| G3 Esercizi | contratto, contenuti, validator | renderer e input | scoring identico su mouse/touch/tastiera |
| G4 NORA | `ConceptEntry`, stato e testi | Manuale e presentazione | errore → spiegazione → ritorno sessione |
| G5 Ondata | curriculum e mission grammar | mondo visuale completo | audit + capture + performance |

Regole:

- chi produce il contratto non modifica la resa dell’altro senza handoff;
- Codex non calcola mastery, ricompense o gate nella UI;
- Opus non decide posizionamento visuale o budget di rendering;
- un cambio di contratto richiede aggiornamento di fixture e consumer nello
  stesso gate;
- nessuna ondata successiva parte con audit rossi nell’ondata corrente.

## Handoff Opus → Codex · contratto O-P1 (per C-P1)

Contratto **read-only** pronto da consumare nella `WorldScene`:

- **`WorldProfileCatalog.profile(level)`** → il profilo del mondo: identità
  (terreno, topologia, art kit, landmark, luce, meteo, soundscape),
  `learningFocus`, `missionGrammar`, `eventPools.formats`, `performanceBudget`, e
  la geometria autorata `shipEntrance {position, rotation, safeRadius}`, `spawn`,
  `safeRoute`, `worldHalfExtent`. Coordinate in unità mondo, origine sull'ingresso
  nave; la procedura riempie il profilo ma **non invade `safeRadius`** né cambia
  l'identità. `validate_all()` disponibile.
- **`MissionEventDirector.plan(profile, context, worldSeed)`** → gli eventi da
  posizionare: `{id, kind(mission|enigma|practice), subject, format, topicHint,
  position, countsForGate, reachable}`. Deterministico (seed+stato → stessi
  eventi). Codex posiziona/renderizza e risolve la navigabilità nudgeando entro
  tolleranza, ma **non** decide materia, conteggi o ricompense; `countsForGate`
  lo stabilisce il contratto. `context` = {missionsRequired, weakTopics,
  dueTopics, recentFormats}.
- **Save**: `worlds {unlocked, current}` + `unlock_world`/`current_world` per la
  mappa di viaggio nella nave; sblocco automatico al salire di livello.

Fixture verdi: `world_profile_audit`, `mission_event_director_audit`.

## Decisioni ancora da valutare

- [ ] Confermare nomi e temi definitivi dei 24 mondi.
- [ ] Decidere quali mondi restano liberamente rivisitabili e come scala la loro
  difficoltà dopo il completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤33%.
- [ ] Definire la quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Stabilire quali aiuti del Manuale NORA sono disponibili durante gli esami.
- [ ] Approvare la mappa provvisoria dei mondi 13–24 e il finale trasversale.
- [ ] Fissare budget misurabili per FPS, memoria, download e tempi di caricamento
  sui dispositivi scolastici target.
- [ ] Decidere priorità tra nuovi asset originali e riuso modulare per ogni
  ondata di mondi.

---

## Lavori da non iniziare ora

- Ulteriore polish delle Palestre fisse.
- Nuovi grandi banchi composti quasi soltanto da scelta multipla.
- Produzione contemporanea di tutti i 24 mondi.
- Duplicazione di `WorldScene` in una scena separata per livello.
- Nuovi effetti della nave non collegati a una progressione didattica.
- Moduli, pet o valuta che permettano di saltare prove di competenza.
