# Export del mondo Godot per il Web

Il modulo Godot viene esportato in `public/godot/outdoor/` e servito dal client
Phaser all'URL `/godot/outdoor/index.html`. Se il bundle non è presente,
Phaser mantiene automaticamente il mondo nativo come fallback.

## Prerequisiti

- Godot 4.7.1-stable;
- Export Templates Web 4.7.1;
- Node/npm installati per rigenerare le fixture e la build Phaser.

Il valore `config/features = "4.3"` in `godot/project.godot` indica il livello
di compatibilità del progetto, non la versione obbligatoria dell'editor.

## Export Web

Il preset Web usa `variant/thread_support=false`, necessario per GitHub Pages,
che non fornisce gli header COOP/COEP richiesti dai build multithread.

Da PowerShell:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path . --export-release Web `
  ../public/godot/outdoor/index.html
```

## Export Windows

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path . --export-release Windows `
  build/eli-quest-outdoor.exe
```

## Verifica completa

```powershell
node scripts/build-outdoor-fixtures.mjs
godot --headless --path godot --script res://scripts/fixture_audit.gd
npm run build
npm test -- --run
```

Per il round-trip manuale:

1. avvia `npm run dev`;
2. entra nel mondo esterno Phaser;
3. premi `Godot`;
4. raccogli un tesoro oppure avvia un incontro;
5. per l'incontro, completa il minigioco NORA in Phaser;
6. verifica il ritorno in Godot con posizione e stato ripristinati;
7. attraversa il portale e verifica il ritorno finale a Phaser.
