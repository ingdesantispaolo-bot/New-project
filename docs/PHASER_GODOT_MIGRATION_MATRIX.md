# Matrice C-09 · Phaser → Godot

| Funzione | Sostituto Godot | Stato | Audit |
|---|---|---:|---|
| Generazione chunk outdoor | `outdoor_generator.gd` + parity fixtures | migrata | fixture audit |
| Streaming 8×8 | `chunk_manager.gd` | migrata | editor scan |
| Missioni | `OutdoorGameplay` + `ContentManager` | migrata | C-02/C-04 |
| Esame finale | `OutdoorGameplay` + `ProgressionManager` | migrata | round-trip |
| Save bridge | `GameSaveManager` + `OutdoorSaveBridge` | migrata | C-03 |
| Progressione livelli | `ApparatusConfig` + `ProgressionManager` | migrata | C-05 |
| HUD/marker | `OutdoorHud` + `OutdoorInteractionMarker` | componente pronto | gate integrazione |
| Nave/apparati | `HubScene` + `HubController` | migrata vertical slice | C-06 |
| Narrazione NORA | `NarrativeManager` | migrata | C-07 |
| Telemetria locale | `LocalProgressReport` | migrata | C-08 |
| Redirect missioni verso Phaser | nessun redirect nel loop Godot | eliminata | round-trip |
| Contenuto esercizi (7 materie non-matematica) | banchi bakati da `scripts/build-exercise-banks.mjs`, generatori TS reali (vocabolari it/en, declinazioni latine, componenti circuiti, semi Python) o teoria curata (fisica/musica) | migrata (C-12) | validazione bake + c04_audit |

Regola di rimozione: una voce può essere eliminata dal fallback Phaser solo dopo
fixture parity, round-trip e smoke test Web verdi.
