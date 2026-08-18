# art-sources

Sorgenti d'arte, tenute fuori dal codice. Erano in `src/assets/`, insieme al
runtime TypeScript/Phaser che non viene più eseguito: il codice è stato rimosso,
l'arte no.

## Cosa è vivo

Tre script leggono da qui:

| script | legge | produce |
|---|---|---|
| `build-exercise-atlas.mjs` | `images/history-artifacts-atlas-v1.png` | `godot/assets/exercises/…webp` |
| `build-godot-asset-manifest.mjs` | `images/` (inventario) | `docs/GODOT_ASSET_MANIFEST.json` |
| `build-godot-audio-assets.mjs` | `audio/generated/` | i clip già approvati in `godot/assets/audio/` |

## Cosa è eredità Phaser

Tutto il resto (`sprites/`, `props/`, `maps/`, `tiles/`, `painted/`, i fondali
`*-painted-bg.*`, gli `area-*-primi.*`) serviva alle scene Phaser. Nulla di
questo viene letto dal runtime Godot.

Una parte era **generata** dagli script `build-visual-assets.mjs`,
`build-tiled-*.mjs`, `build-prop-assets.mjs` — rimossi insieme al runtime,
perché producevano asset per un motore che non c'è più. Una parte è **originale**:
`painted/lab-prop-sheet-source.png`, `painted/mission-prop-sheet-source.png` e i
fondali dipinti. Non sono stati cancellati proprio perché distinguere le due
categorie file per file richiede l'occhio di chi le ha prodotte.

Se serve spazio: questa cartella pesa ~130 MB e si può potare a mano, tenendo
conto della tabella qui sopra. Il contenuto resta comunque recuperabile dalla
storia git.
