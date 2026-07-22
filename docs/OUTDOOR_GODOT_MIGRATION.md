# Runtime outdoor nativo Godot

Stato al 22 luglio 2026: la migrazione runtime è conclusa. Questo documento
sostituisce il vecchio contratto Phaser → Godot.

## Flusso scene

`boot_menu.tscn → outdoor_world.tscn ⇄ hub.tscn`

- `GIOCA` apre il mondo;
- il portale entra nella nave;
- `TORNA AL MONDO` e `Esc` dalla nave riaprono il mondo;
- non esistono redirect, ricariche pagina, `returnUrl` o result file esterni.

## Stato

- `GameSaveManager` è la sola fonte persistente e salva in
  `user://eli-quest-save.json`;
- `NativeWorldState` crea seed, avatar fallback e collezioni transitorie della
  sessione;
- `OutdoorGameplay` possiede economia, missioni, mastery, progressione,
  bottega, NORA e report;
- `OutdoorRuntimeState` è una vista read-only consumata dall'HUD.

La migrazione dei vecchi JSON resta idempotente dentro `GameSaveManager`, ma
non è un bridge e non viene eseguita tramite JavaScript.

## Contenuti e mondo

Il mondo conserva 64 chunk logici (`-4..3`), streaming visivo 3×3, sei biomi,
giorno/notte, incontri, enigmi, tesori e apparato. Gli esercizi si aprono
direttamente con `ExercisePlayer`; gli esiti aggiornano immediatamente il save.

La parità storica del generatore è verificabile offline con
`data/parity-fixtures.json` e `fixture_audit.gd`. Fixture, audit e render probe
sono esclusi dal PCK di release.

## Export

Il preset Web usa Godot 4.7.1 Compatibility senza thread. Il comando canonico è:

```powershell
& "C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web "..\public\godot\outdoor\index.html"
```

La root Web reindirizza a questo export e non carica bundle Phaser.
