# Eli Quest — mondo esterno Godot

Questo è il vertical slice Godot del mondo esterno procedurale. Il progetto è
separato dal runtime Phaser e non modifica il client web esistente.

## Scope

- **sei biomi** (academy, ruins, geo, logic, wild, crystal) con ancore fisse e
  selezione procedurale per i chunk lontani;
- mondo logico 8×8 chunk (`x/y = -4..3`), 896 unità per chunk;
- streaming grafico 3×3 attorno al giocatore;
- movimento tastiera, touch e mouse (click/drag);
- generatore procedurale a **parità esatta** con Phaser
  (`src/procedural/OutdoorChunkGenerator.ts`): ostacoli tipizzati per bioma,
  prop, landmark, incontri (tabelline/mentale/capitali/geografia/guardiano),
  tesori con ricompense variabili e sentieri;
- ciclo giorno/notte con indicatore di fase e modulazione della luce;
- interazioni via `Area2D` + segnali (nessuna scansione per-frame), con feedback
  contestuale per tesoro, incontro e portale;
- depth ordering y-sort tra player e oggetti; terreno/bioma/sentieri su strato
  di sfondo;
- HUD responsivo (ancore `Control`) adatto a risoluzioni e aspect ratio diversi;
- portale di uscita nel mondo, più pulsante di uscita nell'HUD;
- contratto JSON per Phaser con stato in ingresso e risultati in uscita;
- renderer procedurale colorato per bioma, sostituibile con asset artistici.

## Avvio

Aprire la cartella `godot/` con Godot 4.x e avviare `scenes/outdoor_world.tscn`.
Il progetto usa il renderer Compatibility per mantenere una base adatta a Web
e Windows.

Per un controllo senza aprire la finestra:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit-after 3
```

## Contratto

Godot legge `user://eli-quest-outdoor-request.json` e scrive
`user://eli-quest-outdoor-result.json`. Il formato versionato è documentato in
`docs/OUTDOOR_GODOT_MIGRATION.md`.

La persistenza economica resta sotto il controllo di Phaser: Godot restituisce
eventi raccolti, non modifica direttamente energia o inventario.

## Parità del generatore

Il generatore GDScript (`scripts/outdoor_generator.gd`) è speculare a quello
TypeScript. Il contratto condiviso è la fixture `data/parity-fixtures.json`:

```powershell
# 1) genera la fixture dal generatore reale Phaser (lato Node)
node scripts/build-outdoor-fixtures.mjs
# 2) verifica il lato Godot
godot --headless --path godot --script res://scripts/fixture_audit.gd
```

Il test Vitest `src/integration/__tests__/outdoorGeneratorFixture.test.ts`
verifica lo stesso file sul lato TypeScript. Qualsiasi modifica al generatore
richiede di rigenerare la fixture e rieseguire entrambi i controlli.

Smoke test del flusso Godot (tesoro → incontro pendente → risultato Phaser):

```powershell
godot --headless --path . --script res://scripts/roundtrip_audit.gd
```

## Comandi della slice

- `WASD`/frecce: movimento;
- touch: destinazione del personaggio;
- `E`: raccoglie, affronta o attraversa il portale quando Eli è vicino;
- `ESC`: uscita di emergenza con scrittura del risultato.

## Export

I preset `Windows` e `Web` sono già presenti in `export_presets.cfg`.
Per esportare servono anche gli Export Templates della stessa versione Godot
(`4.7.1.stable`), installabili da `Editor > Manage Export Templates`.

```powershell
godot --headless --path . --export-release Windows build/eli-quest-outdoor.exe
godot --headless --path . --export-release Web ../public/godot/outdoor/index.html
```

L'export Web va direttamente in `public/godot/outdoor`, così Vite lo serve
all'URL `/godot/outdoor/index.html` usato dal pulsante Phaser.
