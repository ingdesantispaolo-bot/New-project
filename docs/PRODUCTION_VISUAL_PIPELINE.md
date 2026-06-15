# Production Visual Pipeline

## Obiettivo

La pipeline visiva deve portare Eli Quest verso una qualità da gioco premium senza perdere leggibilità, performance web e iterabilità con Codex.

Il runtime resta Phaser 4.1 + TypeScript. Gli strumenti esterni consigliati entrano come formati di produzione, non come dipendenze obbligatorie del gioco.

## Strumenti

- **LDtk o Tiled** per mappe, layer, hotspot, collisioni e luci finte.
- **Aseprite** per sprite animati e stati dei personaggi.
- **TexturePacker** per atlas ottimizzati.
- **Sharp** per generare e comprimere WebP/AVIF.
- **Vite** per bundling, code-splitting e asset hashing.

## Comandi

```bash
npm run assets:build
npm run build
```

`assets:build` rigenera:

- tileset Tiled in `src/assets/tiles/eli-production-tileset.png`;
- mappe Tiled con layer artistici in `src/assets/maps/tiled`;
- layout runtime compatti in `src/assets/maps/runtime`;
- atlas TexturePacker-compatible in `src/assets/sprites/eli-quest-atlas.webp`;
- JSON atlas in `src/assets/sprites/eli-quest-atlas.json`;
- fondali ottimizzati WebP/AVIF.

## Convenzioni Asset

Le scene non devono dipendere dal nome del file sorgente, ma da runtime key stabili:

- `bg-academy-painted`
- `bg-lab-painted`
- `bg-greenhouse-painted`
- `bg-factory-painted`
- `bg-archive-painted`
- `eli-atlas`

Frame iniziali dell'atlas:

- `particle-diamond`
- `soft-flare`
- `lens-streak`
- `circuit-node`
- `ui-corner`
- `leaf-glyph`
- `gear-glyph`
- `archive-glyph`
- `robot-core`

Quando arriveranno export reali da Aseprite/TexturePacker, vanno mantenuti questi frame name o va aggiornato solo `VisualKit`.

## Mappe

Le mappe contratto iniziali sono:

- `src/assets/maps/main-hub.ldtk.json`
- `src/assets/maps/academy-lab.ldtk.json`
- `src/assets/maps/greenhouse.ldtk.json`
- `src/assets/maps/factory.ldtk.json`
- `src/assets/maps/archive.ldtk.json`

I file runtime modificabili in Tiled sono generati in:

- `src/assets/maps/tiled/main-menu.tiled.json`
- `src/assets/maps/tiled/hub-academy.tiled.json`
- `src/assets/maps/tiled/academy-lab.tiled.json`
- `src/assets/maps/tiled/greenhouse.tiled.json`
- `src/assets/maps/tiled/factory.tiled.json`
- `src/assets/maps/tiled/archive.tiled.json`

Rigenerazione e validazione:

```bash
npm run maps:build
```

`maps:build` produce tre livelli di asset:

- contratti sorgente `*.ldtk.json`;
- mappe artistiche `tiled/*.tiled.json` apribili in Tiled, con layer `floor`, `set_dressing`, `layout`, `foreground_light`;
- layout runtime `runtime/*.layout.json`, piccoli e caricati dal gioco.

Per passare a Tiled completo:

1. Creare livelli 1280x720.
2. Separare layer: fondo, architettura, oggetti, hotspot, foreground, luci.
3. Dare a hotspot e UI un `id` stabile compatibile con `MapLayoutSystem`.
4. Evitare testi dentro la mappa: i testi restano dati missione/localizzazione.
5. Validare che ogni puzzle richiesto abbia almeno un hotspot raggiungibile.
6. Non rinominare la property `runtimeId`: è il collegamento stabile con il codice.

Il runtime non importa i tile layer completi: `MapLayoutSystem` legge solo i file compatti in `maps/runtime`, così il bundle non cresce quando le mappe diventano più ricche.

## VisualKit

`VisualKit` centralizza:

- parallax multilivello;
- grading leggero;
- vignette;
- particelle da atlas;
- flare e lens streak;
- pannelli glass rifiniti;
- feedback success/warning/error;
- transizioni cinematiche brevi.

Le scene dovrebbero usare `VisualKit` invece di ricreare effetti locali. Questo mantiene coerenza visiva e riduce il costo di revisione.

## Performance

Budget iniziale consigliato:

- fondale WebP sotto 250 KB per scena;
- atlas UI/sprite sotto 512 KB nelle prime iterazioni;
- massimo 60-80 particelle leggere persistenti per scena;
- transizioni sotto 800 ms;
- nessun effetto che impedisca di leggere testo o obiettivi.

Il bundle separa `phaser`, `howler` e codice gioco tramite `manualChunks` in Vite. Phaser resta il chunk più grande; lo step successivo sarà caricare missioni e scene avanzate con dynamic import quando la struttura sarà più stabile.
