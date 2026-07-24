# Struttura del finale — Mondo 24 · Cuore dei Primi (congelata, Gate E1→E2)

Stato: **struttura approvata da Opus.** Da qui Codex implementa la resa e la
sequenza (Gate E2). I contratti didattici qui sotto sono congelati: un cambiamento
richiede aggiornamento coordinato di fixture e consumer nello stesso gate.

Il finale deve essere **un solo flusso verificabile**, non una serie di menu
scollegati. Cinque tappe, in quest'ordine.

## 1 · Ingresso al mondo 24

- `WorldProfile` livello 24 (`world-24-cuore`, focus `logica/trasversale`).
- Dodici settori riconoscibili che convergono verso il Cuore (uno per sistema/
  materia). Ingresso nave autorato e protetto come ogni mondo.
- Briefing NORA del livello 24 (`NarrativeManager.beat_for_level(24)`): «tutti i
  sistemi convergono… le usi tutte insieme, trasferendo i metodi».

## 2 · Prova trasversale (i dodici sistemi)

Contratto Opus **già disponibile**: `ContentManager.build_final_transversal_exam(24, rng, mastery_by_subject)`.

- 12 nodi, **uno per materia** in ordine canonico (`ApparatusConfig.SUBJECT_CYCLE`);
  ogni nodo porta `system = <materia>`. Risolverlo **accende quel sistema**.
- 1 nodo di **sintesi** finale (`system = "sintesi"`, `transfer = true`), formato
  interattivo (non scelta multipla): applica i metodi a un caso nuovo.
- Multi-formato, mai solo scelta multipla, **senza limite di tempo** (`reasoning`).
- Ogni sistema è adattivo alla competenza reale della materia (`mastery_by_subject`).
- Verificato da `finale_transversal_audit.gd` (deterministico a parità di seed).

**Resa Codex:** ogni nodo risolto accende visibilmente il settore/sistema
corrispondente; la reazione a cinque stadi del Cuore avanza con i sistemi accesi.
La prova vive nella nave/Cuore, non nel mondo esterno (l'esame è sempre nella nave).

## 3 · Convergenza dei dodici sistemi

- Quando tutti i sistemi sono accesi (prova superata), i dodici settori convergono
  nel Cuore in un'unica animazione continua.
- Il progresso è quello reale del save: gli apparati riparati (12) determinano
  integrità e memoria di NORA (`NoraState.sync_from_progress`).

## 4 · Beat conclusivo di NORA e riattivazione della nave

- Beat livello 24 poi **beat finale**: `NarrativeManager.FINAL_BEAT`
  («La nave è viva e la rotta è aperta… da equipaggio»).
- Riattivazione **completa** della nave: `ProgressionManager.repair_and_advance`
  porta il livello oltre `MAX_LEVEL` → `is_complete()` vero; tutti i nodi apparato
  risultano riparati. `NoraState.integrity` → 1.0.
- La riattivazione e il beat sono parte della stessa sequenza, senza schermate
  intermedie scollegate.

## 5 · Ritorno al mondo

- Dopo il finale si torna in un mondo giocabile (rivisitabile), con la nave
  pienamente online. Nessun vicolo cieco: `is_complete()` non blocca il gioco,
  disabilita solo nuovi gate.
- I mondi restano rivisitabili (decisione di scala difficoltà: aperta, vedi
  insieme.md).

## Audit integrato (Gate E2, Codex)

`world_wave_e2_audit.gd` deve verificare in un'unica esecuzione: convergenza dei
dodici sistemi accesi dalla prova, beat NORA finale, riattivazione completa della
nave (`is_complete`), ritorno a un mondo giocabile — come **una sola sequenza**,
più la rigiocata dell'intera progressione 1→24. Sul lato contenuti restano verdi
`finale_transversal_audit`, `world_semantics_audit`, `world_lesson_audit`.
